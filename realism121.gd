extends Node3D
## Slice 121: owner-supplied GLB villager models (owner action
## 2026-10-24 ~23:00 +07: sent myanmar_traditional_3d_characters_glb.zip,
## 4 files, after the parent told him Godot needs .glb; owner said
## "try it"). Runtime dressing only, no scene touched.
##
## HONEST LIMITS, READ FIRST — these models are STATIC, vertex-coloured,
## single-mesh figures, verified live in the parent's glb-trial AND
## re-verified by import in this project: each file is valid glTF 2.0
## (generator MyanmarGame3DBuilder), exactly 1 mesh + 1 material,
## 0 skins (NO skeleton/rig), 0 animations (NO walk/idle), 0 images,
## 0 textures, attributes COLOR_0 + NORMAL + POSITION only (no UVs).
## They are real modelled shapes — a genuine upgrade over the
## sphere/box/cylinder villagers — but they CANNOT walk with skeletal
## leg animation. Walking villagers get whole-body bob ONLY (vertical
## oscillation + slight forward lean while moving); there are no legs
## to swing, so no fake leg-swing is added. Never claim animated
## walking for these models.
## PEACEFUL-ONLY FLAG: the "fighter" model is a single merged mesh with
## no part names, so its appearance CANNOT be verified headless. It is
## included (the owner sent it; dropping his file unilaterally would
## be wrong), but the owner MUST check on his phone whether it
## carries a weapon — if he reports one, the next slice removes or
## replaces it. Do NOT claim it is weapon-free.
## FACING ASSUMPTION: model yaw is 0. npc.gd faces movement with
## rotation.y = atan2(dir.x, dir.z), which makes local +z the forward
## direction, so yaw 0 assumes the models face local +z. Facing
## cannot be verified headless (merged mesh, no render). If figures
## walk backward on the phone, the next slice adds PI yaw (and flips
## the lean sign) — a 1-line fix, stated here so it is not a surprise.
## SEATED FIGURES: a static mesh cannot sit (no rig). Bus riders
## keep the model visible at the seat origin, i.e. they read as
## standing passengers, NOT seated ones. This is the task's literal
## requirement (model moves WITH the figure on boarding) and it is
## safe: model top (1.70 + 0.04 = 1.74 m) stays below the old seated
## display top (head 1.62 + sphere r 0.22 = 1.84 m), so no new roof
## clipping vs the old display. Sinking the mesh into the seat to
## fake sitting is DEFERRED: bench/bus seat occlusion geometry is
## unverified headless, and a wrong sink would clip through floors
## on the phone. Owner may ask for it after seeing S121.
## HIDE-AND-REPLACE: old procedural parts are HIDDEN, never deleted,
## and re-hidden every frame by _enforce (realism117's mirror
## re-shows Arm117 parts when a rider alights — this node is added
## after Realism117, so its _process runs after the mirror's and the
## re-hide wins in the same frame, before render). DestBoard86
## (rider destination sign) and DialogueLabel/PromptLabel are NEVER
## hidden. Labels are repositioned to keep the old clearance above
## the new (shorter) head: dialogue +0.65 m, prompt +1.25 m.
## VILLAGER ORIGIN: villager nodes sit ~1.0 m above ground
## (CapsuleShape3D_player: radius 0.4, height 1.2 -> bottom at local
## -1.0, matching Longyi bottom -0.55 - 0.9/2 = -1.00), so the model
## base is computed from the LIVE capsule shape, NOT hardcoded:
## base_y = -(height/2 + radius) + 0.04. Bus-stop figure origins sit
## at ground (Body74 spans 0.0..1.10), so their base is +0.04.
## Model feet sit at local y = -0.04 in every file, hence +0.04.
## PERFORMANCE: each model instance is 1 draw call vs ~8+ parts for
## a procedural figure, and all instances share one mesh resource,
## so this REDUCES draw calls per figure; ~15.6K new verts across
## all 4 models is trivial. Model names (Model121) match NONE of
## perf120's hide prefixes (Blade93_/94_/95_/110_, Reed57_/62/107_/
## 108_), and models are people (gameplay role), so perf120 must
## NEVER hide them — the sim proves models stay visible at all
## distances while far lights cull and small dressing hides.
## NOT touched: perf120 radii/logic, S119 menu, bus/minibus/big bus
## (Slice 81 limit), tuk-wheel scene file (open owner/parent
## decision), S95 car driver exclusion, vehicle driver/rider figures
## (tight measured headroom — a 1.6 m model in a car seat would clip
## roofs; and the task's figure list does not ask for them), the
## Player figure (not asked), no new gameplay system.

