extends Node3D
## Slice 70 — graphics realism pass, part 1 (owner order 2026-10-23
## 06:32, binding: STOP adding features, make people and houses
## look like the real thing, not wobbly dolls). Runtime-only: no
## scene file is touched, no positions moved, no colliders added,
## no gameplay code changed, no new feature/quest/sign/label.
## What it does, all procedural (no external assets, no copied
## opponent shaders, no scanned textures claimed):
## - HOUSES: flat slab roofs on the village houses (Roof1-5,7,8)
##   get a real pitched cap (two slanted slabs + ridge beam,
##   overhanging eaves) computed from each roof's own size, so the
##   silhouette stops being a box. East Fields stilt houses get
##   veranda rails + cross-bracing between the front posts.
## - TEXTURES (grayscale brightness patterns, so each material's
##   own colour survives): wood planks on wood walls/decks,
##   brick courses on masonry house walls, corrugation on tin
##   roofs, a framed window (border + cross mullion) on the
##   shared window material, panelled doors on door materials,
##   asphalt speckle on the East Fields main road, dirt speckle
##   on dirt patches/rows/lanes. Textures are set IN PLACE on the
##   live material objects (never duplicated, never reassigned),
##   so Slice 62 season tints (which re-read the live ground
##   material) and Slice 66 wet-road gloss (same live road
##   material) keep working. Nothing already textured is
##   overwritten (albedo_texture set only when currently null).
## - GROUND: the village ground ALREADY has a mottled texture
##   (Slice 53), but it is stretched over the whole 520 m plane,
##   so it reads as blur. This pass only tiles it 8x8 via
##   uv1_scale, so the existing grass detail becomes visible
##   instead of inventing a second texture.
## - PEOPLE: head reshaped from a ball to an oval (scale
##   0.85/1.12/0.92, moved up onto a new neck cylinder), hair and
##   straw hats shifted up to sit on the new head top, hands
##   added under the shoulder pivots (so arms end in hands, not
##   flat box ends). Collision is untouched: the capsule shape
##   on each body is a separate node and is never resized.
## - LIGHTING: sun shadow bias tuned (bias 0.01, normal bias
##   0.06) to cut shadow acne on flat walls/ground; sun energy,
##   colours, the Slice 61 night floor (0.35) and season tints
##   are NOT touched. True ambient occlusion / global
##   illumination does not exist in this gl_compatibility project
##   and is not faked here.
## - SWAY: the doll wobble itself is fixed in walk_anim58.gd
##   (idle 0.06 -> 0.025 rad, walk 0.45 -> 0.32 rad, legs
##   0.7 -> 0.55, longyi 0.12 -> 0.06); this script only reshapes
##   the bodies.
## Capture runs once at frame >= 12, after every deferred
## dressing (Slice 62 district, 64, 66 capture at 8, 69, Slice 61
## style) has landed, then processing stops: zero per-frame cost.

var _frames: int = 0
var _done: bool = false


static func _h(x: int, y: int, seed: int) -> float:
	var v := sin(float(x) * 127.1 + float(y) * 311.7 + float(seed) * 74.7) * 43758.5453
	return v - floor(v)


