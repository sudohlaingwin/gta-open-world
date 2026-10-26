extends Node3D
## Slice 134 — MARKET + SHOPFRONT DETAIL AUDIT ROUND,
## AUDIT-FIRST, under the owner's goal "OpenTaxi Thadingyut
## Night level game graphic". BOUNDARY (binding): take ONLY
## the visual STANDARD from the reference video. NEVER copy
## OpenTaxi assets, branding, names, maps, layouts, or URLs;
## no club, no Yangon copy, no flying cars. World stays
## village/Mindon/fields. All content below is ORIGINAL.
## MARKET AUDIT (audit134 + audit134b, live headless,
## S133 dressing complete, day time 300 then night 900;
## 6 m camera read proxied honestly by counts, positions,
## materials and omni coverage — the dummy renderer returns
## no pixels, S130, so no look claim is made headless):
## - S129's "Awnings 3 against 44 stalls" is CORRECTED.
##   Both numbers were prefix-count artifacts: awning nodes
##   are named MarketStallAAwning / StallDAwning / etc.
##   (nothing starts with "Awning" except Awning20A/B/C),
##   and "Stall" prefix counts stall PARTS (posts, piles,
##   tables), not stalls. Distinct selling units are ~15,
##   and MOST HAVE SHADE already. Per-unit shade audit
##   (geometry: shade slab above table height, not name):
##   MarketStallA/B/15D, StallC13, FestivalStall16,
##   GoldStall19, NightMarket20 (3 awnings), -6 row (2
##   awnings), TeaShop13 (canopy roof), MindonShops
##   (roof), Workshop19 (roof) — all SHADED. Two units
##   are genuinely SHADELESS, fixed below.
## - MarketStallE17 (26,16): REAL GAP. Table + 2 food
##   cubes + 2 front posts (2.2 tall, z 15.5) and NOTHING
##   on top — posts stand bare. Fixed: 2 rear posts +
##   2 beams + red awning + sign frame (S102 MarketStallA
##   pattern: sign posts + board, NO text — S129's text
##   banner deferral stands).
## - StallF18 (20,22): REAL GAP. Big 4x4 table + 2
##   baskets, ZERO posts, ZERO shade. Fixed: 4 corner
##   posts + 2 beams + blue awning + sign frame.
## - GoldStall18/18B/18C: REAL DEFECT, TRIPLE DUPLICATE.
##   All three holders sit at (34,0,26) with IDENTICAL
##   children at IDENTICAL global positions (GoldTable18
##   (34,0.8,26) + 3 boxes) — three copies of one stall
##   rendered on top of each other, z-fighting on table
##   + boxes. No script references 18B/18C by name.
##   Fixed below: hide ALL meshes of 18B and 18C,
##   guarded by exact table-position coincidence.
##   The shared S102 gold-row canopy stays over the one
##   remaining stall; S102's gold-row sign frame stays.
## - MarketStallB vs MarketStall15D ("StallD"): REAL
##   DEFECT, DUPLICATE SURFACES. Both holders sit at
##   (22,0,12); their tables coincide EXACTLY (22,0.9,12,
##   3.6x0.15x2) and their awnings coincide EXACTLY
##   (22,2.55,12, 4.2x0.12x3) — z-fighting on table +
##   awning. Posts/beams/piles/garland sit at DIFFERENT
##   positions (B is rotated relative to 15D), so only
##   the two coinciding surfaces are hidden below.
##   15D keeps its S127 lantern posts (Accent127_Stall
##   lanterns sit on StallDPost_ children, untouched).
## - FestivalStall16: NOT a gap — audit correction.
##   First audit's goods=0 was a CLASSIFIER miss
##   ("Snack" not in the goods list): counter + awning +
##   3 snacks live. Nothing shipped.
## - MindonShops: NOT a gap. 105 meshes: glass
##   storefront + ShopHeader100 + door + steps +
##   balcony + pilasters + band + eaves + roof.
##   First audit's signs=0 was a CLASSIFIER miss
##   ("Header" not in the sign list). S127 accents
##   correctly hidden at day (7/7). Nothing shipped.
## - TeaShop13: NOT a gap. Canopy roof + sign + label
##   + 5 tables + stools + cups + lantern. Nothing
##   shipped (cups are goods; the goods classifier
##   missed "Cup" too).
## - NIGHT MARKET READ: NO GAP. After perf120
##   force_pass per area at night (S131 lesson: far-cull
##   artifact otherwise): village-market emis 19 /
##   omni 9, night-market20 29/10, gold-row 48/9,
##   mindon-shops 30/2, tea-shop 16/10,
##   festival-stall16 7/1. S127 stall lanterns 4/4
##   visible at night; LampMarket102 head + omni
##   visible. No dark stretches; no new omnis.
## SHIPPED (18 meshes + 10 hides, 0 new omnis, 0 new
## colliders, UNGATED visible day AND night like S128
## ground / S130 banks; frame >= 790 holders-ready
## gate; zero per-frame work after _apply):
## - E17: 2 rear posts + 2 beams + red awning + sign
##   frame (2 posts + board) = 8.
## - F18: 4 corner posts + 2 beams + blue awning +
##   sign frame (2 posts + board) = 10.
## - Hides: GoldStall18B 4 meshes + GoldStall18C 4
##   meshes + MarketStallB table + awning = 10.
## NOT touched: bus/minibus/big bus (Slice 81), S119
## menu, S121 models, S124/S127 night, S125 beacons/
## ox/smooth-look, S126 plane re-face, S128 hut grounding
## + ground, S129 clouds + bunting, S130 water + banks,
## S131 pagoda glow + festival, S132 villager motion,
## S133 road paint; no .tscn edits.

