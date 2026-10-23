extends Node3D
## Slice 93 GRAPHICS TURBO BATCH (owner order 2026-10-23: turbo
## mode for graphics, then a bigger batch, then the detail spec).
## Runtime dressing ONLY: no .tscn edits, no gameplay, no bus
## systems, no control changes, minibus NOT rewired. Everything
## here is StandardMaterial3D, zero colliders, no dead specular
## lines, and detailed realistic-STYLISED procedural work — not
## scanned photorealism, not claimed as such.
##
## What this batch adds (93 assemblies, each grep-proven missing
## before it was written; see the item notes inline):
##   DETAIL CORE, owner detail spec 2026-10-23:
##   - GRASS (20 tuft clusters x 3 blades): dense where the player
##     actually walks and drives — bus-route edges, the village
##     lane, East Fields road edges. PLAIN LIMIT: tuft CLUSTERS
##     near paths and inhabited areas only, NOT per-blade cover
##     of the whole 2520 m world (millions of meshes would kill
##     phone performance). Blades sway via grass_sway93.gd.
##   - TREES (5 village-tree detail sets): root flare + two
##     angled branch cylinders + a second offset canopy sphere
##     (layered, not a single ball) + fruit on 3 trees, flowers
##     on 2. Types vary; no tree is flattened to one shape.
##   - PEOPLE (1 proportions pass + 38 finger sets): measured
##     BEFORE — head 0.448 m tall on a 1.924 m figure = 23.3%
##     (real adult ~13%), shoulder span 0.85 m = 44% (real ~26%
##     of height, floor 0.65 m given the 0.5 m torso), arm+hand
##     0.67 m = 35% (real ~44%). AFTER — head 0.28 m = 14.6%,
##     shoulders 0.69 m = 36%, arm+hand 0.84 m = 44% (fingertips
##     reach mid-thigh). Head shrink also moves eyes, hat and
##     brim so nothing floats. Fingers: 5 small static boxes per
##     hand (4 fingers + thumb, slightly curled, curl varied per
##     figure), parented to the shoulder pivots so they swing
##     with the existing WalkAnim58 motion. PLAIN LIMIT: static
##     primitives, NOT articulated joints, NOT animated finger
##     movement — procedural code cannot do scanned hands.
##   VEHICLES (7): motorcycle front + rear fenders (segmented
##     arcs over the wheels, NOT solid discs), bus mirror pair +
##     roof AC pod, minibus mirror pair + roof rack, tuk-tuk
##     taillight pair. Bus/minibus items wait for the live nodes
##     (same deferred pattern as Slice 92); motorcycle/tuk-tuk
##     are scene nodes and dress synchronously.
##   WORLD (22): village house steps x2, firewood stacks x2,
##     water jar pair, clothesline, haystacks x2, kilometre
##     posts x5, S-bend guard rail run, depot oil drums,
##     depot tyre stack, pond lotus x2 ponds, boulders x3,
##     East Fields irrigation channel.
## Counting rule: one item = one placed assembly, or one
## symmetric pair placed together (mirror pair, taillight pair,
## jar pair, drum pair). 20 + 5 + 1 + 38 + 7 + 22 = 93.

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

