extends Node3D

# --- Authentic Mindon Township (မင်းတုန်းမြို့) Real-World Urban & District Map Builder ---
# Geographic Center: 19.351497 N, 94.731889 E (Mindon, Magway Region, Myanmar)
# True Urban Architecture: 
# - Real GIS Roads (Pyay-Mindon Highway, Town Bazaar Street, Strand Road, Residential Lanes)
# - Real Mindon Town Wards:
#   * အမှတ် (၁) ရပ်ကွက် (Ward 1 - Northern Residential Ward)
#   * အမှတ် (၂) ရပ်ကွက် (Ward 2 - High School & Monastery Ward)
#   * အမှတ် (၃) ရပ်ကွက် (Ward 3 - Central Bazaar & General Hospital Ward)
#   * အမှတ် (၄) ရပ်ကွက် (Ward 4 - Strand Road, Mindon Creek & Shwe Mindon Pagoda Ward)
# - Densely populated authentic Myanmar stilt houses lining the streets on both sides!
# - Real civic landmarks (Central Market, Hospital, High School, Pagoda, Bamboo Bridge)

const HOUSE_SCENE = preload("res://scenes/myanmar_house.tscn")
const PALM_SCENE = preload("res://scenes/toddy_palm.tscn")
const BANANA_SCENE = preload("res://scenes/banana_plant.tscn")
const ZAYAT_SCENE = preload("res://scenes/myanmar_zayat.tscn")
const POT_SCENE = preload("res://scenes/water_pot_stand.tscn")
const WELL_SCENE = preload("res://scenes/village_well.tscn")
const VILLAGE_GATE_SCENE = preload("res://scenes/village_gate.tscn")
const PADDY_SCENE = preload("res://scenes/myanmar_paddy_field.tscn")
const PAGODA_SCENE = preload("res://scenes/myanmar_pagoda.tscn")
const PIER_SCENE = preload("res://scenes/river_boat_pier.tscn")
const BOAT_SCENE = preload("res://scenes/ayeyarwady_rowboat.tscn")
const BRIDGE_SCENE = preload("res://scenes/bamboo_bridge.tscn")
const TEASHOP_SCENE = preload("res://scenes/myanmar_teashop.tscn")
const STALL_SCENE = preload("res://scenes/market_stall.tscn")
const PITCH_SCENE = preload("res://scenes/football_pitch.tscn")
const BELL_SCENE = preload("res://scenes/monastery_bell.tscn")
const MONASTERY_SCENE = preload("res://scenes/monastery_school.tscn")
const NIGHT_MARKET_SCENE = preload("res://scenes/myanmar_night_market.tscn")
const GUESTHOUSE_SCENE = preload("res://scenes/myanmar_guesthouse.tscn")
const RIVER_SHADER = preload("res://scripts/water_river.gdshader")
const BULLOCK_CART_SCENE = preload("res://scenes/bullock_cart.tscn")
const COW_SCENE = preload("res://scenes/rideable_cow.tscn")
const MOTORCYCLE_SCENE = preload("res://scenes/myanmar_motorcycle.tscn")
const TUKTUK_SCENE = preload("res://scenes/myanmar_tuktuk.tscn")

func _ready() -> void:
	var file = FileAccess.open("res://mindon_geo_data.json", FileAccess.READ)
	if not file:
		push_error("MindonMapBuilder: Failed to open mindon_geo_data.json")
		return
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		push_error("MindonMapBuilder: Failed to parse mindon_geo_data.json")
		return

	var data = json.data
	var roads = data.get("roads", [])
	var buildings = data.get("buildings", [])
	var rivers = data.get("rivers", [])

	_generate_mindon_roads(roads)
	_generate_mindon_street_houses(roads)
	_generate_mindon_buildings(buildings)
	_generate_mindon_rivers(rivers)
	_generate_mindon_wards_and_signboards()
	_generate_mindon_civic_landmarks()
	_generate_vast_paddy_terraces_and_farms()
	_generate_mindon_airfield()
	_generate_mindon_district_vehicles_and_mounts()

