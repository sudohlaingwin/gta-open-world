extends RefCounted
## Slice 60 — HUD legibility pass + Slice 60 HUD nodes (runtime-only,
## no scene file touched, so main.tscn load_steps never moves).
## Measured baseline at 1280x720 (Slice 60 sim, before this pass):
## - SpeedLabel (top-left, driving-only) sat exactly on DayLabel
##   (same 25,14,294x36 rect) whenever the player drove.
## - QuestTrackerLabel's 36-stage line ran past its 640 px rect
##   toward the minimap; FruitWaterLabel's 21-counter line measured
##   701 px wide from x=1075, i.e. off the right edge entirely.
## - Minimap PlayerDot was 8 px, invisible against busy ground.
## Fixes below, all verified by the Slice 60 post-pass sim audit:
## - SpeedLabel moves to bottom-centre, just under the stamina bar
##   (y 680-716, clear of StaminaBar ending 676 and PromptLabel
##   ending 626); DayLabel keeps the top-left corner alone.
## - QuestTrackerLabel wraps at 14 px (autowrap on, rect
##   y 54-162, fits its 5 wrapped lines): clear of QuestLabel
##   above (ends 50) and of SightseeingLabel54 below (moved to
##   y 169-205 for exactly this stack).
## - FruitWaterLabel wraps inside x 704-1075 (clear of the
##   always-visible right-column buttons) with a 3-line-tall rect,
##   so the counter line can no longer run off-screen.
## - PlayerDot grows 8 -> 12 px with a white halo behind it.
## New nodes: DistrictLabel60 (district quest progress, updated by
## player._update_district60) and GarageButton60 + GarageLabel60
## (garage recall; button hidden while driving by the player).
## Created here, not in the scene, so an old scene still works;
## polish() is idempotent (re-running finds existing nodes and
## only re-applies rects, never duplicates buttons/labels).
## Note: _apply_hud_scale scales by Control.scale, independent of
## these anchor changes, so polish order vs hud-scale is free.

static func polish(layer: CanvasLayer, player: Node) -> void:
	if layer == null:
		return
	var tracker := layer.get_node_or_null("QuestTrackerLabel") as Label
	if tracker != null:
		tracker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# 10 px: the label's minimum size grows with wrapped text
		# (measured: 207 px tall at 14 px for this text), so a
		# larger font overflows the anchor band no matter how tall
		# the rect is drawn — the rect itself grows to the minimum
		# size. At 10 px + the single-space join in tracker_for,
		# the text wraps to 4 lines inside the 108 px rect
		# (sim-verified). The main quest label keeps its full-size
		# font; only this secondary 36-stage overview is small.
		tracker.add_theme_font_size_override("font_size", 10)
		tracker.anchor_left = 0.25
		tracker.anchor_top = 0.075
		tracker.anchor_right = 0.75
		tracker.anchor_bottom = 0.225
		tracker.offset_left = 0.0
		tracker.offset_top = 0.0
		tracker.offset_right = 0.0
		tracker.offset_bottom = 0.0
	# Centre-column stack, all disjoint at 1280x720 (sim-verified):
	# QuestLabel 14-50, tracker 54-162, sightseeing 169-205,
	# district 216-252, garage notice 259-295. SightseeingLabel54
	# is moved down from its 0.18-0.23 band to make room; the
	# transient ParachuteLabel (86-122, scene node, drawn above)
	# still covers the tracker briefly while parachuting, which is
	# the correct priority for a landing notice.
	var sight_lbl := layer.get_node_or_null("SightseeingLabel54") as Label
	if sight_lbl != null:
		sight_lbl.anchor_left = 0.30
		sight_lbl.anchor_top = 0.235
		sight_lbl.anchor_right = 0.70
		sight_lbl.anchor_bottom = 0.285
		sight_lbl.offset_left = 0.0
		sight_lbl.offset_top = 0.0
		sight_lbl.offset_right = 0.0
		sight_lbl.offset_bottom = 0.0
	var speed := layer.get_node_or_null("SpeedLabel") as Label
	if speed != null:
		speed.anchor_left = 0.25
		speed.anchor_top = 0.945
		speed.anchor_right = 0.45
		speed.anchor_bottom = 0.995
		speed.offset_left = 0.0
		speed.offset_top = 0.0
		speed.offset_right = 0.0
		speed.offset_bottom = 0.0
	var counters := layer.get_node_or_null("FruitWaterLabel") as Label
	if counters != null:
		counters.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		counters.anchor_left = 0.55
		counters.anchor_top = 0.42
		counters.anchor_right = 0.84
		counters.anchor_bottom = 0.52
		counters.offset_left = 0.0
		counters.offset_top = 0.0
		counters.offset_right = 0.0
		counters.offset_bottom = 0.0
	var panel := layer.get_node_or_null("MinimapPanel") as Control
	if panel != null:
		var dot := panel.get_node_or_null("PlayerDot") as ColorRect
		if dot != null:
			dot.size = Vector2(12.0, 12.0)
			if dot.get_node_or_null("PlayerHalo60") == null:
				var halo := ColorRect.new()
				halo.name = "PlayerHalo60"
				halo.color = Color(1.0, 1.0, 1.0, 1.0)
				halo.position = Vector2(-4.0, -4.0)
				halo.size = Vector2(20.0, 20.0)
				halo.z_index = -1
				dot.add_child(halo)
	var district := layer.get_node_or_null("DistrictLabel60") as Label
	if district == null:
		district = Label.new()
		district.name = "DistrictLabel60"
		district.anchor_left = 0.30
		district.anchor_top = 0.30
		district.anchor_right = 0.70
		district.anchor_bottom = 0.35
		district.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		district.text = ""
		layer.add_child(district)
	else:
		district.anchor_left = 0.30
		district.anchor_top = 0.30
		district.anchor_right = 0.70
		district.anchor_bottom = 0.35
	var garage_label := layer.get_node_or_null("GarageLabel60") as Label
	if garage_label == null:
		garage_label = Label.new()
		garage_label.name = "GarageLabel60"
		garage_label.anchor_left = 0.30
		garage_label.anchor_top = 0.36
		garage_label.anchor_right = 0.70
		garage_label.anchor_bottom = 0.41
		garage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		garage_label.text = ""
		garage_label.visible = false
		layer.add_child(garage_label)
	else:
		garage_label.anchor_left = 0.30
		garage_label.anchor_top = 0.36
		garage_label.anchor_right = 0.70
		garage_label.anchor_bottom = 0.41
	var garage_btn := layer.get_node_or_null("GarageButton60") as Button
	if garage_btn == null:
		garage_btn = Button.new()
		garage_btn.name = "GarageButton60"
		garage_btn.text = "🚗 ဂိုဒေါင်"
		garage_btn.anchor_left = 0.84
		garage_btn.anchor_top = 0.60
		garage_btn.anchor_right = 0.98
		garage_btn.anchor_bottom = 0.66
		layer.add_child(garage_btn)
		if player != null and player.has_method("_on_garage_button_pressed"):
			garage_btn.pressed.connect(Callable(player, "_on_garage_button_pressed"))
