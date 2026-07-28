extends RefCounted

const GAME_ENEMY_DEFS: GDScript = preload("res://scripts/content/game_enemy_defs.gd")
const EFFECT_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const WIZARD_FIRE_BOLT_EFFECT: Texture2D = preload("res://assets/characters/packs/pack01/projectiles/magic/Wizard_Attack02_Effect.png")
const NECROMANCER_ATTACK_EFFECT: Texture2D = preload("res://assets/characters/packs/pack01/projectiles/magic/Necromancer_Attack02_Effect.png")
const PRIEST_HEAL_EFFECT: Texture2D = preload("res://assets/characters/packs/pack01/projectiles/magic/Priest_Heal_effect.png")
const PRIEST_ATTACK_EFFECT: Texture2D = preload("res://assets/characters/packs/pack01/projectiles/magic/Priest_Attack_effect.png")
const GHOSTFIRE_BEAM_EFFECT: Texture2D = preload("res://assets/characters/packs/pack02/projectiles/Ghostfire_Beam.png")

static func launch_wave(game: Node, entered_room: Vector2i) -> void:
	var dark_rooms: Array[Vector2i] = []
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if room_coord == game.crystal_room or not room["opened"] or room["lit"]:
			continue
		dark_rooms.append(room_coord)
	if dark_rooms.is_empty():
		game.door_wave_auto_heal_pending = false
		game.door_wave_healing_active = true
		game.status_message = "Opened a lit frontier. No dark room was available for a wave."
		game.update_hud()
		return
	game.wave_index += 1
	var spawn_room_count: int = mini(mini(1 + int(floor(float(max(game.wave_index - 1, 0)) / 2.0)), dark_rooms.size()), game.DOOR_WAVE_POINTS)
	var total_wave_points: int = game.DOOR_WAVE_POINTS
	var chosen_rooms: Array[Vector2i] = []
	while chosen_rooms.size() < spawn_room_count and not dark_rooms.is_empty():
		var room_index: int = game.rng.randi_range(0, dark_rooms.size() - 1)
		chosen_rooms.append(dark_rooms[room_index])
		dark_rooms.remove_at(room_index)
	var delayed_room_order: int = 0
	for spawn_index in range(chosen_rooms.size()):
		var room_coord: Vector2i = chosen_rooms[spawn_index]
		var wave_points: int = maxi(1, int(floor(float(total_wave_points) / float(chosen_rooms.size()))))
		if spawn_index < total_wave_points % chosen_rooms.size():
			wave_points += 1
		var immediate: bool = room_coord == entered_room
		queue_wave_spawn(game, room_coord, wave_points, immediate, delayed_room_order)
		if not immediate:
			delayed_room_order += 1
	game.status_message = "Wave %d emerged from %d dark room%s." % [game.wave_index, chosen_rooms.size(), "" if chosen_rooms.size() == 1 else "s"]
	game.update_hud()

static func queue_wave_spawn(game: Node, room_coord: Vector2i, wave_points: int, immediate: bool, spawn_order: int) -> void:
	if not game.rooms.has(room_coord):
		return
	var spawn_plan: Array[String] = build_enemy_spawn_plan(game, wave_points, false)
	if spawn_plan.is_empty():
		return
	if immediate:
		for enemy_type in spawn_plan:
			spawn_wave_enemy(game, room_coord, enemy_type)
		return
	var room_delay: float = 0.0 if immediate else game.WAVE_WARNING_DURATION + float(spawn_order) * game.WAVE_STAGGER_ROOM_INTERVAL
	game.rooms[room_coord]["warning_timer_left"] = room_delay
	var spawn_positions: Array = build_spawn_positions(game, room_coord, spawn_plan.size())
	game.pending_enemy_spawns.append({
		"room": room_coord,
		"remaining": spawn_plan.size(),
		"delay_left": room_delay,
		"interval": game.WAVE_STAGGER_ENEMY_INTERVAL,
		"total_count": spawn_plan.size(),
		"spawned": 0,
		"plan": spawn_plan,
		"positions": spawn_positions,
	})

static func advance_pending_enemy_spawns(game: Node, delta: float) -> void:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		game.rooms[room_coord]["warning_timer_left"] = maxf(float(game.rooms[room_coord].get("warning_timer_left", 0.0)) - delta, 0.0)
	var active_spawns: Array = []
	for pending_spawn in game.pending_enemy_spawns:
		pending_spawn["delay_left"] = float(pending_spawn["delay_left"]) - delta
		while int(pending_spawn["remaining"]) > 0 and float(pending_spawn["delay_left"]) <= 0.0:
			var plan: Array = Array(pending_spawn.get("plan", []))
			var positions: Array = Array(pending_spawn.get("positions", []))
			var spawn_index: int = int(pending_spawn.get("spawned", 0))
			if spawn_index < 0 or spawn_index >= plan.size():
				break
			var spawn_position: Vector2 = Vector2.INF
			if spawn_index >= 0 and spawn_index < positions.size():
				spawn_position = Vector2(positions[spawn_index])
			spawn_wave_enemy_at(game, Vector2i(pending_spawn["room"]), String(plan[spawn_index]), spawn_position)
			pending_spawn["spawned"] = int(pending_spawn["spawned"]) + 1
			pending_spawn["remaining"] = int(pending_spawn["remaining"]) - 1
			pending_spawn["delay_left"] = float(pending_spawn["delay_left"]) + float(pending_spawn["interval"])
		if int(pending_spawn["remaining"]) > 0:
			active_spawns.append(pending_spawn)
	game.pending_enemy_spawns = active_spawns

static func advance_crystal_pressure(game: Node, delta: float) -> void:
	if game.crystal_holder == null or not is_instance_valid(game.crystal_holder):
		return
	game.crystal_pressure_timer_left = maxf(game.crystal_pressure_timer_left - delta, 0.0)
	if game.crystal_pressure_timer_left > 0.0:
		return
	game.crystal_pressure_timer_left = game.CRYSTAL_PRESSURE_INTERVAL
	trigger_crystal_pressure(game)

static func trigger_crystal_pressure(game: Node) -> void:
	var dark_rooms: Array[Vector2i] = []
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if room_coord == game.crystal_room or not room["opened"] or room["lit"]:
			continue
		dark_rooms.append(room_coord)
	if dark_rooms.is_empty():
		return
	for room_coord in dark_rooms:
		queue_pressure_spawn(game, room_coord, game.CRYSTAL_PRESSURE_ENEMIES_PER_ROOM + int(floor(float(max(game.floor_index - 1, 0)) / 2.0)))
	game.status_message = "The crystal agitates %d dark room%s." % [dark_rooms.size(), "" if dark_rooms.size() == 1 else "s"]
	game.update_hud()

static func queue_pressure_spawn(game: Node, room_coord: Vector2i, count: int) -> void:
	if not game.rooms.has(room_coord) or count <= 0:
		return
	var spawn_plan: Array[String] = build_enemy_spawn_plan(game, count, true)
	if spawn_plan.is_empty():
		return
	game.rooms[room_coord]["warning_timer_left"] = maxf(float(game.rooms[room_coord].get("warning_timer_left", 0.0)), game.CRYSTAL_PRESSURE_WARNING_DURATION)
	var spawn_positions: Array = build_spawn_positions(game, room_coord, spawn_plan.size())
	game.pending_enemy_spawns.append({
		"room": room_coord,
		"remaining": spawn_plan.size(),
		"delay_left": game.CRYSTAL_PRESSURE_WARNING_DURATION,
		"interval": game.WAVE_STAGGER_ENEMY_INTERVAL,
		"total_count": spawn_plan.size(),
		"spawned": 0,
		"plan": spawn_plan,
		"positions": spawn_positions,
	})

static func enemy_pack_size(game: Node, enemy_type: String) -> int:
	return GAME_ENEMY_DEFS.enemy_pack_size(enemy_type)

static func enemy_wave_point_cost(game: Node, enemy_type: String) -> int:
	return GAME_ENEMY_DEFS.enemy_wave_point_cost(enemy_type)

