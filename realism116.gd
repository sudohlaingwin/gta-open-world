extends Node3D

## Slice 115 — SUPERIOR BUILD, harsh senior mode (owner order
## 2026-10-24 11:39 +07). Audit-first: every item below was
## live-probed MISSING before adding (audit116/audit116b/
## audit116c outputs at frame 560, after all earlier passes).
## TWO genuine gaps, both about traffic — the vehicles the
## player actually meets on every road:
## (1) LONG-ROUTE TRAFFIC STILL BOXY. Slice 112 reshaped the
## village traffic cars/vans (Tub112C/V, glass, roof, arches),
## but its scan matched ONLY names beginning with
## "TrafficCar"/"TrafficVan". The six long-route cars are named
## "LongTraffic76_*", so they never matched: audit116c proves
## all six still show the original solid body (1.4 x 0.55 x 3.2)
## and cabin VISIBLE, with zero 112 parts. Fixed here with the
## S112 car pattern exactly (same dims, same glass material,
## body colour read live from each car's own TrafficBody, so
## paint stays live), under 116 names.
## (2) TRAFFIC DRIVERS — ALL NINE TRAFFIC VEHICLES WERE
## DRIVERLESS. Slice 105 deferred traffic drivers because the
## cabins were solid boxes a driver would not read through.
## That deferral is OVERTURNED by S112's glass: Glass112C/V
## is semi-transparent (transparency mode 1, alpha 0.45,
## proven live in audit116c), exactly like the S91 bus glass
## the seated passengers already read through. So every
## traffic vehicle now carries a static seated driver figure
## (S113/S114 pattern: child of the vehicle so it follows
## movement, ZERO new colliders, controller/tuning/lights
## untouched, present whether parked or driving — same
## standing pattern as S113/S114 figures). Both scans are
## dynamic (S112 pattern: re-scan every 1.0 s), so traffic
## vehicles spawned later get reshaped + driven too — the
## driver prefix is the vehicle name itself, so parts never
## collide across vehicles.
## MEASURED FITS, STATED PLAINLY (traffic front is +z:
## headlights sit at +z, so arms reach +z):
## CAR (village + long-route, same dims): tub top 0.80,
## glass band 0.825-1.275, roof underside 1.28. Compact
## figure: torso 0.42 tall centred 1.01 (base exactly on tub
## top), head r 0.13 centred 1.13 (top 1.26, 0.02 clear of the
## roof), arms forward inside the glass z-range, thighs on
## the tub top. Headroom is too tight for the full S114
## figure — forcing it would clip the roof, so cars get the
## compact figure, not the tall one.
## VAN (TrafficVan3 only): tub top 1.075, glass band
## 1.075-1.625, roof underside 1.63. Roomier figure: torso
## 0.55 tall centred 1.32 (base 0.03 sunk into the tub top,
## reads as sitting), head r 0.13 centred 1.48 (top 1.61,
## 0.02 clear of the roof).
## SHINS OMITTED FOR ALL NINE, DELIBERATELY: below the tub
## top the lower legs would sit inside the solid tub, fully
## invisible. Adding invisible boxes would be padding, so
## traffic drivers are 6 visible parts (torso, head, 2 arms,
## 2 thighs), not 8. The S113/S114 rideable figures keep
## their shins because those vehicles are open.
## NOT TOUCHED, WITH REASONS: headlights (LongTraffic76_1
## shows headlights off while 76_0 shows them on at the same
## frame — investigated: headlights follow the day/night
## cycle plus the S83 peak-band parking rule, and 76_1/3/4/5
## sit on depot parking spots; this is band logic, not a
## defect, so headlight visibility is left exactly alone);
## traffic controllers/tuning/waypoints (not rewired);
## bus system, minibus (Slice 81 limit stands); the
## tuk-wheel scene file's 3 bare Transform3D lines (owner/
## parent decision pending — scene file untouched, the S112
## _ready restore stands).
## Runs at frame >= 520, after realism115's 500 pass.
## HONEST COUNT: 6 reshapes + 9 drivers = 15 items — UNDER
## the ~50 target, NO padding. No other core gap survived
## auditing: car/bus/minibus (S95/S109), motorcycle tank/
## engine/frame/cowl (S111), bicycle tubes (S111), cart bed
## (S111), boat hull (S111), heli tub/nose/boom (S111),
## plane capsule fuselage (S111), cow capsule body (S111),
## elephant barrel body (S111), and all S113/S114 figures
## are already present and re-proved in SIM116.

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism116") != null:
		return
	var n := Node3D.new()
	n.name = "Realism116"
	n.set_script(load("res://realism116.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 520:
		_done = true
		_apply(get_parent() as Node3D)
	# S112 pattern: re-scan every 1.0 s so traffic vehicles
	# added later (fresh spawns) get reshaped + driven too.
	_scan_t += _delta
	if _scan_t >= 1.0:
		_scan_t = 0.0
		var w := get_parent() as Node3D
		if w != null:
			for car in _scan(w, "LongTraffic"):
				_reshape_car(car as Node3D)
			_driver_scan(w)

static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m

static func _glass() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = 1
	m.albedo_color = Color(0.65, 0.75, 0.85, 0.45)
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

static func _cyl(parent: Node, r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)

static func _torus(parent: Node, inner_r: float, outer_r: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_r
	mesh.outer_radius = outer_r
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)

static func _hide(node: Node, nm: String) -> void:
	if node == null:
		return
	var c := node.get_node_or_null(nm) as Node3D
	if c != null:
		c.visible = false

static func _scan(world: Node3D, prefix: String) -> Array[Node]:
	var found: Array[Node] = []
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var nn: Node = stack.pop_back()
		for c in nn.get_children():
			stack.append(c)
		if nn is Node3D and String(nn.name).begins_with(prefix) and not nn.has_meta("dressed116"):
			found.append(nn)
	return found

static func _reshape_car(car: Node3D) -> void:
	var body := car.get_node_or_null("TrafficBody") as MeshInstance3D
	if body == null:
		return
	var bm: Material = body.material_override
	if bm == null:
		bm = _mat(Color(0.8, 0.2, 0.2, 1.0), 0.4)
	var dark := _mat(Color(0.1, 0.1, 0.1, 1.0), 0.9)
	var grey := _mat(Color(0.5, 0.5, 0.5, 1.0), 0.4, 0.6)
	var gl := _glass()
	body.visible = false
	_hide(car, "TrafficCabin")
	for w in [["WheelFL", "WheelMeshFL"], ["WheelFR", "WheelMeshFR"], ["WheelRL", "WheelMeshRL"], ["WheelRR", "WheelMeshRR"]]:
		var hold0 := car.get_node_or_null(w[0]) as Node3D
		if hold0 != null:
			_hide(hold0, w[1])
	_box(car, Vector3(1.36, 0.5, 3.12), bm, Vector3(0, 0.55, 0), "Tub116C")
	_box(car, Vector3(1.3, 0.18, 0.7), bm, Vector3(0, 0.89, 1.15), "Hood116C")
	_box(car, Vector3(1.16, 0.45, 1.5), gl, Vector3(0, 1.05, -0.2), "Glass116C")
	_box(car, Vector3(1.2, 0.08, 1.6), bm, Vector3(0, 1.32, -0.2), "Roof116C")
	_box(car, Vector3(1.3, 0.18, 0.6), bm, Vector3(0, 0.89, -1.25), "Trunk116C")
	for w in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		var hold := car.get_node_or_null(w) as Node3D
		if hold == null:
			continue
		var has_wheel := false
		for ch in hold.get_children():
			# Count only VISIBLE meshes: the original WheelMesh
			# was just hidden above, and a hidden mesh must not
			# block its replacement (else the car ends up with
			# NO visible wheels at all).
			if ch is MeshInstance3D and (ch as MeshInstance3D).visible:
				has_wheel = true
		if not has_wheel:
			_cyl(hold, 0.32, 0.22, dark, Vector3.ZERO, "Wheel116C", Vector3(0, 0, 1.5707963))
			_cyl(hold, 0.12, 0.24, grey, Vector3.ZERO, "Hub116C", Vector3(0, 0, 1.5707963))
		_torus(car, 0.34, 0.42, dark, hold.position, "Arch116C_" + w, Vector3(0, 1.5707963, 0))
	car.set_meta("dressed116", true)

static func _driver_car(v: Node3D, pfx: String, shirt: Material, skin: Material) -> void:
	# Compact car driver: torso base on tub top 0.80, head top
	# 1.26 (0.02 clear of roof underside 1.28). Front is +z.
	var dx := 0.35
	_box(v, Vector3(0.42, 0.42, 0.26), shirt, Vector3(dx, 1.01, 0.10), pfx + "Torso116")
	_sph(v, 0.13, skin, Vector3(dx, 1.13, 0.10), pfx + "Head116")
	_box(v, Vector3(0.08, 0.08, 0.4), shirt, Vector3(dx - 0.18, 1.05, 0.30), pfx + "Arm116_L")
	_box(v, Vector3(0.08, 0.08, 0.4), shirt, Vector3(dx + 0.18, 1.05, 0.30), pfx + "Arm116_R")
	_box(v, Vector3(0.15, 0.12, 0.45), shirt, Vector3(dx - 0.13, 0.86, -0.05), pfx + "Thigh116_L")
	_box(v, Vector3(0.15, 0.12, 0.45), shirt, Vector3(dx + 0.13, 0.86, -0.05), pfx + "Thigh116_R")

static func _driver_van(v: Node3D, pfx: String, shirt: Material, skin: Material) -> void:
	# Roomier van driver: torso base 0.03 sunk into tub top
	# 1.075 (reads as sitting), head top 1.61 (0.02 clear of
	# roof underside 1.63). Front is +z.
	var dx := 0.40
	_box(v, Vector3(0.42, 0.55, 0.28), shirt, Vector3(dx, 1.32, 0.20), pfx + "Torso116")
	_sph(v, 0.13, skin, Vector3(dx, 1.48, 0.20), pfx + "Head116")
	_box(v, Vector3(0.08, 0.08, 0.5), shirt, Vector3(dx - 0.18, 1.35, 0.45), pfx + "Arm116_L")
	_box(v, Vector3(0.08, 0.08, 0.5), shirt, Vector3(dx + 0.18, 1.35, 0.45), pfx + "Arm116_R")
	_box(v, Vector3(0.15, 0.12, 0.45), shirt, Vector3(dx - 0.13, 1.13, 0.05), pfx + "Thigh116_L")
	_box(v, Vector3(0.15, 0.12, 0.45), shirt, Vector3(dx + 0.13, 1.13, 0.05), pfx + "Thigh116_R")

static func _apply(world: Node3D) -> void:
	if world == null:
		return
	# Reshapes first: long-route drivers sit in reshaped cars.
	for car in _scan(world, "LongTraffic"):
		_reshape_car(car as Node3D)
	_driver_scan(world)

static func _scan_all(world: Node3D, prefix: String) -> Array[Node]:
	# Like _scan() but without the dressed116 filter: drivers
	# must be found on cars that were JUST reshaped.
	var found: Array[Node] = []
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var nn: Node = stack.pop_back()
		for c in nn.get_children():
			stack.append(c)
		if nn is Node3D and String(nn.name).begins_with(prefix):
			found.append(nn)
	return found

## Slice 120 LEAK FIX (owner performance order): vehicle-root
## match only (digits suffix), the SAME rule realism118 already
## uses. Before this fix, _driver_scan matched by bare prefix,
## so driver parts THEMSELVES matched: a part named
## "TrafficCar6_Torso116" begins with "TrafficCar", has no
## driver116 meta, and got a full 6-part driver figure of its
## own — whose parts matched again next scan. 1 vehicle -> 6
## parts -> 36 -> 216 -> ... : measured live, the tree grew
## 14,125 -> 25,936 -> 97,392 nodes in ~25 s of play while
## headless frame rate collapsed 86 -> 41 -> 9 fps. The
## driver116 meta alone cannot stop this (it guards a node,
## not the prefix namespace); only the root rule can. Fresh
## spawns are still covered: traffic_manager names are
## TrafficCar%d / TrafficVan%d and long-route cars are
## LongTraffic76_%d, all digits-suffixed roots.
static func _is_traffic_vehicle(nm: String) -> bool:
	if nm.begins_with("TrafficCar") or nm.begins_with("TrafficVan"):
		return nm.substr(10).is_valid_int()
	if nm.begins_with("LongTraffic76_"):
		return nm.substr(14).is_valid_int()
	return false


static func _driver_scan(world: Node3D) -> void:
	# Dynamic, like S112's reshape scan: ANY traffic vehicle
	# gets a driver, not just the nine known fleet names, so
	# fresh spawns are covered too. Prefix is the vehicle
	# name itself, so parts never collide across vehicles.
	var shirts := [
		_mat(Color(1.0, 1.0, 1.0, 1.0), 0.8),
		_mat(Color(0.7, 0.85, 1.0, 1.0), 0.8),
		_mat(Color(0.75, 0.9, 0.75, 1.0), 0.8),
		_mat(Color(0.9, 0.8, 0.6, 1.0), 0.8),
	]
	var skin := _mat(Color(0.85, 0.65, 0.5, 1.0), 0.8)
	var all: Array[Node] = []
	# NOTE: _scan() filters out dressed116 cars, but _apply()
	# reshapes BEFORE driving — so _scan() here would find
	# zero LongTraffic cars (they were just dressed). Drivers
	# need the unfiltered scan; duplicates are prevented by
	# TWO guards together: the driver116 meta (same node
	# twice) AND the _is_traffic_vehicle root rule (a driver
	# part must never be treated as a vehicle — S120 leak).
	all.append_array(_scan_all(world, "TrafficCar"))
	all.append_array(_scan_all(world, "TrafficVan"))
	all.append_array(_scan_all(world, "LongTraffic"))
	for v in all:
		var veh := v as Node3D
		if veh == null or veh.has_meta("driver116"):
			continue
		if not _is_traffic_vehicle(String(veh.name)):
			continue
		var h := 0
		for ch in String(veh.name):
			h += ch.unicode_at(0)
		var shirt: Material = shirts[h % shirts.size()]
		if String(veh.name).begins_with("TrafficVan"):
			_driver_van(veh, String(veh.name) + "_", shirt, skin)
		else:
			_driver_car(veh, String(veh.name) + "_", shirt, skin)
		veh.set_meta("driver116", true)
