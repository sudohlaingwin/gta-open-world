extends Node3D
## Slice 163: REALISTIC WALKING PEOPLE (owner order 2026-10-28
## 22:48 +07: arms that SWING, joints that BEND and STRETCH,
## clothes + longyi almost like the real world).
##
## THE GLB DECISION (stated openly, do not soften it): the
## owner-supplied GLBs (S121) are STATIC single meshes — 0 skins,
## 0 animations, 1 merged mesh each. Godot cannot auto-rig them,
## so a GLB figure CANNOT bend an elbow or a knee, ever. Walking
## figures therefore go back to SEGMENTED procedural builds with
## real pivots (shoulder / elbow / hip / knee / ankle), driven by
## gait163.gd. The owner's GLBs are NOT deleted and NOT unloaded:
## they stay visible on STANDING figures (bus-stop Waiting74_ /
## Alighted75_ figures, which never walk and where the GLB reads
## best). If the owner later supplies RIGGED animated GLBs
## (skeleton + walk clip), those integrate and replace the
## procedural walkers — that is the path to mocap-level realism,
## but this slice does not wait for it.
##
## TWO FIGURE TYPES (probed live, never assumed):
##  - TYPE A (Player + Villager1-18): S58/S94 figures exist under
##    ShoulderPivot58 / HipPivot58 / LongyiPivot58, but S121 hid
##    every mesh and shows a bobbing GLB instead. This slice
##    detaches them from Realism121's control (erases their entries
##    from its _walkers list, so its per-frame _enforce/_bob stop
##    touching them), hides the GLB, re-shows the S94 figure, and
##    performs limb surgery: elbow pivots (forearm/wrist/cuff/hand/
##    fingers reparented, baked -0.25 mesh bend zeroed into pivot
##    rotation) and knee pivots (Leg58 resized to a thigh, new shin
##    + ankle pivot + sandal under it).
##  - TYPE B (Villager19-24, S152): BARE bodies — S58 ran before
##    they existed, so they have no pivots, no torso, no head, only
##    the S121 GLB. This slice BUILDS their articulated figure from
##    scratch in S94's dimensions, materials, and sex split.
## GROUNDING: Type A villagers were never S148-lifted (their S94
## parts sit 0.40 m sunk, which is WHY S121's GLB base exists).
## Both types ride a Figure163 root at +0.43 for villagers (the
## S148-measured lift) and +0.00 for the player (already lifted),
## so soles land exactly on the S148 grounding bands.
## LONGYI SOLUTION: the tube stays (identity untouched: colours,
## bands, folds, male front knot) but its hem is raised via
## scale.y 0.78, so lower legs + sandals show below the hem and
## the knee bend READS while walking — exactly the stride a real
## longyi wearer shows. Hip swing is shortened (0.26 rad) for the
## same reason: shorter steps read MORE real in a longyi.
## NEVER touched: Model121 on standing figures, DestBoard86,
## DialogueLabel/PromptLabel (repositioned only, never hidden),
## straw hats (Hat58 stays hidden per S143 — with procedural heads
## they would now seat correctly, so restoring them is a 1-line
## owner decision, not shipped here), PlayerHat visibility (the
## outfit toggle owns it; this slice only reparents it under the
## torso pivot so it twists WITH the head), S157/S159/S160/S161,
## bus/minibus/big bus, no .tscn edits, no Zoom buttons.

const FRAME_GATE: int = 950
const LIFT_VILLAGER: float = 0.43
const LONGYI_SCALE_Y: float = 0.78
const GaitScript = preload("res://gait163.gd")

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0
var dressed_count: int = 0
var rebuilt_count: int = 0

static var _thigh_mesh: BoxMesh = null
static var _shin_mesh: BoxMesh = null
static var _white_top: StandardMaterial3D = null
static var _pink_top: StandardMaterial3D = null
static var _male_lg: StandardMaterial3D = null
static var _fema_lg: StandardMaterial3D = null
static var _femb_lg: StandardMaterial3D = null
static var _green_band: StandardMaterial3D = null
static var _pink_band: StandardMaterial3D = null
static var _white_band: StandardMaterial3D = null
static var _dark_mat: StandardMaterial3D = null
static var _heel_mat: StandardMaterial3D = null
static var _flower_mat: StandardMaterial3D = null
static var _flower_c: StandardMaterial3D = null
static var _mouth_mat: StandardMaterial3D = null
static var _black_hair: StandardMaterial3D = null
static var _skin_fallback: StandardMaterial3D = null


