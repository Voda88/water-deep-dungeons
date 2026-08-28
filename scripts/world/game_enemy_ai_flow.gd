extends RefCounted

const GAME_ENEMY_TARGET_PRIORITY_DEFS: GDScript = preload("res://scripts/content/game_enemy_target_priority_defs.gd")
const GAME_ENEMY_DEFS: GDScript = preload("res://scripts/content/game_enemy_defs.gd")

const ROOM_TARGET_LOCK_ACTOR_KEY_META: StringName = &"room_target_lock_actor_key"
const ROOM_TARGET_LOCK_ROOM_META: StringName = &"room_target_lock_room"
const ROOM_TARGET_LOCK_ROOM_TARGETS_META: StringName = &"room_target_lock_room_targets"
const ENEMY_AI_THINK_TIMER_META: StringName = &"enemy_ai_think_timer_left"
const CONVERTED_TARGET_LOCK_ENEMY_UID_META: StringName = &"converted_target_lock_enemy_uid"
const PRIORITY_TARGET_CACHE_FRAME_META: StringName = &"priority_target_cache_frame"
const PRIORITY_TARGET_CACHE_ACTOR_META: StringName = &"priority_target_cache_actor"
const FEAR_FLEE_DISTANCE: float = 240.0
const TARGET_CATEGORY_RANGED: String = "ranged_target"
const TARGET_CATEGORY_MELEE: String = "melee_target"
const TARGET_CATEGORY_RESEARCH_CRYSTAL: String = "research_crystal"
const TARGET_CATEGORY_MAJOR_MODULE: String = "major_module"
const TARGET_CATEGORY_MINOR_MODULE: String = "minor_module"
const TARGET_CATEGORY_GENERATOR_CRYSTAL: String = "generator_crystal"
const TARGETABLE_ACTOR_CACHE_FRAME_META: StringName = &"enemy_targetable_actor_cache_frame"
const TARGETABLE_ACTOR_CACHE_VALUE_META: StringName = &"enemy_targetable_actor_cache_value"
const ROOM_TARGETABLE_CACHE_FRAME_META: StringName = &"enemy_room_targetable_cache_frame"
const ROOM_TARGETABLE_CACHE_VALUE_META: StringName = &"enemy_room_targetable_cache_value"
const ROOM_PATH_DISTANCE_CACHE_FRAME_META: StringName = &"enemy_room_path_distance_cache_frame"
const ROOM_PATH_DISTANCE_CACHE_VALUE_META: StringName = &"enemy_room_path_distance_cache_value"
const ENEMY_SOFT_SEPARATION_CELL_SIZE: float = 72.0
const ENEMY_SOFT_SEPARATION_SPRITE_RADIUS_BASE: float = 50.0
const ENEMY_SOFT_SEPARATION_SPRITE_RADIUS_FACTOR: float = 0.75
const ENEMY_SOFT_SEPARATION_MIN_RADIUS: float = 18.0
const ENEMY_SOFT_SEPARATION_MAX_RADIUS: float = 96.0
const ENEMY_SOFT_SEPARATION_STRENGTH: float = 16.0
const ENEMY_SOFT_SEPARATION_MAX_OFFSET: float = 20.0
const ENEMY_SOFT_SEPARATION_MAX_NEIGHBORS: int = 8

static func room_target_cache_key(room_coord: Vector2i, strict: bool) -> String:
	return "%d:%d:%d" % [room_coord.x, room_coord.y, 1 if strict else 0]

static func room_path_distance_cached(game: Node, from_room: Vector2i, to_room: Vector2i) -> int:
	if from_room == to_room:
		return 0
	var physics_frame: int = Engine.get_physics_frames()
	var cache_frame: int = int(game.get_meta(ROOM_PATH_DISTANCE_CACHE_FRAME_META, -1))
	var cache: Dictionary = {}
	if cache_frame == physics_frame:
		cache = game.get_meta(ROOM_PATH_DISTANCE_CACHE_VALUE_META, {})
	else:
		game.set_meta(ROOM_PATH_DISTANCE_CACHE_FRAME_META, physics_frame)
	var cache_key: String = "%d:%d|%d:%d" % [from_room.x, from_room.y, to_room.x, to_room.y]
	if cache.has(cache_key):
		return int(cache[cache_key])
	var distance_value: int = int(game.room_path_distance(from_room, to_room))
	cache[cache_key] = distance_value
	game.set_meta(ROOM_PATH_DISTANCE_CACHE_VALUE_META, cache)
	return distance_value

static func targetable_room_actors_cached(game: Node, room_coord: Vector2i, strict: bool) -> Array:
	if room_coord == game.INVALID_ROOM:
		return []
	var physics_frame: int = Engine.get_physics_frames()
	var cache_frame: int = int(game.get_meta(ROOM_TARGETABLE_CACHE_FRAME_META, -1))
	var cache: Dictionary = {}
	if cache_frame == physics_frame:
		cache = game.get_meta(ROOM_TARGETABLE_CACHE_VALUE_META, {})
	else:
		game.set_meta(ROOM_TARGETABLE_CACHE_FRAME_META, physics_frame)
	var cache_key: String = room_target_cache_key(room_coord, strict)
	if cache.has(cache_key):
		return cache[cache_key]
	var room_actors: Array = []
	var room_heroes: Array = heroes_in_room_strict(game, room_coord) if strict else heroes_in_room(game, room_coord)
	for hero in room_heroes:
		if hero_is_enemy_targetable(game, hero):
			room_actors.append(hero)
	for summon in game.enemies:
		if not enemy_summon_is_enemy_targetable(game, summon):
			continue
		if strict:
			if Vector2i(summon.current_room) != room_coord:
				continue
		elif not hero_is_in_room(game, summon, room_coord):
			continue
		room_actors.append(summon)
	cache[cache_key] = room_actors
	game.set_meta(ROOM_TARGETABLE_CACHE_VALUE_META, cache)
	return room_actors

static func adaptive_enemy_ai_think_interval(game: Node, _active_enemy_count: int) -> float:
	return float(game.ENEMY_AI_THINK_INTERVAL)

static func deterministic_ai_budget_defer(enemy: Variant, defer_min: float, defer_max: float) -> float:
	if defer_max <= defer_min:
		return defer_min
	var uid_value: int = abs(int(enemy.enemy_uid))
	var bucket_count: int = 7
	var bucket_index: int = uid_value % bucket_count
	var ratio: float = float(bucket_index) / float(bucket_count - 1)
	return lerpf(defer_min, defer_max, ratio)

static func enemy_spatial_room_cell_key(room_coord: Vector2i, cell_coord: Vector2i) -> String:
	return "%d:%d|%d:%d" % [room_coord.x, room_coord.y, cell_coord.x, cell_coord.y]

static func enemy_spatial_cell_coord(position: Vector2, cell_size: float) -> Vector2i:
	var safe_size: float = maxf(cell_size, 1.0)
	return Vector2i(floori(position.x / safe_size), floori(position.y / safe_size))

static func build_enemy_spatial_hash(active_enemies: Array, cell_size: float) -> Dictionary:
	var hash: Dictionary = {}
	for enemy in active_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if bool(enemy.get("throw_active")):
			continue
		var room_coord: Vector2i = Vector2i(enemy.current_room)
		var cell_coord: Vector2i = enemy_spatial_cell_coord(enemy.global_position, cell_size)
		var hash_key: String = enemy_spatial_room_cell_key(room_coord, cell_coord)
		var bucket: Array = hash.get(hash_key, [])
		bucket.append(enemy)
		hash[hash_key] = bucket
	return hash

static func separation_direction_from_overlap(enemy: Variant, neighbor: Variant) -> Vector2:
	var uid_delta: int = int(enemy.enemy_uid) - int(neighbor.enemy_uid)
	var angle: float = float(abs(uid_delta % 32)) * (TAU / 32.0)
	if uid_delta < 0:
		angle += PI
	return Vector2.RIGHT.rotated(angle)

