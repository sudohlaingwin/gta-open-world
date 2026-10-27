extends Node3D
## Slice 100 (parent sequence): FINISH S99'S DEFERRED BUILDING LIST +
## EAST SKYLINE + FULL EF VERANDA STAIRCASES + OPENTAXI NIGHT FILL.
## Owner standing rules: ~50 items per push, graphics-first, whole buildings
## finished, not thin detail spread everywhere.
##
## AUDIT-FIRST findings (all live-probed, 2026-10-23):
## - Hamlet houses (HamletHouse75_0..3, x1.8, at (2075/2125, 78/98)) have NO
##   solid at all (player walks through walls), NO frames/sills, blank backs,
##   NO corner boards/eaves/plinth/door frame. Their stairs come from the
##   S94 restyle holder — but ONLY for the z-78 pair (Restyle94_2075_78 /
##   2125_78, 4 steps, floor-to-ground, door-aligned); the z-98 pair has NO
##   stairs at all. The restyle front rail (RailTop94) crosses the doorway
##   on the z-78 pair, so it is hidden here (steps, rust, logs, pots and
##   clotheslines stay).
## - StiltHouse13 (x1.7, (20,-22)) has S56 windows on both faces but NO
##   frames/sills, NO corner boards, NO door frame, NO steps (door on the
##   +z face, deck edge at local z 2.0, ground 1.65 below), NO night glows.
##   Its Trim56 band already serves as the eaves trim, so no second eaves
##   band is added. No second storey: it is a raised single-storey dwelling
##   (total height 6.9 m, already 3.6x player height).
## - School13 (x1.7, (-34,14)) is a GROUND building, so it DOES warrant the
##   full Mindon-6 treatment including a genuine second storey: upper walls
##   + windows + frames + sills, floor band, eaves band, new pitched roof
##   (old roofs hidden at runtime), pilasters, plinth, door frame, upper
##   night glows. Sign and flagpole stay on the ground floor.
## - Stilt97 rebuilds (5/6/15_4, S96) have front windows only, NO frames /
##   sills / back windows / corner boards / cornice / floor trim / door
##   frame / veranda rails. Their S96 steps already exist and are kept.
##   No second storey: raised single-storey dwellings (apex 6.4 m).
## - EF staircases (StiltHouse62, x1.5): S99's 3 entry steps rise only to
##   0.60 local while the veranda floor is at 1.35 — the veranda is still
##   unreachable. ROAD-CLEARANCE SURVEY (measured, not assumed):
##   north row (z -16, facing +z): straight 7-step stair toe lands at
##   world z -6.64, CLEAR of the EF main-road edge (z -6) by 0.64 m;
##   south row (z 16, facing -z): toe at z +6.64, same 0.64 m clearance;
##   west row (x 330, facing +x): only 1.5 m of clear ground between the
##   veranda edge (x 336) and the north dirt lane (x 337.5..342.5) — NO
##   straight stair fits, so the west pair gets SIDE staircases running
##   north along the house side (clear of the lane by 1.8 m, of the walls
##   by 0.45 m, of the stream channel (x 347..353) by 11.3 m). The S99
##   stub steps are hidden everywhere (replaced by the full staircase);
##   the S94 centre stairs on EF houses 1-2 (300/330,-16) are also hidden
##   (they sit 1.8 m from the door-aligned staircase and would double it)
##   together with the S94 front rail that crosses the stair opening.
##   The S99 front rail is split with a real stair opening (rail segment
##   -0.6..1.45 + newels); the west pair keeps its front rail and opens
##   its side rail instead. All staircases are visual-only (zero colliders,
##   like every step in this game); the EF solid stays exactly as S99 set
##   it (veranda + steps stay outside it, stated).
## - Night fill (OpenTaxi-look, look only — no assets, maps or branding
##   copied): Mindon ground-floor windows were dark (S99 lit only the upper
##   fronts); EF houses have NO window glows and only one road omni for
##   x 270..420; hamlet houses sit OUTSIDE the existing hamlet omni's
##   22 m range (26.9 m to centres) and have NO glows. Filled below.
## - East skyline: S99 built only the north band; the east horizon ends in
##   black void. Mirrored here with the north band's exact pattern.
## Rules unchanged: runtime dressing ONLY, no .tscn edits, no bus-system
## changes, minibus NOT rewired, big bus NOT rewired (Slice 81 limit),
## touch controls untouched, zero NEW colliders EXCEPT collider
## replacements sized to new envelopes (S96/S99 exception, sim-proved
## walk-around clearance, no wall traps), StandardMaterial3D only, no
## dead specular lines, no fog/SSAO/glow claims (no WorldEnvironment
## exists), no photorealism claims: stylised smooth procedural rebuilds,
## stated plainly. Runs at frame >= 200, after realism100's 180 pass.
## Counting: one item = one building treatment set, one staircase, one
## skyline band, one lamp, or one building's glow set. 49 items:
##   BUILDINGS 9: Hamlet 4, StiltHouse13 1, School 1, Stilt97 3
##   STAIRCASES 12: EF straight 10, EF side 2 (house 8's stair
##     shifted 0.9 m west in world terms: its door-aligned
##     position put its east rail inside StreamSouth62)
##   SKYLINE 1: east band
##   NIGHT 27: Mindon ground glows 6, EF glows 12, hamlet glows 4,
##     EF road lamps 3, hamlet lamps 2

