extends Node3D
## Slice 75 — BUS SIMULATION, part 2 (owner simulation
## direction 2026-10-23 11:31 + bus choice 11:32).
## This node is added deferred by dress() AFTER the Slice 74
## dress() calls (player.gd), so the Bus node and LongRoute74
## already exist when _ready runs; bus polish still retries
## on _process until the Bus appears, so a queue-order
## surprise can never silently drop the interior or sign.
## What it builds, all runtime-only, NO scene touched:
## - CURVED SCENIC SECTIONS (the Slice 74 road was one
##   straight slab): a 4-segment S-bend loop leaving the
##   main road at x 1500, swinging north to z -120 and
##   rejoining at x 1900, plus a junction spur at x 2100
##   running south to a small hamlet (4 houses + 5 trees).
##   The straight road and all 4 stops are untouched and
##   unmoved; the new slabs only TOUCH the main slab at
##   its edge (z -6 / z +6), never overlap it, so there is
##   no coplanar z-fighting. Everything sits inside the
##   Slice 38 world bounds (x -69.5..2449.5, z
##   -209.5..109.5). Zero colliders on every new mesh
##   (visual only, Slice 74 pattern) — the bus drives on
##   the ground plane, and no curve can block a road.
## - BUS POLISH: driver seat + steering wheel + 4 rows of
##   passenger seats inside the bus, and a destination
##   sign (DestSign75, real Noto font like Slice 69/74)
##   on the bus front showing the next stop (text owned
##   by bus_controller74.gd). The Slice 74 side windows
##   were opaque dark glass, so the interior would have
##   been invisible: their material is replaced with a
##   semi-transparent glass, and only then is the
##   interior claimed visible — the transparency change
##   is part of this slice, not assumed.
## - ROUTE HUD: RouteLabel75 (text owned by the
##   controller, same visibility rule as BoardLabel74).
## No traffic-rule enforcement, no economy, no new quest
## or signboard system: this slice stays inside the
## bus-simulation scope. No opponent code, map, names or
## structure is used. Touch-first throughout (no keys).

const LOOP_PTS: Array = [
	Vector2(1500.0, -6.0),
	Vector2(1500.0, -80.0),
	Vector2(1700.0, -120.0),
	Vector2(1900.0, -80.0),
	Vector2(1900.0, -6.0),
]

var _built: bool = false
var _bus_done: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusRoute75") != null:
		return
	var n := Node3D.new()
	n.name = "BusRoute75"
	n.set_script(load("res://bus_route75.gd"))
	world.call_deferred("add_child", n)


static func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


static func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.rotation.y = rot_y
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


static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61/74 HUD controls.
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


func _tree(parent: Node3D, nm: String, pos: Vector3, trunk_m: Material, canopy_m: Material) -> void:
	# Canopy name contains "Canopy", so the Slice 62
	# season tint applies to it like Canopy64/74.
	var tg := Node3D.new()
	tg.name = nm
	tg.position = pos
	parent.add_child(tg)
	_cyl(tg, "Trunk75", 0.25, 0.35, 2.2, Vector3(0.0, 1.1, 0.0), trunk_m)
	_sphere(tg, "Canopy75", 2.2, Vector3(0.0, 3.2, 0.0), canopy_m)


func _house(parent: Node3D, nm: String, pos: Vector3, wall_m: Material, roof_m: Material, post_m: Material) -> void:
	# Small stilt house: 4 posts + walls + flat roof slab +
	# door. Visual only, no collider, same as Slice 74.
	var g := Node3D.new()
	g.name = nm
	g.position = pos
	parent.add_child(g)
	# Sibling names must be unique or Godot silently renames
	# losers to @MeshInstance3D@N (Slice 58 lesson).
	var pi := 0
	for px in [-3.0, 3.0]:
		for pz in [-2.5, 2.5]:
			_cyl(g, "Post75_%d" % pi, 0.14, 0.14, 1.2, Vector3(px, 0.6, pz), post_m)
			pi += 1
	_box(g, "Walls75", Vector3(7.0, 2.4, 6.0), Vector3(0.0, 2.4, 0.0), wall_m)
	_box(g, "Roof75", Vector3(8.0, 0.2, 7.0), Vector3(0.0, 3.7, 0.0), roof_m)
	_box(g, "Door75", Vector3(1.0, 1.8, 0.12), Vector3(0.0, 2.1, -3.05), post_m)


