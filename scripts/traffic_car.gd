extends Node3D

@export var speed: float = 6.0
@export var turn_speed: float = 2.5
var waypoints: Array[Vector3] = []
var current_wp_idx: int = 0
var is_stopped: bool = false
var blocked_timer: float = 0.0

@onready var wheel_fl: Node3D = $VisualMesh/WheelFL
@onready var wheel_fr: Node3D = $VisualMesh/WheelFR
@onready var wheel_bl: Node3D = $VisualMesh/WheelBL
@onready var wheel_br: Node3D = $VisualMesh/WheelBR
@onready var headlights: Node3D = $VisualMesh/Headlights

func _ready() -> void:
	add_to_group("traffic_cars")

func _physics_process(delta: float) -> void:
	if waypoints.is_empty():
		return

	# Obstacle perception check (stop-only forward cone)
	_check_obstacles()

	if is_stopped:
		blocked_timer += delta
		if blocked_timer > 15.0:
			# Stuck timeout respawn
			_respawn_at_next_waypoint()
		return
	else:
		blocked_timer = 0.0

	var target = waypoints[current_wp_idx]
	var dir = (target - global_position)
	dir.y = 0.0

	if dir.length() < 1.8:
		current_wp_idx = (current_wp_idx + 1) % waypoints.size()
	else:
		var move_dir = dir.normalized()
		var target_rot = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, turn_speed * delta)
		
		var forward = -global_transform.basis.z
		global_position += forward * speed * delta

		# Rolling wheel spin
		var spin = (speed / 0.35) * delta
		if wheel_fl: wheel_fl.rotate_x(spin)
		if wheel_fr: wheel_fr.rotate_x(spin)
		if wheel_bl: wheel_bl.rotate_x(spin)
		if wheel_br: wheel_br.rotate_x(spin)

func _check_obstacles() -> void:
	var forward = -global_transform.basis.z
	var stop = false

	# Check player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var p_diff = player.global_position - global_position
		p_diff.y = 0.0
		var p_dist = p_diff.length()
		if p_dist < 2.5 or (p_dist < 6.0 and forward.dot(p_diff.normalized()) > 0.65):
			stop = true

	# Check other traffic cars
	if not stop:
		var others = get_tree().get_nodes_in_group("traffic_cars")
		for car in others:
			if car != self:
				var c_diff = car.global_position - global_position
				c_diff.y = 0.0
				var c_dist = c_diff.length()
				if c_dist < 2.5 or (c_dist < 5.5 and forward.dot(c_diff.normalized()) > 0.7):
					stop = true
					break

	# Check villagers
	if not stop:
		var villagers = get_tree().get_nodes_in_group("villagers")
		for v in villagers:
			var v_diff = v.global_position - global_position
			v_diff.y = 0.0
			var v_dist = v_diff.length()
			if v_dist < 2.5 or (v_dist < 5.0 and forward.dot(v_diff.normalized()) > 0.7):
				stop = true
				break

	is_stopped = stop

func _respawn_at_next_waypoint() -> void:
	blocked_timer = 0.0
	current_wp_idx = (current_wp_idx + 2) % waypoints.size()
	global_position = waypoints[current_wp_idx]