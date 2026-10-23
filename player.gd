extends CharacterBody3D
const DressingScript = preload("res://village_dressing.gd")
const City56Script = preload("res://city_visual56.gd")
const River57Script = preload("res://river_bridge57.gd")
const Dress58Script = preload("res://character_dress58.gd")
const Dress59Script = preload("res://district_dress59.gd")
const Style61Script = preload("res://style61.gd")
const HudPolish60Script = preload("res://hud_polish60.gd")
const HudFix61bScript = preload("res://hud_fix61b.gd")
const Chill62Script = preload("res://chill_world62.gd")
const EastFields64Script = preload("res://eastfields64.gd")
const Signboards69Script = preload("res://signboards69.gd")
const BusSim74Script = preload("res://bus_sim74.gd")
const BusRoute75Script = preload("res://bus_route75.gd")
const BusSim76Script = preload("res://bus_sim76.gd")
const BusSim77Script = preload("res://bus_sim77.gd")
## Slice 2 player: walk + sprint + jump + enter/exit car AND cart.
## Walk: arrow keys / WASD, or the touch joystick (touch_vector).
## Slice 8 action HUD (TOUCH-FIRST — this is a mobile game):
## on-screen Sprint (hold) + Jump + Vehicle buttons in JoystickLayer
## do sprint / jump / enter-exit on a phone; Shift / J / Enter-Space
## are kept ONLY as desktop fallbacks, never the primary path.
## Talk to a villager (TOUCH-FIRST — this is a mobile game):
## walk within 3.5 m and the on-screen Talk button appears
## (TalkButton in JoystickLayer); tap it — or tap the villager
## directly — and the nearest villager's talk_to() faces the player
## and shows its greeting bubble. E is kept ONLY as an optional
## desktop-debug fallback, not the primary path (Slice 6 made E the
## primary path; that was a mobile-design miss, corrected in Slice 7).

@export var walk_speed: float = 5.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 5.0

var driving: bool = false
var driving_vehicle: Node = null
var touch_vector: Vector2 = Vector2.ZERO
var touch_sprint: bool = false
var touch_throttle_up: bool = false
var touch_throttle_down: bool = false
var jump_requested: bool = false
var e_was_pressed: bool = false
var talk_button: Button = null
var talk_button_connected: bool = false
var sprint_button: Button = null
var sprint_button_connected: bool = false
var jump_button: Button = null
var jump_button_connected: bool = false
var vehicle_button: Button = null
var vehicle_button_connected: bool = false
var throttle_up_button: Button = null
var throttle_up_connected: bool = false
var throttle_down_button: Button = null
var throttle_down_connected: bool = false
var quest_label: Label = null
var talked_ids: Array = []
var speed_label: Label = null
var clock_label: Label = null
var orbit_button: Button = null
var orbit_button_connected: bool = false
# Slice 10 HUD + quest state. All nodes live in the real scene
# (JoystickLayer) and are found lazily, like the Slice 7/8 buttons.
var stamina: float = 100.0
var touch_yaw_left: bool = false
var touch_yaw_right: bool = false
var minimap_dots: Dictionary = {}
var minimap_panel: Control = null
var compass_label: Label = null
# Slice 50 (audit item 7): per-frame HUD throttle. The audit counted ~25
# _update_* calls per physics frame with ~60 minimap node lookups, a
# villager group scan, and ~60 dot writes every frame. Measurement (see
# README item-7 section) showed the real on-foot total was ~188 node
# lookups + 3 group scans per frame, because the prompt loop, the
# nearest-vehicle/villager helpers, and every button updater repeat the
# same lookups. The fix has three parts, all behaviour-preserving:
# 1. _n() caches every player-relative node reference once (nulls are
#    never cached, so the lazy first-frame wiring still retries until
#    the CanvasLayer exists; freed nodes are re-looked-up via
#    is_instance_valid). World/scene nodes are never reparented at
#    runtime, so a cached valid reference is the node at that path.
# 2. _villagers() refreshes the villager group list at most once per
#    second; membership never changes at runtime (18 villagers spawned
#    with the scene, none freed), while dots still track every frame
#    from the cached references.
# 3. _set_text/_set_visible/_set_bar_value write only when the new
#    value differs from the shown one; minimap dots write only when
#    their computed panel position differs. Moving dots still track
#    every frame while moving (their position changes every frame);
#    parked vehicles, standing villagers, and static landmarks cost
#    zero writes. Button visibility toggles are deliberately NOT
#    converted (boolean assigns, out of the item's list) — deferred.
var _node_cache: Dictionary = {}
var _child_cache: Dictionary = {}
var _villagers_cache: Array = []
var _villagers_cache_age: float = 999.0
var _mm_cached: Node = null
var _sm_cached: Node = null


## Cached player-relative node lookup (see the Slice 50 block above).
func _n(path: String) -> Node:
	var cached: Node = _node_cache.get(path)
	if cached != null and is_instance_valid(cached):
		return cached
	var found: Node = get_node_or_null(path)
	if found != null:
		_node_cache[path] = found
	return found


## Cached child lookup for nodes owned by another node (lantern glows,
## vehicle headlights): same rules as _n, keyed by a stable string.
func _child_cached(parent: Node, child_name: String, key: String) -> Node:
	var cached: Node = _child_cache.get(key)
	if cached != null and is_instance_valid(cached):
		return cached
	var found: Node = parent.get_node_or_null(child_name) if parent != null else null
	if found != null:
		_child_cache[key] = found
	return found


## Villager group list, refreshed at most once per second (see above).
func _villagers() -> Array:
	if _villagers_cache_age > 1.0 or _villagers_cache.is_empty():
		_villagers_cache = get_tree().get_nodes_in_group("villagers")
		_villagers_cache_age = 0.0
	return _villagers_cache


## Change-only display writes (see the Slice 50 block above).
func _set_text(node: Node, text: String) -> void:
	if node != null and str(node.get("text")) != text:
		node.set("text", text)


func _set_visible(node: Node, v: bool) -> void:
	if node != null and bool(node.get("visible")) != v:
		node.set("visible", v)


func _set_bar_value(bar: Node, v: float) -> void:
	if bar != null and float(bar.get("value")) != v:
		bar.set("value", v)
# Slice 34: waypoint guidance HUD (completes the Slice 28 map waypoint).
# Nodes live in the real scene (JoystickLayer/GuidePanel34) and are
# found lazily like the other HUD controls. The panel is a plain
# Control child of JoystickLayer, so the Slice 32 _apply_hud_scale
# pass scales it with every other HUD control automatically.
var guide_panel: Control = null
var guide_arrow: Label = null
var guide_dist: Label = null
# Arrived radius in metres: inside this the arrow hides and the
# arrived label shows. The waypoint is NOT auto-cleared — it stays
# set (beacon + minimap dot stay) until the player clears it from
# the map, so arrival never silently deletes the player's marker.
const GUIDE_ARRIVED_RADIUS: float = 5.0
# Slice 38 solidity: world bounds, exit clearance, stuck recovery.
# The playable ground plane is 320 x 220 centred at (90, 0), so the
# playable area is x -70..250, z -110..110. The clamp keeps the
# capsule CENTRE 0.5 m inside the edge so the body never hangs off
# the plane; the edge label tells the player why they stopped.
const WORLD_MIN_X: float = -69.5
const WORLD_MAX_X: float = 2449.5
const WORLD_MIN_Z: float = -209.5
const WORLD_MAX_Z: float = 109.5
# Last ground position where the player stood freely (on the floor
# with no slide collision). Stuck recovery returns here. Runtime
# only — never saved, so it is always fresh for this session.
var last_free_pos: Vector3 = Vector3(0.0, 1.0, 5.0)
var _probe_shape: CapsuleShape3D = null
var exit_blocked_timer: float = 0.0
var edge_label: Label = null
var stuck_button: Button = null
var stuck_button_connected: bool = false
var day_label: Label = null
var stamina_bar: ProgressBar = null
var speed_bar: ProgressBar = null
var prompt_label: Label = null
var help_button: Button = null
var help_button_connected: bool = false
var help_label: Label = null
var yaw_left_button: Button = null
var yaw_left_connected: bool = false
var yaw_right_button: Button = null
var yaw_right_connected: bool = false
var zoom_in_button: Button = null
var zoom_in_connected: bool = false
var zoom_out_button: Button = null
var zoom_out_connected: bool = false
# Slice 11: bell quest + reward + tracker + camera reset.
var bell_label_timer: float = 0.0
# Slice 12: market + well. Fruit/water are bought/drawn with on-screen
# buttons only (touch-first; no keyboard path exists for them).
var draw_timer: float = 0.0
var fruit_button: Button = null
var fruit_button_connected: bool = false
var water_button: Button = null
var water_button_connected: bool = false
var fruit_water_label: Label = null
# Slice 13: gate + banana grove. BananaButton picks a bunch from the
# grove; bunches regrow 20 s after the last one is picked. Lights
# toggle the car/motorcycle headlight meshes (touch-first).
var banana_regrow_timer: float = 0.0
var banana_button: Button = null
var banana_button_connected: bool = false
var lights_button: Button = null
var lights_button_connected: bool = false
var lights_on: bool = true
var quest_tracker_label: Label = null
var camera_reset_button: Button = null
var camera_reset_connected: bool = false
# Slice 28: world-map button (touch-first; lives in the real scene).
var map_button: Button = null
# Slice 54 sightseeing: runtime HUD (created in _ready, like
# world_map.gd _build_ui — no scene edit, so main.tscn load_steps
# is untouched). Button toggles start/cancel/restart; label shows
# the tour status line. Both are stored directly, not via _n(),
# because they do not exist in the scene file.
var sightseeing_button: Button = null
var sightseeing_button_connected: bool = false
var sightseeing_label: Label = null
## Slice 60 owned-vehicle garage: the name of the last vehicle the
## player drove (one of the 14 _try_enter_vehicle names, "" = none
## yet). Persisted under the "garage" save key; a pre-60 save loads
## as "" (no recall until the player drives something). The recall
## button only MOVES that vehicle near the player — it never
## auto-enters it, so the existing Vehicle-button flow still owns
## entering, and a recalled aircraft/boat keeps its own height.
var garage_vehicle_name: String = ""
var garage_notice_text: String = ""
var garage_notice_timer: float = 0.0
var garage_button: Button = null
# Slice 61 addendum: More-gate for secondary HUD buttons (Map, Camera
# reset, Garage, Mute, Photo, Rain). False = only the PUBG cluster
# + joystick + More button show; true = the secondary stack shows.
var hud_more_open: bool = false
var garage_label: Label = null
var district_label: Label = null
## Slice 64 East Fields side quests: runtime touch button +
## progress label, same pattern as the Slice 54 sightseeing HUD
## (created at runtime because they do not exist in the scene
## file). The button re-points the shared Slice 28/34 waypoint
## guidance at the next unvisited East Fields stop (or clears it
## when all four are done); the label always shows live progress.
var eastfields_button: Button = null
var eastfields_label: Label = null
var map_button_connected: bool = false
# Slice 16: parachute + festival. The parachute deploys itself on
# a mid-air vehicle exit and stows itself on landing (no button
# needed); drum / lantern / snack buttons are touch-first like
# every other interaction button.
var parachuting: bool = false
var parachute_label: Label = null
var drum_button: Button = null
var drum_button_connected: bool = false
var lantern_button: Button = null
var lantern_button_connected: bool = false
var snack_button: Button = null
var snack_button_connected: bool = false
var drum_timer: float = 0.0
# Slice 17: fishing / donating / milking / watering / feeding, horn,
# bell, photo, rain, football, seventh reward. All buttons touch-first;
# the chime is generated in code (AudioStreamWAV sine) and actually
# played on quest advance — no dormant audio manager.
var crop_growth: int = 0
var ball_vel: Vector2 = Vector2.ZERO
var rain_on: bool = false
var chime_player: AudioStreamPlayer = null
var last_chime_stage: int = 0
var fish_button: Button = null
var fish_button_connected: bool = false
var donate_button: Button = null
var donate_button_connected: bool = false
var milk_button: Button = null
var milk_button_connected: bool = false
var water17_button: Button = null
var water17_button_connected: bool = false
var feed_button: Button = null
var feed_button_connected: bool = false
var horn_button: Button = null
var horn_button_connected: bool = false
var bell17_button: Button = null
var bell17_button_connected: bool = false
var photo_button: Button = null
var photo_button_connected: bool = false
var rain_button: Button = null
var rain_button_connected: bool = false
# Slice 14: hinthar prayer. The Pray button lives in the real scene
# (JoystickLayer/PrayButton); the blessing label shows 4 s.
var pray_button: Button = null
var pray_button_connected: bool = false
var blessing_timer: float = 0.0
# Slice 15: tea shop + school come alive, bicycle, 2 more villagers.
var tea_button: Button = null
var tea_button_connected: bool = false
var book_button: Button = null
var book_button_connected: bool = false

# Slice 18: elephant + offering / rice / rest / feed quests, mute,
# trumpet, eighth reward. All buttons touch-first; no keyboard path
# exists for any of them (the mute button is a setting, visible
# on foot and while driving).
var rice_growth: int = 0
var sound_on: bool = true
var offer_button: Button = null
var offer_button_connected: bool = false
var plant_button: Button = null
var plant_button_connected: bool = false
var rest_button: Button = null
var rest_button_connected: bool = false
var mute_button: Button = null
var mute_button_connected: bool = false
var trumpet_button: Button = null
var trumpet_button_connected: bool = false
var feed18_button: Button = null
var feed18_button_connected: bool = false

# Slice 19: horse + gold / lesson / horse-feed quests, ninth reward.
# All buttons touch-first; no keyboard path exists for any of them
# (the whistle shows only while driving the horse, like the Slice 18
# trumpet shows only while driving the elephant).
var gold_button: Button = null
var gold_button_connected: bool = false
var lesson_button: Button = null
var lesson_button_connected: bool = false
var feed_horse_button: Button = null
var feed_horse_button_connected: bool = false
var whistle_button: Button = null
var whistle_button_connected: bool = false

# Slice 20: night market + guest house + second boat/horse, tenth reward.
# All buttons touch-first; no keyboard path exists for any of them.
var sleep_timer: float = 0.0
var noodle_button: Button = null
var noodle_button_connected: bool = false
var drink_button: Button = null
var drink_button_connected: bool = false
var sleep_button: Button = null
var sleep_button_connected: bool = false
var guestbook_button: Button = null
var guestbook_button_connected: bool = false

# Slice 21: main menu + pause + save foundation. SaveManager is an
# autoload; every access goes through _sm() so a missing manager
# degrades to no-save instead of a crash. Talked villagers are saved
# by node name (instance ids change every run); growth scales and the
# talked-name mapping apply on the first physics frame, when every
# scene node is in the tree (player _ready runs before later siblings
# like the villagers enter).
var pause_button: Button = null
var pause_button_connected: bool = false
var pause_panel: Panel = null
var resume_button: Button = null
var resume_button_connected: bool = false
var save_button21: Button = null
var save_button21_connected: bool = false
var pause_settings_button: Button = null
var pause_settings_button_connected: bool = false
var quit_button: Button = null
var quit_button_connected: bool = false
var save_status_label: Label = null
var pause_settings_panel: Node = null
var pending_talked_names: Array = []
var pending_growth_applied: bool = false
var vehicle_paints_applied: bool = false
var last_saved_stage: int = -1

