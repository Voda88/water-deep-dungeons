extends RefCounted

static func ensure_runtime_ui(game: Node) -> void:
	game.apply_hud_styling()
	ensure_performance_label(game)
	ensure_hero_select_toggle_button(game)
	ensure_calm_speed_bar(game)
	ensure_hero_bar_panel(game)
	ensure_exit_button(game)
	ensure_restart_button_hold_fill(game)
	ensure_inventory_overlay(game)
	ensure_merchant_overlay(game)
	ensure_research_overlay(game)
	ensure_hero_select_overlay(game)
	game.update_hero_select_overlay()
	game.update_network_ui()

static func ensure_performance_label(game: Node) -> void:
	if game.performance_label != null and is_instance_valid(game.performance_label):
		return
	var hbox: HBoxContainer = game.top_bar_panel.get_node("HBox")
	game.performance_label = Label.new()
	game.performance_label.name = "PerformanceLabel"
	game.performance_label.custom_minimum_size = Vector2(220.0, 0.0)
	game.performance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	game.performance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game.performance_label.add_theme_font_size_override("font_size", 14)
	game.performance_label.add_theme_color_override("font_color", Color("d6e4ee"))
	hbox.add_child(game.performance_label)
	if game.center_button != null and is_instance_valid(game.center_button):
		var center_index: int = hbox.get_children().find(game.center_button)
		if center_index >= 0:
			hbox.move_child(game.performance_label, center_index)
	if game.has_method("refresh_performance_ui_now"):
		game.refresh_performance_ui_now()

static func ensure_hero_select_toggle_button(game: Node) -> void:
	if game.hero_select_toggle_button != null:
		return
	var hbox: HBoxContainer = game.top_bar_panel.get_node("HBox")
	game.hero_select_toggle_button = Button.new()
	game.hero_select_toggle_button.custom_minimum_size = Vector2(78.0, 36.0)
	game.hero_select_toggle_button.text = "Lobby"
	game.hero_select_toggle_button.add_theme_font_size_override("font_size", 16)
	game.hero_select_toggle_button.pressed.connect(game._on_hero_select_toggle_button_pressed)
	game.hero_select_toggle_button.button_down.connect(game._on_ui_button_hold_down.bind("lobby_enter"))
	game.hero_select_toggle_button.button_up.connect(game._on_ui_button_hold_up.bind("lobby_enter"))
	game.hero_select_toggle_button.mouse_exited.connect(game._on_ui_button_hold_cancel.bind("lobby_enter"))
	hbox.add_child(game.hero_select_toggle_button)
	hbox.move_child(game.hero_select_toggle_button, max(hbox.get_child_count() - 2, 0))

static func ensure_calm_speed_bar(game: Node) -> void:
	if game.calm_speed_bar != null:
		return
	var hbox: HBoxContainer = game.top_bar_panel.get_node("HBox")
	game.calm_speed_bar = HBoxContainer.new()
	game.calm_speed_bar.add_theme_constant_override("separation", 4)
	var speed_label: Label = Label.new()
	speed_label.text = "Speed"
	speed_label.add_theme_font_size_override("font_size", 15)
	speed_label.add_theme_color_override("font_color", Color("d6e4ee"))
	game.calm_speed_bar.add_child(speed_label)
	for option_index in range(game.CALM_SPEED_OPTIONS.size()):
		var multiplier: int = int(game.CALM_SPEED_OPTIONS[option_index])
		var speed_button: Button = Button.new()
		speed_button.custom_minimum_size = Vector2(44.0, 34.0)
		speed_button.add_theme_font_size_override("font_size", 15)
		speed_button.toggle_mode = true
		speed_button.text = "%dx" % multiplier
		speed_button.pressed.connect(game._on_calm_speed_button_pressed.bind(option_index))
		game.calm_speed_bar.add_child(speed_button)
		game.calm_speed_buttons.append(speed_button)
	hbox.add_child(game.calm_speed_bar)
	hbox.move_child(game.calm_speed_bar, 0)

