extends RefCounted

const GAME_HERO_PROFILE_FLOW: GDScript = preload("res://scripts/world/game_hero_profile_flow.gd")

static func setup_multiplayer_callbacks(game: Node) -> void:
	game.multiplayer.peer_connected.connect(game._on_multiplayer_peer_connected)
	game.multiplayer.peer_disconnected.connect(game._on_multiplayer_peer_disconnected)
	game.multiplayer.connected_to_server.connect(game._on_multiplayer_connected_to_server)
	game.multiplayer.connection_failed.connect(game._on_multiplayer_connection_failed)
	game.multiplayer.server_disconnected.connect(game._on_multiplayer_server_disconnected)

static func multiplayer_session_active(game: Node) -> bool:
	return game.multiplayer.multiplayer_peer != null

static func authoritative_simulation_active(game: Node) -> bool:
	return not multiplayer_session_active(game) or game.multiplayer.is_server()

static func local_peer_id(game: Node) -> int:
	if multiplayer_session_active(game):
		return game.multiplayer.get_unique_id()
	return game.NETWORK_HOST_PEER_ID

static func reset_hero_owner_peer_ids(game: Node) -> void:
	game.hero_owner_peer_ids.clear()
	for _hero_index in range(game.HERO_COUNT):
		game.hero_owner_peer_ids.append(game.NETWORK_HOST_PEER_ID)
	ensure_valid_selected_hero(game)
	sync_lobby_peer_ready_states(game, not game.lobby_game_started)

static func hero_owner_peer_id(game: Node, hero_index: int) -> int:
	if hero_index < 0 or hero_index >= game.hero_owner_peer_ids.size():
		return game.NETWORK_HOST_PEER_ID
	return int(game.hero_owner_peer_ids[hero_index])

static func can_local_control_hero_index(game: Node, hero_index: int) -> bool:
	if hero_index < 0 or hero_index >= game.HERO_COUNT:
		return false
	if not multiplayer_session_active(game):
		return true
	return hero_owner_peer_id(game, hero_index) == local_peer_id(game)

static func first_controlled_hero_index_for_peer(game: Node, peer_id: int) -> int:
	for hero_index in range(game.hero_owner_peer_ids.size()):
		if int(game.hero_owner_peer_ids[hero_index]) == peer_id:
			return hero_index
	return -1

static func controlled_hero_indices_for_peer(game: Node, peer_id: int) -> Array[int]:
	var controlled_indices: Array[int] = []
	for hero_index in range(game.hero_owner_peer_ids.size()):
		if int(game.hero_owner_peer_ids[hero_index]) == peer_id:
			controlled_indices.append(hero_index)
	return controlled_indices

static func first_local_controlled_hero_index(game: Node) -> int:
	for hero_index in controlled_hero_indices_for_peer(game, local_peer_id(game)):
		var hero: Variant = game.heroes[hero_index] if hero_index >= 0 and hero_index < game.heroes.size() else null
		if game.hero_is_active(hero):
			return hero_index
	return -1

static func ensure_valid_selected_hero(game: Node) -> void:
	if can_local_control_hero_index(game, game.selected_hero_index) and game.hero_is_active(game.selected_hero()):
		return
	var fallback_index: int = first_local_controlled_hero_index(game)
	if fallback_index >= 0:
		game.selected_hero_index = fallback_index
	else:
		game.selected_hero_index = clampi(game.selected_hero_index, 0, max(game.HERO_COUNT - 1, 0))

static func room_actions_allowed_for_local_peer(game: Node) -> bool:
	return game.selected_hero() != null and can_local_control_hero_index(game, game.selected_hero_index)

static func inventory_actions_allowed_for_local_peer(game: Node) -> bool:
	return game.selected_hero() != null and can_local_control_hero_index(game, game.selected_hero_index)

static func multiplayer_status_text(game: Node) -> String:
	if not multiplayer_session_active(game):
		return "Offline"
	var local_heroes: Array[int] = controlled_hero_indices_for_peer(game, local_peer_id(game))
	var local_hero_text: String = ""
	if not local_heroes.is_empty():
		var labels: Array[String] = []
		for hero_index in local_heroes:
			labels.append("H%d" % (hero_index + 1))
		local_hero_text = " %s" % ",".join(labels)
	if game.multiplayer.is_server():
		return "Host %d/%d%s" % [1 + game.multiplayer.get_peers().size(), game.HERO_COUNT, local_hero_text]
	if not local_heroes.is_empty():
		return "Client%s" % local_hero_text
	return "Client"

