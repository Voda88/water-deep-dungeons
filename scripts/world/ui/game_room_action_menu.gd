extends RefCounted

const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/inventory/game_inventory_item_flow.gd")
const MERCHANT_PAGE_SIZE: int = 3
const TRADE_RESOURCE_AMOUNT: int = 5

static func with_spread_angles(buttons: Array, start_angle: float = -3.12, end_angle: float = -1.48) -> Array:
	if buttons.is_empty():
		return buttons
	if buttons.size() == 1:
		var single_button: Dictionary = Dictionary(buttons[0]).duplicate(true)
		single_button["angle"] = (start_angle + end_angle) * 0.5
		return [single_button]
	var spread_buttons: Array = []
	for button_index in range(buttons.size()):
		var button_data: Dictionary = Dictionary(buttons[button_index]).duplicate(true)
		var t: float = float(button_index) / float(buttons.size() - 1)
		button_data["angle"] = lerpf(start_angle, end_angle, t)
		spread_buttons.append(button_data)
	return spread_buttons

static func action_suffix_int(action_id: String, prefix: String) -> int:
	if not action_id.begins_with(prefix):
		return -1
	var suffix: String = action_id.trim_prefix(prefix)
	if not suffix.is_valid_int():
		return -1
	return int(suffix)

static func merchant_resource_short_label(resource_id: String) -> String:
	match resource_id:
		"food":
			return "F"
		"industry":
			return "M"
		"science":
			return "A"
		"dust":
			return "D"
		_:
			return "R"

static func short_item_label(game: Node, item_id: String) -> String:
	var item_def: Dictionary = game.item_defs.get(item_id, {})
	var short_label: String = String(item_def.get("short", ""))
	if short_label != "":
		return short_label
	var item_name: String = String(item_def.get("name", item_id.capitalize()))
	if item_name.length() <= 4:
		return item_name.to_upper()
	return item_name.substr(0, 4).to_upper()

static func paged_merchant_buttons(game: Node, entries: Array, page_key: String, empty_label: String, back_action: String) -> Array:
	var page: int = max(0, int(game.room_action_menu.get(page_key, 0)))
	var total_pages: int = max(1, int(ceil(float(entries.size()) / float(max(1, MERCHANT_PAGE_SIZE)))))
	page = clampi(page, 0, total_pages - 1)
	game.room_action_menu[page_key] = page
	var buttons: Array = []
	if entries.is_empty():
		buttons.append({"id": "merchant_none", "label": empty_label, "fill": Color("76848d")})
	else:
		var start_index: int = page * MERCHANT_PAGE_SIZE
		var end_index: int = mini(start_index + MERCHANT_PAGE_SIZE, entries.size())
		for entry_index in range(start_index, end_index):
			buttons.append(entries[entry_index])
	if total_pages > 1 and page > 0:
		buttons.append({"id": "merchant_page_prev", "label": "Prev", "fill": Color("d7dfeb")})
	if total_pages > 1 and page < total_pages - 1:
		buttons.append({"id": "merchant_page_next", "label": "Next", "fill": Color("d7dfeb")})
	buttons.append({"id": back_action, "label": "Back", "fill": Color("d7dfeb")})
	return with_spread_angles(buttons)

static func clear_room_action_hold(game: Node) -> void:
	game.room_action_hold.clear()

static func clear_room_action_menu_pointer(game: Node) -> void:
	game.room_action_menu_hold_selection_active = false
	if game.room_action_menu.is_empty():
		return
	game.room_action_menu.erase("pointer_kind")
	game.room_action_menu.erase("pointer_id")
	game.room_action_menu.erase("pointer_origin_screen")
	game.room_action_menu.erase("pointer_screen")
	game.room_action_menu.erase("pointer_active")

static func room_action_overlay_scale(game: Node) -> float:
	var viewport_size: Vector2 = game.get_viewport_rect().size
	return clampf(minf(viewport_size.x, viewport_size.y) / 900.0, 0.84, 1.28)

static func room_action_menu_screen_center(game: Node) -> Vector2:
	var viewport_size: Vector2 = game.get_viewport_rect().size
	return viewport_size * 0.5

static func room_action_menu_virtual_pointer_screen_position(game: Node) -> Vector2:
	var menu_center: Vector2 = room_action_menu_screen_center(game)
	if game.room_action_menu.is_empty() or not bool(game.room_action_menu.get("pointer_active", false)):
		return menu_center
	if String(game.room_action_menu.get("pointer_kind", "")) == "mouse":
		return Vector2(game.room_action_menu.get("pointer_screen", menu_center))
	var origin_screen: Vector2 = Vector2(game.room_action_menu.get("pointer_origin_screen", menu_center))
	var pointer_screen: Vector2 = Vector2(game.room_action_menu.get("pointer_screen", origin_screen))
	return menu_center + (pointer_screen - origin_screen)

