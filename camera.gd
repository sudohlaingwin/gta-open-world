extends Camera3D
## Slice 2 camera: angled follow + orbit.
## Q/E rotate the view around the player (keyboard orbit, works
## without touch — the opponent's orbit is touch-drag only).
## Touch-drag orbit is a later slice; this is stated, not claimed.
## Camera collision avoidance (direction-independent, serves the
## village world and any future city district): the follow camera
## must not pass through walls or buildings. Each frame a raycast
## runs from the player's eye point to the camera's desired
## position; when a wall or building blocks the ray, the camera
## shortens toward the player instead of clipping through it, and
## when the obstruction clears it glides back out smoothly.
## Touch-first: orbit (touch-drag), zoom buttons, and the camera
## reset button are unchanged; Q/E remain desktop fallbacks only.

@export var target: NodePath
@export var orbit_angle: float = 0.0
# Slice 10 camera controls (touch-first): zoom factor for the
# Zoom + / - buttons, and touch-drag orbit on the right half of
# the screen (the joystick lives on the left, so the halves do not
# fight). Q/E remain desktop fallbacks only.
var zoom: float = 1.0

# Collision-avoidance tuning. EYE_HEIGHT puts the ray origin at
# the player's head instead of their feet, so low walls the player
# stands behind still shorten the camera. MIN_DIST keeps the
# camera close but outside the player's own body in narrow
# spaces. BLOCK_MARGIN stops the camera short of the wall face so
# it never rests inside geometry. Shortening is fast (a wall must
# never be crossed for even a frame); recovery is slow on purpose
# so the camera glides back out instead of snapping.
const EYE_HEIGHT: float = 1.6
const MIN_DIST: float = 1.2
const BLOCK_MARGIN: float = 0.4
const SHORTEN_RATE: float = 14.0
const RECOVER_RATE: float = 2.5
# Smoothed camera distance. -1 means "not started yet" and snaps
# to the desired distance on the first frame only.
var cur_dist: float = -1.0

func zoom_in() -> void:
	zoom = clamp(zoom - 0.2, 0.6, 1.8)

func zoom_out() -> void:
	zoom = clamp(zoom + 0.2, 0.6, 1.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var vp := get_viewport().get_visible_rect().size
		if event.position.x > vp.x * 0.5:
			orbit_angle += event.relative.x * 0.005

# Physics bodies the camera ray must ignore. Everything on the
# default layer that is NOT a StaticBody3D is a character, a
# vehicle, or an animal: the player, ridden vehicles, villagers,
# and rideable animals. They must never shorten the camera (a
# villager walking behind the player would otherwise yank the
# view). StaticBody3D nodes — pagoda, bridges, stalls, ground,
# and the camera-blocker volumes added for collision-less houses
# — are exactly what the ray is meant to hit, so they are kept.
# Traffic cars are Node3D with no physics body, so they cannot
# block the ray; that is a stated limit, not a bug.
func _excluded_rids() -> Array[RID]:
	var out: Array[RID] = []
	var parent := get_parent()
	if parent == null:
		return out
	for child in parent.get_children():
		if child is CollisionObject3D and not (child is StaticBody3D):
			out.append(child.get_rid())
	return out

# Shortest distance the camera may sit at along its current orbit
# direction without crossing a wall. Casts both ways along the
# segment: eye-to-camera catches a wall between player and
# camera, and camera-to-eye catches the case where the player is
# standing inside a building footprint (a ray starting inside a
# shape reports no hit, so the reverse ray is what keeps the
# camera outside the wall in that case). Returns the desired
# distance when nothing blocks the segment.
func _blocked_distance(eye: Vector3, desired_pos: Vector3, desired: float) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return desired
	var excluded := _excluded_rids()
	var allowed := desired
	for pair in [[eye, desired_pos], [desired_pos, eye]]:
		var query := PhysicsRayQueryParameters3D.create(pair[0], pair[1])
		query.collision_mask = 3
		query.exclude = excluded
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			var hit_dist := (hit["position"] as Vector3 - eye).length()
			allowed = min(allowed, clamp(hit_dist - BLOCK_MARGIN, MIN_DIST, desired))
	return allowed

func _process(delta: float) -> void:
	var t := get_node_or_null(target)
	if t == null:
		return
	if Input.is_physical_key_pressed(KEY_Q):
		orbit_angle += 0.02
	if Input.is_physical_key_pressed(KEY_E):
		orbit_angle -= 0.02
	var desired := 10.0 * zoom
	if cur_dist < 0.0:
		cur_dist = desired
	var dir_h := Vector3(sin(orbit_angle), 0.0, cos(orbit_angle))
	var eye: Vector3 = t.global_position + Vector3(0.0, EYE_HEIGHT, 0.0)
	var desired_pos: Vector3 = t.global_position + Vector3(dir_h.x * desired, 10.0 * zoom, dir_h.z * desired)
	var allowed := _blocked_distance(eye, desired_pos, desired)
	if allowed < cur_dist:
		cur_dist = max(allowed, cur_dist - SHORTEN_RATE * delta)
	else:
		cur_dist = min(allowed, cur_dist + RECOVER_RATE * delta)
	var f := cur_dist / desired if desired > 0.0 else 1.0
	var pos: Vector3 = t.global_position + Vector3(dir_h.x * cur_dist, 10.0 * zoom * f, dir_h.z * cur_dist)
	if pos.y < t.global_position.y + 0.5:
		pos.y = t.global_position.y + 0.5
	global_position = pos
	look_at(t.global_position, Vector3.UP)
