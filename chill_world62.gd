extends RefCounted
## Slice 62 — "big beautiful chill Myanmar world", part 1: EAST expansion.
## Owner directions 2026-10-23 00:06 + 00:08 + 00:11: the old world
## (x -70..250, z -110..110) ends after a short walk, houses were
## placed arbitrarily and are not Myanmar traditional styles, and the
## owner wants wide roads + small lanes to drive (car, bullock cart,
## motorcycle) while looking at beautiful surroundings and chilling.
## What this file builds, all runtime-only (main.tscn itself is
## touched ONLY for the ground-plane resize + bounds, see player.gd):
## - East Fields district east of Mindon: a WIDE main road (12 m) from
##   x 250 to 445 at z 0 with centre dashes + edge lines, two small
##   side lanes (north lane x 340, south lane x 390), lane scenery.
## - 12 Myanmar traditional STILT houses placed ALONG the roads
##   (never scattered): stilt posts, wood walls, tin gable roofs,
##   verandas, windows on the shared DayNight window material (so
##   they glow at night under the existing <0.15 rule), doors, and
##   a layer-1 StaticBody3D collider per house (Slice 38 pattern).
## - Living-nature groundwork: 19 trees, 2 ponds, a stream at x 350
##   (split so the main road slab covers the crossing), reeds,
##   ~34 flowers along the lanes/roads, 6 streetlights.
## - The animated part (sway, seasons, lamps, rain) lives in
##   chill_controller62.gd, added as a runtime Node3D child; the
##   TPP/FPP toggle lives in camera.gd (cycle_view) with a
##   touch-first View button + a Season button in the More stack row.
## Idempotent: if EastDistrict62 already exists, dress() returns.
## No opponent map, names, structure or code is used: positions are
## new Muse district coordinates along the new roads, and the house
## style is the Graphics Master Prompt look ONLY (graphics-only
## owner clarification 2026-10-22 22:55 +07).

const City56Script = preload("res://city_visual56.gd")

const ROAD_X0: float = 250.0
const ROAD_X1: float = 445.0

static func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

static func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61 hud_fix61b._set_rect, so these
	# buttons scale exactly like the rest of the HUD (raw offsets
	# do NOT: a raw-offset button rendered 56 px tall for a 36 px
	# span in the audit viewport, overlapping Rain by 6 px).
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0