static func begin_room_action_menu_pointer(game: Node, pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if game.room_action_menu.is_empty():
		return false
	game.room_action_menu_hold_selection_active = true
	game.room_action_menu["pointer_kind"] = pointer_kind
	game.room_action_menu["pointer_id"] = pointer_id
	game.room_action_menu["pointer_origin_screen"] = screen_position
	game.room_action_menu["pointer_screen"] = screen_position
	game.room_action_menu["pointer_active"] = true
	game.queue_redraw()
	return true

static func update_room_action_menu_pointer(game: Node, pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if game.room_action_menu.is_empty() or not bool(game.room_action_menu.get("pointer_active", false)):
		return false
	if String(game.room_action_menu.get("pointer_kind", "")) != pointer_kind or int(game.room_action_menu.get("pointer_id", -1)) != pointer_id:
		return false
	game.room_action_menu["pointer_screen"] = screen_position
	game.queue_redraw()
	return true

static func release_room_action_menu_pointer(game: Node, pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if not update_room_action_menu_pointer(game, pointer_kind, pointer_id, screen_position):
		return false
	var pointer_position: Vector2 = room_action_menu_virtual_pointer_screen_position(game)
	var action_id: String = room_action_button_at_screen_position(game, pointer_position)
	clear_room_action_menu_pointer(game)
	if action_id == "":
		close_room_action_menu(game)
		game.queue_redraw()
		return true
	perform_room_action(game, game.room_action_menu.get("room", game.INVALID_ROOM), action_id)
	return true

static func focus_room_action_menu(game: Node, room_coord: Vector2i, _center_on_screen: bool) -> void:
	game.room_action_camera_target = game.room_center(room_coord)
	game.room_action_camera_target_active = true
	game.reset_camera_pan_state()
	game.mark_camera_interaction()
	game.queue_redraw()

static func close_room_action_menu(game: Node) -> void:
	game.room_action_menu.clear()
	clear_room_action_menu_pointer(game)
	game.cancel_room_action_camera_focus()

static func room_action_target_for_selected_hero(game: Node) -> Vector2i:
	var hero: Variant = game.selected_hero()
	if hero == null or not is_instance_valid(hero):
		return game.INVALID_ROOM
	if game.opening_hero == hero and game.opening_origin_room != game.INVALID_ROOM and game.rooms.has(game.opening_origin_room) and game.rooms[game.opening_origin_room]["opened"]:
		return game.opening_origin_room
	if hero.pending_open_origin_room != game.HERO_INVALID_ROOM and game.rooms.has(hero.pending_open_origin_room) and game.rooms[hero.pending_open_origin_room]["opened"]:
		return hero.pending_open_origin_room
	if not hero.move_steps.is_empty():
		for step_index in range(hero.move_steps.size() - 1, -1, -1):
			var step: Dictionary = hero.move_steps[step_index]
			var step_room: Vector2i = step.get("room", game.INVALID_ROOM)
			if step_room != game.INVALID_ROOM and game.rooms.has(step_room) and game.rooms[step_room]["opened"]:
				return step_room
	if hero.pending_room != game.HERO_INVALID_ROOM and game.rooms.has(hero.pending_room) and game.rooms[hero.pending_room]["opened"]:
		return hero.pending_room
	if game.rooms.has(hero.current_room) and game.rooms[hero.current_room]["opened"]:
		return hero.current_room
	return game.INVALID_ROOM

static func begin_room_action_hold(game: Node, pointer_kind: String, pointer_id: int, screen_position: Vector2) -> void:
	if not game.room_actions_allowed_for_local_peer():
		return
	var room_coord: Vector2i = room_action_target_for_selected_hero(game)
	if room_coord == game.INVALID_ROOM:
		clear_room_action_hold(game)
		return
	game.room_action_hold = {
		"pointer_kind": pointer_kind,
		"pointer_id": pointer_id,
		"start_screen": screen_position,
		"current_screen": screen_position,
		"elapsed": 0.0,
		"room": room_coord,
	}

static func advance_room_action_hold(game: Node, delta: float) -> void:
	if game.room_action_hold.is_empty() or game.inventory_overlay != null and game.inventory_overlay.visible or not game.room_action_menu.is_empty():
		return
	game.room_action_hold["elapsed"] = float(game.room_action_hold["elapsed"]) + delta
	if float(game.room_action_hold["elapsed"]) < game.ROOM_ACTION_HOLD_START_DELAY + game.ROOM_ACTION_HOLD_LOADER_DURATION:
		return
	open_room_action_menu(
		game,
		game.room_action_hold["room"],
		game.room_action_hold["current_screen"],
		true,
		String(game.room_action_hold.get("pointer_kind", "")),
		int(game.room_action_hold.get("pointer_id", -1))
	)
	clear_room_action_hold(game)
	game.update_hud()

static func open_room_action_menu(game: Node, room_coord: Vector2i, screen_position: Vector2, hold_selection_active: bool = false, pointer_kind: String = "", pointer_id: int = -1) -> void:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord) or not game.rooms[room_coord]["opened"]:
		return
	game.selected_room = room_coord
	game.build_menu_open = false
	game.clear_build_mode()
	game.room_action_menu_hold_selection_active = hold_selection_active
	game.room_action_menu = {
		"room": room_coord,
		"mode": "root",
		"merchant_page": 0,
		"trade_resource_id": "",
		"pointer_kind": pointer_kind,
		"pointer_id": pointer_id,
		"pointer_origin_screen": screen_position,
		"pointer_screen": screen_position,
		"pointer_active": hold_selection_active,
	}
	focus_room_action_menu(game, room_coord, not hold_selection_active)
	game.status_message = "Room actions for %s." % game.room_title(room_coord)
	game.queue_redraw()

static func room_action_button_layout(game: Node) -> Array:
	var mode: String = String(game.room_action_menu.get("mode", "root"))
	var room_coord: Vector2i = Vector2i(game.room_action_menu.get("room", game.INVALID_ROOM))
	var selected_hero: Variant = game.selected_hero()
	var crystal_carry_available_here: bool = game.crystal_holder == null \
		and game.crystal_ground_room == room_coord \
		and game.is_exit_discovered() \
		and game.rooms.has(room_coord) \
		and bool(game.rooms[room_coord].get("opened", false))
	var merchant_here: bool = GAME_INVENTORY_ITEM_FLOW.room_has_merchant(game, room_coord)
	var merchant_resource_id: String = GAME_INVENTORY_ITEM_FLOW.merchant_resource_id_for_room(game, room_coord)
	var merchant_resource_short: String = merchant_resource_short_label(merchant_resource_id)
	match mode:
		"crystal_carry_confirm":
			return with_spread_angles([
				{"id": "crystal_carry_confirm_action", "label": "Confirm Carry", "fill": Color("f7bd87")},
				{"id": "crystal_carry_back", "label": "Back", "fill": Color("d7dfeb")},
			], -2.92, -1.68)
		"build_kind":
			return with_spread_angles([
				{"id": "build_minor_menu", "label": "Minor", "angle": -3.08, "fill": Color("9bd8ff")},
				{"id": "build_major_menu", "label": "Major", "angle": -2.42, "fill": Color("f6c983")},
				{"id": "submenu_back", "label": "Back", "angle": -1.76, "fill": Color("d7dfeb")},
			])
		"build_minor":
			var minor_buttons: Array = []
			var action_specs: Array = game.available_minor_module_action_specs()
			for action_spec_variant in action_specs:
				var action_spec: Dictionary = action_spec_variant
				var action_id: String = String(action_spec.get("id", ""))
				var module_type: String = game.minor_module_type_for_action(action_id)
				var cost: int = game.minor_module_cost(module_type)
				minor_buttons.append({
					"id": action_id,
					"label": "%s\n%dM" % [game.build_type_label(module_type), cost],
					"fill": Color(action_spec.get("fill", Color("89f2ff"))),
					"fill_alpha": 0.42,
					"highlight_fill_alpha": 0.5,
				})
			minor_buttons.append({"id": "submenu_back_build", "label": "Back", "fill": Color("d7dfeb")})
			return with_spread_angles(minor_buttons, -3.10, -1.52)
		"build_major":
			var major_food_cost: int = game.major_module_action_cost(room_coord, game.MAJOR_MODULE_FOOD)
			var major_science_cost: int = game.major_module_action_cost(room_coord, game.MAJOR_MODULE_SCIENCE)
			var major_industry_cost: int = game.major_module_action_cost(room_coord, game.MAJOR_MODULE_INDUSTRY)
			return with_spread_angles([
				{"id": "build_major_food", "label": "Food\n%dM" % major_food_cost, "angle": -3.10, "fill": Color("8ee28a")},
				{"id": "build_major_science", "label": "Arcana\n%dM" % major_science_cost, "angle": -2.58, "fill": Color("8bc1ff")},
				{"id": "build_major_industry", "label": "Materials\n%dM" % major_industry_cost, "angle": -2.06, "fill": Color("f1c26b")},
				{"id": "submenu_back_build", "label": "Back", "angle": -1.54, "fill": Color("d7dfeb")},
			])
		"merchant_root":
			return with_spread_angles([
				{"id": "merchant_buy_menu", "label": "Buy %s" % merchant_resource_short, "fill": Color("a6efba")},
				{"id": "merchant_sell_menu", "label": "Sell %s" % merchant_resource_short, "fill": Color("f3d88f")},
				{"id": "merchant_buyback_menu", "label": "Buyback", "fill": Color("9bc7ff")},
				{"id": "merchant_back", "label": "Back", "fill": Color("d7dfeb")},
			], -3.12, -1.44)
		"merchant_buy":
			var buy_entries: Array = []
			for offer_variant in Array(game.rooms.get(room_coord, {}).get("merchant_stock", [])):
				var offer: Dictionary = Dictionary(offer_variant)
				var offer_short: String = GAME_INVENTORY_ITEM_FLOW.merchant_offer_short_label(game, offer)
				var price: int = GAME_INVENTORY_ITEM_FLOW.merchant_offer_price(game, offer)
				buy_entries.append({
					"id": "merchant_buy_offer_%d" % int(offer.get("offer_uid", -1)),
					"label": "%s %d%s" % [offer_short, price, merchant_resource_short],
					"fill": Color("a6efba"),
				})
			return paged_merchant_buttons(game, buy_entries, "merchant_page", "No offers", "merchant_root")
		"merchant_sell":
			var sell_entries: Array = []
			if selected_hero != null and is_instance_valid(selected_hero):
				for hero_item_variant in selected_hero.inventory_items:
					var hero_item: Dictionary = Dictionary(hero_item_variant)
					var hero_item_id: String = String(hero_item.get("item_id", ""))
					var hero_item_short: String = short_item_label(game, hero_item_id)
					var sell_price: int = GAME_INVENTORY_ITEM_FLOW.merchant_item_sell_price(game, hero_item)
					sell_entries.append({
						"id": "merchant_sell_item_%d" % int(hero_item.get("uid", -1)),
						"label": "%s +%d%s" % [hero_item_short, sell_price, merchant_resource_short],
						"fill": Color("f3d88f"),
					})
			return paged_merchant_buttons(game, sell_entries, "merchant_page", "No items", "merchant_root")
		"merchant_buyback":
			var buyback_entries: Array = []
			for buyback_offer_variant in Array(game.rooms.get(room_coord, {}).get("merchant_buyback", [])):
				var buyback_offer: Dictionary = Dictionary(buyback_offer_variant)
				var buyback_item: Dictionary = Dictionary(buyback_offer.get("item", {}))
				var buyback_item_short: String = short_item_label(game, String(buyback_item.get("item_id", "")))
				var buyback_price: int = int(buyback_offer.get("price", GAME_INVENTORY_ITEM_FLOW.merchant_item_full_price(game, buyback_item)))
				buyback_entries.append({
					"id": "merchant_buyback_offer_%d" % int(buyback_offer.get("offer_uid", -1)),
					"label": "%s %d%s" % [buyback_item_short, buyback_price, merchant_resource_short],
					"fill": Color("9bc7ff"),
				})
			return paged_merchant_buttons(game, buyback_entries, "merchant_page", "No buyback", "merchant_root")
		"trade_resource":
			var trade_buttons: Array = []
			for resource_entry in [
				{"id": "food", "label": "Food", "fill": Color("8ee28a")},
				{"id": "industry", "label": "Mat", "fill": Color("f1c26b")},
				{"id": "science", "label": "Arc", "fill": Color("8bc1ff")},
				{"id": "dust", "label": "Dust", "fill": Color("f3d88f")},
			]:
				var resource_id: String = String(resource_entry["id"])
				var amount_available: int = GAME_INVENTORY_ITEM_FLOW.merchant_resource_amount(game, resource_id)
				trade_buttons.append({
					"id": "trade_resource_%s" % resource_id,
					"label": "%s %d" % [String(resource_entry["label"]), amount_available],
					"fill": resource_entry["fill"],
				})
			trade_buttons.append({"id": "trade_back", "label": "Back", "fill": Color("d7dfeb")})
			return with_spread_angles(trade_buttons)
		"trade_target":
			var resource_to_trade: String = String(game.room_action_menu.get("trade_resource_id", ""))
			var resource_short: String = merchant_resource_short_label(resource_to_trade)
			var target_buttons: Array = []
			if selected_hero != null and is_instance_valid(selected_hero):
				for hero_in_room in game.heroes_in_room(room_coord):
					if hero_in_room == selected_hero:
						continue
					target_buttons.append({
						"id": "trade_target_%d" % int(hero_in_room.hero_index),
						"label": "%s +%d%s" % [hero_in_room.hero_name, TRADE_RESOURCE_AMOUNT, resource_short],
						"fill": Color("9bd8ff"),
					})
			if target_buttons.is_empty():
				target_buttons.append({"id": "trade_none", "label": "No target", "fill": Color("76848d")})
			target_buttons.append({"id": "trade_resource_back", "label": "Back", "fill": Color("d7dfeb")})
			return with_spread_angles(target_buttons)
		_:
			var root_buttons: Array = [
				{"id": "loot", "label": "Loot", "fill": Color("a6efba")},
				{"id": "build_menu", "label": "Build", "fill": Color("91d1ff")},
			]
			var light_label: String = "Light %d" % game.ROOM_LIGHT_DUST_COST
			if game.can_start_research_in_room(Vector2i(game.room_action_menu.get("room", game.INVALID_ROOM))):
				root_buttons.append({"id": "research", "label": "Research", "fill": Color("8bc1ff")})
			else:
				pass
			if merchant_here:
				root_buttons.append({"id": "merchant_menu", "label": "Merchant", "fill": Color("d8c1ff")})
			if crystal_carry_available_here:
				root_buttons.append({"id": "crystal_carry_menu", "label": "Carry Crystal", "fill": Color("c6a0ff")})
			root_buttons.append({"id": "light", "label": light_label, "fill": Color("f3d88f")})
			if game.heroes_in_room(room_coord).size() > 1:
				root_buttons.append({"id": "trade_menu", "label": "Trade", "fill": Color("9bd8ff")})
			return with_spread_angles(root_buttons)

static func room_action_sector_layout(game: Node) -> Array:
	var buttons: Array = room_action_button_layout(game)
	var sectors: Array = []
	if buttons.is_empty():
		return sectors
	for index in range(buttons.size()):
		var button_data: Dictionary = buttons[index]
		var center_angle: float = float(button_data.get("angle", 0.0))
		var start_angle: float = center_angle
		var end_angle: float = center_angle
		if buttons.size() == 1:
			start_angle -= 0.5
			end_angle += 0.5
		else:
			if index == 0:
				var next_angle: float = float((buttons[index + 1] as Dictionary).get("angle", center_angle))
				start_angle = center_angle - (next_angle - center_angle) * 0.5
			else:
				var prev_angle: float = float((buttons[index - 1] as Dictionary).get("angle", center_angle))
				start_angle = (prev_angle + center_angle) * 0.5
			if index == buttons.size() - 1:
				var prev_angle_last: float = float((buttons[index - 1] as Dictionary).get("angle", center_angle))
				end_angle = center_angle + (center_angle - prev_angle_last) * 0.5
			else:
				var next_angle_mid: float = float((buttons[index + 1] as Dictionary).get("angle", center_angle))
				end_angle = (center_angle + next_angle_mid) * 0.5
		var sector_data: Dictionary = button_data.duplicate(true)
		sector_data["start_angle"] = start_angle
		sector_data["end_angle"] = end_angle
		sectors.append(sector_data)
	return sectors

static func room_action_angle_near_reference(_game: Node, angle: float, reference: float) -> float:
	return reference + wrapf(angle - reference, -PI, PI)

static func room_action_button_screen_center(game: Node, button_data: Dictionary) -> Vector2:
	var menu_center: Vector2 = room_action_menu_screen_center(game)
	var angle: float = float(button_data.get("angle", 0.0))
	var overlay_scale: float = room_action_overlay_scale(game)
	var label_radius: float = game.ROOM_ACTION_LABEL_RADIUS * overlay_scale
	label_radius -= 18.0 * overlay_scale
	var minimum_radius: float = game.ROOM_ACTION_DEADZONE_RADIUS * overlay_scale + 26.0 * overlay_scale
	label_radius = maxf(label_radius, minimum_radius)
	return menu_center + Vector2(cos(angle), sin(angle)) * label_radius

static func room_action_button_at_screen_position(game: Node, screen_position: Vector2) -> String:
	if game.room_action_menu.is_empty():
		return ""
	var menu_center: Vector2 = room_action_menu_screen_center(game)
	var offset: Vector2 = screen_position - menu_center
	if offset.length() < game.ROOM_ACTION_DEADZONE_RADIUS * room_action_overlay_scale(game):
		return ""
	var pointer_angle: float = offset.angle()
	for sector_data_variant in room_action_sector_layout(game):
		var sector_data: Dictionary = sector_data_variant
		var center_angle: float = float(sector_data.get("angle", 0.0))
		var local_angle: float = room_action_angle_near_reference(game, pointer_angle, center_angle)
		if local_angle >= float(sector_data.get("start_angle", center_angle)) and local_angle <= float(sector_data.get("end_angle", center_angle)):
			return String(sector_data.get("id", ""))
	return ""

static func room_action_sector_points(_game: Node, center: Vector2, inner_radius: float, outer_radius: float, start_angle: float, end_angle: float, segments: int = 18) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var safe_segments: int = max(segments, 4)
	for step in range(safe_segments + 1):
		var t: float = float(step) / float(safe_segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)
	for step in range(safe_segments, -1, -1):
		var t: float = float(step) / float(safe_segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)
	return points

static func handle_room_action_menu_tap(game: Node, screen_position: Vector2) -> void:
	var action_id: String = room_action_button_at_screen_position(game, screen_position)
	if action_id == "":
		close_room_action_menu(game)
		game.queue_redraw()
		return
	perform_room_action(game, game.room_action_menu.get("room", game.INVALID_ROOM), action_id)

static func perform_room_action(game: Node, room_coord: Vector2i, action_id: String) -> void:
	if room_coord == game.INVALID_ROOM or not game.rooms.has(room_coord):
		return
	var minor_module_type: String = game.minor_module_type_for_action(action_id)
	var is_build_action: bool = action_id == "build_menu" or action_id == "build_minor_menu" or action_id == "build_major_menu" or action_id == "build_major_food" or action_id == "build_major_science" or action_id == "build_major_industry" or action_id == "submenu_back_build" or minor_module_type != ""
	if not is_build_action and not game.room_action_enabled(room_coord, action_id):
		close_room_action_menu(game)
		game.status_message = "That action is unavailable for %s." % game.room_title(room_coord)
		game.update_hud()
		game.queue_redraw()
		return
	game.selected_room = room_coord
	clear_room_action_menu_pointer(game)
	match action_id:
		"build_menu":
			game.room_action_menu["mode"] = "build_kind"
			focus_room_action_menu(game, room_coord, true)
			game.status_message = "Choose a build category for %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
		"build_minor_menu":
			game.room_action_menu["mode"] = "build_minor"
			focus_room_action_menu(game, room_coord, true)
			game.status_message = "Choose a minor module for %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
		"build_major_menu":
			game.room_action_menu["mode"] = "build_major"
			focus_room_action_menu(game, room_coord, true)
			game.status_message = "Choose a major module for %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
		"submenu_back":
			game.room_action_menu["mode"] = "root"
			focus_room_action_menu(game, room_coord, true)
			game.status_message = "Room actions for %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
		"submenu_back_build":
			game.room_action_menu["mode"] = "build_kind"
			focus_room_action_menu(game, room_coord, true)
			game.status_message = "Choose a build category for %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
		"merchant_menu":
			close_room_action_menu(game)
			if not game.open_room_merchant_overlay(room_coord):
				game.status_message = "No merchant is available in %s." % game.room_title(room_coord)
				game.update_hud()
				game.queue_redraw()
		"merchant_buy_menu":
			game.room_action_menu["mode"] = "merchant_buy"
			game.room_action_menu["merchant_page"] = 0
			focus_room_action_menu(game, room_coord, true)
			game.queue_redraw()
		"merchant_sell_menu":
			game.room_action_menu["mode"] = "merchant_sell"
			game.room_action_menu["merchant_page"] = 0
			focus_room_action_menu(game, room_coord, true)
			game.queue_redraw()
		"merchant_buyback_menu":
			game.room_action_menu["mode"] = "merchant_buyback"
			game.room_action_menu["merchant_page"] = 0
			focus_room_action_menu(game, room_coord, true)
			game.queue_redraw()
		"merchant_back":
			game.room_action_menu["mode"] = "root"
			focus_room_action_menu(game, room_coord, true)
			game.update_hud()
			game.queue_redraw()
		"crystal_carry_menu":
			game.room_action_menu["mode"] = "crystal_carry_confirm"
			focus_room_action_menu(game, room_coord, true)
			if game.selected_hero() != null and is_instance_valid(game.selected_hero()):
				game.status_message = "Confirm carrying the crystal with %s." % game.selected_hero().hero_name
			else:
				game.status_message = "Confirm carrying the crystal."
			game.update_hud()
			game.queue_redraw()
		"crystal_carry_back":
			game.room_action_menu["mode"] = "root"
			focus_room_action_menu(game, room_coord, true)
			game.status_message = "Room actions for %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
		"crystal_carry_confirm_action":
			close_room_action_menu(game)
			game.request_selected_hero_pick_up_crystal()
		"merchant_page_prev":
			game.room_action_menu["merchant_page"] = max(0, int(game.room_action_menu.get("merchant_page", 0)) - 1)
			game.queue_redraw()
		"merchant_page_next":
			game.room_action_menu["merchant_page"] = max(0, int(game.room_action_menu.get("merchant_page", 0)) + 1)
			game.queue_redraw()
		"trade_menu":
			game.room_action_menu["mode"] = "trade_resource"
			game.room_action_menu["trade_resource_id"] = ""
			focus_room_action_menu(game, room_coord, true)
			game.status_message = "Choose a resource to trade in %s." % game.room_title(room_coord)
			game.update_hud()
			game.queue_redraw()
		"trade_back":
			game.room_action_menu["mode"] = "root"
			focus_room_action_menu(game, room_coord, true)
			game.queue_redraw()
		"trade_resource_back":
			game.room_action_menu["mode"] = "trade_resource"
			focus_room_action_menu(game, room_coord, true)
			game.queue_redraw()
		"trade_none", "merchant_none":
			focus_room_action_menu(game, room_coord, true)
			game.queue_redraw()
		"light":
			close_room_action_menu(game)
			game.request_room_light(room_coord)
		"research":
			close_room_action_menu(game)
			game.request_room_research(room_coord)
		"loot":
			close_room_action_menu(game)
			game.request_room_loot(room_coord)
		"build_major_food":
			close_room_action_menu(game)
			game.request_room_construction(room_coord, game.MAJOR_MODULE_FOOD)
		"build_major_science":
			close_room_action_menu(game)
			game.request_room_construction(room_coord, game.MAJOR_MODULE_SCIENCE)
		"build_major_industry":
			close_room_action_menu(game)
			game.request_room_construction(room_coord, game.MAJOR_MODULE_INDUSTRY)
		_:
			if action_id.begins_with("merchant_buy_offer_"):
				var buy_offer_uid: int = action_suffix_int(action_id, "merchant_buy_offer_")
				var selected_hero_buy: Variant = game.selected_hero()
				var immediate_buy: bool = game.authoritative_simulation_active() and game.hero_ready_for_room_action(selected_hero_buy, room_coord)
				if game.request_room_merchant_buy(room_coord, buy_offer_uid):
					if immediate_buy:
						game.room_action_menu["mode"] = "merchant_buy"
						focus_room_action_menu(game, room_coord, true)
						game.queue_redraw()
					else:
						close_room_action_menu(game)
				return
			if action_id.begins_with("merchant_sell_item_"):
				var sell_item_uid: int = action_suffix_int(action_id, "merchant_sell_item_")
				var selected_hero_sell: Variant = game.selected_hero()
				var immediate_sell: bool = game.authoritative_simulation_active() and game.hero_ready_for_room_action(selected_hero_sell, room_coord)
				if game.request_room_merchant_sell(room_coord, sell_item_uid):
					if immediate_sell:
						game.room_action_menu["mode"] = "merchant_sell"
						focus_room_action_menu(game, room_coord, true)
						game.queue_redraw()
					else:
						close_room_action_menu(game)
				return
			if action_id.begins_with("merchant_buyback_offer_"):
				var buyback_offer_uid: int = action_suffix_int(action_id, "merchant_buyback_offer_")
				var selected_hero_buyback: Variant = game.selected_hero()
				var immediate_buyback: bool = game.authoritative_simulation_active() and game.hero_ready_for_room_action(selected_hero_buyback, room_coord)
				if game.request_room_merchant_buyback(room_coord, buyback_offer_uid):
					if immediate_buyback:
						game.room_action_menu["mode"] = "merchant_buyback"
						focus_room_action_menu(game, room_coord, true)
						game.queue_redraw()
					else:
						close_room_action_menu(game)
				return
			if action_id.begins_with("trade_resource_"):
				var trade_resource_id: String = action_id.trim_prefix("trade_resource_")
				game.room_action_menu["trade_resource_id"] = trade_resource_id
				game.room_action_menu["mode"] = "trade_target"
				focus_room_action_menu(game, room_coord, true)
				game.queue_redraw()
				return
			if action_id.begins_with("trade_target_"):
				var trade_target_hero_index: int = action_suffix_int(action_id, "trade_target_")
				var resource_id: String = String(game.room_action_menu.get("trade_resource_id", ""))
				if resource_id == "":
					game.room_action_menu["mode"] = "trade_resource"
					focus_room_action_menu(game, room_coord, true)
					game.queue_redraw()
					return
				var selected_hero_trade: Variant = game.selected_hero()
				var immediate_trade: bool = game.authoritative_simulation_active() and game.hero_ready_for_room_action(selected_hero_trade, room_coord)
				if game.request_room_resource_trade(room_coord, trade_target_hero_index, resource_id, TRADE_RESOURCE_AMOUNT):
					if immediate_trade:
						game.room_action_menu["mode"] = "trade_target"
						focus_room_action_menu(game, room_coord, true)
						game.queue_redraw()
					else:
						close_room_action_menu(game)
				return
			if minor_module_type != "":
				if game.request_room_construction(room_coord, minor_module_type):
					var hero_minor: Variant = game.selected_hero()
					if game.hero_ready_for_room_action(hero_minor, room_coord):
						game.room_action_menu["mode"] = "build_minor"
						focus_room_action_menu(game, room_coord, true)
						game.queue_redraw()
					else:
						close_room_action_menu(game)
				else:
					close_room_action_menu(game)

static func draw_room_action_hold(game: Node) -> void:
	if game.room_action_hold.is_empty():
		return
	var hold_room: Vector2i = game.room_action_hold.get("room", game.INVALID_ROOM)
	if hold_room == game.INVALID_ROOM or not game.rooms.has(hold_room):
		return
	var hold_elapsed: float = float(game.room_action_hold.get("elapsed", 0.0))
	if hold_elapsed < game.ROOM_ACTION_HOLD_START_DELAY:
		return
	var hold_ratio: float = clampf((hold_elapsed - game.ROOM_ACTION_HOLD_START_DELAY) / maxf(game.ROOM_ACTION_HOLD_LOADER_DURATION, 0.001), 0.0, 1.0)
	var center: Vector2 = game.room_center(hold_room)
	var radius: float = (44.0 + 20.0 * hold_ratio) * game.camera.zoom.x
	game.draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * hold_ratio, 34, Color("ffe39b"), 6.2 * game.camera.zoom.x, true)
	game.draw_circle(center, 14.0 * game.camera.zoom.x, Color(1.0, 0.93, 0.68, 0.12 + 0.16 * hold_ratio))

static func draw_room_action_menu(game: Node) -> void:
	if game.room_action_menu.is_empty():
		return
	var menu_center_screen: Vector2 = room_action_menu_screen_center(game)
	var menu_center_world: Vector2 = game.screen_to_world(menu_center_screen)
	var pointer_screen: Vector2 = room_action_menu_virtual_pointer_screen_position(game)
	var pointer_world: Vector2 = game.screen_to_world(pointer_screen)
	var hovered_action_id: String = room_action_button_at_screen_position(game, pointer_screen) if game.room_action_menu_hold_selection_active else ""
	var overlay_scale: float = room_action_overlay_scale(game)
	var menu_radius_world: float = game.ROOM_ACTION_MENU_RADIUS * overlay_scale * game.camera.zoom.x
	var center_radius_world: float = game.ROOM_ACTION_DEADZONE_RADIUS * overlay_scale * game.camera.zoom.x
	var sector_inner_radius_world: float = maxf(center_radius_world + 12.0 * overlay_scale * game.camera.zoom.x, 28.0 * overlay_scale * game.camera.zoom.x)
	var sector_outer_radius_world: float = game.ROOM_ACTION_SECTOR_OUTER_RADIUS * overlay_scale * game.camera.zoom.x
	game.draw_circle(menu_center_world, center_radius_world, Color("132129"))
	game.draw_circle(menu_center_world, center_radius_world * 1.9, Color(0.07, 0.14, 0.17, 0.12))
	game.draw_arc(menu_center_world, menu_radius_world * 0.68, 0.0, TAU, 58, Color("476775"), 2.8 * game.camera.zoom.x, true)
	if game.room_action_menu_hold_selection_active:
		game.draw_line(menu_center_world, pointer_world, Color("8fe7ff"), 3.6 * game.camera.zoom.x, true)
		game.draw_circle(pointer_world, 12.0 * overlay_scale * game.camera.zoom.x, Color("eefbff"))
		game.draw_circle(pointer_world, 20.0 * overlay_scale * game.camera.zoom.x, Color(0.72, 0.94, 1.0, 0.12))
	for sector_data_variant in room_action_sector_layout(game):
		var sector_data: Dictionary = sector_data_variant
		var button_center_screen: Vector2 = room_action_button_screen_center(game, sector_data)
		var button_center_world: Vector2 = game.screen_to_world(button_center_screen)
		var action_id: String = String(sector_data.get("id", ""))
		var enabled: bool = game.room_action_enabled(game.room_action_menu.get("room", game.INVALID_ROOM), action_id)
		var fill: Color = sector_data.get("fill", Color("9ed4ff"))
		var base_fill: Color = fill
		if not enabled:
			fill = fill.darkened(0.5)
		var highlighted: bool = hovered_action_id == action_id
		var outline_color: Color = fill.lightened(0.18) if highlighted else fill
		var outline_width: float = (4.8 if highlighted else 3.2) * game.camera.zoom.x
		if not enabled:
			outline_color = Color("8ea9b6") if highlighted else Color("5e6d75")
		var start_angle: float = float(sector_data.get("start_angle", 0.0))
		var end_angle: float = float(sector_data.get("end_angle", 0.0))
		var fill_alpha: float = clampf(float(sector_data.get("fill_alpha", 0.24)), 0.0, 1.0)
		var highlight_fill_alpha: float = clampf(float(sector_data.get("highlight_fill_alpha", fill_alpha + 0.04)), 0.0, 1.0)
		var sector_points: PackedVector2Array = room_action_sector_points(game, menu_center_world, sector_inner_radius_world, sector_outer_radius_world, start_angle, end_angle)
		game.draw_colored_polygon(sector_points, Color(fill, fill_alpha if enabled else 0.12))
		if highlighted:
			var highlighted_points: PackedVector2Array = room_action_sector_points(game, menu_center_world, sector_inner_radius_world + 10.0 * overlay_scale * game.camera.zoom.x, sector_outer_radius_world - 10.0 * overlay_scale * game.camera.zoom.x, start_angle, end_angle)
			var highlight_tint: Color = (base_fill if enabled else Color("8ea9b6")).lightened(0.14)
			game.draw_colored_polygon(highlighted_points, Color(highlight_tint, highlight_fill_alpha if enabled else 0.18))
		game.draw_arc(menu_center_world, sector_outer_radius_world, start_angle, end_angle, 18, outline_color, outline_width, true)
		game.draw_arc(menu_center_world, sector_inner_radius_world, start_angle, end_angle, 18, outline_color, outline_width * 0.85, true)
		game.draw_line(menu_center_world + Vector2(cos(start_angle), sin(start_angle)) * sector_inner_radius_world, menu_center_world + Vector2(cos(start_angle), sin(start_angle)) * sector_outer_radius_world, outline_color, outline_width * 0.8, true)
		game.draw_line(menu_center_world + Vector2(cos(end_angle), sin(end_angle)) * sector_inner_radius_world, menu_center_world + Vector2(cos(end_angle), sin(end_angle)) * sector_outer_radius_world, outline_color, outline_width * 0.8, true)
		var label_text: String = String(sector_data.get("label", ""))
		var label_rows: PackedStringArray = label_text.split("\n", false)
		var single_line_width: float = 148.0 * overlay_scale * game.camera.zoom.x
		var multiline_row_width: float = 160.0 * overlay_scale * game.camera.zoom.x
		if label_rows.size() <= 1:
			var single_position: Vector2 = Vector2(button_center_world.x - single_line_width * 0.5, button_center_world.y + 8.0 * overlay_scale * game.camera.zoom.x)
			game.draw_string(ThemeDB.fallback_font, single_position, label_text, HORIZONTAL_ALIGNMENT_CENTER, single_line_width, int(round(22.0 * overlay_scale * game.camera.zoom.x)), Color("eef8ff"))
			continue
		var row_spacing: float = 14.0 * overlay_scale * game.camera.zoom.x
		var row_anchor_y: float = button_center_world.y + 4.0 * overlay_scale * game.camera.zoom.x
		var row_start_y: float = row_anchor_y - row_spacing * float(label_rows.size() - 1) * 0.5
		for row_index in range(label_rows.size()):
			var row_text: String = String(label_rows[row_index])
			var row_font_size: int = int(round((18.0 if row_index == 0 else 16.0) * overlay_scale * game.camera.zoom.x))
			var row_position: Vector2 = Vector2(button_center_world.x - multiline_row_width * 0.5, row_start_y + row_spacing * float(row_index))
			game.draw_string(ThemeDB.fallback_font, row_position, row_text, HORIZONTAL_ALIGNMENT_CENTER, multiline_row_width, row_font_size, Color("eef8ff"))