static func enemy_spawn_weight(game: Node, enemy_type: String, pressure_spawn: bool = false) -> float:
	return GAME_ENEMY_DEFS.enemy_spawn_weight(enemy_type, pressure_spawn)

static func weighted_enemy_type_choice(game: Node, candidates: Array[String], pressure_spawn: bool = false) -> String:
	if candidates.is_empty():
		return game.ENEMY_TYPE_ORC
	var total_weight: float = 0.0
	for enemy_type in candidates:
		total_weight += enemy_spawn_weight(game, enemy_type, pressure_spawn)
	var roll: float = game.rng.randf() * maxf(total_weight, 0.001)
	for enemy_type in candidates:
		roll -= enemy_spawn_weight(game, enemy_type, pressure_spawn)
		if roll <= 0.0:
			return enemy_type
	return candidates[candidates.size() - 1]

static func build_enemy_spawn_plan(game: Node, budget: int, pressure_spawn: bool = false) -> Array[String]:
	var remaining: int = maxi(1, budget)
	var plan: Array[String] = []
	while remaining > 0:
		var candidates: Array[String] = []
		for enemy_type_variant in GAME_ENEMY_DEFS.enemy_spawn_order():
			var enemy_type: String = String(enemy_type_variant)
			if not GAME_ENEMY_DEFS.enemy_available_on_floor(enemy_type, game.floor_index):
				continue
			if enemy_wave_point_cost(game, enemy_type) <= remaining:
				candidates.append(enemy_type)
		if candidates.is_empty():
			candidates = [game.ENEMY_TYPE_ORC]
		var chosen_type: String = weighted_enemy_type_choice(game, candidates, pressure_spawn)
		var pack_size: int = enemy_pack_size(game, chosen_type)
		for _pack_index in range(pack_size):
			plan.append(chosen_type)
		remaining -= enemy_wave_point_cost(game, chosen_type)
	return plan

static func spawn_wave(game: Node, room_coord: Vector2i, count: int) -> void:
	var spawn_plan: Array[String] = build_enemy_spawn_plan(game, count, false)
	for enemy_type in spawn_plan:
		spawn_wave_enemy(game, room_coord, enemy_type)

static func build_spawn_positions(game: Node, room_coord: Vector2i, count: int) -> Array:
	var positions: Array = []
	for _spawn_index in range(maxi(count, 0)):
		positions.append(game.random_walkable_point(room_coord))
	return positions

static func spawn_wave_enemy(game: Node, room_coord: Vector2i, enemy_type: String) -> void:
	spawn_wave_enemy_at(game, room_coord, enemy_type, Vector2.INF)

static func spawn_wave_enemy_at(game: Node, room_coord: Vector2i, enemy_type: String, spawn_position_hint: Vector2 = Vector2.INF) -> void:
	var enemy: Variant = game.ENEMY_SCENE.instantiate()
	game.enemy_layer.add_child(enemy)
	enemy.enemy_uid = game.next_enemy_uid
	game.next_enemy_uid += 1
	var spawn_position: Vector2 = spawn_position_hint
	if spawn_position == Vector2.INF:
		spawn_position = game.random_walkable_point(room_coord)
	enemy.global_position = spawn_position
	enemy.reset_physics_interpolation()
	enemy.set_role(enemy_type)
	enemy.current_room = room_coord
	enemy.previous_room = room_coord
	enemy.next_room = room_coord
	enemy.set_destination(spawn_position)
	game.enemies.append(enemy)

static func projectile_numeric_pierce(projectile: Dictionary) -> int:
	if projectile.has("pierce"):
		return maxi(0, int(projectile.get("pierce", 0)))
	return maxi(0, int(projectile.get("max_pierce", 1)) - 1)

static func projectile_total_hits(projectile: Dictionary) -> int:
	return projectile_numeric_pierce(projectile) + 1

static func projectile_numeric_bounces(projectile: Dictionary) -> int:
	return maxi(0, int(projectile.get("remaining_bounces", projectile.get("bounces", 0))))

static func projectile_uses_linear_motion(projectile: Dictionary) -> bool:
	var projectile_kind: String = String(projectile.get("kind", ""))
	if projectile_kind == "axe" or projectile_kind == "dagger":
		return true
	if String(projectile.get("motion_mode", "")) == "linear":
		return true
	if int(projectile.get("bounces", 0)) > 0 or int(projectile.get("remaining_bounces", 0)) > 0:
		return true
	if projectile_numeric_pierce(projectile) > 0:
		return true
	return false

static func apply_projectile_final_hit_bonus(game: Node, projectile: Dictionary, impact_position: Vector2) -> void:
	var projectile_kind: String = String(projectile.get("kind", ""))
	var effect_kind: String = String(projectile.get("final_hit_effect_kind", ""))
	if effect_kind == "" and projectile_kind == "axe":
		effect_kind = "shield_flash"
	if effect_kind != "":
		var effect_color: Color = Color(projectile.get("final_hit_effect_color", projectile.get("color", Color("ffd27a"))))
		var effect_radius: float = maxf(float(projectile.get("final_hit_effect_radius", 42.0)), 1.0)
		var effect_duration: float = maxf(float(projectile.get("final_hit_effect_duration", 0.24)), 0.05)
		var effect_width: float = maxf(float(projectile.get("final_hit_effect_width", 3.2)), 0.5)
		game.projectiles.append({
			"kind": effect_kind,
			"position": impact_position,
			"previous": impact_position,
			"target_position": impact_position,
			"color": effect_color,
			"radius": effect_radius,
			"impact_radius": effect_radius,
			"lifetime_left": effect_duration,
			"blast_duration": effect_duration,
			"width": effect_width,
		})
	var final_hit_label: String = String(projectile.get("final_hit_label", ""))
	if final_hit_label == "" and projectile_kind == "axe":
		final_hit_label = "Final Hit"
	if final_hit_label != "":
		var label_color: Color = Color(projectile.get("final_hit_label_color", projectile.get("color", Color("ffd27a"))))
		game.add_resource_floating_text(impact_position + Vector2(0.0, -14.0), final_hit_label, label_color.lightened(0.18))

static func apply_card_projectile_hits(game: Node, projectile: Dictionary) -> void:
	var projectile_kind: String = String(projectile.get("kind", ""))
	var pierced_count: int = int(projectile.get("pierced_count", 0))
	var max_hits: int = projectile_total_hits(projectile)
	if pierced_count >= max_hits:
		projectile["expire_after_hit"] = true
		return
	var room_coord: Vector2i = projectile.get("room", game.INVALID_ROOM)
	var previous: Vector2 = projectile.get("previous", projectile.get("position", Vector2.ZERO))
	var current: Vector2 = projectile.get("position", Vector2.ZERO)
	var projectile_direction: Vector2 = (current - previous).normalized()
	if projectile_direction == Vector2.ZERO:
		projectile_direction = Vector2(projectile.get("velocity", Vector2.RIGHT)).normalized()
	var hit_radius: float = float(projectile.get("radius", 10.0))
	var already_hit: Array = Array(projectile.get("hit_enemy_uids", []))
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		if already_hit.has(int(enemy.enemy_uid)):
			continue
		if game.point_distance_to_segment(enemy.global_position, previous, current) > hit_radius:
			continue
		var damage: float = float(projectile.get("damage", 0.0))
		if projectile_kind == "dagger":
			var projectile_forward: Vector2 = Vector2(projectile.get("velocity", Vector2.RIGHT)).normalized()
			if projectile_forward.dot(game.enemy_forward_direction(enemy)) > 0.45:
				damage *= float(projectile.get("backstab_multiplier", 1.75))
				var owner_index: int = int(projectile.get("owner_hero_index", -1))
				if owner_index >= 0 and owner_index < game.heroes.size():
					var owner_hero: Variant = game.heroes[owner_index]
					if owner_hero != null and is_instance_valid(owner_hero):
						owner_hero.combo_points += int(projectile.get("combo_gain", 1))
		var impact_direction: Vector2 = projectile_direction
		if impact_direction == Vector2.ZERO:
			impact_direction = (enemy.global_position - previous).normalized()
		if impact_direction == Vector2.ZERO:
			impact_direction = Vector2(projectile.get("velocity", Vector2.RIGHT)).normalized()
		if impact_direction == Vector2.ZERO:
			impact_direction = Vector2.RIGHT
		enemy.take_damage(damage, impact_direction)
		already_hit.append(int(enemy.enemy_uid))
		pierced_count += 1
		var base_knockback_force: float = maxf(float(projectile.get("knockback_force", 0.0)), 0.0)
		var final_hit_knockback_multiplier: float = maxf(float(projectile.get("final_hit_knockback_multiplier", 1.0)), 1.0)
		var base_knockback_duration: float = clampf(float(projectile.get("knockback_duration", 0.18)), 0.08, 0.5)
		var final_hit: bool = pierced_count >= max_hits
		var knockback_force: float = base_knockback_force * (final_hit_knockback_multiplier if final_hit else 1.0)
		var knockback_duration: float = base_knockback_duration * (1.2 if final_hit else 1.0)
		if knockback_force > 0.0:
			game.knockback_actor(enemy, impact_direction, knockback_force, knockback_duration, enemy.current_room)
		if final_hit:
			apply_projectile_final_hit_bonus(game, projectile, enemy.global_position)
			projectile["expire_after_hit"] = true
			break
	projectile["pierced_count"] = pierced_count
	projectile["max_pierce"] = max_hits
	projectile["pierce"] = max_hits - 1
	projectile["hit_enemy_uids"] = already_hit