const MODEL_PATHS: Array = [
	"res://models/1_child_cowherd_character.glb",
	"res://models/2_youth_weaver_character.glb",
	"res://models/3_adult_fighter_character.glb",
	"res://models/4_elder_villager_character.glb",
]
# Measured heights (m) from the glTF JSON AABBs, same order as paths.
const MODEL_HEIGHTS: Array = [1.355, 1.635, 1.70, 1.62]
const CHILD_CUT: float = 0.18
const BOB_AMP: float = 0.04
const BOB_RATE: float = 7.0
const LEAN: float = 0.05
const FRAME_GATE: int = 600

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0
var _scenes: Array = []
var _walkers: Array = []
var _stops: Array = []


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism121") != null:
		return
	var n := Node3D.new()
	n.name = "Realism121"
	n.set_script(load("res://realism121.gd"))
	world.call_deferred("add_child", n)


func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= FRAME_GATE:
		_done = true
		_load_models()
		_apply(get_parent() as Node3D)
	if not _done:
		return
	_scan_t += delta
	if _scan_t >= 1.0:
		_scan_t = 0.0
		_apply(get_parent() as Node3D)
	_bob(delta)
	_enforce()


static func _hash01(s: String) -> float:
	# Position-weighted sum, NOT the classic running hash: sequential
	# names ("Villager1".."Villager18") differ only in the last char,
	# and a running hash (h*31 + c) maps them to a ~0.009 band, so
	# the old version gave all villagers ONE adult model. Weighting
	# by position spreads consecutive names across the range (last
	# char contributes (i+1)*31, i.e. 279 per digit step here), so
	# child + all three adult models actually appear in the village.
	var h: int = 0
	for i in range(s.length()):
		h = (h + int(s.unicode_at(i)) * (i + 1) * 31) % 1000003
	return float(h % 1000) / 1000.0


func _load_models() -> void:
	if not _scenes.is_empty():
		return
	for p in MODEL_PATHS:
		var sc := load(str(p)) as PackedScene
		if sc == null:
			push_error("Realism121: FAILED to load model " + str(p))
		_scenes.append(sc)


func _pick_scene(fig_name: String) -> PackedScene:
	if _scenes.is_empty():
		return null
	var h := _hash01(fig_name)
	var idx := 0
	if h < CHILD_CUT:
		idx = 0
	else:
		idx = 1 + (int(h * 10.0) % 3)
	var sc := _scenes[idx] as PackedScene
	if sc == null:
		for s in _scenes:
			if s != null:
				return s as PackedScene
		return null
	return sc


static func _hide_meshes(fig: Node3D) -> void:
	# Hide every MeshInstance3D under fig EXCEPT the Model121 subtree
	# and the DestBoard86 subtree (rider destination sign). Labels
	# (Label3D) and CollisionShape3D are not meshes and survive.
	var stack: Array = []
	for c in fig.get_children():
		stack.append(c)
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x.name == "Model121" or x.name == "DestBoard86":
			continue
		if x is MeshInstance3D:
			(x as MeshInstance3D).visible = false
		for c in x.get_children():
			stack.append(c)


