extends CanvasLayer
## Slice 160 — Custom Controls layout editor (owner order 2026-10-28
## 19:47 +07: Settings must let the player place the user controls
## however they like). Code-only editor, no scene file touched.
##
## Design (read before touching):
## - The editor shows DRAG PROXIES, never the real HUD buttons, so
##   editing can never fire a game action. Proxies are Panels;
##   the only Buttons in the editor are Done / Cancel / Reset /
##   the three view toggles, all wired to editor methods only.
## - Positions are stored as CENTRE fractions of the viewport in
##   SaveManager.custom_controls (key -> {"x": float, "y": float}).
##   Centres are scale-invariant: player _apply_hud_scale scales
##   every HUD control around its own centre, so a stored centre
##   stays exactly where the player put it at any HUD size.
## - hud157.gd applies the custom map at the END of its every-frame
##   _apply_layout, so Done applies live in game with no restart,
##   and an empty map means exactly the S157 defaults.
## - Two slot keys: horn buttons share ONE position in game (all
##   horn buttons are placed at the same cell, only one visible
##   per vehicle), and context buttons share ONE slot (only one
##   designed visible at a time). Moving the Horn/Context proxy
##   moves the whole slot. Per-button positions for those families
##   would be uneditable overlap, so slots are the honest unit.
## - Three views (foot / drive / fly) because the same cell is
##   reused across states (Talk vs ThrottleUp, Sprint vs
##   ThrottleDown, Vehicle 76 vs 96): views show only the units
##   of that state, so no two proxies ever overlap. A custom
##   centre is shared across views (one position per control).
## - Clamp margin 8 px: no proxy centre can leave the rendered
##   rect (proxy size = base size x HUD scale) outside the screen.
## - The editor layer runs PROCESS_MODE_ALWAYS: the pause menu
##   sets get_tree().paused = true, and input would otherwise
##   never reach the editor from pause settings.
## - NOT in scope (ordered): per-button hide/show (a hidden
##   essential button could strand the player), per-button resize
##   (HUD size 0.8-1.25 already covers size).

const CLAMP_MARGIN: float = 8.0
const HORN_SLOT: String = "HornSlot160"
const CONTEXT_SLOT: String = "ContextSlot160"

const HORN_FAMILY: Array = [
	"HornButton17", "HornButton80", "BellButton17",
	"TrumpetButton18", "WhistleButton19",
]
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
const SECONDARY: Array = [
	"MoreButton61b", "PauseButton21", "MapButton28",
	"CameraResetButton", "GarageButton60", "MuteButton18",
	"PhotoButton17", "RainButton17", "ViewButton96",
]

static func slot_key(nm: String) -> String:
	if HORN_FAMILY.has(nm):
		return HORN_SLOT
	if CONTEXT.has(nm):
		return CONTEXT_SLOT
	return nm

static func clamp_centre(c: Vector2, size: Vector2, vs: Vector2) -> Vector2:
	var x: float = clampf(c.x, size.x * 0.5 + CLAMP_MARGIN, vs.x - size.x * 0.5 - CLAMP_MARGIN)
	var y: float = clampf(c.y, size.y * 0.5 + CLAMP_MARGIN, vs.y - size.y * 0.5 - CLAMP_MARGIN)
	return Vector2(x, y)

static func units_for_view(view: String) -> Array:
	# Visibility-grounded (player.gd / bus_sim80.gd): Lights shows
	# only while driving Car/Motorcycle/TukTuk, Horn only while
	# driving, Request only while driving a bus — so those three
	# live in the drive view only (their stored position applies
	# in every state; they are simply invisible elsewhere).
	# Context shows on foot + drive (place interactions). The
	# foot view is pairwise overlap-free; drive/fly inherit one
	# small S157 overlap (Talk driving column vs the View corner
	# of the secondary row) — every proxy stays grabbable via
	# its uncovered area, so it is noted, not hidden.
	var units: Array = ["Joystick"]
	if view == "foot":
		units += ["TalkButton", "SprintButton", "JumpButton", "VehicleButton", "OrbitButton"]
		units += [CONTEXT_SLOT]
	elif view == "fly":
		units += ["TalkButton", "VehicleButton", "ThrottleUpButton", "ThrottleDownButton", "YawLeftButton", "YawRightButton"]
	else:
		units += ["TalkButton", "VehicleButton"]
		units += [HORN_SLOT, "LightsButton", "RequestButton80", CONTEXT_SLOT]
	units += SECONDARY
	return units

