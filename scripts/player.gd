extends CharacterBody3D

# --- Character Stats ---
@export var speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.8
@export var rotation_speed: float = 12.0

# --- State Management ---
enum State { ON_FOOT, RIDING_MOUNT, DRIVING_VEHICLE }
var current_state: State = State.ON_FOOT

var active_mount: Node3D = null
var nearby_mount: Node3D = null

var active_vehicle: Node3D = null
var nearby_vehicle: Node3D = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting: bool = false
var touch_input_vector: Vector2 = Vector2.ZERO

@onready var visual_mesh: Node3D = $VisualMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: Node3D = $CameraPivot

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if current_state != State.ON_FOOT:
		# When riding a mount or driving, movement is handled by the mount/vehicle
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Direction input
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if touch_input_vector != Vector2.ZERO:
		input_dir = touch_input_vector

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
		var target_angle = atan2(direction.x, direction.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

# --- Mount & Vehicle Interactions ---

func interact() -> void:
	if current_state == State.RIDING_MOUNT and active_mount:
		active_mount.dismount()
	elif current_state == State.DRIVING_VEHICLE and active_vehicle:
		active_vehicle.exit_vehicle()
	elif nearby_mount:
		nearby_mount.mount(self)
	elif nearby_vehicle:
		nearby_vehicle.enter_vehicle(self)

func set_mounted_state(mounted: bool, mount_node: Node3D) -> void:
	if mounted:
		current_state = State.RIDING_MOUNT
		active_mount = mount_node
		collision_shape.disabled = true
	else:
		current_state = State.ON_FOOT
		active_mount = null
		collision_shape.disabled = false

func set_driving_state(driving: bool, vehicle_node: Node3D) -> void:
	if driving:
		current_state = State.DRIVING_VEHICLE
		active_vehicle = vehicle_node
		collision_shape.disabled = true
	else:
		current_state = State.ON_FOOT
		active_vehicle = null
		collision_shape.disabled = false

func set_interactable_mount(mount_node: Node3D) -> void:
	nearby_mount = mount_node

func set_interactable_vehicle(vehicle_node: Node3D) -> void:
	nearby_vehicle = vehicle_node

func jump() -> void:
	if current_state == State.ON_FOOT and is_on_floor():
		velocity.y = jump_velocity

func set_sprint(sprint: bool) -> void:
	is_sprinting = sprint
