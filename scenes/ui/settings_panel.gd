extends Panel
## Slice 21 settings panel: ONLY settings that actually work.
## Mute toggles SaveManager.muted (and the world tone player reads
## it), volume scales every generated tone, reset restores defaults
## and saves them. No decorative sliders: if a control is shown,
## it changes the game. Shared by the main menu and the pause menu.
## Slice 32 adds three control settings, all persisted in
## SaveManager settings and all genuinely wired:
## - Camera sensitivity: scales touch-drag orbit speed in camera.gd
##   (zoom buttons and Q/E fallbacks keep their fixed steps).
## - HUD size: scales every touch HUD control around its own centre
##   in player.gd (_apply_hud_scale); pause menu and world-map
##   overlay are deliberately NOT scaled (menus keep their layout,
##   and the map's pixel math must not move under it).
## - Joystick deadzone: the single deadzone for player movement AND
##   every vehicle's steering, because all vehicles read the
##   joystick's deadzone-filtered touch_vector.
## Camera sensitivity and deadzone are read live on every input, so
## a change made in the pause Settings screen takes effect the
## moment play resumes. HUD size applies on world load and on
## pause-resume (player.gd re-applies it in _on_resume_pressed).
## Slice 55 driving-assistance mode: a cycle button (Arcade ->
## Balanced -> Realistic -> Arcade) that writes
## SaveManager.driving_mode and saves immediately. The road
## vehicles read the mode live every physics frame, so a change
## made in the pause Settings screen applies the moment play
## resumes, with no re-enter and no restart. Reset restores
## Balanced (the pre-Slice-55 behaviour exactly) via refresh().

var mute_check: CheckButton = null
var volume_slider: HSlider = null
var volume_label: Label = null
var camera_slider: HSlider = null
var camera_label: Label = null
var hud_slider: HSlider = null
var hud_label: Label = null
var deadzone_slider: HSlider = null
var deadzone_label: Label = null
## Slice 68 graphics tiers replace the Slice 40 High/Low toggle:
## a cycle button (Low -> Balanced -> High -> Ultra -> Low)
## writing SaveManager.graphics_tier (and the graphics_quality
## mirror), persisted immediately, applied live to the world via
## player.apply_graphics_quality when one is loaded.
var quality_check: CheckButton = null
var tier_button: Button = null
var fps_check: CheckButton = null
var drive_label: Label = null
var drive_button: Button = null
var reset_button: Button = null
var back_button: Button = null
## Slice 158 full-settings round: three genuinely wired controls
## created in CODE (the .tscn is never edited): SFX volume
## (effect sounds on top of master), vibration toggle (gates S157
## haptics), camera invert-Y toggle (flips free-look pitch drag).
## The panel is re-laid out in code too: existing rows compress
## to a compact anchor table and the panel grows to 0.04-0.98,
## so the three new rows fit with no overlap on phone or pause.
var sfx_label: Label = null
var sfx_slider: HSlider = null
var vibration_check: CheckButton = null
var invert_check: CheckButton = null


func _ready() -> void:
	mute_check = get_node_or_null("MuteCheck") as CheckButton
	if mute_check != null:
		mute_check.toggled.connect(_on_mute_toggled)
	volume_slider = get_node_or_null("VolumeSlider") as HSlider
	if volume_slider != null:
		volume_slider.value_changed.connect(_on_volume_changed)
	volume_label = get_node_or_null("VolumeLabel") as Label
	camera_slider = get_node_or_null("CameraSlider") as HSlider
	if camera_slider != null:
		camera_slider.value_changed.connect(_on_camera_changed)
	camera_label = get_node_or_null("CameraLabel") as Label
	hud_slider = get_node_or_null("HudSlider") as HSlider
	if hud_slider != null:
		hud_slider.value_changed.connect(_on_hud_changed)
	hud_label = get_node_or_null("HudLabel") as Label
	deadzone_slider = get_node_or_null("DeadzoneSlider") as HSlider
	if deadzone_slider != null:
		deadzone_slider.value_changed.connect(_on_deadzone_changed)
	deadzone_label = get_node_or_null("DeadzoneLabel") as Label
	quality_check = get_node_or_null("QualityCheck") as CheckButton
	if quality_check != null:
		quality_check.visible = false
	tier_button = get_node_or_null("TierButton") as Button
	if tier_button != null:
		tier_button.pressed.connect(_on_tier_pressed)
	fps_check = get_node_or_null("FpsCheck") as CheckButton
	if fps_check != null:
		fps_check.toggled.connect(_on_fps_toggled)
	drive_label = get_node_or_null("DriveLabel") as Label
	drive_button = get_node_or_null("DriveButton") as Button
	if drive_button != null:
		drive_button.pressed.connect(_on_drive_pressed)
	reset_button = get_node_or_null("ResetButton") as Button
	if reset_button != null:
		reset_button.pressed.connect(_on_reset_pressed)
	back_button = get_node_or_null("BackButton") as Button
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	_layout158()
	refresh()


