extends RefCounted

const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/inventory/game_inventory_item_flow.gd")
const GAME_ENEMY_DEFS: GDScript = preload("res://scripts/content/game_enemy_defs.gd")
const OPENED_DOOR_EVENT_BONUS_MIN: int = 7
const OPENED_DOOR_EVENT_BONUS_MAX: int = 9

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
	for hero_variant in game.heroes:
		var hero: Variant = hero_variant
		if hero == null or not is_instance_valid(hero):
			continue
		var had_same_open_order: bool = hero.pending_open_room == breached_room and hero.pending_open_origin_room == from_room
		if not had_same_open_order and not breach_heroes.has(hero):
			continue
		hero.pending_open_room = game.HERO_INVALID_ROOM
		hero.pending_open_origin_room = game.HERO_INVALID_ROOM
		if had_same_open_order and not breach_heroes.has(hero):
			hero.move_steps.clear()
			hero.player_command_locked = false
			hero.set_destination(hero.global_position)
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

static func crystal_dust_damage_for_enemy(game: Node, enemy: Variant) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 0.0
	var enemy_role: String = String(enemy.enemy_role)
	if enemy_role == game.ENEMY_TYPE_ORC or enemy_role == game.ENEMY_TYPE_BAT:
		return float(game.CRYSTAL_DUST_DAMAGE_BASE_HIT)
	var goblin_profile: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(game.ENEMY_TYPE_ORC)
	var goblin_attack_damage: float = maxf(float(goblin_profile.get("attack_damage", 20.0)), 0.001)
	var enemy_profile: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(enemy_role)
	var enemy_attack_damage: float = maxf(float(enemy_profile.get("attack_damage", enemy.attack_damage)), 0.0)
	return float(game.CRYSTAL_DUST_DAMAGE_BASE_HIT) * (enemy_attack_damage / goblin_attack_damage)

static func paid_permanent_light_rooms(game: Node) -> Array[Vector2i]:
	var rooms_with_paid_light: Array[Vector2i] = []
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if room_coord == game.crystal_room:
			continue
		var room: Dictionary = game.rooms[room_coord]
		if not bool(room.get("opened", false)):
			continue
		if bool(room.get("permanent_light", false)) and not bool(room.get("permanent_light_seeded", false)):
			rooms_with_paid_light.append(room_coord)
	return rooms_with_paid_light

static func pick_room_for_dust_shutdown(game: Node, candidates: Array[Vector2i]) -> Vector2i:
	var chosen_room: Vector2i = game.INVALID_ROOM
	var chosen_has_heroes: bool = true
	var chosen_distance: int = -1
	for room_coord in candidates:
		var has_heroes: bool = not game.heroes_in_room(room_coord).is_empty()
		var crystal_distance: int = game.room_path_distance(room_coord, game.crystal_room)
		if chosen_room == game.INVALID_ROOM \
		or (chosen_has_heroes and not has_heroes) \
		or (has_heroes == chosen_has_heroes and crystal_distance > chosen_distance) \
		or (has_heroes == chosen_has_heroes and crystal_distance == chosen_distance and (room_coord.y > chosen_room.y or (room_coord.y == chosen_room.y and room_coord.x > chosen_room.x))):
			chosen_room = room_coord
			chosen_has_heroes = has_heroes
			chosen_distance = crystal_distance
	return chosen_room

static func shutdown_room_for_dust(game: Node, room_coord: Vector2i) -> void:
	if not game.rooms.has(room_coord):
		return
	var room: Dictionary = game.rooms[room_coord]
	room["permanent_light"] = false
	room["permanent_light_seeded"] = false
	room["temporary_light_turns"] = 0
	room["wave_torch_until_wave"] = -1

static func apply_crystal_dust_loss(game: Node, dust_points: int) -> Dictionary:
	var result: Dictionary = {
		"dust_lost": 0,
		"rooms_darkened": 0,
	}
	if dust_points <= 0:
		return result
	var paid_lit_rooms: Array[Vector2i] = paid_permanent_light_rooms(game)
	var room_light_cost: int = maxi(int(game.ROOM_LIGHT_DUST_COST), 1)
	var reserved_dust: int = paid_lit_rooms.size() * room_light_cost
	var total_dust_before: int = maxi(game.dust, 0) + reserved_dust
	var total_dust_after: int = maxi(total_dust_before - dust_points, 0)
	result["dust_lost"] = total_dust_before - total_dust_after
	var supported_paid_rooms: int = clampi(int(floor(float(total_dust_after) / float(room_light_cost))), 0, paid_lit_rooms.size())
	var rooms_to_darken: int = maxi(paid_lit_rooms.size() - supported_paid_rooms, 0)
	var rooms_darkened: int = 0
	while rooms_to_darken > 0 and not paid_lit_rooms.is_empty():
		var room_to_darken: Vector2i = pick_room_for_dust_shutdown(game, paid_lit_rooms)
		if room_to_darken == game.INVALID_ROOM:
			break
		shutdown_room_for_dust(game, room_to_darken)
		paid_lit_rooms.erase(room_to_darken)
		rooms_to_darken -= 1
		rooms_darkened += 1
	var reserved_dust_after: int = supported_paid_rooms * room_light_cost
	game.dust = maxi(total_dust_after - reserved_dust_after, 0)
	if rooms_darkened > 0:
		refresh_room_lighting_states(game)
	result["rooms_darkened"] = rooms_darkened
	return result

