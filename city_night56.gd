extends Node3D
## Slice 56 night + water + cloud + fireworks controller.
## Created at runtime by city_visual56.dress() as NightLights56,
## a child of the world root, so DayNight is a sibling.
## Same daylight rule as the rest of the game: night is
## daylight < 0.15 (day_night.gd). No 24/7 lights: OmniLights
## are hidden by day, fountains glow only at night, fireworks
## show only at night. Water UV scroll and cloud drift run
## at all hours (water movement is not a night effect).

var _time: float = 0.0
var _water_offset: Vector2 = Vector2.ZERO
## S120: omni loop below is gated on night-state CHANGE, not every
## frame — the old per-frame write undid Perf120's distance
## culling within one frame. Water/cloud/fireworks animation
## below stays per-frame (not light state, no conflict).
var _last_night := false
var _gate_once := false

func _process(delta: float) -> void:
	_time += delta
	var world := get_parent()
	if world == null:
		return
	var day := 1.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		day = float(dn.call("daylight"))
	var night: bool = day < 0.15
	if not _gate_once or night != _last_night:
		_gate_once = true
		_last_night = night
		for child in get_children():
			if child is OmniLight3D:
				(child as OmniLight3D).visible = night
	var pond := world.get_node_or_null("Pond") as MeshInstance3D
	if pond != null:
		var wmat := pond.get_surface_override_material(0) as StandardMaterial3D
		if wmat != null:
			_water_offset.x = fmod(_water_offset.x + delta * 0.02, 1.0)
			_water_offset.y = fmod(_water_offset.y + delta * 0.01, 1.0)
			wmat.uv1_offset = Vector3(_water_offset.x, _water_offset.y, 0.0)
	for child in world.get_children():
		var nm := String(child.name)
		if nm.begins_with("Fountain56"):
			for grand in child.get_children():
				if grand is MeshInstance3D and String(grand.name) == "FountainWater56":
					var fmat := (grand as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
					if fmat != null:
						fmat.emission_enabled = night
		elif nm.begins_with("Cloud56"):
			var c := child as Node3D
			c.position.x += delta * 1.0
			if c.position.x > 450.0:
				c.position.x = -70.0
	var fw := world.get_node_or_null("Fireworks56") as Node3D
	if fw != null:
		fw.visible = night
		if night:
			var active: int = int(_time / 2.0) % 3
			var idx := 0
			for cluster in fw.get_children():
				if cluster is Node3D:
					(cluster as Node3D).visible = idx == active
					var s: float = 1.0 + sin(_time * 3.0) * 0.25
					(cluster as Node3D).scale = Vector3(s, s, s)
					idx += 1
