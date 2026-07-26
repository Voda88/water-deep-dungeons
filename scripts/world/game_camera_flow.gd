extends RefCounted

static func center_camera(game: Node) -> void:
	refresh_camera_bounds(game)
	game.camera.zoom = Vector2(game.CAMERA_DEFAULT_ZOOM, game.CAMERA_DEFAULT_ZOOM)
	game.camera.global_position = hero_focus_position(game)
	clamp_camera(game)

static func refresh_camera_bounds(game: Node) -> void:
	var crystal_rect: Rect2 = game.room_rect(game.crystal_room)
	var min_point: Vector2 = crystal_rect.position
	var max_point: Vector2 = crystal_rect.position + crystal_rect.size
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		var rect: Rect2 = game.room_rect(room_coord)
		min_point.x = minf(min_point.x, rect.position.x)
		min_point.y = minf(min_point.y, rect.position.y)
		max_point.x = maxf(max_point.x, rect.position.x + rect.size.x)
		max_point.y = maxf(max_point.y, rect.position.y + rect.size.y)
	var viewport_padding: Vector2 = game.get_viewport_rect().size * 0.12 * game.camera.zoom
	var total_padding: Vector2 = game.CAMERA_BOUNDS_PADDING + game.CAMERA_DISCOVERED_PAN_SLACK + viewport_padding
	game.camera_bounds = Rect2(min_point - total_padding, (max_point - min_point) + total_padding * 2.0)

static func hero_focus_position(game: Node) -> Vector2:
	var hero: Variant = game.selected_hero()
	if hero == null:
		return game.room_center(game.crystal_room)
	return hero.global_position + game.CAMERA_SOFT_FOLLOW_OFFSET * game.camera.zoom.y

static func mark_camera_interaction(game: Node) -> void:
	game.camera_interaction_cooldown = game.CAMERA_INTERACTION_COOLDOWN

static func mark_camera_pan_interaction(game: Node) -> void:
	game.camera_interaction_cooldown = maxf(game.camera_interaction_cooldown, game.CAMERA_MANUAL_PAN_COOLDOWN)

static func reset_camera_pan_state(_game: Node) -> void:
	return

static func cancel_room_action_camera_focus(game: Node) -> void:
	game.room_action_camera_target_active = false

static func advance_camera(game: Node, delta: float) -> void:
	game.camera_interaction_cooldown = maxf(game.camera_interaction_cooldown - delta, 0.0)
	if not game.room_action_menu.is_empty():
		game.camera.global_position = game.camera.global_position.lerp(game.room_action_camera_target, minf(game.CAMERA_ROOM_ACTION_PAN_SPEED * delta, 1.0))
		if game.camera.global_position.distance_to(game.room_action_camera_target) <= 3.0:
			game.camera.global_position = game.room_action_camera_target
		clamp_camera(game)
		return
	if game.room_action_camera_target_active:
		game.camera.global_position = game.camera.global_position.lerp(game.room_action_camera_target, minf(game.CAMERA_ROOM_ACTION_PAN_SPEED * delta, 1.0))
		if game.camera.global_position.distance_to(game.room_action_camera_target) <= 6.0:
			game.room_action_camera_target_active = false
		clamp_camera(game)
		return
	if game.touch_dragging and game.active_touch_id >= 0 and game.touch_points.has(game.active_touch_id):
		var touch_screen: Vector2 = Vector2(game.touch_points[game.active_touch_id])
		game.camera.global_position -= (touch_screen - game.touch_pan_last_screen) * game.camera.zoom * game.CAMERA_PAN_DRAG_MULTIPLIER
		game.touch_pan_last_screen = touch_screen
	if game.camera_interaction_cooldown <= 0.0 and game.touch_points.is_empty() and not game.mouse_pressed:
		var hero: Variant = game.selected_hero()
		if hero != null and (not hero.is_idle() or hero.pending_room != game.HERO_INVALID_ROOM):
			var target_position: Vector2 = hero_focus_position(game)
			game.camera.global_position = game.camera.global_position.lerp(target_position, minf(game.CAMERA_SOFT_FOLLOW_SPEED * delta, 1.0))
	clamp_camera(game)

static func clamp_camera(game: Node) -> void:
	if game.camera_bounds == Rect2():
		return
	var viewport_size: Vector2 = game.get_viewport_rect().size
	var view_half: Vector2 = viewport_size * 0.5 * game.camera.zoom
	var min_x: float = game.camera_bounds.position.x + view_half.x
	var max_x: float = game.camera_bounds.position.x + game.camera_bounds.size.x - view_half.x
	var min_y: float = game.camera_bounds.position.y + view_half.y
	var max_y: float = game.camera_bounds.position.y + game.camera_bounds.size.y - view_half.y
	if min_x > max_x:
		game.camera.global_position.x = game.camera_bounds.get_center().x
	else:
		game.camera.global_position.x = clampf(game.camera.global_position.x, min_x, max_x)
	if min_y > max_y:
		game.camera.global_position.y = game.camera_bounds.get_center().y
	else:
		game.camera.global_position.y = clampf(game.camera.global_position.y, min_y, max_y)

static func set_camera_zoom(game: Node, zoom_value: float) -> void:
	var clamped_zoom: float = clampf(zoom_value, game.CAMERA_MIN_ZOOM, game.CAMERA_MAX_ZOOM)
	game.camera.zoom = Vector2(clamped_zoom, clamped_zoom)
	clamp_camera(game)

static func center_on_selected_hero(game: Node) -> void:
	mark_camera_interaction(game)
	game.camera.global_position = hero_focus_position(game)
	clamp_camera(game)
