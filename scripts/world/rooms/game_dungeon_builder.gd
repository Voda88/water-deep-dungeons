extends RefCounted

const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/inventory/game_inventory_item_flow.gd")

const SPECIAL_ROOM_WEIGHT_BASE: float = 1.0
const RESEARCH_MAJOR_SLOT_WEIGHT_BONUS: float = 1.7
const RESEARCH_DISTANCE_WEIGHT_STEP: float = 0.18
const RESEARCH_EXIT_WEIGHT_MULTIPLIER: float = 0.72
const MERCHANT_UNOPENED_WEIGHT_BONUS: float = 0.25
const MERCHANT_DISTANCE_WEIGHT_STEP: float = 0.12
const MERCHANT_EXIT_WEIGHT_MULTIPLIER: float = 0.82
const LOOT_DISTANCE_WEIGHT_STEP: float = 0.1
const LOOT_EXIT_WEIGHT_MULTIPLIER: float = 0.9
const SPAWN_DISTANCE_WEIGHT_STEP: float = 0.22
const SPAWN_EXIT_WEIGHT_MULTIPLIER: float = 1.15
const BONUS_RESOURCE_DISTANCE_WEIGHT_STEP: float = 0.14
const BONUS_RESOURCE_EXIT_WEIGHT_MULTIPLIER: float = 0.86
const PERMANENT_LIGHT_DISTANCE_WEIGHT_STEP: float = 0.16
const PERMANENT_LIGHT_EXIT_WEIGHT_MULTIPLIER: float = 0.84
const SPECIAL_FEATURE_RESEARCH: String = "research"
const SPECIAL_FEATURE_MERCHANT: String = "merchant"
const SPECIAL_FEATURE_LOOT: String = "loot"
const SPECIAL_FEATURE_SPAWN: String = "spawn"
const SPECIAL_FEATURE_BONUS_RESOURCE: String = "bonus_resource"
const SPECIAL_FEATURE_PERMANENT_LIGHT: String = "permanent_light"

static func is_in_bounds(game: Node, room_coord: Vector2i) -> bool:
	return room_coord.x >= 0 and room_coord.y >= 0 and room_coord.x < game.GRID_SIZE.x and room_coord.y < game.GRID_SIZE.y
static func random_room_offset(game: Node, radius: float) -> Vector2:
	return Vector2(
		game.rng.randf_range(-radius, radius),
		game.rng.randf_range(-radius * 0.55, radius * 0.55)
	)

static func build_dungeon(game: Node, reset_resources: bool = true) -> void:
	if reset_resources:
		game.hero_profiles.clear()
	else:
		game.save_hero_profiles_from_nodes()
	game.clear_inventory_session(false)
	game.close_merchant_overlay()
	game.clear_floor_actors()
	game.rooms.clear()
	game.room_nav_cache.clear()
	game.projectiles.clear()
	game.floating_resource_texts.clear()
	game.pending_enemy_spawns.clear()
	game.pending_room_constructions.clear()
	game.next_enemy_uid = 1
	game.next_card_uid = 1
	game.global_item_card_states.clear()
	game.global_item_passive_timers.clear()
	game.active_hand_drag.clear()
	game.hand_card_return_animations.clear()
	game.pending_melee_attacks.clear()
	game.active_research.clear()
	game.build_menu_open = false
	game.pending_build_type = ""
	game.opened_rooms = 1
	game.doors_opened = 0
	game.wave_index = 0
	game.floor_major_modules_built_count = 0
	game.exit_room = game.INVALID_ROOM
	game.crystal_holder = null
	game.crystal_ground_room = game.crystal_room
	game.crystal_prompt_visible = false
	game.crystal_pressure_timer_left = 0.0
	game.door_wave_auto_heal_pending = false
	game.door_wave_healing_active = false
	game.door_wave_major_payout_pending = false
	game.opening_room = game.INVALID_ROOM
	game.opening_origin_room = game.INVALID_ROOM
	game.opening_hero = null
	game.opening_timer_left = 0.0
	game.opening_heroes.clear()
	game.room_action_hold.clear()
	game.room_action_menu.clear()
	if reset_resources:
		game.floor_index = 1
		game.dust = 24
		game.crystal_dust_damage_fraction = 0.0
		game.food = 10
		game.industry = 18
		game.science = 10
		game.research_reroll_count = 0
		game.rejoin_claimable_hero_indices.clear()
		game.minor_module_levels = game.normalized_minor_module_levels(game.initialized_minor_module_levels())
		game.major_module_levels = game.normalized_major_module_levels(game.initialized_major_module_levels())
	elif game.minor_module_levels.is_empty():
		game.minor_module_levels = game.normalized_minor_module_levels(game.initialized_minor_module_levels())
	elif game.major_module_levels.is_empty():
		game.major_module_levels = game.normalized_major_module_levels(game.initialized_major_module_levels())
	game.minor_module_levels = game.normalized_minor_module_levels(game.minor_module_levels)
	game.major_module_levels = game.normalized_major_module_levels(game.major_module_levels)
	var minimum_room_count: int = 9 if game.floor_index == 1 else 10
	var target_room_count: int = 13 if game.floor_index == 1 else 15
	var layout_generation_attempts: int = 0
	while layout_generation_attempts < 12:
		layout_generation_attempts += 1
		game.rooms.clear()
		game.room_nav_cache.clear()
		var crystal_door_dirs: Array = game.crystal_room_door_dirs_for_floor()
		game.create_room(game.crystal_room, game.ROOM_TEMPLATE_FORGE, crystal_door_dirs, Vector2.ZERO)
		var crystal: Dictionary = game.rooms[game.crystal_room]
		crystal["opened"] = true
		crystal["lit"] = true
		crystal["permanent_light"] = true
		crystal["permanent_light_seeded"] = true
		crystal["temporary_light_turns"] = 0
		crystal["wave_torch_until_wave"] = -1
		crystal["crystal"] = true
		crystal["minor_slots"] = 0
		crystal["major_slots"] = 0
		crystal["major_under_construction"] = false
		var layout_attempts: int = 0
		while game.rooms.size() < target_room_count and layout_attempts < 800:
			layout_attempts += 1
			var frontier_sockets: Array = game.collect_frontier_sockets()
			if frontier_sockets.is_empty():
				break
			var socket: Dictionary = frontier_sockets[game.rng.randi_range(0, frontier_sockets.size() - 1)]
			var origin: Vector2i = socket["room"]
			var direction: Vector2i = socket["direction"]
			var room_coord: Vector2i = origin + direction
			var generating_second_room: bool = game.rooms.size() == 1
			var prefer_dead_end: bool = game.rooms.size() >= 4 and frontier_sockets.size() >= 3 and game.rng.randf() < 0.58
			var minimum_doors: int = 2 if generating_second_room else 1
			var blueprint: Dictionary = game.roll_room_blueprint(-direction, generating_second_room, prefer_dead_end, minimum_doors)
			if blueprint.is_empty():
				continue
			var template_id: String = String(blueprint["template_id"])
			var candidate_center: Vector2 = game.proposed_room_center(origin, template_id, direction)
			if not game.can_place_room_center(candidate_center, game.room_template_size(template_id)):
				continue
			game.create_room(room_coord, template_id, blueprint["door_dirs"], candidate_center)
			game.connect_rooms(origin, room_coord)
		if game.rooms.size() >= minimum_room_count:
			break
	game.reconcile_room_connections()
	game.finalize_room_slot_distribution()
	assign_exit_room(game)
	assign_special_room_features(game)
	game.prepare_floor_enemy_spawn_types()
	game.prewarm_enemy_pool_for_floor()
	spawn_starting_room_test_items(game)
	game.normalize_runtime_rooms_slot_capacity()
	game.refresh_room_lighting_states()
	game.refresh_camera_bounds()
	game.invalidate_static_dungeon_layer()

static func spawn_starting_room_test_items(game: Node) -> void:
	if not game.rooms.has(game.crystal_room):
		return
	var item_ids: Array[String] = []
	for item_id_variant in game.item_defs.keys():
		var item_id: String = String(item_id_variant)
		item_ids.append(item_id)
	if item_ids.is_empty():
		return
	item_ids.sort()
	var room_coord: Vector2i = game.crystal_room
	var room_data: Dictionary = Dictionary(game.rooms[room_coord]).duplicate(true)
	var center_position: Vector2 = game.room_walkable_center(room_coord)
	var items_per_ring: int = 12
	var base_radius: float = 40.0
	var ring_spacing: float = 44.0
	for item_index in range(item_ids.size()):
		var ring_index: int = item_index / items_per_ring
		var in_ring_index: int = item_index % items_per_ring
		var ring_start: int = ring_index * items_per_ring
		var ring_count: int = mini(items_per_ring, item_ids.size() - ring_start)
		var angle: float = TAU * float(in_ring_index) / float(maxi(ring_count, 1))
		var radius: float = base_radius + float(ring_index) * ring_spacing
		var drop_position: Vector2 = game.clamp_point_to_room(center_position + Vector2(cos(angle), sin(angle)) * radius, room_coord)
		room_data["ground_items"].append(game.make_ground_item(item_ids[item_index], drop_position))
	game.rooms[room_coord] = room_data

static func roll_room_template(game: Node) -> String:
	var roll: float = game.rng.randf()
	if roll < 0.28:
		return game.ROOM_TEMPLATE_NOOK
	if roll < 0.52:
		return game.ROOM_TEMPLATE_GALLERY
	if roll < 0.8:
		return game.ROOM_TEMPLATE_WORKSHOP
	return game.ROOM_TEMPLATE_FORGE

static func crystal_room_door_dirs_for_floor(game: Node) -> Array:
	if game.floor_index == 1:
		return [game.CARDINAL_DIRS[game.rng.randi_range(0, game.CARDINAL_DIRS.size() - 1)]]
	return game.random_template_doors(game.ROOM_TEMPLATE_FORGE)

static func door_dirs_suffix(game: Node, door_dirs: Array) -> String:
	var suffix: String = ""
	var ordered_dirs: Array[Dictionary] = [
		{"dir": Vector2i.LEFT, "key": "l"},
		{"dir": Vector2i.RIGHT, "key": "r"},
		{"dir": Vector2i.UP, "key": "u"},
		{"dir": Vector2i.DOWN, "key": "d"},
	]
	for entry in ordered_dirs:
		var direction: Vector2i = entry["dir"]
		if door_dirs.has(direction):
			suffix += String(entry["key"])
	return suffix