static func _people(world: Node3D) -> void:
	# Proportions pass + fingers, Player + every villager.
	var skin := _mat(Color(0.85, 0.65, 0.50, 1.0), 0.8)
	for child in world.get_children():
		if child.name != "Player" and not String(child.name).begins_with("Villager"):
			continue
		var b := child as Node3D
		if b == null:
			continue
		var head := b.get_node_or_null("Head") as MeshInstance3D
		var skin_mat: Material = null
		if head != null:
			skin_mat = head.get_surface_override_material(0)
			# BEFORE scale (0.85, 1.12, 0.92) -> head 0.448 m.
			# AFTER scale (0.60, 0.70, 0.65) -> head 0.28 m.
			head.scale = Vector3(0.60, 0.70, 0.65)
		if skin_mat == null:
			skin_mat = skin
		var eye_l := b.get_node_or_null("Eye73_L") as Node3D
		var eye_r := b.get_node_or_null("Eye73_R") as Node3D
		if eye_l != null:
			eye_l.position = Vector3(-0.06, 0.725, 0.135)
		if eye_r != null:
			eye_r.position = Vector3(0.06, 0.725, 0.135)
		var hat := b.get_node_or_null("Hat58") as Node3D
		if hat != null and absf(hat.position.y - 1.02) < 0.01:
			hat.position = Vector3(hat.position.x, 0.94, hat.position.z)
		var brim := b.get_node_or_null("HatBrim73") as Node3D
		if brim != null and absf(brim.position.y - 0.92) < 0.01:
			brim.position = Vector3(brim.position.x, 0.86, brim.position.z)
		var curl_base := float(abs(String(b.name).hash()) % 5) * 0.06
		for side in ["R", "L"]:
			var piv := b.get_node_or_null("ShoulderPivot58_" + side) as Node3D
			if piv == null:
				continue
			# BEFORE pivots at +/-0.35 (span 0.85 m); AFTER
			# +/-0.27 (span 0.69 m, the floor the 0.5 m torso
			# allows). Pivot rotation is untouched, so the
			# walk swing keeps working.
			var sx := 0.27 if side == "R" else -0.27
			piv.position = Vector3(sx, piv.position.y, piv.position.z)
			var arm := piv.get_node_or_null("Arm_" + side) as MeshInstance3D
			if arm != null:
				arm.scale = Vector3(arm.scale.x, arm.scale.y * 1.1, arm.scale.z)
			var hand := piv.get_node_or_null("Hand70_" + side) as Node3D
			if hand != null:
				# Hand drops to meet the lengthened arm; the
				# sphere itself is Slice 70's, only moved.
				hand.position = Vector3(hand.position.x, -0.64, hand.position.z)
			# Fingers: 4 fingers + thumb, slightly curled.
			# Fingertips land at pivot-relative -0.84, i.e.
			# body-relative -0.42 (mid-thigh): arm+hand
			# 0.42 -> -0.42 = 0.84 m = 44% of figure height.
			var curl := 0.25 + curl_base
			for fi in range(4):
				var fx := -0.045 + float(fi) * 0.03
				_box(piv, Vector3(0.024, 0.10, 0.024), skin_mat, Vector3(fx, -0.79, 0.0), "Finger93_" + side + "_" + str(fi), Vector3(curl, 0.0, 0.0))
			var tx := -0.075 if side == "R" else 0.075
			var tz := 0.5 if side == "R" else -0.5
			_box(piv, Vector3(0.024, 0.08, 0.024), skin_mat, Vector3(tx, -0.70, 0.0), "Finger93_" + side + "_4", Vector3(0.15, 0.0, tz))

static func _grass(ctrl: Node3D) -> void:
	# 20 tuft clusters x 3 blades, dense where seen, none in
	# far empty ground (see the header limit).
	var green_a := _mat(Color(0.25, 0.55, 0.20, 1.0), 0.9)
	var green_b := _mat(Color(0.35, 0.65, 0.25, 1.0), 0.9)
	var spots: Array = []
	for x in [550.0, 750.0, 950.0, 1150.0, 1350.0, 1550.0, 1750.0, 1950.0, 2150.0, 2350.0]:
		spots.append([x, -8.5])
	for x in [650.0, 1050.0, 1450.0, 1850.0, 2250.0]:
		spots.append([x, 12.5])
	for x in [-5.0, 10.0, 25.0]:
		spots.append([x, -1.6])
	spots.append([280.0, -8.0])
	spots.append([420.0, 8.0])
	var ci := 0
	for s in spots:
		var tuft := Node3D.new()
		tuft.name = "Grass93_%d" % ci
		tuft.position = Vector3(float(s[0]), 0.0, float(s[1]))
		ctrl.add_child(tuft)
		var blades: Array = [[-0.09, 0.35, -0.20, 0.05, green_a], [0.0, 0.45, 0.06, -0.03, green_b], [0.09, 0.40, 0.24, 0.08, green_a]]
		var bi := 0
		for bl in blades:
			_box(tuft, Vector3(0.035, float(bl[1]), 0.035), bl[4], Vector3(float(bl[0]), float(bl[1]) * 0.5, 0.0), "Blade93_%d_%d" % [ci, bi], Vector3(float(bl[3]), 0.0, float(bl[2])))
			bi += 1
		ci += 1

