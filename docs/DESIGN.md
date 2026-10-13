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

36 deterministic studies, generated with seeds `8900` through `8935`. Generation first chooses a physically valid removal order, then assigns colours while retaining a safe route. Both Python and GDScript verify the recorded routes. The runtime solver independently solves the boards. More colours and panels add complexity; adjacent levels are not promised to be strictly harder.

The first four studies use three colours, so unmatched counts cannot exceed six. This teaches the rules without a failure trap. Later studies use four or five colours and allow real tray overflow.

## Presentation

A warm paper workbench, muted metal panels, coloured screw heads, and six stamped symbols. Sound and motion can be disabled. Mouse, touch, and keyboard are supported. Campaign completion and preferences are saved locally. An in-progress board resets on reload.

All code, vector drawing, and synthesized sound are created for this repository. The other three games were used only to understand mechanics and web-export configuration.

## Architecture

- `scripts/puzzle.gd`: pure rules and bounded depth-first solver, using a 64-bit removal mask.
- `scripts/main.gd`: drawing, input, animation, undo, and local persistence.
- `data/levels.json`: generated campaign and witness routes.
- `tools/generate_levels.py`: deterministic generation and independent verification.
- `tests/run_tests.gd`: rule, solver, and scene-controller tests.
- `tests/browser/game.spec.js`: real exported-game desktop and touch checks.
- `tools/prepare_web.py`: splits the engine binary into static-host-friendly chunks, verifying byte equality.

## Limits

No physics simulation, accounts, multiplayer, monetization, or endless-mode claims. Panel disappearance is a short visual transition, not a physics event. The first build is a playable experiment; market success and retention remain untested.
