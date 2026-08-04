extends RefCounted

static func hand_card_level(game: Node, hand_card: Dictionary) -> int:
	var spell_level: int = int(hand_card.get("spell_level", 0))
	if spell_level > 0:
		return spell_level
	var item_level: int = int(hand_card.get("item_level", 0))
	if item_level > 0:
		return item_level
	var card_id: String = String(hand_card.get("card_id", ""))
	if card_id != "":
		var card_def: Dictionary = game.card_definition(card_id)
		spell_level = int(card_def.get("spell_level", 0))
		if spell_level > 0:
			return spell_level
		item_level = int(card_def.get("item_level", 0))
		if item_level > 0:
			return item_level
	var item_id: String = String(hand_card.get("item_id", ""))
	if item_id != "":
		item_level = int(game.item_defs.get(item_id, {}).get("item_level", 1))
		if item_level > 0:
			return item_level
	return 0

static func sort_hero_hand_cards_by_level(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero) or hero.hand_cards.size() <= 1:
		return
	var decorated_cards: Array = []
	for hand_index in range(hero.hand_cards.size()):
		var hand_card: Dictionary = (hero.hand_cards[hand_index] as Dictionary).duplicate(true)
		var generator_key: String = String(hand_card.get("generator_key", ""))
		if generator_key == "":
			var fallback_item_uid: int = int(hand_card.get("item_uid", -1))
			generator_key = "%d:%s" % [fallback_item_uid, String(hand_card.get("card_id", ""))]
		decorated_cards.append({
			"level": hand_card_level(game, hand_card),
			"generator_key": generator_key,
			"card_id": String(hand_card.get("card_id", "")),
			"item_uid": int(hand_card.get("item_uid", -1)),
			"uid": int(hand_card.get("uid", -1)),
			"index": hand_index,
			"card": hand_card,
		})
	decorated_cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var level_a: int = int(a.get("level", 0))
		var level_b: int = int(b.get("level", 0))
		if level_a != level_b:
			return level_a > level_b
		var generator_key_a: String = String(a.get("generator_key", ""))
		var generator_key_b: String = String(b.get("generator_key", ""))
		if generator_key_a != generator_key_b:
			return generator_key_a < generator_key_b
		var card_id_a: String = String(a.get("card_id", ""))
		var card_id_b: String = String(b.get("card_id", ""))
		if card_id_a != card_id_b:
			return card_id_a < card_id_b
		var item_uid_a: int = int(a.get("item_uid", -1))
		var item_uid_b: int = int(b.get("item_uid", -1))
		if item_uid_a != item_uid_b:
			return item_uid_a < item_uid_b
		var uid_a: int = int(a.get("uid", -1))
		var uid_b: int = int(b.get("uid", -1))
		if uid_a != uid_b:
			return uid_a < uid_b
		return int(a.get("index", 0)) < int(b.get("index", 0))
	)
	var sorted_hand: Array = []
	for decorated_variant in decorated_cards:
		sorted_hand.append((decorated_variant as Dictionary).get("card", {}))
	hero.hand_cards = sorted_hand

static func generator_base_door_interval(game: Node, generator: Dictionary, card_def: Dictionary) -> int:
	var base_interval: int = maxi(1, int(card_def.get("door_interval", int(generator.get("door_interval", 1)))))
	if not bool(generator.get("cooldown_scales_with_item_level", false)):
		return base_interval
	var item_level: int = maxi(1, int(generator.get("item_level", game.item_defs.get(String(generator.get("item_id", "")), {}).get("item_level", 1))))
	# Higher item level shortens the door cooldown, capped at one door.
	return maxi(1, base_interval - (item_level - 1))

static func generator_effective_door_interval(game: Node, generator: Dictionary, card_def: Dictionary, item_bonus: Dictionary) -> int:
	var base_interval: int = generator_base_door_interval(game, generator, card_def)
	var interval_multiplier: float = float(item_bonus.get("card_charge_mult", 1.0))
	return maxi(1, int(round(float(base_interval) * interval_multiplier)))

