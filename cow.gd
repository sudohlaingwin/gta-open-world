extends Node3D
## Slice 7 cow: RIDEABLE (was a scenery stub in Slices 1-6).
## Owner-spec item: the player can ride a cow, not just see one.
## Same enter/exit interface as car.gd/cart.gd: walk within 4 m,
## Enter/Space (ui_accept) to mount, Enter/Space again to dismount.
## Movement is position-based (flat ground, like the cart): WASD /
## arrow keys move the cow in that world direction and the cow faces
## its direction of travel; the wired touch joystick works too via
## the driver's touch_vector. Walk 3.0, trot 4.5 with Shift (physical
## key, no undefined input action) or, TOUCH-FIRST, by holding the
## on-screen Sprint button (driver.touch_sprint, Slice 9).
## The camera retargets to the cow while riding and back to the
## player on dismount (see Slice 7 note in README.md: previously
## the camera stayed at the mount point).
## Slice 45 cow driving-physics polish (audit plan item 5, fourth
## parity vehicle — same pattern as the Slice 26 car, Slice 31
## motorcycle, Slice 33 tuk-tuk, Slice 36 bicycle, Slice 42 cart,
## Slice 43 horse, and Slice 44 elephant polishes): the cow stays a
## position-based Node3D — NO physics-body migration in this round
## (stated as deferred: the position model already preserves
## enter/exit, the Slice 24 camera-collision behaviour, the Slice 41
## driver-body fix, and the HUD speed readout, and a body swap
## would rework collision and camera retargeting for no measured
## benefit). What changed is the TUNING inside that model,
## measured headlessly before/after (table in README). The cow
## keeps its own character, it is NOT converted to the cart's
## forward/steer model: joystick direction is still the travel
## direction and the cow still faces its direction of travel. What
## changed inside that convention: a drive acceleration curve
## (soft launch, strong mid-range, taper near top speed), a real
## brake (pushing roughly opposite to the facing brakes hard
## toward a stop instead of carrying full speed into the new
## direction — the old code never braked at all: opposite input
## kept speed 4.5 and just walked the other way), speed-dependent
## turning (agile at low speed, stable at top speed — the old
## fixed 10.0/s facing lerp snapped equally fast everywhere),
## turning at a bounded rate (the bound IS the smoothing — no
## snap), and a much longer rolling coast (the cow keeps rolling
## along its facing when you release the joystick — the old code
## froze position outright on release and only decayed a hidden
## speed number). Two plainly stated behaviour notes: the cow
## now walks along its FACING and arcs toward the joystick
## direction, instead of sliding sideways along the input
## direction while its body snapped around (that slide is what
## made the old turn rate meaningless); and the cow has NO
## reverse gear, before or after — it turns around and walks
## (so there is no reverse top to report, and top speeds are
## unchanged: walk 3.0, trot 4.5 = HUD vmax["Cow"]). The cow's
## reverse gate is angular, not speed-based: while the joystick
## points more than 90 degrees away from the facing, the cow
## brakes to a stop and turns in place, and only accelerates
## the new way once the facing is within 90 degrees of the
## input. The Slice 9
## leg-swing + body-bob animation is UNCHANGED (its pace was
## already speed-scaled: walk_phase advances with speed * 2.5).
## Driving FEEL cannot be verified headlessly — the owner's
## on-device verdict decides whether this tuning feels right.
## This file touches no materials and no scenes, so every other
## vehicle's look is unaffected.

@export var walk_speed: float = 3.0
@export var trot_multiplier: float = 1.5
@export var accel: float = 4.0
@export var max_speed: float = 4.5
@export var turn_rate: float = 2.0
@export var high_speed_turn_rate: float = 1.0
@export var brake_force: float = 8.0
@export var coast_drag: float = 1.2

var driver: Node = null
var speed: float = 0.0
var walk_phase: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

