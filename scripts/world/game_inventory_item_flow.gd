extends RefCounted

const GAME_DUNGEON_BUILDER: GDScript = preload("res://scripts/world/game_dungeon_builder.gd")

static func item_size_in_cells(game: Node, item: Dictionary) -> Vector2i:
	var item_def: Dictionary = game.item_defs.get(String(item.get("item_id", "")), {})
	var base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	if bool(item.get("rotated", false)):
		return Vector2i(base_size.y, base_size.x)
	return base_size

static func normalize_item_instance(game: Node, item_variant: Variant) -> Dictionary:
	var item: Dictionary = (item_variant as Dictionary).duplicate(true)
	var item_def: Dictionary = game.item_defs.get(String(item.get("item_id", "")), {})
	if not item.has("uid"):
		item["uid"] = game.next_item_uid
		game.next_item_uid += 1
	if item_def.has("max_charges") and not item.has("charges_left"):
		item["charges_left"] = int(item_def.get("max_charges", 0))
	return item

static func make_ground_item(game: Node, item_id: String, world_position: Vector2) -> Dictionary:
	var ground_item: Dictionary = normalize_item_instance(game, {
		"uid": game.next_item_uid,
		"item_id": item_id,
		"position": world_position,
		"rotated": false,
	})
	game.next_item_uid += 1
	return ground_item

static func make_inventory_item(game: Node, item_id: String, anchor: Vector2i = Vector2i(-99, -99), rotated: bool = false) -> Dictionary:
	var item: Dictionary = {
		"uid": game.next_item_uid,
		"item_id": item_id,
		"rotated": rotated,
	}
	if anchor != game.INVALID_ROOM:
		item["anchor"] = anchor
	game.next_item_uid += 1
	return normalize_item_instance(game, item)

static func default_inventory_items_for_class(game: Node, class_id: String) -> Array:
	var items: Array = []
	match class_id:
		game.HERO_CLASS_WIZARD:
			items.append(make_inventory_item(game, "spellbook", game.INVENTORY_BASE_ORIGIN))
		game.HERO_CLASS_CLERIC:
			items.append(make_inventory_item(game, "holy_symbol", game.INVENTORY_BASE_ORIGIN))
	return items

static func roll_ground_item_id(game: Node) -> String:
	var weighted_item_ids: Array[String] = [
		"ration", "ration",
		"boots", "boots",
		"blade", "blade",
		"buckler",
		"whetstone", "whetstone",
		"banner",
		"lantern",
		"medkit",
		"torch",
		"axe",
		"daggers",
		"scroll_fireball",
		"scroll_magic_missile",
		"scroll_misty_step",
		"scroll_shield",
		"scroll_lightning_bolt",
	]
	if weighted_item_ids.is_empty():
		return ""
	return String(weighted_item_ids[game.rng.randi_range(0, weighted_item_ids.size() - 1)])

static func spawn_ground_loot(game: Node, room_coord: Vector2i) -> void:
	if not game.rooms.has(room_coord):
		return
	if game.rng.randf() > 0.72:
		return
	var loot_count: int = 1
	if game.rng.randf() < 0.18:
		loot_count = 2
	for loot_index in range(loot_count):
		var item_id: String = roll_ground_item_id(game)
		if item_id == "":
			continue
		var item_position: Vector2 = game.clamp_point_to_room(game.room_center(room_coord) + GAME_DUNGEON_BUILDER.random_room_offset(game, 84.0 + float(loot_index) * 28.0), room_coord)
		game.rooms[room_coord]["ground_items"].append(make_ground_item(game, item_id, item_position))

static func ground_item_draw_rect(game: Node, ground_item: Dictionary) -> Rect2:
	var size_cells: Vector2i = item_size_in_cells(game, ground_item)
	var draw_size: Vector2 = Vector2(size_cells) * game.GROUND_ITEM_DRAW_SCALE
	return Rect2(Vector2(ground_item["position"]) - draw_size * 0.5, draw_size)

