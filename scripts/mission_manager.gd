extends Node

# --- Data-Driven Mission & Quest Architecture (မစ်ရှင် စနစ်) ---

signal mission_stage_advanced(new_stage, reward_text)

var current_stage: int = 1
var max_stage: int = 6

var mission_data = {
	1: {
		"title": "ရွာသူရွာသားများနှင့် စကားပြောပါ",
		"req_talk": 3,
		"prompt": "ရွာသူရွာသား ၃ ဦးနှင့် မိတ်ဆက်စကားပြောပါ",
		"reward": "ကျေးလက်အသိပညာ ရရှိခြင်း"
	},
	2: {
		"title": "ရွာဦးရွှေစေတီတော်သို့ သွားရောက်ဖူးမြော်ပါ",
		"target_dist": 14.0,
		"prompt": "စေတီတော်ရင်ပြင်သို့ သွားရောက်ကြည်ညိုပါ",
		"reward": "စိတ်အေးချမ်းမှု ရရှိခြင်း"
	},
	3: {
		"title": "ကျောင်းတိုက်ခေါင်းလောင်းတော်သို့ သွားပါ",
		"target_dist": 8.0,
		"prompt": "ကျောင်းတိုက်ခေါင်းလောင်းတော်ကို တွေ့ရှိပါ",
		"reward": "ကုသိုလ်အသံ ကြားသိခြင်း"
	},
	4: {
		"title": "ရွာလယ်လက်ဖက်ရည်ဆိုင်သို့ သွားရောက်အပန်းဖြေပါ",
		"target_dist": 10.0,
		"prompt": "လက်ဖက်ရည်ဆိုင်တွင် ခေတ္တနားနေပါ",
		"reward": "အမောပြေခြင်း"
	},
	5: {
		"title": "ယာဉ် သို့မဟုတ် တိရစ္ဆာန် တစ်မျိုးမျိုးကို မောင်းနှင်စီးနင်းပါ",
		"prompt": "လှည်း/နွား/ကား/ဆိုင်ကယ်/သုံးဘီး/ဆင်/မြင်း/လှေ စီးနင်းပါ",
		"reward": "ခရီးသွားလာမှု ကျွမ်းကျင်ခြင်း"
	},
	6: {
		"title": "ရွာကို လွတ်လပ်စွာ လှည့်လည်နိုင်ပါပြီ",
		"prompt": "တာဝန်အားလုံး ပြီးမြောက် အောင်မြင်ပါပြီ!",
		"reward": "ရွာသူရွာသားများ၏ ချစ်ခင်လေးစားမှု"
	}
}

func get_current_mission() -> Dictionary:
	if mission_data.has(current_stage):
		return mission_data[current_stage]
	return {}

func advance_mission(from_stage: int) -> bool:
	if current_stage == from_stage and current_stage < max_stage:
		current_stage += 1
		var reward_text = mission_data[current_stage].get("reward", "")
		mission_stage_advanced.emit(current_stage, reward_text)
		
		# Auto-save mission progress
		var save_mgr = get_node_or_null("/root/SaveManager")
		var player = get_tree().get_first_node_in_group("player")
		if save_mgr and player:
			save_mgr.save_game(player.global_position, current_stage, 3, player.stamina)
		return true
	return false