extends Node3D
## Slice 97 TERTIARY SHEET DETAIL + NIGHT / SCALE / EDGE POLISH
## (owner standing rules: ~50 items per push, graphics-first).
## Slice 96 deferred its tertiary sheet detail (the three
## complaints + steering filled it, no padding added) — this
## batch picks it up, plus polish on Slice 96's own work:
## night lights for the Slice 94 pagodas (which had none),
## dressing for the new Slice 96 extension land (which was
## mostly empty planes + border pines), and window/vehicle
## dressing the earlier passes never reached.
## Runtime dressing ONLY. No .tscn edits, no bus-system
## changes, minibus NOT rewired, big bus NOT rewired (Slice 81
## binding limit — bus pillars below are children of the Bus
## node, they move with it, they do not touch the controller),
## touch controls untouched, zero colliders on new dressing,
## StandardMaterial3D only, no dead specular lines, no
## fog/SSAO/glow claims (no WorldEnvironment exists),
## no photorealism claims: stylised smooth procedural
## rebuilds from the owner's 2D sheets, stated plainly.
## Runs at frame >= 140: after Slice 70 (12), Slice 73 (26),
## Slice 93 (40), Slice 94 (60), Slice 95 (80), Slice 95b
## realism96 (100) and Slice 96 scale97 (120), so every
## position below is read off FINAL geometry.
## Counting: one item = one placed assembly, or one
## symmetric pair / one set of identical parts on one
## figure, house, pagoda or vehicle. 60 items:
##   PEOPLE 10: male longyi front apron panels (1 per male)
##   TREES 10: third + fourth sheet trees, 5 types x 2 sites
##   PAGODAS 9: golden arches + shrines, brick minis +
##     lions, white stairs + minis, forest hut, hilltop
##     bell frame + shelter hut
##   HOUSES 12: EF shutters x2, hamlet windows+shutters x2,
##     benches x4, banana clumps x4
##   NIGHT 7: pagoda lanterns x5, route lamps x2
##   EXTENSION 10: crop-row fields x6, ponds x2, paths x2
##   VEHICLES 2: bus window pillars, minibus window pillars

static func _mat(c: Color, rough: float, met: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = met
	return m

static func _glow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.75, 0.4, 1.0)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.35, 1.0)
	m.emission_energy_multiplier = 1.2
	m.roughness = 1.0
	return m

static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node3D, r: float, mat: Material, pos: Vector3, nm: String, sy: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0 * sy
	mi.mesh = sm
	mi.position = pos
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _holder(root: Node3D, pos: Vector3, rot_y: float, nm: String) -> Node3D:
	var g := Node3D.new()
	g.name = nm
	g.position = pos
	g.rotation.y = rot_y
	root.add_child(g)
	return g

static func _find_rec(n: Node, nm: String) -> Node:
	# Slice 94 pagodas live under Dress94Root, Slice 62
	# stilt houses under the chill district holder, and
	# Slice 75 hamlet houses under Curves75 — none are
	# direct world children, so a root-only lookup
	# silently misses them (caught by the Slice 97 sim).
	if n.name == nm:
		return n
	for c in n.get_children():
		var r := _find_rec(c, nm)
		if r != null:
			return r
	return null

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism98") != null:
		return
	var n := Node3D.new()
	n.name = "Realism98"
	n.set_script(load("res://realism98.gd"))
	world.call_deferred("add_child", n)

var _frames: int = 0
var _done: bool = false
var _lantern_omnis: Array = []
var _lantern_heads: Array = []

func _process(_delta: float) -> void:
	_frames += 1
	if _frames < 140 or _done:
		# Lantern gating still runs every frame once applied
		# (same pattern as night97: gate on daylight < 0.15).
		if _done:
			_gate_lanterns()
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	_people_aprons(world)
	_trees(world)
	_pagodas(world)
	_houses(world)
	_night(world)
	_extension(world)
	_vehicle_pillars(world)
	_done = true
	_gate_lanterns()

func _daylight(world: Node3D) -> float:
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		return float(dn.call("daylight"))
	return 1.0

func _gate_lanterns() -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var night := _daylight(world) < 0.15
	for o in _lantern_omnis:
		(o as OmniLight3D).visible = night
	for h in _lantern_heads:
		(h as MeshInstance3D).visible = night

