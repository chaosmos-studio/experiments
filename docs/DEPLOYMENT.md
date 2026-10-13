# Web publishing

Every push to `main` runs `.github/workflows/web.yml`:

1. Download pinned Godot 4.5.2 and verify both archives with SHA-256.
2. Import the project, regenerate levels, and run rule and scene tests.
3. Export the single-threaded WebGL 2 build.
4. Run Chromium checks at desktop and phone sizes, including touch input.
5. Upload the web build and test screenshots as Actions artifacts.
6. Publish the tested build to GitHub Pages.

## One-time Pages setting

In the repository, open **Settings > Pages > Build and deployment > Source**, and select **GitHub Actions**. Rerun the workflow if the first deployment ran before this setting was enabled.

The repository is private. GitHub Pages on private repositories requires an eligible GitHub plan. The workflow does not change repository visibility. If the plan does not include private-repository Pages, the downloadable artifact still builds; use another static host for publishing.

Expected Pages address after a successful deployment: `https://shravanngoswamii.github.io/game-experiment/`. This is an expected address, not evidence of a live deployment. Use the URL shown in the successful deployment job.

## Local preview

Install Godot 4.5.2 and its export templates, then run:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/run_tests.gd
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 tools/prepare_web.py
python3 -m http.server 8000 --directory build/web
```

Open `http://localhost:8000`. Opening `index.html` directly as a file will not work.

For browser checks, run `npm ci`, `npx playwright install chromium`, then `npm run test:web`. The test runner starts its own local server.

## Hosting details

The game uses GDScript and Godot's Compatibility renderer. Thread and extension support are disabled, so COOP/COEP headers and SharedArrayBuffer are unnecessary. HTTPS and WebGL 2/WebAssembly support are required for the deployed preview.

`prepare_web.py` divides the 38MB engine into four files under 10MiB. The loader streams their bytes back into one WebAssembly response. This supports static hosts with per-file limits without changing the engine. The generated `build-info.json` records the complete engine hash. First load is still substantial; an optimized custom Godot template is a future performance improvement.

The browser stores completed studies and preferences locally. Browser storage restrictions can prevent persistence. No personal data is sent to a game server.

Sources: [Godot Web export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html), [GitHub Pages workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages).
