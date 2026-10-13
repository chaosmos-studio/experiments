"""Build a deterministic campaign and independently verify every witness route."""
import json
import random
from pathlib import Path
from audit_levels import Board

ROOT = Path(__file__).resolve().parents[1]
NAMES = [
    'In a row', 'A step back', 'Under the surface', 'Cross grain',
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


def ordered_word(rng, count, colors):
    groups = [i % colors for i in range(count)]
    rng.shuffle(groups)
    word = []
    for color in groups:
        positions = list(range(len(word)+1))
        rng.shuffle(positions)
        for pos in positions:
            trial = word[:pos] + [color]*3 + word[pos:]
            stack, peak = [], 0
            for c in trial:
                stack.append(c)
                if len(stack) >= 3 and stack[-3:] == [c]*3:
                    del stack[-3:]
                peak = max(peak, len(stack))
            if peak < 7:
                word = trial
                break
        else:
            raise AssertionError('Appending a complete triple should remain possible')
    return word


def return_demo(board):
    # A,B,A,A -> return B -> A,A,A clears. Check a full winning continuation.
    def visit(mask, line, route):
        if len(route) == 4:
            next_mask, next_line = board.put_back(mask, line, route[1])
            if next_line:
                return None
            try:
                solution, _ = board.solve(next_mask, next_line)
            except TimeoutError:
                return None
            if solution is not None:
                return {'takes': route, 'return_id': route[1], 'after': solution}
            return None
        for i in board.choices(mask):
            if route:
                same = board.colors[i] == board.colors[route[0]]
                if same != (len(route) != 1):
                    continue
            next_mask, next_line = board.take(mask, line, i)
            result = visit(next_mask, next_line, route + [i])
            if result:
                return result
        return None
    return visit(0, (), [])


def candidate(number, attempt):
    seed = 728000 + number * 10000 + attempt
    rng = random.Random(seed)
    plates, screws = [], []
    count = min(5 + number//3, 12)
    colors = 3 if number < 3 else 4 if number < 12 else 5 if number < 24 else 6
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
    # A reducible ordered word gives a safe route with deliberate interleaving.
    word = ordered_word(rng, count, colors)
    for index, color in zip(route, word):
        screws[index]['color'] = color
    board = Board(level)
    mask, line, peak = 0, (), 0
    for index in route:
        mask, line = board.take(mask, line, index)
        peak = max(peak, len(line))
    assert board.won(mask, line)
    level['solution'] = route
    level['witness_peak'] = peak
    level['seed'] = seed
    level['chapter'] = 'Learn' if number < 3 else 'Plan' if number < 12 else 'Think ahead' if number < 24 else 'Master'
    return level


def make(number):
    # Reject both arbitrary-tapping wins and boards solved by local matching alone.
    if number < 3:
        random_band, greedy_band = (0.01, 0.18), (0.65, 0.94)
    elif number < 12:
        random_band, greedy_band = (0.0, 0.075), (0.35, 0.79)
    elif number < 24:
        random_band, greedy_band = (0.0, 0.025), (0.12, 0.52)
    else:
        random_band, greedy_band = (0.0, 0.012), (0.025, 0.32)
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
            route, visits = board.solve(limit=3000)
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
        level['full_route'] = screen_random['full_route']
        if not level['full_route']:
            continue
        if number == 0:
            demo = return_demo(board)
            if not demo:
                continue
            level['return_demo'] = demo
        return level
    raise RuntimeError(f'Could not find a suitable study {number+1}')


def verify(level):
    # Separate coordinate-based exposure check plus the ordered-tray model.
    board = Board(level)
    mask, line = 0, ()
    for index in level['solution']:
        assert exposed(level, mask, index)
        mask, line = board.take(mask, line, index)
        assert len(line) < 7
    assert board.won(mask, line)
    mask, line = 0, ()
    for index in level['full_route']:
        assert exposed(level, mask, index)
        mask, line = board.take(mask, line, index)
    assert len(line) == 7 and not board.won(mask, line)
    for index in line:
        restored_mask, restored_line = board.put_back(mask, line, index)
        assert len(restored_line) < 7 and not restored_mask & (1 << index)


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
