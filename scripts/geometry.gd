extends RefCounted

# Geometry is independent of rendering. All contact counts, including collinear
# overlaps and nodes placed on unrelated strands, must clear before a win.
const NODE_GAP := 64.0
const STRAND_GAP := 25.0
const AREA := Rect2(66, 276, 588, 488)

static func segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d := b-a
	if d.length_squared()<0.0001: return p.distance_to(a)
	return p.distance_to(a+d*clampf((p-a).dot(d)/d.length_squared(),0.0,1.0))

static func intersects(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var x := (b-a).cross(c-a)
	var y := (b-a).cross(d-a)
	var u := (d-c).cross(a-c)
	var v := (d-c).cross(b-c)
	if x*y<0.0 and u*v<0.0: return true
	return minf(minf(segment_distance(a,c,d),segment_distance(b,c,d)),minf(segment_distance(c,a,b),segment_distance(d,a,b)))<0.5

static func inspect(points: Array[Vector2], edges: Array) -> Dictionary:
	var bad_edges: Dictionary = {}
	var bad_nodes: Dictionary = {}
	var marks: Array[Vector2] = []
	var count := 0
	for i in edges.size():
		var e: Array = [int(edges[i][0]),int(edges[i][1])]
		for j in range(i+1,edges.size()):
			var f: Array = [int(edges[j][0]),int(edges[j][1])]
			if e[0] in f or e[1] in f: continue
			if intersects(points[e[0]],points[e[1]],points[f[0]],points[f[1]]):
				count+=1; bad_edges[i]=true; bad_edges[j]=true
				var hit = Geometry2D.segment_intersects_segment(points[e[0]],points[e[1]],points[f[0]],points[f[1]])
				if hit is Vector2: marks.append(hit)
		for n in points.size():
			if n in e: continue
			if segment_distance(points[n],points[e[0]],points[e[1]])<STRAND_GAP:
				count+=1; bad_edges[i]=true; bad_nodes[n]=true
	for i in points.size():
		for j in range(i+1,points.size()):
			if points[i].distance_to(points[j])<NODE_GAP:
				count+=1; bad_nodes[i]=true; bad_nodes[j]=true
	return {"count":count,"edges":bad_edges,"nodes":bad_nodes,"marks":marks}

static func clamp_point(p: Vector2) -> Vector2:
	return p.clamp(AREA.position,AREA.end)
