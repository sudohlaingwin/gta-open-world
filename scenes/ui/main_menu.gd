extends Control
## Slice 21 main menu: Continue (only when a valid save exists),
## New Game (fresh world), Settings (working settings only).
## Continue hands the loaded save to SaveManager.pending_load and the
## world player applies it on spawn; New Game clears pending_load so
## the world starts fresh. No decorative buttons: every button here
## does what it says.
## Slice 30 adds Character (wired exactly like Settings): it shows
## the outfit panel, whose choices persist in SaveManager settings
## and apply to the player at world spawn.
## Slice 35 adds Vehicle the same way: it shows the paint panel,
## whose choices persist in SaveManager settings and apply to the
## player vehicles at world spawn.

var continue_button: Button = null
var new_game_button: Button = null
var settings_button: Button = null
var character_button: Button = null
var vehicle_button: Button = null
var no_save_label: Label = null
var settings_panel: Node = null
var character_panel: Node = null
var vehicle_panel: Node = null
var loading_label: Label = null
var loading: bool = false
# Slice 61 addendum (owner 00:03: menu "no animation, dry/stiff"):
# code-only animation, no scene change. Title gently pulses,
# background colour drifts warm, every menu button punches on
# press (scale 1.0 -> 1.08 -> 1.0), panels scale in 0.92 -> 1.0
# when opened. All values are measured in the addendum sim.
var _menu_time: float = 0.0
var _pulse: float = 0.0
var _pulse_button: Button = null
var _title_label: Label = null
var _bg_rect: ColorRect = null
# Slice 109 (owner 2026-10-24 11:14 screenshot: menu reads as
# flat dark; S61's +-3% pulse + near-black drift do not read
# on the phone): code-only PUBG-style animated menu scene —
# sunset gradient sky + pulsing sun + drifting clouds + dark
# village silhouette row (houses + pagoda) + stronger title
# animation. Built LAST in _ready so a build failure cannot
# unwire buttons; inserted behind buttons/panels; old
# Background rect hidden (drift code left harmless).
var _title_base_pos: Vector2 = Vector2.ZERO
var _sun110: Panel = null
var _clouds110: Array = []
# Slice 119 (owner 2026-10-24 18:21: menu buttons DEAD + UI "shabby,
# no high-level animation"): P0 root cause — _build_scene110
# appended Cloud110_* + fullscreen Silhouette110 AFTER the buttons
# with Control's default MOUSE_FILTER_STOP, so the silhouette
# swallowed every touch. P0 fix: every decorative node (and all
# its descendants) gets MOUSE_FILTER_IGNORE, AND decor is moved
# behind the buttons/panels. P1: premium rebuild — parallax cloud
# layers, rotating sun rays, twinkling silhouette windows, title
# entrance + stronger float, button stagger-in with spring
# overshoot, press punch that actually fires (it never did while
# presses were blocked), gradient-look pill buttons with borders.
# All code-only; no scene change; Burmese labels unchanged.
var _subtitle_label: Label = null
var _subtitle_base_pos: Vector2 = Vector2.ZERO
var _rays110: Control = null
var _window_lights110: Array = []
var _button_base_pos: Dictionary = {}
var _layout_ready: bool = false
var _last_vp_size: Vector2 = Vector2.ZERO
var _vp_stable: int = 0
# Slice 158 (owner 2026-10-28: main menu SPECIAL + full
# settings): code-only premium layer on top of S119 — gold
# frame, rising festival embers, gold rule under the subtitle,
# small H2W mark. All decor IGNORE + behind buttons, exactly
# like S119's decor, so menu entry can never regress.
var _frame158: Panel = null
var _embers158: Array = []
var _h2w158: Label = null
var _rule158: ColorRect = null
var _rule158_placed: bool = false


