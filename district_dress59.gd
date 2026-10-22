## Slice 59: Mindon district + village outskirts + vehicle dressing.
## ORIGINAL procedural/code-generated models only, no external assets,
## nothing copied. Runtime-only: no scene file is touched, no new
## physics bodies (streetlight poles, trees, facade boxes and vehicle
## trim are visual-only, same precedent as Slice 53/56/57/58 dressing;
## the Slice 38 rule is kept because no existing collider moves and
## no walkable building gains a new solid it did not already have).
## Runs once at world spawn from player._ready, after Slice 58.
## Loaded by preload, NOT class_name (a new class_name needs a
## regenerated .godot global-class cache, and a stale cache breaks
## player.gd's parse — proven Slice 53).
## Direct adds go to existing sub-nodes (buildings, vehicles); the
## streetlight/outskirts group is added via call_deferred, because a
## world-root add_child from player._ready fails ("Parent node is
## busy setting up children") — proven Slice 56/57.
## Night gating uses district_night59.gd on the shared daylight
## < 0.15 rule. Honest limits: facade windows are boxes proud of
## the walls (not cut openings); streetlight glow is emissive boxes
## + 4 real OmniLights, not a lighting bake; new trees have no
## colliders, so they are walk-through dressing; how it looks on a
## phone is the owner's V60 verdict, not a headless claim.

const Night59Script = preload("res://district_night59.gd")

static var _win_mesh: BoxMesh = null
static var _door_mesh: BoxMesh = null
static var _win_mat: StandardMaterial3D = null
static var _door_mat: StandardMaterial3D = null
static var _pole_mat: StandardMaterial3D = null
static var _lamp_mat: StandardMaterial3D = null
static var _glow_mat: StandardMaterial3D = null
static var _trunk_mat: StandardMaterial3D = null
static var _leaf_mat: StandardMaterial3D = null
static var _leaf2_mat: StandardMaterial3D = null
static var _dirt_mat: StandardMaterial3D = null
static var _glass_mat: StandardMaterial3D = null
static var _chrome_mat: StandardMaterial3D = null
static var _dark_mat: StandardMaterial3D = null

static func _shared() -> void:
	if _win_mesh != null:
		return
	_win_mesh = BoxMesh.new()
	_win_mesh.size = Vector3(0.55, 0.7, 0.06)
	_door_mesh = BoxMesh.new()
	_door_mesh.size = Vector3(0.8, 1.4, 0.08)
	_win_mat = StandardMaterial3D.new()
	_win_mat.albedo_color = Color(0.15, 0.22, 0.30, 1.0)
	_win_mat.roughness = 0.25
	_win_mat.metallic = 0.1
	_win_mat.emission_enabled = true
	_win_mat.emission = Color(1.0, 0.75, 0.35, 1.0)
	_win_mat.emission_energy_multiplier = 0.0
	_door_mat = StandardMaterial3D.new()
	_door_mat.albedo_color = Color(0.30, 0.20, 0.10, 1.0)
	_door_mat.roughness = 0.9
	_pole_mat = StandardMaterial3D.new()
	_pole_mat.albedo_color = Color(0.20, 0.20, 0.22, 1.0)
	_pole_mat.roughness = 0.6
	_pole_mat.metallic = 0.5
	_lamp_mat = StandardMaterial3D.new()
	_lamp_mat.albedo_color = Color(0.85, 0.85, 0.80, 1.0)
	_lamp_mat.roughness = 0.5
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.albedo_color = Color(1.0, 0.85, 0.45, 1.0)
	_glow_mat.emission_enabled = true
	_glow_mat.emission = Color(1.0, 0.80, 0.35, 1.0)
	_glow_mat.emission_energy_multiplier = 1.2
	_trunk_mat = StandardMaterial3D.new()
	_trunk_mat.albedo_color = Color(0.35, 0.24, 0.15, 1.0)
	_trunk_mat.roughness = 0.95
	_leaf_mat = StandardMaterial3D.new()
	_leaf_mat.albedo_color = Color(0.16, 0.38, 0.16, 1.0)
	_leaf_mat.roughness = 0.9
	_leaf2_mat = StandardMaterial3D.new()
	_leaf2_mat.albedo_color = Color(0.28, 0.48, 0.18, 1.0)
	_leaf2_mat.roughness = 0.9
	_dirt_mat = StandardMaterial3D.new()
	_dirt_mat.albedo_color = Color(0.55, 0.42, 0.28, 1.0)
	_dirt_mat.roughness = 1.0
	_glass_mat = StandardMaterial3D.new()
	_glass_mat.albedo_color = Color(0.10, 0.14, 0.18, 1.0)
	_glass_mat.roughness = 0.1
	_glass_mat.metallic = 0.4
	_chrome_mat = StandardMaterial3D.new()
	_chrome_mat.albedo_color = Color(0.75, 0.75, 0.78, 1.0)
	_chrome_mat.roughness = 0.3
	_chrome_mat.metallic = 0.8
	_dark_mat = StandardMaterial3D.new()
	_dark_mat.albedo_color = Color(0.12, 0.12, 0.12, 1.0)
	_dark_mat.roughness = 0.9

