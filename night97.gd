extends Node3D
## Slice 97 NIGHT VISIBILITY (owner complaint 2026-10-23 ~20:29:
## "at night NOTHING is visible" — his night screenshot and video
## show black ground/characters with only lit pagoda tiers).
## ROOT CAUSE, measured from the code (not guessed): the sun
## floor from Slice 61 (energy 0.35 at daylight 0) is NOT the
## problem on its own — the DirectionalLight SunLight ROTATES
## with the day clock (day_night.gd: rotation.x = angle - 90),
## so at deep night it shines sideways/upward and ground top
## faces, characters and house walls get almost no direct
## light however high the energy floor is. FIX: a MOON light
## that shines DOWN from above all night (same identity-down
## orientation the noon sun uses, tilted 35 deg for modelling),
## cool blue, energy 0.55 at daylight 0 fading to 0 at daylight
## 0.15 — day values are untouched (sun energy line and the
## daylight clock itself are NOT changed). Plus 10 warm street
## omnis and 34 window-glow planes at the scaled/rebuilt
## houses, all gated on the existing daylight < 0.15 rule and
## applied EVERY frame (Slice 76/77 lesson: gating applied at
## build, not only on daylight change — a fresh load at night
## is lit immediately). Shadows OFF on the moon light (the sun
## already casts; a second shadow map is cost for no gain).
## StandardMaterial3D only, no dead specular, no WorldEnvironment
## levers claimed (none exists in this project). Phone verdict
## still decides whether night now reads — headless sims prove
## energies/counts/gating, not screen brightness.

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Night97") != null:
		return
	var n := Node3D.new()
	n.name = "Night97"
	n.set_script(load("res://night97.gd"))
	world.call_deferred("add_child", n)

var _moon: DirectionalLight3D = null
var _omnis: Array = []
var _glows: Array = []
var _built: bool = false

func _process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _built:
		_build(world)
		_built = true
	var day := 1.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		day = float(dn.call("daylight"))
	var night := day < 0.15
	# Moon: full 0.55 at daylight 0, linear fade to 0 at 0.15.
	if _moon != null:
		_moon.light_energy = 0.55 * clampf((0.15 - day) / 0.15, 0.0, 1.0)
		_moon.visible = night
	for o in _omnis:
		(o as OmniLight3D).visible = night
	for g in _glows:
		(g as MeshInstance3D).visible = night

func _mat_glow() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.75, 0.4, 1.0)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.35, 1.0)
	m.emission_energy_multiplier = 1.2
	m.roughness = 1.0
	return m

func _omni(parent: Node3D, nm: String, pos: Vector3, energy: float, rng: float) -> void:
	var o := OmniLight3D.new()
	o.name = nm
	o.position = pos
	o.light_color = Color(1.0, 0.78, 0.5, 1.0)
	o.light_energy = energy
	o.omni_range = rng
	o.shadow_enabled = false
	parent.add_child(o)
	_omnis.append(o)

func _glow(parent: Node3D, nm: String, pos: Vector3, w: float, h: float, rot_y: float = 0.0) -> void:
	var m := PlaneMesh.new()
	m.size = Vector2(w, h)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = m
	mi.material_override = _mat_glow()
	mi.position = pos
	mi.rotation.y = rot_y
	parent.add_child(mi)
	_glows.append(mi)

