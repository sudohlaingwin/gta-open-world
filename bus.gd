extends CharacterBody3D
## Slice 74 — BUS SIMULATION, part 1 (owner redirection 2026-10-23
## 11:31 + owner choice 11:32: BUS + STOPS + PASSENGERS).
## The bus is a drivable vehicle like the car (Slice 1/26 pattern:
## CharacterBody3D kinematic driver, driver + speed + start_driving
## + exit_vehicle, joystick touch_vector input, ui_accept desktop
## fallback exit), but tuned as a SIMULATION vehicle, not arcade:
## heavy slow launch, long braking distance, speed-sensitive
## steering that goes deliberately numb at speed, long rolling
## coast. The car (Slice 26 polish + Slice 55 modes) already has
## this shape; the bus numbers below are heavier still, and the
## bus honours the same Slice 55 driving-mode scales as the car
## (brake/coast/steer/high-turn/scrub) so a mode change in the
## pause Settings screen applies to the bus too.
## Door: the bus carries a side door group (set by bus_sim74
## dress()); toggle_door() slides it and flips door_open. The
## Slice 74 controller (bus_controller74.gd) reads door_open to
## run boarding/alighting — the door is touch-first ("🚪 တံခါး"
## button); there is NO keyboard-primary door control (Evo's F
## key is adapted to touch, never copied as a key binding).
## No money/economy system in this slice (later owner decision,
## not invented here). Peaceful only: no combat, no weapons.

@export var max_speed: float = 16.0
@export var accel: float = 5.0
@export var turn_rate: float = 1.6
@export var high_speed_turn_rate: float = 0.6
@export var brake_force: float = 10.0
@export var reverse_speed_ratio: float = 0.3
@export var coast_drag: float = 1.5
@export var steer_response: float = 5.0
@export var turn_scrub: float = 1.0
@export var wheel_radius: float = 0.55

var driver: Node = null
var speed: float = 0.0
var steer_smooth: float = 0.0
var wheels: Array = []
var door_open: bool = false
var door_node: Node3D = null
var _door_base_z: float = 0.0
var _door_base_set: bool = false
var _sm_cached: Node = null


func _driving_mode() -> int:
	if _sm_cached != null and is_instance_valid(_sm_cached):
		return clampi(int(_sm_cached.get("driving_mode")), 0, 2)
	_sm_cached = get_node_or_null("/root/SaveManager")
	if _sm_cached == null:
		return 1
	return clampi(int(_sm_cached.get("driving_mode")), 0, 2)


func _mode_brake() -> float:
	match _driving_mode():
		0:
			return brake_force * 1.5
		2:
			return brake_force * 0.75
		_:
			return brake_force


func _mode_coast() -> float:
	match _driving_mode():
		0:
			return coast_drag * 0.6
		2:
			return coast_drag * 1.5
		_:
			return coast_drag


func _mode_steer_response() -> float:
	match _driving_mode():
		0:
			return steer_response * 1.25
		2:
			return steer_response * 0.75
		_:
			return steer_response


func _mode_high_turn() -> float:
	match _driving_mode():
		0:
			return high_speed_turn_rate * 1.3
		2:
			return high_speed_turn_rate * 0.7
		_:
			return high_speed_turn_rate


func _mode_scrub() -> float:
	match _driving_mode():
		0:
			return turn_scrub * 0.5
		2:
			return turn_scrub * 1.5
		_:
			return turn_scrub


func _ready() -> void:
	for child in get_children():
		if child is MeshInstance3D and str(child.name).begins_with("Wheel74"):
			wheels.append(child)


func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	steer_smooth = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())


## Simulation acceleration curve: heavy launch (0.5 at
## standstill — a bus does not jerk off), full pull mid-range,
## taper to 0.55 at top speed (top speed is approached, never
## slammed into). Because accel itself is low (5.0 vs car 8.0),
## the 0-to-top time is long: that IS the simulation feel.
func _accel_curve(speed_ratio: float) -> float:
	if speed_ratio < 0.3:
		return 0.5 + 0.5 * (speed_ratio / 0.3)
	return 1.0 - 0.45 * ((speed_ratio - 0.3) / 0.7)


func _physics_process(delta: float) -> void:
	if driver == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if Input.is_action_just_pressed("ui_accept"):
		_exit_bus()
		return
	var fwd := Input.get_axis("ui_down", "ui_up")
	var steer := Input.get_axis("ui_left", "ui_right")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		steer = driver.touch_vector.x
		fwd = -driver.touch_vector.y
	var ratio := absf(speed) / max_speed
	if fwd > 0.0:
		speed += fwd * accel * _accel_curve(ratio) * delta
	elif fwd < 0.0:
		if speed > 0.5:
			# Long braking distance on purpose (brake 10.0 vs
			# car 16.0): stopping from top speed takes metres,
			# so the driver must brake early for a bus stop.
			speed = maxf(0.0, speed - _mode_brake() * (-fwd) * delta)
		else:
			speed += fwd * accel * _accel_curve(ratio) * delta
	else:
		speed = move_toward(speed, 0.0, _mode_coast() * delta)
	speed = clamp(speed, -max_speed * reverse_speed_ratio, max_speed)
	steer_smooth = move_toward(steer_smooth, steer, _mode_steer_response() * delta)
	# Speed-sensitive steering: 1.6 rad/s at standstill down to
	# 0.6 rad/s at top speed — a bus at speed must NOT twitch.
	var turn := lerpf(turn_rate, _mode_high_turn(), ratio)
	if absf(steer_smooth) > 0.5 and ratio > 0.5:
		speed = move_toward(speed, 0.0, _mode_scrub() * absf(steer_smooth) * ratio * delta)
	rotation.y -= steer_smooth * turn * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity = forward * speed
	move_and_slide()
	for w in wheels:
		(w as MeshInstance3D).rotate_object_local(Vector3(0, 1, 0), speed / wheel_radius * delta)


## Touch-first door toggle (HUD "🚪 တံခါး" button). Slides the
## door panel along the body; the controller reads door_open.
func toggle_door() -> void:
	door_open = not door_open
	if door_node != null:
		if not _door_base_set:
			_door_base_z = door_node.position.z
			_door_base_set = true
		door_node.position.z = _door_base_z + (1.4 if door_open else 0.0)


func exit_vehicle() -> void:
	_exit_bus()


func _exit_bus() -> void:
	if driver == null:
		return
	var p: Node = driver
	# Same Slice 38 free-spot probe as the car: never step out
	# into a wall; a blocked exit keeps the player in the bus.
	var spot: Vector3 = p.find_free_exit_spot(self, Vector3(2.0, 0.5, 0.0))
	if spot == Vector3.INF:
		p.show_exit_blocked()
		return
	driver = null
	speed = 0.0
	steer_smooth = 0.0
	velocity = Vector3.ZERO
	p.global_position = spot
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
