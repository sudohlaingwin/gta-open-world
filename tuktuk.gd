extends CharacterBody3D
## Slice 16 tuk-tuk: RIDEABLE three-wheeler (slower than the car,
## faster than the bicycle — the village taxi). Same enter/exit
## interface as car.gd / bicycle.gd, so the on-screen Vehicle
## button enters and exits it and the camera retargets to it
## while ridden. TOUCH-FIRST — this is a mobile game: the wired
## touch joystick steers + accelerates (joystick x = steer,
## joystick up = forward, down = reverse). Arrow keys / WASD
## remain ONLY as a desktop fallback. The three wheels spin
## around their own (cylinder) axis at ground speed, exactly
## like the bicycle wheels since Slice 15.
## Slice 33 tuk-tuk driving-physics polish (direction-independent,
## master prompt section 8, one vehicle at a time — same pattern
## as the Slice 26 car and Slice 31 motorcycle polishes): the
## tuk-tuk stays a CharacterBody3D kinematic driver — NO
## VehicleBody3D migration in this round (stated as deferred:
## the kinematic model already preserves enter/exit, the Slice
## 24 camera-collision behaviour, and the HUD speed readout,
## and a VehicleBody3D swap would rework collision, wheels, and
## camera retargeting for no measured benefit). What changed is
## the TUNING inside that model, measured headlessly before/after
## (table in README): acceleration curve (soft launch, strong
## mid-range, taper near top speed), a real brake (stronger than
## acceleration, only while moving forward; reverse engages from
## near-stop, capped at the old 0.4 ratio), speed-dependent
## steering (agile at low speed, stable at top speed — the old
## constant rate was equally twitchy everywhere), steering
## smoothing (no snap), gentle turn scrub (hard turns at speed
## bleed a little speed — weight feel), longer rolling coast,
## and wheels that REALLY roll at ground speed (the old code
## spun them with rotate_y, which the Slice 33 harness proved
## yaws them about the parent Y axis instead of rolling them:
## theta about the wheel's own local Y was 0 while total
## rotation was exactly speed/radius*dt — same bug the Slice 31
## motorcycle fix caught; fixed here with rotate_object_local
## around local Y, verified by the same basis math).
## No lean banking: a three-wheeler stays upright (unlike the
## motorcycle's lean) — its body does not tilt into turns.
## Riding FEEL cannot be verified headlessly — the owner's
## on-device verdict decides whether this tuning feels right.
## Top speed stays 11.0 on purpose: player.gd's HUD SpeedBar
## uses vmax["TukTuk"] = 11.0, so changing it would break the
## bar. Reverse cap stays 0.4 for the same reason (the old code
## already clamped there). The Slice 32 joystick deadzone keeps
## applying unchanged: steering still reads the driver's
## deadzone-filtered touch_vector, exactly as before.

@export var max_speed: float = 11.0
@export var accel: float = 6.0
@export var turn_rate: float = 2.0
@export var high_speed_turn_rate: float = 1.0
@export var brake_force: float = 12.0
@export var reverse_speed_ratio: float = 0.4
@export var coast_drag: float = 2.5
@export var steer_response: float = 8.0
@export var turn_scrub: float = 1.0
@export var wheel_radius: float = 0.35

var driver: Node = null
var speed: float = 0.0
var steer_smooth: float = 0.0
var wheels: Array = []

func _ready() -> void:
	for wname in ["TukWheelF", "TukWheelL", "TukWheelR"]:
		var w := get_node_or_null(wname)
		if w != null:
			wheels.append(w)

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	steer_smooth = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

## Acceleration curve: soft launch (0.55 at standstill, so the
## tuk-tuk does not jerk), full pull through the mid-range,
## taper to 0.5 at top speed (so top speed is approached, not
## slammed into).
func _accel_curve(speed_ratio: float) -> float:
	if speed_ratio < 0.3:
		return 0.55 + 0.45 * (speed_ratio / 0.3)
	return 1.0 - 0.5 * ((speed_ratio - 0.3) / 0.7)

func _physics_process(delta: float) -> void:
	if driver == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if Input.is_action_just_pressed("ui_accept"):
		_exit_tuktuk()
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
			# Real brake: stronger than acceleration, and it never
			# rolls the tuk-tuk backwards by itself.
			speed = maxf(0.0, speed - brake_force * (-fwd) * delta)
		else:
			# Near-stop: reverse engages, capped below.
			speed += fwd * accel * _accel_curve(ratio) * delta
	else:
		# Coasting: gentle rolling drag, longer than the old
		# accel*0.5 stop, so the tuk-tuk keeps its momentum.
		speed = move_toward(speed, 0.0, coast_drag * delta)
	speed = clamp(speed, -max_speed * reverse_speed_ratio, max_speed)
	# Steering smoothing: the wheel turns toward the input instead
	# of snapping to it (weight feel, no twitch on small inputs).
	steer_smooth = move_toward(steer_smooth, steer, steer_response * delta)
	# Speed-dependent steering: agile at low speed, stable at top
	# speed (the old constant rate was equally twitchy everywhere).
	var turn := lerpf(turn_rate, high_speed_turn_rate, ratio)
	# Turn scrub: a hard turn at speed bleeds a little speed.
	if absf(steer_smooth) > 0.5 and ratio > 0.5:
		speed = move_toward(speed, 0.0, turn_scrub * absf(steer_smooth) * ratio * delta)
	rotation.y -= steer_smooth * turn * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity = forward * speed
	move_and_slide()
	# Wheels roll at ground speed. The wheel mesh's cylinder axis
	# is its local Y (which the scene basis maps to the tuk-tuk's
	# X axle), so this must be rotate_object_local around local Y:
	# plain rotate_y turns about the parent Y axis instead, which
	# yaws the wheels like steering instead of rolling them
	# (proven by the Slice 33 harness basis math on the old code,
	# same lesson as the Slice 26 car and Slice 31 motorcycle
	# fixes). Rolling without slipping: spin rate = speed / radius.
	for w in wheels:
		w.rotate_object_local(Vector3(0, 1, 0), speed / wheel_radius * delta)

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_tuktuk()

func _exit_tuktuk() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	speed = 0.0
	steer_smooth = 0.0
	velocity = Vector3.ZERO
	# Step out beside the tuk-tuk so the player is not stuck in it.
	p.global_position = global_position + Vector3(2.0, 0.5, 0.0)
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
