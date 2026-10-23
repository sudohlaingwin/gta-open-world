extends Node3D
## Slice 97 REAL SCALE (owner complaint 2026-10-23 ~20:29:
## "buildings must be MUCH bigger than characters like real
## life, right now they look like little toys placed around").
## Player stays ~1.92 m (NOT shrunk — shrinking the player
## would fake the ratio). Measured before-state (main.tscn +
## dressing code, sim-verified): village slab houses are
## FLOATING slabs (2.0 x 0.8 x 4.0 at y 2.0, nothing to the
## ground, ~2.75 m total); scene stilt houses ~3.05 m; East
## Fields stilt houses ~4.6 m; hamlet houses ~3.8 m; Mindon
## buildings 2.8-3.6 m walls; school ~3.8 m; village trees
## ~4.8 m; East Fields trees ~5.5 m; route trees ~5.4 m.
## After-state in this file: village rebuilds ~6.95 m, stilt
## rebuilds ~6.4 m, East Fields ~6.9 m, hamlet ~6.8 m, Mindon
## ~5.8-7.6 m, school ~6.5 m, StiltHouse13 ~6.9 m, trees
## 9-11 m by type. Positions NEVER move — only sizes change.
##
## Method (runtime dressing only, no .tscn edits): grouped
## houses scale as whole groups (children, including solids
## and facade details, scale with them); flat scene houses
## are REBUILT (old floating slab hidden, new ground-to-roof
## house + new layer-1 solid — the stated replace-not-add
## collider exception; old solids sit inside the new
## footprint and are harmless); world-sibling colliders of
## scaled groups (Mindon camblocks, Stilt13/School solids)
## scale with position.y *= s so they stay grounded and cover
## the new walls. Trees scale with their detail sets (S93/S94
## root/branch/canopy/fruit nodes are world-sibling or holder
## children positioned by absolute coords — scaling a trunk
## without them would strand floating fruit, so they are
## transformed around the same ground point, same factor).
## Dressing lives at depth 1 (scene) AND depth 2 (holder
## groups: EastDistrict62, Curves75, Realism93/94/95 roots),
## so every scan searches both levels.
## Excluded with reason: StiltHouse17_5/18_6 are open
## pavilions (deck + legs + roof, no walls) whose plans
## ALREADY overlap 1 x 2 m — scaling both worsens it;
## banana clumps stay ~4.5 m (real bananas are short);
## toddy/coconut palms are already 9-11 m; House5-8 camblocks
## are pre-existing orphans (no meshes) and are untouched.
## Zero colliders on new dressing EXCEPT the house solids
## above (stated exception). StandardMaterial3D only.

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Scale97") != null:
		return
	var n := Node3D.new()
	n.name = "Scale97"
	n.set_script(load("res://scale97.gd"))
	world.call_deferred("add_child", n)

var _frames: int = 0
var _done: bool = false

func _process(_delta: float) -> void:
	# Frame >= 120: after S70 (12), S73 (26), S93 (40), S94
	# (60), S95 (80) and S96-taper (100) have all run, so the
	# scale lands on final geometry.
	_frames += 1
	if _frames < 120 or _done:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	_apply(world)
	_done = true

func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)

