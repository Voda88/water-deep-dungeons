extends RefCounted

const GAME_HERO_PROFILE_FLOW: GDScript = preload("res://scripts/world/game_hero_profile_flow.gd")

static func apply_hud_styling(game: Node) -> void:
	var bottom_style: StyleBoxEmpty = StyleBoxEmpty.new()
	game.bottom_bar_panel.add_theme_stylebox_override("panel", bottom_style)
	game.room_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0, 0.95))
	game.hint_label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.95, 0.88))
	game.dust_label.add_theme_color_override("font_color", Color("f3d88f"))
	game.food_label.add_theme_color_override("font_color", Color("9ee28b"))
	game.industry_label.add_theme_color_override("font_color", Color("f1c26b"))
	game.science_label.add_theme_color_override("font_color", Color("8bc1ff"))
	game.crystal_label.add_theme_color_override("font_color", Color("f6e3a4"))
	game.wave_label.add_theme_color_override("font_color", Color("d6e4ee"))

static func status_message_is_combat_detail(status_text: String) -> bool:
	if status_text == "":
		return false
	var lower_text: String = status_text.to_lower()
	var combat_tokens: Array[String] = [
		"lunges at",
		"looses an arrow",
		"swarming",
		"striking the crystal",
		"peppering the crystal",
		"dive at the crystal",
		"hammers",
		"all heroes have fallen",
		" killed ",
	]
	for token in combat_tokens:
		if lower_text.find(token) >= 0:
			return true
	return false

static func rebuild_hero_bar(game: Node) -> void:
	if game.hero_bar == null:
		return
	for button_data_variant in game.hero_buttons:
		var button_data: Dictionary = button_data_variant
		var root_button: Button = button_data.get("button", null)
		if is_instance_valid(root_button):
			root_button.queue_free()
	game.hero_buttons.clear()
	for hero_index in range(game.heroes.size()):
		var hero_button: Button = Button.new()
		hero_button.custom_minimum_size = Vector2(102.0, 118.0)
		hero_button.toggle_mode = true
		hero_button.clip_contents = true
		hero_button.text = ""
		hero_button.pressed.connect(game._on_hero_button_pressed.bind(hero_index))
		game.hero_bar.add_child(hero_button)
		var portrait_rect: TextureRect = TextureRect.new()
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_rect.anchor_left = 0.0
		portrait_rect.anchor_top = 0.0
		portrait_rect.anchor_right = 1.0
		portrait_rect.anchor_bottom = 1.0
		portrait_rect.offset_left = -10.0
		portrait_rect.offset_top = -6.0
		portrait_rect.offset_right = 10.0
		portrait_rect.offset_bottom = -12.0
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hero_button.add_child(portrait_rect)
		var status_label: Label = Label.new()
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_label.anchor_left = 0.0
		status_label.anchor_top = 1.0
		status_label.anchor_right = 1.0
		status_label.anchor_bottom = 1.0
		status_label.offset_left = 4.0
		status_label.offset_top = -42.0
		status_label.offset_right = -4.0
		status_label.offset_bottom = -22.0
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 11)
		hero_button.add_child(status_label)
		var health_bar: ProgressBar = ProgressBar.new()
		health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_bar.anchor_left = 0.0
		health_bar.anchor_top = 1.0
		health_bar.anchor_right = 1.0
		health_bar.anchor_bottom = 1.0
		health_bar.offset_left = 8.0
		health_bar.offset_top = -18.0
		health_bar.offset_right = -8.0
		health_bar.offset_bottom = -8.0
		health_bar.show_percentage = false
		health_bar.min_value = 0.0
		health_bar.max_value = 100.0
		var health_fill_style: StyleBoxFlat = StyleBoxFlat.new()
		health_fill_style.bg_color = Color("69d36f")
		health_fill_style.corner_radius_top_left = 4
		health_fill_style.corner_radius_top_right = 4
		health_fill_style.corner_radius_bottom_left = 4
		health_fill_style.corner_radius_bottom_right = 4
		health_bar.add_theme_stylebox_override("fill", health_fill_style)
		var health_bg_style: StyleBoxFlat = StyleBoxFlat.new()
		health_bg_style.bg_color = Color("253226")
		health_bg_style.corner_radius_top_left = 4
		health_bg_style.corner_radius_top_right = 4
		health_bg_style.corner_radius_bottom_left = 4
		health_bg_style.corner_radius_bottom_right = 4
		health_bar.add_theme_stylebox_override("background", health_bg_style)
		hero_button.add_child(health_bar)
		game.hero_buttons.append({
			"button": hero_button,
			"portrait": portrait_rect,
			"status": status_label,
			"health": health_bar,
		})

