extends Node3D
## Slice 129 — DAYLIGHT GRAPHICS ROUND, AUDIT-FIRST, under the
## owner's goal "OpenTaxi Thadingyut Night level game graphic".
## BOUNDARY (binding): take ONLY the visual STANDARD from the
## reference video. NEVER copy OpenTaxi assets, branding,
## names, maps, layouts, or URLs; no club, no Yangon copy, no
## flying cars. World stays village/Mindon/fields. Festival
## dressing below is ORIGINAL Thadingyut content (bunting +
## clouds), not a copy of any reference shot.
## DAY AUDIT (audit129, live headless, S128 dressing complete,
## DayNight.time = 300 -> daylight 0.99999):
## - DAY SKY, CORRECTION: WorldEnvironment56 EXISTS at
##   runtime (city_visual56.dress creates it with a
##   ProceduralSkyMaterial gradient; S120's "no
##   WorldEnvironment" was scene-file true, runtime
##   false). Sun: SunLight energy 1.20, warm white
##   (1, 0.96, 0.86), shadow_enabled = TRUE in main.tscn
##   (line ~1507) — the "no shadows" day gap is
##   DISPROVED, sun shadows already exist. Sky: top
##   (0.30, 0.56, 0.82), horizon (0.70, 0.79, 0.86),
##   sun_angle_max 30, sky_energy 1, fog/glow/SSAO off.
##   REAL GAP: clouds = 3 ONLY (Cloud56_0..2, all near
##   village spawn x -39..81, z -60..-20, y 42) — the
##   sky over Mindon, hamlet, the route, and the pagoda
##   is EMPTY gradient. 12 district clouds shipped.
## - DAY BUILDING READ: NO GAP. Every sampled holder
##   carries 5-23 distinct colours (House97_1/2: 5,
##   MDHouse4/5/11: 8-9, HamletHouse75_0: 12, OoHouse1:
##   7, House6: 10, School13: 23, DepotOffice82: 8,
##   MindonShops: 14, FishingHut19: 3, LakesideHut19:
##   7, StiltHouse13: 9), roofs 2-3 colours each, trims
##   complete (Trim122 59, Trim123 40, Trim128 5).
##   Stilt97/CityBlock56 "MISSING" in the audit is a
##   NAME miss (Stilt97_5 etc. per S128's gate), not a
##   gap. No new trim shipped (would be padding).
## - DAY FESTIVAL: REAL GAP. Flags 18 exist, but
##   Banners 0, Bunting 0, Awnings 3 against 44 stalls
##   — the market/village does NOT read as festival-
##   ready in daylight (night festival is lanterns +
##   fireworks, S124/S127). 5 bunting strings shipped:
##   village plaza x2, market row x2, Mindon shops
##   front x1 (shopfront derived from the live
##   Accent127_Shop_Strip global position + the
##   MindonShops global front normal — the S127
##   scale-aware pattern, never a guessed offset).
## - GROUND: complete (S128) — Ground122 39 + Ground123
##   54 + Ground127 16 + Ground128 14, all visible at
##   day. No new ground shipped.
## - NIGHT BASELINE (time = 900): Ground127 16/16,
##   Accent127 7/7, SkyLantern127 4/4, WaterLantern127
##   14/14, Lamp127 4/4, Halo127 1/1, Moon17 visible.
##   S129's items are DAY-GATED (visible only when
##   daylight >= 0.15, flipped on state CHANGE only,
##   S120's gate pattern) so night stays EXACTLY S127.
## PERFORMANCE: ZERO new OmniLight3Ds, ZERO colliders,
## ZERO per-frame tree walks (the gate is one
## daylight() call + one comparison per frame, and
## writes visibility only on a day/night transition).
## Names (Cloud129_/Pole129_/Pennant129_/Cord129_/
## Flag129_) match NONE of perf120's hide prefixes
## (Blade93_/94_/95_/110_, Reed57_/62/107_/108_).
## Single pass at frame >= 740 (after Realism128's
## 730), with a holders-ready retry gate (Ground122_
## plaza + Accent127_Shop_Strip must exist, so a
## fast-forward ordering quirk can never strand the
## Mindon string or the plaza strings).

