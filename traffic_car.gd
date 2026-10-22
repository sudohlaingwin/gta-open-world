extends Node3D
## Milestone 6 (part 1): ambient traffic car. NOT a player vehicle and
## NOT enterable (entering traffic is a later milestone, not this one).
## A traffic car follows a waypoint loop, keeps its speed believable,
## and STOPS for anything ahead of it (player, villager, other traffic)
## or anything very close on any side. Avoidance is STOP-ONLY: it never
## steers around an obstacle, so it can never swerve through a building
## or into the player. It has NO physics body on purpose: a moving body
## could push or trap the player, and this is a peaceful game with no
## damage system anywhere. If the player walks into a stopped traffic
## car, nothing happens: no damage, no push, no launch.
## Forward is +Z (rotation.y = atan2(dir.x, dir.z), same convention as
## player.gd). Headlights are plain emissive boxes toggled by the
## manager when the day/night cycle is dark (same daylight < 0.15 rule
## day_night.gd uses for the moon and stars).

@export var top_speed: float = 6.0
@export var accel_rate: float = 3.0
@export var brake_rate: float = 9.0
@export var turn_rate: float = 2.2
@export var body_color: Color = Color(0.8, 0.2, 0.2, 1)

var route: Array = []
var waypoint_index: int = 0
var speed: float = 0.0
var headlights_on: bool = false
## Seconds this car has spent continuously blocked (see drive()).
## TrafficManager despawns + respawns a car stuck past its timeout:
## a parked player vehicle or a lingering villager must never jam a
## road forever, and v1 has no steering-around (stop-only by design).
var stuck_time: float = 0.0

var _headlight_l: MeshInstance3D = null
var _headlight_r: MeshInstance3D = null
var _wheels: Array = []

func _ready() -> void:
	# Visuals live in scenes/traffic_car.tscn (scene resources, not
	# code-built meshes: code-built meshes trip the headless dummy
	# renderer with null-mesh errors, while scene resources load
	# clean. The body material is duplicated per car so each car
	# keeps its own paint color instead of tinting all cars at once.
	var body := get_node_or_null("TrafficBody") as MeshInstance3D
	if body != null and body.material_override != null:
		var own_mat := (body.material_override as Material).duplicate() as StandardMaterial3D
		own_mat.albedo_color = body_color
		body.material_override = own_mat
	var cabin := get_node_or_null("TrafficCabin") as MeshInstance3D
	if cabin != null and body != null:
		cabin.material_override = body.material_override
	for wname in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		var spinner := get_node_or_null(wname) as Node3D
		if spinner != null:
			_wheels.append(spinner)
	_headlight_l = get_node_or_null("TrafficHeadlightL") as MeshInstance3D
	_headlight_r = get_node_or_null("TrafficHeadlightR") as MeshInstance3D

func set_headlights(on: bool) -> void:
	headlights_on = on
	if _headlight_l != null:
		_headlight_l.visible = on
	if _headlight_r != null:
		_headlight_r.visible = on

func _forward() -> Vector3:
	return Vector3(sin(rotation.y), 0.0, cos(rotation.y))

func _blocked(obstacles: Array) -> bool:
	var pos := Vector2(global_position.x, global_position.z)
	var fwd := _forward()
	for ob in obstacles:
		var o := Vector2(ob.x, ob.z)
		var to_ob := o - pos
		var dist := to_ob.length()
		if dist < 2.5:
			return true
		if dist < 6.0:
			var dir := to_ob / dist
			var cone := fwd.x * dir.x + fwd.z * dir.y
			if cone > 0.7:
				return true
	return false

## Called by TrafficManager every physics frame. Returns nothing; the
## car moves itself. Obstacles are Vector3 world positions (player,
## player vehicles, villagers, other traffic cars).
func drive(delta: float, obstacles: Array) -> void:
	if route.is_empty():
		return
	var target := route[waypoint_index] as Vector2
	var pos := Vector2(global_position.x, global_position.z)
	var to_target := target - pos
	if to_target.length() < 2.0:
		waypoint_index = (waypoint_index + 1) % route.size()
		target = route[waypoint_index]
		to_target = target - pos
	var desired_yaw := atan2(to_target.x, to_target.y)
	var diff := desired_yaw - rotation.y
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	var step := clampf(diff, -turn_rate * delta, turn_rate * delta)
	rotation.y += step
	var want := top_speed
	if _blocked(obstacles):
		want = 0.0
		# Still counts while decelerating into the jam: a car that
		# sits blocked for the manager's whole timeout is stuck,
		# whether it stopped instantly or braked to a halt first.
		stuck_time += delta
	else:
		stuck_time = 0.0
	if speed < want:
		speed = min(want, speed + accel_rate * delta)
	else:
		speed = max(want, speed - brake_rate * delta)
	var fwd := _forward()
	global_position += fwd * speed * delta
	for wheel in _wheels:
		wheel.rotation.x += speed * delta / 0.32
