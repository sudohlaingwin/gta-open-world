extends Node3D
## Slice 95 GRAPHICS BATCH 3 — sheet programme, second pass
## (owner standing rules: ~50 distinct items per push,
## graphics-first, people judged first).
## Runtime dressing ONLY: no .tscn edits, no gameplay, no bus
## systems, no control changes, minibus NOT rewired. Everything
## here is StandardMaterial3D, zero colliders, no dead specular
## lines, and detailed realistic-STYLISED procedural work from
## the owner's 2D reference sheets — not scanned photorealism,
## not pixel-identical patterns (stripes/patterns are
## geometry/colour bands; no texture-painting system exists).
##
## Audit first (all grep-proven missing before writing):
##   - No eyebrows, no sandal straps, no male placket, no
##     female-A lace scallops, no female-B side buttons, no
##     female waistband, no longyi hem band anywhere in .gd.
##   - Sandals exist only as plain dark boxes (Sandal58).
##   - Second sheet trees/pagoda details do not exist; the
##     Slice 94 hilltop wall is still one solid wall (fixed
##     here by editing realism94.gd: split wall + gate posts).
##   - No corrugated roof ribs anywhere; Slice 94 roofs got
##     flat rust strips only.
## Counting rule (Slices 93/94): one item = one placed
## assembly, or one symmetric pair/set placed together. A
## figure's whole second-pass detail set counts as ONE item
## (the Slice 94 precedent: a full rebuild per figure = 1).
##   PEOPLE second pass (19 figure sets): eyebrows, sandal
##     thong straps, male placket + buttons, female-A lace
##     scallops + sleeve rings, female-B side buttons,
##     female waistband, longyi hem band. Runs at frame
##     >= 80 (after Slice 94's frame-60 pass).
##   SHEET TREES second set (5): toddy, coconut, flame,
##     banana, banyan + shrine — same type key features as
##     Slice 94, new open-ground spots (banyan aerial roots
##     now reach the ground, closer to the sheet).
##   PAGODA DETAILS (4 + hilltop fix): golden cardinal
##     minis (grounded on terrace B, unlike Slice 94's
##     diagonal minis — see peer note) + hti ball; brick
##     moss + eave strips; white terrace minis + finial;
##     forest hti + offering flowers; hilltop gate gap.
##   HOUSE ROOFS (8 = ridge set + rust set x 4 houses):
##     corrugated ribs + darker rust strips on the 4
##     Slice 94 restyled houses (positions untouched).
##   GRASS (8 clusters x 3 blades): pagoda grounds.
##   WORLD (5): depot bench, third scarecrow, second tea
##     stall, pagoda offering garlands, hamlet pots.
## Total: 19 + 5 + 5 + 8 + 8 + 5 = 50 items.

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

static func _hash01(s: String) -> float:
	# Identical to Slice 94's splitter, so the sex split
	# matches Slice 94 exactly (player male; villagers by
	# hash thirds into male / female A / female B).
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0