static func _box(parent: Node, name: String, mesh: BoxMesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = name
	m.mesh = mesh
	m.set_surface_override_material(0, mat)
	m.position = pos
	parent.add_child(m)
	return m

static func _facade(world: Node) -> int:
	# Mindon named buildings share the 6 x 2.8 x 5 wall box at
	# local y 1.4 (walls span y 0..2.8). Windows sit proud of the
	# faces at local z +/-2.53 and x +/-3.03; children inherit the
	# building's own scale, so a scaled building gets scaled windows.
	var count := 0
	for bname in ["MindonHospital", "MindonPost", "MindonEdu", "MindonMRTV", "MindonShops", "MindonTemple"]:
		var b := world.get_node_or_null(bname)
		if b == null:
			continue
		for i in 4:
			var x := -2.1 + i * 1.4
			_box(b, "Win59_F_%d" % i, _win_mesh, _win_mat, Vector3(x, 1.7, 2.53))
			_box(b, "Win59_B_%d" % i, _win_mesh, _win_mat, Vector3(x, 1.7, -2.53))
			count += 2
		_box(b, "Door59", _door_mesh, _door_mat, Vector3(0, 0.7, 2.54))
		count += 1
	return count

static func _streetlights(world: Node, night: Node) -> int:
	# 10 poles: 6 along the main Mindon E-W street (z +4.5 side,
	# arms reach toward the road), 3 along the link road (z +3.5),
	# 1 at the Mindon bridge. Glow boxes + OmniLights live under
	# the night node so the controller gates them; poles/arms/lamps
	# live in the deferred group.
	var group := Node3D.new()
	group.name = "DistrictDress59"
	var pole_mesh := BoxMesh.new()
	pole_mesh.size = Vector3(0.18, 3.2, 0.18)
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.12, 0.12, 1.1)
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(0.42, 0.14, 0.26)
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(0.34, 0.06, 0.20)
	var spots: Array = [
		Vector3(105, 0, 4.5), Vector3(125, 0, 4.5), Vector3(145, 0, 4.5),
		Vector3(165, 0, 4.5), Vector3(185, 0, 4.5), Vector3(205, 0, 4.5),
		Vector3(55, 0, 3.5), Vector3(67, 0, 3.5), Vector3(79, 0, 3.5),
		Vector3(92, 0, 4.5),
	]
	var idx := 0
	for s in spots:
		var pole := MeshInstance3D.new()
		pole.name = "StreetPole59_%d" % idx
		pole.mesh = pole_mesh
		pole.set_surface_override_material(0, _pole_mat)
		pole.position = Vector3(s.x, 1.6, s.z)
		group.add_child(pole)
		var arm := MeshInstance3D.new()
		arm.name = "StreetArm59_%d" % idx
		arm.mesh = arm_mesh
		arm.set_surface_override_material(0, _pole_mat)
		arm.position = Vector3(s.x, 3.15, s.z - 0.55)
		group.add_child(arm)
		var lamp := MeshInstance3D.new()
		lamp.name = "StreetLamp59_%d" % idx
		lamp.mesh = lamp_mesh
		lamp.set_surface_override_material(0, _lamp_mat)
		lamp.position = Vector3(s.x, 3.1, s.z - 1.05)
		group.add_child(lamp)
		var glow := MeshInstance3D.new()
		glow.name = "StreetGlow59_%d" % idx
		glow.mesh = glow_mesh
		glow.set_surface_override_material(0, _glow_mat)
		glow.position = Vector3(s.x, 3.02, s.z - 1.05)
		glow.visible = false
		night.add_child(glow)
		idx += 1
	for lx in [125.0, 165.0, 205.0, 67.0]:
		var li := OmniLight3D.new()
		li.name = "StreetLight59_%d" % int(lx)
		li.light_energy = 1.2
		li.omni_range = 14.0
		li.position = Vector3(lx, 3.0, 0.0)
		li.visible = false
		night.add_child(li)
	world.call_deferred("add_child", group)
	return idx