func _lantern(parent: Node3D, pos: Vector3, nm: String, energy: float, rng: float) -> void:
	# Pole + warm emissive head + gated omni. The omni and
	# head are stored on the Realism98 node for per-frame
	# gating (night97 pattern); the pole is always visible.
	var pole_m := _mat(Color(0.20, 0.16, 0.12, 1.0), 0.9)
	_cyl(parent, 0.06, 0.06, 2.2, pole_m, pos + Vector3(0.0, 1.1, 0.0), nm + "_Pole")
	var head := _box(parent, Vector3(0.30, 0.30, 0.30), _glow_mat(), pos + Vector3(0.0, 2.30, 0.0), nm + "_Head")
	var o := OmniLight3D.new()
	o.name = nm + "_Omni"
	o.position = pos + Vector3(0.0, 2.30, 0.0)
	o.light_energy = energy
	o.omni_range = rng
	o.light_color = Color(1.0, 0.75, 0.45, 1.0)
	parent.add_child(o)
	_lantern_omnis.append(o)
	_lantern_heads.append(head)

static func _people_aprons(world: Node3D) -> void:
	# Male longyi front apron fold panels, one per male
	# figure. Males are detected by the Slice 94 collar node
	# (Collar94 exists on sex == 0 only) — no name-hash
	# re-derivation, so the split matches S94 exactly.
	# Female longyis have no front apron flap on the
	# sheets, so females get none.
	var male_longyi := _mat(Color(0.20, 0.15, 0.38, 1.0), 0.85)
	for child in world.get_children():
		var nm := String(child.name)
		if nm != "Player" and not nm.begins_with("Villager"):
			continue
		if child.get_node_or_null("Collar94") == null:
			continue
		var lpiv := child.get_node_or_null("LongyiPivot58") as Node3D
		if lpiv == null:
			continue
		if lpiv.get_node_or_null("Apron98") != null:
			continue
		# Panel in lpiv-local coords: longyi flare is
		# top r ~0.24 -> bottom r ~0.32, so the panel sits
		# 0.30 proud of the tube centre and tilts -0.09 rad
		# to follow the flare. Panel spans lpiv-local
		# y -0.275..-0.825, inside the longyi's -0.30..-0.80
		# band (tube centre -0.55, height 0.50).
		_box(lpiv, Vector3(0.30, 0.55, 0.02), male_longyi, Vector3(0.0, -0.55, 0.30), "Apron98", Vector3(-0.09, 0.0, 0.0))

static func _tree_toddy(parent: Node3D, pos: Vector3, nm: String) -> void:
	# Sheet: tall straight trunk, fan of fronds at the
	# crown, dry fronds hanging below the crown.
	var trunk_m := _mat(Color(0.45, 0.35, 0.22, 1.0), 0.95)
	var leaf_m := _mat(Color(0.20, 0.45, 0.18, 1.0), 0.9)
	var dry_m := _mat(Color(0.55, 0.45, 0.25, 1.0), 0.95)
	var g := _holder(parent, pos, 0.0, nm)
	_cyl(g, 0.22, 0.30, 7.0, trunk_m, Vector3(0.0, 3.5, 0.0), nm + "_Trunk")
	for i in range(8):
		var a := float(i) / 8.0 * 6.283185307179586
		var frond := _box(g, Vector3(0.28, 0.04, 2.4), leaf_m, Vector3(sin(a) * 1.0, 7.15, cos(a) * 1.0), nm + "_Frond%d" % i, Vector3(-0.45 * cos(a), 0.0, 0.45 * sin(a)))
		frond.rotation.y = -a
	for i in range(4):
		var a := float(i) / 4.0 * 6.283185307179586 + 0.4
		_box(g, Vector3(0.22, 0.03, 1.4), dry_m, Vector3(sin(a) * 0.6, 6.6, cos(a) * 0.6), nm + "_Dry%d" % i, Vector3(0.9 * cos(a), 0.0, -0.9 * sin(a)))

static func _tree_coconut(parent: Node3D, pos: Vector3, nm: String) -> void:
	# Sheet: two-segment tilted trunk, arching fronds,
	# nut cluster at the crown.
	var trunk_m := _mat(Color(0.40, 0.30, 0.20, 1.0), 0.95)
	var leaf_m := _mat(Color(0.18, 0.42, 0.20, 1.0), 0.9)
	var nut_m := _mat(Color(0.35, 0.25, 0.15, 1.0), 0.9)
	var g := _holder(parent, pos, 0.0, nm)
	_cyl(g, 0.24, 0.30, 4.0, trunk_m, Vector3(0.0, 2.0, 0.0), nm + "_TrunkA", Vector3(0.10, 0.0, 0.0))
	_cyl(g, 0.20, 0.24, 3.5, trunk_m, Vector3(0.0, 5.5, 0.45), nm + "_TrunkB", Vector3(0.18, 0.0, 0.0))
	for i in range(8):
		var a := float(i) / 8.0 * 6.283185307179586
		_box(g, Vector3(0.30, 0.04, 2.6), leaf_m, Vector3(sin(a) * 1.1, 7.0, 0.9 + cos(a) * 1.1), nm + "_Frond%d" % i, Vector3(-0.85 * cos(a), 0.0, 0.85 * sin(a)))
	for i in range(5):
		var a := float(i) / 5.0 * 6.283185307179586
		_sphere(g, 0.16, nut_m, Vector3(sin(a) * 0.35, 6.75, 0.95 + cos(a) * 0.35), nm + "_Nut%d" % i)