static func ground_item_pick_rect(game: Node, ground_item: Dictionary) -> Rect2:
	var draw_rect_local: Rect2 = ground_item_draw_rect(game, ground_item)
	var expanded_size: Vector2 = Vector2(
		maxf(draw_rect_local.size.x + 20.0, game.GROUND_ITEM_PICK_MIN_SIZE),
		maxf(draw_rect_local.size.y + 20.0, game.GROUND_ITEM_PICK_MIN_SIZE)
	)
	return Rect2(draw_rect_local.get_center() - expanded_size * 0.5, expanded_size)

static func ground_item_at_world_position(game: Node, world_position: Vector2) -> Dictionary:
	var closest_hit: Dictionary = {}
	var closest_distance: float = game.GROUND_ITEM_PICK_RADIUS
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if not room["opened"]:
			continue
		for item_index in range(room["ground_items"].size() - 1, -1, -1):
			var ground_item: Dictionary = room["ground_items"][item_index]
			var item_center: Vector2 = Vector2(ground_item["position"])
			var item_distance: float = item_center.distance_to(world_position)
			if not ground_item_pick_rect(game, ground_item).has_point(world_position) and item_distance > game.GROUND_ITEM_PICK_RADIUS:
				continue
			if closest_hit.is_empty() or item_distance < closest_distance:
				closest_distance = item_distance
				closest_hit = {
					"room": room_coord,
					"index": item_index,
					"item": ground_item,
				}
	return closest_hit

static func find_ground_item_index(game: Node, room_coord: Vector2i, item_uid: int) -> int:
	if not game.rooms.has(room_coord):
		return -1
	for item_index in range(game.rooms[room_coord]["ground_items"].size()):
		if int(game.rooms[room_coord]["ground_items"][item_index]["uid"]) == item_uid:
			return item_index
	return -1

static func prepare_ground_items_for_room(game: Node, room_coord: Vector2i, ground_items: Array) -> Array:
	var prepared_items: Array = []
	for item_index in range(ground_items.size()):
		var ground_item: Dictionary = normalize_item_instance(game, ground_items[item_index])
		ground_item.erase("anchor")
		var fallback_position: Vector2 = game.room_center(room_coord) + GAME_DUNGEON_BUILDER.random_room_offset(game, 70.0 + float(item_index) * 20.0)
		ground_item["position"] = game.clamp_point_to_room(Vector2(ground_item.get("position", fallback_position)), room_coord)
		prepared_items.append(ground_item)
	return prepared_items

static func inventory_base_cells(game: Node) -> Array:
	var cells: Array = []
	for offset_y in range(game.INVENTORY_BASE_SIZE.y):
		for offset_x in range(game.INVENTORY_BASE_SIZE.x):
			cells.append(game.INVENTORY_BASE_ORIGIN + Vector2i(offset_x, offset_y))
	return cells

static func pack_cells(_game: Node, pack_module: Dictionary) -> Array:
	var cells: Array = []
	var anchor: Vector2i = pack_module.get("anchor", Vector2i(-99, -99))
	var size_cells: Vector2i = pack_module.get("size", Vector2i.ONE)
	if anchor == Vector2i(-99, -99):
		return cells
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			cells.append(anchor + Vector2i(offset_x, offset_y))
	return cells

static func active_inventory_cells_from_packs(game: Node, pack_modules: Array) -> Dictionary:
	var active_cells: Dictionary = {}
	for base_cell in inventory_base_cells(game):
		active_cells[base_cell] = true
	for pack_module_variant in pack_modules:
		for pack_cell in pack_cells(game, pack_module_variant):
			active_cells[pack_cell] = true
	return active_cells

static func inventory_capacity(game: Node, pack_modules: Array) -> int:
	return active_inventory_cells_from_packs(game, pack_modules).size()

