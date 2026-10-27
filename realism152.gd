## Slice 152: MAP EXPANSION + IMMERSION.
##
## DATA BASIS (read FIRST, before placing anything — owner 2026-10-27 11:32
## complaint, second time: map still not the real town's houses/roads):
##   - OSM Overpass STILL BLOCKED from this VM on 2026-10-27 (overpass-api.de
##     HTTP 406 in 1.19 s; kumi/private.coffee mirrors 30 s timeouts;
##     Nominatim works — reverse geocode confirms the pin area = Ward 3,
##     Mindon, on a residential highway, lat 19.3515613 lon 94.7317941).
##     The block is Overpass-specific; it is NOT proof OSM lacks Mindon data.
##   - Google Maps short link (maps.app.goo.gl/uoR2kk27QMGoMn2K7) fetch
##     FAILED (no extractable content; do NOT retry that link).
##   - Usable basis therefore remains the 2026-10-22 pin-area read +
##     Nominatim confirmation + regional pattern: dense small footprints
##     around the pin, irregular street grid, E-W street south of the pin,
##     N-S + diagonal branches, densest at pin + east/southeast, sparser
##     south + field edges, Maton watercourse west + north, Oo village
##     west across the water, fields on all sides.
##   - CONSEQUENCE, stated not hidden: NO new per-house/per-road coordinate
##     data was obtained. Every S152 placement is labeled below:
##     DATA-BACKED = follows a real corridor/direction from that basis;
##     PATTERN-FOLLOWING = placed by the existing cluster pattern (S102
##     house pattern, S122/S128 ground, S124 lamp pools, S133 road paint,
##     S97 border treatment) where data gives a direction but not a point.
##     Nothing here claims to be a surveyed Mindon house position.
##
## EXPANSION (east, the direction the 2026-10-22 read says the town is
## densest — one direction done well, not all directions thinly):
##   - Playable bounds east 3050 -> 3850 (player clamp 3049.5 -> 3849.5,
##     map_transform max_x 3050 -> 3850, GroundEast97 extended in place
##     by a NEW 800x920 plane at (3450,-50) = x 3050..3850, z -510..410).
##   - East border ring MOVED with the bounds (S97 pattern, counts
##     identical): Hill97E x 3035 -> 3835 (8 hills), BorderTree97E
##     x 3010 -> 3810 (12 trees). East skyline MOVED (S101 pattern):
##     SkylineE101 x 3110 -> 3910 (16 boxes, beyond the new clamp — the
##     wall the old east road could not pass is now scenery behind the
##     new settlement, not a barrier on the road).
##   - Straight east road z=0, 2445 -> 3400 (955 m, slab top 0.13 to avoid
##     coplanar z-fight with TrackEast97 top 0.12, edges/dashes 0.14,
##     79 dashes 4.0 every 12 from 2455, S133 precedent) + dirt
##     continuation 3400 -> 3800 (8 wide, S97 track pattern). Both are
##     DRIVABLE (solid ground planes beneath, no decorative-only road).
##   - East settlement, PATTERN-FOLLOWING, 6 houses (S102 simplified
##     pattern, fresh materials shared ONLY across these houses — never
##     with 102, so this slice cannot join the S151 season-leak class):
##     north side face +z at (3180/3220/3260,-20), south side face -z
##     (rotation.y = PI) at (3200/3240/3280,20); each + 8x8 dirt patch
##     + 2 night-gated window glows (S131 emissive-only, no omni) +
##     solid collider (S102 pattern, own fresh shape, under the holder
##     so rotation applies — equivalent to 102's world-child solids).
##   - Mindon-south infill, PATTERN-FOLLOWING, up to 3 houses at targets
##     (170,140), (220,150), (150,180), face town -z: S138 guard
##     (candidates at 8/10/12 m in 8 directions, first whose footprint
##     clears every LOW mesh wins, else the house is SKIPPED and
##     reported — never overlapped, never forced). Gate: >= 1 placed.
##   - 6 new walkers Villager19-24 (npc.gd system, NOT a new AI): 4 at
##     east settlement homes, 2 at Mindon-south homes; wander_radius 8;
##     realism121's 1.0 s scan dresses them with GLB models
##     automatically (name Villager*, not VillagerHat*); each needs a
##     CapsuleShape3D child (without it the body falls forever) +
##     group "villagers" (Talk button/prompts) + Dialogue/PromptLabel
##     children (realism121 repositions them). Displacement > 0.5 m
##     in 6 s proven like S132. npc.gd OBSTACLES += 9 circles (6
##     settlement + 3 infill targets) so no walker picks a target
##     inside a new house; harmless if an infill house is skipped.
##   - Traffic density (existing systems only, NO bus/minibus/big-bus
##     service rewiring): traffic_manager MAX_SLOTS 10 -> 12; slots 10
##     (car) + 11 (van) on the east main loop (route_idx 2, order 0/1);
##     midday fleet 10 -> 12; 7/3 bands UNCHANGED (sim135's day-7 gate
##     still holds). realism112 dresses slot cars (TrafficCar*/Van*
##     prefix), realism116 drivers (digits-suffix rule), realism118
##     brake lights (TrafficCar/TrafficVan prefix) — all by existing
##     scans, no new code paths. + 4 primitive parked cars (body +
##     cabin + 4 cylinder wheels = 6 meshes each, no colliders,
##     off-lane |z| = 10).
##   - Roadside trees 12 (x 2550..3350 step 160, z +-12) + settlement
##     trees 6 + track trees 4 = 20 (Trunk152_*/Canopy152_*; S146 tints
##     Canopy* at season change — intended, not a leak). Fields 4
##     (40x30, clear of road corridor |z| >= 12 + settlement
##     footprints). Road lamps 4 (x 2600/2900/3200/3350, z -10, S124
##     pool pattern: ungated pole + gated head + gated omni 1.5/22)
##     + settlement lamps 2 + infill lamps 2 (5 m from V23/V24 homes,
##     sim143 night-audit gap) = 8 new omnis (perf120's 5 s re-scan
##     picks them up; far-cull applies at night).
##   - MOUNTAINS (NEW, backdrop only): north range 23 cones
##     (x -600..3800 step 200, z -650, h 60..120, r 80..160) + east
##     range 6 cones (z -400..400 step 160, x 4050, h 60..110,
##     r 80..150) = 29. NO colliders, OUTSIDE the clamp (player can
##     never stand on them, nothing sits on a slope) — the horizon
##     read changes, play physics cannot break. Terrain relief inside
##     the playable area is SKIPPED (would break placements) and
##     stated as such — backdrop only, not a relief claim.
##   - Immersion guard: PUBG camera untouched (6.0 m, pitch 0.38);
##     player light untouched; fog stays deferred (S130 measured
##     reason); night water sheen stays deferred (S130).
##   - NOT touched (deferred/owner): S151 season-tint leak (lateral,
##     touches S146 — do NOT fold in); S151 Stilt17/18 pavilion
##     notes (owner phone verdict); S137 anchor/airplane decisions
##     (owner decisions); moon halo (S127, owner verdict).
##   - Materials use set_surface_override_material(0, ...) (realism151
##     precedent), NOT material_override: realism146's complement
##     tint reads ONLY surface overrides (a mesh with
##     get_surface_override_material_count() == 0 is skipped), so
##     material_override ground/canopy would silently never tint
##     per season. S146 itself is untouched.
##   - Perf: zero per-frame tree walks, zero per-frame light writers;
##     night gate is one daylight() call + one comparison per frame
##     (S120 pattern); everything else writes once at _apply.
##   - Frame gate 870 (after Realism151's 860): holders-ready =
##     Realism151 _done + House97_1 + HamletHouse75_0 + Edge97.
##     Fast-forward in sims is stated openly; holders-ready retry
##     gate (S128 pattern) protects against fast-forward ordering
##     artifacts (S127/S128 lesson).
extends Node3D

