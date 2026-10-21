extends Node3D
## Slice 18 sky life: a bird flock circles the pagoda and clouds drift
## across the sky. Pure ambience — no gameplay, no interaction, no
## fake claims: three primitive birds on a rotating flock node, three
## white cloud blobs drifting +x and wrapping at the world edge.

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
