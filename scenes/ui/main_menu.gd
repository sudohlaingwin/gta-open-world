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
	_bg_rect = get_node_or_null("Background") as ColorRect
	for b in [continue_button, new_game_button, settings_button, character_button, vehicle_button]:
		if b != null:
			b.button_down.connect(_on_menu_button_down.bind(b))
	_build_scene110()


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
	add_child(_sun110)
	move_child(_sun110, 1)
	var cloud_defs: Array = [
		[180.0, 44.0, 0.05, 0.08, 14.0],
		[140.0, 36.0, 0.45, 0.16, 20.0],
		[200.0, 48.0, 0.75, 0.05, 10.0],
		[120.0, 32.0, 0.25, 0.22, 24.0],
		[160.0, 40.0, 0.60, 0.13, 17.0],
	]
	var cstyle := StyleBoxFlat.new()
	cstyle.bg_color = Color(1.0, 1.0, 1.0, 0.30)
	cstyle.set_corner_radius_all(18)
	for ci in range(cloud_defs.size()):
		var cd: Array = cloud_defs[ci]
		var cl := Panel.new()
		cl.name = "Cloud110_%d" % ci
		cl.add_theme_stylebox_override("panel", cstyle)
		cl.position = Vector2(vs.x * float(cd[2]), vs.y * float(cd[3]))
		cl.size = Vector2(float(cd[0]), float(cd[1]))
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
	if _title_label != null:
		_title_base_pos = _title_label.position


func _on_menu_button_down(b: Button) -> void:
	_pulse_button = b
	_pulse = 1.0

func _process(delta: float) -> void:
	_menu_time += delta
	if _title_label != null:
		var sc := 1.0 + 0.04 * sin(_menu_time * 2.0)
		_title_label.scale = Vector2(sc, sc)
		_title_label.position = _title_base_pos + Vector2(0.0, 6.0 * sin(_menu_time * 1.2))
	if _sun110 != null:
		var ss := 1.0 + 0.03 * sin(_menu_time * 1.0)
		_sun110.scale = Vector2(ss, ss)
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
	if _bg_rect != null:
		var t := 0.5 + 0.5 * sin(_menu_time * 0.25)
		_bg_rect.color = Color(0.05, 0.07, 0.14, 1.0).lerp(Color(0.12, 0.08, 0.10, 1.0), t)
	if _pulse_button != null and _pulse > 0.0:
		_pulse = maxf(_pulse - delta * 4.0, 0.0)
		var ps := 1.0 + 0.08 * _pulse
		_pulse_button.scale = Vector2(ps, ps)
		if _pulse <= 0.0:
			_pulse_button.scale = Vector2.ONE
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
