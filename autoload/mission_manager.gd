extends Node
## Slice 27 mission framework: the quest chain owned as DATA + state.
## MissionManager is an autoload (like SaveManager) and is the single
## source of truth for: current stage, the 10 reward flags, and the
## 22 interaction counters. player.gd keeps only the world side —
## positions, buttons, growth scales, stamina, talked instance ids —
## and calls advance()/bump() when things happen in the world.
## Behaviour is identical to the Slice 10-20 chain: same 36 stages in
## the same order, same rewards in the same order, same save keys
## ("quest_stage", "rewards" r1..r10, "counters"), same label and
## tracker texts (see mission_data.gd, copied byte-for-byte).
## Counters live here so save/load round-trips through one place;
## crop/rice GROWTH stays in player.gd (it drives plant scales, not
## mission state). Free roam is untouched: missions never gate
## movement, driving, or dialogue — advance() only fires when the
## world already did the thing, and out-of-order triggers are no-ops.

const Data := preload("res://autoload/mission_data.gd")

var stage: int = 0
var rewards: Dictionary = {}
var counters: Dictionary = {}


func _init() -> void:
	for rid in Data.REWARD_ORDER:
		rewards[rid] = false
	for key in Data.COUNTER_KEYS:
		counters[key] = 0


## Fire a world trigger. Advances ONLY when the current stage matches
## the trigger's from-stage (out-of-order calls are silent no-ops,
## exactly like the old `if quest_stage == X` guards). Returns
## {"advanced": bool, "reward": String} — reward is "" unless the
## transition newly granted one (a flag already set never re-applies).
func advance(trigger: String) -> Dictionary:
	var row = Data.TRIGGERS.get(trigger, null)
	if not (row is Dictionary):
		return {"advanced": false, "reward": ""}
	if stage != int(row.get("from", -1)):
		return {"advanced": false, "reward": ""}
	stage = int(row.get("to", stage))
	var rid := String(row.get("reward", ""))
	if rid != "" and not bool(rewards.get(rid, false)):
		rewards[rid] = true
		return {"advanced": true, "reward": rid}
	return {"advanced": true, "reward": ""}


## Talk-all promotion: stage 0 becomes 1 once every villager has been
## talked to. Called from the quest-label refresh, exactly where the
## old code promoted (inside _update_quest_label, not on talk).
func promote_talk_all(talked: int, total: int) -> bool:
	if stage == 0 and total > 0 and talked >= total:
		stage = 1
		return true
	return false


func label_text(talked: int, total: int, banana: int) -> String:
	return Data.label_for(stage, rewards, talked, total, banana)


func tracker_text() -> String:
	return Data.tracker_for(stage)


## HUD counter line, in the exact old order and emoji order.
## (elephant_feed is saved but was never displayed — preserved.)
func nonzero_summary() -> String:
	# Slice 61 addendum: the phone screenshot showed a bare grid of
	# 21 zero counters (emoji glyphs the default font cannot render).
	# Empty string when everything is zero (caller hides the label);
	# otherwise only nonzero counters, Burmese text, no emoji.
	var labels := {"fruit": "သီး", "water": "ရေ", "banana": "ငှက်ပျော", "tea": "လက်ဖက်", "book": "စာအုပ်", "snack": "မုန့်", "lantern": "မီးပုံး", "fish": "ငါး", "donation": "အလှူ", "milk": "နို့", "egg": "ဥ", "goal": "ဂိုး", "flower": "ပန်း", "photo": "ဓာတ်ပုံ", "rice": "စပါး", "gold": "ရွှေ", "lesson": "သင်ခန်း", "horse_feed": "မြင်းစာ", "noodle": "ခေါက်ဆွဲ", "drink": "အအေး", "guestbook": "ဧည့်စာရင်း"}
	var parts: Array = []
	for k in labels:
		var v := int(counters.get(k, 0))
		if v > 0:
			parts.append("%s %d" % [labels[k], v])
	return "  ".join(parts)

