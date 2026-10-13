# Rivet

Remove exposed screws from overlapping panels. Three matching screws clear from a seven-slot tray. Clear every panel to finish a study.

## Rules

- A panel remains until all three of its screws are removed.
- A screw is covered when its centre lies under an active panel above it.
- Collected screws are grouped by colour in the tray. Three of one colour clear immediately.
- Seven unmatched screws end the attempt. The seventh screw may complete a triple and clear safely.
- Undo restores the exact board, tray, and set count, including cleared panels and triples.
- Hints search for a winning continuation. A stuck state prompts undo; a search limit never produces an unverified hint.

## Content

36 deterministic studies, each recording its seed, winning route, and losing route. Version 2 replaces the original campaign after play feedback showed that the first four studies could not lose and many later ones required little planning.

Generation retains a safe solution, then rejects layouts that are too easy for random play or for a greedy policy that completes available triples and pairs without looking ahead. Separate fixed seeds screen candidates and audit the final campaign. Both Python and GDScript verify every winning and losing route; the runtime solver independently solves every board. See [difficulty results](BALANCE.md).

- Studies 1–3, Learn: four colours, real tray pressure from the first board.
- Studies 4–12, Plan: five colours and layered choices.
- Studies 13–24, Think ahead: stronger dependencies and five or six colours.
- Studies 25–36, Master: six colours; immediate matching is rarely enough.

The seven-slot rule is unchanged. These are broad difficulty bands, not a claim that adjacent studies are strictly ordered by human difficulty. Simulation is a regression check, not proof that a puzzle is enjoyable.

Inspect shows remaining colours for every numbered panel, including covered screws. It does not remove pieces or reveal a solution and does not count as a hint. Players can plan with visible information rather than guess. A solve without hints or undo earns a filled completion mark; assisted completion earns an outline. There are no limits on assistance.

Campaign version 2 starts old saves at study 1 with a fresh completion record. Previous completion is retained in `legacy_completion`; sound and motion preferences are preserved. New-version progress persists normally.

## Presentation

A warm paper workbench, muted metal panels, coloured screw heads, and six stamped symbols. Sound and motion can be disabled. Mouse, touch, and keyboard are supported. Campaign completion and preferences are saved locally. An in-progress board resets on reload.

All code, vector drawing, and synthesized sound are created for this repository. The other three games were used only to understand mechanics and web-export configuration.

## Architecture

- `scripts/puzzle.gd`: pure rules and bounded depth-first solver, using a 64-bit removal mask.
- `scripts/main.gd`: drawing, input, animation, undo, and local persistence.
- `data/levels.json`: generated campaign and witness routes.
- `tools/generate_levels.py`: deterministic generation and candidate screening.
- `tools/audit_levels.py`: independent solver, random/greedy simulations, and difficulty gates.
- `tests/run_tests.gd`: rule, solver, and scene-controller tests.
- `tests/browser/game.spec.js`: real exported-game desktop and touch checks.
- `tools/prepare_web.py`: splits the engine binary into static-host-friendly chunks, verifying byte equality.

## Limits

No physics simulation, accounts, multiplayer, monetization, or endless-mode claims. Panel disappearance is a short visual transition, not a physics event. The first build is a playable experiment; market success and retention remain untested.
