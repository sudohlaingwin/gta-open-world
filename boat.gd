extends Node3D
## Slice 14 rowboat: RIDEABLE on the river (and anywhere else, like
## the cart — movement is position-based, stated plainly).
## TOUCH-FIRST — this is a mobile game: the wired touch joystick
## steers + rows the boat (joystick x = steer, joystick up =
## forward, down = reverse), same convention as the cart and the
## motorcycle. Arrow keys / WASD remain ONLY as a desktop
## fallback. Same enter/exit interface as car.gd / cart.gd, so
## the on-screen Vehicle button enters and exits it, and the
## camera retargets to it while ridden.
## Slice 46 boat driving-physics polish (audit plan item 5, fifth
## parity vehicle — same pattern as the Slice 26 car, Slice 31
## motorcycle, Slice 33 tuk-tuk, Slice 36 bicycle, Slice 42 cart,
## Slice 43 horse, Slice 44 elephant, and Slice 45 cow polishes):
## the boat stays a position-based Node3D — NO physics-body
## migration in this round (stated as deferred: the position model
## already preserves enter/exit, the Slice 24 camera-collision
## behaviour, the Slice 41 driver-body fix, and the HUD speed
## readout, and a body swap would rework collision and camera
## retargeting for no measured benefit). What changed is the
## TUNING inside that model, measured headlessly before/after
## (table in README): a drive acceleration curve (soft launch,
## strong mid-range, taper near top speed), a real brake
## (stronger than driving, only while rolling forward; reverse
## engages from near-stop, capped at the old 0.4 ratio), speed-
## dependent steering (agile at low speed, stable at top speed —
## the old constant rate was equally twitchy everywhere),
## steering smoothing (no snap), and a much longer rolling coast
## — a boat glides on water, so its drag (0.8/s) is deliberately
## lower than the land vehicles' 1.2/s: from top speed the boat
## now glides about 15.6 m, longer than the cart's 14.2 m from a
## higher top speed, which is the measured water-glide character,
## not an assertion. The old coast decayed at accel*0.5 = 2.0/s
## and halted the boat in 2.5 s. Top speed stays 5.0 on purpose:
## player.gd's HUD SpeedBar uses vmax["Boat"] = 5.0, so changing
## it would break the bar. Reverse cap stays 0.4 for the same
## reason (the old code already clamped there). The reverse
## steering flip is kept (unlike the opponent's slice-67 horse,
## which steers forward-handed while reversing): a reversing
## boat still turns the way its stern swings. PLAINLY STATED:
## the boat has NO oar animation and NO water bob — OarL/OarR
## are static meshes in the scene and no animation code exists
## for them in this script or anywhere else, so there is nothing
## to keep working here; rowing animation is deferred, not
## silently added in a physics round and not claimed. This file
## touches no materials and no scenes, so every other vehicle's
## look is unaffected. Driving FEEL cannot be verified
## headlessly — the owner's on-device verdict decides whether
## this tuning feels right.

@export var max_speed: float = 5.0
@export var accel: float = 4.0
@export var turn_rate: float = 1.6
@export var high_speed_turn_rate: float = 0.8
@export var brake_force: float = 8.0
@export var reverse_speed_ratio: float = 0.4
@export var coast_drag: float = 0.8
@export var steer_response: float = 8.0

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

## Drive curve: soft launch (0.55 at standstill, so the boat does
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
		_exit_boat()
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
			# rolls the boat backwards by itself.
			speed = maxf(0.0, speed - brake_force * (-fwd) * delta)
		else:
			# Near-stop: reverse engages, capped below.
			speed += fwd * accel * _accel_curve(ratio) * delta
	else:
		# Coasting: a boat glides on water when you stop rowing
		# — gentle drag only, much longer than the old
		# accel*0.5 stop, so the boat keeps its momentum.
		speed = move_toward(speed, 0.0, coast_drag * delta)
	speed = clamp(speed, -max_speed * reverse_speed_ratio, max_speed)
	# Steering smoothing: the boat turns toward the input instead
	# of snapping to it (weight feel, no twitch on small inputs).
	steer_smooth = move_toward(steer_smooth, steer, steer_response * delta)
	# Speed-dependent steering: agile at low speed, stable at top
	# speed (the old constant rate was equally twitchy everywhere).
	var turn := lerpf(turn_rate, high_speed_turn_rate, ratio)
	rotation.y -= steer_smooth * turn * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	position += forward * speed * delta

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_boat()

func _exit_boat() -> void:
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
