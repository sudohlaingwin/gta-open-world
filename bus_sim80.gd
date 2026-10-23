extends Node3D
## Slice 80 — BUS SIMULATION, part 7 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 7).
## What it builds, all runtime-only, NO scene touched:
## - STOP REQUEST: a touch-first button, visible only while
##   driving the bus (same rule as DoorButton74), that
##   simulates a passenger pulling the stop cord: it flags
##   the controller's CURRENT next stop, and a HUD label
##   names the requested stop in Myanmar digits. The flag
##   clears when that stop is served in order (the only
##   path that advances next_stop), when the service is
##   switched (Local/Express recompute, Slice 79), or when
##   the player leaves the bus. NO money, NO penalty if
##   the driver ignores the request — the flag is guidance
##   only, stated plainly. Session-only, nothing saved.
## - HORN: a touch-first horn button (same visibility
##   rule) that plays a REAL generated dual-tone honk
##   (370 + 466 Hz, 0.5 s, whole cycles so the buffer
##   starts and ends silently) — the same generated-buffer
##   approach as Slice 65 engine audio. No recording, no
##   copyrighted sound, no sound claimed that is not
##   generated here.
## - DOOR CHIME: a short REAL generated two-tone chime
##   (880 Hz then 660 Hz, 0.25 s each, whole cycles) that
##   plays on EVERY door edge — opening and closing —
##   watched from bus.door_open, the same value the Slice
##   74 controller reads. The bus script itself is NOT
##   edited; this node only observes the flag.
## Mute follows the established rule (player sound_on off
## or SaveManager "muted" on silences both sounds, same
## as Slice 65). No opponent code, map, names or structure
## is used. Touch-first throughout (no keys anywhere).

const HORN_FREQ_A: float = 370.0
const HORN_FREQ_B: float = 466.0
const CHIME_FREQ_A: float = 880.0
const CHIME_FREQ_B: float = 660.0
const BUFFER_HZ: int = 22050
const MY_DIGITS: Array = ["၀", "၁", "၂", "၃", "၄", "၅", "၆", "၇", "၈", "၉"]

var _hud_done: bool = false
var _horn_btn: Button = null
var _req_btn: Button = null
var _req_label: Label = null
var _horn_player: AudioStreamPlayer = null
var _chime_player: AudioStreamPlayer = null
var _prev_door_open: bool = false
var _door_seen: bool = false
# Requested stop index, or -1 when no request is active.
var request_stop80: int = -1
var _req_dir: int = -1
var _req_next: int = -1
# Counters, so the world sim can assert sounds fired
# (headless ears cannot hear; playing flags + counters can).
var horn_plays80: int = 0
var chime_plays80: int = 0


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim80") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim80"
	n.set_script(load("res://bus_sim80.gd"))
	world.call_deferred("add_child", n)


static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61/74/75/76/77/78/79 HUD
	# controls. Horn (940,470,104,40) and Request
	# (940,515,104,40) stack ABOVE ServiceButton79
	# (940,560,104,40) and left of the Slice 61 cluster
	# (x >= 1050): disjoint from every bus HUD rect.
	# Request label (720,400,214,40) sits ABOVE the Slice
	# 76 feedback label (720,450,214,40) and below nothing:
	# disjoint from RouteLabel75 (720,560), the Slice 76
	# prompt (720,500) and the Slice 77 timetable (720,655).
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


static func _my_num(n: int) -> String:
	var s := str(n)
	var out := ""
	for ch in s:
		out += MY_DIGITS[int(ch)]
	return out


func _ready() -> void:
	_horn_player = AudioStreamPlayer.new()
	_horn_player.name = "Horn80"
	_horn_player.stream = _make_horn()
	_horn_player.volume_db = -10.0
	add_child(_horn_player)
	_chime_player = AudioStreamPlayer.new()
	_chime_player.name = "Chime80"
	_chime_player.stream = _make_chime()
	_chime_player.volume_db = -14.0
	add_child(_chime_player)


func _make_horn() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = BUFFER_HZ
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var frames := int(BUFFER_HZ * 0.5)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(BUFFER_HZ)
		# 370 Hz = 185 cycles in 0.5 s, 466 Hz = 233 cycles:
		# both end at a zero crossing, so the one-shot has
		# no click at either end.
		var v := sin(t * HORN_FREQ_A * TAU) * 0.55 + sin(t * HORN_FREQ_B * TAU) * 0.35
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 24000.0))
	wav.data = data
	return wav


func _make_chime() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = BUFFER_HZ
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var frames := int(BUFFER_HZ * 0.5)
	var half := frames / 2
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(BUFFER_HZ)
		# Ding-dong: 880 Hz for 0.25 s (220 cycles), then
		# 660 Hz for 0.25 s (165 cycles). Each half starts
		# and ends at a zero crossing, so neither the join
		# nor the ends click.
		var f := CHIME_FREQ_A if i < half else CHIME_FREQ_B
		var tt := t if i < half else t - 0.25
		var v := sin(tt * f * TAU) * 0.6
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 24000.0))
	wav.data = data
	return wav


