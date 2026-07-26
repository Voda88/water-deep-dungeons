extends RefCounted

static func issue_enemy_steps(_game: Node, enemy: Variant, steps: Array) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	enemy.move_steps.clear()
	for step in steps:
		enemy.move_steps.append(step)

static func enemy_move_plan_matches(game: Node, enemy: Variant, target_room: Vector2i, target_position: Vector2) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.move_steps.is_empty():
		return false
	var final_step: Dictionary = enemy.move_steps[enemy.move_steps.size() - 1]
	if Vector2i(final_step.get("room", game.INVALID_ROOM)) != target_room:
		return false
	var planned_position: Vector2 = Vector2(final_step.get("position", Vector2.INF))
	var desired_position: Vector2 = game.clamp_point_to_room(target_position, target_room)
	return planned_position != Vector2.INF and planned_position.distance_squared_to(desired_position) <= 196.0

static func issue_hero_steps(_game: Node, hero: Variant, steps: Array) -> void:
	hero.move_steps.clear()
	hero.player_command_locked = not steps.is_empty()
	for step in steps:
		hero.move_steps.append(step)

static func active_hero_room_for_commands(game: Node, hero: Variant) -> Vector2i:
	if hero.pending_room == game.HERO_INVALID_ROOM:
		return hero.current_room
	var current_distance: float = hero.global_position.distance_to(game.room_center(hero.current_room))
	var pending_distance: float = hero.global_position.distance_to(game.room_center(hero.pending_room))
	if pending_distance + 24.0 < current_distance:
		return hero.pending_room
	return hero.current_room

static func interrupt_hero_orders(game: Node, hero: Variant) -> Vector2i:
	var command_room: Vector2i = active_hero_room_for_commands(game, hero)
	game.clear_pending_room_loot_request(hero.hero_index)
	game.clear_pending_room_action_request(hero.hero_index)
	hero.move_steps.clear()
	hero.player_command_locked = false
	game.opening_heroes.erase(hero)
	if game.opening_hero == hero:
		game.opening_hero = game.opening_heroes[0] if not game.opening_heroes.is_empty() else null
	if game.opening_room != game.INVALID_ROOM and game.opening_heroes.is_empty():
		game.opening_room = game.INVALID_ROOM
		game.opening_origin_room = game.INVALID_ROOM
		game.opening_hero = null
		game.opening_timer_left = 0.0
	hero.pending_open_room = game.HERO_INVALID_ROOM
	hero.pending_open_origin_room = game.HERO_INVALID_ROOM
	hero.pending_room = game.HERO_INVALID_ROOM
	hero.current_room = command_room
	hero.set_destination(hero.global_position)
	return command_room

