extends Node3D
## Slice 132: people life audit round (owner goal OpenTaxi
## Thadingyut Night level, look only, never copy). Runtime
## dressing only, no scene touched, no new meshes, no new
## colliders, no new omnis.
##
## AUDIT RESULTS (audit132 + probe132, live headless):
## 1) FACING PROVEN FORWARD, NO FIX NEEDED. S121 assumed the
##    GLB models face local +z. Proven two ways: (a) geometry —
##    every model carries face features (white 180 + dark 180 +
##    lips 24 verts) at z +0.09..+0.12, x centred 0, at head
##    height, and NOTHING facial on the -z side, in all four
##    files; (b) live — every moving walker measured median
##    velocity-vs-fig-forward dot = 1.0 (min 0.86, turn
##    transients only). Fig forward = movement dir (npc.gd)
##    and model faces fig +z, so models walk forward.
## 2) STUCK VILLAGERS (REAL DEFECT, FIXED IN npc.gd, NOT
##    HERE): grid-sampled audit (25x25 per centre) proves
##    STRICT-STUCK (clear fraction 0.000) for Villager4 home,
##    Villager7/8/14/17 day anchors, and Villager9/10 home
##    AND anchor — plus MOSTLY-STUCK (P(all 8 picks
##    rejected) 0.57-0.99) for Villager4/5/16 day anchors
##    and Villager18 home. 10 of 18 villagers frozen or
##    mostly-frozen in at least one band. The old
##    target = wander_center fallback pause-looped them
##    forever; npc.gd now widens the ring (2x/3x/5x)
##    before falling back. Normal villagers never reach
##    that code, so their behaviour is unchanged.
## 3) IDLE STATUES (FIXED HERE): all 18 waiting figures
##    measured EXACTLY 0 transform change over 3 s, and
##    walkers freeze during pauses (1-3 s) and talks (4 s) —
##    realism121 only bobs walkers while moving and gives
##    stops no motion code at all. This script adds a
##    gentle weight-shift sway (rotation.z, 0.02 rad, 0.5 Hz,
##    per-figure phase) to still figures: stops always, and
##    walkers whenever they have been still for 0.25 s.
##    Deliberately subtle and slow — the owner condemned
##    doll-wobble, so this is a living signal, not a dance.
##    It touches ONLY rotation.z; realism121 owns position.y
##    and rotation.x (bob + lean), so the two never fight.
## 4) VARIETY: NO GAP. Live mesh-AABB classes match the
##    hash prediction exactly: youth 12, elder 7, fighter
##    10, child 7 across 36 figures (walkers youth 4 /
##    elder 5 / fighter 5 / child 4; stops youth 8 / elder
##    2 / fighter 5 / child 3). No cluster fix shipped.
## 5) SEATED: NO FAKE POSE. bus_sim91 moves the whole
##    figure node to the seat origin while _set_seated_pose
##    moves only the HIDDEN Body74/Head74 parts, so the
##    visible S121 model stands at the seat origin — seated
##    reads as standing, exactly S121's flag. A single
##    unrigged mesh cannot bend into a seat; true sitting
##    needs owner-supplied seated models, so this is an
##    OWNER DECISION, not a code fix. Sway still applies
##    to seated models (subtle, same as standing).
## 6) FIGHTER GEOMETRY (OWNER PHONE CHECK, STILL OPEN):
##    the fighter mesh carries a long thin brown column
##    (200 + 50 verts, x ~-0.26, z ~+0.18, y 0.00..1.38)
##    at its left side plus a small red side object
##    (24 verts, x ~+0.23, y 0.74..0.86). Square-ish
##    0.04 cross-section reads staff/pole-like, not
##    blade-like, but whether the owner reads it as a
##    weapon is HIS verdict — this slice does NOT claim
##    weapon-free and does NOT remove his model.
## PERFORMANCE: per-frame work is O(figures) over a
## cached list (no tree walks); re-sync every 1 s reads
## Realism121's own _walkers/_stops arrays only. Sway
## adds ZERO nodes and ZERO meshes. Names: no new
## nodes except this Realism132 holder.
## NOT touched: bus/minibus/big bus (Slice 81), S119 menu,
## S121 models, S124/S127 night, S125 beacons/ox/
## smooth-look, S126 plane re-face, S128 hut grounding +
## ground, S129 clouds + bunting, S130 water + banks,
## S131 pagoda glow + festival; no .tscn edits.

