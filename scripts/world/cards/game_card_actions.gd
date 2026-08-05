extends RefCounted

const GAME_ENEMY_DEFS: GDScript = preload("res://scripts/content/game_enemy_defs.gd")
const GAME_DUNGEON_BUILDER: GDScript = preload("res://scripts/world/rooms/game_dungeon_builder.gd")

static func hero_hand_card_index(_game: Node, hero: Variant, card_uid: int) -> int:
	if hero == null or not is_instance_valid(hero):
		return -1
	for card_index in range(hero.hand_cards.size()):
		if int((hero.hand_cards[card_index] as Dictionary).get("uid", -1)) == card_uid:
			return card_index
	return -1

static func hero_hand_card_index_by_id(_game: Node, hero: Variant, card_id: String) -> int:
	if hero == null or not is_instance_valid(hero) or card_id == "":
		return -1
	for card_index in range(hero.hand_cards.size()):
		if String((hero.hand_cards[card_index] as Dictionary).get("card_id", "")) == card_id:
			return card_index
	return -1

static func card_supports_reaction(_game: Node, hand_card: Dictionary) -> bool:
	return String(hand_card.get("reaction_trigger", "")) != ""

static func reaction_nonrenewable_cost(hand_card: Dictionary) -> int:
	return maxi(0, int(hand_card.get("food_cost", 0))) + maxi(0, int(hand_card.get("arcana_cost", hand_card.get("science_cost", 0)))) + maxi(0, int(hand_card.get("material_cost", hand_card.get("industry_cost", 0))))

static func reaction_consumes_source(hand_card: Dictionary) -> bool:
	return bool(hand_card.get("consume_item_on_play", false)) or int(hand_card.get("consume_item_charges_on_play", 0)) > 0

static func reaction_priority_value(hand_card: Dictionary) -> int:
	var card_id: String = String(hand_card.get("card_id", ""))
	if card_id == "sunpepper_jerky_card" or card_id == "moon_truffle_card" or card_id == "tidekelp_roll_card":
		return maxi(int(hand_card.get("reaction_priority", 0)), 30)
	if card_id == "emergency_snack_card":
		return mini(int(hand_card.get("reaction_priority", 0)), 0)
	return int(hand_card.get("reaction_priority", 0))

static func play_reaction_card_for_hero_at_index(game: Node, hero: Variant, hand_index: int, trigger_id: String = "", reaction_target_hero: Variant = null) -> bool:
	if hero == null or not is_instance_valid(hero) or hero.carrying_crystal or hand_index < 0 or hand_index >= hero.hand_cards.size():
		return false
	var hand_card: Dictionary = (hero.hand_cards[hand_index] as Dictionary).duplicate(true)
	if not game.hand_card_phase_allows_play(hand_card):
		return false
	var resolved_reaction_target_hero: Variant = reaction_target_hero
	if resolved_reaction_target_hero == null or not is_instance_valid(resolved_reaction_target_hero):
		resolved_reaction_target_hero = hero
	var resolved_reaction_room: Vector2i = resolved_reaction_target_hero.current_room if resolved_reaction_target_hero != null and is_instance_valid(resolved_reaction_target_hero) else hero.current_room
	var resolved_reaction_world_position: Vector2 = resolved_reaction_target_hero.global_position if resolved_reaction_target_hero != null and is_instance_valid(resolved_reaction_target_hero) else hero.global_position
	var target_data: Dictionary = {
		"hero": resolved_reaction_target_hero,
		"room": resolved_reaction_room,
		"world_position": resolved_reaction_world_position,
		"reaction_trigger": trigger_id,
	}
	if not game.apply_hand_card_effect(hero, hand_card, target_data):
		return false
	if not bool(hand_card.get("reusable", false)):
		hero.hand_cards.remove_at(hand_index)
		game.finalize_played_hand_card_source(hand_card)
	game.fill_queued_hand_cards(hero)
	game.cleanup_global_item_card_states()
	return true

static func first_reaction_card_index_for_trigger(game: Node, hero: Variant, trigger_id: String) -> int:
	if hero == null or not is_instance_valid(hero) or trigger_id == "":
		return -1
	var best_index: int = -1
	var best_nonrenewable_penalty: int = 2
	var best_consumes_source_penalty: int = 2
	var best_priority: int = -999999
	var best_nonrenewable_cost: int = 999999
	for hand_index in range(hero.hand_cards.size()):
		var hand_card: Dictionary = hero.hand_cards[hand_index]
		if String(hand_card.get("reaction_trigger", "")) != trigger_id or not bool(hand_card.get("reaction_enabled", false)):
			continue
		if not game.hand_card_phase_allows_play(hand_card):
			continue
		var nonrenewable_cost: int = reaction_nonrenewable_cost(hand_card)
		var nonrenewable_penalty: int = 1 if nonrenewable_cost > 0 else 0
		var consumes_source_penalty: int = 1 if reaction_consumes_source(hand_card) else 0
		var priority_value: int = reaction_priority_value(hand_card)
		if best_index < 0 \
		or nonrenewable_penalty < best_nonrenewable_penalty \
		or (nonrenewable_penalty == best_nonrenewable_penalty and consumes_source_penalty < best_consumes_source_penalty) \
		or (nonrenewable_penalty == best_nonrenewable_penalty and consumes_source_penalty == best_consumes_source_penalty and priority_value > best_priority) \
		or (nonrenewable_penalty == best_nonrenewable_penalty and consumes_source_penalty == best_consumes_source_penalty and priority_value == best_priority and nonrenewable_cost < best_nonrenewable_cost):
			best_index = hand_index
			best_nonrenewable_penalty = nonrenewable_penalty
			best_consumes_source_penalty = consumes_source_penalty
			best_priority = priority_value
			best_nonrenewable_cost = nonrenewable_cost
	return best_index

static func first_room_rescue_cure_reaction_for_fallen_hero(game: Node, fallen_hero: Variant) -> Dictionary:
	if fallen_hero == null or not is_instance_valid(fallen_hero):
		return {}
	var fallen_room: Vector2i = fallen_hero.current_room
	if fallen_room == game.INVALID_ROOM or not game.rooms.has(fallen_room):
		return {}
	var best: Dictionary = {}
	var best_priority: int = -999999
	for room_hero in game.heroes_in_room(fallen_room):
		if room_hero == null or not is_instance_valid(room_hero) or room_hero.carrying_crystal:
			continue
		var reaction_index: int = first_reaction_card_index_for_trigger(game, room_hero, "ally_fatal_in_room")
		if reaction_index < 0:
			continue
		var reaction_card: Dictionary = room_hero.hand_cards[reaction_index]
		if String(reaction_card.get("card_id", "")) != "cure_light_wounds_card":
			continue
		var reaction_priority: int = reaction_priority_value(reaction_card)
		if best.is_empty() or reaction_priority > best_priority:
			best = {
				"hero": room_hero,
				"index": reaction_index,
			}
			best_priority = reaction_priority
	return best

static func trigger_first_reaction_card(game: Node, hero: Variant, trigger_id: String) -> bool:
	if hero == null or not is_instance_valid(hero) or hero.carrying_crystal:
		return false
	var hand_index: int = first_reaction_card_index_for_trigger(game, hero, trigger_id)
	if hand_index < 0:
		return false
	return play_reaction_card_for_hero_at_index(game, hero, hand_index, trigger_id)

static func can_activate_card_with_reactions(_game: Node, hero: Variant, _activation_cost: float = 0.0) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	return true

static func cooldown_level_for_generator(game: Node, generator: Dictionary, card_def: Dictionary) -> int:
	var spell_level: int = maxi(0, int(card_def.get("spell_level", 0)))
	if spell_level > 0:
		return spell_level
	var item_level: int = maxi(0, int(generator.get("item_level", 0)))
	if item_level > 0:
		return item_level
	var item_id: String = String(generator.get("item_id", ""))
	if item_id != "":
		item_level = int(game.item_defs.get(item_id, {}).get("item_level", 1))
	return maxi(1, item_level)

static func collect_resettable_cooldowns(game: Node, hero: Variant) -> Array:
	var entries: Array = []
	if hero == null or not is_instance_valid(hero):
		return entries
	var effect_summary: Dictionary = game.inventory_effect_summary(hero.inventory_items)
	var resolved_generators: Array = Array(effect_summary.get("card_generators", [])).duplicate(true)
	for spell_generator_variant in game.spellbook_card_generators(hero, effect_summary):
		resolved_generators.append((spell_generator_variant as Dictionary).duplicate(true))
	var generators_by_key: Dictionary = {}
	for generator_variant in resolved_generators:
		var generator: Dictionary = Dictionary(generator_variant).duplicate(true)
		generators_by_key[game.resolve_generator_key(generator)] = generator
	for state_key_variant in game.global_item_card_states.keys():
		var state_key: String = String(state_key_variant)
		if not generators_by_key.has(state_key):
			continue
		var generator_for_key: Dictionary = Dictionary(generators_by_key[state_key]).duplicate(true)
		var state: Dictionary = Dictionary(game.global_item_card_states.get(state_key, {})).duplicate(true)
		if String(state.get("generation_mode", game.resolve_card_generator_mode(generator_for_key))) != "door_interval":
			continue
		var card_def: Dictionary = game.card_definition(String(generator_for_key.get("card_id", "")))
		var max_stored_cards: int = maxi(1, game.generator_max_stored_cards(generator_for_key, card_def))
		var stored_cards: int = game.hero_hand_card_count_for_generator_key(hero, state_key) + int(state.get("queued_cards", 0))
		if stored_cards >= max_stored_cards:
			continue
		var remaining_doors: int = maxi(0, int(state.get("remaining_doors", 0)))
		if remaining_doors <= 0:
			continue
		entries.append({
			"key": state_key,
			"state": state,
			"generator": generator_for_key,
			"remaining_doors": remaining_doors,
			"cooldown_level": cooldown_level_for_generator(game, generator_for_key, card_def),
		})
	return entries

static func try_reset_cooldowns_with_arcana(game: Node, hero: Variant) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"reason": "no_cooldowns",
		"required_arcana": 0,
		"total_cost": 0,
		"refreshed_cards": 0,
		"reduced_turns": 0,
	}
	var cooldown_entries: Array = collect_resettable_cooldowns(game, hero)
	if cooldown_entries.is_empty():
		return result
	var total_cost: int = 0
	for entry_variant in cooldown_entries:
		var entry: Dictionary = entry_variant
		total_cost += int(entry.get("remaining_doors", 0)) * maxi(1, int(entry.get("cooldown_level", 1))) * game.ARCANA_RESET_COST_PER_LEVEL_PER_TURN
	result["required_arcana"] = total_cost
	if total_cost <= 0:
		return result
	if game.science < total_cost:
		result["reason"] = "not_enough_arcana"
		return result
	game.science -= total_cost
	var refreshed_cards: int = 0
	var reduced_turns: int = 0
	for entry_variant in cooldown_entries:
		var entry: Dictionary = entry_variant
		var key: String = String(entry.get("key", ""))
		if key == "":
			continue
		var state: Dictionary = Dictionary(entry.get("state", {})).duplicate(true)
		var generator: Dictionary = Dictionary(entry.get("generator", {})).duplicate(true)
		var card_def: Dictionary = game.card_definition(String(generator.get("card_id", "")))
		var max_stored_cards: int = maxi(1, game.generator_max_stored_cards(generator, card_def))
		var hand_count: int = game.hero_hand_card_count_for_generator_key(hero, key)
		var queue_target: int = maxi(0, max_stored_cards - hand_count)
		state["queued_cards"] = maxi(int(state.get("queued_cards", 0)), queue_target)
		state["remaining_doors"] = maxi(1, int(state.get("interval", state.get("remaining_doors", 1))))
		game.global_item_card_states[key] = state
		refreshed_cards += 1
		reduced_turns += int(entry.get("remaining_doors", 0))
	game.fill_queued_hand_cards(hero)
	game.cleanup_global_item_card_states()
	result["success"] = true
	result["reason"] = ""
	result["total_cost"] = total_cost
	result["refreshed_cards"] = refreshed_cards
	result["reduced_turns"] = reduced_turns
	return result

static func projected_hero_damage_after_barrier(_game: Node, hero: Variant, amount: float) -> float:
	if hero == null or not is_instance_valid(hero):
		return maxf(amount, 0.0)
	return maxf(float(amount) - float(hero.barrier_amount), 0.0)

static func commit_hand_state(game: Node, hero_index: int, hand_state: Array) -> void:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	var cards_by_uid: Dictionary = {}
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
		cards_by_uid[int(hand_card.get("uid", -1))] = hand_card
	var rebuilt_hand: Array = []
	for state_variant in hand_state:
		var state: Dictionary = state_variant as Dictionary
		var card_uid: int = int(state.get("uid", -1))
		if not cards_by_uid.has(card_uid):
			continue
		var rebuilt_card: Dictionary = (cards_by_uid[card_uid] as Dictionary).duplicate(true)
		if card_supports_reaction(game, rebuilt_card):
			var reaction_enabled: bool = bool(state.get("reaction_enabled", rebuilt_card.get("reaction_enabled", false)))
			rebuilt_card["reaction_enabled"] = reaction_enabled
			if hero.has_method("set_reaction_card_preference"):
				hero.set_reaction_card_preference(String(rebuilt_card.get("generator_key", "")), String(rebuilt_card.get("card_id", "")), reaction_enabled)
		rebuilt_hand.append(rebuilt_card)
		cards_by_uid.erase(card_uid)
	for remaining_card_variant in hero.hand_cards:
		var remaining_card: Dictionary = remaining_card_variant as Dictionary
		var remaining_uid: int = int(remaining_card.get("uid", -1))
		if cards_by_uid.has(remaining_uid):
			rebuilt_hand.append((cards_by_uid[remaining_uid] as Dictionary).duplicate(true))
			cards_by_uid.erase(remaining_uid)
	hero.hand_cards = rebuilt_hand

static func serialized_hand_state(_game: Node, hero: Variant) -> Array:
	var state: Array = []
	if hero == null or not is_instance_valid(hero):
		return state
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = hand_card_variant as Dictionary
		state.append({
			"uid": int(hand_card.get("uid", -1)),
			"reaction_enabled": bool(hand_card.get("reaction_enabled", false)),
		})
	return state

static func toggle_hand_card_reaction(game: Node, hero: Variant, hand_index: int) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hand_index < 0 or hand_index >= hero.hand_cards.size():
		return false
	var hand_card: Dictionary = (hero.hand_cards[hand_index] as Dictionary).duplicate(true)
	if not card_supports_reaction(game, hand_card):
		return false
	hand_card["reaction_enabled"] = not bool(hand_card.get("reaction_enabled", false))
	if hero.has_method("set_reaction_card_preference"):
		hero.set_reaction_card_preference(String(hand_card.get("generator_key", "")), String(hand_card.get("card_id", "")), bool(hand_card.get("reaction_enabled", false)))
	hero.hand_cards[hand_index] = hand_card
	return true

static func move_hand_card(_game: Node, hero: Variant, from_index: int, insertion_index: int) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if from_index < 0 or from_index >= hero.hand_cards.size():
		return false
	var clamped_insertion: int = clampi(insertion_index, 0, hero.hand_cards.size())
	if from_index < clamped_insertion:
		clamped_insertion -= 1
	if clamped_insertion == from_index:
		return false
	var moving_card: Dictionary = (hero.hand_cards[from_index] as Dictionary).duplicate(true)
	hero.hand_cards.remove_at(from_index)
	hero.hand_cards.insert(clampi(clamped_insertion, 0, hero.hand_cards.size()), moving_card)
	return true

static func hand_card_by_uid(game: Node, hero: Variant, card_uid: int) -> Dictionary:
	var hand_index: int = hero_hand_card_index(game, hero, card_uid)
	if hand_index < 0:
		return {}
	return (hero.hand_cards[hand_index] as Dictionary).duplicate(true)

static func hero_at_world_position(game: Node, world_position: Vector2, controllable_only: bool = false) -> Variant:
	for hero_index in range(game.heroes.size()):
		var hero: Variant = game.heroes[hero_index]
		if hero == null or not is_instance_valid(hero):
			continue
		if controllable_only and not game.can_local_control_hero_index(hero_index):
			continue
		if hero.global_position.distance_to(world_position) <= game.HERO_SELECTION_RADIUS:
			return hero
	return null

static func room_target_at_world_position(game: Node, world_position: Vector2, preferred_from_room: Vector2i = Vector2i(-99, -99)) -> Vector2i:
	var direct_room: Vector2i = game.room_at_world_position(world_position)
	if direct_room != game.INVALID_ROOM:
		return direct_room
	return game.corridor_room_target_at_position(world_position, preferred_from_room)

static func default_room_card_world_position(game: Node, room_coord: Vector2i, fallback_world_position: Vector2) -> Vector2:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return fallback_world_position
	return game.clamp_point_to_room(fallback_world_position, room_coord)

static func room_has_living_hero(game: Node, room_coord: Vector2i) -> bool:
	for room_hero in game.heroes_in_room(room_coord):
		if room_hero != null and is_instance_valid(room_hero) and room_hero.current_health > 0.0:
			return true
	return false

