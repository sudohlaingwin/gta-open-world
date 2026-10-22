extends Node3D

@export var touch_sensitivity: float = 0.005
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 0.8
@export var max_zoom: float = 4.0
@export var shorten_speed: float = 24.0
@export var recovery_speed: float = 4.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var target_arm_length: float = 2.4
var current_arm_length: float = 2.4

func _ready() -> void:
	if spring_arm:
		spring_arm.spring_length = target_arm_length
		spring_arm.margin = 0.25

func _physics_process(delta: float) -> void:
	if not spring_arm or not camera:
		return

	# Raycast obstruction clearance
	var space_state = get_world_3d().direct_space_state
	var origin_pos = global_position
	var cam_dir = (camera.global_position - origin_pos).normalized()
	var query = PhysicsRayQueryParameters3D.create(origin_pos, origin_pos + cam_dir * target_arm_length)
	
	# Exclude player from raycast
	var player = get_parent()
	if player:
		query.exclude = [player.get_rid()]

	var result = space_state.intersect_ray(query)
	var desired_length = target_arm_length

	if not result.is_empty():
		var hit_dist = origin_pos.distance_to(result.position) - 0.2
		desired_length = clamp(hit_dist, min_zoom, target_arm_length)

	# Asymmetric smoothing: Snap fast inwards on wall collision, smoothly drift outwards on clearance
	if desired_length < current_arm_length:
		current_arm_length = move_toward(current_arm_length, desired_length, shorten_speed * delta)
	else:
		current_arm_length = move_toward(current_arm_length, desired_length, recovery_speed * delta)

	spring_arm.spring_length = current_arm_length

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if event.position.x > get_viewport().size.x * 0.4:
			var sens = touch_sensitivity
			var sm = get_node_or_null("/root/SaveManager")
			if sm and sm.get("camera_sensitivity") != null:
				sens *= sm.camera_sensitivity
			rotation.y -= event.relative.x * sens
			rotation.x -= event.relative.y * sens
			var pitch_min = -70.0
			var pitch_max = 25.0
			if sm and sm.get("game_mode") == "mlbb":
				pitch_min = -60.0
				pitch_max = -20.0
			rotation.x = clamp(rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))