extends Node3D
## Slice 130 — WATER + ATMOSPHERE AUDIT ROUND, AUDIT-FIRST,
## under the owner's goal "OpenTaxi Thadingyut Night level
## game graphic". BOUNDARY (binding): take ONLY the visual
## STANDARD from the reference video. NEVER copy OpenTaxi
## assets, branding, names, maps, layouts, or URLs; no club,
## no Yangon copy, no flying cars. World stays
## village/Mindon/fields. All content below is ORIGINAL.
## WATER AUDIT (audit130, live headless, S129 dressing
## complete, day time 300 then night time 900):
## - Main waters SHARE one ripple material (city_visual56
##   _water_mat: ripple texture, rough 0.08, metal 0.15,
##   uv scale 3) and it SCROLLS (city_night56 shimmer
##   0.02/0.01 per second, proven: uv_off day
##   (0.0205, 0.0103) -> night (0.0408, 0.0204)): village
##   Pond, River13, MindonWaterNS/North/SW, Pond62A/B.
##   Streams have their OWN faster material (V scroll
##   0.1847 -> 0.3673, water_flow65 0.18/s). GOOD.
## - Pond97 FLAT (REAL GAP): material_override is a flat
##   colour (0.20, 0.45, 0.75), rough 0.4, NO texture, NO
##   scroll (uv 0,0 day AND night) — while every other
##   pond ripples. Pond97 is a FESTIVAL site (24 reeds +
##   10 S124 water lanterns), not a backwater. FIXED:
##   Pond97 now shares the ripple material (shimmer
##   follows automatically, same instance).
## - Pond98_0/1 FLAT too (0.15, 0.35, 0.55, rough 0.4,
##   no texture, no scroll) — DEFERRED, NOT fixed:
##   world-edge ponds (-500,-300) + (2400,320), S127/S128
##   edge deferrals stand. (Audit correction: Pond98
##   reeds are 4 each, named Pond98_*_Reed*, so the
##   audit130 "Reed"-prefix count of 0 was a NAME miss,
##   not a missing ring — source realism98.gd:579.)
## - Mindon watercourses: NS (165 m) + North (162 m)
##   are NOT gaps — probe130b proves their edges are
##   dressed URBAN (NS: street lamps/poles, signboards,
##   house windows, lanes; North: MDHouse5, MindonDiag
##   Road, Ground127 patches, an existing MindonBankN).
##   Reeds there would clash with streets + houses.
##   SW (47 m, centre (68, 82.5)) IS bare: banks AND
##   strip EMPTY at every sample — REAL GAP, dressed
##   below (reeds + bank dirt, Walls guard applied).
## - Bank rings (S128 Pond62B pattern: ring radius =
##   water radius + 3.5, 8 dirt patches 3x0.06x3):
##   Pond97 reeds ring at r 12.5-13.1, banks 0 within
##   20 m, walls 0 in ring zone -> ring at r 15.5.
##   Pond62A reeds ring at r 6.5-7.1, banks 0 within
##   20 m (S128's "1 bank mesh at 62A" NOT reproduced
##   at any radius <= 20 m), walls 0 -> ring at r 9.5.
##   Village pond needs NO ring (plaza/scatter ground
##   within 20 m, reeds 6, lanterns 8 — dressed).
## ATMOSPHERE AUDIT (same run):
## - Sky grading WORKS day AND night (day_night tints
##   the runtime ProceduralSkyMaterial): day top
##   (0.30, 0.557, 0.817) / horizon (0.70, 0.787, 0.86);
##   night top (0.02, 0.029, 0.103) / horizon (0.07,
##   0.067, 0.155). Sun day 1.20 warm white, shadows
##   on; night sun floor 0.35 cool, MoonLight97 0.55
##   visible, Moon17 + Stars17 visible, omnis 167
##   total / 38 visible at night. NO sky gap.
## - FOG: DEFERRED with a MEASURED reason, plus a
##   CORRECTION to S120's record. S120's fog probe set
##   `fog_depth_enabled` — that property DOES NOT
##   EXIST in Godot 4.3 (script error, verified this
##   slice) — and never set `fog_mode`, so its depth
##   begin/end values were inert. S120 proved only
##   that a WorldEnvironment + Environment can be
##   instantiated, NOT that depth fog works or looks
##   right. This slice re-proved the REAL API exists
##   (fog_mode = FOG_MODE_DEPTH = 1 accepted, depth
##   begin/end set cleanly) — but the dummy renderer
##   on this VM returns EMPTY viewport textures
##   (rendertest: IMAGE EMPTY/NULL under both
##   --headless and --display-driver headless), so
##   fog's LOOK cannot be verified headless at all.
##   A wrong density would wash out the night or do
##   nothing, and node-visibility checks cannot catch
##   that (fog never hides nodes). Fog stays deferred
##   until a phone-visible test exists. Do NOT let
##   anyone cite S120's probe as fog evidence again.
## - Night water sheen: DEFERRED (aesthetic risk,
##   look unverifiable headless; water already catches
##   MoonLight97 0.55 + sun floor 0.35 via metal 0.15
##   / rough 0.08).
## PERFORMANCE: ZERO new OmniLight3Ds, ZERO colliders,
## ZERO per-frame work after _apply (items are ungated,
## visible day AND night, like S128 ground). Names
## (Bank130_/Reed130_) match NONE of perf120's hide
## prefixes (Blade93_/94_/95_/110_, Reed57_/62/107_/
## 108_ — "Reed130_" begins with "Reed1", not those).
## Single pass at frame >= 750 (after Realism129's
## 740), with a holders-ready retry gate (Pond97 +
## Pond62A + MindonWaterSW must exist, so a
## fast-forward ordering quirk can never strand it).

