extends Node3D
## Slice 123 graphics + motorcycle brake light (System v2,
## target-first: judged by what changes at 6 m phone distance,
## NOT by item count). OWNER RE-POINT 2026-10-26: work does NOT
## wait for the S122 verdict — this slice starts now.
## AUDIT (audit123 + audit123_speed, live headless, S122
## dressing complete — every choice below traces to a number):
## - WORLD: 12,070 meshes, 9,879 visible, 7,564 boxes (S122's
##   11,832 + 238, exactly as shipped — no drift).
## - GROUND, TOP GAP: every stop has its S122 apron (3 variant
##   nodes within 15 m) but EVERYTHING between stops is bare
##   sheet — all 5 stop-midpoints 0, all 4 loop-slab shoulders
##   0/0, spur road centre 0. FIX: 54 shoulder patches along
##   the live route (sorted stops 500-2400 at z=0), the 4 live
##   loop slabs, and the spur road — offset 10 m, size <= 6 m,
##   so no patch touches a 12 m-wide road (inner edge 7 m).
## - TREES, AUDIT-DISPROVED (NOT shipped): 157 eligible
##   trunks, 140 Canopy122, covered 140/140; the 17 uncovered
##   trunks are ALL > 60 m from every anchor — canopy round 2
##   would be invisible padding, so it is refused.
## - HOUSES: MDHouse11/12/13/14 (6 colours, same builder class
##   as S122's trimmed 4/5/7/9) and HamletHouse75_0..3 (7-10
##   colours, but the WALL FACE is still one flat colour) are
##   untrimmed. FIX: S122 kind-2 trim (plinth + 4 corners),
##   5 pieces x 8 houses = 40. EXCLUDED, UNTOUCHED:
##   MDHouse1/2/3/6/10 (S103 permanent bare), MDHouse8
##   (MindonPost overlap), all S122-trimmed houses.
## - MOTORCYCLE BRAKE LIGHT, DEFERRAL OVERTURNED BY EVIDENCE:
##   S118 said the bike has "NO tail mesh at all (realism93
##   gives it fenders only)". The live audit PROVES otherwise:
##   Tail99_Moto EXISTS (realism99.gd:246, box 0.22x0.12x0.06
##   red glow at local (0, 0.15, 1.05), rear face, above the
##   rear plate, behind the rear fender tip) — S118's grep
##   missed it because it searched for a drive, not the mesh.
##   FIX: drive Tail99 with the S118 system (measured
##   deceleration > 1.0 m/s^2, 1.0 s hold, teleport guard).
##   Dim = 1.2 (its authored _glow_mat base, unchanged — the
##   tuk precedent, NOT the car's 0.25, which would dim an
##   existing look); bright = 2.5 (system standard). LIMIT,
##   STATED: 1.2 -> 2.5 is only a 2x step (car is 10x), so in
##   bright daylight the change is subtler than the car's;
##   at night/dusk it is clear. Material is CLONED before
##   driving so no other mesh can ever share the modulation.
## - DRIVING TUNING, MEASURED AND LEFT UNCHANGED (second
##   time, now with the softening candidate tested): accel
##   0.073/step launch ramp, top speed 13.54 in 137 steps,
##   brake 16/s with correct reverse-from-near-stop, steer
##   ramp monotonic at max 0.133/step, speed-sensitive yaw
##   0.0340 low-speed -> 0.0142 high-speed (-58%, works).
##   steer_response 8.0 vs 6.0 vs 5.0: steer-angle step falls
##   -25%/-37% BUT yaw step barely moves (-1.4%/-2.6%) and
##   full lock slows 7 -> 9 -> 11 steps with settling lag.
##   Softening the wheel ramp does NOT smooth the heading
##   change the player feels, so it is REJECTED, not shipped.
##   car.gd is NOT touched. NEXT TARGET if the owner still
##   feels driving jerk on the phone: input-side (joystick
##   quantization/deadzone) or the S122 camera smoothing's
##   phone verdict — NOT these tuning curves.
## PERFORMANCE NOTE: names (Ground123_, Trim123_) match NONE
## of perf120's hide prefixes, so they stay visible always.
## Total added: 54 + 40 = 94 meshes (+1.0% of visible), zero
## colliders, StandardMaterial3D only. Brake tracking is ONE
## vehicle, O(1) position-delta math per frame — no tree
## walk, no light-visibility writes (emission only, and only
## on state change, unlike S118's every-frame write).
## Runs once at frame >= 640 (after Realism122's 620 pass).

