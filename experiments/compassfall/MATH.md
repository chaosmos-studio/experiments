# Compassfall mechanics

The pilot's gravity is a unit vector that points down, left, up or right.
Each shift rotates it by ninety degrees and rounds the result to a cardinal direction.
Running follows the tangent to gravity, so the same left and right controls work on every surface.
Jumping pushes against gravity.

The cargo applies force along the same gravity vector each physics frame.
Light bridge collisions swap state on each shift.
The pilot keeps a short jump buffer and coyote window so a button press near an edge still feels responsive.

The current movement constants and their actual behavior live in `scripts/player.gd` and `scripts/cargo.gd`.
Tune them by playing through every room, especially after consecutive shifts.
