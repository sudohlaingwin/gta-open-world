## Slice 28: WORKING world map (master prompt section 10).
## A full-screen overlay opened by the touch-first Map button in the HUD.
## It beats the opponent's slice-35 map on every point that map failed:
## the button is actually connected (player.gd wires it lazily like every
## other HUD button), landmark markers are computed from REAL world node
## positions through a documented transform (never fixed canvas offsets),
## and the player marker is CLAMPED to the map area at the world edges.
## Tap the map to set a waypoint (marker + bearing only, NO routing or
## pathfinding — that is deliberately not claimed); tap again to move it,
## Clear removes it. The waypoint also shows on the minimap (player.gd
## reads has_waypoint/waypoint) and as a red beacon in the world.
## Zoom is button-driven (touch-friendly); drag pans the map.
## Slice 49 (audit item 6, re-scoped): the world map no longer owns
## its own centre/span constants — it uses the SHARED MapTransform
## (bounds read from the live GroundMesh, same source as the
## minimap). The Slice 28 formula's VALUES are preserved exactly
## (same scale, same zoom-about-centre + pan), but its coordinate
## SPACE is corrected: the old world_to_map returned OVERLAY
## coordinates (centre included _map_area.position) while the dots
## are children of _map_area, so every dot rendered displaced by
## _map_area.position and clipped at the area edge — and taps,
## which _gui_input delivers AREA-LOCAL, were read back as overlay
## coordinates, landing ~171 m / ~69 m off at zoom 1. Both paths are
## area-local now. One deliberate difference from the old tap clamp:
## taps in the square area's void bands (world z beyond +-110) used
## to place a beacon up to z +-160, outside the ground plane where
## the player can never walk; they now clamp to the ground edge.
## Slice 34 guidance and the beacon use raw world coordinates and
## are untouched by this change.
extends Control

const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 3.0
const TAP_SLOP_PX: float = 14.0

var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO
var has_waypoint: bool = false
var waypoint: Vector2 = Vector2.ZERO
var was_paused: bool = false

var _map_area: Control = null
var _map_bg: ColorRect = null
var _title_label: Label = null
var _info_label: Label = null
var _legend_label: Label = null
var _district_nodes: Dictionary = {}
var _water_nodes: Dictionary = {}
var _close_btn: Button = null
var _zoom_in_btn: Button = null
var _zoom_out_btn: Button = null
var _clear_btn: Button = null
var _marker_nodes: Dictionary = {}
var _player_dot: ColorRect = null
# Slice 87 bus route line (child of _map_area, created in
# _build_ui, refreshed in _update_markers beside the dots).
var _route_line: Line2D = null
var _waypoint_dot: ColorRect = null
var _waypoint_label: Label = null
var _beacon: MeshInstance3D = null
var _world_root_cache: Node = null
var _last_vp_size: Vector2 = Vector2.ZERO
var _press_pos: Vector2 = Vector2.ZERO
var _press_pan: Vector2 = Vector2.ZERO
var _dragging: bool = false

