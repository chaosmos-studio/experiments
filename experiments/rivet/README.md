# Rivet

Archived experiment. [Play Tessera](https://shravangoswami.com/game-experiment/) is the current game.

A quiet sorting puzzle made in Godot. Keep screws in removal order, match three neighbours, and return pieces to their panels.

[Play Rivet](https://shravangoswami.com/game-experiment/experiments/rivet/)

- 36 verified solvable levels
- Inspect hidden colours, undo, hints, and saved completion
- Four difficulty chapters and unaided solve marks
- Mouse, touch, and keyboard controls
- Optional sound and reduced motion

## Run

Open `project.godot` in Godot 4.5.2 and press F6 on `scenes/main.tscn`, or press F5.

```sh
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
```

## Controls

Tap an exposed screw to add it to the right end of the tray. Three adjacent screws with the same colour or symbol clear. Tap any unmatched tray screw to return it to its original panel; closing the gap can create a match. A full tray blocks collection until you return a screw. Clear both the panels and tray to win.

Keyboard: arrows select, Enter collects, 1–7 return tray slots, U undoes, H hints, R restarts, M toggles sound, I inspects the layers.

## Notes

- [Research](docs/RESEARCH.md)
- [Game design](docs/DESIGN.md)
- [Difficulty checks](docs/BALANCE.md)
- [Web publishing](docs/DEPLOYMENT.md)
- [Build workflow](https://github.com/shravanngoswamii/game-experiment/actions/workflows/web.yml)

CI tests and exports each push to `main`, then publishes to GitHub Pages.
