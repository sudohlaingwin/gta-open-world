extends Node
## Slice 21 save foundation: versioned JSON saves + persistent settings.
## Save file user://savegame.json holds gameplay progress (position,
## quest stage, talked villagers by name, stamina, reward flags,
## counters, crop growth, and a settings snapshot for reference).
## Settings file user://settings.json holds mute + volume + the player
## outfit (shirt/longyi colours as HTML strings, hat on/off) + the
## Slice 32 control settings (camera sensitivity, HUD scale,
## joystick deadzone), and is
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
## Slice 158 full-settings round: sfx_volume scales UI/effect
## sounds only (HUD clicks, horn, bus chime) on top of master
## volume; vibration_enabled gates S157 haptics; camera_invert_y
## flips free-look pitch drag. All three persist like every other
## setting, default to exactly the pre-158 behaviour (volumes 1.0
## = 0 dB offset, vibration on, invert off), so an old settings
## file loads as before.
var sfx_volume: float = 1.0
var vibration_enabled: bool = true
var camera_invert_y: bool = false
## Slice 160 Custom Controls: per-control centre fractions
## (key -> {"x": float, "y": float}) from the layout editor.
## Empty = exactly the S157 defaults. Horn buttons share the
## "HornSlot160" entry, context buttons "ContextSlot160".
## Entries are validated on load (numeric x/y, clamped 0-1) so
## a hand-edited file can never strand a button off-screen.
var custom_controls: Dictionary = {}
## Slice 30 outfit: defaults are the scene's own colours (off-white
## taikpon, dark-green longyi, hat on), so a missing settings file
## looks exactly like the pre-customization player.
var shirt_color_html: String = "#F5F0E6"
var longyi_color_html: String = "#145938"
var hat_visible: bool = true
## Slice 35 vehicle paints: defaults are the scene's own body colours
## (car red, motorcycle teal, tuk-tuk blue), so a missing settings
## file looks exactly like the pre-customization vehicles. Paints are
## colours of the existing body meshes only, applied at world spawn.
var car_paint_html: String = "#D91A26"
var motorcycle_paint_html: String = "#1A8C99"
var tuktuk_paint_html: String = "#1A66CC"
## Slice 32 control settings. camera_sensitivity scales touch-drag
## orbit speed (1.0 = Slice 24 behaviour); hud_scale scales every
## touch HUD control around its own centre (1.0 = current layout);
## joystick_deadzone is the joystick deadzone fraction shared by
## player movement AND all vehicle steering, because every vehicle
## reads the player's touch_vector, which the joystick already
## deadzone-filters. Ranges are enforced on load so a hand-edited
## settings file can never produce an unusable HUD (tiny buttons)
## or a dead joystick (deadzone >= 1.0).
var camera_sensitivity: float = 1.0
var hud_scale: float = 1.0
var joystick_deadzone: float = 0.15
## Audit item 4 graphics quality: 0 = High (the look every slice so
## far shipped: sun shadows on, full 3D resolution), 1 = Low (sun
## shadows off, 3D render scale 0.75 with bilinear upscaling — the
## two levers that actually exist in this project; it has no
## WorldEnvironment, so there is no glow/bloom lever to offer).
## Slice 68 graphics tiers supersede this flag: graphics_tier
## 0 = Low, 1 = Balanced, 2 = High, 3 = Ultra (default High, the
## pre-68 look). graphics_quality is kept as a mirror (0 when
## tier >= 2, else 1) so old files and old readers keep working:
## a pre-68 file (quality 0) loads as tier High, (quality 1) as
## tier Low. fps_visible toggles the measured-FPS overlay (default
## ON since Slice 120, so the owner can report real phone FPS
## numbers without hunting for the toggle; Settings still turns
## it off, and an existing save file keeps its stored value).
var graphics_quality: int = 0
var graphics_tier: int = 2
var fps_visible: bool = true
## Slice 55 driving-assistance modes (audit item 9): 0 = Arcade
## (more forgiving), 1 = Balanced (the default, and exactly the
## Slice 26/31/33 polished physics — no tuning change at all),
## 2 = Realistic (stricter). The mode only scales the road
## vehicles' brake, coast, steering response, high-speed turn
## rate and turn scrub (see car.gd / motorcycle.gd / tuktuk.gd);
## top speed, acceleration curve and reverse caps are identical
## in all three modes, so a mode is assistance, not an engine
## upgrade. A settings file written before Slice 55 has no key
## and loads as Balanced, so old behaviour is preserved exactly.
var driving_mode: int = 1
## Slice 81 fleet paint: 0 yellow (the Slice 74 bus colour),
## 1 red, 2 blue, 3 green — one livery for both buses.
var bus_paint81: int = 0
## Slice 62 seasons: 0 summer နွေ (dry/golden), 1 rainy မိုး (rain),
## 2 winter ဆောင်း (cool/clear). Default summer; old settings files
## without the key load as summer, so old behaviour is preserved.
var season62: int = 0
## Slice 99 season clock: seconds accumulated toward the
## next automatic season change (3600 s = 1 hour of play).
## Old settings files without the key load as 0.0, so the
## current season is never disturbed by the migration.
var season62_play_s: float = 0.0


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


