extends CharacterBody3D

# --- Authentic Myanmar Royal & Working Elephant (ဆင်မောင်းနှင်မှုစနစ်) ---

@export var max_speed: float = 6.0
@export var sprint_speed: float = 9.0
@export var acceleration: float = 8.0
@export var turn_speed: float = 1.6

var current_rider: Node3D = null
var is_ridden: bool = false
var current_speed: float = 0.0

@onready var howdah_seat: Marker3D = $HowdahSeat
@onready var visual_mesh: Node3D = $VisualMesh
@onready var interaction_area: Area3D = $InteractionArea
@onready var trunk: Node3D = $VisualMesh/Trunk

signal rider_entered(rider)
signal rider_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if is_ridden and current_rider:
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if current_rider.get("touch_input_vector") != null and current_rider.touch_input_vector != Vector2.ZERO:
			input_dir = current_rider.touch_input_vector

		rotate_y(-input_dir.x * turn_speed * delta)

		var top_speed = sprint_speed if (current_rider.get("is_sprinting") == true) else max_speed
		var target_speed = -input_dir.y * top_speed
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)

		var forward = -global_transform.basis.z
		velocity.x = forward.x * current_speed
		velocity.z = forward.z * current_speed

		# Gentle trunk sway animation
		if abs(current_speed) > 0.2:
			var sway = sin(Time.get_ticks_msec() * 0.005) * 0.3
			if trunk: trunk.rotation.x = sway
	else:
		current_speed = move_toward(current_speed, 0.0, acceleration * 2.0 * delta)
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		if trunk: trunk.rotation.x = 0.0

	move_and_slide()

func enter_mount(rider: Node3D) -> void:
	if is_ridden:
		return
	is_ridden = true
	current_rider = rider
	rider.reparent(howdah_seat)
	rider.position = Vector3.ZERO
	rider.rotation = Vector3.ZERO
	if rider.has_method("set_riding_state"):
		rider.set_riding_state(true, self)
	rider_entered.emit(rider)

func exit_mount() -> void:
	if not is_ridden or not current_rider:
		return
	var rider = current_rider
	is_ridden = false
	current_rider = null
	var exit_pos = global_position + (global_transform.basis.x * 2.5)
	rider.reparent(get_parent())
	rider.global_position = exit_pos
	if rider.has_method("set_riding_state"):
		rider.set_riding_state(false, null)
	rider_exited.emit()

func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_mount"):
		body.set_interactable_mount(self)

func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_mount"):
		body.set_interactable_mount(null)