extends Node3D
## Slice 133 — ROAD + ROADSIDE READ AUDIT ROUND,
## AUDIT-FIRST, under the owner's goal "OpenTaxi Thadingyut
## Night level game graphic". BOUNDARY (binding): take ONLY
## the visual STANDARD from the reference video. NEVER copy
## OpenTaxi assets, branding, names, maps, layouts, or URLs;
## no club, no Yangon copy, no flying cars. World stays
## village/Mindon/fields. All content below is ORIGINAL.
## ROAD AUDIT (audit133 + probe133b/c/d, live headless,
## S132 dressing complete, day time 300 then night 900;
## 6 m camera read proxied honestly by counts, positions,
## materials and omni coverage — the dummy renderer returns
## no pixels, S130, so no look claim is made headless):
## - MAIN ROAD (LongRoad74): COMPLETE. Slab 2000x12 +
##   2 edge lines + 2 curbs + 166 centre dashes, x 455..2435.
##   Nothing shipped (would be padding).
## - LOOP (LoopSlab75): COMPLETE. 4 slabs + 46 dashes
##   (loop pattern: dashes only, no edges/curbs).
## - SPUR (SpurRoad75): REAL GAP, FIXED BELOW. Bare
##   asphalt 12x54 at (2100, 33), ZERO dashes, ZERO edges
##   — the only drivable road segment with no markings at
##   all. Corridor probe proves the dash positions clear:
##   only SpurRoad75 itself + 4 Blade94 edge blades at
##   x 2094/2105.9, z 20/45 (dash centres x 2100, z 10..14 /
##   22..26 / 34..38 / 46..50 — clear of both).
## - LOOP REJOIN (x 1900): REAL GAP, FIXED BELOW.
##   bus_sim76 JUNCTION_X = [1500, 2100] only, so the
##   loop's rejoin onto the main road never got the
##   StopLine76 treatment the other two junctions have
##   (StopLine76 1.0x0.03x11.0 white at y 0.13, exactly 2
##   live: 1500 + 2100). Junction scan at 1900 found ZERO
##   non-dash/edge low meshes within 12 m. The new stop
##   line sits on the main slab like the other two (main
##   dashes at 1895 + 1907 bracket it clear: line spans
##   x 1899.5..1900.5, dashes end 1897 / start 1905).
## - EAST ROAD (MainRoad62): NOT A GAP — audit
##   correction. audit133's "RoadDash62 count=1" was a
##   NAME-SEARCH artifact, not a missing-dash gap: Godot
##   4 auto-renames duplicate-name siblings to
##   @MeshInstance3D@N, so the 23 later dashes hide from
##   prefix counts. Verbatim children listing proves 24
##   dashes total (RoadDash62 + @14..@36), dx 255..439
##   step 8, matching the chill_world62 loop exactly.
##   Slab + 2 edges + 24 dashes: complete. Future audits
##   must count @-renamed nodes, not prefixes, wherever
##   a script reuses one name in a loop.
## - MINDON STREETS: NOT A GAP. Dirt (0.62, 0.5, 0.32)
##   on pale ground (0.94, 0.92, 0.63) = strong contrast,
##   raised profile (top 0.16), continuous E-W street
##   x 55..238 (LinkRoad + Street1-6, bridge + ramps
##   cover 79..97) + N-S branches + diagonal + stub.
##   Painted lines on dirt town streets would look wrong;
##   nothing shipped. Bridge deck distinct (0.72, 0.62,
##   0.42). NOT a gap.
## - VILLAGE: NO CONTINUOUS ROAD BY DESIGN. Only
##   scattered stone stepping slabs (1.4x1.4 / 2x1.5 /
##   1.6x1.2, stone 0.85, 0.84, 0.8). The village is
##   pedestrian; inventing a path network would be
##   arbitrary placement against the owner's map-exactness
##   order. NOT shipped, stated as design, not a gap.
## - ROADSIDE: ADEQUATE. Km93 5 posts + 5 tops
##   (x 500/1000/1490/2000/2400, z -8), S-bend guard
##   7 posts + 6 rails, stop signs 6/6, junction signs
##   at 1500 + 2100, village/gate/tea/school signs live.
##   Spur roadside needs nothing: junction sign at 2100
##   exists, hamlet end has houses/trees/festival. NOT
##   shipped (would be padding on a 54 m road).
## - NIGHT ROAD READ: ADEQUATE, NO NEW OMNIS. Visible
##   omnis within 25 m after force_pass at night: main
##   2 @ 7.5 m, loop 1 @ 12.0 m, spur mid 2 @ 15.6 m,
##   spur far end 1 @ 19.2 m (hamlet end has S127 yard
##   lamps + festival — not dark), Mindon 7/4 @ 0 m,
##   village path 9 @ 7.5 m, junctions 2 @ 0/14.4 m.
##   Roads do not vanish at night; markings stay dim
##   white like every other marking (non-emissive, same
##   as main/loop — no glowing-road invention).
## SHIPPED (5 meshes, 0 new omnis, 0 colliders, UNGATED
## paint visible day AND night like S128 ground / S130
## banks; frame >= 780 holders-ready gate: SpurRoad75
## must exist; zero per-frame work after _apply):
## - SpurDash133_0..3: centre dashes on SpurRoad75,
##   loop pattern (4 m dash every 12 m, y 0.13, white
##   0.9/0.9/0.85): (2100, 0.13, 12/24/36/48), size
##   (0.3, 0.03, 4.0) — long axis along the road (spur
##   runs N-S, unlike the E-W loop segments, so the
##   4.0 m side is Z, not X). No edge lines: loop
##   precedent — side roads get dashes only; main-road
##   edges + curbs stay main-road furniture.
## - StopLine133: (1900, 0.13, 0), size (1.0, 0.03,
##   11.0), same white — completes the junction set.
## NOT touched: bus/minibus/big bus (Slice 81), S119
## menu, S121 models, S124/S127 night, S125 beacons/
## ox/smooth-look, S126 plane re-face, S128 hut grounding
## + ground, S129 clouds + bunting, S130 water + banks,
## S131 pagoda glow + festival, S132 villager motion;
## no .tscn edits.

const FRAME_GATE: int = 780

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism133") != null:
		return
	var n := Node3D.new()
	n.name = "Realism133"
	n.set_script(load("res://realism133.gd"))
	world.call_deferred("add_child", n)

func _mat(color: Color, rough: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

func _box(nm: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.set_surface_override_material(0, mat)
	add_child(mi)

func _apply() -> void:
	var white: StandardMaterial3D = _mat(Color(0.9, 0.9, 0.85, 1.0), 0.8)
	for i in range(4):
		var z: float = 12.0 + float(i) * 12.0
		_box("SpurDash133_%d" % i, Vector3(0.3, 0.03, 4.0), Vector3(2100.0, 0.13, z), white)
	_box("StopLine133", Vector3(1.0, 0.03, 11.0), Vector3(1900.0, 0.13, 0.0), white)

func _process(_delta: float) -> void:
	_frames += 1
	if _done:
		return
	if _frames < FRAME_GATE:
		return
	var world: Node = get_parent()
	if world == null:
		return
	if world.get_node_or_null("BusRoute75/Curves75/SpurRoad75") == null:
		return
	_apply()
	_done = true
