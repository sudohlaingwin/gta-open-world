extends CharacterBody3D

@export var max_speed: float = 14.0
@export var acceleration: float = 12.0
@export var brake_decel: float = 22.0
@export var low_speed_turn: float = 2.8
@export var high_speed_turn: float = 1.6

var current_driver: Node3D = null
var is_driven: bool = false
var current_speed: float = 0.0

@onready var driver_seat: Marker3D = $DriverSeat
@onready var visual_mesh: Node3D = $VisualMesh
@onready var interaction_area: Area3D = $InteractionArea
@onready var front_wheel: Node3D = $VisualMesh/FrontWheel
@onready var wheel_bl: Node3D = $VisualMesh/WheelBL
@onready var wheel_br: Node3D = $VisualMesh/WheelBR

signal driver_entered(driver)
signal driver_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if is_driven and current_driver:
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if current_driver.get("touch_input_vector") != null and current_driver.touch_input_vector != Vector2.ZERO:
			input_dir = current_driver.touch_input_vector

		var speed_ratio = clamp(abs(current_speed) / max_speed, 0.0, 1.0)
		var turn_rate = lerp(low_speed_turn, high_speed_turn, speed_ratio)

		# Steer
		rotate_y(-input_dir.x * turn_rate * delta)

		# Progressive Throttle, Active Brake & Coasting
		if input_dir.y < -0.1: # Forward
			var power = lerp(0.7, 1.0, 1.0 - speed_ratio * 0.4)
			current_speed = move_toward(current_speed, max_speed, acceleration * power * delta)
		elif input_dir.y > 0.1: # Brake / Reverse
			if current_speed > 0.5:
				current_speed = move_toward(current_speed, 0.0, brake_decel * delta)
			else:
				current_speed = move_toward(current_speed, -3.5, acceleration * 0.5 * delta)
		else:
			current_speed = move_toward(current_speed, 0.0, 2.5 * delta)

		var forward = -global_transform.basis.z
		velocity.x = forward.x * current_speed
		velocity.z = forward.z * current_speed

		# Triple Wheel Synchronous Rolling
		var spin_rate = (current_speed / 0.35) * delta
		if front_wheel: front_wheel.rotate_object_local(Vector3(0, 1, 0), spin_rate)
		if wheel_bl: wheel_bl.rotate_object_local(Vector3(0, 1, 0), spin_rate)
		if wheel_br: wheel_br.rotate_object_local(Vector3(0, 1, 0), spin_rate)
	else:
		current_speed = move_toward(current_speed, 0.0, 4.0 * delta)
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)

	move_and_slide()

func enter_vehicle(driver: Node3D) -> void:
	if is_driven:
		return
	is_driven = true
	current_driver = driver
	driver.reparent(driver_seat)
	driver.position = Vector3.ZERO
	driver.rotation = Vector3.ZERO
	if driver.has_method("set_driving_state"):
		driver.set_driving_state(true, self)
	driver_entered.emit(driver)

func exit_vehicle() -> void:
	if not is_driven or not current_driver:
		return
	var driver = current_driver
	is_driven = false
	current_driver = null
	var exit_pos = global_position + (global_transform.basis.x * 2.0)
	driver.reparent(get_parent())
	driver.global_position = exit_pos
	if driver.has_method("set_driving_state"):
		driver.set_driving_state(false, null)
	driver_exited.emit()

func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_vehicle"):
		body.set_interactable_vehicle(self)

func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_vehicle"):
		body.set_interactable_vehicle(null)