func _dress_villager(fig: Node3D) -> void:
	if fig == null or fig.has_meta("dressed121"):
		return
	var sc := _pick_scene(String(fig.name))
	if sc == null:
		return
	var inst := sc.instantiate() as Node3D
	if inst == null:
		return
	inst.name = "Model121"
	var base_y := -0.96
	var col := fig.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null and col.shape is CapsuleShape3D:
		var cap := col.shape as CapsuleShape3D
		base_y = -(cap.height / 2.0 + cap.radius) + 0.04
	var h := _hash01(String(fig.name))
	var midx := 0
	if h < CHILD_CUT:
		midx = 0
	else:
		midx = 1 + (int(h * 10.0) % 3)
	inst.position = Vector3(0.0, base_y, 0.0)
	fig.add_child(inst)
	var top := base_y + float(MODEL_HEIGHTS[midx])
	var dlg := fig.get_node_or_null("DialogueLabel") as Node3D
	if dlg != null:
		dlg.position.y = top + 0.65
	var prm := fig.get_node_or_null("PromptLabel") as Node3D
	if prm != null:
		prm.position.y = top + 1.25
	_hide_meshes(fig)
	fig.set_meta("dressed121", true)
	_walkers.append({"fig": fig, "model": inst, "base_y": base_y, "phase": 0.0, "last": fig.global_position})


func _dress_stop(fig: Node3D) -> void:
	if fig == null or fig.has_meta("dressed121"):
		return
	var sc := _pick_scene(String(fig.name))
	if sc == null:
		return
	var inst := sc.instantiate() as Node3D
	if inst == null:
		return
	inst.name = "Model121"
	inst.position = Vector3(0.0, 0.04, 0.0)
	fig.add_child(inst)
	_hide_meshes(fig)
	fig.set_meta("dressed121", true)
	_stops.append(fig)


func _apply(world: Node3D) -> void:
	if world == null:
		return
	var stack: Array = [world]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x != world and x is Node3D:
			var nm := String(x.name)
			if nm.begins_with("Villager"):
				_dress_villager(x as Node3D)
			elif nm.begins_with("Waiting74_") or nm.begins_with("Alighted75_"):
				_dress_stop(x as Node3D)
		for c in x.get_children():
			stack.append(c)


func _bob(delta: float) -> void:
	var dead: Array = []
	for w in _walkers:
		var fig := w["fig"] as Node3D
		var model := w["model"] as Node3D
		if fig == null or not is_instance_valid(fig) or model == null or not is_instance_valid(model):
			dead.append(w)
			continue
		var cur := fig.global_position
		var prev := w["last"] as Vector3
		var moved := Vector2(cur.x - prev.x, cur.z - prev.z).length()
		w["last"] = cur
		var base_y := float(w["base_y"])
		if moved > 0.001:
			w["phase"] = float(w["phase"]) + delta * BOB_RATE
			model.position.y = base_y + absf(sin(float(w["phase"]))) * BOB_AMP
			model.rotation.x = lerpf(model.rotation.x, LEAN, minf(1.0, delta * 8.0))
		else:
			model.position.y = lerpf(model.position.y, base_y, minf(1.0, delta * 8.0))
			model.rotation.x = lerpf(model.rotation.x, 0.0, minf(1.0, delta * 8.0))
	for d in dead:
		_walkers.erase(d)


func _enforce() -> void:
	# Re-hide old parts every frame: realism117's mirror re-shows
	# Arm117 parts when a rider alights, and late dressing could add
	# meshes after the 600-frame pass. This runs after the mirror
	# (Realism121 is added after Realism117), so it wins same-frame.
	for fig in _stops:
		if fig != null and is_instance_valid(fig):
			_hide_meshes(fig as Node3D)
	for w in _walkers:
		var fig := w["fig"] as Node3D
		if fig != null and is_instance_valid(fig):
			_hide_meshes(fig)
