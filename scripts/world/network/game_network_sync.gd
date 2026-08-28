extends RefCounted

const GAME_DUNGEON_BUILDER: GDScript = preload("res://scripts/world/rooms/game_dungeon_builder.gd")

static func peer_can_control_hero(game: Node, peer_id: int, hero_index: int) -> bool:
	return hero_index >= 0 and hero_index < game.hero_owner_peer_ids.size() and int(game.hero_owner_peer_ids[hero_index]) == peer_id

static func maybe_broadcast_network_snapshot(game: Node, delta: float) -> void:
	if not game.multiplayer_session_active() or not game.multiplayer.is_server():
		return
	game.network_snapshot_timer += delta
	if game.network_snapshot_timer < game.NETWORK_SNAPSHOT_INTERVAL:
		return
	game.network_snapshot_timer = 0.0
	broadcast_network_snapshot(game, false)

static func broadcast_network_snapshot(game: Node, include_rooms: bool = true) -> void:
	if not game.multiplayer_session_active() or not game.multiplayer.is_server():
		return
	if include_rooms:
		game.receive_network_full_snapshot.rpc(build_network_snapshot(game, true))
		return
	game.receive_network_snapshot.rpc(build_network_snapshot(game, false))

static func build_network_snapshot(game: Node, include_rooms: bool = true) -> Dictionary:
	var room_visual_states: Dictionary = {}
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = Vector2i(room_coord_variant)
		var room: Dictionary = game.rooms[room_coord]
		room_visual_states[room_coord] = {
			"opened": bool(room.get("opened", false)),
			"scry_revealed": bool(room.get("scry_revealed", false)),
			"lit": bool(room.get("lit", false)),
		}
	var hero_states: Array = []
	for hero in game.heroes:
		if not is_instance_valid(hero):
			continue
		var hero_state: Dictionary = {
			"hero_index": hero.hero_index,
			"hero_name": hero.hero_name,
			"hero_class_id": hero.hero_class_id,
			"level": hero.level,
			"position": hero.global_position,
			"destination": hero.destination,
			"current_room": hero.current_room,
			"pending_room": hero.pending_room,
			"pending_open_room": hero.pending_open_room,
			"pending_open_origin_room": hero.pending_open_origin_room,
			"player_command_locked": hero.player_command_locked,
			"current_health": hero.current_health,
			"max_health": hero.max_health,
			"barrier_amount": hero.barrier_amount,
			"barrier_capacity": hero.barrier_capacity,
			"barrier_time_left": hero.barrier_time_left,
			"invulnerability_time_left": hero.invulnerability_time_left,
			"max_hand_size": hero.max_hand_size,
			"combo_points": hero.combo_points,
			"fighter_rage": hero.fighter_rage,
			"fighter_rage_max": hero.fighter_rage_max,
			"fighter_rage_hit_progress": hero.fighter_rage_hit_progress,
			"fighter_rage_throw_level": hero.fighter_rage_throw_level,
			"fighter_rage_throw_hits_left": hero.fighter_rage_throw_hits_left,
			"combo_attack_progress": hero.combo_attack_progress,
			"combo_decay_time_left": hero.combo_decay_time_left,
			"food_attack_cooldown_multiplier": hero.food_attack_cooldown_multiplier,
			"food_attack_speed_time_left": hero.food_attack_speed_time_left,
			"food_defence_bonus": hero.food_defence_bonus,
			"food_defence_time_left": hero.food_defence_time_left,
			"food_move_speed_multiplier": hero.food_move_speed_multiplier,
			"food_move_speed_time_left": hero.food_move_speed_time_left,
			"haste_move_speed_multiplier": hero.haste_move_speed_multiplier,
			"haste_attack_cooldown_multiplier": hero.haste_attack_cooldown_multiplier,
			"haste_time_left": hero.haste_time_left,
			"enemy_slow_amount": hero.enemy_slow_amount,
			"enemy_slow_time_left": hero.enemy_slow_time_left,
			"enemy_flatfooted_time_left": hero.enemy_flatfooted_time_left,
			"enemy_flatfooted_duration": hero.enemy_flatfooted_duration,
			"enemy_flatfooted_damage_taken_multiplier": hero.enemy_flatfooted_damage_taken_multiplier,
			"enemy_aura_attack_damage_multiplier": hero.enemy_aura_attack_damage_multiplier,
			"enemy_aura_time_left": hero.enemy_aura_time_left,
			"expose_stacks": hero.expose_stacks,
			"expose_time_left": hero.expose_time_left,
			"fragility_time_left": hero.fragility_time_left,
			"heal_flash_time_left": hero.heal_flash_time_left,
			"scorcher_channel_active": hero.scorcher_channel_active,
			"scorcher_channel_room": hero.scorcher_channel_room,
			"scorcher_channel_direction": hero.scorcher_channel_direction,
			"scorcher_channel_range": hero.scorcher_channel_range,
			"scorcher_channel_arc_degrees": hero.scorcher_channel_arc_degrees,
			"scorcher_dot_damage_per_second": hero.scorcher_dot_damage_per_second,
			"scorcher_channel_tick_interval": hero.scorcher_channel_tick_interval,
			"scorcher_channel_tick_time_left": hero.scorcher_channel_tick_time_left,
			"temporary_skulker_until_doors_opened": hero.temporary_skulker_until_doors_opened,
			"skulking_visual_active": hero.skulking_visual_active,
			"operate_room": hero.operate_room,
			"operate_started_at_door": hero.operate_started_at_door,
			"operate_attuned": hero.operate_attuned,
			"operate_turns_left": hero.operate_turns_left,
			"attack_damage": hero.attack_damage,
			"defence": hero.defence,
			"wit": hero.wit,
			"basic_attack_knockback": hero.basic_attack_knockback,
			"attack_range": hero.attack_range,
			"attack_cooldown": hero.attack_cooldown,
			"move_speed": hero.move_speed,
			"cooldown_left": hero.cooldown_left,
			"carrying_crystal": hero.carrying_crystal,
			"dead_started": hero.dead_started,
			"attack_effect_left": hero.attack_effect_left,
			"attack_direction": hero.attack_direction,
			"attack_style": hero.attack_style,
			"preferred_attack_style": hero.preferred_attack_style,
			"calm_multiplier": hero.calm_move_speed_multiplier,
			"combat_multiplier": hero.combat_move_speed_multiplier,
			"combat_mode": hero.combat_movement_mode,
			"light_cantrip_active": hero.light_cantrip_active,
			"studying_spell_id": hero.studying_spell_id,
			"studying_room": hero.studying_room,
			"studying_started_at_door": hero.studying_started_at_door,
		}
		if include_rooms:
			hero_state.merge({
				"pack_modules": hero.pack_modules.duplicate(true),
				"inventory_items": hero.inventory_items.duplicate(true),
				"applied_poisons": hero.applied_poisons.duplicate(true),
				"hand_cards": hero.hand_cards.duplicate(true),
				"learned_spells": hero.learned_spells.duplicate(),
				"slotted_spells": hero.slotted_spells.duplicate(),
				"active_floor_spells": hero.active_floor_spells.duplicate(),
				"pending_item_fusions": hero.pending_item_fusions.duplicate(true),
			})
		hero_states.append(hero_state)
	var enemy_states: Array = []
	for enemy in game.enemies:
		if not is_instance_valid(enemy):
			continue
		enemy_states.append({
			"enemy_uid": enemy.enemy_uid,
			"position": enemy.global_position,
			"destination": enemy.destination,
			"current_room": enemy.current_room,
			"pending_room": enemy.pending_room,
			"previous_room": enemy.previous_room,
			"next_room": enemy.next_room,
			"moving_between_rooms": enemy.moving_between_rooms,
			"enemy_role": enemy.enemy_role,
			"current_health": enemy.current_health,
			"attack_cooldown_left": enemy.attack_cooldown_left,
			"rooted_time_left": enemy.rooted_time_left,
			"converted_time_left": enemy.converted_time_left,
			"death_started": enemy.death_started,
		})
	var snapshot: Dictionary = {
		"room_visual_states": room_visual_states,
		"floating_resource_texts": game.floating_resource_texts.duplicate(true),
		"pending_enemy_spawns": game.pending_enemy_spawns.duplicate(true),
		"pending_room_constructions": game.pending_room_constructions.duplicate(true),
		"lobby_game_started": game.lobby_game_started,
		"heroes": hero_states,
		"enemies": enemy_states,
		"opening_room": game.opening_room,
		"opening_origin_room": game.opening_origin_room,
		"opening_timer_left": game.opening_timer_left,
		"selected_room": game.selected_room,
		"crystal_room": game.crystal_room,
		"exit_room": game.exit_room,
		"floor_index": game.floor_index,
		"dust": game.dust,
		"food": game.food,
		"industry": game.industry,
		"science": game.science,
		"research_reroll_count": game.research_reroll_count,
		"opened_rooms": game.opened_rooms,
		"wave_index": game.wave_index,
		"doors_opened": game.doors_opened,
		"floor_major_modules_built_count": game.floor_major_modules_built_count,
		"game_over": game.game_over,
		"status_message": game.status_message,
		"crystal_ground_room": game.crystal_ground_room,
		"crystal_holder_index": game.crystal_holder.hero_index if game.crystal_holder != null and is_instance_valid(game.crystal_holder) else -1,
		"door_wave_auto_heal_pending": game.door_wave_auto_heal_pending,
		"door_wave_healing_active": game.door_wave_healing_active,
		"door_wave_spawns_incoming": game.door_wave_spawns_incoming,
		"next_enemy_uid": game.next_enemy_uid,
		"next_item_uid": game.next_item_uid,
	}
	if include_rooms:
		snapshot["rooms"] = game.rooms.duplicate(true)
		snapshot["global_item_card_states"] = game.global_item_card_states.duplicate(true)
		snapshot["global_item_passive_timers"] = game.global_item_passive_timers.duplicate(true)
		snapshot["hero_owner_peer_ids"] = game.hero_owner_peer_ids.duplicate(true)
		snapshot["rejoin_claimable_hero_indices"] = game.rejoin_claimable_hero_indices.duplicate(true)
		snapshot["lobby_peer_ready"] = game.lobby_peer_ready.duplicate(true)
		snapshot["minor_module_levels"] = game.minor_module_levels.duplicate(true)
		snapshot["major_module_levels"] = game.major_module_levels.duplicate(true)
		snapshot["active_research"] = game.active_research.duplicate(true)
	return snapshot

