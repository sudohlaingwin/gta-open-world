extends Node3D

## Slice 114 — SUPERIOR BUILD, harsh senior mode (owner order
## 2026-10-24 11:39 +07). Audit-first: every item below was
## live-probed MISSING before adding (audit115 + audit115b
## outputs: seat/handle/saddle/bench positions read from the
## live world at frame 560, after all earlier dressing passes).
## This slice completes what Slice 113 started: bus + minibus
## got driver figures in S113; every OTHER rideable was still
## driverless in TPP — the vehicle drove away with an empty
## seat. 13 figures, S113 pattern exactly: STATIC seated poses
## (no animation, present whether or not the player drives),
## children of their vehicles so they follow, 8 parts each
## (torso, head, 2 arms reaching toward the controls, 2 thighs,
## 2 shins), ZERO new colliders, collider/tuning/controller/
## door/seats/sign/lamp untouched. NO scene edits, NO .tscn
## edits, no bus-system changes, minibus NOT rewired, big bus
## NOT rewired (Slice 81 limit), touch controls untouched,
## StandardMaterial3D only, no dead specular lines, no fog/
## SSAO/glow claims (no WorldEnvironment exists), no
## photorealism claims: stylised smooth procedural work.
## Runs at frame >= 500, after realism114's 480 pass.
## HONEST COUNT: 13 figures — UNDER the ~50 target, NO
## padding. Deliberately NOT added, with measured reasons:
## CAR DRIVER — the S95 cabin has only ~0.45 m local headroom
## (tub top 0.045 to roof underside 0.495) and a 0.32-tall
## window band; a readable figure cannot fit without clipping
## the roof, and would hide behind the roof line. Forcing one
## would be padding, not improvement. BUS/MINIBUS DRIVERS —
## already present since S113 (re-proved in SIM115).
## HONEST LIMITS, same as S113: figures are STATIC poses;
## the in-vehicle FPP eye sits at vehicle origin + 1.5 m (not
## at the seat), so each figure reads below/around the FPP
## centre, never blocking it (eye heights checked per vehicle
## in SIM115). The airplane pilot's torso base overlaps the
## Glass99_Plane canopy by 0.05 m (torso bottom 0.60 vs canopy
## top 0.65); the canopy is transparent glass, so the overlap
## reads as sitting IN the cockpit opening, not as a clip
## through solid bodywork — stated, not hidden.

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism115") != null:
		return
	var n := Node3D.new()
	n.name = "Realism115"
	n.set_script(load("res://realism115.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 500:
		_done = true
		_apply(get_parent() as Node3D)

static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

static func _sph(parent: Node, r: float, mat: Material, pos: Vector3, nm: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

# One 8-part figure. Torso/head vertical, arms reach toward
# (ax, ay, az) controls, thighs point toward (tx, tz), shins
# drop to (sy). All coords are vehicle-local; forward sign is
# carried by the caller through arm/thigh z placement.
static func _figure(parent: Node, pfx: String, shirt: Material, skin: Material, dark: Material, torso_pos: Vector3, torso_size: Vector3, head_pos: Vector3, head_r: float, arm_pos_l: Vector3, arm_pos_r: Vector3, arm_size: Vector3, thigh_pos_l: Vector3, thigh_pos_r: Vector3, thigh_size: Vector3, shin_pos_l: Vector3, shin_pos_r: Vector3, shin_size: Vector3) -> void:
	_box(parent, torso_size, shirt, torso_pos, pfx + "Torso115")
	_sph(parent, head_r, skin, head_pos, pfx + "Head115")
	_box(parent, arm_size, shirt, arm_pos_l, pfx + "Arm115_L")
	_box(parent, arm_size, shirt, arm_pos_r, pfx + "Arm115_R")
	_box(parent, thigh_size, dark, thigh_pos_l, pfx + "Thigh115_L")
	_box(parent, thigh_size, dark, thigh_pos_r, pfx + "Thigh115_R")
	_box(parent, shin_size, dark, shin_pos_l, pfx + "Shin115_L")
	_box(parent, shin_size, dark, shin_pos_r, pfx + "Shin115_R")

func _apply(world: Node3D) -> void:
	var shirt := _mat(Color(0.15, 0.25, 0.5, 1.0), 0.8)
	var skin := _mat(Color(0.85, 0.65, 0.5, 1.0), 0.8)
	var dark := _mat(Color(0.2, 0.2, 0.25, 1.0), 0.8)
	var moto := world.get_node_or_null("Motorcycle") as Node3D
	if moto != null:
		# Seat (0, 0.45, 0.3), bars (0, 0.48, -0.7), forward -z.
		_figure(moto, "Moto", shirt, skin, dark,
			Vector3(0, 0.78, 0.3), Vector3(0.40, 0.55, 0.26),
			Vector3(0, 1.18, 0.3), 0.13,
			Vector3(-0.18, 0.75, -0.20), Vector3(0.18, 0.75, -0.20), Vector3(0.08, 0.08, 0.80),
			Vector3(-0.13, 0.55, 0.05), Vector3(0.13, 0.55, 0.05), Vector3(0.15, 0.12, 0.50),
			Vector3(-0.14, 0.30, -0.10), Vector3(0.14, 0.30, -0.10), Vector3(0.13, 0.50, 0.13))
	var tuk := world.get_node_or_null("TukTuk") as Node3D
	if tuk != null:
		# Seat (0, 0.55, 0.4), front wheel z -1.1, forward -z.
		_figure(tuk, "Tuk", shirt, skin, dark,
			Vector3(0, 0.90, 0.40), Vector3(0.42, 0.55, 0.28),
			Vector3(0, 1.30, 0.40), 0.14,
			Vector3(-0.20, 1.00, 0.05), Vector3(0.20, 1.00, 0.05), Vector3(0.08, 0.08, 0.55),
			Vector3(-0.13, 0.62, 0.15), Vector3(0.13, 0.62, 0.15), Vector3(0.15, 0.12, 0.45),
			Vector3(-0.13, 0.40, -0.05), Vector3(0.13, 0.40, -0.05), Vector3(0.13, 0.50, 0.13))
	var cart := world.get_node_or_null("Cart") as Node3D
	if cart != null:
		# Bench seat (0, 0.7, -1.4), back (0, 0.95, -1.18),
		# driver faces +z (backrest is on the -z side).
		_figure(cart, "Cart", shirt, skin, dark,
			Vector3(0, 1.05, -1.40), Vector3(0.42, 0.55, 0.28),
			Vector3(0, 1.45, -1.40), 0.14,
			Vector3(-0.20, 1.10, -1.00), Vector3(0.20, 1.10, -1.00), Vector3(0.08, 0.08, 0.60),
			Vector3(-0.13, 0.78, -1.10), Vector3(0.13, 0.78, -1.10), Vector3(0.15, 0.12, 0.50),
			Vector3(-0.13, 0.50, -0.90), Vector3(0.13, 0.50, -0.90), Vector3(0.13, 0.50, 0.13))
	var bike := world.get_node_or_null("Bicycle") as Node3D
	if bike != null:
		# Seat (0, 0.95, 0.45), handle (0, 0.9, -0.55),
		# pedals (+-0.28, 0.42, 0), forward -z.
		_figure(bike, "Bike", shirt, skin, dark,
			Vector3(0, 1.28, 0.45), Vector3(0.38, 0.55, 0.26),
			Vector3(0, 1.66, 0.45), 0.13,
			Vector3(-0.18, 1.15, -0.05), Vector3(0.18, 1.15, -0.05), Vector3(0.07, 0.07, 0.80),
			Vector3(-0.13, 1.02, 0.20), Vector3(0.13, 1.02, 0.20), Vector3(0.14, 0.11, 0.45),
			Vector3(-0.20, 0.70, 0.05), Vector3(0.20, 0.70, 0.05), Vector3(0.12, 0.55, 0.12))
	for bn in ["Boat", "Boat2"]:
		var boat := world.get_node_or_null(bn) as Node3D
		if boat == null:
			continue
		# Rear bench (0, 0.55, 0.6), bow -z, oars at
		# (+-0.8, 0.45, 0.3): arms reach sideways to the oars.
		var pfx := "Boat" if bn == "Boat" else "Boat2"
		_figure(boat, pfx, shirt, skin, dark,
			Vector3(0, 0.88, 0.60), Vector3(0.42, 0.55, 0.28),
			Vector3(0, 1.28, 0.60), 0.14,
			Vector3(-0.45, 0.75, 0.45), Vector3(0.45, 0.75, 0.45), Vector3(0.70, 0.08, 0.08),
			Vector3(-0.13, 0.62, 0.30), Vector3(0.13, 0.62, 0.30), Vector3(0.15, 0.12, 0.50),
			Vector3(-0.13, 0.40, 0.15), Vector3(0.13, 0.40, 0.15), Vector3(0.13, 0.50, 0.13))
	for hn in ["Horse", "Horse2"]:
		var horse := world.get_node_or_null(hn) as Node3D
		if horse == null:
			continue
		# Saddle (0, 2.02, 0.1), head (0, 1.9, -1.2),
		# stirrups (+-0.52, 1.55, 0.1), forward -z.
		var pfx := "Horse" if hn == "Horse" else "Horse2"
		_figure(horse, pfx, shirt, skin, dark,
			Vector3(0, 2.38, 0.10), Vector3(0.42, 0.55, 0.28),
			Vector3(0, 2.78, 0.10), 0.14,
			Vector3(-0.20, 2.45, -0.35), Vector3(0.20, 2.45, -0.35), Vector3(0.08, 0.08, 0.70),
			Vector3(-0.38, 1.95, 0.10), Vector3(0.38, 1.95, 0.10), Vector3(0.14, 0.40, 0.16),
			Vector3(-0.50, 1.60, 0.10), Vector3(0.50, 1.60, 0.10), Vector3(0.12, 0.50, 0.12))
	var ele := world.get_node_or_null("Elephant") as Node3D
	if ele != null:
		# Howdah (0, 2.75, 0.1), roof underside ~3.55:
		# head top 3.54 clears it by 0.01 — tight, measured.
		_figure(ele, "Ele", shirt, skin, dark,
			Vector3(0, 3.08, 0.10), Vector3(0.42, 0.50, 0.28),
			Vector3(0, 3.42, 0.10), 0.12,
			Vector3(-0.20, 3.15, -0.25), Vector3(0.20, 3.15, -0.25), Vector3(0.08, 0.08, 0.60),
			Vector3(-0.13, 2.82, -0.15), Vector3(0.13, 2.82, -0.15), Vector3(0.15, 0.12, 0.45),
			Vector3(-0.13, 2.70, -0.30), Vector3(0.13, 2.70, -0.30), Vector3(0.13, 0.40, 0.13))
	for cn in ["Cow", "Cow2"]:
		var cow := world.get_node_or_null(cn) as Node3D
		if cow == null:
			continue
		# Cow saddle (0, 0.55, 0); Cow2 has no saddle node
		# but S113 proved identical body/scale/transform, so
		# the same local coords apply. Head end +z (bell at
		# z 0.55, reins at z 0.375), so the rider faces +z.
		var pfx := "Cow" if cn == "Cow" else "Cow2"
		_figure(cow, pfx, shirt, skin, dark,
			Vector3(0, 0.88, 0.00), Vector3(0.42, 0.55, 0.28),
			Vector3(0, 1.28, 0.00), 0.14,
			Vector3(-0.20, 0.95, 0.30), Vector3(0.20, 0.95, 0.30), Vector3(0.08, 0.08, 0.60),
			Vector3(-0.13, 0.62, 0.25), Vector3(0.13, 0.62, 0.25), Vector3(0.15, 0.12, 0.45),
			Vector3(-0.13, 0.40, 0.10), Vector3(0.13, 0.40, 0.10), Vector3(0.13, 0.50, 0.13))
	var heli := world.get_node_or_null("Helicopter") as Node3D
	if heli != null:
		# Open front cockpit: tub top 0.05, windshield at
		# (0, 0.15, -2.02), roof front edge z -1 — the pilot
		# at z -1.2 sits ahead of the roof, no roof conflict.
		_figure(heli, "Heli", shirt, skin, dark,
			Vector3(0, 0.35, -1.20), Vector3(0.42, 0.55, 0.28),
			Vector3(0, 0.72, -1.20), 0.13,
			Vector3(-0.20, 0.42, -1.55), Vector3(0.20, 0.42, -1.55), Vector3(0.08, 0.08, 0.50),
			Vector3(-0.13, 0.12, -1.45), Vector3(0.13, 0.12, -1.45), Vector3(0.15, 0.12, 0.40),
			Vector3(-0.13, 0.20, -1.60), Vector3(0.13, 0.20, -1.60), Vector3(0.13, 0.30, 0.13))
	var plane := world.get_node_or_null("Airplane") as Node3D
	if plane != null:
		# Open cockpit: fuselage top 0.40, canopy glass at
		# (0, 0.50, -0.80); prop at z -2.1, forward -z.
		_figure(plane, "Plane", shirt, skin, dark,
			Vector3(0, 0.85, -0.80), Vector3(0.42, 0.50, 0.30),
			Vector3(0, 1.20, -0.80), 0.13,
			Vector3(-0.20, 0.95, -1.15), Vector3(0.20, 0.95, -1.15), Vector3(0.08, 0.08, 0.50),
			Vector3(-0.13, 0.62, -1.05), Vector3(0.13, 0.62, -1.05), Vector3(0.15, 0.12, 0.40),
			Vector3(-0.13, 0.55, -1.20), Vector3(0.13, 0.55, -1.20), Vector3(0.13, 0.30, 0.13))
