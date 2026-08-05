extends Node2D

const ROOM_PREWARM_INTERVAL: float = 0.05

var game = null
var room_instances: Dictionary = {}
var room_scene_cache: Dictionary = {}
var prewarm_queue: Array[Vector2i] = []
var prewarmed_rooms: Dictionary = {}
var prewarm_timer_left: float = 0.0

func configure(next_game) -> void:
	game = next_game
	rebuild()

func rebuild() -> void:
	_sync_room_instances()
	_queue_opened_room_neighbors_for_prewarm()
	queue_redraw()

func _exit_tree() -> void:
	_clear_room_instances()

func _process(delta: float) -> void:
	_advance_room_prewarm(delta)

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(Vector2(-2400.0, -1800.0), Vector2(4800.0, 3600.0)), Color("0c1418"), true)

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
	prewarm_queue.clear()
	prewarmed_rooms.clear()
	prewarm_timer_left = 0.0

func queue_adjacent_rooms_for_prewarm(origin_room: Vector2i) -> void:
	if game == null or not game.rooms.has(origin_room):
		return
	var neighbors: Array = Array(game.rooms[origin_room].get("neighbors", []))
	for neighbor_variant in neighbors:
		var neighbor: Vector2i = Vector2i(neighbor_variant)
		_queue_room_for_prewarm(neighbor)

func _queue_opened_room_neighbors_for_prewarm() -> void:
	if game == null:
		return
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if not bool(room.get("opened", false)):
			continue
		queue_adjacent_rooms_for_prewarm(room_coord)

func _queue_room_for_prewarm(room_coord: Vector2i) -> void:
	if game == null or not game.rooms.has(room_coord):
		return
	var room: Dictionary = game.rooms[room_coord]
	if bool(room.get("opened", false)) or bool(room.get("scry_revealed", false)):
		return
	if room_instances.has(room_coord) and is_instance_valid(room_instances[room_coord]):
		return
	if prewarmed_rooms.has(room_coord):
		return
	if prewarm_queue.has(room_coord):
		return
	if String(room.get("room_scene_path", "")).is_empty():
		return
	prewarm_queue.append(room_coord)

func _advance_room_prewarm(delta: float) -> void:
	if game == null or prewarm_queue.is_empty():
		return
	prewarm_timer_left = maxf(prewarm_timer_left - delta, 0.0)
	if prewarm_timer_left > 0.0:
		return
	prewarm_timer_left = ROOM_PREWARM_INTERVAL
	_prewarm_next_room()

func _prewarm_next_room() -> void:
	while not prewarm_queue.is_empty():
		var room_coord: Vector2i = prewarm_queue[0]
		prewarm_queue.remove_at(0)
		if game == null or not game.rooms.has(room_coord):
			continue
		var room: Dictionary = game.rooms[room_coord]
		if bool(room.get("opened", false)) or bool(room.get("scry_revealed", false)):
			continue
		_sync_single_room_instance(room_coord, room)
		return

func _load_room_scene(scene_path: String) -> PackedScene:
	if room_scene_cache.has(scene_path):
		return room_scene_cache[scene_path]
	var scene_resource: Resource = load(scene_path)
	if scene_resource is PackedScene:
		room_scene_cache[scene_path] = scene_resource
		return scene_resource
	return null

func _room_should_be_visible(room: Dictionary) -> bool:
	return bool(room.get("opened", false)) or bool(room.get("scry_revealed", false))

func _room_should_keep_instance(room_coord: Vector2i, room: Dictionary) -> bool:
	if _room_should_be_visible(room):
		return true
	return prewarmed_rooms.has(room_coord)

func _sync_single_room_instance(room_coord: Vector2i, room: Dictionary) -> void:
	var scene_path: String = String(room.get("room_scene_path", ""))
	if scene_path.is_empty():
		return
	var instance: Node2D = room_instances.get(room_coord)
	if instance == null or not is_instance_valid(instance) or String(instance.scene_file_path) != scene_path:
		if instance != null and is_instance_valid(instance):
			instance.queue_free()
		var packed_scene: PackedScene = _load_room_scene(scene_path)
		if packed_scene == null:
			return
		instance = packed_scene.instantiate() as Node2D
		if instance == null:
			return
		_room_instances_root().add_child(instance)
		room_instances[room_coord] = instance
	instance.position = game.room_center(room_coord)
	var opened: bool = bool(room.get("opened", false))
	var scry_revealed: bool = bool(room.get("scry_revealed", false))
	instance.visible = opened or scry_revealed
	if instance.has_method("apply_room_state"):
		instance.call("apply_room_state", game, room_coord, room)
	if instance.has_method("set_scry_revealed"):
		instance.call("set_scry_revealed", scry_revealed and not opened)
	if opened or scry_revealed:
		prewarmed_rooms.erase(room_coord)
	else:
		prewarmed_rooms[room_coord] = true

func _sync_room_instances() -> void:
	var active_rooms: Dictionary = {}
	if game == null:
		_clear_room_instances()
		return
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if not _room_should_keep_instance(room_coord, room):
			continue
		active_rooms[room_coord] = true
		_sync_single_room_instance(room_coord, room)
	for room_coord_variant in room_instances.keys():
		var room_coord: Vector2i = room_coord_variant
		if active_rooms.has(room_coord):
			continue
		var stale_instance: Node = room_instances[room_coord]
		if stale_instance != null and is_instance_valid(stale_instance):
			stale_instance.queue_free()
		room_instances.erase(room_coord)
		prewarmed_rooms.erase(room_coord)

