extends Control

# --- Myanmar Traditional Character Customization Panel ---

signal outfit_selected(preset_name, shirt_color, longyi_color)

@onready var close_btn: Button = $Panel/CloseBtn
@onready var preset1_btn: Button = $Panel/VBox/Preset1
@onready var preset2_btn: Button = $Panel/VBox/Preset2
@onready var preset3_btn: Button = $Panel/VBox/Preset3
@onready var preset4_btn: Button = $Panel/VBox/Preset4

const OUTFITS = {
	"ရိုးရာဖြူစိမ်း": {"shirt": Color(0.96, 0.94, 0.90, 1), "longyi": Color(0.08, 0.35, 0.22, 1)},
	"မိုးပြာရောင်": {"shirt": Color(0.65, 0.80, 0.95, 1), "longyi": Color(0.10, 0.20, 0.45, 1)},
	"ပန်းရောင်": {"shirt": Color(0.95, 0.75, 0.80, 1), "longyi": Color(0.45, 0.10, 0.15, 1)},
	"ရွှေဝါရောင်": {"shirt": Color(0.95, 0.85, 0.55, 1), "longyi": Color(0.35, 0.22, 0.10, 1)}
}

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): visible = false)
	if preset1_btn:
		preset1_btn.pressed.connect(func(): _apply_outfit("ရိုးရာဖြူစိမ်း"))
	if preset2_btn:
		preset2_btn.pressed.connect(func(): _apply_outfit("မိုးပြာရောင်"))
	if preset3_btn:
		preset3_btn.pressed.connect(func(): _apply_outfit("ပန်းရောင်"))
	if preset4_btn:
		preset4_btn.pressed.connect(func(): _apply_outfit("ရွှေဝါရောင်"))

func _apply_outfit(p_name: String) -> void:
	if OUTFITS.has(p_name):
		var data = OUTFITS[p_name]
		var save_mgr = get_node_or_null("/root/SaveManager")
		if save_mgr and save_mgr.get("save_data") != null:
			save_mgr.save_data["shirt_color"] = data["shirt"]
			save_mgr.save_data["longyi_color"] = data["longyi"]
		
		# If in-world, update player directly
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("set_outfit_colors"):
			player.set_outfit_colors(data["shirt"], data["longyi"])
		
		visible = false