extends Node3D

func _ready() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("load_game"):
		var data = save_mgr.load_game()
		if not data.is_empty():
			var player = get_tree().get_first_node_in_group("player")
			if player and data.has("pos_x"):
				player.global_position = Vector3(data["pos_x"], data["pos_y"], data["pos_z"])
				if data.has("stamina"):
					player.stamina = float(data["stamina"])
			
			var hud = get_tree().get_first_node_in_group("hud")
			if not hud:
				hud = get_node_or_null("MobileTouchHUD")
			if hud:
				if data.has("quest_stage"):
					hud.quest_stage = int(data["quest_stage"])
				if data.has("villagers_talked"):
					hud.villagers_talked_count = int(data["villagers_talked"])
				if hud.has_method("_update_quest_text"):
					hud._update_quest_text()