static func cardinal_dir_key(_game: Node, direction: Vector2i) -> String:
	match direction:
		Vector2i.LEFT:
			return "left"
		Vector2i.RIGHT:
			return "right"
		Vector2i.UP:
			return "up"
		Vector2i.DOWN:
			return "down"
		_:
			return ""

static func room_template_base_scene_path(game: Node, template_id: String, crystal_chamber: bool = false) -> String:
	if crystal_chamber:
		if game.floor_index == 1:
			return game.FLOOR1_CRYSTAL_ROOM_SCENE.resource_path
		return game.CRYSTAL_ROOM_SCENE.resource_path
	var base_scene: PackedScene = game.ROOM_TEMPLATE_SCENES.get(template_id, game.ROOM_TEMPLATE_SCENES[game.ROOM_TEMPLATE_NOOK])
	return base_scene.resource_path

static func room_template_scene_path(game: Node, template_id: String, _door_dirs: Array = [], crystal_chamber: bool = false) -> String:
	return game.room_template_base_scene_path(template_id, crystal_chamber)

static func room_template_scene(game: Node, template_id: String, door_dirs: Array = [], crystal_chamber: bool = false) -> PackedScene:
	var scene_path: String = game.room_template_scene_path(template_id, door_dirs, crystal_chamber)
	var scene_resource: Resource = load(scene_path)
	if scene_resource is PackedScene:
		return scene_resource
	var fallback_scene_path: String = game.room_template_base_scene_path(template_id, crystal_chamber)
	var fallback_resource: Resource = load(fallback_scene_path)
	return fallback_resource as PackedScene

static func room_template_metadata(game: Node, template_id: String, door_dirs: Array = [], crystal_chamber: bool = false) -> Dictionary:
	var scene: PackedScene = game.room_template_scene(template_id, door_dirs, crystal_chamber)
	if scene == null:
		return {}
	var scene_path: String = scene.resource_path
	if game.room_template_metadata_cache.has(scene_path):
		return Dictionary(game.room_template_metadata_cache[scene_path]).duplicate(true)
	var instance: Node = scene.instantiate()
	var metadata: Dictionary = {}
	if instance != null and instance.has_method("build_template_metadata"):
		metadata = Dictionary(instance.call("build_template_metadata"))
	instance.free()
	if metadata.is_empty():
		metadata = {
			"scene_path": scene_path,
		}
	game.room_template_metadata_cache[scene_path] = metadata.duplicate(true)
	return metadata.duplicate(true)

static func shrink_normalized_rect(_game: Node, rect: Rect2, margin: Vector2) -> Rect2:
	var shrunk_position: Vector2 = rect.position + margin
	var shrunk_size: Vector2 = rect.size - margin * 2.0
	return Rect2(
		shrunk_position,
		Vector2(
			maxf(shrunk_size.x, 0.04),
			maxf(shrunk_size.y, 0.04)
		)
	)

static func floor_theme_id_for_floor(game: Node, target_floor_index: int) -> String:
	if game.FLOOR_THEME_ORDER.is_empty():
		return game.FLOOR_THEME_CAVERN
	return game.FLOOR_THEME_ORDER[posmod(target_floor_index - 1, game.FLOOR_THEME_ORDER.size())]

static func current_floor_theme_id(game: Node) -> String:
	return game.floor_theme_id_for_floor(game.floor_index)

static func pick_room_geometry_id(game: Node, template_id: String, door_dirs: Array, crystal_chamber: bool = false) -> String:
	if crystal_chamber:
		return "crystal_grotto"
	var candidates: Array[String] = [
		"flooded_cross",
		"moss_terraces",
	]
	var has_horizontal: bool = door_dirs.has(Vector2i.LEFT) or door_dirs.has(Vector2i.RIGHT)
	var has_vertical: bool = door_dirs.has(Vector2i.UP) or door_dirs.has(Vector2i.DOWN)
	if has_horizontal:
		candidates.append("stream_horizontal")
	if has_vertical:
		candidates.append("stream_vertical")
	if template_id == game.ROOM_TEMPLATE_WORKSHOP or template_id == game.ROOM_TEMPLATE_FORGE or door_dirs.size() >= 3:
		candidates.append("moss_terraces")
	return candidates[game.rng.randi_range(0, candidates.size() - 1)]

static func build_room_geometry(game: Node, template_id: String, door_dirs: Array, crystal_chamber: bool = false) -> Dictionary:
	var metadata: Dictionary = game.room_template_metadata(template_id, door_dirs, crystal_chamber)
	var walkable_regions: Array = []
	for spec_variant in Array(metadata.get("walkable_region_specs", [])):
		var spec: Dictionary = spec_variant
		var required_door_key: String = String(spec.get("required_door_key", ""))
		if not required_door_key.is_empty():
			var required_direction: Vector2i = Vector2i.ZERO
			match required_door_key:
				"left":
					required_direction = Vector2i.LEFT
				"right":
					required_direction = Vector2i.RIGHT
				"up":
					required_direction = Vector2i.UP
				"down":
					required_direction = Vector2i.DOWN
			if required_direction == Vector2i.ZERO or not door_dirs.has(required_direction):
				continue
		if spec.has("rect"):
			walkable_regions.append(Rect2(spec["rect"]))
	var slot_regions: Array = Array(metadata.get("slot_regions_normalized", []))
	var geometry_id: String = String(metadata.get("geometry_id", game.pick_room_geometry_id(template_id, door_dirs, crystal_chamber)))
	var liquid_regions: Array = []
	var growth_regions: Array = []
	var obstacle_regions: Array = []
	return {
		"geometry_id": geometry_id,
		"walkable_regions": walkable_regions.duplicate(true),
		"slot_regions": slot_regions,
		"liquid_regions": liquid_regions,
		"growth_regions": growth_regions,
		"obstacle_regions": obstacle_regions,
	}

static func normalize_runtime_room_slot_capacity(game: Node, room_coord: Vector2i, room_data: Dictionary) -> Dictionary:
	var normalized: Dictionary = room_data.duplicate(true)
	var scene_minor_positions: Array = []
	var scene_metadata: Dictionary = {}
	if Array(normalized.get("minor_slot_positions_normalized", [])).is_empty() or (int(normalized.get("minor_slots", 0)) <= 0 and room_coord != game.crystal_room):
		scene_metadata = game.room_template_metadata(String(normalized.get("profile", game.ROOM_TEMPLATE_NOOK)), Array(normalized.get("door_dirs", [])), room_coord == game.crystal_room)
		scene_minor_positions = Array(scene_metadata.get("minor_slot_positions_normalized", []))
		if Array(normalized.get("minor_slot_positions_normalized", [])).is_empty() and not scene_minor_positions.is_empty():
			normalized["minor_slot_positions_normalized"] = scene_minor_positions.duplicate(true)
		if not normalized.has("major_slot_normalized") and scene_metadata.has("major_slot_normalized"):
			normalized["major_slot_normalized"] = Vector2(scene_metadata["major_slot_normalized"])
	var minor_positions: Array = Array(normalized.get("minor_slot_positions_normalized", []))
	if not minor_positions.is_empty():
		normalized["minor_slots"] = maxi(int(normalized.get("minor_slots", 0)), minor_positions.size())
	return normalized

static func normalize_runtime_rooms_slot_capacity(game: Node) -> void:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		game.rooms[room_coord] = game.normalize_runtime_room_slot_capacity(room_coord, Dictionary(game.rooms[room_coord]))

static func create_room(game: Node, room_coord: Vector2i, template_id: String, door_dirs: Array, world_center: Vector2 = Vector2.INF) -> void:
	var template_metadata: Dictionary = game.room_template_metadata(template_id, door_dirs, room_coord == game.crystal_room)
	var room_size: Vector2 = Vector2(330.0, 220.0)
	var minor_slots: int = 2
	var major_slots: int = 0
	var template_name: String = "Nook"
	var seeded_permanent_light: bool = false
	room_size = Vector2(template_metadata.get("room_size", room_size))
	minor_slots = int(template_metadata.get("minor_slots", minor_slots))
	major_slots = int(template_metadata.get("major_slots", major_slots))
	template_name = String(template_metadata.get("template_name", template_name))
	var geometry_data: Dictionary = game.build_room_geometry(template_id, door_dirs, room_coord == game.crystal_room)
	var theme_id: String = game.current_floor_theme_id()
	var room_data: Dictionary = {
		"neighbors": [],
		"center": world_center if world_center != Vector2.INF else game.room_center(room_coord),
		"opened": false,
		"lit": seeded_permanent_light,
		"permanent_light": seeded_permanent_light,
		"permanent_light_seeded": seeded_permanent_light,
		"temporary_light_turns": 0,
		"wave_torch_until_wave": -1,
		"crystal": false,
		"exit": false,
		"profile": template_id,
		"theme_id": theme_id,
		"template_name": template_name,
		"door_dirs": door_dirs.duplicate(),
		"room_scene_path": String(template_metadata.get("scene_path", game.room_template_scene_path(template_id, door_dirs, room_coord == game.crystal_room))),
		"door_positions_normalized": Dictionary(template_metadata.get("door_positions_normalized", {})).duplicate(true),
		"geometry_id": String(geometry_data.get("geometry_id", "flooded_cross")),
		"walkable_regions": Array(geometry_data.get("walkable_regions", [])),
		"slot_regions": Array(geometry_data.get("slot_regions", [])),
		"liquid_regions": Array(geometry_data.get("liquid_regions", [])),
		"growth_regions": Array(geometry_data.get("growth_regions", [])),
		"obstacle_regions": Array(geometry_data.get("obstacle_regions", [])),
		"size": room_size,
		"minor_slots": minor_slots,
		"major_slots": major_slots,
		"minor_modules": [],
		"major_module_type": "",
		"major_health": 0.0,
		"major_under_construction": false,
		"research_crystal": false,
		"research_crystal_spent": false,
		"neurostun_time_left": 0.0,
		"warning_timer_left": 0.0,
		"color_filter_id": "",
		"ground_items": [],
		"merchant_theme": "",
		"merchant_stock": [],
		"merchant_buyback": [],
		"merchant_buyback_doors_opened": 0,
		"feature_force_loot": false,
		"feature_spawn_priority": false,
		"feature_bonus_resource_event": "",
	}
	if template_metadata.has("major_slot_normalized"):
		room_data["major_slot_normalized"] = Vector2(template_metadata["major_slot_normalized"])
	room_data["minor_slot_positions_normalized"] = Array(template_metadata.get("minor_slot_positions_normalized", [])).duplicate(true)
	game.rooms[room_coord] = game.normalize_runtime_room_slot_capacity(room_coord, room_data)

