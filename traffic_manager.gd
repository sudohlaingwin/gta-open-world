extends Node3D
## Milestone 6 (part 1): ambient traffic manager. Lives ONLY in
## main.tscn (the world), so there is no traffic while the player is
## in the main menu: the menu scene never instantiates this node.
## It spawns a small fixed number of traffic vehicles, keeps them on
## waypoint loops along existing village roads, and respawns any
## vehicle that drifts too far from the player at a waypoint 25-45 m
## from the player (never within 15 m: never on top of the player).
## Traffic is AMBIENT and NOT saved: on load, fresh vehicles spawn
## again; no save data references them.
## A vehicle blocked continuously for 15 s is despawned and its slot
## refilled from a free waypoint: stop-only avoidance means a parked
## player vehicle or a villager lingering on the road would otherwise
## jam that road forever. This is standard traffic management, stated
## plainly, not steering-around (which part 2 does not add either).
## Pause: this node and its vehicles use the default pause mode, so
## when Slice 21's pause sets get_tree().paused, traffic freezes with
## the rest of the world. No code here fights the pause.
## Headlights follow the day/night cycle: dark means the same
## daylight < 0.15 rule day_night.gd uses for the moon and stars.
## Traffic vehicles are NOT enterable and have no physics body (see
## traffic_car.gd). Entering traffic, traffic signals, intersection
## priority, and steering-around avoidance are intentionally deferred.
## Milestone 6 (part 2): a second vehicle type (van) shares the routes
## with the cars, and the fleet follows the time of day. Density and
## speed come from the SAME shared daylight value day_night.gd
## exposes (daylight()): midday (daylight >= 0.6) runs all 6 slots at
## full speed; morning/evening (0.15 <= daylight < 0.6) runs 4 slots
## at 0.85 speed; night (daylight < 0.15) runs 2 slots at 0.7 speed.
## The total is still capped (6 max) so low-end phones stay safe.
## Shrinking the fleet despawns the extra vehicles outright (the same
## despawn the stuck-timeout already used); growing it refills the
## empty slots from free waypoints. No vehicle is ever teleported
## into the player's face: refills use the same 25-45 m band.

const MAX_SLOTS: int = 6
const SPAWN_MIN: float = 25.0
const SPAWN_MAX: float = 45.0
const DESPAWN_DIST: float = 75.0
## A vehicle blocked continuously for this long is despawned and
## respawned on a free stretch (standard traffic management, not a
## crash): with stop-only avoidance, a parked player vehicle or a
## villager lingering on the road would otherwise jam that road
## forever. The replacement spawns 25-45 m from the player, never on
## top of the player.
const STUCK_TIMEOUT: float = 15.0
## Time-of-day re-evaluation cadence: the daylight band changes a
## few times per 120 s day, so checking once a second is plenty.
const REEVAL_INTERVAL: float = 1.0

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
## Slot table, fixed at _ready: slots 0-2 run the north loop, 3-5 the
## south loop. Types alternate so both routes are mixed: north runs
## car, van, car; south runs van, car, van. Order is the slot's
## position within its own route (used for spawn spreading).
var _slot_is_van: Array = [false, true, false, true, false, true]
var _slot_route_idx: Array = [0, 0, 0, 1, 1, 1]
var _slot_order: Array = [0, 1, 2, 0, 1, 2]

var _cars: Array = []
var _player: Node3D = null
var _day_night: Node = null
var _car_scene: PackedScene = null
var _van_scene: PackedScene = null
var _colors: Array = [
	Color(0.8, 0.2, 0.2, 1), Color(0.2, 0.4, 0.8, 1),
	Color(0.9, 0.85, 0.2, 1), Color(0.25, 0.7, 0.3, 1),
]
var _player_vehicle_names: Array = [
	"Car", "Cart", "Motorcycle", "Airplane", "Helicopter",
	"TukTuk", "Boat", "Boat2", "Bicycle", "Elephant",
	"Horse", "Horse2", "Cow", "Cow2",
]
var _speed_factor: float = 1.0
var _reeval_timer: float = 0.0

func _route_for(slot: int) -> Array:
	return north_route if _slot_route_idx[slot] == 0 else south_route

func _scene_for(slot: int) -> PackedScene:
	return _van_scene if _slot_is_van[slot] else _car_scene

