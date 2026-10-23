extends Node3D
## Slice 82 — BUS SIMULATION, part 9 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 9).
## What it builds, all runtime-only, NO scene touched:
## - DEPOT OFFICE: a small office building north of the parked
##   buses (walls, pitched roof, door, windows, steps). Visual
##   only — NOT enterable, stated plainly, no interior.
## - FUEL PUMP (visual only): a pump prop south-east of the
##   yard with a real-Noto Myanmar label ("ဆီ"). NO
##   refuelling system, NO fuel gauge, NO economy invented.
## - NIGHT DEPOT LIGHTING: two lamp posts with real
##   OmniLights gated by the Slice 57 night rule (daylight
##   < 0.15), applied immediately when this node enters the
##   tree AND on every daylight change (Slice 76 lesson: a
##   world starting at night must not run dark until the
##   first transition). The lamp FIXTURES are props; only the
##   LIGHTS are gated, stated plainly.
## - DEPOT FENCE: a low fence marking the yard (north and
##   south sides full, west side with a 12 m entrance gap,
##   east side fully open as the bus exit). Visual only,
##   ZERO colliders, so nothing here blocks a road, a lane,
##   a footpath, or a vehicle entry — the open sides are the
##   entrances, stated as the tradeoff.
## All dressing lives under this one BusSim82 group node at
## the world origin, so positions below are world positions.
## The Slice 81 honest limit stands unchanged: the minibus
## is a free-drive fleet vehicle, NOT rewired into the route
## system in this slice either.
## No opponent code, map, names or structure is used.
## Touch-first throughout (no keys anywhere).

const OFFICE_POS: Vector3 = Vector3(30.0, 0.0, 6.0)
const FUEL_POS: Vector3 = Vector3(40.0, 0.0, 32.0)
const LAMP_POS: Array = [Vector3(22.0, 0.0, 10.0), Vector3(38.0, 0.0, 30.0)]
const FUEL_LABEL_TEXT: String = "ဆီ"

var _lamps: Array = []
var _last_night: bool = false
var _lamps_applied: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim82") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim82"
	n.set_script(load("res://bus_sim82.gd"))
	world.call_deferred("add_child", n)
	_build_office(n)
	_build_fuel_pump(n)
	_build_lamps(n)
	_build_fence(n)


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


static func _build_office(group: Node3D) -> void:
	var g := Node3D.new()
	g.name = "DepotOffice82"
	g.position = OFFICE_POS
	group.add_child(g)
	var wall_m := _mat(Color(0.9, 0.85, 0.75, 1.0), 0.95)
	var roof_m := _mat(Color(0.55, 0.2, 0.15, 1.0), 0.7)
	var wood_m := _mat(Color(0.4, 0.25, 0.12, 1.0), 0.9)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.1, 0.2, 0.3, 0.45)
	glass.roughness = 0.1
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(g, "OfficeWalls82", Vector3(8.0, 3.2, 5.0), Vector3(0.0, 1.6, 0.0), wall_m)
	var slab_s := _box(g, "OfficeRoofS82", Vector3(8.6, 0.15, 3.0), Vector3(0.0, 3.65, 1.25), roof_m)
	slab_s.rotation.x = 0.35
	var slab_n := _box(g, "OfficeRoofN82", Vector3(8.6, 0.15, 3.0), Vector3(0.0, 3.65, -1.25), roof_m)
	slab_n.rotation.x = -0.35
	_box(g, "OfficeRidge82", Vector3(8.6, 0.2, 0.3), Vector3(0.0, 4.15, 0.0), roof_m)
	_box(g, "OfficeDoor82", Vector3(1.0, 2.1, 0.1), Vector3(0.0, 1.05, 2.55), wood_m)
	_box(g, "OfficeWinS82_0", Vector3(1.2, 1.0, 0.08), Vector3(-2.5, 1.8, 2.54), glass)
	_box(g, "OfficeWinS82_1", Vector3(1.2, 1.0, 0.08), Vector3(2.5, 1.8, 2.54), glass)
	_box(g, "OfficeWinE82", Vector3(0.08, 1.0, 1.2), Vector3(4.04, 1.8, 0.0), glass)
	_box(g, "OfficeSteps82", Vector3(1.6, 0.15, 0.7), Vector3(0.0, 0.075, 2.9), _mat(Color(0.6, 0.6, 0.6, 1.0), 1.0))


