extends Node3D

## Slice 104 (parent sequence): DETAIL ROUND 3 — face readability at 6 m,
## vehicle trim gaps, world dressing gaps. Audit-first, live-probed
## 2026-10-24: every item below was PROVEN missing before it was added.
## Deliberately NOT added (audited, already present): market goods
## (StallA/B mango piles, StallC crates, StallD/E food, StallF baskets,
## night-market noodle pot + drink jars + balloons + benches), tea-shop
## teapot + 7 cups, monastery garlands + incense pots, zayat flower
## pots, school fence + bell + books + flowers + flag, pagoda lanterns
## + gate archways + lions, scarecrows x3, ploughs x2, clotheslines,
## kilometre posts, cart crossed spokes (2 per wheel, proper cross),
## car mirrors/handles/plates/roof rails, motorcycle mirrors/bags/
## chain guard, tuk-tuk canopy posts/windshield frame/mudflaps,
## bicycle basket/rack/fenders/bell/pedals, bus mirrors/pillars/seats/
## wipers, minibus rack/pillars/seats, horse saddle/blanket/bridle/
## reins/stirrups, elephant howdah/blanket/bell/toenails, boat benches/
## oars/rope/lantern/fish basket, helicopter skids/fin/glass, airplane
## glass/struts/nav lights/propeller, cow bell/saddle/tail tuft.
## Runtime dressing ONLY, no .tscn edits, no bus-system changes,
## minibus NOT rewired, big bus NOT rewired (Slice 81 limit), touch
## controls untouched, zero NEW colliders, StandardMaterial3D only,
## no dead specular lines, no fog/SSAO/glow claims (no WorldEnvironment
## exists), no photorealism claims: stylised smooth procedural work.
## Runs at frame >= 280, after realism104's 260 pass.
##
## AUDIT findings (live probe, probe105_out.txt):
## - Faces: eyes are 0.060 balls, brows 0.05 x 0.012 slivers, mouth
##   0.09 wide — at the 6.0 m camera distance these read as dots, not
##   features. FIX: eyes r 0.030 -> 0.038, brows -> 0.07 x 0.02, mouth
##   -> 0.12 x 0.03, positions/rotations untouched (S94 re-mesh pattern).
##   19 figures (Player + 18 villagers) = 19 items by S95 precedent.
## - Car: headlights + bumper exist but NO grille between them.
##   Indicators: none on the fenders. FIX: grille + amber pair.
## - Tuk-tuk: windshield FRAME exists (WindFrame99) but NO glass pane.
## - Bicycle: basket/rack/fenders/bell/pedals exist but NO chain and
##   NO sprockets at all (motorcycle has a chain guard; bicycle none).
## - Helicopter: fin + glass + skids exist but NO tail rotor and NO
##   landing light.
## - Airplane: glass/struts/nav lights exist but NO horizontal
##   stabilizers and NO nose wheel (only 2 main wheels).
## - Cow (rideable): bell + saddle exist but NO reins and NO girth
##   strap (horse has both).
## - Bus/minibus: mirrors/pillars/seats exist but NO wheel-arch trims
##   (car got Arch96) and NO side stripe.
## - Horse: blanket exists but NO edge trim.
## - School13: fence + bell + books + flower bed + flag exist but NO
##   benches in the yard.
## - BrickWell (6,12): pulley + rope + bucket exist but NO jars at
##   the base.
## - Hamlet houses (2075/2125, 78/98, group x1.8, front -z): NO
##   firewood stacks (the sheet's stilt house HAS firewood).
## - MindonPost: 2-storey + balcony + door + steps exist but NO
##   letter box (a post office without one). Placed as a MindonPost
##   child in pre-scale locals (group x1.7 — Post uses 1.7, NOT 1.8,
##   the S96 street-clearance exception): local (1.05, 0.31, 3.0)
##   size (0.28, 0.61, 0.17) -> world (1.79, 0.53, 5.10) size
##   (0.48, 1.04, 0.29), 0.60 m clear of the door steps in x and
##   0.71 m clear of the wall face in z.
## Counting: one item = one placed assembly, or one symmetric pair/
## set placed together (S93/S94 rule). PEOPLE 19 + VEHICLES 17 +
## WORLD 7 = 43 honest items (under the ~50 target, NO padding).
## DONE vs DEFERRED: MD1/2/3/6/10 stay bare + unscaled (S103 decision,
## permanent, NOT reopened); StiltHouse17_5/18_6 pavilions (S96
## exclusion stands); House1/2/3/4 slabs stay hidden (House97_1-4);
## night residuals stand (rows band ~1.4, spur 1.3 m, junction 4.5 m,
## hill-face 4.71 m — marginal, NOT padded with more lamps).
## Honest limit: phone feel unproven until the owner's vivo V60 verdict.

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism105") != null:
		return
	var n := Node3D.new()
	n.name = "Realism105"
	n.set_script(load("res://realism105.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 280:
		_done = true
		_apply(get_parent() as Node3D)

static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m

static func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m

static func _glass_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.70, 0.85, 0.90, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.15
	return m

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node, r_top: float, r_bot: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _sphere(parent: Node, r: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _torus(parent: Node, inner_r: float, outer_r: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var tm := TorusMesh.new()
	tm.inner_radius = inner_r
	tm.outer_radius = outer_r
	mi.mesh = tm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _ball_mesh(r: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	return sm

static func _box_mesh(size: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = size
	return bm

static func _find(world: Node, nm: String) -> Node:
	for c in world.get_children():
		if String(c.name) == nm:
			return c
		var sub := _find(c, nm)
		if sub != null:
			return sub
	return null

static func _child(parent: Node, nm: String) -> Node:
	if parent == null:
		return null
	var direct := parent.get_node_or_null(nm)
	if direct != null:
		return direct
	return _find(parent, nm)

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_faces(world)
	_vehicles(world)
	_world_items(world)

# Face readability: re-mesh only (S94 pattern), positions untouched.
func _faces(world: Node3D) -> void:
	for child in world.get_children():
		var nm := String(child.name)
		if nm != "Player" and not nm.begins_with("Villager"):
			continue
		var b := child as Node3D
		if b == null:
			continue
		for side in ["L", "R"]:
			var eye := b.get_node_or_null("Eye73_" + side) as MeshInstance3D
			if eye != null:
				eye.mesh = _ball_mesh(0.038)
			var brow := b.get_node_or_null("Brow95_" + side) as MeshInstance3D
			if brow != null:
				brow.mesh = _box_mesh(Vector3(0.07, 0.02, 0.02))
		var mouth := b.get_node_or_null("Mouth94") as MeshInstance3D
		if mouth != null:
			mouth.mesh = _box_mesh(Vector3(0.12, 0.03, 0.03))

func _vehicles(world: Node3D) -> void:
	var dark := _mat(Color(0.12, 0.12, 0.12, 1.0), 0.5, 0.3)
	var chrome := _mat(Color(0.75, 0.75, 0.78, 1.0), 0.3, 0.7)
	var amber := _glow_mat(Color(1.0, 0.65, 0.10, 1.0), 0.6)
	var glass := _glass_mat()
	var steel := _mat(Color(0.30, 0.30, 0.32, 1.0), 0.4, 0.6)
	var leather := _mat(Color(0.45, 0.30, 0.18, 1.0), 0.8)
	var red := _mat(Color(0.60, 0.10, 0.10, 1.0), 0.7)
	# Car: grille between the headlights + amber fender indicators.
	var car := world.get_node_or_null("Car") as Node3D
	if car != null:
		var hl := _child(car, "Headlight71_L") as Node3D
		var hr := _child(car, "Headlight71_R") as Node3D
		if hl != null and hr != null:
			var hy: float = hl.position.y
			var hz: float = hl.position.z
			_box(car, Vector3(0.80, 0.20, 0.04), chrome, Vector3(0.0, hy, hz - 0.10), "Grille105_Car")
			for sx in [-1.0, 1.0]:
				_box(car, Vector3(0.03, 0.10, 0.14), amber, Vector3(sx * 0.97, hy, hz), "Indicator105_Car_%d" % int(sx))
	# Tuk-tuk: windshield glass inside the existing frame.
	var tuk := world.get_node_or_null("TukTuk") as Node3D
	if tuk != null:
		var fl := _child(tuk, "WindFrame99_Tuk_L") as Node3D
		var fr := _child(tuk, "WindFrame99_Tuk_R") as Node3D
		if fl != null and fr != null:
			var w: float = absf(fr.position.x - fl.position.x) - 0.06
			_box(tuk, Vector3(w, 0.50, 0.03), glass, Vector3((fl.position.x + fr.position.x) * 0.5, fl.position.y, fl.position.z), "Glass105_Tuk")
	# Bicycle: chain runs + chainring + rear sprocket.
	var bike := world.get_node_or_null("Bicycle") as Node3D
	if bike != null:
		var wf := _child(bike, "BikeWheelF") as Node3D
		var wb := _child(bike, "BikeWheelB") as Node3D
		if wf != null and wb != null:
			var wy: float = wf.position.y
			var crank_z: float = (wf.position.z + wb.position.z) * 0.5
			var mid_z: float = (wb.position.z + crank_z) * 0.5
			_box(bike, Vector3(0.03, 0.03, absf(wb.position.z - crank_z)), steel, Vector3(0.07, wy + 0.09, mid_z), "Chain105_Bike_Top")
			_box(bike, Vector3(0.03, 0.03, absf(wb.position.z - crank_z)), steel, Vector3(0.07, wy - 0.09, mid_z), "Chain105_Bike_Bot")
			_cyl(bike, 0.12, 0.12, 0.03, steel, Vector3(0.07, wy, crank_z), "ChainRing105_Bike", Vector3(0.0, 0.0, 1.5708))
			_cyl(bike, 0.06, 0.06, 0.03, steel, Vector3(0.07, wy, wb.position.z), "Sprocket105_Bike", Vector3(0.0, 0.0, 1.5708))
	# Helicopter: tail rotor (hub + crossed blades) + landing light.
	var heli := world.get_node_or_null("Helicopter") as Node3D
	if heli != null:
		var fin := _child(heli, "Fin99_Heli") as Node3D
		if fin != null:
			var c := fin.position + Vector3(0.14, 0.15, 0.35)
			_cyl(heli, 0.06, 0.06, 0.12, dark, c, "TailRotor105_Heli_Hub", Vector3(0.0, 0.0, 1.5708))
			_box(heli, Vector3(0.03, 0.72, 0.08), dark, c, "TailRotor105_Heli_V")
			_box(heli, Vector3(0.03, 0.08, 0.72), dark, c, "TailRotor105_Heli_H")
		var body := _child(heli, "Body") as Node3D
		if body != null:
			_box(heli, Vector3(0.16, 0.08, 0.06), _glow_mat(Color(1.0, 0.95, 0.75, 1.0), 1.2), body.position + Vector3(0.0, -0.32, -2.02), "LandLight105_Heli")
	# Airplane: horizontal stabilizers + nose wheel (same height as mains).
	var plane := world.get_node_or_null("Airplane") as Node3D
	if plane != null:
		var tfin := _child(plane, "PlaneTailFin") as Node3D
		if tfin != null:
			for sx in [-1.0, 1.0]:
				_box(plane, Vector3(1.30, 0.08, 0.90), _mat(Color(0.80, 0.80, 0.82, 1.0), 0.6), Vector3(sx * 0.65, tfin.position.y - 0.35, tfin.position.z), "Stab105_Plane_%d" % int(sx))
		var fus := _child(plane, "Fuselage") as Node3D
		var mw := _child(plane, "PlaneWheel12_L") as Node3D
		if fus != null and mw != null:
			_cyl(plane, 0.28, 0.28, 0.12, dark, Vector3(0.0, mw.position.y, fus.position.z - 1.85), "NoseWheel105_Plane", Vector3(0.0, 0.0, 1.5708))
	# Cow: reins + girth strap (horse already has both).
	var cow := world.get_node_or_null("Cow") as Node3D
	if cow != null:
		var head := _child(cow, "Head72") as Node3D
		var saddle := _child(cow, "CowSaddle") as Node3D
		if head != null and saddle != null:
			var ln: float = absf(head.position.z - saddle.position.z)
			var mz: float = (head.position.z + saddle.position.z) * 0.5
			var my: float = (head.position.y + saddle.position.y) * 0.5
			for sx in [-1.0, 1.0]:
				_box(cow, Vector3(0.03, 0.03, ln), leather, Vector3(sx * 0.30, my, mz), "Rein105_Cow_%d" % int(sx))
			_box(cow, Vector3(0.95, 0.06, 0.18), leather, Vector3(0.0, saddle.position.y - 0.60, saddle.position.z), "Harness105_Cow")
	# Bus + minibus: wheel-arch trims (S95 car pattern) + side stripes.
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus != null:
		for wname in ["Wheel74_0", "Wheel74_1", "Wheel74_2", "Wheel74_3"]:
			var w := _child(bus, wname) as Node3D
			if w != null:
				_torus(bus, 0.56, 0.66, dark, Vector3(w.position.x + signf(w.position.x) * 0.05, w.position.y, w.position.z), "Arch105_Bus_" + wname, Vector3(0.0, 1.5708, 0.0))
		for sx in [-1.0, 1.0]:
			_box(bus, Vector3(0.04, 0.25, 8.60), dark, Vector3(sx * 1.32, 1.0, 0.0), "Stripe105_Bus_%d" % int(sx))
	var mini := world.get_node_or_null("Minibus") as Node3D
	if mini != null:
		for wname in ["Wheel74M_0", "Wheel74M_1", "Wheel74M_2", "Wheel74M_3"]:
			var w := _child(mini, wname) as Node3D
			if w != null:
				_torus(mini, 0.51, 0.61, dark, Vector3(w.position.x + signf(w.position.x) * 0.04, w.position.y, w.position.z), "Arch105_Mini_" + wname, Vector3(0.0, 1.5708, 0.0))
		for sx in [-1.0, 1.0]:
			_box(mini, Vector3(0.04, 0.22, 5.60), dark, Vector3(sx * 1.22, 0.9, 0.0), "Stripe105_Mini_%d" % int(sx))
	# Horse: blanket edge trim.
	var horse := world.get_node_or_null("Horse") as Node3D
	if horse != null:
		var bl := _child(horse, "HorseBlanket") as MeshInstance3D
		if bl != null and bl.mesh != null:
			var sz: Vector3 = bl.mesh.get_aabb().size
			_box(horse, Vector3(sz.x + 0.06, 0.05, sz.z + 0.06), red, bl.position + Vector3(0.0, -0.08, 0.0), "Trim105_Horse")

func _world_items(world: Node3D) -> void:
	var wood := _mat(Color(0.45, 0.32, 0.20, 1.0), 0.9)
	var clay := _mat(Color(0.65, 0.45, 0.30, 1.0), 0.9)
	var log_m := _mat(Color(0.42, 0.30, 0.18, 1.0), 0.9)
	var red := _mat(Color(0.75, 0.10, 0.10, 1.0), 0.7)
	var dark := _mat(Color(0.12, 0.12, 0.12, 1.0), 0.5, 0.3)
	# School yard benches (School13 front is +z: sign/fence at z 3.2/5).
	var school := _find(world, "School13") as Node3D
	if school != null:
		for sx in [-1.0, 1.0]:
			var bx: float = sx * 4.0
			_box(school, Vector3(1.20, 0.08, 0.40), wood, Vector3(bx, 0.45, 4.60), "Bench105_School_%d" % int(sx))
			for lx in [-0.50, 0.50]:
				_box(school, Vector3(0.08, 0.45, 0.36), wood, Vector3(bx + lx, 0.225, 4.60), "BenchLeg105_School_%d_%d" % [int(sx), int(lx * 10.0)])
	# Well jars at the BrickWell base (anchored to the wall mesh itself,
	# so the jars land at the real well whatever the group origin is).
	var well := _find(world, "BrickWellWall") as Node3D
	if well == null:
		well = _find(world, "BrickWell") as Node3D
	if well != null:
		var wp: Vector3 = well.global_position
		for sx in [-1.0, 1.0]:
			var jp := Vector3(wp.x + sx * 1.40, 0.0, wp.z + 0.60)
			_cyl(world, 0.22, 0.18, 0.45, clay, jp + Vector3(0.0, 0.225, 0.0), "Jar105_Well_%d" % int(sx))
			_cyl(world, 0.24, 0.24, 0.06, clay, jp + Vector3(0.0, 0.46, 0.0), "JarRim105_Well_%d" % int(sx))
	# Hamlet firewood stacks (houses x1.8, front -z; local x 4.4 ->
	# world 7.92 from centre, clear of the 6.3 m wall half-width).
	for hi in [0, 1]:
		var g := _find(world, "HamletHouse75_%d" % hi) as Node3D
		if g == null:
			continue
		_cyl(g, 0.12, 0.12, 1.10, log_m, Vector3(4.40, 0.12, 1.75), "Firewood105_H%d_A" % hi, Vector3(0.0, 0.0, 1.5708))
		_cyl(g, 0.12, 0.12, 1.10, log_m, Vector3(4.40, 0.12, 2.25), "Firewood105_H%d_B" % hi, Vector3(0.0, 0.0, 1.5708))
		_cyl(g, 0.12, 0.12, 1.10, log_m, Vector3(4.40, 0.33, 2.00), "Firewood105_H%d_C" % hi, Vector3(0.0, 0.0, 1.5708))
	# Post-office letter box (pre-scale locals, group x1.8 — see header).
	var post := _find(world, "MindonPost") as Node3D
	if post != null:
		_box(post, Vector3(0.28, 0.61, 0.17), red, Vector3(1.05, 0.31, 3.00), "LetterBox105_Post")
		_box(post, Vector3(0.20, 0.04, 0.02), dark, Vector3(1.05, 0.50, 3.09), "LetterSlot105_Post")
