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

## Slice 48 helicopter driving-physics polish (audit plan item 5,
## SEVENTH parity round — this COMPLETES item 5: all 11 rideables
## now polished — car, motorcycle, tuk-tuk, bicycle, cart, horse,
## elephant, cow, boat, airplane, helicopter; table in README):
## the helicopter stays a move_and_slide CharacterBody3D — NO
## body-type migration in this round (the move_and_slide model
## already preserves enter/exit, the Slice 24 camera behaviour,
## the Slice 41 driver-body fix, and the Slice 16 parachute flow
## via player.gd's leave_vehicle(), and a body swap would rework
## collision and camera retargeting for no measured benefit).
## What changed is the TUNING inside that model, measured
## headlessly before/after (table in README): a drive accel curve
## (soft launch, strong mid-range, taper near top speed — the
## horse _accel_curve shape), a real brake (stronger than
## driving, only while rolling forward; reverse engages from
## near-stop, capped at the old 0.4 ratio — the old code drove
## straight through zero into reverse at full rate), speed-
## dependent yaw (agile at low speed, stable at top speed — the
## old constant 2.0 rad/s was equally twitchy everywhere),
## steering smoothing (no snap), a much longer coast (the old
## 4.5/s stop halted it in 2.67 s), and a vertical spool (climb /
## descend ease toward their UNCHANGED targets instead of
## snapping — the old code set velocity.y = 6.0 in a single step).
## Preserved in kind, not tuned away: top speed stays 12.0
## (player.gd's HUD SpeedBar uses vmax["Helicopter"] = 12.0);
## reverse cap stays 0.4; climb target stays 6.0 and descend
## target stays 4.0; hover still eases vertical speed to 0 (the
## old 20.0/s hover ease is untouched); the rotor still spins at
## a CONSTANT 20.0 rad/s while flying and 1.0 idle — deliberately
## NOT scaled with forward speed, because a helicopter's rotor RPM
## is roughly constant in flight (collective changes lift, not
## RPM), so scaling it would be unphysical decoration. Touch
## controls are unchanged: joystick + touch yaw buttons + touch
## throttle up/down are primary; WASD / arrows + Shift / Ctrl +
## ui_accept remain ONLY as desktop fallbacks. Driving FEEL
## cannot be verified headlessly — the owner's on-device verdict
## decides whether this tuning feels right.

@export var max_speed: float = 12.0
@export var accel: float = 9.0
@export var turn_rate: float = 2.0
@export var high_speed_turn_rate: float = 1.0
@export var brake_force: float = 18.0
@export var reverse_speed_ratio: float = 0.4
@export var coast_drag: float = 1.2
@export var steer_response: float = 8.0
@export var climb_speed: float = 6.0
@export var descend_speed: float = 4.0
@export var vertical_response: float = 12.0

var driver: Node = null
var speed: float = 0.0
var steer_smooth: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	steer_smooth = 0.0
	velocity = Vector3.ZERO
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

## Drive curve: soft launch (0.55 at standstill, so the helicopter
## does not jerk), full pull through the mid-range, taper to 0.5 at
## top speed (so top speed is approached, not slammed into).
func _accel_curve(speed_ratio: float) -> float:
	if speed_ratio < 0.3:
		return 0.55 + 0.45 * (speed_ratio / 0.3)
	return 1.0 - 0.5 * ((speed_ratio - 0.3) / 0.7)

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
	# Drive curve + brake + coast, same family as the polished
	# land vehicles: soft launch, full mid-range, taper near top;
	# a real brake that never rolls the helicopter backwards by
	# itself (reverse engages only from near-stop); a long coast
	# when the stick is released.
	var ratio := absf(speed) / max_speed
	if fwd > 0.0:
		speed += fwd * accel * _accel_curve(ratio) * delta
	elif fwd < 0.0:
		if speed > 0.5:
			# Real brake: stronger than driving, and it never
			# rolls the helicopter backwards by itself.
			speed = maxf(0.0, speed - brake_force * (-fwd) * delta)
		else:
			# Near-stop: reverse engages, capped below.
			speed += fwd * accel * _accel_curve(ratio) * delta
	else:
		# Coasting: gentle drag only, much longer than the old
		# accel*0.5 stop, so the helicopter keeps its momentum.
		speed = move_toward(speed, 0.0, coast_drag * delta)
	speed = clamp(speed, -max_speed * reverse_speed_ratio, max_speed)
	# Steering smoothing: the helicopter turns toward the input
	# instead of snapping to it (weight feel, no twitch).
	steer_smooth = move_toward(steer_smooth, turn, steer_response * delta)
	# Speed-dependent yaw: agile at low speed, stable at top
	# speed (the old constant rate was equally twitchy everywhere).
	# The reverse sign flip is kept: pulling back still steers
	# the tail the way a reversing rotorcraft does.
	var turn_now := lerpf(turn_rate, high_speed_turn_rate, ratio)
	rotation.y -= steer_smooth * turn_now * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	# Vertical: touch throttle buttons first, Shift/Ctrl as fallback.
	# No input = hover (vertical speed eases to 0, it does not fall).
	# Targets are UNCHANGED (climb 6.0, descend 4.0, hover 0); only
	# the climb/descend TRANSITION is new — velocity eases toward
	# the target at vertical_response instead of snapping to it in
	# a single step. Hover ease keeps its old 20.0/s rate.
	var climb: bool = Input.is_physical_key_pressed(KEY_SHIFT) or driver.get("touch_throttle_up") == true
	var descend: bool = Input.is_physical_key_pressed(KEY_CTRL) or driver.get("touch_throttle_down") == true
	if climb:
		velocity.y = move_toward(velocity.y, climb_speed, vertical_response * delta)
	elif descend:
		velocity.y = move_toward(velocity.y, -descend_speed, vertical_response * delta)
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
	# Slice 38: exit clearance probe (see car.gd) — never step out
	# into a wall; if blocked everywhere, stay mounted and say so.
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
