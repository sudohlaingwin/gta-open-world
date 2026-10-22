## Slice 58: 3D character + nature + building + ground set (owner ask
## 2026-10-22 20:44: can Muse render the needed characters in 3D and
## use them in the game — people, trees, buildings, map, ground).
## ORIGINAL procedural/code-generated models only, no external assets,
## nothing copied. Runtime-only: no scene file is touched, no new
## physics bodies, no gameplay code changed. Runs once at world spawn
## from player._ready, after Slice 53/56/57 dressing. Loaded by
## preload, NOT class_name (a new class_name needs a regenerated
## .godot cache and a stale cache breaks player.gd's parse — proven
## Slice 53). Honest limits, stated in the report: villager legs sit
## under the longyi (as a real longyi covers them) — the visible
## walking read is arm swing + longyi sway + sandals at the hem;
## trees/buildings/ground are dressing, not new gameplay.

const WalkAnimScript = preload("res://walk_anim58.gd")

static var _skin_mat: StandardMaterial3D = null
static var _hair_mat: StandardMaterial3D = null
static var _straw_mat: StandardMaterial3D = null
static var _dark_mat: StandardMaterial3D = null
static var _wood_mat: StandardMaterial3D = null
static var _eaves_mat: StandardMaterial3D = null
static var _dirt_mat: StandardMaterial3D = null
static var _blossom_mat: StandardMaterial3D = null
static var _blossom2_mat: StandardMaterial3D = null
static var _fruit_mat: StandardMaterial3D = null
static var _leaf2_mat: StandardMaterial3D = null


## Raw String.hash() clusters badly on sequential names (proven this
## slice: Villager1..18 hashed to 0.676-0.684 and 0.916-0.924, so a
## hash<0.34 split gave zero straw hats). Mix with xorshift-multiply
## before taking mod 1000, as village_dressing's noise hash does.
static func _hash01(s: String) -> float:
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
	if _skin_mat != null:
		return
	_skin_mat = _mat(Color(0.85, 0.65, 0.50, 1.0), 0.8)
	_hair_mat = _mat(Color(0.12, 0.08, 0.06, 1.0), 0.9)
	_straw_mat = _mat(Color(0.85, 0.72, 0.42, 1.0), 0.9)
	_dark_mat = _mat(Color(0.30, 0.20, 0.10, 1.0), 0.9)
	_wood_mat = _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	_eaves_mat = _mat(Color(0.55, 0.32, 0.20, 1.0), 0.9)
	_dirt_mat = _mat(Color(0.55, 0.42, 0.28, 1.0), 1.0)
	_blossom_mat = _mat(Color(0.95, 0.65, 0.75, 1.0), 0.8)
	_blossom2_mat = _mat(Color(0.98, 0.95, 0.90, 1.0), 0.8)
	_fruit_mat = _mat(Color(0.95, 0.55, 0.15, 1.0), 0.7)
	_leaf2_mat = _mat(Color(0.15, 0.45, 0.15, 1.0), 0.9)


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


