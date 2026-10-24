extends Node3D

# --- Mindon Township Ward 3 Real-World GIS Procedural Generator ---
# Exact Center: 19.351497 N, 94.731889 E (Mindon, Magway Region, Myanmar)
# Generates real-world roads, buildings (Ward 3 hospital, residential houses),
# native tropical roadside vegetation (Toddy palms, banana plants), and Mindon stream (မင်းတုန်းချောင်း)

const HOUSE_SCENE = preload("res://scenes/myanmar_house.tscn")
const PALM_SCENE = preload("res://scenes/toddy_palm.tscn")
const BANANA_SCENE = preload("res://scenes/banana_plant.tscn")
const ZAYAT_SCENE = preload("res://scenes/myanmar_zayat.tscn")
const FESTIVAL_SCENE = preload("res://scenes/festival_ground.tscn")
const POT_SCENE = preload("res://scenes/water_pot_stand.tscn")
const WELL_SCENE = preload("res://scenes/village_well.tscn")
const VILLAGE_GATE_SCENE = preload("res://scenes/village_gate.tscn")
const PADDY_SCENE = preload("res://scenes/myanmar_paddy_field.tscn")
const PAGODA_SCENE = preload("res://scenes/myanmar_pagoda.tscn")
const PIER_SCENE = preload("res://scenes/river_boat_pier.tscn")
const BOAT_SCENE = preload("res://scenes/ayeyarwady_rowboat.tscn")
const BRIDGE_SCENE = preload("res://scenes/bamboo_bridge.tscn")
const WOODEN_BRIDGE_SCENE = preload("res://scenes/wooden_stream_bridge.tscn")
const TEASHOP_SCENE = preload("res://scenes/myanmar_teashop.tscn")
const STALL_SCENE = preload("res://scenes/market_stall.tscn")
const PEDESTRIAN_SCENE = preload("res://scenes/ambient_pedestrian.tscn")
const FIREFLIES_SCENE = preload("res://scenes/village_fireflies.tscn")
const HINTHAR_SCENE = preload("res://scenes/hinthar_statue.tscn")
const PITCH_SCENE = preload("res://scenes/football_pitch.tscn")
const BELL_SCENE = preload("res://scenes/monastery_bell.tscn")
const MONASTERY_SCENE = preload("res://scenes/monastery_school.tscn")
const CART_SCENE = preload("res://scenes/bullock_cart.tscn")
const NIGHT_MARKET_SCENE = preload("res://scenes/myanmar_night_market.tscn")
const GUESTHOUSE_SCENE = preload("res://scenes/myanmar_guesthouse.tscn")
const RIVER_SHADER = preload("res://scripts/water_river.gdshader")
const AIRDROP_SCENE = preload("res://scenes/airdrop_crate.tscn")

func _ready() -> void:
	var file = FileAccess.open("res://mindon_geo_data.json", FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return

	var data = json.data
	_generate_mindon_roads(data.get("roads", []))
	_generate_mindon_buildings(data.get("buildings", []))
	_generate_mindon_rivers(data.get("rivers", []))
	_generate_ward3_amenities()
	_generate_countryside_exploration_routes()
	_generate_grand_union_highway()
	_generate_scenic_riverside_loop()
	_generate_mountain_pass_viewpoints()
	_generate_distant_mountain_horizons()
	_generate_vast_paddy_terraces_and_farms()
	_generate_airdrop_supply_drops()
	_generate_highway_milestone_posts()

func _generate_countryside_exploration_routes() -> void:
	# Sprawling countryside gravel & dirt exploration trails connecting village to hills and streams
	var routes_holder = Node3D.new()
	routes_holder.name = "CountrysideExplorationTrails"
	add_child(routes_holder)

	var dirt_trail_mat = StandardMaterial3D.new()
	dirt_trail_mat.albedo_color = Color(0.46, 0.38, 0.26, 1.0)
	dirt_trail_mat.roughness = 0.94

	# 4 Primary exploration trails winding out across the rolling terrain (North, East, South, West)
	var trail_directions = [
		Vector2(0.0, 1.0),    # South into foothills
		Vector2(1.0, 0.2),    # East towards Ayeyarwady basin
		Vector2(-0.8, -0.6),  # Northwest mountain pass
		Vector2(0.3, -1.0)    # North valley crossing
	]

	for trail_idx in range(trail_directions.size()):
		var base_dir = trail_directions[trail_idx].normalized()
		var start_pos = Vector2(-20.0, 40.0) + base_dir * 120.0
		var current_pos = start_pos
		var trail_segments = 35 # ~1200m each trail
		var segment_len = 35.0

		for s in range(trail_segments):
			var angle_offset = sin(float(s) * 0.45 + float(trail_idx) * 1.5) * 0.4
			var seg_dir = base_dir.rotated(angle_offset).normalized()
			var next_pos = current_pos + seg_dir * segment_len

			var p1 = Vector3(current_pos.x, 0.05, current_pos.y)
			var p2 = Vector3(next_pos.x, 0.05, next_pos.y)
			var dist = p1.distance_to(p2)

			var mesh_inst = MeshInstance3D.new()
			var quad = BoxMesh.new()
			quad.size = Vector3(5.2, 0.06, dist)
			mesh_inst.mesh = quad
			mesh_inst.set_surface_override_material(0, dirt_trail_mat)

			var mid_point = (p1 + p2) * 0.5
			var forward = (p2 - p1).normalized()
			routes_holder.add_child(mesh_inst)
			mesh_inst.global_position = mid_point
			mesh_inst.look_at(mid_point + forward, Vector3.UP)

			# Scatter roadside waystones and toddy palms along trail
			if s % 5 == 0:
				var palm = PALM_SCENE.instantiate()
				routes_holder.add_child(palm)
				var side_offset = forward.cross(Vector3.UP).normalized() * (4.2 + (s % 3) * 1.5)
				palm.global_position = mid_point + side_offset
				palm.scale = Vector3(1.4, 1.4, 1.4)

			current_pos = next_pos


func _generate_mindon_roads(roads: Array) -> void:
	var road_holder = Node3D.new()
	road_holder.name = "MindonRoads"
	add_child(road_holder)

	var asphalt_mat = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.24, 0.25, 0.27, 1.0)
	asphalt_mat.roughness = 0.92
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
	earth_mat.albedo_color = Color(0.48, 0.39, 0.28, 1.0)
	earth_mat.roughness = 1.0

	var curb_mat = StandardMaterial3D.new()
	curb_mat.albedo_color = Color(0.65, 0.64, 0.62, 1.0)
	curb_mat.roughness = 0.8

	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.95, 0.85, 0.2, 1.0)
	line_mat.roughness = 0.5
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.85, 0.75, 0.15, 1.0)
	line_mat.emission_energy_multiplier = 0.3

	var palm_count = 0
	var banana_count = 0

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
			if dist < 0.4 or dist > 200.0:
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

			# Road curbs and dashed center markings along paved unclassified highway
			if r_type == "unclassified":
				# Left Curb
				var curb_l = MeshInstance3D.new()
				var curb_box = BoxMesh.new()
				curb_box.size = Vector3(0.4, 0.18, dist)
				curb_l.mesh = curb_box
				curb_l.set_surface_override_material(0, curb_mat)
				var right_dir = forward.cross(Vector3.UP).normalized()
				road_holder.add_child(curb_l)
				curb_l.global_position = mid_point - right_dir * (road_width * 0.5 + 0.2)
				curb_l.look_at(curb_l.global_position + forward, Vector3.UP)

				# Right Curb
				var curb_r = MeshInstance3D.new()
				curb_r.mesh = curb_box
				curb_r.set_surface_override_material(0, curb_mat)
				road_holder.add_child(curb_r)
				curb_r.global_position = mid_point + right_dir * (road_width * 0.5 + 0.2)
				curb_r.look_at(curb_r.global_position + forward, Vector3.UP)

				# Dashed yellow lane divider stripe
				if i % 2 == 0 and dist >= 1.5:
					var stripe = MeshInstance3D.new()
					var stripe_mesh = BoxMesh.new()
					stripe_mesh.size = Vector3(0.28, 0.09, minf(dist * 0.6, 3.8))
					stripe.mesh = stripe_mesh
					stripe.set_surface_override_material(0, line_mat)
					road_holder.add_child(stripe)
					stripe.global_position = mid_point + Vector3(0, 0.01, 0)
					stripe.look_at(stripe.global_position + forward, Vector3.UP)

			# Plant roadside authentic vegetation along real road shoulders
			if i % 3 == 0 and palm_count < 90:
				var right_dir = forward.cross(Vector3.UP).normalized()
				var side_mult = 1.0 if (i % 2 == 0) else -1.0
				var palm_pos = mid_point + right_dir * (road_width * 0.5 + 2.4 * side_mult)
				palm_pos.y = 0.0
				
				var palm = PALM_SCENE.instantiate()
				road_holder.add_child(palm)
				palm.global_position = palm_pos
				palm_count += 1

			if i % 4 == 1 and banana_count < 70:
				var right_dir = forward.cross(Vector3.UP).normalized()
				var side_mult = -1.0 if (i % 2 == 0) else 1.0
				var banana_pos = mid_point + right_dir * (road_width * 0.5 + 1.8 * side_mult)
				banana_pos.y = 0.0

				var banana = BANANA_SCENE.instantiate()
				road_holder.add_child(banana)
				banana.global_position = banana_pos
				banana_count += 1

