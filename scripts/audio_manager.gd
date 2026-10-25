extends Node

# --- Authentic Myanmar Ambient & Sound Effects Generator ---
# Procedural Synthesized Audio Streams for Mobile Performance

var monastery_bell_player: AudioStreamPlayer
var cow_moo_player: AudioStreamPlayer
var vehicle_engine_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var teashop_chime_player: AudioStreamPlayer
var river_stream_player: AudioStreamPlayer
var birds_stream_player: AudioStreamPlayer
var bgm_music_player: AudioStreamPlayer
var bird_ambient_timer: float = 3.0
var river_ambient_timer: float = 1.0
var radio_station_index: int = 1
var cart_bell_player: AudioStreamPlayer = null
var cart_bell_timer: float = 0.0
var is_muted: bool = false
var horn_player: AudioStreamPlayer = null
var skid_player: AudioStreamPlayer = null
var wind_rush_player: AudioStreamPlayer = null
var radio_tuning_player: AudioStreamPlayer = null
var throttle_pedal_player: AudioStreamPlayer = null
var brake_pedal_player: AudioStreamPlayer = null
var sima_chant_player: AudioStreamPlayer = null
var deep_gong_player: AudioStreamPlayer = null
var door_lock_player: AudioStreamPlayer = null
var door_latch_player: AudioStreamPlayer = null
var banyan_wind_player: AudioStreamPlayer = null
var nat_chime_player: AudioStreamPlayer = null
var armrest_player: AudioStreamPlayer = null
var palm_leaf_player: AudioStreamPlayer = null
var temple_chime_player: AudioStreamPlayer = null
var fog_switch_player: AudioStreamPlayer = null

const RADIO_STATIONS: Array[String] = [
	"📻 ရေဒီယို: ပိတ်ထားသည် (Off)",
	"📻 ရေဒီယို: မြန်မာအကူးစတစ်နှင့် ပလွေ (Acoustic & Flute)",
	"📻 ရေဒီယို: သဘာဝတောတောင်နှင့် လေညင်း (Mountain Wind)",
	"📻 ရေဒီယို: ရိုးရာစောင်းနှင့် အေးချမ်းသံ (Harp & Chimes)",
	"📻 ရေဒီယို: မန္တလေး FM ပေါ့ပ်ဂစ်တာ (Mandalay Pop FM 98.5 MHz)"
]

func cycle_radio_station() -> String:
	play_radio_tuning_fx()
	radio_station_index = (radio_station_index + 1) % RADIO_STATIONS.size()
	_apply_radio_station()
	return RADIO_STATIONS[radio_station_index]

