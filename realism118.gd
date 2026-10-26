## Slice 117: traffic brake lights (harsh senior mode).
##
## GAP FOUND BY AUDIT (measured, not invented): traffic cars and vans
## have NO taillight meshes at all and NO brake visualization, even
## though traffic_car.gd has real deceleration (brake_rate 9.0, speed
## cut when blocked or when the wanted speed drops). Base scenes
## carry body + cabin + 4 wheels + 2 headlights only; the S112
## reshape (Tub112C/V) and S115 reshape + drivers add no tail
## lights either. So a braking traffic car at night shows nothing
## behind it. This pass adds 2 taillight lenses per traffic vehicle
## whose brightness is DRIVEN BY MEASURED DECELERATION, not a
## static prop: dim while cruising, bright while the vehicle's own
## position-delta speed is falling faster than 1.0 m/s^2, with a
## 1.0 s brake-hold after the last deceleration so a car stopped
## in a jam keeps its lights on (as a real held brake does).
##
## PLACEMENT (vehicle-local, forward is +z per traffic_car.gd
## _forward(); rear face is -z). Verified against live geometry:
## reshaped car tub Tub112C/Tub116C is 1.36 x 0.5 x 3.12 at y 0.55
## (rear face z -1.56) and original car body is 1.4 x 0.55 x 3.2 at
## y 0.55 (rear face z -1.60); reshaped van tub Tub112V is
## 1.66 x 0.85 x 4.32 at y 0.65 (rear face z -2.16) and original van
## body is 1.7 x 0.9 x 4.4 at y 0.65 (rear face z -2.20). Lenses sit
## 0.02-0.04 proud of either rear face so they read on reshaped
## AND not-yet-reshaped bodies: cars z -1.60, vans z -2.20.
## x inset 0.13 from each tub half-width (cars +-0.55, vans +-0.70).
##
## SCOPE, HONEST: one working system, not N items. 2 meshes per
## live traffic vehicle (10 manager slots + 6 long-route cars at
## most), dynamic 1.0 s re-scan so manager refills and depot
## unparking gain lights when they appear. Zero new colliders
## (MeshInstance3D only, children of their vehicles, so they
## follow). No bus-system changes, minibus/big bus untouched
## (Slice 81 limit), no player-car changes (its Taillight71 meshes
## already exist; this pass covers the traffic fleet only, which
## had none). No .tscn edits. Runs at frame >= 560, after
## realism117's 540 pass.
extends Node3D

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0
## instance_id -> {node, prev_pos, prev_speed, hold, mat}
var _tracked: Dictionary = {}

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism118") != null:
		return
	var n := Node3D.new()
	n.name = "Realism118"
	n.set_script(load("res://realism118.gd"))
	world.call_deferred("add_child", n)

func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 560:
		_done = true
		_apply(get_parent() as Node3D)
	if _done:
		_update_brakes(delta)
	_scan_t += delta
	if _scan_t >= 1.0:
		_scan_t = 0.0
		if _done:
			_scan_and_dress(get_parent() as Node3D)

func _apply(world: Node3D) -> void:
	if world == null:
		return
	for veh in _scan(world):
		_dress(veh)

func _scan_and_dress(world: Node3D) -> void:
	if world == null:
		return
	for veh in _scan(world):
		_dress(veh)

## Vehicle-root match only (digits suffix): driver-part children
## are named "TrafficCar0_Torso116" etc. and MUST NOT be dressed
## — a prefix match would hang taillights on the driver figures
## themselves. Slots are 0-9, long-route cars 0-5, so a digits-only
## suffix is exact for every real traffic vehicle.
static func _is_traffic_vehicle(nm: String) -> bool:
	if nm.begins_with("TrafficCar") or nm.begins_with("TrafficVan"):
		return nm.substr(10).is_valid_int()
	if nm.begins_with("LongTraffic76_"):
		return nm.substr(14).is_valid_int()
	return false

static func _scan(world: Node3D) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array = [world]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is Node3D):
			continue
		if not _is_traffic_vehicle(String(n.name)):
			continue
		if n.has_meta("dressed118"):
			continue
		out.append(n)
	return out

static func _mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.02, 0.02, 1.0)
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = Color(1.0, 0.02, 0.02, 1.0)
	m.emission_energy_multiplier = 0.25
	return m

static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _dress(veh: Node3D) -> void:
	if veh == null or veh.has_meta("dressed118"):
		return
	var is_van := String(veh.name).begins_with("TrafficVan")
	var mat := _mat()
	var x := 0.70 if is_van else 0.55
	var y := 0.65 if is_van else 0.55
	var z := -2.20 if is_van else -1.60
	_box(veh, Vector3(0.22, 0.12, 0.06), mat, Vector3(-x, y, z), "Tail118_L")
	_box(veh, Vector3(0.22, 0.12, 0.06), mat, Vector3(x, y, z), "Tail118_R")
	veh.set_meta("dressed118", true)
	_tracked[veh.get_instance_id()] = {
		"node": veh,
		"prev_pos": veh.global_position,
		"prev_speed": 0.0,
		"hold": 0.0,
		"mat": mat,
	}

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
		if dist > 20.0:
			# Respawn / teleport jump, not driving: reset, no flash.
			tr["prev_pos"] = pos
			tr["prev_speed"] = 0.0
			tr["hold"] = 0.0
			_set_bright(tr["mat"], false)
			continue
		var speed := dist / delta
		var prev_speed: float = tr["prev_speed"]
		var decel := (prev_speed - speed) / delta
		var hold: float = tr["hold"]
		if decel > 1.0:
			hold = 1.0
		elif hold > 0.0 and speed >= 0.1:
			# Slice 135: a car stopped in a jam keeps its brake lights
			# on while it sits stopped. The old code decayed the 1.0 s
			# hold even at speed 0, so a queue stopped > 1 s read dim
			# (audit135 sample2: stopped 3.7 s, tail 0.25) despite the
			# S117 header's stated intent. Hold resumes decaying once
			# the car moves again, so the light still clears ~1 s after
			# pull-away; a car that spawns stopped (hold 0) stays dim.
			hold = maxf(0.0, hold - delta)
		tr["hold"] = hold
		_set_bright(tr["mat"], hold > 0.0)
		tr["prev_pos"] = pos
		tr["prev_speed"] = speed
	for id in dead:
		_tracked.erase(id)

static func _set_bright(mat: StandardMaterial3D, bright: bool) -> void:
	mat.emission_energy_multiplier = 2.5 if bright else 0.25
