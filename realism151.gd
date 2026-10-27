extends Node3D

## Slice 151 — HOUSE DAY READ AUDIT ROUND (audit-first, live
## probed before shipping). Audit151 first ran fast-forwarded
## and fired BEFORE scale97's frame-120 holder creation
## (S128 artifact class): House97/Stilt97/HamletHouse75 read
## MISSING and FishingHut19 read y=36. Audit151b re-ran with a
## holders-ready gate (House97_1 + Stilt97_5 + HamletHouse75_0
## present AND Realism128/138/148 _done) and audit151c
## followed up with name dumps + a material-share scan. The
## corrected day read, per family (LIVE tree, verbatim
## children incl. @-renamed, holder descendants only so the
## MDHouse8/MindonPost overlap cannot pollute):
## - ROOFS: every house family carries its roof at its top
##   (roof_top == ymax): House97/Stilt97 pitched RoofS/N97
##   (0.252 rad, apex 6.95/6.51/6.37), School Roof101
##   (11.48), StiltHouse13 StiltRoof13 (6.89), House6/MD/Oo
##   Roof102 pairs (11.79/9.82/6.55), hamlet Roof75 (6.84),
##   FishingHut19 (2.15), LakesideHut19 HutRoof19 (2.15),
##   StiltHouse17_5 StiltRoof17 (3.40). NO GAP.
## - WINDOWS/DOORS (classifier correction: the first census
##   counted only the substring "Window" and scored 0 for
##   houses whose windows are named Win*/Win102/Win97 —
##   S134's "Snack"/"Header" miss, same class): corrected
##   Win* counts are House97_1 4 (WinG97/WinU97), Stilt97 2
##   (Win97), StiltHouse13 12 (Win56) + 12 Sill/Frame101,
##   School13 19 (6 WinU101 + 6 Window72 + 6 WindowFrame72
##   + WindowGlowSchool, probe151e), MDHouse4/OoHouse1 16 (Win102) + 16
##   Sill/Frame102 each, HamletHouse75_0/1 4 (WinBack101
##   + Window98), House5's plot a complete 102 house
##   (realism102 line 370: (-24,-8); its 22 scene meshes
##   are hidden as REPLACED, same pattern as House1-4 ->
##   House97). Every family has >= 1 door. NO GAP except
##   the one shipped below.
## - STAIRS: every stilt/raised house has them (Stilt97 4
##   Steps, StiltHouse13 6 Steps + rails + newels +
##   stringers, hamlet 4-10 Steps, 102 houses Step102_A/B).
##   NO GAP.
## - VERANDA: no mesh is NAMED veranda anywhere, but every
##   stilt house reads its raised platform (Stilt97 Floor97
##   + 4 Posts, StiltHouse13 Deck + 4 Pillars, Stilt17/18
##   Deck + 4 Legs). A separate veranda mesh would be
##   redundant geometry, not a read fix. NOT A GAP.
## - WALL VARIETY: families read DISTINCT (village plaster
##   tan, stilt dark wood, 102 cream, hamlet cream + brown
##   walls, school 21 albedos). NO GAP.
## - GROUNDED: all ymin 0.00 except StiltHouse13's stair
##   stringer AABB -0.30 (angled beam; its steps start at
##   0.00 — AABB artifact, not sinking) and Stilt17/18
##   legs -1.00..1.00 (posts buried 1 m, foundations) with
##   deck blocks -0.30..2.70 overlapping them (continuous
##   structure, not floating). FishingHut19 grounded at
##   0.00..2.15 — S128 holds in the holders-ready run.
##   NO GAP.
## - S103 EXCLUDED, NOT GAPS: MDHouse1/2/3/6/10 stay 2/2
##   meshes (Walls + Roof), bare + unscaled PERMANENTLY
##   by S103 decision. Cited, not "fixed".
## - SEASON LEAK, OBSERVED NOT SHIPPED (mechanism proven
##   by audit151c's material-share scan, effect mild):
##   102 trim/door/upper colours shift per season because
##   their SHARED materials are tinted through name
##   collisions: _trim_mat (783 sharers) via CanopyRoof102
##   (realism102 line 810 uses _trim_mat for a mesh whose
##   name contains "Canopy", so chill_controller62 AND
##   realism146 both tint it); Door102's mat (65 sharers)
##   via CanopyPost102_35_27; Upper102's mat (15 sharers)
##   via Ground102 (realism146's Ground* target). Trim
##   0.83,0.79,0.78 -> 0.87,0.79,0.61 -> 0.79,0.84,0.70
##   across seasons; Win102 glass (222 sharers, all
##   Win102/WinB102) and Roof102 (1 sharer) do NOT move.
##   This is NOT a washout and NOT a day-read gap (the
##   houses still read, tinted like the ground around
##   them); freezing trim while the world tints would be
##   lateral, not a 6 m improvement, and it would touch
##   S146's season system. Fix sketched for a future
##   slice or owner call: clone the material for the 3
##   name-colliding meshes only. S146's stated "buildings
##   NOT tinted" scope is deviated from in letter, not
##   in visible harm — stated, not hidden.
## - PAVILIONS, OBSERVED NOT SHIPPED: StiltHouse18_6 is a
##   roofless deck platform (S103-excluded pavilion, not a
##   house missing its roof — adding one would invent
##   structure against this slice's brief) and
##   StiltHouse17_5's roof sits 0.30 m above its deck top
##   (sub-6 m-gate marginal; closing it needs a geometry
##   move, also against the brief). Owner phone verdict
##   decides whether either reads as broken.
## SHIPPED (12 meshes, 0 colliders, 0 .tscn edits): the ONE
## proven day-read gap — hamlet front windows missing on
## houses 2 and 3. Realism98's restyle comment says "the
## S94 restyle left these houses windowless" and its loop
## is `for idx in [0, 1]` — houses 2/3 never got front
## glass, while their front Sill101_F/Frame101_F frames
## (S101) sit empty. Live: HamletHouse75_0/1 Win* = 4
## (WinBack101 + Window98), 75_2/75_3 Win* = 2 (WinBack101
## only). Fix adds realism98's EXACT window set as
## children of 75_2/75_3 (same local coords, same sizes,
## same materials — door span -0.5..0.5, so +/-2.0 is
## clear per realism98's comment): glass 0.70x0.70x0.10
## at local (+/-2.0, 2.40, -3.06), shutters
## 0.35x0.70x0.05 at (+/-2.0 -/+ 0.525, 2.40, -3.07).
## Idempotent: a house that already has Window98_*
## children is skipped, never duplicated. Night
## regression: S124 Window124 36/36 at night, 0/36 at
## day (proven in both audit151 runs); this dressing is
## ungated day AND night like realism98's windows, so
## night is untouched by construction.
## NOT touched: S137 anchor/airplane decisions (owner
## decisions); moon halo (S127, owner verdict pending);
## S146 season tint logic itself; no .tscn edits; no
## economy/combat/map changes.

