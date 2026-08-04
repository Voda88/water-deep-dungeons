extends RefCounted

const HERO_CLASS_FIGHTER: String = "fighter"
const HERO_CLASS_CLERIC: String = "cleric"
const HERO_CLASS_ROGUE: String = "rogue"
const HERO_CLASS_WIZARD: String = "wizard"

static func hero_class_definition(class_id: String) -> Dictionary:
	match class_id:
		HERO_CLASS_CLERIC:
			return {
				"id": HERO_CLASS_CLERIC,
				"name": "Cleric",
				"title": "Melee Cleric",
				"move_speed": 236.0,
				"max_health": 108.0,
				"attack_damage": 18.0,
				"attack_range": 70.0,
				"attack_cooldown": 0.84,
				"attack_style": "melee",
				"weight": 1.7,
				"melee_windup": 0.21,
				"body_color": Color("9fe6b0"),
				"core_color": Color("f5fff1"),
			}
		HERO_CLASS_ROGUE:
			return {
				"id": HERO_CLASS_ROGUE,
				"name": "Rogue",
				"title": "Melee Rogue",
				"move_speed": 286.0,
				"max_health": 92.0,
				"attack_damage": 17.0,
				"attack_range": 70.0,
				"attack_cooldown": 0.42,
				"attack_style": "melee",
				"weight": 1.35,
				"melee_windup": 0.16,
				"body_color": Color("c2d8ff"),
				"core_color": Color("f6fbff"),
			}
		HERO_CLASS_WIZARD:
			return {
				"id": HERO_CLASS_WIZARD,
				"name": "Wizard",
				"title": "Ranged Wizard",
				"move_speed": 220.0,
				"max_health": 86.0,
				"attack_damage": 24.0,
				"attack_range": 320.0,
				"attack_cooldown": 1.5,
				"attack_style": "fire_bolt",
				"weight": 1.2,
				"melee_windup": 0.18,
				"body_color": Color("c7a7ff"),
				"core_color": Color("fff6ff"),
			}
		_:
			return {
				"id": HERO_CLASS_FIGHTER,
				"name": "Fighter",
				"title": "Melee Fighter",
				"move_speed": 248.0,
				"max_health": 170.0,
				"attack_damage": 28.0,
				"attack_range": 70.0,
				"attack_cooldown": 1.0,
				"attack_style": "melee",
				"weight": 2.8,
				"melee_windup": 0.24,
				"body_color": Color("ff9a7a"),
				"core_color": Color("fff2dd"),
			}

static func default_learned_spells_for_class(class_id: String, card_lookup: Callable) -> Array[String]:
	return starting_known_spells_for_class(class_id, card_lookup)

static func default_slotted_spells_for_class(class_id: String, card_lookup: Callable) -> Array[String]:
	var starter_spells: Array[String] = starting_known_spells_for_class(class_id, card_lookup)
	var slot_counts: Array[int] = spell_slot_counts_for_class_level(class_id, 1)
	var total_slots: int = 0
	for slot_count_variant in slot_counts:
		total_slots += int(slot_count_variant)
	var prepared: Array[String] = []
	for spell_variant in starter_spells:
		if prepared.size() >= total_slots:
			break
		prepared.append(String(spell_variant))
	return prepared

static func implemented_spellbook_spells_for_class(class_id: String) -> Array[String]:
	match class_id:
		HERO_CLASS_WIZARD:
			return ["magic_missile_card", "shield_card", "misty_step_card", "web_card", "scry_card", "summon_arcane_sentinel_card", "summon_warden_spirit_card", "fireball_card", "lightning_bolt_card"]
		HERO_CLASS_CLERIC:
			return ["cure_light_wounds_card", "sanctuary_card", "hold_person_card", "fear_card", "spiritual_weapon_card", "summon_warden_spirit_card"]
		_:
			return []

