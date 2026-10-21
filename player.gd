extends CharacterBody3D
## Slice 2 player: walk + sprint + jump + enter/exit car AND cart.
## Walk: arrow keys / WASD, or the touch joystick (touch_vector).
## Slice 8 action HUD (TOUCH-FIRST — this is a mobile game):
## on-screen Sprint (hold) + Jump + Vehicle buttons in JoystickLayer
## do sprint / jump / enter-exit on a phone; Shift / J / Enter-Space
## are kept ONLY as desktop fallbacks, never the primary path.
## Talk to a villager (TOUCH-FIRST — this is a mobile game):
## walk within 3.5 m and the on-screen Talk button appears
## (TalkButton in JoystickLayer); tap it — or tap the villager
## directly — and the nearest villager's talk_to() faces the player
## and shows its greeting bubble. E is kept ONLY as an optional
## desktop-debug fallback, not the primary path (Slice 6 made E the
## primary path; that was a mobile-design miss, corrected in Slice 7).

@export var walk_speed: float = 5.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 5.0

var driving: bool = false
var driving_vehicle: Node = null
var touch_vector: Vector2 = Vector2.ZERO
var touch_sprint: bool = false
var touch_throttle_up: bool = false
var touch_throttle_down: bool = false
var jump_requested: bool = false
var e_was_pressed: bool = false
var talk_button: Button = null
var talk_button_connected: bool = false
var sprint_button: Button = null
var sprint_button_connected: bool = false
var jump_button: Button = null
var jump_button_connected: bool = false
var vehicle_button: Button = null
var vehicle_button_connected: bool = false
var throttle_up_button: Button = null
var throttle_up_connected: bool = false
var throttle_down_button: Button = null
var throttle_down_connected: bool = false
var quest_label: Label = null
var talked_ids: Array = []
var speed_label: Label = null
var clock_label: Label = null
var orbit_button: Button = null
var orbit_button_connected: bool = false
# Slice 10 HUD + quest state. All nodes live in the real scene
# (JoystickLayer) and are found lazily, like the Slice 7/8 buttons.
var stamina: float = 100.0
var quest_stage: int = 0  # 0 talk-all, 1 visit pagoda, 2 ride, 3 done
var touch_yaw_left: bool = false
var touch_yaw_right: bool = false
var minimap_dots: Dictionary = {}
var compass_label: Label = null
var day_label: Label = null
var stamina_bar: ProgressBar = null
var speed_bar: ProgressBar = null
var prompt_label: Label = null
var help_button: Button = null
var help_button_connected: bool = false
var help_label: Label = null
var yaw_left_button: Button = null
var yaw_left_connected: bool = false
var yaw_right_button: Button = null
var yaw_right_connected: bool = false
var zoom_in_button: Button = null
var zoom_in_connected: bool = false
var zoom_out_button: Button = null
var zoom_out_connected: bool = false
# Slice 11: bell quest + reward + tracker + camera reset.
var bell_label_timer: float = 0.0
var quest_rewarded: bool = false
# Slice 12: market + well. Fruit/water are bought/drawn with on-screen
# buttons only (touch-first; no keyboard path exists for them).
var fruit_count: int = 0
var water_count: int = 0
var draw_timer: float = 0.0
var quest_rewarded2: bool = false
var fruit_button: Button = null
var fruit_button_connected: bool = false
var water_button: Button = null
var water_button_connected: bool = false
var fruit_water_label: Label = null
# Slice 13: gate + banana grove. BananaButton picks a bunch from the
# grove; bunches regrow 20 s after the last one is picked. Lights
# toggle the car/motorcycle headlight meshes (touch-first).
var banana_count: int = 0
var banana_regrow_timer: float = 0.0
var quest_rewarded3: bool = false
var banana_button: Button = null
var banana_button_connected: bool = false
var lights_button: Button = null
var lights_button_connected: bool = false
var lights_on: bool = true
var quest_tracker_label: Label = null
var camera_reset_button: Button = null
var camera_reset_connected: bool = false
# Slice 16: parachute + festival. The parachute deploys itself on
# a mid-air vehicle exit and stows itself on landing (no button
# needed); drum / lantern / snack buttons are touch-first like
# every other interaction button.
var parachuting: bool = false
var parachute_label: Label = null
var drum_button: Button = null
var drum_button_connected: bool = false
var lantern_button: Button = null
var lantern_button_connected: bool = false
var snack_button: Button = null
var snack_button_connected: bool = false
var drum_timer: float = 0.0
var snack_count: int = 0
var lantern_count: int = 0
var quest_rewarded6: bool = false
# Slice 17: fishing / donating / milking / watering / feeding, horn,
# bell, photo, rain, football, seventh reward. All buttons touch-first;
# the chime is generated in code (AudioStreamWAV sine) and actually
# played on quest advance — no dormant audio manager.
var fish_count: int = 0
var donation_count: int = 0
var milk_count: int = 0
var egg_count: int = 0
var goal_count: int = 0
var photo_count: int = 0
var crop_growth: int = 0
var quest_rewarded7: bool = false
var ball_vel: Vector2 = Vector2.ZERO
var rain_on: bool = false
var chime_player: AudioStreamPlayer = null
var last_chime_stage: int = 0
var fish_button: Button = null
var fish_button_connected: bool = false
var donate_button: Button = null
var donate_button_connected: bool = false
var milk_button: Button = null
var milk_button_connected: bool = false
var water17_button: Button = null
var water17_button_connected: bool = false
var feed_button: Button = null
var feed_button_connected: bool = false
var horn_button: Button = null
var horn_button_connected: bool = false
var bell17_button: Button = null
var bell17_button_connected: bool = false
var photo_button: Button = null
var photo_button_connected: bool = false
var rain_button: Button = null
var rain_button_connected: bool = false
# Slice 14: hinthar prayer. The Pray button lives in the real scene
# (JoystickLayer/PrayButton); the blessing label shows 4 s.
var pray_button: Button = null
var pray_button_connected: bool = false
var blessing_timer: float = 0.0
var quest_rewarded4: bool = false
# Slice 15: tea shop + school come alive, bicycle, 2 more villagers.
var tea_count: int = 0
var book_count: int = 0
var quest_rewarded5: bool = false
var tea_button: Button = null
var tea_button_connected: bool = false
var book_button: Button = null
var book_button_connected: bool = false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	_update_clock_label()
	_update_day_label()
	_update_minimap()
	_update_compass()
	_update_stamina(delta)
	_update_prompt_label()
	_update_fruit_water_label()
	_update_draw_animation(delta)
	_update_banana_regrow(delta)
	_update_banana_button()
	_update_pray_button()
	_update_tea_book_buttons()
	_update_festival_buttons()
	_update_blessing(delta)
	_update_lights_button()
	_update_slice17_buttons()
	_update_football(delta)
	if driving:
		velocity = Vector3.ZERO
		move_and_slide()
		if talk_button != null:
			talk_button.visible = false
		_update_market_buttons()
		# Driving: only the vehicle Exit button stays on screen.
		_update_action_buttons()
		_update_speed_label()
		return
	if not is_on_floor():
		velocity.y -= 20.0 * delta
		# Slice 16 parachute: gentle descent while the canopy is out.
		if parachuting:
			velocity.y = maxf(velocity.y, -3.0)
	else:
		velocity.y = 0.0
		# Slice 16: touching down stows the canopy (and can finish
		# the parachute quest stage).
		if parachuting:
			_stow_parachute()
		if Input.is_physical_key_pressed(KEY_J) or jump_requested:
			velocity.y = jump_velocity
		jump_requested = false
	var ix := Input.get_axis("ui_left", "ui_right")
	var iz := Input.get_axis("ui_up", "ui_down")
	if touch_vector != Vector2.ZERO:
		ix = touch_vector.x
		iz = touch_vector.y
	# Slice 10 analog walk speed: a half-pushed joystick walks
	# slower than a full push (keyboard input stays full speed).
	# Slice 10 stamina: sprinting is blocked once stamina hits 0.
	var raw := Vector3(ix, 0.0, iz)
	if raw.length() > 1.0:
		raw = raw.normalized()
	var dir := Vector3.ZERO
	if raw != Vector3.ZERO:
		dir = raw.normalized()
	var speed := walk_speed
	if touch_vector != Vector2.ZERO:
		speed *= 0.4 + 0.6 * clampf(raw.length(), 0.0, 1.0)
	var sprinting := (Input.is_physical_key_pressed(KEY_SHIFT) or touch_sprint) and stamina > 0.0
	if sprinting:
		speed *= sprint_multiplier
	if dir != Vector3.ZERO:
		rotation.y = atan2(dir.x, dir.z)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	_update_talk_button()
	_update_market_buttons()
	_update_action_buttons()
	_update_speed_label()
	# Slice 13 quest stage 6: walk through the village gate arch.
	# The arch is two posts + a beam (no blocking collision), so a
	# player can actually pass under it — unlike a solid-wall gate.
	if quest_stage == 6:
		var beam := get_node_or_null("../GateBeam12") as Node3D
		if beam != null:
			var dx := global_position.x - beam.global_position.x
			var dz := global_position.z - beam.global_position.z
			if dx * dx + dz * dz < 4.0:
				quest_stage = 7
				_update_quest_label()
	# Slice 14 quest stage 8: cross the bamboo footbridge over the
	# river. The bridge midpoint is its root node; horizontal
	# distance < 2.5 m counts, so deck height never blocks it.
	if quest_stage == 8:
		var br := get_node_or_null("../BambooBridge14") as Node3D
		if br != null:
			var bdx := global_position.x - br.global_position.x
			var bdz := global_position.z - br.global_position.z
			if bdx * bdx + bdz * bdz < 6.25:
				quest_stage = 9
				_update_quest_label()
	# Slice 10 quest stage 1: walk within 8 m of the pagoda.
	if quest_stage == 1:
		var pag := get_node_or_null("../Pagoda")
		if pag != null and global_position.distance_to(pag.global_position) < 8.0:
			quest_stage = 2
			_update_quest_label()
	# Slice 11 quest stage 3: walk within 3.5 m of the monastery
	# bell to ring it. The bell label shows on any ring (with a 4 s
	# cooldown); the quest advances only once stage 2 (ride) is done.
	var bell := get_node_or_null("../MonasteryBell") as Node3D
	if bell != null and global_position.distance_to(bell.global_position) < 3.5 and bell_label_timer <= 0.0:
		bell_label_timer = 4.0
		var bl := get_node_or_null("../MonasteryBell/BellLabel") as Label3D
		if bl != null:
			bl.visible = true
		if quest_stage == 3:
			quest_stage = 4
			if not quest_rewarded:
				quest_rewarded = true
			_update_quest_label()
	if bell_label_timer > 0.0:
		bell_label_timer -= delta
		if bell_label_timer <= 0.0:
			var bl2 := get_node_or_null("../MonasteryBell/BellLabel") as Label3D
			if bl2 != null:
				bl2.visible = false
	if drum_timer > 0.0:
		drum_timer -= delta
		if drum_timer <= 0.0:
			var dl2 := get_node_or_null("../FestivalDrum16/DrumLabel") as Label3D
			if dl2 != null:
				dl2.visible = false
	if Input.is_action_just_pressed("ui_accept"):
		_try_enter_vehicle()
	# E is a desktop-debug fallback ONLY — the primary path is the
	# on-screen Talk button / tapping the villager (see header).
	var e_now := Input.is_physical_key_pressed(KEY_E)
	if e_now and not e_was_pressed:
		_try_talk()
	e_was_pressed = e_now

