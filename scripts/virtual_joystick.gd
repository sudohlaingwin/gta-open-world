extends Control

# --- High-Quality Circular Touch Joystick with Analog Deadzone & Visual Feedback ---

var touch_start: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var joystick_radius: float = 80.0
var deadzone: float = 0.15
var output_vector: Vector2 = Vector2.ZERO

@onready var base: Panel = $Base
@onready var handle: Panel = $Base/Handle
@onready var direction_indicator: Control = $Base/Indicator

signal joystick_moved(vector: Vector2)
signal joystick_released()

func _ready() -> void:
	visible = true
	_update_handle_position(Vector2.ZERO)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			touch_start = event.position
			base.global_position = event.position - base.size / 2.0
			_update_handle_position(Vector2.ZERO)
		else:
			is_dragging = false
			output_vector = Vector2.ZERO
			_update_handle_position(Vector2.ZERO)
			joystick_released.emit()
			joystick_moved.emit(Vector2.ZERO)

	elif event is InputEventScreenDrag and is_dragging:
		var diff = event.position - touch_start
		var dist = diff.length()
		
		if dist > joystick_radius:
			diff = diff.normalized() * joystick_radius
		
		_update_handle_position(diff)
		
		# Analog Deadzone calculation
		var normalized_dist = dist / joystick_radius
		if normalized_dist < deadzone:
			output_vector = Vector2.ZERO
		else:
			var scaled_dist = (normalized_dist - deadzone) / (1.0 - deadzone)
			output_vector = diff.normalized() * scaled_dist
			
		joystick_moved.emit(output_vector)

func _update_handle_position(offset: Vector2) -> void:
	if handle and base:
		handle.position = (base.size / 2.0 - handle.size / 2.0) + offset
