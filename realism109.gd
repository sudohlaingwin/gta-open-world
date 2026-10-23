extends Node3D

## Slice 108 (parent sequence): FINISH THE SHEET-DETAIL BACKLOG —
## Stilt97 / Stilt13 / hamlet clotheslines + firewood + 2 route signs.
## Audit-first, live-probed 2026-10-24 (audit109.gd):
## - ALL 8 target groups carry ZERO line/log children: Stilt97_5
##   (-26,-16), Stilt97_6 (0,-22), Stilt97_15_4 (-40,-4), all
##   unscaled, front +z; StiltHouse13 (20,-22) x1.7, front +z;
##   HamletHouse75_0..3 (2075/2125, 78/98) x1.8, front -z.
## - BUT the hamlet z-78 pair ALREADY has a clothesline + firewood
##   from the S94 restyle: Restyle94_2075_78 / Restyle94_2125_78
##   each carry Line94 (5.0 line at world z 84, back side) +
##   Cloth94_A/B + Log94_0..4. Adding S107-style lines there
##   would DUPLICATE them, so the z-78 pair is EXCLUDED.
## - Genuine per-house gaps: Stilt97 x3, StiltHouse13 x1,
##   hamlet z-98 pair x2 = 6 houses x (1 clothesline +
##   1 firewood stack) = 12 items, placed in WORLD coords
##   (S107 EF precedent — no group-scale assumption, S104's
##   1.7-vs-1.8 lesson: never hardcode a group scale).
## - Clearances (live solids, audit109): Stilt97 lines sit 5.0 m
##   behind centres vs solid half-depth 3.15 -> 1.85 m clear;
##   Stilt13 line 6.8 m behind centre vs scaled solid half-depth
##   3.23 -> 3.57 m clear; hamlet lines 9.0 m behind centres vs
##   solid half-depth 5.76 -> 3.24 m clear; firewood sides clear
##   by 1.25 m (Stilt97), 1.72 m (Stilt13, scaled), 3.09 m
##   (hamlet). Garments hang below the raised back windows:
##   Stilt97 window bottoms y 2.15 vs garment tops 1.575;
##   Stilt13 window bottoms y 2.89 (scaled) vs 1.575; hamlet
##   window bottoms y 3.69 vs 1.575 — no window hidden.
## - ROUTE SIGNS (fresh gap, proven): S69's 10 signboards sit
##   nowhere near the 2100 junction or the hamlet (nearest board
##   is 1842 m away at (258,10)), so the junction spur and the
##   hamlet have NO marker at all. Two boards in the S69
##   pattern (posts + board + gold trims + Noto Label3D):
##   junction board at (2086,14) facing -x (head-on for
##   eastbound drivers; westbound see the back, the same
##   one-sided limitation as S69) reading "hamlet road", and
##   hamlet board at (2088,68) facing -z toward the spur
##   approach reading "hamlet". "hamlet" is this slice's
##   Burmese rendering of "hamlet" — no owner-given hamlet
##   name exists in the game. The hamlet board stands EAST
##   of the spur path (clear of the 2094..2106 spur slab by
##   2.8 m) so it never reads as a roadblock across the path.
## - Hill summit dressing: SKIPPED, confirming S107 — the
##   nearest S96 hill to any road is Hill97E_0, 135 m from the
##   east-track end and behind the S106 border forest; summit
##   dressing there would not read at phone distance.
## Deliberately NOT added (audited, reasons stand): MD1/2/3/6/10
## (S103, permanent); MindonPost/MDHouse8 relocation (owner
## order 2026-10-22 — the overlap stands); S104-S107
## audited-present items (markets/tea/monastery/zayat/school/
## pagoda dressing, scarecrows, ploughs, EF clotheslines —
## S107 did those — kilometre posts, vehicle trim incl.
## Tail99/Stand99/Bag99/Mud99/Bump99/Harness105/Nav99,
## earrings/necklaces, market umbrellas, vendor figures);
## Cow2 (ambient, not rideable); traffic-car drivers (solid
## cabins, would not read); bus door window (strip already
## spans above the door); temple bell / traffic lights
## (invented / no logic); marginal night residuals (rows band
## 1.41 m gap, spur 1.3 m, junction 4.5 m, hill-face 4.71 m —
## NOT padded with more lamps).
## Counting (stated): clothesline = 1 per house; firewood
## stack = 1 per house; sign board assembly = 1. TOTAL:
## 12 + 2 = 14 honest items — small, stated plainly.
## BACKLOG STATE after this slice: the sheet-detail backlog
## is FINISHED (every stilt/house group that can take the
## sheet treatment has it, except the S96 pavilion exclusion
## and the permanent MD1/2/3/6/10). What remains is only
## low-value hill summit dressing, the standing conflicts /
## residuals, and whatever the owner's phone verdicts
## (still pending on S96-S107) point at next.
## Runtime dressing ONLY, no .tscn edits, no bus-system
## changes, minibus NOT rewired, big bus NOT rewired
## (Slice 81 limit), touch controls untouched, zero NEW
## colliders, StandardMaterial3D only, no dead specular
## lines, no fog/SSAO/glow claims (no WorldEnvironment
## exists), no photorealism claims: stylised smooth
## procedural work. Runs at frame >= 360, after
## realism108's 340 pass.

