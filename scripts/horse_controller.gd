extends CharacterBody3D

# --- Authentic Myanmar Riding Horse (မြင်းမောင်းနှင်မှု ရူပဗေဒစနစ်) ---

@export var max_speed: float = 11.0
@export var sprint_speed: float = 16.0
@export var accel: float = 6.0
@export var turn_speed: float = 2.4
@export var high_speed_turn_speed: float = 1.1
@export var brake_force: float = 12.0
@export var coast_drag: float = 1.2
@export var steer_response: float = 8.0

var current_rider: Node3D = null
var is_ridden: bool = false
var current_speed: float = 0.0
var steer_smooth: float = 0.0

@onready var rider_seat: Marker3D = $RiderSeat
@onready var visual_mesh: Node3D = $VisualMesh
@onready var interaction_area: Area3D = $InteractionArea
@onready var leg_fl: Node3D = $VisualMesh/LegFL
@onready var leg_fr: Node3D = $VisualMesh/LegFR
@onready var leg_bl: Node3D = $VisualMesh/LegBL
@onready var leg_br: Node3D = $VisualMesh/LegBR

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

		var top_speed = sprint_speed if (current_rider.get("is_sprinting") == true) else max_speed
		var speed_ratio = clampf(abs(current_speed) / top_speed, 0.0, 1.0)

		# Speed-Dependent Steering (Agile at low speed, stable at high gallop)
		var active_turn = lerpf(turn_speed, high_speed_turn_speed, speed_ratio)
		var target_turn = -input_dir.x * active_turn
		steer_smooth = move_toward(steer_smooth, target_turn, steer_response * delta)
		rotate_y(steer_smooth * delta)

		# Progressive Acceleration Curve & Real Active Braking
		var forward = -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()

		if input_dir.y < -0.1: # Forward Throttle
			var curve = 0.55 + 0.45 * (1.0 - speed_ratio * 0.4)
			var target_v = top_speed * (-input_dir.y)
			current_speed = move_toward(current_speed, target_v, accel * curve * delta)
		elif input_dir.y > 0.1: # Reverse or Active Brake
			if current_speed > 0.4: # Real forward brake
				current_speed = move_toward(current_speed, 0.0, brake_force * input_dir.y * delta)
			else: # Reverse gear engages only from standstill
				var target_rev = -top_speed * 0.4 * input_dir.y
				current_speed = move_toward(current_speed, target_rev, accel * 0.6 * delta)
		else: # Gentle coasting drag (momentum preservation)
			current_speed = move_toward(current_speed, 0.0, coast_drag * delta)

		velocity.x = forward.x * current_speed
		velocity.z = forward.z * current_speed

		# Gallop leg swinging animation
		if abs(current_speed) > 0.5:
			var anim_rate = 0.012 * (abs(current_speed) / max_speed + 0.5)
			var gallop_cycle = sin(Time.get_ticks_msec() * anim_rate) * 0.45
			if leg_fl: leg_fl.rotation.x = gallop_cycle
			if leg_br: leg_br.rotation.x = gallop_cycle
			if leg_fr: leg_fr.rotation.x = -gallop_cycle
			if leg_bl: leg_bl.rotation.x = -gallop_cycle
	else:
		current_speed = move_toward(current_speed, 0.0, coast_drag * 2.0 * delta)
		velocity.x = move_toward(velocity.x, 0.0, coast_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, coast_drag * delta)
		if leg_fl: leg_fl.rotation.x = 0.0
		if leg_fr: leg_fr.rotation.x = 0.0
		if leg_bl: leg_bl.rotation.x = 0.0
		if leg_br: leg_br.rotation.x = 0.0

	move_and_slide()

func enter_mount(rider: Node3D) -> void:
	if is_ridden:
		return
	is_ridden = true
	current_rider = rider
	current_speed = 0.0
	steer_smooth = 0.0
	rider.reparent(rider_seat)
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
	current_speed = 0.0
	steer_smooth = 0.0
	var exit_pos = global_position + (global_transform.basis.x * 1.8)
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