## Shows the Talk button only when a villager is in talk range.
## The button lives in the real scene (JoystickLayer/TalkButton),
## not in a script nobody instantiates; it is found lazily because
## the player enters the tree before the CanvasLayer does.
func _update_talk_button() -> void:
	if talk_button == null:
		talk_button = get_node_or_null("../JoystickLayer/TalkButton") as Button
		if talk_button != null and not talk_button_connected:
			talk_button.pressed.connect(_try_talk)
			talk_button_connected = true
	if talk_button != null:
		talk_button.visible = _nearest_villager() != null

## Slice 8: wires the on-screen Sprint / Jump / Vehicle buttons.
## They live in the real scene (JoystickLayer), found lazily like
## the Talk button, because the player enters the tree first.
## Sprint is hold-to-sprint (button_down/up); Jump sets a request
## consumed on the next ground frame; Vehicle enters the nearest
## vehicle within 4 m on foot, or exits the ridden one while driving.
func _update_action_buttons() -> void:
	if sprint_button == null:
		sprint_button = get_node_or_null("../JoystickLayer/SprintButton") as Button
		if sprint_button != null and not sprint_button_connected:
			sprint_button.button_down.connect(_on_sprint_down)
			sprint_button.button_up.connect(_on_sprint_up)
			sprint_button_connected = true
	if jump_button == null:
		jump_button = get_node_or_null("../JoystickLayer/JumpButton") as Button
		if jump_button != null and not jump_button_connected:
			jump_button.pressed.connect(_on_jump_pressed)
			jump_button_connected = true
	if vehicle_button == null:
		vehicle_button = get_node_or_null("../JoystickLayer/VehicleButton") as Button
		if vehicle_button != null and not vehicle_button_connected:
			vehicle_button.pressed.connect(_on_vehicle_button_pressed)
			vehicle_button_connected = true
	# Slice 9 throttle buttons: hold-to-climb / hold-to-descend for
	# aircraft (airplane throttle, helicopter lift). They live in
	# the real scene (JoystickLayer), found lazily like the rest.
	if throttle_up_button == null:
		throttle_up_button = get_node_or_null("../JoystickLayer/ThrottleUpButton") as Button
		if throttle_up_button != null and not throttle_up_connected:
			throttle_up_button.button_down.connect(_on_throttle_up_down)
			throttle_up_button.button_up.connect(_on_throttle_up_up)
			throttle_up_connected = true
	if throttle_down_button == null:
		throttle_down_button = get_node_or_null("../JoystickLayer/ThrottleDownButton") as Button
		if throttle_down_button != null and not throttle_down_connected:
			throttle_down_button.button_down.connect(_on_throttle_down_down)
			throttle_down_button.button_up.connect(_on_throttle_down_up)
			throttle_down_connected = true
	# Slice 10: yaw buttons (flying only), zoom buttons, help button.
	# All live in the real scene (JoystickLayer), wired lazily.
	if yaw_left_button == null:
		yaw_left_button = get_node_or_null("../JoystickLayer/YawLeftButton") as Button
		if yaw_left_button != null and not yaw_left_connected:
			yaw_left_button.button_down.connect(_on_yaw_left_down)
			yaw_left_button.button_up.connect(_on_yaw_left_up)
			yaw_left_connected = true
	if yaw_right_button == null:
		yaw_right_button = get_node_or_null("../JoystickLayer/YawRightButton") as Button
		if yaw_right_button != null and not yaw_right_connected:
			yaw_right_button.button_down.connect(_on_yaw_right_down)
			yaw_right_button.button_up.connect(_on_yaw_right_up)
			yaw_right_connected = true
	if zoom_in_button == null:
		zoom_in_button = get_node_or_null("../JoystickLayer/ZoomInButton") as Button
		if zoom_in_button != null and not zoom_in_connected:
			zoom_in_button.pressed.connect(_on_zoom_in)
			zoom_in_connected = true
	if zoom_out_button == null:
		zoom_out_button = get_node_or_null("../JoystickLayer/ZoomOutButton") as Button
		if zoom_out_button != null and not zoom_out_connected:
			zoom_out_button.pressed.connect(_on_zoom_out)
			zoom_out_connected = true
	if help_button == null:
		help_button = get_node_or_null("../JoystickLayer/HelpButton") as Button
		if help_button != null and not help_button_connected:
			help_button.pressed.connect(_on_help_pressed)
			help_button_connected = true
	# Slice 11 camera reset button: tap to restore default orbit
	# angle and zoom (touch-first; it lives in the real scene).
	if camera_reset_button == null:
		camera_reset_button = get_node_or_null("../JoystickLayer/CameraResetButton") as Button
		if camera_reset_button != null and not camera_reset_connected:
			camera_reset_button.pressed.connect(_on_camera_reset)
			camera_reset_connected = true
	if camera_reset_button != null:
		camera_reset_button.visible = true
	if help_label == null:
		help_label = get_node_or_null("../JoystickLayer/HelpLabel") as Label
	if driving:
		if sprint_button != null:
			sprint_button.visible = false
		if jump_button != null:
			jump_button.visible = false
		if vehicle_button != null:
			vehicle_button.visible = true
			vehicle_button.text = "ဆင်းမည်"
		var flying := driving_vehicle != null and driving_vehicle.name in ["Airplane", "Helicopter"]
		if throttle_up_button != null:
			throttle_up_button.visible = flying
		if throttle_down_button != null:
			throttle_down_button.visible = flying
		if yaw_left_button != null:
			yaw_left_button.visible = flying
		if yaw_right_button != null:
			yaw_right_button.visible = flying
		if zoom_in_button != null:
			zoom_in_button.visible = true
		if zoom_out_button != null:
			zoom_out_button.visible = true
		if help_button != null:
			help_button.visible = true
		return
	if sprint_button != null:
		sprint_button.visible = true
	if jump_button != null:
		jump_button.visible = true
	if throttle_up_button != null:
		throttle_up_button.visible = false
	if throttle_down_button != null:
		throttle_down_button.visible = false
	# Slice 9 orbit button: tap to rotate the camera around the
	# player/vehicle (touch orbit — Q/E remain a desktop fallback).
	if orbit_button == null:
		orbit_button = get_node_or_null("../JoystickLayer/OrbitButton") as Button
		if orbit_button != null and not orbit_button_connected:
			orbit_button.pressed.connect(_on_orbit_pressed)
			orbit_button_connected = true
	if orbit_button != null:
		orbit_button.visible = true
	if vehicle_button != null:
		var near := _nearest_vehicle()
		vehicle_button.visible = near != null
		if near != null:
			vehicle_button.text = "စီးမည်"
	if yaw_left_button != null:
		yaw_left_button.visible = false
	if yaw_right_button != null:
		yaw_right_button.visible = false
	if zoom_in_button != null:
		zoom_in_button.visible = true
	if zoom_out_button != null:
		zoom_out_button.visible = true
	if help_button != null:
		help_button.visible = true

