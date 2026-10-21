extends Node

# --- Authentic Myanmar Ambient & Sound Effects Generator ---
# Procedural Synthesized Audio Streams for Mobile Performance

var monastery_bell_player: AudioStreamPlayer
var cow_moo_player: AudioStreamPlayer
var vehicle_engine_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var teashop_chime_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()

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
