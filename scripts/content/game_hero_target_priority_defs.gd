extends RefCounted

const TARGET_CATEGORY_HOSTILE_ENEMY: String = "hostile_enemy"

const DEFAULT_PRIORITY_TABLE: Dictionary = {
	TARGET_CATEGORY_HOSTILE_ENEMY: 1,
}

static func priority_table_for_hero(_hero: Variant) -> Dictionary:
	return Dictionary(DEFAULT_PRIORITY_TABLE).duplicate(true)