static func resolve_card_target(game: Node, hero: Variant, hand_card: Dictionary, target_world_position: Vector2) -> Dictionary:
	if hero == null or not is_instance_valid(hero):
		return {}
	var target_scope: String = String(hand_card.get("target_scope", "hero_room"))
	var preferred_from_room: Vector2i = game.active_hero_room_for_commands(hero)
	match target_scope:
		"global":
			return {
				"world_position": target_world_position,
			}
		"hero":
			var target_room: Vector2i = room_target_at_world_position(game, target_world_position, preferred_from_room)
			if target_room == game.INVALID_ROOM or not game.rooms.has(target_room) or not game.rooms[target_room]["opened"] or not room_has_living_hero(game, target_room):
				return {}
			return {
				"room": target_room,
				"world_position": default_room_card_world_position(game, target_room, target_world_position),
			}
		"same_hero":
			var self_room: Vector2i = room_target_at_world_position(game, target_world_position, preferred_from_room)
			if self_room != hero.current_room:
				return {}
			return {
				"room": hero.current_room,
				"world_position": default_room_card_world_position(game, hero.current_room, target_world_position),
			}
		"opened_room":
			var target_room_opened: Vector2i = room_target_at_world_position(game, target_world_position, preferred_from_room)
			if target_room_opened == game.INVALID_ROOM or not game.rooms.has(target_room_opened) or not game.rooms[target_room_opened]["opened"]:
				return {}
			return {
				"room": target_room_opened,
				"world_position": default_room_card_world_position(game, target_room_opened, target_world_position),
			}
		"same_room", "hero_room":
			var same_room_target: Vector2i = room_target_at_world_position(game, target_world_position, preferred_from_room)
			if same_room_target != hero.current_room or not game.rooms.has(hero.current_room):
				return {}
			return {
				"room": hero.current_room,
				"world_position": default_room_card_world_position(game, hero.current_room, target_world_position),
			}
	return {}

static func fallback_room_target_hero(game: Node, source_hero: Variant, room_coord: Vector2i) -> Variant:
	var preferred_hero: Variant = null
	for room_hero in game.heroes_in_room(room_coord):
		if room_hero == null or not is_instance_valid(room_hero) or room_hero.current_health <= 0.0:
			continue
		if room_hero == source_hero:
			return room_hero
		if preferred_hero == null:
			preferred_hero = room_hero
	return preferred_hero

static func most_damaged_hero_in_room(game: Node, room_coord: Vector2i) -> Variant:
	var best_hero: Variant = null
	var best_damage_ratio: float = -1.0
	var best_missing_health: float = -1.0
	for room_hero in game.heroes_in_room(room_coord):
		if room_hero == null or not is_instance_valid(room_hero) or room_hero.current_health <= 0.0:
			continue
		var max_health: float = maxf(room_hero.max_health, 1.0)
		var missing_health: float = maxf(max_health - room_hero.current_health, 0.0)
		if missing_health <= 0.001:
			continue
		var damage_ratio: float = missing_health / max_health
		if best_hero == null or damage_ratio > best_damage_ratio + 0.001 or (absf(damage_ratio - best_damage_ratio) <= 0.001 and missing_health > best_missing_health + 0.001):
			best_hero = room_hero
			best_damage_ratio = damage_ratio
			best_missing_health = missing_health
	return best_hero

static func room_target_hero_for_card(game: Node, source_hero: Variant, hand_card: Dictionary, target_data: Dictionary) -> Variant:
	var explicit_hero: Variant = target_data.get("hero", null)
	var card_id: String = String(hand_card.get("card_id", ""))
	var reaction_trigger: String = String(target_data.get("reaction_trigger", ""))
	if explicit_hero != null and is_instance_valid(explicit_hero) and (explicit_hero.current_health > 0.0 or (card_id == "cure_light_wounds_card" and reaction_trigger == "ally_fatal_in_room")):
		return explicit_hero
	var room_coord: Vector2i = target_data.get("room", game.INVALID_ROOM)
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return source_hero if source_hero != null and is_instance_valid(source_hero) and source_hero.current_health > 0.0 else null
	match card_id:
		"cure_light_wounds_card", "mend_card":
			var heal_target: Variant = most_damaged_hero_in_room(game, room_coord)
			if heal_target != null and is_instance_valid(heal_target):
				return heal_target
	return fallback_room_target_hero(game, source_hero, room_coord)

static func heal_amount_for_card_target(hand_card: Dictionary, target_hero: Variant, fallback_heal_amount: float, fallback_heal_percent: float = 0.0) -> float:
	if target_hero == null or not is_instance_valid(target_hero):
		return maxf(fallback_heal_amount, 0.0)
	var fixed_heal_amount: float = float(hand_card.get("heal_amount", fallback_heal_amount))
	if fixed_heal_amount > 0.0:
		return fixed_heal_amount
	var heal_percent: float = clampf(float(hand_card.get("heal_percent", fallback_heal_percent)), 0.0, 1.0)
	if heal_percent <= 0.0:
		return maxf(fallback_heal_amount, 0.0)
	return maxf(target_hero.max_health * heal_percent, 1.0)

static func card_cast_candidate_rooms(game: Node, target_room: Vector2i, hand_card: Dictionary) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room) or not game.rooms[target_room]["opened"]:
		return candidates
	var max_hops: int = maxi(0, int(hand_card.get("cast_adjacent_hops", 0)))
	var frontier: Array = [{
		"room": target_room,
		"depth": 0,
	}]
	var visited: Dictionary = {
		target_room: true,
	}
	while not frontier.is_empty():
		var entry: Dictionary = frontier.pop_front()
		var room_coord: Vector2i = entry.get("room", game.INVALID_ROOM)
		var depth: int = int(entry.get("depth", 0))
		if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord) or not game.rooms[room_coord]["opened"]:
			continue
		candidates.append(room_coord)
		if depth >= max_hops:
			continue
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if visited.has(neighbor) or not game.rooms.has(neighbor) or not game.rooms[neighbor]["opened"]:
				continue
			visited[neighbor] = true
			frontier.append({
				"room": neighbor,
				"depth": depth + 1,
			})
	return candidates

static func room_has_neighbor(game: Node, room_coord: Vector2i, neighbor: Vector2i) -> bool:
	return game.rooms.has(room_coord) and Array(game.rooms[room_coord].get("neighbors", [])).has(neighbor)

static func card_requires_adjacent_room_target(_game: Node, hand_card: Dictionary) -> bool:
	return bool(hand_card.get("requires_adjacent_room_target", false))

static func evasive_roll_origin_room(game: Node, hero: Variant) -> Vector2i:
	if hero == null or not is_instance_valid(hero):
		return game.INVALID_ROOM
	var world_room: Vector2i = game.room_at_world_position(hero.global_position)
	if world_room != game.INVALID_ROOM and game.rooms.has(world_room):
		return world_room
	if hero.current_room != game.INVALID_ROOM and game.rooms.has(hero.current_room):
		return hero.current_room
	var command_room: Vector2i = game.active_hero_room_for_commands(hero)
	if command_room != game.INVALID_ROOM and game.rooms.has(command_room):
		return command_room
	return game.INVALID_ROOM

static func adjacent_target_valid_for_card(game: Node, hero: Variant, hand_card: Dictionary, target_room: Vector2i) -> bool:
	if not card_requires_adjacent_room_target(game, hand_card):
		return true
	if hero == null or not is_instance_valid(hero) or target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return false
	var cast_room: Vector2i = game.active_hero_room_for_commands(hero)
	var card_id: String = String(hand_card.get("card_id", ""))
	if card_id == "evasive_roll_card" or card_id == "whirling_blade_card":
		cast_room = evasive_roll_origin_room(game, hero)
	if cast_room == game.INVALID_ROOM or not game.rooms.has(cast_room):
		cast_room = hero.current_room
	if card_id == "whirling_blade_card" and cast_room == target_room:
		return true
	return room_has_neighbor(game, cast_room, target_room)

static func travel_distance_for_steps(start_position: Vector2, steps: Array) -> float:
	var total_distance: float = 0.0
	var previous_position: Vector2 = start_position
	for step_variant in steps:
		var step: Dictionary = step_variant
		var step_position: Vector2 = Vector2(step.get("position", previous_position))
		total_distance += previous_position.distance_to(step_position)
		previous_position = step_position
	return total_distance

static func room_interior_rect(game: Node, room_coord: Vector2i, margin: float = 24.0) -> Rect2:
	var walkable_regions: Array = game.room_walkable_regions(room_coord, margin)
	if walkable_regions.is_empty():
		return game.room_rect(room_coord).grow(-margin)
	return game.bounding_rect_for_regions(walkable_regions)

static func cross_room_card_cast_staging_position(game: Node, cast_room: Vector2i, target_room: Vector2i, target_world_position: Vector2) -> Vector2:
	if cast_room == game.INVALID_ROOM or target_room == game.INVALID_ROOM or not game.rooms.has(cast_room) or not game.rooms.has(target_room):
		return Vector2.INF
	if not room_has_neighbor(game, cast_room, target_room):
		return Vector2.INF
	var target_point: Vector2 = game.clamp_point_to_room(target_world_position, target_room)
	var doorway_cast: Vector2 = game.doorway_position(cast_room, target_room)
	var delta: Vector2i = target_room - cast_room
	for inset_step in range(0, 7):
		var inset: float = 56.0 - float(inset_step) * 6.0
		if abs(delta.x) == 1:
			var stage_x: float = doorway_cast.x - float(delta.x) * inset
			var denominator_x: float = target_point.x - stage_x
			if absf(denominator_x) <= 0.001:
				continue
			var interpolation_x: float = (doorway_cast.x - stage_x) / denominator_x
			if interpolation_x <= 0.0 or interpolation_x >= 1.0:
				continue
			var stage_y: float = (doorway_cast.y - interpolation_x * target_point.y) / (1.0 - interpolation_x)
			var candidate: Vector2 = Vector2(stage_x, stage_y)
			if game.room_walkable_contains_point(cast_room, candidate, 20.0):
				return candidate
		elif abs(delta.y) == 1:
			var stage_y_axis: float = doorway_cast.y - float(delta.y) * inset
			var denominator_y: float = target_point.y - stage_y_axis
			if absf(denominator_y) <= 0.001:
				continue
			var interpolation_y: float = (doorway_cast.y - stage_y_axis) / denominator_y
			if interpolation_y <= 0.0 or interpolation_y >= 1.0:
				continue
			var stage_x_axis: float = (doorway_cast.x - interpolation_y * target_point.x) / (1.0 - interpolation_y)
			var candidate_axis: Vector2 = Vector2(stage_x_axis, stage_y_axis)
			if game.room_walkable_contains_point(cast_room, candidate_axis, 20.0):
				return candidate_axis
	return Vector2.INF

static func card_cast_staging_position(game: Node, cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2 = Vector2.INF) -> Vector2:
	if cast_room == game.INVALID_ROOM or not game.rooms.has(cast_room):
		return Vector2.INF
	return game.room_action_staging_position(cast_room)

static func card_can_cast_to_adjacent_room_from_anywhere(game: Node, cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary) -> bool:
	if not bool(hand_card.get("adjacent_cast_anywhere", false)):
		return false
	if cast_room == game.INVALID_ROOM or target_room == game.INVALID_ROOM:
		return false
	return cast_room == target_room or room_has_neighbor(game, cast_room, target_room)

static func card_cast_has_line_of_effect(game: Node, cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2) -> bool:
	return cast_room != game.INVALID_ROOM and target_room != game.INVALID_ROOM and game.rooms.has(cast_room) and game.rooms.has(target_room)

static func hero_ready_for_card_cast(game: Node, hero: Variant, cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2 = Vector2.INF) -> bool:
	if not game.hero_ready_for_room_action(hero, cast_room):
		return false
	return true

static func best_card_cast_room(game: Node, from_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2) -> Vector2i:
	if card_can_cast_to_adjacent_room_from_anywhere(game, from_room, target_room, hand_card):
		return from_room
	var candidates: Array[Vector2i] = card_cast_candidate_rooms(game, target_room, hand_card)
	if candidates.is_empty():
		return game.INVALID_ROOM
	if candidates.has(from_room):
		return from_room
	var best_room: Vector2i = game.INVALID_ROOM
	var best_path_size: int = 999999
	var best_target_distance: int = 999999
	for candidate in candidates:
		var path_size: int = 1
		if candidate != from_room:
			var path: Array[Vector2i] = game.find_path(from_room, candidate, true)
			if path.size() <= 1:
				continue
			path_size = path.size()
		var target_distance: int = 0 if candidate == target_room else 1
		if best_room == game.INVALID_ROOM or path_size < best_path_size or (path_size == best_path_size and target_distance < best_target_distance):
			best_room = candidate
			best_path_size = path_size
			best_target_distance = target_distance
	return best_room

static func card_target_is_valid(game: Node, hero: Variant, hand_card: Dictionary, target_world_position: Vector2) -> bool:
	var target_data: Dictionary = resolve_card_target(game, hero, hand_card, target_world_position)
	if target_data.is_empty():
		return false
	var target_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
	return adjacent_target_valid_for_card(game, hero, hand_card, target_room)

static func hand_card_starts_spell_study(game: Node, hero: Variant, hand_card: Dictionary, target_data: Dictionary) -> bool:
	return false

static func hand_card_phase_allows_play(game: Node, hand_card: Dictionary) -> bool:
	var phase: String = String(hand_card.get("phase", "combat"))
	match phase:
		"out_of_combat":
			return not game.wave_in_progress()
		"combat":
			return game.wave_in_progress()
		"any":
			return true
		_:
			return true

