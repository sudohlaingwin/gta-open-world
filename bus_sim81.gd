extends Node3D
## Slice 81 — BUS SIMULATION, part 8 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 8).
## What it builds, all runtime-only, NO scene touched:
## - SECOND BUS TYPE: a smaller minibus parked at the depot
##   beside the big bus, enterable and drivable like the big
##   bus (same bus.gd sim script, its own tuning: shorter
##   body, quicker launch, lower top speed). It carries its
##   OWN door group (toggle_door works through bus.gd) and
##   its OWN destination sign in the real Noto font — but
##   the sign text is fixed ("မီနီဘတ်စ်"): the minibus runs
##   NO scheduled route. The Slice 74 controller, the Slice
##   75 route system, the timetable, the stop request, the
##   horn and the chime all read the node literally named
##   "Bus"; they are NOT rewired here, because retargeting
##   them to two buses would break the single-bus route
##   invariants (boarded counts, in-order sequence, dues)
##   that Slices 74-79 proved. The minibus is a free-drive
##   fleet vehicle, stated plainly — not a second route bus.
##   Long-route traffic avoidance (Slice 76) likewise covers
##   the big bus only; a minibus driver must steer around
##   traffic cars themselves.
## - BUS PAINT: 4 fleet-livery presets (yellow / red / blue /
##   green) applied to BOTH bus bodies at once — one fleet,
##   one livery, stated plainly. A touch-first paint button
##   appears when the player is on foot near either bus
##   (the depot yard); each press cycles the preset, saves
##   it at once in SaveManager ("bus_paint81", settings
##   file, Slice 35 paint pattern), and repaints both bodies
##   immediately. Body colour only — no claimed textures.
## - DEPOT PARKING: the big bus already parks at (30, 16);
##   the minibus parks at (30, 26), 10 m south, same east
##   facing, so the depot reads as a bus yard at game start
##   (vehicles stay where the player leaves them after that
##   — the existing game rule, not a new claim). A depot
##   sign board in the real Noto font ("ဘတ်စ်ကားဂိုဒေါင်")
##   stands between them. Zero colliders on the sign and
##   on every minibus dressing mesh except the minibus body
##   collider itself, so nothing here blocks a road, a lane,
##   or a vehicle entry.
## - MINIBUS DOOR BUTTON: DoorButton81 sits on the exact
##   DoorButton74 rect (940, 610, 104, 104) but is visible
##   ONLY while driving the minibus, while DoorButton74 is
##   visible only while driving the big bus — same spot,
##   never co-visible, zero overlap by construction.
## Wheels are named Wheel74M_* on purpose: bus.gd _ready
## collects children whose names begin with "Wheel74", so
## the minibus wheels spin without touching bus.gd.
## No opponent code, map, names or structure is used.
## Touch-first throughout (no keys anywhere).

const MINIBUS_POS: Vector3 = Vector3(30.0, 0.0, 26.0)
const MINIBUS_ROT_Y: float = -PI * 0.5
const PAINTS: Array = [Color(0.9, 0.75, 0.15, 1.0), Color(0.8, 0.15, 0.15, 1.0), Color(0.15, 0.4, 0.8, 1.0), Color(0.15, 0.6, 0.3, 1.0)]
const PAINT_DIGITS: Array = ["၁", "၂", "၃", "၄"]
const DEPOT_SIGN_TEXT: String = "ဘတ်စ်ကားဂိုဒေါင်"
const MINI_SIGN_TEXT: String = "မီနီဘတ်စ်"

var _hud_done: bool = false
var _door_btn: Button = null
var _paint_btn: Button = null
var _paint_applied_for: int = -1


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim81") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim81"
	n.set_script(load("res://bus_sim81.gd"))
	world.call_deferred("add_child", n)
	_build_minibus(world)
	_build_depot_sign(world)
	_add_minimap_dot(world)


static func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


static func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
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


static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61/74/75/76/77/78/79/80
	# HUD controls.
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