func play_radio_tuning_fx() -> void:
	if is_muted:
		return
	if not radio_tuning_player:
		radio_tuning_player = AudioStreamPlayer.new()
		radio_tuning_player.name = "RadioTuningAudio"
		add_child(radio_tuning_player)

	var sample_hz = 22050
	var duration = 0.32
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)

	var rng_seed = 12345
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		rng_seed = (rng_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var white_noise = (float(rng_seed) / 1073741824.0) - 1.0

		var sweep_freq = lerpf(750.0, 2200.0, t / duration)
		var whistle = sin(t * sweep_freq * TAU) * 0.28
		var click = exp(-t * 22.0) * 0.65

		var env = sin((t / duration) * PI)
		var val = (white_noise * 0.45 + whistle + click) * env
		var int_sample = int(clamp(val, -1.0, 1.0) * 19000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	radio_tuning_player.stream = stream
	radio_tuning_player.volume_db = -6.0
	radio_tuning_player.play()

func get_current_radio_station_name() -> String:
	return RADIO_STATIONS[radio_station_index]

func _apply_radio_station() -> void:
	if not bgm_music_player:
		return
	match radio_station_index:
		0:
			bgm_music_player.stop()
		1:
			_synthesize_acoustic_flute_song()
		2:
			_synthesize_nature_ambience_loop()
		3:
			_synthesize_myanmar_harp_song()
		4:
			_synthesize_mandalay_pop_song()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("audio_manager")
	_setup_audio_players()
	_start_background_music()

func _start_background_music() -> void:
	if not bgm_music_player:
		bgm_music_player = AudioStreamPlayer.new()
		bgm_music_player.name = "BackgroundMusicAudio"
		add_child(bgm_music_player)

	var sm = get_node_or_null("/root/SaveManager")
	var m_vol = 0.8
	if sm and sm.get("music_volume") != null:
		m_vol = float(sm.music_volume)
	if sm and sm.get("muted"):
		m_vol = 0.0

	bgm_music_player.volume_db = linear_to_db(clampf(m_vol * 0.45, 0.0001, 1.0))
	_synthesize_acoustic_flute_song()

func _synthesize_myanmar_harp_song() -> void:
	# Generates a serene pentatonic Myanmar Saung-gauk (စောင်းကောက်) harp melody loop
	var sample_hz = 22050
	var duration = 12.0 # 12-second peaceful pentatonic loop
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_frames

	var data = PackedByteArray()
	data.resize(total_frames * 2)

	# Burmese Classical Pentatonic scale frequencies: C4, D4, F4, G4, A4, C5
	var scale = [261.63, 293.66, 349.23, 392.00, 440.00, 523.25]
	var notes = [
		{"t": 0.0, "f": 261.63, "dur": 1.4},
		{"t": 1.5, "f": 349.23, "dur": 1.2},
		{"t": 3.0, "f": 392.00, "dur": 1.5},
		{"t": 4.5, "f": 440.00, "dur": 1.8},
		{"t": 6.0, "f": 392.00, "dur": 1.4},
		{"t": 7.5, "f": 349.23, "dur": 1.2},
		{"t": 9.0, "f": 293.66, "dur": 1.4},
		{"t": 10.5, "f": 261.63, "dur": 1.5}
	]

	for i in range(total_frames):
		var cur_t = float(i) / float(sample_hz)
		var total_sample = 0.0
		for n in notes:
			var note_start = n["t"]
			var note_dur = n["dur"]
			if cur_t >= note_start and cur_t < (note_start + note_dur):
				var nt = cur_t - note_start
				var env = exp(-nt * 3.2)
				var f = n["f"]
				# Authentic warm harp pluck harmonics
				var pluck = sin(nt * f * TAU) * 0.7 + sin(nt * f * 2.0 * TAU) * 0.22 + sin(nt * f * 3.0 * TAU) * 0.08
				total_sample += pluck * env * 0.45
		var int_sample = int(clamp(total_sample, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	bgm_music_player.stream = stream
	bgm_music_player.play()

func _synthesize_mandalay_pop_song() -> void:
	# Upbeat 120 BPM Myanmar Radio Pop with rhythmic guitar chords & patala xylophone shimmer
	var sample_hz = 22050
	var duration = 10.0
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_frames

	var data = PackedByteArray()
	data.resize(total_frames * 2)

	var bpm = 120.0
	var beat_sec = 60.0 / bpm

	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var beat_progress = fmod(t, beat_sec) / beat_sec
		var bar_num = int(t / (beat_sec * 4.0)) % 4

		var root_f = 196.0 # G
		if bar_num == 1: root_f = 164.8 # Em
		elif bar_num == 2: root_f = 130.8 # C
		elif bar_num == 3: root_f = 146.8 # D

		var strum_env = exp(-beat_progress * 5.5)
		var chord = (sin(t * root_f * TAU) * 0.45 + sin(t * root_f * 1.25 * TAU) * 0.35 + sin(t * root_f * 1.5 * TAU) * 0.3) * strum_env

		var melody_step = int(t / (beat_sec * 0.5)) % 8
		var patala_f = root_f * 4.0
		if melody_step == 1: patala_f *= 1.125
		elif melody_step == 3: patala_f *= 1.25
		elif melody_step == 5: patala_f *= 1.5
		elif melody_step == 7: patala_f *= 1.667

		var sub_beat = fmod(t, beat_sec * 0.5) / (beat_sec * 0.5)
		var patala_env = exp(-sub_beat * 8.0)
		var patala = sin(t * patala_f * TAU) * patala_env * 0.22
		var bass = sin(t * (root_f * 0.5) * TAU) * (0.3 + 0.2 * strum_env)

		var total_sample = (chord * 0.5 + patala + bass * 0.4)
		var int_sample = int(clamp(total_sample, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	bgm_music_player.stream = stream
	bgm_music_player.play()


func _process(delta: float) -> void:
	if is_muted:
		return
	# Ambient tropical birds singing across the countryside
	bird_ambient_timer -= delta
	if bird_ambient_timer <= 0.0:
		bird_ambient_timer = randf_range(8.0, 16.0)
		play_tropical_birds()

	# Ambient river flowing sound near Mindon stream or village river
	river_ambient_timer -= delta
	if river_ambient_timer <= 0.0:
		river_ambient_timer = 2.2
		var player = get_tree().get_first_node_in_group("player")
		if player:
			# If player is near the river (Z around 20-35 or river coordinates)
			var dist_to_river = absf(player.global_position.z - 28.0)
			if dist_to_river < 95.0:
				play_river_flow()

func _setup_audio_players() -> void:
	# 1. Monastery Bell Player
	monastery_bell_player = AudioStreamPlayer.new()
	monastery_bell_player.name = "MonasteryBellAudio"
	monastery_bell_player.volume_db = 2.0
	add_child(monastery_bell_player)

	# 2. Cow Moo Player
	cow_moo_player = AudioStreamPlayer.new()
	cow_moo_player.name = "CowMooAudio"
	cow_moo_player.volume_db = -2.0
	add_child(cow_moo_player)

	# 3. Vehicle Engine Player
	vehicle_engine_player = AudioStreamPlayer.new()
	vehicle_engine_player.name = "VehicleEngineAudio"
	vehicle_engine_player.volume_db = -6.0
	add_child(vehicle_engine_player)

	# 4. Footstep Player
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepAudio"
	footstep_player.volume_db = -8.0
	add_child(footstep_player)

	# 5. Tea Shop Chime
	teashop_chime_player = AudioStreamPlayer.new()
	teashop_chime_player.name = "TeaShopChimeAudio"
	teashop_chime_player.volume_db = 0.0
	add_child(teashop_chime_player)

	# 6. River Water Audio Player
	river_stream_player = AudioStreamPlayer.new()
	river_stream_player.name = "RiverWaterAudio"
	river_stream_player.volume_db = -10.0
	add_child(river_stream_player)

	# 7. Tropical Birds Audio Player
	birds_stream_player = AudioStreamPlayer.new()
	birds_stream_player.name = "TropicalBirdsAudio"
	birds_stream_player.volume_db = -8.0
	add_child(birds_stream_player)

func play_bell_strike() -> void:
	# Generates deep monastery bronze bell resonance
	var sample_hz = 22050
	var duration = 2.5
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	var freq1 = 216.0 # Sacred Kyone bell fundamental
	var freq2 = 432.0 # Golden overtone
	
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var decay = exp(-t * 2.2)
		var sample_val = (sin(t * freq1 * TAU) * 0.7 + sin(t * freq2 * TAU) * 0.3) * decay
		var int_sample = int(clamp(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
		
	stream.data = data
	monastery_bell_player.stream = stream
	monastery_bell_player.play()

func play_cow_moo() -> void:
	# Generates organic low-pitch cattle vocalization
	var sample_hz = 22050
	var duration = 1.2
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var pitch = 110.0 + sin(t * 4.0) * 15.0 # Gentle frequency modulation
		var env = sin(clamp(t / duration, 0.0, 1.0) * PI)
		var sample_val = sin(t * pitch * TAU) * env * 0.8
		var int_sample = int(clamp(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
		
	stream.data = data
	cow_moo_player.stream = stream
	cow_moo_player.play()

func play_teashop_chime() -> void:
	# Generates bright bell chime when ordering tea
	var sample_hz = 22050
	var duration = 0.8
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = exp(-t * 5.0)
		var sample_val = (sin(t * 880.0 * TAU) * 0.6 + sin(t * 1760.0 * TAU) * 0.4) * env
		var int_sample = int(clamp(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
		
	stream.data = data
	teashop_chime_player.stream = stream
	teashop_chime_player.play()

func play_car_engine(speed_ratio: float = 0.0) -> void:
	if is_muted: return
	if not vehicle_engine_player:
		vehicle_engine_player = AudioStreamPlayer.new()
		vehicle_engine_player.name = "VehicleEngineAudio"
		vehicle_engine_player.volume_db = -6.0
		add_child(vehicle_engine_player)
	if vehicle_engine_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.35
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	# Deep 4-cylinder sedan engine rumble with RPM pitch modulation
	var base_freq = 42.0 + clampf(speed_ratio, 0.0, 1.2) * 88.0
	var fade_frames = mini(128, total_frames / 4)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var rumble = sin(t * base_freq * TAU) * 0.55 + sin(t * base_freq * 2.0 * TAU) * 0.3 + sin(t * base_freq * 4.0 * TAU) * 0.15
		var env = 1.0
		if i < fade_frames:
			env = 0.5 * (1.0 - cos(float(i) / float(fade_frames) * PI))
		elif i > total_frames - fade_frames:
			env = 0.5 * (1.0 - cos(float(total_frames - i) / float(fade_frames) * PI))
		var int_sample = int(clamp(rumble * env, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	vehicle_engine_player.stream = stream
	vehicle_engine_player.play()

func play_motorcycle_engine(speed_ratio: float = 0.0) -> void:
	if is_muted: return
	if not vehicle_engine_player:
		vehicle_engine_player = AudioStreamPlayer.new()
		vehicle_engine_player.name = "VehicleEngineAudio"
		vehicle_engine_player.volume_db = -6.0
		add_child(vehicle_engine_player)
	if vehicle_engine_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.35
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	# High-rev single-cylinder Kenbo 125cc engine roar
	var base_freq = 65.0 + clampf(speed_ratio, 0.0, 1.2) * 110.0
	var fade_frames = mini(128, total_frames / 4)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var pop = sin(t * base_freq * TAU) * 0.6 + sin(t * base_freq * 2.0 * TAU) * 0.3 + sin(t * base_freq * 4.0 * TAU) * 0.1
		var env = 1.0
		if i < fade_frames:
			env = 0.5 * (1.0 - cos(float(i) / float(fade_frames) * PI))
		elif i > total_frames - fade_frames:
			env = 0.5 * (1.0 - cos(float(total_frames - i) / float(fade_frames) * PI))
		var int_sample = int(clamp(pop * env, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	vehicle_engine_player.stream = stream
	vehicle_engine_player.play()

func play_tuktuk_engine(speed_ratio: float = 0.0) -> void:
	if is_muted: return
	if not vehicle_engine_player:
		vehicle_engine_player = AudioStreamPlayer.new()
		vehicle_engine_player.name = "VehicleEngineAudio"
		vehicle_engine_player.volume_db = -6.0
		add_child(vehicle_engine_player)
	if vehicle_engine_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.4
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	# Characteristic 2-stroke / 4-stroke thumping Tuk-Tuk engine
	var base_freq = 48.0 + clampf(speed_ratio, 0.0, 1.2) * 75.0
	var fade_frames = mini(128, total_frames / 4)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var thump = sin(t * base_freq * TAU) * 0.7 + sin(t * base_freq * 1.5 * TAU) * 0.2 + sin(t * base_freq * 3.0 * TAU) * 0.1
		var env = 1.0
		if i < fade_frames:
			env = 0.5 * (1.0 - cos(float(i) / float(fade_frames) * PI))
		elif i > total_frames - fade_frames:
			env = 0.5 * (1.0 - cos(float(total_frames - i) / float(fade_frames) * PI))
		var int_sample = int(clamp(thump * env, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	vehicle_engine_player.stream = stream
	vehicle_engine_player.play()

func play_footstep() -> void:
	if is_muted: return
	if not footstep_player:
		footstep_player = AudioStreamPlayer.new()
		footstep_player.name = "FootstepAudio"
		footstep_player.volume_db = -10.0
		add_child(footstep_player)
	var sample_hz = 22050
	var duration = 0.12
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = exp(-t * 35.0)
		var crunch = (sin(t * 180.0 * TAU) * 0.5 + sin(t * 360.0 * TAU) * 0.3 + sin(t * 720.0 * TAU) * 0.2)
		var val = crunch * env
		var int_sample = int(clamp(val, -1.0, 1.0) * 24000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	footstep_player.stream = stream
	footstep_player.play()

var is_muted: bool = false
var horn_player: AudioStreamPlayer
var bicycle_bell_player: AudioStreamPlayer
var elephant_trumpet_player: AudioStreamPlayer

func toggle_mute() -> bool:
	is_muted = not is_muted
	AudioServer.set_bus_mute(0, is_muted)
	return is_muted

func play_horn() -> void:
	if is_muted: return
	if not horn_player:
		horn_player = AudioStreamPlayer.new()
		add_child(horn_player)
	var sample_hz = 22050
	var duration = 0.4
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var val = (sin(t * 220.0 * TAU) * 0.7 + sin(t * 440.0 * TAU) * 0.3)
		var int_sample = int(clamp(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	horn_player.stream = stream
	horn_player.play()

func play_bicycle_bell() -> void:
	if is_muted: return
	if not bicycle_bell_player:
		bicycle_bell_player = AudioStreamPlayer.new()
		add_child(bicycle_bell_player)
	var sample_hz = 22050
	var duration = 0.35
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = exp(-t * 9.0)
		var val = sin(t * 880.0 * TAU) * env
		var int_sample = int(clamp(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	bicycle_bell_player.stream = stream
	bicycle_bell_player.play()

var horse_gallop_player: AudioStreamPlayer

func play_horse_gallop(speed_ratio: float = 0.0) -> void:
	if is_muted: return
	if not horse_gallop_player:
		horse_gallop_player = AudioStreamPlayer.new()
		horse_gallop_player.name = "HorseGallopAudio"
		horse_gallop_player.volume_db = -8.0
		add_child(horse_gallop_player)
	if horse_gallop_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.28
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	# Rhythmic double-strike hoof beat on soil/turf
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env1 = exp(-t * 28.0)
		var env2 = exp(-maxf(t - 0.12, 0.0) * 32.0) if t > 0.12 else 0.0
		var thump1 = (sin(t * 95.0 * TAU) * 0.7 + sin(t * 190.0 * TAU) * 0.3) * env1
		var thump2 = (sin(t * 110.0 * TAU) * 0.6 + sin(t * 220.0 * TAU) * 0.4) * env2
		var int_sample = int(clamp(thump1 + thump2, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	horse_gallop_player.stream = stream
	horse_gallop_player.play()

func play_elephant_trumpet() -> void:
	if is_muted: return
	if not elephant_trumpet_player:
		elephant_trumpet_player = AudioStreamPlayer.new()
		add_child(elephant_trumpet_player)
	var sample_hz = 22050
	var duration = 0.9
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var pitch = 380.0 + sin(t * 12.0) * 45.0
		var env = sin(clamp(t / duration, 0.0, 1.0) * PI)
		var val = sin(t * pitch * TAU) * env
		var int_sample = int(clamp(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	elephant_trumpet_player.stream = stream
	elephant_trumpet_player.play()

var elephant_footstep_player: AudioStreamPlayer

func play_elephant_footstep() -> void:
	if is_muted: return
	if not elephant_footstep_player:
		elephant_footstep_player = AudioStreamPlayer.new()
		elephant_footstep_player.name = "ElephantFootstepAudio"
		elephant_footstep_player.volume_db = -6.0
		add_child(elephant_footstep_player)
	if elephant_footstep_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.38
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	# Heavy sub-bass ground impact thud (48Hz fundamental)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = exp(-t * 14.0)
		var thud = (sin(t * 48.0 * TAU) * 0.7 + sin(t * 96.0 * TAU) * 0.3) * env
		var int_sample = int(clamp(thud, -1.0, 1.0) * 26000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	elephant_footstep_player.stream = stream
	elephant_footstep_player.play()

func play_river_flow() -> void:
	if is_muted: return
	if not river_stream_player:
		river_stream_player = AudioStreamPlayer.new()
		river_stream_player.name = "RiverWaterAudio"
		river_stream_player.volume_db = -10.0
		add_child(river_stream_player)
	var sample_hz = 22050
	var duration = 2.0
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var brown_noise = (sin(t * 130.0 * TAU) * 0.4 + sin(t * 220.0 * TAU) * 0.3 + sin(t * 310.0 * TAU) * 0.3)
		var val = brown_noise * (0.8 + 0.2 * sin(t * 3.5))
		var int_sample = int(clamp(val, -1.0, 1.0) * 16383.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	river_stream_player.stream = stream
	river_stream_player.play()

func play_tropical_birds() -> void:
	if is_muted: return
	if not birds_stream_player:
		birds_stream_player = AudioStreamPlayer.new()
		birds_stream_player.name = "TropicalBirdsAudio"
		birds_stream_player.volume_db = -8.0
		add_child(birds_stream_player)
	var sample_hz = 22050
	var duration = 0.5
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = exp(-t * 6.0)
		var freq = 1800.0 + sin(t * 25.0) * 400.0
		var val = sin(t * freq * TAU) * env * 0.5
		var int_sample = int(clamp(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	birds_stream_player.stream = stream
	birds_stream_player.play()

var cart_wheel_player: AudioStreamPlayer
var boat_splash_player: AudioStreamPlayer

func play_cart_wheel_creak() -> void:
	if is_muted: return
	if not cart_wheel_player:
		cart_wheel_player = AudioStreamPlayer.new()
		cart_wheel_player.name = "CartWheelCreakAudio"
		cart_wheel_player.volume_db = -9.0
		add_child(cart_wheel_player)
	if cart_wheel_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.35
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = sin(t / duration * PI)
		# Rhythmic wooden creak vibration
		var creak = sin(t * 180.0 * TAU + sin(t * 40.0) * 4.0) * 0.6 + sin(t * 360.0 * TAU) * 0.3
		var int_sample = int(clamp(creak * env, -1.0, 1.0) * 18000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	cart_wheel_player.stream = stream
	cart_wheel_player.play()

func play_boat_row_splash() -> void:
	if is_muted: return
	if not boat_splash_player:
		boat_splash_player = AudioStreamPlayer.new()
		boat_splash_player.name = "BoatSplashAudio"
		boat_splash_player.volume_db = -8.0
		add_child(boat_splash_player)
	if boat_splash_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.42
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = exp(-t * 5.5)
		# Water splash burst
		var water_burst = (sin(t * 110.0 * TAU) * 0.5 + sin(t * 260.0 * TAU) * 0.3 + sin(t * 520.0 * TAU) * 0.2)
		var int_sample = int(clamp(water_burst * env, -1.0, 1.0) * 20000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	boat_splash_player.stream = stream
	boat_splash_player.play()

var aircraft_engine_player: AudioStreamPlayer
var helicopter_rotor_player: AudioStreamPlayer

func play_airplane_engine(throttle: float = 1.0) -> void:
	if is_muted: return
	if not aircraft_engine_player:
		aircraft_engine_player = AudioStreamPlayer.new()
		aircraft_engine_player.name = "AirplaneEngineAudio"
		aircraft_engine_player.volume_db = -6.0
		add_child(aircraft_engine_player)
	if aircraft_engine_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.6
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	var base_freq = 120.0 + clampf(throttle, 0.0, 1.5) * 80.0
	var fade_frames = mini(128, total_frames / 4)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var roar = (sin(t * base_freq * TAU) * 0.5 + sin(t * base_freq * 2.0 * TAU) * 0.3 + sin(t * base_freq * 3.5 * TAU) * 0.2)
		var env = 1.0
		if i < fade_frames:
			env = 0.5 * (1.0 - cos(float(i) / float(fade_frames) * PI))
		elif i > total_frames - fade_frames:
			env = 0.5 * (1.0 - cos(float(total_frames - i) / float(fade_frames) * PI))
		var int_sample = int(clamp(roar * env, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	aircraft_engine_player.stream = stream
	aircraft_engine_player.play()

func play_helicopter_rotor(rpm_factor: float = 1.0) -> void:
	if is_muted: return
	if not helicopter_rotor_player:
		helicopter_rotor_player = AudioStreamPlayer.new()
		helicopter_rotor_player.name = "HelicopterRotorAudio"
		helicopter_rotor_player.volume_db = -5.0
		add_child(helicopter_rotor_player)
	if helicopter_rotor_player.playing:
		return
	var sample_hz = 22050
	var duration = 0.5
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	var blade_freq = 24.0 * clampf(rpm_factor, 0.2, 1.4)
	var fade_frames = mini(128, total_frames / 4)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var thud = pow(abs(sin(t * blade_freq * TAU)), 6.0)
		var whoosh = sin(t * 180.0 * TAU) * 0.35 + sin(t * 90.0 * TAU) * 0.45
		var val = whoosh * (0.3 + thud * 0.7)
		var env = 1.0
		if i < fade_frames:
			env = 0.5 * (1.0 - cos(float(i) / float(fade_frames) * PI))
		elif i > total_frames - fade_frames:
			env = 0.5 * (1.0 - cos(float(total_frames - i) / float(fade_frames) * PI))
		var int_sample = int(clamp(val * env, -1.0, 1.0) * 25000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	helicopter_rotor_player.stream = stream
	helicopter_rotor_player.play()

func _synthesize_acoustic_flute_song() -> void:
	# Soothing Myanmar countryside acoustic guitar chords & bamboo flute melody loop
	var sample_hz = 22050
	var duration = 16.0
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_frames

	var data = PackedByteArray()
	data.resize(total_frames * 2)

	# Peaceful Pentatonic flute notes
	var flute_notes = [
		{"t": 0.5, "f": 523.25, "dur": 2.2}, # C5
		{"t": 3.0, "f": 587.33, "dur": 1.8}, # D5
		{"t": 5.0, "f": 659.25, "dur": 2.5}, # E5
		{"t": 8.0, "f": 783.99, "dur": 3.0}, # G5
		{"t": 11.5, "f": 659.25, "dur": 1.8},
		{"t": 13.5, "f": 523.25, "dur": 2.2}
	]

	# Acoustic guitar fingerpicking arpeggios
	var guitar_arpeggio = [
		130.81, 164.81, 196.0, 261.63, # C
		146.83, 174.61, 220.0, 293.66, # Dm
		164.81, 196.0, 246.94, 329.63, # Em
		174.61, 220.0, 261.63, 349.23  # F
	]

	for i in range(total_frames):
		var cur_t = float(i) / float(sample_hz)
		var total_sample = 0.0

		# Guitar arpeggio pattern every 0.35s
		var beat = fmod(cur_t, 0.35)
		var note_idx = int(cur_t / 0.35) % guitar_arpeggio.size()
		var g_freq = guitar_arpeggio[note_idx]
		var g_env = exp(-beat * 6.5)
		var g_wave = sin(beat * g_freq * TAU) * 0.7 + sin(beat * g_freq * 2.0 * TAU) * 0.25
		total_sample += g_wave * g_env * 0.35

		# Bamboo flute breath & gentle vibrato
		for fn in flute_notes:
			var n_start = fn["t"]
			var n_dur = fn["dur"]
			if cur_t >= n_start and cur_t < (n_start + n_dur):
				var nt = cur_t - n_start
				var attack = clampf(nt / 0.3, 0.0, 1.0)
				var release = clampf((n_dur - nt) / 0.4, 0.0, 1.0)
				var vibrato = 1.0 + sin(nt * 5.2 * TAU) * 0.012
				var flute_f = fn["f"] * vibrato
				var flute_sound = sin(nt * flute_f * TAU) * 0.8 + sin(nt * flute_f * 3.0 * TAU) * 0.12
				var breath_noise = (randf() * 2.0 - 1.0) * 0.04
				total_sample += (flute_sound + breath_noise) * attack * release * 0.40

		var int_sample = int(clamp(total_sample, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	bgm_music_player.stream = stream
	bgm_music_player.play()

func _synthesize_nature_ambience_loop() -> void:
	# Gentle mountain wind, cicadas, and distant bamboo chimes
	var sample_hz = 22050
	var duration = 14.0
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_frames

	var data = PackedByteArray()
	data.resize(total_frames * 2)

	for i in range(total_frames):
		var cur_t = float(i) / float(sample_hz)
		# Low wind rumble & sweeping breeze
		var wind_mod = (sin(cur_t * 0.45 * TAU) * 0.5 + 0.5)
		var wind_noise = (sin(cur_t * 85.0 * TAU) + sin(cur_t * 142.0 * TAU) * 0.6) * wind_mod * 0.25
		# Summer cicadas / crickets shimmer
		var cicada = sin(cur_t * 4200.0 * TAU) * sin(cur_t * 18.0 * TAU) * 0.08
		# Occasional bamboo chime ping
		var chime = 0.0
		var chime_time = fmod(cur_t, 3.5)
		if chime_time < 0.8:
			var c_env = exp(-chime_time * 4.5)
			chime = (sin(chime_time * 1240.0 * TAU) * 0.6 + sin(chime_time * 2480.0 * TAU) * 0.3) * c_env * 0.18

		var total_sample = wind_noise + cicada + chime
		var int_sample = int(clamp(total_sample, -1.0, 1.0) * 20000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	bgm_music_player.stream = stream
	bgm_music_player.play()

func play_cart_bell() -> void:
	if is_muted: return
	if not cart_bell_player:
		cart_bell_player = AudioStreamPlayer.new()
		cart_bell_player.name = "CartBellAudio"
		cart_bell_player.volume_db = -9.0
		add_child(cart_bell_player)
	if cart_bell_player.playing: return
	var sample_hz = 22050
	var duration = 0.4
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = exp(-t * 11.0)
		var bell = sin(t * 1520.0 * TAU) * 0.65 + sin(t * 2280.0 * TAU) * 0.35 + sin(t * 3040.0 * TAU) * 0.15
		var int_sample = int(clamp(bell * env, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	cart_bell_player.stream = stream
	cart_bell_player.play()

func play_horn() -> void:
	if is_muted: return
	if not horn_player:
		horn_player = AudioStreamPlayer.new()
		horn_player.name = "VehicleHornAudio"
		horn_player.volume_db = -4.0
		add_child(horn_player)
	var sample_hz = 22050
	var duration = 0.55
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = 1.0
		if t < 0.04:
			env = t / 0.04
		elif t > 0.45:
			env = 1.0 - (t - 0.45) / 0.10
		var tone = (sin(t * 349.2 * TAU) * 0.45 + sin(t * 440.0 * TAU) * 0.40 + sin(t * 880.0 * TAU) * 0.15)
		var int_sample = int(clamp(tone * env, -1.0, 1.0) * 26000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	horn_player.stream = stream
	horn_player.play()

func play_tire_skid(intensity: float = 1.0) -> void:
	if is_muted: return
	if not skid_player:
		skid_player = AudioStreamPlayer.new()
		skid_player.name = "TireSkidAudio"
		skid_player.volume_db = -8.0
		add_child(skid_player)
	if skid_player.playing: return
	var sample_hz = 22050
	var duration = 0.40
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = exp(-t * 4.0) * clampf(intensity, 0.2, 1.0)
		var screech = (sin(t * 1920.0 * TAU) * 0.5 + sin(t * 2380.0 * TAU) * 0.35 + sin(t * 1150.0 * TAU) * 0.25)
		var flutter = (1.0 + 0.3 * sin(t * 65.0 * TAU))
		var int_sample = int(clamp(screech * flutter * env, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	skid_player.stream = stream
	skid_player.play()

func set_wind_rush(speed_ratio: float, windows_open: bool = false) -> void:
	if is_muted:
		if wind_rush_player and wind_rush_player.playing: wind_rush_player.stop()
		return
	if not wind_rush_player:
		wind_rush_player = AudioStreamPlayer.new()
		wind_rush_player.name = "HighwayWindRushAudio"
		add_child(wind_rush_player)
		var sample_hz = 22050
		var duration = 2.0
		var total_frames = int(sample_hz * duration)
		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = sample_hz
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = total_frames
		var data = PackedByteArray()
		data.resize(total_frames * 2)
		for i in range(total_frames):
			var t = float(i) / float(sample_hz)
			var buffeting = (sin(t * 85.0 * TAU) * 0.45 + sin(t * 145.0 * TAU) * 0.35 + sin(t * 220.0 * TAU) * 0.20)
			var hiss = sin(t * 1650.0 * TAU) * (0.8 + 0.2 * sin(t * 12.0 * TAU)) * 0.15
			var val = (buffeting + hiss)
			var int_sample = int(clamp(val, -1.0, 1.0) * 18000.0)
			data.encode_s16(i * 2, int_sample)
		stream.data = data
		wind_rush_player.stream = stream

	if speed_ratio > 0.15:
		if not wind_rush_player.playing:
			wind_rush_player.play()
		var base_vol = lerpf(-30.0, -8.0, clampf((speed_ratio - 0.15) / 0.85, 0.0, 1.0))
		var target_vol = (base_vol + 7.5) if windows_open else base_vol
		wind_rush_player.volume_db = target_vol
		var max_pitch = 1.45 if windows_open else 1.35
		wind_rush_player.pitch_scale = lerpf(0.85, max_pitch, speed_ratio)
	else:
		if wind_rush_player.playing:
			wind_rush_player.stop()

var headlight_switch_player: AudioStreamPlayer = null

func play_headlight_switch() -> void:
	if is_muted:
		return
	if not headlight_switch_player:
		headlight_switch_player = AudioStreamPlayer.new()
		headlight_switch_player.name = "HeadlightSwitchAudio"
		add_child(headlight_switch_player)

	var sample_hz = 22050
	var duration = 0.08
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)

	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var snap1 = exp(-t * 90.0) * sin(t * 3200.0 * TAU) * 0.7
		var snap2 = 0.0
		if t > 0.025:
			snap2 = exp(-(t - 0.025) * 80.0) * sin((t - 0.025) * 1150.0 * TAU) * 0.5
		var val = snap1 + snap2
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	headlight_switch_player.stream = stream
	headlight_switch_player.volume_db = -4.0
	headlight_switch_player.play()

var wiper_sfx_player: AudioStreamPlayer = null

func play_wiper_sweep() -> void:
	if is_muted:
		return
	if not wiper_sfx_player:
		wiper_sfx_player = AudioStreamPlayer.new()
		wiper_sfx_player.name = "WiperSweepAudio"
		add_child(wiper_sfx_player)

	var sample_hz = 22050
	var duration = 0.22
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)

	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = sin((t / duration) * PI)
		var squeak = (sin(t * 1850.0 * TAU) * 0.4 + sin(t * 2650.0 * TAU) * 0.35 + sin(t * 880.0 * TAU) * 0.25)
		var flutter = (1.0 + 0.3 * sin(t * 45.0 * TAU))
		var int_sample = int(clamp(squeak * flutter * env, -1.0, 1.0) * 16000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	wiper_sfx_player.stream = stream
	wiper_sfx_player.volume_db = -8.0
	wiper_sfx_player.play()

var power_window_player: AudioStreamPlayer = null

func play_power_window(roll_down: bool) -> void:
	if is_muted:
		return
	if not power_window_player:
		power_window_player = AudioStreamPlayer.new()
		power_window_player.name = "PowerWindowAudio"
		add_child(power_window_player)

	var sample_hz = 22050
	var duration = 0.42
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)

	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# 12V DC window motor hum (260Hz - 310Hz)
		var motor_freq = lerpf(290.0, 260.0, t / duration) if roll_down else lerpf(260.0, 310.0, t / duration)
		var motor = (sin(t * motor_freq * TAU) * 0.45 + sin(t * motor_freq * 2.0 * TAU) * 0.25)
		var glass_slide = sin(t * 1400.0 * TAU) * 0.12 * sin(t * 30.0 * TAU)
		var thump = 0.0
		if t > (duration - 0.06):
			var thump_t = t - (duration - 0.06)
			thump = exp(-thump_t * 80.0) * sin(thump_t * 90.0 * TAU) * 0.75
		var env = sin(clampf((t / duration) * PI, 0.0, PI))
		var val = (motor + glass_slide) * env + thump
		var int_sample = int(clamp(val, -1.0, 1.0) * 17000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	power_window_player.stream = stream
	power_window_player.volume_db = -6.0
	power_window_player.play()

var exhaust_pop_player: AudioStreamPlayer = null

func play_exhaust_pop() -> void:
	if is_muted:
		return
	if not exhaust_pop_player:
		exhaust_pop_player = AudioStreamPlayer.new()
		exhaust_pop_player.name = "ExhaustPopAudio"
		add_child(exhaust_pop_player)

	var sample_hz = 22050
	var duration = 0.16
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)

	var rng_seed = 98765
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		rng_seed = (rng_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var noise = (float(rng_seed) / 1073741824.0) - 1.0

		# Deep muffled bass explosion (92Hz) + crackle (840Hz)
		var pop = exp(-t * 38.0) * (sin(t * 92.0 * TAU) * 0.75 + sin(t * 840.0 * TAU) * 0.35)
		var crackle = exp(-t * 55.0) * noise * 0.4
		var env = sin(clampf((t / duration) * PI, 0.0, PI))
		var val = (pop + crackle) * env
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	exhaust_pop_player.stream = stream
	exhaust_pop_player.volume_db = -4.5
	exhaust_pop_player.pitch_scale = randf_range(0.92, 1.15)
	exhaust_pop_player.play()

var turn_signal_player: AudioStreamPlayer = null

func play_turn_signal_tick(is_on: bool) -> void:
	if is_muted:
		return
	if not turn_signal_player:
		turn_signal_player = AudioStreamPlayer.new()
		turn_signal_player.name = "TurnSignalAudio"
		add_child(turn_signal_player)

	var sample_hz = 22050
	var duration = 0.04
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)

	var tick_freq = 2800.0 if is_on else 1850.0
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var snap = exp(-t * 160.0) * sin(t * tick_freq * TAU) * 0.75
		var int_sample = int(clamp(snap, -1.0, 1.0) * 19000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	turn_signal_player.stream = stream
	turn_signal_player.volume_db = -8.0
	turn_signal_player.play()

var mirror_flip_player: AudioStreamPlayer = null

func play_mirror_flip() -> void:
	if is_muted:
		return
	if not mirror_flip_player:
		mirror_flip_player = AudioStreamPlayer.new()
		mirror_flip_player.name = "MirrorFlipAudio"
		add_child(mirror_flip_player)

	var sample_hz = 22050
	var duration = 0.06
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)

	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Dual mechanical detent snap (3400Hz + 1600Hz)
		var snap1 = exp(-t * 110.0) * sin(t * 3400.0 * TAU) * 0.7
		var snap2 = 0.0
		if t > 0.018:
			snap2 = exp(-(t - 0.018) * 95.0) * sin((t - 0.018) * 1600.0 * TAU) * 0.5
		var val = snap1 + snap2
		var int_sample = int(clamp(val, -1.0, 1.0) * 19000.0)
		data.encode_s16(i * 2, int_sample)

	stream.data = data
	mirror_flip_player.stream = stream
	mirror_flip_player.volume_db = -5.0
	mirror_flip_player.play()

var ac_blower_player: AudioStreamPlayer = null

func play_ac_blower(level: int) -> void:
	if is_muted:
		if ac_blower_player and ac_blower_player.playing: ac_blower_player.stop()
		return
	if not ac_blower_player:
		ac_blower_player = AudioStreamPlayer.new()
		ac_blower_player.name = "ACBlowerAudio"
		add_child(ac_blower_player)
		var sample_hz = 22050
		var duration = 2.0
		var total_frames = int(sample_hz * duration)
		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = sample_hz
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = total_frames
		var data = PackedByteArray()
		data.resize(total_frames * 2)
		var rng_seed = 13579
		for i in range(total_frames):
			var t = float(i) / float(sample_hz)
			rng_seed = (rng_seed * 1103515245 + 12345) & 0x7FFFFFFF
			var noise = (float(rng_seed) / 1073741824.0) - 1.0
			var blower = sin(t * 180.0 * TAU) * 0.45 + sin(t * 360.0 * TAU) * 0.25
			var air_hiss = noise * 0.35
			var val = (blower + air_hiss) * 0.65
			var int_sample = int(clamp(val, -1.0, 1.0) * 16000.0)
			data.encode_s16(i * 2, int_sample)
		stream.data = data
		ac_blower_player.stream = stream

	if level <= 0:
		if ac_blower_player.playing:
			ac_blower_player.stop()
	elif level == 1:
		if not ac_blower_player.playing:
			ac_blower_player.play()
		ac_blower_player.volume_db = -16.0
		ac_blower_player.pitch_scale = 0.95
	else:
		if not ac_blower_player.playing:
			ac_blower_player.play()
		ac_blower_player.volume_db = -10.5
		ac_blower_player.pitch_scale = 1.35

var watermill_churn_player: AudioStreamPlayer = null

func play_watermill_churn() -> void:
	if is_muted: return
	if not watermill_churn_player:
		watermill_churn_player = AudioStreamPlayer.new()
		watermill_churn_player.name = "WatermillChurnAudio"
		watermill_churn_player.volume_db = -8.5
		add_child(watermill_churn_player)
	var sample_hz = 22050
	var duration = 0.6
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = sin((t / duration) * PI)
		var creak = (sin(t * 92.0 * TAU + sin(t * 24.0) * 3.5) * 0.65 + sin(t * 184.0 * TAU) * 0.25)
		var splash = (sin(t * 310.0 * TAU) * 0.35 + sin(t * 620.0 * TAU) * 0.20)
		var val = (creak + splash) * env
		var int_sample = int(clamp(val, -1.0, 1.0) * 19000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	watermill_churn_player.stream = stream
	watermill_churn_player.play()

var dome_light_player: AudioStreamPlayer = null

func play_dome_light_click() -> void:
	if is_muted: return
	if not dome_light_player:
		dome_light_player = AudioStreamPlayer.new()
		dome_light_player.name = "DomeLightClickAudio"
		dome_light_player.volume_db = -6.0
		add_child(dome_light_player)
	var sample_hz = 22050
	var duration = 0.05
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Crisp micro-switch snap (3200Hz + 1200Hz)
		var snap1 = exp(-t * 120.0) * sin(t * 3200.0 * TAU) * 0.7
		var snap2 = 0.0
		if t > 0.015:
			snap2 = exp(-(t - 0.015) * 90.0) * sin((t - 0.015) * 1200.0 * TAU) * 0.45
		var val = snap1 + snap2
		var int_sample = int(clamp(val, -1.0, 1.0) * 20000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	dome_light_player.stream = stream
	dome_light_player.play()

var cave_bell_player: AudioStreamPlayer = null

func play_cave_bell_strike() -> void:
	if is_muted: return
	if not cave_bell_player:
		cave_bell_player = AudioStreamPlayer.new()
		cave_bell_player.name = "CaveBellAudio"
		cave_bell_player.volume_db = -5.0
		add_child(cave_bell_player)
	var sample_hz = 22050
	var duration = 2.4
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var decay = exp(-t * 2.2)
		var base = sin(t * 330.0 * TAU) * 0.55 + sin(t * 660.0 * TAU) * 0.25 + sin(t * 990.0 * TAU) * 0.12
		var shimmer = sin(t * 4.8 * TAU) * 0.08
		var echo = 0.0
		if t > 0.28:
			echo = exp(-(t - 0.28) * 2.4) * sin((t - 0.28) * 330.0 * TAU) * 0.35
		var val = (base * (1.0 + shimmer)) * decay + echo
		var int_sample = int(clamp(val, -1.0, 1.0) * 26000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	cave_bell_player.stream = stream
	cave_bell_player.play()

var glovebox_player: AudioStreamPlayer = null

func play_glovebox_latch(is_open: bool) -> void:
	if is_muted: return
	if not glovebox_player:
		glovebox_player = AudioStreamPlayer.new()
		glovebox_player.name = "GloveboxAudio"
		glovebox_player.volume_db = -6.0
		add_child(glovebox_player)
	var sample_hz = 22050
	var duration = 0.08
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	var snap_freq = 2400.0 if is_open else 1650.0
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var snap = exp(-t * 95.0) * sin(t * snap_freq * TAU) * 0.7
		var thump = 0.0
		if t > 0.02:
			thump = exp(-(t - 0.02) * 65.0) * sin((t - 0.02) * 120.0 * TAU) * 0.5
		var val = snap + thump
		var int_sample = int(clamp(val, -1.0, 1.0) * 21000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	glovebox_player.stream = stream
	glovebox_player.play()

var sun_visor_player: AudioStreamPlayer = null

func play_sun_visor_flip(is_down: bool) -> void:
	if is_muted: return
	if not sun_visor_player:
		sun_visor_player = AudioStreamPlayer.new()
		sun_visor_player.name = "SunVisorAudio"
		sun_visor_player.volume_db = -6.5
		add_child(sun_visor_player)
	var sample_hz = 22050
	var duration = 0.07
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	var snap_freq = 1850.0 if is_down else 2600.0
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var snap = exp(-t * 110.0) * sin(t * snap_freq * TAU) * 0.75
		var friction = sin(t * 450.0 * TAU) * exp(-t * 55.0) * 0.35
		var val = snap + friction
		var int_sample = int(clamp(val, -1.0, 1.0) * 21000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	sun_visor_player.stream = stream
	sun_visor_player.play()

var anvil_player: AudioStreamPlayer = null

func play_anvil_strike() -> void:
	if is_muted: return
	if not anvil_player:
		anvil_player = AudioStreamPlayer.new()
		anvil_player.name = "AnvilAudio"
		anvil_player.volume_db = -5.0
		add_child(anvil_player)
	var sample_hz = 22050
	var duration = 0.45
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Crisp metallic hammer impact + high overtone ping + brief quench sizzle
		var ping = sin(t * 1450.0 * TAU) * 0.6 + sin(t * 2900.0 * TAU) * 0.3 + sin(t * 4350.0 * TAU) * 0.15
		var strike = exp(-t * 16.0) * ping
		var sizzle = 0.0
		if t > 0.08:
			sizzle = exp(-(t - 0.08) * 8.0) * sin(t * 3100.0 * TAU + sin(t * 120.0) * 8.0) * 0.2
		var val = strike + sizzle
		var int_sample = int(clamp(val, -1.0, 1.0) * 26000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	anvil_player.stream = stream
	anvil_player.play()
var kiln_player: AudioStreamPlayer = null

func play_charcoal_crackle() -> void:
	if is_muted: return
	if not kiln_player:
		kiln_player = AudioStreamPlayer.new()
		kiln_player.name = "CharcoalKilnAudio"
		kiln_player.volume_db = -8.0
		add_child(kiln_player)
	var sample_hz = 22050
	var duration = 0.55
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep smoldering kiln draft hum (68Hz) + sporadic sharp ember pop crackles
		var hum = sin(t * 68.0 * TAU) * 0.35 + sin(t * 136.0 * TAU) * 0.15
		var pop1 = 0.0
		if t > 0.12 and t < 0.16:
			pop1 = exp(-(t - 0.12) * 90.0) * sin((t - 0.12) * 1850.0 * TAU) * 0.4
		var pop2 = 0.0
		if t > 0.34 and t < 0.38:
			pop2 = exp(-(t - 0.34) * 90.0) * sin((t - 0.34) * 2300.0 * TAU) * 0.35
		var val = hum + pop1 + pop2
		var int_sample = int(clamp(val, -1.0, 1.0) * 19000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	kiln_player.stream = stream
	kiln_player.play()
var diffuser_player: AudioStreamPlayer = null

func play_diffuser_spray() -> void:
	if is_muted: return
	if not diffuser_player:
		diffuser_player = AudioStreamPlayer.new()
		diffuser_player.name = "DiffuserSprayAudio"
		diffuser_player.volume_db = -8.5
		add_child(diffuser_player)
	var sample_hz = 22050
	var duration = 0.22
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Soft pressurized spray hiss + gentle capillary liquid resonance
		var hiss = exp(-t * 18.0) * (sin(t * 2800.0 * TAU) * 0.4 + sin(t * 3600.0 * TAU) * 0.3)
		var bubble = 0.0
		if t > 0.04:
			bubble = exp(-(t - 0.04) * 25.0) * sin((t - 0.04) * 850.0 * TAU) * 0.25
		var val = hiss + bubble
		var int_sample = int(clamp(val, -1.0, 1.0) * 19000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	diffuser_player.stream = stream
	diffuser_player.play()
var oil_press_player: AudioStreamPlayer = null

func play_oil_press_creak() -> void:
	if is_muted: return
	if not oil_press_player:
		oil_press_player = AudioStreamPlayer.new()
		oil_press_player.name = "OilPressAudio"
		oil_press_player.volume_db = -7.5
		add_child(oil_press_player)
	var sample_hz = 22050
	var duration = 0.65
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = sin(t / duration * PI)
		# Deep rhythmic hardwood mortise friction & rotational groan
		var groan = sin(t * 115.0 * TAU + sin(t * 35.0) * 3.5) * 0.6 + sin(t * 230.0 * TAU) * 0.3
		var creak = sin(t * 460.0 * TAU) * exp(-t * 8.0) * 0.2
		var val = (groan + creak) * env
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	oil_press_player.stream = stream
	oil_press_player.play()
var tea_sip_player: AudioStreamPlayer = null

func play_straw_sip() -> void:
	if is_muted: return
	if not tea_sip_player:
		tea_sip_player = AudioStreamPlayer.new()
		tea_sip_player.name = "TeaStrawSipAudio"
		tea_sip_player.volume_db = -6.5
		add_child(tea_sip_player)
	var sample_hz = 22050
	var duration = 0.38
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Suction straw slurp + liquid bubble gurgle + ice cube clink
		var slurp = exp(-t * 12.0) * (sin(t * 2100.0 * TAU + sin(t * 45.0) * 3.0) * 0.45 + sin(t * 920.0 * TAU) * 0.35)
		var clink = 0.0
		if t > 0.18 and t < 0.25:
			clink = exp(-(t - 0.18) * 85.0) * sin((t - 0.18) * 3900.0 * TAU) * 0.3
		var val = slurp + clink
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	tea_sip_player.stream = stream
	tea_sip_player.play()
var hay_rustle_player: AudioStreamPlayer = null

func play_hay_rustle() -> void:
	if is_muted: return
	if not hay_rustle_player:
		hay_rustle_player = AudioStreamPlayer.new()
		hay_rustle_player.name = "HayRustleAudio"
		hay_rustle_player.volume_db = -8.0
		add_child(hay_rustle_player)
	var sample_hz = 22050
	var duration = 0.45
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var env = sin(t / duration * PI)
		# Soft dry golden straw rustle with gentle wind flutter
		var rustle = (sin(t * 1950.0 * TAU) * 0.4 + sin(t * 2850.0 * TAU + sin(t * 80.0) * 2.0) * 0.35 + sin(t * 3350.0 * TAU) * 0.25)
		var val = rustle * env * exp(-t * 3.5)
		var int_sample = int(clamp(val, -1.0, 1.0) * 19000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	hay_rustle_player.stream = stream
	hay_rustle_player.play()
var ferry_bell_player: AudioStreamPlayer = null

func play_ferry_bell() -> void:
	if is_muted: return
	if not ferry_bell_player:
		ferry_bell_player = AudioStreamPlayer.new()
		ferry_bell_player.name = "FerryBellAudio"
		ferry_bell_player.volume_db = -6.0
		add_child(ferry_bell_player)
	var sample_hz = 22050
	var duration = 1.2
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Clear resonant 640Hz nautical brass bell with 1280Hz overtone and water lap
		var decay = exp(-t * 3.8)
		var bell = (sin(t * 640.0 * TAU) * 0.6 + sin(t * 1280.0 * TAU) * 0.3) * decay
		var lap = 0.0
		if t > 0.15:
			lap = exp(-(t - 0.15) * 4.0) * sin((t - 0.15) * 280.0 * TAU) * 0.2
		var val = bell + lap
		var int_sample = int(clamp(val, -1.0, 1.0) * 24000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	ferry_bell_player.stream = stream
	ferry_bell_player.play()
var stalk_click_player: AudioStreamPlayer = null

func play_stalk_click() -> void:
	if is_muted: return
	if not stalk_click_player:
		stalk_click_player = AudioStreamPlayer.new()
		stalk_click_player.name = "StalkClickAudio"
		stalk_click_player.volume_db = -6.0
		add_child(stalk_click_player)
	var sample_hz = 22050
	var duration = 0.06
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Crisp automotive column switch detent snap
		var snap = exp(-t * 120.0) * sin(t * 3100.0 * TAU) * 0.75
		var spring = 0.0
		if t > 0.015:
			spring = exp(-(t - 0.015) * 85.0) * sin((t - 0.015) * 1950.0 * TAU) * 0.4
		var val = snap + spring
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	stalk_click_player.stream = stream
	stalk_click_player.play()
var wood_adze_player: AudioStreamPlayer = null

func play_wood_adze_chop() -> void:
	if is_muted: return
	if not wood_adze_player:
		wood_adze_player = AudioStreamPlayer.new()
		wood_adze_player.name = "WoodAdzeAudio"
		wood_adze_player.volume_db = -6.5
		add_child(wood_adze_player)
	var sample_hz = 22050
	var duration = 0.28
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep hardwood adze blade impact + crisp timber splinter chip crackle
		var thud = exp(-t * 22.0) * (sin(t * 140.0 * TAU) * 0.65 + sin(t * 280.0 * TAU) * 0.35)
		var chip = exp(-t * 45.0) * sin(t * 1850.0 * TAU) * 0.4
		var val = thud + chip
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	wood_adze_player.stream = stream
	wood_adze_player.play()
var granary_latch_player: AudioStreamPlayer = null

func play_granary_latch() -> void:
	if is_muted: return
	if not granary_latch_player:
		granary_latch_player = AudioStreamPlayer.new()
		granary_latch_player.name = "GranaryLatchAudio"
		granary_latch_player.volume_db = -6.5
		add_child(granary_latch_player)
	var sample_hz = 22050
	var duration = 0.35
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Heavy timber hatch creak + brass padlock click
		var creak = exp(-t * 14.0) * (sin(t * 180.0 * TAU) * 0.6 + sin(t * 360.0 * TAU) * 0.3)
		var brass = 0.0
		if t > 0.08 and t < 0.16:
			brass = exp(-(t - 0.08) * 65.0) * sin((t - 0.08) * 3400.0 * TAU) * 0.35
		var val = creak + brass
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	granary_latch_player.stream = stream
	granary_latch_player.play()
var water_ladle_player: AudioStreamPlayer = null

func play_water_ladle_dip() -> void:
	if is_muted: return
	if not water_ladle_player:
		water_ladle_player = AudioStreamPlayer.new()
		water_ladle_player.name = "WaterLadleAudio"
		water_ladle_player.volume_db = -6.5
		add_child(water_ladle_player)
	var sample_hz = 22050
	var duration = 0.42
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep hollow clay pot cavity resonance + brass ladle water dip and splash
		var hollow = exp(-t * 12.0) * sin(t * 190.0 * TAU) * 0.45
		var dip = 0.0
		if t > 0.05:
			dip = exp(-(t - 0.05) * 16.0) * (sin((t - 0.05) * 950.0 * TAU) * 0.4 + sin((t - 0.05) * 1480.0 * TAU) * 0.25)
		var trickle = 0.0
		if t > 0.14:
			trickle = exp(-(t - 0.14) * 22.0) * sin((t - 0.14) * 2200.0 * TAU + sin(t * 60.0) * 3.0) * 0.25
		var val = hollow + dip + trickle
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	water_ladle_player.stream = stream
	water_ladle_player.play()
var vanity_slide_player: AudioStreamPlayer = null

func play_vanity_slide(is_open: bool) -> void:
	if is_muted: return
	if not vanity_slide_player:
		vanity_slide_player = AudioStreamPlayer.new()
		vanity_slide_player.name = "VanitySlideAudio"
		vanity_slide_player.volume_db = -7.0
		add_child(vanity_slide_player)
	var sample_hz = 22050
	var duration = 0.12
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	var snap_freq = 2700.0 if is_open else 1850.0
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Smooth plastic slide friction + recess snap click
		var slide = sin(t * 1250.0 * TAU) * exp(-t * 35.0) * 0.35
		var snap = 0.0
		if t > 0.05:
			snap = exp(-(t - 0.05) * 85.0) * sin((t - 0.05) * snap_freq * TAU) * 0.65
		var val = slide + snap
		var int_sample = int(clamp(val, -1.0, 1.0) * 21000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	vanity_slide_player.stream = stream
	vanity_slide_player.play()

var well_sweep_player: AudioStreamPlayer = null
var well_bucket_player: AudioStreamPlayer = null

func play_well_sweep_creak() -> void:
	if is_muted: return
	if not well_sweep_player:
		well_sweep_player = AudioStreamPlayer.new()
		well_sweep_player.name = "WellSweepAudio"
		well_sweep_player.volume_db = -6.0
		add_child(well_sweep_player)
	var sample_hz = 22050
	var duration = 0.55
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep hardwood fulcrum groaning creak + bamboo lever stress harmonic
		var groan = sin(t * 135.0 * TAU + sin(t * 18.0) * 1.5) * exp(-t * 4.5) * 0.55
		var stress = sin(t * 270.0 * TAU) * exp(-t * 6.5) * 0.3
		var friction = sin(t * 780.0 * TAU) * exp(-t * 12.0) * 0.15
		var val = groan + stress + friction
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	well_sweep_player.stream = stream
	well_sweep_player.play()

func play_well_bucket_dip() -> void:
	if is_muted: return
	if not well_bucket_player:
		well_bucket_player = AudioStreamPlayer.new()
		well_bucket_player.name = "WellBucketAudio"
		well_bucket_player.volume_db = -5.5
		add_child(well_bucket_player)
	var sample_hz = 22050
	var duration = 0.48
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep well acoustic chamber hollow + metal bucket water immersion slosh
		var chamber = exp(-t * 8.0) * sin(t * 165.0 * TAU) * 0.45
		var slosh = 0.0
		if t > 0.06:
			slosh = exp(-(t - 0.06) * 14.0) * (sin((t - 0.06) * 720.0 * TAU) * 0.4 + sin((t - 0.06) * 1150.0 * TAU) * 0.3)
		var droplets = 0.0
		if t > 0.18:
			droplets = exp(-(t - 0.18) * 18.0) * sin((t - 0.18) * 1920.0 * TAU + sin(t * 45.0) * 2.0) * 0.25
		var val = chamber + slosh + droplets
		var int_sample = int(clamp(val, -1.0, 1.0) * 23500.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	well_bucket_player.stream = stream
	well_bucket_player.play()

var gear_shift_player: AudioStreamPlayer = null

func play_gear_shift() -> void:
	if is_muted: return
	if not gear_shift_player:
		gear_shift_player = AudioStreamPlayer.new()
		gear_shift_player.name = "GearShiftAudio"
		gear_shift_player.volume_db = -6.5
		add_child(gear_shift_player)
	var sample_hz = 22050
	var duration = 0.09
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Mechanical gate detent click + solid transmission gate notch snap
		var notch_thud = exp(-t * 80.0) * sin(t * 180.0 * TAU) * 0.55
		var detent_snap = exp(-t * 120.0) * (sin(t * 2400.0 * TAU) * 0.45 + sin(t * 1750.0 * TAU) * 0.3)
		var val = notch_thud + detent_snap
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	gear_shift_player.stream = stream
	gear_shift_player.play()

var monastery_bell_player: AudioStreamPlayer = null
var kyeezee_player: AudioStreamPlayer = null

func play_monastery_bell() -> void:
	if is_muted: return
	if not monastery_bell_player:
		monastery_bell_player = AudioStreamPlayer.new()
		monastery_bell_player.name = "MonasteryBellAudio"
		monastery_bell_player.volume_db = -4.0
		add_child(monastery_bell_player)
	var sample_hz = 22050
	var duration = 1.4
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep reverberating bronze pagoda bell strike + rich harmonic overtone bloom
		var fundamental = sin(t * 280.0 * TAU) * exp(-t * 2.2) * 0.55
		var octave = sin(t * 560.0 * TAU) * exp(-t * 3.4) * 0.3
		var overtone = sin(t * 840.0 * TAU) * exp(-t * 5.5) * 0.15
		var strike_transient = exp(-t * 45.0) * sin(t * 1120.0 * TAU) * 0.4
		var val = fundamental + octave + overtone + strike_transient
		var int_sample = int(clamp(val, -1.0, 1.0) * 24000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	monastery_bell_player.stream = stream
	monastery_bell_player.play()

func play_kyeezee_chime() -> void:
	if is_muted: return
	if not kyeezee_player:
		kyeezee_player = AudioStreamPlayer.new()
		kyeezee_player.name = "KyeezeeAudio"
		kyeezee_player.volume_db = -5.0
		add_child(kyeezee_player)
	var sample_hz = 22050
	var duration = 1.2
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Classic rotary spinning Myanmar triangular Kyeezee brass vibrato
		var spin_mod = sin(t * 12.0 * TAU) * 28.0
		var strike = exp(-t * 60.0) * sin(t * 2400.0 * TAU) * 0.35
		var shimmer = sin(t * (1650.0 + spin_mod) * TAU) * exp(-t * 2.8) * 0.45
		var shimmer_hi = sin(t * (2280.0 - spin_mod * 0.7) * TAU) * exp(-t * 3.8) * 0.25
		var val = strike + shimmer + shimmer_hi
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	kyeezee_player.stream = stream
	kyeezee_player.play()

var handbrake_ratchet_player: AudioStreamPlayer = null
var handbrake_release_player: AudioStreamPlayer = null

func play_handbrake_ratchet() -> void:
	if is_muted: return
	if not handbrake_ratchet_player:
		handbrake_ratchet_player = AudioStreamPlayer.new()
		handbrake_ratchet_player.name = "HandbrakeRatchetAudio"
		handbrake_ratchet_player.volume_db = -6.0
		add_child(handbrake_ratchet_player)
	var sample_hz = 22050
	var duration = 0.22
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	# 4 crisp mechanical pawl ratchet teeth clicks in sequence
	var click_times = [0.01, 0.06, 0.11, 0.16]
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		var val = 0.0
		for c_t in click_times:
			if t >= c_t and t < c_t + 0.035:
				var dt = t - c_t
				var click = exp(-dt * 140.0) * (sin(dt * 2900.0 * TAU) * 0.5 + sin(dt * 1850.0 * TAU) * 0.35)
				val += click
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	handbrake_ratchet_player.stream = stream
	handbrake_ratchet_player.play()

func play_handbrake_release() -> void:
	if is_muted: return
	if not handbrake_release_player:
		handbrake_release_player = AudioStreamPlayer.new()
		handbrake_release_player.name = "HandbrakeReleaseAudio"
		handbrake_release_player.volume_db = -6.5
		add_child(handbrake_release_player)
	var sample_hz = 22050
	var duration = 0.12
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Button detent snap + resting rubber stop thud
		var button_snap = exp(-t * 90.0) * sin(t * 2650.0 * TAU) * 0.45
		var thud = 0.0
		if t > 0.03:
			thud = exp(-(t - 0.03) * 45.0) * sin((t - 0.03) * 140.0 * TAU) * 0.5
		var val = button_snap + thud
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	handbrake_release_player.stream = stream
	handbrake_release_player.play()

var bridge_groan_player: AudioStreamPlayer = null
var river_pile_player: AudioStreamPlayer = null

func play_bridge_timber_groan() -> void:
	if is_muted: return
	if not bridge_groan_player:
		bridge_groan_player = AudioStreamPlayer.new()
		bridge_groan_player.name = "BridgeGroanAudio"
		bridge_groan_player.volume_db = -5.5
		add_child(bridge_groan_player)
	var sample_hz = 22050
	var duration = 0.52
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Heavy teak timber boardwalk plank flex groan + structural mortise friction
		var groan = sin(t * 115.0 * TAU + sin(t * 16.0) * 1.8) * exp(-t * 5.0) * 0.55
		var harmonic = sin(t * 230.0 * TAU) * exp(-t * 7.5) * 0.3
		var friction = sin(t * 680.0 * TAU) * exp(-t * 14.0) * 0.15
		var val = groan + harmonic + friction
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	bridge_groan_player.stream = stream
	bridge_groan_player.play()

func play_river_pile_lap() -> void:
	if is_muted: return
	if not river_pile_player:
		river_pile_player = AudioStreamPlayer.new()
		river_pile_player.name = "RiverPileLapAudio"
		river_pile_player.volume_db = -6.0
		add_child(river_pile_player)
	var sample_hz = 22050
	var duration = 0.46
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# River current wave lapping against heavy submerged stilt pile logs
		var surge = exp(-t * 7.0) * sin(t * 95.0 * TAU) * 0.45
		var slap = 0.0
		if t > 0.05:
			slap = exp(-(t - 0.05) * 15.0) * (sin((t - 0.05) * 540.0 * TAU) * 0.4 + sin((t - 0.05) * 980.0 * TAU) * 0.3)
		var trickle = 0.0
		if t > 0.16:
			trickle = exp(-(t - 0.16) * 20.0) * sin((t - 0.16) * 1420.0 * TAU + sin(t * 40.0) * 2.0) * 0.25
		var val = surge + slap + trickle
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	river_pile_player.stream = stream
	river_pile_player.play()

var ignition_key_player: AudioStreamPlayer = null
var engine_crank_player: AudioStreamPlayer = null

func play_ignition_key_turn() -> void:
	if is_muted: return
	if not ignition_key_player:
		ignition_key_player = AudioStreamPlayer.new()
		ignition_key_player.name = "IgnitionKeyAudio"
		ignition_key_player.volume_db = -6.0
		add_child(ignition_key_player)
	var sample_hz = 22050
	var duration = 0.11
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Mechanical cylinder tumbler detent snap + brass keyring jingle
		var tumbler = exp(-t * 110.0) * (sin(t * 2950.0 * TAU) * 0.5 + sin(t * 1850.0 * TAU) * 0.35)
		var jingle = 0.0
		if t > 0.02:
			jingle = exp(-(t - 0.02) * 55.0) * sin((t - 0.02) * 4400.0 * TAU) * 0.25
		var val = tumbler + jingle
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	ignition_key_player.stream = stream
	ignition_key_player.play()

func play_engine_crank() -> void:
	if is_muted: return
	if not engine_crank_player:
		engine_crank_player = AudioStreamPlayer.new()
		engine_crank_player.name = "EngineCrankAudio"
		engine_crank_player.volume_db = -4.5
		add_child(engine_crank_player)
	var sample_hz = 22050
	var duration = 0.38
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Starter motor solenoid engagement + compression cylinder chug
		var starter_whir = sin(t * 880.0 * TAU) * exp(-t * 4.0) * 0.25
		var crank_pulse = (sin(t * 78.0 * TAU) + sin(t * 156.0 * TAU) * 0.5) * exp(-t * 2.5) * 0.55
		var click = exp(-t * 80.0) * sin(t * 1650.0 * TAU) * 0.35
		var val = starter_whir + crank_pulse + click
		var int_sample = int(clamp(val, -1.0, 1.0) * 24000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	engine_crank_player.stream = stream
	engine_crank_player.play()

var sugarcane_roller_player: AudioStreamPlayer = null
var jaggery_syrup_player: AudioStreamPlayer = null

func play_sugarcane_roller_creak() -> void:
	if is_muted: return
	if not sugarcane_roller_player:
		sugarcane_roller_player = AudioStreamPlayer.new()
		sugarcane_roller_player.name = "SugarcaneRollerAudio"
		sugarcane_roller_player.volume_db = -5.5
		add_child(sugarcane_roller_player)
	var sample_hz = 22050
	var duration = 0.55
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Heavy hardwood roller rotational groan + fiber crunch squeak
		var roller_groan = sin(t * 125.0 * TAU + sin(t * 18.0) * 1.6) * exp(-t * 4.2) * 0.55
		var harmonic = sin(t * 250.0 * TAU) * exp(-t * 6.5) * 0.3
		var fiber_crunch = sin(t * 1750.0 * TAU) * exp(-t * 12.0) * 0.2
		var val = roller_groan + harmonic + fiber_crunch
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	sugarcane_roller_player.stream = stream
	sugarcane_roller_player.play()

func play_jaggery_syrup_bubble() -> void:
	if is_muted: return
	if not jaggery_syrup_player:
		jaggery_syrup_player = AudioStreamPlayer.new()
		jaggery_syrup_player.name = "JaggerySyrupAudio"
		jaggery_syrup_player.volume_db = -6.0
		add_child(jaggery_syrup_player)
	var sample_hz = 22050
	var duration = 0.48
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Low hearth fire draft + viscous thick syrup simmering bubble pops
		var hearth = exp(-t * 6.0) * sin(t * 95.0 * TAU) * 0.35
		var bubble1 = 0.0
		if t > 0.04 and t < 0.22:
			var dt1 = t - 0.04
			bubble1 = exp(-dt1 * 25.0) * sin(dt1 * 320.0 * TAU) * 0.45
		var bubble2 = 0.0
		if t > 0.18:
			var dt2 = t - 0.18
			bubble2 = exp(-dt2 * 32.0) * sin(dt2 * 580.0 * TAU) * 0.35
		var val = hearth + bubble1 + bubble2
		var int_sample = int(clamp(val, -1.0, 1.0) * 23500.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	jaggery_syrup_player.stream = stream
	jaggery_syrup_player.play()

var rev_limiter_player: AudioStreamPlayer = null

func play_rev_limiter() -> void:
	if is_muted: return
	if not rev_limiter_player:
		rev_limiter_player = AudioStreamPlayer.new()
		rev_limiter_player.name = "RevLimiterAudio"
		rev_limiter_player.volume_db = -5.0
		add_child(rev_limiter_player)
	var sample_hz = 22050
	var duration = 0.15
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Fuel-cut rev limiter bounce stutter + exhaust manifold pulse
		var fuel_cut = sin(t * 85.0 * TAU) * exp(-t * 15.0) * 0.55
		var ping = exp(-t * 60.0) * (sin(t * 2800.0 * TAU) * 0.4 + sin(t * 1850.0 * TAU) * 0.25)
		var val = fuel_cut + ping
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	rev_limiter_player.stream = stream
	rev_limiter_player.play()

var bamboo_raft_player: AudioStreamPlayer = null
var bamboo_wave_player: AudioStreamPlayer = null

func play_bamboo_raft_creak() -> void:
	if is_muted: return
	if not bamboo_raft_player:
		bamboo_raft_player = AudioStreamPlayer.new()
		bamboo_raft_player.name = "BambooRaftCreakAudio"
		bamboo_raft_player.volume_db = -5.5
		add_child(bamboo_raft_player)
	var sample_hz = 22050
	var duration = 0.52
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Interlocking bamboo culm friction groan + rattan lashing stress harmonic
		var groan = sin(t * 140.0 * TAU + sin(t * 14.0) * 1.5) * exp(-t * 4.5) * 0.55
		var harmonic = sin(t * 280.0 * TAU) * exp(-t * 6.5) * 0.3
		var rattan_squeak = sin(t * 820.0 * TAU) * exp(-t * 12.0) * 0.15
		var val = groan + harmonic + rattan_squeak
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	bamboo_raft_player.stream = stream
	bamboo_raft_player.play()

func play_bamboo_wave_slap() -> void:
	if is_muted: return
	if not bamboo_wave_player:
		bamboo_wave_player = AudioStreamPlayer.new()
		bamboo_wave_player.name = "BambooWaveSlapAudio"
		bamboo_wave_player.volume_db = -6.0
		add_child(bamboo_wave_player)
	var sample_hz = 22050
	var duration = 0.44
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# River wave slap against hollow tubular bamboo cavity + water spray
		var hollow = exp(-t * 9.0) * sin(t * 360.0 * TAU) * 0.45
		var wave_slap = 0.0
		if t > 0.04:
			wave_slap = exp(-(t - 0.04) * 16.0) * (sin((t - 0.04) * 640.0 * TAU) * 0.4 + sin((t - 0.04) * 1250.0 * TAU) * 0.25)
		var droplets = 0.0
		if t > 0.15:
			droplets = exp(-(t - 0.15) * 22.0) * sin((t - 0.15) * 1850.0 * TAU) * 0.2
		var val = hollow + wave_slap + droplets
		var int_sample = int(clamp(val, -1.0, 1.0) * 23500.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	bamboo_wave_player.stream = stream
	bamboo_wave_player.play()

func play_throttle_press() -> void:
	if is_muted: return
	if not throttle_pedal_player:
		throttle_pedal_player = AudioStreamPlayer.new()
		throttle_pedal_player.name = "ThrottlePedalAudio"
		throttle_pedal_player.volume_db = -8.0
		add_child(throttle_pedal_player)
	var sample_hz = 22050
	var duration = 0.16
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Mechanical throttle return spring tension squeak + floor bracket pivot click
		var spring_squeak = sin(t * (1450.0 + t * 600.0) * TAU) * exp(-t * 28.0) * 0.35
		var cable_slide = sin(t * 850.0 * TAU) * exp(-t * 18.0) * 0.22
		var floor_stop = 0.0
		if t > 0.06:
			floor_stop = sin((t - 0.06) * 320.0 * TAU) * exp(-(t - 0.06) * 35.0) * 0.35
		var val = spring_squeak + cable_slide + floor_stop
		var int_sample = int(clamp(val, -1.0, 1.0) * 20000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	throttle_pedal_player.stream = stream
	throttle_pedal_player.play()

func play_brake_pedal_press() -> void:
	if is_muted: return
	if not brake_pedal_player:
		brake_pedal_player = AudioStreamPlayer.new()
		brake_pedal_player.name = "BrakePedalAudio"
		brake_pedal_player.volume_db = -7.5
		add_child(brake_pedal_player)
	var sample_hz = 22050
	var duration = 0.22
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Hydraulic vacuum brake booster air hiss + master cylinder plunger thump
		var booster_hiss = (sin(t * 1150.0 * TAU) * 0.3 + sin(t * 2250.0 * TAU) * 0.2) * exp(-t * 14.0)
		var plunger_thump = sin(t * 165.0 * TAU) * exp(-t * 22.0) * 0.45
		var rubber_pad_squish = sin(t * 420.0 * TAU) * exp(-t * 30.0) * 0.25
		var val = booster_hiss + plunger_thump + rubber_pad_squish
		var int_sample = int(clamp(val, -1.0, 1.0) * 21500.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	brake_pedal_player.stream = stream
	brake_pedal_player.play()

func play_sima_ordination_chant() -> void:
	if is_muted: return
	if not sima_chant_player:
		sima_chant_player = AudioStreamPlayer.new()
		sima_chant_player.name = "SimaChantAudio"
		sima_chant_player.volume_db = -5.0
		add_child(sima_chant_player)
	var sample_hz = 22050
	var duration = 1.8
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Monastic deep resonant Pali chant drone (108Hz / 216Hz) with spinning Kyeezee rotary chime overtone
		var drone_fundamental = sin(t * 108.0 * TAU) * 0.45 * (1.0 - exp(-t * 8.0)) * exp(-t * 1.2)
		var drone_harmonic = sin(t * 216.0 * TAU) * 0.28 * exp(-t * 1.5)
		var spin_mod = sin(t * 9.0 * TAU) * 0.5 + 0.5
		var kyeezee_spin = (sin(t * 1750.0 * TAU) * 0.22 + sin(t * 2350.0 * TAU) * 0.15) * spin_mod * exp(-t * 2.2)
		var val = drone_fundamental + drone_harmonic + kyeezee_spin
		var int_sample = int(clamp(val, -1.0, 1.0) * 23500.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	sima_chant_player.stream = stream
	sima_chant_player.play()

func play_temple_gong_deep() -> void:
	if is_muted: return
	if not deep_gong_player:
		deep_gong_player = AudioStreamPlayer.new()
		deep_gong_player.name = "DeepGongAudio"
		deep_gong_player.volume_db = -4.0
		add_child(deep_gong_player)
	var sample_hz = 22050
	var duration = 2.2
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Massive temple bronze bell gong strike (82Hz) with rich octave harmonics & long warm acoustic decay
		var strike_transient = sin(t * 780.0 * TAU) * exp(-t * 25.0) * 0.4
		var low_drone = sin(t * 82.0 * TAU) * exp(-t * 0.95) * 0.65
		var mid_harmonic = sin(t * 164.0 * TAU) * exp(-t * 1.4) * 0.35
		var high_sing = sin(t * 328.0 * TAU + sin(t * 3.5) * 0.8) * exp(-t * 1.8) * 0.2
		var val = strike_transient + low_drone + mid_harmonic + high_sing
		var int_sample = int(clamp(val, -1.0, 1.0) * 25000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	deep_gong_player.stream = stream
	deep_gong_player.play()

func play_door_lock_click(locked: bool) -> void:
	if is_muted: return
	if not door_lock_player:
		door_lock_player = AudioStreamPlayer.new()
		door_lock_player.name = "DoorLockAudio"
		door_lock_player.volume_db = -6.5
		add_child(door_lock_player)
	var sample_hz = 22050
	var duration = 0.18
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Heavy central locking electric solenoid thunk + metal lock tumbler snap
		var freq1 = 280.0 if locked else 440.0
		var freq2 = 140.0 if locked else 220.0
		var solenoid = sin(t * freq1 * TAU) * exp(-t * 26.0) * 0.55
		var tumbler = sin(t * freq2 * TAU) * exp(-t * 38.0) * 0.4
		var body_thud = 0.0
		if t > 0.04:
			body_thud = sin((t - 0.04) * 95.0 * TAU) * exp(-(t - 0.04) * 28.0) * 0.35
		var val = solenoid + tumbler + body_thud
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	door_lock_player.stream = stream
	door_lock_player.play()

func play_door_latch_pull() -> void:
	if is_muted: return
	if not door_latch_player:
		door_latch_player = AudioStreamPlayer.new()
		door_latch_player.name = "DoorLatchAudio"
		door_latch_player.volume_db = -7.0
		add_child(door_latch_player)
	var sample_hz = 22050
	var duration = 0.22
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Spring-loaded interior chrome pull handle pivot snap + door striker pin release
		var spring_flick = sin(t * 1450.0 * TAU) * exp(-t * 40.0) * 0.35
		var latch_release = sin(t * 360.0 * TAU) * exp(-t * 22.0) * 0.45
		var hollow_door = 0.0
		if t > 0.05:
			hollow_door = sin((t - 0.05) * 120.0 * TAU) * exp(-(t - 0.05) * 18.0) * 0.3
		var val = spring_flick + latch_release + hollow_door
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	door_latch_player.stream = stream
	door_latch_player.play()

func play_banyan_wind_whisper() -> void:
	if is_muted: return
	if not banyan_wind_player:
		banyan_wind_player = AudioStreamPlayer.new()
		banyan_wind_player.name = "BanyanWindAudio"
		banyan_wind_player.volume_db = -6.0
		add_child(banyan_wind_player)
	var sample_hz = 22050
	var duration = 1.6
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep rustling of large sacred Banyan canopy leaves in mountain breeze
		var leaf_rustle1 = sin(t * 240.0 * TAU + sin(t * 7.5) * 1.8) * 0.35 * exp(-t * 1.2)
		var leaf_rustle2 = sin(t * 520.0 * TAU + sin(t * 14.0) * 1.2) * 0.22 * exp(-t * 1.6)
		# Delicate fluttering bronze wind bell chimes
		var chime_spin = sin(t * 8.0 * TAU) * 0.5 + 0.5
		var bell_tinkle = (sin(t * 3400.0 * TAU) * 0.18 + sin(t * 4200.0 * TAU) * 0.12) * chime_spin * exp(-t * 2.5)
		var val = leaf_rustle1 + leaf_rustle2 + bell_tinkle
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	banyan_wind_player.stream = stream
	banyan_wind_player.play()

func play_nat_shrine_chime() -> void:
	if is_muted: return
	if not nat_chime_player:
		nat_chime_player = AudioStreamPlayer.new()
		nat_chime_player.name = "NatChimeAudio"
		nat_chime_player.volume_db = -5.0
		add_child(nat_chime_player)
	var sample_hz = 22050
	var duration = 1.4
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# High-pitched sacred brass wind bell strike with harmonic resonance
		var strike = sin(t * 1850.0 * TAU) * exp(-t * 3.8) * 0.55
		var overtone = sin(t * 2650.0 * TAU) * exp(-t * 5.2) * 0.35
		var hum = sin(t * 925.0 * TAU) * exp(-t * 2.2) * 0.2
		var val = strike + overtone + hum
		var int_sample = int(clamp(val, -1.0, 1.0) * 24000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	nat_chime_player.stream = stream
	nat_chime_player.play()

func play_armrest_latch(is_opening: bool) -> void:
	if is_muted: return
	if not armrest_player:
		armrest_player = AudioStreamPlayer.new()
		armrest_player.name = "ArmrestLatchAudio"
		armrest_player.volume_db = -7.0
		add_child(armrest_player)
	var sample_hz = 22050
	var duration = 0.2
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Mechanical armrest spring button latch click + soft leather cushion thud
		var click_freq = 1650.0 if is_opening else 2400.0
		var latch_click = sin(t * click_freq * TAU) * exp(-t * 35.0) * 0.45
		var hinge_squeak = sin(t * 850.0 * TAU) * exp(-t * 22.0) * 0.2
		var leather_thud = 0.0
		if is_opening:
			if t > 0.05:
				leather_thud = sin((t - 0.05) * 110.0 * TAU) * exp(-(t - 0.05) * 18.0) * 0.25
		else:
			if t > 0.03:
				leather_thud = sin((t - 0.03) * 85.0 * TAU) * exp(-(t - 0.03) * 25.0) * 0.5
		var val = latch_click + hinge_squeak + leather_thud
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	armrest_player.stream = stream
	armrest_player.play()

func play_palm_leaf_manuscript_flip() -> void:
	if is_muted: return
	if not palm_leaf_player:
		palm_leaf_player = AudioStreamPlayer.new()
		palm_leaf_player.name = "PalmLeafAudio"
		palm_leaf_player.volume_db = -6.5
		add_child(palm_leaf_player)
	var sample_hz = 22050
	var duration = 0.28
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Crisp dry rustling of inscribed sacred palm-leaf folios (Pe-Sar) and silk ribbon tie
		var leaf_rustle = sin(t * 850.0 * TAU + sin(t * 22.0) * 1.5) * exp(-t * 14.0) * 0.4
		var dry_flex = sin(t * 420.0 * TAU) * exp(-t * 18.0) * 0.3
		var cord_slide = 0.0
		if t > 0.08:
			cord_slide = sin((t - 0.08) * 1850.0 * TAU) * exp(-(t - 0.08) * 32.0) * 0.22
		var val = leaf_rustle + dry_flex + cord_slide
		var int_sample = int(clamp(val, -1.0, 1.0) * 22500.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	palm_leaf_player.stream = stream
	palm_leaf_player.play()

func play_sacred_temple_chime() -> void:
	if is_muted: return
	if not temple_chime_player:
		temple_chime_player = AudioStreamPlayer.new()
		temple_chime_player.name = "TempleChimeAudio"
		temple_chime_player.volume_db = -4.5
		add_child(temple_chime_player)
	var sample_hz = 22050
	var duration = 1.9
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep monastery bronze bell strike (95Hz) with high rotary Kyeezee shimmer (1850Hz)
		var bell_drone = sin(t * 95.0 * TAU) * exp(-t * 1.1) * 0.55
		var bell_harmonic = sin(t * 190.0 * TAU) * exp(-t * 1.6) * 0.3
		var kyeezee_spin = sin(t * 10.0 * TAU) * 0.5 + 0.5
		var rotary_shimmer = sin(t * 1850.0 * TAU) * kyeezee_spin * exp(-t * 2.8) * 0.22
		var val = bell_drone + bell_harmonic + rotary_shimmer
		var int_sample = int(clamp(val, -1.0, 1.0) * 24500.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	temple_chime_player.stream = stream
	temple_chime_player.play()

func play_fog_light_switch() -> void:
	if is_muted: return
	if not fog_switch_player:
		fog_switch_player = AudioStreamPlayer.new()
		fog_switch_player.name = "FogSwitchAudio"
		fog_switch_player.volume_db = -6.5
		add_child(fog_switch_player)
	var sample_hz = 22050
	var duration = 0.16
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Heavy rocker switch snap + automotive lighting relay click
		var switch_snap = sin(t * 1950.0 * TAU) * exp(-t * 36.0) * 0.45
		var relay_clunk = sin(t * 380.0 * TAU) * exp(-t * 22.0) * 0.35
		var contact_thud = 0.0
		if t > 0.03:
			contact_thud = sin((t - 0.03) * 85.0 * TAU) * exp(-(t - 0.03) * 28.0) * 0.4
		var val = switch_snap + relay_clunk + contact_thud
		var int_sample = int(clamp(val, -1.0, 1.0) * 22000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	fog_switch_player.stream = stream
	fog_switch_player.play()
var bridge_creak_player: AudioStreamPlayer = null
var river_gorge_player: AudioStreamPlayer = null

func play_suspension_bridge_creak() -> void:
	if is_muted: return
	if not bridge_creak_player:
		bridge_creak_player = AudioStreamPlayer.new()
		bridge_creak_player.name = "SuspensionBridgeCreakAudio"
		bridge_creak_player.volume_db = -5.5
		add_child(bridge_creak_player)
	var sample_hz = 22050
	var duration = 0.55
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Deep teak timber flex groan (180-240Hz)
		var wood_freq = 190.0 + sin(t * 14.0 * TAU) * 35.0
		var wood_groan = sin(t * wood_freq * TAU) * exp(-t * 4.8) * 0.45
		# Steel cable tension creak/friction squeak (1200-1450Hz)
		var cable_friction = sin(t * (1320.0 + sin(t * 24.0 * TAU) * 110.0) * TAU) * exp(-t * 6.5) * 0.25
		# Footstep plank settle thump
		var thump = sin(t * 75.0 * TAU) * exp(-t * 9.0) * 0.35
		var val = wood_groan + cable_friction + thump
		var int_sample = int(clamp(val, -1.0, 1.0) * 23000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	bridge_creak_player.stream = stream
	bridge_creak_player.play()

func play_river_gorge_breeze() -> void:
	if is_muted: return
	if not river_gorge_player:
		river_gorge_player = AudioStreamPlayer.new()
		river_gorge_player.name = "RiverGorgeBreezeAudio"
		river_gorge_player.volume_db = -8.0
		add_child(river_gorge_player)
	var sample_hz = 22050
	var duration = 1.2
	var total_frames = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	var data = PackedByteArray()
	data.resize(total_frames * 2)
	for i in range(total_frames):
		var t = float(i) / float(sample_hz)
		# Low valley gorge wind sweep
		var wind_freq = 220.0 + sin(t * 1.8 * TAU) * 45.0
		var wind = sin(t * wind_freq * TAU) * sin(t / duration * PI) * 0.38
		# Cable Aeolian whistle harmonic
		var cable_whistle = sin(t * 540.0 * TAU) * sin(t / duration * PI) * 0.18
		# River rush water murmur (pink-ish mod)
		var river_ripple = sin(t * 140.0 * TAU) * sin(t * 12.0 * TAU) * sin(t / duration * PI) * 0.28
		var val = wind + cable_whistle + river_ripple
		var int_sample = int(clamp(val, -1.0, 1.0) * 21000.0)
		data.encode_s16(i * 2, int_sample)
	stream.data = data
	river_gorge_player.stream = stream
	river_gorge_player.play()
