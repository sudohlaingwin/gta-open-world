extends Node3D
## Slice 76 — BUS SIMULATION, part 3 (owner simulation
## direction 2026-10-23 11:31 + bus choice 11:32, part 3).
## What it builds, all runtime-only, NO scene touched:
## - LONG-ROUTE TRAFFIC: 4 traffic cars (the Slice 22
##   traffic_car.tscn, same stop-only drive() as the
##   village fleet) looping the Slice 74 long road in
##   both directions (eastbound lane z -3, westbound
##   lane z +3, x 600..2400), so the road no longer
##   feels empty. Slice 83 adds two more cars (6 total)
##   parked at the depot by default, unparked by the
##   Slice 83 time band (peak 6 / off-peak 4 / night 2
##   on the road). Obstacles include the bus as THREE
##   points (centre + front + rear, 4.5 m each way, the
##   bus is 9 m long): the Slice 22 stop distance is
##   tuned for car/van lengths, so a bare bus-centre
##   obstacle would let a follower's nose overlap the
##   bus rear — the front/rear points stop it clear.
##   A car blocked > 30 s is respawned at the route
##   waypoint farthest from the bus (manager pattern:
##   a parked bus must never jam the road forever).
##   Speed/headlights follow the same daylight bands
##   as Slice 22 (1.0 / 0.85 / 0.7, dark < 0.15).
## - INTERSECTION STOPS: a painted stop line + a stop
##   sign (real Noto font, "ရပ်" — no emoji, Noto has
##   no emoji glyphs, Slice 71 finding) at the S-bend
##   junction (x 1500, where the Slice 75 loop leaves
##   the main road) and the hamlet spur junction
##   (x 2100). A touch-friendly prompt label (no key,
##   no button to miss) appears while the bus
##   approaches an uncleared junction; a full stop
##   (speed < 0.5 m/s inside 12 m) marks it cleared
##   until the bus drives 60 m away, when it resets.
##   NO fine, NO money, NO blocking: the prompt is
##   guidance, the detection is the record — a missed
##   stop is simply never marked cleared, stated
##   plainly, not enforced with a fake penalty.
## - NIGHT + RAIN BUS OPERATION: two real SpotLight3D
##   headlights on the bus front (visible only when
##   daylight < 0.15, the Slice 57 night rule), an
##   interior OmniLight at night, and two wiper blades
##   on the windshield that sweep ONLY in the rainy
##   season (season62 == 1) and sit still otherwise.
##   The wipers are visual only — they do not clear
##   rain, and no rain-clearing is claimed.
## - PASSENGER FEEDBACK: a brief "✓" confirmation line
##   when a stop is served (boarded/alighted deltas
##   read from the Slice 74 controller's own totals,
##   so no count is invented) and when a junction
##   full stop is recorded. It shows 3.5 s, then hides.
## No new quest, signboard system, economy, or feature
## outside the bus-simulation scope. No opponent code,
## map, names or structure is used. Touch-first
## throughout (no keys anywhere in this slice).
## State is session-only (junction cleared flags,
## traffic positions): nothing new is saved, so no
## save key is added and no old save can break.

const LONG_ROUTE: Array = [
	Vector2(600.0, -3.0), Vector2(2400.0, -3.0),
	Vector2(2400.0, 3.0), Vector2(600.0, 3.0),
]
const JUNCTION_X: Array = [1500.0, 2100.0]
const JUNC_STOP_R: float = 12.0
const JUNC_PROMPT_R: float = 45.0
const JUNC_RESET_R: float = 60.0
const FULL_STOP_SPEED: float = 0.5
const STUCK_RESPAWN_S: float = 30.0
const FEEDBACK_S: float = 3.5
const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0, 500.0, 2400.0]
const MY_DIGITS: Array = ["၁", "၂", "၃", "၄", "၅", "၆"]
# Slice 83 depot park spots, one per car that can ever
# park (night parks 1, 3, 4, 5 — four cars, four spots).
# All sit inside the Slice 82 fence lines, clear of both
# depot buses (30,16 / 30,26), the office (30,6), the
# fuel pump (40,32) and both depot lamps (22,10 / 38,30).
# Parked cars are visual only here (the loop below skips
# them entirely, so a parked car never drives, never
# counts as stuck, and never blocks).
const PARK83: Array = [
	Vector3(22.0, 0.0, 20.0), Vector3(38.0, 0.0, 20.0),
	Vector3(22.0, 0.0, 30.0), Vector3(38.0, 0.0, 10.0),
]

