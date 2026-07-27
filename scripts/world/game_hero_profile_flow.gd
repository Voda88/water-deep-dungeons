extends RefCounted

const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/inventory/game_inventory_item_flow.gd")

static func hero_portrait_texture(game: Node, class_id: String) -> Texture2D:
	if game.hero_portrait_cache.has(class_id):
		return game.hero_portrait_cache[class_id]
	var portrait_path: String = game.HERO_SCRIPT.portrait_path_for_class(class_id)
	var source_texture_resource: Resource = load(portrait_path)
	if not (source_texture_resource is Texture2D):
		return null
	var source_image: Image = source_texture_resource.get_image()
	var portrait: Image = source_image.get_region(Rect2i(0, 0, 100, 100))
	portrait.convert(Image.FORMAT_RGBA8)
	var texture: ImageTexture = ImageTexture.create_from_image(portrait)
	game.hero_portrait_cache[class_id] = texture
	return texture

static func hero_profile_class_id(game: Node, hero_index: int) -> String:
	game.ensure_hero_profiles()
	var class_id: String = String(game.hero_profiles[hero_index].get("class_id", game.default_hero_class_for_slot(hero_index)))
	if game.HERO_CLASS_ORDER.has(class_id):
		return class_id
	return game.default_hero_class_for_slot(hero_index)

static func hero_display_name(game: Node, hero_index: int, class_id: String) -> String:
	var class_def: Dictionary = game.hero_class_definition(class_id)
	return "%s %d" % [String(class_def.get("name", "Hero")), hero_index + 1]

static func set_hero_profile_class(game: Node, hero_index: int, class_id: String, apply_to_spawned_hero: bool = true) -> void:
	game.ensure_hero_profiles()
	if hero_index < 0 or hero_index >= game.hero_profiles.size():
		return
	var resolved_class_id: String = class_id if game.HERO_CLASS_ORDER.has(class_id) else game.default_hero_class_for_slot(hero_index)
	game.hero_profiles[hero_index]["class_id"] = resolved_class_id
	game.hero_profiles[hero_index]["name"] = hero_display_name(game, hero_index, resolved_class_id)
	if not game.hero_class_selection_locked():
		game.hero_profiles[hero_index]["inventory_items"] = GAME_INVENTORY_ITEM_FLOW.default_inventory_items_for_class(game, resolved_class_id)
		game.hero_profiles[hero_index]["learned_spells"] = game.default_learned_spells_for_class(resolved_class_id)
		game.hero_profiles[hero_index]["slotted_spells"] = game.default_slotted_spells_for_class(resolved_class_id)
	if apply_to_spawned_hero and hero_index < game.heroes.size():
		var hero: Variant = game.heroes[hero_index]
		if hero != null and is_instance_valid(hero):
			apply_hero_class_to_node(game, hero, resolved_class_id, game.hero_profiles[hero_index]["name"])
			if not game.hero_class_selection_locked():
				hero.inventory_items = Array(game.hero_profiles[hero_index].get("inventory_items", [])).duplicate(true)
				hero.learned_spells = Array(game.hero_profiles[hero_index].get("learned_spells", [])).duplicate()
				hero.slotted_spells = Array(game.hero_profiles[hero_index].get("slotted_spells", [])).duplicate()
				hero.active_floor_spells = hero.slotted_spells.duplicate()
				game.sanitize_hero_spellbook(hero)
			game.apply_inventory_stats_to_hero(hero)
			hero.restore_health()

static func apply_hero_class_to_node(game: Node, hero: Variant, class_id: String, display_name: String = "") -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var class_def: Dictionary = game.hero_class_definition(class_id)
	var resolved_name: String = display_name if display_name != "" else hero_display_name(game, hero.hero_index, class_id)
	hero.configure_archetype(
		String(class_def.get("id", game.HERO_CLASS_FIGHTER)),
		resolved_name,
		float(class_def.get("move_speed", 340.0)),
		float(class_def.get("max_health", 100.0)),
		float(class_def.get("attack_damage", 20.0)),
		float(class_def.get("attack_range", 150.0)),
		float(class_def.get("attack_cooldown", 0.55)),
		String(class_def.get("attack_style", "laser")),
		float(class_def.get("weight", 1.6)),
		float(class_def.get("melee_windup", 0.2)),
		class_def.get("body_color", Color("7ad7ff")),
		class_def.get("core_color", Color("f7f4d5"))
	)

static func hero_class_summary_lines(game: Node, class_id: String) -> Array[String]:
	var class_def: Dictionary = game.hero_class_definition(class_id)
	return [
		String(class_def.get("title", "Hero")),
		"%s  %d atk  %d hp  %d spd" % ["Melee" if String(class_def.get("attack_style", "laser")) == "melee" else "Ranged", int(round(float(class_def.get("attack_damage", 0.0)))), int(round(float(class_def.get("max_health", 0.0)))), int(round(float(class_def.get("move_speed", 0.0))))],
		"Range %d  Cooldown %.2fs  Weight %.1f" % [int(round(float(class_def.get("attack_range", 0.0)))), float(class_def.get("attack_cooldown", 0.0)), float(class_def.get("weight", 1.0))],
	]