## Landmarks: world node name, short label, dot colour. Positions are
## read from these nodes every frame the map is open — never hardcoded.
const LANDMARKS: Array = [
	["Pagoda", "ဘုရား", Color(1.0, 0.8, 0.1, 1.0)],
	["MarketStallA", "ဈေး", Color(1.0, 0.55, 0.1, 1.0)],
	["Pier20", "ဆိပ်ကမ်း", Color(0.2, 0.6, 1.0, 1.0)],
	["School13", "ကျောင်း", Color(0.2, 0.7, 1.0, 1.0)],
	["GuestHouse20", "တည်းခိုခန်း", Color(0.8, 0.4, 1.0, 1.0)],
	["FestivalStage16", "ပွဲ", Color(1.0, 0.2, 0.3, 1.0)],
	["MindonPagoda", "စုတောင်ပြည် ဘုရား", Color(1.0, 0.8, 0.1, 1.0)],
	["MindonTemple", "ဘုန်းကြီးကျောင်း", Color(0.9, 0.7, 0.2, 1.0)],
	["MindonPost", "စာတိုက်", Color(0.2, 0.6, 1.0, 1.0)],
	["MindonHospital", "ဆေးရုံ", Color(1.0, 0.2, 0.3, 1.0)],
	["MindonEdu", "ပညာရေးရုံး", Color(0.2, 0.7, 1.0, 1.0)],
	["MindonMRTV", "MRTV", Color(0.8, 0.4, 1.0, 1.0)],
	["MindonShops", "ဈေးဆိုင်", Color(1.0, 0.55, 0.1, 1.0)],
	["OoHouse1", "အိုးရွာ", Color(0.85, 0.8, 0.7, 1.0)],
	# Slice 74 bus stops: group origins ARE the stop points,
	# so these dots track the stops live like every landmark.
	# Slice 84: labels are TRAVEL positions (group 4 = ၁,
	# group 0 = ၂, ..., group 5 = ၆), and 2 new endpoints
	# join. The lookup below falls back to the LongRoute74
	# path, because the groups are children of LongRoute74,
	# not of the world root (the old direct lookup silently
	# hid every stop dot — found while adding the new ones).
	["BusStop74_4", "ဘတ်စ်ကား ၁", Color(0.2, 0.6, 1.0, 1.0)],
	["BusStop74_0", "ဘတ်စ်ကား ၂", Color(0.2, 0.6, 1.0, 1.0)],
	["BusStop74_1", "ဘတ်စ်ကား ၃", Color(0.2, 0.6, 1.0, 1.0)],
	["BusStop74_2", "ဘတ်စ်ကား ၄", Color(0.2, 0.6, 1.0, 1.0)],
	["BusStop74_3", "ဘတ်စ်ကား ၅", Color(0.2, 0.6, 1.0, 1.0)],
	["BusStop74_5", "ဘတ်စ်ကား ၆", Color(0.2, 0.6, 1.0, 1.0)],
]

## Slice 67 — district region titles. Unlike LANDMARKS, a region has
## no single scene node, so its centre is a documented band centre
## in WORLD metres (mapped through world_to_map like everything
## else — never a canvas offset): Village spans the Slice 37 ground
## west of the village/Mindon bridge at x 88 (centre x 9, the middle
## of -70..88); Mindon spans x 88..250 (centre x 169); East Fields
## spans the Slice 62 ground x 250..450 (centre x 350, z -50, the
## middle of -210..110). Titles render larger (22 pt) and centred
## above their anchor so they read as region titles, not dot labels.
const DISTRICTS: Array = [
	["ရွာ", Vector2(9.0, 0.0), Color(0.6, 1.0, 0.6, 1.0)],
	["မင်းတုန်း", Vector2(169.0, 0.0), Color(1.0, 0.85, 0.5, 1.0)],
	["လယ်ကွင်း", Vector2(350.0, -50.0), Color(0.7, 1.0, 0.7, 1.0)],
	# Slice 74 long road: x 450..2450 band centre (1447.5, -50).
	["လမ်းရှည်", Vector2(1447.5, -50.0), Color(0.7, 0.85, 1.0, 1.0)],
]

## Slice 67 — East Fields water labels. Pond62A/Pond62B and the
## Slice 62 stream are runtime children of EastDistrict62, not scene
## nodes, so the world map cannot read them live like LANDMARKS;
## their positions are the real Slice 62 build coordinates (Pond62A
## centre (300,-60) r 6, Pond62B centre (415,45) r 5, stream slab
## x 350 with its north segment centre z -59 and south segment
## centre z 34 — the label sits on the north segment at (350,-80),
## clear of the လယ်ကွင်း region title at (350,-50) by 30 m).
const WATER_LABELS: Array = [
	["ရေကန်", Vector2(300.0, -60.0)],
	["ရေကန်", Vector2(415.0, 45.0)],
	["ချောင်း", Vector2(350.0, -80.0)],
]

