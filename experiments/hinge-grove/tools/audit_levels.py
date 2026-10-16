"""Re-solve, symmetry-check and run a seeded random-play baseline."""
import json, random, hashlib
from pathlib import Path
from generate_levels import solve, canonical, transitions

ROOT=Path(__file__).resolve().parents[1]

def validate(levels):
    assert len(levels)==30
    seen=set();last=0
    for level in levels:
        result=solve(level)
        assert result and result['par']==level['par']
        assert len(level['solution'])==level['par']>=last
        state=tuple(sum(level['start'],[]))
        for move in level['solution']:
            matches=[s for s,m,_ in transitions(level,state) if m==move]
            assert len(matches)==1
            state=matches[0]
        assert state==tuple(sum(level['goals'],[]))
        key=canonical(level);assert key not in seen;seen.add(key);last=level['par']

def main():
    raw=(ROOT/'data/levels.json').read_bytes();levels=json.loads(raw)['levels'];validate(levels)
    # Mutation checks establish that the guards can fail.
    duplicate=json.loads(raw)['levels'];duplicate[-1]=duplicate[-2]
    try:validate(duplicate)
    except AssertionError:pass
    else:raise AssertionError('Duplicate guard failed')
    wrong=json.loads(raw)['levels'];wrong[-1]['solution'][0][1]=99
    try:validate(wrong)
    except AssertionError:pass
    else:raise AssertionError('Witness guard failed')
    rng=random.Random(16102026);rows=[];dead_end=None
    for level in levels:
        wins=0;trials=300;goal=tuple(sum(level['goals'],[]))
        for _ in range(trials):
            state=tuple(sum(level['start'],[]));route=[]
            for step in range(level['par']*2):
                options=list(transitions(level,state))
                if not options:
                    if state!=goal and dead_end is None:dead_end={'level':level['id'],'moves':route,'state':list(state)}
                    break
                state,move,_=rng.choice(options);route.append(move)
                if state==goal:wins+=1;break
        rows.append({'level':level['id'],'par':level['par'],'states':level['states'],'random_wins_in_twice_par':wins,'trials':trials})
    assert dead_end, 'Campaign must contain consequential mistakes, not automatic wins'
    report={'seed':16102026,'sha256':hashlib.sha256(raw).hexdigest(),'levels':30,'symmetry_pairs':435,'native_cross_check':'tests/run_tests.gd','random_policy':'uniform among legal moves, at most twice shortest solution length, 300 trials per board','results':rows,'dead_end_fixture':dead_end}
    (ROOT/'docs/audit.json').write_text(json.dumps(report,indent=2)+'\n')
    print('AUDIT_OK: 30 shortest-route proofs, 435 symmetry pairs, mutation guards, 9000 random trials')
    print('Dead end fixture:',dead_end)
    print('Random wins:',sum(r['random_wins_in_twice_par'] for r in rows),'/ 9000')

if __name__=='__main__':main()
