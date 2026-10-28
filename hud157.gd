extends Node
## Slice 157 — user-control HUD overhaul (owner order 2026-10-27 20:31
## +07: buttons are not user-friendly, fix UI/style/layout FIRST,
## one hour, everything else stopped). PUBG/MLBB-style layout,
## enforced every frame at late process priority so it wins over
## scene rects and the Slice 61 dress in every state (on-foot,
## driving, flying). Runtime-only: no scene file is touched.
##
## What it does:
## - ONE consistent button style: round 76 px action buttons, one
##   96 px prominent Vehicle/Exit button while driving, one tidy
##   44 px secondary row under the minimap (More-gated, as before).
## - ONE contextual slot right of the action cluster: every place
##   button (fruit/tea/pray/offer/...) is moved to the same slot
##   column, stacked upward only if two ever show at once.
## - Quest + tracker + compass compact top-center; quest NEVER
##   mid-screen. Minimap top-right with a border, never obscured.
##   Speed + stamina bottom-center, overlapping nothing.
## - Buttons fire on touch-down: every tap button's pressed
##   connection is moved to button_down (hold buttons Sprint /
##   Throttle / Yaw already use button_down/up and are untouched).
##   pressed is disconnected so nothing double-fires.
## - Help "?" clutter removed (HelpButton + HelpLabel forced
##   hidden); touch-first, no keyboard key, no Zoom buttons.
## - HUD scale: managed nodes are JoystickLayer children, so the
##   existing player _apply_hud_scale (0.8-1.25) scales them too.
## Multi-touch: joystick and buttons are separate Controls with
## disjoint rects, so a held joystick + a tapped button both
## register (proven in sim157, not assumed).
## Designed states left alone: contextual buttons hidden when not
## near a place, More-gated secondary row, pause/world-map/guide
## overlays, transient labels (Prompt/Edge/Parachute).

const MARGIN: float = 24.0
const ACT: float = 76.0
const BIG: float = 96.0
const GAP: float = 24.0
const JOY: float = 320.0
const SEC_H: float = 44.0
const MM: float = 200.0

const CONTEXT: Array = [
	"FruitButton", "WaterButton", "BananaButton", "PrayButton",
	"TeaButton15", "BookButton15", "DrumButton16", "LanternButton16",
	"SnackButton16", "FishButton17", "DonateButton17", "MilkButton17",
	"WaterButton17", "FeedButton17", "OfferButton18", "PlantButton18",
	"RestButton18", "FeedButton18", "GoldButton19", "LessonButton19",
	"FeedHorseButton19", "NoodleButton20", "DrinkButton20",
	"SleepButton20", "GuestbookButton20", "EastFieldsButton64",
	"SightseeingButton54",
]
const HORN_FAMILY: Array = [
	"HornButton17", "HornButton80", "BellButton17",
	"TrumpetButton18", "WhistleButton19",
]
const HOLD_BUTTONS: Array = [
	"SprintButton", "ThrottleUpButton", "ThrottleDownButton",
	"YawLeftButton", "YawRightButton",
]
const LEAVE_ALONE: Array = [
	"GuidePanel34", "PausePanel21", "WorldMapPanel",
	"FruitWaterLabel", "RequestLabel80", "EdgeLabel38",
	"PromptLabel", "ParachuteLabel",
]

var _layer: CanvasLayer = null
var _player: Node = null
var _rewired: Dictionary = {}
var _seen_unmapped: Dictionary = {}
var _mapped: Dictionary = {}
var _round76: StyleBoxFlat = null
var _round76p: StyleBoxFlat = null
var _round96: StyleBoxFlat = null
var _round96p: StyleBoxFlat = null
var _rect44: StyleBoxFlat = null
var _rect44p: StyleBoxFlat = null
var _mm_style: StyleBoxFlat = null

