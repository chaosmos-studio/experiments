# Chaosmos Action Lab

Three playable action concepts share one Godot 4.7 project and an original cast of Blender rendered sprites.
Each game has its own movement goal and complete result loop.

## Brassburrow

Walk beside a traveling hearth, harvest copper pods, place seed cannons and survive three beetle waves.
Move with WASD or arrows, strike with J or click, dash with Space, build with K and repair with R.

## Veilmarket

Borrow a shopper's appearance, stun wardens, gather three sealed parcels and reach the gate.
Move with WASD or arrows, blend with Q, stun with J or click and dash with Space.

## Threadrail

Swing from post to post across floating islands.
Move with WASD or arrows, hook or release with J or click, toggle reeling with Q and dash with Space.

On a phone, turn sideways and use the joystick and action buttons.

## Run and verify

Run `godot --path .` from this directory for Brassburrow.
Pass `-- game=veilmarket` or `-- game=threadrail` after Godot options to open another mode.
The three headless smoke scenes in `tools/` cover the core actions and result loops.
Export the Web preset to `build/web/index.html` after importing the assets in Godot.
The browser build selects a game with `?game=brassburrow`, `?game=veilmarket` or `?game=threadrail`.

## Art and audio

`tools/render_assets.py` builds and renders the character and prop models in Blender.
`tools/make_audio.py` synthesizes the original sound effects and music from waveforms.
Lilita One and Baloo 2 are included under the SIL Open Font License in `assets/fonts/`.
Made with the help of AI tools.
