extends RefCounted

const HERO_CLASS_FIGHTER: String = "fighter"
const HERO_CLASS_CLERIC: String = "cleric"
const HERO_CLASS_ROGUE: String = "rogue"
const HERO_CLASS_WIZARD: String = "wizard"

const LEVEL_UP_FOOD_COSTS: Array[int] = [16, 24, 36, 44, 56, 68, 80, 92, 104, 116]
const LEVEL_UP_FOOD_COST_STEP_AFTER_TABLE: int = 14

const HERO_LEVEL_UP_STAT_GAINS: Dictionary = {
	HERO_CLASS_FIGHTER: [
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
	],
	HERO_CLASS_CLERIC: [
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 100.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
	],
	HERO_CLASS_ROGUE: [
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 2.0, "wit": 1.0},
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 2.0, "wit": 1.0},
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 2.0, "wit": 1.0},
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 2.0, "wit": 1.0},
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 2.0, "wit": 1.0},
	],
	HERO_CLASS_WIZARD: [
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
		{"health": 50.0, "attack": 3.0, "defense": 3.0, "speed": 1.0, "wit": 1.0},
	],
}

static func level_up_food_cost(level_value: int) -> int:
	var index: int = maxi(level_value - 1, 0)
	if index < LEVEL_UP_FOOD_COSTS.size():
		return LEVEL_UP_FOOD_COSTS[index]
	var overflow_steps: int = index - (LEVEL_UP_FOOD_COSTS.size() - 1)
	return LEVEL_UP_FOOD_COSTS[LEVEL_UP_FOOD_COSTS.size() - 1] + overflow_steps * LEVEL_UP_FOOD_COST_STEP_AFTER_TABLE

static func level_up_stat_gain_for_class_level(class_id: String, level_value: int) -> Dictionary:
	if level_value <= 1:
		return {"health": 0.0, "attack": 0.0, "defense": 0.0, "defence": 0.0, "speed": 0.0, "wit": 0.0}
	var table: Array = Array(HERO_LEVEL_UP_STAT_GAINS.get(class_id, HERO_LEVEL_UP_STAT_GAINS[HERO_CLASS_FIGHTER]))
	if table.is_empty():
		return {"health": 0.0, "attack": 0.0, "defense": 0.0, "defence": 0.0, "speed": 0.0, "wit": 0.0}
	var gain_index: int = clampi(level_value - 2, 0, table.size() - 1)
	var entry: Dictionary = Dictionary(table[gain_index])
	var defence_gain: float = float(entry.get("defence", entry.get("defense", 0.0)))
	return {
		"health": float(entry.get("health", 0.0)),
		"attack": float(entry.get("attack", 0.0)),
		"defense": defence_gain,
		"defence": defence_gain,
		"speed": float(entry.get("speed", 0.0)),
		"wit": float(entry.get("wit", 0.0)),
	}
