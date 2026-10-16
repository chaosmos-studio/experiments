# Verification

## 0.2 usability and garden growth

16 October 2026, Godot 4.5.2.

- Source: [cb844c7](https://github.com/chaosmos-studio/experiments/commit/cb844c7c68deb0ea01746fa891f19589cbc60118).
- [CI run 38968430693](https://github.com/chaosmos-studio/experiments/actions/runs/38968430693): all three games and deployment passed.
- Native: 2,274 checks, zero failures. Covers rules, legal saved histories, growth transitions, reduced motion and returning to unfinished gardens.
- The campaign is unchanged: 30 exact shortest routes, 435 symmetry comparisons and the independent random-play audit.
- Desktop and mobile Chromium scenarios passed (2/2), using real mouse, touch and keyboard input. Scenarios cover moving-seed selection, continuous drag previews, canceled releases, ignored second touches, roots and blooms, immediate-refresh persistence, gallery resumes, protected restart, dead-end recovery, late gardens, audio and reduced motion.
- The mobile scenario also checks 360 × 640 layout and minimum 48 CSS-pixel button target height.
- Visually inspected CI frames for guidance, drag preview, roots, opening petals, the completed bloom, recovery, garden 30 and 360 × 640 settings. No clipped text or overlapping controls in those captures.
- Review frames are published under [review/](https://chaosmos.studio/experiments/hinge-grove/review/01-guidance.png).
- [GitHub Pages rollout](https://github.com/chaosmos-studio/chaosmos-studio.github.io/actions/runs/38969259339): passed for site commit `fee7905f0a0001b5d3b35c3f94bf4d78f889fdb8`. The deployed HTML carries version 2.
- The development workspace was offline for this update. Execution and screenshots came from CI; no fresh interactive session on the public URL was performed.

The first CI run caught an immediate-refresh save race. The web build now mirrors its small save
snapshot synchronously to browser storage while retaining Godot's filesystem save and native path.

## 0.1 initial release

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
