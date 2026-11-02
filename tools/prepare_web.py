"""Split Godot's WebAssembly file for the studio site's static deployment."""

import hashlib
import json
from pathlib import Path


root = Path.cwd() / "build" / "web"
(root.parent / ".gdignore").touch()
wasm = root / "index.wasm"
raw = wasm.read_bytes()
assert raw[:4] == b"\0asm", "Not a WebAssembly build"
chunk_size = 4 * 1024 * 1024
parts = []
for old in root.glob("index.wasm.part*"):
    old.unlink()
for offset in range(0, len(raw), chunk_size):
    name = f"index.wasm.part{offset // chunk_size}"
    (root / name).write_bytes(raw[offset : offset + chunk_size])
    parts.append(name)

loader = """// Stream the engine from static-host-friendly chunks.
(() => {
  const nativeFetch = window.fetch.bind(window);
  const parts = PARTS;
  const base = new URL('.', document.currentScript.src);
  window.fetch = async function(resource, options) {
    const url = new URL(typeof resource === 'string' ? resource : resource.url || String(resource), location.href);
    if (url.href !== new URL('index.wasm', base).href) return nativeFetch(resource, options);
    const stream = new ReadableStream({async start(controller) {
      try {
        for (const name of parts) {
          const response = await nativeFetch(new URL(name, base), options);
          if (!response.ok) throw new Error('Engine download failed: ' + response.status);
          const reader = response.body.getReader();
          while (true) {const {done, value} = await reader.read(); if (done) break; controller.enqueue(value);}
        }
        controller.close();
      } catch (error) {controller.error(error);}
    }});
    return new Response(stream, {headers: {'Content-Type': 'application/wasm', 'Content-Length': 'SIZE'}});
  };
})();
""".replace("PARTS", json.dumps(parts)).replace("SIZE", str(len(raw)))
(root / "wasm-loader.js").write_text(loader)
(root / ".nojekyll").touch()
(root / "build-info.json").write_text(
    json.dumps({"wasm_sha256": hashlib.sha256(raw).hexdigest(), "wasm_size": len(raw), "parts": parts}, indent=2) + "\n"
)
assert b"".join((root / name).read_bytes() for name in parts) == raw
wasm.unlink()
for imported in root.glob("*.import"):
    imported.unlink()
assert max(path.stat().st_size for path in root.iterdir() if path.is_file()) <= chunk_size
print(f"Prepared web build: {len(parts)} verified WASM chunks, {len(raw)} bytes.")
