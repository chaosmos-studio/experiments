# Experiments

Chaosmos game prototypes.
Each one is a standalone Godot project under `experiments/`.

- [Hinge Grove](experiments/hinge-grove/), a garden puzzle about swinging paired seeds and choosing when to take root. [Play the preview](https://chaosmos.studio/experiments/hinge-grove/)
- [Rivet](experiments/rivet/), a sorting puzzle about taking screws out in order. [Play the preview](https://chaosmos.studio/experiments/rivet/)
- [Tessera](experiments/tessera/), a finite block puzzle with fixed pieces and line goals. [Play the preview](https://chaosmos.studio/experiments/tessera/)

Game Off 2026 drafts for the theme SHIFT:

- [Phasewalk](experiments/phasewalk/), switch between two versions of a room to cross blocked paths.
- [Rowshift](experiments/rowshift/), slide rows and columns to match four stones with their marks.

Pyxis, first called Filament, started here and graduated to its own repo, [chaosmos-studio/pyxis](https://github.com/chaosmos-studio/pyxis).
The games in development, Ripple, Hako, Rinse and Corona, each have their own repo (`chaosmos-studio/<name>`) and publish to `chaosmos.studio/experiments/<name>/` themselves.
The list at [chaosmos.studio/experiments](https://chaosmos.studio/experiments/) is a page of the studio site, in `src/data/experiments.ts`, so add or remove a prototype there too.

## Run

Phasewalk and Rowshift use Godot 4.7.
The three earlier experiments use Godot 4.5.2.
Run these from the individual game's directory under `experiments/`.

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

Every code push to `main` runs the checks for the three earlier experiments and publishes them to chaosmos.studio.
The Game Off drafts are local Godot projects until a concept is selected for a web release.
