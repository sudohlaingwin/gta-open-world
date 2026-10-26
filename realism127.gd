extends Node3D
## Slice 127 — NIGHT ROUND 2 under the owner's goal
## "OpenTaxi Thadingyut Night level game graphic" (2026-10-26).
## BOUNDARY (binding): take ONLY the visual STANDARD from the
## reference video. NEVER copy OpenTaxi assets, branding,
## names, maps, layouts, or URLs; no club, no Yangon copy, no
## flying cars. World stays village/Mindon/fields; festival
## content here is ORIGINAL Thadingyut content for OUR world.
## AUDIT (audit127 + audit127b, live headless, night forced
## to daylight 0, S126 dressing complete):
## - MINDON-DISTRICT GROUND, REAL GAP (S124 deferral, now
##   audited): MDHouse extent x=[125,220] z=[-35,62]; grid
##   36 samples step 20 m: varied 15, BARE 21; ZERO S122/S123
##   patches inside Mindon. FIX: live-computed patches on
##   bare samples (same rule as the audit: no ground-level
##   mesh within 7 m) + an 8 m walls-centre exclusion so no
##   patch clips a house footprint; dirt palette, 0.06 thick
##   at ground + 0.03. No route conflict: the route starts
##   at x=500, Mindon extent ends at x=220.
## - COLOURED ACCENTS: 24 at audit (S124 counted 8) — mostly
##   festival lanterns/fireworks + beacons + fountains, NOT
##   building accents. Real gap: MindonShops front has warm
##   light only (ShopGlass/Mullion/Header, 15-16 warm emis
##   nearby, zero colour); village StallC13 group has ZERO
##   emissive neighbours (dark stall). FIX: 3 coloured boxes
##   on the MindonShops front (cyan strip + gold/pink flanks,
##   anchored to live ShopHeader100) + 2 lantern boxes on
##   StallC front posts + 2 on StallD front posts (post
##   positions read live; lanterns sit ON the posts so they
##   cannot float). Emissive only, ZERO new omnis.
## - FESTIVAL DENSITY: village 17 festival meshes within
##   100 m (dense, untouched); pagoda 9 (fine, untouched);
##   hamlet 8 = ONE firework site only, no lanterns/lamps;
##   Mindon 4 counted (Fireworks56 sparks are named Spark56,
##   not Firework-prefixed, so the count understates Mindon
##   — Mindon has fireworks + 4 sky lanterns, still no lamps).
##   FIX: 4 sky lanterns over hamlet (houses at (2075/2125,
##   78/98), site at (2100,88) centre) + 4 corner yard lamps
##   on hamlet houses (walls-AABB corners, facing-free) +
##   8 water lanterns on the VILLAGE pond (16,-2, never had
##   any) + 6 on Pond62B (415,45, never had any). Edge ponds
##   Pond98_0 (-500,-300) + Pond98_1 (2400,320) skipped:
##   world-edge, low phone visibility (stated, not hidden).
## - SKY: 48 stars visible (8 + 40, enough — no more stars,
##   that would be padding). Moon17 static at (-30,25,-40),
##   mesh AABB 4x4x4 (radius 2.0); DayNight only toggles its
##   visibility, never moves it. FIX (S124's rejection
##   distinguished): NOT a plain solid sphere — a
##   TRANSPARENT shell (radius moon + 0.8, alpha 0.12,
##   emission 0.6) centred on the live moon position. A
##   transparent shell larger than the moon cannot read as a
##   second moon; it reads as a halo. Static (moon never
##   moves), night-gated, one node, zero per-frame work.
##   If the owner says it reads as a second moon, reverting
##   it is one node.
## - DARK BUILDINGS ROUND 2: 56 Walls-holders checked, ZERO
##   dark (S124 windows + gate fixes lit them all). NO new
##   windows shipped — that would be padding (stated).
## - NOT re-done: S123's audit-disproved canopy round 2
##   (17 far trunks) and S124's audit-corrected route pools
##   (route already continuous) — no new evidence overturns
##   those audits.
## PERFORMANCE NOTE: ZERO new OmniLight3Ds (all emissive
## MeshInstance3D). Names (Ground127_/Accent127_/
## SkyLantern127_/Lamp127_/WaterLantern127_/Halo127_)
## match NONE of perf120's hide prefixes. Zero colliders.
## Animation touches ONLY this node's own arrays (sky rise
## + water bob), only at night; day hides everything and
## skips updates. Light visibility is written ONLY on
## night-state change (S120 composition). Single pass at
## frame >= 710 (after Realism126's 700, before Perf120's
## 720 scan, so any new light would join its cache — though
## this slice adds no lights at all).

