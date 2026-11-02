# Handover plan

## Vision

The player shifts between three caretakers in an orbital greenhouse.
Each caretaker keeps doing the task they were given after the player shifts away.
The team restores water, light, and sunrise by maintaining chains of cooperation.

## Current playable draft

The game has an authored beginning, three short puzzle chapters, and an ending.
Touch and mouse both use large illustrated machine and caretaker targets.
The browser build opens in a warm light palette and asks phone players to rotate to landscape.

## Design decisions

The handoff model is deterministic so an assigned task remains active until the chapter ends.
The scene presents one greenhouse view with chapter-specific tasks.
We chose this over platform movement because task relationships need to read clearly on a phone.
The stage definitions live in `scripts/handover_model.gd`, separate from drawing and input.

## Next questions for playtesting

Does shifting feel satisfying after the first chapter?
Would the player rather solve a spatial route, a timing problem, or a more open machine network?
Do the three caretakers feel distinct enough to support a longer jam game?

## Jam scope

Build a stronger playable loop, deepen the character handoffs, and author a short story during the jam.
Publish a browser build and source on GitHub, then submit the game on itch.io with AI use disclosed.
