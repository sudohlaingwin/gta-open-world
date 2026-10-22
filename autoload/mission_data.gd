extends RefCounted
## Slice 27 mission data: the quest chain as DATA, not code.
## Stage texts, tracker names and done texts below are copied
## byte-for-byte from the Slice 10-20 quest chain in player.gd;
## only their home moved. Stage 0 and 7 labels are dynamic
## (talked/total, banana count) and are built by label_text().
##
## NEW-MISSION FORMAT (fields a future mission entry needs):
## id: unique trigger name; from_stage/to_stage: the chain link;
## reward: "" or r1..r10; title: tracker word; label: quest text;
## waypoint: Vector2 world position or null; timer_seconds: 0 = none;
## checkpoints: [] of Vector2 (empty = none). Timer/waypoint/
## checkpoint fields exist in the format now but are NOT live
## systems yet — no mission uses them until one is built.
## Worked example (NOT activated — duplicates stage 1 exactly):
## {"id": "example_visit_pagoda", "from_stage": 1, "to_stage": 2,
##  "reward": "", "title": "example", "label": "example",
##  "waypoint": null, "timer_seconds": 0, "checkpoints": []}

# Tracker words, one per stage 0..35, in chain order.
const STAGE_TITLES: Array[String] = [
	"စကားပြော",
	"ဘုရားဖူး",
	"ယာဉ်စီး",
	"ခေါင်းလောင်း",
	"သစ်သီးဝယ်",
	"ရေဆွဲ",
	"မုခ်ဦးဖြတ်",
	"ငှက်ပျောခူး",
	"ဝါးတံတားဖြတ်",
	"ဟင်္သာဆုတောင်း",
	"လက်ဖက်ရည်မှာစား",
	"စာအုပ်လှူ",
	"စက်ဘီးစီး",
	"သုံးဘီးစီး",
	"လေထီးဆင်း",
	"ဗုံတီး",
	"ငါးဖမ်း",
	"အလှူပေး",
	"နို့ညှစ်",
	"ရေလောင်း",
	"အစာကျွေး",
	"ဆင်စီး",
	"ပန်းကပ်",
	"စပါးစိုက်",
	"ခုံတန်းနား",
	"ဆင်အစာကျွေး",
	"မြင်းစီး",
	"ရွှေဝယ်",
	"စာသင်ခန်း",
	"မြင်းအစာကျွေး",
	"ရေကန်အိမ်",
	"ဒုတိယလှေစီး",
	"ဒုတိယမြင်းစီး",
	"ခေါက်ဆွဲဝယ်",
	"ဧည့်စာရင်းထိုး",
	"တည်းခိုခန်းအိပ်",
]

# Quest-label texts for stages 1..35 (index 0 = stage 1).
const STAGE_LABELS: Array[String] = [
	"တာဝန်: ဘုရားကို သွားပါ",
	"တာဝန်: ယာဉ်တစ်စီး စီးပါ",
	"တာဝန်: ခေါင်းလောင်းထိုးပါ",
	"တာဝန်: ဈေးက သစ်သီးဝယ်ပါ",
	"တာဝန်: ရေတွင်းက ရေဆွဲပါ",
	"တာဝန်: ရွာမုခ်ဦးကို ဖြတ်သန်းပါ",
	"တာဝန်: ငှက်ပျောသီး ခူးပါ (",
	"တာဝန်: ဝါးတံတားကို ဖြတ်ပါ",
	"တာဝန်: ဟင်္သာရုပ်တုမှာ ဆုတောင်းပါ",
	"တာဝန်: လက်ဖက်ရည်ဆိုင်မှာ လက်ဖက်ရည်မှာပါ",
	"တာဝန်: ကျောင်းကို စာအုပ်လှူပါ",
	"တာဝန်: စက်ဘီးစီးပါ",
	"တာဝန်: သုံးဘီးစီးပါ",
	"တာဝန်: လေထီးနဲ့ မြေပြင်ကို ဆင်းပါ",
	"တာဝန်: ပွဲတော်မှာ ဗုံတီးပါ",
	"တာဝန်: မြစ်မှာ ငါးဖမ်းပါ",
	"တာဝန်: ဘုရားမှာ အလှူပေးပါ",
	"တာဝန်: နွားနို့ ညှစ်ပါ",
	"တာဝန်: သီးနှံခင်းကို ရေလောင်းပါ",
	"တာဝန်: ကြက်တွေကို အစာကျွေးပါ",
	"တာဝန်: ဆင်စီးပါ",
	"တာဝန်: ဘုရားမှာ ပန်းကပ်ပါ",
	"တာဝန်: စပါးစိုက်ပါ",
	"တာဝန်: ခုံတန်းမှာ နားပါ",
	"တာဝန်: ဆင်ကို အစာကျွေးပါ",
	"တာဝန်: မြင်းစီးပါ",
	"တာဝန်: ရွှေဆိုင်မှာ ရွှေဝယ်ပါ",
	"တာဝန်: ကျောင်းမှာ စာသင်ခန်း တက်ပါ",
	"တာဝန်: မြင်းကို အစာကျွေးပါ",
	"တာဝန်: ရေကန်အိမ်ကို သွားပါ",
	"တာဝန်: ဒုတိယလှေစီးပါ",
	"တာဝန်: ဒုတိယမြင်းစီးပါ",
	"တာဝန်: ညဈေးမှာ ခေါက်ဆွဲဝယ်ပါ",
	"တာဝန်: တည်းခိုခန်းမှာ ဧည့်စာရင်းထိုးပါ",
	"တာဝန်: တည်းခိုခန်းမှာ အိပ်ပါ",
]

