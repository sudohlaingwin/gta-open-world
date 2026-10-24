extends Node3D

## Slice 109 — CORE-MODEL REBUILD (owner re-point 2026-10-24
## 11:14 +07, supersedes the post-S108 pause: the owner sent 2
## vivo V60 screenshots proving the CORE MODELS still look
## terrible — flat dark menu, bus = yellow box, person = white
## blob, palms = sticks + flat blades, ground = flat green —
## despite the S104-S108 dressing backlog being finished).
## This slice rebuilds CORE SHAPES, not dressing. No new
## clotheslines/bins/reeds/signs/firewood (all done S104-S108).
## Runtime hide-and-replace ONLY (S95 car precedent): original
## body boxes hidden, new geometry in the SAME footprint,
## collider/tuning/controller/door/seats/sign/lamp untouched.
## Bus paint is LIVE (S35/S81): new body parts SHARE the
## original body's material instance, so a paint press recolors
## the new body too — proven in SIM110 by shared-instance id.
## No .tscn edits, no bus-system changes, minibus NOT rewired,
## big bus NOT rewired (Slice 81 limit), touch controls
## untouched, zero NEW colliders, StandardMaterial3D only,
## no dead specular lines, no fog/SSAO/glow claims (no
## WorldEnvironment exists), no photorealism claims:
## stylised smooth procedural work. Runs at frame >= 380,
## after realism109's 360 pass.

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism110") != null:
		return
	var n := Node3D.new()
	n.name = "Realism110"
	n.set_script(load("res://realism110.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 380:
		_done = true
		_apply(get_parent() as Node3D)

static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node, r: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _glass() -> StandardMaterial3D:
	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.1, 0.2, 0.3, 0.45)
	g.roughness = 0.1
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return g

static func _hide(node: Node, nm: String) -> void:
	var mi := node.get_node_or_null(nm) as MeshInstance3D
	if mi != null:
		mi.visible = false

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_bus(world)
	_minibus(world)
	_people(world)
	_palms(world)
	_ground(world)

# BIG BUS — same footprint (x +-1.35, y <= 3.0, z +-4.6),
# forward = local -z. Original slab boxes hidden; new stepped
# body: inset tub (stripe/pillars proud), split side glass
# leaving the +x door bay (z 0.4..1.6) open, raked-free flat
# glass + header rails, stepped nose + grille. Heads/tails/
# plates/bumpers/mirrors/AC pod/vents/exhaust/pillars98/
# arches105/stripes105/seats/sign/lamp/door ALL kept.
func _bus(world: Node3D) -> void:
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus == null:
		return
	var body_mi := bus.get_node_or_null("BusBody74") as MeshInstance3D
	if body_mi == null:
		return
	var body_mat := body_mi.get_surface_override_material(0)
	if body_mat == null:
		body_mat = _mat(Color(0.9, 0.75, 0.15, 1.0), 0.5)
	for nm in ["BusBody74", "BusSkirt74", "BusRoof74", "BusWinL74", "BusWinR74", "BusShield74", "BusRear74"]:
		_hide(bus, nm)
	var glass := _glass()
	var dark := _mat(Color(0.15, 0.15, 0.2, 1.0), 0.6)
	# Lower tub, inset so S104 stripe (x +-1.32) + S97 pillars
	# (x +-1.33) read proud of the side.
	_box(bus, Vector3(2.56, 0.9, 8.7), body_mat, Vector3(0.0, 1.05, 0.0), "Tub110")
	# Sill strips under the windows.
	_box(bus, Vector3(0.06, 0.2, 8.7), body_mat, Vector3(-1.28, 1.6, 0.0), "Sill110_L")
	_box(bus, Vector3(0.06, 0.2, 4.7), body_mat, Vector3(1.28, 1.6, -2.0), "Sill110_R_F")
	_box(bus, Vector3(0.06, 0.2, 2.7), body_mat, Vector3(1.28, 1.6, 3.0), "Sill110_R_R")
	# Side glass, semi-transparent so S91 seated riders stay
	# visible; +x side split around the door bay.
	_box(bus, Vector3(0.06, 0.7, 8.7), glass, Vector3(-1.30, 2.05, 0.0), "Glass110_L")
	_box(bus, Vector3(0.06, 0.7, 4.7), glass, Vector3(1.30, 2.05, -2.0), "Glass110_R_F")
	_box(bus, Vector3(0.06, 0.7, 2.7), glass, Vector3(1.30, 2.05, 3.0), "Glass110_R_R")
	# Header rails close the side up to the roof.
	_box(bus, Vector3(0.06, 0.45, 8.7), body_mat, Vector3(-1.30, 2.625, 0.0), "Header110_L")
	_box(bus, Vector3(0.06, 0.45, 4.7), body_mat, Vector3(1.30, 2.625, -2.0), "Header110_R_F")
	_box(bus, Vector3(0.06, 0.45, 2.7), body_mat, Vector3(1.30, 2.625, 3.0), "Header110_R_R")
	# Roof, same footprint as the old roof (AC pod + vents ride on).
	_box(bus, Vector3(2.7, 0.15, 9.0), body_mat, Vector3(0.0, 2.925, 0.0), "Roof110")
	# Front: stepped nose proud of the tub ends (tub ends +-4.35).
	_box(bus, Vector3(2.56, 1.1, 0.15), body_mat, Vector3(0.0, 1.05, -4.405), "FrontPanel110")
	_box(bus, Vector3(2.56, 0.1, 0.15), body_mat, Vector3(0.0, 1.65, -4.405), "FrontBrow110")
	_box(bus, Vector3(2.2, 0.7, 0.1), glass, Vector3(0.0, 2.05, -4.43), "FrontGlass110")
	_box(bus, Vector3(2.56, 0.45, 0.15), body_mat, Vector3(0.0, 2.625, -4.405), "FrontHeader110")
	_box(bus, Vector3(1.2, 0.35, 0.06), dark, Vector3(0.0, 1.25, -4.51), "Grille110")
	# Rear: same step, no grille (tails + plate already there).
	_box(bus, Vector3(2.56, 1.1, 0.15), body_mat, Vector3(0.0, 1.05, 4.405), "RearPanel110")
	_box(bus, Vector3(2.56, 0.1, 0.15), body_mat, Vector3(0.0, 1.65, 4.405), "RearBrow110")
	_box(bus, Vector3(2.2, 0.7, 0.1), glass, Vector3(0.0, 2.05, 4.43), "RearGlass110")
	_box(bus, Vector3(2.56, 0.45, 0.15), body_mat, Vector3(0.0, 2.625, 4.405), "RearHeader110")

# MINIBUS — same pattern, own footprint (x +-1.25, y <= 2.79,
# z +-3.1). Door bay on +x is z 0.0..1.0. MiniDestBoard81 /
# MiniSign81 kept; front glass top (2.35) clears the board
# bottom (2.275) in z (glass face -2.98 vs board -3.04).
func _minibus(world: Node3D) -> void:
	var bus := world.get_node_or_null("Minibus") as Node3D
	if bus == null:
		return
	var body_mi := bus.get_node_or_null("MiniBody81") as MeshInstance3D
	if body_mi == null:
		return
	var body_mat := body_mi.get_surface_override_material(0)
	if body_mat == null:
		body_mat = _mat(Color(0.9, 0.75, 0.15, 1.0), 0.5)
	for nm in ["MiniBody81", "MiniSkirt81", "MiniRoof81", "MiniWinL81", "MiniWinR81", "MiniShield81", "MiniRear81"]:
		_hide(bus, nm)
	var glass := _glass()
	var dark := _mat(Color(0.15, 0.15, 0.2, 1.0), 0.6)
	_box(bus, Vector3(2.36, 0.8, 5.7), body_mat, Vector3(0.0, 1.0, 0.0), "MiniTub110")
	_box(bus, Vector3(0.06, 0.3, 5.7), body_mat, Vector3(-1.18, 1.55, 0.0), "MiniSill110_L")
	_box(bus, Vector3(0.06, 0.3, 2.8), body_mat, Vector3(1.18, 1.55, -1.45), "MiniSill110_R_F")
	_box(bus, Vector3(0.06, 0.3, 1.8), body_mat, Vector3(1.18, 1.55, 1.95), "MiniSill110_R_R")
	_box(bus, Vector3(0.06, 0.7, 5.7), glass, Vector3(-1.20, 2.0, 0.0), "MiniGlass110_L")
	_box(bus, Vector3(0.06, 0.7, 2.8), glass, Vector3(1.20, 2.0, -1.45), "MiniGlass110_R_F")
	_box(bus, Vector3(0.06, 0.7, 1.8), glass, Vector3(1.20, 2.0, 1.95), "MiniGlass110_R_R")
	_box(bus, Vector3(0.06, 0.35, 5.7), body_mat, Vector3(-1.20, 2.525, 0.0), "MiniHeader110_L")
	_box(bus, Vector3(0.06, 0.35, 2.8), body_mat, Vector3(1.20, 2.525, -1.45), "MiniHeader110_R_F")
	_box(bus, Vector3(0.06, 0.35, 1.8), body_mat, Vector3(1.20, 2.525, 1.95), "MiniHeader110_R_R")
	_box(bus, Vector3(2.5, 0.18, 6.2), body_mat, Vector3(0.0, 2.7, 0.0), "MiniRoof110")
	_box(bus, Vector3(2.36, 0.9, 0.15), body_mat, Vector3(0.0, 1.05, -2.905), "MiniFrontPanel110")
	_box(bus, Vector3(2.36, 0.15, 0.15), body_mat, Vector3(0.0, 1.575, -2.905), "MiniFrontBrow110")
	_box(bus, Vector3(2.0, 0.7, 0.1), glass, Vector3(0.0, 2.0, -2.93), "MiniFrontGlass110")
	_box(bus, Vector3(2.36, 0.35, 0.15), body_mat, Vector3(0.0, 2.525, -2.905), "MiniFrontHeader110")
	_box(bus, Vector3(1.0, 0.3, 0.06), dark, Vector3(0.0, 1.2, -3.01), "MiniGrille110")
	_box(bus, Vector3(2.36, 0.9, 0.15), body_mat, Vector3(0.0, 1.05, 2.905), "MiniRearPanel110")
	_box(bus, Vector3(2.36, 0.15, 0.15), body_mat, Vector3(0.0, 1.575, 2.905), "MiniRearBrow110")
	_box(bus, Vector3(2.0, 0.7, 0.1), glass, Vector3(0.0, 2.0, 2.93), "MiniRearGlass110")
	_box(bus, Vector3(2.36, 0.35, 0.15), body_mat, Vector3(0.0, 2.525, 2.905), "MiniRearHeader110")

# PEOPLE — arm separation at distance. Audit fact: hands hang
# at pivot x +-0.27 while the flared longyi reaches r 0.32, so
# hands sit INSIDE the longyi silhouette — the screenshot
# "white blob". Outward pivot angle 0.18 rad moves hands out
# sin(0.18)*0.75 = 0.134 m to x +-0.404, clear of the longyi
# by ~0.08 m. WalkAnim58 / idle set rotation.x ONLY, so the
# z angle persists through walk + idle. Positions, rotations
# (x/y), walk animation, outfits all untouched. Head NOT
# scaled: S94 face features sit at fixed body-space positions,
# growing the head would sink them.
func _people(world: Node3D) -> void:
	for child in world.get_children():
		if String(child.name) != "Player" and not String(child.name).begins_with("Villager"):
			continue
		var b := child as Node3D
		if b == null:
			continue
		for side in ["L", "R"]:
			var piv := b.get_node_or_null("ShoulderPivot58_" + side) as Node3D
			if piv == null:
				continue
			var sgn := -1.0 if side == "L" else 1.0
			piv.rotation = Vector3(piv.rotation.x, piv.rotation.y, sgn * 0.18)

# PALMS — village palms are the screenshot's "sticks + flat
# blades": Palm18A/B carry only 4 fronds each, Palm20 groups 6.
# Sheet palms already carry 8 fronds + nuts (S97/S98) and are
# NOT touched. Border pines got trunks + tiers in S106 and
# are NOT redone. Second drooping ring per village palm group
# (offset half-step so blades interleave) + nut cluster ONLY
# where the group has no nut/coconut child already.
func _palms(world: Node3D) -> void:
	var leaf := _mat(Color(0.18, 0.45, 0.20, 1.0), 0.9)
	var nut_m := _mat(Color(0.35, 0.25, 0.15, 1.0), 0.9)
	for gname in ["Palm18A", "Palm18B"]:
		var grp := world.get_node_or_null(gname) as Node3D
		if grp == null:
			continue
		for ai in 4:
			var a := 0.7853981633974483 + float(ai) * 1.5707963267948966
			_box(grp, Vector3(0.22, 0.05, 2.1), leaf, Vector3(sin(a) * 0.9, 5.55, cos(a) * 0.9), "Frond110_%d" % ai, Vector3(0.85, a, 0.0))
		if not _has_nut(grp):
			for ai in 3:
				var a := float(ai) * 2.0943951023931953
				_sphere(grp, 0.15, nut_m, Vector3(sin(a) * 0.35, 5.5, cos(a) * 0.35), "Nut110_%d" % ai)
	var stack: Array = [world]
	while stack.size() > 0:
		var nn: Node = stack.pop_back()
		if nn is MeshInstance3D and String(nn.name).begins_with("Palm20") and (nn as MeshInstance3D).mesh is CylinderMesh:
			var pm := nn as MeshInstance3D
			for ai in 6:
				var a := 0.5235987755982988 + float(ai) * 1.0471975511965976
				_box(pm, Vector3(0.22, 0.05, 2.1), leaf, Vector3(sin(a) * 0.8, 4.7, cos(a) * 0.8), "Frond110B_%d" % ai, Vector3(0.85, a, 0.0))
			if not _has_nut(pm):
				for ai in 3:
					var a := float(ai) * 2.0943951023931953
					_sphere(pm, 0.15, nut_m, Vector3(sin(a) * 0.3, 4.6, cos(a) * 0.3), "Nut110B_%d" % ai)
		for c in nn.get_children():
			stack.append(c)

static func _has_nut(n: Node) -> bool:
	for c in n.get_children():
		var nm := String(c.name)
		if nm.contains("Nut") or nm.contains("Coconut"):
			return true
	return false

# GROUND — break the flat-green sheet near play areas. Tufts
# flank the EF road + long-route verges (2.5 m clear of the
# 12 m slabs); dirt patches + tone slabs sit on the village
# green. Visual only, y 0.02..0.05, zero colliders, no terrain
# height change, roads untouched.
func _ground(world: Node3D) -> void:
	var leaf_a := _mat(Color(0.20, 0.48, 0.18, 1.0), 0.9)
	var leaf_b := _mat(Color(0.26, 0.55, 0.22, 1.0), 0.9)
	var tufts: Array = [
		[265.0, -8.5], [295.0, 8.5], [325.0, -8.5], [355.0, 8.5],
		[385.0, -8.5], [415.0, 8.5], [600.0, 8.5], [700.0, -8.5],
		[900.0, 8.5], [1200.0, -8.5], [1600.0, 8.5], [2000.0, -8.5],
	]
	for ti in range(tufts.size()):
		var tx := float(tufts[ti][0])
		var tz := float(tufts[ti][1])
		var hold := Node3D.new()
		hold.name = "Tuft110_%d" % ti
		hold.position = Vector3(tx, 0.0, tz)
		world.add_child(hold)
		for bi in 3:
			var m := leaf_a if bi % 2 == 0 else leaf_b
			_box(hold, Vector3(0.08, 0.45 + 0.1 * float(bi), 0.03), m, Vector3(-0.12 + 0.12 * float(bi), 0.25, 0.0), "Blade110_%d" % bi, Vector3(0.12 * float(bi - 1), 0.0, 0.0))
	var dirt := _mat(Color(0.45, 0.32, 0.20, 1.0), 1.0)
	var patches: Array = [
		[-20.0, 10.0], [5.0, 14.0], [50.0, -10.0],
		[-45.0, -20.0], [-10.0, 24.0], [55.0, 10.0],
	]
	for pi in range(patches.size()):
		_box(world, Vector3(3.0, 0.04, 2.0), dirt, Vector3(float(patches[pi][0]), 0.03, float(patches[pi][1])), "Dirt110_%d" % pi)
	var tone_a := _mat(Color(0.20, 0.42, 0.16, 1.0), 1.0)
	var tone_b := _mat(Color(0.32, 0.55, 0.22, 1.0), 1.0)
	var slabs: Array = [[-20.0, 0.0], [0.0, -10.0], [40.0, 0.0], [0.0, 20.0]]
	for si in range(slabs.size()):
		var m := tone_a if si % 2 == 0 else tone_b
		_box(world, Vector3(6.0, 0.02, 4.0), m, Vector3(float(slabs[si][0]), 0.02, float(slabs[si][1])), "Tone110_%d" % si)
