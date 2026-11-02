# Compassfall design

Compassfall is an action puzzle game about restoring light to a clockwork station.
The pilot runs and jumps through a compartment while the player turns gravity ninety degrees at a time.
Each turn also swaps the solid light bridges, and loose cargo falls with the pilot.
Sparks open the exit, and one room asks the player to guide a cargo block onto a plate.

## Player experience

- The pilot has animated idle, running and floating poses made from original Blender renders.
- Every room has a different route through walls, sparks, light bridges and hazards.
- A shift rotates the pilot, changes the force on cargo, swaps the light bridges and sends a visible pulse across the room.
- The light art uses warm paper, teal machinery and brass highlights.
- A restart returns the player to the start of the current room.

## Controls

On desktop, use A and D to move, Space to jump, Q and E to turn gravity, R to restart and P to pause.
On a phone, turn the screen sideways and use the on-screen controls.

## Structure

`scripts/level_data.gd` holds authored room geometry and goals.
`scripts/game_controller.gd` builds each room and owns progress, pickups, hazards and shifts.
`scripts/player.gd` owns movement and pilot animation.
`scripts/cargo.gd` applies the current gravity to the movable block.
`scripts/world_view.gd` draws the clockwork rooms and effects.
`scripts/hud.gd` provides touch controls and game panels.

The current build is a playable Game Off concept draft for the theme SHIFT.
The next design pass should use player feedback to tune room routes, touch controls and pacing before submission.