static func connected_session_peer_ids(game: Node) -> Array[int]:
	var peer_ids: Array[int] = []
	var candidate_ids: Array[int] = [game.NETWORK_HOST_PEER_ID]
	if multiplayer_session_active(game):
		var local_id: int = game.multiplayer.get_unique_id()
		if local_id > 0:
			candidate_ids.append(local_id)
		for peer_id_variant in game.multiplayer.get_peers():
			candidate_ids.append(int(peer_id_variant))
	for peer_id in candidate_ids:
		if not peer_ids.has(peer_id):
			peer_ids.append(peer_id)
	peer_ids.sort()
	return peer_ids

static func sync_lobby_peer_ready_states(game: Node, reset_ready: bool = false) -> void:
	var next_ready: Dictionary = {}
	for peer_id in connected_session_peer_ids(game):
		next_ready[peer_id] = false if reset_ready else bool(game.lobby_peer_ready.get(peer_id, false))
	game.lobby_peer_ready = next_ready

static func local_peer_ready_state(game: Node) -> bool:
	return bool(game.lobby_peer_ready.get(local_peer_id(game), false))

static func all_lobby_players_ready(game: Node) -> bool:
	var peer_ids: Array[int] = connected_session_peer_ids(game)
	if peer_ids.is_empty():
		return false
	for peer_id in peer_ids:
		if not bool(game.lobby_peer_ready.get(peer_id, false)):
			return false
	return true

static func player_display_name(game: Node, peer_id: int) -> String:
	if not multiplayer_session_active(game):
		return "Player"
	var label: String = "Host" if peer_id == game.NETWORK_HOST_PEER_ID else "Player %d" % peer_id
	if peer_id == local_peer_id(game):
		label += " (You)"
	return label

static func lobby_hero_label(game: Node, hero_index: int) -> String:
	var class_id: String = game.hero_profile_class_id(hero_index)
	var class_label: String = String(game.hero_class_definition(class_id).get("name", class_id.capitalize()))
	if hero_index < game.heroes.size():
		var hero: Variant = game.heroes[hero_index]
		if hero != null and is_instance_valid(hero):
			class_label = String(game.hero_class_definition(hero.hero_class_id).get("name", hero.hero_class_id.capitalize()))
	return "H%d %s%s" % [hero_index + 1, class_label, " [Dead]" if bool(game.hero_profiles[hero_index].get("dead", false)) else ""]

static func rebuild_hero_select_player_list(game: Node) -> void:
	if game.hero_select_player_list == null:
		return
	for child in game.hero_select_player_list.get_children():
		child.queue_free()
	for peer_id in connected_session_peer_ids(game):
		var row_panel: PanelContainer = PanelContainer.new()
		game.hero_select_player_list.add_child(row_panel)
		var row_vbox: VBoxContainer = VBoxContainer.new()
		row_vbox.add_theme_constant_override("separation", 6)
		row_panel.add_child(row_vbox)
		var title_label: Label = Label.new()
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.text = player_display_name(game, peer_id)
		row_vbox.add_child(title_label)
		var hero_lines: Array[String] = []
		for hero_index in controlled_hero_indices_for_peer(game, peer_id):
			hero_lines.append(lobby_hero_label(game, hero_index))
		var heroes_label: Label = Label.new()
		heroes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heroes_label.add_theme_font_size_override("font_size", 14)
		heroes_label.text = "Heroes: %s" % (", ".join(hero_lines) if not hero_lines.is_empty() else "None")
		row_vbox.add_child(heroes_label)
		var ready: bool = bool(game.lobby_peer_ready.get(peer_id, false))
		var status_label: Label = Label.new()
		status_label.add_theme_font_size_override("font_size", 14)
		status_label.add_theme_color_override("font_color", Color("8df4b2") if ready else Color("d6e4ee"))
		status_label.text = "Ready" if ready else "Not Ready"
		row_vbox.add_child(status_label)
		if peer_id == local_peer_id(game) and not game.lobby_game_started:
			var ready_button: Button = Button.new()
			ready_button.custom_minimum_size = Vector2(0.0, 36.0)
			ready_button.add_theme_font_size_override("font_size", 14)
			ready_button.text = "Unready" if ready else "Ready"
			ready_button.pressed.connect(game._on_hero_select_ready_button_pressed)
			row_vbox.add_child(ready_button)

