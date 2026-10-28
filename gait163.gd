extends Node
## Slice 163 gait animator — REPLACES WalkAnim58 on walking figures.
## One phase drives shoulder / hip / elbow / knee / ankle / torso /
## longyi, so every joint stays phase-locked (WalkAnim58's single
## sine could never bend an elbow or a knee: its arms and legs were
## rigid planks pivoting at shoulder/hip only).
## SIGN CONVENTION (same as walk_anim58, verified from its code):
## rotation.x POSITIVE swings a hanging limb BACKWARD (-z);
## NEGATIVE swings it FORWARD (+z). Hence arm_R back while leg_R
## forward is counter-phase, as in real gait.
## KNEE CURVE: flexion peaks MID-SWING (leg passing vertical, foot
## clearing ground) and returns to ~0 at foot plant: flex =
## KNEE * max(0, cos(phase)) on the swinging side, 0 in stance.
## ELBOW CURVE: the arm bends more as it swings FORWARD and
## extends as it swings back: bend = ELBOW0 + ELBOW * forward-share.
## LONGYI STRIDE IS DELIBERATELY SHORT (hip 0.26 rad, not a
## trouser 0.35): real longyi wearers take shorter steps, and the
## shorter stride reads MORE real, not less. The sim gates it.
## IDLE: eases to rest (arms at sides with the natural 0.25 rest
## bend, legs straight) + near-still breathing (S70 levels), never
## a snap. While driving, the figure also rests (seated, legs
## hidden by the vehicle anyway). Visual only: never touches
## velocity, position, or collision. Per-frame work is ~12 rotation
## writes on cached nodes per figure, no tree walks, no allocation.

const ARM: float = 0.38
const HIP: float = 0.26
const KNEE: float = 0.95
const ELBOW0: float = 0.25
const ELBOW: float = 0.35
const TWIST: float = 0.07
const BOB: float = 0.012
const LONGYI_X: float = 0.06
const LONGYI_Z: float = 0.03
const IDLE_ARM: float = 0.025
const IDLE_LG: float = 0.005

var _phase: float = 0.0
var _idle_phase: float = 0.0
var _amp: float = 0.0
var _fig: Node3D = null
var _torso: Node3D = null
var _sh_r: Node3D = null
var _sh_l: Node3D = null
var _el_r: Node3D = null
var _el_l: Node3D = null
var _hip_r: Node3D = null
var _hip_l: Node3D = null
var _knee_r: Node3D = null
var _knee_l: Node3D = null
var _ank_r: Node3D = null
var _ank_l: Node3D = null
var _longyi: Node3D = null


func _ready() -> void:
	var body := get_parent() as Node3D
	if body == null:
		return
	_fig = body.get_node_or_null("Figure163") as Node3D
	if _fig == null:
		return
	_torso = _fig.get_node_or_null("TorsoPivot163") as Node3D
	if _torso != null:
		_sh_r = _torso.get_node_or_null("ShoulderPivot58_R") as Node3D
		_sh_l = _torso.get_node_or_null("ShoulderPivot58_L") as Node3D
	if _sh_r != null:
		_el_r = _sh_r.get_node_or_null("ElbowPivot163") as Node3D
	if _sh_l != null:
		_el_l = _sh_l.get_node_or_null("ElbowPivot163") as Node3D
	_hip_r = _fig.get_node_or_null("HipPivot58_R") as Node3D
	_hip_l = _fig.get_node_or_null("HipPivot58_L") as Node3D
	if _hip_r != null:
		_knee_r = _hip_r.get_node_or_null("KneePivot163") as Node3D
	if _hip_l != null:
		_knee_l = _hip_l.get_node_or_null("KneePivot163") as Node3D
	if _knee_r != null:
		_ank_r = _knee_r.get_node_or_null("AnklePivot163") as Node3D
	if _knee_l != null:
		_ank_l = _knee_l.get_node_or_null("AnklePivot163") as Node3D
	_longyi = _fig.get_node_or_null("LongyiPivot58") as Node3D


func _process(delta: float) -> void:
	var parent := get_parent()
	if parent == null or _fig == null:
		return
	var speed := 0.0
	if parent is CharacterBody3D:
		var v := (parent as CharacterBody3D).velocity
		speed = Vector2(v.x, v.z).length()
	var driving: Variant = parent.get("driving")
	var walking: bool = driving != true and speed > 0.2
	if walking:
		_phase += delta * (4.0 + speed * 1.8)
		_amp = move_toward(_amp, 1.0, delta * 4.0)
	else:
		_idle_phase += delta * 1.2
		_amp = move_toward(_amp, 0.0, delta * 4.0)
	_apply_pose(sin(_phase), cos(_phase), _amp, sin(_idle_phase))


## The pose function, separated so a sim can sweep it across a full
## cycle deterministically (phase-sweep proves the joint curves;
## live frames prove the phase actually advances in real time).
func _apply_pose(s: float, c: float, a: float, ib: float) -> void:
	var sh_r := ARM * s * a + IDLE_ARM * ib * (1.0 - a)
	var sh_l := -ARM * s * a - IDLE_ARM * ib * (1.0 - a)
	var hip_r := -HIP * s * a
	var hip_l := HIP * s * a
	var knee_r := KNEE * maxf(0.0, c) * a
	var knee_l := KNEE * maxf(0.0, -c) * a
	var elb_r := -(ELBOW0 + ELBOW * maxf(0.0, -s) * a)
	var elb_l := -(ELBOW0 + ELBOW * maxf(0.0, s) * a)
	var ank_r := -(hip_r + knee_r) * 0.4
	var ank_l := -(hip_l + knee_l) * 0.4
	if _sh_r != null:
		_sh_r.rotation.x = sh_r
	if _sh_l != null:
		_sh_l.rotation.x = sh_l
	if _el_r != null:
		_el_r.rotation.x = elb_r
	if _el_l != null:
		_el_l.rotation.x = elb_l
	if _hip_r != null:
		_hip_r.rotation.x = hip_r
	if _hip_l != null:
		_hip_l.rotation.x = hip_l
	if _knee_r != null:
		_knee_r.rotation.x = knee_r
	if _knee_l != null:
		_knee_l.rotation.x = knee_l
	if _ank_r != null:
		_ank_r.rotation.x = ank_r
	if _ank_l != null:
		_ank_l.rotation.x = ank_l
	if _torso != null:
		_torso.rotation.y = TWIST * s * a
		_torso.position.y = BOB * absf(s) * a
	if _longyi != null:
		# Lagged sway derived from (s, c) — NOT from the member
		# _phase — so _apply_pose is a pure function of its inputs
		# and a phase sweep measures the true sway curve. In-game
		# s = sin(_phase), c = cos(_phase), so this is identical
		# to sin(_phase - 0.6): sin(a-b) = sin a cos b - cos a sin b.
		var lg_s: float = s * cos(0.6) - c * sin(0.6)
		_longyi.rotation.x = LONGYI_X * lg_s * a + IDLE_LG * ib * (1.0 - a)
		_longyi.rotation.z = LONGYI_Z * s * a
