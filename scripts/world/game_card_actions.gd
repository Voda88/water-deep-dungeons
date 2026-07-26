extends RefCounted

const GAME_DUNGEON_BUILDER: GDScript = preload("res://scripts/world/game_dungeon_builder.gd")
const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/game_inventory_item_flow.gd")

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

static func play_reaction_card_for_hero_at_index(game: Node, hero: Variant, hand_index: int) -> bool:
	if hero == null or not is_instance_valid(hero) or hand_index < 0 or hand_index >= hero.hand_cards.size():
		return false
	var hand_card: Dictionary = (hero.hand_cards[hand_index] as Dictionary).duplicate(true)
	if not game.hand_card_phase_allows_play(hand_card):
		return false
	var target_data: Dictionary = {
		"hero": hero,
		"room": hero.current_room,
		"world_position": hero.global_position,
	}
	if not game.apply_hand_card_effect(hero, hand_card, target_data):
		return false
	if not bool(hand_card.get("reusable", false)):
		hero.hand_cards.remove_at(hand_index)
		game.finalize_played_hand_card_source(hand_card)
	game.fill_queued_hand_cards(hero)
	game.cleanup_global_item_card_states()
	return true

static func trigger_first_reaction_card(game: Node, hero: Variant, trigger_id: String) -> bool:
	if hero == null or not is_instance_valid(hero) or trigger_id == "":
		return false
	for hand_index in range(hero.hand_cards.size()):
		var hand_card: Dictionary = hero.hand_cards[hand_index]
		if String(hand_card.get("reaction_trigger", "")) != trigger_id or not bool(hand_card.get("reaction_enabled", false)):
			continue
		if play_reaction_card_for_hero_at_index(game, hero, hand_index):
			return true
	return false

static func spend_hero_stamina_with_reactions(game: Node, hero: Variant, amount: float) -> bool:
	if amount > 0.0 and not game.stamina_use_enabled:
		return false
	if hero == null or not is_instance_valid(hero):
		return false
	var previous_stamina: float = hero.stamina
	if not hero.spend_stamina(amount):
		return false
	if previous_stamina >= -0.001 and hero.stamina < -0.001:
		trigger_first_reaction_card(game, hero, "stamina_negative")
	return true

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
			rebuilt_card["reaction_enabled"] = bool(state.get("reaction_enabled", rebuilt_card.get("reaction_enabled", false)))
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

static func resolve_card_target(game: Node, hero: Variant, hand_card: Dictionary, target_world_position: Vector2) -> Dictionary:
	if hero == null or not is_instance_valid(hero):
		return {}
	var target_scope: String = String(hand_card.get("target_scope", "hero_room"))
	match target_scope:
		"global":
			return {
				"world_position": target_world_position,
			}
		"hero":
			var target_hero: Variant = hero_at_world_position(game, target_world_position, false)
			if target_hero == null or not is_instance_valid(target_hero):
				return {}
			return {
				"hero": target_hero,
				"hero_index": target_hero.hero_index,
				"world_position": target_hero.global_position,
			}
		"same_hero":
			return {
				"hero": hero,
				"hero_index": hero.hero_index,
				"world_position": hero.global_position,
			}
		"opened_room":
			var target_room: Vector2i = room_target_at_world_position(game, target_world_position, game.active_hero_room_for_commands(hero))
			if target_room == game.INVALID_ROOM or not game.rooms.has(target_room) or not game.rooms[target_room]["opened"]:
				return {}
			return {
				"room": target_room,
				"world_position": game.clamp_point_to_room(target_world_position, target_room),
			}
		"same_room", "hero_room":
			if not game.rooms.has(hero.current_room) or not game.room_rect(hero.current_room).has_point(target_world_position):
				return {}
			return {
				"room": hero.current_room,
				"world_position": target_world_position,
			}
	return {}

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
	if not bool(hand_card.get("requires_line_of_effect", false)):
		return game.room_action_staging_position(cast_room)
	if target_room == game.INVALID_ROOM or cast_room == target_room:
		return game.room_action_staging_position(cast_room)
	var resolved_target: Vector2 = target_world_position
	if resolved_target == Vector2.INF:
		resolved_target = game.room_walkable_center(target_room)
	return cross_room_card_cast_staging_position(game, cast_room, target_room, resolved_target)

