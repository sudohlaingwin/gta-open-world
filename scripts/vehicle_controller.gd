extends VehicleBody3D

@export var max_engine_force: float = 850.0
@export var max_brake_force: float = 80.0
@export var low_speed_steer_angle: float = 0.52
@export var high_speed_steer_angle: float = 0.22
@export var top_speed_ms: float = 28.0

var current_driver: Node3D = null
var is_driven: bool = false
var smoothed_steering: float = 0.0

@onready var driver_seat: Marker3D = $DriverSeat
@onready var interaction_area: Area3D = $InteractionArea
@onready var headlight_beam_l: SpotLight3D = get_node_or_null("HeadlightBeamL")
@onready var headlight_beam_r: SpotLight3D = get_node_or_null("HeadlightBeamR")
@onready var headlight_mesh_l: MeshInstance3D = get_node_or_null("HeadlightL")
@onready var headlight_mesh_r: MeshInstance3D = get_node_or_null("HeadlightR")
@onready var taillight_mesh_l: MeshInstance3D = get_node_or_null("TaillightL")
@onready var taillight_mesh_r: MeshInstance3D = get_node_or_null("TaillightR")

signal driver_entered(driver)
signal driver_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _update_headlights() -> void:
	var dnc = get_tree().get_first_node_in_group("day_night")
	var is_night = false
	if dnc and dnc.has_method("get_daylight"):
		is_night = (dnc.get_daylight() < 0.35)
	var lights_on = is_night or is_driven
	if headlight_beam_l: headlight_beam_l.visible = lights_on
	if headlight_beam_r: headlight_beam_r.visible = lights_on
	if headlight_mesh_l:
		var mat = headlight_mesh_l.get_surface_override_material(0)
		if mat is StandardMaterial3D: mat.emission_enabled = lights_on
	if headlight_mesh_r:
		var mat = headlight_mesh_r.get_surface_override_material(0)
		if mat is StandardMaterial3D: mat.emission_enabled = lights_on
	if taillight_mesh_l:
		var mat = taillight_mesh_l.get_surface_override_material(0)
		if mat is StandardMaterial3D: mat.emission_enabled = lights_on
	if taillight_mesh_r:
		var mat = taillight_mesh_r.get_surface_override_material(0)
		if mat is StandardMaterial3D: mat.emission_enabled = lights_on

func _physics_process(delta: float) -> void:
	_update_headlights()
	if is_driven and current_driver:
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if current_driver.get("touch_input_vector") != null and current_driver.touch_input_vector != Vector2.ZERO:
			input_dir = current_driver.touch_input_vector

		var forward_speed = linear_velocity.dot(-global_transform.basis.z)
		var speed_ratio = clamp(abs(forward_speed) / top_speed_ms, 0.0, 1.0)

		# Speed-Dependent Steering (Agile at low speeds, high-speed stability)
		var target_steer_limit = lerp(low_speed_steer_angle, high_speed_steer_angle, speed_ratio)
		var target_steering = -input_dir.x * target_steer_limit
		smoothed_steering = move_toward(smoothed_steering, target_steering, 8.0 * delta)
		steering = smoothed_steering

		# Progressive Acceleration & Dual-Power Braking
		if input_dir.y < -0.1: # Forward Throttle
			var throttle_curve = lerp(0.65, 1.0, 1.0 - speed_ratio * 0.5)
			engine_force = -input_dir.y * max_engine_force * throttle_curve
			brake = 0.0
		elif input_dir.y > 0.1: # Reverse input / Active Braking
			if forward_speed > 0.5: # Hard forward brake
				brake = input_dir.y * max_brake_force
				engine_force = 0.0
			else: # Reverse gear engages only at near-stop
				brake = 0.0
				engine_force = -input_dir.y * (max_engine_force * 0.45)
		else:
			# Gentle coasting friction (momentum preservation)
			engine_force = 0.0
			brake = 1.2
	else:
		engine_force = 0.0
		brake = 10.0

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