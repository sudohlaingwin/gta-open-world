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
##
## Slice 79 — NIGHT LEGS + SERVICE-POSITION DUES (part 6).
## A leg starting at night (daylight < 0.15, Slice 57 rule)
## runs 90 s per stop instead of 60 s; the duration is
## fixed at leg start, so nightfall mid-leg does not
## stretch the leg already running. Dues are counted by
## position in the current service order (Slice 79 node
## owns the service mode; the controller answers
## service_pos79), so Express dues are 0 / 1 legs, never
## Local spacing. The feedback sequence counter lets the
## Slice 79 summary count on-time stops without reading
## label text.
##
## Slice 83 — PEAK LEGS (part 10). A leg starting during
## a peak band runs 45 s per stop instead of 60 s; night
## still wins over peak (evening peak overlaps night, and
## a night leg stays 90 s). The band rule is the same
## rule as bus_sim83.gd (night first, then the 120 s day
## clock: morning [0, 15), evening [45, 60)) — keep the
## two copies in sync; SIM83 proves they agree at every
## band. Duration is fixed at leg start like Slice 79, so
## a band change mid-leg does NOT stretch the leg already
## running, and the first-observation estimate uses
## current daylight + current band for the same choice.

## Slice 85 — RAIN LEGS (part 12). A leg starting in the
## rainy season (SaveManager season62 == 1) runs 75 s per
## stop instead of 60 s. Precedence, stated plainly:
## night 90 s wins over rain 75 s, rain wins over peak
## 45 s, off-peak stays 60 s. Duration is fixed at leg
## start like Slices 79/83, so a weather change mid-leg
## does NOT stretch the leg already running. Rain does
## NOT change the boards (they list Local minute marks;
## the live timetable label gives the exact countdown).
## The rain test reads SaveManager directly; a missing
## SaveManager means dry, same default as bus.gd braking.
##
## Slice 84 — FULL-LENGTH ROUTE (part 11). 6 stops, not 4:
## travel order east [4, 0, 1, 2, 3, 5], west [5, 3, 2, 1, 0,
## 4] (controller owns it). Leg-start latch is now generic
## via service_order79 (first stop of an east order, second
## stop of a west order — the flip stop counts as served);
## timetable dues count by service position, so Local dues
## run 0..5 legs and Express dues 0..1; player-facing
## digits are travel positions via the controller's
## pos_digit79, never group indices. The Slice 77 upgrade
## loop covers all 6 groups (BusSim84 builds groups 4/5;
## this loop retries until they exist, same pattern).

const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0, 500.0, 2400.0]
const STOP_ZONE_R: float = 9.0
const STOP_SPEED: float = 0.5
const LEG_S: float = 60.0
const NIGHT_LEG_S: float = 90.0
const PEAK_LEG_S: float = 45.0
const RAIN_LEG_S: float = 75.0
const ON_TIME_S: float = 15.0
const FEEDBACK_S: float = 5.0
const BOARD_TEXT: String = "ဘတ်စ်ဇယား\nမှတ်တိုင် ၁ ၀ မိနစ်\nမှတ်တိုင် ၂ ၁ မိနစ်\nမှတ်တိုင် ၃ ၂ မိနစ်\nမှတ်တိုင် ၄ ၃ မိနစ်\nမှတ်တိုင် ၅ ၄ မိနစ်\nမှတ်တိုင် ၆ ၅ မိနစ်"

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
# Slice 79: leg duration is fixed when a leg STARTS (day
# 60 s, night 90 s by the Slice 57 dark rule) — a
# day-to-night change mid-leg does NOT stretch the leg
# already running, stated plainly. The Slice 79 summary
# reads the feedback sequence, never the label text.
var _leg_s: float = LEG_S
var feedback_seq79: int = 0
var last_feedback_ontime79: bool = false


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


func _is_rainy() -> bool:
	# Slice 85: rainy season is SaveManager season62 == 1
	# (same read as bus.gd rain braking and the Slice 62
	# season controller). Missing SaveManager means dry.
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or sm.get("season62") == null:
		return false
	return int(sm.get("season62")) == 1


func _leg_duration_now() -> float:
	# Slice 83 band rule, mirrored from bus_sim83.gd,
	# plus Slice 85 rain precedence: night (daylight <
	# 0.15) first at 90 s, then rain at 75 s, then peak
	# bands on the 120 s day clock at 45 s, else 60 s.
	if _daylight() < 0.15:
		return NIGHT_LEG_S
	if _is_rainy():
		return RAIN_LEG_S
	var world := get_parent() as Node3D
	var t := 0.0
	if world != null:
		var dn := world.get_node_or_null("DayNight")
		if dn != null and dn.get("time") != null:
			t = float(dn.get("time"))
	t = fmod(t, 120.0)
	if t < 0.0:
		t += 120.0
	if t < 15.0:
		return PEAK_LEG_S
	if t >= 45.0 and t < 60.0:
		return PEAK_LEG_S
	return LEG_S