func _generate_mindon_roads(roads: Array) -> void:
	var road_holder = Node3D.new()
	road_holder.name = "MindonRoads"
	add_child(road_holder)

	# --- PBR Road Surface & Shoulder Materials ---
	# 1. Dark Bitumen Asphalt for Pyay-Mindon Highway
	var highway_asphalt_mat = StandardMaterial3D.new()
	highway_asphalt_mat.albedo_color = Color(0.20, 0.21, 0.22, 1.0)
	highway_asphalt_mat.roughness = 0.84
	var asphalt_noise = FastNoiseLite.new()
	asphalt_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	asphalt_noise.frequency = 0.08
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = asphalt_noise
	noise_tex.as_normal_map = true
	noise_tex.bump_strength = 0.85
	highway_asphalt_mat.normal_enabled = true
	highway_asphalt_mat.normal_texture = noise_tex

	# 2. Weathered Chip-Seal Asphalt for Town Residential & Bazaar Streets
	var town_asphalt_mat = StandardMaterial3D.new()
	town_asphalt_mat.albedo_color = Color(0.28, 0.29, 0.30, 1.0)
	town_asphalt_mat.roughness = 0.90
	town_asphalt_mat.normal_enabled = true
	town_asphalt_mat.normal_texture = noise_tex

	# 3. Compacted Myanmar Red-Earth Laterite Gravel for Countryside & Monastic Lanes (မြေနီကျောက်စရစ်လမ်း)
	var dirt_lane_mat = StandardMaterial3D.new()
	dirt_lane_mat.albedo_color = Color(0.50, 0.38, 0.24, 1.0)
	dirt_lane_mat.roughness = 0.95

	# 4. Red Laterite Dirt Road Shoulders (လမ်းဘေး ပခုံးမြေသား)
	var road_shoulder_mat = StandardMaterial3D.new()
	road_shoulder_mat.albedo_color = Color(0.46, 0.34, 0.22, 1.0)
	road_shoulder_mat.roughness = 0.96

	# 5. Concrete Curbs & Drainage Gutters (မြို့တွင်း လမ်းဘောင်ခတ်ကျောက်တုံးများ)
	var curb_mat = StandardMaterial3D.new()
	curb_mat.albedo_color = Color(0.68, 0.67, 0.64, 1.0)
	curb_mat.roughness = 0.78

	# 6. Highway Yellow Dashed Centerline (လမ်းလယ် အဝါရောင် မျဉ်းကြား)
	var yellow_line_mat = StandardMaterial3D.new()
	yellow_line_mat.albedo_color = Color(0.96, 0.82, 0.14, 1.0)
	yellow_line_mat.roughness = 0.35
	yellow_line_mat.emission_enabled = true
	yellow_line_mat.emission = Color(0.92, 0.76, 0.12, 1.0)
	yellow_line_mat.emission_energy_multiplier = 0.45

	# 7. Highway Outer White Boundary Edge Lines (လမ်းဘေး အဖြူရောင် အစွန်းမျဉ်း)
	var white_line_mat = StandardMaterial3D.new()
	white_line_mat.albedo_color = Color(0.95, 0.95, 0.92, 1.0)
	white_line_mat.roughness = 0.40

	# 8. Amber Reflective Cat's Eye Studs (လမ်းလယ် အလင်းပြန်ခလုတ်များ)
	var cat_eye_mat = StandardMaterial3D.new()
	cat_eye_mat.albedo_color = Color(1.0, 0.84, 0.18, 1.0)
	cat_eye_mat.metallic = 0.80
	cat_eye_mat.roughness = 0.15
	cat_eye_mat.emission_enabled = true
	cat_eye_mat.emission = Color(1.0, 0.80, 0.15, 1.0)
	cat_eye_mat.emission_energy_multiplier = 1.2

	# 9. Myanmar Whitewashed Road Milestone Pillar Material (မြန်မာ့မိုင်တိုင်များ)
	var milestone_mat = StandardMaterial3D.new()
	milestone_mat.albedo_color = Color(0.94, 0.94, 0.92, 1.0)
	milestone_mat.roughness = 0.65

	var milestone_base_mat = StandardMaterial3D.new()
	milestone_base_mat.albedo_color = Color(0.22, 0.22, 0.24, 1.0)
	milestone_base_mat.roughness = 0.80

	var highway_milestone_interval: float = 0.0

	# Track processed junction nodes to place seamless junction discs
	var visited_nodes: Dictionary = {}

	for r in roads:
		var pts = r.get("pts", [])
		if pts.size() < 2:
			continue

		var r_type = str(r.get("type", "residential"))
		var is_highway: bool = (r_type == "unclassified")
		var is_residential: bool = (r_type == "residential")

		var road_width: float = 9.6 if is_highway else (6.2 if is_residential else 4.6)
		var pavement_mat = highway_asphalt_mat if is_highway else (town_asphalt_mat if is_residential else dirt_lane_mat)

		# 1. Seamless Circular Junction Disc Pads at Nodes
		for p in pts:
			var node_key = "%.1f_%.1f" % [p["x"], p["z"]]
			if not visited_nodes.has(node_key):
				visited_nodes[node_key] = true
				var node_pos = Vector3(p["x"], 0.0, p["z"])

				# Red dirt shoulder disc
				var sh_disc = MeshInstance3D.new()
				var sh_cyl = CylinderMesh.new()
				sh_cyl.top_radius = (road_width + 2.4) * 0.52
				sh_cyl.bottom_radius = (road_width + 2.4) * 0.52
				sh_cyl.height = 0.041
				sh_disc.mesh = sh_cyl
				sh_disc.set_surface_override_material(0, road_shoulder_mat)
				road_holder.add_child(sh_disc)
				sh_disc.global_position = node_pos + Vector3(0, 0.02, 0)

				# Pavement disc
				var pv_disc = MeshInstance3D.new()
				var pv_cyl = CylinderMesh.new()
				pv_cyl.top_radius = road_width * 0.52
				pv_cyl.bottom_radius = road_width * 0.52
				pv_cyl.height = 0.076
				pv_disc.mesh = pv_cyl
				pv_disc.set_surface_override_material(0, pavement_mat)
				road_holder.add_child(pv_disc)
				pv_disc.global_position = node_pos + Vector3(0, 0.038, 0)

		# 2. Road Segments, Dirt Shoulders & Highway Features
		for i in range(pts.size() - 1):
			var p1 = Vector3(pts[i]["x"], 0.0, pts[i]["z"])
			var p2 = Vector3(pts[i + 1]["x"], 0.0, pts[i + 1]["z"])
			var dist = p1.distance_to(p2)
			if dist < 0.4 or dist > 220.0:
				continue

			var mid_point = (p1 + p2) * 0.5
			var forward = (p2 - p1).normalized()
			var right_dir = forward.cross(Vector3.UP).normalized()

			# A. Red Laterite Dirt Road Shoulder (Flanking both sides by 1.2m)
			var shoulder_mesh = MeshInstance3D.new()
			var sh_box = BoxMesh.new()
			sh_box.size = Vector3(road_width + 2.4, 0.04, dist)
			shoulder_mesh.mesh = sh_box
			shoulder_mesh.set_surface_override_material(0, road_shoulder_mat)
			road_holder.add_child(shoulder_mesh)
			shoulder_mesh.global_position = mid_point + Vector3(0, 0.02, 0)
			shoulder_mesh.look_at(shoulder_mesh.global_position + forward, Vector3.UP)

			# B. Main Pavement Box
			var pavement_mesh = MeshInstance3D.new()
			var pv_box = BoxMesh.new()
			pv_box.size = Vector3(road_width, 0.075, dist)
			pavement_mesh.mesh = pv_box
			pavement_mesh.set_surface_override_material(0, pavement_mat)
			road_holder.add_child(pavement_mesh)
			pavement_mesh.global_position = mid_point + Vector3(0, 0.038, 0)
			pavement_mesh.look_at(pavement_mesh.global_position + forward, Vector3.UP)

			# C. Highway Markings, Cat's Eyes & Milestone Pillars
			if is_highway:
				# Outer Solid White Edge Lines (Placed 0.45m from road edge)
				var line_box = BoxMesh.new()
				line_box.size = Vector3(0.18, 0.082, dist)

				var line_l = MeshInstance3D.new()
				line_l.mesh = line_box
				line_l.set_surface_override_material(0, white_line_mat)
				road_holder.add_child(line_l)
				line_l.global_position = mid_point - right_dir * (road_width * 0.5 - 0.45) + Vector3(0, 0.042, 0)
				line_l.look_at(line_l.global_position + forward, Vector3.UP)

				var line_r = MeshInstance3D.new()
				line_r.mesh = line_box
				line_r.set_surface_override_material(0, white_line_mat)
				road_holder.add_child(line_r)
				line_r.global_position = mid_point + right_dir * (road_width * 0.5 - 0.45) + Vector3(0, 0.042, 0)
				line_r.look_at(line_r.global_position + forward, Vector3.UP)

				# Center Dashed Yellow Divider Stripe
				if i % 2 == 0 and dist >= 1.8:
					var stripe = MeshInstance3D.new()
					var stripe_mesh = BoxMesh.new()
					stripe_mesh.size = Vector3(0.28, 0.084, minf(dist * 0.65, 3.4))
					stripe.mesh = stripe_mesh
					stripe.set_surface_override_material(0, yellow_line_mat)
					road_holder.add_child(stripe)
					stripe.global_position = mid_point + Vector3(0, 0.043, 0)
					stripe.look_at(stripe.global_position + forward, Vector3.UP)

					# Amber Reflective Cat's Eye Stud
					var cat_eye = MeshInstance3D.new()
					var cat_mesh = BoxMesh.new()
					cat_mesh.size = Vector3(0.12, 0.092, 0.12)
					cat_eye.mesh = cat_mesh
					cat_eye.set_surface_override_material(0, cat_eye_mat)
					road_holder.add_child(cat_eye)
					cat_eye.global_position = mid_point + Vector3(0, 0.046, 0)

				# Town Section Concrete Curbs (-220 < x < 220)
				if mid_point.x > -220.0 and mid_point.x < 220.0:
					var curb_box = BoxMesh.new()
					curb_box.size = Vector3(0.35, 0.16, dist)

					var curb_l = MeshInstance3D.new()
					curb_l.mesh = curb_box
					curb_l.set_surface_override_material(0, curb_mat)
					road_holder.add_child(curb_l)
					curb_l.global_position = mid_point - right_dir * (road_width * 0.5 + 0.18) + Vector3(0, 0.08, 0)
					curb_l.look_at(curb_l.global_position + forward, Vector3.UP)

					var curb_r = MeshInstance3D.new()
					curb_r.mesh = curb_box
					curb_r.set_surface_override_material(0, curb_mat)
					road_holder.add_child(curb_r)
					curb_r.global_position = mid_point + right_dir * (road_width * 0.5 + 0.18) + Vector3(0, 0.08, 0)
					curb_r.look_at(curb_r.global_position + forward, Vector3.UP)

				# Authentic Myanmar Highway Milestone Pillars (မိုင်တိုင်များ at ~200m intervals)
				highway_milestone_interval += dist
				if highway_milestone_interval >= 190.0:
					highway_milestone_interval = 0.0
					var m_post = Node3D.new()
					road_holder.add_child(m_post)
					var m_side = 1.0 if (i % 2 == 0) else -1.0
					m_post.global_position = mid_point + right_dir * (road_width * 0.5 + 1.1) * m_side

					# Black Foundation Plinth
					var m_base = MeshInstance3D.new()
					var b_mesh = BoxMesh.new()
					b_mesh.size = Vector3(0.48, 0.22, 0.48)
					m_base.mesh = b_mesh
					m_base.set_surface_override_material(0, milestone_base_mat)
					m_post.add_child(m_base)
					m_base.position = Vector3(0, 0.11, 0)

					# Whitewashed Curved Milestone Pillar
					var m_body = MeshInstance3D.new()
					var body_mesh = CylinderMesh.new()
					body_mesh.top_radius = 0.16
					body_mesh.bottom_radius = 0.18
					body_mesh.height = 0.72
					m_body.mesh = body_mesh
					m_body.set_surface_override_material(0, milestone_mat)
					m_post.add_child(m_body)
					m_body.position = Vector3(0, 0.54, 0)

					# Top Dome Cap
					var m_dome = MeshInstance3D.new()
					var dome_mesh = SphereMesh.new()
					dome_mesh.radius = 0.16
					dome_mesh.height = 0.22
					m_dome.mesh = dome_mesh
					m_dome.set_surface_override_material(0, milestone_mat)
					m_post.add_child(m_dome)
					m_dome.position = Vector3(0, 0.88, 0)

					# Milestone Text Label (Myanmar Road Distance)
					var m_lbl = Label3D.new()
					m_lbl.text = "မင်းတုန်း\n၀ မိုင်" if absf(mid_point.x) < 80.0 else ("ပြည်\n၆၅ မိုင်" if mid_point.x < 0 else "တောင်ကုတ်\n၈၅ မိုင်")
					m_lbl.font_size = 28
					m_lbl.modulate = Color(0.12, 0.12, 0.14)
					m_lbl.outline_modulate = Color(1, 1, 1, 0.9)
					m_lbl.outline_size = 3
					m_lbl.pixel_size = 0.0038
					m_post.add_child(m_lbl)
					m_lbl.position = Vector3(0, 0.58, 0.19)
					m_post.look_at(m_post.global_position - right_dir * m_side, Vector3.UP)