const City56Script = preload("res://city_visual56.gd")

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism130") != null:
		return
	var n: Node3D = Node3D.new()
	n.name = "Realism130"
	n.set_script(load("res://realism130.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 750:
		var w: Node3D = get_parent() as Node3D
		if _holders_ready(w):
			_done = true
			_apply(w)

static func _mat(c: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

static func _find_recursive(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f: Node = _find_recursive(c, nm)
		if f != null:
			return f
	return null

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node, r_top: float, r_bot: float, h: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _holders_ready(world: Node3D) -> bool:
	if world == null:
		return false
	if _find_recursive(world, "Pond97") == null:
		return false
	if _find_recursive(world, "Pond62A") == null:
		return false
	if _find_recursive(world, "MindonWaterSW") == null:
		return false
	return true

func _ground_y(world: Node3D) -> float:
	var gm: Node3D = world.get_node_or_null("GroundMesh") as Node3D
	if gm != null:
		return gm.global_position.y
	return 0.0

func _walls_centres(world: Node3D) -> Array:
	var out: Array = []
	var stack: Array = [world]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if x is MeshInstance3D and String(x.name).contains("Walls"):
			out.append((x as Node3D).global_position)
	return out

func _wall_clear(walls: Array, x: float, z: float, dist: float) -> bool:
	for w in walls:
		var wp: Vector3 = w
		if Vector2(wp.x - x, wp.z - z).length() <= dist:
			return false
	return true

func _ring(world: Node3D, cx: float, cz: float, radius: float, tag: String, gy: float) -> int:
	var dirt: StandardMaterial3D = _mat(Color(0.52, 0.42, 0.30))
	var dirt2: StandardMaterial3D = _mat(Color(0.45, 0.35, 0.25))
	var dry: StandardMaterial3D = _mat(Color(0.62, 0.55, 0.38))
	var mats: Array = [dirt, dirt2, dry]
	var n: int = 0
	for k in range(8):
		var a: float = float(k) / 8.0 * 6.283185307179586
		var px: float = cx + radius * cos(a)
		var pz: float = cz + radius * sin(a)
		_box(world, Vector3(3.0, 0.06, 3.0), mats[k % 3], Vector3(px, gy + 0.03, pz), "Bank130_%s_%d" % [tag, k])
		n += 1
	return n

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var gy: float = _ground_y(world)
	var walls: Array = _walls_centres(world)
	# 1. Pond97 water: flat colour -> shared ripple material.
	var water_fixed: int = 0
	var pond97: Node = _find_recursive(world, "Pond97")
	if pond97 != null and pond97 is MeshInstance3D:
		var wm: Material = City56Script._water_mat
		if wm == null:
			var pond: Node = _find_recursive(world, "Pond")
			if pond != null and pond is MeshInstance3D:
				wm = (pond as MeshInstance3D).get_surface_override_material(0)
		if wm != null:
			(pond97 as MeshInstance3D).material_override = wm
			water_fixed = 1
	# 2. Bank rings (S128 Pond62B pattern: radius = water + 3.5).
	var ring97: int = _ring(world, -350.0, 0.0, 15.5, "Pond97", gy)
	var ring62a: int = _ring(world, 300.0, -60.0, 9.5, "Pond62A", gy)
	# 3. MindonWaterSW banks: reeds both sides + dirt patches.
	# Course centre x 68, z 58.9..106.1, half-width 4. Reeds at
	# |x-68| = 5.5 (1.5 m outside the water edge); dirt at 6.5.
	# Banks proven empty by probe130b; Walls guard still applied.
	var reed_m: StandardMaterial3D = _mat(Color(0.30, 0.50, 0.20), 0.9)
	var dirt: StandardMaterial3D = _mat(Color(0.52, 0.42, 0.30))
	var dirt2: StandardMaterial3D = _mat(Color(0.45, 0.35, 0.25))
	var reeds: int = 0
	for side in [-1.0, 1.0]:
		var rx: float = 68.0 + side * 5.5
		for zi in range(6):
			var rz: float = 62.0 + float(zi) * 8.0
			if not _wall_clear(walls, rx, rz, 8.0):
				continue
			_cyl(world, 0.05, 0.05, 1.2, reed_m, Vector3(rx, 0.6, rz), "Reed130_SW_%d_%d" % [int(side + 1.0), zi])
			reeds += 1
	var swdirt: int = 0
	for side2 in [-1.0, 1.0]:
		var dx: float = 68.0 + side2 * 6.5
		for dz in [66.0, 82.0, 98.0]:
			if not _wall_clear(walls, dx, dz, 8.0):
				continue
			_box(world, Vector3(3.0, 0.06, 3.0), dirt if int(side2 + 1.0) == 0 else dirt2, Vector3(dx, gy + 0.03, dz), "Bank130_SW_%d_%d" % [int(side2 + 1.0), int(dz)])
			swdirt += 1
	print("REALISM130 dressed: pond97_water_fixed=", water_fixed, " ring97=", ring97, " ring62a=", ring62a, " sw_reeds=", reeds, " sw_dirt=", swdirt)
