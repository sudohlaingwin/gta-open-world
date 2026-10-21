extends Control

# Mobile Touch UI for Actions (Ride / Drive / Jump / Sprint)
@onready var interact_btn: Button = $InteractBtn
@onready var jump_btn: Button = $JumpBtn
@onready var sprint_btn: Button = $SprintBtn
@onready var virtual_joystick: Control = $VirtualJoystick

var player: Node3D = null

func setup(target_player: Node3D) -> void:
	player = target_player
	if virtual_joystick:
		virtual_joystick.joystick_moved.connect(_on_joystick_moved)
		virtual_joystick.joystick_released.connect(_on_joystick_released)
	
	if interact_btn:
		interact_btn.pressed.connect(_on_interact_pressed)
	if jump_btn:
		jump_btn.pressed.connect(_on_jump_pressed)
	if sprint_btn:
		sprint_btn.button_down.connect(func(): if player: player.set_sprint(true))
		sprint_btn.button_up.connect(func(): if player: player.set_sprint(false))

func _on_joystick_moved(vec: Vector2) -> void:
	if player:
		player.touch_input_vector = vec

func _on_joystick_released() -> void:
	if player:
		player.touch_input_vector = Vector2.ZERO

func _on_interact_pressed() -> void:
	if player and player.has_method("interact"):
		player.interact()

func _on_jump_pressed() -> void:
	if player and player.has_method("jump"):
		player.jump()
