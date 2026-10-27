extends Node3D

## Slice 141 — vehicle lights + wheels round (audit-first, all three
## items live-probed before shipping):
##
## (1) DUPLICATE WHEELS, Cart + Motorcycle (S134 duplicate class):
## audit141b proves BOTH vehicles carry two wheel sets at once:
## scene wheels (CartWheelL/R 0.7 tire, WheelBike_F/B 0.7 tire —
## the sets cart.gd:132 / motorcycle.gd:120 SPIN while driving)
## AND realism71 dressing wheels (Wheel71_0/1: cart 1.1 wood with
## spokes+hubs, bike 0.76 tire with hubs) at near-identical
## centres (bike: EXACT same centres; cart: 0.2 m offset). The
## static set never spins, so a driven Cart/Motorcycle shows a
## doubled wheel (spinning disc inside a frozen disc). FIX (S134
## pattern, hide never delete): hide the static Wheel71 nodes
## ONLY when the spinning scene wheels exist and are visible —
## otherwise keep both (doubled beats wheel-less). Hiding the
## parent hides its Hub71/Spoke71 children with it.
##
## (2) BICYCLE NIGHT DARKNESS (exception against controls):
## audit141 proves the Bicycle is the ONLY player vehicle with
## ZERO light meshes and ZERO emissive meshes (car 8 lights,
## cart 5, moto 5, plane nav 2, heli landlight 1, boats lamp 1,
## tuk 3, bus heads+tails, minibus heads+tails). At night the
## ridden bicycle is a fully dark silhouette. FIX: one headlight
## + one taillight, children of Bicycle (so they follow when
## driven), placed from LIVE BikeWheelF/B local positions
## (head 0.6 above the front wheel, 0.15 further forward;
## tail 0.6 above the rear wheel, 0.15 further back), ungated
## emissive 1.2 like Boat Lamp99 (the closest precedent — small
## vehicle lamps in this game are ungated, not drive-gated).
## Bicycle front is local -z (front wheel z -0.7, handle -0.55).
##
## (3) BUS / MINIBUS BRAKE LIGHTS MISSING (S118 missed class):
## audit141b/141c prove BusTail74 + MiniTail81 exist but NO
## system ever drives them (bus_sim74/bus_sim81 static materials
## only): tails read 0.0 parked, driving, AND stopped, while
## car/tuk/moto tails go bright 2.5 on deceleration (S118/S123).
## Bus/Minibus are the only wheeled player vehicles with zero
## brake lights — driving behind a braking bus at night shows
## nothing. FIX (brief explicitly allows extending S117/S118
## for a proven missed class): drive the EXISTING tail meshes
## by the S118 pattern — measured position-delta deceleration
## (decel > 1.0 m/s^2 -> bright 2.5, else dim 0.25, 1.0 s hold
## that persists while stopped per S135). Materials are CLONED
## before driving (S123 lesson) so no shared material is ever
## mutated. This writes MATERIAL ENERGY ONLY — bus service
## logic, routes, and seating are untouched (Slice 81 limit
## honoured: visual dressing on a proven read gap, stated).
## The same loop also lights service-driven buses (their
## position deltas brake the same way) — correct behaviour,
## not a service change. ONE DELIBERATE DIFFERENCE from S118,
## proven by three probes: bus POSITION-delta speed is JITTERY
## (sim141probe per-100 ms samples during a smooth pull-away
## read 2.12 -> 0.77, 5.07 -> 2.91, 7.85 -> 2.64 m/s — the
## move_and_slide body stutters against the world while its
## integrator speed rises smoothly), so a position-only
## detector re-triggers the hold during pull-away: sim141
## first run (no debounce) failed Bus dim with the bus moved
## 5.64 m at speed 7.01, and debounce-3 alone STILL failed
## (a sawtooth stall can fall 3+ consecutive frames). The
## fix reads the vehicle's own integrator speed instead:
## bus.gd (which the Minibus shares per bus_sim81:134)
## updates `speed` every physics frame while driven, and the
## bus body NEVER moves without a driver (bus.gd driver-null
## branch sets velocity ZERO; _exit_bus zeroes speed), so
## `speed` is the authoritative motion signal whenever the
## bus moves at all. sim141probe3's intspeed trace during
## pull-away is perfectly monotonic (0.43, 0.81, 1.31, 1.70,
## 2.04, 2.47, 2.85, 3.40, 3.99, 4.62, 5.28, 5.93, 6.55, 7.09,
## 7.62, 8.20, 8.77, 9.25, 9.80, 10.32) — no drops, so no
## false re-trip. Speed is read as ABS (reversing is not
## braking: |speed| rises while reversing, so it never
## lights). Position deltas remain only as the fallback for
## a vehicle without a `speed` var, still guarded by the
## 3-consecutive-frame debounce. Realism118's traffic
## detector is NOT touched by this change.
##
## NOT shipped, with reasons: traffic variety (manager cars vary
## by slot colour — traffic_manager _colors red/blue/yellow/
## green, cycled; no clone-read proven); traffic box wheels
## (WheelMesh 0.2x0.6x0.6 BoxMesh on manager cars — they move
## fast past the camera and read as dark discs; reshaping them
## is a new modelling pass, not a proven 6 m gap); animal
## lights (cows/horses/elephant have no headlights in reality
## — dark animals at night are correct, moonlight still reads
## them); car driver figure (deliberately absent per S115
## header — 0.45 m cabin headroom, a figure would clip the
## roof); vehicle interiors (invisible at 6 m exterior view —
## padding, refused). Runs at frame >= 810, after realism138's
## 800 pass. Zero new colliders, zero per-frame tree walks
## (cached _tracked dict, O(vehicles)), no .tscn edits.

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0
## instance_id -> {node, prev_pos, prev_speed, hold, mat}
var _tracked: Dictionary = {}

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism141") != null:
		return
	var n := Node3D.new()
	n.name = "Realism141"
	n.set_script(load("res://realism141.gd"))
	world.call_deferred("add_child", n)

