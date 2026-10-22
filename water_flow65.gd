extends Node
## Slice 65 — directional stream flow.
## Slice 56's shared ripple material already scrolls slowly
## (city_night56: 0.02/0.01 per second, diagonal) on every water
## surface. That reads as shimmer, not flow. The Slice 62 stream
## runs north-south (along z), so it gets its OWN duplicated
## material scrolled along V only, faster (0.18/s): water visibly
## travels down the stream while the ponds keep the slow shared
## shimmer. Same texture and colours as before — only the stream's
## material instance and its offset change, so season tints and the
## night rules are untouched. Ponds are deliberately NOT duplicated:
## still water should not flow.

const FLOW_V := 0.18
var stream_offset := 0.0
var _stream_mats: Array = []

func _process(delta: float) -> void:
	var world := get_parent()
	if world == null:
		return
	var dist := world.get_node_or_null("EastDistrict62")
	if dist == null:
		return
	if _stream_mats.is_empty():
		for nm in ["StreamNorth62", "StreamSouth62"]:
			var mi := dist.get_node_or_null(nm) as MeshInstance3D
			if mi == null:
				continue
			var base := mi.get_surface_override_material(0)
			if base == null:
				continue
			var dup := base.duplicate() as Material
			mi.set_surface_override_material(0, dup)
			_stream_mats.append(dup)
	stream_offset = fmod(stream_offset + delta * FLOW_V, 1.0)
	for m in _stream_mats:
		if m is StandardMaterial3D:
			(m as StandardMaterial3D).uv1_offset = Vector3(0.0, stream_offset, 0.0)