var _frames: int = 0
var _done: bool = false
var _was_dark: Variant = null
var _day_items: Array = []

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism129") != null:
		return
	var n: Node3D = Node3D.new()
	n.name = "Realism129"
	n.set_script(load("res://realism129.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 740:
		var w: Node3D = get_parent() as Node3D
		if _holders_ready(w):
			_done = true
			_apply(w)
	if _done:
		var w2: Node3D = get_parent() as Node3D
		if w2 != null:
			var dn: Node = w2.get_node_or_null("DayNight")
			if dn != null and dn.has_method("daylight"):
				var dark: bool = float(dn.call("daylight")) < 0.15
				if _was_dark == null:
					_was_dark = dark
					for it in _day_items:
						(it as Node3D).visible = not dark
				elif bool(_was_dark) != dark:
					_was_dark = dark
					for it in _day_items:
						(it as Node3D).visible = not dark

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

func _holders_ready(world: Node3D) -> bool:
	if world == null:
		return false
	if _find_recursive(world, "Ground122_plaza") == null:
		return false
	if _find_recursive(world, "Accent127_Shop_Strip") == null:
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

func _pole_clear(walls: Array, x: float, z: float, dist: float) -> bool:
	for w in walls:
		var wp: Vector3 = w
		if Vector2(wp.x - x, wp.z - z).length() <= dist:
			return false
	return true

func _cord(parent: Node, a: Vector3, b: Vector3, nm: String) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = d.length()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(0.03, 0.03, ln)
	mi.mesh = bm
	mi.set_surface_override_material(0, _mat(Color(0.20, 0.16, 0.12)))
	mi.position = (a + b) * 0.5
	mi.basis = Basis.looking_at(d.normalized(), Vector3.UP)
	parent.add_child(mi)
	return mi

func _flag_at(parent: Node, p: Vector3, yaw: float, col: Color, nm: String) -> MeshInstance3D:
	var mi: MeshInstance3D = _box(parent, Vector3(0.18, 0.25, 0.02), _mat(col), Vector3(p.x, p.y - 0.13, p.z), nm)
	mi.rotation.y = yaw
	return mi

func _string(world: Node3D, a: Vector3, b: Vector3, tag: String, sidx: int) -> int:
	var m1: Vector3 = a.lerp(b, 0.3333) + Vector3(0.0, -0.25, 0.0)
	var m2: Vector3 = a.lerp(b, 0.6667) + Vector3(0.0, -0.35, 0.0)
	var pts: Array = [a, m1, m2, b]
	var n: int = 0
	for i in range(3):
		var seg: MeshInstance3D = _cord(world, pts[i], pts[i + 1], "Cord129_%s_%d" % [tag, i])
		_day_items.append(seg)
		n += 1
	var horiz: Vector2 = Vector2(b.x - a.x, b.z - a.z)
	var yaw: float = atan2(-horiz.y, horiz.x)
	var palette: Array = [Color(1.0, 0.75, 0.25), Color(1.0, 0.40, 0.65), Color(0.25, 0.80, 1.0), Color(1.0, 0.96, 0.86)]
	for fi in range(7):
		var t: float = (float(fi) + 1.0) / 8.0
		var segf: float = t * 3.0
		var si: int = int(segf)
		if si > 2:
			si = 2
		var lt: float = segf - float(si)
		var p: Vector3 = (pts[si] as Vector3).lerp(pts[si + 1] as Vector3, lt)
		var col: Color = palette[(sidx * 7 + fi) % 4]
		var fl: MeshInstance3D = _flag_at(world, p, yaw, col, "Flag129_%s_%d" % [tag, fi])
		_day_items.append(fl)
		n += 1
	return n

func _pole(world: Node3D, x: float, z: float, gy: float, yaw: float, tag: String) -> int:
	var red: StandardMaterial3D = _mat(Color(0.75, 0.15, 0.15))
	var gold: StandardMaterial3D = _mat(Color(1.0, 0.75, 0.25))
	var p: MeshInstance3D = _box(world, Vector3(0.12, 3.2, 0.12), red, Vector3(x, gy + 1.6, z), "Pole129_%s" % tag)
	_day_items.append(p)
	var pen: MeshInstance3D = _box(world, Vector3(0.55, 0.32, 0.02), gold, Vector3(x, gy + 3.05, z), "Pennant129_%s" % tag)
	pen.rotation.y = yaw
	_day_items.append(pen)
	return 2

func _clouds(world: Node3D) -> int:
	var defs: Array = [
		[Vector3(-100.0, 42.0, 30.0), 6.0, Vector3(2.0, 0.5, 1.0)],
		[Vector3(150.0, 42.0, 0.0), 5.5, Vector3(2.2, 0.45, 1.0)],
		[Vector3(200.0, 42.0, 60.0), 6.5, Vector3(1.8, 0.55, 1.1)],
		[Vector3(108.0, 42.0, -90.0), 6.0, Vector3(2.4, 0.4, 0.9)],
		[Vector3(800.0, 42.0, -40.0), 7.0, Vector3(2.0, 0.5, 1.0)],
		[Vector3(1200.0, 42.0, 20.0), 5.0, Vector3(2.2, 0.6, 1.0)],
		[Vector3(1600.0, 42.0, -30.0), 6.5, Vector3(1.9, 0.45, 1.1)],
		[Vector3(2000.0, 42.0, 40.0), 5.5, Vector3(2.3, 0.5, 0.9)],
		[Vector3(2080.0, 42.0, 70.0), 6.0, Vector3(2.0, 0.55, 1.0)],
		[Vector3(2130.0, 42.0, 110.0), 6.5, Vector3(2.1, 0.4, 1.0)],
		[Vector3(450.0, 42.0, -120.0), 7.0, Vector3(2.0, 0.5, 1.1)],
		[Vector3(600.0, 42.0, 120.0), 5.5, Vector3(2.4, 0.45, 0.9)],
	]
	var cm: StandardMaterial3D = _mat(Color(1.0, 1.0, 1.0, 0.9))
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var n: int = 0
	for i in range(defs.size()):
		var def: Array = defs[i]
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "Cloud129_%d" % i
		var sm: SphereMesh = SphereMesh.new()
		sm.radius = float(def[1])
		sm.height = 3.0
		mi.mesh = sm
		mi.set_surface_override_material(0, cm)
		mi.position = def[0]
		mi.scale = def[2]
		world.add_child(mi)
		_day_items.append(mi)
		n += 1
	return n

func _apply(world: Node3D) -> void:
	var gy: float = _ground_y(world)
	var walls: Array = _walls_centres(world)
	var total: int = 0
	total += _clouds(world)
	var plaza: Node3D = _find_recursive(world, "Ground122_plaza") as Node3D
	if plaza != null:
		var cp: Vector3 = plaza.global_position
		var pp: Array = [
			[cp.x - 7.0, cp.z - 4.0, "PlazaNW"], [cp.x + 7.0, cp.z - 4.0, "PlazaNE"],
			[cp.x - 7.0, cp.z + 4.0, "PlazaSW"], [cp.x + 7.0, cp.z + 4.0, "PlazaSE"],
		]
		var ok: Dictionary = {}
		for pd in pp:
			var px: float = float(pd[0])
			var pz: float = float(pd[1])
			var tag: String = String(pd[2])
			if _pole_clear(walls, px, pz, 2.5):
				total += _pole(world, px, pz, gy, 0.0, tag)
				ok[tag] = true
		if bool(ok.get("PlazaNW", false)) and bool(ok.get("PlazaNE", false)):
			total += _string(world, Vector3(cp.x - 7.0, gy + 3.0, cp.z - 4.0), Vector3(cp.x + 7.0, gy + 3.0, cp.z - 4.0), "PlazaN", 0)
		if bool(ok.get("PlazaSW", false)) and bool(ok.get("PlazaSE", false)):
			total += _string(world, Vector3(cp.x - 7.0, gy + 3.0, cp.z + 4.0), Vector3(cp.x + 7.0, gy + 3.0, cp.z + 4.0), "PlazaS", 1)
	var mp: Array = [
		[8.0, 18.0, "MarketNW"], [26.0, 18.0, "MarketNE"],
		[8.0, 10.0, "MarketSW"], [26.0, 10.0, "MarketSE"],
	]
	var mok: Dictionary = {}
	for md in mp:
		var mx: float = float(md[0])
		var mz: float = float(md[1])
		var mtag: String = String(md[2])
		if _pole_clear(walls, mx, mz, 2.5):
			total += _pole(world, mx, mz, gy, 0.0, mtag)
			mok[mtag] = true
	if bool(mok.get("MarketNW", false)) and bool(mok.get("MarketNE", false)):
		total += _string(world, Vector3(8.0, gy + 3.0, 18.0), Vector3(26.0, gy + 3.0, 18.0), "MarketN", 2)
	if bool(mok.get("MarketSW", false)) and bool(mok.get("MarketSE", false)):
		total += _string(world, Vector3(8.0, gy + 3.0, 10.0), Vector3(26.0, gy + 3.0, 10.0), "MarketS", 3)
	var strip: Node3D = _find_recursive(world, "Accent127_Shop_Strip") as Node3D
	var shops: Node3D = _find_recursive(world, "MindonShops") as Node3D
	if strip != null and shops != null:
		var sp: Vector3 = strip.global_position
		var nrm: Vector3 = (shops.global_transform.basis * Vector3(0.0, 0.0, 1.0))
		nrm.y = 0.0
		if nrm.length() > 0.01:
			nrm = nrm.normalized()
			var tang: Vector3 = Vector3(0.0, 1.0, 0.0).cross(nrm).normalized()
			var ax: Vector3 = sp - tang * 7.0 + nrm * 1.5
			var bx: Vector3 = sp + tang * 7.0 + nrm * 1.5
			total += _pole(world, ax.x, ax.z, gy, atan2(-tang.z, tang.x), "ShopsW")
			total += _pole(world, bx.x, bx.z, gy, atan2(-tang.z, tang.x), "ShopsE")
			total += _string(world, Vector3(ax.x, gy + 3.0, ax.z), Vector3(bx.x, gy + 3.0, bx.z), "Shops", 4)
	var dn: Node = world.get_node_or_null("DayNight")
	var day: bool = true
	if dn != null and dn.has_method("daylight"):
		day = float(dn.call("daylight")) >= 0.15
	_was_dark = not day
	for it in _day_items:
		(it as Node3D).visible = day
	print("Realism129 applied items=", total, " day_items=", _day_items.size(), " day_now=", day)
