extends VehicleBody3D

@export var max_engine_force: float = 850.0
@export var max_brake_force: float = 80.0
@export var low_speed_steer_angle: float = 0.52
@export var high_speed_steer_angle: float = 0.22
@export var top_speed_ms: float = 28.0

var current_driver: Node3D = null
var is_driven: bool = false
var smoothed_steering: float = 0.0

@onready var driver_seat: Marker3D = $DriverSeat
@onready var interaction_area: Area3D = $InteractionArea
@onready var headlight_beam_l: SpotLight3D = get_node_or_null("HeadlightBeamL")
@onready var headlight_beam_r: SpotLight3D = get_node_or_null("HeadlightBeamR")
@onready var headlight_mesh_l: MeshInstance3D = get_node_or_null("HeadlightL")
@onready var headlight_mesh_r: MeshInstance3D = get_node_or_null("HeadlightR")
@onready var taillight_mesh_l: MeshInstance3D = get_node_or_null("TaillightL")
@onready var taillight_mesh_r: MeshInstance3D = get_node_or_null("TaillightR")
@onready var tire_smoke_l: CPUParticles3D = get_node_or_null("TireSmokeL")
@onready var tire_smoke_r: CPUParticles3D = get_node_or_null("TireSmokeR")
@onready var nitro_flame: CPUParticles3D = get_node_or_null("NitroFlame")
@onready var body_mesh: MeshInstance3D = get_node_or_null("BodyMesh")
@onready var charm_pivot: Node3D = get_node_or_null("HangingCharmPivot")
@onready var wiper_pivot_l: Node3D = get_node_or_null("WiperPivotL")
@onready var wiper_pivot_r: Node3D = get_node_or_null("WiperPivotR")
@onready var side_window_l: MeshInstance3D = get_node_or_null("SideWindowL")
@onready var side_window_r: MeshInstance3D = get_node_or_null("SideWindowR")
@onready var dashboard_display: Label3D = get_node_or_null("DashboardDisplay")
@onready var ac_led: MeshInstance3D = get_node_or_null("ACIndicatorLED")
var ac_level: int = 0
var cabin_temp: float = 32.0
var dome_light_on: bool = false
var total_odometer_km: float = 0.0
var trip_km: float = 0.0
@onready var dome_light: OmniLight3D = get_node_or_null("DomeLightFixture/DomeLight")
@onready var dome_lens: MeshInstance3D = get_node_or_null("DomeLightFixture/DomeLightGlass")
@onready var trip_display: Label3D = get_node_or_null("TripCounterDisplay")
var glovebox_open: bool = false
@onready var glove_door: MeshInstance3D = get_node_or_null("GloveCompartmentPivot/GloveDoor")
@onready var steering_wheel_pivot: Node3D = get_node_or_null("SteeringWheelPivot")
@onready var stalk_pivot: Node3D = get_node_or_null("TurnSignalStalkPivot")
var vanity_shutter_open: bool = false
@onready var vanity_shutter: MeshInstance3D = get_node_or_null("SunVisorPivotR/VanityShutterCover")
@onready var gear_shift_pivot: Node3D = get_node_or_null("GearShiftAssembly/GearShiftLeverPivot")
@onready var shift_indicator: Label3D = get_node_or_null("GearShiftAssembly/ShiftIndicatorDisplay")
var current_gear: String = "D"
@onready var handbrake_pivot: Node3D = get_node_or_null("HandbrakeLeverAssembly/HandbrakePivot")
@onready var brake_warning_display: Label3D = get_node_or_null("HandbrakeLeverAssembly/BrakeWarningDisplay")
var handbrake_engaged: bool = false
@onready var ignition_key_pivot: Node3D = get_node_or_null("IgnitionKeyAssembly/IgnitionKeyPivot")
@onready var keyring_pivot: Node3D = get_node_or_null("IgnitionKeyAssembly/IgnitionKeyPivot/DanglingKeyringPivot")
var engine_ignition_on: bool = true
var keyring_roll: float = 0.0
var keyring_roll_vel: float = 0.0
var keyring_pitch: float = 0.0
var keyring_pitch_vel: float = 0.0
@onready var speedo_needle: Node3D = get_node_or_null("InstrumentCluster/SpeedometerDial/SpeedoNeedlePivot")
@onready var tacho_needle: Node3D = get_node_or_null("InstrumentCluster/TachometerDial/TachoNeedlePivot")
@onready var cluster_backlight: OmniLight3D = get_node_or_null("InstrumentCluster/ClusterBacklight")
@onready var throttle_pivot: Node3D = get_node_or_null("PedalsAssembly/ThrottlePivot")
@onready var brake_pivot: Node3D = get_node_or_null("PedalsAssembly/BrakePivot")
@onready var footwell_light: OmniLight3D = get_node_or_null("PedalsAssembly/FootwellLight")
var prev_throttle_depressed: bool = false
var prev_brake_depressed: bool = false
var doors_locked: bool = false
@onready var lock_peg_l: MeshInstance3D = get_node_or_null("DoorInteriorAssembly/DoorInteriorL/LockPegL")
@onready var lock_peg_r: MeshInstance3D = get_node_or_null("DoorInteriorAssembly/DoorInteriorR/LockPegR")
@onready var handle_pivot_l: Node3D = get_node_or_null("DoorInteriorAssembly/DoorInteriorL/HandlePivotL")
@onready var handle_pivot_r: Node3D = get_node_or_null("DoorInteriorAssembly/DoorInteriorR/HandlePivotR")
var armrest_open: bool = false
@onready var armrest_lid_pivot: Node3D = get_node_or_null("CenterConsoleArmrestAssembly/ArmrestLidPivot")
var fog_lights_on: bool = false
@onready var fog_light_l: MeshInstance3D = get_node_or_null("FogLampAssembly/FogLightL")
@onready var fog_light_r: MeshInstance3D = get_node_or_null("FogLampAssembly/FogLightR")
@onready var fog_beam_l: SpotLight3D = get_node_or_null("FogLampAssembly/FogBeamL")
@onready var fog_beam_r: SpotLight3D = get_node_or_null("FogLampAssembly/FogBeamR")
@onready var fog_indicator_display: Label3D = get_node_or_null("FogLampAssembly/FogIndicatorDisplay")
var engine_rpm: float = 0.0
var rev_limiter_cooldown: float = 0.0
var aroma_diffuser_active: bool = false
@onready var aroma_particles: CPUParticles3D = get_node_or_null("AirFreshenerDiffuser/DiffuserBottle/AromaVaporParticles")
var sun_visors_down: bool = false
@onready var visor_pivot_l: Node3D = get_node_or_null("SunVisorPivotL")
@onready var visor_pivot_r: Node3D = get_node_or_null("SunVisorPivotR")
@onready var exhaust_backfire: CPUParticles3D = get_node_or_null("ExhaustBackfire")
@onready var radio_eq_display: Label3D = get_node_or_null("RadioEqualizerDisplay")
@onready var turn_signal_fl: MeshInstance3D = get_node_or_null("TurnSignalFL")
@onready var turn_signal_fr: MeshInstance3D = get_node_or_null("TurnSignalFR")
@onready var turn_signal_bl: MeshInstance3D = get_node_or_null("TurnSignalBL")
@onready var turn_signal_br: MeshInstance3D = get_node_or_null("TurnSignalBR")
@onready var hazard_display: Label3D = get_node_or_null("HazardBlinkerDisplay")
@onready var rearview_mirror: MeshInstance3D = get_node_or_null("RearviewMirror")