static func receive_network_snapshot(game: Node, snapshot: Dictionary) -> void:
	if game.authoritative_simulation_active():
		return
	apply_network_snapshot(game, snapshot)

static func receive_network_full_snapshot(game: Node, snapshot: Dictionary) -> void:
	if game.authoritative_simulation_active():
		return
	apply_network_snapshot(game, snapshot)

static func network_projectile_visual_state(projectile: Dictionary) -> Dictionary:
	return {
		"kind": projectile.get("kind", "laser"),
		"position": projectile.get("position", Vector2.ZERO),
		"previous": projectile.get("previous", Vector2.ZERO),
		"target_position": projectile.get("target_position", Vector2.ZERO),
		"speed": float(projectile.get("speed", 950.0)),
		"color": projectile.get("color", Color.WHITE),
		"width": float(projectile.get("width", 4.0)),
		"network_visual_only": true,
	}

static func receive_network_projectile_visual(game: Node, projectile: Dictionary) -> void:
	if game.authoritative_simulation_active():
		return
	game.projectiles.append(projectile.duplicate(true))

static func receive_lobby_ready_confirmation(game: Node, ready: bool) -> void:
	if game.authoritative_simulation_active():
		return
	game.lobby_peer_ready[game.local_peer_id()] = ready
	game.update_hud()

