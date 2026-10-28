extends CharacterBody3D

# --- Character Stats & State ---
@export var speed: float = 4.8
@export var sprint_speed: float = 8.5
@export var accel: float = 26.0
@export var decel: float = 34.0
@export var jump_velocity: float = 5.4
@export var rotation_speed: float = 14.0

var locomotion_phase: float = 0.0

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
@onready var torso_mesh: MeshInstance3D = $VisualMesh.get_node_or_null("Torso")
@onready var longyi_mesh: MeshInstance3D = $VisualMesh.get_node_or_null("Longyi")

# Authentic Myanmar 3D Human Characters (1:1 Anatomical Scale with Full Sculpted Legs, Feet & Traditional Attire)
const CHARACTER_MODELS: Dictionary = {
	"fighter": "res://models/3_adult_fighter_character.glb",
	"youth": "res://models/2_youth_weaver_character.glb",
	"elder": "res://models/4_elder_villager_character.glb",
	"cowherd": "res://models/1_child_cowherd_character.glb"
}
const MODEL_NAMES: Dictionary = {
	"fighter": "🥋 ကိုမင်းဒင် (Adult Hero)",
	"youth": "🧵 ကိုအောင်ကျော် (Youth Weaver)",
	"elder": "👴 ဦးရွှေရိုး (Elder Sage)",
	"cowherd": "🐂 ဖိုးခွား (Cowherd Boy)"
}
var current_model_key: String = "fighter"
var character_model: Node3D = null

func _ready() -> void:
	add_to_group("player")
	_apply_game_mode()
	# Stair step snapping & slope walking smoothness (အိမ်လှေကားနှင့် ကုန်းဆင်းကုန်းတက် ချောမွေ့မှု)
	floor_snap_length = 0.35
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(48.0)
	wall_min_slide_angle = deg_to_rad(15.0)

	# Authentic 1:1 Human Scale (1.70m human height, 0.76m shoulder width)
	if visual_mesh:
		visual_mesh.scale = Vector3.ONE
	if collision_shape:
		collision_shape.scale = Vector3.ONE

	_setup_character_model("fighter")

func _setup_character_model(model_key: String) -> void:
	var existing = visual_mesh.get_node_or_null("CharacterModel3D")
	if existing:
		character_model = existing
	else:
		var path = CHARACTER_MODELS.get(model_key, CHARACTER_MODELS["fighter"])
		if ResourceLoader.exists(path):
			var scn = load(path) as PackedScene
			if scn:
				character_model = scn.instantiate() as Node3D
				character_model.name = "CharacterModel3D"
				visual_mesh.add_child(character_model)

	if character_model:
		character_model.position = Vector3(0.0, 0.04, 0.0)
		_setup_pbr_materials(character_model)

func _setup_pbr_materials(node: Node) -> void:
	for child in node.find_children("*", "MeshInstance3D", true):
		var mesh_inst = child as MeshInstance3D
		for s in range(mesh_inst.get_surface_override_material_count()):
			var mat = mesh_inst.get_active_material(s)
			if mat is StandardMaterial3D:
				mat.vertex_color_use_as_albedo = true
				mat.roughness = 0.72
				mat.specular = 0.25
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED

func set_character_model(model_key: String) -> String:
	if not CHARACTER_MODELS.has(model_key):
		return ""
	current_model_key = model_key
	if character_model and is_instance_valid(character_model):
		character_model.queue_free()
		character_model = null

	var path = CHARACTER_MODELS[model_key]
	if ResourceLoader.exists(path):
		var scn = load(path) as PackedScene
		if scn:
			character_model = scn.instantiate() as Node3D
			character_model.name = "CharacterModel3D"
			visual_mesh.add_child(character_model)
			character_model.position = Vector3(0.0, 0.04, 0.0)
			_setup_pbr_materials(character_model)

	var display_name = MODEL_NAMES.get(model_key, model_key)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_temporary_prompt"):
		hud.show_temporary_prompt("👤 ဇာတ်ကောင်: %s" % display_name, 3.0)
	return display_name

