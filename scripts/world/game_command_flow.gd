extends RefCounted

const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/inventory/game_inventory_item_flow.gd")
const RESOURCE_TRADE_TRANSFER_AMOUNT: int = 5

static func action_suffix_int(action_id: String, prefix: String) -> int:
	if not action_id.begins_with(prefix):
		return -1
	var suffix: String = action_id.trim_prefix(prefix)
	if not suffix.is_valid_int():
		return -1
	return int(suffix)

static func hero_inventory_item_index_by_uid(hero: Variant, item_uid: int) -> int:
	if hero == null or not is_instance_valid(hero):
		return -1
	for item_index in range(hero.inventory_items.size()):
		if int(Dictionary(hero.inventory_items[item_index]).get("uid", -1)) == item_uid:
			return item_index
	return -1

static func room_offer_index_by_uid(room: Dictionary, list_key: String, offer_uid: int) -> int:
	for offer_index in range(Array(room.get(list_key, [])).size()):
		if int(Dictionary(Array(room.get(list_key, []))[offer_index]).get("offer_uid", -1)) == offer_uid:
			return offer_index
	return -1

static func execute_room_merchant_buy_for_hero(game: Node, hero: Variant, room_coord: Vector2i, offer_uid: int) -> bool:
	if hero == null or not is_instance_valid(hero) or not game.rooms.has(room_coord):
		return false
	if not GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord):
		game.status_message = "No merchant is available in %s." % game.room_title(room_coord)
		game.update_hud()
		return false
	GAME_INVENTORY_ITEM_FLOW.ensure_room_merchant_state(game, room_coord)
	var room: Dictionary = game.rooms[room_coord]
	var stock: Array = Array(room.get("merchant_stock", []))
	var offer_index: int = room_offer_index_by_uid(room, "merchant_stock", offer_uid)
	if offer_index < 0:
		game.status_message = "That offer is no longer available."
		game.update_hud()
		return false
	var offer: Dictionary = Dictionary(stock[offer_index]).duplicate(true)
	var offer_kind: String = GAME_INVENTORY_ITEM_FLOW.merchant_offer_kind(offer)
	var item: Dictionary = Dictionary(offer.get("item", {})).duplicate(true)
	var item_name: String = GAME_INVENTORY_ITEM_FLOW.merchant_offer_item_name(game, offer)
	var price: int = GAME_INVENTORY_ITEM_FLOW.merchant_offer_price(game, offer)
	var resource_id: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_id_for_room(game, room_coord)
	var resource_label: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_label(game, resource_id)
	if offer_kind != "item":
		game.status_message = "Only item offers can be purchased from merchants."
		game.update_hud()
		return false
	if resource_id == "":
		game.status_message = "Merchant setup is invalid."
		game.update_hud()
		return false
	if GAME_INVENTORY_ITEM_FLOW.merchant_resource_amount(game, resource_id) < price:
		game.status_message = "Need %d %s to buy %s." % [price, resource_label, item_name]
		game.update_hud()
		return false
	if not game.add_item_to_hero_inventory(hero, item):
		game.status_message = "%s has no inventory space for %s." % [hero.hero_name, item_name]
		game.update_hud()
		return false
	if not GAME_INVENTORY_ITEM_FLOW.merchant_spend_resource(game, resource_id, price):
		game.status_message = "Could not spend %s for that purchase." % resource_label
		game.update_hud()
		return false
	stock.remove_at(offer_index)
	room["merchant_stock"] = stock
	game.status_message = "%s bought %s for %d %s." % [hero.hero_name, item_name, price, resource_label]
	game.update_hud()
	game.queue_redraw()
	return true

static func execute_room_merchant_sell_for_hero(game: Node, hero: Variant, room_coord: Vector2i, item_uid: int) -> bool:
	if hero == null or not is_instance_valid(hero) or not game.rooms.has(room_coord):
		return false
	if not GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord):
		game.status_message = "No merchant is available in %s." % game.room_title(room_coord)
		game.update_hud()
		return false
	GAME_INVENTORY_ITEM_FLOW.ensure_room_merchant_state(game, room_coord)
	var item_index: int = hero_inventory_item_index_by_uid(hero, item_uid)
	if item_index < 0:
		game.status_message = "That item can no longer be sold."
		game.update_hud()
		return false
	var sold_item: Dictionary = Dictionary(hero.inventory_items[item_index]).duplicate(true)
	var item_name: String = String(game.item_defs.get(String(sold_item.get("item_id", "")), {}).get("name", String(sold_item.get("item_id", "item")).capitalize()))
	var sell_price: int = GAME_INVENTORY_ITEM_FLOW.merchant_item_sell_price(game, sold_item)
	var buyback_price: int = GAME_INVENTORY_ITEM_FLOW.merchant_item_full_price(game, sold_item)
	var resource_id: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_id_for_room(game, room_coord)
	var resource_label: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_label(game, resource_id)
	if resource_id == "":
		game.status_message = "Merchant setup is invalid."
		game.update_hud()
		return false
	hero.inventory_items.remove_at(item_index)
	game.apply_inventory_stats_to_hero(hero)
	GAME_INVENTORY_ITEM_FLOW.merchant_add_resource(game, resource_id, sell_price)
	sold_item.erase("anchor")
	sold_item.erase("position")
	var room: Dictionary = game.rooms[room_coord]
	var buyback: Array = Array(room.get("merchant_buyback", []))
	buyback.append({
		"offer_uid": int(sold_item.get("uid", -1)),
		"item": sold_item,
		"price": buyback_price,
		"sold_by_hero_index": int(hero.hero_index),
	})
	if buyback.size() > 24:
		buyback.pop_front()
	room["merchant_buyback"] = buyback
	room["merchant_buyback_doors_opened"] = game.doors_opened
	game.status_message = "%s sold %s for %d %s." % [hero.hero_name, item_name, sell_price, resource_label]
	game.update_hud()
	game.queue_redraw()
	return true

