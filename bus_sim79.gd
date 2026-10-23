extends Node3D
## Slice 79 — BUS SIMULATION, part 6 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 6).
## What it builds, all runtime-only, NO scene touched:
## - SERVICE VARIANTS: a touch-first selector button (visible
##   only while driving the bus, same rule as DoorButton74)
##   toggles Local vs Express. Local is the Slice 75 route
##   unchanged; Express serves only stops 0 and 3 — the
##   controller (bus_controller74.gd) owns the order, the
##   boarding filter and the next-stop recompute, so the
##   destination sign, the Slice 77 timetable dues and the
##   Slice 28/34 guidance all follow automatically. This
##   node only re-texts the physical timetable boards at
##   the 4 stops (Local lists stops 1-4 at 0/1/2/3 minutes,
##   Express lists stops 1 and 4 at 0/1 minutes — Myanmar
##   digits and words only, because the Noto font has no
##   '+' or ':' glyphs, Slice 77 lesson). The service mode
##   is session-only (NOT saved): a loaded save resumes as
##   Local, stated plainly.
## - SERVICE SUMMARY: when a round trip completes and the
##   bus then reaches the depot (Slice 78 return), a HUD
##   summary shows counts only — in-order stops served,
##   passengers carried, on-time stops — for the service
##   just completed. NO money, NO score, NO rating. If a
##   second round trip completes before the depot is ever
##   visited, the pending summary is replaced by the newer
##   service's counts (the older uncollected summary is
##   dropped, stated plainly, not silently merged).
## - NIGHT SERVICE: legs starting at night run 90 s per
##   stop instead of 60 s — that rule lives in
##   bus_sim77.gd (fixed at leg start); stop lamps and bus
##   headlights already gate on the Slice 57 night rule,
##   so no new lighting is claimed here.
## State is session-only (service mode, summary counters):
## nothing new is saved, so no save key is added and no old
## save can break. No opponent code, map, names or structure
## is used. Touch-first throughout (no keys anywhere).

const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0]
const DEPOT_POS: Vector3 = Vector3(30.0, 0.0, 16.0)
const DEPOT_R: float = 12.0
const SUMMARY_S: float = 10.0
const MY_DIGITS: Array = ["၀", "၁", "၂", "၃", "၄", "၅", "၆", "၇", "၈", "၉"]
const BOARD_LOCAL: String = "ဘတ်စ်ဇယား\nမှတ်တိုင် ၁ ၀ မိနစ်\nမှတ်တိုင် ၂ ၁ မိနစ်\nမှတ်တိုင် ၃ ၂ မိနစ်\nမှတ်တိုင် ၄ ၃ မိနစ်"
const BOARD_EXPRESS: String = "ဘတ်စ်ဇယား\nမှတ်တိုင် ၁ ၀ မိနစ်\nမှတ်တိုင် ၄ ၁ မိနစ်"

var _hud_done: bool = false
var _boards_done: bool = false
var _service_btn: Button = null
var _summary_label: Label = null
var _summary_timer: float = 0.0
var _prev_dir: int = -1
var _prev_next: int = -1
var _observed: bool = false
var _last_fb_seq: int = 0
# Running counters for the round trip in progress.
var _svc_serves: int = 0
var _svc_start_boarded: int = 0
var _svc_ontime: int = 0
# Finalised counts of the last completed round trip,
# shown at the next depot arrival.
var _pending: bool = false
var _pend_serves: int = 0
var _pend_carried: int = 0
var _pend_ontime: int = 0
var _last_service: int = -1


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim79") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim79"
	n.set_script(load("res://bus_sim79.gd"))
	world.call_deferred("add_child", n)


static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61/74/75/76/77/78 HUD
	# controls. Service button (940,560,104,40): right of
	# RouteLabel75 (ends x 934), left of the Slice 61
	# cluster (starts x 1050), above DoorButton74 (y 610),
	# so it overlaps no bus HUD element. Summary label
	# (505,470,214,80): above Service78 (y 560), left of
	# RouteLabel75 (x 720), two lines for the counts.
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


static func _my_num(n: int) -> String:
	# Myanmar digits for counts (RouteLabel75 already uses
	# Myanmar digits in HUD labels, so this is established).
	var s := str(n)
	var out := ""
	for ch in s:
		var d := int(ch)
		out += MY_DIGITS[d]
	return out


func _try_hud(world: Node3D) -> bool:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return false
	if layer.get_node_or_null("ServiceButton79") == null:
		var btn := Button.new()
		btn.name = "ServiceButton79"
		btn.text = "ရိုးရိုး"
		_set_rect(btn, 940.0, 560.0, 104.0, 40.0)
		btn.visible = false
		btn.pressed.connect(_on_service_pressed)
		layer.add_child(btn)
		_service_btn = btn
	else:
		_service_btn = layer.get_node_or_null("ServiceButton79") as Button
	if layer.get_node_or_null("Summary79") == null:
		var lab := Label.new()
		lab.name = "Summary79"
		lab.text = ""
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_rect(lab, 505.0, 470.0, 214.0, 80.0)
		lab.visible = false
		layer.add_child(lab)
		_summary_label = lab
	else:
		_summary_label = layer.get_node_or_null("Summary79") as Label
	return true


