extends Node3D
## Slice 112: flag wave (genuine gap — both flags were static
## meshes: school Flag99 from Slice 98, post-office Flag106_Post
## from Slice 105; no wave code existed anywhere). The two flags
## flutter gently every frame once this pass applies (frame >=
## 460 pass, after realism112's 440). Runtime dressing only:
## no scene touched, no new nodes except this pass's own node,
## zero colliders, no position changes (rotation only, so poles
## and clearances are untouched). School flag + post flag only;
## no other banners exist to wave.
var _frames := 0
var _done := false
var _flags: Array = []

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism113") != null:
		return
	var n := Node3D.new()
	n.name = "Realism113"
	n.set_script(load("res://realism113.gd"))
	world.call_deferred("add_child", n)

func _find_recursive(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f := _find_recursive(c, nm)
		if f != null:
			return f
	return null

func _apply(world: Node3D) -> void:
	for nm in ["Flag99", "Flag106_Post"]:
		var f := _find_recursive(world, nm)
		if f != null:
			_flags.append(f)

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 460:
		_done = true
		_apply(get_parent() as Node3D)
	if not _done:
		return
	var t := Time.get_ticks_msec() / 1000.0
	for f in _flags:
		(f as Node3D).rotation.y = sin(t * 3.0) * 0.25
