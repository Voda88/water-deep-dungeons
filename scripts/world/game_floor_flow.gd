extends RefCounted

const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/inventory/game_inventory_item_flow.gd")
const GAME_ENEMY_DEFS: GDScript = preload("res://scripts/content/game_enemy_defs.gd")
const OPENED_DOOR_EVENT_BONUS_MIN: int = 7
const OPENED_DOOR_EVENT_BONUS_MAX: int = 9
const ROOM_OPENING_HUD_UPDATE_INTERVAL: float = 0.12
const ROOM_OPENING_HUD_PERCENT_STEP: int = 5
const ROOM_OPENING_LAST_HUD_UPDATE_META: StringName = &"room_opening_last_hud_update"
const ROOM_OPENING_LAST_HUD_PERCENT_META: StringName = &"room_opening_last_hud_percent"

static func start_room_opening(game: Node, room_coord: Vector2i, from_room: Vector2i) -> void:
	game.opening_room = room_coord
	game.opening_origin_room = from_room
	game.opening_timer_left = game.DOOR_OPEN_DURATION
	game.set_meta(ROOM_OPENING_LAST_HUD_UPDATE_META, 0.0)
	game.set_meta(ROOM_OPENING_LAST_HUD_PERCENT_META, -1)
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
	var progress_percent: int = clampi(int(progress_ratio * 100.0), 0, 99)
	var last_hud_update_age: float = float(game.get_meta(ROOM_OPENING_LAST_HUD_UPDATE_META, 0.0)) + delta
	var last_hud_percent: int = int(game.get_meta(ROOM_OPENING_LAST_HUD_PERCENT_META, -1))
	var should_refresh_hud: bool = last_hud_update_age >= ROOM_OPENING_HUD_UPDATE_INTERVAL
	if last_hud_percent < 0:
		should_refresh_hud = true
	elif progress_percent - last_hud_percent >= ROOM_OPENING_HUD_PERCENT_STEP:
		should_refresh_hud = true
	if not should_refresh_hud:
		game.set_meta(ROOM_OPENING_LAST_HUD_UPDATE_META, last_hud_update_age)
		return
	game.status_message = "Opening %s from %s. %d%%" % [game.room_title(game.opening_room), game.room_title(game.opening_origin_room), progress_percent]
	game.update_hud()
	game.set_meta(ROOM_OPENING_LAST_HUD_UPDATE_META, 0.0)
	game.set_meta(ROOM_OPENING_LAST_HUD_PERCENT_META, progress_percent)

static func finish_room_opening(game: Node) -> void:
	var breached_room: Vector2i = game.opening_room
	var from_room: Vector2i = game.opening_origin_room
	var breach_heroes: Array = game.opening_heroes.duplicate()
	game.opening_room = game.INVALID_ROOM
	game.opening_origin_room = game.INVALID_ROOM
	game.opening_hero = null
	game.opening_timer_left = 0.0
	if game.has_meta(ROOM_OPENING_LAST_HUD_UPDATE_META):
		game.remove_meta(ROOM_OPENING_LAST_HUD_UPDATE_META)
	if game.has_meta(ROOM_OPENING_LAST_HUD_PERCENT_META):
		game.remove_meta(ROOM_OPENING_LAST_HUD_PERCENT_META)
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
		game.refresh_static_visible_room_states()

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

static func apply_portable_item_effects_on_door_open(game: Node) -> void:
	for hero_variant in game.heroes:
		var hero: Variant = hero_variant
		if hero == null or not is_instance_valid(hero):
			continue
		var kept_poisons: Array = []
		for poison_variant in Array(hero.applied_poisons):
			var poison_state: Dictionary = Dictionary(poison_variant).duplicate(true)
			var expires_on_doors_opened: int = int(poison_state.get("expires_on_doors_opened", -1))
			if expires_on_doors_opened >= 0 and game.doors_opened >= expires_on_doors_opened:
				continue
			kept_poisons.append(poison_state)
		hero.applied_poisons = kept_poisons
		if int(hero.temporary_skulker_until_doors_opened) > 0 and game.doors_opened >= int(hero.temporary_skulker_until_doors_opened):
			hero.temporary_skulker_until_doors_opened = 0
	game.sync_hero_skulking_visual_states()

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
	if game.rooms.has(room_coord) and game.rooms[room_coord].has("hidden_dust_reward"):
		dust_reward = maxi(int(game.rooms[room_coord].get("hidden_dust_reward", 0)), 0)
	else:
		if game.rooms.has(room_coord):
			var room_data: Dictionary = Dictionary(game.rooms[room_coord]).duplicate(true)
			var room_rng: RandomNumberGenerator = RandomNumberGenerator.new()
			var seed_text: String = "%d:%d:%d:%s" % [game.floor_index, room_coord.x, room_coord.y, String(room_data.get("profile", "room"))]
			room_rng.seed = int(hash(seed_text))
			if room_rng.randf() < game.ROOM_OPEN_DUST_CHANCE:
				dust_reward = room_rng.randi_range(game.ROOM_OPEN_DUST_MIN, game.ROOM_OPEN_DUST_MAX)
			room_data["hidden_dust_reward"] = dust_reward
			game.rooms[room_coord] = room_data
		else:
			if game.rng.randf() < game.ROOM_OPEN_DUST_CHANCE:
				dust_reward = game.rng.randi_range(game.ROOM_OPEN_DUST_MIN, game.ROOM_OPEN_DUST_MAX)
	var opened_door_bonus: Dictionary = apply_opened_door_event(game, room_coord)
	return {
		"door_reward": door_reward,
		"dust_reward": dust_reward,
		"opened_door_bonus": opened_door_bonus,
	}

