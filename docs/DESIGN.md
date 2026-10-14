# Filament

The user found Tessera buggy and too close to Rivet's tray-and-board presentation.
Filament replaces that interaction with continuous, direct manipulation: pull knots
in a living web until none of its strands cross. No pieces are added or consumed.

The earlier research suggested visible disorder becoming order, short sessions,
clear immediate feedback and touch-friendly interaction. Those are the parts kept.
Untangling is a deliberate design experiment; the research does not establish it as
one of the three biggest puzzle markets. It is not a new random category draw.

## Rules

Move circular knots anywhere in the play area. Square knots are anchored. Strands
may cross while moving. Release the last knot when every crossing and contact is
clear. Unrelated strands cannot overlap, knots cannot pile up, and a knot must stay
clear of unrelated strands. Shared endpoints are allowed. Multiple valid shapes
can solve a web; there are no hidden destination slots.

Each drag is one move. Undo restores the whole previous layout. There is no timer
or irreversible failure. Geometry, not move count or animation, decides completion.
Hints show a useful move from the current state; in a local minimum they indicate
one knot's position in a verified solution, which may temporarily increase tangles.
Hints never move knots automatically. All twelve webs are available from Webs.

## Feedback and controls

Crossed strands glow coral and crossing points carry diamonds. Clear strands glow
blue; a finished web turns green. Light travels along the lines, knots pulse on
contact, and the completed web releases a short particle burst. The geometry stays
straight and stable so the drawn crossings agree with the rules. Motion can be
reduced, and sound can be muted. Both preferences persist.

Touch is handled directly, with one active finger. Mouse emulation is disabled to
avoid duplicate touch actions. Overlapping knots cycle selection so a knot cannot
become permanently hidden. Loss of focus cancels an unfinished drag. Bounds keep
knots inside the playable area. A win only triggers after release, so moving through
a clear intermediate arrangement cannot steal control.

Keyboard: Tab cycles knots, arrows move, Shift gives finer movement, Enter releases,
Escape cancels, U undoes, H hints, R resets, L opens the web list.

## Content and verification

Twelve authored planar graph families have deterministic scrambled layouts. The
first four introduce direct movement; the middle four add anchors and nested webs;
the last four increase density. All have valid geometric witnesses, checked in both
Python and Godot. This verifies solvability, not enjoyment or human difficulty.

Native tests cover degenerate geometry, all campaign witnesses, anchors, clamping,
coincident knot selection, multi-finger ownership, cancellation, undo, release-only
completion, keyboard input and persisted progress. Playwright exercises exported
Godot through real mouse and touch events on desktop and phone viewports, including
a real solve, reset, undo, help, settings and an anchored late-game web.

No account, ads, analytics, remote assets, purchases, or energy timers.
