"""Build a deterministic campaign and independently verify every witness route."""
import json
import random
from pathlib import Path
from audit_levels import Board

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


def candidate(number, attempt):
    seed = 128000 + number * 10000 + attempt
    rng = random.Random(seed)
    plates, screws = [], []
    count = min(5 + number//3, 12)
    colors = 4 if number < 3 else 5 if number < 18 else 6
    # Lattice-aligned plates make overlap and hit targets unambiguous.
    for p in range(count):
        vertical = (p % 2 == 1)
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
        # Six single colours can fill the safe space with no possible triple.
        # Reject that candidate instead of producing an impossible witness.
        if not safe:
            return None
        c = rng.choice(safe)
        screws[index]['color'] = c
        remaining[c] -= 1
        tray[c] = (tray[c] + 1) % 3
        peak = max(peak, sum(tray))
    level['solution'] = route
    level['witness_peak'] = peak
    level['seed'] = seed
    level['chapter'] = 'Learn' if number < 3 else 'Plan' if number < 12 else 'Think ahead' if number < 24 else 'Master'
    return level


def make(number):
    # Reject both arbitrary-tapping wins and boards solved by local matching alone.
    if number < 3:
        random_band, greedy_band = (0.18, 0.38), (0.70, 0.96)
    elif number < 12:
        random_band, greedy_band = (0.025, 0.16), (0.40, 0.78)
    elif number < 24:
        random_band, greedy_band = (0.0, 0.045), (0.12, 0.48)
    else:
        random_band, greedy_band = (0.0, 0.018), (0.025, 0.24)
    for attempt in range(20000):
        level = candidate(number, attempt)
        if level is None:
            continue
        board = Board(level)
        if sum(bool(x) for x in board.covers) < 3:
            continue
        random_result = board.simulate(128, seed=51000 + number)
        if not random_band[0] <= random_result['win_rate'] <= random_band[1]:
            continue
        greedy_result = board.simulate(128, seed=61000 + number, greedy=True)
        if not greedy_band[0] <= greedy_result['win_rate'] <= greedy_band[1]:
            continue
        try:
            route, visits = board.solve(limit=12000)
        except TimeoutError:
            continue
        if route is None:
            continue
        # Larger independent screening sample avoids selecting a lucky small run.
        screen_random = board.simulate(512, seed=81000 + number)
        screen_greedy = board.simulate(512, seed=101000 + number, greedy=True)
        if not random_band[0] <= screen_random['win_rate'] <= random_band[1]:
            continue
        if not greedy_band[0] <= screen_greedy['win_rate'] <= greedy_band[1]:
            continue
        level['failure_route'] = screen_random['loss_route']
        assert level['failure_route']
        return level
    raise RuntimeError(f'Could not find a suitable study {number+1}')


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
    levels = []
    for i in range(36):
        level = make(i)
        verify(level)
        levels.append(level)
        print(f'Verified study {i+1}: seed {level["seed"]}', flush=True)
    target = ROOT/'data'/'levels.json'
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(levels, separators=(',', ':'))+'\n')
    print(f'Generated and verified {len(levels)} levels.')
