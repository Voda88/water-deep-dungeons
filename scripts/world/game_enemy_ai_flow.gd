extends RefCounted

static func advance_enemy_routes(game: Node, delta: float) -> void:
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy):
			continue
		if enemy.has_method("set_situational_speed_multiplier"):
			enemy.set_situational_speed_multiplier(enemy_situational_speed_multiplier(game, enemy))
		enemy.attack_cooldown_left = maxf(enemy.attack_cooldown_left - delta, 0.0)
		if enemy.pending_room != game.INVALID_ROOM:
			if enemy.is_idle():
				enemy.moving_between_rooms = false
				enemy.previous_room = enemy.current_room
				enemy.current_room = enemy.pending_room
				enemy.pending_room = game.INVALID_ROOM
			else:
				continue
		var target_room: Vector2i = target_room_for_enemy(game, enemy)
		if target_room == game.INVALID_ROOM:
			enemy.move_steps.clear()
			continue
		var target_position: Vector2 = enemy_target_position(game, enemy)
		var attack_start_distance: float = enemy_attack_start_distance(game, enemy)
		if not enemy.is_idle():
			if enemy.current_room == target_room:
				var live_distance: float = enemy.global_position.distance_to(target_position)
				if live_distance <= attack_start_distance:
					enemy.move_steps.clear()
					enemy.next_room = enemy.current_room
					enemy.moving_between_rooms = false
					enemy.set_destination(enemy.global_position)
					resolve_enemy_attack(game, enemy)
					continue
				enemy.move_steps.clear()
				enemy.next_room = enemy.current_room
				enemy.moving_between_rooms = false
				enemy.set_destination(target_position)
			continue
		if enemy.current_room == target_room and enemy.global_position.distance_to(target_position) <= attack_start_distance:
			enemy.move_steps.clear()
			resolve_enemy_attack(game, enemy)
			continue
		if enemy.move_steps.is_empty() or not game.enemy_move_plan_matches(enemy, target_room, target_position):
			if enemy.current_room == target_room:
				game.issue_enemy_steps(enemy, game.build_steps_for_path([target_room], enemy.global_position, target_position))
			else:
				var path: Array[Vector2i] = game.find_path(enemy.current_room, target_room, true)
				if path.size() <= 1:
					enemy.move_steps.clear()
					continue
				game.issue_enemy_steps(enemy, game.build_steps_for_path(path, enemy.global_position, target_position))
		if enemy.move_steps.is_empty():
			continue
		var next_step: Dictionary = enemy.move_steps[0]
		enemy.move_steps.remove_at(0)
		var next_room: Vector2i = next_step["room"]
		var next_position: Vector2 = next_step["position"]
		if next_room != enemy.current_room:
			enemy.pending_room = next_room
			enemy.next_room = next_room
			enemy.moving_between_rooms = true
		else:
			enemy.next_room = enemy.current_room
			enemy.moving_between_rooms = false
		enemy.set_destination(next_position)

static func target_room_for_enemy(game: Node, enemy: Variant) -> Vector2i:
	var local_target: Variant = local_enemy_override_target(game, enemy)
	if local_target != null:
		return hero_room_for_enemy_targeting(game, local_target)
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_LIZARDMAN:
			var lizard_target: Variant = orc_rider_target_hero(game, enemy)
			if lizard_target == null:
				return game.crystal_room
			return hero_room_for_enemy_targeting(game, lizard_target)
		game.ENEMY_TYPE_SKELETON_ARCHER:
			var archer_target: Variant = skeleton_archer_target_hero(game, enemy)
			if archer_target == null:
				return game.crystal_room
			return hero_room_for_enemy_targeting(game, archer_target)
		game.ENEMY_TYPE_GOBLIN, game.ENEMY_TYPE_GOBLIN_SHAMAN:
			if enemy.current_room == game.crystal_room and heroes_in_room(game, enemy.current_room).is_empty():
				return game.crystal_room
			var goblin_target: Variant = goblin_target_hero(game, enemy)
			if goblin_target != null:
				return hero_room_for_enemy_targeting(game, goblin_target)
			return game.crystal_room
		game.ENEMY_TYPE_GOLEM:
			var major_module_room: Vector2i = preferred_golem_major_module_room(game, enemy)
			if major_module_room != game.INVALID_ROOM:
				return major_module_room
			return game.crystal_room
		game.ENEMY_TYPE_BAT:
			return game.crystal_room
		_:
			return game.crystal_room