static func _outskirts(world: Node) -> int:
	# 16 visual-only trees (no colliders, Slice 53/58 precedent):
	# 8 flanking the link road (clear of the 5 m road strip),
	# 4 on the village north edge, 4 on the south edge. Plus 16
	# dirt patches under them and 2 dirt path strips.
	var group := Node3D.new()
	group.name = "Outskirts59"
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.22
	trunk_mesh.height = 1.6
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 1.1
	canopy_mesh.height = 2.2
	var patch_mesh := BoxMesh.new()
	patch_mesh.size = Vector3(1.8, 0.05, 1.8)
	var spots: Array = []
	for x in [58.0, 66.0, 74.0, 82.0]:
		spots.append(Vector3(x, 0, 6.5))
		spots.append(Vector3(x, 0, -6.5))
	for x in [-20.0, -5.0, 10.0, 25.0]:
		spots.append(Vector3(x, 0, -30.0))
		spots.append(Vector3(x, 0, 30.0))
	var idx := 0
	for s in spots:
		var trunk := MeshInstance3D.new()
		trunk.name = "OutTree59_Trunk_%d" % idx
		trunk.mesh = trunk_mesh
		trunk.set_surface_override_material(0, _trunk_mat)
		trunk.position = Vector3(s.x, 0.8, s.z)
		group.add_child(trunk)
		var canopy := MeshInstance3D.new()
		canopy.name = "OutTree59_Canopy_%d" % idx
		canopy.mesh = canopy_mesh
		canopy.set_surface_override_material(0, _leaf_mat if idx % 2 == 0 else _leaf2_mat)
		canopy.position = Vector3(s.x, 2.3, s.z)
		group.add_child(canopy)
		var patch := MeshInstance3D.new()
		patch.name = "OutPatch59_%d" % idx
		patch.mesh = patch_mesh
		patch.set_surface_override_material(0, _dirt_mat)
		patch.position = Vector3(s.x, 0.03, s.z)
		group.add_child(patch)
		idx += 1
	var path_mesh := BoxMesh.new()
	path_mesh.size = Vector3(25, 0.06, 2.0)
	var p1 := MeshInstance3D.new()
	p1.name = "OutPath59_East"
	p1.mesh = path_mesh
	p1.set_surface_override_material(0, _dirt_mat)
	p1.position = Vector3(42.5, 0.04, 0.0)
	group.add_child(p1)
	var path2_mesh := BoxMesh.new()
	path2_mesh.size = Vector3(110, 0.06, 1.5)
	var p2 := MeshInstance3D.new()
	p2.name = "OutPath59_Mindon"
	p2.mesh = path2_mesh
	p2.set_surface_override_material(0, _dirt_mat)
	p2.position = Vector3(155, 0.04, -4.5)
	group.add_child(p2)
	world.call_deferred("add_child", group)
	return idx

