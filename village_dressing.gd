## NOTE: this script deliberately has NO class_name. A new
## class_name needs the project's .godot global-class cache to be
## regenerated before any other script can reference it, and a
## stale cache makes the referencing script fail to parse (proven
## this slice: player.gd failed on "VillageDressing not declared"
## until the reference became a preload). player.gd loads this
## file with preload("res://village_dressing.gd") instead, which
## works in a fresh clone with no cache at all.
## Slice 53 graphics (realistic direction, procedural only, no
## external assets). Runs once at world spawn from player._ready.
## What it does, honestly: it does NOT make the game photoreal.
## It fixes the most visible stylised gaps in the village centre:
## (1) the scene houses are floating slabs (a 2 x 0.8 x 4 box at
## y = 2 with a roof, nothing beneath, collision aside) — dressing
## adds a wall box from the ground up to the slab, plus windows and
## doors, so houses sit on the ground and read as houses; the new
## visuals sit INSIDE the existing Slice 38 collision boxes
## (2.6 x 2.8 x 4.6 at y = 1.4, spanning y 0-2.8), so no new
## collision is needed and the player cannot walk through them.
## (2) tree canopies get deterministic per-tree scale + green tint
## variety instead of one identical sphere each (toddy palms from
## Slice 11 are left alone). (3) the flat-colour ground gets a
## procedural mottled grass texture and dirt paths get a speckle
## texture, both generated in code (no asset files). Window/door
## meshes are shared; wall meshes are per-house size (houses share
## one box size today, but a shared mesh mutated per house would
## resize every earlier wall). The node cost is draw calls only. Everything is visual-only: zero physics bodies added,
## zero gameplay code touched. The owner order (max performance,
## no capping) applies: this pass adds detail, it does not
## simplify anything to save frames.

static var _window_mesh: BoxMesh = null
static var _door_mesh: BoxMesh = null
static var _wall_mat: StandardMaterial3D = null
static var _door_mat: StandardMaterial3D = null


static func _hash01(s: String) -> float:
	return float(abs(s.hash()) % 1000) / 1000.0


static func _noise2(x: float, y: float) -> float:
	var xi: int = int(floor(x))
	var yi: int = int(floor(y))
	var xf: float = x - floor(x)
	var yf: float = y - floor(y)
	var u: float = xf * xf * (3.0 - 2.0 * xf)
	var v: float = yf * yf * (3.0 - 2.0 * yf)
	var h := func(ix: int, iy: int) -> float:
		var n := (ix * 374761393 + iy * 668265263) & 0x7fffffff
		n = (n ^ (n >> 13)) * 1274126177
		return float((n ^ (n >> 16)) & 0xffffff) / float(0xffffff)
	var a: float = float(h.call(xi, yi))
	var b: float = float(h.call(xi + 1, yi))
	var c: float = float(h.call(xi, yi + 1))
	var d: float = float(h.call(xi + 1, yi + 1))
	return (a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v)


static func _make_ground_texture() -> ImageTexture:
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var greens := [Color(0.20, 0.48, 0.20, 1.0), Color(0.28, 0.58, 0.26, 1.0),
		Color(0.16, 0.40, 0.16, 1.0), Color(0.45, 0.42, 0.22, 1.0)]
	for y in size:
		for x in size:
			var n: float = _noise2(x / 32.0, y / 32.0) * 0.65 + _noise2(x / 11.0, y / 11.0) * 0.35
			var idx := 0
			if n > 0.72:
				idx = 3
			elif n > 0.55:
				idx = 1
			elif n > 0.38:
				idx = 0
			else:
				idx = 2
			var col: Color = greens[idx]
			if _noise2(x / 3.0 + 50.0, y / 3.0) > 0.78:
				col = Color(0.42, 0.36, 0.22, 1.0)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func _make_dirt_texture() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var n: float = _noise2(x / 9.0, y / 9.0)
			var col: Color = Color(0.55, 0.44, 0.30, 1.0) if n > 0.45 else Color(0.48, 0.38, 0.26, 1.0)
			if _noise2(x / 2.0 + 30.0, y / 2.0) > 0.80:
				col = Color(0.38, 0.30, 0.20, 1.0)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func _shared_meshes() -> void:
	if _window_mesh == null:
		_window_mesh = BoxMesh.new()
		_window_mesh.size = Vector3(0.5, 0.5, 0.06)
		_door_mesh = BoxMesh.new()
		_door_mesh.size = Vector3(0.7, 1.2, 0.08)
		_wall_mat = StandardMaterial3D.new()
		_wall_mat.albedo_color = Color(0.82, 0.76, 0.62, 1.0)
		_wall_mat.roughness = 0.95
		_door_mat = StandardMaterial3D.new()
		_door_mat.albedo_color = Color(0.42, 0.28, 0.14, 1.0)
		_door_mat.roughness = 0.9


