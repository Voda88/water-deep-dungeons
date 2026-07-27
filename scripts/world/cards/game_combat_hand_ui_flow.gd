extends RefCounted

static func active_hand_returning_uids(game: Node) -> Dictionary:
	var returning: Dictionary = {}
	for animation_variant in game.hand_card_return_animations:
		var animation: Dictionary = animation_variant
		returning[int(animation.get("card_uid", -1))] = true
	return returning

static func selected_hand_hero(game: Node) -> Variant:
	if not game.lobby_game_started or game.game_over:
		return null
	if game.hero_select_overlay != null and game.hero_select_overlay.visible:
		return null
	if game.inventory_overlay != null and game.inventory_overlay.visible:
		return null
	var hero: Variant = game.selected_hero()
	if hero == null or not is_instance_valid(hero) or not game.can_local_control_hero_index(hero.hero_index):
		return null
	if hero.hand_cards.is_empty():
		return null
	return hero

static func combat_hand_panel_rect(game: Node, hero: Variant) -> Rect2:
	var viewport_size: Vector2 = game.get_viewport_rect().size
	var slot_count: int = maxi(maxi(hero.hand_cards.size(), hero.max_hand_size), 1)
	var visible_slots: int = mini(slot_count, 5)
	var panel_width: float = minf(viewport_size.x - game.CARD_HAND_SIDE_MARGIN * 2.0, game.CARD_HAND_CARD_SIZE.x * float(visible_slots) + game.CARD_HAND_GAP * float(maxi(visible_slots - 1, 0)) + 24.0)
	var panel_height: float = game.CARD_HAND_CARD_SIZE.y + 44.0
	return Rect2(Vector2((viewport_size.x - panel_width) * 0.5, viewport_size.y - panel_height - game.CARD_HAND_BOTTOM_MARGIN), Vector2(panel_width, panel_height))

static func combat_hand_card_rect(game: Node, hero: Variant, card_index: int) -> Rect2:
	var panel_rect: Rect2 = combat_hand_panel_rect(game, hero)
	var visible_count: int = maxi(hero.hand_cards.size(), 1)
	var total_width: float = game.CARD_HAND_CARD_SIZE.x * float(visible_count) + game.CARD_HAND_GAP * float(maxi(visible_count - 1, 0))
	var start_x: float = panel_rect.get_center().x - total_width * 0.5
	return Rect2(Vector2(start_x + float(card_index) * (game.CARD_HAND_CARD_SIZE.x + game.CARD_HAND_GAP), panel_rect.position.y + 8.0), game.CARD_HAND_CARD_SIZE)

static func combat_hand_info_button_rect(game: Node, hero: Variant) -> Rect2:
	var panel_rect: Rect2 = combat_hand_panel_rect(game, hero)
	return Rect2(Vector2(panel_rect.position.x + 10.0, panel_rect.position.y + panel_rect.size.y - 28.0), Vector2(56.0, 20.0))

static func combat_hand_info_panel_rect(game: Node, hero: Variant) -> Rect2:
	var panel_rect: Rect2 = combat_hand_panel_rect(game, hero)
	var viewport_size: Vector2 = game.get_viewport_rect().size
	var panel_width: float = minf(viewport_size.x - 24.0, 332.0)
	var panel_height: float = 138.0
	return Rect2(Vector2((viewport_size.x - panel_width) * 0.5, panel_rect.position.y - panel_height - 10.0), Vector2(panel_width, panel_height))

static func combat_hand_reaction_rect(game: Node, hero: Variant, card_index: int) -> Rect2:
	var card_rect: Rect2 = combat_hand_card_rect(game, hero, card_index)
	return Rect2(card_rect.position + Vector2(card_rect.size.x - 24.0, 6.0), Vector2(18.0, 18.0))

static func combat_hand_reaction_touch_rect(game: Node, hero: Variant, card_index: int) -> Rect2:
	return combat_hand_reaction_rect(game, hero, card_index).grow(8.0)

static func combat_hand_insertion_index(game: Node, hero: Variant, screen_position: Vector2) -> int:
	if hero == null or not is_instance_valid(hero) or hero.hand_cards.is_empty():
		return 0
	var insertion_index: int = 0
	for card_index in range(hero.hand_cards.size()):
		var card_rect: Rect2 = combat_hand_card_rect(game, hero, card_index)
		if screen_position.x < card_rect.get_center().x:
			return card_index
		insertion_index = card_index + 1
	return insertion_index

