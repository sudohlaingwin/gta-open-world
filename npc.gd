extends CharacterBody3D
## Slice 5 villager: walks around the village in Myanmar dress.
## No dialogue, no quests, no obstacle avoidance yet — stated
## plainly in README.md. Picks a random point, walks to it, pauses,
## repeats. Stays clear of the pagoda platform at (-20, -25).

@export var walk_speed: float = 1.6
@export var bound: float = 30.0

var target: Vector3 = Vector3.ZERO
var pause_left: float = 0.0

func _ready() -> void:
	_pick_target()

func _pick_target() -> void:
	for _i in range(8):
		var t := Vector3(randf_range(-bound, bound), 0.0, randf_range(-bound, bound))
		if Vector2(t.x, t.z).distance_to(Vector2(-20.0, -25.0)) > 13.0:
			target = t
			return
	target = Vector3(0.0, 0.0, 0.0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	if pause_left > 0.0:
		pause_left -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var to := target - global_position
	to.y = 0.0
	if to.length() < 1.0:
		pause_left = randf_range(1.0, 3.0)
		_pick_target()
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var dir := to.normalized()
	rotation.y = atan2(dir.x, dir.z)
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed
	move_and_slide()