## Slice 67 — district bands for the current-district readout.
## x 88 is the Slice 37 village/Mindon bridge line, x 250 is the
## Slice 62 road start (Mindon/East Fields boundary). Bands, not
## exact borders — stated plainly, since no border geometry exists.
static func district_name_for(wx: float) -> String:
	if wx >= 450.0:
		return "လမ်းရှည်"
	if wx >= 250.0:
		return "လယ်ကွင်း"
	if wx >= 88.0:
		return "မင်းတုန်း"
	return "ရွာ"


func _ready() -> void:
	visible = false
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "MapBg"
	bg.color = Color(0.05, 0.08, 0.05, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_title_label = Label.new()
	_title_label.name = "MapTitle"
	_title_label.text = "🗺 မြေပုံ — တို့ထိပြီး လမ်းကြောင်း သတ်မှတ်ပါ"
	_title_label.position = Vector2(16.0, 16.0)
	_title_label.size = Vector2(900.0, 48.0)
	add_child(_title_label)
	_map_area = Control.new()
	_map_area.name = "MapArea"
	_map_area.clip_contents = true
	_map_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_area.gui_input.connect(_on_map_area_input)
	add_child(_map_area)
	_map_bg = ColorRect.new()
	_map_bg.name = "MapAreaBg"
	_map_bg.color = Color(0.12, 0.28, 0.12, 1.0)
	_map_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_area.add_child(_map_bg)
	# Slice 87 bus route line: drawn FIRST among the map
	# content so every marker dot draws on top of it.
	# Points refresh in _update_markers (zoom/pan move
	# it for free); width suits the large map area.
	_route_line = Line2D.new()
	_route_line.name = "BusRouteLine87"
	_route_line.width = 3.0
	_route_line.default_color = Color(1.0, 0.85, 0.2, 1.0)
	_map_area.add_child(_route_line)
	for lm in LANDMARKS:
		var dot := ColorRect.new()
		dot.name = "Dot_" + str(lm[0])
		dot.size = Vector2(14.0, 14.0)
		dot.color = lm[2]
		_map_area.add_child(dot)
		var lab := Label.new()
		lab.name = "Label_" + str(lm[0])
		lab.text = str(lm[1])
		lab.position = Vector2.ZERO
		_map_area.add_child(lab)
		_marker_nodes[str(lm[0])] = [dot, lab]
	for d in DISTRICTS:
		var dlab := Label.new()
		dlab.name = "District_" + str(d[0])
		dlab.text = str(d[0])
		dlab.add_theme_font_size_override("font_size", 22)
		dlab.add_theme_color_override("font_color", d[2])
		_map_area.add_child(dlab)
		_district_nodes[str(d[0])] = dlab
	for w in WATER_LABELS:
		var wdot := ColorRect.new()
		wdot.name = "WaterDot_" + str(w[0]) + "_" + str(int(w[1].x)) + "_" + str(int(w[1].y))
		wdot.size = Vector2(10.0, 10.0)
		wdot.color = Color(0.2, 0.6, 1.0, 1.0)
		_map_area.add_child(wdot)
		var wlab := Label.new()
		wlab.name = "WaterLabel_" + str(w[0]) + "_" + str(int(w[1].x)) + "_" + str(int(w[1].y))
		wlab.text = str(w[0])
		_map_area.add_child(wlab)
		_water_nodes[wdot.name] = [wdot, wlab, w[1]]
	_player_dot = ColorRect.new()
	_player_dot.name = "PlayerDot"
	_player_dot.size = Vector2(18.0, 18.0)
	_player_dot.color = Color(1.0, 0.85, 0.1, 1.0)
	_map_area.add_child(_player_dot)
	_waypoint_dot = ColorRect.new()
	_waypoint_dot.name = "WaypointDot"
	_waypoint_dot.size = Vector2(16.0, 16.0)
	_waypoint_dot.color = Color(1.0, 0.1, 0.1, 1.0)
	_waypoint_dot.visible = false
	_map_area.add_child(_waypoint_dot)
	_waypoint_label = Label.new()
	_waypoint_label.name = "WaypointLabel"
	_waypoint_label.text = "★"
	_waypoint_label.visible = false
	_map_area.add_child(_waypoint_label)
	_info_label = Label.new()
	_info_label.name = "MapInfo"
	_info_label.text = "လမ်းကြောင်း မရှိသေးပါ"
	_info_label.position = Vector2(16.0, 70.0)
	_info_label.size = Vector2(900.0, 40.0)
	add_child(_info_label)
	_close_btn = Button.new()
	_close_btn.name = "CloseBtn"
	_close_btn.text = "✕ ပိတ်"
	_close_btn.position = Vector2(16.0, 120.0)
	_close_btn.size = Vector2(150.0, 64.0)
	_close_btn.pressed.connect(close_map)
	add_child(_close_btn)
	_zoom_in_btn = Button.new()
	_zoom_in_btn.name = "ZoomInBtn"
	_zoom_in_btn.text = "+"
	_zoom_in_btn.position = Vector2(182.0, 120.0)
	_zoom_in_btn.size = Vector2(64.0, 64.0)
	_zoom_in_btn.pressed.connect(_on_zoom_in)
	add_child(_zoom_in_btn)
	_zoom_out_btn = Button.new()
	_zoom_out_btn.name = "ZoomOutBtn"
	_zoom_out_btn.text = "-"
	_zoom_out_btn.position = Vector2(262.0, 120.0)
	_zoom_out_btn.size = Vector2(64.0, 64.0)
	_zoom_out_btn.pressed.connect(_on_zoom_out)
	add_child(_zoom_out_btn)
	_clear_btn = Button.new()
	_clear_btn.name = "ClearBtn"
	_clear_btn.text = "လမ်းကြောင်း ဖျက်"
	_clear_btn.position = Vector2(342.0, 120.0)
	_clear_btn.size = Vector2(220.0, 64.0)
	_clear_btn.pressed.connect(clear_waypoint)
	add_child(_clear_btn)
	# Slice 67 legend: one bottom strip, a child of the overlay so it
	# opens/closes with the map itself (no separate toggle needed).
	# Plain words only — no symbol glyphs the default font may lack.
	_legend_label = Label.new()
	_legend_label.name = "MapLegend"
	_legend_label.text = "အညွှန်း — အဝါ: ကစားသူ • အနီ: လမ်းကြောင်း • အဝါရောင်မျဉ်း: လမ်း • ဘတ်စ်လမ်း • စာတန်း: ခရိုင် / နေရာအမည်"
	_legend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_legend_label)
	_layout()


