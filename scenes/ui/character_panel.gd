extends Panel
## Slice 30 character panel: player-only outfit presets in Myanmar
## traditional dress colours, plus a straw-hat on/off toggle.
## Presets are DATA here; the chosen colours persist in
## SaveManager settings (settings.json) and player.gd applies them
## at world spawn. The player model is primitive meshes, so this is
## COLOURS of the existing Torso/Longyi/Hat meshes only — no new
## meshes, no new model, villagers untouched. Shared by the main
## menu only (the pause menu keeps Settings). If a control is
## shown, it changes the game: every preset button writes settings
## immediately, and refresh() always shows the saved choice.

const PRESETS: Array = [
	{"name": "အဖြူ-စိမ်း (ရိုးရာ)", "shirt": "#F5F0E6", "longyi": "#145938"},
	{"name": "မိုးပြာ", "shirt": "#A6CCF2", "longyi": "#1A3373"},
	{"name": "ပန်း", "shirt": "#F2BFCC", "longyi": "#731A26"},
	{"name": "ရွှေဝါ", "shirt": "#F2D98C", "longyi": "#59381A"},
]

var preset_buttons: Array = []
var hat_check: CheckButton = null
var current_label: Label = null
var back_button: Button = null


func _ready() -> void:
	for i in range(PRESETS.size()):
		var btn = get_node_or_null("Preset%dButton" % (i + 1)) as Button
		if btn != null:
			btn.text = str(PRESETS[i]["name"])
			btn.pressed.connect(_on_preset_pressed.bind(i))
			preset_buttons.append(btn)
	hat_check = get_node_or_null("HatCheck") as CheckButton
	if hat_check != null:
		hat_check.toggled.connect(_on_hat_toggled)
	current_label = get_node_or_null("CurrentLabel") as Label
	back_button = get_node_or_null("BackButton") as Button
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	refresh()
	_glass159()


# Slice 159 Liquid Glass: visual treatment only — glass panel
# + glass preset/back buttons. Preset data, persistence, and
# refresh() are untouched.
func _glass159() -> void:
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.10, 0.13, 0.24, 0.60)
	pstyle.set_corner_radius_all(18)
	pstyle.border_width_left = 2
	pstyle.border_width_right = 2
	pstyle.border_width_top = 2
	pstyle.border_width_bottom = 2
	pstyle.border_color = Color(1.0, 0.96, 0.88, 0.55)
	pstyle.shadow_size = 8
	pstyle.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	pstyle.shadow_offset = Vector2(0.0, 4.0)
	add_theme_stylebox_override("panel", pstyle)
	var row_n := StyleBoxFlat.new()
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
	var row_p := StyleBoxFlat.new()
	row_p.bg_color = Color(0.08, 0.10, 0.20, 0.70)
	row_p.set_corner_radius_all(12)
	row_p.border_width_left = 2
	row_p.border_width_right = 2
	row_p.border_width_top = 2
	row_p.border_width_bottom = 2
	row_p.border_color = Color(1.0, 0.96, 0.88, 0.70)
	var btns: Array = []
	for b in preset_buttons:
		btns.append(b)
	if back_button != null:
		btns.append(back_button)
	for b in btns:
		if b is Button:
			(b as Button).add_theme_stylebox_override("normal", row_n)
			(b as Button).add_theme_stylebox_override("pressed", row_p)


func _sm():
	return get_node_or_null("/root/SaveManager")


func refresh() -> void:
	var sm = _sm()
	if sm == null:
		return
	var shirt = str(sm.get("shirt_color_html"))
	var longyi = str(sm.get("longyi_color_html"))
	var current = "စိတ်ကြိုက်"
	for i in range(PRESETS.size()):
		if shirt == str(PRESETS[i]["shirt"]) and longyi == str(PRESETS[i]["longyi"]):
			current = str(PRESETS[i]["name"])
			break
	if current_label != null:
		current_label.text = "လက်ရှိဝတ်စုံ: " + current
	if hat_check != null:
		hat_check.button_pressed = bool(sm.get("hat_visible"))


func _on_preset_pressed(index: int) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("shirt_color_html", str(PRESETS[index]["shirt"]))
	sm.set("longyi_color_html", str(PRESETS[index]["longyi"]))
	sm.call("save_settings")
	refresh()


func _on_hat_toggled(pressed: bool) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set("hat_visible", pressed)
	sm.call("save_settings")


func _on_back_pressed() -> void:
	visible = false