static func _make_tex(kind: String) -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var b: float = 1.0
			if kind == "plank":
				# Horizontal wood planks: dark line every 16 px,
				# grain jitter per pixel, slight per-column shift.
				if y % 16 < 2:
					b = 0.62
				else:
					b = 0.93 + _h(x, y, 70) * 0.07
					b *= 0.97 + _h(x, 0, 71) * 0.03
			elif kind == "brick":
				# Brick courses: mortar line every 16 px, joints
				# offset on alternate courses.
				if y % 16 < 2:
					b = 0.60
				else:
					var joint := 0
					if (y / 16) % 2 == 1:
						joint = 32
					if (x + joint) % 64 < 2:
						b = 0.60
					else:
						b = 0.92 + _h(x, y, 72) * 0.08
			elif kind == "corrugated":
				# Tin roof ridges: vertical light/dark stripes.
				if x % 8 < 4:
					b = 0.82
				else:
					b = 1.0
				b *= 0.97 + _h(x, y, 73) * 0.03
			elif kind == "window":
				# Frame border + cross mullion + 4 glass panes.
				if x < 8 or x >= 56 or y < 8 or y >= 56:
					b = 0.45
				elif (x >= 30 and x < 34) or (y >= 30 and y < 34):
					b = 0.50
				else:
					b = 0.95 + _h(x, y, 74) * 0.05
			elif kind == "door":
				# Frame border + centre stile + two recessed panels.
				if x < 6 or x >= 58 or y < 6 or y >= 58:
					b = 0.50
				elif x >= 30 and x < 34:
					b = 0.60
				elif x >= 12 and x < 28 and ((y >= 12 and y < 30) or (y >= 34 and y < 52)):
					b = 0.85
				else:
					b = 0.98
			elif kind == "asphalt":
				# Worn asphalt: speckle + rare dark pits.
				b = 0.84 + _h(x, y, 75) * 0.16
				if _h(x, y, 76) > 0.97:
					b = 0.70
			else:  # dirt
				b = 0.86 + _h(x, y, 77) * 0.14
				if _h(x, y, 78) > 0.96:
					b = 0.72
			img.set_pixel(x, y, Color(b, b, b, 1.0))
	return ImageTexture.create_from_image(img)


static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = pos
	m.rotation = rot
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


func _apply_tex(mats: Array, tex: Texture2D) -> void:
	for m in mats:
		if m is StandardMaterial3D:
			var sm := m as StandardMaterial3D
			if sm.albedo_texture == null:
				sm.albedo_texture = tex


