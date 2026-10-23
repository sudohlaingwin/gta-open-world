extends Node3D
## Slice 91 — BUS SIMULATION, part 18 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 18).
## ONBOARD SEATED PASSENGERS: a boarded rider no longer
## vanishes at the bus flank. After the Slice 78 walk to the
## flank, the rider steps aboard and SITS in one of the
## Slice 75 interior seats (8 seats, 4 rows x 2, seat bases
## at local (±0.75, 1.0, row_z)), visible through the Slice 75
## semi-transparent side glass while riding. The rider
## follows the bus every frame (seat world position via
## bus.to_global), so the bus visibly carries its passengers.
## On alighting, the rider leaves the seat: the waiting-rider
## node hides (the Slice 75 Alighted75 figure at the stop is
## the person who walks away under Slice 78 — one person,
## not two), and the freed seat is reusable by a later
## boarder (first-free seat search, so seats recycle in
## order). CAP, stated plainly: 8 seats only. A 9th
## simultaneous rider stays hidden count-only exactly as
## before — no 9th seat is invented and no count is dropped.
## Display only: Slice 79 stays the single source of truth
## for served/carried/on-time counts; this node never
## counts, never saves (no new save key, session only),
## no money, no economy. The minibus is NOT rewired
## (Slice 81 honest limit stands): seating applies to the
## big route bus only; MiniSign81 and the free-drive
## minibus are untouched.
## Ownership rules (why three small edits elsewhere):
## - Slice 78 walk completion hands arrived riders to this
##   node (meta arrived91) instead of hiding them, and its
##   bench-reseat branch skips seated/arrived riders —
##   otherwise it would teleport a seated rider back to
##   the bench every physics frame.
## - The controller's _waiting_bools excludes seated /
##   arrived riders, same duplicate-avoidance rule as its
##   mid-walk exclusion: a mid-ride save must not record
##   an onboard rider as waiting, or a load would duplicate
##   them (onboard dest from the save + a bench rider).
##   Seating display itself is session-only: metas do not
##   survive a load, so a loaded save shows no seated
##   riders — counts from the save stay correct.
## - Slice 83's seat-2 band rule skips seated / arrived
##   riders, same as it skips mid-walk riders: otherwise an
##   off-peak frame would hide a seated third rider
##   (and mark them peak83_hidden) while still onboard.
## - While seated, the Slice 86 destination board above the
##   rider's head is hidden: its job is to show a WAITING
##   rider's destination, and at bus-local y 2.615 it would
##   poke the bus roof (body top 2.8, board top 2.825).
##   The board is restored whenever the seat is freed, so
##   a round-trip respawn shows boards again.
## Rotation is deliberately NOT claimed: the rider figure
## is a symmetric cylinder + sphere, so only its position
## follows the bus; its world rotation is left as it was
## at the stop.

const STOPS_X: Array = [700.0, 1200.0, 1700.0, 2200.0, 500.0, 2400.0]
const STOP_ZONE_R: float = 9.0
# Slice 75 seat bases: rows front-to-back, sides left/right.
# Seat index = row * 2 + side, matching Seat75_0..7 order.
const SEAT_ROWS: Array = [-2.5, -1.0, 0.5, 2.0]
const SEAT_XS: Array = [-0.75, 0.75]
# Rider-node origin for a seated rider: the bench seated
# pose puts the body centre 0.37 above the bench seat top
# (body centre 0.98, seat top 0.61). The bus seat top is
# 1.075 (base centre 1.0 + half height 0.075), so the body
# centre must be 1.075 + 0.37 = 1.445, and the origin is
# 1.445 - 0.98 = 0.465.
const SEAT_ORIGIN_Y: float = 0.465
const SEAT_BODY_Y: float = 0.98
const SEAT_HEAD_Y: float = 1.62

var _prev_dir: int = -1
var _prev_next: int = -1
var _prev_alighted: int = 0


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim91") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim91"
	n.set_script(load("res://bus_sim91.gd"))
	world.call_deferred("add_child", n)


func _stop_group(world: Node3D, idx: int) -> Node3D:
	return world.get_node_or_null("LongRoute74/BusStop74_%d" % idx) as Node3D


func _seat_origin(idx: int) -> Vector3:
	var row := clampi(idx / 2, 0, 3)
	var side := idx % 2
	return Vector3(SEAT_XS[side], SEAT_ORIGIN_Y, SEAT_ROWS[row])


func _set_seated_pose(w: Node3D) -> void:
	var body := w.get_node_or_null("Body74") as MeshInstance3D
	if body != null:
		body.position = Vector3(0.0, SEAT_BODY_Y, 0.0)
	var head := w.get_node_or_null("Head74") as MeshInstance3D
	if head != null:
		head.position = Vector3(0.0, SEAT_HEAD_Y, 0.0)


func _set_board_visible(w: Node3D, vis: bool) -> void:
	var board := w.get_node_or_null("DestBoard86") as Node3D
	if board != null:
		board.visible = vis