static func _add_box(parent: Node3D, mesh: BoxMesh, mat: Material, pos: Vector3, name: String) -> void:
	var m := MeshInstance3D.new()
	m.name = name
	m.mesh = mesh
	m.position = pos
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)


static func dress(world: Node) -> void:
	if world == null:
		return
	_shared_meshes()
	var win_mat: Material = null
	var dn := world.get_node_or_null("DayNight")
	if dn != null:
		win_mat = dn.get("window_material") as Material
	if win_mat == null:
		win_mat = StandardMaterial3D.new()
		(win_mat as StandardMaterial3D).albedo_color = Color(0.10, 0.12, 0.16, 1.0)
		(win_mat as StandardMaterial3D).roughness = 0.4
	var ground_tex := _make_ground_texture()
	var dirt_tex := _make_dirt_texture()
	var stack: Array = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		var nm := node.name
		if nm == "GroundMesh":
			var gm := mi.get_surface_override_material(0)
			if gm is StandardMaterial3D:
				var dup := (gm as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
				dup.albedo_texture = ground_tex
				dup.roughness = 1.0
				mi.set_surface_override_material(0, dup)
		elif "Path" in nm:
			var pm := mi.get_surface_override_material(0)
			if pm is StandardMaterial3D:
				var dup := (pm as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
				dup.albedo_texture = dirt_tex
				mi.set_surface_override_material(0, dup)
		elif nm.begins_with("TreeTop"):
			var h: float = _hash01(nm)
			mi.scale *= (0.85 + h * 0.45)
			var tm := mi.get_surface_override_material(0)
			if tm is StandardMaterial3D:
				var dup := (tm as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = Color(0.12 + h * 0.16, 0.48 + h * 0.18, 0.12 + h * 0.10, 1.0)
				mi.set_surface_override_material(0, dup)
		elif nm.begins_with("House"):
			var mesh := mi.mesh
			if not (mesh is BoxMesh):
				continue
			var bsize := (mesh as BoxMesh).size
			var hy := mi.position.y
			var bottom := hy - bsize.y * 0.5
			if bottom < 0.3:
				continue
			var wall_h := bottom
			var wall_centre_y := bottom * 0.5 - hy
			var wall_mesh := BoxMesh.new()
			wall_mesh.size = Vector3(bsize.x, wall_h, bsize.z)
			_add_box(mi, wall_mesh, _wall_mat, Vector3(0, wall_centre_y, 0), "DressWall53")
			var fz := bsize.z * 0.5 + 0.03
			for side in [-1.0, 1.0]:
				for wx in [-0.5, 0.5]:
					_add_box(mi, _window_mesh, win_mat,
						Vector3(wx, -hy + 1.0, side * fz), "DressWindow53_%d_%d" % [int(side), int(wx * 2)])
				_add_box(mi, _door_mesh, _door_mat,
					Vector3(0, -hy + 0.6, side * (bsize.z * 0.5 + 0.04)), "DressDoor53_%d" % int(side))