func _fmt_mmss(t: float) -> String:
	var total := int(maxf(0.0, t))
	return "%d:%02d" % [total / 60, total % 60]


func _due_for(stop_idx: int, direction: int) -> float:
	# Due = leg start + (position in the service order) x
	# leg duration. Slice 79: Express positions are 0 -> 0,
	# 1 -> 1 eastbound (0 -> 0, 1 -> 1 westbound in full
	# terms — endpoints only), so an Express stop is never
	# due on Local spacing; Local positions run 0..5.
	# A stop the service skips falls back to its FULL
	# order position (Slice 84), never its group index.
	var pos := -1
	var world := get_parent() as Node3D
	if world != null:
		var ctrl := world.get_node_or_null("BusSim74") as Node3D
		if ctrl != null and ctrl.has_method("service_pos79"):
			pos = int(ctrl.call("service_pos79", stop_idx, direction))
		if pos < 0 and ctrl != null and ctrl.has_method("full_pos79"):
			pos = int(ctrl.call("full_pos79", stop_idx, direction))
	if pos < 0:
		pos = stop_idx
	return _epoch + float(pos) * _leg_s


func _pos_digit(stop_idx: int, direction: int) -> String:
	# Player-facing digit: travel position, never group.
	var world := get_parent() as Node3D
	if world != null:
		var ctrl := world.get_node_or_null("BusSim74") as Node3D
		if ctrl != null and ctrl.has_method("pos_digit79"):
			return str(ctrl.call("pos_digit79", stop_idx, direction))
	return ""


func _try_stops(world: Node3D) -> bool:
	# All 6 stop groups must exist first (Slice 74 dress +
	# Slice 84 dress run before this node, but deferred
	# order is retried anyway).
	for si in range(6):
		if world.get_node_or_null("LongRoute74/BusStop74_%d" % si) == null:
			return false
	var wood := _mat(Color(0.45, 0.30, 0.15, 1.0), 0.9)
	var post_m := _mat(Color(0.4, 0.4, 0.42, 1.0), 0.6)
	var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
	var mark_m := _mat(Color(0.95, 0.85, 0.2, 1.0), 0.8)
	var lamp_m := _mat(Color(1.0, 0.85, 0.5, 1.0), 0.5)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	var night := _daylight() < 0.15
	for si in range(6):
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
	# controller flips to the first stop of an east order
	# or the second stop of a west order (the flip stop
	# itself counts as served). Slice 84: generic via
	# service_order79 — Local east starts at 4, west at
	# 3; Express east starts at 4, west at 4. The old
	# hardcoded (east, 0) / (west, 2) pair died with the
	# 4-stop route and is NOT kept as a fallback.
	if ctrl != null:
		var dir := int(ctrl.get("direction"))
		var nxt := int(ctrl.get("next_stop"))
		var key := "%d-%d" % [dir, nxt]
		if not _observed:
			var done_steps := 0
			if ctrl.has_method("service_pos79"):
				var p0 := int(ctrl.call("service_pos79", nxt, dir))
				if p0 >= 0:
					done_steps = p0
			_leg_s = _leg_duration_now()
			_epoch = _service_t - float(done_steps) * _leg_s
			_observed = true
			_leg_key = key
		elif key != _leg_key:
			var leg_start := false
			if ctrl.has_method("service_order79"):
				var order: Array = ctrl.call("service_order79", dir)
				if dir == 0 and order.size() > 0 and nxt == int(order[0]):
					leg_start = true
				elif dir == 1 and order.size() > 1 and nxt == int(order[1]):
					leg_start = true
			if leg_start:
				_epoch = _service_t
				_leg_s = _leg_duration_now()
			_leg_key = key
	# Timetable label: service clock + countdown to the
	# next stop's due time (or how late it already is).
	if _timetable_label != null and ctrl != null:
		var nxt2 := int(ctrl.get("next_stop"))
		var dir2 := int(ctrl.get("direction"))
		var remain := _due_for(nxt2, dir2) - _service_t
		var line2 := ""
		var digit2 := _pos_digit(nxt2, dir2)
		if remain >= 0.0:
			line2 = "နောက်: %s · %s အတွင်း" % [digit2, _fmt_mmss(remain)]
		else:
			line2 = "နောက်: %s · နောက်ကျ %s" % [digit2, _fmt_mmss(-remain)]
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
				last_feedback_ontime79 = true
			elif late > 0.0:
				_show_feedback("နောက်ကျ %s" % _fmt_mmss(late))
				last_feedback_ontime79 = false
			else:
				_show_feedback("စော %s" % _fmt_mmss(-late))
				last_feedback_ontime79 = false
			feedback_seq79 += 1
	_prev_door_open = door_open