func _ready() -> void:
	_apply_pending_load()
	_apply_outfit()
	_apply_hud_scale()
	_create_sightseeing_hud()
	_create_eastfields_hud()
	_apply_hud_scale()
	# Slice 60 HUD polish + garage/district HUD nodes (runtime-only,
	# see hud_polish60.gd). Runs here so the layer exists; hud-scale
	# uses Control.scale, independent of the polish anchor changes.
	var _layer60 := get_node_or_null("../JoystickLayer") as CanvasLayer
	if _layer60 != null:
		HudPolish60Script.polish(_layer60, self)
		HudFix61bScript.dress(_layer60, self)
	apply_graphics_quality()
	_configure_map_bounds()
	# Slice 53 graphics: village dressing (walls/windows/doors for
	# the floating house slabs, tree variety, ground/path textures).
	# Runs at spawn, before the first frame, so nothing pops in.
	# The whole subtree exists by now (scene instantiation parents
	# every node before any _ready fires), even though later
	# siblings have not had _ready yet. Loaded by preload, not
	# class_name: a new class_name needs a regenerated .godot
	# global-class cache, and a stale cache breaks this script's
	# parse in a fresh clone.
	DressingScript.dress(get_parent())
	# Slice 56 visual city overhaul (sky, water, textured
	# buildings, trees, roads, streetlights, night park).
	# Runs after Slice 53 dressing so it textures the walls
	# Slice 53 added. Runtime-only: no scene file is touched.
	City56Script.dress(get_parent())
	# Slice 57 river + pagoda dressing (long wooden bridge,
	# waterside, pagoda gold trim, night-gated lanterns).
	# Runs after Slice 56; runtime-only, no scene touched.
	River57Script.dress(get_parent())
	# Slice 58 character + nature + building + ground set (owner
	# 20:44 ask: 3D-rendered characters in the game). Runs last;
	# runtime-only, no scene touched.
	Dress58Script.dress(get_parent())
	# Slice 59 Mindon district + outskirts + vehicle dressing.
	# Runs after Slice 58; runtime-only, no scene touched.
	Dress59Script.dress(get_parent())
	# Slice 62 big chill world (east expansion + living nature +
	# seasons + FPP/cart-top views). Runs after Slice 59; runtime-only.
	Chill62Script.dress(get_parent())
	# Slice 64 East Fields living district (quest markers, farm
	# fields, fences, scenery carts/animals, lane trees/flowers).
	# Runs after Slice 62; runtime-only, no scene touched.
	EastFields64Script.dress(get_parent())
	# Slice 69 Burmese 3D signboards (runtime-only, no scene
	# touched): physical boards on posts at real landmarks, with
	# a real Myanmar font (Noto Sans Myanmar) — NOT the default
	# font, which contains no Myanmar glyphs (proven live in the
	# Slice 69 review of opponent slices 209/210/212/213).
	Signboards69Script.dress(get_parent())
	# Slice 65 driving feel (runtime-only, no scene touched):
	# EngineAudio65 rides on the player (it reads driving_vehicle
	# from its parent every tick); WaterFlow65 rides on the world
	# (it finds EastDistrict62 there). Both deferred, same reason
	# as the Slice 62 district adds: _ready runs while Main is
	# still setting up children. Idempotent: re-running _ready
	# (scene reload) finds the existing nodes and skips creating.
	if get_node_or_null("EngineAudio65Node") == null:
		var _eng65 := Node.new()
		_eng65.name = "EngineAudio65Node"
		_eng65.set_script(load("res://engine_audio65.gd"))
		call_deferred("add_child", _eng65)
	var _world65 := get_parent()
	if _world65 != null and _world65.get_node_or_null("WaterFlow65") == null:
		var _flow65 := Node.new()
		_flow65.name = "WaterFlow65"
		_flow65.set_script(load("res://water_flow65.gd"))
		_world65.call_deferred("add_child", _flow65)
	# Slice 66 material realism pass (runtime-only, no scene
	# touched): roughness/metallic variation + village TreeTop
	# sway + vehicle gloss + rainy wet road. Added deferred
	# like the Slice 65 nodes; it captures at frame >= 8, after
	# all deferred dressing and the Slice 61 style pass.
	var _world66 := get_parent()
	if _world66 != null and _world66.get_node_or_null("MaterialRealism66") == null:
		var _real66 := Node3D.new()
		_real66.name = "MaterialRealism66"
		_real66.set_script(load("res://material_realism66.gd"))
		_world66.call_deferred("add_child", _real66)
	# Slice 70 graphics realism, part 1 (owner 06:32: people and
	# houses must stop looking like wobbly dolls — no new feature
	# in this slice): pitched roof caps, stilt rails/bracing,
	# head/neck/hands reshaping, procedural wall/roof/window/door/
	# road textures, ground tiling, sun shadow bias. Runtime-only,
	# no scene touched. Captures once at its frame >= 12, after
	# all deferred dressing and the Slice 61 style pass, then
	# stops processing (zero per-frame cost).
	var _world70 := get_parent()
	if _world70 != null and _world70.get_node_or_null("Realism70") == null:
		var _real70 := Node3D.new()
		_real70.name = "Realism70"
		_real70.set_script(load("res://realism70.gd"))
		_world70.call_deferred("add_child", _real70)
	# Slice 71 graphics realism, part 2 (owner 06:32 order, still
	# binding: graphics first, no new feature): layered tree
	# canopies + trunk bark, palm frond rings, vehicle hubs /
	# windows / lights / bumpers / real motorcycle + cart wheels,
	# river + pond ripple planes, pagoda tiered eaves, bell
	# pavilion roof. Runtime-only, no scene touched. Captures
	# once at its frame >= 16 (after Slice 70's frame-12 capture),
	# then keeps processing only to scroll the ripple planes.
	var _world71 := get_parent()
	if _world71 != null and _world71.get_node_or_null("Realism71") == null:
		var _real71 := Node3D.new()
		_real71.name = "Realism71"
		_real71.set_script(load("res://realism71.gd"))
		_world71.call_deferred("add_child", _real71)
	# Slice 72 graphics realism, part 3 (owner 06:32 order, still
	# binding: graphics first, no new feature): animal detail
	# (cow head/ears/horns/tail/hooves, horse ears/saddle/stirrups/
	# hooves, elephant howdah/toenails/tail, scenery cows/chickens),
	# buildings round 2 (stall crates/fruit, tea-shop benches/jars,
	# school windows/door/steps, night-market trays, guest-house
	# table/pillow, hospital canopy/steps/cross), road curbs +
	# rain-only puddles + clouds + horizon hills. Runtime-only,
	# no scene touched. Captures once at its frame >= 20 (after
	# Slice 71's frame-16 capture), then keeps processing only
	# for the rainy-season puddle toggle.
	var _world72 := get_parent()
	if _world72 != null and _world72.get_node_or_null("Realism72") == null:
		var _real72 := Node3D.new()
		_real72.name = "Realism72"
		_real72.set_script(load("res://realism72.gd"))
		_world72.call_deferred("add_child", _real72)
	# Slice 73 graphics realism part 4 (owner 06:32 order: clothing
	# + faces + interiors glimpse + night lights, NO new feature).
	# Same deferred pattern; captures at frame >= 26, after 72.
	var _world73 := get_parent()
	if _world73 != null and _world73.get_node_or_null("Realism73") == null:
		var _real73 := Node3D.new()
		_real73.name = "Realism73"
		_real73.set_script(load("res://realism73.gd"))
		_world73.call_deferred("add_child", _real73)
	# Slice 74 BUS SIMULATION (owner redirection 2026-10-23
	# 11:31 + choice 11:32: BUS + STOPS + PASSENGERS): long
	# scenic route x 445..2445 + drivable bus + 4 stops +
	# waiting passengers + door/boarding controller + HUD.
	# Runs after Slice 73; runtime-only except the ground-plane
	# resize + bounds in main.tscn (same class of change as
	# Slice 62). The bus node itself is added deferred by
	# dress(), like every deferred district node above.
	BusSim74Script.dress(get_parent())
	# Slice 75 BUS SIMULATION part 2 (route system +
	# destinations + curved sections + bus polish): runs
	# after Slice 74, same deferred pattern — its node
	# queues behind the bus, so bus polish finds the bus.
	BusRoute75Script.dress(get_parent())
	# Slice 76 BUS SIMULATION part 3 (long-route traffic +
	# junction full stops + night/rain bus operation +
	# passenger feedback): runs after Slice 75, same
	# deferred pattern — its node queues behind the bus
	# and the Slice 74 controller it reads totals from.
	BusSim76Script.dress(get_parent())
	# Slice 77 BUS SIMULATION part 4 (timetable + stop
	# upgrades + night stop lamps + rain braking): runs
	# after Slice 76, same deferred pattern — its node
	# queues behind the bus, the Slice 74 controller it
	# reads route state from, and the Slice 74 stops it
	# upgrades.
	BusSim77Script.dress(get_parent())
	# Slice 61 owner-ordered GRAPHICS-ONLY style pass (master-prompt
	# look only: vivid warm palette, soft shading — no positions,
	# no structure, no code from that document). Recolours existing
	# models only; runtime-only, no scene touched. DEFERRED on
	# purpose: Dress58Ground, District59 groups and City56 blocks
	# are added via call_deferred from earlier dressing, so a direct
	# call here would run before those groups exist in the tree
	# (proven by the Slice 61 sim: deferred dirt/trees kept their
	# old colours). This call is queued AFTER those adds, so it
	# runs after they land.
	call_deferred("_apply_style61")


## Slice 61: deferred style pass (see _ready note above).
func _apply_style61() -> void:
	Style61Script.dress(get_parent())

## Slice 61 addendum: More toggle (see hud_fix61b.gd). Visibility of
## the six secondary buttons is re-applied by the per-frame button
## updates, so this only flips the flag; the next frame applies it.
func _on_more_toggle() -> void:
	hud_more_open = not hud_more_open


## Slice 49: the shared map transform reads the live ground plane
## once at spawn (GroundMesh PlaneMesh 320x220 at (90, 0, 0) in
## main.tscn), so the minimap, the world map, and the waypoint all
## derive their bounds from the same scene source. Falls back to
## the same rect if the node is ever absent (MapTransform keeps its
## fallback bounds in that case); the world map re-configures on
## open as a second guarantee.
func _configure_map_bounds() -> void:
	var ground := get_node_or_null("../GroundMesh") as Node3D
	if ground != null:
		MapTransform.configure_from_ground(ground)


## Slice 68 graphics tiers: replaces the Slice 40 High/Low toggle
## (0 = High, 1 = Low) with four tiers, all LIVE (no restart, no
## world reload), using only levers that actually exist in this
## project — there is no WorldEnvironment, so no glow/bloom lever
## is claimed. Tier table (all five read back in the SIM68 sim):
## - Low (0): sun shadows OFF, render scale 0.75, MSAA off,
##   camera far 500 m (shorter draw distance — far corners clip
##   from the opposite corner, a real tradeoff), rain 150 drops.
## - Balanced (1): shadows ON, scale 0.90, MSAA 2X, far 1000 m,
##   rain 300 drops.
## - High (2, default = pre-68 look): shadows ON, scale 1.0,
##   MSAA 2X, far 2000 m, rain 400 drops.
## - Ultra (3): shadows ON, scale 1.0, MSAA 4X, far 4000 m
##   (the Camera3D default), rain 400 drops.
## Old files without graphics_tier map from graphics_quality
## (0 -> High, 1 -> Low), so a pre-68 Low user stays Low.
## Night floor 0.35 (Slice 61), season tints (Slice 62) and
## material realism (Slice 66) are untouched: this function
## never writes sun colour/energy or any material albedo.
## Called at world spawn and again from the Settings panel
## whenever the tier changes in the pause menu, so a pause-menu
## change takes effect the moment play resumes.
func apply_graphics_quality() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	var tier := 2
	if sm != null:
		if sm.get("graphics_tier") != null:
			tier = clampi(int(sm.get("graphics_tier")), 0, 3)
		else:
			tier = 2 if int(sm.get("graphics_quality")) == 0 else 0
	var scales := [0.75, 0.9, 1.0, 1.0]
	var msaas := [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_2X, Viewport.MSAA_4X]
	var fars := [500.0, 1000.0, 2000.0, 4000.0]
	var rain_amounts := [150, 300, 400, 400]
	var sun = get_parent().get_node_or_null("DayNight/SunLight") as DirectionalLight3D
	if sun != null:
		sun.shadow_enabled = tier != 0
	var vp = get_viewport()
	if vp != null:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = scales[tier]
		vp.msaa_3d = msaas[tier]
	var cam = get_node_or_null("../FollowCamera") as Camera3D
	if cam != null:
		cam.far = fars[tier]
	var rain = get_node_or_null("../Rain17") as GPUParticles3D
	if rain != null:
		rain.amount = rain_amounts[tier]
	var mm = _mm()
	if mm != null:
		last_saved_stage = mm.stage

func _physics_process(delta: float) -> void:
	_villagers_cache_age += delta
	if exit_blocked_timer > 0.0:
		exit_blocked_timer -= delta
	_apply_deferred_load()
	if not vehicle_paints_applied:
		_apply_vehicle_paints()
	_update_pause_ui()
	_autosave_on_stage_change()
	_update_clock_label()
	_update_day_label()
	_update_minimap()
	_update_compass()
	_update_waypoint_guide()
	_update_sightseeing()
	_update_district60()
	_update_eastfields64()
	_update_garage_notice(delta)
	_update_stamina(delta)
	_update_prompt_label()
	_update_fruit_water_label()
	_update_draw_animation(delta)
	_update_banana_regrow(delta)
	_update_banana_button()
	_update_pray_button()
	_update_tea_book_buttons()
	_update_festival_buttons()
	_update_blessing(delta)
	_update_lights_button()
	_update_slice17_buttons()
	_update_slice18_buttons()
	_update_slice19_buttons()
	_update_slice20_buttons()
	_update_football(delta)
	if driving:
		velocity = Vector3.ZERO
		move_and_slide()
		# Slice 38: vehicles are clamped to the playable area too.
		# The driven vehicle moves in its own script; this corrects
		# any overshoot each frame so driving past the edge stops
		# at the edge instead of leaving the ground plane.
		if driving_vehicle != null:
			_show_edge_notice(_clamp_node_to_bounds(driving_vehicle))
		if talk_button != null:
			talk_button.visible = false
		_update_market_buttons()
		# Driving: only the vehicle Exit button stays on screen.
		_update_action_buttons()
		_update_speed_label()
		return
	if not is_on_floor():
		velocity.y -= 20.0 * delta
		# Slice 16 parachute: gentle descent while the canopy is out.
		if parachuting:
			velocity.y = maxf(velocity.y, -3.0)
	else:
		velocity.y = 0.0
		# Slice 16: touching down stows the canopy (and can finish
		# the parachute quest stage).
		if parachuting:
			_stow_parachute()
		if Input.is_physical_key_pressed(KEY_J) or jump_requested:
			velocity.y = jump_velocity
		jump_requested = false
	var ix := Input.get_axis("ui_left", "ui_right")
	var iz := Input.get_axis("ui_up", "ui_down")
	if touch_vector != Vector2.ZERO:
		ix = touch_vector.x
		iz = touch_vector.y
	# Slice 10 analog walk speed: a half-pushed joystick walks
	# slower than a full push (keyboard input stays full speed).
	# Slice 10 stamina: sprinting is blocked once stamina hits 0.
	var raw := Vector3(ix, 0.0, iz)
	if raw.length() > 1.0:
		raw = raw.normalized()
	var dir := Vector3.ZERO
	if raw != Vector3.ZERO:
		# Slice 53: camera-relative movement. Joystick-up is the
		# direction the camera looks, not world -Z: after any orbit
		# the old world-axis mapping read as sideways/backwards on
		# screen, which is part of "cannot move forward". The camera
		# sits at player + dir_h * dist with
		# dir_h = (sin(orbit), 0, cos(orbit)), so view-forward is
		# (-sin(orbit), 0, -cos(orbit)) and view-right is
		# (cos(orbit), 0, -sin(orbit)). Falls back to the old
		# world-axis mapping if no camera is found.
		var cam := get_node_or_null("../FollowCamera")
		if cam != null and cam.get("orbit_angle") != null:
			var o := float(cam.get("orbit_angle"))
			var fwd := Vector3(-sin(o), 0.0, -cos(o))
			var rgt := Vector3(cos(o), 0.0, -sin(o))
			dir = (rgt * raw.x + fwd * (-raw.z)).normalized()
		else:
			dir = raw.normalized()
	var speed := walk_speed
	if touch_vector != Vector2.ZERO:
		speed *= 0.4 + 0.6 * clampf(raw.length(), 0.0, 1.0)
	var sprinting := (Input.is_physical_key_pressed(KEY_SHIFT) or touch_sprint) and stamina > 0.0
	if sprinting:
		speed *= sprint_multiplier
	if dir != Vector3.ZERO:
		rotation.y = atan2(dir.x, dir.z)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	# Slice 38: on foot, the player stops at the world edge, and
	# every freely-stood ground position becomes the recovery point.
	# "Free" is verified with the player's own capsule shape (the
	# slide-count heuristic was wrong: a standing player rests in
	# contact with the ground, so slide count is 1 even when free).
	_show_edge_notice(_clamp_node_to_bounds(self))
	if is_on_floor() and _capsule_spot_is_free(global_position):
		last_free_pos = global_position
	_update_talk_button()
	_update_market_buttons()
	_update_action_buttons()
	_update_speed_label()
	# Slice 13 quest stage 6: walk through the village gate arch.
	# The arch is two posts + a beam (no blocking collision), so a
	# player can actually pass under it — unlike a solid-wall gate.
	var beam := _n("../GateBeam12") as Node3D
	if beam != null:
		var dx := global_position.x - beam.global_position.x
		var dz := global_position.z - beam.global_position.z
		if dx * dx + dz * dz < 4.0:
			if _mm().advance("pass_gate")["advanced"]:
				_update_quest_label()
	# Slice 14 quest stage 8: cross the bamboo footbridge over the
	# river. The bridge midpoint is its root node; horizontal
	# distance < 2.5 m counts, so deck height never blocks it.
	var br := _n("../BambooBridge14") as Node3D
	if br != null:
		var bdx := global_position.x - br.global_position.x
		var bdz := global_position.z - br.global_position.z
		if bdx * bdx + bdz * bdz < 6.25:
			if _mm().advance("cross_bridge")["advanced"]:
				_update_quest_label()
	# Slice 19 quest stage 30: walk within 5 m of the lakeside hut.
	var hut := _n("../LakesideHut19") as Node3D
	if hut != null and global_position.distance_to(hut.global_position) < 5.0:
		var res = _mm().advance("visit_hut")
		if res["reward"] != "":
			_apply_reward(res["reward"])
		if res["advanced"]:
			_update_quest_label()
	# Slice 10 quest stage 1: walk within 8 m of the pagoda.
	var pag := _n("../Pagoda")
	if pag != null and global_position.distance_to(pag.global_position) < 8.0:
		if _mm().advance("visit_pagoda")["advanced"]:
			_update_quest_label()
	# Slice 11 quest stage 3: walk within 3.5 m of the monastery
	# bell to ring it. The bell label shows on any ring (with a 4 s
	# cooldown); the quest advances only once stage 2 (ride) is done.
	var bell := _n("../MonasteryBell") as Node3D
	if bell != null and global_position.distance_to(bell.global_position) < 3.5 and bell_label_timer <= 0.0:
		bell_label_timer = 4.0
		var bl := _n("../MonasteryBell/BellLabel") as Label3D
		if bl != null:
			bl.visible = true
		var res = _mm().advance("ring_bell")
		if res["reward"] != "":
			_apply_reward(res["reward"])
		if res["advanced"]:
			_update_quest_label()
	if bell_label_timer > 0.0:
		bell_label_timer -= delta
		if bell_label_timer <= 0.0:
			var bl2 := _n("../MonasteryBell/BellLabel") as Label3D
			if bl2 != null:
				bl2.visible = false
	if drum_timer > 0.0:
		drum_timer -= delta
		if drum_timer <= 0.0:
			var dl2 := _n("../FestivalDrum16/DrumLabel") as Label3D
			if dl2 != null:
				dl2.visible = false
	if sleep_timer > 0.0:
		sleep_timer -= delta
		if sleep_timer <= 0.0:
			var sl2 := _n("../GuestHouse20/SleepLabel20") as Label3D
			if sl2 != null:
				sl2.visible = false
	if Input.is_action_just_pressed("ui_accept"):
		_try_enter_vehicle()
	# E is a desktop-debug fallback ONLY — the primary path is the
	# on-screen Talk button / tapping the villager (see header).
	var e_now := Input.is_physical_key_pressed(KEY_E)
	if e_now and not e_was_pressed:
		_try_talk()
	e_was_pressed = e_now

