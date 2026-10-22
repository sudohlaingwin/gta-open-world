extends Node3D
## Slice 57 night controller for bridge + pagoda lantern lights.
## Same daylight rule as the rest of the game (day_night.gd):
## night is daylight < 0.15. No 24/7 lights: every OmniLight
## child of this node is hidden by day. Created at runtime by
## river_bridge57.dress(); it is a plain Node3D (no class_name),
## so no .godot global-class cache regeneration is needed.

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
