extends RefCounted

const GAME_ENEMY_DEFS: GDScript = preload("res://scripts/content/game_enemy_defs.gd")

const UNIFIED_KNOCKBACK_FLATFOOTED_DURATION: float = 4.0
const UNIFIED_KNOCKBACK_FLATFOOTED_MOVE_MULTIPLIER: float = 0.72
const UNIFIED_KNOCKBACK_FLATFOOTED_ATTACK_SPEED_MULTIPLIER: float = 0.78
const UNIFIED_KNOCKBACK_FLATFOOTED_DAMAGE_TAKEN_MULTIPLIER: float = 1.5
const UNIFIED_KNOCKBACK_BOUNCE_COLOR: Color = Color("c5d4df")
const KNOCKBACK_GEOMETRY_CACHE_META: StringName = &"knockback_geometry_cache"

static func knockback_geometry_cache_key(game: Node, room_coord: Vector2i) -> String:
	return "%d|%d:%d" % [int(game.floor_index), room_coord.x, room_coord.y]

static func cached_knockback_geometry(game: Node, room_coord: Vector2i) -> Dictionary:
	var cache: Dictionary = Dictionary(game.get_meta(KNOCKBACK_GEOMETRY_CACHE_META, {}))
	var cache_key: String = knockback_geometry_cache_key(game, room_coord)
	if cache.has(cache_key):
		return Dictionary(cache[cache_key])
	var geometry: Dictionary = {
		"bounds": game.room_interior_rect(room_coord, 20.0),
		"regions": game.room_walkable_regions(room_coord, game.ROOM_WALKABLE_INSET + 2.0),
	}
	cache[cache_key] = geometry
	game.set_meta(KNOCKBACK_GEOMETRY_CACHE_META, cache)
	return geometry

static func enemy_forward_direction(game: Node, enemy: Variant) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return Vector2.RIGHT
	var velocity_like: Vector2 = enemy.destination - enemy.global_position
	if velocity_like.length() > 3.0:
		return velocity_like.normalized()
	var target_position: Vector2 = game.enemy_target_position(enemy)
	var target_direction: Vector2 = target_position - enemy.global_position
	if target_direction.length() > 3.0:
		return target_direction.normalized()
	return Vector2.RIGHT

static func enemy_is_active(_game: Node, enemy: Variant) -> bool:
	return _game.is_enemy_actor(enemy) and (not enemy.has_method("is_dying_state") or not enemy.is_dying_state())

static func actor_weight(_game: Node, actor: Variant) -> float:
	if actor == null or not is_instance_valid(actor):
		return 1.0
	return maxf(float(actor.get("weight")), 0.1)

static func find_enemy_by_uid(game: Node, enemy_uid: int) -> Variant:
	for enemy in game.enemies:
		if enemy_is_active(game, enemy) and int(enemy.enemy_uid) == enemy_uid:
			return enemy
	return null

static func find_hero_by_index(game: Node, hero_index: int) -> Variant:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return null
	var hero: Variant = game.heroes[hero_index]
	return hero if game.hero_is_active(hero) else null

