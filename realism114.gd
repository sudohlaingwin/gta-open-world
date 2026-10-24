extends Node3D

## Slice 113 — SUPERIOR BUILD, harsh senior mode (owner order
## 2026-10-24 11:39 +07). Audit-first: every item below was
## live-probed MISSING/VISIBLE-BOXY before adding (audit113
## + audit113b + audit113d outputs). Runtime hide-and-replace
## ONLY (S95/S109/S110 precedent): original slabs hidden, new
## geometry in the SAME footprint, collider/tuning/controller/
## door/seats/sign/lamp untouched. NO scene edits, NO .tscn
## edits, no bus-system changes, minibus NOT rewired, big bus
## NOT rewired (Slice 81 limit), touch controls untouched,
## ZERO new colliders, StandardMaterial3D only, no dead
## specular lines, no fog/SSAO/glow claims (no WorldEnvironment
## exists), no photorealism claims: stylised smooth procedural
## work. Runs at frame >= 480, after realism113's 460 pass.
## HONEST COUNT: 6 assemblies (heli rotor, plane wings, plane
## propeller, bus driver, minibus driver, Cow2 parity) — UNDER
## the ~50 target, NO padding. Deliberately NOT added (audited
## present, re-adding would be padding): traffic box wheels
## (hidden since S111, re-proved visible=false), boat Hull
## (hidden since S110), heli Body / plane Fuselage (hidden
## since S110), bus/minibus mirrors (S93, present), people
## sandals/straps/hats (S58/S94/S95, present), horse mane/tail
## and elephant howdah/blanket/ladder/bell (present).
## HONEST LIMITS: driver figures are STATIC seated poses
## (no animation, present whether or not the player drives);
## the in-vehicle FPP eye sits at vehicle origin + 1.5 m (not
## at the driver seat), so the driver figure reads in the
## right of the FPP frame but does NOT block the centre view
## (verified against camera.gd: eye = origin + fwd*0.3 +
## (0,1.5,0), driver at x 0.75, z -3.35). Rotor/propeller
## blades mirror the original nodes' rotation every frame
## (helicopter.gd Rotor.rotation.y, airplane.gd Propeller.
## rotation.z), so spin behaviour is inherited, not faked
## with a static pose.

