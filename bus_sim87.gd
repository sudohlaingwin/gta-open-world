extends Node3D
## Slice 87 — BUS SIMULATION, part 14 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 14).
## ROUTE DRAWN ON THE MAPS: the 6-stop bus route becomes visible
## on both maps, so the player can see the whole service at a
## glance instead of only the next stop. One highlighted
## polyline runs through the 6 stop positions in west-to-east
## travel order (the Slice 84 Local east order
## [4, 0, 1, 2, 3, 5], x 500..2400); the westbound order is
## the same 6 points reversed, so the line geometry is
## identical in both directions — one line, not two.
## The line is GUIDANCE ONLY: it does not steer the bus,
## route the player, or change any service rule (Local vs
## Express, dues, boarding, and the Slice 78 depot return
## are untouched — stated plainly).
## Minimap half: a Line2D child of JoystickLayer/MinimapPanel
## (Slice 61 road-line pattern: same MapTransform mapping,
## same panel). Points are the live stop-dot CENTRES, not
## approximations: the Slice 84 controller positions each
## stop dot at clamp_dot(world_to_panel(...), size, 8x8)
## (top-left corner), so the line point is that corner
## plus (4, 4). The line is moved to child index 0 so the
## dots draw on top of it. Tint is exactly the Slice 75
## next-stop-dot yellow (1.0, 0.85, 0.2), distinct from the
## Slice 61 road yellow (0.95, 0.85, 0.4).
## World-map half: the line itself lives in world_map.gd
## (created in _build_ui, refreshed in _update_markers
## beside the landmark dots, so zoom and pan move it for
## free); this node does not touch the overlay. There the
## points are world_to_map(stop) exactly — the same
## transform the marker dots use, and a marker dot's
## CENTRE is world_to_map (dots sit at p - (7, 7) with
## size 14), so the line passes through the dot centres.
## Stop positions are read live from the stop groups
## (controller _stop_pos, LongRoute74 path) with the
## STOPS_X fallback only before the groups exist — never
## a hardcoded canvas offset. No money, no economy, no new
## HUD label, no new save key. The Slice 81 honest limit
## stands unchanged: the minibus is a free-drive fleet
## vehicle and is NOT rewired into the route system in
## this slice either. No opponent code, map, names or
## structure is used. Touch-first throughout (nothing
## here needs a button at all).

# West-to-east travel order (Slice 84 Local east order).
# Group indices, NOT positions: group 4 = x 500, group 5
# = x 2400 (appended by Slice 84, never renumbering).
const ROUTE_ORDER: Array = [4, 0, 1, 2, 3, 5]
# Group-indexed stop x, same table as the controller
# (bus_controller74.gd STOPS_X) — fallback only, used
# solely before the stop groups exist in the tree.
const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0, 500.0, 2400.0]
const ROUTE_YELLOW: Color = Color(1.0, 0.85, 0.2, 1.0)
const MINIMAP_LINE_WIDTH: float = 2.0
const DOT_SIZE: Vector2 = Vector2(8.0, 8.0)


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim87") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim87"
	n.set_script(load("res://bus_sim87.gd"))
	world.call_deferred("add_child", n)


func _stop_world_pos(world: Node3D, idx: int) -> Vector3:
	# Controller first (single source of truth for stop
	# positions); local table only if the controller
	# node is not in the tree yet.
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	if ctrl != null and ctrl.has_method("_stop_pos"):
		return ctrl.call("_stop_pos", world, idx) as Vector3
	return Vector3(STOPS_X[idx], 0.0, 0.0)


func _physics_process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return
	var panel := layer.get_node_or_null("MinimapPanel") as Control
	if panel == null:
		return
	# The controller positions dots from panel.size
	# directly (no fallback); the line uses the same
	# size, so line and dots can never disagree. Before
	# layout gives the panel a size, there is nothing
	# truthful to draw yet — skip, do not guess.
	if panel.size.x <= 0.0 or panel.size.y <= 0.0:
		return
	var line := panel.get_node_or_null("BusRouteLine87") as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "BusRouteLine87"
		line.width = MINIMAP_LINE_WIDTH
		line.default_color = ROUTE_YELLOW
		panel.add_child(line)
		# Behind every dot: dots stay fully readable,
		# the line emerges from behind them.
		panel.move_child(line, 0)
	var pts: PackedVector2Array = PackedVector2Array()
	for g in ROUTE_ORDER:
		var sp := _stop_world_pos(world, int(g))
		var pp := MapTransform.world_to_panel(sp.x, sp.z, panel.size)
		var cp := MapTransform.clamp_dot(pp, panel.size, DOT_SIZE)
		pts.append(cp + DOT_SIZE * 0.5)
	if line.points != pts:
		line.points = pts
