extends CharacterBody3D

# --- Rideable Mount & Bullock Cart System (မြန်မာ့ရိုးရာ လှည်းနှင့်နွား စနစ်) ---

enum MountType { COW, BULLOCK_CART, HORSE }
@export var mount_type: MountType = MountType.COW

@export var walk_speed: float = 4.0
@export var trot_speed: float = 7.0
@export var turn_speed: float = 3.5

var current_rider: Node3D = null
var is_mounted: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var saddle_point: Marker3D = $SaddlePoint
@onready var visual_mesh: Node3D = $VisualMesh
@onready var interaction_area: Area3D = $InteractionArea

signal mount_entered(rider)
signal mount_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_mounted and current_rider:
		# Process rider driving inputs
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		# Read touch joystick vector directly from rider
		if current_rider.get("touch_input_vector") != null and current_rider.touch_input_vector != Vector2.ZERO:
			input_dir = current_rider.touch_input_vector

		# Steering rotation
		if abs(input_dir.x) > 0.1:
			rotate_y(-input_dir.x * turn_speed * delta)

		# Forward / Backward movement
		var forward = -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()

		# Sprint check via rider's is_sprinting state or physical Shift key (no undefined action)
		var is_sprinting = (current_rider.get("is_sprinting") == true) or Input.is_key_pressed(KEY_SHIFT)
		var speed = trot_speed if is_sprinting else walk_speed
		
		if input_dir.y < -0.1: # Forward
			velocity.x = forward.x * speed
			velocity.z = forward.z * speed
		elif input_dir.y > 0.1: # Backward / Reverse
			velocity.x = -forward.x * (speed * 0.5)
			velocity.z = -forward.z * (speed * 0.5)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

		move_and_slide()
	else:
		velocity.x = move_toward(velocity.x, 0, 2.0)
		velocity.z = move_toward(velocity.z, 0, 2.0)
		move_and_slide()

func mount(rider: Node3D) -> void:
	if is_mounted:
		return
	is_mounted = true
	current_rider = rider
	rider.reparent(saddle_point)
	rider.position = Vector3.ZERO
	rider.rotation = Vector3.ZERO
	if rider.has_method("set_mounted_state"):
		rider.set_mounted_state(true, self)
	mount_entered.emit(rider)

func dismount() -> void:
	if not is_mounted or not current_rider:
		return
	var rider = current_rider
	is_mounted = false
	current_rider = null
	var dismount_pos = global_position + (global_transform.basis.x * 1.5)
	rider.reparent(get_parent())
	rider.global_position = dismount_pos
	if rider.has_method("set_mounted_state"):
		rider.set_mounted_state(false, null)
	mount_exited.emit()

func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_mount"):
		body.set_interactable_mount(self)

func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_mount"):
		body.set_interactable_mount(null)