var traffic_cars: Array = []
var junction_cleared: Array = [false, false]
var prompt_label: Label = null
var feedback_label: Label = null
var _bus_done: bool = false
var _hud_done: bool = false
var _spot_l: SpotLight3D = null
var _spot_r: SpotLight3D = null
var _interior_light: OmniLight3D = null
var _wiper_l: Node3D = null
var _wiper_r: Node3D = null
var _last_night: bool = false
var _last_rainy: bool = false
var _last_boarded_total: int = -1
var _last_alighted_total: int = -1
var _feedback_timer: float = 0.0
var _wiper_phase: float = 0.0


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim76") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim76"
	n.set_script(load("res://bus_sim76.gd"))
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


static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61/74/75 HUD controls.
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


func _daylight() -> float:
	var world := get_parent() as Node3D
	if world == null:
		return 1.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		return float(dn.call("daylight"))
	return 1.0


func _is_rainy() -> bool:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or sm.get("season62") == null:
		return false
	return int(sm.get("season62")) == 1


func _speed_factor_for_day(day: float) -> float:
	if day >= 0.6:
		return 1.0
	if day >= 0.15:
		return 0.85
	return 0.7


func _build_junctions(world: Node3D) -> void:
	var grp := Node3D.new()
	grp.name = "Junctions76"
	add_child(grp)
	var line_m := _mat(Color(0.9, 0.9, 0.85, 1.0), 0.8)
	var post_m := _mat(Color(0.4, 0.4, 0.42, 1.0), 0.6)
	var board_m := _mat(Color(0.7, 0.1, 0.1, 1.0), 0.8)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	for ji in range(JUNCTION_X.size()):
		var jx: float = JUNCTION_X[ji]
		var g := Node3D.new()
		g.name = "Junction76_%d" % ji
		g.position = Vector3(jx, 0.0, 0.0)
		grp.add_child(g)
		# Painted stop line across the 12 m slab.
		_box(g, "StopLine76", Vector3(1.0, 0.03, 11.0), Vector3(0.0, 0.13, 0.0), line_m)
		# Sign post + board on the south side (z 8.5, clear
		# of slab + curbs, Slice 74 stop-sign pattern).
		_cyl(g, "SignPost76", 0.1, 0.1, 2.0, Vector3(0.0, 1.0, 8.5), post_m)
		_box(g, "SignBoard76", Vector3(2.5, 0.8, 0.12), Vector3(0.0, 2.2, 8.5), board_m)
		if font != null:
			var lab := Label3D.new()
			lab.name = "SignLabel76"
			lab.text = "ရပ်"
			lab.font = font
			lab.font_size = 48
			lab.pixel_size = 0.012
			lab.position = Vector3(0.0, 2.2, 8.42)
			lab.rotation.y = PI
			lab.double_sided = true
			g.add_child(lab)
		else:
			push_error("BusSim76: Myanmar font failed to load, junction sign skipped")


