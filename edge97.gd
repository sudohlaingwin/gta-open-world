extends Node3D
## Slice 97 WORLD EDGES (owner complaint 2026-10-23 ~20:29:
## "sold as a real open world yet there ARE end places" — the
## player hits the ground cut / clamp at x -70..2450,
## z -210..110). The ground grows to x -670..3050,
## z -510..410 (3720 x 920 m, ~3.42 km2, ~4.2x the old
## 2520 x 320 m), as 4 new planes abutting the old rect with
## NO overlap (east/west fill the old z band, north/south
## span the full new width outside it). Each new plane gets
## a REAL collision body (a visual-only plane would drop the
## player through — second stated collider exception besides
## the scaled-house solids). The long route continues EAST
## as a dirt track (scenery ONLY — no bus stops, no route
## logic, no timetable change: bus-system changes are
## forbidden). ALL new borders get hills + forest so the
## boundary reads as landscape, not a cut, and the extension
## interior gets fields/trees/pond so it does not read as
## void. The bounds clamp STAYS (player never falls off the
## world) but moves out to the new rect minus the old 0.5 m
## margin. MapTransform + minimap/world-map follow via
## apply_extension() (called here AND from both
## _configure_map_bounds paths, so opening the world map
## cannot snap the bounds back to the old rect — the Slice
## 49/62 bounds-bug lesson). HONEST LIMIT, stated plainly:
## the world stays FINITE — a truly endless streaming-terrain
## world is architecture work beyond one slice; this extension
## pushes the ends far out and landscapes them, it does not
## remove ends. Runtime dressing only, no .tscn edits.

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Edge97") != null:
		return
	var n := Node3D.new()
	n.name = "Edge97"
	n.set_script(load("res://edge97.gd"))
	world.call_deferred("add_child", n)

var _done: bool = false

func _process(_delta: float) -> void:
	if _done:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	_build(world)
	_done = true

func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

func _cone(parent: Node3D, nm: String, r: float, h: float, pos: Vector3, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.1
	mesh.bottom_radius = r
	mesh.height = h
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

func _hash01(s: String) -> float:
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0

func _ground_plane(parent: Node3D, nm: String, size: Vector2, cx: float, cz: float, mat: Material) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(cx, 0.0, cz)
	parent.add_child(mi)
	var body := StaticBody3D.new()
	body.name = nm + "Body"
	body.position = Vector3(cx, -0.5, cz)
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.name = "Shape97"
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 1.0, size.y)
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)

