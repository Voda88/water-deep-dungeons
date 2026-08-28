extends RefCounted

static func targetable_hostile_enemies_in_room(game: Node, room_coord: Vector2i, include_transitions: bool = false) -> Array:
	var candidates: Array = []
	for enemy_variant in game.enemies:
		var enemy: Variant = enemy_variant
		if not game.enemy_is_active(enemy):
			continue
		if enemy.has_method("is_converted") and enemy.is_converted():
			continue
		var is_in_room: bool = Vector2i(enemy.current_room) == room_coord
		if include_transitions:
			is_in_room = is_in_room or Vector2i(enemy.pending_room) == room_coord or Vector2i(enemy.next_room) == room_coord
		elif bool(enemy.moving_between_rooms):
			continue
		if is_in_room:
			candidates.append(enemy)
	return candidates

static func targetable_hostile_enemies_by_room(game: Node) -> Dictionary:
	var enemies_by_room: Dictionary = {}
	for enemy_variant in game.enemies:
		var enemy: Variant = enemy_variant
		if not game.enemy_is_active(enemy):
			continue
		if enemy.has_method("is_converted") and enemy.is_converted():
			continue
		var candidate_rooms: Array[Vector2i] = [Vector2i(enemy.current_room), Vector2i(enemy.pending_room), Vector2i(enemy.next_room)]
		var visited_rooms: Dictionary = {}
		for candidate_room in candidate_rooms:
			if candidate_room == game.INVALID_ROOM or visited_rooms.has(candidate_room) or not game.rooms.has(candidate_room):
				continue
			visited_rooms[candidate_room] = true
			if not enemies_by_room.has(candidate_room):
				enemies_by_room[candidate_room] = []
			(enemies_by_room[candidate_room] as Array).append(enemy)
	return enemies_by_room

static func target_category_for_actor(game: Node, seeker: Variant, actor: Variant) -> String:
	if actor == null or not is_instance_valid(actor):
		return ""
	if game.is_module_actor(actor):
		return "major_module" if actor.is_major else "minor_module"
	if game.is_enemy_actor(actor):
		return "hostile_enemy"
	if game.is_enemy_actor(seeker) and seeker.has_method("is_converted") and seeker.is_converted():
		return "hostile_enemy"
	return "ranged_target" if game.hero_is_long_range_target(actor) else "melee_target"

static func select_in_room_actor_target(game: Node, seeker: Variant, candidates: Array, priority_table: Dictionary, target_meta: StringName = &"", prefer_highest_strength: bool = false) -> Variant:
	if seeker == null or not is_instance_valid(seeker):
		return null
	var choices: Array = []
	for candidate_variant in candidates:
		var candidate: Variant = candidate_variant
		if candidate == null or not is_instance_valid(candidate):
			continue
		choices.append({
			"category": target_category_for_actor(game, seeker, candidate),
			"position": candidate.global_position,
			"actor": candidate,
			"strength": float(candidate.get("current_health", 0.0)),
		})
	var target_choice: Dictionary = persistent_actor_target_choice(seeker, target_meta, choices, priority_table, prefer_highest_strength) if target_meta != &"" else highest_priority_choice(seeker, choices, priority_table, prefer_highest_strength)
	return target_choice.get("actor", null)

static func select_actor_targets(origin: Vector2, candidates: Array, strategy: String, max_range: float = 0.0) -> Array:
	var selected_targets: Array = []
	if strategy == "none":
		return selected_targets
	var selected_target: Variant = null
	var selected_strength: float = -INF
	var selected_distance: float = INF
	for candidate_variant in candidates:
		var candidate: Variant = candidate_variant
		if candidate == null or not is_instance_valid(candidate):
			continue
		var distance_value: float = origin.distance_to(candidate.global_position)
		if max_range > 0.0 and distance_value > max_range:
			continue
		if strategy == "all":
			selected_targets.append(candidate)
			continue
		var strength: float = float(candidate.get("current_health", 0.0))
		if selected_target == null \
		or (strategy == "strongest" and (strength > selected_strength or (is_equal_approx(strength, selected_strength) and distance_value < selected_distance))) \
		or (strategy != "strongest" and distance_value < selected_distance):
			selected_target = candidate
			selected_strength = strength
			selected_distance = distance_value
	if selected_target != null:
		selected_targets.append(selected_target)
	return selected_targets

static func priority_rank(priority_table: Dictionary, category: String) -> int:
	var rank: int = int(priority_table.get(category, -1))
	return rank if rank >= 0 else 999

static func highest_priority_choice(seeker: Variant, choices: Array, priority_table: Dictionary, prefer_highest_strength: bool = false) -> Dictionary:
	if seeker == null or not is_instance_valid(seeker):
		return {}
	var selected_choice: Dictionary = {}
	var selected_rank: int = 999
	var selected_strength: float = -INF
	var selected_secondary_strength: float = -INF
	var selected_distance: float = INF
	for choice_variant in choices:
		var choice: Dictionary = choice_variant
		var rank: int = priority_rank(priority_table, String(choice.get("category", "")))
		if rank >= 999:
			continue
		var strength: float = float(choice.get("strength", 0.0))
		var secondary_strength: float = float(choice.get("secondary_strength", 0.0))
		var distance_value: float = seeker.global_position.distance_to(Vector2(choice.get("position", seeker.global_position)))
		if rank < selected_rank \
		or (rank == selected_rank and prefer_highest_strength and strength > selected_strength) \
		or (rank == selected_rank and prefer_highest_strength and is_equal_approx(strength, selected_strength) and secondary_strength > selected_secondary_strength) \
		or (rank == selected_rank and (not prefer_highest_strength or (is_equal_approx(strength, selected_strength) and is_equal_approx(secondary_strength, selected_secondary_strength))) and distance_value < selected_distance):
			selected_choice = choice
			selected_rank = rank
			selected_strength = strength
			selected_secondary_strength = secondary_strength
			selected_distance = distance_value
	return selected_choice

static func persistent_actor_target_choice(seeker: Variant, target_meta: StringName, choices: Array, priority_table: Dictionary, prefer_highest_strength: bool = false) -> Dictionary:
	if seeker == null or not is_instance_valid(seeker):
		return {}
	if seeker.has_meta(target_meta):
		var stored_choice: Dictionary = Dictionary(seeker.get_meta(target_meta, {}))
		var stored_actor: Variant = stored_choice.get("actor", null)
		for choice_variant in choices:
			var choice: Dictionary = choice_variant
			if choice.get("actor", null) == stored_actor and is_instance_valid(stored_actor):
				return choice
		seeker.remove_meta(target_meta)
	var selected_choice: Dictionary = highest_priority_choice(seeker, choices, priority_table, prefer_highest_strength)
	if not selected_choice.is_empty():
		seeker.set_meta(target_meta, selected_choice)
	return selected_choice

static func contains_target_choice(choices: Array, expected_choice: Dictionary) -> bool:
	var expected_category: String = String(expected_choice.get("category", ""))
	var expected_room: Vector2i = Vector2i(expected_choice.get("room", Vector2i(-99999, -99999)))
	var expected_actor: Variant = expected_choice.get("actor", null)
	for choice_variant in choices:
		var choice: Dictionary = choice_variant
		if String(choice.get("category", "")) != expected_category:
			continue
		if Vector2i(choice.get("room", Vector2i(-99999, -99999))) != expected_room:
			continue
		if choice.get("actor", null) == expected_actor:
			return true
	return false