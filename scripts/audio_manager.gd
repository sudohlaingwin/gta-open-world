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
var bird_ambient_timer: float = 3.0
var river_ambient_timer: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()

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
			if dist_to_river < 40.0:
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