func _generate_mindon_buildings(buildings: Array) -> void:
	var building_holder = Node3D.new()
	building_holder.name = "MindonBuildings"
	add_child(building_holder)

	var hospital_wall_mat = StandardMaterial3D.new()
	hospital_wall_mat.albedo_color = Color(0.92, 0.94, 0.95, 1.0)
	hospital_wall_mat.roughness = 0.75
	var stucco_noise = FastNoiseLite.new()
	stucco_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	stucco_noise.frequency = 0.12
	var stucco_tex = NoiseTexture2D.new()
	stucco_tex.noise = stucco_noise
	stucco_tex.as_normal_map = true
	stucco_tex.bump_strength = 0.6
	hospital_wall_mat.normal_enabled = true
	hospital_wall_mat.normal_texture = stucco_tex

	var hospital_roof_mat = StandardMaterial3D.new()
	hospital_roof_mat.albedo_color = Color(0.22, 0.42, 0.65, 1.0)
	hospital_roof_mat.roughness = 0.35
	hospital_roof_mat.metallic = 0.4

	var window_glass_mat = StandardMaterial3D.new()
	window_glass_mat.albedo_color = Color(0.18, 0.32, 0.45, 0.9)
	window_glass_mat.roughness = 0.15
	window_glass_mat.metallic = 0.3

	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.15, 0.22, 0.28, 1.0)
	frame_mat.roughness = 0.6

	var cross_mat = StandardMaterial3D.new()
	cross_mat.albedo_color = Color(0.9, 0.1, 0.1, 1.0)
	cross_mat.emission_enabled = true
	cross_mat.emission = Color(0.9, 0.1, 0.1, 1.0)
	cross_mat.emission_energy_multiplier = 1.5

	var hosp_idx = 0
	var house_idx = 0
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
			# Mindon Township General Hospital (မင်းတုန်းမြို့နယ် ပြည်သူ့ဆေးရုံ) compound buildings
			var hosp = StaticBody3D.new()
			hosp_idx += 1
			hosp.name = "MindonHospitalBuilding" if hosp_idx == 1 else ("MindonHospitalBuilding_%d" % hosp_idx)

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

			# Red Cross symbol and hospital signboard on facade
			var front_z = (b_depth * 0.5) + 0.08
			var b_cross_mat = cross_mat.duplicate()
			var cross_v = MeshInstance3D.new()
			cross_v.name = "CrossV"
			var cv_mesh = BoxMesh.new()
			cv_mesh.size = Vector3(0.45, 1.8, 0.1)
			cross_v.mesh = cv_mesh
			cross_v.position = Vector3(0.0, 4.4, front_z)
			cross_v.set_surface_override_material(0, b_cross_mat)
			hosp.add_child(cross_v)

			var cross_h = MeshInstance3D.new()
			cross_h.name = "CrossH"
			var ch_mesh = BoxMesh.new()
			ch_mesh.size = Vector3(1.5, 0.5, 0.1)
			cross_h.mesh = ch_mesh
			cross_h.position = Vector3(0.0, 4.4, front_z)
			cross_h.set_surface_override_material(0, b_cross_mat)
			hosp.add_child(cross_h)

			# Hospital entrance porch canopy & columns
			var canopy = MeshInstance3D.new()
			var canopy_mesh = BoxMesh.new()
			canopy_mesh.size = Vector3(4.8, 0.35, 2.8)
			canopy.mesh = canopy_mesh
			canopy.position = Vector3(0.0, 3.8, front_z + 1.3)
			canopy.set_surface_override_material(0, hospital_roof_mat)
			hosp.add_child(canopy)

			for pillar_x in [-2.1, 2.1]:
				var pillar = MeshInstance3D.new()
				var pillar_mesh = BoxMesh.new()
				pillar_mesh.size = Vector3(0.3, 3.8, 0.3)
				pillar.mesh = pillar_mesh
				pillar.position = Vector3(pillar_x, 1.9, front_z + 2.5)
				pillar.set_surface_override_material(0, frame_mat)
				hosp.add_child(pillar)

			# Glazed windows on building front
			var win_offset_x = (b_width * 0.5) * 0.55
			for wx in [-win_offset_x, win_offset_x]:
				var win = MeshInstance3D.new()
				var win_mesh = BoxMesh.new()
				win_mesh.size = Vector3(2.2, 1.8, 0.12)
				win.mesh = win_mesh
				win.position = Vector3(wx, 3.2, front_z)
				win.set_surface_override_material(0, window_glass_mat)
				hosp.add_child(win)

				var win_frame = MeshInstance3D.new()
				var win_fmesh = BoxMesh.new()
				win_fmesh.size = Vector3(2.35, 1.95, 0.08)
				win_frame.mesh = win_fmesh
				win_frame.position = Vector3(wx, 3.2, front_z - 0.02)
				win_frame.set_surface_override_material(0, frame_mat)
				hosp.add_child(win_frame)

			var sign = Label3D.new()
			sign.text = "မင်းတုန်းမြို့နယ် ပြည်သူ့ဆေးရုံ"
			sign.font_size = 36
			sign.outline_size = 10
			sign.modulate = Color(0.15, 0.45, 0.85, 1.0)
			sign.position = Vector3(0.0, 5.6, front_z + 0.05)
			hosp.add_child(sign)

			# Attach automated day/night lantern controller and porch lantern
			var porch_light = OmniLight3D.new()
			porch_light.name = "HospitalPorchLight"
			porch_light.light_color = Color(1.0, 0.92, 0.82, 1.0)
			porch_light.light_energy = 2.6 if hosp_idx == 1 else 1.8
			porch_light.omni_range = 24.0 if hosp_idx == 1 else 16.0
			porch_light.position = Vector3(0.0, 4.2, front_z + 0.8)
			hosp.add_child(porch_light)

			var hosp_lantern = preload("res://scripts/village_lantern_controller.gd").new()
			hosp.add_child(hosp_lantern)

			building_holder.add_child(hosp)
			hosp.global_position = Vector3(cx, 0.0, cz)
		else:
			# Myanmar teak & bamboo elevated residential home
			var house = HOUSE_SCENE.instantiate()
			house_idx += 1
			house.name = "MyanmarHouse_%d" % house_idx

			# Architectural upgrade: add authentic wooden window shutters and eave fascias
			var visual = house.get_node_or_null("VisualMesh")
			if visual:
				var wood_mat = StandardMaterial3D.new()
				wood_mat.albedo_color = Color(0.38, 0.22, 0.12, 1.0)
				wood_mat.roughness = 0.85

				var shutter_mat = StandardMaterial3D.new()
				shutter_mat.albedo_color = Color(0.28, 0.16, 0.08, 1.0)
				shutter_mat.roughness = 0.9

				# Front window with traditional Burmese hinged shutters
				var win_mesh = BoxMesh.new()
				win_mesh.size = Vector3(1.1, 1.1, 0.08)
				var win_inst = MeshInstance3D.new()
				win_inst.mesh = win_mesh
				win_inst.position = Vector3(0.5, 2.2, 2.92)
				win_inst.set_surface_override_material(0, wood_mat)
				visual.add_child(win_inst)

				# Open wooden shutter wings
				var shutter_l = MeshInstance3D.new()
				var shutter_mesh = BoxMesh.new()
				shutter_mesh.size = Vector3(0.5, 1.0, 0.04)
				shutter_l.mesh = shutter_mesh
				shutter_l.position = Vector3(-0.1, 2.2, 2.96)
				shutter_l.rotation = Vector3(0, deg_to_rad(45.0), 0)
				shutter_l.set_surface_override_material(0, shutter_mat)
				visual.add_child(shutter_l)

				var shutter_r = MeshInstance3D.new()
				shutter_r.mesh = shutter_mesh
				shutter_r.position = Vector3(1.1, 2.2, 2.96)
				shutter_r.rotation = Vector3(0, deg_to_rad(-45.0), 0)
				shutter_r.set_surface_override_material(0, shutter_mat)
				visual.add_child(shutter_r)

				# Roof carved eave overhang trim (နန်းတွင်း/ရိုးရာ အမိုးအနားသတ်)
				var eave = MeshInstance3D.new()
				var eave_mesh = BoxMesh.new()
				eave_mesh.size = Vector3(6.6, 0.12, 6.8)
				eave.mesh = eave_mesh
				eave.position = Vector3(0.0, 3.32, 0.0)
				eave.set_surface_override_material(0, wood_mat)
				visual.add_child(eave)

			# Authentic 1:1 Real-Scale Myanmar Teak & Stilt House (ကလေးကစားစရာအရုပ်မဟုတ်စေရန် အချိုးအစားမှန် 2.2x စကေးအပြည့်ချဲ့ခြင်း)
			house.scale = Vector3(2.2, 2.2, 2.2)
			building_holder.add_child(house)
			house.global_position = Vector3(cx, 0.0, cz)