func _on_sprint_down() -> void:
	touch_sprint = true

func _on_sprint_up() -> void:
	touch_sprint = false

func _on_jump_pressed() -> void:
	if not driving:
		jump_requested = true

func _on_orbit_pressed() -> void:
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.orbit_angle += 0.6

## Slice 9 driving readout: vehicle name + speed, shown only
## while driving. Speed comes from the vehicle's own `speed`
## variable where it has one (car/cart/bike/heli/cow), else from
## its velocity (airplane). Names are shown in Burmese.
## Slice 10: speed is shown in km/h (units/s x 3.6, like a real
## speedometer), plus a SpeedBar showing the fraction of that
## vehicle's top speed.
func _update_speed_label() -> void:
	if speed_label == null:
		speed_label = get_node_or_null("../JoystickLayer/SpeedLabel") as Label
	if speed_bar == null:
		speed_bar = get_node_or_null("../JoystickLayer/SpeedBar") as ProgressBar
	if speed_label == null:
		return
	if not driving or driving_vehicle == null:
		speed_label.visible = false
		if speed_bar != null:
			speed_bar.visible = false
		return
	var names := {"Car": "ကား", "Cart": "လှည်း", "Motorcycle": "ဆိုင်ကယ်",
		"Airplane": "လေယာဉ်", "Cow": "နွား", "Helicopter": "ရဟတ်ယာဉ်", "Boat": "လှေ", "Bicycle": "စက်ဘီး", "TukTuk": "သုံးဘီး"}
	var vmax := {"Car": 14.0, "Cart": 6.0, "Motorcycle": 18.0,
		"Airplane": 50.0, "Cow": 4.5, "Helicopter": 12.0, "Boat": 5.0, "Bicycle": 7.0, "TukTuk": 11.0}
	var vname: String = str(names.get(driving_vehicle.name, driving_vehicle.name))
	var spd := 0.0
	if driving_vehicle.get("speed") != null:
		spd = absf(float(driving_vehicle.get("speed")))
	elif driving_vehicle.get("velocity") != null:
		spd = (driving_vehicle.get("velocity") as Vector3).length()
	speed_label.text = vname + " — " + ("%d km/h" % int(spd * 3.6))
	speed_label.visible = true
	if speed_bar != null:
		var top: float = float(vmax.get(driving_vehicle.name, 14.0))
		speed_bar.value = clampf(spd / top * 100.0, 0.0, 100.0)
		speed_bar.visible = true

## Slice 9 clock: in-game time from DayNight.time (120 s = 1 day).
## Guarded: an older scene without DayNight just shows no clock.
func _update_clock_label() -> void:
	if clock_label == null:
		clock_label = get_node_or_null("../JoystickLayer/ClockLabel") as Label
	if clock_label == null:
		return
	var dn := get_node_or_null("../DayNight")
	if dn == null or dn.get("time") == null or dn.get("day_length_seconds") == null:
		clock_label.visible = false
		return
	var day_len := float(dn.get("day_length_seconds"))
	if day_len <= 0.0:
		clock_label.visible = false
		return
	var frac := fmod(float(dn.get("time")) / day_len, 1.0)
	var total_min := int(frac * 24.0 * 60.0)
	clock_label.text = "အချိန် %02d:%02d" % [total_min / 60, total_min % 60]
	clock_label.visible = true

func _on_throttle_up_down() -> void:
	touch_throttle_up = true

func _on_throttle_up_up() -> void:
	touch_throttle_up = false

func _on_throttle_down_down() -> void:
	touch_throttle_down = true

func _on_throttle_down_up() -> void:
	touch_throttle_down = false

## Slice 9 first quest: talk to every villager in the village.
## Called by npc.gd talk_to(), so BOTH the Talk button and the
## direct-tap path count — a tap-only conversation is not lost.
## The QuestLabel lives in the real scene (JoystickLayer) with its
## starting text set in main.tscn; this only rewrites it on progress.
func record_talk(villager: Node) -> void:
	var vid := villager.get_instance_id()
	if not talked_ids.has(vid):
		talked_ids.append(vid)
	_update_quest_label()