static func _people95(world: Node3D) -> void:
	# Second-pass detail on the Slice 94 bodies. Body-local
	# geometry (Slice 94): head centre y 0.65, eyes
	# (±0.055, 0.72, 0.10), nose (0, 0.66, 0.14), chest
	# 0.58 wide / waist 0.44 wide, shoulder pivots
	# (±0.27, 0.42), hip pivots (±0.13, -0.10), sandals
	# (Sandal58) at hip-local (0, -0.90, 0.06), longyi
	# pivot (0, -0.10) with tube local -0.90..0.00.
	# Nothing here moves or re-materials a Slice 94 mesh:
	# every item is an ADDED child, so WalkAnim58 swing
	# and the Slice 94 rebuild are untouched.
	var white_top := _mat(Color(0.96, 0.96, 0.97, 1.0), 0.7)
	var pink_top := _mat(Color(0.95, 0.80, 0.85, 1.0), 0.7)
	var male_lg := _mat(Color(0.20, 0.15, 0.38, 1.0), 0.9)
	var fema_lg := _mat(Color(0.45, 0.20, 0.60, 1.0), 0.9)
	var femb_lg := _mat(Color(0.85, 0.50, 0.65, 1.0), 0.9)
	var dark_btn := _mat(Color(0.15, 0.12, 0.10, 1.0), 0.6)
	var seam := _mat(Color(0.88, 0.88, 0.90, 1.0), 0.7)
	var brow_m := _mat(Color(0.12, 0.08, 0.06, 1.0), 0.9)
	var strap_m := _mat(Color(0.40, 0.15, 0.10, 1.0), 0.8)
	var bodies: Array = []
	for child in world.get_children():
		if child.name == "Player" or String(child.name).begins_with("Villager"):
			bodies.append(child)
	for b in bodies:
		if b.get_node_or_null("Brow95_L") != null:
			continue
		var h: float = _hash01(String(b.name))
		var is_player := String(b.name) == "Player"
		var sex := 0
		if not is_player:
			sex = int(h * 3.0) % 3
		var lg_mat: Material = male_lg
		if sex == 1:
			lg_mat = fema_lg
		elif sex == 2:
			lg_mat = femb_lg
		# Eyebrows (pair): above the Slice 94 eyes, on the
		# face curve, tilted slightly toward the nose.
		_box(b, Vector3(0.05, 0.012, 0.02), brow_m, Vector3(-0.055, 0.745, 0.09), "Brow95_L", Vector3(0.0, 0.0, -0.12))
		_box(b, Vector3(0.05, 0.012, 0.02), brow_m, Vector3(0.055, 0.745, 0.09), "Brow95_R", Vector3(0.0, 0.0, 0.12))
		# Sandal thong straps (pair): on top of the plain
		# Sandal58 boxes, at the front of each foot.
		for side in ["R", "L"]:
			var hip := b.get_node_or_null("HipPivot58_" + side) as Node3D
			if hip != null:
				_box(hip, Vector3(0.14, 0.025, 0.05), strap_m, Vector3(0.0, -0.865, 0.18), "Strap95_" + side)
		if sex == 0:
			# Male taikpon placket seam + 3 front buttons.
			_box(b, Vector3(0.05, 0.52, 0.02), seam, Vector3(0.0, 0.22, 0.18), "Placket95")
			for bi in range(3):
				_sphere(b, 0.015, dark_btn, Vector3(0.0, 0.40 - float(bi) * 0.15, 0.185), "Button95_%d" % bi)
		elif sex == 1:
			# Female A lace: scallop row on the neckline +
			# lace rings at the cap-sleeve edges.
			for si in range(5):
				_sphere(b, 0.02, white_top, Vector3(-0.20 + float(si) * 0.10, 0.46, 0.17), "Scallop95_%d" % si)
			for side in ["R", "L"]:
				var piv := b.get_node_or_null("ShoulderPivot58_" + side) as Node3D
				if piv != null:
					_cyl(piv, 0.102, 0.102, 0.03, white_top, Vector3(0.0, -0.135, 0.0), "SleeveRing95_" + side)
		else:
			# Female B side buttons down the left top edge.
			for bi in range(3):
				_sphere(b, 0.015, white_top, Vector3(-0.30, 0.40 - float(bi) * 0.15, 0.05), "SideBtn95_%d" % bi)
		if sex != 0:
			# Female waistband in the figure's longyi colour.
			_box(b, Vector3(0.46, 0.07, 0.30), lg_mat, Vector3(0.0, 0.10, 0.0), "WaistBand95")
		# Longyi hem band (all figures): slightly proud of
		# the flared tube bottom (tube bottom r 0.32).
		var lpiv := b.get_node_or_null("LongyiPivot58") as Node3D
		if lpiv != null:
			_cyl(lpiv, 0.325, 0.332, 0.06, lg_mat, Vector3(0.0, -0.88, 0.0), "Hem95")

