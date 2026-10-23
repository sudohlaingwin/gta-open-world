extends Node3D
## Slice 83 — BUS SIMULATION, part 10 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 10). The service
## breathes with the time of day, using ONLY procedural work:
## - PEAK HOURS: the long-route fleet (Slice 76) varies by time
##   band, reusing the Slice 63 fleet-band pattern (daylight
##   bands there were 10 / 7 / 3; here the road counts are
##   PEAK 6 / OFF-PEAK 4 / NIGHT 2, stated tuning values).
##   Off-peak and night cars are NOT deleted — they park at
##   the depot yard (four Slice 83 park spots, one per car
##   that can ever park, clear of both buses, the office,
##   the fuel pump and the fence lines)
##   and rejoin the road when the band changes back. The
##   Slice 76 loop skips parked cars, so a parked car never
##   drives, never counts as stuck, and never blocks.
## - PEAK PASSENGERS: every stop gains a THIRD waiting rider
##   (seat 2, middle of the Slice 77 bench), visible ONLY
##   during peak bands. Off-peak and night the stop shows
##   the usual 2 riders. Counts only: no money, no economy,
##   no fare, no score — the rider is a person waiting, and
##   boards exactly like seats 0 and 1 (same direction and
##   destination rules, Slice 75 + Slice 79 Express filter).
## - PEAK TIMETABLE: legs starting during a peak band run
##   45 s per stop instead of 60 s (night legs stay 90 s,
##   Slice 79). The rule lives in bus_sim77.gd, duration
##   fixed at leg start like Slice 79, so a band change
##   mid-leg does NOT stretch the leg already running.
## Band rule (ONE rule, shared with bus_sim77.gd — keep the
## two copies in sync; SIM83 proves they agree at every band):
## night wins first (daylight < 0.15, Slice 57 rule, even
## inside a peak window — evening peak overlaps night),
## then the 120 s day clock: morning peak [0, 15), evening
## peak [45, 60), everything else off-peak. Times are
## seconds on the DayNight clock, not wall-clock hours.
## No new HUD label: the band reads through the road
## (traffic count), the stops (2 vs 3 waiting riders) and
## the existing Slice 77 timetable label (dues 45 / 60 /
## 90 s). No new save key is created here: the controller
## gains one small key (peak83_hidden, see below) so a
## peak-hidden rider is not confused with a boarded rider
## after a save/load; everything else is session-only.
## The Slice 81 honest limit stands unchanged: the minibus
## is a free-drive fleet vehicle and is NOT rewired into
## the route system in this slice either. No opponent code,
## map, names or structure is used. Touch-first throughout
## (no keys anywhere; nothing here needs a button at all).

## Slice 84 — FULL-LENGTH ROUTE (part 11). The third
## seat now covers all 6 stops: groups 4 and 5 gain seat 2
## with the same shape (group 4 -> 5 east, the Express
## endpoint; group 5 -> 4 west, the Express endpoint).
## Band visibility loops all 6 groups.
##
## Slice 85 — RAIN RIDERS (part 12). The third seat stays
## hidden in rain even at peak: fewer people wait in the
## rain, counts only, no money, no economy. The rule is
## show = peak band AND dry; a rain-hidden rider keeps
## the peak83_hidden marker, so it resurrects at the next
## dry peak exactly like an off-peak-hidden rider (a
## boarded rider is never resurrected — the walk hides
## it without setting the marker, and the controller
## boards visible riders only, so a hidden rider cannot
## board while hidden). Rain braking (Slice 77, x 0.8)
## is verified unchanged by SIM85, not touched here.

const BAND_NIGHT: int = 0
const BAND_PEAK: int = 1
const BAND_OFFPEAK: int = 2
const DAY_LENGTH_S: float = 120.0
const PEAK_MORNING_END: float = 15.0
const PEAK_EVENING_START: float = 45.0
const PEAK_EVENING_END: float = 60.0
# Parked fleet by band (Slice 76 car indices; 0/2 are the
# cars that always stay on the road, one per direction).
# Peak: none parked. Off-peak: the two Slice 83 extra cars
# (4, 5) park. Night: only 0 (east) and 2 (west) run.
const PARKED_PEAK: Array = []
const PARKED_OFFPEAK: Array = [4, 5]
const PARKED_NIGHT: Array = [1, 3, 4, 5]
# Third-seat destinations, same shape as the Slice 75 DESTS
# table (controller holds the same values; BusSim83 sets
# them at creation so the rider is never meta-less, and the
# controller's own assignment skips riders that have meta).
# Seat 2: group 0 -> 3 east, group 1 -> 3 east, group 2 ->
# 0 west, group 3 -> 0 west. Slice 84: group 4 -> 5 east,
# group 5 -> 4 west. All six board Local; group 1 never
# boards Express (not a service stop), groups 0 / 2 / 3
# board Express when the direction matches, and the new
# endpoint seats (4 -> 5, 5 -> 4) board Express too.
const DESTS83: Array = [[3, 0], [3, 0], [0, 1], [0, 1], [5, 0], [4, 1]]
const SEAT2_BODY: Color = Color(0.85, 0.6, 0.2, 1.0)
const SEAT2_HEAD: Color = Color(0.8, 0.6, 0.45, 1.0)

var _seats_done: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim83") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim83"
	n.set_script(load("res://bus_sim83.gd"))
	world.call_deferred("add_child", n)


