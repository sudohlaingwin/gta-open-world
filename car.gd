extends CharacterBody3D
## Slice 1 car: simple drivable car.
## Slice 9 joystick driving (TOUCH-FIRST — this is a mobile game):
## the wired touch joystick now steers + accelerates the car
## (joystick x = steer, joystick up = forward, down = reverse),
## exactly like the motorcycle has done since Slice 3. Arrow keys /
## WASD remain ONLY as a desktop fallback. Enter/Space exits
## (the on-screen Vehicle button calls exit_vehicle() since Slice 8).
## Car driving-physics polish (direction-independent, master prompt
## section 8: "begin with one polished, functional car"):
## the car stays a CharacterBody3D kinematic driver — NO
## VehicleBody3D migration in this round (stated as deferred: the
## kinematic model already preserves enter/exit, the Slice 24
## camera-collision behaviour, and the HUD speed readout, and a
## VehicleBody3D swap would rework collision, wheels, and camera
## retargeting for no measured benefit). What changed is the
## TUNING inside that model, measured headlessly before/after:
## acceleration curve (soft launch, strong mid-range, taper near
## top speed), a real brake (stronger than acceleration, only
## while moving forward; reverse engages from near-stop),
## speed-dependent steering (agile at low speed, stable at top
## speed), steering smoothing (no snap), gentle turn scrub
## (hard turns at speed bleed a little speed — weight feel),
## longer rolling coast, and wheels that spin at ground speed.
## Driving FEEL cannot be verified headlessly — the owner's
## on-device verdict decides whether this tuning feels right.
## Top speed stays 14.0 on purpose: player.gd's HUD SpeedBar
## uses vmax["Car"] = 14.0, so changing it would break the bar.

@export var max_speed: float = 14.0
@export var accel: float = 8.0
@export var turn_rate: float = 2.2
@export var high_speed_turn_rate: float = 0.85
@export var brake_force: float = 16.0
@export var reverse_speed_ratio: float = 0.35
@export var coast_drag: float = 2.5
@export var steer_response: float = 8.0
@export var turn_scrub: float = 1.2
@export var wheel_radius: float = 0.35

var driver: Node = null
var speed: float = 0.0
var steer_smooth: float = 0.0
var wheels: Array = []

func _ready() -> void:
	for wname in ["WheelCar_p1_p13", "WheelCar_m1_p13", "WheelCar_p1_m13", "WheelCar_m1_m13"]:
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

## Acceleration curve: soft launch (0.55 at standstill, so the car
## does not jerk), full pull through the mid-range, taper to 0.5
## at top speed (so top speed is approached, not slammed into).
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
		_exit_car()
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
			# rolls the car backwards by itself.
			speed = maxf(0.0, speed - brake_force * (-fwd) * delta)
		else:
			# Near-stop: reverse engages, capped below.
			speed += fwd * accel * _accel_curve(ratio) * delta
	else:
		# Coasting: gentle rolling drag, longer than the old
		# accel*0.5 stop, so the car keeps its momentum.
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
	# is its local Y (which the scene basis maps to the car's X
	# axle), so this must be rotate_object_local around local Y:
	# plain rotate_y turns about the parent Y axis instead, which
	# would yaw the wheels like steering instead of rolling them
	# (caught by the headless world test, fixed before commit).
	# Rolling without slipping: spin rate = speed / radius.
	for w in wheels:
		w.rotate_object_local(Vector3(0, 1, 0), speed / wheel_radius * delta)

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_car()

func _exit_car() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	speed = 0.0
	steer_smooth = 0.0
	velocity = Vector3.ZERO
	# Step out beside the car so the player is not stuck inside it.
	p.global_position = global_position + Vector3(2.0, 0.5, 0.0)
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
