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

@export var max_speed: float = 11.0
@export var accel: float = 6.0
@export var turn_rate: float = 2.0

var driver: Node = null
var speed: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

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
	speed += fwd * accel * delta
	speed = clamp(speed, -max_speed * 0.4, max_speed)
	if fwd == 0.0:
		speed = move_toward(speed, 0.0, accel * 0.5 * delta)
	rotation.y -= steer * turn_rate * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity = forward * speed
	move_and_slide()
	# Spin all three wheels around their own axis at ground speed
	# (wheel radius 0.35, same as the bicycle wheels).
	var spin := speed * delta / 0.35
	for wname in ["TukWheelF", "TukWheelL", "TukWheelR"]:
		var w := get_node_or_null(wname)
		if w != null:
			w.rotate_y(spin)

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_tuktuk()

func _exit_tuktuk() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	speed = 0.0
	velocity = Vector3.ZERO
	# Step out beside the tuk-tuk so the player is not stuck in it.
	p.global_position = global_position + Vector3(2.0, 0.5, 0.0)
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
