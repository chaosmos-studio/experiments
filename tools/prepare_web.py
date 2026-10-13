"""Split WASM for static hosts with per-file size limits; preserve streaming loading."""
import json
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parents[1]/'build'/'web'
(root.parent/'.gdignore').touch()
wasm = root/'index.wasm'
raw = wasm.read_bytes()
assert raw[:4] == b'\0asm', 'Not a WebAssembly build'
parts = []
chunk_size = 4*1024*1024
for old in root.glob('index.wasm.part*'):
    old.unlink()
for i in range(0, len(raw), chunk_size):
    name = f'index.wasm.part{i//chunk_size}'
    (root/name).write_bytes(raw[i:i+chunk_size])
    parts.append(name)
script = '''// Reassemble the engine from static-host-friendly chunks.
(() => {
  const nativeFetch = window.fetch.bind(window);
  const parts = PARTS;
  const base = new URL('.', document.currentScript.src);
  window.fetch = async function(resource, options) {
    const url = new URL(typeof resource === 'string' ? resource : resource.url || String(resource), location.href);
    if (url.href !== new URL('index.wasm', base).href) return nativeFetch(resource, options);
    const responses = await Promise.all(parts.map(name => nativeFetch(new URL(name, base), options)));
    for (const response of responses) if (!response.ok) throw new Error('Engine download failed: ' + response.status);
    const stream = new ReadableStream({async start(controller) {
      try {
        for (const response of responses) {
          const reader = response.body.getReader();
          while (true) {const {done,value}=await reader.read();if(done)break;controller.enqueue(value);}
        }
        controller.close();
      } catch (error) {controller.error(error);}
    }});
    return new Response(stream,{headers:{'Content-Type':'application/wasm','Content-Length':'SIZE'}});
  };
})();
'''.replace('PARTS', json.dumps(parts)).replace('SIZE', str(len(raw)))
(root/'wasm-loader.js').write_text(script)
(root/'.nojekyll').touch()
manifest = {'wasm_sha256': hashlib.sha256(raw).hexdigest(), 'wasm_size': len(raw), 'parts': parts}
(root/'build-info.json').write_text(json.dumps(manifest, indent=2)+'\n')
assert b''.join((root/p).read_bytes() for p in parts) == raw
wasm.unlink()
for imported in root.glob('*.import'):
    imported.unlink()
assert max(p.stat().st_size for p in root.iterdir() if p.is_file()) <= chunk_size
print(f'Prepared web build: {len(parts)} verified WASM chunks, {len(raw)} bytes.')
