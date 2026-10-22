extends Panel
## Slice 35 vehicle panel: paint presets for the three physics-polished
## road vehicles (car, motorcycle, tuk-tuk), picked from the main menu.
## Presets are DATA here; the chosen colours persist in SaveManager
## settings (settings.json) and player.gd applies them at world spawn.
## The vehicles are primitive meshes, so this is COLOURS of the
## existing body meshes only — no new meshes, no new models, no
## parts or accessories. If a control is shown, it changes the game:
## every preset button writes settings immediately, and refresh()
## always shows the saved choice for the selected vehicle.
## Applied on world load, not live: changing a paint in the menu
## shows up the next time the world loads.

const VEHICLES: Array = ["Car", "Motorcycle", "TukTuk"]
const VEHICLE_LABELS: Array = ["ကား", "ဆိုင်ကယ်", "သုံးဘီး"]
const VEHICLE_KEYS: Array = ["car_paint_html", "motorcycle_paint_html", "tuktuk_paint_html"]
const PRESETS: Array = [
	[
		{"name": "အနီ (မူလ)", "color": "#D91A26"},
		{"name": "အဖြူ", "color": "#F2F2F2"},
		{"name": "နက်ပြာ", "color": "#1A2A4A"},
		{"name": "ရွှေဝါ", "color": "#D9A419"},
	],
	[
		{"name": "စိမ်းပြာ (မူလ)", "color": "#1A8C99"},
		{"name": "အနီ", "color": "#D91A26"},
		{"name": "အနက်", "color": "#1A1A1A"},
		{"name": "လိမ္မော်", "color": "#E67E22"},
	],
	[
		{"name": "အပြာ (မူလ)", "color": "#1A66CC"},
		{"name": "အဝါ", "color": "#F2C200"},
		{"name": "အစိမ်း", "color": "#1A7A3A"},
		{"name": "ပန်းရောင်", "color": "#D94A7A"},
	],
]

var selected_vehicle: int = 0
var vehicle_buttons: Array = []
var preset_buttons: Array = []
var current_label: Label = null
var back_button: Button = null


func _ready() -> void:
	for i in range(VEHICLES.size()):
		var btn = get_node_or_null("Vehicle%dButton" % (i + 1)) as Button
		if btn != null:
			btn.text = str(VEHICLE_LABELS[i])
			btn.pressed.connect(_on_vehicle_pressed.bind(i))
			vehicle_buttons.append(btn)
	for i in range(4):
		var btn = get_node_or_null("Preset%dButton" % (i + 1)) as Button
		if btn != null:
			btn.pressed.connect(_on_preset_pressed.bind(i))
			preset_buttons.append(btn)
	current_label = get_node_or_null("CurrentLabel") as Label
	back_button = get_node_or_null("BackButton") as Button
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	refresh()


func _sm():
	return get_node_or_null("/root/SaveManager")


func refresh() -> void:
	var sm = _sm()
	for i in range(preset_buttons.size()):
		var btn = preset_buttons[i] as Button
		if btn != null:
			btn.text = str(PRESETS[selected_vehicle][i]["name"])
	if sm == null:
		return
	var key = str(VEHICLE_KEYS[selected_vehicle])
	var saved = str(sm.get(key))
	var current = "စိတ်ကြိုက်"
	for i in range(PRESETS[selected_vehicle].size()):
		if saved == str(PRESETS[selected_vehicle][i]["color"]):
			current = str(PRESETS[selected_vehicle][i]["name"])
			break
	if current_label != null:
		current_label.text = "လက်ရှိဆေး (" + str(VEHICLE_LABELS[selected_vehicle]) + "): " + current


func _on_vehicle_pressed(index: int) -> void:
	selected_vehicle = index
	refresh()


func _on_preset_pressed(index: int) -> void:
	var sm = _sm()
	if sm == null:
		return
	sm.set(str(VEHICLE_KEYS[selected_vehicle]), str(PRESETS[selected_vehicle][index]["color"]))
	sm.call("save_settings")
	refresh()


func _on_back_pressed() -> void:
	visible = false
