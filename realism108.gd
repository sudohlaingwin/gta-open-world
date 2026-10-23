extends Node3D

## Slice 107 (parent sequence): DETAIL ROUND 6 — pond reed rings,
## skyline completion, bicycle kickstand, MRTV mast, EF stilt-house
## sheet details. Audit-first, live-probed 2026-10-24:
## - Pond62A (300,-60, r 6) nearest reed 55.34 m away; Pond62B
##   (415,45, r 5) nearest reed 151.38 m away (audit108b). Both
##   have S93 lotus pads/flowers but NO reed ring — west Pond97
##   got its ring in S106, these two did not. Each gets an
##   8-cluster x 3-stalk ring at pond radius + 0.8 (S106 pattern).
##   S97's Pond98 pair already have 4 reeds each (audit108b).
## - Skyline: north (S99) + east (S100) bands exist; south and
##   west bands do NOT (Skyline rec = 32 = 16 + 16, audit108).
##   South mirrors north (16 boxes + 8 gated dots, dots on the
##   north faces); west mirrors east (dots on the east faces).
##   Bands sit 60+ m beyond their clamps, exactly like the
##   north/east precedent — distant silhouettes, not playable
##   ground (stated, same as S99/S100).
## - Bicycle kickstand: motorcycle has Stand99, bicycle has
##   NONE (audit108). Rear-wheel-relative placement, like the
##   S104 chain set (reads the live wheel node, no assumed
##   geometry). One static prop — no parking mechanic.
## - MRTV antenna mast: MindonMRTV is the TV station and has
##   NO mast (audit108c) — its defining feature is missing.
##   Pole + 2 crossbars + dish + red/white bands, as a child
##   of the group in LOCAL coords (roof apex local 6.6 per
##   S99, so the pole spans local 6.4..10.4 and inherits the
##   group scale, whatever it is — S104's 1.7-vs-1.8 lesson:
##   never hardcode a group scale). Static only, no blinking.
## - EF stilt houses (12): the owner's sheet stilt house shows
##   a clothesline + firewood as signature features, and NO
##   stilt house in the game has either (WORLD clothes = 1
##   village line only, audit108e; firewood lives at village +
##   hamlet only). Each EF house gets 1 clothesline assembly
##   (2 poles + line + 3 garments) on its BACK side + 1
##   firewood stack (3 logs) on its side — 24 assemblies.
##   Placed in WORLD coords from the chill_world62 layout
##   table (positions exact, no group-scale assumption):
##   back offset 5.0 m clears the S99 solid (world half-depth
##   3.93 at x1.5 scale, 2.62 unscaled — safe under either);
##   side offset 6.2 m clears the solid half-width (5.43 at
##   x1.5, 3.62 unscaled). House 8 (345,16) is the stream
##   house: its clothesline span is shifted west to centre
##   x 343 (poles 341..345, 2 m clear of the stream edge
##   x 347) and its firewood goes on the WEST side (x 338.8,
##   8.2 m clear of the stream). Clotheslines hang below
##   the raised back windows (garments y ~1.2, windows
##   world y ~4.05) — no window is hidden.
## Deliberately NOT added (audited, reasons stand): MD1/2/3/6/10
## (S103, permanent); MindonPost/MDHouse8 relocation (owner
## order 2026-10-22 — the overlap stands); S104/S105/S106
## audited-present items (markets/tea/monastery/zayat/school/
## pagoda dressing, scarecrows, ploughs, kilometre posts,
## vehicle trim incl. Tail99/Stand99/Bag99/Mud99/Bump99/
## Harness105/Nav99, market umbrellas, vendor figures);
## Cow2 (ambient, not rideable); traffic-car drivers (solid
## cabins, would not read); bus door window (strip already
## spans above the door); temple bell / traffic lights
## (invented / no logic); hill summit dressing (hills sit
## BEHIND the S106 border forest, barely visible at phone
## distance — low value, stated); marginal night residuals
## (rows band 1.41 m gap, spur 1.3 m, junction 4.5 m,
## hill-face 4.71 m — NOT padded with more lamps).
## Counting (stated): pond ring = 1 per pond; skyline band = 1
## per band (S99/S100 precedent: 16 boxes + 8 dots = 1);
## kickstand = 1; mast assembly = 1 (pole + bars + dish +
## bands, S98 flag precedent); clothesline = 1 per house;
## firewood stack = 1 per house. TOTAL: 2 + 2 + 1 + 1 + 24 = 30
## honest items — under the ~50 target, NO padding.
## Runtime dressing ONLY, no .tscn edits, no bus-system
## changes, minibus NOT rewired, big bus NOT rewired
## (Slice 81 limit), touch controls untouched, zero NEW
## colliders, StandardMaterial3D only, no dead specular
## lines, no fog/SSAO/glow claims (no WorldEnvironment
## exists), no photorealism claims: stylised smooth
## procedural work. Runs at frame >= 340, after
## realism107's 320 pass.
## Honest limit: phone feel unproven until the owner's vivo
## V60 verdict. Backlog note: after this slice the
## graphics backlog is nearly exhausted for proven gaps —
## what remains is Stilt97/Stilt13/hamlet clotheslines +
## firewood (same treatment, different layouts — survey
## first), hill dressing (low value, above), and the
## standing conflicts/residuals. The owner's phone
## verdicts on S96-S106 are the real bottleneck now.

