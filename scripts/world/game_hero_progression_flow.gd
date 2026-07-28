extends RefCounted

static func next_level_pack_size(game: Node, level_value: int) -> Vector2i:
	var sequence_index: int = maxi(level_value - 2, 0) % game.LEVEL_UP_PACK_SEQUENCE.size()
	return game.LEVEL_UP_PACK_SEQUENCE[sequence_index]

static func hero_level_stat_bonuses(_game: Node, level_value: int) -> Dictionary:
	var earned_levels: int = maxi(level_value - 1, 0)
	return {
		"health": float(earned_levels) * 8.0,
		"attack": float(earned_levels) * 2.0,
		"speed": float(earned_levels) * 10.0,
	}

static func hero_spell_slot_capacity(game: Node, hero: Variant) -> int:
	if hero == null or not is_instance_valid(hero) or not game.hero_supports_spell_repertoire(hero):
		return 0
	return game.spell_slot_capacity_for_class_level(String(hero.hero_class_id), int(hero.level))

static func hero_spell_slot_counts(game: Node, hero: Variant) -> Array[int]:
	if hero == null or not is_instance_valid(hero) or not game.hero_supports_spell_repertoire(hero):
		return []
	return game.spell_slot_counts_for_class_level(String(hero.hero_class_id), int(hero.level))

static func hero_spellbook_overlay_data(game: Node, hero: Variant) -> Dictionary:
	if hero == null or not is_instance_valid(hero):
		return {
			"enabled": false,
			"known": [],
			"slotted": [],
			"capacity": 0,
		}
	var focus_item_id: String = game.spell_focus_item_id_for_class(String(hero.hero_class_id))
	return {
		"enabled": game.hero_supports_spell_repertoire(hero) and game.hero_has_spell_focus_item(hero),
		"focus_item_id": focus_item_id,
		"title": game.spell_panel_title_for_class(String(hero.hero_class_id)),
		"known": hero.learned_spells.duplicate(),
		"spells": game.spell_overlay_entries(hero.learned_spells),
		"slotted": hero.slotted_spells.duplicate(),
		"capacity": hero_spell_slot_capacity(game, hero),
		"slots_by_level": hero_spell_slot_counts(game, hero),
		"editable": game.hero_spell_repertoire_editable(hero),
		"prep_note": "Level %d spells. In the first room, slot edits immediately refresh generated spell cards, but no cards can be played until the first door opens. After that, edits save for next floor only, and existing generated cards stay until played." % game.hero_max_spell_level_for_class_level(String(hero.hero_class_id), int(hero.level)),
	}

static func hero_can_study_spell(game: Node, hero: Variant, spell_id: String) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hero.hero_class_id != game.HERO_CLASS_WIZARD or not game.hero_has_spell_focus_item(hero):
		return false
	if spell_id == "" or hero.learned_spells.has(spell_id):
		return false
	return not game.wave_in_progress()

static func begin_spell_scroll_study(game: Node, hero: Variant, spell_id: String) -> bool:
	if not hero_can_study_spell(game, hero, spell_id):
		return false
	hero.studying_spell_id = spell_id
	hero.studying_room = game.active_hero_room_for_commands(hero)
	hero.studying_started_at_door = game.doors_opened
	game.status_message = "%s began studying %s. Stay in the room until the next door opens." % [hero.hero_name, game.spell_display_name(spell_id)]
	return true

