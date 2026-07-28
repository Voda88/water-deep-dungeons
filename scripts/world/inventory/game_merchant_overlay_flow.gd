extends RefCounted

const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/inventory/game_inventory_item_flow.gd")

static func open_room_merchant_overlay(game: Node, room_coord: Vector2i) -> bool:
	if not game.rooms.has(room_coord) or not bool(game.rooms[room_coord].get("opened", false)):
		return false
	if not GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord):
		return false
	if game.merchant_overlay == null:
		return false
	if game.inventory_overlay != null and game.inventory_overlay.visible:
		game.clear_inventory_session(true)
	if game.research_overlay != null and game.research_overlay.visible:
		game.close_research_overlay()
	game.build_menu_open = false
	game.clear_build_mode()
	game.crystal_prompt_visible = false
	game.clear_room_action_hold()
	game.close_room_action_menu()
	GAME_INVENTORY_ITEM_FLOW.ensure_room_merchant_state(game, room_coord)
	game.merchant_session = {
		"room": room_coord,
	}
	game.merchant_overlay.configure(build_merchant_overlay_data(game, room_coord))
	game.status_message = "%s is ready to trade in %s." % [merchant_display_name(game, room_coord), game.room_title(room_coord)]
	game.mouse_pressed = false
	game.mouse_dragging = false
	game.touch_points.clear()
	game.active_touch_id = -1
	game.update_hud()
	game.queue_redraw()
	return true

static func close_merchant_overlay(game: Node) -> void:
	if game.merchant_overlay != null:
		game.merchant_overlay.hide_overlay()
	game.merchant_session.clear()
	game.queue_redraw()

static func refresh_open_merchant_overlay(game: Node) -> void:
	if game.merchant_overlay == null or not game.merchant_overlay.visible or game.merchant_session.is_empty():
		return
	var room_coord: Vector2i = Vector2i(game.merchant_session.get("room", game.INVALID_ROOM))
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord) or not bool(game.rooms[room_coord].get("opened", false)):
		close_merchant_overlay(game)
		return
	if not GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord):
		close_merchant_overlay(game)
		return
	GAME_INVENTORY_ITEM_FLOW.ensure_room_merchant_state(game, room_coord)
	game.merchant_overlay.configure(build_merchant_overlay_data(game, room_coord))

static func merchant_display_name(game: Node, room_coord: Vector2i) -> String:
	return GAME_INVENTORY_ITEM_FLOW.merchant_theme_display_name(game, GAME_INVENTORY_ITEM_FLOW.merchant_theme_for_room(game, room_coord))

static func build_merchant_overlay_data(game: Node, room_coord: Vector2i) -> Dictionary:
	var selected_hero: Variant = game.selected_hero()
	var selected_hero_name: String = "No hero selected"
	if selected_hero != null and is_instance_valid(selected_hero):
		selected_hero_name = "%s in %s" % [selected_hero.hero_name, game.room_title(selected_hero.current_room)]
	var merchant_name: String = merchant_display_name(game, room_coord)
	var resource_id: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_id_for_room(game, room_coord)
	var resource_label: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_label(game, resource_id)
	var resource_amount: int = GAME_INVENTORY_ITEM_FLOW.merchant_resource_amount(game, resource_id)
	return {
		"room_coord": room_coord,
		"merchant_title": merchant_name,
		"room_title": "Trading in %s" % game.room_title(room_coord),
		"hero_title": "Selected hero: %s" % selected_hero_name,
		"resource_title": "%s: %d" % [resource_label, resource_amount],
		"footer_title": "Tap an entry to trade.",
		"buy_entries": build_buy_entries(game, room_coord, selected_hero, resource_id, resource_label, resource_amount),
		"sell_entries": build_sell_entries(game, selected_hero, resource_label),
		"buyback_entries": build_buyback_entries(game, room_coord, selected_hero, resource_id, resource_label, resource_amount),
	}

static func item_display_name(game: Node, item: Dictionary) -> String:
	var item_id: String = String(item.get("item_id", ""))
	if item_id == "":
		return "Unknown"
	return String(game.item_defs.get(item_id, {}).get("name", item_id.capitalize()))

static func build_buy_entries(game: Node, room_coord: Vector2i, selected_hero: Variant, resource_id: String, resource_label: String, resource_amount: int) -> Array:
	var entries: Array = []
	for offer_variant in Array(game.rooms[room_coord].get("merchant_stock", [])):
		var offer: Dictionary = Dictionary(offer_variant)
		var offer_uid: int = int(offer.get("offer_uid", -1))
		if offer_uid < 0:
			continue
		var offer_kind: String = GAME_INVENTORY_ITEM_FLOW.merchant_offer_kind(offer)
		var price: int = GAME_INVENTORY_ITEM_FLOW.merchant_offer_price(game, offer)
		var needs_space: bool = GAME_INVENTORY_ITEM_FLOW.merchant_offer_needs_inventory_space(offer)
		var item: Dictionary = Dictionary(offer.get("item", {})).duplicate(true)
		var affordable: bool = resource_amount >= price
		var has_space: bool = true
		if needs_space:
			has_space = selected_hero != null and is_instance_valid(selected_hero) and game.find_first_inventory_item_anchor(selected_hero, item) != game.INVALID_ROOM
		var can_upgrade: bool = true
		if offer_kind == "major_upgrade":
			var module_type: String = String(offer.get("module_type", ""))
			var target_level: int = int(offer.get("target_level", 1))
			can_upgrade = target_level > game.major_module_level(module_type)
		var enabled: bool = selected_hero != null and is_instance_valid(selected_hero) and resource_id != "" and affordable and has_space and can_upgrade
		var reason: String = ""
		if selected_hero == null or not is_instance_valid(selected_hero):
			reason = "Select a hero first."
		elif resource_id == "":
			reason = "Merchant resource is not configured."
		elif not affordable:
			reason = "Need %d more %s." % [price - resource_amount, resource_label]
		elif not can_upgrade:
			reason = "That upgrade is already applied."
		elif not has_space:
			reason = "%s has no inventory space." % selected_hero.hero_name
		entries.append({
			"uid": offer_uid,
			"label": "%s - %d %s" % [GAME_INVENTORY_ITEM_FLOW.merchant_offer_display_name(game, offer), price, resource_label],
			"enabled": enabled,
			"note": reason,
		})
	return entries