static func total_crystal_dust_support(game: Node) -> int:
	var room_light_cost: int = maxi(int(game.ROOM_LIGHT_DUST_COST), 1)
	var reserved_dust: int = paid_permanent_light_rooms(game).size() * room_light_cost
	return maxi(int(game.dust), 0) + reserved_dust

static func apply_crystal_damage_from_enemy(game: Node, enemy: Variant) -> Dictionary:
	var result: Dictionary = {
		"dust_damage": 0.0,
		"dust_points_lost": 0,
		"rooms_darkened": 0,
	}
	if enemy == null or not is_instance_valid(enemy):
		return result
	var dust_damage: float = maxf(crystal_dust_damage_for_enemy(game, enemy), 0.0)
	result["dust_damage"] = dust_damage
	if dust_damage <= 0.0:
		return result
	game.crystal_dust_damage_fraction = maxf(float(game.crystal_dust_damage_fraction) + dust_damage, 0.0)
	var dust_points_to_remove: int = int(floor(game.crystal_dust_damage_fraction))
	if dust_points_to_remove <= 0:
		return result
	game.crystal_dust_damage_fraction = maxf(game.crystal_dust_damage_fraction - float(dust_points_to_remove), 0.0)
	var loss_result: Dictionary = apply_crystal_dust_loss(game, dust_points_to_remove)
	result["dust_points_lost"] = int(loss_result.get("dust_lost", 0))
	result["rooms_darkened"] = int(loss_result.get("rooms_darkened", 0))
	return result

static func apply_opened_door_event(game: Node, room_coord: Vector2i) -> Dictionary:
	if room_coord == game.crystal_room:
		return {}
	if not game.rooms.has(room_coord):
		return {}
	var room_data: Dictionary = game.rooms[room_coord]
	var event_id: String = String(room_data.get("feature_bonus_resource_event", ""))
	if event_id == "" or event_id == game.BONUS_RESOURCE_EVENT_NONE:
		return {}
	room_data["feature_bonus_resource_event"] = game.BONUS_RESOURCE_EVENT_NONE
	game.rooms[room_coord] = room_data
	var bonus_amount: int = game.rng.randi_range(OPENED_DOOR_EVENT_BONUS_MIN, OPENED_DOOR_EVENT_BONUS_MAX)
	var popup_text: String = ""
	var status_text: String = ""
	var popup_color: Color = Color.WHITE
	match event_id:
		game.BONUS_RESOURCE_EVENT_FOOD:
			popup_text = "+%d Bonus Food" % bonus_amount
			status_text = "You found a food cache (+%d)." % bonus_amount
			popup_color = Color("9ee28b")
		game.BONUS_RESOURCE_EVENT_INDUSTRY:
			popup_text = "+%d Bonus Materials" % bonus_amount
			status_text = "You found a materials cache (+%d)." % bonus_amount
			popup_color = Color("f1c26b")
		game.BONUS_RESOURCE_EVENT_SCIENCE:
			popup_text = "+%d Bonus Arcana" % bonus_amount
			status_text = "You found an arcana cache (+%d)." % bonus_amount
			popup_color = Color("8bc1ff")
		_:
			return {}
	return {
		"id": event_id,
		"amount": bonus_amount,
		"popup_text": popup_text,
		"status_text": status_text,
		"color": popup_color,
	}

static func build_room_open_reward_bundle(game: Node, room_coord: Vector2i) -> Dictionary:
	var door_reward: Dictionary = calculate_door_rewards(game)
	var dust_reward: int = 0
	if game.rng.randf() < game.ROOM_OPEN_DUST_CHANCE:
		dust_reward = game.rng.randi_range(game.ROOM_OPEN_DUST_MIN, game.ROOM_OPEN_DUST_MAX)
	var opened_door_bonus: Dictionary = apply_opened_door_event(game, room_coord)
	return {
		"door_reward": door_reward,
		"dust_reward": dust_reward,
		"opened_door_bonus": opened_door_bonus,
	}

