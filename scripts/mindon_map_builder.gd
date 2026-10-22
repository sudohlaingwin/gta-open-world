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
	asphalt_mat.roughness = 0.95

	var earth_mat = StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.48, 0.39, 0.28, 1.0)
	earth_mat.roughness = 1.0

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
			mesh_inst.global_position = mid_point
			var forward = (p2 - p1).normalized()
			mesh_inst.look_at(mesh_inst.global_position + forward, Vector3.UP)
			road_holder.add_child(mesh_inst)

			# Plant roadside authentic vegetation along real road shoulders
			if i % 3 == 0 and palm_count < 90:
				var right_dir = forward.cross(Vector3.UP).normalized()
				var side_mult = 1.0 if (i % 2 == 0) else -1.0
				var palm_pos = mid_point + right_dir * (road_width * 0.5 + 2.4 * side_mult)
				palm_pos.y = 0.0
				
				var palm = PALM_SCENE.instantiate()
				palm.global_position = palm_pos
				road_holder.add_child(palm)
				palm_count += 1

			if i % 4 == 1 and banana_count < 70:
				var right_dir = forward.cross(Vector3.UP).normalized()
				var side_mult = -1.0 if (i % 2 == 0) else 1.0
				var banana_pos = mid_point + right_dir * (road_width * 0.5 + 1.8 * side_mult)
				banana_pos.y = 0.0

				var banana = BANANA_SCENE.instantiate()
				banana.global_position = banana_pos
				road_holder.add_child(banana)
				banana_count += 1

func _generate_mindon_buildings(buildings: Array) -> void:
	var building_holder = Node3D.new()
	building_holder.name = "MindonBuildings"
	add_child(building_holder)

	var hospital_wall_mat = StandardMaterial3D.new()
	hospital_wall_mat.albedo_color = Color(0.92, 0.94, 0.95, 1.0)
	hospital_wall_mat.roughness = 0.7

	var hospital_roof_mat = StandardMaterial3D.new()
	hospital_roof_mat.albedo_color = Color(0.22, 0.42, 0.65, 1.0)
	hospital_roof_mat.roughness = 0.4

	for b in buildings:
		var pts = b.get("pts", [])
		if pts.is_empty():
			continue

		var cx = 0.0
		var cz = 0.0
		for p in pts:
			cx += p["x"]
			cz += p["z"]
		cx /= float(pts.size())
		cz /= float(pts.size())

		var b_type = str(b.get("type", "house"))
		if b_type == "hospital":
			# Mindon Township General Hospital compound buildings
			var hosp = Node3D.new()
			hosp.name = "MindonHospitalBuilding"

			var body_mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(12.0, 4.0, 10.0)
			body_mesh.mesh = box
			body_mesh.position = Vector3(0.0, 2.0, 0.0)
			body_mesh.set_surface_override_material(0, hospital_wall_mat)
			hosp.add_child(body_mesh)

			var roof_mesh = MeshInstance3D.new()
			var roof_box = BoxMesh.new()
			roof_box.size = Vector3(13.0, 0.6, 11.0)
			roof_mesh.mesh = roof_box
			roof_mesh.position = Vector3(0.0, 4.3, 0.0)
			roof_mesh.set_surface_override_material(0, hospital_roof_mat)
			hosp.add_child(roof_mesh)

			hosp.global_position = Vector3(cx, 0.0, cz)
			building_holder.add_child(hosp)
		else:
			# Myanmar teak & bamboo elevated residential home
			var house = HOUSE_SCENE.instantiate()
			house.global_position = Vector3(cx, 0.0, cz)
			building_holder.add_child(house)

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
			mesh_inst.global_position = mid_point
			var forward = (p2 - p1).normalized()
			mesh_inst.look_at(mesh_inst.global_position + forward, Vector3.UP)
			river_holder.add_child(mesh_inst)

func _generate_ward3_amenities() -> void:
	# Add authentic village infrastructure in Ward 3 center
	var amenities_holder = Node3D.new()
	amenities_holder.name = "Ward3Amenities"
	add_child(amenities_holder)

	var well = WELL_SCENE.instantiate()
	well.global_position = Vector3(5.0, 0.0, -8.0)
	amenities_holder.add_child(well)

	var pot = POT_SCENE.instantiate()
	pot.global_position = Vector3(3.5, 0.0, -6.5)
	amenities_holder.add_child(pot)

	var zayat = ZAYAT_SCENE.instantiate()
	zayat.global_position = Vector3(-12.0, 0.0, -14.0)
	amenities_holder.add_child(zayat)