static func hero_has_locked_player_command(game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if bool(hero.player_command_locked):
		return true
	if game.pending_room_action_requests.has(hero.hero_index) or game.pending_room_loot_requests.has(hero.hero_index):
		return true
	if hero.pending_room != game.HERO_INVALID_ROOM or hero.pending_open_room != game.HERO_INVALID_ROOM or not hero.move_steps.is_empty():
		return true
	return game.opening_hero == hero or game.opening_heroes.has(hero)

static func release_finished_player_command(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero) or not bool(hero.player_command_locked):
		return
	if game.pending_room_action_requests.has(hero.hero_index) or game.pending_room_loot_requests.has(hero.hero_index):
		return
	if hero.pending_room != game.HERO_INVALID_ROOM or hero.pending_open_room != game.HERO_INVALID_ROOM or not hero.move_steps.is_empty():
		return
	if game.opening_hero == hero or game.opening_heroes.has(hero):
		return
	if not hero.is_idle():
		return
	hero.player_command_locked = false

static func pause_autonomous_heroes_for_hand_drag(game: Node) -> void:
	for hero in game.heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		if hero_has_locked_player_command(game, hero):
			continue
		hero.set_destination(hero.global_position)

static func make_hero_step(_game: Node, room_coord: Vector2i, world_position: Vector2) -> Dictionary:
	return {
		"room": room_coord,
		"position": world_position,
	}

static func room_nav_fallback_points(game: Node, room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> Array:
	var clamped_start: Vector2 = game.clamp_point_to_room(start_position, room_coord)
	var clamped_target: Vector2 = game.clamp_point_to_room(target_position, room_coord)
	var walkable_regions: Array = game.room_walkable_regions(room_coord, 0.0)
	if walkable_regions.is_empty():
		return [clamped_target]
	var start_region_index: int = game.walkable_region_index_for_point(room_coord, clamped_start, 0.0)
	var target_region_index: int = game.walkable_region_index_for_point(room_coord, clamped_target, 0.0)
	if start_region_index < 0 or target_region_index < 0 or start_region_index == target_region_index:
		return [clamped_target]
	var primary_region: Rect2 = game.largest_region_rect(walkable_regions)
	var points: Array = []
	if not primary_region.has_point(clamped_start):
		points.append(game.closest_point_in_rect(clamped_start, primary_region))
	if not primary_region.has_point(clamped_target):
		var bridge_target: Vector2 = game.closest_point_in_rect(clamped_target, primary_region)
		if points.is_empty() or Vector2(points[points.size() - 1]).distance_squared_to(bridge_target) > 16.0:
			points.append(bridge_target)
	if points.is_empty() or Vector2(points[points.size() - 1]).distance_squared_to(clamped_target) > 16.0:
		points.append(clamped_target)
	return points

static func room_nav_data(game: Node, room_coord: Vector2i) -> Dictionary:
	if game.room_nav_cache.has(room_coord):
		return game.room_nav_cache[room_coord]
	var walkable_regions: Array = game.room_walkable_regions(room_coord, 0.0)
	if walkable_regions.is_empty():
		game.room_nav_cache[room_coord] = {}
		return {}
	var bounds: Rect2 = game.bounding_rect_for_regions(walkable_regions).grow(game.ROOM_NAV_CELL_SIZE)
	var min_cell: Vector2i = Vector2i(
		int(floor(bounds.position.x / game.ROOM_NAV_CELL_SIZE)),
		int(floor(bounds.position.y / game.ROOM_NAV_CELL_SIZE))
	)
	var max_cell: Vector2i = Vector2i(
		int(ceil(bounds.end.x / game.ROOM_NAV_CELL_SIZE)),
		int(ceil(bounds.end.y / game.ROOM_NAV_CELL_SIZE))
	)
	var grid_size: Vector2i = Vector2i.ONE + (max_cell - min_cell)
	var astar: AStarGrid2D = AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, grid_size)
	astar.cell_size = Vector2.ONE * game.ROOM_NAV_CELL_SIZE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	var walkable_cells: Array = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var local_cell: Vector2i = Vector2i(x, y)
			var world_rect: Rect2 = Rect2(Vector2(min_cell + local_cell) * game.ROOM_NAV_CELL_SIZE, Vector2.ONE * game.ROOM_NAV_CELL_SIZE)
			var is_walkable: bool = game.room_walkable_contains_point(room_coord, world_rect.get_center(), game.ROOM_NAV_WALKABLE_MARGIN)
			astar.set_point_solid(local_cell, not is_walkable)
			if is_walkable:
				walkable_cells.append(local_cell)
	var nav_data_value: Dictionary = {
		"astar": astar,
		"origin_cell": min_cell,
		"grid_size": grid_size,
		"walkable_cells": walkable_cells,
	}
	game.room_nav_cache[room_coord] = nav_data_value
	return nav_data_value

static func room_nav_cell_rect(game: Node, nav_data: Dictionary, local_cell: Vector2i) -> Rect2:
	var origin_cell: Vector2i = nav_data.get("origin_cell", Vector2i.ZERO)
	return Rect2(Vector2(origin_cell + local_cell) * game.ROOM_NAV_CELL_SIZE, Vector2.ONE * game.ROOM_NAV_CELL_SIZE)

static func room_nav_local_cell_for_world(game: Node, nav_data: Dictionary, world_position: Vector2) -> Vector2i:
	var origin_cell: Vector2i = nav_data.get("origin_cell", Vector2i.ZERO)
	var world_cell: Vector2i = Vector2i(
		int(floor(world_position.x / game.ROOM_NAV_CELL_SIZE)),
		int(floor(world_position.y / game.ROOM_NAV_CELL_SIZE))
	)
	return world_cell - origin_cell

static func room_nav_is_local_cell_in_bounds(_game: Node, nav_data: Dictionary, local_cell: Vector2i) -> bool:
	var grid_size: Vector2i = nav_data.get("grid_size", Vector2i.ZERO)
	return Rect2i(Vector2i.ZERO, grid_size).has_point(local_cell)

static func nearest_walkable_room_nav_cell(game: Node, nav_data: Dictionary, world_position: Vector2) -> Vector2i:
	if nav_data.is_empty():
		return Vector2i(-1, -1)
	var astar: AStarGrid2D = nav_data.get("astar", null)
	if astar == null:
		return Vector2i(-1, -1)
	var local_cell: Vector2i = room_nav_local_cell_for_world(game, nav_data, world_position)
	if room_nav_is_local_cell_in_bounds(game, nav_data, local_cell) and not astar.is_point_solid(local_cell):
		return local_cell
	var walkable_cells: Array = nav_data.get("walkable_cells", [])
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_distance_squared: float = INF
	for cell_variant in walkable_cells:
		var candidate_cell: Vector2i = cell_variant
		var candidate_center: Vector2 = room_nav_cell_rect(game, nav_data, candidate_cell).get_center()
		var distance_squared: float = candidate_center.distance_squared_to(world_position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_cell = candidate_cell
	return best_cell

static func room_nav_point_for_cell(game: Node, nav_data: Dictionary, local_cell: Vector2i, preferred_position: Vector2) -> Vector2:
	return game.closest_point_in_rect(preferred_position, room_nav_cell_rect(game, nav_data, local_cell))

static func room_nav_segment_is_walkable(game: Node, room_coord: Vector2i, start_position: Vector2, end_position: Vector2) -> bool:
	var distance: float = start_position.distance_to(end_position)
	if distance <= 1.0:
		return game.room_walkable_contains_point(room_coord, end_position, game.ROOM_NAV_WALKABLE_MARGIN)
	var sample_count: int = maxi(int(ceil(distance / maxf(game.ROOM_NAV_CELL_SIZE * 0.45, 4.0))), 1)
	for sample_index in range(sample_count + 1):
		var t: float = float(sample_index) / float(sample_count)
		var sample_point: Vector2 = start_position.lerp(end_position, t)
		if not game.room_walkable_contains_point(room_coord, sample_point, game.ROOM_NAV_WALKABLE_MARGIN):
			return false
	return true

static func smooth_room_navigation_points(game: Node, room_coord: Vector2i, points: Array) -> Array:
	if points.size() <= 2:
		return points.duplicate()
	var smoothed: Array = []
	var anchor_point: Vector2 = points[0]
	var next_index: int = 1
	while next_index < points.size():
		var furthest_index: int = next_index
		for test_index in range(next_index + 1, points.size()):
			if not room_nav_segment_is_walkable(game, room_coord, anchor_point, Vector2(points[test_index])):
				break
			furthest_index = test_index
		var chosen_point: Vector2 = points[furthest_index]
		smoothed.append(chosen_point)
		anchor_point = chosen_point
		next_index = furthest_index + 1
	return smoothed

static func simplify_room_navigation_points(_game: Node, points: Array) -> Array:
	if points.size() <= 2:
		return points.duplicate()
	var simplified: Array = [points[0]]
	var previous_direction: Vector2 = Vector2.ZERO
	for index in range(1, points.size()):
		var current_point: Vector2 = points[index]
		var previous_point: Vector2 = simplified[simplified.size() - 1]
		var direction: Vector2 = (current_point - previous_point).normalized()
		if index < points.size() - 1 and previous_direction != Vector2.ZERO and absf(direction.dot(previous_direction)) > 0.995:
			simplified[simplified.size() - 1] = current_point
		else:
			simplified.append(current_point)
		previous_direction = direction
	return simplified

static func room_navigation_points(game: Node, room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> Array:
	var clamped_start: Vector2 = game.clamp_point_to_room(start_position, room_coord)
	var clamped_target: Vector2 = game.clamp_point_to_room(target_position, room_coord)
	if clamped_start.distance_squared_to(clamped_target) <= 16.0:
		return [clamped_target]
	var nav_data: Dictionary = room_nav_data(game, room_coord)
	if nav_data.is_empty():
		return room_nav_fallback_points(game, room_coord, clamped_start, clamped_target)
	var astar: AStarGrid2D = nav_data.get("astar", null)
	if astar == null:
		return room_nav_fallback_points(game, room_coord, clamped_start, clamped_target)
	var start_cell: Vector2i = nearest_walkable_room_nav_cell(game, nav_data, clamped_start)
	var target_cell: Vector2i = nearest_walkable_room_nav_cell(game, nav_data, clamped_target)
	if start_cell.x < 0 or target_cell.x < 0:
		return room_nav_fallback_points(game, room_coord, clamped_start, clamped_target)
	if start_cell == target_cell:
		return [clamped_target]
	var cell_path: Array = astar.get_id_path(start_cell, target_cell)
	if cell_path.is_empty():
		return room_nav_fallback_points(game, room_coord, clamped_start, clamped_target)
	var raw_points: Array = [clamped_start]
	for path_index in range(1, cell_path.size() - 1):
		var local_cell: Vector2i = cell_path[path_index]
		raw_points.append(room_nav_cell_rect(game, nav_data, local_cell).get_center())
	raw_points.append(clamped_target)
	var nav_points: Array = smooth_room_navigation_points(game, room_coord, raw_points)
	if nav_points.is_empty() or Vector2(nav_points[nav_points.size() - 1]).distance_squared_to(clamped_target) > 4.0:
		nav_points.append(clamped_target)
	return simplify_room_navigation_points(game, nav_points)

static func append_room_navigation_steps(game: Node, steps: Array, room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> void:
	for nav_point_variant in room_navigation_points(game, room_coord, start_position, target_position):
		var nav_point: Vector2 = nav_point_variant
		if not steps.is_empty():
			var previous_step: Dictionary = steps[steps.size() - 1]
			if Vector2i(previous_step.get("room", game.INVALID_ROOM)) == room_coord and Vector2(previous_step.get("position", Vector2.INF)).distance_squared_to(nav_point) <= 4.0:
				continue
		steps.append(make_hero_step(game, room_coord, nav_point))

static func build_steps_for_path(game: Node, path: Array[Vector2i], start_position: Vector2, final_position: Vector2) -> Array:
	var steps: Array = []
	if path.is_empty():
		return steps
	var current_position: Vector2 = start_position
	if current_position == Vector2.INF:
		current_position = game.room_walkable_center(path[0])
	if path.size() == 1:
		append_room_navigation_steps(game, steps, path[0], current_position, final_position)
		return steps
	for index in range(path.size() - 1):
		var current_room: Vector2i = path[index]
		var next_room: Vector2i = path[index + 1]
		var exit_position: Vector2 = game.doorway_navigation_position(current_room, next_room)
		append_room_navigation_steps(game, steps, current_room, current_position, exit_position)
		var entry_position: Vector2 = game.doorway_navigation_position(next_room, current_room)
		steps.append(make_hero_step(game, next_room, entry_position))
		current_position = entry_position
	var destination_room: Vector2i = path[path.size() - 1]
	append_room_navigation_steps(game, steps, destination_room, current_position, final_position)
	return steps

static func advance_hero_movement(game: Node) -> void:
	game.update_selected_hero_flags()
	for hero in game.heroes:
		if not is_instance_valid(hero):
			continue
		if game.try_execute_pending_room_action_request(hero):
			continue
		if game.try_open_pending_room_loot_request(hero):
			continue
		if hero.pending_room != game.HERO_INVALID_ROOM:
			if hero.is_idle():
				hero.current_room = hero.pending_room
				hero.pending_room = game.HERO_INVALID_ROOM
				if hero == game.selected_hero():
					game.selected_room = hero.current_room
			else:
				continue
		if game.opening_room == game.INVALID_ROOM and hero.pending_open_room != game.HERO_INVALID_ROOM and hero.is_idle() and hero.move_steps.is_empty():
			var breach_room: Vector2i = hero.pending_open_room
			var from_room: Vector2i = hero.pending_open_origin_room
			hero.pending_open_room = game.HERO_INVALID_ROOM
			hero.pending_open_origin_room = game.HERO_INVALID_ROOM
			game.opening_hero = hero
			game.start_room_opening(breach_room, from_room)
			continue
		if game.opening_room != game.INVALID_ROOM and hero.pending_open_room == game.opening_room and hero.pending_open_origin_room == game.opening_origin_room and hero.is_idle() and hero.move_steps.is_empty():
			hero.pending_open_room = game.HERO_INVALID_ROOM
			hero.pending_open_origin_room = game.HERO_INVALID_ROOM
			if not game.opening_heroes.has(hero):
				game.opening_heroes.append(hero)
			continue
		if hero.move_steps.is_empty() or not hero.is_idle():
			continue
		var next_step: Dictionary = hero.move_steps[0]
		hero.move_steps.remove_at(0)
		var next_room: Vector2i = next_step["room"]
		var next_position: Vector2 = next_step["position"]
		if next_room != hero.current_room:
			hero.pending_room = next_room
		hero.set_destination(next_position)
	for hero in game.heroes:
		if is_instance_valid(hero):
			release_finished_player_command(game, hero)
	game.refresh_room_lighting_states()

static func room_path_distance(game: Node, from_room: Vector2i, to_room: Vector2i) -> int:
	if from_room == to_room:
		return 0
	var path: Array[Vector2i] = game.find_path(from_room, to_room, true)
	if path.is_empty():
		return 99999
	return maxi(path.size() - 1, 0)