func _clear_rider(w: Node3D, hide: bool) -> void:
	w.set_meta("seated91", false)
	w.set_meta("arrived91", false)
	w.set_meta("seat91", -1)
	_set_board_visible(w, true)
	if hide:
		w.visible = false


func _clear_all_seated(world: Node3D, hide: bool) -> void:
	for si in range(6):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(3):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
			if w != null and (bool(w.get_meta("seated91", false)) or bool(w.get_meta("arrived91", false))):
				_clear_rider(w, hide)


func _first_free_seat(world: Node3D) -> int:
	var used: Array = []
	for si in range(6):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(3):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
			if w != null and bool(w.get_meta("seated91", false)):
				used.append(int(w.get_meta("seat91", -1)))
	for idx in range(8):
		if not used.has(idx):
			return idx
	return -1


func _nearest_stop(world: Node3D, bus: Node3D) -> int:
	var best := -1
	var best_d := STOP_ZONE_R
	var bp := bus.global_position
	for si in range(6):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		var sp := grp.global_position
		var d := Vector2(bp.x - sp.x, bp.z - sp.z).length()
		if d < best_d:
			best_d = d
			best = si
	return best


func _process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var bus := world.get_node_or_null("Bus") as Node3D
	var ctrl := world.get_node_or_null("BusSim74") as Node3D
	# --- Claim arrived riders + keep seated riders in the bus. ---
	for si in range(6):
		var grp := _stop_group(world, si)
		if grp == null:
			continue
		for wi in range(3):
			var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
			if w == null:
				continue
			if bool(w.get_meta("seated91", false)):
				if bus != null:
					w.global_position = bus.to_global(_seat_origin(int(w.get_meta("seat91", 0))))
					w.visible = true
			elif bool(w.get_meta("arrived91", false)):
				var seat := _first_free_seat(world)
				if seat >= 0:
					w.set_meta("seated91", true)
					w.set_meta("seat91", seat)
					w.set_meta("arrived91", false)
					_set_seated_pose(w)
					_set_board_visible(w, false)
					if bus != null:
						w.global_position = bus.to_global(_seat_origin(seat))
					w.visible = true
				else:
					# 8 seats full: hidden count-only, exactly
					# as before this slice. The controller
					# already recorded the boarding count.
					w.set_meta("arrived91", false)
					w.visible = false
	if ctrl == null:
		return
	var dir := int(ctrl.get("direction"))
	var nxt := int(ctrl.get("next_stop"))
	var alighted := int(ctrl.get("alighted_total"))
	# --- Round-trip respawn flip: every onboard rider has
	# alighted by the west terminus, and the controller
	# respawned all waiting riders. Clear seating flags
	# (do NOT hide: respawn made them visible at stops).
	if _prev_dir == 1 and _prev_next == 4 and dir == 0 and nxt == 4:
		_clear_all_seated(world, false)
		_prev_dir = dir
		_prev_next = nxt
		_prev_alighted = alighted
		return
	# --- Alighting: free the seats of riders whose
	# destination is the stop just served. The controller
	# runs its _process before this node (tree order), so
	# the bus is still at the stop when this frame runs.
	if alighted > _prev_alighted:
		var k := alighted - _prev_alighted
		var served := -1
		if bus != null:
			served = _nearest_stop(world, bus)
		if served < 0:
			var leg: Array = ctrl.get("leg_served")
			if leg.size() > 0:
				served = int(leg[leg.size() - 1])
		var freed := 0
		if served >= 0:
			for si in range(6):
				if freed >= k:
					break
				var grp := _stop_group(world, si)
				if grp == null:
					continue
				for wi in range(3):
					if freed >= k:
						break
					var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
					if w != null and bool(w.get_meta("seated91", false)) and int(w.get_meta("dest75", -1)) == served:
						_clear_rider(w, true)
						freed += 1
		if freed < k:
			# Fallback (bus already pulled away before this
			# frame, so the stop could not be read): free
			# the earliest-seated riders first, so no seat
			# leaks occupied forever. Counts never change
			# here — only the display seat is freed.
			for si in range(6):
				if freed >= k:
					break
				var grp := _stop_group(world, si)
				if grp == null:
					continue
				for wi in range(3):
					if freed >= k:
						break
					var w := grp.get_node_or_null("Waiting74_%d_%d" % [si, wi]) as Node3D
					if w != null and bool(w.get_meta("seated91", false)):
						_clear_rider(w, true)
						freed += 1
		_prev_alighted = alighted
	# --- Safety: nobody onboard means nobody seated. This
	# covers a flip the frame watcher missed; it can never
	# fire while anyone is riding (onboard is only empty
	# with zero riders aboard).
	var onboard: Array = ctrl.get("onboard_dests")
	if onboard.size() == 0:
		_clear_all_seated(world, true)
	_prev_dir = dir
	_prev_next = nxt