static func card_cast_has_line_of_effect(game: Node, cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2) -> bool:
	if not bool(hand_card.get("requires_line_of_effect", false)):
		return true
	if cast_room == game.INVALID_ROOM or target_room == game.INVALID_ROOM or not game.rooms.has(cast_room) or not game.rooms.has(target_room):
		return false
	if cast_room == target_room:
		return game.room_walkable_contains_point(target_room, game.clamp_point_to_room(target_world_position, target_room), 10.0)
	return card_cast_staging_position(game, cast_room, target_room, hand_card, target_world_position) != Vector2.INF

static func hero_ready_for_card_cast(game: Node, hero: Variant, cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2 = Vector2.INF) -> bool:
	if not game.hero_ready_for_room_action(hero, cast_room):
		return false
	if not bool(hand_card.get("requires_line_of_effect", false)):
		return true
	if cast_room == target_room or target_room == game.INVALID_ROOM:
		return true
	var staging_position: Vector2 = card_cast_staging_position(game, cast_room, target_room, hand_card, target_world_position)
	return staging_position != Vector2.INF and hero.global_position.distance_to(staging_position) <= 22.0

static func best_card_cast_room(game: Node, from_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2) -> Vector2i:
	var candidates: Array[Vector2i] = card_cast_candidate_rooms(game, target_room, hand_card)
	if candidates.is_empty():
		return game.INVALID_ROOM
	var best_room: Vector2i = game.INVALID_ROOM
	var best_path_size: int = 999999
	var best_target_distance: int = 999999
	for candidate in candidates:
		if bool(hand_card.get("requires_line_of_effect", false)) and not card_cast_has_line_of_effect(game, candidate, target_room, hand_card, target_world_position):
			continue
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
	return not resolve_card_target(game, hero, hand_card, target_world_position).is_empty()

