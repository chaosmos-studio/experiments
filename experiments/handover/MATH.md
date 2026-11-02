# Handover systems

## Task dependencies

Each chapter lists a caretaker for each machine and the index of a machine that must already be active.
A machine with `-1` as its prerequisite is available at the start.
An assignment succeeds when the selected caretaker matches its owner and its prerequisite is still active.
The chapter clears when every machine is active at once.
This is a small state machine, so the same rules can be checked without rendering the scene.

## Screen coordinates

The art and tap targets are authored on a 1920 by 1080 canvas.
The game scales by `min(viewport_width / 1920, viewport_height / 1080)` and centers the result.
Input uses the inverse transform to keep touch and mouse targets aligned with the art.
