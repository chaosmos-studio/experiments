# Palewheel 96

Palewheel 96 is an experimental late-90s pixel-art interpretation of Palewheel's gravity platforming.
Run through a copper engine, collect light cells, shift gravity in quarter turns, and use each turn to change bridges, cargo, and sentry timing.

[Play Palewheel 96](https://chaosmos.studio/experiments/palewheel-96/) on a phone in landscape or on a desktop.
The [current Palewheel](https://chaosmos.studio/palewheel/) remains available for comparison.

Use A and D to move, Space to jump, Q or E to turn gravity, R to restart, and P to pause.
The phone version uses controls over the playfield.

Run `./play.sh` from this directory with Godot 4.7.
Run `godot --headless --path . -s res://tests/run_tests.gd` for gameplay checks.
The browser build uses `godot --headless --path . --export-release Web build/web/index.html`, then `python3 tools/prepare_web.py`.
