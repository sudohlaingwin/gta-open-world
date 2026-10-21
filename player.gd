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

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	_update_clock_label()
	_update_day_label()
	_update_minimap()
	_update_compass()
	_update_stamina(delta)
	_update_prompt_label()
	if driving:
		velocity = Vector3.ZERO
		move_and_slide()
		if talk_button != null:
			talk_button.visible = false
		# Driving: only the vehicle Exit button stays on screen.
		_update_action_buttons()
		_update_speed_label()
		return
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
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
	_update_action_buttons()
	_update_speed_label()
	# Slice 10 quest stage 1: walk within 8 m of the pagoda.
	if quest_stage == 1:
		var pag := get_node_or_null("../Pagoda")
		if pag != null and global_position.distance_to(pag.global_position) < 8.0:
			quest_stage = 2
			_update_quest_label()
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
		"Airplane": "လေယာဉ်", "Cow": "နွား", "Helicopter": "ရဟတ်ယာဉ်"}
	var vmax := {"Car": 14.0, "Cart": 6.0, "Motorcycle": 18.0,
		"Airplane": 50.0, "Cow": 4.5, "Helicopter": 12.0}
	var vname := names.get(driving_vehicle.name, driving_vehicle.name)
	var spd := 0.0
	if driving_vehicle.get("speed") != null:
		spd = absf(float(driving_vehicle.get("speed")))
	elif driving_vehicle.get("velocity") != null:
		spd = (driving_vehicle.get("velocity") as Vector3).length()
	speed_label.text = vname + " — " + ("%d km/h" % int(spd * 3.6))
	speed_label.visible = true
	if speed_bar != null:
		var top := vmax.get(driving_vehicle.name, 14.0)
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
	else:
		quest_label.text = "တာဝန်များ အားလုံး ပြီးပါပြီ!"

func _on_vehicle_button_pressed() -> void:
	if driving:
		if driving_vehicle != null and driving_vehicle.has_method("exit_vehicle"):
			driving_vehicle.call("exit_vehicle")
		return
	_try_enter_vehicle()

func _nearest_vehicle() -> Node:
	var best: Node = null
	var best_dist: float = 4.0
	for name in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Helicopter"]:
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
	for name in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Helicopter"]:
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
		best.start_driving(self)

func leave_vehicle() -> void:
	driving = false
	driving_vehicle = null
	visible = true

## Slice 10 stamina: sprinting drains it, resting restores it, and
## sprint is blocked at 0. The bar lives in the real scene.
func _update_stamina(delta: float) -> void:
	if stamina_bar == null:
		stamina_bar = get_node_or_null("../JoystickLayer/StaminaBar") as ProgressBar
	var sprinting := (Input.is_physical_key_pressed(KEY_SHIFT) or touch_sprint) and not driving
	if sprinting and velocity.length() > 0.5:
		stamina = maxf(stamina - 25.0 * delta, 0.0)
	else:
		stamina = minf(stamina + 15.0 * delta, 100.0)
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
		for name in ["PlayerDot", "VillagerDot1", "VillagerDot2", "VillagerDot3", "PagodaDot",
				"VehicleDotCar", "VehicleDotCart", "VehicleDotMotorcycle", "VehicleDotAirplane",
				"VehicleDotCow", "VehicleDotHelicopter"]:
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
	for i in range(min(villagers.size(), 3)):
		put.call("VillagerDot%d" % (i + 1), (villagers[i] as Node3D).global_position)
	var pag := get_node_or_null("../Pagoda")
	if pag != null:
		put.call("PagodaDot", (pag as Node3D).global_position)
	for vname in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Helicopter"]:
		var v := get_node_or_null("../" + vname)
		if v != null:
			put.call("VehicleDot" + vname, (v as Node3D).global_position)

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
			"Airplane": "လေယာဉ်", "Cow": "နွား", "Helicopter": "ရဟတ်ယာဉ်"}
		prompt_label.text = "အနီး: " + names.get(veh.name, veh.name) + " — စီးမည်"
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
