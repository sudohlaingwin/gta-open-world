extends Node3D
## Slice 138 — VILLAGE DETAIL AUDIT ROUND, AUDIT-FIRST, under the owner's
## goal "OpenTaxi Thadingyut Night level game graphic".
## BOUNDARY (binding): take ONLY the visual STANDARD from the
## reference video. NEVER copy OpenTaxi assets, branding,
## names, maps, layouts, or URLs; no club, no Yangon copy, no
## flying cars. World stays village/Mindon/fields.
## AUDIT (audit138 + audit138b + audit138c, live headless, S137
## dressing complete, day 300 then night 900):
## - VILLAGE CENTRE HOMES: all 10 read dressed at 6 m. Yard
##   census (visible meshes within 10 m, holder descendants
##   excluded): House97_1 118, House97_2 171, House97_3 167,
##   House97_4 137, Stilt97_5 104, Stilt97_6 78, Stilt97_15_4 84,
##   School13 65, StiltHouse13 48, House6 269 — fences, benches,
##   jars, clotheslines (Line109/Cloth93/94 — the literal
##   "Clothesline" name search reads 0, a NAME artifact, not
##   a gap), firewood, flowers, baskets, tables, stools, carts.
##   NOTHING shipped for village-centre homes (would be padding).
## - PLAZA: Ground122_plaza at (0,5), 16x16; 82 tall meshes
##   within 12 m (lamps, well parts, baskets, canopies, poles,
##   firewood, flowers, trees, carts, benches). NOT a gap.
## - PATHS: Path 29 (OutPath59_East/Mindon) + Step 50 exist in
##   village bounds. Stone/Walkway/Trail read 0 — NAME
##   artifacts (paths are named Path/Step, not Stone). NOT a gap.
## - GRID: only 2 cells with no non-house tall mesh, both
##   fringe at x=-45 (nearest homes 16.8 m / 11.7 m away,
##   outside the inhabited cluster). NOT patched (same fringe
##   rule as S128/S136 — dressing the world edge would be
##   arbitrary placement).
## - NIGHT: every home has window glows within 8 m
##   (House97 7 each, Stilt97 4-5, School13 7, StiltHouse13 19,
##   House6 28, OoHouse 8-11 via Glow102 sets); village bounds
##   27 visible omnis + 242 emissive meshes. NO dark cluster.
##   NOTHING shipped for night (would be padding).
## - OO CLUSTER — THE ONE REAL GAP (S128 grid miss): the 3 Oo
##   houses (66,-16), (66,16), (74,-10) sit on the FLAT PALE
##   SHEET: per-house census finds ZERO Ground* patches within
##   12 m of any Oo house. S128's village grid counted these
##   cells "varied" only because its 7 m varied-guard credited
##   the tiny 1.8x1.8 OutPatch59 TREE-BASE patches (a tree base
##   is not yard ground). Each Oo house otherwise reads: a
##   detailed 74-mesh house + 1-3 OutTree59 trees + window
##   glows at night — a lone house on a flat sheet, visibly
##   sparser than every village-centre home. The Oo cluster
##   is a map POI (OoVillageDot) 16 m off the route, walkable
##   — NOT backdrop (unlike S136's Field97 at 127 m+), so a
##   fix here IS visible at 6 m play.
## SHIPPED (this file only, 3 meshes, zero .tscn edits): one
## front-yard dirt patch per Oo house (5.5x0.06x5.5, S122/S128
## dirt palette), placed by LIVE geometry, never hand-placed:
## front direction comes from each house's own Door102 child
## (OoHouse2 faces -z, the other two +z — S102 door_sgn;
## a +z guess for all three would have put OoHouse2's patch
## on its BACK side). Candidates ring the house (8 compass
## directions ordered by angle to the front, distances 8/10/12
## m); the first whose footprint clears every LOW mesh
## (global AABB min-y < 0.5: walls, plinths, steps, trunks,
## existing ground patches — expanded 0.3 m) wins. Sky/high
## meshes (canopies, roofs, glow planes) never block: a tree
## canopy overhanging a dirt patch is normal shade, not a
## collision. Terrain slabs and the base GroundMesh are
## excluded from blockers (footprint half-extent > 30 m).
## If no candidate clears, that house is SKIPPED and reported
## — never overlapped, never z-fighting. Patches are UNGATED
## (visible day AND night like S128 ground), zero colliders,
## zero per-frame work after _apply.
## DELIBERATELY NOT SHIPPED: yard OBJECTS for Oo houses
## (fences/jars/firewood/clotheslines) — ground variation is
## the S128-precedented fix for exactly this gap class;
## inventing yard contents for these houses would be
## arbitrary placement, and the owner judges whether yards
## need objects. Stated, not hidden.
## PERFORMANCE NOTE: ZERO new OmniLight3Ds, ZERO colliders,
## ZERO per-frame work after _apply. Names Ground138_
## match NONE of perf120's hide prefixes (Blade93_/94_/95_/
## 110_, Reed57_/62/107_/108_). Single pass at frame >= 800
## (after Realism134's 790), with a holders-ready retry gate:
## _apply runs only once OoHouse1/2/3 exist, so a
## fast-forward ordering quirk can never silently ship a
## patch at a wrong centre (S122-trim lesson).

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism138") != null:
		return
	var n: Node3D = Node3D.new()
	n.name = "Realism138"
	n.set_script(load("res://realism138.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if _done:
		return
	if _frames < 800:
		return
	if not _holders_ready(get_parent() as Node3D):
		return
	_done = true
	_apply(get_parent() as Node3D)

static func _mat(c: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _find_recursive(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f: Node = _find_recursive(c, nm)
		if f != null:
			return f
	return null

func _holders_ready(world: Node3D) -> bool:
	if world == null:
		return false
	for tag in ["OoHouse1", "OoHouse2", "OoHouse3"]:
		if _find_recursive(world, tag) == null:
			return false
	return true

func _ground_y(world: Node3D) -> float:
	var gm: Node3D = world.get_node_or_null("GroundMesh") as Node3D
	if gm != null:
		return gm.global_position.y
	return 0.0

## A blocker circle: centre XZ + radius, from a low mesh's world AABB.
## Returns true when the 5.5m patch square at (cx, cz) clears it.
static func _square_clears_circle(cx: float, cz: float, half: float, bx: float, bz: float, br: float) -> bool:
	var dx: float = maxf(absf(bx - cx) - half, 0.0)
	var dz: float = maxf(absf(bz - cz) - half, 0.0)
	return (dx * dx + dz * dz) > br * br

func _apply(world: Node3D) -> void:
	var gy: float = _ground_y(world)
	# Blocker circles from every LOW visible mesh (global AABB min-y < 0.5),
	# skipping terrain slabs (half-extent > 30 m) and the base GroundMesh.
	var blockers: Array = []
	var stack: Array = [world]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if not (x is MeshInstance3D):
			continue
		var mi: MeshInstance3D = x as MeshInstance3D
		if not mi.visible:
			continue
		if String(mi.name) == "GroundMesh":
			continue
		if mi.mesh == null:
			continue
		var sz: Vector3 = mi.mesh.get_aabb().size
		var sc: Vector3 = mi.global_transform.basis.get_scale()
		var hx: float = 0.5 * sz.x * absf(sc.x)
		var hz: float = 0.5 * sz.z * absf(sc.z)
		if hx > 30.0 or hz > 30.0:
			continue
		var miny: float = mi.global_position.y + (mi.mesh.get_aabb().position.y - 0.5 * sz.y) * sc.y
		if miny >= 0.5:
			continue
		var p: Vector3 = mi.global_position
		var r: float = maxf(hx, hz) + 0.3
		blockers.append([p.x, p.z, r])
	var mats: Array = [_mat(Color(0.52, 0.42, 0.30)), _mat(Color(0.45, 0.35, 0.25)), _mat(Color(0.62, 0.55, 0.38))]
	var hi: int = 0
	for hn in ["OoHouse1", "OoHouse2", "OoHouse3"]:
		var holder: Node3D = _find_recursive(world, hn) as Node3D
		if holder == null:
			continue
		var centre: Vector3 = holder.global_position
		# Front direction from the house's own Door102 child (live geometry).
		var front: Vector2 = Vector2(0.0, 1.0)
		var door: Node = _find_recursive(holder, "Door102")
		if door != null and door is Node3D:
			var dp: Vector3 = (door as Node3D).global_position
			var dv: Vector2 = Vector2(dp.x - centre.x, dp.z - centre.z)
			if dv.length() > 0.1:
				front = dv.normalized()
		# Candidate directions ordered by angle to front: front, +-45, +-90, +-135, back.
		var base_ang: float = atan2(front.x, front.y)
		var dirs: Array = []
		for da in [0.0, 0.785398, -0.785398, 1.570796, -1.570796, 2.356194, -2.356194, 3.141593]:
			var a: float = base_ang + da
			dirs.append(Vector2(sin(a), cos(a)))
		var placed: bool = false
		for dist in [8.0, 10.0, 12.0]:
			if placed:
				break
			for d in dirs:
				var cx: float = centre.x + d.x * dist
				var cz: float = centre.z + d.y * dist
				var clear: bool = true
				for b in blockers:
					if not _square_clears_circle(cx, cz, 2.75, float(b[0]), float(b[1]), float(b[2])):
						clear = false
						break
				if clear:
					_box(world, Vector3(5.5, 0.06, 5.5), mats[hi % 3], Vector3(cx, gy + 0.03, cz), "Ground138_%s" % hn)
					hi += 1
					placed = true
					break
		# If no candidate clears, the house is skipped (reported by the sim count).
