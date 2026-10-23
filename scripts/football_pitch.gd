extends StaticBody3D

@onready var football: RigidBody3D = $FootballRigid
var initial_ball_pos: Vector3 = Vector3(0, 0.45, 0)
var score_count: int = 0

func _physics_process(delta: float) -> void:
	if not football:
		return
	
	# Goal detection (Left goal x < -32.0, Right goal x > 32.0 within z bounds -3.6 to 3.6)
	var b_pos = football.position
	if abs(b_pos.z) < 3.7:
		if b_pos.x < -32.0 or b_pos.x > 32.0:
			score_count += 1
			football.position = initial_ball_pos
			football.linear_velocity = Vector3.ZERO
			football.angular_velocity = Vector3.ZERO
			
			var hud = get_tree().get_first_node_in_group("hud")
			if not hud:
				hud = get_parent().get_node_or_null("MobileTouchHUD")
			if hud and hud.has_method("_show_prompt"):
				hud._show_prompt("⚽ ဂိုးသွင်းယူနိုင်ခဲ့ပါပြီ! (စုစုပေါင်းဂိုး: %d)" % score_count)