# Done texts for stage >= 36, in elif order r10 down to r1.
const DONE_TEXTS: Array[String] = [
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10% + ခုန်အား +10% + ခုန်အား ထပ် +10% + လမ်းလျှောက် ထပ် +5% + လမ်းလျှောက် ထပ် +5% + လမ်းလျှောက် ထပ် +5% + ခုန်အား ထပ် +10%",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10% + ခုန်အား +10% + ခုန်အား ထပ် +10% + လမ်းလျှောက် ထပ် +5% + လမ်းလျှောက် ထပ် +5%",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10% + ခုန်အား +10% + ခုန်အား ထပ် +10% + လမ်းလျှောက် ထပ် +5%",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10% + ခုန်အား +10% + ခုန်အား ထပ် +10%",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10% + ခုန်အား +10%",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် + အပြေးမြန် +10%",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် +5% + ဆုတောင်း",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန် +5%",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့် + လမ်းလျှောက်မြန်",
	"တာဝန်များ ပြီးပါပြီ! ဆုလာဘ်: အားအမြန်ပြည့်",
]

const DONE_TEXT_NONE: String = "တာဝန်များ အားလုံး ပြီးပါပြီ!"

# Stage 0 / stage 7 label prefixes (dynamic suffix appended).
const TALK_LABEL_PREFIX: String = "တာဝန်: ရွာသားနဲ့ စကားပြောပါ ("
const BANANA_LABEL_PREFIX: String = "တာဝန်: ငှက်ပျောသီး ခူးပါ ("

# Trigger table: trigger name -> from stage, to stage, reward id.
# This table IS the chain: adding a mission means adding a row
# (plus its title/label) — no handler code changes for the link.
const TRIGGERS: Dictionary = {
	"ride_any": {"from": 2, "to": 3, "reward": ""},
	"visit_pagoda": {"from": 1, "to": 2, "reward": ""},
	"ring_bell": {"from": 3, "to": 4, "reward": "r1"},
	"buy_fruit": {"from": 4, "to": 5, "reward": ""},
	"draw_water": {"from": 5, "to": 6, "reward": "r2"},
	"pass_gate": {"from": 6, "to": 7, "reward": ""},
	"pick_bananas": {"from": 7, "to": 8, "reward": "r3"},
	"cross_bridge": {"from": 8, "to": 9, "reward": ""},
	"pray": {"from": 9, "to": 10, "reward": "r4"},
	"order_tea": {"from": 10, "to": 11, "reward": ""},
	"donate_book": {"from": 11, "to": 12, "reward": "r5"},
	"ride_bicycle": {"from": 12, "to": 13, "reward": ""},
	"ride_tuktuk": {"from": 13, "to": 14, "reward": ""},
	"land_parachute": {"from": 14, "to": 15, "reward": ""},
	"beat_drum": {"from": 15, "to": 16, "reward": "r6"},
	"fish": {"from": 16, "to": 17, "reward": ""},
	"donate": {"from": 17, "to": 18, "reward": ""},
	"milk": {"from": 18, "to": 19, "reward": ""},
	"water_crops": {"from": 19, "to": 20, "reward": ""},
	"feed_chickens": {"from": 20, "to": 21, "reward": "r7"},
	"ride_elephant": {"from": 21, "to": 22, "reward": ""},
	"offer_flowers": {"from": 22, "to": 23, "reward": ""},
	"plant_rice": {"from": 23, "to": 24, "reward": ""},
	"rest": {"from": 24, "to": 25, "reward": ""},
	"feed_elephant": {"from": 25, "to": 26, "reward": "r8"},
	"ride_horse": {"from": 26, "to": 27, "reward": ""},
	"buy_gold": {"from": 27, "to": 28, "reward": ""},
	"lesson": {"from": 28, "to": 29, "reward": ""},
	"feed_horse": {"from": 29, "to": 30, "reward": ""},
	"visit_hut": {"from": 30, "to": 31, "reward": "r9"},
	"ride_boat2": {"from": 31, "to": 32, "reward": ""},
	"ride_horse2": {"from": 32, "to": 33, "reward": ""},
	"buy_noodles": {"from": 33, "to": 34, "reward": ""},
	"guestbook": {"from": 34, "to": 35, "reward": ""},
	"sleep": {"from": 35, "to": 36, "reward": "r10"},
}

