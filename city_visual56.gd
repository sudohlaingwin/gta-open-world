## Slice 56 visual city overhaul: ORIGINAL procedural models only.
## No class_name, by design (same reason as village_dressing.gd:
## a new class_name needs a regenerated .godot global-class cache,
## and a stale cache breaks preload references in a fresh clone).
## player.gd loads this file with preload("res://city_visual56.gd").
## Runs once at world spawn from player._ready, after Slice 53
## village dressing. Everything here is visual-only EXCEPT the new
## city-block colliders, which match their visual footprints exactly
## (Slice 38 solidity rule: a visible building must not be walkable
## through). No scene file is touched, so main.tscn load_steps is
## unchanged. Night gating reuses the existing daylight rule:
## window heads use DayNight's window_material (emission on only
## when daylight < 0.15), streetlight OmniLights and fountains are
## toggled by city_night56.gd on the same rule. This is a big
## stylised-to-realistic step, NOT photorealism and NOT a measured
## FPS claim: how it looks on a phone is the owner's V60 verdict.
## Honest scope: village centre + Mindon district buildings are
## upgraded; the rest of the world keeps its existing dressing.
## No external assets, no copied content: all textures are
## generated in code below (plaster, ripple, grass is Slice 53).

static var _window_mesh: BoxMesh = null
static var _door_mesh: BoxMesh = null
static var _door_mat: StandardMaterial3D = null
static var _trim_mat: StandardMaterial3D = null
static var _water_mat: StandardMaterial3D = null
static var _plaster: Array = []

static func _hash01(s: String) -> float:
	return float(abs(s.hash()) % 1000) / 1000.0

static func _noise2(x: float, y: float) -> float:
	var xi: int = int(floor(x))
	var yi: int = int(floor(y))
	var xf: float = x - floor(x)
	var yf: float = y - floor(y)
	var u: float = xf * xf * (3.0 - 2.0 * xf)
	var v: float = yf * yf * (3.0 - 2.0 * yf)
	var h := func(ix: int, iy: int) -> float:
		var n := (ix * 374761393 + iy * 668265263) & 0x7fffffff
		n = (n ^ (n >> 13)) * 1274126177
		return float((n ^ (n >> 16)) & 0xffffff) / float(0xffffff)
	var a: float = float(h.call(xi, yi))
	var b: float = float(h.call(xi + 1, yi))
	var c: float = float(h.call(xi + 1, yi + 1))
	var d: float = float(h.call(xi, yi + 1))
	return (a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v)

static func _make_plaster(base: Color) -> ImageTexture:
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var n: float = _noise2(x / 24.0, y / 24.0) * 0.7 + _noise2(x / 7.0, y / 7.0) * 0.3
			var col: Color = base.lerp(Color(0.0, 0.0, 0.0, 1.0), (0.5 - n) * 0.35)
			if y % 32 == 0:
				col = col.darkened(0.12)
			if _noise2(x / 3.0 + 40.0, y / 3.0) > 0.82:
				col = col.darkened(0.15)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _make_ripple() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var n: float = _noise2(x / 10.0, y / 10.0) * 0.6 + _noise2(x / 4.0 + 20.0, y / 4.0) * 0.4
			var col: Color = Color(0.55, 0.72, 0.90, 1.0).lerp(Color(0.15, 0.35, 0.60, 1.0), n)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _shared() -> void:
	if _window_mesh != null:
		return
	_window_mesh = BoxMesh.new()
	_window_mesh.size = Vector3(0.55, 0.7, 0.06)
	_door_mesh = BoxMesh.new()
	_door_mesh.size = Vector3(0.8, 1.4, 0.08)
	_door_mat = StandardMaterial3D.new()
	_door_mat.albedo_color = Color(0.30, 0.20, 0.10, 1.0)
	_door_mat.roughness = 0.9
	_trim_mat = StandardMaterial3D.new()
	_trim_mat.albedo_color = Color(0.92, 0.90, 0.85, 1.0)
	_trim_mat.roughness = 0.85
	_water_mat = StandardMaterial3D.new()
	_water_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_water_mat.albedo_texture = _make_ripple()
	_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_water_mat.roughness = 0.08
	_water_mat.metallic = 0.15
	_water_mat.uv1_scale = Vector3(3.0, 3.0, 1.0)
	var bases: Array = [
		Color(0.88, 0.82, 0.68, 1.0),
		Color(0.72, 0.42, 0.36, 1.0),
		Color(0.90, 0.78, 0.48, 1.0),
		Color(0.72, 0.82, 0.88, 1.0),
		Color(0.95, 0.93, 0.88, 1.0),
	]
	for base in bases:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		mat.albedo_texture = _make_plaster(base)
		mat.roughness = 0.95
		_plaster.append(mat)