static func apply_room_open_rewards_immediately(game: Node, room_coord: Vector2i, room_open_reward_bundle: Dictionary) -> Dictionary:
	var dust_reward: int = maxi(int(room_open_reward_bundle.get("dust_reward", 0)), 0)
	if dust_reward > 0:
		game.dust += dust_reward
		preview_room_open_rewards(game, room_coord, room_open_reward_bundle)

	return {
		"food": 0,
		"industry": 0,
		"science": 0,
		"dust": dust_reward,
	}

static func queue_room_open_rewards_for_wave_defeat(game: Node, room_coord: Vector2i, room_open_reward_bundle: Dictionary) -> void:
	var door_reward: Dictionary = Dictionary(room_open_reward_bundle.get("door_reward", {}))
	var dust_reward: int = maxi(int(room_open_reward_bundle.get("dust_reward", 0)), 0)
	var opened_door_bonus: Dictionary = Dictionary(room_open_reward_bundle.get("opened_door_bonus", {}))
	var delayed_food: int = int(door_reward.get("food", 0))
	var delayed_industry: int = int(door_reward.get("industry", 0))
	var delayed_science: int = int(door_reward.get("science", 0))
	if not opened_door_bonus.is_empty():
		var bonus_amount: int = int(opened_door_bonus.get("amount", 0))
		match String(opened_door_bonus.get("id", "")):
			game.BONUS_RESOURCE_EVENT_FOOD:
				delayed_food += bonus_amount
			game.BONUS_RESOURCE_EVENT_INDUSTRY:
				delayed_industry += bonus_amount
			game.BONUS_RESOURCE_EVENT_SCIENCE:
				delayed_science += bonus_amount
			_:
				pass
	if not game.pending_room_open_reward_totals.has("food"):
		game.pending_room_open_reward_totals["food"] = 0
	if not game.pending_room_open_reward_totals.has("industry"):
		game.pending_room_open_reward_totals["industry"] = 0
	if not game.pending_room_open_reward_totals.has("science"):
		game.pending_room_open_reward_totals["science"] = 0
	game.pending_room_open_reward_totals["food"] = int(game.pending_room_open_reward_totals.get("food", 0)) + delayed_food
	game.pending_room_open_reward_totals["industry"] = int(game.pending_room_open_reward_totals.get("industry", 0)) + delayed_industry
	game.pending_room_open_reward_totals["science"] = int(game.pending_room_open_reward_totals.get("science", 0)) + delayed_science
	game.pending_door_open_income.append({
		"room": room_coord,
		"door_reward": {
			"food": int(door_reward.get("food", 0)),
			"industry": int(door_reward.get("industry", 0)),
			"science": int(door_reward.get("science", 0)),
		},
		"dust_reward": dust_reward,
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
	var total_food: int = int(game.pending_room_open_reward_totals.get("food", 0))
	var total_industry: int = int(game.pending_room_open_reward_totals.get("industry", 0))
	var total_science: int = int(game.pending_room_open_reward_totals.get("science", 0))
	if game.pending_door_open_income.is_empty() and total_food <= 0 and total_industry <= 0 and total_science <= 0:
		return {}
	var total_dust: int = 0
	if total_food > 0:
		game.food += total_food
	if total_industry > 0:
		game.industry += total_industry
	if total_science > 0:
		game.science += total_science
	game.pending_room_open_reward_totals["food"] = 0
	game.pending_room_open_reward_totals["industry"] = 0
	game.pending_room_open_reward_totals["science"] = 0
	var pending_entries: Array = Array(game.pending_door_open_income)
	game.pending_door_open_income.clear()
	for pending_entry_variant in pending_entries:
		var pending_entry: Dictionary = Dictionary(pending_entry_variant)
		var room_coord: Vector2i = Vector2i(pending_entry.get("room", game.INVALID_ROOM))
		var door_reward: Dictionary = Dictionary(pending_entry.get("door_reward", {}))
		var dust_reward: int = maxi(int(pending_entry.get("dust_reward", 0)), 0)
		total_dust += dust_reward
		game.dust += dust_reward
		var opened_door_bonus: Dictionary = Dictionary(pending_entry.get("opened_door_bonus", {}))
		if room_coord != game.INVALID_ROOM and game.rooms.has(room_coord):
			spawn_door_reward_texts(game, room_coord, door_reward, dust_reward, opened_door_bonus)
			preview_room_open_rewards(game, room_coord, {
				"dust_reward": dust_reward,
			})
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

static func room_has_active_operate_major_module(game: Node, room_coord: Vector2i) -> bool:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	if not bool(room.get("opened", false)) or not bool(room.get("lit", false)):
		return false
	if String(room.get("major_module_type", "")) == "":
		return false
	if float(room.get("major_health", 0.0)) <= 0.0:
		return false
	if bool(room.get("major_under_construction", false)):
		return false
	return true

static func hero_operate_candidate_room(game: Node, hero: Variant) -> Vector2i:
	if hero == null or not is_instance_valid(hero):
		return game.INVALID_ROOM
	if not game.hero_is_active(hero) or not game.hero_can_operate_major_modules(hero):
		return game.INVALID_ROOM
	if hero.pending_room != game.HERO_INVALID_ROOM:
		return game.INVALID_ROOM
	var room_coord: Vector2i = Vector2i(hero.current_room)
	if not room_has_active_operate_major_module(game, room_coord):
		return game.INVALID_ROOM
	if not game.room_rect(room_coord).has_point(hero.global_position):
		return game.INVALID_ROOM
	return room_coord

static func clear_hero_operate_attunement(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if Vector2i(hero.operate_room) == game.INVALID_ROOM and not bool(hero.operate_attuned) and int(hero.operate_started_at_door) < 0:
		return
	hero.operate_room = game.INVALID_ROOM
	hero.operate_started_at_door = -1
	hero.operate_attuned = false
	hero.operate_turns_left = 0
	hero.queue_redraw()

static func sync_hero_operate_attunement_states(game: Node) -> void:
	for hero_variant in game.heroes:
		var hero: Variant = hero_variant
		if hero == null or not is_instance_valid(hero):
			continue
		if not game.hero_can_operate_major_modules(hero):
			clear_hero_operate_attunement(game, hero)
			continue
		var candidate_room: Vector2i = hero_operate_candidate_room(game, hero)
		if String(hero.hero_class_id) == game.HERO_CLASS_CLERIC and int(hero.operate_turns_left) > 0:
			if room_has_active_operate_major_module(game, Vector2i(hero.operate_room)):
				hero.operate_attuned = true
				continue
			clear_hero_operate_attunement(game, hero)
			continue
		if candidate_room == game.INVALID_ROOM:
			clear_hero_operate_attunement(game, hero)
			continue
		var changed: bool = false
		if Vector2i(hero.operate_room) != candidate_room:
			hero.operate_room = candidate_room
			hero.operate_started_at_door = game.doors_opened
			hero.operate_attuned = false
			changed = true
		elif int(hero.operate_started_at_door) < 0:
			hero.operate_started_at_door = game.doors_opened
			changed = true
		if changed:
			hero.queue_redraw()

static func resolve_hero_operate_attunement_on_door_open(game: Node) -> void:
	sync_hero_operate_attunement_states(game)
	for hero_variant in game.heroes:
		var hero: Variant = hero_variant
		if hero == null or not is_instance_valid(hero):
			continue
		if not game.hero_can_operate_major_modules(hero):
			continue
		if Vector2i(hero.operate_room) == game.INVALID_ROOM:
			continue
		if bool(hero.operate_attuned):
			continue
		if game.doors_opened <= int(hero.operate_started_at_door):
			continue
		hero.operate_attuned = true
		hero.queue_redraw()

static func calculate_operate_major_module_wave_bonus(game: Node) -> Dictionary:
	var rewards: Dictionary = {
		"food": 0,
		"industry": 0,
		"science": 0,
		"entries": [],
	}
	var entries: Array = []
	for hero_variant in game.heroes:
		var hero: Variant = hero_variant
		if hero == null or not is_instance_valid(hero):
			continue
		if not bool(hero.operate_attuned):
			continue
		if not game.hero_can_operate_major_modules(hero):
			continue
		var attuned_room: Vector2i = Vector2i(hero.operate_room)
		if attuned_room == game.INVALID_ROOM:
			continue
		var cleric_temporary_operate: bool = String(hero.hero_class_id) == game.HERO_CLASS_CLERIC and int(hero.operate_turns_left) > 0
		if not cleric_temporary_operate and (Vector2i(hero.current_room) != attuned_room or hero.pending_room != game.HERO_INVALID_ROOM):
			continue
		if not room_has_active_operate_major_module(game, attuned_room):
			continue
		var wit_bonus: int = maxi(game.hero_operate_wit(hero), 0)
		if wit_bonus <= 0:
			continue
		var room: Dictionary = game.rooms[attuned_room]
		var major_type: String = String(room.get("major_module_type", ""))
		match major_type:
			game.MAJOR_MODULE_FOOD:
				rewards["food"] = int(rewards.get("food", 0)) + wit_bonus
			game.MAJOR_MODULE_INDUSTRY:
				rewards["industry"] = int(rewards.get("industry", 0)) + wit_bonus
			game.MAJOR_MODULE_SCIENCE:
				rewards["science"] = int(rewards.get("science", 0)) + wit_bonus
			_:
				continue
		entries.append({
			"hero_name": String(hero.hero_name),
			"room": attuned_room,
			"major_module_type": major_type,
			"wit": wit_bonus,
		})
	rewards["entries"] = entries
	return rewards

static func consume_cleric_operate_turns(game: Node) -> void:
	for hero_variant in game.heroes:
		var hero: Variant = hero_variant
		if hero == null or not is_instance_valid(hero) or int(hero.operate_turns_left) <= 0:
			continue
		clear_hero_operate_attunement(game, hero)

static func open_room(game: Node, room_coord: Vector2i) -> void:
	if game.rooms[room_coord]["opened"]:
		return
	advance_temporary_room_lights(game, 1)
	var room: Dictionary = game.rooms[room_coord]
	room["opened"] = true
	room["scry_revealed"] = false
	game.opened_rooms += 1
	game.doors_opened += 1
	resolve_hero_operate_attunement_on_door_open(game)
	GAME_INVENTORY_ITEM_FLOW.clear_all_merchant_buybacks(game)
	var completed_research_title: String = game.advance_active_research_on_door_open()
	game.resolve_spell_scroll_studies()
	game.expire_door_turn_hand_cards()
	game.advance_item_door_card_generators(1)
	game.advance_hero_builtin_door_card_generators(1)
	apply_portable_item_effects_on_door_open(game)
	var room_open_reward_bundle: Dictionary = build_room_open_reward_bundle(game, room_coord)
	var immediate_room_reward: Dictionary = apply_room_open_rewards_immediately(game, room_coord, room_open_reward_bundle)
	var delayed_room_reward_bundle: Dictionary = room_open_reward_bundle.duplicate(true)
	delayed_room_reward_bundle["dust_reward"] = 0
	queue_room_open_rewards_for_wave_defeat(game, room_coord, delayed_room_reward_bundle)
	game.door_wave_healing_active = false
	game.door_wave_major_payout_pending = true
	game.door_wave_auto_heal_pending = true
	game.door_wave_spawns_incoming = true
	game.launch_wave(room_coord)
	if room_coord != game.crystal_room:
		game.spawn_ground_loot(room_coord)
	game.refresh_camera_bounds()
	game.sync_static_room_instance(room_coord)
	game.queue_adjacent_room_prewarm(room_coord)
	game.status_message = "Opened %s. Immediate reward +%d dust. Food/materials/arcana payout flagged for wave clear." % [
		game.room_title(room_coord),
		int(immediate_room_reward.get("dust", 0)),
	]
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
		game.update_hud()

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
	var operate_bonus: Dictionary = calculate_operate_major_module_wave_bonus(game)
	food_reward += int(operate_bonus.get("food", 0))
	industry_reward += int(operate_bonus.get("industry", 0))
	science_reward += int(operate_bonus.get("science", 0))
	return {
		"food": food_reward,
		"industry": industry_reward,
		"science": science_reward,
		"operate_bonus": operate_bonus,
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
	consume_cleric_operate_turns(game)
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

static func active_hostile_enemy_count_for_wave_recovery(game: Node) -> int:
	var active_enemy_count: int = 0
	for enemy_variant in game.enemies:
		if not game.enemy_is_active(enemy_variant):
			continue
		if enemy_variant.has_method("is_converted") and enemy_variant.is_converted():
			continue
		active_enemy_count += 1
	return active_enemy_count

static func active_hostile_door_wave_enemy_count_for_wave_recovery(game: Node) -> int:
	var active_enemy_count: int = 0
	for enemy_variant in game.enemies:
		if not game.enemy_is_active(enemy_variant):
			continue
		if enemy_variant.has_method("is_converted") and enemy_variant.is_converted():
			continue
		if String(enemy_variant.get_meta("spawn_source", "door_wave")) != "door_wave":
			continue
		active_enemy_count += 1
	return active_enemy_count

static func pending_door_wave_spawn_count_for_wave_recovery(game: Node) -> int:
	var pending_count: int = 0
	pending_count += int(game.pending_door_wave_build_count())
	for pending_spawn_variant in game.pending_enemy_spawns:
		var pending_spawn: Dictionary = Dictionary(pending_spawn_variant)
		if String(pending_spawn.get("spawn_source", "door_wave")) != "door_wave":
			continue
		pending_count += maxi(int(pending_spawn.get("remaining", 0)), 0)
	return pending_count

static func dismiss_temporary_summons_on_calm(game: Node) -> int:
	var dismissed_count: int = 0
	for enemy_variant in game.enemies:
		if enemy_variant == null or not is_instance_valid(enemy_variant):
			continue
		if not game.enemy_is_active(enemy_variant):
			continue
		if not enemy_variant.has_meta("temporary_summon"):
			continue
		enemy_variant.converted_time_left = 0.0
		enemy_variant.begin_death()
		enemy_variant.remove_meta("temporary_summon")
		dismissed_count += 1
	return dismissed_count

static func advance_wave_recovery(game: Node, delta: float) -> void:
	var pending_door_wave_spawns: int = pending_door_wave_spawn_count_for_wave_recovery(game)
	var active_door_wave_enemies: int = active_hostile_door_wave_enemy_count_for_wave_recovery(game)
	var calm_now: bool = pending_door_wave_spawns <= 0 and active_door_wave_enemies <= 0
	var cleared_thrash_buffs: int = 0
	if calm_now:
		for hero_variant in game.heroes:
			var hero: Variant = hero_variant
			if hero == null or not is_instance_valid(hero):
				continue
			if game.clear_fighter_rage_throw_buff(hero, true):
				cleared_thrash_buffs += 1
	var dismissed_summons: int = dismiss_temporary_summons_on_calm(game) if calm_now else 0
	if calm_now and bool(game.door_wave_spawns_incoming):
		game.door_wave_spawns_incoming = false
	var has_pending_room_rewards: bool = not game.pending_door_open_income.is_empty()
	var started_recovery_now: bool = false
	if calm_now and game.door_wave_auto_heal_pending:
		game.door_wave_auto_heal_pending = false
		game.door_wave_healing_active = true
		started_recovery_now = true
		for hero in game.heroes:
			if is_instance_valid(hero):
				game.reset_hero_combo(hero)
		game.save_checkpoint("room_combat_finished", false)
		game.status_message = "The wave is over. Heroes are recovering."
		refresh_room_lighting_states(game)
	elif calm_now and not game.door_wave_healing_active and (game.door_wave_major_payout_pending or has_pending_room_rewards):
		game.door_wave_healing_active = true
		started_recovery_now = true
		game.status_message = "The room is calm. Heroes are recovering."

	# Settle delayed door rewards from the same proven recovery trigger as healing.
	if game.door_wave_healing_active:
		var settled_door_reward: Dictionary = apply_room_open_rewards_on_wave_defeat(game)
		var settled_major_reward: Dictionary = apply_major_module_wave_rewards(game)
		if cleared_thrash_buffs > 0:
			game.status_message += " Thrash Around fades as calm returns."
		if dismissed_summons > 0:
			game.status_message += " %d summoned unit%s fade as calm returns." % [dismissed_summons, "" if dismissed_summons == 1 else "s"]
		if not settled_door_reward.is_empty():
			game.status_message += " Room reward +%d food, +%d materials, +%d arcana, +%d dust." % [
				int(settled_door_reward.get("food", 0)),
				int(settled_door_reward.get("industry", 0)),
				int(settled_door_reward.get("science", 0)),
				int(settled_door_reward.get("dust", 0)),
			]
		if not settled_major_reward.is_empty():
			game.status_message += " Major output +%d food, +%d materials, +%d arcana." % [
				int(settled_major_reward.get("food", 0)),
				int(settled_major_reward.get("industry", 0)),
				int(settled_major_reward.get("science", 0)),
			]
		if started_recovery_now or not settled_door_reward.is_empty() or not settled_major_reward.is_empty():
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
