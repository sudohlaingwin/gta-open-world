extends Node3D
## Slice 124 — FIRST slice under the owner's goal
## "OpenTaxi Thadingyut Night level game graphic" (2026-10-26).
## BOUNDARY (binding): take ONLY the visual STANDARD from the
## reference video (dense warm night light, atmosphere, clean
## stylised geometry, smooth camera). NEVER copy OpenTaxi
## assets, branding, names, maps, layouts, or URLs; no club,
## no Yangon copy, no flying cars. The world stays
## village/Mindon/fields; the festival content here is
## ORIGINAL Thadingyut content for OUR world.
## AUDIT (audit124 + audit124b + audit124c, live headless,
## night forced to daylight 0, S123 dressing complete):
## - HEADLINE BUG, S120 change-gate ordering: realism100/101/
##   102/103/104 gate their night glows on night-state CHANGE
##   from frame 1, but their _apply runs at frames 180/200/
##   220/240/260 — the "first frame always runs" pass gates an
##   EMPTY list, then _apply creates the glows invisible and
##   the gate never re-runs until a daylight transition.
##   Measured at a fresh night load: Realism100 glows 38/0 +
##   dusk 5/0, Realism101 73/0, Realism102 94/0, Realism103
##   heads 49/0, Realism104 68/3. (Realism98 7/7, Realism99
##   6/6 and Night97 34/34 are FINE — they gate explicitly
##   right after _done, not from frame 1.) FIX (this slice,
##   5 small edits): force the gate on the _apply frame.
##   Fresh-load note, stated: the real game starts at time 0
##   (night) and daylight crosses 0.15 after ~29 s of play, so
##   on the phone the dark window is ~29 s (dusk glows ~89 s),
##   not permanent — but a fresh night load still opens dark,
##   and headless (no transition) reads dark forever.
## - ROUTE POOLS, AUDIT-CORRECTED: audit124's "81/81 gaps"
##   was a measurement artifact (it counted only VISIBLE
##   omnis; perf120 culls far lights by design). Counting ALL
##   164 omnis: z=-8 verge gaps 2/81, both single samples
##   already covered in 3D by the RouteMid omni — the route
##   is CONTINUOUS. NO new route pools (would be padding).
## - MINDON STREETS, REAL GAP: grid 12/21 with all omnis;
##   uncovered points (100,40) (100,60) (120,40) (120,60)
##   (140,60) (160,60) (200,60) (220,40) (220,60). FIX: 3
##   pools at (110,50) (150,70) (210,50), each within 22 m
##   of its cluster (max 14.2 m), clear of house footprints
##   (nearest wall clearance >= 0.8 m; (150,70) sits 10 m
##   north of MDHouse13's centre, not inside it).
## - DARK HOUSES, DISTINCT HOLDERS (Walls child criterion):
##   9 of 56 holders have no visible emissive mesh within
##   8 m: OoHouse1/2/3, MDHouse5/11/13/14, FishingHut19,
##   LakesideHut19. FIX: 4 windows each (both faces, so no
##   facing assumption), walls-AABB based, y guarded to
##   min(1.7, height*0.55) above the wall base.
## - FESTIVAL: Fireworks56 EXISTS and animates (Mindon sky
##   only, 3 clusters, 2 s cycle) — the brief's "no fireworks
##   system" was wrong for Mindon; what is MISSING is
##   fireworks anywhere else, plus SkyLantern 0, WaterLantern
##   0, OilLamp 0. FIX: fireworks extended to 3 more sites
##   (village, pagoda, hamlet) with rockets + bursts;
##   8 rising sky lanterns; 16 water lanterns on West
##   Pond97 (-350,0.05,r12) + Pond62A (300,-60,r6); 10 oil
##   lamps (6 stops + 4 House97 fronts, front +z known).
## - SKY: Moon17 visible, 8 Star17 dots only — sparse for a
##   festival night. FIX: +40 stars on a r35-45 dome (8 -> 48).
##   Moon glow NOT invented (no clean halo mesh; a plain
##   sphere would read as a second moon, not a glow).
## - COLOURED ACCENTS: 8 at audit. Firework bursts (gold /
##   pink / cyan), pink + cyan water/sky lanterns raise this
##   measurably without any club copy.
## PERFORMANCE NOTE: only 3 new OmniLight3Ds (Mindon pools);
## everything else is emissive MeshInstance3D (no light
## count growth). Names (Window124_/Pool124_/Lamp124_/
## Firework124_/SkyLantern124_/WaterLantern124_/Star124_)
## match NONE of perf120's hide prefixes. Zero colliders.
## Animation touches ONLY this node's own arrays (O(~90)),
## only at night; day hides everything and skips updates.
## Light visibility is written ONLY on night-state change
## (S120 composition: owner controls DAY/NIGHT state,
## perf120 controls DISTANCE state). Runs once at frame
## >= 660 (after Realism123's 640 pass, before Perf120's
## 720 scan, so the 3 pool omnis join its cache).