# --- Slice 157 follow-up: HUD button feel (owner-approved 2026-10-27).
# Press animation + click SFX + haptics, code-only, riding the S157
# button_down wiring (nothing disconnected, nothing double-fires).
# Press = scale to rest x 0.88 on button_down; release = spring
# back to rest over 0.22 s (TRANS_BACK, S119 menu spring pattern).
# Rest scale is re-captured every frame while a button is neither
# pressed nor tweening, so HUD-scale changes (spawn / pause-resume
# only, player _apply_hud_scale) never drift the rest value, and a
# re-press mid-spring still springs back to the true rest scale.
# Clicks: one AudioStreamPlayer owned by this node, three generated
# short buffers (engine_audio65 / bus_sim80 one-shot pattern:
# 16-bit, 22050 Hz, LOOP_DISABLED, whole-cycle frequencies, decay
# envelope to zero so neither end clicks). Classes: primary 875 Hz,
# back 625 Hz, toggle 1125 Hz, all 0.08 s (70 / 50 / 90 cycles).
# Mute rule mirrors engine_audio65: SaveManager "muted" OR player
# sound_on off silences clicks — except the mute button itself,
# whose click always plays so the toggle action has feedback.
# Haptics: Input.vibrate_handheld(25 ms), Android-guarded; on any
# other OS the call is skipped and counted, never faked.
const PRESS_SCALE: float = 0.88
const SPRING_TIME: float = 0.22
const CLICK_DB: float = -14.0
const CLICK_HZ: int = 22050
const CLICK_SEC: float = 0.08
const CLICK_PRIMARY: float = 875.0
const CLICK_BACK: float = 625.0
const CLICK_TOGGLE: float = 1125.0
const HAPTIC_MS: int = 25
const FEEL_BACK: Array = ["PauseButton21", "MapButton28"]
const FEEL_TOGGLE: Array = [
	"MuteButton18", "MoreButton61b", "RainButton17",
	"ViewButton96", "LightsButton",
]
var _feel: Dictionary = {}
var _feel_base: Dictionary = {}
var _feel_tween: Dictionary = {}
var _feel_pressed: Dictionary = {}
var _sfx_player: AudioStreamPlayer = null
var _click_primary: AudioStreamWAV = null
var _click_back: AudioStreamWAV = null
var _click_toggle: AudioStreamWAV = null
var _haptic_guarded: int = 0
var _haptic_calls: int = 0
# Slice 158: vibration-off presses are counted, never silently
# dropped, so the toggle gate is sim-provable on non-Android
# headless runs (where vibrate_handheld is guarded anyway).
var _vibration_skipped: int = 0

