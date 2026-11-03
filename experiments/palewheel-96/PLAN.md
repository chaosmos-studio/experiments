# Palewheel 96 comparison

## Intent

The player is a gravity mechanic trying to restart a failing orbital engine.
The signature move turns gravity by a quarter turn.
That turn also trades solid and ghosted bridges, pushes loose cargo, pauses moving drones, and sends a visible pulse across the chamber.
The player collects light to open each exit, with beacons preserving progress after a hit.

## Direction

This experiment keeps Palewheel's gravity mechanics and room routes so the player can judge the effect of a different visual and musical direction.
It uses a limited copper, teal and aubergine palette, visible square pixels, a hand-pixeled mechanic, engine props, blocky UI controls, and an original four-voice game loop.
Jump height follows the hold time, and gravity turns preserve momentum while the character art rotates into the new orientation.
The touch controls sit over the full-screen playfield.

## Structure

`scripts/level_data.gd` owns authored room geometry and goals.
`scripts/game_controller.gd` owns progress, pickups, hazards, checkpoint state, and gravity shifts.
`scripts/player.gd` owns courier movement and visual motion.
`scripts/cargo.gd` applies gravity to the movable block.
`scripts/sentry.gd` owns watcher patrol, collision, and freeze timing.
`scripts/world_view.gd` draws the engine chamber and gameplay objects over pixel-art backgrounds.
`scripts/hud.gd` owns touch controls, status, hints, and panels.

## Scope

The main Palewheel project is the home of campaign expansion and movement tuning.
This project provides a playable style comparison.
