extends CharacterBody3D

# --- Flight System for Airplanes & Helicopters (လေယာဉ်မျိုးစုံ မောင်းနှင်သည့် စနစ်) ---

@export var max_thrust: float = 30.0
@export var lift_coefficient: float = 1.2
@export var pitch_speed: float = 1.5
@export var roll_speed: float = 2.0
@export var yaw_speed: float = 0.8
@export var stall_speed: float = 8.0

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
		# Ground idle or natural gravity drop
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		move_and_slide()
		return

	# Pilot flight controls
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if current_pilot.get("touch_input_vector") != null and current_pilot.touch_input_vector != Vector2.ZERO:
		input_dir = current_pilot.touch_input_vector

	# Throttle up / down (Auto-accelerate forward when flying)
	throttle = clamp(throttle + delta * 0.4, 0.0, 1.0)
	var forward = -global_transform.basis.z

	# Pitch (Up/Down) & Roll (Tilt) & Yaw
	rotate_object_local(Vector3.RIGHT, -input_dir.y * pitch_speed * delta)
	rotate_object_local(Vector3.FORWARD, -input_dir.x * roll_speed * delta)
	rotate_y(-input_dir.x * yaw_speed * delta)

	# Aerodynamic Thrust and Lift
	var forward_speed = velocity.dot(forward)
	var thrust = forward * (throttle * max_thrust)
	var lift = Vector3.UP * (max(0.0, forward_speed) * lift_coefficient)
	var gravity_force = Vector3.DOWN * 9.8

	velocity += (thrust + lift + gravity_force) * delta
	velocity = velocity.limit_length(50.0) # Speed cap for mobile

	move_and_slide()

func enter_aircraft(pilot: Node3D) -> void:
	if is_flying:
		return
	is_flying = true
	current_pilot = pilot
	throttle = 0.3
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
