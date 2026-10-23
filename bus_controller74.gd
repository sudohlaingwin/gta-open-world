extends Node3D
## Slice 74 — bus stop controller (companion to bus_sim74.gd).
## Runs on the world root as BusSim74. Every frame it:
## - shows the touch-first "🚪 တံခါး" door button and the
##   "🚌 N" boarded-count label ONLY while the player is
##   driving the bus (hidden on foot and in every other
##   vehicle, so it can never clutter the Slice 61 HUD);
## - on the rising edge of the bus door opening, serves the
##   nearest stop, but ONLY when the bus is properly stopped
##   (speed under 0.5 m/s inside the 9 m stop zone): a
##   drive-by with the door open boards nobody, and a
##   door opened far from any stop serves nothing;
## - serving a stop alights first, then boards: boarded
##   passengers get off (count to zero, 2 figures appear at
##   that stop) and the stop's waiting passengers get on
##   (figures hidden, count rises). Alighted figures are
##   named Alighted74_*, so a later door-open at the same
##   stop never re-boards them as waiting passengers.
## The door itself lives on the bus (bus.gd toggle_door);
## this controller only READS door_open, never drives the
## bus. No money/economy: boarding is a count, not a fare.

var boarded: int = 0
var _prev_door_open: bool = false

const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0]
const STOP_ZONE_R: float = 9.0
const STOP_SPEED: float = 0.5


func _stop_pos(world: Node3D, idx: int) -> Vector3:
	var grp := world.get_node_or_null("LongRoute74/BusStop74_%d" % idx) as Node3D
	if grp != null:
		return grp.global_position
	return Vector3(STOPS_X[idx], 0.0, 0.0)


func _serve_stop(world: Node3D, bus: Node3D, stop_idx: int) -> void:
	# Alight first: boarded passengers leave at this stop.
	if boarded > 0:
		boarded = 0
		var grp := world.get_node_or_null("LongRoute74/BusStop74_%d" % stop_idx) as Node3D
		if grp != null:
			for ai in range(2):
				if grp.get_node_or_null("Alighted74_%d_%d" % [stop_idx, ai]) != null:
					continue
				var body_m := StandardMaterial3D.new()
				body_m.albedo_color = Color(0.9, 0.85, 0.7, 1.0)
				var head_m := StandardMaterial3D.new()
				head_m.albedo_color = Color(0.8, 0.6, 0.45, 1.0)
				var g := Node3D.new()
				g.name = "Alighted74_%d_%d" % [stop_idx, ai]
				g.position = Vector3(-4.0 + float(ai) * 2.0, 0.0, 10.5)
				grp.add_child(g)
				var b := MeshInstance3D.new()
				b.name = "Body74"
				var bm := CylinderMesh.new()
				bm.top_radius = 0.28
				bm.bottom_radius = 0.28
				bm.height = 1.1
				b.mesh = bm
				b.position = Vector3(0.0, 0.55, 0.0)
				b.set_surface_override_material(0, body_m)
				g.add_child(b)
				var h := MeshInstance3D.new()
				h.name = "Head74"
				var hm := SphereMesh.new()
				hm.radius = 0.22
				hm.height = 0.44
				h.mesh = hm
				h.position = Vector3(0.0, 1.35, 0.0)
				h.set_surface_override_material(0, head_m)
				g.add_child(h)
	# Then board: every still-visible waiting passenger at
	# this stop gets on (their group is hidden, never freed,
	# so a later inspection can still count the stop).
	var grp2 := world.get_node_or_null("LongRoute74/BusStop74_%d" % stop_idx) as Node3D
	if grp2 == null:
		return
	for wi in range(2):
		var w := grp2.get_node_or_null("Waiting74_%d_%d" % [stop_idx, wi]) as Node3D
		if w != null and w.visible:
			w.visible = false
			boarded += 1


func _process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var bus := world.get_node_or_null("Bus") as Node3D
	var player := world.get_node_or_null("Player") as Node3D
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	var driving_bus := false
	if bus != null and player != null:
		driving_bus = bool(player.get("driving")) and player.get("driving_vehicle") == bus
	if layer != null:
		var dbtn := layer.get_node_or_null("DoorButton74") as Button
		if dbtn != null:
			dbtn.visible = driving_bus
		var blab := layer.get_node_or_null("BoardLabel74") as Label
		if blab != null:
			blab.visible = driving_bus
			blab.text = "🚌 %d" % boarded
	if bus == null or not driving_bus:
		_prev_door_open = false
		return
	var door_open := bool(bus.get("door_open"))
	var speed := 0.0
	if bus.get("speed") != null:
		speed = absf(float(bus.get("speed")))
	# Rising edge only: holding the door open must not
	# re-board every frame, and a door opened while moving
	# must not serve a stop the bus rolls past.
	if door_open and not _prev_door_open and speed < STOP_SPEED:
		var bp := (bus as Node3D).global_position
		var best := -1
		var best_d := STOP_ZONE_R
		for si in range(STOPS_X.size()):
			var sp := _stop_pos(world, si)
			var d := Vector2(bp.x - sp.x, bp.z - sp.z).length()
			if d < best_d:
				best_d = d
				best = si
		if best >= 0:
			_serve_stop(world, bus, best)
	_prev_door_open = door_open