static func room_layout_signature(rooms: Dictionary) -> String:
	var tokens: Array[String] = []
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = Vector2i(room_coord_variant)
		var room: Dictionary = Dictionary(rooms[room_coord_variant])
		tokens.append("%s|%s|%s|%s|%s" % [room_coord, room.get("world_center", Vector2.ZERO), room.get("room_scene_path", ""), room.get("door_dirs", []), room.get("door_positions_normalized", {})])
	tokens.sort()
	return ";".join(tokens)

static func apply_network_snapshot(game: Node, snapshot: Dictionary) -> void:
	var previous_lobby_started: bool = game.lobby_game_started
	if snapshot.has("rooms"):
		var synchronized_rooms: Dictionary = Dictionary(snapshot["rooms"]).duplicate(true)
		var next_layout_signature: String = room_layout_signature(synchronized_rooms)
		var layout_changed: bool = next_layout_signature != game.network_room_layout_signature
		game.rooms = synchronized_rooms
		game.normalize_runtime_rooms_slot_capacity()
		if layout_changed:
			game.network_room_layout_signature = next_layout_signature
			game.invalidate_static_dungeon_layer()
	var room_visual_states: Dictionary = Dictionary(snapshot.get("room_visual_states", {}))
	if not room_visual_states.is_empty():
		for room_coord_variant in room_visual_states.keys():
			var room_coord: Vector2i = Vector2i(room_coord_variant)
			if not game.rooms.has(room_coord):
				continue
			var visual_state: Dictionary = Dictionary(room_visual_states[room_coord_variant])
			var local_room: Dictionary = game.rooms[room_coord]
			var visibility_changed: bool = bool(visual_state.get("opened", false)) != bool(local_room.get("opened", false)) or bool(visual_state.get("scry_revealed", false)) != bool(local_room.get("scry_revealed", false))
			local_room["opened"] = bool(visual_state.get("opened", local_room.get("opened", false)))
			local_room["scry_revealed"] = bool(visual_state.get("scry_revealed", local_room.get("scry_revealed", false)))
			local_room["lit"] = bool(visual_state.get("lit", local_room.get("lit", false)))
			if visibility_changed:
				game.sync_static_room_instance(room_coord)
		game.refresh_static_visible_room_states()
	if snapshot.has("projectiles"):
		game.projectiles = Array(snapshot["projectiles"]).duplicate(true)
	game.floating_resource_texts = Array(snapshot.get("floating_resource_texts", [])).duplicate(true)
	game.pending_wave_spawn_builds.clear()
	game.pending_enemy_spawns = Array(snapshot.get("pending_enemy_spawns", [])).duplicate(true)
	game.pending_room_constructions = Array(snapshot.get("pending_room_constructions", [])).duplicate(true)
	game.global_item_card_states = Dictionary(snapshot.get("global_item_card_states", game.global_item_card_states)).duplicate(true)
	game.global_item_passive_timers = Dictionary(snapshot.get("global_item_passive_timers", game.global_item_passive_timers)).duplicate(true)
	game.hero_owner_peer_ids = Array(snapshot.get("hero_owner_peer_ids", [])).duplicate(true)
	if game.hero_owner_peer_ids.size() != game.HERO_COUNT:
		game.reset_hero_owner_peer_ids()
	game.rejoin_claimable_hero_indices = Array(snapshot.get("rejoin_claimable_hero_indices", [])).duplicate(true)
	game.lobby_peer_ready = Dictionary(snapshot.get("lobby_peer_ready", {})).duplicate(true)
	game.lobby_game_started = bool(snapshot.get("lobby_game_started", game.lobby_game_started))
	game.opening_room = snapshot.get("opening_room", game.INVALID_ROOM)
	game.opening_origin_room = snapshot.get("opening_origin_room", game.INVALID_ROOM)
	game.opening_timer_left = float(snapshot.get("opening_timer_left", 0.0))
	game.selected_room = snapshot.get("selected_room", game.crystal_room)
	game.crystal_room = snapshot.get("crystal_room", game.crystal_room)
	game.exit_room = snapshot.get("exit_room", game.INVALID_ROOM)
	game.floor_index = int(snapshot.get("floor_index", game.floor_index))
	game.dust = int(snapshot.get("dust", game.dust))
	game.food = int(snapshot.get("food", game.food))
	game.industry = int(snapshot.get("industry", game.industry))
	game.science = int(snapshot.get("science", game.science))
	game.research_reroll_count = maxi(int(snapshot.get("research_reroll_count", game.research_reroll_count)), 0)
	game.minor_module_levels = game.normalized_minor_module_levels(Dictionary(snapshot.get("minor_module_levels", game.initialized_minor_module_levels())).duplicate(true))
	game.major_module_levels = game.normalized_major_module_levels(Dictionary(snapshot.get("major_module_levels", game.initialized_major_module_levels())).duplicate(true))
	game.active_research = Dictionary(snapshot.get("active_research", {})).duplicate(true)
	game.opened_rooms = int(snapshot.get("opened_rooms", game.opened_rooms))
	game.wave_index = int(snapshot.get("wave_index", game.wave_index))
	game.doors_opened = int(snapshot.get("doors_opened", game.doors_opened))
	game.floor_major_modules_built_count = maxi(int(snapshot.get("floor_major_modules_built_count", game.estimate_floor_major_modules_built_count())), 0)
	game.game_over = bool(snapshot.get("game_over", game.game_over))
	game.status_message = String(snapshot.get("status_message", game.status_message))
	game.crystal_ground_room = snapshot.get("crystal_ground_room", game.INVALID_ROOM)
	game.door_wave_auto_heal_pending = bool(snapshot.get("door_wave_auto_heal_pending", false))
	game.door_wave_healing_active = bool(snapshot.get("door_wave_healing_active", false))
	game.door_wave_spawns_incoming = bool(snapshot.get("door_wave_spawns_incoming", false))
	game.next_enemy_uid = int(snapshot.get("next_enemy_uid", game.next_enemy_uid))
	game.next_item_uid = int(snapshot.get("next_item_uid", game.next_item_uid))
	var hero_states: Array = Array(snapshot.get("heroes", []))
	if not hero_states.is_empty() and game.heroes.is_empty():
		game.spawn_heroes()
	apply_hero_snapshots(game, hero_states)
	apply_enemy_snapshots(game, Array(snapshot.get("enemies", [])))
	var crystal_holder_index: int = int(snapshot.get("crystal_holder_index", -1))
	game.crystal_holder = game.heroes[crystal_holder_index] if crystal_holder_index >= 0 and crystal_holder_index < game.heroes.size() else null
	if game.crystal_holder != null or game.crystal_ground_room == game.INVALID_ROOM or not game.is_exit_discovered():
		game.crystal_prompt_visible = false
	game.ensure_valid_selected_hero()
	var local_selected: Variant = game.selected_hero()
	if local_selected != null and is_instance_valid(local_selected):
		game.selected_room = game.active_hero_room_for_commands(local_selected)
	if game.lobby_game_started and not previous_lobby_started and game.hero_select_overlay != null:
		game.hero_select_overlay.visible = false
		if game.hero_select_toggle_button != null:
			game.hero_select_toggle_button.text = "Lobby"
	elif not game.lobby_game_started and previous_lobby_started:
		game.set_hero_select_overlay_visible(true)
	process_client_pending_local_requests(game)
	game.refresh_camera_bounds()
	game.update_hud()
	game.update_network_ui()
	game.queue_redraw()

