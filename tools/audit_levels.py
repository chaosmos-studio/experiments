"""Independent ordered-tray model. Simulations measure pressure, not enjoyment."""
import argparse
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPACITY = 7


class Board:
    def __init__(self, level):
        self.level = level
        self.colors = [s['color'] for s in level['screws']]
        self.size = len(self.colors)
        self.full = (1 << self.size) - 1
        self.plates = [sum(1 << i for i, s in enumerate(level['screws'])
                           if s['plate'] == p) for p in range(len(level['plates']))]
        self.covers = []
        for s in level['screws']:
            covers = []
            for p in range(s['plate'] + 1, len(self.plates)):
                x, y, w, h = level['plates'][p]['rect']
                if x <= s['x'] < x+w and y <= s['y'] < y+h:
                    covers.append(self.plates[p])
            self.covers.append(covers)

    def choices(self, mask):
        return [i for i in range(self.size) if not mask & (1 << i)
                and all(mask & p == p for p in self.covers[i])]

    def settle(self, line):
        result = list(line)
        i = 0
        while i + 2 < len(result):
            if len({self.colors[j] for j in result[i:i+3]}) == 1:
                del result[i:i+3]
                i = max(0, i-2)
            else:
                i += 1
        return tuple(result)

    def take(self, mask, line, index):
        assert len(line) < CAPACITY and index in self.choices(mask)
        return mask | (1 << index), self.settle((*line, index))

    def put_back(self, mask, line, index):
        assert index in line and mask & (1 << index)
        return mask & ~(1 << index), self.settle([j for j in line if j != index])

    def won(self, mask, line):
        return mask == self.full and not line

    def solve(self, initial=0, line=(), limit=5000):
        dead = set()
        visits = 0

        def visit(mask, tray):
            nonlocal visits
            if self.won(mask, tray):
                return []
            key = mask, tray
            if len(tray) >= CAPACITY or key in dead:
                return None
            visits += 1
            if visits > limit:
                raise TimeoutError('Solver budget exceeded')
            tail = self.colors[tray[-1]] if tray else -1
            choices = sorted(self.choices(mask), key=lambda i: self.colors[i] != tail)
            for i in choices:
                next_mask, next_tray = self.take(mask, tray, i)
                route = visit(next_mask, next_tray)
                if route is not None:
                    return [i] + route
            dead.add(key)
            return None

        return visit(initial, tuple(line)), visits

    def simulate(self, attempts=1000, seed=541, greedy=False):
        rng = random.Random(seed)
        wins = 0
        full_route = None
        for _ in range(attempts):
            mask, line, route = 0, (), []
            while len(line) < CAPACITY and not self.won(mask, line):
                options = self.choices(mask)
                if not options:
                    break
                if greedy and line:
                    same = [i for i in options if self.colors[i] == self.colors[line[-1]]]
                    if same:
                        options = same
                i = rng.choice(options)
                route.append(i)
                mask, line = self.take(mask, line, i)
            if self.won(mask, line):
                wins += 1
            elif len(line) == CAPACITY and full_route is None:
                full_route = route
        return {'wins': wins, 'attempts': attempts,
                'win_rate': round(wins / attempts, 4), 'full_route': full_route}


def audit(levels, attempts=1000):
    rows = []
    for i, level in enumerate(levels):
        board = Board(level)
        random_result = board.simulate(attempts, 73000 + i)
        greedy_result = board.simulate(attempts, 91000 + i, greedy=True)
        route, nodes = board.solve()
        assert route is not None, f'Study {i+1} needs a verified forward route'
        rows.append({'study': i+1, 'random_win_rate': random_result['win_rate'],
                     'greedy_win_rate': greedy_result['win_rate'], 'solver_nodes': nodes,
                     'random_attempts': attempts, 'greedy_attempts': attempts})
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--attempts', type=int, default=1000)
    args = parser.parse_args()
    levels = json.loads((ROOT/'data/levels.json').read_text())
    rows = audit(levels, args.attempts)
    for row in rows:
        print(f"{row['study']:02d}: random={row['random_win_rate']:.1%} "
              f"greedy={row['greedy_win_rate']:.1%} nodes={row['solver_nodes']}")
    if args.check:
        for row in rows:
            maximum = 0.25 if row['study'] <= 3 else 0.10 if row['study'] <= 12 else 0.04
            assert row['random_win_rate'] <= maximum, ('Random collection too easy', row)
            greedy_maximum = 0.99 if row['study'] <= 3 else 0.87 if row['study'] <= 12 else 0.62 if row['study'] <= 24 else 0.42
            assert row['greedy_win_rate'] <= greedy_maximum, ('Local matching too easy', row)
            assert row['solver_nodes'] < 5000, ('Hint search too expensive', row)
        assert all(row['greedy_win_rate'] > row['random_win_rate'] for row in rows[:3])
    (ROOT/'docs/difficulty-audit.json').write_text(json.dumps(rows, indent=2)+'\n')