func cycle_character_model() -> String:
	var keys = ["fighter", "youth", "elder", "cowherd"]
	var idx = keys.find(current_model_key)
	var next_idx = (idx + 1) % keys.size()
	return set_character_model(keys[next_idx])

func _apply_game_mode() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm or not camera_pivot:
		return
	if sm.get("game_mode") == "mlbb":
		camera_pivot.target_arm_length = 6.5
		camera_pivot.current_arm_length = 6.5
		camera_pivot.rotation.x = deg_to_rad(-45.0)
	else:
		# PUBG TPP full-body framing (feet, legs & footsteps visible)
		camera_pivot.target_arm_length = 2.65
		camera_pivot.current_arm_length = 2.65
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

	var target_vel_x = move_direction.x * current_speed
	var target_vel_z = move_direction.z * current_speed
	var current_accel = accel if move_direction != Vector3.ZERO else decel

	if not is_parachuting:
		velocity.x = move_toward(velocity.x, target_vel_x, current_accel * delta)
		velocity.z = move_toward(velocity.z, target_vel_z, current_accel * delta)

	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	var speed_ratio = clampf(horiz_speed / sprint_speed, 0.0, 1.0)

	if horiz_speed > 0.12 and not is_parachuting:
		var target_angle = atan2(velocity.x, velocity.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, rotation_speed * delta)

		# Procedural organic human locomotion (footstep stride bob, thoracic counter-twist & athletic forward lean)
		if is_on_floor():
			var stride_freq = 11.5 if is_sprinting else 8.5
			locomotion_phase += delta * stride_freq
			var bob_y = abs(sin(locomotion_phase)) * 0.052 * speed_ratio
			var twist_y = sin(locomotion_phase) * 0.068 * speed_ratio
			var pitch_x = (0.05 + 0.09 * speed_ratio) if is_sprinting else (0.038 * speed_ratio)
			var sway_z = sin(locomotion_phase) * 0.042 * speed_ratio

			if character_model and is_instance_valid(character_model):
				character_model.position.y = 0.04 + bob_y
				character_model.rotation.y = twist_y
				character_model.rotation.z = sway_z
				character_model.rotation.x = pitch_x
			else:
				visual_mesh.position.y = bob_y
				visual_mesh.rotation.z = sway_z
				visual_mesh.rotation.x = pitch_x

			# Synchronized footstep audio
			footstep_timer -= delta
			var step_interval = 0.28 if is_sprinting else 0.44
			if footstep_timer <= 0.0:
				footstep_timer = step_interval
				var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
				if audio_mgr and audio_mgr.has_method("play_footstep"):
					audio_mgr.play_footstep()
	elif not is_parachuting:
		# Idle life: natural human breathing rhythm & grounded foot posture
		if is_on_floor():
			var breath = sin(Time.get_ticks_msec() * 0.0022) * 0.008
			if character_model and is_instance_valid(character_model):
				character_model.position.y = lerpf(character_model.position.y, 0.04 + breath, delta * 6.0)
				character_model.rotation.y = lerp_angle(character_model.rotation.y, 0.0, delta * 6.0)
				character_model.rotation.z = lerp_angle(character_model.rotation.z, 0.0, delta * 6.0)
				character_model.rotation.x = lerp_angle(character_model.rotation.x, 0.0, delta * 6.0)
			visual_mesh.position.y = lerpf(visual_mesh.position.y, 0.0, delta * 8.0)
			visual_mesh.rotation.z = lerpf(visual_mesh.rotation.z, 0.0, delta * 8.0)
			visual_mesh.rotation.x = lerpf(visual_mesh.rotation.x, 0.0, delta * 8.0)
		else:
			# Jump / Air posture: legs extending and forward pitch
			if character_model and is_instance_valid(character_model):
				character_model.position.y = lerpf(character_model.position.y, 0.08, delta * 8.0)
				character_model.rotation.x = lerpf(character_model.rotation.x, clampf(-velocity.y * 0.035, -0.22, 0.22), delta * 8.0)
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

