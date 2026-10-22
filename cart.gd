extends Node3D
## Slice 2 cart: DRIVABLE (slower than the car).
## Slice 9 joystick driving (TOUCH-FIRST — this is a mobile game):
## the wired touch joystick now steers + drives the cart
## (joystick x = steer, joystick up = forward, down = reverse),
## same convention as the motorcycle. Arrow keys / WASD remain
## ONLY as a desktop fallback. Same enter/exit interface as car.gd.
## No physics body in Slice 2 (flat ground, houses have no collision
## in this scene either) — movement is position-based, stated plainly.
## Slice 42 cart driving-physics polish (audit plan item 5, first
## parity vehicle — same pattern as the Slice 26 car, Slice 31
## motorcycle, Slice 33 tuk-tuk, and Slice 36 bicycle polishes):
## the cart stays a position-based Node3D — NO physics-body
## migration in this round (stated as deferred: the position model
## already preserves enter/exit, the Slice 24 camera-collision
## behaviour, and the HUD speed readout, and a body swap would
## rework collision and camera retargeting for no measured
## benefit). What changed is the TUNING inside that model,
## measured headlessly before/after (table in README): a drive
## acceleration curve (soft launch, strong mid-range, taper near
## top speed), a real brake (stronger than driving, only while
## rolling forward; reverse engages from near-stop, capped at the
## old 0.4 ratio), speed-dependent steering (agile at low speed,
## stable at top speed — the old constant rate was equally twitchy
## everywhere), steering smoothing (no snap), a much longer
## rolling coast (a cart keeps rolling when you stop driving —
## the old stop rate halted it in 2.4 s), and wheels that
## genuinely roll at ground speed (the old code had NO wheel code
## at all — the BEFORE harness proved it: 0 rad of wheel rotation
## over 1 s at top speed while the cart travelled 6 m; fixed with
## rotate_object_local around local Y, the same lesson as the
## Slice 26/31/33/36 fixes; the wheel mesh's cylinder axis is its
## local Y, which the scene basis maps to the cart's X axle).
## Driving FEEL cannot be verified headlessly — the owner's
## on-device verdict decides whether this tuning feels right.
## Top speed stays 6.0 on purpose: player.gd's HUD SpeedBar
## uses vmax["Cart"] = 6.0, so changing it would break the
## bar. Reverse cap stays 0.4 for the same reason (the old code
## already clamped there). The cart has NO headlight (the
## Slice 13 Lights button covers car/motorcycle/tuk-tuk only) —
## stated, not added here. This file touches no materials and no
## scenes, so every other vehicle's look is unaffected.

@export var max_speed: float = 6.0
@export var accel: float = 5.0
@export var turn_rate: float = 1.8
@export var high_speed_turn_rate: float = 0.8
@export var brake_force: float = 10.0
@export var reverse_speed_ratio: float = 0.4
@export var coast_drag: float = 1.2
@export var steer_response: float = 8.0
@export var wheel_radius: float = 0.35

var driver: Node = null
var speed: float = 0.0
var steer_smooth: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	steer_smooth = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

## Drive curve: soft launch (0.55 at standstill, so the cart does
## not jerk), full pull through the mid-range, taper to 0.5 at top
## speed (so top speed is approached, not slammed into).
func _accel_curve(speed_ratio: float) -> float:
	if speed_ratio < 0.3:
		return 0.55 + 0.45 * (speed_ratio / 0.3)
	return 1.0 - 0.5 * ((speed_ratio - 0.3) / 0.7)

func _process(delta: float) -> void:
	if driver == null:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_exit_cart()
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
			# Real brake: stronger than driving, and it never
			# rolls the cart backwards by itself.
			speed = maxf(0.0, speed - brake_force * (-fwd) * delta)
		else:
			# Near-stop: reverse engages, capped below.
			speed += fwd * accel * _accel_curve(ratio) * delta
	else:
		# Coasting: a cart keeps rolling when you stop driving —
		# gentle drag only, much longer than the old accel*0.5
		# stop, so the cart keeps its momentum.
		speed = move_toward(speed, 0.0, coast_drag * delta)
	speed = clamp(speed, -max_speed * reverse_speed_ratio, max_speed)
	# Steering smoothing: the cart turns toward the input instead
	# of snapping to it (weight feel, no twitch on small inputs).
	steer_smooth = move_toward(steer_smooth, steer, steer_response * delta)
	# Speed-dependent steering: agile at low speed, stable at top
	# speed (the old constant rate was equally twitchy everywhere).
	var turn := lerpf(turn_rate, high_speed_turn_rate, ratio)
	rotation.y -= steer_smooth * turn * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	position += forward * speed * delta
	# Wheels roll at ground speed. The wheel mesh's cylinder axis
	# is its local Y (which the scene basis maps to the cart's X
	# axle), so this must be rotate_object_local around local Y:
	# plain rotate_y turns about the parent Y axis instead, which
	# yaws the wheels like steering instead of rolling them
	# (same lesson as the Slice 26/31/33/36 fixes; the BEFORE
	# harness proved this cart had no wheel code at all).
	# Rolling without slipping: spin rate = speed / radius.
	var spin := speed * delta / wheel_radius
	for wname in ["CartWheelL", "CartWheelR"]:
		var w := get_node_or_null(wname)
		if w != null:
			w.rotate_object_local(Vector3(0, 1, 0), spin)

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_cart()

func _exit_cart() -> void:
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
	p.global_position = spot
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