static func unit_label(key: String) -> String:
	match key:
		"Joystick":
			return "Joystick"
		"TalkButton":
			return "Talk"
		"SprintButton":
			return "Sprint"
		"JumpButton":
			return "Jump"
		"VehicleButton":
			return "Vehicle"
		"ThrottleUpButton":
			return "ThrUp"
		"ThrottleDownButton":
			return "ThrDn"
		"YawLeftButton":
			return "YawL"
		"YawRightButton":
			return "YawR"
		"OrbitButton":
			return "Orbit"
		"HornSlot160":
			return "Horn"
		"LightsButton":
			return "Lights"
		"RequestButton80":
			return "Request"
		"ContextSlot160":
			return "Context"
		"MoreButton61b":
			return "More"
		"PauseButton21":
			return "Pause"
		"MapButton28":
			return "Map"
		"CameraResetButton":
			return "Camera"
		"GarageButton60":
			return "Garage"
		"MuteButton18":
			return "Mute"
		"PhotoButton17":
			return "Photo"
		"RainButton17":
			return "Rain"
		"ViewButton96":
			return "View"
	return key

static func unit_base_size(key: String, view: String) -> Vector2:
	if key == "Joystick":
		return Vector2(320.0, 320.0)
	if key == "VehicleButton" and view != "foot":
		return Vector2(96.0, 96.0)
	if SECONDARY.has(key):
		if key == "MoreButton61b" or key == "PauseButton21":
			return Vector2(64.0, 44.0)
		return Vector2(104.0, 44.0)
	return Vector2(76.0, 76.0)

## S157 on-foot / driving / flying default centres, replicating
## hud157.gd _apply_layout exactly (MARGIN 24, ACT 76, BIG 96,
## GAP 24, JOY 320, secondary row y 288). The sim proves these
## against hud157's live defaults, so drift here is caught.
static func default_centre(key: String, view: String, vs: Vector2) -> Vector2:
	var w: float = vs.x
	var h: float = vs.y
	match key:
		"Joystick":
			return Vector2(184.0, h - 184.0)
		"TalkButton":
			if view == "foot":
				return Vector2(w - 162.0, h - 162.0)
			return Vector2(w - 62.0, h - 382.0)
		"SprintButton":
			return Vector2(w - 162.0, h - 62.0)
		"JumpButton":
			return Vector2(w - 62.0, h - 62.0)
		"VehicleButton":
			if view == "foot":
				return Vector2(w - 62.0, h - 162.0)
			if view == "fly":
				return Vector2(w - 72.0, h - 272.0)
			return Vector2(w - 72.0, h - 72.0)
		"ThrottleUpButton":
			return Vector2(w - 162.0, h - 162.0)
		"ThrottleDownButton":
			return Vector2(w - 162.0, h - 62.0)
		"YawLeftButton":
			return Vector2(w - 62.0, h - 162.0)
		"YawRightButton":
			return Vector2(w - 62.0, h - 62.0)
		"OrbitButton":
			return Vector2(62.0, h - 438.0)
		"HornSlot160":
			return Vector2(w - 62.0, h - 182.0)
		"LightsButton":
			return Vector2(w - 62.0, h - 282.0)
		"RequestButton80":
			return Vector2(w - 182.0, h - 62.0)
		"ContextSlot160":
			return Vector2(w - 262.0, h - 162.0)
		"ViewButton96":
			return Vector2(w - 76.0, 310.0)
		"RainButton17":
			return Vector2(w - 208.0, 310.0)
		"PhotoButton17":
			return Vector2(w - 336.0, 310.0)
		"MuteButton18":
			return Vector2(w - 464.0, 310.0)
		"GarageButton60":
			return Vector2(w - 592.0, 310.0)
		"CameraResetButton":
			return Vector2(w - 720.0, 310.0)
		"MapButton28":
			return Vector2(w - 848.0, 310.0)
		"PauseButton21":
			return Vector2(w - 956.0, 310.0)
		"MoreButton61b":
			return Vector2(w - 1048.0, 310.0)
	return Vector2(w * 0.5, h * 0.5)

class Proxy160 extends Panel:
	var pkey: String = ""
	var editor = null
	var _grab_index: int = -2
	var _grab_last: Vector2 = Vector2.ZERO

	func _gui_input(event: InputEvent) -> void:
		if editor == null:
			return
		if event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			if st.pressed and _grab_index == -2:
				_grab_index = st.index
				_grab_last = st.position
			elif not st.pressed and st.index == _grab_index:
				_grab_index = -2
		elif event is InputEventScreenDrag:
			var sd := event as InputEventScreenDrag
			if sd.index == _grab_index:
				var delta: Vector2 = sd.position - _grab_last
				_grab_last = sd.position
				editor.call("drag_proxy", pkey, delta)
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed and _grab_index == -2:
					_grab_index = -1
					_grab_last = mb.position
				elif not mb.pressed and _grab_index == -1:
					_grab_index = -2
		elif event is InputEventMouseMotion:
			var mm := event as InputEventMouseMotion
			if _grab_index == -1 and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
				var delta2: Vector2 = mm.position - _grab_last
				_grab_last = mm.position
				editor.call("drag_proxy", pkey, delta2)

