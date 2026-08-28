extends RefCounted

static func clear_floor_actors(game: Node) -> void:
	game.pending_room_loot_requests.clear()
	game.pending_room_action_requests.clear()
	game.pending_room_constructions.clear()
	game.pending_melee_attacks.clear()
	game.floating_resource_texts.clear()
	for hero in game.heroes:
		if is_instance_valid(hero):
			hero.queue_free()
	game.heroes.clear()
	for enemy in game.enemies:
		if is_instance_valid(enemy):
			game.release_enemy_to_pool(enemy)
	game.enemies.clear()
	game.module_actors.clear()

static func reconcile_module_actors(game: Node) -> void:
	var reconciled_actors: Dictionary = {}
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		var major_type: String = String(room.get("major_module_type", ""))
		if major_type != "":
			var major_key: String = "module:major:%d:%d:-1" % [room_coord.x, room_coord.y]
			var major_actor: Variant = game.module_actors.get(major_key, game.MODULE_ACTOR_SCRIPT.new())
			major_actor.configure(game, room_coord, -1, true, major_type)
			reconciled_actors[major_key] = major_actor
		for module_data_variant in Array(room.get("minor_modules", [])):
			var module_data: Dictionary = Dictionary(module_data_variant)
			var slot_index: int = int(module_data.get("slot_index", -1))
			if slot_index < 0:
				continue
			var module_type: String = String(module_data.get("type", ""))
			if module_type == "":
				continue
			var minor_key: String = "module:minor:%d:%d:%d" % [room_coord.x, room_coord.y, slot_index]
			var minor_actor: Variant = game.module_actors.get(minor_key, game.MODULE_ACTOR_SCRIPT.new())
			minor_actor.configure(game, room_coord, slot_index, false, module_type)
			reconciled_actors[minor_key] = minor_actor
	game.module_actors = reconciled_actors

static func active_module_actors_in_room(game: Node, room_coord: Vector2i) -> Array:
	reconcile_module_actors(game)
	var active_modules: Array = []
	for module_actor_variant in game.module_actors.values():
		var module_actor: Variant = module_actor_variant
		if module_actor != null and module_actor.current_room == room_coord and module_actor.is_active():
			active_modules.append(module_actor)
	return active_modules

static func spawn_heroes(game: Node) -> void:
	game.ensure_hero_profiles()
	for hero_index in range(game.HERO_COUNT):
		var hero: Variant = game.HERO_SCENE.instantiate()
		game.actor_layer.add_child(hero)
		hero.hero_index = hero_index
		var hero_class_id: String = game.hero_profile_class_id(hero_index)
		game.apply_hero_class_to_node(hero, hero_class_id, String(game.hero_profiles[hero_index].get("name", game.hero_display_name(hero_index, hero_class_id))))
		hero.level = int(game.hero_profiles[hero_index].get("level", 1))
		hero.selected = hero_index == game.selected_hero_index
		hero.inventory_canvas_size = game.INVENTORY_CANVAS_SIZE
		hero.base_inventory_origin = game.INVENTORY_BASE_ORIGIN
		hero.base_inventory_size = game.INVENTORY_BASE_SIZE
		hero.pack_modules = Array(game.hero_profiles[hero_index].get("pack_modules", [])).duplicate(true)
		hero.inventory_items = Array(game.hero_profiles[hero_index].get("inventory_items", [])).duplicate(true)
		hero.learned_spells = Array(game.hero_profiles[hero_index].get("learned_spells", game.default_learned_spells_for_class(hero_class_id))).duplicate()
		hero.slotted_spells = Array(game.hero_profiles[hero_index].get("slotted_spells", game.default_slotted_spells_for_class(hero_class_id))).duplicate()
		hero.active_floor_spells = hero.slotted_spells.duplicate()
		game.sanitize_hero_spellbook(hero)
		hero.set_calm_movement_multiplier(game.selected_calm_speed_multiplier())
		hero.set_room(game.crystal_room, game.hero_idle_position(game.crystal_room, hero_index, game.HERO_COUNT))
		game.apply_inventory_stats_to_hero(hero)
		if bool(game.hero_profiles[hero_index].get("dead", false)):
			hero.set_permanently_dead_hidden()
		else:
			hero.restore_health()
		if not hero.fighter_rage_filled.is_connected(game._on_hero_fighter_rage_filled.bind(hero)):
			hero.fighter_rage_filled.connect(game._on_hero_fighter_rage_filled.bind(hero))
		game.heroes.append(hero)
	if game.selected_hero_index >= game.heroes.size():
		game.selected_hero_index = 0
	game.ensure_valid_selected_hero()
	game.rebuild_hero_bar()
	game.update_selected_hero_flags()
