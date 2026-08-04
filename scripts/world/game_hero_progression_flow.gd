extends RefCounted

const GAME_HERO_LEVEL_DEFS: GDScript = preload("res://scripts/content/game_hero_level_defs.gd")

static func next_level_pack_size(game: Node, level_value: int) -> Vector2i:
	var sequence_index: int = maxi(level_value - 2, 0) % game.LEVEL_UP_PACK_SEQUENCE.size()
	return game.LEVEL_UP_PACK_SEQUENCE[sequence_index]

static func hero_level_stat_bonuses(game: Node, level_value: int, class_id: String = "") -> Dictionary:
	var resolved_class_id: String = class_id
	if resolved_class_id == "":
		resolved_class_id = String(game.HERO_CLASS_FIGHTER)
	var totals: Dictionary = {
		"health": 0.0,
		"attack": 0.0,
		"defence": 0.0,
		"defense": 0.0,
		"speed": 0.0,
	}
	for step_level in range(2, maxi(level_value, 1) + 1):
		var gain: Dictionary = GAME_HERO_LEVEL_DEFS.level_up_stat_gain_for_class_level(resolved_class_id, step_level)
		totals["health"] = float(totals.get("health", 0.0)) + float(gain.get("health", 0.0))
		totals["attack"] = float(totals.get("attack", 0.0)) + float(gain.get("attack", 0.0))
		totals["defence"] = float(totals.get("defence", 0.0)) + float(gain.get("defence", 0.0))
		totals["speed"] = float(totals.get("speed", 0.0)) + float(gain.get("speed", 0.0))
	totals["defense"] = float(totals.get("defence", 0.0))
	return totals

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
	if game.hero_supports_spell_repertoire(hero):
		game.sanitize_hero_spellbook(hero)
	sync_pending_item_fusions_for_hero(game, hero)
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
		"fusion_glow_uids": fusion_glow_item_uids(hero),
		"fusion_links": fusion_link_pairs(hero),
		"prep_note": "Level %d spells. Before the first door, slot edits refresh prepared cards immediately (cards still cannot be played until a door opens). Mid-floor, newly assigned spells are added to this floor on cooldown." % game.hero_max_spell_level_for_class_level(String(hero.hero_class_id), int(hero.level)),
	}

static func hero_can_study_spell(game: Node, hero: Variant, spell_id: String) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hero.hero_class_id != game.HERO_CLASS_WIZARD or not game.hero_has_spell_focus_item(hero):
		return false
	if spell_id == "" or not game.spell_is_available_to_class(spell_id, String(hero.hero_class_id)):
		return false
	if spell_id == "" or hero.learned_spells.has(spell_id):
		return false
	return not game.wave_in_progress()

static func begin_spell_scroll_study(game: Node, hero: Variant, spell_id: String) -> bool:
	return false

static func fusion_entry_key(entry: Dictionary) -> String:
	return "%s:%d:%d" % [String(entry.get("kind", "")), int(entry.get("item_uid_left", -1)), int(entry.get("item_uid_right", -1))]

static func pending_fusion_signature(entries: Array) -> String:
	var tokens: Array[String] = []
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		tokens.append("%s@%d:%s" % [fusion_entry_key(entry), int(entry.get("started_at_door", -1)), String(entry.get("learn_spell_id", ""))])
	tokens.sort()
	return "|".join(PackedStringArray(tokens))

static func item_is_directly_right_of(game: Node, left_item: Dictionary, right_item: Dictionary) -> bool:
	var left_anchor: Vector2i = left_item.get("anchor", game.INVALID_ROOM)
	var right_anchor: Vector2i = right_item.get("anchor", game.INVALID_ROOM)
	if left_anchor == game.INVALID_ROOM or right_anchor == game.INVALID_ROOM:
		return false
	var left_size: Vector2i = game.item_size_in_cells(left_item)
	var right_size: Vector2i = game.item_size_in_cells(right_item)
	var left_right_x: int = left_anchor.x + left_size.x
	if right_anchor.x != left_right_x:
		return false
	var left_top: int = left_anchor.y
	var left_bottom: int = left_anchor.y + left_size.y
	var right_top: int = right_anchor.y
	var right_bottom: int = right_anchor.y + right_size.y
	return maxi(left_top, right_top) < mini(left_bottom, right_bottom)

