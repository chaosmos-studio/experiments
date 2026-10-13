# Rivet

A quiet sorting puzzle made in Godot. Remove exposed screws, collect matching triples, and keep space in the tray.

- 36 verified solvable levels
- Undo, hints, and saved completion
- Mouse, touch, and keyboard controls
- Optional sound and reduced motion

## Run

Open `project.godot` in Godot 4.5.2 and press F6 on `scenes/main.tscn`, or press F5.

```sh
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
```

## Controls

Tap a screw to collect it. Match three colours or symbols to clear them. Seven unmatched screws fill the tray.

Keyboard: arrows select, Enter collects, U undoes, H hints, R restarts, M toggles sound.

## Notes

- [Research](docs/RESEARCH.md)
- [Game design](docs/DESIGN.md)
- [Web publishing](docs/DEPLOYMENT.md)
- [Build workflow](https://github.com/shravanngoswamii/game-experiment/actions/workflows/web.yml)

CI tests and exports each push to `main`, then deploys to GitHub Pages when Pages is enabled.