var prev_throttle_input: float = 0.0
var prev_boosting: bool = false
var eq_frame_timer: float = 0.0
var eq_frame_index: int = 0
const VU_BARS: Array[String] = [
	"[ ▅█▇▅▃ ]",
	"[ ▃▅█▇▅ ]",
	"[ ▂▄▆█▄ ]",
	"[ ▄▆█▇▆ ]",
	"[ ▆▇█▆▄ ]",
	"[ ▃▅▆▅▃ ]",
	"[ ▄▆▇█▇ ]",
	"[ █▇▆▅▃ ]"
]

var charm_roll: float = 0.0
var charm_roll_vel: float = 0.0
var charm_pitch: float = 0.0
var charm_pitch_vel: float = 0.0
var wipers_active: bool = false
var wiper_phase: float = 0.0
var last_wiper_dir: float = 0.0

var hazard_active: bool = false
var blinker_timer: float = 0.0
var blinker_state: bool = false

var mirror_antiglare_active: bool = false
const MIRROR_ROT_NORMAL: float = 0.173648
const MIRROR_ROT_ANTIGLARE: float = 0.244346

func cycle_transmission_gear() -> String:
	var next_gear = "D"
	match current_gear:
		"P": next_gear = "R"
		"R": next_gear = "N"
		"N": next_gear = "D"
		"D": next_gear = "P"
	_set_gear_state(next_gear)
	var gear_desc = "P (ရပ်နား/ပါကင်)"
	match current_gear:
		"R": gear_desc = "R (နောက်ဆုတ်)"
		"N": gear_desc = "N (ဂီယာလွတ်)"
		"D": gear_desc = "D (ရှေ့သို့မောင်းနှင်)"
	return "⚙️ ဂီယာ: [%s] သို့ ပြောင်းလဲလိုက်ပါသည်" % gear_desc

func _set_gear_state(p_gear: String) -> void:
	if current_gear != p_gear:
		current_gear = p_gear
		var am_shift = get_tree().get_first_node_in_group("audio_manager")
		if am_shift and am_shift.has_method("play_gear_shift"):
			am_shift.play_gear_shift()
		if shift_indicator:
			match current_gear:
				"P":
					shift_indicator.text = "[P]  R   N   D"
					shift_indicator.modulate = Color(1.0, 0.42, 0.35, 1.0)
				"R":
					shift_indicator.text = " P  [R]  N   D"
					shift_indicator.modulate = Color(1.0, 0.58, 0.25, 1.0)
				"N":
					shift_indicator.text = " P   R  [N]  D"
					shift_indicator.modulate = Color(0.95, 0.9, 0.35, 1.0)
				"D":
					shift_indicator.text = " P   R   N  [D]"
					shift_indicator.modulate = Color(0.25, 1.0, 0.55, 1.0)