static func learnable_spell_id_from_item(game: Node, item: Dictionary) -> String:
	var item_def: Dictionary = game.item_defs.get(String(item.get("item_id", "")), {})
	var generators: Array = []
	if item_def.has("hand_cards"):
		generators = Array(item_def.get("hand_cards", [])).duplicate(true)
	else:
		var single_generator: Dictionary = Dictionary(item_def.get("hand_card", {}))
		if not single_generator.is_empty():
			generators.append(single_generator)
	for generator_variant in generators:
		var generator: Dictionary = generator_variant as Dictionary
		if not bool(generator.get("learnable_spell_scroll", false)):
			continue
		var spell_id: String = String(generator.get("learn_spell_id", generator.get("card_id", "")))
		if spell_id != "":
			return spell_id
	return ""

static func build_item_fusion_candidates(game: Node, hero: Variant) -> Array:
	var candidates: Array = []
	if hero == null or not is_instance_valid(hero):
		return candidates
	if game.wave_in_progress():
		return candidates
	if String(hero.hero_class_id) != game.HERO_CLASS_WIZARD:
		return candidates
	var dedupe_keys: Dictionary = {}
	for left_item_variant in hero.inventory_items:
		var left_item: Dictionary = left_item_variant
		if String(left_item.get("item_id", "")) != "spellbook":
			continue
		for right_item_variant in hero.inventory_items:
			var right_item: Dictionary = right_item_variant
			if int(right_item.get("uid", -1)) == int(left_item.get("uid", -1)):
				continue
			if not item_is_directly_right_of(game, left_item, right_item):
				continue
			var spell_id: String = learnable_spell_id_from_item(game, right_item)
			if spell_id == "" or not hero_can_study_spell(game, hero, spell_id):
				continue
			var candidate: Dictionary = {
				"kind": "spell_scroll_into_spellbook",
				"item_uid_left": int(left_item.get("uid", -1)),
				"item_uid_right": int(right_item.get("uid", -1)),
				"learn_spell_id": spell_id,
			}
			var key: String = fusion_entry_key(candidate)
			if dedupe_keys.has(key):
				continue
			dedupe_keys[key] = true
			candidates.append(candidate)
	return candidates