static func process_combat(game: Node, delta: float) -> void:
	game.advance_pending_melee_attacks(delta)
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		hero.cooldown_left = maxf(hero.cooldown_left - delta, 0.0)
		if hero.carrying_crystal or hero.pending_room != game.HERO_INVALID_ROOM or hero.cooldown_left > 0.0 or game.attacker_has_pending_melee(hero):
			continue
		if hero.preferred_attack_style == "melee":
			var melee_target: Variant = nearest_enemy_in_room(game, hero.current_room, hero.global_position, 100000.0)
			if melee_target == null:
				continue
			var melee_offset: Vector2 = melee_target.global_position - hero.global_position
			var melee_distance: float = melee_offset.length()
			var melee_engage_distance: float = game.melee_attack_resolution_distance(hero, melee_target)
			if melee_distance > melee_engage_distance:
				if not game.active_hand_drag.is_empty() or game.hero_has_locked_player_command(hero):
					continue
				var engage_direction: Vector2 = melee_offset.normalized() if melee_distance > 0.001 else Vector2.RIGHT
				var desired_position: Vector2 = game.clamp_point_to_room(melee_target.global_position - engage_direction * maxf(melee_engage_distance - 10.0, 28.0), hero.current_room)
				var current_room_path: Array[Vector2i] = [hero.current_room]
				game.issue_hero_steps(hero, game.build_steps_for_path(current_room_path, hero.global_position, desired_position))
				continue
			var preserve_player_orders: bool = game.hero_has_locked_player_command(hero)
			if not preserve_player_orders:
				hero.move_steps.clear()
				hero.set_destination(hero.global_position)
			hero.trigger_attack(melee_target.global_position, hero.preferred_attack_style)
			game.queue_pending_melee_attack(hero, melee_target, hero.attack_damage, hero.melee_impact_delay(), hero.hero_name)
			hero.cooldown_left = hero.attack_cooldown
			continue
		var hero_target: Variant = nearest_enemy_in_room(game, hero.current_room, hero.global_position, hero.attack_range)
		if hero_target != null:
			hero.trigger_attack(hero_target.global_position, hero.preferred_attack_style)
			if String(hero.preferred_attack_style) == "fire_bolt":
				spawn_fire_bolt_projectile(game, hero.global_position, hero_target, hero.attack_damage, Color("ff8e47"), 4.4, 1120.0)
			elif String(hero.preferred_attack_style) == "holy_bolt":
				hero_target.take_damage(hero.attack_damage, (hero_target.global_position - hero.global_position).normalized())
				game.projectiles.append({
					"kind": "priest_attack_effect",
					"position": hero_target.global_position,
					"previous": hero_target.global_position,
					"target_position": hero_target.global_position,
					"color": Color("d8f7b0"),
					"radius": 28.0,
					"impact_radius": 28.0,
					"lifetime_left": 0.24,
					"blast_duration": 0.24,
					"width": 3.0,
				})
			else:
				spawn_laser_projectile(game, hero.global_position, hero_target, hero.attack_damage, Color("ffe48a"), 5.5, 1220.0)
			hero.cooldown_left = hero.attack_cooldown
	for hero in game.heroes:
		if not game.hero_is_active(hero):
			continue
		if hero.carrying_crystal or hero.pending_room != game.HERO_INVALID_ROOM or hero.pending_open_room != game.HERO_INVALID_ROOM or game.attacker_has_pending_melee(hero):
			continue
		if game.hero_has_locked_player_command(hero) or not game.active_hand_drag.is_empty():
			continue
		if nearest_enemy_in_room(game, hero.current_room, hero.global_position, 100000.0) != null:
			continue
		var idle_position: Vector2 = game.room_local_idle_position_for_hero(hero.current_room, hero)
		if hero.global_position.distance_to(idle_position) <= 18.0:
			continue
		var idle_room_path: Array[Vector2i] = [hero.current_room]
		game.issue_hero_steps(hero, game.build_steps_for_path(idle_room_path, hero.global_position, idle_position))

static func process_modules(game: Node, delta: float) -> void:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		room["neurostun_time_left"] = maxf(float(room.get("neurostun_time_left", 0.0)) - delta, 0.0)
		if not room["opened"] or not room["lit"]:
			game.rooms[room_coord] = room
			continue
		var slot_positions: Array = game.minor_slot_positions(room_coord)
		for module_index in range(room["minor_modules"].size()):
			var module_data: Dictionary = Dictionary(room["minor_modules"][module_index])
			if float(module_data["health"]) <= 0.0 or bool(module_data.get("under_construction", false)):
				continue
			module_data["cooldown"] = maxf(float(module_data["cooldown"]) - delta, 0.0)
			if float(module_data["cooldown"]) > 0.0:
				room["minor_modules"][module_index] = module_data
				continue
			var slot_index: int = int(module_data.get("slot_index", -1))
			if slot_index < 0 or slot_index >= slot_positions.size():
				room["minor_modules"][module_index] = module_data
				continue
			var slot_position: Vector2 = slot_positions[slot_index]
			var module_type: String = game.canonical_minor_module_type(String(module_data.get("type", game.MINOR_MODULE_TURRET)))
			module_data["type"] = module_type
			match module_type:
				game.MINOR_MODULE_PULSE:
					var gas_hit: bool = false
					for enemy in game.enemies:
						if not enemy_is_targetable_by_module(game, enemy, room_coord):
							continue
						var module_impact_direction: Vector2 = (enemy.global_position - slot_position).normalized()
						if module_impact_direction == Vector2.ZERO:
							module_impact_direction = (enemy.destination - slot_position).normalized()
						if module_impact_direction == Vector2.ZERO:
							module_impact_direction = Vector2.RIGHT
						enemy.take_damage(game.minor_module_damage(module_type), module_impact_direction)
						gas_hit = true
					if gas_hit:
						module_data["cooldown"] = game.minor_module_cooldown(module_type)
						game.projectiles.append({
							"kind": "gas_pulse",
							"position": slot_position,
							"previous": slot_position,
							"target_position": slot_position,
							"color": game.minor_module_color(module_type),
							"radius": 74.0,
							"impact_radius": 74.0,
							"lifetime_left": 0.24,
							"blast_duration": 0.24,
							"width": 3.0,
						})
				game.MINOR_MODULE_CANNON:
					var slow_target: Variant = nearest_enemy_for_module(game, room_coord, slot_position, 620.0)
					if slow_target != null:
						module_data["cooldown"] = game.minor_module_cooldown(module_type)
						room["neurostun_time_left"] = maxf(float(room.get("neurostun_time_left", 0.0)), 1.0 + float(game.minor_module_level(module_type)) * 0.12)
						game.projectiles.append({
							"kind": "gas_pulse",
							"position": slot_position,
							"previous": slot_position,
							"target_position": slot_position,
							"color": game.minor_module_color(module_type),
							"radius": 88.0,
							"impact_radius": 88.0,
							"lifetime_left": 0.2,
							"blast_duration": 0.2,
							"width": 2.0,
						})
				game.MINOR_MODULE_KIP:
					var kip_target: Variant = strongest_enemy_for_module(game, room_coord, slot_position, 620.0)
					if kip_target != null:
						module_data["cooldown"] = game.minor_module_cooldown(module_type)
						spawn_arrow_projectile(game, slot_position, kip_target, game.minor_module_damage(module_type), game.minor_module_color(module_type), game.minor_module_projectile_width(module_type), game.minor_module_projectile_speed(module_type))
				_:
					var turret_target: Variant = nearest_enemy_for_module(game, room_coord, slot_position, 620.0)
					if turret_target == null:
						room["minor_modules"][module_index] = module_data
						continue
					module_data["cooldown"] = game.minor_module_cooldown(module_type)
					spawn_arrow_projectile(game, slot_position, turret_target, game.minor_module_damage(module_type), game.minor_module_color(module_type), game.minor_module_projectile_width(module_type), game.minor_module_projectile_speed(module_type))
			room["minor_modules"][module_index] = module_data
		game.rooms[room_coord] = room

