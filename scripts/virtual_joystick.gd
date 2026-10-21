extends Control

# Virtual Touch Joystick for Mobile Open World Controls
var touch_start: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var joystick_radius: float = 64.0
var output_vector: Vector2 = Vector2.ZERO

@onready var base: Control = $Base
@onready var handle: Control = $Base/Handle

signal joystick_moved(vector: Vector2)
signal joystick_released()

func _ready() -> void:
	visible = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			touch_start = event.position
			base.global_position = event.position - base.size / 2.0
			handle.position = base.size / 2.0 - handle.size / 2.0
		else:
			is_dragging = false
			output_vector = Vector2.ZERO
			handle.position = base.size / 2.0 - handle.size / 2.0
			joystick_released.emit()
			joystick_moved.emit(Vector2.ZERO)

	elif event is InputEventScreenDrag and is_dragging:
		var diff = event.position - touch_start
		if diff.length() > joystick_radius:
			diff = diff.normalized() * joystick_radius
		
		handle.position = (base.size / 2.0 - handle.size / 2.0) + diff
		output_vector = diff / joystick_radius
		joystick_moved.emit(output_vector)
