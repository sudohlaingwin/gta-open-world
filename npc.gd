extends CharacterBody3D
## Slice 6 villager: walks around HIS OWN home area in Myanmar dress,
## and TALKS. Slice 7 touch-first correction (this is a mobile game):
## the PRIMARY paths are tapping this villager directly (see
## _input_event below) or the on-screen Talk button that player.gd
## shows when in range — both call talk_to(). E is only a desktop
## debug fallback. talk_to() faces the player and shows his own
## Burmese greeting in a Label3D bubble for 4 seconds, then walks on.
## Slice 17 obstacle avoidance: villagers steer around the mapped
## obstacle circles below (pagoda, school, tea shop, market, zayat,
## houses, festival, statues, bridge, gate) instead of walking
## through them, and wander targets inside a circle are rejected.
## This is steering around circles, not full pathfinding — stated
## plainly. Wander targets are picked around the villager's spawn
## (home) point, not the world origin.

@export var walk_speed: float = 1.6
@export var wander_radius: float = 12.0
@export var talk_seconds: float = 4.0
@export var dialogue_text: String = "မင်္ဂလာပါ!"
@export var villager_name: String = ""

var home: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
var pause_left: float = 0.0
var talking_left: float = 0.0
## Slice 17 obstacle circles: [x, z, radius] for the structures a
## villager must not walk through. Radii cover the footprint plus
## a small margin; steering adds its own 0.8 clearance.
const OBSTACLES: Array = [
	[-20.0, -25.0, 10.0], [-6.0, -32.0, 2.0], [-34.0, 14.0, 7.0],
	[-14.0, 20.0, 5.0], [18.0, 15.0, 7.0], [28.0, 2.0, 5.0],
	[-8.0, -8.0, 4.0], [10.0, -10.0, 4.0], [-14.0, 10.0, 4.0],
	[-16.0, 14.0, 4.0], [42.0, -33.0, 7.0], [-26.0, -16.0, 2.0],
	[-14.0, -16.0, 2.0], [18.0, 44.0, 4.0], [0.0, 26.0, 3.0],
	# Slice 18: pavilion, elephant stable, second bridge, house 8,
	# stilt house 6, playground.
	[-2.0, 38.0, 4.0], [-44.0, 26.0, 4.0], [-24.0, 44.0, 3.0],
	[36.0, 30.0, 4.0], [-2.0, -40.0, 4.0], [-34.0, 6.0, 3.0],
	# Slice 19: horse pen, lakeside hut, gold stall, bamboo workshop,
	# clay kiln, fishing hut, tea plantation.
	[-38.0, -30.0, 3.0], [44.0, 38.0, 3.0], [29.0, 22.0, 2.0],
	[-20.0, 38.0, 3.0], [45.0, 10.0, 2.0], [39.0, 42.0, 3.0],
	[-44.0, -4.0, 4.0],
]

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
		if villager_name != "":
			label.text = villager_name + "\n" + dialogue_text
		else:
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
		var clear := true
		for ob in OBSTACLES:
			if Vector2(t.x, t.z).distance_to(Vector2(ob[0], ob[1])) <= float(ob[2]) + 1.0:
				clear = false
				break
		if clear:
			target = t
			return
	target = home

## Slice 9 prompt: a "!" floats above this villager while the
## player is in talk range (and not already talking), so a phone
## player can SEE who is talkable without hunting for buttons.
## Guarded: no player node, no prompt — never a crash.
func _update_prompt() -> void:
	var prompt := get_node_or_null("PromptLabel") as Label3D
	if prompt == null:
		return
	if talking_left > 0.0:
		prompt.visible = false
		return
	var player := get_node_or_null("../Player")
	if player == null:
		prompt.visible = false
		return
	prompt.visible = global_position.distance_to(player.global_position) <= 3.5

func _physics_process(delta: float) -> void:
	_update_prompt()
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
	# Slice 17 avoidance: if the next step would enter an obstacle
	# circle, push the step-out point to the circle's edge first,
	# then walk toward that adjusted point instead.
	var nxt := Vector2(global_position.x, global_position.z) + Vector2(dir.x, dir.z) * 0.6
	for ob in OBSTACLES:
		var c := Vector2(ob[0], ob[1])
		var r := float(ob[2]) + 0.8
		var d := nxt.distance_to(c)
		if d < r and d > 0.001:
			nxt = c + (nxt - c).normalized() * r
	var ndir := Vector2(nxt.x - global_position.x, nxt.y - global_position.z)
	if ndir.length() > 0.05:
		dir = Vector3(ndir.x, 0.0, ndir.y).normalized()
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
