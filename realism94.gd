extends Node3D
## Slice 94 GRAPHICS BATCH 2 (owner standing rules: ~50 distinct
## items per push, graphics-first, detail direction continues).
## Runtime dressing ONLY: no .tscn edits, no gameplay, no bus
## systems, no control changes, minibus NOT rewired. Everything
## here is StandardMaterial3D, zero colliders, no dead specular
## lines, and detailed realistic-STYLISED procedural work — not
## scanned photorealism, not claimed as such.
##
## What this batch adds (each grep-proven missing before it was
## written; see the item notes inline):
##   PEOPLE FIRST (owner verdict 2026-10-23: S93 figures still
##     read as wooden blocks at the 6 m camera; owner
##     reference sheets 2026-10-23 define the outfits): a
##     full humanoid rebuild of the player + all 18
##     villagers — tapered limbs with joint spheres, elbows
##     bent 0.25 rad, shaped chest/waist torso + neck,
##     re-seated shaped face (eyes/nose/mouth/ears), 4 skin
##     tones, sheet outfits by sex (player always male;
##     villagers split by name hash % 3): male = white
##     taikpon + collar + cuffs + striped longyi + front
##     knot + side-parted hair; female A = white lace
##     off-shoulder top + purple longyi + bun + flower +
##     heels; female B = pale-pink long-sleeve top + pink
##     longyi + bun + flower. Stripes/patterns are
##     geometry/colour bands (no texture-painting system
##     exists — bands approximate the woven patterns, not
##     pixel-matched). Scarves + walking sticks from the
##     pre-sheet plan are DROPPED (not sheet outfits).
##     Legs are deliberately NOT rebuilt: the longyi tube
##     fully hides them (see _people). 19 figures.
##   SHEET TREES (5 types): toddy palm (fan + dry
##     fronds), coconut palm (curved trunk + arching
##     fronds + nuts), flame tree (spreading branches +
##     red blooms), banana clump (broad leaves + bunch +
##     purple bud), banyan (multi-trunk + aerial roots +
##     shrine). SHEET PAGODAS (5 NEW landmarks, existing
##     pagoda untouched): golden Shwedagon-style, brick
##     Bagan-style, white alabaster, forest monastic,
##     hilltop miniature. STILT-HOUSE RESTYLE (4 existing
##     houses, positions + colliders untouched): stairs,
##     veranda rail, rust roof patches, firewood, pot,
##     back-yard clothesline. Honest roof note: rust
##     PATCH strips on the existing slabs, not a roof
##     replacement (that would double the roofline).
##   GRASS (12 tuft clusters x 3 blades): route ends, village
##     ground, Mindon street edges, hamlet spur edges, pagoda
##     ground. PLAIN LIMIT (same as Slice 93): tuft CLUSTERS
##     near paths and inhabited areas only, NOT per-blade cover
##     of the whole 2520 m world. Blades sway via the reused
##     name-agnostic grass_sway93.gd (it tilts every child tuft).
##   TREES (6 detail sets): Mindon MD1/MD2/MD3, hamlet x2, East
##     Fields x1 — root flare + two angled branches + a second
##     offset canopy sphere + fruit/flowers, same pattern as
##     Slice 93's village sets, at trees Slice 93 did not touch.
##   PEOPLE (scarves + head-wraps + walking sticks): scarves on
##     the player + first 7 villagers; gaungbaung-style head
##     wraps on the player + every villager WITHOUT a StrawHat58
##     (hatted figures keep their hats — no double headwear);
##     walking sticks on the first 3 villagers, planted at
##     ground level beside the body (not swung, so they never
##     clip the ground). PLAIN LIMIT: wraps/scarves/sticks are
##     simple static primitives, not cloth simulation.
##   VEHICLES (13): exhaust pipes x5 (car, motorcycle, tuk-tuk,
##     big bus, minibus — only the bicycle had one, Slice 59),
##     licence plates x5 (car front+rear pair, motorcycle rear,
##     tuk-tuk rear, bus pair, minibus pair — zero plates
##     existed anywhere in .gd or main.tscn; plates are plain
##     white boxes with a dark frame, NO fake text, because
##     Noto Sans Myanmar has no Latin-digit glyphs), car door
##     handles (set of 4), car roof rails (pair), car mirror
##     pair (bus/minibus got mirrors in Slice 93; the car had
##     none). Minibus hubcaps are NOT claimed: Slice 81 already
##     fits Hub81 on every minibus wheel.
##   WORLD (13): East Fields scarecrows x2, field ploughs x2,
##     depot traffic-cone set (4 cones flanking the office and
##     the bus parking), fuel-pump hose loop, roadside tea
##     stall at x 1000, market umbrella pair, pagoda offering
##     bowl set (3 bowls outside the 6.5 m pagoda base),
##     East Fields clothesline, hamlet clothesline, depot wash
##     bucket. A second clothesline is a distinct item by the
##     Slice 93 rule (same assembly type, different place —
##     as its haystacks x2 / steps x2 / firewood x2 were).
## Counting rule (Slice 93's): one item = one placed assembly,
## or one symmetric pair/set placed together. People wraps
## are counted live in the sim (the count depends on how many
## villagers lack hats); the total below is the sim count.

var _veh_done: bool = false

