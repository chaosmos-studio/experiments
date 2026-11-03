#!/usr/bin/env bash
# Launch the game directly with the Godot version on PATH.
exec godot --path "$(cd "$(dirname "$0")" && pwd)" "$@"
