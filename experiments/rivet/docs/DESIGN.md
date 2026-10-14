# Rivet

Remove exposed screws from overlapping panels. Keep their order in a seven-slot tray and clear matching neighbours.

## Rules

- A collected screw joins the right end of the tray. Pieces never sort themselves.
- Three adjacent screws with the same colour or symbol disappear. Separated matches remain.
- Tap any unmatched tray screw to return it to its original hole. The remaining pieces close the gap and any new triples clear, including cascades.
- A panel disappears when its last screw is removed. Returning an unmatched screw restores that panel, which may cover lower screws again. Matched screws cannot be returned.
- A covered screw cannot be collected. Coverage uses its centre and active panels above it.
- Seven unmatched screws block further collection. The tray stays interactive: return a screw, undo, inspect, or request a hint. There is no loss overlay.
- Both the board and tray must be empty to win.
- Undo restores the exact previous board, tray order, set count, and peak occupancy. Returns are ordinary moves and can also be undone.

For example, A B A A stays in the tray. Return B and the remaining A A A clears.

## Hints and progress

Hints first search for a forward solution from the current ordered tray. If needed, they test single returns and front/back return sequences, each followed by a forward search. A hint always has a verified winning continuation; the bounded search is not exhaustive. If no route is found within its budget, it suggests returning or undoing without claiming the puzzle is impossible.

Inspect shows remaining colours on each numbered panel, including covered screws. It does not count as a hint. A solve without hints or undo earns a filled completion mark; other completion earns an outline. Returns do not disqualify a clean solve. The result shows the number of return actions taken, including returns later undone.

Campaign version 3 rebuilds all 36 studies for ordered matching. Each records a seed, a winning collection sequence, and a sequence that fills the tray. The first study also records a verified gap-closing return example. Generation screens random and greedy collection policies, then a separate audit checks fresh samples. See [difficulty results](BALANCE.md).

- Studies 1–3: Learn, three colours.
- Studies 4–12: Plan, four colours.
- Studies 13–24: Think ahead, five colours.
- Studies 25–36: Master, six colours.

Old campaigns restart at study 1 with fresh completion. Earlier completion records remain in `legacy_completion`, keyed by campaign version. Sound and motion preferences survive. Version 3 completion persists normally; an in-progress board resets on reload.

## Presentation and controls

A warm paper workbench, muted panels, coloured heads, and six stamped symbols. Numbered slots and arrows show tray order. Tap a board screw to collect; tap a tray screw to return. Arrows select a board screw, Enter collects, 1–7 return tray slots, U undoes, H hints, I inspects, R restarts, and M toggles sound. Sound and motion can be disabled.

All code, vector drawing, and synthesized sound were created for this repository. The other three games informed mechanics and web-export configuration only.

## Architecture

- `scripts/puzzle.gd`: pure transitions and solver; state contains a removal mask and ordered screw IDs.
- `scripts/main.gd`: drawing, input, animation, undo, and local persistence.
- `data/levels.json`: generated campaign and witness routes.
- `tools/generate_levels.py`: deterministic generation and candidate screening.
- `tools/audit_levels.py`: independent solver, simulations, and difficulty gates.
- `tests/run_tests.gd`: rules, solver, returns, controller, and save migration.
- `tests/browser/game.spec.js`: actual desktop and touch input in the exported game.
- `tools/prepare_web.py`: splits the engine binary into static-host-friendly chunks and verifies byte equality.

No physics simulation, accounts, multiplayer, monetization, or endless mode. Human difficulty and enjoyment still need play feedback.
