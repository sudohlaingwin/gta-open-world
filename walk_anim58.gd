extends Node
## Slice 58 walk animator (runtime child of Player and each villager).
## Added by character_dress58.gd after the shoulder/hip/longyi pivots
## exist, so _ready can cache them. Every _process it reads the
## parent body's horizontal speed and swings arms opposite, legs
## opposite to their arm, and the longyi hem slightly. While the
## parent is driving a vehicle (player driving flag) or idle, the
## swing eases back to zero instead of snapping. Visual only: it
## never touches velocity, position, or collision.

var _phase: float = 0.0
var _idle_phase: float = 0.0  # Slice 61 addendum: idle breathing phase.
var _amp: float = 0.0
var _arm_r: Node3D = null
var _arm_l: Node3D = null
var _leg_r: Node3D = null
var _leg_l: Node3D = null
var _longyi: Node3D = null


func _ready() -> void:
	var p := get_parent() as Node3D
	if p == null:
		return
	_arm_r = p.get_node_or_null("ShoulderPivot58_R") as Node3D
	_arm_l = p.get_node_or_null("ShoulderPivot58_L") as Node3D
	_leg_r = p.get_node_or_null("HipPivot58_R") as Node3D
	_leg_l = p.get_node_or_null("HipPivot58_L") as Node3D
	_longyi = p.get_node_or_null("LongyiPivot58") as Node3D


func _process(delta: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var speed := 0.0
	if parent is CharacterBody3D:
		var v := (parent as CharacterBody3D).velocity
		speed = Vector2(v.x, v.z).length()
	var driving: Variant = parent.get("driving")
	var target := 0.0
	if driving == true or speed <= 0.2:
		# Slice 61 addendum (owner 00:03: "dry/stiff"): idle breathing
		# — arms sway gently, longyi hem moves slightly, legs still.
		# This runs ONLY when not walking/driving, so walk swing and
		# idle sway never fight (walking branch below is untouched).
		_idle_phase += delta * 1.5
		var ib := sin(_idle_phase) * 0.06
		if _arm_r != null:
			_arm_r.rotation.x = ib
		if _arm_l != null:
			_arm_l.rotation.x = -ib
		if _leg_r != null:
			_leg_r.rotation.x = 0.0
		if _leg_l != null:
			_leg_l.rotation.x = 0.0
		if _longyi != null:
			_longyi.rotation.x = sin(_idle_phase) * 0.01
		_amp = move_toward(_amp, 0.0, delta * 4.0)
		return
	if driving != true and speed > 0.2:
		_phase += delta * (4.0 + speed * 1.8)
		target = 1.0
	_amp = move_toward(_amp, target, delta * 4.0)
	var s := sin(_phase) * 0.45 * _amp
	if _arm_r != null:
		_arm_r.rotation.x = s
	if _arm_l != null:
		_arm_l.rotation.x = -s
	if _leg_r != null:
		_leg_r.rotation.x = -s * 0.7
	if _leg_l != null:
		_leg_l.rotation.x = s * 0.7
	if _longyi != null:
		_longyi.rotation.x = -s * 0.12