static func _sheet_trees2(root: Node3D) -> void:
	# Second set of the five sheet tree types, on open
	# ground clear of roads, houses, the S-bend corridor
	# (x 1500..1900, z < 0) and all Slice 94 trees (z -30
	# north line, z 30 banana): north line moves to z -55,
	# banana to the south line z 55.
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
	# 1. Toddy palm (800,-55): straight trunk, fan crown,
	# dry hanging fronds, base grass.
	var t1 := _holder(root, Vector3(800.0, 0.0, -55.0), 0.0, "Toddy95")
	_cyl(t1, 0.25, 0.30, 8.0, trunk, Vector3(0.0, 4.0, 0.0), "Trunk95")
	var crown1 := _holder(t1, Vector3(0.0, 8.0, 0.0), 0.0, "Crown95")
	for i in range(8):
		_frond(crown1, float(i) * PI / 4.0, 0.15, 0.6, 1.8, palm_green, "Fan95_%d" % i)
	for i in range(4):
		_box(crown1, Vector3(0.5, 1.2, 0.05), dry, Vector3(0.45 * sin(float(i) * PI / 2.0), -0.6, 0.45 * cos(float(i) * PI / 2.0)), "Dry95_%d" % i)
	for i in range(3):
		_box(t1, Vector3(0.035, 0.40, 0.035), palm_green, Vector3(-0.4 + float(i) * 0.4, 0.20, 0.5), "BaseGrass95_%d" % i)
	# 2. Coconut palm (1200,-55): leaning trunk, arching
	# fronds, nut cluster, one dry frond (sheet detail).
	var t2 := _holder(root, Vector3(1200.0, 0.0, -55.0), 0.0, "Coconut95")
	_cyl(t2, 0.28, 0.32, 3.0, trunk, Vector3(0.0, 1.5, 0.0), "Trunk95_A")
	_cyl(t2, 0.26, 0.28, 3.0, trunk, Vector3(0.35, 4.4, 0.0), "Trunk95_B", Vector3(0.0, 0.0, -0.12))
	_cyl(t2, 0.24, 0.26, 3.0, trunk, Vector3(0.85, 7.2, 0.0), "Trunk95_C", Vector3(0.0, 0.0, -0.20))
	var crown2 := _holder(t2, Vector3(1.1, 8.6, 0.0), 0.0, "Crown95")
	for i in range(8):
		_frond(crown2, float(i) * PI / 4.0, 0.5, 0.35, 2.4, palm_green, "Arch95_%d" % i)
	for i in range(5):
		_sphere(crown2, 0.18, bunch_m, Vector3(0.25 * sin(float(i) * 1.256), -0.3, 0.25 * cos(float(i) * 1.256)), "Nut95_%d" % i)
	_box(crown2, Vector3(0.35, 1.6, 0.05), dry, Vector3(0.0, -0.8, 0.6), "Dry95")
	# 3. Flame tree (2100,-55): spreading branches, green
	# canopy, red blooms, fallen petals on the ground.
	var t3 := _holder(root, Vector3(2100.0, 0.0, -55.0), 0.0, "Flame95")
	_cyl(t3, 0.35, 0.45, 3.0, trunk, Vector3(0.0, 1.5, 0.0), "Trunk95")
	for i in range(4):
		var a := float(i) * PI / 2.0 + PI / 4.0
		_cyl(t3, 0.12, 0.20, 2.5, trunk, Vector3(0.8 * sin(a), 4.0, 0.8 * cos(a)), "Branch95_%d" % i, Vector3(0.6 * cos(a), 0.0, -0.6 * sin(a)))
	for i in range(6):
		var a := float(i) * PI / 3.0
		_sphere(t3, 1.2, leaf_green, Vector3(1.2 * sin(a), 5.0, 1.2 * cos(a)), "Canopy95_%d" % i)
	for i in range(8):
		_sphere(t3, 0.35, flame_red, Vector3(1.6 * sin(float(i) * 0.785), 5.6, 1.6 * cos(float(i) * 0.785)), "Bloom95_%d" % i)
	for i in range(5):
		_box(t3, Vector3(0.12, 0.02, 0.12), flame_red, Vector3(1.8 * sin(float(i) * 1.256), 0.02, 1.8 * cos(float(i) * 1.256)), "Petal95_%d" % i)
	# 4. Banana clump (2300,55): stems, broad leaves,
	# bunch + purple bud, young shoots at the base.
	var t4 := _holder(root, Vector3(2300.0, 0.0, 55.0), 0.0, "Banana95")
	for i in range(5):
		var a := float(i) * 1.256
		_cyl(t4, 0.12, 0.15, 2.5, leaf_green, Vector3(0.5 * sin(a), 1.25, 0.5 * cos(a)), "Stem95_%d" % i)
		_frond(t4, a, 0.6, 0.5, 2.0, banana_leaf, "Leaf95_%d" % i)
		t4.get_node_or_null("Leaf95_%d_Hold" % i).position = Vector3(0.5 * sin(a), 2.5, 0.5 * cos(a))
	_sphere(t4, 0.09, bunch_m, Vector3(0.3, 2.2, 0.2), "Bunch95_A")
	_sphere(t4, 0.09, bunch_m, Vector3(0.45, 2.05, 0.2), "Bunch95_B")
	_sphere(t4, 0.09, bunch_m, Vector3(0.3, 2.05, 0.35), "Bunch95_C")
	_cyl(t4, 0.02, 0.12, 0.35, bud_m, Vector3(0.35, 1.8, 0.25), "Bud95")
	for i in range(2):
		_cyl(t4, 0.08, 0.10, 1.0, leaf_green, Vector3(-0.8 + float(i) * 1.6, 0.5, -0.6), "Shoot95_%d" % i)
		_frond(t4, float(i) * 1.5, 0.5, 0.3, 1.0, banana_leaf, "ShootLeaf95_%d" % i)
		t4.get_node_or_null("ShootLeaf95_%d_Hold" % i).position = Vector3(-0.8 + float(i) * 1.6, 1.0, -0.6)
	# 5. Banyan (500,-55): multi-trunk, aerial roots that
	# REACH the ground (sheet: roots anchor at the base),
	# dense canopy, small shrine + offerings.
	var t5 := _holder(root, Vector3(500.0, 0.0, -55.0), 0.0, "Banyan95")
	_cyl(t5, 0.35, 0.45, 4.0, trunk, Vector3(-0.6, 2.0, 0.0), "Trunk95_A")
	_cyl(t5, 0.35, 0.45, 4.0, trunk, Vector3(0.6, 2.0, 0.3), "Trunk95_B")
	_cyl(t5, 0.30, 0.40, 4.0, trunk, Vector3(0.0, 2.0, -0.5), "Trunk95_C")
	for i in range(6):
		var a := float(i) * PI / 3.0
		_cyl(t5, 0.05, 0.05, 5.5, root_m, Vector3(1.5 * sin(a), 2.75, 1.5 * cos(a)), "Aerial95_%d" % i)
	for i in range(6):
		var a := float(i) * PI / 3.0
		_sphere(t5, 1.6, banyan_leaf, Vector3(1.0 * sin(a), 6.0, 1.0 * cos(a)), "Canopy95_%d" % i)
	_box(t5, Vector3(0.5, 0.4, 0.4), gold, Vector3(1.2, 0.2, 0.8), "Shrine95")
	_box(t5, Vector3(0.7, 0.1, 0.6), gold, Vector3(1.2, 0.45, 0.8), "ShrineRoof95")
	for i in range(2):
		_sphere(t5, 0.05, flame_red, Vector3(1.0 + float(i) * 0.4, 0.48, 1.05), "Offering95_%d" % i)

