extends Node3D
## Slice 120 — performance manager, the PUBG/MLBB way: stop paying
## for what the camera cannot use. Measured BEFORE (S120 probe,
## frame 25 after fast-forward dressing): 13,799 nodes, 12,164
## meshes (11,721 visible ~= draw calls under gl_compatibility),
## 164 omni lights ALL visible at once at night. Two timer-driven
## passes (never per-frame) attack the two costs that scale with
## the world instead of with the screen:
## (1) LIGHT CULLING, night only (DayNight.daylight() < 0.15, the
## same < 0.15 dark rule every other system uses): omni lights
## farther than LIGHT_RADIUS (120 m) from the active camera go
## visible=false; nearer ones are left/returned to visible=true.
## 120 m is generous — a pool's own range is 18-22 m, so a light
## beyond 120 m lights nothing the camera can see, and every
## pool within 120 m stays on, so near-field night coverage
## stays continuous exactly as S102/S103 built it (no gaps
## introduced inside the radius, only far pools switched off).
## At day the manager leaves lights entirely alone (owners
## control them; fighting an owner's day state would be a bug).
## (2) SMALL-DRESSING HIDING, always: grass blades (Blade93_/
## Blade94_/Blade95_/Blade110_) and pond/bank reeds (Reed57_/
## Reed62_/Reed107_/Reed108_) farther than DRESS_RADIUS (100 m)
## from the camera go visible=false and return when near.
## These are sub-pixel at 100 m, so hiding them changes nothing
## the eye can see. NEVER hidden: vehicles, people, bus stops,
## signs, houses, tree trunks/canopies, or anything with a
## collider or a gameplay role — only the listed small meshes.
## NEVER TOUCHED: PlayerLight100_Omni (the player forward foot
## light, realism100) — excluded by exact name. Bus, minibus,
## big bus, tuk-wheel scene file, and bus_sim91 boarding logic
## are untouched; this manager only flips visibility, never
## positions, materials, colliders, or tuning.
## Lists are cached (built once after dressing, frame >= 720)
## and re-scanned every 5.0 s for late nodes (respawns,
## alighting); per-pass work is O(cached), never a tree walk.
## force_pass(center) is the single pass entry so the sim can
## drive it with explicit centres; the timer calls it with the
## live camera centre. Exposed counters (passes_done,
## rescans_done, lights_total, lights_off_now, dress_total,
## dress_hidden_now) let the sim — and later slices — read the
## effect instead of guessing it.
## CULLING NEEDS OWNER COOPERATION (S120 second half): eleven
## night-light owners used to re-assert visible=night EVERY
## frame (night97, realism98/99/100/101/102/103/104,
## city_night56, river_night57, district_night59), which undid
## this manager's culling within one frame — measured live
## (35 visible right after a pass, 158 one frame later). Each
## owner is now gated on night-state CHANGE (first frame always
## runs; after that only on change — same pattern bus_sim82 and
## realism73 already used). Owner controls DAY/NIGHT state,
## this manager controls DISTANCE state; the two compose
## because owners only speak on state change. Any future owner
## that writes light visibility every frame WILL break culling
## again — gate it the same way. Player-light repositioning in
## realism100 stays per-frame (carrier pattern, not a conflict:
## PlayerLight100_Omni is excluded here by exact name).
## DELIBERATELY NOT HERE: fog (deferred — camera far is the
## default 400 m, so depth fog beginning at 800 m would affect
## nothing unless far is raised, and the sunset look cannot be
## verified headless) and MultiMesh instancing (deferred —
## repeated-mesh loops are small and scattered, see COLLAB).

var _frames: int = 0
var _done: bool = false
var _cull_t: float = 0.0
var _rescan_t: float = 0.0
var _lights: Array = []
var _dress: Dictionary = {}
var passes_done: int = 0
var rescans_done: int = 0
var lights_total: int = 0
var lights_off_now: int = 0
var dress_total: int = 0
var dress_hidden_now: int = 0

const LIGHT_RADIUS: float = 120.0
const DRESS_RADIUS: float = 100.0
const DRESS_PREFIXES: Array = ["Blade93_", "Blade94_", "Blade95_", "Blade110_", "Reed57_", "Reed62", "Reed107_", "Reed108_"]
const PLAYER_LIGHT_NAME: String = "PlayerLight100_Omni"


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Perf120") != null:
		return
	var n := Node3D.new()
	n.name = "Perf120"
	n.set_script(load("res://perf120.gd"))
	world.call_deferred("add_child", n)


func _process(delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 720:
		_done = true
		_scan(get_parent() as Node3D)
	if not _done:
		return
	_cull_t += delta
	if _cull_t >= 0.5:
		_cull_t = 0.0
		force_pass(_center())
	_rescan_t += delta
	if _rescan_t >= 5.0:
		_rescan_t = 0.0
		_scan(get_parent() as Node3D)
		rescans_done += 1


func _center() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		return cam.global_position
	var p := get_parent().get_node_or_null("Player")
	if p is Node3D:
		return (p as Node3D).global_position
	return Vector3.ZERO


func _is_night() -> bool:
	var dn := get_parent().get_node_or_null("DayNight")
	if dn == null or not dn.has_method("daylight"):
		return false
	return float(dn.call("daylight")) < 0.15


func force_pass(center: Vector3) -> void:
	passes_done += 1
	var hid := 0
	for mi in _dress.keys():
		if mi == null or not is_instance_valid(mi):
			continue
		var pos: Vector3 = _dress[mi]
		var show := pos.distance_to(center) <= DRESS_RADIUS
		if (mi as MeshInstance3D).visible != show:
			(mi as MeshInstance3D).visible = show
		if not show:
			hid += 1
	dress_hidden_now = hid
	if not _is_night():
		lights_off_now = 0
		return
	var off := 0
	for l in _lights:
		if l == null or not is_instance_valid(l):
			continue
		var om := l as OmniLight3D
		if om.global_position.distance_to(center) > LIGHT_RADIUS:
			if om.visible:
				om.visible = false
			off += 1
		else:
			if not om.visible:
				om.visible = true
	lights_off_now = off


func _scan(world: Node3D) -> void:
	if world == null:
		return
	var st: Array = [world]
	while not st.is_empty():
		var n = st.pop_back()
		for c in n.get_children():
			st.append(c)
		if n is OmniLight3D:
			if String(n.name) != PLAYER_LIGHT_NAME and not n.has_meta("perf120"):
				n.set_meta("perf120", true)
				_lights.append(n)
		elif n is MeshInstance3D:
			var nm := String(n.name)
			for p in DRESS_PREFIXES:
				if nm.begins_with(p):
					_dress[n] = (n as MeshInstance3D).global_position
					if not n.has_meta("perf120"):
						n.set_meta("perf120", true)
					break
	lights_total = _lights.size()
	dress_total = _dress.size()