static func queue_room_open_rewards_for_wave_defeat(game: Node, room_coord: Vector2i, room_open_reward_bundle: Dictionary) -> void:
	var door_reward: Dictionary = Dictionary(room_open_reward_bundle.get("door_reward", {}))
	var dust_reward: int = int(room_open_reward_bundle.get("dust_reward", 0))
	var opened_door_bonus: Dictionary = Dictionary(room_open_reward_bundle.get("opened_door_bonus", {}))
	game.pending_door_open_income.append({
		"room": room_coord,
		"door_reward": {
			"food": int(door_reward.get("food", 0)),
			"industry": int(door_reward.get("industry", 0)),
			"science": int(door_reward.get("science", 0)),
		},
		"dust_reward": maxi(int(dust_reward), 0),
		"opened_door_bonus": opened_door_bonus.duplicate(true),
	})

static func spawn_dust_burst_effect(game: Node, room_coord: Vector2i) -> void:
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

static func preview_room_open_rewards(game: Node, room_coord: Vector2i, room_open_reward_bundle: Dictionary) -> void:
	var dust_reward: int = maxi(int(room_open_reward_bundle.get("dust_reward", 0)), 0)
	if dust_reward <= 0:
		return
	var anchor: Vector2 = game.room_walkable_center(room_coord)
	add_resource_floating_text(game, anchor + Vector2(0.0, 12.0), "+%d Dust" % dust_reward, Color("f3d88f"))
	spawn_dust_burst_effect(game, room_coord)

static func apply_room_open_rewards_on_wave_defeat(game: Node) -> Dictionary:
	if game.pending_door_open_income.is_empty():
		return {}
	var total_food: int = 0
	var total_industry: int = 0
	var total_science: int = 0
	var total_dust: int = 0
	var pending_entries: Array = Array(game.pending_door_open_income)
	game.pending_door_open_income.clear()
	for pending_entry_variant in pending_entries:
		var pending_entry: Dictionary = Dictionary(pending_entry_variant)
		var room_coord: Vector2i = Vector2i(pending_entry.get("room", game.INVALID_ROOM))
		var door_reward: Dictionary = Dictionary(pending_entry.get("door_reward", {}))
		var food_reward: int = int(door_reward.get("food", 0))
		var industry_reward: int = int(door_reward.get("industry", 0))
		var science_reward: int = int(door_reward.get("science", 0))
		var dust_reward: int = maxi(int(pending_entry.get("dust_reward", 0)), 0)
		total_food += food_reward
		total_industry += industry_reward
		total_science += science_reward
		total_dust += dust_reward
		game.food += food_reward
		game.industry += industry_reward
		game.science += science_reward
		game.dust += dust_reward
		var opened_door_bonus: Dictionary = Dictionary(pending_entry.get("opened_door_bonus", {}))
		if not opened_door_bonus.is_empty():
			var bonus_amount: int = int(opened_door_bonus.get("amount", 0))
			match String(opened_door_bonus.get("id", "")):
				game.BONUS_RESOURCE_EVENT_FOOD:
					total_food += bonus_amount
					game.food += bonus_amount
				game.BONUS_RESOURCE_EVENT_INDUSTRY:
					total_industry += bonus_amount
					game.industry += bonus_amount
				game.BONUS_RESOURCE_EVENT_SCIENCE:
					total_science += bonus_amount
					game.science += bonus_amount
				_:
					pass
		if room_coord != game.INVALID_ROOM and game.rooms.has(room_coord):
			spawn_door_reward_texts(game, room_coord, door_reward, dust_reward, opened_door_bonus)
	if total_food <= 0 and total_industry <= 0 and total_science <= 0 and total_dust <= 0:
		return {}
	return {
		"food": total_food,
		"industry": total_industry,
		"science": total_science,
		"dust": total_dust,
	}

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
	var room_open_reward_bundle: Dictionary = build_room_open_reward_bundle(game, room_coord)
	queue_room_open_rewards_for_wave_defeat(game, room_coord, room_open_reward_bundle)
	preview_room_open_rewards(game, room_coord, room_open_reward_bundle)
	game.door_wave_major_payout_pending = true
	game.door_wave_auto_heal_pending = true
	game.launch_wave(room_coord)
	if room_coord != game.crystal_room:
		game.spawn_ground_loot(room_coord)
	game.refresh_camera_bounds()
	game.invalidate_static_dungeon_layer()
	game.status_message = "Opened %s. Door income will be granted after the wave." % game.room_title(room_coord)
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
	return {
		"food": food_reward,
		"industry": industry_reward,
		"science": science_reward,
	}

static func calculate_major_module_wave_rewards(game: Node) -> Dictionary:
	var food_reward: int = 0
	var industry_reward: int = 0
	var science_reward: int = 0
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

