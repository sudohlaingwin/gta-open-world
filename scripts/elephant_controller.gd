extends CharacterBody3D

# --- Authentic Myanmar Royal & Working Elephant (ဆင်မောင်းနှင်မှုစနစ်) ---

@export var max_speed: float = 6.0
@export var sprint_speed: float = 8.5
@export var accel: float = 5.0
@export var turn_speed: float = 1.6
@export var high_speed_turn_speed: float = 0.8
@export var brake_force: float = 10.0
@export var coast_drag: float = 1.2
@export var steer_response: float = 8.0

var current_rider: Node3D = null
var is_ridden: bool = false
var current_speed: float = 0.0
var steer_smooth: float = 0.0

@onready var howdah_seat: Marker3D = $HowdahSeat
@onready var visual_mesh: Node3D = $VisualMesh
@onready var interaction_area: Area3D = $InteractionArea
@onready var trunk: Node3D = $VisualMesh/Trunk

signal rider_entered(rider)
signal rider_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if is_ridden and current_rider:
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if current_rider.get("touch_input_vector") != null and current_rider.touch_input_vector != Vector2.ZERO:
			input_dir = current_rider.touch_input_vector

		var top_speed = sprint_speed if (current_rider.get("is_sprinting") == true) else max_speed
		var speed_ratio = clampf(abs(current_speed) / top_speed, 0.0, 1.0)

		# Speed-Dependent Steering (Agile at slow pivot, stable at stride)
		var active_turn = lerpf(turn_speed, high_speed_turn_speed, speed_ratio)
		var target_turn = -input_dir.x * active_turn
		steer_smooth = move_toward(steer_smooth, target_turn, steer_response * delta)
		rotate_y(steer_smooth * delta)

		# Progressive Acceleration Curve & Real Active Braking
		var forward = -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()

		if input_dir.y < -0.1: # Forward Throttle
			var curve = 0.55 + 0.45 * (1.0 - speed_ratio * 0.4)
			var target_v = top_speed * (-input_dir.y)
			current_speed = move_toward(current_speed, target_v, accel * curve * delta)
		elif input_dir.y > 0.1: # Reverse or Active Brake
			if current_speed > 0.3: # Real forward brake
				current_speed = move_toward(current_speed, 0.0, brake_force * input_dir.y * delta)
			else: # Reverse gear engages only from standstill
				var target_rev = -top_speed * 0.4 * input_dir.y
				current_speed = move_toward(current_speed, target_rev, accel * 0.6 * delta)
		else: # Gentle coasting drag (heavy elephant kinetic momentum preservation)
			current_speed = move_toward(current_speed, 0.0, coast_drag * delta)

		velocity.x = forward.x * current_speed
		velocity.z = forward.z * current_speed

		# Gentle trunk sway animation & massive footstep impact audio
		if abs(current_speed) > 0.2:
			var sway_rate = 0.005 * (abs(current_speed) / max_speed + 0.5)
			var sway = sin(Time.get_ticks_msec() * sway_rate) * 0.3
			if trunk: trunk.rotation.x = sway
			var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
			if audio_mgr and audio_mgr.has_method("play_elephant_footstep"):
				audio_mgr.play_elephant_footstep()
	else:
		current_speed = move_toward(current_speed, 0.0, coast_drag * 2.0 * delta)
		velocity.x = move_toward(velocity.x, 0.0, coast_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, coast_drag * delta)
		if trunk: trunk.rotation.x = 0.0

	move_and_slide()

func enter_mount(rider: Node3D) -> void:
	if is_ridden:
		return
	is_ridden = true
	current_rider = rider
	current_speed = 0.0
	steer_smooth = 0.0
	rider.reparent(howdah_seat)
	rider.position = Vector3.ZERO
	rider.rotation = Vector3.ZERO
	if rider.has_method("set_riding_state"):
		rider.set_riding_state(true, self)
	var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
	if audio_mgr and audio_mgr.has_method("play_elephant_trumpet"):
		audio_mgr.play_elephant_trumpet()
	rider_entered.emit(rider)

func exit_mount() -> void:
	if not is_ridden or not current_rider:
		return
	var rider = current_rider
	is_ridden = false
	current_rider = null
	current_speed = 0.0
	steer_smooth = 0.0
	var exit_pos = global_position + (global_transform.basis.x * 2.5)
	rider.reparent(get_parent())
	rider.global_position = exit_pos
	if rider.has_method("set_riding_state"):
		rider.set_riding_state(false, null)
	rider_exited.emit()

func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_mount"):
		body.set_interactable_mount(self)

func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_mount"):
		body.set_interactable_mount(null)