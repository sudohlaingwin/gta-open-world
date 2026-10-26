extends Node3D
## Slice 131 — PAGODA + LANDMARK GRANDEUR AUDIT ROUND,
## AUDIT-FIRST, under the owner's goal "OpenTaxi Thadingyut
## Night level game graphic". BOUNDARY (binding): take ONLY
## the visual STANDARD from the reference video. NEVER copy
## OpenTaxi assets, branding, names, maps, layouts, or URLs;
## no club, no Yangon copy, no flying cars. World stays
## village/Mindon/fields. All content below is ORIGINAL.
## PAGODA AUDIT (audit131, live headless, S130 dressing
## complete, day time 300 then night time 900; 6 m camera
## read proxied honestly by emissive/omni counts within
## 15 m of each site — the dummy renderer returns no
## pixels, S130, so no look claim is made headless):
## - Gold emission is OFF on EVERY pagoda (scene gold
##   (1, 0.84, 0) metal 0.8; S94 gold (0.85, 0.65, 0.25)
##   metal 0): at night gold bodies catch only moonlight
##   (0.55) + sun floor (0.35) + whatever nearby omni
##   exists. No pagoda GLOWS.
## - MindonPagoda (108,-62) is the DARKEST pagoda in the
##   game at night: near-probe (probe131b, player at 6 m,
##   perf120 force_pass at that position) proves
##   emis_vis_r15 = 0 and ZERO festival dressing, versus
##   old Pagoda (4 lamp omnis + flags + lanterns) and the
##   S94 pagodas (1 corner lantern head + omni each).
##   The audit's omni vis=false was a perf120 FAR-CULL
##   artifact (player sat at spawn) — near-probe proves
##   Omni97_Pagoda DOES turn visible when near. So the
##   gap is NOT missing light: it is missing GLOW and
##   missing FESTIVAL. Fixed below, emissive-first.
## - Landmarks are NOT gaps: MindonPost/Hospital/Edu/
##   Temple/MRTV/Shops read 23-29 emissive window glows
##   within 12 m at night, market reads flags 14 +
##   bunting + lamps 4. NOTHING shipped for them (would
##   be padding).
## SHIPPED (40 meshes, 0 new omnis, 0 colliders):
## - Night-gated GOLD GLOW bands (emissive gold, energy
##   1.2) hugging each gold pagoda's own geometry (radii
##   from live subresources / S94 source dims, proud by
##   0.06-0.08 so they never z-fight S57's day bands):
##   scene pagodas x2 (bell bands y 4.0 r 2.85 + y 5.5
##   r 2.35; spire bands y 7.5 r 1.38 + y 9.9 r 0.76) =
##   8; Gold94 (bell equator band y 3.0 r 2.28 + spire
##   bands y 6.0 r 0.42 + y 7.2 r 0.24) = 3; White94
##   (gold-band glow y 3.4 r 2.08 + spire band y 5.2
##   r 0.30) = 2; Forest94 (bell band y 1.6 r 1.28 +
##   spire band y 3.2 r 0.20) = 2; Hill94 (spire band
##   y 4.3 r 0.14) = 1. Brick94 has NO gold: its 4
##   niches (unrotated boxes, S94 source) get warm
##   niche glows instead = 4. Total glow = 20.
## - MindonPagoda FESTIVAL (its zero, fixed): 8 lantern
##   posts at r 8.2 on the platform (S57 old-Pagoda
##   pattern) + 8 warm lamp heads (NIGHT-gated,
##   emissive-only, NO new omnis — Omni97_Pagoda
##   already lights the site) + 4 festival flags on
##   alternating posts (S129 gold/pink/cyan/warm-white
##   palette, ungated like S94 Forest flags) = 20.
## NIGHT-GATING (S120/S124/S129 pattern, NOT S124's bug):
## glow bands + lamp heads are written visible ONLY on
## day/night state CHANGE (one daylight() call + one
## comparison per frame, zero writes otherwise). At
## _apply the visibility is set from the LIVE daylight
## reading, so the first-frame empty-list bug (S124)
## cannot recur. Posts + flags are ungated structure
## (read day and night, like S94 Forest flags).
## PERFORMANCE: ZERO new OmniLight3Ds, ZERO colliders,
## ZERO per-frame mesh work (one comparison per frame).
## Names (Glow131_/Lamp131_/Flag131_) match NONE of
## perf120's hide prefixes (Blade93_/94_/95_/110_,
## Reed57_/62/107_/108_ — S124 Lamp124_ + S127 Lamp127_
## + S129 Flag129_ precedents verified visible at spawn
## force_pass). Single pass at frame >= 760 (after
## Realism130's 750), with a holders-ready retry gate
## (all 7 pagoda holders must exist, so a fast-forward
## ordering quirk can never strand it).