const FRAME_GATE: int = 870

var _frames: int = 0
var _done: bool = false
var _night_items: Array = []
var _night_now: bool = false
var _placed_infill: int = 0
var _infill_pos: Array = []

static func dress(world: Node) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism152") != null:
		return
	var node: Node = Node3D.new()
	node.name = "Realism152"
	node.set_script(load("res://realism152.gd"))
	world.call_deferred("add_child", node)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done:
		if _frames >= FRAME_GATE and _holders_ready():
			_apply()
		return
	var w: Node = get_parent()
	if w == null:
		return
	var dn: Node = w.get_node_or_null("DayNight")
	if dn == null or not dn.has_method("daylight"):
		return
	var is_night: bool = float(dn.call("daylight")) < 0.15
	if is_night != _night_now:
		_night_now = is_night
		for item in _night_items:
			var n: Node3D = item as Node3D
			if n != null and is_instance_valid(n):
				n.visible = is_night

static func _find_rec(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f: Node = _find_rec(c, nm)
		if f != null:
			return f
	return null

## Recursive lookup (S152 probe lesson): HamletHouse75_0 is NESTED
## under a route holder, NOT a direct world child — a
## get_node_or_null check on it is permanently false and the
## gate never fires. House97_1 appears only at scale97's
## frame 120 (scale97 is not a Realism* node, so the sim's
## fast-forward does not accelerate it — the gate waits).
func _holders_ready() -> bool:
	var w: Node = get_parent()
	if w == null:
		return false
	var r151: Node = _find_rec(w, "Realism151")
	if r151 == null:
		return false
	var done151: Variant = r151.get("_done")
	if done151 != null and not bool(done151):
		return false
	if _find_rec(w, "House97_1") == null:
		return false
	if _find_rec(w, "HamletHouse75_0") == null:
		return false
	if _find_rec(w, "Edge97") == null:
		return false
	return true

func _hash01(s: String) -> float:
	var n: int = s.hash()
	n = n & 0x7fffffff
	return float(n % 1000) / 1000.0

func _mat(r: float, g: float, b: float, rough: float = 0.9, metal: float = 0.0, emis: float = 0.0) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(r, g, b)
	m.roughness = rough
	m.metallic = metal
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = Color(r, g, b)
		m.emission_energy_multiplier = emis
	return m

func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, name: String, rot_y: float = 0.0) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = name
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation.y = rot_y
	parent.add_child(mi)
	return mi

