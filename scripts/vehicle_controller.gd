extends VehicleBody3D

# --- Vehicle Driving System (ကား / ဆိုင်ကယ် မောင်းနှင်သည့် စနစ်) ---

@export var max_engine_force: float = 350.0
@export var max_brake_force: float = 25.0
@export var max_steer_angle: float = 0.5

var current_driver: Node3D = null
var is_driven: bool = false

@onready var driver_seat: Marker3D = $DriverSeat
@onready var interaction_area: Area3D = $InteractionArea

signal driver_entered(driver)
signal driver_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if is_driven and current_driver:
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if current_driver.get("touch_input_vector") != null and current_driver.touch_input_vector != Vector2.ZERO:
			input_dir = current_driver.touch_input_vector

		# Steering
		steering = move_toward(steering, -input_dir.x * max_steer_angle, delta * 2.5)

		# Acceleration and Brake
		if input_dir.y < -0.1: # Forward
			engine_force = -input_dir.y * max_engine_force
			brake = 0.0
		elif input_dir.y > 0.1: # Reverse / Brake
			if linear_velocity.dot(-global_transform.basis.z) > 0.5:
				brake = input_dir.y * max_brake_force
				engine_force = 0.0
			else:
				brake = 0.0
				engine_force = -input_dir.y * (max_engine_force * 0.5)
		else:
			engine_force = 0.0
			brake = 2.0
	else:
		engine_force = 0.0
		brake = 5.0

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
