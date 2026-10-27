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
## exposes (daylight()): midday (daylight >= 0.6) runs all 10 slots at
## full speed; morning/evening (0.15 <= daylight < 0.6) runs 7 slots
## at 0.85 speed; night (daylight < 0.15) runs 3 slots at 0.7 speed.
## The total is still capped (10 max) so low-end phones stay safe.
## Shrinking the fleet despawns the extra vehicles outright (the same
## despawn the stuck-timeout already used); growing it refills the
## empty slots from free waypoints. No vehicle is ever teleported
## into the player's face: refills use the same 25-45 m band.

const MAX_SLOTS: int = 12
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

## Slice 63: EAST routes on the Slice 62 East Fields network. The
## main road is a 12 m slab (z -6..6), so it carries a two-lane loop
## (eastbound z -3, westbound z +3, both on the slab, corners cut by
## at most ~3 m at turn_rate 2.2 — still inside the x -70..450
## bounds and clear of every house/tree/lamp). The dirt lanes are
## dead ends, so they run as out-and-back loops (the repeated middle
## waypoint is intentional: drive() advances on arrival, so the car
## drives down the lane and back on the same strip, U-turning at
## the far end). Clearances checked against Slice 62 coordinates:
## north lane x 340 stays 6.4+ m from the (330,-40)/(330,-70)
## stilt-house footprints (x ..332.5) and 8 m from lane trees;
## south lane x 390 stays clear of pond B (x 410..420) and lane
## trees; neither lane touches the x 350 stream (x 347..353) or
## any pond. Traffic cars have no physics body, so a route that
## crossed a house footprint would still LOOK wrong — none does.
## Fleet grows 6 -> 10 slots (4 east): the old "6 max" cap was a
## low-end safety note, and 4 extra body-less scene instances do
## not change that profile; village loops are untouched.
var east_main_route: Array = [
	Vector2(250, -3), Vector2(445, -3),
	Vector2(445, 3), Vector2(250, 3),
]
var east_north_route: Array = [
	Vector2(340, 0), Vector2(340, -50), Vector2(340, -95),
	Vector2(340, -50), Vector2(340, 0),
]
var east_south_route: Array = [
	Vector2(390, 0), Vector2(390, 40), Vector2(390, 75),
	Vector2(390, 40), Vector2(390, 0),
]

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
## south loop, 6-7 the east main-road loop, 8 the north dirt lane,
## 9 the south dirt lane. Types alternate so routes are mixed:
## north car, van, car; south van, car, van; east main car, van;
## lanes one car each. Order is the slot's position within its own
## route (used for spawn spreading).
var _slot_is_van: Array = [false, true, false, true, false, true, false, true, false, false, false, true]
var _slot_route_idx: Array = [0, 0, 0, 1, 1, 1, 2, 2, 3, 4, 2, 2]
var _slot_order: Array = [0, 1, 2, 0, 1, 2, 0, 1, 0, 0, 2, 3]

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
	var ri: int = _slot_route_idx[slot]
	if ri == 0:
		return north_route
	if ri == 1:
		return south_route
	if ri == 2:
		return east_main_route
	if ri == 3:
		return east_north_route
	return east_south_route

func _scene_for(slot: int) -> PackedScene:
	return _van_scene if _slot_is_van[slot] else _car_scene

func _name_for(slot: int) -> String:
	if _slot_is_van[slot]:
		return "TrafficVan%d" % slot
	return "TrafficCar%d" % slot

## Which slots run at each fleet size. The first slots of each route
## stay on longest: at night only slot 0 (north car), slot 3
## (south van) and slot 6 (east main car) run, so no road network
## goes fully quiet; morning/evening adds slot 1 (north van),
## slot 4 (south car), slot 7 (east main van) and slot 8 (north
## lane); midday runs all twelve (S152: slots 10/11 on the
## east main loop, orders 2/3 — distinct from slots 6/7 orders 0/1,
## so no two east-loop cars share a spawn waypoint).
func _active_slots(count: int) -> Array:
	if count >= 12:
		return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	if count >= 10:
		return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	if count >= 7:
		return [0, 1, 3, 4, 6, 7, 8]
	return [0, 3, 6]