static func _cyl(parent: Node3D, nm: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = h
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node3D, nm: String, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _stilt_house(parent: Node3D, idx: int, x: float, z: float, rot_y: float, wall_mat: Material, roof_mat: Material, win_mat: Material, wood_mat: Material, door_mat: Material) -> void:
	var g := Node3D.new()
	g.name = "StiltHouse62_%d" % idx
	g.position = Vector3(x, 0.0, z)
	g.rotation.y = rot_y
	parent.add_child(g)
	# Stilt posts (1.2 m, the traditional raised-floor height).
	for px in [-2.8, 0.0, 2.8]:
		for pz in [-1.8, 1.8]:
			_cyl(g, "Post62", 0.18, 0.2, 1.2, Vector3(px, 0.6, pz), wood_mat)
	# Floor, walls, gable roof (two slanted slabs), veranda, door.
	_box(g, "Floor62", Vector3(7.0, 0.3, 5.0), Vector3(0.0, 1.35, 0.0), wood_mat)
	_box(g, "Walls62", Vector3(6.6, 2.2, 4.6), Vector3(0.0, 2.6, 0.0), wall_mat)
	_box(g, "RoofL62", Vector3(7.4, 0.15, 2.9), Vector3(0.0, 3.95, -1.25), roof_mat, Vector3(0.5, 0.0, 0.0))
	_box(g, "RoofR62", Vector3(7.4, 0.15, 2.9), Vector3(0.0, 3.95, 1.25), roof_mat, Vector3(-0.5, 0.0, 0.0))
	_box(g, "Veranda62", Vector3(3.0, 0.15, 1.6), Vector3(0.0, 1.35, 3.2), wood_mat)
	_box(g, "Door62", Vector3(0.9, 1.8, 0.12), Vector3(-1.2, 2.4, 2.36), door_mat)
	if win_mat != null:
		_box(g, "Window62A", Vector3(0.7, 0.7, 0.1), Vector3(1.2, 2.7, 2.36), win_mat)
		_box(g, "Window62B", Vector3(0.7, 0.7, 0.1), Vector3(2.4, 2.7, 2.36), win_mat)
	# Solid: one layer-1 collider for the whole footprint (Slice 38).
	var body := StaticBody3D.new()
	body.name = "StiltHouse62Solid_%d" % idx
	body.collision_layer = 1
	g.add_child(body)
	var shape := CollisionShape3D.new()
	shape.name = "Shape62"
	var bs := BoxShape3D.new()
	bs.size = Vector3(7.0, 3.8, 5.0)
	shape.shape = bs
	shape.position = Vector3(0.0, 1.9, 0.0)
	body.add_child(shape)

static func _tree(parent: Node3D, idx: int, x: float, z: float, canopy_mat: Material, trunk_mat: Material) -> void:
	var g := Node3D.new()
	g.name = "Chill62_Tree_%d" % idx
	g.position = Vector3(x, 0.0, z)
	parent.add_child(g)
	_cyl(g, "Trunk62", 0.22, 0.3, 2.6, Vector3(0.0, 1.3, 0.0), trunk_mat)
	_sphere(g, "Chill62_Canopy_%d" % idx, 1.7, Vector3(0.0, 3.4, 0.0), canopy_mat)
	_sphere(g, "Chill62_CanopyTop_%d" % idx, 1.1, Vector3(0.5, 4.4, 0.0), canopy_mat)

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("EastDistrict62") != null:
		return
	var win_mat: Material = null
	var dn := world.get_node_or_null("DayNight")
	if dn != null:
		win_mat = dn.get("window_material") as Material
	# Water: reuse Slice 56's shared ripple material (already scrolled
	# by city_night56's tick); fall back to a plain blue material.
	var water_mat: Material = City56Script._water_mat
	if water_mat == null:
		water_mat = _mat(Color(0.15, 0.45, 0.75, 0.9), 0.1)
	var asphalt := _mat(Color(0.16, 0.16, 0.18, 1.0), 0.95)
	var line_white := _mat(Color(0.95, 0.95, 0.9, 1.0), 0.8)
	var dirt := _mat(Color(0.55, 0.42, 0.28, 1.0), 1.0)
	var wood := _mat(Color(0.45, 0.3, 0.16, 1.0), 0.9)
	var trunk_m := _mat(Color(0.35, 0.22, 0.12, 1.0), 1.0)
	var door_m := _mat(Color(0.25, 0.15, 0.08, 1.0), 0.9)
	var wall_a := _mat(Color(0.72, 0.58, 0.38, 1.0), 0.9)
	var wall_b := _mat(Color(0.9, 0.86, 0.78, 1.0), 0.9)
	var roof_red := _mat(Color(0.6, 0.18, 0.14, 1.0), 0.7)
	var roof_grey := _mat(Color(0.45, 0.47, 0.5, 1.0), 0.7)
	var canopy_a := _mat(Color(0.1, 0.42, 0.16, 1.0), 1.0)
	var canopy_b := _mat(Color(0.16, 0.5, 0.2, 1.0), 1.0)
	var reed_m := _mat(Color(0.25, 0.5, 0.2, 1.0), 1.0)
	var lamp_m := StandardMaterial3D.new()
	lamp_m.albedo_color = Color(1.0, 0.85, 0.5, 1.0)
	lamp_m.emission_enabled = false
	lamp_m.emission = Color(1.0, 0.85, 0.5, 1.0)
	lamp_m.emission_energy_multiplier = 2.0

	var dist := Node3D.new()
	dist.name = "EastDistrict62"
	# Deferred add: player._ready runs while Main is still setting
	# up children, so a direct add_child fails ("parent busy") —
	# the same reason Slice 56/59 dressing defers its group adds.
	# Content is built onto dist before the add, so nothing pops.
	world.call_deferred("add_child", dist)

	# Wide main road (12 m) along z 0, x 250..445, centre dashes.
	var road_cx := (ROAD_X0 + ROAD_X1) * 0.5
	var road_len := ROAD_X1 - ROAD_X0
	_box(dist, "MainRoad62", Vector3(road_len, 0.12, 12.0), Vector3(road_cx, 0.06, 0.0), asphalt)
	_box(dist, "RoadEdgeN62", Vector3(road_len, 0.03, 0.25), Vector3(road_cx, 0.13, -5.5), line_white)
	_box(dist, "RoadEdgeS62", Vector3(road_len, 0.03, 0.25), Vector3(road_cx, 0.13, 5.5), line_white)
	var dx := ROAD_X0 + 5.0
	while dx < ROAD_X1 - 2.0:
		_box(dist, "RoadDash62", Vector3(2.0, 0.03, 0.3), Vector3(dx, 0.13, 0.0), line_white)
		dx += 8.0
	# Small side lanes (dirt): north lane x 340 (z 0..-100), south x 390 (z 0..80).
	_box(dist, "LaneNorth62", Vector3(5.0, 0.1, 100.0), Vector3(340.0, 0.05, -50.0), dirt)
	_box(dist, "LaneSouth62", Vector3(5.0, 0.1, 80.0), Vector3(390.0, 0.05, 40.0), dirt)

	# Stilt houses along the roads (front faces the road).
	var houses: Array = [
		[270.0, -16.0, 0.0, wall_a, roof_red], [300.0, -16.0, 0.0, wall_b, roof_grey],
		[330.0, -16.0, 0.0, wall_a, roof_grey], [360.0, -16.0, 0.0, wall_b, roof_red],
		[390.0, -16.0, 0.0, wall_a, roof_red], [420.0, -16.0, 0.0, wall_b, roof_grey],
		[285.0, 16.0, PI, wall_b, roof_red], [315.0, 16.0, PI, wall_a, roof_grey],
		[345.0, 16.0, PI, wall_b, roof_grey], [405.0, 16.0, PI, wall_a, roof_red],
		[330.0, -40.0, PI * 0.5, wall_a, roof_grey], [330.0, -70.0, PI * 0.5, wall_b, roof_red],
	]
	var hi := 0
	for h in houses:
		_stilt_house(dist, hi, float(h[0]), float(h[1]), float(h[2]), h[3], h[4], win_mat, wood, door_m)
		hi += 1

	# Trees: road edges, lanes, ponds/fields (kept clear of the road
	# slab, house footprints and the stream crossing at x 350).
	var tree_spots: Array = [
		[265.0, -10.0], [285.0, 10.0], [305.0, -10.0], [325.0, 10.0],
		[365.0, -10.0], [385.0, 10.0], [405.0, -10.0], [425.0, 10.0],
		[332.0, -30.0], [348.0, -60.0], [332.0, -90.0], [382.0, 20.0],
		[398.0, 60.0], [290.0, -50.0], [310.0, -80.0], [420.0, 40.0],
		[430.0, -40.0], [280.0, 50.0], [440.0, 70.0],
	]
	var ti := 0
	for t in tree_spots:
		_tree(dist, ti, float(t[0]), float(t[1]), canopy_a if ti % 2 == 0 else canopy_b, trunk_m)
		ti += 1

	# Stream at x 350 (two segments; the road slab covers the gap),
	# ponds, reeds on the stream banks.
	_box(dist, "StreamNorth62", Vector3(6.0, 0.1, 102.0), Vector3(350.0, 0.08, -59.0), water_mat)
	_box(dist, "StreamSouth62", Vector3(6.0, 0.1, 52.0), Vector3(350.0, 0.08, 34.0), water_mat)
	var pond_a := MeshInstance3D.new()
	pond_a.name = "Pond62A"
	var pm_a := CylinderMesh.new()
	pm_a.top_radius = 6.0
	pm_a.bottom_radius = 6.0
	pm_a.height = 0.1
	pond_a.mesh = pm_a
	pond_a.position = Vector3(300.0, 0.08, -60.0)
	pond_a.set_surface_override_material(0, water_mat)
	dist.add_child(pond_a)
	var pond_b := MeshInstance3D.new()
	pond_b.name = "Pond62B"
	var pm_b := CylinderMesh.new()
	pm_b.top_radius = 5.0
	pm_b.bottom_radius = 5.0
	pm_b.height = 0.1
	pond_b.mesh = pm_b
	pond_b.position = Vector3(415.0, 0.08, 45.0)
	pond_b.set_surface_override_material(0, water_mat)
	dist.add_child(pond_b)
	for rz in [-90.0, -75.0, -45.0, -30.0, 20.0, 50.0]:
		_cyl(dist, "Reed62", 0.04, 0.05, 0.9, Vector3(346.5, 0.45, rz), reed_m)
		_cyl(dist, "Reed62", 0.04, 0.05, 0.9, Vector3(353.5, 0.45, rz + 5.0), reed_m)

	# Flowers along lanes and road edges (sway via the controller).
	var flower_mats: Array = [_mat(Color(0.95, 0.4, 0.6, 1.0), 0.8), _mat(Color(0.95, 0.85, 0.2, 1.0), 0.8), _mat(Color(0.95, 0.95, 0.95, 1.0), 0.8)]
	var fi := 0
	for fz in [-15.0, -30.0, -45.0, -60.0, -75.0, -90.0]:
		for fx in [336.0, 344.0]:
			var fg := Node3D.new()
			fg.name = "Chill62_Flower_%d" % fi
			fg.position = Vector3(fx, 0.0, fz)
			dist.add_child(fg)
			_cyl(fg, "Stem62", 0.03, 0.03, 0.4, Vector3(0.0, 0.2, 0.0), reed_m)
			_sphere(fg, "Head62", 0.13, Vector3(0.0, 0.45, 0.0), flower_mats[fi % 3])
			fi += 1
	for fz in [15.0, 30.0, 45.0, 60.0, 75.0]:
		for fx in [386.0, 394.0]:
			var fg := Node3D.new()
			fg.name = "Chill62_Flower_%d" % fi
			fg.position = Vector3(fx, 0.0, fz)
			dist.add_child(fg)
			_cyl(fg, "Stem62", 0.03, 0.03, 0.4, Vector3(0.0, 0.2, 0.0), reed_m)
			_sphere(fg, "Head62", 0.13, Vector3(0.0, 0.45, 0.0), flower_mats[fi % 3])
			fi += 1
	for fx in range(260, 441, 15):
		var fz2 := -7.5 if (int(fx) / 15) % 2 == 0 else 7.5
		var fg := Node3D.new()
		fg.name = "Chill62_Flower_%d" % fi
		fg.position = Vector3(float(fx), 0.0, fz2)
		dist.add_child(fg)
		_cyl(fg, "Stem62", 0.03, 0.03, 0.4, Vector3(0.0, 0.2, 0.0), reed_m)
		_sphere(fg, "Head62", 0.13, Vector3(0.0, 0.45, 0.0), flower_mats[fi % 3])
		fi += 1

	# Streetlights along the main road (glow gated by the controller).
	for li in range(6):
		var lx := 270.0 + li * 32.0
		_cyl(dist, "LampPole62", 0.12, 0.14, 4.5, Vector3(lx, 2.25, -7.0), trunk_m)
		_sphere(dist, "Chill62_Lamp_%d" % li, 0.25, Vector3(lx, 4.6, -7.0), lamp_m)

	# Controller: created exactly once here (deferred add, see the
	# dist note above), used by the Season button below.
	var ctrl := Node3D.new()
	ctrl.name = "ChillController62"
	ctrl.set_script(load("res://chill_controller62.gd"))
	world.call_deferred("add_child", ctrl)

	# Minimap roads for the new district (same MapTransform mapping
	# the dots use; panel size falls back exactly like Slice 61).
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer != null:
		var panel := layer.get_node_or_null("MinimapPanel") as Control
		if panel != null:
			var psize := panel.size
			if psize.x <= 0.0 or psize.y <= 0.0:
				psize = Vector2(179.0, 180.0)
			var roads: Array = [
				[Vector2(250.0, 0.0), Vector2(445.0, 0.0)],
				[Vector2(340.0, 0.0), Vector2(340.0, -100.0)],
				[Vector2(390.0, 0.0), Vector2(390.0, 80.0)],
			]
			for ri in range(roads.size()):
				var lname := "MinimapRoad62_%d" % ri
				if panel.get_node_or_null(lname) != null:
					continue
				var line := Line2D.new()
				line.name = lname
				line.width = 2.0
				line.default_color = Color(0.95, 0.85, 0.4, 0.9)
				panel.add_child(line)
				var pts := PackedVector2Array()
				for w in roads[ri]:
					pts.append(MapTransform.world_to_panel(w.x, w.y, psize))
				line.points = pts

		# Touch-first buttons in the More-stack row (y 560: Rain
		# renders to y 560 and cluster row 2 starts at y 610, so
		# the 50 px rendered height edge-touches both neighbours
		# with zero overlap in the audit): View cycles TPP/FPP/
		# cart-top; Season cycles နွေ/မိုး/ဆောင်း. Font size 14 +
		# short labels so the buttons stay one line tall (a wrapped
		# label rendered 56 px tall and overlapped Rain).
		# Slice 63 resolved the stack-vs-cluster overlap class
		# noted here before: while More is open, player.gd hides
		# Talk / Vehicle / ThrottleUp (the only cluster buttons
		# sharing the stack's rects), so the stack is disjoint
		# from the cluster in every More × driving state; this
		# row itself is clear of the stack and of cluster row 2
		# in all states.
		# Slice 95 RETIREMENT: ViewButton62 is gone — the tiny
		# More-buried "View" button is replaced by the dedicated
		# visible ViewButton96 (realism96.gd, main HUD). Nothing
		# is created here any more; the controller force-hides
		# any stale instance so two view buttons can never exist.
		var season_btn := layer.get_node_or_null("SeasonButton62") as Button
		if season_btn == null:
			season_btn = Button.new()
			season_btn.name = "SeasonButton62"
			season_btn.text = "နွေ"
			season_btn.add_theme_font_size_override("font_size", 14)
			layer.add_child(season_btn)
			if ctrl.has_method("cycle_season"):
				season_btn.pressed.connect(Callable(ctrl, "cycle_season"))
		_set_rect(season_btn, 1174.0, 560.0, 70.0, 36.0)
		season_btn.visible = false