func _ready() -> void:
	continue_button = get_node_or_null("ContinueButton") as Button
	if continue_button != null:
		continue_button.pressed.connect(_on_continue_pressed)
	new_game_button = get_node_or_null("NewGameButton") as Button
	if new_game_button != null:
		new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button = get_node_or_null("SettingsButton") as Button
	if settings_button != null:
		settings_button.pressed.connect(_on_settings_pressed)
	character_button = get_node_or_null("CharacterButton") as Button
	if character_button != null:
		character_button.pressed.connect(_on_character_pressed)
	vehicle_button = get_node_or_null("VehicleButton") as Button
	if vehicle_button != null:
		vehicle_button.pressed.connect(_on_vehicle_pressed)
	no_save_label = get_node_or_null("NoSaveLabel") as Label
	settings_panel = get_node_or_null("SettingsPanel")
	character_panel = get_node_or_null("CharacterPanel")
	vehicle_panel = get_node_or_null("VehiclePanel")
	# Slice 53: loading feedback, created in code (no scene change).
	# The world scene is heavy (hundreds of nodes, first-load shader
	# compile on Mali takes seconds), and change_scene_to_file loads
	# synchronously, so a tap with no immediate feedback reads as a
	# dead button. Showing this label and yielding two frames lets
	# it paint BEFORE the load blocks the main thread.
	loading_label = Label.new()
	loading_label.name = "LoadingLabel53"
	loading_label.text = "တင်နေသည်…"
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.anchor_left = 0.35
	loading_label.anchor_right = 0.65
	loading_label.anchor_top = 0.85
	loading_label.anchor_bottom = 0.92
	loading_label.visible = false
	add_child(loading_label)
	_refresh_continue()
	_title_label = get_node_or_null("TitleLabel") as Label
	_subtitle_label = get_node_or_null("SubtitleLabel") as Label
	_bg_rect = get_node_or_null("Background") as ColorRect
	for b in [continue_button, new_game_button, settings_button, character_button, vehicle_button]:
		if b != null:
			b.button_down.connect(_on_menu_button_down.bind(b))
	_build_scene110()
	_build_special158()


