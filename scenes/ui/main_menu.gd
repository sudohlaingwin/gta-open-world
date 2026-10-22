extends Control
## Slice 21 main menu: Continue (only when a valid save exists),
## New Game (fresh world), Settings (working settings only).
## Continue hands the loaded save to SaveManager.pending_load and the
## world player applies it on spawn; New Game clears pending_load so
## the world starts fresh. No decorative buttons: every button here
## does what it says.
## Slice 30 adds Character (wired exactly like Settings): it shows
## the outfit panel, whose choices persist in SaveManager settings
## and apply to the player at world spawn.
## Slice 35 adds Vehicle the same way: it shows the paint panel,
## whose choices persist in SaveManager settings and apply to the
## player vehicles at world spawn.

var continue_button: Button = null
var new_game_button: Button = null
var settings_button: Button = null
var character_button: Button = null
var vehicle_button: Button = null
var no_save_label: Label = null
var settings_panel: Node = null
var character_panel: Node = null
var vehicle_panel: Node = null


func _ready() -> void:
	continue_button = get_node_or_null("ContinueButton") as Button
	if continue_button != null:
		continue_button.pressed.connect(_on_continue_pressed)
	new_game_button = get_node_or_null("NewGameButton") as Button
	if new_game_button != null:
		new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button = get_node_or_null("SettingsButton") as Button
	if settings_button != null:
		settings_button.pressed.connect(_on_settings_pressed)
	character_button = get_node_or_null("CharacterButton") as Button
	if character_button != null:
		character_button.pressed.connect(_on_character_pressed)
	vehicle_button = get_node_or_null("VehicleButton") as Button
	if vehicle_button != null:
		vehicle_button.pressed.connect(_on_vehicle_pressed)
	no_save_label = get_node_or_null("NoSaveLabel") as Label
	settings_panel = get_node_or_null("SettingsPanel")
	character_panel = get_node_or_null("CharacterPanel")
	vehicle_panel = get_node_or_null("VehiclePanel")
	_refresh_continue()


func _sm():
	return get_node_or_null("/root/SaveManager")


func _refresh_continue() -> void:
	var sm = _sm()
	var has = false
	if sm != null:
		has = bool(sm.call("has_valid_save"))
	if continue_button != null:
		continue_button.visible = has
	if no_save_label != null:
		no_save_label.visible = not has


func _on_continue_pressed() -> void:
	var sm = _sm()
	if sm == null:
		return
	var data = sm.call("load_save")
	if not (data is Dictionary) or data.is_empty():
		_refresh_continue()
		return
	sm.set("pending_load", data)
	get_tree().change_scene_to_file("res://main.tscn")


func _on_new_game_pressed() -> void:
	var sm = _sm()
	if sm != null:
		sm.set("pending_load", {})
	get_tree().change_scene_to_file("res://main.tscn")


func _on_settings_pressed() -> void:
	if settings_panel == null:
		settings_panel = get_node_or_null("SettingsPanel")
	if settings_panel == null:
		return
	settings_panel.visible = true
	if settings_panel.has_method("refresh"):
		settings_panel.call("refresh")


func _on_character_pressed() -> void:
	if character_panel == null:
		character_panel = get_node_or_null("CharacterPanel")
	if character_panel == null:
		return
	character_panel.visible = true
	if character_panel.has_method("refresh"):
		character_panel.call("refresh")


func _on_vehicle_pressed() -> void:
	if vehicle_panel == null:
		vehicle_panel = get_node_or_null("VehiclePanel")
	if vehicle_panel == null:
		return
	vehicle_panel.visible = true
	if vehicle_panel.has_method("refresh"):
		vehicle_panel.call("refresh")