func counter_text() -> String:
	return "🍎 %d 💧 %d 🍌 %d 🍵 %d 📚 %d 🍡 %d 🪔 %d 🐟 %d 💰 %d 🥛 %d 🥚 %d ⚽ %d 🌸 %d 📸 %d 🌾 %d 🪙 %d 📖 %d 🐴 %d 🍜 %d 🥤 %d 📝 %d" % [counters.get("fruit", 0), counters.get("water", 0), counters.get("banana", 0), counters.get("tea", 0), counters.get("book", 0), counters.get("snack", 0), counters.get("lantern", 0), counters.get("fish", 0), counters.get("donation", 0), counters.get("milk", 0), counters.get("egg", 0), counters.get("goal", 0), counters.get("flower", 0), counters.get("photo", 0), counters.get("rice", 0), counters.get("gold", 0), counters.get("lesson", 0), counters.get("horse_feed", 0), counters.get("noodle", 0), counters.get("drink", 0), counters.get("guestbook", 0)]


func bump(key: String) -> void:
	if counters.has(key):
		counters[key] = int(counters.get(key, 0)) + 1


func get_count(key: String) -> int:
	return int(counters.get(key, 0))


## Multipliers from the reward flags, in r2..r10 order (r1 is
## stamina-only and is read as a flag by the stamina code).
## Matches the old _apply_reward_stats arithmetic exactly.
func stats_multipliers() -> Dictionary:
	var walk := 1.0
	var sprint := 1.0
	var jump := 1.0
	for rid in Data.REWARD_ORDER:
		if rid == "r1":
			continue
		if bool(rewards.get(rid, false)):
			var row = Data.REWARDS.get(rid, {})
			walk *= float(row.get("walk", 1.0))
			sprint *= float(row.get("sprint", 1.0))
			jump *= float(row.get("jump", 1.0))
	return {"walk": walk, "sprint": sprint, "jump": jump}


func stamina_blessed() -> bool:
	return bool(rewards.get("r1", false))


## Incremental effect of one newly granted reward (walk/sprint/jump
## multipliers + stamina refill flag). r1 returns all-ones: its
## stamina blessing is a flag read, not a stat change.
func reward_effect(rid: String) -> Dictionary:
	var row = Data.REWARDS.get(rid, null)
	if not (row is Dictionary):
		return {}
	return row.duplicate()


func rewards_dict() -> Dictionary:
	return rewards.duplicate()


func counters_dict() -> Dictionary:
	return counters.duplicate()


## Slice 54, audit item 8 — sightseeing side mission (see
## mission_data.gd SIGHTSEEING_STOPS). Parallel to the main chain:
## it never touches stage/rewards/counters, so an old save loads
## with sightseeing inactive and zero completions, and a main-chain
## save round-trips unchanged. State is saved under the optional
## "sightseeing" key in the save file (player.gd); a save without
## that key loads as inactive, never as an error.
var sightseeing_active: bool = false
var sightseeing_index: int = 0
var sightseeing_completed: int = 0


func sightseeing_stop_count() -> int:
	return Data.SIGHTSEEING_STOPS.size()


func sightseeing_current() -> Dictionary:
	if not sightseeing_active:
		return {}
	if sightseeing_index < 0 or sightseeing_index >= Data.SIGHTSEEING_STOPS.size():
		return {}
	return Data.SIGHTSEEING_STOPS[sightseeing_index]


func sightseeing_start() -> void:
	sightseeing_active = true
	sightseeing_index = 0


func sightseeing_cancel() -> void:
	sightseeing_active = false
	sightseeing_index = 0