static func room_template_door_options(game: Node, template_id: String) -> Array:
	match template_id:
		game.ROOM_TEMPLATE_GALLERY:
			return [
				[Vector2i.LEFT, Vector2i.RIGHT],
				[Vector2i.UP, Vector2i.DOWN],
				[Vector2i.LEFT, Vector2i.UP],
				[Vector2i.UP, Vector2i.RIGHT],
				[Vector2i.RIGHT, Vector2i.DOWN],
				[Vector2i.DOWN, Vector2i.LEFT],
			]
		game.ROOM_TEMPLATE_WORKSHOP:
			return [
				[Vector2i.LEFT],
				[Vector2i.RIGHT],
				[Vector2i.UP],
				[Vector2i.DOWN],
				[Vector2i.LEFT, Vector2i.UP],
				[Vector2i.UP, Vector2i.RIGHT],
				[Vector2i.RIGHT, Vector2i.DOWN],
				[Vector2i.DOWN, Vector2i.LEFT],
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP],
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN],
				[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT],
				[Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT],
			]
		game.ROOM_TEMPLATE_FORGE:
			return [
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP],
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN],
				[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT],
				[Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT],
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN],
			]
		_:
			return [
				[Vector2i.LEFT],
				[Vector2i.RIGHT],
				[Vector2i.UP],
				[Vector2i.DOWN],
			]

static func random_template_doors(game: Node, template_id: String, required_dir: Vector2i = Vector2i(-99, -99)) -> Array:
	var valid_options: Array = []
	for option in game.room_template_door_options(template_id):
		if required_dir == game.INVALID_ROOM or option.has(required_dir):
			valid_options.append(option)
	if valid_options.is_empty():
		return []
	var chosen: Array = valid_options[game.rng.randi_range(0, valid_options.size() - 1)]
	return chosen.duplicate()

static func template_can_support_major_slots(game: Node, template_id: String) -> bool:
	return template_id != ""

static func room_blueprint_weight(game: Node, template_id: String, door_dirs: Array, prefer_major: bool = false, prefer_dead_end: bool = false) -> float:
	var weight: float = 1.0
	match template_id:
		game.ROOM_TEMPLATE_NOOK:
			weight = 3.0
		game.ROOM_TEMPLATE_GALLERY:
			weight = 2.1
		game.ROOM_TEMPLATE_WORKSHOP:
			weight = 2.2
		game.ROOM_TEMPLATE_FORGE:
			weight = 1.15
		_:
			weight = 1.0
	var door_count: int = door_dirs.size()
	if prefer_dead_end:
		if door_count <= 1:
			weight *= 2.45
		elif door_count == 2:
			weight *= 1.05
		else:
			weight *= 0.58
	else:
		if door_count <= 1:
			weight *= 1.22
		elif door_count >= 4:
			weight *= 0.82
	if prefer_major:
		if game.template_can_support_major_slots(template_id):
			weight *= 3.0
		elif template_id == game.ROOM_TEMPLATE_GALLERY:
			weight *= 0.55
		else:
			weight *= 0.18
	return weight

static func roll_room_blueprint(game: Node, required_dir: Vector2i, prefer_major: bool = false, prefer_dead_end: bool = false, minimum_doors: int = 1) -> Dictionary:
	var candidates: Array = []
	var total_weight: float = 0.0
	for template_id_variant in [game.ROOM_TEMPLATE_NOOK, game.ROOM_TEMPLATE_GALLERY, game.ROOM_TEMPLATE_WORKSHOP, game.ROOM_TEMPLATE_FORGE]:
		var template_id: String = String(template_id_variant)
		for option_variant in game.room_template_door_options(template_id):
			var door_dirs: Array = Array(option_variant)
			if (required_dir != game.INVALID_ROOM and not door_dirs.has(required_dir)) or door_dirs.size() < minimum_doors:
				continue
			var candidate_weight: float = game.room_blueprint_weight(template_id, door_dirs, prefer_major, prefer_dead_end)
			if candidate_weight <= 0.0:
				continue
			candidates.append({
				"template_id": template_id,
				"door_dirs": door_dirs.duplicate(),
				"weight": candidate_weight,
			})
			total_weight += candidate_weight
	if candidates.is_empty():
		return {}
	var roll: float = game.rng.randf() * maxf(total_weight, 0.001)
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		roll -= float(candidate.get("weight", 1.0))
		if roll <= 0.0:
			return {
				"template_id": String(candidate.get("template_id", game.ROOM_TEMPLATE_NOOK)),
				"door_dirs": Array(candidate.get("door_dirs", [])).duplicate(),
			}
	var fallback: Dictionary = candidates[candidates.size() - 1]
	return {
		"template_id": String(fallback.get("template_id", game.ROOM_TEMPLATE_NOOK)),
		"door_dirs": Array(fallback.get("door_dirs", [])).duplicate(),
	}

static func room_template_size(game: Node, template_id: String) -> Vector2:
	var metadata: Dictionary = game.room_template_metadata(template_id)
	if metadata.has("room_size"):
		return Vector2(metadata["room_size"])
	match template_id:
		game.ROOM_TEMPLATE_GALLERY:
			return Vector2(400.0, 250.0)
		game.ROOM_TEMPLATE_WORKSHOP:
			return Vector2(490.0, 320.0)
		game.ROOM_TEMPLATE_FORGE:
			return Vector2(540.0, 350.0)
		_:
			return Vector2(330.0, 220.0)

static func proposed_room_center(game: Node, origin_room: Vector2i, template_id: String, direction: Vector2i) -> Vector2:
	var origin_size: Vector2 = game.room_size_for(origin_room)
	var next_size: Vector2 = game.room_template_size(template_id)
	var offset: Vector2 = Vector2.ZERO
	if direction.x != 0:
		offset.x = float(direction.x) * ((origin_size.x + next_size.x) * 0.5 + game.ROOM_DOOR_GAP)
	if direction.y != 0:
		offset.y = float(direction.y) * ((origin_size.y + next_size.y) * 0.5 + game.ROOM_DOOR_GAP)
	return game.room_center(origin_room) + offset

static func can_place_room_center(game: Node, world_center: Vector2, room_size: Vector2) -> bool:
	var candidate_rect: Rect2 = Rect2(world_center - room_size * 0.5, room_size).grow(game.ROOM_LAYOUT_CLEARANCE)
	for existing_coord_variant in game.rooms.keys():
		var existing_coord: Vector2i = existing_coord_variant
		if candidate_rect.intersects(game.room_rect(existing_coord).grow(game.ROOM_LAYOUT_CLEARANCE)):
			return false
	return true

static func collect_frontier_sockets(game: Node) -> Array:
	var sockets: Array = []
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		for direction_variant in room["door_dirs"]:
			var direction: Vector2i = direction_variant
			var candidate: Vector2i = room_coord + direction
			if not is_in_bounds(game, candidate) or game.rooms.has(candidate):
				continue
			sockets.append({
				"room": room_coord,
				"direction": direction,
			})
	return sockets

static func connect_rooms(game: Node, a: Vector2i, b: Vector2i) -> void:
	var delta: Vector2i = b - a
	if not game.rooms[a]["door_dirs"].has(delta) or not game.rooms[b]["door_dirs"].has(-delta):
		return
	if not game.rooms[a]["neighbors"].has(b):
		game.rooms[a]["neighbors"].append(b)
	if not game.rooms[b]["neighbors"].has(a):
		game.rooms[b]["neighbors"].append(a)

static func are_neighbors(game: Node, a: Vector2i, b: Vector2i) -> bool:
	return game.rooms.has(a) and game.rooms[a]["neighbors"].has(b)

static func reconcile_room_connections(game: Node) -> void:
	var edge_keys: Dictionary = {}
	var connected_edges: Array = []
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var listed_neighbors: Array = Array(game.rooms[room_coord].get("neighbors", []))
		for neighbor_variant in listed_neighbors:
			var neighbor_coord: Vector2i = neighbor_variant
			if not game.rooms.has(neighbor_coord):
				continue
			var delta: Vector2i = neighbor_coord - room_coord
			if abs(delta.x) + abs(delta.y) != 1:
				continue
			var first: Vector2i = room_coord
			var second: Vector2i = neighbor_coord
			if second.x < first.x or (second.x == first.x and second.y < first.y):
				first = neighbor_coord
				second = room_coord
			var edge_key: String = "%d,%d|%d,%d" % [first.x, first.y, second.x, second.y]
			if edge_keys.has(edge_key):
				continue
			edge_keys[edge_key] = true
			connected_edges.append({"a": first, "b": second})

	var neighbor_map: Dictionary = {}
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		neighbor_map[room_coord] = []
	for edge_variant in connected_edges:
		var edge: Dictionary = edge_variant
		var room_a: Vector2i = Vector2i(edge.get("a", game.INVALID_ROOM))
		var room_b: Vector2i = Vector2i(edge.get("b", game.INVALID_ROOM))
		if room_a == game.INVALID_ROOM or room_b == game.INVALID_ROOM:
			continue
		var a_neighbors: Array = Array(neighbor_map.get(room_a, []))
		if not a_neighbors.has(room_b):
			a_neighbors.append(room_b)
		neighbor_map[room_a] = a_neighbors
		var b_neighbors: Array = Array(neighbor_map.get(room_b, []))
		if not b_neighbors.has(room_a):
			b_neighbors.append(room_a)
		neighbor_map[room_b] = b_neighbors

	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = Dictionary(game.rooms[room_coord]).duplicate(true)
		var normalized_neighbors: Array = Array(neighbor_map.get(room_coord, [])).duplicate(true)
		room["neighbors"] = normalized_neighbors

		var normalized_door_dirs: Array = []
		for direction_variant in game.CARDINAL_DIRS:
			var direction: Vector2i = direction_variant
			var neighbor_coord: Vector2i = room_coord + direction
			if normalized_neighbors.has(neighbor_coord):
				normalized_door_dirs.append(direction)
		room["door_dirs"] = normalized_door_dirs

		var old_door_positions: Dictionary = Dictionary(room.get("door_positions_normalized", {})).duplicate(true)
		var filtered_door_positions: Dictionary = {}
		for direction_variant in normalized_door_dirs:
			var direction: Vector2i = direction_variant
			var direction_key: String = game.cardinal_dir_key(direction)
			if direction_key != "" and old_door_positions.has(direction_key):
				filtered_door_positions[direction_key] = old_door_positions[direction_key]
		room["door_positions_normalized"] = filtered_door_positions

		var profile_id: String = String(room.get("profile", game.ROOM_TEMPLATE_NOOK))
		var crystal_chamber: bool = room_coord == game.crystal_room
		var geometry_data: Dictionary = game.build_room_geometry(profile_id, normalized_door_dirs, crystal_chamber)
		room["geometry_id"] = String(geometry_data.get("geometry_id", room.get("geometry_id", "flooded_cross")))
		room["walkable_regions"] = Array(geometry_data.get("walkable_regions", room.get("walkable_regions", []))).duplicate(true)
		room["slot_regions"] = Array(geometry_data.get("slot_regions", room.get("slot_regions", []))).duplicate(true)
		room["liquid_regions"] = Array(geometry_data.get("liquid_regions", room.get("liquid_regions", []))).duplicate(true)
		room["growth_regions"] = Array(geometry_data.get("growth_regions", room.get("growth_regions", []))).duplicate(true)
		room["obstacle_regions"] = Array(geometry_data.get("obstacle_regions", room.get("obstacle_regions", []))).duplicate(true)
		room["room_scene_path"] = String(game.room_template_scene_path(profile_id, normalized_door_dirs, crystal_chamber))

		game.rooms[room_coord] = game.normalize_runtime_room_slot_capacity(room_coord, room)