func toggle_engine_ignition() -> String:
	engine_ignition_on = !engine_ignition_on
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am:
		if am.has_method("play_ignition_key_turn"):
			am.play_ignition_key_turn()
		if engine_ignition_on and am.has_method("play_engine_crank"):
			am.play_engine_crank()
	if ignition_key_pivot:
		ignition_key_pivot.rotation.z = deg_to_rad(45.0) if engine_ignition_on else 0.0
	if engine_ignition_on:
		return "🔑 စက်နှိုးခလုတ်: စက်နှိုးထားသည် (Engine ON - Key Turned)"
	else:
		engine_force = 0.0
		return "🔑 စက်နှိုးခလုတ်: စက်သတ်လိုက်သည် (Engine OFF - Key Turned LOCK)"
func toggle_handbrake() -> String:
	handbrake_engaged = !handbrake_engaged
	var am = get_tree().get_first_node_in_group("audio_manager")
	if handbrake_engaged:
		if am and am.has_method("play_handbrake_ratchet"):
			am.play_handbrake_ratchet()
		if brake_warning_display:
			brake_warning_display.visible = true
		return "🅿️ လက်ဘရိတ်: ဆွဲထားသည် (Handbrake ENGAGED - Wheels Locked)"
	else:
		if am and am.has_method("play_handbrake_release"):
			am.play_handbrake_release()
		if brake_warning_display:
			brake_warning_display.visible = false
		return "🅿️ လက်ဘရိတ်: ဖြုတ်လိုက်သည် (Handbrake RELEASED)"
func sip_iced_tea() -> String:
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_straw_sip"):
		am.play_straw_sip()
	if current_driver and current_driver.get("stamina") != null:
		current_driver.stamina = minf(current_driver.stamina + 25.0, 100.0)
	return "🥤 ရိုးရာ လက်ဖက်ရည် အအေးခွက်မှ တစ်ငုံ အရသာခံ သောက်သုံးလိုက်ပါသည် (အမောပြေ စွမ်းအင်တိုး)"

func toggle_aroma_diffuser() -> String:
	aroma_diffuser_active = !aroma_diffuser_active
	if aroma_particles:
		aroma_particles.emitting = aroma_diffuser_active
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_diffuser_spray"):
		am.play_diffuser_spray()
	return "🌸 သဘာဝ သံပရာရနံ့ ကားလေမွှေး: ဖွင့်ထားသည် (Natural Citrus Scent ON)" if aroma_diffuser_active else "🌸 ကားလေမွှေး: ပိတ်ထားသည် (Diffuser OFF)"

func toggle_vanity_mirror() -> String:
	vanity_shutter_open = !vanity_shutter_open
	if vanity_shutter:
		vanity_shutter.position.x = 0.24 if vanity_shutter_open else 0.08
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_vanity_slide"):
		am.play_vanity_slide(vanity_shutter_open)
	return "🪞 ဘေးခုံ နေကာပြားမှန်: အဖုံးဖွင့်ထားသည် (Vanity Mirror Open)" if vanity_shutter_open else "🪞 ဘေးခုံ နေကာပြားမှန်: အဖုံးပိတ်ထားသည် (Vanity Mirror Closed)"

func toggle_sun_visors() -> String:
	sun_visors_down = !sun_visors_down
	var target_rot = 1.15 if sun_visors_down else 0.0
	if visor_pivot_l: visor_pivot_l.rotation.x = target_rot
	if visor_pivot_r: visor_pivot_r.rotation.x = target_rot
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_sun_visor_flip"):
		am.play_sun_visor_flip(sun_visors_down)
	return "☀️ နေကာပြား: ချထားသည် (နေရောင်ကာကွယ်မှု ON)" if sun_visors_down else "☀️ နေကာပြား: ပြန်တင်ထားသည် (Sun Visors UP)"

func toggle_glovebox() -> String:
	glovebox_open = !glovebox_open
	if glove_door:
		glove_door.rotation.x = -0.58 if glovebox_open else 0.0
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_glovebox_latch"):
		am.play_glovebox_latch(glovebox_open)
	return "📦 အံဆွဲ: ဖွင့်ထားသည် (ရိုးရာကွမ်းအစ်နှင့် ခရီးဆောင်မြေပုံ)" if glovebox_open else "📦 အံဆွဲ: ပြန်ပိတ်ထားသည် (Glove Box Closed)"

func toggle_fog_lights() -> String:
	fog_lights_on = !fog_lights_on
	if fog_beam_l: fog_beam_l.visible = fog_lights_on
	if fog_beam_r: fog_beam_r.visible = fog_lights_on
	if fog_indicator_display: fog_indicator_display.visible = fog_lights_on
	if fog_light_l:
		var mat = fog_light_l.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_enabled = fog_lights_on
	if fog_light_r:
		var mat = fog_light_r.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_enabled = fog_lights_on
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_fog_light_switch"):
		am.play_fog_light_switch()
	return "🌫️ မြူနှင်းခွဲမီး: ဖွင့်ထားသည် (Selective Amber Fog Lamps ON)" if fog_lights_on else "🌫️ မြူနှင်းခွဲမီး: ပိတ်ထားသည် (Fog Lamps OFF)"

