extends Node3D
## Slice 102 (parent sequence): LONG-ROUTE NIGHT FILL. Owner standing
## rules: ~50 items per push, graphics-first, whole buildings finished
## not thin detail spread everywhere. Runtime dressing ONLY, no .tscn
## edits, no bus-system changes, minibus NOT rewired, big bus NOT
## rewired (Slice 81 limit), touch controls untouched, zero NEW
## colliders, StandardMaterial3D only, no dead specular lines, no
## fog/SSAO/glow claims (no WorldEnvironment exists), no photorealism
## claims: stylised smooth procedural dressing, stated plainly.
## Runs at frame >= 240, after realism102's 220 pass.
##
## AUDIT-FIRST findings (all live-probed, 2026-10-24):
## - HEADLINE: S101 stated the long route (x 445..2445, 2000 m) stays
##   mostly dark between stops — its own audit measured only 24/100
##   centreline samples lit at daylight 0, with dark runs up to
##   188.4 m. A full fill needs ~40 lamps at 22 m range. This slice
##   places 48 pools along the route + 1 EF-road notch pool = 49 items
##   (honest count, one under the ~50 target — no padding).
## - POOL DERIVATION (live probe, not guesswork): the route's TRUE
##   light inventory, read from the scripts (not assumed): 6 stop
##   lamps (495/695/1195/1695/2195/2395 at z +10.5, range 12 — NOT 22,
##   so each lights only +-5.81 m of centreline), S99 RouteOmni100
##   (600/1000/1500/2000 at z +7.5, range 18), S98 route lamps
##   (1000/2000 at z -14, range 22), S101's 3 mid-stretch pools
##   (850/1350/1850 at z +8, range 22), S101's EF lamps
##   (255/385/440, range 22), S100's EF lamps (280/350/420, range 22),
##   and Night97's omnis (RouteMid at (1500, 0) and EFRoad at
##   (330, 0), range 22). Merging their centreline intervals leaves
##   14 dark gaps on the route; pool x positions are computed per
##   gap (38 m spacing inside gaps, bridged by the inventory lights
##   at the junctions) so every interval overlaps its neighbours.
##   Two junctions rely on inventory lights, verified, not assumed:
##   the 693.85..699.31 and 2392.29..2399.31 joints are bridged by
##   the stop lamps (689.19..700.81 and 2389.19..2400.81), and the
##   1516.36..1520.5 joint by Night97 RouteMid (to 1522). Worst
##   centreline distance after fill is 21.07 m (< 22 range) —
##   continuous coverage x 445..2440.29, verified in sim103 by
##   5 m sampling against the LIVE omni set (not a static list).
## - SIDE: all route pools sit at z = -8, the north verge: 2.0 m clear
##   of the 12 m slab edge (|z| = 6; curbs sit 6.0..6.5, so pools are
##   1.5 m past the curb outer edge — same basis as S101's z = +-8
##   pools), 7 m clear of the stop-shelter zones (z -1..9, +z side),
##   and clear of the S-bend corridors (segment-0 x 1494..1506: nearest
##   pools 1465.49 / 1540.99; segment-3 x 1894..1906: nearest pools
##   1889.49 / 1927.49, 4.51 m clear of the corridor edge). The S-bend
##   loop itself and the east track stay deliberately unfilled
##   (scenery-only, same exclusion as S101) — stated, not claimed.
## - HILL NOTE: pools 2371.8 and 2419.8 stand inside the S74 horizon
##   hill footprint (cone at (2440, 0), base radius 90, y 0..70): their
##   poles are hidden inside the hill mesh, exactly like the existing
##   stop-2400 lamp at (2395, 10.5) already is. Their LIGHTS still work
##   (OmniLight3D with shadows off ignores mesh occlusion) — the
##   road-end view is lit, only the pole silhouette is absorbed.
##   Stated plainly, not hidden.
## - RESIDUAL (honest, not claimed away): the final 4.71 m of road
##   (2440.29..2445) runs into the hill face; a pool past the terminus
##   would light no road, so none is placed. The road is lit to
##   2440.29 and dark only for those last metres inside the hill.
## - EF NOTCH: the EF road (x 250..445) has ONE real light gap
##   (300.68..308, 7.32 m) once every inventory light is counted:
##   S101/S100 lamp intervals give 234.51..300.68 and 329.32..460.49,
##   and Night97's EFRoad omni at (330, 0) covers 308..352 — so the
##   gap is 7.32 m, not the 28.64 m a partial inventory suggests.
##   One pool at (319.67, -8) covers 299.18..340.16 and bridges it
##   with margin on both sides. S62's streetlight poles (z -7,
##   x 270..430 step 32) carry no omnis (verified: no OmniLight3D in
##   chill_world62 / chill_controller62), so they do not change the
##   gap analysis; the notch pool clears them by >= 14.4 m and clears
##   EF trees (305,-10) / (325,10) by >= 14.8 m.
## - MD1/2/3/6/10 STAY DEFERRED (surveyed live + static, 2026-10-24):
##   all five ALREADY overlap S56 blocks at x1.0 (pre-existing S37/S56
##   conflict): MD1 (125,-14) vs Block A (130,-12, 10x8) 3.0x4.5 m;
##   MD2 (125,14) vs D (130,12, 8x8) 2.0x4.5; MD3 (155,-14) vs B
##   (160,-12, 8x8) 2.0x4.5; MD6 (170,14) vs E (170,12, 10x8) 6.0x4.5;
##   MD10 (200,16) vs F (200,12, 8x8) 6.0x2.5. At x1.8 + 0.2 overhang
##   the overlaps grow to ~4.6-10 x 4.7-6.7 m. Clearing by moving
##   houses = 6-11 m arbitrary re-placement (owner rejected arbitrary
##   placement); clearing by moving blocks = editing city_visual56
##   coordinates, breaking the S56 row (130/160/190 spacing). A x1.0
##   detail-only treatment is also wrong (upper storey + door would
##   sit inside the block; MD1's door lands on the block edge x=125).
##   NOT forced; the table + reasons are the deliverable here.
## - PROVEN NOT GAPS (do not build): S56 CityBlock56A-F windows
##   already glow at night via DayNight window_material (emission
##   1.0/0.72/0.32 x1.4, toggled at daylight < 0.15 in day_night.gd)
##   — the audit's "0 Glow nodes" was a naming artifact. House97_1-4
##   and Stilt97 houses already have night97 world-child glows.
##   StiltHouse17_5 (-6,-38) / 18_6 (-2,-40) are open pavilions whose
##   plans already overlap 1x2 m — S96 explicitly excluded them;
##   adding walls would invent structure.
## Counting: one item = one lamp pool (pole + emissive head + omni).
##   NIGHT 49: long-route pools 48 + EF notch pool 1.
## DELIBERATELY NOT FILLED, stated: S-bend loop (scenery-only);
## east track (scenery-only, 455 m); S97 tree lines (empty fields,
## not routes); final 4.71 m into the S74 hill face (above).

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
	if world.get_node_or_null("Realism103") != null:
		return
	var n := Node3D.new()
	n.name = "Realism103"
	n.set_script(load("res://realism103.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 240:
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

# Long-route night fill: 48 pools at z = -8 (north verge) + 1 EF-road
# notch pool at (319.67, -8). Each pool = 1 item, same gated pattern
# as S101 (pole + emissive head + omni 1.5/22). Pool x positions are
# computed from the live light inventory (see header): two pools per
# dark gap, 38 m apart, so intervals overlap by >= 1.5 m; single-pool
# gaps are centred on their gap. S101's own pools (850/1350/1850 at
# z +8) are on the opposite verge and are NOT duplicated.
func _nightlamps(world: Node3D) -> void:
	var route_x: Array = [
		479.49, 519.8, 557.8, 595.8, 635.36, 673.36, 719.8, 757.8,
		795.8, 833.8, 889.49, 927.49, 965.49, 1035.96, 1073.96, 1111.96,
		1149.96, 1187.96, 1219.8, 1257.8, 1295.8, 1333.8, 1389.49,
		1427.49, 1465.49, 1540.99, 1578.99, 1616.99, 1654.99, 1692.99,
		1719.8, 1757.8, 1795.8, 1833.8, 1889.49, 1927.49, 1965.49,
		2035.96, 2073.96, 2111.96, 2149.96, 2187.96, 2219.8, 2257.8,
		2295.8, 2333.8, 2371.8, 2419.8,
	]
	var sites: Array = []
	for x in route_x:
		sites.append(Vector3(float(x), 0.0, -8.0))
	sites.append(Vector3(319.67, 0.0, -8.0))
	var li := 0
	for s in sites:
		var p := s as Vector3
		_box(world, Vector3(0.12, 3.00, 0.12), _pole_mat, Vector3(p.x, 1.50, p.z), "Lamp103_Pole%d" % li)
		var head := _box(world, Vector3(0.20, 0.12, 0.20), _glow_mat, Vector3(p.x, 3.05, p.z), "Lamp103_Head%d" % li)
		head.visible = false
		_glows.append(head)
		var om := OmniLight3D.new()
		om.name = "Lamp103_Omni%d" % li
		om.light_color = Color(1.0, 0.75, 0.45, 1.0)
		om.light_energy = 1.5
		om.omni_range = 22.0
		om.shadow_enabled = false
		om.position = Vector3(p.x, 3.00, p.z)
		om.visible = false
		world.add_child(om)
		_glows.append(om)
		li += 1
