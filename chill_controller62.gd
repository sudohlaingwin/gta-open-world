extends Node3D
## Slice 62 controller — living nature + 3 Myanmar seasons + HUD gating.
## Added at runtime by chill_world62.dress() as ChillController62, a
## child of the world root (same pattern as Slice 56 NightLights56).
## What runs every frame (all absolute assignments, never stacking):
## - Sway: Chill62 canopy + flower nodes rotate gently (sin phase).
## - Seasons: နွေ summer (dry/golden), မိုး rainy (rain on), ဆောင်း
##   winter (cool/clear). A season change re-tints the ground (base
##   albedo captured AFTER the deferred Slice 61 style pass, so the
##   style palette is the base, not a fight) and every canopy/TreeTop
##   material, and re-asserts rain: rainy season forces Rain17 on,
##   other seasons restore the player's manual rain toggle.
## - Lamps: Chill62 lamp glow material emits only when daylight
##   < 0.15 (the game's shared dark rule).
## - HUD: View/Season buttons are visible only while the player's
##   hud_more_open is true (the Slice 61 More-stack rule).
## Season persists in SaveManager.season62 (0/1/2, default summer);
## when SaveManager is absent (headless sim without autoloads) the
## controller still works in-session and simply does not persist.

const SEASON_NAMES: Array = ["နွေ", "မိုး", "ဆောင်း"]
const GROUND_MUL: Array = [Color(1.0, 0.92, 0.72, 1.0), Color(0.92, 1.0, 0.92, 1.0), Color(0.96, 0.96, 1.0, 1.0)]
const LEAF_MUL: Array = [Color(1.0, 0.94, 0.78, 1.0), Color(0.9, 1.0, 0.9, 1.0), Color(0.95, 0.95, 1.0, 1.0)]

var _time: float = 0.0
var _frames: int = 0
var _season: int = 0
var _applied: int = -1
var _captured: bool = false
var _ground_base: Color = Color.WHITE
var _canopy_base: Dictionary = {}
var _sway: Array = []
var _lamp_mats: Array = []

static func _hash01(s: String) -> float:
	var n := s.hash()
	n = (n ^ (n >> 13)) * 1274126177
	n = (n ^ (n >> 16)) & 0x7fffffff
	return float(n % 1000) / 1000.0

func _ready() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.get("season62") != null:
		_season = clampi(int(sm.get("season62")), 0, 2)

func cycle_season() -> void:
	_season = (_season + 1) % 3
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.get("season62") != null:
		sm.set("season62", _season)
		if sm.has_method("save_settings"):
			sm.call("save_settings")
	_applied = -1

func _capture(world: Node3D) -> void:
	_captured = true
	var ground := world.get_node_or_null("GroundMesh") as MeshInstance3D
	if ground != null:
		var gm := ground.get_surface_override_material(0) as StandardMaterial3D
		if gm != null:
			_ground_base = gm.albedo_color
	var stack: Array = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var nm_all := String(n.name)
		# Flower groups are Node3D containers (stem + head meshes
		# inside); swaying the group sways the whole flower. (The
		# MeshInstance3D branch below only catches canopy meshes.)
		if n is Node3D and nm_all.begins_with("Chill62_Flower") and not (n is MeshInstance3D):
			_sway.append([n, (n as Node3D).rotation.z, _hash01(nm_all) * 6.283])
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var nm := String(mi.name)
			if nm.begins_with("Chill62_Canopy") or nm.begins_with("Chill62_Flower"):
				_sway.append([mi, mi.rotation.z, _hash01(nm) * 6.283])
			if nm.begins_with("Chill62_Lamp"):
				var lm := mi.get_surface_override_material(0) as StandardMaterial3D
				if lm != null and not _lamp_mats.has(lm):
					_lamp_mats.append(lm)
			if "Canopy" in nm or nm.begins_with("TreeTop"):
				var cm := mi.get_surface_override_material(0) as StandardMaterial3D
				if cm != null and not cm.emission_enabled and not _canopy_base.has(cm):
					_canopy_base[cm] = cm.albedo_color
		for c in n.get_children():
			stack.push_back(c)

func _apply_season(world: Node3D) -> void:
	_applied = _season
	var gm_mul := GROUND_MUL[_season] as Color
	var lf_mul := LEAF_MUL[_season] as Color
	var ground := world.get_node_or_null("GroundMesh") as MeshInstance3D
	if ground != null:
		var gm := ground.get_surface_override_material(0) as StandardMaterial3D
		if gm != null:
			gm.albedo_color = Color(_ground_base.r * gm_mul.r, _ground_base.g * gm_mul.g, _ground_base.b * gm_mul.b, 1.0)
	for mat in _canopy_base.keys():
		var base := _canopy_base[mat] as Color
		(mat as StandardMaterial3D).albedo_color = Color(base.r * lf_mul.r, base.g * lf_mul.g, base.b * lf_mul.b, 1.0)

func _process(delta: float) -> void:
	_time += delta
	_frames += 1
	var world := get_parent() as Node3D
	if world == null:
		return
	if not _captured and _frames >= 5:
		_capture(world)
	if _captured and _season != _applied:
		_apply_season(world)
	# Sway (canopies gentle, flowers a touch livelier).
	for entry in _sway:
		var sn := entry[0] as Node3D
		if sn == null:
			continue
		var base_rot: float = entry[1]
		var phase: float = entry[2]
		var amp := 0.06 if String(sn.name).begins_with("Chill62_Flower") else 0.03
		sn.rotation.z = base_rot + sin(_time * 1.6 + phase) * amp
	# Daylight for lamp gating.
	var day := 1.0
	var dn := world.get_node_or_null("DayNight")
	if dn != null and dn.has_method("daylight"):
		day = float(dn.call("daylight"))
	var night := day < 0.15
	for lm in _lamp_mats:
		(lm as StandardMaterial3D).emission_enabled = night
	# Rain: rainy season forces Rain17 on; otherwise the manual toggle.
	var player := world.get_node_or_null("Player")
	var rain := world.get_node_or_null("Rain17") as GPUParticles3D
	if rain != null:
		var want := false
		if _season == 1:
			want = true
		elif player != null and player.get("rain_on") != null:
			want = bool(player.get("rain_on"))
		rain.visible = want
		rain.emitting = want
	# More-gated buttons (Slice 61 rule) + season label.
	var more := false
	if player != null and player.get("hud_more_open") != null:
		more = bool(player.get("hud_more_open"))
	var layer := world.get_node_or_null("JoystickLayer") as CanvasLayer
	if layer != null:
		var vb := layer.get_node_or_null("ViewButton62") as Button
		if vb != null:
			vb.visible = more
		var sb := layer.get_node_or_null("SeasonButton62") as Button
		if sb != null:
			sb.visible = more
			sb.text = SEASON_NAMES[_season]