static func enemy_soft_separation_radius(enemy: Variant) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return ENEMY_SOFT_SEPARATION_MIN_RADIUS
	var role_scale: float = 1.0
	if enemy.has_method("role_scale"):
		role_scale = maxf(float(enemy.call("role_scale")), 0.2)
	var sprite_radius: float = ENEMY_SOFT_SEPARATION_SPRITE_RADIUS_BASE * role_scale
	return clampf(sprite_radius * ENEMY_SOFT_SEPARATION_SPRITE_RADIUS_FACTOR, ENEMY_SOFT_SEPARATION_MIN_RADIUS, ENEMY_SOFT_SEPARATION_MAX_RADIUS)

static func enemy_soft_separation_offset(game: Node, enemy: Variant, spatial_hash: Dictionary) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return Vector2.ZERO
	if not game.enemy_is_active(enemy):
		return Vector2.ZERO
	if bool(enemy.get("throw_active")):
		return Vector2.ZERO
	var room_coord: Vector2i = Vector2i(enemy.current_room)
	var source_position: Vector2 = enemy.global_position
	var source_cell: Vector2i = enemy_spatial_cell_coord(source_position, ENEMY_SOFT_SEPARATION_CELL_SIZE)
	var accumulated_push: Vector2 = Vector2.ZERO
	var considered_neighbors: int = 0
	var separation_radius: float = enemy_soft_separation_radius(enemy)
	var max_distance_sq: float = separation_radius * separation_radius
	for y_offset in range(-1, 2):
		for x_offset in range(-1, 2):
			if considered_neighbors >= ENEMY_SOFT_SEPARATION_MAX_NEIGHBORS:
				break
			var neighbor_cell: Vector2i = source_cell + Vector2i(x_offset, y_offset)
			var hash_key: String = enemy_spatial_room_cell_key(room_coord, neighbor_cell)
			if not spatial_hash.has(hash_key):
				continue
			var bucket: Array = spatial_hash[hash_key]
			for neighbor in bucket:
				if considered_neighbors >= ENEMY_SOFT_SEPARATION_MAX_NEIGHBORS:
					break
				if neighbor == null or not is_instance_valid(neighbor) or neighbor == enemy:
					continue
				if bool(neighbor.get("throw_active")):
					continue
				if Vector2i(neighbor.current_room) != room_coord:
					continue
				var delta: Vector2 = source_position - neighbor.global_position
				var distance_sq: float = delta.length_squared()
				if distance_sq > max_distance_sq:
					continue
				var direction: Vector2 = Vector2.ZERO
				var normalized_distance: float = 1.0
				if distance_sq <= 0.0001:
					direction = separation_direction_from_overlap(enemy, neighbor)
					normalized_distance = 0.0
				else:
					var distance_value: float = sqrt(distance_sq)
					direction = delta / maxf(distance_value, 0.001)
					normalized_distance = clampf(distance_value / separation_radius, 0.0, 1.0)
				var influence: float = 1.0 - normalized_distance
				accumulated_push += direction * influence
				considered_neighbors += 1
		if considered_neighbors >= ENEMY_SOFT_SEPARATION_MAX_NEIGHBORS:
			break
	if accumulated_push == Vector2.ZERO:
		return Vector2.ZERO
	var push_offset: Vector2 = accumulated_push.normalized() * minf(accumulated_push.length() * ENEMY_SOFT_SEPARATION_STRENGTH, ENEMY_SOFT_SEPARATION_MAX_OFFSET)
	return push_offset

static func room_has_active_major_module(game: Node, room_coord: Vector2i) -> bool:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	return String(room.get("major_module_type", "")) != "" and float(room.get("major_health", 0.0)) > 0.0

static func enemy_is_converted(enemy: Variant) -> bool:
	if enemy == null or not is_instance_valid(enemy) or not enemy.has_method("is_converted"):
		return false
	return bool(enemy.is_converted())

static func enemy_is_feared(enemy: Variant) -> bool:
	if enemy == null or not is_instance_valid(enemy) or not enemy.has_method("is_feared"):
		return false
	return bool(enemy.is_feared())

static func enemy_is_calm_neutralized(enemy: Variant) -> bool:
	if enemy == null or not is_instance_valid(enemy) or not enemy.has_method("is_calm_emotions_neutralized"):
		return false
	return bool(enemy.is_calm_emotions_neutralized())

static func feared_enemy_target_position(game: Node, enemy: Variant) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return Vector2.ZERO
	var fear_origin: Vector2 = enemy.global_position
	if enemy.has_method("fear_origin_position"):
		fear_origin = Vector2(enemy.fear_origin_position())
	var flee_direction: Vector2 = (enemy.global_position - fear_origin).normalized()
	if flee_direction == Vector2.ZERO:
		flee_direction = Vector2.RIGHT.rotated(float(enemy.enemy_uid % 16) * (TAU / 16.0))
	var flee_target: Vector2 = enemy.global_position + flee_direction * FEAR_FLEE_DISTANCE
	return game.clamp_point_to_room(flee_target, Vector2i(enemy.current_room))

static func nearest_hostile_enemy_for_converted(game: Node, converted_enemy: Variant) -> Variant:
	if converted_enemy == null or not is_instance_valid(converted_enemy):
		return null
	var best_target: Variant = null
	var best_distance: float = INF
	for enemy in game.enemies:
		if not hostile_enemy_candidate_for_converted(game, converted_enemy, enemy):
			continue
		var distance_value: float = converted_enemy.global_position.distance_to(enemy.global_position)
		if best_target == null or distance_value < best_distance:
			best_target = enemy
			best_distance = distance_value
	return best_target

static func hostile_enemy_candidate_for_converted(game: Node, converted_enemy: Variant, enemy: Variant) -> bool:
	if enemy == converted_enemy:
		return false
	if not game.enemy_is_active(enemy):
		return false
	if enemy_is_converted(enemy):
		return false
	if Vector2i(enemy.current_room) != Vector2i(converted_enemy.current_room):
		return false
	if bool(enemy.moving_between_rooms):
		return false
	return true

static func apply_hero_enemy_auras(game: Node, active_enemies: Array) -> void:
	for enemy in active_enemies:
		if enemy_is_converted(enemy) or String(enemy.enemy_role) != GAME_ENEMY_DEFS.TYPE_WARLOCK:
			continue
		var warlock_def: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(enemy.enemy_role)
		var aura_radius: float = maxf(float(warlock_def.get("hero_aura_radius", 0.0)), 0.0)
		if aura_radius <= 0.0:
			continue
		for hero in game.heroes:
			if not game.hero_is_active(hero) or not hero.has_method("apply_enemy_aura"):
				continue
			if Vector2i(hero.current_room) != Vector2i(enemy.current_room) or hero.global_position.distance_to(enemy.global_position) > aura_radius:
				continue
			hero.apply_enemy_aura(float(warlock_def.get("hero_aura_attack_damage_multiplier", 1.0)), 0.5)

static func apply_enemy_defensive_auras(game: Node, active_enemies: Array) -> void:
	for ally in active_enemies:
		if ally.has_method("clear_allied_defence_aura"):
			ally.clear_allied_defence_aura()
	for enemy in active_enemies:
		if enemy_is_converted(enemy) or String(enemy.enemy_role) != game.ENEMY_TYPE_DEATH_KNIGHT:
			continue
		if enemy.has_method("has_active_status_effect") and bool(enemy.has_active_status_effect()):
			continue
		var death_knight_def: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(enemy.enemy_role)
		var aura_radius: float = maxf(float(death_knight_def.get("ally_aura_radius", 0.0)), 0.0)
		if aura_radius <= 0.0:
			continue
		var damage_taken_multiplier: float = float(death_knight_def.get("ally_aura_damage_taken_multiplier", 1.0))
		for ally in active_enemies:
			if ally == enemy or enemy_is_converted(ally):
				continue
			if Vector2i(ally.current_room) != Vector2i(enemy.current_room) or ally.global_position.distance_to(enemy.global_position) > aura_radius:
				continue
			if ally.has_method("apply_allied_defence_aura"):
				ally.apply_allied_defence_aura(damage_taken_multiplier)

