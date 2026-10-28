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
			# Authentic Southeast Asian lush tropical pasture earth & grass blend
			pbr_ground_mat.albedo_color = Color(0.26, 0.44, 0.16, 1.0)
			pbr_ground_mat.roughness = 0.88
			pbr_ground_mat.metallic = 0.02
			pbr_ground_mat.specular = 0.22
			var ground_noise = FastNoiseLite.new()
			ground_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			ground_noise.frequency = 0.05
			ground_noise.fractal_octaves = 4
			ground_noise.fractal_gain = 0.55
			var g_tex = NoiseTexture2D.new()
			g_tex.noise = ground_noise
			g_tex.as_normal_map = true
			g_tex.bump_strength = 2.0
			pbr_ground_mat.normal_enabled = true
			pbr_ground_mat.normal_texture = g_tex
			pbr_ground_mat.uv1_scale = Vector3(450.0, 450.0, 450.0)
			ground_mesh_inst.set_surface_override_material(0, pbr_ground_mat)

	# Dynamic 3D Grasslands & Meadow Wildflower System (လေတိုက်ခတ်ယိမ်းနွဲ့နေသော မြက်ခင်းပြင်စနစ်)
	var grass_script = preload("res://scripts/grass_system.gd")
	if grass_script:
		var grass_inst = grass_script.new()
		grass_inst.name = "GrassSystem"
		add_child(grass_inst)

	_generate_scenic_mountain_ranges()

func _generate_scenic_mountain_ranges() -> void:
	var mountains_holder = Node3D.new()
	mountains_holder.name = "ScenicMountainsAndHills"
	add_child(mountains_holder)

	var hill_mat = StandardMaterial3D.new()
	hill_mat.albedo_color = Color(0.20, 0.35, 0.15, 1.0)
	hill_mat.roughness = 0.95
	hill_mat.specular = 0.15

	var mountain_mat = StandardMaterial3D.new()
	mountain_mat.albedo_color = Color(0.18, 0.28, 0.22, 1.0)
	mountain_mat.roughness = 0.92
	mountain_mat.specular = 0.20

	# 1. Distant Mountain Ranges encircling the 8000m x 8000m map
	var num_ranges = 36
	for i in range(num_ranges):
		var angle = (float(i) / float(num_ranges)) * TAU
		var radius = 1200.0 + (i % 5) * 220.0
		var mx = cos(angle) * radius
		var mz = sin(angle) * radius
		var height = 180.0 + (i % 7) * 45.0
		var base_radius = 220.0 + (i % 4) * 60.0

		var mountain = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 12.0
		cone.bottom_radius = base_radius
		cone.height = height
		mountain.mesh = cone
		mountain.set_surface_override_material(0, mountain_mat)
		mountains_holder.add_child(mountain)
		mountain.global_position = Vector3(mx, height * 0.45, mz)

	# 2. Mid-distance Rolling Hills & Ridges
	var num_hills = 28
	for j in range(num_hills):
		var h_angle = (float(j) / float(num_hills)) * TAU + 0.15
		var h_radius = 550.0 + (j % 4) * 110.0
		var hx = cos(h_angle) * h_radius
		var hz = sin(h_angle) * h_radius
		var h_height = 55.0 + (j % 5) * 18.0
		var h_base = 110.0 + (j % 3) * 35.0

		var hill = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = h_base
		sphere.height = h_height * 2.0
		hill.mesh = sphere
		hill.set_surface_override_material(0, hill_mat)
		mountains_holder.add_child(hill)
		hill.global_position = Vector3(hx, 0.0, hz)

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

	# 1. Car paint (VillageCar uses BodyMesh with high-gloss metallic finish)
	var car = get_node_or_null("VillageCar")
	if car and sm.get("car_paint_html") != null:
		var body = car.get_node_or_null("BodyMesh")
		if not body:
			body = car.get_node_or_null("VisualMesh/Body")
		if body:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.from_string(sm.car_paint_html, Color(0.12, 0.45, 0.78, 1))
			mat.metallic = 0.22
			mat.roughness = 0.32
			mat.specular = 0.75
			body.set_surface_override_material(0, mat)

	# 2. Motorcycle paint (MyanmarMotorcycle uses VisualMesh/Frame)
	var bike = get_node_or_null("MyanmarMotorcycle")
	if bike and sm.get("motorcycle_paint_html") != null:
		var frame = bike.get_node_or_null("VisualMesh/Frame")
		if not frame:
			frame = bike.get_node_or_null("Frame")
		if frame:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.from_string(sm.motorcycle_paint_html, Color(0.85, 0.15, 0.1, 1))
			mat.metallic = 0.25
			mat.roughness = 0.28
			mat.specular = 0.75
			frame.set_surface_override_material(0, mat)

	# 3. Tuk-Tuk paint (MyanmarTukTuk uses VisualMesh/Cabin)
	var tuktuk = get_node_or_null("MyanmarTukTuk")
	if tuktuk and sm.get("tuktuk_paint_html") != null:
		var cabin = tuktuk.get_node_or_null("VisualMesh/Cabin")
		if not cabin:
			cabin = tuktuk.get_node_or_null("Cabin")
		if cabin:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.from_string(sm.tuktuk_paint_html, Color(0.95, 0.72, 0.1, 1))
			mat.metallic = 0.22
			mat.roughness = 0.32
			mat.specular = 0.70
			cabin.set_surface_override_material(0, mat)