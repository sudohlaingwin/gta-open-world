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
## Slice 55 driving-assistance modes (audit item 9). The @export
## values above are the Balanced mode exactly (Slice 26 polish);
## Arcade (0) and Realistic (2) only scale them at drive time,
## read live from SaveManager.driving_mode, so a change made in
## the pause Settings screen applies the moment play resumes
## with no re-enter and no restart. Top speed, the acceleration
## curve and the reverse cap are identical in all three modes.
## Arcade: brake x1.5 (shorter stop), coast x0.6 (gentler,
## longer roll), steering response x1.25 (more settled),
## high-speed turn rate x1.3 (still responds at top speed),
## turn scrub x0.5 (turns bleed less speed).
## Realistic: brake x0.75 (longer stop), coast x1.5 (heavier
## drag, shorter roll), steering response x0.75 (heavier),
## high-speed turn rate x0.7 (tighter at speed), scrub x1.5.
var _sm_cached: Node = null


func _driving_mode() -> int:
	if _sm_cached != null and is_instance_valid(_sm_cached):
		return clampi(int(_sm_cached.get("driving_mode")), 0, 2)
	_sm_cached = get_node_or_null("/root/SaveManager")
	if _sm_cached == null:
		return 1
	return clampi(int(_sm_cached.get("driving_mode")), 0, 2)


func _mode_brake() -> float:
	match _driving_mode():
		0:
			return brake_force * 1.5
		2:
			return brake_force * 0.75
		_:
			return brake_force


func _mode_coast() -> float:
	match _driving_mode():
		0:
			return coast_drag * 0.6
		2:
			return coast_drag * 1.5
		_:
			return coast_drag


func _mode_steer_response() -> float:
	match _driving_mode():
		0:
			return steer_response * 1.25
		2:
			return steer_response * 0.75
		_:
			return steer_response


func _mode_high_turn() -> float:
	match _driving_mode():
		0:
			return high_speed_turn_rate * 1.3
		2:
			return high_speed_turn_rate * 0.7
		_:
			return high_speed_turn_rate