func _cyl(parent: Node3D, nm: String, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bot
	mesh.height = h
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

func _all_nodes(world: Node3D) -> Array:
	# Recursive: Curves75 groups (hamlet houses, loop and
	# hamlet trees) sit at depth 3 (world -> BusRoute75 ->
	# Curves75 -> group). A depth-2 scan silently missed them
	# (Slice 97 sim finding); recursion misses nothing.
	var out: Array = []
	var stack: Array = [world]
	while stack.size() > 0:
		var cur := stack.pop_back() as Node
		for c in cur.get_children():
			out.append(c)
			if c is Node3D:
				stack.append(c)
	return out

func _find(world: Node3D, nm: String) -> Node3D:
	for n in _all_nodes(world):
		if String(n.name) == nm:
			return n as Node3D
	return null

func _scale_group(world: Node3D, nm: String, s: float) -> bool:
	var n := _find(world, nm)
	if n == null:
		return false
	n.scale *= s
	return true

func _scale_collider(world: Node3D, nm: String, s: float) -> bool:
	# World-sibling body whose shape is centred at half its
	# height: scale the node AND lift its centre by s so the
	# shape stays grounded and covers the new walls.
	var n := _find(world, nm)
	if n == null:
		return false
	n.scale *= s
	n.position.y *= s
	return true

func _transform_around(n: Node3D, centre: Vector3, s: float) -> void:
	n.position = centre + (n.position - centre) * s
	n.scale *= s

func _village_house(world: Node3D, idx: int, cx: float, cz: float, w: float, d: float = 7.0) -> void:
	# Hide the floating slab + roof, build a real 2-storey
	# house on the same centre: ground 0..3.0, slab, upper
	# 3.2..5.8, pitched roof. Door + windows on the +z face
	# (night97 glows align: x +/-w*0.28, y 1.7,
	# z cz+d/2+0.06). New layer-1 solid (replace, not add).
	# d = 7.0 keeps the exact Slice 97 numbers (apex 6.95);
	# smaller d (Houses 3/4, see _apply) uses the same roof
	# pitch (0.252 rad) with a shorter run (apex ~6.52).
	for nm in ["House%d" % idx, "Roof%d" % idx]:
		var old := world.get_node_or_null(nm) as Node3D
		if old != null:
			old.visible = false
	var h := Node3D.new()
	h.name = "House97_%d" % idx
	h.position = Vector3(cx, 0.0, cz)
	world.add_child(h)
	var plaster := _mat(Color(0.82, 0.72, 0.58, 1.0), 0.95)
	var roof_m := _mat(Color(0.55, 0.25, 0.20, 1.0), 0.9)
	var wood := _mat(Color(0.45, 0.30, 0.18, 1.0), 0.9)
	var win_m := _mat(Color(0.85, 0.80, 0.60, 1.0), 0.6)
	_box(h, "Ground97", Vector3(w, 3.0, d), Vector3(0.0, 1.5, 0.0), plaster)
	_box(h, "Slab97", Vector3(w + 0.2, 0.2, d + 0.2), Vector3(0.0, 3.1, 0.0), plaster)
	_box(h, "Upper97", Vector3(w, 2.6, d), Vector3(0.0, 4.5, 0.0), plaster)
	var apex := 6.95
	if d >= 6.9:
		_box(h, "RoofS97", Vector3(w + 0.4, 0.18, 4.1), Vector3(0.0, 6.35, 1.95), roof_m, Vector3(0.252, 0.0, 0.0))
		_box(h, "RoofN97", Vector3(w + 0.4, 0.18, 4.1), Vector3(0.0, 6.35, -1.95), roof_m, Vector3(-0.252, 0.0, 0.0))
		_box(h, "Door97", Vector3(0.9, 2.0, 0.12), Vector3(0.0, 1.0, 3.56), wood)
		for sx in [-1.0, 1.0]:
			_box(h, "WinG97_%d" % int(sx), Vector3(0.8, 0.9, 0.08), Vector3(sx * w * 0.28, 1.7, 3.53), win_m)
			_box(h, "WinU97_%d" % int(sx), Vector3(0.8, 0.9, 0.08), Vector3(sx * w * 0.28, 4.5, 3.53), win_m)
	else:
		var run_h := d * 0.5 + 0.43
		var slab_len := run_h / cos(0.252)
		var czr := d * 0.25 + 0.1975
		var rise := run_h * tan(0.252)
		var cy := 5.8 + rise * 0.5
		apex = 5.8 + rise + 0.09
		_box(h, "RoofS97", Vector3(w + 0.4, 0.18, slab_len), Vector3(0.0, cy, czr), roof_m, Vector3(0.252, 0.0, 0.0))
		_box(h, "RoofN97", Vector3(w + 0.4, 0.18, slab_len), Vector3(0.0, cy, -czr), roof_m, Vector3(-0.252, 0.0, 0.0))
		_box(h, "Door97", Vector3(0.9, 2.0, 0.12), Vector3(0.0, 1.0, d * 0.5 + 0.06), wood)
		for sx in [-1.0, 1.0]:
			_box(h, "WinG97_%d" % int(sx), Vector3(0.8, 0.9, 0.08), Vector3(sx * w * 0.28, 1.7, d * 0.5 + 0.03), win_m)
			_box(h, "WinU97_%d" % int(sx), Vector3(0.8, 0.9, 0.08), Vector3(sx * w * 0.28, 4.5, d * 0.5 + 0.03), win_m)
	var body := StaticBody3D.new()
	body.name = "House97Solid_%d" % idx
	body.position = Vector3(cx, apex * 0.5, cz)
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.name = "Shape97"
	var box := BoxShape3D.new()
	box.size = Vector3(w, apex, d)
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)