static func _build_minibus(world: Node3D) -> void:
	if world.get_node_or_null("Minibus") != null:
		return
	var bus := CharacterBody3D.new()
	bus.name = "Minibus"
	bus.position = MINIBUS_POS
	bus.rotation.y = MINIBUS_ROT_Y
	bus.set_script(load("res://bus.gd"))
	# Own sim tuning, stated values not physics claims:
	# quicker off the line than the big bus (accel 6.5 vs
	# 5.0), lower top speed (14.0 vs 16.0), firmer brakes.
	bus.set("max_speed", 14.0)
	bus.set("accel", 6.5)
	bus.set("brake_force", 11.0)
	bus.set("turn_rate", 1.8)
	bus.set("high_speed_turn_rate", 0.7)
	bus.set("reverse_speed_ratio", 0.35)
	bus.set("coast_drag", 1.4)
	bus.set("steer_response", 5.5)
	bus.set("turn_scrub", 0.8)
	bus.set("wheel_radius", 0.5)
	world.call_deferred("add_child", bus)
	var body_m := _mat(Color(0.9, 0.75, 0.15, 1.0), 0.5)
	var trim_m := _mat(Color(0.15, 0.15, 0.2, 1.0), 0.6)
	var seat_m := _mat(Color(0.2, 0.25, 0.35, 1.0), 0.9)
	var tyre_m := _mat(Color(0.1, 0.1, 0.1, 1.0), 1.0)
	var hub_m := _mat(Color(0.7, 0.7, 0.7, 1.0), 0.4)
	var lamp_e := StandardMaterial3D.new()
	lamp_e.albedo_color = Color(1.0, 0.9, 0.6, 1.0)
	lamp_e.emission_enabled = true
	lamp_e.emission = Color(1.0, 0.9, 0.6, 1.0)
	lamp_e.emission_energy_multiplier = 1.5
	var tail_m := _mat(Color(0.9, 0.1, 0.1, 1.0), 0.5)
	# Semi-transparent glass FIRST (Slice 75 pattern), so
	# the interior seats below are actually visible.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.1, 0.2, 0.3, 0.45)
	glass.roughness = 0.1
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Body along local Z (forward = local -z, the car/bus
	# convention): 6.0 m long, 2.4 m wide, 2.6 m tall.
	_box(bus, "MiniBody81", Vector3(2.4, 2.0, 6.0), Vector3(0.0, 1.6, 0.0), body_m)
	_box(bus, "MiniSkirt81", Vector3(2.3, 0.5, 5.8), Vector3(0.0, 0.55, 0.0), trim_m)
	_box(bus, "MiniRoof81", Vector3(2.5, 0.18, 6.2), Vector3(0.0, 2.7, 0.0), trim_m)
	_box(bus, "MiniWinL81", Vector3(0.1, 0.7, 5.0), Vector3(-1.21, 2.0, 0.0), glass)
	_box(bus, "MiniWinR81", Vector3(0.1, 0.7, 5.0), Vector3(1.21, 2.0, 0.0), glass)
	_box(bus, "MiniShield81", Vector3(2.0, 0.8, 0.1), Vector3(0.0, 2.0, -3.01), glass)
	_box(bus, "MiniRear81", Vector3(2.0, 0.8, 0.1), Vector3(0.0, 2.0, 3.01), glass)
	_box(bus, "MiniHeadL81", Vector3(0.4, 0.25, 0.1), Vector3(-0.85, 0.95, -3.05), lamp_e)
	_box(bus, "MiniHeadR81", Vector3(0.4, 0.25, 0.1), Vector3(0.85, 0.95, -3.05), lamp_e)
	_box(bus, "MiniTailL81", Vector3(0.4, 0.25, 0.1), Vector3(-0.85, 0.95, 3.05), tail_m)
	_box(bus, "MiniTailR81", Vector3(0.4, 0.25, 0.1), Vector3(0.85, 0.95, 3.05), tail_m)
	# Door group on local +x side: when the minibus faces
	# east (+x world), +x local maps to world +z (south) —
	# the same stops side as the big bus door.
	var door := Node3D.new()
	door.name = "DoorGroup81"
	door.position = Vector3(1.21, 1.4, 0.5)
	bus.add_child(door)
	_box(door, "DoorPanel81", Vector3(0.12, 1.7, 1.0), Vector3(0.0, 0.0, 0.0), trim_m)
	bus.set("door_node", door)
	# Wheels: Wheel74M_* so bus.gd _ready (begins_with
	# "Wheel74") spins them without touching bus.gd.
	var wpos: Array = [[-1.2, -2.0], [1.2, -2.0], [-1.2, 2.0], [1.2, 2.0]]
	for wi in range(wpos.size()):
		var w := _cyl(bus, "Wheel74M_%d" % wi, 0.5, 0.5, 0.28, Vector3(wpos[wi][0], 0.5, wpos[wi][1]), tyre_m)
		w.rotation.z = PI * 0.5
		var hub := _cyl(w, "Hub81", 0.18, 0.18, 0.3, Vector3(0.0, 0.0, 0.0), hub_m)
		hub.rotation.z = 0.0
	# Interior: driver seat + wheel + 2 rows of 2 seats
	# (4 passenger seats), visible through the glass.
	_box(bus, "MiniDriverSeat81", Vector3(0.5, 0.15, 0.45), Vector3(0.7, 0.95, -2.2), seat_m)
	_box(bus, "MiniDriverBack81", Vector3(0.5, 0.55, 0.12), Vector3(0.7, 1.25, -1.95), seat_m)
	var col := _cyl(bus, "MiniSteerCol81", 0.05, 0.05, 0.55, Vector3(0.7, 1.35, -2.6), seat_m)
	col.rotation.x = 0.6
	var wheel := _cyl(bus, "MiniSteerWheel81", 0.26, 0.26, 0.06, Vector3(0.7, 1.5, -2.7), seat_m)
	wheel.rotation.x = PI * 0.5
	var sidx := 0
	for row_z in [-0.8, 0.8]:
		for sx in [-0.65, 0.65]:
			_box(bus, "MiniSeat81_%d" % sidx, Vector3(0.5, 0.15, 0.45), Vector3(sx, 0.95, row_z), seat_m)
			_box(bus, "MiniSeatBack81_%d" % sidx, Vector3(0.5, 0.55, 0.12), Vector3(sx, 1.25, row_z + 0.26), seat_m)
			sidx += 1
	# Destination sign on the minibus front (local -z
	# face): dark board + real Myanmar text, rotated PI
	# so the face points forward, double-sided so it also
	# reads through the transparent windshield. The text
	# is FIXED: the minibus runs no scheduled route, so
	# it must not borrow the route's next-stop text.
	var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
	_box(bus, "MiniDestBoard81", Vector3(2.0, 0.55, 0.08), Vector3(0.0, 2.55, -3.08), board_m)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	if font == null:
		push_error("BusSim81: Myanmar font failed to load, minibus sign skipped")
	else:
		var lab := Label3D.new()
		lab.name = "MiniSign81"
		lab.text = MINI_SIGN_TEXT
		lab.font = font
		lab.font_size = 40
		lab.pixel_size = 0.012
		lab.position = Vector3(0.0, 2.55, -3.13)
		lab.rotation.y = PI
		lab.double_sided = true
		bus.add_child(lab)
	var shape := CollisionShape3D.new()
	shape.name = "MiniCollider81"
	shape.position = Vector3(0.0, 1.4, 0.0)
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.4, 2.6, 6.0)
	shape.shape = box_shape
	bus.add_child(shape)


