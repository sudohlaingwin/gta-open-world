extends Node3D

# --- Waypoint Beacon Vertical Beam Pulse Animation ---
@onready var light_pillar: MeshInstance3D = $LightPillar
@onready var beacon_head: MeshInstance3D = $BeaconHead

var time_accum: float = 0.0

func _process(delta: float) -> void:
	if not visible:
		return
	time_accum += delta
	# Pulsing beacon head scale and bob
	var pulse = 1.0 + sin(time_accum * 4.0) * 0.18
	if beacon_head:
		beacon_head.scale = Vector3(pulse, pulse, pulse)
		beacon_head.position.y = 28.0 + sin(time_accum * 2.5) * 0.8

	# Pulsing pillar light alpha
	if light_pillar:
		var mat = light_pillar.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color.a = 0.65 + sin(time_accum * 3.0) * 0.25
