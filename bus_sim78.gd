extends Node3D
## Slice 78 — BUS SIMULATION, part 5 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 5).
## What it builds, all runtime-only, NO scene touched:
## - PASSENGER LIFE: Slice 74 waiting riders no longer stand
##   under the shelter like statues — they SIT on the Slice 77
##   bench (seat top y 0.61: body centre 0.98, head 1.62, so the
##   legless figure reads as seated, not standing on the
##   bench). When the Slice 74 controller serves their stop,
##   they no longer vanish on the spot: they stand up and
##   WALK to the bus flank on the stops side (target fixed at
##   walk start, so the onboard count the controller already
##   recorded stays consistent even if the bus pulls away
##   mid-walk — stated limitation, not hidden), then step
##   aboard (hidden). Alighted figures (Slice 75) walk away
##   from the stop (south, +z, 4 m) and then fade out over
##   FADE_S — their materials are fresh per figure (the
##   controller creates new ones per alight), so fading one
##   figure touches nothing else. The walk is translation
##   only: these figures have no legs, so no leg animation is
##   claimed.
## - DEPOT RETURN: when the Slice 75 controller flips from
##   (west, next 0) to (east, next 0) — a full round trip —
##   the service is done: a HUD line says so and the Slice
##   28/34 waypoint points at the depot (30, 16). Driving the
##   bus within 12 m of the depot clears the service and
##   shows a fresh-service line; the next serve re-points
##   the waypoint at the next stop as usual. NO money, NO
##   score, NO penalty — the return is a loop-closer only.
## - NEXT-STOP ANNOUNCEMENT: whenever the controller's next
##   stop changes while the player drives the bus (i.e. right
##   after serving a stop, as the bus leaves), a HUD line
##   names the next stop in Myanmar digits for 5 s. It reuses
##   the Slice 75 destination-sign text, never the default
##   font (which has no Myanmar glyphs) — HUD Labels use the
##   project's font path only where the engine applies it;
##   the text itself is Myanmar digits, verified in sim.
## State is session-only (walk states, service flag, timers):
## nothing new is saved, so no save key is added and no old
## save can break. No opponent code, map, names or structure
## is used. Touch-first throughout (no keys anywhere).

const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0]
const DEPOT_POS: Vector3 = Vector3(30.0, 0.0, 16.0)
const DEPOT_R: float = 12.0
const SEAT_X: Array = [-0.7, 0.7]
const SEAT_Z: float = 12.5
const SEAT_BODY_Y: float = 0.98
const SEAT_HEAD_Y: float = 1.62
const STAND_BODY_Y: float = 0.55
const STAND_HEAD_Y: float = 1.35
const AWAY_DIST: float = 4.0
const ANNOUNCE_S: float = 5.0
const SERVICE_MSG_S: float = 5.0
const MY_DIGITS: Array = ["၁", "၂", "၃", "၄"]

# Walk/fade speeds are vars (not consts) so the headless sim
# can accelerate them; the shipped defaults are the real
# walking pace, and the sim states its overrides plainly.
var walk_speed: float = 2.0
var away_speed: float = 1.4
var fade_s: float = 1.5

var _hud_done: bool = false
var _announce_label: Label = null
var _service_label: Label = null
var _announce_timer: float = 0.0
var _service_msg_timer: float = 0.0
var _prev_dir: int = -1
var _prev_next: int = -1
var _service_done: bool = false
var _away_seen: Array = []


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim78") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim78"
	n.set_script(load("res://bus_sim78.gd"))
	world.call_deferred("add_child", n)


static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61/74/75/76/77 HUD controls.
	# Announcement (505,605,214,40) and service (505,560,214,40)
	# sit LEFT of the bus cluster (x 720+) and ABOVE the
	# StaminaBar (y 648+), so they overlap no bus HUD element.
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