func toggle_console_armrest() -> String:
	armrest_open = !armrest_open
	if armrest_lid_pivot:
		armrest_lid_pivot.rotation.x = deg_to_rad(65.0) if armrest_open else 0.0
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_armrest_latch"):
		am.play_armrest_latch(armrest_open)
	return "🧰 လက်တင်အံဆွဲ: ဖွင့်ထားသည် (၁၀၀၀၀ တန် ငွေစက္ကူထပ်နှင့် နေကာမျက်မှန်)" if armrest_open else "🧰 လက်တင်အံဆွဲ: ပြန်ပိတ်ထားသည် (Console Armrest Closed)"

func toggle_door_locks() -> String:
	doors_locked = !doors_locked
	var peg_target_y = 0.165 if doors_locked else 0.185
	if lock_peg_l: lock_peg_l.position.y = peg_target_y
	if lock_peg_r: lock_peg_r.position.y = peg_target_y
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_door_lock_click"):
		am.play_door_lock_click(doors_locked)
	return "🔒 ဗဟိုတံခါးလော့ခ်: လော့ခ်ချထားသည် (Central Door Locks ENGAGED)" if doors_locked else "🔓 ဗဟိုတံခါးလော့ခ်: ဖွင့်လိုက်သည် (Doors UNLOCKED)"

func toggle_dome_light() -> String:
	dome_light_on = !dome_light_on
	if dome_light:
		dome_light.visible = dome_light_on
		dome_light.light_energy = 1.9 if dome_light_on else 0.0
	if dome_lens:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.95, 0.8, 1.0)
		mat.emission_enabled = dome_light_on
		mat.emission = Color(1.0, 0.88, 0.65, 1.0)
		mat.emission_energy_multiplier = 2.5 if dome_light_on else 0.0
		dome_lens.set_surface_override_material(0, mat)
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_dome_light_click"):
		am.play_dome_light_click()
		if footwell_light:
		footwell_light.visible = (dome_light_on or not is_driven)
	return "💡 အတွင်းခန်းမီး: ဖွင့်ထားသည် (Cabin Light ON)" if dome_light_on else "💡 အတွင်းခန်းမီး: ပိတ်ထားသည် (Cabin Light OFF)"

func toggle_ac() -> String:
	ac_level = (ac_level + 1) % 3
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_ac_blower"):
		am.play_ac_blower(ac_level)

	if ac_led:
		var mat = StandardMaterial3D.new()
		if ac_level == 0:
			mat.albedo_color = Color(0.12, 0.14, 0.16, 1.0)
			mat.emission_enabled = false
		elif ac_level == 1:
			mat.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.85, 1.0, 1.0)
			mat.emission_energy_multiplier = 2.4
		else:
			mat.albedo_color = Color(0.6, 1.0, 1.0, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.5, 0.95, 1.0, 1.0)
			mat.emission_energy_multiplier = 4.2
		ac_led.set_surface_override_material(0, mat)

	if ac_level == 0:
		return "❄️ လေအေးပေးစက်: ပိတ်ထားသည် (A/C OFF ☀️)"
	elif ac_level == 1:
		return "❄️ လေအေးပေးစက်: အဆင့် ၁ (လေနုအေး 22°C)"
	else:
		return "❄️❄️ လေအေးပေးစက်: အဆင့် ၂ (အအေးဆုံး မုန်တိုင်းလေ 18°C)"

func toggle_rearview_mirror() -> String:
	mirror_antiglare_active = !mirror_antiglare_active
	if rearview_mirror:
		if mirror_antiglare_active:
			rearview_mirror.rotation.x = -MIRROR_ROT_ANTIGLARE
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.18, 0.35, 0.28, 1.0)
			mat.metallic = 0.92
			mat.roughness = 0.12
			mat.specular = 0.65
			rearview_mirror.set_surface_override_material(0, mat)
		else:
			rearview_mirror.rotation.x = -MIRROR_ROT_NORMAL
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.85, 0.90, 0.95, 1.0)
			mat.metallic = 0.98
			mat.roughness = 0.08
			mat.specular = 0.95
			rearview_mirror.set_surface_override_material(0, mat)
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_mirror_flip"):
		am.play_mirror_flip()
	return "🪞 နောက်ကြည့်မှန်: ညဘက်အလင်းပြန်ကာစနစ် (Anti-Glare ON)" if mirror_antiglare_active else "🪞 နောက်ကြည့်မှန်: ပုံမှန်အကြည် (Day Mode)"

func toggle_hazard_lights() -> String:
	if stalk_pivot:
		stalk_pivot.rotation.z = 0.24 if not hazard_active else 0.0
	var am_stalk = get_tree().get_first_node_in_group("audio_manager")
	if am_stalk and am_stalk.has_method("play_stalk_click"):
		am_stalk.play_stalk_click()
	hazard_active = !hazard_active
	if not hazard_active:
		_set_blinkers_visible(false)
		return "⚠️ အရေးပေါ်မီး: ပိတ်ထားသည် (Hazard Lights OFF)"
	else:
		blinker_timer = 0.0
		blinker_state = true
		_set_blinkers_visible(true)
		var am = get_tree().get_first_node_in_group("audio_manager")
		if am and am.has_method("play_turn_signal_tick"):
			am.play_turn_signal_tick(true)
		return "⚠️ အရေးပေါ်မီး: ဖွင့်ထားသည် (Hazard Lights ON)"