static func can_place_pack_module(game: Node, pack_modules: Array, pack_size: Vector2i, anchor: Vector2i, ignore_index: int = -1) -> bool:
	if anchor.x < 0 or anchor.y < 0:
		return false
	if anchor.x + pack_size.x > game.INVENTORY_CANVAS_SIZE.x or anchor.y + pack_size.y > game.INVENTORY_CANVAS_SIZE.y:
		return false
	var occupied_cells: Dictionary = {}
	for base_cell in inventory_base_cells(game):
		occupied_cells[base_cell] = true
	for pack_index in range(pack_modules.size()):
		if pack_index == ignore_index:
			continue
		for pack_cell in pack_cells(game, pack_modules[pack_index]):
			occupied_cells[pack_cell] = true
	var touches_existing: bool = false
	for offset_y in range(pack_size.y):
		for offset_x in range(pack_size.x):
			var cell: Vector2i = anchor + Vector2i(offset_x, offset_y)
			if occupied_cells.has(cell):
				return false
			for direction in game.CARDINAL_DIRS:
				if occupied_cells.has(cell + direction):
					touches_existing = true
	if pack_modules.is_empty():
		return touches_existing
	return touches_existing

static func item_fits_active_cells(game: Node, item: Dictionary, active_cells: Dictionary) -> bool:
	for occupied_cell_variant in item_occupied_cells(game, item):
		var occupied_cell: Vector2i = occupied_cell_variant
		if not active_cells.has(occupied_cell):
			return false
	return true

static func find_default_pack_anchor(game: Node, pack_modules: Array, pack_size: Vector2i) -> Vector2i:
	for anchor_y in range(game.INVENTORY_CANVAS_SIZE.y - pack_size.y + 1):
		for anchor_x in range(game.INVENTORY_CANVAS_SIZE.x - pack_size.x + 1):
			var anchor: Vector2i = Vector2i(anchor_x, anchor_y)
			if can_place_pack_module(game, pack_modules, pack_size, anchor):
				return anchor
	return game.INVALID_ROOM

static func item_occupied_cells(game: Node, item: Dictionary) -> Array:
	var occupied_cells: Array = []
	var anchor: Vector2i = item.get("anchor", game.INVALID_ROOM)
	if anchor == game.INVALID_ROOM:
		return occupied_cells
	var size_cells: Vector2i = item_size_in_cells(game, item)
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			occupied_cells.append(anchor + Vector2i(offset_x, offset_y))
	return occupied_cells

static func can_place_inventory_item(game: Node, hero: Variant, item: Dictionary, anchor: Vector2i, ignore_uid: int = -1) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	var size_cells: Vector2i = item_size_in_cells(game, item)
	if anchor.x < 0 or anchor.y < 0:
		return false
	if anchor.x + size_cells.x > hero.inventory_canvas_size.x or anchor.y + size_cells.y > hero.inventory_canvas_size.y:
		return false
	var active_cells: Dictionary = active_inventory_cells_from_packs(game, hero.pack_modules)
	var occupied_cells: Dictionary = {}
	for other_item_variant in hero.inventory_items:
		var other_item: Dictionary = other_item_variant
		if int(other_item.get("uid", -1)) == ignore_uid:
			continue
		for occupied_cell_variant in item_occupied_cells(game, other_item):
			occupied_cells[occupied_cell_variant] = true
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			var cell: Vector2i = anchor + Vector2i(offset_x, offset_y)
			if not active_cells.has(cell) or occupied_cells.has(cell):
				return false
	return true

static func find_first_inventory_item_anchor(game: Node, hero: Variant, item: Dictionary) -> Vector2i:
	if hero == null or not is_instance_valid(hero):
		return game.INVALID_ROOM
	var size_cells: Vector2i = item_size_in_cells(game, item)
	for anchor_y in range(hero.inventory_canvas_size.y - size_cells.y + 1):
		for anchor_x in range(hero.inventory_canvas_size.x - size_cells.x + 1):
			var anchor: Vector2i = Vector2i(anchor_x, anchor_y)
			if can_place_inventory_item(game, hero, item, anchor):
				return anchor
	return game.INVALID_ROOM

