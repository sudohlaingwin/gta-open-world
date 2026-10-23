extends Node3D

## Slice 105 (parent sequence): DETAIL ROUND 4 — second-vehicle parity,
## vehicle trim gaps, district street furniture. Audit-first, live-probed
## 2026-10-24: every item below was PROVEN missing before it was added.
## Deliberately NOT added (audited, already present): people — faces
## (S104 re-mesh), hair/hats/knots/sandals/fingers/flowers (S58/S73/
## S94/S95), longyi stripes/bands/waistbands/aprons/cuffs/collars/
## lace/panels/buttons (S73/S94/S95/S97/S98); the 3 apparent bun gaps
## (Villager3/9/11 lack Bun94) are NOT gaps — all three carry the older
## HairBun73; female-B heels are by sheet design (S94 gives heel blocks
## to female A only). Traffic-car drivers (cabins are solid boxes —
## a driver inside would not read). Bus door window (the side-window
## strip spans above the door). Cow2 dressing (ambient herd cow, not a
## rideable — cow.gd has no Cow2 reference and no ride mission; the
## rideable Cow already has saddle/bell/reins/girth). Temple bell
## (invented, not sheet-specified). Traffic lights at intersections
## (would be static decoration with no signal logic).
## Runtime dressing ONLY, no .tscn edits, no bus-system changes,
## minibus NOT rewired, big bus NOT rewired (Slice 81 limit), touch
## controls untouched, zero NEW colliders, StandardMaterial3D only,
## no dead specular lines, no fog/SSAO/glow claims (no WorldEnvironment
## exists), no photorealism claims: stylised smooth procedural work.
## Runs at frame >= 300, after realism105's 280 pass.
##
## AUDIT findings (live probes audit106/audit106b/c/d/e/f):
## - Cart: canopy/posts/wheels/rails/yoke/sacks/lamp exist, NO bench.
## - Motorcycle: rear plate only (Plate94_MotoR), NO front plate, NO
##   indicators (count Indicator = 2, both the S104 car pair).
## - Tuk-tuk: single centre headlight, NO indicators.
## - Airplane: propeller is a bare blade box, NO spinner cone.
## - Horse2 (rideable, horse.gd runs both horses): saddle/stirrups/
##   blanket exist, NO bridle, NO reins, NO blanket trim (Horse has
##   all three: Bridle99, Reins99, Trim105).
## - Boat2 (rideable): hull/benches/oars exist, NO rope coil, NO stern
##   lantern, NO fish basket (Boat has Rope99, LampPost99/Lamp99,
##   Fish99).
## - Elephant: howdah/posts/roof/blanket/bell exist, NO access ladder.
## - Mindon streets: lane markings + curbs + lamps exist, ZERO benches
##   near the streets, ZERO bins anywhere (count Bin = 0), NO zebra
##   crossings (only hospital crosses), NO post-office flag (school
##   flag exists; MindonPost/Hospital/Edu Flag = 0 — post office only,
##   hospitals do not fly flags the same way). Flag goes on the post's
##   NORTH side: the front (local z +3.2) lands inside MDHouse8's
##   footprint — pre-existing overlap (post walls 10.2 x 8.5 at
##   (148, 26) vs MDHouse8 walls 10.8 x 9.0 at (148, 32), 2.75 m in z;
##   post front door world z 30.32 opens inside MDHouse8). Relocating
##   either building would be arbitrary re-placement, so the conflict
##   stands and is reported, not silently fixed.
## Counting: one item = one placed assembly, or one symmetric pair/
## set placed together (S93/S94 rule). VEHICLES 12 + WORLD 13 = 25
## honest items (under the ~50 target, NO padding).
## DONE vs DEFERRED: MD1/2/3/6/10 stay bare + unscaled (S103 decision,
## permanent, NOT reopened); StiltHouse17_5/18_6 pavilions (S96
## exclusion stands); House1/2/3/4 slabs stay hidden (House97_1-4);
## night residuals stand (rows band ~1.4, spur 1.3 m, junction 4.5 m,
## hill-face 4.71 m — marginal, NOT padded with more lamps).
## Honest limit: phone feel unproven until the owner's vivo V60 verdict.

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism106") != null:
		return
	var n := Node3D.new()
	n.name = "Realism106"
	n.set_script(load("res://realism106.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 300:
		_done = true
		_apply(get_parent() as Node3D)

static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m

static func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
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

static func _cyl(parent: Node, r_top: float, r_bot: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node, r: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
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

static func _find(world: Node, nm: String) -> Node:
	if world == null:
		return null
	if String(world.name) == nm:
		return world
	for c in world.get_children():
		var r := _find(c, nm)
		if r != null:
			return r
	return null

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_vehicles(world)
	_world_items(world)

func _vehicles(world: Node3D) -> void:
	var wood := _mat(Color(0.45, 0.30, 0.15, 1.0), 0.9)
	var dark := _mat(Color(0.15, 0.15, 0.15, 1.0), 0.7)
	var leather := _mat(Color(0.40, 0.25, 0.10, 1.0), 0.8)
	var amber := _mat(Color(1.0, 0.65, 0.0, 1.0), 0.4)
	var white := _mat(Color(0.95, 0.95, 0.95, 1.0), 0.5)
	var chrome := _mat(Color(0.85, 0.85, 0.87, 1.0), 0.3, 0.8)
	var rope_m := _mat(Color(0.75, 0.65, 0.45, 1.0), 1.0)
	var red := _mat(Color(0.70, 0.10, 0.10, 1.0), 0.8)
	# 1. Cart driver bench (cart faces -z; driver sits at front, back
	# toward +z; bed top is local y 0.4).
	var cart := _find(world, "Cart")
	if cart != null:
		_box(cart, Vector3(1.40, 0.08, 0.45), wood, Vector3(0.0, 0.70, -1.40), "Bench106_Cart_Seat")
		_box(cart, Vector3(1.40, 0.50, 0.08), wood, Vector3(0.0, 0.95, -1.18), "Bench106_Cart_Back")
		_box(cart, Vector3(0.08, 0.30, 0.08), wood, Vector3(-0.60, 0.55, -1.40), "Bench106_Cart_LegL")
		_box(cart, Vector3(0.08, 0.30, 0.08), wood, Vector3(0.60, 0.55, -1.40), "Bench106_Cart_LegR")
	# 2. Motorcycle front plate (mirrors rear Plate94_MotoR, forward -z).
	var moto := _find(world, "Motorcycle")
	if moto != null:
		_box(moto, Vector3(0.24, 0.16, 0.03), white, Vector3(0.0, -0.25, -1.15), "Plate106_MotoF")
		# 3. Motorcycle indicator pair (at handlebar ends, forward -z).
		_box(moto, Vector3(0.06, 0.08, 0.06), amber, Vector3(-0.30, 0.48, -0.70), "Indicator106_Moto_L")
		_box(moto, Vector3(0.06, 0.08, 0.06), amber, Vector3(0.30, 0.48, -0.70), "Indicator106_Moto_R")
	# 4. Tuk-tuk indicator pair (front face z -1.2, headlight at -1.25).
	var tuk := _find(world, "TukTuk")
	if tuk != null:
		_box(tuk, Vector3(0.12, 0.12, 0.06), amber, Vector3(-0.55, 0.20, -1.22), "Indicator106_Tuk_L")
		_box(tuk, Vector3(0.12, 0.12, 0.06), amber, Vector3(0.55, 0.20, -1.22), "Indicator106_Tuk_R")
	# 5. Airplane spinner cone (propeller plane z -2.1, tip forward -z;
	# cylinder +Y is the small top radius, rot -90 deg maps +Y to -Z).
	var plane := _find(world, "Airplane")
	if plane != null:
		_cyl(plane, 0.03, 0.12, 0.30, chrome, Vector3(0.0, 0.0, -2.33), "Spinner106_Plane", Vector3(-1.5708, 0.0, 0.0))
	# 6-8. Horse2 parity (same locals as Horse's S98/S105 dressing).
	var horse2 := _find(world, "Horse2")
	if horse2 != null:
		_box(horse2, Vector3(0.06, 0.30, 0.06), leather, Vector3(-0.27, 1.90, -1.20), "Bridle106_H2_L")
		_box(horse2, Vector3(0.06, 0.30, 0.06), leather, Vector3(0.27, 1.90, -1.20), "Bridle106_H2_R")
		_box(horse2, Vector3(0.54, 0.07, 0.06), leather, Vector3(0.0, 2.05, -1.20), "Bridle106_H2_Top")
		_box(horse2, Vector3(0.04, 0.04, 1.30), leather, Vector3(-0.20, 1.85, -0.45), "Rein106_H2_L")
		_box(horse2, Vector3(0.04, 0.04, 1.30), leather, Vector3(0.20, 1.85, -0.45), "Rein106_H2_R")
		_box(horse2, Vector3(1.06, 0.05, 1.26), red, Vector3(0.0, 1.77, 0.10), "Trim106_H2")
	# 9-11. Boat2 parity (same locals as Boat's S98 dressing).
	var boat2 := _find(world, "Boat2")
	if boat2 != null:
		_cyl(boat2, 0.16, 0.16, 0.045, rope_m, Vector3(0.0, 0.575, -0.95), "Rope106_Boat2_0")
		_cyl(boat2, 0.13, 0.13, 0.045, rope_m, Vector3(0.0, 0.620, -0.95), "Rope106_Boat2_1")
		_cyl(boat2, 0.10, 0.10, 0.045, rope_m, Vector3(0.0, 0.665, -0.95), "Rope106_Boat2_2")
		_box(boat2, Vector3(0.06, 0.70, 0.06), dark, Vector3(0.0, 0.90, 1.05), "LampPost106_Boat2")
		_sphere(boat2, 0.09, _glow_mat(Color(1.0, 0.85, 0.55, 1.0), 1.2), Vector3(0.0, 1.28, 1.05), "Lamp106_Boat2")
		_cyl(boat2, 0.26, 0.26, 0.35, wood, Vector3(-0.22, 0.725, 0.0), "Fish106_Boat2")
	# 12. Elephant howdah ladder (+x side, clear of 1.1 body half-width;
	# ground is local y -1.6, howdah top 2.825).
	var ele := _find(world, "Elephant")
	if ele != null:
		_box(ele, Vector3(0.06, 4.45, 0.06), wood, Vector3(1.35, 0.625, -0.15), "Ladder106_Ele_RailA")
		_box(ele, Vector3(0.06, 4.45, 0.06), wood, Vector3(1.35, 0.625, 0.35), "Ladder106_Ele_RailB")
		for i in 5:
			var ry := float([-1.00, -0.10, 0.80, 1.70, 2.40][i])
			_box(ele, Vector3(0.06, 0.06, 0.50), wood, Vector3(1.35, ry, 0.10), "Ladder106_Ele_Rung%d" % i)

func _world_items(world: Node3D) -> void:
	var wood := _mat(Color(0.45, 0.30, 0.15, 1.0), 0.9)
	var green := _mat(Color(0.15, 0.35, 0.20, 1.0), 0.8)
	var silver := _mat(Color(0.75, 0.75, 0.78, 1.0), 0.4, 0.6)
	var flag_red := _mat(Color(0.75, 0.10, 0.10, 1.0), 0.8)
	var paint_white := _mat(Color(0.95, 0.95, 0.95, 1.0), 0.7)
	# 13-16. Mindon street benches (street half-width 3 + curb 0.3, block
	# faces at |z| 8 — z +-5.5 sits between; x 145/180 sit in block gaps).
	for bi in 4:
		var bx := float([145.0, 145.0, 180.0, 180.0][bi])
		var bz := float([-5.50, 5.50, -5.50, 5.50][bi])
		var back_z := bz + (0.22 if bz > 0.0 else -0.22)
		_box(world, Vector3(1.60, 0.08, 0.45), wood, Vector3(bx, 0.45, bz), "Bench106_Mindon_%d" % bi)
		_box(world, Vector3(0.08, 0.45, 0.40), wood, Vector3(bx - 0.70, 0.225, bz), "BenchLeg106_Mindon_%d_L" % bi)
		_box(world, Vector3(0.08, 0.45, 0.40), wood, Vector3(bx + 0.70, 0.225, bz), "BenchLeg106_Mindon_%d_R" % bi)
		_box(world, Vector3(1.60, 0.50, 0.06), wood, Vector3(bx, 0.80, back_z), "BenchBack106_Mindon_%d" % bi)
	# 17-22. Litter bins (Mindon 4 + village market 1 + EF road 1).
	var bin_sites: Array = [Vector3(150.0, 0.0, -5.50), Vector3(150.0, 0.0, 5.50), Vector3(210.0, 0.0, -5.50), Vector3(210.0, 0.0, 5.50), Vector3(-2.0, 0.0, 2.0), Vector3(320.0, 0.0, -8.0)]
	for i in bin_sites.size():
		var bp: Vector3 = bin_sites[i]
		_cyl(world, 0.28, 0.28, 0.70, green, Vector3(bp.x, 0.35, bp.z), "Bin106_%d" % i)
		_cyl(world, 0.30, 0.30, 0.06, green, Vector3(bp.x, 0.72, bp.z), "BinRim106_%d" % i)
	# 23. Post-office flag (MindonPost child, group scale 1.7 — the S96
	# street-clearance exception, verified live; world pole base
	# (145.62, 0, 20.56), 1.02 m clear of the post solid's north face.
	# NORTH side, not the front: the front (local z +3.2) lands inside
	# MDHouse8's footprint — pre-existing layout conflict, reported
	# not fixed: MDHouse8 walls (148, 32, world 10.8 x 9.0) overlap the
	# post walls (148, 26, world 10.2 x 8.5) by 2.75 m in z, and the
	# post front door (world z 30.32) opens inside MDHouse8. Moving
	# either building would be arbitrary re-placement (owner order),
	# so the conflict stands and the flag goes on the clear side.
	var post := _find(world, "MindonPost")
	if post != null:
		_box(post, Vector3(0.08, 4.00, 0.08), silver, Vector3(-1.40, 2.00, -3.20), "FlagPole106_Post")
		_box(post, Vector3(0.70, 0.45, 0.02), flag_red, Vector3(-1.01, 3.70, -3.20), "Flag106_Post")
	# 24-25. Mindon zebra crossings (across the z=0 main street at the
	# block gaps x 145/180; stripes at y 0.20, above the 0.18 dashes).
	for ci in 2:
		var cx := float([145.0, 180.0][ci])
		for si in 6:
			var sz := -2.50 + float(si) * 1.00
			_box(world, Vector3(2.50, 0.02, 0.50), paint_white, Vector3(cx, 0.20, sz), "Zebra106_%d_%d" % [ci, si])