static func _trees(root: Node3D) -> void:
	# 5 village trees (trunk nodes TreeTrunk_* in main.tscn):
	# trunk top 2.5, canopy centre 3.2 r 1.2. Detail adds the
	# root flare, two angled branches, a second offset canopy
	# sphere, and fruit (trees 0, 2, 4) or flowers (1, 3).
	var trunk_m := _mat(Color(0.45, 0.30, 0.20, 1.0), 0.9)
	var leaf_a := _mat(Color(0.20, 0.50, 0.20, 1.0), 0.9)
	var leaf_b := _mat(Color(0.25, 0.58, 0.22, 1.0), 0.9)
	var mango := _mat(Color(0.95, 0.60, 0.10, 1.0), 0.7)
	var bloom_a := _mat(Color(0.95, 0.60, 0.75, 1.0), 0.8)
	var bloom_b := _mat(Color(0.98, 0.95, 0.90, 1.0), 0.8)
	var trees: Array = [[8.0, 6.0], [-12.0, 4.0], [14.0, -8.0], [-18.0, 8.0], [20.0, -12.0]]
	var ti := 0
	for t in trees:
		var x := float(t[0])
		var z := float(t[1])
		_cyl(root, 0.30, 0.62, 0.45, trunk_m, Vector3(x, 0.22, z), "Tree93_%d_Root" % ti)
		_cyl(root, 0.05, 0.08, 1.5, trunk_m, Vector3(x - 0.55, 2.05, z), "Tree93_%d_BranchA" % ti, Vector3(0.0, 0.0, 0.7))
		_cyl(root, 0.05, 0.08, 1.5, trunk_m, Vector3(x + 0.55, 2.05, z), "Tree93_%d_BranchB" % ti, Vector3(0.15, 0.0, -0.7))
		_sphere(root, 0.85, leaf_a if ti % 2 == 0 else leaf_b, Vector3(x + 0.7, 3.9, z + 0.4), "Tree93_%d_Canopy2" % ti)
		if ti % 2 == 0:
			_sphere(root, 0.14, mango, Vector3(x - 0.9, 3.1, z + 0.6), "Tree93_%d_Fruit0" % ti)
			_sphere(root, 0.14, mango, Vector3(x + 0.9, 3.4, z - 0.5), "Tree93_%d_Fruit1" % ti)
			_sphere(root, 0.14, mango, Vector3(x + 0.2, 4.2, z + 0.9), "Tree93_%d_Fruit2" % ti)
		else:
			_sphere(root, 0.09, bloom_a, Vector3(x - 0.8, 3.3, z + 0.5), "Tree93_%d_Flower0" % ti)
			_sphere(root, 0.09, bloom_b, Vector3(x + 0.8, 3.5, z - 0.4), "Tree93_%d_Flower1" % ti)
			_sphere(root, 0.09, bloom_a, Vector3(x + 0.1, 4.1, z + 0.8), "Tree93_%d_Flower2" % ti)
			_sphere(root, 0.09, bloom_b, Vector3(x - 0.3, 3.8, z - 0.9), "Tree93_%d_Flower3" % ti)
		ti += 1