static func ensure_hero_bar_panel(game: Node) -> void:
	if game.hero_bar_panel != null:
		return
	var ui_root: Node = game.get_node(^"UI")
	game.hero_bar_panel = PanelContainer.new()
	game.hero_bar_panel.anchor_left = 1.0
	game.hero_bar_panel.anchor_top = 0.0
	game.hero_bar_panel.anchor_right = 1.0
	game.hero_bar_panel.anchor_bottom = 1.0
	game.hero_bar_panel.offset_left = -126.0
	game.hero_bar_panel.offset_top = 72.0
	game.hero_bar_panel.offset_right = -10.0
	game.hero_bar_panel.offset_bottom = -12.0
	game.hero_bar_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(game.hero_bar_panel)
	game.hero_bar = VBoxContainer.new()
	game.hero_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.hero_bar.add_theme_constant_override("separation", 8)
	game.hero_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	game.hero_bar_panel.add_child(game.hero_bar)

static func ensure_exit_button(game: Node) -> void:
	if game.exit_button != null:
		return
	var ui_root: Node = game.get_node(^"UI")
	game.exit_button = Button.new()
	game.exit_button.visible = false
	game.exit_button.anchor_left = 0.5
	game.exit_button.anchor_top = 1.0
	game.exit_button.anchor_right = 0.5
	game.exit_button.anchor_bottom = 1.0
	game.exit_button.offset_left = -170.0
	game.exit_button.offset_top = -246.0
	game.exit_button.offset_right = 170.0
	game.exit_button.offset_bottom = -178.0
	game.exit_button.add_theme_font_size_override("font_size", 26)
	game.exit_button.text = "Escape Floor"
	game.exit_button.pressed.connect(game._on_exit_button_pressed)
	ui_root.add_child(game.exit_button)

static func ensure_restart_button_hold_fill(game: Node) -> void:
	if game.restart_button_hold_fill != null or game.restart_button == null or not is_instance_valid(game.restart_button):
		return
	game.restart_button_hold_fill = Panel.new()
	game.restart_button_hold_fill.name = "HoldFill"
	game.restart_button_hold_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.restart_button_hold_fill.show_behind_parent = true
	game.restart_button_hold_fill.anchor_left = 0.0
	game.restart_button_hold_fill.anchor_top = 0.0
	game.restart_button_hold_fill.anchor_right = 0.0
	game.restart_button_hold_fill.anchor_bottom = 1.0
	game.restart_button_hold_fill.offset_left = 0.0
	game.restart_button_hold_fill.offset_top = 0.0
	game.restart_button_hold_fill.offset_right = 0.0
	game.restart_button_hold_fill.offset_bottom = 0.0
	var restart_fill_style: StyleBoxFlat = StyleBoxFlat.new()
	restart_fill_style.bg_color = Color("d26448")
	restart_fill_style.corner_radius_top_left = 10
	restart_fill_style.corner_radius_bottom_left = 10
	restart_fill_style.corner_radius_top_right = 10
	restart_fill_style.corner_radius_bottom_right = 10
	game.restart_button_hold_fill.add_theme_stylebox_override("panel", restart_fill_style)
	game.restart_button.add_child(game.restart_button_hold_fill)
	game.restart_button.move_child(game.restart_button_hold_fill, 0)

static func ensure_inventory_overlay(game: Node) -> void:
	if game.inventory_overlay != null:
		return
	var ui_root: Node = game.get_node(^"UI")
	game.inventory_overlay = game.INVENTORY_OVERLAY_SCENE.instantiate()
	game.inventory_overlay.visible = false
	ui_root.add_child(game.inventory_overlay)
	game.inventory_overlay.close_requested.connect(game._on_inventory_close_requested)
	game.inventory_overlay.inventory_changed.connect(game._on_inventory_overlay_changed)
	game.inventory_overlay.pack_layout_changed.connect(game._on_inventory_pack_layout_changed)
	game.inventory_overlay.level_up_requested.connect(game._on_inventory_level_up_requested)
	game.inventory_overlay.item_dropped.connect(game._on_inventory_item_dropped)
	game.inventory_overlay.spellbook_slots_changed.connect(game._on_inventory_spellbook_slots_changed)

