extends CharacterBody3D

# --- Realistic Airplane Flight Dynamics & Airspace System ---

@export var max_thrust: float = 35.0
@export var lift_coefficient: float = 1.4
@export var pitch_speed: float = 1.6
@export var roll_speed: float = 2.2
@export var yaw_speed: float = 0.9
@export var stall_speed: float = 9.0

var current_pilot: Node3D = null
var is_flying: bool = false
var throttle: float = 0.0

@onready var cockpit_seat: Marker3D = $CockpitSeat
@onready var interaction_area: Area3D = $InteractionArea

signal pilot_entered(pilot)
signal pilot_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if not is_flying or not current_pilot:
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		move_and_slide()
		return

	# Pilot flight controls via Touch Joystick or Arrow/WASD keys
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if current_pilot.get("touch_input_vector") != null and current_pilot.touch_input_vector != Vector2.ZERO:
		input_dir = current_pilot.touch_input_vector

	# Explicit Pilot Throttle Management (Sprint increases throttle, normal holds cruise)
	if current_pilot.get("is_sprinting") == true:
		throttle = clamp(throttle + delta * 0.5, 0.0, 1.0)
	else:
		throttle = clamp(throttle - delta * 0.15, 0.35, 1.0) # Stable cruise throttle

	var forward = -global_transform.basis.z
	var forward_speed = velocity.dot(forward)

	# Dedicated Decoupled Controls:
	# Y axis -> Pitch (Nose Up/Down)
	# X axis -> Bank Roll, with aerodynamic natural Yaw turning
	rotate_object_local(Vector3.RIGHT, -input_dir.y * pitch_speed * delta)
	rotate_object_local(Vector3.FORWARD, -input_dir.x * roll_speed * delta)
	rotate_y(-input_dir.x * yaw_speed * delta * 0.4) # Coordinated turn

	# Aerodynamic Stall Physics Calculation
	var thrust = forward * (throttle * max_thrust)
	var lift: Vector3
	if forward_speed < stall_speed:
		# Airflow separation stall: Lift drops sharply and nose falls
		var stall_factor = clamp(forward_speed / stall_speed, 0.1, 1.0)
		lift = Vector3.UP * (forward_speed * lift_coefficient * stall_factor)
		rotate_object_local(Vector3.RIGHT, deg_to_rad(15.0 * delta)) # Natural stall nose drop
	else:
		lift = Vector3.UP * (forward_speed * lift_coefficient)

	var gravity_force = Vector3.DOWN * 9.8
	velocity += (thrust + lift + gravity_force) * delta
	velocity = velocity.limit_length(60.0)

	move_and_slide()

func enter_aircraft(pilot: Node3D) -> void:
	if is_flying:
		return
	is_flying = true
	current_pilot = pilot
	throttle = 0.5
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
