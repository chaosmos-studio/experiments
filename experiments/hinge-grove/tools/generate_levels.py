"""Deterministic hinge puzzles, reverse construction and exact breadth-first proof."""
from collections import deque
from pathlib import Path
from itertools import permutations
import json, random, math, hashlib

ROOT = Path(__file__).resolve().parents[1]
SEED = 16102026
SIZE = 4

def poses(n):
    return [(a,b) for a in range(n*n) for b in (a+1,a+n)
            if b<n*n and (b==a+n or a//n==b//n)]

def turns(pair,n):
    for pivot,other in (pair,pair[::-1]):
        x,y=pivot%n,pivot//n; dx,dy=other%n-x,other//n-y
        for sign in (-1,1):
            nx,ny=-dy*sign,dx*sign
            tx,ty=x+nx,y+ny; cx,cy=x+dx+nx,y+dy+ny
            if 0<=tx<n and 0<=ty<n and 0<=cx<n and 0<=cy<n:
                target=ty*n+tx; corner=cy*n+cx
                yield pivot,other,target,corner,sign

def transitions(level,state,reverse=False):
    n=level['size']; walls=set(level['walls']); goals=level['goals']
    occupied=set(state)
    for i in range(len(goals)):
        pair=state[2*i:2*i+2]
        for pivot,other,target,corner,sign in turns(pair,n):
            if (target if reverse else other) in goals[i]:
                continue
            if target in walls or corner in walls or target in occupied or corner in occupied:
                continue
            nxt=list(state);nxt[2*i:2*i+2]=sorted((pivot,target))
            yield tuple(nxt),[i,pivot,sign],target

def solve(level,start=None,cap=90000):
    start=tuple(start or sum(level['start'],[]));goal=tuple(sum(level['goals'],[]))
    queue=deque([start]); parent={start:None};depth={start:0};winning=None
    while queue:
        state=queue.popleft()
        if state==goal:
            winning=state;break
        for nxt,move,_ in transitions(level,state):
            if nxt not in parent:
                parent[nxt]=(state,move);depth[nxt]=depth[state]+1;queue.append(nxt)
                if len(parent)>cap:return None
    if winning is None:return None
    path=[]
    while parent[winning]:
        prev,move=parent[winning];path.append(move);winning=prev
    return {'solution':path[::-1],'par':len(path),'states':len(parent)}

def canonical(level):
    n=level['size'];keys=[]
    for flip in (False,True):
        for rot in range(4):
            def cell(c):
                x,y=c%n,c//n
                if flip:x=n-1-x
                for _ in range(rot):x,y=n-1-y,x
                return y*n+x
            pairs=sorted((tuple(sorted(map(cell,a))),tuple(sorted(map(cell,b)))) for a,b in zip(level['start'],level['goals']))
            keys.append((tuple(sorted(map(cell,level['walls']))),tuple(pairs)))
    return str(min(keys))

def generate():
    rng=random.Random(SEED);pool=[];seen=set()
    for count,needed,minimum,maximum in ((1,6,1,6),(2,12,6,12),(3,12,12,20)):
        candidates=[];tries=0
        while len(candidates)<needed*6 and tries<1800:
            tries+=1;n=SIZE;all_poses=poses(n);rng.shuffle(all_poses)
            goals=[];used=set()
            for pair in all_poses:
                if not used.intersection(pair):
                    goals.append(list(pair));used.update(pair)
                    if len(goals)==count:break
            empty=[x for x in range(n*n) if x not in used]
            wall_count=rng.randrange(0,3 if count<3 else 2)
            level={'size':n,'walls':sorted(rng.sample(empty,wall_count)),'goals':goals}
            state=tuple(sum(goals,[]));history={state}
            for _ in range(rng.randint(10,30)):
                options=[(s,m) for s,m,_ in transitions(level,state,True) if s not in history]
                if not options:break
                state,_=rng.choice(options);history.add(state)
            level['start']=[list(state[i:i+2]) for i in range(0,len(state),2)]
            if any(set(a).intersection(b) for a,b in zip(level['start'],goals)):continue
            key=canonical(level)
            if key in seen:continue
            result=solve(level)
            if not result or not minimum<=result['par']<=maximum:continue
            # More explored states at equal par is a transparent secondary proxy.
            level.update(result);level['difficulty']=round(result['par']+math.log2(1+result['states'])/100,6)
            seen.add(key);candidates.append(level)
        candidates.sort(key=lambda l:l['difficulty'])
        if len(candidates)<needed:raise RuntimeError((count,len(candidates),tries))
        # Spread the chosen levels across the candidate range, with exact par nondecreasing.
        chosen=[candidates[round(i*(len(candidates)-1)/(needed-1))] for i in range(needed)]
        pool.extend(chosen)
        print('generated',count,'pairs',len(candidates),'candidates',tries,'attempts',flush=True)
    pool.sort(key=lambda l:l['difficulty'])
    # Give the first lesson a short, readable move sequence; retain proof for all levels.
    for i,level in enumerate(pool):level['id']=i+1
    data={'version':1,'seed':SEED,'levels':pool}
    (ROOT/'data/levels.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
    print('LEVELS',len(pool),'PARS',[l['par'] for l in pool],flush=True)

if __name__=='__main__':generate()