var _view: String = "foot"
var _proxies: Dictionary = {}
var _draft: Dictionary = {}
var _dim: ColorRect = null
var _toggle_btns: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_build_chrome()
	_build_view()

func _sm():
	return get_node_or_null("/root/SaveManager")

func _vs() -> Vector2:
	return get_viewport().get_visible_rect().size

func _hud_scale() -> float:
	var sm = _sm()
	if sm != null and sm.get("hud_scale") != null:
		return clampf(float(sm.get("hud_scale")), 0.8, 1.25)
	return 1.0

func _saved_centre(key: String, vs: Vector2) -> Vector2:
	var sm = _sm()
	if sm != null and sm.get("custom_controls") != null:
		var cmap: Dictionary = sm.get("custom_controls")
		if cmap.has(key):
			var e = cmap[key]
			if e is Dictionary and (e as Dictionary).has("x") and (e as Dictionary).has("y"):
				return Vector2(clampf(float((e as Dictionary)["x"]), 0.0, 1.0) * vs.x, clampf(float((e as Dictionary)["y"]), 0.0, 1.0) * vs.y)
	return default_centre(key, _view, vs)

func _glass_proxy(round: bool, size: Vector2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.20, 0.32, 0.75)
	if round:
		var r: int = int(size.x / 2.0)
		sb.corner_radius_top_left = r
		sb.corner_radius_top_right = r
		sb.corner_radius_bottom_left = r
		sb.corner_radius_bottom_right = r
	else:
		sb.set_corner_radius_all(12)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.96, 0.88, 0.55)
	sb.shadow_size = 6
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	sb.shadow_offset = Vector2(0.0, 3.0)
	return sb

func _glass_btn() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.16, 0.28, 0.55)
	sb.set_corner_radius_all(12)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.96, 0.88, 0.55)
	sb.shadow_size = 4
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_offset = Vector2(0.0, 2.0)
	return sb

func _build_chrome() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim160"
	_dim.color = Color(0.0, 0.0, 0.0, 0.6)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.anchor_left = 0.0
	_dim.anchor_top = 0.0
	_dim.anchor_right = 1.0
	_dim.anchor_bottom = 1.0
	add_child(_dim)
	var title := Label.new()
	title.name = "Title160"
	title.text = "ခလုတ်နေရာ ပြင်"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.anchor_left = 0.5
	title.anchor_top = 0.0
	title.anchor_right = 0.5
	title.anchor_bottom = 0.0
	title.offset_left = -200.0
	title.offset_top = 8.0
	title.offset_right = 200.0
	title.offset_bottom = 48.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	add_child(title)
	var hint := Label.new()
	hint.name = "Hint160"
	hint.text = "ဆွဲပြီး ရွှေ့ပါ · Done = သိမ်း · Cancel = မသိမ်း · Reset = မူလအတိုင်း"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.anchor_left = 0.5
	hint.anchor_top = 0.0
	hint.anchor_right = 0.5
	hint.anchor_bottom = 0.0
	hint.offset_left = -360.0
	hint.offset_top = 50.0
	hint.offset_right = 360.0
	hint.offset_bottom = 78.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	add_child(hint)
	var views: Array = [["foot", "ခြေလျင်"], ["drive", "မောင်းနေစဉ်"], ["fly", "ပျံနေစဉ်"]]
	var tx: float = 16.0
	for v in views:
		var b := Button.new()
		b.name = "View160_" + str(v[0])
		b.text = str(v[1])
		b.anchor_left = 0.0
		b.anchor_top = 0.0
		b.anchor_right = 0.0
		b.anchor_bottom = 0.0
		b.offset_left = tx
		b.offset_top = 12.0
		b.offset_right = tx + 140.0
		b.offset_bottom = 56.0
		b.add_theme_stylebox_override("normal", _glass_btn())
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_on_view_pressed.bind(str(v[0])))
		add_child(b)
		_toggle_btns[str(v[0])] = b
		tx += 152.0
	var acts: Array = [["Done160", "Done", "_on_done_pressed"], ["Cancel160", "Cancel", "_on_cancel_pressed"], ["Reset160", "Reset", "_on_reset_pressed"]]
	var ax: float = 16.0
	for a in acts:
		var b2 := Button.new()
		b2.name = str(a[0])
		b2.text = str(a[1])
		b2.anchor_left = 1.0
		b2.anchor_top = 0.0
		b2.anchor_right = 1.0
		b2.anchor_bottom = 0.0
		b2.offset_left = -ax - 120.0
		b2.offset_top = 12.0
		b2.offset_right = -ax
		b2.offset_bottom = 56.0
		b2.add_theme_stylebox_override("normal", _glass_btn())
		b2.add_theme_font_size_override("font_size", 20)
		b2.pressed.connect(Callable(self, str(a[2])))
		add_child(b2)
		ax += 132.0