func _set_blinkers_visible(p_vis: bool) -> void:
	if turn_signal_fl: turn_signal_fl.visible = p_vis
	if turn_signal_fr: turn_signal_fr.visible = p_vis
	if turn_signal_bl: turn_signal_bl.visible = p_vis
	if turn_signal_br: turn_signal_br.visible = p_vis
	if hazard_display: hazard_display.visible = p_vis

func toggle_wipers() -> String:
	wipers_active = !wipers_active
	if wipers_active:
		var am = get_tree().get_first_node_in_group("audio_manager")
		if am and am.has_method("play_wiper_sweep"):
			am.play_wiper_sweep()
		return "🌧️ မိုးရေသုတ်တံ: ဖွင့်ထားသည် (Wipers ON)"
	else:
		if wiper_pivot_l: wiper_pivot_l.rotation.z = 0.0
		if wiper_pivot_r: wiper_pivot_r.rotation.z = 0.0
		return "🌧️ မိုးရေသုတ်တံ: ပိတ်ထားသည် (Wipers OFF)"

signal driver_entered(driver)
signal driver_exited()

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

enum HeadlightMode { AUTO, HIGH_BEAM, LOW_BEAM, OFF }
var headlight_mode: HeadlightMode = HeadlightMode.AUTO

func _update_headlights() -> void:
	var dnc = get_tree().get_first_node_in_group("day_night")
	var is_night = false
	if dnc and dnc.has_method("get_daylight"):
		is_night = (dnc.get_daylight() < 0.35)

	var lights_on = false
	var range_val = 42.0
	var energy_val = 3.2
	var angle_val = 42.0
	var light_col = Color(1.0, 0.96, 0.88, 1.0)

	match headlight_mode:
		HeadlightMode.AUTO:
			lights_on = is_night or is_driven
			range_val = 42.0
			energy_val = 3.2
			angle_val = 42.0
			light_col = Color(1.0, 0.96, 0.88, 1.0)
		HeadlightMode.HIGH_BEAM:
			lights_on = true
			range_val = 90.0
			energy_val = 4.8
			angle_val = 50.0
			light_col = Color(0.92, 0.96, 1.0, 1.0)
		HeadlightMode.LOW_BEAM:
			lights_on = true
			range_val = 28.0
			energy_val = 2.0
			angle_val = 32.0
			light_col = Color(1.0, 0.94, 0.82, 1.0)
		HeadlightMode.OFF:
			lights_on = false

	if headlight_beam_l:
		headlight_beam_l.visible = lights_on
		headlight_beam_l.spot_range = range_val
		headlight_beam_l.light_energy = energy_val
		headlight_beam_l.spot_angle = angle_val
		headlight_beam_l.light_color = light_col
	if headlight_beam_r:
		headlight_beam_r.visible = lights_on
		headlight_beam_r.spot_range = range_val
		headlight_beam_r.light_energy = energy_val
		headlight_beam_r.spot_angle = angle_val
		headlight_beam_r.light_color = light_col
	if headlight_mesh_l:
		var mat = headlight_mesh_l.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_enabled = lights_on
			mat.emission_energy_multiplier = 4.2 if headlight_mode == HeadlightMode.HIGH_BEAM else 2.5
	if headlight_mesh_r:
		var mat = headlight_mesh_r.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_enabled = lights_on
			mat.emission_energy_multiplier = 4.2 if headlight_mode == HeadlightMode.HIGH_BEAM else 2.5
	if taillight_mesh_l:
		var mat = taillight_mesh_l.get_surface_override_material(0)
		if mat is StandardMaterial3D: mat.emission_enabled = lights_on
	if taillight_mesh_r:
		var mat = taillight_mesh_r.get_surface_override_material(0)
		if mat is StandardMaterial3D: mat.emission_enabled = lights_on

func cycle_headlight_mode() -> String:
	headlight_mode = ((headlight_mode + 1) % 4) as HeadlightMode
	_update_headlights()
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am and am.has_method("play_headlight_switch"):
		am.play_headlight_switch()
	match headlight_mode:
		HeadlightMode.AUTO: return "💡 ရှေ့မီး: အလိုအလျောက် (Auto)"
		HeadlightMode.HIGH_BEAM: return "💡 ရှေ့မီး: မီးကြီး (High Beam 90m)"
		HeadlightMode.LOW_BEAM: return "💡 ရှေ့မီး: မီးနိမ့် (Low Beam 28m)"
		HeadlightMode.OFF: return "💡 ရှေ့မီး: ပိတ်ထားသည် (Off)"
	return ""