static func _pagoda_details(root: Node3D) -> void:
	# Detailing ON the Slice 94 pagodas, placed as new
	# standalone holders at the same world positions (so
	# no timing dependency on the Slice 94 dress root).
	# Golden (700,-50): terraces A 10x10 top 0.6, B 8x8
	# top 1.2, C 6x6 top 1.8; spire spans 5.0..8.0.
	var gold := _mat(Color(0.85, 0.65, 0.25, 1.0), 0.5)
	var brick := _mat(Color(0.55, 0.30, 0.20, 1.0), 0.9)
	var moss := _mat(Color(0.25, 0.45, 0.20, 1.0), 0.9)
	var white_m := _mat(Color(0.95, 0.95, 0.93, 1.0), 0.6)
	var pink := _mat(Color(0.95, 0.60, 0.75, 1.0), 0.8)
	var yellow := _mat(Color(0.95, 0.80, 0.20, 1.0), 0.8)
	var g := _holder(root, Vector3(700.0, 0.0, -50.0), 0.0, "PagodaGold95")
	for i in range(4):
		var a := float(i) * PI / 2.0
		_cyl(g, 0.02, 0.3, 1.2, gold, Vector3(4.0 * sin(a), 1.8, 4.0 * cos(a)), "Mini95_%d" % i)
	_sphere(g, 0.12, gold, Vector3(0.0, 8.05, 0.0), "Hti95")
	# Brick (1100,-50): terraces A top 0.8, B top 1.6,
	# C 5x5 top 2.4; stupa base r 1.8 at centre.
	var br := _holder(root, Vector3(1100.0, 0.0, -50.0), 0.0, "PagodaBrick95")
	for i in range(4):
		var a := float(i) * PI / 2.0 + PI / 4.0
		_box(br, Vector3(0.6, 0.05, 0.6), moss, Vector3(2.0 * sin(a), 1.625, 2.0 * cos(a)), "Moss95_%d" % i)
	_box(br, Vector3(5.0, 0.12, 0.4), brick, Vector3(0.0, 2.46, 2.3), "Eave95_N")
	_box(br, Vector3(5.0, 0.12, 0.4), brick, Vector3(0.0, 2.46, -2.3), "Eave95_S")
	_box(br, Vector3(0.4, 0.12, 5.0), brick, Vector3(2.3, 2.46, 0.0), "Eave95_E")
	_box(br, Vector3(0.4, 0.12, 5.0), brick, Vector3(-2.3, 2.46, 0.0), "Eave95_W")
	# White (1500,50): round terrace A r 4.5 top 0.6;
	# spire spans 3.95..6.45.
	var wh := _holder(root, Vector3(1500.0, 0.0, 50.0), 0.0, "PagodaWhite95")
	for i in range(4):
		var a := float(i) * PI / 2.0
		_cyl(wh, 0.02, 0.25, 1.0, white_m, Vector3(3.8 * sin(a), 1.1, 3.8 * cos(a)), "Mini95_%d" % i)
	_sphere(wh, 0.10, gold, Vector3(0.0, 6.5, 0.0), "Finial95")
	# Forest (2000,50): spire spans 2.45..3.95; offering
	# table top 0.85 at (1.5, 2.0).
	var fo := _holder(root, Vector3(2000.0, 0.0, 50.0), 0.0, "PagodaForest95")
	_sphere(fo, 0.10, gold, Vector3(0.0, 4.0, 0.0), "Hti95")
	_sphere(fo, 0.05, pink, Vector3(1.2, 0.90, 2.0), "Flower95_0")
	_sphere(fo, 0.05, yellow, Vector3(1.5, 0.90, 2.0), "Flower95_1")
	_sphere(fo, 0.05, pink, Vector3(1.8, 0.90, 2.0), "Flower95_2")

