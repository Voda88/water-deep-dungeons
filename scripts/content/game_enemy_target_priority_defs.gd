extends RefCounted

const TARGET_CATEGORY_RANGED: String = "ranged_target"
const TARGET_CATEGORY_MELEE: String = "melee_target"
const TARGET_CATEGORY_RESEARCH_CRYSTAL: String = "research_crystal"
const TARGET_CATEGORY_MAJOR_MODULE: String = "major_module"
const TARGET_CATEGORY_GENERATOR_CRYSTAL: String = "generator_crystal"

const DEFAULT_PRIORITY_TABLE: Dictionary = {
	TARGET_CATEGORY_MELEE: 1,
	TARGET_CATEGORY_RANGED: 2,
	TARGET_CATEGORY_RESEARCH_CRYSTAL: 3,
	TARGET_CATEGORY_MAJOR_MODULE: 4,
	TARGET_CATEGORY_GENERATOR_CRYSTAL: 5,
}

# Lower number = higher priority. Priority 0 disables category for that role.
const ROLE_PRIORITY_TABLE: Dictionary = {
	"orc": {
		TARGET_CATEGORY_MELEE: 1,
		TARGET_CATEGORY_RANGED: 2,
		TARGET_CATEGORY_RESEARCH_CRYSTAL: 3,
		TARGET_CATEGORY_MAJOR_MODULE: 4,
		TARGET_CATEGORY_GENERATOR_CRYSTAL: 5,
	},
	"orc_rider": {
		TARGET_CATEGORY_MELEE: 1,
		TARGET_CATEGORY_RANGED: 2,
		TARGET_CATEGORY_RESEARCH_CRYSTAL: 3,
		TARGET_CATEGORY_MAJOR_MODULE: 4,
		TARGET_CATEGORY_GENERATOR_CRYSTAL: 5,
	},
	"skeleton_archer": {
		TARGET_CATEGORY_RANGED: 1,
		TARGET_CATEGORY_MELEE: 2,
		TARGET_CATEGORY_RESEARCH_CRYSTAL: 3,
		TARGET_CATEGORY_MAJOR_MODULE: 4,
		TARGET_CATEGORY_GENERATOR_CRYSTAL: 5,
	},
	"wraith": {
		TARGET_CATEGORY_RANGED: 1,
		TARGET_CATEGORY_MELEE: 2,
		TARGET_CATEGORY_RESEARCH_CRYSTAL: 3,
		TARGET_CATEGORY_MAJOR_MODULE: 4,
		TARGET_CATEGORY_GENERATOR_CRYSTAL: 5,
	},
	"bat": {
		TARGET_CATEGORY_RESEARCH_CRYSTAL: 1,
		TARGET_CATEGORY_MAJOR_MODULE: 2,
		TARGET_CATEGORY_GENERATOR_CRYSTAL: 3,
		TARGET_CATEGORY_MELEE: 0,
		TARGET_CATEGORY_RANGED: 0,
	},
	"golem": {
		TARGET_CATEGORY_RESEARCH_CRYSTAL: 1,
		TARGET_CATEGORY_MAJOR_MODULE: 2,
		TARGET_CATEGORY_GENERATOR_CRYSTAL: 3,
		TARGET_CATEGORY_MELEE: 0,
		TARGET_CATEGORY_RANGED: 0,
	},
	"demon_d": {
		TARGET_CATEGORY_RESEARCH_CRYSTAL: 1,
		TARGET_CATEGORY_MAJOR_MODULE: 2,
		TARGET_CATEGORY_GENERATOR_CRYSTAL: 3,
		TARGET_CATEGORY_MELEE: 0,
		TARGET_CATEGORY_RANGED: 0,
	},
}

const DEFAULT_TARGETING_RULE: Dictionary = {
	"lock_room_target": false,
	"allow_path_target": true,
}

# Behavioral knobs for target selection using the priority table above.
const ROLE_TARGETING_RULE_TABLE: Dictionary = {
	"orc": {
		"lock_room_target": true,
		"allow_path_target": true,
	},
	"orc_rider": {
		"lock_room_target": true,
		"allow_path_target": true,
	},
	"skeleton_archer": {
		"lock_room_target": false,
		"allow_path_target": true,
	},
	"wraith": {
		"lock_room_target": false,
		"allow_path_target": true,
	},
	"bat": {
		"lock_room_target": false,
		"allow_path_target": false,
	},
	"golem": {
		"lock_room_target": false,
		"allow_path_target": false,
	},
	"demon_d": {
		"lock_room_target": false,
		"allow_path_target": false,
	},
}

static func priority_table_for_role(enemy_role: String) -> Dictionary:
	var table: Dictionary = Dictionary(DEFAULT_PRIORITY_TABLE).duplicate(true)
	var role_table: Dictionary = Dictionary(ROLE_PRIORITY_TABLE.get(enemy_role, {}))
	for category in role_table.keys():
		table[category] = role_table[category]
	return table

static func targeting_rule_for_role(enemy_role: String) -> Dictionary:
	var rule: Dictionary = Dictionary(DEFAULT_TARGETING_RULE).duplicate(true)
	var role_rule: Dictionary = Dictionary(ROLE_TARGETING_RULE_TABLE.get(enemy_role, {}))
	for key in role_rule.keys():
		rule[key] = role_rule[key]
	return rule
