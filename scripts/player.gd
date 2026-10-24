extends CharacterBody3D

# --- Character Stats & State ---
@export var speed: float = 7.5
@export var sprint_speed: float = 12.0
@export var jump_velocity: float = 5.2
@export var rotation_speed: float = 12.0

var stamina: float = 100.0
var health: float = 100.0
var max_health: float = 100.0

enum State { ON_FOOT, RIDING_MOUNT, DRIVING_VEHICLE, FLYING_AIRCRAFT }
var current_state: State = State.ON_FOOT

var active_mount: Node3D = null
var nearby_mount: Node3D = null
var active_vehicle: Node3D = null
var nearby_vehicle: Node3D = null
var active_aircraft: Node3D = null
var nearby_aircraft: Node3D = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting: bool = false
var is_parachuting: bool = false
@export var parachute_fall_speed: float = 3.5
@export var parachute_glide_speed: float = 8.0
var touch_input_vector: Vector2 = Vector2.ZERO
var touch_yaw: float = 0.0
var footstep_timer: float = 0.0

@onready var visual_mesh: Node3D = $VisualMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var torso_mesh: MeshInstance3D = $VisualMesh/Torso
@onready var longyi_mesh: MeshInstance3D = $VisualMesh/Longyi

func _ready() -> void:
	add_to_group("player")
	_apply_saved_outfit()
	_apply_game_mode()
	# PUBG Full-size Character Scale (အရွယ်အစား ပီပြင်စေရန် 1.25x scale မြှင့်တင်ခြင်း)
	if visual_mesh:
		visual_mesh.scale = Vector3(1.25, 1.25, 1.25)
	if collision_shape:
		collision_shape.scale = Vector3(1.15, 1.15, 1.15)

func _apply_game_mode() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm or not camera_pivot:
		return
	if sm.get("game_mode") == "mlbb":
		camera_pivot.target_arm_length = 6.5
		camera_pivot.current_arm_length = 6.5
		camera_pivot.rotation.x = deg_to_rad(-45.0)
	else:
		# PUBG TPP over-the-shoulder framing
		camera_pivot.target_arm_length = 1.95
		camera_pivot.current_arm_length = 1.95
		camera_pivot.rotation.x = deg_to_rad(-8.0)

var highest_fall_speed: float = 0.0

func _physics_process(delta: float) -> void:
	if current_state != State.ON_FOOT:
		return

	if not is_on_floor():
		if is_parachuting:
			velocity.y = move_toward(velocity.y, -parachute_fall_speed, 10.0 * delta)
			var forward = -camera_pivot.global_transform.basis.z
			forward.y = 0.0
			forward = forward.normalized()
			var right = camera_pivot.global_transform.basis.x
			right.y = 0.0
			right = right.normalized()
			var glide_dir = (forward * -touch_input_vector.y + right * touch_input_vector.x).normalized()
			velocity.x = glide_dir.x * parachute_glide_speed
			velocity.z = glide_dir.z * parachute_glide_speed
			highest_fall_speed = 0.0
		else:
			velocity.y -= gravity * delta
			if -velocity.y > highest_fall_speed:
				highest_fall_speed = -velocity.y
	else:
		if is_parachuting:
			is_parachuting = false
			var chute_mesh = visual_mesh.get_node_or_null("ParachuteMesh")
			if chute_mesh:
				chute_mesh.visible = false
		elif highest_fall_speed > 14.0:
			# Apply authentic fall impact damage based on landing velocity
			var damage = (highest_fall_speed - 14.0) * 4.5
			take_damage(damage)
		highest_fall_speed = 0.0

		# Gradual health recovery over time when resting safely
		if health < max_health:
			health = min(max_health, health + 2.0 * delta)

	# Input handling (Touch priority, keyboard fallback)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if touch_input_vector != Vector2.ZERO:
		input_dir = touch_input_vector

	# Transform input relative to camera orbit
	var cam_basis = camera_pivot.global_transform.basis
	var forward = -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right = cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	var current_speed = sprint_speed if (is_sprinting and stamina > 0.0) else speed

	if move_direction != Vector3.ZERO and not is_parachuting:
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
		var target_angle = atan2(move_direction.x, move_direction.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, rotation_speed * delta)
		
		# Footstep audio trigger on ground
		if is_on_floor():
			footstep_timer -= delta
			var step_interval = 0.28 if is_sprinting else 0.45
			if footstep_timer <= 0.0:
				footstep_timer = step_interval
				var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
				if audio_mgr and audio_mgr.has_method("play_footstep"):
					audio_mgr.play_footstep()
	elif not is_parachuting:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		footstep_timer = 0.1

	move_and_slide()