static func strongest_hostile_enemy_for_converted(game: Node, converted_enemy: Variant) -> Variant:
	if converted_enemy == null or not is_instance_valid(converted_enemy):
		return null
	var best_target: Variant = null
	var best_max_health: float = -INF
	var best_health: float = -INF
	var best_distance: float = INF
	for enemy in game.enemies:
		if not hostile_enemy_candidate_for_converted(game, converted_enemy, enemy):
			continue
		var enemy_max_health: float = float(enemy.get("max_health"))
		var enemy_health: float = float(enemy.get("current_health"))
		var distance_value: float = converted_enemy.global_position.distance_to(enemy.global_position)
		if best_target == null \
		or enemy_max_health > best_max_health \
		or (is_equal_approx(enemy_max_health, best_max_health) and enemy_health > best_health) \
		or (is_equal_approx(enemy_max_health, best_max_health) and is_equal_approx(enemy_health, best_health) and distance_value < best_distance):
			best_target = enemy
			best_max_health = enemy_max_health
			best_health = enemy_health
			best_distance = distance_value
	return best_target

static func locked_hostile_enemy_for_converted(game: Node, converted_enemy: Variant) -> Variant:
	if converted_enemy == null or not is_instance_valid(converted_enemy):
		return null
	if not converted_enemy.has_meta(CONVERTED_TARGET_LOCK_ENEMY_UID_META):
		return null
	var locked_enemy_uid: int = int(converted_enemy.get_meta(CONVERTED_TARGET_LOCK_ENEMY_UID_META, -1))
	if locked_enemy_uid < 0:
		converted_enemy.remove_meta(CONVERTED_TARGET_LOCK_ENEMY_UID_META)
		return null
	var locked_enemy: Variant = game.find_enemy_by_uid(locked_enemy_uid)
	if locked_enemy == null or not hostile_enemy_candidate_for_converted(game, converted_enemy, locked_enemy):
		converted_enemy.remove_meta(CONVERTED_TARGET_LOCK_ENEMY_UID_META)
		return null
	return locked_enemy

static func set_locked_hostile_enemy_for_converted(converted_enemy: Variant, target_enemy: Variant) -> void:
	if converted_enemy == null or not is_instance_valid(converted_enemy):
		return
	if target_enemy == null or not is_instance_valid(target_enemy):
		if converted_enemy.has_meta(CONVERTED_TARGET_LOCK_ENEMY_UID_META):
			converted_enemy.remove_meta(CONVERTED_TARGET_LOCK_ENEMY_UID_META)
		return
	converted_enemy.set_meta(CONVERTED_TARGET_LOCK_ENEMY_UID_META, int(target_enemy.enemy_uid))

static func converted_enemy_is_familiar(converted_enemy: Variant) -> bool:
	if converted_enemy == null or not is_instance_valid(converted_enemy):
		return false
	var summon_card_id: String = String(converted_enemy.get_meta("summon_card_id", ""))
	if summon_card_id == "find_familiar_card":
		return true
	var summon_behavior: String = String(converted_enemy.get_meta("summon_behavior", ""))
	return summon_behavior == "familiar_strongest" and summon_card_id != "spiritual_weapon_card"

static func converted_enemy_anchor_position(converted_enemy: Variant) -> Vector2:
	if converted_enemy == null or not is_instance_valid(converted_enemy):
		return Vector2.ZERO
	if converted_enemy.has_meta("summon_anchor_position"):
		return Vector2(converted_enemy.get_meta("summon_anchor_position", converted_enemy.global_position))
	return converted_enemy.global_position

static func converted_enemy_target(game: Node, converted_enemy: Variant) -> Variant:
	if converted_enemy == null or not is_instance_valid(converted_enemy):
		return null
	if converted_enemy_is_familiar(converted_enemy):
		var locked_enemy: Variant = locked_hostile_enemy_for_converted(game, converted_enemy)
		if locked_enemy != null:
			return locked_enemy
		var strongest_enemy: Variant = strongest_hostile_enemy_for_converted(game, converted_enemy)
		set_locked_hostile_enemy_for_converted(converted_enemy, strongest_enemy)
		return strongest_enemy
	set_locked_hostile_enemy_for_converted(converted_enemy, null)
	return nearest_hostile_enemy_for_converted(game, converted_enemy)

