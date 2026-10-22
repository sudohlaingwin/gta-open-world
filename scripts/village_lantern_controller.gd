extends Node3D

# --- Village Streetlight & Lantern Day/Night Auto-Switching ---
# Automatically turns on amber lanterns during evening/night (daylight < 0.4)
# and dims them during bright midday to optimize mobile GPU performance.

@export var max_light_energy: float = 1.8
@export var night_threshold: float = 0.4

var omni_lights: Array[OmniLight3D] = []
var emissive_meshes: Array[MeshInstance3D] = []
var day_night_node: Node = null

func _ready() -> void:
	day_night_node = get_tree().get_first_node_in_group("day_night")
	_find_lights_and_lanterns(self)
	_update_lighting_state(1.0)

func _find_lights_and_lanterns(parent: Node) -> void:
	for child in parent.get_children():
		if child is OmniLight3D:
			omni_lights.append(child)
		elif child is MeshInstance3D and ("Lamp" in child.name or "Lantern" in child.name):
			emissive_meshes.append(child)
		_find_lights_and_lanterns(child)

func _process(_delta: float) -> void:
	if not day_night_node:
		day_night_node = get_tree().get_first_node_in_group("day_night")
		if not day_night_node:
			return

	var daylight = 1.0
	if day_night_node.has_method("get_daylight"):
		daylight = day_night_node.get_daylight()
	
	_update_lighting_state(daylight)

func _update_lighting_state(daylight: float) -> void:
	var is_night = daylight < night_threshold
	var target_energy = max_light_energy * (1.0 - daylight) if is_night else 0.0

	for light in omni_lights:
		light.visible = is_night
		if is_night:
			light.light_energy = target_energy

	for mesh in emissive_meshes:
		var mat = mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_enabled = is_night
