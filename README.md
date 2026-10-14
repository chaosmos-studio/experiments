# Tessera

A block-placement puzzle made in Godot. Clear the target number of rows and columns with a fixed set of pieces.

[Play Tessera](https://shravangoswami.com/game-experiment/) · [Play Rivet](https://shravangoswami.com/game-experiment/experiments/rivet/)

- 18 verified solvable boards with real losing routes
- Three pieces at a time; upcoming sets are visible
- Drag a piece, or select it and tap its top-left cell
- Undo, verified hints, saved progress, sound and reduced motion

Keyboard: 1–3 choose, arrows move, Enter places, U undo, H hint, R restart.

## Run

Open `project.godot` in Godot 4.5.2, or run:

```sh
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
```

Rivet is a separate project in `experiments/rivet/`:

```sh
godot --path experiments/rivet
```

## Notes

- [Design and research decision](docs/DESIGN.md)
- [Original market research](docs/RESEARCH.md)
- [Difficulty checks](docs/BALANCE.md)
- [Web publishing](docs/DEPLOYMENT.md)

Every successful push to `main` tests and publishes both games at their matching paths.
