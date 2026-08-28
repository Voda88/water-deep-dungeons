extends RefCounted
class_name DungeonModule

var game: Node
var current_room: Vector2i = Vector2i(-99, -99)
var slot_index: int = -1
var is_major: bool = false
var module_type: String = ""
var actor_key: String = ""
var global_position: Vector2:
	get:
		return world_position()

func configure(owner_game: Node, room_coord: Vector2i, module_slot_index: int, major: bool, type: String) -> void:
	game = owner_game
	current_room = room_coord
	slot_index = module_slot_index
	is_major = major
	module_type = type
	actor_key = "module:%s:%s" % ["major" if is_major else "minor", "%d:%d:%d" % [current_room.x, current_room.y, slot_index]]

func world_position() -> Vector2:
	if game == null or not game.rooms.has(current_room):
		return Vector2.ZERO
	if is_major:
		return game.major_slot_position(current_room)
	var slot_positions: Array = game.minor_slot_positions(current_room)
	return Vector2(slot_positions[slot_index]) if slot_index >= 0 and slot_index < slot_positions.size() else game.room_center(current_room)

func is_active() -> bool:
	return current_health() > 0.0

func current_health() -> float:
	var state: Dictionary = state_data()
	return float(state.get("health", 0.0))

func is_under_construction() -> bool:
	return bool(state_data().get("under_construction", false))

func take_damage(amount: float, _impact_direction: Vector2 = Vector2.RIGHT, source_label: String = "Enemies") -> bool:
	if amount <= 0.0 or game == null or not game.rooms.has(current_room):
		return false
	var remaining_health: float = maxf(current_health() - amount, 0.0)
	if remaining_health <= 0.0:
		destroy(source_label)
	else:
		write_health(remaining_health)
		game.status_message = "%s is damaging %s in %s." % [source_label, game.build_type_label(module_type).to_lower(), game.room_title(current_room)]
	return remaining_health <= 0.0

func state_data() -> Dictionary:
	if game == null or not game.rooms.has(current_room):
		return {}
	var room: Dictionary = game.rooms[current_room]
	if is_major:
		return {
			"health": room.get("major_health", 0.0),
			"under_construction": room.get("major_under_construction", false),
		}
	for module_data_variant in Array(room.get("minor_modules", [])):
		var module_data: Dictionary = Dictionary(module_data_variant)
		if int(module_data.get("slot_index", -1)) == slot_index:
			return module_data
	return {}

func write_health(health: float) -> void:
	if game == null or not game.rooms.has(current_room):
		return
	var room: Dictionary = game.rooms[current_room]
	if is_major:
		room["major_health"] = health
		if health <= 0.0:
			room["major_module_type"] = ""
		game.rooms[current_room] = room
		return
	for module_index in range(room["minor_modules"].size()):
		var module_data: Dictionary = Dictionary(room["minor_modules"][module_index])
		if int(module_data.get("slot_index", -1)) != slot_index:
			continue
		module_data["health"] = health
		room["minor_modules"][module_index] = module_data
		game.rooms[current_room] = room
		return

func destroy(source_label: String) -> void:
	if game == null or not game.rooms.has(current_room):
		return
	var room: Dictionary = game.rooms[current_room]
	if is_major:
		room["major_health"] = 0.0
		room["major_module_type"] = ""
		room["major_under_construction"] = false
		game.rooms[current_room] = room
		game.cancel_pending_major_construction(current_room)
	else:
		for module_index in range(room["minor_modules"].size()):
			if int(room["minor_modules"][module_index].get("slot_index", -1)) != slot_index:
				continue
			room["minor_modules"].remove_at(module_index)
			game.rooms[current_room] = room
			game.cancel_pending_minor_construction(current_room, slot_index)
			break
	game.status_message = "%s destroyed %s in %s." % [source_label, game.build_type_label(module_type).to_lower(), game.room_title(current_room)]