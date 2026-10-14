# Puzzle games, 2023–2026

Research date: 13 October 2026.

## Scope and method

The requested three-year window is 13 October 2023–13 October 2026. Most public market datasets use calendar years or half-years, so this review uses late-2023 context, 2024 and 2025 results, and available 2026 evidence. Full-year 2026 results do not yet exist. Figures that cover all of 2023 are context, not exact measurements of the requested window.

“Popular” can mean downloads, paying demand, active play, or cultural visibility. These measures answer different questions. This review keeps them separate rather than inventing a combined worldwide ranking. Mobile has the strongest public category data and is especially relevant to a touch-friendly browser experiment. Web and premium PC puzzles provide additional design context.

Priority went to market-data publishers, developer/publisher pages, store listings, and direct interviews. Secondary reporting fills gaps where original reports could not be fully retrieved. AppMagic pages sometimes returned an empty body; their indexed extracts were available. Such figures are marked below. No paid analytics dashboard was accessed.

Revenue figures are the source's estimated in-app purchase revenue, not total developer profit or proof of active users. Advertising, platform fees, direct payments, tax, geography, and third-party Android stores are not consistently included across sources. Do not add these estimates together or compare their absolute values across providers. Downloads are installations, not unique people. Puzzle plays are repeat sessions, not player counts.

## What has been popular

| Puzzle family | Evidence in the window | What the evidence supports | Representative games |
| --- | --- | --- | --- |
| Match-3 | AppMagic's 2025 indexed report: about $4.8B IAP revenue, 811M downloads; revenue broadly flat and downloads down 8% [1]. | The strongest established revenue category in this comparison. Mature and difficult to enter. | Royal Match, Candy Crush Saga, Gardenscapes |
| Merge, especially Merge-2 | The same 2025 report estimates $1.4B IAP revenue, up 80%, and 507M downloads, up 9% [1]. | Strong commercial growth; not merely a short download spike. | Gossip Harbor, Travel Town, Seaside Escape |
| Block placement and line clearing | Sensor Tower placed Block Blast third among worldwide mobile-game downloads in July 2026 [4]. Its developer reports 70M daily and 300M monthly active users on its current site [5]. | Very large reach. The active-user figures are publisher-reported, not independently audited here. | Block Blast |
| Sorting | AppMagic's H1 2024 analysis describes 12-fold year-on-year revenue growth in its Tier-1 West scope [2]. A secondary summary of its 2025 report gives $279M IAP revenue [3]. | An important fast-growing family, smaller in IAP than Match-3 or Merge. | Goods Puzzle: Sort Challenge, water/ball/goods sorting variants |
| Screw and disassembly | A secondary summary of AppMagic's 2025 report gives $177M IAP revenue and says Sort and Screw doubled revenue relative to 2024 [3]. | A growing commercial puzzle format, not one of the three largest categories by revenue. | Screw Jam, layered screw-removal variants |
| Match-2 / blast | AppMagic's 2025 indexed report gives $466M IAP revenue, about 0.8% growth, and 62M downloads, down 32% [1]. | A durable, established audience with slowing acquisition. | Toon Blast, Toy Blast |
| Daily words and associations | A 2024 interview with NYT's games head describes about eight billion puzzle plays in 2023 and Connections becoming its second-most-played game [7]. AP reports 11.2B portfolio plays in 2025, including 4.2B Wordle plays [8]. | Exceptionally strong repeat-play habits across web and mobile; these are plays, not unique people. | Wordle, Connections, Strands, crosswords |
| Arrow escape / obstruction removal | Arrow Puzzle appeared fourth in Sensor Tower's July 2026 global download ranking [4]. | Recent mass-market demand, but unsuitable here because Apsis already uses this core interaction. | Arrow Puzzle and related escape games |

The most defensible high-level answer is: Match-3 leads established spending, Merge leads major-category growth, block puzzles show exceptional mass reach, and sorting/screw puzzles are important emerging families. Daily word games lead a separate habit-driven web audience. There is no evidence here for one universal top-three list across all platforms and metrics.

## How the picture changed

### Late 2023: familiar matching, expanding daily habits

Sensor Tower's Q4 2023 US Android review shows Royal Match and Candy Crush sustaining substantial weekly revenue. This is a regional platform slice, not a global ranking [6]. Together with the NYT interview, it shows two viable patterns entering the window: long-running level-based games and short daily rituals [7].

Design implication: a mechanic does not need to be newly invented to support a new experiment. Clarity, pacing, level quality, and presentation matter. That is an inference from continued engagement with established formats, not a measured causal effect.

### 2024: growth shifted within puzzle

AppMagic's H1 2024 Tier-1 West analysis describes rapid sorting growth and Merge-2 monetization growth. It also reports that four incumbents held 84% of Match-3 Meta revenue in that regional scope [2]. This is useful evidence of concentration; it should not be relabelled as an 84% worldwide share.