func _on_service_pressed() -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	var bus := world.get_node_or_null("Bus") as Node3D
	if ctrl == null or not ctrl.has_method("set_service79"):
		return
	var cur := int(ctrl.get("service79"))
	var nxt := 1 - cur
	ctrl.call("set_service79", nxt, world, bus)
	_sync_button(ctrl)
	_sync_boards(world)


func _sync_button(ctrl: Node3D) -> void:
	if _service_btn == null or ctrl == null:
		return
	_service_btn.text = "အမြန်" if int(ctrl.get("service79")) == 1 else "ရိုးရိုး"


func _sync_boards(world: Node3D) -> void:
	# Physical timetable boards follow the active service.
	# Runs once the Slice 77 upgrades exist, and again on
	# every service switch (cheap: 4 labels, text only).
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	if ctrl == null:
		return
	var express := int(ctrl.get("service79")) == 1
	var text := BOARD_EXPRESS if express else BOARD_LOCAL
	for si in range(4):
		var grp := world.get_node_or_null("LongRoute74/BusStop74_%d" % si) as Node3D
		if grp == null:
			continue
		var lab := grp.get_node_or_null("Upgrades77/BoardLabel77") as Label3D
		if lab != null:
			lab.text = text


func _physics_process(delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _hud_done:
		_hud_done = _try_hud(world)
	if not _boards_done:
		# Slice 77 upgrades land deferred; retry until the
		# first board exists, then sync once (later syncs
		# happen on service switches).
		var g0 := world.get_node_or_null("LongRoute74/BusStop74_0") as Node3D
		if g0 != null and g0.get_node_or_null("Upgrades77/BoardLabel77") != null:
			_sync_boards(world)
			_boards_done = true
	var bus := world.get_node_or_null("Bus") as Node3D
	var player := world.get_node_or_null("Player") as Node3D
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	var sim77 := world.get_node_or_null("BusSim77") as Node3D
	var driving_bus := false
	if bus != null and player != null:
		driving_bus = bool(player.get("driving")) and player.get("driving_vehicle") == bus
	if _service_btn != null:
		_service_btn.visible = driving_bus
		if ctrl != null:
			_sync_button(ctrl)
	if _summary_timer > 0.0:
		_summary_timer -= delta
		if _summary_timer <= 0.0 and _summary_label != null:
			_summary_label.visible = false
	if ctrl == null:
		return
	# On-time counting via the Slice 77 feedback sequence
	# (never by reading label text).
	if sim77 != null:
		var seq := int(sim77.get("feedback_seq79"))
		if seq != _last_fb_seq:
			_last_fb_seq = seq
			if bool(sim77.get("last_feedback_ontime79")):
				_svc_ontime += 1
	var dir := int(ctrl.get("direction"))
	var nxt := int(ctrl.get("next_stop"))
	if not _observed:
		_observed = true
		_prev_dir = dir
		_prev_next = nxt
		_svc_start_boarded = int(ctrl.get("boarded_total"))
		_svc_serves = 0
		_svc_ontime = 0
		return
	if dir != _prev_dir or nxt != _prev_next:
		# An in-order serve changed the route state (only
		# the in-order path moves next_stop/direction).
		_svc_serves += 1
		if _prev_dir == 1 and _prev_next == 0 and dir == 0 and nxt == 0:
			# Round trip complete: finalise this service's
			# counts; they show at the next depot arrival.
			# A previous uncollected summary is replaced.
			_pend_serves = _svc_serves
			_pend_carried = int(ctrl.get("boarded_total")) - _svc_start_boarded
			_pend_ontime = _svc_ontime
			_pending = true
			_svc_serves = 0
			_svc_start_boarded = int(ctrl.get("boarded_total"))
			_svc_ontime = 0
		_prev_dir = dir
		_prev_next = nxt
	# Depot arrival with a pending summary: show it for
	# SUMMARY_S, then clear. The Slice 78 fresh-service
	# line shows at the same moment on its own label —
	# different message, different rect, no fight.
	if _pending and bus != null and driving_bus:
		var d := Vector2(bus.global_position.x - DEPOT_POS.x, bus.global_position.z - DEPOT_POS.z).length()
		if d < DEPOT_R:
			_pending = false
			if _summary_label != null:
				_summary_label.text = "ဝန်ဆောင်မှုပြီးပြီ ✓\nမှတ်တိုင် %s · ခရီးသည် %s · အချိန်မှန် %s" % [_my_num(_pend_serves), _my_num(_pend_carried), _my_num(_pend_ontime)]
				_summary_label.visible = true
			_summary_timer = SUMMARY_S
	if _summary_label != null and not driving_bus:
		_summary_label.visible = false