static func combat_hand_card_index_at_screen_position(game: Node, hero: Variant, screen_position: Vector2) -> int:
	for card_index in range(hero.hand_cards.size() - 1, -1, -1):
		if combat_hand_card_rect(game, hero, card_index).has_point(screen_position):
			return card_index
	return -1

static func hand_card_footer_bits(game: Node, hand_card: Dictionary) -> Array[String]:
	var footer_bits: Array[String] = []
	var interval: int = int(hand_card.get("door_interval", 0))
	if interval > 0:
		footer_bits.append("Every %d" % interval)
	var food_cost: int = int(hand_card.get("food_cost", 0))
	if food_cost > 0:
		footer_bits.append("%d Food" % food_cost)
	var stamina_cost: float = float(hand_card.get("stamina_cost", 0.0))
	if stamina_cost > 0.0:
		footer_bits.append("%.0f Sta" % stamina_cost)
	var expires_on: int = int(hand_card.get("expires_on_doors_opened", -1))
	if expires_on >= 0:
		footer_bits.append("Exp %d" % maxi(0, expires_on - game.doors_opened))
	if game.card_supports_reaction(hand_card):
		footer_bits.append("React")
	return footer_bits

static func open_hand_card_info(game: Node, hero: Variant, hand_card: Dictionary) -> void:
	if hero == null or not is_instance_valid(hero):
		game.active_hand_info_card.clear()
		game.active_hand_info_hero_index = -1
		return
	game.active_hand_info_card = hand_card.duplicate(true)
	game.active_hand_info_hero_index = hero.hero_index
	game.queue_redraw()

static func clear_hand_card_info(game: Node) -> void:
	game.active_hand_info_card.clear()
	game.active_hand_info_hero_index = -1

static func dismiss_hand_card_info_if_outside(game: Node, screen_position: Vector2) -> bool:
	if game.active_hand_info_card.is_empty():
		return false
	var hero: Variant = selected_hand_hero(game)
	if hero == null or not is_instance_valid(hero) or game.active_hand_info_hero_index != hero.hero_index:
		clear_hand_card_info(game)
		return false
	if combat_hand_info_panel_rect(game, hero).has_point(screen_position):
		return false
	clear_hand_card_info(game)
	game.queue_redraw()
	return true