const FRAME_GATE: int = 770
const SWAY_AMP: float = 0.02
const SWAY_FREQ: float = 0.5
const SWAY_EASE: float = 4.0
const STILL_WINDOW: float = 0.25
const STILL_DIST: float = 0.05

var _frames: int = 0
var _done: bool = false
var _scan_t: float = 0.0
var _time: float = 0.0
var _entries: Array = []
var _by_fig: Dictionary = {}

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism132") != null:
		return
	var n := Node3D.new()
	n.name = "Realism132"
	n.set_script(load("res://realism132.gd"))
	world.call_deferred("add_child", n)

func _process(delta: float) -> void:
	_frames += 1
	_time += delta
	_scan_t += delta
	if _scan_t >= 1.0:
		_scan_t = 0.0
		_sync()
	if not _done and _frames >= FRAME_GATE and _entries.size() >= 36:
		_done = true
	_sway(delta)

func _add(fig: Node3D, model: Node3D, is_stop: bool) -> void:
	var key: int = fig.get_instance_id()
	if _by_fig.has(key):
		return
	var phase: float = float(absi(String(fig.name).hash()) % 1000) / 1000.0 * TAU
	_by_fig[key] = true
	_entries.append({
		"key": key, "fig": fig, "model": model, "is_stop": is_stop,
		"phase": phase, "factor": 0.0, "was_moving": false,
		"last_pos": fig.global_position, "last_t": _time,
	})

func _sync() -> void:
	var world: Node = get_parent()
	if world == null:
		return
	var r121: Node = world.get_node_or_null("Realism121")
	if r121 == null:
		return
	var walkers: Array = r121.get("_walkers") as Array
	for w in walkers:
		var fig: Node3D = w["fig"] as Node3D
		var model: Node3D = w["model"] as Node3D
		if fig != null and is_instance_valid(fig) and model != null and is_instance_valid(model):
			_add(fig, model, false)
	var stops: Array = r121.get("_stops") as Array
	for s in stops:
		var fig2: Node3D = s as Node3D
		if fig2 == null or not is_instance_valid(fig2):
			continue
		var model2: Node3D = fig2.get_node_or_null("Model121")
		if model2 != null:
			_add(fig2, model2, true)
	var dead: Array = []
	for e in _entries:
		var f: Node3D = e["fig"] as Node3D
		var m: Node3D = e["model"] as Node3D
		if f == null or not is_instance_valid(f) or m == null or not is_instance_valid(m):
			dead.append(e)
	for d in dead:
		_by_fig.erase(int(d["key"]))
		_entries.erase(d)

func _sway(delta: float) -> void:
	for e in _entries:
		var fig: Node3D = e["fig"] as Node3D
		var model: Node3D = e["model"] as Node3D
		if fig == null or not is_instance_valid(fig) or model == null or not is_instance_valid(model):
			continue
		var target_f: float = 1.0
		if not bool(e["is_stop"]):
			if _time - float(e["last_t"]) >= STILL_WINDOW:
				var cur: Vector3 = fig.global_position
				var prev: Vector3 = e["last_pos"]
				var moved: float = Vector2(cur.x - prev.x, cur.z - prev.z).length()
				e["last_pos"] = cur
				e["last_t"] = _time
				e["was_moving"] = moved >= STILL_DIST
			if bool(e["was_moving"]):
				target_f = 0.0
		var f: float = lerpf(float(e["factor"]), target_f, minf(1.0, delta * SWAY_EASE))
		e["factor"] = f
		model.rotation.z = sin(_time * TAU * SWAY_FREQ + float(e["phase"])) * SWAY_AMP * f