func _build_curves() -> void:
	var grp := Node3D.new()
	grp.name = "Curves75"
	add_child(grp)
	var asphalt := _mat(Color(0.16, 0.16, 0.17, 1.0), 0.95)
	var line_white := _mat(Color(0.9, 0.9, 0.85, 1.0), 0.8)
	var crop := _mat(Color(0.2, 0.55, 0.2, 1.0), 1.0)
	var trunk_m := _mat(Color(0.35, 0.22, 0.12, 1.0), 1.0)
	var canopy_m := _mat(Color(0.1, 0.42, 0.16, 1.0), 1.0)
	var wall_m := _mat(Color(0.55, 0.42, 0.3, 1.0), 0.9)
	var roof_m := _mat(Color(0.45, 0.2, 0.15, 1.0), 0.8)
	var post_m := _mat(Color(0.4, 0.3, 0.2, 1.0), 0.9)
	# S-bend loop: 4 slabs, each rotated to its segment
	# heading (local +X maps to (cos, -sin) under rot Y).
	for si in range(LOOP_PTS.size() - 1):
		var a: Vector2 = LOOP_PTS[si]
		var b: Vector2 = LOOP_PTS[si + 1]
		var d := b - a
		var seg_len := d.length()
		var mid := (a + b) * 0.5
		var theta := atan2(-d.y, d.x)
		_box(grp, "LoopSlab75_%d" % si, Vector3(seg_len, 0.12, 12.0), Vector3(mid.x, 0.06, mid.y), asphalt, theta)
		var t := 6.0
		var di := 0
		while t < seg_len - 2.0:
			var p := a + d.normalized() * t
			_box(grp, "LoopDash75_%d_%d" % [si, di], Vector3(4.0, 0.03, 0.3), Vector3(p.x, 0.13, p.y), line_white, theta)
			di += 1
			t += 12.0
	# Loop trees + fields (clear of the slabs: the loop
	# corridor is 12 m wide, trees sit 14+ m off-centre).
	var loop_trees: Array = [
		Vector3(1480.0, 0.0, -40.0), Vector3(1600.0, 0.0, -100.0),
		Vector3(1800.0, 0.0, -100.0), Vector3(1920.0, 0.0, -40.0),
		Vector3(1560.0, 0.0, -135.0), Vector3(1840.0, 0.0, -140.0),
	]
	for ti in range(loop_trees.size()):
		_tree(grp, "LoopTree75_%d" % ti, loop_trees[ti], trunk_m, canopy_m)
	_box(grp, "LoopField75_0", Vector3(30.0, 0.08, 16.0), Vector3(1650.0, 0.04, -45.0), crop)
	_box(grp, "LoopField75_1", Vector3(30.0, 0.08, 16.0), Vector3(1750.0, 0.04, -150.0), crop)
	# Hamlet spur: junction at x 2100 on the main road's
	# south edge (z +6), running south to z 60; the hamlet
	# sits at z 75..101, inside the world bounds.
	_box(grp, "SpurRoad75", Vector3(12.0, 0.12, 54.0), Vector3(2100.0, 0.06, 33.0), asphalt)
	var hamlet_pos: Array = [
		Vector3(2075.0, 0.0, 78.0), Vector3(2125.0, 0.0, 78.0),
		Vector3(2075.0, 0.0, 98.0), Vector3(2125.0, 0.0, 98.0),
	]
	for hi in range(hamlet_pos.size()):
		_house(grp, "HamletHouse75_%d" % hi, hamlet_pos[hi], wall_m, roof_m, post_m)
	var hamlet_trees: Array = [
		Vector3(2055.0, 0.0, 70.0), Vector3(2145.0, 0.0, 70.0),
		Vector3(2100.0, 0.0, 105.0), Vector3(2050.0, 0.0, 88.0),
		Vector3(2150.0, 0.0, 88.0),
	]
	for ti in range(hamlet_trees.size()):
		_tree(grp, "HamletTree75_%d" % ti, hamlet_trees[ti], trunk_m, canopy_m)


