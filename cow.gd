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
## Slice 9 walk animation (primitive, honest — not a skinned rig):
## while the cow moves, its four leg meshes swing in diagonal pairs
## and the body bobs slightly; standing still, the legs ease back to
## neutral. Legs are LegFL / LegFR / LegBL / LegBR in main.tscn.

@export var walk_speed: float = 3.0
@export var trot_multiplier: float = 1.5
@export var accel: float = 4.0

var driver: Node = null
var speed: float = 0.0
var walk_phase: float = 0.0

func start_driving(p: Node) -> void:
	driver = p
	speed = 0.0
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("target", get_path())

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
	if dir.length() > 0.01:
		dir = dir.normalized()
		var target_speed := walk_speed
		if Input.is_physical_key_pressed(KEY_SHIFT) or driver.get("touch_sprint") == true:
			target_speed *= trot_multiplier
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 10.0 * delta)
		speed = move_toward(speed, target_speed, accel * delta)
		position += dir * speed * delta
	else:
		speed = move_toward(speed, 0.0, accel * delta)
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
