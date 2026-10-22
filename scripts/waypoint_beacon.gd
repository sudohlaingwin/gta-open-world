extends Node3D

# --- Waypoint Beacon Vertical Beam Pulse Animation ---
@onready var light_pillar: MeshInstance3D = $LightPillar
@onready var beacon_head: MeshInstance3D = $BeaconHead

var time_accum: float = 0.0

func _process(_delta: float) -> void:
	if not visible:
		return
	var t_sec = float(Time.get_ticks_msec()) / 1000.0
	# Pulsing beacon head scale and bob (synchronized with world map beacon radar)
	var pulse = 1.0 + sin(t_sec * 4.0) * 0.18
	if beacon_head:
		beacon_head.scale = Vector3(pulse, pulse, pulse)
		beacon_head.position.y = 28.0 + sin(t_sec * 2.5) * 0.8

	# Pulsing pillar light alpha
	if light_pillar:
		var mat = light_pillar.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color.a = 0.65 + sin(t_sec * 3.0) * 0.25