static func execute_room_merchant_buyback_for_hero(game: Node, hero: Variant, room_coord: Vector2i, offer_uid: int) -> bool:
	if hero == null or not is_instance_valid(hero) or not game.rooms.has(room_coord):
		return false
	if not GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord):
		game.status_message = "No merchant is available in %s." % game.room_title(room_coord)
		game.update_hud()
		return false
	GAME_INVENTORY_ITEM_FLOW.ensure_room_merchant_state(game, room_coord)
	var room: Dictionary = game.rooms[room_coord]
	var buyback: Array = Array(room.get("merchant_buyback", []))
	var offer_index: int = room_offer_index_by_uid(room, "merchant_buyback", offer_uid)
	if offer_index < 0:
		game.status_message = "That buyback offer expired."
		game.update_hud()
		return false
	var offer: Dictionary = Dictionary(buyback[offer_index]).duplicate(true)
	var item: Dictionary = Dictionary(offer.get("item", {})).duplicate(true)
	var item_name: String = String(game.item_defs.get(String(item.get("item_id", "")), {}).get("name", String(item.get("item_id", "item")).capitalize()))
	var buyback_price: int = int(offer.get("price", GAME_INVENTORY_ITEM_FLOW.merchant_item_full_price(game, item)))
	var resource_id: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_id_for_room(game, room_coord)
	var resource_label: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_label(game, resource_id)
	if resource_id == "":
		game.status_message = "Merchant setup is invalid."
		game.update_hud()
		return false
	if GAME_INVENTORY_ITEM_FLOW.merchant_resource_amount(game, resource_id) < buyback_price:
		game.status_message = "Need %d %s to buy back %s." % [buyback_price, resource_label, item_name]
		game.update_hud()
		return false
	if not game.add_item_to_hero_inventory(hero, item):
		game.status_message = "%s has no inventory space for %s." % [hero.hero_name, item_name]
		game.update_hud()
		return false
	if not GAME_INVENTORY_ITEM_FLOW.merchant_spend_resource(game, resource_id, buyback_price):
		game.status_message = "Could not spend %s for that buyback." % resource_label
		game.update_hud()
		return false
	buyback.remove_at(offer_index)
	room["merchant_buyback"] = buyback
	game.status_message = "%s bought back %s for %d %s." % [hero.hero_name, item_name, buyback_price, resource_label]
	game.update_hud()
	game.queue_redraw()
	return true

static func execute_room_resource_trade_for_hero(game: Node, hero: Variant, room_coord: Vector2i, target_hero_index: int, resource_id: String, amount: int) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if target_hero_index < 0 or target_hero_index >= game.heroes.size() or target_hero_index == int(hero.hero_index):
		game.status_message = "Choose another hero as a trade partner."
		game.update_hud()
		return false
	var target_hero: Variant = game.heroes[target_hero_index]
	if target_hero == null or not is_instance_valid(target_hero):
		game.status_message = "Trade target is unavailable."
		game.update_hud()
		return false
	if target_hero.current_room != room_coord:
		game.status_message = "%s is not in %s." % [target_hero.hero_name, game.room_title(room_coord)]
		game.update_hud()
		return false
	if resource_id != "food" and resource_id != "industry" and resource_id != "science" and resource_id != "dust":
		game.status_message = "That resource cannot be traded."
		game.update_hud()
		return false
	var resource_available: int = GAME_INVENTORY_ITEM_FLOW.merchant_resource_amount(game, resource_id)
	var trade_amount: int = mini(maxi(amount, 1), resource_available)
	if trade_amount <= 0:
		game.status_message = "No %s available to trade." % GAME_INVENTORY_ITEM_FLOW.merchant_resource_label(game, resource_id)
		game.update_hud()
		return false
	# Resources are pooled party-wide; this records an explicit hero-to-hero trade action.
	var resource_label: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_label(game, resource_id)
	game.status_message = "%s shared %d %s with %s." % [hero.hero_name, trade_amount, resource_label, target_hero.hero_name]
	game.add_resource_floating_text(hero.global_position + Vector2(0.0, -36.0), "-%d %s" % [trade_amount, resource_label], Color("f3d88f"))
	game.add_resource_floating_text(target_hero.global_position + Vector2(0.0, -36.0), "+%d %s" % [trade_amount, resource_label], Color("8bc1ff"))
	game.update_hud()
	game.queue_redraw()
	return true

static func clear_pending_room_loot_request(game: Node, hero_index: int = -1) -> void:
	if hero_index < 0:
		game.pending_room_loot_requests.clear()
		return
	game.pending_room_loot_requests.erase(hero_index)

static func clear_pending_room_action_request(game: Node, hero_index: int = -1) -> void:
	if hero_index < 0:
		game.pending_room_action_requests.clear()
		return
	game.pending_room_action_requests.erase(hero_index)

