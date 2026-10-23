extends Node3D
## Slice 73 — graphics realism pass, part 4 (owner order 2026-10-23
## 06:32, binding: graphics FIRST, no new feature). Slices 70-72 did
## houses/people/ground/lighting + trees/vehicles/water/pagoda +
## animals/buildings/roads/sky; this round does the next most visible
## toy-looking elements, all procedural, own work, no external
## assets, no copied opponent shaders, no scanned texture claimed.
## Runtime-only: no scene file is touched, no positions moved, no
## colliders added, no gameplay code changed, no new feature/quest/
## sign/label/system.
## - CLOTHING + FACES: shirt sleeves on every shoulder pivot,
##   longyi waist/hem bands + pattern stripes (torus rings, so no
##   cap-disc artefacts), straw-hat brims on existing hats, simple
##   eyes on every head front (forward is local +z: npc.gd and
##   player.gd both rotate with atan2(dir.x, dir.z), which maps +z
##   onto the movement direction), hair buns on a deterministic
##   third of villagers. Sandals already exist (Sandal58) and are
##   NOT duplicated.
## - INTERIORS GLIMPSE (visual only, nothing enterable): tea cups
##   on the tea-shop table (table top is exactly y 0.825: box
##   3.6x0.15x2.0 at y 0.75), ground baskets + produce beside the
##   two village stall counters, a zayat altar table + candles
##   with emissive tips + flower bowl (deck top is exactly
##   y 0.775: box 8.5x0.35x6.5 at y 0.6).
## - NIGHT: 4 warm OmniLights (tea shop, market, zayat, night
##   market) + 2 emissive school window-glow planes, all gated by
##   the same rule as the rest of the game (DayNight.daylight <
##   0.15). Sun energy, colours, Slice 61 night floor (0.35) and
##   season tints are NOT touched.
## Capture runs once at frame >= 26, after Slice 72's frame-20
## capture; _process then stays alive ONLY for the night toggle
## (one DayNight call per frame, visibility/energy flips only
## when night actually changes).

var _frames: int = 0
var _captured: bool = false
var _night_lights: Array = []
var _night_glows: Array = []
var _night_visible: bool = false


static func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


static func _glow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.80, 0.45, 1.0)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.70, 0.30, 1.0)
	m.emission_energy_multiplier = 1.6
	return m