static func _house_roofs(root: Node3D) -> void:
	# Corrugated ribs + darker rust on the 4 Slice 94
	# restyled houses. Positions/orientations are the
	# Slice 94 ones (holders rot 0; East Fields pitched
	# slabs at y 4.12 with strip tilt +-0.5, hamlet flat
	# slab at y 3.82). Nothing moves; ribs sit ~0.03 above
	# the existing strips/slab.
	var rib := _mat(Color(0.60, 0.30, 0.20, 1.0), 0.9)
	var rust_dark := _mat(Color(0.45, 0.20, 0.12, 1.0), 0.9)
	for hx in [300.0, 330.0]:
		var hz := -16.0
		var g := _holder(root, Vector3(hx, 0.0, hz), 0.0, "Roof95_EF_%d" % int(hx))
		for side in [-1.0, 1.0]:
			var tilt := 0.5 if side < 0.0 else -0.5
			for i in range(7):
				_box(g, Vector3(0.10, 0.04, 1.1), rib, Vector3(-3.0 + float(i), 4.15, side * 1.25), "Rib95_%d_%d" % [int(side), i], Vector3(tilt, 0.0, 0.0))
			_box(g, Vector3(3.0, 0.02, 0.35), rust_dark, Vector3(0.0, 4.13, side * 1.25), "Rust95_%d" % int(side), Vector3(tilt, 0.0, 0.0))
	for hx in [2075.0, 2125.0]:
		var g := _holder(root, Vector3(hx, 0.0, 78.0), 0.0, "Roof95_Ham_%d" % int(hx))
		for i in range(8):
			_box(g, Vector3(0.10, 0.04, 4.4), rib, Vector3(-3.5 + float(i), 3.86, 0.0), "Rib95_%d" % i)
		_box(g, Vector3(3.5, 0.02, 0.5), rust_dark, Vector3(0.0, 3.84, 0.0), "Rust95")