func interact() -> void:
	match current_state:
		State.RIDING_MOUNT:
			if active_mount and active_mount.has_method("exit_mount"):
				active_mount.exit_mount()
		State.DRIVING_VEHICLE:
			if active_vehicle and active_vehicle.has_method("exit_vehicle"):
				active_vehicle.exit_vehicle()
		State.FLYING_AIRCRAFT:
			if active_aircraft and active_aircraft.has_method("exit_aircraft"):
				active_aircraft.exit_aircraft()
		State.ON_FOOT:
			if nearby_mount and nearby_mount.has_method("enter_mount"):
				nearby_mount.enter_mount(self)
			elif nearby_vehicle and nearby_vehicle.has_method("enter_vehicle"):
				nearby_vehicle.enter_vehicle(self)
			elif nearby_aircraft and nearby_aircraft.has_method("enter_aircraft"):
				nearby_aircraft.enter_aircraft(self)
			else:
				var airdrop = _get_nearest_airdrop(5.0)
				if airdrop and airdrop.has_method("loot_crate"):
					airdrop.loot_crate(self)
				else:
					var villager = _get_nearest_villager(4.0)
					if villager and villager.has_method("talk_to"):
						villager.talk_to(global_position)
						var hud = get_tree().get_first_node_in_group("hud")
						if not hud:
							hud = get_parent().get_node_or_null("MobileTouchHUD")
						if hud and hud.has_method("record_villager_talk"):
							hud.record_villager_talk()

func _get_nearest_airdrop(max_dist: float) -> Node3D:
	var drops = get_tree().get_nodes_in_group("interactables")
	var nearest: Node3D = null
	var min_dist = max_dist
	for d_node in drops:
		if d_node.has_method("loot_crate") and not d_node.get("is_looted"):
			var dist = global_position.distance_to(d_node.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = d_node
	return nearest

func _get_nearest_villager(max_dist: float) -> Node3D:
	var villagers = get_tree().get_nodes_in_group("villagers")
	var nearest: Node3D = null
	var min_dist = max_dist
	for v in villagers:
		var d = global_position.distance_to(v.global_position)
		if d < min_dist:
			min_dist = d
			nearest = v
	return nearest

func set_riding_state(riding: bool, mount_node: Node3D) -> void:
	if riding:
		current_state = State.RIDING_MOUNT
		active_mount = mount_node
		collision_shape.disabled = true
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
	else:
		current_state = State.ON_FOOT
		active_mount = null
		collision_shape.disabled = false
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)

func set_driving_state(driving: bool, vehicle_node: Node3D) -> void:
	if driving:
		current_state = State.DRIVING_VEHICLE
		active_vehicle = vehicle_node
		collision_shape.disabled = true
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
	else:
		current_state = State.ON_FOOT
		active_vehicle = null
		collision_shape.disabled = false
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)

func set_flying_state(flying: bool, aircraft_node: Node3D) -> void:
	if flying:
		current_state = State.FLYING_AIRCRAFT
		active_aircraft = aircraft_node
		collision_shape.disabled = true
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
	else:
		current_state = State.ON_FOOT
		active_aircraft = null
		collision_shape.disabled = false
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)

func set_interactable_mount(mount_node: Node3D) -> void:
	nearby_mount = mount_node

func set_interactable_vehicle(vehicle_node: Node3D) -> void:
	nearby_vehicle = vehicle_node

func set_interactable_aircraft(aircraft_node: Node3D) -> void:
	nearby_aircraft = aircraft_node

func jump() -> void:
	if current_state == State.ON_FOOT and is_on_floor():
		velocity.y = jump_velocity

func toggle_parachute() -> void:
	if current_state == State.ON_FOOT and not is_on_floor():
		is_parachuting = not is_parachuting
		var chute_mesh = visual_mesh.get_node_or_null("ParachuteMesh")
		if chute_mesh:
			chute_mesh.visible = is_parachuting

func set_sprint(sprint: bool) -> void:
	is_sprinting = sprint

func set_outfit_colors(shirt_color: Color, longyi_color: Color) -> void:
	if torso_mesh:
		var torso_mat = StandardMaterial3D.new()
		torso_mat.albedo_color = shirt_color
		torso_mesh.set_surface_override_material(0, torso_mat)
	if longyi_mesh:
		var longyi_mat = StandardMaterial3D.new()
		longyi_mat.albedo_color = longyi_color
		longyi_mat.roughness = 0.8
		longyi_mesh.set_surface_override_material(0, longyi_mat)

func _apply_saved_outfit() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.get("save_data") is Dictionary:
		var data = save_mgr.save_data
		if data.has("shirt_color") and data.has("longyi_color"):
			set_outfit_colors(data["shirt_color"], data["longyi_color"])

func recover_from_stuck() -> void:
	if current_state == State.DRIVING_VEHICLE and active_vehicle:
		if active_vehicle.has_method("exit_vehicle"):
			active_vehicle.exit_vehicle()
	elif current_state == State.RIDING_MOUNT and active_mount:
		if active_mount.has_method("exit_mount"):
			active_mount.exit_mount()
	elif current_state == State.FLYING_AIRCRAFT and active_aircraft:
		if active_aircraft.has_method("exit_aircraft"):
			active_aircraft.exit_aircraft()
	# Unstuck teleport to open village ground (Safe central plaza spawn)
	global_position = Vector3(0.0, 1.0, 0.0)
	velocity = Vector3.ZERO
	current_state = State.ON_FOOT
	collision_shape.disabled = false

func take_damage(amount: float) -> void:
	health = clampf(health - amount, 0.0, max_health)
	if health <= 0.0:
		# Player knockdown & respawn at central village ground
		recover_from_stuck()
		health = max_health

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			if current_state != State.ON_FOOT:
				var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
				if audio_mgr and audio_mgr.has_method("play_horn"):
					audio_mgr.play_horn()