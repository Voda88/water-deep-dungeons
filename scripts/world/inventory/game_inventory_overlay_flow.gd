extends RefCounted

const GAME_DUNGEON_BUILDER: GDScript = preload("res://scripts/world/rooms/game_dungeon_builder.gd")

static func refresh_open_inventory_overlay(game: Node) -> void:
	if game.inventory_overlay == null or not game.inventory_overlay.visible or game.inventory_session.is_empty():
		return
	var hero_index: int = int(game.inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	game.inventory_overlay.refresh_state(
		game.build_inventory_stat_lines(hero, hero.inventory_items),
		game.build_inventory_ability_sections(hero),
		game.build_level_up_reward_lines(hero),
		game.food,
		game.level_up_food_cost(hero.level),
		game.hero_can_level_up(hero),
		hero.level,
		hero.pack_modules,
		game.hero_spellbook_overlay_data(hero)
	)

static func open_room_loot_inventory(game: Node, hero: Variant, room_coord: Vector2i) -> void:
	if hero == null or not is_instance_valid(hero) or not game.rooms.has(room_coord):
		return
	game.clear_pending_room_loot_request(hero.hero_index)
	open_hero_inventory(game, hero, room_coord)

static func open_hero_inventory(game: Node, hero: Variant, room_coord: Vector2i = Vector2i(-99, -99)) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	game.build_menu_open = false
	game.clear_build_mode()
	game.crystal_prompt_visible = false
	game.room_action_menu.clear()
	var ground_items: Array = []
	var loot_enabled: bool = game.rooms.has(room_coord)
	if loot_enabled:
		for ground_item_variant in game.rooms[room_coord]["ground_items"]:
			ground_items.append((ground_item_variant as Dictionary).duplicate(true))
	game.inventory_session = {
		"hero_index": hero.hero_index,
		"room": room_coord,
	}
	game.inventory_overlay.configure(
		hero.hero_name,
		hero.level,
		game.food,
		game.level_up_food_cost(hero.level),
		game.hero_can_level_up(hero),
		game.build_inventory_stat_lines(hero, hero.inventory_items),
		game.build_inventory_ability_sections(hero),
		game.build_level_up_reward_lines(hero),
		hero.inventory_canvas_size,
		hero.base_inventory_origin,
		hero.base_inventory_size,
		hero.pack_modules,
		game.item_defs,
		hero.inventory_items,
		ground_items,
		loot_enabled,
		game.hero_spellbook_overlay_data(hero)
	)
	game.status_message = "Inventory open for %s." % hero.hero_name
	game.mouse_pressed = false
	game.mouse_dragging = false
	game.touch_points.clear()
	game.active_touch_id = -1
	game.room_action_hold.clear()
	game.update_hud()

static func clear_inventory_session(game: Node, _commit_pending_item: bool) -> void:
	if game.inventory_session.is_empty():
		if game.inventory_overlay != null:
			game.inventory_overlay.hide_overlay()
		return
	var hero_index: int = int(game.inventory_session.get("hero_index", -1))
	var room_coord: Vector2i = game.inventory_session.get("room", game.INVALID_ROOM)
	if game.inventory_overlay != null:
		var commit_items: Array = game.inventory_overlay.get_inventory_items()
		var commit_ground_items: Array = game.inventory_overlay.get_ground_items()
		commit_inventory_state(game, hero_index, room_coord, commit_items, commit_ground_items)
		if game.multiplayer_session_active() and not game.authoritative_simulation_active():
			game.server_commit_inventory_state.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord, commit_items, commit_ground_items)
	if game.inventory_overlay != null:
		game.inventory_overlay.hide_overlay()
	game.inventory_session.clear()
	if game.multiplayer_session_active() and game.multiplayer.is_server():
		game.broadcast_network_snapshot()
	game.queue_redraw()

