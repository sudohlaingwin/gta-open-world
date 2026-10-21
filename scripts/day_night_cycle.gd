extends Node3D

# Simple Open World Day/Night Sun Rotation Cycle
@export var day_length_seconds: float = 120.0 # 2 minutes full cycle
@onready var sun: DirectionalLight3D = $SunLight

func _process(delta: float) -> void:
	if sun:
		var rotation_rate = 360.0 / day_length_seconds
		sun.rotate_x(deg_to_rad(rotation_rate * delta))