static func enemy_room_goal_position(game: Node, enemy: Variant, room_coord: Vector2i) -> Vector2:
	var target_room: Vector2i = target_room_for_enemy(game, enemy)
	if target_room == game.INVALID_ROOM:
		return game.clamp_point_to_room(enemy.global_position, room_coord)
	if room_coord == target_room:
		return enemy_target_position(game, enemy)
	var path: Array[Vector2i] = game.find_path(room_coord, target_room, true)
	if path.size() > 1:
		return game.doorway_navigation_position(room_coord, path[1])
	return game.clamp_point_to_room(enemy.global_position, room_coord)

static func enemy_target_position(game: Node, enemy: Variant) -> Vector2:
	var local_target: Variant = local_enemy_override_target(game, enemy)
	if local_target != null:
		if String(enemy.enemy_role) == game.ENEMY_TYPE_SKELETON_ARCHER:
			return skeleton_archer_goal_position(game, enemy)
		return local_target.global_position
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_LIZARDMAN:
			var lizard_target: Variant = orc_rider_target_hero(game, enemy)
			if lizard_target != null:
				return lizard_target.global_position
			return game.clamp_point_to_room(enemy.global_position, enemy.current_room)
		game.ENEMY_TYPE_SKELETON_ARCHER:
			var archer_target: Variant = skeleton_archer_target_hero(game, enemy)
			if archer_target != null:
				if hero_is_in_room(game, archer_target, enemy.current_room):
					return skeleton_archer_goal_position(game, enemy)
				return archer_target.global_position
			return game.crystal_world_position()
		game.ENEMY_TYPE_GOBLIN, game.ENEMY_TYPE_GOBLIN_SHAMAN:
			if enemy.current_room == game.crystal_room and heroes_in_room(game, enemy.current_room).is_empty():
				return game.crystal_world_position()
			var goblin_target: Variant = goblin_target_hero(game, enemy)
			if goblin_target != null:
				return goblin_target.global_position
			return game.crystal_world_position()
		game.ENEMY_TYPE_GOLEM:
			var major_module_room: Vector2i = preferred_golem_major_module_room(game, enemy)
			if major_module_room != game.INVALID_ROOM and major_module_room == enemy.current_room:
				return major_module_target_position(game, enemy.current_room)
			return game.crystal_world_position()
		game.ENEMY_TYPE_BAT:
			return game.crystal_world_position()
		_:
			return game.crystal_world_position()

static func enemy_attack_start_distance(game: Node, enemy: Variant) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 18.0
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_LIZARDMAN, game.ENEMY_TYPE_GOBLIN, game.ENEMY_TYPE_GOLEM, game.ENEMY_TYPE_BAT:
			return maxf(float(enemy.get("melee_reach")), 18.0)
		_:
			return 18.0

static func melee_attack_resolution_distance(game: Node, attacker: Variant, target: Variant) -> float:
	if attacker == null or target == null or not is_instance_valid(attacker) or not is_instance_valid(target):
		return 18.0
	var attacker_reach: float = 18.0
	if game.is_hero_actor(attacker):
		attacker_reach = float(attacker.attack_range)
	else:
		attacker_reach = float(attacker.get("melee_reach"))
	var target_reach: float = 0.0
	if game.is_enemy_actor(target):
		target_reach = float(target.get("melee_reach"))
	elif game.is_hero_actor(target) and String(target.preferred_attack_style) == "melee":
		target_reach = float(target.attack_range)
	return maxf(attacker_reach, target_reach) + 8.0

static func hero_room_for_enemy_targeting(game: Node, hero: Variant) -> Vector2i:
	if hero == null or not is_instance_valid(hero):
		return game.INVALID_ROOM
	if hero.pending_room != game.HERO_INVALID_ROOM and game.rooms.has(hero.pending_room) and game.room_rect(hero.pending_room).has_point(hero.global_position):
		return hero.pending_room
	return hero.current_room

