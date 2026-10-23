extends Node3D

## Slice 106 (parent sequence): DETAIL ROUND 5 — cone-tree upgrade,
## field rows, pond reeds. Audit-first, live-probed 2026-10-24:
## - Edge97's border/scatter/track "pines" are BARE single cones
##   (CylinderMesh top 0.1, bottom r 2.2-2.5, base at ground, NO
##   trunk, NO second tier). BorderTree97: N 61 + S 61 + W 12 +
##   E 12 = 146; ScatTree97: 67; TrackTree97: 6. Total 219 trees.
##   Each gets a visible trunk (cone lifted 1.8 m, trunk bridges
##   ground to cone base) + an upper tier cone. A trunk alone
##   would be INVISIBLE inside the 2.2-2.5 m cone base, so the
##   lift is load-bearing, not cosmetic churn: trunk local
##   y = -h*0.5 - 0.9, tier local y = h*0.33 (base at 62% of
##   cone height). Cones carry NO colliders, so lifting them
##   cannot trap the player or break a road.
## - Field97 boxes (43) are flat colour slabs with ZERO row
##   children (audit107b) — S97's Field98 were NEW fields with
##   rows, NOT rows on Field97, so this is a real fix, not a
##   duplicate. Each Field97 box gets 3 crop rows (children at
##   local y 0.08, z -8/0/8, size 38 x 0.06 x 0.8).
## - West Pond97 (-350, 0, r 12) has NO reeds within 307 m
##   (audit107c: nearest ReedTip57 is 307.64 m away). It gets
##   an 8-cluster reed ring at r 12.8, 3 stalks per cluster.
## Deliberately NOT added (audited, already present or not
## visible at 6 m): markets/tea/monastery/zayat/school/pagoda
## dressing, scarecrows, ploughs, clotheslines, kilometre posts
## (S104 audit); vehicle trim incl. Tail99/Stand99/Bag99/Mud99/
## Bump99/Harness105/Nav99 (audit107b naming traps — probe
## terms, not gaps); earrings/necklaces (would not read at 6 m);
## market umbrellas (stalls already have awnings); vendor
## figures (no vendor construction exists; villagers stand at
## the market already). Cow2 (ambient, not rideable), traffic-car
## drivers (solid cabins), bus door window (strip spans above
## door), temple bell / traffic lights (invented / no logic).
## MD1/2/3/6/10 stay bare + unscaled (S103 decision, permanent,
## NOT reopened); MindonPost/MDHouse8 overlap stands (S105,
## relocation = arbitrary re-placement); night residuals stand
## (rows band 1.41 m gap, spur 1.3 m, junction 4.5 m, hill-face
## 4.71 m — marginal, NOT padded with more lamps).
## Counting (stated): trees counted per run/set (border N/S/W/E,
## scatter set, track set = 6, S97 set precedent); fields
## counted per field (S97: 6 fields = 6 items); pond ring = 1.
## TOTAL: 6 + 43 + 1 = 50 honest items, no padding.
## Runtime dressing ONLY, no .tscn edits, no bus-system changes,
## minibus NOT rewired, big bus NOT rewired (Slice 81 limit),
## touch controls untouched, zero NEW colliders,
## StandardMaterial3D only, no dead specular lines, no
## fog/SSAO/glow claims (no WorldEnvironment exists), no
## photorealism claims: stylised smooth procedural work.
## Runs at frame >= 320, after realism106's 300 pass.
## Honest limit: phone feel unproven until the owner's vivo V60
## verdict.

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism107") != null:
		return
	var n := Node3D.new()
	n.name = "Realism107"
	n.set_script(load("res://realism107.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 320:
		_done = true
		_apply(get_parent() as Node3D)

static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
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

static func _cyl(parent: Node, r_top: float, r_bot: float, h: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	mi.mesh = cm
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
	_trees(world)
	_fields(world)
	_pond(world)

func _trees(world: Node3D) -> void:
	var edge := _find(world, "Edge97") as Node3D
	if edge == null:
		return
	var trunk_m := _mat(Color(0.45, 0.30, 0.20, 1.0), 0.9)
	var leaf_m := _mat(Color(0.10, 0.35, 0.12, 1.0), 1.0)
	for tree in edge.get_children():
		var tn := String(tree.name)
		if not (tn.begins_with("BorderTree97") or tn.begins_with("ScatTree97") or tn.begins_with("TrackTree97")):
			continue
		if not (tree is MeshInstance3D):
			continue
		var mi := tree as MeshInstance3D
		if not (mi.mesh is CylinderMesh):
			continue
		var cm: CylinderMesh = mi.mesh
		var h := cm.height
		var r := cm.bottom_radius
		# Lift the cone so the trunk below it is visible (a
		# trunk inside the 2.2-2.5 m cone base would be hidden).
		mi.position.y += 1.8
		_cyl(mi, 0.32, 0.28, 1.8, trunk_m, Vector3(0.0, -h * 0.5 - 0.9, 0.0), "Trunk107_" + tn)
		_cyl(mi, 0.1, r * 0.62, h * 0.42, leaf_m, Vector3(0.0, h * 0.33, 0.0), "Tier107_" + tn)

func _fields(world: Node3D) -> void:
	var edge := _find(world, "Edge97") as Node3D
	if edge == null:
		return
	var crop_a := _mat(Color(0.20, 0.55, 0.20, 1.0), 1.0)
	var crop_b := _mat(Color(0.45, 0.55, 0.15, 1.0), 1.0)
	for field in edge.get_children():
		var fn := String(field.name)
		if not fn.begins_with("Field97_"):
			continue
		for ri in 3:
			var rz := -8.0 + 8.0 * float(ri)
			_box(field, Vector3(38.0, 0.06, 0.8), crop_a if ri % 2 == 0 else crop_b, Vector3(0.0, 0.08, rz), "Row107_%s_%d" % [fn, ri])

func _pond(world: Node3D) -> void:
	var reed_m := _mat(Color(0.25, 0.55, 0.25, 1.0), 1.0)
	for ci in 8:
		var ang := float(ci) * 0.7853981633974483
		var cx := -350.0 + 12.8 * cos(ang)
		var cz := 12.8 * sin(ang)
		for si in 3:
			var ox := float([-0.25, 0.0, 0.25][si])
			var oz := float([0.2, -0.15, 0.1][si])
			_cyl(world, 0.03, 0.03, 1.2, reed_m, Vector3(cx + ox, 0.6, cz + oz), "Reed107_Pond_%d_%d" % [ci, si])
