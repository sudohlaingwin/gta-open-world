extends CharacterBody3D
## Slice 3 airplane: flyable, with EXPLICIT throttle control.
## This deliberately avoids the opponent's auto-throttle defect
## (throttle rising every frame with no way down) and its unused
## stall_speed export (stall is actually applied here).
##
## Slice 47 physics polish (audit plan item 5, sixth parity
## vehicle): the airplane stays a move_and_slide CharacterBody3D
## (no body migration — the move_and_slide model already
## preserves enter/exit, camera retargeting, and the Slice 16
## parachute flow, so there is nothing to gain by migrating it).
## Top speed stays 50.0 on purpose: velocity.limit_length(50.0)
## below, and player.gd's HUD SpeedBar uses vmax["Airplane"] =
## 50.0, so changing it would break the bar. There is NO reverse
## gear, before or after — throttle clamps at 0, thrust is never
## negative, and the air equivalent of braking is throttle cut +
## air drag (see below), not reverse thrust. Stall is PRESERVED,
## not tuned away: stall_speed stays 8.0 and lift still collapses
## below it, so a slow plane still sinks. The Slice 16 parachute
## flow is untouched: a mid-air exit still drops the pilot and
## player.gd auto-deploys the canopy above y = 3.0 (descent capped
## 3.0 m/s, auto-stow on landing). Driving FEEL cannot be
## verified headlessly — the owner's on-device verdict decides
## whether this tuning feels right.
## Tuning, same family as the land/water polishes:
##   throttle spool curve (soft spool-up, full mid-range, taper
##     near top speed — the horse _accel_curve shape, keyed on
##     forward-speed ratio);
##   real air drag (3.0 u/s^2 opposing the velocity vector, so
##     throttle cut actually slows the plane instead of gliding
##     forever at the same forward speed — the old code had no
##     drag at all, proven by the harness: 0.00 forward-speed
##     drop over 0.25 s at throttle 0);
##   speed-dependent yaw/roll/pitch authority (agile at low
##     speed, stable at top speed, interpolated + 8.0/s
##     smoothing — the old constant rates were equally twitchy
##     everywhere);
##   propeller spin now scales with throttle (idle spin at 0,
##     full 30 rad/s at 1 — the old code spun at a constant 30
##     regardless of throttle).
## Touch controls are unchanged: ThrottleUp / ThrottleDown
## buttons (Slice 9, shown only while flying) + joystick pitch /
## roll with coordinated yaw + touch yaw buttons (Slice 10).
## Q/E yaw and Shift/Ctrl throttle remain ONLY as desktop
## fallbacks (explicit, clamped 0..1, never auto-rising).
## The Slice 3 header note about "no parachute" is stale since
## Slice 16 and is corrected here: the parachute exists.
## Enter/exit: same start_driving()/leave_vehicle() interface as
## the other vehicles, so the player's vehicle picker works unchanged.

@export var max_thrust: float = 30.0
@export var lift_coefficient: float = 1.2
@export var stall_speed: float = 8.0
@export var air_drag: float = 3.0
@export var low_pitch_rate: float = 1.8
@export var high_pitch_rate: float = 0.9
@export var low_roll_rate: float = 2.4
@export var high_roll_rate: float = 1.2
@export var low_yaw_rate: float = 1.2
@export var high_yaw_rate: float = 0.5
@export var steer_response: float = 8.0

var driver: Node = null
var is_flying: bool = false
var throttle: float = 0.0
var propeller_node: Node = null
var pitch_smooth: float = 0.0
var roll_smooth: float = 0.0
var yaw_smooth: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	is_flying = true
	throttle = 0.0
	pitch_smooth = 0.0
	roll_smooth = 0.0
	yaw_smooth = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

## Throttle spool curve: soft spool-up (0.55 at standstill, so
## the engine does not jerk to full power), full pull through
## the mid-range, taper to 0.5 at top speed (so top speed is
## approached, not slammed into). Same shape as the land
## vehicles' accel curve, keyed on forward-speed ratio.
func _spool_curve(speed_ratio: float) -> float:
	if speed_ratio < 0.3:
		return 0.55 + 0.45 * (speed_ratio / 0.3)
	return 1.0 - 0.5 * ((speed_ratio - 0.3) / 0.7)

