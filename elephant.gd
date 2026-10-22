extends CharacterBody3D
## Slice 18 elephant: RIDEABLE (owner-spec vehicles keep growing — the
## village elephant). Same enter/exit interface as car.gd / tuktuk.gd,
## so the on-screen Vehicle button enters and exits it and the camera
## retargets while ridden. TOUCH-FIRST — this is a mobile game: the
## wired touch joystick steers + walks (joystick x = steer, joystick
## up = forward, down = reverse). Arrow keys / WASD remain ONLY as a
## desktop fallback. Primitive, honest animation (not a skinned rig):
## four legs swing in diagonal pairs, the trunk sways, ears flap while
## moving; standing still everything eases back to neutral.

@export var max_speed: float = 6.0
@export var accel: float = 5.0
@export var turn_rate: float = 1.6

var driver: Node = null
var speed: float = 0.0
var walk_phase: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

func _physics_process(delta: float) -> void:
	if driver == null:
		velocity = Vector3.ZERO
		_animate(delta, false)
		move_and_slide()
		return
	if Input.is_action_just_pressed("ui_accept"):
		_exit_elephant()
		return
	var fwd := Input.get_axis("ui_down", "ui_up")
	var steer := Input.get_axis("ui_left", "ui_right")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		steer = driver.touch_vector.x
		fwd = -driver.touch_vector.y
	speed += fwd * accel * delta
	speed = clamp(speed, -max_speed * 0.4, max_speed)
	if fwd == 0.0:
		speed = move_toward(speed, 0.0, accel * 0.5 * delta)
	rotation.y -= steer * turn_rate * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity = forward * speed
	move_and_slide()
	_animate(delta, absf(speed) > 0.1)

func _animate(delta: float, moving: bool) -> void:
	if moving:
		walk_phase += delta * 6.0
	var s := sin(walk_phase) * 0.5 if moving else 0.0
	var legs := {"EleLegFL": s, "EleLegBR": s, "EleLegFR": -s, "EleLegBL": -s}
	for lname in legs:
		var leg := get_node_or_null(lname)
		if leg != null:
			leg.rotation.x = legs[lname]
	var trunk := get_node_or_null("EleTrunk")
	if trunk != null:
		trunk.rotation.x = sin(walk_phase * 0.5) * 0.2 if moving else 0.0
	for ename in ["EleEarL", "EleEarR"]:
		var ear := get_node_or_null(ename)
		if ear != null:
			ear.rotation.z = sin(walk_phase) * 0.3 if moving else 0.0

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_elephant()

func _exit_elephant() -> void:
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
	velocity = Vector3.ZERO
	# Step out beside the elephant so the player is not stuck in it.
	p.global_position = spot
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