static func commit_inventory_state(game: Node, hero_index: int, room_coord: Vector2i, items: Array, ground_items: Array) -> void:
	if game.rooms.has(room_coord):
		game.rooms[room_coord]["ground_items"] = game.prepare_ground_items_for_room(room_coord, ground_items)
	if hero_index >= 0 and hero_index < game.heroes.size():
		var hero: Variant = game.heroes[hero_index]
		if is_instance_valid(hero):
			hero.inventory_items = items.duplicate(true)
			game.apply_inventory_stats_to_hero(hero)

static func commit_pack_layout(game: Node, hero_index: int, pack_modules: Array) -> void:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	hero.pack_modules = pack_modules.duplicate(true)
	game.apply_inventory_stats_to_hero(hero)

static func reset_hero_spellbook_generated_cards(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var filtered_hand: Array = []
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
		var generator_key: String = String(hand_card.get("generator_key", ""))
		if generator_key.begins_with("spellbook:%d:" % hero.hero_index):
			continue
		filtered_hand.append(hand_card)
	hero.hand_cards = filtered_hand
	var stale_keys: Array = []
	for state_key_variant in game.global_item_card_states.keys():
		var state_key: String = String(state_key_variant)
		if state_key.begins_with("spellbook:%d:" % hero.hero_index):
			stale_keys.append(state_key)
	for stale_key_variant in stale_keys:
		game.global_item_card_states.erase(String(stale_key_variant))

static func commit_spell_slots(game: Node, hero_index: int, slotted_spells: Array) -> void:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	hero.slotted_spells = Array(slotted_spells).duplicate()
	game.sanitize_hero_spellbook(hero)
	if game.doors_opened == 0:
		reset_hero_spellbook_generated_cards(game, hero)
		game.refresh_active_floor_spells(hero, true)
	else:
		apply_midfloor_spell_slot_additions_on_cooldown(game, hero)
	game.apply_inventory_stats_to_hero(hero)

static func spell_count_map(spells: Array) -> Dictionary:
	var counts: Dictionary = {}
	for spell_variant in spells:
		var spell_id: String = String(spell_variant)
		if spell_id == "":
			continue
		counts[spell_id] = int(counts.get(spell_id, 0)) + 1
	return counts

static func spellbook_generator_key(hero_index: int, spell_index: int, spell_id: String) -> String:
	return "spellbook:%d:%d:%s" % [hero_index, spell_index, spell_id]

static func build_spellbook_generator_key_counts(hero: Variant, source_spells: Array) -> Dictionary:
	var key_counts: Dictionary = {}
	for spell_index in range(source_spells.size()):
		var spell_id: String = String(source_spells[spell_index])
		if spell_id == "":
			continue
		var key: String = spellbook_generator_key(int(hero.hero_index), spell_index, spell_id)
		key_counts[key] = int(key_counts.get(key, 0)) + 1
	return key_counts

static func added_spell_copies(previous_spells: Array, slotted_spells: Array) -> Array[String]:
	var additions: Array[String] = []
	var previous_counts: Dictionary = spell_count_map(previous_spells)
	var slotted_counts: Dictionary = spell_count_map(slotted_spells)
	for spell_id_variant in slotted_counts.keys():
		var spell_id: String = String(spell_id_variant)
		var additional_copies: int = int(slotted_counts.get(spell_id, 0)) - int(previous_counts.get(spell_id, 0))
		for copy_index in range(maxi(additional_copies, 0)):
			additions.append(spell_id)
	return additions

static func apply_midfloor_spell_slot_additions_on_cooldown(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero) or not game.hero_supports_spell_repertoire(hero):
		return
	var previous_active_spells: Array = Array(hero.active_floor_spells).duplicate()
	var new_spells: Array[String] = added_spell_copies(previous_active_spells, Array(hero.slotted_spells))
	if new_spells.is_empty():
		return
	for spell_id in new_spells:
		hero.active_floor_spells.append(spell_id)
	var previous_key_counts: Dictionary = build_spellbook_generator_key_counts(hero, previous_active_spells)
	var current_key_counts: Dictionary = build_spellbook_generator_key_counts(hero, Array(hero.active_floor_spells))
	var added_generator_keys: Array[String] = []
	for key_variant in current_key_counts.keys():
		var key: String = String(key_variant)
		var delta: int = int(current_key_counts.get(key, 0)) - int(previous_key_counts.get(key, 0))
		for count_index in range(maxi(delta, 0)):
			added_generator_keys.append(key)
	if added_generator_keys.is_empty():
		return
	var effect_summary: Dictionary = game.inventory_effect_summary(hero.inventory_items)
	game.sync_hero_card_sources(hero, effect_summary)
	var filtered_hand: Array = []
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
		var generator_key: String = String(hand_card.get("generator_key", ""))
		if added_generator_keys.has(generator_key):
			continue
		filtered_hand.append(hand_card)
	hero.hand_cards = filtered_hand
	for generator_key_variant in added_generator_keys:
		var added_key: String = String(generator_key_variant)
		if not game.global_item_card_states.has(added_key):
			continue
		var state: Dictionary = Dictionary(game.global_item_card_states.get(added_key, {})).duplicate(true)
		var interval: int = maxi(1, int(state.get("interval", 1)))
		state["queued_cards"] = 0
		state["remaining_doors"] = interval
		game.global_item_card_states[added_key] = state
	game.fill_queued_hand_cards(hero, effect_summary)
	game.cleanup_global_item_card_states()

static func _on_inventory_overlay_changed(game: Node, items: Array) -> void:
	if game.inventory_session.is_empty():
		return
	var hero_index: int = int(game.inventory_session.get("hero_index", -1))
	var room_coord: Vector2i = game.inventory_session.get("room", game.INVALID_ROOM)
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if game.rooms.has(room_coord) and game.inventory_overlay != null:
		game.rooms[room_coord]["ground_items"] = game.prepare_ground_items_for_room(room_coord, game.inventory_overlay.get_ground_items())
	hero.inventory_items = items.duplicate(true)
	game.apply_inventory_stats_to_hero(hero)
	if game.multiplayer_session_active() and not game.authoritative_simulation_active() and game.inventory_overlay != null:
		game.server_commit_inventory_state.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord, items, game.inventory_overlay.get_ground_items())
	refresh_open_inventory_overlay(game)
	game.update_hud()