static func _tree_flame(parent: Node3D, pos: Vector3, nm: String) -> void:
	# Sheet: spreading branches, green canopy, red
	# flower clusters. Taller than the Slice 94 flame
	# (trunk 4.5 m, canopy top ~8.5 m) so it reads at the
	# same scale as the Slice 96 scaled flame (~8.3 m).
	var trunk_m := _mat(Color(0.35, 0.25, 0.18, 1.0), 0.95)
	var leaf_m := _mat(Color(0.22, 0.48, 0.20, 1.0), 0.9)
	var flower_m := _mat(Color(0.85, 0.15, 0.10, 1.0), 0.8)
	var g := _holder(parent, pos, 0.0, nm)
	_cyl(g, 0.35, 0.50, 4.5, trunk_m, Vector3(0.0, 2.25, 0.0), nm + "_Trunk")
	for i in range(4):
		var a := float(i) / 4.0 * 6.283185307179586 + 0.4
		_cyl(g, 0.12, 0.20, 3.0, trunk_m, Vector3(sin(a) * 1.2, 5.2, cos(a) * 1.2), nm + "_Branch%d" % i, Vector3(0.7 * cos(a), 0.0, -0.7 * sin(a)))
	for i in range(5):
		var a := float(i) / 5.0 * 6.283185307179586
		_sphere(g, 1.6, leaf_m, Vector3(sin(a) * 1.8, 6.8, cos(a) * 1.8), nm + "_Canopy%d" % i)
	_sphere(g, 1.8, leaf_m, Vector3(0.0, 7.4, 0.0), nm + "_CanopyTop")
	for i in range(8):
		var a := float(i) / 8.0 * 6.283185307179586 + 0.2
		_sphere(g, 0.35, flower_m, Vector3(sin(a) * 2.6, 7.0, cos(a) * 2.6), nm + "_Flower%d" % i)

static func _tree_banana(parent: Node3D, pos: Vector3, nm: String) -> void:
	# Sheet: broad leaves, hanging bunch, purple bud.
	# Naturally short (~4 m) — banana is not scaled up
	# in Slice 96 either, and a 9 m banana would be wrong.
	var stalk_m := _mat(Color(0.30, 0.45, 0.20, 1.0), 0.9)
	var leaf_m := _mat(Color(0.20, 0.50, 0.22, 1.0), 0.9)
	var fruit_m := _mat(Color(0.55, 0.65, 0.20, 1.0), 0.85)
	var bud_m := _mat(Color(0.45, 0.15, 0.35, 1.0), 0.8)
	var g := _holder(parent, pos, 0.0, nm)
	for i in range(3):
		var a := float(i) / 3.0 * 6.283185307179586
		_cyl(g, 0.12, 0.16, 2.2, stalk_m, Vector3(sin(a) * 0.4, 1.1, cos(a) * 0.4), nm + "_Stalk%d" % i)
	for i in range(10):
		var a := float(i) / 10.0 * 6.283185307179586
		_box(g, Vector3(0.60, 0.03, 2.2), leaf_m, Vector3(sin(a) * 1.0, 2.6, cos(a) * 1.0), nm + "_Leaf%d" % i, Vector3(-0.55 * cos(a), 0.0, 0.55 * sin(a)))
	for i in range(4):
		_cyl(g, 0.05, 0.05, 0.5, fruit_m, Vector3(0.15 * float(i), 2.0 - 0.15 * float(i), 0.3), nm + "_Fruit%d" % i, Vector3(0.5, 0.0, 0.0))
	_sphere(g, 0.18, bud_m, Vector3(0.0, 1.5, 0.35), nm + "_Bud", 1.4)

