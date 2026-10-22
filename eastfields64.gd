extends RefCounted
## Slice 64 — East Fields LIVING DISTRICT (depth for the Slice 62
## district, not a new district and not a new system).
## Owner directions 2026-10-23 00:06 + 00:08: the owner wants wide
## roads + small lanes to drive (car, bullock cart, motorcycle)
## while looking at beautiful surroundings and chilling. Slice 62
## built the roads/lanes/houses; Slice 63 put traffic on them.
## This file makes the district feel LIVED-IN and gives it a reason
## to visit: quest marker posts, farm fields, fences, scenery carts
## (NOT rideable — plain meshes, no vehicle script, no enter
## prompt, named SceneryCart64 so they can never be confused with
## the rideable bullock cart), scenery farm animals, and more
## trees/flowers along the lanes. All runtime-only: main.tscn is
## NOT touched, no existing position moves, no opponent map, names,
## structure or code is used (coordinates are Muse Slice 62
## district coordinates, extended along the same roads/lanes).
## Idempotent: if EastFields64 already exists, dress() returns.
## Deferred add: player._ready runs while Main is still setting up
## children, so a direct add_child fails ("parent busy") — the
## same reason Slice 56/59/62 dressing defers its group adds.
## Content is built onto the group before the add, so nothing pops.
## Season note: tree canopy meshes are named Canopy64_* (the
## Slice 62 controller tints any mesh whose name contains
## "Canopy", and captures at frame 5+, after this deferred add
## lands — so Slice 64 trees change colour with the seasons for
## free). Flower groups are named Flower64_* and canopy sway +
## flower sway + animal head-bob live in eastfields_anim64.gd
## (the controller only sways Chill62_* names, so nothing sways
## twice).

const Anim64Script = preload("res://eastfields_anim64.gd")

static func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

static func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, nm: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = h
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node3D, nm: String, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _tree(parent: Node3D, idx: int, x: float, z: float, canopy_mat: Material, trunk_mat: Material) -> void:
	var g := Node3D.new()
	g.name = "Tree64_%d" % idx
	g.position = Vector3(x, 0.0, z)
	parent.add_child(g)
	_cyl(g, "Trunk64", 0.22, 0.3, 2.6, Vector3(0.0, 1.3, 0.0), trunk_mat)
	_sphere(g, "Canopy64_%d" % idx, 1.7, Vector3(0.0, 3.4, 0.0), canopy_mat)
	_sphere(g, "Canopy64Top_%d" % idx, 1.1, Vector3(0.5, 4.4, 0.0), canopy_mat)

static func _marker(parent: Node3D, qid: String, x: float, z: float, top_mat: Material, pole_mat: Material) -> void:
	# Quest marker post: tall pole + coloured top sphere, NO
	# collider (players walk up to it; a collider would block the
	# 9 m arrival radius). The minimap dot mirrors this node.
	var g := Node3D.new()
	g.name = "Marker64_" + qid
	g.position = Vector3(x, 0.0, z)
	parent.add_child(g)
	_cyl(g, "Pole64", 0.12, 0.14, 3.2, Vector3(0.0, 1.6, 0.0), pole_mat)
	_sphere(g, "Top64", 0.45, Vector3(0.0, 3.4, 0.0), top_mat)

static func _cow(parent: Node3D, idx: int, x: float, z: float, rot_y: float, body_mat: Material, head_mat: Material, dark_mat: Material) -> void:
	# Scenery cow: body + head group named Head64 (bobbed by the
	# anim script) + 4 legs. No script, no collider, no rideable
	# behaviour — it is farm scenery, not a vehicle.
	var g := Node3D.new()
	g.name = "Cow64_%d" % idx
	g.position = Vector3(x, 0.0, z)
	g.rotation.y = rot_y
	parent.add_child(g)
	_box(g, "Body64", Vector3(1.1, 1.0, 2.2), Vector3(0.0, 1.05, 0.0), body_mat)
	_box(g, "Patch64", Vector3(1.12, 0.5, 1.0), Vector3(0.0, 1.2, 0.3), dark_mat)
	var head := Node3D.new()
	head.name = "Head64"
	head.position = Vector3(0.0, 1.45, 1.25)
	g.add_child(head)
	_box(head, "HeadBox64", Vector3(0.55, 0.55, 0.6), Vector3(0.0, 0.0, 0.0), head_mat)
	for lx in [-0.4, 0.4]:
		for lz in [-0.8, 0.8]:
			_box(g, "Leg64_%d_%d" % [int((lx + 0.4) * 10.0), int((lz + 0.8) * 10.0)], Vector3(0.18, 0.6, 0.18), Vector3(lx, 0.3, lz), dark_mat)

