extends Node3D
## Slice 84 — BUS SIMULATION, part 11 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 11).
## FULL-LENGTH ROUTE: the Slice 75 route ran 4 stops
## (x 700 / 1200 / 1700 / 2200). It now runs the whole
## 2 km road end to end with 6 stops: this node adds the
## two missing endpoints — x 500 (road start) and x 2400
## (road end) — with the FULL Slice 74 / 77 treatment
## (shelter, sign board + Label3D in the real Noto font,
## painted zone, bench + markings + timetable board +
## night lamp via the Slice 77 loop, waiting passengers
## with destinations, minimap dot).
##
## GROUP-INDEX MODEL (read this before touching stop code):
## existing groups BusStop74_0..3 keep their identities
## and x positions FOREVER, so old saves stay valid with
## zero migration: group 0 is still x 700, group 3 still
## x 2200. The two new groups are APPENDED as group 4
## (x 500) and group 5 (x 2400) — NOT inserted at the
## front, which would have renumbered every old stop and
## broken every saved route. Travel order is therefore
## east [4, 0, 1, 2, 3, 5] and west [5, 3, 2, 1, 0, 4]
## (bus_controller74.gd service_order79 owns it).
## PLAYER-FACING stop numbers are TRAVEL POSITIONS
## (1..6 west to east), never group indices: group 4 is
## stop 1, group 0 is stop 2, ..., group 5 is stop 6.
## Every display (destination sign, route label, timetable
## label, announcement, request label, feedback, boards,
## physical signs, map labels) uses the position digit.
## This node re-texts the 4 old physical signs to their
## position digits (group 0 -> 2, 1 -> 3, 2 -> 4, 3 -> 5)
## so a sign on the roadside never disagrees with the HUD.
##
## SCOPE FIXES (pre-existing gaps this slice closes, so
## the new stops actually show on the maps):
## - world-map stop dots never resolved: world_map.gd
##   looked up "BusStop74_N" as a direct world child, but
##   the groups live under LongRoute74, so every dot was
##   hidden. world_map.gd now falls back to the
##   LongRoute74 path (plus 2 new landmark entries).
## - minimap stop dots were created (Slice 74) but nothing
##   ever positioned them, so they sat at the panel
##   corner. bus_controller74.gd now positions all 6
##   dots every frame from the group positions.
## The Slice 81 honest limit stands unchanged: the minibus
## is a free-drive fleet vehicle and is NOT rewired into
## the route system in this slice either. No opponent code,
## map, names or structure is used. Touch-first throughout
## (nothing here needs a button at all).

# New stops, group-indexed like the controller's STOPS_X.
const NEW_STOPS: Array = [
	[4, 500.0],
	[5, 2400.0],
]
# Travel-position digit per GROUP index (position 1..6).
const POS_DIGIT: Dictionary = {4: "၁", 0: "၂", 1: "၃", 2: "၄", 3: "၅", 5: "၆"}
# Destinations for the new stops' 3 seats, same shape as
# the controller DESTS table: [destination group, direction]
# (0 = east, 1 = west). Group 4 (west terminus) rides east
# only; group 5 (east terminus) rides west only. Dests 5
# (from 4) and 4 (from 5) are the Express endpoints, so
# those seats board Express; the others are Local-only.
const NEW_DESTS: Dictionary = {
	4: [[0, 0], [1, 0], [5, 0]],
	5: [[3, 1], [0, 1], [4, 1]],
}

var _done: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim84") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim84"
	n.set_script(load("res://bus_sim84.gd"))
	world.call_deferred("add_child", n)


static func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


static func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi


static func _cyl(parent: Node3D, nm: String, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = h
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi


static func _sphere(parent: Node3D, nm: String, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi


func _build_stop(route: Node3D, idx: int, x: float, font: Font, shelter_m: Material, post_m: Material, board_m: Material, zone_m: Material, body_mats: Array, head_m: Material) -> void:
	# Same layout as Slice 74 _stop (group origin IS the
	# stop point; shelter + sign on the south side, clear
	# of the slab and curbs). 3 waiting passengers: seats
	# 0/1 at the Slice 74 spots, seat 2 at the Slice 83
	# bench-middle spot — Slice 78 seats all three.
	var g := Node3D.new()
	g.name = "BusStop74_%d" % idx
	g.position = Vector3(x, 0.0, 0.0)
	route.add_child(g)
	_box(g, "Zone74", Vector3(18.0, 0.02, 10.0), Vector3(0.0, 0.14, 4.0), zone_m)
	_cyl(g, "ShelterPost74A", 0.12, 0.12, 2.2, Vector3(-3.0, 1.1, 10.5), post_m)
	_cyl(g, "ShelterPost74B", 0.12, 0.12, 2.2, Vector3(3.0, 1.1, 10.5), post_m)
	_box(g, "ShelterRoof74", Vector3(7.0, 0.15, 3.0), Vector3(0.0, 2.3, 10.5), shelter_m)
	_cyl(g, "SignPost74", 0.1, 0.1, 2.0, Vector3(0.0, 1.0, 8.5), post_m)
	_box(g, "SignBoard74", Vector3(4.0, 1.0, 0.12), Vector3(0.0, 2.2, 8.5), board_m)
	if font != null:
		var lab := Label3D.new()
		lab.name = "SignLabel74"
		lab.text = "ဘတ်စ်ကား မှတ်တိုင် " + str(POS_DIGIT[idx])
		lab.font = font
		lab.font_size = 32
		lab.pixel_size = 0.012
		lab.position = Vector3(0.0, 2.2, 8.42)
		lab.rotation.y = PI
		lab.double_sided = true
		g.add_child(lab)
	else:
		push_error("BusSim84: Myanmar font failed to load, stop label skipped")
	var seat_x: Array = [-2.0, 2.0, 0.0]
	var dests: Array = NEW_DESTS[idx]
	for wi in range(3):
		var w := Node3D.new()
		w.name = "Waiting74_%d_%d" % [idx, wi]
		w.position = Vector3(seat_x[wi], 0.0, 10.5)
		g.add_child(w)
		_cyl(w, "Body74", 0.28, 0.28, 1.1, Vector3(0.0, 0.55, 0.0), body_mats[wi])
		_sphere(w, "Head74", 0.22, Vector3(0.0, 1.35, 0.0), head_m)
		# Meta now, like Slice 83: the controller's first
		# frame may already have run before this group
		# exists, so a meta-less rider must never happen.
		w.set_meta("dest75", dests[wi][0])
		w.set_meta("dir75", dests[wi][1])


func _try_build(world: Node3D) -> bool:
	var route := world.get_node_or_null("LongRoute74") as Node3D
	if route == null:
		return false
	var shelter_m := _mat(Color(0.3, 0.5, 0.7, 1.0), 0.8)
	var post_m := _mat(Color(0.4, 0.4, 0.42, 1.0), 0.6)
	var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
	var zone_m := _mat(Color(0.95, 0.8, 0.2, 1.0), 0.8)
	var body_a := _mat(Color(0.95, 0.95, 0.9, 1.0), 0.9)
	var body_b := _mat(Color(0.2, 0.5, 0.8, 1.0), 0.9)
	var body_c := _mat(Color(0.85, 0.6, 0.2, 1.0), 0.9)
	var skin_m := _mat(Color(0.8, 0.6, 0.45, 1.0), 0.9)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	for entry in NEW_STOPS:
		var idx: int = entry[0]
		var x: float = entry[1]
		if route.get_node_or_null("BusStop74_%d" % idx) == null:
			_build_stop(route, idx, x, font, shelter_m, post_m, board_m, zone_m, [body_a, body_b, body_c], skin_m)
	# Re-text the 4 old physical signs to their travel
	# positions (idempotent: setting the same text twice
	# changes nothing, so a retry is harmless).
	for old in [0, 1, 2, 3]:
		var grp := route.get_node_or_null("BusStop74_%d" % old) as Node3D
		if grp == null:
			return false
		var lab := grp.get_node_or_null("SignLabel74") as Label3D
		if lab != null:
			lab.text = "ဘတ်စ်ကား မှတ်တိုင် " + str(POS_DIGIT[old])
	# Minimap dots for the 2 new stops (Slice 74 pattern:
	# blue 8x8; positioning + tinting live in the
	# controller, which now covers all 6 stops).
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer != null:
		var panel := layer.get_node_or_null("MinimapPanel") as Control
		if panel != null:
			for entry in NEW_STOPS:
				var dname := "BusStop74_%d" % entry[0]
				if panel.get_node_or_null(dname) == null:
					var dot := ColorRect.new()
					dot.name = dname
					dot.color = Color(0.2, 0.6, 1.0, 1.0)
					dot.size = Vector2(8.0, 8.0)
					panel.add_child(dot)
	return true


func _physics_process(_delta: float) -> void:
	if _done:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	_done = _try_build(world)