static func _tree_banyan(parent: Node3D, pos: Vector3, nm: String) -> void:
	# Sheet: multi-trunk, aerial roots reaching the
	# ground, dense canopy, small shrine at the base.
	var trunk_m := _mat(Color(0.40, 0.30, 0.22, 1.0), 0.95)
	var leaf_m := _mat(Color(0.16, 0.38, 0.18, 1.0), 0.9)
	var shrine_m := _mat(Color(0.85, 0.75, 0.55, 1.0), 0.9)
	var g := _holder(parent, pos, 0.0, nm)
	_cyl(g, 0.60, 0.90, 5.0, trunk_m, Vector3(0.0, 2.5, 0.0), nm + "_Trunk")
	for i in range(3):
		var a := float(i) / 3.0 * 6.283185307179586 + 0.5
		_cyl(g, 0.20, 0.30, 4.0, trunk_m, Vector3(sin(a) * 1.2, 2.0, cos(a) * 1.2), nm + "_Trunk%d" % i)
	for i in range(6):
		var a := float(i) / 6.0 * 6.283185307179586
		_cyl(g, 0.06, 0.06, 4.5, trunk_m, Vector3(sin(a) * 2.2, 2.25, cos(a) * 2.2), nm + "_Root%d" % i)
	for i in range(6):
		var a := float(i) / 6.0 * 6.283185307179586 + 0.3
		_sphere(g, 1.9, leaf_m, Vector3(sin(a) * 2.0, 7.0, cos(a) * 2.0), nm + "_Canopy%d" % i)
	_sphere(g, 2.1, leaf_m, Vector3(0.0, 7.8, 0.0), nm + "_CanopyTop")
	_box(g, Vector3(0.8, 0.9, 0.8), shrine_m, Vector3(1.8, 0.45, 1.8), nm + "_Shrine")
	_box(g, Vector3(1.0, 0.12, 1.0), shrine_m, Vector3(1.8, 0.96, 1.8), nm + "_ShrineRoof")

static func _trees(world: Node3D) -> void:
	# Third + fourth sheet trees on OPEN Slice 96
	# extension ground (x -670..-70 / 2450..3050 /
	# z -510..-210 / 110..410). These are new assemblies
	# at new positions, not duplicates of the Slice 94/95
	# tree positions. Site A south (z -350), Site B
	# north (z 300), each clear of roads, stops and the
	# extension fields/paths below by 20 m or more.
	_tree_toddy(world, Vector3(-300.0, 0.0, -350.0), "Toddy98_A")
	_tree_coconut(world, Vector3(300.0, 0.0, -350.0), "Coconut98_A")
	_tree_flame(world, Vector3(900.0, 0.0, -350.0), "Flame98_A")
	_tree_banana(world, Vector3(1500.0, 0.0, -350.0), "Banana98_A")
	_tree_banyan(world, Vector3(2200.0, 0.0, -350.0), "Banyan98_A")
	_tree_toddy(world, Vector3(-400.0, 0.0, 300.0), "Toddy98_B")
	_tree_coconut(world, Vector3(400.0, 0.0, 300.0), "Coconut98_B")
	_tree_flame(world, Vector3(2600.0, 0.0, 300.0), "Flame98_B")
	_tree_banana(world, Vector3(2800.0, 0.0, 300.0), "Banana98_B")
	_tree_banyan(world, Vector3(2000.0, 0.0, 300.0), "Banyan98_B")