static func knockback_actor(game: Node, actor: Variant, direction: Vector2, impulse_strength: float, recovery_duration: float, room_coord: Vector2i, options: Dictionary = {}) -> void:
	if actor == null or not is_instance_valid(actor) or direction == Vector2.ZERO or impulse_strength <= 0.0 or recovery_duration <= 0.0:
		return
	var knockback_geometry: Dictionary = cached_knockback_geometry(game, room_coord)
	var knockback_bounds: Rect2 = Rect2(knockback_geometry.get("bounds", Rect2()))
	var knockback_regions: Array = Array(knockback_geometry.get("regions", []))
	if game.is_enemy_actor(actor) and actor.has_method("begin_physics_throw"):
		var max_wall_bounces: int = maxi(0, int(options.get("max_wall_bounces", 1)))
		var wall_hit_damage: float = maxf(float(options.get("wall_hit_damage", 0.0)), 0.0)
		var flatfooted_duration: float = maxf(float(options.get("flatfooted_duration", UNIFIED_KNOCKBACK_FLATFOOTED_DURATION)), 0.0)
		var flatfooted_move_multiplier: float = clampf(float(options.get("flatfooted_move_multiplier", UNIFIED_KNOCKBACK_FLATFOOTED_MOVE_MULTIPLIER)), 0.0, 1.0)
		var flatfooted_attack_speed_multiplier: float = clampf(float(options.get("flatfooted_attack_speed_multiplier", UNIFIED_KNOCKBACK_FLATFOOTED_ATTACK_SPEED_MULTIPLIER)), 0.0, 1.0)
		var flatfooted_damage_taken_multiplier: float = maxf(float(options.get("flatfooted_damage_taken_multiplier", UNIFIED_KNOCKBACK_FLATFOOTED_DAMAGE_TAKEN_MULTIPLIER)), 1.0)
		var source_hero_index: int = int(options.get("source_hero_index", -1))
		var bounce_effect_color: Color = Color(options.get("bounce_effect_color", UNIFIED_KNOCKBACK_BOUNCE_COLOR))
		actor.begin_physics_throw(
			direction.normalized() * impulse_strength,
			recovery_duration,
			knockback_bounds,
			knockback_regions,
			max_wall_bounces,
			wall_hit_damage,
			flatfooted_duration,
			flatfooted_move_multiplier,
			flatfooted_attack_speed_multiplier,
			flatfooted_damage_taken_multiplier,
			source_hero_index,
			bounce_effect_color
		)
		actor.reset_physics_interpolation()
		return
	if not actor.has_method("apply_knockback_impulse"):
		return
	actor.apply_knockback_impulse(direction.normalized() * impulse_strength, recovery_duration, knockback_bounds, knockback_regions)
	actor.reset_physics_interpolation()

static func apply_weighted_melee_knockback(game: Node, attacker: Variant, defender: Variant, room_coord: Vector2i, base_force: float = 0.0) -> void:
	if base_force <= 0.0:
		return
	if attacker == null or defender == null or not is_instance_valid(attacker) or not is_instance_valid(defender):
		return
	var push_direction: Vector2 = (defender.global_position - attacker.global_position).normalized()
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	var attacker_weight: float = actor_weight(game, attacker)
	var defender_weight: float = actor_weight(game, defender)
	var weight_gap: float = absf(attacker_weight - defender_weight)
	var equal_duration: float = clampf(0.16 + weight_gap * 0.04, 0.14, 0.34)
	if absf(attacker_weight - defender_weight) <= 0.18:
		knockback_actor(game, defender, push_direction, base_force * 0.62, equal_duration, room_coord)
		knockback_actor(game, attacker, -push_direction, base_force * 0.62, equal_duration, room_coord)
		return
	if attacker_weight > defender_weight:
		var attacker_ratio: float = clampf(attacker_weight / maxf(defender_weight, 0.1), 1.0, 2.5)
		var defender_duration: float = clampf(0.18 + weight_gap * 0.05, 0.16, 0.42)
		var attacker_duration: float = clampf(0.10 + weight_gap * 0.02, 0.08, 0.24)
		knockback_actor(game, defender, push_direction, base_force * attacker_ratio, defender_duration, room_coord)
		knockback_actor(game, attacker, -push_direction, base_force * 0.34 * clampf(defender_weight / attacker_weight, 0.45, 1.0), attacker_duration, room_coord)
		return
	var defender_ratio: float = clampf(defender_weight / maxf(attacker_weight, 0.1), 1.0, 2.5)
	var attacker_duration_heavy: float = clampf(0.18 + weight_gap * 0.05, 0.16, 0.42)
	var defender_duration_light: float = clampf(0.10 + weight_gap * 0.02, 0.08, 0.24)
	knockback_actor(game, attacker, -push_direction, base_force * defender_ratio, attacker_duration_heavy, room_coord)
	knockback_actor(game, defender, push_direction, base_force * 0.34 * clampf(attacker_weight / defender_weight, 0.45, 1.0), defender_duration_light, room_coord)

