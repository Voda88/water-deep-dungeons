extends RefCounted

const HERO_CLASS_FIGHTER: String = "fighter"
const HERO_CLASS_CLERIC: String = "cleric"
const HERO_CLASS_ROGUE: String = "rogue"
const HERO_CLASS_WIZARD: String = "wizard"

static func build_item_defs() -> Dictionary:
	return {
		"axe": {
			"name": "Axe Rack",
			"short": "AXE",
			"size": Vector2i(2, 2),
			"color": Color("ffb36b"),
			"description_lines": ["Passive: hurls a bouncing axe in combat", "Synergies boost proc speed and damage"],
			"tags": ["weapon", "metal", "axe"],
			"stats": {"attack": 5.0},
			"synergy_sockets": [
				{"offset": Vector2i(-1, 0), "tag": "support", "bonuses": {"attack": 2.0, "card_charge_mult": 0.9}},
				{"offset": Vector2i(2, 1), "tag": "metal", "bonuses": {"card_damage": 5.0}},
			],
			"passive_combat_ability": {"card_id": "axe_card", "cooldown": 1.8},
		},
		"daggers": {
			"name": "Daggers",
			"short": "DAG",
			"size": Vector2i(1, 2),
			"color": Color("d8e4ff"),
			"description_lines": ["Passive: fires a 3-dagger fan in combat", "Back hits build combo and bonus damage"],
			"tags": ["weapon", "blade", "dagger"],
			"stats": {"attack": 3.0},
			"synergy_sockets": [
				{"offset": Vector2i(1, 0), "tag": "support", "bonuses": {"projectile_count": 1}},
				{"offset": Vector2i(1, 1), "tag": "metal", "bonuses": {"dagger_backstab_bonus": 0.25, "card_charge_mult": 0.92}},
			],
			"passive_combat_ability": {"card_id": "dagger_card", "cooldown": 1.35},
		},
		"blade": {
			"name": "Blade",
			"short": "BLD",
			"size": Vector2i(1, 2),
			"color": Color("ffb36b"),
			"description_lines": ["Simple weapon upgrade", "Purely boosts attack"],
			"tags": ["weapon", "metal"],
			"stats": {"attack": 6.0},
			"synergy_sockets": [
				{"offset": Vector2i(1, 0), "tag": "tool", "bonuses": {"attack": 2.0}},
			],
		},
		"boots": {
			"name": "Boots",
			"short": "BOT",
			"size": Vector2i(2, 1),
			"color": Color("8ed7c5"),
			"description_lines": ["Move faster and gain stamina", "Pairs well with support gear"],
			"tags": ["gear", "footwear"],
			"stats": {"speed": 36.0, "stamina": 1.0},
			"synergy_sockets": [
				{"offset": Vector2i(0, -1), "tag": "support", "bonuses": {"stamina": 1.0}},
			],
		},
		"ration": {
			"name": "Ration",
			"short": "RAT",
			"size": Vector2i(1, 2),
			"color": Color("c8e07b"),
			"description_lines": ["Packed meals for recovery", "Adds a self-support card over dungeon turns"],
			"tags": ["food", "support"],
			"stats": {"health": 12.0, "hand_size": 1},
			"hand_cards": [
				{"card_id": "ration_meal_card", "door_interval": 2, "generation_mode": "door_interval", "max_stored_cards": 1},
			],
			"synergy_sockets": [
				{"offset": Vector2i(0, -1), "tag": "support", "bonuses": {"hand_size": 1}},
			],
		},
		"buckler": {
			"name": "Buckler",
			"short": "BCK",
			"size": Vector2i(2, 2),
			"color": Color("9ec3ff"),
			"description_lines": ["Health and stamina buffer", "Weapon synergy lowers card stamina cost"],
			"tags": ["armor", "metal"],
			"stats": {"health": 18.0, "stamina": 1.0},
			"synergy_sockets": [
				{"offset": Vector2i(-1, 1), "tag": "weapon", "bonuses": {"stamina_cost_mult": 0.92}},
			],
		},
		"whetstone": {
			"name": "Whetstone",
			"short": "WHT",
			"size": Vector2i(1, 1),
			"color": Color("f2e4a4"),
			"description_lines": ["Star tool", "Stars buff neighboring weapons"],
			"tags": ["tool"],
			"synergy_sockets": [
				{"offset": Vector2i(-1, 0), "tag": "weapon", "bonuses": {"attack": 4.0}},
				{"offset": Vector2i(1, 0), "tag": "weapon", "bonuses": {"attack": 4.0}},
				{"offset": Vector2i(0, -1), "tag": "weapon", "bonuses": {"attack": 4.0}},
				{"offset": Vector2i(0, 1), "tag": "weapon", "bonuses": {"attack": 4.0}},
			],
		},
		"banner": {
			"name": "Banner",
			"short": "BNR",
			"size": Vector2i(1, 3),
			"color": Color("ea7e7e"),
			"description_lines": ["Star support standard", "Perimeter stars aid armor and weapons"],
			"tags": ["support"],
			"synergy_sockets": [
				{"offset": Vector2i(-1, 0), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(-1, 1), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(-1, 2), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(1, 0), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(1, 1), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(1, 2), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(0, -1), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(0, 3), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
			],
		},
		"lantern": {
			"name": "Lantern",
			"short": "LNT",
			"size": Vector2i(1, 2),
			"color": Color("ffe38a"),
			"description_lines": ["Three-use utility light", "Readies one torch card per door, up to one held"],
			"tags": ["support", "light"],
			"stats": {"hand_size": 1},
			"max_charges": 3,
			"synergy_sockets": [
				{"offset": Vector2i(1, 0), "tag": "support", "bonuses": {"card_charge_mult": 0.85}},
			],
			"hand_card": {"card_id": "torch_card", "door_interval": 1, "generation_mode": "door_interval", "max_stored_cards": 1, "consume_item_charges_on_play": 1},
		},
		"medkit": {
			"name": "Medkit",
			"short": "MED",
			"size": Vector2i(2, 1),
			"color": Color("ff9b9b"),
			"description_lines": ["Adds a Mend card immediately", "Mend is a large combat heal"],
			"tags": ["support", "medical"],
			"stats": {"health": 8.0},
			"max_charges": 2,
			"synergy_sockets": [
				{"offset": Vector2i(0, 1), "tag": "food", "bonuses": {"health": 4.0}},
				{"offset": Vector2i(2, 0), "tag": "support", "bonuses": {"card_charge_mult": 0.9}},
			],
			"hand_card": {"card_id": "mend_card", "door_interval": 3, "generation_mode": "door_interval", "max_stored_cards": 1, "consume_item_charges_on_play": 1},
		},
		"torch": {
			"name": "Torch",
			"short": "TOR",
			"size": Vector2i(1, 2),
			"color": Color("ffbf73"),
			"description_lines": ["Single-use utility light", "Consumed when its torch card is played"],
			"tags": ["support", "light", "torch"],
			"hand_card": {"card_id": "torch_card", "generation_mode": "single", "consume_item_on_play": true},
		},
		"spellbook": {
			"name": "Spellbook",
			"short": "SPB",
			"size": Vector2i(1, 2),
			"color": Color("caa8ff"),
			"description_lines": ["Wizard focus", "Slots learned spells for one cast each floor"],
			"tags": ["arcane", "book", "support"],
			"stats": {"hand_size": 1},
		},
		"holy_symbol": {
			"name": "Holy Symbol",
			"short": "HLY",
			"size": Vector2i(1, 1),
			"color": Color("d8e8a8"),
			"description_lines": ["Cleric focus", "Prepares prayers for one cast each floor"],
			"tags": ["divine", "focus", "support"],
			"stats": {"hand_size": 1},
		},
		"scroll_fireball": {
			"name": "Scroll of Fireball",
			"short": "SFB",
			"size": Vector2i(1, 2),
			"color": Color("ff9a5e"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "fireball_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Fireball Scroll", "description_lines_override": ["Cast Fireball once", "Wizard can study it in calm mode"]},
		},
		"scroll_magic_missile": {
			"name": "Scroll of Magic Missile",
			"short": "SMM",
			"size": Vector2i(1, 2),
			"color": Color("9cd7ff"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "magic_missile_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Magic Missile Scroll", "description_lines_override": ["Launch seeking missiles once", "Wizard can study it in calm mode"]},
		},
		"scroll_misty_step": {
			"name": "Scroll of Misty Step",
			"short": "SMS",
			"size": Vector2i(1, 2),
			"color": Color("b89cff"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "misty_step_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Misty Step Scroll", "description_lines_override": ["Teleport once to a seen room", "Wizard can study it in calm mode"]},
		},
		"scroll_shield": {
			"name": "Scroll of Shield",
			"short": "SSH",
			"size": Vector2i(1, 2),
			"color": Color("9fc8ff"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "shield_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Shield Scroll", "description_lines_override": ["Gain a temporary arcane barrier", "Wizard can study it in calm mode"]},
		},
		"scroll_lightning_bolt": {
			"name": "Scroll of Lightning Bolt",
			"short": "SLB",
			"size": Vector2i(1, 2),
			"color": Color("8bd9ff"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "lightning_bolt_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Lightning Bolt Scroll", "description_lines_override": ["Fire a piercing line through a doorway", "Wizard can study it in calm mode"]},
		},
	}

static func hero_class_definition(class_id: String) -> Dictionary:
	match class_id:
		HERO_CLASS_CLERIC:
			return {
				"id": HERO_CLASS_CLERIC,
				"name": "Cleric",
				"title": "Melee Cleric",
				"move_speed": 236.0,
				"max_health": 118.0,
				"attack_damage": 18.0,
				"attack_range": 82.0,
				"attack_cooldown": 0.52,
				"attack_style": "melee",
				"weight": 2.0,
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
				"attack_range": 78.0,
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
				"attack_style": "laser",
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
				"max_health": 142.0,
				"attack_damage": 28.0,
				"attack_range": 76.0,
				"attack_cooldown": 1.0,
				"attack_style": "melee",
				"weight": 2.45,
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
			return ["magic_missile_card", "shield_card", "misty_step_card", "fireball_card", "lightning_bolt_card"]
		HERO_CLASS_CLERIC:
			return ["cure_light_wounds_card", "sanctuary_card"]
		_:
			return []

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
	return String(card_definition(spell_id, card_lookup).get("spell_class", ""))

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

static func runtime_card_definition(game: Node, card_id: String) -> Dictionary:
	match card_id:
		"fireball_card":
			return {
				"id": "fireball_card",
				"name": "Fireball",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 3,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Can cast into adjacent rooms", "Recharges after 3 opened rooms"],
				"stamina_cost": 2.0,
				"base_damage": 42.0,
				"impact_radius": 92.0,
				"radius": 12.0,
				"speed": 880.0,
				"cast_adjacent_hops": 1,
				"door_interval": 3,
				"color": Color("ff9a5e"),
			}
		"magic_missile_card":
			return {
				"id": "magic_missile_card",
				"name": "Magic Missile",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Launches three seeking missiles", "Recharges after 1 opened room from a slotted spell"],
				"stamina_cost": 1.0,
				"base_damage": 14.0,
				"projectile_count": 3,
				"cast_adjacent_hops": 1,
				"door_interval": 1,
				"color": Color("9cd7ff"),
			}
		"light_cantrip_card":
			return {
				"id": "light_cantrip_card",
				"name": "Light",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "same_room",
				"phase": "out_of_combat",
				"description_lines": ["Wizard cantrip", "Lights the wizard's current room", "Light follows the wizard until recast or the floor ends"],
				"stamina_cost": 0.0,
				"color": Color("fff1a8"),
				"reusable": true,
			}
		"misty_step_card":
			return {
				"id": "misty_step_card",
				"name": "Misty Step",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "any",
				"description_lines": ["Teleport to a seen point", "Can hop into an adjacent room through a doorway", "Recharges after 2 opened rooms from a slotted spell"],
				"stamina_cost": 0.0,
				"cast_adjacent_hops": 1,
				"door_interval": 2,
				"color": Color("b89cff"),
			}
		"shield_card":
			return {
				"id": "shield_card",
				"name": "Shield",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-casts on a fatal hit", "Grants 6 seconds of immunity", "Recharges after 2 opened rooms from a slotted spell"],
				"stamina_cost": 1.0,
				"shield_amount": 0.0,
				"shield_duration": 0.0,
				"immunity_duration": 6.0,
				"auto_cast_on_fatal": true,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"door_interval": 2,
				"color": Color("9fc8ff"),
			}
		"lightning_bolt_card":
			return {
				"id": "lightning_bolt_card",
				"name": "Lightning Bolt",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 3,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Strike a line through one room or doorway", "Recharges after 3 opened rooms from a slotted spell"],
				"stamina_cost": 2.0,
				"base_damage": 30.0,
				"impact_radius": 18.0,
				"cast_adjacent_hops": 1,
				"door_interval": 3,
				"color": Color("8bd9ff"),
			}
		"lantern_torch_card":
			return {
				"id": "lantern_torch_card",
				"name": "Lamp Oil",
				"target_scope": "hero",
				"phase": "out_of_combat",
				"description_lines": ["Create one torch in a hero backpack", "Consumes 1 lantern charge"],
				"door_interval": 1,
				"color": Color("ffe38a"),
			}
		"torch_card":
			return {
				"id": "torch_card",
				"name": "Torch",
				"target_scope": "opened_room",
				"phase": "out_of_combat",
				"description_lines": ["Light one opened room", "Lasts through the next combat wave"],
				"door_interval": 2,
				"color": Color("ffe38a"),
			}
		"cure_light_wounds_card":
			return {
				"id": "cure_light_wounds_card",
				"name": "Cure Light Wounds",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "hero",
				"phase": "combat",
				"description_lines": ["Restore 36 health to one hero", "Recharges after 2 opened rooms from a prepared prayer"],
				"heal_amount": 36.0,
				"door_interval": 2,
				"color": Color("c3ffb3"),
			}
		"sanctuary_card":
			return {
				"id": "sanctuary_card",
				"name": "Sanctuary",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Gain a brief divine ward", "Recharges after 2 opened rooms from a prepared prayer"],
				"stamina_cost": 1.0,
				"shield_amount": 24.0,
				"shield_duration": 8.0,
				"door_interval": 2,
				"color": Color("e3ff9f"),
			}
		"mend_card":
			return {
				"id": "mend_card",
				"name": "Mend",
				"target_scope": "hero",
				"phase": "combat",
				"description_lines": ["Large combat heal", "Restore 60 health to one hero"],
				"heal_amount": 60.0,
				"door_interval": 3,
				"color": Color("ff9b9b"),
			}
		"emergency_snack_card":
			return {
				"id": "emergency_snack_card",
				"name": "Emergency Snack",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Spend party food to fully patch up", "Combat only, expires on the next door"],
				"food_cost": game.HEAL_FOOD_COST,
				"heal_full": true,
				"restore_stamina_full": true,
				"expires_after_turns": 1,
				"reaction_trigger": "stamina_negative",
				"reaction_default_enabled": true,
				"color": Color("ffd79c"),
			}
		"ration_meal_card":
			return {
				"id": "ration_meal_card",
				"name": "Eat Ration",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Combat heal plus stamina restore", "Also grants minor combat stamina regen"],
				"heal_amount": 24.0,
				"stamina_restore": 2.0,
				"stamina_regen_rate": 0.45,
				"stamina_regen_duration": 7.0,
				"door_interval": 2,
				"reaction_trigger": "stamina_negative",
				"reaction_default_enabled": true,
				"color": Color("d7f09f"),
			}
		"dagger_card":
			return {
				"id": "dagger_card",
				"name": "Dagger Fan",
				"target_scope": "same_room",
				"stamina_cost": 1.0,
				"base_damage": 10.0,
				"projectile_count": 3,
				"spread": 0.16,
				"speed": 1020.0,
				"bounces": 1,
				"lifetime": 1.45,
				"color": Color("d7f0ff"),
				"backstab_multiplier": 1.75,
				"combo_gain": 1,
				"test_cooldown": 1.35,
			}
		_:
			return {
				"id": "axe_card",
				"name": "Whirling Axe",
				"target_scope": "same_room",
				"stamina_cost": 2.0,
				"base_damage": 20.0,
				"speed": 760.0,
				"bounces": 2,
				"lifetime": 2.2,
				"color": Color("ffd27a"),
				"radius": 17.0,
				"test_cooldown": 1.8,
			}

static func card_target_scope_label(_game: Node, target_scope: String) -> String:
	match target_scope:
		"same_hero":
			return "Self"
		"same_room", "hero_room":
			return "Room"
		"hero":
			return "Hero"
		"opened_room":
			return "Open"
		"global":
			return "Global"
		_:
			return "Free"

static func hero_builtin_card_generators(game: Node, hero: Variant) -> Array:
	if hero == null or not is_instance_valid(hero):
		return []
	var generators: Array = [{
		"card_id": "emergency_snack_card",
		"door_interval": 1,
		"generation_mode": "door_interval",
		"initial_queued_cards": 1,
		"max_stored_cards": 1,
		"source_type": "hero_builtin",
		"hero_index": hero.hero_index,
		"generator_key": "hero:%d:emergency_snack_card" % hero.hero_index,
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
