extends CharacterBody3D

# --- Dynamic Driveable & Hijackable GTA-Style Open-World Traffic Vehicle ---

@export var speed: float = 7.5
@export var player_max_speed: float = 24.0 # ~86 km/h
@export var player_accel: float = 16.0
@export var player_reverse_speed: float = 8.5
@export var turn_speed: float = 2.4
@export var waypoints: Array[Vector3] = []
@export var current_wp_idx: int = 0

var is_player_driven: bool = false
var current_driver: Node3D = null
var current_speed: float = 0.0
var steer_angle: float = 0.0
var is_stopped: bool = false
var blocked_timer: float = 0.0
var headlights_on: bool = true

@onready var visual_mesh: Node3D = get_node_or_null("VisualMesh")
@onready var wheel_fl: Node3D = get_node_or_null("VisualMesh/WheelFL")
@onready var wheel_fr: Node3D = get_node_or_null("VisualMesh/WheelFR")
@onready var wheel_bl: Node3D = get_node_or_null("VisualMesh/WheelBL")
@onready var wheel_br: Node3D = get_node_or_null("VisualMesh/WheelBR")
@onready var driver_seat: Marker3D = get_node_or_null("DriverSeat")
@onready var interaction_area: Area3D = get_node_or_null("InteractionArea")
@onready var headlight_beam_l: SpotLight3D = get_node_or_null("VisualMesh/Headlights/BeamL")
@onready var headlight_beam_r: SpotLight3D = get_node_or_null("VisualMesh/Headlights/BeamR")
@onready var car_sign: Label3D = get_node_or_null("TrafficCarSign")

func _ready() -> void:
	add_to_group("traffic_cars")
	add_to_group("vehicles")
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_player_driven:
		if body.has_method("set_interactable_vehicle"):
			body.set_interactable_vehicle(self)

func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player") and not is_player_driven:
		if body.has_method("set_interactable_vehicle"):
			body.set_interactable_vehicle(null)

func enter_vehicle(driver: Node3D) -> void:
	if is_player_driven:
		return
	is_player_driven = true
	current_driver = driver
	
	# Seat driver inside cabin
	if driver_seat:
		driver.reparent(driver_seat)
	else:
		driver.reparent(self)
	driver.position = Vector3.ZERO
	driver.rotation = Vector3.ZERO
	
	if driver.has_method("set_driving_state"):
		driver.set_driving_state(true, self)
	
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_door_latch_pull"):
		am.play_door_latch_pull()
	if am and am.has_method("play_engine_crank"):
		am.play_engine_crank()

	if car_sign:
		car_sign.text = "🚗 မောင်းနှင်နေသည် (Player Driving)"
		car_sign.modulate = Color(0.2, 1.0, 0.4)

func exit_vehicle() -> void:
	if not is_player_driven or not current_driver:
		return
	var driver = current_driver
	is_player_driven = false
	current_driver = null
	current_speed = 0.0
	velocity = Vector3.ZERO
	
	# Safe step-out position on driver side
	var exit_pos = global_position + (global_transform.basis.x * 2.2)
	driver.reparent(get_parent())
	driver.global_position = exit_pos
	
	if driver.has_method("set_driving_state"):
		driver.set_driving_state(false, null)
		
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_door_latch_pull"):
		am.play_door_latch_pull()
	if am and am.has_method("play_car_engine"):
		am.play_car_engine(0.0)

	if car_sign:
		car_sign.text = "မင်းတုန်း မြို့ပြ ခရီးသည်တင်ယာဉ် 🚕"
		car_sign.modulate = Color(1.0, 0.9, 0.4)

func _physics_process(delta: float) -> void:
	# Gravity to stay grounded on open-world terrain
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -1.0 # Slight downward stickiness

	if is_player_driven and current_driver:
		_process_player_driving(delta)
	else:
		_process_ai_traffic(delta)

	move_and_slide()

