extends RefCounted
## Slice 69 — Burmese 3D signboards, physical boards on posts.
## Owner direction: readable Burmese signs at real landmarks (not
## floating text). This is the honest fix to the opponent slices
## 209/210/212/213 defect, proven live in review: their Label3D
## nodes carry Burmese strings but NO font, and Godot 4.3's default
## font has_char() is false for every Myanmar codepoint tested
## (U+1000, U+1004, U+1019, U+102C, U+1039, U+103A, U+1040) and for
## emoji — so their "Burmese signage" cannot render as Burmese.
## This file therefore uses a REAL Myanmar font: Noto Sans Myanmar
## Regular (fonts/NotoSansMyanmar-Regular.ttf, SIL OFL 1.1, see
## fonts/NotoSansMyanmar-ATTRIBUTION.txt), loaded as a FontFile.
## Coverage is verified in the Slice 69 sim: every codepoint of
## every sign text below returns has_char() == true on that font,
## and get_string_size() widths at font_size 64 are 118-553 px, so
## at pixel_size 0.012 the widest sign is 6.64 m on a 7.5 m board.
## Design: two wood posts + a dark green board with gold trim +
## a Label3D (billboard disabled, double_sided true) on the board
## face. Boards are visual only — NO colliders anywhere, so no
## sign can block a road, a lane, or a vehicle entry (stated
## plainly; a player walking through a signpost is the accepted
## tradeoff, same as the Slice 64 scenery carts' no-collider rule
## for non-blocking props). Runtime-only, no scene touched.
## Positions are real scene-node coordinates (main.tscn): Market
## MarketStallA (16,12), TeaShop13 (-14,20), School13 (-34,14),
## MindonHospital (122,58), MonasteryBell (-6,-32), Pagoda
## (-20,-25), GuestHouse20 (26,36), NightMarket20 (-36,32).
## Gate signs stand beside real roads: East Fields sign at
## (258,10) — off the Slice 62 12 m road slab (z -6..6), clear
## of the south houses (x >= 285) and north houses (z -16);
## Mindon sign at (84,9) — west of the Slice 37 bridge line
## x 88, checked clear of bridge/bank/water nodes (all at z <= 0).
## Idempotent: if Signboards69 already exists, dress() returns.

static func _mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

static func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, nm: String, r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _sign(parent: Node3D, idx: int, text: String, x: float, z: float, rot_y: float, font: Font, board_mat: Material, trim_mat: Material, post_mat: Material) -> void:
	var g := Node3D.new()
	g.name = "Signboard69_%d" % idx
	g.position = Vector3(x, 0.0, z)
	g.rotation.y = rot_y
	parent.add_child(g)
	# Posts (3.7 m) + board (7.5 x 2.2 m, centre y 2.6) + gold trim.
	_cyl(g, "Post69L", 0.18, 3.7, Vector3(-3.2, 1.85, 0.0), post_mat)
	_cyl(g, "Post69R", 0.18, 3.7, Vector3(3.2, 1.85, 0.0), post_mat)
	_box(g, "Board69", Vector3(7.5, 2.2, 0.15), Vector3(0.0, 2.6, 0.0), board_mat)
	_box(g, "Trim69T", Vector3(7.5, 0.12, 0.17), Vector3(0.0, 3.7, 0.0), trim_mat)
	_box(g, "Trim69B", Vector3(7.5, 0.12, 0.17), Vector3(0.0, 1.5, 0.0), trim_mat)
	# Label3D on the board face. Font MUST be the Myanmar font:
	# if it failed to load, skip the label rather than show boxes
	# from the default font (the sim fails loudly on this case).
	if font != null:
		var lab := Label3D.new()
		lab.name = "Label69"
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
		push_error("Signboards69: Myanmar font failed to load, label skipped for " + text)

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Signboards69") != null:
		return
	var font := load("res://fonts/NotoSansMyanmar-Regular.ttf") as Font
	var board := _mat(Color(0.06, 0.24, 0.17, 1.0), 0.85)
	var trim := _mat(Color(0.85, 0.68, 0.15, 1.0), 0.4)
	trim.metallic = 0.3
	var post := _mat(Color(0.45, 0.30, 0.16, 1.0), 0.9)
	var grp := Node3D.new()
	grp.name = "Signboards69"
	# Deferred add: player._ready runs while Main is still setting
	# up children, so a direct add_child fails ("parent busy") —
	# the same reason Slice 56/59/62 dressing defers its adds.
	# Content is built onto grp before the add, so nothing pops.
	world.call_deferred("add_child", grp)
	# [text, x, z, rot_y] — sign stands 8 m off the landmark in +z
	# and faces -z toward it (rot PI), except the Mindon gate,
	# which faces +x into town (rot PI/2).
	var signs: Array = [
		["ဈေး", 16.0, 20.0, PI],
		["လက်ဖက်ရည်", -14.0, 28.0, PI],
		["ကျောင်း", -34.0, 22.0, PI],
		["ဆေးရုံ", 122.0, 66.0, PI],
		["ဘုန်းကြီးကျောင်း", -6.0, -24.0, PI],
		["စေတီ", -20.0, -17.0, PI],
		["ဧည့်ရိပ်သာ", 26.0, 44.0, PI],
		["ညဈေး", -36.0, 40.0, PI],
		["လယ်ကွင်း ဝင်ပေါက်", 258.0, 10.0, PI],
		["မင်းတုန်း ဝင်ပေါက်", 84.0, 9.0, PI * 0.5],
	]
	var i := 0
	for s in signs:
		_sign(grp, i, str(s[0]), float(s[1]), float(s[2]), float(s[3]), font, board, trim, post)
		i += 1
