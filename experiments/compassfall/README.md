# Compassfall

Run and jump through a clockwork station, turn gravity to cross its rooms, pause moving sentries, move cargo and collect the sparks that open each door.

[Play Compassfall in a landscape phone browser](https://chaosmos.studio/experiments/compassfall/).

## Controls

On desktop, use A and D to move, Space to jump, Q and E to turn gravity, R to restart and P to pause.
On a phone, turn the screen sideways and use the on-screen controls.

## Development

This is a standalone Godot 4.7 project using the GL Compatibility renderer.
Run `./play.sh` from this directory to play locally.
Run `godot --headless --path . -s res://tests/run_tests.gd` to check the gameplay loop.
The web build is exported and published by `.github/workflows/compassfall-web.yml` in the experiments repository.

The pilot and sentry sprites come from `tools/render_pilot.py` and `tools/render_sentry.py`, and the sound effects come from `tools/make_sound.py`.
`tools/fetch_web_template.py` can retrieve the exact official Godot web template used by the committed export preset.
See [the design notes](PLAN.md) and [credits](CREDITS.md).
