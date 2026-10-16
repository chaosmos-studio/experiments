# Rules and proof

## A turn

A plant occupies adjacent integer grid cells `p` and `q`. Hold `p`; let `d = q - p`.
For a clockwise quarter-turn, `r = (-d.y, d.x)`; counterclockwise uses `-r`.
The landing cell is `p + r`, and the swept corner is `p + d + r`.
Both must be inside the garden and empty of stones and other seeds. The conservative corner rule
matches the visible quarter-circle clearance of a seed with radius 32 on a pitch of 128.

A seed on its own soil cannot be the moving end. This is derived from coordinates, so there is no
hidden lock flag to drift out of sync. A plant whose two cells match its goal pair is complete and
still occupies those cells. Endpoint order is irrelevant; every pair is stored sorted.

JSON numbers arrive in Godot as floats. Normalize every coordinate to `int` before membership or array
equality checks. A native/browser mismatch found during development demonstrated why this boundary
is part of the rule contract.

## Generation

Seed `16102026`, generator version 1, 4 by 4 boards. Place disjoint target pairs and up to two stones.
Walk backwards from the complete garden. A reverse move may lift a root, but its forward inverse must
be legal: the newly displaced seed cannot be on its own soil. Avoid revisiting states in this walk.
Reject starts with an already rooted seed. Then solve forward with BFS; reverse-walk length is never par.

Thirty boards are selected from 180 accepted candidates across one, two and three plant pools. The
candidate limits are explicit; generation fails rather than weakening the required route range.

## Shortest routes and hints

All edges of the state graph cost one turn. FIFO breadth-first search therefore finds a shortest
solution. State consists only of the sorted occupied pair for each plant. The Python generator and
the separate Godot implementation both solve every shipped board. Native tests replay the stored
witness and check obstacles, overlaps, rooted endpoints and the final state after every move.

The hint solves the current state, not just the opening. It highlights the first move without playing
it. An exhausted search says the current planting is stuck; a search cap has a separate status and is
never called impossible. Undo restores the entire previous state.

## Difficulty

Primary measure: exact minimum turns, 2 through 18, nondecreasing across all 30 boards.
Secondary ranking: `par + log2(1 + discovered BFS states) / 100`. This is a transparent heuristic,
not a validated model of human difficulty. The BFS count depends on the documented move ordering.
No claimed strict increase in what each player feels, and no synthetic difficulty points from level ID.

## Uniqueness

For each board, apply all eight rotations/reflections of the square. Transform stones, starts and
goals together, sort pairs and then sort each plant's `(start, goal)` record to ignore colour labels.
The smallest representation is its canonical signature. Compare all 435 board pairs. This excludes
exact transformed or colour-swapped copies; it does not prove that two different puzzles cannot feel alike.

## Random-play baseline

`tools/audit_levels.py` runs 300 seeded trials per board, choosing uniformly among legal moves, with
a budget of twice that board's optimal route. 1,291 of 9,000 trials solved (14.34%). This is a narrow
anti-triviality diagnostic, not an estimate of human win rate, enjoyment, retention or commercial success.
The first recorded dead end is garden 10; its replay is an actual browser regression test. The audit
also corrupts a solution and duplicates a board to verify that its guards reject both.

## Useful tuning values

- `PITCH = 128` logical pixels; seed radius 32, hit radius 50.
- `SWING_SECONDS = 0.34`; reduced motion uses 0.06 seconds.
- Solver cap: 100,000 discovered states. Largest shipped opening search: 4,831 states.
- Original music: 32 seconds, four eight-second chords, deterministic synthesis at 22,050 Hz.