static func process_client_pending_local_requests(game: Node) -> void:
	if game.authoritative_simulation_active():
		return
	for hero in game.heroes:
		if not is_instance_valid(hero):
			continue
		if game.try_open_pending_room_loot_request(hero):
			return

static func apply_hero_snapshots(game: Node, hero_states: Array) -> void:
	game.ensure_hero_profiles()
	for hero_state_variant in hero_states:
		var hero_state: Dictionary = hero_state_variant
		var hero_index: int = int(hero_state.get("hero_index", -1))
		if hero_index < 0 or hero_index >= game.heroes.size():
			continue
		var hero: Variant = game.heroes[hero_index]
		if hero == null or not is_instance_valid(hero):
			continue
		var hero_class_id: String = String(hero_state.get("hero_class_id", hero.hero_class_id))
		var hero_name: String = String(hero_state.get("hero_name", hero.hero_name))
		if hero.hero_class_id != hero_class_id or hero.hero_name != hero_name:
			game.apply_hero_class_to_node(hero, hero_class_id, hero_name)
		game.hero_profiles[hero_index]["class_id"] = hero_class_id
		game.hero_profiles[hero_index]["name"] = hero_name
		game.hero_profiles[hero_index]["dead"] = bool(hero_state.get("dead_started", false))
		hero.level = int(hero_state.get("level", hero.level))
		hero.pack_modules = Array(hero_state.get("pack_modules", hero.pack_modules)).duplicate(true)
		hero.inventory_items = Array(hero_state.get("inventory_items", hero.inventory_items)).duplicate(true)
		hero.learned_spells = Array(hero_state.get("learned_spells", hero.learned_spells)).duplicate()
		hero.slotted_spells = Array(hero_state.get("slotted_spells", hero.slotted_spells)).duplicate()
		hero.active_floor_spells = Array(hero_state.get("active_floor_spells", hero.active_floor_spells)).duplicate()
		hero.pending_item_fusions = Array(hero_state.get("pending_item_fusions", hero.pending_item_fusions)).duplicate(true)
		hero.studying_spell_id = String(hero_state.get("studying_spell_id", hero.studying_spell_id))
		hero.studying_room = hero_state.get("studying_room", hero.studying_room)
		hero.studying_started_at_door = int(hero_state.get("studying_started_at_door", hero.studying_started_at_door))
		game.sanitize_hero_spellbook(hero)
		game.hero_profiles[hero_index]["learned_spells"] = hero.learned_spells.duplicate()
		game.hero_profiles[hero_index]["slotted_spells"] = hero.slotted_spells.duplicate()
		hero.barrier_amount = float(hero_state.get("barrier_amount", hero.barrier_amount))
		hero.barrier_capacity = float(hero_state.get("barrier_capacity", hero.barrier_capacity))
		hero.barrier_time_left = float(hero_state.get("barrier_time_left", hero.barrier_time_left))
		hero.invulnerability_time_left = float(hero_state.get("invulnerability_time_left", hero.invulnerability_time_left))
		hero.max_hand_size = int(hero_state.get("max_hand_size", hero.max_hand_size))
		hero.combo_points = clampi(int(hero_state.get("combo_points", hero.combo_points)), 0, 3)
		hero.fighter_rage_max = maxi(int(hero_state.get("fighter_rage_max", hero.fighter_rage_max)), 0)
		hero.fighter_rage = clampi(int(hero_state.get("fighter_rage", hero.fighter_rage)), 0, hero.fighter_rage_max)
		hero.fighter_rage_hit_progress = maxi(int(hero_state.get("fighter_rage_hit_progress", hero.fighter_rage_hit_progress)), 0)
		hero.fighter_rage_throw_level = clampi(int(hero_state.get("fighter_rage_throw_level", hero.fighter_rage_throw_level)), 0, hero.fighter_rage_max)
		hero.fighter_rage_throw_hits_left = maxi(int(hero_state.get("fighter_rage_throw_hits_left", hero.fighter_rage_throw_hits_left)), 0)
		if hero.fighter_rage_throw_hits_left <= 0:
			hero.fighter_rage_throw_level = 0
		hero.combo_attack_progress = int(hero_state.get("combo_attack_progress", hero.combo_attack_progress))
		hero.combo_decay_time_left = float(hero_state.get("combo_decay_time_left", hero.combo_decay_time_left))
		hero.food_attack_cooldown_multiplier = float(hero_state.get("food_attack_cooldown_multiplier", hero.food_attack_cooldown_multiplier))
		hero.food_attack_speed_time_left = float(hero_state.get("food_attack_speed_time_left", hero.food_attack_speed_time_left))
		hero.food_defence_bonus = float(hero_state.get("food_defence_bonus", hero.food_defence_bonus))
		hero.food_defence_time_left = float(hero_state.get("food_defence_time_left", hero.food_defence_time_left))
		hero.food_move_speed_multiplier = float(hero_state.get("food_move_speed_multiplier", hero.food_move_speed_multiplier))
		hero.food_move_speed_time_left = float(hero_state.get("food_move_speed_time_left", hero.food_move_speed_time_left))
		hero.haste_move_speed_multiplier = float(hero_state.get("haste_move_speed_multiplier", hero.haste_move_speed_multiplier))
		hero.haste_attack_cooldown_multiplier = float(hero_state.get("haste_attack_cooldown_multiplier", hero.haste_attack_cooldown_multiplier))
		hero.haste_time_left = float(hero_state.get("haste_time_left", hero.haste_time_left))
		hero.enemy_slow_amount = clampf(float(hero_state.get("enemy_slow_amount", hero.enemy_slow_amount)), 0.0, 0.9)
		hero.enemy_slow_time_left = maxf(float(hero_state.get("enemy_slow_time_left", hero.enemy_slow_time_left)), 0.0)
		hero.enemy_flatfooted_time_left = maxf(float(hero_state.get("enemy_flatfooted_time_left", hero.enemy_flatfooted_time_left)), 0.0)
		hero.enemy_flatfooted_duration = maxf(float(hero_state.get("enemy_flatfooted_duration", hero.enemy_flatfooted_duration)), 0.0)
		hero.enemy_flatfooted_damage_taken_multiplier = clampf(float(hero_state.get("enemy_flatfooted_damage_taken_multiplier", hero.enemy_flatfooted_damage_taken_multiplier)), 1.0, 4.0)
		hero.enemy_aura_attack_damage_multiplier = clampf(float(hero_state.get("enemy_aura_attack_damage_multiplier", hero.enemy_aura_attack_damage_multiplier)), 0.1, 1.0)
		hero.enemy_aura_time_left = maxf(float(hero_state.get("enemy_aura_time_left", hero.enemy_aura_time_left)), 0.0)
		hero.expose_stacks = clampi(int(hero_state.get("expose_stacks", hero.expose_stacks)), 0, 3)
		hero.expose_time_left = maxf(float(hero_state.get("expose_time_left", hero.expose_time_left)), 0.0)
		hero.fragility_time_left = maxf(float(hero_state.get("fragility_time_left", hero.fragility_time_left)), 0.0)
		hero.heal_flash_time_left = maxf(float(hero_state.get("heal_flash_time_left", hero.heal_flash_time_left)), 0.0)
		hero.scorcher_channel_active = bool(hero_state.get("scorcher_channel_active", hero.scorcher_channel_active))
		hero.scorcher_channel_room = hero_state.get("scorcher_channel_room", hero.scorcher_channel_room)
		hero.scorcher_channel_direction = Vector2(hero_state.get("scorcher_channel_direction", hero.scorcher_channel_direction))
		hero.scorcher_channel_range = float(hero_state.get("scorcher_channel_range", hero.scorcher_channel_range))
		hero.scorcher_channel_arc_degrees = float(hero_state.get("scorcher_channel_arc_degrees", hero.scorcher_channel_arc_degrees))
		hero.scorcher_dot_damage_per_second = float(hero_state.get("scorcher_dot_damage_per_second", hero.scorcher_dot_damage_per_second))
		hero.scorcher_channel_tick_interval = float(hero_state.get("scorcher_channel_tick_interval", hero.scorcher_channel_tick_interval))
		hero.scorcher_channel_tick_time_left = float(hero_state.get("scorcher_channel_tick_time_left", hero.scorcher_channel_tick_time_left))
		hero.temporary_skulker_until_doors_opened = int(hero_state.get("temporary_skulker_until_doors_opened", hero.temporary_skulker_until_doors_opened))
		hero.skulking_visual_active = bool(hero_state.get("skulking_visual_active", hero.skulking_visual_active))
		hero.operate_room = hero_state.get("operate_room", hero.operate_room)
		hero.operate_started_at_door = int(hero_state.get("operate_started_at_door", hero.operate_started_at_door))
		hero.operate_attuned = bool(hero_state.get("operate_attuned", hero.operate_attuned))
		hero.operate_turns_left = clampi(int(hero_state.get("operate_turns_left", hero.operate_turns_left)), 0, 1)
		hero.applied_poisons = Array(hero_state.get("applied_poisons", hero.applied_poisons)).duplicate(true)
		hero.hand_cards = Array(hero_state.get("hand_cards", hero.hand_cards)).duplicate(true)
		hero.move_speed = float(hero_state.get("move_speed", hero.move_speed))
		hero.max_health = float(hero_state.get("max_health", hero.max_health))
		hero.attack_damage = float(hero_state.get("attack_damage", hero.attack_damage))
		hero.defence = float(hero_state.get("defence", hero.defence))
		hero.wit = maxf(float(hero_state.get("wit", hero.wit)), 0.0)
		hero.basic_attack_knockback = maxf(float(hero_state.get("basic_attack_knockback", hero.basic_attack_knockback)), 0.0)
		hero.attack_range = float(hero_state.get("attack_range", hero.attack_range))
		hero.attack_cooldown = float(hero_state.get("attack_cooldown", hero.attack_cooldown))
		hero.current_health = float(hero_state.get("current_health", hero.current_health))
		if bool(hero_state.get("dead_started", false)):
			hero.begin_death()
		hero.cooldown_left = float(hero_state.get("cooldown_left", hero.cooldown_left))
		var predicting_local_movement: bool = not game.authoritative_simulation_active() and game.can_local_control_hero_index(hero_index) and (not hero.move_steps.is_empty() or hero.pending_room != game.HERO_INVALID_ROOM)
		if not predicting_local_movement:
			hero.current_room = hero_state.get("current_room", hero.current_room)
			hero.pending_room = hero_state.get("pending_room", hero.pending_room)
			hero.pending_open_room = hero_state.get("pending_open_room", hero.pending_open_room)
			hero.pending_open_origin_room = hero_state.get("pending_open_origin_room", hero.pending_open_origin_room)
			hero.player_command_locked = bool(hero_state.get("player_command_locked", hero.player_command_locked))
		hero.carrying_crystal = bool(hero_state.get("carrying_crystal", false))
		var host_attack_effect_left: float = float(hero_state.get("attack_effect_left", 0.0))
		if host_attack_effect_left > hero.attack_effect_left + 0.02:
			hero.attack_effect_left = host_attack_effect_left
			hero.attack_direction = Vector2(hero_state.get("attack_direction", Vector2.RIGHT))
			hero.attack_style = String(hero_state.get("attack_style", ""))
		hero.preferred_attack_style = String(hero_state.get("preferred_attack_style", hero.preferred_attack_style))
		hero.combat_move_speed_multiplier = float(hero_state.get("combat_multiplier", hero.combat_move_speed_multiplier))
		hero.set_calm_movement_multiplier(float(hero_state.get("calm_multiplier", hero.calm_move_speed_multiplier)))
		hero.set_combat_movement_mode(bool(hero_state.get("combat_mode", false)))
		hero.light_cantrip_active = bool(hero_state.get("light_cantrip_active", hero.light_cantrip_active))
		if not predicting_local_movement:
			var host_position: Vector2 = Vector2(hero_state.get("position", hero.global_position))
			if not hero.network_position_initialized or hero.global_position.distance_to(host_position) > 140.0:
				hero.global_position = host_position
				hero.network_position_initialized = true
			hero.destination = Vector2(hero_state.get("destination", host_position))
			hero.move_steps.clear()
		hero.queue_redraw()

