# Timefall

## Concept

Fall through a tower of descending light gates.
Drag to steer into each opening, then shift into slow time when the route changes sharply.
Slow time uses charge that returns during normal flight.

## Slice

- One portrait descent with a start, run, and crash loop.
- Drag anywhere in the playfield to steer left or right.
- Tap the SHIFT TIME button to toggle slow time.
- Procedural light gates, depth streaks, trails, and short generated sounds.

## Implementation

- `scripts/descent.gd` owns gates, charge, collision, and scoring.
  Skills: `godot-prompter:math-essentials`, `godot-prompter:state-machine`.
- `scripts/main.gd` draws the world and maps touch and keyboard input into model actions.
  Skills: `godot-prompter:2d-essentials`, `godot-prompter:input-handling`, `godot-prompter:responsive-ui`.
- The web shell uses the studio's static deployment pattern.
  Skills: `godot-prompter:web-export`, `godot-prompter:export-pipeline`.