static func try_open_pending_room_loot_request(game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if game.inventory_overlay != null and game.inventory_overlay.visible:
		return false
	if not game.pending_room_loot_requests.has(hero.hero_index):
		return false
	if hero.pending_room != game.HERO_INVALID_ROOM or not hero.is_idle() or not hero.move_steps.is_empty():
		return false
	var loot_request: Dictionary = game.pending_room_loot_requests[hero.hero_index]
	var room_coord: Vector2i = loot_request.get("room", game.INVALID_ROOM)
	if hero.current_room != room_coord:
		return false
	clear_pending_room_loot_request(game, hero.hero_index)
	hero.player_command_locked = false
	game.open_room_loot_inventory(hero, room_coord)
	return true

static func try_execute_pending_room_action_request(game: Node, hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if not game.pending_room_action_requests.has(hero.hero_index):
		return false
	var action_request: Dictionary = game.pending_room_action_requests[hero.hero_index]
	var action_room: Vector2i = action_request.get("room", game.INVALID_ROOM)
	match String(action_request.get("kind", "")):
		"card":
			var card_room: Vector2i = action_request.get("target_room", action_room)
			if not game.hero_ready_for_card_cast(hero, action_room, card_room, game.hand_card_by_uid(hero, int(action_request.get("card_uid", -1))), Vector2(action_request.get("target_world_position", game.room_center(card_room)))):
				return false
		_:
			if not hero_ready_for_room_action(game, hero, action_room):
				return false
	clear_pending_room_action_request(game, hero.hero_index)
	var room_coord: Vector2i = action_room
	match String(action_request.get("kind", "")):
		"light":
			hero.player_command_locked = false
			game.toggle_room_light(room_coord)
			return true
		"research":
			hero.player_command_locked = false
			game.open_research_overlay(room_coord)
			return true
		"build":
			hero.player_command_locked = false
			game.queue_room_construction(room_coord, String(action_request.get("module_type", "")))
			return true
		"merchant_buy":
			hero.player_command_locked = false
			return execute_room_merchant_buy_for_hero(game, hero, room_coord, int(action_request.get("offer_uid", -1)))
		"merchant_sell":
			hero.player_command_locked = false
			return execute_room_merchant_sell_for_hero(game, hero, room_coord, int(action_request.get("item_uid", -1)))
		"merchant_buyback":
			hero.player_command_locked = false
			return execute_room_merchant_buyback_for_hero(game, hero, room_coord, int(action_request.get("offer_uid", -1)))
		"trade_resource":
			hero.player_command_locked = false
			return execute_room_resource_trade_for_hero(
				game,
				hero,
				room_coord,
				int(action_request.get("target_hero_index", -1)),
				String(action_request.get("resource_id", "")),
				int(action_request.get("amount", RESOURCE_TRADE_TRANSFER_AMOUNT))
			)
		"card":
			hero.player_command_locked = false
			return game.play_card_for_hero(hero.hero_index, int(action_request.get("card_uid", -1)), Vector2(action_request.get("target_world_position", game.room_center(room_coord))))
		_:
			return false

static func handle_screen_touch(game: Node, event: InputEventScreenTouch) -> void:
	game.mark_camera_interaction()
	if not event.pressed and game.finish_hand_card_drag("touch", event.index, event.position):
		game.touch_points.erase(event.index)
		if game.touch_points.is_empty():
			game.active_touch_id = -1
			game.touch_dragging = false
			game.pinch_active = false
		return
	if event.pressed and game.dismiss_hand_card_info_if_outside(event.position):
		return
	if event.pressed and not game.room_action_menu.is_empty():
		game.begin_room_action_menu_pointer("touch", event.index, event.position)
		return
	if not event.pressed and not game.room_action_menu.is_empty():
		game.touch_points.erase(event.index)
		if event.index == game.active_touch_id:
			game.active_touch_id = -1
			game.touch_dragging = false
			game.pinch_active = false
		game.release_room_action_menu_pointer("touch", event.index, event.position)
		return
	if event.pressed:
		if game.begin_hand_card_drag("touch", event.index, event.position):
			return
		game.touch_points[event.index] = event.position
		game.reset_camera_pan_state()
		if game.touch_points.size() == 1:
			game.active_touch_id = event.index
			game.touch_start_screen = event.position
			game.touch_pan_last_screen = event.position
			game.touch_dragging = false
			game.pinch_active = false
			game.begin_room_action_hold("touch", event.index, event.position)
		elif game.touch_points.size() >= 2:
			begin_pinch_gesture(game)
			game.clear_room_action_hold()
		return
	var released_position: Vector2 = event.position
	var should_tap: bool = event.index == game.active_touch_id and not game.touch_dragging and not game.pinch_active
	game.touch_points.erase(event.index)
	if not game.room_action_hold.is_empty() and game.room_action_hold["pointer_kind"] == "touch" and int(game.room_action_hold["pointer_id"]) == event.index:
		game.clear_room_action_hold()
	if should_tap:
		handle_world_tap(game, game.screen_to_world(released_position), released_position)
	if game.touch_points.size() == 1:
		var remaining_ids: Array = game.touch_points.keys()
		game.active_touch_id = int(remaining_ids[0])
		game.touch_start_screen = game.touch_points[game.active_touch_id]
		game.touch_pan_last_screen = game.touch_points[game.active_touch_id]
		game.touch_dragging = false
		game.pinch_active = false
	elif game.touch_points.is_empty():
		game.active_touch_id = -1
		game.touch_dragging = false
		game.pinch_active = false

static func handle_screen_drag(game: Node, event: InputEventScreenDrag) -> void:
	if game.update_hand_card_drag("touch", event.index, event.position):
		return
	if not game.room_action_menu.is_empty():
		game.update_room_action_menu_pointer("touch", event.index, event.position)
		return
	game.touch_points[event.index] = event.position
	game.mark_camera_interaction()
	if not game.room_action_hold.is_empty() and game.room_action_hold["pointer_kind"] == "touch" and int(game.room_action_hold["pointer_id"]) == event.index:
		game.room_action_hold["current_screen"] = event.position
		if event.position.distance_to(Vector2(game.room_action_hold["start_screen"])) > game.ROOM_ACTION_HOLD_CANCEL_DISTANCE:
			game.clear_room_action_hold()
	if game.touch_points.size() >= 2:
		game.mark_camera_pan_interaction()
		update_pinch_gesture(game)
		game.touch_dragging = true
		return
	if event.index != game.active_touch_id:
		return
	if not game.touch_dragging and event.position.distance_to(game.touch_start_screen) > game.CAMERA_DRAG_THRESHOLD:
		game.touch_dragging = true
		game.touch_pan_last_screen = event.position
	if game.touch_dragging:
		game.cancel_room_action_camera_focus()
		game.mark_camera_pan_interaction()

static func begin_pinch_gesture(game: Node) -> void:
	var ids: Array = game.touch_points.keys()
	if ids.size() < 2:
		return
	var first_index: int = int(ids[0])
	var second_index: int = int(ids[1])
	var first_point: Vector2 = game.touch_points[first_index]
	var second_point: Vector2 = game.touch_points[second_index]
	game.pinch_last_distance = first_point.distance_to(second_point)
	game.pinch_last_midpoint = (first_point + second_point) * 0.5
	game.pinch_active = game.pinch_last_distance > 0.0
	game.active_touch_id = -1
	game.touch_dragging = false
	game.reset_camera_pan_state()
	game.mark_camera_pan_interaction()
	game.cancel_room_action_camera_focus()

static func update_pinch_gesture(game: Node) -> void:
	var ids: Array = game.touch_points.keys()
	if ids.size() < 2:
		return
	var first_index: int = int(ids[0])
	var second_index: int = int(ids[1])
	var first_point: Vector2 = game.touch_points[first_index]
	var second_point: Vector2 = game.touch_points[second_index]
	var current_distance: float = first_point.distance_to(second_point)
	if current_distance <= 0.0:
		return
	var current_midpoint: Vector2 = (first_point + second_point) * 0.5
	if game.pinch_last_distance > 0.0:
		var zoom_scale: float = game.pinch_last_distance / current_distance
		game.set_camera_zoom(game.camera.zoom.x * zoom_scale)
	game.cancel_room_action_camera_focus()
	game.mark_camera_pan_interaction()
	game.camera.global_position -= (current_midpoint - game.pinch_last_midpoint) * game.camera.zoom
	game.pinch_last_distance = current_distance
	game.pinch_last_midpoint = current_midpoint
	game.clamp_camera()

static func handle_mouse_button(game: Node, event: InputEventMouseButton) -> void:
	if not game.touch_points.is_empty():
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		game.mark_camera_interaction()
		game.set_camera_zoom(game.camera.zoom.x * 0.9)
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		game.mark_camera_interaction()
		game.set_camera_zoom(game.camera.zoom.x * 1.1)
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not event.pressed and game.finish_hand_card_drag("mouse", 0, event.position):
		game.mouse_pressed = false
		game.mouse_dragging = false
		return
	if event.pressed and game.dismiss_hand_card_info_if_outside(event.position):
		game.mouse_pressed = false
		game.mouse_dragging = false
		return
	if event.pressed and not game.room_action_menu.is_empty():
		game.mouse_pressed = true
		game.mouse_dragging = false
		game.mouse_press_screen = event.position
		game.begin_room_action_menu_pointer("mouse", 0, event.position)
		return
	if not event.pressed and not game.room_action_menu.is_empty():
		game.release_room_action_menu_pointer("mouse", 0, event.position)
		game.mouse_pressed = false
		game.mouse_dragging = false
		return
	if event.pressed:
		if game.begin_hand_card_drag("mouse", 0, event.position):
			game.mouse_pressed = false
			game.mouse_dragging = false
			return
		game.mouse_pressed = true
		game.mouse_dragging = false
		game.mouse_press_screen = event.position
		game.reset_camera_pan_state()
		game.mark_camera_interaction()
		game.begin_room_action_hold("mouse", 0, event.position)
	else:
		var should_tap: bool = game.mouse_pressed and not game.mouse_dragging
		game.mouse_pressed = false
		if not game.room_action_hold.is_empty() and game.room_action_hold["pointer_kind"] == "mouse":
			game.clear_room_action_hold()
		if should_tap:
			handle_world_tap(game, game.screen_to_world(event.position), event.position)

static func handle_mouse_motion(game: Node, event: InputEventMouseMotion) -> void:
	if game.update_hand_card_drag("mouse", 0, event.position):
		return
	if not game.touch_points.is_empty():
		return
	if not game.room_action_menu.is_empty():
		if game.mouse_pressed:
			game.update_room_action_menu_pointer("mouse", 0, event.position)
		return
	if not game.mouse_pressed:
		return
	if not game.room_action_hold.is_empty() and game.room_action_hold["pointer_kind"] == "mouse":
		game.room_action_hold["current_screen"] = event.position
		if event.position.distance_to(Vector2(game.room_action_hold["start_screen"])) > game.ROOM_ACTION_HOLD_CANCEL_DISTANCE:
			game.clear_room_action_hold()
	if not game.mouse_dragging and event.position.distance_to(game.mouse_press_screen) > game.CAMERA_DRAG_THRESHOLD:
		game.mouse_dragging = true
	if game.mouse_dragging:
		game.cancel_room_action_camera_focus()
		game.mark_camera_pan_interaction()
		game.camera.global_position -= event.relative * game.camera.zoom * game.CAMERA_PAN_DRAG_MULTIPLIER

static func handle_world_tap(game: Node, world_position: Vector2, screen_position: Vector2) -> void:
	if not game.room_action_menu.is_empty():
		game.close_room_action_menu()
		game.queue_redraw()
		return
	var build_target_tap: bool = game.is_valid_build_target_tap(world_position)
	if game.build_menu_open or game.pending_build_type != "":
		var tapping_build_menu: bool = game.build_menu_contains_screen_position(screen_position)
		if tapping_build_menu:
			return
		if game.pending_build_type != "" and build_target_tap:
			game.build_menu_open = false
			if game.handle_build_tap(world_position):
				game.clear_build_mode()
				game.update_hud()
				game.queue_redraw()
				return
		game.build_menu_open = false
		if game.pending_build_type != "":
			game.clear_build_mode()
			game.status_message = "Build cancelled."
			game.update_hud()
			game.queue_redraw()
			return
	if game.try_handle_crystal_tap(world_position):
		game.update_hud()
		game.queue_redraw()
		return
	var hero: Variant = game.selected_hero()
	if hero == null or not game.can_local_control_hero_index(game.selected_hero_index):
		return
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		execute_world_command_for_hero(game, game.selected_hero_index, world_position, true)
		game.server_request_world_command.rpc_id(game.NETWORK_HOST_PEER_ID, game.selected_hero_index, world_position)
		return
	execute_world_command_for_hero(game, game.selected_hero_index, world_position, true)
	if game.multiplayer_session_active() and game.multiplayer.is_server():
		game.broadcast_network_snapshot()

static func execute_world_command_for_hero(game: Node, hero_index: int, world_position: Vector2, update_local_selection: bool) -> void:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	var command_room: Vector2i = game.active_hero_room_for_commands(hero)
	var frontier_door: Dictionary = game.frontier_target_at_position(world_position)
	var tapped_room: Vector2i = game.corridor_room_target_at_position(world_position, command_room)
	if frontier_door.is_empty() and tapped_room == game.INVALID_ROOM:
		return
	if frontier_door.is_empty() and tapped_room == command_room:
		game.interrupt_hero_orders(hero)
		if update_local_selection:
			game.selected_room = tapped_room
		game.status_message = "%s holding in %s." % [hero.hero_name, game.room_title(tapped_room)]
		game.update_hud()
		return
	command_room = game.interrupt_hero_orders(hero)
	if not frontier_door.is_empty():
		var from_room: Vector2i = frontier_door["from_room"]
		var sealed_room: Vector2i = frontier_door["to_room"]
		var origin_room_path: Array[Vector2i] = [from_room]
		if update_local_selection:
			game.selected_room = from_room
		hero.pending_open_origin_room = from_room
		hero.pending_open_room = sealed_room
		if command_room == from_room:
			game.issue_hero_steps(hero, game.build_steps_for_path(origin_room_path, hero.global_position, game.doorway_navigation_position(from_room, sealed_room)))
		else:
			var door_path: Array[Vector2i] = game.find_path(command_room, from_room, true)
			if door_path.is_empty():
				game.status_message = "No open route to that door."
				game.update_hud()
				return
			game.issue_hero_steps(hero, game.build_steps_for_path(door_path, hero.global_position, game.doorway_navigation_position(from_room, sealed_room)))
		game.status_message = "%s moving to open a new chamber from %s." % [hero.hero_name, game.room_title(from_room)]
		game.update_hud()
		return
	if update_local_selection:
		game.selected_room = tapped_room
	var path: Array[Vector2i] = game.find_path(command_room, tapped_room, true)
	if path.size() <= 1:
		game.status_message = "No open route to that room."
	else:
		var room_target_position: Vector2 = game.hero_room_entry_target_position(path, hero, tapped_room)
		game.issue_hero_steps(hero, game.build_steps_for_path(path, hero.global_position, room_target_position))
		game.status_message = "%s moving to %s." % [hero.hero_name, game.room_title(tapped_room)]
	game.update_hud()

static func request_room_loot(game: Node, room_coord: Vector2i) -> void:
	request_room_loot_for_hero(game, game.selected_hero_index, room_coord)

static func request_room_loot_for_hero(game: Node, hero_index: int, room_coord: Vector2i, open_inventory_on_arrival: bool = true) -> void:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if not game.rooms.has(room_coord) or not game.rooms[room_coord]["opened"]:
		return
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		clear_pending_room_action_request(game, hero.hero_index)
		game.pending_room_loot_requests[hero.hero_index] = {
			"room": room_coord,
		}
		game.server_request_room_loot.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord)
		game.status_message = "%s moving to loot %s." % [hero.hero_name, game.room_title(room_coord)]
		game.update_hud()
		game.queue_redraw()
		return
	clear_pending_room_action_request(game, hero.hero_index)
	var command_room: Vector2i = game.interrupt_hero_orders(hero)
	if command_room == room_coord:
		if open_inventory_on_arrival:
			game.open_room_loot_inventory(hero, room_coord)
		return
	var path: Array[Vector2i] = game.find_path(command_room, room_coord, true)
	if path.size() <= 1:
		game.status_message = "No open route to that room's loot."
		game.update_hud()
		game.queue_redraw()
		return
	if open_inventory_on_arrival:
		game.pending_room_loot_requests[hero.hero_index] = {
			"room": room_coord,
		}
	game.issue_hero_steps(hero, game.build_steps_for_path(path, hero.global_position, game.loot_focus_position(room_coord)))
	game.status_message = "%s moving to loot %s." % [hero.hero_name, game.room_title(room_coord)]
	game.update_hud()
	game.queue_redraw()

static func hero_ready_for_room_action(game: Node, hero: Variant, room_coord: Vector2i) -> bool:
	return hero != null and is_instance_valid(hero) and game.rooms.has(room_coord) and hero.current_room == room_coord and hero.pending_room == game.HERO_INVALID_ROOM and hero.is_idle() and hero.move_steps.is_empty() and game.room_rect(room_coord).has_point(hero.global_position)

static func room_action_staging_position(game: Node, room_coord: Vector2i) -> Vector2:
	return game.room_walkable_center(room_coord)

static func request_deferred_room_action(game: Node, room_coord: Vector2i, kind: String, module_type: String = "", extra_request: Dictionary = {}, action_label_override: String = "") -> bool:
	return request_deferred_room_action_for_hero(game, game.selected_hero_index, room_coord, kind, module_type, extra_request, action_label_override)

static func request_deferred_room_action_for_hero(game: Node, hero_index: int, room_coord: Vector2i, kind: String, module_type: String = "", extra_request: Dictionary = {}, action_label_override: String = "") -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not game.rooms.has(room_coord) or not game.rooms[room_coord]["opened"]:
		return false
	clear_pending_room_loot_request(game, hero.hero_index)
	clear_pending_room_action_request(game, hero.hero_index)
	var command_room: Vector2i = game.interrupt_hero_orders(hero)
	var action_request: Dictionary = {
		"room": room_coord,
		"kind": kind,
		"module_type": module_type,
	}
	for extra_key_variant in extra_request.keys():
		action_request[extra_key_variant] = extra_request[extra_key_variant]
	game.pending_room_action_requests[hero.hero_index] = action_request
	if command_room == room_coord:
		hero.move_steps.clear()
	else:
		var path: Array[Vector2i] = game.find_path(command_room, room_coord, true)
		if path.size() <= 1:
			clear_pending_room_action_request(game, hero.hero_index)
			game.status_message = "No open route to %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
			return false
		var target_position: Vector2 = game.hero_room_entry_target_position(path, hero, room_coord)
		game.issue_hero_steps(hero, game.build_steps_for_path(path, hero.global_position, target_position))
	var action_label: String = action_label_override
	if action_label == "":
		action_label = "light %s" % game.room_title(room_coord)
		if kind == "build":
			action_label = "build in %s" % game.room_title(room_coord)
		elif kind == "research":
			action_label = "research in %s" % game.room_title(room_coord)
	game.status_message = "%s moving to %s." % [hero.hero_name, action_label]
	game.update_hud()
	game.queue_redraw()
	return true

static func request_deferred_room_card_for_hero(game: Node, hero_index: int, room_coord: Vector2i, target_room: Vector2i, card_uid: int, target_world_position: Vector2) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not game.rooms.has(room_coord) or not game.rooms[room_coord]["opened"]:
		return false
	clear_pending_room_loot_request(game, hero.hero_index)
	clear_pending_room_action_request(game, hero.hero_index)
	var command_room: Vector2i = game.interrupt_hero_orders(hero)
	game.pending_room_action_requests[hero.hero_index] = {
		"room": room_coord,
		"target_room": target_room,
		"kind": "card",
		"card_uid": card_uid,
		"target_world_position": target_world_position,
	}
	if command_room == room_coord:
		hero.move_steps.clear()
	else:
		var path: Array[Vector2i] = game.find_path(command_room, room_coord, true)
		if path.size() <= 1:
			clear_pending_room_action_request(game, hero.hero_index)
			game.status_message = "No open route to %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
			return false
		var target_position: Vector2 = game.hero_room_entry_target_position(path, hero, room_coord)
		game.issue_hero_steps(hero, game.build_steps_for_path(path, hero.global_position, target_position))
	game.status_message = "%s moving to cast into %s." % [hero.hero_name, game.room_title(target_room)]
	game.update_hud()
	game.queue_redraw()
	return true

static func request_room_light(game: Node, room_coord: Vector2i) -> bool:
	return request_room_light_for_hero(game, game.selected_hero_index, room_coord)

static func request_room_light_for_hero(game: Node, hero_index: int, room_coord: Vector2i) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return false
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_request_room_light.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord)
		game.status_message = "%s moving to light %s." % [hero.hero_name, game.room_title(room_coord)]
		game.update_hud()
		game.queue_redraw()
		return true
	if hero_ready_for_room_action(game, hero, room_coord):
		game.toggle_room_light(room_coord)
		return true
	return request_deferred_room_action_for_hero(game, hero_index, room_coord, "light")