func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, name: String, rot_x: float = 0.0) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = name
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation.x = rot_x
	parent.add_child(mi)
	return mi

func _sphere(parent: Node3D, r: float, mat: Material, pos: Vector3, name: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = name
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _ground_plane(parent: Node3D, size: Vector2, pos: Vector3, mat: Material, name: String) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = name
	var pm: PlaneMesh = PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	var body: StaticBody3D = StaticBody3D.new()
	body.name = name + "_Body"
	body.position = Vector3(pos.x, -0.5, pos.z)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = Vector3(size.x, 1.0, size.y)
	shape.shape = bs
	body.add_child(shape)
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)

## Simplified S102 house (fresh materials, never shared with 102).
## Local frame: door at +z; rot_y = PI faces -z. Returns the holder.
func _house152(parent: Node3D, name: String, pos: Vector3, rot_y: float, mats: Dictionary) -> Node3D:
	var h: Node3D = Node3D.new()
	h.name = name
	h.position = pos
	h.rotation.y = rot_y
	parent.add_child(h)
	var plaster: Material = mats["plaster"] as Material
	var trim: Material = mats["trim"] as Material
	var wood: Material = mats["wood"] as Material
	var glass: Material = mats["glass"] as Material
	var glow: Material = mats["glow"] as Material
	_box(h, Vector3(5.0, 3.0, 7.0), plaster, Vector3(0, 1.5, 0), name + "_Ground")
	_box(h, Vector3(5.2, 0.2, 7.2), trim, Vector3(0, 3.1, 0), name + "_Slab")
	_box(h, Vector3(5.0, 2.6, 7.0), plaster, Vector3(0, 4.5, 0), name + "_Upper")
	var roof: Material = mats["roof"] as Material
	var r1: MeshInstance3D = _box(h, Vector3(5.4, 0.18, 4.1), roof, Vector3(0, 6.35, 1.95), name + "_RoofS")
	r1.rotation.x = 0.252
	var r2: MeshInstance3D = _box(h, Vector3(5.4, 0.18, 4.1), roof, Vector3(0, 6.35, -1.95), name + "_RoofN")
	r2.rotation.x = -0.252
	_box(h, Vector3(0.9, 2.0, 0.12), wood, Vector3(0, 1.0, 3.56), name + "_Door")
	for sx in [-1.4, 1.4]:
		_box(h, Vector3(0.70, 0.70, 0.10), glass, Vector3(sx, 1.7, 3.56), name + "_WinF_%d" % int(sx * 10))
		_box(h, Vector3(0.70, 0.70, 0.10), glass, Vector3(sx, 1.7, -3.56), name + "_WinB_%d" % int(sx * 10))
		_box(h, Vector3(0.80, 0.08, 0.06), trim, Vector3(sx, 1.30, 3.58), name + "_SillF_%d" % int(sx * 10))
		var gl: MeshInstance3D = _box(h, Vector3(0.80, 0.90, 0.04), glow, Vector3(sx, 1.7, 3.62), name + "_Glow_%d" % int(sx * 10))
		gl.visible = false
		_night_items.append(gl)
	_box(h, Vector3(5.2, 0.30, 7.2), trim, Vector3(0, 0.15, 0), name + "_Plinth")
	_box(h, Vector3(1.2, 0.15, 0.6), trim, Vector3(0, 0.075, 3.9), name + "_StepA")
	_box(h, Vector3(1.2, 0.15, 0.6), trim, Vector3(0, 0.225, 3.6), name + "_StepB")
	var solid: StaticBody3D = StaticBody3D.new()
	solid.name = name + "_Solid"
	solid.position = Vector3(0, 3.475, 0)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = Vector3(5.24, 6.95, 7.24)
	shape.shape = bs
	solid.add_child(shape)
	solid.collision_layer = 1
	solid.collision_mask = 0
	h.add_child(solid)
	return h