var _frames: int = 0
var _done: bool = false
var _glows: Array = []

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism108") != null:
		return
	var n := Node3D.new()
	n.name = "Realism108"
	n.set_script(load("res://realism108.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 340:
		_done = true
		_apply(get_parent() as Node3D)
	var world := get_parent() as Node3D
	if world == null:
		return
	var day := _daylight(world)
	for g in _glows:
		var m := g as Node3D
		if m != null:
			m.visible = day < 0.15

static func _daylight(world: Node3D) -> float:
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		return float(dn.call("daylight"))
	return 1.0

static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
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

static func _find(world: Node, nm: String) -> Node:
	if world == null:
		return null
	if String(world.name) == nm:
		return world
	for c in world.get_children():
		var r := _find(c, nm)
		if r != null:
			return r
	return null

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_ponds(world)
	_skyline(world)
	_kickstand(world)
	_mast(world)
	_ef_sheet(world)

func _ponds(world: Node3D) -> void:
	var reed_m := _mat(Color(0.25, 0.55, 0.25, 1.0), 1.0)
	for pond in [[300.0, -60.0, 6.8, "A"], [415.0, 45.0, 5.8, "B"]]:
		var cx := float(pond[0])
		var cz := float(pond[1])
		var rr := float(pond[2])
		var tag := String(pond[3])
		for ci in 8:
			var ang := float(ci) * 0.7853981633974483
			var px := cx + rr * cos(ang)
			var pz := cz + rr * sin(ang)
			for si in 3:
				var ox := float([-0.25, 0.0, 0.25][si])
				var oz := float([0.2, -0.15, 0.1][si])
				_cyl(world, 0.03, 0.03, 1.2, reed_m, Vector3(px + ox, 0.6, pz + oz), "Reed108_%s_%d_%d" % [tag, ci, si])

func _skyline(world: Node3D) -> void:
	var sky_m := _mat(Color(0.10, 0.12, 0.20, 1.0), 1.0)
	var glow_m := _mat(Color(1.0, 0.75, 0.45, 1.0), 1.0)
	glow_m.emission_enabled = true
	glow_m.emission = Color(1.0, 0.70, 0.35, 1.0)
	glow_m.emission_energy_multiplier = 1.6
	# South band: mirrors S99 north (dots on the north faces,
	# facing the world).
	for k in range(16):
		var x := -600.0 + 240.0 * float(k)
		var z := -570.0 - float(k % 3) * 15.0
		var h := 12.0 + float((k * 7) % 17)
		var w := 30.0 + float((k * 13) % 50)
		_box(world, Vector3(w, h, 20.0), sky_m, Vector3(x, h * 0.5, z), "SkylineS108_%d" % k)
		if k % 2 == 0:
			var dot := _box(world, Vector3(1.5, 2.0, 0.10), glow_m, Vector3(x, 6.0 + float(k % 4) * 3.0, z + 10.06), "SkyDotS108_%d" % k)
			dot.visible = false
			_glows.append(dot)
	# West band: mirrors S100 east (dots on the east faces,
	# facing the world).
	for k in range(16):
		var z2 := -480.0 + 60.0 * float(k)
		var x2 := -730.0 - float(k % 3) * 15.0
		var h2 := 12.0 + float((k * 7) % 17)
		var w2 := 30.0 + float((k * 13) % 50)
		_box(world, Vector3(20.0, h2, w2), sky_m, Vector3(x2, h2 * 0.5, z2), "SkylineW108_%d" % k)
		if k % 2 == 0:
			var dot := _box(world, Vector3(0.10, 2.0, 1.50), glow_m, Vector3(x2 + 10.06, 6.0 + float(k % 4) * 3.0, z2), "SkyDotW108_%d" % k)
			dot.visible = false
			_glows.append(dot)

func _kickstand(world: Node3D) -> void:
	var bike := world.get_node_or_null("Bicycle") as Node3D
	if bike == null:
		return
	var wb := bike.get_node_or_null("BikeWheelB") as Node3D
	if wb == null:
		return
	var steel := _mat(Color(0.15, 0.15, 0.15, 1.0), 0.5, 0.3)
	var wy: float = wb.position.y
	_box(bike, Vector3(0.05, wy, 0.05), steel, Vector3(wb.position.x - 0.28, wy * 0.5, wb.position.z), "Stand108_Bike", Vector3(0.0, 0.0, 0.45))

func _mast(world: Node3D) -> void:
	var grp := world.get_node_or_null("MindonMRTV") as Node3D
	if grp == null:
		return
	var dark := _mat(Color(0.20, 0.20, 0.22, 1.0), 0.6, 0.4)
	var red := _mat(Color(0.80, 0.15, 0.15, 1.0), 0.6)
	var white := _mat(Color(0.95, 0.95, 0.95, 1.0), 0.6)
	# Local coords: roof apex local 6.6 (S99), so the pole
	# spans 6.4..10.4 and inherits the group scale.
	_cyl(grp, 0.08, 0.08, 4.0, dark, Vector3(0.0, 8.4, 0.0), "Mast108_Pole")
	_cyl(grp, 0.09, 0.09, 0.5, red, Vector3(0.0, 7.0, 0.0), "Mast108_BandR")
	_cyl(grp, 0.09, 0.09, 0.5, white, Vector3(0.0, 7.6, 0.0), "Mast108_BandW")
	_box(grp, Vector3(1.2, 0.06, 0.06), dark, Vector3(0.0, 9.2, 0.0), "Mast108_BarA")
	_box(grp, Vector3(1.2, 0.06, 0.06), dark, Vector3(0.0, 10.0, 0.0), "Mast108_BarB")
	_cyl(grp, 0.5, 0.5, 0.08, white, Vector3(0.6, 9.6, 0.0), "Mast108_Dish", Vector3(0.0, 0.0, 1.5708))

func _ef_sheet(world: Node3D) -> void:
	# chill_world62 layout table: [x, z, type] where type 0 =
	# north row (front +z, back -z), 1 = south row (front -z,
	# back +z), 2 = east-facing pair (front +x, back -x).
	var houses: Array = [
		[270.0, -16.0, 0], [300.0, -16.0, 0], [330.0, -16.0, 0],
		[360.0, -16.0, 0], [390.0, -16.0, 0], [420.0, -16.0, 0],
		[285.0, 16.0, 1], [315.0, 16.0, 1], [345.0, 16.0, 1],
		[405.0, 16.0, 1], [330.0, -40.0, 2], [330.0, -70.0, 2],
	]
	var wood_m := _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	var line_m := _mat(Color(0.80, 0.80, 0.80, 1.0), 0.9)
	var bark_m := _mat(Color(0.35, 0.22, 0.12, 1.0), 1.0)
	var garments: Array = [
		_mat(Color(0.95, 0.95, 0.95, 1.0), 0.9),
		_mat(Color(0.45, 0.20, 0.60, 1.0), 0.9),
		_mat(Color(0.95, 0.60, 0.70, 1.0), 0.9),
	]
	for i in range(12):
		var hx := float(houses[i][0])
		var hz := float(houses[i][1])
		var ty := int(houses[i][2])
		# Back centre: 5.0 m behind the house centre.
		var bcx := hx
		var bcz := hz
		if ty == 0:
			bcz = hz - 5.0
		elif ty == 1:
			bcz = hz + 5.0
		else:
			bcx = hx - 5.0
		# House 8 (345,16) is the stream house: shift the
		# span west so the east pole stays 2 m clear of the
		# stream edge x 347.
		var scx := bcx
		var scz := bcz
		if i == 8:
			scx = 343.0
		var span_x := ty != 2
		var p1 := Vector3(scx - 2.0, 0.85, scz) if span_x else Vector3(scx, 0.85, scz - 2.0)
		var p2 := Vector3(scx + 2.0, 0.85, scz) if span_x else Vector3(scx, 0.85, scz + 2.0)
		_cyl(world, 0.05, 0.05, 1.7, wood_m, p1, "Line108_%d_PoleA" % i)
		_cyl(world, 0.05, 0.05, 1.7, wood_m, p2, "Line108_%d_PoleB" % i)
		if span_x:
			_box(world, Vector3(4.0, 0.02, 0.02), line_m, Vector3(scx, 1.6, scz), "Line108_%d_Line" % i)
		else:
			_box(world, Vector3(0.02, 0.02, 4.0), line_m, Vector3(scx, 1.6, scz), "Line108_%d_Line" % i)
		for gi in 3:
			var off := -1.3 + 1.3 * float(gi)
			if span_x:
				_box(world, Vector3(0.55, 0.75, 0.03), garments[gi], Vector3(scx + off, 1.2, scz), "Line108_%d_Garment%d" % [i, gi])
			else:
				_box(world, Vector3(0.03, 0.75, 0.55), garments[gi], Vector3(scx, 1.2, scz + off), "Line108_%d_Garment%d" % [i, gi])
		# Firewood: 6.2 m to the side (house 8: west side,
		# away from the stream).
		var fx := hx
		var fz := hz
		if ty == 2:
			fz = hz - 6.2
		elif i == 8:
			fx = hx - 6.2
		else:
			fx = hx + 6.2
		if ty == 2:
			_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx - 0.18, 0.15, fz), "Wood108_%d_A" % i, Vector3(0.0, 0.0, 1.5708))
			_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx + 0.18, 0.15, fz), "Wood108_%d_B" % i, Vector3(0.0, 0.0, 1.5708))
			_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx, 0.42, fz), "Wood108_%d_C" % i, Vector3(0.0, 0.0, 1.5708))
		else:
			_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx, 0.15, fz - 0.18), "Wood108_%d_A" % i, Vector3(1.5708, 0.0, 0.0))
			_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx, 0.15, fz + 0.18), "Wood108_%d_B" % i, Vector3(1.5708, 0.0, 0.0))
			_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx, 0.42, fz), "Wood108_%d_C" % i, Vector3(1.5708, 0.0, 0.0))