func _clear_proxies() -> void:
	# Immediate free (not queue_free): a same-frame rebuild must
	# not leave stale same-name nodes behind, or node lookups
	# return the stale proxy instead of the new one.
	for k in _proxies.keys():
		var p = _proxies[k]
		if is_instance_valid(p):
			(p as Node).free()
	_proxies.clear()

func _build_view() -> void:
	_clear_proxies()
	var vs: Vector2 = _vs()
	var sc: float = _hud_scale()
	for key in units_for_view(_view):
		var k: String = str(key)
		var base: Vector2 = unit_base_size(k, _view)
		var size: Vector2 = base * sc
		var centre: Vector2
		if _draft.has(k):
			centre = _draft[k]
		else:
			centre = _saved_centre(k, vs)
		centre = clamp_centre(centre, size, vs)
		var p := Proxy160.new()
		p.name = "Proxy160_" + k
		p.pkey = k
		p.editor = self
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.anchor_left = 0.0
		p.anchor_top = 0.0
		p.anchor_right = 0.0
		p.anchor_bottom = 0.0
		p.offset_left = centre.x - size.x * 0.5
		p.offset_top = centre.y - size.y * 0.5
		p.offset_right = centre.x + size.x * 0.5
		p.offset_bottom = centre.y + size.y * 0.5
		p.add_theme_stylebox_override("panel", _glass_proxy(k == "Joystick", size))
		var lab := Label.new()
		lab.name = "ProxyLabel160"
		lab.text = unit_label(k)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lab.anchor_left = 0.0
		lab.anchor_top = 0.0
		lab.anchor_right = 1.0
		lab.anchor_bottom = 1.0
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 18)
		p.add_child(lab)
		add_child(p)
		_proxies[k] = p

func drag_proxy(key: String, delta: Vector2) -> void:
	if not _proxies.has(key):
		return
	var p: Control = _proxies[key]
	var vs: Vector2 = _vs()
	# Capture size FIRST: offsets are mutated one by one below,
	# and a live p.size read after offset_left moves would use
	# the stale right edge and balloon the rect (proven: a 76 px
	# proxy became 662x382 from exactly this).
	var sz: Vector2 = p.size
	var centre: Vector2 = Vector2(p.offset_left + sz.x * 0.5, p.offset_top + sz.y * 0.5) + delta
	centre = clamp_centre(centre, sz, vs)
	p.offset_left = centre.x - sz.x * 0.5
	p.offset_top = centre.y - sz.y * 0.5
	p.offset_right = centre.x + sz.x * 0.5
	p.offset_bottom = centre.y + sz.y * 0.5
	_draft[key] = centre

## Sim + programmatic entry: move a proxy to an absolute centre
## (clamped), marking it moved. Real drags go through drag_proxy.
func move_proxy(key: String, centre: Vector2) -> void:
	if not _proxies.has(key):
		return
	var p: Control = _proxies[key]
	var vs: Vector2 = _vs()
	# Same capture-first rule as drag_proxy (see above).
	var sz: Vector2 = p.size
	centre = clamp_centre(centre, sz, vs)
	p.offset_left = centre.x - sz.x * 0.5
	p.offset_top = centre.y - sz.y * 0.5
	p.offset_right = centre.x + sz.x * 0.5
	p.offset_bottom = centre.y + sz.y * 0.5
	_draft[key] = centre

func proxy_centre(key: String) -> Vector2:
	if not _proxies.has(key):
		return Vector2(-1.0, -1.0)
	var p: Control = _proxies[key]
	return Vector2(p.offset_left + p.size.x * 0.5, p.offset_top + p.size.y * 0.5)

func proxy_count() -> int:
	return _proxies.size()

func current_view() -> String:
	return _view

func switch_view(view: String) -> void:
	if view != "foot" and view != "drive" and view != "fly":
		return
	_view = view
	_build_view()

func _on_view_pressed(view: String) -> void:
	switch_view(view)

func _on_done_pressed() -> void:
	var sm = _sm()
	var vs: Vector2 = _vs()
	if sm != null and sm.get("custom_controls") != null:
		var cmap: Dictionary = sm.get("custom_controls")
		for k in _draft.keys():
			var c: Vector2 = _draft[k]
			cmap[str(k)] = {"x": c.x / vs.x, "y": c.y / vs.y}
		sm.set("custom_controls", cmap)
		sm.call("save_settings")
	queue_free()

func _on_cancel_pressed() -> void:
	queue_free()

func _on_reset_pressed() -> void:
	var sm = _sm()
	if sm != null:
		sm.set("custom_controls", {})
		sm.call("save_settings")
	_draft.clear()
	_build_view()
