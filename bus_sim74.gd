extends RefCounted
## Slice 74 — BUS SIMULATION, part 1 (owner redirection 2026-10-23
## 11:31 + owner choice 11:32: BUS + STOPS + PASSENGERS).
## What this file builds, all runtime-only (main.tscn itself is
## touched ONLY for the ground-plane resize + bounds, see
## player.gd — the same class of change Slice 62 made):
## - LONG SCENIC ROUTE: the East Fields main road continues east
##   from x 445 to x 2445 — 2000 m of driveable road at z 0, 12 m
##   wide, with centre dashes, edge lines, curbs, a stream
##   crossing at x 1500 (split so the road slab covers it, Slice
##   62 pattern), crop fields, 32 trees, horizon hills. The old
##   world was ~520 m wide, so a long-view drive ended in
##   seconds; this is the core scale gap the owner named.
## - BUS STOPS: 4 stops at x 700 / 1200 / 1700 / 2200, south
##   side (z 10.5, clear of the 12 m slab + curbs): shelter +
##   sign board with a REAL Myanmar font (Noto Sans Myanmar, the
##   Slice 69 font — never the default font, which has no Myanmar
##   glyphs) + painted stop zone + 2 waiting passengers each.
## - BUS: a drivable CharacterBody3D "Bus" (script bus.gd) parked
##   in the village at (30, 16) facing east, so the player walks
##   a few steps, presses Vehicle, and drives the long road.
## - CONTROLLER + HUD: BusSim74 node (bus_controller74.gd)
##   runs door/boarding/alighting + the touch-first "🚪 တံခါး"
##   door button and the "🚌 N" boarded-count label; minimap
##   dots for the 4 stops + the bus (Slice 64 runtime-dot
##   pattern). No money/economy system (later owner decision).
## - MAPS: the resized ground plane (2520x320 at x 1190) makes
##   Slice 49 MapTransform read the new bounds live, so the
##   minimap + world map + tap clamps cover x -70..2450 with no
##   map code changed; world-map LANDMARKS + a "လမ်းရှည်"
##   district band are added in world_map.gd.
## Idempotent: if LongRoute74 already exists, dress() returns.
## No opponent map, names, structure or code is used. No
## keyboard-primary control is added anywhere (Evo's F key is
## a touch button here, never a key binding).

const ROAD_X0: float = 445.0
const ROAD_X1: float = 2445.0
const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0]
const STOP_ZONE_R: float = 9.0


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


