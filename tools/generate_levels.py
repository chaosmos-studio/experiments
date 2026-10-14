"""Reproducible planar webs; every puzzle carries a geometric solution witness."""
import json, math, random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def distance(p,a,b):
    dx,dy=b[0]-a[0],b[1]-a[1]
    t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/max(1e-9,dx*dx+dy*dy)))
    return math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy)
def cross(a,b,c): return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def intersects(a,b,c,d):
    return cross(a,b,c)*cross(a,b,d)<0 and cross(c,d,a)*cross(c,d,b)<0 or min(distance(a,c,d),distance(b,c,d),distance(c,a,b),distance(d,a,b))<.5

def inspect(points,edges):
    result=0
    for i,(a,b) in enumerate(edges):
        for c,d in edges[i+1:]:
            if len({a,b,c,d})==4 and intersects(points[a],points[b],points[c],points[d]): result+=1
        for n,p in enumerate(points):
            if n not in (a,b) and distance(p,points[a],points[b])<25: result+=1
    for i,p in enumerate(points):
        for q in points[i+1:]:
            if math.dist(p,q)<64: result+=1
    return result

def ring(n,rx=242,ry=208,offset=-math.pi/2):
    return [[round(360+rx*math.cos(offset+i*math.tau/n),2),round(520+ry*math.sin(offset+i*math.tau/n),2)] for i in range(n)]
def cycle(n): return [[i,(i+1)%n] for i in range(n)]
def wheel(n): return ring(n)+[[360,520]],cycle(n)+[[i,n] for i in range(n)]
def grid(w,h):
    pts=[[140+x*440/(w-1),330+y*380/(h-1)] for y in range(h) for x in range(w)]
    edges=[]
    for y in range(h):
        for x in range(w):
            if x<w-1: edges.append([y*w+x,y*w+x+1])
            if y<h-1: edges.append([y*w+x,(y+1)*w+x])
    return pts,edges

def prism(n):
    return ring(n)+ring(n,112,98),cycle(n)+[[a+n,b+n] for a,b in cycle(n)]+[[i,i+n] for i in range(n)]

specs=[]
def add(name,kind,points,edges,anchors=(),target=5): specs.append((name,kind,points,edges,list(anchors),target))
add('Loose ends','One small move.',[[200,360],[520,360],[520,680],[200,680]],cycle(4),target=1)
add('A gentle pull','Find a little space.',ring(5),cycle(5)+[[0,2]],target=4)
add('Butterfly','Let the wings unfold.',ring(6),cycle(6)+[[0,2],[0,4]],target=7)
add('Sunburst','Work from the outside in.',*wheel(5),target=9)
add('Still point','The square knot stays put.',*grid(3,2),anchors=[0],target=8)
add('Heartstrings','A quiet centre. A tangled edge.',*wheel(6),anchors=[6],target=13)
p,e=grid(3,3); e+=[[0,4],[4,8]]
add('Gossamer','Give each thread its own path.',p,e,anchors=[0,2],target=18)
add('Within','There is a web inside the web.',*prism(4),anchors=[0],target=16)
add('Afterglow','Follow one thread at a time.',*wheel(7),anchors=[7],target=18)
p,e=grid(4,3); e+=[[0,5],[2,7],[5,10]]
add('Tidal lace','Sometimes it gets worse first.',p,e,anchors=[0,3],target=28)
add('Double bloom','Find the shape inside.',*prism(5),anchors=[0,2],target=23)
add('Silk symphony','Take your time.',*prism(6),anchors=[0,3],target=30)

rng=random.Random(14102026)
levels=[]
audit=[]
for index,(name,note,solution,edges,anchors,target) in enumerate(specs):
    assert inspect(solution,edges)==0,(name,inspect(solution,edges))
    best=None
    movable=[i for i in range(len(solution)) if i not in anchors]
    for _ in range(300):
        order=movable[:];rng.shuffle(order)
        start=[p[:] for p in solution]
        for a,b in zip(movable,order): start[a]=solution[b][:]
        count=inspect(start,edges)
        if count and (best is None or abs(count-target)<abs(best[0]-target)):best=(count,start)
    count,start=best
    if index==0:
        start=[p[:] for p in solution];start[1],start[2]=start[2],start[1]
        count=inspect(start,edges)
    # Fixed seeds sample careless, independent placements. This is a regression
    # signal for accidental auto-wins, not a player difficulty/retention estimate.
    random_wins=0
    for _ in range(300):
        sample=[[rng.uniform(80,640),rng.uniform(290,750)] if i not in anchors else solution[i][:] for i in range(len(solution))]
        random_wins+=inspect(sample,edges)==0
    levels.append(dict(name=name,note=note,points=start,edges=edges,anchors=anchors,solution=solution,initial_tangles=count))
    audit.append(dict(level=index+1,name=name,knots=len(solution),strands=len(edges),anchors=len(anchors),initial_tangles=count,witness_tangles=0,random_layout_wins=random_wins,samples=300))
(ROOT/'data/levels.json').write_text(json.dumps(levels,indent=2)+'\n')
(ROOT/'docs/difficulty-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
print('Verified 12 planar solutions; initial tangles:',[l['initial_tangles'] for l in levels])
print('Random-layout wins / 300:',[a['random_layout_wins'] for a in audit])
