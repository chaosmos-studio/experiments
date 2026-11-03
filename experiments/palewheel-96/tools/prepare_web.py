"""Prepare a Godot web export for static hosting with a per-file size limit."""

import hashlib
import json
from pathlib import Path


root = Path.cwd() / "build" / "web"
(root.parent / ".gdignore").touch()
chunk_size = 4 * 1024 * 1024
assets = {}
for file_name, content_type in (("index.wasm", "application/wasm"), ("index.pck", "application/octet-stream")):
    source = root / file_name
    raw = source.read_bytes()
    if file_name.endswith(".wasm"):
        assert raw[:4] == b"\0asm", "Not a WebAssembly build"
    else:
        assert b"ECFG" in raw, "The game pack has no project configuration"
    for old in root.glob(f"{file_name}.part*"):
        old.unlink()
    parts = []
    for offset in range(0, len(raw), chunk_size):
        name = f"{file_name}.part{offset // chunk_size}"
        (root / name).write_bytes(raw[offset : offset + chunk_size])
        parts.append(name)
    assert b"".join((root / name).read_bytes() for name in parts) == raw
    assets[file_name] = {
        "parts": parts,
        "size": len(raw),
        "sha256": hashlib.sha256(raw).hexdigest(),
        "content_type": content_type,
    }
    source.unlink()

loader = """// Stream the engine and game pack from static-host-friendly chunks.
(() => {
  const nativeFetch = window.fetch.bind(window);
  const assets = ASSETS;
  const base = new URL('.', document.currentScript.src);
  window.fetch = async function(resource, options) {
    const url = new URL(typeof resource === 'string' ? resource : resource.url || String(resource), location.href);
    const name = Object.keys(assets).find(candidate => url.href === new URL(candidate, base).href);
    if (!name) return nativeFetch(resource, options);
    const asset = assets[name];
    const stream = new ReadableStream({async start(controller) {
      try {
        for (const part of asset.parts) {
          const partUrl = new URL(part, base);
          partUrl.searchParams.set('v', asset.sha256.slice(0, 12));
          const response = await nativeFetch(partUrl, options);
          if (!response.ok) throw new Error('Game download failed: ' + response.status);
          const reader = response.body.getReader();
          while (true) {const {done, value} = await reader.read(); if (done) break; controller.enqueue(value);}
        }
        controller.close();
      } catch (error) {controller.error(error);}
    }});
    return new Response(stream, {headers: {'Content-Type': asset.content_type, 'Content-Length': String(asset.size)}});
  };
})();
""".replace("ASSETS", json.dumps(assets))
(root / "wasm-loader.js").write_text(loader)
html = root / "index.html"
html_text = html.read_text()
loader_tag = 'src="wasm-loader.js"'
assert loader_tag in html_text
html.write_text(html_text.replace(loader_tag, f'src="wasm-loader.js?v={assets["index.pck"]["sha256"][:12]}"'))
(root / ".nojekyll").touch()
(root / "build-info.json").write_text(
    json.dumps(assets, indent=2) + "\n"
)
for imported in root.glob("*.import"):
    imported.unlink()
assert max(path.stat().st_size for path in root.iterdir() if path.is_file()) <= chunk_size
print("Prepared web build: " + ", ".join(f"{name}: {len(asset['parts'])} chunks" for name, asset in assets.items()))