var _frames: int = 0
var _done: bool = false
var _gated: Array = []
var _last_night: bool = false
var _gate_once: bool = false
var _anim_t: float = 0.0
var _sky: Array = []
var _sky_base: Array = []
var _water: Array = []
var _water_base: Array = []
var _water_phase: Array = []

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism127") != null:
		return
	var n: Node3D = Node3D.new()
	n.name = "Realism127"
	n.set_script(load("res://realism127.gd"))
	world.call_deferred("add_child", n)

func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 710:
		_done = true
		_apply(get_parent() as Node3D)
	if not _done:
		return
	var world: Node3D = get_parent() as Node3D
	if world == null:
		return
	var day: float = 1.0
	var dn: Node = world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		day = float(dn.call("daylight"))
	var night: bool = day < 0.15
	if not _gate_once or night != _last_night:
		_gate_once = true
		_last_night = night
		for g in _gated:
			var m: Node3D = g as Node3D
			if m != null:
				m.visible = night
	if night:
		_anim_t += delta
		_update_festival(delta)

static func _mat(c: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

static func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 1.0
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

func _ground_y(world: Node3D) -> float:
	var gm: Node3D = world.get_node_or_null("GroundMesh") as Node3D
	if gm != null:
		return gm.global_position.y
	return 0.0

func _mindon_ground(world: Node3D) -> int:
	var gy: float = _ground_y(world)
	var centres: Array = []
	var minx: float = 1e9
	var maxx: float = -1e9
	var minz: float = 1e9
	var maxz: float = -1e9
	var stack: Array = [world]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if not (x is Node3D):
			continue
		var nm: String = String(x.name)
		if nm.begins_with("MDHouse") and nm.substr(7).is_valid_int():
			var p: Vector3 = (x as Node3D).global_position
			centres.append(p)
			if p.x < minx:
				minx = p.x
			if p.x > maxx:
				maxx = p.x
			if p.z < minz:
				minz = p.z
			if p.z > maxz:
				maxz = p.z
	if centres.size() == 0:
		return 0
	var ground_meshes: Array = []
	var walls_centres: Array = []
	var stack2: Array = [world]
	while not stack2.is_empty():
		var x = stack2.pop_back()
		for c in x.get_children():
			stack2.append(c)
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
			var m: StandardMaterial3D = mats[idx % 3]
			idx += 1
			_box(world, Vector3(5.5, 0.06, 5.5), m,
				Vector3(float(sx), gy + 0.03, float(sz)),
				"Ground127_Mindon_%d" % n)
			n += 1
	return n

func _shop_accents(world: Node3D) -> int:
	# TIMING-PROOF placement (sim127 run-1 lesson): MindonShops
	# is scaled x1.8 by scale97 (frame-120 pass, probe-verified
	# scale (1.8,1.8,1.8)); a world-global position read at
	# _apply time can predate that scale and land 1.58 m low /
	# 2.06 m south (exactly what run 1 measured). So the
	# accents are children of MindonShops, positioned from the
	# header's LOCAL position with the final 1.8 factored in —
	# correct once the scale applies, whenever _apply runs.
	var holder: Node3D = null
	var header: Node3D = null
	var stack: Array = [world]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if String(x.name) == "MindonShops" and x is Node3D:
			holder = x as Node3D
		if String(x.name) == "ShopHeader100" and x is Node3D:
			header = x as Node3D
	if holder == null or header == null:
		return 0
	var hp: Vector3 = header.position
	var cyan: StandardMaterial3D = _glow_mat(Color(0.25, 0.80, 1.0, 1.0), 1.8)
	var gold: StandardMaterial3D = _glow_mat(Color(1.0, 0.75, 0.25, 1.0), 1.8)
	var pink: StandardMaterial3D = _glow_mat(Color(1.0, 0.40, 0.65, 1.0), 1.8)
	var dy: float = 0.65 / 1.8
	var dz: float = 0.12 / 1.8
	var strip: MeshInstance3D = _box(holder, Vector3(3.2 / 1.8, 0.28 / 1.8, 0.10 / 1.8), cyan,
		Vector3(hp.x, hp.y + dy, hp.z + dz), "Accent127_Shop_Strip")
	strip.visible = false
	_gated.append(strip)
	var left: MeshInstance3D = _box(holder, Vector3(0.50 / 1.8, 0.28 / 1.8, 0.10 / 1.8), gold,
		Vector3(hp.x - 3.5 / 1.8, hp.y + dy, hp.z + dz), "Accent127_Shop_Gold")
	left.visible = false
	_gated.append(left)
	var right: MeshInstance3D = _box(holder, Vector3(0.50 / 1.8, 0.28 / 1.8, 0.10 / 1.8), pink,
		Vector3(hp.x + 3.5 / 1.8, hp.y + dy, hp.z + dz), "Accent127_Shop_Pink")
	right.visible = false
	_gated.append(right)
	return 3

func _stall_post_lanterns(world: Node3D, prefix: String, tag: String, col_a: Color, col_b: Color) -> int:
	var gy: float = _ground_y(world)
	var posts: Array = []
	var stack: Array = [world]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if String(x.name).begins_with(prefix) and x is Node3D:
			posts.append(x as Node3D)
	if posts.size() < 2:
		return 0
	var maxz: float = -1e9
	for p in posts:
		var pp: Vector3 = (p as Node3D).global_position
		if pp.z > maxz:
			maxz = pp.z
	var front: Array = []
	for p in posts:
		var pp: Vector3 = (p as Node3D).global_position
		if absf(pp.z - maxz) < 0.01:
			front.append(p as Node3D)
	if front.size() < 2:
		return 0
	front.sort_custom(func(a, b): return (a as Node3D).global_position.x < (b as Node3D).global_position.x)
	var n: int = 0
	var cols: Array = [col_a, col_b]
	for i in range(mini(2, front.size())):
		var fp: Vector3 = (front[i] as Node3D).global_position
		var lamp: MeshInstance3D = _box(world, Vector3(0.30, 0.35, 0.30),
			_glow_mat(cols[i], 1.8),
			Vector3(fp.x, gy + 1.6, fp.z + 0.15),
			"Accent127_Stall_%s_%d" % [tag, i])
		lamp.visible = false
		_gated.append(lamp)
		n += 1
	return n

func _hamlet_festival(world: Node3D) -> int:
	var gy: float = _ground_y(world)
	var total: int = 0
	var bases: Array = [Vector3(2085.0, 0.0, 80.0), Vector3(2115.0, 0.0, 80.0),
		Vector3(2085.0, 0.0, 96.0), Vector3(2115.0, 0.0, 96.0)]
	var warm: StandardMaterial3D = _glow_mat(Color(1.0, 0.65, 0.25, 1.0), 1.8)
	var pink: StandardMaterial3D = _glow_mat(Color(1.0, 0.45, 0.60, 1.0), 1.8)
	var cyan: StandardMaterial3D = _glow_mat(Color(0.45, 0.80, 1.0, 1.0), 1.8)
	for i in range(bases.size()):
		var b: Vector3 = bases[i]
		var m: StandardMaterial3D = warm
		if i == 2:
			m = pink
		elif i == 3:
			m = cyan
		var lamp: MeshInstance3D = _box(world, Vector3(0.45, 0.60, 0.45), m,
			Vector3(b.x, 3.0 + float(i) * 3.5, b.z), "SkyLantern127_%d" % i)
		lamp.visible = false
		_gated.append(lamp)
		_sky.append(lamp)
		_sky_base.append(b)
		total += 1
	var lamp_mat: StandardMaterial3D = _glow_mat(Color(1.0, 0.70, 0.30, 1.0), 1.6)
	var houses: Array = ["HamletHouse75_0", "HamletHouse75_1", "HamletHouse75_2", "HamletHouse75_3"]
	for tag in houses:
		var holder: Node3D = null
		var stack: Array = [world]
		while not stack.is_empty():
			var x = stack.pop_back()
			for c in x.get_children():
				stack.append(c)
			if String(x.name) == tag and x is Node3D:
				holder = x as Node3D
				break
		if holder == null:
			continue
		var walls: MeshInstance3D = null
		for c in holder.get_children():
			if c is MeshInstance3D and String(c.name).contains("Walls"):
				walls = c as MeshInstance3D
				break
		if walls == null or walls.mesh == null:
			continue
		var ws: Vector3 = walls.mesh.get_aabb().size
		var wp: Vector3 = walls.position
		var centre: Vector3 = holder.global_position + wp
		var lamp: MeshInstance3D = _box(world, Vector3(0.25, 0.30, 0.25), lamp_mat,
			Vector3(centre.x + ws.x * 0.5 + 0.5, gy + 0.35, centre.z + ws.z * 0.5 + 0.5),
			"Lamp127_Hamlet_%s" % tag)
		lamp.visible = false
		_gated.append(lamp)
		total += 1
	return total

func _pond_lanterns(world: Node3D) -> int:
	var n: int = 0
	var gold: StandardMaterial3D = _glow_mat(Color(1.0, 0.70, 0.30, 1.0), 1.6)
	var pink: StandardMaterial3D = _glow_mat(Color(1.0, 0.45, 0.60, 1.0), 1.6)
	var cyan: StandardMaterial3D = _glow_mat(Color(0.45, 0.80, 1.0, 1.0), 1.6)
	var ponds: Array = [[Vector3(16.0, 0.0, -2.0), 8, "Village"], [Vector3(415.0, 0.0, 45.0), 6, "Pond62B"]]
	for pi in range(ponds.size()):
		var pc: Vector3 = ponds[pi][0]
		var cnt: int = ponds[pi][1]
		var tag: String = String(ponds[pi][2])
		for k in range(cnt):
			var ang: float = float(k) * 0.6283 + float(pi) * 0.5
			var r: float = 3.0 + float(k % 3) * 1.5
			if pi == 1:
				r = 2.0 + float(k % 2) * 2.0
			var m: StandardMaterial3D = gold
			if k % 4 == 1:
				m = pink
			elif k % 4 == 3:
				m = cyan
			var px: float = pc.x + cos(ang) * r
			var pz: float = pc.z + sin(ang) * r
			var lamp: MeshInstance3D = _box(world, Vector3(0.40, 0.25, 0.40), m,
				Vector3(px, 0.30, pz), "WaterLantern127_%s_%d" % [tag, k])
			lamp.visible = false
			_gated.append(lamp)
			_water.append(lamp)
			_water_base.append(Vector3(px, 0.30, pz))
			_water_phase.append(float(k) * 0.9)
			n += 1
	return n

func _moon_halo(world: Node3D) -> int:
	var moon: Node3D = null
	var stack: Array = [world]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if String(x.name) == "Moon17" and x is Node3D:
			moon = x as Node3D
			break
	if moon == null or not (moon is MeshInstance3D):
		return 0
	var mmi: MeshInstance3D = moon as MeshInstance3D
	if mmi.mesh == null:
		return 0
	var msz: Vector3 = mmi.mesh.get_aabb().size
	var moon_r: float = maxf(msz.x, msz.z) * 0.5
	var shell_r: float = moon_r + 0.8
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.85, 0.12)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.85, 1.0)
	mat.emission_energy_multiplier = 0.6
	mat.roughness = 1.0
	mat.metallic = 0.0
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "Halo127_Moon"
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = shell_r
	sm.height = shell_r * 2.0
	mi.mesh = sm
	mi.set_surface_override_material(0, mat)
	mi.position = moon.global_position
	mi.visible = false
	mi.set_meta("halo_moon_r", moon_r)
	mi.set_meta("halo_shell_r", shell_r)
	world.add_child(mi)
	_gated.append(mi)
	return 1