func _generate_mindon_rivers(rivers: Array) -> void:
	var river_holder = Node3D.new()
	river_holder.name = "MindonStream"
	add_child(river_holder)

	var river_mat = ShaderMaterial.new()
	river_mat.shader = RIVER_SHADER

	for r in rivers:
		var pts = r.get("pts", [])
		if pts.size() < 2:
			continue

		for i in range(pts.size() - 1):
			var p1 = Vector3(pts[i]["x"], -0.3, pts[i]["z"])
			var p2 = Vector3(pts[i + 1]["x"], -0.3, pts[i + 1]["z"])
			var dist = p1.distance_to(p2)
			if dist < 1.0 or dist > 600.0:
				continue

			var river_width: float = 42.0
			var mesh_inst = MeshInstance3D.new()
			var water_box = BoxMesh.new()
			water_box.size = Vector3(river_width, 0.45, dist)
			mesh_inst.mesh = water_box
			mesh_inst.set_surface_override_material(0, river_mat)

			var mid_point = (p1 + p2) * 0.5
			var forward = (p2 - p1).normalized()
			river_holder.add_child(mesh_inst)
			mesh_inst.global_position = mid_point
			mesh_inst.look_at(mid_point + forward, Vector3.UP)

func _generate_ward3_amenities() -> void:
	# Add authentic village infrastructure at Mindon Ward 3 Hospital compound
	var amenities_holder = Node3D.new()
	amenities_holder.name = "Ward3Amenities"
	add_child(amenities_holder)

	var well = WELL_SCENE.instantiate()
	amenities_holder.add_child(well)
	well.global_position = Vector3(-65.0, 0.0, 115.0)

	var pot = POT_SCENE.instantiate()
	amenities_holder.add_child(pot)
	pot.global_position = Vector3(-48.0, 0.0, 122.0)

	var zayat = ZAYAT_SCENE.instantiate()
	amenities_holder.add_child(zayat)
	zayat.global_position = Vector3(-75.0, 0.0, 155.0)

	# Mindon Ward 3 Village Entrance Gate (ရွာဝင်မုခ်ဦး) across hospital access road
	var gate = VILLAGE_GATE_SCENE.instantiate()
	amenities_holder.add_child(gate)
	gate.global_position = Vector3(-12.0, 0.0, 78.0)
	gate.rotation.y = deg_to_rad(90.0)

	# Lush rural paddy fields along eastern and southern perimeter of Mindon stream
	var paddy_positions = [
		Vector3(45.0, 0.0, 85.0),
		Vector3(75.0, 0.0, 110.0),
		Vector3(-95.0, 0.0, 60.0)
	]
	for p_pos in paddy_positions:
		var paddy = PADDY_SCENE.instantiate()
		amenities_holder.add_child(paddy)
		paddy.global_position = p_pos

	# Mindon Ward 3 Landmark: Shwe Bon Thar Hilltop Golden Pagoda (ရွှေဘုံသာစေတီတော်)
	# Terraced hill elevation mound with stone stair ramp ascending 14 meters above valley
	var hill = StaticBody3D.new()
	hill.name = "PagodaHillMound"
	var hill_col = CollisionShape3D.new()
	var hill_cshape = CylinderShape3D.new()
	hill_cshape.height = 14.0
	hill_cshape.radius = 32.0
	hill_col.shape = hill_cshape
	hill_col.position = Vector3(0.0, 7.0, 0.0)
	hill.add_child(hill_col)

	# Stone stairway ascent ramp collider
	var stair_col = CollisionShape3D.new()
	var stair_box = BoxShape3D.new()
	stair_box.size = Vector3(6.2, 0.8, 22.0)
	stair_col.shape = stair_box
	stair_col.position = Vector3(0.0, 6.8, -24.0)
	stair_col.rotation.x = deg_to_rad(32.0)
	hill.add_child(stair_col)

	var hill_mesh = MeshInstance3D.new()
	var hill_cmesh = CylinderMesh.new()
	hill_cmesh.top_radius = 28.0
	hill_cmesh.bottom_radius = 42.0
	hill_cmesh.height = 14.0
	hill_mesh.mesh = hill_cmesh
	hill_mesh.position = Vector3(0.0, 7.0, 0.0)
	var hill_mat = StandardMaterial3D.new()
	hill_mat.albedo_color = Color(0.32, 0.44, 0.22, 1.0)
	hill_mat.roughness = 0.95
	hill_mesh.set_surface_override_material(0, hill_mat)
	hill.add_child(hill_mesh)

	# Stone stairway ascent ramp
	var stair = MeshInstance3D.new()
	var stair_mesh = BoxMesh.new()
	stair_mesh.size = Vector3(6.0, 0.6, 22.0)
	stair.mesh = stair_mesh
	stair.position = Vector3(0.0, 6.8, -24.0)
	stair.rotation.x = deg_to_rad(32.0)
	var stair_mat = StandardMaterial3D.new()
	stair_mat.albedo_color = Color(0.72, 0.70, 0.65, 1.0)
	stair.set_surface_override_material(0, stair_mat)
	hill.add_child(stair)

	amenities_holder.add_child(hill)
	hill.global_position = Vector3(-110.0, 0.0, 180.0)

	var pagoda = PAGODA_SCENE.instantiate()
	pagoda.name = "MindonHilltopPagoda"
	amenities_holder.add_child(pagoda)
	pagoda.global_position = Vector3(-110.0, 14.0, 180.0)

	# Mindon Stream Wooden Boat Pier & Docked Ayeyarwady Rowboat (မင်းတုန်းချောင်း ဆိပ်ကမ်းနှင့် လှေ)
	var pier = PIER_SCENE.instantiate()
	pier.name = "MindonStreamPier"
	amenities_holder.add_child(pier)
	pier.global_position = Vector3(15.0, 0.0, 32.0)
	pier.rotation.y = deg_to_rad(-15.0)

	var boat = BOAT_SCENE.instantiate()
	boat.name = "MindonRowboat"
	amenities_holder.add_child(boat)
	boat.global_position = Vector3(18.5, -0.2, 38.0)
	boat.rotation.y = deg_to_rad(65.0)

	# Mindon Stream Bamboo Footbridge (မင်းတုန်းချောင်း ဝါးတံတား) connecting village to farmlands
	var bridge = BRIDGE_SCENE.instantiate()
	bridge.name = "MindonBambooBridge"
	amenities_holder.add_child(bridge)
	bridge.global_position = Vector3(2.0, 0.1, 28.0)
	bridge.rotation.y = deg_to_rad(20.0)

	# Heavy Teakwood Vehicular & Bullock Cart Stream Bridge (မင်းတုန်းချောင်း ကျွန်းသစ်တံတားကြီး)
	var teak_bridge = WOODEN_BRIDGE_SCENE.instantiate()
	teak_bridge.name = "MindonTeakwoodVehicularBridge"
	amenities_holder.add_child(teak_bridge)
	teak_bridge.global_position = Vector3(56.0, 0.15, 62.0)
	teak_bridge.rotation.y = deg_to_rad(-45.0)

	# Traditional roadside Myanmar Tea Shop (မင်းတုန်း ရိုးရာလက်ဖက်ရည်ဆိုင်)
	var teashop = TEASHOP_SCENE.instantiate()
	teashop.name = "MindonTeashop"
	amenities_holder.add_child(teashop)
	teashop.global_position = Vector3(-28.0, 0.0, 92.0)
	teashop.rotation.y = deg_to_rad(-45.0)

	# Traditional roadside Fruit & Produce Market Stalls (ဈေးသည်ဆိုင်တန်း)
	var stall1 = STALL_SCENE.instantiate()
	stall1.name = "MindonMarketStall_1"
	amenities_holder.add_child(stall1)
	stall1.global_position = Vector3(-35.0, 0.0, 96.0)
	stall1.rotation.y = deg_to_rad(-40.0)

	var stall2 = STALL_SCENE.instantiate()
	stall2.name = "MindonMarketStall_2"
	amenities_holder.add_child(stall2)
	stall2.global_position = Vector3(-22.0, 0.0, 88.0)
	stall2.rotation.y = deg_to_rad(-50.0)

	# Ambient Mindon Citizens (ရွာသူရွာသား လမ်းလျှောက်သူများ)
	var ped_spawns = [
		Vector3(-25.0, 0.0, 90.0),
		Vector3(-31.0, 0.0, 94.0),
		Vector3(-15.0, 0.0, 80.0),
		Vector3(0.0, 0.0, 30.0)
	]
	var ped_idx = 0
	for p_pos in ped_spawns:
		ped_idx += 1
		var ped = PEDESTRIAN_SCENE.instantiate()
		ped.name = "MindonCitizen_%d" % ped_idx
		amenities_holder.add_child(ped)
		ped.global_position = p_pos

	# Atmospheric Night Fireflies (ပိုးစုန်းကြူးများ) over Mindon stream & paddy terraces
	var flies_river = FIREFLIES_SCENE.instantiate()
	flies_river.name = "MindonStreamFireflies"
	amenities_holder.add_child(flies_river)
	flies_river.global_position = Vector3(10.0, 1.2, 30.0)

	var flies_paddy = FIREFLIES_SCENE.instantiate()
	flies_paddy.name = "MindonPaddyFireflies"
	amenities_holder.add_child(flies_paddy)
	flies_paddy.global_position = Vector3(60.0, 1.2, 95.0)

	# Guardian Golden Hinthar Bird Statues (ဟင်္သာရုပ်တုများ) at Pagoda Stairway Portal
	var hinthar_l = HINTHAR_SCENE.instantiate()
	hinthar_l.name = "GuardianHinthar_L"
	amenities_holder.add_child(hinthar_l)
	hinthar_l.global_position = Vector3(-113.0, 0.0, 163.0)
	hinthar_l.rotation.y = deg_to_rad(15.0)

	var hinthar_r = HINTHAR_SCENE.instantiate()
	hinthar_r.name = "GuardianHinthar_R"
	amenities_holder.add_child(hinthar_r)
	hinthar_r.global_position = Vector3(-107.0, 0.0, 163.0)
	hinthar_r.rotation.y = deg_to_rad(-15.0)

	# Mindon Ward 3 Youth Community Football Pitch (ဘောလုံးကွင်းနှင့် ဘောလုံး)
	var pitch = PITCH_SCENE.instantiate()
	pitch.name = "MindonFootballPitch"
	amenities_holder.add_child(pitch)
	pitch.global_position = Vector3(-45.0, 0.0, 150.0)
	pitch.rotation.y = deg_to_rad(-10.0)

	# Sacred Bronze Monastery Bell (ရွှေဘုံသာ ခေါင်းလောင်းတော်) on Pagoda Hilltop Terrace
	var bell = BELL_SCENE.instantiate()
	bell.name = "MindonPagodaBell"
	amenities_holder.add_child(bell)
	bell.global_position = Vector3(-98.0, 14.0, 178.0)
	bell.rotation.y = deg_to_rad(-30.0)

	# Mindon Ward 3 Monastic Education Monastery School (ဘုန်းတော်ကြီးသင်ပညာရေးကျောင်း)
	var monastery = MONASTERY_SCENE.instantiate()
	monastery.name = "MindonMonasterySchool"
	amenities_holder.add_child(monastery)
	monastery.global_position = Vector3(-135.0, 0.0, 195.0)
	monastery.rotation.y = deg_to_rad(25.0)

	# Traditional Myanmar Bullock Carts (နွားလှည်းများ) along Village Lanes
	var cart_paddy = CART_SCENE.instantiate()
	cart_paddy.name = "MindonPaddyBullockCart"
	amenities_holder.add_child(cart_paddy)
	cart_paddy.global_position = Vector3(38.0, 0.0, 78.0)
	cart_paddy.rotation.y = deg_to_rad(45.0)

	var cart_lane = CART_SCENE.instantiate()
	cart_lane.name = "MindonVillageLaneCart"
	amenities_holder.add_child(cart_lane)
	cart_lane.global_position = Vector3(-18.0, 0.0, 72.0)
	cart_lane.rotation.y = deg_to_rad(-120.0)

	# Traditional Roadside Clay Water Pot Stands (ရေချမ်းစင်များ) for Wayfarers
	var pot_gate = POT_SCENE.instantiate()
	pot_gate.name = "RoadsideWaterPot_Gate"
	amenities_holder.add_child(pot_gate)
	pot_gate.global_position = Vector3(-9.0, 0.0, 76.0)
	pot_gate.rotation.y = deg_to_rad(-80.0)

	var pot_teashop = POT_SCENE.instantiate()
	pot_teashop.name = "RoadsideWaterPot_Teashop"
	amenities_holder.add_child(pot_teashop)
	pot_teashop.global_position = Vector3(-25.0, 0.0, 94.0)
	pot_teashop.rotation.y = deg_to_rad(10.0)

	# Communal Brick Drinking Well (ရပ်ကွက်ရေတွင်းကြီး) near Monastic School
	var well_communal = WELL_SCENE.instantiate()
	well_communal.name = "MindonVillageWell"
	amenities_holder.add_child(well_communal)
	well_communal.global_position = Vector3(-120.0, 0.0, 186.0)

	# Traditional Teakwood Wayfarer Rest House (ဓမ္မာရုံ / ဇရပ်) near Pagoda base
	var zayat_pagoda = ZAYAT_SCENE.instantiate()
	zayat_pagoda.name = "MindonPagodaZayat"
	amenities_holder.add_child(zayat_pagoda)
	zayat_pagoda.global_position = Vector3(-85.0, 0.0, 168.0)
	zayat_pagoda.rotation.y = deg_to_rad(-25.0)

	# Village Traditional Zat Pwe / Festival Stage (ရိုးရာပွဲတော်နှင့် ဇာတ်စင်ကြီး)
	var stage = FESTIVAL_SCENE.instantiate()
	stage.name = "MindonFestivalStage"
	amenities_holder.add_child(stage)
	stage.global_position = Vector3(-70.0, 0.0, 135.0)
	stage.rotation.y = deg_to_rad(15.0)

	# Vibrant Night Market Bazaar (ရွှေမင်္ဂလာ ညဈေးတန်းကြီး) with food stalls & globe lanterns
	var market = NIGHT_MARKET_SCENE.instantiate()
	market.name = "MindonNightMarket"
	amenities_holder.add_child(market)
	market.global_position = Vector3(-42.0, 0.0, 108.0)
	market.rotation.y = deg_to_rad(-8.0)

	# Traditional Teakwood Guest House (ရွှေဧည့်ရိပ်သာ တည်းခိုခန်း) with night lantern
	var guesthouse = GUESTHOUSE_SCENE.instantiate()
	guesthouse.name = "MindonGuestHouse"
	amenities_holder.add_child(guesthouse)
	guesthouse.global_position = Vector3(-55.0, 0.0, 85.0)
	guesthouse.rotation.y = deg_to_rad(-85.0)

