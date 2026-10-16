# Hinge Grove

Swing a seed. Grow a little garden.

[Play](https://chaosmos.studio/experiments/hinge-grove/)

Tap the seed you want to move, then a marked landing spot. Or drag that same seed along its arc.
Its partner stays still. Both belong on matching soil.
A planted seed takes root. Plant too soon and you can close another route; undo is always free.

- 30 solver-proven gardens, with shortest routes from 2 to 18 turns
- Three stages: first turns, making room, and shared ground
- Live drag previews, spreading roots, springy leaves and staggered petal blooms
- Original music, shape-coded colours and a reduced-motion option
- Guided opening gardens, larger controls and specific feedback for blocked swings
- Touch, mouse and keyboard; hints, undo and protected restart
- Unfinished gardens and undo history survive reloads and level switching
- One-tap recovery to before an irreversible blocked planting
- Light UI with Manrope, reduced motion and separate sound/music controls

This is a playable experiment, ready for feedback on the core mechanic.

## Run

Godot 4.5.2, GL Compatibility, portrait.

```sh
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
python3 tools/audit_levels.py
```

`docs/RESEARCH.md` records the evidence and competition. `PLAN.md` describes the playtest gates.
`MATH.md` explains the rules, generation and exact shortest-route proof.

## Web

```sh
mkdir -p build/web
godot --headless --editor --path . --import --quit
godot --headless --path . --export-release Web build/web/index.html
python3 tools/prepare_web.py
npm ci
npx playwright install chromium
npx playwright test
```

The repository's shared workflow builds and publishes this directory alongside Rivet and Tessera.
