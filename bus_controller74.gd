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
##   from a stop ride to a LATER stop in travel order,
##   westbound riders to a LATER stop in west travel
##   order, so a rider never gets off at the wrong stop
##   just because the bus stopped there;
## - serving a stop always alights (dest == this stop) and
##   boards (direction matches) whoever is there, but the
##   ROUTE SEQUENCE only advances when the stops are
##   served IN ORDER: eastbound 4 -> 0 -> 1 -> 2 -> 3 -> 5
##   completes the leg (HUD banner + saved), then the
##   direction flips west (5 -> 3 -> 2 -> 1 -> 0 -> 4); a
##   full round trip respawns fresh waiting passengers
##   and restarts eastbound, so the shuttle never runs dry;
## - next-stop guidance reuses the Slice 28/34 waypoint
##   (WorldMapPanel waypoint + WaypointBeacon28 + GuidePanel34
##   arrow/distance, updated only when the next stop
##   changes, never cleared automatically) and the next
##   stop's minimap dot is tinted yellow;
## - the bus destination sign (DestSign75, bus_route75.gd)
##   shows the next stop in travel-position Myanmar digits,
##   and the "🚌 N ↓M" label shows onboard + total alighted;
## - route state (next stop, direction, completion,
##   totals, onboard destinations, leg served, waiting
##   visibility) is saved under "busroute75" (player.gd
##   collect_save_data reads busroute75_state(); a load
##   restores it from the save file on the first frame —
##   a pre-75 save loads as a fresh route, same guard
##   pattern as the Slice 54/60/64 optional keys).
## Traffic-rule enforcement (signals, lane discipline,
## fines) is NOT built here — stated plainly, not faked.
##
## Slice 84 — FULL-LENGTH ROUTE (part 11). The route runs
## the whole 2 km road: 6 stops, travel order east
## [4, 0, 1, 2, 3, 5] and west [5, 3, 2, 1, 0, 4].
## Group indices are NOT travel positions (bus_sim84.gd
## header explains why): group 4 is x 500 (stop 1), group
## 5 is x 2400 (stop 6). Player-facing digits are travel
## positions via service_pos79 / full_pos79, never the
## group index. Old saves need NO migration: groups 0..3
## kept their stops, so a saved next_stop / onboard dest
## / leg_served still means the same stop; a saved route
## simply continues with 2 new endpoints available.
##
## Slice 79 — SERVICE VARIANTS (Local vs Express, part 6).
## The route controller owns the service mode (session-only,
## NOT saved: a loaded save always resumes as Local, stated
## plainly — the busroute75 key is untouched):
## - Local serves every stop in order (east 4 -> 0 -> 1 ->
##   2 -> 3 -> 5, west 5 -> 3 -> 2 -> 1 -> 0 -> 4) — the
##   Slice 75 behaviour, kept exactly: the boarding filter
##   below reduces to the old direction-match rule for
##   Local, because the DESTS table only ever gives
##   ahead destinations in travel order;
## - Express serves only the endpoints 500 and 2400 (east
##   4 -> 5, west 5 -> 4). The destination sign, the Slice
##   77 timetable dues and the Slice 28/34 guidance all
##   follow next_stop, so they re-point automatically; the
##   Slice 79 node only re-texts the physical timetable boards;
## - boarding is filtered by the service: a rider boards
##   only if the stop is a service stop, their required
##   direction matches the leg, AND their destination is a
##   later service stop in that direction. A group-4 rider
##   bound for group 1 therefore does NOT board an Express
##   (they wait for Local); an out-of-order Express serve
##   at a skipped stop boards nobody at all;
## - switching mid-leg recomputes next_stop as the first
##   service stop ahead of the last in-order served stop
##   (by position in the travel direction), so a switch
##   can never send the bus backwards or strand the route.

var boarded: int = 0
var _prev_door_open: bool = false