static func update_restart_button_hold_fill(game: Node) -> void:
	if game.restart_button_hold_fill == null or not is_instance_valid(game.restart_button_hold_fill):
		return
	var progress: float = game.ui_button_hold_progress("restart")
	game.restart_button_hold_fill.visible = progress > 0.001
	game.restart_button_hold_fill.anchor_right = progress
	game.restart_button_hold_fill.offset_right = 0.0
	var fill_style: StyleBoxFlat = game.restart_button_hold_fill.get_theme_stylebox("panel") as StyleBoxFlat
	if fill_style != null:
		fill_style.corner_radius_top_right = 10 if progress >= 0.995 else 0
		fill_style.corner_radius_bottom_right = 10 if progress >= 0.995 else 0

static func update_hud(game: Node) -> void:
	game.update_selected_hero_flags()
	var inventory_open: bool = game.inventory_overlay != null and game.inventory_overlay.visible
	var merchant_open: bool = game.merchant_overlay != null and game.merchant_overlay.visible
	var research_open: bool = game.research_overlay != null and game.research_overlay.visible
	if inventory_open:
		game.refresh_open_inventory_overlay()
	if merchant_open:
		game.refresh_open_merchant_overlay()
	if research_open:
		game.refresh_research_overlay()
	var door_income: Dictionary = game.calculate_door_rewards()
	var major_income: Dictionary = game.calculate_major_module_wave_rewards()
	var operate_bonus: Dictionary = Dictionary(major_income.get("operate_bonus", {}))
	var operate_food_bonus: int = int(operate_bonus.get("food", 0))
	var operate_industry_bonus: int = int(operate_bonus.get("industry", 0))
	var operate_science_bonus: int = int(operate_bonus.get("science", 0))
	var projected_food_income: int = int(door_income.get("food", 0)) + int(major_income.get("food", 0))
	var projected_industry_income: int = int(door_income.get("industry", 0)) + int(major_income.get("industry", 0))
	var projected_science_income: int = int(door_income.get("science", 0)) + int(major_income.get("science", 0))
	var crystal_carried: bool = game.crystal_holder != null and is_instance_valid(game.crystal_holder)
	var calm_phase: bool = not game.wave_in_progress() and not crystal_carried
	var inventory_allowed: bool = game.inventory_actions_allowed_for_local_peer()
	game.dust_label.text = "Dust %d" % game.dust
	game.food_label.text = "Food %d +%d%s" % [game.food, projected_food_income, " (Op+%d)" % operate_food_bonus if operate_food_bonus > 0 else ""]
	game.industry_label.text = "Mat %d +%d%s" % [game.industry, projected_industry_income, " (Op+%d)" % operate_industry_bonus if operate_industry_bonus > 0 else ""]
	game.science_label.text = "Arc %d +%d%s" % [game.science, projected_science_income, " (Op+%d)" % operate_science_bonus if operate_science_bonus > 0 else ""]
	if game.crystal_holder != null and is_instance_valid(game.crystal_holder):
		game.crystal_label.text = "Crystal  %s Carrying" % game.crystal_holder.hero_name
	else:
		game.crystal_label.text = "Crystal"
	game.wave_label.text = "Floor %d  Doors %d  Waves %d  Dark %d" % [game.floor_index, game.doors_opened, game.wave_index, count_dark_open_rooms(game)]
	game.room_label.text = game.room_summary(game.selected_room)
	game.inventory_button.disabled = inventory_open or merchant_open or research_open or game.selected_hero() == null or not inventory_allowed
	game.inventory_button.text = "Inventory"
	game.restart_button.disabled = false
	game.restart_button.text = "Restart"
	update_restart_button_hold_fill(game)
	game.build_menu.visible = game.build_menu_open and not inventory_open and not merchant_open and not research_open
	game.build_menu_title.text = game.build_menu_title_text()
	game.turret_button.disabled = not game.any_room_can_build_or_repair_turret()
	game.turret_button.text = game.turret_button_text(game.selected_room)
	game.food_major_button.disabled = not game.any_room_can_build_or_repair_major(game.MAJOR_MODULE_FOOD)
	game.science_major_button.disabled = not game.any_room_can_build_or_repair_major(game.MAJOR_MODULE_SCIENCE)
	game.industry_major_button.disabled = not game.any_room_can_build_or_repair_major(game.MAJOR_MODULE_INDUSTRY)
	game.food_major_button.text = game.major_button_text(game.selected_room, game.MAJOR_MODULE_FOOD, "Food")
	game.science_major_button.text = game.major_button_text(game.selected_room, game.MAJOR_MODULE_SCIENCE, "Arcana")
	game.industry_major_button.text = game.major_button_text(game.selected_room, game.MAJOR_MODULE_INDUSTRY, "Materials")
	update_calm_speed_bar(game, calm_phase)
	update_hero_button_text(game)
	update_runtime_button_state(game)
	if String(game.room_flow_status_message) == "":
		game.room_flow_status_message = "Open a door to discover new room events."
	game.hint_label.text = game.room_flow_status_message
	game.update_network_ui()
	game.update_hero_select_overlay()