static func request_room_research(game: Node, room_coord: Vector2i) -> bool:
	return request_room_research_for_hero(game, game.selected_hero_index, room_coord)

static func request_room_research_for_hero(game: Node, hero_index: int, room_coord: Vector2i) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not game.can_start_research_in_room(room_coord):
		return false
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.status_message = "Research crystals are host-controlled for now."
		game.update_hud()
		return false
	if hero_ready_for_room_action(game, hero, room_coord):
		game.open_research_overlay(room_coord)
		return true
	return request_deferred_room_action_for_hero(game, hero_index, room_coord, "research")

static func request_room_construction(game: Node, room_coord: Vector2i, module_type: String) -> bool:
	return request_room_construction_for_hero(game, game.selected_hero_index, room_coord, module_type)

static func request_room_construction_for_hero(game: Node, hero_index: int, room_coord: Vector2i, module_type: String) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size():
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return false
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_request_room_construction.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord, module_type)
		game.status_message = "%s moving to build in %s." % [hero.hero_name, game.room_title(room_coord)]
		game.update_hud()
		game.queue_redraw()
		return true
	if hero_ready_for_room_action(game, hero, room_coord):
		return game.queue_room_construction(room_coord, module_type)
	return request_deferred_room_action_for_hero(game, hero_index, room_coord, "build", module_type)