# --- 1. Grand Union National Highway (ပြည်ထောင်စုလမ်းမကြီး - မင်းတုန်း-သရက် အမြန်လမ်း) ---
func _generate_grand_union_highway() -> void:
	var highway_holder = Node3D.new()
	highway_holder.name = "GrandUnionHighway"
	add_child(highway_holder)

	var asphalt_mat = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.20, 0.21, 0.23, 1.0)
	asphalt_mat.roughness = 0.88

	var line_yellow = StandardMaterial3D.new()
	line_yellow.albedo_color = Color(0.96, 0.82, 0.18, 1.0)
	line_yellow.emission_enabled = true
	line_yellow.emission = Color(0.96, 0.82, 0.18, 1.0)
	line_yellow.emission_energy_multiplier = 0.45

	var line_white = StandardMaterial3D.new()
	line_white.albedo_color = Color(0.92, 0.94, 0.96, 1.0)
	line_white.roughness = 0.6

	var sign_green = StandardMaterial3D.new()
	sign_green.albedo_color = Color(0.08, 0.42, 0.22, 1.0)
	sign_green.roughness = 0.4

	# Highway Waypoints spanning 3600m from West pass through Mindon valley to Eastern hills
	var highway_pts = [
		Vector3(-1800.0, 0.08, -480.0),
		Vector3(-1400.0, 0.08, -380.0),
		Vector3(-1000.0, 0.08, -260.0),
		Vector3(-600.0, 0.08, -120.0),
		Vector3(-200.0, 0.08, 0.0),
		Vector3(200.0, 0.08, 60.0),
		Vector3(600.0, 0.08, 150.0),
		Vector3(1000.0, 0.08, 280.0),
		Vector3(1400.0, 0.08, 420.0),
		Vector3(1800.0, 0.08, 560.0)
	]

	var road_w = 11.5 # 2-lane wide highway with paved shoulders
	var total_dist = 0.0

	for i in range(highway_pts.size() - 1):
		var p1 = highway_pts[i]
		var p2 = highway_pts[i + 1]
		var sub_steps = 14
		var prev_sub = p1

		for s in range(1, sub_steps + 1):
			var t = float(s) / float(sub_steps)
			var sub_pt = p1.lerp(p2, t)
			# Gentle organic highway curvature
			sub_pt.z += sin(float(i * sub_steps + s) * 0.28) * 12.0
			var seg_len = prev_sub.distance_to(sub_pt)

			# Main Road Slab
			var road_mesh = MeshInstance3D.new()
			var quad = BoxMesh.new()
			quad.size = Vector3(road_w, 0.10, seg_len)
			road_mesh.mesh = quad
			road_mesh.set_surface_override_material(0, asphalt_mat)
			highway_holder.add_child(road_mesh)

			var mid = (prev_sub + sub_pt) * 0.5
			var fwd = (sub_pt - prev_sub).normalized()
			road_mesh.global_position = mid
			road_mesh.look_at(mid + fwd, Vector3.UP)

			# White Edge Lines (Left & Right)
			for edge_side in [-1.0, 1.0]:
				var edge_mesh = MeshInstance3D.new()
				var e_box = BoxMesh.new()
				e_box.size = Vector3(0.24, 0.12, seg_len)
				edge_mesh.mesh = e_box
				edge_mesh.set_surface_override_material(0, line_white)
				highway_holder.add_child(edge_mesh)
				var e_offset = fwd.cross(Vector3.UP).normalized() * (road_w * 0.46 * edge_side)
				edge_mesh.global_position = mid + e_offset
				edge_mesh.look_at(mid + e_offset + fwd, Vector3.UP)

			# Dashed Yellow Center Divider (alternate segments)
			if (i * sub_steps + s) % 2 == 0:
				var center_dash = MeshInstance3D.new()
				var c_box = BoxMesh.new()
				c_box.size = Vector3(0.28, 0.13, seg_len * 0.7)
				center_dash.mesh = c_box
				center_dash.set_surface_override_material(0, line_yellow)
				highway_holder.add_child(center_dash)
				center_dash.global_position = mid
				center_dash.look_at(mid + fwd, Vector3.UP)

			# Roadside Mileposts (မိုင်တိုင်များ) & Highway Signs
			if (i * sub_steps + s) % 7 == 0:
				var mile_num = int((i * sub_steps + s) / 7)
				var post = MeshInstance3D.new()
				var p_box = BoxMesh.new()
				p_box.size = Vector3(0.35, 0.85, 0.35)
				post.mesh = p_box
				var post_mat = StandardMaterial3D.new()
				post_mat.albedo_color = Color(0.95, 0.95, 0.92, 1.0)
				post.set_surface_override_material(0, post_mat)
				highway_holder.add_child(post)
				var p_side = fwd.cross(Vector3.UP).normalized() * (road_w * 0.55)
				post.global_position = mid + p_side + Vector3(0, 0.42, 0)

				# Red top paint
				var post_cap = MeshInstance3D.new()
				var c_mesh = BoxMesh.new()
				c_mesh.size = Vector3(0.37, 0.22, 0.37)
				post_cap.mesh = c_mesh
				var red_mat = StandardMaterial3D.new()
				red_mat.albedo_color = Color(0.85, 0.15, 0.12, 1.0)
				post_cap.set_surface_override_material(0, red_mat)
				post.add_child(post_cap)
				post_cap.position = Vector3(0, 0.36, 0)

				# Highway Solar Streetlight
				var light_pole = MeshInstance3D.new()
				var pole_mesh = CylinderMesh.new()
				pole_mesh.top_radius = 0.08
				pole_mesh.bottom_radius = 0.12
				pole_mesh.height = 7.5
				light_pole.mesh = pole_mesh
				var metal_mat = StandardMaterial3D.new()
				metal_mat.albedo_color = Color(0.65, 0.68, 0.72, 1.0)
				metal_mat.metallic = 0.8
				light_pole.set_surface_override_material(0, metal_mat)
				highway_holder.add_child(light_pole)
				var pole_side = fwd.cross(Vector3.UP).normalized() * (road_w * 0.62)
				light_pole.global_position = mid + pole_side + Vector3(0, 3.75, 0)

				# Streetlight lamp arm
				var lamp_spot = OmniLight3D.new()
				lamp_spot.light_color = Color(1.0, 0.92, 0.75, 1.0)
				lamp_spot.light_energy = 1.4
				lamp_spot.omni_range = 24.0
				light_pole.add_child(lamp_spot)
				lamp_spot.position = Vector3(0, 3.8, 0)

			prev_sub = sub_pt

	# Highway Destination Signboards
	var signs_data = [
		{"pos": Vector3(-550.0, 0.0, -110.0), "txt": "ပြည်ထောင်စုလမ်းမကြီး\nမင်းတုန်းမြို့နယ် မှ ကြိုဆိုပါသည်", "fwd": Vector3(1, 0, 0.2)},
		{"pos": Vector3(550.0, 0.0, 140.0), "txt": "သရက်မြို့ သို့ -> ၃၈ မိုင်\nယာဉ်စည်းကမ်း လိုက်နာပါ", "fwd": Vector3(1, 0, 0.3)},
		{"pos": Vector3(-1200.0, 0.0, -320.0), "txt": "ရခိုင်ရိုးမ ရှုခင်းသာတောင်ကြားလမ်း", "fwd": Vector3(1, 0, 0.1)}
	]
	for sd in signs_data:
		var sign_board = MeshInstance3D.new()
		var sb_mesh = BoxMesh.new()
		sb_mesh.size = Vector3(4.8, 2.2, 0.15)
		sign_board.mesh = sb_mesh
		sign_board.set_surface_override_material(0, sign_green)
		highway_holder.add_child(sign_board)
		sign_board.global_position = sd["pos"] + Vector3(0, 3.4, 0)
		sign_board.look_at(sign_board.global_position + sd["fwd"], Vector3.UP)

		# Support pillars
		for s_offset in [-1.8, 1.8]:
			var pillar = MeshInstance3D.new()
			var p_cyl = CylinderMesh.new()
			p_cyl.top_radius = 0.08
			p_cyl.bottom_radius = 0.08
			p_cyl.height = 3.4
			pillar.mesh = p_cyl
			sign_board.add_child(pillar)
			pillar.position = Vector3(s_offset, -1.7, 0)

		# 3D Label on sign
		var lbl = Label3D.new()
		lbl.text = sd["txt"]
		lbl.font_size = 32
		lbl.outline_size = 8
		lbl.modulate = Color(1.0, 1.0, 1.0, 1.0)
		sign_board.add_child(lbl)
		lbl.position = Vector3(0, 0, 0.1)