func _generate_mindon_street_houses(roads: Array) -> void:
	var street_houses_holder = Node3D.new()
	street_houses_holder.name = "MindonStreetHouses"
	add_child(street_houses_holder)

	var placed_houses: Array[Vector3] = []
	var min_house_dist: float = 18.0

	var fence_mat = StandardMaterial3D.new()
	fence_mat.albedo_color = Color(0.52, 0.38, 0.22, 1.0)
	fence_mat.roughness = 0.9

	var lantern_post_mat = StandardMaterial3D.new()
	lantern_post_mat.albedo_color = Color(0.28, 0.18, 0.10, 1.0)
	lantern_post_mat.roughness = 0.85

	var lantern_script = preload("res://scripts/village_lantern_controller.gd")

	for r_idx in range(roads.size()):
		var r = roads[r_idx]
		var pts = r.get("pts", [])
		if pts.size() < 2:
			continue

		var is_highway = (str(r.get("type", "")) == "unclassified")
		var setback: float = 9.8 if is_highway else 7.2
		var step: float = 28.0 if is_highway else 22.0

		for i in range(pts.size() - 1):
			var p1 = Vector3(pts[i]["x"], 0.0, pts[i]["z"])
			var p2 = Vector3(pts[i + 1]["x"], 0.0, pts[i + 1]["z"])
			var dist = p1.distance_to(p2)
			if dist < 16.0:
				continue

			var fwd = (p2 - p1).normalized()
			var right_dir = fwd.cross(Vector3.UP).normalized()
			var count = int(dist / step)

			for k in range(1, count + 1):
				var t = (float(k) * step) / dist
				var mid = p1 + (p2 - p1) * t

				# Left House Slot
				var left_pos = mid - right_dir * setback
				var left_rot = atan2(right_dir.x, right_dir.z)
				_try_spawn_house(street_houses_holder, left_pos, left_rot, placed_houses, min_house_dist, fence_mat, lantern_post_mat, lantern_script, right_dir)

				# Right House Slot
				var right_pos = mid + right_dir * setback
				var right_rot = atan2(-right_dir.x, -right_dir.z)
				_try_spawn_house(street_houses_holder, right_pos, right_rot, placed_houses, min_house_dist, fence_mat, lantern_post_mat, lantern_script, -right_dir)

