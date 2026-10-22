extends CharacterBody3D

# --- Traditional Myanmar Helicopter (မြန်မာ့ရဟတ်ယာဉ်) ---

@export var max_lift_speed: float = 9.0
@export var max_horizontal_speed: float = 18.0
@export var turn_speed: float = 1.8
@export var lift_accel: float = 8.0
@export var horiz_accel: float = 14.0
@export var air_drag: float = 4.0

var current_pilot: Node3D = null
var is_flying: bool = false
var rotor_speed: float = 0.0
var current_pitch: float = 0.0
var current_roll: float = 0.0

@onready var cockpit_seat: Marker3D = $CockpitSeat
@onready var interaction_area: Area3D = $InteractionArea
@onready var rotor_mesh: MeshInstance3D = $VisualMesh/Rotor
@onready var tail_rotor_mesh: MeshInstance3D = $VisualMesh/TailRotor
@onready var visual_mesh: Node3D = $VisualMesh

signal pilot_entered(pilot)
signal pilot_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if is_flying and current_pilot:
		rotor_speed = move_toward(rotor_speed, 42.0, delta * 15.0)
		
		# Flight controls via touch joystick or arrow keys
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if current_pilot.get("touch_input_vector") != null and current_pilot.touch_input_vector != Vector2.ZERO:
			input_dir = current_pilot.touch_input_vector

		# Vertical climb / descent via sprint or jump
		var vertical_input: float = 0.0
		if current_pilot.get("is_sprinting") == true or Input.is_key_pressed(KEY_SPACE):
			vertical_input = 1.0 # Climb
		elif Input.is_key_pressed(KEY_CTRL):
			vertical_input = -1.0 # Descend

		# Yaw turning
		var yaw_input: float = -input_dir.x * 0.75
		if current_pilot.get("touch_yaw") != null and current_pilot.touch_yaw != 0.0:
			yaw_input = current_pilot.touch_yaw
		rotate_y(yaw_input * turn_speed * delta)

		var forward = -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right = global_transform.basis.x
		right.y = 0.0
		right = right.normalized()

		# Horizontal velocity with smooth acceleration and air drag
		var target_vel_x = (right.x * input_dir.x + forward.x * -input_dir.y) * max_horizontal_speed
		var target_vel_z = (right.z * input_dir.x + forward.z * -input_dir.y) * max_horizontal_speed
		velocity.x = move_toward(velocity.x, target_vel_x, delta * horiz_accel)
		velocity.z = move_toward(velocity.z, target_vel_z, delta * horiz_accel)

		# Vertical lift with progressive spool-dependent climb
		var lift_authority = clampf(rotor_speed / 30.0, 0.0, 1.0)
		var target_lift = vertical_input * max_lift_speed * lift_authority
		velocity.y = move_toward(velocity.y, target_lift, delta * lift_accel)

		# Dynamic visual pitch and roll tilt for realistic flight posture
		var target_pitch = clampf(input_dir.y * 0.25, -0.3, 0.3)
		var target_roll = clampf(-input_dir.x * 0.25, -0.3, 0.3)
		current_pitch = move_toward(current_pitch, target_pitch, delta * 2.5)
		current_roll = move_toward(current_roll, target_roll, delta * 2.5)
		if visual_mesh:
			visual_mesh.rotation.x = current_pitch
			visual_mesh.rotation.z = current_roll

	else:
		rotor_speed = move_toward(rotor_speed, 0.0, delta * 6.0)
		current_pitch = move_toward(current_pitch, 0.0, delta * 3.0)
		current_roll = move_toward(current_roll, 0.0, delta * 3.0)
		if visual_mesh:
			visual_mesh.rotation.x = current_pitch
			visual_mesh.rotation.z = current_roll

		if not is_on_floor():
			velocity.y -= 9.8 * delta
		velocity.x = move_toward(velocity.x, 0.0, delta * air_drag)
		velocity.z = move_toward(velocity.z, 0.0, delta * air_drag)

	if rotor_mesh and rotor_speed > 0.1:
		rotor_mesh.rotate_y(rotor_speed * delta)
	if tail_rotor_mesh and rotor_speed > 0.1:
		tail_rotor_mesh.rotate_x(rotor_speed * 1.5 * delta)

	# Trigger procedural rotor blade chop audio
	if rotor_speed > 2.0:
		var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
		if audio_mgr and audio_mgr.has_method("play_helicopter_rotor"):
			var rpm_factor = clampf(rotor_speed / 42.0, 0.2, 1.4)
			audio_mgr.play_helicopter_rotor(rpm_factor)

	move_and_slide()

func enter_aircraft(pilot: Node3D) -> void:
	if is_flying:
		return
	is_flying = true
	current_pilot = pilot
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