func _ready() -> void:
	set_process_priority(1000)
	var p := get_parent()
	if p is CanvasLayer:
		_layer = p
	else:
		_layer = get_node_or_null("../JoystickLayer") as CanvasLayer
	if _layer == null:
		return
	var main := _layer.get_parent()
	if main != null:
		_player = main.get_node_or_null("Player")
	# Slice 159 Liquid Glass: HUD buttons go from near-opaque
	# dark chips to translucent dark glass (normal more
	# see-through, pressed deeper) + the pale rim from _mk_*.
	_round76 = _mk_round(ACT, Color(0.10, 0.13, 0.22, 0.50))
	_round76p = _mk_round(ACT, Color(0.16, 0.20, 0.32, 0.70))
	_round96 = _mk_round(BIG, Color(0.10, 0.13, 0.22, 0.50))
	_round96p = _mk_round(BIG, Color(0.16, 0.20, 0.32, 0.70))
	_rect44 = _mk_rect(Color(0.10, 0.13, 0.22, 0.50))
	_rect44p = _mk_rect(Color(0.16, 0.20, 0.32, 0.70))
	_mm_style = StyleBoxFlat.new()
	_mm_style.bg_color = Color(0.08, 0.10, 0.18, 0.55)
	_mm_style.border_color = Color(1.0, 0.96, 0.88, 0.55)
	_mm_style.border_width_left = 2
	_mm_style.border_width_top = 2
	_mm_style.border_width_right = 2
	_mm_style.border_width_bottom = 2
	_mm_style.corner_radius_top_left = 12
	_mm_style.corner_radius_top_right = 12
	_mm_style.corner_radius_bottom_left = 12
	_mm_style.corner_radius_bottom_right = 12
	_mm_style.shadow_size = 6
	_mm_style.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	_mm_style.shadow_offset = Vector2(0.0, 3.0)
	for nm in [
		"Joystick", "TalkButton", "SprintButton", "JumpButton",
		"VehicleButton", "ThrottleUpButton", "ThrottleDownButton",
		"YawLeftButton", "YawRightButton", "OrbitButton",
		"QuestLabel", "QuestTrackerLabel", "CompassLabel",
		"DistrictLabel60", "EastFieldsLabel64",
		"ClockLabel", "DayLabel", "MinimapPanel", "SpeedLabel",
		"StaminaBar", "SpeedBar", "StaminaLabel61b", "FpsLabel40",
		"HelpButton", "HelpLabel", "LightsButton", "RequestButton80",
		"MoreButton61b", "PauseButton21", "MapButton28",
		"CameraResetButton", "GarageButton60", "MuteButton18",
		"PhotoButton17", "RainButton17", "ViewButton96",
	]:
		_mapped[nm] = true
	for nm in CONTEXT:
		_mapped[nm] = true
	for nm in HORN_FAMILY:
		_mapped[nm] = true
	_apply_layout()
	# Slice 159: minimap top specular strip — IGNORE, index 0
	# (behind the map dots), added once. _apply_layout runs
	# every frame but only re-applies the stylebox; the strip
	# children persist untouched.
	var mm := _ctl("MinimapPanel")
	if mm is Panel and (mm as Panel).get_node_or_null("GlassStrip159_Line") == null:
		var mm_band := ColorRect.new()
		mm_band.name = "GlassStrip159_Band"
		mm_band.color = Color(1.0, 1.0, 1.0, 0.10)
		mm_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mm_band.anchor_left = 0.0
		mm_band.anchor_right = 1.0
		mm_band.anchor_top = 0.0
		mm_band.anchor_bottom = 0.0
		mm_band.offset_left = 12.0
		mm_band.offset_right = -12.0
		mm_band.offset_top = 3.0
		mm_band.offset_bottom = 13.0
		(mm as Panel).add_child(mm_band)
		(mm as Panel).move_child(mm_band, 0)
		var mm_line := ColorRect.new()
		mm_line.name = "GlassStrip159_Line"
		mm_line.color = Color(1.0, 1.0, 1.0, 0.45)
		mm_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mm_line.anchor_left = 0.0
		mm_line.anchor_right = 1.0
		mm_line.anchor_top = 0.0
		mm_line.anchor_bottom = 0.0
		mm_line.offset_left = 12.0
		mm_line.offset_right = -12.0
		mm_line.offset_top = 3.0
		mm_line.offset_bottom = 5.0
		(mm as Panel).add_child(mm_line)
		(mm as Panel).move_child(mm_line, 0)
	_rewire_all()
	_init_sfx()
	_wire_feel()

func _mk_round(size: float, col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	var r: int = int(size / 2.0)
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	# Slice 159 Liquid Glass: frosted pale rim + soft shadow.
	# Fill translucency + rim carry the glass read; no blur
	# shader (unavailable on this gl_compatibility renderer).
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.96, 0.88, 0.50)
	sb.shadow_size = 6
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	sb.shadow_offset = Vector2(0.0, 3.0)
	return sb

func _mk_rect(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.96, 0.88, 0.50)
	sb.shadow_size = 6
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	sb.shadow_offset = Vector2(0.0, 3.0)
	return sb

func _process(_delta: float) -> void:
	if _layer == null:
		return
	_apply_layout()
	_rewire_all()
	_wire_feel()
	_refresh_feel_rest()
	_recover_stuck_presses()
	_report_unmapped()

func _ctl(nm: String) -> Control:
	if _layer == null:
		return null
	return _layer.get_node_or_null(nm) as Control

func _btn(nm: String) -> Button:
	return _ctl(nm) as Button

# Right-bottom anchored cell: dx = px from right edge, dy = px from
# bottom edge.
func _br(c: Control, dx: float, dy: float, w: float, h: float) -> void:
	c.anchor_left = 1.0
	c.anchor_top = 1.0
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = -dx - w
	c.offset_top = -dy - h
	c.offset_right = -dx
	c.offset_bottom = -dy

func _bl(c: Control, mx: float, my: float, w: float, h: float) -> void:
	c.anchor_left = 0.0
	c.anchor_top = 1.0
	c.anchor_right = 0.0
	c.anchor_bottom = 1.0
	c.offset_left = mx
	c.offset_top = -my - h
	c.offset_right = mx + w
	c.offset_bottom = -my

func _bc(c: Control, dy: float, w: float, h: float) -> void:
	c.anchor_left = 0.5
	c.anchor_top = 1.0
	c.anchor_right = 0.5
	c.anchor_bottom = 1.0
	c.offset_left = -w / 2.0
	c.offset_top = -dy - h
	c.offset_right = w / 2.0
	c.offset_bottom = -dy

