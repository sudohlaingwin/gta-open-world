extends Node3D

# --- High-Performance Procedural 3D Grasslands & Meadow Wildflower System ---
# Optimized for Mobile Vulkan / Godot 4 (vivo V60 class)
# Single Draw Call via MultiMeshInstance3D with Foliage Wind Sway & SSS

const FOLIAGE_SHADER = preload("res://scripts/foliage_sway.gdshader")

var multi_mesh_inst: MultiMeshInstance3D = null
var player_ref: Node3D = null
var last_center_pos: Vector3 = Vector3(1e9, 1e9, 1e9)

const TOTAL_BLADES: int = 4096
const FIELD_RADIUS: float = 78.0
const SNAP_THRESHOLD: float = 5.0

# Pre-computed local distribution offsets
var local_offsets: Array[Vector3] = []
var local_scales: Array[Vector3] = []
var local_rotations: Array[float] = []
var local_colors: Array[Color] = []

func _ready() -> void:
	_init_distribution_cache()
	_build_multimesh()

func _init_distribution_cache() -> void:
	local_offsets.clear()
	local_scales.clear()
	local_rotations.clear()
	local_colors.clear()

	# Concentric stratified distribution:
	# 55% dense core near player (0 - 32m)
	# 30% mid meadow (32 - 58m)
	# 15% outer perimeter (58 - 78m)
	for i in range(TOTAL_BLADES):
		var r: float = 0.0
		var roll = randf()
		if roll < 0.55:
			r = sqrt(randf()) * 32.0
		elif roll < 0.85:
			r = 32.0 + sqrt(randf()) * 26.0
		else:
			r = 58.0 + sqrt(randf()) * 20.0

		var theta = randf() * TAU
		var ox = cos(theta) * r
		var oz = sin(theta) * r
		local_offsets.append(Vector3(ox, 0.0, oz))

		# Natural randomized size: height 0.55m to 0.92m, width 0.75m to 1.30m
		var h = randf_range(0.55, 0.92)
		var w = randf_range(0.75, 1.30)
		local_scales.append(Vector3(w, h, w))
		local_rotations.append(randf() * TAU)

		# Color Palette:
		# 74% Lush tropical Myanmar pasture emerald green
		# 16% Warm sun-kissed meadow olive-green
		#  6% Golden Padauk wildflower tips (ပိတောက်ဝါဝါ)
		#  4% Country daisy ivory-white blossoms (ခရေဖြူစင်)
		var flower_roll = randf()
		var col: Color
		if flower_roll < 0.06:
			col = Color(0.98, 0.84, 0.16, 1.0) # Golden Padauk Yellow
		elif flower_roll < 0.10:
			col = Color(0.96, 0.96, 0.92, 1.0) # Country Daisy Ivory White
		elif flower_roll < 0.26:
			var shade = randf_range(0.9, 1.1)
			col = Color(0.38 * shade, 0.68 * shade, 0.18, 1.0) # Sun-kissed Olive
		else:
			var shade = randf_range(0.85, 1.15)
			col = Color(0.28 * shade, 0.62 * shade, 0.16, 1.0) # Lush Tropical Emerald
		local_colors.append(col)

func _create_crossed_grass_mesh() -> ArrayMesh:
	var am = ArrayMesh.new()
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var w: float = 0.26
	var h: float = 0.76

	# Quad 1 (Angle 0 deg)
	var idx = 0
	verts.append(Vector3(-w, 0.0, 0.0))
	uvs.append(Vector2(0.0, 0.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(w, 0.0, 0.0))
	uvs.append(Vector2(1.0, 0.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(w, h, 0.0))
	uvs.append(Vector2(1.0, 1.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(-w, h, 0.0))
	uvs.append(Vector2(0.0, 1.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	indices.append_array([idx, idx + 1, idx + 2, idx, idx + 2, idx + 3])
	idx += 4

	# Quad 2 (Angle 60 deg)
	var a2 = PI / 3.0
	var c2 = cos(a2) * w
	var s2 = sin(a2) * w

	verts.append(Vector3(-c2, 0.0, -s2))
	uvs.append(Vector2(0.0, 0.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(c2, 0.0, s2))
	uvs.append(Vector2(1.0, 0.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(c2, h, s2))
	uvs.append(Vector2(1.0, 1.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(-c2, h, -s2))
	uvs.append(Vector2(0.0, 1.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	indices.append_array([idx, idx + 1, idx + 2, idx, idx + 2, idx + 3])
	idx += 4

	# Quad 3 (Angle 120 deg for lush full tuft)
	var a3 = 2.0 * PI / 3.0
	var c3 = cos(a3) * w
	var s3 = sin(a3) * w

	verts.append(Vector3(-c3, 0.0, -s3))
	uvs.append(Vector2(0.0, 0.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(c3, 0.0, s3))
	uvs.append(Vector2(1.0, 0.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(c3, h, s3))
	uvs.append(Vector2(1.0, 1.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	verts.append(Vector3(-c3, h, -s3))
	uvs.append(Vector2(0.0, 1.0))
	normals.append(Vector3(0.0, 1.0, 0.0))

	indices.append_array([idx, idx + 1, idx + 2, idx, idx + 2, idx + 3])

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am

func _build_multimesh() -> void:
	multi_mesh_inst = MultiMeshInstance3D.new()
	multi_mesh_inst.name = "LushGrassMultiMesh"
	add_child(multi_mesh_inst)

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _create_crossed_grass_mesh()
	mm.instance_count = TOTAL_BLADES
	multi_mesh_inst.multimesh = mm

	# Create ShaderMaterial with wind physics & SSS
	var mat = ShaderMaterial.new()
	mat.shader = FOLIAGE_SHADER
	mat.set_shader_parameter("foliage_color", Color(0.30, 0.64, 0.16, 1.0))
	mat.set_shader_parameter("stalk_color", Color(0.18, 0.38, 0.10, 1.0))
	mat.set_shader_parameter("sun_transmission_color", Color(0.52, 0.86, 0.22, 1.0))
	mat.set_shader_parameter("wind_speed", 1.6)
	mat.set_shader_parameter("wind_strength", 0.22)
	mat.set_shader_parameter("flutter_speed", 6.5)
	mat.set_shader_parameter("flutter_strength", 0.08)
	multi_mesh_inst.material_override = mat

	_update_blade_positions(Vector3.ZERO)

func _update_blade_positions(center: Vector3) -> void:
	if not multi_mesh_inst or not multi_mesh_inst.multimesh:
		return
	var mm = multi_mesh_inst.multimesh

	for i in range(TOTAL_BLADES):
		var base_off = local_offsets[i]
		var world_x = center.x + base_off.x
		var world_z = center.z + base_off.z

		var t = Transform3D()
		t = t.scaled(local_scales[i])
		t = t.rotated(Vector3.UP, local_rotations[i])
		t.origin = Vector3(world_x, 0.05, world_z)

		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, local_colors[i])

func _process(_delta: float) -> void:
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
	if player_ref:
		var p_pos = player_ref.global_position
		p_pos.y = 0.0
		if p_pos.distance_squared_to(last_center_pos) > (SNAP_THRESHOLD * SNAP_THRESHOLD):
			last_center_pos = p_pos
			_update_blade_positions(last_center_pos)
