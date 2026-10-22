extends Label
## Audit item 4: real measured-FPS readout. This label shows ONLY the
## engine's measured frames per second — never a hardcoded, estimated,
## or target number. Smoothing: frames are counted over a ~0.5 s window
## and the shown value is frames/window, rounded, so the number reads
## stably instead of flickering every frame. The current graphics-quality
## level (from SaveManager) rides along so a device report can say
## which quality the number was measured at.
## Visibility is self-managed: the label reads SaveManager.fps_visible
## every frame, so toggling it in Settings (menu or pause) shows/hides
## it with no extra wiring. process_mode is ALWAYS (set in _ready), so
## the readout keeps updating while the game is paused — and says so
## honestly with a (ရပ်) marker instead of showing a frozen number as
## if play were still running. Headless FPS is meaningless (the dummy
## renderer) and must NEVER be reported as a device result; real
## numbers await the owner's vivo V60 test.

var _accum: float = 0.0
var _frames: int = 0
var _shown: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	visible = sm != null and bool(sm.get("fps_visible"))
	if not visible:
		return
	_accum += delta
	_frames += 1
	if _accum >= 0.5:
		_shown = int(round(float(_frames) / _accum))
		_accum = 0.0
		_frames = 0
	var quality_text: String = "မြင့်"
	if sm != null and int(sm.get("graphics_quality")) == 1:
		quality_text = "နိမ့်"
	if get_tree().paused:
		text = "FPS: %d (ရပ်) · %s" % [_shown, quality_text]
	else:
		text = "FPS: %d · %s" % [_shown, quality_text]