static func spawn_arrow_projectile(game: Node, origin: Vector2, target: Variant, damage: float, color: Color = Color("d8bf7a"), width: float = 2.4, speed: float = 950.0, bounces: int = 0, pierce: int = 0) -> void:
	var target_position: Vector2 = target.global_position if is_instance_valid(target) else origin
	var projectile: Dictionary = {
		"kind": "arrow",
		"position": origin,
		"previous": origin,
		"target": target,
		"target_position": target_position,
		"damage": damage,
		"speed": speed,
		"color": color,
		"width": width,
	}
	if bounces > 0 or pierce > 0:
		var direction: Vector2 = (target_position - origin).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		projectile["motion_mode"] = "linear"
		projectile["velocity"] = direction * maxf(speed, 1.0)
		projectile["room"] = game.room_at_world_position(origin)
		projectile["radius"] = maxf(width * 1.6, 6.0)
		projectile["pierce"] = maxi(0, pierce)
		projectile["max_pierce"] = int(projectile["pierce"]) + 1
		projectile["pierced_count"] = 0
		projectile["bounces"] = maxi(0, bounces)
		projectile["remaining_bounces"] = maxi(0, bounces)
		projectile["hit_enemy_uids"] = []
		projectile["expire_after_hit"] = false
		projectile["lifetime_left"] = maxf(origin.distance_to(target_position) / maxf(speed, 1.0) + 0.6, 0.35)
	game.projectiles.append(projectile)

static func spawn_laser_projectile(game: Node, origin: Vector2, target: Variant, damage: float, color: Color = Color("89f2ff"), width: float = 4.0, speed: float = 950.0, bounces: int = 0, pierce: int = 0) -> void:
	var target_position: Vector2 = target.global_position if is_instance_valid(target) else origin
	var projectile: Dictionary = {
		"kind": "laser",
		"position": origin,
		"previous": origin,
		"target": target,
		"target_position": target_position,
		"damage": damage,
		"speed": speed,
		"color": color,
		"width": width,
	}
	if bounces > 0 or pierce > 0:
		var direction: Vector2 = (target_position - origin).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		projectile["motion_mode"] = "linear"
		projectile["velocity"] = direction * maxf(speed, 1.0)
		projectile["room"] = game.room_at_world_position(origin)
		projectile["radius"] = maxf(width * 1.5, 7.0)
		projectile["pierce"] = maxi(0, pierce)
		projectile["max_pierce"] = int(projectile["pierce"]) + 1
		projectile["pierced_count"] = 0
		projectile["bounces"] = maxi(0, bounces)
		projectile["remaining_bounces"] = maxi(0, bounces)
		projectile["hit_enemy_uids"] = []
		projectile["expire_after_hit"] = false
		projectile["lifetime_left"] = maxf(origin.distance_to(target_position) / maxf(speed, 1.0) + 0.55, 0.3)
	game.projectiles.append(projectile)

static func spawn_magic_missile_projectile(game: Node, origin: Vector2, target: Variant, damage: float, color: Color = Color("c18dff"), width: float = 4.8, speed: float = 1180.0, curve_offset: float = 0.0) -> void:
	var target_position: Vector2 = target.global_position if is_instance_valid(target) else origin
	var target_direction: Vector2 = (target_position - origin).normalized()
	if target_direction == Vector2.ZERO:
		target_direction = Vector2.RIGHT
	var curve_sign: float = 1.0 if curve_offset >= 0.0 else -1.0
	var launch_direction: Vector2 = Vector2(-target_direction.y, target_direction.x) * curve_sign
	if launch_direction == Vector2.ZERO:
		launch_direction = Vector2.RIGHT * curve_sign
	game.projectiles.append({
		"kind": "magic_missile",
		"position": origin,
		"previous": origin,
		"target": target,
		"target_position": target_position,
		"damage": damage,
		"speed": speed,
		"color": color,
		"width": width,
		"velocity": Vector2.ZERO,
		"travel_direction": launch_direction,
		"current_speed": 0.0,
		"acceleration": maxf(speed * 2.6, 1500.0),
		"curve_turn_rate": 2.8,
		"glow_radius": 22.0,
		"hit_radius": 12.0,
	})

static func spawn_fire_bolt_projectile(game: Node, origin: Vector2, target: Variant, damage: float, color: Color = Color("ff8e47"), width: float = 4.4, speed: float = 1120.0, bounces: int = 0, pierce: int = 0) -> void:
	var target_position: Vector2 = target.global_position if is_instance_valid(target) else origin
	var projectile: Dictionary = {
		"kind": "fire_bolt",
		"position": origin,
		"previous": origin,
		"target": target,
		"target_position": target_position,
		"damage": damage,
		"speed": speed,
		"color": color,
		"width": width,
	}
	if bounces > 0 or pierce > 0:
		var direction: Vector2 = (target_position - origin).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		projectile["motion_mode"] = "linear"
		projectile["velocity"] = direction * maxf(speed, 1.0)
		projectile["room"] = game.room_at_world_position(origin)
		projectile["radius"] = maxf(width * 1.45, 7.0)
		projectile["pierce"] = maxi(0, pierce)
		projectile["max_pierce"] = int(projectile["pierce"]) + 1
		projectile["pierced_count"] = 0
		projectile["bounces"] = maxi(0, bounces)
		projectile["remaining_bounces"] = maxi(0, bounces)
		projectile["hit_enemy_uids"] = []
		projectile["expire_after_hit"] = false
		projectile["lifetime_left"] = maxf(origin.distance_to(target_position) / maxf(speed, 1.0) + 0.55, 0.3)
	game.projectiles.append(projectile)

static func apply_enemy_ranged_damage_to_hero(game: Node, hero: Variant, damage: float, source_label: String) -> void:
	if hero == null or not is_instance_valid(hero) or not game.hero_is_active(hero):
		return
	var defeated: bool = hero.take_damage(damage, false)
	if defeated and game.try_auto_cast_fatal_shield(hero, damage):
		return
	if defeated:
		game.finalize_hero_death(hero, source_label)

