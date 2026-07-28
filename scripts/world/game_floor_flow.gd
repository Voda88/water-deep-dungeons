extends RefCounted

const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/inventory/game_inventory_item_flow.gd")

static func start_room_opening(game: Node, room_coord: Vector2i, from_room: Vector2i) -> void:
	game.opening_room = room_coord
	game.opening_origin_room = from_room
	game.opening_timer_left = game.DOOR_OPEN_DURATION
	game.opening_heroes.clear()
	if game.opening_hero != null and is_instance_valid(game.opening_hero):
		game.opening_heroes.append(game.opening_hero)
	game.status_message = "Opening %s. Hold for %.1fs." % [game.room_title(room_coord), game.DOOR_OPEN_DURATION]
	game.update_hud()

static func advance_room_opening(game: Node, delta: float) -> void:
	if game.opening_room == game.INVALID_ROOM:
		return
	var active_openers: Array = []
	for hero_variant in game.opening_heroes:
		var hero: Variant = hero_variant
		if hero == null or not is_instance_valid(hero):
			continue
		if hero.current_room == game.opening_origin_room and hero.pending_room == game.HERO_INVALID_ROOM and hero.is_idle():
			active_openers.append(hero)
	game.opening_heroes = active_openers
	var opener_count: int = max(game.opening_heroes.size(), 1)
	game.opening_timer_left = maxf(game.opening_timer_left - delta * float(opener_count), 0.0)
	if game.opening_timer_left <= 0.0:
		finish_room_opening(game)
		return
	var progress_ratio: float = 1.0 - (game.opening_timer_left / game.DOOR_OPEN_DURATION)
	game.status_message = "Opening %s from %s. %d%%" % [game.room_title(game.opening_room), game.room_title(game.opening_origin_room), int(progress_ratio * 100.0)]
	game.update_hud()

static func finish_room_opening(game: Node) -> void:
	var breached_room: Vector2i = game.opening_room
	var from_room: Vector2i = game.opening_origin_room
	var breach_heroes: Array = game.opening_heroes.duplicate()
	game.opening_room = game.INVALID_ROOM
	game.opening_origin_room = game.INVALID_ROOM
	game.opening_hero = null
	game.opening_timer_left = 0.0
	game.opening_heroes.clear()
	open_room(game, breached_room)
	for breach_hero_variant in breach_heroes:
		var breach_hero: Variant = breach_hero_variant
		if breach_hero != null and is_instance_valid(breach_hero):
			game.issue_hero_steps(breach_hero, [
				game.make_hero_step(breached_room, game.doorway_navigation_position(breached_room, from_room)),
			])
	game.update_hud()

static func hero_emits_room_light(_game: Node, hero: Variant) -> bool:
	return hero != null and is_instance_valid(hero) and hero.current_health > 0.0 and bool(hero.light_cantrip_active)

static func room_has_wave_torch_light(game: Node, room: Dictionary) -> bool:
	var expiry_wave: int = int(room.get("wave_torch_until_wave", -1))
	if expiry_wave < 0:
		return false
	if game.wave_index < expiry_wave:
		return true
	return game.wave_index == expiry_wave and game.wave_in_progress()

static func refresh_room_lighting_states(game: Node) -> void:
	var changed: bool = false
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		var previous_lit: bool = bool(room.get("lit", false))
		var lit: bool = bool(room.get("crystal", false)) or bool(room.get("permanent_light", false)) or int(room.get("temporary_light_turns", 0)) > 0 or room_has_wave_torch_light(game, room)
		if not lit:
			for hero in game.heroes:
				if not hero_emits_room_light(game, hero):
					continue
				if hero.current_room == room_coord and game.room_rect(room_coord).has_point(hero.global_position):
					lit = true
					break
		room["lit"] = lit
		if previous_lit != lit:
			changed = true
	if changed:
		game.invalidate_static_dungeon_layer()

static func apply_temporary_light_to_room(game: Node, room_coord: Vector2i, turn_count: int) -> bool:
	if turn_count <= 0 or not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	room["temporary_light_turns"] = maxi(int(room.get("temporary_light_turns", 0)), turn_count)
	refresh_room_lighting_states(game)
	return true