static func add_item_to_hero_inventory(game: Node, hero: Variant, item_variant: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	var item: Dictionary = normalize_item_instance(game, item_variant)
	item.erase("position")
	var anchor: Vector2i = item.get("anchor", game.INVALID_ROOM)
	if anchor == game.INVALID_ROOM or not can_place_inventory_item(game, hero, item, anchor):
		anchor = find_first_inventory_item_anchor(game, hero, item)
	if anchor == game.INVALID_ROOM:
		return false
	item["anchor"] = anchor
	hero.inventory_items.append(item)
	game.apply_inventory_stats_to_hero(hero)
	return true

static func item_has_tag(game: Node, item: Dictionary, tag_name: String) -> bool:
	var item_def: Dictionary = game.item_defs.get(String(item.get("item_id", "")), {})
	return Array(item_def.get("tags", [])).has(tag_name)

static func item_instance_enabled(_game: Node, _item: Dictionary) -> bool:
	return true

static func rotated_socket_offset(game: Node, item: Dictionary, socket_offset: Vector2i) -> Vector2i:
	var item_def: Dictionary = game.item_defs.get(String(item.get("item_id", "")), {})
	var base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	if not bool(item.get("rotated", false)):
		return socket_offset
	return Vector2i(base_size.y - 1 - socket_offset.y, socket_offset.x)

static func socket_match_entries(_game: Node, socket_rule: Dictionary) -> Array:
	if socket_rule.has("matches"):
		return Array(socket_rule.get("matches", []))
	if socket_rule.has("tag"):
		return [{
			"tag": String(socket_rule.get("tag", "")),
			"bonuses": Dictionary(socket_rule.get("bonuses", {})),
		}]
	return []

static func empty_inventory_effect_summary(_game: Node) -> Dictionary:
	return {
		"speed": 0.0,
		"health": 0.0,
		"attack": 0.0,
		"stamina": 0.0,
		"hand_size": 0,
		"card_damage": 0.0,
		"projectile_count": 0,
		"dagger_backstab_bonus": 0.0,
		"card_charge_mult": 1.0,
		"stamina_cost_mult": 1.0,
		"synergies": 0,
		"card_generators": [],
		"combat_passives": [],
		"item_bonus_by_uid": {},
	}

static func apply_inventory_effect_bonuses(target: Dictionary, bonus_stats: Dictionary) -> void:
	for bonus_key_variant in bonus_stats.keys():
		var bonus_key: String = String(bonus_key_variant)
		match bonus_key:
			"hand_size", "projectile_count":
				target[bonus_key] = int(target.get(bonus_key, 0)) + int(bonus_stats[bonus_key_variant])
			"card_charge_mult", "stamina_cost_mult":
				target[bonus_key] = float(target.get(bonus_key, 1.0)) * float(bonus_stats[bonus_key_variant])
			_:
				target[bonus_key] = float(target.get(bonus_key, 0.0)) + float(bonus_stats[bonus_key_variant])

static func inventory_effect_summary(game: Node, items: Array) -> Dictionary:
	var summary: Dictionary = empty_inventory_effect_summary(game)
	var move_bonus: float = 0.0
	var health_bonus: float = 0.0
	var attack_bonus: float = 0.0
	for item_variant in items:
		var item: Dictionary = item_variant
		if not item_instance_enabled(game, item):
			continue
		var item_def: Dictionary = game.item_defs.get(String(item.get("item_id", "")), {})
		var direct_stats: Dictionary = item_def.get("stats", {})
		apply_inventory_effect_bonuses(summary, direct_stats)
		move_bonus += float(direct_stats.get("speed", 0.0))
		health_bonus += float(direct_stats.get("health", 0.0))
		attack_bonus += float(direct_stats.get("attack", 0.0))
	var cell_to_item: Dictionary = {}
	for item_index in range(items.size()):
		if not item_instance_enabled(game, items[item_index]):
			continue
		for cell in item_occupied_cells(game, items[item_index]):
			cell_to_item[cell] = item_index
	for item_index in range(items.size()):
		var item: Dictionary = items[item_index]
		if not item_instance_enabled(game, item):
			continue
		var item_def: Dictionary = game.item_defs.get(String(item.get("item_id", "")), {})
		var item_uid: int = int(item.get("uid", -1))
		var item_bonus: Dictionary = empty_inventory_effect_summary(game)
		var socket_rules: Array = Array(item_def.get("synergy_sockets", []))
		var item_anchor: Vector2i = item.get("anchor", game.INVALID_ROOM)
		if item_anchor != game.INVALID_ROOM:
			for socket_variant in socket_rules:
				var socket_rule: Dictionary = socket_variant
				var target_cell: Vector2i = item_anchor + rotated_socket_offset(game, item, Vector2i(socket_rule.get("offset", Vector2i.ZERO)))
				var neighbor_index_variant: Variant = cell_to_item.get(target_cell, null)
				if neighbor_index_variant == null or int(neighbor_index_variant) == item_index:
					continue
				var neighbor_item: Dictionary = items[int(neighbor_index_variant)]
				for match_variant in socket_match_entries(game, socket_rule):
					var match_rule: Dictionary = match_variant as Dictionary
					if not item_has_tag(game, neighbor_item, String(match_rule.get("tag", ""))):
						continue
					var socket_bonus: Dictionary = Dictionary(match_rule.get("bonuses", {}))
					apply_inventory_effect_bonuses(summary, socket_bonus)
					apply_inventory_effect_bonuses(item_bonus, socket_bonus)
					summary["synergies"] = int(summary.get("synergies", 0)) + 1
					break
		if item_uid >= 0:
			summary["item_bonus_by_uid"][item_uid] = item_bonus
	for item_variant in items:
		var item_with_card: Dictionary = item_variant
		if not item_instance_enabled(game, item_with_card):
			continue
		var item_def_card: Dictionary = game.item_defs.get(String(item_with_card.get("item_id", "")), {})
		var item_uid_card: int = int(item_with_card.get("uid", -1))
		var card_generators: Array = []
		if item_def_card.has("hand_cards"):
			card_generators = Array(item_def_card.get("hand_cards", [])).duplicate(true)
		else:
			var single_generator: Dictionary = Dictionary(item_def_card.get("hand_card", item_def_card.get("combat_card", {})))
			if not single_generator.is_empty():
				card_generators.append(single_generator)
		for card_generator_variant in card_generators:
			var card_generator: Dictionary = Dictionary(card_generator_variant).duplicate(true)
			card_generator["item_uid"] = item_uid_card
			card_generator["item_id"] = String(item_with_card.get("item_id", ""))
			card_generator["item_bonus"] = Dictionary(summary.get("item_bonus_by_uid", {}).get(item_uid_card, empty_inventory_effect_summary(game))).duplicate(true)
			summary["card_generators"].append(card_generator)
		var combat_passive: Dictionary = Dictionary(item_def_card.get("passive_combat_ability", {}))
		if not combat_passive.is_empty():
			combat_passive["item_uid"] = item_uid_card
			combat_passive["item_id"] = String(item_with_card.get("item_id", ""))
			combat_passive["item_bonus"] = Dictionary(summary.get("item_bonus_by_uid", {}).get(item_uid_card, empty_inventory_effect_summary(game))).duplicate(true)
			summary["combat_passives"].append(combat_passive)
	summary["speed"] = move_bonus + float(summary.get("speed", 0.0)) - move_bonus
	summary["health"] = health_bonus + float(summary.get("health", 0.0)) - health_bonus
	summary["attack"] = attack_bonus + float(summary.get("attack", 0.0)) - attack_bonus
	return summary

static func collect_world_item_uids(game: Node) -> Dictionary:
	var known_item_uids: Dictionary = {}
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		for item_variant in hero.inventory_items:
			known_item_uids[int((item_variant as Dictionary).get("uid", -1))] = true
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		for ground_item_variant in game.rooms[room_coord]["ground_items"]:
			known_item_uids[int((ground_item_variant as Dictionary).get("uid", -1))] = true
	return known_item_uids

static func hero_has_hand_card_for_generator_key(game: Node, generator_key: String) -> bool:
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		for hand_card_variant in hero.hand_cards:
			var hand_card: Dictionary = hand_card_variant
			var hand_key: String = String(hand_card.get("generator_key", game.card_generator_key(int(hand_card.get("item_uid", -1)), String(hand_card.get("card_id", "")))))
			if hand_key == generator_key:
				return true
	return false

static func cleanup_global_item_card_states(game: Node) -> void:
	var known_item_uids: Dictionary = collect_world_item_uids(game)
	var stale_timer_keys: Array = []
	for timer_key_variant in game.global_item_card_states.keys():
		var timer_key: String = String(timer_key_variant)
		var state: Dictionary = Dictionary(game.global_item_card_states.get(timer_key, {}))
		var item_uid: int = int(state.get("item_uid", -1))
		var queued_cards: int = int(state.get("queued_cards", 0))
		if known_item_uids.has(item_uid) or queued_cards > 0 or hero_has_hand_card_for_generator_key(game, timer_key):
			continue
		stale_timer_keys.append(timer_key)
	for stale_key_variant in stale_timer_keys:
		game.global_item_card_states.erase(String(stale_key_variant))

static func mark_orphaned_card_states_for_item(game: Node, item_uid: int) -> void:
	for timer_key_variant in game.global_item_card_states.keys():
		var timer_key: String = String(timer_key_variant)
		var state: Dictionary = Dictionary(game.global_item_card_states.get(timer_key, {})).duplicate(true)
		if int(state.get("item_uid", -1)) != item_uid:
			continue
		state["allow_orphaned_cards"] = true
		game.global_item_card_states[timer_key] = state

static func remove_item_by_uid_from_world(game: Node, item_uid: int) -> void:
	if item_uid < 0:
		return
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		var filtered_items: Array = []
		var removed_any: bool = false
		for item_variant in hero.inventory_items:
			var item: Dictionary = item_variant
			if int(item.get("uid", -1)) == item_uid:
				removed_any = true
				continue
			filtered_items.append(item.duplicate(true))
		if removed_any:
			hero.inventory_items = filtered_items
			game.apply_inventory_stats_to_hero(hero)
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var filtered_ground_items: Array = []
		var removed_ground: bool = false
		for ground_item_variant in game.rooms[room_coord]["ground_items"]:
			var ground_item: Dictionary = ground_item_variant
			if int(ground_item.get("uid", -1)) == item_uid:
				removed_ground = true
				continue
			filtered_ground_items.append(ground_item.duplicate(true))
		if removed_ground:
			game.rooms[room_coord]["ground_items"] = prepare_ground_items_for_room(game, room_coord, filtered_ground_items)

static func consume_item_charges_by_uid(game: Node, item_uid: int, amount: int, orphan_generated_cards_on_break: bool = false) -> bool:
	if item_uid < 0 or amount <= 0:
		return false
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		for item_index in range(hero.inventory_items.size()):
			var item: Dictionary = normalize_item_instance(game, hero.inventory_items[item_index])
			if int(item.get("uid", -1)) != item_uid:
				continue
			if not item.has("charges_left"):
				return false
			item["charges_left"] = int(item.get("charges_left", 0)) - amount
			if int(item.get("charges_left", 0)) <= 0:
				if orphan_generated_cards_on_break:
					mark_orphaned_card_states_for_item(game, item_uid)
				remove_item_by_uid_from_world(game, item_uid)
			else:
				hero.inventory_items[item_index] = item
				game.apply_inventory_stats_to_hero(hero)
			return true
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		for item_index in range(game.rooms[room_coord]["ground_items"].size()):
			var ground_item: Dictionary = normalize_item_instance(game, game.rooms[room_coord]["ground_items"][item_index])
			if int(ground_item.get("uid", -1)) != item_uid:
				continue
			if not ground_item.has("charges_left"):
				return false
			ground_item["charges_left"] = int(ground_item.get("charges_left", 0)) - amount
			if int(ground_item.get("charges_left", 0)) <= 0:
				if orphan_generated_cards_on_break:
					mark_orphaned_card_states_for_item(game, item_uid)
				remove_item_by_uid_from_world(game, item_uid)
			else:
				game.rooms[room_coord]["ground_items"][item_index] = ground_item
			return true
	return false
