extends CharacterBody3D

# --- Intelligent Myanmar Villager NPC with Home Radius & Unique Variety ---

@export var villager_name: String = "ဦးရွှေရိုး"
@export var dialogue_text: String = "မင်္ဂလာပါ ခင်ဗျာ! ကျွန်တော်တို့ ရွာလေးကို ကြိုဆိုပါတယ်။"
@export var longyi_color: Color = Color(0.55, 0.12, 0.15, 1)
@export var wander_radius: float = 12.0
@export var walk_speed: float = 2.0
@export var day_anchor: Vector3 = Vector3.ZERO
var is_day_shift_active: bool = false

enum NPCState { IDLE, WANDERING, TALKING }
var state: NPCState = NPCState.IDLE

var spawn_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Authentic Myanmar 3D GLB Character Models (Adopted from MUSE audit)
const GLB_MODELS: Dictionary = {
	"child": "res://models/1_child_cowherd_character.glb",
	"youth": "res://models/2_youth_weaver_character.glb",
	"fighter": "res://models/3_adult_fighter_character.glb",
	"elder": "res://models/4_elder_villager_character.glb"
}
var character_model: Node3D = null
var walk_anim_time: float = 0.0

# Obstacle Avoidance Circles: [Vector3(pos), float(radius), ...]
const OBSTACLE_POSITIONS = [
	Vector3(0, 0, -25),
	Vector3(12, 0, -15),
	Vector3(-16, 0, -18),
	Vector3(-26, 0, -32),
	Vector3(20, 0, 10),
	Vector3(0, 0, -40),
	Vector3(15, 0, -5),
	Vector3(0, 0, 35)
]
const OBSTACLE_RADII = [6.5, 4.0, 5.5, 7.5, 4.5, 5.0, 4.0, 4.5]

@onready var visual_mesh: Node3D = $VisualMesh
@onready var dialogue_label: Label3D = $DialogueLabel
@onready var longyi_mesh: MeshInstance3D = $VisualMesh/Longyi

func _ready() -> void:
	add_to_group("villagers")
	spawn_position = global_position
	if dialogue_label:
		dialogue_label.visible = false
		dialogue_label.text = dialogue_text
	
	if longyi_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = longyi_color
		longyi_mesh.set_surface_override_material(0, mat)

	_setup_character_model()
	_pick_new_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	state_timer -= delta

	match state:
		NPCState.IDLE:
			velocity.x = move_toward(velocity.x, 0, walk_speed)
			velocity.z = move_toward(velocity.z, 0, walk_speed)
			if character_model:
				character_model.position.y = move_toward(character_model.position.y, 0.0, delta * 2.0)
				character_model.rotation.x = move_toward(character_model.rotation.x, 0.0, delta * 2.0)
			if state_timer <= 0:
				_pick_new_state()

		NPCState.WANDERING:
			var dir = (target_position - global_position)
			dir.y = 0.0
			if dir.length() < 1.0 or state_timer <= 0:
				_pick_new_state()
			else:
				var move_dir = dir.normalized()
				var next_step = global_position + (move_dir * 1.5)
				for i in range(OBSTACLE_POSITIONS.size()):
					var obs_pos: Vector3 = OBSTACLE_POSITIONS[i]
					var obs_rad: float = OBSTACLE_RADII[i]
					var dist_to_obs = Vector2(next_step.x - obs_pos.x, next_step.z - obs_pos.z).length()
					if dist_to_obs < (obs_rad + 0.8):
						var push = (Vector2(global_position.x - obs_pos.x, global_position.z - obs_pos.z)).normalized()
						move_dir = Vector3(push.x, 0, push.y)
						break

				velocity.x = move_dir.x * walk_speed
				velocity.z = move_dir.z * walk_speed
				var target_angle = atan2(move_dir.x, move_dir.z)
				if visual_mesh and visual_mesh.visible:
					visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, 6.0 * delta)
				if character_model:
					walk_anim_time += delta * 8.5
					character_model.position.y = abs(sin(walk_anim_time)) * 0.035
					character_model.rotation.x = 0.04
					character_model.rotation.y = lerp_angle(character_model.rotation.y, target_angle, 6.0 * delta)

		NPCState.TALKING:
			velocity.x = move_toward(velocity.x, 0, walk_speed)
			velocity.z = move_toward(velocity.z, 0, walk_speed)
			if state_timer <= 0:
				if dialogue_label:
					dialogue_label.visible = false
				_pick_new_state()

	move_and_slide()

func talk_to(player_pos: Vector3) -> void:
	state = NPCState.TALKING
	state_timer = 4.5
	if dialogue_label:
		dialogue_label.text = dialogue_text
		dialogue_label.visible = true
	var dir = (player_pos - global_position).normalized()
	dir.y = 0.0
	var face_rot = atan2(dir.x, dir.z)
	if visual_mesh and visual_mesh.visible:
		visual_mesh.rotation.y = face_rot
	if character_model:
		character_model.rotation.y = face_rot
		character_model.position.y = 0.0
		character_model.rotation.x = 0.0

func _pick_new_state() -> void:
	if randf() < 0.4:
		state = NPCState.IDLE
		state_timer = randf_range(2.0, 5.0)
	else:
		state = NPCState.WANDERING
		state_timer = randf_range(4.0, 7.0)
		var angle = randf() * TAU
		var dist = randf_range(2.0, wander_radius)
		var base_anchor = spawn_position
		if day_anchor != Vector3.ZERO:
			var day_night = get_parent().get_node_or_null("DayNightCycle")
			var daylight = 1.0
			if day_night and day_night.has_method("get_daylight"):
				daylight = day_night.get_daylight()
			if daylight >= 0.15:
				base_anchor = day_anchor
		var candidate = base_anchor + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		var is_inside = false
		for i in range(OBSTACLE_POSITIONS.size()):
			var obs_pos: Vector3 = OBSTACLE_POSITIONS[i]
			var obs_rad: float = OBSTACLE_RADII[i]
			if Vector2(candidate.x - obs_pos.x, candidate.z - obs_pos.z).length() < (obs_rad + 1.0):
				is_inside = true
				break
		if not is_inside:
			target_position = candidate
		else:
			target_position = spawn_position

func _setup_character_model() -> void:
	var model_key = "elder"
	var n = villager_name.to_lower()
	if "ဖိုးခွား" in n or "ကလေး" in n or "နွားကျောင်း" in n or "child" in n:
		model_key = "child"
	elif "မအေးကြည်" in n or "မေ" in n or "ရက်ကန်း" in n or "ပျို" in n:
		model_key = "youth"
	elif "ကိုမင်းဒင်" in n or "ကိုဖိုးတုတ်" in n or "မောင်" in n or "ကာလသား" in n:
		model_key = "fighter"
	else:
		var hash_val = abs(villager_name.hash()) % 4
		match hash_val:
			0: model_key = "child"
			1: model_key = "youth"
			2: model_key = "fighter"
			3: model_key = "elder"

	var path = GLB_MODELS.get(model_key, "")
	if ResourceLoader.exists(path):
		var scn = load(path) as PackedScene
		if scn:
			character_model = scn.instantiate() as Node3D
			if character_model:
				character_model.name = "CharacterModel3D"
				add_child(character_model)
				character_model.position = Vector3(0, 0, 0)
				if visual_mesh:
					visual_mesh.visible = false
				if dialogue_label:
					dialogue_label.position.y = 2.15
