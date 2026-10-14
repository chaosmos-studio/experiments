# Web publishing

GitHub Pages serves two standalone Godot exports:

| Source | Web path |
| --- | --- |
| Repository root, Tessera | [game-experiment/](https://shravangoswami.com/game-experiment/) |
| `experiments/rivet/` | [game-experiment/experiments/rivet/](https://shravangoswami.com/game-experiment/experiments/rivet/) |

The previous game is archived as source and remains playable. Its assets, rules, campaign and saves use its own Godot project. Each successful push to `main` rebuilds and tests both games before publishing one Pages artifact. Pages source remains GitHub Actions.

CI installs pinned Godot 4.5.2 and checks archive hashes, imports both projects, runs both native test suites, regenerates Tessera's levels, exports both builds, validates nested asset paths, and runs desktop and mobile browser tests. Screenshots and the combined web build are uploaded as Actions artifacts.

## Local build

Install Godot 4.5.2 and its web export templates, then:

```sh
godot --headless --editor --path . --import --quit
godot --headless --editor --path experiments/rivet --import --quit
bash tools/build_web.sh
python3 -m http.server 8000 --directory build/web
```

Open `http://localhost:8000/` or `http://localhost:8000/experiments/rivet/`. To run browser tests: `npm ci`, `npx playwright install chromium`, and `npm run test:web`.

Both exports use WebGL 2 and single-threaded WebAssembly, with no cross-origin isolation header requirement. Each engine is split into verified relative-path chunks. No accounts or server-side player data are used. Browser restrictions may prevent local progress saving.
