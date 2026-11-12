# Experiments

Chaosmos game prototypes.
Each one is a standalone Godot or browser project under `experiments/`.

Action worlds:

- [Veylifter](experiments/veylifter/), an aerial rescue run where a storm presses in as you carry stranded people home. [Play the preview](https://chaosmos.studio/experiments/veylifter/)
- [Undertow Bloom](experiments/undertow-bloom/), a deep-sea escort game about building and protecting a living chain of lights. [Play the preview](https://chaosmos.studio/experiments/undertow-bloom/)
- [Mixtape Mile](experiments/mixtape-mile/), a skate courier ride where tricks build a song across three city shows. [Play the preview](https://chaosmos.studio/experiments/mixtape-mile/)

- [Hinge Grove](experiments/hinge-grove/), a garden puzzle about swinging paired seeds and choosing when to take root. [Play the preview](https://chaosmos.studio/experiments/hinge-grove/)
- [Rivet](experiments/rivet/), a sorting puzzle about taking screws out in order. [Play the preview](https://chaosmos.studio/experiments/rivet/)
- [Tessera](experiments/tessera/), a finite block puzzle with fixed pieces and line goals. [Play the preview](https://chaosmos.studio/experiments/tessera/)

Game Off 2026 drafts for the theme SHIFT:

- [Compassfall](experiments/compassfall/), run, jump and turn gravity through a clockwork station. [Play on the web](https://chaosmos.studio/experiments/compassfall/)
- [Handover](experiments/handover/), assign three caretakers to connected tasks in an orbital greenhouse. [Play on the web](https://chaosmos.studio/experiments/handover/)
- [Phasewalk](experiments/phasewalk/), switch between two versions of a room to cross blocked paths. [Play on the web](https://chaosmos.studio/experiments/phasewalk/)
- [Rowshift](experiments/rowshift/), slide rows and columns to match four stones with their marks. [Play on the web](https://chaosmos.studio/experiments/rowshift/)
- [Flipline](experiments/flipline/), tap to reverse gravity and slip past barriers. [Play on the web](https://chaosmos.studio/experiments/flipline/)
- [Timefall](experiments/timefall/), steer through gates and shift into slow time. [Play on the web](https://chaosmos.studio/experiments/timefall/)

Pyxis, first called Filament, started here and graduated to its own repo, [chaosmos-studio/pyxis](https://github.com/chaosmos-studio/pyxis).
The games in development, Ripple, Hako, Rinse and Corona, each have their own repo (`chaosmos-studio/<name>`) and publish to `chaosmos.studio/experiments/<name>/` themselves.
The list at [chaosmos.studio/experiments](https://chaosmos.studio/experiments/) is a page of the studio site, in `src/data/experiments.ts`, so add or remove a prototype there too.

## Run

Compassfall, Handover, Phasewalk and Rowshift use Godot 4.7.
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
The Game Off drafts and action worlds publish from their own workflows to the studio site's GitHub Pages branch.
