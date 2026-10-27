extends CharacterBody3D

# --- Ambient Pedestrian AI System (ရွာလမ်းလျှောက်သူများ AI) ---

@export var walk_speed: float = 1.6
@export var route_radius: float = 18.0
var target_pos: Vector3 = Vector3.ZERO
var wait_timer: float = 0.0

const GLB_MODELS: Array[String] = [
	"res://models/1_child_cowherd_character.glb",
	"res://models/2_youth_weaver_character.glb",
	"res://models/3_adult_fighter_character.glb",
	"res://models/4_elder_villager_character.glb"
]
var character_model: Node3D = null
var walk_phase: float = 0.0

@onready var visual_mesh: Node3D = $VisualMesh
@onready var leg_l: Node3D = $VisualMesh/LegL
@onready var leg_r: Node3D = $VisualMesh/LegR

func _ready() -> void:
	add_to_group("ambient_pedestrians")
	if visual_mesh:
		visual_mesh.scale = Vector3(1.25, 1.25, 1.25)
	_setup_character_model()
	_pick_new_target()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if wait_timer > 0.0:
		wait_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed)
		if leg_l: leg_l.rotation.x = 0.0
		if leg_r: leg_r.rotation.x = 0.0
		if character_model:
			character_model.position.y = move_toward(character_model.position.y, 0.0, delta * 2.0)
			character_model.rotation.x = move_toward(character_model.rotation.x, 0.0, delta * 2.0)
	else:
		var diff = target_pos - global_position
		diff.y = 0.0
		if diff.length() < 1.2:
			wait_timer = randf_range(2.0, 5.0)
			_pick_new_target()
		else:
			var move_dir = diff.normalized()
			
			# Physics Ray obstacle probe to prevent walking into buildings / walls
			var space_state = get_world_3d().direct_space_state
			var ray_query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.6, 0), global_position + Vector3(0, 0.6, 0) + move_dir * 1.5)
			ray_query.exclude = [get_rid()]
			var hit = space_state.intersect_ray(ray_query)
			if not hit.is_empty():
				# Obstacle ahead: reroute immediately
				_pick_new_target()
				wait_timer = 0.5
			else:
				velocity.x = move_dir.x * walk_speed
				velocity.z = move_dir.z * walk_speed
				
				var target_rot = atan2(move_dir.x, move_dir.z)
				if visual_mesh and visual_mesh.visible:
					visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_rot, 5.0 * delta)
				
				# Walk leg swing for placeholder
				var swing = sin(Time.get_ticks_msec() * 0.008) * 0.35
				if leg_l: leg_l.rotation.x = swing
				if leg_r: leg_r.rotation.x = -swing
				
				# Procedural walk motion for 3D GLB model
				if character_model:
					walk_phase += delta * 8.0
					character_model.position.y = abs(sin(walk_phase)) * 0.035
					character_model.rotation.x = 0.04
					character_model.rotation.y = lerp_angle(character_model.rotation.y, target_rot, 6.0 * delta)

	move_and_slide()

func _pick_new_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(4.0, route_radius)
	var candidate = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	# Avoid walking directly into deep river water (y < -0.5)
	if candidate.x > 0.0 and candidate.x < 30.0 and candidate.z > 0.0 and candidate.z < 60.0:
		candidate.x = -abs(candidate.x)
	target_pos = candidate

func _setup_character_model() -> void:
	var idx = randi() % GLB_MODELS.size()
	var path = GLB_MODELS[idx]
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