func _layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_last_vp_size = vp
	var side := minf(vp.x, vp.y) * 0.86
	var top := 200.0
	if _map_area != null:
		_map_area.position = Vector2((vp.x - side) * 0.5, top)
		_map_area.size = Vector2(side, side)
	if _legend_label != null:
		_legend_label.position = Vector2(16.0, vp.y - 40.0)
		_legend_label.size = Vector2(vp.x - 32.0, 32.0)


func _process(_delta: float) -> void:
	if not visible:
		return
	var vp := get_viewport_rect().size
	if vp != _last_vp_size:
		_layout()
	_update_markers()


## Shared transform, documented once (Slice 49): world metres map
## through the shared MapTransform onto the map AREA, in AREA-LOCAL
## coordinates (the dots are children of _map_area, so their
## positions are read in area space — NOT overlay space). Same
## orientation as the minimap (panel x from world x, panel y from
## world z) so the two maps never disagree. Zoom scales about the
## area centre; pan shifts after zoom. The area is square, so the
## fit scale is side/320 and the 320x220 world sits centred with
## void bands top/bottom — the same rendering the Slice 28 square
## region produced, pixel for pixel.
func world_to_map(wx: float, wz: float) -> Vector2:
	if _map_area == null:
		return Vector2.ZERO
	var base := MapTransform.world_to_panel(wx, wz, _map_area.size)
	return _map_area.size * 0.5 + (base - _map_area.size * 0.5) * zoom + pan


