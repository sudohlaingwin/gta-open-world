extends CanvasLayer

# --- Mobile Touch HUD & Multi-Vehicle Speedometer System ---

@onready var virtual_joystick: Control = $VirtualJoystick
@onready var interact_btn: Button = $ActionContainer/InteractBtn
@onready var jump_btn: Button = $ActionContainer/JumpBtn
@onready var chute_btn: Button = $ActionContainer/ChuteBtn
@onready var sprint_btn: Button = $ActionContainer/SprintBtn
@onready var view_btn: Button = $ActionContainer.get_node_or_null("ViewBtn")
@onready var radio_btn: Button = $ActionContainer.get_node_or_null("RadioBtn")
@onready var horn_btn: Button = $ActionContainer.get_node_or_null("HornBtn")
@onready var headlight_btn: Button = .get_node_or_null("HeadlightBtn")
@onready var window_btn: Button = .get_node_or_null("WindowBtn")
@onready var hazard_btn: Button = .get_node_or_null("HazardBtn")
@onready var mirror_btn: Button = .get_node_or_null("MirrorBtn")
@onready var ac_btn: Button = .get_node_or_null("ACBtn")
@onready var quest_banner: Label = $TopCenterHUD/QuestBanner
@onready var player_icon: ColorRect = $TopLeftHUD/MiniMap/PlayerIcon
@onready var pagoda_icon: ColorRect = $TopLeftHUD/MiniMap/PagodaIcon
@onready var compass_label: Label = $TopLeftHUD/CompassLabel
@onready var stamina_bar: ProgressBar = $TopLeftHUD/StaminaBar
@onready var fps_label: Label = $TopLeftHUD/FpsLabel
@onready var flight_controls: Control = $FlightControls
@onready var yaw_left_btn: Button = $FlightControls/YawLeftBtn
@onready var yaw_right_btn: Button = $FlightControls/YawRightBtn
@onready var speedometer_panel: Panel = $BottomCenterHUD/Speedometer
@onready var speed_label: Label = $BottomCenterHUD/Speedometer/SpeedLabel
@onready var vehicle_type_label: Label = $BottomCenterHUD/Speedometer/VehicleTypeLabel
@onready var throttle_bar: ProgressBar = $BottomCenterHUD/Speedometer/ThrottleBar
@onready var pause_btn: Button = $TopLeftHUD/PauseBtn
@onready var map_btn: Button = $TopLeftHUD/MapBtn
@onready var pause_menu: Control = $PauseMenu
@onready var resume_btn: Button = $PauseMenu/PauseBox/ResumeBtn
@onready var save_btn: Button = $PauseMenu/PauseBox/SaveBtn
@onready var unstuck_btn: Button = $PauseMenu/PauseBox/UnstuckBtn
@onready var settings_btn: Button = $PauseMenu/PauseBox/SettingsBtn
@onready var quit_to_menu_btn: Button = $PauseMenu/PauseBox/QuitToMenuBtn
@onready var full_map_overlay: Control = $FullMapOverlay
@onready var settings_panel: Control = $SettingsPanel
@onready var prompt_banner: Label = $PromptBanner
@onready var waypoint_guide: Panel = $TopCenterHUD/WaypointGuide
@onready var guide_arrow: Label = $TopCenterHUD/WaypointGuide/ArrowLabel
@onready var guide_dist: Label = $TopCenterHUD/WaypointGuide/DistanceLabel

var player: CharacterBody3D = null
var beacon_node: Node3D = null
var quest_stage: int = 1
var villagers_talked_count: int = 0
var pagoda_node: Node3D = null
var bell_node: Node3D = null
var teashop_node: Node3D = null
var prompt_hold_timer: float = 0.0

