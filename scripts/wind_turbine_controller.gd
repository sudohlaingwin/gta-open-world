extends StaticBody3D

# --- Mountain Wind Turbine Rotor & Aviation Beacon Controller ---
# Adds majestic cinematic scale to mountain ridges for chilling open-world drives

@export var rotor_speed_rpm: float = 8.5 # Majestic slow rotation (approx 0.89 rad/s)
@onready var rotor_hub: Node3D = get_node_or_null("VisualMesh/Nacelle/RotorHub")
@onready var beacon_light: OmniLight3D = get_node_or_null("VisualMesh/Nacelle/BeaconLight")
@onready var beacon_mesh: MeshInstance3D = get_node_or_null("VisualMesh/Nacelle/BeaconMesh")

var rot_speed_rad: float = 0.0
var beacon_timer: float = 0.0

func _ready() -> void:
	rot_speed_rad = (rotor_speed_rpm * TAU) / 60.0
	# Give each turbine a slight phase offset based on world position
	if rotor_hub:
		rotor_hub.rotation.z = fposmod(global_position.x * 0.05 + global_position.z * 0.03, TAU)
	beacon_timer = fposmod(global_position.x * 0.1, 2.0)

func _process(delta: float) -> void:
	# Smooth continuous aerodynamic rotation
	if rotor_hub:
		rotor_hub.rotate_z(rot_speed_rad * delta)

	# Aviation hazard warning red beacon pulse
	beacon_timer += delta
	var pulse = sin(beacon_timer * 3.14159)
	var is_flashing = pulse > 0.4

	if beacon_light:
		beacon_light.visible = is_flashing
	if beacon_mesh:
		var mat = beacon_mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission_energy_multiplier = 4.0 if is_flashing else 0.4
