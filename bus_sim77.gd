extends Node3D
## Slice 77 — BUS SIMULATION, part 4 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 4).
## What it builds, all runtime-only, NO scene touched:
## - TIMETABLE: the bus service runs on a service clock that
##   advances while the player drives the bus. A leg (eastbound
##   0 -> 3, then westbound 3 -> 0) starts when the Slice 75
##   route controller flips to a leg start; each stop is due
##   LEG_S (60 s) after the previous stop on the same leg, so
##   the board at every stop lists 0 / 1 / 2 / 3 minutes from
##   leg start (Myanmar digits only: the Noto font has no
##   '+' or ':' glyphs, verified live — those characters
##   would render as boxes, so the board avoids them).
##   service clock plus the countdown to the next stop's due
##   time (or how late it already is). When a stop is served
##   (same rule as the Slice 74 controller: door rising edge,
##   speed under 0.5 m/s, inside the 9 m stop zone), the
##   feedback label says on-time (within ON_TIME_S of due),
##   late by, or early by — feedback only, NO money, NO
##   fines, NO invented penalty, stated plainly.
##   The timetable runs on SERVICE time (seconds driven),
##   NOT the 120-second day/night clock: a day-clock
##   timetable would tick a departure every few seconds
##   and be unreadable, so that is deliberately not done.
## - STOP UPGRADES: every one of the 4 Slice 74 stops gets
##   a bench (seat + back + legs) behind the shelter, painted
##   waiting-area markings on the ground, a timetable board
##   (real Noto font, same Slice 69 font — never the default
##   font, which has no Myanmar glyphs), and a lamp post
##   with a real OmniLight3D for night service.
## - WEATHER + DAY BUS OPERATION: stop lamps are visible
##   ONLY when daylight < 0.15 (the Slice 57 night rule),
##   applied immediately at build (Slice 76 lesson: gating
##   only on change leaves a world that starts at night
##   dark) and on every daylight change after. Rain
##   braking lives in bus.gd: brake force x 0.8 in the
##   rainy season (season62 == 1) — a stated tuning value,
##   not a physics claim; dry braking is unchanged.
## State is session-only (service clock, leg epoch, feedback):
## nothing new is saved, so no save key is added and no old
## save can break. No opponent code, map, names or structure
## is used. Touch-first throughout (no keys anywhere).

const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0]
const STOP_ZONE_R: float = 9.0
const STOP_SPEED: float = 0.5
const LEG_S: float = 60.0
const ON_TIME_S: float = 15.0
const FEEDBACK_S: float = 5.0
const MY_DIGITS: Array = ["၁", "၂", "၃", "၄"]
const BOARD_TEXT: String = "ဘတ်စ်ဇယား\nမှတ်တိုင် ၁ ၀ မိနစ်\nမှတ်တိုင် ၂ ၁ မိနစ်\nမှတ်တိုင် ၃ ၂ မိနစ်\nမှတ်တိုင် ၄ ၃ မိနစ်"

var _stops_done: bool = false
var _hud_done: bool = false
var _stop_lamps: Array = []
var _last_night: bool = false
var _service_t: float = 0.0
var _epoch: float = 0.0
var _leg_key: String = ""
var _observed: bool = false
var _prev_door_open: bool = false
var _feedback_timer: float = 0.0
var _timetable_label: Label = null
var _feedback_label: Label = null


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim77") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim77"
	n.set_script(load("res://bus_sim77.gd"))
	world.call_deferred("add_child", n)


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
	# Same anchor pattern as Slice 61/74/75/76 HUD controls.
	# Timetable (720,655,214,40): below RouteLabel75
	# (720,560,214,40) and BoardLabel74 (830,610,104,40),
	# left of DoorButton74 (x 940+), so it overlaps none.
	# Feedback (720,605,104,40): under RouteLabel75's left
	# part, above the timetable label, left of BoardLabel74.
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


func _fmt_mmss(t: float) -> String:
	var total := int(maxf(0.0, t))
	return "%d:%02d" % [total / 60, total % 60]


func _due_for(stop_idx: int, direction: int) -> float:
	# Eastbound leg: stop k due k legs after leg start.
	# Westbound leg: stop k due (3 - k) legs after leg start.
	if direction == 0:
		return _epoch + float(stop_idx) * LEG_S
	return _epoch + float(3 - stop_idx) * LEG_S