static func finalize_room_slot_distribution(game: Node) -> void:
	var second_room: Vector2i = game.INVALID_ROOM
	if game.rooms.has(game.crystal_room):
		var crystal_neighbors: Array = Array(game.rooms[game.crystal_room].get("neighbors", []))
		if not crystal_neighbors.is_empty():
			second_room = Vector2i(crystal_neighbors[0])
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if room_coord == game.crystal_room:
			room["minor_slots"] = 0
			room["major_slots"] = 0
			continue
		var degree: int = Array(room.get("neighbors", [])).size()
		var profile_id: String = String(room.get("profile", game.ROOM_TEMPLATE_NOOK))
		var major_slot_chance: float = 0.18
		match profile_id:
			game.ROOM_TEMPLATE_FORGE:
				major_slot_chance = 1.0
			game.ROOM_TEMPLATE_WORKSHOP:
				major_slot_chance = 0.62 if degree <= 1 else 0.44
			game.ROOM_TEMPLATE_GALLERY:
				major_slot_chance = 0.34 if degree <= 1 else 0.22
			game.ROOM_TEMPLATE_NOOK:
				major_slot_chance = 0.26 if degree <= 1 else 0.16
			_:
				major_slot_chance = 0.2
		room["major_slots"] = 1 if game.rng.randf() < major_slot_chance else 0
	if second_room != game.INVALID_ROOM and game.rooms.has(second_room):
		game.rooms[second_room]["major_slots"] = max(1, int(game.rooms[second_room].get("major_slots", 0)))

static func assign_exit_room(game: Node) -> void:
	var best_path_length: int = -1
	game.exit_room = game.INVALID_ROOM
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		game.rooms[room_coord]["exit"] = false
		if room_coord == game.crystal_room:
			continue
		var path: Array[Vector2i] = game.find_path(game.crystal_room, room_coord, false)
		if path.is_empty():
			continue
		if path.size() > best_path_length:
			best_path_length = path.size()
			game.exit_room = room_coord
	if game.exit_room == game.INVALID_ROOM:
		for neighbor_variant in Array(game.rooms.get(game.crystal_room, {}).get("neighbors", [])):
			var fallback_room: Vector2i = neighbor_variant
			if game.rooms.has(fallback_room):
				game.exit_room = fallback_room
				break
	if game.exit_room != game.INVALID_ROOM:
		game.rooms[game.exit_room]["exit"] = true

