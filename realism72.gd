extends Node3D
## Slice 72 — graphics realism pass, part 3 (owner order 2026-10-23
## 06:32, binding: graphics FIRST, no new feature). Slices 70-71 did
## houses/people/ground/lighting + trees/vehicles/water/pagoda; this
## round does the next most visible toy-looking elements, all
## procedural, own work, no external assets, no copied opponent
## shaders, no scanned texture claimed. Runtime-only: no scene file
## is touched, no positions moved, no colliders added, no gameplay
## code changed, no new feature/quest/sign/label/system.
## - ANIMALS: the rideable cow finally gets a head (it was a bare
##   capsule + legs), ears, horns, muzzle, tail, hooves; horses get
##   ears, a saddle, stirrups, hooves; the elephant gets a howdah
##   platform + canopy, toenails, a tail; East Fields scenery cows
##   get ears/horns/muzzle/tail/hooves on their bobbing heads, and
##   chickens get beaks, tails, legs. Every detail is a child of
##   its animal node, so it travels (and bobs/swings) with it.
## - BUILDINGS round 2: market-stall crates + fruit, tea-shop
##   benches + side table + jars, school windows + door + steps,
##   night-market food trays, guest-house table/stools/pillow,
##   hospital entrance canopy + steps + red-cross sign (front is
##   +z: the Slice 69 hospital signboard sits at z 66, hospital
##   at z 58). No walls moved, no new signboards.
## - ROADS + SKY: raised curbs along the East Fields main road,
##   rain-only puddle discs (visible exactly when SaveManager
##   season62 == 1, the rainy season — otherwise hidden, so dry
##   seasons never show wet road), extra cloud puffs, distant
##   hill silhouettes on the north/west ground edges (visual only,
##   no colliders — a player walking to the edge passes through a
##   backdrop hill, stated plainly).
## Capture runs once at frame >= 20, after Slice 71's frame-16
## capture; _process then stays alive ONLY for the puddle toggle
## (one autoload int read per frame, visibility flips only when
## the season actually changes).

var _frames: int = 0
var _captured: bool = false
var _puddles: Array = []
var _puddle_visible: bool = false


static func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = pos
	m.rotation = rot
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	m.mesh = cm
	m.position = pos
	m.rotation = rot
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