static func sync_pending_item_fusions_for_hero(game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hero.studying_spell_id != "":
		hero.studying_spell_id = ""
		hero.studying_room = game.INVALID_ROOM
		hero.studying_started_at_door = -1
	var previous_signature: String = pending_fusion_signature(Array(hero.pending_item_fusions))
	var existing_by_key: Dictionary = {}
	for existing_variant in Array(hero.pending_item_fusions):
		var existing_entry: Dictionary = existing_variant
		existing_by_key[fusion_entry_key(existing_entry)] = existing_entry
	var next_entries: Array = []
	for candidate_variant in build_item_fusion_candidates(game, hero):
		var candidate: Dictionary = candidate_variant
		var candidate_key: String = fusion_entry_key(candidate)
		var next_entry: Dictionary = candidate.duplicate(true)
		if existing_by_key.has(candidate_key):
			next_entry["started_at_door"] = int(Dictionary(existing_by_key[candidate_key]).get("started_at_door", game.doors_opened))
		else:
			next_entry["started_at_door"] = game.doors_opened
		next_entries.append(next_entry)
	hero.pending_item_fusions = next_entries
	return previous_signature != pending_fusion_signature(next_entries)

static func fusion_glow_item_uids(hero: Variant) -> Array[int]:
	var glow_uids_map: Dictionary = {}
	for fusion_variant in Array(hero.pending_item_fusions):
		var fusion_entry: Dictionary = fusion_variant
		glow_uids_map[int(fusion_entry.get("item_uid_left", -1))] = true
		glow_uids_map[int(fusion_entry.get("item_uid_right", -1))] = true
	var glow_uids: Array[int] = []
	for uid_variant in glow_uids_map.keys():
		var uid: int = int(uid_variant)
		if uid >= 0:
			glow_uids.append(uid)
	return glow_uids

static func fusion_link_pairs(hero: Variant) -> Array:
	var pairs: Array = []
	for fusion_variant in Array(hero.pending_item_fusions):
		var fusion_entry: Dictionary = fusion_variant
		var left_uid: int = int(fusion_entry.get("item_uid_left", -1))
		var right_uid: int = int(fusion_entry.get("item_uid_right", -1))
		if left_uid < 0 or right_uid < 0:
			continue
		pairs.append({
			"left_uid": left_uid,
			"right_uid": right_uid,
		})
	return pairs

static func hero_inventory_item_by_uid(hero: Variant, item_uid: int) -> Dictionary:
	for item_variant in hero.inventory_items:
		var item: Dictionary = item_variant
		if int(item.get("uid", -1)) == item_uid:
			return item
	return {}

static func prepare_newly_learned_spell(game: Node, hero: Variant, spell_id: String) -> void:
	var prepared_level_index: int = game.spell_level(spell_id) - 1
	var slot_counts: Array[int] = hero_spell_slot_counts(game, hero)
	var prepared_count_for_level: int = 0
	for slotted_spell_variant in hero.slotted_spells:
		if game.spell_level(String(slotted_spell_variant)) == prepared_level_index + 1:
			prepared_count_for_level += 1
	if prepared_level_index >= 0 and prepared_level_index < slot_counts.size() and prepared_count_for_level < int(slot_counts[prepared_level_index]) and not hero.slotted_spells.has(spell_id):
		hero.slotted_spells.append(spell_id)

static func resolve_spell_scroll_fusion_entry(game: Node, hero: Variant, fusion_entry: Dictionary) -> bool:
	if String(fusion_entry.get("kind", "")) != "spell_scroll_into_spellbook":
		return false
	var spell_id: String = String(fusion_entry.get("learn_spell_id", ""))
	if spell_id == "" or not hero_can_study_spell(game, hero, spell_id):
		return false
	var scroll_uid: int = int(fusion_entry.get("item_uid_right", -1))
	var scroll_item: Dictionary = hero_inventory_item_by_uid(hero, scroll_uid)
	if scroll_item.is_empty():
		return false
	var scroll_name: String = String(game.item_defs.get(String(scroll_item.get("item_id", "")), {}).get("name", "scroll"))
	if not hero.learned_spells.has(spell_id):
		hero.learned_spells.append(spell_id)
	prepare_newly_learned_spell(game, hero, spell_id)
	game.remove_item_by_uid_from_world(scroll_uid)
	game.sanitize_hero_spellbook(hero)
	apply_inventory_stats_to_hero(game, hero)
	game.status_message = "%s fused %s into the spellbook and learned %s." % [hero.hero_name, scroll_name, game.spell_display_name(spell_id)]
	return true

static func resolve_spell_scroll_studies(game: Node) -> void:
	var overlay_needs_refresh: bool = false
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		sync_pending_item_fusions_for_hero(game, hero)
		var candidate_by_key: Dictionary = {}
		for candidate_variant in build_item_fusion_candidates(game, hero):
			var candidate_entry: Dictionary = candidate_variant
			candidate_by_key[fusion_entry_key(candidate_entry)] = candidate_entry
		var kept_entries: Array = []
		for fusion_variant in Array(hero.pending_item_fusions):
			var fusion_entry: Dictionary = fusion_variant
			var started_at_door: int = int(fusion_entry.get("started_at_door", game.doors_opened))
			if game.doors_opened <= started_at_door:
				kept_entries.append(fusion_entry.duplicate(true))
				continue
			var candidate_key: String = fusion_entry_key(fusion_entry)
			if not candidate_by_key.has(candidate_key):
				continue
			var resolved_entry: Dictionary = Dictionary(candidate_by_key[candidate_key]).duplicate(true)
			resolved_entry["started_at_door"] = started_at_door
			if resolve_spell_scroll_fusion_entry(game, hero, resolved_entry):
				overlay_needs_refresh = true
		hero.pending_item_fusions = kept_entries
		if sync_pending_item_fusions_for_hero(game, hero):
			overlay_needs_refresh = true
	if overlay_needs_refresh:
		game.refresh_open_inventory_overlay()

static func advance_spell_scroll_studies(game: Node) -> void:
	var overlay_needs_refresh: bool = false
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		if sync_pending_item_fusions_for_hero(game, hero):
			overlay_needs_refresh = true
	if overlay_needs_refresh:
		game.refresh_open_inventory_overlay()

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
	var current_bonus: Dictionary = hero_level_stat_bonuses(game, hero.level, String(hero.hero_class_id))
	var next_bonus: Dictionary = hero_level_stat_bonuses(game, hero.level + 1, String(hero.hero_class_id))
	var health_gain: int = int(round(float(next_bonus.get("health", 0.0)) - float(current_bonus.get("health", 0.0))))
	var attack_gain: int = int(round(float(next_bonus.get("attack", 0.0)) - float(current_bonus.get("attack", 0.0))))
	var defence_gain: int = int(round(float(next_bonus.get("defence", 0.0)) - float(current_bonus.get("defence", 0.0))))
	var speed_gain: int = int(round(float(next_bonus.get("speed", 0.0)) - float(current_bonus.get("speed", 0.0))))
	var next_pack_size: Vector2i = hero_next_pack_size(game, hero)
	var unlock_names: Array[String] = hero_next_level_unlock_names(game, hero)
	reward_lines.append("Stats +%d hp  +%d dmg  +%d def  +%d spd" % [health_gain, attack_gain, defence_gain, speed_gain])
	reward_lines.append("Pack %dx%d inventory module" % [next_pack_size.x, next_pack_size.y])
	if unlock_names.is_empty():
		reward_lines.append("Passive ability: none this level")
	else:
		reward_lines.append("Passive ability: %s" % ", ".join(PackedStringArray(unlock_names)))
	return reward_lines

static func level_up_food_cost(_game: Node, level_value: int) -> int:
	return GAME_HERO_LEVEL_DEFS.level_up_food_cost(level_value)

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
	var level_bonuses: Dictionary = hero_level_stat_bonuses(game, hero.level, String(hero.hero_class_id))
	var used_cells: int = 0
	for item_variant in items:
		used_cells += game.item_occupied_cells(item_variant).size()
	var stat_lines: Array[String] = []
	stat_lines.append("Damage %d" % int(round(hero.base_attack_damage + float(level_bonuses.get("attack", 0.0)) + float(bonuses["attack"]))))
	stat_lines.append("Defence %d" % int(round(hero.base_defence + float(level_bonuses.get("defence", 0.0)) + float(bonuses.get("defence", bonuses.get("defense", 0.0))))))
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
		"dagger_card", "rogue_combo_dagger_card":
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
	var level_bonuses: Dictionary = hero_level_stat_bonuses(game, hero.level, String(hero.hero_class_id))
	hero.apply_inventory_stats(
		float(level_bonuses.get("speed", 0.0)) + float(bonuses["speed"]),
		float(level_bonuses.get("health", 0.0)) + float(bonuses["health"]),
		float(level_bonuses.get("attack", 0.0)) + float(bonuses["attack"]),
		float(level_bonuses.get("defence", 0.0)) + float(bonuses.get("defence", bonuses.get("defense", 0.0))),
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