func _update_festival(delta: float) -> void:
	for i in range(_sky.size()):
		var lamp: Node3D = _sky[i] as Node3D
		var b: Vector3 = _sky_base[i]
		var y: float = lamp.position.y + delta * 1.2
		if y > 32.0:
			y = 3.0
		lamp.position = Vector3(b.x, y, b.z)
	var t: float = _anim_t
	for i in range(_water.size()):
		var lamp: Node3D = _water[i] as Node3D
		var b: Vector3 = _water_base[i]
		lamp.position.y = b.y + sin(t * 1.3 + float(_water_phase[i])) * 0.06

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var g: int = _mindon_ground(world)
	var s: int = _shop_accents(world)
	var sc: int = _stall_post_lanterns(world, "StallCPost13_", "StallC", Color(0.25, 0.80, 1.0, 1.0), Color(1.0, 0.40, 0.65, 1.0))
	var sd: int = _stall_post_lanterns(world, "StallDPost_", "StallD", Color(1.0, 0.75, 0.25, 1.0), Color(0.45, 0.80, 1.0, 1.0))
	var h: int = _hamlet_festival(world)
	var w: int = _pond_lanterns(world)
	var m: int = _moon_halo(world)
	print("REALISM127 dressed: mindon_ground=", g, " shop_accents=", s, " stallC_lanterns=", sc, " stallD_lanterns=", sd, " hamlet_festival=", h, " pond_lanterns=", w, " moon_halo=", m)