static func apply_hand_card_effect(game: Node, hero: Variant, hand_card: Dictionary, target_data: Dictionary) -> bool:
	if hero == null or not is_instance_valid(hero) or hero.carrying_crystal:
		return false
	var card_id: String = String(hand_card.get("card_id", ""))
	if card_id != "scorcher_card":
		cancel_hero_channel_spell(game, hero)
	var target_world_position: Vector2 = Vector2(target_data.get("world_position", hero.global_position))
	if hand_card_starts_spell_study(game, hero, hand_card, target_data):
		return game.begin_spell_scroll_study(hero, String(hand_card.get("learn_spell_id", "")))
	match card_id:
		"fireball_card":
			var room_coord: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
				return false
			cast_fireball_spell(game, hero, target_world_position, room_coord, hand_card)
			game.status_message = "%s cast Fireball." % hero.hero_name
			return true
		"magic_missile_card":
			var missile_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if missile_room == game.INVALID_ROOM or not game.rooms.has(missile_room):
				return false
			cast_magic_missile_spell(game, hero, target_world_position, missile_room, hand_card)
			game.status_message = "%s cast Magic Missile." % hero.hero_name
			return true
		"light_cantrip_card":
			hero.light_cantrip_active = true
			game.refresh_room_lighting_states()
			hero.trigger_attack(hero.global_position + Vector2(0.0, -18.0), "laser")
			game.status_message = "%s invoked Light." % hero.hero_name
			return true
		"scorcher_card":
			if not game.wave_in_progress():
				game.status_message = "Scorcher can only be cast during combat."
				return false
			var scorcher_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if scorcher_room == game.INVALID_ROOM or not game.rooms.has(scorcher_room):
				return false
			if scorcher_room != hero.current_room:
				game.status_message = "Scorcher can only be channeled in your current room."
				return false
			if not cast_scorcher_spell(game, hero, target_world_position, scorcher_room, hand_card):
				return false
			game.status_message = "%s began channeling Scorcher." % hero.hero_name
			return true
		"evasive_roll_card":
			if not game.wave_in_progress():
				game.status_message = "Evasive Roll can only be played in combat."
				return false
			var roll_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if roll_room == game.INVALID_ROOM or not game.rooms.has(roll_room):
				return false
			if not adjacent_target_valid_for_card(game, hero, hand_card, roll_room):
				game.status_message = "Evasive Roll needs an adjacent opened room."
				return false
			if not cast_evasive_roll(game, hero, target_world_position, roll_room, hand_card):
				return false
			game.status_message = "%s rolled into %s." % [hero.hero_name, game.room_title(roll_room)]
			return true
		"speed_dash_card":
			if not game.wave_in_progress():
				game.status_message = "Speed Dash can only be played in combat."
				return false
			var dash_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if dash_room == game.INVALID_ROOM or not game.rooms.has(dash_room):
				return false
			if not cast_speed_dash(game, hero, target_world_position, dash_room, hand_card):
				return false
			game.status_message = "%s dashed to %s and stayed accelerated." % [hero.hero_name, game.room_title(dash_room)]
			return true
		"whirling_blade_card":
			if not game.wave_in_progress():
				game.status_message = "Whirling Blade can only be played in combat."
				return false
			var blade_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if blade_room == game.INVALID_ROOM or not game.rooms.has(blade_room):
				return false
			if not adjacent_target_valid_for_card(game, hero, hand_card, blade_room):
				game.status_message = "Whirling Blade needs an adjacent opened room."
				return false
			if not cast_whirling_blade(game, hero, target_world_position, blade_room, hand_card):
				return false
			game.status_message = "%s carved through to %s." % [hero.hero_name, game.room_title(blade_room)]
			return true
		"silver_gauntlet_toss_card":
			if not game.wave_in_progress():
				game.status_message = "Rage Throw can only be used in combat."
				return false
			var toss_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if toss_room == game.INVALID_ROOM or not game.rooms.has(toss_room):
				return false
			if not cast_silver_gauntlet_toss(game, hero, target_world_position, toss_room, hand_card):
				return false
			return true
		"shield_bash_card":
			if not game.wave_in_progress():
				game.status_message = "Shield Bash can only be played in combat."
				return false
			var bash_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if bash_room == game.INVALID_ROOM or not game.rooms.has(bash_room):
				return false
			if not cast_shield_bash(game, hero, target_world_position, bash_room, hand_card):
				return false
			return true
		"hold_person_card":
			if not game.wave_in_progress():
				game.status_message = "Hold Person can only be cast during combat."
				return false
			var hold_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if hold_room == game.INVALID_ROOM or not game.rooms.has(hold_room):
				return false
			var held_count: int = cast_hold_person_spell(game, hero, target_world_position, hold_room, hand_card)
			if held_count <= 0:
				game.status_message = "%s cast Hold Person, but no enemy was seized." % hero.hero_name
				return false
			game.status_message = "%s cast Hold Person on %d enem%s in %s." % [hero.hero_name, held_count, "y" if held_count == 1 else "ies", game.room_title(hold_room)]
			return true
		"fear_card":
			if not game.wave_in_progress():
				game.status_message = "Fear can only be cast during combat."
				return false
			var fear_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if fear_room == game.INVALID_ROOM or not game.rooms.has(fear_room):
				return false
			var feared_count: int = cast_fear_spell(game, hero, target_world_position, fear_room, hand_card)
			if feared_count <= 0:
				game.status_message = "%s cast Fear, but no enemy was terrified." % hero.hero_name
				return false
			game.status_message = "%s cast Fear on %d enem%s." % [hero.hero_name, feared_count, "y" if feared_count == 1 else "ies"]
			return true
		"turn_undead_card":
			if not game.wave_in_progress():
				game.status_message = "Turn Undead can only be cast during combat."
				return false
			if String(hero.hero_class_id) != String(game.HERO_CLASS_CLERIC):
				game.status_message = "Only clerics can invoke Turn Undead."
				return false
			var turn_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if turn_room == game.INVALID_ROOM or not game.rooms.has(turn_room):
				return false
			var turned_count: int = cast_turn_undead_spell(game, hero, turn_room, hand_card)
			if turned_count <= 0:
				game.status_message = "%s invoked Turn Undead, but no undead were affected." % hero.hero_name
				return false
			game.status_message = "%s invoked Turn Undead on %d undead." % [hero.hero_name, turned_count]
			return true
		"calm_emotions_card":
			if not game.wave_in_progress():
				game.status_message = "Calm Emotions can only be cast during combat."
				return false
			var calm_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if calm_room == game.INVALID_ROOM or not game.rooms.has(calm_room):
				return false
			var calm_count: int = cast_calm_emotions_spell(game, hero, calm_room, hand_card)
			if calm_count <= 0:
				game.status_message = "%s cast Calm Emotions, but no enemies were affected." % hero.hero_name
				return false
			game.status_message = "%s calmed %d enem%s in %s." % [hero.hero_name, calm_count, "y" if calm_count == 1 else "ies", game.room_title(calm_room)]
			return true
		"beacon_of_hope_card":
			var beacon_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if beacon_room == game.INVALID_ROOM or not game.rooms.has(beacon_room):
				return false
			if not cast_beacon_of_hope_spell(game, hero, beacon_room, hand_card):
				return false
			game.status_message = "%s invoked Beacon of Hope in %s." % [hero.hero_name, game.room_title(beacon_room)]
			return true
		"web_card":
			var web_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if web_room == game.INVALID_ROOM or not game.rooms.has(web_room):
				return false
			cast_web_spell(game, hero, target_world_position, web_room, hand_card)
			game.status_message = "%s cast Web." % hero.hero_name
			return true
		"scry_card":
			var anchor_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if anchor_room == game.INVALID_ROOM or not game.rooms.has(anchor_room):
				return false
			var revealed_rooms: int = cast_scry_spell(game, hero, anchor_room, hand_card)
			if revealed_rooms <= 0:
				game.status_message = "No unopened adjacent rooms to scry from %s." % game.room_title(anchor_room)
				return false
			game.status_message = "%s cast Scry and revealed %d adjacent room%s." % [hero.hero_name, revealed_rooms, "" if revealed_rooms == 1 else "s"]
			return true
		"find_familiar_card", "animate_dead_card", "spiritual_weapon_card":
			if not game.wave_in_progress():
				game.status_message = "%s can only be cast during combat." % String(hand_card.get("name", "That summon"))
				return false
			var summon_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if summon_room == game.INVALID_ROOM or not game.rooms.has(summon_room):
				return false
			var summon_count: int = cast_temporary_summon_spell(game, hero, summon_room, hand_card)
			if summon_count <= 0:
				return false
			game.status_message = "%s cast %s in %s." % [hero.hero_name, String(hand_card.get("name", "a summon")), game.room_title(summon_room)]
			return true
		"shield_card":
			cast_shield_spell(game, hero, hand_card)
			game.status_message = "%s cast Shield." % hero.hero_name
			return true
		"cure_light_wounds_card":
			var cleric_target: Variant = room_target_hero_for_card(game, hero, hand_card, target_data)
			if cleric_target == null or not is_instance_valid(cleric_target):
				return false
			var previous_cleric_health: float = cleric_target.current_health
			var cure_heal_amount: float = heal_amount_for_card_target(hand_card, cleric_target, 36.0, 0.5)
			cleric_target.heal(cure_heal_amount)
			hero.trigger_attack(cleric_target.global_position, "heal_cast")
			if cleric_target.current_health <= previous_cleric_health + 0.001:
				game.status_message = "%s does not need healing." % cleric_target.hero_name
				return false
			append_timed_effect_projectile(game, "priest_heal_effect", cleric_target.global_position + Vector2(0.0, -10.0), Color(hand_card.get("color", Color("9fe6b0"))), 0.58, 0.58)
			if String(target_data.get("reaction_trigger", "")) == "ally_fatal_in_room":
				game.status_message = "%s reflexively cast Cure Light Wounds to save %s." % [hero.hero_name, cleric_target.hero_name]
			else:
				game.status_message = "%s cast Cure Light Wounds." % hero.hero_name
			return true
		"sanctuary_card":
			var sanctuary_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if sanctuary_room == game.INVALID_ROOM or not game.rooms.has(sanctuary_room):
				return false
			var sanctuary_target: Variant = cast_sanctuary_spell(game, hero, sanctuary_room, hand_card)
			if sanctuary_target == null or not is_instance_valid(sanctuary_target):
				game.status_message = "%s invoked Sanctuary in %s, but no ally could receive it." % [hero.hero_name, game.room_title(sanctuary_room)]
				return false
			game.status_message = "%s invoked Sanctuary on %s in %s." % [hero.hero_name, sanctuary_target.hero_name, game.room_title(sanctuary_room)]
			return true
		"lightning_bolt_card":
			var bolt_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if bolt_room == game.INVALID_ROOM or not game.rooms.has(bolt_room):
				return false
			cast_lightning_bolt_spell(game, hero, target_world_position, bolt_room, hand_card)
			game.status_message = "%s cast Lightning Bolt." % hero.hero_name
			return true
		"haste_card":
			if not game.wave_in_progress():
				game.status_message = "Haste can only be cast during combat."
				return false
			var haste_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if haste_room == game.INVALID_ROOM or not game.rooms.has(haste_room):
				return false
			var haste_target: Variant = cast_haste_spell(game, hero, haste_room, hand_card)
			if haste_target == null or not is_instance_valid(haste_target):
				game.status_message = "%s cast Haste, but no ally could be accelerated." % hero.hero_name
				return false
			game.status_message = "%s cast Haste on %s in %s." % [hero.hero_name, haste_target.hero_name, game.room_title(haste_room)]
			return true
		"lantern_beacon_card":
			var room_coord_torch: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if room_coord_torch == game.INVALID_ROOM or not game.rooms.has(room_coord_torch):
				return false
			var target_room_data: Dictionary = game.rooms[room_coord_torch]
			if bool(target_room_data.get("permanent_light", false)) or game.room_has_wave_torch_light(target_room_data):
				game.status_message = "%s is already secured by light." % game.room_title(room_coord_torch)
				return false
			game.apply_wave_torch_light_to_room(room_coord_torch)
			hero.trigger_attack(game.room_center(room_coord_torch), "laser")
			game.status_message = "%s lit %s through the next wave." % [hero.hero_name, game.room_title(room_coord_torch)]
			return true
		"mend_card":
			var target_hero_mend: Variant = room_target_hero_for_card(game, hero, hand_card, target_data)
			if target_hero_mend == null or not is_instance_valid(target_hero_mend):
				return false
			var previous_health: float = target_hero_mend.current_health
			target_hero_mend.heal(float(hand_card.get("heal_amount", 35.0)))
			hero.trigger_attack(target_hero_mend.global_position, "heal_cast")
			if target_hero_mend.current_health <= previous_health + 0.001:
				game.status_message = "%s is already fully patched up." % target_hero_mend.hero_name
				return false
			append_timed_effect_projectile(game, "priest_heal_effect", target_hero_mend.global_position + Vector2(0.0, -10.0), Color("9fe6b0"), 0.58, 0.58)
			game.status_message = "%s restored %s." % [hero.hero_name, target_hero_mend.hero_name]
			return true
		"arcane_reset_card":
			var reset_result: Dictionary = try_reset_cooldowns_with_arcana(game, hero)
			if not bool(reset_result.get("success", false)):
				if String(reset_result.get("reason", "")) == "not_enough_arcana":
					game.status_message = "Need %d arcana to reset cooldowns." % int(reset_result.get("required_arcana", 0))
				else:
					game.status_message = "No cooldowns are currently waiting."
				return false
			hero.trigger_attack(hero.global_position + Vector2(0.0, -16.0), "laser")
			append_timed_effect_projectile(game, "shield_flash", hero.global_position, Color(hand_card.get("color", Color("8bc1ff"))), 0.24, 0.24)
			var refresh_count: int = int(reset_result.get("refreshed_cards", 0))
			var spent_arcana: int = int(reset_result.get("total_cost", 0))
			game.status_message = "%s spent %d arcana to refresh %d cooldown%s." % [hero.hero_name, spent_arcana, refresh_count, "" if refresh_count == 1 else "s"]
			return true
		"cloak_of_shadows_card":
			var cloak_target: Variant = target_data.get("hero", hero)
			if cloak_target == null or not is_instance_valid(cloak_target):
				return false
			var cloak_duration_doors: int = maxi(1, int(hand_card.get("skulker_duration_doors", 1)))
			cloak_target.temporary_skulker_until_doors_opened = maxi(int(cloak_target.temporary_skulker_until_doors_opened), game.doors_opened + cloak_duration_doors)
			hero.trigger_attack(cloak_target.global_position, "laser")
			game.sync_hero_skulking_visual_states()
			game.status_message = "%s wrapped %s in shadow for 1 turn." % [hero.hero_name, cloak_target.hero_name]
			return true
		"serpent_venom_card", "wyvern_toxin_card", "blacklotus_oil_card":
			var poison_target: Variant = target_data.get("hero", hero)
			if poison_target == null or not is_instance_valid(poison_target):
				return false
			var poison_def: Dictionary = game.card_definition(String(hand_card.get("card_id", "")))
			var poison_turn_duration_doors: int = maxi(1, int(poison_def.get("poison_turn_duration_doors", 1)))
			var poison_payload: Dictionary = {
				"poison_id": String(poison_def.get("poison_id", hand_card.get("card_id", ""))),
				"name": String(poison_def.get("poison_name", hand_card.get("name", "Poison"))),
				"stackable": bool(poison_def.get("poison_stackable", false)),
				"stacks": maxi(1, int(poison_def.get("poison_apply_stacks", 1))),
				"max_stacks": maxi(1, int(poison_def.get("poison_max_stacks", 1))),
				"remaining_hits": int(poison_def.get("poison_hit_charges", 8)),
				"expires_on_doors_opened": game.doors_opened + poison_turn_duration_doors,
				"physical_only": bool(poison_def.get("poison_physical_only", true)),
				"on_hit_damage_per_stack": maxf(float(poison_def.get("poison_on_hit_damage_per_stack", 0.0)), 0.0),
				"dot_damage_per_second": maxf(float(poison_def.get("poison_dot_damage_per_second", 0.0)), 0.0),
				"dot_duration": maxf(float(poison_def.get("poison_dot_duration", 0.0)), 0.0),
				"dot_max_stacks": maxi(1, int(poison_def.get("poison_dot_max_stacks", poison_def.get("poison_max_stacks", 1)))),
				"slow_duration": maxf(float(poison_def.get("poison_slow_duration", 0.0)), 0.0),
				"slow_move_multiplier": clampf(float(poison_def.get("poison_slow_move_multiplier", 1.0)), 0.0, 1.0),
				"slow_attack_speed_multiplier": clampf(float(poison_def.get("poison_slow_attack_speed_multiplier", 1.0)), 0.0, 1.0),
				"flatfooted_duration": maxf(float(poison_def.get("poison_flatfooted_duration", 0.0)), 0.0),
				"flatfooted_move_multiplier": clampf(float(poison_def.get("poison_flatfooted_move_multiplier", 1.0)), 0.0, 1.0),
				"flatfooted_attack_speed_multiplier": clampf(float(poison_def.get("poison_flatfooted_attack_speed_multiplier", 1.0)), 0.0, 1.0),
				"flatfooted_damage_taken_multiplier": maxf(float(poison_def.get("poison_flatfooted_damage_taken_multiplier", 1.0)), 1.0),
			}
			var applied_poison: Dictionary = game.apply_poison_coating_to_hero(poison_target, poison_payload)
			if applied_poison.is_empty():
				return false
			hero.trigger_attack(poison_target.global_position, "laser")
			game.status_message = "%s coated %s with %s for 1 turn (all physical attacks)." % [hero.hero_name, poison_target.hero_name, String(applied_poison.get("name", "poison"))]
			return true
		"emergency_snack_card":
			var snack_target: Variant = target_data.get("hero", hero)
			if snack_target == null or not is_instance_valid(snack_target):
				return false
			var food_cost: int = int(hand_card.get("food_cost", game.HEAL_FOOD_COST))
			if game.food < food_cost:
				game.status_message = "Not enough food for %s." % String(hand_card.get("name", "that card"))
				return false
			var previous_snack_health: float = snack_target.current_health
			var heal_percent: float = clampf(float(hand_card.get("heal_percent", 0.4)), 0.0, 1.0)
			var heal_amount: float = maxf(snack_target.max_health * heal_percent, 1.0)
			snack_target.heal(heal_amount)
			if snack_target.current_health <= previous_snack_health + 0.001:
				game.status_message = "%s does not need an emergency snack right now." % snack_target.hero_name
				return false
			game.food -= food_cost
			game.reset_hero_combo(snack_target)
			hero.trigger_attack(snack_target.global_position, "laser")
			var healed_amount: int = int(round(maxf(snack_target.current_health - previous_snack_health, 0.0)))
			game.status_message = "%s used an emergency snack (+%d HP)." % [snack_target.hero_name, healed_amount]
			return true
		"sunpepper_jerky_card", "moon_truffle_card", "tidekelp_roll_card":
			var ration_target: Variant = target_data.get("hero", hero)
			if ration_target == null or not is_instance_valid(ration_target):
				return false
			var previous_ration_health: float = ration_target.current_health
			var ration_heal_percent: float = clampf(float(hand_card.get("heal_percent", 0.4)), 0.0, 1.0)
			var ration_heal_amount: float = maxf(ration_target.max_health * ration_heal_percent, 1.0)
			ration_target.heal(ration_heal_amount)
			hero.trigger_attack(ration_target.global_position, "laser")
			var card_def: Dictionary = game.card_definition(String(hand_card.get("card_id", "")))
			var buff_duration: float = maxf(float(hand_card.get("food_buff_duration", card_def.get("food_buff_duration", 0.0))), 0.0)
			var ration_healed: int = int(round(maxf(ration_target.current_health - previous_ration_health, 0.0)))
			var detail_tokens: Array[String] = []
			if buff_duration > 0.0:
				var attack_cooldown_multiplier: float = clampf(float(hand_card.get("food_attack_cooldown_multiplier", card_def.get("food_attack_cooldown_multiplier", 1.0))), 0.1, 1.0)
				if attack_cooldown_multiplier < 0.999 and ration_target.has_method("apply_food_attack_speed_buff"):
					ration_target.apply_food_attack_speed_buff(attack_cooldown_multiplier, buff_duration)
					detail_tokens.append("Atk Spd")
				var defence_bonus: float = maxf(float(hand_card.get("food_defence_bonus", card_def.get("food_defence_bonus", 0.0))), 0.0)
				if defence_bonus > 0.0 and ration_target.has_method("apply_food_defence_buff"):
					ration_target.apply_food_defence_buff(defence_bonus, buff_duration)
					detail_tokens.append("Def")
				var move_speed_multiplier: float = maxf(float(hand_card.get("food_move_speed_multiplier", card_def.get("food_move_speed_multiplier", 1.0))), 1.0)
				if move_speed_multiplier > 1.001 and ration_target.has_method("apply_food_move_speed_buff"):
					ration_target.apply_food_move_speed_buff(move_speed_multiplier, buff_duration)
					detail_tokens.append("Move")
			if ration_healed <= 0 and detail_tokens.is_empty():
				game.status_message = "%s does not need %s right now." % [ration_target.hero_name, String(hand_card.get("name", "that food")).to_lower()]
				return false
			var effect_tokens: Array[String] = []
			if ration_healed > 0:
				effect_tokens.append("+%d HP" % ration_healed)
			effect_tokens.append_array(detail_tokens)
			game.status_message = "%s used %s (%s)." % [ration_target.hero_name, String(hand_card.get("name", "an exotic food")).to_lower(), ", ".join(effect_tokens)]
			return true
		"dagger_card", "rogue_combo_dagger_card", "ricochet_dagger_card":
			if String(hand_card.get("card_id", "")) == "rogue_combo_dagger_card" and game.combo_level_for_hero(hero) < 3:
				game.status_message = "Shadow Throw requires 3 combo points."
				return false
			spawn_dagger_card_projectiles(game, hero, target_world_position, hand_card)
			if String(hand_card.get("card_id", "")) == "rogue_combo_dagger_card":
				game.status_message = "%s cast Shadow Throw." % hero.hero_name
			elif String(hand_card.get("card_id", "")) == "ricochet_dagger_card":
				game.status_message = "%s hurled a ricochet chakram." % hero.hero_name
			else:
				game.status_message = "%s flung a dagger fan." % hero.hero_name
			return true
		_:
			spawn_axe_card_projectile(game, hero, target_world_position, hand_card)
			game.status_message = "%s threw a razor boomerang." % hero.hero_name
			return true