func _build_scene110() -> void:
	if _bg_rect != null:
		_bg_rect.visible = false
	var vs := get_viewport_rect().size
	if vs.x <= 0.0 or vs.y <= 0.0:
		vs = Vector2(1280.0, 720.0)
	var sky := TextureRect.new()
	sky.name = "Sky110"
	sky.anchor_left = 0.0
	sky.anchor_right = 1.0
	sky.anchor_top = 0.0
	sky.anchor_bottom = 1.0
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.60, 0.24, 1.0))
	grad.add_point(0.55, Color(1.0, 0.42, 0.54, 1.0))
	grad.add_point(1.0, Color(0.16, 0.11, 0.31, 1.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	sky.texture = gt
	add_child(sky)
	move_child(sky, 0)
	var sun_style := StyleBoxFlat.new()
	sun_style.bg_color = Color(1.0, 0.82, 0.40, 1.0)
	sun_style.set_corner_radius_all(90)
	_sun110 = Panel.new()
	_sun110.name = "Sun110"
	_sun110.add_theme_stylebox_override("panel", sun_style)
	_sun110.position = Vector2(vs.x * 0.68, vs.y * 0.10)
	_sun110.size = Vector2(180.0, 180.0)
	_sun110.pivot_offset = Vector2(90.0, 90.0)
	add_child(_sun110)
	move_child(_sun110, 1)
	# Slice 119: rotating sun rays (behind the sun disc). 8 spokes,
	# each a thin rect centred on the sun centre and rotated by
	# i*45 degrees; the container rotates slowly in _process.
	_rays110 = Control.new()
	_rays110.name = "SunRays110"
	_rays110.position = Vector2(vs.x * 0.68 - 108.0, vs.y * 0.10 - 108.0)
	_rays110.size = Vector2(396.0, 396.0)
	_rays110.pivot_offset = Vector2(198.0, 198.0)
	add_child(_rays110)
	for ri in range(8):
		var ray := ColorRect.new()
		ray.name = "Ray110_%d" % ri
		ray.color = Color(1.0, 0.82, 0.40, 0.55)
		ray.position = Vector2(198.0 - 7.0, 198.0 - 150.0)
		ray.size = Vector2(14.0, 300.0)
		ray.pivot_offset = Vector2(7.0, 150.0)
		ray.rotation = float(ri) * PI / 4.0
		_rays110.add_child(ray)
	# Slice 119: parallax cloud layers — far slow/small/faint, mid,
	# near fast/large/opaque. Speeds are px/s at 1280 wide: even the
	# far layer moves ~45 px in the first second, so motion reads
	# immediately (S109's 10-24 px/s was effectively static).
	var cloud_defs: Array = [
		[100.0, 30.0, 0.10, 0.06, 45.0, 0.18],
		[120.0, 34.0, 0.55, 0.10, 50.0, 0.18],
		[150.0, 40.0, 0.30, 0.16, 90.0, 0.28],
		[170.0, 44.0, 0.70, 0.05, 95.0, 0.28],
		[210.0, 52.0, 0.15, 0.20, 150.0, 0.42],
		[240.0, 56.0, 0.60, 0.12, 160.0, 0.42],
	]
	for ci in range(cloud_defs.size()):
		var cd: Array = cloud_defs[ci]
		var cstyle := StyleBoxFlat.new()
		cstyle.bg_color = Color(1.0, 1.0, 1.0, float(cd[5]))
		cstyle.set_corner_radius_all(18)
		var cl := Panel.new()
		cl.name = "Cloud110_%d" % ci
		cl.add_theme_stylebox_override("panel", cstyle)
		cl.position = Vector2(vs.x * float(cd[2]), vs.y * float(cd[3]))
		cl.size = Vector2(float(cd[0]), float(cd[1]))
		var bump := Panel.new()
		bump.name = "CloudBump110_%d" % ci
		bump.add_theme_stylebox_override("panel", cstyle)
		bump.position = Vector2(float(cd[0]) * 0.25, -float(cd[1]) * 0.35)
		bump.size = Vector2(float(cd[0]) * 0.45, float(cd[1]) * 0.7)
		cl.add_child(bump)
		add_child(cl)
		_clouds110.append([cl, float(cd[4])])
	var sil := Control.new()
	sil.name = "Silhouette110"
	sil.anchor_left = 0.0
	sil.anchor_right = 1.0
	sil.anchor_top = 0.0
	sil.anchor_bottom = 1.0
	add_child(sil)
	var house_defs: Array = [
		[90.0, 80.0, 0.02], [70.0, 110.0, 0.13], [110.0, 65.0, 0.24],
		[80.0, 95.0, 0.36], [95.0, 120.0, 0.47], [65.0, 70.0, 0.58],
		[105.0, 85.0, 0.68], [75.0, 100.0, 0.79],
	]
	for hi in range(house_defs.size()):
		var hd: Array = house_defs[hi]
		var hr := ColorRect.new()
		hr.name = "House110_%d" % hi
		hr.color = Color(0.10, 0.06, 0.20, 0.85)
		hr.position = Vector2(vs.x * float(hd[2]), vs.y - float(hd[1]))
		hr.size = Vector2(float(hd[0]), float(hd[1]))
		sil.add_child(hr)
	var pag_x := vs.x * 0.88
	var pag_base := ColorRect.new()
	pag_base.name = "Pagoda110_Base"
	pag_base.color = Color(0.10, 0.06, 0.20, 0.85)
	pag_base.position = Vector2(pag_x, vs.y - 70.0)
	pag_base.size = Vector2(70.0, 70.0)
	sil.add_child(pag_base)
	var pag_mid := ColorRect.new()
	pag_mid.name = "Pagoda110_Mid"
	pag_mid.color = Color(0.10, 0.06, 0.20, 0.85)
	pag_mid.position = Vector2(pag_x + 12.5, vs.y - 115.0)
	pag_mid.size = Vector2(45.0, 45.0)
	sil.add_child(pag_mid)
	var pag_spire := ColorRect.new()
	pag_spire.name = "Pagoda110_Spire"
	pag_spire.color = Color(0.10, 0.06, 0.20, 0.85)
	pag_spire.position = Vector2(pag_x + 26.0, vs.y - 170.0)
	pag_spire.size = Vector2(18.0, 55.0)
	sil.add_child(pag_spire)
	# Slice 119: twinkling silhouette window lights — small warm
	# rects on the house fronts + pagoda base, alpha-animated in
	# _process. Children of the silhouette, so they move with it
	# and are covered by the recursive IGNORE below.
	for hi in range(house_defs.size()):
		var hd: Array = house_defs[hi]
		var wl := ColorRect.new()
		wl.name = "WindowLight110_%d" % hi
		wl.color = Color(1.0, 0.85, 0.45, 0.9)
		wl.position = Vector2(vs.x * float(hd[2]) + float(hd[0]) * 0.5 - 3.5, vs.y - float(hd[1]) + 15.0)
		wl.size = Vector2(7.0, 9.0)
		sil.add_child(wl)
		_window_lights110.append([wl, float(hi) * 1.7, 1.5 + float(hi % 4) * 0.5])
	for wi in range(2):
		var wl2 := ColorRect.new()
		wl2.name = "WindowLight110_Pag%d" % wi
		wl2.color = Color(1.0, 0.85, 0.45, 0.9)
		wl2.position = Vector2(pag_x + 12.0 + float(wi) * 36.0, vs.y - 55.0)
		wl2.size = Vector2(7.0, 9.0)
		sil.add_child(wl2)
		_window_lights110.append([wl2, 2.3 + float(wi) * 1.9, 2.2 + float(wi) * 0.6])
	# Slice 119 P0 (belt and suspenders): decor must neither STOP
	# input nor sit above the buttons. IGNORE the whole decor
	# trees, then move them behind buttons/panels in ascending
	# order (sky, rays, sun, clouds, silhouette).
	_ignore_tree(sky)
	_ignore_tree(_rays110)
	_ignore_tree(_sun110)
	for ce in _clouds110:
		_ignore_tree(ce[0])
	_ignore_tree(sil)
	move_child(sky, 0)
	move_child(_rays110, 1)
	move_child(_sun110, 2)
	for ci in range(_clouds110.size()):
		move_child(_clouds110[ci][0], 3 + ci)
	move_child(sil, 3 + _clouds110.size())
	# Slice 119 P1: gradient-look pill buttons with borders.
	# StyleBoxFlat has no gradient, so the premium look comes from
	# a rich violet fill + gold border + soft shadow + pill radius.
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.25, 0.22, 0.55, 0.95)
	btn_normal.set_corner_radius_all(25)
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = Color(1.0, 0.82, 0.40, 1.0)
	btn_normal.shadow_size = 6
	btn_normal.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	btn_normal.shadow_offset = Vector2(0.0, 3.0)
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.35, 0.31, 0.68, 0.95)
	btn_hover.set_corner_radius_all(25)
	btn_hover.border_width_left = 2
	btn_hover.border_width_right = 2
	btn_hover.border_width_top = 2
	btn_hover.border_width_bottom = 2
	btn_hover.border_color = Color(1.0, 0.88, 0.55, 1.0)
	btn_hover.shadow_size = 6
	btn_hover.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	btn_hover.shadow_offset = Vector2(0.0, 3.0)
	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.18, 0.16, 0.42, 0.95)
	btn_pressed.set_corner_radius_all(25)
	btn_pressed.border_width_left = 2
	btn_pressed.border_width_right = 2
	btn_pressed.border_width_top = 2
	btn_pressed.border_width_bottom = 2
	btn_pressed.border_color = Color(1.0, 0.82, 0.40, 1.0)
	var btn_disabled := StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.25, 0.22, 0.55, 0.45)
	btn_disabled.set_corner_radius_all(25)
	btn_disabled.border_width_left = 2
	btn_disabled.border_width_right = 2
	btn_disabled.border_width_top = 2
	btn_disabled.border_width_bottom = 2
	btn_disabled.border_color = Color(1.0, 0.82, 0.40, 0.4)
	for b in [continue_button, new_game_button, settings_button, character_button, vehicle_button]:
		if b != null:
			b.add_theme_stylebox_override("normal", btn_normal)
			b.add_theme_stylebox_override("hover", btn_hover)
			b.add_theme_stylebox_override("pressed", btn_pressed)
			b.add_theme_stylebox_override("disabled", btn_disabled)
	if _title_label != null:
		_title_base_pos = _title_label.position
	if _subtitle_label != null:
		_subtitle_base_pos = _subtitle_label.position


