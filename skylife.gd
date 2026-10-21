extends Node3D
## Slice 18 sky life: a bird flock circles the pagoda and clouds drift
## across the sky. Pure ambience — no gameplay, no interaction, no
## fake claims: three primitive birds on a rotating flock node, three
## white cloud blobs drifting +x and wrapping at the world edge.
## Slice 19 butterflies: three more ambient creatures near the flower
## beds — each flaps two wing children and bobs gently. Wing flap is
## rotation only (no rig, no fake flight model); the butterflies stay
## near their garden posts.

var fly_time: float = 0.0

func _process(delta: float) -> void:
	var flock := get_node_or_null("BirdFlock18")
	if flock != null:
		flock.rotation.y += 0.25 * delta
	for cname in ["Cloud18A", "Cloud18B", "Cloud18C"]:
		var c := get_node_or_null(cname)
		if c != null:
			c.position.x += 1.2 * delta
			if c.position.x > 50.0:
				c.position.x = -50.0
	# Slice 19 butterflies: flap + bob around their home post.
	fly_time += delta
	for bname in ["Butterfly19A", "Butterfly19B", "Butterfly19C"]:
		var b := get_node_or_null(bname)
		if b == null:
			continue
		if not b.has_meta("base_y"):
			b.set_meta("base_y", b.position.y)
		var base_y: float = float(b.get_meta("base_y"))
		b.position.y = base_y + sin(fly_time * 2.0) * 0.3
		b.rotation.y += 0.4 * delta
		var flap := sin(fly_time * 12.0) * 0.7
		var wl := b.get_node_or_null("WingL")
		if wl != null:
			wl.rotation.z = flap
		var wr := b.get_node_or_null("WingR")
		if wr != null:
			wr.rotation.z = -flap
