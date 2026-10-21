extends Node3D
## Slice 7 cow: RIDEABLE (was a scenery stub in Slices 1-6).
## Owner-spec item: the player can ride a cow, not just see one.
## Same enter/exit interface as car.gd/cart.gd: walk within 4 m,
## Enter/Space (ui_accept) to mount, Enter/Space again to dismount.
## Movement is position-based (flat ground, like the cart): WASD /
## arrow keys move the cow in that world direction and the cow faces
## its direction of travel; the wired touch joystick works too via
## the driver's touch_vector. Walk 3.0, trot 4.5 with Shift (physical
## key, no undefined input action). The camera retargets to the cow
## while riding and back to the player on dismount (see Slice 7 note
## in README.md: previously the camera stayed at the mount point).
## No walk animation yet — stated plainly, not faked.

@export var walk_speed: float = 3.0
@export var trot_multiplier: float = 1.5
@export var accel: float = 4.0

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
		_exit_cow()
		return
	var ix := Input.get_axis("ui_left", "ui_right")
	var iz := Input.get_axis("ui_up", "ui_down")
	if driver.get("touch_vector") != null and driver.touch_vector != Vector2.ZERO:
		ix = driver.touch_vector.x
		iz = driver.touch_vector.y
	var dir := Vector3(ix, 0.0, iz)
	if dir.length() > 0.01:
		dir = dir.normalized()
		var target_speed := walk_speed
		if Input.is_physical_key_pressed(KEY_SHIFT):
			target_speed *= trot_multiplier
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 10.0 * delta)
		speed = move_toward(speed, target_speed, accel * delta)
		position += dir * speed * delta
	else:
		speed = move_toward(speed, 0.0, accel * delta)

func _exit_cow() -> void:
	if driver == null:
		return
	var p: Node = driver
	driver = null
	speed = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", p.get_path())
	p.global_position = global_position + Vector3(2.0, 0.5, 0.0)
	p.leave_vehicle()
