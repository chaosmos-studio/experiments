#!/usr/bin/env bash
# Launch the game directly, no Godot editor. Extra args pass through, e.g. `./play.sh -- touch`.
exec ~/.local/bin/godot --path "$(cd "$(dirname "$0")" && pwd)" "$@"