static func _find_node(world: Node, nm: String) -> Node:
	var stack: Array = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if String(node.name) == nm:
			return node
		for child in node.get_children():
			stack.push_back(child)
	return null

static func _add_box(parent: Node3D, mesh: BoxMesh, mat: Material, pos: Vector3, nm: String) -> void:
	var m := MeshInstance3D.new()
	m.name = nm
	m.mesh = mesh
	m.position = pos
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)

static func _window_grid(wall: MeshInstance3D, win_mat: Material, cols: int, floors: int) -> int:
	var mesh := wall.mesh as BoxMesh
	if mesh == null:
		return 0
	var sx: float = mesh.size.x
	var sy: float = mesh.size.y
	var sz: float = mesh.size.z
	var count := 0
	for side in [-1.0, 1.0]:
		for f in floors:
			var wy: float = -sy * 0.5 + (float(f) + 0.5) * (sy / float(floors))
			for c in cols:
				var wx: float = -sx * 0.5 + (float(c) + 0.5) * (sx / float(cols))
				_add_box(wall, _window_mesh, win_mat, Vector3(wx, wy, side * (sz * 0.5 + 0.04)), "Win56_%d_%d_%d" % [int(side), f, c])
				count += 1
	return count

static func _trim_and_door(wall: MeshInstance3D, win_mat: Material) -> void:
	var mesh := wall.mesh as BoxMesh
	if mesh == null:
		return
	var sx: float = mesh.size.x
	var sy: float = mesh.size.y
	var sz: float = mesh.size.z
	var trim := BoxMesh.new()
	trim.size = Vector3(sx + 0.3, 0.3, sz + 0.3)
	_add_box(wall, trim, _trim_mat, Vector3(0.0, sy * 0.5 + 0.12, 0.0), "Trim56")
	_add_box(wall, _door_mesh, _door_mat, Vector3(0.0, -sy * 0.5 + 0.7, sz * 0.5 + 0.04), "Door56")

static func _dress_wall(mi: MeshInstance3D, win_mat: Material, variant: int, cols: int, floors: int) -> int:
	var mesh := mi.mesh as BoxMesh
	if mesh == null:
		return 0
	var mat: Material = _plaster[variant % _plaster.size()]
	mi.set_surface_override_material(0, mat)
	var n: int = _window_grid(mi, win_mat, cols, floors)
	_trim_and_door(mi, win_mat)
	return n

