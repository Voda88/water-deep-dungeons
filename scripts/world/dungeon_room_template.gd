@tool
extends Node2D

const DOOR_VISUAL_WIDTH: float = 42.0
const PREVIEW_BACKGROUND: Color = Color(0.05, 0.07, 0.08, 0.65)
const BACKDROP_NODE_PATH: NodePath = ^"Art/RoomBackdrop"
const INNER_WALL_NODE_PATH: NodePath = ^"Art/InnerWall"
const DUNGEON_TILEMAP_NODE_PATH: NodePath = ^"Art/DungeonTileMap"
const WATER_TILEMAP_NODE_PATH: NodePath = ^"Art/WaterTileMap"
const DOOR_ART_ROOT_PATH: NodePath = ^"DoorArt"

@export var template_id: String = "nook"
@export var template_name: String = "Nook"
@export var room_size: Vector2 = Vector2(300.0, 200.0)
@export var default_minor_slots: int = 2
@export var default_major_slots: int = 0
@export var show_backdrop_helpers_in_runtime: bool = true
@export var show_layout_helpers_in_runtime: bool = true
@export var preview_theme_id: String = "cavern"
@export var preview_lit: bool = false
@export var preview_crystal: bool = false
@export var preview_left_door: bool = true
@export var preview_right_door: bool = true
@export var preview_up_door: bool = true
@export var preview_down_door: bool = true
@export var dark_room_modulate: Color = Color(0.20, 0.22, 0.28, 1.0)

var runtime_game = null
var runtime_room_coord: Vector2i = Vector2i.ZERO
var runtime_room: Dictionary = {}

func _ready() -> void:
	sync_control_input_passthrough()
	refresh_room_visuals()

func apply_room_state(next_game, room_coord: Vector2i, room_data: Dictionary) -> void:
	runtime_game = next_game
	runtime_room_coord = room_coord
	runtime_room = room_data.duplicate(true)
	sync_control_input_passthrough()
	refresh_room_visuals()

func build_template_metadata() -> Dictionary:
	var walkable_region_specs: Array = walkable_region_specs_normalized()
	var slot_regions: Array = slot_regions_normalized()
	var metadata: Dictionary = {
		"scene_path": scene_file_path,
		"template_id": template_id,
		"template_name": template_name,
		"room_size": room_size,
		"minor_slots": default_minor_slots,
		"major_slots": default_major_slots,
		"walkable_region_specs": walkable_region_specs,
		"slot_regions_normalized": slot_regions,
		"minor_slot_positions_normalized": minor_slot_positions_normalized(),
		"door_positions_normalized": door_positions_normalized(),
		"geometry_id": template_id,
		"wall_thickness": wall_thickness(),
	}
	if default_major_slots > 0:
		var major_slot: Marker2D = get_node_or_null(^"Slots/MajorSlot")
		if major_slot != null:
			metadata["major_slot_normalized"] = local_point_to_normalized(major_slot.position)
	return metadata

func room_theme_palette(theme_id: String, lit: bool, crystal_chamber: bool) -> Dictionary:
	if runtime_game != null and runtime_game.has_method("room_theme_palette"):
		return runtime_game.room_theme_palette(theme_id, lit, crystal_chamber)
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

func current_theme_id() -> String:
	if not runtime_room.is_empty():
		return String(runtime_room.get("theme_id", preview_theme_id))
	return preview_theme_id

func current_lit() -> bool:
	if not runtime_room.is_empty():
		return bool(runtime_room.get("lit", preview_lit))
	return preview_lit

func current_crystal() -> bool:
	if not runtime_room.is_empty():
		return bool(runtime_room.get("crystal", preview_crystal))
	return preview_crystal

func current_door_dirs() -> Array:
	if not runtime_room.is_empty():
		return Array(runtime_room.get("door_dirs", []))
	var preview_doors: Array = []
	if preview_left_door:
		preview_doors.append(Vector2i.LEFT)
	if preview_right_door:
		preview_doors.append(Vector2i.RIGHT)
	if preview_up_door:
		preview_doors.append(Vector2i.UP)
	if preview_down_door:
		preview_doors.append(Vector2i.DOWN)
	return preview_doors

func direction_key_to_vector(direction_key: String) -> Vector2i:
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

func local_room_rect() -> Rect2:
	return Rect2(-room_size * 0.5, room_size)

func normalized_rect_to_local(normalized_rect: Rect2) -> Rect2:
	var room_rect: Rect2 = local_room_rect()
	return Rect2(
		room_rect.position + Vector2(normalized_rect.position.x * room_size.x, normalized_rect.position.y * room_size.y),
		Vector2(normalized_rect.size.x * room_size.x, normalized_rect.size.y * room_size.y)
	)

func local_point_to_normalized(local_point: Vector2) -> Vector2:
	var room_rect: Rect2 = local_room_rect()
	return Vector2(
		(local_point.x - room_rect.position.x) / maxf(room_size.x, 1.0),
		(local_point.y - room_rect.position.y) / maxf(room_size.y, 1.0)
	)