var _frames: int = 0
var _done: bool = false
var _heli_blades: Node3D = null
var _prop_blades: Node3D = null
var _heli_rotor: Node3D = null
var _prop_node: Node3D = null

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism114") != null:
		return
	var n := Node3D.new()
	n.name = "Realism114"
	n.set_script(load("res://realism114.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 480:
		_done = true
		_apply(get_parent() as Node3D)
	if not _done:
		return
	# Spin inheritance: mirror the original nodes' rotation.
	if _heli_rotor != null and _heli_blades != null:
		_heli_blades.rotation.y = _heli_rotor.rotation.y
	if _prop_node != null and _prop_blades != null:
		_prop_blades.rotation.z = _prop_node.rotation.z

static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
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

static func _sph(parent: Node, r: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _hide(node: Node, nm: String) -> void:
	var c := node.get_node_or_null(nm)
	if c is Node3D:
		(c as Node3D).visible = false

static func _child(node: Node, nm: String) -> Node:
	return node.get_node_or_null(nm)

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_heli(world)
	_plane(world)
	_bus_drivers(world)
	_cow2(world)

# HELICOPTER ROTOR — audit113b proved Rotor visible=true as
# an 8 x 0.3 x 1.5 flat slab. Replaced by 2 thin blades +
# hub; spin inherited via _process mirror of Rotor.rotation.y.
func _heli(world: Node3D) -> void:
	var heli := world.get_node_or_null("Helicopter") as Node3D
	if heli == null:
		return
	var rotor := _child(heli, "Rotor") as Node3D
	if rotor == null:
		return
	_heli_rotor = rotor
	rotor.visible = false
	var dark := _mat(Color(0.15, 0.15, 0.15, 1.0), 0.6)
	var blades := Node3D.new()
	blades.name = "HeliBlades114"
	blades.position = rotor.position
	heli.add_child(blades)
	_heli_blades = blades
	_box(blades, Vector3(3.9, 0.06, 0.28), dark, Vector3(1.95, 0.0, 0.0), "HeliBlade114_R")
	_box(blades, Vector3(3.9, 0.06, 0.28), dark, Vector3(-1.95, 0.0, 0.0), "HeliBlade114_L")
	_cyl(blades, 0.18, 0.12, dark, Vector3(0.0, 0.0, 0.0), "HeliHub114")

# AIRPLANE WINGS + PROPELLER — audit113b proved Wings
# visible=true as an 8 x 0.3 x 1.5 slab and Propeller
# visible=true as a 0.15 x 1.8 x 0.15 plank. Wings replaced
# by 2 thin wings; propeller replaced by a 2-blade prop whose
# spin mirrors Propeller.rotation.z (airplane.gd).
func _plane(world: Node3D) -> void:
	var plane := world.get_node_or_null("Airplane") as Node3D
	if plane == null:
		return
	_hide(plane, "Wings")
	var white := _mat(Color(0.9, 0.9, 0.9, 1.0), 0.5)
	_box(plane, Vector3(3.9, 0.12, 1.4), white, Vector3(2.05, 0.0, 0.0), "Wing114_R")
	_box(plane, Vector3(3.9, 0.12, 1.4), white, Vector3(-2.05, 0.0, 0.0), "Wing114_L")
	var prop := _child(plane, "Propeller") as Node3D
	if prop == null:
		return
	_prop_node = prop
	prop.visible = false
	var dark := _mat(Color(0.15, 0.15, 0.15, 1.0), 0.6)
	var blades := Node3D.new()
	blades.name = "PropBlades114"
	blades.position = prop.position
	plane.add_child(blades)
	_prop_blades = blades
	_box(blades, Vector3(0.14, 1.8, 0.06), dark, Vector3(0.0, 0.0, 0.0), "PropBlade114")
	_cyl(blades, 0.1, 0.12, dark, Vector3(0.0, 0.0, 0.0), "PropHub114", Vector3(1.5708, 0.0, 0.0))

# BUS + MINIBUS DRIVER FIGURES — audit113b proved NO driver
# figure exists (DriverSeat75 + SteerWheel75 present, seat
# empty; same for minibus). Static seated figures, children
# of the vehicles so they follow. No colliders.
func _bus_drivers(world: Node3D) -> void:
	var shirt := _mat(Color(0.15, 0.25, 0.5, 1.0), 0.8)
	var skin := _mat(Color(0.85, 0.65, 0.5, 1.0), 0.8)
	var dark := _mat(Color(0.2, 0.2, 0.25, 1.0), 0.8)
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus != null:
		# Seat (0.75, 1.0, -3.4), wheel (0.75, 1.55, -4.0).
		_box(bus, Vector3(0.42, 0.55, 0.28), shirt, Vector3(0.75, 1.35, -3.35), "DriverTorso114")
		_sph(bus, 0.14, skin, Vector3(0.75, 1.78, -3.35), "DriverHead114")
		_box(bus, Vector3(0.09, 0.09, 0.55), shirt, Vector3(0.55, 1.5, -3.68), "DriverArm114_L")
		_box(bus, Vector3(0.09, 0.09, 0.55), shirt, Vector3(0.95, 1.5, -3.68), "DriverArm114_R")
		_box(bus, Vector3(0.16, 0.12, 0.45), dark, Vector3(0.62, 1.08, -3.65), "DriverThigh114_L")
		_box(bus, Vector3(0.16, 0.12, 0.45), dark, Vector3(0.88, 1.08, -3.65), "DriverThigh114_R")
		_box(bus, Vector3(0.14, 0.5, 0.14), dark, Vector3(0.62, 0.8, -3.85), "DriverShin114_L")
		_box(bus, Vector3(0.14, 0.5, 0.14), dark, Vector3(0.88, 0.8, -3.85), "DriverShin114_R")
	var mini := world.get_node_or_null("Minibus") as Node3D
	if mini != null:
		# Seat (0.7, 0.95, -2.2), wheel (0.7, 1.5, -2.7).
		_box(mini, Vector3(0.4, 0.5, 0.26), shirt, Vector3(0.7, 1.28, -2.15), "MiniDriverTorso114")
		_sph(mini, 0.13, skin, Vector3(0.7, 1.68, -2.15), "MiniDriverHead114")
		_box(mini, Vector3(0.08, 0.08, 0.5), shirt, Vector3(0.52, 1.42, -2.42), "MiniDriverArm114_L")
		_box(mini, Vector3(0.08, 0.08, 0.5), shirt, Vector3(0.88, 1.42, -2.42), "MiniDriverArm114_R")
		_box(mini, Vector3(0.15, 0.11, 0.4), dark, Vector3(0.58, 1.02, -2.4), "MiniDriverThigh114_L")
		_box(mini, Vector3(0.15, 0.11, 0.4), dark, Vector3(0.82, 1.02, -2.4), "MiniDriverThigh114_R")
		_box(mini, Vector3(0.13, 0.45, 0.13), dark, Vector3(0.58, 0.75, -2.58), "MiniDriverShin114_L")
		_box(mini, Vector3(0.13, 0.45, 0.13), dark, Vector3(0.82, 0.75, -2.58), "MiniDriverShin114_R")

# COW2 PARITY — audit113 proved Cow carries Harness105 +
# reins + bell while Cow2 (same body, same scale, same
# Body111 transform) carries none. S105 deferred Cow2 as
# "ambient"; the visible difference is real, so parity is
# added here, same local transforms as Cow.
func _cow2(world: Node3D) -> void:
	var cow2 := world.get_node_or_null("Cow2") as Node3D
	if cow2 == null:
		return
	var leather := _mat(Color(0.45, 0.3, 0.15, 1.0), 0.8)
	var gold := _mat(Color(0.9, 0.75, 0.2, 1.0), 0.4, 0.6)
	_box(cow2, Vector3(0.95, 0.06, 0.18), leather, Vector3(0.0, -0.05, 0.0), "Harness114_Cow2")
	_box(cow2, Vector3(0.03, 0.03, 0.75), leather, Vector3(0.3, 0.45, 0.375), "Rein114_Cow2_1")
	_box(cow2, Vector3(0.03, 0.03, 0.75), leather, Vector3(-0.3, 0.45, 0.375), "Rein114_Cow2_-1")
	_sph(cow2, 0.09, gold, Vector3(0.0, 0.0, 0.55), "Bell114_Cow2")