static func _grass95(ctrl: Node3D) -> void:
	# 8 tuft clusters x 3 blades on pagoda grounds, each
	# ~12.8 m from its pagoda centre (clear of bases).
	var green_a := _mat(Color(0.25, 0.55, 0.20, 1.0), 0.9)
	var green_b := _mat(Color(0.35, 0.65, 0.25, 1.0), 0.9)
	var spots: Array = [
		[690.0, -42.0], [710.0, -58.0], [1090.0, -42.0], [1110.0, -58.0],
		[1490.0, 42.0], [1510.0, 58.0], [1990.0, 42.0], [2010.0, 58.0],
	]
	var ci := 0
	for s in spots:
		var tuft := Node3D.new()
		tuft.name = "Grass95_%d" % ci
		tuft.position = Vector3(float(s[0]), 0.0, float(s[1]))
		ctrl.add_child(tuft)
		var blades: Array = [[-0.09, 0.35, -0.20, 0.05, green_a], [0.0, 0.45, 0.06, -0.03, green_b], [0.09, 0.40, 0.24, 0.08, green_a]]
		var bi := 0
		for bl in blades:
			_box(tuft, Vector3(0.035, float(bl[1]), 0.035), bl[4], Vector3(float(bl[0]), float(bl[1]) * 0.5, 0.0), "Blade95_%d_%d" % [ci, bi], Vector3(float(bl[3]), 0.0, float(bl[2])))
			bi += 1
		ci += 1

