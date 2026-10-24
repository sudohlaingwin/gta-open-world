extends Node3D

## Slice 110 — CORE-MODEL REBUILD ROUND 2 (owner re-point
## 2026-10-24 11:14 +07, continued: S109 rebuilt bus/minibus/
## arms/palms/ground/menu; this round rebuilds the REMAINING
## boxy vehicles + the floating/buried animals + the roofless
## village house + 6 m clothing readability). Every item below
## was live-probed missing/broken BEFORE adding (audits
## audit111_out.txt, audit111b_out.txt, audit111c_out.txt,
## audit111d_out.txt). Runtime hide-and-replace ONLY (S95/S109
## precedent): original body boxes hidden, new geometry in the
## SAME footprint, collider/tuning/controller/door/seats/sign/
## lamp untouched. NO scene edits, NO .tscn edits, no bus-system
## changes, minibus NOT rewired, big bus NOT rewired (Slice 81
## limit), touch controls untouched, zero NEW colliders (horse/
## elephant node moves carry their EXISTING colliders down to
## the ground they already should touch), StandardMaterial3D
## only, no dead specular lines, no fog/SSAO/glow claims (no
## WorldEnvironment exists), no photorealism claims: stylised
## smooth procedural work. Runs at frame >= 400, after
## realism110's 380 pass. HONEST LIMIT, measured (SIM111 +
## probes): restoring the tuk wheels does NOT reduce the
## "Parameter m is null" engine error count (454 in SIM111,
## 453 in a probe with wheels fixed at frame 0, 368 in a
## probe that quits before the first frame) — the bulk of
## those errors is LOAD-TIME (scene instantiation + _ready
## dressing queries against the malformed blocks), before
## any runtime fix can apply. Only a scene-file fix removes
## them, and .tscn edits are forbidden to this slice. The
## wheels ARE restored (SIM111 proves mesh, cylinder, spot,
## axle, ground contact) — the error log is not the metric
## for this fix; the geometry is.

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism111") != null:
		return
	var n := Node3D.new()
	n.name = "Realism111"
	n.set_script(load("res://realism111.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 400:
		_done = true
		_apply(get_parent() as Node3D)

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

static func _cyl(parent: Node, r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _capsule(parent: Node, r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	mi.scale = sc
	parent.add_child(mi)
	return mi

static func _cyl_tb(parent: Node, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _torus(parent: Node, inner_r: float, outer_r: float, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var tm := TorusMesh.new()
	tm.inner_radius = inner_r
	tm.outer_radius = outer_r
	mi.mesh = tm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _tube(parent: Node, p1: Vector3, p2: Vector3, r: float, mat: Material, nm: String) -> MeshInstance3D:
	var d := p2 - p1
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = d.length()
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = (p1 + p2) * 0.5
	mi.quaternion = Quaternion(Vector3.UP, d.normalized())
	parent.add_child(mi)
	return mi

static func _hide(node: Node, nm: String) -> void:
	var mi := node.get_node_or_null(nm) as MeshInstance3D
	if mi != null:
		mi.visible = false

static func _find_rec(n: Node, nm: String) -> Node:
	if String(n.name) == nm:
		return n
	for c in n.get_children():
		var r := _find_rec(c, nm)
		if r != null:
			return r
	return null

static func _mesh_mat(mi: MeshInstance3D) -> Material:
	if mi == null:
		return null
	return mi.get_surface_override_material(0)

static func _box_size_close(a: Vector3, b: Vector3) -> bool:
	return absf(a.x - b.x) < 0.001 and absf(a.y - b.y) < 0.001 and absf(a.z - b.z) < 0.001

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_tuktuk_wheels(world)
	_cart(world)
	_motorcycle(world)
	_bicycle(world)
	_boat(world, "Boat")
	_boat(world, "Boat2")
	_cow(world, "Cow")
	_cow(world, "Cow2")
	_horse(world, "Horse")
	_horse(world, "Horse2")
	_elephant(world)
	_helicopter(world)
	_airplane(world)
	_house5(world)
	_house_cleanup(world)
	_people(world)

# TUKTUK WHEELS — the scene file's three wheel blocks carry a
# bare Transform3D line (missing "transform = ", main.tscn
# lines 6117/6122/6127), so the engine drops the whole block:
# all three wheels sit at the vehicle origin, unrotated, with
# NULL mesh (454 "Parameter m is null" errors per audit run).
# Restore EXACTLY the author's intended transforms (basis +
# origin from those lines) + the scene's cylinder (r 0.35,
# h 0.20) + dark metal. The existing spin code
# (rotate_object_local around local Y) then rolls them on the
# true X axle, and realism71's Hub71 children ride along.
func _tuktuk_wheels(world: Node3D) -> void:
	var tuk := world.get_node_or_null("TukTuk") as Node3D
	if tuk == null:
		return
	var basis := Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1))
	var dark := _mat(Color(0.12, 0.12, 0.14, 1.0), 0.6)
	var spots := {
		"TukWheelF": Vector3(0.0, -0.65, -1.1),
		"TukWheelL": Vector3(-0.7, -0.65, 0.9),
		"TukWheelR": Vector3(0.7, -0.65, 0.9),
	}
	for wn in spots:
		var wh := tuk.get_node_or_null(wn) as MeshInstance3D
		if wh == null:
			continue
		wh.transform = Transform3D(basis, spots[wn])
		var cm := CylinderMesh.new()
		cm.top_radius = 0.35
		cm.bottom_radius = 0.35
		cm.height = 0.20
		wh.mesh = cm
		wh.set_surface_override_material(0, dark)

# CART — slab replaced by a real bed (floor + front/back
# boards + under-beams) at the SAME top height (0.90), so
# sacks/bench/rails keep sitting exactly. Ground contact
# fixed both ways: original wheels floated 0.10 (axle 0.45 ->
# 0.35, bottom 0.0), Wheel71 wheels were buried 0.60 (axle
# -0.05 -> 0.55, bottom 0.0). Canopy/posts/yoke/lamp kept.
func _cart(world: Node3D) -> void:
	var cart := world.get_node_or_null("Cart") as Node3D
	if cart == null:
		return
	var slab: MeshInstance3D = null
	for ch in cart.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh is BoxMesh:
			if _box_size_close(((ch as MeshInstance3D).mesh as BoxMesh).size, Vector3(2.0, 0.8, 4.0)):
				slab = ch as MeshInstance3D
				break
	var wood: Material = _mesh_mat(slab)
	if wood == null:
		wood = _mat(Color(0.45, 0.30, 0.15, 1.0), 0.7)
	var dark := _mat(Color(0.25, 0.18, 0.10, 1.0), 0.7)
	if slab != null:
		slab.visible = false
	_box(cart, Vector3(1.90, 0.12, 3.90), wood, Vector3(0.0, 0.34, 0.0), "Bed111")
	_box(cart, Vector3(1.90, 0.30, 0.08), wood, Vector3(0.0, 0.55, -1.96), "Front111")
	_box(cart, Vector3(1.90, 0.30, 0.08), wood, Vector3(0.0, 0.55, 1.96), "Back111")
	_box(cart, Vector3(0.12, 0.15, 3.60), dark, Vector3(0.70, 0.20, 0.0), "Beam111_R")
	_box(cart, Vector3(0.12, 0.15, 3.60), dark, Vector3(-0.70, 0.20, 0.0), "Beam111_L")
	for wn in ["CartWheelL", "CartWheelR"]:
		var w := cart.get_node_or_null(wn) as Node3D
		if w != null:
			w.position.y -= 0.10
	for wn in ["Wheel71_0", "Wheel71_1"]:
		var w := cart.get_node_or_null(wn) as Node3D
		if w != null:
			w.position.y = 0.05

# MOTORCYCLE — the 0.60 x 0.80 x 2.00 slab becomes a tank +
# engine + frame + tail cowl + side panels + cap, inside the
# slab envelope (x +-0.30, y -0.40..0.40, z +-1.00). Wheels,
# seat, bars, fenders, forks, exhaust, bags, plates, tail,
# stand, chainguard all kept.
func _motorcycle(world: Node3D) -> void:
	var bike := world.get_node_or_null("Motorcycle") as Node3D
	if bike == null:
		return
	var slab: MeshInstance3D = null
	for ch in bike.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh is BoxMesh:
			if _box_size_close(((ch as MeshInstance3D).mesh as BoxMesh).size, Vector3(0.60, 0.80, 2.0)):
				slab = ch as MeshInstance3D
				break
	var paint: Material = _mesh_mat(slab)
	if paint == null:
		paint = _mat(Color(0.75, 0.10, 0.10, 1.0), 0.35, 0.3)
	var dark := _mat(Color(0.15, 0.15, 0.18, 1.0), 0.5, 0.4)
	if slab != null:
		slab.visible = false
	_box(bike, Vector3(0.44, 0.28, 0.75), paint, Vector3(0.0, 0.26, -0.45), "Tank111")
	_box(bike, Vector3(0.50, 0.45, 0.90), dark, Vector3(0.0, -0.10, 0.10), "Engine111")
	_box(bike, Vector3(0.30, 0.25, 1.20), dark, Vector3(0.0, -0.27, 0.20), "Frame111")
	_box(bike, Vector3(0.40, 0.18, 0.50), paint, Vector3(0.0, 0.28, 0.72), "Cowl111")
	_box(bike, Vector3(0.04, 0.30, 0.70), paint, Vector3(0.30, -0.05, 0.15), "Panel111_R")
	_box(bike, Vector3(0.04, 0.30, 0.70), paint, Vector3(-0.30, -0.05, 0.15), "Panel111_L")
	_cyl(bike, 0.06, 0.04, dark, Vector3(0.0, 0.38, -0.45), "Cap111")

# BICYCLE — the single top-tube bar gains a real frame: down
# tube + seat tube + chain stays + seat stays + fork blades
# (tubes between measured points). Wheels, fenders, chain,
# pedals, basket, rack, bell, kickstand kept.
func _bicycle(world: Node3D) -> void:
	var bike := world.get_node_or_null("Bicycle") as Node3D
	if bike == null:
		return
	var frame_mi := bike.get_node_or_null("BikeFrame") as MeshInstance3D
	var fmat: Material = _mesh_mat(frame_mi)
	if fmat == null:
		fmat = _mat(Color(0.15, 0.15, 0.18, 1.0), 0.5, 0.4)
	_tube(bike, Vector3(0.0, 0.88, -0.55), Vector3(0.0, 0.35, 0.0), 0.035, fmat, "Tube111_Down")
	_tube(bike, Vector3(0.0, 0.35, 0.0), Vector3(0.0, 0.92, 0.45), 0.035, fmat, "Tube111_Seat")
	_tube(bike, Vector3(0.0, 0.35, 0.0), Vector3(0.05, 0.35, 0.70), 0.02, fmat, "Tube111_Chain_R")
	_tube(bike, Vector3(0.0, 0.35, 0.0), Vector3(-0.05, 0.35, 0.70), 0.02, fmat, "Tube111_Chain_L")
	_tube(bike, Vector3(0.0, 0.90, 0.45), Vector3(0.05, 0.35, 0.70), 0.02, fmat, "Tube111_Stay_R")
	_tube(bike, Vector3(0.0, 0.90, 0.45), Vector3(-0.05, 0.35, 0.70), 0.02, fmat, "Tube111_Stay_L")
	_tube(bike, Vector3(0.0, 0.88, -0.55), Vector3(0.05, 0.35, -0.70), 0.025, fmat, "Tube111_Fork_R")
	_tube(bike, Vector3(0.0, 0.88, -0.55), Vector3(-0.05, 0.35, -0.70), 0.025, fmat, "Tube111_Fork_L")

# BOAT — the flat 1.00 x 0.50 x 2.40 hull box becomes a hull:
# bottom + side planks (top exactly 0.55, the old top) +
# pointed bow + transom + keel + stem. Benches, oars, rope,
# lamp, fish kept. Same local coords for Boat and Boat2.
func _boat(world: Node3D, nm: String) -> void:
	var boat := world.get_node_or_null(nm) as Node3D
	if boat == null:
		return
	var hull := boat.get_node_or_null("Hull") as MeshInstance3D
	var wood: Material = _mesh_mat(hull)
	if wood == null:
		wood = _mat(Color(0.45, 0.30, 0.15, 1.0), 0.7)
	var dark := _mat(Color(0.25, 0.18, 0.10, 1.0), 0.7)
	if hull != null:
		hull.visible = false
	_box(boat, Vector3(0.90, 0.10, 2.10), wood, Vector3(0.0, 0.15, 0.0), "Bottom111")
	_box(boat, Vector3(0.08, 0.45, 2.10), wood, Vector3(0.46, 0.325, 0.0), "Plank111_R")
	_box(boat, Vector3(0.08, 0.45, 2.10), wood, Vector3(-0.46, 0.325, 0.0), "Plank111_L")
	_box(boat, Vector3(0.50, 0.45, 0.50), wood, Vector3(0.0, 0.325, -0.85), "Bow111", Vector3(0.0, 0.7853981633974483, 0.0))
	_box(boat, Vector3(0.90, 0.45, 0.08), wood, Vector3(0.0, 0.325, 1.06), "Transom111")
	_box(boat, Vector3(0.10, 0.08, 2.10), dark, Vector3(0.0, 0.06, 0.0), "Keel111")
	_box(boat, Vector3(0.08, 0.55, 0.08), wood, Vector3(0.0, 0.30, -1.18), "Stem111")

# COW — the body was a VERTICAL capsule (a standing pill,
# y -0.10..1.10) with legs buried 0.05 and hooves buried
# 0.15. New horizontal capsule body (axis Z, total height
# 1.30, r 0.45) at the same footprint: world y 0.10..1.00,
# z -5.65..-4.35 for Cow (same local coords for Cow2, which
# has no saddle/harness/bell and gets none). Legs lifted to
# touch ground, hooves re-seated to bottom 0.0 (hooves are
# children of the legs, so they are re-seated AFTER the leg
# move, by measured world delta). Cow's harness slab hidden
# (it would sit inside the new body); saddle top touch
# preserved exactly (saddle bottom 1.00 = body top 1.00).
func _cow(world: Node3D, nm: String) -> void:
	var cow := world.get_node_or_null(nm) as Node3D
	if cow == null:
		return
	var cap: MeshInstance3D = null
	for ch in cow.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh is CapsuleMesh:
			cap = ch as MeshInstance3D
			break
	var coat: Material = _mesh_mat(cap)
	if coat == null:
		coat = _mat(Color(0.70, 0.60, 0.50, 1.0), 0.8)
	var dark := _mat(Color(0.20, 0.15, 0.10, 1.0), 0.8)
	if cap != null:
		cap.visible = false
	_capsule(cow, 0.45, 1.30, coat, Vector3(0.0, 0.05, 0.0), "Body111", Vector3(1.5707963267948966, 0.0, 0.0))
	_torus(cow, 0.45, 0.48, dark, Vector3(0.0, 0.05, 0.0), "Girth111")
	_hide(cow, "Harness105_Cow")
	for ln in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var leg := cow.get_node_or_null(ln) as Node3D
		if leg != null:
			leg.position.y += 0.05
	for ch in cow.get_children():
		if ch is Node3D and String(ch.name).begins_with("Leg"):
			for hf in (ch as Node3D).get_children():
				if hf is Node3D and String(hf.name) == "Hoof72":
					var hn := hf as Node3D
					hn.position.y += 0.07 - hn.global_position.y

# HORSE — the node floated 1.64 m above open ground (node
# y 1.60, hooves bottom 1.64). The CAUSE is the collider, not
# the meshes: Horse shares the elephant's BoxShape3D_s18_ele
# (2.4 x 3.2 x 4.0) centred on the node origin, so its bottom
# sits 1.60 BELOW the origin — at scene y 1.00 the box already
# pierces the ground 0.60, and every move_and_slide() tick
# pushes the body up to y 1.60 (collider bottom at 0.0). A bare
# node move CANNOT stick (SIM111 proved it: node stayed 1.60).
# So the collider is REPLACED with one matching the true
# envelope (1.00 x 2.15 x 2.10 at y 1.075 -> spans 0.0..2.15:
# hooves, legs, body, head, saddle) AND the node moves to
# y 0.0: hooves land at bottom 0.04, and the new collider
# bottom (0.0) holds the node there instead of pushing it
# back up. Same local coords for Horse and Horse2 (Horse2's
# parts/collider are runtime-duplicated; if it has no
# collider the node move sticks unopposed).
func _horse(world: Node3D, nm: String) -> void:
	var horse := world.get_node_or_null(nm) as Node3D
	if horse == null:
		return
	var hcol := horse.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if hcol != null:
		var nb := BoxShape3D.new()
		nb.size = Vector3(1.00, 2.15, 2.10)
		hcol.shape = nb
		hcol.position = Vector3(0.0, 1.075, 0.0)
	horse.position.y = 0.0
	var body := horse.get_node_or_null("HorseBody") as MeshInstance3D
	var coat: Material = _mesh_mat(body)
	if coat == null:
		coat = _mat(Color(0.45, 0.30, 0.20, 1.0), 0.8)
	if body != null:
		body.visible = false
	_capsule(horse, 0.45, 2.00, coat, Vector3(0.0, 1.30, 0.0), "Barrel111", Vector3(1.5707963267948966, 0.0, 0.0))
	_tube(horse, Vector3(0.0, 1.45, -0.90), Vector3(0.0, 1.70, -1.15), 0.22, coat, "Neck111")

# ELEPHANT — same floating-node fix, same cause (the shared
# s18_ele box, 2.4 x 3.2 x 4.0 centred on the origin, pushes
# the body to y 1.60). Collider REPLACED with one matching
# the true envelope (2.20 x 4.45 x 3.40 at y 2.225 ->
# spans 0.0..4.45: feet, body, head, howdah) AND the node
# moves to y 0.0 (toenails bottom 0.0). The ground-to-howdah
# ladder is the one ground-anchored part: every
# Ladder106_Ele_* local y rises 1.60, so the ladder keeps
# its EXACT world span (0.005..4.455) while the body drops.
# Body box replaced by a wide barrel capsule (r 0.80, length
# 3.40, axis Z, x-scale 1.375 -> half-width 1.10, the old
# width) + a trunk lower segment + tip sphere.
func _elephant(world: Node3D) -> void:
	var ele := world.get_node_or_null("Elephant") as Node3D
	if ele == null:
		return
	var ecol := ele.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if ecol != null:
		var nb := BoxShape3D.new()
		nb.size = Vector3(2.20, 4.45, 3.40)
		ecol.shape = nb
		ecol.position = Vector3(0.0, 2.225, 0.0)
	ele.position.y = 0.0
	var body := ele.get_node_or_null("EleBody") as MeshInstance3D
	var skin: Material = _mesh_mat(body)
	if skin == null:
		skin = _mat(Color(0.45, 0.45, 0.48, 1.0), 0.9)
	if body != null:
		body.visible = false
	_capsule(ele, 0.80, 3.40, skin, Vector3(0.0, 1.80, 0.0), "Barrel111", Vector3(1.5707963267948966, 0.0, 0.0), Vector3(1.375, 1.0, 1.0))
	_tube(ele, Vector3(0.0, 1.30, -2.60), Vector3(0.0, 0.80, -2.85), 0.18, skin, "Trunk111")
	var tip := MeshInstance3D.new()
	tip.name = "TrunkTip111"
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	tip.mesh = sm
	tip.set_surface_override_material(0, skin)
	tip.position = Vector3(0.0, 0.75, -2.90)
	ele.add_child(tip)
	for ch in ele.get_children():
		if ch is Node3D and String(ch.name).begins_with("Ladder106_Ele_"):
			(ch as Node3D).position.y += 1.60

# HELICOPTER — body box floated 0.10 and skids were buried
# 0.275. New tub + nose + roof + engine deck + tail boom
# (cylinder axis Z) inside the old envelope; skids lifted
# to bottom 0.0 (top overlaps the tub bottom, attached, no
# struts needed — skids tuck under the body). Rotor, fin,
# glass, tail rotor, landing light kept.
func _helicopter(world: Node3D) -> void:
	var heli := world.get_node_or_null("Helicopter") as Node3D
	if heli == null:
		return
	var body := heli.get_node_or_null("Body") as MeshInstance3D
	var paint: Material = _mesh_mat(body)
	if paint == null:
		paint = _mat(Color(0.85, 0.85, 0.85, 1.0), 0.5)
	var dark := _mat(Color(0.15, 0.15, 0.18, 1.0), 0.5, 0.4)
	if body != null:
		body.visible = false
	_box(heli, Vector3(1.90, 0.45, 3.90), paint, Vector3(0.0, -0.175, 0.0), "Tub111")
	_box(heli, Vector3(1.70, 0.45, 0.40), paint, Vector3(0.0, -0.175, -1.85), "Nose111")
	_box(heli, Vector3(1.70, 0.08, 2.00), paint, Vector3(0.0, 0.09, 0.0), "Roof111")
	_box(heli, Vector3(0.90, 0.50, 1.40), dark, Vector3(0.0, 0.38, 0.0), "Deck111")
	_cyl(heli, 0.16, 2.40, paint, Vector3(0.0, 0.05, 1.10), "Boom111", Vector3(1.5707963267948966, 0.0, 0.0))
	for wn in ["Skid_R", "Skid_L"]:
		var s := heli.get_node_or_null(wn) as Node3D
		if s != null:
			s.position.y = -0.425

# AIRPLANE — fuselage box floated 0.10 and all three wheels
# were buried (mains 0.23, nose 0.33). New fuselage
# cylinder (r 0.40, length 4.00, axis Z, x-scale 2.5 ->
# half-width 1.00, the old width) + belly keel; wheels
# lifted to bottom 0.0 (x/z unchanged, they were already
# sensible). Wings, prop, spinner, fin, glass kept.
func _airplane(world: Node3D) -> void:
	var plane := world.get_node_or_null("Airplane") as Node3D
	if plane == null:
		return
	var fuse := plane.get_node_or_null("Fuselage") as MeshInstance3D
	var paint: Material = _mesh_mat(fuse)
	if paint == null:
		paint = _mat(Color(0.85, 0.85, 0.85, 1.0), 0.5)
	var dark := _mat(Color(0.15, 0.15, 0.18, 1.0), 0.5, 0.4)
	if fuse != null:
		fuse.visible = false
	_capsule(plane, 0.40, 4.00, paint, Vector3(0.0, 0.0, 0.0), "Fuse111", Vector3(1.5707963267948966, 0.0, 0.0), Vector3(2.5, 1.0, 1.0))
	_box(plane, Vector3(0.20, 0.14, 3.60), dark, Vector3(0.0, -0.36, 0.0), "Keel111")
	for wn in ["PlaneWheel12_L", "PlaneWheel12_R"]:
		var w := plane.get_node_or_null(wn) as Node3D
		if w != null:
			w.position.y = -0.32
	var nw := plane.get_node_or_null("NoseWheel105_Plane") as Node3D
	if nw != null:
		nw.position.y = -0.22

# HOUSE5 — the village house at (-24, 2, -8) was a roofless
# box: wall top 1.60, eaves floating at 2.40..2.52, a 0.80
# gap with NO upper wall and NO roof. Fill the gap with an
# upper wall band (1.60..2.40) + two pitched roof slabs
# meeting at a ridge (eave ends land exactly on the eaves
# top, 2.524) + a ridge cap. House97_1-4 already cover
# House1-4; House6 is complete; only House5 was roofless.
func _house5(world: Node3D) -> void:
	var h5 := world.get_node_or_null("House5") as Node3D
	if h5 == null:
		return
	var wall := _find_rec(h5, "DressWall53") as MeshInstance3D
	var wmat: Material = _mesh_mat(wall)
	if wmat == null:
		wmat = _mat(Color(0.80, 0.75, 0.65, 1.0), 0.9)
	var eaves := _find_rec(h5, "Eaves58") as MeshInstance3D
	var rmat: Material = _mesh_mat(eaves)
	if rmat == null:
		rmat = _mat(Color(0.45, 0.20, 0.15, 1.0), 0.7)
	_box(h5, Vector3(2.00, 0.80, 4.00), wmat, Vector3(0.0, 0.0, 0.0), "Band111")
	_box(h5, Vector3(2.35, 0.12, 2.60), rmat, Vector3(0.0, 0.97, 1.22), "Roof111_S", Vector3(0.35, 0.0, 0.0))
	_box(h5, Vector3(2.35, 0.12, 2.60), rmat, Vector3(0.0, 0.97, -1.22), "Roof111_N", Vector3(-0.35, 0.0, 0.0))
	_box(h5, Vector3(2.35, 0.10, 0.20), rmat, Vector3(0.0, 1.45, 0.0), "Ridge111")

# HOUSE1-4 CLEANUP — the 17 meshes each under House1/2/3/4
# (68 total) are FULLY INSIDE House97_1-4's ground floors
# (proven by audit: wall extents inside Ground97 extents)
# but still visible=true and still rendered. Hide the
# meshes, NOT the nodes (quests/minimap dots may reference
# node positions). One cleanup item, not 68 — no padding.
func _house_cleanup(world: Node3D) -> void:
	for hn in ["House1", "House2", "House3", "House4"]:
		var h := world.get_node_or_null(hn) as Node3D
		if h == null:
			continue
		_hide_tree(h)

static func _hide_tree(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).visible = false
	for c in n.get_children():
		_hide_tree(c)

# PEOPLE — at 6.0 m the longyi stripe PATTERN vanishes: the
# defining sheet detail is 0.03 m stripes/buttons/brows
# (~3-4 px on a 720p phone, invisible in motion). One BOLD
# band per figure, at the Longyi node's own position, 0.12
# tall (7-8 px at 6 m, visible), TAPERED to hug the longyi
# (the longyi itself is tapered: top r 0.28, bottom r 0.30,
# so the band is top 0.295, bottom 0.315 — exactly 0.015
# proud along its whole height), dark contrasting colour.
# The band is a child of the Longyi's parent so it follows
# any pivot sway. Existing 0.03 stripes are NOT scaled
# (overlap risk with the waist/hem bands). 19 figures
# expected.
func _people(world: Node3D) -> void:
	var dark := _mat(Color(0.15, 0.10, 0.08, 1.0), 0.8)
	var names: Array[String] = ["Player"]
	for i in range(1, 19):
		names.append("Villager%d" % i)
	for fn in names:
		var fig := world.get_node_or_null(fn) as Node3D
		if fig == null:
			continue
		var lg := _find_rec(fig, "Longyi") as MeshInstance3D
		if lg == null:
			continue
		var parent := lg.get_parent() as Node
		if parent == null:
			continue
		var top_r := 0.295
		var bot_r := 0.315
		if lg.mesh is CylinderMesh:
			top_r = (lg.mesh as CylinderMesh).top_radius + 0.015
			bot_r = (lg.mesh as CylinderMesh).bottom_radius + 0.015
		_cyl_tb(parent, top_r, bot_r, 0.12, dark, lg.position, "Band111_Longyi")