## Inverse of world_to_map. Takes AREA-LOCAL coordinates — exactly
## what _gui_input delivers for touches on _map_area (documented
## Godot behaviour: event positions are relative to the control).
## Clamped to the ground rect by MapTransform (see the Slice 49
## header note about the old +-160 z clamp).
func map_to_world(area_pos: Vector2) -> Vector2:
	if _map_area == null:
		return Vector2.ZERO
	if zoom == 0.0:
		return Vector2.ZERO
	var base := _map_area.size * 0.5 + (area_pos - pan - _map_area.size * 0.5) / zoom
	return MapTransform.panel_to_world(base.x, base.y, _map_area.size)


func _world_root() -> Node:
	if _world_root_cache != null and is_instance_valid(_world_root_cache):
		return _world_root_cache
	var cs := get_tree().current_scene
	if cs != null and cs.get_node_or_null("Pagoda") != null:
		_world_root_cache = cs
		return _world_root_cache
	var n: Node = self
	while n != null:
		if n.get_node_or_null("Pagoda") != null:
			_world_root_cache = n
			return _world_root_cache
		n = n.get_parent()
	return null


func _update_markers() -> void:
	var world := _world_root()
	if world == null or _map_area == null:
		return
	for lm in LANDMARKS:
		var node := world.get_node_or_null(str(lm[0])) as Node3D
		if node == null and str(lm[0]).begins_with("BusStop74_"):
			# Slice 84: stop groups live under LongRoute74.
			node = world.get_node_or_null("LongRoute74/" + str(lm[0])) as Node3D
		var pair: Array = _marker_nodes.get(str(lm[0]), [])
		if pair.is_empty():
			continue
		if node == null:
			(pair[0] as ColorRect).visible = false
			(pair[1] as Label).visible = false
			continue
		var p := world_to_map(node.global_position.x, node.global_position.z)
		(pair[0] as ColorRect).visible = true
		(pair[0] as ColorRect).position = p - Vector2(7.0, 7.0)
		(pair[1] as Label).visible = true
		(pair[1] as Label).position = p + Vector2(10.0, -6.0)
	# Slice 87 bus route line, through the same world_to_map
	# (zoom/pan) as the landmark dots: one polyline through
	# the 6 stop positions in west-to-east travel order
	# (Slice 84 Local east order [4, 0, 1, 2, 3, 5]). A
	# marker dot's CENTRE is world_to_map (dots sit at
	# p - (7, 7) with size 14), so these points pass
	# through the stop dot centres exactly. Guidance
	# only — it steers nothing and changes no rule. A
	# missing stop group hides the line rather than
	# drawing a guessed partial route.
	if _route_line != null:
		var rpts: PackedVector2Array = PackedVector2Array()
		var all_found := true
		for g in [4, 0, 1, 2, 3, 5]:
			var gnode := world.get_node_or_null("LongRoute74/BusStop74_%d" % g) as Node3D
			if gnode == null:
				all_found = false
				break
			rpts.append(world_to_map(gnode.global_position.x, gnode.global_position.z))
		_route_line.visible = all_found
		if all_found:
			_route_line.points = rpts
	# Slice 67 region titles + water labels, through the same
	# world_to_map (zoom/pan) as the landmark dots. Titles are
	# centred above their anchor so they read as region titles.
	for d in DISTRICTS:
		var dlab := _district_nodes.get(str(d[0])) as Label
		if dlab == null:
			continue
		var dp := world_to_map(float(d[1].x), float(d[1].y))
		var dw := dlab.get_minimum_size().x
		dlab.position = dp + Vector2(-dw * 0.5, -34.0)
	for key in _water_nodes:
		var trio: Array = _water_nodes.get(key, [])
		if trio.size() < 3:
			continue
		var wp2 := world_to_map(float(trio[2].x), float(trio[2].y))
		(trio[0] as ColorRect).position = wp2 - Vector2(5.0, 5.0)
		(trio[1] as Label).position = wp2 + Vector2(10.0, -6.0)
	var player := world.get_node_or_null("Player") as Node3D
	var area_suffix := ""
	if player != null:
		area_suffix = " • လက်ရှိ: " + district_name_for(player.global_position.x)
	if player != null and _player_dot != null:
		var pp := world_to_map(player.global_position.x, player.global_position.z)
		pp = MapTransform.clamp_dot(pp, _map_area.size, _player_dot.size)
		_player_dot.position = pp
	if _waypoint_dot != null:
		_waypoint_dot.visible = has_waypoint
		_waypoint_label.visible = has_waypoint
		if has_waypoint:
			var wp := world_to_map(waypoint.x, waypoint.y)
			_waypoint_dot.position = wp - Vector2(8.0, 8.0)
			_waypoint_label.position = wp + Vector2(10.0, -6.0)
			if player != null:
				var dx := waypoint.x - player.global_position.x
				var dz := waypoint.y - player.global_position.z
				var dist := sqrt(dx * dx + dz * dz)
				var deg := wrapf(180.0 - rad_to_deg(atan2(-dx, -dz)), 0.0, 360.0)
				_info_label.text = "လမ်းကြောင်း: %d° • %d m (လမ်းညွှန်သာ — လမ်းကြောင်းရှာခြင်း မပါ)%s" % [int(deg), int(dist), area_suffix]
		else:
			_info_label.text = "လမ်းကြောင်း မရှိသေးပါ%s" % area_suffix
	_update_beacon(world)


