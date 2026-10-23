extends CharacterBody3D
const CamSteer97 = preload("res://camera_steer97.gd")
## Slice 19 horse: RIDEABLE (the village horse). Same enter/exit
## interface as elephant.gd / tuktuk.gd, so the on-screen Vehicle
## button enters and exits it and the camera retargets while ridden.
## TOUCH-FIRST — this is a mobile game: the wired touch joystick
## steers + gallops (joystick x = steer, joystick up = forward,
## down = reverse). Arrow keys / WASD remain ONLY as a desktop
## fallback. Primitive, honest animation (not a skinned rig): four
## legs swing in diagonal pairs at gallop pace, the mane and tail
## stream while moving; standing still everything eases to neutral.
## Slice 43 horse driving-physics polish (audit plan item 5, second
## parity vehicle — same pattern as the Slice 26 car, Slice 31
## motorcycle, Slice 33 tuk-tuk, Slice 36 bicycle, and Slice 42
## cart polishes): the horse stays a move_and_slide CharacterBody3D
## animal — NO body-type migration in this round (stated as
## deferred: the move_and_slide model already preserves enter/exit,
## the Slice 24 camera-collision behaviour, the Slice 41
## driver-body fix, and the HUD speed readout, and a body swap
## would rework collision and camera retargeting for no measured
## benefit). What changed is the TUNING inside that model,
## measured headlessly before/after (table in README): a drive
## acceleration curve (soft launch, strong mid-range, taper near
## top speed), a real brake (stronger than driving, only while
## rolling forward; reverse engages from near-stop, capped at the
## old 0.4 ratio), speed-dependent steering (agile at low speed,
## stable at top speed — the old constant rate was equally twitchy
## everywhere), steering smoothing (no snap), and a much longer
## rolling coast (a horse keeps its momentum when you stop
## driving — the old stop rate halted it in 3.0 s). The gallop leg
## animation + streaming mane/tail are UNCHANGED (they still
## animate at speed, verified in the world sim — animation pace is
## the old fixed 9.0/s walk_phase rate, not speed-scaled, stated
## plainly). Both Horse and Horse2 run this one script, so both
## horses get the tuning. Driving FEEL cannot be verified
## headlessly — the owner's on-device verdict decides whether this
## tuning feels right. Top speed stays 9.0 on purpose: player.gd's
## HUD SpeedBar uses vmax["Horse"] = 9.0, so changing it would
## break the bar. Reverse cap stays 0.4 for the same reason (the
## old code already clamped there). This file touches no materials
## and no scenes, so every other vehicle's look is unaffected.

@export var max_speed: float = 9.0
@export var accel: float = 6.0
@export var turn_rate: float = 1.9
@export var high_speed_turn_rate: float = 0.9
@export var brake_force: float = 12.0
@export var reverse_speed_ratio: float = 0.4
@export var coast_drag: float = 1.2
@export var steer_response: float = 8.0

var driver: Node = null
var speed: float = 0.0
var walk_phase: float = 0.0
var steer_smooth: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	steer_smooth = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

## Drive curve: soft launch (0.55 at standstill, so the horse does
## not jerk), full pull through the mid-range, taper to 0.5 at top
## speed (so top speed is approached, not slammed into).
func _accel_curve(speed_ratio: float) -> float:
	if speed_ratio < 0.3:
		return 0.55 + 0.45 * (speed_ratio / 0.3)
	return 1.0 - 0.5 * ((speed_ratio - 0.3) / 0.7)

func _physics_process(delta: float) -> void:
	if driver == null:
		velocity = Vector3.ZERO
		_animate(delta, false)
		move_and_slide()
		return
	if Input.is_action_just_pressed("ui_accept"):
		_exit_horse()
		return
	var fwd := Input.get_axis("ui_down", "ui_up")
	var steer := Input.get_axis("ui_left", "ui_right")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		# Slice 97: camera-relative steering (Slice 95 car fix,
		# shared camera_steer97.gd helper) — joystick-up is the
		# camera look direction, not screen-up. Smoothing and
		# mode scales below are untouched; no camera means the
		# old raw mapping (fallback, unchanged behaviour).
		var _cam97 := get_node_or_null("../FollowCamera")
		if _cam97 != null and _cam97.get("orbit_angle") != null:
			var _gs97 := CamSteer97.ground_steer(driver.touch_vector, float(_cam97.get("orbit_angle")), rotation.y)
			steer = _gs97.x
			fwd = _gs97.y
		else:
			steer = driver.touch_vector.x
			fwd = -driver.touch_vector.y
	var ratio := absf(speed) / max_speed
	if fwd > 0.0:
		speed += fwd * accel * _accel_curve(ratio) * delta
	elif fwd < 0.0:
		if speed > 0.5:
			# Real brake: stronger than driving, and it never
			# rolls the horse backwards by itself.
			speed = maxf(0.0, speed - brake_force * (-fwd) * delta)
		else:
			# Near-stop: reverse engages, capped below.
			speed += fwd * accel * _accel_curve(ratio) * delta
	else:
		# Coasting: a horse keeps its momentum when you stop
		# driving — gentle drag only, much longer than the old
		# accel*0.5 stop, so the horse keeps rolling.
		speed = move_toward(speed, 0.0, coast_drag * delta)
	speed = clamp(speed, -max_speed * reverse_speed_ratio, max_speed)
	# Steering smoothing: the horse turns toward the input instead
	# of snapping to it (weight feel, no twitch on small inputs).
	steer_smooth = move_toward(steer_smooth, steer, steer_response * delta)
	# Speed-dependent steering: agile at low speed, stable at top
	# speed (the old constant rate was equally twitchy everywhere).
	var turn := lerpf(turn_rate, high_speed_turn_rate, ratio)
	rotation.y -= steer_smooth * turn * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity = forward * speed
	move_and_slide()
	_animate(delta, absf(speed) > 0.1)

func _animate(delta: float, moving: bool) -> void:
	if moving:
		walk_phase += delta * 9.0
	var s := sin(walk_phase) * 0.6 if moving else 0.0
	var legs := {"HorseLegFL": s, "HorseLegBR": s, "HorseLegFR": -s, "HorseLegBL": -s}
	for lname in legs:
		var leg := get_node_or_null(lname)
		if leg != null:
			leg.rotation.x = legs[lname]
	var mane := get_node_or_null("HorseMane")
	if mane != null:
		mane.rotation.x = sin(walk_phase * 0.5) * 0.25 if moving else 0.0
	var tail := get_node_or_null("HorseTail")
	if tail != null:
		tail.rotation.x = sin(walk_phase) * 0.4 if moving else 0.0

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_horse()

func _exit_horse() -> void:
	if driver == null:
		return
	var p: Node = driver
	# Slice 38: exit clearance probe (see car.gd) — never step out
	# into a wall; if blocked everywhere, stay mounted and say so.
	var spot: Vector3 = p.find_free_exit_spot(self, Vector3(2.5, 0.5, 0.0))
	if spot == Vector3.INF:
		p.show_exit_blocked()
		return
	driver = null
	speed = 0.0
	steer_smooth = 0.0
	velocity = Vector3.ZERO
	# Step out beside the horse so the player is not stuck in it.
	p.global_position = spot
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