func _try_bus_polish() -> bool:
	var world := get_parent() as Node3D
	if world == null:
		return false
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus == null:
		return false
	# Semi-transparent glass FIRST: without it the seats
	# below would be invisible behind opaque glass, and
	# claiming a visible interior would be false.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.1, 0.2, 0.3, 0.45)
	glass.roughness = 0.1
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for wn in ["BusWinL74", "BusWinR74", "BusShield74", "BusRear74"]:
		var w := bus.get_node_or_null(wn) as MeshInstance3D
		if w != null:
			w.set_surface_override_material(0, glass)
	var seat_m := _mat(Color(0.2, 0.25, 0.35, 1.0), 0.9)
	# 4 rows of passenger seats (forward = local -z, so
	# backrests sit toward +z of each seat base). Indexed
	# names: duplicate sibling names get silently renamed
	# by Godot (Slice 58 lesson), so Seat75/SeatBack75
	# must be unique per seat.
	var sidx := 0
	for row_z in [-2.5, -1.0, 0.5, 2.0]:
		for sx in [-0.75, 0.75]:
			_box(bus, "Seat75_%d" % sidx, Vector3(0.55, 0.15, 0.5), Vector3(sx, 1.0, row_z), seat_m)
			_box(bus, "SeatBack75_%d" % sidx, Vector3(0.55, 0.6, 0.12), Vector3(sx, 1.3, row_z + 0.28), seat_m)
			sidx += 1
	# Driver seat + steering wheel (driver sits local +x:
	# facing -z, the driver's right hand is +x).
	_box(bus, "DriverSeat75", Vector3(0.55, 0.15, 0.5), Vector3(0.75, 1.0, -3.4), seat_m)
	_box(bus, "DriverBack75", Vector3(0.55, 0.6, 0.12), Vector3(0.75, 1.3, -3.12), seat_m)
	var col := _cyl(bus, "SteerCol75", 0.05, 0.05, 0.6, Vector3(0.75, 1.4, -3.9), seat_m)
	col.rotation.x = 0.6
	var wheel := _cyl(bus, "SteerWheel75", 0.28, 0.28, 0.06, Vector3(0.75, 1.55, -4.0), seat_m)
	wheel.rotation.x = PI * 0.5
	# Destination sign on the bus front (local -z face):
	# dark board + real Myanmar text, rotated PI so the
	# face points forward, double-sided so it also reads
	# through the now-transparent windshield.
	var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
	_box(bus, "DestBoard75", Vector3(2.6, 0.6, 0.08), Vector3(0.0, 2.75, -4.58), board_m)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	if font == null:
		push_error("BusRoute75: Myanmar font failed to load, destination sign skipped")
	else:
		var lab := Label3D.new()
		lab.name = "DestSign75"
		lab.text = "မှတ်တိုင် ၁"
		lab.font = font
		lab.font_size = 40
		lab.pixel_size = 0.012
		lab.position = Vector3(0.0, 2.75, -4.63)
		lab.rotation.y = PI
		lab.double_sided = true
		bus.add_child(lab)
	return true


func _ready() -> void:
	if _built:
		return
	_built = true
	_build_curves()
	# HUD route label (text + visibility owned by the
	# controller, same rule as BoardLabel74). Rect
	# (720,560,214,40) is disjoint from DoorButton74
	# (940,610), BoardLabel74 (830,610) and the Slice 61
	# bottom-right cluster (x >= 1050): verified in SIM75.
	var world := get_parent() as Node3D
	if world != null:
		var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
		if layer != null and layer.get_node_or_null("RouteLabel75") == null:
			var rlab := Label.new()
			rlab.name = "RouteLabel75"
			rlab.text = "➡ နောက်: မှတ်တိုင် ၁"
			rlab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_set_rect(rlab, 720.0, 560.0, 214.0, 40.0)
			rlab.visible = false
			layer.add_child(rlab)
	_bus_done = _try_bus_polish()


func _process(_delta: float) -> void:
	if not _bus_done:
		_bus_done = _try_bus_polish()