static func spell_classes_for_spell(spell_id: String, card_lookup: Callable) -> Array[String]:
	var classes: Array[String] = []
	var card_def: Dictionary = card_definition(spell_id, card_lookup)
	for class_variant in Array(card_def.get("spell_classes", [])):
		var class_id: String = String(class_variant)
		if class_id == "" or classes.has(class_id):
			continue
		classes.append(class_id)
	var legacy_class_id: String = String(card_def.get("spell_class", ""))
	if legacy_class_id != "" and not classes.has(legacy_class_id):
		classes.append(legacy_class_id)
	return classes

static func spell_is_available_to_class(spell_id: String, class_id: String, card_lookup: Callable) -> bool:
	if class_id == "":
		return false
	return spell_classes_for_spell(spell_id, card_lookup).has(class_id)

static func starting_known_spells_for_class(class_id: String, card_lookup: Callable) -> Array[String]:
	var learned: Array[String] = []
	for spell_id_variant in implemented_spellbook_spells_for_class(class_id):
		var spell_id: String = String(spell_id_variant)
		if spell_level(spell_id, card_lookup) != 1:
			continue
		learned.append(spell_id)
	return learned

static func spell_display_name(spell_id: String, card_lookup: Callable) -> String:
	return String(card_definition(spell_id, card_lookup).get("name", spell_id.replace("_card", "").replace("_", " ").capitalize()))

static func spell_display_names_joined(spell_ids: Array, card_lookup: Callable) -> String:
	var names: Array[String] = []
	for spell_variant in spell_ids:
		var spell_id: String = String(spell_variant)
		if spell_id == "":
			continue
		names.append(spell_display_name(spell_id, card_lookup))
	return ", ".join(PackedStringArray(names))

static func spell_overlay_entry(spell_id: String, card_lookup: Callable) -> Dictionary:
	var card_def: Dictionary = card_definition(spell_id, card_lookup)
	return {
		"id": spell_id,
		"name": String(card_def.get("name", spell_id.replace("_card", "").replace("_", " ").capitalize())),
		"level": spell_level(spell_id, card_lookup),
		"description_lines": Array(card_def.get("description_lines", [])).duplicate(),
	}

static func spell_overlay_entries(spell_ids: Array, card_lookup: Callable) -> Array:
	var entries: Array = []
	for spell_variant in spell_ids:
		var spell_id: String = String(spell_variant)
		if spell_id == "":
			continue
		entries.append(spell_overlay_entry(spell_id, card_lookup))
	return entries

static func spell_focus_item_id_for_class(class_id: String) -> String:
	match class_id:
		HERO_CLASS_WIZARD:
			return "spellbook"
		HERO_CLASS_CLERIC:
			return "holy_symbol"
		_:
			return ""

static func spell_panel_title_for_class(class_id: String) -> String:
	match class_id:
		HERO_CLASS_CLERIC:
			return "Prayer Book"
		_:
			return "Spellbook"

static func full_caster_spell_slots_for_level(level_value: int) -> Array[int]:
	var table: Array = [
		[2, 0, 0, 0, 0, 0, 0, 0, 0],
		[3, 0, 0, 0, 0, 0, 0, 0, 0],
		[4, 2, 0, 0, 0, 0, 0, 0, 0],
		[4, 3, 0, 0, 0, 0, 0, 0, 0],
		[4, 3, 2, 0, 0, 0, 0, 0, 0],
		[4, 3, 3, 0, 0, 0, 0, 0, 0],
		[4, 3, 3, 1, 0, 0, 0, 0, 0],
		[4, 3, 3, 2, 0, 0, 0, 0, 0],
		[4, 3, 3, 3, 1, 0, 0, 0, 0],
		[4, 3, 3, 3, 2, 0, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 0],
		[4, 3, 3, 3, 1, 1, 1, 1, 1],
		[4, 3, 3, 3, 1, 1, 1, 1, 1],
		[4, 3, 3, 3, 2, 1, 1, 1, 1],
		[4, 3, 3, 3, 2, 2, 1, 1, 1],
	]
	var index: int = clampi(level_value, 1, table.size()) - 1
	var row: Array = table[index]
	var slots: Array[int] = []
	for value in row:
		slots.append(int(value))
	return slots

