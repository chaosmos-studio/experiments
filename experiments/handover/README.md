# Handover

A small cooperative puzzle adventure for [Game Off 2026](https://itch.io/jam/game-off-2026), whose theme is SHIFT.
Three caretakers wake an orbital greenhouse by keeping machines running for one another.

[Play in your browser](https://chaosmos.studio/experiments/handover/).
Turn your phone sideways to play.

## How to play

Tap a machine to assign the selected caretaker.
Tap another caretaker at the bottom of the screen to shift to them.
The first caretaker keeps working while you give the next one a task.
Complete the chain to move toward sunrise.

Keyboard: `1`, `2`, and `3` select caretakers, and `R` restarts.

## Build

Open `project.godot` in Godot 4.7 with the GL Compatibility renderer.
Run `godot --headless --path . -s res://tests/run_tests.gd` to check the handoff sequence.
Run `godot --headless --path . --export-release Web build/web/index.html` to export the web build.
The included no-thread web template supports standard GitHub Pages hosting.

Art and audio sources are listed in [CREDITS.md](CREDITS.md).