static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = pos
	m.rotation = rot
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _sphere(parent: Node3D, radius: float, mat: Material, pos: Vector3, nm: String, sy: float = 1.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	m.mesh = sm
	m.scale = Vector3(1.0, sy, 1.0)
	m.position = pos
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	m.mesh = cm
	m.position = pos
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _torus(parent: Node3D, inner_r: float, outer_r: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var tm := TorusMesh.new()
	tm.inner_radius = inner_r
	tm.outer_radius = outer_r
	tm.rings = 16
	tm.ring_segments = 32
	m.mesh = tm
	m.position = pos
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _hash01(nm: String) -> int:
	var h := 0
	for i in range(nm.length()):
		h = (h * 31 + nm.unicode_at(i)) % 1000
	return h


static func _override0(mi: MeshInstance3D) -> Material:
	if mi == null or mi.get_surface_override_material_count() <= 0:
		return null
	return mi.get_surface_override_material(0)


func _apply_night(night: bool) -> void:
	_night_visible = night
	for l in _night_lights:
		(l as OmniLight3D).light_energy = 1.4 if night else 0.0
	for g in _night_glows:
		(g as Node3D).visible = night


func _capture(world: Node3D) -> void:
	_captured = true
	var skin := _mat(Color(0.72, 0.55, 0.40, 1.0), 0.8)
	var dark := _mat(Color(0.15, 0.12, 0.10, 1.0), 0.9)
	var white := _mat(Color(0.96, 0.94, 0.88, 1.0), 0.7)
	var gold := _mat(Color(0.85, 0.65, 0.25, 1.0), 0.6)
	var straw := _mat(Color(0.82, 0.72, 0.45, 1.0), 0.9)
	var wood := _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	var ceramic := _mat(Color(0.95, 0.95, 0.97, 1.0), 0.3)
	var fruit_a := _mat(Color(0.95, 0.55, 0.15, 1.0), 0.7)
	var fruit_b := _mat(Color(0.30, 0.65, 0.25, 1.0), 0.7)
	var glow := _glow_mat()
	var bodies: Array = []
	for child in world.get_children():
		if child is CharacterBody3D and (String(child.name) == "Player" or String(child.name).begins_with("Villager")):
			bodies.append(child)
	for body in bodies:
		var b := body as Node3D
		var is_player := String(b.name) == "Player"
		var torso := b.get_node_or_null("Torso") as MeshInstance3D
		var shirt: Material = null
		if torso != null:
			shirt = _override0(torso)
		if shirt == null:
			shirt = white
		for side in ["R", "L"]:
			var piv := b.get_node_or_null("ShoulderPivot58_" + side) as Node3D
			if piv != null:
				_box(piv, Vector3(0.19, 0.20, 0.19), shirt, Vector3(0.0, -0.05, 0.0), "Sleeve73_" + side)
		var lpiv := b.get_node_or_null("LongyiPivot58") as Node3D
		if lpiv != null:
			_torus(lpiv, 0.275, 0.30, dark, Vector3(0.0, -0.04, 0.0), "LongyiWaist73")
			_torus(lpiv, 0.29, 0.315, gold, Vector3(0.0, -0.30, 0.0), "LongyiStripe73_A")
			_torus(lpiv, 0.295, 0.32, white, Vector3(0.0, -0.60, 0.0), "LongyiStripe73_B")
			_torus(lpiv, 0.295, 0.325, dark, Vector3(0.0, -0.86, 0.0), "LongyiHem73")
		var hat := b.get_node_or_null("Hat58") as MeshInstance3D
		if hat != null:
			var hmat: Material = _override0(hat)
			if hmat == null:
				hmat = straw
			_cyl(b, 0.55, 0.55, 0.02, hmat, Vector3(0.0, 0.92, 0.0), "HatBrim73")
		_sphere(b, 0.028, dark, Vector3(-0.07, 0.74, 0.185), "Eye73_L")
		_sphere(b, 0.028, dark, Vector3(0.07, 0.74, 0.185), "Eye73_R")
		if not is_player and _hash01(String(b.name)) % 3 == 0:
			var hair := b.get_node_or_null("Hair58") as MeshInstance3D
			var hmat2: Material = null
			if hair != null:
				hmat2 = _override0(hair)
			if hmat2 == null:
				hmat2 = dark
			_sphere(b, 0.09, hmat2, Vector3(0.0, 0.88, -0.19), "HairBun73")
	var tea := world.get_node_or_null("TeaShop13") as Node3D
	if tea != null:
		for cx in [-0.9, 0.9]:
			for cz in [-0.5, 0.5]:
				_cyl(tea, 0.05, 0.04, 0.09, ceramic, Vector3(cx, 0.87, cz), "TeaCup73_%d_%d" % [int(cx * 10.0), int(cz * 10.0)])
	for site in [Vector3(-7.6, 0.0, 2.0), Vector3(-7.6, 0.0, 6.0)]:
		_cyl(world, 0.28, 0.22, 0.30, wood, Vector3(site.x, 0.15, site.z), "MarketBasket73_%d" % int(site.z))
		_sphere(world, 0.11, fruit_a, Vector3(site.x - 0.10, 0.36, site.z), "MarketGoods73_%d_A" % int(site.z))
		_sphere(world, 0.11, fruit_b, Vector3(site.x + 0.12, 0.36, site.z + 0.05), "MarketGoods73_%d_B" % int(site.z))
		_sphere(world, 0.11, fruit_a, Vector3(site.x, 0.36, site.z - 0.12), "MarketGoods73_%d_C" % int(site.z))
	var zayat := world.get_node_or_null("Zayat") as Node3D
	if zayat != null:
		_box(zayat, Vector3(1.6, 0.10, 0.70), wood, Vector3(0.0, 1.10, -2.0), "AltarTable73")
		_box(zayat, Vector3(0.10, 0.30, 0.10), wood, Vector3(-0.70, 0.925, -2.0), "AltarLeg73_L")
		_box(zayat, Vector3(0.10, 0.30, 0.10), wood, Vector3(0.70, 0.925, -2.0), "AltarLeg73_R")
		for cx in [-0.5, 0.5]:
			_cyl(zayat, 0.03, 0.03, 0.16, white, Vector3(cx, 1.23, -2.0), "AltarCandle73_%d" % int(cx * 10.0))
			_sphere(zayat, 0.035, glow, Vector3(cx, 1.33, -2.0), "CandleFlame73_%d" % int(cx * 10.0))
		_sphere(zayat, 0.18, ceramic, Vector3(0.0, 1.24, -1.50), "FlowerBowl73", 0.6)
		for fi in 3:
			var fx: float = [-0.12, 0.0, 0.12][fi]
			_sphere(zayat, 0.06, fruit_b if fi != 1 else fruit_a, Vector3(fx, 1.34, -1.50), "AltarFlower73_%d" % fi)
	var school := world.get_node_or_null("School13") as Node3D
	if school != null:
		for gx in [-1.5, 1.5]:
			var plane := MeshInstance3D.new()
			plane.name = "WindowGlow73_%d" % int(gx * 10.0)
			var pm := PlaneMesh.new()
			pm.size = Vector2(1.0, 0.80)
			plane.mesh = pm
			plane.position = Vector3(gx, 1.70, 3.12)
			plane.rotation = Vector3(PI / 2.0, 0.0, 0.0)
			plane.set_surface_override_material(0, glow)
			plane.visible = false
			school.add_child(plane)
			_night_glows.append(plane)
	for spot in [Vector3(-14.0, 2.5, 20.0), Vector3(16.0, 2.5, 12.0), Vector3(28.0, 3.0, 2.0), Vector3(-36.0, 2.5, 32.0)]:
		var light := OmniLight3D.new()
		light.name = "NightLight73_%d_%d" % [int(spot.x), int(spot.z)]
		light.position = spot
		light.light_color = Color(1.0, 0.75, 0.45, 1.0)
		light.light_energy = 0.0
		light.omni_range = 9.0
		light.omni_attenuation = 1.0
		world.add_child(light)
		_night_lights.append(light)


func _process(_delta: float) -> void:
	_frames += 1
	if not _captured:
		if _frames < 26:
			return
		var world := get_parent() as Node3D
		if world == null:
			return
		_capture(world)
		return
	var dn := get_parent().get_node_or_null("DayNight") if get_parent() != null else null
	var night := false
	if dn != null and dn.has_method("daylight"):
		night = float(dn.call("daylight")) < 0.15
	if night != _night_visible:
		_apply_night(night)
