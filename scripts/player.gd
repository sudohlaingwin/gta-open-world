extends CharacterBody3D

# --- Character Stats & State ---
@export var speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.8
@export var rotation_speed: float = 12.0

var stamina: float = 100.0

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

@onready var visual_mesh: Node3D = $VisualMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: Node3D = $CameraPivot

func _ready() -> void:
	add_to_group("player")

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
		else:
			velocity.y -= gravity * delta
	else:
		if is_parachuting:
			is_parachuting = false
			var chute_mesh = visual_mesh.get_node_or_null("ParachuteMesh")
			if chute_mesh:
				chute_mesh.visible = false

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
	elif not is_parachuting:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

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
				var villager = _get_nearest_villager(4.0)
				if villager and villager.has_method("talk_to"):
					villager.talk_to(global_position)
					var hud = get_tree().get_first_node_in_group("hud")
					if not hud:
						hud = get_parent().get_node_or_null("MobileTouchHUD")
					if hud and hud.has_method("record_villager_talk"):
						hud.record_villager_talk()

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
	else:
		current_state = State.ON_FOOT
		active_mount = null
		collision_shape.disabled = false

func set_driving_state(driving: bool, vehicle_node: Node3D) -> void:
	if driving:
		current_state = State.DRIVING_VEHICLE
		active_vehicle = vehicle_node
		collision_shape.disabled = true
	else:
		current_state = State.ON_FOOT
		active_vehicle = null
		collision_shape.disabled = false

func set_flying_state(flying: bool, aircraft_node: Node3D) -> void:
	if flying:
		current_state = State.FLYING_AIRCRAFT
		active_aircraft = aircraft_node
		collision_shape.disabled = true
	else:
		current_state = State.ON_FOOT
		active_aircraft = null
		collision_shape.disabled = false

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