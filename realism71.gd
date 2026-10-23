extends Node3D
## Slice 71 — graphics realism pass, part 2 (owner order 2026-10-23
## 06:32, binding: graphics FIRST, no new feature). Slice 70 did
## houses + people + ground + lighting; this round does the next
## most visible toy-looking elements, all procedural, own work,
## no external assets, no copied opponent shaders, no scanned
## texture claimed. Runtime-only: no scene file is touched, no
## positions moved, no colliders added, no gameplay code changed,
## no new feature/quest/sign/label/system.
## - TREES: every canopy sphere gets 3 layered foliage spheres
##   as children (they sway WITH the canopy, they share the
##   canopy's own material object so Slice 62 season tints keep
##   working on them); trunks get a vertical-bark grayscale
##   texture set in place (never duplicated, never reassigned).
## - PALMS: drooping frond rings on the bare Palm20 trunks and
##   extra fronds on the Palm18 groups.
## - VEHICLES: hub caps on every existing wheel (children of
##   the wheel nodes, so they inherit the axle rotation), glass
##   side windows + windshield + rear window + headlights +
##   taillights + bumpers on the car, real wheels + headlight +
##   handlebar + seat on the motorcycle, big spoked side wheels
##   + side rails on the cart, hub caps on the tuk-tuk wheels.
##   Everything is parented to its vehicle node, so it travels
##   when the vehicle is driven — nothing is left floating in
##   world space.
## - WATER: thin ripple planes above the river and the two
##   ponds (the ponds' own materials are NOT touched — Slice 65
##   deliberately left ponds as still water, and this plane is
##   only a gentle 0.02/s shimmer on top). The stream is NOT
##   touched: Slice 65 already scrolls its own material.
## - PAGODA + MONASTERY: 3 tiered eave slabs over the pagoda
##   terraces (sized to clear the Slice 57 lantern posts at
##   r 8.2 and the platform radius 9.0), a pavilion roof slab +
##   ridge beam over the monastery bell posts (posts top out
##   at y 3.2, the slab sits on them at 3.28).
## Capture runs once at frame >= 16, after Slice 70's frame-12
## capture; _process then stays alive ONLY to scroll the ripple
## planes (a few material offsets per frame, no mesh work).

var _frames: int = 0
var _captured: bool = false
var _scrolls: Array = []


static func _h(x: int, y: int, seed: int) -> float:
	var v := sin(float(x) * 127.1 + float(y) * 311.7 + float(seed) * 74.7) * 43758.5453
	return v - floor(v)


static func _make_tex(kind: String) -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var b: float = 1.0
			if kind == "bark":
				# Vertical bark streaks: dark fissure lines in
				# a few columns, grain jitter down each column.
				if x % 11 < 2:
					b = 0.55
				else:
					b = 0.88 + _h(x, y, 80) * 0.12
				b *= 0.96 + _h(0, y, 81) * 0.04
			else:  # ripple
				# Soft concentric ripple rings + noise, so a
				# scrolling offset reads as moving water.
				var dx := float(x) - 32.0
				var dy := float(y) - 32.0
				var d := sqrt(dx * dx + dy * dy)
				b = 0.82 + 0.18 * sin(d * 0.9) * (0.7 + 0.3 * _h(x, y, 82))
			img.set_pixel(x, y, Color(b, b, b, 1.0))
	return ImageTexture.create_from_image(img)


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