func _try_stops(world: Node3D) -> bool:
	# All 4 stop groups must exist first (Slice 74 dress runs
	# before this node, but deferred order is retried anyway).
	for si in range(4):
		if world.get_node_or_null("LongRoute74/BusStop74_%d" % si) == null:
			return false
	var wood := _mat(Color(0.45, 0.30, 0.15, 1.0), 0.9)
	var post_m := _mat(Color(0.4, 0.4, 0.42, 1.0), 0.6)
	var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
	var mark_m := _mat(Color(0.95, 0.85, 0.2, 1.0), 0.8)
	var lamp_m := _mat(Color(1.0, 0.85, 0.5, 1.0), 0.5)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	var night := _daylight() < 0.15
	for si in range(4):
		var grp := world.get_node_or_null("LongRoute74/BusStop74_%d" % si) as Node3D
		if grp.get_node_or_null("Upgrades77") != null:
			continue
		var up := Node3D.new()
		up.name = "Upgrades77"
		grp.add_child(up)
		# Bench behind the shelter (shelter roof spans
		# z 9..12 at z 10.5; bench sits at z 12.5, clear of
		# the waiting passengers standing at z 10.5).
		_box(up, "BenchSeat77", Vector3(2.4, 0.12, 0.6), Vector3(0.0, 0.55, 12.5), wood)
		_box(up, "BenchBack77", Vector3(2.4, 0.7, 0.12), Vector3(0.0, 0.95, 12.8), wood)
		_box(up, "BenchLeg77A", Vector3(0.12, 0.55, 0.5), Vector3(-1.0, 0.275, 12.5), wood)
		_box(up, "BenchLeg77B", Vector3(0.12, 0.55, 0.5), Vector3(1.0, 0.275, 12.5), wood)
		# Waiting-area markings: painted rectangle x +-4,
		# z 9..13, drawn 0.01 m above the Slice 74 zone top
		# (zone top y 0.15; strips span y 0.16..0.18, so they
		# touch nothing and never z-fight).
		_box(up, "MarkN77", Vector3(8.0, 0.02, 0.25), Vector3(0.0, 0.17, 9.0), mark_m)
		_box(up, "MarkS77", Vector3(8.0, 0.02, 0.25), Vector3(0.0, 0.17, 13.0), mark_m)
		_box(up, "MarkW77", Vector3(0.25, 0.02, 4.0), Vector3(-4.0, 0.17, 11.0), mark_m)
		_box(up, "MarkE77", Vector3(0.25, 0.02, 4.0), Vector3(4.0, 0.17, 11.0), mark_m)
		# Timetable board on the shelter's east side (roof
		# spans x +-3.5, so x 5.0 is clear of it). The label
		# faces the road (-z, rotation PI, double-sided),
		# same pattern as the Slice 74 stop sign.
		_cyl(up, "BoardPost77", 0.09, 0.09, 1.6, Vector3(5.0, 0.8, 10.5), post_m)
		_box(up, "Board77", Vector3(2.4, 1.5, 0.1), Vector3(5.0, 1.9, 10.5), board_m)
		if font != null:
			var lab := Label3D.new()
			lab.name = "BoardLabel77"
			lab.text = BOARD_TEXT
			lab.font = font
			lab.font_size = 24
			lab.pixel_size = 0.012
			lab.position = Vector3(5.0, 1.9, 10.42)
			lab.rotation.y = PI
			lab.double_sided = true
			up.add_child(lab)
		else:
			push_error("BusSim77: Myanmar font failed to load, timetable board skipped")
		# Stop lamp for night service: post + head + a real
		# OmniLight3D, gated by the Slice 57 night rule and
		# applied immediately (never only on change).
		_cyl(up, "LampPost77", 0.09, 0.09, 2.6, Vector3(-5.0, 1.3, 10.5), post_m)
		_box(up, "LampHead77", Vector3(0.4, 0.25, 0.4), Vector3(-5.0, 2.7, 10.5), lamp_m)
		var lamp := OmniLight3D.new()
		lamp.name = "LampLight77"
		lamp.position = Vector3(-5.0, 2.6, 10.5)
		lamp.omni_range = 12.0
		lamp.light_energy = 1.0
		lamp.light_color = Color(1.0, 0.85, 0.6, 1.0)
		lamp.visible = night
		up.add_child(lamp)
		_stop_lamps.append(lamp)
	_last_night = night
	return true