func _muted(world: Node3D) -> bool:
	if world == null:
		return true
	var player := world.get_node_or_null("Player")
	if player != null and player.get("sound_on") != null and not bool(player.get("sound_on")):
		return true
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.get("muted") != null and bool(sm.get("muted")):
		return true
	return false


func _driving_bus(world: Node3D) -> bool:
	if world == null:
		return false
	var bus := world.get_node_or_null("Bus")
	var player := world.get_node_or_null("Player")
	if bus == null or player == null:
		return false
	return bool(player.get("driving")) and player.get("driving_vehicle") == bus


func _try_hud(world: Node3D) -> bool:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return false
	if layer.get_node_or_null("HornButton80") == null:
		var btn := Button.new()
		btn.name = "HornButton80"
		btn.text = "ဟွန်း"
		_set_rect(btn, 940.0, 470.0, 104.0, 40.0)
		btn.visible = false
		btn.pressed.connect(_on_horn_pressed)
		layer.add_child(btn)
		_horn_btn = btn
	else:
		_horn_btn = layer.get_node_or_null("HornButton80") as Button
	if layer.get_node_or_null("RequestButton80") == null:
		var btn := Button.new()
		btn.name = "RequestButton80"
		btn.text = "ရပ်တောင်းဆို"
		_set_rect(btn, 940.0, 515.0, 104.0, 40.0)
		btn.visible = false
		btn.pressed.connect(_on_request_pressed)
		layer.add_child(btn)
		_req_btn = btn
	else:
		_req_btn = layer.get_node_or_null("RequestButton80") as Button
	if layer.get_node_or_null("RequestLabel80") == null:
		var lab := Label.new()
		lab.name = "RequestLabel80"
		lab.text = ""
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_rect(lab, 720.0, 400.0, 214.0, 40.0)
		lab.visible = false
		layer.add_child(lab)
		_req_label = lab
	else:
		_req_label = layer.get_node_or_null("RequestLabel80") as Label
	return true


func _sync_request_ui(world: Node3D) -> void:
	if _req_btn != null:
		_req_btn.text = "ရပ်မည် ✓" if request_stop80 >= 0 else "ရပ်တောင်းဆို"
	if _req_label != null:
		if request_stop80 >= 0:
			_req_label.text = "ရပ်တောင်းဆိုထားသည် · မှတ်တိုင် " + _my_num(request_stop80 + 1)
			_req_label.visible = _driving_bus(world)
		else:
			_req_label.text = ""
			_req_label.visible = false


func _on_horn_pressed() -> void:
	var world := get_parent() as Node3D
	if world == null or not _driving_bus(world) or _muted(world):
		return
	if _horn_player != null:
		horn_plays80 += 1
		_horn_player.play()


func _on_request_pressed() -> void:
	var world := get_parent() as Node3D
	if world == null or not _driving_bus(world):
		return
	var ctrl := world.get_node_or_null("BusSim74")
	if ctrl == null:
		return
	if request_stop80 >= 0:
		# Second press cancels the request.
		request_stop80 = -1
		_req_dir = -1
		_req_next = -1
		_sync_request_ui(world)
		return
	request_stop80 = int(ctrl.get("next_stop"))
	_req_dir = int(ctrl.get("direction"))
	_req_next = int(ctrl.get("next_stop"))
	_sync_request_ui(world)


func _physics_process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _hud_done:
		_hud_done = _try_hud(world)
	var driving := _driving_bus(world)
	if _horn_btn != null:
		_horn_btn.visible = driving
	if _req_btn != null:
		_req_btn.visible = driving
	if not driving:
		# A request lives only while driving the bus.
		if request_stop80 >= 0:
			request_stop80 = -1
			_req_dir = -1
			_req_next = -1
			_sync_request_ui(world)
		return
	var bus := world.get_node_or_null("Bus")
	var ctrl := world.get_node_or_null("BusSim74")
	if bus != null and bus.get("door_open") != null:
		var open_now := bool(bus.get("door_open"))
		if not _door_seen:
			_door_seen = true
			_prev_door_open = open_now
		elif open_now != _prev_door_open:
			_prev_door_open = open_now
			# Every edge chimes, open AND close, unless muted.
			if not _muted(world) and _chime_player != null:
				chime_plays80 += 1
				_chime_player.play()
	if ctrl != null and request_stop80 >= 0:
		# The controller advances next_stop/direction only
		# on an in-order serve (Slice 75, proven) or a
		# service switch (Slice 79 recompute) — either way
		# the requested stop is no longer the next stop, so
		# the request is spent.
		if int(ctrl.get("direction")) != _req_dir or int(ctrl.get("next_stop")) != _req_next:
			request_stop80 = -1
			_req_dir = -1
			_req_next = -1
			_sync_request_ui(world)
	if _req_label != null:
		_req_label.visible = driving and request_stop80 >= 0