static func build_sell_entries(game: Node, selected_hero: Variant, resource_label: String) -> Array:
	var entries: Array = []
	if selected_hero == null or not is_instance_valid(selected_hero):
		return entries
	for hero_item_variant in selected_hero.inventory_items:
		var hero_item: Dictionary = Dictionary(hero_item_variant)
		var item_uid: int = int(hero_item.get("uid", -1))
		if item_uid < 0:
			continue
		var sell_price: int = GAME_INVENTORY_ITEM_FLOW.merchant_item_sell_price(game, hero_item)
		entries.append({
			"uid": item_uid,
			"label": "%s +%d %s" % [item_display_name(game, hero_item), sell_price, resource_label],
			"enabled": true,
			"note": "Sells from %s's inventory." % selected_hero.hero_name,
		})
	return entries

static func build_buyback_entries(game: Node, room_coord: Vector2i, selected_hero: Variant, resource_id: String, resource_label: String, resource_amount: int) -> Array:
	var entries: Array = []
	for offer_variant in Array(game.rooms[room_coord].get("merchant_buyback", [])):
		var offer: Dictionary = Dictionary(offer_variant)
		var offer_uid: int = int(offer.get("offer_uid", -1))
		if offer_uid < 0:
			continue
		var item: Dictionary = Dictionary(offer.get("item", {})).duplicate(true)
		var price: int = int(offer.get("price", GAME_INVENTORY_ITEM_FLOW.merchant_item_full_price(game, item)))
		var affordable: bool = resource_amount >= price
		var has_space: bool = selected_hero != null and is_instance_valid(selected_hero) and game.find_first_inventory_item_anchor(selected_hero, item) != game.INVALID_ROOM
		var enabled: bool = selected_hero != null and is_instance_valid(selected_hero) and resource_id != "" and affordable and has_space
		var reason: String = ""
		if selected_hero == null or not is_instance_valid(selected_hero):
			reason = "Select a hero first."
		elif resource_id == "":
			reason = "Merchant resource is not configured."
		elif not affordable:
			reason = "Need %d more %s." % [price - resource_amount, resource_label]
		elif not has_space:
			reason = "%s has no inventory space." % selected_hero.hero_name
		entries.append({
			"uid": offer_uid,
			"label": "%s - %d %s" % [item_display_name(game, item), price, resource_label],
			"enabled": enabled,
			"note": reason,
		})
	return entries

static func _on_merchant_overlay_close_requested(game: Node) -> void:
	if game.merchant_session.is_empty():
		return
	close_merchant_overlay(game)
	game.status_message = "Merchant closed."
	game.update_hud()

static func _on_merchant_overlay_buy_requested(game: Node, offer_uid: int) -> void:
	if game.merchant_session.is_empty():
		return
	var room_coord: Vector2i = Vector2i(game.merchant_session.get("room", game.INVALID_ROOM))
	var hero: Variant = game.selected_hero()
	var immediate: bool = game.authoritative_simulation_active() and game.hero_ready_for_room_action(hero, room_coord)
	if game.request_room_merchant_buy(room_coord, offer_uid):
		if immediate:
			refresh_open_merchant_overlay(game)
		else:
			close_merchant_overlay(game)
	game.update_hud()

static func _on_merchant_overlay_sell_requested(game: Node, item_uid: int) -> void:
	if game.merchant_session.is_empty():
		return
	var room_coord: Vector2i = Vector2i(game.merchant_session.get("room", game.INVALID_ROOM))
	var hero: Variant = game.selected_hero()
	var immediate: bool = game.authoritative_simulation_active() and game.hero_ready_for_room_action(hero, room_coord)
	if game.request_room_merchant_sell(room_coord, item_uid):
		if immediate:
			refresh_open_merchant_overlay(game)
		else:
			close_merchant_overlay(game)
	game.update_hud()

static func _on_merchant_overlay_buyback_requested(game: Node, offer_uid: int) -> void:
	if game.merchant_session.is_empty():
		return
	var room_coord: Vector2i = Vector2i(game.merchant_session.get("room", game.INVALID_ROOM))
	var hero: Variant = game.selected_hero()
	var immediate: bool = game.authoritative_simulation_active() and game.hero_ready_for_room_action(hero, room_coord)
	if game.request_room_merchant_buyback(room_coord, offer_uid):
		if immediate:
			refresh_open_merchant_overlay(game)
		else:
			close_merchant_overlay(game)
	game.update_hud()