func _tc(c: Control, dy: float, w: float, h: float) -> void:
	c.anchor_left = 0.5
	c.anchor_top = 0.0
	c.anchor_right = 0.5
	c.anchor_bottom = 0.0
	c.offset_left = -w / 2.0
	c.offset_top = dy
	c.offset_right = w / 2.0
	c.offset_bottom = dy + h

func _tr(c: Control, dx: float, dy: float, w: float, h: float) -> void:
	c.anchor_left = 1.0
	c.anchor_top = 0.0
	c.anchor_right = 1.0
	c.anchor_bottom = 0.0
	c.offset_left = -dx - w
	c.offset_top = dy
	c.offset_right = -dx
	c.offset_bottom = dy + h

func _tl(c: Control, mx: float, my: float, w: float, h: float) -> void:
	c.anchor_left = 0.0
	c.anchor_top = 0.0
	c.anchor_right = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = mx
	c.offset_top = my
	c.offset_right = mx + w
	c.offset_bottom = my + h

func _style_round(b: Button, big: bool, font_size: int) -> void:
	if big:
		b.add_theme_stylebox_override("normal", _round96)
		b.add_theme_stylebox_override("pressed", _round96p)
	else:
		b.add_theme_stylebox_override("normal", _round76)
		b.add_theme_stylebox_override("pressed", _round76p)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	b.mouse_filter = Control.MOUSE_FILTER_STOP

func _style_rect(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _rect44)
	b.add_theme_stylebox_override("pressed", _rect44p)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	b.mouse_filter = Control.MOUSE_FILTER_STOP

func _driving() -> bool:
	if _player == null:
		return false
	return bool(_player.get("driving"))

func _flying() -> bool:
	if not _driving() or _player == null:
		return false
	var v: Node = _player.get("driving_vehicle")
	if v == null:
		return false
	return String(v.name) in ["Airplane", "Helicopter"]