func _build_special158() -> void:
	var vs := get_viewport_rect().size
	if vs.x <= 0.0 or vs.y <= 0.0:
		vs = Vector2(1280.0, 720.0)
	# Gold frame: transparent centre, gold border only.
	var fstyle := StyleBoxFlat.new()
	fstyle.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	fstyle.border_color = Color(1.0, 0.82, 0.40, 0.9)
	fstyle.border_width_left = 4
	fstyle.border_width_right = 4
	fstyle.border_width_top = 4
	fstyle.border_width_bottom = 4
	_frame158 = Panel.new()
	_frame158.name = "Frame158"
	_frame158.add_theme_stylebox_override("panel", fstyle)
	_frame158.anchor_left = 0.0
	_frame158.anchor_top = 0.0
	_frame158.anchor_right = 1.0
	_frame158.anchor_bottom = 1.0
	add_child(_frame158)
	# Rising festival embers: warm gold/orange sparks drifting
	# up over the sunset scene. Positions stored as x fractions
	# so a viewport resize cannot strand them off-screen.
	for i in range(12):
		var e := ColorRect.new()
		e.name = "Ember158_%d" % i
		e.color = Color(1.0, 0.72 + 0.08 * float(i % 3), 0.30, 0.55 + 0.10 * float(i % 4))
		var sz := 3.0 + 2.0 * float(i % 3)
		e.size = Vector2(sz, sz)
		var frac := fmod(float(i) * 0.173 + 0.05, 1.0)
		e.position = Vector2(frac * vs.x, fmod(float(i) * 211.0, vs.y))
		add_child(e)
		_embers158.append([e, 14.0 + 6.0 * float(i % 5), float(i) * 1.3, frac])
	# Gold rule under the subtitle: a CHILD of the subtitle
	# label, so it rides the entrance slide and float exactly.
	# Positioned once in _process when the label size is known.
	if _subtitle_label != null:
		_rule158 = ColorRect.new()
		_rule158.name = "Rule158"
		_rule158.color = Color(1.0, 0.82, 0.40, 0.95)
		_rule158.size = Vector2(160.0, 3.0)
		_rule158.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_subtitle_label.add_child(_rule158)
	# Small H2W mark, bottom centre, clear of every button
	# (buttons end at 0.81, NoSaveLabel at 0.84-0.90).
	_h2w158 = Label.new()
	_h2w158.name = "H2W158"
	_h2w158.text = "H2W"
	_h2w158.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_h2w158.add_theme_font_size_override("font_size", 18)
	_h2w158.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 0.85))
	_h2w158.anchor_left = 0.47
	_h2w158.anchor_top = 0.93
	_h2w158.anchor_right = 0.53
	_h2w158.anchor_bottom = 0.97
	add_child(_h2w158)
	# S119 rule, re-applied: decor IGNORE + behind buttons.
	var decor: Array = []
	if _frame158 != null:
		decor.append(_frame158)
	for em in _embers158:
		decor.append(em[0])
	if _h2w158 != null:
		decor.append(_h2w158)
	for d in decor:
		_ignore_tree(d as Control)
	var min_idx := 999
	for b in [continue_button, new_game_button, settings_button, character_button, vehicle_button]:
		if b != null:
			min_idx = mini(min_idx, b.get_index())
	var idx := min_idx
	for d in decor:
		move_child(d as Control, idx)
		idx += 1