func _stilt_rebuild(world: Node3D, tag: String, cx: float, cz: float, hide_group: String) -> void:
	# Raised-floor stilt house on the same centre: posts to
	# 1.5, floor 1.5..1.8, walls 1.8..5.0, pitched roof apex
	# ~6.4, stairs to the floor, door + windows on +z
	# (night97 glows align: x +/-2.0, y 2.6, z 3.06).
	if hide_group != "":
		var g := world.get_node_or_null(hide_group) as Node3D
		if g != null:
			for c in g.get_children():
				if c is MeshInstance3D:
					(c as MeshInstance3D).visible = false
	else:
		for c in world.get_children():
			if String(c.name).begins_with("StiltDeck_%s" % tag) or String(c.name).begins_with("StiltPillar_%s" % tag) or String(c.name) == "StiltWalls_%s" % tag or String(c.name) == "StiltRoof_%s" % tag:
				if c is MeshInstance3D:
					(c as MeshInstance3D).visible = false
	var h := Node3D.new()
	h.name = "Stilt97_%s" % tag
	h.position = Vector3(cx, 0.0, cz)
	world.add_child(h)
	var wood := _mat(Color(0.45, 0.30, 0.18, 1.0), 0.9)
	var plaster := _mat(Color(0.82, 0.72, 0.58, 1.0), 0.95)
	var roof_m := _mat(Color(0.55, 0.25, 0.20, 1.0), 0.9)
	var win_m := _mat(Color(0.85, 0.80, 0.60, 1.0), 0.6)
	for px in [-3.4, 3.4]:
		for pz in [-2.5, 2.5]:
			_cyl(h, "Post97_%d_%d" % [int(px), int(pz)], 0.18, 0.18, 1.5, Vector3(px, 0.75, pz), wood)
	_box(h, "Floor97", Vector3(8.0, 0.3, 6.0), Vector3(0.0, 1.65, 0.0), wood)
	_box(h, "Walls97", Vector3(7.0, 3.2, 6.0), Vector3(0.0, 3.4, 0.0), plaster)
	_box(h, "RoofS97", Vector3(7.4, 0.18, 3.4), Vector3(0.0, 5.7, 1.5), roof_m, Vector3(0.352, 0.0, 0.0))
	_box(h, "RoofN97", Vector3(7.4, 0.18, 3.4), Vector3(0.0, 5.7, -1.5), roof_m, Vector3(-0.352, 0.0, 0.0))
	_box(h, "Door97", Vector3(0.9, 1.9, 0.12), Vector3(0.0, 2.75, 3.06), wood)
	for sx in [-1.0, 1.0]:
		_box(h, "Win97_%d" % int(sx), Vector3(0.8, 0.9, 0.08), Vector3(sx * 2.0, 2.6, 3.03), win_m)
	var steps: Array = [[1.425, 3.3], [0.975, 3.7], [0.525, 4.1], [0.125, 4.5]]
	var si := 0
	for st in steps:
		_box(h, "Step97_%d" % si, Vector3(1.4, 0.25, 0.5), Vector3(0.0, float(st[0]), float(st[1])), wood)
		si += 1
	var body := StaticBody3D.new()
	body.name = "Stilt97Solid_%s" % tag
	body.position = Vector3(cx, 3.2, cz)
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.name = "Shape97"
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 6.4, 6.0)
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)