static func apply_enemy_snapshots(game: Node, enemy_states: Array) -> void:
	var existing_by_uid: Dictionary = {}
	for enemy in game.enemies:
		if is_instance_valid(enemy):
			existing_by_uid[int(enemy.enemy_uid)] = enemy
	var synced_enemies: Array = []
	for enemy_state_variant in enemy_states:
		var enemy_state: Dictionary = enemy_state_variant
		var enemy_uid: int = int(enemy_state.get("enemy_uid", -1))
		if enemy_uid < 0:
			continue
		var enemy: Variant = existing_by_uid.get(enemy_uid, null)
		if enemy == null or not is_instance_valid(enemy):
			enemy = game.ENEMY_SCENE.instantiate()
			enemy.enemy_uid = enemy_uid
			game.enemy_layer.add_child(enemy)
		existing_by_uid.erase(enemy_uid)
		enemy.set_role(String(enemy_state.get("enemy_role", game.ENEMY_TYPE_ORC)))
		enemy.current_health = float(enemy_state.get("current_health", enemy.current_health))
		enemy.attack_cooldown_left = float(enemy_state.get("attack_cooldown_left", enemy.attack_cooldown_left))
		enemy.rooted_time_left = float(enemy_state.get("rooted_time_left", enemy.rooted_time_left))
		enemy.converted_time_left = float(enemy_state.get("converted_time_left", enemy.converted_time_left))
		enemy.current_room = enemy_state.get("current_room", enemy.current_room)
		enemy.pending_room = enemy_state.get("pending_room", enemy.pending_room)
		enemy.previous_room = enemy_state.get("previous_room", enemy.previous_room)
		enemy.next_room = enemy_state.get("next_room", enemy.next_room)
		enemy.moving_between_rooms = bool(enemy_state.get("moving_between_rooms", false))
		var host_position: Vector2 = Vector2(enemy_state.get("position", enemy.global_position))
		if not enemy.network_position_initialized or enemy.global_position.distance_to(host_position) > 140.0:
			enemy.global_position = host_position
			enemy.network_position_initialized = true
		enemy.destination = Vector2(enemy_state.get("destination", host_position))
		enemy.move_steps.clear()
		if bool(enemy_state.get("death_started", false)):
			enemy.begin_death()
		synced_enemies.append(enemy)
		enemy.queue_redraw()
	for enemy_variant in existing_by_uid.values():
		var stale_enemy: Variant = enemy_variant
		if is_instance_valid(stale_enemy):
			stale_enemy.queue_free()
	game.enemies = synced_enemies

