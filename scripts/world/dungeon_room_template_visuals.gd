extends RefCounted

static func room_theme_palette(room: Node, theme_id: String, lit: bool, crystal_chamber: bool) -> Dictionary:
	if room.runtime_game != null and room.runtime_game.has_method("room_theme_palette"):
		return room.runtime_game.room_theme_palette(theme_id, lit, crystal_chamber)
	var palette: Dictionary = {
		"base_fill": Color("131110"),
		"floor_fill": Color("4a4337"),
		"floor_outline": Color("c9c0ac"),
	}
	if lit:
		palette = {
			"base_fill": Color("221e1a"),
			"floor_fill": Color("7a715f"),
			"floor_outline": Color("fff5df"),
		}
	return palette

static func current_theme_id(room: Node) -> String:
	if not room.runtime_room.is_empty():
		return String(room.runtime_room.get("theme_id", room.preview_theme_id))
	return room.preview_theme_id

static func current_lit(room: Node) -> bool:
	if not room.runtime_room.is_empty():
		return bool(room.runtime_room.get("lit", room.preview_lit))
	return room.preview_lit

static func current_crystal(room: Node) -> bool:
	if not room.runtime_room.is_empty():
		return bool(room.runtime_room.get("crystal", room.preview_crystal))
	return room.preview_crystal

static func current_door_dirs(room: Node) -> Array:
	if not room.runtime_room.is_empty():
		return Array(room.runtime_room.get("door_dirs", []))
	var preview_doors: Array = []
	if room.preview_left_door:
		preview_doors.append(Vector2i.LEFT)
	if room.preview_right_door:
		preview_doors.append(Vector2i.RIGHT)
	if room.preview_up_door:
		preview_doors.append(Vector2i.UP)
	if room.preview_down_door:
		preview_doors.append(Vector2i.DOWN)
	return preview_doors

static func direction_key_to_vector(direction_key: String) -> Vector2i:
	match direction_key:
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
		"up":
			return Vector2i.UP
		"down":
			return Vector2i.DOWN
		_:
			return Vector2i.ZERO

static func door_art_opened(room: Node, direction_key: String) -> bool:
	if room.runtime_game == null or room.runtime_room.is_empty():
		return false
	var direction: Vector2i = direction_key_to_vector(direction_key)
	if direction == Vector2i.ZERO:
		return false
	var neighbor_coord: Vector2i = room.runtime_room_coord + direction
	if not room.runtime_game.rooms.has(neighbor_coord):
		return false
	return bool(room.runtime_game.rooms[neighbor_coord].get("opened", false))

static func door_dir_keys(door_dirs: Array) -> Dictionary:
	var keys: Dictionary = {}
	for direction_variant in door_dirs:
		var direction: Vector2i = direction_variant
		match direction:
			Vector2i.LEFT:
				keys["left"] = true
			Vector2i.RIGHT:
				keys["right"] = true
			Vector2i.UP:
				keys["up"] = true
			Vector2i.DOWN:
				keys["down"] = true
	return keys

static func sync_control_input_passthrough(room: Node) -> void:
	var queue: Array[Node] = [room]
	while not queue.is_empty():
		var current: Node = queue.pop_back()
		if current is Control:
			var control: Control = current
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in current.get_children():
			queue.append(child)

static func sync_backdrop_visuals(room: Node) -> void:
	var palette: Dictionary = room_theme_palette(room, current_theme_id(room), current_lit(room), current_crystal(room))
	var base_fill: Color = Color(palette.get("base_fill", room.PREVIEW_BACKGROUND))
	var backdrop_node: ColorRect = room.get_node_or_null(room.BACKDROP_NODE_PATH)
	if backdrop_node != null:
		backdrop_node.color = Color(base_fill.r, base_fill.g, base_fill.b, 0.94)
	var inner_wall_node: ColorRect = room.get_node_or_null(room.INNER_WALL_NODE_PATH)
	if inner_wall_node != null:
		var inner_alpha: float = 0.10 if Engine.is_editor_hint() else 0.0
		inner_wall_node.color = Color(base_fill.r, base_fill.g, base_fill.b, inner_alpha)

static func sync_tilemap_lighting(room: Node) -> void:
	var lit: bool = current_lit(room)
	var dungeon_tilemap: CanvasItem = room.get_node_or_null(room.DUNGEON_TILEMAP_NODE_PATH) as CanvasItem
	if dungeon_tilemap != null:
		dungeon_tilemap.modulate = Color.WHITE if lit else room.dark_room_modulate
	var water_tilemap: CanvasItem = room.get_node_or_null(room.WATER_TILEMAP_NODE_PATH) as CanvasItem
	if water_tilemap != null:
		water_tilemap.modulate = Color.WHITE if lit else room.dark_room_modulate
	var door_art_root: CanvasItem = room.get_node_or_null(room.DOOR_ART_ROOT_PATH) as CanvasItem
	if door_art_root != null:
		door_art_root.modulate = Color.WHITE if lit else room.dark_room_modulate

static func sync_door_art(room: Node) -> void:
	var door_art_root: Node = room.get_node_or_null(room.DOOR_ART_ROOT_PATH)
	if door_art_root == null:
		return
	var available_door_keys: Dictionary = door_dir_keys(current_door_dirs(room))
	var direction_node_names: Dictionary = {
		"left": "Left",
		"right": "Right",
		"up": "Up",
		"down": "Down",
	}
	for key_variant in direction_node_names.keys():
		var direction_key: String = String(key_variant)
		var direction_node: CanvasItem = door_art_root.get_node_or_null(NodePath(String(direction_node_names[direction_key])))
		if direction_node == null:
			continue
		var has_door: bool = available_door_keys.has(direction_key)
		direction_node.visible = has_door
		if not has_door:
			continue
		var opened: bool = door_art_opened(room, direction_key)
		var closed_node: CanvasItem = direction_node.get_node_or_null(^"Closed")
		var open_node: CanvasItem = direction_node.get_node_or_null(^"Open")
		if closed_node != null:
			closed_node.visible = not opened
		if open_node != null:
			open_node.visible = opened

static func refresh_room_visuals(room: Node) -> void:
	sync_backdrop_visuals(room)
	sync_tilemap_lighting(room)
	sync_door_art(room)