static func update_network_ui(game: Node) -> void:
	if game.network_status_label == null:
		return
	game.network_status_label.text = multiplayer_status_text(game)
	var active: bool = multiplayer_session_active(game)
	if game.network_address_input != null:
		game.network_address_input.editable = not active
	if game.network_host_button != null:
		game.network_host_button.disabled = active
	if game.network_join_button != null:
		game.network_join_button.disabled = active
	if game.network_disconnect_button != null:
		game.network_disconnect_button.disabled = not active
	if game.hero_select_toggle_button != null:
		game.hero_select_toggle_button.text = "Close" if game.hero_select_overlay != null and game.hero_select_overlay.visible else "Lobby"
		game.hero_select_toggle_button.visible = game.lobby_game_started or (game.hero_select_overlay != null and game.hero_select_overlay.visible)
	update_hero_select_overlay(game)

static func set_hero_select_overlay_visible(game: Node, visible: bool) -> void:
	if game.hero_select_overlay == null:
		return
	if visible:
		game.clear_room_action_hold()
		game.close_room_action_menu()
		game.close_merchant_overlay()
		game.cancel_room_action_camera_focus()
		if game.inventory_overlay != null and game.inventory_overlay.visible:
			game.clear_inventory_session(true)
		game.build_menu_open = false
		game.clear_build_mode()
	game.hero_select_overlay.visible = visible
	if game.hero_select_toggle_button != null:
		game.hero_select_toggle_button.text = "Close" if visible else "Lobby"
	update_hero_select_overlay(game)
	game.update_hud()

static func update_hero_select_overlay(game: Node) -> void:
	if game.hero_select_overlay == null:
		return
	game.ensure_hero_profiles()
	game.hero_select_active_index = clampi(game.hero_select_active_index, 0, game.HERO_COUNT - 1)
	var selection_locked: bool = game.hero_class_selection_locked()
	if game.hero_select_title_label != null:
		game.hero_select_title_label.text = "Lobby"
	if game.hero_select_start_button != null:
		if not game.lobby_game_started:
			if multiplayer_session_active(game) and not game.multiplayer.is_server():
				game.hero_select_start_button.text = "Waiting for Host"
				game.hero_select_start_button.disabled = true
			else:
				game.hero_select_start_button.text = "Start Game"
				game.hero_select_start_button.disabled = not all_lobby_players_ready(game)
		else:
			game.hero_select_start_button.text = "Close Lobby"
			game.hero_select_start_button.disabled = false
	var host_actions_allowed: bool = not multiplayer_session_active(game) or game.multiplayer.is_server()
	if game.hero_select_new_game_button != null:
		game.hero_select_new_game_button.disabled = not host_actions_allowed
		game.hero_select_new_game_button.text = "New Game" if host_actions_allowed else "Host: New Game"
	if game.hero_select_load_game_button != null:
		var has_checkpoint: bool = game.checkpoint_exists()
		game.hero_select_load_game_button.disabled = (not host_actions_allowed) or (not has_checkpoint)
		if not host_actions_allowed:
			game.hero_select_load_game_button.text = "Host: Load Game"
		elif has_checkpoint:
			game.hero_select_load_game_button.text = "Load Game"
		else:
			game.hero_select_load_game_button.text = "Load Game (No Save)"
	for hero_index in range(game.HERO_COUNT):
		if not game.hero_select_cards.has(hero_index):
			continue
		var card: Dictionary = game.hero_select_cards[hero_index]
		var class_id: String = game.hero_profile_class_id(hero_index)
		var display_name: String = String(game.hero_profiles[hero_index].get("name", game.hero_display_name(hero_index, class_id)))
		var hero: Variant = game.heroes[hero_index] if hero_index < game.heroes.size() else null
		if hero != null and is_instance_valid(hero):
			class_id = hero.hero_class_id
			display_name = hero.hero_name
			game.hero_profiles[hero_index]["class_id"] = class_id
			game.hero_profiles[hero_index]["name"] = display_name
		var tile_button: Button = card.get("button", null)
		if tile_button != null:
			var tile_owner: String = "You" if not multiplayer_session_active(game) or can_local_control_hero_index(game, hero_index) else "Peer %d" % hero_owner_peer_id(game, hero_index)
			var dead_label: String = "\nDEAD" if bool(game.hero_profiles[hero_index].get("dead", false)) else ""
			tile_button.icon = GAME_HERO_PROFILE_FLOW.hero_portrait_texture(game, class_id)
			tile_button.text = "H%d\n%s\n%s%s" % [hero_index + 1, String(game.hero_class_definition(class_id).get("name", class_id.capitalize())), tile_owner, dead_label]
			tile_button.button_pressed = hero_index == game.hero_select_active_index
	var active_class_id: String = game.hero_profile_class_id(game.hero_select_active_index)
	var active_display_name: String = String(game.hero_profiles[game.hero_select_active_index].get("name", game.hero_display_name(game.hero_select_active_index, active_class_id)))
	var active_hero: Variant = game.heroes[game.hero_select_active_index] if game.hero_select_active_index < game.heroes.size() else null
	if active_hero != null and is_instance_valid(active_hero):
		active_class_id = active_hero.hero_class_id
		active_display_name = active_hero.hero_name
	if game.hero_select_detail_portrait != null:
		game.hero_select_detail_portrait.texture = GAME_HERO_PROFILE_FLOW.hero_portrait_texture(game, active_class_id)
	var active_locally_owned: bool = can_local_control_hero_index(game, game.hero_select_active_index)
	var owner_text: String = "You" if not multiplayer_session_active(game) or active_locally_owned else "Peer %d" % hero_owner_peer_id(game, game.hero_select_active_index)
	if game.hero_select_detail_title_label != null:
		game.hero_select_detail_title_label.text = "H%d  %s%s" % [game.hero_select_active_index + 1, active_display_name, "  [Dead]" if bool(game.hero_profiles[game.hero_select_active_index].get("dead", false)) else ""]
	if game.hero_select_detail_summary_label != null:
		var detail_lines: Array[String] = game.hero_class_summary_lines(active_class_id)
		detail_lines.append("Owner: %s" % owner_text)
		detail_lines.append("Selected for slot H%d." % [game.hero_select_active_index + 1])
		game.hero_select_detail_summary_label.text = "\n".join(detail_lines)
	if game.hero_select_detail_hint_label != null:
		if selection_locked:
			game.hero_select_detail_hint_label.text = "Class choice is locked after the first opened door."
		elif active_locally_owned:
			game.hero_select_detail_hint_label.text = "Tap a class below to set this hero before the run starts."
		else:
			game.hero_select_detail_hint_label.text = "You can inspect this hero here, but only its owner can change the class."
	for class_id_variant in game.HERO_CLASS_ORDER:
		var option_class_id: String = String(class_id_variant)
		var class_button: Button = game.hero_select_detail_class_buttons.get(option_class_id, null)
		if class_button == null:
			continue
		class_button.button_pressed = option_class_id == active_class_id
		class_button.disabled = selection_locked or not active_locally_owned or local_peer_ready_state(game)
	rebuild_hero_select_player_list(game)

