# Filament

Drag knots to untangle a living web.

[Play](https://shravangoswami.com/game-experiment/)

- 12 puzzles with free knots and fixed anchors.
- Light mode by default, with optional dark mode.
- Animated strands, undo, hints, and reduced motion.
- Original ambient music, separate effects, and volume controls.
- Mouse, touch, and keyboard controls.
- Progress saved on this device.

Use Godot 4.5.2 to open `project.godot`.

```sh
godot --headless --script res://tests/run_tests.gd
python3 tools/generate_levels.py
bash tools/build_web.sh
npm ci
npx playwright install chromium
npx playwright test
```

Pushes to `main` test and deploy all three games with GitHub Pages.

Past experiments: [Tessera](experiments/tessera/) · [Rivet](experiments/rivet/).

[Similar games](docs/COMPARABLES.md) · [Music and credits](docs/AUDIO.md) · [Design](docs/DESIGN.md) · [Research](docs/RESEARCH.md) · [Deployment](docs/DEPLOYMENT.md)
