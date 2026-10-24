extends Node3D

# --- Traditional Myanmar Bamboo Irrigation Noria Waterwheel ---
# Rotates continuously with river current and triggers rhythmic splashing churn audio

@onready var wheel_pivot: Node3D = get_node_or_null("WheelPivot")
var churn_audio_player: AudioStreamPlayer3D = null

func _ready() -> void:
	churn_audio_player = get_node_or_null("ChurnAudio") as AudioStreamPlayer3D
	if churn_audio_player:
		churn_audio_player.unit_size = 8.0
		churn_audio_player.max_distance = 45.0
		churn_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE_SQUARED

func _process(delta: float) -> void:
	if wheel_pivot:
		# Smooth continuous hydraulic rotation
		wheel_pivot.rotate_z(-delta * 0.42)
