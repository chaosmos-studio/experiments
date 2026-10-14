#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
for project in . experiments/rivet; do
  mkdir -p "$project/build/web"
  touch "$project/build/.gdignore"
  godot --headless --path "$project" --export-release Web "$repo_root/$project/build/web/index.html" 2>&1 | tee /tmp/export.log
  ! grep -E 'SCRIPT ERROR|Parse Error|ERROR:' /tmp/export.log
  python3 "$project/tools/prepare_web.py"
done
mkdir -p build/web/experiments/rivet
cp -a experiments/rivet/build/web/. build/web/experiments/rivet/
cp web/experiments.html build/web/experiments/index.html
python3 tools/check_web_paths.py