var _frames: int = 0
var _done: bool = false
var _gated: Array = []
var _last_night := false
var _gate_once := false
var _fw_t := 0.0
var _anim_t := 0.0
var _fw_sites: Array = []
var _sky: Array = []
var _sky_base: Array = []
var _water: Array = []
var _water_base: Array = []
var _water_phase: Array = []

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism124") != null:
		return
	var n := Node3D.new()
	n.name = "Realism124"
	n.set_script(load("res://realism124.gd"))
	world.call_deferred("add_child", n)

func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 660:
		_done = true
		_apply(get_parent() as Node3D)
	if not _done:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	var day := 1.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		day = float(dn.call("daylight"))
	var night := day < 0.15
	if not _gate_once or night != _last_night:
		_gate_once = true
		_last_night = night
		for g in _gated:
			var m := g as Node3D
			if m != null:
				m.visible = night
		if night:
			_fw_t = 0.0
	if night:
		_update_festival(delta)

static func _mat(c: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

static func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 1.0
	m.metallic = 0.0
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

func _find_walls(holder: Node3D) -> MeshInstance3D:
	for c in holder.get_children():
		if c is MeshInstance3D and String(c.name).contains("Walls"):
			return c as MeshInstance3D
	return null

func _ground_y(world: Node3D) -> float:
	var gm: Node3D = world.get_node_or_null("GroundMesh") as Node3D
	if gm != null:
		return gm.global_position.y
	return 0.0

func _windows(world: Node3D) -> int:
	var n := 0
	var warm := _glow_mat(Color(1.0, 0.75, 0.45, 1.0), 1.4)
	var targets: Array = ["OoHouse1", "OoHouse2", "OoHouse3",
		"MDHouse5", "MDHouse11", "MDHouse13", "MDHouse14",
		"FishingHut19", "LakesideHut19"]
	var stack: Array = [world]
	var holders := {}
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		if x is Node3D and targets.has(String(x.name)):
			holders[String(x.name)] = x
	for tag in targets:
		if not holders.has(tag):
			continue
		var holder: Node3D = holders[tag]
		var walls := _find_walls(holder)
		if walls == null or walls.mesh == null:
			continue
		var ws: Vector3 = walls.mesh.get_aabb().size
		var wp: Vector3 = walls.position
		var base_y := wp.y - ws.y * 0.5
		var wy := base_y + minf(1.7, ws.y * 0.55)
		for face in [1.0, -1.0]:
			for sx in [-0.22, 0.22]:
				var w := _box(holder, Vector3(0.7, 0.9, 0.06), warm,
					Vector3(wp.x + sx * ws.x, wy, wp.z + face * (ws.z * 0.5 + 0.05)),
					"Window124_%s_%d_%d" % [tag, 1 if face > 0.0 else 0, 1 if sx > 0.0 else 0])
				w.visible = false
				_gated.append(w)
				n += 1
	return n

func _pools(world: Node3D) -> int:
	var n := 0
	var gy := _ground_y(world)
	var pole := _mat(Color(0.25, 0.25, 0.25, 1.0), 0.8)
	var head_mat := _glow_mat(Color(1.0, 0.75, 0.45, 1.0), 1.4)
	var sites: Array = [Vector3(110.0, 0.0, 50.0), Vector3(150.0, 0.0, 70.0), Vector3(210.0, 0.0, 50.0)]
	for i in range(sites.size()):
		var s: Vector3 = sites[i]
		_box(world, Vector3(0.12, 3.0, 0.12), pole, Vector3(s.x, gy + 1.5, s.z), "Pool124_Pole%d" % i)
		var head := _box(world, Vector3(0.20, 0.12, 0.20), head_mat, Vector3(s.x, gy + 3.05, s.z), "Pool124_Head%d" % i)
		head.visible = false
		_gated.append(head)
		var om := OmniLight3D.new()
		om.name = "Pool124_Omni%d" % i
		om.light_color = Color(1.0, 0.75, 0.45, 1.0)
		om.light_energy = 1.5
		om.omni_range = 22.0
		om.shadow_enabled = false
		om.position = Vector3(s.x, gy + 3.0, s.z)
		om.visible = false
		world.add_child(om)
		_gated.append(om)
		n += 1
	return n

func _oil_lamps(world: Node3D) -> int:
	var n := 0
	var gy := _ground_y(world)
	var lamp_mat := _glow_mat(Color(1.0, 0.70, 0.30, 1.0), 1.6)
	for i in range(6):
		var s: Node3D = world.get_node_or_null("LongRoute74/BusStop74_%d" % i) as Node3D
		if s == null:
			continue
		var p: Vector3 = s.global_position
		var lamp := _box(world, Vector3(0.25, 0.30, 0.25), lamp_mat,
			Vector3(p.x + 1.5, gy + 0.35, p.z), "Lamp124_Stop%d" % i)
		lamp.visible = false
		_gated.append(lamp)
		n += 1
	for hi in range(1, 5):
		var h: Node3D = world.get_node_or_null("House97_%d" % hi) as Node3D
		if h == null:
			continue
		var g: MeshInstance3D = h.get_node_or_null("Ground97") as MeshInstance3D
		if g == null or g.mesh == null:
			continue
		var gs: Vector3 = g.mesh.get_aabb().size
		var gp: Vector3 = g.position
		var lamp := _box(h, Vector3(0.25, 0.30, 0.25), lamp_mat,
			Vector3(gp.x, 0.35, gp.z + gs.z * 0.5 + 0.35), "Lamp124_House97_%d" % hi)
		lamp.visible = false
		_gated.append(lamp)
		n += 1
	return n

func _fireworks(world: Node3D) -> int:
	var gy := _ground_y(world)
	# Pagoda site offset to (122,-72): the pagoda itself stands
	# at (108,-62), so a rocket from its exact centre would
	# clip through the tiers; 17.2 m clear of the centre.
	var sites: Array = [Vector3(0.0, 0.0, 0.0), Vector3(122.0, 0.0, -72.0), Vector3(2100.0, 0.0, 88.0)]
	var cols: Array = [Color(1.0, 0.85, 0.25, 1.0), Color(1.0, 0.35, 0.55, 1.0), Color(0.25, 0.65, 1.0, 1.0)]
	for si in range(sites.size()):
		var s: Vector3 = sites[si]
		var holder := Node3D.new()
		holder.name = "Firework124_Site%d" % si
		holder.position = Vector3(s.x, gy, s.z)
		world.add_child(holder)
		var rocket := _sphere(holder, 0.25, _glow_mat(Color(1.0, 0.95, 0.8, 1.0), 2.0),
			Vector3(0.0, 1.0, 0.0), "Firework124_Rocket%d" % si)
		rocket.visible = false
		_gated.append(rocket)
		var burst := Node3D.new()
		burst.name = "Firework124_Burst%d" % si
		burst.position = Vector3(0.0, 14.0, 0.0)
		holder.add_child(burst)
		for k in range(8):
			var ang := float(k) * 0.7854
			var sp := _sphere(burst, 0.30, _glow_mat(cols[si], 2.0),
				Vector3(cos(ang) * 2.5, sin(ang * 2.0) * 1.0, sin(ang) * 2.5),
				"Firework124_Spark%d_%d" % [si, k])
			sp.visible = false
			_gated.append(sp)
		_fw_sites.append({"rocket": rocket, "burst": burst})
	return sites.size()

func _sky_lanterns(world: Node3D) -> int:
	var bases: Array = [Vector3(-15.0, 0.0, -10.0), Vector3(15.0, 0.0, -12.0),
		Vector3(-10.0, 0.0, 15.0), Vector3(18.0, 0.0, 10.0),
		Vector3(135.0, 0.0, 30.0), Vector3(165.0, 0.0, 28.0),
		Vector3(140.0, 0.0, 55.0), Vector3(170.0, 0.0, 52.0)]
	var warm := _glow_mat(Color(1.0, 0.65, 0.25, 1.0), 1.8)
	var pink := _glow_mat(Color(1.0, 0.45, 0.60, 1.0), 1.8)
	var cyan := _glow_mat(Color(0.45, 0.80, 1.0, 1.0), 1.8)
	for i in range(bases.size()):
		var b: Vector3 = bases[i]
		var m: StandardMaterial3D = warm
		if i == 3:
			m = pink
		elif i == 7:
			m = cyan
		var lamp := _box(world, Vector3(0.45, 0.60, 0.45), m,
			Vector3(b.x, 3.0 + float(i) * 3.5, b.z), "SkyLantern124_%d" % i)
		lamp.visible = false
		_gated.append(lamp)
		_sky.append(lamp)
		_sky_base.append(b)
	return bases.size()

func _water_lanterns(world: Node3D) -> int:
	var n := 0
	var gold := _glow_mat(Color(1.0, 0.70, 0.30, 1.0), 1.6)
	var pink := _glow_mat(Color(1.0, 0.45, 0.60, 1.0), 1.6)
	var cyan := _glow_mat(Color(0.45, 0.80, 1.0, 1.0), 1.6)
	var ponds: Array = [[Vector3(-350.0, 0.0, 0.0), 10], [Vector3(300.0, 0.0, -60.0), 6]]
	for pi in range(ponds.size()):
		var pc: Vector3 = ponds[pi][0]
		var cnt: int = ponds[pi][1]
		for k in range(cnt):
			var ang := float(k) * 0.6283 + float(pi) * 0.5
			var r := 4.0 + float(k % 3) * 2.5 if pi == 0 else 2.0 + float(k % 2) * 2.0
			var m: StandardMaterial3D = gold
			if k % 4 == 1:
				m = pink
			elif k % 4 == 3:
				m = cyan
			var lamp := _box(world, Vector3(0.40, 0.25, 0.40), m,
				Vector3(pc.x + cos(ang) * r, 0.30, pc.z + sin(ang) * r),
				"WaterLantern124_%d_%d" % [pi, k])
			lamp.visible = false
			_gated.append(lamp)
			_water.append(lamp)
			_water_base.append(Vector3(pc.x + cos(ang) * r, 0.30, pc.z + sin(ang) * r))
			_water_phase.append(float(k) * 0.9)
			n += 1
	return n

func _stars(world: Node3D) -> int:
	var n := 0
	var star_mat := _glow_mat(Color(0.85, 0.90, 1.0, 1.0), 1.5)
	var moon := Vector3(-30.0, 25.0, -40.0)
	for i in range(40):
		var ang := float(i) * 2.399963
		var rad := 35.0 + float(i % 5) * 2.0
		var pos := Vector3(cos(ang) * rad, 18.0 + float(i % 7) * 3.0, sin(ang) * rad)
		if pos.distance_to(moon) < 8.0:
			pos = Vector3(cos(ang + 0.5) * rad, 18.0 + float(i % 7) * 3.0, sin(ang + 0.5) * rad)
		var st := _sphere(world, 0.30, star_mat, pos, "Star124_%d" % i)
		st.visible = false
		_gated.append(st)
		n += 1
	return n

func _update_festival(delta: float) -> void:
	_anim_t += delta
	_fw_t += delta
	var cycle := 7.5
	var t := fmod(_fw_t, cycle)
	var active := int(t / 2.5) % 3
	var local := fmod(t, 2.5)
	for si in range(_fw_sites.size()):
		var site: Dictionary = _fw_sites[si]
		var rocket := site["rocket"] as Node3D
		var burst := site["burst"] as Node3D
		if si == active:
			if local < 1.2:
				rocket.visible = true
				rocket.position.y = 1.0 + (local / 1.2) * 13.0
				burst.visible = false
			elif local < 2.2:
				rocket.visible = false
				burst.visible = true
				var s := 1.0 + sin(_anim_t * 3.0) * 0.25
				burst.scale = Vector3(s, s, s)
			else:
				rocket.visible = false
				burst.visible = false
		else:
			rocket.visible = false
			burst.visible = false
	for i in range(_sky.size()):
		var lamp := _sky[i] as Node3D
		var b: Vector3 = _sky_base[i]
		var y := lamp.position.y + delta * 1.2
		if y > 32.0:
			y = 3.0
		lamp.position = Vector3(b.x, y, b.z)
	for i in range(_water.size()):
		var lamp := _water[i] as Node3D
		var b: Vector3 = _water_base[i]
		lamp.position.y = b.y + sin(_anim_t * 1.3 + _water_phase[i]) * 0.06

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var w := _windows(world)
	var p := _pools(world)
	var o := _oil_lamps(world)
	var f := _fireworks(world)
	var s := _sky_lanterns(world)
	var wl := _water_lanterns(world)
	var st := _stars(world)
	print("REALISM124 dressed: windows=", w, " pools=", p, " oil_lamps=", o, " fw_sites=", f, " sky_lanterns=", s, " water_lanterns=", wl, " stars=", st)