static func attacker_pending_melee_key(game: Node, attacker: Variant) -> String:
	if attacker == null or not is_instance_valid(attacker):
		return ""
	if game.is_hero_actor(attacker):
		return "hero:%d" % int(attacker.hero_index)
	return "enemy:%d" % int(attacker.enemy_uid)

static func attacker_has_pending_melee(game: Node, attacker: Variant) -> bool:
	var attacker_key: String = attacker_pending_melee_key(game, attacker)
	if attacker_key == "":
		return false
	for pending_attack_variant in game.pending_melee_attacks:
		var pending_attack: Dictionary = pending_attack_variant
		if String(pending_attack.get("attacker_key", "")) == attacker_key:
			return true
	return false

static func queue_pending_melee_attack(game: Node, attacker: Variant, target: Variant, damage: float, windup: float, source_label: String) -> void:
	if attacker == null or target == null or not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	if attacker_has_pending_melee(game, attacker):
		return
	var target_enemy_uid: int = int(target.enemy_uid) if game.is_enemy_actor(target) else -1
	var target_hero_index: int = int(target.hero_index) if game.is_hero_actor(target) else -1
	game.pending_melee_attacks.append({
		"attacker_key": attacker_pending_melee_key(game, attacker),
		"attacker_is_hero": game.is_hero_actor(attacker),
		"attacker_hero_index": int(attacker.hero_index) if game.is_hero_actor(attacker) else -1,
		"attacker_enemy_uid": int(attacker.enemy_uid) if game.is_enemy_actor(attacker) else -1,
		"target_hero_index": target_hero_index,
		"target_enemy_uid": target_enemy_uid,
		"damage": damage,
		"timer_left": maxf(windup, 0.05),
		"source_label": source_label,
	})

static func finalize_hero_death(game: Node, hero: Variant, source_label: String) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var was_selected: bool = hero.hero_index == game.selected_hero_index
	game.clear_pending_room_loot_request(hero.hero_index)
	game.clear_pending_room_action_request(hero.hero_index)
	if game.crystal_holder == hero:
		game.drop_crystal(hero.current_room)
	game.opening_heroes.erase(hero)
	if game.opening_hero == hero:
		game.opening_hero = game.opening_heroes[0] if not game.opening_heroes.is_empty() else null
	if game.opening_room != game.INVALID_ROOM and game.opening_heroes.is_empty():
		game.opening_room = game.INVALID_ROOM
		game.opening_origin_room = game.INVALID_ROOM
		game.opening_hero = null
		game.opening_timer_left = 0.0
	game.reset_hero_combo(hero)
	hero.clear_orders()
	hero.begin_death()
	if hero.hero_index >= 0 and hero.hero_index < game.hero_profiles.size():
		game.hero_profiles[hero.hero_index]["dead"] = true
	if was_selected:
		game.ensure_valid_selected_hero()
		var next_selected: Variant = game.selected_hero()
		if next_selected != null:
			game.selected_room = game.active_hero_room_for_commands(next_selected)
	game.update_selected_hero_flags()
	game.pending_melee_attacks = game.pending_melee_attacks.filter(func(entry: Dictionary) -> bool:
		return int(entry.get("attacker_hero_index", -1)) != hero.hero_index and int(entry.get("target_hero_index", -1)) != hero.hero_index
	)
	if game.alive_hero_count() <= 0:
		game.game_over = true
		game.status_message = "All heroes have fallen."
	else:
		game.status_message = "%s killed %s." % [source_label, hero.hero_name]
	game.update_hud()

