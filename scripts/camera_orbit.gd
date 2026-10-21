extends Node3D

# Mobile Touch Camera Orbit & Pinch-Zoom Controller
@export var touch_sensitivity: float = 0.005
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 2.5
@export var max_zoom: float = 12.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var touch_drag_index: int = -1

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		# Touch swipe on right half of screen rotates the camera
		if event.position.x > get_viewport().size.x * 0.4:
			rotation.y -= event.relative.x * touch_sensitivity
			rotation.x -= event.relative.y * touch_sensitivity
			rotation.x = clamp(rotation.x, deg_to_rad(-65), deg_to_rad(30))