func _physics_process(delta: float) -> void:
	_update_headlights()
	var target_slide = 1.0 if windows_down else 0.0
	window_slide_pos = move_toward(window_slide_pos, target_slide, delta * 1.8)
	if hazard_active:
		blinker_timer += delta
		if blinker_timer >= 0.35:
			blinker_timer = 0.0
			blinker_state = !blinker_state
			_set_blinkers_visible(blinker_state)
			var am_tick = get_tree().get_first_node_in_group("audio_manager")
			if am_tick and am_tick.has_method("play_turn_signal_tick"):
				am_tick.play_turn_signal_tick(blinker_state)
	var cur_window_y = lerpf(WINDOW_Y_CLOSED, WINDOW_Y_OPEN, window_slide_pos)
	if side_window_l:
		side_window_l.position.y = cur_window_y
	if side_window_r:
		side_window_r.position.y = cur_window_y
	if wipers_active and (wiper_pivot_l or wiper_pivot_r):
		wiper_phase += delta * 4.2
		var sweep = (sin(wiper_phase) * 0.5 + 0.5)
		var sweep_angle = deg_to_rad(lerpf(0.0, 72.0, sweep))
		if wiper_pivot_l: wiper_pivot_l.rotation.z = -sweep_angle
		if wiper_pivot_r: wiper_pivot_r.rotation.z = -sweep_angle
		var cur_dir = cos(wiper_phase)
		if (last_wiper_dir > 0.0 and cur_dir <= 0.0) or (last_wiper_dir < 0.0 and cur_dir >= 0.0):
			var am = get_tree().get_first_node_in_group("audio_manager")
			if am and am.has_method("play_wiper_sweep"):
				am.play_wiper_sweep()
		last_wiper_dir = cur_dir

	if is_driven and current_driver:
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if current_driver.get("touch_input_vector") != null and current_driver.touch_input_vector != Vector2.ZERO:
			input_dir = current_driver.touch_input_vector

		var forward_speed = linear_velocity.dot(-global_transform.basis.z)
		var speed_ratio = clamp(abs(forward_speed) / top_speed_ms, 0.0, 1.0)

		# Speed-Dependent Steering (Agile at low speeds, high-speed stability)
		var target_steer_limit = lerp(low_speed_steer_angle, high_speed_steer_angle, speed_ratio)
		var target_steering = -input_dir.x * target_steer_limit
		smoothed_steering = move_toward(smoothed_steering, target_steering, 8.0 * delta)
		steering = smoothed_steering

		var sw = get_node_or_null("SteeringWheel")
		if sw:
			sw.rotation.z = -smoothed_steering * 3.8

		if dashboard_display:
			var dnc = get_tree().get_first_node_in_group("day_night")
			var time_str = dnc.get_time_string() if (dnc and dnc.has_method("get_time_string")) else "02:30 PM"
			var temp_c = dnc.get_ambient_temp_celsius() if (dnc and dnc.has_method("get_ambient_temp_celsius")) else 30
			var fwd = -global_transform.basis.z
			var ang = atan2(fwd.x, -fwd.z)
			var deg = wrapf(rad_to_deg(ang), 0.0, 360.0)
			var compass_dir = "N"
			if deg >= 337.5 or deg < 22.5: compass_dir = "N"
			elif deg < 67.5: compass_dir = "NE"
			elif deg < 112.5: compass_dir = "E"
			elif deg < 157.5: compass_dir = "SE"
			elif deg < 202.5: compass_dir = "S"
			elif deg < 247.5: compass_dir = "SW"
			elif deg < 292.5: compass_dir = "W"
			else: compass_dir = "NW"
						if ac_level == 0:
				cabin_temp = lerpf(cabin_temp, float(temp_c), delta * 0.08)
			elif ac_level == 1:
				cabin_temp = lerpf(cabin_temp, 22.0, delta * 0.15)
			else:
				cabin_temp = lerpf(cabin_temp, 17.5, delta * 0.28)
			var ac_str = "☀️"
			if ac_level == 1: ac_str = "❄️L1"
			elif ac_level == 2: ac_str = "❄️❄️MAX"
						dashboard_display.text = "%s | %s | %d°C %s | %d KM/H" % [time_str, compass_dir, int(cabin_temp), ac_str, int(abs(forward_speed) * 3.6)]

		# 3D Backlit Analog Speedometer & Tachometer Needles with Live Sweeping Motion
		var cur_speed_kmh = abs(forward_speed) * 3.6
		var target_speedo_rot = lerpf(deg_to_rad(135.0), -deg_to_rad(135.0), clampf(cur_speed_kmh / 180.0, 0.0, 1.0))
		if speedo_needle:
			speedo_needle.rotation.y = lerpf(speedo_needle.rotation.y, target_speedo_rot, delta * 12.0)

		var target_rpm = 0.0
		if engine_ignition_on:
			var throttle_val = -input_dir.y if input_dir.y < -0.05 else 0.0
			target_rpm = 850.0 + (throttle_val * 4800.0) + (speed_ratio * 2200.0)
			if is_boosting: target_rpm += 900.0
			target_rpm = clampf(target_rpm, 800.0, 7800.0)
			if target_rpm >= 7400.0:
				rev_limiter_cooldown -= delta
				if rev_limiter_cooldown <= 0.0:
					rev_limiter_cooldown = 0.16
					var am_rev = get_tree().get_first_node_in_group("audio_manager")
					if am_rev and am_rev.has_method("play_rev_limiter"):
						am_rev.play_rev_limiter()
		engine_rpm = lerpf(engine_rpm, target_rpm, delta * 14.0)
		var target_tacho_rot = lerpf(deg_to_rad(135.0), -deg_to_rad(135.0), clampf(engine_rpm / 8000.0, 0.0, 1.0))
		if tacho_needle:
			tacho_needle.rotation.y = lerpf(tacho_needle.rotation.y, target_tacho_rot, delta * 14.0)

		# 3D In-Cabin Foot Pedals Live Articulation & Mechanical Spring Physics
		var throttle_input_raw = -input_dir.y if input_dir.y < -0.05 else 0.0
		var brake_input_raw = input_dir.y if input_dir.y > 0.05 else (1.0 if handbrake_engaged else 0.0)
		var target_throttle_angle = deg_to_rad(-18.0) * clampf(throttle_input_raw, 0.0, 1.0)
		if throttle_pivot:
			throttle_pivot.rotation.x = lerpf(throttle_pivot.rotation.x, target_throttle_angle, delta * 16.0)
		var target_brake_angle = deg_to_rad(15.0) * clampf(brake_input_raw, 0.0, 1.0)
		if brake_pivot:
			brake_pivot.rotation.x = lerpf(brake_pivot.rotation.x, target_brake_angle, delta * 18.0)
		var is_throttle_down = (throttle_input_raw > 0.15)
		if is_throttle_down and not prev_throttle_depressed:
			var am_pedal = get_tree().get_first_node_in_group("audio_manager")
			if am_pedal and am_pedal.has_method("play_throttle_press"):
				am_pedal.play_throttle_press()
		prev_throttle_depressed = is_throttle_down
		var is_brake_down = (brake_input_raw > 0.15)
		if is_brake_down and not prev_brake_depressed:
			var am_pedal = get_tree().get_first_node_in_group("audio_manager")
			if am_pedal and am_pedal.has_method("play_brake_pedal_press"):
				am_pedal.play_brake_pedal_press()
		prev_brake_depressed = is_brake_down
		if footwell_light:
			footwell_light.visible = (dome_light_on or not is_driven)

		# Real-Time Odometer & Trip Distance Counter
		var dist_delta_km = abs(forward_speed) * delta / 1000.0
		total_odometer_km += dist_delta_km
		trip_km += dist_delta_km
		if trip_display:
			trip_display.text = "ODO %06.1f KM | TRIP %.1f" % [total_odometer_km, trip_km]

		# Dashboard Radio Audio Visualizer VU Meter Animation
		if radio_eq_display:
			var am_radio = get_tree().get_first_node_in_group("audio_manager")
			var station_idx = am_radio.get("radio_station_index") if am_radio else 1
			if station_idx == 0:
				radio_eq_display.text = "📻 [ - - - - - ] OFF"
				radio_eq_display.modulate = Color(0.65, 0.65, 0.65, 0.7)
			else:
				eq_frame_timer += delta
				if eq_frame_timer >= 0.11:
					eq_frame_timer = 0.0
					eq_frame_index = (eq_frame_index + 1) % VU_BARS.size()
				var bar_str = VU_BARS[eq_frame_index]
				var st_name = "98.5 MHz"
				match station_idx:
					1: st_name = "Acoustic"
					2: st_name = "Nature"
					3: st_name = "Saung"
					4: st_name = "Pop FM"
				radio_eq_display.text = "📻 %s %s" % [bar_str, st_name]
				radio_eq_display.modulate = Color(0.25, 0.95, 0.75, 1.0)

		# Dynamic Chassis Weight Transfer (Roll & Pitch Suspension Reaction)
		if body_mesh:
			var target_body_roll = -smoothed_steering * 0.12 * speed_ratio
			var target_body_pitch = 0.0
			if brake > 5.0 and forward_speed > 1.0:
				target_body_pitch = (brake / max_brake_force) * 0.06
			elif engine_force > 10.0:
				target_body_pitch = -(engine_force / (max_engine_force * 1.75)) * 0.04
			body_mesh.rotation.z = lerpf(body_mesh.rotation.z, target_body_roll, delta * 8.0)
			body_mesh.rotation.x = lerpf(body_mesh.rotation.x, target_body_pitch, delta * 8.0)

		var is_boosting = false
		if current_driver and current_driver.get("is_sprinting") != null:
			is_boosting = current_driver.is_sprinting

		if nitro_flame:
			nitro_flame.emitting = (is_boosting and input_dir.y < -0.1)

		# Exhaust Backfire & Pop / Burble on Throttle Lift-Off or Turbo Cutoff
		var current_throttle = -input_dir.y if input_dir.y < -0.1 else 0.0
		var sharp_throttle_lift = (prev_throttle_input > 0.65 and current_throttle < 0.15 and forward_speed > 6.0)
		var boost_cutoff = (prev_boosting and not is_boosting and forward_speed > 8.0)
		if sharp_throttle_lift or boost_cutoff:
			if exhaust_backfire:
				exhaust_backfire.restart()
				exhaust_backfire.emitting = true
			var am_pop = get_tree().get_first_node_in_group("audio_manager")
			if am_pop and am_pop.has_method("play_exhaust_pop"):
				am_pop.play_exhaust_pop()
		prev_throttle_input = current_throttle
		prev_boosting = is_boosting

		# Progressive Acceleration & Dual-Power Braking
		if input_dir.y < -0.1: # Forward Throttle
			var boost_mult = 1.75 if is_boosting else 1.0
			var throttle_curve = lerp(0.65, 1.0, 1.0 - speed_ratio * 0.45)
			engine_force = -input_dir.y * max_engine_force * throttle_curve * boost_mult
			brake = 0.0
		elif input_dir.y > 0.1: # Reverse input / Active Braking
			if forward_speed > 0.5: # Hard forward brake
				brake = input_dir.y * max_brake_force
				engine_force = 0.0
			else: # Reverse gear engages only at near-stop
				brake = 0.0
				engine_force = -input_dir.y * (max_engine_force * 0.45)
		else:
			# Gentle coasting friction (momentum preservation)
			engine_force = 0.0
			brake = 1.2

		# Continuous procedural engine audio & dynamic tire skid/drift audio
		var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
		if audio_mgr:
			if audio_mgr.has_method("play_car_engine"):
				audio_mgr.play_car_engine(speed_ratio)
			var lateral_speed = abs(linear_velocity.dot(global_transform.basis.x))
			var is_skidding = (lateral_speed > 3.8 and forward_speed > 5.0) or (brake > 12.0 and forward_speed > 6.0)
			if tire_smoke_l: tire_smoke_l.emitting = is_skidding
			if tire_smoke_r: tire_smoke_r.emitting = is_skidding
			if audio_mgr.has_method("set_wind_rush"):
				audio_mgr.set_wind_rush(speed_ratio, windows_down)
			if is_skidding and audio_mgr.has_method("play_tire_skid"):
				var skid_intensity = clampf((lateral_speed - 3.0) / 4.0, 0.4, 1.0)
				audio_mgr.play_tire_skid(skid_intensity)

		# Hanging Jasmine Charm Inertia Physics (Rearview Mirror Garland Sway)
		if charm_pivot:
			var spring_k: float = 36.0
			var damping: float = 4.2
			var target_roll_force = -smoothed_steering * speed_ratio * 0.55
			var target_pitch_force = ((brake / max_brake_force) * 0.4) - ((engine_force / max_engine_force) * 0.3)
			charm_roll_vel += (-spring_k * charm_roll - damping * charm_roll_vel + target_roll_force * 32.0) * delta
			charm_roll += charm_roll_vel * delta
			charm_roll = clampf(charm_roll, -0.65, 0.65)
			charm_pitch_vel += (-spring_k * charm_pitch - damping * charm_pitch_vel + target_pitch_force * 32.0) * delta
			charm_pitch += charm_pitch_vel * delta
			charm_pitch = clampf(charm_pitch, -0.55, 0.55)
			charm_pivot.rotation.z = charm_roll
			charm_pivot.rotation.x = charm_pitch

	else:
		if body_mesh:
			body_mesh.rotation.z = lerpf(body_mesh.rotation.z, 0.0, delta * 6.0)
			body_mesh.rotation.x = lerpf(body_mesh.rotation.x, 0.0, delta * 6.0)
		if charm_pivot:
			charm_roll_vel += (-20.0 * charm_roll - 4.0 * charm_roll_vel) * delta
			charm_roll += charm_roll_vel * delta
			charm_pitch_vel += (-20.0 * charm_pitch - 4.0 * charm_pitch_vel) * delta
			charm_pitch += charm_pitch_vel * delta
			charm_pivot.rotation.z = charm_roll
			charm_pivot.rotation.x = charm_pitch
		if tire_smoke_l: tire_smoke_l.emitting = false
		if tire_smoke_r: tire_smoke_r.emitting = false
		if nitro_flame: nitro_flame.emitting = false
		var am = get_tree().get_first_node_in_group("audio_manager")
		if am and am.has_method("set_wind_rush"):
			am.set_wind_rush(0.0)
		engine_force = 0.0
		brake = 10.0