Sensor Tower's broader 2024 review reports total mobile-game downloads falling while time spent and sessions rose. That context suggests acquisition and engagement were moving differently; it does not prove that every puzzle subtype retained users better [9].

### 2025: mature leaders and expanding alternatives

The data in the table shows mature Match-3 alongside growing Merge. Sorting, blocks, and screws gained commercial weight from smaller starting points [1,3]. The secondary report also says only four of 367 newly launched Match-3 games exceeded $100K monthly revenue even once in 2025 [3]. That threshold is a revenue observation, not a profitability measure or a probability forecast for this project.

Design implication: borrow an understandable matching reward, but avoid building a content-heavy Royal Match-style business around an untested prototype. A small, complete core loop can be evaluated much sooner.

### 2026 to the research cutoff: both incumbents and simple formats persist

In July, Sensor Tower placed Gossip Harbor and Royal Match in the worldwide mobile revenue top five, and Block Blast and an arrow puzzle in the download top five [4]. This supports persistence across different business models. One month is not enough to rank the entire year.

AppMagic's July 2026 analysis identifies Sort, Block, and Screw as a newer wave beside the established Match-3, Merge, and Blast families [10]. Its existence and framing corroborate the emerging-family shortlist; exact additional numbers were not recoverable from the opened page and are not asserted here.

## Web, PC, and regional limits

Poki's Blocky Blast page identifies an April 2024 release, desktop/phone/tablet support, and a large cumulative vote count [11]. This is useful evidence that the interaction transfers to browsers. Votes are neither monthly users nor downloads, and the current count does not isolate the three-year period.

Blue Prince's publisher describes a mixture of room drafting, mystery, strategy, and puzzles, released in April 2025 [12]. It demonstrates a premium direction with deeper discovery and a much larger authored-content burden. Its publisher page is not market-share evidence. This research does not equate acclaim, store reviews, or awards with mass popularity.

Sudoku, nonograms, jigsaws, escape rooms, and spatial adventures remain relevant design references, but the retrieved evidence does not support ranking their worldwide 2023–2026 audiences alongside the mobile categories above. They are left unranked rather than assigned invented scores.

India is a significant mobile acquisition market: Sensor Tower reports it accounted for 16.4% of all mobile-game downloads in July 2026 [4]. That does not establish an India-specific puzzle ranking. A language-light interface, legible phone controls, and limited asset sizes are sensible product choices, but should be tested with actual target players.

## Design lessons and tradeoffs

These are design judgments, not claims that research has established a causal formula for success.

| Pattern | Useful part to borrow | Cost or risk | Decision for this experiment |
| --- | --- | --- | --- |
| Matching | A small, immediately visible completion reward | Familiarity can become sameness | Use three-of-a-kind collection, with the decision in removal order |
| Sorting | Visible order emerging from clutter | Hidden rules and tiny targets frustrate players | Automatically group collected colours; stamp a second identifying symbol on each |
| Layered removal | Each action can reveal new information | Random layouts can be impossible or trivial | Verify all shipped layouts with a solver |
| Finite storage | Simple rules can create planning pressure | A full tray can feel like a punishment | Unlimited undo, restart, and safe-move hints |
| Daily rituals | A natural reason to return | Calendar content and streak systems add maintenance | Save campaign completion first; daily mode is a later experiment |
| Live events and narrative | More reasons to revisit a mature game | Continuous production work, servers, monetization complexity | Keep the prototype focused on the puzzle |
| Calm presentation | Space to think and read the board | Animation can delay interaction or obscure state | Short feedback, optional sound, reduced motion, no timer |

The main testable hypothesis is that revealing a lower layer while completing a triple creates a satisfying two-part reward. The main design risk is that the result feels too familiar to existing screw-sort games. Visual polish alone does not remove that risk. A future experiment could add alternative panel-release conditions, but that would need fresh solvability and usability testing.

## Random selection

The request was interpreted as three randomly chosen popular puzzle families feeding one new game, rather than three separate games. “Top three” and “random” cannot both mean a strict revenue ranking, so popularity was used to qualify the pool, then an equal-probability draw selected three entries without replacement.

Pool, in order: Match-3, Merge-2, Block placement, Sorting, Screw puzzles, Daily word association.

Recorded seed: `1067741102`. Python method: `random.Random(seed).sample(pool, 3)`.

Result: **Screw puzzles, Match-3, Sorting**. The complete record is in [selection.json](selection.json). It was a single draw; the categories were not rerolled to fit the implementation. Blast was excluded because chain-clearing would overlap with Carillon's identity, and arrow escape because it directly overlaps with Apsis.

The prototype borrows the three-of-a-kind reward from matching. It is not a conventional adjacent-swap Match-3 board, and no claim is made that it inherits Match-3 market size or retention.

## Existing-game review and differentiation

The three repositories' READMEs were read directly. Plumb's export preset was also inspected for browser configuration. No source code or assets were copied.