func _try_hud(world: Node3D) -> bool:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return false
	if layer.get_node_or_null("TimetableLabel77") == null:
		var lab := Label.new()
		lab.name = "TimetableLabel77"
		lab.text = ""
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_rect(lab, 720.0, 655.0, 214.0, 40.0)
		lab.visible = false
		layer.add_child(lab)
		_timetable_label = lab
	else:
		_timetable_label = layer.get_node_or_null("TimetableLabel77") as Label
	if layer.get_node_or_null("Feedback77") == null:
		var flab := Label.new()
		flab.name = "Feedback77"
		flab.text = ""
		flab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_rect(flab, 720.0, 605.0, 104.0, 40.0)
		flab.visible = false
		layer.add_child(flab)
		_feedback_label = flab
	else:
		_feedback_label = layer.get_node_or_null("Feedback77") as Label
	return true


func _show_feedback(text: String) -> void:
	if _feedback_label != null:
		_feedback_label.text = text
		_feedback_label.visible = true
	_feedback_timer = FEEDBACK_S


func _physics_process(delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _stops_done:
		_stops_done = _try_stops(world)
	if not _hud_done:
		_hud_done = _try_hud(world)
	# Night gating for stop lamps, on change only (initial
	# state was applied at build, Slice 76 lesson).
	var night := _daylight() < 0.15
	if night != _last_night:
		_last_night = night
		for lamp in _stop_lamps:
			if lamp != null:
				lamp.visible = night
	var bus := world.get_node_or_null("Bus") as Node3D
	var player := world.get_node_or_null("Player") as Node3D
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	var driving_bus := false
	if bus != null and player != null:
		driving_bus = bool(player.get("driving")) and player.get("driving_vehicle") == bus
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0 and _feedback_label != null:
			_feedback_label.visible = false
	if not driving_bus:
		if _timetable_label != null:
			_timetable_label.visible = false
		_prev_door_open = false
		return
	_service_t += delta
	# Leg-start latch: a fresh leg starts exactly when the
	# controller flips to (east, next 0) or (west, next 2).
	# First observation estimates the epoch from the stops
	# already served on the current leg (a loaded mid-route
	# save), and is the only estimated value here.
	if ctrl != null:
		var dir := int(ctrl.get("direction"))
		var nxt := int(ctrl.get("next_stop"))
		var key := "%d-%d" % [dir, nxt]
		if not _observed:
			var done_steps := nxt if dir == 0 else 3 - nxt
			_epoch = _service_t - float(done_steps) * LEG_S
			_observed = true
			_leg_key = key
		elif key != _leg_key:
			if (dir == 0 and nxt == 0) or (dir == 1 and nxt == 2):
				_epoch = _service_t
			_leg_key = key
	# Timetable label: service clock + countdown to the
	# next stop's due time (or how late it already is).
	if _timetable_label != null and ctrl != null:
		var nxt2 := int(ctrl.get("next_stop"))
		var dir2 := int(ctrl.get("direction"))
		var remain := _due_for(nxt2, dir2) - _service_t
		var line2 := ""
		if remain >= 0.0:
			line2 = "နောက်: %s · %s အတွင်း" % [MY_DIGITS[nxt2], _fmt_mmss(remain)]
		else:
			line2 = "နောက်: %s · နောက်ကျ %s" % [MY_DIGITS[nxt2], _fmt_mmss(-remain)]
		_timetable_label.text = "🕐 %s · %s" % [_fmt_mmss(_service_t), line2]
		_timetable_label.visible = true
	# Serve detection, same rule as the Slice 74 controller:
	# door rising edge, speed under 0.5, inside 9 m of a stop.
	var door_open := false
	if bus != null and bus.get("door_open") != null:
		door_open = bool(bus.get("door_open"))
	var bus_speed := 0.0
	if bus != null and bus.get("speed") != null:
		bus_speed = absf(float(bus.get("speed")))
	if door_open and not _prev_door_open and bus_speed < STOP_SPEED and ctrl != null:
		var bp := bus.global_position
		var best := -1
		var best_d := STOP_ZONE_R
		for si in range(STOPS_X.size()):
			var d := Vector2(bp.x - STOPS_X[si], bp.z - 0.0).length()
			if d < best_d:
				best_d = d
				best = si
		if best >= 0:
			var dir3 := int(ctrl.get("direction"))
			var late := _service_t - _due_for(best, dir3)
			if absf(late) <= ON_TIME_S:
				_show_feedback("အချိန်မှန် ✓")
			elif late > 0.0:
				_show_feedback("နောက်ကျ %s" % _fmt_mmss(late))
			else:
				_show_feedback("စော %s" % _fmt_mmss(-late))
	_prev_door_open = door_open
