extends Node3D
## Slice 66 — material realism pass (own work, StandardMaterial3D only).
## NO shaders, NO copied opponent code: the opponent's foliage_sway
## .gdshader is deliberately NOT used or ported here; Muse's sway
## stays the script-rotation pattern from Slice 62/64.
## What this does, all runtime-only, no scene file touched:
## - Roughness/metallic variation on the main visual classes, so
##   surfaces stop reading as one flat colour: wood walls
##   0.75-0.95, tin roofs 0.35-0.55 + metallic 0.35, tree trunks
##   0.90-1.00, canopies 0.85-1.00, palm fronds 0.80-0.95. Every
##   value is deterministic per node name (xorshift hash, NOT
##   String.hash — Slice 58 proved String.hash clusters
##   sequential names). Shared materials are duplicated per mesh
##   first, so varying one tree never repaints every tree.
## - ALBEDO IS NEVER TOUCHED, except the MainRoad62 wet-look,
##   which stores and restores its own base. That keeps Slice 61
##   style colours, Slice 62 season tints (the season controller
##   owns canopy/ground albedo), Slice 35 paint presets (vehicle
##   albedo is the player's saved colour) and the Slice 61 night
##   floor (no light/energy change anywhere) intact by design.
## - Village TreeTop sway: the same ±0.03 rad rotation.z pattern
##   as the Slice 62 canopy sway, applied to VILLAGE TreeTop
##   meshes only. East Fields trees are excluded by name
##   (Chill62_*, Tree64 groups, Chill62_Flower) so no tree is
##   swayed twice; night-driven materials (Window/Glow/Lamp/
##   Lantern/Light in the name, or emission_enabled) are skipped.
## - Vehicle gloss: car/motorcycle/tuk-tuk body materials get
##   roughness 0.25 + metallic 0.6 every frame (albedo untouched),
##   re-applied after Slice 35 paint duplication replaces the
##   material, so presets keep working and stay glossy.
## - Wet road: MainRoad62 asphalt goes rough 0.90 dry -> 0.35 wet
##   + albedo darkened x0.75 in rainy season only (season read
##   from the live ChillController62 node first, SaveManager
##   second), restored exactly when the season leaves rainy.
## Capture runs at frame >= 8 so all deferred dressing (Slice 56/
## 59/62/64 groups, Slice 61 style, Slice 35 paints) has landed.

var _time: float = 0.0
var _frames: int = 0
var _captured: bool = false
var _sway: Array = []
var _seen_mats: Array = []
var _road_mat: StandardMaterial3D = null
var _road_base_albedo: Color = Color.WHITE
var _road_base_rough: float = 0.95
var _wet: bool = false

static func _hash01(s: String) -> float:
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0

func _unique_mat(mi: MeshInstance3D) -> StandardMaterial3D:
	if mi.get_surface_override_material_count() <= 0:
		return null
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	if m == null:
		return null
	if _seen_mats.has(m):
		var dup := m.duplicate() as StandardMaterial3D
		mi.set_surface_override_material(0, dup)
		_seen_mats.append(dup)
		return dup
	_seen_mats.append(m)
	return m

func _capture(world: Node3D) -> void:
	_captured = true
	var stack: Array = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		var nm := String(mi.name)
		# Night-driven materials are owned by DayNight/lantern
		# controllers; never touch them here.
		if "Window" in nm or "Glow" in nm or "Lamp" in nm or "Lantern" in nm or "Light" in nm:
			continue
		var h := _hash01(nm)
		if nm.begins_with("TreeTop"):
			_sway.append([mi, mi.rotation.z, h * 6.283])
			var m := _unique_mat(mi)
			if m != null:
				m.roughness = 0.85 + h * 0.15
		elif nm.begins_with("TreeTrunk") or nm.begins_with("PalmTrunk"):
			var m2 := _unique_mat(mi)
			if m2 != null:
				m2.roughness = 0.90 + h * 0.10
		elif nm.begins_with("PalmFrond") or nm.begins_with("PalmLeaf"):
			var m3 := _unique_mat(mi)
			if m3 != null:
				m3.roughness = 0.80 + h * 0.15
		elif nm.begins_with("Roof") or nm == "RoofL62" or nm == "RoofR62":
			var m4 := _unique_mat(mi)
			if m4 != null:
				m4.roughness = 0.35 + h * 0.20
				m4.metallic = 0.35
		elif nm.begins_with("House") or nm.begins_with("DressWall53") or nm == "Walls62" or nm == "House6Walls":
			var m5 := _unique_mat(mi)
			if m5 != null:
				m5.roughness = 0.75 + h * 0.20
				m5.metallic = 0.0
		elif nm == "Floor62":
			var m6 := _unique_mat(mi)
			if m6 != null:
				m6.roughness = 0.80 + h * 0.15
		elif "Canopy" in nm:
			var m7 := _unique_mat(mi)
			if m7 != null and not m7.emission_enabled:
				m7.roughness = 0.85 + h * 0.15
		elif nm == "MainRoad62":
			var m8 := mi.get_surface_override_material(0) as StandardMaterial3D
			if m8 != null:
				_road_mat = m8
				_road_base_albedo = m8.albedo_color
				_road_base_rough = m8.roughness

func _season() -> int:
	var world := get_parent() as Node3D
	if world != null:
		var ctrl := world.get_node_or_null("ChillController62")
		if ctrl != null and ctrl.get("_season") != null:
			return clampi(int(ctrl.get("_season")), 0, 2)
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.get("season62") != null:
		return clampi(int(sm.get("season62")), 0, 2)
	return 0

func _process(delta: float) -> void:
	_time += delta
	_frames += 1
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _captured and _frames >= 8:
		_capture(world)
	if not _captured:
		return
	# Village tree sway, same pattern as Slice 62 canopies.
	for entry in _sway:
		var sn := entry[0] as Node3D
		if sn == null:
			continue
		sn.rotation.z = float(entry[1]) + sin(_time * 1.6 + float(entry[2])) * 0.03
	# Vehicle gloss (albedo untouched; re-applies after paint dup).
	var bodies: Array = ["Car/MeshInstance3D", "Motorcycle/MeshInstance3D", "TukTuk/TukBody"]
	for path in bodies:
		var mesh := world.get_node_or_null(path) as MeshInstance3D
		if mesh == null or mesh.get_surface_override_material_count() <= 0:
			continue
		var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat == null:
			continue
		if mat.roughness != 0.25:
			mat.roughness = 0.25
		if mat.metallic != 0.6:
			mat.metallic = 0.6
	# Wet road: rainy season only.
	if _road_mat != null:
		var rainy := _season() == 1
		if rainy and not _wet:
			_wet = true
			_road_mat.roughness = 0.35
			_road_mat.albedo_color = Color(_road_base_albedo.r * 0.75, _road_base_albedo.g * 0.75, _road_base_albedo.b * 0.75, 1.0)
		elif not rainy and _wet:
			_wet = false
			_road_mat.roughness = _road_base_rough
			_road_mat.albedo_color = _road_base_albedo