static func request_room_merchant_buy(game: Node, room_coord: Vector2i, offer_uid: int) -> bool:
	return request_room_merchant_buy_for_hero(game, game.selected_hero_index, room_coord, offer_uid)

static func request_room_merchant_buy_for_hero(game: Node, hero_index: int, room_coord: Vector2i, offer_uid: int) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size() or not game.rooms.has(room_coord) or not bool(game.rooms[room_coord].get("opened", false)):
		return false
	if not GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord):
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return false
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_request_room_merchant_action.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord, "buy", offer_uid)
		game.status_message = "%s moving to buy from %s." % [hero.hero_name, game.room_title(room_coord)]
		game.update_hud()
		game.queue_redraw()
		return true
	if hero_ready_for_room_action(game, hero, room_coord):
		return execute_room_merchant_buy_for_hero(game, hero, room_coord, offer_uid)
	return request_deferred_room_action_for_hero(
		game,
		hero_index,
		room_coord,
		"merchant_buy",
		"",
		{"offer_uid": offer_uid},
		"trade with the merchant in %s" % game.room_title(room_coord)
	)

static func request_room_merchant_sell(game: Node, room_coord: Vector2i, item_uid: int) -> bool:
	return request_room_merchant_sell_for_hero(game, game.selected_hero_index, room_coord, item_uid)

