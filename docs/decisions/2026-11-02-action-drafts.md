# Game Off action drafts: decisions

| Decision | Choice | Why | Revisit when |
| --- | --- | --- | --- |
| Scope | Two short playable slices | The next step is choosing a concept by feel | One concept moves to its own repo |
| Dimension | 2D portrait | Both mechanics need one thumb on a phone | A concept needs a wider playfield |
| Language | GDScript | Godot 4.7 web exports support it | The target engine changes |
| Authority | Single player, local state | Each run stands alone | A shared score becomes useful |
| Art | Procedural shapes and a bundled font | The mechanics should be judged before asset work | A concept is selected |
| Input | Flipline uses a tap, Timefall uses drag and a time shift button | Their control feel should differ | Phone play reveals missed touches |
| State | One enum and a small model per game | Each slice has start, play, and crash states | The run gains more distinct phases |

## Open / deferred

- Persistent scores are assumed unnecessary for these drafts.
- Sound is assumed useful, but each game must play without it.
- The concepts are assumed to stay in this experimental repo until Shravan chooses one.
