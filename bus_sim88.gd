extends Node3D
## Slice 88 — BUS SIMULATION, part 15 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 15).
## DEPOT SERVICE BOARD: the depot office now shows the
## service's own record, so the yard reads like a working
## depot, not just parked buses. A board on the Slice 82
## office south face, beside the door, displays the last
## completed round trip's summary from the Slice 79 data
## (in-order stops served, passengers carried, on-time
## stops — counts only, NO money, NO score, NO rating).
## The board reads Slice 79's published last_shown_* (seq
## bumps once per depot collection), so it can never
## disagree with the HUD summary: it shows exactly what
## Slice 79 collected, and a second round trip REPLACES
## the older counts (the board re-texts on the next depot
## collection, never merges — same rule as Slice 79).
## Before any round trip completes, the board shows a
## neutral line in Myanmar words only — no invented
## numbers, no zeroes-as-results. Session-only like the
## Slice 79 summary: no new save key, stated plainly.
## Placement (local to DepotOffice82, whose walls are
## 8 x 3.2 x 5 centred at y 1.6, south face z 2.5, door
## x -0.5..0.5, south windows x 1.9..3.1 and -3.1..-1.9):
## the 1.3 m board sits at x 1.2, spanning 0.55..1.85 —
## beside the door, clear of both windows, 0.05 m clear
## of the east window. The label faces +z (toward the
## depot yard, where the buses park) and is double-sided,
## so it reads from the yard and from behind. Zero
## colliders: plain MeshInstance3D + Label3D only, so the
## board can never block the bus, the road, or a footpath.
## Myanmar digits only (the Noto font has no '+' or ':'
## glyphs, Slice 77 lesson). No opponent code, map,
## names or structure is used. Touch-first throughout
## (nothing here needs a button at all).
## The Slice 81 honest limit stands unchanged: the
## minibus is a free-drive fleet vehicle and is NOT
## rewired into the route system in this slice either.
##
## Slice 89 — SHIFT TOTALS (part 16): the board gains a
## second section directly below the first, same x span,
## same backing and label style. The last-trip section
## above is untouched (replaced per trip, never added).
## The totals section shows the running session sum from
## Slice 79's total_* (bumped at the same depot
## collection as last_shown_*): total stops served,
## total passengers carried, total on-time stops across
## ALL completed round trips this session. Before any
## round trip it shows the same neutral treatment —
## Myanmar words only, no invented numbers, no
## zeroes-as-results. Placement: totals board centre
## y 0.75, spanning 0.25..1.25 — clear of the door
## (x ends 0.5), clear of the south windows (y starts
## 1.3, board top 1.25 leaves 0.05), and above the
## steps (top 0.15, board bottom 0.25 leaves 0.10).
## Session-only, no new save key. The two sections can
## never be confused: one replaces, the other adds, and
## the sim proves both from the same two trips.

const BOARD_POS: Vector3 = Vector3(1.2, 1.8, 2.56)
const BOARD_SIZE: Vector3 = Vector3(1.3, 1.0, 0.06)
const LABEL_POS: Vector3 = Vector3(1.2, 1.8, 2.60)
const PRE_TEXT: String = "ဝန်ဆောင်မှု\nမပြီးသေးပါ"
const TOTALS_BOARD_POS: Vector3 = Vector3(1.2, 0.75, 2.56)
const TOTALS_LABEL_POS: Vector3 = Vector3(1.2, 0.75, 2.60)
const TOTALS_PRE_TEXT: String = "စုစုပေါင်း\nမပြီးသေးပါ"
const MY_DIGITS: Array = ["၀", "၁", "၂", "၃", "၄", "၅", "၆", "၇", "၈", "၉"]

var _built: bool = false
var _label: Label3D = null
var _totals_label: Label3D = null
var _seen_seq: int = -1


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim88") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim88"
	n.set_script(load("res://bus_sim88.gd"))
	world.call_deferred("add_child", n)


