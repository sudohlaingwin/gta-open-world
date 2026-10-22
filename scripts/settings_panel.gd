extends Control

# --- Mobile Settings System (Genuinely Wired & Persistent) ---

@onready var close_btn: Button = $Panel/CloseBtn
@onready var mute_check: CheckButton = $Panel/ScrollBox/MuteCheck
@onready var volume_slider: HSlider = $Panel/ScrollBox/VolumeSlider
@onready var volume_label: Label = $Panel/ScrollBox/VolumeLabel
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
	if mute_check:
		mute_check.toggled.connect(_on_mute_toggled)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
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
	if mute_check and sm.get("muted") != null:
		mute_check.button_pressed = bool(sm.muted)
	if volume_slider and sm.get("volume") != null:
		volume_slider.value = float(sm.volume) * 100.0
		if volume_label: volume_label.text = "🔊 အသံအတိုးအကျယ် (Volume): %d%%" % int(round(volume_slider.value))
	if camera_slider and sm.get("camera_sensitivity") != null:
		camera_slider.value = float(sm.camera_sensitivity) * 100.0
		if camera_label: camera_label.text = "🎥 ကင်မရာလှည့်နှုန်း (Sensitivity): %d%%" % int(round(camera_slider.value))
	if hud_slider and sm.get("hud_scale") != null:
		hud_slider.value = float(sm.hud_scale) * 100.0
		if hud_label: hud_label.text = "🎮 ခလုတ်အရွယ်အစား (HUD Scale): %d%%" % int(round(hud_slider.value))
	if deadzone_slider and sm.get("joystick_deadzone") != null:
		deadzone_slider.value = float(sm.joystick_deadzone) * 100.0
		if deadzone_label: deadzone_label.text = "🕹️ Joystick အသေဇုန် (Deadzone): %d%%" % int(round(deadzone_slider.value))

func _on_mute_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm:
		sm.muted = pressed
		sm.save_settings()

func _on_volume_changed(val: float) -> void:
	var sm = _sm()
	if sm:
		sm.volume = clampf(val / 100.0, 0.0, 1.0)
		sm.save_settings()
		if volume_label:
			volume_label.text = "🔊 အသံအတိုးအကျယ် (Volume): %d%%" % int(round(val))

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
