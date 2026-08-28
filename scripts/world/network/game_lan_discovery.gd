extends RefCounted

const DISCOVERY_PROTOCOL_VERSION: int = 1

static func start_listening(game: Node) -> void:
	if game.network_discovery_listener != null or game.multiplayer_session_active():
		return
	var listener: PacketPeerUDP = PacketPeerUDP.new()
	if listener.bind(game.NETWORK_DISCOVERY_PORT) != OK:
		return
	game.network_discovery_listener = listener

static func stop_listening(game: Node) -> void:
	if game.network_discovery_listener != null:
		game.network_discovery_listener.close()
		game.network_discovery_listener = null
	if not game.network_discovered_hosts.is_empty():
		game.network_discovered_hosts.clear()
		refresh_lan_host_selector(game)

static func start_announcing(game: Node) -> void:
	if game.network_discovery_broadcaster != null:
		return
	var broadcaster: PacketPeerUDP = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	game.network_discovery_broadcaster = broadcaster
	game.network_discovery_announce_timer = 0.0

static func stop_announcing(game: Node) -> void:
	if game.network_discovery_broadcaster != null:
		game.network_discovery_broadcaster.close()
		game.network_discovery_broadcaster = null

static func advance(game: Node, delta: float) -> void:
	if game.multiplayer_session_active() and game.multiplayer.is_server():
		stop_listening(game)
		start_announcing(game)
		game.network_discovery_announce_timer -= delta
		if game.network_discovery_announce_timer <= 0.0:
			announce_host(game)
			game.network_discovery_announce_timer = game.NETWORK_DISCOVERY_ANNOUNCE_INTERVAL
		return
	stop_announcing(game)
	if game.multiplayer_session_active():
		stop_listening(game)
		return
	start_listening(game)
	poll_for_hosts(game)
	remove_expired_hosts(game)

static func announce_host(game: Node) -> void:
	if game.network_discovery_broadcaster == null:
		return
	var announcement: Dictionary = {
		"protocol": DISCOVERY_PROTOCOL_VERSION,
		"port": game.NETWORK_PORT,
		"players": 1 + game.multiplayer.get_peers().size(),
		"max_players": game.HERO_COUNT,
		"in_progress": game.lobby_game_started,
	}
	game.network_discovery_broadcaster.set_dest_address("255.255.255.255", game.NETWORK_DISCOVERY_PORT)
	game.network_discovery_broadcaster.put_packet(JSON.stringify(announcement).to_utf8_buffer())

static func poll_for_hosts(game: Node) -> void:
	if game.network_discovery_listener == null:
		return
	var changed: bool = false
	while game.network_discovery_listener.get_available_packet_count() > 0:
		var packet: PackedByteArray = game.network_discovery_listener.get_packet()
		var parser: JSON = JSON.new()
		if parser.parse(packet.get_string_from_utf8()) != OK or not parser.data is Dictionary:
			continue
		var announcement: Dictionary = parser.data
		if int(announcement.get("protocol", -1)) != DISCOVERY_PROTOCOL_VERSION:
			continue
		var host_port: int = int(announcement.get("port", -1))
		if host_port != game.NETWORK_PORT:
			continue
		var host_address: String = game.network_discovery_listener.get_packet_ip()
		if host_address.is_empty():
			continue
		var host_key: String = "%s:%d" % [host_address, host_port]
		announcement["address"] = host_address
		announcement["last_seen"] = Time.get_ticks_msec()
		game.network_discovered_hosts[host_key] = announcement
		changed = true
	if changed:
		refresh_lan_host_selector(game)

static func remove_expired_hosts(game: Node) -> void:
	var now: int = Time.get_ticks_msec()
	var changed: bool = false
	for host_key_variant in game.network_discovered_hosts.keys():
		var host_key: String = String(host_key_variant)
		var host: Dictionary = Dictionary(game.network_discovered_hosts[host_key])
		if now - int(host.get("last_seen", 0)) <= game.NETWORK_DISCOVERY_HOST_TIMEOUT_MS:
			continue
		game.network_discovered_hosts.erase(host_key)
		changed = true
	if changed:
		refresh_lan_host_selector(game)

static func refresh_lan_host_selector(game: Node) -> void:
	if game.network_discovery_option == null:
		return
	game.network_discovery_option.clear()
	game.network_discovery_option.add_item("LAN games")
	var hosts: Array[Dictionary] = []
	for host_variant in game.network_discovered_hosts.values():
		hosts.append(Dictionary(host_variant))
	hosts.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return String(left.get("address", "")) < String(right.get("address", "")))
	for host in hosts:
		var state: String = "In progress" if bool(host.get("in_progress", false)) else "Lobby"
		var label: String = "%s  %d/%d  %s" % [String(host.get("address", "")), int(host.get("players", 0)), int(host.get("max_players", 0)), state]
		game.network_discovery_option.add_item(label)
		game.network_discovery_option.set_item_metadata(game.network_discovery_option.item_count - 1, String(host.get("address", "")))

static func on_host_selected(game: Node, selected_index: int) -> void:
	if game.network_discovery_option == null or selected_index <= 0 or game.network_address_input == null:
		return
	var address: String = String(game.network_discovery_option.get_item_metadata(selected_index))
	if address.is_empty():
		return
	game.network_address_input.text = address
	game.network_discovery_option.select(0)