static func request_room_merchant_sell_for_hero(game: Node, hero_index: int, room_coord: Vector2i, item_uid: int) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size() or not game.rooms.has(room_coord) or not bool(game.rooms[room_coord].get("opened", false)):
		return false
	if not GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord):
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return false
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_request_room_merchant_action.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord, "sell", item_uid)
		game.status_message = "%s moving to sell in %s." % [hero.hero_name, game.room_title(room_coord)]
		game.update_hud()
		game.queue_redraw()
		return true
	if hero_ready_for_room_action(game, hero, room_coord):
		return execute_room_merchant_sell_for_hero(game, hero, room_coord, item_uid)
	return request_deferred_room_action_for_hero(
		game,
		hero_index,
		room_coord,
		"merchant_sell",
		"",
		{"item_uid": item_uid},
		"trade with the merchant in %s" % game.room_title(room_coord)
	)

static func request_room_merchant_buyback(game: Node, room_coord: Vector2i, offer_uid: int) -> bool:
	return request_room_merchant_buyback_for_hero(game, game.selected_hero_index, room_coord, offer_uid)

static func request_room_merchant_buyback_for_hero(game: Node, hero_index: int, room_coord: Vector2i, offer_uid: int) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size() or not game.rooms.has(room_coord) or not bool(game.rooms[room_coord].get("opened", false)):
		return false
	if not GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord):
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return false
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_request_room_merchant_action.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord, "buyback", offer_uid)
		game.status_message = "%s moving to buy back in %s." % [hero.hero_name, game.room_title(room_coord)]
		game.update_hud()
		game.queue_redraw()
		return true
	if hero_ready_for_room_action(game, hero, room_coord):
		return execute_room_merchant_buyback_for_hero(game, hero, room_coord, offer_uid)
	return request_deferred_room_action_for_hero(
		game,
		hero_index,
		room_coord,
		"merchant_buyback",
		"",
		{"offer_uid": offer_uid},
		"trade with the merchant in %s" % game.room_title(room_coord)
	)

