# Deployment

Godot 4.5.2, compatibility renderer, single-threaded WebAssembly, GitHub Pages.

| Project | Public path |
| --- | --- |
| Filament (root) | `/game-experiment/` |
| Tessera | `/game-experiment/experiments/tessera/` |
| Rivet | `/game-experiment/experiments/rivet/` |

`main` pushes run native tests for all three projects, verify Filament's generated
content, export all three, run desktop and phone browser tests, then deploy a single
Pages artifact. Failed tests block deployment. The existing custom domain is
`shravangoswami.com`. No Pages settings change is needed.

`experiments/.gdignore` keeps archived projects out of the root Godot import.
`tools/build_web.sh` exports each separately and combines their outputs. Relative
asset paths keep every archived URL independent. Each export uses verified WASM
chunks and a local loader. Browser screenshots are retained as workflow artifacts.

The saved-progress namespaces are separate: `filament.json`, `tessera.json`, and
Rivet's existing save. Filament saves level completion and preferences, not a
partially moved web. The game runs without cross-origin isolation headers.