static func _world_items(root: Node3D) -> void:
	var concrete := _mat(Color(0.75, 0.75, 0.72, 1.0), 0.95)
	var wood := _mat(Color(0.55, 0.38, 0.22, 1.0), 0.9)
	var bark := _mat(Color(0.45, 0.30, 0.20, 1.0), 0.95)
	var clay := _mat(Color(0.75, 0.42, 0.28, 1.0), 0.85)
	var white := _mat(Color(0.95, 0.95, 0.92, 1.0), 0.8)
	var red := _mat(Color(0.85, 0.15, 0.15, 1.0), 0.7)
	var straw := _mat(Color(0.85, 0.75, 0.35, 1.0), 0.95)
	var leaf := _mat(Color(0.25, 0.55, 0.20, 1.0), 0.9)
	var water := _mat(Color(0.20, 0.45, 0.75, 1.0), 0.4)
	var grey := _mat(Color(0.55, 0.55, 0.55, 1.0), 0.95)
	var dark := _mat(Color(0.15, 0.15, 0.15, 1.0), 0.8)
	var pink := _mat(Color(0.95, 0.60, 0.75, 1.0), 0.8)
	var blue := _mat(Color(0.30, 0.50, 0.85, 1.0), 0.8)
	var rust := _mat(Color(0.65, 0.30, 0.20, 1.0), 0.8)
	# Village house steps (deck top 0.975; steps descend south
	# from the deck edge). House 5 deck centre (-26, -16), edge
	# z -12.75; house 6 deck centre (0, -22), edge z -18.75.
	# No steps existed for village houses (only school +
	# hospital steps, Slice 72).
	for h in [[5, -26.0, -12.425], [6, 0.0, -18.425]]:
		var hn := int(h[0])
		var hx := float(h[1])
		var z0 := float(h[2])
		for si in range(3):
			var sy := 0.61 - float(si) * 0.24
			_box(root, Vector3(1.8, 0.24, 0.65), concrete, Vector3(hx, sy, z0 + float(si) * 0.65), "Steps93_%d_%d" % [hn, si])
	# Firewood stacks: 3 horizontal logs, pyramid stack.
	for fw in [["A", -20.5, -16.0], ["B", -10.5, 8.0]]:
		var fx := float(fw[1])
		var fz := float(fw[2])
		_cyl(root, 0.12, 0.12, 1.2, bark, Vector3(fx, 0.12, fz - 0.13), "Firewood93_%s_0" % String(fw[0]), Vector3(0.0, 0.0, 1.5707963267948966))
		_cyl(root, 0.12, 0.12, 1.2, bark, Vector3(fx, 0.12, fz + 0.13), "Firewood93_%s_1" % String(fw[0]), Vector3(0.0, 0.0, 1.5707963267948966))
		_cyl(root, 0.12, 0.12, 1.2, bark, Vector3(fx, 0.32, fz), "Firewood93_%s_2" % String(fw[0]), Vector3(0.0, 0.0, 1.5707963267948966))
	# Water jar pair by house 5 (south of its deck edge, clear
	# of the new steps at x -26).
	_cyl(root, 0.28, 0.22, 0.7, clay, Vector3(-24.5, 0.35, -12.0), "Jar93_A")
	_cyl(root, 0.28, 0.22, 0.7, clay, Vector3(-23.8, 0.35, -11.6), "Jar93_B")
	# Clothesline: two posts, a line, three cloths.
	_cyl(root, 0.04, 0.04, 1.8, wood, Vector3(-15.0, 0.9, 2.0), "LinePost93_A")
	_cyl(root, 0.04, 0.04, 1.8, wood, Vector3(-15.0, 0.9, 6.0), "LinePost93_B")
	_box(root, Vector3(0.04, 0.04, 4.0), dark, Vector3(-15.0, 1.65, 4.0), "Line93")
	_box(root, Vector3(0.5, 0.7, 0.03), white, Vector3(-15.0, 1.28, 3.0), "Cloth93_0")
	_box(root, Vector3(0.5, 0.7, 0.03), blue, Vector3(-15.0, 1.28, 4.0), "Cloth93_1")
	_box(root, Vector3(0.5, 0.7, 0.03), pink, Vector3(-15.0, 1.28, 5.0), "Cloth93_2")
	# Haystacks: cone on a low cylinder base.
	for hy in [["A", 356.0, -52.0], ["B", 380.0, 52.0]]:
		_cyl(root, 0.95, 0.95, 0.25, straw, Vector3(float(hy[1]), 0.12, float(hy[2])), "Hay93_%s_Base" % String(hy[0]))
		_cyl(root, 0.0, 0.95, 1.4, straw, Vector3(float(hy[1]), 0.95, float(hy[2])), "Hay93_%s_Cone" % String(hy[0]))
	# Kilometre posts: white post + red top. The x 1500 post
	# sits at 1490, clear of the S-bend slab (x 1495..1505).
	for ki in range(5):
		var kx: float = [500.0, 1000.0, 1490.0, 2000.0, 2400.0][ki]
		_box(root, Vector3(0.25, 1.1, 0.25), white, Vector3(kx, 0.55, -8.0), "Km93_%d" % ki)
		_box(root, Vector3(0.27, 0.25, 0.27), red, Vector3(kx, 1.05, -8.0), "KmTop93_%d" % ki)
	# S-bend guard rail run: posts + rails following the outer
	# (north) edge of the bend, 10-18 m clear of the road slabs.
	# Bend waypoints: (1500,-6) (1500,-80) (1700,-120) (1900,-80).
	var posts: Array = [[1550.0, -100.0], [1600.0, -110.0], [1650.0, -128.0], [1700.0, -132.0], [1750.0, -128.0], [1800.0, -110.0], [1850.0, -100.0]]
	for pi in range(posts.size()):
		_cyl(root, 0.09, 0.09, 1.1, grey, Vector3(float(posts[pi][0]), 0.55, float(posts[pi][1])), "GuardPost93_%d" % pi)
	for ri in range(posts.size() - 1):
		var ax := float(posts[ri][0])
		var az := float(posts[ri][1])
		var bx := float(posts[ri + 1][0])
		var bz := float(posts[ri + 1][1])
		var dx := bx - ax
		var dz := bz - az
		var ln := sqrt(dx * dx + dz * dz)
		_box(root, Vector3(0.15, 0.15, ln), grey, Vector3((ax + bx) * 0.5, 0.95, (az + bz) * 0.5), "GuardRail93_%d" % ri, Vector3(0.0, atan2(dx, dz), 0.0))
	# Depot extras (office 26..34 x, 3.5..8.5 z; buses at
	# (30,16) and (30,26)): oil drums west of the office, a
	# tyre stack east of it, both clear of both footprints.
	_cyl(root, 0.35, 0.35, 0.9, rust, Vector3(24.0, 0.45, 4.0), "Drum93_A")
	_cyl(root, 0.35, 0.35, 0.9, blue, Vector3(24.8, 0.45, 4.6), "Drum93_B")
	for ti in range(3):
		_cyl(root, 0.55, 0.55, 0.25, dark, Vector3(36.0, 0.125 + float(ti) * 0.25, 10.0), "Tire93_%d" % ti)
	# Pond lotus: pads + one flower per pond (ponds had reeds
	# on banks only, no lotus on the water).
	for lp in [[298.0, -58.0], [302.0, -61.0], [300.0, -63.0]]:
		_cyl(root, 0.5, 0.5, 0.05, leaf, Vector3(float(lp[0]), 0.12, float(lp[1])), "LotusPad93_A%d" % int(lp[0]))
	_sphere(root, 0.12, pink, Vector3(300.0, 0.22, -60.0), "LotusFlower93_A")
	for lp in [[413.0, 44.0], [417.0, 46.0]]:
		_cyl(root, 0.5, 0.5, 0.05, leaf, Vector3(float(lp[0]), 0.12, float(lp[1])), "LotusPad93_B%d" % int(lp[0]))
	_sphere(root, 0.12, pink, Vector3(415.0, 0.22, 45.0), "LotusFlower93_B")
	# Boulders: squashed spheres, no colliders (dressing only).
	_sphere(root, 0.7, grey, Vector3(340.0, 0.4, 24.0), "Boulder93_0", 0.7)
	_sphere(root, 0.9, grey, Vector3(1480.0, 0.4, -14.0), "Boulder93_1", 0.7)
	_sphere(root, 0.6, grey, Vector3(-35.0, 0.4, 10.0), "Boulder93_2", 0.7)
	# Irrigation channel beside the north crop strips (rows
	# span x 356..368; the channel runs at x 354.5, clear).
	_box(root, Vector3(0.8, 0.08, 26.0), water, Vector3(354.5, 0.06, -36.0), "Channel93")