func _try_hud(world: Node3D) -> bool:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return false
	if layer.get_node_or_null("Announce78") == null:
		var lab := Label.new()
		lab.name = "Announce78"
		lab.text = ""
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_rect(lab, 505.0, 605.0, 214.0, 40.0)
		lab.visible = false
		layer.add_child(lab)
		_announce_label = lab
	else:
		_announce_label = layer.get_node_or_null("Announce78") as Label
	if layer.get_node_or_null("Service78") == null:
		var slab := Label.new()
		slab.name = "Service78"
		slab.text = ""
		slab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_rect(slab, 505.0, 560.0, 214.0, 40.0)
		slab.visible = false
		layer.add_child(slab)
		_service_label = slab
	else:
		_service_label = layer.get_node_or_null("Service78") as Label
	return true


func _stop_group(world: Node3D, idx: int) -> Node3D:
	return world.get_node_or_null("LongRoute74/BusStop74_%d" % idx) as Node3D


func _seat_rider(w: Node3D, wi: int) -> void:
	# Bench seat: stop-local (±0.7, 0, 12.5). Seated pose is
	# body/head lowered onto the seat top; standing pose is
	# restored when the walk starts.
	w.position = Vector3(SEAT_X[wi], 0.0, SEAT_Z)
	var body := w.get_node_or_null("Body74") as MeshInstance3D
	if body != null:
		body.position = Vector3(0.0, SEAT_BODY_Y, 0.0)
	var head := w.get_node_or_null("Head74") as MeshInstance3D
	if head != null:
		head.position = Vector3(0.0, SEAT_HEAD_Y, 0.0)


func _stand_rider(w: Node3D) -> void:
	var body := w.get_node_or_null("Body74") as MeshInstance3D
	if body != null:
		body.position = Vector3(0.0, STAND_BODY_Y, 0.0)
	var head := w.get_node_or_null("Head74") as MeshInstance3D
	if head != null:
		head.position = Vector3(0.0, STAND_HEAD_Y, 0.0)


func _set_waypoint(world: Node3D, p: Vector2) -> void:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return
	var wm := layer.get_node_or_null("WorldMapPanel")
	if wm != null:
		wm.set("has_waypoint", true)
		wm.set("waypoint", p)
	var beacon := world.get_node_or_null("WaypointBeacon28") as Node3D
	if beacon != null:
		beacon.visible = true
		beacon.global_position = Vector3(p.x, 2.5, p.y)


