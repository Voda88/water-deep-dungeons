extends RefCounted

static var pending_start_data: Dictionary = {}

static func set_pending_start_data(data: Dictionary) -> void:
	pending_start_data = data.duplicate(true)

static func consume_pending_start_data() -> Dictionary:
	var result: Dictionary = pending_start_data.duplicate(true)
	pending_start_data.clear()
	return result