static func _on_inventory_close_requested(game: Node) -> void:
	clear_inventory_session(game, true)
	game.status_message = "Inventory closed."
	game.update_hud()

static func _on_inventory_pack_layout_changed(game: Node, pack_modules: Array) -> void:
	if game.inventory_session.is_empty():
		return
	var hero_index: int = int(game.inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	commit_pack_layout(game, hero_index, pack_modules)
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_commit_pack_layout.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, pack_modules)
	refresh_open_inventory_overlay(game)
	game.update_hud()

static func _on_inventory_level_up_requested(game: Node) -> void:
	if game.inventory_session.is_empty():
		return
	var hero_index: int = int(game.inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_request_inventory_level_up.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index)
		game.status_message = "Level-up requested for %s." % hero.hero_name
		game.update_hud()
		return
	if game.grant_level_up_pack_to_hero(hero):
		game.status_message = "%s reached level %d." % [hero.hero_name, hero.level]
	else:
		game.status_message = "Not enough food or no room for another pack."
	game.apply_inventory_stats_to_hero(hero)
	refresh_open_inventory_overlay(game)
	game.update_hud()

static func _on_inventory_spellbook_slots_changed(game: Node, slotted_spells: Array) -> void:
	if game.inventory_session.is_empty():
		return
	var hero_index: int = int(game.inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	commit_spell_slots(game, hero_index, slotted_spells)
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_commit_spell_slots.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, slotted_spells)
	refresh_open_inventory_overlay(game)
	game.update_hud()

static func _on_inventory_item_dropped(game: Node, item: Dictionary) -> void:
	if game.inventory_session.is_empty():
		return
	var hero_index: int = int(game.inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not game.rooms.has(hero.current_room):
		return
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_request_inventory_drop.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, item)
		game.status_message = "%s dropped %s." % [hero.hero_name, String(game.item_defs.get(String(item.get("item_id", "")), {}).get("name", "an item"))]
		game.update_hud()
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
	game.queue_redraw()
