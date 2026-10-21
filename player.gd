extends CharacterBody3D
## Slice 1 player: third-person walk + enter/exit the car.
## Walk with arrow keys / WASD (ui_* actions, Godot defaults).
## Press Enter/Space (ui_accept) near the car to get in/out.

@export var walk_speed: float = 5.0
@export var turn_speed: float = 2.5

var driving: bool = false
var car: Node = null

func _ready() -> void:
	car = get_node_or_null("../Car")

func _physics_process(delta: float) -> void:
	if driving:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# Gravity so the player stays on the ground collision.
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	var ix := Input.get_axis("ui_left", "ui_right")
	var iz := Input.get_axis("ui_up", "ui_down")
	# Camera-relative forward: camera looks along -Z of the player rig.
	# Keep it simple for Slice 1: world-aligned movement, player faces
	# the walk direction.
	var dir := Vector3(ix, 0.0, iz).normalized()
	if dir != Vector3.ZERO:
		rotation.y = atan2(dir.x, dir.z)
		velocity.x = dir.x * walk_speed
		velocity.z = dir.z * walk_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	if Input.is_action_just_pressed("ui_accept"):
		_try_enter_car()

func _try_enter_car() -> void:
	if car == null:
		return
	# Only enter when close to the car (Slice 1 rule, 4 metres).
	if global_position.distance_to(car.global_position) < 4.0:
		driving = true
		visible = false
		car.start_driving(self)