func _spawn_traffic() -> void:
	var car_scene := load("res://scenes/traffic_car.tscn") as PackedScene
	if car_scene == null:
		push_error("BusSim76: traffic_car.tscn failed to load")
		return
	# Spawn table: [x, z, next waypoint index]. Two cars per
	# direction, spread along the road so no two share a
	# spawn point (Slice 22 lesson: shared spawns jam).
	# Slice 83 adds two more cars (indices 4, 5), one per
	# direction, parked at the depot by default so the
	# pre-83 road still runs 4 cars until the Slice 83 band
	# logic unparks them at peak (or at night, parks more).
	var spawns: Array = [
		[900.0, -3.0, 1], [1800.0, -3.0, 1],
		[1500.0, 3.0, 3], [2100.0, 3.0, 3],
		[600.0, -3.0, 1], [2400.0, 3.0, 3],
	]
	var colors: Array = [
		Color(0.8, 0.2, 0.2, 1), Color(0.2, 0.4, 0.8, 1),
		Color(0.9, 0.85, 0.2, 1), Color(0.25, 0.7, 0.3, 1),
		Color(0.55, 0.2, 0.7, 1), Color(0.9, 0.5, 0.15, 1),
	]
	var day := _daylight()
	for ci in range(spawns.size()):
		var car := car_scene.instantiate() as Node3D
		car.name = "LongTraffic76_%d" % ci
		car.set("body_color", colors[ci])
		car.set("route", LONG_ROUTE)
		add_child(car)
		var sx: float = spawns[ci][0]
		var sz: float = spawns[ci][1]
		car.global_position = Vector3(sx, 0.0, sz)
		var nxt: Vector2 = LONG_ROUTE[int(spawns[ci][2])]
		var dir := nxt - Vector2(sx, sz)
		car.rotation.y = atan2(dir.x, dir.y)
		car.set("waypoint_index", int(spawns[ci][2]))
		car.set("speed", 0.0)
		car.set("speed_factor", _speed_factor_for_day(day))
		traffic_cars.append(car)
		# Slice 83: the two extra cars start parked at the
		# depot (the pre-83 road baseline of 4 driving cars
		# is preserved until the band logic unparks them).
		if ci >= 4:
			park_car83(ci)


func _respawn_car(car: Node3D, bus_pos: Vector3, slot_idx: int = -1) -> void:
	# Farthest route waypoint from the bus (manager
	# pattern, widened: the long road has no 25-45 m
	# band rule, distance alone is the criterion).
	# Slice 135: NEVER land on the waypoint itself. The old code put
	# every respawned/unparked car on the single farthest waypoint,
	# so cars unparked together (night->peak unparks 4) stacked at
	# identical coordinates and blocked each other forever: each
	# sees the other inside its stop radius, and the 30 s respawn
	# then re-stacked them on the same point (probe135c: 2 cars at
	# (2400,-3) for 39 s straight incl. a stuck-reset that changed
	# nothing, 4 after a peak transition). The manager's own
	# _pick_spawn_index comment states this exact failure mode for
	# shared spawn waypoints; the long-road respawn lacked the
	# equivalent guard. The car now lands 10*(slot_idx+1) m BACK
	# along the route path from the farthest waypoint (walking
	# backward around corners, so it always stays ON the road) and
	# targets that waypoint, so simultaneously respawned cars form
	# a spaced queue on the lane instead of a stack. Unknown slot
	# lands 10 m back, never 0.
	var best := 0
	var best_d := -1.0
	for wi in range(LONG_ROUTE.size()):
		var wp: Vector2 = LONG_ROUTE[wi]
		var d := Vector2(bus_pos.x - wp.x, bus_pos.z - wp.y).length()
		if d > best_d:
			best_d = d
			best = wi
	var back: float = 10.0 * float(slot_idx + 1) if slot_idx >= 0 else 10.0
	var wp0: Vector2 = LONG_ROUTE[best]
	var pos: Vector2 = wp0
	var remaining: float = back
	var i: int = best
	var guard: int = 0
	while remaining > 0.0 and guard < 8:
		guard += 1
		var prev: int = (i - 1 + LONG_ROUTE.size()) % LONG_ROUTE.size()
		var seg: float = LONG_ROUTE[i].distance_to(LONG_ROUTE[prev])
		if seg <= 0.0:
			break
		if remaining <= seg:
			pos = LONG_ROUTE[i].lerp(LONG_ROUTE[prev], remaining / seg)
			break
		remaining -= seg
		i = prev
	car.global_position = Vector3(pos.x, 0.0, pos.y)
	var dir: Vector2 = wp0 - pos
	if dir.length() > 0.001:
		car.rotation.y = atan2(dir.x, dir.y)
	else:
		var wp1: Vector2 = LONG_ROUTE[(best + 1) % LONG_ROUTE.size()]
		var d1: Vector2 = wp1 - wp0
		car.rotation.y = atan2(d1.x, d1.y)
	car.set("waypoint_index", best)
	car.set("speed", 0.0)
	car.set("stuck_time", 0.0)