func _try_spawn_house(holder: Node3D, pos: Vector3, rot_y: float, placed: Array[Vector3], min_dist: float, fence_mat: Material, post_mat: Material, lantern_script: Script, facing_dir: Vector3) -> void:
	for existing in placed:
		if pos.distance_squared_to(existing) < (min_dist * min_dist):
			return

	placed.append(pos)

	var house = HOUSE_SCENE.instantiate()
	holder.add_child(house)
	house.global_position = pos
	house.rotation.y = rot_y
	house.scale = Vector3(1.0, 1.0, 1.0)

	# Front Courtyard Entrance Post & Night Hurricane Lantern
	var post = MeshInstance3D.new()
	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.08
	post_mesh.bottom_radius = 0.09
	post_mesh.height = 2.4
	post.mesh = post_mesh
	post.set_surface_override_material(0, post_mat)
	holder.add_child(post)
	var post_offset = pos + facing_dir * 3.8 + (facing_dir.cross(Vector3.UP) * 2.2)
	post_offset.y = 1.2
	post.global_position = post_offset

	# Warm Night Lantern
	var lantern_light = OmniLight3D.new()
	lantern_light.light_color = Color(1.0, 0.88, 0.65, 1.0)
	lantern_light.light_energy = 1.6
	lantern_light.omni_range = 14.0
	lantern_light.position = Vector3(0.0, 1.1, 0.0)
	post.add_child(lantern_light)

	var lantern_ctrl = lantern_script.new()
	post.add_child(lantern_ctrl)

	# Water Pot Stand (သောက်ရေအိုးစင်) in front of compound (every 2nd house)
	if placed.size() % 2 == 0:
		var pot = POT_SCENE.instantiate()
		holder.add_child(pot)
		var pot_pos = pos + facing_dir * 4.2 - (facing_dir.cross(Vector3.UP) * 1.8)
		pot_pos.y = 0.0
		pot.global_position = pot_pos

	# Yard Toddy Palm or Banana Plant
	if placed.size() % 3 == 1:
		var palm = PALM_SCENE.instantiate()
		holder.add_child(palm)
		var palm_pos = pos - facing_dir * 3.5 + (facing_dir.cross(Vector3.UP) * 3.2)
		palm_pos.y = 0.0
		palm.global_position = palm_pos
	elif placed.size() % 3 == 2:
		var banana = BANANA_SCENE.instantiate()
		holder.add_child(banana)
		var banana_pos = pos - facing_dir * 3.2 - (facing_dir.cross(Vector3.UP) * 3.0)
		banana_pos.y = 0.0
		banana.global_position = banana_pos

