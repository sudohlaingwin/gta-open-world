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
## Milestone 6 (part 2): first daily schedule. day_anchor is the
## daytime gathering place (Vector3.ZERO = no schedule: this villager
## always wanders around home). With a day_anchor set, the villager
## wanders around day_anchor while it is day and around home at
## night. The shift is a WALK, never a teleport: only the wander
## centre changes, and the next picked target is around the new
## centre, so the villager walks there through the normal avoidance
## steering. A villager mid-conversation is NEVER yanked away: if
## the day/night band changes while talking_left > 0, the shift is
## deferred (_schedule_pending) and applied when the talk ends.
## wander_center is the live centre; home never changes.
@export var day_anchor: Vector3 = Vector3.ZERO
var wander_center: Vector3 = Vector3.ZERO
var _schedule_is_day: bool = true
var _schedule_pending: bool = false
var _schedule_timer: float = 0.0
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
	# Slice 20: night market, guest house, pier, horse pen 2, boat2.
	[-36.0, 32.0, 5.0], [26.0, 36.0, 4.0], [46.0, 44.0, 3.0],
	[-28.0, -38.0, 3.0], [30.0, 44.0, 2.0],
	[-38.0, -30.0, 3.0], [44.0, 38.0, 3.0], [29.0, 22.0, 2.0],
	[-20.0, 38.0, 3.0], [45.0, 10.0, 2.0], [39.0, 42.0, 3.0],
	[-44.0, -4.0, 4.0],
	# Slice 152: east settlement (6) + Mindon-south infill targets (3).
	[3180.0, -20.0, 5.0], [3220.0, -20.0, 5.0], [3260.0, -20.0, 5.0],
	[3200.0, 20.0, 5.0], [3240.0, 20.0, 5.0], [3280.0, 20.0, 5.0],
	[170.0, 140.0, 5.0], [220.0, 150.0, 5.0], [150.0, 180.0, 5.0],
]

func _ready() -> void:
	home = global_position
	wander_center = home
	_hide_label()
	_pick_target()

## Day band from the shared day/night cycle: day while daylight is
## at least 0.15, night below it (the same < 0.15 dark rule the
## moon, stars, fireflies, and traffic headlights use). No DayNight
## node or no daylight() method: no schedule changes, ever.
func _daylight_is_day() -> bool:
	var dn := get_node_or_null("../DayNight")
	if dn == null or not dn.has_method("daylight"):
		return _schedule_is_day
	return float(dn.call("daylight")) >= 0.15

## Applies a day/night band change as a walk, not a teleport: only
## wander_center moves, and _pick_target sends the villager walking
## toward the new area. Called once a second from _physics_process,
## and immediately (forced) when a deferred shift's talk ends.
func _update_schedule(force: bool) -> void:
	if day_anchor == Vector3.ZERO:
		return
	var is_day := _daylight_is_day()
	if is_day == _schedule_is_day and not force:
		return
	if talking_left > 0.0 and not force:
		# Mid-conversation: defer, do not yank the villager away.
		_schedule_pending = true
		return
	_schedule_is_day = is_day
	_schedule_pending = false
	wander_center = day_anchor if is_day else home
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

func _point_clear(x: float, z: float) -> bool:
	for ob in OBSTACLES:
		if Vector2(x, z).distance_to(Vector2(ob[0], ob[1])) <= float(ob[2]) + 1.0:
			return false
	return true

func _pick_target() -> void:
	for _i in range(8):
		var t := Vector3(
			wander_center.x + randf_range(-wander_radius, wander_radius),
			0.0,
			wander_center.z + randf_range(-wander_radius, wander_radius))
		if _point_clear(t.x, t.z):
			target = t
			return
	# Slice 132: the old fallback was target = wander_center, which
	# permanently stuck any villager whose home/anchor sits deep
	# inside an obstacle circle (grid-sampled audit, 25x25 per
	# centre: STRICT-STUCK clear fraction 0.000 — Villager4
	# home, Villager7/8/14/17 day anchors, Villager9/10 home
	# AND anchor; MOSTLY-STUCK — Villager4/5/16 day anchors
	# and Villager18 home, P(all 8 picks rejected) 0.57-0.99):
	# every pick in the normal ring is rejected, so the
	# target equals the centre, the arrival check fires at
	# once, and the villager re-picks forever without ever
	# moving in that band. Widen the ring instead: a
	# villager that wanders a little farther from home is
	# alive; a frozen one is a statue. Normal villagers
	# never reach this code (their first-ring picks
	# succeed), so their behaviour is unchanged.
	for mult in [2.0, 3.0, 5.0]:
		var r: float = wander_radius * mult
		for _j in range(16):
			var t2 := Vector3(
				wander_center.x + randf_range(-r, r),
				0.0,
				wander_center.z + randf_range(-r, r))
			if _point_clear(t2.x, t2.z):
				target = t2
				return
	target = wander_center

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
	# Milestone 6 (part 2): schedule check once a second, not every
	# frame — the day/night band changes twice per 120 s day, so a
	# 1 s cadence is plenty and costs nothing.
	_schedule_timer += delta
	if _schedule_timer >= 1.0:
		_schedule_timer = 0.0
		_update_schedule(false)
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
			if _schedule_pending:
				# Talk over: apply the deferred day/night shift now.
				_update_schedule(true)
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