static func apply_major_module_wave_rewards(game: Node) -> Dictionary:
	if not bool(game.door_wave_major_payout_pending):
		return {}
	game.door_wave_major_payout_pending = false
	var major_reward: Dictionary = calculate_major_module_wave_rewards(game)
	var food_reward: int = int(major_reward.get("food", 0))
	var industry_reward: int = int(major_reward.get("industry", 0))
	var science_reward: int = int(major_reward.get("science", 0))
	if food_reward > 0:
		game.food += food_reward
	if industry_reward > 0:
		game.industry += industry_reward
	if science_reward > 0:
		game.science += science_reward
	if food_reward <= 0 and industry_reward <= 0 and science_reward <= 0:
		return {}
	return {
		"food": food_reward,
		"industry": industry_reward,
		"science": science_reward,
	}

static func spawn_door_reward_texts(game: Node, room_coord: Vector2i, door_reward: Dictionary, _dust_reward: int, opened_door_bonus: Dictionary = {}) -> void:
	var popup_entries: Array = []
	popup_entries.append({"text": "+%d Food" % int(door_reward.get("food", 0)), "color": Color("9ee28b"), "offset": Vector2(-84.0, -14.0)})
	popup_entries.append({"text": "+%d Mat" % int(door_reward.get("industry", 0)), "color": Color("f1c26b"), "offset": Vector2(0.0, -30.0)})
	popup_entries.append({"text": "+%d Arc" % int(door_reward.get("science", 0)), "color": Color("8bc1ff"), "offset": Vector2(84.0, -14.0)})
	if not opened_door_bonus.is_empty():
		popup_entries.append({
			"text": String(opened_door_bonus.get("popup_text", "")),
			"color": opened_door_bonus.get("color", Color.WHITE),
			"offset": Vector2(0.0, 12.0),
		})
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
	if game.door_wave_major_payout_pending and game.door_wave_healing_active and not game.door_wave_auto_heal_pending:
		var queued_major_reward: Dictionary = apply_major_module_wave_rewards(game)
		var queued_door_reward: Dictionary = apply_room_open_rewards_on_wave_defeat(game)
		if not queued_door_reward.is_empty():
			game.status_message += " Door income +%d food, +%d materials, +%d arcana, +%d dust." % [
				int(queued_door_reward.get("food", 0)),
				int(queued_door_reward.get("industry", 0)),
				int(queued_door_reward.get("science", 0)),
				int(queued_door_reward.get("dust", 0)),
			]
		if not queued_major_reward.is_empty():
			game.status_message += " Major output +%d food, +%d materials, +%d arcana." % [
				int(queued_major_reward.get("food", 0)),
				int(queued_major_reward.get("industry", 0)),
				int(queued_major_reward.get("science", 0)),
			]
		if not queued_door_reward.is_empty() or not queued_major_reward.is_empty():
			game.update_hud()
	if game.door_wave_auto_heal_pending and game.pending_enemy_spawns.is_empty() and game.enemies.is_empty():
		game.door_wave_auto_heal_pending = false
		game.door_wave_healing_active = true
		var major_reward: Dictionary = apply_major_module_wave_rewards(game)
		var door_reward: Dictionary = apply_room_open_rewards_on_wave_defeat(game)
		for hero in game.heroes:
			if is_instance_valid(hero):
				hero.combo_points = 0
		game.save_checkpoint("room_combat_finished", false)
		game.status_message = "The wave is over. Heroes are recovering."
		if not door_reward.is_empty():
			game.status_message += " Door income +%d food, +%d materials, +%d arcana, +%d dust." % [
				int(door_reward.get("food", 0)),
				int(door_reward.get("industry", 0)),
				int(door_reward.get("science", 0)),
				int(door_reward.get("dust", 0)),
			]
		if not major_reward.is_empty():
			game.status_message += " Major output +%d food, +%d materials, +%d arcana." % [
				int(major_reward.get("food", 0)),
				int(major_reward.get("industry", 0)),
				int(major_reward.get("science", 0)),
			]
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
		var calm_major_reward: Dictionary = apply_major_module_wave_rewards(game)
		var calm_door_reward: Dictionary = apply_room_open_rewards_on_wave_defeat(game)
		game.door_wave_healing_active = false
		game.status_message = "The wave is over. The heroes recovered."
		if not calm_door_reward.is_empty():
			game.status_message += " Door income +%d food, +%d materials, +%d arcana, +%d dust." % [
				int(calm_door_reward.get("food", 0)),
				int(calm_door_reward.get("industry", 0)),
				int(calm_door_reward.get("science", 0)),
				int(calm_door_reward.get("dust", 0)),
			]
		if not calm_major_reward.is_empty():
			game.status_message += " Major output +%d food, +%d materials, +%d arcana." % [
				int(calm_major_reward.get("food", 0)),
				int(calm_major_reward.get("industry", 0)),
				int(calm_major_reward.get("science", 0)),
			]
	game.update_hud()

static func all_floor_doors_opened(game: Node) -> bool:
	return game.opened_rooms >= game.rooms.size() and not game.rooms.is_empty()