# --- 2. Scenic Riverside Nature Loop (မင်းတုန်းချောင်း ရှုခင်းသာပတ်လမ်း) ---
func _generate_scenic_riverside_loop() -> void:
	var river_loop_holder = Node3D.new()
	river_loop_holder.name = "ScenicRiversideLoop"
	add_child(river_loop_holder)

	var gravel_mat = StandardMaterial3D.new()
	gravel_mat.albedo_color = Color(0.52, 0.44, 0.32, 1.0)
	gravel_mat.roughness = 0.96

	# Meandering riverside route along Mindon stream banks (2400m circuit)
	var river_loop_pts = [
		Vector3(-600.0, 0.06, 80.0),
		Vector3(-300.0, 0.06, 110.0),
		Vector3(0.0, 0.06, 45.0),
		Vector3(350.0, 0.06, -30.0),
		Vector3(700.0, 0.06, -110.0),
		Vector3(1100.0, 0.06, -60.0),
		Vector3(1450.0, 0.06, 80.0),
		Vector3(1100.0, 0.06, 220.0),
		Vector3(600.0, 0.06, 260.0),
		Vector3(100.0, 0.06, 180.0),
		Vector3(-400.0, 0.06, 140.0)
	]

	var r_width = 7.0
	for i in range(river_loop_pts.size() - 1):
		var p1 = river_loop_pts[i]
		var p2 = river_loop_pts[i + 1]
		var dist = p1.distance_to(p2)

		var r_mesh = MeshInstance3D.new()
		var quad = BoxMesh.new()
		quad.size = Vector3(r_width, 0.08, dist)
		r_mesh.mesh = quad
		r_mesh.set_surface_override_material(0, gravel_mat)
		river_loop_holder.add_child(r_mesh)

		var mid = (p1 + p2) * 0.5
		var fwd = (p2 - p1).normalized()
		r_mesh.global_position = mid
		r_mesh.look_at(mid + fwd, Vector3.UP)

		# Roadside Giant Banyan Trees & Resting Benches every segment
		if i % 2 == 0:
			var zayat = ZAYAT_SCENE.instantiate()
			river_loop_holder.add_child(zayat)
			var side_v = fwd.cross(Vector3.UP).normalized() * 7.5
			zayat.global_position = mid + side_v
			zayat.look_at(mid, Vector3.UP)

			var pot = POT_SCENE.instantiate()
			river_loop_holder.add_child(pot)
			pot.global_position = mid + side_v + Vector3(2.5, 0, 1.5)

		if i % 3 == 0:
			var bridge = WOODEN_BRIDGE_SCENE.instantiate()
			river_loop_holder.add_child(bridge)
			bridge.global_position = mid + Vector3(0, 0.1, 0)
			bridge.look_at(mid + fwd, Vector3.UP)