static func finalize_played_hand_card_source(game: Node, hand_card: Dictionary) -> void:
	var item_uid: int = int(hand_card.get("item_uid", -1))
	if item_uid < 0:
		return
	if bool(hand_card.get("consume_item_on_play", false)):
		game.remove_item_by_uid_from_world(item_uid)
		return
	var charge_cost: int = int(hand_card.get("consume_item_charges_on_play", 0))
	if charge_cost > 0:
		game.consume_item_charges_by_uid(item_uid, charge_cost)

static func play_card_for_hero(game: Node, hero_index: int, card_uid: int, target_world_position: Vector2) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or hero.current_health <= 0.0 or hero.carrying_crystal:
		return false
	if game.doors_opened == 0:
		game.status_message = "Cards cannot be played until the first door opens."
		game.update_hud()
		return false
	var hand_index: int = hero_hand_card_index(game, hero, card_uid)
	if hand_index < 0:
		return false
	var hand_card: Dictionary = (hero.hand_cards[hand_index] as Dictionary).duplicate(true)
	if String(hand_card.get("card_id", "")) == "rogue_combo_dagger_card" and game.combo_level_for_hero(hero) < 3:
		game.status_message = "Shadow Throw requires 3 combo points."
		game.update_hud()
		return false
	if not hand_card_phase_allows_play(game, hand_card):
		return false
	var target_data: Dictionary = resolve_card_target(game, hero, hand_card, target_world_position)
	if target_data.is_empty():
		return false
	var target_room_for_constraints: Vector2i = target_data.get("room", game.INVALID_ROOM)
	if not adjacent_target_valid_for_card(game, hero, hand_card, target_room_for_constraints):
		game.status_message = "%s needs an adjacent opened room target." % String(hand_card.get("name", "That card"))
		game.update_hud()
		return false
	var target_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
	var hand_card_id: String = String(hand_card.get("card_id", ""))
	if target_room != game.INVALID_ROOM and hand_card_id != "evasive_roll_card" and hand_card_id != "whirling_blade_card" and hand_card_id != "speed_dash_card":
		var cast_room: Vector2i = best_card_cast_room(game, game.active_hero_room_for_commands(hero), target_room, hand_card, Vector2(target_data.get("world_position", target_world_position)))
		if cast_room == game.INVALID_ROOM:
			game.status_message = "No reachable cast room for that target."
			game.update_hud()
			return false
		if not hero_ready_for_card_cast(game, hero, cast_room, target_room, hand_card, Vector2(target_data.get("world_position", target_world_position))):
			return game.request_deferred_room_card_for_hero(hero_index, cast_room, target_room, card_uid, Vector2(target_data.get("world_position", target_world_position)))
	var is_study_play: bool = hand_card_starts_spell_study(game, hero, hand_card, target_data)
	if not apply_hand_card_effect(game, hero, hand_card, target_data):
		return false
	if not bool(hand_card.get("reusable", false)):
		hero.hand_cards.remove_at(hand_index)
		finalize_played_hand_card_source(game, hand_card)
	game.fill_queued_hand_cards(hero)
	game.cleanup_global_item_card_states()
	game.update_hud()
	return true

static func cast_fireball_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	hero.trigger_attack(target_world_position, "laser")
	explode_fireball_projectile(game, {
		"position": target_world_position,
		"target_position": target_world_position,
		"damage": float(hand_card.get("damage", 42.0)),
		"color": hand_card.get("color", Color("ff9a5e")),
		"radius": float(hand_card.get("radius", 12.0)),
		"impact_radius": float(hand_card.get("impact_radius", 92.0)),
		"push_distance": 56.0,
		"room": target_room,
		"source_label": "%s's Fireball" % hero.hero_name,
	})

static func nearest_enemies_in_room(game: Node, room_coord: Vector2i, origin: Vector2, max_count: int) -> Array:
	var room_enemies: Array = []
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		room_enemies.append({
			"enemy": enemy,
			"distance": origin.distance_squared_to(enemy.global_position),
		})
	room_enemies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", INF)) < float(b.get("distance", INF))
	)
	var resolved: Array = []
	for enemy_entry_variant in room_enemies:
		if resolved.size() >= max_count:
			break
		resolved.append(enemy_entry_variant.get("enemy", null))
	return resolved

static func strongest_enemy_in_range(game: Node, room_coord: Vector2i, origin: Vector2, max_distance: float) -> Variant:
	var best_enemy: Variant = null
	var best_strength_score: float = -INF
	var best_distance_squared: float = INF
	var max_distance_squared: float = maxf(max_distance, 0.0) * maxf(max_distance, 0.0)
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		if enemy.has_method("is_converted") and bool(enemy.is_converted()):
			continue
		var distance_squared: float = origin.distance_squared_to(enemy.global_position)
		if distance_squared > max_distance_squared:
			continue
		var strength_score: float = float(enemy.current_health) * 2.4 + float(enemy.attack_damage) * 5.5 + float(enemy.max_health)
		if best_enemy == null or strength_score > best_strength_score + 0.001 or (absf(strength_score - best_strength_score) <= 0.001 and distance_squared < best_distance_squared):
			best_enemy = enemy
			best_strength_score = strength_score
			best_distance_squared = distance_squared
	return best_enemy

static func simulate_elastic_throw_path(start_position: Vector2, launch_direction: Vector2, travel_distance: float, bounds: Rect2, max_bounces: int) -> Dictionary:
	var remaining_distance: float = maxf(travel_distance, 0.0)
	var direction: Vector2 = launch_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var current_position: Vector2 = start_position
	current_position.x = clampf(current_position.x, bounds.position.x, bounds.end.x)
	current_position.y = clampf(current_position.y, bounds.position.y, bounds.end.y)
	var bounce_points: Array = []
	var bounce_normals: Array = []
	var safety_counter: int = 0
	while remaining_distance > 0.001 and safety_counter < 12:
		safety_counter += 1
		var to_x_wall: float = INF
		var to_y_wall: float = INF
		if direction.x > 0.0001:
			to_x_wall = (bounds.end.x - current_position.x) / direction.x
		elif direction.x < -0.0001:
			to_x_wall = (bounds.position.x - current_position.x) / direction.x
		if direction.y > 0.0001:
			to_y_wall = (bounds.end.y - current_position.y) / direction.y
		elif direction.y < -0.0001:
			to_y_wall = (bounds.position.y - current_position.y) / direction.y
		var hit_distance: float = minf(to_x_wall, to_y_wall)
		if hit_distance == INF or hit_distance < 0.0:
			current_position += direction * remaining_distance
			remaining_distance = 0.0
			break
		if hit_distance > remaining_distance:
			current_position += direction * remaining_distance
			remaining_distance = 0.0
			break
		current_position += direction * maxf(hit_distance, 0.0)
		remaining_distance -= maxf(hit_distance, 0.0)
		if max_bounces <= 0:
			remaining_distance = 0.0
			break
		var hit_x: bool = absf(hit_distance - to_x_wall) <= 0.05
		var hit_y: bool = absf(hit_distance - to_y_wall) <= 0.05
		var normal: Vector2 = Vector2.ZERO
		if hit_x:
			normal.x = -signf(direction.x)
		if hit_y:
			normal.y = -signf(direction.y)
		if normal == Vector2.ZERO:
			normal = -direction
		bounce_points.append(current_position)
		bounce_normals.append(normal.normalized())
		if bounce_points.size() >= max_bounces:
			break
		if hit_x:
			direction.x = -direction.x
		if hit_y:
			direction.y = -direction.y
		direction = direction.normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		current_position += direction * 0.4
		current_position.x = clampf(current_position.x, bounds.position.x + 0.2, bounds.end.x - 0.2)
		current_position.y = clampf(current_position.y, bounds.position.y + 0.2, bounds.end.y - 0.2)
	current_position.x = clampf(current_position.x, bounds.position.x, bounds.end.x)
	current_position.y = clampf(current_position.y, bounds.position.y, bounds.end.y)
	return {
		"final_position": current_position,
		"final_direction": direction,
		"bounce_points": bounce_points,
		"bounce_normals": bounce_normals,
	}

static func enemies_in_cone_in_room(game: Node, room_coord: Vector2i, origin: Vector2, aim_direction: Vector2, max_distance: float, arc_angle_degrees: float, max_count: int = -1) -> Array:
	var half_arc_radians: float = deg_to_rad(clampf(arc_angle_degrees * 0.5, 5.0, 180.0))
	var resolved_direction: Vector2 = aim_direction.normalized()
	if resolved_direction == Vector2.ZERO:
		resolved_direction = Vector2.RIGHT
	var cone_targets: Array = []
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		if enemy.has_method("is_converted") and bool(enemy.is_converted()):
			continue
		var to_enemy: Vector2 = enemy.global_position - origin
		var distance_to_enemy: float = to_enemy.length()
		if distance_to_enemy > max_distance:
			continue
		if distance_to_enemy > 0.001:
			var enemy_direction: Vector2 = to_enemy / distance_to_enemy
			var cone_dot: float = clampf(resolved_direction.dot(enemy_direction), -1.0, 1.0)
			if acos(cone_dot) > half_arc_radians:
				continue
		cone_targets.append({
			"enemy": enemy,
			"distance": origin.distance_squared_to(enemy.global_position),
		})
	cone_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", INF)) < float(b.get("distance", INF))
	)
	var resolved_targets: Array = []
	for target_entry_variant in cone_targets:
		if max_count > 0 and resolved_targets.size() >= max_count:
			break
		resolved_targets.append(target_entry_variant.get("enemy", null))
	return resolved_targets

static func heroes_in_cone_in_room(game: Node, room_coord: Vector2i, origin: Vector2, aim_direction: Vector2, max_distance: float, arc_angle_degrees: float, exclude_hero: Variant = null) -> Array:
	var half_arc_radians: float = deg_to_rad(clampf(arc_angle_degrees * 0.5, 5.0, 180.0))
	var resolved_direction: Vector2 = aim_direction.normalized()
	if resolved_direction == Vector2.ZERO:
		resolved_direction = Vector2.RIGHT
	var cone_targets: Array = []
	for room_hero in game.heroes_in_room(room_coord):
		if room_hero == null or not is_instance_valid(room_hero):
			continue
		if exclude_hero != null and room_hero == exclude_hero:
			continue
		if not game.hero_is_active(room_hero):
			continue
		var to_hero: Vector2 = room_hero.global_position - origin
		var distance_to_hero: float = to_hero.length()
		if distance_to_hero > max_distance:
			continue
		if distance_to_hero > 0.001:
			var hero_direction: Vector2 = to_hero / distance_to_hero
			var cone_dot: float = clampf(resolved_direction.dot(hero_direction), -1.0, 1.0)
			if acos(cone_dot) > half_arc_radians:
				continue
		cone_targets.append(room_hero)
	return cone_targets

static func cast_magic_missile_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	hero.trigger_attack(target_world_position, "laser")
	var missile_targets: Array = nearest_enemies_in_room(game, target_room, target_world_position, int(hand_card.get("projectile_count", 3)))
	if missile_targets.is_empty():
		game.add_resource_floating_text(target_world_position, "Miss", Color(hand_card.get("color", Color("9cd7ff"))))
		return
	var missile_count: int = maxi(1, int(hand_card.get("projectile_count", 3)))
	for missile_index in range(missile_count):
		var target_enemy: Variant = missile_targets[missile_index % missile_targets.size()]
		if target_enemy == null or not is_instance_valid(target_enemy):
			continue
		var curve_sign: float = -1.0 if missile_index % 2 == 0 else 1.0
		var curve_scale: float = 0.58 + float(missile_index) * 0.14
		game.spawn_magic_missile_projectile(
			hero.global_position,
			target_enemy,
			float(hand_card.get("damage", hand_card.get("base_damage", 14.0))),
			hand_card.get("color", Color("9cd7ff")),
			4.8,
			1180.0,
			curve_sign * curve_scale
		)

static func cancel_hero_channel_spell(game: Node, hero: Variant, show_feedback: bool = false) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if not (hero.has_method("has_active_scorcher_channel") and bool(hero.has_active_scorcher_channel())):
		return
	if hero.has_method("end_scorcher_channel"):
		hero.end_scorcher_channel()
	if show_feedback:
		game.status_message = "%s stopped channeling Scorcher." % hero.hero_name

static func cast_scorcher_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if target_room != hero.current_room:
		return false
	var cast_origin: Vector2 = hero.global_position
	var aim_direction: Vector2 = (target_world_position - cast_origin).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.LEFT if bool(hero.get("visual_facing_left")) else Vector2.RIGHT
	var channel_range: float = maxf(float(hand_card.get("impact_radius", 220.0)), 24.0)
	var channel_arc: float = clampf(float(hand_card.get("arc_angle_deg", 70.0)), 10.0, 180.0)
	var dot_damage_per_second: float = maxf(float(hand_card.get("dot_damage_per_second", hand_card.get("damage", 28.0))), 0.0)
	var tick_interval: float = maxf(float(hand_card.get("channel_tick_interval", 0.25)), 0.05)
	if dot_damage_per_second <= 0.0:
		return false
	game.interrupt_hero_orders(hero)
	if hero.has_method("begin_scorcher_channel"):
		hero.begin_scorcher_channel(target_room, aim_direction, channel_range, channel_arc, dot_damage_per_second, tick_interval)
	hero.set_destination(hero.global_position)
	hero.trigger_attack(cast_origin + aim_direction * 22.0, "fire_bolt")
	spawn_scorcher_channel_effect(game, cast_origin, aim_direction, channel_range, channel_arc, Color(hand_card.get("color", Color("ff9b63"))), maxf(tick_interval * 1.35, 0.26))
	return true

static func spawn_scorcher_channel_effect(game: Node, origin: Vector2, aim_direction: Vector2, cone_range: float, cone_arc_degrees: float, effect_color: Color, lifetime: float) -> void:
	var resolved_direction: Vector2 = aim_direction.normalized()
	if resolved_direction == Vector2.ZERO:
		resolved_direction = Vector2.RIGHT
	var resolved_range: float = maxf(cone_range, 12.0)
	var resolved_arc: float = clampf(cone_arc_degrees, 10.0, 180.0)
	var tip_position: Vector2 = origin + resolved_direction * resolved_range
	game.projectiles.append({
		"kind": "scorcher_flame_cone",
		"position": tip_position,
		"previous": origin,
		"target_position": tip_position,
		"color": effect_color,
		"radius": 22.0,
		"impact_radius": 22.0,
		"lifetime_left": lifetime,
		"blast_duration": lifetime,
		"width": 18.0,
		"cone_origin": origin,
		"cone_direction": resolved_direction,
		"cone_range": resolved_range,
		"cone_arc_degrees": resolved_arc,
	})

static func advance_scorcher_channels(game: Node, delta: float) -> void:
	if delta <= 0.0:
		return
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		if not (hero.has_method("has_active_scorcher_channel") and bool(hero.has_active_scorcher_channel())):
			continue
		if not game.wave_in_progress() or not game.hero_is_active(hero):
			cancel_hero_channel_spell(game, hero)
			continue
		if Vector2i(hero.current_room) != Vector2i(hero.scorcher_channel_room):
			cancel_hero_channel_spell(game, hero)
			continue
		hero.move_steps.clear()
		hero.player_command_locked = true
		hero.set_destination(hero.global_position)
		var tick_interval: float = maxf(float(hero.scorcher_channel_tick_interval), 0.05)
		hero.scorcher_channel_tick_time_left = float(hero.scorcher_channel_tick_time_left) - delta
		while hero.scorcher_channel_tick_time_left <= 0.0:
			var cast_origin: Vector2 = hero.global_position
			var aim_direction: Vector2 = Vector2(hero.scorcher_channel_direction).normalized()
			if aim_direction == Vector2.ZERO:
				aim_direction = Vector2.LEFT if bool(hero.get("visual_facing_left")) else Vector2.RIGHT
			var scorch_range: float = maxf(float(hero.scorcher_channel_range), 12.0)
			var scorch_arc: float = clampf(float(hero.scorcher_channel_arc_degrees), 10.0, 180.0)
			var tick_damage: float = maxf(float(hero.scorcher_dot_damage_per_second), 0.0) * tick_interval
			if tick_damage <= 0.0:
				cancel_hero_channel_spell(game, hero)
				break
			var hit_count: int = 0
			for enemy_variant in enemies_in_cone_in_room(game, hero.current_room, cast_origin, aim_direction, scorch_range, scorch_arc):
				var enemy: Variant = enemy_variant
				if enemy == null or not is_instance_valid(enemy):
					continue
				var scorch_direction: Vector2 = (enemy.global_position - cast_origin).normalized()
				if scorch_direction == Vector2.ZERO:
					scorch_direction = aim_direction
				enemy.take_damage(tick_damage, scorch_direction)
				game.register_hero_enemy_hit(hero, enemy, scorch_direction)
				hit_count += 1
			for allied_hero_variant in heroes_in_cone_in_room(game, hero.current_room, cast_origin, aim_direction, scorch_range, scorch_arc, hero):
				var allied_hero: Variant = allied_hero_variant
				if allied_hero == null or not is_instance_valid(allied_hero):
					continue
				apply_spell_damage_to_hero(game, allied_hero, tick_damage, "%s's Scorcher" % hero.hero_name)
				hit_count += 1
			hero.trigger_attack(cast_origin + aim_direction * 26.0, "fire_bolt")
			spawn_scorcher_channel_effect(game, cast_origin, aim_direction, scorch_range, scorch_arc, Color("ff9b63"), maxf(tick_interval * 1.35, 0.26))
			if hit_count > 0:
				game.add_resource_floating_text(cast_origin + aim_direction * 34.0, "Burn", Color("ffb37a"))
			hero.scorcher_channel_tick_time_left += tick_interval

