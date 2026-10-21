extends CanvasLayer

# --- Live Shipped Mobile Touch HUD & On-Screen Action Controls ---

@onready var action_bar: HBoxContainer = $ActionContainer
@onready var interact_btn: Button = $ActionContainer/InteractBtn
@onready var jump_btn: Button = $ActionContainer/JumpBtn
@onready var sprint_btn: Button = $ActionContainer/SprintBtn
@onready var virtual_joystick: Control = $VirtualJoystick
@onready var prompt_banner: Label = $PromptBanner

var player: CharacterBody3D = null

func _ready() -> void:
	layer = 10 # Display above 3D world
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	
	if virtual_joystick and virtual_joystick.has_signal("joystick_moved"):
		virtual_joystick.joystick_moved.connect(_on_joystick_moved)
		virtual_joystick.joystick_released.connect(_on_joystick_released)

	if interact_btn:
		interact_btn.pressed.connect(_on_interact_pressed)
	if jump_btn:
		jump_btn.pressed.connect(_on_jump_pressed)
	if sprint_btn:
		sprint_btn.button_down.connect(_on_sprint_down)
		sprint_btn.button_up.connect(_on_sprint_up)

func _process(_delta: float) -> void:
	if not player:
		return
	# Dynamic action button label based on player interaction context
	if interact_btn:
		match player.current_state:
			player.State.RIDING_MOUNT:
				interact_btn.text = "ဆင်းမည် (Dismount)"
			player.State.DRIVING_VEHICLE:
				interact_btn.text = "ဆင်းမည် (Exit Car)"
			player.State.FLYING_AIRCRAFT:
				interact_btn.text = "ဆင်းမည် (Exit Plane)"
			player.State.ON_FOOT:
				if player.nearby_mount:
					interact_btn.text = "စီးမည် (Ride Mount)"
				elif player.nearby_aircraft:
					interact_btn.text = "မောင်းမည် (Fly Plane)"
				elif player.nearby_vehicle:
					interact_btn.text = "မောင်းမည် (Drive)"
				else:
					var villager = player._get_nearest_villager(4.0)
					if villager:
						interact_btn.text = "စကားပြော (Talk)"
					else:
						interact_btn.text = "လုပ်ဆောင် (Action)"

func _on_joystick_moved(vec: Vector2) -> void:
	if player:
		player.touch_input_vector = vec

func _on_joystick_released() -> void:
	if player:
		player.touch_input_vector = Vector2.ZERO

func _on_interact_pressed() -> void:
	if player:
		player.interact()

func _on_jump_pressed() -> void:
	if player:
		player.jump()

func _on_sprint_down() -> void:
	if player:
		player.set_sprint(true)

func _on_sprint_up() -> void:
	if player:
		player.set_sprint(false)