func _build(world: Node3D) -> void:
	# Bounds FIRST: minimap/world-map must use the new rect
	# from this frame on (both _configure_map_bounds paths
	# also call apply_extension after any re-configure).
	MapTransform.apply_extension()
	var ground_m := _mat(Color(0.25, 0.55, 0.25, 1.0), 1.0)
	_ground_plane(self, "GroundEast97", Vector2(600.0, 320.0), 2750.0, -50.0, ground_m)
	_ground_plane(self, "GroundWest97", Vector2(600.0, 320.0), -370.0, -50.0, ground_m)
	_ground_plane(self, "GroundNorth97", Vector2(3720.0, 300.0), 1190.0, -360.0, ground_m)
	_ground_plane(self, "GroundSouth97", Vector2(3720.0, 300.0), 1190.0, 260.0, ground_m)
	# Border hills + forest ring (inside the new bounds by
	# 15-40 m so the clamp line itself is never the visual
	# edge). Hills: big green cones; forest: single-cone
	# pines (distant border dressing — one node per tree).
	var hill_m := _mat(Color(0.16, 0.42, 0.16, 1.0), 1.0)
	var pine_m := _mat(Color(0.10, 0.35, 0.12, 1.0), 1.0)
	var hi := 0
	var x := -600.0
	while x <= 3000.0:
		var hr := 20.0 + _hash01("hillN%d" % hi) * 25.0
		var hh := 15.0 + _hash01("hillNh%d" % hi) * 20.0
		_cone(self, "Hill97N_%d" % hi, hr, hh, Vector3(x, hh * 0.5, -495.0), hill_m)
		hr = 20.0 + _hash01("hillS%d" % hi) * 25.0
		hh = 15.0 + _hash01("hillSh%d" % hi) * 20.0
		_cone(self, "Hill97S_%d" % hi, hr, hh, Vector3(x, hh * 0.5, 395.0), hill_m)
		hi += 1
		x += 150.0
	var z := -400.0
	while z <= 300.0:
		var hr := 20.0 + _hash01("hillW%d" % int(z)) * 25.0
		var hh := 15.0 + _hash01("hillWh%d" % int(z)) * 20.0
		_cone(self, "Hill97W_%d" % int(z), hr, hh, Vector3(-655.0, hh * 0.5, z), hill_m)
		hr = 20.0 + _hash01("hillE%d" % int(z)) * 25.0
		hh = 15.0 + _hash01("hillEh%d" % int(z)) * 20.0
		_cone(self, "Hill97E_%d" % int(z), hr, hh, Vector3(3035.0, hh * 0.5, z), hill_m)
		z += 100.0
	var ti := 0
	x = -600.0
	while x <= 3000.0:
		var th := 7.0 + _hash01("treeN%d" % ti) * 4.0
		_cone(self, "BorderTree97N_%d" % ti, 2.5, th, Vector3(x, th * 0.5, -470.0), pine_m)
		th = 7.0 + _hash01("treeS%d" % ti) * 4.0
		_cone(self, "BorderTree97S_%d" % ti, 2.5, th, Vector3(x, th * 0.5, 370.0), pine_m)
		ti += 1
		x += 60.0
	z = -400.0
	while z <= 300.0:
		var th := 7.0 + _hash01("treeW%d" % int(z)) * 4.0
		_cone(self, "BorderTree97W_%d" % int(z), 2.5, th, Vector3(-630.0, th * 0.5, z), pine_m)
		th = 7.0 + _hash01("treeE%d" % int(z)) * 4.0
		_cone(self, "BorderTree97E_%d" % int(z), 2.5, th, Vector3(3010.0, th * 0.5, z), pine_m)
		z += 60.0
	# Extension interior: fields + scattered pines + one pond
	# (west), so the new ground reads as countryside, not void.
	# Deterministic hash scatter, kept clear of the east dirt
	# track (z -4..4) and 30 m inside every border.
	var crop_a := _mat(Color(0.20, 0.55, 0.20, 1.0), 1.0)
	var crop_b := _mat(Color(0.45, 0.55, 0.15, 1.0), 1.0)
	var dirt := _mat(Color(0.65, 0.52, 0.32, 1.0), 1.0)
	var water := _mat(Color(0.20, 0.45, 0.75, 1.0), 0.4)
	var fi := 0
	for rect in [[2500.0, 3000.0, -180.0, 80.0], [-620.0, -120.0, -180.0, 80.0], [-620.0, 3000.0, -480.0, -240.0], [-620.0, 3000.0, 140.0, 380.0]]:
		var fx0: float = rect[0]
		var fx1: float = rect[1]
		var fz0: float = rect[2]
		var fz1: float = rect[3]
		for k in range(11):
			var fx := fx0 + (fx1 - fx0) * _hash01("field%d_%d" % [fi, k])
			var fz := fz0 + (fz1 - fz0) * _hash01("fieldz%d_%d" % [fi, k])
			if fx > 2440.0 and absf(fz) < 12.0:
				continue
			_box(self, "Field97_%d_%d" % [fi, k], Vector3(40.0, 0.1, 30.0), Vector3(fx, 0.05, fz), crop_a if k % 2 == 0 else crop_b)
		fi += 1
	var si := 0
	for rect in [[2500.0, 3000.0, -180.0, 80.0], [-620.0, -120.0, -180.0, 80.0], [-620.0, 3000.0, -480.0, -240.0], [-620.0, 3000.0, 140.0, 380.0]]:
		var fx0: float = rect[0]
		var fx1: float = rect[1]
		var fz0: float = rect[2]
		var fz1: float = rect[3]
		for k in range(17):
			var fx := fx0 + (fx1 - fx0) * _hash01("scat%d_%d" % [si, k])
			var fz := fz0 + (fz1 - fz0) * _hash01("scatz%d_%d" % [si, k])
			if fx > 2440.0 and absf(fz) < 12.0:
				continue
			var th := 6.0 + _hash01("scath%d_%d" % [si, k]) * 4.0
			_cone(self, "ScatTree97_%d_%d" % [si, k], 2.2, th, Vector3(fx, th * 0.5, fz), pine_m)
		si += 1
	# West pond.
	var pond := CylinderMesh.new()
	pond.top_radius = 12.0
	pond.bottom_radius = 12.0
	pond.height = 0.1
	var pond_mi := MeshInstance3D.new()
	pond_mi.name = "Pond97"
	pond_mi.mesh = pond
	pond_mi.material_override = water
	pond_mi.position = Vector3(-350.0, 0.05, 0.0)
	add_child(pond_mi)
	# East dirt track: route continuation as SCENERY ONLY
	# (no stops, no route logic, no timetable — bus system
	# untouched). From the old route end (x 2445) to x 2900.
	_box(self, "TrackEast97", Vector3(455.0, 0.12, 8.0), Vector3(2672.5, 0.06, 0.0), dirt)
	for k in range(6):
		var tx := 2500.0 + float(k) * 70.0
		var th := 6.0 + float(k) * 0.5
		_cone(self, "TrackTree97_%d" % k, 2.2, th, Vector3(tx, th * 0.5, -10.0), pine_m)