# --- 3. Mountain Pass Scenic Viewpoints & Hilltop Pagodas (တောင်ပေါ်ရှုခင်းသာ စေတီများ) ---
func _generate_mountain_pass_viewpoints() -> void:
	var viewpoints_holder = Node3D.new()
	viewpoints_holder.name = "MountainPassViewpoints"
	add_child(viewpoints_holder)

	var viewpoints = [
		{"name": "MyaThaPeikPagoda", "pos": Vector3(880.0, 0.0, -560.0), "h": 36.0, "rad": 55.0, "p_name": "မြသပိတ် တောင်စွန်းစေတီတော်"},
		{"name": "TaungZalatViewpoint", "pos": Vector3(-1050.0, 0.0, 480.0), "h": 32.0, "rad": 48.0, "p_name": "တောင်ဇလပ် ရှုခင်းသာစခန်း"},
		{"name": "ShweMyinTinPagoda", "pos": Vector3(1350.0, 0.0, -220.0), "h": 42.0, "rad": 62.0, "p_name": "ရွှေမြင်တင် တောင်ထွတ်စေတီတော်"}
	]

	var hill_mat = StandardMaterial3D.new()
	hill_mat.albedo_color = Color(0.28, 0.42, 0.20, 1.0)
	hill_mat.roughness = 0.95

	var stair_mat = StandardMaterial3D.new()
	stair_mat.albedo_color = Color(0.75, 0.72, 0.65, 1.0)

	for vp in viewpoints:
		var v_pos: Vector3 = vp["pos"]
		var h: float = vp["h"]
		var rad: float = vp["rad"]

		# Elevated Hill Body
		var hill_body = StaticBody3D.new()
		hill_body.name = "%s_Hill" % vp["name"]
		var col = CollisionShape3D.new()
		var cyl_shape = CylinderShape3D.new()
		cyl_shape.height = h
		cyl_shape.radius = rad
		col.shape = cyl_shape
		col.position = Vector3(0, h * 0.5, 0)
		hill_body.add_child(col)

		var h_mesh = MeshInstance3D.new()
		var cyl_mesh = CylinderMesh.new()
		cyl_mesh.top_radius = rad * 0.75
		cyl_mesh.bottom_radius = rad * 1.35
		cyl_mesh.height = h
		h_mesh.mesh = cyl_mesh
		h_mesh.position = Vector3(0, h * 0.5, 0)
		h_mesh.set_surface_override_material(0, hill_mat)
		hill_body.add_child(h_mesh)

		viewpoints_holder.add_child(hill_body)
		hill_body.global_position = v_pos

		# Winding Access Ramp for Cars & Bullock Carts
		var ramp_body = StaticBody3D.new()
		var ramp_col = CollisionShape3D.new()
		var r_box_shape = BoxShape3D.new()
		r_box_shape.size = Vector3(7.5, 0.8, rad * 1.6)
		ramp_col.shape = r_box_shape
		ramp_body.add_child(ramp_col)

		var ramp_mesh = MeshInstance3D.new()
		var r_mesh_box = BoxMesh.new()
		r_mesh_box.size = Vector3(7.5, 0.6, rad * 1.6)
		ramp_mesh.mesh = r_mesh_box
		ramp_mesh.set_surface_override_material(0, stair_mat)
		ramp_body.add_child(ramp_mesh)

		hill_body.add_child(ramp_body)
		ramp_body.position = Vector3(0, h * 0.48, -rad * 0.95)
		ramp_body.rotation.x = deg_to_rad(24.0)

		# Golden Stupa atop hill
		var pagoda = PAGODA_SCENE.instantiate()
		pagoda.name = vp["name"]
		viewpoints_holder.add_child(pagoda)
		pagoda.global_position = v_pos + Vector3(0, h, 0)

		# Nameplate Billboard
		var lbl = Label3D.new()
		lbl.text = "🏛️ %s" % vp["p_name"]
		lbl.font_size = 36
		lbl.outline_size = 10
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate = Color(1.0, 0.88, 0.25, 1.0)
		pagoda.add_child(lbl)
		lbl.position = Vector3(0, 9.5, 0)

		# Monastic bronze bell on terrace
		var bell = BELL_SCENE.instantiate()
		viewpoints_holder.add_child(bell)
		bell.global_position = v_pos + Vector3(14.0, h, 8.0)

