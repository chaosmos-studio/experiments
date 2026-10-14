#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
for project in . experiments/rivet experiments/tessera; do
  mkdir -p "$project/build/web"
  touch "$project/build/.gdignore"
  godot --headless --path "$project" --export-release Web "$repo_root/$project/build/web/index.html" 2>&1 | tee /tmp/export.log
  ! grep -E 'SCRIPT ERROR|Parse Error|ERROR:' /tmp/export.log
  python3 "$project/tools/prepare_web.py"
done
for archived in rivet tessera; do
  mkdir -p "build/web/experiments/$archived"
  cp -a "experiments/$archived/build/web/." "build/web/experiments/$archived/"
done
cp web/experiments.html build/web/experiments/index.html
mkdir -p build/web/licenses
cp assets/fonts/*-LICENSE.txt build/web/licenses/
cp assets/CREDITS.txt build/web/licenses/CREDITS.txt
python3 tools/check_web_paths.py
