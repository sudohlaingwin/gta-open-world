extends CharacterBody3D

# --- Ambient Pedestrian AI System (ရွာလမ်းလျှောက်သူများ AI) ---

@export var walk_speed: float = 1.6
@export var route_radius: float = 18.0
var target_pos: Vector3 = Vector3.ZERO
var wait_timer: float = 0.0

@onready var visual_mesh: Node3D = $VisualMesh
@onready var leg_l: Node3D = $VisualMesh/LegL
@onready var leg_r: Node3D = $VisualMesh/LegR

func _ready() -> void:
	add_to_group("ambient_pedestrians")
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
	else:
		var diff = target_pos - global_position
		diff.y = 0.0
		if diff.length() < 1.2:
			wait_timer = randf_range(2.0, 5.0)
			_pick_new_target()
		else:
			var move_dir = diff.normalized()
			velocity.x = move_dir.x * walk_speed
			velocity.z = move_dir.z * walk_speed
			
			var target_rot = atan2(move_dir.x, move_dir.z)
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_rot, 5.0 * delta)
			
			# Walk leg swing
			var swing = sin(Time.get_ticks_msec() * 0.008) * 0.35
			if leg_l: leg_l.rotation.x = swing
			if leg_r: leg_r.rotation.x = -swing

	move_and_slide()

func _pick_new_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(4.0, route_radius)
	target_pos = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)