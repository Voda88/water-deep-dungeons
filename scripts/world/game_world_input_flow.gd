extends RefCounted

static func _unhandled_input(game: Node, event: InputEvent) -> void:
	if game.game_over:
		return
	if game.hero_select_overlay != null and game.hero_select_overlay.visible:
		return
	if game.research_overlay != null and game.research_overlay.visible:
		return
	if game.merchant_overlay != null and game.merchant_overlay.visible:
		return
	if event is InputEventKey and handle_pc_hero_hotkeys(game, event):
		return
	if game.inventory_overlay != null and game.inventory_overlay.visible:
		handle_inventory_input(game, event)
		return
	if event is InputEventScreenTouch:
		game.handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		game.handle_screen_drag(event)
	elif event is InputEventMouseButton:
		game.handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		game.handle_mouse_motion(event)

static func handle_pc_hero_hotkeys(game: Node, event: InputEventKey) -> bool:
	if event == null or not event.pressed or event.echo:
		return false
	var keycode: int = int(event.keycode)
	if keycode == 0:
		keycode = int(event.physical_keycode)
	var hero_index: int = -1
	match keycode:
		KEY_1, KEY_KP_1:
			hero_index = 0
		KEY_2, KEY_KP_2:
			hero_index = 1
		KEY_3, KEY_KP_3:
			hero_index = 2
		KEY_4, KEY_KP_4:
			hero_index = 3
	if hero_index < 0:
		return false
	if hero_index >= game.heroes.size() or not game.can_local_control_hero_index(hero_index):
		return true
	game.select_hero_by_index(hero_index)
	return true

static func handle_inventory_input(game: Node, event: InputEvent) -> void:
	if game.inventory_overlay == null or not game.inventory_overlay.visible:
		return
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			game.inventory_overlay.pointer_press(touch_event.position)
		else:
			game.inventory_overlay.pointer_release(touch_event.position)
	elif event is InputEventScreenDrag:
		game.inventory_overlay.pointer_move(event.position)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			game.inventory_overlay.pointer_press(mouse_event.position)
		else:
			game.inventory_overlay.pointer_release(mouse_event.position)
	elif event is InputEventMouseMotion:
		game.inventory_overlay.pointer_move(event.position)

static func try_handle_crystal_tap(game: Node, world_position: Vector2) -> bool:
	if game.crystal_holder != null or game.crystal_ground_room == game.INVALID_ROOM or not is_exit_discovered(game):
		return false
	if not game.rooms.has(game.crystal_ground_room) or not game.rooms[game.crystal_ground_room]["opened"]:
		return false
	if game.crystal_world_position().distance_to(world_position) > 40.0:
		return false
	game.selected_room = game.crystal_ground_room
	var hero: Variant = game.selected_hero()
	if hero != null and hero.current_room == game.crystal_ground_room and hero.pending_room == game.HERO_INVALID_ROOM and hero.is_idle():
		game.status_message = "Crystal selected. Use room actions to confirm Carry Crystal with %s." % hero.hero_name
	else:
		game.status_message = "Crystal selected. Move a hero into this room, then use room actions > Carry Crystal."
	return true

static func can_selected_hero_pick_up_crystal(game: Node) -> bool:
	var hero: Variant = game.selected_hero()
	return hero != null and game.crystal_holder == null and game.crystal_ground_room != game.INVALID_ROOM and is_exit_discovered(game) and hero.current_room == game.crystal_ground_room and hero.pending_room == game.HERO_INVALID_ROOM and hero.is_idle()

static func is_exit_discovered(game: Node) -> bool:
	return game.exit_room != game.INVALID_ROOM and game.rooms.has(game.exit_room) and game.rooms[game.exit_room]["opened"]

static func drop_crystal(game: Node, room_coord: Vector2i) -> void:
	if game.crystal_holder != null and is_instance_valid(game.crystal_holder):
		game.crystal_holder.carrying_crystal = false
	game.crystal_holder = null
	game.crystal_ground_room = room_coord
	game.crystal_prompt_visible = false
	game.crystal_pressure_timer_left = 0.0