static func hand_card_starts_spell_study(game: Node, hero: Variant, hand_card: Dictionary, target_data: Dictionary) -> bool:
	if hero == null or not is_instance_valid(hero) or game.wave_in_progress():
		return false
	if not bool(hand_card.get("learnable_spell_scroll", false)):
		return false
	var spell_id: String = String(hand_card.get("learn_spell_id", ""))
	if not game.hero_can_study_spell(hero, spell_id):
		return false
	var target_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
	if target_room != game.INVALID_ROOM:
		return target_room == hero.current_room and game.hero_ready_for_room_action(hero, target_room)
	var target_hero: Variant = target_data.get("hero", null)
	return target_hero == hero and game.hero_ready_for_room_action(hero, hero.current_room)

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
	var target_world_position: Vector2 = Vector2(target_data.get("world_position", hero.global_position))
	if hand_card_starts_spell_study(game, hero, hand_card, target_data):
		return game.begin_spell_scroll_study(hero, String(hand_card.get("learn_spell_id", "")))
	match String(hand_card.get("card_id", "")):
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
		"misty_step_card":
			var teleport_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if teleport_room == game.INVALID_ROOM or not game.rooms.has(teleport_room):
				return false
			cast_misty_step_spell(game, hero, target_world_position, teleport_room, hand_card)
			game.status_message = "%s cast Misty Step." % hero.hero_name
			return true
		"shield_card":
			cast_shield_spell(game, hero, hand_card)
			game.status_message = "%s cast Shield." % hero.hero_name
			return true
		"cure_light_wounds_card":
			var cleric_target: Variant = target_data.get("hero", hero)
			if cleric_target == null or not is_instance_valid(cleric_target):
				return false
			var previous_cleric_health: float = cleric_target.current_health
			cleric_target.heal(float(hand_card.get("heal_amount", 36.0)))
			hero.trigger_attack(cleric_target.global_position, "laser")
			if cleric_target.current_health <= previous_cleric_health + 0.001:
				game.status_message = "%s does not need healing." % cleric_target.hero_name
				return false
			game.status_message = "%s cast Cure Light Wounds." % hero.hero_name
			return true
		"sanctuary_card":
			cast_shield_spell(game, hero, {
				"shield_amount": float(hand_card.get("shield_amount", 24.0)),
				"shield_duration": float(hand_card.get("shield_duration", 8.0)),
				"color": hand_card.get("color", Color("e3ff9f")),
			})
			game.status_message = "%s invoked Sanctuary." % hero.hero_name
			return true
		"lightning_bolt_card":
			var bolt_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
			if bolt_room == game.INVALID_ROOM or not game.rooms.has(bolt_room):
				return false
			cast_lightning_bolt_spell(game, hero, target_world_position, bolt_room, hand_card)
			game.status_message = "%s cast Lightning Bolt." % hero.hero_name
			return true
		"lantern_torch_card":
			var target_hero: Variant = target_data.get("hero", null)
			if target_hero == null or not is_instance_valid(target_hero):
				return false
			var created_torch: Dictionary = GAME_INVENTORY_ITEM_FLOW.make_inventory_item(game, "torch")
			if not game.add_item_to_hero_inventory(target_hero, created_torch):
				game.status_message = "%s has no room for a torch." % target_hero.hero_name
				return false
			hero.trigger_attack(target_hero.global_position, "laser")
			game.status_message = "%s prepared a torch for %s." % [hero.hero_name, target_hero.hero_name]
			return true
		"torch_card":
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
			var target_hero_mend: Variant = target_data.get("hero", null)
			if target_hero_mend == null or not is_instance_valid(target_hero_mend):
				return false
			var previous_health: float = target_hero_mend.current_health
			target_hero_mend.heal(float(hand_card.get("heal_amount", 35.0)))
			hero.trigger_attack(target_hero_mend.global_position, "laser")
			if target_hero_mend.current_health <= previous_health + 0.001:
				game.status_message = "%s is already fully patched up." % target_hero_mend.hero_name
				return false
			game.status_message = "%s restored %s." % [hero.hero_name, target_hero_mend.hero_name]
			return true
		"emergency_snack_card":
			var snack_target: Variant = target_data.get("hero", hero)
			if snack_target == null or not is_instance_valid(snack_target):
				return false
			var food_cost: int = int(hand_card.get("food_cost", game.HEAL_FOOD_COST))
			if game.food < food_cost:
				game.status_message = "Not enough food for %s." % String(hand_card.get("name", "that card"))
				return false
			game.food -= food_cost
			snack_target.restore_health()
			snack_target.refill_stamina()
			snack_target.combo_points = 0
			snack_target.clear_stamina_regen_buff()
			hero.trigger_attack(snack_target.global_position, "laser")
			game.status_message = "%s used an emergency snack." % snack_target.hero_name
			return true
		"ration_meal_card":
			var ration_target: Variant = target_data.get("hero", hero)
			if ration_target == null or not is_instance_valid(ration_target):
				return false
			var previous_ration_health: float = ration_target.current_health
			var previous_ration_stamina: float = ration_target.stamina
			var previous_regen_time_left: float = ration_target.stamina_regen_time_left
			if bool(hand_card.get("heal_full", false)):
				ration_target.restore_health()
			else:
				ration_target.heal(float(hand_card.get("heal_amount", 0.0)))
			if bool(hand_card.get("restore_stamina_full", false)):
				ration_target.refill_stamina()
			else:
				ration_target.restore_stamina(float(hand_card.get("stamina_restore", 0.0)))
			ration_target.apply_stamina_regen_buff(float(hand_card.get("stamina_regen_rate", 0.0)), float(hand_card.get("stamina_regen_duration", 0.0)))
			hero.trigger_attack(ration_target.global_position, "laser")
			if ration_target.current_health <= previous_ration_health + 0.001 and ration_target.stamina <= previous_ration_stamina + 0.001 and ration_target.stamina_regen_time_left <= previous_regen_time_left + 0.001:
				game.status_message = "%s does not need a ration right now." % ration_target.hero_name
				return false
			game.status_message = "%s ate a ration." % ration_target.hero_name
			return true
		"dagger_card":
			spawn_dagger_card_projectiles(game, hero, target_world_position, hand_card)
			game.status_message = "%s flung a dagger fan." % hero.hero_name
			return true
		_:
			spawn_axe_card_projectile(game, hero, target_world_position, hand_card)
			game.status_message = "%s hurled a whirling axe." % hero.hero_name
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
	if not hand_card_phase_allows_play(game, hand_card):
		return false
	var target_data: Dictionary = resolve_card_target(game, hero, hand_card, target_world_position)
	if target_data.is_empty():
		return false
	var target_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
	if target_room != game.INVALID_ROOM:
		var cast_room: Vector2i = best_card_cast_room(game, game.active_hero_room_for_commands(hero), target_room, hand_card, Vector2(target_data.get("world_position", target_world_position)))
		if cast_room == game.INVALID_ROOM:
			game.status_message = "No line of effect to that spot."
			game.update_hud()
			return false
		if not hero_ready_for_card_cast(game, hero, cast_room, target_room, hand_card, Vector2(target_data.get("world_position", target_world_position))):
			return game.request_deferred_room_card_for_hero(hero_index, cast_room, target_room, card_uid, Vector2(target_data.get("world_position", target_world_position)))
	var is_study_play: bool = hand_card_starts_spell_study(game, hero, hand_card, target_data)
	var stamina_cost: float = float(hand_card.get("stamina_cost", 0.0))
	if not is_study_play and stamina_cost > 0.0 and not spend_hero_stamina_with_reactions(game, hero, stamina_cost):
		game.status_message = "%s is too exhausted for that." % hero.hero_name
		game.update_hud()
		return false
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
		game.spawn_laser_projectile(hero.global_position, target_enemy, float(hand_card.get("damage", hand_card.get("base_damage", 14.0))), hand_card.get("color", Color("9cd7ff")), 4.2, 1480.0)

