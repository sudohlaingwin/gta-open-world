extends Node

@export var traffic_car_scene: PackedScene = preload("res://scenes/traffic_car.tscn")

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
	if not traffic_car_scene:
		return

	# North Loop Car 1
	var car1 = traffic_car_scene.instantiate()
	car1.waypoints = north_loop
	car1.current_wp_idx = 0
	car1.position = north_loop[0]
	add_child(car1)

	# North Loop Car 2 (offset)
	var car2 = traffic_car_scene.instantiate()
	car2.waypoints = north_loop
	car2.current_wp_idx = 3
	car2.position = north_loop[3]
	add_child(car2)

	# South Loop Car 1
	var car3 = traffic_car_scene.instantiate()
	car3.waypoints = south_loop
	car3.current_wp_idx = 0
	car3.position = south_loop[0]
	add_child(car3)

	# South Loop Car 2 (offset)
	var car4 = traffic_car_scene.instantiate()
	car4.waypoints = south_loop
	car4.current_wp_idx = 2
	car4.position = south_loop[2]
	add_child(car4)