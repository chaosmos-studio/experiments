"""Extract only the official Godot 4.7 Web template from its release TPZ."""

import hashlib
import struct
import urllib.request
import zlib
from pathlib import Path


URL = "https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_export_templates.tpz"
TARGET = "templates/web_nothreads_release.zip"
EXPECTED_SHA256 = "6e1d01e7d8995a2dfec8b33dc530f02c034906267ec441288c2a3318d49e00b9"
OUTPUT = Path(__file__).resolve().parents[1] / "web" / "godot.web.template_release.wasm32.nothreads.zip"


def fetch(header):
    request = urllib.request.Request(URL, headers={"Range": header, "User-Agent": "Compassfall-template-extractor"})
    with urllib.request.urlopen(request, timeout=120) as response:
        if response.status != 206:
            raise RuntimeError(f"Expected HTTP 206, got {response.status}")
        return response.read(), response.headers["Content-Range"]


with urllib.request.urlopen(urllib.request.Request(URL, method="HEAD"), timeout=120) as response:
    size = int(response.headers["Content-Length"])
tail, extent = fetch(f"bytes={size - 262144}-{size - 1}")
end_at = tail.rfind(b"PK\x05\x06")
if end_at < 0:
    raise RuntimeError("ZIP end of central directory was not found")
directory_size, directory_offset = struct.unpack_from("<II", tail, end_at + 12)
directory, _ = fetch(f"bytes={directory_offset}-{directory_offset + directory_size - 1}")
cursor = 0
entry = None
while cursor < len(directory):
    if directory[cursor:cursor + 4] != b"PK\x01\x02":
        raise RuntimeError("Bad ZIP central directory")
    compression = struct.unpack_from("<H", directory, cursor + 10)[0]
    expected_crc = struct.unpack_from("<I", directory, cursor + 16)[0]
    compressed_size = struct.unpack_from("<I", directory, cursor + 20)[0]
    original_size = struct.unpack_from("<I", directory, cursor + 24)[0]
    name_size, extra_size, comment_size = struct.unpack_from("<HHH", directory, cursor + 28)
    local_offset = struct.unpack_from("<I", directory, cursor + 42)[0]
    name = directory[cursor + 46:cursor + 46 + name_size].decode()
    if name == TARGET:
        entry = (compression, expected_crc, compressed_size, original_size, local_offset)
        break
    cursor += 46 + name_size + extra_size + comment_size
if entry is None:
    raise RuntimeError(f"{TARGET} was not in official release TPZ")
compression, expected_crc, compressed_size, original_size, local_offset = entry
header, _ = fetch(f"bytes={local_offset}-{local_offset + 4095}")
if header[:4] != b"PK\x03\x04":
    raise RuntimeError("Bad ZIP local header")
name_size, extra_size = struct.unpack_from("<HH", header, 26)
data_offset = local_offset + 30 + name_size + extra_size
packed, _ = fetch(f"bytes={data_offset}-{data_offset + compressed_size - 1}")
data = zlib.decompress(packed, -15) if compression == 8 else packed
if len(data) != original_size or zlib.crc32(data) != expected_crc or not data.startswith(b"PK\x03\x04"):
    raise RuntimeError("Extracted Web template is incomplete")
if hashlib.sha256(data).hexdigest() != EXPECTED_SHA256:
    raise RuntimeError("Official Web template checksum changed")
OUTPUT.write_bytes(data)
print(f"Official Web template: {len(data)} bytes, SHA256 {hashlib.sha256(data).hexdigest()}, TPZ {size} bytes")
