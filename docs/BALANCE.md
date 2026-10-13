# Ordered matching revision

Version 3 preserves removal order and allows unmatched screws to return to their original panels. Three matching neighbours clear; separated pieces do not. All 36 studies were rebuilt for this rule.

## Collection-only audit

Each rate is the chapter mean of 1,000 attempts per study and policy. Random play chooses uniformly among exposed screws. Greedy play prefers the colour at the right end of the tray, breaking ties randomly. Both stop at a full tray. Neither uses returns, inspection, hints, undo, or lookahead. Separate seeds screen generation and audit the finished campaign.

| Studies | Random wins | Greedy wins |
| --- | ---: | ---: |
| 1–3 | 1.87% | 82.3% |
| 4–12 | 0.01% | 64.6% |
| 13–24 | 0.00% | 38.2% |
| 25–36 | 0.00% | 17.1% |

Returns are deliberately excluded from this audit to measure the importance of collection order. A full tray is recoverable during actual play, so these figures are not player failure rates and are not directly comparable to the earlier auto-sorting campaign. A measured 0% means no wins in this sample, not impossibility.

All 36 studies have a verified winning route and a legal route to a full tray. Every occupied slot can be returned from that full state. The longest independent Python solution search visits 2860 states.

## Regression checks

`python3 tools/audit_levels.py --check` evaluates 72,000 attempts and enforces chapter-specific upper bounds. CI regenerates the campaign and compares both generated levels and audit results with git.

Godot tests verify every winning and full-tray route, separate versus adjacent matches, cascades, panel revival, return-aware hints, exact undo, save migration, and scene completion. Desktop and phone browser tests perform a gap-closing return through actual input, undo it, recover from a full tray, and complete a clean solve using a return. Screenshots include ordered and full trays, help, and the final study.

These checks prevent trivial collection order and rule regressions. They do not measure human difficulty, enjoyment, or retention. Raw results are in [difficulty-audit.json](difficulty-audit.json).