static func ensure_merchant_overlay(game: Node) -> void:
	if game.merchant_overlay != null:
		return
	var ui_root: Node = game.get_node(^"UI")
	game.merchant_overlay = game.MERCHANT_OVERLAY_SCENE.instantiate()
	game.merchant_overlay.visible = false
	ui_root.add_child(game.merchant_overlay)
	game.merchant_overlay.close_requested.connect(game._on_merchant_overlay_close_requested)
	game.merchant_overlay.buy_requested.connect(game._on_merchant_overlay_buy_requested)
	game.merchant_overlay.sell_requested.connect(game._on_merchant_overlay_sell_requested)
	game.merchant_overlay.buyback_requested.connect(game._on_merchant_overlay_buyback_requested)

static func ensure_research_overlay(game: Node) -> void:
	if game.research_overlay != null:
		return
	var ui_root: Node = game.get_node(^"UI")
	game.research_overlay = ColorRect.new()
	game.research_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.research_overlay.color = Color(0.03, 0.06, 0.08, 0.84)
	game.research_overlay.visible = false
	game.research_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(game.research_overlay)

	game.research_panel = PanelContainer.new()
	game.research_panel.anchor_left = 0.08
	game.research_panel.anchor_top = 0.08
	game.research_panel.anchor_right = 0.92
	game.research_panel.anchor_bottom = 0.92
	game.research_overlay.add_child(game.research_panel)

	var research_vbox: VBoxContainer = VBoxContainer.new()
	research_vbox.add_theme_constant_override("separation", 10)
	game.research_panel.add_child(research_vbox)

	game.research_title_label = Label.new()
	game.research_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.research_title_label.add_theme_font_size_override("font_size", 24)
	game.research_title_label.text = "Research Crystal"
	research_vbox.add_child(game.research_title_label)

	game.research_room_label = Label.new()
	game.research_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.research_room_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.research_room_label.add_theme_font_size_override("font_size", 14)
	research_vbox.add_child(game.research_room_label)

	var research_row: HBoxContainer = HBoxContainer.new()
	research_row.add_theme_constant_override("separation", 12)
	research_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	research_vbox.add_child(research_row)

	var research_list_panel: PanelContainer = PanelContainer.new()
	research_list_panel.custom_minimum_size = Vector2(240.0, 0.0)
	research_row.add_child(research_list_panel)

	var research_list_vbox: VBoxContainer = VBoxContainer.new()
	research_list_vbox.add_theme_constant_override("separation", 8)
	research_list_panel.add_child(research_list_vbox)
	for choice_index in range(4):
		var choice_button: Button = Button.new()
		choice_button.toggle_mode = true
		choice_button.custom_minimum_size = Vector2(0.0, 76.0)
		choice_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice_button.add_theme_font_size_override("font_size", 15)
		choice_button.pressed.connect(game._on_research_choice_button_pressed.bind(choice_index))
		research_list_vbox.add_child(choice_button)
		game.research_choice_buttons.append(choice_button)

	var research_detail_panel: PanelContainer = PanelContainer.new()
	research_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	research_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	research_row.add_child(research_detail_panel)

	var research_detail_vbox: VBoxContainer = VBoxContainer.new()
	research_detail_vbox.add_theme_constant_override("separation", 10)
	research_detail_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	research_detail_panel.add_child(research_detail_vbox)

	game.research_detail_title_label = Label.new()
	game.research_detail_title_label.add_theme_font_size_override("font_size", 24)
	research_detail_vbox.add_child(game.research_detail_title_label)

	game.research_detail_summary_label = Label.new()
	game.research_detail_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.research_detail_summary_label.add_theme_font_size_override("font_size", 15)
	research_detail_vbox.add_child(game.research_detail_summary_label)

	game.research_detail_stats_label = Label.new()
	game.research_detail_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.research_detail_stats_label.add_theme_font_size_override("font_size", 15)
	game.research_detail_stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	research_detail_vbox.add_child(game.research_detail_stats_label)

	game.research_detail_cost_label = Label.new()
	game.research_detail_cost_label.add_theme_font_size_override("font_size", 16)
	game.research_detail_cost_label.add_theme_color_override("font_color", Color("8bc1ff"))
	research_detail_vbox.add_child(game.research_detail_cost_label)

	game.research_start_button = Button.new()
	game.research_start_button.custom_minimum_size = Vector2(160.0, 44.0)
	game.research_start_button.add_theme_font_size_override("font_size", 18)
	game.research_start_button.text = "Start Research"
	game.research_start_button.pressed.connect(game._on_research_start_button_pressed)
	research_detail_vbox.add_child(game.research_start_button)

	var research_footer: HBoxContainer = HBoxContainer.new()
	research_footer.alignment = BoxContainer.ALIGNMENT_END
	research_footer.add_theme_constant_override("separation", 10)
	research_vbox.add_child(research_footer)

	game.research_reroll_button = Button.new()
	game.research_reroll_button.custom_minimum_size = Vector2(110.0, 42.0)
	game.research_reroll_button.text = "Reroll"
	game.research_reroll_button.add_theme_font_size_override("font_size", 17)
	game.research_reroll_button.pressed.connect(game._on_research_reroll_button_pressed)
	research_footer.add_child(game.research_reroll_button)

	var research_close_button: Button = Button.new()
	research_close_button.custom_minimum_size = Vector2(110.0, 42.0)
	research_close_button.text = "Later"
	research_close_button.add_theme_font_size_override("font_size", 17)
	research_close_button.pressed.connect(game._on_research_close_button_pressed)
	research_footer.add_child(research_close_button)