func enter_vehicle(driver: Node3D) -> void:
	if is_driven:
		return
	is_driven = true
	current_driver = driver
	driver.reparent(driver_seat)
	driver.position = Vector3.ZERO
	driver.rotation = Vector3.ZERO
	if driver.has_method("set_driving_state"):
		driver.set_driving_state(true, self)
	var am_latch = get_tree().get_first_node_in_group("audio_manager")
	if am_latch and am_latch.has_method("play_door_latch_pull"):
		am_latch.play_door_latch_pull()
	driver_entered.emit(driver)

func exit_vehicle() -> void:
	if not is_driven or not current_driver:
		return
	var driver = current_driver
	is_driven = false
	current_driver = null
	if tire_smoke_l: tire_smoke_l.emitting = false
	if tire_smoke_r: tire_smoke_r.emitting = false
	if nitro_flame: nitro_flame.emitting = false
	var am_exit = get_tree().get_first_node_in_group("audio_manager")
	if am_exit and am_exit.has_method("set_wind_rush"):
		am_exit.set_wind_rush(0.0)
	var exit_pos = global_position + (global_transform.basis.x * 2.0)
	driver.reparent(get_parent())
	driver.global_position = exit_pos
	if driver.has_method("set_driving_state"):
		driver.set_driving_state(false, null)
	var am_exit_latch = get_tree().get_first_node_in_group("audio_manager")
	if am_exit_latch and am_exit_latch.has_method("play_door_latch_pull"):
		am_exit_latch.play_door_latch_pull()
	driver_exited.emit()

func _on_interaction_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_vehicle"):
		body.set_interactable_vehicle(self)

func _on_interaction_area_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("set_interactable_vehicle"):
		body.set_interactable_vehicle(null)