func park_car83(idx: int) -> void:
	# Slice 83: park one fleet car at the depot. The meta
	# flag is what the loop skips on and what BusSim83
	# reads; headlights go off so a parked car never
	# glows at night like a driving one.
	if idx < 0 or idx >= traffic_cars.size():
		return
	var car := traffic_cars[idx] as Node3D
	if car == null:
		return
	car.set_meta("parked83", true)
	# One spot per parked car, never shared: 1 -> 0,
	# 3 -> 1, 4 -> 2, 5 -> 3 (any other index -> 0).
	var spot := 0
	match idx:
		1:
			spot = 0
		3:
			spot = 1
		4:
			spot = 2
		5:
			spot = 3
	car.global_position = PARK83[spot]
	car.rotation.y = PI / 2.0
	car.set("speed", 0.0)
	car.call("set_headlights", false)


func unpark_car83(idx: int, bus_pos: Vector3) -> void:
	# Slice 83: return a parked car to the road via the
	# same farthest-waypoint respawn as a stuck car, so
	# it rejoins traffic instead of popping onto the road
	# at the depot (where it would have to drive cross-
	# country to reach the long road).
	if idx < 0 or idx >= traffic_cars.size():
		return
	var car := traffic_cars[idx] as Node3D
	if car == null:
		return
	car.set_meta("parked83", false)
	_respawn_car(car, bus_pos, idx)


func road_count83() -> int:
	# Slice 83: driving cars on the road right now
	# (parked depot cars excluded). Used by SIM83 and by
	# any later HUD that wants the live fleet count.
	var n := 0
	for car in traffic_cars:
		if car != null and not bool((car as Node3D).get_meta("parked83", false)):
			n += 1
	return n


func _try_hud(world: Node3D) -> bool:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return false
	# Rects sit left of the Slice 61 bottom-right cluster
	# (x >= 1050) and clear of RouteLabel75 (720,560),
	# BoardLabel74 (830,610) and DoorButton74 (940,610):
	# prompt (720,500) and feedback (720,450) touch none.
	if layer.get_node_or_null("StopPrompt76") == null:
		var pl := Label.new()
		pl.name = "StopPrompt76"
		pl.text = "လမ်းဆုံ ရှေ့မှာ ရပ်ပါ"
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		_set_rect(pl, 720.0, 500.0, 214.0, 40.0)
		pl.visible = false
		layer.add_child(pl)
		prompt_label = pl
	if layer.get_node_or_null("StopFeedback76") == null:
		var fl := Label.new()
		fl.name = "StopFeedback76"
		fl.text = ""
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
		_set_rect(fl, 720.0, 450.0, 214.0, 40.0)
		fl.visible = false
		layer.add_child(fl)
		feedback_label = fl
	return true