# --- 4. Distant Mountain Horizons & Basin Ridges (PUBG-Style Vast Panoramic Landscape) ---
func _generate_distant_mountain_horizons() -> void:
	var mountains_holder = Node3D.new()
	mountains_holder.name = "DistantMountainHorizons"
	add_child(mountains_holder)

	var mountain_mat = StandardMaterial3D.new()
	mountain_mat.albedo_color = Color(0.22, 0.35, 0.20, 1.0)
	mountain_mat.roughness = 0.96

	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.38, 0.36, 0.32, 1.0)
	rock_mat.roughness = 0.92

	# 28 Majestic Mountain Peaks encircling the 8km perimeter (R = 2200m to 3800m)
	var mountain_count = 28
	for m in range(mountain_count):
		var angle = float(m) / float(mountain_count) * TAU
		var dist = randf_range(2400.0, 3600.0)
		var m_x = cos(angle) * dist
		var m_z = sin(angle) * dist
		var m_height = randf_range(110.0, 240.0)
		var m_base_w = randf_range(380.0, 680.0)

		var mt = StaticBody3D.new()
		mt.name = "MountainPeak_%d" % m
		var col = CollisionShape3D.new()
		var c_shape = CylinderShape3D.new()
		c_shape.height = m_height
		c_shape.radius = m_base_w * 0.45
		col.shape = c_shape
		col.position = Vector3(0, m_height * 0.5, 0)
		mt.add_child(col)

		var m_mesh = MeshInstance3D.new()
		var p_mesh = PrismMesh.new()
		p_mesh.size = Vector3(m_base_w, m_height, m_base_w * 0.85)
		m_mesh.mesh = p_mesh
		m_mesh.position = Vector3(0, m_height * 0.5, 0)
		m_mesh.rotation.y = randf_range(0.0, TAU)
		m_mesh.set_surface_override_material(0, mountain_mat if m % 2 == 0 else rock_mat)
		mt.add_child(m_mesh)

		mountains_holder.add_child(mt)
		mt.global_position = Vector3(m_x, 0.0, m_z)