func _name_for(slot: int) -> String:
	if _slot_is_van[slot]:
		return "TrafficVan%d" % slot
	return "TrafficCar%d" % slot

## Which slots run at each fleet size. The first slots of each route
## stay on longest: at night only slot 0 (north car) and slot 3
## (south van) run; morning/evening adds slot 1 (north van) and
## slot 4 (south car); midday runs all six.
func _active_slots(count: int) -> Array:
	if count >= 6:
		return [0, 1, 2, 3, 4, 5]
	if count >= 4:
		return [0, 1, 3, 4]
	return [0, 3]

func _daylight() -> float:
	if _day_night == null or not _day_night.has_method("daylight"):
		return 1.0
	return float(_day_night.call("daylight"))

func _fleet_for_day(day: float) -> int:
	if day >= 0.6:
		return 6
	if day >= 0.15:
		return 4
	return 2

func _speed_for_day(day: float) -> float:
	if day >= 0.6:
		return 1.0
	if day >= 0.15:
		return 0.85
	return 0.7

## Applies the current time-of-day fleet: sets the speed factor and
## despawns vehicles in slots that are no longer active. Growing the
## fleet needs no work here: the main loop refills null slots from
## free waypoints on the next frame.
func _apply_time_of_day() -> void:
	var day := _daylight()
	_speed_factor = _speed_for_day(day)
	var active := _active_slots(_fleet_for_day(day))
	for ci in range(_cars.size()):
		if not active.has(ci) and _cars[ci] != null:
			var dead := _cars[ci] as Node3D
			remove_child(dead)
			dead.queue_free()
			_cars[ci] = null

func _ready() -> void:
	_player = get_node_or_null("../Player") as Node3D
	_day_night = get_node_or_null("../DayNight")
	_car_scene = load("res://scenes/traffic_car.tscn") as PackedScene
	_van_scene = load("res://scenes/traffic_van.tscn") as PackedScene
	var day := _daylight()
	_speed_factor = _speed_for_day(day)
	var active := _active_slots(_fleet_for_day(day))
	for ci in range(MAX_SLOTS):
		if active.has(ci):
			var route := _route_for(ci)
			var car := _scene_for(ci).instantiate() as Node3D
			car.name = _name_for(ci)
			car.set("body_color", _colors[ci % _colors.size()])
			car.set("route", route)
			add_child(car)
			_spawn_car(car, route, _slot_order[ci] * (route.size() / 3), true)
			car.set("speed_factor", _speed_factor)
			_cars.append(car)
		else:
			_cars.append(null)

## Picks the waypoint nearest 35 m from the player, or -1 when no
## waypoint is in the 25-45 m band. Offset spreads vehicles sharing
## one route around the loop: two vehicles spawned on the same
## waypoint would block each other forever (each sees the other
## inside its stop radius), so same-route vehicles must never share
## a spawn waypoint.
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
	return _daylight() < 0.15

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

## Fills an empty ACTIVE slot with a fresh vehicle on the slot's
## route, or leaves the slot empty for a later frame when no waypoint
## is in the 25-45 m band. Inactive slots are never refilled: the
## night fleet stays quiet until the day band grows again.
func _refill_slot(ci: int) -> void:
	if not _active_slots(_fleet_for_day(_daylight())).has(ci):
		return
	var route := _route_for(ci)
	var car := _scene_for(ci).instantiate() as Node3D
	car.name = _name_for(ci)
	car.set("body_color", _colors[ci % _colors.size()])
	car.set("route", route)
	add_child(car)
	if _spawn_car(car, route, _slot_order[ci] * (route.size() / 3), false):
		car.set("speed_factor", _speed_factor)
		_cars[ci] = car
	else:
		remove_child(car)
		car.queue_free()

func _physics_process(delta: float) -> void:
	_reeval_timer += delta
	if _reeval_timer >= REEVAL_INTERVAL:
		_reeval_timer = 0.0
		_apply_time_of_day()
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
				# player; otherwise the vehicle keeps looping
				# (respawning to a still-distant waypoint every tick
				# would churn without ever bringing traffic near
				# the player).
				var route := _route_for(ci)
				_spawn_car(car_node, route, _slot_order[ci] * (route.size() / 3), false)
		car_node.set("speed_factor", _speed_factor)
		car_node.call("set_headlights", dark)
		var obs := _collect_obstacles(car_node)
		car_node.call("drive", delta, obs)
