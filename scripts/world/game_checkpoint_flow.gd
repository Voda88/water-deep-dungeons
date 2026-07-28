extends RefCounted

const CHECKPOINT_FILE_PATH: String = "user://run_checkpoint.save"
const CHECKPOINT_FORMAT_VERSION: int = 1

static func checkpoint_exists(_game: Node) -> bool:
	return FileAccess.file_exists(CHECKPOINT_FILE_PATH)

static func save_checkpoint(game: Node, reason: String = "", show_feedback: bool = false) -> bool:
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		return false
	var payload: Dictionary = {
		"version": CHECKPOINT_FORMAT_VERSION,
		"saved_unix_time": Time.get_unix_time_from_system(),
		"reason": reason,
		"snapshot": game.build_network_snapshot(),
	}
	var save_file: FileAccess = FileAccess.open(CHECKPOINT_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		if show_feedback:
			game.status_message = "Failed to write checkpoint."
			game.update_hud()
		return false
	save_file.store_var(payload, false)
	if show_feedback:
		game.status_message = "Checkpoint saved."
		game.update_hud()
	return true

static func load_checkpoint(game: Node, show_feedback: bool = true) -> bool:
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		if show_feedback:
			game.status_message = "Only the host can load a checkpoint."
			game.update_hud()
		return false
	if not checkpoint_exists(game):
		if show_feedback:
			game.status_message = "No checkpoint found."
			game.update_hud()
		return false
	var save_file: FileAccess = FileAccess.open(CHECKPOINT_FILE_PATH, FileAccess.READ)
	if save_file == null:
		if show_feedback:
			game.status_message = "Failed to read checkpoint."
			game.update_hud()
		return false
	var payload_variant: Variant = save_file.get_var(false)
	if typeof(payload_variant) != TYPE_DICTIONARY:
		if show_feedback:
			game.status_message = "Checkpoint is invalid."
			game.update_hud()
		return false
	var payload: Dictionary = payload_variant
	var snapshot: Dictionary = Dictionary(payload.get("snapshot", {})).duplicate(true)
	if snapshot.is_empty():
		if show_feedback:
			game.status_message = "Checkpoint has no world state."
			game.update_hud()
		return false

	# Rebuild runtime nodes first, then apply the serialized world snapshot.
	game.clear_room_action_hold()
	game.close_room_action_menu()
	game.close_merchant_overlay()
	game.close_research_overlay()
	if game.inventory_overlay != null and game.inventory_overlay.visible:
		game.clear_inventory_session(true)
	game.build_dungeon(false)
	game.spawn_heroes()
	game.apply_network_snapshot(snapshot)
	game.assign_multiplayer_hero_owners_after_floor_transition()
	game.set_hero_select_overlay_visible(not game.lobby_game_started)
	game.selected_room = game.crystal_room if not game.rooms.has(game.selected_room) else game.selected_room
	game.ensure_valid_selected_hero()
	game.center_camera()
	if show_feedback:
		game.status_message = "Checkpoint loaded."
		game.update_hud()
	game.update_network_ui()
	game.queue_redraw()
	if game.multiplayer_session_active() and game.multiplayer.is_server():
		game.broadcast_network_snapshot()
	return true

static func start_new_game(game: Node) -> void:
	if game.multiplayer_session_active() and not game.multiplayer.is_server():
		game.status_message = "Only the host can start a new game."
		game.update_hud()
		return
	game.clear_room_action_hold()
	game.close_room_action_menu()
	game.close_merchant_overlay()
	game.close_research_overlay()
	if game.inventory_overlay != null and game.inventory_overlay.visible:
		game.clear_inventory_session(true)
	game.build_dungeon(true)
	game.spawn_heroes()
	if game.multiplayer_session_active() and game.multiplayer.is_server():
		game.redistribute_multiplayer_hero_owners()
	else:
		game.reset_hero_owner_peer_ids()
	game.sync_lobby_peer_ready_states(true)
	game.lobby_game_started = false
	game.selected_room = game.crystal_room
	game.ensure_valid_selected_hero()
	game.center_camera()
	game.status_message = "New game started."
	game.set_hero_select_overlay_visible(true)
	game.update_hud()
	game.update_network_ui()
	game.queue_redraw()
	if game.multiplayer_session_active() and game.multiplayer.is_server():
		game.broadcast_network_snapshot()
