extends Control

# --- Main Menu System ---

@onready var continue_btn: Button = $ButtonContainer/ContinueBtn
@onready var new_game_btn: Button = $ButtonContainer/NewGameBtn
@onready var outfit_btn: Button = $ButtonContainer/OutfitBtn
@onready var vehicle_btn: Button = $ButtonContainer/VehicleBtn
@onready var settings_btn: Button = $ButtonContainer/SettingsBtn
@onready var quit_btn: Button = $ButtonContainer/QuitBtn
@onready var character_customizer: Control = $CharacterCustomizer
@onready var vehicle_customizer: Control = $VehicleCustomizer
@onready var settings_panel: Control = $SettingsPanel

func _ready() -> void:
	var save_path = "user://myanmar_savegame.json"
	if continue_btn:
		continue_btn.visible = FileAccess.file_exists(save_path)
		continue_btn.pressed.connect(_on_continue_pressed)
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game_pressed)
	if outfit_btn:
		outfit_btn.pressed.connect(_on_outfit_pressed)
	if vehicle_btn:
		vehicle_btn.pressed.connect(_on_vehicle_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func _on_outfit_pressed() -> void:
	if character_customizer:
		character_customizer.visible = true

func _on_vehicle_pressed() -> void:
	if vehicle_customizer:
		vehicle_customizer.visible = true
		if vehicle_customizer.has_method("refresh"):
			vehicle_customizer.refresh()

func _on_settings_pressed() -> void:
	if settings_panel:
		settings_panel.visible = true
		if settings_panel.has_method("refresh"):
			settings_panel.refresh()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_new_game_pressed() -> void:
	var save_path = "user://myanmar_savegame.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()