func _try_bus_parts(world: Node3D) -> bool:
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus == null:
		return false
	# Two real spotlights on the bus front (local -z is
	# forward, and SpotLight3D shines along local -z, so
	# no rotation is needed). Visible only at night.
	for side in [-1.0, 1.0]:
		var sp := SpotLight3D.new()
		sp.name = "BusSpot76_L" if side < 0.0 else "BusSpot76_R"
		sp.position = Vector3(0.9 * side, 1.0, -4.55)
		sp.spot_angle = 35.0
		sp.spot_range = 35.0
		sp.light_energy = 2.5
		sp.light_color = Color(1.0, 0.9, 0.7, 1.0)
		sp.visible = false
		bus.add_child(sp)
		if side < 0.0:
			_spot_l = sp
		else:
			_spot_r = sp
	# Interior light: warm glow for the Slice 75 seats.
	var omni := OmniLight3D.new()
	omni.name = "BusInteriorLight76"
	omni.position = Vector3(0.0, 2.3, 0.0)
	omni.omni_range = 7.0
	omni.light_energy = 0.9
	omni.light_color = Color(1.0, 0.85, 0.6, 1.0)
	omni.visible = false
	bus.add_child(omni)
	_interior_light = omni
	# Wiper blades on the windshield face (shield front is
	# local z -4.56, so -4.58 sits just in front of it).
	# Each blade pivots at its inner end and sweeps in
	# the windshield plane (rotation around local z).
	var blade_m := _mat(Color(0.1, 0.1, 0.1, 1.0), 0.9)
	for side in [-1.0, 1.0]:
		var g := Node3D.new()
		g.name = "Wiper76_L" if side < 0.0 else "Wiper76_R"
		g.position = Vector3(0.15 * side, 1.75, -4.58)
		bus.add_child(g)
		_box(g, "WiperBlade76", Vector3(0.55, 0.06, 0.03), Vector3(0.28 * side, 0.0, 0.0), blade_m)
		g.visible = false
		if side < 0.0:
			_wiper_l = g
		else:
			_wiper_r = g
	# Apply gating IMMEDIATELY (SIM76 caught this): the
	# world starts at DayNight time 0, i.e. daylight 0,
	# i.e. night — leaving the lights at visible=false
	# until the first day/night transition would mean a
	# night start with a dark bus. The _physics_process
	# change-detection below only re-applies on change.
	_last_night = _daylight() < 0.15
	_last_rainy = _is_rainy()
	if _spot_l != null:
		_spot_l.visible = _last_night
	if _spot_r != null:
		_spot_r.visible = _last_night
	if _interior_light != null:
		_interior_light.visible = _last_night
	if _wiper_l != null:
		_wiper_l.visible = _last_rainy
	if _wiper_r != null:
		_wiper_r.visible = _last_rainy
	return true


func _show_feedback(text: String) -> void:
	if feedback_label != null:
		feedback_label.text = text
		feedback_label.visible = true
	_feedback_timer = FEEDBACK_S


func _ready() -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	_build_junctions(world)
	_spawn_traffic()
	_hud_done = _try_hud(world)
	_bus_done = _try_bus_parts(world)
	_last_night = _daylight() < 0.15
	_last_rainy = _is_rainy()


