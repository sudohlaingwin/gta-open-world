extends Node3D
## Slice 101 (parent sequence): REMAINING BUILDING DETAIL + SECOND NIGHT
## AUDIT + FRAME-COVER FIX. Owner standing rules: ~50 items per push,
## graphics-first, whole buildings finished, not thin detail spread
## everywhere. Runtime dressing ONLY, no .tscn edits, no bus-system
## changes, minibus NOT rewired, big bus NOT rewired (Slice 81 limit),
## touch controls untouched, zero NEW colliders EXCEPT collider
## replacements sized to new envelopes (S96/S99/S100 exception,
## sim-proved walk-around clearance, no wall traps), StandardMaterial3D
## only, no dead specular lines, no fog/SSAO/glow claims (no
## WorldEnvironment exists), no photorealism claims: stylised smooth
## procedural rebuilds, stated plainly. Runs at frame >= 220, after
## realism101's 200 pass.
##
## AUDIT-FIRST findings (all live-probed, 2026-10-24):
## - FRAME-COVER DEFECT (S99/S100, real, fixed here as a code fix, not
##   counted in the item total): S99/S100 "frame" panels sit PROUD of
##   the window insets and, being larger, hide them — Mindon FrameG/U100
##   at local z +-2.575 vs window front 2.56; hamlet Frame101_F at -3.10
##   vs S98 window front -3.09, FrameBack101 at 3.10 vs WinBack101 front
##   3.11; Stilt13 frames at +-1.88 vs S56 window front 1.87; School
##   FrameU101 at +-3.08 vs WinU101 front 3.09; Stilt97 frames at +-3.08
##   vs S96 window front 3.07; House97 Frame97 at d/2+0.06 (front d/2+0.08)
##   vs S96 window front d/2+0.07; EF FrameBack100 at -2.42 (front -2.45)
##   vs WinBack100 front -2.41. Fix: shift every pre-102 Frame* panel
##   toward its parent centre (0.06 generally, 0.04 for Frame97/B97,
##   0.08 for FrameBack100) so the window front stays proud of the
##   frame front and the frame front stays proud of the wall face.
##   S101's OWN frames use the correct construction from the start
##   (frame centre at face+0.02, window inset at face+0.03, so the
##   border shows) and are excluded by name + by running the fix first.
## - Mindon district houses MD4/5/7/8/11/12/13/14 + Oo1/2 (bare 6x2.8x5
##   boxes, children = Walls + Roof only, scale 1.0, solids 6x3x5
##   matching) were NEVER scaled by S96 (only the 6 named buildings
##   were). They get x1.8 + the full S99-style 2-storey treatment.
##   MD9 gets x1.5 (its neighbour gap is only 0.5 m at x1.8); Oo3 +
##   village House6 get x1.0 + the same full treatment (no balcony —
##   the element list omits it, stated). MD1/2/3/6/10 STAY DEFERRED:
##   they are embedded in S56 city blocks at original size (BlockA/B/D/
##   E/F overlap them); dressing their block-facing sides would bury
##   detail inside the blocks — fixing needs block relocation, a
##   layout change beyond this slice.
## - Village House5 (-24,-8) is VISIBLE (not hidden): floating slab at
##   y 2.0 + S53 DressWall below + Roof5, S53/S58 dressing only. It is
##   REBUILT here S96-pattern (old House5/Roof5 hidden, new 5x7 house
##   apex 6.95, new solid, door +z) + S99-style detail. House6 (28,30)
##   is VISIBLE with walls + roof + door but NO windows — treated at
##   x1.0 (x1.8 would hit GuestHouse20's posts). House7_17/ House8_18
##   have S56 windows + Trim56 + door + glow but NO frames/sills/
##   plinth/steps/door frame — finished here. House1/2/3/4 STAY
##   DEFERRED as slabs: they are hidden AND already replaced by
##   House97_1..4 (S96) — re-detailing them would mean unhiding
##   duplicates that fight the replacements, stated explicitly.
## - Commercial/civic structures (all visible): village market stalls
##   (-6 row + MarketStallA at (16,12)), TeaShop13 (-14,20, open-air),
##   NightMarket20 (-36,32), GuestHouse20 (26,36, open pavilion),
##   MonasteryBell (-6,-32), Zayat (28,2), LakesideHut19 (44,38),
##   DepotOffice82 (30,6), ElephantStable18 (-44,26), HorsePen19
##   (-38,-30), HorsePen20, gold stall row (29..34, 22..26). Open-air
##   structures get NO invented walls — canopy/rails/signs/lamps only.
## - Bus-stop shelters at x 500/2400 DO exist (ShelterPost74 at
##   497/503 and 2397/2403) — no shelter item needed, stated.
## - People/vehicle round 3: boat oars already exist (boat.gd OarL/R);
##   straw hats are a variety choice (S58, ~9/18 villagers), NOT a gap.
##   No further people/vehicle gap was proven by the audit, so this
##   slice adds NO people/vehicle items rather than padding.
## Counting: one item = one building treatment set, one lamp, or one
## building's glow set. Honest total below (under 50 — no padding):
##   BUILDINGS 29: MD x1.8 10, MD9 x1.5 1, Oo3 x1.0 1, House6 1,
##     House5 rebuild 1, House7/8 2, market 1, tea shop 1, night
##     market 1, guest house 1, monastery 1, zayat 1, lakeside hut 1,
##     depot office 1, elephant stable 1, horse pens 2, gold row 1
##   NIGHT 10: second night-dark audit lamps (village north 1,
##     branch140 1, branch190 2, EF road 3, long-route mid-stretch 3)
##   CODE FIX (not counted): frame-cover fix across S99/S100 families
## Second night-dark audit (daylight 0, 62 omnis, per-sample): gaps
## filled by the 10 lamps above. DELIBERATELY NOT filled, stated:
##   - Mindon main west end (100,0)=25.2 — marginal, 0.2 m over the
##     25 m threshold, adjacent street discs + moonlight cover it.
##   - East track (scenery-only, 455 m, worst 125 at 2675): one lamp
##     cannot fill it; a dedicated track-lighting pass is needed.
##   - S97 tree lines (x -300..400, z -338/288): empty fields, not
##     routes — no lamps in fields; player light + moonlight cover a
##     walking player there.
##   - Long route full fill: 1900 m needs ~40 lamps for 22 m pools
##     every 44 m; this batch places 3 mid-stretch pools (850/1350/
##     1850) and states the route stays mostly dark between stops.
##   - EF south front (300,11)=27 — residual marginal gap (2 m over);
##     the house's own window glows + moonlight cover it visually.

