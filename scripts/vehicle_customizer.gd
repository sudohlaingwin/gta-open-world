extends Control

# --- Vehicle Paint Customization System (Genuinely Wired & Persisted) ---

const VEHICLES = ["Car", "Motorcycle", "TukTuk"]
const LABELS = ["ကား", "ဆိုင်ကယ်", "သုံးဘီး"]
const KEYS = ["car_paint_html", "motorcycle_paint_html", "tuktuk_paint_html"]

const PRESETS = [
	[
		{"name": "တော်ဝင်အပြာ (မူလ)", "color": "#1F73C7"},
		{"name": "မိုးပြာရောင်", "color": "#7FA8DB"},
		{"name": "ပတ္တမြားနီ", "color": "#D92634"},
		{"name": "ရွှေဝါရောင်", "color": "#D9A419"}
	],
	[
		{"name": "ကင်ဘိုနီ (မူလ)", "color": "#D9261A"},
		{"name": "စိမ်းပြာရောင်", "color": "#1A8C99"},
		{"name": "နက်မှောင်ရောင်", "color": "#1A1A1A"},
		{"name": "ရွှေဝါရောင်", "color": "#F2C200"}
	],
	[
		{"name": "ရွှေဝါတက်ဆီ (မူလ)", "color": "#F2B81A"},
		{"name": "မြစိမ်းရောင်", "color": "#1F8C3D"},
		{"name": "မိုးပြာရောင်", "color": "#1A66CC"},
		{"name": "ပန်းရောင်", "color": "#D94A7A"}
	]
]

var selected_type: int = 0

@onready var close_btn: Button = $Panel/CloseBtn
@onready var car_tab: Button = $Panel/TabContainer/CarTab
@onready var bike_tab: Button = $Panel/TabContainer/BikeTab
@onready var tuk_tab: Button = $Panel/TabContainer/TukTab
@onready var current_label: Label = $Panel/CurrentLabel
@onready var preset_btns = [
	$Panel/PresetsBox/Preset1,
	$Panel/PresetsBox/Preset2,
	$Panel/PresetsBox/Preset3,
	$Panel/PresetsBox/Preset4
]

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): visible = false)
	if car_tab:
		car_tab.pressed.connect(func(): _select_tab(0))
	if bike_tab:
		bike_tab.pressed.connect(func(): _select_tab(1))
	if tuk_tab:
		tuk_tab.pressed.connect(func(): _select_tab(2))

	for i in range(preset_btns.size()):
		var b = preset_btns[i]
		if b:
			b.pressed.connect(_on_preset_selected.bind(i))

	refresh()

func _sm():
	return get_node_or_null("/root/SaveManager")

func _select_tab(idx: int) -> void:
	selected_type = idx
	refresh()

func refresh() -> void:
	var sm = _sm()
	var current_color_hex = ""
	if sm:
		current_color_hex = str(sm.get(KEYS[selected_type]))

	var current_name = "ရွေးချယ်ထားခြင်းမရှိ"
	var vehicle_presets = PRESETS[selected_type]
	for i in range(preset_btns.size()):
		var p = vehicle_presets[i]
		preset_btns[i].text = p["name"]
		if p["color"] == current_color_hex:
			current_name = p["name"]

	if current_label:
		current_label.text = "လက်ရှိဆေး (%s): %s" % [LABELS[selected_type], current_name]

func _on_preset_selected(idx: int) -> void:
	var sm = _sm()
	var chosen = PRESETS[selected_type][idx]
	if sm:
		sm.set(KEYS[selected_type], chosen["color"])
		sm.save_settings()

	# If currently inside world, apply immediately to active vehicles
	var world = get_tree().current_scene
	if world and world.has_method("apply_vehicle_paints"):
		world.apply_vehicle_paints()

	refresh()
