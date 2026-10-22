## Slice 61: owner-ordered GRAPHICS-ONLY style pass.
## Binding owner clarification 2026-10-22 22:55 +07 (see
## ~/workspace/games/graphics-master-prompt.md, OWNER CLARIFICATION):
## take ONLY the graphics/visual look from that document — low-poly
## stylized, vivid daytime palette with warm sunlight, clean simple
## geometry, soft painted shading, Myanmar traditional looks — and apply
## it to the EXISTING Muse game. Do NOT adopt that document's game
## structure, map, positions, names, school, or code. No building
## position moves, no new nodes, no gameplay change, no scene file
## touched. This is a RECOLOUR pass on existing models, not a rebuild:
## every operation below is an absolute material colour assignment
## (re-running it gives the same colours, never stacks), and the
## report must say recolour vs rebuild plainly per asset class.
## Ownership rules — breaking any of these breaks the game:
## - Player Torso/Longyi belong to the outfit system (Slice 30/35):
##   untouched. Only VILLAGER torsos are recoloured (their materials
##   were already duplicated per body in Slice 58).
## - Vehicle paints belong to settings (Slice 35): no vehicle node
##   is touched at all (the whitelist below names no vehicle part).
## - Night-driven materials (emission on, or Window/Glow/Lamp/
##   Lantern/Light in the name) are untouched: the DayNight window
##   and lantern controllers keep owning them.
## - Textured materials (plaster, grass, dirt textures) are TINTED
##   only: albedo_color multiplies the texture, the texture stays.
## - Shared dressing materials (Slice 58/59) are recoloured in place
##   (one palette change for all users of that material, as intended);
##   scene materials of unknown sharing (tree trunks, palm fronds)
##   are duplicated per node first, so nothing else changes colour.
## Runs last, DEFERRED from player._ready, after Dress59. Deferred
## because Dress58Ground, District59 groups and City56 blocks are
## themselves added via call_deferred: a direct call would run before
## those groups exist in the tree. Loaded by preload,
## NOT class_name (a new class_name needs a regenerated .godot
## global-class cache and a stale cache breaks player.gd's parse —
## proven Slice 53).

static func _hash01(s: String) -> float:
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0


static func _mat_of(mi: MeshInstance3D) -> StandardMaterial3D:
	if mi == null:
		return null
	var nm := String(mi.name)
	if "Window" in nm or "Win56" in nm or "Win59" in nm or "Glow" in nm or "Lamp" in nm or "Lantern" in nm or "Light" in nm:
		return null
	var m := mi.get_surface_override_material(0)
	if not (m is StandardMaterial3D):
		return null
	if (m as StandardMaterial3D).emission_enabled:
		return null
	return m as StandardMaterial3D


## Duplicate-then-recolour: safe for materials that may be shared
## with nodes outside this pass (scene trunks/fronds, per-node
## canopy/torso materials). Returns false when skipped.
static func _recolor_dup(mi: MeshInstance3D, color: Color, rough: float) -> bool:
	var m := _mat_of(mi)
	if m == null:
		return false
	var dup := m.duplicate() as StandardMaterial3D
	if dup == null:
		return false
	dup.albedo_color = color
	dup.roughness = rough
	mi.set_surface_override_material(0, dup)
	return true


## In-place palette change for dressing materials that are MEANT to
## be shared (Slice 58/59 dressing mats, doors, trim). Texture, if
## any, is preserved: only albedo_color changes.
static func _recolor_shared(mi: MeshInstance3D, color: Color) -> bool:
	var m := _mat_of(mi)
	if m == null:
		return false
	m.albedo_color = color
	return true


## In-place warm tint for textured materials: the generated texture
## stays, albedo_color (previously white) becomes the warm multiplier.
static func _tint_shared(mi: MeshInstance3D, tint: Color) -> bool:
	var m := _mat_of(mi)
	if m == null:
		return false
	if m.albedo_texture == null:
		return false
	m.albedo_color = tint
	return true


