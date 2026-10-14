# Webs

Twelve puzzles increase from four knots and one crossing to twelve knots and thirty
initial tangles. Fixed anchors begin in web five. Ring, wheel, grid and nested-ring
structures provide different shapes to discover.

`tools/generate_levels.py` checks every solution and writes `difficulty-audit.json`.
Its random-layout samples are an anti-auto-win regression check, not a player skill
model. Early lessons are intentionally easy. From web six onward, none of 300
independent random layouts per web solved it in the recorded sample.

Difficulty is not strictly increasing. Real playtesting is still needed to judge
whether the pacing, touch targets, and completion reward are enjoyable.
