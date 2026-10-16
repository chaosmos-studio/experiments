# Why Hinge Grove

Research and decision: 16 October 2026. A new experiment, separate from Pyxis.

## What is working in puzzle games

The useful signal is a readable action with a visible consequence, enough ordering decisions to
support short levels, and a satisfying transformation. It is not simply that a game contains blocks,
screws or a conveyor. Commercial rankings also reflect advertising, distribution and live operations.

| Evidence | What it tells us | Limit |
| --- | --- | --- |
| [Sensor Tower, September 2026](https://sensortower.com/blog/top-10-worldwide-mobile-games-by-revenue-and-downloads-in-september-2026) | Block Blast ranked third in worldwide downloads; Bus Fever Party ranked fifth and led download growth. Candy Crush and Gossip Harbor remained among the five highest revenue games. | These are estimates for one month. Downloads do not establish retention, profit or organic demand. |
| [Sensor Tower, May 2026](https://sensortower.com/blog/top-10-worldwide-mobile-games-by-revenue-and-downloads-in-may-2026) | Arrows Puzzle Escape led downloads, followed by Block Blast. The report connects the arrow game's acceleration with increased paid acquisition. | A clear rule can advertise well, but paid reach is not evidence that copying it will grow organically. |
| [AppMagic, Mobile Market Landscape 2026](https://appmagic.rocks/files/view/upload/Reports/EN_MobileMarkeLandscape2026.pdf), especially p. 56 | Comparing 2025 with 2024, Sort Puzzle downloads rose 41% and revenue approximately 2.1 times. Block Puzzle revenue grew about 12 times and downloads about 1.9 times. Physics Puzzle revenue nearly doubled while downloads rose roughly 3%. | The report estimates store downloads and in-app purchase revenue. It excludes advertising revenue and web purchases; the subgenres have different starting sizes. |
| [Scopely, 19 February 2026](https://www.scopely.com/en/news/scopely-to-acquire-majority-stake-in-breakout-mobile-game-pixel-flow-and-the-development-team-behind-it) | The publisher reported more than ten million Pixel Flow players and a US monthly top-20 grossing position within months of launch. | A publisher announcement, not an independent experiment or a forecast for a new studio. |

These sources cover the 2024-2025 shift and the latest completed month of 2026. Rankings, revenue
estimates, publisher player counts and individual reviews are different evidence, not interchangeable
measures of popularity. The first two are useful for choosing what to investigate; none proves that
a particular new mechanic will succeed.

The [official Pixel Flow listing](https://play.google.com/store/apps/details?hl=en_IN&id=com.loomgames.pixelflow)
shows a particularly clear loop: choose a coloured shooter, send it around a conveyor, remove matching
cubes, manage limited ammunition and five waiting slots. Its appeal is an inference from that visible
interaction: a small decision produces a large, legible change. Some visible reviews object to forced
losses, boosters and audio interruptions. Those anecdotes are useful failure hypotheses, not a survey.

## What we should borrow

1. One action that can be understood in a short, honest gameplay clip.
2. A board whose changing state is immediately visible.
3. Decisions about order and space, with consequences beyond the next tap.
4. A compact success moment that rewards the action itself.
5. Fast, fair recovery while learning. This prototype uses free undo and hints.

What we should not infer: that a conveyor, sorting tray or trendy theme is sufficient; that longer
solutions necessarily feel harder; or that a polished prototype establishes retention. There is no
defensible numerical probability of commercial success from these sources.

## Candidate and competition screen

The search covered official mobile store listings, developer pages and a research paper on the
closest abstract operation. Alternatives were rejected when an existing game already closely matched
the proposed hook, or when the action repeated this studio's games.

| Candidate | Closest source found | Decision |
| --- | --- | --- |
| Fold strips to match a shadow | [Shadow Fold](https://apps.apple.com/us/app/shadow-fold/id6761526112), tap folds to match silhouettes | Too close to an existing product. |
| Move a delayed or mirrored partner | [Mirror Desync](https://apps.apple.com/us/app/mirror-desync-echo-puzzle/id6766522250), simultaneous echo movement | Familiar coupled-character territory; also risks resembling Plumb's global manipulation. |
| Fold a coloured board into a target | [Fold the Grid](https://play.google.com/store/apps/details?id=com.rjreedstudios.fold), folding and colour blending | A direct overlap, rather than a useful new experiment. |
| Swap ink between a stamp and paper | [Borrowed Ink](https://morassgames.com/games/borrowed-ink/), two-cell stamp and target image | Very close to the proposed interaction. |
| Alter weights to balance a scene | [Counterweight](https://play.google.com/store/apps/details?id=com.flash.counterweight), mass changes followed by simulation | Existing hook, with a less predictable mobile input and physics tuning burden. |
| Pivot paired seeds; matching soil permanently roots them | [Gourds](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ISAAC.2020.33), domino-like piece reconfiguration | Keep the pivot, add irreversible planting as the central planning constraint. |

Gourds matters: turning connected pairs is not a new invention. That paper studies pieces on a
hexagonal board with one vacant cell and slide/turn/pivot operations. Hinge Grove uses a square board,
quarter-turns with a clear swept corner, multiple vacancies, plant-specific soil and permanent roots.
The proposed distinction is this combination and its garden presentation. The search did not reveal
an exact match, but that does not prove none exists.

Within Chaosmos, this avoids global marble tilting (Plumb), musical pop chains (Carillon), arrow escape
(Apsis), Pyxis's existing identity, screw extraction and tray order (Rivet), and placing supplied blocks
onto a board (Tessera). There is no piece inventory beneath the board. Every action rearranges the
living board itself.

## The selected hypothesis

**Swing a seed. Grow a garden.** Each plant has two neighbouring seeds. Hold one, swing the other a
quarter-turn. Put both on matching soil and they bloom. The first seed to reach its soil takes root,
so an apparently helpful move can permanently close a route for another plant.

This creates a visual promise and a planning problem in the same action: growth changes the board's
future possibilities. Animation follows the exact movement, and roots show why a seed cannot move.
Undo is available because experimenting should teach the rule, not consume a currency.

The theme is an inference-driven design choice, not a researched claim that gardens outperform other
themes. Warm paper and sage keep the board quiet; green, terracotta and blue separate plants. Circle,
diamond and line marks repeat on seeds and targets so colour is not the only cue. Manrope keeps labels
plain. An original gentle score and short interaction sounds make completion perceptible without a
large celebration layer. Music, effects and reduced motion have separate controls.

## What this build establishes

Thirty levels are enough to test the mechanic across one, two and three interacting plants. Each has
an exact BFS shortest route in both Python and Godot. Minimum turns never decrease (2 to 18). The
campaign rejects duplicates under every square rotation/reflection and plant-colour relabelling.
These are objective checks; they do not establish strictly increasing perceived difficulty.

The independent audit tries 300 random legal walks per level, each capped at twice its shortest
solution. It solved 1,291 of 9,000 runs (14.34%) and records a reachable dead end. This specifically
tests the earlier experiment's problem that random action always wins. It is not a human completion
rate, a measure of fun, or a market forecast. See [audit.json](audit.json) and [MATH.md](../MATH.md).

Native tests verify the rules and all shortest routes. Real browser input tests cover desktop and
touch, early and late puzzles, a rooted mistake, undo, hints, the ending, keyboard controls, saved
preferences and actual audio output/muting. This establishes a working prototype, not device-fleet
coverage or a store-ready release.

## What remains unknown

The biggest risks are hinge-versus-moving-seed confusion, rooting feeling punitive, repetitive-looking
boards, and players solving by trial without understanding the constraint. Longer shortest paths do
not resolve those risks. We need people to explain the rule and voluntarily continue.

The next gate is 8-12 fresh testers: aim for 80% to make a first move without spoken help in 20 seconds,
70% to finish garden 3 unaided, and at least half to choose another garden after garden 6. These are
proposed decision thresholds, not measured results. Record time, mis-taps, undo and hint use during
consented observation; the game itself contains no analytics SDK. Ask whether an early root felt like
their decision or an unexpected punishment.

Compare two short recordings of real play: a clean swing-to-bloom, and a mistaken early planting
rescued by undo. Do not use invented interactions, fake reviews or fabricated performance metrics.
Only expand the campaign or consider a store release after the comprehension and voluntary-play gate.
See [PLAN.md](../PLAN.md) for the decision criteria.