## Shows the Talk button only when a villager is in talk range.
## The button lives in the real scene (JoystickLayer/TalkButton),
## not in a script nobody instantiates; it is found lazily because
## the player enters the tree before the CanvasLayer does.
func _update_talk_button() -> void:
	if talk_button == null:
		talk_button = get_node_or_null("../JoystickLayer/TalkButton") as Button
		if talk_button != null and not talk_button_connected:
			talk_button.pressed.connect(_try_talk)
			talk_button_connected = true
	if talk_button != null:
		# Slice 63: while the More stack is open, the right column
		# belongs to the stack — Talk sits on the stack's Photo /
		# Rain / View / Season rects, so it stays hidden until
		# More closes (the More button itself stays tappable).
		talk_button.visible = _nearest_villager() != null and not hud_more_open

## Slice 8: wires the on-screen Sprint / Jump / Vehicle buttons.
## They live in the real scene (JoystickLayer), found lazily like
## the Talk button, because the player enters the tree first.
## Sprint is hold-to-sprint (button_down/up); Jump sets a request
## consumed on the next ground frame; Vehicle enters the nearest
## vehicle within 4 m on foot, or exits the ridden one while driving.
func _update_action_buttons() -> void:
	if sprint_button == null:
		sprint_button = get_node_or_null("../JoystickLayer/SprintButton") as Button
		if sprint_button != null and not sprint_button_connected:
			sprint_button.button_down.connect(_on_sprint_down)
			sprint_button.button_up.connect(_on_sprint_up)
			sprint_button_connected = true
	if jump_button == null:
		jump_button = get_node_or_null("../JoystickLayer/JumpButton") as Button
		if jump_button != null and not jump_button_connected:
			jump_button.pressed.connect(_on_jump_pressed)
			jump_button_connected = true
	if vehicle_button == null:
		vehicle_button = get_node_or_null("../JoystickLayer/VehicleButton") as Button
		if vehicle_button != null and not vehicle_button_connected:
			vehicle_button.pressed.connect(_on_vehicle_button_pressed)
			vehicle_button_connected = true
	# Slice 9 throttle buttons: hold-to-climb / hold-to-descend for
	# aircraft (airplane throttle, helicopter lift). They live in
	# the real scene (JoystickLayer), found lazily like the rest.
	if throttle_up_button == null:
		throttle_up_button = get_node_or_null("../JoystickLayer/ThrottleUpButton") as Button
		if throttle_up_button != null and not throttle_up_connected:
			throttle_up_button.button_down.connect(_on_throttle_up_down)
			throttle_up_button.button_up.connect(_on_throttle_up_up)
			throttle_up_connected = true
	if throttle_down_button == null:
		throttle_down_button = get_node_or_null("../JoystickLayer/ThrottleDownButton") as Button
		if throttle_down_button != null and not throttle_down_connected:
			throttle_down_button.button_down.connect(_on_throttle_down_down)
			throttle_down_button.button_up.connect(_on_throttle_down_up)
			throttle_down_connected = true
	# Slice 10: yaw buttons (flying only), zoom buttons, help button.
	# All live in the real scene (JoystickLayer), wired lazily.
	if yaw_left_button == null:
		yaw_left_button = get_node_or_null("../JoystickLayer/YawLeftButton") as Button
		if yaw_left_button != null and not yaw_left_connected:
			yaw_left_button.button_down.connect(_on_yaw_left_down)
			yaw_left_button.button_up.connect(_on_yaw_left_up)
			yaw_left_connected = true
	if yaw_right_button == null:
		yaw_right_button = get_node_or_null("../JoystickLayer/YawRightButton") as Button
		if yaw_right_button != null and not yaw_right_connected:
			yaw_right_button.button_down.connect(_on_yaw_right_down)
			yaw_right_button.button_up.connect(_on_yaw_right_up)
			yaw_right_connected = true
	if zoom_in_button == null:
		zoom_in_button = get_node_or_null("../JoystickLayer/ZoomInButton") as Button
		if zoom_in_button != null and not zoom_in_connected:
			zoom_in_button.pressed.connect(_on_zoom_in)
			zoom_in_connected = true
	if zoom_out_button == null:
		zoom_out_button = get_node_or_null("../JoystickLayer/ZoomOutButton") as Button
		if zoom_out_button != null and not zoom_out_connected:
			zoom_out_button.pressed.connect(_on_zoom_out)
			zoom_out_connected = true
	if help_button == null:
		help_button = get_node_or_null("../JoystickLayer/HelpButton") as Button
		if help_button != null and not help_button_connected:
			help_button.pressed.connect(_on_help_pressed)
			help_button_connected = true
	# Slice 11 camera reset button: tap to restore default orbit
	# angle and zoom (touch-first; it lives in the real scene).
	if camera_reset_button == null:
		camera_reset_button = get_node_or_null("../JoystickLayer/CameraResetButton") as Button
		if camera_reset_button != null and not camera_reset_connected:
			camera_reset_button.pressed.connect(_on_camera_reset)
			camera_reset_connected = true
	if camera_reset_button != null:
		camera_reset_button.visible = hud_more_open
	# Slice 28 world-map button: tap to open the full-screen map.
	# Wired lazily like every other HUD button, so the button is
	# ACTUALLY CONNECTED (the opponent's slice-35 MapBtn never was).
	if map_button == null:
		map_button = get_node_or_null("../JoystickLayer/MapButton28") as Button
		if map_button != null and not map_button_connected:
			map_button.pressed.connect(_on_map_button_pressed)
			map_button_connected = true
	if map_button != null:
		map_button.visible = hud_more_open
	if help_label == null:
		help_label = get_node_or_null("../JoystickLayer/HelpLabel") as Label
	if driving:
		if sprint_button != null:
			sprint_button.visible = false
		if jump_button != null:
			jump_button.visible = false
		if vehicle_button != null:
			vehicle_button.visible = not hud_more_open
			_set_text(vehicle_button, "ဆင်းမည်")
		var flying := driving_vehicle != null and driving_vehicle.name in ["Airplane", "Helicopter"]
		if throttle_up_button != null:
			# Slice 63: ThrottleUp sits on the stack's Garage /
			# Mute / Photo rects, so it hides while More is open
			# (ThrottleDown is left of the stack and stays).
			throttle_up_button.visible = flying and not hud_more_open
		if throttle_down_button != null:
			throttle_down_button.visible = flying
		if yaw_left_button != null:
			yaw_left_button.visible = flying
		if yaw_right_button != null:
			yaw_right_button.visible = flying
		if zoom_in_button != null:
			zoom_in_button.visible = false
		if zoom_out_button != null:
			zoom_out_button.visible = false
		if help_button != null:
			help_button.visible = true
		return
	if sprint_button != null:
		sprint_button.visible = true
	if jump_button != null:
		jump_button.visible = true
	if throttle_up_button != null:
		throttle_up_button.visible = false
	if throttle_down_button != null:
		throttle_down_button.visible = false
	# Slice 9 orbit button: tap to rotate the camera around the
	# player/vehicle (touch orbit — Q/E remain a desktop fallback).
	if orbit_button == null:
		orbit_button = get_node_or_null("../JoystickLayer/OrbitButton") as Button
		if orbit_button != null and not orbit_button_connected:
			orbit_button.pressed.connect(_on_orbit_pressed)
			orbit_button_connected = true
	if orbit_button != null:
		orbit_button.visible = true
	if vehicle_button != null:
		var near := _nearest_vehicle()
		vehicle_button.visible = near != null and not hud_more_open
		if near != null:
			_set_text(vehicle_button, "စီးမည်")
	if yaw_left_button != null:
		yaw_left_button.visible = false
	if yaw_right_button != null:
		yaw_right_button.visible = false
	if zoom_in_button != null:
		zoom_in_button.visible = false
	if zoom_out_button != null:
		zoom_out_button.visible = false
	if help_button != null:
		help_button.visible = true

func _on_sprint_down() -> void:
	touch_sprint = true

func _on_sprint_up() -> void:
	touch_sprint = false

func _on_jump_pressed() -> void:
	if not driving:
		jump_requested = true

func _on_orbit_pressed() -> void:
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.orbit_angle += 0.6

## Slice 9 driving readout: vehicle name + speed, shown only
## while driving. Speed comes from the vehicle's own `speed`
## variable where it has one (car/cart/bike/heli/cow), else from
## its velocity (airplane). Names are shown in Burmese.
## Slice 10: speed is shown in km/h (units/s x 3.6, like a real
## speedometer), plus a SpeedBar showing the fraction of that
## vehicle's top speed.
func _update_speed_label() -> void:
	if speed_label == null:
		speed_label = get_node_or_null("../JoystickLayer/SpeedLabel") as Label
	if speed_bar == null:
		speed_bar = get_node_or_null("../JoystickLayer/SpeedBar") as ProgressBar
	if speed_label == null:
		return
	if not driving or driving_vehicle == null:
		_set_visible(speed_label, false)
		if speed_bar != null:
			_set_visible(speed_bar, false)
		return
	var names := {"Car": "ကား", "Cart": "လှည်း", "Motorcycle": "ဆိုင်ကယ်",
		"Airplane": "လေယာဉ်", "Cow": "နွား", "Helicopter": "ရဟတ်ယာဉ်", "Boat": "လှေ", "Bicycle": "စက်ဘီး", "TukTuk": "သုံးဘီး", "Elephant": "ဆင်", "Horse": "မြင်း", "Boat2": "လှေ", "Horse2": "မြင်း", "Bus": "ဘတ်စ်ကား"}
	var vmax := {"Car": 14.0, "Cart": 6.0, "Motorcycle": 18.0,
		"Airplane": 50.0, "Cow": 4.5, "Helicopter": 12.0, "Boat": 5.0, "Bicycle": 7.0, "TukTuk": 11.0, "Elephant": 6.0, "Horse": 9.0, "Boat2": 5.0, "Horse2": 9.0, "Bus": 16.0}
	var vname: String = str(names.get(driving_vehicle.name, driving_vehicle.name))
	var spd := 0.0
	if driving_vehicle.get("speed") != null:
		spd = absf(float(driving_vehicle.get("speed")))
	elif driving_vehicle.get("velocity") != null:
		spd = (driving_vehicle.get("velocity") as Vector3).length()
	_set_text(speed_label, vname + " — " + ("%d km/h" % int(spd * 3.6)))
	_set_visible(speed_label, true)
	if speed_bar != null:
		var top: float = float(vmax.get(driving_vehicle.name, 14.0))
		_set_bar_value(speed_bar, clampf(spd / top * 100.0, 0.0, 100.0))
		_set_visible(speed_bar, true)

## Slice 9 clock: in-game time from DayNight.time (120 s = 1 day).
## Guarded: an older scene without DayNight just shows no clock.
func _update_clock_label() -> void:
	if clock_label == null:
		clock_label = _n("../JoystickLayer/ClockLabel") as Label
	if clock_label == null:
		return
	var dn := _n("../DayNight")
	if dn == null or dn.get("time") == null or dn.get("day_length_seconds") == null:
		_set_visible(clock_label, false)
		return
	var day_len := float(dn.get("day_length_seconds"))
	if day_len <= 0.0:
		_set_visible(clock_label, false)
		return
	var frac := fmod(float(dn.get("time")) / day_len, 1.0)
	var total_min := int(frac * 24.0 * 60.0)
	_set_text(clock_label, "အချိန် %02d:%02d" % [total_min / 60, total_min % 60])
	_set_visible(clock_label, true)

func _on_throttle_up_down() -> void:
	touch_throttle_up = true

func _on_throttle_up_up() -> void:
	touch_throttle_up = false

func _on_throttle_down_down() -> void:
	touch_throttle_down = true

func _on_throttle_down_up() -> void:
	touch_throttle_down = false

## Slice 9 first quest: talk to every villager in the village.
## Called by npc.gd talk_to(), so BOTH the Talk button and the
## direct-tap path count — a tap-only conversation is not lost.
## The QuestLabel lives in the real scene (JoystickLayer) with its
## starting text set in main.tscn; this only rewrites it on progress.
func record_talk(villager: Node) -> void:
	var vid := villager.get_instance_id()
	if not talked_ids.has(vid):
		talked_ids.append(vid)
	_update_quest_label()

## Slice 10 quest chain: 0 talk to every villager, 1 visit the
## pagoda, 2 ride any vehicle, 3 all done. Stage 0 promotes itself
## here once the talk count is complete; stage 1 is promoted by the
## pagoda distance check in _physics_process, stage 2 by entering
## a vehicle in _try_enter_vehicle.
## Slice 27: quest label/tracker/chime now render MissionManager state.
## The texts live in autoload/mission_data.gd (copied byte-for-byte
## from this function); the talk-all promotion rule lives in the
## manager. Order preserved: label lookup, promotion, label text,
## tracker text, then the stage-change chime.
func _update_quest_label() -> void:
	if quest_label == null:
		quest_label = _n("../JoystickLayer/QuestLabel") as Label
	if quest_label == null:
		return
	var mm = _mm()
	if mm == null:
		return
	var villagers := _villagers()
	var total := villagers.size()
	mm.promote_talk_all(talked_ids.size(), total)
	_set_text(quest_label, mm.label_text(talked_ids.size(), total, mm.get_count("banana")))
	# Preserved old quirk: while stage 0 is incomplete the function
	# returns here, so the tracker keeps its scene text until stage 1.
	if mm.stage == 0:
		return
	if quest_tracker_label == null:
		quest_tracker_label = _n("../JoystickLayer/QuestTrackerLabel") as Label
	if quest_tracker_label != null:
		_set_text(quest_tracker_label, mm.tracker_text())
		_set_visible(quest_tracker_label, true)
	# Slice 17 quest chime: a short generated tone whenever the stage
	# actually advances (not on every label refresh).
	if mm.stage != last_chime_stage:
		last_chime_stage = mm.stage
		_play_tone(660.0, 0.25)

func _on_vehicle_button_pressed() -> void:
	if driving:
		if driving_vehicle != null and driving_vehicle.has_method("exit_vehicle"):
			driving_vehicle.call("exit_vehicle")
		return
	_try_enter_vehicle()

func _nearest_vehicle() -> Node:
	var best: Node = null
	var best_dist: float = 4.0
	for name in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Cow2", "Helicopter", "Boat", "Bicycle", "TukTuk", "Elephant", "Horse", "Boat2", "Horse2", "Bus"]:
		var v := _n("../" + name)
		if v != null:
			var d := global_position.distance_to(v.global_position)
			if d < best_dist:
				best_dist = d
				best = v
	return best

func _nearest_villager() -> Node:
	var best: Node = null
	var best_dist: float = 3.5
	for villager in _villagers():
		var d := global_position.distance_to(villager.global_position)
		if d < best_dist:
			best_dist = d
			best = villager
	return best

func _try_talk() -> void:
	var best := _nearest_villager()
	if best != null and best.has_method("talk_to"):
		best.call("talk_to", global_position)

func _try_enter_vehicle() -> void:
	# Nearest vehicle within 4 m wins (Slice 6 took the first name in
	# list order, which could pick a farther vehicle over a nearer one).
	var best: Node = null
	var best_dist: float = 4.0
	for name in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Cow2", "Helicopter", "Boat", "Bicycle", "TukTuk", "Elephant", "Horse", "Boat2", "Horse2", "Bus"]:
		var v := get_node_or_null("../" + name)
		if v != null:
			var d := global_position.distance_to(v.global_position)
			if d < best_dist:
				best_dist = d
				best = v
	if best != null:
		driving = true
		driving_vehicle = best
		visible = false
		# Slice 60 garage: remember the last vehicle driven and
		# persist it at once, so a quit right after entering still
		# keeps the garage (same save-on-action pattern as the
		# sightseeing button press).
		garage_vehicle_name = str(best.name)
		var _sm60 = _sm()
		if _sm60 != null:
			_sm60.call("save_game", collect_save_data())
		# Driver-body fix: while driving, the player body must not
		# block its own vehicle. Entering hid the body but left it
		# live at the entry spot, running zero-velocity
		# move_and_slide every physics frame — entering a vehicle
		# from directly ahead left that invisible body in the
		# vehicle's path and move_and_slide froze the vehicle
		# (Slice 40 sim: car at top speed 14, position frozen).
		# Entering from the side worked only because the body sat
		# beside the path. Clearing layer 1 (so no vehicle
		# move_and_slide collides with it) and mask 1 (so its own
		# zero-velocity slide touches nothing) makes the driver
		# truly absent while driving. Both are restored exactly
		# in leave_vehicle(), the single shared exit path every
		# rideable funnels through, so the restored body lands
		# on the Slice 38 probed-free exit spot.
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		# Slice 27: ride transitions now fire through the mission table.
		if _mm().advance("ride_any")["advanced"]:
			_update_quest_label()
		if best.name == "Bicycle" and _mm().advance("ride_bicycle")["advanced"]:
			_update_quest_label()
		if best.name == "TukTuk" and _mm().advance("ride_tuktuk")["advanced"]:
			_update_quest_label()
		if best.name == "Elephant" and _mm().advance("ride_elephant")["advanced"]:
			_update_quest_label()
		if best.name == "Horse" and _mm().advance("ride_horse")["advanced"]:
			_update_quest_label()
		if best.name == "Boat2" and _mm().advance("ride_boat2")["advanced"]:
			_update_quest_label()
		if best.name == "Horse2" and _mm().advance("ride_horse2")["advanced"]:
			_update_quest_label()
		best.start_driving(self)