static func request_room_resource_trade(game: Node, room_coord: Vector2i, target_hero_index: int, resource_id: String, amount: int = RESOURCE_TRADE_TRANSFER_AMOUNT) -> bool:
	return request_room_resource_trade_for_hero(game, game.selected_hero_index, room_coord, target_hero_index, resource_id, amount)

static func request_room_resource_trade_for_hero(game: Node, hero_index: int, room_coord: Vector2i, target_hero_index: int, resource_id: String, amount: int = RESOURCE_TRADE_TRANSFER_AMOUNT) -> bool:
	if hero_index < 0 or hero_index >= game.heroes.size() or not game.rooms.has(room_coord) or not bool(game.rooms[room_coord].get("opened", false)):
		return false
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return false
	if game.multiplayer_session_active() and not game.authoritative_simulation_active():
		game.server_request_room_resource_trade.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, room_coord, target_hero_index, resource_id, amount)
		game.status_message = "%s moving to trade in %s." % [hero.hero_name, game.room_title(room_coord)]
		game.update_hud()
		game.queue_redraw()
		return true
	if hero_ready_for_room_action(game, hero, room_coord):
		return execute_room_resource_trade_for_hero(game, hero, room_coord, target_hero_index, resource_id, amount)
	return request_deferred_room_action_for_hero(
		game,
		hero_index,
		room_coord,
		"trade_resource",
		"",
		{
			"target_hero_index": target_hero_index,
			"resource_id": resource_id,
			"amount": amount,
		},
		"trade resources in %s" % game.room_title(room_coord)
	)