static func _add_city_block(world: Node3D, win_mat: Material, nm: String, x: float, z: float, w: float, h: float, d: float, variant: int, spire: bool) -> void:
	var group := Node3D.new()
	group.name = nm
	group.position = Vector3(x, 0.0, z)
	world.call_deferred("add_child", group)
	var walls := MeshInstance3D.new()
	walls.name = nm + "Walls"
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, d)
	walls.mesh = bm
	walls.position = Vector3(0.0, h * 0.5, 0.0)
	walls.set_surface_override_material(0, _plaster[variant % _plaster.size()])
	group.add_child(walls)
	var cols: int = maxi(2, int(w / 3.0))
	var floors: int = maxi(2, int(h / 3.0))
	_window_grid(walls, win_mat, cols, floors)
	_trim_and_door(walls, win_mat)
	if spire:
		var cone := MeshInstance3D.new()
		cone.name = nm + "Spire"
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 1.1
		cm.height = 4.0
		cm.radial_segments = 8
		cone.mesh = cm
		cone.position = Vector3(0.0, h + 2.0, 0.0)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.95, 0.95, 0.92, 1.0)
		sm.roughness = 0.8
		cone.set_surface_override_material(0, sm)
		group.add_child(cone)
	var body := StaticBody3D.new()
	body.name = nm + "Solid"
	body.collision_layer = 1
	group.add_child(body)
	var shape := CollisionShape3D.new()
	shape.name = nm + "Shape"
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, h, d)
	shape.shape = bs
	shape.position = Vector3(0.0, h * 0.5, 0.0)
	body.add_child(shape)

static func _add_fountain(world: Node3D, nm: String, x: float, z: float) -> void:
	var group := Node3D.new()
	group.name = nm
	group.position = Vector3(x, 0.0, z)
	world.call_deferred("add_child", group)
	var basin := MeshInstance3D.new()
	basin.name = nm + "Basin"
	var bm := BoxMesh.new()
	bm.size = Vector3(3.4, 0.4, 3.4)
	basin.mesh = bm
	basin.position = Vector3(0.0, 0.2, 0.0)
	var bm_mat := StandardMaterial3D.new()
	bm_mat.albedo_color = Color(0.75, 0.75, 0.72, 1.0)
	bm_mat.roughness = 0.9
	basin.set_surface_override_material(0, bm_mat)
	group.add_child(basin)
	var water := MeshInstance3D.new()
	water.name = "FountainWater56"
	var wm := BoxMesh.new()
	wm.size = Vector3(3.0, 0.12, 3.0)
	water.mesh = wm
	water.position = Vector3(0.0, 0.42, 0.0)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.20, 0.55, 0.95, 1.0)
	wmat.emission_enabled = false
	wmat.emission = Color(0.20, 0.55, 1.0, 1.0)
	wmat.emission_energy_multiplier = 1.2
	water.set_surface_override_material(0, wmat)
	group.add_child(water)
	var jet_idx := 0
	for jx in [-0.8, 0.0, 0.8]:
		var jet := MeshInstance3D.new()
		jet.name = "FountainJet56_%d" % jet_idx
		jet_idx += 1
		var jm := BoxMesh.new()
		jm.size = Vector3(0.12, 1.0, 0.12)
		jet.mesh = jm
		jet.position = Vector3(jx, 0.9, 0.0)
		var jmat := StandardMaterial3D.new()
		jmat.albedo_color = Color(0.85, 0.93, 1.0, 0.85)
		jmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		jet.set_surface_override_material(0, jmat)
		group.add_child(jet)

