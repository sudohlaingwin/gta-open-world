extends CharacterBody3D

# --- Intelligent Myanmar Villager NPC (ရွာသူရွာသားများ စကားပြော / လမ်းလျှောက် AI) ---

@export var walk_speed: float = 2.2
@export var wander_radius: float = 25.0
@export var dialogue_text: String = "မင်္ဂလာပါ ခင်ဗျာ! ကျွန်တော်တို့ ရွာလေးကို ကြိုဆိုပါတယ်။"

enum NPCState { IDLE, WANDERING, TALKING }
var state: NPCState = NPCState.IDLE

var target_position: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual_mesh: Node3D = $VisualMesh
@onready var interaction_area: Area3D = $InteractionArea
@onready var dialogue_label: Label3D = $DialogueLabel

func _ready() -> void:
	if dialogue_label:
		dialogue_label.visible = false
		dialogue_label.text = dialogue_text
	_pick_new_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	state_timer -= delta

	match state:
		NPCState.IDLE:
			velocity.x = move_toward(velocity.x, 0, walk_speed)
			velocity.z = move_toward(velocity.z, 0, walk_speed)
			if state_timer <= 0:
				_pick_new_state()

		NPCState.WANDERING:
			var dir = (target_position - global_position)
			dir.y = 0.0
			if dir.length() < 1.0 or state_timer <= 0:
				_pick_new_state()
			else:
				var move_dir = dir.normalized()
				velocity.x = move_dir.x * walk_speed
				velocity.z = move_dir.z * walk_speed
				var target_angle = atan2(move_dir.x, move_dir.z)
				visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, 6.0 * delta)

		NPCState.TALKING:
			velocity.x = move_toward(velocity.x, 0, walk_speed)
			velocity.z = move_toward(velocity.z, 0, walk_speed)
			if state_timer <= 0:
				if dialogue_label:
					dialogue_label.visible = false
				_pick_new_state()

	move_and_slide()

func talk_to_player(player_pos: Vector3) -> void:
	state = NPCState.TALKING
	state_timer = 4.5
	if dialogue_label:
		dialogue_label.visible = true
	var dir = (player_pos - global_position).normalized()
	dir.y = 0.0
	visual_mesh.rotation.y = atan2(dir.x, dir.z)

func _pick_new_state() -> void:
	if randf() < 0.4:
		state = NPCState.IDLE
		state_timer = randf_range(2.0, 5.0)
	else:
		state = NPCState.WANDERING
		state_timer = randf_range(4.0, 8.0)
		var offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		target_position = Vector3(offset.x, global_position.y, offset.y)
