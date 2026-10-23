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

const RADIO_STATIONS: Array[String] = [
	"📻 ရေဒီယို: ပိတ်ထားသည် (Off)",
	"📻 ရေဒီယို: မြန်မာအကူးစတစ်နှင့် ပလွေ (Acoustic & Flute)",
	"📻 ရေဒီယို: သဘာဝတောတောင်နှင့် လေညင်း (Mountain Wind)",
	"📻 ရေဒီယို: ရိုးရာစောင်းနှင့် အေးချမ်းသံ (Harp & Chimes)"
]

func cycle_radio_station() -> String:
	radio_station_index = (radio_station_index + 1) % RADIO_STATIONS.size()
	_apply_radio_station()
	return RADIO_STATIONS[radio_station_index]

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