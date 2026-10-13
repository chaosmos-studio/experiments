"""Build a deterministic campaign and independently verify every witness route."""
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NAMES = [
    'First turn', 'A little order', 'Under the surface', 'Cross grain',
    'Three of a kind', 'Hidden in plain sight', 'Small decisions', 'The overlap',
    'A careful hand', 'Colour study', 'Leave some room', 'Loose ends',
    'Between the layers', 'A new angle', 'The quiet middle', 'Stacked odds',
    'Keep a clear space', 'One at a time', 'Colour memory', 'Tight quarters',
    'The long way round', 'Less is more', 'Unfinished business', 'Make room',
    'Below the fold', 'A delicate balance', 'Soft geometry', 'The third choice',
    'A different order', 'Almost there', 'Deep work', 'Intersections',
    'The last layer', 'Patience pays', 'Everything in place', 'A clean slate',
]


def exposed(level, mask, i):
    if mask >> i & 1:
        return False
    s = level['screws'][i]
    for p in range(s['plate'] + 1, len(level['plates'])):
        x, y, w, h = level['plates'][p]['rect']
        if x <= s['x'] < x+w and y <= s['y'] < y+h:
            if any(t['plate'] == p and not (mask >> j & 1)
                   for j, t in enumerate(level['screws'])):
                return False
    return True


def held(level, mask):
    counts = [0]*6
    for i, s in enumerate(level['screws']):
        if mask >> i & 1:
            counts[s['color']] += 1
    return [n % 3 for n in counts]


def make(number):
    rng = random.Random(8900 + number)
    plates, screws = [], []
    count = 3 if number == 0 else min(5 + number//4, 12)
    colors = 3 if number < 4 else 4 if number < 14 else 5
    # Lattice-aligned plates make overlap and hit targets unambiguous.
    for p in range(count):
        vertical = (p % 2 == 1)
        if number == 0:
            coords = [(190 + 96*k, 104 + 102*p) for k in range(3)]
        else:
            col = rng.randrange(6 if vertical else 4)
            row = rng.randrange(3 if vertical else 5)
            coords = [(46+96*(col+(0 if vertical else k)),
                       44+88*(row+(k if vertical else 0))) for k in range(3)]
        xs, ys = zip(*coords)
        plates.append({'rect': [min(xs)-38, min(ys)-38,
                                max(xs)-min(xs)+76, max(ys)-min(ys)+76],
                       'style': p % 5})
        for x, y in coords:
            screws.append({'x': x, 'y': y, 'plate': p, 'color': 0})
    level = {'name': NAMES[number], 'plates': plates, 'screws': screws}
    # Choose a legal physical removal route first.
    mask, route = 0, []
    while len(route) < len(screws):
        choices = [i for i in range(len(screws)) if exposed(level, mask, i)]
        i = rng.choice(choices)
        route.append(i)
        mask |= 1 << i
    # Assign colours along that route, always leaving room to complete triples.
    remaining = [0]*6
    for p in range(count):
        remaining[p % colors] += 3
    tray = [0]*6
    peak = 0
    for index in route:
        choices = [c for c in range(colors) if remaining[c] > 0]
        safe = [c for c in choices if sum(tray) + (1 if tray[c] < 2 else -2) < 7]
        # At occupancy six at least one held colour has two screws.
        assert safe
        c = rng.choice(safe)
        screws[index]['color'] = c
        remaining[c] -= 1
        tray[c] = (tray[c] + 1) % 3
        peak = max(peak, sum(tray))
    if number == 0:
        for i, s in enumerate(screws):
            s['color'] = i % 3
        route = [0, 3, 6, 1, 4, 7, 2, 5, 8]
    level['solution'] = route
    level['witness_peak'] = peak
    return level


def verify(level):
    mask = 0
    for i in level['solution']:
        assert exposed(level, mask, i), ('covered', i)
        assert sum(held(level, mask)) < 7
        mask |= 1 << i
        assert sum(held(level, mask)) < 7
    assert mask == (1 << len(level['screws'])) - 1
    assert sum(held(level, mask)) == 0


if __name__ == '__main__':
    levels = [make(i) for i in range(36)]
    for level in levels:
        verify(level)
    target = ROOT/'data'/'levels.json'
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(levels, separators=(',', ':'))+'\n')
    print(f'Generated and verified {len(levels)} levels.')