func _generate_mindon_wards_and_signboards() -> void:
	var civic_holder = Node3D.new()
	civic_holder.name = "MindonCivicWards"
	add_child(civic_holder)

	# The 4 Historical Wards of Mindon Town (မင်းတုန်းမြို့ ၄ ရပ်ကွက်)
	var ward_gates = [
		{
			"name": "အမှတ် (၁) ရပ်ကွက်",
			"sub": "မင်းတုန်းမြို့ မြောက်ပိုင်း လူနေရပ်ကွက်",
			"pos": Vector3(120.0, 0.0, -120.0),
			"rot": 45.0
		},
		{
			"name": "အမှတ် (၂) ရပ်ကွက်",
			"sub": "မင်းတုန်း အထက ကျောင်းကြီး နှင့် ဘုန်းတော်ကြီးကျောင်း ရပ်ကွက်",
			"pos": Vector3(-180.0, 0.0, -80.0),
			"rot": -35.0
		},
		{
			"name": "အမှတ် (၃) ရပ်ကွက်",
			"sub": "မင်းတုန်း မြို့မဈေးကြီး နှင့် ပြည်သူ့ဆေးရုံ ရပ်ကွက်",
			"pos": Vector3(-15.0, 0.0, 78.0),
			"rot": 90.0
		},
		{
			"name": "အမှတ် (၄) ရပ်ကွက်",
			"sub": "မင်းတုန်း ကမ်းနားလမ်း နှင့် ရွှေမင်းတုန်းစေတီ ရပ်ကွက်",
			"pos": Vector3(80.0, 0.0, 160.0),
			"rot": -60.0
		}
	]

	for wg in ward_gates:
		var gate = VILLAGE_GATE_SCENE.instantiate()
		civic_holder.add_child(gate)
		gate.global_position = wg["pos"]
		gate.rotation.y = deg_to_rad(wg["rot"])

		# Ward Title Signboard above Arch
		var sign = Label3D.new()
		sign.text = "%s\n(%s)" % [wg["name"], wg["sub"]]
		sign.font_size = 32
		sign.outline_size = 8
		sign.modulate = Color(1.0, 0.88, 0.25, 1.0)
		sign.position = Vector3(0.0, 5.2, 0.0)
		sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		gate.add_child(sign)

	# Major Crossroads 3D Wayfinding Directional Signboards
	var crossroads_signs = [
		{
			"pos": Vector3(0.0, 0.0, 30.0),
			"text": "ပြည် - မင်းတုန်း လမ်းမကြီး\n⬅️ ပြည်မြို့ (၆၅ မိုင်) | တောင်ကုတ်မြို့ (၈၅ မိုင်) ➡️\n⬆️ မြို့မဈေးကြီး နှင့် ပြည်သူ့ဆေးရုံ သို့",
			"color": Color(0.2, 0.9, 1.0)
		},
		{
			"pos": Vector3(-80.0, 0.0, 105.0),
			"text": "🏥 မင်းတုန်းမြို့နယ် ပြည်သူ့ဆေးရုံကြီး လမ်းခွဲ",
			"color": Color(1.0, 0.35, 0.35)
		},
		{
			"pos": Vector3(25.0, 0.0, 20.0),
			"text": "🛍️ မင်းတုန်း မြို့မဈေးကြီး နှင့် လက်ဖက်ရည်ဆိုင် လမ်းမ",
			"color": Color(1.0, 0.85, 0.2)
		},
		{
			"pos": Vector3(15.0, 0.0, 85.0),
			"text": "🌊 မင်းတုန်း ကမ်းနားလမ်း နှင့် ဝါးတံတား သို့ ⬇️",
			"color": Color(0.3, 1.0, 0.6)
		}
	]

	for cs in crossroads_signs:
		_create_wayfinding_post(civic_holder, cs["pos"], cs["text"], cs["color"])