static func on_hero_select_toggle_button_pressed(game: Node) -> void:
	set_hero_select_overlay_visible(game, game.hero_select_overlay == null or not game.hero_select_overlay.visible)

static func on_hero_select_card_pressed(game: Node, hero_index: int) -> void:
	game.hero_select_active_index = clampi(hero_index, 0, game.HERO_COUNT - 1)
	update_hero_select_overlay(game)

static func on_hero_select_detail_class_pressed(game: Node, class_id: String) -> void:
	on_hero_select_class_pressed(game, game.hero_select_active_index, class_id)

static func on_hero_select_ready_button_pressed(game: Node) -> void:
	if game.lobby_game_started:
		return
	var next_ready: bool = not local_peer_ready_state(game)
	if multiplayer_session_active(game) and not authoritative_simulation_active(game):
		game.server_request_lobby_ready.rpc_id(game.NETWORK_HOST_PEER_ID, next_ready)
		return
	game.lobby_peer_ready[local_peer_id(game)] = next_ready
	game.update_hud()
	if multiplayer_session_active(game) and game.multiplayer.is_server():
		game.broadcast_network_snapshot()

static func on_hero_select_class_pressed(game: Node, hero_index: int, class_id: String) -> void:
	if hero_index < 0 or hero_index >= game.HERO_COUNT:
		return
	game.hero_select_active_index = hero_index
	if not game.can_local_edit_hero_class(hero_index):
		update_hero_select_overlay(game)
		return
	if multiplayer_session_active(game) and not authoritative_simulation_active(game):
		game.server_request_hero_class.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, class_id)
		return
	game.lobby_peer_ready[local_peer_id(game)] = false
	game.set_hero_profile_class(hero_index, class_id, true)
	update_hero_select_overlay(game)
	game.update_hud()
	if multiplayer_session_active(game) and game.multiplayer.is_server():
		game.broadcast_network_snapshot()

