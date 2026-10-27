extends Node3D

## Slice 146 — seasons audit round (audit-first, live-probed before
## shipping). Audit146/146b measured the season system on the LIVE
## tree (never the scene file alone, S144 lesson) and found it REAL
## but INCOMPLETE: the controller (chill_controller62, capture at
## frame >= 5) tints only GroundMesh + the canopy materials that
## existed at frame 5, while the ground the player actually walks on
## and the densest foliage at play viewpoints never change:
## - GroundMesh: summer (0.94,0.92,0.634) / rainy (0.865,1,0.81) /
##   winter (0.902,0.96,0.88) — strong summer-golden read.
## - TreeTop (scene, 28/28): re-tint every season change.
## - Canopy122 (S122 second canopies, 140, nearest village centre +
##   stops — the densest foliage at play viewpoints): 0/140 change
##   (Realism122 runs at frame >= 620, source, long after the
##   frame-5 capture; audit146's fast-forward run ARTIFICIALLY
##   captured them — the S127/S128 fast-forward artifact class —
##   and audit146b's natural run corrected it).
## - Chill62_Canopy: 2/38 change; Canopy64: 2/26 change (the 2s are
##   meshes sharing material objects with captured canopies).
## - Ground122/123/128/138 patches (village plaza, stops, route,
##   Oo yards — the ground underfoot at every play viewpoint):
##   0 change in every season.
## - Rainy-only channels all work: Rain17 on, Puddle72 4/4 visible,
##   MainRoad62 wet (rough 0.35 + albedo x0.75), bus wipers on.
## - Sun/sky tints work (summer (1,0.96,0.86) / rainy (0.88,0.93,1) /
##   winter (0.96,0.97,1)); rainy vs winter colour differs only
##   ~4-9% and is distinguished by rain, not colour (same as the
##   base plane's own behaviour — not a new gap).
## FIX (this file, runtime dressing only, zero .tscn edits): tint the
## COMPLEMENT — every Ground* patch except GroundMesh itself, and
## every Canopy/TreeTop mesh whose material is NOT already in the
## controller's captured set — with the controller's OWN multipliers
## (read from chill_controller62.gd constants via preload, the
## City56Script pattern — never re-typed values that could drift).
## Disjoint sets by construction (cap guard), so no double tint and
## no fight with the controller. Bases are stored per material
## object and every application multiplies from the BASE, never from
## the current value, so repeated cycles return EXACTLY to start
## (no stacking drift, proven by sim146). The target set is
## re-collected on every season change, so materials added by later
## dressing are picked up self-healingly (a new material object's
## base is its current untinted albedo — unless the controller
## already tints it, in which case the cap guard skips it).
## Runs at frame >= 840, after Realism145's 820 pass, so every
## S122-S145 patch/canopy exists. Writes happen ONLY on season
## change (one int compare per frame, zero per-frame writers, S120
## pattern); ungated day + night (albedo tints, same as controller).
## NOT tinted, with reasons: GroundMesh itself (controller's);
## water (S130 ripple material — ground multipliers would be wrong);
## roads (MainRoad62 has its own rainy wet/dry system, S66);
## buildings, vehicles, people, animals (not ground/foliage);
## OutPatch59 tree bases (tiny 1.8 m bases, different system);
## emissive materials (glows/lamps — never tinted, controller rule);
## palms (controller's canopy definition is Canopy/TreeTop only).
## LIMITS (same class as the controller's own capture): meshes
## auto-renamed to @MeshInstance3D@N by Godot duplicate-name rules
## are missed by name matching — but they share material objects
## with their named siblings in practice, so tinting the sibling's
## material tints them too. S137 anchor/airplane decisions untouched
## (owner decisions). Day/night cycle timing untouched (S99).

const Chill62Script = preload("res://chill_controller62.gd")

var _frames: int = 0
var _done: bool = false
var _applied_season: int = -1
var _base: Dictionary = {}

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism146") != null:
		return
	var n := Node3D.new()
	n.name = "Realism146"
	n.set_script(load("res://realism146.gd"))
	world.call_deferred("add_child", n)

func _leaf_mul_for(season: int) -> Color:
	# Constants are static members of the preloaded script (dot
	# access — .get() on a script class is a parse error, proven by
	# sim146's first run). Fallback copies the same values.
	var arr: Array = Chill62Script.LEAF_MUL
	if arr.size() == 3:
		return arr[clampi(season, 0, 2)] as Color
	var fall: Array = [Color(1.0, 0.94, 0.78, 1.0), Color(0.9, 1.0, 0.9, 1.0), Color(0.95, 0.95, 1.0, 1.0)]
	return fall[clampi(season, 0, 2)] as Color

func _ground_mul_for(season: int) -> Color:
	var arr: Array = Chill62Script.GROUND_MUL
	if arr.size() == 3:
		return arr[clampi(season, 0, 2)] as Color
	var fall: Array = [Color(1.0, 0.92, 0.72, 1.0), Color(0.92, 1.0, 0.92, 1.0), Color(0.96, 0.96, 1.0, 1.0)]
	return fall[clampi(season, 0, 2)] as Color

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var ctrl: Node = world.get_node_or_null("ChillController62")
	if ctrl == null or ctrl.get("_season") == null:
		return
	var season: int = clampi(int(ctrl.get("_season")), 0, 2)
	var cap: Dictionary = {}
	if ctrl.get("_canopy_base") != null:
		cap = ctrl.get("_canopy_base")
	var gmul: Color = _ground_mul_for(season)
	var lmul: Color = _leaf_mul_for(season)
	var stack: Array = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if not (n is MeshInstance3D):
			continue
		var mi: MeshInstance3D = n as MeshInstance3D
		var nm: String = String(mi.name)
		var is_ground: bool = nm.begins_with("Ground") and nm != "GroundMesh"
		var is_canopy: bool = nm.contains("Canopy") or nm.begins_with("TreeTop")
		if not is_ground and not is_canopy:
			continue
		if mi.get_surface_override_material_count() <= 0:
			continue
		var mat: StandardMaterial3D = mi.get_surface_override_material(0) as StandardMaterial3D
		if mat == null or mat.emission_enabled:
			continue
		if cap.has(mat):
			continue
		var base: Color
		if _base.has(mat):
			base = _base[mat] as Color
		else:
			base = mat.albedo_color
			_base[mat] = base
		var mul: Color = gmul if is_ground else lmul
		mat.albedo_color = Color(base.r * mul.r, base.g * mul.g, base.b * mul.b, 1.0)
	_applied_season = season
	_done = true

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 840:
		_apply(get_parent() as Node3D)
		return
	if not _done:
		return
	var world: Node = get_parent() as Node3D
	if world == null:
		return
	var ctrl: Node = world.get_node_or_null("ChillController62")
	if ctrl == null or ctrl.get("_season") == null:
		return
	var season: int = clampi(int(ctrl.get("_season")), 0, 2)
	if season != _applied_season:
		_apply(world)
