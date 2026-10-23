extends Control

# --- Mobile Settings System (Genuinely Wired & Persistent) ---

@onready var close_btn: Button = $Panel/CloseBtn
@onready var mode_option: OptionButton = $Panel/ScrollBox/ModeOption
@onready var lang_option: OptionButton = $Panel/ScrollBox/LangOption
@onready var graphics_option: OptionButton = $Panel/ScrollBox/GraphicsOption
@onready var mute_check: CheckButton = $Panel/ScrollBox/MuteCheck
@onready var vibrate_check: CheckButton = $Panel/ScrollBox/VibrateCheck
@onready var fps_check: CheckButton = $Panel/ScrollBox/FpsCheck
@onready var volume_slider: HSlider = $Panel/ScrollBox/VolumeSlider
@onready var volume_label: Label = $Panel/ScrollBox/VolumeLabel
@onready var music_slider: HSlider = $Panel/ScrollBox/MusicSlider
@onready var music_label: Label = $Panel/ScrollBox/MusicLabel
@onready var camera_slider: HSlider = $Panel/ScrollBox/CameraSlider
@onready var camera_label: Label = $Panel/ScrollBox/CameraLabel
@onready var hud_slider: HSlider = $Panel/ScrollBox/HudSlider
@onready var hud_label: Label = $Panel/ScrollBox/HudLabel
@onready var deadzone_slider: HSlider = $Panel/ScrollBox/DeadzoneSlider
@onready var deadzone_label: Label = $Panel/ScrollBox/DeadzoneLabel
@onready var reset_btn: Button = $Panel/ScrollBox/ResetBtn

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): visible = false)
	if mode_option:
		mode_option.item_selected.connect(_on_mode_selected)
	if lang_option:
		lang_option.item_selected.connect(_on_lang_selected)
	if graphics_option:
		graphics_option.item_selected.connect(_on_graphics_selected)
	if mute_check:
		mute_check.toggled.connect(_on_mute_toggled)
	if vibrate_check:
		vibrate_check.toggled.connect(_on_vibrate_toggled)
	if fps_check:
		fps_check.toggled.connect(_on_fps_toggled)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if camera_slider:
		camera_slider.value_changed.connect(_on_camera_changed)
	if hud_slider:
		hud_slider.value_changed.connect(_on_hud_changed)
	if deadzone_slider:
		deadzone_slider.value_changed.connect(_on_deadzone_changed)
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
		
	refresh()

func _sm():
	return get_node_or_null("/root/SaveManager")

func refresh() -> void:
	var sm = _sm()
	if not sm:
		return
	if mode_option:
		mode_option.clear()
		mode_option.add_item("🎯 PUBG Mode (Tactical TPP)", 0)
		mode_option.add_item("⚔️ MLBB Mode (Strategic Aerial View)", 1)
		mode_option.selected = 1 if sm.get("game_mode") == "mlbb" else 0
	if lang_option:
		lang_option.clear()
		lang_option.add_item("🇲🇲 မြန်မာစာ (Myanmar)", 0)
		lang_option.add_item("🌐 English (UK/US)", 1)
		lang_option.selected = 1 if sm.get("language") == "en" else 0
	if graphics_option:
		graphics_option.clear()
		graphics_option.add_item("⚡ ချောမွေ့ (Smooth - 60 FPS)", 0)
		graphics_option.add_item("⚖️ မျှတ (Balanced)", 1)
		graphics_option.add_item("✨ အမြင့် (HD / PBR)", 2)
		graphics_option.add_item("💎 အလွန်မြင့် (Ultra HDR)", 3)
		var gq = sm.get("graphics_quality")
		graphics_option.selected = 0 if gq == "smooth" else (2 if gq == "hd" else (3 if gq == "ultra" else 1))
		apply_graphics_settings(str(gq))
	if mute_check and sm.get("muted") != null:
		mute_check.button_pressed = bool(sm.muted)
	if vibrate_check and sm.get("vibration_enabled") != null:
		vibrate_check.button_pressed = bool(sm.vibration_enabled)
	if fps_check and sm.get("show_fps") != null:
		fps_check.button_pressed = bool(sm.show_fps)
	if volume_slider and sm.get("volume") != null:
		volume_slider.value = float(sm.volume) * 100.0
		if volume_label: volume_label.text = "🔊 အသံအတိုးအကျယ် (SFX Volume): %d%%" % int(round(volume_slider.value))
	if music_slider and sm.get("music_volume") != null:
		music_slider.value = float(sm.music_volume) * 100.0
		if music_label: music_label.text = "🎵 သီချင်းသံ (Music/Song Volume): %d%%" % int(round(music_slider.value))
	if camera_slider and sm.get("camera_sensitivity") != null:
		camera_slider.value = float(sm.camera_sensitivity) * 100.0
		if camera_label: camera_label.text = "🎥 ကင်မရာလှည့်နှုန်း (Sensitivity): %d%%" % int(round(camera_slider.value))
	if hud_slider and sm.get("hud_scale") != null:
		hud_slider.value = float(sm.hud_scale) * 100.0
		if hud_label: hud_label.text = "🎮 ခလုတ်အရွယ်အစား (HUD Scale): %d%%" % int(round(hud_slider.value))
	if deadzone_slider and sm.get("joystick_deadzone") != null:
		deadzone_slider.value = float(sm.joystick_deadzone) * 100.0
		if deadzone_label: deadzone_label.text = "🕹️ Joystick အသေဇုန် (Deadzone): %d%%" % int(round(deadzone_slider.value))