static func advance_enemy_routes(game: Node, delta: float) -> void:
	var active_enemies: Array = []
	for enemy_variant in game.enemies:
		if game.enemy_is_active(enemy_variant):
			active_enemies.append(enemy_variant)
	apply_hero_enemy_auras(game, active_enemies)
	apply_enemy_defensive_auras(game, active_enemies)
	var enemy_spatial_hash: Dictionary = {}
	if active_enemies.size() > 1:
		enemy_spatial_hash = build_enemy_spatial_hash(active_enemies, ENEMY_SOFT_SEPARATION_CELL_SIZE)
	var think_interval: float = adaptive_enemy_ai_think_interval(game, active_enemies.size())
	var pathfind_budget: int = maxi(1, int(game.ENEMY_AI_PATHFIND_PER_TICK_BUDGET))
	var defer_min: float = maxf(float(game.ENEMY_AI_BUDGET_DEFER_MIN), 0.0)
	var defer_max: float = maxf(float(game.ENEMY_AI_BUDGET_DEFER_MAX), defer_min)
	for enemy in active_enemies:
		if enemy.has_method("set_situational_speed_multiplier"):
			enemy.set_situational_speed_multiplier(enemy_situational_speed_multiplier(game, enemy))
		var cooldown_tick_scale: float = 1.0
		if enemy.has_method("attack_cooldown_tick_scale"):
			cooldown_tick_scale = maxf(float(enemy.attack_cooldown_tick_scale()), 0.0)
		enemy.attack_cooldown_left = maxf(enemy.attack_cooldown_left - delta * cooldown_tick_scale, 0.0)
		if enemy_is_calm_neutralized(enemy):
			enemy.move_steps.clear()
			enemy.pending_room = game.INVALID_ROOM
			enemy.next_room = enemy.current_room
			enemy.moving_between_rooms = false
			enemy.set_destination(enemy.global_position)
			continue
		if enemy.pending_room != game.INVALID_ROOM:
			if enemy.is_idle():
				enemy.moving_between_rooms = false
				enemy.previous_room = enemy.current_room
				enemy.current_room = enemy.pending_room
				enemy.pending_room = game.INVALID_ROOM
				enemy.next_room = enemy.current_room
				# Rebuild route from the new room side to avoid doorway backstep jitter.
				enemy.move_steps.clear()
			else:
				continue
		if think_interval > 0.0:
			if not enemy.has_meta(ENEMY_AI_THINK_TIMER_META):
				enemy.set_meta(ENEMY_AI_THINK_TIMER_META, game.rng.randf() * think_interval)
			var think_timer_left: float = maxf(float(enemy.get_meta(ENEMY_AI_THINK_TIMER_META, 0.0)) - delta, 0.0)
			var urgent_attack_check: bool = enemy.is_idle() and enemy.attack_cooldown_left <= 0.0
			if think_timer_left > 0.0 and not urgent_attack_check:
				enemy.set_meta(ENEMY_AI_THINK_TIMER_META, think_timer_left)
				continue
			enemy.set_meta(ENEMY_AI_THINK_TIMER_META, think_interval)
		elif enemy.has_meta(ENEMY_AI_THINK_TIMER_META):
			enemy.remove_meta(ENEMY_AI_THINK_TIMER_META)
		var target_room: Vector2i = target_room_for_enemy(game, enemy)
		if target_room == game.INVALID_ROOM:
			enemy.move_steps.clear()
			continue
		var enemy_idle: bool = enemy.is_idle()
		if not enemy_idle and enemy.current_room != target_room:
			continue
		# Keep movement target anchored to the chosen room so doorway transitions
		# cannot temporarily pull enemies back across a threshold.
		var target_position: Vector2 = game.clamp_point_to_room(enemy_target_position(game, enemy), target_room)
		if not enemy_spatial_hash.is_empty() and target_room == Vector2i(enemy.current_room) and not bool(enemy.get("throw_active")):
			target_position = game.clamp_point_to_room(target_position + enemy_soft_separation_offset(game, enemy, enemy_spatial_hash), target_room)
		var attack_start_distance: float = enemy_attack_start_distance(game, enemy)
		if not enemy_idle:
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
				var target_room_path: Array[Vector2i] = [target_room]
				game.issue_enemy_steps(enemy, game.build_steps_for_path(target_room_path, enemy.global_position, target_position))
			else:
				if pathfind_budget <= 0:
					enemy.set_meta(ENEMY_AI_THINK_TIMER_META, deterministic_ai_budget_defer(enemy, defer_min, defer_max))
					continue
				var path: Array[Vector2i] = game.find_path(enemy.current_room, target_room, true)
				pathfind_budget -= 1
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
	if enemy_is_converted(enemy):
		return Vector2i(enemy.current_room) if converted_enemy_target(game, enemy) != null else game.INVALID_ROOM
	if enemy_is_feared(enemy):
		return Vector2i(enemy.current_room)
	if String(enemy.enemy_role) == game.ENEMY_TYPE_SLIME:
		var slime_room: Vector2i = Vector2i(enemy.current_room)
		if not enemy_targetable_heroes_in_room_strict(game, slime_room).is_empty():
			return slime_room
		if should_target_active_minor_module(game, enemy):
			return slime_room
		var minor_module_room: Vector2i = find_nearest_minor_module_room(game, slime_room)
		if minor_module_room != game.INVALID_ROOM:
			return minor_module_room
		var slime_hero_target: Variant = priority_target_hero(game, enemy)
		return hero_room_for_enemy_targeting(game, slime_hero_target) if slime_hero_target != null else game.INVALID_ROOM
	var local_target: Variant = local_enemy_override_target(game, enemy)
	var role_target: Variant = priority_target_hero(game, enemy)
	if local_target != null:
		return hero_room_for_enemy_targeting(game, local_target)
	if should_target_active_major_module(game, enemy):
		return Vector2i(enemy.current_room)
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_ORC_RIDER, game.ENEMY_TYPE_DEATH_KNIGHT:
			if role_target == null:
				return game.crystal_room
			return hero_room_for_enemy_targeting(game, role_target)
		game.ENEMY_TYPE_SKELETON_ARCHER:
			if role_target == null:
				return game.crystal_room
			return hero_room_for_enemy_targeting(game, role_target)
		game.ENEMY_TYPE_ORC:
			if enemy.current_room == game.crystal_room and enemy_targetable_heroes_in_room_strict(game, Vector2i(enemy.current_room)).is_empty():
				return game.crystal_room
			if role_target != null:
				return hero_room_for_enemy_targeting(game, role_target)
			return game.crystal_room
		game.ENEMY_TYPE_WRAITH:
			if enemy.current_room == game.crystal_room and enemy_targetable_heroes_in_room_strict(game, Vector2i(enemy.current_room)).is_empty():
				return game.crystal_room
			if role_target != null:
				return hero_room_for_enemy_targeting(game, role_target)
			return game.crystal_room
		game.ENEMY_TYPE_GOLEM:
			return golem_objective_room(game, enemy)
		game.ENEMY_TYPE_DEMON_D:
			return power_crystal_target_room(game)
		game.ENEMY_TYPE_BAT:
			return power_crystal_target_room(game)
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
	if enemy_is_converted(enemy):
		if converted_enemy_is_familiar(enemy):
			return converted_enemy_anchor_position(enemy)
		var converted_target: Variant = converted_enemy_target(game, enemy)
		if converted_target != null:
			return converted_target.global_position
		return game.clamp_point_to_room(enemy.global_position, enemy.current_room)
	if enemy_is_feared(enemy):
		return feared_enemy_target_position(game, enemy)
	if String(enemy.enemy_role) == game.ENEMY_TYPE_SLIME:
		var slime_hero_target: Variant = priority_target_hero(game, enemy)
		if slime_hero_target != null and hero_is_in_room(game, slime_hero_target, enemy.current_room):
			return slime_hero_target.global_position
		if should_target_active_minor_module(game, enemy):
			return minor_module_target_position(game, Vector2i(enemy.current_room), enemy.global_position)
		return game.clamp_point_to_room(enemy.global_position, enemy.current_room)
	var local_target: Variant = local_enemy_override_target(game, enemy)
	var role_target: Variant = priority_target_hero(game, enemy)
	if local_target != null:
		if String(enemy.enemy_role) == game.ENEMY_TYPE_SKELETON_ARCHER or String(enemy.enemy_role) == game.ENEMY_TYPE_WRAITH:
			return skeleton_archer_goal_position(game, enemy)
		return local_target.global_position
	if should_target_active_major_module(game, enemy):
		return major_module_target_position(game, Vector2i(enemy.current_room))
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_ORC_RIDER:
			if role_target != null:
				return role_target.global_position
			return game.clamp_point_to_room(enemy.global_position, enemy.current_room)
		game.ENEMY_TYPE_SKELETON_ARCHER:
			if role_target != null:
				if hero_is_in_room(game, role_target, enemy.current_room):
					return skeleton_archer_goal_position(game, enemy)
				return role_target.global_position
			return game.crystal_world_position()
		game.ENEMY_TYPE_ORC:
			if enemy.current_room == game.crystal_room and enemy_targetable_heroes_in_room_strict(game, Vector2i(enemy.current_room)).is_empty():
				return game.crystal_world_position()
			if role_target != null:
				return role_target.global_position
			return game.crystal_world_position()
		game.ENEMY_TYPE_WRAITH:
			if enemy.current_room == game.crystal_room and enemy_targetable_heroes_in_room_strict(game, Vector2i(enemy.current_room)).is_empty():
				return game.crystal_world_position()
			if role_target != null:
				if hero_is_in_room(game, role_target, enemy.current_room):
					return game.clamp_point_to_room(enemy.global_position, enemy.current_room)
				return role_target.global_position
			return game.crystal_world_position()
		game.ENEMY_TYPE_GOLEM:
			return golem_objective_position(game, enemy)
		game.ENEMY_TYPE_DEMON_D:
			return power_crystal_target_position(game)
		game.ENEMY_TYPE_BAT:
			return power_crystal_target_position(game)
		_:
			return game.crystal_world_position()

static func enemy_attack_start_distance(game: Node, enemy: Variant) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 18.0
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_ORC_RIDER, game.ENEMY_TYPE_DEATH_KNIGHT, game.ENEMY_TYPE_ORC, game.ENEMY_TYPE_GOLEM, game.ENEMY_TYPE_BAT, game.ENEMY_TYPE_DEMON_A, game.ENEMY_TYPE_DEMON_D, game.ENEMY_TYPE_SKELETON, game.ENEMY_TYPE_SKELETON_ARMORED, game.ENEMY_TYPE_SKELETON_GREATSWORD, game.ENEMY_TYPE_SPIRITUAL_WEAPON, game.ENEMY_TYPE_SLIME:
			return maxf(float(enemy.get("attack_range")), 18.0)
		_:
			return 18.0

static func melee_attack_resolution_distance(game: Node, attacker: Variant, target: Variant) -> float:
	if attacker == null or target == null or not is_instance_valid(attacker) or not is_instance_valid(target):
		return 18.0
	var attacker_reach: float = 18.0
	if game.is_hero_actor(attacker):
		attacker_reach = float(attacker.attack_range)
	else:
		attacker_reach = float(attacker.get("attack_range"))
	var target_reach: float = 0.0
	if game.is_enemy_actor(target):
		target_reach = float(target.get("attack_range"))
	elif game.is_hero_actor(target) and String(target.preferred_attack_style) == "melee":
		target_reach = float(target.attack_range)
	return maxf(attacker_reach, target_reach) + 8.0