static func cast_misty_step_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	var landing_position: Vector2 = game.clamp_point_to_room(target_world_position, target_room)
	hero.clear_orders()
	game.clear_pending_room_action_request(hero.hero_index)
	game.clear_pending_room_loot_request(hero.hero_index)
	hero.set_room(target_room, landing_position)
	hero.trigger_attack(landing_position, "laser")
	game.projectiles.append({
		"kind": "fireball_blast",
		"position": landing_position,
		"previous": landing_position,
		"target_position": landing_position,
		"color": hand_card.get("color", Color("b89cff")),
		"radius": 18.0,
		"impact_radius": 42.0,
		"lifetime_left": 0.16,
		"blast_duration": 0.16,
		"width": 4.0,
	})
	game.add_resource_floating_text(landing_position, "Step", Color(hand_card.get("color", Color("b89cff"))))

static func cast_shield_spell(game: Node, hero: Variant, hand_card: Dictionary) -> void:
	var barrier_amount: float = float(hand_card.get("shield_amount", 34.0))
	var barrier_duration: float = float(hand_card.get("shield_duration", 10.0))
	var immunity_duration: float = float(hand_card.get("immunity_duration", 0.0))
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
	if hero.current_health <= 0.0 or hero.invulnerability_time_left > 0.0:
		return false
	var lethal_damage: float = projected_hero_damage_after_barrier(game, hero, incoming_damage)
	if lethal_damage < hero.current_health - 0.001:
		return false
	if not trigger_first_reaction_card(game, hero, "fatal_damage"):
		return false
	game.status_message = "%s reflexively cast Shield." % hero.hero_name
	return true

static func cast_lightning_bolt_spell(game: Node, hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	var bolt_origin: Vector2 = hero.global_position
	var bolt_target: Vector2 = game.clamp_point_to_room(target_world_position, target_room)
	var bolt_radius: float = maxf(float(hand_card.get("impact_radius", 18.0)), 8.0)
	var bolt_damage: float = float(hand_card.get("damage", hand_card.get("base_damage", 30.0)))
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy):
			continue
		if enemy.current_room != hero.current_room and enemy.current_room != target_room:
			continue
		if game.point_distance_to_segment(enemy.global_position, bolt_origin, bolt_target) > bolt_radius:
			continue
		enemy.take_damage(bolt_damage)
	hero.trigger_attack(bolt_target, "laser")
	game.projectiles.append({
		"kind": "lightning_bolt",
		"position": bolt_target,
		"previous": bolt_origin,
		"target_position": bolt_target,
		"color": hand_card.get("color", Color("8bd9ff")),
		"radius": bolt_radius,
		"impact_radius": bolt_radius,
		"lifetime_left": 0.18,
		"blast_duration": 0.18,
		"width": 7.0,
		"room": target_room,
	})
	game.add_resource_floating_text(bolt_target, "Bolt", Color(hand_card.get("color", Color("8bd9ff"))))

