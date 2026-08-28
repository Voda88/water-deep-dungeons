extends RefCounted

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