static func _cone(parent: Node3D, nm: String, bot_r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	# Godot 4.3 has no ConeMesh; a cylinder with top radius 0
	# is the cone (same trick Slice 72 used for hill cones).
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = bot_r
	mesh.height = h
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi


static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61 hud_fix61b._set_rect, so
	# these controls scale exactly like the rest of the HUD.
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


static func _hash01(s: String) -> float:
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0


static func _passenger(parent: Node3D, nm: String, pos: Vector3, body_mat: Material, head_mat: Material) -> void:
	# Waiting figure: simple villager body + head, Myanmar
	# dress colours. Visual only — no collider, no script, so a
	# waiting passenger can never block the bus or the road.
	var g := Node3D.new()
	g.name = nm
	g.position = pos
	parent.add_child(g)
	_cyl(g, "Body74", 0.28, 0.28, 1.1, Vector3(0.0, 0.55, 0.0), body_mat)
	_sphere(g, "Head74", 0.22, Vector3(0.0, 1.35, 0.0), head_mat)


static func _stop(parent: Node3D, idx: int, x: float, font: Font, shelter_mat: Material, post_mat: Material, board_mat: Material, zone_mat: Material, body_mats: Array, head_mat: Material) -> void:
	# Stop group origin IS the stop point (x, 0): the world-map
	# LANDMARKS entry reads this node, so the dot tracks the
	# stop exactly. Shelter + sign sit on the south side
	# (z 8.5..10.5), clear of the slab (|z| <= 6) and curbs.
	var g := Node3D.new()
	g.name = "BusStop74_%d" % idx
	g.position = Vector3(x, 0.0, 0.0)
	parent.add_child(g)
	# Painted stop zone on the road shoulder: x +-9, z -1..9.
	_box(g, "Zone74", Vector3(18.0, 0.02, 10.0), Vector3(0.0, 0.14, 4.0), zone_mat)
	# Shelter: 2 posts + roof.
	_cyl(g, "ShelterPost74A", 0.12, 0.12, 2.2, Vector3(-3.0, 1.1, 10.5), post_mat)
	_cyl(g, "ShelterPost74B", 0.12, 0.12, 2.2, Vector3(3.0, 1.1, 10.5), post_mat)
	_box(g, "ShelterRoof74", Vector3(7.0, 0.15, 3.0), Vector3(0.0, 2.3, 10.5), shelter_mat)
	# Sign post + board + real Myanmar text. The board faces
	# the road (-z): Label3D rotated PI so its face points at
	# oncoming drivers, double-sided so it reads from behind too.
	_cyl(g, "SignPost74", 0.1, 0.1, 2.0, Vector3(0.0, 1.0, 8.5), post_mat)
	_box(g, "SignBoard74", Vector3(4.0, 1.0, 0.12), Vector3(0.0, 2.2, 8.5), board_mat)
	if font != null:
		var lab := Label3D.new()
		lab.name = "SignLabel74"
		var my_digits: Array = ["၁", "၂", "၃", "၄"]
		lab.text = "ဘတ်စ်ကား မှတ်တိုင် " + str(my_digits[idx])
		lab.font = font
		lab.font_size = 32
		lab.pixel_size = 0.012
		lab.position = Vector3(0.0, 2.2, 8.42)
		lab.rotation.y = PI
		lab.double_sided = true
		g.add_child(lab)
	else:
		push_error("BusSim74: Myanmar font failed to load, stop label skipped")
	# 2 waiting passengers under the shelter.
	_passenger(g, "Waiting74_%d_0" % idx, Vector3(-2.0, 0.0, 10.5), body_mats[0], head_mat)
	_passenger(g, "Waiting74_%d_1" % idx, Vector3(2.0, 0.0, 10.5), body_mats[1], head_mat)


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("LongRoute74") != null:
		return
	var asphalt := _mat(Color(0.16, 0.16, 0.17, 1.0), 0.95)
	var line_white := _mat(Color(0.9, 0.9, 0.85, 1.0), 0.8)
	var concrete := _mat(Color(0.55, 0.55, 0.55, 1.0), 1.0)
	var water := _mat(Color(0.15, 0.45, 0.75, 1.0), 0.3)
	var crop := _mat(Color(0.2, 0.55, 0.2, 1.0), 1.0)
	var trunk_m := _mat(Color(0.35, 0.22, 0.12, 1.0), 1.0)
	var canopy_a := _mat(Color(0.1, 0.42, 0.16, 1.0), 1.0)
	var canopy_b := _mat(Color(0.16, 0.5, 0.2, 1.0), 1.0)
	var hill_m := _mat(Color(0.25, 0.45, 0.25, 1.0), 1.0)
	var shelter_m := _mat(Color(0.3, 0.5, 0.7, 1.0), 0.8)
	var post_m := _mat(Color(0.4, 0.4, 0.42, 1.0), 0.6)
	var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
	var zone_m := _mat(Color(0.95, 0.8, 0.2, 1.0), 0.8)
	var body_a := _mat(Color(0.95, 0.95, 0.9, 1.0), 0.9)
	var body_b := _mat(Color(0.2, 0.5, 0.8, 1.0), 0.9)
	var skin_m := _mat(Color(0.8, 0.6, 0.45, 1.0), 0.9)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font

	var grp := Node3D.new()
	grp.name = "LongRoute74"
	world.call_deferred("add_child", grp)

	# Long road: 2000 m slab + edges + curbs (Slice 62 pattern:
	# slab y 0.06 top 0.12, lines y 0.13).
	var road_len := ROAD_X1 - ROAD_X0
	var road_cx := (ROAD_X0 + ROAD_X1) * 0.5
	_box(grp, "LongRoad74", Vector3(road_len, 0.12, 12.0), Vector3(road_cx, 0.06, 0.0), asphalt)
	_box(grp, "LongEdgeN74", Vector3(road_len, 0.03, 0.25), Vector3(road_cx, 0.13, -5.5), line_white)
	_box(grp, "LongEdgeS74", Vector3(road_len, 0.03, 0.25), Vector3(road_cx, 0.13, 5.5), line_white)
	_box(grp, "LongCurbN74", Vector3(road_len, 0.3, 0.5), Vector3(road_cx, 0.15, -6.25), concrete)
	_box(grp, "LongCurbS74", Vector3(road_len, 0.3, 0.5), Vector3(road_cx, 0.15, 6.25), concrete)
	# Centre dashes every 12 m (4 m dash, 8 m gap), Slice 62
	# pattern — individual boxes so the sim can measure each
	# dash position exactly (no texture-orientation gamble).
	var di := 0
	var dx := ROAD_X0 + 10.0
	while dx < ROAD_X1 - 2.0:
		_box(grp, "LongDash74_%d" % di, Vector3(4.0, 0.03, 0.3), Vector3(dx, 0.13, 0.0), line_white)
		di += 1
		dx += 12.0
	# Stream crossing at x 1500, split so the road slab covers
	# it (Slice 62 pattern): water stays below the slab top.
	_box(grp, "LongStreamN74", Vector3(6.0, 0.1, 204.0), Vector3(1500.0, 0.05, -108.0), water)
	_box(grp, "LongStreamS74", Vector3(6.0, 0.1, 104.0), Vector3(1500.0, 0.05, 58.0), water)
	# Crop fields along the road.
	for fi in range(10):
		var fx := 600.0 + float(fi) * 180.0
		var fz := -25.0 if fi % 2 == 0 else 25.0
		_box(grp, "LongField74_%d" % fi, Vector3(40.0, 0.08, 20.0), Vector3(fx, 0.04, fz), crop)
	# Trees along the road (canopy names contain "Canopy", so
	# the Slice 62 season tint applies to them like Canopy64).
	for ti in range(32):
		var tx := 520.0 + float(ti) * 60.0 + _hash01("tree74_%d" % ti) * 20.0
		var tz := (14.0 + _hash01("treez74_%d" % ti) * 26.0) * (1.0 if ti % 2 == 0 else -1.0)
		var tg := Node3D.new()
		tg.name = "LongTree74_%d" % ti
		tg.position = Vector3(tx, 0.0, tz)
		grp.add_child(tg)
		_cyl(tg, "Trunk74", 0.25, 0.35, 2.2, Vector3(0.0, 1.1, 0.0), trunk_m)
		_sphere(tg, "Canopy74", 2.2, Vector3(0.0, 3.2, 0.0), canopy_a if ti % 2 == 0 else canopy_b)
	# Horizon hills: receding silhouettes + 3 big ones at the
	# far end so the road ends in a view, not a void. Visual
	# only, no colliders (Slice 72 hill pattern, stated).
	for hi in range(8):
		var hx := 650.0 + float(hi) * 230.0
		var hz := (120.0 + _hash01("hill74_%d" % hi) * 60.0) * (1.0 if hi % 2 == 0 else -1.0)
		_cone(grp, "LongHill74_%d" % hi, 45.0, 28.0, Vector3(hx, 14.0, hz), hill_m)
	for hi in range(3):
		var hz_list: Array = [-120.0, 0.0, 120.0]
		var hz2: float = hz_list[hi]
		_cone(grp, "LongHorizon74_%d" % hi, 90.0, 70.0, Vector3(2440.0, 35.0, hz2), hill_m)
	# 4 bus stops.
	for si in range(STOPS_X.size()):
		_stop(grp, si, STOPS_X[si], font, shelter_m, post_m, board_m, zone_m, [body_a, body_b], skin_m)

	# Bus (sibling of Player, so player._try_enter_vehicle
	# finds "../Bus" once "Bus" joins its name lists).
	var bus_ref: Node = world.get_node_or_null("Bus")
	if bus_ref == null:
		var bus := CharacterBody3D.new()
		bus.name = "Bus"
		bus.position = Vector3(30.0, 0.0, 16.0)
		bus.rotation.y = -PI * 0.5
		bus.set_script(load("res://bus.gd"))
		world.call_deferred("add_child", bus)
		var bus_body := _mat(Color(0.9, 0.75, 0.15, 1.0), 0.5)
		var bus_trim := _mat(Color(0.15, 0.15, 0.2, 1.0), 0.6)
		var glass_m := _mat(Color(0.1, 0.2, 0.3, 1.0), 0.2)
		var tyre_m := _mat(Color(0.1, 0.1, 0.1, 1.0), 1.0)
		var hub_m := _mat(Color(0.7, 0.7, 0.7, 1.0), 0.4)
		var lamp_m := _mat(Color(1.0, 0.9, 0.6, 1.0), 0.4)
		var lamp_e := StandardMaterial3D.new()
		lamp_e.albedo_color = Color(1.0, 0.9, 0.6, 1.0)
		lamp_e.emission_enabled = true
		lamp_e.emission = Color(1.0, 0.9, 0.6, 1.0)
		lamp_e.emission_energy_multiplier = 1.5
		var tail_m := _mat(Color(0.9, 0.1, 0.1, 1.0), 0.5)
		# Body built along local Z (forward = local -z, the car
		# convention): 9.0 m long, 2.6 m wide, 2.8 m tall.
		_box(bus, "BusBody74", Vector3(2.6, 2.2, 9.0), Vector3(0.0, 1.7, 0.0), bus_body)
		_box(bus, "BusSkirt74", Vector3(2.5, 0.6, 8.8), Vector3(0.0, 0.6, 0.0), bus_trim)
		_box(bus, "BusRoof74", Vector3(2.7, 0.2, 9.2), Vector3(0.0, 2.9, 0.0), bus_trim)
		_box(bus, "BusWinL74", Vector3(0.1, 0.8, 7.5), Vector3(-1.31, 2.1, 0.0), glass_m)
		_box(bus, "BusWinR74", Vector3(0.1, 0.8, 7.5), Vector3(1.31, 2.1, 0.0), glass_m)
		_box(bus, "BusShield74", Vector3(2.2, 0.9, 0.1), Vector3(0.0, 2.1, -4.51), glass_m)
		_box(bus, "BusRear74", Vector3(2.2, 0.9, 0.1), Vector3(0.0, 2.1, 4.51), glass_m)
		_box(bus, "BusHeadL74", Vector3(0.4, 0.3, 0.1), Vector3(-0.9, 1.0, -4.55), lamp_e)
		_box(bus, "BusHeadR74", Vector3(0.4, 0.3, 0.1), Vector3(0.9, 1.0, -4.55), lamp_e)
		_box(bus, "BusTailL74", Vector3(0.4, 0.3, 0.1), Vector3(-0.9, 1.0, 4.55), tail_m)
		_box(bus, "BusTailR74", Vector3(0.4, 0.3, 0.1), Vector3(0.9, 1.0, 4.55), tail_m)
		# Door group on the local +x side: when the bus faces
		# east (+x world), +x local maps to world +z (south) —
		# the stops side. bus.gd slides it along local z.
		var door := Node3D.new()
		door.name = "DoorGroup74"
		door.position = Vector3(1.31, 1.5, 1.0)
		bus.add_child(door)
		_box(door, "DoorPanel74", Vector3(0.12, 1.9, 1.2), Vector3(0.0, 0.0, 0.0), bus_trim)
		bus.set("door_node", door)
		# Wheels: cylinder axis local Y, instance rotated z 90
		# degrees so the axle lies along bus local X; bus.gd
		# spins them with rotate_object_local(Y) (car pattern).
		var wpos: Array = [[-1.3, -3.0], [1.3, -3.0], [-1.3, 3.0], [1.3, 3.0]]
		for wi in range(wpos.size()):
			var w := _cyl(bus, "Wheel74_%d" % wi, 0.55, 0.55, 0.3, Vector3(wpos[wi][0], 0.55, wpos[wi][1]), tyre_m)
			w.rotation.z = PI * 0.5
			var hub := _cyl(w, "Hub74", 0.2, 0.2, 0.32, Vector3(0.0, 0.0, 0.0), hub_m)
			hub.rotation.z = 0.0
		var shape := CollisionShape3D.new()
		shape.name = "BusCollider74"
		shape.position = Vector3(0.0, 1.5, 0.0)
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(2.6, 3.0, 9.0)
		shape.shape = box_shape
		bus.add_child(shape)
		bus_ref = bus

	# Controller node (door/boarding/alighting + HUD).
	if world.get_node_or_null("BusSim74") == null:
		var ctrl := Node3D.new()
		ctrl.name = "BusSim74"
		ctrl.set_script(load("res://bus_controller74.gd"))
		world.call_deferred("add_child", ctrl)

	# Minimap dots (Slice 64 runtime-dot pattern): 4 stops +
	# the bus vehicle dot. Created before player._update_minimap
	# builds its dot list on the first frame.
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer != null:
		var panel := layer.get_node_or_null("MinimapPanel") as Control
		if panel != null:
			for di2 in range(4):
				var dname := "BusStop74_%d" % di2
				if panel.get_node_or_null(dname) == null:
					var dot := ColorRect.new()
					dot.name = dname
					dot.color = Color(0.2, 0.6, 1.0, 1.0)
					dot.size = Vector2(8.0, 8.0)
					panel.add_child(dot)
			if panel.get_node_or_null("VehicleDotBus") == null:
				var vdot := ColorRect.new()
				vdot.name = "VehicleDotBus"
				vdot.color = Color(1.0, 1.0, 1.0, 1.0)
				vdot.size = Vector2(8.0, 8.0)
				panel.add_child(vdot)
		# HUD: door button + boarded-count label (Slice 60
		# garage-button pattern). Door button sits left of the
		# Slice 61 bottom-right cluster (right edge 1044 < 1050,
		# so it cannot overlap Sprint/Jump/Vehicle/Talk).
		if layer.get_node_or_null("DoorButton74") == null:
			var dbtn := Button.new()
			dbtn.name = "DoorButton74"
			dbtn.text = "🚪 တံခါး"
			_set_rect(dbtn, 940.0, 610.0, 104.0, 104.0)
			dbtn.visible = false
			layer.add_child(dbtn)
			if bus_ref != null and bus_ref.has_method("toggle_door"):
				dbtn.pressed.connect(Callable(bus_ref, "toggle_door"))
		if layer.get_node_or_null("BoardLabel74") == null:
			var blab := Label.new()
			blab.name = "BoardLabel74"
			blab.text = "🚌 0"
			blab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_set_rect(blab, 830.0, 610.0, 104.0, 40.0)
			blab.visible = false
			layer.add_child(blab)
