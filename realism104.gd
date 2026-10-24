extends Node3D

## Slice 103 (parent sequence): NIGHT FILL ROUND 3 + MD1/2/3/6/10 DECISION.
## Owner standing rules: ~50 items per push, graphics-first, whole buildings
## finished not thin detail spread everywhere. Runtime dressing ONLY, no .tscn
## edits, no bus-system changes, minibus NOT rewired, big bus NOT rewired
## (Slice 81 limit), touch controls untouched, zero NEW colliders,
## StandardMaterial3D only, no dead specular lines, no fog/SSAO/glow claims
## (no WorldEnvironment exists), no photorealism claims: stylised smooth
## procedural dressing, stated plainly. Runs at frame >= 260, after
## realism103's 240 pass.
##
## AUDIT-FIRST findings (all live-probed at daylight 0, 2026-10-24):
## The live omni set at daylight 0 is 130 visible omnis. Sampling every
## walkable/driveable line at 5-10 m steps gives these REAL gaps:
## - Mindon west approach (MindonLinkRoad gap + street start): z=0 samples
##   x85..110 dark, worst 14.0 m beyond range at (95,0); house rows z=+-14
##   x100..120 dark, worst 14.7 at (100,+-14). The S59 poles stand at
##   (105,4.5)/(92,4.5) but carry only 4 omnis district-wide, so the
##   approach is dark. FILLED with 3 pools (see sites).
## - Mindon rows gap between blocks: rows z=+-14 x130..145 dark (up to
##   3.2 m beyond range in audit104, and the x140..145 north samples
##   stay dark after the west pools alone) — this is open ground
##   between Block D/E (south) and Block A/B (north), NOT a block face,
##   so no window glow covers it. FILLED with 2 pools at (137,+-8):
##   2.0 m east of Block A's east face, 3.0 m east of Block D's east
##   face, 5.0 m clear of the street edge, >= 8.7 m from every S59 pole.
## - Mindon east end: street z=0 x220..230 dark (worst 6.0 at (225,0)) and
##   rows z=+-14 x220..240 dark (worst 11.3 at (230,14)) past the last
##   block (F ends x=204). FILLED with 1 pool at (225,5): it covers the
##   street 203.6..246.4 and both rows to (240,14) (17.5 m) — verified
##   in sim104, not assumed.
## - EF south front: z=11 x295..305 dark, worst 5.2 at (300,11) — the
##   S101 marginal residual (nearest omni edge 5.2 m away). FILLED with
##   1 pool at (300,8): 2.0 m clear of the 12 m EF road edge, 25.1 m
##   from the (325,10) tree, 18.7 m from (305,-10).
## - East track (S96 dirt track x 2445..2900, z -4..4, 8 m wide, driveable
##   scenery): 36/46 samples dark, worst 98.1 beyond range at (2670,0).
##   Only the two S98 lamps (2550,6)/(2800,-6) light it, in islands
##   2528.8..2571.2 and 2778.8..2821.2. FILLED with 10 pools at z=6
##   (2.0 m clear of the track edge): gaps bridged with >= 0.4 m
##   overlap at every joint (sim104 proves 0 dark samples on z=0).
##   Residual: 2440.29..2444.8 (4.5 m) at the route/track junction,
##   same class as S102's 4.71 m hill-face residual — stated, not filled
##   (a pool there would sit on the junction, not on the track).
## - S-bend loop road (LOOP_PTS 4 segments, 12 m slabs, ~480 m total,
##   driveable): 54/58 path samples dark, worst 103.9 at (1510,-130);
##   only the two junctions are lit (RouteMid at (1500,0) covers the
##   west junction; S102 pools cover the east junction). FILLED with
##   15 pools offset 8.0 m OUTSIDE the loop (2.0 m clear of the 6 m
##   slab half-width): seg0 west side, seg1/seg2 south side, seg3 east
##   side. Spacing 36 m on the long segments (not 38-40 m): at 38 m
##   spacing the two corners keep 2-4 m dark slivers (corner geometry
##   shortens each pool's along-path reach below 20.49 m), so the
##   corner pools sit at seg1 s=195 / seg2 s=30 to bridge both corners
##   with margin. Loop trees sit 14+ m off-centre (bus_route75 comment),
##   so pools at 8 m are >= 6 m clear of them. Sim104 samples the path
##   every 5 m and requires 0 dark.
## - Hamlet spur road (x 2094..2106, z 6..60): only 3/10 samples dark
##   and all marginal (1.3/3.1/1.3 m). FILLED with 1 pool at (2108,15)
##   (2.0 m clear of the spur's east edge) for the (12,18) pair; the
##   (2100,60) sample stays a stated 1.3 m marginal residual (hamlet
##   omni at (2100,88) reaches to z 66; the 6 m to the house row is
##   field edge, not road).
## Counting: one item = one lamp pool (pole + emissive head + omni).
## NIGHT 34: Mindon west 3 + Mindon rows gap 2 + Mindon east 1 + EF south 1
## + east track 10 + S-bend loop 15 + hamlet spur 1 + Mindon rows band 1
## ((182,-8), added after SIM104's first run showed the 3.205 residual).
##
## MD1/2/3/6/10 DECISION (surveyed live + static, 2026-10-24 — this slice
## closes the question S101/S102 left open; the decision IS the
## deliverable, not another deferral):
## All five houses are scene nodes in main.tscn (Walls mesh 6x2.8x5,
## solid 6x3x5) and ALL FIVE already overlap S56 city blocks at x1.0,
## measured live from mesh AABBs (house vs block):
## - MD1 (125,-14): house 122..128 x -16.5..-11.5 vs Block A (130,-12,
##   10x8) 125..135 x -16..-8 → OVERLAP 3.00 x 4.50 m. Exposed: only a
##   3.0 m west strip (122..125); the door face and every window face
##   sit inside the block. At x1.8 the overlap grows to 5.4 x 6.5 m.
## - MD2 (125,14): house 122..128 x 11.5..16.5 vs Block D (130,12, 8x8)
##   126..134 x 8..16 → OVERLAP 2.00 x 4.50 m. Exposed: 4.0 m west strip.
##   At x1.8: 4.4 x 6.5 m.
## - MD3 (155,-14): house 152..158 x -16.5..-11.5 vs Block B (160,-12,
##   8x8) 156..164 x -16..-8 → OVERLAP 2.00 x 4.50 m. Exposed: 4.0 m
##   west strip. At x1.8: 4.4 x 6.5 m.
## - MD6 (170,14): house 167..173 x 11.5..16.5 vs Block E (170,12, 10x8)
##   165..175 x 8..16 → OVERLAP 6.00 x 4.50 m. The house x-range lies
##   ENTIRELY inside the block x-range; exposed: only a 0.5 m south
##   sliver (z 16..16.5). At x1.8: 10.0 x 6.5 m — swallowed whole.
## - MD10 (200,16): house 197..203 x 13.5..18.5 vs Block F (200,12, 8x8)
##   196..204 x 8..16 → OVERLAP 6.00 x 2.50 m. House x-range entirely
##   inside the block; exposed: 2.5 m south strip. At x1.8: 8.0 x 4.5 m.
## Extraction fails every allowed move: moving a house = arbitrary
## re-placement (owner order 2026-10-22: houses must NOT be placed
## conveniently; the house rows 125/155/170/200 and 125/155/170/200
## would break, and the free ground around them is unplanned district
## edge, not a lot); moving a block = breaking S56 row alignment
## (north 130/160/190, south 130/170/200, with windows/glows/colliders
## tied to those coordinates); a x1.0 detail-only treatment is wrong
## (upper storey + door would sit inside the block; MD6/MD10 have no
## dressable face at all). Deleting them is NOT done: that would be a
## .tscn edit (forbidden) and would remove district content rather
## than finish a building. VERDICT: MD1/2/3/6/10 STAY BARE + UNSCALED,
## permanently, with these reasons on record. They read at street
## level as block wall strips, not as houses — that is the honest
## state, not a hidden defect.
## DONE vs DEFERRED building lists: DONE — Mindon district MD4/5/7/8/9/
## 11/12/13/14 + Oo1/2/3 (S101), landmarks Post/Edu/MRTV/Shops/Temple/
## Hospital (S99), village House97_1-4 (S99), House5 rebuild + House6 +
## House7_17/8_18 (S101), EF stilt x12 (S99), hamlet x4 (S100), Stilt13
## (S100, no 2nd storey — reason stands), Stilt97 x3 (S100), School
## 2nd storey (S100/S101), EF staircases (S100), market/tea/night-
## market/guest/monastery/zayat/lakeside hut/depot office/stable/pens/
## gold row (S101). DEFERRED — MD1/2/3/6/10 (above); StiltHouse17_5/
## 18_6 open pavilions (S96 exclusion stands: plans already overlap
## 1x2 m, adding walls would invent structure); House1/2/3/4 slabs stay
## hidden (already replaced by House97_1-4).
##
## DELIBERATELY NOT FILLED, stated: village field edges (grid dark
## points at z=+-40, x=+-60/90 are fields, not lanes — the (-60,0)
## point sits on NO road slab: village slabs cluster x -30..0, z
## 19..38); hamlet field edges (x 2050/2160, z 55..95 are off-road —
## the spur road itself + house fronts are lit); Mindon rows
## x145..215 marginals (after the (182,-8) pool: worst ~1.4 m beyond
## range at (190,14), block window glow present on those faces —
## S56 windows glow via DayNight window_material, emission
## 1.0/0.72/0.32 x1.4 at daylight < 0.15); spur (2100,60) 1.3 m; route/track junction 4.5 m; S102 final
## 4.71 m into the hill face (unchanged).