func _ignore_tree(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in c.get_children():
		if ch is Control:
			_ignore_tree(ch as Control)


func _ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var u := t - 1.0
	return 1.0 + c3 * u * u * u + c1 * u * u


func _on_menu_button_down(b: Button) -> void:
	_pulse_button = b
	_pulse = 1.0

func _process(delta: float) -> void:
	_menu_time += delta
	# Layout stabilization gate: cache resting transforms only
	# once the viewport size has been stable for 2 frames
	# (headless starts at 64x64 then jumps to the project size;
	# a phone is stable from frame 1). Caching before any
	# entrance write keeps the cached base equal to the natural
	# anchored position, so later resizes lay out naturally.
	var vps := get_viewport_rect().size
	if vps != _last_vp_size:
		_last_vp_size = vps
		_vp_stable = 0
	else:
		_vp_stable += 1
	if not _layout_ready and _vp_stable >= 2:
		_layout_ready = true
		if _title_label != null and _title_label.size.x > 0.0:
			_title_base_pos = _title_label.position
			_title_label.pivot_offset = _title_label.size * 0.5
		if _subtitle_label != null and _subtitle_label.size.x > 0.0:
			_subtitle_base_pos = _subtitle_label.position
		for b in [continue_button, new_game_button, settings_button, character_button, vehicle_button]:
			if b != null and b.size.x > 0.0:
				_button_base_pos[b] = b.position
				b.pivot_offset = b.size * 0.5
	# Title: entrance (0.7 s ease-out-back from -46 px + 0.85
	# scale), then a stronger gentle float (was +-4% / +-6 px).
	# Float phase starts at the entrance end so there is no pop.
	if _title_label != null:
		var te := clampf(_menu_time / 0.7, 0.0, 1.0)
		var esc := _ease_out_back(te)
		var sc := 0.85 + 0.15 * esc
		var yoff := -46.0 * (1.0 - esc)
		if te >= 1.0:
			sc = 1.0 + 0.05 * sin((_menu_time - 0.7) * 1.6)
			yoff = 10.0 * sin((_menu_time - 0.7) * 1.2)
		_title_label.scale = Vector2(sc, sc)
		_title_label.position = _title_base_pos + Vector2(0.0, yoff)
	# Subtitle: delayed entrance (0.15 s delay, 0.6 s slide+fade).
	if _subtitle_label != null:
		var st := clampf((_menu_time - 0.15) / 0.6, 0.0, 1.0)
		_subtitle_label.position = _subtitle_base_pos + Vector2(0.0, 20.0 * (1.0 - st))
		_subtitle_label.modulate.a = st
	# Sun: stronger pulse (was +-3%) + rotating rays.
	if _sun110 != null:
		var ss := 1.0 + 0.08 * sin(_menu_time * 1.2)
		_sun110.scale = Vector2(ss, ss)
	if _rays110 != null:
		_rays110.rotation += delta * 0.15
	if _clouds110.size() > 0:
		var vw := get_viewport_rect().size.x
		if vw <= 0.0:
			vw = 1280.0
		for ce in _clouds110:
			var cl: Control = ce[0]
			var spd: float = ce[1]
			cl.position.x += spd * delta
			if cl.position.x > vw:
				cl.position.x = -cl.size.x
	# Slice 158 embers: rise + sway, wrap to the bottom.
	var vw158 := get_viewport_rect().size.x
	if vw158 <= 0.0:
		vw158 = 1280.0
	var vh158 := get_viewport_rect().size.y
	if vh158 <= 0.0:
		vh158 = 720.0
	for em in _embers158:
		var er: ColorRect = em[0]
		var esp: float = em[1]
		var eph: float = em[2]
		var efr: float = em[3]
		er.position.y -= esp * delta
		er.position.x = efr * vw158 + 12.0 * sin(_menu_time * 0.9 + eph)
		if er.position.y < -12.0:
			er.position.y = vh158 + 8.0
	# Slice 158 gold rule: place once under the subtitle.
	if _rule158 != null and not _rule158_placed and _subtitle_label != null and _subtitle_label.size.x > 0.0:
		_rule158.position = Vector2((_subtitle_label.size.x - 160.0) * 0.5, _subtitle_label.size.y + 8.0)
		_rule158_placed = true
	# Silhouette windows: twinkle.
	for we in _window_lights110:
		var wl: ColorRect = we[0]
		var ph: float = we[1]
		var sp: float = we[2]
		wl.color = Color(1.0, 0.85, 0.45, 0.55 + 0.45 * sin(_menu_time * sp + ph))
	if _bg_rect != null:
		var t := 0.5 + 0.5 * sin(_menu_time * 0.25)
		_bg_rect.color = Color(0.05, 0.07, 0.14, 1.0).lerp(Color(0.12, 0.08, 0.10, 1.0), t)
	# Button stagger-in: visible buttons only, 0.15 s + i*0.08 s
	# start, 0.45 s ease-out-back scale 0.9 -> 1 (+overshoot) and
	# +30 px slide. Skips pulsing/disabled buttons; once a
	# button's entrance completes its transform is restored
	# exactly and left alone, so later resizes lay out naturally.
	if _layout_ready:
		var bi := 0
		for b in [continue_button, new_game_button, settings_button, character_button, vehicle_button]:
			if b != null and b.visible and not b.disabled and b != _pulse_button:
				if _button_base_pos.has(b):
					var bt := clampf((_menu_time - 0.15 - float(bi) * 0.08) / 0.45, 0.0, 1.0)
					if bt < 1.0:
						var e := _ease_out_back(bt)
						b.scale = Vector2(0.9 + 0.1 * e, 0.9 + 0.1 * e)
						b.position = (_button_base_pos[b] as Vector2) + Vector2(0.0, 30.0 * (1.0 - e))
					elif b.scale != Vector2.ONE:
						b.scale = Vector2.ONE
						b.position = _button_base_pos[b] as Vector2
			bi += 1
	# Press punch: stronger (was 1.08) + white flash. This never
	# fired before because presses were blocked; it fires now.
	if _pulse_button != null and _pulse > 0.0:
		_pulse = maxf(_pulse - delta * 4.0, 0.0)
		var ps := 1.0 + 0.12 * _pulse
		_pulse_button.scale = Vector2(ps, ps)
		_pulse_button.modulate = Color(1.0 + 0.35 * _pulse, 1.0 + 0.35 * _pulse, 1.0 + 0.35 * _pulse, 1.0)
		if _pulse <= 0.0:
			_pulse_button.scale = Vector2.ONE
			_pulse_button.modulate = Color.WHITE
			_pulse_button = null
	for pnl in [settings_panel, character_panel, vehicle_panel]:
		if pnl != null and pnl.visible and pnl.scale.x < 1.0:
			var ns := minf(pnl.scale.x + delta * 3.0, 1.0)
			pnl.scale = Vector2(ns, ns)

func _show_loading() -> void:
	if loading:
		return
	loading = true
	for b in [continue_button, new_game_button, settings_button, character_button, vehicle_button]:
		if b != null:
			b.disabled = true
	if loading_label != null:
		loading_label.visible = true


func _sm():
	return get_node_or_null("/root/SaveManager")


func _refresh_continue() -> void:
	var sm = _sm()
	var has = false
	if sm != null:
		has = bool(sm.call("has_valid_save"))
	if continue_button != null:
		continue_button.visible = has
	if no_save_label != null:
		no_save_label.visible = not has


func _on_continue_pressed() -> void:
	var sm = _sm()
	if sm == null:
		return
	var data = sm.call("load_save")
	if not (data is Dictionary) or data.is_empty():
		_refresh_continue()
		return
	if loading:
		return
	_show_loading()
	await get_tree().process_frame
	await get_tree().process_frame
	sm.set("pending_load", data)
	get_tree().change_scene_to_file("res://main.tscn")


func _on_new_game_pressed() -> void:
	if loading:
		return
	_show_loading()
	await get_tree().process_frame
	await get_tree().process_frame
	var sm = _sm()
	if sm != null:
		sm.set("pending_load", {})
	get_tree().change_scene_to_file("res://main.tscn")


func _on_settings_pressed() -> void:
	if settings_panel == null:
		settings_panel = get_node_or_null("SettingsPanel")
	if settings_panel == null:
		return
	settings_panel.visible = true
	settings_panel.scale = Vector2(0.92, 0.92)
	if settings_panel.has_method("refresh"):
		settings_panel.call("refresh")


func _on_character_pressed() -> void:
	if character_panel == null:
		character_panel = get_node_or_null("CharacterPanel")
	if character_panel == null:
		return
	character_panel.visible = true
	character_panel.scale = Vector2(0.92, 0.92)
	if character_panel.has_method("refresh"):
		character_panel.call("refresh")


func _on_vehicle_pressed() -> void:
	if vehicle_panel == null:
		vehicle_panel = get_node_or_null("VehiclePanel")
	if vehicle_panel == null:
		return
	vehicle_panel.visible = true
	vehicle_panel.scale = Vector2(0.92, 0.92)
	if vehicle_panel.has_method("refresh"):
		vehicle_panel.call("refresh")