static func try_spawn_enemy_dust_drop(game: Node, enemy: Variant) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_meta("dust_drop_resolved"):
		return
	enemy.set_meta("dust_drop_resolved", true)
	var dust_drop_chance: float = GAME_ENEMY_DEFS.enemy_dust_drop_chance(String(enemy.enemy_role))
	if dust_drop_chance <= 0.0 or game.rng.randf() > dust_drop_chance:
		return
	game.dust += 1
	var drop_position: Vector2 = enemy.global_position + Vector2(0.0, -8.0)
	game.add_resource_floating_text(drop_position + Vector2(0.0, -10.0), "+1 Dust", Color("f3d88f"))
	game.projectiles.append({
		"kind": "dust_burst",
		"position": drop_position,
		"previous": drop_position,
		"target_position": drop_position,
		"color": Color("f3d88f"),
		"radius": 28.0,
		"impact_radius": 28.0,
		"lifetime_left": 0.34,
		"blast_duration": 0.34,
		"width": 2.0,
	})

static func advance_projectiles(game: Node, delta: float) -> void:
	var active_projectiles: Array = []
	for projectile in game.projectiles:
		var projectile_kind: String = String(projectile.get("kind", "laser"))
		if projectile_uses_linear_motion(projectile):
			projectile["lifetime_left"] = float(projectile.get("lifetime_left", projectile.get("lifetime", 2.2))) - delta
			if float(projectile["lifetime_left"]) <= 0.0:
				continue
			var previous_position: Vector2 = projectile.get("position", Vector2.ZERO)
			var current_position: Vector2 = previous_position
			var velocity: Vector2 = projectile.get("velocity", Vector2.ZERO)
			if velocity == Vector2.ZERO:
				var fallback_target: Vector2 = Vector2(projectile.get("target_position", current_position + Vector2.RIGHT))
				var fallback_direction: Vector2 = (fallback_target - current_position).normalized()
				if fallback_direction == Vector2.ZERO:
					fallback_direction = Vector2.RIGHT
				velocity = fallback_direction * maxf(float(projectile.get("speed", game.PROJECTILE_SPEED)), 1.0)
			var room_coord: Vector2i = projectile.get("room", game.INVALID_ROOM)
			if room_coord == game.INVALID_ROOM:
				room_coord = game.room_at_world_position(current_position)
				projectile["room"] = room_coord
			var room_bounds: Rect2 = game.room_rect(room_coord).grow(-14.0) if game.rooms.has(room_coord) else Rect2(current_position - Vector2(320.0, 220.0), Vector2(640.0, 440.0))
			var next_position: Vector2 = current_position + velocity * delta
			var remaining_bounces: int = projectile_numeric_bounces(projectile)
			var bounced: bool = false
			if next_position.x < room_bounds.position.x or next_position.x > room_bounds.end.x:
				if remaining_bounces <= 0:
					continue
				velocity.x *= -1.0
				next_position.x = clampf(next_position.x, room_bounds.position.x, room_bounds.end.x)
				remaining_bounces -= 1
				bounced = true
			if next_position.y < room_bounds.position.y or next_position.y > room_bounds.end.y:
				if remaining_bounces <= 0:
					continue
				velocity.y *= -1.0
				next_position.y = clampf(next_position.y, room_bounds.position.y, room_bounds.end.y)
				remaining_bounces -= 1
				bounced = true
			projectile["previous"] = previous_position
			projectile["position"] = next_position
			projectile["velocity"] = velocity
			projectile["remaining_bounces"] = remaining_bounces
			if not projectile.has("bounces"):
				projectile["bounces"] = remaining_bounces
			projectile["rotation_angle"] = float(projectile.get("rotation_angle", 0.0)) + float(projectile.get("spin_speed", 0.0)) * delta
			apply_card_projectile_hits(game, projectile)
			if bool(projectile.get("expire_after_hit", false)):
				continue
			if bounced and projectile_kind == "dagger":
				projectile["rotation_angle"] = velocity.angle()
			active_projectiles.append(projectile)
			continue
		if projectile_kind == "fireball_blast" or projectile_kind == "shield_flash" or projectile_kind == "lightning_bolt" or projectile_kind == "gas_pulse" or projectile_kind == "necromancer_attack_effect" or projectile_kind == "priest_heal_effect" or projectile_kind == "priest_attack_effect" or projectile_kind == "web_field" or projectile_kind == "ghostfire_ray" or projectile_kind == "dust_burst":
			projectile["lifetime_left"] = maxf(float(projectile.get("lifetime_left", 0.0)) - delta, 0.0)
			if float(projectile["lifetime_left"]) <= 0.0:
				continue
			active_projectiles.append(projectile)
			continue
		if projectile_kind == "magic_missile":
			var missile_position: Vector2 = projectile.get("position", Vector2.ZERO)
			var missile_target_position: Vector2 = projectile.get("target_position", missile_position)
			var missile_target: Variant = projectile.get("target", null)
			if game.enemy_is_active(missile_target):
				missile_target_position = missile_target.global_position
				projectile["target_position"] = missile_target_position
			elif game.hero_is_active(missile_target):
				missile_target_position = missile_target.global_position
				projectile["target_position"] = missile_target_position
			else:
				missile_target = null
			var missile_offset: Vector2 = missile_target_position - missile_position
			var missile_travel_direction: Vector2 = Vector2(projectile.get("travel_direction", Vector2.ZERO)).normalized()
			if missile_travel_direction == Vector2.ZERO:
				missile_travel_direction = Vector2(projectile.get("velocity", Vector2.ZERO)).normalized()
			var missile_speed: float = maxf(float(projectile.get("speed", 1180.0)), 1.0)
			var current_missile_speed: float = maxf(float(projectile.get("current_speed", missile_speed)), 1.0)
			current_missile_speed = move_toward(float(projectile.get("current_speed", 0.0)), missile_speed, float(projectile.get("acceleration", missile_speed * 3.0)) * delta)
			projectile["current_speed"] = current_missile_speed
			var missile_hit_radius: float = maxf(float(projectile.get("hit_radius", 12.0)), 6.0)
			if missile_offset.length() <= missile_hit_radius:
				if game.enemy_is_active(missile_target):
					var missile_impact_direction: Vector2 = missile_offset.normalized()
					if missile_impact_direction == Vector2.ZERO:
						missile_impact_direction = missile_travel_direction
					if missile_impact_direction == Vector2.ZERO:
						missile_impact_direction = Vector2.RIGHT
					missile_target.take_damage(float(projectile.get("damage", 0.0)), missile_impact_direction)
				elif game.hero_is_active(missile_target):
					apply_enemy_ranged_damage_to_hero(game, missile_target, float(projectile.get("damage", 0.0)), String(projectile.get("source_label", "A magic missile")))
				continue
			var desired_direction: Vector2 = missile_offset.normalized()
			var stored_direction: Vector2 = Vector2(projectile.get("travel_direction", desired_direction))
			if stored_direction == Vector2.ZERO:
				stored_direction = desired_direction
			var missile_velocity: Vector2 = Vector2(projectile.get("velocity", stored_direction * current_missile_speed))
			if missile_velocity == Vector2.ZERO and current_missile_speed > 0.0:
				missile_velocity = stored_direction * current_missile_speed
			var close_assist_distance: float = maxf(34.0, current_missile_speed * delta * 2.4)
			projectile["previous"] = missile_position
			if missile_offset.length() <= close_assist_distance:
				var assisted_position: Vector2 = missile_position.move_toward(missile_target_position, current_missile_speed * delta)
				projectile["position"] = assisted_position
				projectile["velocity"] = desired_direction * current_missile_speed
				projectile["travel_direction"] = desired_direction
				if assisted_position.distance_to(missile_target_position) <= missile_hit_radius or game.point_distance_to_segment(missile_target_position, missile_position, assisted_position) <= missile_hit_radius:
					if game.enemy_is_active(missile_target):
						missile_target.take_damage(float(projectile.get("damage", 0.0)), desired_direction)
					elif game.hero_is_active(missile_target):
						apply_enemy_ranged_damage_to_hero(game, missile_target, float(projectile.get("damage", 0.0)), String(projectile.get("source_label", "A magic missile")))
					continue
				active_projectiles.append(projectile)
				continue
			var steer_target_velocity: Vector2 = desired_direction * maxf(current_missile_speed, 0.001)
			missile_velocity = missile_velocity.move_toward(steer_target_velocity, maxf(current_missile_speed, 24.0) * float(projectile.get("curve_turn_rate", 8.5)) * delta)
			var missile_step: float = minf(current_missile_speed * delta, missile_offset.length())
			var missile_next_position: Vector2 = missile_position + missile_velocity.normalized() * missile_step
			if missile_next_position.distance_to(missile_target_position) <= missile_hit_radius or game.point_distance_to_segment(missile_target_position, missile_position, missile_next_position) <= missile_hit_radius:
				if game.enemy_is_active(missile_target):
					var missile_finish_direction: Vector2 = missile_velocity.normalized()
					if missile_finish_direction == Vector2.ZERO:
						missile_finish_direction = desired_direction
					if missile_finish_direction == Vector2.ZERO:
						missile_finish_direction = missile_travel_direction
					if missile_finish_direction == Vector2.ZERO:
						missile_finish_direction = Vector2.RIGHT
					missile_target.take_damage(float(projectile.get("damage", 0.0)), missile_finish_direction)
				elif game.hero_is_active(missile_target):
					apply_enemy_ranged_damage_to_hero(game, missile_target, float(projectile.get("damage", 0.0)), String(projectile.get("source_label", "A magic missile")))
				continue
			projectile["position"] = missile_next_position
			projectile["velocity"] = missile_velocity
			projectile["travel_direction"] = missile_velocity.normalized() if missile_velocity.length() > 0.001 else stored_direction
			active_projectiles.append(projectile)
			continue
		var current_position_simple: Vector2 = projectile["position"]
		var previous_position_simple: Vector2 = projectile.get("previous", current_position_simple)
		var target_position: Vector2 = projectile["target_position"]
		var target: Variant = projectile["target"]
		if game.enemy_is_active(target):
			target_position = target.global_position
			projectile["target_position"] = target_position
		elif game.hero_is_active(target):
			target_position = target.global_position
			projectile["target_position"] = target_position
		else:
			target = null
		var offset: Vector2 = target_position - current_position_simple
		if offset.length() <= 6.0:
			if game.enemy_is_active(target):
				var impact_direction_simple: Vector2 = offset.normalized()
				if impact_direction_simple == Vector2.ZERO:
					impact_direction_simple = (current_position_simple - previous_position_simple).normalized()
				if impact_direction_simple == Vector2.ZERO:
					impact_direction_simple = Vector2(projectile.get("velocity", Vector2.ZERO)).normalized()
				if impact_direction_simple == Vector2.ZERO:
					impact_direction_simple = Vector2.RIGHT
				target.take_damage(float(projectile["damage"]), impact_direction_simple)
			elif game.hero_is_active(target):
				apply_enemy_ranged_damage_to_hero(game, target, float(projectile.get("damage", 0.0)), String(projectile.get("source_label", "A ranged attack")))
			continue
		var travel_distance: float = minf(float(projectile["speed"]) * delta, offset.length())
		projectile["previous"] = current_position_simple
		projectile["position"] = current_position_simple + offset.normalized() * travel_distance
		active_projectiles.append(projectile)
	game.projectiles = active_projectiles