func _daylight() -> float:
	if _day_night == null or not _day_night.has_method("daylight"):
		return 1.0
	return float(_day_night.call("daylight"))

func _fleet_for_day(day: float) -> int:
	if day >= 0.6:
		return 12
	if day >= 0.15:
		return 7
	return 3

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

## Slice 137: is this waypoint blocked for THIS car right now?
## Mirrors traffic_car._blocked exactly (stop radius on any side,
## plus the forward cone toward the next waypoint): a car spawned
## on a blocked waypoint can never move — it sits until the 15 s
## stuck timeout despawns it, and the refill re-picks the same
## point. Audit137 proved it: TrafficVan3 spawned 10/10 times at
## the south corner (14,36) with Villager6 within 4.8 m in 51/51
## samples, speed 0 in every sample, 0 m driven in ~150 s.
func _waypoint_blocked(car: Node3D, route: Array, idx: int, obstacles: Array) -> bool:
	var wp: Vector2 = route[idx] as Vector2
	var nxt: Vector2 = route[(idx + 1) % route.size()] as Vector2
	var fwd: Vector2 = nxt - wp
	var flen: float = fwd.length()
	var half: float = 1.6
	if car.get("half_length") != null:
		half = float(car.get("half_length"))
	var stop_dist: float = half + 2.6
	var cone_dist: float = stop_dist + 3.5
	for ob in obstacles:
		var ob3: Vector3 = ob as Vector3
		var o: Vector2 = Vector2(ob3.x, ob3.z)
		var to_ob: Vector2 = o - wp
		var dist: float = to_ob.length()
		if dist < stop_dist:
			return true
		if dist < cone_dist and flen > 0.001 and dist > 0.001:
			var dir: Vector2 = to_ob / dist
			var fwdn: Vector2 = fwd / flen
			if fwdn.x * dir.x + fwdn.y * dir.y > 0.7:
				return true
	return false

## Slice 137: walk forward along the route from the picked spawn
## waypoint to the first one no live obstacle blocks (villagers,
## player vehicles, the player, other traffic cars — the same set
## drive() stops for). Falls back to the picked waypoint when
## every waypoint is blocked, so a spawn never fails that would
## otherwise succeed. This fixes the spawn defect only: a car that
## spawns clear still stops later if a villager wanders onto its
## path — that is the manager's designed 15 s despawn cycle, and
## the two wander areas overlapping the south loop (Villager6 at
## the (14,36) corner, Villager5 at the bottom leg) are a
## placement matter for the owner, not something this walk hides.
func _first_clear_waypoint(car: Node3D, route: Array, start_idx: int) -> int:
	var obstacles: Array = _collect_obstacles(car)
	for k in range(route.size()):
		var idx: int = (start_idx + k) % route.size()
		if not _waypoint_blocked(car, route, idx, obstacles):
			return idx
	return start_idx

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
	# Slice 137: never spawn on a blocked waypoint (see
	# _first_clear_waypoint). Without this, a refill whose picked
	# waypoint sits under a lingering villager spawns already
	# stuck and re-jams the same point every 15 s forever.
	idx = _first_clear_waypoint(car, route, idx)
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
				# Slice 152: respawn with offset 0, NOT the slot
				# order offset. This branch exists to bring a far
				# car NEAR the player, but best+order can land
				# 195 m away on a 4-point loop — and then the car
				# re-triggers this branch every frame, resetting
				# speed to 0 forever (probe152c: TrafficVan11 sat
				# 13 s at (445,3), speed 0.05, respawning to
				# itself). Offset 0 lands on best (near by
				# definition); _first_clear_waypoint still spreads
				# several respawning cars to adjacent clear
				# waypoints, so no pile-up. _refill_slot keeps
				# the slot-order offset for initial spawns.
				_spawn_car(car_node, route, 0, false)
		car_node.set("speed_factor", _speed_factor)
		car_node.call("set_headlights", dark)
		var obs := _collect_obstacles(car_node)
		car_node.call("drive", delta, obs)
