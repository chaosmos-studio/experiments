# Flipline

## Concept

Run through a neon city while gravity pulls toward one of two rails.
Tap to reverse gravity before the next barrier reaches the runner.
The run ends on contact, and passing a barrier adds to the score.

## Slice

- One portrait arena with a start, run, and crash loop.
- Touch anywhere to start, shift gravity, or retry.
- Space shifts gravity on desktop.
- Procedural skyline, moving barriers, trails, and short generated sounds.

## Implementation

- `scripts/run.gd` owns motion, collision, and scoring.
  Skills: `godot-prompter:math-essentials`, `godot-prompter:state-machine`.
- `scripts/main.gd` draws the world and maps input into model actions.
  Skills: `godot-prompter:2d-essentials`, `godot-prompter:input-handling`, `godot-prompter:responsive-ui`.
- The web shell uses the studio's static deployment pattern.
  Skills: `godot-prompter:web-export`, `godot-prompter:export-pipeline`.