func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 810:
		_done = true
		_apply(get_parent() as Node3D)
	if _done:
		_update_brakes(delta)
		_scan_t += delta
		if _scan_t >= 1.0:
			_scan_t = 0.0
			_scan_and_dress(get_parent() as Node3D)

func _find_recursive(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f: Node = _find_recursive(c, nm)
		if f != null:
			return f
	return null

func _glow_mat(col: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r * 0.35, col.g * 0.35, col.b * 0.35, 1.0)
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m

func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _hide_wheel_dupes(world: Node3D) -> void:
	var pairs: Array = [
		["Cart", "Wheel71_0", "Wheel71_1", "CartWheelL", "CartWheelR"],
		["Motorcycle", "Wheel71_0", "Wheel71_1", "WheelBike_F", "WheelBike_B"],
	]
	for p in pairs:
		var veh: Node = _find_recursive(world, String(p[0]))
		if veh == null:
			continue
		var keep_a: Node = _find_recursive(veh, String(p[3]))
		var keep_b: Node = _find_recursive(veh, String(p[4]))
		if keep_a == null or keep_b == null:
			continue
		if not (keep_a as Node3D).visible or not (keep_b as Node3D).visible:
			continue
		for wi in [1, 2]:
			var dupe: Node = _find_recursive(veh, String(p[wi]))
			if dupe != null:
				(dupe as Node3D).visible = false

func _bicycle_lamps(world: Node3D) -> void:
	var bike: Node = _find_recursive(world, "Bicycle")
	if bike == null:
		return
	if _find_recursive(bike, "Head141_Bike") != null:
		return
	var wf: Node = _find_recursive(bike, "BikeWheelF")
	var wb: Node = _find_recursive(bike, "BikeWheelB")
	if wf == null or wb == null:
		return
	var fpos: Vector3 = (wf as Node3D).position
	var bpos: Vector3 = (wb as Node3D).position
	var head_mat: StandardMaterial3D = _glow_mat(Color(1.0, 0.9, 0.6, 1.0), 1.2)
	var tail_mat: StandardMaterial3D = _glow_mat(Color(1.0, 0.02, 0.02, 1.0), 1.2)
	_box(bike as Node3D, Vector3(0.12, 0.08, 0.06), head_mat, Vector3(0.0, fpos.y + 0.6, fpos.z - 0.15), "Head141_Bike")
	_box(bike as Node3D, Vector3(0.12, 0.08, 0.06), tail_mat, Vector3(0.0, bpos.y + 0.6, bpos.z + 0.15), "Tail141_Bike")

func _dress_bus(veh: Node3D) -> void:
	if veh == null or veh.has_meta("dressed141"):
		return
	var tail_names: Array = []
	if String(veh.name) == "Bus":
		tail_names = ["BusTailL74", "BusTailR74"]
	elif String(veh.name) == "Minibus":
		tail_names = ["MiniTailL81", "MiniTailR81"]
	else:
		return
	var meshes: Array = []
	for tn in tail_names:
		var m: Node = _find_recursive(veh, String(tn))
		if m != null and m is MeshInstance3D:
			meshes.append(m as MeshInstance3D)
	if meshes.is_empty():
		return
	var src: MeshInstance3D = meshes[0]
	var src_mat: Material = src.get_surface_override_material(0)
	if src_mat == null:
		src_mat = src.material_override
	var clone: StandardMaterial3D = null
	if src_mat is StandardMaterial3D:
		clone = (src_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
	else:
		clone = StandardMaterial3D.new()
	clone.emission_enabled = true
	clone.emission = Color(1.0, 0.02, 0.02, 1.0)
	clone.emission_energy_multiplier = 0.25
	for mi in meshes:
		(mi as MeshInstance3D).set_surface_override_material(0, clone)
	veh.set_meta("dressed141", true)
	_tracked[veh.get_instance_id()] = {
		"node": veh,
		"prev_pos": veh.global_position,
		"prev_speed": 0.0,
		"hold": 0.0,
		"deb": 0,
		"mat": clone,
	}

func _scan_and_dress(world: Node3D) -> void:
	if world == null:
		return
	for vn in ["Bus", "Minibus"]:
		var veh: Node = _find_recursive(world, vn)
		if veh != null:
			_dress_bus(veh as Node3D)

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_hide_wheel_dupes(world)
	_bicycle_lamps(world)
	_scan_and_dress(world)

func _update_brakes(delta: float) -> void:
	if delta <= 0.0:
		return
	var dead: Array = []
	for id in _tracked.keys():
		var tr: Dictionary = _tracked[id]
		var veh = tr["node"]
		if veh == null or not is_instance_valid(veh):
			dead.append(id)
			continue
		var pos: Vector3 = (veh as Node3D).global_position
		var prev_pos: Vector3 = tr["prev_pos"]
		var dist := (pos - prev_pos).length()
		var int_speed = (veh as Node).get("speed")
		if int_speed == null and dist > 20.0:
			tr["prev_pos"] = pos
			tr["prev_speed"] = 0.0
			tr["hold"] = 0.0
			_set_bright(tr["mat"], false)
			continue
		var speed: float = 0.0
		if int_speed != null:
			speed = absf(float(int_speed))
		else:
			speed = dist / delta
		var prev_speed: float = tr["prev_speed"]
		var decel := (prev_speed - speed) / delta
		var hold: float = tr["hold"]
		var deb: int = tr["deb"]
		if decel > 1.0:
			deb += 1
			if deb >= 3:
				hold = 1.0
		else:
			deb = 0
			if hold > 0.0 and speed >= 0.1:
				hold = maxf(0.0, hold - delta)
		tr["hold"] = hold
		tr["deb"] = deb
		_set_bright(tr["mat"], hold > 0.0)
		tr["prev_pos"] = pos
		tr["prev_speed"] = speed
	for id in dead:
		_tracked.erase(id)

static func _set_bright(mat: StandardMaterial3D, bright: bool) -> void:
	mat.emission_energy_multiplier = 2.5 if bright else 0.25
