extends CanvasLayer

# --- High-Fidelity Mobile Touch Gaming HUD & Flight Deck ---

@onready var minimap: Panel = $TopLeftHUD/MiniMap
@onready var player_icon: ColorRect = $TopLeftHUD/MiniMap/PlayerIcon
@onready var pagoda_icon: ColorRect = $TopLeftHUD/MiniMap/PagodaIcon
@onready var compass_label: Label = $TopLeftHUD/CompassLabel
@onready var stamina_bar: ProgressBar = $TopLeftHUD/StaminaBar
@onready var quest_banner: Label = $TopCenterHUD/QuestBanner
@onready var flight_controls: Control = $FlightControls
@onready var yaw_left_btn: Button = $FlightControls/YawLeftBtn
@onready var yaw_right_btn: Button = $FlightControls/YawRightBtn
@onready var virtual_joystick: Control = $VirtualJoystick
@onready var sprint_btn: Button = $ActionContainer/SprintBtn
@onready var jump_btn: Button = $ActionContainer/JumpBtn
@onready var interact_btn: Button = $ActionContainer/InteractBtn
@onready var speedometer_panel: Panel = $BottomCenterHUD/Speedometer
@onready var speed_label: Label = $BottomCenterHUD/Speedometer/SpeedLabel
@onready var vehicle_type_label: Label = $BottomCenterHUD/Speedometer/VehicleTypeLabel
@onready var throttle_bar: ProgressBar = $BottomCenterHUD/Speedometer/ThrottleBar
@onready var prompt_banner: Label = $PromptBanner

var player: CharacterBody3D = null
var quest_stage: int = 1 # 1: Talk, 2: Visit Pagoda, 3: Ring Bell, 4: Tea Shop, 5: Ride Mount/Car/Bike/Plane, 6: Complete
var villagers_talked_count: int = 0
var pagoda_node: Node3D = null
var bell_node: Node3D = null
var teashop_node: Node3D = null

func _ready() -> void:
	layer = 15
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	pagoda_node = get_parent().get_node_or_null("GoldenPagoda")
	bell_node = get_parent().get_node_or_null("MonasteryBell")
	teashop_node = get_parent().get_node_or_null("MyanmarTeaShop")
	
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
		
	if yaw_left_btn:
		yaw_left_btn.button_down.connect(func(): if player: player.touch_yaw = -1.0)
		yaw_left_btn.button_up.connect(func(): if player: player.touch_yaw = 0.0)
	if yaw_right_btn:
		yaw_right_btn.button_down.connect(func(): if player: player.touch_yaw = 1.0)
		yaw_right_btn.button_up.connect(func(): if player: player.touch_yaw = 0.0)

	_update_quest_text()
	var audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_bell_strike"):
		audio_mgr.play_bell_strike()