## Dresses one character body (Player or a villager). Arm meshes are
## reparented under shoulder pivots so the walk animator can swing
## them; the longyi is reparented under a hip pivot so the hem sways;
## legs + sandals hang from hip pivots. Geometry (measured from
## main.tscn): head centre y 0.65 (r 0.2), torso box 0.5x0.6x0.3 at
## y 0.15, longyi cylinder h 0.9 at y -0.55 (spans -1.0..-0.1), arms
## box 0.15x0.55x0.15 at (+-0.35, 0.15). Pivots preserve every world
## position exactly (arm offset -0.27 from a 0.42 shoulder).
static func _dress_body(body: Node3D, is_player: bool) -> void:
	if body.get_node_or_null("ShoulderPivot58_R") != null:
		return
	var h: float = _hash01(body.name)
	for side in ["R", "L"]:
		var sx := 0.35 if side == "R" else -0.35
		var arm := body.get_node_or_null("Arm_" + side) as MeshInstance3D
		if arm != null:
			var piv := Node3D.new()
			piv.name = "ShoulderPivot58_" + side
			piv.position = Vector3(sx, 0.42, 0.0)
			body.add_child(piv)
			body.remove_child(arm)
			piv.add_child(arm)
			arm.position = Vector3(0.0, -0.27, 0.0)
			arm.rotation = Vector3.ZERO
	var lg := body.get_node_or_null("Longyi") as MeshInstance3D
	if lg != null:
		var lpiv := Node3D.new()
		lpiv.name = "LongyiPivot58"
		lpiv.position = Vector3(0.0, -0.10, 0.0)
		body.add_child(lpiv)
		body.remove_child(lg)
		lpiv.add_child(lg)
		lg.position = Vector3(0.0, -0.45, 0.0)
		lg.rotation = Vector3.ZERO
	for side in ["R", "L"]:
		var sx := 0.13 if side == "R" else -0.13
		var hpiv := Node3D.new()
		hpiv.name = "HipPivot58_" + side
		hpiv.position = Vector3(sx, -0.10, 0.0)
		body.add_child(hpiv)
		_box(hpiv, Vector3(0.13, 0.85, 0.13), _skin_mat, Vector3(0.0, -0.425, 0.0), "Leg58_" + side)
		_box(hpiv, Vector3(0.16, 0.06, 0.34), _dark_mat, Vector3(0.0, -0.90, 0.06), "Sandal58_" + side)
	_box(body, Vector3(0.54, 0.09, 0.34), _dark_mat, Vector3(0.0, -0.12, 0.0), "Belt58")
	_ball(body, 0.20, _hair_mat, Vector3(0.0, 0.80, -0.04), "Hair58", 0.55)
	if not is_player and int(h * 3.0) == 0:
		var hat := MeshInstance3D.new()
		hat.name = "Hat58"
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.46
		cm.height = 0.20
		hat.mesh = cm
		hat.position = Vector3(0.0, 0.95, 0.0)
		hat.set_surface_override_material(0, _straw_mat)
		body.add_child(hat)
	if not is_player:
		var torso := body.get_node_or_null("Torso") as MeshInstance3D
		if torso != null:
			var old := torso.get_surface_override_material(0)
			if old is StandardMaterial3D:
				var dup := (old as StandardMaterial3D).duplicate() as StandardMaterial3D
				var palette: Array = [
					Color(0.96, 0.94, 0.90, 1.0), Color(0.65, 0.78, 0.90, 1.0),
					Color(0.93, 0.70, 0.75, 1.0), Color(0.70, 0.85, 0.70, 1.0),
					Color(0.80, 0.75, 0.90, 1.0),
				]
				dup.albedo_color = palette[int(h * 5.0) % 5]
				torso.set_surface_override_material(0, dup)
	var anim := Node.new()
	anim.name = "WalkAnim58"
	anim.set_script(WalkAnimScript)
	body.add_child(anim)