static func cast_evasive_roll(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> bool:
	var from_room: Vector2i = evasive_roll_origin_room(game, hero)
	if from_room == game.INVALID_ROOM or not game.rooms.has(from_room):
		game.status_message = "Evasive Roll failed: no valid origin room."
		return false
	if from_room == target_room:
		game.status_message = "Evasive Roll needs an adjacent room."
		return false
	if not room_has_neighbor(game, from_room, target_room):
		game.status_message = "Evasive Roll needs an adjacent opened room."
		return false
	game.interrupt_hero_orders(hero)
	hero.current_room = from_room
	hero.pending_room = game.HERO_INVALID_ROOM
	var landing_position: Vector2 = game.clamp_point_to_room(target_world_position, target_room)
	var roll_path: Array[Vector2i] = [from_room, target_room]
	var roll_steps: Array = game.build_steps_for_path(roll_path, hero.global_position, landing_position)
	if roll_steps.is_empty():
		hero.set_room(target_room, landing_position)
		hero.begin_evasive_roll(0.28, 2.0, 18.0)
		return true
	var travel_distance: float = travel_distance_for_steps(hero.global_position, roll_steps)
	var base_speed: float = maxf(hero.movement_speed(), 1.0)
	var roll_speed: float = base_speed * 2.0
	var roll_duration: float = clampf(travel_distance / roll_speed + 0.16, 0.24, 3.5)
	hero.begin_evasive_roll(roll_duration, 2.0, 18.0)
	game.issue_hero_steps(hero, roll_steps)
	hero.trigger_attack(landing_position, "melee")
	append_timed_effect_projectile(game, "shield_flash", hero.global_position, Color(hand_card.get("color", Color("9ef4df"))), 0.2, 0.2)
	return true

static func cast_speed_dash(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room) or not bool(game.rooms[target_room].get("opened", false)):
		game.status_message = "Speed Dash needs an opened room target."
		return false
	var origin_room: Vector2i = evasive_roll_origin_room(game, hero)
	if origin_room == game.INVALID_ROOM or not game.rooms.has(origin_room):
		game.status_message = "Speed Dash failed: no valid origin room."
		return false
	game.interrupt_hero_orders(hero)
	hero.current_room = origin_room
	hero.pending_room = game.HERO_INVALID_ROOM
	var landing_position: Vector2 = game.clamp_point_to_room(target_world_position, target_room)
	var dash_path: Array[Vector2i] = [origin_room]
	if origin_room != target_room:
		dash_path = game.find_path(origin_room, target_room, true)
		if dash_path.is_empty():
			game.status_message = "Speed Dash failed: no route to target room."
			return false
	var dash_steps: Array = game.build_steps_for_path(dash_path, hero.global_position, landing_position)
	var dash_multiplier: float = maxf(float(hand_card.get("dash_speed_multiplier", 4.0)), 1.0)
	var post_dash_duration: float = clampf(float(hand_card.get("dash_post_duration", 6.0)), 0.5, 12.0)
	var minimum_burst: float = clampf(float(hand_card.get("dash_duration", 0.2)), 0.1, 2.0)
	if not dash_steps.is_empty():
		var travel_distance: float = travel_distance_for_steps(hero.global_position, dash_steps)
		var base_speed: float = maxf(hero.movement_speed(), 1.0)
		var boosted_speed: float = maxf(base_speed * dash_multiplier, 1.0)
		var travel_duration: float = travel_distance / boosted_speed
		hero.begin_evasive_roll(maxf(travel_duration + post_dash_duration, post_dash_duration + minimum_burst), dash_multiplier, 0.0, false)
		game.issue_hero_steps(hero, dash_steps)
	else:
		hero.begin_evasive_roll(post_dash_duration, dash_multiplier, 0.0, false)
	hero.trigger_attack(landing_position, "melee")
	append_timed_effect_projectile(game, "shield_flash", hero.global_position, Color(hand_card.get("color", Color("8ff6df"))), 0.18, 0.18)
	return true

static func apply_whirling_blade_sweep_damage(game: Node, hero: Variant, from_room: Vector2i, target_room: Vector2i, landing_position: Vector2, roll_steps: Array, hand_card: Dictionary) -> int:
	var sweep_points: Array = [hero.global_position]
	for step_variant in roll_steps:
		sweep_points.append(Vector2((step_variant as Dictionary).get("position", landing_position)))
	if sweep_points.size() < 2:
		sweep_points.append(landing_position)
	var impact_radius: float = maxf(float(hand_card.get("impact_radius", 54.0)), 20.0)
	var damage: float = float(hand_card.get("damage", hand_card.get("base_damage", 24.0)))
	var knockback_force: float = maxf(float(hand_card.get("knockback_force", 360.0)), 0.0)
	var knockback_duration: float = clampf(float(hand_card.get("knockback_duration", 0.22)), 0.08, 0.5)
	var hit_count: int = 0
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy):
			continue
		if enemy.current_room != from_room and enemy.current_room != target_room:
			continue
		if point_distance_to_polyline(game, sweep_points, enemy.global_position) > impact_radius:
			continue
		var impact_direction: Vector2 = (enemy.global_position - hero.global_position).normalized()
		if impact_direction == Vector2.ZERO:
			impact_direction = (landing_position - hero.global_position).normalized()
		if impact_direction == Vector2.ZERO:
			impact_direction = Vector2.RIGHT
		enemy.take_damage(damage, impact_direction)
		game.register_hero_enemy_hit(hero, enemy, impact_direction)
		game.knockback_actor(enemy, impact_direction, knockback_force, knockback_duration, enemy.current_room)
		hit_count += 1
	if hit_count > 0:
		game.add_resource_floating_text(landing_position, "Whirl x%d" % hit_count, Color(hand_card.get("color", Color("ffe08b"))))
	return hit_count