func _build(world: Node3D) -> void:
	_moon = DirectionalLight3D.new()
	_moon.name = "MoonLight97"
	_moon.light_color = Color(0.65, 0.75, 1.0, 1.0)
	_moon.light_energy = 0.55
	_moon.shadow_enabled = false
	# Identity-down orientation (the noon sun's convention),
	# tilted 35 deg on X and 25 deg on Y so walls get modelling
	# instead of flat top light.
	_moon.rotation_degrees = Vector3(35.0, 25.0, 0.0)
	add_child(_moon)
	# 10 street omnis: village, market, school, pagoda, EF road,
	# hamlet, Mindon centre, depot, long-route mid, village east.
	var spots: Array = [
		["Omni97_Village", Vector3(0.0, 2.0, 0.0)],
		["Omni97_Market", Vector3(-6.0, 2.0, 6.0)],
		["Omni97_School", Vector3(-30.0, 2.0, 14.0)],
		["Omni97_Pagoda", Vector3(108.0, 2.0, -62.0)],
		["Omni97_EFRoad", Vector3(330.0, 2.0, 0.0)],
		["Omni97_Hamlet", Vector3(2100.0, 2.0, 88.0)],
		["Omni97_Mindon", Vector3(150.0, 2.0, 40.0)],
		["Omni97_Depot", Vector3(30.0, 2.0, 20.0)],
		["Omni97_RouteMid", Vector3(1500.0, 2.0, 0.0)],
		["Omni97_VillageEast", Vector3(40.0, 2.0, -20.0)],
	]
	for s in spots:
		_omni(self, String(s[0]), Vector3(s[1]), 1.5, 22.0)
	# Window glows (world-positioned children of Night97, which
	# sits at the world origin unrotated, so local = world).
	# Village rebuilds (scale97): House1 2.6 wide (Villager1
	# spawns 2 m away — narrow by necessity), House2 5.0
	# wide, Houses 3/4 2.0 wide x 4.0 deep (centres only
	# 4.47 m apart — full-size houses would interpenetrate),
	# all front +z, ground windows at y 1.7.
	var village: Array = [
		[Vector3(-8.0, 0.0, -8.0), 2.6, 7.0], [Vector3(10.0, 0.0, -10.0), 5.0, 7.0],
		[Vector3(-14.0, 0.0, 10.0), 2.0, 4.0], [Vector3(-16.0, 0.0, 14.0), 2.0, 4.0],
	]
	var vi := 0
	for v in village:
		var c: Vector3 = v[0]
		var w: float = v[1]
		var d: float = v[2]
		_glow(self, "Glow97_Village%dA" % vi, Vector3(c.x - w * 0.28, 1.7, c.z + d * 0.5 + 0.06), 0.7, 0.9)
		_glow(self, "Glow97_Village%dB" % vi, Vector3(c.x + w * 0.28, 1.7, c.z + d * 0.5 + 0.06), 0.7, 0.9)
		vi += 1
	# Scene stilt rebuilds (scale97): 8.0 x 6.0, front +z, floor
	# windows at y 2.6 (raised floor).
	for si in range(2):
		var c := Vector3(-26.0, 0.0, -16.0) if si == 0 else Vector3(0.0, 0.0, -22.0)
		_glow(self, "Glow97_Stilt%dA" % si, Vector3(c.x - 2.0, 2.6, c.z + 3.06), 0.7, 0.9)
		_glow(self, "Glow97_Stilt%dB" % si, Vector3(c.x + 2.0, 2.6, c.z + 3.06), 0.7, 0.9)
	# Mindon buildings (scale97 x1.8, Post x1.7 for street
	# clearance): base footprint 6.0 x 5.0 except Temple
	# 9.0 x 7.0 and Hospital 10.8 x 8.0 (baked group
	# scales); front +z, windows at y 1.5 x scale.
	# Stored as [centre, scaled width, scaled depth, glow y].
	var mindon: Array = [
		[Vector3(218.0, 0.0, -22.0), 16.2, 12.6, 2.7],
		[Vector3(122.0, 0.0, 58.0), 19.44, 14.4, 2.7],
		[Vector3(148.0, 0.0, 26.0), 10.2, 8.5, 2.55],
		[Vector3(102.0, 0.0, 62.0), 10.8, 9.0, 2.7],
		[Vector3(108.0, 0.0, 42.0), 10.8, 9.0, 2.7],
		[Vector3(205.0, 0.0, 38.0), 10.8, 9.0, 2.7],
	]
	var mi := 0
	for b in mindon:
		var c: Vector3 = b[0]
		var d: float = b[2]
		var gy: float = b[3]
		_glow(self, "Glow97_Mindon%d" % mi, Vector3(c.x, gy, c.z + d * 0.5 + 0.06), 0.8, 1.0)
		mi += 1
	# East Fields houses (scale97 x1.5): 10.5 x 7.5. Front faces
	# the road: rot 0 -> +z, rot PI -> -z, rot PI/2 -> +x.
	var ef: Array = [
		[270.0, -16.0, 0.0], [300.0, -16.0, 0.0], [330.0, -16.0, 0.0],
		[360.0, -16.0, 0.0], [390.0, -16.0, 0.0], [420.0, -16.0, 0.0],
		[285.0, 16.0, PI], [315.0, 16.0, PI], [345.0, 16.0, PI],
		[405.0, 16.0, PI], [330.0, -40.0, PI * 0.5], [330.0, -70.0, PI * 0.5],
	]
	var ei := 0
	for h in ef:
		var x: float = h[0]
		var z: float = h[1]
		var r: float = h[2]
		if r == 0.0:
			_glow(self, "Glow97_EF%d" % ei, Vector3(x, 4.0, z + 3.51), 0.8, 1.0)
		elif r == PI:
			_glow(self, "Glow97_EF%d" % ei, Vector3(x, 4.0, z - 3.51), 0.8, 1.0, PI)
		else:
			_glow(self, "Glow97_EF%d" % ei, Vector3(x + 3.51, 4.0, z), 0.8, 1.0, PI * 0.5)
		ei += 1
	# Hamlet houses (scale97 x1.8): 12.6 x 10.8, door on -z.
	var hamlet: Array = [Vector3(2075.0, 0.0, 78.0), Vector3(2125.0, 0.0, 78.0), Vector3(2075.0, 0.0, 98.0), Vector3(2125.0, 0.0, 98.0)]
	var hi := 0
	for c in hamlet:
		_glow(self, "Glow97_Hamlet%d" % hi, Vector3(c.x, 3.2, c.z - 5.46), 0.8, 1.0, PI)
		hi += 1
