extends Control

# --- Main Menu System ---

@onready var continue_btn: Button = $ButtonContainer/ContinueBtn
@onready var new_game_btn: Button = $ButtonContainer/NewGameBtn
@onready var quit_btn: Button = $ButtonContainer/QuitBtn

func _ready() -> void:
	var save_path = "user://myanmar_savegame.json"
	if continue_btn:
		continue_btn.visible = FileAccess.file_exists(save_path)
		continue_btn.pressed.connect(_on_continue_pressed)
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_new_game_pressed() -> void:
	var save_path = "user://myanmar_savegame.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()