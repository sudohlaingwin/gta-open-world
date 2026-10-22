extends Node
## Slice 65 — continuous engine audio, coupled to live driving.
## The Muse game had only one-shot chime tones (player.gd _play_tone);
## nothing sounded while driving. This node owns ONE looping 1.0 s
## generated buffer (fundamental + harmonics, whole sine cycles so
## the loop joins silently) and varies AudioStreamPlayer.pitch_scale
## and volume_db EVERY tick from live speed. Pitch therefore changes
## continuously — there is no 0.35-0.6 s clip boundary where pitch
## can only update, and idle/coast/brake all sound (quieter), not
## throttle-only. Mute (SaveManager "muted" or the player's sound_on)
## stops the player outright. Lightweight for mobile: one buffer,
## generated once, no per-frame allocations.

const BASE_FREQ := 70.0
const BUFFER_HZ := 22050
const BUFFER_SEC := 1.0
const VEHICLE_BASE := {"Car": 65.0, "Motorcycle": 95.0, "TukTuk": 55.0}

var _player: AudioStreamPlayer = null
var current_pitch: float = 1.0
var current_db: float = -20.0
var current_vehicle: String = ""

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "EngineAudio65"
	add_child(_player)
	_player.stream = _make_loop()
	_player.volume_db = -20.0
	_player.pitch_scale = 1.0

func _make_loop() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = BUFFER_HZ
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var frames := int(BUFFER_HZ * BUFFER_SEC)
	wav.loop_begin = 0
	wav.loop_end = frames
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(BUFFER_HZ)
		# 70 + 140 + 280 Hz: exactly 70/140/280 full cycles in 1.0 s,
		# so the buffer starts and ends at a zero crossing (no click).
		var v := sin(t * BASE_FREQ * TAU) * 0.65 + sin(t * BASE_FREQ * 2.0 * TAU) * 0.25 + sin(t * BASE_FREQ * 4.0 * TAU) * 0.1
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 24000.0))
	wav.data = data
	return wav

## The single coupling point, used both by _process (live driving)
## and by the world sim (which calls it directly with fake values
## and asserts pitch/volume actually move with speed).
func tick_for(vehicle_name: String, speed: float, max_speed: float, muted: bool) -> void:
	if muted or vehicle_name == "" or max_speed <= 0.0:
		current_vehicle = ""
		if _player != null and _player.playing:
			_player.stop()
		return
	var base := float(VEHICLE_BASE.get(vehicle_name, 65.0))
	var ratio := clampf(absf(speed) / max_speed, 0.0, 1.0)
	# Idle sits at the vehicle's base pitch; pitch doubles by top
	# speed. Volume rises with speed, so idle/coast/brake stay
	# audible but quiet instead of silent.
	current_pitch = (base / BASE_FREQ) * (1.0 + ratio)
	current_db = lerpf(-20.0, -7.0, ratio)
	current_vehicle = vehicle_name
	if _player == null:
		return
	_player.pitch_scale = current_pitch
	_player.volume_db = current_db
	if not _player.playing:
		_player.play()

func _process(_delta: float) -> void:
	var p := get_parent()
	if p == null:
		tick_for("", 0.0, 0.0, true)
		return
	var muted := false
	if p.get("sound_on") != null:
		muted = not bool(p.get("sound_on"))
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.get("muted") != null and bool(sm.get("muted")):
		muted = true
	if p.get("driving") == null or not bool(p.get("driving")):
		tick_for("", 0.0, 0.0, muted)
		return
	var veh = p.get("driving_vehicle")
	if veh == null:
		tick_for("", 0.0, 0.0, muted)
		return
	var nm := str(veh.name)
	if not VEHICLE_BASE.has(nm):
		tick_for("", 0.0, 0.0, muted)
		return
	var spd := 0.0
	var mx := 0.0
	if veh.get("speed") != null:
		spd = absf(float(veh.get("speed")))
	if veh.get("max_speed") != null:
		mx = float(veh.get("max_speed"))
	tick_for(nm, spd, mx, muted)
