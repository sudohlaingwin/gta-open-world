extends CharacterBody3D

# --- Authentic Myanmar Rideable Mount & Bullock Cart Controller ---

enum MountType { COW, BULLOCK_CART, HORSE }
@export var mount_type: MountType = MountType.COW

@export var walk_speed: float = 3.6
@export var trot_speed: float = 6.4
@export var turn_speed: float = 2.8

var current_rider: Node3D = null
var is_mounted: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var smoothed_turn: float = 0.0

@onready var saddle_point: Marker3D = $SaddlePoint
@onready var visual_mesh: Node3D = $VisualMesh
@onready var interaction_area: Area3D = $InteractionArea

# Legs & Wheels for physical rolling / walking animation
var legs: Array = []
var wheels: Array = []

signal mount_entered(rider)
signal mount_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

	for leg_name in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var l = visual_mesh.get_node_or_null(leg_name)
		if l:
			legs.append(l)

	for wheel_name in ["WheelLeft", "WheelRight"]:
		var w = visual_mesh.get_node_or_null(wheel_name)
		if w:
			wheels.append(w)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_mounted and current_rider:
		# Process rider driving inputs
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		# Read touch joystick vector directly from rider
		if current_rider.get("touch_input_vector") != null and current_rider.touch_input_vector != Vector2.ZERO:
			input_dir = current_rider.touch_input_vector

		# Smooth steering rotation
		var target_turn = -input_dir.x * turn_speed
		smoothed_turn = move_toward(smoothed_turn, target_turn, 8.0 * delta)
		rotate_y(smoothed_turn * delta)

		# Forward / Backward movement
		var forward = -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()

		# Sprint check via rider's is_sprinting state or physical Shift key
		var is_sprinting = (current_rider.get("is_sprinting") == true) or Input.is_key_pressed(KEY_SHIFT)
		var speed = trot_speed if is_sprinting else walk_speed
		
		var move_speed: float = 0.0
		if input_dir.y < -0.1: # Forward
			move_speed = speed * (-input_dir.y)
			velocity.x = forward.x * move_speed
			velocity.z = forward.z * move_speed
		elif input_dir.y > 0.1: # Backward / Reverse
			move_speed = -speed * 0.45 * input_dir.y
			velocity.x = forward.x * move_speed
			velocity.z = forward.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed * 2.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, speed * 2.0 * delta)

		move_and_slide()

		# 1. Wheels rotation on ground speed (for bullock carts)
		var actual_speed = Vector2(velocity.x, velocity.z).length()
		for w in wheels:
			w.rotate_object_local(Vector3(0, 1, 0), (actual_speed / 0.8) * delta * (1.0 if move_speed >= 0 else -1.0))
		if wheels.size() > 0 and actual_speed > 0.5:
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_cart_wheel_creak"):
				am.play_cart_wheel_creak()

		# 2. Leg stride animation (for rideable cow)
		if legs.size() >= 4 and actual_speed > 0.2:
			var leg_phase = sin(Time.get_ticks_msec() * 0.008 * (actual_speed / walk_speed)) * 0.35
			legs[0].rotation.x = leg_phase
			legs[1].rotation.x = -leg_phase
			legs[2].rotation.x = -leg_phase
			legs[3].rotation.x = leg_phase
	else:
		velocity.x = move_toward(velocity.x, 0.0, 3.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 3.0 * delta)
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