static func ensure_hero_profiles(game: Node) -> void:
	if game.hero_profiles.size() >= game.HERO_COUNT:
		for hero_index in range(game.hero_profiles.size()):
			if not game.hero_profiles[hero_index].has("class_id"):
				game.hero_profiles[hero_index]["class_id"] = game.default_hero_class_for_slot(hero_index)
			if not game.hero_profiles[hero_index].has("dead"):
				game.hero_profiles[hero_index]["dead"] = false
			game.hero_profiles[hero_index]["name"] = hero_display_name(game, hero_index, String(game.hero_profiles[hero_index].get("class_id", game.default_hero_class_for_slot(hero_index))))
			if not game.hero_profiles[hero_index].has("learned_spells"):
				game.hero_profiles[hero_index]["learned_spells"] = game.default_learned_spells_for_class(String(game.hero_profiles[hero_index]["class_id"]))
			if not game.hero_profiles[hero_index].has("slotted_spells"):
				game.hero_profiles[hero_index]["slotted_spells"] = game.default_slotted_spells_for_class(String(game.hero_profiles[hero_index]["class_id"]))
		return
	for hero_index in range(game.hero_profiles.size(), game.HERO_COUNT):
		var class_id: String = game.default_hero_class_for_slot(hero_index)
		game.hero_profiles.append({
			"class_id": class_id,
			"name": hero_display_name(game, hero_index, class_id),
			"level": 1,
			"dead": false,
			"pack_modules": [],
			"inventory_items": GAME_INVENTORY_ITEM_FLOW.default_inventory_items_for_class(game, class_id),
			"learned_spells": game.default_learned_spells_for_class(class_id),
			"slotted_spells": game.default_slotted_spells_for_class(class_id),
		})

static func hero_supports_spell_repertoire(game: Node, hero: Variant) -> bool:
	return hero != null and is_instance_valid(hero) and game.spell_focus_item_id_for_class(String(hero.hero_class_id)) != ""

