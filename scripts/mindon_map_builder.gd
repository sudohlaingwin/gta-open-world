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

func _generate_mindon_roads(roads: Array) -> void:
	var road_holder = Node3D.new()
	road_holder.name = "MindonRoads"
	add_child(road_holder)

	var asphalt_mat = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.24, 0.25, 0.27, 1.0)
	asphalt_mat.roughness = 0.88
	var asphalt_noise = FastNoiseLite.new()
	asphalt_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	asphalt_noise.frequency = 0.08
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = asphalt_noise
	noise_tex.as_normal_map = true
	noise_tex.bump_strength = 0.8
	asphalt_mat.normal_enabled = true
	asphalt_mat.normal_texture = noise_tex

	var earth_mat = StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.48, 0.38, 0.26, 1.0)
	earth_mat.roughness = 0.95

	var curb_mat = StandardMaterial3D.new()
	curb_mat.albedo_color = Color(0.65, 0.64, 0.62, 1.0)
	curb_mat.roughness = 0.8

	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.96, 0.86, 0.22, 1.0)
	line_mat.roughness = 0.4
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.92, 0.80, 0.18, 1.0)
	line_mat.emission_energy_multiplier = 0.4

	for r in roads:
		var pts = r.get("pts", [])
		if pts.size() < 2:
			continue

		var r_type = str(r.get("type", "residential"))
		var road_width: float = 9.2 if r_type == "unclassified" else (5.8 if r_type == "residential" else 4.2)
		var mat = asphalt_mat if r_type == "unclassified" else earth_mat

		for i in range(pts.size() - 1):
			var p1 = Vector3(pts[i]["x"], 0.06, pts[i]["z"])
			var p2 = Vector3(pts[i + 1]["x"], 0.06, pts[i + 1]["z"])
			var dist = p1.distance_to(p2)
			if dist < 0.4 or dist > 220.0:
				continue

			var mesh_inst = MeshInstance3D.new()
			var quad = BoxMesh.new()
			quad.size = Vector3(road_width, 0.08, dist)
			mesh_inst.mesh = quad
			mesh_inst.set_surface_override_material(0, mat)

			var mid_point = (p1 + p2) * 0.5
			var forward = (p2 - p1).normalized()
			road_holder.add_child(mesh_inst)
			mesh_inst.global_position = mid_point
			mesh_inst.look_at(mid_point + forward, Vector3.UP)

			# Highway curbs and dashed center markings along Pyay-Mindon Highway
			if r_type == "unclassified":
				var right_dir = forward.cross(Vector3.UP).normalized()
				var curb_box = BoxMesh.new()
				curb_box.size = Vector3(0.4, 0.18, dist)

				var curb_l = MeshInstance3D.new()
				curb_l.mesh = curb_box
				curb_l.set_surface_override_material(0, curb_mat)
				road_holder.add_child(curb_l)
				curb_l.global_position = mid_point - right_dir * (road_width * 0.5 + 0.2)
				curb_l.look_at(curb_l.global_position + forward, Vector3.UP)

				var curb_r = MeshInstance3D.new()
				curb_r.mesh = curb_box
				curb_r.set_surface_override_material(0, curb_mat)
				road_holder.add_child(curb_r)
				curb_r.global_position = mid_point + right_dir * (road_width * 0.5 + 0.2)
				curb_r.look_at(curb_r.global_position + forward, Vector3.UP)

				# Center dashed yellow stripe
				if i % 2 == 0 and dist >= 1.5:
					var stripe = MeshInstance3D.new()
					var stripe_mesh = BoxMesh.new()
					stripe_mesh.size = Vector3(0.28, 0.09, minf(dist * 0.65, 3.8))
					stripe.mesh = stripe_mesh
					stripe.set_surface_override_material(0, line_mat)
					road_holder.add_child(stripe)
					stripe.global_position = mid_point + Vector3(0, 0.01, 0)
					stripe.look_at(stripe.global_position + forward, Vector3.UP)

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