func _layout158() -> void:
	# Grow the panel a little (menu and pause parents are both
	# fullscreen, so this is safe in both contexts), then make
	# the content SCROLLABLE: measured minimum row heights
	# (Title 71 px, checks 44 px, labels/buttons 36 px, sliders
	# 20 px — tall Myanmar font metrics) sum to ~717 px, over
	# the 677 px panel, so a squeezed single page would overlap
	# rows. A VBox in a ScrollContainer keeps every row at full
	# readable size and is the standard mobile settings pattern.
	# Scene file untouched: children are only reparented in code.
	anchor_top = 0.04
	anchor_bottom = 0.98
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll158"
	scroll.anchor_left = 0.0
	scroll.anchor_top = 0.0
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	var box := VBoxContainer.new()
	box.name = "Rows158"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	scroll.add_child(box)
	add_child(scroll)
	var existing: Array = []
	for ch in get_children():
		if ch != scroll:
			existing.append(ch)
	for ch in existing:
		remove_child(ch)
		(ch as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(ch)
	sfx_label = Label.new()
	sfx_label.name = "SfxLabel158"
	sfx_label.text = "SFX အသံ: 100%"
	sfx_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(sfx_label)
	sfx_slider = HSlider.new()
	sfx_slider.name = "SfxSlider158"
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0
	sfx_slider.value = 100.0
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.value_changed.connect(_on_sfx_changed)
	box.add_child(sfx_slider)
	vibration_check = CheckButton.new()
	vibration_check.name = "VibrationCheck158"
	vibration_check.text = "တုန်ခါမှု"
	vibration_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vibration_check.toggled.connect(_on_vibration_toggled)
	box.add_child(vibration_check)
	invert_check = CheckButton.new()
	invert_check.name = "InvertCheck158"
	invert_check.text = "ကင်မရာ ပြောင်းပြန် (Y)"
	invert_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	invert_check.toggled.connect(_on_invert_toggled)
	box.add_child(invert_check)
	# New rows go right after the master volume rows (same
	# order as the anchor table they replace): move the four
	# new nodes to just after VolumeSlider in the box.
	var vol_idx := -1
	for i in range(box.get_child_count()):
		if String(box.get_child(i).name) == "VolumeSlider":
			vol_idx = i
			break
	if vol_idx >= 0:
		box.move_child(sfx_label, vol_idx + 1)
		box.move_child(sfx_slider, vol_idx + 2)
		box.move_child(vibration_check, vol_idx + 3)
		box.move_child(invert_check, vol_idx + 4)


func _sm():
	return get_node_or_null("/root/SaveManager")


func refresh() -> void:
	var sm = _sm()
	if sm == null:
		return
	if mute_check != null:
		mute_check.button_pressed = bool(sm.get("muted"))
	if volume_slider != null:
		volume_slider.value = float(sm.get("volume")) * 100.0
	if volume_label != null:
		volume_label.text = "အသံအတိုးအကျယ်: %d%%" % int(round(float(sm.get("volume")) * 100.0))
	if camera_slider != null:
		camera_slider.value = float(sm.get("camera_sensitivity")) * 100.0
	if camera_label != null:
		camera_label.text = "ကင်မရာ လှည့်နှုန်း: %d%%" % int(round(float(sm.get("camera_sensitivity")) * 100.0))
	if hud_slider != null:
		hud_slider.value = float(sm.get("hud_scale")) * 100.0
	if hud_label != null:
		hud_label.text = "ခလုတ် အရွယ်အစား: %d%%" % int(round(float(sm.get("hud_scale")) * 100.0))
	if deadzone_slider != null:
		deadzone_slider.value = float(sm.get("joystick_deadzone")) * 100.0
	if deadzone_label != null:
		deadzone_label.text = "Joystick အသေဇုန်: %d%%" % int(round(float(sm.get("joystick_deadzone")) * 100.0))
	if quality_check != null:
		quality_check.visible = false
	if tier_button != null:
		tier_button.text = _tier_text(_current_tier(sm))
	if fps_check != null:
		fps_check.button_pressed = bool(sm.get("fps_visible"))
	if sfx_slider != null:
		sfx_slider.value = float(sm.get("sfx_volume")) * 100.0
	if sfx_label != null:
		sfx_label.text = "SFX အသံ: %d%%" % int(round(float(sm.get("sfx_volume")) * 100.0))
	if vibration_check != null:
		vibration_check.button_pressed = bool(sm.get("vibration_enabled"))
	if invert_check != null:
		invert_check.button_pressed = bool(sm.get("camera_invert_y"))
	if drive_button != null:
		drive_button.text = _drive_mode_text(int(sm.get("driving_mode")))


## Audit item 4: apply the quality setting to the live world, if one
## is loaded. In the main menu there is no Player node, so this is a
## no-op there and the choice applies at the next world spawn
## (player.gd calls apply_graphics_quality in _ready). In the pause
## menu the world is loaded, so the change takes effect the moment
## play resumes — no restart, no reload.
func _apply_quality_to_world() -> void:
	var world = get_tree().current_scene
	if world == null:
		return
	var pl = world.get_node_or_null("Player")
	if pl != null and pl.has_method("apply_graphics_quality"):
		pl.call("apply_graphics_quality")


func _current_tier(sm) -> int:
	if sm == null:
		return 2
	if sm.get("graphics_tier") != null:
		return clampi(int(sm.get("graphics_tier")), 0, 3)
	return 2 if int(sm.get("graphics_quality")) == 0 else 0


func _tier_text(tier: int) -> String:
	match clampi(tier, 0, 3):
		0:
			return "ဂရပ်ဖစ်: နိမ့် (Low)"
		1:
			return "ဂရပ်ဖစ်: အလယ် (Balanced)"
		3:
			return "ဂရပ်ဖစ်: အလွန်မြင့် (Ultra)"
		_:
			return "ဂရပ်ဖစ်: မြင့် (High)"


func _on_tier_pressed() -> void:
	var sm = _sm()
	if sm == null:
		return
	var next_tier = (_current_tier(sm) + 1) % 4
	sm.set("graphics_tier", next_tier)
	sm.set("graphics_quality", 0 if next_tier >= 2 else 1)
	sm.call("save_settings")
	if tier_button != null:
		tier_button.text = _tier_text(next_tier)
	_apply_quality_to_world()


func _on_fps_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("fps_visible", pressed)
	sm.call("save_settings")


func _on_mute_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("muted", pressed)
	sm.call("save_settings")


func _on_volume_changed(value: float) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("volume", clampf(value / 100.0, 0.0, 1.0))
	sm.call("save_settings")
	if volume_label != null:
		volume_label.text = "အသံအတိုးအကျယ်: %d%%" % int(round(value))


func _on_sfx_changed(value: float) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("sfx_volume", clampf(value / 100.0, 0.0, 1.0))
	sm.call("save_settings")
	if sfx_label != null:
		sfx_label.text = "SFX အသံ: %d%%" % int(round(value))


func _on_vibration_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("vibration_enabled", pressed)
	sm.call("save_settings")


func _on_invert_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("camera_invert_y", pressed)
	sm.call("save_settings")


func _on_camera_changed(value: float) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("camera_sensitivity", clampf(value / 100.0, 0.5, 2.0))
	sm.call("save_settings")
	if camera_label != null:
		camera_label.text = "ကင်မရာ လှည့်နှုန်း: %d%%" % int(round(value))


func _on_hud_changed(value: float) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("hud_scale", clampf(value / 100.0, 0.8, 1.25))
	sm.call("save_settings")
	if hud_label != null:
		hud_label.text = "ခလုတ် အရွယ်အစား: %d%%" % int(round(value))


func _on_deadzone_changed(value: float) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("joystick_deadzone", clampf(value / 100.0, 0.0, 0.4))
	sm.call("save_settings")
	if deadzone_label != null:
		deadzone_label.text = "Joystick အသေဇုန်: %d%%" % int(round(value))


func _drive_mode_text(mode: int) -> String:
	match clampi(mode, 0, 2):
		0:
			return "မောင်းနှင်မှုပုံစံ: လွယ်ကူ (Arcade)"
		2:
			return "မောင်းနှင်မှုပုံစံ: လက်တွေ့ (Realistic)"
		_:
			return "မောင်းနှင်မှုပုံစံ: ပုံမှန် (Balanced)"


func _on_drive_pressed() -> void:
	var sm = _sm()
	if sm == null:
		return
	var next_mode = (int(sm.get("driving_mode")) + 1) % 3
	sm.set("driving_mode", next_mode)
	sm.call("save_settings")
	if drive_button != null:
		drive_button.text = _drive_mode_text(next_mode)


func _on_reset_pressed() -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.call("reset_settings")
	refresh()


func _on_back_pressed() -> void:
	visible = false