static func band_for(daylight: float, day_time: float) -> int:
	# Night precedence first (Slice 57 rule), then peak
	# windows on the 120 s day clock, else off-peak.
	if daylight < 0.15:
		return BAND_NIGHT
	var t := fmod(day_time, DAY_LENGTH_S)
	if t < 0.0:
		t += DAY_LENGTH_S
	if t < PEAK_MORNING_END:
		return BAND_PEAK
	if t >= PEAK_EVENING_START and t < PEAK_EVENING_END:
		return BAND_PEAK
	return BAND_OFFPEAK


static func parked_for_band(band: int) -> Array:
	if band == BAND_PEAK:
		return PARKED_PEAK
	if band == BAND_NIGHT:
		return PARKED_NIGHT
	return PARKED_OFFPEAK


func _daylight() -> float:
	var world := get_parent() as Node3D
	if world == null:
		return 1.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		return float(dn.call("daylight"))
	return 1.0


func _day_time() -> float:
	var world := get_parent() as Node3D
	if world == null:
		return 0.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.get("time") != null:
		return float(dn.get("time"))
	return 0.0


func _band() -> int:
	return band_for(_daylight(), _day_time())


func _is_rainy() -> bool:
	# Slice 85: rainy season is SaveManager season62 == 1
	# (same read as bus.gd rain braking). Missing
	# SaveManager means dry.
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or sm.get("season62") == null:
		return false
	return int(sm.get("season62")) == 1


func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _try_third_seat(world: Node3D) -> bool:
	# All 6 stop groups must exist first (Slice 74 dress +
	# Slice 84 dress run before this node, but deferred
	# order is retried anyway — same pattern as Slice 77).
	for si in range(6):
		if world.get_node_or_null("LongRoute74/BusStop74_%d" % si) == null:
			return false
	var body_m := _mat(SEAT2_BODY, 0.9)
	var head_m := _mat(SEAT2_HEAD, 0.9)
	for si in range(6):
		var grp := world.get_node_or_null("LongRoute74/BusStop74_%d" % si) as Node3D
		if grp == null:
			continue
		if grp.get_node_or_null("Waiting74_%d_2" % si) != null:
			continue
		# Same legless figure as Slice 74 (body cylinder +
		# head sphere, names Body74/Head74 so Slice 78
		# seats and walks it exactly like seats 0 and 1).
		# Standing pose at first; Slice 78 seats it on the
		# bench middle (x 0.0) on the next physics tick.
		var g := Node3D.new()
		g.name = "Waiting74_%d_2" % si
		g.position = Vector3(0.0, 0.0, 10.5)
		grp.add_child(g)
		var b := MeshInstance3D.new()
		b.name = "Body74"
		var bm := CylinderMesh.new()
		bm.top_radius = 0.28
		bm.bottom_radius = 0.28
		bm.height = 1.1
		b.mesh = bm
		b.position = Vector3(0.0, 0.55, 0.0)
		b.set_surface_override_material(0, body_m)
		g.add_child(b)
		var h := MeshInstance3D.new()
		h.name = "Head74"
		var hm := SphereMesh.new()
		hm.radius = 0.22
		hm.height = 0.44
		h.mesh = hm
		h.position = Vector3(0.0, 1.35, 0.0)
		h.set_surface_override_material(0, head_m)
		g.add_child(h)
		# Destinations now, so the rider is never meta-less
		# even if the controller's first frame already ran
		# (its assignment skips riders that have meta).
		g.set_meta("dest75", DESTS83[si][0])
		g.set_meta("dir75", DESTS83[si][1])
	return true


func _apply_band(world: Node3D, band: int) -> void:
	# --- Fleet: park / unpark only on state change. ---
	var s76 := world.get_node_or_null("BusSim76") as Node3D
	if s76 != null and s76.has_method("park_car83") and s76.has_method("unpark_car83"):
		var parked: Array = parked_for_band(band)
		var cars: Array = s76.get("traffic_cars")
		var bus := world.get_node_or_null("Bus") as Node3D
		var bus_pos := Vector3.ZERO
		if bus != null:
			bus_pos = bus.global_position
		for ci in range(cars.size()):
			var car := cars[ci] as Node3D
			if car == null:
				continue
			var want_parked := parked.has(ci)
			var is_parked := bool(car.get_meta("parked83", false))
			if want_parked and not is_parked:
				s76.call("park_car83", ci)
			elif is_parked and not want_parked:
				s76.call("unpark_car83", ci, bus_pos)
	# --- Third seat: visibility every frame, not just on
	# band change, so a round-trip respawn or a loaded save
	# during the same band still lands on the right count.
	# The peak83_hidden marker is what separates "hidden
	# by the band" (show again at peak) from "boarded and
	# hidden by the walk" (never resurrected by the band).
	# A rider mid-walk is owned by Slice 78 and skipped.
	for si in range(6):
		var grp := world.get_node_or_null("LongRoute74/BusStop74_%d" % si) as Node3D
		if grp == null:
			continue
		var w := grp.get_node_or_null("Waiting74_%d_2" % si) as Node3D
		if w == null:
			continue
		if bool(w.get_meta("walking78", false)):
			continue
		# Slice 85: show the third seat at a DRY peak only.
		# Rain hides it even at peak; the marker keeps
		# rain-hidden distinct from boarded (see header).
		var show_seat2 := band == BAND_PEAK and not _is_rainy()
		if show_seat2:
			if bool(w.get_meta("peak83_hidden", false)):
				w.visible = true
				w.set_meta("peak83_hidden", false)
		else:
			if w.visible:
				w.visible = false
				w.set_meta("peak83_hidden", true)


func _physics_process(_delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _seats_done:
		_seats_done = _try_third_seat(world)
	_apply_band(world, _band())