## Check the given world-x/z position against the current stop.
## Returns {"visited": bool, "completed": bool}. A visit only counts
## in stop order; standing at a later stop early is a no-op, and
## calling with no active tour is a no-op. Completion ends the
## tour (active=false) and increments the completed count, so the
## tour is restartable but the count only grows on real completion.
func sightseeing_check(pos: Vector2) -> Dictionary:
	if not sightseeing_active:
		return {"visited": false, "completed": false}
	var cur := sightseeing_current()
	if cur.is_empty():
		return {"visited": false, "completed": false}
	var target: Vector2 = cur.get("pos", Vector2.ZERO)
	if pos.distance_to(target) > Data.SIGHTSEEING_RADIUS:
		return {"visited": false, "completed": false}
	sightseeing_index += 1
	if sightseeing_index >= Data.SIGHTSEEING_STOPS.size():
		sightseeing_active = false
		sightseeing_index = 0
		sightseeing_completed += 1
		return {"visited": true, "completed": true}
	return {"visited": true, "completed": false}


func sightseeing_label() -> String:
	# Slice 67: district prefix. All four stops are village landmarks
	# (Pagoda (-20,-25), MonasteryBell (-6,-32), MarketStallA (16,12),
	# Zayat (28,2) — all x < 88, the village/Mindon bridge line), so
	# "ရွာ" is exact, and every quest-tracker line now carries its
	# district (district60_label already says မင်းတုန်း, eastfields64
	# already says လယ်ကွင်း) instead of reading as village quests.
	if sightseeing_active:
		var cur := sightseeing_current()
		if cur.is_empty():
			return ""
		return "ရွာ လည်ပတ် (%d/%d): %s" % [sightseeing_index + 1, Data.SIGHTSEEING_STOPS.size(), str(cur.get("label", ""))]
	if sightseeing_completed > 0:
		return "ရွာ လည်ပတ် ပြီးပါပြီ (%d ကြိမ်) — အား ပြည့်သွားပါပြီ" % sightseeing_completed
	return ""


func sightseeing_state() -> Dictionary:
	return {"active": sightseeing_active, "index": sightseeing_index, "completed": sightseeing_completed}


func sightseeing_load_state(data: Dictionary) -> void:
	sightseeing_active = bool(data.get("active", false))
	sightseeing_index = clampi(int(data.get("index", 0)), 0, Data.SIGHTSEEING_STOPS.size())
	sightseeing_completed = maxi(int(data.get("completed", 0)), 0)
	if sightseeing_index >= Data.SIGHTSEEING_STOPS.size():
		sightseeing_active = false
		sightseeing_index = 0


## Slice 60 — Mindon district side quests (see mission_data.gd
## DISTRICT60_QUESTS). Parallel to the main chain and to sightseeing:
## it never touches stage/rewards/counters, and a pre-60 save loads
## with both quests undone, never as an error. State is saved under
## the optional "district60" key in the save file (player.gd).
## Check the given world-x/z position against every undone quest.
## Returns {"visited": bool, "quest": String, "all_done": bool}.
## A visit only counts inside DISTRICT60_RADIUS; already-done quests
## never re-trigger, so the stamina reward cannot be farmed.
var district60_done: Dictionary = {"hospital": false, "mrtv": false}


func district60_done_count() -> int:
	var n := 0
	for q in Data.DISTRICT60_QUESTS:
		if bool(district60_done.get(str(q.get("id", "")), false)):
			n += 1
	return n


func district60_check(pos: Vector2) -> Dictionary:
	for q in Data.DISTRICT60_QUESTS:
		var qid := str(q.get("id", ""))
		if bool(district60_done.get(qid, false)):
			continue
		var target: Vector2 = q.get("pos", Vector2.ZERO)
		if pos.distance_to(target) <= Data.DISTRICT60_RADIUS:
			district60_done[qid] = true
			return {"visited": true, "quest": qid, "all_done": district60_done_count() >= Data.DISTRICT60_QUESTS.size()}
	return {"visited": false, "quest": "", "all_done": false}