# GROUP-indexed stop x positions (group 4 = x 500 west end,
# group 5 = x 2400 east end — appended by Slice 84, never
# renumbering groups 0..3). Travel order lives in
# service_order79 below; never read this array as travel
# order.
const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0, 500.0, 2400.0]
const STOP_ZONE_R: float = 9.0
const STOP_SPEED: float = 0.5

# Slice 75 route state.
const DIR_EAST: int = 0
const DIR_WEST: int = 1
# TRAVEL-POSITION digits (1..6 west to east), NOT group
# digits: position 0 = x 500, position 5 = x 2400. Use
# _pos_digit() / service_pos79, never MY_DIGITS[group].
const MY_DIGITS: Array = ["၁", "၂", "၃", "၄", "၅", "၆"]
# Per stop, per waiting seat: [destination stop, required
# direction]. Destinations are always AHEAD in travel
# order for their direction (east: later in the east
# order; west: later in the west order), so the boarding
# rule (position of dest > position of stop) can never
# board a rider going the wrong way.
# Slice 83 adds seat 2 (the peak third rider, created by
# BusSim83): group 0 -> 3 east, group 1 -> 3 east, group 2 ->
# 0 west, group 3 -> 0 west. Slice 84 adds groups 4 and 5:
# group 4 (west terminus) rides east only, group 5 (east
# terminus) rides west only; dests 5 (from 4) and 4 (from
# 5) are the Express endpoints, so those seats board
# Express while the other new seats are Local-only.
const DESTS: Array = [
	[[2, DIR_EAST], [3, DIR_EAST], [3, DIR_EAST]],
	[[3, DIR_EAST], [2, DIR_EAST], [3, DIR_EAST]],
	[[3, DIR_EAST], [0, DIR_WEST], [0, DIR_WEST]],
	[[1, DIR_WEST], [0, DIR_WEST], [0, DIR_WEST]],
	[[0, DIR_EAST], [1, DIR_EAST], [5, DIR_EAST]],
	[[3, DIR_WEST], [0, DIR_WEST], [4, DIR_WEST]],
]
# Fresh route starts at the west terminus (x 500), the
# first stop of an east leg. Restored saves overwrite this.
var next_stop: int = 4
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

# Slice 79 service mode (session-only, NOT saved).
const SERVICE_LOCAL: int = 0
const SERVICE_EXPRESS: int = 1
var service79: int = SERVICE_LOCAL


func service_order79(dir: int) -> Array:
	# Stops in travel order for the current service. Local
	# is the Slice 75 order; Express serves only the two
	# endpoints (groups 4 and 5).
	if service79 == SERVICE_EXPRESS:
		if dir == DIR_WEST:
			return [5, 4]
		return [4, 5]
	if dir == DIR_WEST:
		return [5, 3, 2, 1, 0, 4]
	return [4, 0, 1, 2, 3, 5]


func service_pos79(stop_idx: int, dir: int) -> int:
	return service_order79(dir).find(stop_idx)


func full_pos79(stop_idx: int, dir: int) -> int:
	# Position in the FULL travel order, ignoring the
	# service: the fallback for a stop the current service
	# skips (service_pos79 returns -1 there). Never -1 for
	# a valid group 0..5.
	if dir == DIR_WEST:
		return [5, 3, 2, 1, 0, 4].find(stop_idx)
	return [4, 0, 1, 2, 3, 5].find(stop_idx)


func pos_digit79(stop_idx: int, dir: int) -> String:
	# Player-facing digit for a stop: ALWAYS its
	# west-to-east travel position (1..6), never its
	# position in the current service order, never its
	# group index, and never its position in the
	# direction of travel (full_pos79 west order would
	# renumber every stop on the return leg). A stop's
	# number must be stable: the physical sign at
	# group 2 reads ၄, the Local board lists it as ၄,
	# and the Express board lists the endpoints as ၁
	# and ၆ — so the destination sign, route label,
	# announcement and request label must show the
	# same digits in both directions and both services.
	# (Slice 84 fix, second draft: the first draft used
	# service positions, so the same stop showed ၃
	# westbound but ၄ eastbound, and the Express
	# endpoint showed ၂ instead of ၆; full_pos79 with
	# the travel direction still renumbered westbound.)
	# dir is kept for signature compatibility; the
	# numbering is direction-independent by design.
	var p := full_pos79(stop_idx, DIR_EAST)
	if p < 0:
		return ""
	return MY_DIGITS[p]


