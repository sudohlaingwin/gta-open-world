extends Node3D
## Slice 64 — East Fields idle animation (companion to
## eastfields64.gd). Runs on the EastFields64 group: it sways the
## whole Tree64_* groups (group origin at the ground, so a small
## rotation visibly leans the canopy — swaying a sphere mesh in
## place would be invisible), sways Flower64_* groups, and bobs
## animal Head64 groups (cow/chicken heads are Node3D groups, so
## their rotation is visible; flower Head64 spheres are
## MeshInstance3D and are deliberately skipped here — flowers
## sway via their group instead). Names are Slice 64-only, so the
## Slice 62 controller never double-sways these nodes (it only
## sways Chill62_* names; it DOES season-tint Canopy64_* meshes
## because their names contain "Canopy" — that tint is wanted,
## and this script never touches colours, so there is no fight).

var _time: float = 0.0
var _sway: Array = []
var _heads: Array = []

static func _hash01(s: String) -> float:
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0

func _ready() -> void:
	var grp := get_parent() as Node3D
	if grp == null:
		return
	var stack: Array = [grp]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var nm := String(n.name)
		if n is Node3D and not (n is MeshInstance3D):
			if nm.begins_with("Tree64_"):
				_sway.append([n, (n as Node3D).rotation.z, _hash01(nm) * 6.283, 0.02])
			elif nm.begins_with("Flower64_"):
				_sway.append([n, (n as Node3D).rotation.z, _hash01(nm) * 6.283, 0.06])
			elif nm == "Head64":
				_heads.append([n, (n as Node3D).rotation.x, _hash01(str(n.get_path())) * 6.283])
		for c in n.get_children():
			stack.push_back(c)

func _process(delta: float) -> void:
	_time += delta
	for e in _sway:
		var sn := e[0] as Node3D
		sn.rotation.z = float(e[1]) + sin(_time * 1.6 + float(e[2])) * float(e[3])
	for e in _heads:
		var hd := e[0] as Node3D
		hd.rotation.x = float(e[1]) + sin(_time * 1.9 + float(e[2])) * 0.1
