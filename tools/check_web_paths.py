"""Check the combined Pages artifact and each local engine path."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]/'build/web'
for relative,marker in [('experiments/rivet', 'rivet-campaign'), ('experiments/tessera', 'tessera-version')]:
    game=root/relative
    assert marker in (game/'index.html').read_text()
    assert (game/'index.js').is_file() and (game/'index.pck').is_file()
    manifest=json.loads((game/'build-info.json').read_text())
    assert all((game/p).is_file() for p in manifest['parts'])
    assert (game/'wasm-loader.js').is_file()
assert (root/'experiments/index.html').is_file()
assert 'https://chaosmos.studio/filament/play/' in (root/'index.html').read_text()
print('Verified Filament redirect and archived game paths.')