func _physics_process(delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _hud_done:
		_hud_done = _try_hud(world)
	if not _bus_done:
		_bus_done = _try_bus_parts(world)
	var bus := world.get_node_or_null("Bus") as Node3D
	var player := world.get_node_or_null("Player") as Node3D
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	var driving_bus := false
	if bus != null and player != null:
		driving_bus = bool(player.get("driving")) and player.get("driving_vehicle") == bus
	# --- Traffic on the long road (manager pattern, but
	# the bus counts as three obstacle points, see header).
	var day := _daylight()
	var dark := day < 0.15
	var sf := _speed_factor_for_day(day)
	var bus_pos := Vector3.INF
	var bus_fwd := Vector3.ZERO
	if bus != null:
		bus_pos = bus.global_position
		bus_fwd = Vector3(-sin(bus.rotation.y), 0.0, -cos(bus.rotation.y))
	for car in traffic_cars:
		if car == null:
			continue
		# Slice 83: parked depot cars never drive, never
		# count as stuck, and never get headlight/speed
		# updates — they sit until BusSim83 unparks them.
		if bool((car as Node3D).get_meta("parked83", false)):
			continue
		var obs: Array = []
		if player != null:
			obs.append(player.global_position)
		if bus_pos != Vector3.INF:
			obs.append(bus_pos)
			obs.append(bus_pos + bus_fwd * 4.5)
			obs.append(bus_pos - bus_fwd * 4.5)
		# Slice 154: other long-route cars are traffic obstacles
		# (forward cone only) — same split as TrafficManager, so a
		# follower behind a leader can never freeze the leader.
		# Player + bus points stay non-traffic (any-side, unchanged).
		var traffic_obs: Array = []
		for other in traffic_cars:
			if other != null and other != car:
				traffic_obs.append((other as Node3D).global_position)
		car.set("speed_factor", sf)
		car.call("set_headlights", dark)
		var stuck: float = float(car.get("stuck_time"))
		if stuck > STUCK_RESPAWN_S and bus_pos != Vector3.INF:
			_respawn_car(car, bus_pos, traffic_cars.find(car))
			continue
		car.call("drive", delta, obs, traffic_obs)
	# --- Night / rain gating, applied only on change
	# (same pattern as Slice 72 rain puddles).
	var night := day < 0.15
	var rainy := _is_rainy()
	if night != _last_night:
		_last_night = night
		if _spot_l != null:
			_spot_l.visible = night
		if _spot_r != null:
			_spot_r.visible = night
		if _interior_light != null:
			_interior_light.visible = night
	if rainy != _last_rainy:
		_last_rainy = rainy
		if _wiper_l != null:
			_wiper_l.visible = rainy
		if _wiper_r != null:
			_wiper_r.visible = rainy
	if rainy:
		_wiper_phase += delta * 5.0
		var ang := sin(_wiper_phase) * 0.45
		if _wiper_l != null:
			_wiper_l.rotation.z = ang
		if _wiper_r != null:
			_wiper_r.rotation.z = -ang
	# --- Junction full-stop detection + prompt.
	if not driving_bus:
		if prompt_label != null:
			prompt_label.visible = false
		if ctrl != null:
			_last_boarded_total = int(ctrl.get("boarded_total"))
			_last_alighted_total = int(ctrl.get("alighted_total"))
		if _feedback_timer > 0.0:
			_feedback_timer -= delta
			if _feedback_timer <= 0.0 and feedback_label != null:
				feedback_label.visible = false
		return
	var bus_speed := 0.0
	if bus.get("speed") != null:
		bus_speed = absf(float(bus.get("speed")))
	var bp := bus.global_position
	var nearest_open := -1
	var nearest_open_d := JUNC_PROMPT_R
	for ji in range(JUNCTION_X.size()):
		var d := Vector2(bp.x - JUNCTION_X[ji], bp.z - 0.0).length()
		if d > JUNC_RESET_R:
			junction_cleared[ji] = false
		elif d < JUNC_STOP_R and bus_speed < FULL_STOP_SPEED and not junction_cleared[ji]:
			junction_cleared[ji] = true
			_show_feedback("✓ လမ်းဆုံမှာ ရပ်ပြီးပြီ")
		if not junction_cleared[ji] and d < nearest_open_d:
			nearest_open_d = d
			nearest_open = ji
	if prompt_label != null:
		prompt_label.visible = nearest_open >= 0
	# --- Passenger feedback: totals deltas from the
	# Slice 74 controller, never invented here.
	if ctrl != null:
		var bt := int(ctrl.get("boarded_total"))
		var at := int(ctrl.get("alighted_total"))
		if _last_boarded_total >= 0 and (bt != _last_boarded_total or at != _last_alighted_total):
			var db := bt - _last_boarded_total
			var da := at - _last_alighted_total
			var stop_idx := -1
			var stop_d := 25.0
			for si in range(STOPS_X.size()):
				var dd := Vector2(bp.x - STOPS_X[si], bp.z - 0.0).length()
				if dd < stop_d:
					stop_d = dd
					stop_idx = si
			if stop_idx >= 0:
				# Digit is the travel position (Slice 84),
				# never the group index: group 4 shows ၁.
				var digit := ""
				if ctrl.has_method("pos_digit79"):
					digit = str(ctrl.call("pos_digit79", stop_idx, int(ctrl.get("direction"))))
				if digit == "":
					digit = str(MY_DIGITS[clampi(stop_idx, 0, 5)])
				_show_feedback("✓ မှတ်တိုင် %s: တက် +%d · ဆင်း +%d" % [digit, db, da])
			else:
				_show_feedback("✓ ခရီးသည် တက် +%d · ဆင်း +%d" % [db, da])
		_last_boarded_total = bt
		_last_alighted_total = at
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0 and feedback_label != null:
			feedback_label.visible = false
