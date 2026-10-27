extends Node3D

## Slice 153 — TERRAIN RELIEF + FOOTHILLS + HILL DRESSING.
##
## Audit153 (on the 6014177 tree, live, holders-ready gated) established:
## - S152 mountains confirmed: 29 (N 23 at z=-650, h 79-104; E 6 at
##   x=4050, h 81-82). Border hills confirmed: Edge97 Hill97N/S 25+25
##   (z=-495/395, R 20-44, h 16-34), Hill97W/E 8+8 (x=-655/3835).
##   Hills are CONES (edge97 _cone: top_radius 0.1 — a POINT, not a
##   flat disc), so summit dressing must bury into the apex, not sit
##   on a disc. Border trees: N 61, S 61, W 12, E 12.
## - NPC homes/anchors: village walkers 1-18 all within x -40..45,
##   z -35..42; S152 walkers 19-22 east (x 3170..3270), 23-24
##   Mindon-south (x 165..215, z 130..160). Wander radii 3-12 m.
## - 21 candidate relief zones PASS the live LOW-mesh guard (nearest
##   ground-level blocker 8.8-133.6 m away, nearest NPC home/anchor
##   85+ m away); 4 zones FAIL and are SKIPPED (W1 7.5 m, W2 0 m,
##   W4 1.5 m, M5 0 m — inside/near field patches).
##
## Design (three parts, all runtime dressing, zero .tscn edits):
## 1. GENTLE SWELLS inside the playable area, ONLY in gameplay-empty
##    open land (no roads, paths, houses, stops, ponds, NPC homes /
##    anchors, traffic routes, or quests within guard distances).
##    Heights 0.7-1.2 m over radii 6-16 m (slopes ~5 deg). CLIPPING
##    LIMIT, STATED OPENLY: the player/vehicle physics plane stays
##    flat, so a player who deliberately walks to a swell crown
##    sinks up to 1.2 m visually at the exact crown, cm-scale on
##    the flanks. This is why swells are gentle (not 3-5 m mounds)
##    and why sites are gameplay-empty: no play path crosses a
##    swell, so the clip needs deliberate hiking to reach. A real
##    heightmap-physics terrain would fix it properly and is a
##    major pipeline change, NOT this slice. If the owner finds
##    the crown clip unacceptable on his phone, the honest fixes
##    are lower swells or removal — report it, do not hide it.
## 2. FOOTHILLS outside the playable clamp (player can never touch
##    them, so ZERO clipping possible): north row at z=-575 (south
##    edge -515 at worst radius, 5.5 m outside the -509.5 clamp)
##    bridging Hill97N (16-34 m) to Mountain152_N (79-104 m), and
##    east row at x=3950 (west edge 3865 at worst radius, 15.5 m
##    outside the 3849.5 clamp) bridging Hill97E to Mountain152_E.
##    Heights 35-60 m, radii 45-85 m, alternating rock/forest like
##    the S152 mountains. Foothills may mass against Hill97 /
##    Mountain152 meshes (that overlap IS the continuous rise);
##    every other LOW mesh still blocks them. Backdrop class
##    (proven by probe153b, not assumed): SkylineS108_* /
##    SkylineE101_* bands are low-AABB backdrop walls along the
##    same edges — 9 north + 5 east foothill candidates failed
##    ONLY on a Skyline band (e.g. N0 distance 0, E1/E2/E3
##    distance 0), so Skyline joins Hill97/Mountain152_ in the
##    foothill ignore list. Mounds do NOT ignore Skyline (no
##    Skyline band comes near any inside-playable mound site).
## 3. SUMMIT DRESSING on all 66 Edge97 hills (the standing
##    "hill summit dressing skipped" residual): one single-cone
##    pine (r 2.0, h 6, base buried 1.5 m below the apex point so
##    its base meets the cone flank) + one boulder (r 1.2,
##    half-buried in the peak slope 2 m off-axis) per hill, both
##    placed from the hill's OWN live CylinderMesh (bottom
##    radius + height) and global position — never guessed.
##    Mountain summits are NOT dressed (79-104 m peaks 500-800 m
##    away: a tree there would not read; stated, not skipped
##    silently).
##
## Guards (S138 pattern, enforced live in code, not just audit):
## - _site_clear: every visible in-tree MeshInstance3D with global
##   AABB min-y < 0.5 counts as a blocker EXCEPT true ground
##   planes (BOTH XZ half-extents > 30 m — long thin road slabs
##   still block) and this slice's own prefixes (so a cluster's
##   second mound does not fail against its first). Footprint
##   must clear every blocker by >= 0.3 m or the item is SKIPPED,
##   never overlapped.
## - _npc_clear: >= 20 m from every villager home AND day anchor
##   (wander radii are 3-12 m; 20 m covers normal wander + margin;
##   S132 widening rings only trigger when a villager is already
##   surrounded by obstacles, which cannot happen at these sites
##   because the sites themselves are obstacle-free).
## - _route_clear: >= radius + 2 m from every traffic route
##   centerline segment (traffic cars have no physics body, so a
##   mound on a mesh-less dirt lane would still be driven
##   through; routes run on roads anyway, so this is belt and
##   braces).
## - NO houses and NO roads are placed by this slice (S152's data
##   block stands: Overpass still blocked, Google Maps fetch
##   failed; nothing here claims a surveyed position).
## - Names avoid S146 tint targets (no Ground*/Canopy*/TreeTop*
##   prefixes) and perf120 hide prefixes (no Blade*/Reed*), so
##   S146 and perf120 both ignore this dressing by construction.
##   S146, S152, and all prior slices untouched.
## - Perf: zero per-frame tree walks, zero per-frame light
##   writers, zero colliders, zero lights; everything writes once
##   at _apply. Frame gate 880 (after Realism152's 870).

