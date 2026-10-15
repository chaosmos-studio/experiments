# Experiments

Chaosmos prototypes that did not ship.
Each one is a standalone Godot project under `experiments/`.

- [Rivet](experiments/rivet/), a sorting puzzle about taking screws out in order. [Play the preview](https://chaosmos.studio/experiments/rivet/)
- [Tessera](experiments/tessera/), a finite block puzzle with fixed pieces and line goals. [Play the preview](https://chaosmos.studio/experiments/tessera/)

Pyxis, first called Filament, started here and graduated to its own repo, [chaosmos-studio/pyxis](https://github.com/chaosmos-studio/pyxis).
The list at [chaosmos.studio/experiments](https://chaosmos.studio/experiments/) is a page of the studio site, in `src/data/experiments.ts`, so add or remove a prototype there too.

## Run

Both prototypes use Godot 4.5.2.
Run these from `experiments/rivet` or `experiments/tessera`.

```sh
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
```

The browser tests run against a web export.

```sh
godot --headless --path . --export-release Web build/web/index.html
python3 tools/prepare_web.py
npm ci
npx playwright install chromium
npx playwright test
```

Every push to `main` runs the same checks for both and publishes them to chaosmos.studio.
