extends RefCounted

static func priority_rank(priority_table: Dictionary, category: String) -> int:
	var rank: int = int(priority_table.get(category, -1))
	return rank if rank >= 0 else 999

static func highest_priority_choice(seeker: Variant, choices: Array, priority_table: Dictionary) -> Dictionary:
	if seeker == null or not is_instance_valid(seeker):
		return {}
	var selected_choice: Dictionary = {}
	var selected_rank: int = 999
	var selected_distance: float = INF
	for choice_variant in choices:
		var choice: Dictionary = choice_variant
		var rank: int = priority_rank(priority_table, String(choice.get("category", "")))
		if rank >= 999:
			continue
		var distance_value: float = seeker.global_position.distance_to(Vector2(choice.get("position", seeker.global_position)))
		if rank < selected_rank or (rank == selected_rank and distance_value < selected_distance):
			selected_choice = choice
			selected_rank = rank
			selected_distance = distance_value
	return selected_choice

static func persistent_actor_target_choice(seeker: Variant, target_meta: StringName, choices: Array, priority_table: Dictionary) -> Dictionary:
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
	var selected_choice: Dictionary = highest_priority_choice(seeker, choices, priority_table)
	if not selected_choice.is_empty():
		seeker.set_meta(target_meta, selected_choice)
	return selected_choice