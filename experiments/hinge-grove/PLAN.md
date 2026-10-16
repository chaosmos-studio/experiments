# Hinge Grove

## Vision

A tiny living puzzle: swing paired seeds into their soil, then watch them bloom. The move is readable
in a few seconds; rooting makes the sequence matter. One hand, short sessions, thoughtful mistakes.

## Pillars

- Show cause and effect: one seed stays, its partner follows a quarter-circle.
- Make decisions count: planted seeds become permanent hinges and can obstruct another route.
- Make recovery kind: instant undo, free hints, no timer or lives.

## Scope

A standalone Godot 4.5.2 prototype in the existing experiments repository and CI. Match the repository's
pinned engine instead of migrating the archived games. The established studio games, including Pyxis,
remain separate. This prototype has no ads, accounts, purchases, tracking SDKs or store release.
The 500-level Pyxis campaign is not a requirement to duplicate before testing this new mechanic.

## Mechanics

Each plant is a pair of neighbouring seeds joined by a stem. Select the seed that stays still, then
select the partner's landing spot. A quarter-turn needs a clear destination and swept corner.
The cells of a matching soil pair root that plant's seeds. A rooted seed cannot move. Both rooted
seeds bloom and remain on the board. Stones and other plants block movement.

Touch/mouse: two taps, or drag the moving seed to a legal landing spot. Keyboard: arrows select a cell,
Enter selects/acts, Z undo, R reset, H hint, Escape closes a sheet. One touch owns a gesture.

## Content

Thirty generated gardens: six single-plant lessons, twelve two-plant puzzles, twelve three-plant
puzzles. The concepts deepen through interference and planting order. They do not pretend to be
thirty different mechanics. All are open for playtesting. Shortest routes never decrease; no exact
rotation/reflection/colour-renaming duplicate is allowed. Perceived difficulty still needs people.

## Presentation

Warm paper, sage soil, green/terracotta/blue plants. Plain Manrope at two weights. The seeds and soil
also carry circle/diamond/cross marks. Gentle swing easing, leaf movement, rooting and blooms.
An original 32-second score and short turn/root/bloom/undo sounds. Music and effects mute separately;
reduced motion removes leaf sway and shortens turns. Progress is local to this browser/device.

## Architecture

- `scripts/puzzle.gd`: pure rules and BFS; coordinates normalized to integers at the JSON boundary.
- `scripts/main.gd`: input, drawing, animation, saves, audio and read-only browser diagnostics.
- `tools/generate_levels.py`: seeded reverse construction, exact BFS, symmetry filtering.
- `tools/audit_levels.py`: independent re-solve, witness/mutation checks, random-play baseline.
- `tests/`: native rules and real desktop/touch browser input.

## Milestones

- M0 mechanical gate: done. Real choices, legal dead ends, independently proven solvability.
- M1 playable loop: done. Swing, root, bloom, undo, reset, hint, next, gallery, ending.
- M2 presentation and web verification: done. CI passed; the published mobile preview was played successfully on 16 October 2026. See `docs/VERIFICATION.md`.
- M3 human fun test: pending. Do not scale the content or add monetization before this passes.

## Playtest decision

Targets, not measured results: with 8-12 new testers, at least 80% should make a first move without
spoken help in 20 seconds, at least 70% should finish garden 3 unaided, and at least half should choose
to continue after garden 6. Ask each to explain rooting in their own words. Measure time, mis-taps,
undo frequency, hint use and voluntary continuation. Record no personal data in the game.

Test two honest short clips of the actual game: a clean swing-to-bloom and a wrong early planting
rescued by undo. A small prototype sample cannot establish market retention or predict popularity.

Kill or change the concept if players cannot distinguish the hinge from the moving seed, if rooting
feels arbitrary despite its visible marks, or if solving feels like aimless tapping. Consider a drag-first
guide or fewer choices before producing more levels. Keep the generator seed fixed while comparing UI.
