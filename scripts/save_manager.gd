extends Node

# --- Reliable Save & Load Architecture for Mobile ---

const SAVE_PATH: String = "user://myanmar_savegame.json"

var has_save: bool = false
var save_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	has_save = FileAccess.file_exists(SAVE_PATH)

func save_game(player_pos: Vector3, quest_stage: int, villagers_count: int, stamina: float) -> bool:
	var data = {
		"version": 1,
		"pos_x": player_pos.x,
		"pos_y": player_pos.y,
		"pos_z": player_pos.z,
		"quest_stage": quest_stage,
		"villagers_talked": villagers_count,
		"stamina": stamina,
		"timestamp": Time.get_unix_time_from_system()
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	var json_str = JSON.stringify(data)
	file.store_string(json_str)
	file.close()
	has_save = true
	save_data = data
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(content)
	if err == OK and json.data is Dictionary:
		save_data = json.data
		return save_data
	return {}