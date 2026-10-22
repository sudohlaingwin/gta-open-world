extends Panel
## Slice 21 settings panel: ONLY settings that actually work.
## Mute toggles SaveManager.muted (and the world tone player reads
## it), volume scales every generated tone, reset restores defaults
## and saves them. No decorative sliders: if a control is shown,
## it changes the game. Shared by the main menu and the pause menu.

var mute_check: CheckButton = null
var volume_slider: HSlider = null
var reset_button: Button = null
var back_button: Button = null


func _ready() -> void:
	mute_check = get_node_or_null("MuteCheck") as CheckButton
	if mute_check != null:
		mute_check.toggled.connect(_on_mute_toggled)
	volume_slider = get_node_or_null("VolumeSlider") as HSlider
	if volume_slider != null:
		volume_slider.value_changed.connect(_on_volume_changed)
	reset_button = get_node_or_null("ResetButton") as Button
	if reset_button != null:
		reset_button.pressed.connect(_on_reset_pressed)
	back_button = get_node_or_null("BackButton") as Button
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	refresh()


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


func _on_reset_pressed() -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.call("reset_settings")
	refresh()


func _on_back_pressed() -> void:
	visible = false