static func _vehicles(world: Node) -> int:
	# Visual-only trim on the three road vehicles. No wheels are
	# added: Car/Motorcycle/TukTuk wheels already exist at runtime
	# (WheelCar_*, WheelBike_*, TukWheel*) and spin with speed.
	# No colliders are added or moved, so physics is untouched.
	var count := 0
	var car := world.get_node_or_null("Car")
	if car != null:
		var roof := BoxMesh.new()
		roof.size = Vector3(1.7, 0.1, 1.8)
		_box(car, "CarRoof59", roof, _glass_mat, Vector3(0, 0.45, 0.2))
		var mir := BoxMesh.new()
		mir.size = Vector3(0.25, 0.15, 0.1)
		_box(car, "CarMirror59_L", mir, _chrome_mat, Vector3(-1.05, 0.1, 0.3))
		_box(car, "CarMirror59_R", mir, _chrome_mat, Vector3(1.05, 0.1, 0.3))
		var bump := BoxMesh.new()
		bump.size = Vector3(1.9, 0.15, 0.15)
		_box(car, "CarBumper59_F", bump, _dark_mat, Vector3(0, -0.3, -2.0))
		_box(car, "CarBumper59_R", bump, _dark_mat, Vector3(0, -0.3, 2.0))
		var trim := BoxMesh.new()
		trim.size = Vector3(0.05, 0.1, 3.6)
		_box(car, "CarTrim59_L", trim, _chrome_mat, Vector3(-1.01, -0.1, 0))
		_box(car, "CarTrim59_R", trim, _chrome_mat, Vector3(1.01, -0.1, 0))
		count += 7
	var bike := world.get_node_or_null("Motorcycle")
	if bike != null:
		var seat := BoxMesh.new()
		seat.size = Vector3(0.5, 0.15, 0.8)
		_box(bike, "BikeSeat59", seat, _dark_mat, Vector3(0, 0.45, 0.3))
		var bar := BoxMesh.new()
		bar.size = Vector3(0.7, 0.08, 0.08)
		_box(bike, "BikeBar59", bar, _chrome_mat, Vector3(0, 0.55, -0.8))
		var exh := BoxMesh.new()
		exh.size = Vector3(0.12, 0.12, 1.0)
		_box(bike, "BikeExhaust59", exh, _chrome_mat, Vector3(0.35, -0.1, 0.2))
		var bmir := BoxMesh.new()
		bmir.size = Vector3(0.15, 0.1, 0.05)
		_box(bike, "BikeMirror59_L", bmir, _chrome_mat, Vector3(-0.35, 0.6, -0.8))
		_box(bike, "BikeMirror59_R", bmir, _chrome_mat, Vector3(0.35, 0.6, -0.8))
		count += 5
	var tuk := world.get_node_or_null("TukTuk")
	if tuk != null:
		var tmir := BoxMesh.new()
		tmir.size = Vector3(0.2, 0.12, 0.08)
		_box(tuk, "TukMirror59_L", tmir, _chrome_mat, Vector3(-0.85, 0.7, -0.8))
		_box(tuk, "TukMirror59_R", tmir, _chrome_mat, Vector3(0.85, 0.7, -0.8))
		var tbump := BoxMesh.new()
		tbump.size = Vector3(1.5, 0.12, 0.12)
		_box(tuk, "TukBumper59", tbump, _dark_mat, Vector3(0, -0.3, -1.3))
		var ttrim := BoxMesh.new()
		ttrim.size = Vector3(1.5, 0.08, 1.5)
		_box(tuk, "TukTrim59", ttrim, _lamp_mat, Vector3(0, 1.08, 0))
		count += 4
	return count

static func dress(world: Node) -> void:
	_shared()
	var night := Night59Script.new()
	night.name = "DistrictNight59"
	night.win_mat = _win_mat
	world.call_deferred("add_child", night)
	var f := _facade(world)
	var s := _streetlights(world, night)
	var o := _outskirts(world)
	var v := _vehicles(world)
	var marker := Node3D.new()
	marker.name = "DistrictDress59Applied"
	world.call_deferred("add_child", marker)
	print("DISTRICT59 facades=", f, " streetlights=", s, " outskirt_trees=", o, " vehicle_meshes=", v)