func leave_vehicle() -> void:
	driving = false
	driving_vehicle = null
	visible = true
	# Driver-body fix, restore half: the body becomes a live
	# collider again the moment the player is on foot. This runs
	# after the vehicle exit path has already placed the player
	# on the Slice 38 probed-free spot, so the restored body
	# never lands inside a wall. The refused-exit path never
	# reaches here (it returns early with the blocked prompt),
	# so a refused exit correctly keeps the body non-colliding
	# while the player stays in the vehicle. Stuck recovery
	# also funnels through here before it moves the player to
	# the last free ground position, which was shape-probed free.
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	# Slice 16 parachute: leaving a vehicle high above the ground
	# opens the canopy automatically — this closes the standing
	# "no parachute" gap from Slice 3. Ground exits (y near 1)
	# never deploy.
	if global_position.y > 3.0:
		_deploy_parachute()

## Slice 38 solidity: world bounds. Clamps a node's X/Z to the
## playable ground-plane extent (0.5 m margin keeps the capsule
## centre on the plane). Returns true when it actually moved the
## node, so the caller can show the edge notice only while the
## player is pushing against the edge.
func _clamp_node_to_bounds(node: Node) -> bool:
	if not (node is Node3D):
		return false
	var n3: Node3D = node as Node3D
	var p: Vector3 = n3.global_position
	var cx: float = clampf(p.x, WORLD_MIN_X, WORLD_MAX_X)
	var cz: float = clampf(p.z, WORLD_MIN_Z, WORLD_MAX_Z)
	if cx == p.x and cz == p.z:
		return false
	n3.global_position = Vector3(cx, p.y, cz)
	return true

## Slice 38 solidity: per-frame vehicle clamp. The driven vehicle
## moves in its own script AFTER this script's _physics_process
## clamp, so it can overshoot the edge by one physics tick (0.23 m
## at top speed) before the next correction. Re-clamping here, in
## the idle frame after all physics ticks and before rendering,
## keeps the vehicle visibly at the edge instead of past it.
func _process(_delta: float) -> void:
	if driving and driving_vehicle != null:
		_clamp_node_to_bounds(driving_vehicle)