func set_service79(mode: int, world: Node3D, bus: Node3D) -> void:
	# Touch-first selector (Slice 79 node) calls this. A
	# mid-leg switch recomputes next_stop from the last
	# in-order served stop, never from the old next_stop,
	# so the route can neither run backwards nor stall.
	if mode != SERVICE_LOCAL and mode != SERVICE_EXPRESS:
		return
	if mode == service79:
		return
	service79 = mode
	var order: Array = service_order79(direction)
	var last := -1
	if leg_served.size() > 0:
		last = int(leg_served[leg_served.size() - 1])
	# "Ahead" is measured in the FULL travel order, not the
	# service order: after serving group 0 eastbound, the
	# next Express stop is 5 (full position 5), not 4
	# (full position 0, behind the bus). The old group-
	# index comparison only worked while group order was
	# travel order; Slice 84 broke that identity.
	var last_full := full_pos79(last, direction) if last >= 0 else -1
	var nxt := -1
	for s in order:
		if last_full < 0 or full_pos79(int(s), direction) > last_full:
			nxt = int(s)
			break
	if nxt == -1:
		nxt = int(order[0])
	next_stop = nxt
	_update_route_guidance(world)
	if bus != null:
		_update_dest_sign(bus)


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
	for si in range(6):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(3):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
			if w != null and not w.has_meta("dest75"):
				w.set_meta("dest75", DESTS[si][wi][0])
				w.set_meta("dir75", DESTS[si][wi][1])


func _waiting_bools(world: Node3D) -> Array:
	var out: Array = []
	for si in range(6):
		var grp := _stop_group(world, si)
		for wi in range(3):
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


func _peak_hidden_bools(world: Node3D) -> Array:
	# Slice 83: seat 2's peak-hidden marker per stop, so
	# the save can tell a band-hidden rider (resurrect at
	# peak) from a boarded rider (stay hidden).
	var out: Array = []
	for si in range(6):
		var grp := _stop_group(world, si)
		var hidden := false
		if grp != null:
			var w := grp.get_node_or_null("Waiting74_%d_2" % si) as Node3D
			if w != null:
				hidden = bool(w.get_meta("peak83_hidden", false))
		out.append(hidden)
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
		# Slice 83: seat 2's peak-hidden marker, per stop.
		# Without it a peak-hidden rider and a boarded rider
		# both save as waiting=false and could not be told
		# apart on load (the peak rule must resurrect only
		# the peak-hidden one). Old saves lack the key and
		# read as all-false, which is correct for them.
		"peak83_hidden": _peak_hidden_bools(world) if world != null else [],
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
	next_stop = clampi(int(br.get("next_stop", 4)), 0, 5)
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
	var ph: Array = br.get("peak83_hidden", [])
	# Slice 84: saves hold 18 waiting entries (3 seats x 6
	# stops). Slice 83 saves hold 12 (3 seats x 4 stops)
	# and pre-83 saves hold 8 (2 seats x 4); reading any
	# of those with the new stride would misalign every
	# stop after the first, so old saves keep their own
	# stride and groups 4/5 are left visible (the band
	# rule then hides seat 2 off-peak on the next frame).
	# Groups 0..3 never moved, so no index remap is needed.
	var seats := 3 if waiting.size() >= 12 else 2
	var stops := 6 if waiting.size() >= 18 else 4
	for si in range(stops):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(seats):
			var k := si * seats + wi
			if k < waiting.size() and not bool(waiting[k]):
				var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
				if w != null:
					w.visible = false
			if wi == 2 and si < ph.size() and bool(ph[si]):
				var w2 := grp.get_node_or_null("Waiting74_%d_2" % si) as Node3D
				if w2 != null:
					w2.set_meta("peak83_hidden", true)