static func build_hand_card_from_generator(game: Node, hero: Variant, generator: Dictionary, effect_summary: Dictionary) -> Dictionary:
	var card_def: Dictionary = game.card_definition(String(generator.get("card_id", "")))
	var item_bonus: Dictionary = Dictionary(generator.get("item_bonus", game.empty_inventory_effect_summary()))
	var card_id: String = String(card_def.get("id", ""))
	var generator_key: String = game.resolve_generator_key(generator, card_def)
	var phase: String = String(generator.get("phase_override", card_def.get("phase", "combat")))
	var target_scope: String = String(generator.get("target_scope_override", card_def.get("target_scope", "same_room")))
	var expires_after_turns: int = int(card_def.get("expires_after_turns", int(generator.get("expires_after_turns", 0))))
	var description_lines: Array = Array(generator.get("description_lines_override", card_def.get("description_lines", [])))
	var reaction_default_enabled: bool = bool(card_def.get("reaction_default_enabled", false))
	var reaction_enabled: bool = reaction_default_enabled
	if hero != null and is_instance_valid(hero) and hero.has_method("get_reaction_card_preference"):
		reaction_enabled = bool(hero.get_reaction_card_preference(generator_key, card_id, reaction_default_enabled))
	var item_id: String = String(generator.get("item_id", ""))
	var item_def: Dictionary = game.item_defs.get(item_id, {})
	var spell_level: int = maxi(0, int(card_def.get("spell_level", 0)))
	var item_level: int = 0 if item_id == "" else maxi(0, int(generator.get("item_level", item_def.get("item_level", 1))))
	var cooldown_level: int = spell_level if spell_level > 0 else maxi(item_level, 1)
	var effective_interval: int = generator_effective_door_interval(game, generator, card_def, item_bonus)
	var hand_card: Dictionary = {
		"uid": game.next_card_uid,
		"id": card_id,
		"card_id": card_id,
		"name": String(generator.get("name_override", card_def.get("name", "Card"))),
		"item_uid": int(generator.get("item_uid", -1)),
		"item_id": item_id,
		"spell_level": spell_level,
		"item_level": item_level,
		"cooldown_level": cooldown_level,
		"source_type": String(generator.get("source_type", "item")),
		"source_hero_index": int(generator.get("hero_index", hero.hero_index)),
		"phase": phase,
		"target_scope": target_scope,
		"target_scope_label": game.card_target_scope_label(target_scope),
		"description_lines": description_lines,
		"door_interval": effective_interval,
		"generation_mode": game.resolve_card_generator_mode(generator, card_def),
		"requires_line_of_effect": bool(card_def.get("requires_line_of_effect", false)),
		"requires_adjacent_room_target": bool(card_def.get("requires_adjacent_room_target", false)),
		"damage": float(card_def.get("base_damage", 0.0)) + float(item_bonus.get("card_damage", 0.0)),
		"projectile_count": int(card_def.get("projectile_count", 1)) + int(item_bonus.get("projectile_count", 0)),
		"spread": float(card_def.get("spread", 0.0)),
		"speed": float(card_def.get("speed", 900.0)),
		"bounces": int(card_def.get("bounces", 0)),
		"pierce": maxi(0, int(card_def.get("pierce", maxi(0, int(card_def.get("max_pierce", 1)) - 1)))),
		"max_pierce": maxi(1, int(card_def.get("max_pierce", int(card_def.get("pierce", 0)) + 1))),
		"lifetime": float(card_def.get("lifetime", 1.5)),
		"radius": float(card_def.get("radius", 12.0)),
		"impact_radius": float(card_def.get("impact_radius", card_def.get("radius", 12.0))),
		"arc_angle_deg": float(card_def.get("arc_angle_deg", 110.0)),
		"knockback_force": float(card_def.get("knockback_force", 0.0)),
		"knockback_duration": float(card_def.get("knockback_duration", 0.18)),
		"slow_duration": float(card_def.get("slow_duration", 0.0)),
		"slow_move_multiplier": float(card_def.get("slow_move_multiplier", 1.0)),
		"slow_attack_speed_multiplier": float(card_def.get("slow_attack_speed_multiplier", 1.0 / maxf(float(card_def.get("slow_attack_cooldown_multiplier", 1.0)), 0.001))),
		"slow_attack_cooldown_multiplier": float(card_def.get("slow_attack_cooldown_multiplier", 1.0)),
		"shield_amount": float(card_def.get("shield_amount", 0.0)),
		"shield_duration": float(card_def.get("shield_duration", 0.0)),
		"immunity_duration": float(card_def.get("immunity_duration", 0.0)),
		"cast_adjacent_hops": int(card_def.get("cast_adjacent_hops", 0)),
		"color": card_def.get("color", Color("d7efff")),
		"backstab_multiplier": float(card_def.get("backstab_multiplier", 1.0)) + float(item_bonus.get("dagger_backstab_bonus", 0.0)),
		"combo_damage_scale": float(card_def.get("combo_damage_scale", 1.5)),
		"bounce_explosion_min_bounces": int(card_def.get("bounce_explosion_min_bounces", 0)),
		"bounce_explosion_impact_radius": float(card_def.get("bounce_explosion_impact_radius", card_def.get("impact_radius", 0.0))),
		"bounce_explosion_damage_multiplier": float(card_def.get("bounce_explosion_damage_multiplier", 1.0)),
		"combo_flatfooted_level_2_threshold": int(card_def.get("combo_flatfooted_level_2_threshold", 2)),
		"combo_flatfooted_level_3_threshold": int(card_def.get("combo_flatfooted_level_3_threshold", 3)),
		"combo_flatfooted_duration_level_2": float(card_def.get("combo_flatfooted_duration_level_2", 2.2)),
		"combo_flatfooted_duration_level_3": float(card_def.get("combo_flatfooted_duration_level_3", 3.8)),
		"combo_flatfooted_damage_taken_multiplier_level_2": float(card_def.get("combo_flatfooted_damage_taken_multiplier_level_2", 1.28)),
		"combo_flatfooted_damage_taken_multiplier_level_3": float(card_def.get("combo_flatfooted_damage_taken_multiplier_level_3", 1.5)),
		"combo_flatfooted_move_multiplier": float(card_def.get("combo_flatfooted_move_multiplier", 1.0)),
		"combo_flatfooted_attack_speed_multiplier": float(card_def.get("combo_flatfooted_attack_speed_multiplier", 1.0)),
		"combo_gain": int(card_def.get("combo_gain", 0)),
		"heal_amount": float(card_def.get("heal_amount", 0.0)),
		"heal_full": bool(card_def.get("heal_full", false)),
		"heal_percent": float(card_def.get("heal_percent", 0.0)),
		"food_buff_duration": float(card_def.get("food_buff_duration", 0.0)),
		"food_attack_cooldown_multiplier": float(card_def.get("food_attack_cooldown_multiplier", 1.0)),
		"food_defence_bonus": float(card_def.get("food_defence_bonus", 0.0)),
		"food_move_speed_multiplier": float(card_def.get("food_move_speed_multiplier", 1.0)),
		"food_cost": int(card_def.get("food_cost", 0)),
		"expires_on_doors_opened": game.doors_opened + expires_after_turns if expires_after_turns > 0 else -1,
		"hero_index": hero.hero_index,
		"max_stored_cards": game.generator_max_stored_cards(generator, card_def),
		"reusable": bool(card_def.get("reusable", false)) or item_level == 0,
		"generator_key": generator_key,
		"consume_item_on_play": bool(generator.get("consume_item_on_play", false)),
		"consume_item_charges_on_play": int(generator.get("consume_item_charges_on_play", 0)),
		"learnable_spell_scroll": bool(generator.get("learnable_spell_scroll", false)),
		"learn_spell_id": String(generator.get("learn_spell_id", card_def.get("id", ""))),
		"reaction_trigger": String(card_def.get("reaction_trigger", "")),
		"reaction_enabled": reaction_enabled,
		"reaction_priority": int(card_def.get("reaction_priority", 0)),
		"auto_cast_on_fatal": bool(card_def.get("auto_cast_on_fatal", false)),
		"summon_enemy_role": String(card_def.get("summon_enemy_role", "")),
		"summon_enemy_roles": Array(card_def.get("summon_enemy_roles", [])).duplicate(true),
		"summon_count": int(card_def.get("summon_count", 1)),
		"summon_attack_damage_override": float(card_def.get("summon_attack_damage_override", 0.0)),
		"summon_behavior": String(card_def.get("summon_behavior", "")),
		"summon_applies_flatfooted": bool(card_def.get("summon_applies_flatfooted", false)),
		"summon_flatfooted_duration": float(card_def.get("summon_flatfooted_duration", 6.0)),
		"summon_flatfooted_move_multiplier": float(card_def.get("summon_flatfooted_move_multiplier", 0.0)),
		"summon_flatfooted_attack_speed_multiplier": float(card_def.get("summon_flatfooted_attack_speed_multiplier", 0.0)),
		"summon_flatfooted_damage_taken_multiplier": float(card_def.get("summon_flatfooted_damage_taken_multiplier", 1.5)),
		"summon_source_label": String(card_def.get("summon_source_label", "A summoned ally")),
		"summon_conversion_duration": float(card_def.get("summon_conversion_duration", 600.0)),
	}
	game.next_card_uid += 1
	return hand_card