var _frames: int = 0
var _done: bool = false
var _night_items: Array = []
var _night_now: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism131") != null:
		return
	var n: Node3D = Node3D.new()
	n.name = "Realism131"
	n.set_script(load("res://realism131.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 760:
		var w: Node3D = get_parent() as Node3D
		if _holders_ready(w):
			_done = true
			_apply(w)
			return
	if _done:
		var w2: Node3D = get_parent() as Node3D
		if w2 == null:
			return
		var dn: Node = w2.get_node_or_null("DayNight")
		if dn == null or not dn.has_method("daylight"):
			return
		var is_night: bool = float(dn.call("daylight")) < 0.15
		if is_night != _night_now:
			_night_now = is_night
			for it in _night_items:
				(it as Node3D).visible = is_night

static func _glow_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.65, 0.25, 1.0)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.8, 0.3, 1.0)
	m.emission_energy_multiplier = 1.2
	m.roughness = 0.5
	m.metallic = 0.0
	return m

static func _lamp_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.82, 0.45, 1.0)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.82, 0.45, 1.0)
	m.emission_energy_multiplier = 1.5
	m.roughness = 0.7
	m.metallic = 0.0
	return m

static func _warm_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.75, 0.4, 1.0)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.75, 0.4, 1.0)
	m.emission_energy_multiplier = 1.0
	m.roughness = 0.8
	m.metallic = 0.0
	return m

static func _plain_mat(c: Color, rough: float = 0.9) -> StandardMaterial3D:
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
	for nm in ["Pagoda", "MindonPagoda", "PagodaGold94", "PagodaBrick94", "PagodaWhite94", "PagodaForest94", "PagodaHill94"]:
		if _find_recursive(world, nm) == null:
			return false
	return true

func _glow_band(parent: Node, r: float, y: float, tag: String, mat: Material) -> void:
	var band: MeshInstance3D = _cyl(parent, r, r, 0.2, mat, Vector3(0.0, y, 0.0), "Glow131_" + tag)
	_night_items.append(band)