static func assign_multiplayer_hero_owners_after_floor_transition(game: Node) -> void:
	if not game.multiplayer_session_active() or not game.multiplayer.is_server():
		return
	if game.hero_owner_peer_ids.size() != game.HERO_COUNT:
		game.reset_hero_owner_peer_ids()
	var connected_peers: Array[int] = game.connected_session_peer_ids()
	for hero_index in range(game.HERO_COUNT):
		var owner_peer_id: int = int(game.hero_owner_peer_ids[hero_index])
		if connected_peers.has(owner_peer_id):
			continue
		game.hero_owner_peer_ids[hero_index] = game.NETWORK_HOST_PEER_ID
		if game.lobby_game_started and not game.rejoin_claimable_hero_indices.has(hero_index):
			game.rejoin_claimable_hero_indices.append(hero_index)
	game.rejoin_claimable_hero_indices.sort()
	game.ensure_valid_selected_hero()

static func server_request_world_command(game: Node, hero_index: int, world_position: Vector2) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	game.execute_world_command_for_hero(hero_index, world_position, false)
	broadcast_network_snapshot(game, false)

static func server_request_network_full_snapshot(game: Node) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if sender_peer_id <= 0:
		return
	game.receive_network_full_snapshot.rpc_id(sender_peer_id, build_network_snapshot(game, true))