func _create_wayfinding_post(parent: Node3D, pos: Vector3, label_text: String, col: Color) -> void:
	var post = MeshInstance3D.new()
	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.09
	post_mesh.bottom_radius = 0.10
	post_mesh.height = 3.2
	post.mesh = post_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.24, 0.26, 1.0)
	mat.roughness = 0.7
	post.set_surface_override_material(0, mat)
	parent.add_child(post)
	pos.y = 1.6
	post.global_position = pos

	var sign = Label3D.new()
	sign.text = label_text
	sign.font_size = 28
	sign.outline_size = 8
	sign.modulate = col
	sign.position = Vector3(0.0, 1.4, 0.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	post.add_child(sign)

func _generate_mindon_civic_landmarks() -> void:
	var landmark_holder = Node3D.new()
	landmark_holder.name = "MindonLandmarks"
	add_child(landmark_holder)

	# 1. Ward 3: Mindon Central Market (မင်းတုန်း မြို့မဈေးကြီး)
	var market_pos = Vector3(35.0, 0.0, 25.0)
	var stall1 = STALL_SCENE.instantiate()
	landmark_holder.add_child(stall1)
	stall1.global_position = market_pos + Vector3(-6.0, 0.0, 0.0)

	var stall2 = STALL_SCENE.instantiate()
	landmark_holder.add_child(stall2)
	stall2.global_position = market_pos + Vector3(6.0, 0.0, 0.0)

	var night_market = NIGHT_MARKET_SCENE.instantiate()
	landmark_holder.add_child(night_market)
	night_market.global_position = market_pos + Vector3(0.0, 0.0, 12.0)

	var teashop = TEASHOP_SCENE.instantiate()
	landmark_holder.add_child(teashop)
	teashop.global_position = market_pos + Vector3(-16.0, 0.0, 6.0)

	var guesthouse = GUESTHOUSE_SCENE.instantiate()
	landmark_holder.add_child(guesthouse)
	guesthouse.global_position = market_pos + Vector3(18.0, 0.0, 8.0)

	# 2. Ward 2: Mindon Basic Education High School (မင်းတုန်း အထက)
	var school_pos = Vector3(-195.0, 0.0, -110.0)
	var school = MONASTERY_SCENE.instantiate()
	landmark_holder.add_child(school)
	school.global_position = school_pos

	var pitch = PITCH_SCENE.instantiate()
	landmark_holder.add_child(pitch)
	pitch.global_position = school_pos + Vector3(32.0, 0.0, 15.0)

	var bell = BELL_SCENE.instantiate()
	landmark_holder.add_child(bell)
	bell.global_position = school_pos + Vector3(-14.0, 0.0, 6.0)

	# 3. Ward 4: Mindon Creek Waterfront & Historic Bamboo Bridge
	var river_pier = PIER_SCENE.instantiate()
	landmark_holder.add_child(river_pier)
	river_pier.global_position = Vector3(18.0, 0.0, 65.0)

	var rowboat = BOAT_SCENE.instantiate()
	landmark_holder.add_child(rowboat)
	rowboat.global_position = Vector3(18.5, -0.2, 72.0)

	var bridge = BRIDGE_SCENE.instantiate()
	landmark_holder.add_child(bridge)
	bridge.global_position = Vector3(-45.0, 0.0, 55.0)

	# 4. Ward 4: Shwe Mindon Hilltop Golden Pagoda (ရွှေမင်းတုန်း စေတီတော်မြတ်ကြီး)
	var pagoda_pos = Vector3(45.0, 0.0, 185.0)
	var pagoda = PAGODA_SCENE.instantiate()
	landmark_holder.add_child(pagoda)
	pagoda.global_position = pagoda_pos

	var pagoda_sign = Label3D.new()
	pagoda_sign.text = "ရွှေမင်းတုန်း စေတီတော်မြတ်ကြီး\n(Shwe Mindon Golden Pagoda)"
	pagoda_sign.font_size = 36
	pagoda_sign.outline_size = 10
	pagoda_sign.modulate = Color(1.0, 0.84, 0.15, 1.0)
	pagoda_sign.position = pagoda_pos + Vector3(0.0, 22.0, 0.0)
	pagoda_sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	landmark_holder.add_child(pagoda_sign)

func _generate_mindon_buildings(buildings: Array) -> void:
	var building_holder = Node3D.new()
	building_holder.name = "MindonBuildings"
	add_child(building_holder)

	var hospital_wall_mat = StandardMaterial3D.new()
	hospital_wall_mat.albedo_color = Color(0.92, 0.94, 0.95, 1.0)
	hospital_wall_mat.roughness = 0.75

	var hospital_roof_mat = StandardMaterial3D.new()
	hospital_roof_mat.albedo_color = Color(0.22, 0.42, 0.65, 1.0)
	hospital_roof_mat.roughness = 0.35
	hospital_roof_mat.metallic = 0.4

	var cross_mat = StandardMaterial3D.new()
	cross_mat.albedo_color = Color(0.9, 0.1, 0.1, 1.0)
	cross_mat.emission_enabled = true
	cross_mat.emission = Color(0.9, 0.1, 0.1, 1.0)
	cross_mat.emission_energy_multiplier = 1.5

	var hosp_idx = 0
	for b in buildings:
		var pts = b.get("pts", [])
		if pts.is_empty():
			continue

		var cx = 0.0
		var cz = 0.0
		var min_x = 99999.0
		var max_x = -99999.0
		var min_z = 99999.0
		var max_z = -99999.0
		for p in pts:
			cx += p["x"]
			cz += p["z"]
			if p["x"] < min_x: min_x = p["x"]
			if p["x"] > max_x: max_x = p["x"]
			if p["z"] < min_z: min_z = p["z"]
			if p["z"] > max_z: max_z = p["z"]
		cx /= float(pts.size())
		cz /= float(pts.size())

		var b_width = maxf(max_x - min_x, 6.0)
		var b_depth = maxf(max_z - min_z, 6.0)

		var b_type = str(b.get("type", "house"))
		if b_type == "hospital":
			var hosp = StaticBody3D.new()
			hosp_idx += 1
			hosp.name = "MindonHospitalBuilding_%d" % hosp_idx

			var col = CollisionShape3D.new()
			var col_box = BoxShape3D.new()
			col_box.size = Vector3(b_width + 0.6, 6.8, b_depth + 0.6)
			col.shape = col_box
			col.position = Vector3(0.0, 3.4, 0.0)
			hosp.add_child(col)

			var body_mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(b_width, 6.2, b_depth)
			body_mesh.mesh = box
			body_mesh.position = Vector3(0.0, 3.1, 0.0)
			body_mesh.set_surface_override_material(0, hospital_wall_mat)
			hosp.add_child(body_mesh)

			var roof_mesh = MeshInstance3D.new()
			var roof_box = BoxMesh.new()
			roof_box.size = Vector3(b_width + 1.2, 0.8, b_depth + 1.2)
			roof_mesh.mesh = roof_box
			roof_mesh.position = Vector3(0.0, 6.6, 0.0)
			roof_mesh.set_surface_override_material(0, hospital_roof_mat)
			hosp.add_child(roof_mesh)

			var sign = Label3D.new()
			sign.text = "မင်းတုန်းမြို့နယ် ပြည်သူ့ဆေးရုံကြီး 🏥"
			sign.font_size = 34
			sign.outline_size = 10
			sign.modulate = Color(0.15, 0.45, 0.85, 1.0)
			sign.position = Vector3(0.0, 5.6, b_depth * 0.5 + 0.1)
			hosp.add_child(sign)

			building_holder.add_child(hosp)
			hosp.global_position = Vector3(cx, 0.0, cz)

func _generate_mindon_rivers(rivers: Array) -> void:
	var river_holder = Node3D.new()
	river_holder.name = "MindonStreamRiver"
	add_child(river_holder)

	var river_mat = ShaderMaterial.new()
	river_mat.shader = RIVER_SHADER

	for riv in rivers:
		var pts = riv.get("pts", [])
		if pts.size() < 2:
			continue

		for i in range(pts.size() - 1):
			var p1 = Vector3(pts[i]["x"], -0.15, pts[i]["z"])
			var p2 = Vector3(pts[i + 1]["x"], -0.15, pts[i + 1]["z"])
			var dist = p1.distance_to(p2)
			if dist < 0.5 or dist > 450.0:
				continue

			var mesh_inst = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(26.0, 0.45, dist)
			mesh_inst.mesh = box
			mesh_inst.set_surface_override_material(0, river_mat)

			var mid = (p1 + p2) * 0.5
			var forward = (p2 - p1).normalized()
			river_holder.add_child(mesh_inst)
			mesh_inst.global_position = mid
			mesh_inst.look_at(mid + forward, Vector3.UP)

func _generate_vast_paddy_terraces_and_farms() -> void:
	var farm_holder = Node3D.new()
	farm_holder.name = "MindonFarmsAndPaddies"
	add_child(farm_holder)

	var paddy_centers = [
		Vector3(120.0, 0.0, 95.0),
		Vector3(160.0, 0.0, 140.0),
		Vector3(-140.0, 0.0, 45.0),
		Vector3(-85.0, 0.0, -180.0),
		Vector3(95.0, 0.0, -190.0)
	]

	for pos in paddy_centers:
		var paddy = PADDY_SCENE.instantiate()
		farm_holder.add_child(paddy)
		paddy.global_position = pos


func _generate_mindon_airfield() -> void:
	var airfield_holder = Node3D.new()
	airfield_holder.name = "MindonAirfieldAndHelipad"
	add_child(airfield_holder)

	var runway_center = Vector3(280.0, 0.05, -220.0)
	var runway_length = 160.0
	var runway_width = 16.0

	# 1. Main Asphalt Runway Surface
	var runway_mat = StandardMaterial3D.new()
	runway_mat.albedo_color = Color(0.18, 0.19, 0.20, 1.0)
	runway_mat.roughness = 0.82
	var runway_mesh = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(runway_width, 0.1, runway_length)
	runway_mesh.mesh = r_box
	runway_mesh.set_surface_override_material(0, runway_mat)
	runway_mesh.global_position = runway_center
	airfield_holder.add_child(runway_mesh)

	# 2. Runway Centerline Dashed Markings
	var stripe_mat = StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.96, 0.96, 0.98, 1.0)
	stripe_mat.roughness = 0.5
	stripe_mat.emission_enabled = true
	stripe_mat.emission = Color(0.96, 0.96, 0.98, 1.0)
	stripe_mat.emission_energy_multiplier = 0.4

	for i in range(-6, 7):
		var stripe = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.6, 0.12, 6.0)
		stripe.mesh = s_box
		stripe.set_surface_override_material(0, stripe_mat)
		stripe.global_position = runway_center + Vector3(0.0, 0.06, i * 11.5)
		airfield_holder.add_child(stripe)

	# 3. Runway Threshold Heading Numbers & Boundary Lines
	var south_label = Label3D.new()
	south_label.text = "12"
	south_label.font_size = 48
	south_label.outline_size = 12
	south_label.modulate = Color(0.96, 0.96, 0.98, 1.0)
	south_label.rotation.x = deg_to_rad(-90.0)
	south_label.position = runway_center + Vector3(0.0, 0.12, 65.0)
	airfield_holder.add_child(south_label)

	var north_label = Label3D.new()
	north_label.text = "30"
	north_label.font_size = 48
	north_label.outline_size = 12
	north_label.modulate = Color(0.96, 0.96, 0.98, 1.0)
	north_label.rotation.x = deg_to_rad(-90.0)
	north_label.rotation.y = deg_to_rad(180.0)
	north_label.position = runway_center + Vector3(0.0, 0.12, -65.0)
	airfield_holder.add_child(north_label)

	# 4. Orange Runway Boundary Marker Cones
	var cone_mat = StandardMaterial3D.new()
	cone_mat.albedo_color = Color(0.98, 0.45, 0.08, 1.0)
	cone_mat.roughness = 0.6
	for j in range(-7, 8):
		var cone_z = runway_center.z + (j * 10.0)
		for side in [-1.0, 1.0]:
			var cone = MeshInstance3D.new()
			var c_mesh = CylinderMesh.new()
			c_mesh.top_radius = 0.08
			c_mesh.bottom_radius = 0.28
			c_mesh.height = 0.65
			cone.mesh = c_mesh
			cone.set_surface_override_material(0, cone_mat)
			cone.global_position = Vector3(runway_center.x + (side * (runway_width * 0.5 + 0.8)), 0.32, cone_z)
			airfield_holder.add_child(cone)

	# 5. Concrete Helipad Apron centered under Helicopter (220, 0, -180)
	var heli_center = Vector3(220.0, 0.05, -180.0)
	var pad_mat = StandardMaterial3D.new()
	pad_mat.albedo_color = Color(0.32, 0.33, 0.35, 1.0)
	pad_mat.roughness = 0.88
	var pad_mesh = MeshInstance3D.new()
	var pad_box = BoxMesh.new()
	pad_box.size = Vector3(22.0, 0.1, 22.0)
	pad_mesh.mesh = pad_box
	pad_mesh.set_surface_override_material(0, pad_mat)
	pad_mesh.global_position = heli_center
	airfield_holder.add_child(pad_mesh)

	# Helipad Yellow "H" Marking
	var h_label = Label3D.new()
	h_label.text = "H"
	h_label.font_size = 96
	h_label.outline_size = 18
	h_label.modulate = Color(1.0, 0.85, 0.12, 1.0)
	h_label.rotation.x = deg_to_rad(-90.0)
	h_label.position = heli_center + Vector3(0.0, 0.12, 0.0)
	airfield_holder.add_child(h_label)

	# 6. Airfield Windsock Mast
	var windsock_pos = Vector3(248.0, 0.0, -198.0)
	var mast = MeshInstance3D.new()
	var mast_mesh = CylinderMesh.new()
	mast_mesh.top_radius = 0.08
	mast_mesh.bottom_radius = 0.12
	mast_mesh.height = 6.5
	mast.mesh = mast_mesh
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.85, 0.88, 0.90, 1.0)
	steel_mat.metallic = 0.85
	mast.set_surface_override_material(0, steel_mat)
	mast.global_position = windsock_pos + Vector3(0.0, 3.25, 0.0)
	airfield_holder.add_child(mast)

	var sock = MeshInstance3D.new()
	var sock_mesh = CylinderMesh.new()
	sock_mesh.top_radius = 0.40
	sock_mesh.bottom_radius = 0.18
	sock_mesh.height = 2.4
	sock.mesh = sock_mesh
	var sock_mat = StandardMaterial3D.new()
	sock_mat.albedo_color = Color(0.92, 0.22, 0.12, 1.0)
	sock.set_surface_override_material(0, sock_mat)
	sock.rotation.z = deg_to_rad(75.0)
	sock.position = Vector3(1.1, 2.8, 0.0)
	mast.add_child(sock)

	# 7. Airfield Entrance Wayfinding Signpost
	var sign_pos = Vector3(210.0, 0.0, -155.0)
	_create_wayfinding_post(airfield_holder, sign_pos, "မင်းတုန်း ဒေသန္တရ လေယာဉ်ကွင်း\n(Mindon Countryside Airfield ✈️🚁)", Color(0.2, 0.9, 0.4, 1.0))