static func explode_fireball_projectile(game: Node, projectile: Dictionary) -> void:
	var room_coord: Vector2i = projectile.get("room", game.INVALID_ROOM)
	var target_position: Vector2 = projectile.get("target_position", projectile.get("position", Vector2.ZERO))
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return
	var impact_radius: float = maxf(float(projectile.get("impact_radius", 92.0)), 12.0)
	var damage: float = float(projectile.get("damage", 42.0))
	var push_distance: float = float(projectile.get("push_distance", 56.0))
	var hit_any: bool = false
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		var enemy_offset: Vector2 = enemy.global_position - target_position
		var enemy_distance: float = enemy_offset.length()
		if enemy_distance > impact_radius:
			continue
		enemy.take_damage(damage)
		var push_direction: Vector2 = enemy_offset.normalized() if enemy_distance > 0.001 else GAME_DUNGEON_BUILDER.random_room_offset(game, 1.0).normalized()
		if push_direction == Vector2.ZERO:
			push_direction = Vector2.RIGHT
		var distance_ratio: float = 1.0 - clampf(enemy_distance / impact_radius, 0.0, 1.0)
		var pushed_position: Vector2 = game.clamp_point_to_room(enemy.global_position + push_direction * push_distance * (0.35 + distance_ratio * 0.65), room_coord)
		enemy.global_position = pushed_position
		enemy.set_destination(pushed_position)
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

static func explode_enemy_fireball(game: Node, room_coord: Vector2i, target_position: Vector2, damage: float, impact_radius: float, push_force: float, source_label: String) -> Array[String]:
	var defeated_heroes: Array[String] = []
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return defeated_heroes
	var hit_any: bool = false
	for hero in game.heroes_in_room(room_coord):
		if hero == null or not is_instance_valid(hero):
			continue
		var hero_offset: Vector2 = hero.global_position - target_position
		var hero_distance: float = hero_offset.length()
		if hero_distance > impact_radius:
			continue
		var distance_ratio: float = 1.0 - clampf(hero_distance / maxf(impact_radius, 0.001), 0.0, 1.0)
		var applied_damage: float = damage * (0.7 + distance_ratio * 0.3)
		if try_auto_cast_fatal_shield(game, hero, applied_damage):
			hit_any = true
			continue
		var defeated: bool = hero.take_damage(applied_damage)
		var push_direction: Vector2 = hero_offset.normalized() if hero_distance > 0.001 else GAME_DUNGEON_BUILDER.random_room_offset(game, 1.0).normalized()
		if push_direction == Vector2.ZERO:
			push_direction = Vector2.RIGHT
		game.knockback_actor(hero, push_direction, push_force * (0.45 + distance_ratio * 0.55), 0.16 + distance_ratio * 0.12, room_coord)
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
		"lifetime_left": 0.22,
		"blast_duration": 0.22,
		"width": 5.0,
	})
	game.add_resource_floating_text(target_position, "Blast" if hit_any else "Miss", Color("ff8558"))
	return defeated_heroes

static func spawn_axe_card_projectile(game: Node, hero: Variant, target_world_position: Vector2, hand_card: Dictionary) -> void:
	var direction: Vector2 = (target_world_position - hero.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	hero.trigger_attack(target_world_position, "melee")
	game.projectiles.append({
		"kind": "axe",
		"position": hero.global_position,
		"previous": hero.global_position,
		"velocity": direction * float(hand_card.get("speed", 760.0)),
		"damage": float(hand_card.get("damage", 20.0)),
		"color": hand_card.get("color", Color("ffd27a")),
		"width": 7.0,
		"radius": float(hand_card.get("radius", 17.0)),
		"room": hero.current_room,
		"lifetime_left": float(hand_card.get("lifetime", 2.2)),
		"remaining_bounces": int(hand_card.get("bounces", 2)),
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
	hero.trigger_attack(target_world_position, "laser")
	var spread: float = float(hand_card.get("spread", 0.16))
	for projectile_index in range(count):
		var offset_ratio: float = 0.0 if count == 1 else (float(projectile_index) / float(count - 1) - 0.5) * 2.0
		var direction: Vector2 = center_direction.rotated(offset_ratio * spread)
		game.projectiles.append({
			"kind": "dagger",
			"position": hero.global_position,
			"previous": hero.global_position,
			"velocity": direction * float(hand_card.get("speed", 1020.0)),
			"damage": float(hand_card.get("damage", 10.0)) + float(hero.combo_points) * 1.5,
			"color": hand_card.get("color", Color("d7f0ff")),
			"width": 4.0,
			"radius": 9.0,
			"room": hero.current_room,
			"lifetime_left": float(hand_card.get("lifetime", 1.45)),
			"remaining_bounces": int(hand_card.get("bounces", 1)),
			"rotation_angle": direction.angle(),
			"spin_speed": 0.0,
			"hit_enemy_uids": [],
			"owner_hero_index": hero.hero_index,
			"backstab_multiplier": float(hand_card.get("backstab_multiplier", 1.75)),
			"combo_gain": int(hand_card.get("combo_gain", 1)),
		})