## Slice 10 quest chain: 0 talk to every villager, 1 visit the
## pagoda, 2 ride any vehicle, 3 all done. Stage 0 promotes itself
## here once the talk count is complete; stage 1 is promoted by the
## pagoda distance check in _physics_process, stage 2 by entering
## a vehicle in _try_enter_vehicle.
func _update_quest_label() -> void:
	if quest_label == null:
		quest_label = get_node_or_null("../JoystickLayer/QuestLabel") as Label
	if quest_label == null:
		return
	var villagers := get_tree().get_nodes_in_group("villagers")
	var total := villagers.size()
	if quest_stage == 0:
		if total > 0 and talked_ids.size() >= total:
			quest_stage = 1
		else:
			quest_label.text = "တာဝန်: ရွာသားနဲ့ စကားပြောပါ (" + str(talked_ids.size()) + "/" + str(total) + ")"
			return
	if quest_stage == 1:
		quest_label.text = "တာဝန်: ဘုရားကို သွားပါ"
	elif quest_stage == 2:
		quest_label.text = "တာဝန်: ယာဉ်တစ်စီး စီးပါ"
	elif quest_stage == 3:
		quest_label.text = "တာဝန်: ခေါင်းလောင်းထိုးပါ"
	elif quest_stage == 4:
		quest_label.text = "တာဝန်: ဈေးက သစ်သီးဝယ်ပါ"
	elif quest_stage == 5:
		quest_label.text = "တာဝန်: ရေတွင်းက ရေဆွဲပါ"
	elif quest_stage == 6:
		quest_label.text = "တာဝန်: ရွာမုခ်ဦးကို ဖြတ်သန်းပါ"
	elif quest_stage == 7:
		quest_label.text = "တာဝန်: ငှက်ပျောသီး ခူးပါ (" + str(mini(banana_count, 3)) + "/3)"
	elif quest_stage == 8:
		quest_label.text = "တာဝန်: ဝါးတံတားကို ဖြတ်ပါ"
	elif quest_stage == 9:
		quest_label.text = "တာဝန်: ဟင်္သာရုပ်တုမှာ ဆုတောင်းပါ"
	elif quest_stage == 10:
		quest_label.text = "တာဝန်: လက်ဖက်ရည်ဆိုင်မှာ လက်ဖက်ရည်မှာပါ"
	elif quest_stage == 11:
		quest_label.text = "တာဝန်: ကျောင်းကို စာအုပ်လှူပါ"
	elif quest_stage == 12:
		quest_label.text = "တာဝန်: စက်ဘီးစီးပါ"
	elif quest_stage == 13:
		quest_label.text = "တာဝန်: သုံးဘီးစီးပါ"
	elif quest_stage == 14:
		quest_label.text = "တာဝန်: လေထီးနဲ့ မြေပြင်ကို ဆင်းပါ"
	elif quest_stage == 15:
		quest_label.text = "တာဝန်: ပွဲတော်မှာ ဗုံတီးပါ"
	elif quest_stage == 16:
		quest_label.text = "တာဝန်: မြစ်မှာ ငါးဖမ်းပါ"
	elif quest_stage == 17:
		quest_label.text = "တာဝန်: ဘုရားမှာ အလှူပေးပါ"
	elif quest_stage == 18:
		quest_label.text = "တာဝန်: နွားနို့ ညှစ်ပါ"
	elif quest_stage == 19:
		quest_label.text = "တာဝန်: သီးနှံခင်းကို ရေလောင်းပါ"
	elif quest_stage == 20:
		quest_label.text = "တာဝန်: ကြက်တွေကို အစာကျွေးပါ"
	elif quest_rewarded7:
		quest_label.text = "တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10% + ခုန်အား +10% + ခုန်အား ထပ် +10%"
	elif quest_rewarded6:
		quest_label.text = "တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10% + ခုန်အား +10%"
	elif quest_rewarded5:
		quest_label.text = "တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10%"
	elif quest_rewarded4:
		quest_label.text = "တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် +5% + ဆုတောင်း"
	elif quest_rewarded3:
		quest_label.text = "တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် +5%"
	elif quest_rewarded2:
		quest_label.text = "တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန်"
	elif quest_rewarded:
		quest_label.text = "တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့်"
	else:
		quest_label.text = "တာဝန်များ အားလုံး ပြီးပါပြီ!"
	# Slice 11 quest tracker: live checklist of the stages.
	# Slice 12: 6 stages now (market fruit + well water added).
	if quest_tracker_label == null:
		quest_tracker_label = get_node_or_null("../JoystickLayer/QuestTrackerLabel") as Label
	if quest_tracker_label != null:
		var stage_names := ["စကားပြော", "ဘုရားဖူး", "ယာဉ်စီး", "ခေါင်းလောင်း", "သစ်သီးဝယ်", "ရေဆွဲ", "မုခ်ဦးဖြတ်", "ငှက်ပျောခူး", "ဝါးတံတားဖြတ်", "ဟင်္သာဆုတောင်း", "လက်ဖက်ရည်မှာစား", "စာအုပ်လှူ", "စက်ဘီးစီး", "သုံးဘီးစီး", "လေထီးဆင်း", "ဗုံတီး", "ငါးဖမ်း", "အလှူပေး", "နို့ညှစ်", "ရေလောင်း", "အစာကျွေး"]
		var parts: Array = []
		for i in range(21):
			parts.append(("✓ " if quest_stage > i else "○ ") + stage_names[i])
		quest_tracker_label.text = "   ".join(parts)
		quest_tracker_label.visible = true
	# Slice 17 quest chime: a short generated tone whenever the stage
	# actually advances (not on every label refresh).
	if quest_stage != last_chime_stage:
		last_chime_stage = quest_stage
		_play_tone(660.0, 0.25)

func _on_vehicle_button_pressed() -> void:
	if driving:
		if driving_vehicle != null and driving_vehicle.has_method("exit_vehicle"):
			driving_vehicle.call("exit_vehicle")
		return
	_try_enter_vehicle()

func _nearest_vehicle() -> Node:
	var best: Node = null
	var best_dist: float = 4.0
	for name in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Cow2", "Helicopter", "Boat", "Bicycle", "TukTuk"]:
		var v := get_node_or_null("../" + name)
		if v != null:
			var d := global_position.distance_to(v.global_position)
			if d < best_dist:
				best_dist = d
				best = v
	return best

func _nearest_villager() -> Node:
	var best: Node = null
	var best_dist: float = 3.5
	for villager in get_tree().get_nodes_in_group("villagers"):
		var d := global_position.distance_to(villager.global_position)
		if d < best_dist:
			best_dist = d
			best = villager
	return best

func _try_talk() -> void:
	var best := _nearest_villager()
	if best != null and best.has_method("talk_to"):
		best.call("talk_to", global_position)

func _try_enter_vehicle() -> void:
	# Nearest vehicle within 4 m wins (Slice 6 took the first name in
	# list order, which could pick a farther vehicle over a nearer one).
	var best: Node = null
	var best_dist: float = 4.0
	for name in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Cow2", "Helicopter", "Boat", "Bicycle", "TukTuk"]:
		var v := get_node_or_null("../" + name)
		if v != null:
			var d := global_position.distance_to(v.global_position)
			if d < best_dist:
				best_dist = d
				best = v
	if best != null:
		driving = true
		driving_vehicle = best
		visible = false
		# Slice 10 quest stage 2: riding any vehicle completes it.
		if quest_stage == 2:
			quest_stage = 3
			_update_quest_label()
		# Slice 15 quest stage 12: riding the bicycle finishes the chain.
		if quest_stage == 12 and best.name == "Bicycle":
			quest_stage = 13
			_update_quest_label()
		# Slice 16 quest stage 13: riding the tuk-tuk continues it.
		if quest_stage == 13 and best.name == "TukTuk":
			quest_stage = 14
			_update_quest_label()
		best.start_driving(self)

func leave_vehicle() -> void:
	driving = false
	driving_vehicle = null
	visible = true
	# Slice 16 parachute: leaving a vehicle high above the ground
	# opens the canopy automatically — this closes the standing
	# "no parachute" gap from Slice 3. Ground exits (y near 1)
	# never deploy.
	if global_position.y > 3.0:
		_deploy_parachute()

## Slice 16 parachute (TOUCH-FIRST — no button needed: it opens
## itself on a mid-air exit and stows itself on landing; the
## joystick steers the drift while it is out, like walking).
func _deploy_parachute() -> void:
	parachuting = true
	for nname in ["ParachuteCanopy", "ParachuteLineL", "ParachuteLineR"]:
		var n := get_node_or_null(nname) as Node3D
		if n != null:
			n.visible = true
	if parachute_label == null:
		parachute_label = get_node_or_null("../JoystickLayer/ParachuteLabel") as Label
	if parachute_label != null:
		parachute_label.visible = true

func _stow_parachute() -> void:
	parachuting = false
	for nname in ["ParachuteCanopy", "ParachuteLineL", "ParachuteLineR"]:
		var n := get_node_or_null(nname) as Node3D
		if n != null:
			n.visible = false
	if parachute_label != null:
		parachute_label.visible = false
	if quest_stage == 14:
		quest_stage = 15
		_update_quest_label()

## Slice 10 stamina: sprinting drains it, resting restores it, and
## sprint is blocked at 0. The bar lives in the real scene.
func _update_stamina(delta: float) -> void:
	if stamina_bar == null:
		stamina_bar = get_node_or_null("../JoystickLayer/StaminaBar") as ProgressBar
	var sprinting := (Input.is_physical_key_pressed(KEY_SHIFT) or touch_sprint) and not driving
	# Slice 11 quest reward: finishing the chain blesses stamina —
	# it drains half as fast and restores twice as fast.
	var drain := 25.0
	var regen := 15.0
	if quest_rewarded:
		drain = 12.5
		regen = 30.0
	if sprinting and velocity.length() > 0.5:
		stamina = maxf(stamina - drain * delta, 0.0)
	else:
		stamina = minf(stamina + regen * delta, 100.0)
	if stamina_bar != null:
		stamina_bar.value = stamina
		stamina_bar.visible = not driving