static func resolve_spell_scroll_studies(game: Node) -> void:
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero) or hero.studying_spell_id == "":
			continue
		if game.doors_opened <= hero.studying_started_at_door:
			continue
		var studied_spell_id: String = hero.studying_spell_id
		var study_succeeded: bool = hero.current_room == hero.studying_room and hero.pending_room == game.INVALID_ROOM and hero.pending_open_room == game.INVALID_ROOM
		hero.studying_spell_id = ""
		hero.studying_room = game.INVALID_ROOM
		hero.studying_started_at_door = -1
		if not study_succeeded:
			game.status_message = "%s lost focus and failed to learn %s." % [hero.hero_name, game.spell_display_name(studied_spell_id)]
			continue
		if not hero.learned_spells.has(studied_spell_id):
			hero.learned_spells.append(studied_spell_id)
		var prepared_level_index: int = game.spell_level(studied_spell_id) - 1
		var slot_counts: Array[int] = hero_spell_slot_counts(game, hero)
		var prepared_count_for_level: int = 0
		for slotted_spell_variant in hero.slotted_spells:
			if game.spell_level(String(slotted_spell_variant)) == prepared_level_index + 1:
				prepared_count_for_level += 1
		if prepared_level_index >= 0 and prepared_level_index < slot_counts.size() and prepared_count_for_level < int(slot_counts[prepared_level_index]) and not hero.slotted_spells.has(studied_spell_id):
			hero.slotted_spells.append(studied_spell_id)
		game.sanitize_hero_spellbook(hero)
		apply_inventory_stats_to_hero(game, hero)
		game.status_message = "%s learned %s." % [hero.hero_name, game.spell_display_name(studied_spell_id)]

static func advance_spell_scroll_studies(game: Node) -> void:
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero) or hero.studying_spell_id == "":
			continue
		if hero.current_room == hero.studying_room and hero.pending_room == game.INVALID_ROOM and hero.pending_open_room == game.INVALID_ROOM:
			continue
		var studied_spell_id: String = hero.studying_spell_id
		hero.studying_spell_id = ""
		hero.studying_room = game.INVALID_ROOM
		hero.studying_started_at_door = -1
		game.status_message = "%s interrupted study of %s." % [hero.hero_name, game.spell_display_name(studied_spell_id)]

static func hero_next_level_unlock_names(game: Node, hero: Variant) -> Array[String]:
	var unlock_names: Array[String] = []
	if hero == null or not is_instance_valid(hero):
		return unlock_names
	var next_level: int = hero.level + 1
	var class_def: Dictionary = game.hero_class_definition(hero.hero_class_id)
	for passive_unlock_variant in Array(class_def.get("level_passives", [])):
		var passive_unlock: Dictionary = passive_unlock_variant
		if int(passive_unlock.get("level", -1)) != next_level:
			continue
		unlock_names.append(String(passive_unlock.get("name", "Passive")))
	return unlock_names

static func build_level_up_reward_lines(game: Node, hero: Variant) -> Array[String]:
	var reward_lines: Array[String] = []
	if hero == null or not is_instance_valid(hero):
		return reward_lines
	var current_bonus: Dictionary = hero_level_stat_bonuses(game, hero.level)
	var next_bonus: Dictionary = hero_level_stat_bonuses(game, hero.level + 1)
	var health_gain: int = int(round(float(next_bonus.get("health", 0.0)) - float(current_bonus.get("health", 0.0))))
	var attack_gain: int = int(round(float(next_bonus.get("attack", 0.0)) - float(current_bonus.get("attack", 0.0))))
	var speed_gain: int = int(round(float(next_bonus.get("speed", 0.0)) - float(current_bonus.get("speed", 0.0))))
	var next_pack_size: Vector2i = hero_next_pack_size(game, hero)
	var unlock_names: Array[String] = hero_next_level_unlock_names(game, hero)
	reward_lines.append("Stats +%d hp  +%d dmg  +%d spd" % [health_gain, attack_gain, speed_gain])
	reward_lines.append("Pack %dx%d inventory module" % [next_pack_size.x, next_pack_size.y])
	if unlock_names.is_empty():
		reward_lines.append("Passive ability: none this level")
	else:
		reward_lines.append("Passive ability: %s" % ", ".join(PackedStringArray(unlock_names)))
	return reward_lines

static func level_up_food_cost(_game: Node, level_value: int) -> int:
	return 4 + level_value * 2

