extends CharacterBody3D

# --- Intelligent Myanmar Villager NPC with Home Radius & Unique Variety ---

@export var villager_name: String = "ဦးရွှေရိုး"
@export var dialogue_text: String = "မင်္ဂလာပါ ခင်ဗျာ! ကျွန်တော်တို့ ရွာလေးကို ကြိုဆိုပါတယ်။"
@export var longyi_color: Color = Color(0.55, 0.12, 0.15, 1) # Default Ruby Maroon
@export var wander_radius: float = 12.0
@export var walk_speed: float = 2.0

enum NPCState { IDLE, WANDERING, TALKING }
var state: NPCState = NPCState.IDLE

var spawn_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
# Obstacle Avoidance Circles (center_x, center_z, radius)
const OBSTACLE_CIRCLES = [
	Vector3(0, 0, -25), 6.5,     # Golden Pagoda
	Vector3(12, 0, -15), 4.0,    # Monastery Bell
	Vector3(-16, 0, -18), 5.5,   # Myanmar Tea Shop
	Vector3(-26, 0, -32), 7.5,   # Monastery School
	Vector3(20, 0, 10), 4.5,     # Market Stall
	Vector3(0, 0, -40), 5.0,     # Myanmar Zayat
	Vector3(15, 0, -5), 4.0,     # Village Well
	Vector3(0, 0, 35), 4.5       # Village Gate
]

@onready var visual_mesh: Node3D = $VisualMesh
@onready var dialogue_label: Label3D = $DialogueLabel
@onready var longyi_mesh: MeshInstance3D = $VisualMesh/Longyi

func _ready() -> void:
	add_to_group("villagers")
	spawn_position = global_position
	if dialogue_label:
		dialogue_label.visible = false
		dialogue_label.text = dialogue_text
	
	# Apply unique custom longyi color per villager instance
	if longyi_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = longyi_color
		longyi_mesh.surface_material_override/0 = mat
		
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
				# Ray-circle proximity obstacle diversion
				var next_step = global_position + move_dir * 1.5
				for i in range(0, OBSTACLE_CIRCLES.size(), 2):
					var obs_pos: Vector3 = OBSTACLE_CIRCLES[i]
					var obs_rad: float = OBSTACLE_CIRCLES[i + 1]
					var dist_to_obs = Vector2(next_step.x - obs_pos.x, next_step.z - obs_pos.z).length()
					if dist_to_obs < (obs_rad + 0.8):
						# Deflect perpendicular around obstacle perimeter
						var push_away = (Vector2(global_position.x - obs_pos.x, global_position.z - obs_pos.z)).normalized()
						move_dir.x = push_away.x
						move_dir.z = push_away.y
						break
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

func talk_to(player_pos: Vector3) -> void:
	state = NPCState.TALKING
	state_timer = 4.5
	if dialogue_label:
		dialogue_label.text = dialogue_text
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
		state_timer = randf_range(4.0, 7.0)
		# Wander relative to own home spawn position, not world origin
		var angle = randf() * TAU
		var dist = randf_range(2.0, wander_radius)
				var candidate = spawn_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		var is_inside_building = false
		for i in range(0, OBSTACLE_CIRCLES.size(), 2):
			var obs_pos: Vector3 = OBSTACLE_CIRCLES[i]
			var obs_rad: float = OBSTACLE_CIRCLES[i + 1]
			if Vector2(candidate.x - obs_pos.x, candidate.z - obs_pos.z).length() < (obs_rad + 1.0):
				is_inside_building = true
				break
		if not is_inside_building:
			target_position = candidate
		else:
			target_position = spawn_position