## Slice 10 day counter from DayNight time (120 s = 1 day).
func _update_day_label() -> void:
	if day_label == null:
		day_label = get_node_or_null("../JoystickLayer/DayLabel") as Label
	if day_label == null:
		return
	var dn := get_node_or_null("../DayNight")
	if dn == null or dn.get("time") == null or dn.get("day_length_seconds") == null:
		day_label.visible = false
		return
	var day_len := float(dn.get("day_length_seconds"))
	if day_len <= 0.0:
		day_label.visible = false
		return
	var day := int(float(dn.get("time")) / day_len) + 1
	day_label.text = "နေ့ %d" % day
	day_label.visible = true

## Slice 10 compass: heading from the facing rotation. Facing -Z
## is north (rotation.y = 180 deg there), so heading = 180 - rot.
func _cardinal(deg: float) -> String:
	if deg >= 337.5 or deg < 22.5:
		return "N"
	elif deg < 67.5:
		return "NE"
	elif deg < 112.5:
		return "E"
	elif deg < 157.5:
		return "SE"
	elif deg < 202.5:
		return "S"
	elif deg < 247.5:
		return "SW"
	elif deg < 292.5:
		return "W"
	else:
		return "NW"

func _update_compass() -> void:
	if compass_label == null:
		compass_label = get_node_or_null("../JoystickLayer/CompassLabel") as Label
	if compass_label == null:
		return
	var facing: Node3D = self
	if driving and driving_vehicle != null:
		facing = driving_vehicle
	var deg := wrapf(180.0 - rad_to_deg(facing.rotation.y), 0.0, 360.0)
	compass_label.text = "%d° %s" % [int(deg), _cardinal(deg)]
	compass_label.visible = true

## Slice 10 REAL minimap: dots positioned from real world positions
## (world spans roughly -50..50 on x/z; the panel is ~170 px, so
## (w + 50) / 100 * 170 maps world to panel). Unlike a static
## panel with a rotating icon, these dots actually move: player
## (yellow), villagers (green), pagoda (gold), vehicles (white).
func _update_minimap() -> void:
	if minimap_dots.is_empty():
		var panel := get_node_or_null("../JoystickLayer/MinimapPanel")
		if panel == null:
			return
		for name in ["PlayerDot", "VillagerDot1", "VillagerDot2", "VillagerDot3", "VillagerDot4", "PagodaDot",
				"VehicleDotCar", "VehicleDotCart", "VehicleDotMotorcycle", "VehicleDotAirplane",
				"VehicleDotCow", "VehicleDotHelicopter",
				"BellDot", "ZayatDot", "GroveDot", "MarketDot", "WellDot", "VillagerDot5",
			"GateDot13", "GroveDot13", "SchoolDot13", "TeaShopDot13", "FootballDot13",
			"VillagerDot6", "VehicleDotBoat", "HintharDot14L", "HintharDot14R", "BridgeDot14",
			"VillagerDot7", "VillagerDot8", "VehicleDotBicycle", "VehicleDotTukTuk",
			"FestivalDot16", "VillagerDot9", "VillagerDot10",
			"FishDot17", "DonateDot17", "VillagerDot11", "VillagerDot12", "StallDot17", "WellDot17", "VehicleDotCow2", "BallDot17", "HouseDot17"]:
			var dot := panel.get_node_or_null(name) as ColorRect
			if dot != null:
				minimap_dots[name] = dot
		if minimap_dots.is_empty():
			return
	var put := func(dot_name: String, wpos: Vector3) -> void:
		var dot: ColorRect = minimap_dots.get(dot_name)
		if dot != null:
			var mx := clampf((wpos.x + 50.0) / 100.0 * 170.0, 0.0, 162.0)
			var my := clampf((wpos.z + 50.0) / 100.0 * 170.0, 0.0, 162.0)
			dot.position = Vector2(mx, my)
	put.call("PlayerDot", global_position)
	var villagers := get_tree().get_nodes_in_group("villagers")
	for i in range(min(villagers.size(), 10)):
		put.call("VillagerDot%d" % (i + 1), (villagers[i] as Node3D).global_position)
	var pag := get_node_or_null("../Pagoda")
	if pag != null:
		put.call("PagodaDot", (pag as Node3D).global_position)
	# Slice 11 landmark dots: bell (bronze), zayat (brown), grove
	# (green, tracked at the first palm trunk).
	var bellm := get_node_or_null("../MonasteryBell")
	if bellm != null:
		put.call("BellDot", (bellm as Node3D).global_position)
	var zay := get_node_or_null("../Zayat")
	if zay != null:
		put.call("ZayatDot", (zay as Node3D).global_position)
	var palm := get_node_or_null("../PalmTrunk_s11_1")
	if palm != null:
		put.call("GroveDot", (palm as Node3D).global_position)
	# Slice 12 market + well dots: the market square and the brick
	# well are tracked like the other landmarks.
	var stall := get_node_or_null("../MarketStallA")
	if stall != null:
		put.call("MarketDot", (stall as Node3D).global_position)
	var well := get_node_or_null("../BrickWell")
	if well != null:
		put.call("WellDot", (well as Node3D).global_position)
	# Slice 13 landmark dots: gate (gold), grove (green), school
	# (blue), tea shop (orange), football ground (white).
	for pair in [["GateBeam12", "GateDot13"], ["BananaGrove13", "GroveDot13"],
			["School13", "SchoolDot13"], ["TeaShop13", "TeaShopDot13"],
			["Football13", "FootballDot13"]]:
		var lm := get_node_or_null("../" + pair[0]) as Node3D
		if lm != null:
			put.call(pair[1], lm.global_position)
	for vname in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Cow2", "Helicopter", "Boat", "Bicycle", "TukTuk"]:
		var v := get_node_or_null("../" + vname)
		if v != null:
			put.call("VehicleDot" + vname, (v as Node3D).global_position)
	# Slice 14 landmark dots: bamboo bridge (bamboo brown) and the
	# two golden hinthar statues (gold).
	var br14 := get_node_or_null("../BambooBridge14")
	if br14 != null:
		put.call("BridgeDot14", (br14 as Node3D).global_position)
	var hsL := get_node_or_null("../HintharStatue14L")
	if hsL != null:
		put.call("HintharDot14L", (hsL as Node3D).global_position)
	var hsR := get_node_or_null("../HintharStatue14R")
	if hsR != null:
		put.call("HintharDot14R", (hsR as Node3D).global_position)
	# Slice 16 festival dot: the festival ground slab.
	var fest16 := get_node_or_null("../FestivalGround16")
	if fest16 != null:
		put.call("FestivalDot16", fest16.global_position)
	# Slice 17 dots: fishing spot, donation box, stall E, well #2,
	# House7, Cow2, football ball; villagers 11/12 by node name
	# (the group loop above only covers the first 10 villagers).
	for pair in [["FishingSpot17", "FishDot17"], ["DonationBox17", "DonateDot17"],
			["MarketStallE17", "StallDot17"], ["Well17_2", "WellDot17"],
			["House7_17", "HouseDot17"], ["Cow2", "VehicleDotCow2"],
			["FootballBall17", "BallDot17"], ["Villager11", "VillagerDot11"],
			["Villager12", "VillagerDot12"]]:
		var lm17 := get_node_or_null("../" + pair[0]) as Node3D
		if lm17 != null:
			put.call(pair[1], lm17.global_position)

