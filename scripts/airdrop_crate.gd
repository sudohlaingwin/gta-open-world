extends Area3D

# --- PUBG-Style Myanmar Rural Air Drop Crate ---
# Drops onto scenic hill viewpoints and valley plains with a towering crimson smoke flare
# Visible from kilometers away across the 8000m basin, rewarding driving exploration.

@export var crate_id: String = "airdrop_01"
@export var reward_health: float = 100.0
@export var reward_coins: int = 500

@onready var smoke_column: Node3D = get_node_or_null("SmokeColumn")
@onready var prompt_label: Label3D = get_node_or_null("PromptLabel")
@onready var flare_light: OmniLight3D = get_node_or_null("FlareLight")

var is_looted: bool = false
var anim_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	anim_time += delta
	# Billowing crimson smoke animation (swirling and ascending)
	if smoke_column and not is_looted:
		smoke_column.rotation.y += delta * 0.45
		var pulse = 0.85 + 0.15 * sin(anim_time * 3.5)
		if flare_light:
			flare_light.light_energy = 2.4 * pulse

func _on_body_entered(body: Node3D) -> void:
	if is_looted:
		return
	if body.is_in_group("player"):
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("_show_prompt"):
			hud._show_prompt("📦 ထောက်ပံ့ရေးသေတ္တာဖွင့်ရန် (Tap Interact to Loot Air Drop)")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("_hide_prompt"):
			hud._hide_prompt()

func loot_crate(player: CharacterBody3D) -> void:
	if is_looted:
		return
	is_looted = true

	# Reward health and notify HUD
	if player and player.get("health") != null:
		player.health = min(player.max_health, player.health + reward_health)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("_show_prompt"):
		hud._show_prompt("🎉 ရယူပြီးပါပြီ: ဆေးသေတ္တာနှင့် ကျပ်ငွေ ၅၀၀ (Air Drop Looted!)")

	# Extinguish smoke column
	if smoke_column:
		var tween = create_tween()
		tween.tween_property(smoke_column, "scale", Vector3.ZERO, 1.2)
		tween.tween_callback(func(): smoke_column.visible = false)
	if flare_light:
		flare_light.visible = false
	if prompt_label:
		prompt_label.text = "📦 ဖွင့်ဖောက်ပြီး (EMPTY CRATE)"
		prompt_label.modulate = Color(0.6, 0.6, 0.6, 0.8)