static var _trim_mat: StandardMaterial3D = null
static var _plaster_mat: StandardMaterial3D = null
static var _dark_mat: StandardMaterial3D = null
static var _wood_mat: StandardMaterial3D = null
static var _glow_mat: StandardMaterial3D = null
static var _sky_mat: StandardMaterial3D = null
static var _pole_mat: StandardMaterial3D = null

var _frames: int = 0
var _done: bool = false
var _glows: Array = []
## S120: gate on night-state CHANGE, not every frame — the old
## per-frame write undid Perf120's distance culling within one
## frame. First frame always runs; after that only on change.
var _last_night := false
var _gate_once := false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism101") != null:
		return
	var n := Node3D.new()
	n.name = "Realism101"
	n.set_script(load("res://realism101.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	# S124 gate-order fix (see realism100.gd): the S120
	# change-gate ran from frame 1, BEFORE _apply (frame 200)
	# created the glows, so a fresh night load stayed dark
	# until the first daylight transition. Forcing the gate
	# on the _apply frame fixes it; afterwards change-only.
	var applied := false
	if not _done and _frames >= 200:
		_done = true
		_apply(get_parent() as Node3D)
		applied = true
	var world := get_parent() as Node3D
	if world == null:
		return
	var day := _daylight(world)
	var night := day < 0.15
	if applied or not _gate_once or night != _last_night:
		_gate_once = true
		_last_night = night
		for g in _glows:
			var m := g as Node3D
			if m != null:
				m.visible = night

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
	_wood_mat = StandardMaterial3D.new()
	_wood_mat.albedo_color = Color(0.45, 0.30, 0.18, 1.0)
	_wood_mat.roughness = 0.9
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.albedo_color = Color(1.0, 0.75, 0.45, 1.0)
	_glow_mat.emission_enabled = true
	_glow_mat.emission = Color(1.0, 0.70, 0.35, 1.0)
	_glow_mat.emission_energy_multiplier = 1.6
	_sky_mat = StandardMaterial3D.new()
	_sky_mat.albedo_color = Color(0.10, 0.12, 0.20, 1.0)
	_sky_mat.roughness = 1.0
	_pole_mat = StandardMaterial3D.new()
	_pole_mat.albedo_color = Color(0.25, 0.25, 0.25, 1.0)
	_pole_mat.roughness = 0.8

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

static func _hide_named(parent: Node, nm: String) -> void:
	if parent == null:
		return
	for c in parent.get_children():
		if String(c.name) == nm and c is Node3D:
			(c as Node3D).visible = false

static func _hide_prefix(parent: Node, prefix: String) -> void:
	if parent == null:
		return
	for c in parent.get_children():
		if String(c.name).begins_with(prefix) and c is Node3D:
			(c as Node3D).visible = false

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_mats()
	_hamlet(world)
	_stilt13(world)
	_school(world)
	_stilt97(world)
	_ef_stairs(world)
	_skyline_east(world)
	_nightfill(world)

func _hamlet(world: Node3D) -> void:
	# Local coords (group x1.8, unrotated, front = -z): posts at local
	# (+-3, +-2.5), walls 7 x 2.4 x 6 at y 2.4 (world 2.16..6.48), flat
	# roof at y 3.7, door (1 x 1.8) at (0, 2.1, -3.05), S98 front
	# windows (0.7 x 0.7) at (+-2, 2.4, -3.06) + shutters at -3.08.
	# Backs were blank. No solid existed at all — one is ADDED here.
	var centres: Array = [[2075.0, 78.0], [2125.0, 78.0], [2075.0, 98.0], [2125.0, 98.0]]
	for hi in range(4):
		var g := _find(world, "HamletHouse75_%d" % hi) as Node3D
		if g == null:
			continue
		# Front window frames + sills around the S98 windows.
		for sx in [-2.0, 2.0]:
			_box(g, Vector3(0.90, 0.90, 0.06), _trim_mat, Vector3(sx, 2.40, -3.10), "Frame101_F%d" % int(sx))
			_box(g, Vector3(0.90, 0.08, 0.10), _trim_mat, Vector3(sx, 1.98, -3.10), "Sill101_F%d" % int(sx))
			# NEW back windows + frames + sills (backs were blank).
			_box(g, Vector3(0.70, 0.70, 0.10), _dark_mat, Vector3(sx, 2.40, 3.06), "WinBack101_%d" % int(sx))
			_box(g, Vector3(0.90, 0.90, 0.06), _trim_mat, Vector3(sx, 2.40, 3.10), "FrameBack101_%d" % int(sx))
			_box(g, Vector3(0.90, 0.08, 0.10), _trim_mat, Vector3(sx, 1.98, 3.10), "SillBack101_%d" % int(sx))
		# Corner boards, eaves band, plinth skirt.
		for cx in [-3.45, 3.45]:
			for cz in [-3.02, 3.02]:
				_box(g, Vector3(0.20, 2.40, 0.06), _trim_mat, Vector3(cx, 2.40, cz), "Corner101_%d_%d" % [int(cx * 10.0), int(cz * 10.0)])
		_box(g, Vector3(7.40, 0.18, 6.40), _trim_mat, Vector3(0.0, 3.65, 0.0), "Eaves101")
		_box(g, Vector3(7.20, 0.30, 6.20), _trim_mat, Vector3(0.0, 1.20, 0.0), "Plinth101")
		# Door frame (posts + lintel) around the centred door.
		_box(g, Vector3(0.12, 1.80, 0.10), _trim_mat, Vector3(-0.56, 2.10, -3.10), "DoorFrame101_L")
		_box(g, Vector3(0.12, 1.80, 0.10), _trim_mat, Vector3(0.56, 2.10, -3.10), "DoorFrame101_R")
		_box(g, Vector3(1.24, 0.12, 0.10), _trim_mat, Vector3(0.0, 3.06, -3.10), "DoorLintel101")
		# Stair handrails for the restyle steps (z-78 pair) and the new
		# steps below (z-98 pair): sloped rails + newels, both sides.
		for sx in [-0.66, 0.66]:
			_box(g, Vector3(0.06, 0.06, 1.50), _wood_mat, Vector3(sx, 1.65, -4.10), "StairRail101_%d" % int(sx * 100.0), Vector3(-0.6435, 0.0, 0.0))
			_box(g, Vector3(0.08, 0.90, 0.08), _wood_mat, Vector3(sx, 1.65, -3.50), "StairNewelTop101_%d" % int(sx * 100.0))
			_box(g, Vector3(0.08, 1.20, 0.08), _wood_mat, Vector3(sx, 0.60, -4.70), "StairNewelBot101_%d" % int(sx * 100.0))
		# Front night glows (gated < 0.15 in _process).
		for sx in [-2.0, 2.0]:
			var gl := _box(g, Vector3(0.70, 0.70, 0.04), _glow_mat, Vector3(sx, 2.40, -3.12), "Glow101_F%d" % int(sx))
			gl.visible = false
			_glows.append(gl)
		# The z-98 pair has NO restyle stairs: build the same 4-step
		# pattern the restyle used (tops 1.20/0.90/0.60/0.30 local).
		if hi >= 2:
			for si in range(4):
				_box(g, Vector3(1.20, 0.30, 0.40), _wood_mat, Vector3(0.0, 1.05 - float(si) * 0.30, -(3.50 + float(si) * 0.40)), "Step101_%d" % si)
		# NEW solid (none existed): walls + eaves envelope, full height
		# from the ground. Steps stay outside it (visual-only, stated).
		var hx := float(centres[hi][0])
		var hz := float(centres[hi][1])
		var body := StaticBody3D.new()
		body.name = "Hamlet101Solid_%d" % hi
		body.position = Vector3(hx, 3.42, hz)
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		shape.name = "Shape101"
		var bx := BoxShape3D.new()
		bx.size = Vector3(13.32, 6.84, 11.52)
		shape.shape = bx
		body.add_child(shape)
		world.add_child(body)
	# The z-78 pair's restyle front rail crosses its doorway: hide the
	# rail assembly only (steps, rust, logs, pots, lines stay).
	for nm in ["Restyle94_2075_78", "Restyle94_2125_78"]:
		var rh := _find(world, nm) as Node3D
		if rh != null:
			_hide_named(rh, "RailTop94")
			_hide_named(rh, "RailPost94_L")
			_hide_named(rh, "RailPost94_R")

func _stilt13(world: Node3D) -> void:
	# Local coords (group x1.7, unrotated, front = +z): deck 5 x 0.3 x 4
	# at y 1.5, walls 4.6 x 2.2 x 3.6 at y 2.6 (1.5..3.7), S56 windows
	# (0.55 x 0.7) at x -1.53/0/1.53, y 2.05/3.15, z +-1.84, door
	# (0.8 x 1.4) at (0, 2.2, 1.84), flat roof at y 3.9, Trim56 band
	# at y 3.82 (already an eaves trim — no second band added).
	var g := _find(world, "StiltHouse13") as Node3D
	if g == null:
		return
	for wx in [-1.53, 0.0, 1.53]:
		for wy in [2.05, 3.15]:
			for sgn in [-1.0, 1.0]:
				_box(g, Vector3(0.75, 0.90, 0.05), _trim_mat, Vector3(wx, wy, sgn * 1.88), "Frame101_%d_%d_%d" % [int(wx * 100.0), int(wy * 100.0), int(sgn)])
				_box(g, Vector3(0.75, 0.08, 0.10), _trim_mat, Vector3(wx, wy - 0.47, sgn * 1.88), "Sill101_%d_%d_%d" % [int(wx * 100.0), int(wy * 100.0), int(sgn)])
			# Front night glows only (Mindon pattern); backs stay dark.
			var gl := _box(g, Vector3(0.55, 0.70, 0.04), _glow_mat, Vector3(wx, wy, 1.92), "Glow101_%d_%d" % [int(wx * 100.0), int(wy * 100.0)])
			gl.visible = false
			_glows.append(gl)
	for cx in [-2.25, 2.25]:
		for cz in [-1.83, 1.83]:
			_box(g, Vector3(0.20, 2.20, 0.06), _trim_mat, Vector3(cx, 2.60, cz), "Corner101_%d_%d" % [int(cx * 100.0), int(cz * 100.0)])
	# Door frame around Door56.
	_box(g, Vector3(0.12, 1.60, 0.10), _trim_mat, Vector3(-0.46, 2.20, 1.88), "DoorFrame101_L")
	_box(g, Vector3(0.12, 1.60, 0.10), _trim_mat, Vector3(0.46, 2.20, 1.88), "DoorFrame101_R")
	_box(g, Vector3(1.04, 0.12, 0.10), _trim_mat, Vector3(0.0, 2.96, 1.88), "DoorLintel101")
	# Full 6-step staircase from the deck edge (local z 2.0, deck top
	# 1.65) to the ground: rise 0.275, tread 0.35, toe at local z 4.10
	# (world z -15.03 — surveyed clear of village structures in sim).
	for si in range(6):
		_box(g, Vector3(1.20, 0.275, 0.35), _wood_mat, Vector3(0.0, 1.65 - (float(si) + 0.5) * 0.275, 2.175 + float(si) * 0.35), "Step101_%d" % si)
	for sx in [-0.60, 0.60]:
		_box(g, Vector3(0.08, 0.25, 2.67), _wood_mat, Vector3(sx, 0.75, 3.05), "StairString101_%d" % int(sx * 100.0), Vector3(0.668, 0.0, 0.0))
		_box(g, Vector3(0.06, 0.06, 2.67), _wood_mat, Vector3(sx, 1.65, 3.05), "StairRail101_%d" % int(sx * 100.0), Vector3(0.668, 0.0, 0.0))
		_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(sx, 2.06, 2.00), "StairNewelTop101_%d" % int(sx * 100.0))
		_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(sx, 0.45, 4.10), "StairNewelBot101_%d" % int(sx * 100.0))

