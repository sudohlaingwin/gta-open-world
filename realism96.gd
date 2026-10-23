extends Node3D
## Slice 95 VIDEO-VERDICT + TPP/FPP BATCH (owner orders 2026-10-23
## ~19:56 video verdict + ~20:00 TPP/FPP complaint).
## Runtime dressing ONLY, plus the two camera/steering code fixes
## that live in camera.gd / car.gd (this file is the dressing
## half). No .tscn edits, no bus-system changes, minibus NOT
## rewired, touch controls otherwise untouched, zero colliders
## on new dressing, StandardMaterial3D only, no dead specular
## lines, no fog/SSAO/glow claims, no photorealism claims.
##
## VIDEO EVIDENCE (owner's vivo V60 recording, frames f_001..f_006
## at 20 s steps, read as images before writing):
##   - f_002 (~20 s, night, on foot): the villager at mid-distance
##     reads as a tiny dark block with a head dot — at phone
##     distance and at night, what reads is SILHOUETTE, not
##     finger width or face detail. So this batch fixes the
##     silhouette (torso taper below), not more micro-detail.
##   - f_003/f_004 (~40/60 s, driving): the driven car is a plain
##     blue box with a yellow roof slab — no hood/cabin/trunk
##     steps, no visible wheel arches, wheels a dark strip
##     under the box. The S71 glass/bumpers/headlights sit ON
##     that box, so the outline stays a box. The car rebuild
##     below replaces the box outline with a real car shape.
##   - f_003..f_005: speed to 39 km/h, heading swings 330 -> 108
##     -> 165 -> 153 -> 214 -> 133 deg across frames — the camera
##     orbits while driving, and (diagnosis in car.gd) driving
##     was SCREEN-fixed while walking is CAMERA-relative since
##     Slice 53, so every orbit flipped the car's on-screen
##     drive direction. That is the jerk, not a missing
##     smoothing line (smoothing already existed).
## PEOPLE SILHOUETTE (frame >= 100, after Slice 95's frame-80
## pass): Slice 94's Chest94/Waist94 are flat-sided BOXES
## (0.58 / 0.44 wide) — the biggest blocky mass on every
## figure at phone distance. They are hidden and replaced by
## TAPERED TORSO CYLINDERS: chest top r 0.26 -> bottom r 0.22,
## waist top r 0.22 -> bottom r 0.19, same shirt colour by the
## Slice 94 sex split, same body-local heights (chest y 0.30,
## waist y 0.00), so shoulders stay widest and the torso
## narrows toward the waist like a real body instead of a
## crate. Shoulder spheres, tapered arms, joint spheres,
## elbow bend and WalkAnim58 swing are untouched (swing is
## already 0.32 rad arms / 0.176 rad legs after the Slice 70
## wobble cut — re-widening it would bring the wobble back).
## Honest night limit, stated plainly: at night, far away,
## even a tapered figure is a dark outline — the taper reads
## in daylight and at mid-distance; at night what reads most
## is the moving outline (walk swing) against lit ground.
## CAR REBUILD (frame >= 100, shape only, physics untouched):
## the original BoxMesh_car box (2.0 x 0.8 x 4.0) is hidden and
## replaced by a real car shape in the same footprint, using
## the LIVE body colour (read from the old body's material
## after Slice 35 paints apply, so the owner's paint is
## preserved): lower tub, stepped hood (front, z -1.9..-0.8),
## glass cabin (z -0.6..0.9) with a body-colour roof line,
## stepped trunk (rear, z 1.0..1.9), plus 4 wheel-arch torus
## trims framing the existing round wheels (r 0.35, which
## keep spinning via car.gd — the arches are static children
## of the car, not of the wheels). S71 bumpers/headlights/
## taillights, S94 plates/handles/mirrors/exhaust/roof-rails
## are KEPT — their positions still align (hood front
## z -1.905 vs headlights z -2.02 proud; trunk rear 1.905 vs
## taillights 2.02 proud; bumpers z +/-2.02 proud of the tub
## ends +/-1.95). S71 side/rear glass boxes are hidden: they
## were sized for the 2.0-wide box and would float beside
## the narrower glass cabin. Collider BoxShape3D_car and all
## car.gd tuning are untouched. Other road vehicles are NOT
## reshaped here (motorcycle/tuk-tuk already got Slice 71
## rebuilds; the video complaint is the car).
## TPP/FPP BUTTON (this file, immediate, not frame-gated):
## ViewButton96 in the main HUD at (940, 360, 104, 104) —
## directly above the bus-button column, same thumb column,
## disjoint from every existing rect (proved in the sim
## audit). Label "eye + TPP/FPP" — the mode names the owner
## himself used, not the bare English "View". It calls
## FollowCamera.cycle_view. Visible ALWAYS (it can always
## act: on foot, in a car, on the cart). The old More-stack
## ViewButton62 is RETIRED in this slice: chill_world62 no
## longer creates it and chill_controller62 force-hides any
## instance — one view button only, no duplicates.
## Counting: 19 torso-taper figure sets + 1 car rebuild +
## 1 view button = 21 new dressing items. The steering fix
## (car.gd) and on-foot FPP (camera.gd) are code fixes, not
## dressing items, and are counted separately in the report.
## Together with the Slice 95 items already in this push
## (50), this push carries 71 items + 2 code fixes +
## the opponent slice-384 review.