func _physics_process(delta: float) -> void:
	if not is_flying or driver == null:
		if not is_on_floor():
			velocity.y -= 9.8 * delta
			move_and_slide()
		return
	if Input.is_action_just_pressed("ui_accept"):
		_exit_aircraft()
		return
	# Forward speed FIRST: the spool curve and the control
	# authority both key on it, so it must be read before the
	# throttle and rotation updates below.
	var forward0 := -global_transform.basis.z
	var forward_speed0 := velocity.dot(forward0)
	var speed_ratio := clampf(absf(forward_speed0) / 50.0, 0.0, 1.0)
	# Explicit throttle: touch buttons first, Shift/Ctrl as fallback.
	# Never auto-rises. Spool rate follows the curve: soft at
	# standstill, full mid-range, tapering near top speed.
	var spool := _spool_curve(speed_ratio)
	if Input.is_physical_key_pressed(KEY_SHIFT) or driver.get("touch_throttle_up") == true:
		throttle += 0.5 * spool * delta
	if Input.is_physical_key_pressed(KEY_CTRL) or driver.get("touch_throttle_down") == true:
		throttle -= 0.5 * spool * delta
	throttle = clamp(throttle, 0.0, 1.0)
	var pitch_in := Input.get_axis("ui_up", "ui_down")
	var roll_in := Input.get_axis("ui_left", "ui_right")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		pitch_in = driver.touch_vector.y
		roll_in = driver.touch_vector.x
	# Control smoothing: inputs ease toward their targets instead
	# of snapping (weight feel, no twitch on small inputs).
	pitch_smooth = move_toward(pitch_smooth, pitch_in, steer_response * delta)
	roll_smooth = move_toward(roll_smooth, roll_in, steer_response * delta)
	# Speed-dependent authority: agile at low speed, stable at top
	# speed (the old constant rates were equally twitchy everywhere).
	var pitch_rate := lerpf(low_pitch_rate, high_pitch_rate, speed_ratio)
	var roll_rate := lerpf(low_roll_rate, high_roll_rate, speed_ratio)
	var yaw_rate := lerpf(low_yaw_rate, high_yaw_rate, speed_ratio)
	rotate_object_local(Vector3.RIGHT, pitch_smooth * pitch_rate * delta)
	rotate_object_local(Vector3.FORWARD, -roll_smooth * roll_rate * delta)
	# Coordinated yaw from roll: a joystick-only pilot can turn.
	rotate_y(-roll_smooth * yaw_rate * 0.5 * delta)
	# Slice 10: touch yaw buttons (primary on a phone) + spinning
	# propeller mesh (Propeller node in main.tscn, nose at -Z).
	var yaw_btn := 0.0
	if driver.get("touch_yaw_right") == true:
		yaw_btn += 1.0
	if driver.get("touch_yaw_left") == true:
		yaw_btn -= 1.0
	yaw_smooth = move_toward(yaw_smooth, yaw_btn, steer_response * delta)
	rotate_y(-yaw_smooth * yaw_rate * delta)
	if propeller_node == null:
		propeller_node = get_node_or_null("Propeller")
	if propeller_node != null:
		(propeller_node as Node3D).rotation.z += 30.0 * (0.2 + 0.8 * throttle) * delta
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
	# Air drag: throttle cut actually slows the plane now. This
	# opposes the whole velocity vector at a modest rate, so the
	# plane glides down to stall speed instead of gliding forever
	# at the same forward speed — and it never drives the plane
	# backwards by itself (move_toward stops exactly at zero).
	velocity = velocity.move_toward(Vector3.ZERO, air_drag * delta)
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
	pitch_smooth = 0.0
	roll_smooth = 0.0
	yaw_smooth = 0.0
	p.global_position = spot
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