func backdrop_local_rect() -> Rect2:
	var backdrop_node: ColorRect = get_node_or_null(BACKDROP_NODE_PATH)
	if backdrop_node != null:
		return color_rect_local_rect(backdrop_node)
	return local_room_rect()

func interior_local_rect() -> Rect2:
	var inner_wall_node: ColorRect = get_node_or_null(INNER_WALL_NODE_PATH)
	if inner_wall_node != null:
		return color_rect_local_rect(inner_wall_node)
	var fallback_rect: Rect2 = backdrop_local_rect()
	return fallback_rect.grow(-8.0)

func wall_thickness() -> float:
	var backdrop_rect: Rect2 = backdrop_local_rect()
	var inner_rect: Rect2 = interior_local_rect()
	var left_gap: float = inner_rect.position.x - backdrop_rect.position.x
	var top_gap: float = inner_rect.position.y - backdrop_rect.position.y
	var right_gap: float = backdrop_rect.end.x - inner_rect.end.x
	var bottom_gap: float = backdrop_rect.end.y - inner_rect.end.y
	return maxf(minf(minf(left_gap, right_gap), minf(top_gap, bottom_gap)), 0.0)

func clamped_interior_edge_position(direction_key: String, marker_position: Vector2) -> Vector2:
	var backdrop_rect: Rect2 = backdrop_local_rect()
	var inner_rect: Rect2 = interior_local_rect()
	var edge_padding: float = 8.0
	match direction_key:
		"left":
			return Vector2(
				backdrop_rect.position.x,
				clampf(marker_position.y, inner_rect.position.y + edge_padding, inner_rect.end.y - edge_padding)
			)
		"right":
			return Vector2(
				backdrop_rect.end.x,
				clampf(marker_position.y, inner_rect.position.y + edge_padding, inner_rect.end.y - edge_padding)
			)
		"up":
			return Vector2(
				clampf(marker_position.x, inner_rect.position.x + edge_padding, inner_rect.end.x - edge_padding),
				backdrop_rect.position.y
			)
		"down":
			return Vector2(
				clampf(marker_position.x, inner_rect.position.x + edge_padding, inner_rect.end.x - edge_padding),
				backdrop_rect.end.y
			)
		_:
			return marker_position

func door_cutout_local_rect(direction_key: String, marker_position: Vector2, opening_width: float = DOOR_VISUAL_WIDTH) -> Rect2:
	var backdrop_rect: Rect2 = backdrop_local_rect()
	var inner_rect: Rect2 = interior_local_rect()
	var threshold_position: Vector2 = clamped_interior_edge_position(direction_key, marker_position)
	var half_width: float = opening_width * 0.5
	match direction_key:
		"left":
			return Rect2(
				Vector2(backdrop_rect.position.x - 1.0, threshold_position.y - half_width),
				Vector2(maxf(inner_rect.position.x - backdrop_rect.position.x + 2.0, 2.0), opening_width)
			)
		"right":
			return Rect2(
				Vector2(inner_rect.end.x - 1.0, threshold_position.y - half_width),
				Vector2(maxf(backdrop_rect.end.x - inner_rect.end.x + 2.0, 2.0), opening_width)
			)
		"up":
			return Rect2(
				Vector2(threshold_position.x - half_width, backdrop_rect.position.y - 1.0),
				Vector2(opening_width, maxf(inner_rect.position.y - backdrop_rect.position.y + 2.0, 2.0))
			)
		"down":
			return Rect2(
				Vector2(threshold_position.x - half_width, inner_rect.end.y - 1.0),
				Vector2(opening_width, maxf(backdrop_rect.end.y - inner_rect.end.y + 2.0, 2.0))
			)
		_:
			return Rect2()

func door_positions_normalized() -> Dictionary:
	var doors: Dictionary = {}
	var door_nodes: Dictionary = {
		"left": get_node_or_null(^"Doors/Left"),
		"right": get_node_or_null(^"Doors/Right"),
		"up": get_node_or_null(^"Doors/Up"),
		"down": get_node_or_null(^"Doors/Down"),
	}
	for key_variant in door_nodes.keys():
		var key: String = String(key_variant)
		var node: Marker2D = door_nodes[key]
		if node == null:
			continue
		doors[key] = local_point_to_normalized(clamped_interior_edge_position(key, node.position))
	return doors

func door_art_opened(direction_key: String) -> bool:
	if runtime_game == null or runtime_room.is_empty():
		return false
	var direction: Vector2i = direction_key_to_vector(direction_key)
	if direction == Vector2i.ZERO:
		return false
	var neighbor_coord: Vector2i = runtime_room_coord + direction
	if not runtime_game.rooms.has(neighbor_coord):
		return false
	return bool(runtime_game.rooms[neighbor_coord].get("opened", false))

func minor_slot_positions_normalized() -> Array:
	var positions: Array = []
	var slots_root: Node = get_node_or_null(^"Slots")
	if slots_root == null:
		return positions
	for child in slots_root.get_children():
		if child is Marker2D and String(child.name).begins_with("Minor"):
			positions.append(local_point_to_normalized(child.position))
	return positions

