extends Control

@onready var close_btn: Button = $Panel/CloseBtn
@onready var map_canvas: Control = $Panel/MapCanvas
@onready var player_marker: ColorRect = $Panel/MapCanvas/PlayerMarker
@onready var pagoda_marker: ColorRect = $Panel/MapCanvas/PagodaMarker
@onready var market_marker: ColorRect = $Panel/MapCanvas/MarketMarker
@onready var pier_marker: ColorRect = $Panel/MapCanvas/PierMarker

var player: CharacterBody3D = null

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): visible = false; get_tree().paused = false)

func _process(delta: float) -> void:
	if not visible:
		return

	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	var canvas_size = map_canvas.size
	var center = canvas_size / 2.0
	var scale_factor = 4.5 # Map scale: 1m in world = 4.5px on map

	# Update Landmarks
	if pagoda_marker:
		pagoda_marker.position = center + Vector2(0, -25) * scale_factor - Vector2(8, 8)
	if market_marker:
		market_marker.position = center + Vector2(-38, 32) * scale_factor - Vector2(6, 6)
	if pier_marker:
		pier_marker.position = center + Vector2(-18, 24) * scale_factor - Vector2(6, 6)

	# Update Player Position
	if player and player_marker:
		var p_pos = player.global_position
		player_marker.position = center + Vector2(p_pos.x, p_pos.z) * scale_factor - Vector2(7, 7)