static func apply_wave_torch_light_to_room(game: Node, room_coord: Vector2i) -> bool:
	if not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	room["wave_torch_until_wave"] = maxi(int(room.get("wave_torch_until_wave", -1)), game.wave_index + 1)
	refresh_room_lighting_states(game)
	return true

static func apply_portable_item_effects_on_door_open(_game: Node) -> void:
	return

static func advance_temporary_room_lights(game: Node, turn_count: int = 1) -> void:
	if turn_count <= 0:
		return
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if int(room.get("temporary_light_turns", 0)) <= 0:
			continue
		var remaining_turns: int = max(0, int(room.get("temporary_light_turns", 0)) - turn_count)
		room["temporary_light_turns"] = remaining_turns
	refresh_room_lighting_states(game)

static func open_room(game: Node, room_coord: Vector2i) -> void:
	if game.rooms[room_coord]["opened"]:
		return
	advance_temporary_room_lights(game, 1)
	var room: Dictionary = game.rooms[room_coord]
	room["opened"] = true
	game.opened_rooms += 1
	game.doors_opened += 1
	GAME_INVENTORY_ITEM_FLOW.clear_all_merchant_buybacks(game)
	var completed_research_title: String = game.advance_active_research_on_door_open()
	game.resolve_spell_scroll_studies()
	game.expire_door_turn_hand_cards()
	game.advance_item_door_card_generators(1)
	game.advance_hero_builtin_door_card_generators(1)
	apply_portable_item_effects_on_door_open(game)
	var door_reward: Dictionary = calculate_door_rewards(game)
	game.food += int(door_reward["food"])
	game.industry += int(door_reward["industry"])
	game.science += int(door_reward["science"])
	var dust_reward: int = 0
	if game.rng.randf() < game.ROOM_OPEN_DUST_CHANCE:
		dust_reward = game.rng.randi_range(game.ROOM_OPEN_DUST_MIN, game.ROOM_OPEN_DUST_MAX)
		game.dust += dust_reward
		var dust_fx_position: Vector2 = game.room_walkable_center(room_coord)
		game.projectiles.append({
			"kind": "dust_burst",
			"position": dust_fx_position,
			"previous": dust_fx_position,
			"target_position": dust_fx_position,
			"color": Color("f3d88f"),
			"radius": 52.0,
			"impact_radius": 52.0,
			"lifetime_left": 0.44,
			"blast_duration": 0.44,
			"width": 2.4,
		})
	if room_coord != game.crystal_room:
		game.spawn_ground_loot(room_coord)
	spawn_door_reward_texts(game, room_coord, door_reward, dust_reward)
	game.refresh_camera_bounds()
	game.invalidate_static_dungeon_layer()
	game.door_wave_auto_heal_pending = true
	game.launch_wave(room_coord)
	game.status_message = "Opened %s. +%d food, +%d materials, +%d arcana." % [game.room_title(room_coord), int(door_reward["food"]), int(door_reward["industry"]), int(door_reward["science"])]
	if dust_reward > 0:
		game.status_message += " +%d dust." % dust_reward
	if room_coord == game.exit_room:
		game.status_message += " Exit discovered."
	var merchant_theme: String = String(room.get("merchant_theme", ""))
	if merchant_theme != "":
		var merchant_name: String = "merchant"
		match merchant_theme:
			"food":
				merchant_name = "food merchant"
			"materials":
				merchant_name = "materials merchant"
			"arcana":
				merchant_name = "arcana merchant"
			"dust":
				merchant_name = "dust merchant"
		game.status_message += " A %s has set up in this room. Use room actions to trade." % merchant_name
	if completed_research_title != "":
		game.status_message += " Research complete: %s." % completed_research_title