static func assign_special_room_features(game: Node) -> void:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		game.rooms[room_coord]["research_crystal"] = false
		game.rooms[room_coord]["research_crystal_spent"] = false
		game.rooms[room_coord]["merchant_theme"] = ""
		game.rooms[room_coord]["merchant_stock"] = []
		game.rooms[room_coord]["merchant_buyback"] = []
		game.rooms[room_coord]["merchant_buyback_doors_opened"] = game.doors_opened
		game.rooms[room_coord]["feature_force_loot"] = false
		game.rooms[room_coord]["feature_spawn_priority"] = false
		game.rooms[room_coord]["feature_bonus_resource_event"] = ""
		if room_coord != game.crystal_room:
			game.rooms[room_coord]["lit"] = false
			game.rooms[room_coord]["permanent_light"] = false
			game.rooms[room_coord]["permanent_light_seeded"] = false
			game.rooms[room_coord]["temporary_light_turns"] = 0
	var first_discovered_room: Vector2i = game.INVALID_ROOM
	if game.floor_index == 1 and game.rooms.has(game.crystal_room):
		var crystal_neighbors: Array = Array(game.rooms[game.crystal_room].get("neighbors", []))
		if not crystal_neighbors.is_empty():
			first_discovered_room = Vector2i(crystal_neighbors[0])
	var eligible_rooms: Array[Vector2i] = []
	var weighted_research_candidates: Array[Dictionary] = []
	var weighted_merchant_candidates: Array[Dictionary] = []
	var weighted_loot_candidates: Array[Dictionary] = []
	var weighted_spawn_candidates: Array[Dictionary] = []
	var weighted_bonus_resource_candidates: Array[Dictionary] = []
	var weighted_permanent_light_candidates: Array[Dictionary] = []
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if room_coord == game.crystal_room:
			continue
		var room: Dictionary = game.rooms[room_coord]
		eligible_rooms.append(room_coord)
		if game.floor_index != 1 or room_coord != first_discovered_room:
			if game.effective_minor_slot_count(room_coord) > 0 and int(room.get("major_slots", 0)) > 0:
				weighted_research_candidates.append({
					"room": room_coord,
					"weight": research_room_feature_weight(game, room_coord),
				})
		weighted_merchant_candidates.append({
			"room": room_coord,
			"weight": merchant_room_feature_weight(game, room_coord),
		})
		weighted_loot_candidates.append({
			"room": room_coord,
			"weight": loot_room_feature_weight(game, room_coord),
		})
		weighted_spawn_candidates.append({
			"room": room_coord,
			"weight": spawn_room_feature_weight(game, room_coord),
		})
		weighted_bonus_resource_candidates.append({
			"room": room_coord,
			"weight": bonus_resource_room_feature_weight(game, room_coord),
		})
		weighted_permanent_light_candidates.append({
			"room": room_coord,
			"weight": permanent_light_room_feature_weight(game, room_coord),
		})
	if weighted_research_candidates.is_empty() and not eligible_rooms.is_empty():
		var weighted_eligible_rooms: Array[Dictionary] = []
		for eligible_room in eligible_rooms:
			if game.floor_index == 1 and eligible_room == first_discovered_room:
				continue
			if game.effective_minor_slot_count(eligible_room) <= 0:
				continue
			weighted_eligible_rooms.append({
				"room": eligible_room,
				"weight": research_room_feature_weight(game, eligible_room),
			})
		if not weighted_eligible_rooms.is_empty():
			var promoted_room: Vector2i = weighted_pick_room(game, weighted_eligible_rooms)
			if promoted_room != game.INVALID_ROOM and game.rooms.has(promoted_room):
				game.rooms[promoted_room]["major_slots"] = max(1, int(game.rooms[promoted_room].get("major_slots", 0)))
				weighted_research_candidates.append({
					"room": promoted_room,
					"weight": research_room_feature_weight(game, promoted_room),
				})

	var combined_entries: Array[Dictionary] = []
	for entry_variant in weighted_research_candidates:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["feature"] = SPECIAL_FEATURE_RESEARCH
		combined_entries.append(entry)
	for entry_variant in weighted_merchant_candidates:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["feature"] = SPECIAL_FEATURE_MERCHANT
		combined_entries.append(entry)
	for entry_variant in weighted_loot_candidates:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["feature"] = SPECIAL_FEATURE_LOOT
		combined_entries.append(entry)
	for entry_variant in weighted_spawn_candidates:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["feature"] = SPECIAL_FEATURE_SPAWN
		combined_entries.append(entry)
	for entry_variant in weighted_bonus_resource_candidates:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["feature"] = SPECIAL_FEATURE_BONUS_RESOURCE
		combined_entries.append(entry)
	for entry_variant in weighted_permanent_light_candidates:
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		entry["feature"] = SPECIAL_FEATURE_PERMANENT_LIGHT
		combined_entries.append(entry)

	var assigned_rooms: Dictionary = {}
	var required_features: Array[String] = [
		SPECIAL_FEATURE_RESEARCH,
		SPECIAL_FEATURE_MERCHANT,
		SPECIAL_FEATURE_LOOT,
		SPECIAL_FEATURE_SPAWN,
		SPECIAL_FEATURE_BONUS_RESOURCE,
		SPECIAL_FEATURE_PERMANENT_LIGHT,
	]
	while not combined_entries.is_empty() and assigned_rooms.size() < required_features.size():
		var picked_entry: Dictionary = weighted_pick_entry(game, combined_entries)
		if picked_entry.is_empty():
			break
		var feature_id: String = String(picked_entry.get("feature", ""))
		var picked_room: Vector2i = Vector2i(picked_entry.get("room", game.INVALID_ROOM))
		if feature_id == "" or picked_room == game.INVALID_ROOM:
			break
		if assigned_rooms.has(feature_id):
			continue
		assigned_rooms[feature_id] = picked_room
		var filtered_entries: Array[Dictionary] = []
		for candidate_variant in combined_entries:
			var candidate: Dictionary = candidate_variant
			if String(candidate.get("feature", "")) == feature_id:
				continue
			if Vector2i(candidate.get("room", game.INVALID_ROOM)) == picked_room:
				continue
			filtered_entries.append(candidate)
		combined_entries = filtered_entries

	if not assigned_rooms.has(SPECIAL_FEATURE_RESEARCH):
		var fallback_research: Vector2i = weighted_pick_room(game, weighted_research_candidates)
		if fallback_research != game.INVALID_ROOM:
			assigned_rooms[SPECIAL_FEATURE_RESEARCH] = fallback_research
	if not assigned_rooms.has(SPECIAL_FEATURE_MERCHANT):
		var weighted_merchant_fallback: Array[Dictionary] = []
		for entry_variant in weighted_merchant_candidates:
			var entry: Dictionary = entry_variant
			var entry_room: Vector2i = Vector2i(entry.get("room", game.INVALID_ROOM))
			if entry_room == Vector2i(assigned_rooms.get(SPECIAL_FEATURE_RESEARCH, game.INVALID_ROOM)):
				continue
			weighted_merchant_fallback.append(entry)
		var fallback_merchant: Vector2i = weighted_pick_room(game, weighted_merchant_fallback)
		if fallback_merchant != game.INVALID_ROOM:
			assigned_rooms[SPECIAL_FEATURE_MERCHANT] = fallback_merchant
	if not assigned_rooms.has(SPECIAL_FEATURE_LOOT):
		var weighted_loot_fallback: Array[Dictionary] = []
		for entry_variant in weighted_loot_candidates:
			var entry: Dictionary = entry_variant
			var entry_room: Vector2i = Vector2i(entry.get("room", game.INVALID_ROOM))
			if assigned_rooms.values().has(entry_room):
				continue
			weighted_loot_fallback.append(entry)
		var fallback_loot: Vector2i = weighted_pick_room(game, weighted_loot_fallback)
		if fallback_loot != game.INVALID_ROOM:
			assigned_rooms[SPECIAL_FEATURE_LOOT] = fallback_loot
	if not assigned_rooms.has(SPECIAL_FEATURE_SPAWN):
		var weighted_spawn_fallback: Array[Dictionary] = []
		for entry_variant in weighted_spawn_candidates:
			var entry: Dictionary = entry_variant
			var entry_room: Vector2i = Vector2i(entry.get("room", game.INVALID_ROOM))
			if assigned_rooms.values().has(entry_room):
				continue
			weighted_spawn_fallback.append(entry)
		var fallback_spawn: Vector2i = weighted_pick_room(game, weighted_spawn_fallback)
		if fallback_spawn != game.INVALID_ROOM:
			assigned_rooms[SPECIAL_FEATURE_SPAWN] = fallback_spawn
	if not assigned_rooms.has(SPECIAL_FEATURE_BONUS_RESOURCE):
		var weighted_bonus_resource_fallback: Array[Dictionary] = []
		for entry_variant in weighted_bonus_resource_candidates:
			var entry: Dictionary = entry_variant
			var entry_room: Vector2i = Vector2i(entry.get("room", game.INVALID_ROOM))
			if assigned_rooms.values().has(entry_room):
				continue
			weighted_bonus_resource_fallback.append(entry)
		var fallback_bonus_resource: Vector2i = weighted_pick_room(game, weighted_bonus_resource_fallback)
		if fallback_bonus_resource != game.INVALID_ROOM:
			assigned_rooms[SPECIAL_FEATURE_BONUS_RESOURCE] = fallback_bonus_resource
	if not assigned_rooms.has(SPECIAL_FEATURE_PERMANENT_LIGHT):
		var weighted_permanent_light_fallback: Array[Dictionary] = []
		for entry_variant in weighted_permanent_light_candidates:
			var entry: Dictionary = entry_variant
			var entry_room: Vector2i = Vector2i(entry.get("room", game.INVALID_ROOM))
			if assigned_rooms.values().has(entry_room):
				continue
			weighted_permanent_light_fallback.append(entry)
		var fallback_permanent_light: Vector2i = weighted_pick_room(game, weighted_permanent_light_fallback)
		if fallback_permanent_light != game.INVALID_ROOM:
			assigned_rooms[SPECIAL_FEATURE_PERMANENT_LIGHT] = fallback_permanent_light

	if assigned_rooms.has(SPECIAL_FEATURE_RESEARCH):
		var research_room: Vector2i = Vector2i(assigned_rooms.get(SPECIAL_FEATURE_RESEARCH, game.INVALID_ROOM))
		if research_room != game.INVALID_ROOM and game.rooms.has(research_room):
			game.rooms[research_room]["research_crystal"] = true
	if assigned_rooms.has(SPECIAL_FEATURE_MERCHANT):
		var merchant_room: Vector2i = Vector2i(assigned_rooms.get(SPECIAL_FEATURE_MERCHANT, game.INVALID_ROOM))
		if merchant_room != game.INVALID_ROOM and game.rooms.has(merchant_room):
			apply_merchant_to_room(game, merchant_room)
	if assigned_rooms.has(SPECIAL_FEATURE_LOOT):
		var loot_room: Vector2i = Vector2i(assigned_rooms.get(SPECIAL_FEATURE_LOOT, game.INVALID_ROOM))
		if loot_room != game.INVALID_ROOM and game.rooms.has(loot_room):
			game.rooms[loot_room]["feature_force_loot"] = true
	if assigned_rooms.has(SPECIAL_FEATURE_SPAWN):
		var spawn_room: Vector2i = Vector2i(assigned_rooms.get(SPECIAL_FEATURE_SPAWN, game.INVALID_ROOM))
		if spawn_room != game.INVALID_ROOM and game.rooms.has(spawn_room):
			game.rooms[spawn_room]["feature_spawn_priority"] = true
	if assigned_rooms.has(SPECIAL_FEATURE_BONUS_RESOURCE):
		var bonus_resource_room: Vector2i = Vector2i(assigned_rooms.get(SPECIAL_FEATURE_BONUS_RESOURCE, game.INVALID_ROOM))
		if bonus_resource_room != game.INVALID_ROOM and game.rooms.has(bonus_resource_room):
			game.rooms[bonus_resource_room]["feature_bonus_resource_event"] = roll_bonus_resource_event_id(game)
	if assigned_rooms.has(SPECIAL_FEATURE_PERMANENT_LIGHT):
		var permanent_light_room: Vector2i = Vector2i(assigned_rooms.get(SPECIAL_FEATURE_PERMANENT_LIGHT, game.INVALID_ROOM))
		if permanent_light_room != game.INVALID_ROOM and game.rooms.has(permanent_light_room):
			game.rooms[permanent_light_room]["permanent_light"] = true
			game.rooms[permanent_light_room]["permanent_light_seeded"] = true
			game.rooms[permanent_light_room]["lit"] = true

static func apply_merchant_to_room(game: Node, merchant_room: Vector2i) -> void:
	if merchant_room == game.INVALID_ROOM or not game.rooms.has(merchant_room):
		return
	var merchant_themes: Array[String] = GAME_INVENTORY_ITEM_FLOW.merchant_theme_ids(game)
	var chosen_theme: String = "dust"
	if not merchant_themes.is_empty():
		chosen_theme = merchant_themes[game.rng.randi_range(0, merchant_themes.size() - 1)]
	var room_data: Dictionary = game.rooms[merchant_room]
	room_data["merchant_theme"] = chosen_theme
	room_data["merchant_stock"] = GAME_INVENTORY_ITEM_FLOW.generate_merchant_stock(game, 5)
	room_data["merchant_buyback"] = []
	room_data["merchant_buyback_doors_opened"] = game.doors_opened
	room_data["ground_items"] = []
	game.rooms[merchant_room] = room_data

static func weighted_pick_room(game: Node, weighted_rooms: Array[Dictionary]) -> Vector2i:
	if weighted_rooms.is_empty():
		return game.INVALID_ROOM
	var total_weight: float = 0.0
	for entry_variant in weighted_rooms:
		var entry: Dictionary = entry_variant
		total_weight += maxf(float(entry.get("weight", 0.0)), 0.0)
	if total_weight <= 0.0:
		return Vector2i(weighted_rooms[game.rng.randi_range(0, weighted_rooms.size() - 1)].get("room", game.INVALID_ROOM))
	var roll: float = game.rng.randf() * total_weight
	for entry_variant in weighted_rooms:
		var entry: Dictionary = entry_variant
		roll -= maxf(float(entry.get("weight", 0.0)), 0.0)
		if roll <= 0.0:
			return Vector2i(entry.get("room", game.INVALID_ROOM))
	return Vector2i(weighted_rooms[weighted_rooms.size() - 1].get("room", game.INVALID_ROOM))

static func weighted_pick_entry(game: Node, weighted_entries: Array[Dictionary]) -> Dictionary:
	if weighted_entries.is_empty():
		return {}
	var total_weight: float = 0.0
	for entry_variant in weighted_entries:
		var entry: Dictionary = entry_variant
		total_weight += maxf(float(entry.get("weight", 0.0)), 0.0)
	if total_weight <= 0.0:
		return Dictionary(weighted_entries[game.rng.randi_range(0, weighted_entries.size() - 1)]).duplicate(true)
	var roll: float = game.rng.randf() * total_weight
	for entry_variant in weighted_entries:
		var entry: Dictionary = entry_variant
		roll -= maxf(float(entry.get("weight", 0.0)), 0.0)
		if roll <= 0.0:
			return Dictionary(entry).duplicate(true)
	return Dictionary(weighted_entries[weighted_entries.size() - 1]).duplicate(true)

static func research_room_feature_weight(game: Node, room_coord: Vector2i) -> float:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return 0.0
	var room: Dictionary = game.rooms[room_coord]
	var weight: float = SPECIAL_ROOM_WEIGHT_BASE
	if int(room.get("major_slots", 0)) > 0:
		weight += RESEARCH_MAJOR_SLOT_WEIGHT_BONUS
	var path_length: int = game.room_path_distance(game.crystal_room, room_coord)
	if path_length < 99999:
		weight += float(path_length) * RESEARCH_DISTANCE_WEIGHT_STEP
	if room_coord == game.exit_room:
		weight *= RESEARCH_EXIT_WEIGHT_MULTIPLIER
	return maxf(weight, 0.01)

