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

@export var max_speed: float = 5.0
@export var accel: float = 4.0
@export var turn_rate: float = 1.0

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
		_exit_boat()
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
	p.global_position = spot
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