func _respawn_waiting(world: Node3D) -> void:
	# A full round trip ends the service day: fresh riders
	# appear at every stop (same destinations, same pattern
	# as the first day). Alighted figures stay standing —
	# they are people who got off, not fresh riders.
	for si in range(6):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(3):
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
		lab.text = "မှတ်တိုင် " + pos_digit79(next_stop, direction)


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
	# 2. Board: only still-visible waiting riders on a
	# SERVICE stop whose required direction matches the
	# current leg AND whose destination is a later service
	# stop in that direction (Slice 79). For Local this
	# reduces to the old direction-match rule (the DESTS
	# table only gives ahead destinations); for Express a
	# rider bound for a skipped stop never boards, and an
	# out-of-order serve at a skipped stop boards nobody.
	var order79: Array = service_order79(direction)
	if grp != null and order79.has(stop_idx):
		for wi in range(3):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [stop_idx, wi]) as Node3D
			if w != null and w.visible and not bool(w.get_meta("walking78", false)) and int(w.get_meta("dir75", -1)) == direction:
				var dest79 := int(w.get_meta("dest75", stop_idx))
				# Ahead = later in the CURRENT service order
				# (position comparison, Slice 84: group order
				# is no longer travel order, so the old
				# "dest > stop east / dest < stop west" test
				# would board backwards from group 4).
				var pos_s := order79.find(stop_idx)
				var pos_d := order79.find(dest79)
				if pos_d < 0 or pos_d <= pos_s:
					continue
				# Slice 78: do NOT hide on the spot — flag the
				# rider and let BusSim78 walk them to the bus
				# flank, then hide them there. The count is
				# recorded now; the visual follows.
				w.set_meta("walking78", true)
				onboard_dests.append(dest79)
				boarded_total += 1
		boarded = onboard_dests.size()
	# 3. Route sequence advances ONLY when the stops are
	# served in order; an out-of-order serve still moves
	# passengers, it just does not advance the route.
	# Order-based (Slice 79): the last stop of the current
	# service order completes the leg, so Express (4 -> 5,
	# 5 -> 4) flips exactly like Local (4 -> 5, 5 -> 4
	# endpoints with 4 middle stops between them).
	if stop_idx == next_stop:
		leg_served.append(stop_idx)
		var pos79 := order79.find(stop_idx)
		if pos79 == order79.size() - 1:
			if direction == DIR_EAST:
				route_complete = true
				direction = DIR_WEST
				next_stop = int(service_order79(DIR_WEST)[1])
				leg_served = [stop_idx]
			else:
				_respawn_waiting(world)
				direction = DIR_EAST
				next_stop = int(service_order79(DIR_EAST)[0])
				leg_served = []
		else:
			next_stop = int(order79[pos79 + 1])
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
				rlab.text = "✓ လမ်းကြောင်းပြီးပြီ · ➡ မှတ်တိုင် " + pos_digit79(next_stop, direction)
			else:
				rlab.text = "➡ နောက်: မှတ်တိုင် " + pos_digit79(next_stop, direction)
		# Next-stop minimap dot tint (yellow = next, blue =
		# the rest) AND position (Slice 84 fix: Slice 74
		# created the dots but nothing ever positioned
		# them, so they sat at the panel corner — the
		# controller now drives all 6 from the live group
		# positions, same MapTransform pattern as the
		# player minimap).
		var panel := layer.get_node_or_null("MinimapPanel") as Control
		if panel != null:
			for si in range(6):
				var dot := panel.get_node_or_null("BusStop74_%d" % si) as ColorRect
				if dot != null:
					dot.color = Color(1.0, 0.85, 0.2, 1.0) if si == next_stop else Color(0.2, 0.6, 1.0, 1.0)
					var sp := _stop_pos(world, si)
					var pp := MapTransform.world_to_panel(sp.x, sp.z, panel.size)
					var cp := MapTransform.clamp_dot(pp, panel.size, dot.size)
					if dot.position != cp:
						dot.position = cp
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
