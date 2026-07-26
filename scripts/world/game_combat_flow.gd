extends RefCounted

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
	game.pending_enemy_spawns.append({
		"room": room_coord,
		"remaining": spawn_plan.size(),
		"delay_left": room_delay,
		"interval": game.WAVE_STAGGER_ENEMY_INTERVAL,
		"total_count": spawn_plan.size(),
		"spawned": 0,
		"plan": spawn_plan,
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
			var spawn_index: int = int(pending_spawn.get("spawned", 0))
			if spawn_index < 0 or spawn_index >= plan.size():
				break
			spawn_wave_enemy(game, Vector2i(pending_spawn["room"]), String(plan[spawn_index]))
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
	game.pending_enemy_spawns.append({
		"room": room_coord,
		"remaining": spawn_plan.size(),
		"delay_left": game.CRYSTAL_PRESSURE_WARNING_DURATION,
		"interval": game.WAVE_STAGGER_ENEMY_INTERVAL,
		"total_count": spawn_plan.size(),
		"spawned": 0,
		"plan": spawn_plan,
	})

static func enemy_pack_size(game: Node, enemy_type: String) -> int:
	match enemy_type:
		game.ENEMY_TYPE_LIZARDMAN:
			return 1
		game.ENEMY_TYPE_GOBLIN:
			return 5
		game.ENEMY_TYPE_BAT:
			return 6
		game.ENEMY_TYPE_SKELETON_ARCHER:
			return 2
		game.ENEMY_TYPE_GOLEM:
			return 1
		game.ENEMY_TYPE_GOBLIN_SHAMAN:
			return 2
		_:
			return 1

static func enemy_wave_point_cost(game: Node, enemy_type: String) -> int:
	match enemy_type:
		game.ENEMY_TYPE_GOLEM:
			return 2
		_:
			return 1

static func enemy_spawn_weight(game: Node, enemy_type: String, pressure_spawn: bool = false) -> float:
	match enemy_type:
		game.ENEMY_TYPE_LIZARDMAN:
			return 1.1 if not pressure_spawn else 0.9
		game.ENEMY_TYPE_GOBLIN:
			return 3.4 if not pressure_spawn else 2.8
		game.ENEMY_TYPE_BAT:
			return 2.8 if not pressure_spawn else 3.2
		game.ENEMY_TYPE_SKELETON_ARCHER:
			return 1.4 if not pressure_spawn else 1.1
		game.ENEMY_TYPE_GOLEM:
			return 0.42 if not pressure_spawn else 0.36
		game.ENEMY_TYPE_GOBLIN_SHAMAN:
			return 0.72 if not pressure_spawn else 0.54
		_:
			return 1.0

static func weighted_enemy_type_choice(game: Node, candidates: Array[String], pressure_spawn: bool = false) -> String:
	if candidates.is_empty():
		return game.ENEMY_TYPE_GOBLIN
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
		for enemy_type in [game.ENEMY_TYPE_GOBLIN, game.ENEMY_TYPE_BAT, game.ENEMY_TYPE_SKELETON_ARCHER, game.ENEMY_TYPE_GOBLIN_SHAMAN, game.ENEMY_TYPE_LIZARDMAN, game.ENEMY_TYPE_GOLEM]:
			if game.floor_index == 1 and enemy_type == game.ENEMY_TYPE_GOLEM:
				continue
			if enemy_wave_point_cost(game, enemy_type) <= remaining:
				candidates.append(enemy_type)
		if candidates.is_empty():
			candidates = [game.ENEMY_TYPE_GOBLIN]
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

static func spawn_wave_enemy(game: Node, room_coord: Vector2i, enemy_type: String) -> void:
	var enemy: Variant = game.ENEMY_SCENE.instantiate()
	game.enemy_layer.add_child(enemy)
	enemy.enemy_uid = game.next_enemy_uid
	game.next_enemy_uid += 1
	var spawn_position: Vector2 = game.random_walkable_point(room_coord)
	enemy.global_position = spawn_position
	enemy.reset_physics_interpolation()
	enemy.set_role(enemy_type)
	enemy.current_room = room_coord
	enemy.previous_room = room_coord
	enemy.next_room = room_coord
	enemy.set_destination(spawn_position)
	game.enemies.append(enemy)

static func apply_card_projectile_hits(game: Node, projectile: Dictionary) -> void:
	var projectile_kind: String = String(projectile.get("kind", ""))
	if projectile_kind != "axe" and projectile_kind != "dagger":
		return
	var room_coord: Vector2i = projectile.get("room", game.INVALID_ROOM)
	var previous: Vector2 = projectile.get("previous", projectile.get("position", Vector2.ZERO))
	var current: Vector2 = projectile.get("position", Vector2.ZERO)
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
		enemy.take_damage(damage)
		already_hit.append(int(enemy.enemy_uid))
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
				game.issue_hero_steps(hero, game.build_steps_for_path([hero.current_room], hero.global_position, desired_position))
				continue
			hero.move_steps.clear()
			hero.set_destination(hero.global_position)
			hero.trigger_attack(melee_target.global_position, hero.preferred_attack_style)
			game.queue_pending_melee_attack(hero, melee_target, hero.attack_damage, hero.melee_impact_delay(), hero.hero_name)
			hero.cooldown_left = hero.attack_cooldown
			continue
		var hero_target: Variant = nearest_enemy_in_room(game, hero.current_room, hero.global_position, hero.attack_range)
		if hero_target != null:
			hero.trigger_attack(hero_target.global_position, hero.preferred_attack_style)
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
		game.issue_hero_steps(hero, game.build_steps_for_path([hero.current_room], hero.global_position, idle_position))

static func process_modules(game: Node, delta: float) -> void:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		room["neurostun_time_left"] = maxf(float(room.get("neurostun_time_left", 0.0)) - delta, 0.0)
		if not room["opened"] or not room["lit"]:
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
						if not game.enemy_is_active(enemy) or enemy.current_room != room_coord:
							continue
						enemy.take_damage(game.minor_module_damage(module_type))
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
					var slow_target: Variant = nearest_enemy_in_room(game, room_coord, slot_position, 620.0)
					if slow_target != null:
						module_data["cooldown"] = game.minor_module_cooldown(module_type)
						game.rooms[room_coord]["neurostun_time_left"] = maxf(float(game.rooms[room_coord].get("neurostun_time_left", 0.0)), 1.0 + float(game.minor_module_level(module_type)) * 0.12)
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
					var kip_target: Variant = strongest_enemy_in_room(game, room_coord, slot_position, 620.0)
					if kip_target != null:
						module_data["cooldown"] = game.minor_module_cooldown(module_type)
						spawn_arrow_projectile(game, slot_position, kip_target, game.minor_module_damage(module_type), game.minor_module_color(module_type), game.minor_module_projectile_width(module_type), game.minor_module_projectile_speed(module_type))
				_:
					var turret_target: Variant = nearest_enemy_in_room(game, room_coord, slot_position, 620.0)
					if turret_target == null:
						room["minor_modules"][module_index] = module_data
						continue
					module_data["cooldown"] = game.minor_module_cooldown(module_type)
					spawn_arrow_projectile(game, slot_position, turret_target, game.minor_module_damage(module_type), game.minor_module_color(module_type), game.minor_module_projectile_width(module_type), game.minor_module_projectile_speed(module_type))
			room["minor_modules"][module_index] = module_data

static func spawn_arrow_projectile(game: Node, origin: Vector2, target: Variant, damage: float, color: Color = Color("d8bf7a"), width: float = 2.4, speed: float = 950.0) -> void:
	game.projectiles.append({
		"kind": "arrow",
		"position": origin,
		"previous": origin,
		"target": target,
		"target_position": target.global_position if is_instance_valid(target) else origin,
		"damage": damage,
		"speed": speed,
		"color": color,
		"width": width,
	})

static func spawn_laser_projectile(game: Node, origin: Vector2, target: Variant, damage: float, color: Color = Color("89f2ff"), width: float = 4.0, speed: float = 950.0) -> void:
	game.projectiles.append({
		"kind": "laser",
		"position": origin,
		"previous": origin,
		"target": target,
		"target_position": target.global_position if is_instance_valid(target) else origin,
		"damage": damage,
		"speed": speed,
		"color": color,
		"width": width,
	})

static func advance_projectiles(game: Node, delta: float) -> void:
	var active_projectiles: Array = []
	for projectile in game.projectiles:
		var projectile_kind: String = String(projectile.get("kind", "laser"))
		if projectile_kind == "axe" or projectile_kind == "dagger":
			projectile["lifetime_left"] = float(projectile.get("lifetime_left", 0.0)) - delta
			if float(projectile["lifetime_left"]) <= 0.0:
				continue
			var previous_position: Vector2 = projectile.get("position", Vector2.ZERO)
			var current_position: Vector2 = previous_position
			var velocity: Vector2 = projectile.get("velocity", Vector2.ZERO)
			var room_coord: Vector2i = projectile.get("room", game.INVALID_ROOM)
			var room_bounds: Rect2 = game.room_rect(room_coord).grow(-14.0) if game.rooms.has(room_coord) else Rect2(current_position - Vector2(320.0, 220.0), Vector2(640.0, 440.0))
			var next_position: Vector2 = current_position + velocity * delta
			var remaining_bounces: int = int(projectile.get("remaining_bounces", 0))
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
			projectile["rotation_angle"] = float(projectile.get("rotation_angle", 0.0)) + float(projectile.get("spin_speed", 0.0)) * delta
			apply_card_projectile_hits(game, projectile)
			if bounced and projectile_kind == "dagger":
				projectile["rotation_angle"] = velocity.angle()
			active_projectiles.append(projectile)
			continue
		if projectile_kind == "fireball_blast" or projectile_kind == "shield_flash" or projectile_kind == "lightning_bolt" or projectile_kind == "gas_pulse":
			projectile["lifetime_left"] = maxf(float(projectile.get("lifetime_left", 0.0)) - delta, 0.0)
			if float(projectile["lifetime_left"]) <= 0.0:
				continue
			active_projectiles.append(projectile)
			continue
		var current_position_simple: Vector2 = projectile["position"]
		var target_position: Vector2 = projectile["target_position"]
		var target: Variant = projectile["target"]
		if game.enemy_is_active(target):
			target_position = target.global_position
			projectile["target_position"] = target_position
		else:
			target = null
		var offset: Vector2 = target_position - current_position_simple
		if offset.length() <= 6.0:
			if game.enemy_is_active(target):
				target.take_damage(float(projectile["damage"]))
			continue
		var travel_distance: float = minf(float(projectile["speed"]) * delta, offset.length())
		projectile["previous"] = current_position_simple
		projectile["position"] = current_position_simple + offset.normalized() * travel_distance
		active_projectiles.append(projectile)
	game.projectiles = active_projectiles

static func draw_projectiles(game: Node) -> void:
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
			game.draw_circle(current_position, radius * 0.55, color)
			game.draw_line(current_position + Vector2.RIGHT.rotated(angle) * radius, current_position - Vector2.RIGHT.rotated(angle) * radius, color.lightened(0.18), 5.0, true)
			game.draw_line(current_position + Vector2.UP.rotated(angle) * (radius * 0.8), current_position - Vector2.UP.rotated(angle) * (radius * 0.8), Color("fff7cf"), 3.0, true)
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
			game.draw_colored_polygon(PackedVector2Array([tip, tail_left, tail_right]), color)
			game.draw_line(current_position - direction * 10.0, current_position + direction * 4.0, Color("eff8ff"), 2.0, true)
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
			game.draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_tail_left, arrow_tail_right]), color)
			game.draw_line(current_position - arrow_direction * 12.0, current_position + arrow_direction * 4.0, Color("fff6d3"), maxf(width, 1.4), true)
			continue
		if projectile_kind == "fireball_blast":
			var duration: float = maxf(float(projectile.get("blast_duration", 0.24)), 0.001)
			var life_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / duration, 0.0, 1.0)
			var blast_radius: float = lerpf(10.0, float(projectile.get("impact_radius", projectile.get("radius", 92.0))), life_ratio)
			var blast_color: Color = color
			blast_color.a = 0.32 * (1.0 - life_ratio)
			game.draw_circle(current_position, blast_radius, blast_color)
			game.draw_arc(current_position, blast_radius, 0.0, TAU, 44, color.lightened(0.18), maxf(width * (1.0 - life_ratio * 0.35), 2.0), true)
			game.draw_circle(current_position, blast_radius * 0.42, Color(1.0, 0.95, 0.78, 0.18 * (1.0 - life_ratio)))
			continue
		if projectile_kind == "shield_flash":
			var shield_duration: float = maxf(float(projectile.get("blast_duration", 0.22)), 0.001)
			var shield_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / shield_duration, 0.0, 1.0)
			var shield_radius: float = lerpf(16.0, float(projectile.get("radius", 34.0)), shield_ratio)
			game.draw_arc(current_position, shield_radius, 0.0, TAU, 40, Color(color.r, color.g, color.b, 0.75 - shield_ratio * 0.55), maxf(width * (1.0 - shield_ratio * 0.35), 1.5), true)
			game.draw_circle(current_position, shield_radius * 0.55, Color(color.r, color.g, color.b, 0.10))
			continue
		if projectile_kind == "lightning_bolt":
			var bolt_duration: float = maxf(float(projectile.get("blast_duration", 0.18)), 0.001)
			var bolt_ratio: float = clampf(float(projectile.get("lifetime_left", 0.0)) / bolt_duration, 0.0, 1.0)
			var origin: Vector2 = projectile.get("previous", current_position)
			game.draw_line(origin, current_position, Color(1.0, 0.98, 0.86, 0.95 * bolt_ratio), width + 3.0, true)
			game.draw_line(origin, current_position, Color(color.r, color.g, color.b, 0.9 * bolt_ratio), width, true)
			game.draw_circle(current_position, 6.0 + 6.0 * bolt_ratio, Color(color.r, color.g, color.b, 0.38))
			continue
		if projectile_kind == "gas_pulse":
			var gas_duration: float = maxf(float(projectile.get("blast_duration", 0.22)), 0.001)
			var gas_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / gas_duration, 0.0, 1.0)
			var gas_radius: float = lerpf(18.0, float(projectile.get("impact_radius", projectile.get("radius", 72.0))), gas_ratio)
			game.draw_circle(current_position, gas_radius, Color(color.r, color.g, color.b, 0.10 * (1.0 - gas_ratio)))
			game.draw_arc(current_position, gas_radius, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.55 * (1.0 - gas_ratio * 0.4)), maxf(width, 2.0), true)
			continue
		game.draw_line(previous, current_position, color, width, true)
		game.draw_circle(current_position, 3.0, color)

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

static func cleanup_enemies(game: Node) -> void:
	var alive_enemies: Array = []
	for enemy in game.enemies:
		if is_instance_valid(enemy):
			alive_enemies.append(enemy)
	game.enemies = alive_enemies