func _apply(world: Node3D) -> void:
	# 1. Village rebuilds. House1 is NARROW (2.6 wide):
	# Villager1 spawns at (-10,-10), 2 m from the centre —
	# a 5.0-wide house would swallow the spawn point.
	# Houses 3/4 are NARROW + SHALLOW (2.0 x 4.0): their
	# centres are only 4.47 m apart (dx 2, dz 4), so full
	# 5.0 x 7.0 houses would interpenetrate 3 x 3 m; the
	# original slabs only touched at one corner point.
	var village: Array = [[1, -8.0, -8.0, 2.6, 7.0], [2, 10.0, -10.0, 5.0, 7.0], [3, -14.0, 10.0, 2.0, 4.0], [4, -16.0, 14.0, 2.0, 4.0]]
	for v in village:
		_village_house(world, int(v[0]), float(v[1]), float(v[2]), float(v[3]), float(v[4]))
	# 2. Scene stilt rebuilds (flat _5/_6 pattern + grouped
	# 15_4, same toy slab walls).
	_stilt_rebuild(world, "5", -26.0, -16.0, "")
	_stilt_rebuild(world, "6", 0.0, -22.0, "")
	_stilt_rebuild(world, "15_4", -40.0, -4.0, "StiltHouse15_4")
	# 3. Grouped houses: East Fields x1.5 (12), hamlet x1.8
	# (4), Mindon x1.8 (6), StiltHouse13 x1.7, School x1.7.
	for i in range(12):
		_scale_group(world, "StiltHouse62_%d" % i, 1.5)
	for i in range(4):
		_scale_group(world, "HamletHouse75_%d" % i, 1.8)
	for nm in ["MindonTemple", "MindonHospital", "MindonPost", "MindonEdu", "MindonMRTV", "MindonShops"]:
		_scale_group(world, nm, 1.8)
		_scale_collider(world, nm + "CamBlock", 1.8)
	# MindonPost correction x(1.7/1.8): at x1.8 its wall
	# (x 142.6) sits 0.1 m INTO the Mindon street slab
	# (edge 142.5); x1.7 clears it by 0.4 m. Others stay x1.8.
	_scale_group(world, "MindonPost", 1.7 / 1.8)
	_scale_collider(world, "MindonPostCamBlock", 1.7 / 1.8)
	_scale_group(world, "StiltHouse13", 1.7)
	_scale_collider(world, "Stilt13Solid", 1.7)
	_scale_collider(world, "Stilt13CamBlock", 1.7)
	_scale_group(world, "School13", 1.7)
	_scale_collider(world, "SchoolSolid", 1.7)
	_scale_collider(world, "SchoolCamBlock", 1.7)
	# 4. Restyle + roof holders scale WITH their houses (same
	# centre, same factor — steps, rails, ribs, rust strips
	# stay aligned to the new roofs instead of floating at
	# the old height).
	for nm in ["Restyle94_300_-16", "Restyle94_330_-16"]:
		_scale_group(world, nm, 1.5)
	for nm in ["Restyle94_2075_78", "Restyle94_2125_78"]:
		_scale_group(world, nm, 1.8)
	for nm in ["Roof95_EF_300", "Roof95_EF_330"]:
		_scale_group(world, nm, 1.5)
	for nm in ["Roof95_Ham_2075", "Roof95_Ham_2125"]:
		_scale_group(world, nm, 1.8)
	# 5. Trees. Scene pairs by POSITION (trunk shares the
	# top's x/z exactly, whatever the name suffix): x2.0.
	var nodes := _all_nodes(world)
	var tops: Array = []
	var trunks: Array = []
	for n in nodes:
		if String(n.name).begins_with("TreeTop_"):
			tops.append(n)
		if String(n.name).begins_with("TreeTrunk_"):
			trunks.append(n)
	for top in tops:
		var tp: Vector3 = (top as Node3D).position
		var trunk: Node3D = null
		for tr in trunks:
			var rp: Vector3 = (tr as Node3D).position
			if absf(rp.x - tp.x) < 0.5 and absf(rp.z - tp.z) < 0.5:
				trunk = tr as Node3D
				break
		if trunk == null:
			continue
		var centre := Vector3(tp.x, 0.0, tp.z)
		_transform_around(top as Node3D, centre, 2.0)
		_transform_around(trunk, centre, 2.0)
	# S93 detail sets (world-sibling or holder children) around
	# the same 5 village trees, x2.0.
	var vtrees: Array = [Vector2(8.0, 6.0), Vector2(-12.0, 4.0), Vector2(14.0, -8.0), Vector2(-18.0, 8.0), Vector2(20.0, -12.0)]
	for n in nodes:
		var nm := String(n.name)
		if nm.begins_with("Tree93_"):
			var parts := nm.split("_")
			if parts.size() >= 2:
				var ti := int(parts[1])
				if ti >= 0 and ti < vtrees.size():
					var c: Vector2 = vtrees[ti]
					_transform_around(n as Node3D, Vector3(c.x, 0.0, c.y), 2.0)
	# S94 detail sets: MD trees are scene pairs (x2.0), hamlet
	# + East0 trees are route/EF groups (x1.8).
	var dmap: Dictionary = {"MD1": [Vector2(70.0, -105.0), 2.0], "MD2": [Vector2(100.0, -105.0), 2.0], "MD3": [Vector2(130.0, -105.0), 2.0], "Ham0": [Vector2(2055.0, 70.0), 1.8], "Ham1": [Vector2(2145.0, 70.0), 1.8], "East0": [Vector2(365.0, -10.0), 1.8]}
	for n in nodes:
		var nm := String(n.name)
		if nm.begins_with("Tree94_"):
			var parts := nm.split("_")
			if parts.size() >= 2 and dmap.has(parts[1]):
				var entry: Array = dmap[parts[1]]
				var c: Vector2 = entry[0]
				_transform_around(n as Node3D, Vector3(c.x, 0.0, c.y), float(entry[1]))
	# Grouped trees: East Fields x1.8, route/hamlet x1.8.
	for n in nodes:
		var nm := String(n.name)
		if nm.begins_with("Chill62_Tree_") or nm.begins_with("LoopTree75_") or nm.begins_with("HamletTree75_"):
			(n as Node3D).scale *= 1.8
	# Sheet trees by holder: flame + banyan were short
	# (~6.7 / ~7.6 m); toddy/coconut already 9-11 m, banana
	# stays naturally short (~4.5 m).
	for nm in ["Flame94", "Flame95"]:
		_scale_group(world, nm, 1.4)
	for nm in ["Banyan94", "Banyan95"]:
		_scale_group(world, nm, 1.3)