var _frames: int = 0
var _done: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism151") != null:
		return
	var n := Node3D.new()
	n.name = "Realism151"
	n.set_script(load("res://realism151.gd"))
	world.call_deferred("add_child", n)


static func _mat(c: Color, rough: float, met: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = met
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
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _apply(world: Node3D) -> void:
	if world == null:
		return
	var glass: StandardMaterial3D = _mat(Color(0.15, 0.25, 0.35, 1.0), 0.2, 0.1)
	var shutter_m: StandardMaterial3D = _mat(Color(0.35, 0.25, 0.15, 1.0), 0.9)
	var n: int = 0
	for idx in [2, 3]:
		var grp: Node = _find_recursive(world, "HamletHouse75_%d" % idx)
		if grp == null:
			return
		var g3: Node3D = grp as Node3D
		var has_win: bool = false
		for c in g3.get_children():
			if String(c.name).begins_with("Window98_"):
				has_win = true
				break
		if has_win:
			continue
		for sx in [-1.0, 1.0]:
			var wx: float = sx * 2.0
			_box(g3, Vector3(0.70, 0.70, 0.10), glass, Vector3(wx, 2.40, -3.06), "Window98_%d" % int(sx))
			_box(g3, Vector3(0.35, 0.70, 0.05), shutter_m, Vector3(wx - 0.525, 2.40, -3.07), "Shutter98_%d_L" % int(sx))
			_box(g3, Vector3(0.35, 0.70, 0.05), shutter_m, Vector3(wx + 0.525, 2.40, -3.07), "Shutter98_%d_R" % int(sx))
			n += 3
	_done = true
	print("REALISM151 dressed: hamlet_front_windows=", n)


func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 860:
		_apply(get_parent() as Node3D)