static func on_hero_select_start_button_pressed(game: Node) -> void:
	if not game.lobby_game_started:
		if multiplayer_session_active(game) and not game.multiplayer.is_server():
			return
		if not all_lobby_players_ready(game):
			game.status_message = "Everyone must be ready before the run can start."
			game.update_hud()
			return
		game.lobby_game_started = true
		game.status_message = "The run begins."
		set_hero_select_overlay_visible(game, false)
		if multiplayer_session_active(game) and game.multiplayer.is_server():
			game.broadcast_network_snapshot()
		return
	set_hero_select_overlay_visible(game, false)

static func on_hero_select_new_game_button_pressed(game: Node) -> void:
	game.start_new_game()

static func on_hero_select_load_game_button_pressed(game: Node) -> void:
	game.load_checkpoint(true)

static func hero_index_labels(hero_indices: Array[int]) -> String:
	var labels: Array[String] = []
	for hero_index in hero_indices:
		labels.append("H%d" % (hero_index + 1))
	return ",".join(labels)

static func assign_claimable_heroes_to_peer(game: Node, peer_id: int) -> Array[int]:
	var assigned: Array[int] = []
	var remaining_claims: Array[int] = []
	for hero_index_variant in game.rejoin_claimable_hero_indices:
		var hero_index: int = int(hero_index_variant)
		if hero_index < 0 or hero_index >= game.HERO_COUNT:
			continue
		if int(game.hero_owner_peer_ids[hero_index]) == game.NETWORK_HOST_PEER_ID:
			game.hero_owner_peer_ids[hero_index] = peer_id
			assigned.append(hero_index)
		else:
			remaining_claims.append(hero_index)
	game.rejoin_claimable_hero_indices = remaining_claims
	return assigned

static func assign_host_hero_to_peer_for_live_join(game: Node, peer_id: int) -> Array[int]:
	for hero_index in range(game.HERO_COUNT - 1, -1, -1):
		if int(game.hero_owner_peer_ids[hero_index]) != game.NETWORK_HOST_PEER_ID:
			continue
		game.hero_owner_peer_ids[hero_index] = peer_id
		return [hero_index]
	return []

static func redistribute_multiplayer_hero_owners(game: Node) -> void:
	reset_hero_owner_peer_ids(game)
	game.rejoin_claimable_hero_indices.clear()
	if not multiplayer_session_active(game):
		return
	var peer_ids: Array[int] = connected_session_peer_ids(game)
	if peer_ids.is_empty():
		return
	var participant_count: int = peer_ids.size()
	var base_hero_count: int = game.HERO_COUNT / participant_count
	var extra_hero_count: int = game.HERO_COUNT % participant_count
	var hero_cursor: int = 0
	for participant_index in range(peer_ids.size()):
		var owned_count: int = base_hero_count
		if participant_index < extra_hero_count:
			owned_count += 1
		for _owned_slot in range(owned_count):
			if hero_cursor >= game.HERO_COUNT:
				break
			game.hero_owner_peer_ids[hero_cursor] = peer_ids[participant_index]
			hero_cursor += 1
	ensure_valid_selected_hero(game)

static func start_host_session(game: Node) -> void:
	if multiplayer_session_active(game):
		return
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var create_error: int = peer.create_server(game.NETWORK_PORT, game.NETWORK_MAX_CLIENTS)
	if create_error != OK:
		game.status_message = "Host failed on port %d." % game.NETWORK_PORT
		game.update_hud()
		return
	game.multiplayer.multiplayer_peer = peer
	redistribute_multiplayer_hero_owners(game)
	if not game.lobby_game_started:
		sync_lobby_peer_ready_states(game, true)
	game.network_snapshot_timer = 0.0
	game.status_message = "Hosting co-op on port %d." % game.NETWORK_PORT
	ensure_valid_selected_hero(game)
	game.update_hud()
	update_network_ui(game)
	game.broadcast_network_snapshot()

