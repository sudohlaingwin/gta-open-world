extends Node3D
## Slice 98 VEHICLE DRESSING + SHEET PEOPLE DETAIL + WORLD / NIGHT POLISH
## (owner standing rules: ~50 items per push, graphics-first).
## Audit-first batch: every item below was grep/probe-proven
## missing — motorcycle has no taillight/kickstand/chain
## guard/forks/saddlebags, the tuk-tuk canopy has NO posts
## (it floats at y 1.15), the bicycle has no basket/rack/
## fenders/bell/pedals, the boat has no rope/lantern/basket,
## the cart has no yoke/sacks/lantern, the horse has no
## bridle/reins, the elephant has no howdah blanket/bell,
## the helicopter has no tail fin/glass, the airplane has no
## cockpit glass/struts/nav lights, neither bus has bumpers;
## people: males have no longyi waistband, female A has no
## longyi side panel, female B has no sleeve cuffs (all
## sheet features the S94/S95/S97 passes never reached);
## world: school has no flag, zayat has no prayer mats,
## monastery bell has no offering table, the well has no
## pulley/rope, the S96/S97 extension has no bamboo groves
## or rock outcrops; night: the extension has lamps only
## at (1000,-14)/(2000,-14) — none along the east dirt
## track, the S97 tree sites, the west pond or the hamlet
## spur. Runtime dressing ONLY. No .tscn edits, no bus-
## system changes, minibus NOT rewired, big bus NOT
## rewired (Slice 81 binding limit — bus bumpers below
## are children of the Bus node, they move with it, they
## do not touch the controller), touch controls untouched,
## zero colliders on new dressing, StandardMaterial3D
## only, no dead specular lines, no fog/SSAO/glow claims
## (no WorldEnvironment exists), no photorealism claims:
## stylised smooth procedural rebuilds, stated plainly.
## Runs at frame >= 160: after Slice 70 (12), Slice 73
## (26), Slice 93 (40), Slice 94 (60), Slice 95 (80),
## Slice 95b realism96 (100), Slice 96 scale97 (120) and
## Slice 97 realism98 (140), so every position below is
## read off FINAL geometry.
## Counting: one item = one placed assembly, or one
## symmetric pair / one set of identical parts on one
## figure, vehicle, building or site. 64 items:
##   PEOPLE 19: male waistband x10, female-A side
##     panel x4, female-B cuff pair x5
##   VEHICLES 30: moto 5, tuk-tuk 4, bicycle 5, boat 3,
##     cart 3, horse 1, elephant 2, helicopter 2,
##     airplane 3, bus bumpers 1, minibus bumpers 1
##   WORLD 9: school flag 1, zayat mats 1, monastery
##     table 1, well pulley 1, bamboo groves 3, rocks 2
##   NIGHT 6: extension lamps x6 (gated every frame)

