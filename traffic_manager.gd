extends Node3D
## Milestone 6 (part 1): ambient traffic manager. Lives ONLY in
## main.tscn (the world), so there is no traffic while the player is
## in the main menu: the menu scene never instantiates this node.
## It spawns a small fixed number of traffic cars (4: two per route),
## keeps them on waypoint loops along existing village roads, and
## respawns any car that drifts too far from the player at a waypoint
## 25-45 m from the player (never within 15 m: never on top of the
## player). Traffic is AMBIENT and NOT saved: on load, fresh cars
## spawn again; no save data references them.
## A car blocked continuously for 15 s is despawned and its slot
## refilled from a free waypoint: stop-only avoidance means a parked
## player vehicle or a villager lingering on the road would otherwise
## jam that road forever. This is standard traffic management, stated
## plainly, not steering-around (which v1 does not do).
## Pause: this node and its cars use the default pause mode, so when
## Slice 21's pause sets get_tree().paused, traffic freezes with the
## rest of the world. No code here fights the pause.
## Headlights follow the day/night cycle: dark means the same
## daylight < 0.15 rule day_night.gd uses for the moon and stars.
## Traffic cars are NOT enterable and have no physics body (see
## traffic_car.gd). Entering traffic, traffic signals, intersection
## priority, and pedestrian schedules are intentionally deferred.

const CAR_COUNT: int = 4
const SPAWN_MIN: float = 25.0
const SPAWN_MAX: float = 45.0
const DESPAWN_DIST: float = 75.0
## A car blocked continuously for this long is despawned and respawned
## on a free stretch (standard traffic management, not a crash): with
## stop-only avoidance, a parked player vehicle or a villager lingering
## on the road would otherwise jam that road forever. The replacement
## spawns 25-45 m from the player, never on top of the player.
const STUCK_TIMEOUT: float = 15.0

## North loop: entrance road (x=-1, threading the gate posts and the
## lantern posts with ~0.1-0.5 m clearance) then the north village
## roads. The (-1,-17) waypoint stays north of the raised stilt-house
## deck edge (deck spans z -25.25..-18.75, car length reaches -18.6).
## South loop: pavilion/school quarter, threading the pavilion edge
## (0.3 m), the paddy field edge (0.2 m) and the gate lantern (0.7 m
## from the respawn point). Clearances were checked against the real
## mesh sizes in main.tscn, not just node origins.
var north_route: Array = [
	Vector2(-1, 10), Vector2(-1, -17), Vector2(-8, -17),
	Vector2(-8, -28.5), Vector2(24, -28.5), Vector2(24, -18.5),
	Vector2(18, -18.5), Vector2(18, -12), Vector2(3, -12),
	Vector2(3, -16), Vector2(-10, -16), Vector2(-10, -8),
	Vector2(-10, 6), Vector2(-13, 6), Vector2(-13, 10),
]
var south_route: Array = [
	Vector2(2, 28), Vector2(2, 36), Vector2(14, 36),
	Vector2(14, 28), Vector2(14, 26.6), Vector2(6, 26.6),
]

var _cars: Array = []
var _car_routes: Array = []
var _player: Node3D = null
var _day_night: Node = null
var _car_scene: PackedScene = null
var _colors: Array = [
	Color(0.8, 0.2, 0.2, 1), Color(0.2, 0.4, 0.8, 1),
	Color(0.9, 0.85, 0.2, 1), Color(0.25, 0.7, 0.3, 1),
]
var _player_vehicle_names: Array = [
	"Car", "Cart", "Motorcycle", "Airplane", "Helicopter",
	"TukTuk", "Boat", "Boat2", "Bicycle", "Elephant",
	"Horse", "Horse2", "Cow", "Cow2",
]

func _ready() -> void:
	_player = get_node_or_null("../Player") as Node3D
	_day_night = get_node_or_null("../DayNight")
	var route_counts: Array[int] = [0, 0]
	_car_scene = load("res://scenes/traffic_car.tscn") as PackedScene
	for i in range(CAR_COUNT):
		var car := _car_scene.instantiate() as Node3D
		car.name = "TrafficCar%d" % i
		car.set("body_color", _colors[i % _colors.size()])
		var use_north := i % 2 == 0
		var route: Array = north_route if use_north else south_route
		var slot: int = 0 if use_north else 1
		var offset: int = route_counts[slot] * (route.size() / 2)
		route_counts[slot] += 1
		car.set("route", route)
		add_child(car)
		_spawn_car(car, route, offset, true)
		_cars.append(car)
		_car_routes.append(route)