static func _build_depot_sign(world: Node3D) -> void:
	if world.get_node_or_null("DepotSign81") != null:
		return
	var g := Node3D.new()
	g.name = "DepotSign81"
	g.position = Vector3(30.0, 0.0, 21.0)
	world.call_deferred("add_child", g)
	var post_m := _mat(Color(0.4, 0.4, 0.42, 1.0), 0.6)
	var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
	_cyl(g, "DepotPost81", 0.1, 0.1, 2.0, Vector3(0.0, 1.0, 0.0), post_m)
	_box(g, "DepotBoard81", Vector3(4.0, 1.0, 0.12), Vector3(0.0, 2.2, 0.0), board_m)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	if font == null:
		push_error("BusSim81: Myanmar font failed to load, depot sign skipped")
	else:
		var lab := Label3D.new()
		lab.name = "DepotLabel81"
		lab.text = DEPOT_SIGN_TEXT
		lab.font = font
		lab.font_size = 32
		lab.pixel_size = 0.012
		lab.position = Vector3(0.0, 2.2, -0.08)
		lab.rotation.y = PI
		lab.double_sided = true
		g.add_child(lab)


static func _add_minimap_dot(world: Node3D) -> void:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return
	var panel := layer.get_node_or_null("MinimapPanel") as Control
	if panel == null:
		return
	if panel.get_node_or_null("VehicleDotMinibus") == null:
		var dot := ColorRect.new()
		dot.name = "VehicleDotMinibus"
		dot.color = Color(0.7, 1.0, 0.7, 1.0)
		dot.size = Vector2(8.0, 8.0)
		panel.add_child(dot)