func _process(delta: float) -> void:
	if not player:
		return

	# 1. MiniMap Tracking (Player + Pagoda)
	if player_icon:
		player_icon.rotation = -player.visual_mesh.rotation.y
		
	if pagoda_icon and pagoda_node:
		var rel_pos = (pagoda_node.global_position - player.global_position)
		var map_size = 140.0
		var map_radius = map_size * 0.45
		var scale_factor = 0.8
		var icon_x = clamp(rel_pos.x * scale_factor, -map_radius, map_radius)
		var icon_z = clamp(rel_pos.z * scale_factor, -map_radius, map_radius)
		pagoda_icon.position = Vector2(map_size / 2.0 + icon_x - 4, map_size / 2.0 + icon_z - 4)

	# 2. Compass Label
	if compass_label:
		var deg = wrapf(rad_to_deg(player.visual_mesh.rotation.y), 0, 360)
		compass_label.text = "%d° %s" % [deg, _get_cardinal_dir(deg)]

	# 3. Dynamic Real Stamina Drain & Regeneration
	if stamina_bar:
		if player.is_sprinting and player.current_state == player.State.ON_FOOT and player.velocity.length() > 0.5:
			player.stamina = max(0.0, player.stamina - 24.0 * delta)
			if player.stamina <= 0.0:
				player.set_sprint(false)
		else:
			player.stamina = min(100.0, player.stamina + 16.0 * delta)
		stamina_bar.value = player.stamina

	# 4. Quest Progression Checking
	if quest_stage == 2 and pagoda_node:
		if player.global_position.distance_to(pagoda_node.global_position) < 14.0:
			quest_stage = 3
			_update_quest_text()
	var audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_bell_strike"):
		audio_mgr.play_bell_strike()
	elif quest_stage == 3 and bell_node:
		if player.global_position.distance_to(bell_node.global_position) < 8.0:
			quest_stage = 4
			_update_quest_text()
	var audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_bell_strike"):
		audio_mgr.play_bell_strike()
	elif quest_stage == 4 and teashop_node:
		if player.global_position.distance_to(teashop_node.global_position) < 10.0:
			quest_stage = 5
			_update_quest_text()
	var audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_bell_strike"):
		audio_mgr.play_bell_strike()
	elif quest_stage == 5:
		if player.current_state != player.State.ON_FOOT:
			quest_stage = 6
			_update_quest_text()
	var audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_bell_strike"):
		audio_mgr.play_bell_strike()

	# 5. Speedometer & Flight Controls Toggle
	if player.current_state == player.State.FLYING_AIRCRAFT:
		if flight_controls: flight_controls.visible = true
	else:
		if flight_controls: flight_controls.visible = false

	if speedometer_panel and speed_label and vehicle_type_label:
		if player.current_state != player.State.ON_FOOT:
			speedometer_panel.visible = true
			var speed_kmh: float = 0.0
			var mode_text: String = ""
			
			if player.current_state == player.State.FLYING_AIRCRAFT and player.active_aircraft:
				speed_kmh = player.active_aircraft.velocity.length() * 3.6
				mode_text = "✈️ လေယာဉ် (AIRPLANE)"
				if throttle_bar:
					throttle_bar.visible = true
					throttle_bar.value = player.active_aircraft.throttle * 100.0
			elif player.current_state == player.State.RIDING_MOUNT and player.active_mount:
				speed_kmh = player.active_mount.velocity.length() * 3.6
				mode_text = "🐂 လှည်း/နွား (MOUNT)"
				if throttle_bar: throttle_bar.visible = false
			elif player.current_state == player.State.DRIVING_VEHICLE and player.active_vehicle:
				if player.active_vehicle is VehicleBody3D:
					speed_kmh = player.active_vehicle.linear_velocity.length() * 3.6
					mode_text = "🚗 ကား (VILLAGE CAR)"
				else:
					speed_kmh = player.active_vehicle.velocity.length() * 3.6
					mode_text = "🏍️ ဆိုင်ကယ် (MOTORCYCLE)"
				if throttle_bar: throttle_bar.visible = false
				
			speed_label.text = "%d KM/H" % int(speed_kmh)
			vehicle_type_label.text = mode_text
		else:
			speedometer_panel.visible = false

	# 6. Contextual Action Label & Prompt Banner
	if interact_btn:
		match player.current_state:
			player.State.RIDING_MOUNT:
				interact_btn.text = "🚪 ဆင်းမည် (Dismount)"
				_show_prompt("နွားလှည်းပေါ်မှ ဆင်းရန် နှိပ်ပါ")
			player.State.DRIVING_VEHICLE:
				interact_btn.text = "🚪 ဆင်းမည် (Exit Vehicle)"
				_show_prompt("ယာဉ်ပေါ်မှ ဆင်းရန် နှိပ်ပါ")
			player.State.FLYING_AIRCRAFT:
				interact_btn.text = "🚪 ဆင်းမည် (Exit Plane)"
				_show_prompt("လေယာဉ်မှ ဆင်းရန် နှိပ်ပါ")
			player.State.ON_FOOT:
				if player.nearby_mount:
					interact_btn.text = "🐂 စီးမည် (Ride Mount)"
					_show_prompt("နွား သို့မဟုတ် လှည်းစီးရန် နှိပ်ပါ")
				elif player.nearby_aircraft:
					interact_btn.text = "✈️ မောင်းမည် (Fly Airplane)"
					_show_prompt("လေယာဉ်တက်မောင်းရန် နှိပ်ပါ")
				elif player.nearby_vehicle:
					interact_btn.text = "🚗 မောင်းမည် (Drive Vehicle)"
					_show_prompt("ကား သို့မဟုတ် ဆိုင်ကယ်မောင်းရန် နှိပ်ပါ")
				else:
					var villager = player._get_nearest_villager(4.0)
					if villager:
						interact_btn.text = "💬 စကားပြော (Talk)"
						_show_prompt("%s နှင့် စကားပြောရန် နှိပ်ပါ" % villager.villager_name)
					else:
						interact_btn.text = "⚡ လုပ်ဆောင် (Action)"
						_hide_prompt()

func record_villager_talk() -> void:
	villagers_talked_count += 1
	if quest_stage == 1:
		if villagers_talked_count >= 3:
			quest_stage = 2
		_update_quest_text()
	var audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_bell_strike"):
		audio_mgr.play_bell_strike()

func _update_quest_text()
	var audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_bell_strike"):
		audio_mgr.play_bell_strike() -> void:
	if not quest_banner:
		return
	match quest_stage:
		1:
			quest_banner.text = "📜 တာဝန် ၁: ရွာသူရွာသားများနှင့် စကားပြောပါ (%d/3)" % min(3, villagers_talked_count)
		2:
			quest_banner.text = "📜 တာဝန် ၂: ရွာဦးရွှေစေတီတော်သို့ သွားရောက်ဖူးမြော်ပါ 🏛️"
		3:
			quest_banner.text = "📜 တာဝန် ၃: ကျောင်းတိုက်ခေါင်းလောင်းတော်သို့ သွားပါ 🔔"
		4:
			quest_banner.text = "📜 တာဝန် ၄: ရွာလယ်လက်ဖက်ရည်ဆိုင်သို့ သွားရောက်အပန်းဖြေပါ ☕"
		5:
			quest_banner.text = "📜 တာဝန် ၅: လှည်း/နွား/ကား/ဆိုင်ကယ်/လေယာဉ် တစ်မျိုးမျိုးကို မောင်းနှင်ပါ 🐂🚗✈️"
		6:
			quest_banner.text = "🎉 တာဝန်အားလုံး အောင်မြင်စွာပြီးမြောက်ပါပြီ! ရွာကို လွတ်လပ်စွာ လှည့်လည်နိုင်ပါပြီ ✨"

func _show_prompt(text: String) -> void:
	if prompt_banner:
		prompt_banner.text = text
		prompt_banner.visible = true

func _hide_prompt() -> void:
	if prompt_banner:
		prompt_banner.visible = false

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
	if player and player.stamina > 5.0:
		player.set_sprint(true)

func _on_sprint_up() -> void:
	if player:
		player.set_sprint(false)