static func _pagodas(world: Node3D) -> void:
	# Tertiary sheet features the Slice 94/95 passes
	# never reached. All holders are children of the
	# world root, unrotated, so holder-local coords
	# equal world offsets from the holder origin.
	# Zero colliders on every piece.
	var gold_m := _mat(Color(0.95, 0.75, 0.20, 1.0), 0.35, 0.3)
	var brick_m := _mat(Color(0.55, 0.30, 0.22, 1.0), 0.9)
	var white_m := _mat(Color(0.92, 0.90, 0.86, 1.0), 0.85)
	var wood_m := _mat(Color(0.45, 0.32, 0.20, 1.0), 0.9)
	var roof_m := _mat(Color(0.55, 0.15, 0.12, 1.0), 0.8)
	# GOLDEN (700,-50): gate archways on the +z/-z
	# terrace faces (terrace A is 10x10, so faces at
	# z +/-5.0; arches sit just outside at +/-5.4) +
	# base corner shrines on terrace A (top y 0.6).
	var g := _find_rec(world, "PagodaGold94") as Node3D
	if g != null:
		for fz in [-1.0, 1.0]:
			for sx in [-1.0, 1.0]:
				_box(g, Vector3(0.30, 2.20, 0.30), gold_m, Vector3(sx * 0.90, 1.10, fz * 5.40), "GateArch98_%d_%d" % [int(fz), int(sx)])
			_box(g, Vector3(2.40, 0.30, 0.30), gold_m, Vector3(0.0, 2.30, fz * 5.40), "GateLintel98_%d" % int(fz))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_box(g, Vector3(0.80, 1.00, 0.80), gold_m, Vector3(sx * 4.20, 1.10, sz * 4.20), "CornerShrine98_%d_%d" % [int(sx), int(sz)])
				_cyl(g, 0.05, 0.35, 0.60, gold_m, Vector3(sx * 4.20, 1.90, sz * 4.20), "CornerSpire98_%d_%d" % [int(sx), int(sz)])
	# BRICK (1100,-50): corner mini-stupas on terrace C
	# (top y 2.4, terrace 5x5 so corners at +/-2.5;
	# minis sit inset at +/-2.0) + base lions in front
	# of terrace A (face z 4.0, lions at z 4.6).
	var b := _find_rec(world, "PagodaBrick94") as Node3D
	if b != null:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_cyl(b, 0.05, 0.28, 1.00, brick_m, Vector3(sx * 2.00, 2.90, sz * 2.00), "CornerMini98_%d_%d" % [int(sx), int(sz)])
		for sx in [-1.0, 1.0]:
			_box(b, Vector3(0.60, 0.70, 0.80), brick_m, Vector3(sx * 2.50, 0.35, 4.60), "BaseLion98_%d" % int(sx))
			_sphere(b, 0.30, brick_m, Vector3(sx * 2.50, 0.85, 4.60), "BaseLionHead98_%d" % int(sx))
	# WHITE (1500,50): terrace stairs on all 4 sides
	# (round terrace A r 4.5, top y 0.6; steps descend
	# outward 0.45 per step) + diagonal corner mini-spires
	# on terrace B (top y 1.2, r 3.5; minis at r 2.7).
	var w := _find_rec(world, "PagodaWhite94") as Node3D
	if w != null:
		for d in range(4):
			var a := float(d) * 1.5707963267948966
			for i in range(4):
				var r := 4.75 + 0.45 * float(i)
				var y := 0.525 - 0.15 * float(i)
				var step := _box(w, Vector3(1.40, 0.15, 0.45), white_m, Vector3(sin(a) * r, y, cos(a) * r), "Stair98_%d_%d" % [d, i])
				step.rotation.y = a
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_cyl(w, 0.05, 0.22, 1.00, gold_m, Vector3(sx * 1.91, 1.70, sz * 1.91), "CornerMini98_%d_%d" % [int(sx), int(sz)])
	# FOREST (2000,50): offering hut on open ground at
	# local (-3.5, 0, 3.0) — clear of the tree (-2,-1),
	# flags (1.5,1.5)/(2.5,-1) and table (1.5,2.0).
	var f := _find_rec(world, "PagodaForest94") as Node3D
	if f != null:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_box(f, Vector3(0.12, 1.80, 0.12), wood_m, Vector3(-3.50 + sx * 0.80, 0.90, 3.00 + sz * 0.60), "HutPost98_%d_%d" % [int(sx), int(sz)])
		_box(f, Vector3(2.00, 0.08, 1.60), roof_m, Vector3(-3.50, 1.95, 3.00), "HutRoof98", Vector3(0.0, 0.0, 0.35))
		_box(f, Vector3(1.70, 0.08, 1.30), wood_m, Vector3(-3.50, 0.10, 3.00), "HutFloor98")
	# HILLTOP (2300,-50): bell frame + hanging bell on
	# open ground east of the hill (hill r_bot 5.0, so
	# x 6.5 is clear) + shelter hut west (x -6.5 clear
	# of the walls at +/-4.5 and the gate steps at z 5.2).
	var h := _find_rec(world, "PagodaHill94") as Node3D
	if h != null:
		for sx in [-1.0, 1.0]:
			_box(h, Vector3(0.15, 2.20, 0.15), wood_m, Vector3(6.50 + sx * 0.60, 1.10, 0.0), "BellPost98_%d" % int(sx))
		_box(h, Vector3(1.60, 0.15, 0.15), wood_m, Vector3(6.50, 2.15, 0.0), "BellBeam98")
		_cyl(h, 0.08, 0.28, 0.50, gold_m, Vector3(6.50, 1.75, 0.0), "Bell98")
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_box(h, Vector3(0.12, 1.80, 0.12), wood_m, Vector3(-6.50 + sx * 0.80, 0.90, sz * 0.60), "ShelterPost98_%d_%d" % [int(sx), int(sz)])
		_box(h, Vector3(2.00, 0.08, 1.60), roof_m, Vector3(-6.50, 1.95, 0.0), "ShelterRoof98", Vector3(0.0, 0.0, 0.35))
		_box(h, Vector3(1.70, 0.08, 1.30), wood_m, Vector3(-6.50, 0.10, 0.0), "ShelterFloor98")