func _paint_index() -> int:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or sm.get("bus_paint81") == null:
		return 0
	return clampi(int(sm.get("bus_paint81")), 0, PAINTS.size() - 1)


func _body_mat(world: Node3D, bus_name: String, body_name: String) -> StandardMaterial3D:
	var bus := world.get_node_or_null(bus_name) as Node3D
	if bus == null:
		return null
	var mi := bus.get_node_or_null(body_name) as MeshInstance3D
	if mi == null:
		return null
	return mi.get_surface_override_material(0) as StandardMaterial3D


func _apply_paint(world: Node3D) -> void:
	var idx := _paint_index()
	var col: Color = PAINTS[idx]
	var big := _body_mat(world, "Bus", "BusBody74")
	if big != null:
		big.albedo_color = col
	var mini := _body_mat(world, "Minibus", "MiniBody81")
	if mini != null:
		mini.albedo_color = col
	_paint_applied_for = idx


func _try_hud(world: Node3D) -> bool:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return false
	var mini := world.get_node_or_null("Minibus") as Node3D
	if layer.get_node_or_null("DoorButton81") == null:
		var dbtn := Button.new()
		dbtn.name = "DoorButton81"
		dbtn.text = "🚪 တံခါး"
		_set_rect(dbtn, 940.0, 610.0, 104.0, 104.0)
		dbtn.visible = false
		layer.add_child(dbtn)
		_door_btn = dbtn
		if mini != null and mini.has_method("toggle_door"):
			dbtn.pressed.connect(Callable(mini, "toggle_door"))
	else:
		_door_btn = layer.get_node_or_null("DoorButton81") as Button
	if layer.get_node_or_null("PaintButton81") == null:
		var pbtn := Button.new()
		pbtn.name = "PaintButton81"
		pbtn.text = "🎨 ဆေး ၁"
		_set_rect(pbtn, 940.0, 610.0, 104.0, 104.0)
		pbtn.visible = false
		pbtn.pressed.connect(_on_paint_pressed)
		layer.add_child(pbtn)
		_paint_btn = pbtn
	else:
		_paint_btn = layer.get_node_or_null("PaintButton81") as Button
	_add_minimap_dot(world)
	return true


func _on_paint_pressed() -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or sm.get("bus_paint81") == null:
		return
	var idx := (int(sm.get("bus_paint81")) + 1) % PAINTS.size()
	sm.set("bus_paint81", idx)
	if sm.has_method("save_settings"):
		sm.call("save_settings")
	_apply_paint(world)
	if _paint_btn != null:
		_paint_btn.text = "🎨 ဆေး " + PAINT_DIGITS[idx]


func _physics_process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _hud_done:
		_hud_done = _try_hud(world)
	var mini := world.get_node_or_null("Minibus") as Node3D
	var big := world.get_node_or_null("Bus") as Node3D
	var player := world.get_node_or_null("Player") as Node3D
	# Fleet paint: apply once the buses exist, and again
	# whenever the saved preset changes (button press or
	# a settings load). Bodies never despawn, so a
	# mismatch check is enough — no per-frame recolour.
	if big != null and mini != null and _paint_index() != _paint_applied_for:
		_apply_paint(world)
	var driving_mini := false
	if mini != null and player != null:
		driving_mini = bool(player.get("driving")) and player.get("driving_vehicle") == mini
	if _door_btn != null:
		_door_btn.visible = driving_mini
	# Paint button: on foot, near either bus (the depot
	# yard). It shares the door-button rect, but the two
	# are never visible together: the door button needs
	# driving, the paint button needs on-foot.
	var near_depot := false
	if player != null and not bool(player.get("driving")):
		var pp: Vector3 = (player as Node3D).global_position
		if big != null and pp.distance_to((big as Node3D).global_position) <= 15.0:
			near_depot = true
		if mini != null and pp.distance_to((mini as Node3D).global_position) <= 15.0:
			near_depot = true
	if _paint_btn != null:
		_paint_btn.visible = near_depot
		if near_depot:
			_paint_btn.text = "🎨 ဆေး " + PAINT_DIGITS[_paint_index()]
