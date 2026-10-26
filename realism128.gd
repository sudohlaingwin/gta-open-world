extends Node3D
## Slice 128 — GRAPHICS ROUND 3, AUDIT-FIRST, under the owner's
## goal "OpenTaxi Thadingyut Night level game graphic".
## BOUNDARY (binding): take ONLY the visual STANDARD from the
## reference video. NEVER copy OpenTaxi assets, branding,
## names, maps, layouts, or URLs; no club, no Yangon copy, no
## flying cars. World stays village/Mindon/fields.
## AUDIT (audit128 + probes 128/128b/128c/128d/128e/128f, live
## headless, S127 dressing complete):
## - VILLAGE GROUND: grid over village-holder extent
##   (x -40..74, z -22..42), step 20: varied 25/35, BARE 10.
##   Two bare cells are fringe (>30 m from any holder:
##   (-50,48), (-10,48)) and are NOT patched. The other 8
##   are real walked ground and ARE patched (same guards
##   as S127 Mindon: 8 m Walls-centre exclusion, 7 m
##   already-varied guard, dirt palette, 0.06 thick).
## - HAMLET GROUND: grid over HamletHouse75 extent, 6/12
##   varied, BARE 6 — all within 30 m of a hamlet house,
##   all pass the Walls guard. ALL 6 patched. After S128:
##   hamlet 12/12, village 33/35 (2 fringe cells left).
##   Mindon (S127), route (S123), plaza (S122) already done:
##   ground variation is now COMPLETE across every
##   inhabited area.
## - HOUSE TRIM ROUND 2, CORRECTED: the fast-forward audit
##   first "found" House97/Stilt97 untrimmed — WRONG.
##   Natural-run probe (probe128c, NO fast-forward) proves
##   Trim122 total = 59, exactly S122's claim (House97
##   6x4 + Stilt97 5x3 + MDHouse 5x4). The fast-forward
##   harness fires Realism122._apply before scale97's
##   frame-120 House97 creation, and _done blocks retry —
##   a HARNESS ARTIFACT, not a game gap (same class as
##   S127's Lamp124/sim125 artifacts). NO duplicate trim
##   is shipped for House97/Stilt97. Verified-detailed
##   holders are also NOT re-trimmed: OoHouse/House6/
##   School13/DepotOffice82 (S101/S102 Plinth/Corner/
##   Eaves/Pilaster sets), Mindon civic (S100 Plinth100/
##   Corner100), CityBlock56 (_trim_and_door + window
##   grids), StiltHouse13 (S101 frames/sills/corners/
##   steps), LakesideHut19 (S102 Plinth102 + frames +
##   sills + steps), EF StiltHouse62 (S70 rails/braces +
##   S100 window bars — and a ground plinth under a
##   STILT house would read wrong: stilts stand open).
##   MDHouse1/2/3/6/10 stay bare (S103, CLOSED);
##   MDHouse8 skipped (post overlap). The ONLY flat
##   untrimmed house left is FishingHut19 (walls + roof
##   + S124 windows only) — and it carries a REAL DEFECT
##   (below), so it gets plinth + 4 corners (5).
## - REAL DEFECT, FISHING HUT FLOATS: FishingHut19 sits
##   at y = 36.0 (main.tscn line 8222, authored since
##   Slice 19: Transform3D(..., 39, 36, 42)) — 36 m in
##   the air, no hill, no supports, nothing at (39,42)
##   ground level to stand on. Neighbour LakesideHut19
##   sits at y = 0. FIX (runtime dressing only, zero
##   .tscn edits, S126 plane re-face pattern): ground
##   the hut (position.y 36 -> 0) at dress time, only
##   when still at scene position. S124 windows are
##   children and move with it; sim124 gates counts
##   only, so it stays green; the player.gd POI label
##   ("FishingHut19", radius 5.0) now points at the
##   ground hut instead of the sky.
## - FAR-FIELD TREES: 157 trunks, 140 Canopy122, 17
##   uncovered — S123's "invisible" verdict STANDS for
##   16 of them (>40 m from every play anchor). ONE
##   overturns it with NEW evidence: Trunk74 at
##   (953.8,-20.2), 20.2 m from the route corridor
##   (z=0, x 500..2400) where the bus drives — it
##   reads bare from the road. It alone gets a canopy.
## - POND BANKS: reeds ring every pond (Village 6,
##   WestPond97 24, 62A 24, 62B 24, 98s 4 each), but
##   bank ground meshes are 0 at WestPond97/62B/98s
##   and 1 at 62A (Village pond already 108 via plaza/
##   scatter). Only Pond62B is shipped: it is the S127
##   festival pond (water lanterns), a real viewpoint;
##   8 dirt patches on a ring at radius 8.5 (clear of
##   the r5 water and the r5.8 reed ring). WestPond97/
##   62A/98s are remote or world-edge — skipped, stated.
##   River banks skipped: the village river already has
##   path + benches + bridge + rails + lotus (S13/S14);
##   route streams are drive-by scenery, not a 6 m
##   focal point (deferred, not a gap claim).
## PERFORMANCE NOTE: ZERO new OmniLight3Ds, ZERO
## colliders, ZERO per-frame work after _apply (all
## items ungated, visible day AND night — they are
## daytime geometry, lit by existing lights at night).
## Names (Ground128_/Trim128_/Bank128_/Canopy128_)
## match NONE of perf120's hide prefixes (Blade93_/
## 94_/95_/110_, Reed57_/62/107_/108_). Single pass
## at frame >= 730 (after Realism127's 710), with a
## holders-ready retry gate: _apply runs only once
## House97_1 + Stilt97_5 + HamletHouse75_0 exist, so
## a fast-forward ordering quirk can never silently
## ship a wrong ground grid (S122-trim lesson).

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism128") != null:
		return
	var n: Node3D = Node3D.new()
	n.name = "Realism128"
	n.set_script(load("res://realism128.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if _done:
		return
	if _frames < 730:
		return
	if not _holders_ready(get_parent() as Node3D):
		return
	_done = true
	_apply(get_parent() as Node3D)

static func _mat(c: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

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

static func _find_recursive(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f: Node = _find_recursive(c, nm)
		if f != null:
			return f
	return null

static func _find_all(node: Node, prefix: String, out: Array) -> void:
	if String(node.name).begins_with(prefix):
		out.append(node)
	for c in node.get_children():
		_find_all(c, prefix, out)

func _holders_ready(world: Node3D) -> bool:
	if world == null:
		return false
	for tag in ["House97_1", "Stilt97_5", "HamletHouse75_0", "FishingHut19", "Trunk74"]:
		if _find_recursive(world, tag) == null:
			return false
	return true

func _ground_y(world: Node3D) -> float:
	var gm: Node3D = world.get_node_or_null("GroundMesh") as Node3D
	if gm != null:
		return gm.global_position.y
	return 0.0

func _ground_grid(world: Node3D, prefixes: Array, tag: String) -> int:
	var gy: float = _ground_y(world)
	var holders: Array = []
	for prefix in prefixes:
		var arr: Array = []
		_find_all(world, String(prefix), arr)
		for h in arr:
			if h is Node3D:
				holders.append(h as Node3D)
	if holders.size() == 0:
		return 0
	var minx: float = 1e9
	var maxx: float = -1e9
	var minz: float = 1e9
	var maxz: float = -1e9
	for h in holders:
		var hp: Vector3 = (h as Node3D).global_position
		if hp.x < minx:
			minx = hp.x
		if hp.x > maxx:
			maxx = hp.x
		if hp.z < minz:
			minz = hp.z
		if hp.z > maxz:
			maxz = hp.z
	var ground_meshes: Array = []
	var walls_centres: Array = []
	var stack: Array = [world]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if x is MeshInstance3D:
			var mi: MeshInstance3D = x as MeshInstance3D
			var p: Vector3 = mi.global_position
			if mi != world.get_node_or_null("GroundMesh") and absf(p.y - gy) <= 0.6:
				ground_meshes.append(p)
			if String(mi.name).contains("Walls"):
				walls_centres.append(p)
	var dirt: StandardMaterial3D = _mat(Color(0.52, 0.42, 0.30))
	var dirt2: StandardMaterial3D = _mat(Color(0.45, 0.35, 0.25))
	var dry: StandardMaterial3D = _mat(Color(0.62, 0.55, 0.38))
	var mats: Array = [dirt, dirt2, dry]
	var n: int = 0
	var idx: int = 0
	for sx in range(int(minx) - 10, int(maxx) + 11, 20):
		for sz in range(int(minz) - 10, int(maxz) + 11, 20):
			var blocked: bool = false
			for w in walls_centres:
				var wp: Vector3 = w
				if Vector2(wp.x - float(sx), wp.z - float(sz)).length() <= 8.0:
					blocked = true
					break
			if blocked:
				continue
			var varied: bool = false
			for g in ground_meshes:
				var gp: Vector3 = g
				if Vector2(gp.x - float(sx), gp.z - float(sz)).length() <= 7.0:
					varied = true
					break
			if varied:
				continue
			var near_holder: bool = false
			for h in holders:
				var hp: Vector3 = (h as Node3D).global_position
				if Vector2(hp.x - float(sx), hp.z - float(sz)).length() <= 30.0:
					near_holder = true
					break
			if not near_holder:
				continue
			var m: StandardMaterial3D = mats[idx % 3]
			idx += 1
			_box(world, Vector3(5.5, 0.06, 5.5), m,
				Vector3(float(sx), gy + 0.03, float(sz)),
				"Ground128_%s_%d" % [tag, n])
			n += 1
	return n

func _ground_hut(world: Node3D) -> int:
	var hut: Node3D = _find_recursive(world, "FishingHut19") as Node3D
	if hut == null:
		return 0
	var p: Vector3 = hut.position
	if absf(p.y - 36.0) > 0.5:
		return 0
	if absf(p.x - 39.0) > 1.0 or absf(p.z - 42.0) > 1.0:
		return 0
	hut.position = Vector3(p.x, 0.0, p.z)
	return 1

func _hut_trim(world: Node3D) -> int:
	var gy: float = _ground_y(world)
	var hut: Node3D = _find_recursive(world, "FishingHut19") as Node3D
	if hut == null:
		return 0
	var walls: MeshInstance3D = null
	for c in hut.get_children():
		if c is MeshInstance3D and String(c.name).contains("Walls"):
			walls = c as MeshInstance3D
			break
	if walls == null or walls.mesh == null:
		return 0
	var wsz: Vector3 = walls.mesh.get_aabb().size
	var hs: Vector3 = hut.scale
	var ws: Vector3 = walls.scale
	var sx: float = wsz.x * hs.x * ws.x
	var sz: float = wsz.z * hs.z * ws.z
	var wp: Vector3 = walls.global_position
	var dark: StandardMaterial3D = _mat(Color(0.30, 0.22, 0.14))
	var cream: StandardMaterial3D = _mat(Color(0.92, 0.88, 0.78))
	_box(world, Vector3(sx + 0.4, 0.3, sz + 0.4), dark,
		Vector3(wp.x, gy + 0.15, wp.z), "Trim128_FishingHut19_plinth")
	var n: int = 1
	for sxx in [-1.0, 1.0]:
		for szz in [-1.0, 1.0]:
			_box(world, Vector3(0.25, 1.6, 0.25), cream,
				Vector3(wp.x + sxx * sx * 0.5, gy + 0.8, wp.z + szz * sz * 0.5),
				"Trim128_FishingHut19_corner_%d_%d" % [int(sxx), int(szz)])
			n += 1
	return n

func _pond62b_bank(world: Node3D) -> int:
	var gy: float = _ground_y(world)
	var dirt: StandardMaterial3D = _mat(Color(0.52, 0.42, 0.30))
	var dirt2: StandardMaterial3D = _mat(Color(0.45, 0.35, 0.25))
	var dry: StandardMaterial3D = _mat(Color(0.62, 0.55, 0.38))
	var mats: Array = [dirt, dirt2, dry]
	var ground_meshes: Array = []
	var stack: Array = [world]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if x is MeshInstance3D and x != world.get_node_or_null("GroundMesh"):
			var p: Vector3 = (x as Node3D).global_position
			if absf(p.y - gy) <= 0.6:
				ground_meshes.append(p)
	var n: int = 0
	for k in range(8):
		var ang: float = float(k) * 0.7854
		var px: float = 415.0 + cos(ang) * 8.5
		var pz: float = 45.0 + sin(ang) * 8.5
		var blocked: bool = false
		for g in ground_meshes:
			var gp: Vector3 = g
			if Vector2(gp.x - px, gp.z - pz).length() <= 3.0:
				blocked = true
				break
		if blocked:
			continue
		_box(world, Vector3(3.0, 0.06, 3.0), mats[k % 3],
			Vector3(px, gy + 0.03, pz), "Bank128_Pond62B_%d" % k)
		n += 1
	return n

func _trunk74_canopy(world: Node3D) -> int:
	# 32 route trees share the name "Trunk74" (probe128g) —
	# a first-match lookup grabs a covered one (e.g. the
	# (2393,-30) tree) and the guard then correctly refuses.
	# The audit's bare trunk is the SPECIFIC tree at
	# (953.8,-20.188), 20.2 m from the route corridor, so
	# qualify by position, never by name alone.
	var trunks: Array = []
	_find_all(world, "Trunk74", trunks)
	var trunk: MeshInstance3D = null
	for t in trunks:
		if t is MeshInstance3D:
			var tp: Vector3 = (t as Node3D).global_position
			if absf(tp.x - 953.8) < 1.0 and absf(tp.z - (-20.188)) < 1.0:
				trunk = t as MeshInstance3D
				break
	if trunk == null or trunk.mesh == null:
		return 0
	var tp2: Vector3 = trunk.global_position
	var canopies: Array = []
	_find_all(world, "Canopy122_", canopies)
	for c in canopies:
		var cp: Vector3 = (c as Node3D).global_position
		if Vector2(cp.x - tp2.x, cp.z - tp2.z).length() <= 2.0:
			return 0
	var h: float = trunk.mesh.get_aabb().size.y
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "Canopy128_Trunk74"
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = 1.5
	sm.height = 3.0
	mi.mesh = sm
	mi.set_surface_override_material(0, _mat(Color(0.15, 0.45, 0.18)))
	mi.position = tp2 + Vector3(0.0, h * 0.5 + 0.4, 0.0)
	world.add_child(mi)
	return 1

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var g: int = _ground_hut(world)
	var v: int = _ground_grid(world, ["House97", "Stilt97", "OoHouse", "FishingHut", "LakesideHut"], "Village")
	var h: int = _ground_grid(world, ["HamletHouse75_"], "Hamlet")
	var t: int = _hut_trim(world)
	var b: int = _pond62b_bank(world)
	var c: int = _trunk74_canopy(world)
	print("REALISM128 dressed: hut_grounded=", g, " village_ground=", v, " hamlet_ground=", h, " hut_trim=", t, " pond62b_bank=", b, " trunk74_canopy=", c)