## Picks the waypoint nearest 35 m from the player, or -1 when no
## waypoint is in the 25-45 m band. Offset spreads cars sharing one
## route around the loop: two cars spawned on the same waypoint
## would block each other forever (each sees the other within the
## 2.5 m all-around stop radius), so same-route cars must never
## share a spawn waypoint.
func _pick_spawn_index(route: Array) -> int:
	var best := -1
	var best_score := 1e9
	var player_pos := Vector2.ZERO
	if _player != null:
		player_pos = Vector2(_player.global_position.x, _player.global_position.z)
	for i in range(route.size()):
		var wp := route[i] as Vector2
		var d := wp.distance_to(player_pos) if _player != null else 35.0
		if d >= SPAWN_MIN and d <= SPAWN_MAX:
			var score := absf(d - 35.0)
			if score < best_score:
				best_score = score
				best = i
	return best

func _spawn_car(car: Node3D, route: Array, offset: int, allow_farthest: bool) -> bool:
	var best := _pick_spawn_index(route)
	var idx := -1
	if best >= 0:
		idx = (best + offset) % route.size()
	elif allow_farthest:
		var player_pos := Vector2.ZERO
		if _player != null:
			player_pos = Vector2(_player.global_position.x, _player.global_position.z)
		var farthest := 0
		var farthest_dist := -1.0
		for i in range(route.size()):
			var d := (route[i] as Vector2).distance_to(player_pos)
			if d > farthest_dist:
				farthest_dist = d
				farthest = i
		idx = farthest
	else:
		return false
	var wp0 := route[idx] as Vector2
	var wp1 := route[(idx + 1) % route.size()] as Vector2
	car.global_position = Vector3(wp0.x, 0.0, wp0.y)
	var dir := wp1 - wp0
	car.rotation.y = atan2(dir.x, dir.y)
	car.set("waypoint_index", (idx + 1) % route.size())
	car.set("speed", 0.0)
	return true

func _is_dark() -> bool:
	if _day_night == null:
		return false
	var t: float = _day_night.get("time")
	var day_len: float = _day_night.get("day_length_seconds")
	if day_len <= 0.0:
		return false
	var angle := fmod(t / day_len * 360.0, 360.0)
	var daylight := clampf(sin(deg_to_rad(angle)), 0.0, 1.0)
	return daylight < 0.15

func _collect_obstacles(except_car: Node3D) -> Array:
	var obs: Array = []
	if _player != null:
		obs.append(_player.global_position)
	var root := get_parent()
	if root != null:
		for vname in _player_vehicle_names:
			var v := root.get_node_or_null(vname) as Node3D
			if v != null:
				obs.append(v.global_position)
		for child in root.get_children():
			if child.name.begins_with("Villager"):
				obs.append((child as Node3D).global_position)
	for other in _cars:
		if other != null and other != except_car:
			obs.append((other as Node3D).global_position)
	return obs

## Fills an empty slot (a car previously despawned as stuck) with a
## fresh car on the same route, or leaves the slot empty for a later
## frame when no waypoint is in the 25-45 m band.
func _refill_slot(ci: int) -> void:
	var route: Array = _car_routes[ci]
	var order := 0
	for cj in range(ci):
		if _car_routes[cj] == route and _cars[cj] != null:
			order += 1
	var car := _car_scene.instantiate() as Node3D
	car.name = "TrafficCar%d" % ci
	car.set("body_color", _colors[ci % _colors.size()])
	car.set("route", route)
	add_child(car)
	if _spawn_car(car, route, order * (route.size() / 2), false):
		_cars[ci] = car
	else:
		remove_child(car)
		car.queue_free()

func _physics_process(delta: float) -> void:
	var dark := _is_dark()
	for ci in range(_cars.size()):
		var car_node := _cars[ci] as Node3D
		if car_node == null:
			_refill_slot(ci)
			continue
		var stuck: float = car_node.get("stuck_time")
		if stuck > STUCK_TIMEOUT:
			# Jammed past the timeout (parked vehicle, lingering
			# villager): remove it and refill the slot next frame
			# from a free waypoint, so traffic keeps flowing.
			remove_child(car_node)
			car_node.queue_free()
			_cars[ci] = null
			continue
		if _player != null:
			var d := car_node.global_position.distance_to(_player.global_position)
			if d > DESPAWN_DIST:
				# Respawn only when a waypoint is actually near the
				# player; otherwise the car keeps looping (respawning
				# to a still-distant waypoint every tick would churn
				# without ever bringing traffic near the player).
				var route: Array = _car_routes[ci]
				var order := 0
				for cj in range(ci):
					if _car_routes[cj] == route:
						order += 1
				_spawn_car(car_node, route, order * (route.size() / 2), false)
		car_node.call("set_headlights", dark)
		var obs := _collect_obstacles(car_node)
		car_node.call("drive", delta, obs)
