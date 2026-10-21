extends CharacterBody3D
## Slice 3 motorcycle: drivable, faster and nimbler than the car.
## Same enter/exit interface as car.gd/cart.gd (Enter/Space).
## Steering also reads the driver's touch_vector (joystick), so the
## wired-joystick path works here too — not a signal that nobody
## connects. Leans into turns (visual mesh tilt only).

@export var max_speed: float = 18.0
@export var accel: float = 11.0
@export var turn_rate: float = 2.6

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
		_exit_bike()
		return
	var fwd := Input.get_axis("ui_down", "ui_up")
	var steer := Input.get_axis("ui_left", "ui_right")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		steer = driver.touch_vector.x
		fwd = -driver.touch_vector.y
	speed += fwd * accel * delta
	speed = clamp(speed, -max_speed * 0.3, max_speed)
	if fwd == 0.0:
		speed = move_toward(speed, 0.0, accel * 0.5 * delta)
	rotation.y -= steer * turn_rate * delta * (1.0 if speed >= 0.0 else -1.0)
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh != null:
		mesh.rotation.z = -steer * 0.25
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity = forward * speed
	move_and_slide()

func _exit_bike() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	speed = 0.0
	velocity = Vector3.ZERO
	p.global_position = global_position + Vector3(2.0, 0.5, 0.0)
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