func _school(world: Node3D) -> void:
	# Local coords (group x1.7, unrotated, front = +z): walls 8 x 3 x 6
	# at y 1.5 (0..3.0), S72 windows (1.0 x 0.8) at x -2.5/0/2.5,
	# y 1.7, z +-3.04 (frames, NO sills), door (1.2 x 2.0) at
	# (0, 1.0, 3.06), steps at z 3.5, sign + flagpole on the front.
	# Genuine second storey: upper walls 3.0..5.6, new pitched roof,
	# old roofs hidden at runtime. Sign stays on the ground floor.
	var g := _find(world, "School13") as Node3D
	if g == null:
		return
	_hide_named(g, "SchoolRoof13a")
	_hide_named(g, "SchoolRoof13b")
	_box(g, Vector3(8.0, 2.60, 6.0), _plaster_mat, Vector3(0.0, 4.30, 0.0), "Upper101")
	for wx in [-2.5, 0.0, 2.5]:
		for sgn in [-1.0, 1.0]:
			_box(g, Vector3(1.00, 0.80, 0.10), _dark_mat, Vector3(wx, 4.30, sgn * 3.04), "WinU101_%d_%d" % [int(wx * 10.0), int(sgn)])
			_box(g, Vector3(1.20, 1.00, 0.08), _trim_mat, Vector3(wx, 4.30, sgn * 3.08), "FrameU101_%d_%d" % [int(wx * 10.0), int(sgn)])
			_box(g, Vector3(1.20, 0.08, 0.10), _trim_mat, Vector3(wx, 3.86, sgn * 3.08), "SillU101_%d_%d" % [int(wx * 10.0), int(sgn)])
			# Ground-floor sills (S72 gave frames but no sills).
			_box(g, Vector3(1.20, 0.08, 0.10), _trim_mat, Vector3(wx, 1.26, sgn * 3.08), "SillG101_%d_%d" % [int(wx * 10.0), int(sgn)])
	# Upper-front night glows (Mindon pattern: between windows).
	for gx in [-1.25, 1.25]:
		var gl := _box(g, Vector3(1.00, 0.80, 0.04), _glow_mat, Vector3(gx, 4.30, 3.12), "GlowU101_%d" % int(gx * 100.0))
		gl.visible = false
		_glows.append(gl)
	_box(g, Vector3(8.40, 0.20, 6.40), _trim_mat, Vector3(0.0, 3.00, 0.0), "Band101")
	_box(g, Vector3(8.40, 0.18, 6.40), _trim_mat, Vector3(0.0, 5.60, 0.0), "Eaves101")
	_box(g, Vector3(8.40, 0.18, 3.60), _plaster_mat, Vector3(0.0, 6.05, 1.55), "Roof101_S", Vector3(-0.35, 0.0, 0.0))
	_box(g, Vector3(8.40, 0.18, 3.60), _plaster_mat, Vector3(0.0, 6.05, -1.55), "Roof101_N", Vector3(0.35, 0.0, 0.0))
	for px in [-3.90, 3.90]:
		for sgn in [-1.0, 1.0]:
			_box(g, Vector3(0.20, 3.00, 0.06), _trim_mat, Vector3(px, 1.50, sgn * 3.03), "PilasterG101_%d_%d" % [int(px * 10.0), int(sgn)])
			_box(g, Vector3(0.20, 2.60, 0.06), _trim_mat, Vector3(px, 4.30, sgn * 3.03), "PilasterU101_%d_%d" % [int(px * 10.0), int(sgn)])
	_box(g, Vector3(8.40, 0.30, 6.40), _trim_mat, Vector3(0.0, 0.15, 0.0), "Plinth101")
	_box(g, Vector3(0.12, 2.00, 0.10), _trim_mat, Vector3(-0.66, 1.00, 3.08), "DoorFrame101_L")
	_box(g, Vector3(0.12, 2.00, 0.10), _trim_mat, Vector3(0.66, 1.00, 3.08), "DoorFrame101_R")
	_box(g, Vector3(1.44, 0.12, 0.10), _trim_mat, Vector3(0.0, 2.06, 3.08), "DoorLintel101")
	# Collider match (new second storey): REPLACE the S96-scaled solid
	# with a box sized to the new envelope (walls + bands, apex 6.67
	# local = 11.34 world). Shared shape resources never mutated.
	var solid := world.get_node_or_null("SchoolSolid") as StaticBody3D
	if solid != null:
		solid.scale = Vector3.ONE
		solid.position = Vector3(-34.0, 5.67, 14.0)
		for ch in solid.get_children():
			if ch is CollisionShape3D:
				var nb := BoxShape3D.new()
				nb.size = Vector3(14.28, 11.34, 10.88)
				(ch as CollisionShape3D).shape = nb
				(ch as CollisionShape3D).position = Vector3.ZERO
	# CamBlock height to the same apex (body scale only).
	var cam := world.get_node_or_null("SchoolCamBlock") as StaticBody3D
	if cam != null:
		for ch in cam.get_children():
			if ch is CollisionShape3D:
				var sh := (ch as CollisionShape3D).shape as BoxShape3D
				if sh != null:
					var cur_h := sh.size.y * cam.scale.y
					if cur_h > 0.0:
						cam.scale.y *= 11.34 / cur_h
						cam.position.y = 11.34 * 0.5