var _frames: int = 0
var _done: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism109") != null:
		return
	var n := Node3D.new()
	n.name = "Realism109"
	n.set_script(load("res://realism109.gd"))
	world.call_deferred("add_child", n)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 360:
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

func _apply(world: Node3D) -> void:
	if world == null:
		return
	_sheet(world)
	_signs(world)

func _sheet(world: Node3D) -> void:
	# [tag, house x, house z, line z, firewood x] — all backs are
	# +-z, so every line spans x; firewood sits on the +x side.
	# S107 EF pattern sizes: poles r 0.05 h 1.7, line y 1.6,
	# garments 0.55 x 0.75 at y 1.2, logs r 0.15 h 1.1.
	var houses: Array = [
		["S5", -26.0, -16.0, -21.0, -20.5],
		["S6", 0.0, -22.0, -27.0, 5.5],
		["S15", -40.0, -4.0, -9.0, -34.5],
		["S13", 20.0, -22.0, -28.8, 25.95],
		["H2", 2075.0, 98.0, 107.0, 2084.9],
		["H3", 2125.0, 98.0, 107.0, 2134.9],
	]
	var wood_m := _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	var line_m := _mat(Color(0.80, 0.80, 0.80, 1.0), 0.9)
	var bark_m := _mat(Color(0.35, 0.22, 0.12, 1.0), 1.0)
	var garments: Array = [
		_mat(Color(0.95, 0.95, 0.95, 1.0), 0.9),
		_mat(Color(0.45, 0.20, 0.60, 1.0), 0.9),
		_mat(Color(0.95, 0.60, 0.70, 1.0), 0.9),
	]
	for h in houses:
		var tag := String(h[0])
		var hx := float(h[1])
		var hz := float(h[2])
		var lz := float(h[3])
		var fx := float(h[4])
		_cyl(world, 0.05, 0.05, 1.7, wood_m, Vector3(hx - 2.0, 0.85, lz), "Line109_%s_PoleA" % tag)
		_cyl(world, 0.05, 0.05, 1.7, wood_m, Vector3(hx + 2.0, 0.85, lz), "Line109_%s_PoleB" % tag)
		_box(world, Vector3(4.0, 0.02, 0.02), line_m, Vector3(hx, 1.6, lz), "Line109_%s_Line" % tag)
		for gi in 3:
			var off := -1.3 + 1.3 * float(gi)
			_box(world, Vector3(0.55, 0.75, 0.03), garments[gi], Vector3(hx + off, 1.2, lz), "Line109_%s_Garment%d" % [tag, gi])
		_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx, 0.15, hz - 0.18), "Wood109_%s_A" % tag, Vector3(1.5708, 0.0, 0.0))
		_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx, 0.15, hz + 0.18), "Wood109_%s_B" % tag, Vector3(1.5708, 0.0, 0.0))
		_cyl(world, 0.15, 0.15, 1.1, bark_m, Vector3(fx, 0.42, hz), "Wood109_%s_C" % tag, Vector3(1.5708, 0.0, 0.0))

func _signs(world: Node3D) -> void:
	# S69 pattern: posts + board + gold trims + Noto Label3D.
	# If the font fails to load, skip labels rather than show
	# missing-glyph boxes (the sim fails loudly on this case).
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	var board_m := _mat(Color(0.06, 0.24, 0.17, 1.0), 0.85)
	var trim_m := _mat(Color(0.85, 0.68, 0.15, 1.0), 0.4)
	trim_m.metallic = 0.3
	var post_m := _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	# [tag, text, x, z, rot_y] — junction faces -x (head-on for
	# eastbound drivers), hamlet faces -z (toward the spur).
	var signs: Array = [
		["Junction", "ရွာငယ် လမ်း", 2086.0, 14.0, -PI / 2.0],
		["Hamlet", "ရွာငယ်", 2088.0, 68.0, PI],
	]
	for s in signs:
		var tag := String(s[0])
		var text := String(s[1])
		var g := Node3D.new()
		g.name = "Sign109_%s" % tag
		g.position = Vector3(float(s[2]), 0.0, float(s[3]))
		g.rotation.y = float(s[4])
		world.add_child(g)
		_cyl(g, 0.18, 0.18, 3.7, post_m, Vector3(-3.2, 1.85, 0.0), "Post109L")
		_cyl(g, 0.18, 0.18, 3.7, post_m, Vector3(3.2, 1.85, 0.0), "Post109R")
		_box(g, Vector3(7.5, 2.2, 0.15), board_m, Vector3(0.0, 2.6, 0.0), "Board109")
		_box(g, Vector3(7.5, 0.12, 0.17), trim_m, Vector3(0.0, 3.7, 0.0), "Trim109T")
		_box(g, Vector3(7.5, 0.12, 0.17), trim_m, Vector3(0.0, 1.5, 0.0), "Trim109B")
		if font != null:
			var lab := Label3D.new()
			lab.name = "Label109"
			lab.text = text
			lab.font = font
			lab.font_size = 64
			lab.pixel_size = 0.012
			lab.outline_size = 8
			lab.outline_modulate = Color(0.05, 0.05, 0.05, 1.0)
			lab.modulate = Color(1.0, 0.90, 0.35, 1.0)
			lab.position = Vector3(0.0, 2.6, 0.12)
			g.add_child(lab)
		else:
			push_error("Realism109: Myanmar font failed to load, label skipped for " + text)
