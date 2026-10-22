extends RefCounted
## Slice 61 addendum — owner phone-feedback HUD fixes (2026-10-22 23:57
## screenshot + 23:59 PUBG-button question + 00:02 zoom-removal order).
## Runtime-only, no scene file touched, so main.tscn load_steps never
## moves. Idempotent: re-running finds existing nodes and only
## re-applies rects/styles, never duplicates buttons.
##
## What it does, all measured in the Slice 61 addendum sim:
## - PUBG-style bottom-right cluster: Sprint / Jump / Vehicle / Talk
##   become 104x104 px round buttons (StyleBoxFlat corner radius 52,
##   per-button style instances so the shared hud button style is
##   NOT rounded everywhere) in a 2x2 grid at canvas (1050,500),
##   (1160,500), (1050,610), (1160,610) — thumb-reachable, disjoint.
## - The permanent middle-right text column is gone: Map, Camera
##   reset, Garage, Mute, Photo, Rain move to a stack below a new
##   "More" button under the minimap, and are visible ONLY while
##   player.hud_more_open is true. The player code gates those six
##   visibility assignments on that flag (see player.gd); this file
##   only sets their stack rects and creates the toggle.
## - OrbitButton is renamed in the scene from "Camera" to the
##   Burmese word for rotate, so there is no second "Camera" text.
## - A stamina label is overlaid on the StaminaBar rect itself
##   (no new rect, so it cannot overlap anything else).
## - Minimap roads: 4 Line2D polylines drawn through the SAME
##   MapTransform.world_to_panel mapping the dots use, from REAL
##   scene road geometry — MindonLinkRoad (x 55..79, z 0),
##   MindonStreet1..5 (x 97..217, z 0), MindonBranch140
##   (x 140, z -60..36), village RoadSlab15 lane (-30,19)-(-8,24.5).
##   Dots keep their existing update path; lines are static.
## - Zoom buttons are NOT handled here: they are deleted from
##   main.tscn and locked in camera.gd (zoom fixed at 1.0) — see
##   the addendum commit. This file never re-shows them.

static func _round_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.65)
	sb.corner_radius_top_left = 52
	sb.corner_radius_top_right = 52
	sb.corner_radius_bottom_left = 52
	sb.corner_radius_bottom_right = 52
	return sb

static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0

static func dress(layer: CanvasLayer, player: Node) -> void:
	if layer == null:
		return
	# 1. PUBG-style round bottom-right cluster (104 px squares).
	var cluster := {
		"TalkButton": Vector2(1050.0, 500.0),
		"VehicleButton": Vector2(1160.0, 500.0),
		"SprintButton": Vector2(1050.0, 610.0),
		"JumpButton": Vector2(1160.0, 610.0),
	}
	for btn_name in cluster:
		var b := layer.get_node_or_null(btn_name) as Button
		if b == null:
			continue
		var pos: Vector2 = cluster[btn_name]
		_set_rect(b, pos.x, pos.y, 104.0, 104.0)
		var sb := _round_style()
		b.add_theme_stylebox_override("normal", sb)
		var sbp := _round_style()
		sbp.bg_color = Color(0.2, 0.2, 0.3, 0.8)
		b.add_theme_stylebox_override("pressed", sbp)
		b.add_theme_font_size_override("font_size", 20)
	# 2. Secondary stack under the minimap (More-gated by player).
	var stack := {
		"MapButton28": 0,
		"CameraResetButton": 1,
		"GarageButton60": 2,
		"MuteButton18": 3,
		"PhotoButton17": 4,
		"RainButton17": 5,
	}
	for btn_name in stack:
		var b := layer.get_node_or_null(btn_name) as Button
		if b == null:
			continue
		_set_rect(b, 1100.0, 302.0 + int(stack[btn_name]) * 42.0, 144.0, 36.0)
		b.visible = false
	# 3. More toggle button, directly under the minimap panel
	# (minimap is anchors x 0.84-0.98, y 0.09-0.34 = px 1075-1254,
	# 65-245; More sits at y 252-288, clear of it).
	var more := layer.get_node_or_null("MoreButton61b") as Button
	if more == null:
		more = Button.new()
		more.name = "MoreButton61b"
		more.text = "..."
		layer.add_child(more)
		if player != null and player.has_method("_on_more_toggle"):
			more.pressed.connect(Callable(player, "_on_more_toggle"))
	_set_rect(more, 1075.0, 252.0, 179.0, 36.0)
	more.visible = true
	# 4. Top bar de-overlap: the mute button no longer sits on the
	# clock (it lives in the stack now); clock keeps its corner.
	var clock := layer.get_node_or_null("ClockLabel") as Label
	if clock != null:
		_set_rect(clock, 1024.0, 14.0, 230.0, 36.0)
	# 5. Stamina label overlaid on the bar rect (no new rect).
	var bar := layer.get_node_or_null("StaminaBar") as Control
	if bar != null:
		var lab := layer.get_node_or_null("StaminaLabel61b") as Label
		if lab == null:
			lab = Label.new()
			lab.name = "StaminaLabel61b"
			lab.text = "Stamina"
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			layer.add_child(lab)
		lab.anchor_left = bar.anchor_left
		lab.anchor_top = bar.anchor_top
		lab.anchor_right = bar.anchor_right
		lab.anchor_bottom = bar.anchor_bottom
		lab.offset_left = 0.0
		lab.offset_top = 0.0
		lab.offset_right = 0.0
		lab.offset_bottom = 0.0
		lab.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		lab.add_theme_font_size_override("font_size", 14)
		lab.visible = true
	# 6. Minimap roads (MapTransform mapping, same as the dots).
	var panel := layer.get_node_or_null("MinimapPanel") as Control
	if panel != null:
		var psize := panel.size
		if psize.x <= 0.0 or psize.y <= 0.0:
			psize = Vector2(179.0, 180.0)
		var roads: Array = [
			[Vector2(55.0, 0.0), Vector2(79.0, 0.0)],
			[Vector2(97.0, 0.0), Vector2(217.0, 0.0)],
			[Vector2(140.0, -60.0), Vector2(140.0, 36.0)],
			[Vector2(-30.0, 19.0), Vector2(-8.0, 24.5)],
		]
		for i in range(roads.size()):
			var lname := "MinimapRoad61b_%d" % i
			var line := panel.get_node_or_null(lname) as Line2D
			if line == null:
				line = Line2D.new()
				line.name = lname
				line.width = 2.0
				line.default_color = Color(0.95, 0.85, 0.4, 0.9)
				panel.add_child(line)
			var pts: PackedVector2Array = PackedVector2Array()
			for w in roads[i]:
				pts.append(MapTransform.world_to_panel(w.x, w.y, psize))
			line.points = pts