static func hero_next_pack_size(game: Node, hero: Variant) -> Vector2i:
	return next_level_pack_size(game, hero.level + 1)

static func hero_can_level_up(game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if game.food < level_up_food_cost(game, hero.level):
		return false
	return game.find_default_pack_anchor(hero.pack_modules, hero_next_pack_size(game, hero)) != game.INVALID_ROOM

static func grant_level_up_pack_to_hero(game: Node, hero: Variant) -> bool:
	if not hero_can_level_up(game, hero):
		return false
	var next_pack_size: Vector2i = hero_next_pack_size(game, hero)
	var pack_anchor: Vector2i = game.find_default_pack_anchor(hero.pack_modules, next_pack_size)
	if pack_anchor == game.INVALID_ROOM:
		return false
	game.food -= level_up_food_cost(game, hero.level)
	hero.level += 1
	hero.pack_modules.append({
		"size": next_pack_size,
		"anchor": pack_anchor,
	})
	if hero.hero_index >= 0 and hero.hero_index < game.hero_profiles.size():
		game.hero_profiles[hero.hero_index]["level"] = hero.level
		game.hero_profiles[hero.hero_index]["pack_modules"] = hero.pack_modules.duplicate(true)
	return true

static func build_inventory_stat_lines(game: Node, hero: Variant, items: Array) -> Array[String]:
	var bonuses: Dictionary = game.inventory_effect_summary(items)
	var level_bonuses: Dictionary = hero_level_stat_bonuses(game, hero.level)
	var used_cells: int = 0
	for item_variant in items:
		used_cells += game.item_occupied_cells(item_variant).size()
	var stat_lines: Array[String] = []
	stat_lines.append("Damage %d" % int(round(hero.base_attack_damage + float(level_bonuses.get("attack", 0.0)) + float(bonuses["attack"]))))
	stat_lines.append("Health %d" % int(round(hero.base_max_health + float(level_bonuses.get("health", 0.0)) + float(bonuses["health"]))))
	stat_lines.append("Speed %d" % int(round(hero.base_move_speed + float(level_bonuses.get("speed", 0.0)) + float(bonuses["speed"]))))
	stat_lines.append("Hand inf")
	stat_lines.append("Synergies %d" % int(bonuses["synergies"]))
	stat_lines.append("Space %d/%d" % [used_cells, game.inventory_capacity(hero.pack_modules)])
	return stat_lines

static func format_ability_metric(_game: Node, value: float) -> String:
	if absf(value - round(value)) <= 0.05:
		return str(int(round(value)))
	return "%.1f" % value

static func ability_detail_text(game: Node, cooldown: float, power_text: String, _stamina_cost: float, extra_text: String = "") -> String:
	var detail: String = "CD %ss  Pow %s" % [format_ability_metric(game, cooldown), power_text]
	if extra_text != "":
		detail += "  %s" % extra_text
	return detail

static func ability_power_text(game: Node, card_id: String, payload: Dictionary) -> String:
	match card_id:
		"dagger_card":
			return "%sx%d" % [format_ability_metric(game, float(payload.get("damage", 0.0))), maxi(1, int(payload.get("projectile_count", 1)))]
		"axe_card":
			return format_ability_metric(game, float(payload.get("damage", 0.0)))
		_:
			return format_ability_metric(game, float(payload.get("damage", 0.0)))

static func build_inventory_ability_sections(game: Node, hero: Variant) -> Array:
	var sections: Array = []
	if hero == null or not is_instance_valid(hero):
		return sections
	var class_def: Dictionary = game.hero_class_definition(hero.hero_class_id)
	var attack_style: String = String(class_def.get("attack_style", hero.preferred_attack_style))
	var basic_attack_detail: String = ability_detail_text(game, hero.attack_cooldown, format_ability_metric(game, hero.attack_damage), 0.0, "%s %d rng" % ["Melee" if attack_style == "melee" else "Ranged", int(round(hero.attack_range))])
	sections.append({
		"title": "Current",
		"entries": [{
			"name": "Basic Attack",
			"detail": basic_attack_detail,
		}],
	})
	var effect_summary: Dictionary = game.inventory_effect_summary(hero.inventory_items)
	var gear_entries: Array = []
	for passive_variant in Array(effect_summary.get("combat_passives", [])):
		var passive_ability: Dictionary = passive_variant
		var item_id: String = String(passive_ability.get("item_id", ""))
		var item_def: Dictionary = game.item_defs.get(item_id, {})
		var item_bonus: Dictionary = Dictionary(passive_ability.get("item_bonus", {}))
		var card_def: Dictionary = game.card_definition(String(passive_ability.get("card_id", "")))
		var base_cooldown: float = float(passive_ability.get("cooldown", card_def.get("test_cooldown", 1.5)))
		var effective_cooldown: float = maxf(base_cooldown * float(item_bonus.get("card_charge_mult", 1.0)), 0.25)
		var passive_payload: Dictionary = game.build_passive_combat_payload(passive_ability, effect_summary)
		gear_entries.append({
			"name": "%s: %s" % [String(item_def.get("name", item_id.capitalize())), String(card_def.get("name", "Passive"))],
			"detail": ability_detail_text(game, effective_cooldown, ability_power_text(game, String(card_def.get("id", "")), passive_payload), float(passive_payload.get("stamina_cost", 0.0))),
		})
	if not gear_entries.is_empty():
		sections.append({
			"title": "Gear Passives",
			"entries": gear_entries,
		})
	var level_entries: Array = []
	for passive_unlock_variant in Array(class_def.get("level_passives", [])):
		var passive_unlock: Dictionary = passive_unlock_variant
		var passive_detail: String = String(passive_unlock.get("detail", passive_unlock.get("description", "Locked")))
		level_entries.append({
			"level": int(passive_unlock.get("level", -1)),
			"name": String(passive_unlock.get("name", "Passive")),
			"detail": passive_detail,
		})
	if not level_entries.is_empty():
		level_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("level", 0)) < int(b.get("level", 0))
		)
		sections.append({
			"title": "Level Path",
			"entries": level_entries,
		})
	return sections