static func dress(world: Node) -> void:
	if world == null:
		return
	if world.get_node_or_null("City56Applied") != null:
		return
	_shared()
	var win_mat: Material = null
	var dn := world.get_node_or_null("DayNight")
	if dn != null:
		win_mat = dn.get("window_material") as Material
	if win_mat == null:
		win_mat = StandardMaterial3D.new()
		(win_mat as StandardMaterial3D).albedo_color = Color(0.10, 0.12, 0.16, 1.0)
	var env_node := world.get_node_or_null("WorldEnvironment56")
	if env_node == null:
		var we := WorldEnvironment.new()
		we.name = "WorldEnvironment56"
		var env := Environment.new()
		env.background_mode = Environment.BG_SKY
		var sky := Sky.new()
		var smat := ProceduralSkyMaterial.new()
		smat.sky_top_color = Color(0.30, 0.58, 0.95, 1.0)
		smat.sky_horizon_color = Color(0.70, 0.82, 1.0, 1.0)
		smat.ground_bottom_color = Color(0.25, 0.35, 0.25, 1.0)
		smat.ground_horizon_color = Color(0.55, 0.60, 0.55, 1.0)
		sky.sky_material = smat
		env.sky = sky
		we.environment = env
		world.call_deferred("add_child", we)
	for wname in ["Pond", "River13", "MindonWaterNS", "MindonWaterNorth", "MindonWaterSW"]:
		var mi := world.get_node_or_null(wname) as MeshInstance3D
		if mi != null:
			mi.set_surface_override_material(0, _water_mat)
	var wall_defs: Array = [
		["MindonTempleWalls", 0, 3, 2],
		["MindonHospitalWalls", 4, 3, 2],
		["MindonPostWalls", 2, 3, 2],
		["MindonEduWalls", 3, 3, 2],
		["MindonMRTVWalls", 0, 3, 2],
		["MindonShopsWalls", 1, 3, 2],
		["House6Walls", 0, 3, 2],
		["House7_17", 2, 3, 2],
		["House8_18", 0, 3, 2],
		["StiltWalls13", 0, 3, 2],
		["StiltWalls15_4", 2, 3, 2],
	]
	for def in wall_defs:
		var mi2 := _find_node(world, String(def[0])) as MeshInstance3D
		if mi2 != null:
			_dress_wall(mi2, win_mat, int(def[1]), int(def[2]), int(def[3]))
	var stack: Array = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		if not (node is MeshInstance3D):
			continue
		var mi3 := node as MeshInstance3D
		if String(mi3.name) == "DressWall53":
			var h: float = _hash01(String(mi3.get_parent().name) if mi3.get_parent() != null else "house")
			mi3.set_surface_override_material(0, _plaster[int(h * 5.0) % _plaster.size()])
		elif String(mi3.name).begins_with("TreeTop"):
			var h2: float = _hash01(String(mi3.name))
			if h2 < 0.5:
				var canopy := MeshInstance3D.new()
				canopy.name = "Canopy56"
				var sm2 := SphereMesh.new()
				sm2.radius = 0.9
				sm2.height = 1.8
				canopy.mesh = sm2
				canopy.position = Vector3(0.5, 0.5, 0.3)
				var cm2 := StandardMaterial3D.new()
				cm2.albedo_color = Color(0.10 + h2 * 0.15, 0.45 + h2 * 0.20, 0.12, 1.0)
				cm2.roughness = 1.0
				canopy.set_surface_override_material(0, cm2)
				mi3.add_child(canopy)
	var street_names: Array = ["MindonLinkRoad", "MindonStreet1", "MindonStreet2", "MindonStreet3", "MindonStreet4", "MindonStreet5", "MindonStreet6"]
	for sname in street_names:
		var st := _find_node(world, String(sname)) as MeshInstance3D
		if st == null:
			continue
		var smesh := st.mesh as BoxMesh
		if smesh == null:
			continue
		var length: float = smesh.size.x * st.scale.x
		var width: float = smesh.size.z * st.scale.z
		var base_pos: Vector3 = st.global_position
		var dashes: int = int(length / 4.0)
		for i in dashes:
			var dash := MeshInstance3D.new()
			dash.name = "Lane56_%d_%d" % [int(sname.hash() % 100), i]
			var dm := BoxMesh.new()
			dm.size = Vector3(2.0, 0.02, 0.18)
			dash.mesh = dm
			dash.position = Vector3(base_pos.x - length * 0.5 + (float(i) + 0.5) * 4.0, 0.18, base_pos.z)
			var dmat := StandardMaterial3D.new()
			dmat.albedo_color = Color(0.95, 0.85, 0.25, 1.0)
			dash.set_surface_override_material(0, dmat)
			world.call_deferred("add_child", dash)
		for side in [-1.0, 1.0]:
			var curb := MeshInstance3D.new()
			curb.name = "Curb56_%d_%d" % [int(sname.hash() % 100), int(side)]
			var cm3 := BoxMesh.new()
			cm3.size = Vector3(length, 0.18, 0.6)
			curb.mesh = cm3
			curb.position = Vector3(base_pos.x, 0.12, base_pos.z + side * (width * 0.5 + 0.3))
			var cmat := StandardMaterial3D.new()
			cmat.albedo_color = Color(0.68, 0.68, 0.65, 1.0)
			cmat.roughness = 1.0
			curb.set_surface_override_material(0, cmat)
			world.call_deferred("add_child", curb)
	_add_city_block(world, win_mat, "CityBlock56A", 130.0, -12.0, 10.0, 11.0, 8.0, 0, false)
	_add_city_block(world, win_mat, "CityBlock56B", 160.0, -12.0, 8.0, 14.0, 8.0, 1, true)
	_add_city_block(world, win_mat, "CityBlock56C", 190.0, -12.0, 10.0, 9.0, 8.0, 2, false)
	_add_city_block(world, win_mat, "CityBlock56D", 130.0, 12.0, 8.0, 10.0, 8.0, 3, false)
	_add_city_block(world, win_mat, "CityBlock56E", 170.0, 12.0, 10.0, 12.0, 8.0, 4, false)
	_add_city_block(world, win_mat, "CityBlock56F", 200.0, 12.0, 8.0, 8.0, 8.0, 2, false)
	_add_fountain(world, "Fountain56A", 150.0, -22.0)
	_add_fountain(world, "Fountain56B", 182.0, -22.0)
	var night := Node3D.new()
	night.name = "NightLights56"
	night.set_script(load("res://city_night56.gd"))
	world.call_deferred("add_child", night)
	for li in 4:
		var lamp := OmniLight3D.new()
		lamp.name = "StreetOmni56_%d" % li
		lamp.light_energy = 1.4
		lamp.light_color = Color(1.0, 0.85, 0.55, 1.0)
		lamp.omni_range = 14.0
		lamp.position = Vector3(125.0 + float(li) * 25.0, 4.5, 0.0)
		night.add_child(lamp)
	var fw := Node3D.new()
	fw.name = "Fireworks56"
	fw.position = Vector3(165.0, 28.0, -35.0)
	fw.visible = false
	world.call_deferred("add_child", fw)
	for ci in 3:
		var cluster := Node3D.new()
		cluster.name = "Burst56_%d" % ci
		cluster.position = Vector3(float(ci) * 8.0 - 8.0, 0.0, 0.0)
		fw.add_child(cluster)
		var cols: Array = [Color(1.0, 0.25, 0.25, 1.0), Color(1.0, 0.85, 0.25, 1.0), Color(0.25, 0.65, 1.0, 1.0)]
		for si in 5:
			var spark := MeshInstance3D.new()
			spark.name = "Spark56"
			var ssm := SphereMesh.new()
			ssm.radius = 0.25
			ssm.height = 0.5
			spark.mesh = ssm
			var ang: float = float(si) * 1.2566
			spark.position = Vector3(cos(ang) * 2.5, sin(ang) * 2.5, 0.0)
			var smat2 := StandardMaterial3D.new()
			smat2.albedo_color = cols[ci]
			smat2.emission_enabled = true
			smat2.emission = cols[ci]
			smat2.emission_energy_multiplier = 2.0
			spark.set_surface_override_material(0, smat2)
			cluster.add_child(spark)
	for ci2 in 3:
		var cloud := MeshInstance3D.new()
		cloud.name = "Cloud56_%d" % ci2
		var csm := SphereMesh.new()
		csm.radius = 6.0
		csm.height = 3.0
		cloud.mesh = csm
		cloud.position = Vector3(-40.0 + float(ci2) * 60.0, 42.0, -60.0 + float(ci2) * 20.0)
		cloud.scale = Vector3(2.0, 0.5, 1.0)
		var cmat2 := StandardMaterial3D.new()
		cmat2.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
		cmat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cloud.set_surface_override_material(0, cmat2)
		world.call_deferred("add_child", cloud)
	var marker := Node3D.new()
	marker.name = "City56Applied"
	world.call_deferred("add_child", marker)