static func _mat(c: Color, rough: float, met: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = met
	return m

static func _glow_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 1.2
	m.roughness = 1.0
	return m

static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node3D, r: float, mat: Material, pos: Vector3, nm: String, sy: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0 * sy
	mi.mesh = sm
	mi.position = pos
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _holder(parent: Node3D, pos: Vector3, nm: String) -> Node3D:
	var g := Node3D.new()
	g.name = nm
	g.position = pos
	parent.add_child(g)
	return g

static func _find_rec(n: Node, nm: String) -> Node:
	if n.name == nm:
		return n
	for c in n.get_children():
		var r := _find_rec(c, nm)
		if r != null:
			return r
	return null

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism99") != null:
		return
	var n := Node3D.new()
	n.name = "Realism99"
	n.set_script(load("res://realism99.gd"))
	world.call_deferred("add_child", n)

var _frames: int = 0
var _done: bool = false
var _lantern_omnis: Array = []
var _lantern_heads: Array = []

func _process(_delta: float) -> void:
	_frames += 1
	if _frames < 160 or _done:
		if _done:
			_gate_lanterns()
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	_people(world)
	_vehicles(world)
	_world_dress(world)
	_night(world)
	_done = true
	_gate_lanterns()

func _daylight(world: Node3D) -> float:
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		return float(dn.call("daylight"))
	return 1.0

func _gate_lanterns() -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var night := _daylight(world) < 0.15
	for o in _lantern_omnis:
		(o as OmniLight3D).visible = night
	for h in _lantern_heads:
		(h as MeshInstance3D).visible = night

func _lantern(parent: Node3D, pos: Vector3, nm: String, energy: float, rng: float) -> void:
	var pole_m := _mat(Color(0.20, 0.16, 0.12, 1.0), 0.9)
	_cyl(parent, 0.06, 0.06, 2.2, pole_m, pos + Vector3(0.0, 1.1, 0.0), nm + "_Pole")
	var head := _box(parent, Vector3(0.30, 0.30, 0.30), _glow_mat(Color(1.0, 0.75, 0.4, 1.0)), pos + Vector3(0.0, 2.30, 0.0), nm + "_Head")
	var o := OmniLight3D.new()
	o.name = nm + "_Omni"
	o.position = pos + Vector3(0.0, 2.30, 0.0)
	o.light_energy = energy
	o.omni_range = rng
	o.light_color = Color(1.0, 0.75, 0.45, 1.0)
	parent.add_child(o)
	_lantern_omnis.append(o)
	_lantern_heads.append(head)

static func _people(world: Node3D) -> void:
	# Sex markers from Slice 94 (same hash split as S95):
	# male = Collar94 present, female A = Lace94 present,
	# female B = neither (bun + flower, no collar/lace).
	# Body-local (S94/S95): LongyiPivot58 at body y -0.10,
	# longyi flare top r 0.24 at lpiv y 0.0, bottom r 0.32
	# at lpiv y -0.90; shoulder pivots at (+-0.27, 0.42).
	var male_lg := _mat(Color(0.20, 0.15, 0.38, 1.0), 0.85)
	var fema_band := _mat(Color(0.95, 0.45, 0.75, 1.0), 0.85)
	var femb_top := _mat(Color(0.95, 0.80, 0.85, 1.0), 0.7)
	for child in world.get_children():
		var nm := String(child.name)
		if nm != "Player" and not nm.begins_with("Villager"):
			continue
		var is_male := child.get_node_or_null("Collar94") != null
		var is_fema := child.get_node_or_null("Lace94") != null
		var lpiv := child.get_node_or_null("LongyiPivot58") as Node3D
		if lpiv == null:
			continue
		if lpiv.get_node_or_null("Waist99") != null or lpiv.get_node_or_null("Panel99_A") != null:
			continue
		var piv_r := child.get_node_or_null("ShoulderPivot58_R") as Node3D
		if piv_r != null and piv_r.get_node_or_null("Cuff99_R") != null:
			continue
		if is_male:
			# Waistband: proud ring at the longyi top
			# (tube top r 0.24; band r 0.26, spans just
			# above the tube top so it reads as a band).
			_cyl(lpiv, 0.26, 0.27, 0.09, male_lg, Vector3(0.0, 0.03, 0.0), "Waist99")
		elif is_fema:
			# Side panel: vertical patterned strip on the
			# front-left of the longyi (sheet front view).
			# Tube r at lpiv y -0.50 is 0.284; panel at
			# x -0.18 sits on the surface z 0.220, panel
			# front 0.245, rotated to the surface normal.
			_box(lpiv, Vector3(0.10, 0.70, 0.02), fema_band, Vector3(-0.18, -0.50, 0.235), "Panel99_A", Vector3(0.0, -0.65, 0.0))
		else:
			# Female B sleeve cuffs (pair): rings at the
			# wrist end of the long sleeves, same seat
			# as the male Cuff94 (pivot-local y -0.66,
			# z 0.085, tilt -0.25).
			for side in ["R", "L"]:
				var piv := child.get_node_or_null("ShoulderPivot58_" + side) as Node3D
				if piv != null:
					_cyl(piv, 0.075, 0.075, 0.06, femb_top, Vector3(0.0, -0.66, 0.085), "Cuff99_" + side, Vector3(-0.25, 0.0, 0.0))

static func _vehicles(world: Node3D) -> void:
	var dark := _mat(Color(0.12, 0.10, 0.10, 1.0), 0.7)
	var steel := _mat(Color(0.45, 0.45, 0.48, 1.0), 0.4, 0.6)
	var leather := _mat(Color(0.40, 0.25, 0.15, 1.0), 0.85)
	var wood := _mat(Color(0.45, 0.32, 0.20, 1.0), 0.9)
	var red_tail := _glow_mat(Color(1.0, 0.10, 0.10, 1.0))
	var amber := _glow_mat(Color(1.0, 0.65, 0.15, 1.0))
	var glass_m := _mat(Color(0.55, 0.70, 0.80, 1.0), 0.15, 0.3)
	# MOTORCYCLE (world (-4,1,8); body 0.6x0.8x2 at y 0,
	# wheels y -0.55 z +-0.7 r 0.38, seat y 0.45 z 0.3,
	# handlebar y 0.48 z -0.7, headlight front z -1.02).
	var moto := world.get_node_or_null("Motorcycle") as Node3D
	if moto != null and moto.get_node_or_null("Tail99_Moto") == null:
		_box(moto, Vector3(0.22, 0.12, 0.06), red_tail, Vector3(0.0, 0.15, 1.05), "Tail99_Moto")
		_box(moto, Vector3(0.05, 0.75, 0.05), steel, Vector3(0.33, -0.55, 0.25), "Stand99_Moto", Vector3(0.0, 0.0, 0.30))
		_box(moto, Vector3(0.04, 0.28, 0.90), dark, Vector3(-0.22, -0.35, 0.35), "ChainGuard99_Moto")
		_cyl(moto, 0.03, 0.03, 1.05, steel, Vector3(-0.12, -0.02, -0.70), "Fork99_Moto_L")
		_cyl(moto, 0.03, 0.03, 1.05, steel, Vector3(0.12, -0.02, -0.70), "Fork99_Moto_R")
		_box(moto, Vector3(0.28, 0.42, 0.55), leather, Vector3(-0.42, 0.15, 0.75), "Bag99_Moto_L")
		_box(moto, Vector3(0.28, 0.42, 0.55), leather, Vector3(0.42, 0.15, 0.75), "Bag99_Moto_R")
	# TUK-TUK (body 1.4x0.7x2.4 at y 0.2, top 0.55;
	# canopy 1.5x0.15x2.2 at y 1.15 with NO posts yet;
	# seat y 0.55 z 0.4, headlight front z -1.25).
	var tuk := world.get_node_or_null("TukTuk") as Node3D
	if tuk != null and tuk.get_node_or_null("Post99_Tuk_FL") == null:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var tag := ("L" if sx < 0.0 else "R") + ("F" if sz < 0.0 else "B")
				_box(tuk, Vector3(0.08, 0.55, 0.08), dark, Vector3(sx * 0.65, 0.82, sz * 0.95), "Post99_Tuk_" + tag)
		_box(tuk, Vector3(1.30, 0.08, 0.06), dark, Vector3(0.0, 1.05, -1.18), "WindFrame99_Tuk_Top")
		_box(tuk, Vector3(0.06, 0.55, 0.06), dark, Vector3(-0.62, 0.80, -1.18), "WindFrame99_Tuk_L")
		_box(tuk, Vector3(0.06, 0.55, 0.06), dark, Vector3(0.62, 0.80, -1.18), "WindFrame99_Tuk_R")
		_box(tuk, Vector3(0.30, 0.35, 0.04), dark, Vector3(-0.60, -0.15, 1.25), "Mud99_Tuk_L")
		_box(tuk, Vector3(0.30, 0.35, 0.04), dark, Vector3(0.60, -0.15, 1.25), "Mud99_Tuk_R")
		_box(tuk, Vector3(1.10, 0.45, 0.10), leather, Vector3(0.0, 0.85, 0.92), "Back99_Tuk")
	# BICYCLE (frame y 0.8, seat y 0.95 z 0.45, handle
	# y 0.9 z -0.55, wheels y 0.35 r 0.35 z +-0.7).
	var bike := world.get_node_or_null("Bicycle") as Node3D
	if bike != null and bike.get_node_or_null("Basket99_Bike") == null:
		_box(bike, Vector3(0.42, 0.30, 0.28), wood, Vector3(0.0, 0.88, -0.95), "Basket99_Bike")
		_box(bike, Vector3(0.42, 0.05, 0.55), steel, Vector3(0.0, 0.98, 0.90), "Rack99_Bike")
		for wz in [-1.0, 1.0]:
			var tag := "F" if wz < 0.0 else "R"
			_box(bike, Vector3(0.12, 0.04, 0.30), dark, Vector3(0.0, 0.72, wz * 0.70), "Fender99_Bike_" + tag + "0")
			_box(bike, Vector3(0.12, 0.04, 0.30), dark, Vector3(0.0, 0.68, wz * 0.70 - 0.25 * wz), "Fender99_Bike_" + tag + "1", Vector3(0.35 * wz, 0.0, 0.0))
			_box(bike, Vector3(0.12, 0.04, 0.30), dark, Vector3(0.0, 0.68, wz * 0.70 + 0.25 * wz), "Fender99_Bike_" + tag + "2", Vector3(-0.35 * wz, 0.0, 0.0))
		_sphere(bike, 0.05, steel, Vector3(0.22, 0.96, -0.55), "Bell99_Bike")
		_box(bike, Vector3(0.20, 0.05, 0.14), dark, Vector3(-0.28, 0.42, 0.0), "Pedal99_Bike_L")
		_box(bike, Vector3(0.20, 0.05, 0.14), dark, Vector3(0.28, 0.42, 0.0), "Pedal99_Bike_R")
	# BOAT (hull 1x0.5x2.4 at y 0.3, top 0.55; benches
	# y 0.55 z +-0.6; oars already exist).
	var boat := world.get_node_or_null("Boat") as Node3D
	if boat != null and boat.get_node_or_null("Rope99_Boat") == null:
		_cyl(boat, 0.16, 0.16, 0.045, leather, Vector3(0.0, 0.575, -0.95), "Rope99_Boat_0")
		_cyl(boat, 0.13, 0.13, 0.045, leather, Vector3(0.0, 0.62, -0.95), "Rope99_Boat_1")
		_cyl(boat, 0.10, 0.10, 0.045, leather, Vector3(0.0, 0.665, -0.95), "Rope99_Boat_2")
		_cyl(boat, 0.03, 0.03, 0.70, wood, Vector3(0.0, 0.90, 1.05), "LampPost99_Boat")
		_sphere(boat, 0.09, amber, Vector3(0.0, 1.28, 1.05), "Lamp99_Boat")
		_cyl(boat, 0.26, 0.20, 0.35, wood, Vector3(-0.22, 0.725, 0.0), "Fish99_Boat")
	# CART (body 2x0.8x4 at y 0, top 0.4; rails x +-1.0
	# y 0.55; canopy y 1.6, posts x +-0.9).
	var cart := world.get_node_or_null("Cart") as Node3D
	if cart != null and cart.get_node_or_null("Yoke99_Cart") == null:
		_box(cart, Vector3(0.16, 0.16, 1.40), wood, Vector3(0.0, 0.0, -2.60), "Yoke99_Cart")
		_box(cart, Vector3(0.62, 0.42, 0.55), leather, Vector3(-0.50, 0.61, 0.40), "Sack99_Cart_L")
		_box(cart, Vector3(0.62, 0.42, 0.55), leather, Vector3(0.50, 0.61, 0.40), "Sack99_Cart_R")
		_box(cart, Vector3(0.03, 0.15, 0.03), dark, Vector3(0.90, 1.50, 0.0), "LampLink99_Cart")
		_box(cart, Vector3(0.12, 0.16, 0.12), amber, Vector3(0.90, 1.35, 0.0), "Lamp99_Cart")
	# HORSE (head 0.5x0.5x0.7 at (0,1.9,-1.2); saddle
	# (0.75,0.22,0.95) at (0,2.02,0.1)).
	var horse := world.get_node_or_null("Horse") as Node3D
	if horse != null and horse.get_node_or_null("Bridle99_Horse") == null:
		_box(horse, Vector3(0.06, 0.30, 0.06), leather, Vector3(-0.27, 1.90, -1.20), "Bridle99_Horse_L")
		_box(horse, Vector3(0.06, 0.30, 0.06), leather, Vector3(0.27, 1.90, -1.20), "Bridle99_Horse_R")
		_box(horse, Vector3(0.54, 0.07, 0.06), leather, Vector3(0.0, 2.05, -1.20), "Bridle99_Horse_Top")
		_box(horse, Vector3(0.04, 0.04, 1.30), leather, Vector3(-0.20, 1.85, -0.45), "Reins99_Horse_L")
		_box(horse, Vector3(0.04, 0.04, 1.30), leather, Vector3(0.20, 1.85, -0.45), "Reins99_Horse_R")
	# ELEPHANT (body top 2.6; howdah (1.7,0.15,1.8) at
	# y 2.75 z 0.1; head (1.2^3) at (0,2.6,-1.8)).
	var ele := world.get_node_or_null("Elephant") as Node3D
	if ele != null and ele.get_node_or_null("Blanket99_Ele") == null:
		_box(ele, Vector3(1.90, 0.10, 2.00), _mat(Color(0.70, 0.15, 0.15, 1.0), 0.85), Vector3(0.0, 2.66, 0.10), "Blanket99_Ele")
		_box(ele, Vector3(0.06, 0.25, 0.06), leather, Vector3(0.35, 2.02, -2.35), "BellStrap99_Ele")
		_sphere(ele, 0.12, _mat(Color(0.85, 0.70, 0.20, 1.0), 0.3, 0.7), Vector3(0.35, 1.82, -2.35), "Bell99_Ele")
	# HELICOPTER (body 2x0.8x4 at y 0, front z -2.0).
	var heli := world.get_node_or_null("Helicopter") as Node3D
	if heli != null and heli.get_node_or_null("Fin99_Heli") == null:
		_box(heli, Vector3(0.10, 0.90, 0.90), dark, Vector3(0.0, 0.45, 1.85), "Fin99_Heli")
		_box(heli, Vector3(1.60, 0.35, 0.06), glass_m, Vector3(0.0, 0.15, -2.02), "Glass99_Heli")
	# AIRPLANE (fuselage 2x0.8x4 at y 0, top 0.4; wings
	# 8x0.3x1.5 at y 0, tips x +-4.0).
	var plane := world.get_node_or_null("Airplane") as Node3D
	if plane != null and plane.get_node_or_null("Glass99_Plane") == null:
		_box(plane, Vector3(1.20, 0.30, 0.80), glass_m, Vector3(0.0, 0.50, -0.80), "Glass99_Plane")
		_box(plane, Vector3(1.15, 0.06, 0.06), steel, Vector3(-1.45, -0.25, -0.30), "Strut99_Plane_L", Vector3(0.0, 0.0, -0.18))
		_box(plane, Vector3(1.15, 0.06, 0.06), steel, Vector3(1.45, -0.25, -0.30), "Strut99_Plane_R", Vector3(0.0, 0.0, 0.18))
		_sphere(plane, 0.07, _glow_mat(Color(1.0, 0.10, 0.10, 1.0)), Vector3(-3.98, 0.0, 0.0), "Nav99_Plane_L")
		_sphere(plane, 0.07, _glow_mat(Color(0.10, 1.0, 0.30, 1.0)), Vector3(3.98, 0.0, 0.0), "Nav99_Plane_R")
	# BUS + MINIBUS bumpers (children of the vehicle
	# nodes only — no controller touch, S81 limit).
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus != null and bus.get_node_or_null("Bump99_Bus_F") == null:
		_box(bus, Vector3(2.70, 0.25, 0.15), dark, Vector3(0.0, 0.70, -4.58), "Bump99_Bus_F")
		_box(bus, Vector3(2.70, 0.25, 0.15), dark, Vector3(0.0, 0.70, 4.58), "Bump99_Bus_R")
	var mini := world.get_node_or_null("Minibus") as Node3D
	if mini != null and mini.get_node_or_null("Bump99_Mini_F") == null:
		_box(mini, Vector3(2.50, 0.22, 0.15), dark, Vector3(0.0, 0.65, -3.08), "Bump99_Mini_F")
		_box(mini, Vector3(2.50, 0.22, 0.15), dark, Vector3(0.0, 0.65, 3.08), "Bump99_Mini_R")

static func _world_dress(world: Node3D) -> void:
	var wood := _mat(Color(0.45, 0.32, 0.20, 1.0), 0.9)
	var pole_m := _mat(Color(0.20, 0.16, 0.12, 1.0), 0.9)
	var flag_m := _mat(Color(0.85, 0.20, 0.20, 1.0), 0.85)
	var mat_m := _mat(Color(0.55, 0.35, 0.60, 1.0), 0.95)
	var stone := _mat(Color(0.55, 0.52, 0.48, 1.0), 0.95)
	var bamboo := _mat(Color(0.45, 0.65, 0.25, 1.0), 0.9)
	var leaf_m := _mat(Color(0.25, 0.55, 0.25, 1.0), 0.9)
	# SCHOOL13 (local: walls 8x3x6 at y 1.5, fence posts
	# at z 5; node scaled 1.7, so local pole 3.5 reads
	# 5.95 m in the world — taller than the 5.1 m walls,
	# as a flagpole should be).
	var school := _find_rec(world, "School13") as Node3D
	if school != null and school.get_node_or_null("FlagPole99") == null:
		_cyl(school, 0.06, 0.06, 3.50, pole_m, Vector3(0.0, 1.75, 6.50), "FlagPole99")
		_box(school, Vector3(0.95, 0.60, 0.04), flag_m, Vector3(0.52, 3.05, 6.50), "Flag99")
	# ZAYAT (deck 8.5x0.35x6.5 at y 0.6, top 0.775).
	var zayat := _find_rec(world, "Zayat") as Node3D
	if zayat != null and zayat.get_node_or_null("Mat99_L") == null:
		_box(zayat, Vector3(0.70, 0.04, 1.40), mat_m, Vector3(-1.00, 0.795, 0.50), "Mat99_L")
		_box(zayat, Vector3(0.70, 0.04, 1.40), mat_m, Vector3(1.00, 0.795, 0.50), "Mat99_R")
	# MONASTERY BELL (base r 1.5 at origin; table
	# inner edge 1.6, clear of the base).
	var mon := _find_rec(world, "MonasteryBell") as Node3D
	if mon != null and mon.get_node_or_null("Table99_Mon") == null:
		_box(mon, Vector3(1.20, 0.08, 0.60), wood, Vector3(2.20, 0.75, 0.0), "Table99_Mon")
		for lx in [1.75, 2.65]:
			for lz in [-0.22, 0.22]:
				_box(mon, Vector3(0.08, 0.75, 0.08), wood, Vector3(lx, 0.375, lz), "TableLeg99_Mon_%d_%d" % [int(lx * 100.0), int(lz * 100.0)])
		for bi in range(3):
			_sphere(mon, 0.09, _mat(Color(0.85, 0.70, 0.20, 1.0), 0.3, 0.7), Vector3(1.90 + 0.30 * float(bi), 0.85, 0.0), "Bowl99_Mon_%d" % bi)
	# WELL (ring at (6,0.5,12) top 1.0; posts x 5.2/6.8;
	# roof at y 2.2; rope descends into the ring).
	if world.get_node_or_null("Pulley99_Well") == null:
		_cyl(world, 0.15, 0.15, 0.08, wood, Vector3(6.0, 1.90, 12.0), "Pulley99_Well", Vector3(0.0, 0.0, 1.5708))
		_cyl(world, 0.02, 0.02, 1.00, _mat(Color(0.55, 0.45, 0.30, 1.0), 0.95), Vector3(6.0, 1.35, 12.0), "Rope99_Well")
	# BAMBOO GROVES on open extension ground, clear of
	# S97 tree sites / fields / ponds / paths by 100 m
	# or more (nearest S97 tree: grove0 335 m, grove1
	# 316 m, grove2 800 m+; nearest road: grove2 184 m
	# north of the long route).
	for gi in range(3):
		var site := Vector3(-600.0, 0.0, -200.0) if gi == 0 else (Vector3(1200.0, 0.0, -250.0) if gi == 1 else Vector3(1200.0, 0.0, 200.0))
		if world.get_node_or_null("Grove99_%d" % gi) != null:
			continue
		var g := _holder(world, site, "Grove99_%d" % gi)
		var offs: Array = [[0.0, 0.0, 4.20], [0.50, 0.30, 4.80], [-0.40, 0.40, 5.20], [0.30, -0.50, 4.50], [-0.50, -0.30, 4.90]]
		for oi in range(5):
			var oo: Array = offs[oi]
			_cyl(g, 0.05, 0.06, float(oo[2]), bamboo, Vector3(float(oo[0]), float(oo[2]) * 0.5, float(oo[1])), "Grove99_%d_Culm%d" % [gi, oi])
			if oi < 3:
				_box(g, Vector3(0.50, 0.05, 1.20), leaf_m, Vector3(float(oo[0]), float(oo[2]) + 0.10, float(oo[1])), "Grove99_%d_Leaf%d" % [gi, oi], Vector3(0.30, 0.0, 0.40 * float(oi - 1)))
	# ROCK OUTCROPS on open extension ground (grove/
	# field/tree clearances as above; nearest road for
	# rock1 is 200 m south of the east dirt track).
	for ri in range(2):
		var site := Vector3(-100.0, 0.0, -200.0) if ri == 0 else Vector3(2900.0, 0.0, -200.0)
		if world.get_node_or_null("Rock99_%d" % ri) != null:
			continue
		var g := _holder(world, site, "Rock99_%d" % ri)
		_box(g, Vector3(1.20, 0.80, 1.00), stone, Vector3(0.0, 0.40, 0.0), "Rock99_%d_A" % ri, Vector3(0.0, 0.30, 0.0))
		_box(g, Vector3(0.80, 0.50, 0.70), stone, Vector3(0.90, 0.25, 0.40), "Rock99_%d_B" % ri, Vector3(0.0, -0.40, 0.0))
		_sphere(g, 0.45, stone, Vector3(-0.80, 0.45, -0.30), "Rock99_%d_C" % ri)

func _night(world: Node3D) -> void:
	# Extension lamps, gated every frame on daylight <
	# 0.15 (night97 / realism98 pattern). Sites: east
	# dirt track sides (track z -4..4, lamps 2 m clear),
	# S97 tree sites (10-12 m off the trunks), west pond
	# (8 m clear of the r 12 water edge), hamlet spur
	# (6 m east of the x 2094..2106 road, 40 m from the
	# nearest hamlet house).
	var sites: Array = [
		[Vector3(2550.0, 0.0, 6.0), "Lamp99_Ext_TrackW"],
		[Vector3(2800.0, 0.0, -6.0), "Lamp99_Ext_TrackE"],
		[Vector3(-300.0, 0.0, -338.0), "Lamp99_Ext_TreeS"],
		[Vector3(400.0, 0.0, 288.0), "Lamp99_Ext_TreeN"],
		[Vector3(-330.0, 0.0, 0.0), "Lamp99_Ext_Pond"],
		[Vector3(2112.0, 0.0, 40.0), "Lamp99_Ext_Spur"],
	]
	for s in sites:
		var nm := String(s[1])
		if world.get_node_or_null(nm) != null:
			continue
		_lantern(world, s[0], nm, 1.5, 22.0)
