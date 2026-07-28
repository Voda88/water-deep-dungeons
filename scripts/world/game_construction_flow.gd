extends RefCounted

static func can_build_or_repair_turret(game: Node, room_coord: Vector2i) -> bool:
	if not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	if not room["opened"] or room_coord == game.crystal_room:
		return false
	for slot_index in range(game.effective_minor_slot_count(room_coord)):
		if game.minor_module_index_for_slot(room_coord, slot_index) < 0 and game.pending_minor_construction_for_slot(room_coord, slot_index).is_empty():
			return true
	return false

static func any_room_can_build_or_repair_turret(game: Node) -> bool:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if can_build_or_repair_turret(game, room_coord):
			return true
	return false

static func turret_button_text(game: Node, room_coord: Vector2i) -> String:
	var ballista_level: int = clampi(game.minor_module_level(game.MINOR_MODULE_TURRET), 1, 4)
	var ballista_label: String = "Crossbow %s" % game.module_level_roman(ballista_level)
	if not game.rooms.has(room_coord):
		return ballista_label
	var room: Dictionary = game.rooms[room_coord]
	if not room["lit"]:
		return "%s Auto-Lights" % ballista_label
	if room["minor_modules"].size() < game.effective_minor_slot_count(room_coord):
		return "Build %s (3)" % ballista_label
	return "Minor Slots Full"

