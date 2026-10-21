extends CharacterBody3D
## Slice 6 villager: walks around HIS OWN home area in Myanmar dress,
## and TALKS. Slice 7 touch-first correction (this is a mobile game):
## the PRIMARY paths are tapping this villager directly (see
## _input_event below) or the on-screen Talk button that player.gd
## shows when in range — both call talk_to(). E is only a desktop
## debug fallback. talk_to() faces the player and shows his own
## Burmese greeting in a Label3D bubble for 4 seconds, then walks on.
## No quests, no obstacle avoidance yet — stated plainly in
## README.md. Wander targets are picked around the villager's spawn
## (home) point, not the world origin, and stay clear of the pagoda
## platform at (-20, -25).

@export var walk_speed: float = 1.6
@export var wander_radius: float = 12.0
@export var talk_seconds: float = 4.0
@export var dialogue_text: String = "မင်္ဂလာပါ!"

var home: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
var pause_left: float = 0.0
var talking_left: float = 0.0

func _ready() -> void:
	home = global_position
	_hide_label()
	_pick_target()

func _hide_label() -> void:
	var label := get_node_or_null("DialogueLabel") as Label3D
	if label != null:
		label.visible = false

## Called by the Talk button, by direct tap, or (desktop fallback)
## by E near this villager. Slice 9: talking also counts toward
## the player's first quest (record_talk), whichever path started it.
func talk_to(player_pos: Vector3) -> void:
	var to_player := player_pos - global_position
	to_player.y = 0.0
	if to_player.length() > 0.01:
		rotation.y = atan2(to_player.x, to_player.z)
	talking_left = talk_seconds
	var label := get_node_or_null("DialogueLabel") as Label3D
	if label != null:
		label.text = dialogue_text
		label.visible = true
	var player := get_node_or_null("../Player")
	if player != null and player.has_method("record_talk"):
		player.call("record_talk", self)

func _pick_target() -> void:
	for _i in range(8):
		var t := Vector3(
			home.x + randf_range(-wander_radius, wander_radius),
			0.0,
			home.z + randf_range(-wander_radius, wander_radius))
		if Vector2(t.x, t.z).distance_to(Vector2(-20.0, -25.0)) > 13.0:
			target = t
			return
	target = home

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	if talking_left > 0.0:
		talking_left -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if talking_left <= 0.0:
			_hide_label()
		move_and_slide()
		return
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

## Slice 7 direct tap: tapping this villager on a touch screen (or
## clicking on desktop, where mouse input is emulated as touch)
## talks to the player, with no keyboard involved. Works because
## this CharacterBody3D has a CollisionShape3D child and
## input_ray_pickable defaults to true.
func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	var tapped := false
	if event is InputEventScreenTouch and event.pressed:
		tapped = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	if not tapped:
		return
	var player := get_node_or_null("../Player")
	if player != null:
		talk_to(player.global_position)