func _on_mode_selected(index: int) -> void:
	var sm = _sm()
	if sm:
		sm.game_mode = "mlbb" if index == 1 else "pubg"
		sm.save_settings()
		# Live update camera perspective if player exists
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var pivot = player.get_node_or_null("CameraPivot")
			if pivot:
				if sm.game_mode == "mlbb":
					pivot.target_arm_length = 6.5
					pivot.rotation.x = deg_to_rad(-45.0)
				else:
					pivot.target_arm_length = 2.4
					pivot.rotation.x = deg_to_rad(-10.0)

func _on_lang_selected(index: int) -> void:
	var sm = _sm()
	if sm:
		sm.language = "en" if index == 1 else "my"
		sm.save_settings()

func _on_graphics_selected(index: int) -> void:
	var sm = _sm()
	if sm:
		var modes = ["smooth", "balanced", "hd", "ultra"]
		sm.graphics_quality = modes[clamp(index, 0, 3)]
		sm.save_settings()
		apply_graphics_settings(sm.graphics_quality)

func apply_graphics_settings(quality: String) -> void:
	var vp_rid = get_viewport().get_viewport_rid()
	var env_node = get_tree().get_first_node_in_group("world_env") as WorldEnvironment
	if not env_node:
		env_node = get_node_or_null("/root/World/WorldEnvironment") as WorldEnvironment
	var env = env_node.environment if env_node else null
	
	# Lever 1: Directional Sun Shadows & Lever 4: Shadow Filtering
	var sun = get_tree().root.find_child("SunLight", true, false) as DirectionalLight3D
	
	var foliage_wind_mult = 1.0
	if quality == "smooth":
		# Low / Smooth: 60 FPS mobile performance priority
		foliage_wind_mult = 0.0
		RenderingServer.viewport_set_msaa_3d(vp_rid, RenderingServer.VIEWPORT_MSAA_DISABLED)
		RenderingServer.viewport_set_scaling_3d_scale(vp_rid, 0.75)
		if sun:
			sun.shadow_enabled = false
		if env:
			env.ssao_enabled = false
			env.ssr_enabled = false
			env.ssil_enabled = false
			env.glow_bloom = 0.08
			env.volumetric_fog_enabled = false
	elif quality == "balanced":
		# Balanced: Default solid mobile fidelity
		foliage_wind_mult = 0.75
		RenderingServer.viewport_set_msaa_3d(vp_rid, RenderingServer.VIEWPORT_MSAA_2X)
		RenderingServer.viewport_set_scaling_3d_scale(vp_rid, 0.88)
		if sun:
			sun.shadow_enabled = true
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		if env:
			env.ssao_enabled = true
			env.ssao_radius = 2.0
			env.ssao_intensity = 1.5
			env.ssr_enabled = false
			env.ssil_enabled = false
			env.glow_bloom = 0.16
			env.volumetric_fog_enabled = false
	elif quality == "hd":
		# HD: PUBG Mobile high-tier visual fidelity
		foliage_wind_mult = 1.0
		RenderingServer.viewport_set_msaa_3d(vp_rid, RenderingServer.VIEWPORT_MSAA_2X)
		RenderingServer.viewport_set_scaling_3d_scale(vp_rid, 1.0)
		if sun:
			sun.shadow_enabled = true
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		if env:
			env.ssao_enabled = true
			env.ssao_radius = 3.2
			env.ssao_intensity = 2.4
			env.ssr_enabled = true
			env.ssil_enabled = true
			env.glow_bloom = 0.22
			env.volumetric_fog_enabled = true
	elif quality == "ultra":
		# Ultra HDR: vivo V60 flagship showcase
		foliage_wind_mult = 1.25
		RenderingServer.viewport_set_msaa_3d(vp_rid, RenderingServer.VIEWPORT_MSAA_4X)
		RenderingServer.viewport_set_scaling_3d_scale(vp_rid, 1.0)
		if sun:
			sun.shadow_enabled = true
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		if env:
			env.ssao_enabled = true
			env.ssao_radius = 4.0
			env.ssao_intensity = 3.0
			env.ssr_enabled = true
			env.ssil_enabled = true
			env.glow_bloom = 0.28
			env.volumetric_fog_enabled = true

	# Lever 5: Live Dynamic Foliage Sway Wind Modulation
	_apply_foliage_sway_multiplier(foliage_wind_mult)

	# Lever 6: Dynamic Fluvial River Water Wave Modulation
	var water_wave_mult = 1.0 if quality in ["hd", "ultra"] else (0.6 if quality == "balanced" else 0.0)
	_apply_water_wave_multiplier(water_wave_mult)