static func can_build_or_repair_major(game: Node, room_coord: Vector2i, module_type: String) -> bool:
	if not game.rooms.has(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	if int(room["major_slots"]) <= 0:
		return false
	if bool(room.get("research_crystal", false)):
		return false
	if not game.pending_major_construction_for_room(room_coord).is_empty():
		return false
	if room["major_module_type"] == "":
		return true
	return String(room["major_module_type"]) == module_type and not bool(room.get("major_under_construction", false)) and float(room["major_health"]) < game.MAJOR_MODULE_MAX_HEALTH

static func any_room_can_build_or_repair_major(game: Node, module_type: String) -> bool:
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if game.can_open_build_for_room(room_coord) and can_build_or_repair_major(game, room_coord, module_type):
			return true
	return false

static func major_button_text(game: Node, room_coord: Vector2i, module_type: String, label: String) -> String:
	if not game.rooms.has(room_coord):
		return "Build %s" % label
	var room: Dictionary = game.rooms[room_coord]
	if int(room["major_slots"]) <= 0:
		return "No %s Slot" % label
	if room["major_module_type"] == "":
		return "Build %s" % label
	if String(room["major_module_type"]) == module_type and float(room["major_health"]) < game.MAJOR_MODULE_MAX_HEALTH:
		return "Repair %s" % label
	if String(room["major_module_type"]) == module_type:
		return "%s Online" % label
	return "%s Locked" % label

static func minor_slot_at_position(game: Node, room_coord: Vector2i, world_position: Vector2) -> int:
	var slot_positions: Array = game.minor_slot_positions(room_coord)
	for slot_index in range(slot_positions.size()):
		if slot_positions[slot_index].distance_to(world_position) <= 28.0:
			return slot_index
	return -1

static func major_slot_contains_point(game: Node, room_coord: Vector2i, world_position: Vector2) -> bool:
	return game.major_slot_position(room_coord).distance_to(world_position) <= 28.0

static func minor_module_index_for_slot(game: Node, room_coord: Vector2i, slot_index: int) -> int:
	if not game.rooms.has(room_coord):
		return -1
	for module_index in range(game.rooms[room_coord]["minor_modules"].size()):
		var module_data: Dictionary = game.rooms[room_coord]["minor_modules"][module_index]
		if int(module_data.get("slot_index", -1)) == slot_index:
			return module_index
	return -1

static func pending_minor_construction_for_slot(game: Node, room_coord: Vector2i, slot_index: int) -> Dictionary:
	for construction_variant in game.pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", game.INVALID_ROOM) == room_coord and not bool(construction.get("is_major", false)) and int(construction.get("slot_index", -1)) == slot_index:
			return construction
	return {}

static func pending_major_construction_for_room(game: Node, room_coord: Vector2i) -> Dictionary:
	for construction_variant in game.pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", game.INVALID_ROOM) == room_coord and bool(construction.get("is_major", false)):
			return construction
	return {}

static func cancel_pending_minor_construction(game: Node, room_coord: Vector2i, slot_index: int) -> void:
	if slot_index < 0:
		return
	var active_constructions: Array = []
	for construction_variant in game.pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", game.INVALID_ROOM) == room_coord and not bool(construction.get("is_major", false)) and int(construction.get("slot_index", -1)) == slot_index:
			continue
		active_constructions.append(construction)
	game.pending_room_constructions = active_constructions

static func cancel_pending_major_construction(game: Node, room_coord: Vector2i) -> void:
	var active_constructions: Array = []
	for construction_variant in game.pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", game.INVALID_ROOM) == room_coord and bool(construction.get("is_major", false)):
			continue
		active_constructions.append(construction)
	game.pending_room_constructions = active_constructions

static func should_highlight_minor_slot(game: Node, room_coord: Vector2i, slot_index: int) -> bool:
	if not game.is_minor_module_type(game.pending_build_type) or not game.can_manage_modules(room_coord):
		return false
	var module_index: int = game.minor_module_index_for_slot(room_coord, slot_index)
	if module_index < 0:
		return true
	return float(game.rooms[room_coord]["minor_modules"][module_index]["health"]) < game.MINOR_MODULE_MAX_HEALTH

static func should_highlight_major_slot(game: Node, room_coord: Vector2i) -> bool:
	if not game.can_manage_modules(room_coord):
		return false
	if game.pending_build_type != game.MAJOR_MODULE_FOOD and game.pending_build_type != game.MAJOR_MODULE_SCIENCE and game.pending_build_type != game.MAJOR_MODULE_INDUSTRY:
		return false
	return can_build_or_repair_major(game, room_coord, game.pending_build_type)

static func should_show_room_slot_guides(game: Node, room_coord: Vector2i) -> bool:
	if not game.can_open_build_for_room(room_coord):
		return false
	var room: Dictionary = game.rooms[room_coord]
	return game.effective_minor_slot_count(room_coord) > 0 or int(room.get("major_slots", 0)) > 0

static func is_valid_build_target_tap(game: Node, world_position: Vector2) -> bool:
	if game.pending_build_type == "":
		return false
	var tapped_room: Vector2i = game.room_at_world_position(world_position)
	if tapped_room == game.INVALID_ROOM or not game.can_manage_modules(tapped_room):
		return false
	if game.is_minor_module_type(game.pending_build_type):
		return minor_slot_at_position(game, tapped_room, world_position) >= 0
	return major_slot_contains_point(game, tapped_room, world_position)

static func room_has_pending_construction(game: Node, room_coord: Vector2i) -> bool:
	for construction_variant in game.pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", game.INVALID_ROOM) == room_coord:
			return true
	return false

static func preferred_turret_slot(game: Node, room_coord: Vector2i) -> int:
	if not game.rooms.has(room_coord):
		return -1
	for slot_index in range(game.effective_minor_slot_count(room_coord)):
		if game.minor_module_index_for_slot(room_coord, slot_index) < 0 and game.pending_minor_construction_for_slot(room_coord, slot_index).is_empty():
			return slot_index
	return -1

static func queue_room_construction(game: Node, room_coord: Vector2i, module_type: String) -> bool:
	module_type = game.canonical_minor_module_type(module_type)
	if not game.can_open_build_for_room(room_coord):
		game.status_message = "%s cannot build modules." % game.room_title(room_coord)
		game.update_hud()
		game.queue_redraw()
		return false
	if not game.ensure_room_lit_for_build(room_coord):
		game.update_hud()
		game.queue_redraw()
		return false
	var room: Dictionary = game.rooms[room_coord]
	var is_major: bool = game.is_major_module_type(module_type)
	var industry_cost: int = 0
	var repairing: bool = false
	var slot_index: int = -1
	if is_major:
		if int(room["major_slots"]) <= 0:
			game.status_message = "%s has no major module slot." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
			return false
		if game.room_has_research_crystal(room_coord):
			game.status_message = "Major slot occupied by research crystal in %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
			return false
		if not game.pending_major_construction_for_room(room_coord).is_empty():
			game.status_message = "Major construction is already underway in %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
			return false
		if room["major_module_type"] == "":
			industry_cost = game.MAJOR_MODULE_COST
		elif String(room["major_module_type"]) == module_type and float(room["major_health"]) < game.MAJOR_MODULE_MAX_HEALTH:
			industry_cost = 3
			repairing = true
		else:
			game.status_message = "That major slot is already occupied."
			game.update_hud()
			game.queue_redraw()
			return false
	else:
		if not game.minor_module_unlocked(module_type):
			game.status_message = "%s is not researched yet." % game.build_type_label(module_type)
			game.update_hud()
			game.queue_redraw()
			return false
		slot_index = preferred_turret_slot(game, room_coord)
		if slot_index < 0:
			game.status_message = "No minor slot is available in %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
			return false
		industry_cost = game.minor_module_cost(module_type)
	if game.industry < industry_cost:
		game.status_message = "Not enough materials for %s." % game.build_type_label(module_type).to_lower()
		game.update_hud()
		game.queue_redraw()
		return false
	game.industry -= industry_cost
	var duration: float = game.BUILD_DURATION_WAVE if game.wave_in_progress() else game.BUILD_DURATION_CALM
	var start_health: float = 1.0
	var target_health: float = game.MAJOR_MODULE_MAX_HEALTH if is_major else game.MINOR_MODULE_MAX_HEALTH
	if is_major:
		if repairing:
			start_health = float(room["major_health"])
		else:
			room["major_module_type"] = module_type
			room["major_health"] = start_health
		room["major_under_construction"] = true
	else:
		room["minor_modules"].append({
			"type": module_type,
			"slot_index": slot_index,
			"health": start_health,
			"cooldown": 0.2,
			"under_construction": true,
		})
	game.rooms[room_coord] = room
	game.pending_room_constructions.append({
		"room": room_coord,
		"module_type": module_type,
		"is_major": is_major,
		"slot_index": slot_index,
		"repairing": repairing,
		"start_health": start_health,
		"target_health": target_health,
		"duration": duration,
		"timer_left": duration,
	})
	game.status_message = "%s started in %s." % [("Repair" if repairing else "Build"), game.room_title(room_coord)]
	game.update_hud()
	game.queue_redraw()
	return true

static func advance_room_constructions(game: Node, delta: float) -> void:
	var active_constructions: Array = []
	var completed_any: bool = false
	for construction_variant in game.pending_room_constructions:
		var construction: Dictionary = construction_variant
		construction["timer_left"] = maxf(float(construction.get("timer_left", 0.0)) - delta, 0.0)
		apply_construction_progress(game, construction)
		if float(construction["timer_left"]) <= 0.0:
			finish_room_construction(game, construction)
			completed_any = true
		else:
			active_constructions.append(construction)
	game.pending_room_constructions = active_constructions
	if completed_any:
		game.update_hud()
		game.queue_redraw()

static func apply_construction_progress(game: Node, construction: Dictionary) -> void:
	var room_coord: Vector2i = construction.get("room", game.INVALID_ROOM)
	if not game.rooms.has(room_coord):
		return
	var room: Dictionary = game.rooms[room_coord]
	var duration: float = maxf(float(construction.get("duration", 1.0)), 0.001)
	var timer_left: float = float(construction.get("timer_left", 0.0))
	var progress: float = 1.0 - (timer_left / duration)
	var start_health: float = float(construction.get("start_health", 1.0))
	var target_health: float = float(construction.get("target_health", 1.0))
	var next_health: float = lerpf(start_health, target_health, progress)
	if bool(construction.get("is_major", false)):
		room["major_health"] = next_health
		game.rooms[room_coord] = room
		return
	var slot_index: int = int(construction.get("slot_index", -1))
	var module_index: int = game.minor_module_index_for_slot(room_coord, slot_index)
	if module_index >= 0:
		var module_data: Dictionary = Dictionary(room["minor_modules"][module_index])
		module_data["health"] = next_health
		room["minor_modules"][module_index] = module_data
		game.rooms[room_coord] = room

static func finish_room_construction(game: Node, construction: Dictionary) -> void:
	var room_coord: Vector2i = construction.get("room", game.INVALID_ROOM)
	if not game.rooms.has(room_coord):
		return
	var room: Dictionary = game.rooms[room_coord]
	var module_type: String = String(construction.get("module_type", ""))
	if bool(construction.get("is_major", false)):
		room["major_health"] = game.MAJOR_MODULE_MAX_HEALTH
		room["major_under_construction"] = false
		game.rooms[room_coord] = room
		game.status_message = "%s completed in %s." % [game.build_type_label(module_type), game.room_title(room_coord)]
		return
	var slot_index: int = int(construction.get("slot_index", -1))
	if slot_index < 0:
		return
	var module_index: int = game.minor_module_index_for_slot(room_coord, slot_index)
	if module_index >= 0:
		var module_data: Dictionary = Dictionary(room["minor_modules"][module_index])
		module_data["health"] = game.MINOR_MODULE_MAX_HEALTH
		module_data["under_construction"] = false
		room["minor_modules"][module_index] = module_data
	game.rooms[room_coord] = room
	game.status_message = "%s completed in %s." % [game.build_type_label(module_type), game.room_title(room_coord)]

static func build_menu_title_text(game: Node) -> String:
	if game.pending_build_type == "":
		return "Build Menu"
	return "%s: tap a room" % game.build_type_label(game.pending_build_type)

static func clear_build_mode(game: Node) -> void:
	game.pending_build_type = ""

static func select_build_mode(game: Node, module_type: String) -> void:
	game.build_menu_open = true
	game.pending_build_type = module_type
	game.status_message = "%s selected. Tap the room you want to build in." % game.build_type_label(module_type)
	game.update_hud()
	game.queue_redraw()

static func handle_build_tap(game: Node, world_position: Vector2) -> bool:
	var tapped_room: Vector2i = game.room_at_world_position(world_position)
	if tapped_room == game.INVALID_ROOM:
		game.status_message = "Tap a room to place %s." % game.build_type_label(game.pending_build_type).to_lower()
		return true
	game.selected_room = tapped_room
	game.request_room_construction(tapped_room, game.pending_build_type)
	return true