static func dress(world: Node) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism163") != null:
		return
	var n := Node3D.new()
	n.name = "Realism163"
	n.set_script(load("res://realism163.gd"))
	world.call_deferred("add_child", n)


static func _hash01(s: String) -> float:
	# EXACT replica of realism94's hash, so the sex split matches
	# S94's outfits mesh-for-mesh (male / female A / female B).
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0


static func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


static func _shared() -> void:
	if _thigh_mesh != null:
		return
	_thigh_mesh = BoxMesh.new()
	_thigh_mesh.size = Vector3(0.13, 0.425, 0.13)
	_shin_mesh = BoxMesh.new()
	_shin_mesh.size = Vector3(0.11, 0.425, 0.11)
	_white_top = _mat(Color(0.96, 0.96, 0.97, 1.0), 0.7)
	_pink_top = _mat(Color(0.95, 0.80, 0.85, 1.0), 0.7)
	_male_lg = _mat(Color(0.20, 0.15, 0.38, 1.0), 0.9)
	_fema_lg = _mat(Color(0.45, 0.20, 0.60, 1.0), 0.9)
	_femb_lg = _mat(Color(0.85, 0.50, 0.65, 1.0), 0.9)
	_green_band = _mat(Color(0.15, 0.45, 0.25, 1.0), 0.9)
	_pink_band = _mat(Color(0.90, 0.35, 0.65, 1.0), 0.9)
	_white_band = _mat(Color(0.96, 0.94, 0.92, 1.0), 0.9)
	_dark_mat = _mat(Color(0.30, 0.20, 0.10, 1.0), 0.9)
	_heel_mat = _mat(Color(0.35, 0.15, 0.55, 1.0), 0.7)
	_flower_mat = _mat(Color(0.95, 0.55, 0.70, 1.0), 0.7)
	_flower_c = _mat(Color(0.95, 0.80, 0.20, 1.0), 0.7)
	_mouth_mat = _mat(Color(0.45, 0.10, 0.12, 1.0), 0.8)
	_black_hair = _mat(Color(0.12, 0.08, 0.06, 1.0), 0.9)
	_skin_fallback = _mat(Color(0.85, 0.65, 0.50, 1.0), 0.8)


