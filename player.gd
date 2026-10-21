extends CharacterBody3D
## Slice 2 player: walk + sprint + jump + enter/exit car AND cart.
## Walk: arrow keys / WASD, or the touch joystick (touch_vector).
## Slice 8 action HUD (TOUCH-FIRST — this is a mobile game):
## on-screen Sprint (hold) + Jump + Vehicle buttons in JoystickLayer
## do sprint / jump / enter-exit on a phone; Shift / J / Enter-Space
## are kept ONLY as desktop fallbacks, never the primary path.
## Talk to a villager (TOUCH-FIRST — this is a mobile game):
## walk within 3.5 m and the on-screen Talk button appears
## (TalkButton in JoystickLayer); tap it — or tap the villager
## directly — and the nearest villager's talk_to() faces the player
## and shows its greeting bubble. E is kept ONLY as an optional
## desktop-debug fallback, not the primary path (Slice 6 made E the
## primary path; that was a mobile-design miss, corrected in Slice 7).

@export var walk_speed: float = 5.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 5.0

var driving: bool = false
var driving_vehicle: Node = null
var touch_vector: Vector2 = Vector2.ZERO
var touch_sprint: bool = false
var jump_requested: bool = false
var e_was_pressed: bool = false
var talk_button: Button = null
var talk_button_connected: bool = false
var sprint_button: Button = null
var sprint_button_connected: bool = false
var jump_button: Button = null
var jump_button_connected: bool = false
var vehicle_button: Button = null
var vehicle_button_connected: bool = false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if driving:
		velocity = Vector3.ZERO
		move_and_slide()
		if talk_button != null:
			talk_button.visible = false
		# Driving: only the vehicle Exit button stays on screen.
		_update_action_buttons()
		return
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
		if Input.is_physical_key_pressed(KEY_J) or jump_requested:
			velocity.y = jump_velocity
		jump_requested = false
	var ix := Input.get_axis("ui_left", "ui_right")
	var iz := Input.get_axis("ui_up", "ui_down")
	if touch_vector != Vector2.ZERO:
		ix = touch_vector.x
		iz = touch_vector.y
	var dir := Vector3(ix, 0.0, iz).normalized()
	var speed := walk_speed
	if Input.is_physical_key_pressed(KEY_SHIFT) or touch_sprint:
		speed *= sprint_multiplier
	if dir != Vector3.ZERO:
		rotation.y = atan2(dir.x, dir.z)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	_update_talk_button()
	_update_action_buttons()
	if Input.is_action_just_pressed("ui_accept"):
		_try_enter_vehicle()
	# E is a desktop-debug fallback ONLY — the primary path is the
	# on-screen Talk button / tapping the villager (see header).
	var e_now := Input.is_physical_key_pressed(KEY_E)
	if e_now and not e_was_pressed:
		_try_talk()
	e_was_pressed = e_now

## Shows the Talk button only when a villager is in talk range.
## The button lives in the real scene (JoystickLayer/TalkButton),
## not in a script nobody instantiates; it is found lazily because
## the player enters the tree before the CanvasLayer does.
func _update_talk_button() -> void:
	if talk_button == null:
		talk_button = get_node_or_null("../JoystickLayer/TalkButton") as Button
		if talk_button != null and not talk_button_connected:
			talk_button.pressed.connect(_try_talk)
			talk_button_connected = true
	if talk_button != null:
		talk_button.visible = _nearest_villager() != null

## Slice 8: wires the on-screen Sprint / Jump / Vehicle buttons.
## They live in the real scene (JoystickLayer), found lazily like
## the Talk button, because the player enters the tree first.
## Sprint is hold-to-sprint (button_down/up); Jump sets a request
## consumed on the next ground frame; Vehicle enters the nearest
## vehicle within 4 m on foot, or exits the ridden one while driving.
func _update_action_buttons() -> void:
	if sprint_button == null:
		sprint_button = get_node_or_null("../JoystickLayer/SprintButton") as Button
		if sprint_button != null and not sprint_button_connected:
			sprint_button.button_down.connect(_on_sprint_down)
			sprint_button.button_up.connect(_on_sprint_up)
			sprint_button_connected = true
	if jump_button == null:
		jump_button = get_node_or_null("../JoystickLayer/JumpButton") as Button
		if jump_button != null and not jump_button_connected:
			jump_button.pressed.connect(_on_jump_pressed)
			jump_button_connected = true
	if vehicle_button == null:
		vehicle_button = get_node_or_null("../JoystickLayer/VehicleButton") as Button
		if vehicle_button != null and not vehicle_button_connected:
			vehicle_button.pressed.connect(_on_vehicle_button_pressed)
			vehicle_button_connected = true
	if driving:
		if sprint_button != null:
			sprint_button.visible = false
		if jump_button != null:
			jump_button.visible = false
		if vehicle_button != null:
			vehicle_button.visible = true
			vehicle_button.text = "ဆင်းမည်"
		return
	if sprint_button != null:
		sprint_button.visible = true
	if jump_button != null:
		jump_button.visible = true
	if vehicle_button != null:
		var near := _nearest_vehicle()
		vehicle_button.visible = near != null
		if near != null:
			vehicle_button.text = "စီးမည်"

func _on_sprint_down() -> void:
	touch_sprint = true

func _on_sprint_up() -> void:
	touch_sprint = false

func _on_jump_pressed() -> void:
	if not driving:
		jump_requested = true

func _on_vehicle_button_pressed() -> void:
	if driving:
		if driving_vehicle != null and driving_vehicle.has_method("exit_vehicle"):
			driving_vehicle.call("exit_vehicle")
		return
	_try_enter_vehicle()

func _nearest_vehicle() -> Node:
	var best: Node = null
	var best_dist: float = 4.0
	for name in ["Car", "Cart", "Motorcycle", "Airplane", "Cow"]:
		var v := get_node_or_null("../" + name)
		if v != null:
			var d := global_position.distance_to(v.global_position)
			if d < best_dist:
				best_dist = d
				best = v
	return best

func _nearest_villager() -> Node:
	var best: Node = null
	var best_dist: float = 3.5
	for villager in get_tree().get_nodes_in_group("villagers"):
		var d := global_position.distance_to(villager.global_position)
		if d < best_dist:
			best_dist = d
			best = villager
	return best

func _try_talk() -> void:
	var best := _nearest_villager()
	if best != null and best.has_method("talk_to"):
		best.call("talk_to", global_position)

func _try_enter_vehicle() -> void:
	# Nearest vehicle within 4 m wins (Slice 6 took the first name in
	# list order, which could pick a farther vehicle over a nearer one).
	var best: Node = null
	var best_dist: float = 4.0
	for name in ["Car", "Cart", "Motorcycle", "Airplane", "Cow"]:
		var v := get_node_or_null("../" + name)
		if v != null:
			var d := global_position.distance_to(v.global_position)
			if d < best_dist:
				best_dist = d
				best = v
	if best != null:
		driving = true
		driving_vehicle = best
		visible = false
		best.start_driving(self)

func leave_vehicle() -> void:
	driving = false
	driving_vehicle = null
	visible = true
