extends Node3D

# --- Mindon Township Ward 3 Real-World GIS Procedural Generator ---
# Exact Center: 19.351497 N, 94.731889 E (Mindon, Magway Region, Myanmar)
# Generates real-world roads, buildings (Ward 3 hospital, residential houses),
# native tropical roadside vegetation (Toddy palms, banana plants), and Mindon stream (မင်းတုန်းချောင်း)

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
const PEDESTRIAN_SCENE = preload("res://scenes/ambient_pedestrian.tscn")
const FIREFLIES_SCENE = preload("res://scenes/village_fireflies.tscn")
const HINTHAR_SCENE = preload("res://scenes/hinthar_statue.tscn")
const PITCH_SCENE = preload("res://scenes/football_pitch.tscn")
const BELL_SCENE = preload("res://scenes/monastery_bell.tscn")
const MONASTERY_SCENE = preload("res://scenes/monastery_school.tscn")
const CART_SCENE = preload("res://scenes/bullock_cart.tscn")
const RIVER_SHADER = preload("res://scripts/water_river.gdshader")

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
		var road_width: float = 6.5 if r_type == "unclassified" else (4.2 if r_type == "residential" else 3.2)
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
				curb_box.size = Vector3(0.3, 0.16, dist)
				curb_l.mesh = curb_box
				curb_l.set_surface_override_material(0, curb_mat)
				var right_dir = forward.cross(Vector3.UP).normalized()
				road_holder.add_child(curb_l)
				curb_l.global_position = mid_point - right_dir * (road_width * 0.5 + 0.15)
				curb_l.look_at(curb_l.global_position + forward, Vector3.UP)

				# Right Curb
				var curb_r = MeshInstance3D.new()
				curb_r.mesh = curb_box
				curb_r.set_surface_override_material(0, curb_mat)
				road_holder.add_child(curb_r)
				curb_r.global_position = mid_point + right_dir * (road_width * 0.5 + 0.15)
				curb_r.look_at(curb_r.global_position + forward, Vector3.UP)

				# Dashed yellow lane divider stripe
				if i % 2 == 0 and dist >= 1.5:
					var stripe = MeshInstance3D.new()
					var stripe_mesh = BoxMesh.new()
					stripe_mesh.size = Vector3(0.18, 0.09, minf(dist * 0.6, 3.0))
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
			col_box.size = Vector3(b_width + 0.5, 4.5, b_depth + 0.5)
			col.shape = col_box
			col.position = Vector3(0.0, 2.25, 0.0)
			hosp.add_child(col)

			var body_mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(b_width, 4.0, b_depth)
			body_mesh.mesh = box
			body_mesh.position = Vector3(0.0, 2.0, 0.0)
			body_mesh.set_surface_override_material(0, hospital_wall_mat)
			hosp.add_child(body_mesh)

			var roof_mesh = MeshInstance3D.new()
			var roof_box = BoxMesh.new()
			roof_box.size = Vector3(b_width + 1.0, 0.6, b_depth + 1.0)
			roof_mesh.mesh = roof_box
			roof_mesh.position = Vector3(0.0, 4.3, 0.0)
			roof_mesh.set_surface_override_material(0, hospital_roof_mat)
			hosp.add_child(roof_mesh)

			# Red Cross symbol and hospital signboard on facade
			var front_z = (b_depth * 0.5) + 0.06
			var b_cross_mat = cross_mat.duplicate()
			var cross_v = MeshInstance3D.new()
			cross_v.name = "CrossV"
			var cv_mesh = BoxMesh.new()
			cv_mesh.size = Vector3(0.3, 1.2, 0.08)
			cross_v.mesh = cv_mesh
			cross_v.position = Vector3(0.0, 2.8, front_z)
			cross_v.set_surface_override_material(0, b_cross_mat)
			hosp.add_child(cross_v)

			var cross_h = MeshInstance3D.new()
			cross_h.name = "CrossH"
			var ch_mesh = BoxMesh.new()
			ch_mesh.size = Vector3(1.0, 0.35, 0.08)
			cross_h.mesh = ch_mesh
			cross_h.position = Vector3(0.0, 2.8, front_z)
			cross_h.set_surface_override_material(0, b_cross_mat)
			hosp.add_child(cross_h)

			# Hospital entrance porch canopy & columns
			var canopy = MeshInstance3D.new()
			var canopy_mesh = BoxMesh.new()
			canopy_mesh.size = Vector3(3.2, 0.25, 2.0)
			canopy.mesh = canopy_mesh
			canopy.position = Vector3(0.0, 2.8, front_z + 0.9)
			canopy.set_surface_override_material(0, hospital_roof_mat)
			hosp.add_child(canopy)

			for pillar_x in [-1.4, 1.4]:
				var pillar = MeshInstance3D.new()
				var pillar_mesh = BoxMesh.new()
				pillar_mesh.size = Vector3(0.2, 2.8, 0.2)
				pillar.mesh = pillar_mesh
				pillar.position = Vector3(pillar_x, 1.4, front_z + 1.8)
				pillar.set_surface_override_material(0, frame_mat)
				hosp.add_child(pillar)

			# Glazed windows on building front
			var win_offset_x = (b_width * 0.5) * 0.55
			for wx in [-win_offset_x, win_offset_x]:
				var win = MeshInstance3D.new()
				var win_mesh = BoxMesh.new()
				win_mesh.size = Vector3(1.6, 1.3, 0.1)
				win.mesh = win_mesh
				win.position = Vector3(wx, 2.2, front_z)
				win.set_surface_override_material(0, window_glass_mat)
				hosp.add_child(win)

				var win_frame = MeshInstance3D.new()
				var win_fmesh = BoxMesh.new()
				win_fmesh.size = Vector3(1.72, 1.42, 0.06)
				win_frame.mesh = win_fmesh
				win_frame.position = Vector3(wx, 2.2, front_z - 0.02)
				win_frame.set_surface_override_material(0, frame_mat)
				hosp.add_child(win_frame)

			var sign = Label3D.new()
			sign.text = "မင်းတုန်းမြို့နယ် ပြည်သူ့ဆေးရုံ"
			sign.font_size = 22
			sign.outline_size = 6
			sign.modulate = Color(0.15, 0.45, 0.85, 1.0)
			sign.position = Vector3(0.0, 3.8, front_z + 0.05)
			hosp.add_child(sign)

			# Attach automated day/night lantern controller and porch lantern
			var porch_light = OmniLight3D.new()
			porch_light.name = "HospitalPorchLight"
			porch_light.light_color = Color(1.0, 0.92, 0.82, 1.0)
			porch_light.light_energy = 1.8 if hosp_idx == 1 else 1.2
			porch_light.omni_range = 10.0 if hosp_idx == 1 else 7.0
			porch_light.position = Vector3(0.0, 3.2, front_z + 0.5)
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

			var river_width: float = 24.0
			var mesh_inst = MeshInstance3D.new()
			var water_box = BoxMesh.new()
			water_box.size = Vector3(river_width, 0.35, dist)
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
	# Terraced hill elevation mound with stone stair ramp ascending 8 meters above valley
	var hill = StaticBody3D.new()
	hill.name = "PagodaHillMound"
	var hill_col = CollisionShape3D.new()
	var hill_cshape = CylinderShape3D.new()
	hill_cshape.height = 8.0
	hill_cshape.top_radius = 16.0
	hill_cshape.bottom_radius = 24.0
	hill_col.shape = hill_cshape
	hill_col.position = Vector3(0.0, 4.0, 0.0)
	hill.add_child(hill_col)

	var hill_mesh = MeshInstance3D.new()
	var hill_cmesh = CylinderMesh.new()
	hill_cmesh.top_radius = 16.0
	hill_cmesh.bottom_radius = 24.0
	hill_cmesh.height = 8.0
	hill_mesh.mesh = hill_cmesh
	hill_mesh.position = Vector3(0.0, 4.0, 0.0)
	var hill_mat = StandardMaterial3D.new()
	hill_mat.albedo_color = Color(0.32, 0.44, 0.22, 1.0)
	hill_mat.roughness = 0.95
	hill_mesh.set_surface_override_material(0, hill_mat)
	hill.add_child(hill_mesh)

	# Stone stairway ascent ramp
	var stair = MeshInstance3D.new()
	var stair_mesh = BoxMesh.new()
	stair_mesh.size = Vector3(3.2, 0.5, 12.0)
	stair.mesh = stair_mesh
	stair.position = Vector3(0.0, 3.8, -14.0)
	stair.rotation.x = deg_to_rad(33.0)
	var stair_mat = StandardMaterial3D.new()
	stair_mat.albedo_color = Color(0.72, 0.70, 0.65, 1.0)
	stair.set_surface_override_material(0, stair_mat)
	hill.add_child(stair)

	amenities_holder.add_child(hill)
	hill.global_position = Vector3(-110.0, 0.0, 180.0)

	var pagoda = PAGODA_SCENE.instantiate()
	pagoda.name = "MindonHilltopPagoda"
	amenities_holder.add_child(pagoda)
	pagoda.global_position = Vector3(-110.0, 8.0, 180.0)

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
	bell.global_position = Vector3(-98.0, 8.0, 178.0)
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