static func join_host_session(game: Node, address_text: String) -> void:
	if multiplayer_session_active(game):
		return
	var target_address: String = address_text.strip_edges()
	if target_address == "":
		target_address = game.NETWORK_DEFAULT_ADDRESS
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var create_error: int = peer.create_client(target_address, game.NETWORK_PORT)
	if create_error != OK:
		game.status_message = "Join failed for %s:%d." % [target_address, game.NETWORK_PORT]
		game.update_hud()
		return
	game.multiplayer.multiplayer_peer = peer
	game.rejoin_claimable_hero_indices.clear()
	reset_hero_owner_peer_ids(game)
	if not game.lobby_game_started:
		sync_lobby_peer_ready_states(game, true)
	game.network_snapshot_timer = 0.0
	game.status_message = "Joining %s:%d..." % [target_address, game.NETWORK_PORT]
	game.update_hud()
	update_network_ui(game)

static func stop_network_session(game: Node, reason: String = "Returned to offline mode.") -> void:
	if game.multiplayer.multiplayer_peer != null:
		game.multiplayer.multiplayer_peer.close()
		game.multiplayer.multiplayer_peer = null
	game.rejoin_claimable_hero_indices.clear()
	reset_hero_owner_peer_ids(game)
	sync_lobby_peer_ready_states(game, not game.lobby_game_started)
	game.network_snapshot_timer = 0.0
	game.status_message = reason
	ensure_valid_selected_hero(game)
	game.update_hud()
	update_network_ui(game)

static func on_multiplayer_peer_connected(game: Node, peer_id: int) -> void:
	if not game.multiplayer.is_server():
		return
	var assigned_heroes: Array[int] = []
	if game.lobby_game_started:
		assigned_heroes = assign_claimable_heroes_to_peer(game, peer_id)
		if assigned_heroes.is_empty():
			assigned_heroes = assign_host_hero_to_peer_for_live_join(game, peer_id)
		if assigned_heroes.is_empty():
			game.status_message = "Peer %d joined, but no hero role is currently available." % peer_id
		else:
			game.status_message = "Peer %d rejoined and took %s." % [peer_id, hero_index_labels(assigned_heroes)]
	else:
		redistribute_multiplayer_hero_owners(game)
		sync_lobby_peer_ready_states(game, true)
		assigned_heroes = controlled_hero_indices_for_peer(game, peer_id)
		game.status_message = "Peer %d joined and took %s." % [peer_id, hero_index_labels(assigned_heroes)]
	ensure_valid_selected_hero(game)
	game.update_hud()
	update_network_ui(game)
	game.broadcast_network_snapshot()

static func on_multiplayer_peer_disconnected(game: Node, peer_id: int) -> void:
	if game.multiplayer.is_server():
		if game.lobby_game_started:
			var claimable_now: Array[int] = []
			for hero_index in range(game.HERO_COUNT):
				if int(game.hero_owner_peer_ids[hero_index]) != peer_id:
					continue
				game.hero_owner_peer_ids[hero_index] = game.NETWORK_HOST_PEER_ID
				if not game.rejoin_claimable_hero_indices.has(hero_index):
					game.rejoin_claimable_hero_indices.append(hero_index)
				claimable_now.append(hero_index)
			game.rejoin_claimable_hero_indices.sort()
			if claimable_now.is_empty():
				game.status_message = "Peer %d disconnected." % peer_id
			else:
				game.status_message = "Peer %d disconnected. %s can be reclaimed by a rejoining player." % [peer_id, hero_index_labels(claimable_now)]
		else:
			redistribute_multiplayer_hero_owners(game)
			sync_lobby_peer_ready_states(game, true)
			game.status_message = "Peer %d disconnected." % peer_id
		ensure_valid_selected_hero(game)
		game.update_hud()
		update_network_ui(game)
		game.broadcast_network_snapshot()

static func on_multiplayer_connected_to_server(game: Node) -> void:
	game.status_message = "Connected to host. Waiting for room state."
	game.update_hud()
	update_network_ui(game)

static func on_multiplayer_connection_failed(game: Node) -> void:
	stop_network_session(game, "Connection failed.")

static func on_multiplayer_server_disconnected(game: Node) -> void:
	stop_network_session(game, "Host disconnected.")

static func on_network_host_button_pressed(game: Node) -> void:
	start_host_session(game)

static func on_network_join_button_pressed(game: Node) -> void:
	join_host_session(game, game.network_address_input.text if game.network_address_input != null else game.NETWORK_DEFAULT_ADDRESS)

static func on_network_disconnect_button_pressed(game: Node) -> void:
	stop_network_session(game)
