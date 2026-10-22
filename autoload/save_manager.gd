extends Node
## Slice 21 save foundation: versioned JSON saves + persistent settings.
## Save file user://savegame.json holds gameplay progress (position,
## quest stage, talked villagers by name, stamina, reward flags,
## counters, crop growth, and a settings snapshot for reference).
## Settings file user://settings.json holds mute + volume + the player
## outfit (shirt/longyi colours as HTML strings, hat on/off), and is
## the authority for settings at boot, in the Settings screen, and in
## the Character screen. Old settings files without the outfit keys
## load the default outfit, so a Slice 29 settings file keeps working.
## Missing, corrupt, or wrong-version files load as "no save" — the
## game always falls back to a fresh start, never a crash.
## Talked villagers are saved by node NAME, not instance id, because
## instance ids change every run and would be meaningless on load.

const SAVE_VERSION: int = 1
const DEFAULT_SAVE_PATH: String = "user://savegame.json"
const DEFAULT_SETTINGS_PATH: String = "user://settings.json"

var save_path: String = DEFAULT_SAVE_PATH
var settings_path: String = DEFAULT_SETTINGS_PATH
var pending_load: Dictionary = {}
var muted: bool = false
var volume: float = 1.0
## Slice 30 outfit: defaults are the scene's own colours (off-white
## taikpon, dark-green longyi, hat on), so a missing settings file
## looks exactly like the pre-customization player.
var shirt_color_html: String = "#F5F0E6"
var longyi_color_html: String = "#145938"
var hat_visible: bool = true


func _ready() -> void:
	load_settings()


func has_valid_save() -> bool:
	return not load_save().is_empty()


func load_save() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var text = file.get_buffer(file.get_length()).get_string_from_utf8()
	file.close()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	if int(parsed.get("version", 0)) != SAVE_VERSION:
		return {}
	if not parsed.has("quest_stage"):
		return {}
	if not parsed.has("player"):
		return {}
	return parsed


func save_game(data: Dictionary) -> bool:
	var copy = data.duplicate(true)
	copy["version"] = SAVE_VERSION
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(copy))
	file.close()
	return true


func load_settings() -> void:
	muted = false
	volume = 1.0
	shirt_color_html = "#F5F0E6"
	longyi_color_html = "#145938"
	hat_visible = true
	if not FileAccess.file_exists(settings_path):
		return
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return
	var text = file.get_buffer(file.get_length()).get_string_from_utf8()
	file.close()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return
	if parsed.has("muted"):
		muted = bool(parsed.get("muted"))
	if parsed.has("volume"):
		volume = clampf(float(parsed.get("volume")), 0.0, 1.0)
	if parsed.has("shirt_color_html"):
		var sh = str(parsed.get("shirt_color_html"))
		if Color.html_is_valid(sh):
			shirt_color_html = sh
	if parsed.has("longyi_color_html"):
		var lo = str(parsed.get("longyi_color_html"))
		if Color.html_is_valid(lo):
			longyi_color_html = lo
	if parsed.has("hat_visible"):
		hat_visible = bool(parsed.get("hat_visible"))


func save_settings() -> bool:
	var data = {"muted": muted, "volume": volume,
		"shirt_color_html": shirt_color_html,
		"longyi_color_html": longyi_color_html,
		"hat_visible": hat_visible}
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


func reset_settings() -> void:
	muted = false
	volume = 1.0
	shirt_color_html = "#F5F0E6"
	longyi_color_html = "#145938"
	hat_visible = true
	save_settings()


func volume_db() -> float:
	if volume <= 0.001:
		return -80.0
	return linear_to_db(volume)