## Audit fix (Phase 1): atomic writes. save_game/save_settings used to
## open the live file for WRITE and stream JSON into it, so a kill,
## crash, or power loss mid-write left a truncated file behind — and
## load_save/load_settings treat truncated JSON as "no save", which
## silently destroyed ALL progress (reproduced headlessly: a save
## truncated to half its bytes loads as {}). Writing to a temp file
## in the same directory and renaming over the live file closes that
## window: rename is atomic, so the live file is always either the
## complete old save or the complete new save, never a half-write.
## This prevents FUTURE corruption from interrupted saves; it does
## not recover a file that is already truncated.
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


func save_game(data: Dictionary) -> bool:
	var copy = data.duplicate(true)
	copy["version"] = SAVE_VERSION
	return _atomic_write(save_path, JSON.stringify(copy))


func load_settings() -> void:
	muted = false
	volume = 1.0
	sfx_volume = 1.0
	vibration_enabled = true
	camera_invert_y = false
	custom_controls = {}
	shirt_color_html = "#F5F0E6"
	longyi_color_html = "#145938"
	hat_visible = true
	car_paint_html = "#D91A26"
	motorcycle_paint_html = "#1A8C99"
	tuktuk_paint_html = "#1A66CC"
	camera_sensitivity = 1.0
	hud_scale = 1.0
	joystick_deadzone = 0.15
	graphics_quality = 0
	graphics_tier = 2
	fps_visible = true
	driving_mode = 1
	season62 = 0
	season62_play_s = 0.0
	bus_paint81 = 0
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
	if parsed.has("sfx_volume"):
		sfx_volume = clampf(float(parsed.get("sfx_volume")), 0.0, 1.0)
	if parsed.has("vibration_enabled"):
		vibration_enabled = bool(parsed.get("vibration_enabled"))
	if parsed.has("camera_invert_y"):
		camera_invert_y = bool(parsed.get("camera_invert_y"))
	if parsed.has("custom_controls"):
		var cc = parsed.get("custom_controls")
		if cc is Dictionary:
			var clean: Dictionary = {}
			for k in (cc as Dictionary).keys():
				var e = (cc as Dictionary)[k]
				if e is Dictionary and (e as Dictionary).has("x") and (e as Dictionary).has("y"):
					var ex = float((e as Dictionary)["x"])
					var ey = float((e as Dictionary)["y"])
					if ex == ex and ey == ey:
						clean[str(k)] = {"x": clampf(ex, 0.0, 1.0), "y": clampf(ey, 0.0, 1.0)}
			custom_controls = clean
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
	if parsed.has("car_paint_html"):
		var cp = str(parsed.get("car_paint_html"))
		if Color.html_is_valid(cp):
			car_paint_html = cp
	if parsed.has("motorcycle_paint_html"):
		var mp = str(parsed.get("motorcycle_paint_html"))
		if Color.html_is_valid(mp):
			motorcycle_paint_html = mp
	if parsed.has("tuktuk_paint_html"):
		var tp = str(parsed.get("tuktuk_paint_html"))
		if Color.html_is_valid(tp):
			tuktuk_paint_html = tp
	if parsed.has("camera_sensitivity"):
		camera_sensitivity = clampf(float(parsed.get("camera_sensitivity")), 0.5, 2.0)
	if parsed.has("hud_scale"):
		hud_scale = clampf(float(parsed.get("hud_scale")), 0.8, 1.25)
	if parsed.has("joystick_deadzone"):
		joystick_deadzone = clampf(float(parsed.get("joystick_deadzone")), 0.0, 0.4)
	if parsed.has("graphics_quality"):
		graphics_quality = clampi(int(parsed.get("graphics_quality")), 0, 1)
	if parsed.has("graphics_tier"):
		graphics_tier = clampi(int(parsed.get("graphics_tier")), 0, 3)
		graphics_quality = 0 if graphics_tier >= 2 else 1
	else:
		graphics_tier = 2 if graphics_quality == 0 else 0
	if parsed.has("fps_visible"):
		fps_visible = bool(parsed.get("fps_visible"))
	if parsed.has("driving_mode"):
		driving_mode = clampi(int(parsed.get("driving_mode")), 0, 2)
	if parsed.has("season62"):
		season62 = clampi(int(parsed.get("season62")), 0, 2)
	if parsed.has("season62_play_s"):
		season62_play_s = clampf(float(parsed.get("season62_play_s")), 0.0, 3600.0)
	if parsed.has("bus_paint81"):
		bus_paint81 = clampi(int(parsed.get("bus_paint81")), 0, 3)