const FRAME_GATE: int = 790

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism134") != null:
		return
	var n := Node3D.new()
	n.name = "Realism134"
	n.set_script(load("res://realism134.gd"))
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

func _hide_all_meshes(holder: Node) -> void:
	if holder == null:
		return
	var stack: Array = [holder]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D:
			(x as MeshInstance3D).visible = false
		for c in x.get_children():
			stack.append(c)

func _apply(world: Node3D) -> void:
	var wood: StandardMaterial3D = _mat(Color(0.45, 0.30, 0.18, 1.0), 0.8)
	var red: StandardMaterial3D = _mat(Color(0.8, 0.15, 0.15, 1.0), 0.8)
	var blue: StandardMaterial3D = _mat(Color(0.15, 0.35, 0.65, 1.0), 0.8)
	var cream: StandardMaterial3D = _mat(Color(0.92, 0.88, 0.78, 1.0), 0.8)
	# E17: rear posts mirror the live front posts (25/27, 15.5,
	# 0.25x2.2x0.25, centre y 1.2); beams at post-top height
	# 2.3; awning 0.15 above beams (MarketStallA pattern:
	# posts top 2.4, beams 2.4, awning 2.55).
	_box("Post134_E17_R0", Vector3(0.25, 2.2, 0.25), Vector3(25.0, 1.2, 16.5), wood)
	_box("Post134_E17_R1", Vector3(0.25, 2.2, 0.25), Vector3(27.0, 1.2, 16.5), wood)
	_box("Beam134_E17_F", Vector3(2.4, 0.18, 0.18), Vector3(26.0, 2.3, 15.5), wood)
	_box("Beam134_E17_B", Vector3(2.4, 0.18, 0.18), Vector3(26.0, 2.3, 16.5), wood)
	_box("Awning134_E17", Vector3(2.6, 0.12, 1.6), Vector3(26.0, 2.45, 16.0), red)
	_box("Sign134_E17_PostL", Vector3(0.10, 1.6, 0.10), Vector3(25.2, 0.8, 15.0), wood)
	_box("Sign134_E17_PostR", Vector3(0.10, 1.6, 0.10), Vector3(26.8, 0.8, 15.0), wood)
	_box("Sign134_E17_Board", Vector3(1.8, 0.5, 0.08), Vector3(26.0, 1.7, 15.0), cream)
	# F18: 4 corner posts inside the 4x4 table footprint,
	# beams at post-top height 2.4, awning 0.15 above beams.
	_box("Post134_F18_0", Vector3(0.18, 2.4, 0.18), Vector3(18.1, 1.2, 20.1), wood)
	_box("Post134_F18_1", Vector3(0.18, 2.4, 0.18), Vector3(21.9, 1.2, 20.1), wood)
	_box("Post134_F18_2", Vector3(0.18, 2.4, 0.18), Vector3(18.1, 1.2, 23.9), wood)
	_box("Post134_F18_3", Vector3(0.18, 2.4, 0.18), Vector3(21.9, 1.2, 23.9), wood)
	_box("Beam134_F18_F", Vector3(4.2, 0.18, 0.18), Vector3(20.0, 2.4, 20.1), wood)
	_box("Beam134_F18_B", Vector3(4.2, 0.18, 0.18), Vector3(20.0, 2.4, 23.9), wood)
	_box("Awning134_F18", Vector3(4.4, 0.12, 4.4), Vector3(20.0, 2.55, 22.0), blue)
	_box("Sign134_F18_PostL", Vector3(0.10, 1.6, 0.10), Vector3(19.2, 0.8, 19.8), wood)
	_box("Sign134_F18_PostR", Vector3(0.10, 1.6, 0.10), Vector3(20.8, 0.8, 19.8), wood)
	_box("Sign134_F18_Board", Vector3(1.8, 0.5, 0.08), Vector3(20.0, 1.7, 19.8), cream)
	# Duplicate hides, guarded by exact table-position
	# coincidence (0.01 m). Hide, never delete (S121 pattern).
	var g18: Node = world.get_node_or_null("GoldStall18")
	var g18b: Node = world.get_node_or_null("GoldStall18B")
	var g18c: Node = world.get_node_or_null("GoldStall18C")
	if g18 != null and g18b != null and g18c != null:
		var t18: Node = g18.get_node_or_null("GoldTable18") as Node
		var tb: Node = g18b.get_node_or_null("GoldTable18") as Node
		var tc: Node = g18c.get_node_or_null("GoldTable18") as Node
		if t18 != null and tb != null and (t18 as Node3D).global_position.distance_to((tb as Node3D).global_position) < 0.01:
			_hide_all_meshes(g18b)
		if t18 != null and tc != null and (t18 as Node3D).global_position.distance_to((tc as Node3D).global_position) < 0.01:
			_hide_all_meshes(g18c)
	var mb: Node = world.get_node_or_null("MarketStallB")
	var md: Node = world.get_node_or_null("MarketStall15D")
	if mb != null and md != null:
		var bt: Node = mb.get_node_or_null("MarketStallBTable") as Node
		var ba: Node = mb.get_node_or_null("MarketStallBAwning") as Node
		var dt: Node = md.get_node_or_null("StallDTable") as Node
		var da: Node = md.get_node_or_null("StallDAwning") as Node
		if bt != null and ba != null and dt != null and da != null:
			if (bt as Node3D).global_position.distance_to((dt as Node3D).global_position) < 0.01 and (ba as Node3D).global_position.distance_to((da as Node3D).global_position) < 0.01:
				(bt as MeshInstance3D).visible = false
				(ba as MeshInstance3D).visible = false

func _process(_delta: float) -> void:
	_frames += 1
	if _done:
		return
	if _frames < FRAME_GATE:
		return
	var world: Node = get_parent()
	if world == null:
		return
	for hn in ["MarketStallE17", "StallF18", "GoldStall18", "GoldStall18B", "GoldStall18C", "MarketStallB", "MarketStall15D"]:
		if world.get_node_or_null(hn) == null:
			return
	_apply(world as Node3D)
	_done = true