static func dress(world: Node) -> void:
	if world == null:
		return
	if world.get_node_or_null("Dress58Applied") != null:
		return
	if world.get_node_or_null("Dress58Ground") != null:
		return
	_shared()
	# Phase 1 — collect (never mutate while iterating the tree).
	var bodies: Array = []
	var treetops: Array = []
	var palms18: Array = []
	var palms20: Array = []
	var houses: Array = []
	var fields: Array = []
	var stack: Array = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		if node == world:
			if node is Node3D:
				for child in (node as Node3D).get_children():
					if child is CharacterBody3D and (child.name == "Player" or String(child.name).begins_with("Villager")):
						bodies.append(child)
			continue
		if not (node is MeshInstance3D):
			if node is Node3D and (node.name == "Palm18A" or node.name == "Palm18B"):
				palms18.append(node)
			continue
		var nm := String(node.name)
		if nm.begins_with("TreeTop"):
			treetops.append(node)
		elif nm.begins_with("Palm20"):
			palms20.append(node)
		elif nm.begins_with("House") and (node as MeshInstance3D).mesh is BoxMesh:
			houses.append(node)
		elif nm in ["FieldEast", "FieldNorth", "FieldSouth", "FieldWest"] and (node as MeshInstance3D).mesh is PlaneMesh:
			fields.append(node)
	# Phase 2 — characters.
	for b in bodies:
		_dress_body(b as Node3D, String((b as Node).name) == "Player")
	# Phase 2 — trees: species split by deterministic hash.
	for t in treetops:
		var top := t as MeshInstance3D
		var h: float = _hash01(top.name)
		if h < 0.34:
			var offs: Array = [Vector3(0.9, 0.6, 0.3), Vector3(-0.8, 0.8, -0.4), Vector3(0.2, 1.0, 0.9), Vector3(-0.4, -0.2, -0.9)]
			for i in offs.size():
				_ball(top, 0.20, _blossom_mat if i % 2 == 0 else _blossom2_mat, offs[i], "Blossom58_%d" % i)
		elif h < 0.67:
			var foffs: Array = [Vector3(0.7, -0.9, 0.5), Vector3(-0.6, -1.0, -0.3), Vector3(0.1, -0.7, 0.9)]
			for i in foffs.size():
				_ball(top, 0.17, _fruit_mat, foffs[i], "Fruit58_%d" % i)
		else:
			_ball(top, 0.55, _leaf2_mat, Vector3(0.0, 1.1, 0.0), "Tuft58")
	for p in palms18:
		var grp := p as Node3D
		var coffs: Array = [Vector3(0.2, 5.6, 0.1), Vector3(-0.2, 5.5, -0.1), Vector3(0.0, 5.8, 0.0)]
		for i in coffs.size():
			_ball(grp, 0.16, _dark_mat, coffs[i], "Coconut58_%d" % i)
	for p in palms20:
		var pm := p as MeshInstance3D
		var coffs2: Array = [Vector3(0.2, 4.8, 0.1), Vector3(-0.2, 4.7, -0.1), Vector3(0.0, 5.0, 0.0)]
		for i in coffs2.size():
			_ball(pm, 0.16, _dark_mat, coffs2[i], "Coconut58_%d" % i)
	# Phase 2 — buildings: eaves over each slab roofline, shutters
	# beside each Slice 53 window (windows are 0.5 wide, so shutters
	# sit 0.35 to each side, angled open 0.5 rad).
	for hs in houses:
		var mi := hs as MeshInstance3D
		var bsize := (mi.mesh as BoxMesh).size
		var hy := mi.position.y
		var bottom := hy - bsize.y * 0.5
		if bottom < 0.3:
			continue
		_box(mi, Vector3(bsize.x + 0.35, 0.12, bsize.z + 0.35), _eaves_mat, Vector3(0.0, bsize.y * 0.5 + 0.06, 0.0), "Eaves58")
		var wins: Array = []
		for child in mi.get_children():
			if String(child.name).begins_with("DressWindow53"):
				wins.append(child)
		for w in wins:
			var wp := (w as Node3D).position
			for sgn in [-1.0, 1.0]:
				# Name must include the z side: the two windows
				# sharing an x on opposite faces would otherwise
				# collide, and Godot renames the loser to
				# "@MeshInstance3D@N" (proven this slice).
				var sh := _box(mi, Vector3(0.22, 0.55, 0.04), _wood_mat, Vector3(wp.x + sgn * 0.35, wp.y, wp.z), "Shutter58_%d_%d_%d" % [int(wp.x * 2), int(sgn), int(wp.z)])
				sh.rotation.y = -sgn * 0.5
	# Phase 2 — ground group (world-root add must be deferred: a
	# direct add_child to the world root from player._ready fails
	# with "Parent node is busy setting up children", proven S56).
	var ground := Node3D.new()
	ground.name = "Dress58Ground"
	# Dirt paths from the village centre to the four landmarks
	# (coords are the scene's own: pagoda, market, zayat, well).
	var routes: Array = [Vector2(-20.0, -25.0), Vector2(16.0, 12.0), Vector2(28.0, 2.0), Vector2(6.0, 12.0)]
	for i in routes.size():
		var tgt := routes[i] as Vector2
		var ln := tgt.length()
		var mid := Vector3(tgt.x * 0.5, 0.02, tgt.y * 0.5)
		var p := _box(ground, Vector3(1.3, 0.04, ln), _dirt_mat, mid, "Path58_%d" % i)
		p.rotation.y = atan2(tgt.x, tgt.y)
	for t in treetops:
		var top := t as MeshInstance3D
		_box(ground, Vector3(2.4, 0.03, 2.4), _dirt_mat, Vector3(top.position.x, 0.02, top.position.z), "Patch58_%s" % String(top.name).replace("TreeTop", ""))
	# Field rows in world space, derived from each field plane's own
	# basis (PlaneMesh_pond is 8x6; basis lengths give world extents).
	for f in fields:
		var fm := f as MeshInstance3D
		var basis := fm.transform.basis
		var ext_x := basis.x.length() * 8.0
		var ext_z := basis.z.length() * 6.0
		var long_axis_x := ext_x >= ext_z
		var long_len := ext_x if long_axis_x else ext_z
		var short_len := ext_z if long_axis_x else ext_x
		if long_len < 10.0 or short_len < 2.0:
			continue
		var yaw := atan2(-basis.x.z, basis.x.x)
		var bz := Vector3(basis.z.x, 0.0, basis.z.z).normalized()
		for ri in 5:
			var off := (float(ri) - 2.0) * short_len * 0.16
			var centre := Vector3(fm.position.x, fm.position.y + 0.04, fm.position.z) + bz * off
			var row: MeshInstance3D
			if long_axis_x:
				row = _box(ground, Vector3(long_len - 10.0, 0.03, 1.2), _dirt_mat, centre, "Row58_%s_%d" % [String(fm.name), ri])
			else:
				row = _box(ground, Vector3(1.2, 0.03, long_len - 10.0), _dirt_mat, centre, "Row58_%s_%d" % [String(fm.name), ri])
			row.rotation.y = yaw
	var marker := Node3D.new()
	marker.name = "Dress58Applied"
	world.call_deferred("add_child", ground)
	world.call_deferred("add_child", marker)