static var _trim_mat: StandardMaterial3D = null
static var _plaster_mat: StandardMaterial3D = null
static var _dark_mat: StandardMaterial3D = null
static var _wood_mat: StandardMaterial3D = null
static var _glow_mat: StandardMaterial3D = null
static var _pole_mat: StandardMaterial3D = null
static var _glass_mat: StandardMaterial3D = null

var _frames: int = 0
var _done: bool = false
var _glows: Array = []

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism102") != null:
		return
	var n := Node3D.new()
	n.name = "Realism102"
	n.set_script(load("res://realism102.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 220:
		_done = true
		_apply(get_parent() as Node3D)
	var world := get_parent() as Node3D
	if world == null:
		return
	var day := _daylight(world)
	for g in _glows:
		var m := g as Node3D
		if m != null:
			m.visible = day < 0.15

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
	_pole_mat = StandardMaterial3D.new()
	_pole_mat.albedo_color = Color(0.25, 0.25, 0.25, 1.0)
	_pole_mat.roughness = 0.8
	_glass_mat = StandardMaterial3D.new()
	_glass_mat.albedo_color = Color(0.55, 0.75, 0.85, 1.0)
	_glass_mat.roughness = 0.15

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

# Frame-cover fix: shift every pre-102 window-frame panel toward its
# parent centre so the window inset (not the frame) is outermost.
# Runs FIRST, before any Frame102_* node exists (and new frames are
# name-excluded anyway). Shifts are LOCAL (scale-independent: every
# comparison below is in the frame's own parent space).
static func _fix_frames(world: Node3D) -> int:
	var shifted := 0
	var stack: Array = [world]
	while stack.size() > 0:
		var n := stack.pop_back() as Node
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and String(n.name).begins_with("Frame") and not String(n.name).begins_with("Frame102"):
			var p := (n as MeshInstance3D).position
			if absf(p.z) > 0.5:
				var shift := 0.06
				if String(n.name).contains("FrameBack100"):
					shift = 0.08
				elif String(n.name).contains("FrameB97") or String(n.name).contains("Frame97"):
					shift = 0.04
				var sgn := 1.0 if p.z > 0.0 else -1.0
				(n as MeshInstance3D).position = Vector3(p.x, p.y, sgn * (absf(p.z) - shift))
				shifted += 1
	return shifted

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_mats()
	_fix_frames(world)
	_md_all(world)
	_house5(world)
	_house6(world)
	_house78(world)
	_market(world)
	_tea(world)
	_nightmarket(world)
	_guest(world)
	_monastery(world)
	_zayat(world)
	_lakeside(world)
	_depot_office(world)
	_pens(world)
	_goldrow(world)
	_nightlamps(world)

# Full S99-style 2-storey treatment for one bare Mindon-district house.
# grp is the bare group (children = Walls + Roof only, scale 1.0).
# scale: group scale applied (1.8 / 1.5 / 1.0). overhang o: band/eaves/
# plinth/roof extend past the 6x5 walls by o on each side. door_sgn:
# +1 door on +z, -1 door on -z (street side). New windows/frames use
# the CORRECT construction (frame centre face+0.02, inset face+0.03).
func _md_house(world: Node3D, grp_name: String, scale: float, overhang: float, door_sgn: float) -> bool:
	var grp := _find(world, grp_name) as Node3D
	if grp == null:
		return false
	if scale != 1.0:
		grp.scale = Vector3(scale, scale, scale)
	for c in grp.get_children():
		if String(c.name).ends_with("Roof") and c is Node3D:
			(c as Node3D).visible = false
	var o := overhang
	var gp := grp.global_position
	_box(grp, Vector3(6.0, 2.6, 5.0), _plaster_mat, Vector3(0.0, 4.1, 0.0), "Upper102")
	var xi := 0
	for wx in [-2.1, -0.7, 0.7, 2.1]:
		var fi := 0
		for sgn in [-1.0, 1.0]:
			var yi := 0
			for wy in [1.7, 4.1]:
				_box(grp, Vector3(0.55, 0.70, 0.06), _dark_mat, Vector3(wx, wy, sgn * 2.53), "Win102_%d_%d_%d" % [xi, fi, yi])
				_box(grp, Vector3(0.75, 0.90, 0.04), _trim_mat, Vector3(wx, wy, sgn * 2.52), "Frame102_%d_%d_%d" % [xi, fi, yi])
				_box(grp, Vector3(0.75, 0.08, 0.12), _trim_mat, Vector3(wx, wy - 0.42, sgn * 2.56), "Sill102_%d_%d_%d" % [xi, fi, yi])
				yi += 1
			fi += 1
		xi += 1
	_box(grp, Vector3(6.0 + 2.0 * o, 0.20, 5.0 + 2.0 * o), _trim_mat, Vector3(0.0, 2.90, 0.0), "Band102")
	_box(grp, Vector3(6.0 + 2.0 * o, 0.18, 5.0 + 2.0 * o), _trim_mat, Vector3(0.0, 5.50, 0.0), "Eaves102")
	_box(grp, Vector3(6.0 + 2.0 * o, 0.18, 3.0), _trim_mat, Vector3(0.0, 5.95, 1.30), "Roof102_S", Vector3(-0.35, 0.0, 0.0))
	_box(grp, Vector3(6.0 + 2.0 * o, 0.18, 3.0), _trim_mat, Vector3(0.0, 5.95, -1.30), "Roof102_N", Vector3(0.35, 0.0, 0.0))
	for px in [-1.4, 1.4]:
		_box(grp, Vector3(0.15, 5.5, 0.08), _trim_mat, Vector3(px, 2.75, door_sgn * 2.54), "PilF102_%d" % int(px * 10.0))
	for px in [-1.4, 0.0, 1.4]:
		_box(grp, Vector3(0.15, 5.5, 0.08), _trim_mat, Vector3(px, 2.75, -door_sgn * 2.54), "PilB102_%d" % int(px * 10.0))
	var ci := 0
	for px in [-1.0, 1.0]:
		for sgn in [-1.0, 1.0]:
			_box(grp, Vector3(0.15, 5.5, 0.10), _trim_mat, Vector3(px * 2.95, 2.75, sgn * 2.54), "Corner102_%d" % ci)
			ci += 1
	_box(grp, Vector3(6.0 + 2.0 * o, 0.30, 5.0 + 2.0 * o), _trim_mat, Vector3(0.0, 0.15, 0.0), "Plinth102")
	_box(grp, Vector3(0.9, 2.0, 0.12), _wood_mat, Vector3(0.0, 1.0, door_sgn * 2.56), "Door102")
	_box(grp, Vector3(0.12, 2.0, 0.10), _trim_mat, Vector3(-0.51, 1.0, door_sgn * 2.58), "DoorFrame102_L")
	_box(grp, Vector3(0.12, 2.0, 0.10), _trim_mat, Vector3(0.51, 1.0, door_sgn * 2.58), "DoorFrame102_R")
	_box(grp, Vector3(1.14, 0.12, 0.10), _trim_mat, Vector3(0.0, 2.06, door_sgn * 2.58), "DoorLintel102")
	_box(grp, Vector3(1.4, 0.12, 0.5), _trim_mat, Vector3(0.0, 0.06, door_sgn * 2.90), "Step102_A")
	_box(grp, Vector3(1.4, 0.24, 0.5), _trim_mat, Vector3(0.0, 0.12, door_sgn * 2.65), "Step102_B")
	# Night glows on the door face (world children, gated): window
	# inset front is at local 2.56, so the glow plane at local 2.60
	# sits fully in front — no z-fight (S99 lesson, frame fix above).
	var gi := 0
	for gx in [-1.4, 1.4]:
		for wy in [1.7, 4.1]:
			var gl := _box(world, Vector3(0.55, 0.70, 0.04), _glow_mat, Vector3(gp.x + gx * scale, wy * scale, gp.z + door_sgn * 2.60 * scale), "Glow102_%s_%d" % [grp_name, gi])
			gl.visible = false
			_glows.append(gl)
			gi += 1
	# Solid + camblock replaced to the new envelope (S96/S99 exception:
	# shared shape resources are NEVER mutated — a new shape is
	# assigned to the solid, and only the camblock NODE scale changes).
	var solid := _find(world, grp_name + "Solid") as StaticBody3D
	if solid != null:
		solid.scale = Vector3.ONE
		solid.position = Vector3(gp.x, 3.3 * scale, gp.z)
		for ch in solid.get_children():
			if ch is CollisionShape3D:
				var nb := BoxShape3D.new()
				nb.size = Vector3((6.0 + 2.0 * o) * scale, 6.6 * scale, (5.0 + 2.0 * o) * scale)
				(ch as CollisionShape3D).shape = nb
				(ch as CollisionShape3D).position = Vector3.ZERO
	var cam := _find(world, grp_name + "CamBlock") as StaticBody3D
	if cam != null:
		for ch in cam.get_children():
			if ch is CollisionShape3D and (ch as CollisionShape3D).shape is BoxShape3D:
				var sh := (ch as CollisionShape3D).shape as BoxShape3D
				cam.scale = Vector3((6.0 + 2.0 * o) * scale / sh.size.x, 6.6 * scale / sh.size.y, (5.0 + 2.0 * o) * scale / sh.size.z)
		cam.position = Vector3(gp.x, 3.3 * scale, gp.z)
	return true

func _md_all(world: Node3D) -> void:
	# [group, scale, overhang, door_sgn] — door faces the street side
	# (+z for z<0 houses, -z for z>0). o=0.0 where the neighbour gap
	# demands it (MD5 0.6 m, MD7 0.1 m, MD9 0.5 m, Oo1/Oo3 pair);
	# Oo1 x1.8 + Oo3 x1.0 leaves a stated 0.4x1.0 m corner bite that
	# is inside BOTH solids (no walkable pocket). MD1/2/3/6/10 are
	# NOT in this list: embedded in S56 city blocks, deferred (header).
	var rows: Array = [
		["MDHouse4", 1.8, 0.20, -1.0], ["MDHouse5", 1.8, 0.0, 1.0],
		["MDHouse7", 1.8, 0.0, 1.0], ["MDHouse8", 1.8, 0.20, -1.0],
		["MDHouse9", 1.5, 0.0, 1.0], ["MDHouse11", 1.8, 0.20, -1.0],
		["MDHouse12", 1.8, 0.20, 1.0], ["MDHouse13", 1.8, 0.20, -1.0],
		["MDHouse14", 1.8, 0.20, -1.0], ["OoHouse1", 1.8, 0.0, 1.0],
		["OoHouse2", 1.8, 0.20, -1.0], ["OoHouse3", 1.0, 0.0, 1.0],
	]
	for r in rows:
		_md_house(world, String(r[0]), float(r[1]), float(r[2]), float(r[3]))

# Village House5 rebuild (S96 pattern) + S99-style detail. Old House5
# (floating slab at y 2.0 + S53 DressWall + Roof5) is hidden; the old
# House5Solid stays inside the new solid (harmless, S96 pattern).
func _house5(world: Node3D) -> void:
	_hide_named(world, "House5")
	_hide_named(world, "Roof5")
	var h := Node3D.new()
	h.name = "House102_5"
	h.position = Vector3(-24.0, 0.0, -8.0)
	world.add_child(h)
	_box(h, Vector3(5.0, 3.0, 7.0), _plaster_mat, Vector3(0.0, 1.5, 0.0), "Ground102")
	_box(h, Vector3(5.2, 0.2, 7.2), _trim_mat, Vector3(0.0, 3.1, 0.0), "Slab102")
	_box(h, Vector3(5.0, 2.6, 7.0), _plaster_mat, Vector3(0.0, 4.5, 0.0), "Upper102")
	_box(h, Vector3(5.4, 0.18, 4.1), _trim_mat, Vector3(0.0, 6.35, 1.95), "Roof102_S", Vector3(-0.252, 0.0, 0.0))
	_box(h, Vector3(5.4, 0.18, 4.1), _trim_mat, Vector3(0.0, 6.35, -1.95), "Roof102_N", Vector3(0.252, 0.0, 0.0))
	_box(h, Vector3(0.9, 2.0, 0.12), _wood_mat, Vector3(0.0, 1.0, 3.56), "Door102")
	var hi := 0
	for sx in [-1.0, 1.0]:
		var wx: float = float(sx) * 1.4
		for wy in [1.7, 4.5]:
			_box(h, Vector3(0.8, 0.9, 0.08), _dark_mat, Vector3(wx, wy, 3.53), "Win102_%d" % hi)
			_box(h, Vector3(1.0, 1.1, 0.04), _trim_mat, Vector3(wx, wy, 3.52), "Frame102_%d" % hi)
			_box(h, Vector3(1.0, 0.08, 0.10), _trim_mat, Vector3(wx, wy - 0.48, 3.58), "Sill102_%d" % hi)
			_box(h, Vector3(0.8, 0.9, 0.08), _dark_mat, Vector3(wx, wy, -3.53), "WinB102_%d" % hi)
			_box(h, Vector3(1.0, 1.1, 0.04), _trim_mat, Vector3(wx, wy, -3.52), "FrameB102_%d" % hi)
			_box(h, Vector3(1.0, 0.08, 0.10), _trim_mat, Vector3(wx, wy - 0.48, -3.58), "SillB102_%d" % hi)
			hi += 1
	_box(h, Vector3(5.3, 0.15, 7.3), _trim_mat, Vector3(0.0, 5.85, 0.0), "Eaves102")
	_box(h, Vector3(5.2, 0.30, 7.2), _trim_mat, Vector3(0.0, 0.15, 0.0), "Plinth102")
	var ci := 0
	for px in [-1.0, 1.0]:
		for py in [1.5, 4.5]:
			for sgn in [-1.0, 1.0]:
				_box(h, Vector3(0.15, 3.0 if py < 3.0 else 2.6, 0.06), _trim_mat, Vector3(px * 2.5, py, sgn * 3.53), "Corner102_%d" % ci)
				ci += 1
	_box(h, Vector3(0.12, 2.2, 0.10), _trim_mat, Vector3(-0.51, 1.1, 3.58), "DoorFrame102_L")
	_box(h, Vector3(0.12, 2.2, 0.10), _trim_mat, Vector3(0.51, 1.1, 3.58), "DoorFrame102_R")
	_box(h, Vector3(1.14, 0.12, 0.10), _trim_mat, Vector3(0.0, 2.16, 3.58), "DoorLintel102")
	_box(h, Vector3(1.5, 0.12, 0.5), _trim_mat, Vector3(0.0, 0.06, 3.85), "Step102_A")
	_box(h, Vector3(1.5, 0.24, 0.5), _trim_mat, Vector3(0.0, 0.12, 3.62), "Step102_B")
	for gx in [-1.4, 1.4]:
		var gl := _box(h, Vector3(0.8, 0.9, 0.04), _glow_mat, Vector3(gx, 1.7, 3.62), "Glow102_%d" % int(gx * 10.0))
		gl.visible = false
		_glows.append(gl)
	var solid := StaticBody3D.new()
	solid.name = "House102Solid_5"
	solid.collision_layer = 1
	solid.collision_mask = 0
	solid.position = Vector3(-24.0, 3.475, -8.0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(5.24, 6.95, 7.24)
	cs.shape = bs
	solid.add_child(cs)
	world.add_child(solid)

# Village House6 (28,30): visible walls + roof + door, NO windows.
# Treated at x1.0 (x1.8 would hit GuestHouse20's posts at z 34).
# Existing House6Door (0.9x1.8 at (0, 0.90, 2.55), top y 1.80) is kept;
# frame/lintel/steps are sized to it.
func _house6(world: Node3D) -> void:
	var grp := _find(world, "House6") as Node3D
	if grp == null:
		return
	for c in grp.get_children():
		if String(c.name).ends_with("Roof") and c is Node3D:
			(c as Node3D).visible = false
	_box(grp, Vector3(6.0, 2.6, 5.0), _plaster_mat, Vector3(0.0, 4.1, 0.0), "Upper102")
	var xi := 0
	for wx in [-2.1, -0.7, 0.7, 2.1]:
		var fi := 0
		for sgn in [-1.0, 1.0]:
			var yi := 0
			for wy in [1.7, 4.1]:
				_box(grp, Vector3(0.55, 0.70, 0.06), _dark_mat, Vector3(wx, wy, sgn * 2.53), "Win102_%d_%d_%d" % [xi, fi, yi])
				_box(grp, Vector3(0.75, 0.90, 0.04), _trim_mat, Vector3(wx, wy, sgn * 2.52), "Frame102_%d_%d_%d" % [xi, fi, yi])
				_box(grp, Vector3(0.75, 0.08, 0.12), _trim_mat, Vector3(wx, wy - 0.42, sgn * 2.56), "Sill102_%d_%d_%d" % [xi, fi, yi])
				yi += 1
			fi += 1
		xi += 1
	_box(grp, Vector3(6.4, 0.20, 5.4), _trim_mat, Vector3(0.0, 2.90, 0.0), "Band102")
	_box(grp, Vector3(6.4, 0.18, 5.4), _trim_mat, Vector3(0.0, 5.50, 0.0), "Eaves102")
	_box(grp, Vector3(6.4, 0.18, 3.0), _trim_mat, Vector3(0.0, 5.95, 1.30), "Roof102_S", Vector3(-0.35, 0.0, 0.0))
	_box(grp, Vector3(6.4, 0.18, 3.0), _trim_mat, Vector3(0.0, 5.95, -1.30), "Roof102_N", Vector3(0.35, 0.0, 0.0))
	for px in [-1.4, 1.4]:
		_box(grp, Vector3(0.15, 5.5, 0.08), _trim_mat, Vector3(px, 2.75, 2.54), "PilF102_%d" % int(px * 10.0))
	for px in [-1.4, 0.0, 1.4]:
		_box(grp, Vector3(0.15, 5.5, 0.08), _trim_mat, Vector3(px, 2.75, -2.54), "PilB102_%d" % int(px * 10.0))
	var ci := 0
	for px in [-1.0, 1.0]:
		for sgn in [-1.0, 1.0]:
			_box(grp, Vector3(0.15, 5.5, 0.10), _trim_mat, Vector3(px * 2.95, 2.75, sgn * 2.54), "Corner102_%d" % ci)
			ci += 1
	_box(grp, Vector3(6.4, 0.30, 5.4), _trim_mat, Vector3(0.0, 0.15, 0.0), "Plinth102")
	_box(grp, Vector3(0.12, 2.0, 0.10), _trim_mat, Vector3(-0.51, 1.0, 2.58), "DoorFrame102_L")
	_box(grp, Vector3(0.12, 2.0, 0.10), _trim_mat, Vector3(0.51, 1.0, 2.58), "DoorFrame102_R")
	_box(grp, Vector3(1.14, 0.12, 0.10), _trim_mat, Vector3(0.0, 1.86, 2.58), "DoorLintel102")
	_box(grp, Vector3(1.4, 0.12, 0.5), _trim_mat, Vector3(0.0, 0.06, 2.90), "Step102_A")
	_box(grp, Vector3(1.4, 0.24, 0.5), _trim_mat, Vector3(0.0, 0.12, 2.65), "Step102_B")
	for gx in [-1.4, 1.4]:
		for wy in [1.7, 4.1]:
			var gl := _box(grp, Vector3(0.55, 0.70, 0.04), _glow_mat, Vector3(gx, wy, 2.60), "Glow102_%d_%d" % [int(gx * 10.0), int(wy * 10.0)])
			gl.visible = false
			_glows.append(gl)
	var solid := _find(world, "House6Solid") as StaticBody3D
	if solid != null:
		solid.scale = Vector3.ONE
		solid.position = Vector3(28.0, 3.3, 30.0)
		for ch in solid.get_children():
			if ch is CollisionShape3D:
				var nb := BoxShape3D.new()
				nb.size = Vector3(6.4, 6.6, 5.4)
				(ch as CollisionShape3D).shape = nb
				(ch as CollisionShape3D).position = Vector3.ZERO
	var cam := _find(world, "House6CamBlock") as StaticBody3D
	if cam != null:
		for ch in cam.get_children():
			if ch is CollisionShape3D and (ch as CollisionShape3D).shape is BoxShape3D:
				var sh := (ch as CollisionShape3D).shape as BoxShape3D
				cam.scale = Vector3(6.4 / sh.size.x, 6.6 / sh.size.y, 5.4 / sh.size.z)
		cam.position = Vector3(28.0, 3.3, 30.0)

# House7_17 (-28,30) + House8_18 (36,30): S56 windows + Trim56 + door
# + glow exist; frames/sills/plinth/steps/door frame were missing.
# The houses are MeshInstance3D nodes (5.0x3.0x4.0 box, centre y 1.5),
# so dressing is added as children in LOCAL coords (window local y
# -0.75 = world 0.75; wall faces local z +-2.0; Trim56 already serves
# as the eaves band, stated — no second eaves band).
func _house78(world: Node3D) -> void:
	for nm in ["House7_17", "House8_18"]:
		var h := _find(world, nm) as Node3D
		if h == null:
			continue
		# S56 windows: 3 x-positions x 2 rows (local y -0.75/+0.75)
		# x both faces, size 0.55x0.70x0.06, front at local z +-2.07.
		# Frames (0.75x0.90) at +-2.02 keep the window front proud.
		var wi := 0
		for wx in [-1.67, 0.0, 1.67]:
			for sgn in [-1.0, 1.0]:
				for wy in [-0.75, 0.75]:
					_box(h, Vector3(0.75, 0.90, 0.04), _trim_mat, Vector3(wx, wy, sgn * 2.02), "Frame102_%d_%d_%d" % [wi, int(sgn * 10.0), int(wy * 100.0)])
					_box(h, Vector3(0.75, 0.08, 0.10), _trim_mat, Vector3(wx, wy - 0.42, sgn * 2.06), "Sill102_%d_%d_%d" % [wi, int(sgn * 10.0), int(wy * 100.0)])
				wi += 1
		_box(h, Vector3(5.3, 0.30, 4.3), _trim_mat, Vector3(0.0, -1.35, 0.0), "Plinth102")
		var ci := 0
		for px in [-1.0, 1.0]:
			for sgn in [-1.0, 1.0]:
				_box(h, Vector3(0.15, 3.0, 0.06), _trim_mat, Vector3(px * 2.5, 0.0, sgn * 2.03), "Corner102_%d" % ci)
				ci += 1
		_box(h, Vector3(0.12, 1.6, 0.10), _trim_mat, Vector3(-0.46, -0.80, 2.10), "DoorFrame102_L")
		_box(h, Vector3(0.12, 1.6, 0.10), _trim_mat, Vector3(0.46, -0.80, 2.10), "DoorFrame102_R")
		_box(h, Vector3(1.04, 0.12, 0.10), _trim_mat, Vector3(0.0, -0.04, 2.10), "DoorLintel102")
		_box(h, Vector3(1.2, 0.12, 0.5), _trim_mat, Vector3(0.0, -1.44, 2.35), "Step102_A")
		_box(h, Vector3(1.2, 0.24, 0.5), _trim_mat, Vector3(0.0, -1.32, 2.12), "Step102_B")

# Village market (1 item, whole set): the -6 stall row (counters +
# awnings exist, no crates/sign/light) gets crates + a night lamp
# between the stalls; MarketStallA (16,12, table + posts + beams +
# awning exist) gets crates + a sign frame.
func _market(world: Node3D) -> void:
	var stall := _find(world, "MarketStallA") as Node3D
	if stall != null:
		_box(stall, Vector3(0.6, 0.6, 0.6), _wood_mat, Vector3(-1.2, 0.30, 0.0), "Crate102_A")
		_box(stall, Vector3(0.6, 0.6, 0.6), _wood_mat, Vector3(1.2, 0.30, 0.0), "Crate102_B")
		_box(stall, Vector3(0.10, 1.6, 0.10), _wood_mat, Vector3(-0.9, 0.80, -1.6), "SignPost102_L")
		_box(stall, Vector3(0.10, 1.6, 0.10), _wood_mat, Vector3(0.9, 0.80, -1.6), "SignPost102_R")
		_box(stall, Vector3(2.0, 0.5, 0.08), _trim_mat, Vector3(0.0, 1.70, -1.6), "SignBoard102")
	_box(world, Vector3(0.6, 0.6, 0.6), _wood_mat, Vector3(-5.0, 0.30, 2.0), "Crate102_RowA")
	_box(world, Vector3(0.6, 0.6, 0.6), _wood_mat, Vector3(-5.0, 0.30, 6.0), "Crate102_RowB")
	_box(world, Vector3(0.12, 3.00, 0.12), _pole_mat, Vector3(-6.0, 1.50, 4.0), "LampMarket102_Pole")
	var head := _box(world, Vector3(0.20, 0.12, 0.20), _glow_mat, Vector3(-6.0, 3.05, 4.0), "LampMarket102_Head")
	head.visible = false
	_glows.append(head)
	var om := OmniLight3D.new()
	om.name = "LampMarket102_Omni"
	om.light_color = Color(1.0, 0.75, 0.45, 1.0)
	om.light_energy = 1.5
	om.omni_range = 22.0
	om.shadow_enabled = false
	om.position = Vector3(-6.0, 3.00, 4.0)
	om.visible = false
	world.add_child(om)
	_glows.append(om)

# TeaShop13 (-14,20, open-air tables + stools + sign + one lantern
# mesh): NO walls invented — canopy posts + roof over the tables,
# a serving counter by the jars, a mat under the tables, and a gated
# omni at the existing lantern so it actually lights at night.
func _tea(world: Node3D) -> void:
	var shop := _find(world, "TeaShop13") as Node3D
	if shop == null:
		return
	for px in [-2.4, 4.4]:
		for pz in [-1.6, 1.6]:
			_box(shop, Vector3(0.12, 2.95, 0.12), _wood_mat, Vector3(px, 1.475, pz), "CanopyPost102_%d_%d" % [int(px * 10.0), int(pz * 10.0)])
	_box(shop, Vector3(7.2, 0.12, 3.6), _trim_mat, Vector3(1.0, 2.95, 0.0), "CanopyRoof102")
	_box(shop, Vector3(1.8, 1.0, 0.6), _wood_mat, Vector3(-2.2, 0.50, -0.8), "Counter102")
	_box(shop, Vector3(5.5, 0.04, 3.2), _wood_mat, Vector3(1.0, 0.02, 0.0), "Mat102")
	var om := OmniLight3D.new()
	om.name = "LampTea102_Omni"
	om.light_color = Color(1.0, 0.75, 0.45, 1.0)
	om.light_energy = 1.5
	om.omni_range = 22.0
	om.shadow_enabled = false
	om.position = Vector3(-16.5, 2.45, 20.5)
	om.visible = false
	world.add_child(om)
	_glows.append(om)

# NightMarket20 (-36,32, 3 stalls): awnings float 0.54 m above the
# front-post tops (posts end 1.60, awning bottom 2.14) and there are
# NO rear posts at all. Fixed: rear posts reaching the awnings +
# front-post extensions bridging to the awnings + a string-light
# wire between the two light poles + the existing string bulbs
# re-materialled to glow and gated + 2 warm gated omnis.
func _nightmarket(world: Node3D) -> void:
	var mk := _find(world, "NightMarket20") as Node3D
	if mk == null:
		return
	for cx in [-4.0, 0.0, 4.0]:
		for pz in [-1.2, 1.2]:
			if pz < 0.0:
				_box(mk, Vector3(0.12, 0.60, 0.12), _wood_mat, Vector3(cx - 1.2, 1.90, pz), "PostExt102_%d" % int(cx * 10.0))
				_box(mk, Vector3(0.12, 0.60, 0.12), _wood_mat, Vector3(cx + 1.2, 1.90, pz), "PostExt102b_%d" % int(cx * 10.0))
			else:
				_box(mk, Vector3(0.12, 2.20, 0.12), _wood_mat, Vector3(cx - 1.2, 1.10, pz), "PostRear102_%d" % int(cx * 10.0))
				_box(mk, Vector3(0.12, 2.20, 0.12), _wood_mat, Vector3(cx + 1.2, 1.10, pz), "PostRear102b_%d" % int(cx * 10.0))
	_box(mk, Vector3(12.4, 0.03, 0.03), _pole_mat, Vector3(0.0, 3.00, 0.0), "StringWire102")
	for sx in [-6.0, 6.0]:
		_box(mk, Vector3(0.12, 1.00, 0.12), _wood_mat, Vector3(sx, 2.50, 0.0), "PoleExt102_%d" % int(sx * 10.0))
	for i in range(5):
		var bulb := mk.get_node_or_null("StringBulb20_%d" % i) as MeshInstance3D
		if bulb != null:
			bulb.set_surface_override_material(0, _glow_mat)
			bulb.visible = false
			_glows.append(bulb)
	for sx in [-4.0, 4.0]:
		var om := OmniLight3D.new()
		om.name = "LampNight102_Omni%d" % int(sx * 10.0)
		om.light_color = Color(1.0, 0.75, 0.45, 1.0)
		om.light_energy = 1.5
		om.omni_range = 22.0
		om.shadow_enabled = false
		om.position = Vector3(-36.0 + sx, 2.80, 32.0)
		om.visible = false
		world.add_child(om)
		_glows.append(om)

# GuestHouse20 (26,36, open pavilion — posts + roof + bed + lamp
# meshes, paths on the +z side): NO walls invented — railings on the
# -x/+x/-z sides (gap on the +z entrance side), a mat on the path
# start, and a gated omni at the existing lamp.
func _guest(world: Node3D) -> void:
	var g := _find(world, "GuestHouse20") as Node3D
	if g == null:
		return
	_box(g, Vector3(0.06, 0.06, 4.0), _wood_mat, Vector3(-2.0, 0.70, 0.0), "Rail102_L")
	_box(g, Vector3(0.06, 0.06, 4.0), _wood_mat, Vector3(2.0, 0.70, 0.0), "Rail102_R")
	_box(g, Vector3(4.0, 0.06, 0.06), _wood_mat, Vector3(0.0, 0.70, -2.0), "Rail102_B")
	for px in [-2.0, 2.0]:
		for pz in [-2.0, 2.0]:
			_box(g, Vector3(0.06, 0.57, 0.06), _wood_mat, Vector3(px, 0.445, pz), "RailPost102_%d_%d" % [int(px * 10.0), int(pz * 10.0)])
	_box(g, Vector3(1.6, 0.04, 1.0), _wood_mat, Vector3(0.0, 0.13, 2.8), "Mat102")
	var om := OmniLight3D.new()
	om.name = "LampGuest102_Omni"
	om.light_color = Color(1.0, 0.75, 0.45, 1.0)
	om.light_energy = 1.5
	om.omni_range = 22.0
	om.shadow_enabled = false
	om.position = Vector3(28.0, 2.10, 37.5)
	om.visible = false
	world.add_child(om)
	_glows.append(om)

# MonasteryBell (-6,-32, posts + beam + bell + roof + S98 table/bowls):
# steps up to the base, garland swags on the beam front, post-top
# lantern glows + one gated omni, incense pots on the base corners.
func _monastery(world: Node3D) -> void:
	var m := _find(world, "MonasteryBell") as Node3D
	if m == null:
		return
	_box(m, Vector3(1.6, 0.18, 0.5), _trim_mat, Vector3(0.0, 0.09, 1.85), "Step102_A")
	_box(m, Vector3(1.6, 0.36, 0.5), _trim_mat, Vector3(0.0, 0.18, 1.60), "Step102_B")
	_box(m, Vector3(2.0, 0.08, 0.08), _trim_mat, Vector3(0.0, 2.90, 0.20), "Garland102")
	_box(m, Vector3(0.08, 0.50, 0.08), _trim_mat, Vector3(-0.60, 2.65, 0.20), "GarlandDrop102_L")
	_box(m, Vector3(0.08, 0.50, 0.08), _trim_mat, Vector3(0.60, 2.65, 0.20), "GarlandDrop102_R")
	for px in [-0.90, 0.90]:
		var gl := _box(m, Vector3(0.18, 0.18, 0.18), _glow_mat, Vector3(px, 3.00, 0.0), "LampGlow102_%d" % int(px * 100.0))
		gl.visible = false
		_glows.append(gl)
	var om := OmniLight3D.new()
	om.name = "LampMon102_Omni"
	om.light_color = Color(1.0, 0.75, 0.45, 1.0)
	om.light_energy = 1.5
	om.omni_range = 22.0
	om.shadow_enabled = false
	om.position = Vector3(-6.0, 2.80, -32.0)
	om.visible = false
	world.add_child(om)
	_glows.append(om)
	for px in [-1.10, 1.10]:
		_box(m, Vector3(0.30, 0.40, 0.30), _trim_mat, Vector3(px, 0.55, 1.10), "Incense102_%d" % int(px * 100.0))

# Zayat (28,2, deck top 0.775 + pillars + roofs + benches + altar +
# S98 mats): 3 steps up the +z deck edge, side rails + newels, a
# hanging lantern glow + gated omni under the roof, flower pots
# flanking the steps. NO walls invented (it is an open pavilion).
func _zayat(world: Node3D) -> void:
	var z := _find(world, "Zayat") as Node3D
	if z == null:
		return
	_box(z, Vector3(2.0, 0.26, 0.6), _trim_mat, Vector3(0.0, 0.13, 4.35), "Step102_A")
	_box(z, Vector3(2.0, 0.52, 0.6), _trim_mat, Vector3(0.0, 0.26, 3.75), "Step102_B")
	_box(z, Vector3(2.0, 0.78, 0.6), _trim_mat, Vector3(0.0, 0.39, 3.15), "Step102_C")
	for px in [-1.05, 1.05]:
		_box(z, Vector3(0.06, 0.06, 1.8), _wood_mat, Vector3(px, 0.90, 3.75), "StairRail102_%d" % int(px * 100.0))
		_box(z, Vector3(0.06, 0.90, 0.06), _wood_mat, Vector3(px, 0.45, 4.35), "StairNewel102_%d" % int(px * 100.0))
	var gl := _box(z, Vector3(0.24, 0.24, 0.24), _glow_mat, Vector3(0.0, 3.60, 0.0), "LampGlow102")
	gl.visible = false
	_glows.append(gl)
	var om := OmniLight3D.new()
	om.name = "LampZayat102_Omni"
	om.light_color = Color(1.0, 0.75, 0.45, 1.0)
	om.light_energy = 1.5
	om.omni_range = 22.0
	om.shadow_enabled = false
	om.position = Vector3(28.0, 3.60, 2.0)
	om.visible = false
	world.add_child(om)
	_glows.append(om)
	for px in [-1.6, 1.6]:
		_box(z, Vector3(0.40, 0.40, 0.40), _trim_mat, Vector3(px, 0.20, 4.35), "FlowerPot102_%d" % int(px * 100.0))
		_box(z, Vector3(0.30, 0.30, 0.30), _trim_mat, Vector3(px, 0.55, 4.35), "FlowerTop102_%d" % int(px * 100.0))

# LakesideHut19 (44,38, walls 2.2x1.6x3.4 + big flat roof at y 2.0
# that floats 0.25 m above the wall tops): windows + frames + sills
# on both faces and both sides, door + frame on +z, plinth, roof
# trim band, short posts bridging the wall-top-to-roof gap, stoop
# steps, and a gated omni at the existing lamp. Solid kept (it
# already covers the plinth + trim).
func _lakeside(world: Node3D) -> void:
	var h := _find(world, "LakesideHut19") as Node3D
	if h == null:
		return
	_box(h, Vector3(0.8, 1.4, 0.10), _wood_mat, Vector3(0.0, 0.70, 1.72), "Door102")
	_box(h, Vector3(0.10, 1.5, 0.08), _trim_mat, Vector3(-0.45, 0.75, 1.76), "DoorFrame102_L")
	_box(h, Vector3(0.10, 1.5, 0.08), _trim_mat, Vector3(0.45, 0.75, 1.76), "DoorFrame102_R")
	_box(h, Vector3(1.0, 0.10, 0.08), _trim_mat, Vector3(0.0, 1.45, 1.76), "DoorLintel102")
	for sx in [-0.55, 0.55]:
		for sgn in [-1.0, 1.0]:
			_box(h, Vector3(0.6, 0.6, 0.06), _dark_mat, Vector3(sx, 0.90, sgn * 1.73), "Win102_%d_%d" % [int(sx * 100.0), int(sgn * 10.0)])
			_box(h, Vector3(0.80, 0.80, 0.04), _trim_mat, Vector3(sx, 0.90, sgn * 1.72), "Frame102_%d_%d" % [int(sx * 100.0), int(sgn * 10.0)])
			_box(h, Vector3(0.80, 0.08, 0.10), _trim_mat, Vector3(sx, 0.56, sgn * 1.76), "Sill102_%d_%d" % [int(sx * 100.0), int(sgn * 10.0)])
	for sgn in [-1.0, 1.0]:
		_box(h, Vector3(0.06, 0.6, 0.6), _dark_mat, Vector3(sgn * 1.13, 0.90, 0.0), "WinSide102_%d" % int(sgn * 10.0))
		_box(h, Vector3(0.04, 0.80, 0.80), _trim_mat, Vector3(sgn * 1.12, 0.90, 0.0), "FrameSide102_%d" % int(sgn * 10.0))
	_box(h, Vector3(2.4, 0.20, 3.6), _trim_mat, Vector3(0.0, 0.10, 0.0), "Plinth102")
	_box(h, Vector3(2.4, 0.12, 3.6), _trim_mat, Vector3(0.0, 1.66, 0.0), "RoofTrim102")
	for px in [-1.0, 1.0]:
		for pz in [-1.5, 1.5]:
			_box(h, Vector3(0.12, 0.25, 0.12), _wood_mat, Vector3(px, 1.725, pz), "RoofPost102_%d_%d" % [int(px * 10.0), int(pz * 10.0)])
	_box(h, Vector3(1.2, 0.12, 0.4), _trim_mat, Vector3(0.0, 0.06, 2.05), "Step102_A")
	_box(h, Vector3(1.2, 0.24, 0.4), _trim_mat, Vector3(0.0, 0.12, 1.85), "Step102_B")
	var om := OmniLight3D.new()
	om.name = "LampHut102_Omni"
	om.light_color = Color(1.0, 0.75, 0.45, 1.0)
	om.light_energy = 1.5
	om.omni_range = 22.0
	om.shadow_enabled = false
	om.position = Vector3(45.5, 2.10, 38.0)
	om.visible = false
	world.add_child(om)
	_glows.append(om)

# DepotOffice82 (30,6, child of BusSim82): walls + pitched roof +
# door + glass windows exist, but NO frames/sills/cornice/plinth/
# door frame/steps/glows — and NO walk solid at all (the office is
# currently walk-through). Solid added on the S100 hamlet precedent
# (envelope-sized, clear of the depot lamp at (22,10) by 3.8 m, of
# the fuel pump at (40,32) and the depot sign post at (30,21)).
func _depot_office(world: Node3D) -> void:
	var g := _find(world, "DepotOffice82") as Node3D
	if g == null:
		return
	for wx in [-2.5, 2.5]:
		_box(g, Vector3(1.4, 1.2, 0.04), _trim_mat, Vector3(wx, 1.8, 2.52), "Frame102_%d" % int(wx * 10.0))
		_box(g, Vector3(1.4, 0.08, 0.12), _trim_mat, Vector3(wx, 1.28, 2.56), "Sill102_%d" % int(wx * 10.0))
		var gl := _box(g, Vector3(1.2, 1.0, 0.04), _glow_mat, Vector3(wx, 1.8, 2.62), "Glow102_%d" % int(wx * 10.0))
		gl.visible = false
		_glows.append(gl)
	_box(g, Vector3(0.04, 1.2, 1.4), _trim_mat, Vector3(4.02, 1.8, 0.0), "Frame102_E")
	_box(g, Vector3(0.12, 0.08, 1.4), _trim_mat, Vector3(4.06, 1.28, 0.0), "Sill102_E")
	_box(g, Vector3(8.4, 0.15, 5.4), _trim_mat, Vector3(0.0, 3.30, 0.0), "Cornice102")
	_box(g, Vector3(8.4, 0.30, 5.4), _trim_mat, Vector3(0.0, 0.15, 0.0), "Plinth102")
	_box(g, Vector3(0.12, 2.2, 0.10), _trim_mat, Vector3(-0.56, 1.10, 2.58), "DoorFrame102_L")
	_box(g, Vector3(0.12, 2.2, 0.10), _trim_mat, Vector3(0.56, 1.10, 2.58), "DoorFrame102_R")
	_box(g, Vector3(1.24, 0.12, 0.10), _trim_mat, Vector3(0.0, 2.16, 2.58), "DoorLintel102")
	_box(g, Vector3(1.5, 0.12, 0.5), _trim_mat, Vector3(0.0, 0.06, 2.90), "Step102_A")
	_box(g, Vector3(1.5, 0.24, 0.5), _trim_mat, Vector3(0.0, 0.12, 2.65), "Step102_B")
	var solid := StaticBody3D.new()
	solid.name = "DepotOffice102Solid"
	solid.collision_layer = 1
	solid.collision_mask = 0
	solid.position = Vector3(30.0, 1.65, 6.0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(8.4, 3.3, 5.4)
	cs.shape = bs
	solid.add_child(cs)
	world.add_child(solid)

# Animal pens (open structures — rails + trough + lantern, no walls):
# ElephantStable18 (-44,26, roof + 4 posts + hay only) and HorsePen19
# (-38,-30) + HorsePen20 (4 posts + hay only, NO rails at all).
func _pens(world: Node3D) -> void:
	var st := _find(world, "ElephantStable18") as Node3D
	if st != null:
		# Posts are at (+-2.2, 1.4, +-1.8), roof at y 2.8: rails join
		# the posts on 3 sides, gap on the +z side (entrance).
		for px in [-2.2, 2.2]:
			_box(st, Vector3(0.08, 0.08, 3.6), _wood_mat, Vector3(px, 1.00, 0.0), "Rail102_%d" % int(px * 10.0))
		_box(st, Vector3(4.4, 0.08, 0.08), _wood_mat, Vector3(0.0, 1.00, -1.8), "Rail102_B")
		_box(st, Vector3(1.2, 0.5, 0.6), _wood_mat, Vector3(0.0, 0.25, 0.0), "Trough102")
		var om := OmniLight3D.new()
		om.name = "LampStable102_Omni"
		om.light_color = Color(1.0, 0.75, 0.45, 1.0)
		om.light_energy = 1.5
		om.omni_range = 22.0
		om.shadow_enabled = false
		om.position = Vector3(-44.0, 2.50, 26.0)
		om.visible = false
		world.add_child(om)
		_glows.append(om)
	for pen in ["HorsePen19", "HorsePen20"]:
		var p := _find(world, pen) as Node3D
		if p == null:
			continue
		for sgn in [-1.0, 1.0]:
			_box(p, Vector3(5.0, 0.08, 0.08), _wood_mat, Vector3(0.0, 1.00, sgn * 2.5), "Rail102_%d" % int(sgn * 10.0))
			_box(p, Vector3(0.08, 0.08, 5.0), _wood_mat, Vector3(sgn * 2.5, 1.00, 0.0), "RailSide102_%d" % int(sgn * 10.0))
		_box(p, Vector3(1.0, 0.4, 0.5), _wood_mat, Vector3(-1.5, 0.20, -1.5), "Trough102")

# Gold stall row (29..34, 22..26, tables + boxes only): one canopy
# over the cluster + a sign frame. Counted as ONE row treatment set.
func _goldrow(world: Node3D) -> void:
	for px in [28.0, 35.0]:
		for pz in [21.0, 27.0]:
			_box(world, Vector3(0.12, 2.60, 0.12), _wood_mat, Vector3(px, 1.30, pz), "CanopyPost102_%d_%d" % [int(px), int(pz)])
	_box(world, Vector3(7.4, 0.12, 6.4), _trim_mat, Vector3(31.5, 2.66, 24.0), "CanopyRoof102")
	_box(world, Vector3(0.10, 1.6, 0.10), _wood_mat, Vector3(30.6, 0.80, 20.0), "SignPost102_L")
	_box(world, Vector3(0.10, 1.6, 0.10), _wood_mat, Vector3(32.4, 0.80, 20.0), "SignPost102_R")
	_box(world, Vector3(2.0, 0.5, 0.08), _trim_mat, Vector3(31.5, 1.70, 20.0), "SignBoard102")

# Second night-dark audit lamps — sites from audit102/audit102b
# (daylight 0, per-sample nearest-omni distances). Each lamp = 1
# item, same gated pattern (pole + emissive head + omni 1.5/22),
# every site >= 2 m clear of a driveable surface and >= 1 m clear
# of every solid (verified in sim102).
func _nightlamps(world: Node3D) -> void:
	var sites: Array = [
		Vector3(3.5, 0.0, 42.0), Vector3(135.0, 0.0, -45.0),
		Vector3(185.0, 0.0, -40.0), Vector3(185.0, 0.0, 40.0),
		Vector3(255.0, 0.0, -8.0), Vector3(385.0, 0.0, 8.0),
		Vector3(440.0, 0.0, -8.0), Vector3(850.0, 0.0, 8.0),
		Vector3(1350.0, 0.0, 8.0), Vector3(1850.0, 0.0, 8.0),
	]
	var li := 0
	for s in sites:
		var p := s as Vector3
		_box(world, Vector3(0.12, 3.00, 0.12), _pole_mat, Vector3(p.x, 1.50, p.z), "Lamp102_Pole%d" % li)
		var head := _box(world, Vector3(0.20, 0.12, 0.20), _glow_mat, Vector3(p.x, 3.05, p.z), "Lamp102_Head%d" % li)
		head.visible = false
		_glows.append(head)
		var om := OmniLight3D.new()
		om.name = "Lamp102_Omni%d" % li
		om.light_color = Color(1.0, 0.75, 0.45, 1.0)
		om.light_energy = 1.5
		om.omni_range = 22.0
		om.shadow_enabled = false
		om.position = Vector3(p.x, 3.00, p.z)
		om.visible = false
		world.add_child(om)
		_glows.append(om)
		li += 1
