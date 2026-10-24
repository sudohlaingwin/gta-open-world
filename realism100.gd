extends Node3D
## Slice 99 MINDON 2-STOREY CONVERSION + FINE BUILDING DETAIL + OPENTAXI-LOOK
## NIGHT PASS + PLAYER NIGHT LIGHT (owner standing rules: ~50 items per push,
## graphics-first; owner clarification 2026-10-23 ~22:46: the BUILDING MODELS
## themselves must carry fine detail as GEOMETRY, whole buildings finished, not
## thin detail spread everywhere).
## Audit-first batch: every item below was grep/probe-proven missing or wrong.
## Mindon district buildings (S59 boxes, S96 x1.8) are SINGLE-storey slabs
## with flat walls, no frames, no cornice, no plinth, no steps — and their
## layer-1 Solids were NEVER scaled by S96 (S96 scaled only the groups and
## the layer-2 CamBlocks), so the player can walk THROUGH the visible Mindon
## walls up to 1.75 m before hitting the small inner solid (Post solid
## 6x3x5 vs visible walls 10.2x4.76x8.5). S99 fixes that as part of the
## conversion: every Mindon building gains a genuine second storey (upper
## walls + windows + floor band + new pitched roof; the old single roof is
## hidden at runtime, no scene edit), a front balcony with rails and an
## upper door, full window frames + sills on both floors and both faces,
## pilasters, cornice + eaves bands, plinth, door frame + steps — and a
## REPLACED layer-1 solid sized to the new envelope (individual BoxShape3D
## per building; the shared S59 resources are never mutated) plus a
## height-extended CamBlock so the camera cannot clip the upper floor.
## Village House97 rebuilds (already 2-storey) gain frames + sills on both
## faces (their backs had NO windows at all), corner boards, eaves band,
## plinth, door frame + steps, and a widened solid. East Fields stilt
## houses (S62, x1.5) gain window bars + sills, back windows + frames,
## cornice bands, plinth, door frame, veranda rails and entry steps, and
## a widened solid. People: females had NO waistband (males got Waist99 in
## S98) — female A x4 purple, female B x5 pink. Car: no antenna, no
## wipers. Night (OpenTaxi-look, look only — no assets, maps or branding
## copied; our world stays village/Mindon/fields, NOT a city copy): route
## light pools x8, Mindon street pool discs x6, a north skyline band, dusk
## water glows x5 (ripple planes, NOT mirror reflections — no reflection
## is built or claimed). Player light (owner order 2026-10-23 ~22:40):
## warm forward spot + foot omni, gated daylight < 0.15, travelling with
## the player on foot AND in vehicles.
## DEVIATION, stated: the player light is NOT a child of the Player node.
## The Player body does NOT follow into a vehicle — player.gd
## _try_enter_vehicle() hides the body and leaves it at the entry spot —
## so a child light would stay at the entry spot while driving. Instead
## ONE spot + ONE omni live as world children and are repositioned every
## frame to the carrier (player on foot, driving vehicle in a vehicle).
## Rules unchanged: runtime dressing ONLY, no .tscn edits, no bus-system
## changes, minibus NOT rewired, big bus NOT rewired (Slice 81 limit),
## touch controls untouched, zero NEW colliders (solids are REPLACED, not
## added; steps and balcony floors are visual-only, no interiors, no
## climbing — the player walks around them, sim-proved), StandardMaterial3D
## only, no dead specular lines, no fog/SSAO/glow claims (no
## WorldEnvironment exists), no photorealism claims: stylised smooth
## procedural rebuilds, stated plainly. Runs at frame >= 180, after
## realism99's 160 pass, so every position below is read off FINAL geometry.
## Counting: one item = one placed assembly, or one set of identical parts
## on one building / figure / vehicle / site. 49 items:
##   MINDON 6: Post, Edu, MRTV, Shops (+ shopfront), Temple, Hospital
##   VILLAGE 4: House97_1..4
##   EAST FIELDS 12: StiltHouse62_0..11
##   PEOPLE 9: female-A waistband x4, female-B waistband x5
##   CAR 2: antenna x1, wiper pair x1
##   NIGHT 15: route pools x8, Mindon street discs x1 set,
##     skyline band x1, dusk water glows x5
##   PLAYER LIGHT 1: spot + omni pair
## Deferred to Slice 100, stated not hidden: hamlet houses (4) and the
## StiltHouse13 / School / stilt-rebuild houses (2 + 1 + 1) get the same
## full treatment; the remaining village houses (old House1/2/5/6 slabs
## hidden by S96/S97 rebuilds) are not re-detailed; no second skyline
## band on the east horizon; no full staircase to the EF verandas
## (entry steps only — a 7-step stair per house needs a road-clearance
## survey first, since stairs run 9 m out from the house).