static func build_passive_combat_payload(game: Node, passive_ability: Dictionary, effect_summary: Dictionary) -> Dictionary:
	var card_def: Dictionary = game.card_definition(String(passive_ability.get("card_id", "")))
	var item_bonus: Dictionary = Dictionary(passive_ability.get("item_bonus", game.empty_inventory_effect_summary()))
	return {
		"card_id": String(card_def.get("id", "")),
		"damage": float(card_def.get("base_damage", 0.0)) + float(item_bonus.get("card_damage", 0.0)),
		"projectile_count": int(card_def.get("projectile_count", 1)) + int(item_bonus.get("projectile_count", 0)),
		"spread": float(card_def.get("spread", 0.0)),
		"speed": float(card_def.get("speed", 900.0)),
		"bounces": int(card_def.get("bounces", 0)),
		"pierce": maxi(0, int(card_def.get("pierce", maxi(0, int(card_def.get("max_pierce", 1)) - 1)))),
		"lifetime": float(card_def.get("lifetime", 1.5)),
		"radius": float(card_def.get("radius", 12.0)),
		"max_pierce": maxi(1, int(card_def.get("max_pierce", int(card_def.get("pierce", 0)) + 1))),
		"knockback_force": float(card_def.get("knockback_force", 220.0)),
		"knockback_duration": float(card_def.get("knockback_duration", 0.18)),
		"final_hit_knockback_multiplier": float(card_def.get("final_hit_knockback_multiplier", 1.9)),
		"color": card_def.get("color", Color("d7efff")),
		"backstab_multiplier": float(card_def.get("backstab_multiplier", 1.0)) + float(item_bonus.get("dagger_backstab_bonus", 0.0)),
		"combo_damage_scale": float(card_def.get("combo_damage_scale", 1.5)),
		"bounce_explosion_min_bounces": int(card_def.get("bounce_explosion_min_bounces", 0)),
		"bounce_explosion_impact_radius": float(card_def.get("bounce_explosion_impact_radius", card_def.get("impact_radius", 0.0))),
		"bounce_explosion_damage_multiplier": float(card_def.get("bounce_explosion_damage_multiplier", 1.0)),
		"combo_flatfooted_level_2_threshold": int(card_def.get("combo_flatfooted_level_2_threshold", 2)),
		"combo_flatfooted_level_3_threshold": int(card_def.get("combo_flatfooted_level_3_threshold", 3)),
		"combo_flatfooted_duration_level_2": float(card_def.get("combo_flatfooted_duration_level_2", 2.2)),
		"combo_flatfooted_duration_level_3": float(card_def.get("combo_flatfooted_duration_level_3", 3.8)),
		"combo_flatfooted_damage_taken_multiplier_level_2": float(card_def.get("combo_flatfooted_damage_taken_multiplier_level_2", 1.28)),
		"combo_flatfooted_damage_taken_multiplier_level_3": float(card_def.get("combo_flatfooted_damage_taken_multiplier_level_3", 1.5)),
		"combo_flatfooted_move_multiplier": float(card_def.get("combo_flatfooted_move_multiplier", 1.0)),
		"combo_flatfooted_attack_speed_multiplier": float(card_def.get("combo_flatfooted_attack_speed_multiplier", 1.0)),
		"combo_gain": int(card_def.get("combo_gain", 0)),
	}