# Reward effects, in the exact order _apply_reward_stats used.
# r1 is stamina-only (drain 12.5 / regen 30.0, read as a flag).
const REWARDS: Dictionary = {
	"r1": {"walk": 1.0, "sprint": 1.0, "jump": 1.0, "stamina_refill": false},
	"r2": {"walk": 1.1, "sprint": 1.0, "jump": 1.0, "stamina_refill": false},
	"r3": {"walk": 1.05, "sprint": 1.0, "jump": 1.0, "stamina_refill": false},
	"r4": {"walk": 1.05, "sprint": 1.0, "jump": 1.0, "stamina_refill": true},
	"r5": {"walk": 1.0, "sprint": 1.1, "jump": 1.0, "stamina_refill": false},
	"r6": {"walk": 1.05, "sprint": 1.0, "jump": 1.1, "stamina_refill": false},
	"r7": {"walk": 1.05, "sprint": 1.0, "jump": 1.1, "stamina_refill": false},
	"r8": {"walk": 1.05, "sprint": 1.0, "jump": 1.0, "stamina_refill": true},
	"r9": {"walk": 1.05, "sprint": 1.0, "jump": 1.0, "stamina_refill": true},
	"r10": {"walk": 1.05, "sprint": 1.0, "jump": 1.1, "stamina_refill": true},
}

const REWARD_ORDER: Array[String] = ["r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10"]

# Counter keys, in save-file order. HUD label order is separate.
const COUNTER_KEYS: Array[String] = ["fruit", "water", "banana", "snack", "lantern", "fish", "donation", "milk", "egg", "goal", "photo", "tea", "book", "flower", "rice", "gold", "lesson", "horse_feed", "elephant_feed", "noodle", "drink", "guestbook"]

# Slice 54, audit item 8 — sightseeing tour (FIRST new mission type).
# A side mission, separate from the 36-stage main chain: it never
# advances quest_stage, never grants r1..r10, and never gates
# movement, driving, or dialogue. Stops are REAL scene positions
# (read from main.tscn transforms, not invented): Pagoda (-20,-25),
# MonasteryBell (-6,-32), MarketStallA (16,12), Zayat (28,2).
# Arrival radius 9.0 m: the pagoda base cylinder (r=6.5) stops the
# player at ~6.9 m, so a smaller radius would make stop 1
# unreachable on foot — the same lesson as Slice 38's 8.0 m
# offer-flowers range. Reward is a stamina refill to 100 on
# completion only; it does not stack (stamina is capped at 100),
# so repeating the tour cannot farm stats.
const SIGHTSEEING_RADIUS: float = 9.0
const SIGHTSEEING_STOPS: Array = [
	{"id": "sight_pagoda", "title": "ဘုရား", "label": "ဘုရားကို သွားပါ", "pos": Vector2(-20.0, -25.0)},
	{"id": "sight_bell", "title": "ခေါင်းလောင်း", "label": "ခေါင်းလောင်းကို သွားပါ", "pos": Vector2(-6.0, -32.0)},
	{"id": "sight_market", "title": "ဈေး", "label": "ဈေးကို သွားပါ", "pos": Vector2(16.0, 12.0)},
	{"id": "sight_zayat", "title": "ဇရပ်", "label": "ဇရပ်ကို သွားပါ", "pos": Vector2(28.0, 2.0)},
]

static func label_for(stage: int, rewards: Dictionary, talked: int, total: int, banana: int) -> String:
	if stage == 0:
		return TALK_LABEL_PREFIX + str(talked) + "/" + str(total) + ")"
	if stage >= 1 and stage <= 35:
		if stage == 7:
			return BANANA_LABEL_PREFIX + str(mini(banana, 3)) + "/3)"
		return STAGE_LABELS[stage - 1]
	var done_order: Array[String] = ["r10", "r9", "r8", "r7", "r6", "r5", "r4", "r3", "r2", "r1"]
	for idx in range(done_order.size()):
		if bool(rewards.get(done_order[idx], false)):
			return DONE_TEXTS[idx]
	return DONE_TEXT_NONE

static func tracker_for(stage: int) -> String:
	var parts: Array = []
	for i in range(36):
		parts.append(("✓ " if stage > i else "○ ") + STAGE_TITLES[i])
	return "   ".join(parts)