static func selected_calm_speed_multiplier(game: Node) -> float:
	return float(game.CALM_SPEED_OPTIONS[clampi(game.calm_speed_option_index, 0, game.CALM_SPEED_OPTIONS.size() - 1)])

static func apply_calm_speed_multiplier_to_heroes(game: Node) -> void:
	var multiplier: float = selected_calm_speed_multiplier(game)
	for hero in game.heroes:
		if is_instance_valid(hero):
			hero.set_calm_movement_multiplier(multiplier)

static func update_calm_speed_bar(game: Node, calm_phase: bool) -> void:
	if game.calm_speed_bar == null:
		return
	var host_can_control_speed: bool = not game.multiplayer_session_active() or game.multiplayer.is_server()
	game.calm_speed_bar.visible = calm_phase and host_can_control_speed
	for option_index in range(mini(game.calm_speed_buttons.size(), game.CALM_SPEED_OPTIONS.size())):
		var speed_button: Button = game.calm_speed_buttons[option_index]
		if not is_instance_valid(speed_button):
			continue
		speed_button.button_pressed = option_index == game.calm_speed_option_index
		speed_button.disabled = not host_can_control_speed

static func _on_calm_speed_button_pressed(game: Node, option_index: int) -> void:
	if game.multiplayer_session_active() and not game.multiplayer.is_server():
		return
	game.calm_speed_option_index = clampi(option_index, 0, game.CALM_SPEED_OPTIONS.size() - 1)
	apply_calm_speed_multiplier_to_heroes(game)
	update_hud(game)

static func update_hero_button_text(game: Node) -> void:
	for hero_index in range(mini(game.hero_buttons.size(), game.heroes.size())):
		var button_data: Dictionary = game.hero_buttons[hero_index]
		var hero_button: Button = button_data.get("button", null)
		var portrait_rect: TextureRect = button_data.get("portrait", null)
		var status_label: Label = button_data.get("status", null)
		var health_bar: ProgressBar = button_data.get("health", null)
		var hero: Variant = game.heroes[hero_index]
		if not is_instance_valid(hero_button):
			continue
		var controllable: bool = game.can_local_control_hero_index(hero_index)
		var alive: bool = game.hero_is_active(hero)
		var class_id: String = game.hero_profile_class_id(hero_index)
		if portrait_rect != null:
			portrait_rect.texture = GAME_HERO_PROFILE_FLOW.hero_portrait_texture(game, class_id)
			portrait_rect.modulate = Color.WHITE if alive else Color(0.42, 0.42, 0.42, 0.95)
		if status_label != null:
			var status_text: String = "DEAD"
			if alive:
				status_text = hero.hero_name
			if alive and hero.carrying_crystal:
				status_text += " C"
			status_label.text = status_text
			status_label.add_theme_color_override("font_color", Color("f7f7f2") if controllable else Color("9aa8b2"))
		if health_bar != null:
			health_bar.max_value = maxf(hero.max_health if alive else 100.0, 1.0)
			health_bar.value = clampf(hero.current_health if alive else 0.0, 0.0, health_bar.max_value)
			health_bar.visible = alive
		hero_button.button_pressed = hero_index == game.selected_hero_index and alive
		hero_button.disabled = not controllable or not alive

static func update_runtime_button_state(game: Node) -> void:
	var inventory_open: bool = game.inventory_overlay != null and game.inventory_overlay.visible
	var merchant_open: bool = game.merchant_overlay != null and game.merchant_overlay.visible
	if game.exit_button != null:
		game.exit_button.visible = not inventory_open and not merchant_open and game.carrier_in_exit_room() and game.crystal_holder != null and is_instance_valid(game.crystal_holder) and game.can_local_control_hero_index(game.crystal_holder.hero_index)
		game.exit_button.disabled = not game.all_heroes_in_exit_room()
		game.exit_button.text = "Escape Floor" if game.exit_button.disabled == false else "Gather Heroes"

static func count_dark_open_rooms(game: Node) -> int:
	var count: int = 0
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = game.rooms[room_coord]
		if room_coord != game.crystal_room and room["opened"] and not room["lit"]:
			count += 1
	return count