static func _banana_clump(parent: Node3D, pos: Vector3, nm: String) -> void:
	# Same sheet banana as the tree builder, but as a
	# house-side clump (smaller: 3 stalks, 6 leaves).
	var stalk_m := _mat(Color(0.30, 0.45, 0.20, 1.0), 0.9)
	var leaf_m := _mat(Color(0.20, 0.50, 0.22, 1.0), 0.9)
	var fruit_m := _mat(Color(0.55, 0.65, 0.20, 1.0), 0.85)
	var g := _holder(parent, pos, 0.0, nm)
	for i in range(3):
		var a := float(i) / 3.0 * 6.283185307179586
		_cyl(g, 0.10, 0.14, 2.0, stalk_m, Vector3(sin(a) * 0.3, 1.0, cos(a) * 0.3), nm + "_Stalk%d" % i)
	for i in range(6):
		var a := float(i) / 6.0 * 6.283185307179586
		_box(g, Vector3(0.55, 0.03, 2.0), leaf_m, Vector3(sin(a) * 0.9, 2.4, cos(a) * 0.9), nm + "_Leaf%d" % i, Vector3(-0.55 * cos(a), 0.0, 0.55 * sin(a)))
	_cyl(g, 0.05, 0.05, 0.45, fruit_m, Vector3(0.0, 1.85, 0.25), nm + "_Bunch", Vector3(0.5, 0.0, 0.0))

static func _bench(parent: Node3D, pos: Vector3, nm: String) -> void:
	var wood_m := _mat(Color(0.45, 0.32, 0.20, 1.0), 0.9)
	var g := _holder(parent, pos, 0.0, nm)
	_box(g, Vector3(1.60, 0.08, 0.45), wood_m, Vector3(0.0, 0.45, 0.0), nm + "_Seat")
	for sx in [-1.0, 1.0]:
		_box(g, Vector3(0.10, 0.45, 0.40), wood_m, Vector3(sx * 0.70, 0.225, 0.0), nm + "_Leg%d" % int(sx))
	_box(g, Vector3(1.60, 0.35, 0.06), wood_m, Vector3(0.0, 0.70, -0.20), nm + "_Back")