func _apply_layout() -> void:
	var col2: float = MARGIN
	var col1: float = MARGIN + ACT + GAP
	var row2: float = MARGIN
	var row1: float = MARGIN + ACT + GAP
	# Joystick: generous bottom-left zone, no other control inside.
	var joy := _ctl("Joystick")
	if joy != null:
		_bl(joy, MARGIN, MARGIN, JOY, JOY)
	# Action cluster, on-foot 2x2 (Talk / Vehicle / Sprint / Jump).
	# While driving, Talk moves to the tall driving column above
	# the lights cell, so it never touches the big exit button.
	var talk := _btn("TalkButton")
	if talk != null:
		if _driving():
			_br(talk, MARGIN, MARGIN + BIG + GAP + ACT + GAP + ACT + GAP, ACT, ACT)
		else:
			_br(talk, col1, row1, ACT, ACT)
		_style_round(talk, false, 22)
	var sprint := _btn("SprintButton")
	if sprint != null:
		_br(sprint, col1, row2, ACT, ACT)
		_style_round(sprint, false, 22)
	var jump := _btn("JumpButton")
	if jump != null:
		_br(jump, col2, row2, ACT, ACT)
		_style_round(jump, false, 22)
	# Vehicle: big prominent corner button while driving (exit),
	# above the flying grid while flying (the grid cells would
	# otherwise sit under the corner button), normal cluster cell
	# on foot (enter).
	var veh := _btn("VehicleButton")
	if veh != null:
		if _flying():
			_br(veh, MARGIN, row1 + ACT + GAP, BIG, BIG)
			_style_round(veh, true, 22)
		elif _driving():
			_br(veh, MARGIN, MARGIN, BIG, BIG)
			_style_round(veh, true, 22)
		else:
			_br(veh, col2, row1, ACT, ACT)
			_style_round(veh, false, 22)
	# Driving column above the exit button: horn family (mutually
	# exclusive by vehicle), lights above that.
	var horn_dy: float = MARGIN + BIG + GAP
	for nm in HORN_FAMILY:
		var hb := _btn(nm)
		if hb != null:
			_br(hb, MARGIN, horn_dy, ACT, ACT)
			_style_round(hb, false, 22)
	var lights := _btn("LightsButton")
	if lights != null:
		_br(lights, MARGIN, horn_dy + ACT + GAP, ACT, ACT)
		_style_round(lights, false, 22)
	# Bus request-stop: left of the exit button, bottom-aligned.
	var req := _btn("RequestButton80")
	if req != null:
		_br(req, MARGIN + BIG + GAP, MARGIN, ACT, ACT)
		_style_round(req, false, 20)
	# Flying grid (same cells as the on-foot cluster; sprint/jump
	# are hidden while driving, so no cell is ever double-booked).
	var thr_u := _btn("ThrottleUpButton")
	if thr_u != null:
		_br(thr_u, col1, row1, ACT, ACT)
		_style_round(thr_u, false, 20)
	var yaw_l := _btn("YawLeftButton")
	if yaw_l != null:
		_br(yaw_l, col2, row1, ACT, ACT)
		_style_round(yaw_l, false, 20)
	var thr_d := _btn("ThrottleDownButton")
	if thr_d != null:
		_br(thr_d, col1, row2, ACT, ACT)
		_style_round(thr_d, false, 20)
	var yaw_r := _btn("YawRightButton")
	if yaw_r != null:
		_br(yaw_r, col2, row2, ACT, ACT)
		_style_round(yaw_r, false, 20)
	# ONE contextual slot, right of the cluster, stacked upward
	# only if two ever show at once (designed state is one).
	var slot_dx: float = MARGIN + 2.0 * ACT + 2.0 * GAP
	var slot_dy: float = MARGIN + ACT + GAP
	var slot_idx: int = 0
	for nm in CONTEXT:
		var cb := _btn(nm)
		if cb == null:
			continue
		_br(cb, slot_dx, slot_dy + float(slot_idx) * (ACT + GAP), ACT, ACT)
		_style_round(cb, false, 20)
		if cb.visible:
			slot_idx += 1
	# Orbit: above the joystick with 56 px clearance, so the
	# 320 px joystick zone cannot grow into it at HUD scale 1.25.
	var orbit := _btn("OrbitButton")
	if orbit != null:
		_bl(orbit, MARGIN, MARGIN + JOY + 56.0, ACT, ACT)
		_style_round(orbit, false, 20)
	# Top-center quest block: quest, tracker, compass. NEVER
	# mid-screen over the vehicle.
	# Top-center quest block, 5 lines, 12 px gaps (survives
	# HUD scale 1.25 with ~4 px left). District60 + EastFields64
	# progress labels move here from mid-screen — they are
	# quest progress, not mid-screen banners.
	var q := _ctl("QuestLabel")
	if q != null:
		_tc(q, 8.0, 760.0, 32.0)
		if q is Label:
			(q as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(q as Label).add_theme_font_size_override("font_size", 22)
	var qt := _ctl("QuestTrackerLabel")
	if qt != null:
		_tc(qt, 52.0, 760.0, 30.0)
		if qt is Label:
			(qt as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(qt as Label).add_theme_font_size_override("font_size", 20)
	var dist := _ctl("DistrictLabel60")
	if dist != null:
		_tc(dist, 94.0, 760.0, 28.0)
		if dist is Label:
			(dist as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(dist as Label).add_theme_font_size_override("font_size", 18)
	var ef := _ctl("EastFieldsLabel64")
	if ef != null:
		_tc(ef, 134.0, 760.0, 28.0)
		if ef is Label:
			(ef as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(ef as Label).add_theme_font_size_override("font_size", 18)
	var comp := _ctl("CompassLabel")
	if comp != null:
		_tc(comp, 174.0, 300.0, 26.0)
		if comp is Label:
			(comp as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(comp as Label).add_theme_font_size_override("font_size", 18)
	# Top-right: clock + day line, minimap with border, then ONE
	# tidy secondary row (More-gated visibility kept as before).
	var clock := _ctl("ClockLabel")
	if clock != null:
		_tr(clock, MARGIN, 12.0, 230.0, 32.0)
		if clock is Label:
			(clock as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			(clock as Label).add_theme_font_size_override("font_size", 18)
	var day := _ctl("DayLabel")
	if day != null:
		_tr(day, MARGIN + 230.0 + 12.0, 12.0, 170.0, 32.0)
		if day is Label:
			(day as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			(day as Label).add_theme_font_size_override("font_size", 18)
	var mm := _ctl("MinimapPanel")
	if mm != null:
		_tr(mm, MARGIN, 52.0, MM, MM)
		if mm is Panel:
			(mm as Panel).add_theme_stylebox_override("panel", _mm_style)
	var row_y: float = 52.0 + MM + 36.0
	var row_items: Array = [
		["MoreButton61b", 64.0], ["PauseButton21", 64.0],
		["MapButton28", 104.0], ["CameraResetButton", 104.0],
		["GarageButton60", 104.0], ["MuteButton18", 104.0],
		["PhotoButton17", 104.0], ["RainButton17", 104.0],
		["ViewButton96", 104.0],
	]
	var cursor: float = MARGIN
	for i in range(row_items.size() - 1, -1, -1):
		var nm: String = str(row_items[i][0])
		var w: float = float(row_items[i][1])
		var rb := _btn(nm)
		if rb == null:
			continue
		_tr(rb, cursor, row_y, w, SEC_H)
		_style_rect(rb)
		cursor += w + 28.0
	# Bottom-center speed + stamina, overlapping nothing.
	var spd := _ctl("SpeedLabel")
	if spd != null:
		_bc(spd, 108.0, 460.0, 30.0)
		if spd is Label:
			(spd as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(spd as Label).add_theme_font_size_override("font_size", 22)
	var sbar := _ctl("StaminaBar")
	if sbar != null:
		_bc(sbar, 72.0, 460.0, 16.0)
	var vbar := _ctl("SpeedBar")
	if vbar != null:
		_bc(vbar, 50.0, 460.0, 16.0)
	var slab := _ctl("StaminaLabel61b")
	if slab != null and sbar != null:
		slab.anchor_left = sbar.anchor_left
		slab.anchor_top = sbar.anchor_top
		slab.anchor_right = sbar.anchor_right
		slab.anchor_bottom = sbar.anchor_bottom
		slab.offset_left = sbar.offset_left
		slab.offset_top = sbar.offset_top
		slab.offset_right = sbar.offset_right
		slab.offset_bottom = sbar.offset_bottom
	var fps := _ctl("FpsLabel40")
	if fps != null:
		_tl(fps, 16.0, 12.0, 200.0, 28.0)
	# Help "?" clutter removed by owner order.
	var help_b := _btn("HelpButton")
	if help_b != null:
		help_b.visible = false
	var help_l := _ctl("HelpLabel")
	if help_l != null:
		help_l.visible = false

func _rewire_all() -> void:
	var tap: Array = [
		"TalkButton", "VehicleButton", "JumpButton", "OrbitButton",
		"MoreButton61b", "PauseButton21", "MapButton28",
		"CameraResetButton", "GarageButton60", "MuteButton18",
		"PhotoButton17", "RainButton17", "ViewButton96",
		"RequestButton80", "LightsButton",
	]
	for nm in HORN_FAMILY:
		tap.append(nm)
	for nm in CONTEXT:
		tap.append(nm)
	for nm in tap:
		var b := _btn(nm)
		if b == null or _rewired.has(b):
			continue
		var conns: Array = b.get_signal_connection_list("pressed")
		if conns.is_empty():
			continue
		var moved: bool = false
		for conn in conns:
			var cb: Callable = conn["callable"]
			if not b.button_down.is_connected(cb):
				b.button_down.connect(cb)
			if b.pressed.is_connected(cb):
				b.pressed.disconnect(cb)
			moved = true
		if moved:
			_rewired[b] = true

func _init_sfx() -> void:
	if _sfx_player != null:
		return
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "HudClick157"
	_sfx_player.volume_db = CLICK_DB
	add_child(_sfx_player)
	_click_primary = _make_click(CLICK_PRIMARY)
	_click_back = _make_click(CLICK_BACK)
	_click_toggle = _make_click(CLICK_TOGGLE)

func _make_click(freq: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = CLICK_HZ
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var frames := int(CLICK_HZ * CLICK_SEC)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(CLICK_HZ)
		var env := 1.0 - t / CLICK_SEC
		var v := sin(t * freq * TAU) * 0.6 * env
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 24000.0))
	wav.data = data
	return wav

func _feel_class(nm: String) -> String:
	if FEEL_BACK.has(nm):
		return "back"
	if FEEL_TOGGLE.has(nm):
		return "toggle"
	return "primary"

func _wire_feel() -> void:
	if _layer == null:
		return
	var names: Array = [
		"TalkButton", "VehicleButton", "JumpButton", "OrbitButton",
		"MoreButton61b", "PauseButton21", "MapButton28",
		"CameraResetButton", "GarageButton60", "MuteButton18",
		"PhotoButton17", "RainButton17", "ViewButton96",
		"RequestButton80", "LightsButton",
	]
	for nm in HORN_FAMILY:
		names.append(nm)
	for nm in CONTEXT:
		names.append(nm)
	for nm in HOLD_BUTTONS:
		names.append(nm)
	for nm in names:
		var b := _btn(nm)
		if b == null or _feel.has(b):
			continue
		var cls := _feel_class(nm)
		_feel[b] = cls
		_feel_base[b] = b.scale
		b.button_down.connect(_on_feel_down.bind(b, cls))
		b.button_up.connect(_on_feel_up.bind(b))

func _kill_feel_tween(b: Button) -> void:
	if not _feel_tween.has(b):
		return
	var tw: Tween = _feel_tween[b]
	if tw != null and tw.is_valid():
		tw.kill()
	_feel_tween.erase(b)

func _on_feel_down(b: Button, cls: String) -> void:
	_kill_feel_tween(b)
	var rest: Vector2 = _feel_base.get(b, b.scale)
	b.scale = rest * PRESS_SCALE
	_feel_pressed[b] = true
	_play_click(cls, b)
	_vibrate()

func _on_feel_up(b: Button) -> void:
	_feel_pressed.erase(b)
	_kill_feel_tween(b)
	var target: Vector2 = _feel_base.get(b, Vector2.ONE)
	var tw := create_tween()
	tw.tween_property(b, "scale", target, SPRING_TIME)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	_feel_tween[b] = tw

func _refresh_feel_rest() -> void:
	for b in _feel.keys():
		if not is_instance_valid(b):
			continue
		if _feel_pressed.has(b):
			continue
		if _feel_tween.has(b):
			var tw: Tween = _feel_tween[b]
			if tw != null and tw.is_valid():
				continue
			_feel_tween.erase(b)
		var ctl := b as Control
		ctl.pivot_offset = ctl.size * 0.5
		_feel_base[b] = ctl.scale

func _recover_stuck_presses() -> void:
	for b in _feel_pressed.keys():
		if not is_instance_valid(b):
			_feel_pressed.erase(b)
			continue
		if not (b as Control).visible:
			_on_feel_up(b)

func _sfx_muted() -> bool:
	if _player != null and _player.get("sound_on") != null and not bool(_player.get("sound_on")):
		return true
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.get("muted") != null and bool(sm.get("muted")):
		return true
	return false


# Slice 158: clicks obey master volume AND the new SFX volume
# (both 0 dB at 1.0, so defaults sound exactly as before).
func _vol_off() -> float:
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.has_method("volume_offset_db"):
		return float(sm.call("volume_offset_db"))
	return 0.0


func _sfx_off() -> float:
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.has_method("sfx_offset_db"):
		return float(sm.call("sfx_offset_db"))
	return 0.0


func _play_click(cls: String, b: Button) -> void:
	if _sfx_player == null:
		return
	if _sfx_muted() and String(b.name) != "MuteButton18":
		return
	_sfx_player.volume_db = CLICK_DB + _vol_off() + _sfx_off()
	if cls == "back":
		_sfx_player.stream = _click_back
	elif cls == "toggle":
		_sfx_player.stream = _click_toggle
	else:
		_sfx_player.stream = _click_primary
	_sfx_player.play()


func _vibrate() -> void:
	# Slice 158: the vibration setting gates S157 haptics.
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.get("vibration_enabled") != null and not bool(sm.get("vibration_enabled")):
		_vibration_skipped += 1
		return
	if OS.get_name() != "Android":
		_haptic_guarded += 1
		return
	_haptic_calls += 1
	Input.vibrate_handheld(HAPTIC_MS)

func _report_unmapped() -> void:
	if _layer == null:
		return
	for child in _layer.get_children():
		if not (child is Control):
			continue
		if not (child as Control).visible:
			continue
		var nm: String = String(child.name)
		if nm == "Hud157":
			continue
		if _mapped.has(nm):
			continue
		if LEAVE_ALONE.has(nm):
			continue
		if _seen_unmapped.has(nm):
			continue
		_seen_unmapped[nm] = true
		print("HUD157 UNMAPPED visible: ", nm, " ", (child as Control).get_global_rect())