func set_mounted_state(riding: bool, mount_node: Node3D) -> void:
	set_riding_state(riding, mount_node)

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
		if event.keycode == KEY_F or (event.keycode == KEY_E and current_state == State.ON_FOOT):
			interact()
		elif event.keycode == KEY_SPACE and current_state == State.ON_FOOT and is_on_floor():
			jump()
		elif event.keycode == KEY_H:
			if current_state != State.ON_FOOT:
				var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
				if audio_mgr and audio_mgr.has_method("play_horn"):
					audio_mgr.play_horn()
		elif event.keycode == KEY_R:
			if current_state != State.ON_FOOT:
				var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
				if audio_mgr and audio_mgr.has_method("cycle_radio_station"):
					var st_name = audio_mgr.cycle_radio_station()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(st_name, 3.5)
		elif event.keycode == KEY_L:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("cycle_headlight_mode"):
					var mode_name = active_vehicle.cycle_headlight_mode()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(mode_name, 3.0)
		elif event.keycode == KEY_K:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_wipers"):
					var wiper_msg = active_vehicle.toggle_wipers()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(wiper_msg, 2.5)
		elif event.keycode == KEY_J:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_windows"):
					var win_msg = active_vehicle.toggle_windows()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(win_msg, 2.5)
		elif event.keycode == KEY_U:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_hazard_lights"):
					var hazard_msg = active_vehicle.toggle_hazard_lights()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(hazard_msg, 2.5)
		elif event.keycode == KEY_M:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_rearview_mirror"):
					var mirror_msg = active_vehicle.toggle_rearview_mirror()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(mirror_msg, 2.5)
		elif event.keycode == KEY_O:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_ac"):
					var ac_msg = active_vehicle.toggle_ac()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(ac_msg, 2.5)
		elif event.keycode == KEY_I:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_dome_light"):
					var dome_msg = active_vehicle.toggle_dome_light()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(dome_msg, 2.5)
		elif event.keycode == KEY_G:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_glovebox"):
					var glove_msg = active_vehicle.toggle_glovebox()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(glove_msg, 2.5)
		elif event.keycode == KEY_V:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_sun_visors"):
					var visor_msg = active_vehicle.toggle_sun_visors()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(visor_msg, 2.5)
		elif event.keycode == KEY_P:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_aroma_diffuser"):
					var aroma_msg = active_vehicle.toggle_aroma_diffuser()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(aroma_msg, 2.5)
		elif event.keycode == KEY_T:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("sip_iced_tea"):
					var tea_msg = active_vehicle.sip_iced_tea()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(tea_msg, 2.5)
		elif event.keycode == KEY_Y:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_vanity_mirror"):
					var vanity_msg = active_vehicle.toggle_vanity_mirror()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(vanity_msg, 2.5)
		elif event.keycode == KEY_U:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("cycle_transmission_gear"):
					var gear_msg = active_vehicle.cycle_transmission_gear()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(gear_msg, 2.5)
		elif event.keycode == KEY_B:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_handbrake"):
					var hb_msg = active_vehicle.toggle_handbrake()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(hb_msg, 2.5)
		elif event.keycode == KEY_E:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_engine_ignition"):
					var ign_msg = active_vehicle.toggle_engine_ignition()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(ign_msg, 2.5)
		elif event.keycode == KEY_N:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_door_locks"):
					var lock_msg = active_vehicle.toggle_door_locks()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(lock_msg, 2.5)
		elif event.keycode == KEY_C:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_console_armrest"):
					var armrest_msg = active_vehicle.toggle_console_armrest()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(armrest_msg, 2.5)
		elif event.keycode == KEY_F:
			if current_state == State.DRIVING_VEHICLE and active_vehicle:
				if active_vehicle.has_method("toggle_fog_lights"):
					var fog_msg = active_vehicle.toggle_fog_lights()
					var hud = get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_temporary_prompt"):
						hud.show_temporary_prompt(fog_msg, 2.5)