static func _houses(world: Node3D) -> void:
	# EF shutters: attached as children of the
	# StiltHouse62 groups, so Slice 96's x1.5 scale
	# applies consistently (this pass runs at frame
	# 140, after scale97's frame-120 pass — but as
	# group children the shutters would scale right
	# even if the order were reversed). Window spans
	# (unscaled, group-local): Window62A x 0.85..1.55,
	# Window62B x 2.05..2.75, both at z 2.36, y 2.7.
	# Inner shutters 0.24 wide at offset 0.47 from the
	# window centre (A-right 1.55..1.79, B-left
	# 1.81..2.05, 0.02 gap between them); outer
	# shutters 0.35 wide at offset 0.525 (A-left
	# 0.50..0.85, B-right 2.75..3.10). Nothing overlaps
	# a window or the other shutter. Shutter depth
	# 0.05 centred z 2.42: back 2.395, 0.095 proud of
	# the wall face (2.30), 0.035 proud of the window
	# front (2.41) — normal shutter seating.
	var shutter_m := _mat(Color(0.35, 0.25, 0.15, 1.0), 0.9)
	for idx in [1, 2]:
		var grp := _find_rec(world, "StiltHouse62_%d" % idx) as Node3D
		if grp == null:
			continue
		# Each window gets exactly TWO shutters: the
		# inner-side shutter (facing the gap between
		# the windows) is 0.24 wide at offset 0.47, the
		# outer-side shutter is 0.35 wide at offset
		# 0.525. Window62A is the left window (centre
		# 1.2), so its inner side is +x; Window62B
		# (centre 2.4) has its inner side at -x.
		# Resulting spans, all touching but never
		# overlapping: A-outer 0.50..0.85, A window
		# 0.85..1.55, A-inner 1.55..1.79, gap 0.02,
		# B-inner 1.81..2.05, B window 2.05..2.75,
		# B-outer 2.75..3.10.
		var wa := grp.get_node_or_null("Window62A") as MeshInstance3D
		var wb := grp.get_node_or_null("Window62B") as MeshInstance3D
		if wa != null:
			_box(grp, Vector3(0.35, 0.70, 0.05), shutter_m, Vector3(wa.position.x - 0.525, wa.position.y, 2.42), "Shutter98_A_Outer")
			_box(grp, Vector3(0.24, 0.70, 0.05), shutter_m, Vector3(wa.position.x + 0.47, wa.position.y, 2.42), "Shutter98_A_Inner")
		if wb != null:
			_box(grp, Vector3(0.24, 0.70, 0.05), shutter_m, Vector3(wb.position.x - 0.47, wb.position.y, 2.42), "Shutter98_B_Inner")
			_box(grp, Vector3(0.35, 0.70, 0.05), shutter_m, Vector3(wb.position.x + 0.525, wb.position.y, 2.42), "Shutter98_B_Outer")
	# Hamlet windows + shutters: the S94 restyle left
	# these houses windowless. New window boxes at
	# local (+/-2.0, 2.4, -3.06) on the -z face
	# (door span -0.5..0.5, so +/-2.0 is clear) +
	# shutters 0.35 wide at offset 0.525.
	var glass_m := _mat(Color(0.15, 0.25, 0.35, 1.0), 0.2, 0.1)
	for idx in [0, 1]:
		var grp := _find_rec(world, "HamletHouse75_%d" % idx) as Node3D
		if grp == null:
			continue
		for sx in [-1.0, 1.0]:
			var wx: float = sx * 2.0
			_box(grp, Vector3(0.70, 0.70, 0.10), glass_m, Vector3(wx, 2.40, -3.06), "Window98_%d" % int(sx))
			_box(grp, Vector3(0.35, 0.70, 0.05), shutter_m, Vector3(wx - 0.525, 2.40, -3.07), "Shutter98_%d_L" % int(sx))
			_box(grp, Vector3(0.35, 0.70, 0.05), shutter_m, Vector3(wx + 0.525, 2.40, -3.07), "Shutter98_%d_R" % int(sx))
	# House-side benches + banana clumps, world
	# positions footprint- and road-checked: EF houses
	# at z -16 face +z (rot 0, door on +z face), so
	# z -11 is in front of the house (toward the road
	# at z -6), 1.25 m clear of the footprint edge
	# (z -12.25) and 5 m clear of the road edge.
	# Hamlet houses face -z, so z 71.0 is in front of
	# their z 78 plots (footprint edge 72.6, the spur
	# road x 2094..2106 is far away in z 6..60).
	_bench(world, Vector3(306.5, 0.0, -11.0), "Bench98_EF1")
	_bench(world, Vector3(336.5, 0.0, -11.0), "Bench98_EF2")
	_bench(world, Vector3(2082.5, 0.0, 71.0), "Bench98_Ham0")
	_bench(world, Vector3(2132.5, 0.0, 71.0), "Bench98_Ham1")
	_banana_clump(world, Vector3(293.5, 0.0, -11.0), "Banana98_EF1")
	_banana_clump(world, Vector3(323.5, 0.0, -11.0), "Banana98_EF2")
	_banana_clump(world, Vector3(2067.5, 0.0, 71.0), "Banana98_Ham0")
	_banana_clump(world, Vector3(2117.5, 0.0, 71.0), "Banana98_Ham1")

func _night(world: Node3D) -> void:
	# Instance method (not static) because _lantern
	# stores the gated omnis/heads on this node.
	# Pagoda lanterns: Slice 94 pagodas had NO night
	# lights at all (night97's 10 street omnis + 34
	# window glows cover village/market/school/pagoda
	# (the OLD pagoda)/EF/hamlet/Mindon/depot/route —
	# not these five). One lantern per pagoda at its
	# front-right outside corner, clear of lions,
	# flags, tables, steps and walls. Gated per frame
	# on daylight < 0.15 (night97 pattern). Route
	# lamps at (1000,-14) and (2000,-14): 8 m clear of
	# the route slab edge (z -6) and the stop zones
	# (z -5..5); a hashed tree/field visual overlap
	# is visual-only (no collider) and is stated.
	var g := _find_rec(world, "PagodaGold94") as Node3D
	if g != null:
		_lantern(g, Vector3(5.80, 0.0, 5.80), "Lantern98_Gold", 1.2, 18.0)
	var b := _find_rec(world, "PagodaBrick94") as Node3D
	if b != null:
		_lantern(b, Vector3(4.80, 0.0, 4.80), "Lantern98_Brick", 1.2, 18.0)
	var w := _find_rec(world, "PagodaWhite94") as Node3D
	if w != null:
		_lantern(w, Vector3(5.20, 0.0, 5.20), "Lantern98_White", 1.2, 18.0)
	var f := _find_rec(world, "PagodaForest94") as Node3D
	if f != null:
		_lantern(f, Vector3(3.50, 0.0, 3.50), "Lantern98_Forest", 1.2, 18.0)
	var h := _find_rec(world, "PagodaHill94") as Node3D
	if h != null:
		_lantern(h, Vector3(5.50, 0.0, 5.50), "Lantern98_Hill", 1.2, 18.0)
	_lantern(world, Vector3(1000.0, 0.0, -14.0), "RouteLamp98_A", 1.5, 22.0)
	_lantern(world, Vector3(2000.0, 0.0, -14.0), "RouteLamp98_B", 1.5, 22.0)

