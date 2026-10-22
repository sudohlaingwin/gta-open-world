## Slice 57 river + pagoda visual dressing: ORIGINAL procedural
## models only, no copied content, no external assets.
## No class_name, by design (same reason as village_dressing.gd
## and city_visual56.gd: a new class_name needs a regenerated
## .godot global-class cache, and a stale cache breaks preload
## references in a fresh clone). player.gd loads this file with
## preload("res://river_bridge57.gd") and calls dress() after
## the Slice 56 dressing. Runtime-only: no scene file is
## touched, so main.tscn load_steps is unchanged.
## What lands, all measured by the world sim (see README):
## - LongBridge57: a 20 m wooden footbridge across River13 at
##   x = -28 (the river strip is x -50..50, z 41..47, from
##   PlaneMesh_s13_river 100x6 at (0, 0.05, 44)). 24 planks,
##   2 side rails, 10 rail posts, 10 water pilings, 6 lantern
##   posts with lamp boxes, plus a deck collider and 2 ramp
##   colliders mirroring the Slice 14 bamboo-bridge geometry
##   (Slice 38 solidity rule: a visible bridge you can walk
##   on must not be a phantom). The existing BambooBridge14
##   (x = 18) and RiverBridge13 (x = 0) are untouched.
## - Waterside: 24 reeds + 8 cattail tips on both river banks,
##   2 visual-only rowboats moored in the river (NOT rideable;
##   the rideable boat is the existing Boat node, untouched).
## - Pagoda57: 3 gold terrace trim rings, 4 gold spire bands,
##   a gold material on the existing Hti, a white platform
##   face, 8 lantern posts with lamp boxes, 4 offering bowls.
## - NightLights57: 8 OmniLights (4 bridge, 4 pagoda) gated
##   by the shared daylight < 0.15 rule via river_night57.gd.
##   No 24/7 lights. Lamp boxes without a light are just lamp
##   boxes; only the 8 listed lights shine, and only at night.
## Honest scope: day dressing for the river crossing and the
## pagoda only. Vehicles, characters, the Mindon layout (still
## Slice 37 approximate) and the rest of the world are unchanged.
## Headless cannot prove how this looks on a phone; the owner's
## vivo V60 verdict decides, no photoreal claim.