static func merchant_room_feature_weight(game: Node, room_coord: Vector2i) -> float:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return 0.0
	var room: Dictionary = game.rooms[room_coord]
	var weight: float = SPECIAL_ROOM_WEIGHT_BASE
	if not bool(room.get("opened", false)) and not bool(room.get("crystal", false)):
		weight += MERCHANT_UNOPENED_WEIGHT_BONUS
	var path_length: int = game.room_path_distance(game.crystal_room, room_coord)
	if path_length < 99999:
		weight += float(path_length) * MERCHANT_DISTANCE_WEIGHT_STEP
	if room_coord == game.exit_room:
		weight *= MERCHANT_EXIT_WEIGHT_MULTIPLIER
	return maxf(weight, 0.01)

static func loot_room_feature_weight(game: Node, room_coord: Vector2i) -> float:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return 0.0
	var weight: float = SPECIAL_ROOM_WEIGHT_BASE
	var path_length: int = game.room_path_distance(game.crystal_room, room_coord)
	if path_length < 99999:
		weight += float(path_length) * LOOT_DISTANCE_WEIGHT_STEP
	if room_coord == game.exit_room:
		weight *= LOOT_EXIT_WEIGHT_MULTIPLIER
	return maxf(weight, 0.01)

static func spawn_room_feature_weight(game: Node, room_coord: Vector2i) -> float:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return 0.0
	var room: Dictionary = game.rooms[room_coord]
	var weight: float = SPECIAL_ROOM_WEIGHT_BASE
	if not bool(room.get("opened", false)) and not bool(room.get("crystal", false)):
		weight += 0.2
	var path_length: int = game.room_path_distance(game.crystal_room, room_coord)
	if path_length < 99999:
		weight += float(path_length) * SPAWN_DISTANCE_WEIGHT_STEP
	if room_coord == game.exit_room:
		weight *= SPAWN_EXIT_WEIGHT_MULTIPLIER
	return maxf(weight, 0.01)

static func bonus_resource_room_feature_weight(game: Node, room_coord: Vector2i) -> float:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return 0.0
	var weight: float = SPECIAL_ROOM_WEIGHT_BASE
	var path_length: int = game.room_path_distance(game.crystal_room, room_coord)
	if path_length < 99999:
		weight += float(path_length) * BONUS_RESOURCE_DISTANCE_WEIGHT_STEP
	if room_coord == game.exit_room:
		weight *= BONUS_RESOURCE_EXIT_WEIGHT_MULTIPLIER
	return maxf(weight, 0.01)

static func permanent_light_room_feature_weight(game: Node, room_coord: Vector2i) -> float:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return 0.0
	var weight: float = SPECIAL_ROOM_WEIGHT_BASE
	var path_length: int = game.room_path_distance(game.crystal_room, room_coord)
	if path_length < 99999:
		weight += float(path_length) * PERMANENT_LIGHT_DISTANCE_WEIGHT_STEP
	if room_coord == game.exit_room:
		weight *= PERMANENT_LIGHT_EXIT_WEIGHT_MULTIPLIER
	return maxf(weight, 0.01)

static func roll_bonus_resource_event_id(game: Node) -> String:
	var weighted_events: Array[Dictionary] = []
	if game.floor_index <= 3:
		weighted_events = [
			{"id": game.BONUS_RESOURCE_EVENT_FOOD, "weight": 22.0},
			{"id": game.BONUS_RESOURCE_EVENT_INDUSTRY, "weight": 14.0},
			{"id": game.BONUS_RESOURCE_EVENT_SCIENCE, "weight": 8.0},
		]
	elif game.floor_index <= 6:
		weighted_events = [
			{"id": game.BONUS_RESOURCE_EVENT_FOOD, "weight": 16.0},
			{"id": game.BONUS_RESOURCE_EVENT_INDUSTRY, "weight": 18.0},
			{"id": game.BONUS_RESOURCE_EVENT_SCIENCE, "weight": 18.0},
		]
	else:
		weighted_events = [
			{"id": game.BONUS_RESOURCE_EVENT_FOOD, "weight": 12.0},
			{"id": game.BONUS_RESOURCE_EVENT_INDUSTRY, "weight": 20.0},
			{"id": game.BONUS_RESOURCE_EVENT_SCIENCE, "weight": 26.0},
		]
	var total_weight: float = 0.0
	for entry_variant in weighted_events:
		var entry: Dictionary = entry_variant
		total_weight += maxf(float(entry.get("weight", 0.0)), 0.0)
	if total_weight <= 0.0:
		return game.BONUS_RESOURCE_EVENT_INDUSTRY
	var roll: float = game.rng.randf() * total_weight
	for entry_variant in weighted_events:
		var entry: Dictionary = entry_variant
		roll -= maxf(float(entry.get("weight", 0.0)), 0.0)
		if roll <= 0.0:
			return String(entry.get("id", game.BONUS_RESOURCE_EVENT_INDUSTRY))
	return String(weighted_events[weighted_events.size() - 1].get("id", game.BONUS_RESOURCE_EVENT_INDUSTRY))

static func find_path(game: Node, from_room: Vector2i, to_room: Vector2i, only_open_rooms: bool) -> Array[Vector2i]:
	if from_room == to_room:
		return [from_room]
	var frontier: Array[Vector2i] = [from_room]
	var came_from: Dictionary = {from_room: from_room}
	while not frontier.is_empty():
		var current: Vector2i = frontier[0]
		frontier.remove_at(0)
		if current == to_room:
			break
		for neighbor_variant in game.rooms[current]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if only_open_rooms and not game.rooms[neighbor]["opened"]:
				continue
			if came_from.has(neighbor):
				continue
			frontier.append(neighbor)
			came_from[neighbor] = current
	if not came_from.has(to_room):
		return []
	var path: Array[Vector2i] = []
	var cursor: Vector2i = to_room
	while true:
		path.append(cursor)
		if cursor == from_room:
			break
		cursor = came_from[cursor]
	path.reverse()
	return path

static func room_at_world_position(game: Node, world_position: Vector2) -> Vector2i:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if game.rooms[room_coord]["opened"] and game.room_rect(room_coord).has_point(world_position):
			return room_coord
	return game.INVALID_ROOM

static func corridor_room_target_at_position(game: Node, world_position: Vector2, preferred_from_room: Vector2i = Vector2i(-99, -99)) -> Vector2i:
	var direct_room: Vector2i = game.room_at_world_position(world_position)
	if direct_room != game.INVALID_ROOM:
		return direct_room
	var best_room: Vector2i = game.INVALID_ROOM
	var best_distance: float = INF
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if not game.rooms[neighbor]["opened"]:
				continue
			if room_coord.x > neighbor.x or (room_coord.x == neighbor.x and room_coord.y > neighbor.y):
				continue
			var corridor_target: Dictionary = game.open_corridor_target_for_pair(world_position, room_coord, neighbor, preferred_from_room)
			if corridor_target.is_empty():
				continue
			var corridor_distance: float = float(corridor_target.get("distance", INF))
			if corridor_distance < best_distance:
				best_distance = corridor_distance
				best_room = corridor_target.get("room", game.INVALID_ROOM)
	return best_room

static func open_corridor_target_for_pair(game: Node, world_position: Vector2, room_a: Vector2i, room_b: Vector2i, preferred_from_room: Vector2i = Vector2i(-99, -99)) -> Dictionary:
	var delta: Vector2i = room_b - room_a
	var direction: Vector2 = Vector2(float(delta.x), float(delta.y))
	if direction == Vector2.ZERO:
		return {}
	direction = direction.normalized()
	var tangent: Vector2 = Vector2(-direction.y, direction.x)
	var doorway_a: Vector2 = game.doorway_position(room_a, room_b)
	var doorway_b: Vector2 = game.doorway_position(room_b, room_a)
	var corridor_depth: float = doorway_a.distance_to(doorway_b)
	var offset: Vector2 = world_position - doorway_a
	var forward_distance: float = offset.dot(direction)
	var lateral_distance: float = absf(offset.dot(tangent))
	var room_a_half: Vector2 = game.room_size_for(room_a) * 0.5
	var room_b_half: Vector2 = game.room_size_for(room_b) * 0.5
	var lateral_limit: float = maxf(room_a_half.y, room_b_half.y) + 34.0 if delta.x != 0 else maxf(room_a_half.x, room_b_half.x) + 34.0
	if forward_distance < -18.0 or forward_distance > corridor_depth + 18.0 or lateral_distance > lateral_limit:
		return {}
	var target_room: Vector2i = game.INVALID_ROOM
	if preferred_from_room == room_a:
		target_room = room_b
	elif preferred_from_room == room_b:
		target_room = room_a
	else:
		target_room = room_b if forward_distance >= corridor_depth * 0.5 else room_a
	return {
		"room": target_room,
		"distance": game.point_distance_to_segment(world_position, doorway_a, doorway_b),
	}

static func room_is_revealed(game: Node, room_coord: Vector2i) -> bool:
	return game.rooms.has(room_coord) and game.rooms[room_coord]["opened"]

static func frontier_target_at_position(game: Node, world_position: Vector2) -> Dictionary:
	var door_target: Dictionary = game.frontier_door_at_position(world_position)
	if not door_target.is_empty():
		return door_target
	var wall_target: Dictionary = game.frontier_wall_target_at_position(world_position)
	if not wall_target.is_empty():
		return wall_target
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if game.rooms[neighbor]["opened"]:
				continue
			if game.hidden_room_entry_zone_contains(world_position, room_coord, neighbor):
				return {
					"from_room": room_coord,
					"to_room": neighbor,
				}
			var open_doorway: Vector2 = game.doorway_position(room_coord, neighbor)
			var hidden_doorway: Vector2 = game.doorway_position(neighbor, room_coord)
			if game.point_distance_to_segment(world_position, open_doorway, hidden_doorway) <= 28.0:
				return {
					"from_room": room_coord,
					"to_room": neighbor,
				}
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if game.rooms[room_coord]["opened"] or not game.room_rect(room_coord).has_point(world_position):
			continue
		var opened_neighbors: Array[Vector2i] = []
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if game.rooms[neighbor]["opened"]:
				opened_neighbors.append(neighbor)
		if opened_neighbors.is_empty():
			continue
		var best_from_room: Vector2i = opened_neighbors[0]
		var best_distance: float = game.doorway_position(best_from_room, room_coord).distance_to(world_position)
		for opened_neighbor in opened_neighbors:
			var doorway_distance: float = game.doorway_position(opened_neighbor, room_coord).distance_to(world_position)
			if doorway_distance < best_distance:
				best_distance = doorway_distance
				best_from_room = opened_neighbor
		return {
			"from_room": best_from_room,
			"to_room": room_coord,
		}
	return {}