static func _extension(world: Node3D) -> void:
	# Slice 96 extension land was mostly empty planes
	# + border pines. Crop-row fields (Slice 96's
	# fields were flat colour boxes with NO rows),
	# two ponds and two footpaths, all on open
	# extension ground, clear of the new tree sites
	# by 20 m or more and clear of roads. Field
	# overlap with a border tree is visual-only
	# (no collider) and is stated.
	var soil_m := _mat(Color(0.45, 0.32, 0.20, 1.0), 0.95)
	var crop_m := _mat(Color(0.25, 0.45, 0.15, 1.0), 0.9)
	var water_m := _mat(Color(0.15, 0.35, 0.55, 1.0), 0.4)
	var path_m := _mat(Color(0.55, 0.48, 0.35, 1.0), 0.95)
	var reed_m := _mat(Color(0.30, 0.50, 0.20, 1.0), 0.9)
	for i in range(6):
		var c: Vector3
		if i == 0:
			c = Vector3(-200.0, 0.0, -300.0)
		elif i == 1:
			c = Vector3(200.0, 0.0, -300.0)
		elif i == 2:
			c = Vector3(2600.0, 0.0, -300.0)
		elif i == 3:
			c = Vector3(-200.0, 0.0, 300.0)
		elif i == 4:
			c = Vector3(200.0, 0.0, 300.0)
		else:
			c = Vector3(2400.0, 0.0, 300.0)
		var g := _holder(world, c, 0.0, "Field98_%d" % i)
		_box(g, Vector3(30.0, 0.08, 20.0), soil_m, Vector3(0.0, 0.04, 0.0), "Field98_%d_Patch" % i)
		for r in range(5):
			_box(g, Vector3(28.0, 0.06, 0.80), crop_m, Vector3(0.0, 0.10, -6.4 + 3.2 * float(r)), "Field98_%d_Row%d" % [i, r])
	for i in range(2):
		var c := Vector3(-500.0, 0.0, -300.0) if i == 0 else Vector3(2400.0, 0.0, 320.0)
		var g := _holder(world, c, 0.0, "Pond98_%d" % i)
		_cyl(g, 6.0, 6.0, 0.10, water_m, Vector3(0.0, 0.05, 0.0), "Pond98_%d_Water" % i)
		for r in range(4):
			var a := float(r) / 4.0 * 6.283185307179586 + 0.3
			_cyl(g, 0.05, 0.05, 1.2, reed_m, Vector3(sin(a) * 5.5, 0.60, cos(a) * 5.5), "Pond98_%d_Reed%d" % [i, r])
	_box(world, Vector3(1000.0, 0.05, 2.50), path_m, Vector3(-100.0, 0.025, -330.0), "Path98_South")
	_box(world, Vector3(1000.0, 0.05, 2.50), path_m, Vector3(100.0, 0.025, 330.0), "Path98_North")

static func _vehicle_pillars(world: Node3D) -> void:
	# Window pillars break the single long glass
	# boxes into framed panes. Bus glass: 0.1 x 0.8 x
	# 7.5 at x +/-1.31, y 2.1, z -3.75..3.75 — pillars
	# at x +/-1.33, y 2.1, z -3.0/-1.5/0/1.5/3.0.
	# Minibus glass: 0.1 x 0.7 x 5.0 at x +/-1.21,
	# y 2.0, z -2.5..2.5 — pillars at x +/-1.23,
	# y 2.0, z -2.0/-1.0/0/1.0/2.0. Children of the
	# vehicle nodes, so they move with the vehicles.
	# Thin bars do not meaningfully block the Slice 91
	# seated-rider view through the glass. No collider
	# changes, no controller changes (Slice 81 limit).
	var frame_m := _mat(Color(0.12, 0.12, 0.12, 1.0), 0.6)
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus != null:
		for sx in [-1.0, 1.0]:
			for pz in [-3.0, -1.5, 0.0, 1.5, 3.0]:
				_box(bus, Vector3(0.08, 0.80, 0.12), frame_m, Vector3(sx * 1.33, 2.10, pz), "Pillar98_%d_%d" % [int(sx), int(pz * 10.0)])
	var mini := world.get_node_or_null("Minibus") as Node3D
	if mini != null:
		for sx in [-1.0, 1.0]:
			for pz in [-2.0, -1.0, 0.0, 1.0, 2.0]:
				_box(mini, Vector3(0.08, 0.70, 0.12), frame_m, Vector3(sx * 1.23, 2.00, pz), "MiniPillar98_%d_%d" % [int(sx), int(pz * 10.0)])
