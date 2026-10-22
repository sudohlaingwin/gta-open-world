extends Node3D
## Slice 59 night controller for Mindon streetlights + facade windows.
## Same daylight rule as the rest of the game (day_night.gd):
## night is daylight < 0.15. No 24/7 lights: every OmniLight child
## of this node is hidden by day, every glow box child is hidden by
## day, and the shared facade window material stops emitting by day.
## Plain Node3D, no class_name (same reason as Slice 53/56/57/58:
## a new class_name needs a regenerated .godot global-class cache).

var win_mat: StandardMaterial3D = null

func _process(_delta: float) -> void:
	var world := get_parent()
	if world == null:
		return
	var day := 1.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		day = float(dn.call("daylight"))
	var night: bool = day < 0.15
	for child in get_children():
		if child is OmniLight3D:
			(child as OmniLight3D).visible = night
		if child is MeshInstance3D and str(child.name).contains("Glow59"):
			(child as MeshInstance3D).visible = night
	if win_mat != null:
		win_mat.emission_enabled = true
		win_mat.emission_energy_multiplier = 0.9 if night else 0.0