func _ready() -> void:
	layer = 15
	add_to_group("hud")
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
	if chute_btn:
		chute_btn.pressed.connect(_on_chute_pressed)
	if sprint_btn:
		sprint_btn.button_down.connect(_on_sprint_down)
		sprint_btn.button_up.connect(_on_sprint_up)
	if view_btn:
		view_btn.pressed.connect(_on_view_pressed)
	if radio_btn:
		radio_btn.pressed.connect(_on_radio_pressed)
	if horn_btn:
		horn_btn.pressed.connect(_on_horn_pressed)
	if headlight_btn:
		headlight_btn.pressed.connect(_on_headlight_pressed)
	if window_btn:
		window_btn.pressed.connect(_on_window_pressed)
	if hazard_btn:
		hazard_btn.pressed.connect(_on_hazard_pressed)
	if mirror_btn:
		mirror_btn.pressed.connect(_on_mirror_pressed)
	if ac_btn:
		ac_btn.pressed.connect(_on_ac_pressed)
		
	if yaw_left_btn:
		yaw_left_btn.button_down.connect(func(): if player: player.touch_yaw = -1.0)
		yaw_left_btn.button_up.connect(func(): if player: player.touch_yaw = 0.0)
	if yaw_right_btn:
		yaw_right_btn.button_down.connect(func(): if player: player.touch_yaw = 1.0)
		yaw_right_btn.button_up.connect(func(): if player: player.touch_yaw = 0.0)

	if pause_btn:
		pause_btn.pressed.connect(_on_pause_pressed)
	if map_btn:
		map_btn.pressed.connect(_on_map_pressed)
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
	if unstuck_btn:
		unstuck_btn.pressed.connect(_on_unstuck_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_to_menu_btn:
		quit_to_menu_btn.pressed.connect(_on_quit_to_menu_pressed)

	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		if sm.get("hud_scale") != null:
			apply_hud_scale(sm.hud_scale)
		if sm.get("show_fps") != null and fps_label:
			fps_label.visible = bool(sm.show_fps)

	_update_quest_text()

func _process(delta: float) -> void:
	if not player:
		return

	# 1. MiniMap Tracking
	if player_icon and player.visual_mesh:
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
	if compass_label and player.visual_mesh:
		var deg = wrapf(rad_to_deg(player.visual_mesh.rotation.y), 0, 360)
		compass_label.text = "%d° %s" % [deg, _get_cardinal_dir(deg)]

	# 2b. Waypoint Guidance HUD (Camera-relative Arrow + Distance)
	if not beacon_node:
		beacon_node = get_tree().get_first_node_in_group("waypoint_beacon")
	if waypoint_guide and beacon_node:
		if beacon_node.visible:
			waypoint_guide.visible = true
			var ref_pos = player.global_position
			if player.current_state != player.State.ON_FOOT:
				if player.active_vehicle: ref_pos = player.active_vehicle.global_position
				elif player.active_mount: ref_pos = player.active_mount.global_position
				elif player.active_aircraft: ref_pos = player.active_aircraft.global_position
			var dist = ref_pos.distance_to(beacon_node.global_position)
			if dist <= 5.0:
				if guide_arrow: guide_arrow.visible = false
				if guide_dist: guide_dist.text = "✓ ရောက်ရှိပါပြီ (Arrived)"
			else:
				if guide_arrow:
					guide_arrow.visible = true
					var cam = get_viewport().get_camera_3d()
					var forward = -cam.global_transform.basis.z if cam else Vector3.FORWARD
					forward.y = 0.0
					forward = forward.normalized()
					var to_target = (beacon_node.global_position - ref_pos)
					to_target.y = 0.0
					to_target = to_target.normalized()
					var angle = forward.signed_angle_to(to_target, Vector3.UP)
					guide_arrow.text = _get_relative_arrow(angle)
				if guide_dist:
					guide_dist.text = "📍 လမ်းညွှန်: %dm" % int(dist)
		else:
			waypoint_guide.visible = false

	# 3. Dynamic Stamina & Health
	if stamina_bar:
		if player.is_sprinting and player.current_state == player.State.ON_FOOT and player.velocity.length() > 0.5:
			player.stamina = max(0.0, player.stamina - 24.0 * delta)
			if player.stamina <= 0.0:
				player.set_sprint(false)
		else:
			player.stamina = min(100.0, player.stamina + 16.0 * delta)
		stamina_bar.value = player.stamina

	var health_bar = $TopLeftHUD.get_node_or_null("HealthBar")
	if health_bar and player.get("health") != null:
		health_bar.value = player.health

	if fps_label and fps_label.visible:
		var fps = Engine.get_frames_per_second()
		fps_label.text = "%d FPS" % fps
		if fps >= 50:
			fps_label.set("theme_override_colors/font_color", Color(0.2, 0.9, 0.3, 1))
		elif fps >= 30:
			fps_label.set("theme_override_colors/font_color", Color(1.0, 0.84, 0.0, 1))
		else:
			fps_label.set("theme_override_colors/font_color", Color(0.9, 0.25, 0.25, 1))

	# 4. Parachute Button Visibility
	if chute_btn:
		chute_btn.visible = (player.current_state == player.State.ON_FOOT and not player.is_on_floor())

	# 5. Quest Progression
	if quest_stage == 2 and pagoda_node:
		if player.global_position.distance_to(pagoda_node.global_position) < 14.0:
			quest_stage = 3
			_update_quest_text()
	elif quest_stage == 3 and bell_node:
		if player.global_position.distance_to(bell_node.global_position) < 8.0:
			quest_stage = 4
			_update_quest_text()
	elif quest_stage == 4 and teashop_node:
		if player.global_position.distance_to(teashop_node.global_position) < 10.0:
			quest_stage = 5
			_update_quest_text()
	elif quest_stage == 5:
		if player.current_state != player.State.ON_FOOT:
			quest_stage = 6
			_update_quest_text()

	# 6. Speedometer & Flight Controls Toggle
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
				mode_text = "🐂 လှည်း/နွား/ဆင်/မြင်း (MOUNT)"
				if throttle_bar: throttle_bar.visible = false
			elif player.current_state == player.State.DRIVING_VEHICLE and player.active_vehicle:
				if player.active_vehicle is VehicleBody3D:
					speed_kmh = player.active_vehicle.linear_velocity.length() * 3.6
					mode_text = "🚗 ကား (VILLAGE CAR)"
				else:
					speed_kmh = player.active_vehicle.velocity.length() * 3.6
					mode_text = "🏍️ ဆိုင်ကယ်/သုံးဘီး/သမ္ဗာန် (VEHICLE)"
				if throttle_bar: throttle_bar.visible = false
				
			speed_label.text = "%d KM/H" % int(speed_kmh)
			vehicle_type_label.text = mode_text
		else:
			speedometer_panel.visible = false

	# 7. Action Button Context & Vehicle Horn Visibility
	if horn_btn:
		horn_btn.visible = (player.current_state != player.State.ON_FOOT)
	if headlight_btn:
		headlight_btn.visible = (player.current_state == player.State.DRIVING_VEHICLE)
	if window_btn:
		window_btn.visible = (player.current_state == player.State.DRIVING_VEHICLE)
	if hazard_btn:
		hazard_btn.visible = (player.current_state == player.State.DRIVING_VEHICLE)
	if mirror_btn:
		mirror_btn.visible = (player.current_state == player.State.DRIVING_VEHICLE)
	if ac_btn:
		ac_btn.visible = (player.current_state == player.State.DRIVING_VEHICLE)

	if sprint_btn:
		if player.current_state != player.State.ON_FOOT:
			sprint_btn.text = "🚀 အရှိန်တင် (BOOST)"
		else:
			sprint_btn.text = "🏃 အပြေး (SPRINT)"


	var prompt_text: String = ""
	var should_show_prompt: bool = false

	if interact_btn:
		match player.current_state:
			player.State.RIDING_MOUNT:
				interact_btn.text = "🚪 ဆင်းမည် (Dismount)"
				prompt_text = "စီးနင်းထားသော တိရစ္ဆာန်/လှည်း ပေါ်မှ ဆင်းရန် နှိပ်ပါ"
				should_show_prompt = true
			player.State.DRIVING_VEHICLE:
				interact_btn.text = "🚪 ဆင်းမည် (Exit Vehicle)"
				prompt_text = "ယာဉ်ပေါ်မှ ဆင်းရန် နှိပ်ပါ"
				should_show_prompt = true
			player.State.FLYING_AIRCRAFT:
				interact_btn.text = "🚪 ဆင်းမည် (Exit Plane)"
				prompt_text = "လေယာဉ်မှ ဆင်းရန် နှိပ်ပါ"
				should_show_prompt = true
			player.State.ON_FOOT:
				if player.nearby_mount:
					interact_btn.text = "🐂 စီးမည် (Ride Mount)"
					prompt_text = "နွား/လှည်း/ဆင်/မြင်း တက်စီးရန် နှိပ်ပါ"
					should_show_prompt = true
				elif player.nearby_aircraft:
					interact_btn.text = "✈️ မောင်းမည် (Fly Aircraft)"
					prompt_text = "လေယာဉ်/ရဟတ်ယာဉ် တက်မောင်းရန် နှိပ်ပါ"
					should_show_prompt = true
				elif player.nearby_vehicle:
					interact_btn.text = "🚗 မောင်းမည် (Drive Vehicle)"
					prompt_text = "ကား/ဆိုင်ကယ်/သုံးဘီး/သမ္ဗာန် မောင်းရန် နှိပ်ပါ"
					should_show_prompt = true
				else:
					var villager = player._get_nearest_villager(4.0)
					if villager:
						interact_btn.text = "💬 စကားပြော (Talk)"
						prompt_text = "%s နှင့် စကားပြောရန် နှိပ်ပါ" % villager.villager_name
						should_show_prompt = true
					else:
						interact_btn.text = "⚡ လုပ်ဆောင် (Action)"
						should_show_prompt = false

	if prompt_hold_timer > 0.0:
		prompt_hold_timer -= delta
	else:
		if should_show_prompt:
			_show_prompt(prompt_text)
		else:
			_hide_prompt()

func record_villager_talk() -> void:
	villagers_talked_count += 1
	if quest_stage == 1:
		if villagers_talked_count >= 3:
			quest_stage = 2
			_update_quest_text()

func _update_quest_text() -> void:
	if quest_banner:
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

	var audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_bell_strike"):
		audio_mgr.play_bell_strike()

func show_temporary_prompt(text: String, duration: float = 3.5) -> void:
	prompt_hold_timer = duration
	_show_prompt(text)

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

func _get_relative_arrow(rad: float) -> String:
	var deg = rad_to_deg(rad)
	if deg > -22.5 and deg <= 22.5: return "↑"
	elif deg > 22.5 and deg <= 67.5: return "↖"
	elif deg > 67.5 and deg <= 112.5: return "←"
	elif deg > 112.5 and deg <= 157.5: return "↙"
	elif deg > -67.5 and deg <= -22.5: return "↗"
	elif deg > -112.5 and deg <= -67.5: return "→"
	elif deg > -157.5 and deg <= -112.5: return "↘"
	else: return "↓"

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

func _on_chute_pressed() -> void:
	if player and player.has_method("toggle_parachute"):
		player.toggle_parachute()

func _on_sprint_down() -> void:
	if player and player.stamina > 5.0:
		player.set_sprint(true)

func _on_sprint_up() -> void:
	if player:
		player.set_sprint(false)

func _on_view_pressed() -> void:
	if player and player.get_node_or_null("CameraPivot"):
		var cam_pivot = player.get_node("CameraPivot")
		if cam_pivot.has_method("cycle_view_mode"):
			var mode_name = cam_pivot.cycle_view_mode()
			show_temporary_prompt("ရှုထောင့်: %s" % mode_name, 2.5)

func _on_radio_pressed() -> void:
	var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
	if not audio_mgr:
		audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("cycle_radio_station"):
		var st_name = audio_mgr.cycle_radio_station()
		show_temporary_prompt(st_name, 3.5)

func _on_horn_pressed() -> void:
	var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
	if not audio_mgr:
		audio_mgr = get_parent().get_node_or_null("MyanmarAudioManager")
	if audio_mgr and audio_mgr.has_method("play_horn"):
		audio_mgr.play_horn()

func _on_mirror_pressed() -> void:
	if player and player.current_state == player.State.DRIVING_VEHICLE and player.active_vehicle:
		if player.active_vehicle.has_method("toggle_rearview_mirror"):
			var mode_name = player.active_vehicle.toggle_rearview_mirror()
			show_temporary_prompt(mode_name, 3.0)

func _on_ac_pressed() -> void:
	if player and player.current_state == player.State.DRIVING_VEHICLE and player.active_vehicle:
		if player.active_vehicle.has_method("toggle_ac"):
			var mode_name = player.active_vehicle.toggle_ac()
			show_temporary_prompt(mode_name, 3.0)

func _on_hazard_pressed() -> void:
	if player and player.current_state == player.State.DRIVING_VEHICLE and player.active_vehicle:
		if player.active_vehicle.has_method("toggle_hazard_lights"):
			var mode_name = player.active_vehicle.toggle_hazard_lights()
			show_temporary_prompt(mode_name, 3.0)

func _on_window_pressed() -> void:
	if player and player.current_state == player.State.DRIVING_VEHICLE and player.active_vehicle:
		if player.active_vehicle.has_method("toggle_windows"):
			var mode_name = player.active_vehicle.toggle_windows()
			show_temporary_prompt(mode_name, 3.0)

func _on_headlight_pressed() -> void:
	if player and player.current_state == player.State.DRIVING_VEHICLE and player.active_vehicle:
		if player.active_vehicle.has_method("cycle_headlight_mode"):
			var mode_name = player.active_vehicle.cycle_headlight_mode()
			show_temporary_prompt(mode_name, 3.0)
	_show_prompt("📢 ဟွန်းတီးခြင်း (HONK!)")

func _on_pause_pressed() -> void:
	if pause_menu:
		pause_menu.visible = true
		get_tree().paused = true

func _on_map_pressed() -> void:
	if full_map_overlay:
		full_map_overlay.visible = !full_map_overlay.visible

func _on_resume_pressed() -> void:
	if pause_menu:
		pause_menu.visible = false
		get_tree().paused = false

func _on_save_pressed() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and player:
		var success = save_mgr.save_game(player.global_position, quest_stage, villagers_talked_count, player.stamina)
		if success:
			_show_prompt("ဂိမ်းအခြေအနေကို အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ! ✓")
		else:
			_show_prompt("ဂိမ်းသိမ်းဆည်းမှု မအောင်မြင်ပါ!")

func _on_unstuck_pressed() -> void:
	if player and player.has_method("recover_from_stuck"):
		player.recover_from_stuck()
		if pause_menu:
			pause_menu.visible = false
			get_tree().paused = false
		_show_prompt("နေရာလွတ်သို့ အောင်မြင်စွာ ပြန်ရောက်ပါပြီ! ✓")

func _on_settings_pressed() -> void:
	if settings_panel:
		settings_panel.visible = true
		if settings_panel.has_method("refresh"):
			settings_panel.refresh()

func apply_hud_scale(scale_val: float) -> void:
	var s = clampf(scale_val, 0.8, 1.25)
	var scaled_nodes = [
		$VirtualJoystick,
		$ActionContainer,
		$TopLeftHUD,
		$FlightControls
	]
	for n in scaled_nodes:
		if n:
			n.scale = Vector2(s, s)

func set_fps_visible(p_visible: bool) -> void:
	if fps_label:
		fps_label.visible = p_visible

func _on_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
