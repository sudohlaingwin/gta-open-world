extends CharacterBody3D

# --- Realistic Airplane Flight Dynamics & Airspace System ---

@export var max_thrust: float = 35.0
@export var lift_coefficient: float = 1.4
@export var stall_speed: float = 8.0
@export var air_drag: float = 3.0
@export var low_pitch_rate: float = 1.8
@export var high_pitch_rate: float = 0.9
@export var low_roll_rate: float = 2.4
@export var high_roll_rate: float = 1.2
@export var low_yaw_rate: float = 1.2
@export var high_yaw_rate: float = 0.5
@export var steer_response: float = 8.0

var current_pilot: Node3D = null
var is_flying: bool = false
var throttle: float = 0.0
var pitch_smooth: float = 0.0
var roll_smooth: float = 0.0
var yaw_smooth: float = 0.0

@onready var cockpit_seat: Marker3D = $CockpitSeat
@onready var interaction_area: Area3D = $InteractionArea
@onready var visual_mesh: Node3D = $VisualMesh
@onready var propeller_mesh: MeshInstance3D = get_node_or_null("VisualMesh/Propeller")

signal pilot_entered(pilot)
signal pilot_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _spool_curve(speed_ratio: float) -> float:
	if speed_ratio < 0.3:
		return 0.55 + 0.45 * (speed_ratio / 0.3)
	return 1.0 - 0.5 * ((speed_ratio - 0.3) / 0.7)

func _physics_process(delta: float) -> void:
	if not is_flying or not current_pilot:
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		move_and_slide()
		return

	var forward = -global_transform.basis.z
	var forward_speed = velocity.dot(forward)
	var speed_ratio = clampf(abs(forward_speed) / 50.0, 0.0, 1.0)

	# Pilot flight controls via Touch Joystick or Arrow/WASD keys
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if current_pilot.get("touch_input_vector") != null and current_pilot.touch_input_vector != Vector2.ZERO:
		input_dir = current_pilot.touch_input_vector

	# Throttle Management with Progressive Spool Curve
	var spool = _spool_curve(speed_ratio)
	if current_pilot.get("is_sprinting") == true:
		throttle = clamp(throttle + delta * 0.4 * spool, 0.0, 1.0)
	elif input_dir.y > 0.5:
		throttle = clamp(throttle - delta * 0.35 * spool, 0.0, 1.0)

	# Control Smoothing and Speed-Dependent Authority
	pitch_smooth = move_toward(pitch_smooth, -input_dir.y, steer_response * delta)
	roll_smooth = move_toward(roll_smooth, -input_dir.x, steer_response * delta)

	var pitch_rate = lerpf(low_pitch_rate, high_pitch_rate, speed_ratio)
	var roll_rate = lerpf(low_roll_rate, high_roll_rate, speed_ratio)
	var yaw_rate = lerpf(low_yaw_rate, high_yaw_rate, speed_ratio)

	rotate_object_local(Vector3.RIGHT, pitch_smooth * pitch_rate * delta)
	rotate_object_local(Vector3.FORWARD, roll_smooth * roll_rate * delta)

	# Dedicated Independent Yaw + Coordinated Rudder Bank
	var explicit_yaw: float = 0.0
	if current_pilot.get("touch_yaw") != null:
		explicit_yaw = current_pilot.touch_yaw
	if abs(explicit_yaw) > 0.05:
		yaw_smooth = move_toward(yaw_smooth, -explicit_yaw, steer_response * delta)
		rotate_y(yaw_smooth * yaw_rate * delta)
	else:
		rotate_y(roll_smooth * (yaw_rate * 0.4) * delta)

	# Propeller spin dynamically scaled with engine throttle
	if propeller_mesh:
		propeller_mesh.rotate_z(30.0 * (0.2 + 0.8 * throttle) * delta)

	# Trigger procedural engine roar audio
	var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
	if audio_mgr and audio_mgr.has_method("play_airplane_engine"):
		audio_mgr.play_airplane_engine(throttle)

	# Aerodynamic Stall & Lift Calculation
	var thrust = forward * (throttle * max_thrust)
	var lift: Vector3
	if forward_speed < stall_speed:
		var stall_factor = clamp(forward_speed / stall_speed, 0.0, 1.0)
		lift = Vector3.UP * (forward_speed * lift_coefficient * stall_factor)
		if forward_speed > 2.0:
			rotate_object_local(Vector3.RIGHT, deg_to_rad(12.0 * delta)) # Stall nose drop
	else:
		lift = Vector3.UP * (forward_speed * lift_coefficient)

	var gravity_force = Vector3.DOWN * 9.8
	velocity += (thrust + lift + gravity_force) * delta

	# Real Air Drag (throttle cut naturally decelerates the aircraft)
	velocity = velocity.move_toward(Vector3.ZERO, air_drag * delta)
	velocity = velocity.limit_length(50.0)

	move_and_slide()

func enter_aircraft(pilot: Node3D) -> void:
	if is_flying:
		return
	is_flying = true
	current_pilot = pilot
	throttle = 0.5
	pitch_smooth = 0.0
	roll_smooth = 0.0
	yaw_smooth = 0.0
	pilot.reparent(cockpit_seat)
	pilot.position = Vector3.ZERO
	pilot.rotation = Vector3.ZERO
	if pilot.has_method("set_flying_state"):
		pilot.set_flying_state(true, self)
	pilot_entered.emit(pilot)

func exit_aircraft() -> void:
	if not is_flying or not current_pilot:
		return
	var pilot = current_pilot
	is_flying = false
	current_pilot = null
	pitch_smooth = 0.0
	roll_smooth = 0.0
	yaw_smooth = 0.0
	var exit_pos = global_position + (global_transform.basis.x * 3.0)
	pilot.reparent(get_parent())
	pilot.global_position = exit_pos
	if pilot.has_method("set_flying_state"):
		pilot.set_flying_state(false, null)
	pilot_exited.emit()

func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_aircraft"):
		body.set_interactable_aircraft(self)

func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_aircraft"):
		body.set_interactable_aircraft(null)
