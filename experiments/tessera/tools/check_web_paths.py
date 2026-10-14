"""Check the combined Pages artifact and each local engine path."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]/'build/web'
for relative,marker in [('.', 'tessera-version')]:
    game=root/relative
    assert marker in (game/'index.html').read_text()
    assert (game/'index.js').is_file() and (game/'index.pck').is_file()
    manifest=json.loads((game/'build-info.json').read_text())
    assert all((game/p).is_file() for p in manifest['parts'])
    assert (game/'wasm-loader.js').is_file()
print('Verified Tessera web paths.')
