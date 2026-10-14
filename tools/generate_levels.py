"""Deterministic, independently verified finite block-placement puzzles."""
import json, random
from pathlib import Path
N=6
ROWS=[sum(1<<(y*N+x) for x in range(N)) for y in range(N)]
COLS=[sum(1<<(y*N+x) for y in range(N)) for x in range(N)]
SHAPES=[[(0,0),(1,0)],[(0,0),(0,1)],[(0,0),(1,0),(2,0)],[(0,0),(0,1),(0,2)],
 [(0,0),(0,1),(1,1)],[(0,0),(1,0),(0,1)],[(0,0),(1,0),(1,1)],[(1,0),(0,1),(1,1)],
 [(0,0),(1,0),(0,1),(1,1)],[(0,0),(1,0),(2,0),(1,1)],[(0,0),(0,1),(0,2),(1,2)],
 [(0,0),(1,0),(2,0),(3,0)],[(0,0),(0,1),(0,2),(0,3)],[(0,0),(1,0),(2,0),(0,1),(0,2)],
 [(1,0),(2,0),(0,1),(1,1)]]
PLACEMENTS=[]
for shape in SHAPES:
    options=[]
    for y in range(N-max(p[1] for p in shape)):
        for x in range(N-max(p[0] for p in shape)):
            options.append((x,y,sum(1<<((y+dy)*N+x+dx) for dx,dy in shape)))
    PLACEMENTS.append(options)

def put(board,mask):
    if board&mask:return None
    filled=board|mask
    lines=[m for m in ROWS+COLS if filled&m==m]
    cleared=0
    for m in lines:cleared|=m
    return filled&~cleared,len(lines),cleared

def available(used,count):
    for start in range(0,count,3):
        group=[i for i in range(start,min(start+3,count)) if not used>>i&1]
        if group:return group
    return []

def moves(level,board,used):
    result=[]
    for i in available(used,len(level['pieces'])):
        for x,y,mask in PLACEMENTS[level['pieces'][i]]:
            if not board&mask:
                nxt,lines,clear=put(board,mask)
                result.append((i,x,y,nxt,lines,clear))
    return result

def solve(level,board=None,used=0,lines=0,limit=25000):
    if board is None:board=int(level['board'])
    seen=set();nodes=0
    def walk(board,used,lines):
        nonlocal nodes
        if lines>=level['goal']:return []
        key=(board,used,lines)
        if key in seen:return None
        nodes+=1
        if nodes>limit:raise TimeoutError
        seen.add(key)
        choices=moves(level,board,used)
        choices.sort(key=lambda m:(-m[4],m[0],m[2],m[1]))
        for i,x,y,nxt,count,_ in choices:
            route=walk(nxt,used|1<<i,lines+count)
            if route is not None:return [[i,x,y]]+route
        return None
    return walk(board,used,lines),nodes

def simulate(level,attempts,seed,greedy=False):
    rng=random.Random(seed);wins=0;failure=None
    for _ in range(attempts):
        board=int(level['board']);used=0;lines=0;route=[]
        while lines<level['goal']:
            options=moves(level,board,used)
            if not options:break
            if greedy:
                top=max(m[4] for m in options)
                options=[m for m in options if m[4]==top]
            i,x,y,board,count,_=rng.choice(options)
            used|=1<<i;lines+=count;route.append([i,x,y])
        if lines>=level['goal']:wins+=1
        elif failure is None:failure=route
    return wins/attempts,failure