const FRAME_GATE: int = 880

var _frames: int = 0
var _done: bool = false
var _mounds: int = 0
var _mounds_skipped: int = 0
var _rocks: int = 0
var _foothills: int = 0
var _summits: int = 0

static func dress(world: Node) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism153") != null:
		return
	var node: Node = Node3D.new()
	node.name = "Realism153"
	node.set_script(load("res://realism153.gd"))
	world.call_deferred("add_child", node)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done:
		if _frames >= FRAME_GATE and _holders_ready():
			_apply()
		return
	# No night items, no per-frame work: everything wrote once.

static func _find_rec(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f: Node = _find_rec(c, nm)
		if f != null:
			return f
	return null

func _holders_ready() -> bool:
	var w: Node = get_parent()
	if w == null:
		return false
	var r152: Node = _find_rec(w, "Realism152")
	if r152 == null:
		return false
	var done152: Variant = r152.get("_done")
	if done152 != null and not bool(done152):
		return false
	if _find_rec(w, "House97_1") == null:
		return false
	if _find_rec(w, "HamletHouse75_0") == null:
		return false
	if _find_rec(w, "Edge97") == null:
		return false
	return true

func _mat(r: float, g: float, b: float, rough: float = 0.9, metal: float = 0.0) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(r, g, b, 1.0)
	m.roughness = rough
	m.metallic = metal
	return m

func _mound(parent: Node3D, rx: float, h: float, rz: float, mat: Material, pos: Vector3, name: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mi.mesh = mesh
	mi.material_override = mat
	mi.scale = Vector3(rx, h * 0.5, rz)
	mi.position = Vector3(pos.x, h * 0.5, pos.z)
	mi.name = name
	parent.add_child(mi)
	return mi

func _cone(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, name: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = h
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.name = name
	parent.add_child(mi)
	return mi

func _sphere(parent: Node3D, r: float, mat: Material, pos: Vector3, name: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = r
	mesh.height = 2.0 * r
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.name = name
	parent.add_child(mi)
	return mi

func _hash01(s: String) -> float:
	var h: int = 0
	for i in range(s.length()):
		h = (h * 31 + s.unicode_at(i)) % 1000003
	return float(h % 1000) / 1000.0

func _global_aabb(mi: MeshInstance3D) -> AABB:
	return mi.global_transform * mi.get_aabb()

func _xz_dist_to_aabb(px: float, pz: float, ab: AABB) -> float:
	var dx: float = 0.0
	if px < ab.position.x:
		dx = ab.position.x - px
	elif px > ab.position.x + ab.size.x:
		dx = px - (ab.position.x + ab.size.x)
	var dz: float = 0.0
	if pz < ab.position.z:
		dz = ab.position.z - pz
	elif pz > ab.position.z + ab.size.z:
		dz = pz - (ab.position.z + ab.size.z)
	return sqrt(dx * dx + dz * dz)

func _is_ground_plane(ab: AABB) -> bool:
	return ab.size.x * 0.5 > 30.0 and ab.size.z * 0.5 > 30.0

func _is_own(name: String) -> bool:
	return name.begins_with("Mound153_") or name.begins_with("Foothill153_") or name.begins_with("Summit153_") or name.begins_with("Rock153_")

func _collect_lows(world: Node) -> Array:
	var stack: Array = [world]
	var out: Array = []
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if x is MeshInstance3D and bool((x as MeshInstance3D).visible) and bool((x as MeshInstance3D).is_visible_in_tree()):
			var mi: MeshInstance3D = x as MeshInstance3D
			var ab: AABB = _global_aabb(mi)
			if ab.position.y < 0.5 and not _is_ground_plane(ab) and not _is_own(String(mi.name)):
				out.append([mi, ab])
	return out

func _site_clear(lows: Array, x: float, z: float, radius: float, ignore_prefixes: Array) -> bool:
	for item in lows:
		var mi: MeshInstance3D = item[0]
		var nm: String = String(mi.name)
		var ignored: bool = false
		for pre in ignore_prefixes:
			if nm.begins_with(String(pre)):
				ignored = true
				break
		if ignored:
			continue
		var ab: AABB = item[1]
		if _xz_dist_to_aabb(x, z, ab) < radius + 0.3:
			return false
	return true

func _npc_clear(x: float, z: float) -> bool:
	var vg: Array = get_tree().get_nodes_in_group("villagers")
	for v in vg:
		var hv: Variant = v.get("home")
		var av: Variant = v.get("day_anchor")
		if hv is Vector3:
			var hp: Vector3 = hv
			if sqrt((hp.x - x) * (hp.x - x) + (hp.z - z) * (hp.z - z)) < 20.0:
				return false
		if av is Vector3:
			var ap: Vector3 = av
			if ap != Vector3.ZERO and sqrt((ap.x - x) * (ap.x - x) + (ap.z - z) * (ap.z - z)) < 20.0:
				return false
	return true

func _seg_dist(px: float, pz: float, ax: float, az: float, bx: float, bz: float) -> float:
	var dx: float = bx - ax
	var dz: float = bz - az
	var len2: float = dx * dx + dz * dz
	var t: float = 0.0
	if len2 > 0.0:
		t = ((px - ax) * dx + (pz - az) * dz) / len2
		if t < 0.0:
			t = 0.0
		elif t > 1.0:
			t = 1.0
	var cx: float = ax + t * dx
	var cz: float = az + t * dz
	return sqrt((px - cx) * (px - cx) + (pz - cz) * (pz - cz))

func _route_clear(x: float, z: float, radius: float) -> bool:
	var segs: Array = [
		[500.0, 0.0, 2400.0, 0.0], [2445.0, 0.0, 3400.0, 0.0],
		[3400.0, 0.0, 3800.0, 0.0], [2100.0, 6.0, 2100.0, 60.0],
		[250.0, -3.0, 445.0, -3.0], [445.0, 3.0, 250.0, 3.0],
		[340.0, 0.0, 340.0, -95.0], [390.0, 0.0, 390.0, 75.0],
		[-1.0, 10.0, -1.0, -17.0], [-1.0, -17.0, -8.0, -17.0],
		[-8.0, -17.0, -8.0, -28.5], [-8.0, -28.5, 24.0, -28.5],
		[24.0, -28.5, 24.0, -18.5], [24.0, -18.5, 18.0, -18.5],
		[18.0, -18.5, 18.0, -12.0], [18.0, -12.0, 3.0, -12.0],
		[3.0, -12.0, 3.0, -16.0], [3.0, -16.0, -10.0, -16.0],
		[-10.0, -16.0, -10.0, -8.0], [-10.0, -8.0, -10.0, 6.0],
		[-10.0, 6.0, -13.0, 6.0], [-13.0, 6.0, -13.0, 10.0],
		[2.0, 28.0, 2.0, 36.0], [2.0, 36.0, 14.0, 36.0],
		[14.0, 36.0, 14.0, 28.0], [14.0, 28.0, 14.0, 26.6],
		[14.0, 26.6, 6.0, 26.6],
	]
	for s in segs:
		if _seg_dist(x, z, float(s[0]), float(s[1]), float(s[2]), float(s[3])) < radius + 2.0:
			return false
	return true

func _place_ok(lows: Array, x: float, z: float, radius: float, ignore_prefixes: Array) -> bool:
	return _site_clear(lows, x, z, radius, ignore_prefixes) and _npc_clear(x, z) and _route_clear(x, z, radius)

func _apply() -> void:
	var world: Node = get_parent()
	if world == null:
		return
	var lows: Array = _collect_lows(world)
	var dirt_a: StandardMaterial3D = _mat(0.58, 0.50, 0.33)
	var dirt_b: StandardMaterial3D = _mat(0.65, 0.52, 0.32)
	var grass_dry: StandardMaterial3D = _mat(0.45, 0.50, 0.25)
	var pale: StandardMaterial3D = _mat(0.66, 0.60, 0.44)
	var rock_m: StandardMaterial3D = _mat(0.45, 0.47, 0.45)
	var forest_m: StandardMaterial3D = _mat(0.16, 0.38, 0.18)
	var pine_m: StandardMaterial3D = _mat(0.10, 0.35, 0.12)
	var mats: Array = [dirt_a, dirt_b, grass_dry, pale]
	# 1. Gentle swells: [zone, x, z, main_r, main_h]. Satellites at
	# fixed offsets, each individually guard-checked (a failed
	# satellite is skipped, never forced).
	var zones: Array = [
		["N1", 0.0, -150.0, 15.0, 1.1], ["N2", 150.0, -220.0, 15.0, 1.2],
		["N3", -180.0, -200.0, 15.0, 1.0], ["N4", 0.0, -320.0, 6.0, 0.7],
		["N5", 250.0, -150.0, 14.0, 1.1], ["N6", 0.0, -450.0, 12.0, 1.0],
		["S1", 0.0, 150.0, 15.0, 1.1], ["S2", 150.0, 220.0, 13.0, 1.0],
		["S3", -120.0, 180.0, 15.0, 1.2], ["S4", 60.0, 280.0, 10.0, 0.9],
		["S5", -250.0, 250.0, 12.0, 1.0],
		["E1", 2800.0, 120.0, 15.0, 1.1], ["E2", 2800.0, -120.0, 12.0, 1.0],
		["E3", 3200.0, 100.0, 14.0, 1.1], ["E4", 3200.0, -150.0, 15.0, 1.2],
		["E5", 3600.0, 80.0, 12.0, 1.0], ["E6", 3600.0, -100.0, 15.0, 1.1],
		["W3", -300.0, 150.0, 15.0, 1.2],
		["M1", 1200.0, 150.0, 14.0, 1.0], ["M2", 1200.0, -150.0, 15.0, 1.1],
		["M3", 1800.0, 100.0, 14.0, 1.1], ["M4", 800.0, -200.0, 15.0, 1.2],
	]
	var zi: int = 0
	for zn in zones:
		var zname: String = String(zn[0])
		var zx: float = float(zn[1])
		var zz: float = float(zn[2])
		var zr: float = float(zn[3])
		var zh: float = float(zn[4])
		var zmat: Material = mats[zi % mats.size()]
		if _place_ok(lows, zx, zz, zr, []):
			_mound(self, zr, zh, zr, zmat, Vector3(zx, 0.0, zz), "Mound153_%s" % zname)
			_mounds += 1
		else:
			_mounds_skipped += 1
		# Satellites (guard-checked one by one against NON-own
		# meshes; a satellite that clears the guard may still
		# merge into its zone's main mound — same material, so
		# the pair reads as one ridge, not two intersecting
		# colours. Deliberate, stated, not a guard hole: the
		# guard's job is keeping mounds off roads/houses/NPC
		# areas, and own-cluster merging changes no play fact.)
		var sats: Array = [[16.0, 8.0, 10.0, 0.8], [-17.0, 10.0, 9.0, 0.7]]
		var si: int = 0
		for sat in sats:
			var sx: float = zx + float(sat[0])
			var sz: float = zz + float(sat[1])
			var sr: float = float(sat[2])
			var sh: float = float(sat[3])
			if _place_ok(lows, sx, sz, sr, []):
				_mound(self, sr, sh, sr, zmat, Vector3(sx, 0.0, sz), "Mound153_%s_S%d" % [zname, si])
				_mounds += 1
			else:
				_mounds_skipped += 1
			si += 1
		# Flank boulder (guard-checked).
		var rx: float = zx + zr + 5.0
		var rz: float = zz + 3.0
		if _place_ok(lows, rx, rz, 1.4, []):
			_sphere(self, 1.0 + _hash01("rock153" + zname) * 0.4, rock_m, Vector3(rx, 0.6, rz), "Rock153_%s" % zname)
			_rocks += 1
		zi += 1
	# 2. Foothills OUTSIDE the clamp (no clipping possible).
	# North: z=-575, worst radius 60 -> south edge -515, 5.5 m
	# outside the -509.5 clamp. East: x=3950, worst radius 85 ->
	# west edge 3865, 15.5 m outside the 3849.5 clamp.
	for i in range(16):
		var fx: float = -600.0 + float(i) * 293.0
		var fr: float = 45.0 + _hash01("fhN%d" % i) * 15.0
		var fh: float = 35.0 + _hash01("fhNh%d" % i) * 25.0
		var fm: Material = rock_m if i % 2 == 0 else forest_m
		if -575.0 + fr > -512.0:
			continue
		if _place_ok(lows, fx, -575.0, fr, ["Hill97", "Mountain152_", "Skyline"]):
			_cone(self, fr * 0.15, fr, fh, fm, Vector3(fx, fh * 0.5, -575.0), "Foothill153_N%d" % i)
			_foothills += 1
	for j in range(5):
		var fz: float = -400.0 + float(j) * 200.0
		var fr2: float = 60.0 + _hash01("fhE%d" % j) * 25.0
		var fh2: float = 40.0 + _hash01("fhEh%d" % j) * 20.0
		var fm2: Material = rock_m if j % 2 == 0 else forest_m
		if 3950.0 - fr2 < 3855.0:
			continue
		if _place_ok(lows, 3950.0, fz, fr2, ["Hill97", "Mountain152_", "Skyline"]):
			_cone(self, fr2 * 0.15, fr2, fh2, fm2, Vector3(3950.0, fh2 * 0.5, fz), "Foothill153_E%d" % j)
			_foothills += 1
	# 3. Summit dressing on all Edge97 hills, from each hill's OWN
	# live CylinderMesh (bottom radius + height) and position.
	# Hills are cones (top_radius 0.1): apex = position.y + h/2 =
	# h (position.y IS h/2). Pine cone base buried 1.5 m below the
	# apex so its base meets the cone flank; boulder half-buried
	# in the peak slope 2 m off-axis.
	var edge: Node = _find_rec(world, "Edge97")
	if edge != null:
		for c in edge.get_children():
			if String(c.name).begins_with("Hill97") and c is MeshInstance3D:
				var hill: MeshInstance3D = c as MeshInstance3D
				if not (hill.mesh is CylinderMesh):
					continue
				var cm: CylinderMesh = hill.mesh as CylinderMesh
				var hh: float = cm.height
				var hp: Vector3 = hill.global_position
				var apex: float = hp.y + hh * 0.5
				_cone(self, 0.1, 2.0, 6.0, pine_m, Vector3(hp.x, apex + 1.5, hp.z), "Summit153_Pine_%s" % String(c.name))
				var ang: float = _hash01("summit153" + String(c.name)) * 6.283
				var ox: float = cos(ang) * 2.0
				var oz: float = sin(ang) * 2.0
				_sphere(self, 1.2, rock_m, Vector3(hp.x + ox, apex - 1.0, hp.z + oz), "Summit153_Rock_%s" % String(c.name))
				_summits += 1
	_done = true
	print("REALISM153 dressed: mounds=", _mounds, " skipped=", _mounds_skipped, " rocks=", _rocks, " foothills=", _foothills, " summit_hills=", _summits)