static var _trim_mat: StandardMaterial3D = null
static var _plaster_mat: StandardMaterial3D = null
static var _dark_mat: StandardMaterial3D = null
static var _glass_mat: StandardMaterial3D = null
static var _wood_mat: StandardMaterial3D = null
static var _glow_mat: StandardMaterial3D = null
static var _dusk_mat: StandardMaterial3D = null
static var _sky_mat: StandardMaterial3D = null

var _frames: int = 0
var _done: bool = false
var _glows: Array = []
var _dusk_glows: Array = []
## S120: gate on night/dusk-state CHANGE, not every frame — the
## old per-frame write undid Perf120's distance culling within
## one frame. First frame always runs; after that only on change.
## Player-light update below stays per-frame (carrier reposition).
var _last_night := false
var _last_dusk := false
var _gate_once := false
var _spot: SpotLight3D = null
var _omni: OmniLight3D = null

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism100") != null:
		return
	var n := Node3D.new()
	n.name = "Realism100"
	n.set_script(load("res://realism100.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 180:
		_done = true
		_apply(get_parent() as Node3D)
	var world := get_parent() as Node3D
	if world == null:
		return
	var day := _daylight(world)
	var night := day < 0.15
	var dusk := day < 0.45
	if not _gate_once or night != _last_night or dusk != _last_dusk:
		_gate_once = true
		_last_night = night
		_last_dusk = dusk
		for g in _glows:
			var m := g as Node3D
			if m != null:
				m.visible = night
		for g in _dusk_glows:
			var m := g as Node3D
			if m != null:
				m.visible = dusk
	_update_player_light(world, day)

static func _daylight(world: Node3D) -> float:
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		return float(dn.call("daylight"))
	return 1.0

static func _mats() -> void:
	if _trim_mat != null:
		return
	_trim_mat = StandardMaterial3D.new()
	_trim_mat.albedo_color = Color(0.92, 0.88, 0.78, 1.0)
	_trim_mat.roughness = 0.85
	_plaster_mat = StandardMaterial3D.new()
	_plaster_mat.albedo_color = Color(0.80, 0.70, 0.56, 1.0)
	_plaster_mat.roughness = 0.95
	_dark_mat = StandardMaterial3D.new()
	_dark_mat.albedo_color = Color(0.15, 0.22, 0.30, 1.0)
	_dark_mat.roughness = 0.9
	_glass_mat = StandardMaterial3D.new()
	_glass_mat.albedo_color = Color(0.12, 0.18, 0.26, 1.0)
	_glass_mat.roughness = 0.15
	_glass_mat.metallic = 0.4
	_wood_mat = StandardMaterial3D.new()
	_wood_mat.albedo_color = Color(0.45, 0.30, 0.18, 1.0)
	_wood_mat.roughness = 0.9
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.albedo_color = Color(1.0, 0.75, 0.45, 1.0)
	_glow_mat.emission_enabled = true
	_glow_mat.emission = Color(1.0, 0.70, 0.35, 1.0)
	_glow_mat.emission_energy_multiplier = 1.6
	_dusk_mat = StandardMaterial3D.new()
	_dusk_mat.albedo_color = Color(1.0, 0.55, 0.25, 0.45)
	_dusk_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dusk_mat.roughness = 0.4
	_sky_mat = StandardMaterial3D.new()
	_sky_mat.albedo_color = Color(0.10, 0.12, 0.20, 1.0)
	_sky_mat.roughness = 1.0

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.set_surface_override_material(0, mat)
	m.position = pos
	m.rotation = rot
	parent.add_child(m)
	return m

static func _cyl(parent: Node, r_top: float, r_bottom: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bottom
	cm.height = h
	m.mesh = cm
	m.set_surface_override_material(0, mat)
	m.position = pos
	m.rotation = rot
	parent.add_child(m)
	return m

static func _find(world: Node, nm: String) -> Node:
	for c in world.get_children():
		if String(c.name) == nm:
			return c
		var sub := _find(c, nm)
		if sub != null:
			return sub
	return null

func _update_player_light(world: Node3D, day: float) -> void:
	if _spot == null or _omni == null:
		return
	var on := day < 0.15
	_spot.visible = on
	_omni.visible = on
	if not on:
		return
	var player := world.get_node_or_null("Player") as Node3D
	if player == null:
		_spot.visible = false
		_omni.visible = false
		return
	var carrier: Node3D = player
	if player.get("driving") == true and player.get("driving_vehicle") != null:
		carrier = player.get("driving_vehicle") as Node3D
		if carrier == null:
			carrier = player
	var lift := 1.7 if carrier == player else 2.0
	var pos := carrier.global_position + Vector3(0.0, lift, 0.0)
	_spot.global_position = pos
	_omni.global_position = pos
	var b := carrier.global_transform.basis
	var fwd := b.z if carrier == player else -b.z
	fwd.y = 0.0
	if fwd.length() < 0.001:
		fwd = Vector3(0.0, 0.0, 1.0)
	fwd = fwd.normalized()
	# Beam: carrier forward tilted down 12 degrees (0.21 rad).
	var beam := Vector3(fwd.x * cos(0.21), -sin(0.21), fwd.z * cos(0.21)).normalized()
	_spot.global_transform = Transform3D(Basis.looking_at(beam, Vector3.UP), pos)

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_mats()
	_mindon(world)
	_house97(world)
	_ef(world)
	_people(world)
	_car(world)
	_pools(world)
	_skyline(world)
	_water(world)
	_player_light_nodes()

func _player_light_nodes() -> void:
	# ONE coherent player light: warm forward spot (range 14 m,
	# cone 60 degrees, energy 2.2, shadows OFF for perf) plus
	# a soft foot omni (energy 0.9, range 6 m) so the player's
	# feet are not dark. Gated daylight < 0.15 every frame in
	# _process; fully off in daylight; moonlight and street
	# lamps untouched; day sun value untouched.
	_spot = SpotLight3D.new()
	_spot.name = "PlayerLight100_Spot"
	_spot.light_color = Color(1.0, 0.75, 0.45, 1.0)
	_spot.light_energy = 2.2
	_spot.spot_range = 14.0
	_spot.spot_angle = 60.0
	_spot.shadow_enabled = false
	_spot.visible = false
	add_child(_spot)
	_omni = OmniLight3D.new()
	_omni.name = "PlayerLight100_Omni"
	_omni.light_color = Color(1.0, 0.75, 0.45, 1.0)
	_omni.light_energy = 0.9
	_omni.omni_range = 6.0
	_omni.shadow_enabled = false
	_omni.visible = false
	add_child(_omni)

func _mindon(world: Node3D) -> void:
	# Shared S59 geometry, local coords (children inherit the
	# group scale): walls 6 x 2.8 x 5 at y 1.4, windows
	# 0.55 x 0.7 at x -2.1/-0.7/0.7/2.1, y 1.7, z +-2.53,
	# door 0.8 x 1.4 at (0, 0.7, 2.54), old prism roof at
	# y 3.2 (hidden here). Overhang o: Post uses 0.10 (its
	# solid must stay clear of the S96 street edge at x
	# 142.5 — walls clear it by 0.4, so o = 0.10 keeps 0.23);
	# the other five use 0.20.
	# [group, solid, camblock, overhang]
	var table: Array = [
		["MindonPost", "MindonPostSolid", "MindonPostCamBlock", 0.10],
		["MindonEdu", "MindonEduSolid", "MindonEduCamBlock", 0.20],
		["MindonMRTV", "MindonMRTVSolid", "MindonMRTVCamBlock", 0.20],
		["MindonShops", "MindonShopsSolid", "MindonShopsCamBlock", 0.20],
		["MindonTemple", "MindonTempleSolid", "MindonTempleCamBlock", 0.20],
		["MindonHospital", "MindonHospitalSolid", "MindonHospitalCamBlock", 0.20],
	]
	var win_xs: Array = [-2.1, -0.7, 0.7, 2.1]
	for row in table:
		var grp := world.get_node_or_null(String(row[0])) as Node3D
		if grp == null:
			continue
		var o := float(row[3])
		# Hide the old single roof (runtime only).
		for c in grp.get_children():
			if c is MeshInstance3D and String(c.name).ends_with("Roof"):
				(c as MeshInstance3D).visible = false
		# Genuine second storey: upper walls 2.8..5.4.
		_box(grp, Vector3(6.0, 2.6, 5.0), _plaster_mat, Vector3(0.0, 4.1, 0.0), "Upper100")
		# Upper windows (dark inset) + frames + sills, both faces.
		# Names carry an index: sibling names must be unique
		# or Godot silently renames losers.
		var wi := 0
		for sx in win_xs:
			for sgn in [-1.0, 1.0]:
				_box(grp, Vector3(0.55, 0.7, 0.06), _dark_mat, Vector3(sx, 4.1, sgn * 2.53), "WinU100_%d" % wi)
				_box(grp, Vector3(0.75, 0.9, 0.05), _trim_mat, Vector3(sx, 4.1, sgn * 2.575), "FrameU100_%d" % wi)
				_box(grp, Vector3(0.75, 0.08, 0.12), _trim_mat, Vector3(sx, 3.68, sgn * 2.575), "SillU100_%d" % wi)
				wi += 1
		# Ground window frames + sills around the S59 windows.
		var gi := 0
		for sx in win_xs:
			for sgn in [-1.0, 1.0]:
				_box(grp, Vector3(0.75, 0.9, 0.05), _trim_mat, Vector3(sx, 1.7, sgn * 2.575), "FrameG100_%d" % gi)
				_box(grp, Vector3(0.75, 0.08, 0.12), _trim_mat, Vector3(sx, 1.32, sgn * 2.575), "SillG100_%d" % gi)
				gi += 1
		# Floor-separator band, eaves band, new pitched roof.
		_box(grp, Vector3(6.0 + 2.0 * o, 0.20, 5.0 + 2.0 * o), _trim_mat, Vector3(0.0, 2.90, 0.0), "Band100")
		_box(grp, Vector3(6.0 + 2.0 * o, 0.18, 5.0 + 2.0 * o), _trim_mat, Vector3(0.0, 5.50, 0.0), "Eaves100")
		_box(grp, Vector3(6.0 + 2.0 * o, 0.18, 3.0), _plaster_mat, Vector3(0.0, 5.95, 1.30), "Roof100_S", Vector3(-0.35, 0.0, 0.0))
		_box(grp, Vector3(6.0 + 2.0 * o, 0.18, 3.0), _plaster_mat, Vector3(0.0, 5.95, -1.30), "Roof100_N", Vector3(0.35, 0.0, 0.0))
		# Balcony (front +z, upper floor): floor slab, rails,
		# posts, upper door. Floor at y 2.85 is 5+ m up in
		# world — unreachable on foot, so zero colliders
		# here cannot trap the player (stated).
		_box(grp, Vector3(2.6, 0.15, 1.1), _wood_mat, Vector3(0.0, 2.85, 3.05), "Balcony100")
		_box(grp, Vector3(2.6, 0.06, 0.06), _wood_mat, Vector3(0.0, 3.80, 3.58), "BalRail100_F")
		_box(grp, Vector3(0.06, 0.06, 1.1), _wood_mat, Vector3(-1.27, 3.80, 3.05), "BalRail100_L")
		_box(grp, Vector3(0.06, 0.06, 1.1), _wood_mat, Vector3(1.27, 3.80, 3.05), "BalRail100_R")
		var bp := 0
		for px in [-1.27, 1.27]:
			for pz in [2.55, 3.58]:
				_box(grp, Vector3(0.06, 0.95, 0.06), _wood_mat, Vector3(px, 3.32, pz), "BalPost100_%d" % bp)
				bp += 1
		_box(grp, Vector3(0.8, 1.9, 0.10), _wood_mat, Vector3(0.0, 3.80, 2.55), "BalDoor100")
		# Ground door frame + steps (visual only: no
		# interiors, no climbing — stated).
		_box(grp, Vector3(0.12, 1.6, 0.10), _trim_mat, Vector3(-0.50, 0.80, 2.58), "DoorFrame100_L")
		_box(grp, Vector3(0.12, 1.6, 0.10), _trim_mat, Vector3(0.50, 0.80, 2.58), "DoorFrame100_R")
		_box(grp, Vector3(1.12, 0.12, 0.10), _trim_mat, Vector3(0.0, 1.62, 2.58), "DoorLintel100")
		_box(grp, Vector3(1.4, 0.12, 0.5), _trim_mat, Vector3(0.0, 0.06, 2.90), "Step100_A")
		_box(grp, Vector3(1.4, 0.24, 0.5), _trim_mat, Vector3(0.0, 0.12, 2.65), "Step100_B")
		# Plinth (base skirt) + pilasters (ground floor).
		_box(grp, Vector3(6.0 + 2.0 * o, 0.30, 5.0 + 2.0 * o), _trim_mat, Vector3(0.0, 0.15, 0.0), "Plinth100")
		var pi := 0
		for px in [-1.4, 1.4]:
			_box(grp, Vector3(0.20, 2.8, 0.06), _trim_mat, Vector3(px, 1.4, 2.53), "Pilaster100_F%d" % pi)
			pi += 1
		for px in [-1.4, 0.0, 1.4]:
			_box(grp, Vector3(0.20, 2.8, 0.06), _trim_mat, Vector3(px, 1.4, -2.53), "Pilaster100_B%d" % pi)
			pi += 1
		for px in [-2.95, 2.95]:
			for sgn in [-1.0, 1.0]:
				_box(grp, Vector3(0.20, 2.8, 0.06), _trim_mat, Vector3(px, 1.4, sgn * 2.53), "Corner100_%d" % pi)
				pi += 1
		# Shops shopfront: glazed panes + mullions + header
		# over the centre ground windows (the +-0.7 S59
		# windows read as shop glass now; +-2.1 stay plain).
		if String(row[0]) == "MindonShops":
			var sg := 0
			for gx in [-1.05, 1.05]:
				_box(grp, Vector3(1.4, 1.6, 0.05), _glass_mat, Vector3(gx, 1.1, 2.57), "ShopGlass100_%d" % sg)
				sg += 1
			var smu := 0
			for mx in [-1.80, 0.0, 1.80]:
				_box(grp, Vector3(0.08, 1.6, 0.06), _trim_mat, Vector3(mx, 1.1, 2.58), "ShopMullion100_%d" % smu)
				smu += 1
			_box(grp, Vector3(3.7, 0.15, 0.08), _trim_mat, Vector3(0.0, 1.98, 2.58), "ShopHeader100")
		# Night glows for the upper front windows (world
		# children, gated < 0.15 in _process).
		var sc := grp.scale
		var gp := grp.global_position
		var gl_i := 0
		for gx in [-1.4, 1.4]:
			var gl := _box(world, Vector3(0.55, 0.70, 0.04), _glow_mat, Vector3(gp.x + gx * sc.x, 4.1 * sc.y, gp.z + 2.60 * sc.z), "GlowU100_%d_%d" % [table.find(row), gl_i])
			gl_i += 1
			gl.visible = false
			_glows.append(gl)
		# Collider match (the S96 gap, fixed): REPLACE the
		# undersized shared-shape solid with an individual
		# box sized to the new envelope: walls + band
		# overhang, height to the new roof apex (local 6.6).
		var solid := world.get_node_or_null(String(row[1])) as StaticBody3D
		if solid != null:
			solid.scale = Vector3.ONE
			solid.position = Vector3(gp.x, 6.6 * sc.y * 0.5, gp.z)
			for ch in solid.get_children():
				if ch is CollisionShape3D:
					var nb := BoxShape3D.new()
					nb.size = Vector3((6.0 + 2.0 * o) * sc.x, 6.6 * sc.y, (5.0 + 2.0 * o) * sc.z)
					(ch as CollisionShape3D).shape = nb
					(ch as CollisionShape3D).position = Vector3.ZERO
		# CamBlock height to the same apex (body scale only
		# — the shared shape resource is never mutated).
		var cam := world.get_node_or_null(String(row[2])) as StaticBody3D
		if cam != null:
			for ch in cam.get_children():
				if ch is CollisionShape3D:
					var sh := (ch as CollisionShape3D).shape as BoxShape3D
					if sh != null:
						var cur_h := sh.size.y * cam.scale.y
						var target := 6.6 * sc.y
						if cur_h > 0.0:
							cam.scale.y *= target / cur_h
							cam.position.y = target * 0.5

func _house97(world: Node3D) -> void:
	# S96/S97 rebuilds: ground 0..3.0, slab at 3.1 (already
	# the floor-separator band — not duplicated), upper
	# 3.2..5.8, apex 6.95 (d >= 6.9) else ~6.52. Front +z:
	# door 0.9 x 2.0 at (0, 1.0, d/2+0.06), windows
	# 0.8 x 0.9 at x +-w*0.28, y 1.7/4.5, z d/2+0.03.
	# Backs had NO windows at all — added here, framed.
	var village: Array = [[1, 2.6, 7.0, 6.95], [2, 5.0, 7.0, 6.95], [3, 2.0, 4.0, 6.52], [4, 2.0, 4.0, 6.52]]
	for v in village:
		var idx := int(v[0])
		var w := float(v[1])
		var d := float(v[2])
		var apex := float(v[3])
		var h := world.get_node_or_null("House97_%d" % idx) as Node3D
		if h == null:
			continue
		var hi := 0
		for sx in [-1.0, 1.0]:
			var wx: float = float(sx) * w * 0.28
			for wy in [1.7, 4.5]:
				_box(h, Vector3(1.0, 1.1, 0.04), _trim_mat, Vector3(wx, wy, d * 0.5 + 0.06), "Frame97_%d" % hi)
				_box(h, Vector3(1.0, 0.08, 0.10), _trim_mat, Vector3(wx, wy - 0.48, d * 0.5 + 0.08), "Sill97_%d" % hi)
				_box(h, Vector3(0.8, 0.9, 0.08), _dark_mat, Vector3(wx, wy, -d * 0.5 - 0.03), "WinB97_%d" % hi)
				_box(h, Vector3(1.0, 1.1, 0.04), _trim_mat, Vector3(wx, wy, -d * 0.5 - 0.06), "FrameB97_%d" % hi)
				_box(h, Vector3(1.0, 0.08, 0.10), _trim_mat, Vector3(wx, wy - 0.48, -d * 0.5 - 0.08), "SillB97_%d" % hi)
				hi += 1
		# Eaves band, plinth, corner boards (both floors,
		# both faces), door frame + steps (visual only).
		_box(h, Vector3(w + 0.3, 0.15, d + 0.3), _trim_mat, Vector3(0.0, 5.85, 0.0), "Eaves97")
		_box(h, Vector3(w + 0.2, 0.30, d + 0.2), _trim_mat, Vector3(0.0, 0.15, 0.0), "Plinth97")
		var ci := 0
		for px in [-1.0, 1.0]:
			for py in [1.5, 4.5]:
				for sgn in [-1.0, 1.0]:
					_box(h, Vector3(0.15, 3.0 if py < 3.0 else 2.6, 0.06), _trim_mat, Vector3(px * w * 0.5, py, sgn * (d * 0.5 + 0.03)), "Corner97_%d" % ci)
					ci += 1
		_box(h, Vector3(0.12, 2.2, 0.10), _trim_mat, Vector3(-0.51, 1.1, d * 0.5 + 0.08), "DoorFrame97_L")
		_box(h, Vector3(0.12, 2.2, 0.10), _trim_mat, Vector3(0.51, 1.1, d * 0.5 + 0.08), "DoorFrame97_R")
		_box(h, Vector3(1.14, 0.12, 0.10), _trim_mat, Vector3(0.0, 2.16, d * 0.5 + 0.08), "DoorLintel97")
		_box(h, Vector3(1.5, 0.12, 0.5), _trim_mat, Vector3(0.0, 0.06, d * 0.5 + 0.35), "Step97_A")
		_box(h, Vector3(1.5, 0.24, 0.5), _trim_mat, Vector3(0.0, 0.12, d * 0.5 + 0.12), "Step97_B")
		# Solid widened to cover plinth + frames (height
		# unchanged — the roof is untouched).
		var solid := world.get_node_or_null("House97Solid_%d" % idx) as StaticBody3D
		if solid != null:
			for ch in solid.get_children():
				if ch is CollisionShape3D:
					var nb := BoxShape3D.new()
					nb.size = Vector3(w + 0.24, apex, d + 0.24)
					(ch as CollisionShape3D).shape = nb
					(ch as CollisionShape3D).position = Vector3.ZERO

func _ef(world: Node3D) -> void:
	# S62 stilt houses (x1.5 via S96), local coords: floor
	# 7.0 x 0.3 x 5.0 at y 1.35, walls 6.6 x 2.2 x 4.6 at
	# y 2.6 (faces z +-2.3), roof slabs at y 3.95, veranda
	# 3.0 x 0.15 x 1.6 at (0, 1.35, 3.2), door 0.9 x 1.8 at
	# (-1.2, 2.4, 2.36), windows 0.7 x 0.7 at (1.2/2.4, 2.7,
	# 2.36). Front bars span window + S97 shutters (which
	# sit at z 2.41, y 2.35..3.05): the top bar at y 3.12
	# and sill at y 2.28 clear the shutter row vertically.
	# Back windows are new (the backs were blank).
	for i in range(12):
		var g := _find(world, "StiltHouse62_%d" % i) as Node3D
		if g == null:
			continue
		_box(g, Vector3(2.7, 0.10, 0.05), _trim_mat, Vector3(1.8, 3.12, 2.42), "WinBar100_T")
		_box(g, Vector3(2.7, 0.10, 0.08), _trim_mat, Vector3(1.8, 2.28, 2.42), "WinBar100_B")
		var bi := 0
		for wx in [1.2, 2.4]:
			_box(g, Vector3(0.7, 0.7, 0.10), _dark_mat, Vector3(wx, 2.7, -2.36), "WinBack100_%d" % bi)
			_box(g, Vector3(0.9, 0.9, 0.06), _trim_mat, Vector3(wx, 2.7, -2.42), "FrameBack100_%d" % bi)
			_box(g, Vector3(0.9, 0.08, 0.10), _trim_mat, Vector3(wx, 2.28, -2.42), "SillBack100_%d" % bi)
			bi += 1
		_box(g, Vector3(7.0, 0.15, 0.15), _trim_mat, Vector3(0.0, 3.78, 2.35), "Cornice100_F")
		_box(g, Vector3(7.0, 0.15, 0.15), _trim_mat, Vector3(0.0, 3.78, -2.35), "Cornice100_B")
		_box(g, Vector3(0.15, 0.15, 5.0), _trim_mat, Vector3(3.35, 3.78, 0.0), "Cornice100_L")
		_box(g, Vector3(0.15, 0.15, 5.0), _trim_mat, Vector3(-3.35, 3.78, 0.0), "Cornice100_R")
		_box(g, Vector3(7.2, 0.30, 5.2), _trim_mat, Vector3(0.0, 1.35, 0.0), "Plinth100")
		_box(g, Vector3(0.12, 2.0, 0.10), _trim_mat, Vector3(-1.71, 2.4, 2.40), "DoorFrame100_L")
		_box(g, Vector3(0.12, 2.0, 0.10), _trim_mat, Vector3(-0.69, 2.4, 2.40), "DoorFrame100_R")
		_box(g, Vector3(1.14, 0.12, 0.10), _trim_mat, Vector3(-1.2, 3.38, 2.40), "DoorLintel100")
		# Veranda rails (the stilt house's balcony): front
		# rail + side rails + posts on the veranda edge.
		_box(g, Vector3(3.0, 0.06, 0.06), _wood_mat, Vector3(0.0, 2.35, 4.0), "VerRail100_F")
		_box(g, Vector3(0.06, 0.06, 1.6), _wood_mat, Vector3(-1.45, 2.35, 3.2), "VerRail100_L")
		_box(g, Vector3(0.06, 0.06, 1.6), _wood_mat, Vector3(1.45, 2.35, 3.2), "VerRail100_R")
		var vp := 0
		for px in [-1.45, 0.0, 1.45]:
			_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(px, 1.875, 4.0), "VerPost100_F%d" % vp)
			vp += 1
		for px in [-1.45, 1.45]:
			_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(px, 1.875, 2.45), "VerPost100_S%d" % vp)
			vp += 1
		# Entry steps (visual only, stated: three low steps
		# at the veranda edge, not a full staircase — the
		# veranda itself was already unreachable in S62).
		_box(g, Vector3(1.2, 0.20, 0.35), _trim_mat, Vector3(-1.2, 0.10, 4.55), "Step100_A")
		_box(g, Vector3(1.2, 0.40, 0.35), _trim_mat, Vector3(-1.2, 0.20, 4.30), "Step100_B")
		_box(g, Vector3(1.2, 0.60, 0.35), _trim_mat, Vector3(-1.2, 0.30, 4.05), "Step100_C")
		# Solid widened to cover plinth + frames (the
		# veranda and steps stay outside it, exactly as
		# S62 built them — stated, sim-proved walk-around).
		var solid := g.get_node_or_null("StiltHouse62Solid_%d" % i) as StaticBody3D
		if solid != null:
			for ch in solid.get_children():
				if ch is CollisionShape3D:
					var nb := BoxShape3D.new()
					nb.size = Vector3(7.24, 3.8, 5.24)
					(ch as CollisionShape3D).shape = nb

func _people(world: Node3D) -> void:
	# Sex markers from Slice 94 (same as S98): male =
	# Collar94, female A = Lace94, female B = neither.
	# S98 gave males Waist99; females had NOTHING at the
	# waist. LongyiPivot58 at body y -0.10; longyi flare
	# top r 0.24 at lpiv y 0.0. Bands sit at lpiv y 0.03
	# (just above the tube top), r 0.26/0.27 — the same
	# seat as the male band, so the set reads coherent
	# across the crowd at the 6 m camera.
	var fema_band := _mat(Color(0.45, 0.15, 0.60, 1.0), 0.85)
	var femb_band := _mat(Color(0.90, 0.55, 0.70, 1.0), 0.85)
	for child in world.get_children():
		var nm := String(child.name)
		if nm != "Player" and not nm.begins_with("Villager"):
			continue
		var is_male := child.get_node_or_null("Collar94") != null
		var is_fema := child.get_node_or_null("Lace94") != null
		if is_male:
			continue
		var lpiv := child.get_node_or_null("LongyiPivot58") as Node3D
		if lpiv == null:
			continue
		if lpiv.get_node_or_null("Waist100") != null:
			continue
		if is_fema:
			_cyl(lpiv, 0.26, 0.27, 0.09, fema_band, Vector3(0.0, 0.03, 0.0), "Waist100_A")
		else:
			_cyl(lpiv, 0.26, 0.27, 0.09, femb_band, Vector3(0.0, 0.03, 0.0), "Waist100_B")

static func _mat(col: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	return m

func _car(world: Node3D) -> void:
	# S95 car (live S35 paint): Roof96 at y 0.53 (top
	# 0.565), Hood96 top at y 0.18, cabin glass front
	# face at z -0.575. Antenna on the roof rear;
	# wipers on the hood before the glass, angled.
	var car := world.get_node_or_null("Car") as Node3D
	if car == null:
		return
	var chrome := _mat(Color(0.75, 0.75, 0.78, 1.0), 0.3)
	var dark := _mat(Color(0.12, 0.12, 0.12, 1.0), 0.9)
	_cyl(car, 0.02, 0.03, 0.45, dark, Vector3(0.6, 0.79, 0.75), "Antenna100")
	_box(car, Vector3(0.5, 0.03, 0.06), dark, Vector3(-0.4, 0.20, -0.75), "Wiper100_L", Vector3(0.0, 0.3, 0.0))
	_box(car, Vector3(0.5, 0.03, 0.06), dark, Vector3(0.4, 0.20, -0.75), "Wiper100_R", Vector3(0.0, -0.3, 0.0))

func _pools(world: Node3D) -> void:
	# Route pools: the S74 slab spans |z| <= 6, top y
	# 0.12 — poles stand clear at z +-7.5, discs lie ON
	# the road at y 0.14 (light pools only, zero
	# colliders). Omni on every 2nd pole. Route stops
	# sit at x 500/700/1200/1700/2200/2400 — pool xs
	# (600/800/1000/1300/1500/1800/2000/2300) avoid them.
	var pole_m := _mat(Color(0.25, 0.25, 0.25, 1.0), 0.8)
	var xs: Array = [600.0, 800.0, 1000.0, 1300.0, 1500.0, 1800.0, 2000.0, 2300.0]
	for k in range(xs.size()):
		var x := float(xs[k])
		var side := 1.0 if k % 2 == 0 else -1.0
		_box(world, Vector3(0.12, 3.0, 0.12), pole_m, Vector3(x, 1.5, side * 7.5), "RoutePole100_%d" % k)
		var disc := _cyl(world, 2.4, 2.4, 0.02, _glow_mat, Vector3(x, 0.14, 0.0), "RoutePool100_%d" % k)
		disc.visible = false
		_glows.append(disc)
		if k % 2 == 0:
			var om := OmniLight3D.new()
			om.name = "RouteOmni100_%d" % k
			om.light_color = Color(1.0, 0.75, 0.45, 1.0)
			om.light_energy = 1.2
			om.omni_range = 18.0
			om.shadow_enabled = false
			om.position = Vector3(x, 3.0, side * 7.5)
			om.visible = false
			world.add_child(om)
			_glows.append(om)
	# Mindon street pool discs: the S59 poles stand at
	# x 105..205 (step 20), z 4.5, beside the E-W street
	# (slabs 24 x 0.1 x 6 at y 0.11, top 0.16, z 0) —
	# discs lie on the street at y 0.18, under the poles.
	var mdi := 0
	for x in [105.0, 125.0, 145.0, 165.0, 185.0, 205.0]:
		var disc := _cyl(world, 2.0, 2.0, 0.02, _glow_mat, Vector3(x, 0.18, 0.0), "MindonPool100_%d" % mdi)
		mdi += 1
		disc.visible = false
		_glows.append(disc)

func _skyline(world: Node3D) -> void:
	# Distant north band so night does not end in black
	# void: 16 dark boxes beyond the north clamp (z 409.5),
	# 12..28 m tall, with 8 gated window dots on their
	# south faces. Meshes only — zero colliders.
	for k in range(16):
		var x := -600.0 + 240.0 * k
		var z := 470.0 + float(k % 3) * 15.0
		var h := 12.0 + float((k * 7) % 17)
		var w := 30.0 + float((k * 13) % 50)
		_box(world, Vector3(w, h, 20.0), _sky_mat, Vector3(x, h * 0.5, z), "Skyline100_%d" % k)
		if k % 2 == 0:
			var dot := _box(world, Vector3(1.5, 2.0, 0.10), _glow_mat, Vector3(x, 6.0 + float(k % 4) * 3.0, z - 10.06), "SkyDot100_%d" % k)
			dot.visible = false
			_glows.append(dot)

func _water(world: Node3D) -> void:
	# Dusk water glows: warm translucent planes ON the
	# water (not mirror reflections — no reflection is
	# built or claimed). Gated daylight < 0.45, so they
	# read at dusk AND night, off in day. Village pond
	# plane is 8 x 6 at (16, 0.03, -2); west pond water
	# is r 12 at (-330, 0); river plane is 100 x 6 at
	# (0, 0.05, 44).
	_box(world, Vector3(7.0, 0.04, 5.0), _dusk_mat, Vector3(16.0, 0.09, -2.0), "DuskWater100_Village")
	_box(world, Vector3(8.0, 0.04, 6.0), _dusk_mat, Vector3(-500.0, 0.10, -300.0), "DuskWater100_E0")
	_box(world, Vector3(8.0, 0.04, 6.0), _dusk_mat, Vector3(2400.0, 0.10, 320.0), "DuskWater100_E1")
	var wp := _cyl(world, 8.0, 8.0, 0.04, _dusk_mat, Vector3(-330.0, 0.10, 0.0), "DuskWater100_West")
	_box(world, Vector3(60.0, 0.04, 5.0), _dusk_mat, Vector3(0.0, 0.10, 44.0), "DuskWater100_River")
	for c in world.get_children():
		if String(c.name).begins_with("DuskWater100"):
			(c as Node3D).visible = false
			_dusk_glows.append(c)