func _apply_foliage_sway_multiplier(mult: float) -> void:
	var foliage_nodes = get_tree().get_nodes_in_group("foliage")
	for node in foliage_nodes:
		if node is MeshInstance3D:
			for i in range(node.get_surface_override_material_count()):
				var mat = node.get_surface_override_material(i)
				if mat is ShaderMaterial:
					mat.set_shader_parameter("wind_strength", 0.22 * mult)
					mat.set_shader_parameter("flutter_strength", 0.08 * mult)

func _apply_water_wave_multiplier(mult: float) -> void:
	var river_node = get_tree().root.find_child("VillageRiverWater", true, false) as MeshInstance3D
	if river_node:
		var mat = river_node.get_surface_override_material(0)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("wave_amplitude", 0.12 * mult)

func _on_vibrate_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm:
		sm.vibration_enabled = pressed
		sm.save_settings()
		if pressed:
			Input.vibrate_handheld(60)

func _on_music_changed(val: float) -> void:
	var sm = _sm()
	if sm:
		sm.music_volume = clampf(val / 100.0, 0.0, 1.0)
		sm.save_settings()
		if music_label:
			music_label.text = "🎵 သီချင်းသံ (Music/Song Volume): %d%%" % int(round(val))
		var am = get_node_or_null("/root/AudioManager")
		if not am:
			am = get_tree().get_first_node_in_group("audio_manager")
		if not am:
			var world = get_node_or_null("/root/World")
			if world:
				am = world.get_node_or_null("AudioManager")
		if am and am.get("bgm_music_player"):
			am.bgm_music_player.volume_db = linear_to_db(clampf(sm.music_volume * 0.4, 0.0001, 1.0))

func _on_mute_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm:
		sm.muted = pressed
		sm.save_settings()
		var am = get_node_or_null("/root/AudioManager")
		if not am:
			am = get_tree().get_first_node_in_group("audio_manager")
		if not am:
			var world = get_node_or_null("/root/World")
			if world:
				am = world.get_node_or_null("AudioManager")
		if am:
			am.is_muted = pressed
			if am.get("bgm_music_player"):
				am.bgm_music_player.volume_db = -80.0 if pressed else linear_to_db(clampf(sm.music_volume * 0.4, 0.0001, 1.0))

func _on_fps_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm:
		sm.show_fps = pressed
		sm.save_settings()
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("set_fps_visible"):
			hud.set_fps_visible(pressed)

func _on_volume_changed(val: float) -> void:
	var sm = _sm()
	if sm:
		sm.volume = clampf(val / 100.0, 0.0, 1.0)
		sm.save_settings()
		if volume_label:
			volume_label.text = "🔊 အသံအတိုးအကျယ် (SFX Volume): %d%%" % int(round(val))

func _on_camera_changed(val: float) -> void:
	var sm = _sm()
	if sm:
		sm.camera_sensitivity = clampf(val / 100.0, 0.5, 2.0)
		sm.save_settings()
		if camera_label:
			camera_label.text = "🎥 ကင်မရာလှည့်နှုန်း (Sensitivity): %d%%" % int(round(val))

func _on_hud_changed(val: float) -> void:
	var sm = _sm()
	if sm:
		sm.hud_scale = clampf(val / 100.0, 0.8, 1.25)
		sm.save_settings()
		if hud_label:
			hud_label.text = "🎮 ခလုတ်အရွယ်အစား (HUD Scale): %d%%" % int(round(val))
		# Trigger live HUD rescaling if in world
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("apply_hud_scale"):
			hud.apply_hud_scale(sm.hud_scale)

func _on_deadzone_changed(val: float) -> void:
	var sm = _sm()
	if sm:
		sm.joystick_deadzone = clampf(val / 100.0, 0.0, 0.4)
		sm.save_settings()
		if deadzone_label:
			deadzone_label.text = "🕹️ Joystick အသေဇုန် (Deadzone): %d%%" % int(round(val))

func _on_reset_pressed() -> void:
	var sm = _sm()
	if sm:
		sm.reset_settings()
		refresh()
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("apply_hud_scale"):
			hud.apply_hud_scale(sm.hud_scale)