static func hero_room_for_enemy_targeting(game: Node, hero: Variant) -> Vector2i:
	if hero == null or not is_instance_valid(hero):
		return game.INVALID_ROOM
	if game.is_enemy_actor(hero):
		return Vector2i(hero.current_room)
	if hero.pending_room != game.HERO_INVALID_ROOM and game.rooms.has(hero.pending_room) and game.rooms.has(hero.current_room):
		var room_delta: Vector2i = Vector2i(hero.pending_room) - Vector2i(hero.current_room)
		if absi(room_delta.x) + absi(room_delta.y) == 1:
			var transition_axis: Vector2 = game.room_center(hero.pending_room) - game.room_center(hero.current_room)
			if transition_axis.length_squared() > 0.001:
				transition_axis = transition_axis.normalized()
				var current_side_doorway: Vector2 = game.doorway_position(hero.current_room, hero.pending_room)
				var pending_side_doorway: Vector2 = game.doorway_position(hero.pending_room, hero.current_room)
				var doorway_midpoint: Vector2 = (current_side_doorway + pending_side_doorway) * 0.5
				var side_projection: float = (hero.global_position - doorway_midpoint).dot(transition_axis)
				if side_projection > 8.0:
					return hero.pending_room
				if side_projection < -8.0:
					return hero.current_room
				return hero.current_room
		var current_distance: float = hero.global_position.distance_to(game.room_center(hero.current_room))
		var pending_distance: float = hero.global_position.distance_to(game.room_center(hero.pending_room))
		if pending_distance + 24.0 < current_distance:
			return hero.pending_room
	return hero.current_room

static func hero_is_in_room(game: Node, hero: Variant, room_coord: Vector2i) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if game.is_enemy_actor(hero):
		return Vector2i(hero.current_room) == room_coord
	return hero_room_for_enemy_targeting(game, hero) == room_coord

