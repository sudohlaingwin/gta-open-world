extends Node3D

## Slice 111 — CORE-MODEL REBUILD ROUND 3 (owner re-point
## 2026-10-24 11:14 +07, continued: S109 rebuilt bus/minibus/
## arms/palms/ground/menu; S110 rebuilt the remaining boxy
## vehicles EXCEPT the tuk-tuk body, which S110 explicitly
## deferred. This round finishes that deferral + the two
## traffic fleets, which audit111 proved are still plain
## two-box bodies on SQUARE box wheels, + the floating
## village-palm trunks). Every item below was live-probed
## missing/broken BEFORE adding (audit111.gd, audit112palm.gd
## outputs). Runtime hide-and-replace ONLY (S95/S109/S110
## precedent): original body boxes hidden, new geometry in
## the SAME footprint, collider/tuning/controller/door/
## seats/sign/lamp untouched. NO scene edits, NO .tscn
## edits, no bus-system changes, minibus NOT rewired, big
## bus NOT rewired (Slice 81 limit), touch controls
## untouched, ZERO new colliders (traffic wheels are
## children of the existing spinning holders, so spin
## inherits; no collider is moved, resized, or replaced),
## StandardMaterial3D only, no dead specular lines, no
## fog/SSAO/glow claims (no WorldEnvironment exists), no
## photorealism claims: stylised smooth procedural work.
## Static pass runs at frame >= 440, after realism111's
## 400 pass. Traffic cars/vans spawn dynamically (manager
## + bus_sim76), so a 1.0 s scan dresses any TrafficCar*/
## TrafficVan* instance without the dressed112 marker.
## PAINT RULE (measured, player.gd _apply_vehicle_paints):
## paint duplicates the body material on world load, so new
## parts share the body material instance READ AT DRESS
## TIME (post-paint). A mid-session menu repaint shows on
## the next world load, exactly like the original bodies.
## HONEST COUNT: tuk 13 + traffic car 15 + traffic van 16
## + palm trunks 5 = 49. Patterns are counted once per
## vehicle type (S97 precedent), NOT per traffic instance —
## multiplying by fleet size would be padding.

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism112") != null:
		return
	var n := Node3D.new()
	n.name = "Realism112"
	n.set_script(load("res://realism112.gd"))
	world.call_deferred("add_child", n)