static func frontier_wall_target_at_position(game: Node, world_position: Vector2) -> Dictionary:
	var best_target: Dictionary = {}
	var best_distance: float = INF
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		var room_rect_value: Rect2 = game.room_rect(room_coord)
		var room_center_point: Vector2 = room_rect_value.get_center()
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if game.rooms[neighbor]["opened"]:
				continue
			var delta: Vector2i = neighbor - room_coord
			var doorway: Vector2 = game.doorway_position(room_coord, neighbor)
			var hit_distance: float = INF
			match delta:
				Vector2i.RIGHT:
					var within_x_right: bool = world_position.x >= room_rect_value.end.x - 38.0 and world_position.x <= room_rect_value.end.x + 42.0
					var within_y_right: bool = absf(world_position.y - doorway.y) <= maxf(room_rect_value.size.y * 0.32, 52.0)
					if within_x_right and within_y_right:
						hit_distance = absf(world_position.x - room_rect_value.end.x) + absf(world_position.y - doorway.y) * 0.25
				Vector2i.LEFT:
					var within_x_left: bool = world_position.x <= room_rect_value.position.x + 38.0 and world_position.x >= room_rect_value.position.x - 42.0
					var within_y_left: bool = absf(world_position.y - doorway.y) <= maxf(room_rect_value.size.y * 0.32, 52.0)
					if within_x_left and within_y_left:
						hit_distance = absf(world_position.x - room_rect_value.position.x) + absf(world_position.y - doorway.y) * 0.25
				Vector2i.DOWN:
					var within_y_down: bool = world_position.y >= room_rect_value.end.y - 38.0 and world_position.y <= room_rect_value.end.y + 42.0
					var within_x_down: bool = absf(world_position.x - doorway.x) <= maxf(room_rect_value.size.x * 0.32, 52.0)
					if within_y_down and within_x_down:
						hit_distance = absf(world_position.y - room_rect_value.end.y) + absf(world_position.x - doorway.x) * 0.25
				Vector2i.UP:
					var within_y_up: bool = world_position.y <= room_rect_value.position.y + 38.0 and world_position.y >= room_rect_value.position.y - 42.0
					var within_x_up: bool = absf(world_position.x - doorway.x) <= maxf(room_rect_value.size.x * 0.32, 52.0)
					if within_y_up and within_x_up:
						hit_distance = absf(world_position.y - room_rect_value.position.y) + absf(world_position.x - doorway.x) * 0.25
			if hit_distance >= INF:
				continue
			if room_center_point.distance_to(world_position) > maxf(room_rect_value.size.x, room_rect_value.size.y):
				continue
			if hit_distance < best_distance:
				best_distance = hit_distance
				best_target = {
					"from_room": room_coord,
					"to_room": neighbor,
				}
	return best_target

static func frontier_door_at_position(game: Node, world_position: Vector2) -> Dictionary:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if game.rooms[neighbor]["opened"]:
				continue
			var doorway: Vector2 = game.doorway_position(room_coord, neighbor)
			var stub_position: Vector2 = doorway + (game.room_center(neighbor) - game.room_center(room_coord)).normalized() * 12.0
			if stub_position.distance_to(world_position) <= game.FRONTIER_DOOR_RADIUS:
				return {
					"from_room": room_coord,
					"to_room": neighbor,
				}
	return {}