## Drive curve: soft launch (0.55 at standstill, so the cow does
## not jerk), full pull through the mid-range, taper to 0.5 at top
## speed (so top speed is approached, not slammed into).
func _accel_curve(speed_ratio: float) -> float:
	if speed_ratio < 0.3:
		return 0.55 + 0.45 * (speed_ratio / 0.3)
	return 1.0 - 0.5 * ((speed_ratio - 0.3) / 0.7)

func _process(delta: float) -> void:
	if driver == null:
		_animate_walk(delta, false)
		return
	if Input.is_action_just_pressed("ui_accept"):
		_exit_cow()
		return
	var ix := Input.get_axis("ui_left", "ui_right")
	var iz := Input.get_axis("ui_up", "ui_down")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		ix = driver.touch_vector.x
		iz = driver.touch_vector.y
	var dir := Vector3(ix, 0.0, iz)
	var ratio := speed / max_speed
	# Speed-dependent turning: agile at low speed, stable at top
	# speed (the old fixed 10.0/s facing lerp snapped equally
	# fast everywhere). The bounded rate IS the smoothing.
	var turn := lerpf(turn_rate, high_speed_turn_rate, ratio)
	if dir.length() > 0.01:
		dir = dir.normalized()
		var target_speed := walk_speed
		if Input.is_physical_key_pressed(KEY_SHIFT) or driver.get("touch_sprint") == true:
			target_speed *= trot_multiplier
		var target_angle := atan2(dir.x, dir.z)
		var angle_diff := wrapf(target_angle - rotation.y, -PI, PI)
		rotation.y += clampf(angle_diff, -turn * delta, turn * delta)
		if cos(angle_diff) < 0.0:
			# Real brake: pushing roughly opposite to the facing
			# (more than 90 degrees away) brakes hard toward a
			# stop instead of carrying full speed into the new
			# direction, and the cow keeps turning in place
			# while stopped. It only accelerates the new way
			# once the facing is within 90 degrees of the
			# input — that angle IS the cow's reverse gate
			# (there is no reverse gear to engage from
			# near-stop, the way a wheeled vehicle has).
			# Braking never pushes the cow backwards by itself
			# (speed is a scalar, floored at zero).
			speed = maxf(0.0, speed - brake_force * delta)
		else:
			speed = move_toward(speed, target_speed, accel * _accel_curve(ratio) * delta)
		# The cow walks along its facing, arcing toward the
		# joystick direction — not sideways along the input
		# direction while its body snaps around (old behaviour).
		var forward := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
		position += forward * speed * delta
	else:
		# Coasting: the cow keeps rolling along its facing on
		# momentum — gentle drag only, much longer than the old
		# accel-rate stop, which also froze position outright.
		speed = move_toward(speed, 0.0, coast_drag * delta)
		if speed > 0.0:
			var forward := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
			position += forward * speed * delta
	_animate_walk(delta, speed > 0.1)

## Slice 9: diagonal-pair leg swing + body bob while moving.
## All lookups are guarded, so an older scene without the leg
## nodes still runs (it just shows no animation, not a crash).
func _animate_walk(delta: float, moving: bool) -> void:
	if moving:
		walk_phase += delta * speed * 2.5
	var swing := 0.0
	if moving:
		swing = sin(walk_phase) * 0.5
	var legs := {
		"LegFL": swing,
		"LegBR": swing,
		"LegFR": -swing,
		"LegBL": -swing,
	}
	for leg_name in legs:
		var leg := get_node_or_null(leg_name) as Node3D
		if leg != null:
			leg.rotation.x = lerp(leg.rotation.x, legs[leg_name], 10.0 * delta)
	var body := get_node_or_null("MeshInstance3D") as Node3D
	if body != null:
		var bob := 0.0
		if moving:
			bob = sin(walk_phase * 2.0) * 0.05
		body.position.y = lerp(body.position.y, bob, 10.0 * delta)

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_cow()

func _exit_cow() -> void:
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
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.global_position = spot
	p.leave_vehicle()
