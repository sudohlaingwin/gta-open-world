## Slice 49: ONE shared world<->map transform for every map surface.
## Re-scope finding (audit item 6, verified by code reading + a headless
## probe on the pre-change tree): the audit's "+-50 m" complaint was
## already half-fixed by Slice 37 (world map re-centred to centre x 90 /
## span 320), but TWO live defects remained, both in the transform:
## 1. The minimap (player.gd put()) applied the X mapping to Z as well:
##    (wpos.z + 70.0) / 320.0 * 170.0 treats Z as if it spanned
##    -70..250 (the X range) instead of the real -110..110. The whole
##    northern strip (z -110..-70) pinned to the panel's top edge, and
##    the village centre (z 0) sat at 37 px of 170 (22% down) instead of
##    centred. The minimap and the world map DISAGREED on Z for the
##    same world point. The 170 px panel size was also stale: the
##    MinimapPanel is anchor-relative (0.84-0.98 x 0.09-0.34 of the
##    viewport), so on a real phone it is not 170 px at all (179x180
##    in the headless 1280x720 probe) and dots clustered in the
##    panel's top-left corner.
## 2. The world map (world_map.gd) placed its markers in the WRONG
##    coordinate space: world_to_map returned OVERLAY coordinates
##    (centre includes _map_area.position) but the dots are children
##    of _map_area, so their positions are read as AREA-LOCAL. The
##    probe proved it exactly: the pagoda dot's global position was
##    (750.55, 654.23) against an expected screen position of
##    (427.15, 461.23) — off by (323.4, 193.0), exactly
##    _map_area.position (330.4, 200) minus the 7 px dot half-size.
##    Dots were displaced down-right and clipped at the area edge.
##    The tap path had the mirror-image bug: _gui_input delivers
##    AREA-LOCAL positions, but map_to_world treated them as overlay
##    coordinates, so a tap on empty map landed ~171 m west / ~69 m
##    north of the finger at zoom 1 on a 1920x1080 screen. (Tapping
##    exactly on a displaced dot round-tripped by accident, because
##    the two offsets cancel — which is why the feature looked alive
##    while the map itself rendered wrong.)
## This file fixes both by construction: one fit-the-rect transform,
## bounds read from the live ground plane, area-local coordinates
## for every map surface. The world map's on-screen mapping for a
## square area is PIXEL-IDENTICAL to the old formula (same scale,
## same centre, same zoom-about-centre + pan); only the coordinate
## space is corrected and the tap clamp is tightened to the ground
## rect (taps in the old square region's void bands used to place a
## beacon at z up to +-160, beyond the ground plane, where the
## player can never walk — they now clamp to the ground edge).
## Guidance (Slice 34) and the beacon use raw world coordinates and
## are untouched by this file.
class_name MapTransform
extends RefCounted

## Fallback bounds: the actual ground rect from main.tscn
## (GroundMesh PlaneMesh 320x220 at (90, 0, 0) -> x -70..250,
## z -110..110). Used only if configure_from_ground never runs;
## in the live game it always runs at world spawn (player._ready)
## and again whenever the world map opens, so the scene is the
## single source of truth and this fallback is never consulted.
static var min_x: float = -70.0
static var max_x: float = 250.0
static var min_z: float = -110.0
static var max_z: float = 110.0
static var configured: bool = false


## Reads the bounds from a ground MeshInstance3D: PlaneMesh size
## maps to world x/z spans (times the node's global scale), and the
## node's global position is the rect centre. Returns false (and
## keeps the previous bounds) when anything is missing or degenerate.
static func configure_from_ground(ground: Node3D) -> bool:
	if ground == null:
		return false
	var mi := ground as MeshInstance3D
	if mi == null:
		return false
	var plane := mi.mesh as PlaneMesh
	if plane == null:
		return false
	var sx := plane.size.x * mi.global_transform.basis.x.length()
	var sz := plane.size.y * mi.global_transform.basis.z.length()
	if sx <= 0.0 or sz <= 0.0:
		return false
	var c := mi.global_position
	min_x = c.x - sx * 0.5
	max_x = c.x + sx * 0.5
	min_z = c.z - sz * 0.5
	max_z = c.z + sz * 0.5
	configured = true
	return true


## World metres -> panel-local pixels. The world rect is fitted
## into the panel preserving aspect: the scale is limited by the
## tighter axis and the shorter axis is centred, so a square panel
## shows the 320x220 world with void bands top/bottom (exactly the
## old world map's square-region rendering) and a non-square panel
## never stretches the world.
static func world_to_panel(wx: float, wz: float, panel_size: Vector2) -> Vector2:
	var span_x := max_x - min_x
	var span_z := max_z - min_z
	if panel_size.x <= 0.0 or panel_size.y <= 0.0 or span_x <= 0.0 or span_z <= 0.0:
		return Vector2.ZERO
	var s := minf(panel_size.x / span_x, panel_size.y / span_z)
	var off := (panel_size - Vector2(span_x, span_z) * s) * 0.5
	return off + Vector2(wx - min_x, wz - min_z) * s


## Panel-local pixels -> world metres, clamped to the ground rect
## (a tap in a void band lands on the ground edge, never in the void
## beyond the plane where the player cannot walk).
static func panel_to_world(px: float, py: float, panel_size: Vector2) -> Vector2:
	var span_x := max_x - min_x
	var span_z := max_z - min_z
	if panel_size.x <= 0.0 or panel_size.y <= 0.0 or span_x <= 0.0 or span_z <= 0.0:
		return Vector2.ZERO
	var s := minf(panel_size.x / span_x, panel_size.y / span_z)
	var off := (panel_size - Vector2(span_x, span_z) * s) * 0.5
	var w := (Vector2(px, py) - off) / s
	return Vector2(clampf(w.x + min_x, min_x, max_x), clampf(w.y + min_z, min_z, max_z))


## Keeps a marker dot fully inside its panel (dot_size is the dot's
## own size, so no panel-size or dot-size literal lives anywhere).
static func clamp_dot(pos: Vector2, panel_size: Vector2, dot_size: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, 0.0, maxf(panel_size.x - dot_size.x, 0.0)),
		clampf(pos.y, 0.0, maxf(panel_size.y - dot_size.y, 0.0)))