static func dress(world: Node) -> void:
	if world == null:
		return
	# Vivid Myanmar-traditional palettes (master-prompt style block:
	# vivid daytime, warm sunlight, soft painted shading, no
	# photorealism). All colours are absolute assignments.
	var villager_shirts: Array = [
		Color(0.05, 0.45, 0.30, 1.0),
		Color(0.45, 0.10, 0.15, 1.0),
		Color(0.10, 0.15, 0.45, 1.0),
		Color(0.90, 0.45, 0.55, 1.0),
		Color(0.95, 0.80, 0.45, 1.0),
	]
	var leaf_greens: Array = [
		Color(0.10, 0.55, 0.15, 1.0),
		Color(0.15, 0.45, 0.25, 1.0),
		Color(0.25, 0.60, 0.15, 1.0),
	]
	var warm_plaster := Color(1.0, 0.96, 0.86, 1.0)
	var vivid_grass := Color(0.94, 1.0, 0.88, 1.0)
	var warm_dirt_path := Color(1.0, 0.96, 0.88, 1.0)
	var stack: Array = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		var nm := String(mi.name)
		# Characters: villager torsos only. Player torso's parent is
		# "Player" (outfit-owned) — never touched.
		if nm == "Torso":
			var parent := mi.get_parent()
			if parent != null and String(parent.name).begins_with("Villager"):
				var h := _hash01(String(parent.name))
				_recolor_dup(mi, villager_shirts[int(h * 5.0) % 5], 0.85)
			continue
		# Trees: scene canopies (per-node materials, Slice 53).
		if nm.begins_with("TreeTop"):
			var h2 := _hash01(nm)
			_recolor_dup(mi, leaf_greens[int(h2 * 3.0) % 3], 0.9)
			continue
		if nm == "Canopy56":
			_recolor_dup(mi, Color(0.14, 0.58, 0.20, 1.0), 0.9)
			continue
		if nm.begins_with("TreeTrunk"):
			_recolor_dup(mi, Color(0.42, 0.28, 0.16, 1.0), 0.95)
			continue
		if nm.begins_with("PalmTrunk"):
			_recolor_dup(mi, Color(0.45, 0.30, 0.17, 1.0), 0.95)
			continue
		if nm.begins_with("PalmFrond"):
			_recolor_dup(mi, Color(0.18, 0.60, 0.22, 1.0), 0.9)
			continue
		# Slice 58 nature dressing (shared materials, in place).
		if nm.begins_with("Blossom58"):
			_recolor_shared(mi, Color(0.95, 0.35, 0.55, 1.0))
			continue
		if nm.begins_with("Fruit58"):
			_recolor_shared(mi, Color(0.95, 0.55, 0.10, 1.0))
			continue
		if nm == "Tuft58":
			_recolor_shared(mi, Color(0.20, 0.60, 0.20, 1.0))
			continue
		if nm.begins_with("Coconut58"):
			_recolor_shared(mi, Color(0.45, 0.30, 0.15, 1.0))
			continue
		# Slice 58/59 ground dressing (shared dirt, in place).
		if nm.begins_with("Path58") or nm.begins_with("Patch58") or nm.begins_with("Row58"):
			_recolor_shared(mi, Color(0.60, 0.45, 0.28, 1.0))
			continue
		if nm.begins_with("OutPatch59") or nm.begins_with("OutPath59"):
			_recolor_shared(mi, Color(0.60, 0.45, 0.28, 1.0))
			continue
		# Slice 59 outskirt trees (shared trunk/leaf mats, in place).
		if nm.begins_with("OutTree59_Trunk"):
			_recolor_shared(mi, Color(0.40, 0.27, 0.15, 1.0))
			continue
		if nm.begins_with("OutTree59_Canopy"):
			_recolor_shared(mi, Color(0.16, 0.55, 0.18, 1.0))
			continue
		# Buildings: plaster walls are textured — warm tint only.
		if nm == "DressWall53" or nm.ends_with("Walls"):
			_tint_shared(mi, warm_plaster)
			continue
		# Doors and trim (shared, plain, not night-driven).
		if nm == "Door56" or nm == "Door59" or nm.begins_with("DressDoor53"):
			_recolor_shared(mi, Color(0.40, 0.26, 0.14, 1.0))
			continue
		if nm == "Trim56":
			_recolor_shared(mi, Color(0.60, 0.38, 0.22, 1.0))
			continue
		if nm == "Eaves58":
			_recolor_shared(mi, Color(0.65, 0.30, 0.15, 1.0))
			continue
		if nm.begins_with("Shutter58"):
			_recolor_shared(mi, Color(0.50, 0.32, 0.16, 1.0))
			continue
		# Ground: textured grass/dirt — warm/vivid tint only.
		if nm == "GroundMesh":
			_tint_shared(mi, vivid_grass)
			continue
		if "Path" in nm:
			_tint_shared(mi, warm_dirt_path)
			continue
		# Fields: plain paddy green, or vivid tint if textured.
		if nm in ["FieldEast", "FieldNorth", "FieldSouth", "FieldWest"]:
			var fm := _mat_of(mi)
			if fm != null and fm.albedo_texture != null:
				_tint_shared(mi, vivid_grass)
			else:
				_recolor_dup(mi, Color(0.30, 0.55, 0.20, 1.0), 1.0)
			continue