## Slice 38 solidity: free-spot probe. True when the player's own
## capsule (same radius/height as the real body) placed at the
## given position overlaps no layer-1 body except the ground. The
## 0.05 m lift matches the exit probe: resting contact with the
## ground or a bridge deck never counts as blocked, while any wall,
## house, pagoda base or other vehicle overlapping the capsule
## does. Touching a wall face exactly counts as blocked, which is
## conservative and safe: the recovery point stays clearly free.
func _capsule_spot_is_free(spot: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		return true
	if _probe_shape == null:
		_probe_shape = CapsuleShape3D.new()
		_probe_shape.radius = 0.4
		_probe_shape.height = 1.2
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _probe_shape
	params.collision_mask = 1
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.transform = Transform3D(Basis.IDENTITY, spot + Vector3(0.0, 0.05, 0.0))
	var hits: Array = space.intersect_shape(params, 8)
	for h in hits:
		var col = h.get("collider")
		if col == null or col == self or col.name == "GroundBody":
			continue
		return false
	return true

## Slice 38 solidity: edge notice. A small label under the waypoint
## guide strip; visible exactly while a clamp is active, so the
## failure mode reads "you are at the edge", never silent void.
func _show_edge_notice(show: bool) -> void:
	if edge_label == null:
		edge_label = get_node_or_null("../JoystickLayer/EdgeLabel38") as Label
	if edge_label == null:
		return
	edge_label.visible = show
	if show:
		edge_label.text = "⚠ အစွန်းရောက်နေပါပြီ — ဒီထက်ဆက်သွား၍ မရပါ"

## Slice 38 solidity: exit clearance. Probes candidate step-out
## spots around a vehicle with the player's own capsule shape and
## returns the first spot that overlaps no layer-1 body except the
## ground, the vehicle itself, and the player's own (hidden while
## driving) body. The probe capsule sits 0.05 m above the exact
## placement height so resting contact with the ground or a bridge
## deck never counts as blocked, while any wall, house, pagoda base
## or other vehicle overlapping the capsule does. Returns
## Vector3.INF when every candidate is blocked — the caller must
## then keep the player in the vehicle and say so, never silently
## teleport them into a wall. Candidate order preserves the old
## behaviour in open ground: the vehicle's existing step-out offset
## is tried first, so an open-ground exit lands exactly where it
## always did.
func find_free_exit_spot(vehicle: Node3D, preferred_offset: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		return vehicle.global_position + preferred_offset
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.2
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 1
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var offsets: Array = [preferred_offset,
		Vector3(-preferred_offset.x, preferred_offset.y, preferred_offset.z),
		Vector3(0.0, preferred_offset.y, 2.0),
		Vector3(0.0, preferred_offset.y, -2.0),
		Vector3(2.0, preferred_offset.y, 2.0),
		Vector3(2.0, preferred_offset.y, -2.0),
		Vector3(-2.0, preferred_offset.y, 2.0),
		Vector3(-2.0, preferred_offset.y, -2.0),
		Vector3(3.5, preferred_offset.y, 0.0),
		Vector3(-3.5, preferred_offset.y, 0.0),
		Vector3(0.0, preferred_offset.y, 3.5),
		Vector3(0.0, preferred_offset.y, -3.5)]
	for off in offsets:
		var spot: Vector3 = vehicle.global_position + off + Vector3(0.0, 0.05, 0.0)
		params.transform = Transform3D(Basis.IDENTITY, spot)
		var hits: Array = space.intersect_shape(params, 8)
		var blocked := false
		for h in hits:
			var col = h.get("collider")
			if col == null:
				continue
			if col == self:
				continue
			if col == vehicle:
				continue
			if col.name == "GroundBody":
				continue
			blocked = true
			break
		if not blocked:
			return vehicle.global_position + off
	return Vector3.INF

## Slice 38 solidity: refused-exit notice. Called by a vehicle exit
## path when find_free_exit_spot returns INF; the prompt label
## shows it for a few seconds (see _update_prompt_label).
func show_exit_blocked() -> void:
	exit_blocked_timer = 2.5

## Slice 38 solidity: stuck recovery (touch-first: the pause-menu
## "Stuck" button calls this; no keyboard key exists for it).
## Returns the player on foot to the last freely-stood ground
## position. If the player is driving, the vehicle is stopped and
## left where it is — the player is freed, the vehicle is not
## teleported. The confirmation lands in the pause-menu status
## label, which the player is already looking at.
func recover_from_stuck() -> void:
	if driving and driving_vehicle != null:
		var v: Node = driving_vehicle
		v.set("driver", null)
		if v.get("speed") != null:
			v.set("speed", 0.0)
		if v is CharacterBody3D:
			(v as CharacterBody3D).velocity = Vector3.ZERO
		var cam := get_node_or_null("../FollowCamera")
		if cam != null:
			cam.set("target", get_path())
		leave_vehicle()
	global_position = last_free_pos
	velocity = Vector3.ZERO
	if save_status_label == null:
		save_status_label = get_node_or_null("../JoystickLayer/PausePanel21/SaveStatusLabel21") as Label
	if save_status_label != null:
		save_status_label.text = "လွတ်မြောက်ပါပြီ ✓"

func _on_stuck_pressed() -> void:
	recover_from_stuck()

## Slice 16 parachute (TOUCH-FIRST — no button needed: it opens
## itself on a mid-air exit and stows itself on landing; the
## joystick steers the drift while it is out, like walking).
func _deploy_parachute() -> void:
	parachuting = true
	for nname in ["ParachuteCanopy", "ParachuteLineL", "ParachuteLineR"]:
		var n := get_node_or_null(nname) as Node3D
		if n != null:
			n.visible = true
	if parachute_label == null:
		parachute_label = get_node_or_null("../JoystickLayer/ParachuteLabel") as Label
	if parachute_label != null:
		parachute_label.visible = true

func _stow_parachute() -> void:
	parachuting = false
	for nname in ["ParachuteCanopy", "ParachuteLineL", "ParachuteLineR"]:
		var n := get_node_or_null(nname) as Node3D
		if n != null:
			n.visible = false
	if parachute_label != null:
		parachute_label.visible = false
	if _mm().advance("land_parachute")["advanced"]:
		_update_quest_label()

## Slice 10 stamina: sprinting drains it, resting restores it, and
## sprint is blocked at 0. The bar lives in the real scene.
func _update_stamina(delta: float) -> void:
	if stamina_bar == null:
		stamina_bar = get_node_or_null("../JoystickLayer/StaminaBar") as ProgressBar
	var sprinting := (Input.is_physical_key_pressed(KEY_SHIFT) or touch_sprint) and not driving
	# Slice 11 quest reward: finishing the chain blesses stamina —
	# it drains half as fast and restores twice as fast.
	var drain := 25.0
	var regen := 15.0
	var mm = _mm()
	if mm != null and mm.stamina_blessed():
		drain = 12.5
		regen = 30.0
	if sprinting and velocity.length() > 0.5:
		stamina = maxf(stamina - drain * delta, 0.0)
	else:
		stamina = minf(stamina + regen * delta, 100.0)
	if stamina_bar != null:
		_set_bar_value(stamina_bar, stamina)
		_set_visible(stamina_bar, not driving)

## Slice 10 day counter from DayNight time (120 s = 1 day).
func _update_day_label() -> void:
	if day_label == null:
		day_label = _n("../JoystickLayer/DayLabel") as Label
	if day_label == null:
		return
	var dn := _n("../DayNight")
	if dn == null or dn.get("time") == null or dn.get("day_length_seconds") == null:
		_set_visible(day_label, false)
		return
	var day_len := float(dn.get("day_length_seconds"))
	if day_len <= 0.0:
		_set_visible(day_label, false)
		return
	var day := int(float(dn.get("time")) / day_len) + 1
	_set_text(day_label, "နေ့ %d" % day)
	_set_visible(day_label, true)

## Slice 10 compass: heading from the facing rotation. Facing -Z
## is north (rotation.y = 180 deg there), so heading = 180 - rot.
func _cardinal(deg: float) -> String:
	if deg >= 337.5 or deg < 22.5:
		return "N"
	elif deg < 67.5:
		return "NE"
	elif deg < 112.5:
		return "E"
	elif deg < 157.5:
		return "SE"
	elif deg < 202.5:
		return "S"
	elif deg < 247.5:
		return "SW"
	elif deg < 292.5:
		return "W"
	else:
		return "NW"

func _update_compass() -> void:
	if compass_label == null:
		compass_label = get_node_or_null("../JoystickLayer/CompassLabel") as Label
	if compass_label == null:
		return
	var facing: Node3D = self
	if driving and driving_vehicle != null:
		facing = driving_vehicle
	var deg := wrapf(180.0 - rad_to_deg(facing.rotation.y), 0.0, 360.0)
	_set_text(compass_label, "%d° %s" % [int(deg), _cardinal(deg)])
	_set_visible(compass_label, true)

## Slice 34: waypoint guidance HUD. The Slice 28 map owns the
## waypoint (WorldMapPanel has_waypoint/waypoint, x/z metres); this
## only READS it, exactly like the minimap mirror. The panel shows
## ONLY while a waypoint is set: an 8-way arrow pointing toward the
## waypoint relative to the CAMERA's view direction (so turning the
## camera swings the arrow), plus a live distance in metres. On
## foot the camera looks from the player; while driving it looks
## from the vehicle, so the reference point follows the driving
## camera target too — the arrow follows the driving camera's
## facing, never the player's body facing. Guidance ONLY: no
## routing, no pathfinding, no auto-driving, no road following —
## the panel itself says so (GuideNote), and so does the README.
## Pure math lives in _guide_arrow_for so it is testable without a
## scene: rel_deg is 0 ahead, -90 right, +90 left, +/-180 behind.
func _guide_arrow_for(rel_deg: float) -> String:
	var d := wrapf(rel_deg, -180.0, 180.0)
	if d >= -22.5 and d < 22.5:
		return "↑"
	if d >= -67.5 and d < -22.5:
		return "↗"
	if d >= -112.5 and d < -67.5:
		return "→"
	if d >= -157.5 and d < -112.5:
		return "↘"
	if d >= 157.5 or d < -157.5:
		return "↓"
	if d >= 112.5 and d < 157.5:
		return "↙"
	if d >= 67.5 and d < 112.5:
		return "←"
	return "↖"

func _guide_camera_forward() -> Vector2:
	var cam := _n("../FollowCamera") as Camera3D
	var ref: Node3D = self
	if driving and driving_vehicle != null:
		ref = driving_vehicle as Node3D
	if cam != null:
		var f := Vector2(ref.global_position.x - cam.global_position.x, ref.global_position.z - cam.global_position.z)
		if f.length() > 0.001:
			return f.normalized()
	var ry := ref.rotation.y
	return Vector2(-sin(ry), -cos(ry))

func _update_waypoint_guide() -> void:
	if guide_panel == null:
		guide_panel = _n("../JoystickLayer/GuidePanel34") as Control
		guide_arrow = _n("../JoystickLayer/GuidePanel34/GuideArrow") as Label
		guide_dist = _n("../JoystickLayer/GuidePanel34/GuideDist") as Label
	if guide_panel == null:
		return
	var wm := _n("../JoystickLayer/WorldMapPanel")
	if wm == null or not bool(wm.get("has_waypoint")):
		_set_visible(guide_panel, false)
		return
	var wp: Vector2 = wm.get("waypoint")
	var from: Vector3 = global_position
	if driving and driving_vehicle != null:
		from = (driving_vehicle as Node3D).global_position
	var dx := wp.x - from.x
	var dz := wp.y - from.z
	var dist := sqrt(dx * dx + dz * dz)
	_set_visible(guide_panel, true)
	if dist <= GUIDE_ARRIVED_RADIUS:
		if guide_arrow != null:
			_set_visible(guide_arrow, false)
		if guide_dist != null:
			_set_text(guide_dist, "✓ ရောက်ပါပြီ")
		return
	if guide_arrow != null:
		_set_visible(guide_arrow, true)
		var fwd := _guide_camera_forward()
		var to := Vector2(dx, dz).normalized()
		var rel := rad_to_deg(atan2(fwd.y * to.x - fwd.x * to.y, fwd.dot(to)))
		_set_text(guide_arrow, _guide_arrow_for(rel))
	if guide_dist != null:
		_set_text(guide_dist, "%d m" % int(dist))

## Slice 10 REAL minimap, Slice 49 transform: dots positioned from
## real world positions through the SHARED MapTransform (bounds read
## from the live GroundMesh at spawn, not literals). The old Slice 10
## formula ((w + 70) / 320 * 170, same for x and z) is gone: it
## applied the X range (-70..250) to Z as well, pinning the whole
## northern strip (z -110..-70) to the panel's top edge, and its
## hardcoded 170 px panel size was stale — MinimapPanel is
## anchor-relative, so its real size comes from the panel itself.
## Dots are clamped by their own size, so nothing hangs off the
## panel edge. Unlike a static panel with a rotating icon, these
## dots actually move: player (yellow), villagers (green), pagoda
## (gold), vehicles (white).
func _update_minimap() -> void:
	if minimap_dots.is_empty():
		var panel := _n("../JoystickLayer/MinimapPanel")
		if panel == null:
			return
		minimap_panel = panel as Control
		for name in ["PlayerDot", "VillagerDot1", "VillagerDot2", "VillagerDot3", "VillagerDot4", "PagodaDot",
				"VehicleDotCar", "VehicleDotCart", "VehicleDotMotorcycle", "VehicleDotAirplane",
				"VehicleDotCow", "VehicleDotHelicopter",
				"BellDot", "ZayatDot", "GroveDot", "MarketDot", "WellDot", "VillagerDot5",
			"GateDot13", "GroveDot13", "SchoolDot13", "TeaShopDot13", "FootballDot13",
			"VillagerDot6", "VehicleDotBoat", "HintharDot14L", "HintharDot14R", "BridgeDot14",
			"VillagerDot7", "VillagerDot8", "VehicleDotBicycle", "VehicleDotTukTuk",
			"FestivalDot16", "VillagerDot9", "VillagerDot10",
			"FishDot17", "DonateDot17", "VillagerDot11", "VillagerDot12", "StallDot17", "WellDot17", "VehicleDotCow2", "BallDot17", "HouseDot17", "VehicleDotElephant", "VillagerDot13", "VillagerDot14", "PavilionDot18", "PaddyDot18",
			"VehicleDotHorse", "VillagerDot15", "VillagerDot16", "HutDot19", "GoldStallDot19", "WorkshopDot19", "NightMarketDot20", "GuestHouseDot20", "PierDot20", "VehicleDotBoat2", "VehicleDotHorse2", "VillagerDot17", "VillagerDot18", "WaypointDot", "MindonPagodaDot", "MindonTempleDot", "MindonPostDot", "MindonHospitalDot", "MindonEduDot", "MindonMRTVDot", "MindonShopsDot", "OoVillageDot", "EastDot64_0", "EastDot64_1", "EastDot64_2", "EastDot64_3"]:
			var dot := panel.get_node_or_null(name) as ColorRect
			if dot != null:
				minimap_dots[name] = dot
		if minimap_dots.is_empty():
			return
	var put := func(dot_name: String, wpos: Vector3) -> void:
		var dot: ColorRect = minimap_dots.get(dot_name)
		if dot != null and minimap_panel != null:
			var p := MapTransform.clamp_dot(
				MapTransform.world_to_panel(wpos.x, wpos.z, minimap_panel.size),
				minimap_panel.size, dot.size)
			if dot.position != p:
				dot.position = p
	put.call("PlayerDot", global_position)
	var villagers := _villagers()
	for i in range(min(villagers.size(), 10)):
		put.call("VillagerDot%d" % (i + 1), (villagers[i] as Node3D).global_position)
	var pag := _n("../Pagoda")
	if pag != null:
		put.call("PagodaDot", (pag as Node3D).global_position)
	# Slice 11 landmark dots: bell (bronze), zayat (brown), grove
	# (green, tracked at the first palm trunk).
	var bellm := _n("../MonasteryBell")
	if bellm != null:
		put.call("BellDot", (bellm as Node3D).global_position)
	var zay := _n("../Zayat")
	if zay != null:
		put.call("ZayatDot", (zay as Node3D).global_position)
	var palm := _n("../PalmTrunk_s11_1")
	if palm != null:
		put.call("GroveDot", (palm as Node3D).global_position)
	# Slice 12 market + well dots: the market square and the brick
	# well are tracked like the other landmarks.
	var stall := _n("../MarketStallA")
	if stall != null:
		put.call("MarketDot", (stall as Node3D).global_position)
	var well := _n("../BrickWell")
	if well != null:
		put.call("WellDot", (well as Node3D).global_position)
	# Slice 13 landmark dots: gate (gold), grove (green), school
	# (blue), tea shop (orange), football ground (white).
	for pair in [["GateBeam12", "GateDot13"], ["BananaGrove13", "GroveDot13"],
			["School13", "SchoolDot13"], ["TeaShop13", "TeaShopDot13"],
			["Football13", "FootballDot13"]]:
		var lm := _n("../" + pair[0]) as Node3D
		if lm != null:
			put.call(pair[1], lm.global_position)
	for vname in ["Car", "Cart", "Motorcycle", "Airplane", "Cow", "Cow2", "Helicopter", "Boat", "Bicycle", "TukTuk", "Elephant", "Horse", "Boat2", "Horse2", "Bus"]:
		var v := _n("../" + vname)
		if v != null:
			put.call("VehicleDot" + vname, (v as Node3D).global_position)
	# Slice 14 landmark dots: bamboo bridge (bamboo brown) and the
	# two golden hinthar statues (gold).
	var br14 := _n("../BambooBridge14")
	if br14 != null:
		put.call("BridgeDot14", (br14 as Node3D).global_position)
	var hsL := _n("../HintharStatue14L")
	if hsL != null:
		put.call("HintharDot14L", (hsL as Node3D).global_position)
	var hsR := _n("../HintharStatue14R")
	if hsR != null:
		put.call("HintharDot14R", (hsR as Node3D).global_position)
	# Slice 16 festival dot: the festival ground slab.
	var fest16 := _n("../FestivalGround16")
	if fest16 != null:
		put.call("FestivalDot16", fest16.global_position)
	# Slice 17 dots: fishing spot, donation box, stall E, well #2,
	# House7, Cow2, football ball; villagers 11/12 by node name
	# (the group loop above only covers the first 10 villagers).
	for pair in [["FishingSpot17", "FishDot17"], ["DonationBox17", "DonateDot17"],
			["MarketStallE17", "StallDot17"], ["Well17_2", "WellDot17"],
			["House7_17", "HouseDot17"], ["Cow2", "VehicleDotCow2"],
			["FootballBall17", "BallDot17"], ["Villager11", "VillagerDot11"],
			["Villager12", "VillagerDot12"]]:
		var lm17 := _n("../" + pair[0]) as Node3D
		if lm17 != null:
			put.call(pair[1], lm17.global_position)
	# Slice 18 dots: villagers 13/14 by node name (the group loop
	# above only covers the first 10), pavilion + paddy landmarks.
	for pair in [["Villager13", "VillagerDot13"], ["Villager14", "VillagerDot14"],
			["Pavilion18", "PavilionDot18"], ["Paddy18", "PaddyDot18"]]:
		var lm18 := _n("../" + pair[0]) as Node3D
		if lm18 != null:
			put.call(pair[1], lm18.global_position)
	# Slice 19 dots: villagers 15/16 by node name, lakeside hut,
	# gold stall, bamboo workshop; the horse dot rides the vehicle
	# loop above (it now includes Horse).
	for pair in [["Villager15", "VillagerDot15"], ["Villager16", "VillagerDot16"],
			["LakesideHut19", "HutDot19"], ["GoldStall19", "GoldStallDot19"],
			["Workshop19", "WorkshopDot19"]]:
		var lm19 := _n("../" + pair[0]) as Node3D
		if lm19 != null:
			put.call(pair[1], lm19.global_position)
	# Slice 20 dots: villagers 17/18 by node name, night market,
	# guest house, pier; boat2/horse2 ride the vehicle loop above.
	for pair in [["Villager17", "VillagerDot17"], ["Villager18", "VillagerDot18"],
			["NightMarket20", "NightMarketDot20"], ["GuestHouse20", "GuestHouseDot20"],
			["Pier20", "PierDot20"]]:
		var lm20 := _n("../" + pair[0]) as Node3D
		if lm20 != null:
			put.call(pair[1], lm20.global_position)
	# Slice 37 dots: Mindon district landmarks + Oo village cluster.
	# The minimap transform above now spans the enlarged world
	# (centre x 90, span 320), so village and district share one map.
	for pair in [["MindonPagoda", "MindonPagodaDot"], ["MindonTemple", "MindonTempleDot"],
			["MindonPost", "MindonPostDot"], ["MindonHospital", "MindonHospitalDot"],
			["MindonEdu", "MindonEduDot"], ["MindonMRTV", "MindonMRTVDot"],
			["MindonShops", "MindonShopsDot"], ["OoHouse1", "OoVillageDot"]]:
		var lm37 := _n("../" + pair[0]) as Node3D
		if lm37 != null:
			put.call(pair[1], lm37.global_position)
	# Slice 64 dots: East Fields quest markers (runtime ColorRects
	# created by eastfields64.dress, so they exist before this
	# list is built on the first frame; missing dots are skipped
	# by the put lambda, so a pre-64 scene never errors here).
	for pair in [["EastFields64/Marker64_east_road", "EastDot64_0"], ["EastFields64/Marker64_north_lane", "EastDot64_1"],
			["EastFields64/Marker64_south_lane", "EastDot64_2"], ["EastFields64/Marker64_pond", "EastDot64_3"]]:
		var lm64 := _n("../" + pair[0]) as Node3D
		if lm64 != null:
			put.call(pair[1], lm64.global_position)
	# Slice 28 world-map waypoint dot on the minimap: the overlay owns
	# the waypoint; the minimap only mirrors it (same transform family).
	var wm28 := _n("../JoystickLayer/WorldMapPanel")
	var wp_dot: ColorRect = minimap_dots.get("WaypointDot")
	if wp_dot != null:
		if wm28 != null and bool(wm28.get("has_waypoint")):
			var wpv: Vector2 = wm28.get("waypoint")
			put.call("WaypointDot", Vector3(wpv.x, 0.0, wpv.y))
			_set_visible(wp_dot, true)
		else:
			_set_visible(wp_dot, false)

## Slice 10 nearby prompt: what is close enough to use, on foot.
func _update_prompt_label() -> void:
	if prompt_label == null:
		prompt_label = _n("../JoystickLayer/PromptLabel") as Label
	# Slice 38: a refused vehicle exit owns the prompt for a few
	# seconds so the player knows WHY they stayed in the vehicle.
	if exit_blocked_timer > 0.0 and prompt_label != null:
		_set_text(prompt_label, "ထွက်လို့မရပါ — ဘေးမှာ နေရာကျပ်နေသည်")
		_set_visible(prompt_label, true)
		return
	if prompt_label == null:
		return
	if driving:
		_set_visible(prompt_label, false)
		return
	var vill := _nearest_villager()
	if vill != null:
		var vname := str(vill.get("villager_name"))
		if vname == "":
			vname = "ရွာသား"
		_set_text(prompt_label, "အနီး: " + vname + " — စကားပြော")
		_set_visible(prompt_label, true)
		return
	var veh := _nearest_vehicle()
	if veh != null:
		var names := {"Car": "ကား", "Cart": "လှည်း", "Motorcycle": "ဆိုင်ကယ်",
			"Airplane": "လေယာဉ်", "Cow": "နွား", "Cow2": "နွား", "Helicopter": "ရဟတ်ယာဉ်", "Boat": "လှေ", "Bicycle": "စက်ဘီး", "TukTuk": "သုံးဘီး", "Elephant": "ဆင်", "Horse": "မြင်း", "Boat2": "လှေ", "Horse2": "မြင်း", "Bus": "ဘတ်စ်ကား"}
		_set_text(prompt_label, "အနီး: " + names.get(veh.name, veh.name) + " — စီးမည်")
		_set_visible(prompt_label, true)
		return
	# Slice 11 landmark prompts: bell, zayat, grove.
	# Slice 12: market + well prompts added; village sign prompt
	# added too (the old comment claimed it but the code never had it).
	for pair in [["MonasteryBell", "ခေါင်းလောင်း", 3.5],
			["Zayat", "ဇရပ်", 5.0],
			["PalmTrunk_s11_1", "ထန်းတော", 5.0],
			["MarketStallA", "ဈေး", 5.0],
			["BrickWell", "ရေတွင်း", 5.0],
			["VillageSignPost", "ရွာဆိုင်း", 4.0],
			["GateBeam12", "ရွာမုခ်ဦး", 4.0],
			["BananaGrove13", "ငှက်ပျောတော", 4.0],
			["School13", "ရွာကျောင်း", 5.0],
			["TeaShop13", "လက်ဖက်ရည်ဆိုင်", 5.0],
			["Football13", "ဘောလုံးကွင်း", 5.0],
			["BambooBridge14", "ဝါးတံတား", 4.0],
			["HintharStatue14L", "ဟင်္သာရုပ်တု", 4.0],
			["HintharStatue14R", "ဟင်္သာရုပ်တု", 4.0],
			["FestivalGround16", "ပွဲတော်", 6.0],
		["FishingSpot17", "ငါးဖမ်းဆိပ်", 4.0],
		["DonationBox17", "အလှူခံပုံး", 4.0],
		["SesameField15", "နှမ်းခင်း", 4.0],
		["ChickenCoop17", "ကြက်အိမ်", 4.0],
		["MarketStallE17", "ဈေးဆိုင် E", 5.0],
		["Well17_2", "ရေတွင်း ၂", 5.0],
		["House7_17", "အိမ် ၇", 5.0],
		["StiltHouse17_5", "ခြေတံရှည် အိမ်", 5.0],
		["FootballBall17", "ဘောလုံး", 4.0],
			["FestivalDrum16", "ဗုံ", 4.0],
			["FestivalStall16", "ပွဲဈေးဆိုင်", 4.0],
			["FestivalLantern16A", "ပွဲမီးအိမ်", 4.0],
			["Pavilion18", "မြစ်ကမ်းဇရပ်", 5.0],
			["Paddy18", "စပါးခင်း", 4.0],
			["ElephantStable18", "ဆင်တဲ", 5.0],
			["Playground18", "ကစားကွင်း", 5.0],
			["LakesideHut19", "ရေကန်အိမ်", 5.0],
			["GoldStall19", "ရွှေဆိုင်", 4.0],
			["Workshop19", "ဝါးလုပ်ငန်း", 5.0],
			["Kiln19", "အိုးဖို", 4.0],
			["FishingHut19", "ငါးဖမ်းတဲ", 5.0],
			["TeaPlant19", "လက်ဖက်ခင်း", 5.0],
			["TeacherDesk18", "ဆရာမ စာပွဲ", 4.0],
			["NightMarket20", "ညဈေး", 5.0],
			["GuestHouse20", "တည်းခိုခန်း", 5.0],
			["Pier20", "ရေကန်ဆိပ်", 4.0],
			["HorsePen20", "မြင်းခြံ ၂", 4.0],
			["MindonPagoda", "စုတောင်ပြည် ဘုရား", 6.0],
			["MindonTemple", "ဘုန်းကြီးကျောင်း", 5.0],
			["MindonPost", "စာတိုက်", 5.0],
			["MindonHospital", "ဆေးရုံ", 5.0],
			["MindonEdu", "ပညာရေးရုံး", 5.0],
			["MindonMRTV", "MRTV", 5.0],
			["MindonShops", "ဈေးဆိုင်", 5.0],
			["OoHouse1", "အိုးရွာ", 5.0],
			["MindonBridge", "တံတား", 5.0]]:
		var lm := _n("../" + pair[0]) as Node3D
		if lm != null and global_position.distance_to(lm.global_position) < float(pair[2]):
			_set_text(prompt_label, "အနီး: " + str(pair[1]))
			_set_visible(prompt_label, true)
			return
	_set_visible(prompt_label, false)

func _on_yaw_left_down() -> void:
	touch_yaw_left = true

func _on_yaw_left_up() -> void:
	touch_yaw_left = false

func _on_yaw_right_down() -> void:
	touch_yaw_right = true

func _on_yaw_right_up() -> void:
	touch_yaw_right = false

func _on_zoom_in() -> void:
	var cam := get_node_or_null("../FollowCamera")
	if cam != null and cam.has_method("zoom_in"):
		cam.call("zoom_in")

func _on_zoom_out() -> void:
	var cam := get_node_or_null("../FollowCamera")
	if cam != null and cam.has_method("zoom_out"):
		cam.call("zoom_out")

func _on_help_pressed() -> void:
	if help_label != null:
		help_label.visible = not help_label.visible

## Slice 28: open the world map overlay (it owns pause bookkeeping).
func _on_map_button_pressed() -> void:
	var wm := get_node_or_null("../JoystickLayer/WorldMapPanel")
	if wm != null and wm.has_method("open_map"):
		wm.call("open_map")


## Slice 54, audit item 8 — sightseeing tour HUD + logic.
## The button sits in the free left-column slot between the FPS
## label (top 0.50–0.55) and the joystick base (canvas y 540+,
## i.e. top ~0.75): anchors 0.02–0.14 / 0.56–0.62, so it overlaps
## no scene button. The status label sits below the quest tracker
## (0.075–0.12) and the parachute label (0.12–0.17): 0.18–0.23.
## Both are created at runtime, so main.tscn is untouched.
## Button behaviour, touch-first, no keyboard path: inactive ->
## start the tour (or restart after a completion); active ->
## cancel the tour and clear its waypoint. While active, the
## Slice 28/34 waypoint (WorldMapPanel waypoint + GuidePanel34
## strip + minimap mirror + WaypointBeacon28) points at the
## current stop, because _update_waypoint_guide reads that
## waypoint directly — no second guidance system is built.
## Arrival is checked in _physics_process from the on-foot
## position, or the driven vehicle's position while driving, so
## the tour works on foot AND in a vehicle. Completion refills
## stamina to 100 (the tour's only reward; stamina is capped,
## so it cannot stack) and saves immediately, like a stage
## change — every tour state change saves, never just in memory.
func _create_sightseeing_hud() -> void:
	var layer := get_node_or_null("../JoystickLayer") as CanvasLayer
	if layer == null:
		return
	if sightseeing_button == null:
		sightseeing_button = Button.new()
		sightseeing_button.name = "SightseeingButton54"
		sightseeing_button.text = "🏛 လည်ပတ်"
		sightseeing_button.anchor_left = 0.02
		sightseeing_button.anchor_top = 0.56
		sightseeing_button.anchor_right = 0.14
		sightseeing_button.anchor_bottom = 0.62
		layer.add_child(sightseeing_button)
		sightseeing_button.pressed.connect(_on_sightseeing_button_pressed)
		sightseeing_button_connected = true
	if sightseeing_label == null:
		sightseeing_label = Label.new()
		sightseeing_label.name = "SightseeingLabel54"
		sightseeing_label.anchor_left = 0.30
		sightseeing_label.anchor_top = 0.18
		sightseeing_label.anchor_right = 0.70
		sightseeing_label.anchor_bottom = 0.23
		sightseeing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sightseeing_label.text = ""
		layer.add_child(sightseeing_label)
	# Restored tour (saved mid-tour): re-point the waypoint at
	# the saved current stop and show its status line at once;
	# _update_sightseeing keeps both fresh from here on.
	var mm0 = _mm()
	if mm0 != null and bool(mm0.get("sightseeing_active")):
		_set_sightseeing_waypoint()
	_update_sightseeing_label()


func _on_sightseeing_button_pressed() -> void:
	var mm = _mm()
	if mm == null:
		return
	if bool(mm.get("sightseeing_active")):
		mm.call("sightseeing_cancel")
		_clear_sightseeing_waypoint()
	else:
		mm.call("sightseeing_start")
		_set_sightseeing_waypoint()
	_update_sightseeing_label()
	var sm = _sm()
	if sm != null:
		sm.call("save_game", collect_save_data())


func _set_sightseeing_waypoint() -> void:
	var mm = _mm()
	if mm == null:
		return
	var cur: Dictionary = mm.call("sightseeing_current")
	if cur.is_empty():
		return
	var pos: Vector2 = cur.get("pos", Vector2.ZERO)
	var wm := _n("../JoystickLayer/WorldMapPanel")
	if wm != null:
		wm.set("has_waypoint", true)
		wm.set("waypoint", pos)
	var beacon := _n("../WaypointBeacon28") as MeshInstance3D
	if beacon != null:
		beacon.visible = true
		beacon.global_position = Vector3(pos.x, 2.5, pos.y)


func _clear_sightseeing_waypoint() -> void:
	var wm := _n("../JoystickLayer/WorldMapPanel")
	if wm != null and wm.has_method("clear_waypoint"):
		wm.call("clear_waypoint")


func _update_sightseeing_label() -> void:
	if sightseeing_label == null:
		return
	var mm = _mm()
	if mm == null:
		return
	var text: String = mm.call("sightseeing_label")
	_set_text(sightseeing_label, text)
	_set_visible(sightseeing_label, text != "")


func _update_sightseeing() -> void:
	var mm = _mm()
	if mm == null:
		return
	if not bool(mm.get("sightseeing_active")):
		_update_sightseeing_label()
		return
	var ref: Vector3 = global_position
	if driving and driving_vehicle != null:
		ref = (driving_vehicle as Node3D).global_position
	var result: Dictionary = mm.call("sightseeing_check", Vector2(ref.x, ref.z))
	if not bool(result.get("visited", false)):
		_update_sightseeing_label()
		return
	_play_tone(660.0, 0.25)
	if bool(result.get("completed", false)):
		stamina = 100.0
		_clear_sightseeing_waypoint()
	else:
		_set_sightseeing_waypoint()
	_update_sightseeing_label()
	var sm = _sm()
	if sm != null:
		sm.call("save_game", collect_save_data())


## Slice 60 — Mindon district side quests (see mission_data.gd
## DISTRICT60_QUESTS). Mirrors _update_sightseeing: the check runs
## on foot AND in vehicles (vehicle position used while driving),
## a visit chimes + refills stamina, and the label always shows
## live progress. No waypoint is set: the two targets already have
## minimap dots (MindonHospitalDot, MindonMRTVDot), and the label
## names the next target, so no new guidance system is needed.
func _update_district60() -> void:
	var mm = _mm()
	if mm == null:
		return
	if district_label == null:
		district_label = _n("../JoystickLayer/DistrictLabel60") as Label
	if district_label != null:
		_set_text(district_label, mm.call("district60_label"))
	var ref: Vector3 = global_position
	if driving and driving_vehicle != null:
		ref = (driving_vehicle as Node3D).global_position
	var result: Dictionary = mm.call("district60_check", Vector2(ref.x, ref.z))
	if not bool(result.get("visited", false)):
		return
	_play_tone(660.0, 0.25)
	stamina = 100.0
	if district_label != null:
		_set_text(district_label, mm.call("district60_label"))
	var sm = _sm()
	if sm != null:
		sm.call("save_game", collect_save_data())


## Slice 64 — East Fields side quests (see mission_data.gd
## EASTFIELDS64_QUESTS). Mirrors _update_district60: the check runs
## on foot AND in vehicles (vehicle position used while driving),
## a visit chimes + refills stamina, and the label always shows
## live progress. The button re-points the shared Slice 28/34
## waypoint guidance at the next unvisited stop (same
## WorldMapPanel + WaypointBeacon28 mechanism as sightseeing);
## pressing it again, or pressing it when all four are done,
## clears the waypoint. Button placement (audited in the Slice 64
## sim): left column under the sightseeing button — anchor top
## 0.64..0.70 (canvas y 461..504) sits below SightseeingButton54
## (y 403..446) and above the joystick base (top y 540), so it
## overlaps nothing; the label sits at anchor top 0.42..0.47
## (canvas y 302..338), below GarageLabel60 (y 259..295) and
## above nothing else in that column.
func _create_eastfields_hud() -> void:
	var layer := get_node_or_null("../JoystickLayer") as CanvasLayer
	if layer == null:
		return
	if eastfields_button == null:
		eastfields_button = Button.new()
		eastfields_button.name = "EastFieldsButton64"
		eastfields_button.text = "🌾 လယ်ကွင်း"
		eastfields_button.anchor_left = 0.02
		eastfields_button.anchor_top = 0.64
		eastfields_button.anchor_right = 0.14
		eastfields_button.anchor_bottom = 0.70
		layer.add_child(eastfields_button)
		eastfields_button.pressed.connect(_on_eastfields_button_pressed)
	if eastfields_label == null:
		eastfields_label = Label.new()
		eastfields_label.name = "EastFieldsLabel64"
		eastfields_label.anchor_left = 0.30
		eastfields_label.anchor_top = 0.42
		eastfields_label.anchor_right = 0.70
		eastfields_label.anchor_bottom = 0.47
		eastfields_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eastfields_label.text = ""
		layer.add_child(eastfields_label)
	_update_eastfields_label()


func _on_eastfields_button_pressed() -> void:
	var mm = _mm()
	if mm == null:
		return
	var nxt: Dictionary = mm.call("eastfields64_next")
	if nxt.is_empty():
		_clear_eastfields_waypoint()
		return
	var pos: Vector2 = nxt.get("pos", Vector2.ZERO)
	var wm := _n("../JoystickLayer/WorldMapPanel")
	if wm != null:
		wm.set("has_waypoint", true)
		wm.set("waypoint", pos)
	var beacon := _n("../WaypointBeacon28") as MeshInstance3D
	if beacon != null:
		beacon.visible = true
		beacon.global_position = Vector3(pos.x, 2.5, pos.y)


func _clear_eastfields_waypoint() -> void:
	var wm := _n("../JoystickLayer/WorldMapPanel")
	if wm != null and wm.has_method("clear_waypoint"):
		wm.call("clear_waypoint")


func _update_eastfields_label() -> void:
	if eastfields_label == null:
		return
	var mm = _mm()
	if mm == null:
		return
	_set_text(eastfields_label, mm.call("eastfields64_label"))


func _update_eastfields64() -> void:
	var mm = _mm()
	if mm == null:
		return
	_update_eastfields_label()
	var ref: Vector3 = global_position
	if driving and driving_vehicle != null:
		ref = (driving_vehicle as Node3D).global_position
	var result: Dictionary = mm.call("eastfields64_check", Vector2(ref.x, ref.z))
	if not bool(result.get("visited", false)):
		return
	_play_tone(660.0, 0.25)
	stamina = 100.0
	if bool(result.get("all_done", false)):
		_clear_eastfields_waypoint()
	_update_eastfields_label()
	var sm = _sm()
	if sm != null:
		sm.call("save_game", collect_save_data())


## Slice 60 — garage notice label (transient, 4 s). PromptLabel is
## rewritten every frame by _update_prompt_label, so garage feedback
## gets its own label instead of fighting it. The button hides
## while driving, same as the other on-foot buttons.
func _update_garage_notice(delta: float) -> void:
	if garage_button == null:
		garage_button = _n("../JoystickLayer/GarageButton60") as Button
	if garage_button != null:
		_set_visible(garage_button, not driving and hud_more_open)
	if garage_label == null:
		garage_label = _n("../JoystickLayer/GarageLabel60") as Label
	if garage_label == null:
		return
	if garage_notice_timer > 0.0:
		garage_notice_timer -= delta
		_set_text(garage_label, garage_notice_text)
		_set_visible(garage_label, true)
	else:
		_set_visible(garage_label, false)


## Slice 60 — garage recall. Moves the remembered vehicle to a
## capsule-probed free spot near the player (same probe pattern as
## find_free_exit_spot, centred on the player instead of the
## vehicle). The vehicle keeps its own height, is never auto-entered,
## and is never moved into a wall: if every candidate is blocked the
## button says so and the vehicle stays where it is.
func _on_garage_button_pressed() -> void:
	if driving:
		garage_notice_text = "ယာဉ်စီးနေစဉ် ဂိုဒေါင်ခေါ်၍မရ"
		garage_notice_timer = 4.0
		return
	if garage_vehicle_name == "":
		garage_notice_text = "ဂိုဒေါင်မှာ ယာဉ်မရှိသေးပါ — ယာဉ်တစ်စီး အရင်စီးပါ"
		garage_notice_timer = 4.0
		return
	var veh := get_node_or_null("../" + garage_vehicle_name) as Node3D
	if veh == null:
		garage_notice_text = "ဂိုဒေါင်ယာဉ် ရှာမတွေ့ပါ"
		garage_notice_timer = 4.0
		return
	var spot := _free_spot_near_player(veh)
	if spot == Vector3.INF:
		garage_notice_text = "အနီးမှာ နေရာကျပ်နေသည် — နည်းနည်းရွှေ့ပြီးမှ ပြန်ခေါ်ပါ"
		garage_notice_timer = 4.0
		return
	veh.global_position = Vector3(spot.x, veh.global_position.y, spot.z)
	garage_notice_text = "🚗 ဂိုဒေါင်ယာဉ် ရောက်လာပါပြီ — စီးမည် ကို နှိပ်ပါ"
	garage_notice_timer = 4.0


## Slice 60 — free-spot probe near the player (see
## find_free_exit_spot for the pattern; exclusions identical plus
## the recalled vehicle itself). Returns Vector3.INF if blocked.
func _free_spot_near_player(vehicle: Node3D) -> Vector3:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		return global_position + Vector3(3.0, 0.0, 0.0)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.2
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 1
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var offsets: Array = [Vector3(3.0, 0.0, 0.0), Vector3(-3.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 3.0), Vector3(0.0, 0.0, -3.0),
		Vector3(3.0, 0.0, 3.0), Vector3(3.0, 0.0, -3.0),
		Vector3(-3.0, 0.0, 3.0), Vector3(-3.0, 0.0, -3.0),
		Vector3(5.0, 0.0, 0.0), Vector3(-5.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, -5.0)]
	for off in offsets:
		var spot: Vector3 = global_position + off
		params.transform = Transform3D(Basis.IDENTITY, spot + Vector3(0.0, 0.6, 0.0))
		var hits: Array = space.intersect_shape(params, 8)
		var blocked := false
		for h in hits:
			var col = h.get("collider")
			if col == null:
				continue
			if col == self:
				continue
			if col == vehicle:
				continue
			if col.name == "GroundBody":
				continue
			blocked = true
			break
		if not blocked:
			return spot
	return Vector3.INF


func _on_camera_reset() -> void:
	var cam := get_node_or_null("../FollowCamera")
	if cam != null:
		cam.set("orbit_angle", 0.0)
		cam.set("zoom", 1.0)

## Slice 12 market + well interactions (TOUCH-FIRST — no keyboard
## path exists for buying fruit or drawing water). Both buttons
## live in the real scene (JoystickLayer), found lazily like the
## Talk button, and are hidden while driving.
func _update_market_buttons() -> void:
	if fruit_button == null:
		fruit_button = _n("../JoystickLayer/FruitButton") as Button
		if fruit_button != null and not fruit_button_connected:
			fruit_button.pressed.connect(_on_buy_fruit)
			fruit_button_connected = true
	if water_button == null:
		water_button = _n("../JoystickLayer/WaterButton") as Button
		if water_button != null and not water_button_connected:
			water_button.pressed.connect(_on_draw_water)
			water_button_connected = true
	if driving:
		if fruit_button != null:
			fruit_button.visible = false
		if water_button != null:
			water_button.visible = false
		return
	var stall := _n("../MarketStallA") as Node3D
	var near_stall := stall != null and global_position.distance_to(stall.global_position) < 4.0
	var well := _n("../BrickWell") as Node3D
	var near_well := well != null and global_position.distance_to(well.global_position) < 4.0
	if fruit_button != null:
		fruit_button.visible = near_stall
	if water_button != null:
		water_button.visible = near_well and draw_timer <= 0.0

func _on_buy_fruit() -> void:
	if driving:
		return
	_mm().bump("fruit")
	_mm().advance("buy_fruit")
	_update_quest_label()
	_update_fruit_water_label()

func _on_draw_water() -> void:
	if driving or draw_timer > 0.0:
		return
	draw_timer = 1.5

func _update_fruit_water_label() -> void:
	if fruit_water_label == null:
		fruit_water_label = get_node_or_null("../JoystickLayer/FruitWaterLabel") as Label
	if fruit_water_label == null:
		return
	var mm = _mm()
	if mm == null:
		return
# Slice 61 addendum: hide the label entirely when every counter
	# is zero (the screenshot's bare "0 0 0..." grid); otherwise show
	# only nonzero counters in Burmese text, no emoji.
	var summary: String = mm.nonzero_summary() if mm.has_method("nonzero_summary") else mm.counter_text()
	_set_text(fruit_water_label, summary)
	_set_visible(fruit_water_label, summary != "")

func _update_draw_animation(delta: float) -> void:
	if draw_timer <= 0.0:
		return
	draw_timer -= delta
	var bucket := _n("../BrickWell/WellBucket12") as Node3D
	if bucket != null:
		var phase := 1.0 - maxf(draw_timer, 0.0) / 1.5
		var y := 1.6
		if phase < 0.5:
			y = 1.6 - (1.6 - 0.55) * (phase / 0.5)
		else:
			y = 0.55 + (1.6 - 0.55) * ((phase - 0.5) / 0.5)
		var p := bucket.position
		p.y = y
		bucket.position = p
	if draw_timer <= 0.0:
		_mm().bump("water")
		var res = _mm().advance("draw_water")
		if res["reward"] != "":
			_apply_reward(res["reward"])
		_update_quest_label()
		_update_fruit_water_label()

## Slice 13 banana harvest (TOUCH-FIRST — no keyboard path).
## The button lives in the real scene (JoystickLayer/BananaButton)
## and shows only within 3.5 m of the grove while a bunch is left.
## Picking hides the next bunch; when all 3 are picked they regrow
## after 20 s. Picking 3 bananas finishes quest stage 7 with the
## third reward: +5% walk speed, applied exactly once.
func _banana_bunch_visible() -> bool:
	for i in range(3):
		var b := _n("../BananaGrove13/BananaBunch13_%d" % i) as Node3D
		if b != null and b.visible:
			return true
	return false

func _update_banana_button() -> void:
	if banana_button == null:
		banana_button = _n("../JoystickLayer/BananaButton") as Button
		if banana_button != null and not banana_button_connected:
			banana_button.pressed.connect(_on_pick_banana)
			banana_button_connected = true
	if banana_button == null:
		return
	if driving:
		banana_button.visible = false
		return
	var grove := _n("../BananaGrove13") as Node3D
	banana_button.visible = grove != null and global_position.distance_to(grove.global_position) < 3.5 and _banana_bunch_visible()

func _on_pick_banana() -> void:
	if driving:
		return
	for i in range(3):
		var b := get_node_or_null("../BananaGrove13/BananaBunch13_%d" % i) as Node3D
		if b != null and b.visible:
			b.visible = false
			break
	_mm().bump("banana")
	if _mm().get_count("banana") >= 3:
		var res = _mm().advance("pick_bananas")
		if res["reward"] != "":
			_apply_reward(res["reward"])
	_update_quest_label()
	_update_fruit_water_label()

func _update_banana_regrow(delta: float) -> void:
	if _banana_bunch_visible():
		banana_regrow_timer = 0.0
		return
	if banana_regrow_timer <= 0.0:
		banana_regrow_timer = 20.0
		return
	banana_regrow_timer -= delta
	if banana_regrow_timer <= 0.0:
		for i in range(3):
			var b := get_node_or_null("../BananaGrove13/BananaBunch13_%d" % i) as Node3D
			if b != null:
				b.visible = true

## Slice 13 headlight toggle (TOUCH-FIRST). The Lights button
## shows only while driving the car or motorcycle; it toggles the
## headlight meshes' visibility (the car has two, the motorcycle
## one). No keyboard path is needed for it.
func _apply_lights() -> void:
	var car := _n("../Car")
	if car != null:
		for hn in ["Headlight_R", "Headlight_L"]:
			var h := _child_cached(car, hn, "car/" + hn) as Node3D
			if h != null:
				h.visible = lights_on
	var bike := _n("../Motorcycle")
	if bike != null:
		var bh := _child_cached(bike, "BikeHeadlight", "bike/BikeHeadlight") as Node3D
		if bh != null:
			bh.visible = lights_on
	var tuk := _n("../TukTuk")
	if tuk != null:
		var th := _child_cached(tuk, "TukHeadlight", "tuk/TukHeadlight") as Node3D
		if th != null:
			th.visible = lights_on

func _update_lights_button() -> void:
	if lights_button == null:
		lights_button = get_node_or_null("../JoystickLayer/LightsButton") as Button
		if lights_button != null and not lights_button_connected:
			lights_button.pressed.connect(_on_lights_pressed)
			lights_button_connected = true
	if lights_button == null:
		return
	lights_button.visible = driving and driving_vehicle != null and driving_vehicle.name in ["Car", "Motorcycle", "TukTuk"]
	if lights_button.visible:
		_apply_lights()

func _on_lights_pressed() -> void:
	lights_on = not lights_on
	_apply_lights()

## Slice 14 pray interaction (TOUCH-FIRST — this is a mobile game).
## The Pray button lives in the real scene (JoystickLayer/PrayButton)
## and shows only within 4 m of a hinthar statue while on foot.
## Tapping it shows the nearest statue's blessing label for 4 s;
## on quest stage 9 it completes the chain with the fourth reward
## (+5% walk speed, applied exactly once, plus a full stamina refill).
func _nearest_statue() -> Node:
	var best: Node = null
	var best_dist: float = 4.0
	for sname in ["HintharStatue14L", "HintharStatue14R"]:
		var s := _n("../" + sname) as Node3D
		if s != null:
			var d := global_position.distance_to(s.global_position)
			if d < best_dist:
				best_dist = d
				best = s
	return best

func _update_pray_button() -> void:
	if pray_button == null:
		pray_button = get_node_or_null("../JoystickLayer/PrayButton") as Button
		if pray_button != null and not pray_button_connected:
			pray_button.pressed.connect(_on_pray)
			pray_button_connected = true
	if pray_button == null:
		return
	if driving:
		pray_button.visible = false
		return
	pray_button.visible = _nearest_statue() != null

func _on_pray() -> void:
	if driving:
		return
	var s := _nearest_statue()
	if s == null:
		return
	var bl := s.get_node_or_null("BlessingLabel") as Label3D
	if bl != null:
		bl.visible = true
	blessing_timer = 4.0
	var res = _mm().advance("pray")
	if res["reward"] != "":
		_apply_reward(res["reward"])
	if res["advanced"]:
		_update_quest_label()

func _update_blessing(delta: float) -> void:
	if blessing_timer <= 0.0:
		return
	blessing_timer -= delta
	if blessing_timer <= 0.0:
		for sname in ["HintharStatue14L", "HintharStatue14R"]:
			var s := get_node_or_null("../" + sname)
			if s != null:
				var bl := s.get_node_or_null("BlessingLabel") as Label3D
				if bl != null:
					bl.visible = false

## Slice 15 tea + book interactions (TOUCH-FIRST — no keyboard path).
## The buttons live in the real scene (JoystickLayer/TeaButton15 and
## BookButton15) and show only on foot, within 4 m of the Slice 13
## tea shop / school. Ordering tea finishes quest stage 10;
## donating a book finishes stage 11 with the fifth reward
## (sprint +10%, applied exactly once).
func _update_tea_book_buttons() -> void:
	if tea_button == null:
		tea_button = _n("../JoystickLayer/TeaButton15") as Button
		if tea_button != null and not tea_button_connected:
			tea_button.pressed.connect(_on_order_tea)
			tea_button_connected = true
	if book_button == null:
		book_button = _n("../JoystickLayer/BookButton15") as Button
		if book_button != null and not book_button_connected:
			book_button.pressed.connect(_on_donate_book)
			book_button_connected = true
	if driving:
		if tea_button != null:
			tea_button.visible = false
		if book_button != null:
			book_button.visible = false
		return
	var shop := _n("../TeaShop13") as Node3D
	var near_shop := shop != null and global_position.distance_to(shop.global_position) < 4.0
	var school := _n("../School13") as Node3D
	var near_school := school != null and global_position.distance_to(school.global_position) < 4.0
	if tea_button != null:
		tea_button.visible = near_shop
	if book_button != null:
		book_button.visible = near_school

func _on_order_tea() -> void:
	if driving:
		return
	_mm().bump("tea")
	_mm().advance("order_tea")
	_update_quest_label()
	_update_fruit_water_label()

func _on_donate_book() -> void:
	if driving:
		return
	_mm().bump("book")
	var res = _mm().advance("donate_book")
	if res["reward"] != "":
		_apply_reward(res["reward"])
	_update_quest_label()
	_update_fruit_water_label()

## Slice 16 festival interactions (TOUCH-FIRST — this is a mobile
## game). Drum / lantern / snack buttons live in the real scene
## (JoystickLayer/DrumButton16, LanternButton16, SnackButton16)
## and show only on foot, near the festival. Beating the drum on
## quest stage 15 finishes the chain with the sixth reward
## (+5% walk speed, applied exactly once, +10% jump).
func _update_festival_buttons() -> void:
	if drum_button == null:
		drum_button = _n("../JoystickLayer/DrumButton16") as Button
		if drum_button != null and not drum_button_connected:
			drum_button.pressed.connect(_on_beat_drum)
			drum_button_connected = true
	if lantern_button == null:
		lantern_button = _n("../JoystickLayer/LanternButton16") as Button
		if lantern_button != null and not lantern_button_connected:
			lantern_button.pressed.connect(_on_light_lantern)
			lantern_button_connected = true
	if snack_button == null:
		snack_button = _n("../JoystickLayer/SnackButton16") as Button
		if snack_button != null and not snack_button_connected:
			snack_button.pressed.connect(_on_buy_snack)
			snack_button_connected = true
	if driving:
		if drum_button != null:
			drum_button.visible = false
		if lantern_button != null:
			lantern_button.visible = false
		if snack_button != null:
			snack_button.visible = false
		return
	var drum := _n("../FestivalDrum16") as Node3D
	if drum_button != null:
		drum_button.visible = drum != null and global_position.distance_to(drum.global_position) < 4.0
	if lantern_button != null:
		lantern_button.visible = _nearest_unlit_lantern() != null
	var stall := _n("../FestivalStall16") as Node3D
	if snack_button != null:
		snack_button.visible = stall != null and global_position.distance_to(stall.global_position) < 4.0

func _nearest_unlit_lantern() -> Node:
	var best: Node = null
	var best_dist: float = 4.0
	for lname in ["FestivalLantern16A", "FestivalLantern16B", "FestivalLantern16C"]:
		var l := _n("../" + lname) as Node3D
		if l == null:
			continue
		var glow := _child_cached(l, "LanternGlow", "lantern/" + lname) as Node3D
		if glow != null and glow.visible:
			continue
		var d := global_position.distance_to(l.global_position)
		if d < best_dist:
			best_dist = d
			best = l
	return best

func _on_beat_drum() -> void:
	if driving:
		return
	var drum := get_node_or_null("../FestivalDrum16") as Node3D
	if drum == null:
		return
	var dl := drum.get_node_or_null("DrumLabel") as Label3D
	if dl != null:
		dl.visible = true
	drum_timer = 4.0
	var res = _mm().advance("beat_drum")
	if res["reward"] != "":
		_apply_reward(res["reward"])
	if res["advanced"]:
		_update_quest_label()

func _on_light_lantern() -> void:
	if driving:
		return
	var l := _nearest_unlit_lantern()
	if l == null:
		return
	var glow := (l as Node3D).get_node_or_null("LanternGlow") as Node3D
	if glow != null:
		glow.visible = true
	_mm().bump("lantern")
	_update_fruit_water_label()

func _on_buy_snack() -> void:
	if driving:
		return
	_mm().bump("snack")
	_update_fruit_water_label()

## Slice 17: fishing / donating / milking / watering / feeding, horn,
## bell, photo, rain, football. Every button is touch-first and lives
## in the real scene (JoystickLayer); driving buttons (horn, bell)
## show only while driving the matching vehicle, the rest only on
## foot near their spot. No keyboard path exists for any of them.
func _play_tone(freq: float, dur: float) -> void:
	var sm_tone = _sm()
	if sm_tone != null:
		if bool(sm_tone.get("muted")):
			return
	elif not sound_on:
		return
	if chime_player == null:
		chime_player = AudioStreamPlayer.new()
		add_child(chime_player)
	if sm_tone != null:
		chime_player.volume_db = float(sm_tone.call("volume_db"))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var n := int(22050 * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var s := int(sin(float(i) / 22050.0 * freq * TAU) * 12000.0)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	wav.data = data
	chime_player.stream = wav
	chime_player.play()

func _wire17(btn_name: String, btn: Button, connected: bool, handler: Callable) -> Button:
	if btn == null:
		btn = get_node_or_null("../JoystickLayer/" + btn_name) as Button
		if btn != null and not connected:
			btn.pressed.connect(handler)
			connected = true
	return btn

func _update_slice17_buttons() -> void:
	fish_button = _wire17("FishButton17", fish_button, fish_button_connected, _on_fish)
	if fish_button != null and not fish_button_connected:
		fish_button_connected = true
	donate_button = _wire17("DonateButton17", donate_button, donate_button_connected, _on_donate)
	if donate_button != null and not donate_button_connected:
		donate_button_connected = true
	milk_button = _wire17("MilkButton17", milk_button, milk_button_connected, _on_milk)
	if milk_button != null and not milk_button_connected:
		milk_button_connected = true
	water17_button = _wire17("WaterButton17", water17_button, water17_button_connected, _on_water_crops)
	if water17_button != null and not water17_button_connected:
		water17_button_connected = true
	feed_button = _wire17("FeedButton17", feed_button, feed_button_connected, _on_feed_chickens)
	if feed_button != null and not feed_button_connected:
		feed_button_connected = true
	horn_button = _wire17("HornButton17", horn_button, horn_button_connected, _on_horn)
	if horn_button != null and not horn_button_connected:
		horn_button_connected = true
	bell17_button = _wire17("BellButton17", bell17_button, bell17_button_connected, _on_bell17)
	if bell17_button != null and not bell17_button_connected:
		bell17_button_connected = true
	photo_button = _wire17("PhotoButton17", photo_button, photo_button_connected, _on_photo)
	if photo_button != null and not photo_button_connected:
		photo_button_connected = true
	rain_button = _wire17("RainButton17", rain_button, rain_button_connected, _on_rain)
	if rain_button != null and not rain_button_connected:
		rain_button_connected = true
	if driving:
		if horn_button != null:
			horn_button.visible = driving_vehicle != null and driving_vehicle.name in ["Car", "TukTuk"]
		if bell17_button != null:
			bell17_button.visible = driving_vehicle != null and driving_vehicle.name == "Bicycle"
		for b in [fish_button, donate_button, milk_button, water17_button, feed_button, photo_button, rain_button]:
			if b != null:
				b.visible = false
		return
	var spot := _n("../FishingSpot17") as Node3D
	if fish_button != null:
		fish_button.visible = spot != null and global_position.distance_to(spot.global_position) < 4.0
	var box := _n("../DonationBox17") as Node3D
	if donate_button != null:
		donate_button.visible = box != null and global_position.distance_to(box.global_position) < 4.0
	var cow := _n("../Cow") as Node3D
	if milk_button != null:
		milk_button.visible = cow != null and global_position.distance_to(cow.global_position) < 3.5
	var field := _n("../SesameField15") as Node3D
	if water17_button != null:
		water17_button.visible = field != null and global_position.distance_to(field.global_position) < 4.0
	var coop := _n("../ChickenCoop17") as Node3D
	if feed_button != null:
		feed_button.visible = coop != null and global_position.distance_to(coop.global_position) < 4.0
	if photo_button != null:
		photo_button.visible = hud_more_open
	if rain_button != null:
		rain_button.visible = hud_more_open
		_set_text(rain_button, "မိုးပိတ်" if rain_on else "မိုး")
	if horn_button != null:
		horn_button.visible = false
	if bell17_button != null:
		bell17_button.visible = false

func _on_fish() -> void:
	if driving:
		return
	_mm().bump("fish")
	if _mm().advance("fish")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_donate() -> void:
	if driving:
		return
	_mm().bump("donation")
	if _mm().advance("donate")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_milk() -> void:
	if driving:
		return
	_mm().bump("milk")
	if _mm().advance("milk")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_water_crops() -> void:
	if driving:
		return
	if crop_growth < 3:
		crop_growth += 1
		var s := 1.0 + 0.3 * float(crop_growth)
		for i in range(6):
			var p := get_node_or_null("../SesameField15/SesamePlant15_%d" % i) as Node3D
			if p != null:
				p.scale = Vector3(s, s, s)
	if _mm().advance("water_crops")["advanced"]:
		_update_quest_label()

func _on_feed_chickens() -> void:
	if driving:
		return
	_mm().bump("egg")
	var res = _mm().advance("feed_chickens")
	if res["reward"] != "":
		_apply_reward(res["reward"])
	if res["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_horn() -> void:
	_play_tone(220.0, 0.4)

func _on_bell17() -> void:
	_play_tone(880.0, 0.3)

func _on_photo() -> void:
	if driving:
		return
	var img := get_viewport().get_texture().get_image()
	_mm().bump("photo")
	img.save_png("user://photo17_%d.png" % _mm().get_count("photo"))

func _on_rain() -> void:
	rain_on = not rain_on
	var rain := get_node_or_null("../Rain17") as GPUParticles3D
	if rain != null:
		rain.visible = rain_on
		rain.emitting = rain_on

## Slice 17 football: the ball is pushed when the player walks into
## it and rolls with decay; entering either goal (24,-20) or (36,-20)
## scores, resets the ball to centre, and bumps the goal counter.
func _update_football(delta: float) -> void:
	var ball := _n("../FootballBall17") as Node3D
	if ball == null:
		return
	if not driving:
		var to_ball := Vector2(ball.global_position.x - global_position.x, ball.global_position.z - global_position.z)
		if to_ball.length() < 1.2 and to_ball.length() > 0.01:
			ball_vel += to_ball.normalized() * 8.0
	ball.global_position.x += ball_vel.x * delta
	ball.global_position.z += ball_vel.y * delta
	ball_vel *= maxf(0.0, 1.0 - 2.0 * delta)
	for g in [Vector2(24.0, -20.0), Vector2(36.0, -20.0)]:
		if Vector2(ball.global_position.x, ball.global_position.z).distance_to(g) < 2.0:
			_mm().bump("goal")
			ball.global_position = Vector3(30.0, 0.35, -20.0)
			ball_vel = Vector2.ZERO
			_update_fruit_water_label()
			break

## Slice 18: offering / rice / rest / feed, mute, trumpet. Every
## button is touch-first and lives in the real scene (JoystickLayer);
## the foot buttons show only near their spot, the trumpet only
## while driving the elephant, the mute button always (it is a
## setting, not a spot action). No keyboard path exists for any.
func _update_slice18_buttons() -> void:
	offer_button = _wire17("OfferButton18", offer_button, offer_button_connected, _on_offer)
	if offer_button != null and not offer_button_connected:
		offer_button_connected = true
	plant_button = _wire17("PlantButton18", plant_button, plant_button_connected, _on_plant_rice)
	if plant_button != null and not plant_button_connected:
		plant_button_connected = true
	rest_button = _wire17("RestButton18", rest_button, rest_button_connected, _on_rest)
	if rest_button != null and not rest_button_connected:
		rest_button_connected = true
	mute_button = _wire17("MuteButton18", mute_button, mute_button_connected, _on_mute)
	if mute_button != null and not mute_button_connected:
		mute_button_connected = true
	trumpet_button = _wire17("TrumpetButton18", trumpet_button, trumpet_button_connected, _on_trumpet)
	if trumpet_button != null and not trumpet_button_connected:
		trumpet_button_connected = true
	feed18_button = _wire17("FeedButton18", feed18_button, feed18_button_connected, _on_feed_elephant)
	if feed18_button != null and not feed18_button_connected:
		feed18_button_connected = true
	if mute_button != null:
		var sm_mute = _sm()
		if sm_mute != null:
			sound_on = not bool(sm_mute.get("muted"))
		mute_button.visible = hud_more_open
		_set_text(mute_button, "အသံပိတ်" if sound_on else "အသံဖွင့်")
	if driving:
		if trumpet_button != null:
			trumpet_button.visible = driving_vehicle != null and driving_vehicle.name == "Elephant"
		for b in [offer_button, plant_button, rest_button, feed18_button]:
			if b != null:
				b.visible = false
		return
	if trumpet_button != null:
		trumpet_button.visible = false
	var ele := _n("../Elephant") as Node3D
	if feed18_button != null:
		feed18_button.visible = ele != null and global_position.distance_to(ele.global_position) < 4.0
	var pag := _n("../Pagoda") as Node3D
	if offer_button != null:
		# Slice 38 fix: the pre-existing Slice 18 range (5.0 m) was
		# unreachable — the pagoda base cylinder (Slice 4, radius
		# 6.5 m) stops the player at 6.9 m from the centre, so the
		# offer button never showed and the quest chain stalled at
		# stage 22. 8.0 m lets the player offer from the pagoda
		# base without touching the collision; nothing else about
		# the interaction changes.
		offer_button.visible = pag != null and global_position.distance_to(pag.global_position) < 8.0
	var paddy := _n("../Paddy18") as Node3D
	if plant_button != null:
		plant_button.visible = paddy != null and global_position.distance_to(paddy.global_position) < 4.0
	var rest_spot: Node3D = null
	for rname in ["RestBench18A", "RestBench18B"]:
		var rb := _n("../" + rname) as Node3D
		if rb != null and global_position.distance_to(rb.global_position) < 4.0:
			rest_spot = rb
			break
	if rest_button != null:
		rest_button.visible = rest_spot != null and stamina < 100.0

func _on_offer() -> void:
	if driving:
		return
	_mm().bump("flower")
	if _mm().advance("offer_flowers")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_plant_rice() -> void:
	if driving:
		return
	_mm().bump("rice")
	if rice_growth < 3:
		rice_growth += 1
		var s := 1.0 + 0.3 * float(rice_growth)
		for i in range(6):
			var sd := get_node_or_null("../Paddy18/RiceSeedling18_%d" % i) as Node3D
			if sd != null:
				sd.scale = Vector3(s, s, s)
	if _mm().advance("plant_rice")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_rest() -> void:
	if driving:
		return
	stamina = 100.0
	if _mm().advance("rest")["advanced"]:
		_update_quest_label()


func _on_mute() -> void:
	sound_on = not sound_on
	var sm = _sm()
	if sm != null:
		sm.set("muted", not sound_on)
		sm.call("save_settings")


func _sm():
	if _sm_cached != null and is_instance_valid(_sm_cached):
		return _sm_cached
	_sm_cached = get_node_or_null("/root/SaveManager")
	return _sm_cached


## Slice 30 outfit: apply the saved Character-screen choice at spawn.
## The scene's taikpon/longyi materials are SHARED with all 18
## villagers, so the player's Torso/Longyi get a DUPLICATED material
## each (villagers keep the shared originals, untouched). Hat is a
## visibility toggle only, so no material work is needed for it.
## Applied on world load, not live: changing the outfit in the menu
## shows up the next time the world loads.
func _apply_outfit() -> void:
	var sm = _sm()
	if sm == null:
		return
	var shirt_html = str(sm.get("shirt_color_html"))
	var longyi_html = str(sm.get("longyi_color_html"))
	if Color.html_is_valid(shirt_html):
		_recolor_part("Torso", Color(shirt_html))
	if Color.html_is_valid(longyi_html):
		_recolor_part("Longyi", Color(longyi_html))
	var hat = get_node_or_null("PlayerHat") as MeshInstance3D
	if hat != null:
		hat.visible = bool(sm.get("hat_visible"))


## Slice 35 vehicle paints: apply the saved Vehicle-screen choices at
## world spawn, one DUPLICATED body material per vehicle (the Slice 30
## pattern). Duplication matters here too: the motorcycle body shares
## the scene's teal paint material with the Bicycle frame, so recoloring
## the shared material in place would repaint the bicycle as well —
## the duplicate keeps the bicycle (and every other node) untouched.
## Runs on the first physics frame, when every scene node is in the
## tree; if any body mesh is missing it retries next frame instead of
## silently skipping a vehicle. Applied on world load, not live:
## changing a paint in the menu shows up the next time the world loads.
func _apply_vehicle_paints() -> void:
	var sm = _sm()
	if sm == null:
		return
	var bodies: Array = [
		["../Car/MeshInstance3D", "car_paint_html"],
		["../Motorcycle/MeshInstance3D", "motorcycle_paint_html"],
		["../TukTuk/TukBody", "tuktuk_paint_html"],
	]
	for entry in bodies:
		var mesh = get_node_or_null(str(entry[0])) as MeshInstance3D
		if mesh == null:
			return
		var html = str(sm.get(str(entry[1])))
		if not Color.html_is_valid(html):
			continue
		var base = mesh.get_surface_override_material(0)
		if base == null:
			continue
		var mat = base.duplicate() as StandardMaterial3D
		if mat == null:
			continue
		mat.albedo_color = Color(html)
		mesh.set_surface_override_material(0, mat)
	vehicle_paints_applied = true


## Slice 32 HUD size: scales every touch HUD control around its own
## centre, from the persisted hud_scale (0.8–1.25, default 1.0).
## Applied at world spawn and again on pause-resume, so a change
## made in the pause Settings screen takes effect without a world
## reload. Two JoystickLayer children are deliberately EXCLUDED:
## PausePanel21 (a menu — menus keep their own layout) and
## WorldMapPanel (the Slice 28 map's pixel math is computed from
## its unscaled size; scaling it would move every landmark dot).
## Centred pivots keep each control in place while it grows or
## shrinks, so edge buttons stay on screen at 1.25x and stay
## tappable at 0.8x (the smallest button is still ~60 px across).
## The joystick's drag math is unaffected: _gui_input works in the
## control's local coordinates, which scale with the control.
func _apply_hud_scale() -> void:
	var sm = _sm()
	if sm == null:
		return
	var layer := get_node_or_null("../JoystickLayer") as CanvasLayer
	if layer == null:
		return
	var s: float = clampf(float(sm.get("hud_scale")), 0.8, 1.25)
	for child in layer.get_children():
		if not (child is Control):
			continue
		if child.name == "PausePanel21" or child.name == "WorldMapPanel":
			continue
		var ctl := child as Control
		ctl.pivot_offset = ctl.size * 0.5
		ctl.scale = Vector2(s, s)


func _recolor_part(part_name: String, color: Color) -> void:
	var part = get_node_or_null(part_name) as MeshInstance3D
	if part == null:
		return
	var base = part.get_surface_override_material(0)
	if base == null:
		return
	var mat = base.duplicate() as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = color
	part.set_surface_override_material(0, mat)


## Slice 27: MissionManager access, mirroring the _sm() pattern.
## The manager is a required autoload in-game; callers that run
## before it exists (none in normal play) get null and degrade.
func _mm():
	if _mm_cached != null and is_instance_valid(_mm_cached):
		return _mm_cached
	_mm_cached = get_node_or_null("/root/MissionManager")
	return _mm_cached


## Slice 27: apply a newly granted reward's incremental effect.
## This mirrors the old inline `walk_speed *= ...` lines exactly;
## r1 needs no line here — its stamina blessing is read as a flag.
## Load-time stats come from _apply_reward_stats instead.
func _apply_reward(granted: String) -> void:
	var mm = _mm()
	if mm == null:
		return
	var row = mm.reward_effect(granted)
	if not (row is Dictionary):
		return
	walk_speed *= float(row.get("walk", 1.0))
	sprint_multiplier *= float(row.get("sprint", 1.0))
	jump_velocity *= float(row.get("jump", 1.0))
	if bool(row.get("stamina_refill", false)):
		stamina = 100.0


func _apply_pending_load() -> void:
	var sm = _sm()
	if sm == null:
		return
	var data = sm.get("pending_load")
	if not (data is Dictionary) or data.is_empty():
		return
	sm.set("pending_load", {})
	var p = data.get("player", {})
	if p is Dictionary and p.has("pos"):
		var pos = p.get("pos")
		if pos is Array and pos.size() == 3:
			global_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	if p is Dictionary and p.has("rot_y"):
		rotation.y = float(p.get("rot_y"))
	# Slice 27: mission state (stage, rewards, counters) loads through
	# the manager from the SAME save keys the old code read, so a
	# Slice 26 save maps onto the new manager unchanged.
	var mm = _mm()
	if mm != null:
		var rewards_data = data.get("rewards", {})
		var counters_data = data.get("counters", {})
		if not (rewards_data is Dictionary):
			rewards_data = {}
		if not (counters_data is Dictionary):
			counters_data = {}
		mm.load_state(int(data.get("quest_stage", 0)), rewards_data, counters_data)
		# Slice 54 sightseeing: optional key — a pre-54 save has no
		# "sightseeing" entry and loads as inactive, never an error.
		var sight_data = data.get("sightseeing", {})
		if sight_data is Dictionary:
			mm.call("sightseeing_load_state", sight_data)
		# Slice 60 district quests: optional key, same guard.
		var district_data = data.get("district60", {})
		if district_data is Dictionary:
			mm.call("district60_load_state", district_data)
		# Slice 64 East Fields quests: optional key, same guard.
		var east_data = data.get("eastfields64", {})
		if east_data is Dictionary:
			mm.call("eastfields64_load_state", east_data)
	var garage_data = data.get("garage", {})
	if garage_data is Dictionary:
		garage_vehicle_name = str(garage_data.get("vehicle", ""))
	if data.has("stamina"):
		stamina = clampf(float(data.get("stamina")), 0.0, 100.0)
	var growth = data.get("growth", {})
	if growth is Dictionary:
		crop_growth = int(growth.get("crop", 0))
		rice_growth = int(growth.get("rice", 0))
	if data.has("talked_names"):
		var names = data.get("talked_names")
		if names is Array:
			pending_talked_names = names.duplicate()
	_apply_reward_stats()
	if mm != null:
		last_chime_stage = mm.stage
	_update_quest_label()
	_update_fruit_water_label()

func _apply_reward_stats() -> void:
	walk_speed = 5.0
	sprint_multiplier = 1.6
	jump_velocity = 5.0
	var mm = _mm()
	if mm == null:
		return
	var m = mm.stats_multipliers()
	walk_speed *= float(m["walk"])
	sprint_multiplier *= float(m["sprint"])
	jump_velocity *= float(m["jump"])

func _apply_deferred_load() -> void:
	if pending_growth_applied:
		return
	pending_growth_applied = true
	if crop_growth > 0:
		var s = 1.0 + 0.3 * float(crop_growth)
		for i in range(6):
			var pl = get_node_or_null("../SesameField15/SesamePlant15_%d" % i) as Node3D
			if pl != null:
				pl.scale = Vector3(s, s, s)
	if rice_growth > 0:
		var s2 = 1.0 + 0.3 * float(rice_growth)
		for i in range(6):
			var sd = get_node_or_null("../Paddy18/RiceSeedling18_%d" % i) as Node3D
			if sd != null:
				sd.scale = Vector3(s2, s2, s2)
	if not pending_talked_names.is_empty():
		var villagers = get_tree().get_nodes_in_group("villagers")
		for v in villagers:
			if pending_talked_names.has(v.name):
				var vid = v.get_instance_id()
				if not talked_ids.has(vid):
					talked_ids.append(vid)
		pending_talked_names.clear()
	_update_quest_label()


func _autosave_on_stage_change() -> void:
	var sm = _sm()
	if sm == null:
		return
	var mm = _mm()
	if mm == null:
		return
	if mm.stage == last_saved_stage:
		return
	last_saved_stage = mm.stage
	sm.call("save_game", collect_save_data())

func collect_save_data() -> Dictionary:
	var sm = _sm()
	var muted_now = not sound_on
	var volume_now = 1.0
	if sm != null:
		muted_now = bool(sm.get("muted"))
		volume_now = float(sm.get("volume"))
	var talked_names: Array = []
	for v in get_tree().get_nodes_in_group("villagers"):
		if talked_ids.has(v.get_instance_id()):
			talked_names.append(v.name)
	# Slice 27: mission keys come from the manager; the key names are
	# unchanged ("quest_stage", "rewards" r1..r10, "counters").
	var mm = _mm()
	var stage_now := 0
	var rewards_now := {}
	var counters_now := {}
	if mm != null:
		stage_now = mm.stage
		rewards_now = mm.rewards_dict()
		counters_now = mm.counters_dict()
	# Slice 54 sightseeing: optional side-mission state. A pre-54
	# save has no such key; a Slice 54 save round-trips it, and
	# loading it is guarded in _apply_pending_load.
	var sight_now := {}
	if mm != null:
		sight_now = mm.call("sightseeing_state")
	# Slice 60 garage + district quests: optional keys, same guard
	# pattern — a pre-60 save loads as no-garage / both-undone.
	var garage_now := {"vehicle": garage_vehicle_name}
	var district_now := {}
	if mm != null:
		district_now = mm.call("district60_state")
	# Slice 64 East Fields quests: optional key, same guard pattern.
	var east_now := {}
	if mm != null:
		east_now = mm.call("eastfields64_state")
	# Slice 75 bus route: optional key, same guard pattern —
	# the controller owns the state; a pre-75 save (or a
	# world without the bus yet) saves an empty dict, and
	# the controller restores from the file itself.
	var busroute_now := {}
	var w75 := get_parent() as Node3D
	if w75 != null:
		var bc := w75.get_node_or_null("BusSim74")
		if bc != null and bc.has_method("busroute75_state"):
			busroute_now = bc.call("busroute75_state")
	return {
		"player": {"pos": [global_position.x, global_position.y, global_position.z], "rot_y": rotation.y},
		"quest_stage": stage_now,
		"talked_names": talked_names,
		"stamina": stamina,
		"rewards": rewards_now,
		"counters": counters_now,
		"sightseeing": sight_now,
		"garage": garage_now,
		"district60": district_now,
		"eastfields64": east_now,
		"busroute75": busroute_now,
		"growth": {"crop": crop_growth, "rice": rice_growth},
		"settings": {"muted": muted_now, "volume": volume_now},
	}

func _update_pause_ui() -> void:
	if pause_button == null:
		pause_button = get_node_or_null("../JoystickLayer/PauseButton21") as Button
		if pause_button != null and not pause_button_connected:
			pause_button.pressed.connect(_on_pause_pressed)
			pause_button_connected = true
	if pause_button != null and not get_tree().paused:
		pause_button.visible = true
	if pause_panel == null:
		pause_panel = get_node_or_null("../JoystickLayer/PausePanel21") as Panel
	if resume_button == null:
		resume_button = get_node_or_null("../JoystickLayer/PausePanel21/ResumeButton21") as Button
		if resume_button != null and not resume_button_connected:
			resume_button.pressed.connect(_on_resume_pressed)
			resume_button_connected = true
	if save_button21 == null:
		save_button21 = get_node_or_null("../JoystickLayer/PausePanel21/SaveButton21") as Button
		if save_button21 != null and not save_button21_connected:
			save_button21.pressed.connect(_on_pause_save_pressed)
			save_button21_connected = true
	if pause_settings_button == null:
		pause_settings_button = get_node_or_null("../JoystickLayer/PausePanel21/PauseSettingsButton21") as Button
		if pause_settings_button != null and not pause_settings_button_connected:
			pause_settings_button.pressed.connect(_on_pause_settings_pressed)
			pause_settings_button_connected = true
	if quit_button == null:
		quit_button = get_node_or_null("../JoystickLayer/PausePanel21/QuitButton21") as Button
		if quit_button != null and not quit_button_connected:
			quit_button.pressed.connect(_on_quit_to_menu_pressed)
			quit_button_connected = true
	# Slice 38: stuck recovery lives in the pause menu (touch-first).
	if stuck_button == null:
		stuck_button = get_node_or_null("../JoystickLayer/PausePanel21/StuckButton38") as Button
		if stuck_button != null and not stuck_button_connected:
			stuck_button.pressed.connect(_on_stuck_pressed)
			stuck_button_connected = true
	if save_status_label == null:
		save_status_label = get_node_or_null("../JoystickLayer/PausePanel21/SaveStatusLabel21") as Label
	if pause_settings_panel == null:
		pause_settings_panel = get_node_or_null("../JoystickLayer/PausePanel21/SettingsPanel") as Node


func _on_pause_pressed() -> void:
	if pause_panel == null:
		pause_panel = get_node_or_null("../JoystickLayer/PausePanel21") as Panel
	if pause_panel == null:
		return
	if save_status_label == null:
		save_status_label = get_node_or_null("../JoystickLayer/PausePanel21/SaveStatusLabel21") as Label
	if save_status_label != null:
		save_status_label.text = ""
	if pause_settings_panel != null:
		pause_settings_panel.visible = false
	pause_panel.visible = true
	if pause_button != null:
		pause_button.visible = false
	get_tree().paused = true


func _on_resume_pressed() -> void:
	# Slice 32: re-apply HUD size here so a change made in the
	# pause Settings screen takes effect on resume, no reload.
	_apply_hud_scale()
	get_tree().paused = false
	if pause_panel != null:
		pause_panel.visible = false
	if pause_button != null:
		pause_button.visible = true


func _on_pause_save_pressed() -> void:
	var sm = _sm()
	var ok = false
	if sm != null:
		ok = bool(sm.call("save_game", collect_save_data()))
	if save_status_label == null:
		save_status_label = get_node_or_null("../JoystickLayer/PausePanel21/SaveStatusLabel21") as Label
	if save_status_label != null:
		save_status_label.text = "သိမ်းဆည်းပြီးပါပြီ ✓" if ok else "သိမ်းဆည်း၍ မရပါ"


func _on_pause_settings_pressed() -> void:
	if pause_settings_panel == null:
		pause_settings_panel = get_node_or_null("../JoystickLayer/PausePanel21/SettingsPanel") as Node
	if pause_settings_panel == null:
		return
	pause_settings_panel.visible = true
	if pause_settings_panel.has_method("refresh"):
		pause_settings_panel.call("refresh")


func _on_quit_to_menu_pressed() -> void:
	var sm = _sm()
	if sm != null:
		sm.call("save_game", collect_save_data())
	get_tree().paused = false
	if pause_panel != null:
		pause_panel.visible = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_trumpet() -> void:
	_play_tone(392.0, 0.5)

func _on_feed_elephant() -> void:
	if driving:
		return
	_mm().bump("elephant_feed")
	var res = _mm().advance("feed_elephant")
	if res["reward"] != "":
		_apply_reward(res["reward"])
	if res["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

## Slice 19: gold / lesson / horse-feed buttons + horse whistle.
## Every button is touch-first and lives in the real scene
## (JoystickLayer); the foot buttons show only near their spot,
## the whistle only while driving the horse. No keyboard path
## exists for any of them.
func _update_slice19_buttons() -> void:
	gold_button = _wire17("GoldButton19", gold_button, gold_button_connected, _on_buy_gold)
	if gold_button != null and not gold_button_connected:
		gold_button_connected = true
	lesson_button = _wire17("LessonButton19", lesson_button, lesson_button_connected, _on_lesson)
	if lesson_button != null and not lesson_button_connected:
		lesson_button_connected = true
	feed_horse_button = _wire17("FeedHorseButton19", feed_horse_button, feed_horse_button_connected, _on_feed_horse)
	if feed_horse_button != null and not feed_horse_button_connected:
		feed_horse_button_connected = true
	whistle_button = _wire17("WhistleButton19", whistle_button, whistle_button_connected, _on_whistle)
	if whistle_button != null and not whistle_button_connected:
		whistle_button_connected = true
	if driving:
		if whistle_button != null:
			whistle_button.visible = driving_vehicle != null and driving_vehicle.name in ["Horse", "Horse2"]
		for b in [gold_button, lesson_button, feed_horse_button]:
			if b != null:
				b.visible = false
		return
	if whistle_button != null:
		whistle_button.visible = false
	var stall := _n("../GoldStall19") as Node3D
	if gold_button != null:
		gold_button.visible = stall != null and global_position.distance_to(stall.global_position) < 4.0
	var desk := _n("../TeacherDesk18") as Node3D
	if lesson_button != null:
		lesson_button.visible = desk != null and global_position.distance_to(desk.global_position) < 4.0
	var horse := _n("../Horse") as Node3D
	if feed_horse_button != null:
		feed_horse_button.visible = horse != null and global_position.distance_to(horse.global_position) < 4.0

func _on_buy_gold() -> void:
	if driving:
		return
	_mm().bump("gold")
	if _mm().advance("buy_gold")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_lesson() -> void:
	if driving:
		return
	_mm().bump("lesson")
	if _mm().advance("lesson")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_feed_horse() -> void:
	if driving:
		return
	_mm().bump("horse_feed")
	if _mm().advance("feed_horse")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_whistle() -> void:
	_play_tone(660.0, 0.4)

## Slice 20: night-market + guest-house buttons. Every button is
## touch-first and lives in the real scene (JoystickLayer); the
## foot buttons show only near their spot. No keyboard path exists
## for any of them.
func _update_slice20_buttons() -> void:
	noodle_button = _wire17("NoodleButton20", noodle_button, noodle_button_connected, _on_buy_noodles)
	if noodle_button != null and not noodle_button_connected:
		noodle_button_connected = true
	drink_button = _wire17("DrinkButton20", drink_button, drink_button_connected, _on_buy_drink)
	if drink_button != null and not drink_button_connected:
		drink_button_connected = true
	sleep_button = _wire17("SleepButton20", sleep_button, sleep_button_connected, _on_sleep)
	if sleep_button != null and not sleep_button_connected:
		sleep_button_connected = true
	guestbook_button = _wire17("GuestbookButton20", guestbook_button, guestbook_button_connected, _on_guestbook)
	if guestbook_button != null and not guestbook_button_connected:
		guestbook_button_connected = true
	if driving:
		for b in [noodle_button, drink_button, sleep_button, guestbook_button]:
			if b != null:
				b.visible = false
		return
	var market := _n("../NightMarket20") as Node3D
	if noodle_button != null:
		noodle_button.visible = market != null and global_position.distance_to(market.global_position) < 5.0
	if drink_button != null:
		drink_button.visible = market != null and global_position.distance_to(market.global_position) < 5.0
	var house := _n("../GuestHouse20") as Node3D
	if sleep_button != null:
		sleep_button.visible = house != null and global_position.distance_to(house.global_position) < 4.0
	if guestbook_button != null:
		guestbook_button.visible = house != null and global_position.distance_to(house.global_position) < 4.0

func _on_buy_noodles() -> void:
	if driving:
		return
	_mm().bump("noodle")
	_play_tone(520.0, 0.3)
	if _mm().advance("buy_noodles")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_buy_drink() -> void:
	if driving:
		return
	_mm().bump("drink")
	_play_tone(520.0, 0.3)
	_update_fruit_water_label()

func _on_guestbook() -> void:
	if driving:
		return
	_mm().bump("guestbook")
	if _mm().advance("guestbook")["advanced"]:
		_update_quest_label()
	_update_fruit_water_label()

func _on_sleep() -> void:
	if driving:
		return
	stamina = 100.0
	sleep_timer = 4.0
	var sl := get_node_or_null("../GuestHouse20/SleepLabel20") as Label3D
	if sl != null:
		sl.visible = true
	_play_tone(330.0, 0.5)
	var res = _mm().advance("sleep")
	if res["reward"] != "":
		_apply_reward(res["reward"])
	if res["advanced"]:
		_update_quest_label()
