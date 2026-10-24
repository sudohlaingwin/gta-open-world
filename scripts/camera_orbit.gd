extends Node3D

# --- Advanced PUBG-Scale 3D Camera System with 360° In-Vehicle Cockpit Freelook ---

enum ViewMode { TPP, COCKPIT }

@export var touch_sensitivity: float = 0.005
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 0.1
@export var max_zoom: float = 6.5
@export var shorten_speed: float = 24.0
@export var recovery_speed: float = 4.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var target_arm_length: float = 1.95
var current_arm_length: float = 1.95
var current_view_mode: ViewMode = ViewMode.TPP
var default_fov: float = 75.0
var target_fov: float = 75.0

# Free-look offsets & smoothing
var base_pivot_offset: Vector3 = Vector3(0, 1.45, 0)
var target_pivot_offset: Vector3 = Vector3(0, 1.45, 0)
var current_pivot_offset: Vector3 = Vector3(0, 1.45, 0)
var last_look_time: int = 0

signal view_mode_changed(mode_name: String)

func _ready() -> void:
	if spring_arm:
		spring_arm.spring_length = target_arm_length
		spring_arm.margin = 0.15
	if camera:
		default_fov = camera.fov
		target_fov = default_fov

func cycle_view_mode() -> String:
	if current_view_mode == ViewMode.TPP:
		current_view_mode = ViewMode.COCKPIT
	else:
		current_view_mode = ViewMode.TPP

	var mode_name = "🚗 ကားတွင်းရှုခင်း (Cockpit Freelook)" if current_view_mode == ViewMode.COCKPIT else "🎥 အပြင်မြင်ကွင်း (TPP Chase)"
	view_mode_changed.emit(mode_name)
	return mode_name

func get_current_view_mode_name() -> String:
	return "🚗 ကားတွင်းရှုခင်း" if current_view_mode == ViewMode.COCKPIT else "🎥 အပြင်မြင်ကွင်း"

func recenter_forward() -> void:
	rotation.y = 0.0
	rotation.x = deg_to_rad(-5.0)

