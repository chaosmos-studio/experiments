"""Compress the WebAssembly export for static hosting."""

from pathlib import Path
import gzip


web = Path(__file__).resolve().parents[1] / "build" / "web"
source = web / "index.wasm"
target = web / "index.wasm.gz"
target.write_bytes(gzip.compress(source.read_bytes(), compresslevel=9, mtime=0))
print(f"{source.stat().st_size / 1024 / 1024:.1f} MB -> {target.stat().st_size / 1024 / 1024:.1f} MB")