static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = pos
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	m.mesh = cm
	m.position = pos
	m.rotation = rot
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _ball(parent: Node3D, radius: float, mat: Material, pos: Vector3, nm: String, sy: float = 1.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	m.mesh = sm
	m.scale = Vector3(1.0, sy, 1.0)
	m.position = pos
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _move(node: Node, new_parent: Node3D, new_pos: Vector3) -> void:
	var old: Node = node.get_parent()
	if old != null:
		old.remove_child(node)
	new_parent.add_child(node)
	(node as Node3D).position = new_pos


func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= FRAME_GATE:
		_done = true
		_apply(get_parent() as Node3D)
	if not _done:
		return
	# Late-arrival repair (same 1 s cadence as Realism121's own
	# rescan; world children only, never a whole-tree walk): a
	# walker dressed by Realism121 AFTER this slice's main pass
	# (proven possible by the forced-frame sim, where all gates
	# fire in one frame in tree order: 121 < 152 < 163, so S152
	# walkers get their GLB after 163 already ran) must still end
	# up GLB-hidden and detached. This pass also dresses any
	# walking figure that somehow lacks the meta (none exist in
	# this game today; the branch is belt-and-braces, not padding).
	_scan_t += _delta
	if _scan_t >= 1.0:
		_scan_t = 0.0
		_repair(get_parent() as Node3D)


func _repair(world: Node3D) -> void:
	if world == null:
		return
	var r121: Variant = world.get_node_or_null("Realism121")
	var walkers: Array = []
	if r121 != null and "_walkers" in r121:
		walkers = r121._walkers as Array
	for child in world.get_children():
		var nm := String(child.name)
		if not (child is CharacterBody3D and (nm == "Player" or (nm.begins_with("Villager") and not nm.begins_with("VillagerHat")))):
			continue
		var body: Node3D = child as Node3D
		if not body.has_meta("dressed163"):
			_dress_figure(body, walkers)
			continue
		_detach(body, walkers)
		var model: Node = body.get_node_or_null("Model121")
		if model != null and (model as Node3D).visible:
			(model as Node3D).visible = false


func _apply(world: Node3D) -> void:
	if world == null:
		return
	_shared()
	# Detach walkers from Realism121: its _walkers list drives both
	# the per-frame _enforce (re-hides every mesh) and _bob. Erasing
	# our walkers from that list (arrays are references, so this
	# mutates its list) stops both; its 1 s rescan skips figures
	# already carrying the dressed121 meta, so nothing re-adds.
	var r121: Variant = world.get_node_or_null("Realism121")
	var walkers: Array = []
	if r121 != null and "_walkers" in r121:
		walkers = r121._walkers as Array
	var bodies: Array = []
	for child in world.get_children():
		var nm := String(child.name)
		if child is CharacterBody3D and (nm == "Player" or (nm.begins_with("Villager") and not nm.begins_with("VillagerHat"))):
			bodies.append(child)
	for b in bodies:
		var body: Node3D = b as Node3D
		_dress_figure(body, walkers)
	print("REALISM163 dressed: ", dressed_count, " figures, rebuilt fresh: ", rebuilt_count)


func _detach(body: Node3D, walkers: Array) -> void:
	for i in range(walkers.size() - 1, -1, -1):
		var d: Dictionary = walkers[i] as Dictionary
		if d.get("fig") == body:
			walkers.remove_at(i)


func _sex_of(body: Node3D) -> int:
	if String(body.name) == "Player":
		return 0
	var h: float = _hash01(String(body.name))
	return int(h * 3.0) % 3


func _skin_of(body: Node3D) -> Material:
	var head: Node = body.get_node_or_null("Figure163/TorsoPivot163/Head")
	if head == null:
		head = body.get_node_or_null("Head")
	var hm: MeshInstance3D = head as MeshInstance3D
	if hm != null:
		var m: Material = hm.get_surface_override_material(0)
		if m is StandardMaterial3D:
			return m
	return _skin_fallback


func _reshow(body: Node3D, sex: int) -> void:
	# Restore every figure mesh S121 hid, EXCEPT the ones S94/S96/
	# S143 deliberately hid (old arm boxes, old torso boxes —
	# S96's tapered cylinders replace them — old sleeves,
	# villager straw hats, male buns). PlayerHat is NOT re-shown:
	# the outfit toggle owns its visibility; it is only reparented.
	var exclude: Array = ["Arm_R", "Arm_L", "Torso", "Chest94", "Waist94", "Sleeve73_R", "Sleeve73_L", "Hat58", "PlayerHat"]
	if sex == 0:
		exclude.append("HairBun73")
	var stack: Array = []
	for c in body.get_children():
		stack.append(c)
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if String(x.name) == "Model121":
			continue
		if x is MeshInstance3D:
			if String(x.name) in exclude:
				(x as MeshInstance3D).visible = false
			else:
				(x as MeshInstance3D).visible = true
		for c in x.get_children():
			stack.append(c)


func _arm_surgery(torso: Node3D, side: String) -> void:
	var piv: Node3D = torso.get_node_or_null("ShoulderPivot58_" + side) as Node3D
	if piv == null:
		return
	var elb_mesh: Node = piv.get_node_or_null("Elbow94_" + side)
	var elbow_pos := Vector3(0.0, -0.34, 0.0)
	if elb_mesh != null:
		elbow_pos = (elb_mesh as Node3D).position
	var epiv := Node3D.new()
	epiv.name = "ElbowPivot163"
	epiv.position = elbow_pos
	piv.add_child(epiv)
	for nm in ["Forearm94_" + side, "Wrist94_" + side, "Cuff94_" + side, "Hand70_" + side]:
		var part: Node = piv.get_node_or_null(nm)
		if part == null:
			continue
		var old_pos: Vector3 = (part as Node3D).position
		_move(part, epiv, old_pos - elbow_pos)
		if nm.begins_with("Forearm94_") or nm.begins_with("Cuff94_"):
			# The S94 -0.25 bend was baked into the MESH rotation;
			# zero it so the pivot rotation owns the bend alone.
			(part as Node3D).rotation = Vector3.ZERO
	for c in piv.get_children():
		if String(c.name).begins_with("Finger93_"):
			var fg: Node3D = c as Node3D
			var old_pos: Vector3 = fg.position
			_move(c, epiv, old_pos - elbow_pos)


func _leg_surgery(fig: Node3D, side: String) -> void:
	var hip: Node3D = fig.get_node_or_null("HipPivot58_" + side) as Node3D
	if hip == null:
		return
	var leg: Node = hip.get_node_or_null("Leg58_" + side)
	if leg != null:
		(leg as MeshInstance3D).mesh = _thigh_mesh
		(leg as Node3D).position = Vector3(0.0, -0.2125, 0.0)
	var kpiv := Node3D.new()
	kpiv.name = "KneePivot163"
	kpiv.position = Vector3(0.0, -0.425, 0.0)
	hip.add_child(kpiv)
	var skin: Material = _skin_of(fig.get_parent() as Node3D)
	var shin := MeshInstance3D.new()
	shin.name = "Shin163_" + side
	shin.mesh = _shin_mesh
	shin.position = Vector3(0.0, -0.2125, 0.0)
	shin.set_surface_override_material(0, skin)
	kpiv.add_child(shin)
	var apiv := Node3D.new()
	apiv.name = "AnklePivot163"
	apiv.position = Vector3(0.0, -0.425, 0.0)
	kpiv.add_child(apiv)
	for nm in ["Sandal58_" + side, "Heel94_" + side, "Strap95_" + side]:
		var part: Node = hip.get_node_or_null(nm)
		if part == null:
			continue
		var old_pos: Vector3 = (part as Node3D).position
		_move(part, apiv, old_pos - kpiv.position - apiv.position)


func _build_fresh(body: Node3D, fig: Node3D, sex: int, skin: Material) -> void:
	# TYPE B (S152 walkers): no S58/S94 figure exists, so build the
	# articulated figure directly in S94's dimensions and outfits.
	# Stale S73 eyes on the bare body are removed first (fresh S94
	# eyes are built below); stale S95 face/torso details are
	# REUSED (moved under the torso pivot, re-shown) rather than
	# duplicated.
	for nm in ["Eye73_L", "Eye73_R"]:
		var stale: Node = body.get_node_or_null(nm)
		if stale != null:
			body.remove_child(stale)
			stale.queue_free()
	var shirt: Material = _white_top
	var lg_mat: Material = _male_lg
	var band_mat: Material = _green_band
	if sex == 1:
		lg_mat = _fema_lg
		band_mat = _pink_band
	elif sex == 2:
		shirt = _pink_top
		lg_mat = _femb_lg
		band_mat = _white_band
	var torso := Node3D.new()
	torso.name = "TorsoPivot163"
	fig.add_child(torso)
	# S96 superseded S94's torso boxes with tapered cylinders for
	# every figure; fresh builds match S96 (no boxes, no doubling).
	_cyl(torso, 0.26, 0.22, 0.32, shirt, Vector3(0.0, 0.30, 0.0), "Torso96_Chest")
	_cyl(torso, 0.22, 0.19, 0.30, shirt, Vector3(0.0, 0.00, 0.0), "Torso96_Waist")
	_cyl(torso, 0.06, 0.06, 0.12, skin, Vector3(0.0, 0.50, 0.0), "Neck94")
	if sex == 0:
		_cyl(torso, 0.085, 0.095, 0.08, _white_top, Vector3(0.0, 0.52, 0.0), "Collar94")
	elif sex == 1:
		_box(torso, Vector3(0.52, 0.06, 0.32), _white_top, Vector3(0.0, 0.44, 0.0), "Lace94")
	_ball(torso, 0.20, skin, Vector3(0.0, 0.65, 0.0), "Head")
	_ball(torso, 0.030, _dark_mat, Vector3(-0.055, 0.72, 0.10), "Eye73_L")
	_ball(torso, 0.030, _dark_mat, Vector3(0.055, 0.72, 0.10), "Eye73_R")
	_box(torso, Vector3(0.045, 0.08, 0.06), skin, Vector3(0.0, 0.66, 0.14), "Nose94")
	_box(torso, Vector3(0.09, 0.025, 0.03), _mouth_mat, Vector3(0.0, 0.565, 0.11), "Mouth94")
	_ball(torso, 0.035, skin, Vector3(-0.125, 0.65, 0.0), "Ear94_L")
	_ball(torso, 0.035, skin, Vector3(0.125, 0.65, 0.0), "Ear94_R")
	_ball(torso, 0.20, _black_hair, Vector3(0.0, 0.80, -0.04), "Hair58", 0.55)
	if sex == 0:
		_box(torso, Vector3(0.14, 0.07, 0.04), _black_hair, Vector3(0.04, 0.80, 0.10), "SidePart94")
		var bun73: Node = body.get_node_or_null("HairBun73")
		if bun73 != null:
			_move(bun73, torso, (bun73 as Node3D).position)
			(bun73 as Node3D).visible = false
	else:
		# S94 rule exactly: keep a Slice 73 bun if one exists,
		# otherwise build Bun94; flowers always for females.
		var bun73: Node = body.get_node_or_null("HairBun73")
		if bun73 != null:
			_move(bun73, torso, (bun73 as Node3D).position)
			(bun73 as Node3D).visible = true
		else:
			_ball(torso, 0.09, _black_hair, Vector3(0.0, 0.88, -0.14), "Bun94")
		_ball(torso, 0.035, _flower_mat, Vector3(0.095, 0.90, -0.14), "Flower94")
		_ball(torso, 0.015, _flower_c, Vector3(0.125, 0.90, -0.14), "FlowerC94")
	# Reuse the Slice 95 face/torso details already on this body
	# (brows, placket/buttons, scallops, side buttons, waistband).
	for nm in ["Brow95_L", "Brow95_R", "Placket95", "WaistBand95"]:
		var part: Node = body.get_node_or_null(nm)
		if part != null:
			_move(part, torso, (part as Node3D).position)
			(part as Node3D).visible = true
	for bi in range(3):
		for nm in ["Button95_%d" % bi, "SideBtn95_%d" % bi]:
			var part: Node = body.get_node_or_null(nm)
			if part != null:
				_move(part, torso, (part as Node3D).position)
				(part as Node3D).visible = true
	for si in range(5):
		var part: Node = body.get_node_or_null("Scallop95_%d" % si)
		if part != null:
			_move(part, torso, (part as Node3D).position)
			(part as Node3D).visible = true
	for side in ["R", "L"]:
		var sx: float = 0.27 if side == "R" else -0.27
		var piv := Node3D.new()
		piv.name = "ShoulderPivot58_" + side
		piv.position = Vector3(sx, 0.42, 0.0)
		torso.add_child(piv)
		var shoulder_m: Material = shirt
		if sex == 1:
			shoulder_m = skin
		_ball(piv, 0.095, shoulder_m, Vector3(0.0, 0.0, 0.0), "Shoulder94_" + side)
		_cyl(piv, 0.082, 0.062, 0.34, skin, Vector3(0.0, -0.17, 0.0), "Upper94_" + side)
		if sex == 1:
			_cyl(piv, 0.10, 0.095, 0.14, _white_top, Vector3(0.0, -0.07, 0.0), "Sleeve94_" + side)
		else:
			_cyl(piv, 0.105, 0.088, 0.34, shirt, Vector3(0.0, -0.17, 0.0), "Sleeve94_" + side)
		_ball(piv, 0.064, skin, Vector3(0.0, -0.34, 0.0), "Elbow94_" + side)
		var epiv := Node3D.new()
		epiv.name = "ElbowPivot163"
		epiv.position = Vector3(0.0, -0.34, 0.0)
		piv.add_child(epiv)
		_cyl(epiv, 0.062, 0.048, 0.38, skin, Vector3(0.0, -0.184, 0.047), "Forearm94_" + side)
		_ball(epiv, 0.050, skin, Vector3(0.0, -0.368, 0.094), "Wrist94_" + side)
		if sex == 0:
			_cyl(epiv, 0.058, 0.058, 0.08, _white_top, Vector3(0.0, -0.32, 0.085), "Cuff94_" + side)
		_box(epiv, Vector3(0.10, 0.10, 0.03), skin, Vector3(0.0, -0.37, 0.09), "Palm163_" + side)
		for fi in range(3):
			var fx: float = -0.03 + float(fi) * 0.03
			var fg := _box(epiv, Vector3(0.030, 0.12, 0.030), skin, Vector3(fx, -0.43, 0.11), "Finger93_%s_%d" % [side, fi])
			fg.rotation = Vector3(0.25, 0.0, 0.0)
		var th := _box(epiv, Vector3(0.030, 0.10, 0.030), skin, Vector3(0.06, -0.38, 0.11), "Finger93_%s_4" % side)
		th.rotation = Vector3(0.40, 0.0, 0.0)
	for side in ["R", "L"]:
		var sx: float = 0.13 if side == "R" else -0.13
		var hip := Node3D.new()
		hip.name = "HipPivot58_" + side
		hip.position = Vector3(sx, -0.10, 0.0)
		fig.add_child(hip)
		var thigh := MeshInstance3D.new()
		thigh.name = "Leg58_" + side
		thigh.mesh = _thigh_mesh
		thigh.position = Vector3(0.0, -0.2125, 0.0)
		thigh.set_surface_override_material(0, skin)
		hip.add_child(thigh)
		var kpiv := Node3D.new()
		kpiv.name = "KneePivot163"
		kpiv.position = Vector3(0.0, -0.425, 0.0)
		hip.add_child(kpiv)
		var shin := MeshInstance3D.new()
		shin.name = "Shin163_" + side
		shin.mesh = _shin_mesh
		shin.position = Vector3(0.0, -0.2125, 0.0)
		shin.set_surface_override_material(0, skin)
		kpiv.add_child(shin)
		var apiv := Node3D.new()
		apiv.name = "AnklePivot163"
		apiv.position = Vector3(0.0, -0.425, 0.0)
		kpiv.add_child(apiv)
		_box(apiv, Vector3(0.16, 0.06, 0.34), _dark_mat, Vector3(0.0, -0.05, 0.06), "Sandal58_" + side)
		if sex == 1:
			_box(apiv, Vector3(0.09, 0.05, 0.07), _heel_mat, Vector3(0.0, -0.03, -0.14), "Heel94_" + side)
	_box(fig, Vector3(0.54, 0.09, 0.34), _dark_mat, Vector3(0.0, -0.12, 0.0), "Belt58")
	var lpiv := Node3D.new()
	lpiv.name = "LongyiPivot58"
	lpiv.position = Vector3(0.0, -0.10, 0.0)
	fig.add_child(lpiv)
	var lg := _cyl(lpiv, 0.24, 0.32, 0.9, lg_mat, Vector3(0.0, -0.45, 0.0), "Longyi")
	lg.scale.y = LONGYI_SCALE_Y
	# Hem ring seated on the RAISED hem (pivot-local -0.80), as in
	# the Type A re-seat — never below the tube.
	_cyl(lpiv, 0.325, 0.332, 0.06, lg_mat, Vector3(0.0, -0.80, 0.0), "Hem95")
	for ri in range(8):
		var a: float = float(ri) * PI / 4.0
		_cyl(lpiv, 0.02, 0.02, 0.50, lg_mat, Vector3(0.295 * sin(a), -0.55, 0.295 * cos(a)), "Fold94_%d" % ri)
	var band_r: Array = [[0.270, 0.277, -0.30], [0.292, 0.299, -0.55], [0.310, 0.317, -0.75]]
	for bi in range(3):
		var br: Array = band_r[bi]
		_cyl(lpiv, float(br[0]), float(br[1]), 0.06, band_mat, Vector3(0.0, float(br[2]), 0.0), "Band94_%d" % bi)
	if sex == 0:
		_ball(lpiv, 0.07, lg_mat, Vector3(0.0, -0.02, 0.26), "Knot94")


func _dress_figure(body: Node3D, walkers: Array) -> void:
	if body.has_meta("dressed163"):
		return
	var is_player := String(body.name) == "Player"
	var sex := _sex_of(body)
	_detach(body, walkers)
	var model: Node = body.get_node_or_null("Model121")
	if model != null:
		(model as Node3D).visible = false
	var walk: Node = body.get_node_or_null("WalkAnim58")
	if walk != null:
		body.remove_child(walk)
		walk.queue_free()
	var fig := Node3D.new()
	fig.name = "Figure163"
	fig.position = Vector3(0.0, 0.0 if is_player else LIFT_VILLAGER, 0.0)
	body.add_child(fig)
	var has_pivots := body.get_node_or_null("ShoulderPivot58_R") != null
	if has_pivots:
		# TYPE A: reparent the S94 figure under the new root/pivot.
		# Local coords are kept EXACTLY: the lift comes from the
		# Figure163 root position alone (0.43 villagers, 0 player).
		var torso := Node3D.new()
		torso.name = "TorsoPivot163"
		fig.add_child(torso)
		for nm in ["Chest94", "Waist94", "Neck94", "Collar94", "Lace94", "Head", "Eye73_L", "Eye73_R", "Nose94", "Mouth94", "Ear94_L", "Ear94_R", "Hair58", "HairBun73", "Bun94", "Flower94", "FlowerC94", "SidePart94", "PlayerHat", "ShoulderPivot58_R", "ShoulderPivot58_L", "Torso96_Chest", "Torso96_Waist", "Brow95_L", "Brow95_R", "Placket95", "WaistBand95"]:
			var part: Node = body.get_node_or_null(nm)
			if part != null:
				_move(part, torso, (part as Node3D).position)
		for bi in range(3):
			for nm in ["Button95_%d" % bi, "SideBtn95_%d" % bi]:
				var part: Node = body.get_node_or_null(nm)
				if part != null:
					_move(part, torso, (part as Node3D).position)
		for si in range(5):
			var part: Node = body.get_node_or_null("Scallop95_%d" % si)
			if part != null:
				_move(part, torso, (part as Node3D).position)
		for nm in ["HipPivot58_R", "HipPivot58_L", "LongyiPivot58", "Belt58"]:
			var part: Node = body.get_node_or_null(nm)
			if part != null:
				_move(part, fig, (part as Node3D).position)
		_reshow(body, sex)
		_arm_surgery(torso, "R")
		_arm_surgery(torso, "L")
		_leg_surgery(fig, "R")
		_leg_surgery(fig, "L")
		var lg: Node = fig.get_node_or_null("LongyiPivot58/Longyi")
		if lg != null:
			(lg as Node3D).scale.y = LONGYI_SCALE_Y
		# Hem rings were built for the ankle-length tube; the raised
		# hem sits at pivot-local -0.80, so re-seat both rings there
		# instead of leaving them floating below the tube.
		var lpiv_a: Node = fig.get_node_or_null("LongyiPivot58")
		if lpiv_a != null:
			for nm in ["Hem95", "LongyiHem73"]:
				var ring: Node = (lpiv_a as Node3D).get_node_or_null(nm)
				if ring != null:
					(ring as Node3D).position.y = -0.80
	else:
		# TYPE B: bare S152 body — build the figure fresh.
		var skin_cols: Array = [Color(0.92, 0.75, 0.62, 1.0), Color(0.85, 0.65, 0.50, 1.0), Color(0.72, 0.52, 0.36, 1.0), Color(0.55, 0.38, 0.26, 1.0)]
		var h: float = _hash01(String(body.name))
		var skin: Material = _mat(skin_cols[int(h * 4.0) % 4], 0.8)
		_build_fresh(body, fig, sex, skin)
		rebuilt_count += 1
	# Labels: reposition from the LIVE head top (procedural heads
	# are taller than the GLB tops S121 used); never hidden.
	var head: Node = body.get_node_or_null("Figure163/TorsoPivot163/Head")
	if head != null:
		var hm: MeshInstance3D = head as MeshInstance3D
		var ga: AABB = hm.global_transform * hm.get_aabb()
		var head_top: float = ga.position.y + ga.size.y - body.global_position.y
		var dlg: Node = body.get_node_or_null("DialogueLabel")
		if dlg != null:
			(dlg as Node3D).position.y = head_top + 0.45
		var prm: Node = body.get_node_or_null("PromptLabel")
		if prm != null:
			(prm as Node3D).position.y = head_top + 1.05
	var gait := Node.new()
	gait.name = "Gait163"
	gait.set_script(GaitScript)
	body.add_child(gait)
	body.set_meta("dressed163", true)
	dressed_count += 1
