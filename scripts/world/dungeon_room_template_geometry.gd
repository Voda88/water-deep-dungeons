extends RefCounted

static func build_template_metadata(room: Node) -> Dictionary:
	var walkable_region_specs: Array = walkable_region_specs_normalized(room)
	var slot_regions: Array = slot_regions_normalized(room)
	var metadata: Dictionary = {
		"scene_path": room.scene_file_path,
		"template_id": room.template_id,
		"template_name": room.template_name,
		"room_size": room.room_size,
		"minor_slots": room.default_minor_slots,
		"major_slots": room.default_major_slots,
		"walkable_region_specs": walkable_region_specs,
		"slot_regions_normalized": slot_regions,
		"minor_slot_positions_normalized": minor_slot_positions_normalized(room),
		"door_positions_normalized": door_positions_normalized(room),
		"geometry_id": room.template_id,
		"wall_thickness": wall_thickness(room),
	}
	if room.default_major_slots > 0:
		var major_slot: Marker2D = room.get_node_or_null(^"Slots/MajorSlot")
		if major_slot != null:
			metadata["major_slot_normalized"] = local_point_to_normalized(room, major_slot.position)
	return metadata

static func local_room_rect(room: Node) -> Rect2:
	return Rect2(-room.room_size * 0.5, room.room_size)

static func local_point_to_normalized(room: Node, local_point: Vector2) -> Vector2:
	var room_rect: Rect2 = local_room_rect(room)
	return Vector2(
		(local_point.x - room_rect.position.x) / maxf(room.room_size.x, 1.0),
		(local_point.y - room_rect.position.y) / maxf(room.room_size.y, 1.0)
	)

static func backdrop_local_rect(room: Node) -> Rect2:
	var backdrop_node: ColorRect = room.get_node_or_null(room.BACKDROP_NODE_PATH)
	if backdrop_node != null:
		return color_rect_local_rect(backdrop_node)
	return local_room_rect(room)

static func interior_local_rect(room: Node) -> Rect2:
	var inner_wall_node: ColorRect = room.get_node_or_null(room.INNER_WALL_NODE_PATH)
	if inner_wall_node != null:
		return color_rect_local_rect(inner_wall_node)
	var fallback_rect: Rect2 = backdrop_local_rect(room)
	return fallback_rect.grow(-8.0)

static func wall_thickness(room: Node) -> float:
	var backdrop_rect: Rect2 = backdrop_local_rect(room)
	var inner_rect: Rect2 = interior_local_rect(room)
	var left_gap: float = inner_rect.position.x - backdrop_rect.position.x
	var top_gap: float = inner_rect.position.y - backdrop_rect.position.y
	var right_gap: float = backdrop_rect.end.x - inner_rect.end.x
	var bottom_gap: float = backdrop_rect.end.y - inner_rect.end.y
	return maxf(minf(minf(left_gap, right_gap), minf(top_gap, bottom_gap)), 0.0)

static func clamped_interior_edge_position(room: Node, direction_key: String, marker_position: Vector2) -> Vector2:
	var backdrop_rect: Rect2 = backdrop_local_rect(room)
	var inner_rect: Rect2 = interior_local_rect(room)
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

static func door_positions_normalized(room: Node) -> Dictionary:
	var doors: Dictionary = {}
	var door_nodes: Dictionary = {
		"left": room.get_node_or_null(^"Doors/Left"),
		"right": room.get_node_or_null(^"Doors/Right"),
		"up": room.get_node_or_null(^"Doors/Up"),
		"down": room.get_node_or_null(^"Doors/Down"),
	}
	for key_variant in door_nodes.keys():
		var key: String = String(key_variant)
		var node: Marker2D = door_nodes[key]
		if node == null:
			continue
		doors[key] = local_point_to_normalized(room, clamped_interior_edge_position(room, key, node.position))
	return doors

static func minor_slot_positions_normalized(room: Node) -> Array:
	var positions: Array = []
	var slots_root: Node = room.get_node_or_null(^"Slots")
	if slots_root == null:
		return positions
	for child in slots_root.get_children():
		if child is Marker2D and String(child.name).begins_with("Minor"):
			positions.append(local_point_to_normalized(room, child.position))
	return positions

static func color_rect_local_rect(node: ColorRect) -> Rect2:
	if node == null:
		return Rect2()
	return Rect2(node.position, node.size)

static func walkable_region_nodes(room: Node) -> Array:
	var nodes: Array = []
	var root: Node = room.get_node_or_null(^"Layout/WalkableRegions")
	if root == null:
		return nodes
	for child in root.get_children():
		if child is ColorRect:
			nodes.append(child)
	return nodes

static func slot_region_nodes(room: Node) -> Array:
	var nodes: Array = []
	var root: Node = room.get_node_or_null(^"Layout/SlotAreas")
	if root == null:
		return nodes
	for child in root.get_children():
		if child is ColorRect:
			nodes.append(child)
	return nodes

static func walkable_region_specs_normalized(room: Node) -> Array:
	var regions: Array = []
	for node_variant in walkable_region_nodes(room):
		var node: ColorRect = node_variant
		var region_rect: Rect2 = color_rect_local_rect(node)
		if region_rect.size.x <= 0.0 or region_rect.size.y <= 0.0:
			continue
		regions.append({
			"rect": rect_to_normalized(room, region_rect),
			"required_door_key": walkable_region_required_door_key(String(node.name)),
		})
	return regions

static func slot_regions_normalized(room: Node) -> Array:
	var regions: Array = []
	for node_variant in slot_region_nodes(room):
		var node: ColorRect = node_variant
		var region_rect: Rect2 = color_rect_local_rect(node)
		regions.append(rect_to_normalized(room, region_rect))
	return regions

static func rect_to_normalized(room: Node, local_rect: Rect2) -> Rect2:
	var room_rect: Rect2 = local_room_rect(room)
	return Rect2(
		Vector2(
			(local_rect.position.x - room_rect.position.x) / maxf(room.room_size.x, 1.0),
			(local_rect.position.y - room_rect.position.y) / maxf(room.room_size.y, 1.0)
		),
		Vector2(
			local_rect.size.x / maxf(room.room_size.x, 1.0),
			local_rect.size.y / maxf(room.room_size.y, 1.0)
		)
	)

static func walkable_region_required_door_key(node_name: String) -> String:
	if node_name.ends_with("Left"):
		return "left"
	if node_name.ends_with("Right"):
		return "right"
	if node_name.ends_with("Up"):
		return "up"
	if node_name.ends_with("Down"):
		return "down"
	return ""