static func draw_projectiles(game: Node, canvas: CanvasItem = null) -> void:
	var surface: CanvasItem = canvas if canvas != null else game
	var view_rect: Rect2 = game.current_view_world_rect(140.0)
	for projectile in game.projectiles:
		var previous: Vector2 = projectile["previous"]
		var current_position: Vector2 = projectile["position"]
		if not view_rect.has_point(current_position) and not view_rect.has_point(previous):
			continue
		var color: Color = projectile["color"]
		var width: float = float(projectile.get("width", 4.0))
		var projectile_kind: String = String(projectile.get("kind", "laser"))
		if projectile_kind == "axe":
			var angle: float = float(projectile.get("rotation_angle", 0.0))
			var radius: float = float(projectile.get("radius", 17.0))
			surface.draw_circle(current_position, radius * 0.55, color)
			surface.draw_line(current_position + Vector2.RIGHT.rotated(angle) * radius, current_position - Vector2.RIGHT.rotated(angle) * radius, color.lightened(0.18), 5.0, true)
			surface.draw_line(current_position + Vector2.UP.rotated(angle) * (radius * 0.8), current_position - Vector2.UP.rotated(angle) * (radius * 0.8), Color("fff7cf"), 3.0, true)
			continue
		if projectile_kind == "dagger":
			var velocity: Vector2 = Vector2(projectile.get("velocity", Vector2.RIGHT))
			var direction: Vector2 = velocity.normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT
			var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
			var tip: Vector2 = current_position + direction * 12.0
			var tail_left: Vector2 = current_position - direction * 8.0 + perpendicular * 4.0
			var tail_right: Vector2 = current_position - direction * 8.0 - perpendicular * 4.0
			surface.draw_colored_polygon(PackedVector2Array([tip, tail_left, tail_right]), color)
			surface.draw_line(current_position - direction * 10.0, current_position + direction * 4.0, Color("eff8ff"), 2.0, true)
			continue
		if projectile_kind == "arrow":
			var arrow_target: Vector2 = current_position - previous
			var arrow_direction: Vector2 = arrow_target.normalized()
			if arrow_direction == Vector2.ZERO:
				arrow_direction = Vector2.RIGHT
			var arrow_perp: Vector2 = Vector2(-arrow_direction.y, arrow_direction.x)
			var arrow_tip: Vector2 = current_position + arrow_direction * 9.0
			var arrow_tail_left: Vector2 = current_position - arrow_direction * 8.0 + arrow_perp * 2.8
			var arrow_tail_right: Vector2 = current_position - arrow_direction * 8.0 - arrow_perp * 2.8
			surface.draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_tail_left, arrow_tail_right]), color)
			surface.draw_line(current_position - arrow_direction * 12.0, current_position + arrow_direction * 4.0, Color("fff6d3"), maxf(width, 1.4), true)
			continue
		if projectile_kind == "fire_bolt":
			var bolt_delta: Vector2 = current_position - previous
			var bolt_direction: Vector2 = bolt_delta.normalized()
			if bolt_direction == Vector2.ZERO:
				bolt_direction = Vector2.RIGHT
			surface.draw_line(previous, current_position, Color(color.r, color.g, color.b, 0.85), maxf(width + 1.2, 3.2), true)
			surface.draw_line(previous, current_position, Color(1.0, 0.89, 0.68, 0.72), maxf(width * 0.45, 1.6), true)
			var fire_bolt_frame: int = animated_effect_frame_index(WIZARD_FIRE_BOLT_EFFECT, 0.052)
			draw_effect_strip(surface, WIZARD_FIRE_BOLT_EFFECT, fire_bolt_frame, current_position, Vector2(30.0, 30.0), Color(color.r, color.g, color.b, 0.95))
			surface.draw_circle(current_position, maxf(width * 0.55, 2.4), Color("ffe7b0"))
			var ember_tail: Vector2 = current_position - bolt_direction * 8.0
			surface.draw_circle(ember_tail, maxf(width * 0.42, 2.0), Color(1.0, 0.52, 0.20, 0.34))
			continue
		if projectile_kind == "magic_missile":
			var missile_delta: Vector2 = current_position - previous
			var missile_direction: Vector2 = missile_delta.normalized()
			if missile_direction == Vector2.ZERO:
				missile_direction = Vector2(projectile.get("travel_direction", Vector2.RIGHT)).normalized()
				if missile_direction == Vector2.ZERO:
					missile_direction = Vector2.RIGHT
			var missile_glow_radius: float = maxf(float(projectile.get("glow_radius", 14.0)), width * 1.9)
			surface.draw_line(previous, current_position, Color(color.r, color.g, color.b, 0.34), width + 12.0, true)
			surface.draw_line(previous, current_position, Color(color.r, color.g, color.b, 0.72), width + 5.5, true)
			surface.draw_line(previous, current_position, Color(1.0, 0.94, 1.0, 0.96), maxf(width * 0.72, 2.4), true)
			surface.draw_circle(current_position, missile_glow_radius, Color(color.r, color.g, color.b, 0.18))
			surface.draw_circle(current_position, missile_glow_radius * 0.74, Color(color.r, color.g, color.b, 0.32))
			surface.draw_circle(current_position, missile_glow_radius * 0.42, Color(1.0, 0.92, 1.0, 0.16))
			draw_effect_strip(surface, WIZARD_FIRE_BOLT_EFFECT, animated_effect_frame_index(WIZARD_FIRE_BOLT_EFFECT, 0.048), current_position, Vector2(24.0, 24.0), Color(color.r, color.g, color.b, 1.0))
			surface.draw_circle(current_position + missile_direction * 1.5, maxf(width * 0.72, 2.9), Color("fff2ff"))
			continue
		if projectile_kind == "fireball_blast":
			var duration: float = maxf(float(projectile.get("blast_duration", 0.24)), 0.001)
			var life_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / duration, 0.0, 1.0)
			var blast_radius: float = lerpf(10.0, float(projectile.get("impact_radius", projectile.get("radius", 92.0))), life_ratio)
			var blast_color: Color = color
			blast_color.a = 0.32 * (1.0 - life_ratio)
			surface.draw_circle(current_position, blast_radius, blast_color)
			surface.draw_arc(current_position, blast_radius, 0.0, TAU, 44, color.lightened(0.18), maxf(width * (1.0 - life_ratio * 0.35), 2.0), true)
			surface.draw_circle(current_position, blast_radius * 0.42, Color(1.0, 0.95, 0.78, 0.18 * (1.0 - life_ratio)))
			continue
		if projectile_kind == "shield_flash":
			var shield_duration: float = maxf(float(projectile.get("blast_duration", 0.22)), 0.001)
			var shield_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / shield_duration, 0.0, 1.0)
			var shield_radius: float = lerpf(16.0, float(projectile.get("radius", 34.0)), shield_ratio)
			surface.draw_circle(current_position, shield_radius * 1.08, Color(color.r, color.g, color.b, 0.14 * (1.0 - shield_ratio * 0.35)))
			surface.draw_circle(current_position, shield_radius * 0.72, Color(color.r, color.g, color.b, 0.18 * (1.0 - shield_ratio * 0.45)))
			surface.draw_arc(current_position, shield_radius, 0.0, TAU, 44, Color(color.r, color.g, color.b, 0.88 - shield_ratio * 0.52), maxf(width * (1.15 - shield_ratio * 0.25), 2.1), true)
			surface.draw_arc(current_position, shield_radius * 0.82, 0.0, TAU, 36, Color(0.9, 0.97, 1.0, 0.62 - shield_ratio * 0.35), maxf(width * 0.6, 1.3), true)
			continue
		if projectile_kind == "lightning_bolt":
			var bolt_duration: float = maxf(float(projectile.get("blast_duration", 0.18)), 0.001)
			var bolt_ratio: float = clampf(float(projectile.get("lifetime_left", 0.0)) / bolt_duration, 0.0, 1.0)
			var bolt_points: Array = Array(projectile.get("points", []))
			if bolt_points.size() >= 2:
				for point_index in range(1, bolt_points.size()):
					var segment_start: Vector2 = Vector2(bolt_points[point_index - 1])
					var segment_end: Vector2 = Vector2(bolt_points[point_index])
					surface.draw_line(segment_start, segment_end, Color(1.0, 0.98, 0.86, 0.95 * bolt_ratio), width + 3.0, true)
					surface.draw_line(segment_start, segment_end, Color(color.r, color.g, color.b, 0.9 * bolt_ratio), width, true)
			else:
				var origin: Vector2 = projectile.get("previous", current_position)
				surface.draw_line(origin, current_position, Color(1.0, 0.98, 0.86, 0.95 * bolt_ratio), width + 3.0, true)
				surface.draw_line(origin, current_position, Color(color.r, color.g, color.b, 0.9 * bolt_ratio), width, true)
			surface.draw_circle(current_position, 6.0 + 6.0 * bolt_ratio, Color(color.r, color.g, color.b, 0.38))
			continue
		if projectile_kind == "gas_pulse":
			var gas_duration: float = maxf(float(projectile.get("blast_duration", 0.22)), 0.001)
			var gas_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / gas_duration, 0.0, 1.0)
			var gas_radius: float = lerpf(18.0, float(projectile.get("impact_radius", projectile.get("radius", 72.0))), gas_ratio)
			surface.draw_circle(current_position, gas_radius, Color(color.r, color.g, color.b, 0.10 * (1.0 - gas_ratio)))
			surface.draw_arc(current_position, gas_radius, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.55 * (1.0 - gas_ratio * 0.4)), maxf(width, 2.0), true)
			continue
		if projectile_kind == "web_field":
			var web_duration: float = maxf(float(projectile.get("blast_duration", 0.6)), 0.001)
			var web_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / web_duration, 0.0, 1.0)
			var web_radius: float = lerpf(float(projectile.get("impact_radius", 96.0)) * 0.36, float(projectile.get("impact_radius", 96.0)), web_ratio)
			var web_alpha: float = 0.55 * (1.0 - web_ratio * 0.55)
			surface.draw_circle(current_position, web_radius, Color(color.r, color.g, color.b, 0.06 * web_alpha))
			surface.draw_arc(current_position, web_radius, 0.0, TAU, 30, Color(color.r, color.g, color.b, web_alpha), 2.0, true)
			for spoke_index in range(6):
				var spoke_angle: float = TAU * float(spoke_index) / 6.0 + web_ratio * 0.22
				var spoke_dir: Vector2 = Vector2.RIGHT.rotated(spoke_angle)
				surface.draw_line(current_position - spoke_dir * web_radius * 0.72, current_position + spoke_dir * web_radius * 0.72, Color(0.96, 0.99, 1.0, 0.32 * web_alpha), 1.8, true)
			continue
		if projectile_kind == "ghostfire_ray":
			var ray_duration: float = maxf(float(projectile.get("blast_duration", 0.22)), 0.001)
			var ray_ratio: float = clampf(float(projectile.get("lifetime_left", 0.0)) / ray_duration, 0.0, 1.0)
			var ray_origin: Vector2 = projectile.get("previous", current_position)
			draw_effect_strip_along_line(surface, GHOSTFIRE_BEAM_EFFECT, lifetime_effect_frame_index(projectile, GHOSTFIRE_BEAM_EFFECT), ray_origin, current_position, maxf(width, 12.0), Color(color.r, color.g, color.b, 0.95 * ray_ratio))
			surface.draw_circle(current_position, 12.0 * ray_ratio, Color(color.r, color.g, color.b, 0.24))
			surface.draw_circle(current_position, 5.5, Color("fff2cf"))
			continue
		if projectile_kind == "dust_burst":
			var dust_duration: float = maxf(float(projectile.get("blast_duration", 0.36)), 0.001)
			var dust_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / dust_duration, 0.0, 1.0)
			var dust_radius: float = lerpf(8.0, float(projectile.get("impact_radius", 28.0)), dust_ratio)
			var dust_alpha: float = 1.0 - dust_ratio
			surface.draw_circle(current_position, dust_radius, Color(color.r, color.g, color.b, 0.22 * dust_alpha))
			surface.draw_arc(current_position, dust_radius, 0.0, TAU, 26, Color(color.r, color.g, color.b, 0.9 * dust_alpha), 2.2, true)
			for spark_index in range(6):
				var spark_angle: float = TAU * float(spark_index) / 6.0 + dust_ratio * 0.65
				var spark_dir: Vector2 = Vector2.RIGHT.rotated(spark_angle)
				var spark_start: Vector2 = current_position + spark_dir * (dust_radius * 0.4)
				var spark_end: Vector2 = current_position + spark_dir * (dust_radius + 5.0)
				surface.draw_line(spark_start, spark_end, Color(1.0, 0.95, 0.78, 0.72 * dust_alpha), 1.7, true)
			continue
		if projectile_kind == "necromancer_attack_effect":
			var necromancer_frame: int = lifetime_effect_frame_index(projectile, NECROMANCER_ATTACK_EFFECT)
			draw_effect_strip(surface, NECROMANCER_ATTACK_EFFECT, necromancer_frame, current_position, Vector2(108.0, 108.0), Color(color.r, color.g, color.b, 1.0))
			surface.draw_circle(current_position, 14.0, Color(color.r, color.g, color.b, 0.12))
			continue
		if projectile_kind == "priest_heal_effect":
			var priest_heal_frame: int = lifetime_effect_frame_index(projectile, PRIEST_HEAL_EFFECT)
			surface.draw_circle(current_position, 34.0, Color(color.r, color.g, color.b, 0.20))
			surface.draw_circle(current_position, 22.0, Color(0.96, 1.0, 0.94, 0.28))
			surface.draw_arc(current_position, 30.0, 0.0, TAU, 30, Color(0.90, 1.0, 0.92, 0.44), 2.8, true)
			draw_effect_strip(surface, PRIEST_HEAL_EFFECT, priest_heal_frame, current_position, Vector2(220.0, 220.0), Color(1.0, 1.0, 1.0, 0.98))
			draw_effect_strip(surface, PRIEST_HEAL_EFFECT, priest_heal_frame, current_position, Vector2(176.0, 176.0), Color(color.r, color.g, color.b, 0.92))
			continue
		if projectile_kind == "priest_attack_effect":
			var priest_attack_frame: int = lifetime_effect_frame_index(projectile, PRIEST_ATTACK_EFFECT)
			draw_effect_strip(surface, PRIEST_ATTACK_EFFECT, priest_attack_frame, current_position, Vector2(58.0, 58.0), Color(color.r, color.g, color.b, 0.92))
			continue
		surface.draw_line(previous, current_position, color, width, true)
		surface.draw_circle(current_position, 3.0, color)

