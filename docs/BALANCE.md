# Difficulty revision

Player feedback: arbitrary clicking was enough to finish the game. The original first four studies used only three colours, so the maximum unmatched count was six. A seven-slot tray could never overflow. Several later boards also offered little resistance to immediate matching.

The replacement campaign uses four to six colours, screened overlap layouts, inspection of covered colours, and a visible goal of solving without hints or undo.

## Measured behaviour

Each rate below is the mean across a chapter, with 1,000 attempts per study and policy. Random play chooses uniformly among exposed screws. Greedy play prefers a third matching screw, then a second, breaking ties randomly. Neither policy uses inspection, hints, undo, or lookahead. The generator uses separate seeds and samples from this final audit.

| Studies | Old random wins | New random wins | Old greedy wins | New greedy wins |
| --- | ---: | ---: | ---: | ---: |
| 1–3 | 100.0% | 33.3% | 100.0% | 87.3% |
| 4–12 | 54.2% | 8.4% | 98.2% | 63.9% |
| 13–24 | 18.1% | 1.0% | 92.6% | 30.3% |
| 25–36 | 5.2% | 0.1% | 86.1% | 17.0% |

Study 1 changed from 100% random wins to 34.7% in this sample. All 36 boards retain independently verified winning routes and legal losing routes. The longest Python solution search in the audit visits 132 states. A measured 0% means no wins in 1,000 trials, not proof that random victory is impossible.

## Regression checks

`python3 tools/audit_levels.py --check` audits 72,000 attempts in total and enforces chapter-specific upper bounds for random and greedy success. CI also regenerates the campaign and compares the generated data and audit record with git.

The Godot tests exercise winning and losing routes for every study, save migration, assistance tracking, and the real loss/undo/win screens. Desktop and phone browser tests lose the first study through actual input, undo the loss, inspect covered colours, complete a planned route, and capture the last study and its full inspection list.

These checks address trivial completion. Human difficulty, clarity, and enjoyment still need play feedback. No analytics or player tracking were added. Raw per-study results are in [difficulty-audit.json](difficulty-audit.json).
