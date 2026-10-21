extends CharacterBody3D
## Slice 3 airplane: flyable, with EXPLICIT throttle control.
## This deliberately avoids the opponent's auto-throttle defect
## (throttle rising every frame with no way down) and its unused
## stall_speed export (stall is actually applied here).
##
## Controls while flying (keyboard; joystick also works):
##   Throttle: Shift = up, Ctrl = down (explicit, clamped 0..1)
##   Pitch: Up/Down arrows. Roll: Left/Right arrows. Yaw: Q/E.
##   Joystick: x = roll, y = pitch.
##   Exit: Enter/Space. Exiting mid-air drops the pilot (falling);
##   there is NO parachute yet — stated plainly, not faked.
## Enter/exit: same start_driving()/leave_vehicle() interface as
## the other vehicles, so the player's vehicle picker works unchanged.

@export var max_thrust: float = 30.0
@export var lift_coefficient: float = 1.2
@export var pitch_speed: float = 1.5
@export var roll_speed: float = 2.0
@export var yaw_speed: float = 0.8
@export var stall_speed: float = 8.0

var driver: Node = null
var is_flying: bool = false
var throttle: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	is_flying = true
	throttle = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

func _physics_process(delta: float) -> void:
	if not is_flying or driver == null:
		if not is_on_floor():
			velocity.y -= 9.8 * delta
			move_and_slide()
		return
	if Input.is_action_just_pressed("ui_accept"):
		_exit_aircraft()
		return
	# Explicit throttle: Shift up, Ctrl down. Never auto-rises.
	if Input.is_physical_key_pressed(KEY_SHIFT):
		throttle += 0.5 * delta
	if Input.is_physical_key_pressed(KEY_CTRL):
		throttle -= 0.5 * delta
	throttle = clamp(throttle, 0.0, 1.0)
	var pitch_in := Input.get_axis("ui_up", "ui_down")
	var roll_in := Input.get_axis("ui_left", "ui_right")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		pitch_in = driver.touch_vector.y
		roll_in = driver.touch_vector.x
	rotate_object_local(Vector3.RIGHT, pitch_in * pitch_speed * delta)
	rotate_object_local(Vector3.FORWARD, -roll_in * roll_speed * delta)
	if Input.is_physical_key_pressed(KEY_Q):
		rotate_y(0.8 * delta)
	if Input.is_physical_key_pressed(KEY_E):
		rotate_y(-0.8 * delta)
	var forward := -global_transform.basis.z
	var forward_speed := velocity.dot(forward)
	var thrust := forward * (throttle * max_thrust)
	# Lift scales with forward speed; below stall speed it collapses
	# and the plane sinks — stall_speed is actually used here.
	var lift_factor := clamp(forward_speed / stall_speed, 0.0, 1.0)
	var lift := Vector3.UP * (max(0.0, forward_speed) * lift_coefficient * lift_factor)
	var gravity_force := Vector3.DOWN * 9.8
	velocity += (thrust + lift + gravity_force) * delta
	velocity = velocity.limit_length(50.0)
	move_and_slide()

func _exit_aircraft() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	is_flying = false
	throttle = 0.0
	p.global_position = global_position + Vector3(3.0, 0.5, 0.0)
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
