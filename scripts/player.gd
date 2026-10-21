extends CharacterBody3D

# --- Character Stats ---
@export var speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.8
@export var rotation_speed: float = 12.0

# --- Gravity & Physics ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting: bool = false

# --- Mobile Touch Controls Support ---
var touch_input_vector: Vector2 = Vector2.ZERO

@onready var visual_mesh: Node3D = $VisualMesh
@onready var camera_pivot: Node3D = $CameraPivot

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Gather input direction from keyboard or mobile touch joystick
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if touch_input_vector != Vector2.ZERO:
		input_dir = touch_input_vector

	# Calculate movement direction relative to camera angle
	var camera_basis = camera_pivot.global_transform.basis
	var forward = -camera_basis.z
	var right = camera_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var direction: Vector3 = (right * input_dir.x + forward * -input_dir.y).normalized()
	var current_speed: float = sprint_speed if is_sprinting else speed

	if direction.length() > 0.05:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		# Smooth character rotation facing moving direction
		var target_angle = atan2(direction.x, direction.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity

func set_sprint(sprint: bool) -> void:
	is_sprinting = sprint
