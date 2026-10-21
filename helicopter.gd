extends CharacterBody3D
## Slice 9 helicopter — a NEW owner-spec aircraft type ("fly various
## airplanes" in the owner's spec; the helicopter is distinct from
## the Slice 3 airplane: it hovers, climbs vertically, and turns in
## place instead of needing forward speed for lift).
##
## Controls (TOUCH-FIRST — this is a mobile game):
##   Joystick: up = forward, down = back, x = turn (yaw).
##   ThrottleUp button (hold) = climb, ThrottleDown button = descend;
##   release both and it HOVERS (vertical speed eases to 0).
##   WASD / arrows + Shift / Ctrl are ONLY desktop fallbacks.
##   Exit: on-screen Vehicle button (or Enter/Space on desktop).
## The Rotor mesh spins while flying. Same start_driving() /
## exit_vehicle() interface as every other vehicle, so the player's
## nearest-vehicle picker and camera retarget work unchanged.
## No weapons, no missions for the helicopter yet — stated plainly.

@export var max_speed: float = 12.0
@export var accel: float = 9.0
@export var turn_rate: float = 2.0
@export var climb_speed: float = 6.0
@export var descend_speed: float = 4.0

var driver: Node = null
var speed: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	velocity = Vector3.ZERO
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

func _physics_process(delta: float) -> void:
	var rotor := get_node_or_null("Rotor") as Node3D
	if driver == null:
		if rotor != null:
			rotor.rotation.y += 1.0 * delta
		if not is_on_floor():
			velocity.y -= 9.8 * delta
			velocity.x = 0.0
			velocity.z = 0.0
			move_and_slide()
		else:
			velocity = Vector3.ZERO
		return
	if rotor != null:
		rotor.rotation.y += 20.0 * delta
	if Input.is_action_just_pressed("ui_accept"):
		_exit_heli()
		return
	var fwd := Input.get_axis("ui_down", "ui_up")
	var turn := Input.get_axis("ui_left", "ui_right")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		turn = driver.touch_vector.x
		fwd = -driver.touch_vector.y
	# Slice 10: touch yaw buttons add to the joystick turn input.
	if driver.get("touch_yaw_right") == true:
		turn += 1.0
	if driver.get("touch_yaw_left") == true:
		turn -= 1.0
	speed += fwd * accel * delta
	speed = clamp(speed, -max_speed * 0.4, max_speed)
	if fwd == 0.0:
		speed = move_toward(speed, 0.0, accel * 0.5 * delta)
	rotation.y -= turn * turn_rate * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	# Vertical: touch throttle buttons first, Shift/Ctrl as fallback.
	# No input = hover (vertical speed eases to 0, it does not fall).
	var climb: bool = Input.is_physical_key_pressed(KEY_SHIFT) or driver.get("touch_throttle_up") == true
	var descend: bool = Input.is_physical_key_pressed(KEY_CTRL) or driver.get("touch_throttle_down") == true
	if climb:
		velocity.y = climb_speed
	elif descend:
		velocity.y = -descend_speed
	else:
		velocity.y = move_toward(velocity.y, 0.0, 20.0 * delta)
	move_and_slide()

## Slice 9 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_heli()

func _exit_heli() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	speed = 0.0
	velocity = Vector3.ZERO
	p.global_position = global_position + Vector3(2.0, 0.5, 0.0)
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