func _physics_process(delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _hud_done:
		_hud_done = _try_hud(world)
	var bus := world.get_node_or_null("Bus") as Node3D
	var player := world.get_node_or_null("Player") as Node3D
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	var driving_bus := false
	if bus != null and player != null:
		driving_bus = bool(player.get("driving")) and player.get("driving_vehicle") == bus
	# --- Passenger life: seat, walk to bus, walk away. ---
	for si in range(4):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(2):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
			if w == null:
				continue
			if bool(w.get_meta("walking78", false)):
				# Walking to the bus flank (target fixed at
				# walk start; see header limitation note).
				if not bool(w.get_meta("walk_started78", false)):
					_stand_rider(w)
					var target := Vector3(0.0, 0.0, 7.5)
					if bus != null:
						target = Vector3(bus.global_position.x, 0.0, 7.5)
					w.set_meta("walk_target78", target)
					w.set_meta("walk_started78", true)
				var target: Vector3 = w.get_meta("walk_target78", Vector3.ZERO)
				var cur := w.global_position
				var step := walk_speed * delta
				var dist := Vector2(cur.x - target.x, cur.z - target.z).length()
				if dist <= maxf(step, 0.5):
					w.global_position = Vector3(target.x, 0.0, target.z)
					w.visible = false
					w.set_meta("walking78", false)
					w.set_meta("walk_started78", false)
				else:
					var dir := Vector2(target.x - cur.x, target.z - cur.z).normalized()
					w.global_position = Vector3(cur.x + dir.x * step, 0.0, cur.z + dir.y * step)
			elif w.visible:
				# Seated on the bench (re-seats respawned
				# riders too, so a round-trip respawn never
				# leaves a rider standing in mid-air).
				_seat_rider(w, wi)
		# Alighted figures walk away south, then fade out.
		for child in grp.get_children():
			if not (child.name as String).begins_with("Alighted75_"):
				continue
			var fig := child as Node3D
			if fig == null or not fig.visible:
				continue
			var walked := float(fig.get_meta("walked78", 0.0))
			if walked < AWAY_DIST:
				var step := away_speed * delta
				fig.position = Vector3(fig.position.x, 0.0, fig.position.z + step)
				fig.set_meta("walked78", walked + step)
				if walked + step >= AWAY_DIST:
					# Fade needs alpha transparency; these
					# materials are fresh per figure, so this
					# touches nothing else.
					for part_name in ["Body74", "Head74"]:
						var part := fig.get_node_or_null(part_name) as MeshInstance3D
						if part != null:
							var mat := part.get_surface_override_material(0) as StandardMaterial3D
							if mat != null:
								mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					fig.set_meta("fade78", 0.0)
			else:
				var faded := float(fig.get_meta("fade78", 0.0)) + delta
				fig.set_meta("fade78", faded)
				var alpha := clampf(1.0 - faded / fade_s, 0.0, 1.0)
				for part_name in ["Body74", "Head74"]:
					var part := fig.get_node_or_null(part_name) as MeshInstance3D
					if part != null:
						var mat := part.get_surface_override_material(0) as StandardMaterial3D
						if mat != null:
							var c := mat.albedo_color
							c.a = alpha
							mat.albedo_color = c
				if alpha <= 0.0:
					fig.visible = false
	# --- Depot return + next-stop announcement. ---
	if ctrl != null:
		var dir := int(ctrl.get("direction"))
		var nxt := int(ctrl.get("next_stop"))
		if _prev_dir == 1 and _prev_next == 0 and dir == 0 and nxt == 0:
			# West leg finished at stop 0, route flipped back
			# east: the round trip is complete.
			_service_done = true
			_set_waypoint(world, Vector2(DEPOT_POS.x, DEPOT_POS.z))
		if _prev_dir != -1 and (_prev_next != nxt) and driving_bus:
			# Next stop changed while driving = just left a
			# stop: announce where the bus is headed next.
			if _announce_label != null:
				_announce_label.text = "➡ နောက် မှတ်တိုင် " + str(MY_DIGITS[nxt])
				_announce_label.visible = true
			_announce_timer = ANNOUNCE_S
		_prev_dir = dir
		_prev_next = nxt
	if _announce_timer > 0.0:
		_announce_timer -= delta
		if _announce_timer <= 0.0 and _announce_label != null:
			_announce_label.visible = false
	if _service_msg_timer > 0.0:
		_service_msg_timer -= delta
		if _service_msg_timer <= 0.0 and _service_label != null and not _service_done:
			_service_label.visible = false
	if _service_done and bus != null:
		var d := Vector2(bus.global_position.x - DEPOT_POS.x, bus.global_position.z - DEPOT_POS.z).length()
		if d < DEPOT_R:
			_service_done = false
			if _service_label != null:
				_service_label.text = "ဝန်ဆောင်မှုအသစ် စပါပြီ"
				_service_label.visible = true
			_service_msg_timer = SERVICE_MSG_S
			_set_waypoint(world, Vector2(STOPS_X[0], 0.0))
	if _service_label != null:
		if _service_done and driving_bus:
			_service_label.text = "✓ ဝန်ဆောင်မှုပြီးပြီ · ဂိုဒေါင်သို့ ပြန်ပါ"
			_service_label.visible = true
		elif not _service_done and _service_msg_timer <= 0.0:
			_service_label.visible = false
	if _announce_label != null and not driving_bus:
		_announce_label.visible = false
