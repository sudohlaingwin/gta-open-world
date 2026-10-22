extends Node
## Universal Myanmar Font Autoload & Scene Tree Stylist
## Ensures all 2D UI Controls and 3D Label3D nodes render authentic
## Myanmar Unicode glyphs without tofu boxes or glyph truncation.

const MYANMAR_FONT_PATH := "res://fonts/NotoSansMyanmar-Regular.ttf"
var myanmar_font: Font = null

func _ready() -> void:
	if ResourceLoader.exists(MYANMAR_FONT_PATH):
		myanmar_font = load(MYANMAR_FONT_PATH) as Font
	
	if not myanmar_font:
		push_error("MyanmarFontAutoload: Failed to load font at " + MYANMAR_FONT_PATH)
		return

	# Style current tree and listen for dynamically spawned scenes
	get_tree().node_added.connect(_on_node_added)
	_style_node_recursive(get_tree().root)

func _on_node_added(node: Node) -> void:
	if not myanmar_font:
		return
	_apply_font_to_node(node)

func _style_node_recursive(node: Node) -> void:
	if not node:
		return
	_apply_font_to_node(node)
	for child in node.get_children():
		_style_node_recursive(child)

func _apply_font_to_node(node: Node) -> void:
	if not myanmar_font:
		return
	
	# Apply to 3D text nodes
	if node is Label3D:
		var l3d = node as Label3D
		if l3d.font == null:
			l3d.font = myanmar_font
	
	# Apply to 2D UI Control nodes if they display text
	elif node is Label:
		var lbl = node as Label
		if not lbl.has_theme_font_override("font"):
			lbl.add_theme_font_override("font", myanmar_font)
	elif node is Button:
		var btn = node as Button
		if not btn.has_theme_font_override("font"):
			btn.add_theme_font_override("font", myanmar_font)
	elif node is LineEdit:
		var le = node as LineEdit
		if not le.has_theme_font_override("font"):
			le.add_theme_font_override("font", myanmar_font)
	elif node is TextEdit:
		var te = node as TextEdit
		if not te.has_theme_font_override("font"):
			te.add_theme_font_override("font", myanmar_font)
	elif node is RichTextLabel:
		var rtl = node as RichTextLabel
		if not rtl.has_theme_font_override("normal_font"):
			rtl.add_theme_font_override("normal_font", myanmar_font)
	elif node is OptionButton:
		var ob = node as OptionButton
		if not ob.has_theme_font_override("font"):
			ob.add_theme_font_override("font", myanmar_font)
	elif node is CheckButton:
		var cb = node as CheckButton
		if not cb.has_theme_font_override("font"):
			cb.add_theme_font_override("font", myanmar_font)
	elif node is CheckBox:
		var chk = node as CheckBox
		if not chk.has_theme_font_override("font"):
			chk.add_theme_font_override("font", myanmar_font)