def candidate(number,attempt):
    rng=random.Random(260014+number*10000+attempt)
    count=6 if number<6 else 9
    density=.43 if number<6 else .50
    board=sum(1<<i for i in range(36) if rng.random()<density)
    if any(board&m==m for m in ROWS+COLS):return None
    initial=board;sequence=[];total=0;clear_moves=0
    for step in range(count):
        choices=[]
        for shape in range(len(SHAPES)):
            for x,y,mask in PLACEMENTS[shape]:
                if not board&mask:
                    nxt,lines,_=put(board,mask)
                    choices.append((shape,x,y,nxt,lines))
        if not choices:return None
        # Construct with occasional setup moves, never with an adaptive in-game deal.
        if rng.random()<.78:
            top=max(c[4] for c in choices)
            choices=[c for c in choices if c[4]==top]
        shape,x,y,board,lines=rng.choice(choices)
        sequence.append([shape,x,y]);total+=lines;clear_moves+=int(lines>0)
    if total<(3 if number<6 else 5) or clear_moves==count:return None
    pieces=[];route=[]
    for start in range(0,count,3):
        order=list(range(3));rng.shuffle(order)
        pieces.extend(sequence[start+i][0] for i in order)
        route.extend([[start+order.index(i),sequence[start+i][1],sequence[start+i][2]] for i in range(3)])
    goal=total if number<12 else total+0
    names=['First light','The corner','A little space','Crossing paths','Room to spare','Two directions',
           'Offset','Open centre','The long way','An opening','Interlock','Side by side',
           'Narrow margins','In reserve','Common ground','The last gap','Full picture','One more line']
    return {'name':names[number],'chapter':['Learn','Plan','Master'][number//6],
            'seed':260014+number*10000+attempt,'board':str(initial),'pieces':pieces,'goal':goal,'solution':route}

def verify(level):
    board=int(level['board']);used=0;lines=0
    for i,x,y in level['solution']:
        assert i in available(used,len(level['pieces']))
        shape=SHAPES[level['pieces'][i]]
        assert all(0<=x+dx<N and 0<=y+dy<N for dx,dy in shape)
        mask=sum(1<<((y+dy)*N+x+dx) for dx,dy in shape)
        result=put(board,mask);assert result is not None
        board,count,_=result;used|=1<<i;lines+=count
        if lines>=level['goal']:break
    assert lines>=level['goal']
    board=int(level['board']);used=0;lines=0
    for i,x,y in level['failure_route']:
        opts=[m for m in moves(level,board,used) if m[:3]==(i,x,y)];assert opts
        _,_,_,board,c,_=opts[0];used|=1<<i;lines+=c
    assert lines<level['goal'] and not moves(level,board,used)

def generate():
    levels=[];audit=[]
    for number in range(18):
        for attempt in range(3000):
            level=candidate(number,attempt)
            if level is None:continue
            random_rate,failed=simulate(level,100,51000+number)
            greedy_rate,_=simulate(level,100,71000+number,True)
            if failed is None or random_rate>(.20 if number<3 else .06):continue
            if not (.20<=greedy_rate<=.85 if number<6 else .08<=greedy_rate<=.55):continue
            try:route,nodes=solve(level,limit=10000)
            except TimeoutError:continue
            if route is None:continue
            level['solution']=route;level['failure_route']=failed
            level['opening_choices']=len(moves(level,int(level['board']),0))
            rr,_=simulate(level,500,91000+number)
            gr,_=simulate(level,500,111000+number,True)
            if rr>(.25 if number<3 else .10) or gr>(.90 if number<6 else .65):continue
            verify(level)
            levels.append(level);audit.append({'level':number+1,'random_win_rate':rr,'greedy_win_rate':gr,'solver_nodes':nodes,'attempts_per_policy':500})
            print(f'{number+1:02} seed={level["seed"]} goal={level["goal"]} random={rr:.3f} greedy={gr:.3f} nodes={nodes}',flush=True)
            break
        else:raise RuntimeError(f'No candidate {number}')
    # Order later boards by measured greedy success, with the toughest band last.
    paired=sorted(zip(levels[6:],audit[6:]),key=lambda pair:-pair[1]['greedy_win_rate'])
    later_names=[level['name'] for level in levels[6:]]
    for index,(level,record) in enumerate(paired,6):
        level['name']=later_names[index-6]
        level['chapter']='Plan' if index<12 else 'Master'
        record['level']=index+1
    levels=levels[:6]+[pair[0] for pair in paired]
    audit=audit[:6]+[pair[1] for pair in paired]
    root=Path(__file__).resolve().parents[1]
    (root/'data/levels.json').write_text(json.dumps(levels,separators=(',',':'))+'\n')
    (root/'data/shapes.json').write_text(json.dumps(SHAPES,separators=(',',':'))+'\n')
    (root/'docs/difficulty-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
    print('Verified 18 solutions and 18 losing routes.')
if __name__=='__main__':generate()
