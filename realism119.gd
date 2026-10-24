## Slice 118: player-vehicle brake lights (harsh senior mode).
##
## GAP FOUND BY AUDIT (measured, not invented): the player car and the
## tuk-tuk HAVE tail meshes but ZERO brake visualization. The car
## carries Taillight71_L/R at (+/-0.6, -0.12, 2.02) (realism71.gd:218-219,
## static red boxes, NO emission at all) and the tuk-tuk carries
## Tail93_L/R at (+/-0.5, 0.30, 1.22) (realism93.gd:333-334, dim red
## glow at energy 0.6) — and a repo-wide grep finds NO code anywhere
## that modulates either material after creation. So the two vehicles
## the player drives most, viewed from the TPP camera 6 m behind them,
## show nothing when they brake. Slice 117 explicitly deferred this
## ("no player-car changes (its Taillight71 meshes already exist);
## this pass covers the traffic fleet only, which had none)" —
## realism118.gd header); this pass completes it.
##
## WHAT IT DOES (one working system, S117 semantics, no new meshes):
## the existing tail materials are driven by MEASURED deceleration —
## dim while cruising, bright while the vehicle's own position-delta
## speed is falling faster than 1.0 m/s^2, with a 1.0 s brake-hold
## after the last deceleration so a car stopped at a light keeps its
## lights on briefly. Car dim = 0.25 (S117 dim semantics; its boxes
## had no emission, so emission is enabled here with the boxes'
## own red albedo as the emission color), tuk dim = 0.6 (its authored
## base value, unchanged), bright = 2.5 for both.
##
## NOTES (all measured): player-car forward is -z (headlights at
## z -2.02, taillights at z +2.02) and tuk forward is -z too (headlight
## at z -1.25, tails at z +1.22) — but speed here is a SCALAR
## position delta, so the convention cannot affect the result. The
## L/R boxes share one material instance each (set via
## set_surface_override_material in _box), so modulating the shared
## instance brightens both sides together, as a real brake circuit
## does. No new colliders, no controller/tuning/seat changes, no
## .tscn edits. Runs at frame >= 580, after realism118's 560 pass.
##
## SCOPE, HONEST: car + tuk-tuk only. Motorcycle deferred WITH A
## REASON (not silently): it has NO tail mesh at all (realism93
## gives it fenders only), so it needs its own placement audit
## against live geometry rather than a drive of an existing mesh.
## Bus system, minibus, big bus untouched (Slice 81 limit). Any new
## gameplay system: none ordered.
extends Node3D

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0
## instance_id -> {node, prev_pos, prev_speed, hold, mats, dim}
var _tracked: Dictionary = {}

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism119") != null:
		return
	var n := Node3D.new()
	n.name = "Realism119"
	n.set_script(load("res://realism119.gd"))
	world.call_deferred("add_child", n)

func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 580:
		_done = true
		_apply(get_parent() as Node3D)
	if _done:
		_update_brakes(delta)
	_scan_t += delta
	if _scan_t >= 1.0:
		_scan_t = 0.0
		if _done:
			_apply(get_parent() as Node3D)

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_try_vehicle(world, "Car", 0.25)
	_try_vehicle(world, "TukTuk", 0.6)

func _try_vehicle(world: Node3D, nm: String, dim: float) -> void:
	var veh := world.get_node_or_null(nm) as Node3D
	if veh == null or veh.has_meta("dressed119"):
		return
	var tail_names: Array = []
	if nm == "Car":
		tail_names = ["Taillight71_L", "Taillight71_R"]
	else:
		tail_names = ["Tail93_L", "Tail93_R"]
	var mats: Array = []
	for tn in tail_names:
		var mi := veh.get_node_or_null(tn) as MeshInstance3D
		if mi == null:
			continue
		var m := mi.get_surface_override_material(0) as StandardMaterial3D
		if m != null and not mats.has(m):
			mats.append(m)
	if mats.is_empty():
		return
	for m in mats:
		m.emission_enabled = true
		if nm == "Car":
			m.emission = Color(0.75, 0.08, 0.08, 1.0)
		m.emission_energy_multiplier = dim
	veh.set_meta("dressed119", true)
	_tracked[veh.get_instance_id()] = {
		"node": veh,
		"prev_pos": veh.global_position,
		"prev_speed": 0.0,
		"hold": 0.0,
		"mats": mats,
		"dim": dim,
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
			_set_bright(tr["mats"], tr["dim"], false)
			continue
		var speed := dist / delta
		var prev_speed: float = tr["prev_speed"]
		var decel := (prev_speed - speed) / delta
		var hold: float = tr["hold"]
		if decel > 1.0:
			hold = 1.0
		elif hold > 0.0:
			hold = maxf(0.0, hold - delta)
		tr["hold"] = hold
		_set_bright(tr["mats"], tr["dim"], hold > 0.0)
		tr["prev_pos"] = pos
		tr["prev_speed"] = speed
	for id in dead:
		_tracked.erase(id)

static func _set_bright(mats: Array, dim: float, bright: bool) -> void:
	for m in mats:
		(m as StandardMaterial3D).emission_energy_multiplier = 2.5 if bright else dim