## S138 guard: candidate rect (cx,cz, hw,hd) clears every LOW mesh
## (global AABB min-y < 0.5, expanded 0.3 m). Terrain slabs + base
## GroundMesh excluded (half-extent > 30 m). Sky/high meshes never block.
func _site_clear(world: Node, cx: float, cz: float, hw: float, hd: float) -> bool:
	var stack: Array = [world]
	while stack.size() > 0:
		var n: Node = stack.pop_back() as Node
		for child in n.get_children():
			stack.append(child)
		var mi: MeshInstance3D = n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var aabb: AABB = mi.get_aabb()
		var gt: Transform3D = mi.global_transform
		var c: Vector3 = gt * aabb.get_center()
		var ext: Vector3 = aabb.size * 0.5
		ext.x *= absf(gt.basis.x.length())
		ext.z *= absf(gt.basis.z.length())
		if ext.x > 30.0 or ext.z > 30.0:
			continue
		var min_y: float = c.y - aabb.size.y * 0.5 * absf(gt.basis.y.length())
		if min_y >= 0.5:
			continue
		var min_x: float = c.x - ext.x - 0.3
		var max_x: float = c.x + ext.x + 0.3
		var min_z: float = c.z - ext.z - 0.3
		var max_z: float = c.z + ext.z + 0.3
		if max_x >= cx - hw and min_x <= cx + hw and max_z >= cz - hd and min_z <= cz + hd:
			return false
	return true