func _process_player_driving(delta: float) -> void:
	# Input reading (Mobile Joystick priority, WASD keyboard fallback)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if current_driver.get("touch_input_vector") != null and current_driver.touch_input_vector != Vector2.ZERO:
		input_dir = current_driver.touch_input_vector

	# Responsive steering
	var target_steer = -input_dir.x * 0.42
	steer_angle = move_toward(steer_angle, target_steer, 5.0 * delta)
	
	# Dynamic turning rate proportional to velocity
	var speed_ratio = clampf(abs(current_speed) / player_max_speed, 0.0, 1.0)
	var turn_mult = 1.0 if current_speed >= 0.0 else -1.0
	if abs(current_speed) > 0.5:
		rotation.y += steer_angle * (0.6 + speed_ratio * 0.8) * 3.2 * turn_mult * delta

	# Front wheel visual turning
	if wheel_fl:
		wheel_fl.rotation.y = steer_angle
	if wheel_fr:
		wheel_fr.rotation.y = steer_angle

	# Throttle / Acceleration & Active Braking
	if input_dir.y < -0.05: # Forward Gas
		var boost = 1.4 if (current_driver.get("is_sprinting") and current_driver.is_sprinting) else 1.0
		current_speed = move_toward(current_speed, player_max_speed * boost, player_accel * delta)
	elif input_dir.y > 0.05: # Brake or Reverse
		if current_speed > 1.0:
			# Fast responsive braking
			current_speed = move_toward(current_speed, 0.0, 32.0 * delta)
		else:
			# Reverse gear
			current_speed = move_toward(current_speed, -player_reverse_speed, 12.0 * delta)
	else:
		# Rolling natural friction (momentum preservation)
		current_speed = move_toward(current_speed, 0.0, 6.0 * delta)

	# Forward velocity vector
	var fwd = -global_transform.basis.z
	velocity.x = fwd.x * current_speed
	velocity.z = fwd.z * current_speed

	# Rolling wheel spin
	var spin = (current_speed / 0.42) * delta
	if wheel_fl: wheel_fl.rotate_x(spin)
	if wheel_fr: wheel_fr.rotate_x(spin)
	if wheel_bl: wheel_bl.rotate_x(spin)
	if wheel_br: wheel_br.rotate_x(spin)

	# Dynamic Chassis Roll (Suspension weight transfer during cornering)
	if visual_mesh:
		var target_roll = -steer_angle * 0.12 * speed_ratio
		visual_mesh.rotation.z = lerpf(visual_mesh.rotation.z, target_roll, 8.0 * delta)

	# Audio feedback
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_car_engine"):
		am.play_car_engine(speed_ratio)

func _process_ai_traffic(delta: float) -> void:
	if waypoints.is_empty():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_check_obstacles()

	if is_stopped:
		blocked_timer += delta
		if blocked_timer > 12.0:
			_respawn_at_next_waypoint()
		velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
		return
	else:
		blocked_timer = 0.0

	var target = waypoints[current_wp_idx]
	var dir = (target - global_position)
	dir.y = 0.0

	if dir.length() < 2.0:
		current_wp_idx = (current_wp_idx + 1) % waypoints.size()
	else:
		var move_dir = dir.normalized()
		var target_rot = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, turn_speed * delta)
		
		var forward = -global_transform.basis.z
		velocity.x = forward.x * speed
		velocity.z = forward.z * speed

		var spin = (speed / 0.42) * delta
		if wheel_fl: wheel_fl.rotate_x(spin)
		if wheel_fr: wheel_fr.rotate_x(spin)
		if wheel_bl: wheel_bl.rotate_x(spin)
		if wheel_br: wheel_br.rotate_x(spin)

func _check_obstacles() -> void:
	var forward = -global_transform.basis.z
	var stop = false

	var player = get_tree().get_first_node_in_group("player")
	if player:
		var p_diff = player.global_position - global_position
		p_diff.y = 0.0
		var p_dist = p_diff.length()
		if p_dist < 3.2 or (p_dist < 6.5 and forward.dot(p_diff.normalized()) > 0.65):
			stop = true

	if not stop:
		var others = get_tree().get_nodes_in_group("traffic_cars")
		for car in others:
			if car != self:
				var c_diff = car.global_position - global_position
				c_diff.y = 0.0
				var c_dist = c_diff.length()
				if c_dist < 3.2 or (c_dist < 6.0 and forward.dot(c_diff.normalized()) > 0.7):
					stop = true
					break

	if not stop:
		var villagers = get_tree().get_nodes_in_group("villagers")
		for v in villagers:
			var v_diff = v.global_position - global_position
			v_diff.y = 0.0
			var v_dist = v_diff.length()
			if v_dist < 2.8 or (v_dist < 5.2 and forward.dot(v_diff.normalized()) > 0.7):
				stop = true
				break

	is_stopped = stop

func _respawn_at_next_waypoint() -> void:
	blocked_timer = 0.0
	current_wp_idx = (current_wp_idx + 2) % waypoints.size()
	global_position = waypoints[current_wp_idx]

func cycle_headlight_mode() -> String:
	headlights_on = !headlights_on
	if headlight_beam_l: headlight_beam_l.visible = headlights_on
	if headlight_beam_r: headlight_beam_r.visible = headlights_on
	return "💡 ရှေ့မီးကြီး: ဖွင့်ထားသည်" if headlights_on else "💡 ရှေ့မီးကြီး: ပိတ်ထားသည်"

func honk_horn() -> void:
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_car_horn"):
		am.play_car_horn()
