extends Camera3D
## Slice 1 camera: angled follow view. It follows the player from
## above-behind without spinning when the player turns.

@export var target: NodePath
@export var offset: Vector3 = Vector3(0.0, 10.0, 10.0)

func _process(_delta: float) -> void:
	var t := get_node_or_null(target)
	if t == null:
		return
	global_position = t.global_position + offset
	look_at(t.global_position, Vector3.UP)