static func hero_is_long_range_target(_game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if _game.is_enemy_actor(hero):
		return converted_enemy_is_familiar(hero)
	return String(hero.preferred_attack_style) != "melee" or float(hero.attack_range) > 120.0

static func enemy_summon_is_enemy_targetable(game: Node, summon: Variant) -> bool:
	if summon == null or not is_instance_valid(summon):
		return false
	if not game.enemy_is_active(summon):
		return false
	if not enemy_is_converted(summon):
		return false
	if not bool(summon.get_meta("temporary_summon", false)):
		return false
	# Spiritual Weapon remains untargetable by design.
	if String(summon.get_meta("summon_card_id", "")) == "spiritual_weapon_card":
		return false
	return true

static func hero_is_enemy_targetable(game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if game.is_enemy_actor(hero):
		return enemy_summon_is_enemy_targetable(game, hero)
	if game.hero_has_skulker(hero):
		var hero_room: Vector2i = hero_room_for_enemy_targeting(game, hero)
		if hero_room != game.INVALID_ROOM and game.rooms.has(hero_room):
			if not bool(Dictionary(game.rooms[hero_room]).get("lit", false)):
				return false
	return float(hero.invulnerability_time_left) <= 0.0

static func actor_target_label(game: Node, actor: Variant) -> String:
	if actor == null or not is_instance_valid(actor):
		return "a target"
	if game.is_hero_actor(actor):
		return String(actor.hero_name)
	if game.is_enemy_actor(actor):
		var summon_label: String = String(actor.get_meta("summon_source_label", "a summoned ally"))
		return summon_label.to_lower()
	return "a target"

static func enemy_target_category_priority_for_role(_game: Node, enemy_role: String) -> Dictionary:
	return GAME_ENEMY_TARGET_PRIORITY_DEFS.priority_table_for_role(enemy_role)

static func enemy_target_category_for_actor(game: Node, actor: Variant) -> String:
	if actor == null or not is_instance_valid(actor):
		return ""
	if hero_is_long_range_target(game, actor):
		return TARGET_CATEGORY_RANGED
	return TARGET_CATEGORY_MELEE

static func category_priority_rank(priority_table: Dictionary, category: String) -> int:
	# Negative priorities explicitly disable this category for the caller.
	var rank: int = int(priority_table.get(category, 0))
	if rank < 0:
		return 999
	return rank

static func choose_target_from_actor_candidates(game: Node, enemy: Variant, candidates: Array, priority_table: Dictionary) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	var chosen_actor: Variant = null
	var chosen_priority_rank: int = 999
	var chosen_distance: float = INF
	for actor in candidates:
		if actor == null or not is_instance_valid(actor):
			continue
		var category: String = enemy_target_category_for_actor(game, actor)
		var priority_rank: int = category_priority_rank(priority_table, category)
		if priority_rank >= 999:
			continue
		var distance_value: float = enemy.global_position.distance_to(actor.global_position)
		if chosen_actor == null \
		or priority_rank < chosen_priority_rank \
		or (priority_rank == chosen_priority_rank and distance_value < chosen_distance):
			chosen_actor = actor
			chosen_priority_rank = priority_rank
			chosen_distance = distance_value
	return chosen_actor

static func choose_path_target_from_actor_candidates(game: Node, enemy: Variant, candidates: Array, priority_table: Dictionary) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	var chosen_actor: Variant = null
	var chosen_priority_rank: int = 999
	var chosen_path_length: int = 99999
	var chosen_distance: float = INF
	for actor in candidates:
		if actor == null or not is_instance_valid(actor):
			continue
		if not hero_is_enemy_targetable(game, actor):
			continue
		var candidate_room: Vector2i = hero_room_for_enemy_targeting(game, actor)
		if candidate_room == game.INVALID_ROOM:
			continue
		var path_length: int = room_path_distance_cached(game, Vector2i(enemy.current_room), candidate_room)
		if path_length >= 99999:
			continue
		var category: String = enemy_target_category_for_actor(game, actor)
		var priority_rank: int = category_priority_rank(priority_table, category)
		if priority_rank >= 999:
			continue
		var distance_value: float = enemy.global_position.distance_to(actor.global_position)
		if chosen_actor == null \
		or priority_rank < chosen_priority_rank \
		or (priority_rank == chosen_priority_rank and path_length < chosen_path_length) \
		or (priority_rank == chosen_priority_rank and path_length == chosen_path_length and distance_value < chosen_distance):
			chosen_actor = actor
			chosen_priority_rank = priority_rank
			chosen_path_length = path_length
			chosen_distance = distance_value
	return chosen_actor

static func heroes_in_room(game: Node, room_coord: Vector2i) -> Array:
	var room_heroes: Array = []
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		if hero_is_in_room(game, hero, room_coord):
			room_heroes.append(hero)
	return room_heroes

static func heroes_in_room_strict(game: Node, room_coord: Vector2i) -> Array:
	var room_heroes: Array = []
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		if Vector2i(hero.current_room) == room_coord:
			room_heroes.append(hero)
	return room_heroes

static func enemy_targetable_heroes_in_room(game: Node, room_coord: Vector2i) -> Array:
	return targetable_room_actors_cached(game, room_coord, false)

static func enemy_targetable_heroes_in_room_strict(game: Node, room_coord: Vector2i) -> Array:
	return targetable_room_actors_cached(game, room_coord, true)

static func actor_target_lock_key(game: Node, actor: Variant) -> String:
	if actor == null or not is_instance_valid(actor):
		return ""
	if game.is_hero_actor(actor):
		return "hero:%d" % int(actor.hero_index)
	if game.is_enemy_actor(actor):
		return "enemy:%d" % int(actor.enemy_uid)
	return ""

static func actor_from_room_candidates_by_key(game: Node, room_heroes: Array, actor_key: String) -> Variant:
	if actor_key == "":
		return null
	for hero in room_heroes:
		if actor_target_lock_key(game, hero) == actor_key:
			return hero
	return null

static func clear_room_target_lock(enemy: Variant) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_meta(ROOM_TARGET_LOCK_ACTOR_KEY_META):
		enemy.remove_meta(ROOM_TARGET_LOCK_ACTOR_KEY_META)
	if enemy.has_meta(ROOM_TARGET_LOCK_ROOM_META):
		enemy.remove_meta(ROOM_TARGET_LOCK_ROOM_META)
	if enemy.has_meta(ROOM_TARGET_LOCK_ROOM_TARGETS_META):
		enemy.remove_meta(ROOM_TARGET_LOCK_ROOM_TARGETS_META)

static func room_hero_index_signature(game: Node, room_heroes: Array) -> Array:
	var signature: Array = []
	for hero in room_heroes:
		signature.append(actor_target_lock_key(game, hero))
	signature.sort()
	return signature

static func set_room_target_lock(game: Node, enemy: Variant, room_coord: Vector2i, hero: Variant, room_heroes: Array) -> void:
	if enemy == null or hero == null or not is_instance_valid(enemy) or not is_instance_valid(hero):
		return
	var actor_key: String = actor_target_lock_key(game, hero)
	if actor_key == "":
		return
	enemy.set_meta(ROOM_TARGET_LOCK_ROOM_META, room_coord)
	enemy.set_meta(ROOM_TARGET_LOCK_ACTOR_KEY_META, actor_key)
	enemy.set_meta(ROOM_TARGET_LOCK_ROOM_TARGETS_META, room_hero_index_signature(game, room_heroes))

static func locked_room_target_hero(game: Node, enemy: Variant) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	var current_room: Vector2i = Vector2i(enemy.current_room)
	var room_heroes: Array = enemy_targetable_heroes_in_room_strict(game, current_room)
	if room_heroes.is_empty():
		clear_room_target_lock(enemy)
		return null
	var room_signature: Array = room_hero_index_signature(game, room_heroes)
	if enemy.has_meta(ROOM_TARGET_LOCK_ROOM_META):
		var locked_room: Vector2i = Vector2i(enemy.get_meta(ROOM_TARGET_LOCK_ROOM_META, game.INVALID_ROOM))
		if locked_room != current_room:
			clear_room_target_lock(enemy)
	if enemy.has_meta(ROOM_TARGET_LOCK_ROOM_TARGETS_META):
		var locked_signature: Array = Array(enemy.get_meta(ROOM_TARGET_LOCK_ROOM_TARGETS_META, []))
		if locked_signature != room_signature:
			clear_room_target_lock(enemy)
	if enemy.has_meta(ROOM_TARGET_LOCK_ACTOR_KEY_META):
		var locked_actor_key: String = String(enemy.get_meta(ROOM_TARGET_LOCK_ACTOR_KEY_META, ""))
		var locked_hero: Variant = actor_from_room_candidates_by_key(game, room_heroes, locked_actor_key)
		if locked_hero != null:
			return locked_hero
		clear_room_target_lock(enemy)
	var priority_table: Dictionary = enemy_target_category_priority_for_role(game, String(enemy.enemy_role))
	var next_target: Variant = choose_target_from_actor_candidates(game, enemy, room_heroes, priority_table)
	if next_target != null:
		set_room_target_lock(game, enemy, current_room, next_target, room_heroes)
	return next_target

static func default_room_hero_target(game: Node, room_coord: Vector2i, origin: Vector2) -> Variant:
	var candidates: Array = enemy_targetable_heroes_in_room(game, room_coord)
	if candidates.is_empty():
		return null
	var chosen_hero: Variant = null
	var chosen_priority_rank: int = 999
	var chosen_distance: float = INF
	var default_priority: Dictionary = {
		TARGET_CATEGORY_MELEE: 1,
		TARGET_CATEGORY_RANGED: 2,
	}
	for hero in candidates:
		var category: String = enemy_target_category_for_actor(game, hero)
		if category == TARGET_CATEGORY_RESEARCH_CRYSTAL:
			category = TARGET_CATEGORY_MELEE
		var priority_rank: int = category_priority_rank(default_priority, category)
		if priority_rank >= 999:
			continue
		var distance_value: float = origin.distance_to(hero.global_position)
		if chosen_hero == null \
		or priority_rank < chosen_priority_rank \
		or (priority_rank == chosen_priority_rank and distance_value < chosen_distance):
			chosen_hero = hero
			chosen_priority_rank = priority_rank
			chosen_distance = distance_value
	return chosen_hero

static func enemy_room_hero_candidates(game: Node, enemy: Variant) -> Array:
	if enemy == null or not is_instance_valid(enemy):
		return []
	return enemy_targetable_heroes_in_room(game, Vector2i(enemy.current_room))

static func local_enemy_override_target(game: Node, enemy: Variant) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	var room_heroes: Array = enemy_targetable_heroes_in_room_strict(game, Vector2i(enemy.current_room))
	if room_heroes.is_empty():
		return null
	var enemy_role: String = String(enemy.enemy_role)
	var priority_table: Dictionary = enemy_target_category_priority_for_role(game, enemy_role)
	if category_priority_rank(priority_table, TARGET_CATEGORY_MELEE) >= 999 and category_priority_rank(priority_table, TARGET_CATEGORY_RANGED) >= 999:
		return null
	return locked_room_target_hero(game, enemy)

static func cached_priority_target_hero(enemy: Variant) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	if not enemy.has_meta(PRIORITY_TARGET_CACHE_FRAME_META):
		return null
	var cached_frame: int = int(enemy.get_meta(PRIORITY_TARGET_CACHE_FRAME_META))
	if cached_frame != Engine.get_physics_frames():
		return null
	if not enemy.has_meta(PRIORITY_TARGET_CACHE_ACTOR_META):
		return null
	var cached_target: Variant = enemy.get_meta(PRIORITY_TARGET_CACHE_ACTOR_META)
	if cached_target == null or not is_instance_valid(cached_target):
		return null
	return cached_target

static func set_cached_priority_target_hero(enemy: Variant, target: Variant) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	enemy.set_meta(PRIORITY_TARGET_CACHE_FRAME_META, Engine.get_physics_frames())
	enemy.set_meta(PRIORITY_TARGET_CACHE_ACTOR_META, target if target != null and is_instance_valid(target) else null)

static func priority_target_hero(game: Node, enemy: Variant) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null
	var enemy_role: String = String(enemy.enemy_role)
	var priority_table: Dictionary = enemy_target_category_priority_for_role(game, enemy_role)
	if category_priority_rank(priority_table, TARGET_CATEGORY_MELEE) >= 999 and category_priority_rank(priority_table, TARGET_CATEGORY_RANGED) >= 999:
		set_cached_priority_target_hero(enemy, null)
		return null
	var cached_target: Variant = cached_priority_target_hero(enemy)
	if hero_is_enemy_targetable(game, cached_target):
		if hero_is_in_room(game, cached_target, Vector2i(enemy.current_room)):
			return cached_target
	var room_heroes: Array = enemy_room_hero_candidates(game, enemy)
	if not room_heroes.is_empty():
		var room_target: Variant = locked_room_target_hero(game, enemy)
		if room_target != null:
			set_cached_priority_target_hero(enemy, room_target)
			return room_target
	var resolved_target: Variant = choose_path_target_from_actor_candidates(game, enemy, enemy_targetable_actor_candidates(game), priority_table)
	set_cached_priority_target_hero(enemy, resolved_target)
	return resolved_target

static func should_target_active_major_module(game: Node, enemy: Variant) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	var priority_table: Dictionary = enemy_target_category_priority_for_role(game, String(enemy.enemy_role))
	if category_priority_rank(priority_table, TARGET_CATEGORY_MAJOR_MODULE) >= 999:
		return false
	var room_coord: Vector2i = Vector2i(enemy.current_room)
	if not room_has_active_major_module(game, room_coord):
		return false
	return enemy_targetable_heroes_in_room_strict(game, room_coord).is_empty()

static func should_target_active_minor_module(game: Node, enemy: Variant) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	var priority_table: Dictionary = enemy_target_category_priority_for_role(game, String(enemy.enemy_role))
	if category_priority_rank(priority_table, TARGET_CATEGORY_MINOR_MODULE) >= 999:
		return false
	var room_coord: Vector2i = Vector2i(enemy.current_room)
	if not game.rooms.has(room_coord):
		return false
	if not enemy_targetable_heroes_in_room_strict(game, room_coord).is_empty():
		return false
	for module_data_variant in Array(game.rooms[room_coord].get("minor_modules", [])):
		if float(Dictionary(module_data_variant).get("health", 0.0)) > 0.0:
			return true
	return false

static func enemy_situational_speed_multiplier(game: Node, enemy: Variant) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 1.0
	var room_coord: Vector2i = enemy.current_room
	var role: String = String(enemy.enemy_role)
	var has_heroes: bool = false
	if role == game.ENEMY_TYPE_ORC or role == game.ENEMY_TYPE_BAT:
		has_heroes = room_coord != game.INVALID_ROOM and not enemy_targetable_heroes_in_room(game, room_coord).is_empty()
	var multiplier: float = 1.0
	match role:
		game.ENEMY_TYPE_ORC:
			multiplier = 0.72 if has_heroes else 1.0
		game.ENEMY_TYPE_BAT:
			multiplier = 0.72 if has_heroes else 1.0
		_:
			multiplier = 1.0
	if game.rooms.has(room_coord) and float(game.rooms[room_coord].get("neurostun_time_left", 0.0)) > 0.0:
		multiplier *= 0.58
	return multiplier

static func skeleton_archer_goal_position(game: Node, enemy: Variant) -> Vector2:
	var archer_target: Variant = priority_target_hero(game, enemy)
	if archer_target == null or not hero_is_in_room(game, archer_target, enemy.current_room):
		return game.clamp_point_to_room(enemy.global_position, enemy.current_room)
	return game.clamp_point_to_room(enemy.global_position, enemy.current_room)

static func enemy_targetable_actor_candidates(game: Node) -> Array:
	var physics_frame: int = Engine.get_physics_frames()
	if int(game.get_meta(TARGETABLE_ACTOR_CACHE_FRAME_META, -1)) == physics_frame:
		return game.get_meta(TARGETABLE_ACTOR_CACHE_VALUE_META, [])
	var candidates: Array = []
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		if hero_is_enemy_targetable(game, hero):
			candidates.append(hero)
	for summon in game.enemies:
		if enemy_summon_is_enemy_targetable(game, summon):
			candidates.append(summon)
	game.set_meta(TARGETABLE_ACTOR_CACHE_FRAME_META, physics_frame)
	game.set_meta(TARGETABLE_ACTOR_CACHE_VALUE_META, candidates)
	return candidates

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

static func minor_module_target_position(game: Node, room_coord: Vector2i, origin: Vector2) -> Vector2:
	if not game.rooms.has(room_coord):
		return origin
	var room: Dictionary = game.rooms[room_coord]
	var slot_positions: Array = game.minor_slot_positions(room_coord)
	var closest_position: Vector2 = game.room_walkable_center(room_coord)
	var closest_distance: float = INF
	for module_data_variant in Array(room.get("minor_modules", [])):
		var module_data: Dictionary = Dictionary(module_data_variant)
		if float(module_data.get("health", 0.0)) <= 0.0:
			continue
		var slot_index: int = int(module_data.get("slot_index", -1))
		if slot_index < 0 or slot_index >= slot_positions.size():
			continue
		var slot_position: Vector2 = Vector2(slot_positions[slot_index])
		var distance_value: float = origin.distance_to(slot_position)
		if distance_value < closest_distance:
			closest_position = slot_position
			closest_distance = distance_value
	return closest_position

static func active_research_room(game: Node) -> Vector2i:
	if game.active_research.is_empty():
		return game.INVALID_ROOM
	var research_room: Vector2i = Vector2i(game.active_research.get("room", game.INVALID_ROOM))
	if research_room == game.INVALID_ROOM or not game.rooms.has(research_room):
		return game.INVALID_ROOM
	if not game.room_has_active_research(research_room):
		return game.INVALID_ROOM
	return research_room

static func power_crystal_target_room(game: Node) -> Vector2i:
	if game.crystal_holder != null and is_instance_valid(game.crystal_holder):
		return hero_room_for_enemy_targeting(game, game.crystal_holder)
	if game.crystal_ground_room != game.INVALID_ROOM and game.rooms.has(game.crystal_ground_room):
		return game.crystal_ground_room
	return game.crystal_room

static func power_crystal_target_position(game: Node) -> Vector2:
	return game.crystal_world_position()

static func golem_objective_room(game: Node, enemy: Variant) -> Vector2i:
	if enemy == null or not is_instance_valid(enemy):
		return game.crystal_room
	var research_room: Vector2i = active_research_room(game)
	if research_room == game.INVALID_ROOM:
		return game.crystal_room
	var crystal_room: Vector2i = power_crystal_target_room(game)
	var crystal_distance: int = room_path_distance_cached(game, Vector2i(enemy.current_room), crystal_room)
	var research_distance: int = room_path_distance_cached(game, Vector2i(enemy.current_room), research_room)
	if research_distance < crystal_distance:
		return research_room
	if research_distance == crystal_distance:
		var research_world_distance: float = enemy.global_position.distance_to(game.room_center(research_room))
		var crystal_world_distance: float = enemy.global_position.distance_to(power_crystal_target_position(game))
		if research_world_distance < crystal_world_distance:
			return research_room
	return crystal_room

static func golem_objective_position(game: Node, enemy: Variant) -> Vector2:
	var objective_room: Vector2i = golem_objective_room(game, enemy)
	if objective_room == power_crystal_target_room(game):
		return power_crystal_target_position(game)
	if game.rooms.has(objective_room):
		return game.major_slot_position(objective_room)
	return game.crystal_world_position()

static func preferred_golem_major_module_room(game: Node, enemy: Variant) -> Vector2i:
	var module_room: Vector2i = find_nearest_major_module_room(game, enemy.current_room)
	if module_room == game.INVALID_ROOM:
		return game.INVALID_ROOM
	var module_distance: int = room_path_distance_cached(game, Vector2i(enemy.current_room), module_room)
	var crystal_distance: int = room_path_distance_cached(game, Vector2i(enemy.current_room), game.crystal_room)
	if module_distance < crystal_distance:
		return module_room
	return game.INVALID_ROOM

static func apply_enemy_crystal_strike(game: Node, enemy: Variant) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if game.crystal_holder != null and is_instance_valid(game.crystal_holder):
		game.queue_pending_melee_attack(enemy, game.crystal_holder, enemy.attack_damage, enemy.melee_impact_delay(), String(enemy.enemy_role).capitalize())
		return
	game.apply_crystal_damage_from_enemy(enemy)

static func resolve_enemy_attack(game: Node, enemy: Variant) -> void:
	if enemy.attack_cooldown_left > 0.0:
		return
	if enemy_is_calm_neutralized(enemy):
		return
	if enemy.has_method("is_held_person") and bool(enemy.is_held_person()):
		return
	if enemy_is_feared(enemy):
		return
	if enemy_is_converted(enemy):
		var converted_target: Variant = converted_enemy_target(game, enemy)
		if converted_target == null:
			return
		var source_label: String = String(enemy.get_meta("summon_source_label", "A converted enemy"))
		enemy.trigger_attack(converted_target.global_position)
		game.queue_pending_melee_attack(enemy, converted_target, enemy.attack_damage, enemy.melee_impact_delay(), source_label)
		enemy.attack_cooldown_left = enemy.attack_cooldown
		game.update_hud()
		return
	var local_target: Variant = local_enemy_override_target(game, enemy)
	var role_target: Variant = priority_target_hero(game, enemy)
	if String(enemy.enemy_role) == game.ENEMY_TYPE_SLIME:
		var slime_target: Variant = local_target if local_target != null else role_target
		if slime_target != null and hero_is_in_room(game, slime_target, enemy.current_room):
			enemy.trigger_attack(slime_target.global_position)
			game.queue_pending_melee_attack(enemy, slime_target, enemy.attack_damage, enemy.melee_impact_delay(), "A slime")
			game.status_message = "A slime lashes at %s." % actor_target_label(game, slime_target)
			enemy.attack_cooldown_left = enemy.attack_cooldown
			game.update_hud()
			return
		if not should_target_active_minor_module(game, enemy):
			return
		var slime_target_position: Vector2 = minor_module_target_position(game, Vector2i(enemy.current_room), enemy.global_position)
		enemy.trigger_attack(slime_target_position)
		if not damage_minor_module(game, enemy.current_room, enemy.attack_damage, "A slime"):
			return
		enemy.attack_cooldown_left = enemy.attack_cooldown
		game.update_hud()
		return
	if should_target_active_major_module(game, enemy):
		enemy.trigger_attack(major_module_target_position(game, Vector2i(enemy.current_room)))
		if not game.damage_module(enemy.current_room, enemy.attack_damage, true, String(enemy.enemy_role).capitalize()):
			return
		enemy.attack_cooldown_left = enemy.attack_cooldown
		game.update_hud()
		return
	match String(enemy.enemy_role):
		game.ENEMY_TYPE_ORC_RIDER, game.ENEMY_TYPE_DEATH_KNIGHT:
			var armored_target: Variant = local_target if local_target != null else role_target
			if armored_target == null or not hero_is_in_room(game, armored_target, enemy.current_room):
				return
			enemy.trigger_attack(armored_target.global_position)
			var attacker_label: String = "A death knight" if String(enemy.enemy_role) == game.ENEMY_TYPE_DEATH_KNIGHT else "An armored orc"
			game.queue_pending_melee_attack(enemy, armored_target, enemy.attack_damage, enemy.melee_impact_delay(), attacker_label)
			game.status_message = "%s lunges at %s." % [attacker_label, actor_target_label(game, armored_target)]
		game.ENEMY_TYPE_SKELETON_ARCHER:
			var archer_target: Variant = local_target if local_target != null else role_target
			if archer_target != null and hero_is_in_room(game, archer_target, enemy.current_room):
				enemy.trigger_attack(archer_target.global_position)
				game.spawn_laser_projectile(enemy.global_position, archer_target, enemy.attack_damage, Color("dbe5c8"), 3.2, 980.0)
				game.status_message = "A skeleton archer looses an arrow at %s." % actor_target_label(game, archer_target)
			elif enemy.current_room == game.crystal_room:
				enemy.trigger_attack(game.room_center(game.crystal_room))
				apply_enemy_crystal_strike(game, enemy)
				game.status_message = "Skeleton archers are peppering the crystal."
			else:
				return
		game.ENEMY_TYPE_ARCHER_IMP:
			var imp_target: Variant = local_target if local_target != null else role_target
			if imp_target == null or not hero_is_in_room(game, imp_target, enemy.current_room):
				return
			var imp_def: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(enemy.enemy_role)
			enemy.trigger_attack(imp_target.global_position)
			game.spawn_arrow_projectile(enemy.global_position, imp_target, enemy.attack_damage, Color("ff956a"), 2.8, 1060.0, 0, 0, int(imp_def.get("expose_stacks_per_hit", 1)), float(imp_def.get("expose_duration", 6.0)))
			game.status_message = "An archer imp marks %s." % actor_target_label(game, imp_target)
		game.ENEMY_TYPE_ORC:
			var orc_target: Variant = local_target if local_target != null else role_target
			if orc_target != null and hero_is_in_room(game, orc_target, enemy.current_room):
				enemy.trigger_attack(orc_target.global_position)
				game.queue_pending_melee_attack(enemy, orc_target, enemy.attack_damage, enemy.melee_impact_delay(), "Orcs")
				game.status_message = "Orcs are swarming %s." % actor_target_label(game, orc_target)
			elif enemy.current_room == game.crystal_room:
				enemy.trigger_attack(game.room_center(game.crystal_room))
				apply_enemy_crystal_strike(game, enemy)
				game.status_message = "Orcs are striking the crystal."
			else:
				return
		"hellhound", "warlock":
			var skirmisher_target: Variant = local_target if local_target != null else role_target
			if skirmisher_target == null or not hero_is_in_room(game, skirmisher_target, enemy.current_room):
				return
			enemy.trigger_attack(skirmisher_target.global_position)
			game.queue_pending_melee_attack(enemy, skirmisher_target, enemy.attack_damage, enemy.melee_impact_delay(), "A %s" % String(enemy.enemy_role))
			game.status_message = "A %s attacks %s." % [String(enemy.enemy_role), actor_target_label(game, skirmisher_target)]
		game.ENEMY_TYPE_BAT:
			if enemy.current_room != power_crystal_target_room(game):
				return
			enemy.trigger_attack(power_crystal_target_position(game))
			apply_enemy_crystal_strike(game, enemy)
			game.status_message = "Bats dive at the crystal."
		game.ENEMY_TYPE_GOLEM:
			if local_target != null and hero_is_in_room(game, local_target, enemy.current_room):
				enemy.trigger_attack(local_target.global_position)
				game.queue_pending_melee_attack(enemy, local_target, enemy.attack_damage, enemy.melee_impact_delay(), "A golem")
				game.status_message = "A golem hammers %s." % actor_target_label(game, local_target)
			else:
				var target_room: Vector2i = golem_objective_room(game, enemy)
				if target_room == enemy.current_room and target_room != power_crystal_target_room(game):
					enemy.trigger_attack(game.major_slot_position(enemy.current_room))
					game.status_message = "A flame golem is assaulting a research crystal."
				elif enemy.current_room == power_crystal_target_room(game):
					enemy.trigger_attack(power_crystal_target_position(game))
					apply_enemy_crystal_strike(game, enemy)
					game.status_message = "A golem is pounding the crystal."
				else:
					return
		game.ENEMY_TYPE_DEMON_D:
			if enemy.current_room == power_crystal_target_room(game):
				enemy.trigger_attack(power_crystal_target_position(game))
				apply_enemy_crystal_strike(game, enemy)
				game.status_message = "A raider demon is carving into the crystal."
			else:
				return
		game.ENEMY_TYPE_WRAITH:
			var room_targets: Array = enemy_targetable_heroes_in_room(game, enemy.current_room)
			if not room_targets.is_empty():
				var shaman_priority_table: Dictionary = enemy_target_category_priority_for_role(game, String(enemy.enemy_role))
				var blast_target: Variant = choose_target_from_actor_candidates(game, enemy, room_targets, shaman_priority_table)
				var blast_position: Vector2 = blast_target.global_position if blast_target != null else game.room_walkable_center(enemy.current_room)
				blast_position = game.clamp_point_to_room(blast_position, enemy.current_room)
				enemy.trigger_attack(blast_position)
				var defeated_heroes: Array[String] = game.explode_enemy_fireball(enemy.current_room, blast_position, enemy.attack_damage, 68.0, 360.0, "A wraith")
				if defeated_heroes.is_empty():
					game.status_message = "A wraith hurls a mini fireball."
				elif defeated_heroes.size() == 1:
					game.status_message = "A wraith burned down %s." % defeated_heroes[0]
				else:
					game.status_message = "A wraith burned down multiple heroes."
			elif enemy.current_room == game.crystal_room:
				enemy.trigger_attack(game.room_center(game.crystal_room))
				apply_enemy_crystal_strike(game, enemy)
				game.status_message = "Wraiths are scorching the crystal."
			else:
				return
		_:
			if enemy.current_room != game.crystal_room:
				return
			enemy.trigger_attack(game.room_center(game.crystal_room))
			apply_enemy_crystal_strike(game, enemy)
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
		var path_length: int = room_path_distance_cached(game, from_room, room_coord)
		if path_length >= 99999:
			continue
		if path_length < closest_path_length:
			closest_path_length = path_length
			closest_room = room_coord
	return closest_room

static func find_nearest_minor_module_room(game: Node, from_room: Vector2i) -> Vector2i:
	var closest_room: Vector2i = game.INVALID_ROOM
	var closest_path_length: int = 9999
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if not bool(room.get("opened", false)):
			continue
		for module_data_variant in Array(room.get("minor_modules", [])):
			if float(Dictionary(module_data_variant).get("health", 0.0)) <= 0.0:
				continue
			var path_length: int = room_path_distance_cached(game, from_room, room_coord)
			if path_length < closest_path_length:
				closest_room = room_coord
				closest_path_length = path_length
			break
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

static func damage_minor_module(game: Node, room_coord: Vector2i, amount: float, attacker_label: String = "Enemies") -> bool:
	if not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	var active_indices: Array[int] = []
	for module_index in range(room["minor_modules"].size()):
		if float(room["minor_modules"][module_index].get("health", 0.0)) > 0.0:
			active_indices.append(module_index)
	if active_indices.is_empty():
		return false
	var module_index: int = active_indices[game.rng.randi_range(0, active_indices.size() - 1)]
	var module_data: Dictionary = Dictionary(room["minor_modules"][module_index])
	module_data["health"] = maxf(float(module_data["health"]) - amount, 0.0)
	if float(module_data["health"]) <= 0.0:
		game.cancel_pending_minor_construction(room_coord, int(module_data.get("slot_index", -1)))
		room["minor_modules"].remove_at(module_index)
		game.status_message = "%s destroyed a minor module in %s." % [attacker_label, game.room_title(room_coord)]
	else:
		room["minor_modules"][module_index] = module_data
		game.status_message = "%s is dissolving a minor module in %s." % [attacker_label, game.room_title(room_coord)]
	return true
