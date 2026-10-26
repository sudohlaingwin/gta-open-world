extends Node3D
## Slice 125 owner-verdict fix (2026-10-26: the game "directly
## contradicts the simulation he wants" — cars cannot be driven
## AT ALL, ox carts missing, no motorcycle, joystick-turn + look
## not smooth). PROBE125 PROVED the loop mechanics work (joystick
## routing, walking, direct-call enter, driving, turning) but the
## PLAYER CANNOT FIND the vehicles: spawn sits 5.0-9.4 m from all
## three (enter radius is 4.0 m), no world marker, button + prompt
## hidden until within 4 m, garage empty + behind More, world map
## has ZERO vehicle landmarks. The fix is discoverability + the
## missing ox + camera smoothness, NOT a new menu system.
## - BEACONS: tall emissive beam + ground ring over Car, Cart,
##   Motorcycle (children of the vehicle, so the beam follows a
##   driven vehicle; hidden while THAT vehicle is driven, so no
##   beam in the driver's face). Beam 10 m tall reads from afar.
## - OX: the Cart had NO ox mesh at all (probe125: 6 children,
##   mesh + 2 wheels + canopy + 2 posts) — the owner's "ox cart
##   missing" is literally true in visual terms. A zebu ox (hump
##   reads "ox" at 6 m) hitched ahead of the cart, legs swinging
##   gently only while the cart rolls (speed > 0.5), else at rest.
##   Cart forward is -z (shared car/cart convention, camera.gd).
##   Cart body is BoxMesh_car 2x0.8x4, so the front face is z=-2.
## - Names Beacon125_*/Ox125_* match NONE of perf120's hide
##   prefixes (Blade93_/94_/95_/110_, Reed57_/62/107_/108_), so
##   they stay visible always. Zero colliders, StandardMaterial3D
##   only. Single pass at frame >= 680, after Realism124's 660.
## - Map dots for the three vehicles are added to world_map.gd
##   LANDMARKS (this file does not touch the map); minimap dots
##   already existed in the scene and update live (probe125
##   correction: the first probe searched the wrong panel).
## - Camera smoothness itself lives in camera.gd (pitch smoothing
##   + drag deadband) and the facing-rate reconciliation in
##   player.gd (10/s -> 12/s, matching follow) — see those files.

var _frames: int = 0
var _done: bool = false
var _beacons: Array = []
var _beacon_vis: Array = []
var _ox_legs: Array = []
var _ox_phase: float = 0.0
var _cart: Node = null

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism125") != null:
		return
	var n := Node3D.new()
	n.name = "Realism125"
	n.set_script(load("res://realism125.gd"))
	world.call_deferred("add_child", n)