func _generate_mindon_district_vehicles_and_mounts() -> void:
	var veh_holder = Node3D.new()
	veh_holder.name = "MindonDistrictVehicles"
	add_child(veh_holder)

	# 1. Authentic Bullock Carts (နွားလှည်းများ) at market, strand road & farmsteads
	var cart_spawns = [
		{"pos": Vector3(48.0, 0.0, 22.0), "rot": deg_to_rad(15.0)},   # Ward 3 Bazaar loading zone
		{"pos": Vector3(26.0, 0.0, 64.0), "rot": deg_to_rad(-30.0)},  # Ward 4 Strand Road riverside pier
		{"pos": Vector3(110.0, 0.0, -170.0), "rot": deg_to_rad(65.0)},# Ward 1 Farmstead
		{"pos": Vector3(-135.0, 0.0, 42.0), "rot": deg_to_rad(90.0)}  # West Paddy Field dirt lane
	]
	for cs in cart_spawns:
		var cart = BULLOCK_CART_SCENE.instantiate()
		veh_holder.add_child(cart)
		cart.global_position = cs["pos"]
		cart.rotation.y = cs["rot"]

	# 2. Authentic Rideable Cows & Oxen (နွားများ) in pastures, wells & creek banks
	var cow_spawns = [
		{"pos": Vector3(88.0, 0.0, -182.0), "rot": deg_to_rad(45.0)},  # Ward 1 Village well pasture
		{"pos": Vector3(-22.0, 0.0, 78.0), "rot": deg_to_rad(110.0)},  # Ward 4 Mindon creek riverside meadow
		{"pos": Vector3(148.0, 0.0, 118.0), "rot": deg_to_rad(-20.0)}, # East Farmstead paddy meadow
		{"pos": Vector3(-68.0, 0.0, -162.0), "rot": deg_to_rad(-75.0)} # Central Monastic grounds
	]
	for cow_s in cow_spawns:
		var cow = COW_SCENE.instantiate()
		veh_holder.add_child(cow)
		cow.global_position = cow_s["pos"]
		cow.rotation.y = cow_s["rot"]

	# 3. Authentic Myanmar Motorcycles (ဆိုင်ကယ်များ) parked at key town locations
	var bike_spawns = [
		{"pos": Vector3(17.0, 0.2, 27.0), "rot": deg_to_rad(-40.0)},  # Ward 3 Central Market tea shop
		{"pos": Vector3(-176.0, 0.2, -96.0), "rot": deg_to_rad(80.0)},# Ward 2 High School gate
		{"pos": Vector3(66.0, 0.2, -14.0), "rot": deg_to_rad(10.0)},  # Ward 3 General Hospital entrance
		{"pos": Vector3(-36.0, 0.2, 46.0), "rot": deg_to_rad(-120.0)} # Ward 4 Strand Road near bamboo bridge
	]
	for bs in bike_spawns:
		var bike = MOTORCYCLE_SCENE.instantiate()
		veh_holder.add_child(bike)
		bike.global_position = bs["pos"]
		bike.rotation.y = bs["rot"]

	# 4. Authentic Myanmar Tuk-Tuks (သုံးဘီး ဆိုင်ကယ်များ)
	var tuktuk_spawns = [
		{"pos": Vector3(44.0, 0.2, 36.0), "rot": deg_to_rad(-90.0)},  # Ward 3 Central Market passenger queue
		{"pos": Vector3(56.0, 0.2, -22.0), "rot": deg_to_rad(35.0)}   # Ward 3 Hospital taxi queue
	]
	for ts in tuktuk_spawns:
		var tuktuk = TUKTUK_SCENE.instantiate()
		veh_holder.add_child(tuktuk)
		tuktuk.global_position = ts["pos"]
		tuktuk.rotation.y = ts["rot"]