func _capture(world: Node3D) -> void:
	_done = true
	var plank_tex := _make_tex("plank")
	var brick_tex := _make_tex("brick")
	var corr_tex := _make_tex("corrugated")
	var win_tex := _make_tex("window")
	var door_tex := _make_tex("door")
	var asphalt_tex := _make_tex("asphalt")
	var dirt_tex := _make_tex("dirt")
	# Phase 1 — collect (never mutate while iterating the tree).
	var all_meshes: Array = []
	var world_children: Array = world.get_children()
	var house_pos: Array = []
	var roofs: Array = []
	var bodies: Array = []
	var stack: Array = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		if node is MeshInstance3D:
			all_meshes.append(node)
	for child in world_children:
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var nm := String(child.name)
			if nm.begins_with("House") and mi.mesh is BoxMesh and "Door" not in nm and "Roof" not in nm:
				house_pos.append(mi.position)
			if nm.begins_with("Roof") and mi.mesh is BoxMesh:
				roofs.append(mi)
		if child is CharacterBody3D and (String(child.name) == "Player" or String(child.name).begins_with("Villager")):
			bodies.append(child)
	# Phase 2 — pitched roof caps on village houses only: a roof
	# qualifies when a House box sits at the same x,z (Roof1-5,7,8).
	# Ridge runs along the roof's longer horizontal axis.
	for roof in roofs:
		var rm := roof as MeshInstance3D
		var found := false
		for hp in house_pos:
			var hpos := hp as Vector3
			if absf(hpos.x - rm.position.x) < 0.6 and absf(hpos.z - rm.position.z) < 0.6:
				found = true
				break
		if not found:
			continue
		var rsize := (rm.mesh as BoxMesh).size * rm.scale
		var roof_top := rm.position.y + rsize.y * 0.5
		var rmat: Material = rm.get_surface_override_material(0)
		if rmat == null:
			rmat = StandardMaterial3D.new()
			(rmat as StandardMaterial3D).albedo_color = Color(0.55, 0.30, 0.20, 1.0)
		var run := 0.0
		var rise := 0.7
		var slope_len := 0.0
		var ang := 0.0
		var along_x := rsize.x >= rsize.z
		if along_x:
			run = rsize.z * 0.5 + 0.3
		else:
			run = rsize.x * 0.5 + 0.3
		slope_len = sqrt(run * run + rise * rise)
		ang = atan2(rise, run)
		var base := String(rm.name)
		if along_x:
			_box(world, Vector3(rsize.x + 0.6, 0.12, slope_len), rmat, Vector3(rm.position.x, roof_top + rise * 0.5, rm.position.z - run * 0.5), "PitchCap70_%s_F" % base, Vector3(-ang, 0.0, 0.0))
			_box(world, Vector3(rsize.x + 0.6, 0.12, slope_len), rmat, Vector3(rm.position.x, roof_top + rise * 0.5, rm.position.z + run * 0.5), "PitchCap70_%s_B" % base, Vector3(ang, 0.0, 0.0))
			_box(world, Vector3(rsize.x + 0.6, 0.18, 0.18), rmat, Vector3(rm.position.x, roof_top + rise, rm.position.z), "PitchRidge70_%s" % base)
		else:
			_box(world, Vector3(slope_len, 0.12, rsize.z + 0.6), rmat, Vector3(rm.position.x - run * 0.5, roof_top + rise * 0.5, rm.position.z), "PitchCap70_%s_L" % base, Vector3(0.0, 0.0, ang))
			_box(world, Vector3(slope_len, 0.12, rsize.z + 0.6), rmat, Vector3(rm.position.x + run * 0.5, roof_top + rise * 0.5, rm.position.z), "PitchCap70_%s_R" % base, Vector3(0.0, 0.0, -ang))
			_box(world, Vector3(0.18, 0.18, rsize.z + 0.6), rmat, Vector3(rm.position.x, roof_top + rise, rm.position.z), "PitchRidge70_%s" % base)
	# Phase 2 — East Fields stilt-house veranda rails + front
	# cross-bracing (group-local coords, so rotated houses work).
	var east := world.get_node_or_null("EastDistrict62")
	if east != null:
		for grp in east.get_children():
			if not (grp is Node3D) or not String(grp.name).begins_with("StiltHouse62"):
				continue
			var g := grp as Node3D
			var floor_mi := g.get_node_or_null("Floor62") as MeshInstance3D
			var wood_mat: Material = null
			if floor_mi != null:
				wood_mat = floor_mi.get_surface_override_material(0)
			if wood_mat == null:
				wood_mat = StandardMaterial3D.new()
				(wood_mat as StandardMaterial3D).albedo_color = Color(0.45, 0.30, 0.16, 1.0)
			_box(g, Vector3(3.0, 0.08, 0.08), wood_mat, Vector3(0.0, 2.20, 4.0), "Rail70_Top")
			_box(g, Vector3(0.08, 0.78, 0.08), wood_mat, Vector3(-1.0, 1.81, 4.0), "Rail70_Bal_L")
			_box(g, Vector3(0.08, 0.78, 0.08), wood_mat, Vector3(1.0, 1.81, 4.0), "Rail70_Bal_R")
			var blen := sqrt(2.8 * 2.8 + 1.0 * 1.0)
			var bang := atan2(1.0, 2.8)
			_box(g, Vector3(blen, 0.12, 0.12), wood_mat, Vector3(-1.4, 0.65, 1.8), "Brace70_L", Vector3(0.0, 0.0, bang))
			_box(g, Vector3(blen, 0.12, 0.12), wood_mat, Vector3(1.4, 0.65, 1.8), "Brace70_R", Vector3(0.0, 0.0, -bang))
	# Phase 2 — people: oval head on a neck, hands on the arms.
	for body in bodies:
		var b := body as Node3D
		var head := b.get_node_or_null("Head") as MeshInstance3D
		if head == null:
			continue
		var skin_mat: Material = head.get_surface_override_material(0)
		head.scale = Vector3(0.85, 1.12, 0.92)
		head.position = Vector3(head.position.x, 0.70, head.position.z)
		var hair := b.get_node_or_null("Hair58") as MeshInstance3D
		if hair != null and absf(hair.position.y - 0.80) < 0.01:
			hair.position = Vector3(hair.position.x, 0.92, hair.position.z)
		var hat := b.get_node_or_null("Hat58") as MeshInstance3D
		if hat != null and absf(hat.position.y - 0.95) < 0.01:
			hat.position = Vector3(hat.position.x, 1.02, hat.position.z)
		var neck := MeshInstance3D.new()
		neck.name = "Neck70"
		var cm := CylinderMesh.new()
		cm.top_radius = 0.07
		cm.bottom_radius = 0.08
		cm.height = 0.22
		neck.mesh = cm
		neck.position = Vector3(0.0, 0.52, 0.0)
		if skin_mat != null:
			neck.set_surface_override_material(0, skin_mat)
		b.add_child(neck)
		for side in ["R", "L"]:
			var piv := b.get_node_or_null("ShoulderPivot58_" + side) as Node3D
			if piv == null:
				continue
			var hand := MeshInstance3D.new()
			hand.name = "Hand70_" + side
			var sm := SphereMesh.new()
			sm.radius = 0.07
			sm.height = 0.14
			hand.mesh = sm
			hand.position = Vector3(0.0, -0.60, 0.0)
			if skin_mat != null:
				hand.set_surface_override_material(0, skin_mat)
			piv.add_child(hand)
	# Phase 2 — textures + ground tiling + sun shadow bias.
	var plank_mats: Array = []
	var brick_mats: Array = []
	var corr_mats: Array = []
	var door_mats: Array = []
	var asphalt_mats: Array = []
	var dirt_mats: Array = []
	for mesh_node in all_meshes:
		var mi := mesh_node as MeshInstance3D
		var nm := String(mi.name)
		if mi.get_surface_override_material_count() <= 0:
			continue
		var mat := mi.get_surface_override_material(0)
		if mat == null:
			continue
		if nm == "GroundMesh":
			if mat is StandardMaterial3D:
				(mat as StandardMaterial3D).uv1_scale = Vector3(8.0, 8.0, 1.0)
		elif nm == "DressWall53" or nm == "Walls62" or nm == "Floor62" or nm == "Veranda62" or nm.begins_with("StiltWalls") or nm.begins_with("StiltDeck"):
			if not plank_mats.has(mat):
				plank_mats.append(mat)
		elif nm == "House6Walls" or (nm.begins_with("House") and mi.mesh is BoxMesh and "Door" not in nm and "Roof" not in nm):
			if not brick_mats.has(mat):
				brick_mats.append(mat)
		elif nm.begins_with("Roof") or nm.begins_with("StiltRoof"):
			if not corr_mats.has(mat):
				corr_mats.append(mat)
		elif nm.begins_with("DressDoor53") or nm == "Door62":
			if not door_mats.has(mat):
				door_mats.append(mat)
		elif nm == "MainRoad62":
			if not asphalt_mats.has(mat):
				asphalt_mats.append(mat)
		elif nm.begins_with("Patch58") or nm.begins_with("Row58") or nm == "LaneNorth62" or nm == "LaneSouth62":
			if not dirt_mats.has(mat):
				dirt_mats.append(mat)
	_apply_tex(plank_mats, plank_tex)
	_apply_tex(brick_mats, brick_tex)
	_apply_tex(corr_mats, corr_tex)
	_apply_tex(door_mats, door_tex)
	_apply_tex(asphalt_mats, asphalt_tex)
	_apply_tex(dirt_mats, dirt_tex)
	var dn := world.get_node_or_null("DayNight")
	if dn != null:
		var wm := dn.get("window_material") as StandardMaterial3D
		if wm != null and wm.albedo_texture == null:
			wm.albedo_texture = win_tex
		var sun := world.get_node_or_null("DayNight/SunLight") as DirectionalLight3D
		if sun != null:
			sun.shadow_bias = 0.01
			sun.shadow_normal_bias = 0.06
	set_process(false)


func _process(_delta: float) -> void:
	_frames += 1
	if _done or _frames < 12:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	_capture(world)