static func _sphere(parent: Node3D, r: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	m.mesh = sm
	m.position = pos
	if mat != null:
		m.set_surface_override_material(0, mat)
	parent.add_child(m)
	return m


func _cow_detail(cow: Node3D, hide: Material, dark: Material, horn_m: Material) -> void:
	# Rideable cow: forward is local +z (cow.gd forward vector is
	# (sin(rot.y), 0, cos(rot.y))). Body is the vertical capsule
	# at the node origin; head parts hang off its front.
	_box(cow, Vector3(0.4, 0.4, 0.4), hide, Vector3(0.0, 0.30, 0.45), "Neck72")
	_box(cow, Vector3(0.55, 0.5, 0.5), hide, Vector3(0.0, 0.35, 0.75), "Head72")
	_box(cow, Vector3(0.4, 0.3, 0.25), hide, Vector3(0.0, 0.28, 1.05), "Muzzle72")
	_box(cow, Vector3(0.12, 0.22, 0.08), hide, Vector3(-0.35, 0.55, 0.70), "Ear72_L")
	_box(cow, Vector3(0.12, 0.22, 0.08), hide, Vector3(0.35, 0.55, 0.70), "Ear72_R")
	_cyl(cow, 0.02, 0.06, 0.30, horn_m, Vector3(-0.22, 0.62, 0.72), "Horn72_L", Vector3(0.0, 0.0, 0.5))
	_cyl(cow, 0.02, 0.06, 0.30, horn_m, Vector3(0.22, 0.62, 0.72), "Horn72_R", Vector3(0.0, 0.0, -0.5))
	_box(cow, Vector3(0.08, 0.7, 0.08), dark, Vector3(0.0, 0.25, -0.65), "Tail72")
	_sphere(cow, 0.12, dark, Vector3(0.0, -0.15, -0.65), "TailTuft72")
	for legname in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var leg := cow.get_node_or_null(legname) as Node3D
		if leg != null:
			_box(leg, Vector3(0.24, 0.14, 0.24), dark, Vector3(0.0, -0.38, 0.0), "Hoof72")


func _horse_detail(horse: Node3D, leather: Material, dark: Material) -> void:
	# Horse forward is local -z (head sits at z -1.2, tail +1.3).
	_box(horse, Vector3(0.12, 0.30, 0.12), dark, Vector3(-0.15, 2.28, -1.2), "Ear72_L")
	_box(horse, Vector3(0.12, 0.30, 0.12), dark, Vector3(0.15, 2.28, -1.2), "Ear72_R")
	_box(horse, Vector3(0.75, 0.22, 0.95), leather, Vector3(0.0, 2.02, 0.1), "Saddle72")
	_box(horse, Vector3(0.05, 0.40, 0.22), dark, Vector3(-0.52, 1.55, 0.1), "Stirrup72_L")
	_box(horse, Vector3(0.05, 0.40, 0.22), dark, Vector3(0.52, 1.55, 0.1), "Stirrup72_R")
	for legname in ["HorseLegFL", "HorseLegFR", "HorseLegBL", "HorseLegBR"]:
		var leg := horse.get_node_or_null(legname) as Node3D
		if leg != null:
			_box(leg, Vector3(0.28, 0.12, 0.28), dark, Vector3(0.0, -0.45, 0.0), "Hoof72")


func _capture(world: Node3D) -> void:
	_captured = true
	var hide := _mat(Color(0.85, 0.80, 0.70, 1.0), 0.9)
	var dark := _mat(Color(0.20, 0.15, 0.10, 1.0), 0.9)
	var horn_m := _mat(Color(0.90, 0.85, 0.70, 1.0), 0.6)
	var leather := _mat(Color(0.45, 0.28, 0.12, 1.0), 0.8)
	var wood := _mat(Color(0.35, 0.24, 0.13, 1.0), 0.9)
	var white := _mat(Color(0.95, 0.95, 0.92, 1.0), 0.8)
	var red := _mat(Color(0.80, 0.10, 0.10, 1.0), 0.6)
	var glass := _mat(Color(0.10, 0.16, 0.22, 1.0), 0.15)
	glass.metallic = 0.4
	var fruit_a := _mat(Color(0.95, 0.55, 0.10, 1.0), 0.7)
	var fruit_b := _mat(Color(0.20, 0.60, 0.20, 1.0), 0.7)
	var fruit_c := _mat(Color(0.85, 0.15, 0.15, 1.0), 0.7)
	var concrete := _mat(Color(0.55, 0.55, 0.55, 1.0), 0.95)
	var cloud_m := _mat(Color(1.0, 1.0, 1.0, 0.9), 1.0)
	cloud_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var hill_m := _mat(Color(0.16, 0.28, 0.22, 1.0), 1.0)
	var puddle_m := _mat(Color(0.55, 0.65, 0.75, 0.55), 0.05)
	puddle_m.metallic = 0.5
	puddle_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Phase 1 — animals.
	for cname in ["Cow", "Cow2"]:
		var cow := world.get_node_or_null(cname) as Node3D
		if cow != null:
			_cow_detail(cow, hide, dark, horn_m)
	for hname in ["Horse", "Horse2"]:
		var horse := world.get_node_or_null(hname) as Node3D
		if horse != null:
			_horse_detail(horse, leather, dark)
	var ele := world.get_node_or_null("Elephant") as Node3D
	if ele != null:
		_box(ele, Vector3(1.7, 0.15, 1.8), red, Vector3(0.0, 2.75, 0.1), "Howdah72")
		for px in [-0.75, 0.75]:
			for pz in [-0.65, 0.85]:
				_box(ele, Vector3(0.08, 0.70, 0.08), wood, Vector3(px, 3.15, pz), "HowdahPost72_%d_%d" % [int(px * 100.0), int(pz * 100.0)])
		_box(ele, Vector3(1.9, 0.10, 2.0), red, Vector3(0.0, 3.60, 0.1), "HowdahRoof72")
		_box(ele, Vector3(0.12, 0.90, 0.12), dark, Vector3(0.0, 1.80, 1.85), "Tail72")
		_sphere(ele, 0.15, dark, Vector3(0.0, 1.30, 1.85), "TailTuft72")
		for legname in ["EleLegFL", "EleLegFR", "EleLegBL", "EleLegBR"]:
			var leg := ele.get_node_or_null(legname) as Node3D
			if leg != null:
				_box(leg, Vector3(0.52, 0.12, 0.52), horn_m, Vector3(0.0, -0.79, 0.0), "Toenail72")
	# Scenery farm animals live under the EastFields64 group node
	# (a sibling of EastDistrict62, NOT under it — walking only
	# EastDistrict62 misses them entirely, caught by the SIM72
	# count audit), so this walk starts at the world root.
	var dist := world.get_node_or_null("EastDistrict62") as Node3D
	if true:
		var stack: Array = [world]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for child in node.get_children():
				stack.push_back(child)
			if node is Node3D and String(node.name).begins_with("Cow64_"):
				var grp := node as Node3D
				var head := grp.get_node_or_null("Head64") as Node3D
				if head != null:
					_box(head, Vector3(0.14, 0.22, 0.08), hide, Vector3(-0.32, 0.18, 0.0), "Ear72_L")
					_box(head, Vector3(0.14, 0.22, 0.08), hide, Vector3(0.32, 0.18, 0.0), "Ear72_R")
					_cyl(head, 0.02, 0.05, 0.25, horn_m, Vector3(-0.20, 0.32, 0.0), "Horn72_L", Vector3(0.0, 0.0, 0.5))
					_cyl(head, 0.02, 0.05, 0.25, horn_m, Vector3(0.20, 0.32, 0.0), "Horn72_R", Vector3(0.0, 0.0, -0.5))
					_box(head, Vector3(0.40, 0.25, 0.20), hide, Vector3(0.0, -0.05, 0.35), "Muzzle72")
				_box(grp, Vector3(0.08, 0.60, 0.08), dark, Vector3(0.0, 1.15, -1.15), "Tail72")
				for ch in grp.get_children():
					if ch is MeshInstance3D and String(ch.name).begins_with("Leg64_"):
						_box(ch as Node3D, Vector3(0.22, 0.10, 0.22), dark, Vector3(0.0, -0.30, 0.0), "Hoof72")
			elif node is Node3D and String(node.name).begins_with("Chicken64_"):
				var grp2 := node as Node3D
				var head2 := grp2.get_node_or_null("Head64") as Node3D
				if head2 != null:
					_cyl(head2, 0.01, 0.05, 0.14, fruit_c, Vector3(0.0, -0.02, 0.16), "Beak72", Vector3(1.5707963267948966, 0.0, 0.0))
				_box(grp2, Vector3(0.22, 0.28, 0.06), fruit_c, Vector3(0.0, 0.50, -0.28), "Tail72", Vector3(-0.5, 0.0, 0.0))
				_cyl(grp2, 0.03, 0.03, 0.22, fruit_c, Vector3(-0.08, 0.11, 0.0), "Leg72_L")
				_cyl(grp2, 0.03, 0.03, 0.22, fruit_c, Vector3(0.08, 0.11, 0.0), "Leg72_R")
	# Phase 2 — buildings round 2.
	for sname in ["StallCounter_-6_2", "StallCounter_-6_6"]:
		var counter := world.get_node_or_null(sname) as Node3D
		if counter == null:
			continue
		for ci in 2:
			var cx := -0.5 if ci == 0 else 0.5
			_box(counter, Vector3(0.6, 0.4, 0.6), wood, Vector3(cx, 0.70, 0.0), "Crate72_%d" % ci)
			var fm := fruit_a if ci == 0 else fruit_b
			_sphere(counter, 0.13, fm, Vector3(cx - 0.15, 0.98, 0.0), "Fruit72_%d_A" % ci)
			_sphere(counter, 0.13, fm, Vector3(cx + 0.15, 0.98, 0.12), "Fruit72_%d_B" % ci)
			_sphere(counter, 0.13, fm, Vector3(cx, 0.98, -0.12), "Fruit72_%d_C" % ci)
	var tea := world.get_node_or_null("TeaShop13") as Node3D
	if tea != null:
		_box(tea, Vector3(1.8, 0.12, 0.4), wood, Vector3(0.0, 0.45, 1.30), "Bench72_A")
		_box(tea, Vector3(1.8, 0.12, 0.4), wood, Vector3(0.0, 0.45, -1.30), "Bench72_B")
		_box(tea, Vector3(0.8, 0.08, 0.8), wood, Vector3(-1.80, 0.74, 0.0), "SideTable72")
		_box(tea, Vector3(0.15, 0.70, 0.15), wood, Vector3(-1.80, 0.35, 0.0), "SideTableLeg72")
		for ji in 3:
			_cyl(tea, 0.10, 0.10, 0.32, glass, Vector3(-2.05 + float(ji) * 0.25, 0.94, 0.0), "Jar72_%d" % ji)
	var school := world.get_node_or_null("School13") as Node3D
	if school != null:
		for face in [3.04, -3.04]:
			for wx in [-2.5, 0.0, 2.5]:
				_box(school, Vector3(1.2, 1.0, 0.08), dark, Vector3(wx, 1.70, face), "WindowFrame72_%d_%d" % [int(face * 100.0), int(wx * 10.0)])
				_box(school, Vector3(1.0, 0.80, 0.10), glass, Vector3(wx, 1.70, face), "Window72_%d_%d" % [int(face * 100.0), int(wx * 10.0)])
		_box(school, Vector3(1.2, 2.0, 0.12), wood, Vector3(0.0, 1.00, 3.06), "Door72")
		_box(school, Vector3(1.8, 0.20, 0.90), concrete, Vector3(0.0, 0.10, 3.50), "Steps72")
	var night := world.get_node_or_null("NightMarket20") as Node3D
	if night != null:
		for sx in [-4.0, 0.0, 4.0]:
			for ti in 2:
				var tx: float = sx - 0.9 if ti == 0 else sx + 0.9
				_box(night, Vector3(1.6, 0.10, 1.2), wood, Vector3(tx, 0.95, 0.0), "Tray72_%d_%d" % [int(sx), ti])
				_sphere(night, 0.14, fruit_c, Vector3(tx - 0.3, 1.06, 0.25), "Food72_%d_%d_A" % [int(sx), ti])
				_sphere(night, 0.14, fruit_a, Vector3(tx + 0.3, 1.06, -0.25), "Food72_%d_%d_B" % [int(sx), ti])
	var guest := world.get_node_or_null("GuestHouse20") as Node3D
	if guest != null:
		_box(guest, Vector3(1.1, 0.10, 0.7), wood, Vector3(1.20, 0.60, 0.50), "Table72")
		_box(guest, Vector3(0.08, 0.60, 0.60), wood, Vector3(0.75, 0.30, 0.50), "TableLeg72_A")
		_box(guest, Vector3(0.08, 0.60, 0.60), wood, Vector3(1.65, 0.30, 0.50), "TableLeg72_B")
		_cyl(guest, 0.28, 0.28, 0.45, wood, Vector3(0.60, 0.22, 1.40), "Stool72_A")
		_cyl(guest, 0.28, 0.28, 0.45, wood, Vector3(1.80, 0.22, 1.40), "Stool72_B")
		_box(guest, Vector3(0.70, 0.15, 0.40), white, Vector3(-1.20, 0.68, -1.00), "Pillow72")
	# Hospital entrance (world coords; hospital node is scaled
	# 1.8/1.3/1.6, so dressing goes on the world, not under it).
	_box(world, Vector3(4.0, 0.15, 1.2), concrete, Vector3(122.0, 2.90, 62.70), "HospCanopy72")
	_box(world, Vector3(0.15, 2.90, 0.15), concrete, Vector3(120.60, 1.45, 63.20), "HospPost72_L")
	_box(world, Vector3(0.15, 2.90, 0.15), concrete, Vector3(123.40, 1.45, 63.20), "HospPost72_R")
	_box(world, Vector3(3.2, 0.25, 1.0), concrete, Vector3(122.0, 0.12, 62.60), "HospSteps72")
	_box(world, Vector3(1.3, 1.3, 0.10), white, Vector3(122.0, 2.30, 62.06), "HospSign72")
	_box(world, Vector3(0.32, 1.05, 0.12), red, Vector3(122.0, 2.30, 62.08), "HospCrossV72")
	_box(world, Vector3(1.05, 0.32, 0.12), red, Vector3(122.0, 2.30, 62.08), "HospCrossH72")
	# Phase 3 — roads + sky.
	if dist != null:
		_box(dist, Vector3(195.0, 0.18, 0.30), concrete, Vector3(347.50, 0.15, -6.15), "Curb72_N")
		_box(dist, Vector3(195.0, 0.18, 0.30), concrete, Vector3(347.50, 0.15, 6.15), "Curb72_S")
		for pi in 4:
			var px: float = [300.0, 350.0, 405.0, 340.0][pi]
			var pz: float = [3.0, -3.5, 2.5, -50.0][pi]
			var pr: float = [1.4, 1.8, 1.2, 1.5][pi]
			var py := 0.14 if pi < 3 else 0.12
			var pud := _cyl(dist, pr, pr, 0.02, puddle_m, Vector3(px, py, pz), "Puddle72_%d" % pi)
			pud.visible = false
			_puddles.append(pud)
	for ci in 4:
		var cx: float = [-20.0, 150.0, 300.0, 420.0][ci]
		var cy: float = [48.0, 52.0, 46.0, 50.0][ci]
		var cz: float = [-150.0, -170.0, -160.0, -120.0][ci]
		var cl := _sphere(world, 6.0, cloud_m, Vector3(cx, cy, cz), "Cloud72_%d" % ci)
		cl.scale = Vector3(2.0, 0.5, 1.0)
	for hi in 6:
		var hx: float = [-20.0, 120.0, 260.0, 400.0, -66.0, -66.0][hi]
		var hz: float = [-195.0, -198.0, -195.0, -198.0, -80.0, 40.0][hi]
		var hr: float = [40.0, 34.0, 42.0, 30.0, 32.0, 36.0][hi]
		var hh: float = [24.0, 19.0, 26.0, 17.0, 20.0, 22.0][hi]
		_cyl(world, 0.5, hr, hh, hill_m, Vector3(hx, hh * 0.5, hz), "Hill72_%d" % hi)


func _process(delta: float) -> void:
	_frames += 1
	if not _captured:
		if _frames < 20:
			return
		var world := get_parent() as Node3D
		if world == null:
			return
		_capture(world)
		return
	# Rain-only puddles: season62 0 summer, 1 rainy, 2 winter.
	var sm := get_tree().root.get_node_or_null("SaveManager")
	var rainy := false
	if sm != null and sm.get("season62") != null:
		rainy = int(sm.get("season62")) == 1
	if rainy != _puddle_visible:
		_puddle_visible = rainy
		for p in _puddles:
			(p as Node3D).visible = rainy