static func _mat(albedo: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = roughness
	m.metallic = metallic
	return m

static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func dress(world: Node) -> void:
	if world == null:
		return
	if world.get_node_or_null("River57Applied") != null:
		return
	var wood := _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	var wood_dark := _mat(Color(0.36, 0.23, 0.12, 1.0), 0.9)
	var gold := _mat(Color(0.95, 0.75, 0.20, 1.0), 0.3, 0.85)
	var white := _mat(Color(0.93, 0.92, 0.88, 1.0), 0.9)
	var lamp_mat := _mat(Color(1.0, 0.82, 0.45, 1.0), 0.7)
	var reed_mat := _mat(Color(0.15, 0.45, 0.15, 1.0), 1.0)
	var tip_mat := _mat(Color(0.35, 0.20, 0.08, 1.0), 1.0)
	var terra := _mat(Color(0.70, 0.38, 0.22, 1.0), 0.9)

	# --- Long wooden bridge across River13 at x = -28 ---
	var bridge := Node3D.new()
	bridge.name = "LongBridge57"
	bridge.position = Vector3(-28.0, 0.0, 44.0)
	world.call_deferred("add_child", bridge)
	# Planks run along local z: deck spans local z -10..+10.
	for i in 24:
		var z: float = -9.6 + float(i) * 0.8
		_box(bridge, Vector3(3.2, 0.12, 0.7), wood if i % 2 == 0 else wood_dark, Vector3(0.0, 0.5, z), "Plank57_%d" % i)
	for side in [-1.0, 1.0]:
		_box(bridge, Vector3(0.1, 0.1, 20.0), wood_dark, Vector3(side * 1.55, 1.25, 0.0), "Rail57_%d" % int(side))
		for pi in 5:
			var pz: float = -8.0 + float(pi) * 4.0
			_box(bridge, Vector3(0.12, 0.85, 0.12), wood_dark, Vector3(side * 1.55, 0.85, pz), "RailPost57_%d_%d" % [int(side), pi])
			_cyl(bridge, 0.18, 0.18, 1.4, wood_dark, Vector3(side * 1.7, 0.1, pz), "Piling57_%d_%d" % [int(side), pi])
		for li in 3:
			var lz: float = -8.0 + float(li) * 8.0
			_box(bridge, Vector3(0.12, 1.1, 0.12), wood_dark, Vector3(side * 1.55, 1.05, lz), "LanternPost57_%d_%d" % [int(side), li])
			_box(bridge, Vector3(0.3, 0.3, 0.3), lamp_mat, Vector3(side * 1.55, 1.75, lz), "Lantern57_%d_%d" % [int(side), li])
	# Solid deck + ramps (Slice 14 geometry: deck top 0.56,
	# ramp tilt 0.148 rad, feet buried just above ground).
	var body := StaticBody3D.new()
	body.name = "LongBridge57Solid"
	body.collision_layer = 1
	bridge.add_child(body)
	var deck_shape := CollisionShape3D.new()
	deck_shape.name = "LongBridge57DeckShape"
	var deck_box := BoxShape3D.new()
	deck_box.size = Vector3(3.2, 0.15, 20.0)
	deck_shape.shape = deck_box
	deck_shape.position = Vector3(0.0, 0.485, 0.0)
	body.add_child(deck_shape)
	for side in [-1.0, 1.0]:
		var ramp := CollisionShape3D.new()
		ramp.name = "LongBridge57RampShape_%d" % int(side)
		var ramp_box := BoxShape3D.new()
		ramp_box.size = Vector3(3.2, 0.15, 3.2)
		ramp.shape = ramp_box
		ramp.position = Vector3(0.0, 0.32, side * 11.5)
		ramp.rotation = Vector3(-side * 0.148, 0.0, 0.0)
		body.add_child(ramp)

	# --- Waterside: reeds on both banks, 2 moored rowboats ---
	# Reeds live in their own group added via call_deferred:
	# a direct add_child to the world root from player._ready
	# fails ("Parent node is busy setting up children") — the
	# Slice 56 lesson, re-proven by the first Slice 57 sim run
	# (32 failed adds, 0 reeds in the tree).
	var bank := Node3D.new()
	bank.name = "RiverBank57"
	world.call_deferred("add_child", bank)
	for side in [-1.0, 1.0]:
		var bank_z: float = 40.2 if side < 0.0 else 47.8
		for ri in 12:
			var rx: float = -45.0 + float(ri) * 3.0
			_cyl(bank, 0.05, 0.05, 1.2, reed_mat, Vector3(rx, 0.6, bank_z), "Reed57_%d_%d" % [int(side), ri])
			if ri % 3 == 0:
				_cyl(bank, 0.09, 0.09, 0.35, tip_mat, Vector3(rx, 1.35, bank_z), "ReedTip57_%d_%d" % [int(side), ri])
	for bi in 2:
		var bx: float = -34.0
		var bz: float = 43.0 + float(bi) * 2.5
		var boat := Node3D.new()
		boat.name = "MooredBoat57_%d" % bi
		boat.position = Vector3(bx, 0.0, bz)
		world.call_deferred("add_child", boat)
		_box(boat, Vector3(3.0, 0.5, 1.2), wood, Vector3(0.0, 0.15, 0.0), "Hull57")
		_box(boat, Vector3(1.0, 0.08, 0.9), wood_dark, Vector3(-0.8, 0.45, 0.0), "Bench57A")
		_box(boat, Vector3(1.0, 0.08, 0.9), wood_dark, Vector3(0.8, 0.45, 0.0), "Bench57B")
		_box(boat, Vector3(0.08, 0.08, 2.2), wood_dark, Vector3(1.2, 0.5, 0.6), "Oar57")

	# --- Pagoda dressing (Pagoda node at (-20, 0, -25)) ---
	var pagoda := world.get_node_or_null("Pagoda") as Node3D
	if pagoda != null:
		# Gold trim rings on the three terrace tops (local y).
		var rings: Array = [[5.6, 1.42], [4.6, 2.42], [3.6, 3.42]]
		for ri in rings.size():
			_cyl(pagoda, float(rings[ri][0]), float(rings[ri][0]), 0.15, gold, Vector3(0.0, float(rings[ri][1]), 0.0), "TrimRing57_%d" % ri)
		# Gold bands up the spire (spire local y 6.9..11.9).
		var bands: Array = [[1.30, 7.5], [0.99, 8.7], [0.68, 9.9], [0.37, 11.1]]
		for bi2 in bands.size():
			_cyl(pagoda, float(bands[bi2][0]), float(bands[bi2][0]), 0.18, gold, Vector3(0.0, float(bands[bi2][1]), 0.0), "SpireBand57_%d" % bi2)
		var platform := pagoda.get_node_or_null("Platform") as MeshInstance3D
		if platform != null:
			platform.set_surface_override_material(0, white)
		var hti := pagoda.get_node_or_null("Hti") as MeshInstance3D
		if hti != null:
			hti.set_surface_override_material(0, gold)
		# 8 lantern posts around the platform (r = 8.2, inside
		# the 9.0 platform radius, outside the 6.5 base radius).
		for ai in 8:
			var ang: float = float(ai) * 0.7853981633974483
			var px: float = cos(ang) * 8.2
			var pz: float = sin(ang) * 8.2
			_box(pagoda, Vector3(0.12, 1.1, 0.12), wood_dark, Vector3(px, 0.95, pz), "PagodaLanternPost57_%d" % ai)
			_box(pagoda, Vector3(0.28, 0.28, 0.28), lamp_mat, Vector3(px, 1.65, pz), "PagodaLantern57_%d" % ai)
		# 4 offering bowls on the platform (r = 7.0).
		for ai in 4:
			var ang2: float = 0.7853981633974483 + float(ai) * 1.5707963267948966
			_cyl(pagoda, 0.35, 0.28, 0.25, terra, Vector3(cos(ang2) * 7.0, 0.525, sin(ang2) * 7.0), "OfferingBowl57_%d" % ai)

	# --- Night lights: 4 bridge + 4 pagoda, gated < 0.15 ---
	var night := Node3D.new()
	night.name = "NightLights57"
	night.set_script(load("res://river_night57.gd"))
	world.call_deferred("add_child", night)
	for li in 4:
		var lamp := OmniLight3D.new()
		lamp.name = "BridgeLamp57_%d" % li
		lamp.light_energy = 1.2
		lamp.light_color = Color(1.0, 0.82, 0.45, 1.0)
		lamp.omni_range = 9.0
		var lside: float = -1.0 if li < 2 else 1.0
		var lz: float = -8.0 if li % 2 == 0 else 8.0
		lamp.position = Vector3(-28.0 + lside * 1.55, 1.75, 44.0 + lz)
		night.add_child(lamp)
	for li in 4:
		var plamp := OmniLight3D.new()
		plamp.name = "PagodaLamp57_%d" % li
		plamp.light_energy = 1.2
		plamp.light_color = Color(1.0, 0.82, 0.45, 1.0)
		plamp.omni_range = 9.0
		var pang: float = float(li) * 1.5707963267948966
		plamp.position = Vector3(-20.0 + cos(pang) * 8.2, 1.65, -25.0 + sin(pang) * 8.2)
		night.add_child(plamp)

	var marker := Node3D.new()
	marker.name = "River57Applied"
	world.call_deferred("add_child", marker)