static func draw_hand_card(game: Node, screen_rect: Rect2, hand_card: Dictionary, highlighted: bool, reaction_rect_screen: Rect2 = Rect2()) -> void:
	var world_rect: Rect2 = game.screen_rect_to_world_rect(screen_rect)
	var fill: Color = hand_card.get("color", Color("cfe6ff"))
	if highlighted:
		fill = fill.lightened(0.12)
	game.draw_rect(world_rect, fill, true)
	game.draw_rect(world_rect, Color("eff8ff"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	game.draw_string(font, world_rect.position + Vector2(5.0, 13.0), String(hand_card.get("name", "Card")), HORIZONTAL_ALIGNMENT_LEFT, world_rect.size.x - 10.0, 10, Color("091116"))
	var phase_label: String = "Calm"
	match String(hand_card.get("phase", "combat")):
		"combat":
			phase_label = "Fight"
		"any":
			phase_label = "Any"
	var tag_line: String = "%s  %s" % [phase_label, String(hand_card.get("target_scope_label", game.card_target_scope_label(String(hand_card.get("target_scope", "same_room")))))]
	if bool(hand_card.get("requires_line_of_effect", false)):
		tag_line += "  LoE"
	game.draw_string(font, world_rect.position + Vector2(5.0, 26.0), tag_line, HORIZONTAL_ALIGNMENT_LEFT, world_rect.size.x - 10.0, 8, Color("102028"))
	var info_lines: Array = Array(hand_card.get("description_lines", []))
	for line_index in range(mini(info_lines.size(), 2)):
		game.draw_string(font, world_rect.position + Vector2(5.0, 40.0 + float(line_index) * 10.0), String(info_lines[line_index]), HORIZONTAL_ALIGNMENT_LEFT, world_rect.size.x - 10.0, 8, Color("102028"))
	var footer_bits: Array[String] = hand_card_footer_bits(game, hand_card)
	if not footer_bits.is_empty():
		game.draw_string(font, world_rect.position + Vector2(5.0, world_rect.size.y - 7.0), "  ".join(footer_bits), HORIZONTAL_ALIGNMENT_LEFT, world_rect.size.x - 10.0, 8, Color("20323d"))
	if game.card_supports_reaction(hand_card) and reaction_rect_screen.size != Vector2.ZERO:
		var reaction_world_rect: Rect2 = game.screen_rect_to_world_rect(reaction_rect_screen)
		game.draw_rect(reaction_world_rect, Color(0.08, 0.14, 0.18, 0.92), true)
		game.draw_rect(reaction_world_rect, Color("d8eef8"), false, 1.5)
		if bool(hand_card.get("reaction_enabled", false)):
			game.draw_line(reaction_world_rect.position + Vector2(3.0, 10.0), reaction_world_rect.position + Vector2(7.0, 14.0), Color("9cffb4"), 2.0, true)
			game.draw_line(reaction_world_rect.position + Vector2(7.0, 14.0), reaction_world_rect.position + Vector2(15.0, 4.0), Color("9cffb4"), 2.0, true)
		game.draw_string(font, reaction_world_rect.position + Vector2(-12.0, 15.0), "R", HORIZONTAL_ALIGNMENT_LEFT, 10.0, 10, Color("eef8ff"))

static func draw_hand_card_info_panel(game: Node, hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if game.active_hand_info_card.is_empty() or game.active_hand_info_hero_index != hero.hero_index:
		return
	var panel_screen: Rect2 = combat_hand_info_panel_rect(game, hero)
	var panel_world: Rect2 = game.screen_rect_to_world_rect(panel_screen)
	game.draw_rect(panel_world, Color(0.06, 0.1, 0.13, 0.96), true)
	game.draw_rect(panel_world, Color("83a6b4"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	game.draw_string(font, panel_world.position + Vector2(12.0, 18.0), String(game.active_hand_info_card.get("name", "Card")), HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x - 24.0, 14, Color("eef8ff"))
	var tag_line: String = "%s  %s" % [
		"Fight" if String(game.active_hand_info_card.get("phase", "combat")) == "combat" else ("Any" if String(game.active_hand_info_card.get("phase", "combat")) == "any" else "Calm"),
		String(game.active_hand_info_card.get("target_scope_label", game.card_target_scope_label(String(game.active_hand_info_card.get("target_scope", "same_room"))))),
	]
	if bool(game.active_hand_info_card.get("requires_line_of_effect", false)):
		tag_line += "  LoE"
	if game.card_supports_reaction(game.active_hand_info_card):
		tag_line += "  Reaction"
	game.draw_string(font, panel_world.position + Vector2(12.0, 35.0), tag_line, HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x - 24.0, 11, Color("bed6e3"))
	var y: float = panel_world.position.y + 55.0
	for line_variant in Array(game.active_hand_info_card.get("description_lines", [])):
		game.draw_string(font, Vector2(panel_world.position.x + 12.0, y), String(line_variant), HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x - 24.0, 11, Color("dce9f2"))
		y += 15.0
	for footer_line in hand_card_footer_bits(game, game.active_hand_info_card):
		game.draw_string(font, Vector2(panel_world.position.x + 12.0, y), String(footer_line), HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x - 24.0, 10, Color("f2d8a4"))
		y += 13.0

static func draw_combat_hand(game: Node) -> void:
	var hero: Variant = selected_hand_hero(game)
	if hero == null:
		return
	var panel_screen: Rect2 = combat_hand_panel_rect(game, hero)
	var panel_world: Rect2 = game.screen_rect_to_world_rect(panel_screen)
	game.draw_rect(panel_world, Color(0.07, 0.12, 0.16, 0.86), true)
	game.draw_rect(panel_world, Color("5f8796"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	game.draw_string(font, panel_world.position + Vector2(10.0, 16.0), "%s Cards" % hero.hero_name, HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x * 0.52, 13, Color("eef8ff"))
	var phase_status: String = "Combat" if game.wave_in_progress() else "Calm"
	game.draw_string(font, panel_world.position + Vector2(panel_world.size.x - 116.0, 16.0), phase_status, HORIZONTAL_ALIGNMENT_LEFT, 108.0, 12, Color("bde3ff"))
	game.draw_string(font, panel_world.position + Vector2(panel_world.size.x - 116.0, 30.0), "%d/%d" % [hero.hand_cards.size(), hero.max_hand_size], HORIZONTAL_ALIGNMENT_LEFT, 108.0, 11, Color("ffd8a0"))
	var info_button_world: Rect2 = game.screen_rect_to_world_rect(combat_hand_info_button_rect(game, hero))
	var info_button_fill: Color = Color(0.12, 0.18, 0.21, 0.96)
	if not game.active_hand_drag.is_empty() and combat_hand_info_button_rect(game, hero).grow(12.0).has_point(Vector2(game.active_hand_drag.get("current_screen", Vector2.ZERO))):
		info_button_fill = Color(0.2, 0.28, 0.18, 0.98)
	game.draw_rect(info_button_world, info_button_fill, true)
	game.draw_rect(info_button_world, Color("8db2c2"), false, 1.5)
	game.draw_string(font, info_button_world.position + Vector2(14.0, 14.0), "Info", HORIZONTAL_ALIGNMENT_LEFT, info_button_world.size.x - 16.0, 11, Color("eef8ff"))
	var hidden_uids: Dictionary = active_hand_returning_uids(game)
	if not game.active_hand_drag.is_empty():
		hidden_uids[int(game.active_hand_drag.get("card_uid", -1))] = true
	for card_index in range(hero.hand_cards.size()):
		var hand_card: Dictionary = hero.hand_cards[card_index]
		var card_uid: int = int(hand_card.get("uid", -1))
		if hidden_uids.has(card_uid):
			continue
		draw_hand_card(game, combat_hand_card_rect(game, hero, card_index), hand_card, false, combat_hand_reaction_rect(game, hero, card_index))
	for animation_variant in game.hand_card_return_animations:
		var animation: Dictionary = animation_variant
		var progress: float = clampf(float(animation.get("progress", 1.0)), 0.0, 1.0)
		var from_rect: Rect2 = animation.get("from_rect", Rect2())
		var to_rect: Rect2 = animation.get("to_rect", Rect2())
		var eased: float = ease(progress if from_rect.position.distance_to(to_rect.position) > 0.0 else 1.0, -1.8)
		var animation_rect: Rect2 = Rect2(from_rect.position.lerp(to_rect.position, eased), from_rect.size.lerp(to_rect.size, eased))
		draw_hand_card(game, animation_rect, animation.get("card", {}), true)
	if not game.active_hand_drag.is_empty():
		var drag_card: Dictionary = game.active_hand_drag.get("card", {})
		var drag_rect: Rect2 = Rect2(Vector2(game.active_hand_drag.get("current_screen", Vector2.ZERO)) - game.CARD_HAND_CARD_SIZE * 0.5, game.CARD_HAND_CARD_SIZE)
		draw_hand_card(game, drag_rect, drag_card, true)
	draw_hand_card_info_panel(game, hero)

static func begin_hand_card_drag(game: Node, pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	var hero: Variant = selected_hand_hero(game)
	if hero == null or hero.hand_cards.is_empty():
		return false
	var card_index: int = combat_hand_card_index_at_screen_position(game, hero, screen_position)
	if card_index < 0:
		return false
	game.active_hand_drag = {
		"pointer_kind": pointer_kind,
		"pointer_id": pointer_id,
		"hero_index": hero.hero_index,
		"source_index": card_index,
		"card_uid": int((hero.hand_cards[card_index] as Dictionary).get("uid", -1)),
		"card": (hero.hand_cards[card_index] as Dictionary).duplicate(true),
		"start_screen": screen_position,
		"current_screen": screen_position,
		"tap_toggle_candidate": game.card_supports_reaction(hero.hand_cards[card_index]),
	}
	game.pause_autonomous_heroes_for_hand_drag()
	game.clear_room_action_hold()
	game.close_room_action_menu()
	return true

static func update_hand_card_drag(game: Node, pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if game.active_hand_drag.is_empty():
		return false
	if String(game.active_hand_drag.get("pointer_kind", "")) != pointer_kind or int(game.active_hand_drag.get("pointer_id", -1)) != pointer_id:
		return false
	game.active_hand_drag["current_screen"] = screen_position
	return true

static func start_hand_card_return_animation(game: Node, hand_card: Dictionary, from_rect: Rect2, to_rect: Rect2) -> void:
	game.hand_card_return_animations.append({
		"card_uid": int(hand_card.get("uid", -1)),
		"card": hand_card.duplicate(true),
		"from_rect": from_rect,
		"to_rect": to_rect,
		"progress": 0.0,
	})

static func advance_hand_card_return_animations(game: Node, delta: float) -> void:
	if game.hand_card_return_animations.is_empty():
		return
	var active_animations: Array = []
	for animation_variant in game.hand_card_return_animations:
		var animation: Dictionary = animation_variant
		animation["progress"] = minf(float(animation.get("progress", 0.0)) + delta / game.CARD_HAND_RETURN_DURATION, 1.0)
		if float(animation["progress"]) < 1.0:
			active_animations.append(animation)
	game.hand_card_return_animations = active_animations

static func finish_hand_card_drag(game: Node, pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if game.active_hand_drag.is_empty():
		return false
	if String(game.active_hand_drag.get("pointer_kind", "")) != pointer_kind or int(game.active_hand_drag.get("pointer_id", -1)) != pointer_id:
		return false
	var hero_index: int = int(game.active_hand_drag.get("hero_index", -1))
	var source_index: int = int(game.active_hand_drag.get("source_index", -1))
	var drag_card: Dictionary = Dictionary(game.active_hand_drag.get("card", {}))
	var source_hero: Variant = game.heroes[hero_index] if hero_index >= 0 and hero_index < game.heroes.size() else null
	var source_rect: Rect2 = combat_hand_card_rect(game, source_hero, source_index) if source_hero != null and is_instance_valid(source_hero) else Rect2(screen_position - game.CARD_HAND_CARD_SIZE * 0.5, game.CARD_HAND_CARD_SIZE)
	var drag_rect: Rect2 = Rect2(screen_position - game.CARD_HAND_CARD_SIZE * 0.5, game.CARD_HAND_CARD_SIZE)
	var drag_distance: float = Vector2(game.active_hand_drag.get("start_screen", screen_position)).distance_to(screen_position)
	if source_hero != null and is_instance_valid(source_hero) and combat_hand_info_button_rect(game, source_hero).grow(12.0).has_point(screen_position):
		open_hand_card_info(game, source_hero, drag_card)
		start_hand_card_return_animation(game, drag_card, drag_rect, source_rect)
		game.active_hand_drag.clear()
		return true
	if bool(game.active_hand_drag.get("tap_toggle_candidate", false)) and drag_distance <= game.CARD_HAND_TAP_DISTANCE and source_rect.grow(18.0).has_point(screen_position):
		if game.toggle_hand_card_reaction(source_hero, source_index):
			if game.multiplayer_session_active() and not game.authoritative_simulation_active():
				game.server_commit_hand_state.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, game.serialized_hand_state(source_hero))
			elif game.multiplayer_session_active() and game.multiplayer.is_server():
				game.broadcast_network_snapshot()
			game.update_hud()
			game.queue_redraw()
		game.active_hand_drag.clear()
		return true
	if source_hero != null and is_instance_valid(source_hero) and combat_hand_panel_rect(game, source_hero).grow(18.0).has_point(screen_position):
		var insertion_index: int = combat_hand_insertion_index(game, source_hero, screen_position)
		if game.move_hand_card(source_hero, source_index, insertion_index):
			if game.multiplayer_session_active() and not game.authoritative_simulation_active():
				game.server_commit_hand_state.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, game.serialized_hand_state(source_hero))
			elif game.multiplayer_session_active() and game.multiplayer.is_server():
				game.broadcast_network_snapshot()
			game.update_hud()
			game.active_hand_drag.clear()
			return true
	var played: bool = false
	var target_world_position: Vector2 = game.screen_to_world(screen_position)
	if screen_position.distance_to(source_rect.get_center()) > game.CARD_HAND_RELEASE_DISTANCE and source_hero != null and is_instance_valid(source_hero) and game.card_target_is_valid(source_hero, drag_card, target_world_position):
		if game.multiplayer_session_active() and not game.authoritative_simulation_active():
			game.server_request_play_card.rpc_id(game.NETWORK_HOST_PEER_ID, hero_index, int(drag_card.get("uid", -1)), target_world_position)
			played = true
		else:
			played = game.play_card_for_hero(hero_index, int(drag_card.get("uid", -1)), target_world_position)
			if played and game.multiplayer_session_active() and game.multiplayer.is_server():
				game.broadcast_network_snapshot()
		if not played:
			start_hand_card_return_animation(game, drag_card, drag_rect, source_rect)
	else:
		start_hand_card_return_animation(game, drag_card, drag_rect, source_rect)
	game.active_hand_drag.clear()
	return true
