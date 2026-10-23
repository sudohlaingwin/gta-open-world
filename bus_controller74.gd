extends Node3D
## Slice 74 — bus stop controller (companion to bus_sim74.gd).
## Runs on the world root as BusSim74. Every frame it:
## - shows the touch-first "🚪 တံခါး" door button and the
##   "🚌 N" boarded-count label ONLY while the player is
##   driving the bus (hidden on foot and in every other
##   vehicle, so it can never clutter the Slice 61 HUD);
## - on the rising edge of the bus door opening, serves the
##   nearest stop, but ONLY when the bus is properly stopped
##   (speed under 0.5 m/s inside the 9 m stop zone): a
##   drive-by with the door open boards nobody, and a
##   door opened far from any stop serves nothing.
## The door itself lives on the bus (bus.gd toggle_door);
## this controller only READS door_open, never drives the
## bus. No money/economy: boarding is a count, not a fare.
##
## Slice 75 — ROUTE SYSTEM + PASSENGER DESTINATIONS
## (owner simulation direction 2026-10-23 11:31 + bus choice
## 11:32, part 2). The Slice 74 serve (alight ALL, board ALL)
## becomes destination-aware:
## - every waiting passenger has a fixed destination stop
##   and a required direction (DESTS table, assigned as
##   node metadata on the first frame): eastbound riders
##   from stops 0/1/2 ride to a LATER stop, westbound
##   riders from stops 2/3 ride to an EARLIER stop, so a
##   rider from stop 0 never gets off at stop 1 just because
##   the bus stopped there — they ride to their own stop;
## - serving a stop always alights (dest == this stop) and
##   boards (direction matches) whoever is there, but the
##   ROUTE SEQUENCE only advances when the stops are
##   served IN ORDER: eastbound 0 -> 1 -> 2 -> 3 completes
##   the route (HUD banner + saved), then the direction
##   flips west (3 -> 2 -> 1 -> 0); a full round trip
##   respawns fresh waiting passengers and restarts
##   eastbound, so the shuttle never runs dry;
## - next-stop guidance reuses the Slice 28/34 waypoint
##   (WorldMapPanel waypoint + WaypointBeacon28 + GuidePanel34
##   arrow/distance, updated only when the next stop
##   changes, never cleared automatically) and the next
##   stop's minimap dot is tinted yellow;
## - the bus destination sign (DestSign75, bus_route75.gd)
##   shows the next stop in real Myanmar digits, and the
##   "🚌 N ↓M" label shows onboard + total alighted;
## - route state (next stop, direction, completion,
##   totals, onboard destinations, leg served, waiting
##   visibility) is saved under "busroute75" (player.gd
##   collect_save_data reads busroute75_state(); a load
##   restores it from the save file on the first frame —
##   a pre-75 save loads as a fresh route, same guard
##   pattern as the Slice 54/60/64 optional keys).
## Traffic-rule enforcement (signals, lane discipline,
## fines) is NOT built here — stated plainly, not faked.

var boarded: int = 0
var _prev_door_open: bool = false

const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0]
const STOP_ZONE_R: float = 9.0
const STOP_SPEED: float = 0.5

# Slice 75 route state.
const DIR_EAST: int = 0
const DIR_WEST: int = 1
const MY_DIGITS: Array = ["၁", "၂", "၃", "၄"]
# Per stop, per waiting seat: [destination stop, required
# direction]. Eastbound dests are always later stops, westbound
# dests always earlier stops, so the boarding rule (direction
# must match) can never board a rider going the wrong way.
const DESTS: Array = [
	[[2, DIR_EAST], [3, DIR_EAST]],
	[[3, DIR_EAST], [2, DIR_EAST]],
	[[3, DIR_EAST], [0, DIR_WEST]],
	[[1, DIR_WEST], [0, DIR_WEST]],
]
var next_stop: int = 0
var direction: int = DIR_EAST
var route_complete: bool = false
var boarded_total: int = 0
var alighted_total: int = 0
var onboard_dests: Array = []
var leg_served: Array = []
var _restored: bool = false
var _last_wp_stop: int = -1
var _last_sign_stop: int = -1
var _alight_seq: int = 0


func _stop_pos(world: Node3D, idx: int) -> Vector3:
	var grp := world.get_node_or_null("LongRoute74/BusStop74_%d" % idx) as Node3D
	if grp != null:
		return grp.global_position
	return Vector3(STOPS_X[idx], 0.0, 0.0)


func _stop_group(world: Node3D, idx: int) -> Node3D:
	return world.get_node_or_null("LongRoute74/BusStop74_%d" % idx) as Node3D


