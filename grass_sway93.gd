extends Node3D
## Slice 93 grass sway: this node is the parent of every grass
## tuft cluster added by realism93.dress(). Each frame it tilts
## each tuft a few degrees around its ground-level origin, so the
## blade tips sway while the bases stay planted. The tilt is
## small (about 0.05 rad) and phase-shifted per tuft so the field
## does not move as one rigid sheet. One _process loop for all
## tufts; no per-tuft script, no physics, no colliders.

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	var i := 0
	for tuft in get_children():
		if tuft is Node3D:
			var ph := float(i) * 0.7
			(tuft as Node3D).rotation.z = sin(_time * 1.3 + ph) * 0.05
			(tuft as Node3D).rotation.x = cos(_time * 1.1 + ph) * 0.04
		i += 1
