# Difficulty checks

All 18 boards have independently verified winning and losing routes. Pieces and starting boards are fixed, so a restart is the same puzzle.

Generation screens candidates with separate simulation seeds. The final audit runs 500 attempts for each policy on each board: 18,000 runs total. Random play chooses uniformly among legal piece placements. Greedy play chooses an immediate maximum-line clear, breaking ties randomly. Neither looks ahead or uses undo or hints.

| Chapter | Random wins | Greedy wins |
| --- | ---: | ---: |
| Learn | 8.5% | 54.1% |
| Plan | 3.6% | 42.4% |
| Master | 1.1% | 17.8% |

Later boards are ordered into two bands by the audited greedy win rate. This does not imply a strict human difficulty ranking.

The gap shows that placement decisions matter in these simulations. It does not prove human difficulty or enjoyment. Human play feedback remains the deciding test.

`python3 tools/generate_levels.py` regenerates levels, shapes and the audit deterministically. CI compares all three with git. Godot independently solves every board and checks both recorded routes, simultaneous row/column clears, illegal moves, hand transitions, undo and saved progress. Browser tests use actual drag, mouse, touch and keyboard input, including a loss and recovery.

The archive has its own Godot suite and is browser-tested at `/experiments/rivet/`. Raw results are in [difficulty-audit.json](difficulty-audit.json).
