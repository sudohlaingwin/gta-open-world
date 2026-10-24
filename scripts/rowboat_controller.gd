extends CharacterBody3D

# --- Authentic Myanmar Ayeyarwady Traditional Rowboat (သမ္ဗာန်လှေ) ---

@export var max_speed: float = 6.5
@export var accel: float = 4.0
@export var turn_speed: float = 1.6
@export var high_speed_turn_speed: float = 0.8
@export var brake_force: float = 8.0
@export var coast_drag: float = 0.8
@export var steer_response: float = 8.0

var current_rower: Node3D = null
var is_rowing: bool = false
var current_speed: float = 0.0
var steer_smooth: float = 0.0

@onready var rower_seat: Marker3D = $RiderSeat if has_node("RiderSeat") else $RowerSeat
@onready var interaction_area: Area3D = $InteractionArea
@onready var oar_left: Node3D = $VisualMesh/OarL
@onready var oar_right: Node3D = $VisualMesh/OarR
@onready var visual_mesh: Node3D = $VisualMesh
@onready var prow_lantern_light: OmniLight3D = $VisualMesh.get_node_or_null("ProwLanternGlobe/ProwLanternLight")

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

		var speed_ratio = clampf(abs(current_speed) / max_speed, 0.0, 1.0)

		# Speed-Dependent Steering with Reverse Flip (A reversing boat stern swings naturally)
		var active_turn = lerpf(turn_speed, high_speed_turn_speed, speed_ratio)
		var target_turn = -input_dir.x * active_turn
		steer_smooth = move_toward(steer_smooth, target_turn, steer_response * delta)
		rotate_y(steer_smooth * delta * (1.0 if current_speed >= 0.0 else -1.0))

		# Progressive Rowing Acceleration Curve & Real Water Back-Paddle Brake
		var forward = -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()

		if input_dir.y < -0.1: # Forward Row
			var curve = 0.55 + 0.45 * (1.0 - speed_ratio * 0.4)
			var target_v = max_speed * (-input_dir.y)
			current_speed = move_toward(current_speed, target_v, accel * curve * delta)
		elif input_dir.y > 0.1: # Back-paddle or Reverse
			if current_speed > 0.3: # Active brake while moving forward
				current_speed = move_toward(current_speed, 0.0, brake_force * input_dir.y * delta)
			else: # Reverse rowing engages only from standstill
				var target_rev = -max_speed * 0.4 * input_dir.y
				current_speed = move_toward(current_speed, target_rev, accel * 0.6 * delta)
		else: # Natural water gliding drag (0.8 drag retains smooth river momentum)
			current_speed = move_toward(current_speed, 0.0, coast_drag * delta)

		velocity.x = forward.x * current_speed
		velocity.z = forward.z * current_speed

		# Oar rowing animation
		if abs(current_speed) > 0.2:
			var oar_rate = 0.006 * (abs(current_speed) / max_speed + 0.5)
			var oar_angle = sin(Time.get_ticks_msec() * oar_rate) * 0.45
			if oar_left: oar_left.rotation.y = oar_angle
			if oar_right: oar_right.rotation.y = -oar_angle
			if abs(oar_angle) > 0.38:
				var am = get_tree().get_first_node_in_group("audio_manager")
				if am and am.has_method("play_boat_row_splash"):
					am.play_boat_row_splash()
	else:
		current_speed = move_toward(current_speed, 0.0, coast_drag * delta)
		velocity.x = move_toward(velocity.x, 0.0, coast_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, coast_drag * delta)
		if oar_left: oar_left.rotation.y = 0.0
		if oar_right: oar_right.rotation.y = 0.0

	# Dynamic Day/Night Prow Lantern Lighting
	if prow_lantern_light:
		var dnc = get_tree().get_first_node_in_group("day_night")
		var is_night = false
		if dnc and dnc.has_method("get_daylight"):
			is_night = (dnc.get_daylight() < 0.38)
		prow_lantern_light.visible = (is_night or is_rowing)

	# Hydrodynamic roll banking & pitch acceleration bobbing
	if visual_mesh:
		var target_roll = -steer_smooth * 0.12
		var target_pitch = (current_speed / max_speed) * 0.08
		visual_mesh.rotation.z = lerpf(visual_mesh.rotation.z, target_roll, delta * 6.0)
		visual_mesh.rotation.x = lerpf(visual_mesh.rotation.x, target_pitch, delta * 4.0)

	# Gentle water buoyancy bobbing
	velocity.y = sin(Time.get_ticks_msec() * 0.003) * 0.2

	move_and_slide()

func enter_vehicle(rower: Node3D) -> void:
	if is_rowing:
		return
	is_rowing = true
	current_rower = rower
	current_speed = 0.0
	steer_smooth = 0.0
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
	current_speed = 0.0
	steer_smooth = 0.0
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