static func hero_has_spell_focus_item(game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	var focus_item_id: String = game.spell_focus_item_id_for_class(String(hero.hero_class_id))
	if focus_item_id == "":
		return false
	for item_variant in hero.inventory_items:
		if String((item_variant as Dictionary).get("item_id", "")) == focus_item_id:
			return true
	return false

static func spell_focus_item_uid_for_hero(game: Node, hero: Variant) -> int:
	if hero == null or not is_instance_valid(hero):
		return -1
	var focus_item_id: String = game.spell_focus_item_id_for_class(String(hero.hero_class_id))
	if focus_item_id == "":
		return -1
	for item_variant in hero.inventory_items:
		var item: Dictionary = item_variant
		if String(item.get("item_id", "")) == focus_item_id:
			return int(item.get("uid", -1))
	return -1

static func hero_can_prepare_spell(game: Node, hero: Variant, spell_id: String) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if spell_id == "" or game.spell_class_id(spell_id) != String(hero.hero_class_id):
		return false
	var required_level: int = game.spell_level(spell_id)
	if required_level <= 0:
		return false
	return required_level <= game.hero_max_spell_level_for_class_level(String(hero.hero_class_id), int(hero.level))

static func hero_spell_repertoire_editable(game: Node, hero: Variant) -> bool:
	return hero != null and is_instance_valid(hero) and hero_supports_spell_repertoire(game, hero)

static func prepared_spell_max_copies(game: Node, hero: Variant, spell_id: String, slot_counts: Array[int] = []) -> int:
	if hero == null or not is_instance_valid(hero) or spell_id == "":
		return 0
	var card_def: Dictionary = game.card_definition(spell_id)
	var explicit_limit: int = int(card_def.get("max_prepared_copies", 0))
	if explicit_limit > 0:
		return explicit_limit
	if bool(card_def.get("reusable", false)):
		return 1
	var resolved_slot_counts: Array[int] = slot_counts if not slot_counts.is_empty() else game.spell_slot_counts_for_class_level(String(hero.hero_class_id), int(hero.level))
	var level_index: int = game.spell_level(spell_id) - 1
	if level_index < 0 or level_index >= resolved_slot_counts.size():
		return 0
	return int(resolved_slot_counts[level_index])

static func default_prepared_spell_list(game: Node, hero: Variant, slot_counts: Array[int]) -> Array[String]:
	var prepared: Array[String] = []
	if hero == null or not is_instance_valid(hero):
		return prepared
	var copy_counts: Dictionary = {}
	for level_index in range(slot_counts.size()):
		var slots_remaining: int = int(slot_counts[level_index])
		if slots_remaining <= 0:
			continue
		var level_spells: Array[String] = []
		for learned_spell_variant in hero.learned_spells:
			var learned_spell_id: String = String(learned_spell_variant)
			if game.spell_level(learned_spell_id) == level_index + 1 and hero_can_prepare_spell(game, hero, learned_spell_id):
				level_spells.append(learned_spell_id)
		if level_spells.is_empty():
			continue
		var made_progress: bool = true
		while slots_remaining > 0 and made_progress:
			made_progress = false
			for level_spell_id in level_spells:
				var used_copies: int = int(copy_counts.get(level_spell_id, 0))
				if used_copies >= prepared_spell_max_copies(game, hero, level_spell_id, slot_counts):
					continue
				copy_counts[level_spell_id] = used_copies + 1
				prepared.append(level_spell_id)
				slots_remaining -= 1
				made_progress = true
				if slots_remaining <= 0:
					break
	return prepared

static func cleaned_prepared_spell_list(game: Node, hero: Variant, source_spells: Array) -> Array[String]:
	var cleaned_slots: Array[String] = []
	if hero == null or not is_instance_valid(hero):
		return cleaned_slots
	var slot_counts: Array[int] = game.spell_slot_counts_for_class_level(String(hero.hero_class_id), int(hero.level))
	var used_slots_by_level: Array[int] = []
	used_slots_by_level.resize(slot_counts.size())
	for slot_index in range(used_slots_by_level.size()):
		used_slots_by_level[slot_index] = 0
	var used_spell_copies: Dictionary = {}
	for spell_variant in source_spells:
		var spell_id: String = String(spell_variant)
		if spell_id == "" or not hero.learned_spells.has(spell_id) or not hero_can_prepare_spell(game, hero, spell_id):
			continue
		var level_index: int = game.spell_level(spell_id) - 1
		if level_index < 0 or level_index >= slot_counts.size() or used_slots_by_level[level_index] >= slot_counts[level_index]:
			continue
		var used_copies: int = int(used_spell_copies.get(spell_id, 0))
		if used_copies >= prepared_spell_max_copies(game, hero, spell_id, slot_counts):
			continue
		cleaned_slots.append(spell_id)
		used_slots_by_level[level_index] += 1
		used_spell_copies[spell_id] = used_copies + 1
	if cleaned_slots.is_empty() and not hero.learned_spells.is_empty():
		cleaned_slots = default_prepared_spell_list(game, hero, slot_counts)
	return cleaned_slots

static func refresh_active_floor_spells(game: Node, hero: Variant, force_saved_repertoire: bool = false) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if force_saved_repertoire or hero.active_floor_spells.is_empty() or game.doors_opened == 0:
		hero.active_floor_spells = cleaned_prepared_spell_list(game, hero, hero.slotted_spells)
	else:
		hero.active_floor_spells = cleaned_prepared_spell_list(game, hero, hero.active_floor_spells)

static func sanitize_hero_spellbook(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if not hero_supports_spell_repertoire(game, hero) or not hero_has_spell_focus_item(game, hero):
		hero.learned_spells.clear()
		hero.slotted_spells.clear()
		hero.active_floor_spells.clear()
		hero.studying_spell_id = ""
		hero.studying_room = game.INVALID_ROOM
		hero.studying_started_at_door = -1
		return
	var known_map: Dictionary = {}
	var cleaned_known: Array[String] = []
	for spell_variant in hero.learned_spells:
		var spell_id: String = String(spell_variant)
		if spell_id == "" or known_map.has(spell_id) or game.spell_class_id(spell_id) != String(hero.hero_class_id):
			continue
		known_map[spell_id] = true
		cleaned_known.append(spell_id)
	if cleaned_known.is_empty():
		cleaned_known = game.default_learned_spells_for_class(hero.hero_class_id).duplicate()
	hero.learned_spells = cleaned_known
	hero.slotted_spells = cleaned_prepared_spell_list(game, hero, hero.slotted_spells)
	refresh_active_floor_spells(game, hero)

static func save_hero_profiles_from_nodes(game: Node) -> void:
	game.ensure_hero_profiles()
	for hero in game.heroes:
		if not is_instance_valid(hero):
			continue
		game.hero_profiles[hero.hero_index]["class_id"] = hero.hero_class_id
		game.hero_profiles[hero.hero_index]["name"] = hero.hero_name
		game.hero_profiles[hero.hero_index]["level"] = hero.level
		game.hero_profiles[hero.hero_index]["dead"] = bool(hero.has_method("is_dead_state") and hero.is_dead_state())
		game.hero_profiles[hero.hero_index]["pack_modules"] = hero.pack_modules.duplicate(true)
		game.hero_profiles[hero.hero_index]["inventory_items"] = hero.inventory_items.duplicate(true)
		game.hero_profiles[hero.hero_index]["learned_spells"] = hero.learned_spells.duplicate()
		game.hero_profiles[hero.hero_index]["slotted_spells"] = hero.slotted_spells.duplicate()