func _physics_process(delta: float) -> void:
	if not spring_arm or not camera:
		return

	var player = get_parent()
	var is_in_vehicle = false
	var current_veh = null

	if player:
		if player.get("current_state") != null:
			var st = player.current_state
			# Check state: 1: RIDING_MOUNT, 2: DRIVING_VEHICLE, 3: FLYING_AIRCRAFT
			if st in [1, 2, 3]:
				is_in_vehicle = true
				if player.get("active_vehicle") != null:
					current_veh = player.active_vehicle
				elif player.get("active_mount") != null:
					current_veh = player.active_mount
				elif player.get("active_aircraft") != null:
					current_veh = player.active_aircraft

	# Determine View Mode & Camera Target Position
	if is_in_vehicle and current_view_mode == ViewMode.COCKPIT:
		# --- TRUE IN-VEHICLE COCKPIT / FREELOOK VIEW ---
		# Eye sits directly inside driver seat looking out the windshield and side windows
		target_arm_length = 0.05
		var veh_name = current_veh.name if current_veh else ""
		
		if "Car" in veh_name or "Van" in veh_name:
			# Driver's seat head position inside cabin (left-hand drive Myanmar standard)
			target_pivot_offset = Vector3(-0.35, 1.25, -0.05)
		elif "Cart" in veh_name:
			# Bullock cart driver bench: seated high, looking over wooden yoke and oxen horns
			target_pivot_offset = Vector3(0.0, 1.75, 0.40)
		elif "Motorcycle" in veh_name or "Bike" in veh_name:
			# Motorcycle: just behind windscreen & speedometer
			target_pivot_offset = Vector3(0.0, 1.30, -0.15)
		elif "TukTuk" in veh_name:
			target_pivot_offset = Vector3(0.0, 1.35, 0.10)
		elif "Boat" in veh_name or "Rowboat" in veh_name:
			target_pivot_offset = Vector3(0.0, 0.95, -0.30)
		else:
			# Mount (Cow / Horse / Elephant)
			target_pivot_offset = Vector3(0.0, 1.55, 0.0)

		# Dynamic Cockpit Speed-FOV expansion looking through windshield
		var v_speed = 0.0
		if current_veh and current_veh.get("linear_velocity") != null:
			v_speed = current_veh.linear_velocity.length()
		elif current_veh and current_veh.get("velocity") != null:
			v_speed = current_veh.velocity.length()
		var speed_factor = clampf(v_speed / 36.0, 0.0, 1.0)
		target_fov = lerpf(80.0, 92.0, speed_factor)

	elif is_in_vehicle and current_view_mode == ViewMode.TPP:
		# --- VEHICLE CHASE CAMERA ---
		target_arm_length = 5.8
		target_pivot_offset = Vector3(0, 1.8, 0)

		# Dynamic Speed-FOV expansion (feels like real open-world mobile driving!)
		var v_speed = 0.0
		if current_veh and current_veh.get("linear_velocity") != null:
			v_speed = current_veh.linear_velocity.length()
		elif current_veh and current_veh.get("velocity") != null:
			v_speed = current_veh.velocity.length()
		
		var speed_factor = clampf(v_speed / 36.0, 0.0, 1.0)
		target_fov = lerpf(default_fov, default_fov + 15.0, speed_factor)


	else:
		# --- ON FOOT OVER-SHOULDER ---
		target_arm_length = 1.95
		target_pivot_offset = base_pivot_offset
		target_fov = default_fov

	# Smoothly interpolate position and arm length
	current_pivot_offset = current_pivot_offset.lerp(target_pivot_offset, 10.0 * delta)
	position = current_pivot_offset
	camera.fov = lerpf(camera.fov, target_fov, 6.0 * delta)

	# Gentle vehicular cruise auto-centering (recenters forward after looking around)
	if is_in_vehicle and (Time.get_ticks_msec() - last_look_time > 3200):
		var v_spd = 0.0
		if current_veh and current_veh.get("linear_velocity") != null:
			v_spd = current_veh.linear_velocity.length()
		elif current_veh and current_veh.get("velocity") != null:
			v_spd = current_veh.velocity.length()
		if v_spd > 3.5:
			rotation.y = lerp_angle(rotation.y, 0.0, 1.4 * delta)


	# Raycast obstruction clearance (only relevant for TPP modes)
	if target_arm_length > 0.5:
		var space_state = get_world_3d().direct_space_state
		var origin_pos = global_position
		var cam_dir = (camera.global_position - origin_pos).normalized()
		var query = PhysicsRayQueryParameters3D.create(origin_pos, origin_pos + cam_dir * target_arm_length)
		
		var excludes: Array[RID] = []
		if player:
			excludes.append(player.get_rid())
		if current_veh and current_veh is CollisionObject3D:
			excludes.append(current_veh.get_rid())
		query.exclude = excludes

		var result = space_state.intersect_ray(query)
		var desired_length = target_arm_length

		if not result.is_empty():
			var hit_dist = origin_pos.distance_to(result.position) - 0.2
			desired_length = clamp(hit_dist, min_zoom, target_arm_length)

		if desired_length < current_arm_length:
			current_arm_length = move_toward(current_arm_length, desired_length, shorten_speed * delta)
		else:
			current_arm_length = move_toward(current_arm_length, desired_length, recovery_speed * delta)
	else:
		current_arm_length = target_arm_length

	spring_arm.spring_length = current_arm_length

func _input(event: InputEvent) -> void:
	# Hotkey 'V' on desktop to cycle view mode
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			cycle_view_mode()

	# Touch drag orbit & cockpit freelook on the right side of the screen
	if event is InputEventScreenDrag:
		if event.position.x > get_viewport().size.x * 0.35:
			var sens = touch_sensitivity
			var sm = get_node_or_null("/root/SaveManager")
			if sm and sm.get("camera_sensitivity") != null:
				sens *= sm.camera_sensitivity

			# Horizontal yaw: full 360-degree free look!
			rotation.y -= event.relative.x * sens
			rotation.y = wrapf(rotation.y, -PI, PI)
			last_look_time = Time.get_ticks_msec()

			# Vertical pitch: look up at sky/roof or down at steering/dashboard
			rotation.x -= event.relative.y * sens
			var pitch_min = -65.0
			var pitch_max = 45.0
			
			if current_view_mode == ViewMode.COCKPIT:
				pitch_min = -50.0
				pitch_max = 40.0

			rotation.x = clamp(rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))