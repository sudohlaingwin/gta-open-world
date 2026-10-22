extends Node

@export var traffic_car_scene: PackedScene = preload("res://scenes/traffic_car.tscn")
@export var traffic_van_scene: PackedScene = preload("res://scenes/traffic_van.tscn")

var north_loop: Array[Vector3] = [
	Vector3(0, 0, 32), Vector3(0, 0, 15), Vector3(0, 0, -5),
	Vector3(12, 0, -5), Vector3(12, 0, 15), Vector3(12, 0, 32)
]

var south_loop: Array[Vector3] = [
	Vector3(-12, 0, 5), Vector3(-12, 0, -15), Vector3(-24, 0, -15),
	Vector3(-24, 0, 5)
]

func _ready() -> void:
	_spawn_fleet()

func _spawn_fleet() -> void:
	if not traffic_car_scene or not traffic_van_scene:
		return

	# North Loop: Car 1, Van 1, Car 2
	var n_car1 = traffic_car_scene.instantiate()
	n_car1.waypoints = north_loop
	n_car1.current_wp_idx = 0
	n_car1.position = north_loop[0]
	add_child(n_car1)

	var n_van = traffic_van_scene.instantiate()
	n_van.waypoints = north_loop
	n_van.current_wp_idx = 2
	n_van.position = north_loop[2]
	add_child(n_van)

	var n_car2 = traffic_car_scene.instantiate()
	n_car2.waypoints = north_loop
	n_car2.current_wp_idx = 4
	n_car2.position = north_loop[4]
	add_child(n_car2)

	# South Loop: Van 2, Car 3, Van 3
	var s_van1 = traffic_van_scene.instantiate()
	s_van1.waypoints = south_loop
	s_van1.current_wp_idx = 0
	s_van1.position = south_loop[0]
	add_child(s_van1)

	var s_car = traffic_car_scene.instantiate()
	s_car.waypoints = south_loop
	s_car.current_wp_idx = 1
	s_car.position = south_loop[1]
	add_child(s_car)

	var s_van2 = traffic_van_scene.instantiate()
	s_van2.waypoints = south_loop
	s_van2.current_wp_idx = 3
	s_van2.position = south_loop[3]
	add_child(s_van2)