static func apply_inventory_stats_to_hero(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var normalized_items: Array = []
	for item_variant in hero.inventory_items:
		normalized_items.append(game.normalize_item_instance(item_variant))
	hero.inventory_items = normalized_items
	game.sanitize_hero_spellbook(hero)
	var bonuses: Dictionary = game.inventory_effect_summary(hero.inventory_items)
	var level_bonuses: Dictionary = hero_level_stat_bonuses(game, hero.level)
	hero.apply_inventory_stats(
		float(level_bonuses.get("speed", 0.0)) + float(bonuses["speed"]),
		float(level_bonuses.get("health", 0.0)) + float(bonuses["health"]),
		float(level_bonuses.get("attack", 0.0)) + float(bonuses["attack"]),
		0.0,
		int(bonuses.get("hand_size", 0)),
		int(bonuses["synergies"])
	)
	game.sync_hero_card_sources(hero, bonuses)
	game.sync_hero_passive_combat_sources(hero, bonuses)
	if hero.hero_index >= 0 and hero.hero_index < game.hero_profiles.size():
		game.hero_profiles[hero.hero_index]["level"] = hero.level
		game.hero_profiles[hero.hero_index]["pack_modules"] = hero.pack_modules.duplicate(true)
		game.hero_profiles[hero.hero_index]["inventory_items"] = hero.inventory_items.duplicate(true)
		game.hero_profiles[hero.hero_index]["learned_spells"] = hero.learned_spells.duplicate()
		game.hero_profiles[hero.hero_index]["slotted_spells"] = hero.slotted_spells.duplicate()