func _stilt97(world: Node3D) -> void:
	# Local coords (unscaled, front = +z): floor 8 x 0.3 x 6 at y 1.65,
	# walls 7 x 3.2 x 6 at y 3.4 (1.8..5.0), pitched roof apex ~6.4,
	# door (0.9 x 1.9) at (0, 2.75, 3.06), front windows (0.8 x 0.9)
	# at (+-2, 2.6, 3.03), S96 steps at z 3.3..4.5 (kept).
	for tag in ["5", "6", "15_4"]:
		var g := _find(world, "Stilt97_%s" % tag) as Node3D
		if g == null:
			continue
		for sx in [-2.0, 2.0]:
			_box(g, Vector3(1.00, 1.10, 0.06), _trim_mat, Vector3(sx, 2.60, 3.08), "Frame101_F%d" % int(sx))
			_box(g, Vector3(1.00, 0.08, 0.10), _trim_mat, Vector3(sx, 2.12, 3.08), "Sill101_F%d" % int(sx))
			_box(g, Vector3(0.80, 0.90, 0.08), _dark_mat, Vector3(sx, 2.60, -3.03), "WinBack101_%d" % int(sx))
			_box(g, Vector3(1.00, 1.10, 0.06), _trim_mat, Vector3(sx, 2.60, -3.08), "FrameBack101_%d" % int(sx))
			_box(g, Vector3(1.00, 0.08, 0.10), _trim_mat, Vector3(sx, 2.12, -3.08), "SillBack101_%d" % int(sx))
		for cx in [-3.45, 3.45]:
			for cz in [-3.02, 3.02]:
				_box(g, Vector3(0.20, 3.20, 0.06), _trim_mat, Vector3(cx, 3.40, cz), "Corner101_%d_%d" % [int(cx * 100.0), int(cz * 100.0)])
		_box(g, Vector3(7.20, 0.15, 0.15), _trim_mat, Vector3(0.0, 5.00, 3.02), "Cornice101_F")
		_box(g, Vector3(7.20, 0.15, 0.15), _trim_mat, Vector3(0.0, 5.00, -3.02), "Cornice101_B")
		_box(g, Vector3(0.15, 0.15, 6.20), _trim_mat, Vector3(3.52, 5.00, 0.0), "Cornice101_L")
		_box(g, Vector3(0.15, 0.15, 6.20), _trim_mat, Vector3(-3.52, 5.00, 0.0), "Cornice101_R")
		_box(g, Vector3(8.20, 0.30, 6.20), _trim_mat, Vector3(0.0, 1.65, 0.0), "FloorTrim101")
		_box(g, Vector3(0.12, 2.00, 0.10), _trim_mat, Vector3(-0.51, 2.75, 3.10), "DoorFrame101_L")
		_box(g, Vector3(0.12, 2.00, 0.10), _trim_mat, Vector3(0.51, 2.75, 3.10), "DoorFrame101_R")
		_box(g, Vector3(1.14, 0.12, 0.10), _trim_mat, Vector3(0.0, 3.76, 3.10), "DoorLintel101")
		# Veranda rails: front rail SPLIT at the stair gap (steps at
		# x -0.7..0.7), side rails full length, posts at corners.
		_box(g, Vector3(3.30, 0.06, 0.06), _wood_mat, Vector3(-2.35, 2.70, 3.00), "VerRail101_FL")
		_box(g, Vector3(3.30, 0.06, 0.06), _wood_mat, Vector3(2.35, 2.70, 3.00), "VerRail101_FR")
		_box(g, Vector3(0.06, 0.06, 6.00), _wood_mat, Vector3(3.95, 2.70, 0.0), "VerRail101_L")
		_box(g, Vector3(0.06, 0.06, 6.00), _wood_mat, Vector3(-3.95, 2.70, 0.0), "VerRail101_R")
		for px in [-3.95, -0.70, 0.70, 3.95]:
			_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(px, 2.25, 3.00), "VerPost101_F%d" % int(px * 100.0))
		for px in [-3.95, 3.95]:
			for pz in [-3.00, 0.00]:
				_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(px, 2.25, pz), "VerPost101_S%d_%d" % [int(px * 100.0), int(pz * 100.0)])
		# Solid widened to cover the new trim (door frame to z 3.15).
		var solid := world.get_node_or_null("Stilt97Solid_%s" % tag) as StaticBody3D
		if solid != null:
			for ch in solid.get_children():
				if ch is CollisionShape3D:
					var nb := BoxShape3D.new()
					nb.size = Vector3(8.20, 6.40, 6.30)
					(ch as CollisionShape3D).shape = nb