func save_settings() -> bool:
	var data = {"muted": muted, "volume": volume,
		"sfx_volume": sfx_volume,
		"vibration_enabled": vibration_enabled,
		"camera_invert_y": camera_invert_y,
		"custom_controls": custom_controls,
		"shirt_color_html": shirt_color_html,
		"longyi_color_html": longyi_color_html,
		"hat_visible": hat_visible,
		"car_paint_html": car_paint_html,
		"motorcycle_paint_html": motorcycle_paint_html,
		"tuktuk_paint_html": tuktuk_paint_html,
		"camera_sensitivity": camera_sensitivity,
		"hud_scale": hud_scale,
		"joystick_deadzone": joystick_deadzone,
		"graphics_quality": graphics_quality,
		"graphics_tier": graphics_tier,
		"fps_visible": fps_visible,
		"driving_mode": driving_mode,
		"season62": season62,
		"season62_play_s": season62_play_s,
		"bus_paint81": bus_paint81}
	return _atomic_write(settings_path, JSON.stringify(data))


func reset_settings() -> void:
	muted = false
	volume = 1.0
	sfx_volume = 1.0
	vibration_enabled = true
	camera_invert_y = false
	custom_controls = {}
	shirt_color_html = "#F5F0E6"
	longyi_color_html = "#145938"
	hat_visible = true
	car_paint_html = "#D91A26"
	motorcycle_paint_html = "#1A8C99"
	tuktuk_paint_html = "#1A66CC"
	camera_sensitivity = 1.0
	hud_scale = 1.0
	joystick_deadzone = 0.15
	graphics_quality = 0
	graphics_tier = 2
	fps_visible = true
	driving_mode = 1
	season62 = 0
	season62_play_s = 0.0
	bus_paint81 = 0
	save_settings()


func volume_db() -> float:
	if volume <= 0.001:
		return -80.0
	return linear_to_db(volume)


## Slice 158: dB OFFSETS for the live audio paths (0.0 at 1.0, so
## defaults sound exactly as before). Master scales everything;
## SFX scales effect sounds on top of master. Absolute volume_db()
## above is kept for the world tone player, which already uses it.
func volume_offset_db() -> float:
	if volume <= 0.001:
		return -80.0
	return linear_to_db(volume)


func sfx_offset_db() -> float:
	if sfx_volume <= 0.001:
		return -80.0
	return linear_to_db(sfx_volume)