func _walker152(world: Node, name: String, home: Vector2, anchor: Vector2, radius: float) -> void:
	var w: CharacterBody3D = CharacterBody3D.new()
	w.name = name
	w.set_script(load("res://npc.gd"))
	w.position = Vector3(home.x, 1.0, home.y)
	w.set("day_anchor", Vector3(anchor.x, 0.0, anchor.y))
	w.set("wander_radius", radius)
	var shape: CollisionShape3D = CollisionShape3D.new()
	# S152 fix: an unnamed node gets an @CollisionShape3D@N
	# auto-name, so sim121's get_node_or_null("CollisionShape3D")
	# missed it (collider existed, name did not). Scene villagers
	# carry the explicit name; new walkers must too. Also lets
	# realism121 read the capsule for base_y (same -0.56 result).
	shape.name = "CollisionShape3D"
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.2
	shape.shape = cap
	w.add_child(shape)
	var dl: Label3D = Label3D.new()
	dl.name = "DialogueLabel"
	dl.billboard = 1
	dl.position = Vector3(0, 1.5, 0)
	dl.font_size = 28
	dl.visible = false
	w.add_child(dl)
	var pl: Label3D = Label3D.new()
	pl.name = "PromptLabel"
	pl.billboard = 1
	pl.position = Vector3(0, 2.1, 0)
	pl.text = "!"
	pl.font_size = 36
	pl.visible = false
	w.add_child(pl)
	w.add_to_group("villagers")
	world.add_child(w)

func _parked152(parent: Node3D, name: String, pos: Vector3, body_mat: Material, dark_mat: Material) -> void:
	var h: Node3D = Node3D.new()
	h.name = name
	h.position = pos
	parent.add_child(h)
	_box(h, Vector3(3.6, 0.5, 1.7), body_mat, Vector3(0, 0.55, 0), name + "_Body")
	_box(h, Vector3(1.8, 0.5, 1.5), body_mat, Vector3(-0.2, 1.05, 0), name + "_Cabin")
	for wx in [-1.2, 1.2]:
		for wz in [-0.85, 0.85]:
			_cyl(h, 0.32, 0.32, 0.22, dark_mat, Vector3(wx, 0.32, wz), name + "_Wheel_%d_%d" % [int(wx * 10), int(wz * 10)], PI / 2.0)

func _tree152(parent: Node3D, name: String, pos: Vector3) -> void:
	var h: Node3D = Node3D.new()
	h.name = name
	h.position = pos
	parent.add_child(h)
	_cyl(h, 0.20, 0.35, 2.5, _mat(0.35, 0.22, 0.12), Vector3(0, 1.25, 0), name + "_Trunk")
	_sphere(h, 2.5, _mat(0.15, 0.42, 0.16), Vector3(0, 4.0, 0), name + "_Canopy")

func _lamp152(parent: Node3D, idx: int, pos: Vector3, dark_mat: Material, head_mat: Material) -> void:
	var h: Node3D = Node3D.new()
	h.name = "Lamp152_%d" % idx
	h.position = pos
	parent.add_child(h)
	_box(h, Vector3(0.12, 3.0, 0.12), dark_mat, Vector3(0, 1.5, 0), "Lamp152_%d_Pole" % idx)
	var head: MeshInstance3D = _box(h, Vector3(0.20, 0.12, 0.20), head_mat, Vector3(0, 3.05, 0), "Lamp152_%d_Head" % idx)
	head.visible = false
	_night_items.append(head)
	var omni: OmniLight3D = OmniLight3D.new()
	omni.name = "Lamp152_%d_Omni" % idx
	omni.position = Vector3(0, 3.0, 0)
	omni.light_color = Color(1.0, 0.85, 0.55)
	omni.light_energy = 1.5
	omni.omni_range = 22.0
	omni.shadow_enabled = false
	omni.visible = false
	h.add_child(omni)
	_night_items.append(omni)