func _assign_destinations(world: Node3D) -> void:
	# Metadata on the waiting groups themselves, so a later
	# inspection (sim or save) can read each rider's trip.
	for si in range(4):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(2):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
			if w != null and not w.has_meta("dest75"):
				w.set_meta("dest75", DESTS[si][wi][0])
				w.set_meta("dir75", DESTS[si][wi][1])


func _waiting_bools(world: Node3D) -> Array:
	var out: Array = []
	for si in range(4):
		var grp := _stop_group(world, si)
		for wi in range(2):
			var vis := false
			if grp != null:
				var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
				if w != null:
					# Slice 78: a rider mid-walk to the bus is
					# still visible but already counted
					# onboard — saving them as waiting would
					# duplicate them on load.
					vis = w.visible and not bool(w.get_meta("walking78", false))
			out.append(vis)
	return out


func busroute75_state() -> Dictionary:
	var world := get_parent() as Node3D
	return {
		"complete": route_complete,
		"next_stop": next_stop,
		"direction": direction,
		"boarded_total": boarded_total,
		"alighted_total": alighted_total,
		"onboard": onboard_dests.duplicate(),
		"leg_served": leg_served.duplicate(),
		"waiting": _waiting_bools(world) if world != null else [],
	}


func _restore_state(world: Node3D) -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or not sm.has_method("load_save"):
		return
	var data: Dictionary = sm.call("load_save")
	if data.is_empty():
		return
	var br: Dictionary = data.get("busroute75", {})
	if br.is_empty():
		return
	next_stop = clampi(int(br.get("next_stop", 0)), 0, 3)
	direction = int(br.get("direction", DIR_EAST))
	if direction != DIR_EAST and direction != DIR_WEST:
		direction = DIR_EAST
	route_complete = bool(br.get("complete", false))
	boarded_total = int(br.get("boarded_total", 0))
	alighted_total = int(br.get("alighted_total", 0))
	onboard_dests = (br.get("onboard", []) as Array).duplicate()
	boarded = onboard_dests.size()
	leg_served = (br.get("leg_served", []) as Array).duplicate()
	var waiting: Array = br.get("waiting", [])
	for si in range(4):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(2):
			var k := si * 2 + wi
			if k < waiting.size() and not bool(waiting[k]):
				var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
				if w != null:
					w.visible = false


func _respawn_waiting(world: Node3D) -> void:
	# A full round trip ends the service day: fresh riders
	# appear at every stop (same destinations, same pattern
	# as the first day). Alighted figures stay standing —
	# they are people who got off, not fresh riders.
	for si in range(4):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(2):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
			if w != null:
				w.visible = true
				# Slice 78: clear any stale walk flag so the
				# respawned rider reseats on the bench.
				w.set_meta("walking78", false)
				w.set_meta("walk_started78", false)


func _update_route_guidance(world: Node3D) -> void:
	# Slice 28/34 waypoint, re-pointed only when the next
	# stop changes (so a manual waypoint is never fought
	# every frame). Never auto-cleared, Slice 34 pattern.
	if _last_wp_stop == next_stop:
		return
	_last_wp_stop = next_stop
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return
	var wm := layer.get_node_or_null("WorldMapPanel")
	if wm != null:
		wm.set("has_waypoint", true)
		wm.set("waypoint", Vector2(STOPS_X[next_stop], 0.0))
	var beacon := world.get_node_or_null("WaypointBeacon28") as Node3D
	if beacon != null:
		beacon.visible = true
		beacon.global_position = Vector3(STOPS_X[next_stop], 2.5, 0.0)


func _update_dest_sign(bus: Node3D) -> void:
	if _last_sign_stop == next_stop:
		return
	_last_sign_stop = next_stop
	var lab := bus.get_node_or_null("DestSign75") as Label3D
	if lab != null:
		lab.text = "မှတ်တိုင် " + str(MY_DIGITS[next_stop])


