# Palewheel 96

Palewheel 96 is an experimental late-90s pixel-art interpretation of Palewheel's gravity platforming.
Run through a copper engine, collect light cells, shift gravity in quarter turns, and use each turn to change bridges, cargo, and sentry timing.

[Play Palewheel 96](https://chaosmos.studio/experiments/palewheel-96/) on a phone in landscape or on a desktop.
The [current Palewheel](https://chaosmos.studio/palewheel/) remains available for comparison.

Use A and D or the arrow keys to move, W, Up, or Space to jump, S or Down to crouch, and Shift or a mouse click to turn gravity.
Use R to restart and P or Escape to pause.
On a phone, slide left or right to walk, swipe up to jump, swipe down to crouch, and tap the playfield to turn gravity.

Run `./play.sh` from this directory with Godot 4.7.
Run `godot --headless --path . -s res://tests/run_tests.gd` for gameplay checks.
The browser build uses `godot --headless --path . --export-release Web build/web/index.html`, then `python3 tools/prepare_web.py`.