static func _world95(root: Node3D) -> void:
	var wood := _mat(Color(0.55, 0.38, 0.22, 1.0), 0.9)
	var straw := _mat(Color(0.85, 0.75, 0.35, 1.0), 0.95)
	var red := _mat(Color(0.85, 0.15, 0.15, 1.0), 0.7)
	var clay := _mat(Color(0.75, 0.42, 0.28, 1.0), 0.85)
	var pot_m := _mat(Color(0.55, 0.30, 0.20, 1.0), 0.9)
	var pink := _mat(Color(0.95, 0.60, 0.75, 1.0), 0.8)
	var yellow := _mat(Color(0.95, 0.80, 0.20, 1.0), 0.8)
	var white := _mat(Color(0.95, 0.95, 0.92, 1.0), 0.8)
	# Depot bench at (24,14): clear of office (x 26..34),
	# cones (24,10)/(26,18) and bus parking (x 28.7..31.3).
	_box(root, Vector3(0.08, 0.45, 0.08), wood, Vector3(23.7, 0.225, 14.0), "Bench95_LegL")
	_box(root, Vector3(0.08, 0.45, 0.08), wood, Vector3(24.3, 0.225, 14.0), "Bench95_LegR")
	_box(root, Vector3(1.2, 0.08, 0.45), wood, Vector3(24.0, 0.49, 14.0), "Bench95_Seat")
	_box(root, Vector3(1.2, 0.50, 0.06), wood, Vector3(24.0, 0.80, 13.8), "Bench95_Back")
	# Third scarecrow at (370,-35): east of the crop rows
	# (x 356..368) and the x 354.5 channel.
	_cyl(root, 0.05, 0.05, 1.7, wood, Vector3(370.0, 0.85, -35.0), "Scare95_Post")
	_cyl(root, 0.04, 0.04, 1.0, wood, Vector3(370.0, 1.35, -35.0), "Scare95_Bar", Vector3(0.0, 0.0, 1.5707963267948966))
	_sphere(root, 0.18, straw, Vector3(370.0, 1.75, -35.0), "Scare95_Head")
	_box(root, Vector3(0.70, 0.50, 0.05), red, Vector3(370.0, 1.15, -35.0), "Scare95_Body")
	# Second tea stall at (1600,16): south of the route,
	# clear of the north-side S-bend corridor.
	_box(root, Vector3(1.4, 0.08, 0.9), wood, Vector3(1600.0, 0.75, 16.0), "Tea95_Table")
	_box(root, Vector3(0.40, 0.45, 0.40), wood, Vector3(1599.0, 0.22, 16.8), "Tea95_StoolA")
	_box(root, Vector3(0.40, 0.45, 0.40), wood, Vector3(1601.0, 0.22, 16.8), "Tea95_StoolB")
	_cyl(root, 0.05, 0.04, 0.10, clay, Vector3(1599.7, 0.84, 16.0), "Tea95_CupA")
	_cyl(root, 0.05, 0.04, 0.10, clay, Vector3(1600.3, 0.84, 16.0), "Tea95_CupB")
	# Offering garlands on the 3 Slice 94 offering bowls
	# (bowls at (115.5,-62), (100.5,-62), (108,-54.5),
	# bowl top y 0.20).
	_sphere(root, 0.06, pink, Vector3(115.5, 0.24, -62.0), "Garland95_0")
	_sphere(root, 0.06, yellow, Vector3(100.5, 0.24, -62.0), "Garland95_1")
	_sphere(root, 0.06, white, Vector3(108.0, 0.24, -54.5), "Garland95_2")
	# Hamlet water pots flanking the Slice 94 hamlet
	# clothesline (x 2095..2099, z 88).
	_cyl(root, 0.30, 0.35, 0.6, pot_m, Vector3(2092.0, 0.3, 88.0), "HamPot95_L")
	_cyl(root, 0.30, 0.35, 0.6, pot_m, Vector3(2102.0, 0.3, 88.0), "HamPot95_R")

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism95") != null:
		return
	# World-static items are new nodes (no conflicts), so
	# they go in deferred, like every earlier dressing root.
	# People detail waits until frame >= 80 (after Slice 94's
	# frame-60 pass), so it details final values.
	var root := Node3D.new()
	root.name = "Dress95Root"
	_sheet_trees2(root)
	_pagoda_details(root)
	_house_roofs(root)
	_world95(root)
	world.call_deferred("add_child", root)
	var ctrl := Node3D.new()
	ctrl.name = "Grass95Ctrl"
	ctrl.set_script(load("res://grass_sway93.gd"))
	_grass95(ctrl)
	world.call_deferred("add_child", ctrl)
	var n := Node3D.new()
	n.name = "Realism95"
	n.set_script(load("res://realism95.gd"))
	world.call_deferred("add_child", n)

var _frames: int = 0
var _people_done: bool = false

func _process(_delta: float) -> void:
	# Frame >= 80: after Slice 70 (frame 12), Slice 73
	# (frame 26), Slice 93 (frame 40) and Slice 94
	# (frame 60) have all run, so the detail set lands on
	# final values.
	_frames += 1
	if _frames < 80:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _people_done:
		_people95(world)
		_people_done = true
