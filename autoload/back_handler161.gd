extends Node

## S161: ONE central Android Back handler. This autoload owns Back for
## the whole app — no scene implements its own back path, so two
## handlers can never fight. Registered in project.godot [autoload].
##
## Bug fixed: NOTHING handled Back before (no GO_BACK_REQUEST, no
## KEY_ESCAPE, no quit() anywhere in .gd), so an unhandled Android
## Back press fell through to the engine default and quit the app
## outright instead of reaching the main menu.
##
## Stack, topmost first (each Back peels exactly one layer):
##   confirm dialog open -> dismiss dialog, stay in menu
##   custom-controls editor open -> Cancel-equivalent (discard, queue_free)
##   settings panel visible -> hide it, return to its opener
##     (pause menu if opened from pause, main menu if from menu)
##   pause panel visible -> resume via the existing resume path
##   world map visible -> close_map (restores was_paused)
##   character / vehicle panel visible -> hide it
##   help label visible -> hide it
##   More cluster open -> close it
##   playing, nothing open -> main menu via the EXISTING save path
##     (player _on_quit_to_menu_pressed: save + unpause + change scene)
##   main menu, nothing open -> exit CONFIRM dialog (Burmese)
## Back NEVER quits the app except through the dialog's Yes.
##
## Paths: Android Back arrives as NOTIFICATION_WM_GO_BACK_REQUEST;
## desktop Esc arrives as ui_cancel (fallback only — on Android the
## back button produces the notification, never ui_cancel, so the two
## paths cannot double-fire). Both call handle_back() once and mark
## the viewport input handled so the engine default quit is suppressed.
## process_mode is ALWAYS so Back works while the tree is paused
## (pause menu, world map, and the S160 editor all pause the tree).

var quit_requested: bool = false
var last_action: String = ""
var _dialog: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()
		var vp: Viewport = get_viewport()
		if vp != null:
			vp.set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var k: InputEventKey = event as InputEventKey
	if k != null and k.echo:
		return
	handle_back()
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func dialog_open() -> bool:
	return _dialog != null and is_instance_valid(_dialog)


func handle_back() -> void:
	# 1. Confirm dialog open -> dismiss, stay in menu.
	if dialog_open():
		_dismiss_dialog()
		last_action = "dialog_dismiss"
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		last_action = "none"
		return
	var root: Window = tree.root
	# 2. Custom-controls editor (root child) -> Cancel-equivalent.
	var ed: Node = null
	if root != null:
		ed = root.get_node_or_null("CustomControls160")
	if ed != null and is_instance_valid(ed):
		if ed.has_method("_on_cancel_pressed"):
			ed.call("_on_cancel_pressed")
		else:
			ed.queue_free()
		last_action = "editor_cancel"
		return
	var scene: Node = tree.current_scene
	if scene == null:
		last_action = "none"
		return
	# 3. Settings panel visible -> hide only; the opener (pause menu
	# or main menu) stays exactly as it was underneath.
	var settings: Node = _find_visible(scene, "SettingsPanel")
	if settings != null:
		_hide_panel(settings)
		last_action = "settings"
		return
	# 4. Pause panel visible -> resume via the existing path
	# (it also re-applies HUD scale on resume).
	var player: Node = _find_player(scene)
	var pause_panel: Node = _find_visible(scene, "PausePanel21")
	if pause_panel != null and player != null:
		if player.has_method("_on_resume_pressed"):
			player.call("_on_resume_pressed")
		else:
			tree.paused = false
			(pause_panel as CanvasItem).visible = false
		last_action = "resume"
		return
	# 5. World map visible -> close (restores was_paused).
	var wm: Node = _find_visible(scene, "WorldMapPanel")
	if wm != null:
		if wm.has_method("close_map"):
			wm.call("close_map")
		else:
			(wm as CanvasItem).visible = false
		last_action = "worldmap"
		return
	# 6. Character / vehicle panels visible -> hide.
	for nm in ["CharacterPanel", "VehiclePanel"]:
		var p: Node = _find_visible(scene, nm)
		if p != null:
			_hide_panel(p)
			last_action = "panel"
			return
	# 7. Help label visible -> hide. 8. More cluster open -> close.
	if player != null:
		var help: Variant = player.get("help_label")
		var help_ctl: Control = help as Control
		if help_ctl != null and help_ctl.is_visible_in_tree():
			help_ctl.visible = false
			last_action = "help"
			return
		if bool(player.get("hud_more_open")) and player.has_method("_on_more_toggle"):
			player.call("_on_more_toggle")
			last_action = "more"
			return
	# 9. Playing, nothing open -> main menu via the existing save path.
	if player != null and player.has_method("_on_quit_to_menu_pressed"):
		player.call("_on_quit_to_menu_pressed")
		last_action = "to_menu"
		return
	# 10. Main menu, nothing open -> exit confirm dialog.
	_show_dialog()
	last_action = "dialog"


func _hide_panel(p: Node) -> void:
	if p.has_method("_on_back_pressed"):
		p.call("_on_back_pressed")
	else:
		(p as CanvasItem).visible = false