| Existing game | Core interaction observed | Rivet's distinction |
| --- | --- | --- |
| [Plumb](https://github.com/chaosmos-studio/plumb) | Tilt a board; all marbles roll toward matching holes | Individual screw selection; no tilt, rolling, or destination holes |
| [Carillon](https://github.com/chaosmos-studio/carillon) | Tap dots to start spreading musical chain reactions | Three collected items clear in a tray; no spreading activation or rhythm mechanic |
| [Apsis](https://github.com/chaosmos-studio/apsis) | Launch arrows along clear paths around a sun | Depth-layer access and tray capacity; no directional escape or orbital board |

Rivet does share an abstract dependency idea with many puzzles: some actions expose others. Its player action, board state, constraint, matching reward, and failure condition differ from the three supplied games. It is an original implementation of established genre conventions, not a claim of an unprecedented game mechanic.

## Prototype and next research

Rivet ships 36 deterministic generated studies. Early levels teach matching without a possible tray overflow; later levels add colours, more panels, and greater overlap. Every study has a verified completion route, and runtime hints search from the player's current state. Difficulty is not claimed to increase strictly at every level. A solvability proof does not prove that a level is enjoyable.

For a first playtest, observe 5–10 players on phones and desktops. Record whether they understand the first match, attempt covered screws, recognize the tray limit before failing, and use undo to recover. Ask which moment made them want to continue and which felt arbitrary. Do not treat this small sample as a statistically representative retention study.

Suggested next experiments:

1. Compare a seven-slot tray with eight slots, holding the same boards constant.
2. Compare always-visible lower-layer colour previews with concealed colours.
3. Test automatic sorting against player-selected drawers; keep the version with clearer decisions.
4. Measure actual level completion and retry patterns before expanding the campaign.
5. Add a daily puzzle only after the core is understandable and worth replaying.

No analytics, advertising, account creation, energy timers, purchases, or remote content dependency are included in this build.

## Sources

All links accessed 13 October 2026. Figures are paraphrased; no report graphics or game assets were reproduced.

1. [AppMagic, Casual Games Report 2025](https://appmagic.rocks/research/casual-report-2025), published February 2026. Primary analytics provider. Numeric text retrieved from indexed results; opened body was unavailable.
2. [AppMagic, Casual Gaming in H1 2024](https://appmagic.rocks/research/casual-gaming-2024-h1), August 2024. Primary analytics provider. Tier-1 West scope; indexed text available.
3. [Mobidictum, AppMagic casual games report 2025 summary](https://mobidictum.com/appmagic-casual-games-report-2025-summary/), 24 February 2026. Secondary summary used for Sort/Screw figures and entrant concentration.
4. [Sensor Tower, July 2026 worldwide mobile rankings](https://sensortower.com/blog/top-10-worldwide-mobile-games-by-revenue-and-downloads-in-july-2026), August 2026. Primary analytics provider; store and geography limitations apply.
5. [Block Blast official site](https://www.blockblast.com/). Primary developer marketing source; active-user figures are self-reported and cumulative context is not a period-specific download ranking.
6. [Sensor Tower, US Android puzzle games, Q4 2023](https://sensortower.com/blog/2023-q4-android-top-5-puzzle%20games-revenue-us-64bc1644e1714cfff1e615fc). Regional primary analytics source.
7. [Boston University, Everybody Is a Gamer](https://www.bu.edu/articles/2024/everybody-is-a-gamer/), 7 August 2024. Direct interview with NYT's games head; the 2023 aggregate is attributed there to Axios.
8. [Associated Press, NYT's first two-player game](https://apnews.com/article/4ab76097d6155a022f089d03e94807c3), 2026. Secondary reporting; figures obtained from the indexed article summary when direct open failed.
9. [Sensor Tower, State of Mobile Gaming 2025](https://sensortower.com/blog/state-of-mobile-gaming-2025), March 2025. Covers 2024; primary analytics provider.
10. [AppMagic, New Puzzle Order: Sort, Block, and Screw](https://appmagic.rocks/blog/new-puzzle-order-sort-block-screw), 8 July 2026. Primary analysis; only indexed framing was recoverable.
11. [Poki, Blocky Blast Puzzle](https://poki.com/en/g/blocky-blast-puzzle). First-party distribution listing; current ratings are not period-isolated player counts.
12. [Raw Fury, Blue Prince release announcement](https://rawfury.com/blue-prince-is-arriving-on-april-10th/), 24 February 2025. Primary publisher source; qualitative context only.
13. [Google Play, Screw Jam by Rollic](https://play.google.com/store/apps/details?hl=en_US&id=com.quok.screwJam). Primary store listing identifying the reference mechanic and correct publisher; not used as a three-year download total.
14. [Google Play, Goods Puzzle: Sort Challenge](https://play.google.com/store/apps/details?id=com.fc.goods.sort.matching.puzzle.triplemaster). Primary store listing identifying the sorting/matching family.