func district60_label() -> String:
	var done := district60_done_count()
	var total := Data.DISTRICT60_QUESTS.size()
	if done >= total:
		return "မင်းတုန်း ပြီးပါပြီ (%d/%d)" % [done, total]
	for q in Data.DISTRICT60_QUESTS:
		if not bool(district60_done.get(str(q.get("id", "")), false)):
			return "မင်းတုန်း (%d/%d): %s" % [done, total, str(q.get("label", ""))]
	return "မင်းတုန်း (%d/%d)" % [done, total]


func district60_state() -> Dictionary:
	return district60_done.duplicate()


func district60_load_state(data: Dictionary) -> void:
	for q in Data.DISTRICT60_QUESTS:
		var qid := str(q.get("id", ""))
		district60_done[qid] = bool(data.get(qid, false))


## Slice 64 — East Fields side quests (see mission_data.gd
## EASTFIELDS64_QUESTS). Exact Slice 60 pattern, independent state:
## it never touches stage/rewards/counters/sightseeing/district60,
## and a pre-64 save loads with all four quests undone, never as an
## error. State is saved under the optional "eastfields64" key in
## the save file (player.gd). Check the given world-x/z position
## against every undone quest. Returns {"visited": bool,
## "quest": String, "all_done": bool}. A visit only counts inside
## EASTFIELDS64_RADIUS; already-done quests never re-trigger, so
## the stamina reward cannot be farmed.
var eastfields64_done: Dictionary = {"east_road": false, "north_lane": false, "south_lane": false, "pond": false}


func eastfields64_done_count() -> int:
	var n := 0
	for q in Data.EASTFIELDS64_QUESTS:
		if bool(eastfields64_done.get(str(q.get("id", "")), false)):
			n += 1
	return n


func eastfields64_next() -> Dictionary:
	for q in Data.EASTFIELDS64_QUESTS:
		var qid := str(q.get("id", ""))
		if not bool(eastfields64_done.get(qid, false)):
			return q
	return {}


func eastfields64_check(pos: Vector2) -> Dictionary:
	for q in Data.EASTFIELDS64_QUESTS:
		var qid := str(q.get("id", ""))
		if bool(eastfields64_done.get(qid, false)):
			continue
		var target: Vector2 = q.get("pos", Vector2.ZERO)
		if pos.distance_to(target) <= Data.EASTFIELDS64_RADIUS:
			eastfields64_done[qid] = true
			return {"visited": true, "quest": qid, "all_done": eastfields64_done_count() >= Data.EASTFIELDS64_QUESTS.size()}
	return {"visited": false, "quest": "", "all_done": false}


func eastfields64_label() -> String:
	var done := eastfields64_done_count()
	var total := Data.EASTFIELDS64_QUESTS.size()
	if done >= total:
		return "လယ်ကွင်း ပြီးပါပြီ (%d/%d)" % [done, total]
	for q in Data.EASTFIELDS64_QUESTS:
		if not bool(eastfields64_done.get(str(q.get("id", "")), false)):
			return "လယ်ကွင်း (%d/%d): %s" % [done, total, str(q.get("label", ""))]
	return "လယ်ကွင်း (%d/%d)" % [done, total]


func eastfields64_state() -> Dictionary:
	return eastfields64_done.duplicate()


func eastfields64_load_state(data: Dictionary) -> void:
	for q in Data.EASTFIELDS64_QUESTS:
		var qid := str(q.get("id", ""))
		eastfields64_done[qid] = bool(data.get(qid, false))


## Load mission state from a save dictionary (old saves use the same
## keys, so a Slice 26 save maps onto this manager unchanged).
func load_state(stage_value: int, rewards_data: Dictionary, counters_data: Dictionary) -> void:
	stage = stage_value
	for rid in Data.REWARD_ORDER:
		rewards[rid] = bool(rewards_data.get(rid, false))
	for key in Data.COUNTER_KEYS:
		counters[key] = int(counters_data.get(key, 0))
