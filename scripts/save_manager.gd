extends Node

# --- Reliable Save & Settings Architecture for Mobile ---

const SAVE_PATH: String = "user://myanmar_savegame.json"
const SETTINGS_PATH: String = "user://settings.json"

var has_save: bool = false
var save_data: Dictionary = {}

# Settings State
var muted: bool = false
var volume: float = 1.0
var camera_sensitivity: float = 1.0
var hud_scale: float = 1.0
var joystick_deadzone: float = 0.15
var shirt_color: Color = Color(0.96, 0.94, 0.90, 1.0)
var longyi_color: Color = Color(0.08, 0.35, 0.22, 1.0)

# Vehicle Paints State
var car_paint_html: String = "#1F73C7"
var motorcycle_paint_html: String = "#D9261A"
var tuktuk_paint_html: String = "#F2B81A"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	has_save = FileAccess.file_exists(SAVE_PATH)
	load_settings()

func _atomic_write(path: String, text: String) -> bool:
	var tmp_path := path + ".tmp"
	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	if DirAccess.rename_absolute(tmp_path, path) != OK:
		return false
	return true

func save_game(player_pos: Vector3, quest_stage: int, villagers_count: int, stamina: float) -> bool:
	var data = {
		"version": 1,
		"pos_x": player_pos.x,
		"pos_y": player_pos.y,
		"pos_z": player_pos.z,
		"quest_stage": quest_stage,
		"villagers_talked": villagers_count,
		"stamina": stamina,
		"shirt_color": var_to_str(shirt_color),
		"longyi_color": var_to_str(longyi_color),
		"timestamp": Time.get_unix_time_from_system()
	}
	var json_str = JSON.stringify(data)
	if not _atomic_write(SAVE_PATH, json_str):
		return false
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
		if save_data.has("shirt_color") and save_data["shirt_color"] is String:
			shirt_color = str_to_var(save_data["shirt_color"])
		if save_data.has("longyi_color") and save_data["longyi_color"] is String:
			longyi_color = str_to_var(save_data["longyi_color"])
		return save_data
	return {}

func load_settings() -> void:
	muted = false
	volume = 1.0
	camera_sensitivity = 1.0
	hud_scale = 1.0
	joystick_deadzone = 0.15
	car_paint_html = "#1F73C7"
	motorcycle_paint_html = "#D9261A"
	tuktuk_paint_html = "#F2B81A"
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) == OK and json.data is Dictionary:
		var d = json.data
		if d.has("muted"): muted = bool(d["muted"])
		if d.has("volume"): volume = clampf(float(d["volume"]), 0.0, 1.0)
		if d.has("camera_sensitivity"): camera_sensitivity = clampf(float(d["camera_sensitivity"]), 0.5, 2.0)
		if d.has("hud_scale"): hud_scale = clampf(float(d["hud_scale"]), 0.8, 1.25)
		if d.has("joystick_deadzone"): joystick_deadzone = clampf(float(d["joystick_deadzone"]), 0.0, 0.4)
		if d.has("car_paint_html"): car_paint_html = str(d["car_paint_html"])
		if d.has("motorcycle_paint_html"): motorcycle_paint_html = str(d["motorcycle_paint_html"])
		if d.has("tuktuk_paint_html"): tuktuk_paint_html = str(d["tuktuk_paint_html"])

func save_settings() -> bool:
	var d = {
		"muted": muted,
		"volume": volume,
		"camera_sensitivity": camera_sensitivity,
		"hud_scale": hud_scale,
		"joystick_deadzone": joystick_deadzone,
		"car_paint_html": car_paint_html,
		"motorcycle_paint_html": motorcycle_paint_html,
		"tuktuk_paint_html": tuktuk_paint_html
	}
	return _atomic_write(SETTINGS_PATH, JSON.stringify(d))

func reset_settings() -> void:
	muted = false
	volume = 1.0
	camera_sensitivity = 1.0
	hud_scale = 1.0
	joystick_deadzone = 0.15
	car_paint_html = "#1F73C7"
	motorcycle_paint_html = "#D9261A"
	tuktuk_paint_html = "#F2B81A"
	save_settings()