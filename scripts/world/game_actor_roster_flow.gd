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