static func point_distance_to_segment(_game: Node, point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment: Vector2 = end - start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(start)
	var t: float = clampf((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest_point: Vector2 = start + segment * t
	return point.distance_to(closest_point)

static func hidden_room_entry_zone_contains(game: Node, world_position: Vector2, from_room: Vector2i, to_room: Vector2i) -> bool:
	var delta: Vector2i = to_room - from_room
	var direction: Vector2 = Vector2(float(delta.x), float(delta.y))
	if direction == Vector2.ZERO:
		return false
	direction = direction.normalized()
	var tangent: Vector2 = Vector2(-direction.y, direction.x)
	var doorway: Vector2 = game.doorway_position(from_room, to_room)
	var hidden_doorway: Vector2 = game.doorway_position(to_room, from_room)
	var corridor_depth: float = doorway.distance_to(hidden_doorway)
	var offset: Vector2 = world_position - doorway
	var forward_distance: float = offset.dot(direction)
	var lateral_distance: float = absf(offset.dot(tangent))
	var hidden_half: Vector2 = game.room_size_for(to_room) * 0.5
	var lateral_limit: float = hidden_half.y + 42.0 if delta.x != 0 else hidden_half.x + 42.0
	var forward_limit: float = corridor_depth + 126.0
	return forward_distance >= -18.0 and forward_distance <= forward_limit and lateral_distance <= lateral_limit

static func room_center(game: Node, room_coord: Vector2i) -> Vector2:
	if game.rooms.has(room_coord) and game.rooms[room_coord].has("center"):
		return Vector2(game.rooms[room_coord]["center"])
	var offset_x: float = (float(room_coord.x) - float(game.GRID_SIZE.x - 1) * 0.5) * game.ROOM_SPACING.x
	var offset_y: float = (float(room_coord.y) - float(game.GRID_SIZE.y - 1) * 0.5) * game.ROOM_SPACING.y
	return Vector2(offset_x, offset_y)

static func room_size_for(game: Node, room_coord: Vector2i) -> Vector2:
	return game.rooms[room_coord]["size"]

static func room_rect(game: Node, room_coord: Vector2i) -> Rect2:
	var room_size: Vector2 = game.room_size_for(room_coord)
	return Rect2(game.room_center(room_coord) - room_size * 0.5, room_size)

static func normalized_rect_to_room(game: Node, room_coord: Vector2i, normalized_rect: Rect2) -> Rect2:
	var rect: Rect2 = game.room_rect(room_coord)
	return Rect2(
		rect.position + Vector2(normalized_rect.position.x * rect.size.x, normalized_rect.position.y * rect.size.y),
		Vector2(normalized_rect.size.x * rect.size.x, normalized_rect.size.y * rect.size.y)
	)

static func normalized_point_to_room(game: Node, room_coord: Vector2i, normalized_point: Vector2) -> Vector2:
	var rect: Rect2 = game.room_rect(room_coord)
	return rect.position + Vector2(normalized_point.x * rect.size.x, normalized_point.y * rect.size.y)

static func room_layout_regions(game: Node, room_coord: Vector2i, key: String, inset: float = 0.0) -> Array:
	if not game.rooms.has(room_coord):
		return []
	var normalized_regions: Array = Array(game.rooms[room_coord].get(key, []))
	if normalized_regions.is_empty():
		var fallback_rect: Rect2 = game.room_rect(room_coord).grow(-maxf(inset, 26.0))
		return [fallback_rect]
	var regions: Array = []
	for rect_variant in normalized_regions:
		var world_rect: Rect2 = game.normalized_rect_to_room(room_coord, Rect2(rect_variant))
		if inset > 0.0:
			var inset_amount: float = minf(inset, minf(world_rect.size.x, world_rect.size.y) * 0.48)
			world_rect = world_rect.grow(-inset_amount)
		if world_rect.size.x <= 6.0 or world_rect.size.y <= 6.0:
			continue
		regions.append(world_rect)
	return regions

static func room_walkable_regions(game: Node, room_coord: Vector2i, inset: float = 4.0) -> Array:
	return game.room_layout_regions(room_coord, "walkable_regions", inset)

static func room_slot_regions(game: Node, room_coord: Vector2i, inset: float = 18.0) -> Array:
	return game.room_layout_regions(room_coord, "slot_regions", inset)

static func largest_region_rect(_game: Node, regions: Array) -> Rect2:
	if regions.is_empty():
		return Rect2()
	var largest_rect: Rect2 = Rect2(regions[0])
	var largest_area: float = largest_rect.size.x * largest_rect.size.y
	for region_variant in regions:
		var region_rect: Rect2 = Rect2(region_variant)
		var region_area: float = region_rect.size.x * region_rect.size.y
		if region_area > largest_area:
			largest_area = region_area
			largest_rect = region_rect
	return largest_rect

static func bounding_rect_for_regions(_game: Node, regions: Array) -> Rect2:
	if regions.is_empty():
		return Rect2()
	var bounds: Rect2 = Rect2(regions[0])
	var min_point: Vector2 = bounds.position
	var max_point: Vector2 = bounds.end
	for region_variant in regions:
		var region_rect: Rect2 = Rect2(region_variant)
		min_point.x = minf(min_point.x, region_rect.position.x)
		min_point.y = minf(min_point.y, region_rect.position.y)
		max_point.x = maxf(max_point.x, region_rect.end.x)
		max_point.y = maxf(max_point.y, region_rect.end.y)
	return Rect2(min_point, max_point - min_point)

static func room_slot_anchor_rect(game: Node, room_coord: Vector2i) -> Rect2:
	var slot_regions: Array = game.room_slot_regions(room_coord)
	if not slot_regions.is_empty():
		return game.bounding_rect_for_regions(slot_regions)
	var walkable_regions: Array = game.room_walkable_regions(room_coord)
	if not walkable_regions.is_empty():
		return game.largest_region_rect(walkable_regions)
	return game.room_rect(room_coord).grow(-26.0)

static func closest_point_in_rect(_game: Node, world_position: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clampf(world_position.x, rect.position.x, rect.end.x),
		clampf(world_position.y, rect.position.y, rect.end.y)
	)

static func room_walkable_contains_point(game: Node, room_coord: Vector2i, world_position: Vector2, inset: float = 4.0) -> bool:
	for region_variant in game.room_walkable_regions(room_coord, inset):
		if Rect2(region_variant).has_point(world_position):
			return true
	return false

static func room_walkable_center(game: Node, room_coord: Vector2i) -> Vector2:
	if not game.rooms.has(room_coord):
		return game.room_center(room_coord)
	var walkable_regions: Array = game.room_walkable_regions(room_coord)
	if walkable_regions.is_empty():
		return game.room_center(room_coord)
	var primary_rect: Rect2 = game.largest_region_rect(walkable_regions)
	return game.closest_point_in_rect(game.room_center(room_coord), primary_rect)

static func doorway_navigation_position(game: Node, from_room: Vector2i, to_room: Vector2i) -> Vector2:
	var threshold_position: Vector2 = game.doorway_position(from_room, to_room)
	var walkable_regions: Array = game.room_walkable_regions(from_room, 0.0)
	if walkable_regions.is_empty():
		return game.clamp_point_to_room(threshold_position, from_room)
	var walkable_bounds: Rect2 = game.bounding_rect_for_regions(walkable_regions)
	var delta: Vector2i = to_room - from_room
	var edge_padding: float = 10.0
	if delta.x < 0:
		return game.clamp_point_to_room(
			Vector2(
				walkable_bounds.position.x + edge_padding,
				clampf(threshold_position.y, walkable_bounds.position.y + edge_padding, walkable_bounds.end.y - edge_padding)
			),
			from_room
		)
	if delta.x > 0:
		return game.clamp_point_to_room(
			Vector2(
				walkable_bounds.end.x - edge_padding,
				clampf(threshold_position.y, walkable_bounds.position.y + edge_padding, walkable_bounds.end.y - edge_padding)
			),
			from_room
		)
	if delta.y < 0:
		return game.clamp_point_to_room(
			Vector2(
				clampf(threshold_position.x, walkable_bounds.position.x + edge_padding, walkable_bounds.end.x - edge_padding),
				walkable_bounds.position.y + edge_padding
			),
			from_room
		)
	if delta.y > 0:
		return game.clamp_point_to_room(
			Vector2(
				clampf(threshold_position.x, walkable_bounds.position.x + edge_padding, walkable_bounds.end.x - edge_padding),
				walkable_bounds.end.y - edge_padding
			),
			from_room
		)
	return game.clamp_point_to_room(threshold_position, from_room)

static func random_point_in_regions(game: Node, regions: Array) -> Vector2:
	if regions.is_empty():
		return Vector2.ZERO
	var total_area: float = 0.0
	for region_variant in regions:
		var region_rect: Rect2 = Rect2(region_variant)
		total_area += maxf(region_rect.size.x * region_rect.size.y, 1.0)
	var roll: float = game.rng.randf() * total_area
	for region_variant in regions:
		var candidate_rect: Rect2 = Rect2(region_variant)
		roll -= maxf(candidate_rect.size.x * candidate_rect.size.y, 1.0)
		if roll > 0.0:
			continue
		return Vector2(
			game.rng.randf_range(candidate_rect.position.x, candidate_rect.end.x),
			game.rng.randf_range(candidate_rect.position.y, candidate_rect.end.y)
		)
	var fallback_rect: Rect2 = Rect2(regions[regions.size() - 1])
	return fallback_rect.get_center()

static func random_walkable_point(game: Node, room_coord: Vector2i) -> Vector2:
	var walkable_regions: Array = game.room_walkable_regions(room_coord)
	if walkable_regions.is_empty():
		return game.clamp_point_to_room(game.room_center(room_coord), room_coord)
	return game.random_point_in_regions(walkable_regions)

static func walkable_region_index_for_point(game: Node, room_coord: Vector2i, world_position: Vector2, inset: float = 4.0) -> int:
	var walkable_regions: Array = game.room_walkable_regions(room_coord, inset)
	if walkable_regions.is_empty():
		return -1
	for region_index in range(walkable_regions.size()):
		if Rect2(walkable_regions[region_index]).has_point(world_position):
			return region_index
	var best_index: int = 0
	var best_distance_squared: float = INF
	for region_index in range(walkable_regions.size()):
		var candidate_point: Vector2 = game.closest_point_in_rect(world_position, Rect2(walkable_regions[region_index]))
		var distance_squared: float = candidate_point.distance_squared_to(world_position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_index = region_index
	return best_index

static func clear_enemy_room_navigation(_game: Node, enemy: Variant) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_meta("room_nav_waypoint"):
		enemy.remove_meta("room_nav_waypoint")
	if enemy.has_meta("room_nav_final"):
		enemy.remove_meta("room_nav_final")

static func enemy_room_navigation_destination(game: Node, enemy: Variant, room_coord: Vector2i, target_position: Vector2) -> Vector2:
	var clamped_target: Vector2 = game.clamp_point_to_room(target_position, room_coord)
	if enemy == null or not is_instance_valid(enemy):
		return clamped_target
	var walkable_regions: Array = game.room_walkable_regions(room_coord, 0.0)
	if walkable_regions.is_empty():
		return clamped_target
	var clamped_start: Vector2 = game.clamp_point_to_room(enemy.global_position, room_coord)
	var start_region_index: int = game.walkable_region_index_for_point(room_coord, clamped_start, 0.0)
	var target_region_index: int = game.walkable_region_index_for_point(room_coord, clamped_target, 0.0)
	if start_region_index < 0 or target_region_index < 0 or start_region_index == target_region_index:
		game.clear_enemy_room_navigation(enemy)
		return clamped_target
	var primary_region: Rect2 = game.largest_region_rect(walkable_regions)
	var start_in_primary: bool = primary_region.has_point(clamped_start)
	var target_in_primary: bool = primary_region.has_point(clamped_target)
	game.clear_enemy_room_navigation(enemy)
	if not start_in_primary:
		return game.closest_point_in_rect(clamped_start, primary_region)
	if not target_in_primary:
		return game.closest_point_in_rect(clamped_target, primary_region)
	return clamped_target

static func clamp_point_to_room(game: Node, world_position: Vector2, room_coord: Vector2i) -> Vector2:
	var walkable_regions: Array = game.room_walkable_regions(room_coord)
	if walkable_regions.is_empty():
		var padded_rect: Rect2 = game.room_rect(room_coord).grow(-26.0)
		return Vector2(
			clampf(world_position.x, padded_rect.position.x, padded_rect.end.x),
			clampf(world_position.y, padded_rect.position.y, padded_rect.end.y)
		)
	var nearest_point: Vector2 = game.room_walkable_center(room_coord)
	var nearest_distance_squared: float = INF
	for region_variant in walkable_regions:
		var candidate_point: Vector2 = game.closest_point_in_rect(world_position, Rect2(region_variant))
		var distance_squared: float = candidate_point.distance_squared_to(world_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_point = candidate_point
	return nearest_point

static func doorway_position(game: Node, from_room: Vector2i, to_room: Vector2i) -> Vector2:
	var delta: Vector2i = to_room - from_room
	if game.rooms.has(from_room):
		var door_positions: Dictionary = Dictionary(game.rooms[from_room].get("door_positions_normalized", {}))
		var direction_key: String = game.cardinal_dir_key(delta)
		if not direction_key.is_empty() and door_positions.has(direction_key):
			return game.normalized_point_to_room(from_room, Vector2(door_positions[direction_key]))
	var room_half: Vector2 = game.room_size_for(from_room) * 0.5
	var center: Vector2 = game.room_center(from_room)
	if delta.x != 0:
		return center + Vector2(float(delta.x) * room_half.x, 0.0)
	return center + Vector2(0.0, float(delta.y) * room_half.y)

static func major_slot_position(game: Node, room_coord: Vector2i) -> Vector2:
	if game.rooms.has(room_coord) and game.rooms[room_coord].has("major_slot_normalized"):
		return game.normalized_point_to_room(room_coord, Vector2(game.rooms[room_coord]["major_slot_normalized"]))
	var rect: Rect2 = game.room_slot_anchor_rect(room_coord)
	return rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.23)

static func effective_minor_slot_count(game: Node, room_coord: Vector2i) -> int:
	if not game.rooms.has(room_coord):
		return 0
	game.rooms[room_coord] = game.normalize_runtime_room_slot_capacity(room_coord, Dictionary(game.rooms[room_coord]))
	var room: Dictionary = game.rooms[room_coord]
	var configured_count: int = maxi(int(room.get("minor_slots", 0)), 0)
	var normalized_positions: Array = Array(room.get("minor_slot_positions_normalized", []))
	if normalized_positions.is_empty():
		return configured_count
	return maxi(configured_count, normalized_positions.size())

static func minor_slot_positions(game: Node, room_coord: Vector2i) -> Array:
	if game.rooms.has(room_coord):
		var normalized_positions: Array = Array(game.rooms[room_coord].get("minor_slot_positions_normalized", []))
		if not normalized_positions.is_empty():
			var resolved_positions: Array = []
			var desired_count: int = mini(game.effective_minor_slot_count(room_coord), normalized_positions.size())
			for index in range(desired_count):
				resolved_positions.append(game.normalized_point_to_room(room_coord, Vector2(normalized_positions[index])))
			return resolved_positions
	var rect: Rect2 = game.room_slot_anchor_rect(room_coord)
	var count: int = game.effective_minor_slot_count(room_coord)
	var offsets: Array[Vector2] = []
	match count:
		0:
			offsets = []
		2:
			offsets = [
				Vector2(-0.24, 0.18),
				Vector2(0.24, 0.18),
			]
		3:
			offsets = [
				Vector2(-0.28, 0.02),
				Vector2(0.0, 0.22),
				Vector2(0.28, 0.02),
			]
		5:
			offsets = [
				Vector2(-0.30, -0.14),
				Vector2(0.0, -0.20),
				Vector2(0.30, -0.14),
				Vector2(-0.18, 0.18),
				Vector2(0.18, 0.18),
			]
		7:
			offsets = [
				Vector2(-0.34, -0.18),
				Vector2(0.0, -0.18),
				Vector2(0.34, -0.18),
				Vector2(-0.34, 0.06),
				Vector2(0.0, 0.06),
				Vector2(0.34, 0.06),
				Vector2(0.0, 0.30),
			]
		_:
			offsets = [
				Vector2(-0.26, -0.08),
				Vector2(0.26, -0.08),
				Vector2(-0.26, 0.22),
				Vector2(0.26, 0.22),
			]
	var slot_positions: Array = []
	for offset in offsets:
		slot_positions.append(rect.get_center() + Vector2(offset.x * rect.size.x, offset.y * rect.size.y))
	return slot_positions