static func sync_hero_builtin_card_sources(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var builtin_generators: Array = game.hero_builtin_card_generators(hero)
	var valid_keys: Dictionary = {}
	for generator_variant in builtin_generators:
		var generator: Dictionary = Dictionary(generator_variant).duplicate(true)
		var generator_key: String = String(generator.get("generator_key", "hero:%d:%s" % [hero.hero_index, String(generator.get("card_id", ""))]))
		valid_keys[generator_key] = true
		var card_def: Dictionary = game.card_definition(String(generator.get("card_id", "")))
		var effective_interval: int = maxi(1, int(card_def.get("door_interval", int(generator.get("door_interval", 1)))))
		var persistent_card: bool = bool(generator.get("persistent_card", false))
		var initial_queued_cards: int = maxi(0, int(generator.get("initial_queued_cards", 0)))
		var max_stored_cards: int = game.generator_max_stored_cards(generator, card_def)
		var current_stored_cards: int = game.hero_hand_card_count_for_generator_key(hero, generator_key)
		if not hero.card_generation_timers.has(generator_key):
			var starting_queued_cards: int = 0
			if persistent_card:
				starting_queued_cards = 1
			starting_queued_cards = maxi(starting_queued_cards, initial_queued_cards)
			if max_stored_cards > 0:
				starting_queued_cards = mini(starting_queued_cards, maxi(0, max_stored_cards - current_stored_cards))
			hero.card_generation_timers[generator_key] = {
				"generator": generator,
				"interval": effective_interval,
				"remaining_doors": effective_interval,
				"queued_cards": starting_queued_cards,
			}
			continue
		var state: Dictionary = Dictionary(hero.card_generation_timers.get(generator_key, {})).duplicate(true)
		state["generator"] = generator
		state["interval"] = effective_interval
		state["remaining_doors"] = clampi(int(state.get("remaining_doors", effective_interval)), 1, effective_interval)
		hero.card_generation_timers[generator_key] = state
	var stale_keys: Array = []
	for timer_key_variant in hero.card_generation_timers.keys():
		var timer_key: String = String(timer_key_variant)
		if not valid_keys.has(timer_key):
			stale_keys.append(timer_key)
	for stale_key_variant in stale_keys:
		hero.card_generation_timers.erase(String(stale_key_variant))

static func fill_queued_hero_builtin_cards(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	sync_hero_builtin_card_sources(game, hero)
	for generator_variant in game.hero_builtin_card_generators(hero):
		var generator_for_key: Dictionary = Dictionary(generator_variant).duplicate(true)
		var timer_key: String = String(generator_for_key.get("generator_key", "hero:%d:%s" % [hero.hero_index, String(generator_for_key.get("card_id", ""))]))
		if not hero.card_generation_timers.has(timer_key):
			continue
		var state: Dictionary = Dictionary(hero.card_generation_timers.get(timer_key, {})).duplicate(true)
		var queued_cards: int = int(state.get("queued_cards", 0))
		var generator: Dictionary = Dictionary(state.get("generator", {})).duplicate(true)
		var max_stored_cards: int = game.generator_max_stored_cards(generator)
		var current_stored_cards: int = game.hero_hand_card_count_for_generator_key(hero, timer_key) + queued_cards
		if bool(generator.get("persistent_card", false)) and (max_stored_cards <= 0 or current_stored_cards < max_stored_cards):
			queued_cards = 1
		while queued_cards > 0:
			hero.hand_cards.append(build_hand_card_from_generator(game, hero, generator, game.empty_inventory_effect_summary()))
			queued_cards -= 1
		state["queued_cards"] = queued_cards
		hero.card_generation_timers[timer_key] = state
	sort_hero_hand_cards_by_level(game, hero)

static func advance_hero_builtin_door_card_generators(game: Node, door_count: int = 1) -> void:
	if door_count <= 0:
		return
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		sync_hero_builtin_card_sources(game, hero)
		for timer_key_variant in hero.card_generation_timers.keys():
			var timer_key: String = String(timer_key_variant)
			var state: Dictionary = Dictionary(hero.card_generation_timers.get(timer_key, {})).duplicate(true)
			var generator: Dictionary = Dictionary(state.get("generator", {})).duplicate(true)
			if String(generator.get("generation_mode", game.resolve_card_generator_mode(generator))) != "door_interval":
				hero.card_generation_timers[timer_key] = state
				continue
			var remaining_doors: int = int(state.get("remaining_doors", 1)) - door_count
			var interval: int = maxi(1, int(state.get("interval", 1)))
			var queued_cards: int = int(state.get("queued_cards", 0))
			var max_stored_cards: int = game.generator_max_stored_cards(generator)
			while remaining_doors <= 0:
				var current_stored_cards: int = queued_cards + game.hero_hand_card_count_for_generator_key(hero, timer_key)
				if max_stored_cards <= 0 or current_stored_cards < max_stored_cards:
					queued_cards += 1
				remaining_doors += interval
			state["remaining_doors"] = remaining_doors
			state["queued_cards"] = queued_cards
			hero.card_generation_timers[timer_key] = state
		fill_queued_hero_builtin_cards(game, hero)

static func expire_door_turn_hand_cards(game: Node) -> void:
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		var filtered_hand: Array = []
		for hand_card_variant in hero.hand_cards:
			var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
			var expires_on: int = int(hand_card.get("expires_on_doors_opened", -1))
			if expires_on >= 0 and game.doors_opened >= expires_on:
				continue
			filtered_hand.append(hand_card)
		hero.hand_cards = filtered_hand

static func sync_hero_card_sources(game: Node, hero: Variant, effect_summary: Dictionary = {}) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var resolved_summary: Dictionary = effect_summary if not effect_summary.is_empty() else game.inventory_effect_summary(hero.inventory_items)
	var resolved_generators: Array = Array(resolved_summary.get("card_generators", [])).duplicate(true)
	for spell_generator_variant in game.spellbook_card_generators(hero, resolved_summary):
		resolved_generators.append((spell_generator_variant as Dictionary).duplicate(true))
	var initially_exhausted_item_uids: Dictionary = {}
	for generator_variant in resolved_generators:
		var generator: Dictionary = generator_variant
		var key: String = game.resolve_generator_key(generator)
		var item_bonus: Dictionary = Dictionary(generator.get("item_bonus", {}))
		var card_def: Dictionary = game.card_definition(String(generator.get("card_id", "")))
		var generation_mode: String = game.resolve_card_generator_mode(generator, card_def)
		var effective_interval: int = generator_effective_door_interval(game, generator, card_def, item_bonus)
		var exhaust_cards: int = int(generator.get("exhaust_cards", 0))
		var max_stored_cards: int = game.generator_max_stored_cards(generator, card_def)
		var current_stored_cards: int = game.hero_hand_card_count_for_generator_key(hero, key)
		var initial_queued_cards: int = maxi(1, int(generator.get("initial_queued_cards", 1)))
		if max_stored_cards > 0:
			initial_queued_cards = mini(initial_queued_cards, maxi(0, max_stored_cards - current_stored_cards))
		if not game.global_item_card_states.has(key):
			var initial_state: Dictionary = {
				"item_uid": int(generator.get("item_uid", -1)),
				"generation_mode": generation_mode,
				"remaining_doors": effective_interval,
				"interval": effective_interval,
				"queued_cards": 0 if current_stored_cards > 0 else initial_queued_cards,
				"remaining_generations": 0,
				"allow_orphaned_cards": false,
			}
			if generation_mode == "door_interval":
				initial_state["remaining_generations"] = max(exhaust_cards - 1, 0) if exhaust_cards > 0 else -1
				if exhaust_cards == 1:
					initial_state["allow_orphaned_cards"] = true
					initially_exhausted_item_uids[int(generator.get("item_uid", -1))] = true
			game.global_item_card_states[key] = initial_state
		else:
			var state: Dictionary = Dictionary(game.global_item_card_states.get(key, {})).duplicate(true)
			state["generation_mode"] = generation_mode
			state["interval"] = effective_interval
			if generation_mode == "door_interval":
				state["remaining_doors"] = clampi(int(state.get("remaining_doors", effective_interval)), 1, effective_interval)
			else:
				state["remaining_doors"] = effective_interval
			game.global_item_card_states[key] = state
	for exhausted_uid_variant in initially_exhausted_item_uids.keys():
		game.remove_item_by_uid_from_world(int(exhausted_uid_variant))
	game.cleanup_global_item_card_states()
	var valid_item_uids: Dictionary = {}
	var valid_generator_keys: Dictionary = {}
	for item_variant in hero.inventory_items:
		var inventory_item: Dictionary = item_variant as Dictionary
		var item_uid: int = int(inventory_item.get("uid", -1))
		valid_item_uids[item_uid] = true
	for generator_variant in resolved_generators:
		var generator: Dictionary = generator_variant
		var generator_key: String = game.resolve_generator_key(generator)
		valid_generator_keys[generator_key] = true
	var filtered_hand: Array = []
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
		if String(hand_card.get("source_type", "item")) == "hero_builtin":
			if int(hand_card.get("source_hero_index", -1)) == hero.hero_index:
				filtered_hand.append(hand_card)
			continue
		var hand_item_uid: int = int(hand_card.get("item_uid", -1))
		var hand_key: String = String(hand_card.get("generator_key", game.card_generator_key(hand_item_uid, String(hand_card.get("card_id", "")))))
		if valid_item_uids.has(hand_item_uid):
			if not valid_generator_keys.has(hand_key):
				continue
			filtered_hand.append(hand_card)
		else:
			var hand_state: Dictionary = Dictionary(game.global_item_card_states.get(hand_key, {}))
			if bool(hand_state.get("allow_orphaned_cards", false)):
				filtered_hand.append(hand_card)
			elif game.global_item_card_states.has(hand_key):
				hand_state = Dictionary(game.global_item_card_states.get(hand_key, {})).duplicate(true)
				hand_state["queued_cards"] = int(hand_state.get("queued_cards", 0)) + 1
				game.global_item_card_states[hand_key] = hand_state
	hero.hand_cards = filtered_hand
	fill_queued_hand_cards(game, hero, resolved_summary, resolved_generators)

static func sync_hero_passive_combat_sources(game: Node, hero: Variant, effect_summary: Dictionary = {}) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var resolved_summary: Dictionary = effect_summary if not effect_summary.is_empty() else game.inventory_effect_summary(hero.inventory_items)
	for passive_variant in Array(resolved_summary.get("combat_passives", [])):
		var passive_ability: Dictionary = passive_variant
		var key: String = game.combat_passive_key(int(passive_ability.get("item_uid", -1)), String(passive_ability.get("card_id", "")))
		var item_bonus: Dictionary = Dictionary(passive_ability.get("item_bonus", {}))
		var card_def: Dictionary = game.card_definition(String(passive_ability.get("card_id", "")))
		var base_cooldown: float = float(passive_ability.get("cooldown", card_def.get("test_cooldown", 1.5)))
		var effective_cooldown: float = maxf(base_cooldown * float(item_bonus.get("card_charge_mult", 1.0)), 0.25)
		if not game.global_item_passive_timers.has(key):
			game.global_item_passive_timers[key] = {
				"item_uid": int(passive_ability.get("item_uid", -1)),
				"timer_left": effective_cooldown,
				"last_wave_triggered": -1,
			}
		else:
			var passive_state: Dictionary = Dictionary(game.global_item_passive_timers.get(key, {})).duplicate(true)
			passive_state["timer_left"] = minf(float(passive_state.get("timer_left", effective_cooldown)), effective_cooldown)
			if not passive_state.has("last_wave_triggered"):
				passive_state["last_wave_triggered"] = -1
			game.global_item_passive_timers[key] = passive_state
	var known_item_uids: Dictionary = game.collect_world_item_uids()
	var stale_keys: Array = []
	for timer_key_variant in game.global_item_passive_timers.keys():
		var timer_key: String = String(timer_key_variant)
		var passive_state: Dictionary = Dictionary(game.global_item_passive_timers.get(timer_key, {}))
		if not known_item_uids.has(int(passive_state.get("item_uid", -1))):
			stale_keys.append(timer_key)
	for stale_key_variant in stale_keys:
		game.global_item_passive_timers.erase(String(stale_key_variant))

static func fill_queued_hand_cards(game: Node, hero: Variant, effect_summary: Dictionary = {}, precomputed_generators: Array = []) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var resolved_summary: Dictionary = effect_summary if not effect_summary.is_empty() else game.inventory_effect_summary(hero.inventory_items)
	var resolved_generators: Array = precomputed_generators.duplicate(true) if not precomputed_generators.is_empty() else Array(resolved_summary.get("card_generators", [])).duplicate(true)
	if precomputed_generators.is_empty():
		for spell_generator_variant in game.spellbook_card_generators(hero, resolved_summary):
			resolved_generators.append((spell_generator_variant as Dictionary).duplicate(true))
	for generator_variant in resolved_generators:
		var generator: Dictionary = Dictionary(generator_variant).duplicate(true)
		var timer_key: String = game.resolve_generator_key(generator)
		if not game.global_item_card_states.has(timer_key):
			continue
		var state: Dictionary = Dictionary(game.global_item_card_states.get(timer_key, {})).duplicate(true)
		var queued_cards: int = int(state.get("queued_cards", 0))
		while queued_cards > 0:
			hero.hand_cards.append(build_hand_card_from_generator(game, hero, generator, resolved_summary))
			queued_cards -= 1
		state["queued_cards"] = queued_cards
		game.global_item_card_states[timer_key] = state
	fill_queued_hero_builtin_cards(game, hero)
	sort_hero_hand_cards_by_level(game, hero)

static func advance_item_door_card_generators(game: Node, door_count: int = 1) -> void:
	if door_count <= 0:
		return
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		var effect_summary: Dictionary = game.inventory_effect_summary(hero.inventory_items)
		var resolved_generators: Array = Array(effect_summary.get("card_generators", [])).duplicate(true)
		for spell_generator_variant in game.spellbook_card_generators(hero, effect_summary):
			resolved_generators.append((spell_generator_variant as Dictionary).duplicate(true))
		sync_hero_card_sources(game, hero, effect_summary)
		var exhausted_item_uids: Dictionary = {}
		for generator_variant in resolved_generators:
			var generator: Dictionary = generator_variant
			var key: String = game.resolve_generator_key(generator)
			var state: Dictionary = Dictionary(game.global_item_card_states.get(key, {})).duplicate(true)
			if state.is_empty():
				continue
			if String(state.get("generation_mode", game.resolve_card_generator_mode(generator))) != "door_interval":
				continue
			var remaining_doors: int = int(state.get("remaining_doors", 1)) - door_count
			var interval: int = maxi(1, int(state.get("interval", 1)))
			var queued_cards: int = int(state.get("queued_cards", 0))
			var remaining_generations: int = int(state.get("remaining_generations", -1))
			var max_stored_cards: int = game.generator_max_stored_cards(generator)
			while remaining_doors <= 0:
				if remaining_generations == 0:
					break
				var current_stored_cards: int = queued_cards + game.hero_hand_card_count_for_generator_key(hero, key)
				if max_stored_cards <= 0 or current_stored_cards < max_stored_cards:
					queued_cards += 1
				if remaining_generations > 0:
					remaining_generations -= 1
				remaining_doors += interval
			state["remaining_doors"] = remaining_doors
			state["queued_cards"] = queued_cards
			state["remaining_generations"] = remaining_generations
			if remaining_generations == 0:
				state["allow_orphaned_cards"] = true
				exhausted_item_uids[int(state.get("item_uid", -1))] = true
			game.global_item_card_states[key] = state
		for exhausted_uid_variant in exhausted_item_uids.keys():
			game.remove_item_by_uid_from_world(int(exhausted_uid_variant))
		fill_queued_hand_cards(game, hero, effect_summary, resolved_generators)
	game.cleanup_global_item_card_states()
