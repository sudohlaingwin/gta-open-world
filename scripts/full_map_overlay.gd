extends Control

# --- Real-World Mindon Township Interactive Map & Navigation Overlay ---
# Center: 19.351497 N, 94.731889 E (Mindon Township Ward 3, Myanmar)

@onready var close_btn: Button = $Panel/CloseBtn
@onready var map_canvas: Control = $Panel/MapCanvas
@onready var player_marker: ColorRect = $Panel/MapCanvas/PlayerMarker
@onready var hospital_marker: ColorRect = $Panel/MapCanvas/HospitalMarker
@onready var pagoda_marker: ColorRect = $Panel/MapCanvas/PagodaMarker
@onready var market_marker: ColorRect = $Panel/MapCanvas/MarketMarker
@onready var stream_marker: ColorRect = $Panel/MapCanvas/StreamMarker
@onready var coords_label: Label = $Panel/CoordsLabel

var player: CharacterBody3D = null
var beacon_node: Node3D = null

# GIS mapping scale: 1 world unit (meter) = 0.55 canvas pixels
const MAP_SCALE: float = 0.55

var geo_data: Dictionary = {}

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): visible = false; get_tree().paused = false)
	beacon_node = get_tree().get_first_node_in_group("waypoint_beacon")
	if not beacon_node:
		beacon_node = get_parent().get_parent().get_node_or_null("WaypointBeacon")

	_load_geo_data()
	if map_canvas:
		map_canvas.draw.connect(_on_map_canvas_draw)

func _load_geo_data() -> void:
	var file = FileAccess.open("res://mindon_geo_data.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK and json.data is Dictionary:
			geo_data = json.data

func _on_map_canvas_draw() -> void:
	if not map_canvas:
		return
	var center = map_canvas.size * 0.5

	# 1. Draw Mindon Stream (မင်းတုန်းချောင်း) vectors
	var rivers = geo_data.get("rivers", [])
	for r in rivers:
		var pts = r.get("pts", [])
		for i in range(pts.size() - 1):
			var p1 = center + Vector2(pts[i]["x"], pts[i]["z"]) * MAP_SCALE
			var p2 = center + Vector2(pts[i + 1]["x"], pts[i + 1]["z"]) * MAP_SCALE
			map_canvas.draw_line(p1, p2, Color(0.18, 0.52, 0.92, 0.85), 6.0)

	# 2. Draw Real Mindon Ward 3 Road network
	var roads = geo_data.get("roads", [])
	for rd in roads:
		var pts = rd.get("pts", [])
		var r_type = str(rd.get("type", "residential"))
		var road_color = Color(0.85, 0.78, 0.35, 0.9) if r_type == "unclassified" else Color(0.55, 0.55, 0.58, 0.8)
		var road_w = 4.0 if r_type == "unclassified" else 2.5
		for i in range(pts.size() - 1):
			var p1 = center + Vector2(pts[i]["x"], pts[i]["z"]) * MAP_SCALE
			var p2 = center + Vector2(pts[i + 1]["x"], pts[i + 1]["z"]) * MAP_SCALE
			map_canvas.draw_line(p1, p2, road_color, road_w)

	# 3. Draw Waypoint Beacon destination line and pulsing beacon circle if active
	if beacon_node and beacon_node.visible and player:
		var p_canvas = center + Vector2(player.global_position.x, player.global_position.z) * MAP_SCALE
		var b_canvas = center + Vector2(beacon_node.global_position.x, beacon_node.global_position.z) * MAP_SCALE
		map_canvas.draw_dashed_line(p_canvas, b_canvas, Color(0.95, 0.85, 0.15, 0.8), 2.0, 6.0)
		# 2D pulse effect on map beacon target
		var t_sec = float(Time.get_ticks_msec()) / 1000.0
		var pulse_radius = 6.0 + sin(t_sec * 5.0) * 2.5
		var ring_radius = 10.0 + sin(t_sec * 5.0) * 4.0
		var ring_alpha = clampf(0.8 - (ring_radius - 6.0) / 8.0, 0.0, 1.0)
		map_canvas.draw_circle(b_canvas, pulse_radius, Color(0.95, 0.25, 0.15, 0.95))
		map_canvas.draw_arc(b_canvas, ring_radius, 0.0, TAU, 24, Color(0.95, 0.85, 0.2, ring_alpha), 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_set_waypoint_at_screen_pos(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_set_waypoint_at_screen_pos(event.position)

func _set_waypoint_at_screen_pos(screen_pos: Vector2) -> void:
	if not map_canvas: return
	var canvas_rect = map_canvas.get_global_rect()
	if canvas_rect.has_point(screen_pos):
		var local_pos = screen_pos - canvas_rect.position
		var center = map_canvas.size * 0.5
		var rel_pos = local_pos - center
		var world_x = rel_pos.x / MAP_SCALE
		var world_z = rel_pos.y / MAP_SCALE
		
		if not beacon_node:
			beacon_node = get_parent().get_parent().get_node_or_null("WaypointBeacon")
		if beacon_node:
			beacon_node.global_position = Vector3(world_x, 0.0, world_z)
			beacon_node.visible = true
			if map_canvas:
				map_canvas.queue_redraw()

func _process(_delta: float) -> void:
	if not visible or not map_canvas:
		return

	map_canvas.queue_redraw()

	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	var center = map_canvas.size * 0.5

	# Real-world Mindon Town Ward 3 GIS landmark positions
	if hospital_marker:
		# Mindon Township General Hospital compound (-45m, 135m)
		hospital_marker.position = center + Vector2(-45.0, 135.0) * MAP_SCALE - (hospital_marker.size * 0.5)

	if pagoda_marker:
		pagoda_marker.position = center + Vector2(0.0, -25.0) * MAP_SCALE - (pagoda_marker.size * 0.5)

	if market_marker:
		market_marker.position = center + Vector2(-38.0, 32.0) * MAP_SCALE - (market_marker.size * 0.5)

	if stream_marker:
		# Mindon Stream bridge crossing (-534m, -64m)
		stream_marker.position = center + Vector2(-534.0, -64.0) * MAP_SCALE - (stream_marker.size * 0.5)

	if player and player_marker:
		var p_pos = player.global_position
		player_marker.position = center + Vector2(p_pos.x, p_pos.z) * MAP_SCALE - (player_marker.size * 0.5)
		if coords_label:
			# Live real-world GPS coordinates calculation
			var cur_lat = 19.351497 - (p_pos.z / 111139.0)
			var cur_lon = 94.731889 + (p_pos.x / 104860.0)
			coords_label.text = "GPS: %.6f° N, %.6f° E | မင်းတုန်းမြို့ အမှတ်(၃)ရပ်ကွက်" % [cur_lat, cur_lon]