## Slice 10 nearby prompt: what is close enough to use, on foot.
func _update_prompt_label() -> void:
	if prompt_label == null:
		prompt_label = get_node_or_null("../JoystickLayer/PromptLabel") as Label
	if prompt_label == null:
		return
	if driving:
		prompt_label.visible = false
		return
	var vill := _nearest_villager()
	if vill != null:
		var vname := str(vill.get("villager_name"))
		if vname == "":
			vname = "ရွာသား"
		prompt_label.text = "အနီး: " + vname + " — စကားပြော"
		prompt_label.visible = true
		return
	var veh := _nearest_vehicle()
	if veh != null:
		var names := {"Car": "ကား", "Cart": "လှည်း", "Motorcycle": "ဆိုင်ကယ်",
			"Airplane": "လေယာဉ်", "Cow": "နွား", "Cow2": "နွား", "Helicopter": "ရဟတ်ယာဉ်", "Boat": "လှေ", "Bicycle": "စက်ဘီး", "TukTuk": "သုံးဘီး"}
		prompt_label.text = "အနီး: " + names.get(veh.name, veh.name) + " — စီးမည်"
		prompt_label.visible = true
		return
	# Slice 11 landmark prompts: bell, zayat, grove.
	# Slice 12: market + well prompts added; village sign prompt
	# added too (the old comment claimed it but the code never had it).
	for pair in [["MonasteryBell", "ခေါင်းလောင်း", 3.5],
			["Zayat", "ဇရပ်", 5.0],
			["PalmTrunk_s11_1", "ထန်းတော", 5.0],
			["MarketStallA", "ဈေး", 5.0],
			["BrickWell", "ရေတွင်း", 5.0],
			["VillageSignPost", "ရွာဆိုင်း", 4.0],
			["GateBeam12", "ရွာမုခ်ဦး", 4.0],
			["BananaGrove13", "ငှက်ပျောတော", 4.0],
			["School13", "ရွာကျောင်း", 5.0],
			["TeaShop13", "လက်ဖက်ရည်ဆိုင်", 5.0],
			["Football13", "ဘောလုံးကွင်း", 5.0],
			["BambooBridge14", "ဝါးတံတား", 4.0],
			["HintharStatue14L", "ဟင်္သာရုပ်တု", 4.0],
			["HintharStatue14R", "ဟင်္သာရုပ်တု", 4.0],
			["FestivalGround16", "ပွဲတော်", 6.0],
		["FishingSpot17", "ငါးဖမ်းဆိပ်", 4.0],
		["DonationBox17", "အလှူခံပုံး", 4.0],
		["SesameField15", "နှမ်းခင်း", 4.0],
		["ChickenCoop17", "ကြက်အိမ်", 4.0],
		["MarketStallE17", "ဈေးဆိုင် E", 5.0],
		["Well17_2", "ရေတွင်း ၂", 5.0],
		["House7_17", "အိမ် ၇", 5.0],
		["StiltHouse17_5", "ခြေတံရှည် အိမ်", 5.0],
		["FootballBall17", "ဘောလုံး", 4.0],
			["FestivalDrum16", "ဗုံ", 4.0],
			["FestivalStall16", "ပွဲဈေးဆိုင်", 4.0],
			["FestivalLantern16A", "ပွဲမီးအိမ်", 4.0]]:
		var lm := get_node_or_null("../" + pair[0]) as Node3D
		if lm != null and global_position.distance_to(lm.global_position) < float(pair[2]):
			prompt_label.text = "အနီး: " + str(pair[1])
			prompt_label.visible = true
			return
	prompt_label.visible = false

func _on_yaw_left_down() -> void:
	touch_yaw_left = true

func _on_yaw_left_up() -> void:
	touch_yaw_left = false

func _on_yaw_right_down() -> void:
	touch_yaw_right = true

func _on_yaw_right_up() -> void:
	touch_yaw_right = false

func _on_zoom_in() -> void:
	var cam := get_node_or_null("../FollowCamera")
	if cam != null and cam.has_method("zoom_in"):
		cam.call("zoom_in")

func _on_zoom_out() -> void:
	var cam := get_node_or_null("../FollowCamera")
	if cam != null and cam.has_method("zoom_out"):
		cam.call("zoom_out")

func _on_help_pressed() -> void:
	if help_label != null:
		help_label.visible = not help_label.visible

func _on_camera_reset() -> void:
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("orbit_angle", 0.0)
		cam.set("zoom", 1.0)

## Slice 12 market + well interactions (TOUCH-FIRST — no keyboard
## path exists for buying fruit or drawing water). Both buttons
## live in the real scene (JoystickLayer), found lazily like the
## Talk button, and are hidden while driving.
func _update_market_buttons() -> void:
	if fruit_button == null:
		fruit_button = get_node_or_null("../JoystickLayer/FruitButton") as Button
		if fruit_button != null and not fruit_button_connected:
			fruit_button.pressed.connect(_on_buy_fruit)
			fruit_button_connected = true
	if water_button == null:
		water_button = get_node_or_null("../JoystickLayer/WaterButton") as Button
		if water_button != null and not water_button_connected:
			water_button.pressed.connect(_on_draw_water)
			water_button_connected = true
	if driving:
		if fruit_button != null:
			fruit_button.visible = false
		if water_button != null:
			water_button.visible = false
		return
	var stall := get_node_or_null("../MarketStallA") as Node3D
	var near_stall := stall != null and global_position.distance_to(stall.global_position) < 4.0
	var well := get_node_or_null("../BrickWell") as Node3D
	var near_well := well != null and global_position.distance_to(well.global_position) < 4.0
	if fruit_button != null:
		fruit_button.visible = near_stall
	if water_button != null:
		water_button.visible = near_well and draw_timer <= 0.0

func _on_buy_fruit() -> void:
	if driving:
		return
	fruit_count += 1
	if quest_stage == 4:
		quest_stage = 5
	_update_quest_label()
	_update_fruit_water_label()

func _on_draw_water() -> void:
	if driving or draw_timer > 0.0:
		return
	draw_timer = 1.5

func _update_fruit_water_label() -> void:
	if fruit_water_label == null:
		fruit_water_label = get_node_or_null("../JoystickLayer/FruitWaterLabel") as Label
	if fruit_water_label == null:
		return
	fruit_water_label.text = "🍎 %d 💧 %d 🍌 %d 🍵 %d 📚 %d 🍡 %d 🪔 %d 🐟 %d 💰 %d 🥛 %d 🥚 %d ⚽ %d" % [fruit_count, water_count, banana_count, tea_count, book_count, snack_count, lantern_count, fish_count, donation_count, milk_count, egg_count, goal_count]
	fruit_water_label.visible = true

## Slice 12: the well bucket lowers to the water and rises back
## over 1.5 s while drawing. The bucket node lives in the real
## scene (BrickWell/WellBucket12); guarded lookups, no crash path.
## When the draw completes the water count rises, and a stage-5
## quest becomes stage 6 with the second quest reward: +10% walk
## speed, applied exactly once (quest_rewarded2).
func _update_draw_animation(delta: float) -> void:
	if draw_timer <= 0.0:
		return
	draw_timer -= delta
	var bucket := get_node_or_null("../BrickWell/WellBucket12") as Node3D
	if bucket != null:
		var phase := 1.0 - maxf(draw_timer, 0.0) / 1.5
		var y := 1.6
		if phase < 0.5:
			y = 1.6 - (1.6 - 0.55) * (phase / 0.5)
		else:
			y = 0.55 + (1.6 - 0.55) * ((phase - 0.5) / 0.5)
		var p := bucket.position
		p.y = y
		bucket.position = p
	if draw_timer <= 0.0:
		water_count += 1
		if quest_stage == 5:
			quest_stage = 6
			if not quest_rewarded2:
				quest_rewarded2 = true
				walk_speed *= 1.1
		_update_quest_label()
		_update_fruit_water_label()

## Slice 13 banana harvest (TOUCH-FIRST — no keyboard path).
## The button lives in the real scene (JoystickLayer/BananaButton)
## and shows only within 3.5 m of the grove while a bunch is left.
## Picking hides the next bunch; when all 3 are picked they regrow
## after 20 s. Picking 3 bananas finishes quest stage 7 with the
## third reward: +5% walk speed, applied exactly once.
func _banana_bunch_visible() -> bool:
	for i in range(3):
		var b := get_node_or_null("../BananaGrove13/BananaBunch13_%d" % i) as Node3D
		if b != null and b.visible:
			return true
	return false

func _update_banana_button() -> void:
	if banana_button == null:
		banana_button = get_node_or_null("../JoystickLayer/BananaButton") as Button
		if banana_button != null and not banana_button_connected:
			banana_button.pressed.connect(_on_pick_banana)
			banana_button_connected = true
	if banana_button == null:
		return
	if driving:
		banana_button.visible = false
		return
	var grove := get_node_or_null("../BananaGrove13") as Node3D
	banana_button.visible = grove != null and global_position.distance_to(grove.global_position) < 3.5 and _banana_bunch_visible()

func _on_pick_banana() -> void:
	if driving:
		return
	for i in range(3):
		var b := get_node_or_null("../BananaGrove13/BananaBunch13_%d" % i) as Node3D
		if b != null and b.visible:
			b.visible = false
			break
	banana_count += 1
	if quest_stage == 7 and banana_count >= 3:
		quest_stage = 8
		if not quest_rewarded3:
			quest_rewarded3 = true
			walk_speed *= 1.05
	_update_quest_label()
	_update_fruit_water_label()

