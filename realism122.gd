extends Node3D
## Slice 122 graphics (System v2, target-first: judged by what
## changes at 6 m phone distance, NOT by item count).
## AUDIT (audit122, live headless, dressing complete):
## - World: 11,832 meshes, 9,641 visible, 7,466 BoxMesh (63.1%).
## - GROUND (worst gap): GroundMesh is ONE PlaneMesh 2520x320 in
## ONE colour (0.94,0.92,0.63), and only 15 Ground* nodes exist
## in the whole world — underfoot at 6 m the player walks on a
## flat pale sheet. FIX: patch-based ground variation round 2
## (plaza + scatter + bus-stop aprons, ~39 patches).
## - TREES: 402 trunk-named meshes vs 455 canopy/tier pieces =
## 1.13 canopy pieces per trunk — sticks with blobs. FIX: a
## second canopy sphere on the 140 corridor trees nearest the
## village centre + bus stops (nearest-first, capped).
## - HOUSES: House97 (45 boxes, 3 colours), Stilt97 (49, 4),
## MDHouse4 (71 boxes, 6 colours) — detailed counts but flat
## faces. FIX: contrasting trim (plinth + corner boards + door
## step where the front is known), 5-6 pieces per house.
## - NOT gaps (audit-proven, left alone): the player car already
## has 57 visible meshes (mirrors, handles, plates, exhaust,
## bumpers, trim, arches, wipers, antenna) — car graphics are
## NOT redone. S121 models: 43/43 visible — NOT broken, NOT
## redone. S119 menu untouched.
## EXCLUDED BY STANDING DECISION: MDHouse1/2/3/6/10 stay bare
## (S103 permanent decision — embedded in S56 blocks); MDHouse8
## skipped (MindonPost overlap caution). No other Mindon house
## is touched beyond trim on 4/5/7/9.
## PERFORMANCE NOTE: new names (Ground122_, Canopy122_,
## Trim122_) match NONE of perf120's hide prefixes, so they stay
## visible always. Total added is ~238 meshes (+2.5% of the
## 9,641 visible) — small, and deliberately patch-based (few
## LARGE ground patches, not tuft spam) so the cost stays low.
## Extending perf120's hide list was considered and rejected:
## touching S120's culling logic risks its proof for little gain.
## Zero colliders on all new meshes. StandardMaterial3D only.
## Runs once at frame >= 620 (after Realism121's 600 pass).
## Trunk-top math is approximate (cylinder centre + height/2
## along world Y; trees stand upright in practice) — stated so a
## tilted trunk's canopy offset is not a surprise.

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism122") != null:
		return
	var n := Node3D.new()
	n.name = "Realism122"
	n.set_script(load("res://realism122.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 620:
		_done = true
		_apply(get_parent() as Node3D)

static func _mat(c: Color, rough: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m

static func _box(parent: Node, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
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

func _anchors(world: Node3D) -> Array:
	var out: Array = []
	var player := world.get_node_or_null("Player") as Node3D
	if player != null:
		out.append(player.global_position)
	for i in range(6):
		var stop := world.get_node_or_null("LongRoute74/BusStop74_%d" % i) as Node3D
		if stop != null:
			out.append(stop.global_position)
	return out

func _nearest_anchor_dist(p: Vector3, anchors: Array) -> float:
	var best := 1e9
	for a in anchors:
		var d := (p as Vector3).distance_to(a as Vector3)
		if d < best:
			best = d
	return best

func _ground(world: Node3D, anchors: Array, spawn: Vector3) -> int:
	var n := 0
	var dirt := _mat(Color(0.52, 0.42, 0.30))
	var dirt2 := _mat(Color(0.45, 0.35, 0.25))
	var dry := _mat(Color(0.62, 0.55, 0.38))
	# Ground level from the live GroundMesh plane (never assumed
	# to be 0: the player origin sits ~1 m above it).
	var gy := 0.0
	var gm := world.get_node_or_null("GroundMesh") as Node3D
	if gm != null:
		gy = gm.global_position.y
	# Village plaza: one large worn patch at the spawn.
	_box(self, Vector3(16.0, 0.06, 16.0), dirt, Vector3(spawn.x, gy + 0.03, spawn.z), "Ground122_plaza")
	n += 1
	# Scatter ring around the spawn (golden-angle, deterministic).
	for i in range(20):
		var ang := float(i) * 2.39996
		var rad := 8.0 + float(i % 5) * 7.0
		var sz := 2.0 + float(i % 3)
		var mat: Material = dirt
		if i % 3 == 1:
			mat = dirt2
		elif i % 3 == 2:
			mat = dry
		_box(self, Vector3(sz, 0.06, sz), mat,
			Vector3(spawn.x + cos(ang) * rad, gy + 0.03, spawn.z + sin(ang) * rad),
			"Ground122_scatter_%d" % i)
		n += 1
	# Bus-stop aprons: worn ground where riders wait + board.
	var stops: Array = []
	for a in anchors:
		if (a as Vector3).distance_to(spawn) > 1.0:
			stops.append(a)
	for si in range(stops.size()):
		var s: Vector3 = stops[si]
		_box(self, Vector3(7.0, 0.06, 7.0), dirt, Vector3(s.x, gy + 0.03, s.z), "Ground122_stop_%d" % si)
		n += 1
		for k in range(2):
			var off := Vector3(float(((si * 5 + k * 3) % 7) - 3), 0.0, float(((si * 3 + k * 5) % 7) - 3))
			_box(self, Vector3(3.0, 0.06, 3.0), dirt2 if k == 0 else dry,
				Vector3(s.x + off.x, gy + 0.03, s.z + off.z), "Ground122_stop_%d_%d" % [si, k])
			n += 1
	return n

func _canopy(world: Node3D, anchors: Array) -> int:
	var greens: Array = [Color(0.13, 0.42, 0.16), Color(0.18, 0.52, 0.22), Color(0.10, 0.35, 0.14)]
	var cands: Array = []
	var st: Array = [world]
	while not st.is_empty():
		var x = st.pop_back()
		for c in x.get_children():
			st.append(c)
		if x is MeshInstance3D and String(x.name).contains("Trunk"):
			var mi := x as MeshInstance3D
			if mi.mesh == null:
				continue
			var h := mi.mesh.get_aabb().size.y
			if h < 2.0:
				continue
			var d := _nearest_anchor_dist(mi.global_position, anchors)
			cands.append([d, mi, h])
	cands.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var n := 0
	for e in cands:
		if n >= 140:
			break
		var mi: MeshInstance3D = e[1]
		var h: float = e[2]
		var r := 1.3 + float(n % 6) * 0.1
		var col: Color = greens[n % 3]
		_sphere(self, r, _mat(col), mi.global_position + Vector3(0.0, h * 0.5 + 0.4, 0.0), "Canopy122_%d" % n)
		n += 1
	return n

func _trim_house(holder: Node3D, walls: MeshInstance3D, kind: int) -> int:
	# kind 0 = House97 (plinth + 4 corners + door step, front +z),
	# kind 1 = Stilt97 (floor rim + 4 corners, no plinth/step),
	# kind 2 = Mindon (plinth + 4 corners, front unknown).
	var n := 0
	var wsize: Vector3 = walls.mesh.get_aabb().size
	var wpos: Vector3 = walls.position
	var dark := _mat(Color(0.30, 0.22, 0.14))
	var cream := _mat(Color(0.92, 0.88, 0.78))
	var white := _mat(Color(0.95, 0.93, 0.85))
	var tag := String(holder.name)
	if kind == 0:
		_box(holder, Vector3(wsize.x + 0.12, 0.25, wsize.z + 0.12), dark,
			Vector3(wpos.x, 0.125, wpos.z), "Trim122_%s_plinth" % tag)
		n += 1
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_box(holder, Vector3(0.14, 5.8, 0.14), white,
					Vector3(wpos.x + sx * wsize.x * 0.5, 2.9, wpos.z + sz * wsize.z * 0.5),
					"Trim122_%s_corner_%d_%d" % [tag, int(sx), int(sz)])
				n += 1
		_box(holder, Vector3(1.4, 0.18, 0.7), dark,
			Vector3(wpos.x, 0.09, wpos.z + wsize.z * 0.5 + 0.4), "Trim122_%s_step" % tag)
		n += 1
	elif kind == 1:
		# Rim follows the FLOOR (8.0x6.0), not the walls (7.0x6.0):
		# a walls-sized rim would sit inside the floor box and be
		# invisible. Skip the rim if Floor97 is missing.
		var fl := holder.get_node_or_null("Floor97") as MeshInstance3D
		if fl != null and fl.mesh != null:
			var fsize: Vector3 = fl.mesh.get_aabb().size
			var fpos: Vector3 = fl.position
			_box(holder, Vector3(fsize.x + 0.2, 0.18, fsize.z + 0.2), dark,
				Vector3(fpos.x, fpos.y, fpos.z), "Trim122_%s_rim" % tag)
			n += 1
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_box(holder, Vector3(0.14, wsize.y, 0.14), white,
					Vector3(wpos.x + sx * wsize.x * 0.5, wpos.y, wpos.z + sz * wsize.z * 0.5),
					"Trim122_%s_corner_%d_%d" % [tag, int(sx), int(sz)])
				n += 1
	else:
		_box(holder, Vector3(wsize.x + 0.12, 0.25, wsize.z + 0.12), dark,
			Vector3(wpos.x, wpos.y - wsize.y * 0.5 + 0.125, wpos.z), "Trim122_%s_plinth" % tag)
		n += 1
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_box(holder, Vector3(0.14, wsize.y, 0.14), white,
					Vector3(wpos.x + sx * wsize.x * 0.5, wpos.y, wpos.z + sz * wsize.z * 0.5),
					"Trim122_%s_corner_%d_%d" % [tag, int(sx), int(sz)])
				n += 1
	return n

func _trim(world: Node3D) -> int:
	var n := 0
	for h in world.get_children():
		if not (h is Node3D):
			continue
		var nm := String(h.name)
		if nm in ["House97_1", "House97_2", "House97_3", "House97_4"]:
			var g := (h as Node3D).get_node_or_null("Ground97") as MeshInstance3D
			if g != null and g.mesh != null:
				n += _trim_house(h as Node3D, g, 0)
		elif nm.begins_with("Stilt97_"):
			var w := (h as Node3D).get_node_or_null("Walls97") as MeshInstance3D
			if w != null and w.mesh != null:
				n += _trim_house(h as Node3D, w, 1)
		elif nm in ["MDHouse4", "MDHouse5", "MDHouse7", "MDHouse9"]:
			# MDHouse1/2/3/6/10: PERMANENTLY bare (S103) — never
			# dressed. MDHouse8: skipped (MindonPost overlap).
			var walls: MeshInstance3D = null
			for c in (h as Node3D).get_children():
				if c is MeshInstance3D and String(c.name).contains("Walls"):
					walls = c as MeshInstance3D
					break
			if walls != null and walls.mesh != null:
				n += _trim_house(h as Node3D, walls, 2)
	return n

func _apply(world: Node3D) -> void:
	if world == null:
		return
	var anchors := _anchors(world)
	var player := world.get_node_or_null("Player") as Node3D
	var spawn := Vector3.ZERO
	if player != null:
		spawn = player.global_position
	var g := _ground(world, anchors, spawn)
	var c := _canopy(world, anchors)
	var t := _trim(world)
	print("REALISM122 dressed: ground=", g, " canopy=", c, " trim=", t)
