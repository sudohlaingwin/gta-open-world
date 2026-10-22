extends Control

@onready var close_btn: Button = $Panel/CloseBtn
@onready var map_canvas: Control = $Panel/MapCanvas
@onready var player_marker: ColorRect = $Panel/MapCanvas/PlayerMarker
@onready var pagoda_marker: ColorRect = $Panel/MapCanvas/PagodaMarker
@onready var market_marker: ColorRect = $Panel/MapCanvas/MarketMarker
@onready var pier_marker: ColorRect = $Panel/MapCanvas/PierMarker

var player: CharacterBody3D = null
var beacon_node: Node3D = null

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
		var center = map_canvas.size / 2.0
		var rel_pos = local_pos - center
		var scale_factor = 4.5
		var world_x = rel_pos.x / scale_factor
		var world_z = rel_pos.y / scale_factor
		
		if not beacon_node:
			beacon_node = get_parent().get_parent().get_node_or_null("WaypointBeacon")
		if beacon_node:
			beacon_node.global_position = Vector3(world_x, 0.0, world_z)
			beacon_node.visible = true

func _process(delta: float) -> void:
	if not visible:
		return

	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	var canvas_size = map_canvas.size
	var center = canvas_size / 2.0
	var scale_factor = 4.5

	if pagoda_marker:
		pagoda_marker.position = center + Vector2(0, -25) * scale_factor - Vector2(8, 8)
	if market_marker:
		market_marker.position = center + Vector2(-38, 32) * scale_factor - Vector2(6, 6)
	if pier_marker:
		pier_marker.position = center + Vector2(-18, 24) * scale_factor - Vector2(6, 6)

	if player and player_marker:
		var p_pos = player.global_position
		player_marker.position = center + Vector2(p_pos.x, p_pos.z) * scale_factor - Vector2(7, 7)