static func _cyl(parent: Node3D, r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
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


func _capture(world: Node3D) -> void:
	_captured = true
	var bark_tex := _make_tex("bark")
	var ripple_tex := _make_tex("ripple")
	var glass := _mat(Color(0.10, 0.16, 0.22, 1.0), 0.15)
	glass.metallic = 0.4
	var dark_metal := _mat(Color(0.15, 0.15, 0.16, 1.0), 0.5)
	dark_metal.metallic = 0.6
	var head_mat := _mat(Color(1.0, 0.95, 0.75, 1.0), 0.4)
	head_mat.emission_enabled = true
	head_mat.emission = Color(1.0, 0.9, 0.6, 1.0)
	head_mat.emission_energy_multiplier = 0.6
	var tail_mat := _mat(Color(0.75, 0.08, 0.08, 1.0), 0.4)
	var terra := _mat(Color(0.62, 0.33, 0.20, 1.0), 0.85)
	var wood_dark := _mat(Color(0.30, 0.20, 0.11, 1.0), 0.9)
	var bike_tire_mat: Material = null
	# Phase 1 — collect (never mutate while iterating the tree).
	var canopies: Array = []
	var trunk_mats: Array = []
	var palm_leaf_mat: Material = null
	var stack: Array = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			var nm := String(mi.name)
			var mat := mi.get_surface_override_material(0)
			if nm.begins_with("TreeTop") or (nm.begins_with("Canopy64") and "Top" not in nm) or (nm.begins_with("Chill62_Canopy") and "Top" not in nm):
				if mi.mesh is SphereMesh and mat != null:
					canopies.append(mi)
			elif nm.begins_with("TreeTrunk") or nm == "Trunk62" or nm == "Trunk64":
				if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture == null:
					if not trunk_mats.has(mat):
						trunk_mats.append(mat)
			elif nm.begins_with("PalmLeaf") and palm_leaf_mat == null:
				palm_leaf_mat = mat
	if palm_leaf_mat == null:
		palm_leaf_mat = _mat(Color(0.12, 0.45, 0.18, 1.0), 1.0)
	for m in trunk_mats:
		(m as StandardMaterial3D).albedo_texture = bark_tex
	# Phase 2 — layered foliage (children of the canopy, sharing
	# its material object, so season tints still apply to them).
	for c in canopies:
		var cm := c as MeshInstance3D
		var r := (cm.mesh as SphereMesh).radius
		var cmat := cm.get_surface_override_material(0)
		_sphere(cm, r * 0.58, cmat, Vector3(0.65 * r, 0.45 * r, 0.1 * r), "Layer71_A")
		_sphere(cm, r * 0.58, cmat, Vector3(-0.65 * r, 0.45 * r, -0.1 * r), "Layer71_B")
		_sphere(cm, r * 0.55, cmat, Vector3(0.0, 0.8 * r, 0.0), "Layer71_C")
	# Phase 3 — palms.
	for gname in ["Palm18A", "Palm18B"]:
		var grp := world.get_node_or_null(gname) as Node3D
		if grp == null:
			continue
		for ai in 4:
			var a := float(ai) * 1.5707963267948966
			_box(grp, Vector3(0.22, 0.05, 1.9), palm_leaf_mat, Vector3(sin(a) * 0.9, 5.7, cos(a) * 0.9), "Frond71_%d" % ai, Vector3(0.6, a, 0.0))
	var pstack: Array = [world]
	while not pstack.is_empty():
		var node: Node = pstack.pop_back()
		for child in node.get_children():
			pstack.push_back(child)
		if node is MeshInstance3D and String(node.name).begins_with("Palm20") and (node as MeshInstance3D).mesh is CylinderMesh:
			var pm := node as MeshInstance3D
			for ai in 6:
				var a := float(ai) * 1.0471975511965976
				_box(pm, Vector3(0.22, 0.05, 1.9), palm_leaf_mat, Vector3(sin(a) * 0.8, 4.85, cos(a) * 0.8), "Frond71_%d" % ai, Vector3(0.6, a, 0.0))
	# Phase 4 — vehicles (children of the vehicle nodes).
	var car := world.get_node_or_null("Car") as Node3D
	if car != null:
		var tire_mat: Material = null
		for ch in car.get_children():
			if ch is MeshInstance3D and String(ch.name).begins_with("WheelCar"):
				var wh := ch as MeshInstance3D
				if tire_mat == null:
					tire_mat = wh.get_surface_override_material(0)
				if bike_tire_mat == null:
					bike_tire_mat = wh.get_surface_override_material(0)
				var wh_h := 0.3
				if wh.mesh is CylinderMesh:
					wh_h = (wh.mesh as CylinderMesh).height
				_cyl(wh, 0.12, wh_h + 0.08, dark_metal, Vector3.ZERO, "Hub71")
		if tire_mat == null:
			tire_mat = dark_metal
		_box(car, Vector3(0.06, 0.32, 2.0), glass, Vector3(1.01, 0.12, 0.0), "Window71_L")
		_box(car, Vector3(0.06, 0.32, 2.0), glass, Vector3(-1.01, 0.12, 0.0), "Window71_R")
		_box(car, Vector3(1.7, 0.32, 0.06), glass, Vector3(0.0, 0.12, -2.01), "Windshield71")
		_box(car, Vector3(1.7, 0.32, 0.06), glass, Vector3(0.0, 0.12, 2.01), "RearWindow71")
		_box(car, Vector3(0.32, 0.12, 0.06), head_mat, Vector3(0.6, -0.12, -2.02), "Headlight71_L")
		_box(car, Vector3(0.32, 0.12, 0.06), head_mat, Vector3(-0.6, -0.12, -2.02), "Headlight71_R")
		_box(car, Vector3(0.32, 0.12, 0.06), tail_mat, Vector3(0.6, -0.12, 2.02), "Taillight71_L")
		_box(car, Vector3(0.32, 0.12, 0.06), tail_mat, Vector3(-0.6, -0.12, 2.02), "Taillight71_R")
		_box(car, Vector3(1.9, 0.18, 0.15), dark_metal, Vector3(0.0, -0.32, -2.02), "Bumper71_F")
		_box(car, Vector3(1.9, 0.18, 0.15), dark_metal, Vector3(0.0, -0.32, 2.02), "Bumper71_R")
	var bike := world.get_node_or_null("Motorcycle") as Node3D
	if bike != null:
		var bmat: Material = bike_tire_mat
		if bmat == null:
			bmat = dark_metal
		for wi in 2:
			var wz := -0.7 if wi == 0 else 0.7
			var wheel := _cyl(bike, 0.38, 0.18, bmat, Vector3(0.0, -0.55, wz), "Wheel71_%d" % wi, Vector3(0.0, 0.0, -1.5707963267948966))
			_cyl(wheel, 0.10, 0.24, dark_metal, Vector3.ZERO, "Hub71")
		_box(bike, Vector3(0.22, 0.15, 0.06), head_mat, Vector3(0.0, 0.12, -1.02), "Headlight71")
		_box(bike, Vector3(0.55, 0.06, 0.06), dark_metal, Vector3(0.0, 0.48, -0.7), "Handlebar71")
		_box(bike, Vector3(0.4, 0.1, 0.7), dark_metal, Vector3(0.0, 0.45, 0.3), "Seat71")
	var cart := world.get_node_or_null("Cart") as Node3D
	if cart != null:
		var cart_wood: Material = null
		for ch in cart.get_children():
			if ch is MeshInstance3D:
				cart_wood = (ch as MeshInstance3D).get_surface_override_material(0)
				break
		if cart_wood == null:
			cart_wood = wood_dark
		for si in 2:
			var sx := 1.15 if si == 0 else -1.15
			var wheel := _cyl(cart, 0.55, 0.15, cart_wood, Vector3(sx, -0.55, 0.0), "Wheel71_%d" % si, Vector3(0.0, 0.0, -1.5707963267948966))
			_cyl(wheel, 0.14, 0.21, dark_metal, Vector3.ZERO, "Hub71")
			_box(wheel, Vector3(1.0, 0.04, 0.04), cart_wood, Vector3.ZERO, "Spoke71_A")
			_box(wheel, Vector3(0.04, 0.04, 1.0), cart_wood, Vector3.ZERO, "Spoke71_B")
		_box(cart, Vector3(0.08, 0.3, 3.6), cart_wood, Vector3(1.0, 0.55, 0.0), "Rail71_L")
		_box(cart, Vector3(0.08, 0.3, 3.6), cart_wood, Vector3(-1.0, 0.55, 0.0), "Rail71_R")
	var tuk := world.get_node_or_null("TukTuk") as Node3D
	if tuk != null:
		for ch in tuk.get_children():
			if ch is MeshInstance3D and String(ch.name).begins_with("TukWheel"):
				var wh := ch as MeshInstance3D
				var wh_h := 0.25
				if wh.mesh is CylinderMesh:
					wh_h = (wh.mesh as CylinderMesh).height
				_cyl(wh, 0.10, wh_h + 0.06, dark_metal, Vector3.ZERO, "Hub71")
	# Phase 5 — water ripple planes (own materials, scrolled in
	# _process; the river/pond base materials are never touched).
	var river := world.get_node_or_null("River13") as MeshInstance3D
	if river != null:
		var rm := _mat(Color(0.65, 0.85, 1.0, 0.30), 0.15)
		rm.metallic = 0.1
		rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rm.albedo_texture = ripple_tex
		var rp := MeshInstance3D.new()
		rp.name = "Ripple71_River"
		var pm := PlaneMesh.new()
		pm.size = Vector2(100.0, 6.0)
		rp.mesh = pm
		rp.position = Vector3(0.0, 0.10, 44.0)
		rp.set_surface_override_material(0, rm)
		world.add_child(rp)
		_scrolls.append([rm, 0.05])
	var dist := world.get_node_or_null("EastDistrict62") as Node3D
	if dist != null:
		for pname in ["Pond62A", "Pond62B"]:
			var pond := dist.get_node_or_null(pname) as MeshInstance3D
			if pond == null or not (pond.mesh is CylinderMesh):
				continue
			var pr := (pond.mesh as CylinderMesh).top_radius
			var pm2 := _mat(Color(0.65, 0.85, 1.0, 0.30), 0.15)
			pm2.metallic = 0.1
			pm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			pm2.albedo_texture = ripple_tex
			var disc := _cyl(dist, pr - 0.3, 0.02, pm2, Vector3(pond.position.x, pond.position.y + 0.04, pond.position.z), "Ripple71_" + pname)
			_scrolls.append([pm2, 0.02])
	# Phase 6 — pagoda tiers + monastery bell pavilion roof.
	var pagoda := world.get_node_or_null("Pagoda") as Node3D
	if pagoda != null:
		_box(pagoda, Vector3(11.0, 0.18, 11.0), terra, Vector3(0.0, 1.62, 0.0), "Tier71_0")
		_box(pagoda, Vector3(9.0, 0.18, 9.0), terra, Vector3(0.0, 2.62, 0.0), "Tier71_1")
		_box(pagoda, Vector3(7.0, 0.18, 7.0), terra, Vector3(0.0, 3.62, 0.0), "Tier71_2")
	var bell := world.get_node_or_null("MonasteryBell") as Node3D
	if bell != null:
		var post_mat: Material = wood_dark
		var pl := bell.get_node_or_null("BellPostL") as MeshInstance3D
		if pl != null and pl.get_surface_override_material(0) != null:
			post_mat = pl.get_surface_override_material(0)
		_box(bell, Vector3(2.8, 0.15, 1.6), post_mat, Vector3(0.0, 3.28, 0.0), "BellRoof71")
		_box(bell, Vector3(2.8, 0.12, 0.12), post_mat, Vector3(0.0, 3.43, 0.0), "BellRidge71")


func _process(delta: float) -> void:
	_frames += 1
	if not _captured:
		if _frames < 16:
			return
		var world := get_parent() as Node3D
		if world == null:
			return
		_capture(world)
		return
	for s in _scrolls:
		var m := s[0] as StandardMaterial3D
		var sp := s[1] as float
		var off := m.uv1_offset
		off.x = fmod(off.x + delta * sp, 1.0)
		m.uv1_offset = off
