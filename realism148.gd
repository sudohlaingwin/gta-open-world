extends Node3D

## Slice 148 — figures-grounding round (audit-first, live-probed
## before shipping). Audit148 mapped the figure hierarchies and
## proved the S121-deferred "sinking" is ONE root cause, not a
## per-figure placement bug: Godot 4.3 CapsuleShape3D `height` is
## the TOTAL height, so the physics half-extent is height/2 =
## 0.60 m — NOT height/2 + radius = 1.00 m as realism121 assumed
## (Godot 3 semantics). Proof: (1) live figures rest at origin
## y = 0.600x on physics ground top y = 0.0 with the shape at
## local (0,0,0) and no scale — only half-extent 0.60 is
## consistent; (2) a minimal captest scene (fresh CharacterBody3D
## + CapsuleShape3D(1.2, 0.4) falling onto a box top at y = 0)
## rests at y = 0.60029, on_floor = true. S147's raycast
## (capsule top at origin + 0.60) already implied this; captest
## proves the engine reason. Physics was CORRECT all along:
## capsule bottoms sit exactly on the visual floor. Only the
## VISUAL figures were authored 0.40 m low (feet at local
## -1.00, the old wrong half-extent, instead of -0.60).
## FIX, two parts, consistent for ALL figures (never a
## player-only lift): (a) realism121's walker base formula is
## corrected from -(height/2 + radius) + 0.04 to -(height/2) +
## 0.04 = -0.56 for the standard capsule, so GLB feet land at
## 0.60 - 0.56 - 0.04 = 0.00 exactly; labels rise with the model
## (they were 0.40 low too) and bob runs from the corrected base
## (feet 0.00..+0.04, never below floor). Bus-stop figures
## (base +0.04, origins at ground) were already grounded and
## are untouched. (b) THIS script lifts the PLAYER's visual
## figure: every top-level visual child (direct MeshInstance3D
## children + pivot Node3Ds whose subtrees hold meshes — arms,
## legs, longyi, sandals move WITH their pivots, never meshes
## alone, so WalkAnim58 rotation-only swing is untouched) by
## a LIFT measured live from the lowest visible mesh
## (LIFT = -cap_half - local_min, expected 0.43: soles at
## local -1.03 rise to exactly 0.00, hems at +0.02..+0.03).
## The collider, the body origin, and all physics are untouched.
## ORDERING: runs at frame >= 830, BEFORE Realism147's 850 hat
## seating, and re-seats the hat itself from the LIVE lifted head
## (same guard as 147: only when gap > 0.05), so the hat ends
## seated even if frame-gate skew ever reordered the two passes;
## 147 later finds gap 0 and no-ops. Visibility NEVER touched
## (outfit hat toggle keeps working). Zero new meshes, zero
## colliders, zero per-frame work after _apply. Idempotent via
## the lifted148 meta (re-apply cannot double-lift).
## NOT touched: S137 anchor/airplane decisions (owner
## decisions); S147 hat logic itself (only its input moved);
## rider/driver figures (parented to vehicles, feet never touch
## ground — out of scope); S146 season tint; no .tscn edits;
## no economy/combat/map changes.

var _frames: int = 0
var _done: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism148") != null:
		return
	var n := Node3D.new()
	n.name = "Realism148"
	n.set_script(load("res://realism148.gd"))
	world.call_deferred("add_child", n)


func _subtree_has_mesh(root: Node) -> bool:
	var stack: Array = [root]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D:
			return true
		for c in x.get_children():
			stack.append(c)
	return false


func _apply(world: Node3D) -> void:
	if world == null:
		return
	var player: Node = world.get_node_or_null("Player")
	if player == null:
		_done = true
		return
	var p3: Node3D = player as Node3D
	if p3.has_meta("lifted148"):
		_done = true
		return
	# True floor in player-local coords = -capsule half-extent,
	# where half-extent = height/2 in Godot 4.3 (captest-proven).
	var cap_half: float = 0.60
	var col: CollisionShape3D = p3.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null and col.shape is CapsuleShape3D:
		cap_half = (col.shape as CapsuleShape3D).height / 2.0
	# Lowest visible mesh in player-local coords.
	var local_min: float = 1e9
	var oy: float = p3.global_position.y
	var stack: Array = [p3]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D:
			var mi: MeshInstance3D = x as MeshInstance3D
			if bool(mi.visible) and bool(mi.is_visible_in_tree()):
				var ga: AABB = mi.global_transform * mi.get_aabb()
				local_min = minf(local_min, ga.position.y - oy)
		for c in x.get_children():
			stack.append(c)
	if local_min > 1e8:
		_done = true
		return
	var lift: float = -cap_half - local_min
	if lift < 0.05 or lift > 0.80:
		_done = true
		return
	# Lift top-level visual children ONCE each (pivots carry
	# their subtrees; nested meshes are never lifted separately).
	for c in p3.get_children():
		if c is CollisionShape3D:
			continue
		if String(c.name).contains("Light"):
			continue
		if not (c is Node3D):
			continue
		var c3: Node3D = c as Node3D
		if c3 is MeshInstance3D:
			c3.position.y += lift
		elif _subtree_has_mesh(c3):
			c3.position.y += lift
	# Re-seat the hat on the LIVE lifted head (147's formula).
	var head: MeshInstance3D = p3.get_node_or_null("Head") as MeshInstance3D
	var hat: MeshInstance3D = p3.get_node_or_null("PlayerHat") as MeshInstance3D
	if head != null and hat != null:
		var hr: float = 0.2
		var hm: Mesh = head.mesh
		if hm is SphereMesh:
			hr = (hm as SphereMesh).radius
		var hh: float = 0.28
		var hatm: Mesh = hat.mesh
		if hatm is CylinderMesh:
			hh = (hatm as CylinderMesh).height
		var head_top: float = head.position.y + hr
		var hat_bottom: float = hat.position.y - hh * 0.5
		if hat_bottom - head_top > 0.05:
			hat.position.y = head_top + hh * 0.5
	p3.set_meta("lifted148", true)
	_done = true


func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 830:
		_apply(get_parent() as Node3D)
