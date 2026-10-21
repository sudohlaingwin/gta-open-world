extends Node3D
## Slice 2 cart: DRIVABLE (slower than the car).
## Slice 9 joystick driving (TOUCH-FIRST — this is a mobile game):
## the wired touch joystick now steers + drives the cart
## (joystick x = steer, joystick up = forward, down = reverse),
## same convention as the motorcycle. Arrow keys / WASD remain
## ONLY as a desktop fallback. Same enter/exit interface as car.gd.
## No physics body in Slice 2 (flat ground, houses have no collision
## in this scene either) — movement is position-based, stated plainly.

@export var max_speed: float = 6.0
@export var accel: float = 5.0
@export var turn_rate: float = 1.2

var driver: Node = null
var speed: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

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
	speed += fwd * accel * delta
	speed = clamp(speed, -max_speed * 0.4, max_speed)
	if fwd == 0.0:
		speed = move_toward(speed, 0.0, accel * 0.5 * delta)
	rotation.y -= steer * turn_rate * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	position += forward * speed * delta

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_cart()

func _exit_cart() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	speed = 0.0
	p.global_position = global_position + Vector3(2.0, 0.5, 0.0)
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