static func spell_level(spell_id: String, card_lookup: Callable) -> int:
	return maxi(0, int(card_definition(spell_id, card_lookup).get("spell_level", 0)))

static func spell_class_id(spell_id: String, card_lookup: Callable) -> String:
	var spell_classes: Array[String] = spell_classes_for_spell(spell_id, card_lookup)
	if not spell_classes.is_empty():
		return String(spell_classes[0])
	return ""

static func spell_slot_counts_for_class_level(class_id: String, level_value: int) -> Array[int]:
	match class_id:
		HERO_CLASS_WIZARD, HERO_CLASS_CLERIC:
			return full_caster_spell_slots_for_level(level_value)
		_:
			return []

static func hero_max_spell_level_for_class_level(class_id: String, level_value: int) -> int:
	var slot_counts: Array[int] = spell_slot_counts_for_class_level(class_id, level_value)
	for slot_index in range(slot_counts.size() - 1, -1, -1):
		if slot_counts[slot_index] > 0:
			return slot_index + 1
	return 0

static func spell_slot_capacity_for_class_level(class_id: String, level_value: int) -> int:
	var total: int = 0
	for slot_count in spell_slot_counts_for_class_level(class_id, level_value):
		total += int(slot_count)
	return total

static func default_hero_class_for_slot(hero_index: int, class_order: Array[String]) -> String:
	return String(class_order[hero_index % class_order.size()])

static func card_definition(spell_id: String, card_lookup: Callable) -> Dictionary:
	if card_lookup.is_valid():
		return Dictionary(card_lookup.call(spell_id))
	return {}

static func hero_builtin_card_generators(game: Node, hero: Variant) -> Array:
	if hero == null or not is_instance_valid(hero):
		return []
	var generators: Array = [{
		"card_id": "emergency_snack_card",
		"generation_mode": "single",
		"initial_queued_cards": 1,
		"max_stored_cards": 1,
		"persistent_card": true,
		"source_type": "hero_builtin",
		"hero_index": hero.hero_index,
		"generator_key": "hero:%d:emergency_snack_card" % hero.hero_index,
	}, {
		"card_id": "arcane_reset_card",
		"generation_mode": "single",
		"initial_queued_cards": 1,
		"max_stored_cards": 1,
		"persistent_card": true,
		"source_type": "hero_builtin",
		"hero_index": hero.hero_index,
		"generator_key": "hero:%d:arcane_reset_card" % hero.hero_index,
	}]
	if hero.hero_class_id == game.HERO_CLASS_WIZARD:
		generators.append({
			"card_id": "light_cantrip_card",
			"generation_mode": "single",
			"max_stored_cards": 1,
			"source_type": "hero_builtin",
			"hero_index": hero.hero_index,
			"generator_key": "hero:%d:light_cantrip_card" % hero.hero_index,
			"persistent_card": true,
		})
	return generators

static func spellbook_card_generators(game: Node, hero: Variant, effect_summary: Dictionary) -> Array:
	var generators: Array = []
	if hero == null or not is_instance_valid(hero) or not game.hero_supports_spell_repertoire(hero):
		return generators
	var focus_item_uid: int = game.spell_focus_item_uid_for_hero(hero)
	var focus_item_id: String = spell_focus_item_id_for_class(String(hero.hero_class_id))
	if focus_item_uid < 0 or focus_item_id == "":
		return generators
	for spell_index in range(hero.active_floor_spells.size()):
		var spell_id: String = String(hero.active_floor_spells[spell_index])
		if spell_id == "" or not game.hero_can_prepare_spell(hero, spell_id):
			continue
		generators.append({
			"card_id": spell_id,
			"item_uid": focus_item_uid,
			"item_id": focus_item_id,
			"item_bonus": Dictionary(effect_summary.get("item_bonus_by_uid", {}).get(focus_item_uid, game.empty_inventory_effect_summary())).duplicate(true),
			"generation_mode": "door_interval",
			"max_stored_cards": 1,
			"generator_key": "spellbook:%d:%d:%s" % [hero.hero_index, spell_index, spell_id],
		})
	return generators