static func server_request_room_loot(game: Node, hero_index: int, room_coord: Vector2i) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	game.request_room_loot_for_hero(hero_index, room_coord, false)
	broadcast_network_snapshot(game, false)

static func server_request_room_light(game: Node, hero_index: int, room_coord: Vector2i) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	game.request_room_light_for_hero(hero_index, room_coord)
	broadcast_network_snapshot(game)

static func server_request_room_construction(game: Node, hero_index: int, room_coord: Vector2i, module_type: String) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	game.request_room_construction_for_hero(hero_index, room_coord, module_type)
	broadcast_network_snapshot(game)

static func server_request_room_merchant_action(game: Node, hero_index: int, room_coord: Vector2i, action_kind: String, item_or_offer_uid: int) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	var accepted: bool = false
	match action_kind:
		"buy":
			accepted = game.request_room_merchant_buy_for_hero(hero_index, room_coord, item_or_offer_uid)
		"sell":
			accepted = game.request_room_merchant_sell_for_hero(hero_index, room_coord, item_or_offer_uid)
		"buyback":
			accepted = game.request_room_merchant_buyback_for_hero(hero_index, room_coord, item_or_offer_uid)
		_:
			accepted = false
	if accepted:
		broadcast_network_snapshot(game)

static func server_request_room_resource_trade(game: Node, hero_index: int, room_coord: Vector2i, target_hero_index: int, resource_id: String, amount: int) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	if game.request_room_resource_trade_for_hero(hero_index, room_coord, target_hero_index, resource_id, amount):
		broadcast_network_snapshot(game)

