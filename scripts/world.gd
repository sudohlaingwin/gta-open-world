extends Node3D

func _ready() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("load_game"):
		var data = save_mgr.load_game()
		if not data.is_empty():
			var player = get_tree().get_first_node_in_group("player")
			if player and data.has("pos_x"):
				player.global_position = Vector3(data["pos_x"], data["pos_y"], data["pos_z"])
				if data.has("stamina"):
					player.stamina = float(data["stamina"])
			
			var hud = get_tree().get_first_node_in_group("hud")
			if not hud:
				hud = get_node_or_null("MobileTouchHUD")
			if hud:
				if data.has("quest_stage"):
					hud.quest_stage = int(data["quest_stage"])
				if data.has("villagers_talked"):
					hud.villagers_talked_count = int(data["villagers_talked"])
				if hud.has_method("_update_quest_text"):
					hud._update_quest_text()

	apply_vehicle_paints()
	_setup_infinite_ground()

var terrain_node: Node3D = null
var player_ref: Node3D = null

func _setup_infinite_ground() -> void:
	terrain_node = get_node_or_null("Terrain")
	player_ref = get_tree().get_first_node_in_group("player")
	if terrain_node:
		var ground_mesh_inst = terrain_node.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if ground_mesh_inst:
			var pbr_ground_mat = StandardMaterial3D.new()
			# Authentic Southeast Asian rural earth & lush tropical grass blend
			pbr_ground_mat.albedo_color = Color(0.28, 0.42, 0.18, 1.0)
			pbr_ground_mat.roughness = 0.88
			pbr_ground_mat.metallic = 0.02
			pbr_ground_mat.specular = 0.25
			var ground_noise = FastNoiseLite.new()
			ground_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			ground_noise.frequency = 0.035
			ground_noise.fractal_octaves = 3
			ground_noise.fractal_gain = 0.5
			var g_tex = NoiseTexture2D.new()
			g_tex.noise = ground_noise
			g_tex.as_normal_map = true
			g_tex.bump_strength = 1.4
			pbr_ground_mat.normal_enabled = true
			pbr_ground_mat.normal_texture = g_tex
			pbr_ground_mat.uv1_scale = Vector3(320.0, 320.0, 320.0)
			ground_mesh_inst.set_surface_override_material(0, pbr_ground_mat)

func _process(_delta: float) -> void:
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
	if terrain_node and player_ref:
		# Infinite seamless terrain origin snapping (ကစားသူသွားရာနောက် မြေပြင်အဆုံးမရှိလိုက်ပါခြင်း)
		var px = player_ref.global_position.x
		var pz = player_ref.global_position.z
		terrain_node.global_position.x = floor(px / 50.0) * 50.0
		terrain_node.global_position.z = floor(pz / 50.0) * 50.0


func apply_vehicle_paints() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm:
		return

	# 1. Car paint
	var car = get_node_or_null("VillageCar")
	if car and sm.get("car_paint_html") != null:
		var body = car.get_node_or_null("VisualMesh/Body")
		if body:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.from_string(sm.car_paint_html, Color(0.12, 0.45, 0.78, 1))
			body.set_surface_override_material(0, mat)

	# 2. Motorcycle paint
	var bike = get_node_or_null("MyanmarMotorcycle")
	if bike and sm.get("motorcycle_paint_html") != null:
		var frame = bike.get_node_or_null("VisualMesh/Frame")
		if frame:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.from_string(sm.motorcycle_paint_html, Color(0.85, 0.15, 0.1, 1))
			frame.set_surface_override_material(0, mat)

	# 3. Tuk-Tuk paint
	var tuktuk = get_node_or_null("MyanmarTukTuk")
	if tuktuk and sm.get("tuktuk_paint_html") != null:
		var cabin = tuktuk.get_node_or_null("VisualMesh/Cabin")
		if cabin:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.from_string(sm.tuktuk_paint_html, Color(0.95, 0.72, 0.1, 1))
			cabin.set_surface_override_material(0, mat)