func _scene_pagoda_glow(pag: Node, tag: String, mat: Material) -> void:
	# Bell: cylinder bottom r 3.0 -> top r 1.8 over y 3.4..6.9.
	_glow_band(pag, 2.85, 4.0, tag + "_BellLo", mat)
	_glow_band(pag, 2.35, 5.5, tag + "_BellHi", mat)
	# Spire: bottom r 1.4 -> top r 0.1 over y 6.9..11.9;
	# radii proud of S57's day bands (1.30 / 0.68).
	_glow_band(pag, 1.38, 7.5, tag + "_SpireLo", mat)
	_glow_band(pag, 0.76, 9.9, tag + "_SpireHi", mat)

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var glow: StandardMaterial3D = _glow_mat()
	var warm: StandardMaterial3D = _warm_mat()
	var lamp: StandardMaterial3D = _lamp_mat()
	var wood_dark: StandardMaterial3D = _plain_mat(Color(0.36, 0.23, 0.12, 1.0))
	var flag_cols: Array = [Color(0.85, 0.65, 0.25, 1.0), Color(0.95, 0.4, 0.6, 1.0), Color(0.2, 0.7, 0.85, 1.0), Color(1.0, 0.9, 0.7, 1.0)]
	var n_glow: int = 0
	var n_lamp: int = 0
	var n_flag: int = 0
	# 1. Scene pagodas: gold glow bands (same geometry both).
	for pair in [["Pagoda", "Old"], ["MindonPagoda", "Mindon"]]:
		var pag: Node = _find_recursive(world, String(pair[0]))
		if pag != null:
			_scene_pagoda_glow(pag, String(pair[1]), glow)
			n_glow += 4
	# 2. Gold94: bell equator band + 2 spire bands.
	var g94: Node = _find_recursive(world, "PagodaGold94")
	if g94 != null:
		_glow_band(g94, 2.28, 3.0, "Gold94_Bell", glow)
		_glow_band(g94, 0.42, 6.0, "Gold94_SpireLo", glow)
		_glow_band(g94, 0.24, 7.2, "Gold94_SpireHi", glow)
		n_glow += 3
	# 3. White94: gold-band glow + spire band.
	var w94: Node = _find_recursive(world, "PagodaWhite94")
	if w94 != null:
		_glow_band(w94, 2.08, 3.4, "White94_Band", glow)
		_glow_band(w94, 0.30, 5.2, "White94_Spire", glow)
		n_glow += 2
	# 4. Forest94: bell equator band + spire band.
	var f94: Node = _find_recursive(world, "PagodaForest94")
	if f94 != null:
		_glow_band(f94, 1.28, 1.6, "Forest94_Bell", glow)
		_glow_band(f94, 0.20, 3.2, "Forest94_Spire", glow)
		n_glow += 2
	# 5. Hill94: spire band only (dome + base are white).
	var h94: Node = _find_recursive(world, "PagodaHill94")
	if h94 != null:
		_glow_band(h94, 0.14, 4.3, "Hill94_Spire", glow)
		n_glow += 1
	# 6. Brick94: NO gold — warm niche glows instead. Niches
	# are UNROTATED boxes (S94 source) at r 3.3 cardinals,
	# faces at r 3.4; glow boxes sit 0.05 proud of each face.
	var b94: Node = _find_recursive(world, "PagodaBrick94")
	if b94 != null:
		var faces: Array = [[0.0, 3.45, Vector3(0.6, 0.9, 0.05)], [3.45, 0.0, Vector3(0.05, 0.9, 0.6)], [0.0, -3.45, Vector3(0.6, 0.9, 0.05)], [-3.45, 0.0, Vector3(0.05, 0.9, 0.6)]]
		for fi in range(4):
			var f: Array = faces[fi]
			var gl: MeshInstance3D = _box(b94, Vector3(f[2]), warm, Vector3(float(f[0]), 1.0, float(f[1])), "Glow131_Brick94_Niche%d" % fi)
			_night_items.append(gl)
			n_glow += 1
	# 7. MindonPagoda festival: 8 lantern posts (S57 pattern,
	# r 8.2 on the r 9.0 platform) + 8 night-gated heads +
	# 4 flags on alternating posts (S129 palette).
	var mp: Node = _find_recursive(world, "MindonPagoda")
	if mp != null:
		for ai in range(8):
			var ang: float = float(ai) * 0.7853981633974483
			var px: float = cos(ang) * 8.2
			var pz: float = sin(ang) * 8.2
			_box(mp, Vector3(0.12, 1.1, 0.12), wood_dark, Vector3(px, 0.95, pz), "Lamp131_MindonPost_%d" % ai)
			n_lamp += 1
			var head: MeshInstance3D = _box(mp, Vector3(0.28, 0.28, 0.28), lamp, Vector3(px, 1.65, pz), "Lamp131_MindonHead_%d" % ai)
			_night_items.append(head)
			n_lamp += 1
			if ai % 2 == 0:
				_box(mp, Vector3(0.5, 0.3, 0.03), _plain_mat(flag_cols[(ai / 2) % 4], 0.8), Vector3(px + 0.28, 1.95, pz), "Flag131_Mindon_%d" % ai)
				n_flag += 1
	# Night-gate initial state from the LIVE daylight reading
	# (game starts at night; sims jump time — never assume).
	var dn: Node = world.get_node_or_null("DayNight")
	_night_now = true
	if dn != null and dn.has_method("daylight"):
		_night_now = float(dn.call("daylight")) < 0.15
	for it in _night_items:
		(it as Node3D).visible = _night_now
	print("REALISM131 dressed: glow=", n_glow, " lamp_posts_heads=", n_lamp, " flags=", n_flag, " night_items=", _night_items.size(), " night_now=", _night_now)