static func _chicken(parent: Node3D, idx: int, x: float, z: float, body_mat: Material, comb_mat: Material) -> void:
	var g := Node3D.new()
	g.name = "Chicken64_%d" % idx
	g.position = Vector3(x, 0.0, z)
	parent.add_child(g)
	_sphere(g, "Body64", 0.28, Vector3(0.0, 0.32, 0.0), body_mat)
	var head := Node3D.new()
	head.name = "Head64"
	head.position = Vector3(0.0, 0.6, 0.22)
	g.add_child(head)
	_sphere(head, "HeadBox64", 0.14, Vector3(0.0, 0.0, 0.0), body_mat)
	_box(head, "Comb64", Vector3(0.08, 0.12, 0.1), Vector3(0.0, 0.15, 0.0), comb_mat)

static func _scenery_cart(parent: Node3D, idx: int, x: float, z: float, rot_y: float, wood_mat: Material, wheel_mat: Material) -> void:
	# Scenery cart: parked farm cart, plain meshes only. It has NO
	# vehicle script, NO enter prompt, NO collider — it can never
	# be driven and never blocks the road. Named SceneryCart64.
	var g := Node3D.new()
	g.name = "SceneryCart64_%d" % idx
	g.position = Vector3(x, 0.0, z)
	g.rotation.y = rot_y
	parent.add_child(g)
	_box(g, "Bed64", Vector3(2.0, 0.25, 4.0), Vector3(0.0, 0.9, 0.0), wood_mat)
	_box(g, "Side64A", Vector3(0.15, 0.6, 4.0), Vector3(-1.0, 1.25, 0.0), wood_mat)
	_box(g, "Side64B", Vector3(0.15, 0.6, 4.0), Vector3(1.0, 1.25, 0.0), wood_mat)
	for wi in range(2):
		var wx := -1.05 if wi == 0 else 1.05
		# Cylinder axis is Y by default; rotate so the wheel faces sideways.
		var wheel := _cyl(g, "Wheel64_%d" % wi, 0.55, 0.55, 0.15, Vector3(wx, 0.55, 0.0), wheel_mat)
		wheel.rotation.z = PI * 0.5

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("EastFields64") != null:
		return
	var wood := _mat(Color(0.45, 0.3, 0.16, 1.0), 0.9)
	var trunk_m := _mat(Color(0.35, 0.22, 0.12, 1.0), 1.0)
	var pole_m := _mat(Color(0.4, 0.4, 0.42, 1.0), 0.6)
	var canopy_a := _mat(Color(0.1, 0.42, 0.16, 1.0), 1.0)
	var canopy_b := _mat(Color(0.16, 0.5, 0.2, 1.0), 1.0)
	var crop_m := _mat(Color(0.2, 0.55, 0.2, 1.0), 1.0)
	var paddy_m := _mat(Color(0.3, 0.6, 0.35, 1.0), 0.6)
	var cow_m := _mat(Color(0.85, 0.82, 0.78, 1.0), 0.9)
	var cow_dark := _mat(Color(0.25, 0.2, 0.18, 1.0), 0.9)
	var chicken_m := _mat(Color(0.9, 0.85, 0.7, 1.0), 0.9)
	var comb_m := _mat(Color(0.85, 0.15, 0.15, 1.0), 0.8)
	var flower_mats: Array = [_mat(Color(0.95, 0.4, 0.6, 1.0), 0.8), _mat(Color(0.95, 0.85, 0.2, 1.0), 0.8), _mat(Color(0.95, 0.95, 0.95, 1.0), 0.8)]
	var marker_mats: Array = [_mat(Color(1.0, 0.8, 0.2, 1.0), 0.5), _mat(Color(0.2, 0.8, 0.4, 1.0), 0.5), _mat(Color(0.3, 0.6, 1.0, 1.0), 0.5), _mat(Color(1.0, 0.4, 0.4, 1.0), 0.5)]

	var grp := Node3D.new()
	grp.name = "EastFields64"
	world.call_deferred("add_child", grp)

	# Quest marker posts (same coords as EASTFIELDS64_QUESTS).
	var quests: Array = [
		["east_road", 440.0, 8.5, marker_mats[0]],
		["north_lane", 346.0, -95.0, marker_mats[1]],
		["south_lane", 384.0, 75.0, marker_mats[2]],
		["pond", 307.0, -60.0, marker_mats[3]],
	]
	for q in quests:
		_marker(grp, str(q[0]), float(q[1]), float(q[2]), q[3], pole_m)

	# Farm fields: crop strips east of the north lane (clear of
	# the x 347..353 stream — strips start at x 356) and west of
	# the south lane, plus two paddy patches by Pond62A.
	for i in range(4):
		_box(grp, "CropRow64_%d" % i, Vector3(12.0, 0.18, 0.9), Vector3(362.0, 0.09, -24.0 - i * 8.0), crop_m)
	for i in range(6):
		_box(grp, "CropRow64_%d" % (4 + i), Vector3(10.0, 0.18, 0.9), Vector3(375.0, 0.09, 16.0 + i * 10.0), crop_m)
	_box(grp, "Paddy64_0", Vector3(8.0, 0.12, 12.0), Vector3(288.0, 0.06, -60.0), paddy_m)
	_box(grp, "Paddy64_1", Vector3(8.0, 0.12, 10.0), Vector3(288.0, 0.06, -76.0), paddy_m)
	# Crop tufts on the strips (small green domes).
	var tuft_spots: Array = []
	for i in range(4):
		for tx in [358.0, 362.0, 366.0]:
			tuft_spots.append([tx, -24.0 - i * 8.0])
	for i in range(6):
		for tx in [372.0, 376.0, 380.0]:
			tuft_spots.append([tx, 16.0 + i * 10.0])
	var ti := 0
	for t in tuft_spots:
		_sphere(grp, "Tuft64_%d" % ti, 0.28, Vector3(float(t[0]), 0.3, float(t[1])), crop_m)
		ti += 1

	# Fences along the main road edges (posts every 8 m, rails as
	# long segments split at the two lane junctions x 340 / 390
	# so no fence crosses a lane; north edge z -8.5 stays clear
	# of the z -10 road trees by 1.5 m and of the z -7 lamps).
	var fence_i := 0
	for side_z in [-8.5, 8.5]:
		var segs: Array = [[255.0, 336.0], [344.0, 386.0], [394.0, 445.0]]
		for sg in segs:
			var x0 := float(sg[0])
			var x1 := float(sg[1])
			var px := x0
			while px <= x1:
				_cyl(grp, "FencePost64_%d" % fence_i, 0.09, 0.11, 1.1, Vector3(px, 0.55, side_z), wood)
				fence_i += 1
				px += 8.0
			_box(grp, "FenceRail64_%d" % fence_i, Vector3(x1 - x0, 0.08, 0.08), Vector3((x0 + x1) * 0.5, 0.85, side_z), wood)
			fence_i += 1
			_box(grp, "FenceRail64_%d" % fence_i, Vector3(x1 - x0, 0.08, 0.08), Vector3((x0 + x1) * 0.5, 0.5, side_z), wood)
			fence_i += 1

	# Scenery carts (parked, never driveable).
	_scenery_cart(grp, 0, 356.0, -12.0, 0.3, wood, trunk_m)
	_scenery_cart(grp, 1, 384.0, 12.0, PI * 0.5, wood, trunk_m)

	# Scenery farm animals (idle bob via the anim node).
	_cow(grp, 0, 374.0, 22.0, 0.4, cow_m, cow_m, cow_dark)
	_cow(grp, 1, 376.0, 44.0, -0.5, cow_m, cow_m, cow_dark)
	_cow(grp, 2, 372.0, 58.0, 0.9, cow_m, cow_m, cow_dark)
	_chicken(grp, 0, 358.0, -28.0, chicken_m, comb_m)
	_chicken(grp, 1, 360.0, -36.0, chicken_m, comb_m)
	_chicken(grp, 2, 357.0, -44.0, chicken_m, comb_m)
	_chicken(grp, 3, 362.0, -52.0, chicken_m, comb_m)

	# Lane + road trees (clear of Slice 62 houses, lanes, stream,
	# ponds and existing trees — see header clearance notes).
	var tree_spots: Array = [
		[348.0, -20.0], [348.0, -40.0], [348.0, -80.0],
		[384.0, 12.0], [384.0, 35.0], [384.0, 55.0],
		[275.0, -10.0], [335.0, -10.0], [395.0, -10.0], [435.0, -10.0],
		[295.0, 10.0], [355.0, 10.0], [415.0, 10.0],
	]
	var tri := 0
	for t in tree_spots:
		_tree(grp, tri, float(t[0]), float(t[1]), canopy_a if tri % 2 == 0 else canopy_b, trunk_m)
		tri += 1

	# Lane flowers (groups swayed by the anim node).
	var fi := 0
	for fz in [-10.0, -20.0, -30.0, -40.0, -50.0, -60.0, -70.0, -80.0, -90.0]:
		var fg := Node3D.new()
		fg.name = "Flower64_%d" % fi
		fg.position = Vector3(346.0, 0.0, fz)
		grp.add_child(fg)
		_cyl(fg, "Stem64", 0.03, 0.03, 0.4, Vector3(0.0, 0.2, 0.0), crop_m)
		_sphere(fg, "Head64", 0.13, Vector3(0.0, 0.45, 0.0), flower_mats[fi % 3])
		fi += 1
	for fz in [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0]:
		var fg := Node3D.new()
		fg.name = "Flower64_%d" % fi
		fg.position = Vector3(386.0, 0.0, fz)
		grp.add_child(fg)
		_cyl(fg, "Stem64", 0.03, 0.03, 0.4, Vector3(0.0, 0.2, 0.0), crop_m)
		_sphere(fg, "Head64", 0.13, Vector3(0.0, 0.45, 0.0), flower_mats[fi % 3])
		fi += 1

	# Anim node: sways Canopy64 meshes + Flower64 groups, bobs
	# Head64 animal heads. Runs on the group so it sees all of
	# the above once the deferred add lands.
	var anim := Node3D.new()
	anim.name = "EastFieldsAnim64"
	anim.set_script(load("res://eastfields_anim64.gd"))
	grp.add_child(anim)

	# Minimap dots for the four quest markers (same MapTransform
	# mapping the Slice 62 district roads use; created here so
	# they exist before player._update_minimap builds its dot
	# list on the first frame).
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer != null:
		var panel := layer.get_node_or_null("MinimapPanel") as Control
		if panel != null:
			var dot_colors: Array = [Color(1.0, 0.8, 0.2, 1.0), Color(0.2, 0.8, 0.4, 1.0), Color(0.3, 0.6, 1.0, 1.0), Color(1.0, 0.4, 0.4, 1.0)]
			for di in range(4):
				var dname := "EastDot64_%d" % di
				if panel.get_node_or_null(dname) != null:
					continue
				var dot := ColorRect.new()
				dot.name = dname
				dot.color = dot_colors[di]
				dot.size = Vector2(8.0, 8.0)
				panel.add_child(dot)