static func room_action_enabled(game: Node, room_coord: Vector2i, action_id: String) -> bool:
	var minor_module_type: String = game.minor_module_type_for_action(action_id)
	if minor_module_type != "":
		return game.can_open_build_for_room(room_coord) and game.minor_module_unlocked(minor_module_type)
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return false
	var crystal_carry_available_here: bool = game.crystal_holder == null \
		and game.crystal_ground_room == room_coord \
		and game.is_exit_discovered() \
		and bool(game.rooms[room_coord].get("opened", false))
	var selected_hero: Variant = game.selected_hero()
	var merchant_here: bool = GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord)
	if action_id.begins_with("merchant_buy_offer_"):
		if not merchant_here:
			return false
		if selected_hero == null or not is_instance_valid(selected_hero):
			return false
		var offer_uid: int = action_suffix_int(action_id, "merchant_buy_offer_")
		if offer_uid < 0:
			return false
		var room: Dictionary = game.rooms[room_coord]
		var offer_index: int = room_offer_index_by_uid(room, "merchant_stock", offer_uid)
		if offer_index < 0:
			return false
		var offer: Dictionary = Dictionary(Array(room.get("merchant_stock", []))[offer_index])
		var resource_id: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_id_for_room(game, room_coord)
		var price: int = GAME_INVENTORY_ITEM_FLOW.merchant_offer_price(game, offer)
		if GAME_INVENTORY_ITEM_FLOW.merchant_resource_amount(game, resource_id) < price:
			return false
		if GAME_INVENTORY_ITEM_FLOW.merchant_offer_kind(offer) != "item":
			return false
		var item: Dictionary = Dictionary(offer.get("item", {}))
		return game.find_first_inventory_item_anchor(selected_hero, item) != game.INVALID_ROOM
	if action_id.begins_with("merchant_sell_item_"):
		if not merchant_here or selected_hero == null or not is_instance_valid(selected_hero):
			return false
		var item_uid: int = action_suffix_int(action_id, "merchant_sell_item_")
		return hero_inventory_item_index_by_uid(selected_hero, item_uid) >= 0
	if action_id.begins_with("merchant_buyback_offer_"):
		if not merchant_here or selected_hero == null or not is_instance_valid(selected_hero):
			return false
		var offer_uid_buyback: int = action_suffix_int(action_id, "merchant_buyback_offer_")
		if offer_uid_buyback < 0:
			return false
		var room_buyback: Dictionary = game.rooms[room_coord]
		var offer_index_buyback: int = room_offer_index_by_uid(room_buyback, "merchant_buyback", offer_uid_buyback)
		if offer_index_buyback < 0:
			return false
		var offer_buyback: Dictionary = Dictionary(Array(room_buyback.get("merchant_buyback", []))[offer_index_buyback])
		var item_buyback: Dictionary = Dictionary(offer_buyback.get("item", {}))
		var resource_id_buyback: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_id_for_room(game, room_coord)
		var price_buyback: int = int(offer_buyback.get("price", GAME_INVENTORY_ITEM_FLOW.merchant_item_full_price(game, item_buyback)))
		if GAME_INVENTORY_ITEM_FLOW.merchant_resource_amount(game, resource_id_buyback) < price_buyback:
			return false
		return game.find_first_inventory_item_anchor(selected_hero, item_buyback) != game.INVALID_ROOM
	if action_id.begins_with("trade_target_"):
		if selected_hero == null or not is_instance_valid(selected_hero):
			return false
		var target_hero_index: int = action_suffix_int(action_id, "trade_target_")
		if target_hero_index < 0 or target_hero_index >= game.heroes.size() or target_hero_index == int(selected_hero.hero_index):
			return false
		var target_hero: Variant = game.heroes[target_hero_index]
		if target_hero == null or not is_instance_valid(target_hero):
			return false
		return target_hero.current_room == room_coord
	if action_id.begins_with("trade_resource_") and action_id != "trade_resource_back":
		var resource_id_trade: String = action_id.trim_prefix("trade_resource_")
		if resource_id_trade != "food" and resource_id_trade != "industry" and resource_id_trade != "science" and resource_id_trade != "dust":
			return false
		return GAME_INVENTORY_ITEM_FLOW.merchant_resource_amount(game, resource_id_trade) > 0
	match action_id:
		"light":
			return game.can_toggle_light(room_coord)
		"research":
			return game.can_start_research_in_room(room_coord)
		"build_menu", "build_minor_menu", "build_major_menu":
			return game.can_open_build_for_room(room_coord)
		"build_major_food":
			return game.can_build_or_repair_major(room_coord, game.MAJOR_MODULE_FOOD)
		"build_major_science":
			return game.can_build_or_repair_major(room_coord, game.MAJOR_MODULE_SCIENCE)
		"build_major_industry":
			return game.can_build_or_repair_major(room_coord, game.MAJOR_MODULE_INDUSTRY)
		"submenu_back", "submenu_back_build":
			return true
		"merchant_menu":
			return merchant_here
		"crystal_carry_menu", "crystal_carry_confirm_action", "crystal_carry_back":
			return crystal_carry_available_here
		"merchant_buy_menu", "merchant_sell_menu", "merchant_buyback_menu", "merchant_back", "merchant_page_prev", "merchant_page_next", "merchant_none":
			return merchant_here
		"trade_menu", "trade_back", "trade_resource_back", "trade_none":
			return selected_hero != null and is_instance_valid(selected_hero)
		"loot":
			return game.rooms.has(room_coord) and game.rooms[room_coord]["opened"]
		_:
			return false
