extends Node3D

# --- Mobile Touch Controls Bridge & HUD Overlay ---

@onready var interact_btn: Button = $ActionButtons/InteractBtn
@onready var jump_btn: Button = $ActionButtons/JumpBtn
@onready var sprint_btn: Button = $ActionButtons/SprintBtn
@onready var touch_joystick: Control = $VirtualJoystick
@onready var prompt_label: Label = $PromptLabel

var player: Node3D = null

func _ready() -> void:
	# Automatically wire to player in parent scene
	player = get_parent().get_node_or_null("Player")
	if player:
		_wire_controls()

func _wire_controls() -> void:
	if touch_joystick and touch_joystick.has_signal("joystick_moved"):
		touch_joystick.joystick_moved.connect(_on_joystick_moved)
		touch_joystick.joystick_released.connect(_on_joystick_released)

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

func show_prompt(text: String) -> void:
	if prompt_label:
		prompt_label.text = text
		prompt_label.visible = true

func hide_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false