static func calculate_door_rewards(game: Node) -> Dictionary:
	var food_reward: int = game.DOOR_REWARD_FOOD_BASE
	var industry_reward: int = game.DOOR_REWARD_INDUSTRY_BASE
	var science_reward: int = game.DOOR_REWARD_SCIENCE_BASE
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if not room["opened"] or not room["lit"]:
			continue
		match String(room["major_module_type"]):
			game.MAJOR_MODULE_FOOD:
				if float(room["major_health"]) > 0.0 and not bool(room.get("major_under_construction", false)):
					food_reward += game.major_module_door_yield(game.major_module_level(game.MAJOR_MODULE_FOOD))
			game.MAJOR_MODULE_SCIENCE:
				if float(room["major_health"]) > 0.0 and not bool(room.get("major_under_construction", false)):
					science_reward += game.major_module_door_yield(game.major_module_level(game.MAJOR_MODULE_SCIENCE))
			game.MAJOR_MODULE_INDUSTRY:
				if float(room["major_health"]) > 0.0 and not bool(room.get("major_under_construction", false)):
					industry_reward += game.major_module_door_yield(game.major_module_level(game.MAJOR_MODULE_INDUSTRY))
	return {
		"food": food_reward,
		"industry": industry_reward,
		"science": science_reward,
	}

static func spawn_door_reward_texts(game: Node, room_coord: Vector2i, door_reward: Dictionary, dust_reward: int) -> void:
	var popup_entries: Array = [
		{"text": "+%d Food" % int(door_reward.get("food", 0)), "color": Color("9ee28b"), "offset": Vector2(-84.0, -14.0)},
		{"text": "+%d Mat" % int(door_reward.get("industry", 0)), "color": Color("f1c26b"), "offset": Vector2(0.0, -30.0)},
		{"text": "+%d Arc" % int(door_reward.get("science", 0)), "color": Color("8bc1ff"), "offset": Vector2(84.0, -14.0)},
	]
	if dust_reward > 0:
		popup_entries.append({"text": "+%d Dust" % dust_reward, "color": Color("f3d88f"), "offset": Vector2(0.0, 12.0)})
	var anchor: Vector2 = game.room_walkable_center(room_coord)
	for popup_entry_variant in popup_entries:
		var popup_entry: Dictionary = popup_entry_variant
		add_resource_floating_text(game, anchor + Vector2(popup_entry.get("offset", Vector2.ZERO)), String(popup_entry.get("text", "")), popup_entry.get("color", Color.WHITE))

static func add_resource_floating_text(game: Node, world_position: Vector2, popup_text: String, popup_color: Color) -> void:
	game.floating_resource_texts.append({
		"position": world_position,
		"text": popup_text,
		"color": popup_color,
		"timer_left": game.RESOURCE_FLOAT_DURATION,
	})

static func advance_floating_resource_texts(game: Node, delta: float) -> void:
	var active_popups: Array = []
	for popup_variant in game.floating_resource_texts:
		var popup: Dictionary = popup_variant
		popup["timer_left"] = maxf(float(popup.get("timer_left", 0.0)) - delta, 0.0)
		if float(popup["timer_left"]) > 0.0:
			active_popups.append(popup)
	game.floating_resource_texts = active_popups

static func advance_wave_recovery(game: Node, delta: float) -> void:
	if game.door_wave_auto_heal_pending and game.pending_enemy_spawns.is_empty() and game.enemies.is_empty():
		game.door_wave_auto_heal_pending = false
		game.door_wave_healing_active = true
		for hero in game.heroes:
			if is_instance_valid(hero):
				hero.combo_points = 0
		game.save_checkpoint("room_combat_finished", false)
		game.status_message = "The wave is over. Heroes are recovering."
		refresh_room_lighting_states(game)
		game.update_hud()
	if not game.door_wave_healing_active:
		return
	var everyone_full: bool = true
	for hero in game.heroes:
		if not is_instance_valid(hero):
			continue
		if hero.current_health < hero.max_health - 0.05:
			hero.heal(game.POST_WAVE_HEAL_RATE * delta)
		if hero.current_health < hero.max_health - 0.05:
			everyone_full = false
	if everyone_full:
		game.door_wave_healing_active = false
		game.status_message = "The wave is over. The heroes recovered."
	game.update_hud()

static func all_floor_doors_opened(game: Node) -> bool:
	return game.opened_rooms >= game.rooms.size() and not game.rooms.is_empty()