static func _mat(c: Color, rough: float, met: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = met
	return m

static func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _torus(parent: Node3D, inner_r: float, outer_r: float, mat: Material, pos: Vector3, nm: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var tm := TorusMesh.new()
	tm.inner_radius = inner_r
	tm.outer_radius = outer_r
	mi.mesh = tm
	mi.position = pos
	mi.rotation = rot
	mi.set_surface_override_material(0, mat)
	parent.add_child(mi)
	return mi

static func _hash01(s: String) -> float:
	# Identical to Slice 94/95's splitter, so the sex split
	# matches exactly (player male; villagers by hash thirds).
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0

static func _set_rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	# Same anchor pattern as Slice 61 hud_fix61b._set_rect.
	c.anchor_left = x / 1280.0
	c.anchor_top = y / 720.0
	c.anchor_right = (x + w) / 1280.0
	c.anchor_bottom = (y + h) / 720.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0

static func _view_button(world: Node3D) -> void:
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer == null:
		return
	if layer.get_node_or_null("ViewButton96") != null:
		return
	var cam := world.get_node_or_null("FollowCamera")
	var btn := Button.new()
	btn.name = "ViewButton96"
	btn.text = "👁 TPP/FPP"
	btn.add_theme_font_size_override("font_size", 16)
	layer.add_child(btn)
	_set_rect(btn, 940.0, 360.0, 104.0, 104.0)
	btn.visible = true
	if cam != null and cam.has_method("cycle_view"):
		btn.pressed.connect(Callable(cam, "cycle_view"))

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism96") != null:
		return
	_view_button(world)
	var n := Node3D.new()
	n.name = "Realism96"
	n.set_script(load("res://realism96.gd"))
	world.call_deferred("add_child", n)

var _frames: int = 0
var _done: bool = false

func _process(_delta: float) -> void:
	# Frame >= 100: after Slice 70 (frame 12), Slice 73
	# (frame 26), Slice 93 (frame 40), Slice 94 (frame 60)
	# and Slice 95 (frame 80) have all run, so the taper
	# and the car shape land on final values.
	_frames += 1
	if _frames < 100 or _done:
		return
	var world := get_parent() as Node3D
	if world == null:
		return
	_people_taper(world)
	_car_rebuild(world)
	_done = true

static func _people_taper(world: Node3D) -> void:
	var white_top := _mat(Color(0.96, 0.96, 0.97, 1.0), 0.7)
	var pink_top := _mat(Color(0.95, 0.80, 0.85, 1.0), 0.7)
	var bodies: Array = []
	for child in world.get_children():
		if child.name == "Player" or String(child.name).begins_with("Villager"):
			bodies.append(child)
	for b in bodies:
		var h: float = _hash01(String(b.name))
		var is_player := String(b.name) == "Player"
		var sex := 0
		if not is_player:
			sex = int(h * 3.0) % 3
		var shirt: Material = white_top
		if sex == 2:
			shirt = pink_top
		var chest := b.get_node_or_null("Chest94") as MeshInstance3D
		if chest != null:
			chest.visible = false
		var waist := b.get_node_or_null("Waist94") as MeshInstance3D
		if waist != null:
			waist.visible = false
		# Tapered torso: chest widest at the shoulders, waist
		# narrower below. Heights match the hidden boxes
		# (chest spans y 0.14..0.46, waist -0.15..0.15, with
		# a 0.01 overlap at y 0.14..0.15 so no gap shows).
		_cyl(b, 0.26, 0.22, 0.32, shirt, Vector3(0.0, 0.30, 0.0), "Torso96_Chest")
		_cyl(b, 0.22, 0.19, 0.30, shirt, Vector3(0.0, 0.00, 0.0), "Torso96_Waist")

static func _car_rebuild(world: Node3D) -> void:
	var car := world.get_node_or_null("Car") as Node3D
	if car == null:
		return
	# Live body colour (Slice 35 paint, already applied by
	# player.gd before frame 100). Fallback is the scene's
	# default red-ish paint, never a guessed two-tone.
	var body_col := Color(0.65, 0.12, 0.12, 1.0)
	var old_body := car.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if old_body != null:
		var m := old_body.get_surface_override_material(0) as StandardMaterial3D
		if m != null:
			body_col = m.albedo_color
		old_body.visible = false
	# S71 glass sized for the 2.0-wide box would float
	# beside the narrower cabin — hidden, replaced below.
	for wname in ["Window71_L", "Window71_R", "Windshield71", "RearWindow71"]:
		var w := car.get_node_or_null(wname) as MeshInstance3D
		if w != null:
			w.visible = false
	var body_m := _mat(body_col, 0.45, 0.2)
	var glass_m := _mat(Color(0.10, 0.13, 0.18, 1.0), 0.2, 0.1)
	var arch_m := _mat(Color(0.10, 0.10, 0.10, 1.0), 0.6)
	# Lower tub + stepped hood / trunk + glass cabin + roof.
	# Car-local, forward is -z (headlights at z -2.05).
	_box(car, Vector3(1.90, 0.45, 3.90), body_m, Vector3(0.0, -0.18, 0.0), "Tub96")
	_box(car, Vector3(1.85, 0.16, 1.05), body_m, Vector3(0.0, 0.10, -1.38), "Hood96")
	_box(car, Vector3(1.85, 0.18, 0.85), body_m, Vector3(0.0, 0.10, 1.48), "Trunk96")
	_box(car, Vector3(1.70, 0.40, 1.45), glass_m, Vector3(0.0, 0.30, 0.15), "CabinGlass96")
	_box(car, Vector3(1.78, 0.07, 1.50), body_m, Vector3(0.0, 0.53, 0.15), "Roof96")
	for sx in [-1.0, 1.0]:
		for pz in [-0.55, 0.85]:
			_box(car, Vector3(0.08, 0.40, 0.08), body_m, Vector3(sx * 0.82, 0.30, pz), "Pillar96_%d_%d" % [int(sx), int(pz * 100.0)])
		for wz in [-1.3, 1.3]:
			# Arch ring in the wheel plane (YZ): torus lies in
			# XY by default, so rotate 90 deg about Y. Ring
			# inner r 0.40 / outer 0.48 frames the r 0.35
			# wheel with a 0.05..0.13 trim band.
			_torus(car, 0.40, 0.48, arch_m, Vector3(sx * 1.02, -0.55, wz), "Arch96_%d_%d" % [int(sx), int(wz * 10.0)], Vector3(0.0, 1.5707963267948966, 0.0))