static func hero_is_in_room(game: Node, hero: Variant, room_coord: Vector2i) -> bool:
	return hero_room_for_enemy_targeting(game, hero) == room_coord

static func hero_is_long_range_target(_game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	return String(hero.preferred_attack_style) != "melee" or float(hero.attack_range) > 120.0

static func hero_target_priority_rank(game: Node, hero: Variant) -> int:
	if hero == null or not is_instance_valid(hero):
		return 999
	if bool(hero.carrying_crystal):
		return 0
	if hero_is_long_range_target(game, hero):
		return 1
	return 2

static func orc_rider_target_priority_rank(game: Node, hero: Variant) -> int:
	if hero == null or not is_instance_valid(hero):
		return 999
	if bool(hero.carrying_crystal):
		return 0
	if hero_is_long_range_target(game, hero):
		return 1
	return 0

static func heroes_in_room(game: Node, room_coord: Vector2i) -> Array:
	var room_heroes: Array = []
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		if hero_is_in_room(game, hero, room_coord):
			room_heroes.append(hero)
	return room_heroes

static func default_room_hero_target(game: Node, room_coord: Vector2i, origin: Vector2) -> Variant:
	var chosen_hero: Variant = null
	var chosen_rank: int = 999
	var chosen_distance: float = INF
	for hero in heroes_in_room(game, room_coord):
		var priority_rank: int = hero_target_priority_rank(game, hero)
		var distance_value: float = origin.distance_to(hero.global_position)
		if chosen_hero == null \
		or priority_rank < chosen_rank \
		or (priority_rank == chosen_rank and distance_value < chosen_distance):
			chosen_hero = hero
			chosen_rank = priority_rank
			chosen_distance = distance_value
	return chosen_hero

static func enemy_room_hero_candidates(game: Node, enemy: Variant) -> Array:
	if enemy == null or not is_instance_valid(enemy):
		return []
	return heroes_in_room(game, Vector2i(enemy.current_room))

static func local_enemy_override_target(game: Node, enemy: Variant) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	var room_heroes: Array = enemy_room_hero_candidates(game, enemy)
	if room_heroes.is_empty():
		return null
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_LIZARDMAN:
			return orc_rider_target_hero(game, enemy)
		game.ENEMY_TYPE_SKELETON_ARCHER:
			return skeleton_archer_target_hero(game, enemy)
		game.ENEMY_TYPE_GOBLIN, game.ENEMY_TYPE_GOBLIN_SHAMAN:
			return goblin_target_hero(game, enemy)
		_:
			return default_room_hero_target(game, enemy.current_room, enemy.global_position)

static func priority_hunter_target_hero(game: Node, enemy: Variant) -> Variant:
	var room_heroes: Array = enemy_room_hero_candidates(game, enemy)
	if not room_heroes.is_empty():
		var local_choice: Variant = null
		var local_rank: int = 999
		var local_distance: float = INF
		for hero in room_heroes:
			var priority_rank: int = hero_target_priority_rank(game, hero)
			var distance_value: float = enemy.global_position.distance_to(hero.global_position)
			if local_choice == null \
			or priority_rank < local_rank \
			or (priority_rank == local_rank and distance_value < local_distance):
				local_choice = hero
				local_rank = priority_rank
				local_distance = distance_value
		return local_choice
	var chosen_hero: Variant = null
	var chosen_rank: int = 999
	var chosen_path_length: int = 99999
	var chosen_distance: float = INF
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		var candidate_room: Vector2i = hero_room_for_enemy_targeting(game, hero)
		if candidate_room == game.INVALID_ROOM:
			continue
		var path_length: int = game.room_path_distance(enemy.current_room, candidate_room)
		if path_length >= 99999:
			continue
		var priority_rank: int = hero_target_priority_rank(game, hero)
		var distance_value: float = enemy.global_position.distance_to(hero.global_position)
		if chosen_hero == null \
		or priority_rank < chosen_rank \
		or (priority_rank == chosen_rank and path_length < chosen_path_length) \
		or (priority_rank == chosen_rank and path_length == chosen_path_length and distance_value < chosen_distance):
			chosen_hero = hero
			chosen_rank = priority_rank
			chosen_path_length = path_length
			chosen_distance = distance_value
	return chosen_hero

static func orc_rider_target_hero(game: Node, enemy: Variant) -> Variant:
	var room_heroes: Array = enemy_room_hero_candidates(game, enemy)
	if not room_heroes.is_empty():
		var local_choice: Variant = null
		var local_rank: int = 999
		var local_distance: float = INF
		for hero in room_heroes:
			var priority_rank: int = orc_rider_target_priority_rank(game, hero)
			var distance_value: float = enemy.global_position.distance_to(hero.global_position)
			if local_choice == null \
			or priority_rank < local_rank \
			or (priority_rank == local_rank and distance_value < local_distance):
				local_choice = hero
				local_rank = priority_rank
				local_distance = distance_value
		return local_choice
	var chosen_hero: Variant = null
	var chosen_rank: int = 999
	var chosen_path_length: int = 99999
	var chosen_distance: float = INF
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		var candidate_room: Vector2i = hero_room_for_enemy_targeting(game, hero)
		if candidate_room == game.INVALID_ROOM:
			continue
		var path_length: int = game.room_path_distance(enemy.current_room, candidate_room)
		if path_length >= 99999:
			continue
		var priority_rank: int = orc_rider_target_priority_rank(game, hero)
		var distance_value: float = enemy.global_position.distance_to(hero.global_position)
		if chosen_hero == null \
		or priority_rank < chosen_rank \
		or (priority_rank == chosen_rank and path_length < chosen_path_length) \
		or (priority_rank == chosen_rank and path_length == chosen_path_length and distance_value < chosen_distance):
			chosen_hero = hero
			chosen_rank = priority_rank
			chosen_path_length = path_length
			chosen_distance = distance_value
	return chosen_hero

static func goblin_target_hero(game: Node, enemy: Variant) -> Variant:
	var room_heroes: Array = enemy_room_hero_candidates(game, enemy)
	if not room_heroes.is_empty():
		var local_choice: Variant = null
		var local_rank: int = 999
		var local_distance: float = INF
		for hero in room_heroes:
			var priority_rank: int = 1 if bool(hero.carrying_crystal) else 0
			var distance_value: float = enemy.global_position.distance_to(hero.global_position)
			if local_choice == null \
			or priority_rank < local_rank \
			or (priority_rank == local_rank and distance_value < local_distance):
				local_choice = hero
				local_rank = priority_rank
				local_distance = distance_value
		return local_choice
	var chosen_hero: Variant = null
	var chosen_rank: int = 999
	var chosen_path_length: int = 99999
	var chosen_distance: float = INF
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		var candidate_room: Vector2i = hero_room_for_enemy_targeting(game, hero)
		if candidate_room == game.INVALID_ROOM:
			continue
		var path_length: int = game.room_path_distance(enemy.current_room, candidate_room)
		if path_length >= 99999:
			continue
		var priority_rank: int = 1 if bool(hero.carrying_crystal) else 0
		var distance_value: float = enemy.global_position.distance_to(hero.global_position)
		if chosen_hero == null \
		or priority_rank < chosen_rank \
		or (priority_rank == chosen_rank and path_length < chosen_path_length) \
		or (priority_rank == chosen_rank and path_length == chosen_path_length and distance_value < chosen_distance):
			chosen_hero = hero
			chosen_rank = priority_rank
			chosen_path_length = path_length
			chosen_distance = distance_value
	return chosen_hero

static func bat_target_hero(game: Node, enemy: Variant) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	return default_room_hero_target(game, enemy.current_room, enemy.global_position)

static func golem_target_hero(game: Node, enemy: Variant) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	return default_room_hero_target(game, enemy.current_room, enemy.global_position)

static func enemy_situational_speed_multiplier(game: Node, enemy: Variant) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 1.0
	var room_coord: Vector2i = enemy.current_room
	var has_heroes: bool = room_coord != game.INVALID_ROOM and not heroes_in_room(game, room_coord).is_empty()
	var multiplier: float = 1.0
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_GOBLIN:
			multiplier = 0.72 if has_heroes else 1.0
		game.ENEMY_TYPE_BAT:
			multiplier = 0.58 if has_heroes else 1.0
		_:
			multiplier = 1.0
	if game.rooms.has(room_coord) and float(game.rooms[room_coord].get("neurostun_time_left", 0.0)) > 0.0:
		multiplier *= 0.58
	return multiplier

static func skeleton_archer_target_hero(game: Node, enemy: Variant) -> Variant:
	var room_heroes: Array = enemy_room_hero_candidates(game, enemy)
	if not room_heroes.is_empty():
		var room_has_ranged: bool = false
		for hero in room_heroes:
			if hero_is_long_range_target(game, hero):
				room_has_ranged = true
				break
		var local_choice: Variant = null
		var local_rank: int = 999
		var local_distance: float = INF
		for hero in room_heroes:
			var priority_rank: int = 2
			if bool(hero.carrying_crystal):
				priority_rank = 0
			elif room_has_ranged and hero_is_long_range_target(game, hero):
				priority_rank = 1
			elif not room_has_ranged:
				priority_rank = 1
			var distance_value: float = enemy.global_position.distance_to(hero.global_position)
			if local_choice == null \
			or priority_rank < local_rank \
			or (priority_rank == local_rank and distance_value < local_distance):
				local_choice = hero
				local_rank = priority_rank
				local_distance = distance_value
		return local_choice
	return priority_hunter_target_hero(game, enemy)

static func skeleton_archer_goal_position(game: Node, enemy: Variant) -> Vector2:
	var archer_target: Variant = skeleton_archer_target_hero(game, enemy)
	if archer_target == null or not hero_is_in_room(game, archer_target, enemy.current_room):
		return game.clamp_point_to_room(enemy.global_position, enemy.current_room)
	var desired_range: float = 182.0
	var separation: Vector2 = enemy.global_position - archer_target.global_position
	if separation.length() < desired_range:
		var fallback_direction: Vector2 = separation.normalized() if separation.length() > 0.001 else Vector2.LEFT
		return game.clamp_point_to_room(archer_target.global_position + fallback_direction * desired_range, enemy.current_room)
	return game.clamp_point_to_room(enemy.global_position, enemy.current_room)

static func module_target_position(game: Node, room_coord: Vector2i, origin: Vector2) -> Vector2:
	if not game.rooms.has(room_coord):
		return origin
	var room: Dictionary = game.rooms[room_coord]
	var candidates: Array[Vector2] = []
	if room["major_module_type"] != "" and float(room["major_health"]) > 0.0:
		candidates.append(game.major_slot_position(room_coord))
	var slot_positions: Array = game.minor_slot_positions(room_coord)
	for module_data in room["minor_modules"]:
		if float(module_data["health"]) <= 0.0:
			continue
		var slot_index: int = int(module_data.get("slot_index", -1))
		if slot_index < 0 or slot_index >= slot_positions.size():
			continue
		candidates.append(slot_positions[slot_index])
	if candidates.is_empty():
		return game.room_walkable_center(room_coord)
	var chosen_position: Vector2 = candidates[0]
	var closest_distance: float = origin.distance_to(chosen_position)
	for candidate in candidates:
		var distance: float = origin.distance_to(candidate)
		if distance < closest_distance:
			closest_distance = distance
			chosen_position = candidate
	return chosen_position

static func major_module_target_position(game: Node, room_coord: Vector2i) -> Vector2:
	if not game.rooms.has(room_coord):
		return game.room_walkable_center(room_coord)
	var room: Dictionary = game.rooms[room_coord]
	if String(room.get("major_module_type", "")) == "" or float(room.get("major_health", 0.0)) <= 0.0:
		return game.room_walkable_center(room_coord)
	return game.major_slot_position(room_coord)

static func preferred_golem_major_module_room(game: Node, enemy: Variant) -> Vector2i:
	var module_room: Vector2i = find_nearest_major_module_room(game, enemy.current_room)
	if module_room == game.INVALID_ROOM:
		return game.INVALID_ROOM
	var module_distance: int = game.room_path_distance(enemy.current_room, module_room)
	var crystal_distance: int = game.room_path_distance(enemy.current_room, game.crystal_room)
	if module_distance < crystal_distance:
		return module_room
	return game.INVALID_ROOM

static func resolve_enemy_attack(game: Node, enemy: Variant) -> void:
	if enemy.attack_cooldown_left > 0.0:
		return
	var local_target: Variant = local_enemy_override_target(game, enemy)
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_LIZARDMAN:
			var lizard_target: Variant = local_target if local_target != null else orc_rider_target_hero(game, enemy)
			if lizard_target == null or not hero_is_in_room(game, lizard_target, enemy.current_room):
				return
			enemy.trigger_attack(lizard_target.global_position)
			game.queue_pending_melee_attack(enemy, lizard_target, enemy.attack_damage, enemy.melee_impact_delay(), "An orc rider")
			game.status_message = "An orc rider lunges at %s." % lizard_target.hero_name
		game.ENEMY_TYPE_SKELETON_ARCHER:
			var archer_target: Variant = local_target if local_target != null else skeleton_archer_target_hero(game, enemy)
			if archer_target != null and hero_is_in_room(game, archer_target, enemy.current_room):
				enemy.trigger_attack(archer_target.global_position)
				game.spawn_laser_projectile(enemy.global_position, archer_target, enemy.attack_damage, Color("dbe5c8"), 3.2, 980.0)
				game.status_message = "A skeleton archer looses an arrow at %s." % archer_target.hero_name
			elif enemy.current_room == game.crystal_room:
				enemy.trigger_attack(game.room_center(game.crystal_room))
				game.crystal_health = maxf(game.crystal_health - enemy.attack_damage, 0.0)
				game.status_message = "Skeleton archers are peppering the crystal."
			else:
				return
		game.ENEMY_TYPE_GOBLIN:
			var goblin_target: Variant = local_target if local_target != null else goblin_target_hero(game, enemy)
			if goblin_target != null and hero_is_in_room(game, goblin_target, enemy.current_room):
				enemy.trigger_attack(goblin_target.global_position)
				game.queue_pending_melee_attack(enemy, goblin_target, enemy.attack_damage, enemy.melee_impact_delay(), "Orcs")
				game.status_message = "Orcs are swarming %s." % goblin_target.hero_name
			elif enemy.current_room == game.crystal_room:
				enemy.trigger_attack(game.room_center(game.crystal_room))
				game.crystal_health = maxf(game.crystal_health - enemy.attack_damage, 0.0)
				game.status_message = "Orcs are striking the crystal."
			else:
				return
		game.ENEMY_TYPE_BAT:
			if enemy.current_room == game.crystal_room:
				enemy.trigger_attack(game.room_center(game.crystal_room))
				game.crystal_health = maxf(game.crystal_health - enemy.attack_damage, 0.0)
				game.status_message = "Bats dive at the crystal."
			else:
				return
		game.ENEMY_TYPE_GOLEM:
			if local_target != null and hero_is_in_room(game, local_target, enemy.current_room):
				enemy.trigger_attack(local_target.global_position)
				game.queue_pending_melee_attack(enemy, local_target, enemy.attack_damage, enemy.melee_impact_delay(), "A golem")
				game.status_message = "A golem hammers %s." % local_target.hero_name
			else:
				var target_major_room: Vector2i = preferred_golem_major_module_room(game, enemy)
				if target_major_room != game.INVALID_ROOM and target_major_room == enemy.current_room:
					enemy.trigger_attack(game.room_center(enemy.current_room))
					if not damage_module(game, enemy.current_room, enemy.attack_damage, true, "A golem"):
						return
				elif enemy.current_room == game.crystal_room:
					enemy.trigger_attack(game.room_center(game.crystal_room))
					game.crystal_health = maxf(game.crystal_health - enemy.attack_damage, 0.0)
					game.status_message = "A golem is pounding the crystal."
				else:
					return
		game.ENEMY_TYPE_GOBLIN_SHAMAN:
			var room_targets: Array = heroes_in_room(game, enemy.current_room)
			if not room_targets.is_empty():
				var blast_target: Variant = local_target if local_target != null else goblin_target_hero(game, enemy)
				var blast_position: Vector2 = blast_target.global_position if blast_target != null else game.room_walkable_center(enemy.current_room)
				enemy.trigger_attack(blast_position)
				var defeated_heroes: Array[String] = game.explode_enemy_fireball(enemy.current_room, blast_position, enemy.attack_damage, 68.0, 360.0, "An orc shaman")
				if defeated_heroes.is_empty():
					game.status_message = "An orc shaman hurls a mini fireball."
				elif defeated_heroes.size() == 1:
					game.status_message = "An orc shaman burned down %s." % defeated_heroes[0]
				else:
					game.status_message = "An orc shaman burned down multiple heroes."
			elif enemy.current_room == game.crystal_room:
				enemy.trigger_attack(game.room_center(game.crystal_room))
				game.crystal_health = maxf(game.crystal_health - enemy.attack_damage, 0.0)
				game.status_message = "Orc shamans are scorching the crystal."
			else:
				return
		_:
			if enemy.current_room != game.crystal_room:
				return
			enemy.trigger_attack(game.room_center(game.crystal_room))
			game.crystal_health = maxf(game.crystal_health - enemy.attack_damage, 0.0)
			game.status_message = "Enemies are striking the crystal."
	enemy.attack_cooldown_left = enemy.attack_cooldown
	game.update_hud()

static func find_nearest_major_module_room(game: Node, from_room: Vector2i) -> Vector2i:
	var closest_room: Vector2i = game.INVALID_ROOM
	var closest_path_length: int = 9999
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if room_coord == game.crystal_room or not room["opened"]:
			continue
		if String(room.get("major_module_type", "")) == "" or float(room.get("major_health", 0.0)) <= 0.0:
			continue
		var path: Array[Vector2i] = game.find_path(from_room, room_coord, true)
		if path.is_empty():
			continue
		if path.size() < closest_path_length:
			closest_path_length = path.size()
			closest_room = room_coord
	return closest_room

static func damage_module(game: Node, room_coord: Vector2i, amount: float, major_only: bool = false, attacker_label: String = "Enemies") -> bool:
	if not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	var module_count: int = room["minor_modules"].size()
	var can_hit_major: bool = room["major_module_type"] != "" and float(room["major_health"]) > 0.0
	if (major_only and not can_hit_major) or (module_count == 0 and not can_hit_major):
		return false
	var attack_major: bool = can_hit_major and (major_only or module_count == 0 or game.rng.randf() < 0.45)
	if attack_major:
		room["major_health"] = maxf(float(room["major_health"]) - amount, 0.0)
		if float(room["major_health"]) <= 0.0:
			game.status_message = "%s destroyed the major module in %s." % [attacker_label, game.room_title(room_coord)]
			room["major_module_type"] = ""
			room["major_under_construction"] = false
			game.cancel_pending_major_construction(room_coord)
		else:
			game.status_message = "%s is damaging the major module in %s." % [attacker_label, game.room_title(room_coord)]
		return true
	if major_only:
		return false
	var module_index: int = game.rng.randi_range(0, module_count - 1)
	var module_data: Dictionary = Dictionary(room["minor_modules"][module_index])
	module_data["health"] = maxf(float(module_data["health"]) - amount, 0.0)
	if float(module_data["health"]) <= 0.0:
		game.cancel_pending_minor_construction(room_coord, int(module_data.get("slot_index", -1)))
		room["minor_modules"].remove_at(module_index)
		game.status_message = "%s destroyed a turret in %s." % [attacker_label, game.room_title(room_coord)]
	else:
		room["minor_modules"][module_index] = module_data
		game.status_message = "%s is damaging a turret in %s." % [attacker_label, game.room_title(room_coord)]
	return true