func is_layout_color_rect_node(node: Node) -> bool:
	return node is ColorRect

func color_rect_local_rect(node: ColorRect) -> Rect2:
	if node == null:
		return Rect2()
	return Rect2(node.position, node.size)

func walkable_region_nodes() -> Array:
	var nodes: Array = []
	var root: Node = get_node_or_null(^"Layout/WalkableRegions")
	if root == null:
		return nodes
	for child in root.get_children():
		if is_layout_color_rect_node(child):
			nodes.append(child)
	return nodes

func slot_region_nodes() -> Array:
	var nodes: Array = []
	var root: Node = get_node_or_null(^"Layout/SlotAreas")
	if root == null:
		return nodes
	for child in root.get_children():
		if is_layout_color_rect_node(child):
			nodes.append(child)
	return nodes

func walkable_region_specs_normalized() -> Array:
	var regions: Array = []
	for node_variant in walkable_region_nodes():
		var node: ColorRect = node_variant
		var region_rect: Rect2 = color_rect_local_rect(node)
		if region_rect.size.x <= 0.0 or region_rect.size.y <= 0.0:
			continue
		regions.append({
			"rect": rect_to_normalized(region_rect),
			"required_door_key": walkable_region_required_door_key(String(node.name)),
		})
	return regions

func slot_regions_normalized() -> Array:
	var regions: Array = []
	for node_variant in slot_region_nodes():
		var node: ColorRect = node_variant
		var region_rect: Rect2 = color_rect_local_rect(node)
		regions.append(rect_to_normalized(region_rect))
	return regions

func rect_to_normalized(local_rect: Rect2) -> Rect2:
	var room_rect: Rect2 = local_room_rect()
	return Rect2(
		Vector2(
			(local_rect.position.x - room_rect.position.x) / maxf(room_size.x, 1.0),
			(local_rect.position.y - room_rect.position.y) / maxf(room_size.y, 1.0)
		),
		Vector2(
			local_rect.size.x / maxf(room_size.x, 1.0),
			local_rect.size.y / maxf(room_size.y, 1.0)
		)
	)

func walkable_region_required_door_key(node_name: String) -> String:
	if node_name.ends_with("Left"):
		return "left"
	if node_name.ends_with("Right"):
		return "right"
	if node_name.ends_with("Up"):
		return "up"
	if node_name.ends_with("Down"):
		return "down"
	return ""

func door_dir_keys(door_dirs: Array) -> Dictionary:
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

func sync_control_input_passthrough() -> void:
	var queue: Array[Node] = [self]
	while not queue.is_empty():
		var current: Node = queue.pop_back()
		if current is Control:
			var control: Control = current
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in current.get_children():
			queue.append(child)

func sync_backdrop_visuals() -> void:
	var palette: Dictionary = room_theme_palette(current_theme_id(), current_lit(), current_crystal())
	var base_fill: Color = Color(palette.get("base_fill", PREVIEW_BACKGROUND))
	var backdrop_node: ColorRect = get_node_or_null(BACKDROP_NODE_PATH)
	if backdrop_node != null:
		backdrop_node.color = Color(base_fill.r, base_fill.g, base_fill.b, 0.94)
	var inner_wall_node: ColorRect = get_node_or_null(INNER_WALL_NODE_PATH)
	if inner_wall_node != null:
		var inner_alpha: float = 0.10 if Engine.is_editor_hint() else 0.0
		inner_wall_node.color = Color(base_fill.r, base_fill.g, base_fill.b, inner_alpha)

func sync_tilemap_lighting() -> void:
	var lit: bool = current_lit()
	var dungeon_tilemap: CanvasItem = get_node_or_null(DUNGEON_TILEMAP_NODE_PATH) as CanvasItem
	if dungeon_tilemap != null:
		dungeon_tilemap.modulate = Color.WHITE if lit else dark_room_modulate
	var water_tilemap: CanvasItem = get_node_or_null(WATER_TILEMAP_NODE_PATH) as CanvasItem
	if water_tilemap != null:
		water_tilemap.modulate = Color.WHITE if lit else dark_room_modulate
	var door_art_root: CanvasItem = get_node_or_null(DOOR_ART_ROOT_PATH) as CanvasItem
	if door_art_root != null:
		door_art_root.modulate = Color.WHITE if lit else dark_room_modulate

func sync_door_art() -> void:
	var door_art_root: Node = get_node_or_null(DOOR_ART_ROOT_PATH)
	if door_art_root == null:
		return
	var available_door_keys: Dictionary = door_dir_keys(current_door_dirs())
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
		var opened: bool = door_art_opened(direction_key)
		var closed_node: CanvasItem = direction_node.get_node_or_null(^"Closed")
		var open_node: CanvasItem = direction_node.get_node_or_null(^"Open")
		if closed_node != null:
			closed_node.visible = not opened
		if open_node != null:
			open_node.visible = opened

func refresh_room_visuals() -> void:
	sync_backdrop_visuals()
	sync_tilemap_lighting()
	sync_door_art()