static func server_request_hero_class(game: Node, hero_index: int, class_id: String) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	if game.hero_class_selection_locked():
		return
	if not game.HERO_CLASS_ORDER.has(class_id):
		return
	game.lobby_peer_ready[sender_peer_id] = false
	game.set_hero_profile_class(hero_index, class_id, true)
	game.update_hud()
	broadcast_network_snapshot(game)

static func server_request_lobby_ready(game: Node, ready: bool) -> void:
	if not game.multiplayer.is_server():
		return
	if game.lobby_game_started:
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	game.lobby_peer_ready[sender_peer_id] = ready
	game.update_hud()
	game.receive_lobby_ready_confirmation.rpc_id(sender_peer_id, ready)
	broadcast_network_snapshot(game)

static func server_request_play_card(game: Node, hero_index: int, card_uid: int, target_world_position: Vector2) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	if game.play_card_for_hero(hero_index, card_uid, target_world_position):
		broadcast_network_snapshot(game)

static func server_request_pick_up_crystal(game: Node, hero_index: int) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if game.crystal_holder != null or game.crystal_ground_room == game.INVALID_ROOM or not game.is_exit_discovered():
		return
	if hero.current_room != game.crystal_ground_room or hero.pending_room != game.HERO_INVALID_ROOM or not hero.is_idle():
		return
	game.crystal_holder = hero
	game.crystal_holder.carrying_crystal = true
	game.crystal_ground_room = game.INVALID_ROOM
	game.crystal_prompt_visible = false
	game.crystal_pressure_timer_left = game.CRYSTAL_PRESSURE_PICKUP_DELAY
	game.update_hero_combat_movement_mode()
	game.status_message = "%s picked up the crystal. Dark rooms will agitate every %.0f seconds." % [hero.hero_name, game.CRYSTAL_PRESSURE_INTERVAL]
	game.update_hud()
	broadcast_network_snapshot(game)

static func server_request_exit_floor(game: Node, hero_index: int) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero != game.crystal_holder or not game.all_heroes_in_exit_room():
		return
	if game.floor_index >= game.TOTAL_FLOORS:
		game.game_over = true
		game.status_message = "The dungeon is conquered. All 10 floors are clear."
		game.update_hud()
		broadcast_network_snapshot(game)
		return
	game.floor_index += 1
	game.dust = 24
	game.status_message = "Escaped to floor %d." % game.floor_index
	game.build_dungeon(false)
	game.spawn_heroes()
	assign_multiplayer_hero_owners_after_floor_transition(game)
	game.selected_room = game.crystal_room
	game.center_camera()
	game.update_hud()
	broadcast_network_snapshot(game)

static func server_commit_inventory_state(game: Node, hero_index: int, room_coord: Vector2i, items: Array, ground_items: Array) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	game.commit_inventory_state(hero_index, room_coord, items, ground_items)
	game.update_hud()
	broadcast_network_snapshot(game)

static func server_commit_pack_layout(game: Node, hero_index: int, pack_modules: Array) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	game.commit_pack_layout(hero_index, pack_modules)
	game.update_hud()
	broadcast_network_snapshot(game)

static func server_commit_spell_slots(game: Node, hero_index: int, slotted_spells: Array) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	game.commit_spell_slots(hero_index, slotted_spells)
	game.update_hud()
	broadcast_network_snapshot(game)

static func server_commit_hand_state(game: Node, hero_index: int, hand_state: Array) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	game.commit_hand_state(hero_index, hand_state)
	game.update_hud()
	broadcast_network_snapshot(game)

static func server_request_inventory_level_up(game: Node, hero_index: int) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if game.grant_level_up_pack_to_hero(hero):
		game.status_message = "%s reached level %d." % [hero.hero_name, hero.level]
	else:
		game.status_message = "Not enough food or no room for another pack."
	game.apply_inventory_stats_to_hero(hero)
	game.update_hud()
	broadcast_network_snapshot(game)

static func server_request_inventory_drop(game: Node, hero_index: int, item: Dictionary) -> void:
	if not game.multiplayer.is_server():
		return
	var sender_peer_id: int = game.multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(game, sender_peer_id, hero_index):
		return
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not game.rooms.has(hero.current_room):
		return
	var dropped_item: Dictionary = item.duplicate(true)
	dropped_item.erase("anchor")
	if not dropped_item.has("uid"):
		dropped_item["uid"] = game.next_item_uid
		game.next_item_uid += 1
	dropped_item["position"] = game.clamp_point_to_room(hero.global_position + Vector2(0.0, 34.0) + GAME_DUNGEON_BUILDER.random_room_offset(game, 18.0), hero.current_room)
	game.rooms[hero.current_room]["ground_items"].append(dropped_item)
	game.status_message = "%s dropped %s." % [hero.hero_name, String(game.item_defs.get(String(dropped_item.get("item_id", "")), {}).get("name", "an item"))]
	game.update_hud()
	broadcast_network_snapshot(game)