static func _build_fuel_pump(group: Node3D) -> void:
	var g := Node3D.new()
	g.name = "FuelPump82"
	g.position = FUEL_POS
	group.add_child(g)
	_box(g, "PumpBase82", Vector3(0.9, 0.15, 0.7), Vector3(0.0, 0.075, 0.0), _mat(Color(0.6, 0.6, 0.6, 1.0), 1.0))
	_box(g, "PumpBody82", Vector3(0.7, 1.5, 0.5), Vector3(0.0, 0.9, 0.0), _mat(Color(0.8, 0.15, 0.15, 1.0), 0.6))
	_box(g, "PumpCap82", Vector3(0.8, 0.12, 0.6), Vector3(0.0, 1.71, 0.0), _mat(Color(0.95, 0.95, 0.95, 1.0), 0.5))
	_box(g, "PumpNozzle82", Vector3(0.12, 0.3, 0.12), Vector3(0.42, 1.0, 0.0), _mat(Color(0.15, 0.15, 0.15, 1.0), 0.6))
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	if font == null:
		push_error("BusSim82: Myanmar font failed to load, fuel label skipped")
	else:
		var lab := Label3D.new()
		lab.name = "FuelLabel82"
		lab.text = FUEL_LABEL_TEXT
		lab.font = font
		lab.font_size = 40
		lab.pixel_size = 0.012
		lab.position = Vector3(0.0, 1.1, -0.28)
		lab.rotation.y = PI
		lab.double_sided = true
		g.add_child(lab)


static func _build_lamps(group: Node3D) -> void:
	var post_m := _mat(Color(0.25, 0.25, 0.28, 1.0), 0.6)
	var head_m := StandardMaterial3D.new()
	head_m.albedo_color = Color(1.0, 0.9, 0.6, 1.0)
	head_m.emission_enabled = true
	head_m.emission = Color(1.0, 0.85, 0.6, 1.0)
	head_m.emission_energy_multiplier = 1.2
	for li in range(LAMP_POS.size()):
		var g := Node3D.new()
		g.name = "DepotLamp82_%d" % li
		g.position = LAMP_POS[li]
		group.add_child(g)
		_cyl(g, "LampPost82_%d" % li, 0.09, 0.09, 3.5, Vector3(0.0, 1.75, 0.0), post_m)
		_box(g, "LampHead82_%d" % li, Vector3(0.35, 0.2, 0.35), Vector3(0.0, 3.6, 0.0), head_m)
		var light := OmniLight3D.new()
		light.name = "LampLight82_%d" % li
		light.position = Vector3(0.0, 3.45, 0.0)
		light.omni_range = 12.0
		light.light_energy = 1.2
		light.light_color = Color(1.0, 0.85, 0.6, 1.0)
		light.visible = false
		g.add_child(light)


static func _fence_run(group: Node3D, idx: int, along_z: bool, fixed: float, from_v: float, to_v: float, skip_first: bool, skip_last: bool) -> int:
	var post_m := _mat(Color(0.45, 0.3, 0.15, 1.0), 0.9)
	var rail_m := _mat(Color(0.5, 0.35, 0.18, 1.0), 0.9)
	var posts: Array = []
	var v := from_v
	while v <= to_v + 0.001:
		posts.append(v)
		v += 4.0
	if posts[posts.size() - 1] < to_v - 0.001:
		posts.append(to_v)
	var start := 0
	if skip_first:
		start = 1
	var end := posts.size()
	if skip_last:
		end -= 1
	for pi in range(start, end):
		var pv: float = posts[pi]
		var pos := Vector3(fixed, 0.55, pv) if along_z else Vector3(pv, 0.55, fixed)
		_box(group, "FencePost82_%d" % idx, Vector3(0.14, 1.1, 0.14), pos, post_m)
		idx += 1
	for si in range(posts.size() - 1):
		var a: float = posts[si]
		var b: float = posts[si + 1]
		var mid := (a + b) * 0.5
		var ln := b - a
		for ry in [0.5, 0.95]:
			var size := Vector3(0.08, 0.08, ln) if along_z else Vector3(ln, 0.08, 0.08)
			var pos := Vector3(fixed, ry, mid) if along_z else Vector3(mid, ry, fixed)
			_box(group, "FenceRail82_%d" % idx, size, pos, rail_m)
			idx += 1
	return idx


static func _build_fence(group: Node3D) -> void:
	var g := Node3D.new()
	g.name = "DepotFence82"
	group.add_child(g)
	var idx := 0
	idx = _fence_run(g, idx, false, 0.0, 18.0, 46.0, false, false)
	idx = _fence_run(g, idx, false, 38.0, 18.0, 46.0, false, false)
	idx = _fence_run(g, idx, true, 18.0, 0.0, 12.0, true, false)
	idx = _fence_run(g, idx, true, 18.0, 28.0, 38.0, false, true)


func _daylight() -> float:
	var world := get_parent() as Node3D
	if world == null:
		return 1.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		return float(dn.call("daylight"))
	return 1.0


func _apply_lamps() -> void:
	var night := _daylight() < 0.15
	for light in _lamps:
		if light is Light3D:
			(light as Light3D).visible = night
	_last_night = night
	_lamps_applied = true


func _ready() -> void:
	for li in range(LAMP_POS.size()):
		var lamp := get_node_or_null("DepotLamp82_%d" % li)
		if lamp != null:
			var light := lamp.get_node_or_null("LampLight82_%d" % li)
			if light != null:
				_lamps.append(light)
	_apply_lamps()


func _physics_process(_delta: float) -> void:
	var night := _daylight() < 0.15
	if not _lamps_applied or night != _last_night:
		_apply_lamps()
