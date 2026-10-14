# Tessera

The screw-sorting concept was rejected after play feedback. Rivet is preserved in `experiments/rivet/`; this experiment starts from block placement, another family in the original research pool. This is a deliberate new choice, not a second random draw disguised as the first.

## Why this direction

Apple's August 2026 Arcade announcement describes Block Blast as a chart-leading puzzle built around placing blocks and clearing rows and columns. Sensor Tower's Q2 2025 US review reports substantial downloads and active users for it. Those sources support the category's reach; they do not establish demand for this particular design.

- [Apple, Block Blast on Arcade, August 2026](https://www.apple.com/newsroom/2026/08/apple-arcade-levels-up-with-block-blast-plus-and-art-of-fauna-cozy-puzzles-plus/)
- [Sensor Tower, US puzzle games Q2 2025](https://sensortower.com/blog/2025-q2-unified-top-5-puzzle%20games-units-us-64bc1644e1714cfff1e615fc)
- [Original three-year review](RESEARCH.md)

Tessera borrows spatial placement and line clearing. Fixed finite piece sets turn it into short, replayable puzzles. It uses no screws, sorting tray, tilt movement, radial chain reactions, or directional escape, so the core action differs from Rivet, Plumb, Carillon, and Apsis. Code and art are original; no assets or implementation from those three repositories were copied.

## Rules

Place upright pieces on empty cells of a six-by-six board. Full rows and columns clear simultaneously, including intersecting lines. Each completed row or column counts toward the target. Colours distinguish pieces but do not affect matching.

Choose any of the three current pieces. The next set arrives only after all three have been placed. Queue shows every upcoming piece; nothing is randomly dealt during play. Reach the line target to win. If no current piece fits, or the final pieces run out before the target, the attempt ends. Undo and restart remain available.

Each board has a verified winning route and a legal losing route. The 18 boards form three broad chapters; adjacent boards are not claimed to be strictly ordered by human difficulty. See [audit](BALANCE.md).

Hints search from the actual board, used pieces and line count. They show a placement only when a complete winning continuation has been verified. The search has a fixed node budget; failure to find a route is not proof that the position is unsolvable. A win without hints or undo earns a clean completion mark. Queue inspection is free.

## Interaction

Select a piece and tap its top-left board cell, or drag it there. The mouse preview marks invalid placements in red and outlines lines that will clear. Pieces cannot rotate. Keyboard: 1–3 select, arrows position, Enter places. U undoes, H hints, R restarts. Sound and motion can be toggled in help. Preferences and completion are local; an in-progress board restarts on reload.

The visual direction uses a dark board, ceramic blocks, mint line-clear feedback and restrained type. The game has no timer, ads, accounts, analytics, energy system or purchases.
