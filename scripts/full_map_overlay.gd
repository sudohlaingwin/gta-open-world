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

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): visible = false; get_tree().paused = false)
	beacon_node = get_tree().get_first_node_in_group("waypoint_beacon")
	if not beacon_node:
		beacon_node = get_parent().get_parent().get_node_or_null("WaypointBeacon")

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

func _process(_delta: float) -> void:
	if not visible or not map_canvas:
		return

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