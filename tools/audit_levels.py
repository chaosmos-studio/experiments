"""Simulate legal play without hints or undo; this measures pressure, not fun."""
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

    def held(self, mask):
        counts = [0] * 6
        for i, c in enumerate(self.colors):
            if mask & (1 << i):
                counts[c] += 1
        return [n % 3 for n in counts]

    def solve(self, initial=0, limit=60000):
        dead = set()
        visits = 0

        def visit(mask):
            nonlocal visits
            if mask == self.full:
                return []
            counts = self.held(mask)
            if sum(counts) >= CAPACITY or mask in dead:
                return None
            visits += 1
            if visits > limit:
                raise TimeoutError('Solver budget exceeded')
            choices = sorted(self.choices(mask), key=lambda i: -counts[self.colors[i]])
            for i in choices:
                tail = visit(mask | (1 << i))
                if tail is not None:
                    return [i] + tail
            dead.add(mask)
            return None

        return visit(initial), visits

    def simulate(self, attempts=1000, seed=541, greedy=False):
        rng = random.Random(seed)
        wins = 0
        loss_route = None
        for _ in range(attempts):
            mask, counts, route = 0, [0] * 6, []
            while mask != self.full and sum(counts) < CAPACITY:
                options = self.choices(mask)
                if greedy:
                    # Prefer completing a triple, then a pair; do not look ahead.
                    best = max(counts[self.colors[i]] for i in options)
                    options = [i for i in options if counts[self.colors[i]] == best]
                i = rng.choice(options)
                route.append(i)
                mask |= 1 << i
                counts[self.colors[i]] = (counts[self.colors[i]] + 1) % 3
            if mask == self.full:
                wins += 1
            elif loss_route is None:
                loss_route = route
        return {'wins': wins, 'attempts': attempts,
                'win_rate': round(wins / attempts, 4), 'loss_route': loss_route}


def audit(levels, attempts=1000):
    rows = []
    for i, level in enumerate(levels):
        board = Board(level)
        random_result = board.simulate(attempts, 73000 + i)
        greedy_result = board.simulate(attempts, 91000 + i, greedy=True)
        route, nodes = board.solve()
        assert route is not None, f'Study {i+1} is impossible'
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
            maximum = 0.50 if row['study'] <= 3 else 0.25 if row['study'] <= 12 else 0.08
            assert row['random_win_rate'] <= maximum, ('Random play too easy', row)
            greedy_maximum = 0.99 if row['study'] <= 3 else 0.85 if row['study'] <= 12 else 0.56 if row['study'] <= 24 else 0.32
            assert row['greedy_win_rate'] <= greedy_maximum, ('Matching alone is too easy', row)
            assert row['solver_nodes'] < 60000, ('Hint search too expensive', row)
        assert all(row['greedy_win_rate'] > row['random_win_rate'] for row in rows[:3])
    (ROOT/'docs/difficulty-audit.json').write_text(json.dumps(rows, indent=2)+'\n')
