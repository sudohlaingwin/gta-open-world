extends CharacterBody3D
## Slice 1 car: simple drivable car.
## While driving: arrow keys / WASD steer + accelerate, Enter/Space exits.

@export var max_speed: float = 14.0
@export var accel: float = 8.0
@export var turn_rate: float = 1.8

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
		_exit_car()
		return
	var fwd := Input.get_axis("ui_down", "ui_up")
	var steer := Input.get_axis("ui_left", "ui_right")
	speed += fwd * accel * delta
	speed = clamp(speed, -max_speed * 0.4, max_speed)
	# Gentle friction when no input.
	if fwd == 0.0:
		speed = move_toward(speed, 0.0, accel * 0.5 * delta)
	rotation.y -= steer * turn_rate * delta * (1.0 if speed >= 0.0 else -1.0)
	var forward := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity = forward * speed
	move_and_slide()

## Slice 8 touch exit: the on-screen Vehicle button calls this.
func exit_vehicle() -> void:
	_exit_car()

func _exit_car() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	speed = 0.0
	velocity = Vector3.ZERO
	# Step out beside the car so the player is not stuck inside it.
	p.global_position = global_position + Vector3(2.0, 0.5, 0.0)
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.leave_vehicle()
