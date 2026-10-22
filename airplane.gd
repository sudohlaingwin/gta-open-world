extends CharacterBody3D
## Slice 3 airplane: flyable, with EXPLICIT throttle control.
## This deliberately avoids the opponent's auto-throttle defect
## (throttle rising every frame with no way down) and its unused
## stall_speed export (stall is actually applied here).
##
## Controls while flying (TOUCH-FIRST — this is a mobile game):
##   Throttle: hold the on-screen ThrottleUp / ThrottleDown buttons
##   (Slice 9, shown only while flying an aircraft; player.gd wires
##   them to driver.touch_throttle_up / touch_throttle_down).
##   Shift / Ctrl remain ONLY as desktop fallbacks (explicit,
##   clamped 0..1, never auto-rising).
##   Joystick: x = roll (+ coordinated yaw, so a phone can turn
##   without a keyboard), y = pitch. Q/E yaw remains as a desktop
##   fallback only.
##   Exit: on-screen Vehicle button (or Enter/Space on desktop).
##   Exiting mid-air drops the pilot (falling); there is NO
##   parachute yet — stated plainly, not faked.
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
var propeller_node: Node = null

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
	# Explicit throttle: touch buttons first, Shift/Ctrl as fallback.
	# Never auto-rises.
	if Input.is_physical_key_pressed(KEY_SHIFT) or driver.get("touch_throttle_up") == true:
		throttle += 0.5 * delta
	if Input.is_physical_key_pressed(KEY_CTRL) or driver.get("touch_throttle_down") == true:
		throttle -= 0.5 * delta
	throttle = clamp(throttle, 0.0, 1.0)
	var pitch_in := Input.get_axis("ui_up", "ui_down")
	var roll_in := Input.get_axis("ui_left", "ui_right")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		pitch_in = driver.touch_vector.y
		roll_in = driver.touch_vector.x
	rotate_object_local(Vector3.RIGHT, pitch_in * pitch_speed * delta)
	rotate_object_local(Vector3.FORWARD, -roll_in * roll_speed * delta)
	# Coordinated yaw from roll: a joystick-only pilot can turn.
	rotate_y(-roll_in * yaw_speed * 0.5 * delta)
	# Slice 10: touch yaw buttons (primary on a phone) + spinning
	# propeller mesh (Propeller node in main.tscn, nose at -Z).
	var yaw_btn := 0.0
	if driver.get("touch_yaw_right") == true:
		yaw_btn += 1.0
	if driver.get("touch_yaw_left") == true:
		yaw_btn -= 1.0
	rotate_y(-yaw_btn * yaw_speed * delta)
	if propeller_node == null:
		propeller_node = get_node_or_null("Propeller")
	if propeller_node != null:
		(propeller_node as Node3D).rotation.z += 30.0 * delta
	if Input.is_physical_key_pressed(KEY_Q):
		rotate_y(0.8 * delta)
	if Input.is_physical_key_pressed(KEY_E):
		rotate_y(-0.8 * delta)
	var forward := -global_transform.basis.z
	var forward_speed := velocity.dot(forward)
	var thrust := forward * (throttle * max_thrust)
	# Lift scales with forward speed; below stall speed it collapses
	# and the plane sinks — stall_speed is actually used here.
	var lift_factor: float = clampf(forward_speed / stall_speed, 0.0, 1.0)
	var lift: Vector3 = Vector3.UP * (maxf(0.0, forward_speed) * lift_coefficient * lift_factor)
	var gravity_force := Vector3.DOWN * 9.8
	velocity += (thrust + lift + gravity_force) * delta
	velocity = velocity.limit_length(50.0)
	move_and_slide()

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_aircraft()

func _exit_aircraft() -> void:
	if driver == null:
		return
	var p: Node = driver
	# Slice 38: exit clearance probe (see car.gd) — never step out
	# into a wall; if blocked everywhere, stay mounted and say so.
	var spot: Vector3 = p.find_free_exit_spot(self, Vector3(3.0, 0.5, 0.0))
	if spot == Vector3.INF:
		p.show_exit_blocked()
		return
	driver = null
	is_flying = false
	throttle = 0.0
	p.global_position = spot
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