static func _mat(c: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

static func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	m.metallic = 0.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
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

func _beacon(veh: Node3D, col: Color, ground_y: float) -> void:
	var beam_mat: StandardMaterial3D = _glow(col, 1.6)
	var beam: MeshInstance3D = _box(veh, Vector3(0.35, 10.0, 0.35), beam_mat, Vector3(0.0, 3.0, 0.0), "Beacon125_" + str(veh.name) + "_Beam")
	var ring_mat: StandardMaterial3D = _glow(col, 1.2)
	var ring := MeshInstance3D.new()
	ring.name = "Beacon125_" + str(veh.name) + "_Ring"
	var cm := CylinderMesh.new()
	cm.top_radius = 1.3
	cm.bottom_radius = 1.3
	cm.height = 0.08
	ring.mesh = cm
	ring.set_surface_override_material(0, ring_mat)
	ring.position = Vector3(0.0, ground_y - veh.global_position.y + 0.06, 0.0)
	veh.add_child(ring)
	_beacons.append([veh, beam, ring])
	_beacon_vis.append(true)

func _ox(cart: Node3D) -> int:
	var n := 0
	var grp := Node3D.new()
	grp.name = "Ox125"
	cart.add_child(grp)
	var hide: StandardMaterial3D = _mat(Color(0.75, 0.70, 0.60))
	var dark: StandardMaterial3D = _mat(Color(0.55, 0.48, 0.38))
	var leg_mat: StandardMaterial3D = _mat(Color(0.50, 0.42, 0.32))
	var horn_mat: StandardMaterial3D = _mat(Color(0.90, 0.85, 0.70))
	var wood: StandardMaterial3D = _mat(Color(0.45, 0.32, 0.18))
	# Body: centre z -3.3 (spans -2.5..-4.1), bottom y 0.05.
	_box(grp, Vector3(0.75, 0.85, 1.6), hide, Vector3(0.0, 0.475, -3.3), "Ox125_Body")
	n += 1
	# Zebu hump on top — the shape that reads "ox" at 6 m.
	_box(grp, Vector3(0.5, 0.3, 0.7), hide, Vector3(0.0, 1.05, -3.1), "Ox125_Hump")
	n += 1
	# Head at the front (-z end), slightly lowered.
	_box(grp, Vector3(0.5, 0.55, 0.5), dark, Vector3(0.0, 0.35, -4.25), "Ox125_Head")
	n += 1
	# Horns, angled out from the head top.
	_box(grp, Vector3(0.3, 0.1, 0.1), horn_mat, Vector3(-0.35, 0.68, -4.25), "Ox125_HornL")
	n += 1
	_box(grp, Vector3(0.3, 0.1, 0.1), horn_mat, Vector3(0.35, 0.68, -4.25), "Ox125_HornR")
	n += 1
	# Legs: pivot nodes at the hip (y 0.05) so rotation.x swings
	# around the hip; mesh hangs 0.55 down to the ground (-0.5).
	for sx in [-1.0, 1.0]:
		for sz in [-3.8, -2.8]:
			var pivot := Node3D.new()
			pivot.name = "Ox125_Leg_%d_%d" % [int(sx), int(sz * 10.0)]
			pivot.position = Vector3(sx * 0.28, 0.05, sz)
			grp.add_child(pivot)
			var lm := MeshInstance3D.new()
			lm.name = "Ox125_LegMesh"
			var lbm := BoxMesh.new()
			lbm.size = Vector3(0.16, 0.55, 0.16)
			lm.mesh = lbm
			lm.set_surface_override_material(0, leg_mat)
			lm.position = Vector3(0.0, -0.275, 0.0)
			pivot.add_child(lm)
			_ox_legs.append(pivot)
			n += 1
	# Tail at the rear (cart side), hanging down.
	_box(grp, Vector3(0.08, 0.5, 0.08), dark, Vector3(0.0, 0.2, -2.45), "Ox125_Tail")
	n += 1
	# Yoke bar across the shoulders + 2 poles to the cart front.
	_box(grp, Vector3(1.4, 0.12, 0.12), wood, Vector3(0.0, 0.5, -2.3), "Ox125_Yoke")
	n += 1
	_box(grp, Vector3(0.1, 0.1, 0.6), wood, Vector3(-0.5, 0.45, -2.1), "Ox125_PoleL")
	n += 1
	_box(grp, Vector3(0.1, 0.1, 0.6), wood, Vector3(0.5, 0.45, -2.1), "Ox125_PoleR")
	n += 1
	return n

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var gy: float = 0.0
	var gm: Node3D = world.get_node_or_null("GroundMesh") as Node3D
	if gm != null:
		gy = gm.global_position.y
	var specs: Array = [["Car", Color(1.0, 0.8, 0.1)], ["Cart", Color(0.2, 0.8, 0.3)], ["Motorcycle", Color(0.2, 0.7, 1.0)]]
	for sp in specs:
		var v: Node3D = world.get_node_or_null(str(sp[0])) as Node3D
		if v != null:
			_beacon(v, sp[1] as Color, gy)
	var cart: Node3D = world.get_node_or_null("Cart") as Node3D
	if cart != null:
		_cart = cart
		var ox_n: int = _ox(cart)
		print("REALISM125 dressed: beacons=", _beacons.size(), " ox_parts=", ox_n)
	else:
		print("REALISM125 dressed: beacons=", _beacons.size(), " ox_parts=0 NO_CART")

func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 680:
		_done = true
		_apply(get_parent() as Node3D)
	if not _done:
		return
	# Beacon visibility: hide only the vehicle currently driven.
	# State-change writes only (S120 pattern), O(3) per frame.
	for i in range(_beacons.size()):
		var entry: Array = _beacons[i]
		var veh: Node = entry[0]
		var want: bool = veh.get("driver") == null
		if want != bool(_beacon_vis[i]):
			_beacon_vis[i] = want
			(entry[1] as Node3D).visible = want
			(entry[2] as Node3D).visible = want
	# Ox legs: swing only while the cart rolls, else ease to rest.
	if _cart != null and _ox_legs.size() == 4:
		var rolling: bool = _cart.get("driver") != null and absf(float(_cart.get("speed"))) > 0.5
		if rolling:
			_ox_phase += delta * absf(float(_cart.get("speed"))) * 2.2
			var s: float = sin(_ox_phase) * 0.22
			(_ox_legs[0] as Node3D).rotation.x = s
			(_ox_legs[1] as Node3D).rotation.x = -s
			(_ox_legs[2] as Node3D).rotation.x = -s
			(_ox_legs[3] as Node3D).rotation.x = s
		else:
			for leg in _ox_legs:
				var l3: Node3D = leg as Node3D
				l3.rotation.x = move_toward(l3.rotation.x, 0.0, 2.0 * delta)