func _ef_stairs(world: Node3D) -> void:
	# S62 stilt houses (x1.5), local coords: floor top 1.425, walls
	# 6.6 x 2.2 x 4.6 at y 2.6, veranda 3.0 x 0.15 x 1.6 at (0, 1.35,
	# 3.2), door at (-1.2, 2.4, 2.36), S99 front rail at z 4.0 with
	# posts at x -1.45/0/1.45, S99 stub steps at (-1.2, z 4.05..4.55).
	# Full staircase: 7 steps, rise 0.1929 local, tread 0.32 local,
	# from the veranda edge (z 4.0) to the ground (toe z 6.24).
	# Surveyed toe clearance: 0.64 m from the EF main-road edge for
	# the north/south rows (see header). The west pair cannot fit a
	# straight stair (1.5 m to the dirt lane) and gets a side stair.
	for i in range(12):
		var g := _find(world, "StiltHouse62_%d" % i) as Node3D
		if g == null:
			continue
		# The S99 stub steps are replaced everywhere.
		_hide_named(g, "Step100_A")
		_hide_named(g, "Step100_B")
		_hide_named(g, "Step100_C")
		if i < 10:
			# Straight door-aligned staircase + split front rail.
			# House 8 (345,16, rot pi) is the exception: its
			# door-aligned stair (world x 345.9..347.7) would put
			# its east stringer/rail inside StreamSouth62
			# (x 347..353, z 8..60). Its stair is shifted 0.9 m
			# west in world terms (local centre -1.20 -> -0.60),
			# leaving 0.2 m clear of the stream edge and half
			# the door width still served; the rail gap moves
			# with it, and the S99 centre post F1 (local 0.0)
			# is hidden instead of F0 (which serves the new
			# west rail segment).
			var sc := -1.20
			if i == 8:
				sc = -0.60
				_hide_named(g, "VerPost100_F1")
			else:
				_hide_named(g, "VerPost100_F0")
			_hide_named(g, "VerRail100_F")
			if i == 8:
				_box(g, Vector3(1.45, 0.06, 0.06), _wood_mat, Vector3(0.725, 2.35, 4.00), "VerRail101_Split")
				_box(g, Vector3(0.30, 0.06, 0.06), _wood_mat, Vector3(-1.35, 2.35, 4.00), "VerRail101_West")
			else:
				_box(g, Vector3(2.05, 0.06, 0.06), _wood_mat, Vector3(0.425, 2.35, 4.00), "VerRail101_Split")
			_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(sc - 0.60, 1.875, 4.00), "VerPost101_SplitL")
			_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(sc + 0.60, 1.875, 4.00), "VerPost101_SplitR")
			for si in range(7):
				_box(g, Vector3(1.20, 0.19, 0.32), _wood_mat, Vector3(sc, 1.35 - (float(si) + 0.5) * 0.1929, 4.16 + float(si) * 0.32), "Stair101_%d" % si)
			for sx in [sc - 0.60, sc + 0.60]:
				_box(g, Vector3(0.08, 0.25, 2.61), _wood_mat, Vector3(sx, 0.60, 5.12), "StairString101_%d" % int(sx * 100.0), Vector3(0.54, 0.0, 0.0))
				_box(g, Vector3(0.06, 0.06, 2.61), _wood_mat, Vector3(sx, 1.575, 5.12), "StairRail101_%d" % int(sx * 100.0), Vector3(0.54, 0.0, 0.0))
				_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(sx, 0.45, 6.24), "StairNewelBot101_%d" % int(sx * 100.0))
		else:
			# Side staircase: opens the side rail (local x +1.45,
			# world north for the rot-y-90 west pair) and descends
			# northward in the clear strip beside the house.
			_hide_named(g, "VerRail100_R")
			for si in range(7):
				_box(g, Vector3(0.32, 0.19, 1.20), _wood_mat, Vector3(1.61 + float(si) * 0.32, 1.35 - (float(si) + 0.5) * 0.1929, 3.20), "StairSide101_%d" % si)
			for sz in [2.60, 3.80]:
				_box(g, Vector3(2.61, 0.25, 0.08), _wood_mat, Vector3(2.61, 0.60, sz), "StairSideString101_%d" % int(sz * 100.0), Vector3(0.0, 0.0, -0.527))
				_box(g, Vector3(2.61, 0.06, 0.06), _wood_mat, Vector3(2.61, 1.575, sz), "StairSideRail101_%d" % int(sz * 100.0), Vector3(0.0, 0.0, -0.527))
				_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(1.45, 1.875, sz), "StairSideNewelTop101_%d" % int(sz * 100.0))
				_box(g, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(3.77, 0.45, sz), "StairSideNewelBot101_%d" % int(sz * 100.0))
	# EF houses 1-2: hide the S94 centre stairs (1.8 m from the new
	# door-aligned staircase — doubling them would be absurd) and
	# the S94 front rail that crosses the stair opening. Restyle
	# rails, rust, logs, pots and clotheslines stay.
	for nm in ["Restyle94_300_-16", "Restyle94_330_-16"]:
		var rh := _find(world, nm) as Node3D
		if rh != null:
			_hide_prefix(rh, "Step94_")
			_hide_named(rh, "RailTop94")
			_hide_named(rh, "RailPost94_L")
			_hide_named(rh, "RailPost94_R")