# --- 5. Vast Golden Paddy Terraces & Rural Countryside Farms (ရွှေဝါရောင် လယ်ကွင်းပြင်ကြီးများ) ---
func _generate_vast_paddy_terraces_and_farms() -> void:
	var farms_holder = Node3D.new()
	farms_holder.name = "VastPaddyTerracesAndFarms"
	add_child(farms_holder)

	var emerald_rice = StandardMaterial3D.new()
	emerald_rice.albedo_color = Color(0.24, 0.56, 0.18, 1.0)
	emerald_rice.roughness = 0.85

	var golden_rice = StandardMaterial3D.new()
	golden_rice.albedo_color = Color(0.78, 0.68, 0.22, 1.0)
	golden_rice.roughness = 0.88

	var mud_bund_mat = StandardMaterial3D.new()
	mud_bund_mat.albedo_color = Color(0.42, 0.32, 0.20, 1.0)
	mud_bund_mat.roughness = 0.98

	# Large 350m x 250m terraced paddy sectors across southern and eastern valley
	var sector_coords = [
		Vector3(250.0, 0.0, 320.0),
		Vector3(620.0, 0.0, 480.0),
		Vector3(980.0, 0.0, 360.0),
		Vector3(-450.0, 0.0, 350.0),
		Vector3(-800.0, 0.0, 280.0),
		Vector3(500.0, 0.0, -380.0)
	]

	var sec_idx = 0
	for sc in sector_coords:
		sec_idx += 1
		# Paddy Field Flat Slab
		var field_mesh = MeshInstance3D.new()
		var f_box = BoxMesh.new()
		f_box.size = Vector3(280.0, 0.05, 200.0)
		field_mesh.mesh = f_box
		field_mesh.set_surface_override_material(0, golden_rice if sec_idx % 2 == 0 else emerald_rice)
		farms_holder.add_child(field_mesh)
		field_mesh.global_position = sc

		# Mud Bund Borders (လယ်ကန်သင်းများ)
		for border_x in [-140.0, 140.0]:
			var bund = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(1.2, 0.35, 200.0)
			bund.mesh = b_mesh
			bund.set_surface_override_material(0, mud_bund_mat)
			field_mesh.add_child(bund)
			bund.position = Vector3(border_x, 0.15, 0)

		for border_z in [-100.0, 100.0]:
			var bund_z = MeshInstance3D.new()
			var b_mesh_z = BoxMesh.new()
			b_mesh_z.size = Vector3(280.0, 0.35, 1.2)
			bund_z.mesh = b_mesh_z
			bund_z.set_surface_override_material(0, mud_bund_mat)
			field_mesh.add_child(bund_z)
			bund_z.position = Vector3(0, 0.15, border_z)

		# Traditional Farmer Hut & Haystack in each sector
		var house = HOUSE_SCENE.instantiate()
		farms_holder.add_child(house)
		house.global_position = sc + Vector3(110.0, 0, 80.0)
		house.scale = Vector3(0.9, 0.9, 0.9)

		# Haystack (ကောက်ရိုးပုံ)
		var hay = MeshInstance3D.new()
		var hay_cone = CylinderMesh.new()
		hay_cone.top_radius = 0.2
		hay_cone.bottom_radius = 2.4
		hay_cone.height = 3.2
		hay.mesh = hay_cone
		var straw_mat = StandardMaterial3D.new()
		straw_mat.albedo_color = Color(0.82, 0.72, 0.35, 1.0)
		straw_mat.roughness = 0.95
		hay.set_surface_override_material(0, straw_mat)
		farms_holder.add_child(hay)
		hay.global_position = sc + Vector3(95.0, 1.6, 75.0)

		# Toddy palms line along field borders
		for p_idx in range(4):
			var palm = PALM_SCENE.instantiate()
			farms_holder.add_child(palm)
			palm.global_position = sc + Vector3(-135.0 + float(p_idx) * 70.0, 0, 95.0)
			palm.scale = Vector3(1.3, 1.3, 1.3)

func _generate_airdrop_supply_drops() -> void:
	var airdrop_holder = Node3D.new()
	airdrop_holder.name = "AirDropSupplies"
	add_child(airdrop_holder)

	# 1. Eastern Highway Ridge (Visible from vehicles cruising along Grand Highway)
	var drop1 = AIRDROP_SCENE.instantiate()
	drop1.name = "HighwayAirDrop"
	drop1.crate_id = "drop_highway"
	airdrop_holder.add_child(drop1)
	drop1.global_position = Vector3(420.0, 0.0, 140.0)

	# 2. Taung Zalat Panoramic Hill Overlook (+32m elevation)
	var drop2 = AIRDROP_SCENE.instantiate()
	drop2.name = "HilltopAirDrop"
	drop2.crate_id = "drop_hilltop"
	airdrop_holder.add_child(drop2)
	drop2.global_position = Vector3(-680.0, 32.0, 410.0)

func _generate_highway_milestone_posts() -> void:
	var milestone_holder = Node3D.new()
	milestone_holder.name = "HighwayMilestones"
	add_child(milestone_holder)

	var concrete_mat = StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.93, 0.94, 0.95, 1.0)
	concrete_mat.roughness = 0.82

	var yellow_band_mat = StandardMaterial3D.new()
	yellow_band_mat.albedo_color = Color(0.96, 0.78, 0.12, 1.0)
	yellow_band_mat.roughness = 0.5

	var post_locations = [
		{"pos": Vector3(-1200.0, 0.0, -112.0), "mindon_km": 12, "other": "ပြည် ၅၀"},
		{"pos": Vector3(-900.0, 0.0, -112.0), "mindon_km": 9, "other": "ပြည် ၅၃"},
		{"pos": Vector3(-600.0, 0.0, -112.0), "mindon_km": 6, "other": "ပြည် ၅၆"},
		{"pos": Vector3(-300.0, 0.0, -112.0), "mindon_km": 3, "other": "ပြည် ၅၉"},
		{"pos": Vector3(0.0, 0.0, -112.0), "mindon_km": 0, "other": "မင်းတုန်း ဗဟို"},
		{"pos": Vector3(300.0, 0.0, -112.0), "mindon_km": 3, "other": "ပုသိမ် ၁၈၁"},
		{"pos": Vector3(600.0, 0.0, -112.0), "mindon_km": 6, "other": "ပုသိမ် ၁၇၈"},
		{"pos": Vector3(900.0, 0.0, -112.0), "mindon_km": 9, "other": "ပုသိမ် ၁၇၅"},
		{"pos": Vector3(1200.0, 0.0, -112.0), "mindon_km": 12, "other": "ပုသိမ် ၁၇၂"}
	]

	for data in post_locations:
		var p = Node3D.new()
		p.name = "Milestone_%d" % int(data["mindon_km"])
		milestone_holder.add_child(p)
		p.global_position = data["pos"]

		var base_mesh = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.55, 0.75, 0.35)
		base_mesh.mesh = bm
		base_mesh.position = Vector3(0, 0.375, 0)
		base_mesh.set_surface_override_material(0, concrete_mat)
		p.add_child(base_mesh)

		var crown_mesh = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.27
		cm.bottom_radius = 0.27
		cm.height = 0.35
		crown_mesh.mesh = cm
		crown_mesh.position = Vector3(0, 0.75, 0)
		crown_mesh.rotation = Vector3(deg_to_rad(90.0), 0, 0)
		crown_mesh.set_surface_override_material(0, yellow_band_mat)
		p.add_child(crown_mesh)

		var lbl = Label3D.new()
		lbl.position = Vector3(0, 0.45, 0.19)
		lbl.text = "မင်းတုန်း\n%d KM\n%s" % [data["mindon_km"], data["other"]]
		lbl.font_size = 28
		lbl.outline_size = 8
		lbl.modulate = Color(0.12, 0.12, 0.14, 1.0)
		lbl.outline_modulate = Color(1.0, 1.0, 1.0, 0.9)
		p.add_child(lbl)