static func ensure_hero_select_overlay(game: Node) -> void:
	if game.hero_select_overlay != null:
		return
	var ui_root: Node = game.get_node(^"UI")
	game.hero_select_overlay = game.LOBBY_SCREEN_SCENE.instantiate()
	ui_root.add_child(game.hero_select_overlay)

	game.hero_select_panel = game.hero_select_overlay.get_node(^"Panel")
	game.hero_select_title_label = game.hero_select_overlay.get_node(^"Panel/RootVBox/TitleLabel")
	game.network_panel = game.hero_select_overlay.get_node(^"Panel/RootVBox/NetworkPanel")
	game.network_bar = game.hero_select_overlay.get_node(^"Panel/RootVBox/NetworkPanel/NetworkVBox/NetworkBar")
	game.network_address_input = game.hero_select_overlay.get_node(^"Panel/RootVBox/NetworkPanel/NetworkVBox/NetworkBar/HostIPInput")
	game.network_host_button = game.hero_select_overlay.get_node(^"Panel/RootVBox/NetworkPanel/NetworkVBox/NetworkBar/HostButton")
	game.network_join_button = game.hero_select_overlay.get_node(^"Panel/RootVBox/NetworkPanel/NetworkVBox/NetworkBar/JoinButton")
	game.network_disconnect_button = game.hero_select_overlay.get_node(^"Panel/RootVBox/NetworkPanel/NetworkVBox/NetworkBar/LeaveButton")
	game.network_status_label = game.hero_select_overlay.get_node(^"Panel/RootVBox/NetworkPanel/NetworkVBox/NetworkBar/StatusLabel")
	game.network_discovery_option = game.hero_select_overlay.get_node(^"Panel/RootVBox/NetworkPanel/NetworkVBox/LanGames")
	game.hero_select_detail_portrait = game.hero_select_overlay.get_node(^"Panel/RootVBox/ContentRow/DetailPanel/DetailVBox/Portrait")
	game.hero_select_detail_title_label = game.hero_select_overlay.get_node(^"Panel/RootVBox/ContentRow/DetailPanel/DetailVBox/DetailTitleLabel")
	game.hero_select_detail_summary_label = game.hero_select_overlay.get_node(^"Panel/RootVBox/ContentRow/DetailPanel/DetailVBox/DetailSummaryLabel")
	game.hero_select_detail_hint_label = game.hero_select_overlay.get_node(^"Panel/RootVBox/ContentRow/DetailPanel/DetailVBox/DetailHintLabel")
	game.hero_select_player_list = game.hero_select_overlay.get_node(^"Panel/RootVBox/ContentRow/PlayerPanel/PlayerVBox/PlayerList")
	game.lobby_debug_link = game.hero_select_overlay.get_node(^"DebugLink")
	game.lobby_debug_view = game.hero_select_overlay.get_node(^"DebugView")
	game.lobby_debug_back_button = game.hero_select_overlay.get_node(^"DebugView/BackButton")
	game.lobby_debug_research_panel = game.hero_select_overlay.get_node(^"DebugView/Panel")
	game.lobby_debug_unlock_all_button = game.hero_select_overlay.get_node(^"DebugView/Panel/VBox/UnlockAllButton")
	game.lobby_debug_starting_room_test_items = game.hero_select_overlay.get_node(^"DebugView/Panel/VBox/StartingRoomTestItems")
	game.hero_select_new_game_button = game.hero_select_overlay.get_node(^"Panel/RootVBox/FooterBar/NewGameButton")
	game.hero_select_load_game_button = game.hero_select_overlay.get_node(^"Panel/RootVBox/FooterBar/LoadGameButton")
	game.hero_select_start_button = game.hero_select_overlay.get_node(^"Panel/RootVBox/FooterBar/StartButton")

	game.network_address_input.text = game.NETWORK_DEFAULT_ADDRESS
	game.network_host_button.pressed.connect(game._on_network_host_button_pressed)
	game.network_join_button.pressed.connect(game._on_network_join_button_pressed)
	game.network_disconnect_button.pressed.connect(game._on_network_disconnect_button_pressed)
	game.network_discovery_option.item_selected.connect(game._on_network_discovery_host_selected)
	game.refresh_lan_host_selector()
	game.hero_select_new_game_button.pressed.connect(game._on_hero_select_new_game_button_pressed)
	game.hero_select_load_game_button.pressed.connect(game._on_hero_select_load_game_button_pressed)
	game.hero_select_start_button.pressed.connect(game._on_hero_select_start_button_pressed)
	game.lobby_debug_unlock_all_button.pressed.connect(game._on_lobby_debug_unlock_all_button_pressed)
	game.lobby_debug_starting_room_test_items.toggled.connect(game._on_lobby_debug_starting_room_test_items_toggled)
	game.lobby_debug_link.pressed.connect(game._on_lobby_debug_link_pressed)
	game.lobby_debug_back_button.pressed.connect(game._on_lobby_debug_back_button_pressed)

	game.lobby_debug_research_buttons.clear()
	var module_grid: GridContainer = game.hero_select_overlay.get_node(^"DebugView/Panel/VBox/ModuleGrid")
	for module_type_variant in game.minor_module_catalog():
		var module_type: String = String(module_type_variant)
		var unlock_button: Button = Button.new()
		unlock_button.custom_minimum_size = Vector2(0.0, 34.0)
		unlock_button.add_theme_font_size_override("font_size", 13)
		unlock_button.pressed.connect(game._on_lobby_debug_research_button_pressed.bind(module_type))
		module_grid.add_child(unlock_button)
		game.lobby_debug_research_buttons[module_type] = unlock_button

	game.hero_select_cards.clear()
	var card_grid: GridContainer = game.hero_select_overlay.get_node(^"Panel/RootVBox/ContentRow/HeroTilePanel/CardGrid")
	for hero_index in range(game.HERO_COUNT):
		var card_button: Button = Button.new()
		card_button.toggle_mode = true
		card_button.custom_minimum_size = Vector2(0.0, 94.0)
		card_button.add_theme_font_size_override("font_size", 15)
		card_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		card_button.pressed.connect(game._on_hero_select_card_pressed.bind(hero_index))
		card_grid.add_child(card_button)
		game.hero_select_cards[hero_index] = {
			"button": card_button,
		}

	game.hero_select_detail_class_buttons.clear()
	var class_grid: GridContainer = game.hero_select_overlay.get_node(^"Panel/RootVBox/ContentRow/DetailPanel/DetailVBox/ClassGrid")
	for class_id_variant in game.HERO_CLASS_ORDER:
		var class_id: String = String(class_id_variant)
		var class_def: Dictionary = game.hero_class_definition(class_id)
		var class_button: Button = Button.new()
		class_button.toggle_mode = true
		class_button.custom_minimum_size = Vector2(0.0, 38.0)
		class_button.text = String(class_def.get("name", class_id.capitalize()))
		class_button.add_theme_font_size_override("font_size", 15)
		class_button.pressed.connect(game._on_hero_select_detail_class_pressed.bind(class_id))
		class_grid.add_child(class_button)
		game.hero_select_detail_class_buttons[class_id] = class_button