static func _vehicle_scene_items(world: Node3D) -> void:
	# Motorcycle fenders + tuk-tuk taillights (scene nodes,
	# present at dress time). Motorcycle wheels at local
	# (0,-0.55,-0.7) front and (0,-0.55,0.7) rear, r 0.38:
	# the fender is three angled boxes arcing over each wheel
	# (a solid disc would hide the tyre, as the opponent's
	# Slice 373 mudguard does). Tuk-tuk body spans z +/-1.2.
	var dark := _mat(Color(0.12, 0.12, 0.12, 1.0), 0.5, 0.3)
	var moto := world.get_node_or_null("Motorcycle") as Node3D
	if moto != null:
		_box(moto, Vector3(0.34, 0.05, 0.30), dark, Vector3(0.0, -0.10, -0.70), "Fender93_F0")
		_box(moto, Vector3(0.34, 0.05, 0.30), dark, Vector3(0.0, -0.205, -0.99), "Fender93_F1", Vector3(-0.7, 0.0, 0.0))
		_box(moto, Vector3(0.34, 0.05, 0.30), dark, Vector3(0.0, -0.205, -0.41), "Fender93_F2", Vector3(0.7, 0.0, 0.0))
		_box(moto, Vector3(0.34, 0.05, 0.30), dark, Vector3(0.0, -0.10, 0.70), "Fender93_R0")
		_box(moto, Vector3(0.34, 0.05, 0.30), dark, Vector3(0.0, -0.205, 0.99), "Fender93_R1", Vector3(0.7, 0.0, 0.0))
		_box(moto, Vector3(0.34, 0.05, 0.30), dark, Vector3(0.0, -0.205, 0.41), "Fender93_R2", Vector3(-0.7, 0.0, 0.0))
	var tuk := world.get_node_or_null("TukTuk") as Node3D
	if tuk != null:
		var tail := _mat(Color(0.85, 0.10, 0.10, 1.0), 0.5)
		tail.emission_enabled = true
		tail.emission = Color(0.8, 0.05, 0.05, 1.0)
		tail.emission_energy_multiplier = 0.6
		_box(tuk, Vector3(0.22, 0.14, 0.06), tail, Vector3(-0.5, 0.30, 1.22), "Tail93_L")
		_box(tuk, Vector3(0.22, 0.14, 0.06), tail, Vector3(0.5, 0.30, 1.22), "Tail93_R")

