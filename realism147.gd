extends Node3D

## Slice 147 — player figure audit round (audit-first, live-probed
## before shipping). Audit147/147b/147c measured the PLAYER on the
## LIVE tree (never the scene file alone, S144 lesson) and found the
## figure is NOT the crude procedural body the brief assumed: 86
## meshes, 76 visible — S70 neck, S73 eyes/sleeves/longyi stripes,
## S93 fingers, S94 face (eyes/nose/mouth/brows/ears) + arms +
## longyi folds/bands + FRONT KNOT, S95 buttons/placket/straps,
## S96 torso cylinders, S98 apron, S99 waist, S111 longyi band.
## Scene Torso/Arm boxes are hidden (replaced); walk swing is full
## amplitude (shoulder +-0.32 rad, speed 0.83..5.0); clean idle is
## breathing +-0.025 rad (audit147's 0.296 max was decay from the
## walk phase, re-probed clean); night read is good (76/76 visible,
## PlayerLight100_Omni on, 1.7 m from player, omni12 = 3); TPP
## camera is exactly 6.0 m at pitch 0.38. Face features are absent
## from the FRONT of the plain head sphere, but the face is on +z
## (invisible from the TPP behind-view) and sub-0.1 m face details
## fail the 6 m gate (same reasoning as S143's flower) — NOT shipped.
## THE ONE PLAYER-SPECIFIC DEFECT, shipped here: the straw hat
## FLOATS. PlayerHat (scene cylinder, h 0.28, straw) sits at local
## y 1.55 while the live head top is local 0.90 (Head moved to 0.70
## by head dressing, sphere r 0.20) — a 0.51 m gap, hat visible by
## default (SaveManager hat_visible defaults true, outfit toggle),
## dead centre of the TPP view every second of play. Villager hats
## at the same 1.55 are hidden by realism121 (S143) and their GLBs
## carry their own hats; the player has no GLB, so his scene hat
## is his ONLY hat — and it floats.
## FIX (this file, runtime dressing only, zero .tscn edits): seat
## PlayerHat on the live head top — hat bottom = head top, computed
## from LIVE Head position + sphere radius and LIVE hat cylinder
## height, never hard-coded heights that could drift. Guarded: only
## moves when the gap exceeds 0.05 m (already-seated states are
## no-ops, re-apply idempotent). Visibility is NEVER touched — the
## outfit menu's hat toggle keeps working exactly as before.
## Runs at frame >= 850, after Realism146's 840 pass. Zero new
## meshes, zero colliders, zero per-frame work after _apply.
## MEASURED BUT DELIBERATELY NOT SHIPPED — systemic sinking:
## audit147c proves the player's visual feet sit 0.43 m below the
## floor (sandals -0.43, longyi hem -0.40) AND every NPC GLB sinks
## the same ~0.41 m (Villager1 -0.408, Villager2 -0.409,
## Villager5 -0.405). This is the S121-deferred "sinking", systemic
## across ALL figures — a player-only lift would make the player
## inconsistent with every NPC (grounded hero, buried villagers)
## and would need a full hierarchy map (pivots must move with
## meshes or limbs detach). It belongs to a dedicated
## figures-grounding round, not a silent player-only fix. Phone
## impact is low meanwhile: longyis cover legs, hems read as
## touching ground, feet sit below the TPP frame's focus.
## S137 anchor/airplane decisions untouched (owner decisions);
## S146 season tint untouched; no economy/combat/map changes.

var _frames: int = 0
var _done: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism147") != null:
		return
	var n := Node3D.new()
	n.name = "Realism147"
	n.set_script(load("res://realism147.gd"))
	world.call_deferred("add_child", n)


func _apply(world: Node3D) -> void:
	if world == null:
		return
	var player: Node = world.get_node_or_null("Player")
	if player == null:
		_done = true
		return
	var head: MeshInstance3D = (player as Node3D).get_node_or_null("Head") as MeshInstance3D
	var hat: MeshInstance3D = (player as Node3D).get_node_or_null("PlayerHat") as MeshInstance3D
	if head == null or hat == null:
		_done = true
		return
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
	_done = true


func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 850:
		_apply(get_parent() as Node3D)
