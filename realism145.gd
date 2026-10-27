extends Node3D

## Slice 145 — animal detail audit round (audit-first, live-probed
## before shipping). Audit145 measured every animal type at 6 m, day
## + night, on the live tree (never the scene file alone, S144
## lesson): rideables + ox are COMPLETE (Cow 25 meshes head 2 /
## legs 4 / tail 2 / horns 2 / ears 2 / 8 albedos, grounded AABB
## y 0..1.28; Horse 26 head 1 / legs 4 / mane 1 / tail 1 / 7
## albedos; Elephant 36 head 1 / legs 4 / trunk 3 / tusks 2 /
## ears 2 / howdah 7 / 10 albedos; Ox125 13/13, S125 reference);
## motion is FULL amplitude on the direct driving path (cow legs
## +/-0.50 + bob +/-0.05, horse legs +/-0.59 + mane +/-0.25 +
## tail +/-0.39, elephant legs +/-0.50 + trunk +/-0.20 + ears
## +/-0.30, EastFields64 heads bob +/-0.10); night vis counts are
## IDENTICAL to day for every animal (no night-gating hides any
## animal; village animals sit in lit areas, field animals are
## dark by nature per S136/S141). THE ONE DEFECT CLASS, the only
## floating animals in the world: (1) PigPen13's two pigs are
## LEGLESS and FLOAT 0.24 m — body centre y 0.45, live half-height
## 0.21 (BoxMesh 0.6 * node scale y 0.7 / 2), so body bottom is
## 0.24 above ground, 57% of the 0.42 body height, with zero legs
## to explain it; the pen sits at (26, 24), a village play
## viewpoint. (2) Chicken12_0/1/2 float 0.125 m — body sphere
## centre y 0.30, live half-height 0.175, bottom 0.125, 22% of
## the 0.57 bird height, right beside spawn. Every other animal
## is grounded (goats legs reach -0.025, ducks body bottom
## -0.05, buffalo 0, Cow64 hooves -0.05, rideables 0).
## FIX (this file, runtime dressing only, zero .tscn edits):
## (1) 4 legs per pig, children of the UNSCALED pen (never of the
## scaled body node — body scale (1.3, 0.7, 0.9) would squash
## them), sized + placed from LIVE body geometry (leg height =
## measured body bottom, leg centres at 0.68 / 0.60 of the live
## footprint halves, so legs meet the body exactly and stay
## inside it). (2) Chicken groups grounded by MEASURED shift
## (S128 hut-grounding precedent): each group's live min-y over
## its visible meshes is subtracted from the group position, so
## the body bottom lands exactly at 0 without assuming the
## sphere radius. Both fixes are UNGATED day + night, zero
## colliders, zero per-frame work after _apply. Runs at frame
## >= 820, after realism141's 810 pass. Targets are scene nodes
## present from frame 1, so no holder dependency exists here.
## NOT shipped, with reasons: goat horns/ears/tail (goats read
## complete by silhouette — body + head + 4 grounded legs — and
## monochrome white is realistic for Myanmar white goats; horn
## stubs ~0.1 m fail the 6 m substantiality gate); duck legs /
## wings (ducks sit at -0.05, grounded; 0.1 m legs would not
## read at 6 m); chicken comb (Chicken12 already has beak +
## head; comb ~0.05 m fails the 6 m gate, same reasoning as
## S143's flower); buffalo tail/ears (buffalo complete:
## body + head + horns + 4 legs, grounded); any new species;
## any behaviour/AI change (visual read only); S137 anchor /
## airplane decisions (owner decisions, untouched).

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism145") != null:
		return
	var n := Node3D.new()
	n.name = "Realism145"
	n.set_script(load("res://realism145.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 820:
		_done = true
		_apply(get_parent() as Node3D)

func _find_recursive(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f: Node = _find_recursive(c, nm)
		if f != null:
			return f
	return null

func _mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	return m

func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _pig_legs(world: Node3D) -> void:
	var pen: Node = _find_recursive(world, "PigPen13")
	if pen == null:
		return
	var pen3d: Node3D = pen as Node3D
	var pink: StandardMaterial3D = _mat(Color(0.95, 0.75, 0.75, 1.0))
	for bi in [0, 1]:
		var body: Node = pen3d.get_node_or_null("PigBody13_" + str(bi))
		if body == null:
			continue
		var body3d: Node3D = body as Node3D
		var probe: String = "Leg145_Pig" + str(bi) + "_FL"
		if pen3d.get_node_or_null(probe) != null:
			continue
		var mesh_node: MeshInstance3D = body3d as MeshInstance3D
		var bm: BoxMesh = mesh_node.mesh as BoxMesh
		if bm == null:
			continue
		var half_h: float = bm.size.y * body3d.scale.y * 0.5
		var bottom: float = body3d.position.y - half_h
		if bottom < 0.05:
			continue
		var hx: float = bm.size.x * body3d.scale.x * 0.5
		var hz: float = bm.size.z * body3d.scale.z * 0.5
		var lx: float = hx * 0.68
		var lz: float = hz * 0.60
		var bx: float = body3d.position.x
		var bz: float = body3d.position.z
		_box(pen3d, Vector3(0.10, bottom, 0.10), pink, Vector3(bx - lx, bottom * 0.5, bz - lz), "Leg145_Pig" + str(bi) + "_FL")
		_box(pen3d, Vector3(0.10, bottom, 0.10), pink, Vector3(bx + lx, bottom * 0.5, bz - lz), "Leg145_Pig" + str(bi) + "_FR")
		_box(pen3d, Vector3(0.10, bottom, 0.10), pink, Vector3(bx - lx, bottom * 0.5, bz + lz), "Leg145_Pig" + str(bi) + "_BL")
		_box(pen3d, Vector3(0.10, bottom, 0.10), pink, Vector3(bx + lx, bottom * 0.5, bz + lz), "Leg145_Pig" + str(bi) + "_BR")

func _ground_chickens(world: Node3D) -> void:
	for i in range(3):
		var grp: Node = _find_recursive(world, "Chicken12_" + str(i))
		if grp == null:
			continue
		var g3d: Node3D = grp as Node3D
		var min_y: float = 1e9
		var stack: Array = [g3d]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for c in n.get_children():
				stack.append(c)
			if n is MeshInstance3D:
				var mi: MeshInstance3D = n as MeshInstance3D
				if bool(mi.visible) and bool(mi.is_visible_in_tree()):
					var ga: AABB = mi.global_transform * mi.get_aabb()
					min_y = min(min_y, ga.position.y)
		if min_y > 0.02 and min_y < 0.5:
			g3d.position.y -= min_y

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_pig_legs(world)
	_ground_chickens(world)