var _frames: int = 0
var _done: bool = false
var _bike: Node3D = null
var _bike_mat: StandardMaterial3D = null
var _bike_prev_pos := Vector3.ZERO
var _bike_prev_speed := 0.0
var _bike_hold := 0.0
var _bike_bright := false
const _BIKE_DIM := 1.2

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism123") != null:
		return
	var n := Node3D.new()
	n.name = "Realism123"
	n.set_script(load("res://realism123.gd"))
	world.call_deferred("add_child", n)

func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 640:
		_done = true
		_apply(get_parent() as Node3D)
	if _done:
		_update_brakes(delta)

static func _mat(c: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _find_all_prefix(node: Node, prefix: String, out: Array) -> void:
	if String(node.name).begins_with(prefix):
		out.append(node)
	for c in node.get_children():
		_find_all_prefix(c, prefix, out)

func _ground(world: Node3D) -> int:
	var n := 0
	var dirt := _mat(Color(0.52, 0.42, 0.30))
	var dirt2 := _mat(Color(0.45, 0.35, 0.25))
	var dry := _mat(Color(0.62, 0.55, 0.38))
	var mats: Array = [dirt, dirt2, dry]
	var gy := 0.0
	var gm: Node3D = world.get_node_or_null("GroundMesh") as Node3D
	if gm != null:
		gy = gm.global_position.y
	# Main route: live stops sorted by x (all at z=0, verified
	# by audit123: 500/700/1200/1700/2200/2400).
	var stops: Array = []
	for i in range(6):
		var s: Node3D = world.get_node_or_null("LongRoute74/BusStop74_%d" % i) as Node3D
		if s != null:
			stops.append(s.global_position)
	stops.sort_custom(func(a, b): return float(a.x) < float(b.x))
	var cell := 0
	for si in range(stops.size() - 1):
		var a: Vector3 = stops[si]
		var b: Vector3 = stops[si + 1]
		var seg_len := b.x - a.x
		var cells := int(seg_len / 50.0)
		for k in range(cells):
			var cx := a.x + (float(k) + 0.5) * 50.0
			var side := 1.0 if cell % 2 == 0 else -1.0
			var sz := 5.0 + float(cell % 3) * 0.5
			_box(self, Vector3(sz, 0.06, sz), mats[cell % 3],
				Vector3(cx, gy + 0.03, side * 10.0), "Ground123_route_%d" % cell)
			n += 1
			cell += 1
	# Loop slabs: live nodes, shoulders at true perpendicular
	# (local +Z maps to (sin ry, 0, cos ry)).
	var slabs: Array = []
	_find_all_prefix(world, "LoopSlab75_", slabs)
	var li := 0
	for s in slabs:
		var sn: Node3D = s as Node3D
		var mp: Vector3 = sn.global_position
		var ry: float = sn.rotation.y
		var perp: Vector3 = Vector3(sin(ry), 0.0, cos(ry))
		for side in [1.0, -1.0]:
			var p: Vector3 = mp + perp * (side * 10.0)
			_box(self, Vector3(6.0 if li % 2 == 0 else 5.5, 0.06, 6.0 if li % 2 == 0 else 5.5),
				mats[li % 3], Vector3(p.x, gy + 0.03, p.z),
				"Ground123_loop_%s_%d" % [String(sn.name), li])
			n += 1
			li += 1
	# Spur road: box (12 wide in x, 54 in z) centred (2100, 33),
	# so shoulders at x = 2100 +/- 10 flank it with clearance.
	for zi in range(4):
		var z := 12.0 + float(zi) * 12.0
		for side in [1.0, -1.0]:
			_box(self, Vector3(5.5, 0.06, 5.5), mats[(zi + (1 if side > 0.0 else 0)) % 3],
				Vector3(2100.0 + side * 10.0, gy + 0.03, z),
				"Ground123_spur_%d_%d" % [zi, 1 if side > 0.0 else 0])
			n += 1
	return n

func _trim_house(holder: Node3D, walls: MeshInstance3D) -> int:
	var n := 0
	var wsize: Vector3 = walls.mesh.get_aabb().size
	var wpos: Vector3 = walls.position
	var dark := _mat(Color(0.30, 0.22, 0.14))
	var white := _mat(Color(0.95, 0.93, 0.85))
	var tag := String(holder.name)
	_box(holder, Vector3(wsize.x + 0.12, 0.25, wsize.z + 0.12), dark,
		Vector3(wpos.x, wpos.y - wsize.y * 0.5 + 0.125, wpos.z), "Trim123_%s_plinth" % tag)
	n += 1
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(holder, Vector3(0.14, wsize.y, 0.14), white,
				Vector3(wpos.x + sx * wsize.x * 0.5, wpos.y, wpos.z + sz * wsize.z * 0.5),
				"Trim123_%s_corner_%d_%d" % [tag, int(sx), int(sz)])
			n += 1
	return n

func _trim(world: Node3D) -> int:
	var n := 0
	var targets: Array = ["MDHouse11", "MDHouse12", "MDHouse13", "MDHouse14",
		"HamletHouse75_0", "HamletHouse75_1", "HamletHouse75_2", "HamletHouse75_3"]
	var stack: Array = [world]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if not (x is Node3D):
			continue
		if not targets.has(String(x.name)):
			continue
		var holder: Node3D = x as Node3D
		var walls: MeshInstance3D = null
		for c in holder.get_children():
			if c is MeshInstance3D and String(c.name).contains("Walls"):
				walls = c as MeshInstance3D
				break
		if walls != null and walls.mesh != null:
			n += _trim_house(holder, walls)
	return n

func _brake_apply(world: Node3D) -> bool:
	var bike: Node3D = world.get_node_or_null("Motorcycle") as Node3D
	if bike == null:
		return false
	var tail: MeshInstance3D = bike.get_node_or_null("Tail99_Moto") as MeshInstance3D
	if tail == null:
		return false
	var m: StandardMaterial3D = tail.get_surface_override_material(0) as StandardMaterial3D
	if m == null:
		return false
	# Clone: the driven material must belong to Tail99 alone.
	var clone: StandardMaterial3D = m.duplicate() as StandardMaterial3D
	tail.set_surface_override_material(0, clone)
	clone.emission_enabled = true
	clone.emission = Color(1.0, 0.10, 0.10, 1.0)
	clone.emission_energy_multiplier = _BIKE_DIM
	_bike = bike
	_bike_mat = clone
	_bike_prev_pos = bike.global_position
	_bike_prev_speed = 0.0
	_bike_hold = 0.0
	_bike_bright = false
	return true

func _update_brakes(delta: float) -> void:
	if _bike == null or _bike_mat == null or delta <= 0.0:
		return
	if not is_instance_valid(_bike):
		_bike = null
		return
	var pos: Vector3 = _bike.global_position
	var dist := (pos - _bike_prev_pos).length()
	if dist > 20.0:
		# Teleport / respawn jump, not driving: reset, no flash.
		_bike_prev_pos = pos
		_bike_prev_speed = 0.0
		_bike_hold = 0.0
		_set_bike_bright(false)
		return
	var speed := dist / delta
	var decel := (_bike_prev_speed - speed) / delta
	if decel > 1.0:
		_bike_hold = 1.0
	elif _bike_hold > 0.0:
		_bike_hold = maxf(0.0, _bike_hold - delta)
	_set_bike_bright(_bike_hold > 0.0)
	_bike_prev_pos = pos
	_bike_prev_speed = speed

func _set_bike_bright(bright: bool) -> void:
	if _bike_mat == null or _bike_bright == bright:
		return
	_bike_bright = bright
	_bike_mat.emission_energy_multiplier = 2.5 if bright else _BIKE_DIM

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var g := _ground(world)
	var t := _trim(world)
	var b := _brake_apply(world)
	print("REALISM123 dressed: ground=", g, " trim=", t, " bike_brake=", b)