static func advance_pending_melee_attacks(game: Node, delta: float) -> void:
	if game.pending_melee_attacks.is_empty():
		return
	var active_attacks: Array = []
	for pending_attack_variant in game.pending_melee_attacks:
		var pending_attack: Dictionary = pending_attack_variant
		pending_attack["timer_left"] = maxf(float(pending_attack.get("timer_left", 0.0)) - delta, 0.0)
		if float(pending_attack["timer_left"]) > 0.0:
			active_attacks.append(pending_attack)
			continue
		var attacker: Variant = find_hero_by_index(game, int(pending_attack.get("attacker_hero_index", -1))) if bool(pending_attack.get("attacker_is_hero", false)) else find_enemy_by_uid(game, int(pending_attack.get("attacker_enemy_uid", -1)))
		var target_enemy_uid: int = int(pending_attack.get("target_enemy_uid", -1))
		var target_hero_index: int = int(pending_attack.get("target_hero_index", -1))
		var target: Variant = find_enemy_by_uid(game, target_enemy_uid) if target_enemy_uid >= 0 else find_hero_by_index(game, target_hero_index)
		if attacker == null or target == null:
			continue
		var attack_room: Vector2i = attacker.current_room
		if game.is_hero_actor(target) and not game.hero_is_in_room(target, attack_room):
			continue
		if game.is_enemy_actor(target) and target.current_room != attack_room:
			continue
		# Commit queued melee attacks even if movement changed spacing during windup.
		var incoming_damage: float = float(pending_attack.get("damage", 0.0))
		var defeated: bool = false
		if game.is_hero_actor(target):
			incoming_damage = game.adjusted_incoming_damage_for_hero(target, incoming_damage)
			var previous_rage: int = int(target.fighter_rage)
			defeated = target.take_damage(incoming_damage, false)
			if game.is_enemy_actor(attacker) and String(attacker.enemy_role) == GAME_ENEMY_DEFS.TYPE_HELLHOUND and target.has_method("apply_enemy_flatfooted"):
				var hellhound_def: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(attacker.enemy_role)
				target.apply_enemy_flatfooted(float(hellhound_def.get("hero_slow_per_hit", 0.0)), float(hellhound_def.get("hero_slow_max", 0.0)), float(hellhound_def.get("hero_slow_duration", 0.0)), float(hellhound_def.get("hero_flatfooted_damage_taken_multiplier", 1.5)))
			game.maybe_show_fighter_rage_popup(target, previous_rage)
			if defeated and game.try_auto_cast_fatal_shield(target, incoming_damage):
				continue
		else:
			var melee_auto_crit: bool = false
			if target.has_method("is_held_person") and bool(target.is_held_person()):
				melee_auto_crit = true
			if melee_auto_crit:
				incoming_damage *= 2.0
			defeated = target.take_damage(incoming_damage, (target.global_position - attacker.global_position).normalized())
			if game.is_hero_actor(attacker):
				game.register_hero_enemy_hit(attacker, target, (target.global_position - attacker.global_position).normalized())
			if game.is_enemy_actor(attacker) and bool(attacker.get_meta("summon_applies_flatfooted", false)) and target.has_method("apply_flatfooted_debuff"):
				var flatfooted_duration: float = maxf(float(attacker.get_meta("summon_flatfooted_duration", 6.0)), 0.0)
				if flatfooted_duration > 0.0:
					var flatfooted_move_multiplier: float = clampf(float(attacker.get_meta("summon_flatfooted_move_multiplier", 0.0)), 0.0, 1.0)
					var flatfooted_attack_speed_multiplier: float = clampf(float(attacker.get_meta("summon_flatfooted_attack_speed_multiplier", 0.0)), 0.0, 1.0)
					var flatfooted_damage_taken_multiplier: float = maxf(float(attacker.get_meta("summon_flatfooted_damage_taken_multiplier", 1.5)), 1.0)
					target.apply_flatfooted_debuff(flatfooted_duration, flatfooted_move_multiplier, flatfooted_attack_speed_multiplier, flatfooted_damage_taken_multiplier)
		apply_weighted_melee_knockback(game, attacker, target, attack_room)
		if game.is_hero_actor(attacker) and game.is_enemy_actor(target):
			var bonus_knockback: float = maxf(float(attacker.get("basic_attack_knockback")), 0.0)
			if bonus_knockback > 0.0:
				var bonus_direction: Vector2 = (target.global_position - attacker.global_position).normalized()
				if bonus_direction == Vector2.ZERO:
					bonus_direction = Vector2.RIGHT
				knockback_actor(game, target, bonus_direction, bonus_knockback, 0.2, attack_room)
		if defeated and game.is_hero_actor(target):
			finalize_hero_death(game, target, String(pending_attack.get("source_label", "An enemy")))
	game.pending_melee_attacks = active_attacks