func _find_player(scene: Node) -> Node:
	var direct: Node = scene.get_node_or_null("Player")
	if direct != null and direct.has_method("_on_quit_to_menu_pressed"):
		return direct
	return _find_by_method(scene, "_on_quit_to_menu_pressed")


func _find_by_method(n: Node, method: String) -> Node:
	if n.has_method(method):
		return n
	for c in n.get_children():
		var found: Node = _find_by_method(c, method)
		if found != null:
			return found
	return null


func _find_visible(scene: Node, node_name: String) -> Node:
	return _find_visible_rec(scene, node_name)


func _find_visible_rec(n: Node, node_name: String) -> Node:
	if n.name == node_name:
		var ci: CanvasItem = n as CanvasItem
		if ci != null and ci.is_visible_in_tree():
			return n
	for c in n.get_children():
		var found: Node = _find_visible_rec(c, node_name)
		if found != null:
			return found
	return null


func _show_dialog() -> void:
	if dialog_open():
		return
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "ExitConfirm161"
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim161"
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.anchor_left = 0.0
	dim.anchor_top = 0.0
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	layer.add_child(dim)
	var panel: Panel = Panel.new()
	panel.name = "Panel161"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260.0
	panel.offset_top = -90.0
	panel.offset_right = 260.0
	panel.offset_bottom = 90.0
	var pstyle: StyleBoxFlat = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.10, 0.13, 0.24, 0.75)
	pstyle.set_corner_radius_all(18)
	pstyle.border_width_left = 2
	pstyle.border_width_right = 2
	pstyle.border_width_top = 2
	pstyle.border_width_bottom = 2
	pstyle.border_color = Color(1.0, 0.96, 0.88, 0.55)
	pstyle.shadow_size = 8
	pstyle.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	pstyle.shadow_offset = Vector2(0.0, 4.0)
	panel.add_theme_stylebox_override("panel", pstyle)
	layer.add_child(panel)
	var label: Label = Label.new()
	label.name = "Label161"
	label.text = "ဂိမ်းက ထွက်မလား?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 0.0
	label.offset_left = 20.0
	label.offset_top = 20.0
	label.offset_right = -20.0
	label.offset_bottom = 80.0
	label.add_theme_font_size_override("font_size", 26)
	panel.add_child(label)
	var row_n: StyleBoxFlat = StyleBoxFlat.new()
	row_n.bg_color = Color(0.13, 0.16, 0.28, 0.55)
	row_n.set_corner_radius_all(12)
	row_n.border_width_left = 2
	row_n.border_width_right = 2
	row_n.border_width_top = 2
	row_n.border_width_bottom = 2
	row_n.border_color = Color(1.0, 0.96, 0.88, 0.55)
	row_n.shadow_size = 4
	row_n.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	row_n.shadow_offset = Vector2(0.0, 2.0)
	var row_p: StyleBoxFlat = StyleBoxFlat.new()
	row_p.bg_color = Color(0.08, 0.10, 0.20, 0.70)
	row_p.set_corner_radius_all(12)
	row_p.border_width_left = 2
	row_p.border_width_right = 2
	row_p.border_width_top = 2
	row_p.border_width_bottom = 2
	row_p.border_color = Color(1.0, 0.96, 0.88, 0.70)
	var yes: Button = Button.new()
	yes.name = "Yes161"
	yes.text = "ထွက်မယ်"
	yes.anchor_left = 0.0
	yes.anchor_top = 0.0
	yes.anchor_right = 0.0
	yes.anchor_bottom = 0.0
	yes.offset_left = 30.0
	yes.offset_top = 110.0
	yes.offset_right = 240.0
	yes.offset_bottom = 160.0
	yes.add_theme_stylebox_override("normal", row_n)
	yes.add_theme_stylebox_override("pressed", row_p)
	yes.add_theme_font_size_override("font_size", 22)
	yes.pressed.connect(_on_dialog_yes)
	panel.add_child(yes)
	var no: Button = Button.new()
	no.name = "No161"
	no.text = "မထွက်ဘူး"
	no.anchor_left = 0.0
	no.anchor_top = 0.0
	no.anchor_right = 0.0
	no.anchor_bottom = 0.0
	no.offset_left = 280.0
	no.offset_top = 110.0
	no.offset_right = 490.0
	no.offset_bottom = 160.0
	no.add_theme_stylebox_override("normal", row_n)
	no.add_theme_stylebox_override("pressed", row_p)
	no.add_theme_font_size_override("font_size", 22)
	no.pressed.connect(_on_dialog_no)
	panel.add_child(no)
	tree.root.add_child(layer)
	_dialog = layer


func _dismiss_dialog() -> void:
	if _dialog != null and is_instance_valid(_dialog):
		(_dialog as Node).queue_free()
	_dialog = null


func _on_dialog_yes() -> void:
	quit_requested = true
	last_action = "quit"
	_dismiss_dialog()
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.quit()


func _on_dialog_no() -> void:
	_dismiss_dialog()
	last_action = "dialog_no"
