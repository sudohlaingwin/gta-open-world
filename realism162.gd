extends Node3D
## REALISM162 — tiny-dressing shadow-caster cut (S162 safe win).
## Grass blades (Blade93_/94_/95_/110_, 0.035 m cross-section) and
## pond/bank reeds (Reed57_/62/107_/108_, 0.03-0.05 m radius) are
## sub-pixel at the 6 m phone camera distance, so the shadows
## they cast into the sun shadow map are invisible — but every
## one of them casts by default (MeshInstance3D cast_shadow
## defaults to ON and no dressing script ever sets it).
## Probe162b census (day, post-dress): 156 blades + 97 reeds,
## ALL casting, out of 13,234 casting meshes total. Setting
## cast_shadow OFF on exactly the perf120 prefix set removes
## 253 shadow casters (-1.9%) with zero visible change: visible
## rendering, materials, sway, and perf120 distance hiding are
## untouched. Heli/plane rotor blades (HeliBlade114/PropBlade114)
## and wiper blades (WiperBlade76) are NOT in this prefix set
## and keep casting. This is a micro-win, stated openly: it does
## NOT fix the lag by itself (see S162 report for the ranked
## causes + the proposals that need owner decisions).
const FRAME_GATE: int = 890
const PREFIXES: Array = ["Blade93_", "Blade94_", "Blade95_", "Blade110_", "Reed57_", "Reed62", "Reed107_", "Reed108_"]
var _frames: int = 0
var _done: bool = false
var shadow_off_count: int = 0

static func dress(world: Node) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism162") != null:
		return
	var node: Node = Node3D.new()
	node.name = "Realism162"
	node.set_script(load("res://realism162.gd"))
	world.call_deferred("add_child", node)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= FRAME_GATE:
		_done = true
		_apply(get_parent() as Node3D)

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var stack: Array = [world]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D:
			var nm := String(x.name)
			for p in PREFIXES:
				if nm.begins_with(p):
					if not x.has_meta("dressed162"):
						x.set_meta("dressed162", true)
						(x as MeshInstance3D).cast_shadow = 0
						shadow_off_count += 1
					break
		for c in x.get_children():
			stack.append(c)
