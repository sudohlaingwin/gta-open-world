extends Node3D

## Slice 116 — SUPERIOR BUILD, harsh senior mode (owner order
## 2026-10-24 11:39 +07). Audit-first: every item below was
## live-probed MISSING before adding (audit117/audit117b/
## audit117c/audit117d/audit117e/audit117f/audit117g outputs,
## after fast-forwarding ALL dress gates including Scale97's).
## ONE genuine gap, about the people the player actually meets
## at bus stops — the owner's chosen BUS + STOPS + PASSENGERS
## system (option 2, 2026-10-23 11:32):
## WAITING + ALIGHTED PASSENGERS WERE CYLINDER + BALL.
## bus_sim74's _passenger() and bus_controller74's alighting
## code both build the same figure: a Body74 cylinder
## (r 0.28, h 1.1, centre 0.55) + a Head74 sphere (r 0.22,
## centre 1.35). No arms, no longyi, no hair, no waist band.
## 18 waiting figures stand at the 6 stops (3 per stop,
## Waiting74_0_0..5_2, proven live) and alighted figures
## (Alighted75_*) are created with the identical structure
## whenever a rider steps off. Against the S94/S113/S114/
## S115 figures — tapered torsos, arms, longyi bands, faces —
## these are the crudest people left in the game, standing
## exactly where the bus-simulation player looks.
## Fixed here, ADDITIVELY (never hide-and-replace): Body74
## and Head74 are NEVER touched — bus_sim91's _set_seated_pose
## moves exactly those two nodes by name, so renaming or
## hiding them would break boarding. Five added parts per
## figure, all children of the figure node so they follow
## boarding/alighting movement, ZERO new colliders:
## (1) Arm117_L/R: boxes 0.08 x 0.55 x 0.08 at (+/-0.33,
## 0.82, 0) — inner face 0.29 clears the 0.28 tube by 0.01,
## so arms read free of the body (the S109 white-blob
## lesson: hands hidden inside a flare read as a blob).
## (2) Longyi117: tapered cylinder, top r 0.30 / bottom r
## 0.35, h 0.75, centre y 0.38 — 0.02 proud at the top,
## 0.07 at the hem, S111 band principle. Colour varies by
## figure from a 5-colour Myanmar dress palette.
## (3) Hair117: sphere r 0.23, y-scale 0.75, at y 1.48 —
## caps the head top (head sphere spans 1.13..1.57; hair
## spans 1.31..1.65) without covering the lower head.
## (4) Band117: cylinder r 0.295, h 0.12, at y 0.95 —
## S111 bold-band principle, 0.015 proud of the tube,
## readable at 6 m where 0.03 stripes vanish.
## SEATED MIRROR + POSE FOLLOW (stated openly, no clipping):
## when a waiting rider boards, bus_sim91 moves ONLY
## Body74/Head74 to seat positions — added parts left at
## standing offsets would float wrong. And waiting riders
## are BENCH-SEATED by default in the live world (bus_sim78
## _seat_rider: body 0.98, head 1.62, not standing 0.55/
## 1.35). So this node's _process, every frame, mirrors
## the sim: boarded (seated91 meta) -> my 5 parts hidden
## (the seated rider then looks EXACTLY as today, no
## regression); otherwise -> parts shown FOLLOWING the live
## Body74/Head74 positions (arms body.y + 0.27, longyi
## body.y - 0.17, band body.y + 0.40, hair head.y + 0.13).
## Alighted figures never seat, so their parts are always
## shown (following, same as standing).
## DYNAMIC RE-SCAN (S112/S115 pattern): round-trip respawn
## and alighting create fresh nodes at runtime, so the scan
## repeats every 1.0 s; dressed117 meta prevents duplicates.
## Runs at frame >= 540, after realism116's 520 pass.
## HONEST COUNT: 18 waiting figures x 5 parts = 90 parts at
## load, + 5 per alighted figure as they appear — UNDER the
## ~50-item target in slice terms (18 figures is ONE item
## class, counted honestly as 18 figures, not 90 items).
## No other core gap survived auditing: all rideables
## (S95/S109/S110/S111/S113/S114), all 9 traffic vehicles
## reshaped + driven (S115), House97_1-4 replacements
## (45 visible meshes each, at the old House1-4 spots),
## HamletHouse75_0..3, School, Stilt97_*, all 18 villagers
## (S111's 19-figure band pass), depot, and bus seated
## display itself (dynamic, via bus_sim91 — static absence
## in a fresh-world probe is by design, not a gap).
## NOT TOUCHED, WITH REASONS: bus system files, minibus,
## big bus (Slice 81 limit stands); Body74/Head74 nodes
## (bus_sim91 moves them by name); S95 car driver figure
## (S114's measured 0.45 m headroom exclusion stands);
## animated figures (static poses, stated openly — sway
## would reintroduce the doll-wobble the owner condemned);
## night-fill residuals (S103's disclosed 1.3-1.4 m slivers
## and the in-hill 4.71 m tail are not real gaps — filling
## them with full 22 m pools would be padding); the
## tuk-wheel scene file's 3 bare Transform3D lines (owner/
## parent decision pending — scene file untouched, the S112
## _ready restore stands).

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0
# Slice 120: cached figure list. _mirror_follow used to walk the
# WHOLE world tree every frame (13,799 nodes at S120 measure) just
# to find ~18-30 figures — the worst unconditional per-frame scan
# in the project. Figures are now cached when dressed (fresh
# dresses only, by the dressed117-meta guard, so no duplicates)
# and the mirror iterates the cache; _scan_and_dress still runs
# every 1.0 s for fresh figures, so discovery timing is unchanged.
# Static because _dress_figure is static; stale entries (scene
# reload frees the old figures) are pruned by validity check.
static var _figs: Array = []
static var _longyi_mats: Array = []

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism117") != null:
		return
	var n := Node3D.new()
	n.name = "Realism117"
	n.set_script(load("res://realism117.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 540:
		_done = true
		_apply(get_parent() as Node3D)
	# SEATED MIRROR + POSE FOLLOW, EVERY FRAME (not only on the
	# 1.0 s scan): waiting riders are BENCH-SEATED by default
	# in the live world (bus_sim78 _seat_rider: body 0.98, head
	# 1.62, not the standing 0.55/1.35), and bus_sim91 moves
	# Body74/Head74 again when a rider boards. Static standing
	# offsets would float wrong against both poses, so the
	# added parts FOLLOW the live Body74/Head74 positions:
	# arms body.y + 0.27, longyi body.y - 0.17, band body.y +
	# 0.40, hair head.y + 0.13. When a waiting rider boards
	# (seated91 meta), the parts hide instead, so the seated
	# rider looks exactly as before — no new clipping.
	_mirror_follow()
	_scan_t += _delta
	if _scan_t >= 1.0:
		_scan_t = 0.0
		var w := get_parent() as Node3D
		if w != null:
			_scan_and_dress(w)

static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

static func _palette() -> void:
	if not _longyi_mats.is_empty():
		return
	_longyi_mats = [
		_mat(Color(0.45, 0.25, 0.60, 1.0), 0.9),
		_mat(Color(0.85, 0.45, 0.60, 1.0), 0.9),
		_mat(Color(0.25, 0.50, 0.35, 1.0), 0.9),
		_mat(Color(0.25, 0.40, 0.65, 1.0), 0.9),
		_mat(Color(0.55, 0.20, 0.25, 1.0), 0.9),
	]

static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node3D, r: float, mat: Material, pos: Vector3, nm: String, yscale: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.scale = Vector3(1.0, yscale, 1.0)
	parent.add_child(mi)
	return mi

# Dress ONE figure node (Waiting74_* or Alighted75_*). Body74/Head74
# are read-only here: body material is borrowed for the arms, and
# their positions/visibility are never changed.
static func _dress_figure(fig: Node3D) -> void:
	if fig == null or fig.has_meta("dressed117"):
		return
	_palette()
	var body := fig.get_node_or_null("Body74") as MeshInstance3D
	var arm_mat: Material = null
	if body != null:
		arm_mat = body.get_surface_override_material(0)
		if arm_mat == null:
			arm_mat = body.material_override
	if arm_mat == null:
		arm_mat = _mat(Color(0.80, 0.70, 0.55, 1.0), 0.9)
	var idx := int(abs(fig.name.hash()) % 5)
	var longyi_mat: Material = _longyi_mats[idx]
	var dark_mat := _mat(Color(0.15, 0.10, 0.08, 1.0), 0.8)
	var hair_mat := _mat(Color(0.12, 0.08, 0.06, 1.0), 0.9)
	_box(fig, Vector3(0.08, 0.55, 0.08), arm_mat, Vector3(-0.33, 0.82, 0.0), "Arm117_L")
	_box(fig, Vector3(0.08, 0.55, 0.08), arm_mat, Vector3(0.33, 0.82, 0.0), "Arm117_R")
	_cyl(fig, 0.30, 0.35, 0.75, longyi_mat, Vector3(0.0, 0.38, 0.0), "Longyi117")
	_sphere(fig, 0.23, hair_mat, Vector3(0.0, 1.48, 0.0), "Hair117", 0.75)
	_cyl(fig, 0.295, 0.295, 0.12, dark_mat, Vector3(0.0, 0.95, 0.0), "Band117")
	fig.set_meta("dressed117", true)
	fig.set_meta("seated117_shown", true)
	_figs.append(fig)

static func _scan_and_dress(world: Node) -> void:
	var stack: Array = [world]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var nm := String(n.name)
		if (nm.begins_with("Waiting74_") or nm.begins_with("Alighted75_")) and n is Node3D and not n.has_meta("dressed117"):
			_dress_figure(n as Node3D)

# Seated mirror + pose follow, every frame — over the CACHED
# figure list (Slice 120), NOT a tree walk. Waiting riders that
# boarded (seated91 meta) hide the added parts; everyone else
# shows them FOLLOWING the live Body74/Head74 positions, so
# bench-seated (body 0.98 / head 1.62), standing (0.55/1.35)
# and any other sim pose all read correctly. Visibility flips
# only on state change (meta seated117_shown); positions are
# set every frame (18-30 figures x 5 sets is negligible).
# Behaviour is identical to the old tree-walk version: every
# cached figure was dressed by _scan_and_dress (same 1.0 s
# discovery), and the seated/position logic below is untouched.
func _mirror_follow() -> void:
	var dead: Array = []
	for f in _figs:
		if f == null or not is_instance_valid(f):
			dead.append(f)
			continue
		var fig := f as Node3D
		var nm := String(fig.name)
		var body := fig.get_node_or_null("Body74") as MeshInstance3D
		var head := fig.get_node_or_null("Head74") as MeshInstance3D
		if body == null or head == null:
			continue
		if nm.begins_with("Waiting74_") and bool(fig.get_meta("seated91", false)):
			if bool(fig.get_meta("seated117_shown", true)):
				for part in ["Arm117_L", "Arm117_R", "Longyi117", "Hair117", "Band117"]:
					var mi := fig.get_node_or_null(part) as MeshInstance3D
					if mi != null:
						mi.visible = false
				fig.set_meta("seated117_shown", false)
			continue
		if not bool(fig.get_meta("seated117_shown", true)):
			for part in ["Arm117_L", "Arm117_R", "Longyi117", "Hair117", "Band117"]:
				var mi := fig.get_node_or_null(part) as MeshInstance3D
				if mi != null:
					mi.visible = true
			fig.set_meta("seated117_shown", true)
		var by := body.position.y
		var hy := head.position.y
		var arm_l := fig.get_node_or_null("Arm117_L") as MeshInstance3D
		var arm_r := fig.get_node_or_null("Arm117_R") as MeshInstance3D
		var longyi := fig.get_node_or_null("Longyi117") as MeshInstance3D
		var hair := fig.get_node_or_null("Hair117") as MeshInstance3D
		var band := fig.get_node_or_null("Band117") as MeshInstance3D
		if arm_l != null:
			arm_l.position = Vector3(-0.33, by + 0.27, 0.0)
		if arm_r != null:
			arm_r.position = Vector3(0.33, by + 0.27, 0.0)
		if longyi != null:
			longyi.position = Vector3(0.0, by - 0.17, 0.0)
		if band != null:
			band.position = Vector3(0.0, by + 0.40, 0.0)
		if hair != null:
			hair.position = Vector3(0.0, hy + 0.13, 0.0)
	for d in dead:
		_figs.erase(d)

static func _apply(world: Node3D) -> void:
	if world == null:
		return
	_scan_and_dress(world)