func _serve_stop(world: Node3D, bus: Node3D, stop_idx: int) -> void:
	# 1. Alight first: only riders whose destination IS this
	# stop get off (Slice 74 alighted everyone anywhere).
	var kept: Array = []
	var alighting := 0
	for d in onboard_dests:
		if int(d) == stop_idx:
			alighting += 1
			alighted_total += 1
		else:
			kept.append(d)
	onboard_dests = kept
	boarded = onboard_dests.size()
	var grp := _stop_group(world, stop_idx)
	if grp != null and alighting > 0:
		for ai in range(alighting):
			var body_m := StandardMaterial3D.new()
			body_m.albedo_color = Color(0.9, 0.85, 0.7, 1.0)
			var head_m := StandardMaterial3D.new()
			head_m.albedo_color = Color(0.8, 0.6, 0.45, 1.0)
			var g := Node3D.new()
			g.name = "Alighted75_%d" % _alight_seq
			_alight_seq += 1
			g.position = Vector3(-4.0 + float(_alight_seq % 5) * 2.0, 0.0, 10.5)
			grp.add_child(g)
			var b := MeshInstance3D.new()
			b.name = "Body74"
			var bm := CylinderMesh.new()
			bm.top_radius = 0.28
			bm.bottom_radius = 0.28
			bm.height = 1.1
			b.mesh = bm
			b.position = Vector3(0.0, 0.55, 0.0)
			b.set_surface_override_material(0, body_m)
			g.add_child(b)
			var h := MeshInstance3D.new()
			h.name = "Head74"
			var hm := SphereMesh.new()
			hm.radius = 0.22
			hm.height = 0.44
			h.mesh = hm
			h.position = Vector3(0.0, 1.35, 0.0)
			h.set_surface_override_material(0, head_m)
			g.add_child(h)
	# 2. Board: only still-visible waiting riders whose
	# required direction matches the current leg direction.
	if grp != null:
		for wi in range(2):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [stop_idx, wi]) as Node3D
			if w != null and w.visible and not bool(w.get_meta("walking78", false)) and int(w.get_meta("dir75", -1)) == direction:
				# Slice 78: do NOT hide on the spot — flag the
				# rider and let BusSim78 walk them to the bus
				# flank, then hide them there. The count is
				# recorded now; the visual follows.
				w.set_meta("walking78", true)
				onboard_dests.append(int(w.get_meta("dest75", stop_idx)))
				boarded_total += 1
		boarded = onboard_dests.size()
	# 3. Route sequence advances ONLY when the stops are
	# served in order; an out-of-order serve still moves
	# passengers, it just does not advance the route.
	if stop_idx == next_stop:
		leg_served.append(stop_idx)
		if direction == DIR_EAST:
			if stop_idx == 3:
				route_complete = true
				direction = DIR_WEST
				next_stop = 2
				leg_served = [3]
			else:
				next_stop = stop_idx + 1
		else:
			if stop_idx == 0:
				_respawn_waiting(world)
				direction = DIR_EAST
				next_stop = 0
				leg_served = []
			else:
				next_stop = stop_idx - 1
		_update_route_guidance(world)
		if bus != null:
			_update_dest_sign(bus)


func _process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var bus := world.get_node_or_null("Bus") as Node3D
	var player := world.get_node_or_null("Player") as Node3D
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if not _restored:
		_assign_destinations(world)
		_restore_state(world)
		_restored = true
	var driving_bus := false
	if bus != null and player != null:
		driving_bus = bool(player.get("driving")) and player.get("driving_vehicle") == bus
	if layer != null:
		var dbtn := layer.get_node_or_null("DoorButton74") as Button
		if dbtn != null:
			dbtn.visible = driving_bus
		var blab := layer.get_node_or_null("BoardLabel74") as Label
		if blab != null:
			blab.visible = driving_bus
			blab.text = "🚌 %d ↓%d" % [boarded, alighted_total]
		var rlab := layer.get_node_or_null("RouteLabel75") as Label
		if rlab != null:
			rlab.visible = driving_bus
			if route_complete:
				rlab.text = "✓ လမ်းကြောင်းပြီးပြီ · ➡ မှတ်တိုင် " + str(MY_DIGITS[next_stop])
			else:
				rlab.text = "➡ နောက်: မှတ်တိုင် " + str(MY_DIGITS[next_stop])
		# Next-stop minimap dot tint (yellow = next, blue =
		# the rest); the dots themselves are Slice 74's.
		var panel := layer.get_node_or_null("MinimapPanel") as Control
		if panel != null:
			for si in range(4):
				var dot := panel.get_node_or_null("BusStop74_%d" % si) as ColorRect
				if dot != null:
					dot.color = Color(1.0, 0.85, 0.2, 1.0) if si == next_stop else Color(0.2, 0.6, 1.0, 1.0)
	# The destination sign reads correctly even on foot — it
	# is a physical sign on the bus, not a driving-only HUD.
	if bus != null:
		_update_dest_sign(bus)
	if bus == null or not driving_bus:
		_prev_door_open = false
		return
	var door_open := bool(bus.get("door_open"))
	var speed := 0.0
	if bus.get("speed") != null:
		speed = absf(float(bus.get("speed")))
	# Rising edge only: holding the door open must not
	# re-board every frame, and a door opened while moving
	# must not serve a stop the bus rolls past.
	if door_open and not _prev_door_open and speed < STOP_SPEED:
		var bp := (bus as Node3D).global_position
		var best := -1
		var best_d := STOP_ZONE_R
		for si in range(STOPS_X.size()):
			var sp := _stop_pos(world, si)
			var d := Vector2(bp.x - sp.x, bp.z - sp.z).length()
			if d < best_d:
				best_d = d
				best = si
		if best >= 0:
			_serve_stop(world, bus, best)
	_prev_door_open = door_open
