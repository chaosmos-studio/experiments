# Verification

16 October 2026, Godot 4.5.2.

- Source: [405b8d3](https://github.com/chaosmos-studio/experiments/commit/405b8d3d279e7744d3b71a1c8a6b9f8c3649b72a).
- [Shared CI run](https://github.com/chaosmos-studio/experiments/actions/runs/38913392757): all three games and deployment passed.
- Hinge Grove native rules: 2,257 checks, zero failures.
- Python audit: 30 exact shortest routes, 435 symmetry comparisons, mutation guards and 9,000 random trials passed.
- Desktop and mobile browser scenarios passed locally and in CI. They exercise real input, early and late gardens, a rooted dead end, undo, hints, completion, keyboard input, saved preferences and audible/muted output.
- [Studio listing deployment](https://github.com/chaosmos-studio/website/actions/runs/38913578392): passed; uses a screenshot of the real game.
- [Public preview](https://chaosmos.studio/experiments/hinge-grove/): HTTP 200. A fresh mobile Chromium session loaded all 30 gardens and solved garden 1 in two turns through touch input, with no JavaScript or Godot errors.

The live check allowed only the game's own assets, blocked third-party requests and refused to execute
a fallback page. The game contains no analytics. Local and CI browser runs used the unmodified web export.

This verifies the implemented prototype. Human comprehension, enjoyment, retention, physical-device
coverage and commercial potential remain unmeasured. The playtest gate is in [PLAN.md](../PLAN.md).
