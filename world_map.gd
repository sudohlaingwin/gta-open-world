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
## Pause bookkeeping: opening records whether the tree was already
## paused and closing restores exactly that state (never unpauses
## unconditionally). The panel uses pause_mode always (set in the scene)
## so its buttons work while the tree is paused.
extends Control

const WORLD_HALF: float = 160.0
const WORLD_SPAN: float = 320.0
const WORLD_CENTER_X: float = 90.0
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
var _close_btn: Button = null
var _zoom_in_btn: Button = null
var _zoom_out_btn: Button = null
var _clear_btn: Button = null
var _marker_nodes: Dictionary = {}
var _player_dot: ColorRect = null
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
]


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
	_zoom_in_btn.text = "＋"
	_zoom_in_btn.position = Vector2(182.0, 120.0)
	_zoom_in_btn.size = Vector2(64.0, 64.0)
	_zoom_in_btn.pressed.connect(_on_zoom_in)
	add_child(_zoom_in_btn)
	_zoom_out_btn = Button.new()
	_zoom_out_btn.name = "ZoomOutBtn"
	_zoom_out_btn.text = "－"
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


func _process(_delta: float) -> void:
	if not visible:
		return
	var vp := get_viewport_rect().size
	if vp != _last_vp_size:
		_layout()
	_update_markers()


## Shared transform, documented once: world metres (-50..50 on x/z) map
## linearly onto the square map area, scaled by zoom and shifted by pan.
## Same orientation as the minimap (panel x from world x, panel y from
## world z) so the two maps never disagree.
func world_to_map(wx: float, wz: float) -> Vector2:
	if _map_area == null:
		return Vector2.ZERO
	var scale := (_map_area.size.x / WORLD_SPAN) * zoom
	var center := _map_area.position + _map_area.size * 0.5
	return center + Vector2(wx - WORLD_CENTER_X, wz) * scale + pan


func map_to_world(screen_pos: Vector2) -> Vector2:
	if _map_area == null:
		return Vector2.ZERO
	var scale := (_map_area.size.x / WORLD_SPAN) * zoom
	if scale <= 0.0:
		return Vector2.ZERO
	var center := _map_area.position + _map_area.size * 0.5
	var w := (screen_pos - center - pan) / scale
	return Vector2(clampf(w.x + WORLD_CENTER_X, WORLD_CENTER_X - WORLD_HALF, WORLD_CENTER_X + WORLD_HALF), clampf(w.y, -WORLD_HALF, WORLD_HALF))


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
	var player := world.get_node_or_null("Player") as Node3D
	if player != null and _player_dot != null:
		var pp := world_to_map(player.global_position.x, player.global_position.z)
		pp.x = clampf(pp.x, _map_area.position.x, _map_area.position.x + _map_area.size.x - 18.0)
		pp.y = clampf(pp.y, _map_area.position.y, _map_area.position.y + _map_area.size.y - 18.0)
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
				_info_label.text = "လမ်းကြောင်း: %d° • %d m (လမ်းညွှန်သာ — လမ်းကြောင်းရှာခြင်း မပါ)" % [int(deg), int(dist)]
		else:
			_info_label.text = "လမ်းကြောင်း မရှိသေးပါ"
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
	was_paused = get_tree().paused
	visible = true
	get_tree().paused = true
	_update_markers()


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