static var _pole_mat: StandardMaterial3D = null
static var _glow_mat: StandardMaterial3D = null

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
	if world.get_node_or_null("Realism104") != null:
		return
	var n := Node3D.new()
	n.name = "Realism104"
	n.set_script(load("res://realism104.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 260:
		_done = true
		_apply(get_parent() as Node3D)
	var world := get_parent() as Node3D
	if world == null:
		return
	var day := _daylight(world)
	var night := day < 0.15
	if not _gate_once or night != _last_night:
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
	if _pole_mat != null:
		return
	_pole_mat = StandardMaterial3D.new()
	_pole_mat.albedo_color = Color(0.25, 0.25, 0.25, 1.0)
	_pole_mat.roughness = 0.8
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.albedo_color = Color(1.0, 0.75, 0.45, 1.0)
	_glow_mat.emission_enabled = true
	_glow_mat.emission = Color(1.0, 0.70, 0.35, 1.0)
	_glow_mat.emission_energy_multiplier = 1.6

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.set_surface_override_material(0, mat)
	m.position = pos
	parent.add_child(m)
	return m

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_mats()
	_nightlamps(world)

# 34 pools, S102 pattern (pole + emissive head + omni 1.5/22, gated
# daylight < 0.15 every frame). Site order: Mindon west 3, Mindon rows gap 2,
# Mindon east 1, EF south 1, east track 10, S-bend loop 15, hamlet spur 1,
# Mindon rows band 1 (182,-8, appended last so earlier indices stay stable).
func _nightlamps(world: Node3D) -> void:
	var sites: Array = [
		# Mindon west approach (street 6 m wide, |z| <= 3; blocks start x 125).
		Vector3(90.0, 0.0, -8.0), Vector3(108.0, 0.0, -8.0), Vector3(115.0, 0.0, 8.0),
		# Mindon rows gap between blocks (Block A east face x 135,
		# Block D east face x 134; S59 poles at (125,4.5)/(145,4.5)).
		Vector3(137.0, 0.0, -8.0), Vector3(137.0, 0.0, 8.0),
		# Mindon east end (last street segment 217..235, edge |z| = 3).
		Vector3(225.0, 0.0, 5.0),
		# EF south front (EF road 12 m wide, |z| <= 6).
		Vector3(300.0, 0.0, 8.0),
		# East track (8 m wide, |z| <= 4; S98 lamp islands 2528.8..2571.2
		# and 2778.8..2821.2 bridged with >= 0.4 m overlap at joints).
		Vector3(2466.0, 0.0, 6.0), Vector3(2508.0, 0.0, 6.0),
		Vector3(2590.0, 0.0, 6.0), Vector3(2625.0, 0.0, 6.0),
		Vector3(2660.0, 0.0, 6.0), Vector3(2695.0, 0.0, 6.0),
		Vector3(2730.0, 0.0, 6.0), Vector3(2765.0, 0.0, 6.0),
		Vector3(2842.0, 0.0, 6.0), Vector3(2882.0, 0.0, 6.0),
		# S-bend loop (12 m slabs; pools 8.0 m outside centreline,
		# 36 m spacing on long segments so both corners stay lit).
		Vector3(1492.0, 0.0, -30.0), Vector3(1492.0, 0.0, -65.0),
		Vector3(1518.04, 0.0, -91.77), Vector3(1553.34, 0.0, -98.83),
		Vector3(1588.64, 0.0, -105.89), Vector3(1623.95, 0.0, -112.95),
		Vector3(1659.25, 0.0, -120.01), Vector3(1689.64, 0.0, -126.09),
		Vector3(1730.99, 0.0, -121.96), Vector3(1766.29, 0.0, -114.90),
		Vector3(1801.59, 0.0, -107.84), Vector3(1836.89, 0.0, -100.78),
		Vector3(1872.19, 0.0, -93.72),
		Vector3(1908.0, 0.0, -70.0), Vector3(1908.0, 0.0, -35.0),
		# Hamlet spur (12 m wide, x 2094..2106).
		Vector3(2108.0, 0.0, 15.0),
		# Mindon rows band (added after SIM104 run 1: see header).
		Vector3(182.0, 0.0, -8.0),
	]
	var li := 0
	for s in sites:
		var p := s as Vector3
		_box(world, Vector3(0.12, 3.00, 0.12), _pole_mat, Vector3(p.x, 1.50, p.z), "Lamp104_Pole%d" % li)
		var head := _box(world, Vector3(0.20, 0.12, 0.20), _glow_mat, Vector3(p.x, 3.05, p.z), "Lamp104_Head%d" % li)
		head.visible = false
		_glows.append(head)
		var om := OmniLight3D.new()
		om.name = "Lamp104_Omni%d" % li
		om.light_color = Color(1.0, 0.75, 0.45, 1.0)
		om.light_energy = 1.5
		om.omni_range = 22.0
		om.shadow_enabled = false
		om.position = Vector3(p.x, 3.00, p.z)
		om.visible = false
		world.add_child(om)
		_glows.append(om)
		li += 1