static func _vehicle_live_items(world: Node3D) -> void:
	# Big bus + minibus (runtime nodes, added deferred): mirror
	# pairs, bus roof AC pod, minibus roof rack. Big bus body
	# centre (0,1.7,0) size 2.6x2.2x9.0; minibus body centre
	# (0,1.6,0) size 2.4x2.0x6.0, roof top 2.79.
	var dark := _mat(Color(0.12, 0.12, 0.12, 1.0), 0.5, 0.3)
	var glass := _mat(Color(0.60, 0.70, 0.80, 1.0), 0.2, 0.4)
	var light := _mat(Color(0.90, 0.90, 0.88, 1.0), 0.6)
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus != null:
		for s in [-1.0, 1.0]:
			var nm := "L" if s < 0.0 else "R"
			_box(bus, Vector3(0.25, 0.05, 0.05), dark, Vector3(s * 1.38, 2.35, -3.9), "MirrorArm93_" + nm)
			_box(bus, Vector3(0.06, 0.30, 0.22), glass, Vector3(s * 1.52, 2.35, -3.9), "Mirror93_" + nm)
		_box(bus, Vector3(1.5, 0.35, 3.2), light, Vector3(0.0, 2.98, 0.3), "ACPod93")
		_box(bus, Vector3(1.2, 0.06, 0.2), dark, Vector3(0.0, 3.17, -0.5), "Vent93_A")
		_box(bus, Vector3(1.2, 0.06, 0.2), dark, Vector3(0.0, 3.17, 1.1), "Vent93_B")
	var mini := world.get_node_or_null("Minibus") as Node3D
	if mini != null:
		for s in [-1.0, 1.0]:
			var nm := "L" if s < 0.0 else "R"
			_box(mini, Vector3(0.22, 0.05, 0.05), dark, Vector3(s * 1.28, 2.1, -2.6), "MiniMirrorArm93_" + nm)
			_box(mini, Vector3(0.06, 0.28, 0.20), glass, Vector3(s * 1.40, 2.1, -2.6), "MiniMirror93_" + nm)
		_box(mini, Vector3(1.6, 0.08, 3.6), dark, Vector3(0.0, 2.95, 0.0), "Rack93")
		for rp in [[-0.75, -1.6], [0.75, -1.6], [-0.75, 1.6], [0.75, 1.6]]:
			_box(mini, Vector3(0.06, 0.18, 0.06), dark, Vector3(float(rp[0]), 2.86, float(rp[1])), "RackPost93_%d_%d" % [int(float(rp[0]) * 100.0), int(float(rp[1]) * 100.0)])

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism93") != null:
		return
	# World-static items are new nodes (no conflicts), so they go
	# in deferred, like every earlier dressing root. People and
	# scene-vehicle items are NOT dressed here: Slices 70 and 73
	# capture at frames >= 12 and >= 26 and would overwrite the
	# head/pivot/hand values, so the Realism93 node below waits
	# until frame >= 40 (after both captures) before mutating.
	var root := Node3D.new()
	root.name = "Dress93Root"
	_trees(root)
	_world_items(root)
	world.call_deferred("add_child", root)
	var ctrl := Node3D.new()
	ctrl.name = "Grass93Ctrl"
	ctrl.set_script(load("res://grass_sway93.gd"))
	_grass(ctrl)
	world.call_deferred("add_child", ctrl)
	var n := Node3D.new()
	n.name = "Realism93"
	n.set_script(load("res://realism93.gd"))
	world.call_deferred("add_child", n)

var _frames: int = 0
var _people_done: bool = false

func _process(_delta: float) -> void:
	# Frame >= 40: after Slice 70 (frame 12) and Slice 73
	# (frame 26) have captured, so this pass's head/pivot/hand
	# values are final. Vehicle items wait for the live Bus +
	# Minibus too (both added deferred by earlier slices).
	_frames += 1
	if _frames < 40:
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
