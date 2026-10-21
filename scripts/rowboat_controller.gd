extends CharacterBody3D

# --- Authentic Myanmar Ayeyarwady Traditional Rowboat (သမ္ဗာန်လှေ) ---

@export var max_speed: float = 6.5
@export var acceleration: float = 4.0
@export var turn_speed: float = 1.8

var current_rower: Node3D = null
var is_rowing: bool = false
var current_speed: float = 0.0

@onready var rower_seat: Marker3D = $RowerSeat
@onready var interaction_area: Area3D = $InteractionArea
@onready var oar_left: Node3D = $VisualMesh/OarL
@onready var oar_right: Node3D = $VisualMesh/OarR

signal rower_entered(rower)
signal rower_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	if is_rowing and current_rower:
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if current_rower.get("touch_input_vector") != null and current_rower.touch_input_vector != Vector2.ZERO:
			input_dir = current_rower.touch_input_vector

		# Steer Rowboat
		rotate_y(-input_dir.x * turn_speed * delta)

		# Forward / Backward
		var target_speed = -input_dir.y * max_speed
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)

		var forward = -global_transform.basis.z
		velocity.x = forward.x * current_speed
		velocity.z = forward.z * current_speed

		# Oar rowing animation
		if abs(current_speed) > 0.2:
			var oar_angle = sin(Time.get_ticks_msec() * 0.006) * 0.4
			if oar_left: oar_left.rotation.y = oar_angle
			if oar_right: oar_right.rotation.y = -oar_angle
	else:
		current_speed = move_toward(current_speed, 0.0, acceleration * 2.0 * delta)
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	# Gentle water buoyancy bobbing
	velocity.y = sin(Time.get_ticks_msec() * 0.003) * 0.2

	move_and_slide()

func enter_vehicle(rower: Node3D) -> void:
	if is_rowing:
		return
	is_rowing = true
	current_rower = rower
	rower.reparent(rower_seat)
	rower.position = Vector3.ZERO
	rower.rotation = Vector3.ZERO
	if rower.has_method("set_driving_state"):
		rower.set_driving_state(true, self)
	rower_entered.emit(rower)

func exit_vehicle() -> void:
	if not is_rowing or not current_rower:
		return
	var rower = current_rower
	is_rowing = false
	current_rower = null
	var exit_pos = global_position + (global_transform.basis.x * 2.0)
	rower.reparent(get_parent())
	rower.global_position = exit_pos
	if rower.has_method("set_driving_state"):
		rower.set_driving_state(false, null)
	rower_exited.emit()

func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_vehicle"):
		body.set_interactable_vehicle(self)

func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_vehicle"):
		body.set_interactable_vehicle(null)