static func effect_frame_count(texture: Texture2D) -> int:
	if texture == null:
		return 1
	return maxi(int(texture.get_width() / float(EFFECT_FRAME_SIZE.x)), 1)

static func animated_effect_frame_index(texture: Texture2D, seconds_per_frame: float = 0.06) -> int:
	var frame_count: int = effect_frame_count(texture)
	if frame_count <= 1:
		return 0
	return int(floor(float(Time.get_ticks_msec()) / maxf(seconds_per_frame * 1000.0, 1.0))) % frame_count

static func lifetime_effect_frame_index(projectile: Dictionary, texture: Texture2D) -> int:
	var frame_count: int = effect_frame_count(texture)
	if frame_count <= 1:
		return 0
	var duration: float = maxf(float(projectile.get("blast_duration", projectile.get("lifetime_left", 0.2))), 0.001)
	var life_left: float = clampf(float(projectile.get("lifetime_left", 0.0)), 0.0, duration)
	var elapsed_ratio: float = 1.0 - (life_left / duration)
	return clampi(int(floor(elapsed_ratio * float(frame_count))), 0, frame_count - 1)

static func draw_effect_strip(surface: CanvasItem, texture: Texture2D, frame_index: int, world_position: Vector2, draw_size: Vector2, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	var frame_count: int = effect_frame_count(texture)
	var clamped_index: int = clampi(frame_index, 0, frame_count - 1)
	var source_rect: Rect2 = Rect2(float(clamped_index * EFFECT_FRAME_SIZE.x), 0.0, float(EFFECT_FRAME_SIZE.x), float(EFFECT_FRAME_SIZE.y))
	var draw_rect: Rect2 = Rect2(world_position - draw_size * 0.5, draw_size)
	surface.draw_texture_rect_region(texture, draw_rect, source_rect, modulate, false, true)

static func draw_effect_strip_along_line(surface: CanvasItem, texture: Texture2D, frame_index: int, from_position: Vector2, to_position: Vector2, beam_width: float, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	var segment: Vector2 = to_position - from_position
	var beam_length: float = segment.length()
	if beam_length <= 0.001:
		return
	var angle: float = segment.angle()
	var frame_count: int = effect_frame_count(texture)
	var clamped_index: int = clampi(frame_index, 0, frame_count - 1)
	var source_rect: Rect2 = Rect2(float(clamped_index * EFFECT_FRAME_SIZE.x), 0.0, float(EFFECT_FRAME_SIZE.x), float(EFFECT_FRAME_SIZE.y))
	surface.draw_set_transform(from_position, angle, Vector2.ONE)
	surface.draw_texture_rect_region(texture, Rect2(0.0, -beam_width * 0.5, beam_length, beam_width), source_rect, modulate, false, true)
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func nearest_enemy_in_room(game: Node, room_coord: Vector2i, origin: Vector2, max_range: float) -> Variant:
	var closest_enemy: Variant = null
	var closest_distance: float = max_range
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != room_coord or enemy.moving_between_rooms:
			continue
		var distance: float = origin.distance_to(enemy.global_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	return closest_enemy

static func strongest_enemy_in_room(game: Node, room_coord: Vector2i, origin: Vector2, max_range: float) -> Variant:
	var chosen_enemy: Variant = null
	var chosen_health: float = -1.0
	var chosen_distance: float = max_range
	for enemy in game.enemies:
		if not game.enemy_is_active(enemy) or enemy.current_room != room_coord or enemy.moving_between_rooms:
			continue
		var distance_value: float = origin.distance_to(enemy.global_position)
		if distance_value > max_range:
			continue
		var health_value: float = float(enemy.current_health)
		if chosen_enemy == null or health_value > chosen_health or (is_equal_approx(health_value, chosen_health) and distance_value < chosen_distance):
			chosen_enemy = enemy
			chosen_health = health_value
			chosen_distance = distance_value
	return chosen_enemy

static func enemy_is_targetable_by_module(game: Node, enemy: Variant, room_coord: Vector2i) -> bool:
	if not game.enemy_is_active(enemy):
		return false
	return enemy.current_room == room_coord or enemy.pending_room == room_coord or enemy.next_room == room_coord

static func nearest_enemy_for_module(game: Node, room_coord: Vector2i, origin: Vector2, max_range: float) -> Variant:
	var closest_enemy: Variant = null
	var closest_distance: float = max_range
	for enemy in game.enemies:
		if not enemy_is_targetable_by_module(game, enemy, room_coord):
			continue
		var distance_value: float = origin.distance_to(enemy.global_position)
		if distance_value <= closest_distance:
			closest_distance = distance_value
			closest_enemy = enemy
	return closest_enemy

static func strongest_enemy_for_module(game: Node, room_coord: Vector2i, origin: Vector2, max_range: float) -> Variant:
	var chosen_enemy: Variant = null
	var chosen_health: float = -1.0
	var chosen_distance: float = max_range
	for enemy in game.enemies:
		if not enemy_is_targetable_by_module(game, enemy, room_coord):
			continue
		var distance_value: float = origin.distance_to(enemy.global_position)
		if distance_value > max_range:
			continue
		var health_value: float = float(enemy.current_health)
		if chosen_enemy == null or health_value > chosen_health or (is_equal_approx(health_value, chosen_health) and distance_value < chosen_distance):
			chosen_enemy = enemy
			chosen_health = health_value
			chosen_distance = distance_value
	return chosen_enemy

static func cleanup_enemies(game: Node) -> void:
	var alive_enemies: Array = []
	for enemy in game.enemies:
		if is_instance_valid(enemy):
			if enemy.current_health <= 0.0:
				try_spawn_enemy_dust_drop(game, enemy)
			alive_enemies.append(enemy)
	game.enemies = alive_enemies