func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 440:
		_done = true
		_apply(get_parent() as Node3D)
	_scan_t += delta
	if _scan_t >= 1.0:
		_scan_t = 0.0
		_scan_traffic(get_parent() as Node3D)

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
	m.roughness = 0.1
	m.metallic = 0.1
	return m

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node, r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _torus(parent: Node, inner_r: float, outer_r: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var tm := TorusMesh.new()
	tm.inner_radius = inner_r
	tm.outer_radius = outer_r
	mi.mesh = tm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _hide(node: Node, nm: String) -> void:
	var c := node.get_node_or_null(nm)
	if c is Node3D:
		(c as Node3D).visible = false

static func _apply(world: Node3D) -> void:
	if world == null:
		return
	_tuk(world)
	_palms(world)

# TUK-TUK — S110's explicit deferral. TukBody is still the
# original 1.4 x 0.7 x 2.4 box at (0, 0.2, 0); forward is -z
# (headlight z -1.25, front wheel z -1.1). New body keeps
# the footprint; seat/canopy/posts/glass/indicators/mirrors/
# bumper/tail/exhaust/plates/mudflaps/backrest all untouched.
static func _tuk(world: Node3D) -> void:
	var tuk := world.get_node_or_null("TukTuk") as Node3D
	if tuk == null:
		return
	var body := tuk.get_node_or_null("TukBody") as MeshInstance3D
	if body == null:
		return
	var bm: Material = body.get_surface_override_material(0)
	if bm == null:
		bm = _mat(Color(0.1, 0.4, 0.8, 1.0), 0.25, 0.6)
	var dark := _mat(Color(0.1, 0.1, 0.1, 1.0), 0.9)
	body.visible = false
	_box(tuk, Vector3(1.34, 0.55, 2.36), bm, Vector3(0, 0.125, 0), "Tub112")
	_box(tuk, Vector3(0.06, 0.3, 2.0), bm, Vector3(-0.67, 0.5, 0.1), "Side112_L")
	_box(tuk, Vector3(0.06, 0.3, 2.0), bm, Vector3(0.67, 0.5, 0.1), "Side112_R")
	_box(tuk, Vector3(1.3, 0.3, 0.3), bm, Vector3(0, 0.5, -1.05), "Cowl112")
	_box(tuk, Vector3(1.2, 0.15, 0.25), dark, Vector3(0, 0.62, -0.85), "Dash112")
	_box(tuk, Vector3(1.34, 0.35, 0.08), bm, Vector3(0, 0.475, 1.16), "Rear112")
	_box(tuk, Vector3(0.4, 0.2, 0.04), dark, Vector3(-0.35, 0.2, -1.21), "Grille112_L")
	_box(tuk, Vector3(0.4, 0.2, 0.04), dark, Vector3(0.35, 0.2, -1.21), "Grille112_R")
	_torus(tuk, 0.37, 0.45, dark, Vector3(0, -0.65, -1.1), "Arch112_F", Vector3(0, 1.5707963, 0))
	_torus(tuk, 0.37, 0.45, dark, Vector3(-0.7, -0.65, 0.9), "Arch112_L", Vector3(0, 1.5707963, 0))
	_torus(tuk, 0.37, 0.45, dark, Vector3(0.7, -0.65, 0.9), "Arch112_R", Vector3(0, 1.5707963, 0))
	_cyl(tuk, 0.04, 0.5, dark, Vector3(0, 0.8, -0.75), "Column112", Vector3(-0.35, 0, 0))
	_cyl(tuk, 0.22, 0.05, dark, Vector3(0, 0.98, -0.68), "Wheel112", Vector3(1.1, 0, 0))

# PALMS — Palm18A/B trunks are 0.25 x 4.2 x 0.25 boxes
# centred y 3.0, so they FLOAT 0.9 m above the ground
# (bottom 0.9, no base mesh anywhere in the group).
# Palm20 trunks are r 0.45 cylinders with no rings.
static func _palms(world: Node3D) -> void:
	var trunk_m := _mat(Color(0.35, 0.22, 0.12, 1.0), 1.0)
	var ring_m := _mat(Color(0.28, 0.17, 0.09, 1.0), 1.0)
	for gname in ["Palm18A", "Palm18B"]:
		var grp := world.get_node_or_null(gname) as Node3D
		if grp == null:
			continue
		_box(grp, Vector3(0.3, 0.95, 0.3), trunk_m, Vector3(0, 0.45, 0), "Base112")
		for ri in 3:
			var ry := 1.8 + float(ri) * 1.0
			_box(grp, Vector3(0.31, 0.12, 0.31), ring_m, Vector3(0, ry, 0), "Ring112_%d" % ri)
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var nn: Node = stack.pop_back()
		for c in nn.get_children():
			stack.append(c)
		if nn is MeshInstance3D and String(nn.name).begins_with("Palm20") and (nn as MeshInstance3D).mesh is CylinderMesh:
			var pm := nn as MeshInstance3D
			for ri in 3:
				var ly := -1.5 + float(ri) * 2.0
				_cyl(pm, 0.48, 0.2, ring_m, Vector3(0, ly, 0), "Ring112_%d" % ri)

# TRAFFIC — dynamic instances, dressed on the 1.0 s scan.
# Car: body 1.4 x 0.55 x 3.2 at y 0.55, cabin 1.2 x 0.5 x
# 1.6 at y 1.05 z -0.2, forward +z, wheels are BOXES
# 0.22 x 0.64 x 0.64 at (+/-0.65, 0.32, +/-1.05).
# Van: body 1.7 x 0.9 x 4.4 at y 0.65, cabin 1.5 x 0.6 x
# 2.2 at y 1.35 z -0.3, wheels BOXES at (+/-0.8, 0.36,
# +/-1.5). New wheels are children of the existing
# spinning holders, so spin inherits from traffic_car.gd.
static func _scan_traffic(world: Node3D) -> void:
	if world == null:
		return
	var found: Array[Node] = []
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var nn: Node = stack.pop_back()
		for c in nn.get_children():
			stack.append(c)
		var nm := String(nn.name)
		if nn is Node3D and (nm.begins_with("TrafficCar") or nm.begins_with("TrafficVan")) and not nn.has_meta("dressed112"):
			found.append(nn)
	for inst in found:
		if not (inst as Node).is_inside_tree():
			continue
		if String(inst.name).begins_with("TrafficVan"):
			_dress_van(inst as Node3D)
		else:
			_dress_car(inst as Node3D)
		inst.set_meta("dressed112", true)

static func _dress_car(car: Node3D) -> void:
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
	_box(car, Vector3(1.36, 0.5, 3.12), bm, Vector3(0, 0.55, 0), "Tub112C")
	_box(car, Vector3(1.3, 0.18, 0.7), bm, Vector3(0, 0.89, 1.15), "Hood112C")
	_box(car, Vector3(1.16, 0.45, 1.5), gl, Vector3(0, 1.05, -0.2), "Glass112C")
	_box(car, Vector3(1.2, 0.08, 1.6), bm, Vector3(0, 1.32, -0.2), "Roof112C")
	_box(car, Vector3(1.3, 0.18, 0.6), bm, Vector3(0, 0.89, -1.25), "Trunk112C")
	for w in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		var hold := car.get_node_or_null(w) as Node3D
		if hold == null:
			continue
		_cyl(hold, 0.32, 0.22, dark, Vector3.ZERO, "Wheel112C", Vector3(0, 0, 1.5707963))
		_cyl(hold, 0.12, 0.24, grey, Vector3.ZERO, "Hub112C", Vector3(0, 0, 1.5707963))
		_torus(car, 0.34, 0.42, dark, hold.position, "Arch112C_" + w, Vector3(0, 1.5707963, 0))

static func _dress_van(van: Node3D) -> void:
	var body := van.get_node_or_null("TrafficBody") as MeshInstance3D
	if body == null:
		return
	var bm: Material = body.material_override
	if bm == null:
		bm = _mat(Color(0.8, 0.2, 0.2, 1.0), 0.4)
	var dark := _mat(Color(0.1, 0.1, 0.1, 1.0), 0.9)
	var grey := _mat(Color(0.5, 0.5, 0.5, 1.0), 0.4, 0.6)
	var gl := _glass()
	body.visible = false
	_hide(van, "TrafficCabin")
	for w in [["WheelFL", "WheelMeshFL"], ["WheelFR", "WheelMeshFR"], ["WheelRL", "WheelMeshRL"], ["WheelRR", "WheelMeshRR"]]:
		var hold0 := van.get_node_or_null(w[0]) as Node3D
		if hold0 != null:
			_hide(hold0, w[1])
	_box(van, Vector3(1.66, 0.85, 4.32), bm, Vector3(0, 0.65, 0), "Tub112V")
	_box(van, Vector3(1.46, 0.55, 2.16), gl, Vector3(0, 1.35, -0.3), "Glass112V")
	_box(van, Vector3(1.5, 0.08, 2.2), bm, Vector3(0, 1.67, -0.3), "Roof112V")
	_box(van, Vector3(1.6, 0.2, 1.3), bm, Vector3(0, 1.15, 1.5), "Hood112V")
	_box(van, Vector3(1.6, 0.2, 0.3), bm, Vector3(0, 1.15, -2.05), "Rear112V")
	for w in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		var hold := van.get_node_or_null(w) as Node3D
		if hold == null:
			continue
		_cyl(hold, 0.36, 0.26, dark, Vector3.ZERO, "Wheel112V", Vector3(0, 0, 1.5707963))
		_cyl(hold, 0.14, 0.28, grey, Vector3.ZERO, "Hub112V", Vector3(0, 0, 1.5707963))
		_torus(van, 0.38, 0.46, dark, hold.position, "Arch112V_" + w, Vector3(0, 1.5707963, 0))