static func cast_whirling_blade(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> bool:
	var from_room: Vector2i = evasive_roll_origin_room(game, hero)
	if from_room == game.INVALID_ROOM or not game.rooms.has(from_room):
		game.status_message = "Whirling Blade failed: no valid origin room."
		return false
	if from_room != target_room and not room_has_neighbor(game, from_room, target_room):
		game.status_message = "Whirling Blade needs an adjacent opened room."
		return false
	game.interrupt_hero_orders(hero)
	hero.current_room = from_room
	hero.pending_room = game.HERO_INVALID_ROOM
	var landing_position: Vector2 = game.clamp_point_to_room(target_world_position, target_room)
	var roll_path: Array[Vector2i] = [from_room]
	if from_room != target_room:
		roll_path.append(target_room)
	var roll_steps: Array = game.build_steps_for_path(roll_path, hero.global_position, landing_position)
	if roll_steps.is_empty():
		hero.set_room(target_room, landing_position)
		hero.begin_evasive_roll(0.35, 2.6, float(hand_card.get("spin_speed", 24.0)))
		apply_whirling_blade_sweep_damage(game, hero, from_room, target_room, landing_position, roll_steps, hand_card)
		return true
	var travel_distance: float = travel_distance_for_steps(hero.global_position, roll_steps)
	var travel_multiplier: float = maxf(float(hand_card.get("travel_speed_multiplier", 2.6)), 1.0)
	var travel_speed: float = maxf(hero.movement_speed(), 1.0) * travel_multiplier
	var spin_duration: float = clampf(travel_distance / travel_speed + 0.2, 0.26, 3.8)
	hero.begin_evasive_roll(spin_duration, travel_multiplier, float(hand_card.get("spin_speed", 24.0)))
	game.issue_hero_steps(hero, roll_steps)
	hero.trigger_attack(landing_position, "melee")
	apply_whirling_blade_sweep_damage(game, hero, from_room, target_room, landing_position, roll_steps, hand_card)
	append_timed_effect_projectile(game, "shield_flash", hero.global_position, Color(hand_card.get("color", Color("ffe08b"))), 0.2, 0.2)
	return true

static func cast_silver_gauntlet_toss(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if target_room != hero.current_room:
		game.status_message = "Rage Throw can only be used in your current room."
		return false
	var pickup_radius_multiplier: float = maxf(float(hand_card.get("pickup_radius_multiplier", 2.0)), 1.0)
	var pickup_radius: float = maxf(hero.attack_range * pickup_radius_multiplier, 24.0)
	var throw_target: Variant = strongest_enemy_in_range(game, target_room, hero.global_position, pickup_radius)
	if throw_target == null or not is_instance_valid(throw_target):
		game.status_message = "%s found no enemy to grab for Rage Throw." % hero.hero_name
		return false
	var aim_direction: Vector2 = (target_world_position - hero.global_position).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.LEFT if bool(hero.get("visual_facing_left")) else Vector2.RIGHT
	var rage_max: int = maxi(int(hero.fighter_rage_max), 1)
	var rage_value: int = clampi(int(hero.fighter_rage), 0, rage_max)
	var rage_ratio: float = clampf(float(rage_value) / float(rage_max), 0.0, 1.0)
	var throw_bounds: Rect2 = room_interior_rect(game, target_room, 20.0)
	var room_span: float = maxf(maxf(throw_bounds.size.x, throw_bounds.size.y), 1.0)
	var throw_distance_scale: float = maxf(float(hand_card.get("throw_distance_scale", 2.35)), 0.0)
	var throw_distance_curve: float = maxf(float(hand_card.get("throw_distance_curve", 1.8)), 1.0)
	var throw_distance: float = room_span * throw_distance_scale * pow(rage_ratio, throw_distance_curve)
	var max_bounces: int = maxi(0, int(hand_card.get("max_bounces", 2)))
	var allowed_bounces: int = mini(max_bounces, int(floor(float(rage_value) / 3.0)))
	if rage_value >= rage_max:
		allowed_bounces = mini(max_bounces, maxi(allowed_bounces, 2))
	if allowed_bounces >= 2:
		throw_distance = maxf(throw_distance, room_span * 2.2)
	var bounce_damage: float = maxf(float(hand_card.get("base_bounce_damage", 8.0)) + float(rage_value) * maxf(float(hand_card.get("bounce_damage_per_rage", 9.0)), 0.0), 0.0)
	var flatfooted_duration: float = maxf(float(hand_card.get("flatfooted_duration", 4.0)), 0.0)
	var flatfooted_move_multiplier: float = clampf(float(hand_card.get("flatfooted_move_multiplier", 0.72)), 0.0, 1.0)
	var flatfooted_attack_speed_multiplier: float = clampf(float(hand_card.get("flatfooted_attack_speed_multiplier", 0.78)), 0.0, 1.0)
	var flatfooted_damage_taken_multiplier: float = maxf(float(hand_card.get("flatfooted_damage_taken_multiplier", 1.5)), 1.0)
	var throw_duration: float = clampf(0.34 + rage_ratio * 0.5, 0.24, 1.0)
	if allowed_bounces >= 2:
		throw_duration = maxf(throw_duration, 0.62)
	var launch_speed: float = clampf(throw_distance / maxf(throw_duration, 0.01), 220.0, 1650.0)
	var launch_velocity: Vector2 = aim_direction * launch_speed
	var throw_regions: Array = game.room_walkable_regions(target_room, game.ROOM_WALKABLE_INSET + 2.0)
	if throw_target.has_method("begin_physics_throw"):
		throw_target.begin_physics_throw(
			launch_velocity,
			throw_duration,
			throw_bounds,
			throw_regions,
			allowed_bounces,
			bounce_damage,
			flatfooted_duration,
			flatfooted_move_multiplier,
			flatfooted_attack_speed_multiplier,
			flatfooted_damage_taken_multiplier,
			hero.hero_index,
			Color(hand_card.get("color", Color("c5d4df")))
		)
	else:
		game.knockback_actor(throw_target, aim_direction, launch_speed * 0.24, throw_duration, target_room)
	hero.trigger_attack(target_world_position, "melee")
	append_timed_effect_projectile(game, "shield_flash", hero.global_position, Color(hand_card.get("color", Color("c5d4df"))), 0.2, 0.2)
	game.add_resource_floating_text(hero.global_position, "Rage %d" % rage_value, Color(hand_card.get("color", Color("c5d4df"))))
	game.status_message = "%s hurled %s with Rage %d." % [hero.hero_name, String(throw_target.enemy_role).capitalize(), rage_value]
	return true

static func cast_shield_bash(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if target_room != hero.current_room:
		game.status_message = "Shield Bash can only hit your current room."
		return false
	var bash_origin: Vector2 = hero.global_position
	var aim_direction: Vector2 = (target_world_position - bash_origin).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.LEFT if bool(hero.get("visual_facing_left")) else Vector2.RIGHT
	var impact_radius: float = maxf(float(hand_card.get("impact_radius", 138.0)), 18.0)
	var arc_angle_degrees: float = clampf(float(hand_card.get("arc_angle_deg", 110.0)), 10.0, 180.0)
	var half_arc_radians: float = deg_to_rad(arc_angle_degrees * 0.5)
	var damage: float = float(hand_card.get("damage", hand_card.get("base_damage", 12.0)))
	var knockback_force: float = maxf(float(hand_card.get("knockback_force", 420.0)), 0.0)
	var knockback_duration: float = clampf(float(hand_card.get("knockback_duration", 0.24)), 0.04, 0.65)
	var slow_duration: float = maxf(float(hand_card.get("slow_duration", 6.0)), 0.0)
	var slow_move_multiplier: float = clampf(float(hand_card.get("slow_move_multiplier", 0.0)), 0.0, 1.0)
	var legacy_attack_cooldown_multiplier: float = maxf(float(hand_card.get("slow_attack_cooldown_multiplier", 1.0)), 0.001)
	var slow_attack_speed_multiplier: float = clampf(float(hand_card.get("slow_attack_speed_multiplier", 1.0 / legacy_attack_cooldown_multiplier)), 0.0, 1.0)
	var flatfooted_damage_taken_multiplier: float = maxf(float(hand_card.get("flatfooted_damage_taken_multiplier", 1.5)), 1.0)
	var hit_count: int = 0
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != target_room:
			continue
		var to_enemy: Vector2 = enemy.global_position - bash_origin
		var distance_to_enemy: float = to_enemy.length()
		if distance_to_enemy > impact_radius:
			continue
		var impact_direction: Vector2 = to_enemy.normalized() if distance_to_enemy > 0.001 else aim_direction
		if impact_direction == Vector2.ZERO:
			impact_direction = Vector2.RIGHT
		if distance_to_enemy > 0.001 and aim_direction != Vector2.ZERO:
			var arc_dot: float = clampf(aim_direction.dot(impact_direction), -1.0, 1.0)
			if acos(arc_dot) > half_arc_radians:
				continue
		enemy.take_damage(damage, impact_direction)
		game.register_hero_enemy_hit(hero, enemy, impact_direction)
		game.knockback_actor(enemy, impact_direction, knockback_force, knockback_duration, target_room)
		if slow_duration > 0.0:
			if enemy.has_method("apply_flatfooted_debuff"):
				enemy.apply_flatfooted_debuff(slow_duration, slow_move_multiplier, slow_attack_speed_multiplier, flatfooted_damage_taken_multiplier)
			elif enemy.has_method("apply_recovering_slow_debuff"):
				enemy.apply_recovering_slow_debuff(slow_duration, slow_move_multiplier, slow_attack_speed_multiplier)
		hit_count += 1
	hero.trigger_attack(target_world_position, "melee")
	append_timed_effect_projectile(game, "shield_flash", bash_origin, Color(hand_card.get("color", Color("9ec3ff"))), 0.18, 0.18)
	if hit_count > 0:
		game.add_resource_floating_text(bash_origin, "Bash x%d" % hit_count, Color(hand_card.get("color", Color("9ec3ff"))))
		if hit_count == 1:
			game.status_message = "%s slammed 1 enemy with Shield Bash." % hero.hero_name
		else:
			game.status_message = "%s slammed %d enemies with Shield Bash." % [hero.hero_name, hit_count]
	else:
		game.status_message = "%s used Shield Bash, but hit nothing." % hero.hero_name
	return true

static func cast_hold_person_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> int:
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return 0
	var hold_duration: float = maxf(float(hand_card.get("hold_duration", 6.0)), 0.0)
	if hold_duration <= 0.0:
		return 0
	var hold_target_count: int = maxi(1, int(hand_card.get("hold_target_count", 1)))
	var hold_targets: Array = nearest_enemies_in_room(game, target_room, target_world_position, hold_target_count)
	if hold_targets.is_empty():
		game.add_resource_floating_text(target_world_position, "Miss", Color(hand_card.get("color", Color("d9c0ff"))))
		return 0
	var held_count: int = 0
	for hold_target_variant in hold_targets:
		var hold_target: Variant = hold_target_variant
		if hold_target == null or not is_instance_valid(hold_target):
			continue
		if hold_target.has_method("apply_hold_person_debuff"):
			hold_target.apply_hold_person_debuff(hold_duration)
		elif hold_target.has_method("apply_root"):
			hold_target.apply_root(hold_duration)
		append_timed_effect_projectile(game, "shield_flash", hold_target.global_position, Color(hand_card.get("color", Color("d9c0ff"))), 0.24, 0.24)
		append_timed_effect_projectile(game, "priest_attack_effect", hold_target.global_position, Color(hand_card.get("color", Color("d9c0ff"))), 0.34, 0.34)
		held_count += 1
	hero.trigger_attack(target_world_position, "laser")
	if held_count > 0:
		var hold_label: String = "Held" if held_count == 1 else "Held x%d" % held_count
		game.add_resource_floating_text(target_world_position, hold_label, Color(hand_card.get("color", Color("d9c0ff"))))
	return held_count

static func cast_fear_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> int:
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return 0
	if target_room != hero.current_room:
		return 0
	var fear_duration: float = maxf(float(hand_card.get("fear_duration", 6.0)), 0.0)
	if fear_duration <= 0.0:
		return 0
	var fear_speed_multiplier: float = maxf(float(hand_card.get("fear_speed_multiplier", 1.2)), 1.0)
	var fear_damage_taken_multiplier: float = maxf(float(hand_card.get("fear_damage_taken_multiplier", 2.0)), 1.0)
	var impact_radius: float = maxf(float(hand_card.get("impact_radius", 220.0)), 18.0)
	var arc_angle_degrees: float = clampf(float(hand_card.get("arc_angle_deg", 62.0)), 10.0, 180.0)
	var cast_origin: Vector2 = hero.global_position
	var aim_direction: Vector2 = (target_world_position - cast_origin).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.LEFT if bool(hero.get("visual_facing_left")) else Vector2.RIGHT
	var fear_targets: Array = enemies_in_cone_in_room(game, target_room, cast_origin, aim_direction, impact_radius, arc_angle_degrees)
	if fear_targets.is_empty():
		game.add_resource_floating_text(target_world_position, "Miss", Color(hand_card.get("color", Color("cda3ff"))))
		return 0
	var feared_count: int = 0
	for fear_target_variant in fear_targets:
		var fear_target: Variant = fear_target_variant
		if fear_target == null or not is_instance_valid(fear_target):
			continue
		var fear_target_role: String = String(fear_target.get("enemy_role", ""))
		if not GAME_ENEMY_DEFS.enemy_can_be_feared(fear_target_role):
			continue
		if fear_target.has_method("apply_fear_debuff"):
			fear_target.apply_fear_debuff(fear_duration, cast_origin, fear_speed_multiplier)
		if fear_damage_taken_multiplier > 1.0 and fear_target.has_method("apply_flatfooted_debuff"):
			fear_target.apply_flatfooted_debuff(fear_duration, 1.0, 1.0, fear_damage_taken_multiplier)
		append_timed_effect_projectile(game, "priest_attack_effect", fear_target.global_position, Color(hand_card.get("color", Color("cda3ff"))), 0.34, 0.34)
		append_timed_effect_projectile(game, "shield_flash", fear_target.global_position, Color(hand_card.get("color", Color("cda3ff"))), 0.24, 0.24)
		feared_count += 1
	hero.trigger_attack(target_world_position, "laser")
	if feared_count > 0:
		var fear_label: String = "Fear" if feared_count == 1 else "Fear x%d" % feared_count
		game.add_resource_floating_text(target_world_position, fear_label, Color(hand_card.get("color", Color("cda3ff"))))
	return feared_count

static func cast_turn_undead_spell(game: Node, hero: Variant, target_room: Vector2i, hand_card: Dictionary) -> int:
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return 0
	if target_room != hero.current_room:
		return 0
	if String(hero.hero_class_id) != String(game.HERO_CLASS_CLERIC):
		return 0
	var fear_duration: float = maxf(float(hand_card.get("fear_duration", 6.0)), 0.0)
	if fear_duration <= 0.0:
		return 0
	var fear_speed_multiplier: float = maxf(float(hand_card.get("fear_speed_multiplier", 1.2)), 1.0)
	var fear_damage_taken_multiplier: float = maxf(float(hand_card.get("fear_damage_taken_multiplier", 2.0)), 1.0)
	var cast_origin: Vector2 = hero.global_position
	var turned_count: int = 0
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != target_room:
			continue
		if enemy.has_method("is_converted") and bool(enemy.is_converted()):
			continue
		var enemy_role: String = String(enemy.enemy_role)
		if not GAME_ENEMY_DEFS.enemy_is_undead(enemy_role):
			continue
		if enemy.has_method("apply_fear_debuff"):
			enemy.apply_fear_debuff(fear_duration, cast_origin, fear_speed_multiplier)
		if fear_damage_taken_multiplier > 1.0 and enemy.has_method("apply_flatfooted_debuff"):
			enemy.apply_flatfooted_debuff(fear_duration, 1.0, 1.0, fear_damage_taken_multiplier)
		append_timed_effect_projectile(game, "priest_attack_effect", enemy.global_position, Color(hand_card.get("color", Color("f0efb5"))), 0.34, 0.34)
		append_timed_effect_projectile(game, "shield_flash", enemy.global_position, Color(hand_card.get("color", Color("f0efb5"))), 0.24, 0.24)
		turned_count += 1
	if turned_count > 0:
		hero.trigger_attack(game.room_center(target_room), "laser")
		var turn_label: String = "Turned" if turned_count == 1 else "Turned x%d" % turned_count
		game.add_resource_floating_text(game.room_center(target_room), turn_label, Color(hand_card.get("color", Color("f0efb5"))))
	return turned_count

static func cast_calm_emotions_spell(game: Node, hero: Variant, target_room: Vector2i, hand_card: Dictionary) -> int:
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return 0
	var calm_duration: float = maxf(float(hand_card.get("calm_duration", 12.0)), 0.0)
	if calm_duration <= 0.0:
		return 0
	var neutralized_count: int = 0
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != target_room:
			continue
		if enemy.has_method("is_converted") and bool(enemy.is_converted()):
			continue
		var enemy_role: String = String(enemy.enemy_role)
		if GAME_ENEMY_DEFS.enemy_is_undead(enemy_role):
			continue
		if enemy.has_method("apply_calm_emotions"):
			enemy.apply_calm_emotions(calm_duration)
		append_timed_effect_projectile(game, "calm_emotions_wave", enemy.global_position, Color(hand_card.get("color", Color("b7e8ff"))), 0.56, 0.56)
		neutralized_count += 1
	if neutralized_count > 0:
		append_timed_effect_projectile(game, "calm_emotions_wave", game.room_center(target_room), Color(hand_card.get("color", Color("b7e8ff"))), 0.64, 0.64)
		hero.trigger_attack(game.room_center(target_room), "laser")
		var calm_label: String = "Calmed" if neutralized_count == 1 else "Calmed x%d" % neutralized_count
		game.add_resource_floating_text(game.room_center(target_room), calm_label, Color(hand_card.get("color", Color("b7e8ff"))))
	return neutralized_count

static func cast_web_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	var web_position: Vector2 = game.clamp_point_to_room(target_world_position, target_room)
	var web_radius: float = maxf(float(hand_card.get("impact_radius", 108.0)), 18.0)
	var rooted_count: int = 0
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != target_room:
			continue
		if enemy.global_position.distance_to(web_position) > web_radius:
			continue
		var root_duration: float = game.rng.randf_range(float(hand_card.get("web_duration_min", 6.0)), float(hand_card.get("web_duration_max", 12.0)))
		enemy.apply_root(root_duration)
		rooted_count += 1
	hero.trigger_attack(web_position, "laser")
	game.projectiles.append({
		"kind": "web_field",
		"position": web_position,
		"previous": web_position,
		"target_position": web_position,
		"color": hand_card.get("color", Color("c9f0ff")),
		"radius": web_radius,
		"impact_radius": web_radius,
		"lifetime_left": 0.6,
		"blast_duration": 0.6,
		"width": 2.5,
	})
	game.add_resource_floating_text(web_position, "Web" if rooted_count > 0 else "Miss", Color(hand_card.get("color", Color("c9f0ff"))))

static func cast_scry_spell(game: Node, hero: Variant, anchor_room: Vector2i, hand_card: Dictionary) -> int:
	if anchor_room == game.INVALID_ROOM or not game.rooms.has(anchor_room):
		return 0
	var reveal_count: int = 0
	for neighbor_variant in Array(game.rooms[anchor_room].get("neighbors", [])):
		var neighbor_room: Vector2i = Vector2i(neighbor_variant)
		if not game.rooms.has(neighbor_room):
			continue
		var room_data: Dictionary = Dictionary(game.rooms[neighbor_room])
		if bool(room_data.get("opened", false)) or bool(room_data.get("scry_revealed", false)):
			continue
		room_data["scry_revealed"] = true
		game.rooms[neighbor_room] = room_data
		reveal_count += 1
		var reveal_position: Vector2 = game.room_center(neighbor_room)
		append_timed_effect_projectile(game, "shield_flash", reveal_position, Color(hand_card.get("color", Color("9ed7ff"))), 0.4, 0.4)
	if reveal_count > 0:
		hero.trigger_attack(game.room_center(anchor_room), "laser")
		game.add_resource_floating_text(game.room_center(anchor_room) + Vector2(0.0, -22.0), "Scry +%d" % reveal_count, Color(hand_card.get("color", Color("9ed7ff"))))
	return reveal_count

static func cast_temporary_summon_spell(game: Node, hero: Variant, target_room: Vector2i, hand_card: Dictionary) -> int:
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return 0
	var card_id: String = String(hand_card.get("card_id", hand_card.get("id", "")))
	var card_def: Dictionary = game.card_definition(card_id)
	var summon_role: String = String(hand_card.get("summon_enemy_role", card_def.get("summon_enemy_role", game.ENEMY_TYPE_ORC)))
	var summon_roles: Array = Array(hand_card.get("summon_enemy_roles", card_def.get("summon_enemy_roles", [])))
	var summon_count: int = maxi(1, int(hand_card.get("summon_count", 1)))
	if not summon_roles.is_empty():
		summon_count = maxi(summon_count, summon_roles.size())
	var conversion_duration: float = maxf(float(hand_card.get("summon_conversion_duration", card_def.get("summon_conversion_duration", 600.0))), 0.1)
	var summon_attack_damage_override: float = maxf(float(hand_card.get("summon_attack_damage_override", card_def.get("summon_attack_damage_override", 0.0))), 0.0)
	if card_id == "spiritual_weapon_card":
		summon_attack_damage_override = fighter_level_two_attack_damage(game)
	var summon_behavior: String = String(hand_card.get("summon_behavior", card_def.get("summon_behavior", "")))
	var summon_applies_flatfooted: bool = bool(hand_card.get("summon_applies_flatfooted", card_def.get("summon_applies_flatfooted", false)))
	var summon_flatfooted_duration: float = maxf(float(hand_card.get("summon_flatfooted_duration", card_def.get("summon_flatfooted_duration", 6.0))), 0.0)
	var summon_flatfooted_move_multiplier: float = clampf(float(hand_card.get("summon_flatfooted_move_multiplier", card_def.get("summon_flatfooted_move_multiplier", 0.0))), 0.0, 1.0)
	var summon_flatfooted_attack_speed_multiplier: float = clampf(float(hand_card.get("summon_flatfooted_attack_speed_multiplier", card_def.get("summon_flatfooted_attack_speed_multiplier", 0.0))), 0.0, 1.0)
	var summon_flatfooted_damage_taken_multiplier: float = maxf(float(hand_card.get("summon_flatfooted_damage_taken_multiplier", card_def.get("summon_flatfooted_damage_taken_multiplier", 1.5))), 1.0)
	var summon_source_label: String = String(hand_card.get("summon_source_label", card_def.get("summon_source_label", "A summoned ally")))
	var is_find_familiar: bool = card_id == "find_familiar_card"
	var is_animate_dead: bool = card_id == "animate_dead_card"
	var orc_role_def: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(game.ENEMY_TYPE_ORC)
	var orc_move_speed: float = float(orc_role_def.get("move_speed", 48.0))
	var orc_max_health: float = maxf(float(orc_role_def.get("max_health", 68.0)), 1.0)
	var orc_attack_damage: float = maxf(float(orc_role_def.get("attack_damage", 20.0)) * float(game.ENEMY_SCRIPT.ENEMY_ATTACK_DAMAGE_MULTIPLIER), 0.0)
	var orc_attack_cooldown: float = maxf(float(orc_role_def.get("attack_cooldown", 1.0)) * float(game.ENEMY_SCRIPT.ENEMY_ATTACK_COOLDOWN_MULTIPLIER), 0.05)
	var orc_attack_range: float = float(orc_role_def.get("attack_range", 70.0))
	var orc_weight: float = float(orc_role_def.get("weight", 1.28))
	var summon_particle_primary_color: Color = Color(hand_card.get("color", Color("d7efff")))
	var summon_particle_secondary_color: Color = summon_particle_primary_color.lightened(0.34)
	if card_id == "spiritual_weapon_card":
		summon_particle_primary_color = Color("ffd26a")
		summon_particle_secondary_color = Color("fff2be")
	elif is_find_familiar:
		summon_particle_primary_color = Color("b289ff")
		summon_particle_secondary_color = Color("ead8ff")
	elif card_id == "animate_dead_card":
		summon_particle_primary_color = Color("7de8c0")
		summon_particle_secondary_color = Color("d8fff0")
	var summon_spawn_positions: Array = []
	if card_id == "animate_dead_card":
		var cluster_anchor: Vector2 = game.clamp_point_to_room(hero.global_position, target_room)
		if hero.current_room != target_room and game.are_neighbors(target_room, hero.current_room):
			cluster_anchor = game.doorway_navigation_position(target_room, hero.current_room)
		cluster_anchor = game.clamp_point_to_room(cluster_anchor, target_room)
		var base_angle: float = game.rng.randf() * TAU
		for spawn_index in range(summon_count):
			if spawn_index == 0:
				summon_spawn_positions.append(cluster_anchor)
				continue
			var angle: float = base_angle + (TAU * float(spawn_index - 1) / maxf(float(summon_count - 1), 1.0))
			var offset_radius: float = 30.0
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * offset_radius
			summon_spawn_positions.append(game.clamp_point_to_room(cluster_anchor + offset, target_room))
	var spawned_count: int = 0
	for _spawn_index in range(summon_count):
		var spawn_role: String = summon_role
		if _spawn_index < summon_roles.size():
			spawn_role = String(summon_roles[_spawn_index])
		var summon_spawn_position_hint: Vector2 = Vector2.INF
		if _spawn_index < summon_spawn_positions.size():
			summon_spawn_position_hint = Vector2(summon_spawn_positions[_spawn_index])
		var next_spawn_uid: int = game.next_enemy_uid
		game.spawn_wave_enemy(target_room, spawn_role)
		var summoned_enemy: Variant = game.find_enemy_by_uid(next_spawn_uid)
		if summoned_enemy == null or not is_instance_valid(summoned_enemy):
			continue
		if summon_spawn_position_hint != Vector2.INF:
			summoned_enemy.global_position = summon_spawn_position_hint
			summoned_enemy.reset_physics_interpolation()
			if summoned_enemy.has_method("set_destination"):
				summoned_enemy.set_destination(summon_spawn_position_hint)
		if summoned_enemy.has_method("apply_conversion"):
			summoned_enemy.apply_conversion(conversion_duration)
		else:
			summoned_enemy.converted_time_left = maxf(float(summoned_enemy.get("converted_time_left")), conversion_duration)
		summoned_enemy.set_meta("temporary_summon", true)
		summoned_enemy.set_meta("summon_owner_hero_index", hero.hero_index)
		summoned_enemy.set_meta("summon_card_id", card_id)
		summoned_enemy.set_meta("summon_source_label", summon_source_label)
		summoned_enemy.set_meta("summon_behavior", summon_behavior)
		summoned_enemy.set_meta("summon_applies_flatfooted", summon_applies_flatfooted)
		summoned_enemy.set_meta("summon_flatfooted_duration", summon_flatfooted_duration)
		summoned_enemy.set_meta("summon_flatfooted_move_multiplier", summon_flatfooted_move_multiplier)
		summoned_enemy.set_meta("summon_flatfooted_attack_speed_multiplier", summon_flatfooted_attack_speed_multiplier)
		summoned_enemy.set_meta("summon_flatfooted_damage_taken_multiplier", summon_flatfooted_damage_taken_multiplier)
		summoned_enemy.set_meta("summon_particle_primary_color", summon_particle_primary_color)
		summoned_enemy.set_meta("summon_particle_secondary_color", summon_particle_secondary_color)
		if is_animate_dead:
			summoned_enemy.move_speed = orc_move_speed
			summoned_enemy.base_move_speed = orc_move_speed
			summoned_enemy.attack_range = orc_attack_range
			summoned_enemy.weight = orc_weight
			summoned_enemy.max_health = orc_max_health * 1.5
			summoned_enemy.current_health = summoned_enemy.max_health
			summoned_enemy.attack_damage = orc_attack_damage * 1.5
			summoned_enemy.attack_cooldown = orc_attack_cooldown
			summoned_enemy.attack_cooldown_left = maxf(float(summoned_enemy.attack_cooldown_left), summoned_enemy.attack_cooldown)
		if is_find_familiar:
			summoned_enemy.set_meta("summon_anchor_position", summoned_enemy.global_position)
			var goblin_role_def: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(game.ENEMY_TYPE_ORC)
			var goblin_max_health: float = maxf(float(goblin_role_def.get("max_health", 68.0)), 1.0)
			summoned_enemy.max_health = goblin_max_health
			summoned_enemy.current_health = goblin_max_health
			summoned_enemy.attack_cooldown = maxf(float(summoned_enemy.attack_cooldown) * 1.5, 0.05)
			summoned_enemy.attack_cooldown_left = maxf(float(summoned_enemy.attack_cooldown_left), summoned_enemy.attack_cooldown)
		if card_id == "animate_dead_card":
			summoned_enemy.set_meta("summon_visual_scale_multiplier", 1.04)
			if summoned_enemy.has_method("set_visual_scale_multiplier"):
				summoned_enemy.set_visual_scale_multiplier(1.04)
		elif card_id == "find_familiar_card":
			summoned_enemy.set_meta("summon_visual_scale_multiplier", 0.7)
			if summoned_enemy.has_method("set_visual_scale_multiplier"):
				summoned_enemy.set_visual_scale_multiplier(0.7)
		if summon_attack_damage_override > 0.0:
			summoned_enemy.attack_damage = summon_attack_damage_override
		summoned_enemy.set_meta("spawn_source", "summon_spell")
		append_timed_effect_projectile(game, "necromancer_attack_effect", summoned_enemy.global_position, Color(hand_card.get("color", Color("b8d1ff"))), 0.36, 0.36)
		spawned_count += 1
	if spawned_count > 0:
		hero.trigger_attack(game.room_center(target_room), "laser")
		game.add_resource_floating_text(game.room_center(target_room) + Vector2(0.0, -20.0), "Summoned", Color(hand_card.get("color", Color("b8d1ff"))))
	return spawned_count

static func fighter_level_two_attack_damage(game: Node) -> float:
	var fighter_def: Dictionary = game.hero_class_definition(game.HERO_CLASS_FIGHTER)
	var base_attack_damage: float = float(fighter_def.get("attack_damage", 28.0))
	var level_two_bonuses: Dictionary = game.hero_level_stat_bonuses(2, game.HERO_CLASS_FIGHTER)
	var level_bonus_attack: float = float(level_two_bonuses.get("attack", 0.0))
	return maxf(base_attack_damage + level_bonus_attack, 0.0)

static func cast_sanctuary_spell(game: Node, hero: Variant, target_room: Vector2i, hand_card: Dictionary) -> Variant:
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return null
	var sanctuary_target: Variant = most_damaged_hero_in_room(game, target_room)
	if sanctuary_target == null or not is_instance_valid(sanctuary_target):
		sanctuary_target = fallback_room_target_hero(game, hero, target_room)
	if sanctuary_target == null or not is_instance_valid(sanctuary_target):
		return null
	var room_data: Dictionary = Dictionary(game.rooms[target_room])
	var duration: float = maxf(float(hand_card.get("sanctuary_duration", 10.0)), 0.1)
	var mitigation: float = clampf(float(hand_card.get("sanctuary_damage_multiplier", 0.78)), 0.35, 1.0)
	var regen_per_second: float = maxf(float(hand_card.get("sanctuary_regen_per_second", 3.0)), 0.0)
	room_data["sanctuary_duration"] = maxf(float(room_data.get("sanctuary_duration", 0.0)), duration)
	room_data["sanctuary_time_left"] = maxf(float(room_data.get("sanctuary_time_left", 0.0)), duration)
	room_data["sanctuary_damage_multiplier"] = minf(float(room_data.get("sanctuary_damage_multiplier", 1.0)), mitigation)
	room_data["sanctuary_regen_per_second"] = maxf(float(room_data.get("sanctuary_regen_per_second", 0.0)), regen_per_second)
	room_data["sanctuary_target_hero_index"] = int(sanctuary_target.hero_index)
	room_data["sanctuary_aoe"] = false
	game.rooms[target_room] = room_data
	var sanctuary_center: Vector2 = game.room_center(target_room)
	hero.trigger_attack(sanctuary_center, "heal_cast")
	append_timed_effect_projectile(game, "priest_heal_effect", sanctuary_center, Color(hand_card.get("color", Color("e3ff9f"))), 0.52, 0.52)
	append_timed_effect_projectile(game, "shield_flash", sanctuary_target.global_position, Color(hand_card.get("color", Color("e3ff9f"))), 0.24, 0.24)
	return sanctuary_target

static func cast_beacon_of_hope_spell(game: Node, hero: Variant, target_room: Vector2i, hand_card: Dictionary) -> bool:
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return false
	var room_data: Dictionary = Dictionary(game.rooms[target_room])
	var duration: float = maxf(float(hand_card.get("sanctuary_duration", 10.0)), 0.1)
	var mitigation: float = clampf(float(hand_card.get("sanctuary_damage_multiplier", 0.78)), 0.35, 1.0)
	var regen_per_second: float = maxf(float(hand_card.get("sanctuary_regen_per_second", 3.0)), 0.0)
	room_data["sanctuary_duration"] = maxf(float(room_data.get("sanctuary_duration", 0.0)), duration)
	room_data["sanctuary_time_left"] = maxf(float(room_data.get("sanctuary_time_left", 0.0)), duration)
	room_data["sanctuary_damage_multiplier"] = minf(float(room_data.get("sanctuary_damage_multiplier", 1.0)), mitigation)
	room_data["sanctuary_regen_per_second"] = maxf(float(room_data.get("sanctuary_regen_per_second", 0.0)), regen_per_second)
	room_data["sanctuary_target_hero_index"] = -1
	room_data["sanctuary_aoe"] = true
	game.rooms[target_room] = room_data
	var sanctuary_center: Vector2 = game.room_center(target_room)
	hero.trigger_attack(sanctuary_center, "heal_cast")
	append_timed_effect_projectile(game, "priest_heal_effect", sanctuary_center, Color(hand_card.get("color", Color("d4ff9f"))), 0.56, 0.56)
	return true

static func cast_haste_spell(game: Node, hero: Variant, target_room: Vector2i, hand_card: Dictionary) -> Variant:
	if target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return null
	var haste_duration: float = maxf(float(hand_card.get("haste_duration", 18.0)), 0.1)
	if haste_duration < 18.0:
		haste_duration = 18.0
	var move_speed_multiplier: float = maxf(float(hand_card.get("haste_move_speed_multiplier", 2.0)), 1.0)
	var attack_speed_multiplier: float = maxf(float(hand_card.get("haste_attack_speed_multiplier", 2.0)), 1.0)
	var best_target: Variant = null
	var best_attack_damage: float = -INF
	for room_hero in game.heroes_in_room(target_room):
		if room_hero == null or not is_instance_valid(room_hero):
			continue
		if not game.hero_is_active(room_hero):
			continue
		var hero_attack_damage: float = float(room_hero.attack_damage)
		if best_target == null or hero_attack_damage > best_attack_damage:
			best_target = room_hero
			best_attack_damage = hero_attack_damage
	if best_target == null or not is_instance_valid(best_target):
		return null
	if best_target.has_method("apply_haste_buff"):
		best_target.apply_haste_buff(haste_duration, move_speed_multiplier, attack_speed_multiplier)
	hero.trigger_attack(best_target.global_position, "laser")
	append_timed_effect_projectile(game, "shield_flash", best_target.global_position, Color(hand_card.get("color", Color("ffd56e"))), 0.32, 0.32)
	append_timed_effect_projectile(game, "priest_heal_effect", best_target.global_position, Color(hand_card.get("color", Color("ffd56e"))), 0.26, 0.26)
	return best_target

static func cast_shield_spell(game: Node, hero: Variant, hand_card: Dictionary) -> void:
	var barrier_amount: float = float(hand_card.get("shield_amount", 34.0))
	var barrier_duration: float = float(hand_card.get("shield_duration", 10.0))
	var immunity_duration: float = float(hand_card.get("immunity_duration", 0.0))
	if immunity_duration <= 0.0 and String(hand_card.get("card_id", "")) == "shield_card":
		# Compatibility fallback for hand-card instances created before immunity_duration was serialized.
		immunity_duration = 6.0
	if barrier_amount > 0.0 and barrier_duration > 0.0:
		hero.apply_barrier(barrier_amount, barrier_duration)
	if immunity_duration > 0.0:
		hero.apply_invulnerability(immunity_duration)
	hero.trigger_attack(hero.global_position + Vector2.UP * 8.0, "laser")
	game.projectiles.append({
		"kind": "shield_flash",
		"position": hero.global_position,
		"previous": hero.global_position,
		"target_position": hero.global_position,
		"color": hand_card.get("color", Color("9fc8ff")),
		"radius": 34.0,
		"impact_radius": 34.0,
		"lifetime_left": 0.22,
		"blast_duration": 0.22,
		"width": 3.0,
	})

static func try_auto_cast_fatal_shield(game: Node, hero: Variant, incoming_damage: float) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hero.carrying_crystal:
		return false
	if hero.current_health > 0.0 or hero.invulnerability_time_left > 0.0:
		return false
	var room_rescue_reaction: Dictionary = first_room_rescue_cure_reaction_for_fallen_hero(game, hero)
	if not room_rescue_reaction.is_empty():
		var rescue_hero: Variant = room_rescue_reaction.get("hero", null)
		var rescue_index: int = int(room_rescue_reaction.get("index", -1))
		if rescue_hero != null and is_instance_valid(rescue_hero) and rescue_index >= 0:
			if play_reaction_card_for_hero_at_index(game, rescue_hero, rescue_index, "ally_fatal_in_room", hero):
				if hero.current_health > 0.0:
					return true
	var reaction_index: int = first_reaction_card_index_for_trigger(game, hero, "fatal_damage")
	if reaction_index < 0:
		return false
	var reaction_card: Dictionary = (hero.hand_cards[reaction_index] as Dictionary).duplicate(true)
	if not play_reaction_card_for_hero_at_index(game, hero, reaction_index, "fatal_damage"):
		return false
	var reaction_card_id: String = String(reaction_card.get("card_id", ""))
	if reaction_card_id == "shield_card":
		hero.heal(maxf(incoming_damage, 0.0))
		if hero.invulnerability_time_left <= 0.0:
			hero.apply_invulnerability(6.0)
			game.projectiles.append({
				"kind": "shield_flash",
				"position": hero.global_position,
				"previous": hero.global_position,
				"target_position": hero.global_position,
				"color": Color("7ebaff"),
				"radius": 36.0,
				"impact_radius": 36.0,
				"lifetime_left": 0.26,
				"blast_duration": 0.26,
				"width": 3.4,
			})
		game.status_message = "%s reflexively cast Shield." % hero.hero_name
	elif hero.current_health <= 0.0:
		hero.heal(maxf(incoming_damage, 0.0))
	return true

static func apply_spell_damage_to_hero(game: Node, hero: Variant, damage: float, source_label: String) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	var adjusted_damage: float = game.adjusted_incoming_damage_for_hero(hero, damage)
	var defeated: bool = hero.take_damage(adjusted_damage, false)
	if defeated and try_auto_cast_fatal_shield(game, hero, adjusted_damage):
		return false
	if defeated:
		game.finalize_hero_death(hero, source_label)
	return defeated

static func point_distance_to_polyline(game: Node, points: Array, point: Vector2) -> float:
	if points.size() < 2:
		return INF
	var closest_distance: float = INF
	for point_index in range(1, points.size()):
		var segment_start: Vector2 = Vector2(points[point_index - 1])
		var segment_end: Vector2 = Vector2(points[point_index])
		closest_distance = minf(closest_distance, game.point_distance_to_segment(point, segment_start, segment_end))
	return closest_distance

static func damage_modules_in_blast(game: Node, room_coord: Vector2i, center: Vector2, radius: float, damage: float) -> bool:
	if not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	var changed: bool = false
	var hit_any: bool = false
	if String(room.get("major_module_type", "")) != "" and float(room.get("major_health", 0.0)) > 0.0:
		if game.major_slot_position(room_coord).distance_to(center) <= radius + 18.0:
			room["major_health"] = maxf(float(room.get("major_health", 0.0)) - damage, 0.0)
			if float(room["major_health"]) <= 0.0:
				room["major_module_type"] = ""
				room["major_under_construction"] = false
				game.cancel_pending_major_construction(room_coord)
			changed = true
			hit_any = true
	var slot_positions: Array = game.minor_slot_positions(room_coord)
	for slot_index in range(slot_positions.size() - 1, -1, -1):
		var module_index: int = game.minor_module_index_for_slot(room_coord, slot_index)
		if module_index < 0 or module_index >= room["minor_modules"].size():
			continue
		if Vector2(slot_positions[slot_index]).distance_to(center) > radius + 14.0:
			continue
		var module_data: Dictionary = Dictionary(room["minor_modules"][module_index])
		module_data["health"] = maxf(float(module_data.get("health", 0.0)) - damage, 0.0)
		if float(module_data["health"]) <= 0.0:
			game.cancel_pending_minor_construction(room_coord, int(module_data.get("slot_index", slot_index)))
			room["minor_modules"].remove_at(module_index)
		else:
			room["minor_modules"][module_index] = module_data
		changed = true
		hit_any = true
	if changed:
		game.rooms[room_coord] = room
	return hit_any

static func damage_modules_along_polyline(game: Node, room_coord: Vector2i, points: Array, radius: float, damage: float, hit_keys: Dictionary) -> bool:
	if not game.rooms.has(room_coord) or points.size() < 2:
		return false
	var room: Dictionary = game.rooms[room_coord]
	var changed: bool = false
	var hit_any: bool = false
	var room_key: String = "%d:%d" % [room_coord.x, room_coord.y]
	if String(room.get("major_module_type", "")) != "" and float(room.get("major_health", 0.0)) > 0.0:
		var major_key: String = "%s:major" % room_key
		if not hit_keys.has(major_key) and point_distance_to_polyline(game, points, game.major_slot_position(room_coord)) <= radius + 18.0:
			hit_keys[major_key] = true
			room["major_health"] = maxf(float(room.get("major_health", 0.0)) - damage, 0.0)
			if float(room["major_health"]) <= 0.0:
				room["major_module_type"] = ""
				room["major_under_construction"] = false
				game.cancel_pending_major_construction(room_coord)
			changed = true
			hit_any = true
	var slot_positions: Array = game.minor_slot_positions(room_coord)
	for slot_index in range(slot_positions.size() - 1, -1, -1):
		var module_index: int = game.minor_module_index_for_slot(room_coord, slot_index)
		if module_index < 0 or module_index >= room["minor_modules"].size():
			continue
		var minor_key: String = "%s:minor:%d" % [room_key, slot_index]
		if hit_keys.has(minor_key):
			continue
		if point_distance_to_polyline(game, points, Vector2(slot_positions[slot_index])) > radius + 14.0:
			continue
		hit_keys[minor_key] = true
		var module_data: Dictionary = Dictionary(room["minor_modules"][module_index])
		module_data["health"] = maxf(float(module_data.get("health", 0.0)) - damage, 0.0)
		if float(module_data["health"]) <= 0.0:
			game.cancel_pending_minor_construction(room_coord, int(module_data.get("slot_index", slot_index)))
			room["minor_modules"].remove_at(module_index)
		else:
			room["minor_modules"][module_index] = module_data
		changed = true
		hit_any = true
	if changed:
		game.rooms[room_coord] = room
	return hit_any

static func reflected_direction(direction: Vector2, normal: Vector2) -> Vector2:
	return direction - 2.0 * direction.dot(normal) * normal

static func next_lightning_bounce(start: Vector2, direction: Vector2, bounds: Rect2) -> Dictionary:
	if direction == Vector2.ZERO:
		return {}
	var best_t: float = INF
	var hit_normal: Vector2 = Vector2.ZERO
	if direction.x > 0.001:
		var t_right: float = (bounds.end.x - start.x) / direction.x
		var y_right: float = start.y + direction.y * t_right
		if t_right > 0.001 and y_right >= bounds.position.y - 0.001 and y_right <= bounds.end.y + 0.001 and t_right < best_t:
			best_t = t_right
			hit_normal = Vector2.LEFT
	elif direction.x < -0.001:
		var t_left: float = (bounds.position.x - start.x) / direction.x
		var y_left: float = start.y + direction.y * t_left
		if t_left > 0.001 and y_left >= bounds.position.y - 0.001 and y_left <= bounds.end.y + 0.001 and t_left < best_t:
			best_t = t_left
			hit_normal = Vector2.RIGHT
	if direction.y > 0.001:
		var t_bottom: float = (bounds.end.y - start.y) / direction.y
		var x_bottom: float = start.x + direction.x * t_bottom
		if t_bottom > 0.001 and x_bottom >= bounds.position.x - 0.001 and x_bottom <= bounds.end.x + 0.001 and t_bottom < best_t:
			best_t = t_bottom
			hit_normal = Vector2.UP
	elif direction.y < -0.001:
		var t_top: float = (bounds.position.y - start.y) / direction.y
		var x_top: float = start.x + direction.x * t_top
		if t_top > 0.001 and x_top >= bounds.position.x - 0.001 and x_top <= bounds.end.x + 0.001 and t_top < best_t:
			best_t = t_top
			hit_normal = Vector2.DOWN
	if best_t == INF or hit_normal == Vector2.ZERO:
		return {}
	var hit_position: Vector2 = start + direction * best_t
	return {
		"position": hit_position,
		"direction": reflected_direction(direction, hit_normal).normalized(),
	}

static func build_lightning_bolt_points(game: Node, origin: Vector2, target: Vector2, target_room: Vector2i, bounce_count: int) -> Array:
	var points: Array = [origin, target]
	if bounce_count <= 0 or target_room == game.INVALID_ROOM or not game.rooms.has(target_room):
		return points
	var bounds: Rect2 = game.room_rect(target_room).grow(-26.0)
	var current_position: Vector2 = target
	var direction: Vector2 = (target - origin).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	for _bounce_index in range(bounce_count):
		if not bounds.has_point(current_position):
			current_position = Vector2(
				clampf(current_position.x, bounds.position.x + 2.0, bounds.end.x - 2.0),
				clampf(current_position.y, bounds.position.y + 2.0, bounds.end.y - 2.0)
			)
		var bounce_data: Dictionary = next_lightning_bounce(current_position, direction, bounds)
		if bounce_data.is_empty():
			break
		var hit_position: Vector2 = Vector2(bounce_data.get("position", current_position))
		if hit_position.distance_to(current_position) <= 1.0:
			break
		points.append(hit_position)
		direction = Vector2(bounce_data.get("direction", direction)).normalized()
		if direction == Vector2.ZERO:
			break
		current_position = hit_position + direction * 2.0
	return points

static func cast_lightning_bolt_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	var bolt_origin: Vector2 = hero.global_position
	var bolt_target: Vector2 = game.clamp_point_to_room(target_world_position, target_room)
	var bolt_radius: float = maxf(float(hand_card.get("impact_radius", 18.0)), 8.0)
	var beam_start_width: float = 6.0
	var beam_end_width: float = 24.0
	var beam_outer_visual_width: float = beam_end_width * 2.3
	# Keep damage collision thickness aligned with the visibly widest beam layer.
	bolt_radius = maxf(bolt_radius, beam_outer_visual_width * 0.5)
	var bolt_damage: float = float(hand_card.get("damage", hand_card.get("base_damage", 30.0)))
	var bounce_count: int = maxi(0, int(hand_card.get("bounce_count", 2)))
	var bolt_points: Array = build_lightning_bolt_points(game, bolt_origin, bolt_target, target_room, bounce_count)
	var affected_rooms: Array[Vector2i] = [hero.current_room]
	if target_room != hero.current_room:
		affected_rooms.append(target_room)
	var hit_enemy_uids: Dictionary = {}
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or not affected_rooms.has(enemy.current_room):
			continue
		if hit_enemy_uids.has(int(enemy.enemy_uid)):
			continue
		if point_distance_to_polyline(game, bolt_points, enemy.global_position) > bolt_radius:
			continue
		hit_enemy_uids[int(enemy.enemy_uid)] = true
		var bolt_impact_direction: Vector2 = (enemy.global_position - bolt_origin).normalized()
		if bolt_impact_direction == Vector2.ZERO:
			bolt_impact_direction = (enemy.global_position - bolt_target).normalized()
		if bolt_impact_direction == Vector2.ZERO:
			bolt_impact_direction = (bolt_target - bolt_origin).normalized()
		if bolt_impact_direction == Vector2.ZERO:
			bolt_impact_direction = Vector2.RIGHT
		enemy.take_damage(bolt_damage, bolt_impact_direction)
	var hit_hero_indices: Dictionary = {}
	for room_coord in affected_rooms:
		for room_hero in game.heroes_in_room(room_coord):
			if room_hero == null or not is_instance_valid(room_hero) or room_hero == hero:
				continue
			if hit_hero_indices.has(int(room_hero.hero_index)):
				continue
			if point_distance_to_polyline(game, bolt_points, room_hero.global_position) > bolt_radius:
				continue
			hit_hero_indices[int(room_hero.hero_index)] = true
			apply_spell_damage_to_hero(game, room_hero, bolt_damage, "%s's Lightning Bolt" % hero.hero_name)
	var hit_module_keys: Dictionary = {}
	for room_coord in affected_rooms:
		damage_modules_along_polyline(game, room_coord, bolt_points, bolt_radius, bolt_damage, hit_module_keys)
	hero.trigger_attack(bolt_target, "laser")
	game.projectiles.append({
		"kind": "lightning_bolt",
		"position": Vector2(bolt_points[bolt_points.size() - 1]),
		"previous": Vector2(bolt_points[0]),
		"target_position": bolt_target,
		"color": hand_card.get("color", Color("8bd9ff")),
		"radius": bolt_radius,
		"impact_radius": bolt_radius,
		"lifetime_left": 0.28,
		"blast_duration": 0.28,
		"width": 7.0,
		"beam_start_width": beam_start_width,
		"beam_end_width": beam_end_width,
		"pulse_speed": 0.065,
		"pulse_strength": 0.3,
		"room": target_room,
		"points": bolt_points.duplicate(true),
	})
	game.add_resource_floating_text(bolt_target, "Bolt", Color(hand_card.get("color", Color("8bd9ff"))))

static func append_timed_effect_projectile(game: Node, effect_kind: String, world_position: Vector2, effect_color: Color, lifetime: float, blast_duration: float) -> void:
	game.projectiles.append({
		"kind": effect_kind,
		"position": world_position,
		"previous": world_position,
		"target_position": world_position,
		"color": effect_color,
		"radius": 28.0,
		"impact_radius": 28.0,
		"lifetime_left": lifetime,
		"blast_duration": blast_duration,
		"width": 3.0,
	})

static func active_enemy_count_for_vfx_load(game: Node) -> int:
	var active_count: int = 0
	for enemy in game.enemies:
		if game.enemy_is_active(enemy):
			active_count += 1
	return active_count

static func use_light_enemy_blast_vfx(game: Node) -> bool:
	return active_enemy_count_for_vfx_load(game) >= 16

static func explode_fireball_projectile(game: Node, projectile: Dictionary) -> void:
	var room_coord: Vector2i = projectile.get("room", game.INVALID_ROOM)
	var target_position: Vector2 = projectile.get("target_position", projectile.get("position", Vector2.ZERO))
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return
	var impact_radius: float = maxf(float(projectile.get("impact_radius", 92.0)), 12.0)
	var damage: float = float(projectile.get("damage", 42.0))
	var push_distance: float = float(projectile.get("push_distance", 56.0))
	var apply_combo_flatfooted: bool = bool(projectile.get("combo_flatfooted_on_damage", false))
	var combo_flatfooted_duration: float = maxf(float(projectile.get("combo_flatfooted_duration", 0.0)), 0.0)
	var combo_flatfooted_move_multiplier: float = clampf(float(projectile.get("combo_flatfooted_move_multiplier", 1.0)), 0.0, 1.0)
	var combo_flatfooted_attack_speed_multiplier: float = clampf(float(projectile.get("combo_flatfooted_attack_speed_multiplier", 1.0)), 0.0, 1.0)
	var combo_flatfooted_damage_taken_multiplier: float = maxf(float(projectile.get("combo_flatfooted_damage_taken_multiplier", 1.5)), 1.0)
	var apply_owner_on_hit_effects: bool = bool(projectile.get("apply_owner_on_hit_effects", false))
	var owner_hero: Variant = null
	if apply_owner_on_hit_effects:
		var owner_index: int = int(projectile.get("owner_hero_index", -1))
		if owner_index >= 0 and owner_index < game.heroes.size():
			owner_hero = game.heroes[owner_index]
	var hit_any: bool = false
	var source_label: String = String(projectile.get("source_label", "Fireball"))
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		var enemy_offset: Vector2 = enemy.global_position - target_position
		var enemy_distance: float = enemy_offset.length()
		if enemy_distance > impact_radius:
			continue
		var push_direction: Vector2 = enemy_offset.normalized() if enemy_distance > 0.001 else GAME_DUNGEON_BUILDER.random_room_offset(game, 1.0).normalized()
		if push_direction == Vector2.ZERO:
			push_direction = Vector2.RIGHT
		enemy.take_damage(damage, push_direction)
		if owner_hero != null and is_instance_valid(owner_hero):
			game.register_hero_enemy_hit(owner_hero, enemy, push_direction)
		if apply_combo_flatfooted and combo_flatfooted_duration > 0.0 and enemy.has_method("apply_flatfooted_debuff"):
			enemy.apply_flatfooted_debuff(
				combo_flatfooted_duration,
				combo_flatfooted_move_multiplier,
				combo_flatfooted_attack_speed_multiplier,
				combo_flatfooted_damage_taken_multiplier
			)
		var distance_ratio: float = 1.0 - clampf(enemy_distance / impact_radius, 0.0, 1.0)
		var pushed_position: Vector2 = game.clamp_point_to_room(enemy.global_position + push_direction * push_distance * (0.35 + distance_ratio * 0.65), room_coord)
		enemy.global_position = pushed_position
		enemy.set_destination(pushed_position)
		hit_any = true
	for hero in game.heroes_in_room(room_coord):
		if hero == null or not is_instance_valid(hero):
			continue
		var hero_offset: Vector2 = hero.global_position - target_position
		var hero_distance: float = hero_offset.length()
		if hero_distance > impact_radius:
			continue
		var distance_ratio: float = 1.0 - clampf(hero_distance / maxf(impact_radius, 0.001), 0.0, 1.0)
		var applied_damage: float = damage * (0.7 + distance_ratio * 0.3)
		apply_spell_damage_to_hero(game, hero, applied_damage, source_label)
		var hero_push_direction: Vector2 = hero_offset.normalized() if hero_distance > 0.001 else GAME_DUNGEON_BUILDER.random_room_offset(game, 1.0).normalized()
		if hero_push_direction == Vector2.ZERO:
			hero_push_direction = Vector2.RIGHT
		game.knockback_actor(hero, hero_push_direction, 340.0 * (0.45 + distance_ratio * 0.55), 0.16 + distance_ratio * 0.12, room_coord)
		hit_any = true
	if damage_modules_in_blast(game, room_coord, target_position, impact_radius, damage * 0.38):
		hit_any = true
	game.projectiles.append({
		"kind": "fireball_blast",
		"position": target_position,
		"previous": target_position,
		"target_position": target_position,
		"color": projectile.get("color", Color("ff9a5e")),
		"radius": impact_radius,
		"impact_radius": impact_radius,
		"lifetime_left": 0.24,
		"blast_duration": 0.24,
		"width": 6.0,
	})
	game.add_resource_floating_text(target_position, "Fireball" if hit_any else "Miss", Color(projectile.get("color", Color("ff9a5e"))))

static func explode_enemy_fireball(game: Node, room_coord: Vector2i, target_position: Vector2, damage: float, impact_radius: float, _push_force: float, source_label: String) -> Array[String]:
	var defeated_heroes: Array[String] = []
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return defeated_heroes
	var lightweight_vfx: bool = use_light_enemy_blast_vfx(game)
	var hit_any: bool = false
	for hero in game.heroes_in_room(room_coord):
		if hero == null or not is_instance_valid(hero):
			continue
		var hero_offset: Vector2 = hero.global_position - target_position
		var hero_distance: float = hero_offset.length()
		if hero_distance > impact_radius:
			continue
		var distance_ratio: float = 1.0 - clampf(hero_distance / maxf(impact_radius, 0.001), 0.0, 1.0)
		var applied_damage: float = game.adjusted_incoming_damage_for_hero(hero, damage * (0.7 + distance_ratio * 0.3))
		var defeated: bool = hero.take_damage(applied_damage, false)
		if defeated and try_auto_cast_fatal_shield(game, hero, applied_damage):
			hit_any = true
			continue
		if defeated:
			defeated_heroes.append(hero.hero_name)
		hit_any = true
	for hero_name in defeated_heroes:
		for hero in game.heroes:
			if is_instance_valid(hero) and hero.hero_name == hero_name:
				game.finalize_hero_death(hero, source_label)
				break
	if hit_any:
		game.damage_module(room_coord, damage * 0.38, false, source_label)
	game.projectiles.append({
		"kind": "fireball_blast",
		"position": target_position,
		"previous": target_position,
		"target_position": target_position,
		"color": Color("ff8558"),
		"radius": impact_radius,
		"impact_radius": impact_radius,
		"lifetime_left": 0.14 if lightweight_vfx else 0.22,
		"blast_duration": 0.14 if lightweight_vfx else 0.22,
		"width": 3.6 if lightweight_vfx else 5.0,
	})
	if not lightweight_vfx:
		append_timed_effect_projectile(game, "necromancer_attack_effect", target_position, Color("ff8558"), 0.34, 0.34)
		game.add_resource_floating_text(target_position, "Blast" if hit_any else "Miss", Color("ff8558"))
	elif game.rng.randf() < 0.2:
		game.add_resource_floating_text(target_position, "Blast" if hit_any else "Miss", Color("ff8558"))
	return defeated_heroes

static func spawn_axe_card_projectile(game: Node, hero: Variant, target_world_position: Vector2, hand_card: Dictionary) -> void:
	var direction: Vector2 = (target_world_position - hero.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var axe_pierce: int = maxi(0, int(hand_card.get("pierce", maxi(0, int(hand_card.get("max_pierce", 3)) - 1))))
	var axe_max_pierce: int = axe_pierce + 1
	hero.trigger_attack(target_world_position, "melee")
	game.note_hero_combo_attack(hero)
	game.projectiles.append({
		"kind": "axe",
		"position": hero.global_position,
		"previous": hero.global_position,
		"velocity": direction * float(hand_card.get("speed", 760.0)),
		"damage": float(hand_card.get("damage", 40.0)),
		"color": hand_card.get("color", Color("ffd27a")),
		"width": 7.0,
		"radius": float(hand_card.get("radius", 17.0)),
		"pierce": axe_pierce,
		"max_pierce": axe_max_pierce,
		"pierced_count": 0,
		"knockback_force": float(hand_card.get("knockback_force", 220.0)),
		"knockback_duration": float(hand_card.get("knockback_duration", 0.18)),
		"final_hit_knockback_multiplier": float(hand_card.get("final_hit_knockback_multiplier", 1.9)),
		"final_hit_effect_kind": String(hand_card.get("final_hit_effect_kind", "shield_flash")),
		"final_hit_effect_radius": float(hand_card.get("final_hit_effect_radius", 42.0)),
		"final_hit_effect_duration": float(hand_card.get("final_hit_effect_duration", 0.24)),
		"final_hit_effect_width": float(hand_card.get("final_hit_effect_width", 3.2)),
		"final_hit_effect_color": hand_card.get("final_hit_effect_color", hand_card.get("color", Color("ffd27a"))),
		"final_hit_label": String(hand_card.get("final_hit_label", "Final Hit")),
		"final_hit_label_color": hand_card.get("final_hit_label_color", hand_card.get("color", Color("ffd27a"))),
		"expire_after_hit": false,
		"room": hero.current_room,
		"lifetime_left": float(hand_card.get("lifetime", 2.2)),
		"remaining_bounces": int(hand_card.get("bounces", 2)),
		"bounces": int(hand_card.get("bounces", 2)),
		"rotation_angle": 0.0,
		"spin_speed": 18.0,
		"hit_enemy_uids": [],
		"owner_hero_index": hero.hero_index,
	})

static func spawn_dagger_card_projectiles(game: Node, hero: Variant, target_world_position: Vector2, hand_card: Dictionary) -> void:
	var count: int = maxi(1, int(hand_card.get("projectile_count", 3)))
	var center_direction: Vector2 = (target_world_position - hero.global_position).normalized()
	if center_direction == Vector2.ZERO:
		center_direction = Vector2.RIGHT
	var dagger_pierce: int = maxi(0, int(hand_card.get("pierce", maxi(0, int(hand_card.get("max_pierce", 99)) - 1))))
	var dagger_max_pierce: int = dagger_pierce + 1
	hero.trigger_attack(target_world_position, "laser")
	game.note_hero_combo_attack(hero)
	var spread: float = float(hand_card.get("spread", 0.16))
	for projectile_index in range(count):
		var offset_ratio: float = 0.0 if count == 1 else (float(projectile_index) / float(count - 1) - 0.5) * 2.0
		var direction: Vector2 = center_direction.rotated(offset_ratio * spread)
		game.projectiles.append({
			"kind": "dagger",
			"card_id": String(hand_card.get("card_id", "dagger_card")),
			"position": hero.global_position,
			"previous": hero.global_position,
			"velocity": direction * float(hand_card.get("speed", 1020.0)),
			"damage": float(hand_card.get("damage", 40.0)),
			"color": hand_card.get("color", Color("d7f0ff")),
			"width": 4.0,
			"radius": 9.0,
			"pierce": dagger_pierce,
			"max_pierce": dagger_max_pierce,
			"pierced_count": 0,
			"room": hero.current_room,
			"lifetime_left": float(hand_card.get("lifetime", 1.45)),
			"remaining_bounces": int(hand_card.get("bounces", 2)),
			"bounces": int(hand_card.get("bounces", 2)),
			"rotation_angle": direction.angle(),
			"spin_speed": 0.0,
			"hit_enemy_uids": [],
			"owner_hero_index": hero.hero_index,
			"backstab_multiplier": float(hand_card.get("backstab_multiplier", 2.0)),
			"combo_damage_scale": float(hand_card.get("combo_damage_scale", 1.5)),
			"bounce_explosion_min_bounces": int(hand_card.get("bounce_explosion_min_bounces", 0)),
			"bounce_explosion_impact_radius": float(hand_card.get("bounce_explosion_impact_radius", hand_card.get("impact_radius", 0.0))),
			"bounce_explosion_damage_multiplier": float(hand_card.get("bounce_explosion_damage_multiplier", 1.0)),
			"combo_flatfooted_level_2_threshold": int(hand_card.get("combo_flatfooted_level_2_threshold", 2)),
			"combo_flatfooted_level_3_threshold": int(hand_card.get("combo_flatfooted_level_3_threshold", 3)),
			"combo_flatfooted_duration_level_2": float(hand_card.get("combo_flatfooted_duration_level_2", 2.2)),
			"combo_flatfooted_duration_level_3": float(hand_card.get("combo_flatfooted_duration_level_3", 3.8)),
			"combo_flatfooted_damage_taken_multiplier_level_2": float(hand_card.get("combo_flatfooted_damage_taken_multiplier_level_2", 1.28)),
			"combo_flatfooted_damage_taken_multiplier_level_3": float(hand_card.get("combo_flatfooted_damage_taken_multiplier_level_3", 1.5)),
			"combo_flatfooted_move_multiplier": float(hand_card.get("combo_flatfooted_move_multiplier", 1.0)),
			"combo_flatfooted_attack_speed_multiplier": float(hand_card.get("combo_flatfooted_attack_speed_multiplier", 1.0)),
			"combo_gain": int(hand_card.get("combo_gain", 1)),
		})