func _update_banana_regrow(delta: float) -> void:
	if _banana_bunch_visible():
		banana_regrow_timer = 0.0
		return
	if banana_regrow_timer <= 0.0:
		banana_regrow_timer = 20.0
		return
	banana_regrow_timer -= delta
	if banana_regrow_timer <= 0.0:
		for i in range(3):
			var b := get_node_or_null("../BananaGrove13/BananaBunch13_%d" % i) as Node3D
			if b != null:
				b.visible = true

## Slice 13 headlight toggle (TOUCH-FIRST). The Lights button
## shows only while driving the car or motorcycle; it toggles the
## headlight meshes' visibility (the car has two, the motorcycle
## one). No keyboard path is needed for it.
func _apply_lights() -> void:
	var car := get_node_or_null("../Car")
	if car != null:
		for hn in ["Headlight_R", "Headlight_L"]:
			var h := car.get_node_or_null(hn) as Node3D
			if h != null:
				h.visible = lights_on
	var bike := get_node_or_null("../Motorcycle")
	if bike != null:
		var bh := bike.get_node_or_null("BikeHeadlight") as Node3D
		if bh != null:
			bh.visible = lights_on
	var tuk := get_node_or_null("../TukTuk")
	if tuk != null:
		var th := tuk.get_node_or_null("TukHeadlight") as Node3D
		if th != null:
			th.visible = lights_on

func _update_lights_button() -> void:
	if lights_button == null:
		lights_button = get_node_or_null("../JoystickLayer/LightsButton") as Button
		if lights_button != null and not lights_button_connected:
			lights_button.pressed.connect(_on_lights_pressed)
			lights_button_connected = true
	if lights_button == null:
		return
	lights_button.visible = driving and driving_vehicle != null and driving_vehicle.name in ["Car", "Motorcycle", "TukTuk"]
	if lights_button.visible:
		_apply_lights()

func _on_lights_pressed() -> void:
	lights_on = not lights_on
	_apply_lights()

## Slice 14 pray interaction (TOUCH-FIRST — this is a mobile game).
## The Pray button lives in the real scene (JoystickLayer/PrayButton)
## and shows only within 4 m of a hinthar statue while on foot.
## Tapping it shows the nearest statue's blessing label for 4 s;
## on quest stage 9 it completes the chain with the fourth reward
## (+5% walk speed, applied exactly once, plus a full stamina refill).
func _nearest_statue() -> Node:
	var best: Node = null
	var best_dist: float = 4.0
	for sname in ["HintharStatue14L", "HintharStatue14R"]:
		var s := get_node_or_null("../" + sname) as Node3D
		if s != null:
			var d := global_position.distance_to(s.global_position)
			if d < best_dist:
				best_dist = d
				best = s
	return best

func _update_pray_button() -> void:
	if pray_button == null:
		pray_button = get_node_or_null("../JoystickLayer/PrayButton") as Button
		if pray_button != null and not pray_button_connected:
			pray_button.pressed.connect(_on_pray)
			pray_button_connected = true
	if pray_button == null:
		return
	if driving:
		pray_button.visible = false
		return
	pray_button.visible = _nearest_statue() != null

func _on_pray() -> void:
	if driving:
		return
	var s := _nearest_statue()
	if s == null:
		return
	var bl := s.get_node_or_null("BlessingLabel") as Label3D
	if bl != null:
		bl.visible = true
	blessing_timer = 4.0
	if quest_stage == 9:
		quest_stage = 10
		if not quest_rewarded4:
			quest_rewarded4 = true
			walk_speed *= 1.05
			stamina = 100.0
		_update_quest_label()

func _update_blessing(delta: float) -> void:
	if blessing_timer <= 0.0:
		return
	blessing_timer -= delta
	if blessing_timer <= 0.0:
		for sname in ["HintharStatue14L", "HintharStatue14R"]:
			var s := get_node_or_null("../" + sname)
			if s != null:
				var bl := s.get_node_or_null("BlessingLabel") as Label3D
				if bl != null:
					bl.visible = false

## Slice 15 tea + book interactions (TOUCH-FIRST — no keyboard path).
## The buttons live in the real scene (JoystickLayer/TeaButton15 and
## BookButton15) and show only on foot, within 4 m of the Slice 13
## tea shop / school. Ordering tea finishes quest stage 10;
## donating a book finishes stage 11 with the fifth reward
## (sprint +10%, applied exactly once).
func _update_tea_book_buttons() -> void:
	if tea_button == null:
		tea_button = get_node_or_null("../JoystickLayer/TeaButton15") as Button
		if tea_button != null and not tea_button_connected:
			tea_button.pressed.connect(_on_order_tea)
			tea_button_connected = true
	if book_button == null:
		book_button = get_node_or_null("../JoystickLayer/BookButton15") as Button
		if book_button != null and not book_button_connected:
			book_button.pressed.connect(_on_donate_book)
			book_button_connected = true
	if driving:
		if tea_button != null:
			tea_button.visible = false
		if book_button != null:
			book_button.visible = false
		return
	var shop := get_node_or_null("../TeaShop13") as Node3D
	var near_shop := shop != null and global_position.distance_to(shop.global_position) < 4.0
	var school := get_node_or_null("../School13") as Node3D
	var near_school := school != null and global_position.distance_to(school.global_position) < 4.0
	if tea_button != null:
		tea_button.visible = near_shop
	if book_button != null:
		book_button.visible = near_school

func _on_order_tea() -> void:
	if driving:
		return
	tea_count += 1
	if quest_stage == 10:
		quest_stage = 11
	_update_quest_label()
	_update_fruit_water_label()

func _on_donate_book() -> void:
	if driving:
		return
	book_count += 1
	if quest_stage == 11:
		quest_stage = 12
		if not quest_rewarded5:
			quest_rewarded5 = true
			sprint_multiplier *= 1.1
	_update_quest_label()
	_update_fruit_water_label()

## Slice 16 festival interactions (TOUCH-FIRST — this is a mobile
## game). Drum / lantern / snack buttons live in the real scene
## (JoystickLayer/DrumButton16, LanternButton16, SnackButton16)
## and show only on foot, near the festival. Beating the drum on
## quest stage 15 finishes the chain with the sixth reward
## (+5% walk speed, applied exactly once, +10% jump).
func _update_festival_buttons() -> void:
	if drum_button == null:
		drum_button = get_node_or_null("../JoystickLayer/DrumButton16") as Button
		if drum_button != null and not drum_button_connected:
			drum_button.pressed.connect(_on_beat_drum)
			drum_button_connected = true
	if lantern_button == null:
		lantern_button = get_node_or_null("../JoystickLayer/LanternButton16") as Button
		if lantern_button != null and not lantern_button_connected:
			lantern_button.pressed.connect(_on_light_lantern)
			lantern_button_connected = true
	if snack_button == null:
		snack_button = get_node_or_null("../JoystickLayer/SnackButton16") as Button
		if snack_button != null and not snack_button_connected:
			snack_button.pressed.connect(_on_buy_snack)
			snack_button_connected = true
	if driving:
		if drum_button != null:
			drum_button.visible = false
		if lantern_button != null:
			lantern_button.visible = false
		if snack_button != null:
			snack_button.visible = false
		return
	var drum := get_node_or_null("../FestivalDrum16") as Node3D
	if drum_button != null:
		drum_button.visible = drum != null and global_position.distance_to(drum.global_position) < 4.0
	if lantern_button != null:
		lantern_button.visible = _nearest_unlit_lantern() != null
	var stall := get_node_or_null("../FestivalStall16") as Node3D
	if snack_button != null:
		snack_button.visible = stall != null and global_position.distance_to(stall.global_position) < 4.0

func _nearest_unlit_lantern() -> Node:
	var best: Node = null
	var best_dist: float = 4.0
	for lname in ["FestivalLantern16A", "FestivalLantern16B", "FestivalLantern16C"]:
		var l := get_node_or_null("../" + lname) as Node3D
		if l == null:
			continue
		var glow := l.get_node_or_null("LanternGlow") as Node3D
		if glow != null and glow.visible:
			continue
		var d := global_position.distance_to(l.global_position)
		if d < best_dist:
			best_dist = d
			best = l
	return best

