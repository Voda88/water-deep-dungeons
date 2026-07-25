extends Node2D

const FRONTIER_DOOR_COLOR: Color = Color("f6e39d")
const FRONTIER_CORE_COLOR: Color = Color("203039")

var game = null
var room_instances: Dictionary = {}
var room_scene_cache: Dictionary = {}

@onready var walkable_tile_layer: TileMapLayer = $WalkableTileLayer

func configure(next_game) -> void:
	game = next_game
	rebuild()

func rebuild() -> void:
	_sync_room_instances()
	if walkable_tile_layer != null:
		walkable_tile_layer.clear()
	queue_redraw()

func _exit_tree() -> void:
	_clear_room_instances()

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(Vector2(-2400.0, -1800.0), Vector2(4800.0, 3600.0)), Color("0c1418"), true)
	draw_frontier_doors()

func _room_instances_root() -> Node2D:
	var existing: Node2D = get_node_or_null(^"RoomInstances")
	if existing != null:
		return existing
	var created: Node2D = Node2D.new()
	created.name = "RoomInstances"
	add_child(created)
	move_child(created, get_child_count() - 1)
	return created

func _clear_room_instances() -> void:
	for room_coord_variant in room_instances.keys():
		var instance: Node = room_instances[room_coord_variant]
		if instance != null and is_instance_valid(instance):
			instance.queue_free()
	room_instances.clear()

func _load_room_scene(scene_path: String) -> PackedScene:
	if room_scene_cache.has(scene_path):
		return room_scene_cache[scene_path]
	var scene_resource: Resource = load(scene_path)
	if scene_resource is PackedScene:
		room_scene_cache[scene_path] = scene_resource
		return scene_resource
	return null

func _sync_room_instances() -> void:
	var root: Node2D = _room_instances_root()
	var active_rooms: Dictionary = {}
	if game == null:
		_clear_room_instances()
		return
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if not bool(room.get("opened", false)):
			continue
		active_rooms[room_coord] = true
		var scene_path: String = String(room.get("room_scene_path", ""))
		if scene_path.is_empty():
			continue
		var instance: Node2D = room_instances.get(room_coord)
		if instance == null or not is_instance_valid(instance) or String(instance.scene_file_path) != scene_path:
			if instance != null and is_instance_valid(instance):
				instance.queue_free()
			var packed_scene: PackedScene = _load_room_scene(scene_path)
			if packed_scene == null:
				continue
			instance = packed_scene.instantiate() as Node2D
			if instance == null:
				continue
			root.add_child(instance)
			room_instances[room_coord] = instance
		instance.position = game.room_center(room_coord)
		if instance.has_method("apply_room_state"):
			instance.call("apply_room_state", game, room_coord, room)
	for room_coord_variant in room_instances.keys():
		var room_coord: Vector2i = room_coord_variant
		if active_rooms.has(room_coord):
			continue
		var stale_instance: Node = room_instances[room_coord]
		if stale_instance != null and is_instance_valid(stale_instance):
			stale_instance.queue_free()
		room_instances.erase(room_coord)

func draw_frontier_doors() -> void:
	if game == null:
		return
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if game.rooms[neighbor]["opened"]:
				continue
			var doorway: Vector2 = game.doorway_position(room_coord, neighbor)
			var direction: Vector2 = (game.room_center(neighbor) - game.room_center(room_coord)).normalized()
			var outer_position: Vector2 = doorway + direction * 14.0
			var tangent: Vector2 = Vector2(-direction.y, direction.x)
			draw_line(doorway - direction * 5.0, outer_position, FRONTIER_DOOR_COLOR, 9.0, true)
			draw_line(doorway - direction * 3.0, outer_position, Color("7a6745"), 3.0, true)
			draw_circle(outer_position, 12.0, FRONTIER_CORE_COLOR)
			draw_arc(outer_position, 13.0, 0.0, TAU, 28, FRONTIER_DOOR_COLOR, 3.0, true)
			draw_line(outer_position - tangent * 5.0, outer_position + tangent * 5.0, FRONTIER_DOOR_COLOR, 2.2, true)
			draw_line(outer_position - direction * 5.0, outer_position + direction * 5.0, FRONTIER_DOOR_COLOR, 2.2, true)
