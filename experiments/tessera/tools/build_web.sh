#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/web
touch build/.gdignore
godot --headless --export-release Web build/web/index.html
python3 tools/prepare_web.py