func _on_beat_drum() -> void:
	if driving:
		return
	var drum := get_node_or_null("../FestivalDrum16") as Node3D
	if drum == null:
		return
	var dl := drum.get_node_or_null("DrumLabel") as Label3D
	if dl != null:
		dl.visible = true
	drum_timer = 4.0
	if quest_stage == 15:
		quest_stage = 16
		if not quest_rewarded6:
			quest_rewarded6 = true
			walk_speed *= 1.05
			jump_velocity *= 1.1
		_update_quest_label()

func _on_light_lantern() -> void:
	if driving:
		return
	var l := _nearest_unlit_lantern()
	if l == null:
		return
	var glow := (l as Node3D).get_node_or_null("LanternGlow") as Node3D
	if glow != null:
		glow.visible = true
	lantern_count += 1
	_update_fruit_water_label()

func _on_buy_snack() -> void:
	if driving:
		return
	snack_count += 1
	_update_fruit_water_label()

## Slice 17: fishing / donating / milking / watering / feeding, horn,
## bell, photo, rain, football. Every button is touch-first and lives
## in the real scene (JoystickLayer); driving buttons (horn, bell)
## show only while driving the matching vehicle, the rest only on
## foot near their spot. No keyboard path exists for any of them.
func _play_tone(freq: float, dur: float) -> void:
	if chime_player == null:
		chime_player = AudioStreamPlayer.new()
		add_child(chime_player)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var n := int(22050 * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var s := int(sin(float(i) / 22050.0 * freq * TAU) * 12000.0)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	wav.data = data
	chime_player.stream = wav
	chime_player.play()

func _wire17(btn_name: String, btn: Button, connected: bool, handler: Callable) -> Button:
	if btn == null:
		btn = get_node_or_null("../JoystickLayer/" + btn_name) as Button
		if btn != null and not connected:
			btn.pressed.connect(handler)
			connected = true
	return btn

func _update_slice17_buttons() -> void:
	fish_button = _wire17("FishButton17", fish_button, fish_button_connected, _on_fish)
	if fish_button != null and not fish_button_connected:
		fish_button_connected = true
	donate_button = _wire17("DonateButton17", donate_button, donate_button_connected, _on_donate)
	if donate_button != null and not donate_button_connected:
		donate_button_connected = true
	milk_button = _wire17("MilkButton17", milk_button, milk_button_connected, _on_milk)
	if milk_button != null and not milk_button_connected:
		milk_button_connected = true
	water17_button = _wire17("WaterButton17", water17_button, water17_button_connected, _on_water_crops)
	if water17_button != null and not water17_button_connected:
		water17_button_connected = true
	feed_button = _wire17("FeedButton17", feed_button, feed_button_connected, _on_feed_chickens)
	if feed_button != null and not feed_button_connected:
		feed_button_connected = true
	horn_button = _wire17("HornButton17", horn_button, horn_button_connected, _on_horn)
	if horn_button != null and not horn_button_connected:
		horn_button_connected = true
	bell17_button = _wire17("BellButton17", bell17_button, bell17_button_connected, _on_bell17)
	if bell17_button != null and not bell17_button_connected:
		bell17_button_connected = true
	photo_button = _wire17("PhotoButton17", photo_button, photo_button_connected, _on_photo)
	if photo_button != null and not photo_button_connected:
		photo_button_connected = true
	rain_button = _wire17("RainButton17", rain_button, rain_button_connected, _on_rain)
	if rain_button != null and not rain_button_connected:
		rain_button_connected = true
	if driving:
		if horn_button != null:
			horn_button.visible = driving_vehicle != null and driving_vehicle.name in ["Car", "TukTuk"]
		if bell17_button != null:
			bell17_button.visible = driving_vehicle != null and driving_vehicle.name == "Bicycle"
		for b in [fish_button, donate_button, milk_button, water17_button, feed_button, photo_button, rain_button]:
			if b != null:
				b.visible = false
		return
	var spot := get_node_or_null("../FishingSpot17") as Node3D
	if fish_button != null:
		fish_button.visible = spot != null and global_position.distance_to(spot.global_position) < 4.0
	var box := get_node_or_null("../DonationBox17") as Node3D
	if donate_button != null:
		donate_button.visible = box != null and global_position.distance_to(box.global_position) < 4.0
	var cow := get_node_or_null("../Cow") as Node3D
	if milk_button != null:
		milk_button.visible = cow != null and global_position.distance_to(cow.global_position) < 3.5
	var field := get_node_or_null("../SesameField15") as Node3D
	if water17_button != null:
		water17_button.visible = field != null and global_position.distance_to(field.global_position) < 4.0
	var coop := get_node_or_null("../ChickenCoop17") as Node3D
	if feed_button != null:
		feed_button.visible = coop != null and global_position.distance_to(coop.global_position) < 4.0
	if photo_button != null:
		photo_button.visible = true
	if rain_button != null:
		rain_button.visible = true
		rain_button.text = "မိုးပိတ်" if rain_on else "မိုး"
	if horn_button != null:
		horn_button.visible = false
	if bell17_button != null:
		bell17_button.visible = false

func _on_fish() -> void:
	if driving:
		return
	fish_count += 1
	if quest_stage == 16:
		quest_stage = 17
		_update_quest_label()
	_update_fruit_water_label()

func _on_donate() -> void:
	if driving:
		return
	donation_count += 1
	if quest_stage == 17:
		quest_stage = 18
		_update_quest_label()
	_update_fruit_water_label()

func _on_milk() -> void:
	if driving:
		return
	milk_count += 1
	if quest_stage == 18:
		quest_stage = 19
		_update_quest_label()
	_update_fruit_water_label()

func _on_water_crops() -> void:
	if driving:
		return
	if crop_growth < 3:
		crop_growth += 1
		var s := 1.0 + 0.3 * float(crop_growth)
		for i in range(6):
			var p := get_node_or_null("../SesameField15/SesamePlant15_%d" % i) as Node3D
			if p != null:
				p.scale = Vector3(s, s, s)
	if quest_stage == 19:
		quest_stage = 20
		_update_quest_label()

func _on_feed_chickens() -> void:
	if driving:
		return
	egg_count += 1
	if quest_stage == 20:
		quest_stage = 21
		if not quest_rewarded7:
			quest_rewarded7 = true
			walk_speed *= 1.05
			jump_velocity *= 1.1
		_update_quest_label()
	_update_fruit_water_label()

func _on_horn() -> void:
	_play_tone(220.0, 0.4)

func _on_bell17() -> void:
	_play_tone(880.0, 0.3)

func _on_photo() -> void:
	if driving:
		return
	var img := get_viewport().get_texture().get_image()
	photo_count += 1
	img.save_png("user://photo17_%d.png" % photo_count)

func _on_rain() -> void:
	rain_on = not rain_on
	var rain := get_node_or_null("../Rain17") as GPUParticles3D
	if rain != null:
		rain.visible = rain_on
		rain.emitting = rain_on

## Slice 17 football: the ball is pushed when the player walks into
## it and rolls with decay; entering either goal (24,-20) or (36,-20)
## scores, resets the ball to centre, and bumps the goal counter.
func _update_football(delta: float) -> void:
	var ball := get_node_or_null("../FootballBall17") as Node3D
	if ball == null:
		return
	if not driving:
		var to_ball := Vector2(ball.global_position.x - global_position.x, ball.global_position.z - global_position.z)
		if to_ball.length() < 1.2 and to_ball.length() > 0.01:
			ball_vel += to_ball.normalized() * 8.0
	ball.global_position.x += ball_vel.x * delta
	ball.global_position.z += ball_vel.y * delta
	ball_vel *= maxf(0.0, 1.0 - 2.0 * delta)
	for g in [Vector2(24.0, -20.0), Vector2(36.0, -20.0)]:
		if Vector2(ball.global_position.x, ball.global_position.z).distance_to(g) < 2.0:
			goal_count += 1
			ball.global_position = Vector3(30.0, 0.35, -20.0)
			ball_vel = Vector2.ZERO
			_update_fruit_water_label()
			break