func _apply() -> void:
	var world: Node = get_parent()
	if world == null:
		return
	_done = true
	var holder: Node3D = Node3D.new()
	holder.name = "Expansion152"
	world.add_child(holder)
	var dark: StandardMaterial3D = _mat(0.15, 0.15, 0.15)
	var asphalt: StandardMaterial3D = _mat(0.22, 0.22, 0.22)
	var white: StandardMaterial3D = _mat(0.95, 0.95, 0.95)
	var dirt: StandardMaterial3D = _mat(0.55, 0.42, 0.28)
	var ground152: StandardMaterial3D = _mat(0.55, 0.48, 0.32)
	var mats: Dictionary = {
		"plaster": _mat(0.85, 0.78, 0.62),
		"trim": _mat(0.95, 0.92, 0.82),
		"wood": _mat(0.45, 0.30, 0.18),
		"glass": _mat(0.65, 0.80, 0.85, 0.1, 0.1),
		"glow": _mat(1.0, 0.85, 0.55, 0.0, 0.0, 1.2),
		"roof": _mat(0.55, 0.30, 0.22),
	}
	## 1. New ground plane (DATA-BACKED direction: east; S97 body pattern).
	_ground_plane(holder, Vector2(800.0, 920.0), Vector3(3450.0, 0.0, -50.0), ground152, "GroundEast152")
	## 2. East road, drivable (DATA-BACKED corridor: straight east on z=0,
	##    continuing TrackEast97; S133 paint, slab top 0.13 above the
	##    track's 0.12 to avoid a coplanar z-fight).
	_box(holder, Vector3(955.0, 0.12, 12.0), asphalt, Vector3(2922.5, 0.07, 0), "RoadEast152_Slab")
	_box(holder, Vector3(955.0, 0.03, 0.25), white, Vector3(2922.5, 0.14, 5.5), "RoadEast152_EdgeN")
	_box(holder, Vector3(955.0, 0.03, 0.25), white, Vector3(2922.5, 0.14, -5.5), "RoadEast152_EdgeS")
	_box(holder, Vector3(955.0, 0.30, 0.50), _mat(0.60, 0.60, 0.60), Vector3(2922.5, 0.15, 6.25), "RoadEast152_CurbN")
	_box(holder, Vector3(955.0, 0.30, 0.50), _mat(0.60, 0.60, 0.60), Vector3(2922.5, 0.15, -6.25), "RoadEast152_CurbS")
	var dash_count: int = 0
	for i in range(79):
		var dx: float = 2455.0 + float(i) * 12.0
		_box(holder, Vector3(4.0, 0.03, 0.30), white, Vector3(dx, 0.14, 0), "RoadEast152_Dash_%d" % i)
		dash_count += 1
	_box(holder, Vector3(400.0, 0.12, 8.0), dirt, Vector3(3600.0, 0.06, 0), "TrackEast152_Dirt")
	## 3. East settlement, PATTERN-FOLLOWING (6 houses + patches).
	var east_houses: Array = [
		[Vector2(3180.0, -20.0), 0.0], [Vector2(3220.0, -20.0), 0.0], [Vector2(3260.0, -20.0), 0.0],
		[Vector2(3200.0, 20.0), PI], [Vector2(3240.0, 20.0), PI], [Vector2(3280.0, 20.0), PI],
	]
	for i in range(east_houses.size()):
		var e: Array = east_houses[i] as Array
		var p: Vector2 = e[0] as Vector2
		var ry: float = e[1] as float
		_house152(holder, "House152_E%d" % i, Vector3(p.x, 0.0, p.y), ry, mats)
		_box(holder, Vector3(8.0, 0.06, 8.0), dirt, Vector3(p.x, 0.03, p.y), "Ground152_E%d" % i)
	## 4. Mindon-south infill, PATTERN-FOLLOWING, S138 guard (<= 3).
	var targets: Array = [Vector2(170.0, 140.0), Vector2(220.0, 150.0), Vector2(150.0, 180.0)]
	var offsets: Array = [Vector2(0, 0), Vector2(8, 0), Vector2(-8, 0), Vector2(0, 8), Vector2(0, -8), Vector2(10, 10), Vector2(-10, -10), Vector2(12, 0), Vector2(0, 12), Vector2(-12, 0), Vector2(0, -12), Vector2(10, -10), Vector2(-10, 10)]
	for ti in range(targets.size()):
		var t: Vector2 = targets[ti] as Vector2
		var placed: bool = false
		for off in offsets:
			var o: Vector2 = off as Vector2
			var cx: float = t.x + o.x
			var cz: float = t.y + o.y
			if _site_clear(world, cx, cz, 2.5, 3.5):
				_house152(holder, "House152_S%d" % ti, Vector3(cx, 0.0, cz), PI, mats)
				_box(holder, Vector3(8.0, 0.06, 8.0), dirt, Vector3(cx, 0.03, cz), "Ground152_S%d" % ti)
				_placed_infill += 1
				_infill_pos.append(Vector2(cx, cz))
				placed = true
				break
		if not placed:
			print("REALISM152 infill target %s SKIPPED (no clear site)" % str(t))
	## 5. Walkers (world children — npc.gd needs ../Player + ../DayNight).
	## Homes sit in FRONT of the houses (clear of the 5.24x7.24
	## house solids): Villager19's first home (3180,-20) was the
	## House152_E0 centre itself — the walker spawned inside the
	## solid, sank to y 0.15 and could not move (sim152 first run:
	## feet -0.45, displacement 0.30). Fixed here, not in the sim.
	_walker152(world, "Villager19", Vector2(3170.0, -14.0), Vector2(3200.0, -10.0), 8.0)
	_walker152(world, "Villager20", Vector2(3230.0, -14.0), Vector2(3240.0, -10.0), 8.0)
	_walker152(world, "Villager21", Vector2(3210.0, 14.0), Vector2(3220.0, 10.0), 8.0)
	_walker152(world, "Villager22", Vector2(3270.0, 14.0), Vector2(3260.0, 10.0), 8.0)
	_walker152(world, "Villager23", Vector2(165.0, 130.0), Vector2(190.0, 145.0), 8.0)
	_walker152(world, "Villager24", Vector2(215.0, 160.0), Vector2(190.0, 145.0), 8.0)
	## 6. Parked cars (primitive, no colliders, off-lane).
	var car_cols: Array = [_mat(0.75, 0.15, 0.10), _mat(0.15, 0.35, 0.65), _mat(0.85, 0.85, 0.85), _mat(0.20, 0.55, 0.25)]
	var car_pos: Array = [Vector3(3160.0, 0.0, 10.0), Vector3(3220.0, 0.0, -10.0), Vector3(3290.0, 0.0, 10.0), Vector3(3330.0, 0.0, -10.0)]
	for i in range(4):
		_parked152(holder, "Parked152_%d" % i, car_pos[i] as Vector3, car_cols[i] as Material, dark)
	## 7. Trees: roadside 12 + settlement 6 + track 4 = 20.
	var tree_i: int = 0
	for i in range(6):
		var tx: float = 2550.0 + float(i) * 160.0
		_tree152(holder, "Tree152_%d" % tree_i, Vector3(tx, 0.0, 12.0))
		tree_i += 1
		_tree152(holder, "Tree152_%d" % tree_i, Vector3(tx, 0.0, -12.0))
		tree_i += 1
	for tp in [Vector3(3140.0, 0.0, 26.0), Vector3(3140.0, 0.0, -26.0), Vector3(3260.0, 0.0, 26.0), Vector3(3260.0, 0.0, -26.0), Vector3(3340.0, 0.0, 26.0), Vector3(3340.0, 0.0, -26.0)]:
		_tree152(holder, "Tree152_%d" % tree_i, tp as Vector3)
		tree_i += 1
	for tp in [Vector3(3450.0, 0.0, -10.0), Vector3(3550.0, 0.0, -10.0), Vector3(3650.0, 0.0, -10.0), Vector3(3750.0, 0.0, -10.0)]:
		_tree152(holder, "Tree152_%d" % tree_i, tp as Vector3)
		tree_i += 1
	## 8. Fields 4 (clear of road corridor + settlement footprints).
	var field_cols: Array = [_mat(0.35, 0.55, 0.20), _mat(0.55, 0.60, 0.25), _mat(0.30, 0.50, 0.22), _mat(0.60, 0.58, 0.30)]
	var field_pos: Array = [Vector3(3150.0, 0.0, -60.0), Vector3(3250.0, 0.0, 60.0), Vector3(3450.0, 0.0, -60.0), Vector3(3550.0, 0.0, 60.0)]
	for i in range(4):
		_box(holder, Vector3(40.0, 0.10, 30.0), field_cols[i] as Material, Vector3((field_pos[i] as Vector3).x, 0.05, (field_pos[i] as Vector3).z), "Field152_%d" % i)
	## 9. Lamps: road 4 + settlement 2 + infill 2 = 8 (S124 pool
	## pattern). Infill pools added after sim143's night audit:
	## the 2 Mindon-south residents live 25-30 m from the nearest
	## Mindon pool, so their night area was dark (V24 failed the
	## S143 night-lit gate twice); each pool sits 5 m from its
	## home centre (V24 home (215,160) -> (215,155); V23 home
	## (165,130) -> (165,135)), clear of the infill house solids
	## by >= 1.4 m. Same standard S124/S127/S131 apply to every
	## inhabited area: new homes get night light, not just glows.
	var head_mat: StandardMaterial3D = _mat(1.0, 0.85, 0.55, 0.0, 0.0, 1.2)
	var lamp_pos: Array = [Vector3(2600.0, 0.0, -10.0), Vector3(2900.0, 0.0, -10.0), Vector3(3200.0, 0.0, -10.0), Vector3(3350.0, 0.0, -10.0), Vector3(3190.0, 0.0, 12.0), Vector3(3310.0, 0.0, 12.0), Vector3(215.0, 0.0, 155.0), Vector3(165.0, 0.0, 135.0)]
	for i in range(8):
		_lamp152(holder, i, lamp_pos[i] as Vector3, dark, head_mat)
	## 10. Mountains, BACKDROP ONLY (no colliders, outside the clamp).
	var rock: StandardMaterial3D = _mat(0.45, 0.47, 0.45)
	var forest: StandardMaterial3D = _mat(0.16, 0.38, 0.18)
	for i in range(23):
		var mx: float = -600.0 + float(i) * 200.0
		var mh: float = 60.0 + _hash01("mtnN%d" % i) * 60.0
		var mr: float = 80.0 + _hash01("mtnNr%d" % i) * 80.0
		var mm: Material = rock if i % 2 == 0 else forest
		var mi: MeshInstance3D = _cyl(holder, 1.0, mr, mh, mm, Vector3(mx, mh * 0.5, -650.0), "Mountain152_N%d" % i)
		mi.material_override = mm
	for j in range(6):
		var mz: float = -400.0 + float(j) * 160.0
		var mh2: float = 60.0 + _hash01("mtnE%d" % j) * 50.0
		var mr2: float = 80.0 + _hash01("mtnEr%d" % j) * 70.0
		var mm2: Material = rock if j % 2 == 0 else forest
		_cyl(holder, 1.0, mr2, mh2, mm2, Vector3(4050.0, mh2 * 0.5, mz), "Mountain152_E%d" % j)
	## Night-gate initial state from LIVE daylight (S131 pattern).
	var dn: Node = world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		_night_now = float(dn.call("daylight")) < 0.15
		for item in _night_items:
			var n2: Node3D = item as Node3D
			if n2 != null and is_instance_valid(n2):
				n2.visible = _night_now
	print("REALISM152 dressed: ground 1, road dashes %d, east houses 6, infill %d at %s, walkers 6, parked 4, trees %d, fields 4, lamps 8, mountains 29, night items %d" % [dash_count, _placed_infill, str(_infill_pos), tree_i, _night_items.size()])
