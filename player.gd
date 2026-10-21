extends CharacterBody3D
## Slice 2 player: walk + sprint + jump + enter/exit car AND cart.
## Walk: arrow keys / WASD, or the touch joystick (touch_vector).
## Sprint: hold Shift. Jump: J key (on floor only).
## Enter/exit vehicle: Enter/Space (ui_accept) near a vehicle.
## Talk to a villager: walk within 3.5 m and press E (physical key,
## no custom input action needed) — calls the nearest villager's
## talk_to(), which faces the player and shows its greeting bubble.

@export var walk_speed: float = 5.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 5.0

var driving: bool = false
var driving_vehicle: Node = null
var touch_vector: Vector2 = Vector2.ZERO
var e_was_pressed: bool = false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if driving:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
		if Input.is_physical_key_pressed(KEY_J):
			velocity.y = jump_velocity
	var ix := Input.get_axis("ui_left", "ui_right")
	var iz := Input.get_axis("ui_up", "ui_down")
	if touch_vector != Vector2.ZERO:
		ix = touch_vector.x
		iz = touch_vector.y
	var dir := Vector3(ix, 0.0, iz).normalized()
	var speed := walk_speed
	if Input.is_physical_key_pressed(KEY_SHIFT):
		speed *= sprint_multiplier
	if dir != Vector3.ZERO:
		rotation.y = atan2(dir.x, dir.z)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	if Input.is_action_just_pressed("ui_accept"):
		_try_enter_vehicle()
	var e_now := Input.is_physical_key_pressed(KEY_E)
	if e_now and not e_was_pressed:
		_try_talk()
	e_was_pressed = e_now

func _try_talk() -> void:
	var best: Node = null
	var best_dist: float = 3.5
	for villager in get_tree().get_nodes_in_group("villagers"):
		var d := global_position.distance_to(villager.global_position)
		if d < best_dist:
			best_dist = d
			best = villager
	if best != null and best.has_method("talk_to"):
		best.call("talk_to", global_position)

func _try_enter_vehicle() -> void:
	for name in ["Car", "Cart", "Motorcycle", "Airplane"]:
		var v := get_node_or_null("../" + name)
		if v != null and global_position.distance_to(v.global_position) < 4.0:
			driving = true
			driving_vehicle = v
			visible = false
			v.start_driving(self)
			return

func leave_vehicle() -> void:
	driving = false
	driving_vehicle = null
	visible = true