func _mode_scrub() -> float:
	match _driving_mode():
		0:
			return turn_scrub * 0.5
		2:
			return turn_scrub * 1.5
		_:
			return turn_scrub

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
		# Slice 96 JOYSTICK SMOOTHNESS FIX (owner video verdict
		# 2026-10-23 ~19:56: driving felt jerky, not PUBG-smooth,
		# camera swinging while driving). DIAGNOSIS, measured
		# from the code, not guessed: the joystick itself is
		# already analog and continuous across its deadzone
		# (joystick.gd rescales past the deadzone, no jump at
		# the edge), and steering smoothing already existed
		# (move_toward at steer_response below). The real defect
		# was the DIRECTION FRAME: on-foot movement has been
		# CAMERA-relative since Slice 53 (player.gd rotates the
		# joystick vector by the camera orbit_angle), but EVERY
		# vehicle — this car included — used the joystick RAW,
		# screen-fixed. So after any camera orbit the car drove
		# sideways or backwards on screen while the player
		# pushed "forward", and every orbit drag flipped the
		# drive direction — that reads as jerk and unplayable
		# even though no single frame snaps. FIX: the car now
		# steers toward a CAMERA-relative desired direction,
		# exactly like walking: joystick-up is the direction
		# the camera looks. steer is PROPORTIONAL to the
		# heading error via sin (full lock past ~30 deg
		# off), then still smoothed by the existing move_toward
		# (8.0/s Balanced, 10.0 Arcade, 6.0 Realistic — the
		# smoothing rate is unchanged, the target is now
		# stable). Throttle follows the desired direction's
		# forward component, so the car turns toward the
		# joystick direction and then accelerates into it
		# instead of driving screen-up regardless of view.
		# Keyboard fallback below is untouched; the other
		# vehicles still use raw screen-fixed steering (their
		# fix is next-round scope — stated, not hidden).
		var tv: Vector2 = driver.touch_vector
		var cam := get_node_or_null("../FollowCamera")
		if cam != null and cam.get("orbit_angle") != null:
			var o := float(cam.get("orbit_angle"))
			var view_fwd := Vector3(-sin(o), 0.0, -cos(o))
			var view_rgt := Vector3(cos(o), 0.0, -sin(o))
			var desired := (view_rgt * tv.x + view_fwd * (-tv.y))
			if desired.length() > 0.05:
				desired = desired.normalized()
				var want_rot := atan2(-desired.x, -desired.z)
				var diff := want_rot - rotation.y
				# Proportional steer via sin, NOT a wrapped
				# angle: a wrapped error flips sign at
				# +/-180 deg and the car would chatter in
				# place instead of U-turning, while sin is
				# continuous through the wrap (sin(180 deg)
				# = sin(-180 deg) = 0) and keeps one turning
				# direction. Sign: rotation.y DECREASES for
				# positive steer when driving forward
				# (joystick right turns the car right), so
				# forward steer is -sin(diff); when reversing
				# the rotation factor flips, so reverse steer
				# is +sin of the REAR error (the rear, not
				# the nose, follows the joystick while
				# backing). Full lock past ~30 deg off
				# (sin 0.5 x 2.0), gentle near alignment,
				# zero at alignment. Exact 180.0 deg is a
				# degenerate fixed point (sin = 0) — a real
				# thumb is never exactly there, and any 1
				# deg offset turns the car.
				# Throttle rule (sim-caught, Slice 96): the
				# first draft used dot(desired, car_fwd), so
				# a joystick direction behind the car made it
				# REVERSE — and the reverse turn-flip then
				# drove it to the antipodal fixed point and
				# stuck it there. Instead, joystick-up (or
				# sideways) always drives FORWARD toward the
				# desired direction — the car U-turns, it
				# never backs away from a forward command.
				# Joystick-down keeps the original brake /
				# reverse behaviour.
				if -tv.y >= 0.0:
					steer = clampf(-sin(diff) * 2.0, -1.0, 1.0)
					fwd = tv.length()
				else:
					var rear_want := atan2(desired.x, desired.z)
					steer = clampf(sin(rear_want - rotation.y) * 2.0, -1.0, 1.0)
					fwd = -tv.y
			else:
				steer = 0.0
				fwd = 0.0
		else:
			steer = tv.x
			fwd = -tv.y
	var ratio := absf(speed) / max_speed
	if fwd > 0.0:
		speed += fwd * accel * _accel_curve(ratio) * delta
	elif fwd < 0.0:
		if speed > 0.5:
			# Real brake: stronger than acceleration, and it never
			# rolls the car backwards by itself.
			speed = maxf(0.0, speed - _mode_brake() * (-fwd) * delta)
		else:
			# Near-stop: reverse engages, capped below.
			speed += fwd * accel * _accel_curve(ratio) * delta
	else:
		# Coasting: gentle rolling drag, longer than the old
		# accel*0.5 stop, so the car keeps its momentum.
		speed = move_toward(speed, 0.0, _mode_coast() * delta)
	speed = clamp(speed, -max_speed * reverse_speed_ratio, max_speed)
	# Steering smoothing: the wheel turns toward the input instead
	# of snapping to it (weight feel, no twitch on small inputs).
	steer_smooth = move_toward(steer_smooth, steer, _mode_steer_response() * delta)
	# Speed-dependent steering: agile at low speed, stable at top
	# speed (the old constant rate was equally twitchy everywhere).
	var turn := lerpf(turn_rate, _mode_high_turn(), ratio)
	# Turn scrub: a hard turn at speed bleeds a little speed.
	if absf(steer_smooth) > 0.5 and ratio > 0.5:
		speed = move_toward(speed, 0.0, _mode_scrub() * absf(steer_smooth) * ratio * delta)
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
	# Slice 38: never step out into a wall — probe for a free spot
	# first; if every candidate is blocked, stay in the vehicle
	# and say so instead of teleporting into a collider.
	var spot: Vector3 = p.find_free_exit_spot(self, Vector3(2.0, 0.5, 0.0))
	if spot == Vector3.INF:
		p.show_exit_blocked()
		return
	driver = null
	speed = 0.0
	steer_smooth = 0.0
	velocity = Vector3.ZERO
	# Step out beside the car so the player is not stuck inside it.
	p.global_position = spot
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