static func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


static func _my_num(n: int) -> String:
	# Same Myanmar-digit rendering as Slice 79.
	var s := str(n)
	var out := ""
	for ch in s:
		var d := int(ch)
		out += MY_DIGITS[d]
	return out


func _try_build(world: Node3D) -> bool:
	# Slice 82 dress builds the office synchronously, but
	# deferred order is retried anyway — same pattern as
	# Slice 77 / 83 / 86.
	var office := world.get_node_or_null("BusSim82/DepotOffice82") as Node3D
	if office == null:
		return false
	var existing := office.get_node_or_null("ServiceLabel88") as Label3D
	if existing != null:
		_label = existing
	else:
		var board_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
		var box := MeshInstance3D.new()
		box.name = "ServiceBoard88"
		var bm := BoxMesh.new()
		bm.size = BOARD_SIZE
		box.mesh = bm
		box.position = BOARD_POS
		box.set_surface_override_material(0, board_m)
		office.add_child(box)
		var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
		if font == null:
			push_error("BusSim88: Myanmar font failed to load, service board label skipped")
			return true
		var lab := Label3D.new()
		lab.name = "ServiceLabel88"
		lab.text = PRE_TEXT
		lab.font = font
		lab.font_size = 20
		lab.pixel_size = 0.010
		lab.position = LABEL_POS
		lab.double_sided = true
		office.add_child(lab)
		_label = lab
	# Slice 89: totals section below the last-trip board.
	# Built independently of the first board so a world
	# that already carries ServiceLabel88 still gets it.
	var texisting := office.get_node_or_null("TotalsLabel89") as Label3D
	if texisting != null:
		_totals_label = texisting
	else:
		if office.get_node_or_null("TotalsBoard89") == null:
			var tboard_m := _mat(Color(0.05, 0.3, 0.15, 1.0), 0.8)
			var tbox := MeshInstance3D.new()
			tbox.name = "TotalsBoard89"
			var tbm := BoxMesh.new()
			tbm.size = BOARD_SIZE
			tbox.mesh = tbm
			tbox.position = TOTALS_BOARD_POS
			tbox.set_surface_override_material(0, tboard_m)
			office.add_child(tbox)
		var font2 := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
		if font2 == null:
			push_error("BusSim88: Myanmar font failed to load, totals board label skipped")
			return true
		var tlab := Label3D.new()
		tlab.name = "TotalsLabel89"
		tlab.text = TOTALS_PRE_TEXT
		tlab.font = font2
		tlab.font_size = 20
		tlab.pixel_size = 0.010
		tlab.position = TOTALS_LABEL_POS
		tlab.double_sided = true
		office.add_child(tlab)
		_totals_label = tlab
	return true


func _physics_process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _built:
		_built = _try_build(world)
		if not _built:
			return
	var sim79 := world.get_node_or_null("BusSim79") as Node3D
	if sim79 == null or _label == null:
		return
	var seq := int(sim79.get("last_shown_seq"))
	if seq == _seen_seq:
		return
	_seen_seq = seq
	if seq <= 0:
		return
	_label.text = "ဝန်ဆောင်မှု\nမှတ်တိုင် %s\nခရီးသည် %s\nအချိန်မှန် %s" % [_my_num(int(sim79.get("last_shown_serves"))), _my_num(int(sim79.get("last_shown_carried"))), _my_num(int(sim79.get("last_shown_ontime")))]
	# Slice 89: totals section follows the same seq bump
	# — same collection, same moment, summed counts.
	if _totals_label != null:
		_totals_label.text = "စုစုပေါင်း\nမှတ်တိုင် %s\nခရီးသည် %s\nအချိန်မှန် %s" % [_my_num(int(sim79.get("total_serves"))), _my_num(int(sim79.get("total_carried"))), _my_num(int(sim79.get("total_ontime")))]
