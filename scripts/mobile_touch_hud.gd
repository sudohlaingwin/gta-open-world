extends CanvasLayer

# --- AAA Mobile Gaming HUD (MiniMap, Health, Speedometer, Context Actions, Icons) ---

@onready var action_container: HBoxContainer = $ActionContainer
@onready var interact_btn: Button = $ActionContainer/InteractBtn
@onready var jump_btn: Button = $ActionContainer/JumpBtn
@onready var sprint_btn: Button = $ActionContainer/SprintBtn

@onready var minimap_panel: Panel = $TopLeftHUD/MiniMap
@onready var player_icon: TextureRect = $TopLeftHUD/MiniMap/PlayerIcon
@onready var compass_label: Label = $TopLeftHUD/CompassLabel

@onready var health_bar: ProgressBar = $TopLeftHUD/HealthBar
@onready var stamina_bar: ProgressBar = $TopLeftHUD/StaminaBar

@onready var speedometer_panel: Panel = $BottomCenterHUD/Speedometer
@onready var speed_label: Label = $BottomCenterHUD/Speedometer/SpeedLabel
@onready var vehicle_type_label: Label = $BottomCenterHUD/Speedometer/VehicleTypeLabel

@onready var virtual_joystick: Control = $VirtualJoystick
@onready var prompt_banner: Label = $PromptBanner

var player: CharacterBody3D = null

func _ready() -> void:
	layer = 15
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

func _process(delta: float) -> void:
	if not player:
		return

	# 1. MiniMap & Compass Heading Tracking
	if player_icon:
		player_icon.rotation = -player.visual_mesh.rotation.y
	if compass_label:
		var deg = wrapf(rad_to_deg(player.visual_mesh.rotation.y), 0, 360)
		compass_label.text = "%d° %s" % [deg, _get_cardinal_dir(deg)]

	# 2. Dynamic Speedometer (Shows when driving/riding/flying)
	if speedometer_panel and speed_label and vehicle_type_label:
		if player.current_state != player.State.ON_FOOT:
			speedometer_panel.visible = true
			var speed_kmh: float = 0.0
			var mode_text: String = ""
			
			if player.current_state == player.State.FLYING_AIRCRAFT and player.active_aircraft:
				speed_kmh = player.active_aircraft.velocity.length() * 3.6
				mode_text = "✈️ လေယာဉ် (AIRPLANE)"
			elif player.current_state == player.State.RIDING_MOUNT and player.active_mount:
				speed_kmh = player.active_mount.velocity.length() * 3.6
				mode_text = "🐂 လှည်း/နွား (MOUNT)"
			elif player.current_state == player.State.DRIVING_VEHICLE and player.active_vehicle:
				speed_kmh = player.active_vehicle.linear_velocity.length() * 3.6
				mode_text = "🚗 ကား/ဆိုင်ကယ် (VEHICLE)"
				
			speed_label.text = "%d KM/H" % int(speed_kmh)
			vehicle_type_label.text = mode_text
		else:
			speedometer_panel.visible = false

	# 3. Dynamic Contextual Action Buttons with Icons
	if interact_btn:
		match player.current_state:
			player.State.RIDING_MOUNT:
				interact_btn.text = "🚪 ဆင်းမည် (Dismount)"
			player.State.DRIVING_VEHICLE:
				interact_btn.text = "🚪 ဆင်းမည် (Exit Car)"
			player.State.FLYING_AIRCRAFT:
				interact_btn.text = "🚪 ဆင်းမည် (Exit Plane)"
			player.State.ON_FOOT:
				if player.nearby_mount:
					interact_btn.text = "🐂 စီးမည် (Ride Cow/Cart)"
				elif player.nearby_aircraft:
					interact_btn.text = "✈️ မောင်းမည် (Fly Airplane)"
				elif player.nearby_vehicle:
					interact_btn.text = "🚗 မောင်းမည် (Drive Vehicle)"
				else:
					var villager = player._get_nearest_villager(4.0)
					if villager:
						interact_btn.text = "💬 စကားပြော (Talk)"
					else:
						interact_btn.text = "⚡ လုပ်ဆောင် (Action)"

func _get_cardinal_dir(deg: float) -> String:
	if deg >= 337.5 or deg < 22.5: return "N"
	elif deg >= 22.5 and deg < 67.5: return "NE"
	elif deg >= 67.5 and deg < 112.5: return "E"
	elif deg >= 112.5 and deg < 157.5: return "SE"
	elif deg >= 157.5 and deg < 202.5: return "S"
	elif deg >= 202.5 and deg < 247.5: return "SW"
	elif deg >= 247.5 and deg < 292.5: return "W"
	else: return "NW"

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