func _skyline_east(world: Node3D) -> void:
	# Mirror of the S99 north band's pattern: 16 dark boxes beyond
	# the east clamp (x 3049.5), 12..28 m tall, with 8 gated window
	# dots on their WEST faces (facing the world). Meshes only —
	# zero colliders.
	for k in range(16):
		var z := -480.0 + 60.0 * float(k)
		var x := 3910.0 + float(k % 3) * 15.0
		var h := 12.0 + float((k * 7) % 17)
		var w := 30.0 + float((k * 13) % 50)
		_box(world, Vector3(20.0, h, w), _sky_mat, Vector3(x, h * 0.5, z), "SkylineE101_%d" % k)
		if k % 2 == 0:
			var dot := _box(world, Vector3(0.10, 2.0, 1.50), _glow_mat, Vector3(x - 10.06, 6.0 + float(k % 4) * 3.0, z), "SkyDotE101_%d" % k)
			dot.visible = false
			_glows.append(dot)

func _nightfill(world: Node3D) -> void:
	# Mindon ground-floor glows (S99 lit only the upper fronts):
	# one glow per ground window pair position, both... front only,
	# 2 per building, at the S59 ground-window height.
	for nm in ["MindonPost", "MindonEdu", "MindonMRTV", "MindonShops", "MindonTemple", "MindonHospital"]:
		var g := _find(world, nm) as Node3D
		if g == null:
			continue
		for gx in [-1.40, 1.40]:
			var gl := _box(g, Vector3(0.55, 0.70, 0.04), _glow_mat, Vector3(gx, 1.70, 2.60), "GlowG101_%d" % int(gx * 100.0))
			gl.visible = false
			_glows.append(gl)
	# EF window glows: front windows (local x 1.2/2.4, y 2.7).
	for i in range(12):
		var g := _find(world, "StiltHouse62_%d" % i) as Node3D
		if g == null:
			continue
		for wx in [1.20, 2.40]:
			var gl := _box(g, Vector3(0.70, 0.70, 0.04), _glow_mat, Vector3(wx, 2.70, 2.47), "Glow101_%d" % int(wx * 100.0))
			gl.visible = false
			_glows.append(gl)
	# EF road lamps: poles clear of the 12 m road (|z| <= 6),
	# discs ON the road, omni on every lamp.
	var lamp_xs: Array = [280.0, 350.0, 420.0]
	for k in range(3):
		var x := float(lamp_xs[k])
		var side := -1.0 if k % 2 == 0 else 1.0
		_box(world, Vector3(0.12, 3.00, 0.12), _pole_mat, Vector3(x, 1.50, side * 7.50), "LampEF101_Pole%d" % k)
		var head := _box(world, Vector3(0.20, 0.12, 0.20), _glow_mat, Vector3(x, 3.05, side * 7.50), "LampEF101_Head%d" % k)
		head.visible = false
		_glows.append(head)
		var disc := _cyl(world, 2.40, 2.40, 0.02, _glow_mat, Vector3(x, 0.14, 0.0), "LampEF101_Disc%d" % k)
		disc.visible = false
		_glows.append(disc)
		var om := OmniLight3D.new()
		om.name = "LampEF101_Omni%d" % k
		om.light_color = Color(1.0, 0.75, 0.45, 1.0)
		om.light_energy = 1.5
		om.omni_range = 22.0
		om.shadow_enabled = false
		om.position = Vector3(x, 3.00, side * 7.50)
		om.visible = false
		world.add_child(om)
		_glows.append(om)
	# Hamlet lamps: midway between the two house rows (z 88),
	# 4.6 m clear of every house wall, covering all 4 houses.
	for k in range(2):
		var x := 2075.0 if k == 0 else 2125.0
		_box(world, Vector3(0.12, 3.00, 0.12), _pole_mat, Vector3(x, 1.50, 88.0), "LampHam101_Pole%d" % k)
		var head := _box(world, Vector3(0.20, 0.12, 0.20), _glow_mat, Vector3(x, 3.05, 88.0), "LampHam101_Head%d" % k)
		head.visible = false
		_glows.append(head)
		var om := OmniLight3D.new()
		om.name = "LampHam101_Omni%d" % k
		om.light_color = Color(1.0, 0.75, 0.45, 1.0)
		om.light_energy = 1.5
		om.omni_range = 22.0
		om.shadow_enabled = false
		om.position = Vector3(x, 3.00, 88.0)
		om.visible = false
		world.add_child(om)
		_glows.append(om)
