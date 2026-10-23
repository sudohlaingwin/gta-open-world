extends Node3D
## Slice 86 — BUS SIMULATION, part 13 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 13).
## RIDER DESTINATION BOARDS: every waiting rider now shows
## where they are going, so the player can read the stop
## before opening the door. Each waiting rider (all 3 seats
## at all 6 stops) carries a small board above their head
## with the Myanmar digit of their destination stop, in the
## real Noto font (the Slice 69 font — never the default
## font, which has no Myanmar glyphs). The digit is the
## STABLE west-to-east travel position from Slice 84
## (controller pos_digit79), never the group index and
## never the direction of travel — so a rider bound for
## group 2 always shows ၄, eastbound or westbound, Local
## or Express, exactly like the physical stop signs.
## The board is a CHILD of the rider node, so it follows
## the rider for free through every existing rule, with no
## extra visibility code and no new save key:
## - Slice 78 seats the rider on the bench (board rides
##   above the seated head, head top 1.84, board bottom
##   1.94 — a 0.10 m gap, not touching);
## - Slice 78 walks the rider to the bus flank standing
##   (board rides 0.37 m above the standing head, then
##   hides with the rider when they step aboard — the
##   walk-aboard path is untouched, stated plainly);
## - Slice 83/85 hide seat 2 off-peak or in rain (board
##   hides with the rider, resurrects with the rider);
## - a round-trip respawn shows the rider again, board
##   and all; a boarded rider never resurrects, board
##   included (the rider node itself stays hidden).
## Alighted figures (Alighted75_*) carry NO board: they
## already got off, so a destination digit above them
## would be wrong. No money, no economy, no new HUD label,
## no collider on any board (Label3D + plain MeshInstance3D
## boxes collide with nothing, so a board can never block
## the bus, the road, or a footpath).
## The Slice 81 honest limit stands unchanged: the minibus
## is a free-drive fleet vehicle and is NOT rewired into
## the route system in this slice either. No opponent code,
## map, names or structure is used. Touch-first throughout
## (nothing here needs a button at all).

# Player-facing digit per DESTINATION group index
# (west-to-east travel position 1..6). Fallback only:
# the controller's pos_digit79 is preferred whenever the
# controller node exists, so the two can never disagree.
const POS_DIGIT: Dictionary = {4: "၁", 0: "၂", 1: "၃", 2: "၄", 3: "၅", 5: "၆"}
const BOARD_Y: float = 2.15
const BOARD_SIZE: Vector3 = Vector3(0.55, 0.42, 0.06)

var _done: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim86") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim86"
	n.set_script(load("res://bus_sim86.gd"))
	world.call_deferred("add_child", n)


static func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _digit_for(world: Node3D, dest: int) -> String:
	# Controller first (single source of truth for the
	# stable numbering); local map only if the controller
	# node is not in the tree yet.
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	if ctrl != null and ctrl.has_method("pos_digit79"):
		var d := str(ctrl.call("pos_digit79", dest, 0))
		if d != "":
			return d
	return str(POS_DIGIT.get(dest, ""))


func _attach_board(w: Node3D, digit: String, font: Font, board_m: Material) -> void:
	# Board group rides on the rider: backing box + digit
	# facing the road (-z, rotation PI like the Slice 74
	# stop signs, double-sided so it reads from behind
	# too). No collider, no script on the board itself.
	var bg := Node3D.new()
	bg.name = "DestBoard86"
	bg.position = Vector3(0.0, BOARD_Y, 0.0)
	w.add_child(bg)
	var box := MeshInstance3D.new()
	box.name = "Board86"
	var bm := BoxMesh.new()
	bm.size = BOARD_SIZE
	box.mesh = bm
	box.position = Vector3(0.0, 0.0, 0.0)
	box.set_surface_override_material(0, board_m)
	bg.add_child(box)
	if font != null:
		var lab := Label3D.new()
		lab.name = "BoardLabel86"
		lab.text = digit
		lab.font = font
		lab.font_size = 24
		lab.pixel_size = 0.012
		lab.position = Vector3(0.0, 0.0, -0.04)
		lab.rotation.y = PI
		lab.double_sided = true
		bg.add_child(lab)
	else:
		push_error("BusSim86: Myanmar font failed to load, rider board label skipped")


func _try_boards(world: Node3D) -> bool:
	# All 6 stop groups must exist first (Slice 74 dress +
	# Slice 84 dress run before this node, but deferred
	# order is retried anyway — same pattern as Slice 77
	# / 83). A rider without destination meta yet is
	# skipped this frame, not boarded with a wrong digit:
	# the controller assigns meta on its first frame, and
	# Slice 83 / 84 riders are born with meta, so a skip
	# only ever means "not ready yet".
	var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	var complete := true
	for si in range(6):
		var grp := world.get_node_or_null("LongRoute74/BusStop74_%d" % si) as Node3D
		if grp == null:
			return false
		for wi in range(3):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
			if w == null:
				return false
			var existing := w.get_node_or_null("DestBoard86") as Node3D
			if existing != null:
				# Re-text if the destination ever changed
				# (it never does after assignment, but a
				# stale digit would be worse than a rewrite).
				if w.has_meta("dest75"):
					var want := _digit_for(world, int(w.get_meta("dest75")))
					var lab := existing.get_node_or_null("BoardLabel86") as Label3D
					if lab != null and want != "" and lab.text != want:
						lab.text = want
				continue
			if not w.has_meta("dest75"):
				complete = false
				continue
			var digit := _digit_for(world, int(w.get_meta("dest75")))
			if digit == "":
				complete = false
				continue
			_attach_board(w, digit, font, board_m)
	return complete


func _physics_process(_delta: float) -> void:
	if _done:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	_done = _try_boards(world)