static func _mat(c: Color, rough: float, met: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = met
	return m

static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node3D, r: float, mat: Material, pos: Vector3, nm: String, sy: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.scale = Vector3(1.0, sy, 1.0)
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _grass(ctrl: Node3D) -> void:
	# 12 tuft clusters x 3 blades. None of these spots repeat
	# Slice 93 (route north z -8.5 x 550..2350, south z 12.5
	# x 650..2250, village lane z -1.6, East Fields 280/-8
	# and 420/8): route ends, village ground, Mindon street
	# edges (trees MD1..MD3 stand at z -105), hamlet spur
	# edges (spur road x 2094..2106, z 6..60), pagoda ground
	# (base r 6.5 at (108,-62); tufts 9+ m clear).
	var green_a := _mat(Color(0.25, 0.55, 0.20, 1.0), 0.9)
	var green_b := _mat(Color(0.35, 0.65, 0.25, 1.0), 0.9)
	var spots: Array = [
		[470.0, -8.5], [2430.0, -8.5], [470.0, 12.5], [2430.0, 12.5],
		[-30.0, 6.0], [35.0, 10.0], [85.0, -100.0], [145.0, -100.0],
		[2094.0, 20.0], [2106.0, 45.0], [100.0, -55.0], [115.0, -68.0],
	]
	var ci := 0
	for s in spots:
		var tuft := Node3D.new()
		tuft.name = "Grass94_%d" % ci
		tuft.position = Vector3(float(s[0]), 0.0, float(s[1]))
		ctrl.add_child(tuft)
		var blades: Array = [[-0.09, 0.35, -0.20, 0.05, green_a], [0.0, 0.45, 0.06, -0.03, green_b], [0.09, 0.40, 0.24, 0.08, green_a]]
		var bi := 0
		for bl in blades:
			_box(tuft, Vector3(0.035, float(bl[1]), 0.035), bl[4], Vector3(float(bl[0]), float(bl[1]) * 0.5, 0.0), "Blade94_%d_%d" % [ci, bi], Vector3(float(bl[3]), 0.0, float(bl[2])))
			bi += 1
		ci += 1

static func _tree_set(root: Node3D, x: float, z: float, nm: String, fruit: bool, trunk_top: float) -> void:
	# Root flare + two angled branches + second offset canopy
	# + fruit (3) or flowers (4). trunk_top is the existing
	# trunk top: 2.5 for main.tscn trees (MD + village), 2.2
	# for hamlet trees, 2.6 for East Fields trees.
	var trunk_m := _mat(Color(0.45, 0.30, 0.20, 1.0), 0.9)
	var leaf_a := _mat(Color(0.20, 0.50, 0.20, 1.0), 0.9)
	var leaf_b := _mat(Color(0.25, 0.58, 0.22, 1.0), 0.9)
	var mango := _mat(Color(0.95, 0.60, 0.10, 1.0), 0.7)
	var bloom_a := _mat(Color(0.95, 0.60, 0.75, 1.0), 0.8)
	var bloom_b := _mat(Color(0.98, 0.95, 0.90, 1.0), 0.8)
	_cyl(root, 0.30, 0.62, 0.45, trunk_m, Vector3(x, 0.22, z), "Tree94_%s_Root" % nm)
	_cyl(root, 0.05, 0.08, 1.5, trunk_m, Vector3(x - 0.55, trunk_top - 0.45, z), "Tree94_%s_BranchA" % nm, Vector3(0.0, 0.0, 0.7))
	_cyl(root, 0.05, 0.08, 1.5, trunk_m, Vector3(x + 0.55, trunk_top - 0.45, z), "Tree94_%s_BranchB" % nm, Vector3(0.15, 0.0, -0.7))
	_sphere(root, 0.85, leaf_a if nm.hash() % 2 == 0 else leaf_b, Vector3(x + 0.7, trunk_top + 1.4, z + 0.4), "Tree94_%s_Canopy2" % nm)
	if fruit:
		_sphere(root, 0.14, mango, Vector3(x - 0.9, trunk_top + 0.6, z + 0.6), "Tree94_%s_Fruit0" % nm)
		_sphere(root, 0.14, mango, Vector3(x + 0.9, trunk_top + 0.9, z - 0.5), "Tree94_%s_Fruit1" % nm)
		_sphere(root, 0.14, mango, Vector3(x + 0.2, trunk_top + 1.7, z + 0.9), "Tree94_%s_Fruit2" % nm)
	else:
		_sphere(root, 0.09, bloom_a, Vector3(x - 0.8, trunk_top + 0.8, z + 0.5), "Tree94_%s_Flower0" % nm)
		_sphere(root, 0.09, bloom_b, Vector3(x + 0.8, trunk_top + 1.0, z - 0.4), "Tree94_%s_Flower1" % nm)
		_sphere(root, 0.09, bloom_a, Vector3(x + 0.1, trunk_top + 1.6, z + 0.8), "Tree94_%s_Flower2" % nm)
		_sphere(root, 0.09, bloom_b, Vector3(x - 0.3, trunk_top + 1.3, z - 0.9), "Tree94_%s_Flower3" % nm)

static func _trees(root: Node3D) -> void:
	# MD trees stand at z -105, trunk top 2.5, canopy 3.2 r 1.2
	# (main.tscn CylinderMesh_trunk / SphereMesh_foliage).
	# Hamlet trees: trunk 2.2, canopy 2.2 at 3.2 (bus_route75).
	# East Fields tree (365,-10): trunk 2.6, canopy 1.7 at 3.4
	# (chill_world62). None are Slice 93's five village trees.
	_tree_set(root, 70.0, -105.0, "MD1", true, 2.5)
	_tree_set(root, 100.0, -105.0, "MD2", false, 2.5)
	_tree_set(root, 130.0, -105.0, "MD3", true, 2.5)
	_tree_set(root, 2055.0, 70.0, "Ham0", false, 2.2)
	_tree_set(root, 2145.0, 70.0, "Ham1", true, 2.2)
	_tree_set(root, 365.0, -10.0, "East0", true, 2.6)

static func _hash01(s: String) -> float:
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0

static func _people(world: Node3D) -> void:
	# HUMAN REBUILD, SHEET-DEFINED (owner reference sheets
	# 2026-10-23, order: "draw these as 3D models and reuse
	# them"). Runs at frame >= 60 (after Slice 93's frame-40
	# pass). Body-local geometry (character_dress58 + Slice
	# 93): torso box 0.5x0.6x0.3 at y 0.15, head centre 0.65
	# (S93 scale 0.60/0.70/0.65), shoulder pivots at
	# (+-0.27, 0.42), hip pivots at (+-0.13, -0.10), longyi
	# pivot at (0, -0.10) with the tube at local -0.45,
	# feet at body y -1.0, forward is local +z.
	# SEX ASSIGNMENT (deterministic, no gender data in the
	# project): the player is always MALE (sheet 1 is the
	# player target); villagers split by name hash % 3 into
	# male / female A / female B. The sim counts the split.
	# SHARED REBUILD (all 19 bodies): tapered arm segments
	# (upper 0.082 -> 0.062, h 0.34; forearm 0.062 -> 0.048,
	# h 0.38) with shoulder/elbow/wrist joint spheres, elbow
	# bent 0.25 rad forward (bent, not a plank), segments
	# parented to ShoulderPivot58 so WalkAnim58 swing keeps
	# working (bend is a fixed mesh rotation, not a pivot
	# change); reach preserved (fingertips body -0.41, the
	# S93 mid-thigh reach); shaped chest (0.58) + waist
	# (0.44) + neck; re-seated shaped face (eyes on the
	# shrunk head surface, nose protruding 0.04, mouth
	# seated into the face curve, ears); 4 skin tones;
	# Slice 93 fingers kept, re-seated to the bent wrist
	# and widened 0.024 -> 0.030; longyi flared (top 0.24 ->
	# bottom 0.32, was 0.28 -> 0.30) + 8 fold cords.
	# SHEET OUTFITS (stripes/patterns are geometry/colour
	# bands — there is no texture-painting system, so the
	# sheets' woven patterns are approximated by bands,
	# stated plainly, not pixel-matched):
	#  - MALE (sheet 1): white long-sleeve taikpon (chest /
	#    waist / full sleeves / shoulder spheres white),
	#    standing collar ring at the neck, white cuffs at
	#    the wrists, dark-purple longyi with green stripe
	#    bands, front knot bulge at the waist, black
	#    side-parted hair (cap + side fringe; a Slice 73
	#    bun on a male figure is hidden — it contradicts
	#    the sheet), existing dark sandals kept.
	#  - FEMALE A (sheet 2): white lace off-shoulder top
	#    (white chest/waist, BARE skin shoulder spheres,
	#    short lace cap sleeves, white neckline band),
	#    purple longyi with pink pattern bands, hair bun
	#    (Slice 73 bun kept, never duplicated) + flower,
	#    heeled sandals (heel blocks behind the sandals).
	#  - FEMALE B (sheet 3): pale-pink long-sleeve top
	#    (pink chest/waist/full sleeves/shoulders), pink
	#    longyi with white pattern bands, bun + flower,
	#    flat dark sandals.
	# DROPPED vs the pre-sheet Slice 94 plan: scarves and
	# walking sticks are NOT sheet outfits, so they are
	# out — the sheets define the outfits now.
	# LEGS: deliberately NOT rebuilt. The longyi tube
	# (r 0.24..0.32) fully hides the legs (leg boxes reach
	# only r 0.195 from the axis) — as a real longyi
	# covers them. Rebuilding invisible legs would be
	# padding; visible legs would need a different outfit.
	var skin_cols: Array = [
		Color(0.92, 0.75, 0.62, 1.0), Color(0.85, 0.65, 0.50, 1.0),
		Color(0.72, 0.52, 0.36, 1.0), Color(0.55, 0.38, 0.26, 1.0),
	]
	var white_top := _mat(Color(0.96, 0.96, 0.97, 1.0), 0.7)
	var pink_top := _mat(Color(0.95, 0.80, 0.85, 1.0), 0.7)
	var male_lg := _mat(Color(0.20, 0.15, 0.38, 1.0), 0.9)
	var fema_lg := _mat(Color(0.45, 0.20, 0.60, 1.0), 0.9)
	var femb_lg := _mat(Color(0.85, 0.50, 0.65, 1.0), 0.9)
	var green_band := _mat(Color(0.15, 0.45, 0.25, 1.0), 0.9)
	var pink_band := _mat(Color(0.90, 0.35, 0.65, 1.0), 0.9)
	var white_band := _mat(Color(0.96, 0.94, 0.92, 1.0), 0.9)
	var mouth_m := _mat(Color(0.45, 0.10, 0.12, 1.0), 0.8)
	var black_hair := _mat(Color(0.12, 0.08, 0.06, 1.0), 0.9)
	var flower_m := _mat(Color(0.95, 0.55, 0.70, 1.0), 0.7)
	var flower_c := _mat(Color(0.95, 0.80, 0.20, 1.0), 0.7)
	var heel_m := _mat(Color(0.35, 0.15, 0.55, 1.0), 0.7)
	var bodies: Array = []
	for child in world.get_children():
		if child.name == "Player" or String(child.name).begins_with("Villager"):
			bodies.append(child)
	for b in bodies:
		var h: float = _hash01(String(b.name))
		var is_player := String(b.name) == "Player"
		var sex := 0
		if not is_player:
			sex = int(h * 3.0) % 3
		var skin := _mat(skin_cols[int(h * 4.0) % 4], 0.8)
		var head := b.get_node_or_null("Head") as MeshInstance3D
		if head != null:
			head.set_surface_override_material(0, skin)
		var shirt: Material = white_top
		var lg_mat: Material = male_lg
		var band_mat: Material = green_band
		if sex == 1:
			shirt = white_top
			lg_mat = fema_lg
			band_mat = pink_band
		elif sex == 2:
			shirt = pink_top
			lg_mat = femb_lg
			band_mat = white_band
		var torso := b.get_node_or_null("Torso") as MeshInstance3D
		if torso != null and torso.get_child_count() == 0:
			torso.visible = false
			_box(b, Vector3(0.58, 0.30, 0.34), shirt, Vector3(0.0, 0.30, 0.0), "Chest94")
			_box(b, Vector3(0.44, 0.30, 0.28), shirt, Vector3(0.0, 0.00, 0.0), "Waist94")
			_cyl(b, 0.06, 0.06, 0.12, skin, Vector3(0.0, 0.50, 0.0), "Neck94")
		if sex == 0:
			_cyl(b, 0.085, 0.095, 0.08, white_top, Vector3(0.0, 0.52, 0.0), "Collar94")
		elif sex == 1:
			_box(b, Vector3(0.52, 0.06, 0.32), white_top, Vector3(0.0, 0.44, 0.0), "Lace94")
		var eye_l := b.get_node_or_null("Eye73_L") as MeshInstance3D
		var eye_r := b.get_node_or_null("Eye73_R") as MeshInstance3D
		if eye_l != null:
			eye_l.position = Vector3(-0.055, 0.72, 0.10)
			eye_l.mesh = _ball_mesh(0.030)
		if eye_r != null:
			eye_r.position = Vector3(0.055, 0.72, 0.10)
			eye_r.mesh = _ball_mesh(0.030)
		_box(b, Vector3(0.045, 0.08, 0.06), skin, Vector3(0.0, 0.66, 0.14), "Nose94")
		_box(b, Vector3(0.09, 0.025, 0.03), mouth_m, Vector3(0.0, 0.565, 0.11), "Mouth94")
		_sphere(b, 0.035, skin, Vector3(-0.125, 0.65, 0.0), "Ear94_L")
		_sphere(b, 0.035, skin, Vector3(0.125, 0.65, 0.0), "Ear94_R")
		var hair := b.get_node_or_null("Hair58") as MeshInstance3D
		var hair_m: Material = black_hair
		if hair != null and hair.get_surface_override_material(0) != null:
			hair_m = hair.get_surface_override_material(0)
		var bun73 := b.get_node_or_null("HairBun73") as MeshInstance3D
		if sex == 0:
			_box(b, Vector3(0.14, 0.07, 0.04), black_hair, Vector3(0.04, 0.80, 0.10), "SidePart94")
			if bun73 != null:
				bun73.visible = false
		else:
			if bun73 == null:
				_sphere(b, 0.09, hair_m, Vector3(0.0, 0.88, -0.14), "Bun94")
			_sphere(b, 0.035, flower_m, Vector3(0.095, 0.90, -0.14), "Flower94")
			_sphere(b, 0.015, flower_c, Vector3(0.125, 0.90, -0.14), "FlowerC94")
		for side in ["R", "L"]:
			var piv := b.get_node_or_null("ShoulderPivot58_" + side) as Node3D
			if piv == null:
				continue
			var arm := piv.get_node_or_null("Arm_" + side) as MeshInstance3D
			if arm != null:
				arm.visible = false
			var sl := piv.get_node_or_null("Sleeve73_" + side) as MeshInstance3D
			if sl != null:
				sl.visible = false
			var shoulder_m: Material = shirt
			if sex == 1:
				shoulder_m = skin
			_sphere(piv, 0.095, shoulder_m, Vector3(0.0, 0.0, 0.0), "Shoulder94_" + side)
			_cyl(piv, 0.082, 0.062, 0.34, skin, Vector3(0.0, -0.17, 0.0), "Upper94_" + side)
			if sex == 1:
				_cyl(piv, 0.10, 0.095, 0.14, white_top, Vector3(0.0, -0.07, 0.0), "Sleeve94_" + side)
			else:
				_cyl(piv, 0.105, 0.088, 0.34, shirt, Vector3(0.0, -0.17, 0.0), "Sleeve94_" + side)
			_sphere(piv, 0.064, skin, Vector3(0.0, -0.34, 0.0), "Elbow94_" + side)
			_cyl(piv, 0.062, 0.048, 0.38, skin, Vector3(0.0, -0.524, 0.047), "Forearm94_" + side, Vector3(-0.25, 0.0, 0.0))
			_sphere(piv, 0.050, skin, Vector3(0.0, -0.708, 0.094), "Wrist94_" + side)
			if sex == 0:
				_cyl(piv, 0.058, 0.058, 0.08, white_top, Vector3(0.0, -0.66, 0.085), "Cuff94_" + side, Vector3(-0.25, 0.0, 0.0))
			var hand := piv.get_node_or_null("Hand70_" + side) as Node3D
			if hand != null:
				hand.position = Vector3(hand.position.x, -0.71, 0.09)
				hand.scale = Vector3(1.15, 1.15, 1.15)
				if hand is MeshInstance3D:
					(hand as MeshInstance3D).set_surface_override_material(0, skin)
			for c in piv.get_children():
				if not String(c.name).begins_with("Finger93_"):
					continue
				var fg := c as MeshInstance3D
				var old_rot := fg.rotation
				if String(c.name).ends_with("_4"):
					fg.mesh = _box_mesh(Vector3(0.030, 0.10, 0.030))
					fg.position = Vector3(fg.position.x, -0.72, 0.11)
					fg.rotation = Vector3(0.40, old_rot.y, old_rot.z)
				else:
					fg.mesh = _box_mesh(Vector3(0.030, 0.12, 0.030))
					fg.position = Vector3(fg.position.x, -0.77, 0.11)
					fg.rotation = Vector3(0.25 + old_rot.x, old_rot.y, old_rot.z)
				fg.set_surface_override_material(0, skin)
		if sex == 1:
			for side in ["R", "L"]:
				var hip := b.get_node_or_null("HipPivot58_" + side) as Node3D
				if hip != null:
					_box(hip, Vector3(0.09, 0.05, 0.07), heel_m, Vector3(0.0, -0.88, -0.14), "Heel94_" + side)
		var lpiv := b.get_node_or_null("LongyiPivot58") as Node3D
		var lg: MeshInstance3D = null
		if lpiv != null:
			lg = lpiv.get_node_or_null("Longyi") as MeshInstance3D
		if lpiv != null and lg != null:
			var flare := CylinderMesh.new()
			flare.top_radius = 0.24
			flare.bottom_radius = 0.32
			flare.height = 0.9
			lg.mesh = flare
			lg.set_surface_override_material(0, lg_mat)
			for ri in range(8):
				var a := float(ri) * PI / 4.0
				_cyl(lpiv, 0.02, 0.02, 0.50, lg_mat, Vector3(0.295 * sin(a), -0.55, 0.295 * cos(a)), "Fold94_%d" % ri)
			var band_r: Array = [[0.270, 0.277, -0.30], [0.292, 0.299, -0.55], [0.310, 0.317, -0.75]]
			for bi in range(3):
				var br: Array = band_r[bi]
				_cyl(lpiv, float(br[0]), float(br[1]), 0.06, band_mat, Vector3(0.0, float(br[2]), 0.0), "Band94_%d" % bi)
			if sex == 0:
				_sphere(lpiv, 0.07, lg_mat, Vector3(0.0, -0.02, 0.26), "Knot94")

static func _ball_mesh(r: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	return sm

static func _box_mesh(size: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = size
	return bm

static func _holder(parent: Node3D, pos: Vector3, rot_y: float, nm: String) -> Node3D:
	var g := Node3D.new()
	g.name = nm
	g.position = pos
	g.rotation.y = rot_y
	parent.add_child(g)
	return g

static func _frond(parent: Node3D, yaw: float, droop: float, width: float, length: float, mat: Material, nm: String) -> void:
	var hold := Node3D.new()
	hold.name = nm + "_Hold"
	hold.rotation.y = yaw
	parent.add_child(hold)
	_box(hold, Vector3(width, 0.05, length), mat, Vector3(0.0, -sin(droop) * length * 0.5, cos(droop) * length * 0.5), nm, Vector3(droop, 0.0, 0.0))

static func _sheet_trees(root: Node3D) -> void:
	# Owner trees sheet (5 types, rebuilt as primitives).
	# Spots are open ground clear of roads, houses and the
	# S-bend: north edge of the long route (z -30) for the
	# palms/flame/banyan, south edge (z 30) for the banana
	# clump (clear of the hamlet spur at x 2094..2106).
	var trunk := _mat(Color(0.45, 0.32, 0.20, 1.0), 0.9)
	var palm_green := _mat(Color(0.25, 0.55, 0.25, 1.0), 0.9)
	var dry := _mat(Color(0.55, 0.45, 0.25, 1.0), 0.9)
	var leaf_green := _mat(Color(0.30, 0.60, 0.25, 1.0), 0.9)
	var flame_red := _mat(Color(0.90, 0.20, 0.10, 1.0), 0.8)
	var banana_leaf := _mat(Color(0.35, 0.65, 0.25, 1.0), 0.9)
	var bunch_m := _mat(Color(0.70, 0.75, 0.25, 1.0), 0.8)
	var bud_m := _mat(Color(0.55, 0.20, 0.55, 1.0), 0.8)
	var banyan_leaf := _mat(Color(0.20, 0.40, 0.20, 1.0), 0.9)
	var root_m := _mat(Color(0.40, 0.28, 0.18, 1.0), 0.9)
	var gold := _mat(Color(0.85, 0.65, 0.25, 1.0), 0.6)
	# 1. Toddy palm (600,-30): tall straight trunk, fan
	# fronds, dry hanging fronds.
	var t1 := _holder(root, Vector3(600.0, 0.0, -30.0), 0.0, "Toddy94")
	_cyl(t1, 0.25, 0.30, 8.0, trunk, Vector3(0.0, 4.0, 0.0), "Trunk94")
	var crown1 := _holder(t1, Vector3(0.0, 8.0, 0.0), 0.0, "Crown94")
	for i in range(8):
		_frond(crown1, float(i) * PI / 4.0, 0.15, 0.6, 1.8, palm_green, "Fan94_%d" % i)
	for i in range(4):
		_box(crown1, Vector3(0.5, 1.2, 0.05), dry, Vector3(0.45 * sin(float(i) * PI / 2.0), -0.6, 0.45 * cos(float(i) * PI / 2.0)), "Dry94_%d" % i)
	# 2. Coconut palm (1000,-30): curved trunk (3 leaning
	# segments), arching fronds, coconut cluster.
	var t2 := _holder(root, Vector3(1000.0, 0.0, -30.0), 0.0, "Coconut94")
	_cyl(t2, 0.28, 0.32, 3.0, trunk, Vector3(0.0, 1.5, 0.0), "Trunk94_A")
	_cyl(t2, 0.26, 0.28, 3.0, trunk, Vector3(0.35, 4.4, 0.0), "Trunk94_B", Vector3(0.0, 0.0, -0.12))
	_cyl(t2, 0.24, 0.26, 3.0, trunk, Vector3(0.85, 7.2, 0.0), "Trunk94_C", Vector3(0.0, 0.0, -0.20))
	var crown2 := _holder(t2, Vector3(1.1, 8.6, 0.0), 0.0, "Crown94")
	for i in range(8):
		_frond(crown2, float(i) * PI / 4.0, 0.5, 0.35, 2.4, palm_green, "Arch94_%d" % i)
	for i in range(5):
		_sphere(crown2, 0.18, bunch_m, Vector3(0.25 * sin(float(i) * 1.256), -0.3, 0.25 * cos(float(i) * 1.256)), "Nut94_%d" % i)
	# 3. Flame tree (1400,-30): spreading branches, dense
	# red flower clusters over green canopy.
	var t3 := _holder(root, Vector3(1400.0, 0.0, -30.0), 0.0, "Flame94")
	_cyl(t3, 0.35, 0.45, 3.0, trunk, Vector3(0.0, 1.5, 0.0), "Trunk94")
	for i in range(4):
		var a := float(i) * PI / 2.0 + PI / 4.0
		_cyl(t3, 0.12, 0.20, 2.5, trunk, Vector3(0.8 * sin(a), 4.0, 0.8 * cos(a)), "Branch94_%d" % i, Vector3(0.6 * cos(a), 0.0, -0.6 * sin(a)))
	for i in range(5):
		_sphere(t3, 1.2, leaf_green, Vector3(1.2 * sin(float(i) * 1.256), 5.0, 1.2 * cos(float(i) * 1.256)), "Canopy94_%d" % i)
	_sphere(t3, 1.2, leaf_green, Vector3(0.0, 5.5, 0.0), "Canopy94_C")
	for i in range(8):
		_sphere(t3, 0.35, flame_red, Vector3(1.6 * sin(float(i) * 0.785), 5.6, 1.6 * cos(float(i) * 0.785)), "Bloom94_%d" % i)
	# 4. Banana clump (1800,30): broad leaves, banana
	# bunch + purple bud.
	var t4 := _holder(root, Vector3(1800.0, 0.0, 30.0), 0.0, "Banana94")
	for i in range(5):
		var a := float(i) * 1.256
		_cyl(t4, 0.12, 0.15, 2.5, leaf_green, Vector3(0.5 * sin(a), 1.25, 0.5 * cos(a)), "Stem94_%d" % i)
		_frond(t4, a, 0.6, 0.5, 2.0, banana_leaf, "Leaf94_%d" % i)
		t4.get_node_or_null("Leaf94_%d_Hold" % i).position = Vector3(0.5 * sin(a), 2.5, 0.5 * cos(a))
	_sphere(t4, 0.09, bunch_m, Vector3(0.3, 2.2, 0.2), "Bunch94_A")
	_sphere(t4, 0.09, bunch_m, Vector3(0.45, 2.05, 0.2), "Bunch94_B")
	_sphere(t4, 0.09, bunch_m, Vector3(0.3, 2.05, 0.35), "Bunch94_C")
	_cyl(t4, 0.02, 0.12, 0.35, bud_m, Vector3(0.35, 1.8, 0.25), "Bud94")
	# 5. Banyan (2200,-30): multi-trunk, aerial roots,
	# dense canopy, small shrine at the base.
	var t5 := _holder(root, Vector3(2200.0, 0.0, -30.0), 0.0, "Banyan94")
	_cyl(t5, 0.35, 0.45, 4.0, trunk, Vector3(-0.6, 2.0, 0.0), "Trunk94_A")
	_cyl(t5, 0.35, 0.45, 4.0, trunk, Vector3(0.6, 2.0, 0.3), "Trunk94_B")
	_cyl(t5, 0.30, 0.40, 4.0, trunk, Vector3(0.0, 2.0, -0.5), "Trunk94_C")
	for i in range(6):
		var a := float(i) * PI / 3.0
		_cyl(t5, 0.05, 0.05, 3.5, root_m, Vector3(1.5 * sin(a), 3.75, 1.5 * cos(a)), "Aerial94_%d" % i)
	for i in range(6):
		var a := float(i) * PI / 3.0
		_sphere(t5, 1.6, banyan_leaf, Vector3(1.0 * sin(a), 6.0, 1.0 * cos(a)), "Canopy94_%d" % i)
	_box(t5, Vector3(0.5, 0.4, 0.4), gold, Vector3(1.2, 0.2, 0.8), "Shrine94")
	_box(t5, Vector3(0.7, 0.1, 0.6), gold, Vector3(1.2, 0.45, 0.8), "ShrineRoof94")

static func _sheet_pagodas(root: Node3D) -> void:
	# Owner pagodas sheet (5 NEW landmarks on open ground
	# clear of roads/structures). The existing pagoda at
	# (108,-62) is NOT touched, moved or replaced.
	# Spots: golden (700,-50), brick (1100,-50), white
	# (1500,50) south of the route, forest (2000,50)
	# west of the hamlet spur, hilltop (2300,-50).
	var gold := _mat(Color(0.85, 0.65, 0.25, 1.0), 0.5)
	var brick := _mat(Color(0.55, 0.30, 0.20, 1.0), 0.9)
	var brick_dark := _mat(Color(0.35, 0.20, 0.15, 1.0), 0.9)
	var white_m := _mat(Color(0.95, 0.95, 0.93, 1.0), 0.6)
	var leaf := _mat(Color(0.25, 0.50, 0.22, 1.0), 0.9)
	var trunk := _mat(Color(0.45, 0.32, 0.20, 1.0), 0.9)
	var rock := _mat(Color(0.50, 0.48, 0.45, 1.0), 0.9)
	var wall_m := _mat(Color(0.70, 0.65, 0.58, 1.0), 0.9)
	var wood := _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	var flag_r := _mat(Color(0.85, 0.15, 0.15, 1.0), 0.8)
	var flag_b := _mat(Color(0.15, 0.35, 0.85, 1.0), 0.8)
	# 1. Golden Shwedagon-style.
	var p1 := _holder(root, Vector3(700.0, 0.0, -50.0), 0.0, "PagodaGold94")
	_box(p1, Vector3(10.0, 0.6, 10.0), gold, Vector3(0.0, 0.3, 0.0), "Terrace94_A")
	_box(p1, Vector3(8.0, 0.6, 8.0), gold, Vector3(0.0, 0.9, 0.0), "Terrace94_B")
	_box(p1, Vector3(6.0, 0.6, 6.0), gold, Vector3(0.0, 1.5, 0.0), "Terrace94_C")
	_sphere(p1, 2.2, gold, Vector3(0.0, 3.0, 0.0), "Bell94", 1.3)
	_cyl(p1, 0.05, 0.5, 3.0, gold, Vector3(0.0, 6.5, 0.0), "Spire94")
	for i in range(4):
		var a := float(i) * PI / 2.0 + PI / 4.0
		_cyl(p1, 0.02, 0.3, 1.2, gold, Vector3(4.0 * sin(a), 2.2, 4.0 * cos(a)), "Mini94_%d" % i)
	_box(p1, Vector3(0.8, 0.6, 1.2), gold, Vector3(-2.5, 0.3, 5.5), "Lion94_L")
	_sphere(p1, 0.35, gold, Vector3(-2.5, 1.0, 5.5), "LionHead94_L")
	_box(p1, Vector3(0.8, 0.6, 1.2), gold, Vector3(2.5, 0.3, 5.5), "Lion94_R")
	_sphere(p1, 0.35, gold, Vector3(2.5, 1.0, 5.5), "LionHead94_R")
	# 2. Ancient brick Bagan-style.
	var p2 := _holder(root, Vector3(1100.0, 0.0, -50.0), 0.0, "PagodaBrick94")
	_box(p2, Vector3(8.0, 0.8, 8.0), brick, Vector3(0.0, 0.4, 0.0), "Terrace94_A")
	_box(p2, Vector3(6.5, 0.8, 6.5), brick, Vector3(0.0, 1.2, 0.0), "Terrace94_B")
	_box(p2, Vector3(5.0, 0.8, 5.0), brick, Vector3(0.0, 2.0, 0.0), "Terrace94_C")
	_cyl(p2, 0.1, 1.8, 3.5, brick, Vector3(0.0, 4.2, 0.0), "Stupa94")
	for i in range(4):
		var a := float(i) * PI / 2.0
		_box(p2, Vector3(0.8, 1.2, 0.2), brick_dark, Vector3(3.3 * sin(a), 1.0, 3.3 * cos(a)), "Niche94_%d" % i)
	# 3. White alabaster.
	var p3 := _holder(root, Vector3(1500.0, 0.0, 50.0), 0.0, "PagodaWhite94")
	_cyl(p3, 4.5, 4.5, 0.6, white_m, Vector3(0.0, 0.3, 0.0), "Round94_A")
	_cyl(p3, 3.5, 3.5, 0.6, white_m, Vector3(0.0, 0.9, 0.0), "Round94_B")
	_sphere(p3, 2.0, white_m, Vector3(0.0, 2.2, 0.0), "Dome94", 1.1)
	_cyl(p3, 1.9, 2.0, 0.4, gold, Vector3(0.0, 3.4, 0.0), "GoldBand94")
	_cyl(p3, 0.05, 0.4, 2.5, gold, Vector3(0.0, 5.2, 0.0), "Spire94")
	_box(p3, Vector3(0.8, 0.6, 1.2), white_m, Vector3(-2.5, 0.3, 4.5), "Lion94_L")
	_box(p3, Vector3(0.8, 0.6, 1.2), white_m, Vector3(2.5, 0.3, 4.5), "Lion94_R")
	# 4. Forest monastic: gold stupa under a big tree,
	# flags, offering table.
	var p4 := _holder(root, Vector3(2000.0, 0.0, 50.0), 0.0, "PagodaForest94")
	_box(p4, Vector3(3.0, 0.5, 3.0), gold, Vector3(0.0, 0.25, 0.0), "Base94")
	_sphere(p4, 1.2, gold, Vector3(0.0, 1.6, 0.0), "Bell94", 1.3)
	_cyl(p4, 0.03, 0.25, 1.5, gold, Vector3(0.0, 3.2, 0.0), "Spire94")
	_cyl(p4, 0.4, 0.5, 5.0, trunk, Vector3(-2.0, 2.5, -1.0), "Tree94")
	for i in range(4):
		var a := float(i) * PI / 2.0
		_sphere(p4, 1.8, leaf, Vector3(-2.0 + 1.2 * sin(a), 6.0, -1.0 + 1.2 * cos(a)), "Canopy94_%d" % i)
	_cyl(p4, 0.03, 0.03, 2.0, wood, Vector3(1.5, 1.0, 1.5), "FlagPole94_A")
	_box(p4, Vector3(0.5, 0.3, 0.03), flag_r, Vector3(1.75, 1.85, 1.5), "Flag94_A")
	_cyl(p4, 0.03, 0.03, 2.0, wood, Vector3(2.5, 1.0, -1.0), "FlagPole94_B")
	_box(p4, Vector3(0.5, 0.3, 0.03), flag_b, Vector3(2.75, 1.85, -1.0), "Flag94_B")
	_box(p4, Vector3(1.2, 0.1, 0.6), wood, Vector3(1.5, 0.8, 2.0), "Table94")
	# 5. Hilltop miniature: rocky hill, small white+gold
	# stupa, enclosing wall, steps.
	var p5 := _holder(root, Vector3(2300.0, 0.0, -50.0), 0.0, "PagodaHill94")
	_cyl(p5, 1.5, 5.0, 2.5, rock, Vector3(0.0, 1.25, 0.0), "Hill94")
	_box(p5, Vector3(1.5, 0.4, 1.5), white_m, Vector3(0.0, 2.7, 0.0), "Base94")
	_sphere(p5, 0.8, white_m, Vector3(0.0, 3.4, 0.0), "Dome94", 1.1)
	_cyl(p5, 0.02, 0.15, 1.0, gold, Vector3(0.0, 4.3, 0.0), "Spire94")
	# Slice 95 gate gap: the north wall is split so the steps
	# pass through a real 1.4 m gate opening (was one solid
	# 9.0 m wall the steps merged through, Slice 94's
	# disclosed approximation).
	_box(p5, Vector3(3.8, 0.8, 0.4), wall_m, Vector3(-2.6, 0.4, 4.5), "Wall94_N_L")
	_box(p5, Vector3(3.8, 0.8, 0.4), wall_m, Vector3(2.6, 0.4, 4.5), "Wall94_N_R")
	_box(p5, Vector3(0.3, 1.1, 0.3), wall_m, Vector3(-0.85, 0.55, 4.5), "GatePost94_L")
	_box(p5, Vector3(0.3, 1.1, 0.3), wall_m, Vector3(0.85, 0.55, 4.5), "GatePost94_R")
	_box(p5, Vector3(9.0, 0.8, 0.4), wall_m, Vector3(0.0, 0.4, -4.5), "Wall94_S")
	_box(p5, Vector3(0.4, 0.8, 9.0), wall_m, Vector3(4.5, 0.4, 0.0), "Wall94_E")
	_box(p5, Vector3(0.4, 0.8, 9.0), wall_m, Vector3(-4.5, 0.4, 0.0), "Wall94_W")
	for i in range(6):
		_box(p5, Vector3(1.2, 0.2, 0.6), wall_m, Vector3(0.0, 0.21 + float(i) * 0.42, 5.2 - float(i) * 0.62), "Step94_%d" % i)

static func _house_restyle(root: Node3D) -> void:
	# Owner stilt-house sheet, applied as dressing to 4
	# EXISTING stilt houses (positions + rotations taken
	# from chill_world62 / bus_route75; NOTHING moves).
	# NO existing collider is touched; all new nodes are
	# visual-only (zero colliders, like every S94 item).
	# Roof restyle is honest: rust PATCH strips laid on the
	# existing roof slabs (replacing a roof would double
	# the roofline). Houses: East Fields (300,-16) and
	# (330,-16), both rot 0 (front = world +z, toward the
	# main road); hamlet (2075,78) and (2125,78), front =
	# world -z (door on the -z face).
	var wood := _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	var rust := _mat(Color(0.60, 0.30, 0.20, 1.0), 0.9)
	var pot_m := _mat(Color(0.55, 0.30, 0.20, 1.0), 0.9)
	var cloth_a := _mat(Color(0.85, 0.20, 0.20, 1.0), 0.9)
	var cloth_b := _mat(Color(0.20, 0.50, 0.85, 1.0), 0.9)
	var log_m := _mat(Color(0.40, 0.26, 0.14, 1.0), 0.9)
	_restyled_house(root, Vector3(300.0, 0.0, -16.0), 0.0, 1, wood, rust, pot_m, cloth_a, cloth_b, log_m)
	_restyled_house(root, Vector3(330.0, 0.0, -16.0), 0.0, 1, wood, rust, pot_m, cloth_a, cloth_b, log_m)
	_restyled_house(root, Vector3(2075.0, 0.0, 78.0), 0.0, -1, wood, rust, pot_m, cloth_a, cloth_b, log_m)
	_restyled_house(root, Vector3(2125.0, 0.0, 78.0), 0.0, -1, wood, rust, pot_m, cloth_a, cloth_b, log_m)

static func _restyled_house(root: Node3D, pos: Vector3, rot_y: float, front: int, wood: Material, rust: Material, pot_m: Material, cloth_a: Material, cloth_b: Material, log_m: Material) -> void:
	# front = +1: East Fields (veranda at local +z, floor
	# top 1.5, pitched roof slabs at y 3.95). front = -1:
	# hamlet (door face -z, walls 1.2..3.6, flat roof slab
	# at y 3.7). All children are local to the holder, so
	# one code path serves both orientations.
	var g := _holder(root, pos, rot_y, "Restyle94_%d_%d" % [int(pos.x), int(pos.z)])
	var f := float(front)
	if front == 1:
		for i in range(4):
			_box(g, Vector3(1.2, 0.3, 0.4), wood, Vector3(0.0, 1.2 - float(i) * 0.3, f * (4.2 + float(i) * 0.4)), "Step94_%d" % i)
		_box(g, Vector3(0.08, 0.9, 0.08), wood, Vector3(-1.4, 1.95, f * 3.9), "RailPost94_L")
		_box(g, Vector3(0.08, 0.9, 0.08), wood, Vector3(1.4, 1.95, f * 3.9), "RailPost94_R")
		_box(g, Vector3(3.0, 0.08, 0.08), wood, Vector3(0.0, 2.4, f * 3.9), "RailTop94")
		_box(g, Vector3(7.0, 0.02, 0.4), rust, Vector3(0.0, 4.12, -1.25), "Rust94_L", Vector3(0.5, 0.0, 0.0))
		_box(g, Vector3(7.0, 0.02, 0.4), rust, Vector3(0.0, 4.12, 1.25), "Rust94_R", Vector3(-0.5, 0.0, 0.0))
	else:
		for i in range(4):
			_box(g, Vector3(1.2, 0.3, 0.4), wood, Vector3(0.0, 1.05 - float(i) * 0.3, f * (3.5 + float(i) * 0.4)), "Step94_%d" % i)
		_box(g, Vector3(0.08, 0.9, 0.08), wood, Vector3(-3.0, 1.65, f * 3.1), "RailPost94_L")
		_box(g, Vector3(0.08, 0.9, 0.08), wood, Vector3(3.0, 1.65, f * 3.1), "RailPost94_R")
		_box(g, Vector3(7.0, 0.08, 0.08), wood, Vector3(0.0, 2.1, f * 3.1), "RailTop94")
		_box(g, Vector3(7.5, 0.02, 0.5), rust, Vector3(0.0, 3.82, -2.0), "Rust94_A")
		_box(g, Vector3(7.5, 0.02, 0.5), rust, Vector3(0.0, 3.82, 2.0), "Rust94_B")
	for i in range(5):
		_cyl(g, 0.12, 0.12, 1.0, log_m, Vector3(4.5, 0.12 + float(i / 3) * 0.22, -0.4 + float(i % 3) * 0.4), "Log94_%d" % i, Vector3(0.0, 0.0, PI / 2.0))
	_cyl(g, 0.30, 0.35, 0.6, pot_m, Vector3(-4.2, 0.3, f * 2.0), "Pot94")
	_box(g, Vector3(0.08, 1.8, 0.08), wood, Vector3(-2.5, 0.9, -f * 6.0), "LinePost94_L")
	_box(g, Vector3(0.08, 1.8, 0.08), wood, Vector3(2.5, 0.9, -f * 6.0), "LinePost94_R")
	_box(g, Vector3(5.0, 0.03, 0.03), wood, Vector3(0.0, 1.7, -f * 6.0), "Line94")
	_box(g, Vector3(0.5, 0.6, 0.03), cloth_a, Vector3(-1.0, 1.35, -f * 6.0), "Cloth94_A")
	_box(g, Vector3(0.5, 0.6, 0.03), cloth_b, Vector3(1.0, 1.35, -f * 6.0), "Cloth94_B")


static func _world_items(root: Node3D) -> void:
	var wood := _mat(Color(0.55, 0.38, 0.22, 1.0), 0.9)
	var bark := _mat(Color(0.45, 0.30, 0.20, 1.0), 0.95)
	var straw := _mat(Color(0.85, 0.75, 0.35, 1.0), 0.95)
	var dark := _mat(Color(0.15, 0.15, 0.15, 1.0), 0.8)
	var orange := _mat(Color(0.95, 0.45, 0.10, 1.0), 0.8)
	var white := _mat(Color(0.95, 0.95, 0.92, 1.0), 0.8)
	var clay := _mat(Color(0.75, 0.42, 0.28, 1.0), 0.85)
	var gold := _mat(Color(0.85, 0.70, 0.25, 1.0), 0.5, 0.6)
	var leaf := _mat(Color(0.25, 0.55, 0.20, 1.0), 0.9)
	var blue := _mat(Color(0.30, 0.50, 0.85, 1.0), 0.8)
	var pink := _mat(Color(0.95, 0.60, 0.75, 1.0), 0.8)
	var red := _mat(Color(0.85, 0.15, 0.15, 1.0), 0.7)
	# Scarecrows: post + crossbar + straw head + ragged arms,
	# standing IN the East Fields crop area (rows x 356..368,
	# channel at x 354.5 — both clear of the channel).
	for sc in [[362.0, -30.0], [366.0, -44.0]]:
		var sx := float(sc[0])
		var sz := float(sc[1])
		_cyl(root, 0.05, 0.05, 1.7, wood, Vector3(sx, 0.85, sz), "Scare94_%d_Post" % int(sx))
		_cyl(root, 0.04, 0.04, 1.0, wood, Vector3(sx, 1.35, sz), "Scare94_%d_Bar" % int(sx), Vector3(0.0, 0.0, 1.5707963267948966))
		_sphere(root, 0.18, straw, Vector3(sx, 1.75, sz), "Scare94_%d_Head" % int(sx))
		_box(root, Vector3(0.70, 0.50, 0.05), red, Vector3(sx, 1.15, sz), "Scare94_%d_Body" % int(sx))
	# Field ploughs: wooden beam + share + handles, at the
	# field edge east of the rows, clear of the x 350 stream.
	for pl in [[372.0, -20.0], [374.0, -55.0]]:
		var px := float(pl[0])
		var pz := float(pl[1])
		_box(root, Vector3(0.12, 0.12, 1.6), wood, Vector3(px, 0.25, pz), "Plough94_%d_Beam" % int(px))
		_box(root, Vector3(0.30, 0.06, 0.50), dark, Vector3(px, 0.08, pz + 0.7), "Plough94_%d_Share" % int(px))
		_cyl(root, 0.04, 0.04, 0.9, wood, Vector3(px - 0.15, 0.55, pz - 0.6), "Plough94_%d_HandleL" % int(px), Vector3(0.5, 0.0, 0.0))
		_cyl(root, 0.04, 0.04, 0.9, wood, Vector3(px + 0.15, 0.55, pz - 0.6), "Plough94_%d_HandleR" % int(px), Vector3(0.5, 0.0, 0.0))
	# Depot traffic cones: 4 cones flanking the office front
	# (office x 26..34, z 3.5..8.5) and the bus parking at
	# (30,16) (body x 28.7..31.3) — all 2+ m clear.
	for cn in [[24.0, 10.0], [36.0, 10.0], [26.0, 18.0], [34.0, 18.0]]:
		_cyl(root, 0.03, 0.20, 0.5, orange, Vector3(float(cn[0]), 0.25, float(cn[1])), "Cone94_%d_%d" % [int(float(cn[0])), int(float(cn[1]))])
		_cyl(root, 0.10, 0.13, 0.12, white, Vector3(float(cn[0]), 0.28, float(cn[1])), "ConeBand94_%d_%d" % [int(float(cn[0])), int(float(cn[1]))])
	# Fuel-pump hose loop beside the S82 pump at (40,0,32):
	# two parallel runs + one cross run, lying on the ground.
	_cyl(root, 0.04, 0.04, 1.0, dark, Vector3(39.0, 0.05, 31.6), "Hose94_A", Vector3(0.0, 0.0, 1.5707963267948966))
	_cyl(root, 0.04, 0.04, 1.0, dark, Vector3(39.0, 0.05, 32.4), "Hose94_B", Vector3(0.0, 0.0, 1.5707963267948966))
	_cyl(root, 0.04, 0.04, 0.8, dark, Vector3(39.5, 0.05, 32.0), "Hose94_C", Vector3(1.5707963267948966, 0.0, 0.0))
	# Roadside tea stall at (1000,16): south of the route
	# slab (south grass line is z 12.5), table + 2 stools +
	# 2 cups. One assembly.
	_box(root, Vector3(1.4, 0.08, 0.9), wood, Vector3(1000.0, 0.75, 16.0), "Tea94_Table")
	_box(root, Vector3(0.40, 0.45, 0.40), wood, Vector3(999.0, 0.22, 16.8), "Tea94_StoolA")
	_box(root, Vector3(0.40, 0.45, 0.40), wood, Vector3(1001.0, 0.22, 16.8), "Tea94_StoolB")
	_cyl(root, 0.05, 0.04, 0.10, clay, Vector3(999.7, 0.84, 16.0), "Tea94_CupA")
	_cyl(root, 0.05, 0.04, 0.10, clay, Vector3(1000.3, 0.84, 16.0), "Tea94_CupB")
	# Market umbrellas over the Slice 73 basket sites at
	# (-7.6,2) and (-7.6,6): pole + canopy disc covering the
	# baskets (canopy centre -8.2 r 1.3 spans x -9.5..-6.9).
	for um in [2.0, 6.0]:
		_cyl(root, 0.04, 0.04, 2.2, wood, Vector3(-8.8, 1.1, um), "Umb94_%d_Pole" % int(um))
		_cyl(root, 1.30, 1.30, 0.06, red, Vector3(-8.2, 2.25, um), "Umb94_%d_Top" % int(um))
	# Pagoda offering bowls: 3 bowls at 7.5 m from the pagoda
	# centre (108,-62), outside the 6.5 m base radius.
	for ob in [[115.5, -62.0], [100.5, -62.0], [108.0, -54.5]]:
		_cyl(root, 0.25, 0.18, 0.20, gold, Vector3(float(ob[0]), 0.10, float(ob[1])), "Bowl94_%d" % int(float(ob[0])))
	# Clotheslines (Slice 93 pattern, new places): East
	# Fields house (300,-16) front yard (z -10, clear of the
	# house footprint) and hamlet central ground (2095..2099,
	# 88) between the four hamlet houses.
	for cl in [["East", 296.0, 300.0, -10.0], ["Ham", 2095.0, 2099.0, 88.0]]:
		var ax := float(cl[1])
		var bx := float(cl[2])
		var cz := float(cl[3])
		var nm := String(cl[0])
		_cyl(root, 0.04, 0.04, 1.8, wood, Vector3(ax, 0.9, cz), "LinePost94_%s_A" % nm)
		_cyl(root, 0.04, 0.04, 1.8, wood, Vector3(bx, 0.9, cz), "LinePost94_%s_B" % nm)
		_box(root, Vector3(bx - ax, 0.04, 0.04), dark, Vector3((ax + bx) * 0.5, 1.65, cz), "Line94_%s" % nm)
		_box(root, Vector3(0.5, 0.7, 0.03), white, Vector3(ax + 0.8, 1.28, cz), "Cloth94_%s_0" % nm)
		_box(root, Vector3(0.5, 0.7, 0.03), blue, Vector3((ax + bx) * 0.5, 1.28, cz), "Cloth94_%s_1" % nm)
		_box(root, Vector3(0.5, 0.7, 0.03), pink, Vector3(bx - 0.8, 1.28, cz), "Cloth94_%s_2" % nm)
	# Depot wash bucket beside the pump (pump at (40,32)):
	# bucket + wrung cloth over its rim.
	_cyl(root, 0.22, 0.16, 0.30, blue, Vector3(38.5, 0.15, 32.5), "Bucket94")
	_box(root, Vector3(0.30, 0.04, 0.20), white, Vector3(38.5, 0.32, 32.5), "BucketCloth94")

static func _vehicle_scene_items(world: Node3D) -> void:
	# Scene vehicles (present at dress time). Forward is -z
	# for car + motorcycle (headlights at z -2.05 / -1.1);
	# tuk-tuk rear is +z (Slice 93 taillights at z 1.22).
	# Car body BoxMesh_car (2,0.8,4): faces x +-1, y +-0.4,
	# z +-2. Motorcycle wheels at (0,-0.55,+-0.7) r 0.38.
	# Tuk-tuk body (1.4,0.7,2.4) at (0,0.2,0): z +-1.2.
	var dark := _mat(Color(0.12, 0.12, 0.12, 1.0), 0.5, 0.3)
	var plate_m := _mat(Color(0.95, 0.95, 0.90, 1.0), 0.6)
	var car := world.get_node_or_null("Car") as Node3D
	if car != null:
		_cyl(car, 0.05, 0.05, 0.5, dark, Vector3(0.7, -0.35, 1.9), "Exhaust94_Car", Vector3(1.5707963267948966, 0.0, 0.0))
		_box(car, Vector3(0.5, 0.14, 0.03), plate_m, Vector3(0.0, -0.05, -2.02), "Plate94_CarF")
		_box(car, Vector3(0.5, 0.14, 0.03), plate_m, Vector3(0.0, -0.05, 2.02), "Plate94_CarR")
		for sx in [-1.0, 1.0]:
			for hz in [-0.6, 0.6]:
				_box(car, Vector3(0.03, 0.06, 0.25), dark, Vector3(sx * 1.02, 0.05, hz), "Handle94_Car_%d_%d" % [int(sx), int(hz * 10.0)])
		for sx in [-1.0, 1.0]:
			_box(car, Vector3(0.06, 0.06, 2.6), dark, Vector3(sx * 0.6, 0.45, 0.0), "RoofRail94_Car_%d" % int(sx))
			_box(car, Vector3(0.08, 0.04, 0.04), dark, Vector3(sx * 1.03, 0.25, -1.3), "MirrorArm94_Car_%d" % int(sx))
			_box(car, Vector3(0.05, 0.22, 0.16), dark, Vector3(sx * 1.10, 0.25, -1.3), "Mirror94_Car_%d" % int(sx))
	var moto := world.get_node_or_null("Motorcycle") as Node3D
	if moto != null:
		_cyl(moto, 0.05, 0.05, 0.9, dark, Vector3(0.18, -0.35, 0.1), "Exhaust94_Moto", Vector3(1.5707963267948966, 0.0, 0.0))
		_box(moto, Vector3(0.24, 0.16, 0.03), plate_m, Vector3(0.0, -0.25, 1.10), "Plate94_MotoR")
	var tuk := world.get_node_or_null("TukTuk") as Node3D
	if tuk != null:
		_cyl(tuk, 0.05, 0.05, 0.8, dark, Vector3(0.45, -0.15, 0.5), "Exhaust94_Tuk", Vector3(1.5707963267948966, 0.0, 0.0))
		_box(tuk, Vector3(0.40, 0.14, 0.03), plate_m, Vector3(0.0, 0.15, 1.24), "Plate94_TukR")

static func _vehicle_live_items(world: Node3D) -> void:
	# Big bus body centre (0,1.7,0) size 2.6x2.2x9.0, front
	# -z (Slice 93 mirrors at z -3.9); minibus centre
	# (0,1.6,0) size 2.4x2.0x6.0, front -z (mirrors -2.6).
	var dark := _mat(Color(0.12, 0.12, 0.12, 1.0), 0.5, 0.3)
	var plate_m := _mat(Color(0.95, 0.95, 0.90, 1.0), 0.6)
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus != null:
		_cyl(bus, 0.09, 0.09, 0.6, dark, Vector3(0.9, 0.5, 4.35), "Exhaust94_Bus", Vector3(1.5707963267948966, 0.0, 0.0))
		_box(bus, Vector3(0.7, 0.20, 0.03), plate_m, Vector3(0.0, 0.9, -4.52), "Plate94_BusF")
		_box(bus, Vector3(0.7, 0.20, 0.03), plate_m, Vector3(0.0, 0.9, 4.52), "Plate94_BusR")
	var mini := world.get_node_or_null("Minibus") as Node3D
	if mini != null:
		_cyl(mini, 0.08, 0.08, 0.5, dark, Vector3(0.8, 0.45, 2.9), "Exhaust94_Mini", Vector3(1.5707963267948966, 0.0, 0.0))
		_box(mini, Vector3(0.6, 0.18, 0.03), plate_m, Vector3(0.0, 0.9, -3.02), "Plate94_MiniF")
		_box(mini, Vector3(0.6, 0.18, 0.03), plate_m, Vector3(0.0, 0.9, 3.02), "Plate94_MiniR")

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism94") != null:
		return
	# World-static items are new nodes (no conflicts), so they
	# go in deferred, like every earlier dressing root. People
	# and vehicle items wait until frame >= 60 (after Slice 70
	# frame-12, Slice 73 frame-26 and Slice 93 frame-40
	# passes), so the rebuild reshapes final values.
	var root := Node3D.new()
	root.name = "Dress94Root"
	_trees(root)
	_world_items(root)
	_sheet_trees(root)
	_sheet_pagodas(root)
	_house_restyle(root)
	world.call_deferred("add_child", root)
	var ctrl := Node3D.new()
	ctrl.name = "Grass94Ctrl"
	ctrl.set_script(load("res://grass_sway93.gd"))
	_grass(ctrl)
	world.call_deferred("add_child", ctrl)
	var n := Node3D.new()
	n.name = "Realism94"
	n.set_script(load("res://realism94.gd"))
	world.call_deferred("add_child", n)

var _frames: int = 0
var _people_done: bool = false

func _process(_delta: float) -> void:
	# Frame >= 60: after Slice 70 (frame 12), Slice 73
	# (frame 26) and Slice 93 (frame 40) have all run, so
	# the people rebuild reshapes final values. Vehicle
	# items wait for the live Bus + Minibus too.
	_frames += 1
	if _frames < 60:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _people_done:
		_people(world)
		_vehicle_scene_items(world)
		_people_done = true
	if _veh_done:
		return
	if world.get_node_or_null("Bus") == null:
		return
	if world.get_node_or_null("Minibus") == null:
		return
	_vehicle_live_items(world)
	_veh_done = true