## The beacon is a real scene node (WaypointBeacon28, tall-scaled window
## box + dedicated red emissive material), NOT created at runtime: a
## runtime-created mesh trips a dummy-renderer warning in headless runs,
## and a scene node is visible to anyone reading the scene. If the node
## is ever missing, the map still works — only the beacon is skipped.
func _update_beacon(world: Node) -> void:
	if _beacon == null:
		_beacon = world.get_node_or_null("WaypointBeacon28") as MeshInstance3D
		if _beacon == null:
			return
	_beacon.visible = has_waypoint
	if has_waypoint:
		_beacon.global_position = Vector3(waypoint.x, 2.5, waypoint.y)


func open_map() -> void:
	_configure_map_bounds()
	was_paused = get_tree().paused
	visible = true
	get_tree().paused = true
	_update_markers()


## Slice 49: second guarantee that the shared transform reads the
## live ground plane (the first is player._ready at spawn). The map
## only ever opens in-game, long after spawn, so this refresh is
## cheap insurance against any _ready ordering change.
func _configure_map_bounds() -> void:
	var world := _world_root()
	if world != null:
		var ground := world.get_node_or_null("GroundMesh") as Node3D
		if ground != null:
			MapTransform.configure_from_ground(ground)


func close_map() -> void:
	visible = false
	get_tree().paused = was_paused


func clear_waypoint() -> void:
	has_waypoint = false
	if _waypoint_dot != null:
		_waypoint_dot.visible = false
	if _waypoint_label != null:
		_waypoint_label.visible = false
	if _beacon != null:
		_beacon.visible = false
	_info_label.text = "လမ်းကြောင်း မရှိသေးပါ"


## Slice 49 contract: screen_pos is AREA-LOCAL (what _gui_input
## delivers for touches on _map_area). The caller passes the touch
## position unchanged; map_to_world no longer treats it as overlay
## coordinates, so a tap now lands where the finger actually is.
func set_waypoint_from_screen(screen_pos: Vector2) -> void:
	waypoint = map_to_world(screen_pos)
	has_waypoint = true
	_update_markers()


func _on_zoom_in() -> void:
	zoom = clampf(zoom * 1.25, MIN_ZOOM, MAX_ZOOM)
	_update_markers()


func _on_zoom_out() -> void:
	zoom = clampf(zoom / 1.25, MIN_ZOOM, MAX_ZOOM)
	_update_markers()


func _on_map_area_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press_pos = touch.position
			_press_pan = pan
			_dragging = false
		else:
			if not _dragging and _press_pos.distance_to(touch.position) <= TAP_SLOP_PX:
				set_waypoint_from_screen(touch.position)
			_dragging = false
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _press_pos.distance_to(drag.position) > TAP_SLOP_PX:
			_dragging = true
			pan = _press_pan + (drag.position - _press_pos)
			_update_markers()
