extends Node2D

const HERO_SCENE: PackedScene = preload("res://scenes/actors/hero.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/enemy.tscn")
const INVENTORY_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/inventory_overlay.tscn")
const GRID_SIZE: Vector2i = Vector2i(7, 7)
const ROOM_SPACING: Vector2 = Vector2(548.0, 358.0)
const ROOM_DOOR_GAP: float = 10.0
const ROOM_LAYOUT_CLEARANCE: float = 4.0
const DOOR_VISUAL_WIDTH: float = 42.0
const DOOR_VISUAL_THICKNESS: float = 10.0
const ROOM_WALKABLE_INSET: float = 4.0
const ROOM_SLOT_INSET: float = 18.0
const ROOM_NAV_CELL_SIZE: float = 12.0
const ROOM_NAV_WALKABLE_MARGIN: float = 3.0
const INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const DOOR_OPEN_DURATION: float = 1.82
const FRONTIER_DOOR_RADIUS: float = 24.0
const ROOM_TEMPLATE_NOOK: String = "nook"
const ROOM_TEMPLATE_GALLERY: String = "gallery"
const ROOM_TEMPLATE_WORKSHOP: String = "workshop"
const ROOM_TEMPLATE_FORGE: String = "forge"
const FLOOR_THEME_CAVERN: String = "cavern"
const FLOOR_THEME_FUNGAL: String = "fungal"
const FLOOR_THEME_RUINS: String = "ruins"
const FLOOR_THEME_ORDER: Array[String] = [
	FLOOR_THEME_CAVERN,
	FLOOR_THEME_FUNGAL,
	FLOOR_THEME_RUINS,
]
const ENEMY_TYPE_LIZARDMAN: String = "lizardman"
const ENEMY_TYPE_GOBLIN: String = "goblin"
const ENEMY_TYPE_KOBOLD: String = "kobold"
const ENEMY_TYPE_GOLEM: String = "golem"
const ENEMY_TYPE_GOBLIN_SHAMAN: String = "goblin_shaman"
const MINOR_MODULE_TURRET: String = "laser_turret"
const MINOR_MODULE_PULSE: String = "pulse_turret"
const MINOR_MODULE_CANNON: String = "cannon_turret"
const MAJOR_MODULE_FOOD: String = "food"
const MAJOR_MODULE_SCIENCE: String = "science"
const MAJOR_MODULE_INDUSTRY: String = "industry"
const MAJOR_MODULE_COST: int = 14
const MINOR_MODULE_MAX_HEALTH: float = 80.0
const MAJOR_MODULE_MAX_HEALTH: float = 180.0
const PROJECTILE_SPEED: float = 950.0
const HERO_COUNT: int = 4
const HERO_CLASS_FIGHTER: String = "fighter"
const HERO_CLASS_CLERIC: String = "cleric"
const HERO_CLASS_ROGUE: String = "rogue"
const HERO_CLASS_WIZARD: String = "wizard"
const HERO_CLASS_ORDER: Array[String] = [
	HERO_CLASS_FIGHTER,
	HERO_CLASS_CLERIC,
	HERO_CLASS_ROGUE,
	HERO_CLASS_WIZARD,
]
const NETWORK_HOST_PEER_ID: int = 1
const NETWORK_PORT: int = 7777
const NETWORK_MAX_CLIENTS: int = HERO_COUNT - 1
const NETWORK_SNAPSHOT_INTERVAL: float = 0.12
const NETWORK_DEFAULT_ADDRESS: String = "127.0.0.1"
const INVENTORY_CANVAS_SIZE: Vector2i = Vector2i(9, 8)
const INVENTORY_BASE_ORIGIN: Vector2i = Vector2i(3, 3)
const INVENTORY_BASE_SIZE: Vector2i = Vector2i(2, 2)
const DOOR_REWARD_FOOD_BASE: int = 4
const DOOR_REWARD_INDUSTRY_BASE: int = 4
const DOOR_REWARD_SCIENCE_BASE: int = 4
const DOOR_REWARD_FOOD_MODULE: int = 2
const DOOR_REWARD_INDUSTRY_MODULE: int = 3
const DOOR_REWARD_SCIENCE_MODULE: int = 2
const WAVE_WARNING_DURATION: float = 1.0
const WAVE_STAGGER_ROOM_INTERVAL: float = 2.0
const WAVE_STAGGER_ENEMY_INTERVAL: float = 0.1
const CRYSTAL_PRESSURE_INTERVAL: float = 6.0
const CRYSTAL_PRESSURE_WARNING_DURATION: float = 0.65
const CRYSTAL_PRESSURE_ENEMIES_PER_ROOM: int = 3
const ROOM_ACTION_HOLD_START_DELAY: float = 0.2
const ROOM_ACTION_HOLD_LOADER_DURATION: float = 0.1
const ROOM_ACTION_SUBMENU_HOLD_DURATION: float = 0.17
const ROOM_ACTION_HOLD_CANCEL_DISTANCE: float = 58.0
const ROOM_ACTION_MENU_RADIUS: float = 178.0
const ROOM_ACTION_BUTTON_RADIUS: float = 66.0
const ROOM_ACTION_DEADZONE_RADIUS: float = 16.0
const ROOM_ACTION_SECTOR_OUTER_RADIUS: float = 252.0
const ROOM_ACTION_LABEL_RADIUS: float = 168.0
const GROUND_ITEM_DRAW_SCALE: float = 17.0
const GROUND_ITEM_PICK_MIN_SIZE: float = 46.0
const GROUND_ITEM_PICK_RADIUS: float = 34.0
const RESOURCE_FLOAT_DURATION: float = 1.15
const RESOURCE_FLOAT_RISE: float = 52.0
const HEAL_FOOD_COST: int = 3
const POST_WAVE_HEAL_RATE: float = 210.0
const BUILD_DURATION_CALM: float = 0.9
const BUILD_DURATION_WAVE: float = 2.4
const LEVEL_UP_PACK_SEQUENCE: Array[Vector2i] = [
	Vector2i(1, 2),
	Vector2i(2, 1),
	Vector2i(1, 3),
	Vector2i(2, 2),
	Vector2i(3, 1),
]
const CAMERA_MIN_ZOOM: float = 0.72
const CAMERA_MAX_ZOOM: float = 1.2
const CAMERA_DEFAULT_ZOOM: float = 0.86
const CAMERA_DRAG_THRESHOLD: float = 14.0
const CAMERA_INTERACTION_COOLDOWN: float = 0.28
const CAMERA_MANUAL_PAN_COOLDOWN: float = 1.1
const CAMERA_SOFT_FOLLOW_SPEED: float = 6.5
const CAMERA_ROOM_ACTION_PAN_SPEED: float = 9.5
const CAMERA_PAN_DRAG_MULTIPLIER: float = 1.52
const CAMERA_SOFT_FOLLOW_OFFSET: Vector2 = Vector2(0.0, -70.0)
const CAMERA_BOUNDS_PADDING: Vector2 = Vector2(360.0, 320.0)
const CAMERA_DISCOVERED_PAN_SLACK: Vector2 = Vector2(220.0, 180.0)
const HERO_SELECTION_RADIUS: float = 58.0
const CALM_SPEED_OPTIONS: Array = [1, 2, 5, 10]
const CARD_HAND_CARD_SIZE: Vector2 = Vector2(64.0, 88.0)
const CARD_HAND_GAP: float = 8.0
const CARD_HAND_BOTTOM_MARGIN: float = 4.0
const CARD_HAND_SIDE_MARGIN: float = 12.0
const CARD_HAND_RELEASE_DISTANCE: float = 84.0
const CARD_HAND_RETURN_DURATION: float = 0.18
const CARD_HAND_TAP_DISTANCE: float = 18.0
const UI_BUTTON_HOLD_DURATION: float = 0.3
const UI_RESTART_HOLD_DURATION: float = 1.0
const CARDINAL_DIRS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]

@onready var camera: Camera2D = $Camera2D
@onready var static_dungeon_layer = $StaticDungeonLayer
@onready var actor_layer: Node2D = $ActorLayer
@onready var enemy_layer: Node2D = $EnemyLayer
@onready var top_bar_panel: PanelContainer = $UI/TopBar/Margin/Panel
@onready var bottom_bar_panel: PanelContainer = $UI/BottomBar/Margin/Panel
@onready var dust_label: Label = $UI/TopBar/Margin/Panel/HBox/DustLabel
@onready var food_label: Label = $UI/TopBar/Margin/Panel/HBox/FoodLabel
@onready var industry_label: Label = $UI/TopBar/Margin/Panel/HBox/IndustryLabel
@onready var science_label: Label = $UI/TopBar/Margin/Panel/HBox/ScienceLabel
@onready var crystal_label: Label = $UI/TopBar/Margin/Panel/HBox/CrystalLabel
@onready var wave_label: Label = $UI/TopBar/Margin/Panel/HBox/WaveLabel
@onready var center_button: Button = $UI/TopBar/Margin/Panel/HBox/CenterButton
@onready var room_label: Label = $UI/BottomBar/Margin/Panel/VBox/RoomLabel
@onready var hint_label: Label = $UI/BottomBar/Margin/Panel/VBox/HintLabel
@onready var inventory_button: Button = $UI/BottomBar/Margin/Panel/VBox/Actions/InventoryButton
@onready var stamina_toggle_button: Button = $UI/BottomBar/Margin/Panel/VBox/Actions/StaminaToggleButton
@onready var restart_button: Button = $UI/BottomBar/Margin/Panel/VBox/Actions/RestartButton
@onready var build_menu: Control = $UI/BuildMenu
@onready var build_menu_title: Label = $UI/BuildMenu/Panel/VBox/Title
@onready var turret_button: Button = $UI/BuildMenu/Panel/VBox/Buttons/TurretButton
@onready var food_major_button: Button = $UI/BuildMenu/Panel/VBox/Buttons/FoodMajorButton
@onready var science_major_button: Button = $UI/BuildMenu/Panel/VBox/Buttons/ScienceMajorButton
@onready var industry_major_button: Button = $UI/BuildMenu/Panel/VBox/Buttons/IndustryMajorButton

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var item_defs: Dictionary = {}
var hero_profiles: Array = []
var rooms: Dictionary = {}
var heroes: Array = []
var enemies: Array = []
var projectiles: Array = []
var floating_resource_texts: Array = []
var pending_enemy_spawns: Array = []
var opening_room: Vector2i = INVALID_ROOM
var opening_origin_room: Vector2i = INVALID_ROOM
var opening_hero: Variant = null
var opening_timer_left: float = 0.0
var opening_heroes: Array = []
var selected_room: Vector2i = Vector2i.ZERO
var crystal_room: Vector2i = Vector2i(3, 3)
var exit_room: Vector2i = INVALID_ROOM
var floor_index: int = 1
var selected_hero_index: int = 0
var crystal_holder: Variant = null
var crystal_ground_room: Vector2i = INVALID_ROOM
var crystal_prompt_visible: bool = false
var crystal_pressure_timer_left: float = 0.0
var dust: int = 4
var food: int = 10
var industry: int = 14
var science: int = 0
var crystal_health: float = 100.0
var stamina_use_enabled: bool = true
var opened_rooms: int = 0
var wave_index: int = 0
var doors_opened: int = 0
var game_over: bool = false
var status_message: String = "Drag to pan, open rooms, then use Build to place modules on room slots."
var build_menu_open: bool = false
var pending_build_type: String = ""
var camera_bounds: Rect2 = Rect2()
var touch_points: Dictionary = {}
var active_touch_id: int = -1
var touch_start_screen: Vector2 = Vector2.ZERO
var touch_dragging: bool = false
var touch_pan_last_screen: Vector2 = Vector2.ZERO
var pinch_active: bool = false
var pinch_last_distance: float = 0.0
var pinch_last_midpoint: Vector2 = Vector2.ZERO
var mouse_pressed: bool = false
var mouse_dragging: bool = false
var mouse_press_screen: Vector2 = Vector2.ZERO
var camera_interaction_cooldown: float = 0.0
var hero_select_overlay: Control = null
var hero_select_panel: PanelContainer = null
var hero_select_title_label: Label = null
var hero_select_cards: Dictionary = {}
var hero_select_start_button: Button = null
var hero_select_toggle_button: Button = null
var hero_select_active_index: int = 0
var hero_select_detail_portrait: TextureRect = null
var hero_select_detail_title_label: Label = null
var hero_select_detail_summary_label: Label = null
var hero_select_detail_hint_label: Label = null
var hero_select_detail_class_buttons: Dictionary = {}
var hero_select_player_list: VBoxContainer = null
var network_panel: PanelContainer = null
var network_bar: HBoxContainer = null
var network_address_input: LineEdit = null
var network_host_button: Button = null
var network_join_button: Button = null
var network_disconnect_button: Button = null
var network_status_label: Label = null
var hero_owner_peer_ids: Array = []
var lobby_peer_ready: Dictionary = {}
var lobby_game_started: bool = false
var network_snapshot_timer: float = 0.0
var calm_speed_bar: HBoxContainer = null
var calm_speed_buttons: Array = []
var calm_speed_option_index: int = 1
var hero_bar: HBoxContainer = null
var crystal_action_button: Button = null
var exit_button: Button = null
var hero_buttons: Array = []
var inventory_overlay: Variant = null
var inventory_session: Dictionary = {}
var room_action_hold: Dictionary = {}
var room_action_menu: Dictionary = {}
var room_action_menu_hold_selection_active: bool = false
var room_action_camera_target_active: bool = false
var room_action_camera_target: Vector2 = Vector2.ZERO
var pending_room_loot_requests: Dictionary = {}
var pending_room_action_requests: Dictionary = {}
var door_wave_auto_heal_pending: bool = false
var door_wave_healing_active: bool = false
var pending_room_constructions: Array = []
var next_enemy_uid: int = 1
var next_item_uid: int = 1
var next_card_uid: int = 1
var global_item_card_states: Dictionary = {}
var global_item_passive_timers: Dictionary = {}
var active_hand_drag: Dictionary = {}
var hand_card_return_animations: Array = []
var active_hand_info_card: Dictionary = {}
var active_hand_info_hero_index: int = -1
var ui_button_hold: Dictionary = {}
var restart_button_hold_fill: Panel = null
var room_nav_cache: Dictionary = {}
var hero_portrait_cache: Dictionary = {}
var pending_melee_attacks: Array = []

func _ready() -> void:
	rng.randomize()
	item_defs = build_item_defs()
	setup_multiplayer_callbacks()
	center_button.pressed.connect(_on_center_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	stamina_toggle_button.toggled.connect(_on_stamina_toggle_button_toggled)
	turret_button.pressed.connect(_on_turret_button_pressed)
	food_major_button.pressed.connect(_on_food_major_button_pressed)
	science_major_button.pressed.connect(_on_science_major_button_pressed)
	industry_major_button.pressed.connect(_on_industry_major_button_pressed)
	restart_button.button_down.connect(_on_ui_button_hold_down.bind("restart"))
	restart_button.button_up.connect(_on_ui_button_hold_up.bind("restart"))
	restart_button.mouse_exited.connect(_on_ui_button_hold_cancel.bind("restart"))
	ensure_runtime_ui()
	if static_dungeon_layer != null:
		static_dungeon_layer.configure(self)
	build_dungeon(true)
	spawn_heroes()
	reset_hero_owner_peer_ids()
	sync_lobby_peer_ready_states(true)
	selected_room = crystal_room
	center_camera()
	update_hud()
	set_hero_select_overlay_visible(true)
	queue_redraw()

func invalidate_static_dungeon_layer() -> void:
	if static_dungeon_layer != null:
		static_dungeon_layer.rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		return
	if hero_select_overlay != null and hero_select_overlay.visible:
		return
	if inventory_overlay != null and inventory_overlay.visible:
		handle_inventory_input(event)
		return
	if event is InputEventScreenTouch:
		handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		handle_screen_drag(event)
	elif event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

func _physics_process(delta: float) -> void:
	if game_over:
		return
	if not lobby_game_started:
		maybe_broadcast_network_snapshot(delta)
		return
	advance_room_action_hold(delta)
	if not authoritative_simulation_active():
		return
	update_hero_combat_movement_mode()
	advance_room_opening(delta)
	advance_hero_movement()
	advance_spell_scroll_studies()
	advance_pending_enemy_spawns(delta)
	advance_crystal_pressure(delta)
	advance_enemy_routes(delta)
	advance_projectiles(delta)
	advance_floating_resource_texts(delta)
	advance_room_constructions(delta)
	process_combat(delta)
	advance_hero_stamina_effects(delta)
	advance_passive_item_combat_procs(delta)
	process_modules(delta)
	cleanup_enemies()
	advance_wave_recovery(delta)
	if crystal_health <= 0.0:
		crystal_health = 0.0
		game_over = true
		status_message = "Crystal destroyed. Restart to try again."
		update_hud()
	maybe_broadcast_network_snapshot(delta)

func _process(delta: float) -> void:
	if game_over:
		advance_ui_button_hold(delta)
		queue_redraw()
		return
	advance_ui_button_hold(delta)
	advance_hand_card_return_animations(delta)
	advance_camera(delta)
	queue_redraw()

func _draw() -> void:
	draw_rooms()
	draw_active_hand_card_target_preview()
	draw_projectiles()
	draw_floating_resource_texts()
	draw_room_action_hold()
	draw_room_action_menu()
	draw_combat_hand()

func active_hand_drag_target_preview() -> Dictionary:
	if active_hand_drag.is_empty():
		return {}
	var hero_index: int = int(active_hand_drag.get("hero_index", -1))
	if hero_index < 0 or hero_index >= heroes.size():
		return {}
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return {}
	var current_screen: Vector2 = Vector2(active_hand_drag.get("current_screen", Vector2.ZERO))
	if combat_hand_panel_rect(hero).grow(18.0).has_point(current_screen):
		return {}
	var hand_card: Dictionary = Dictionary(active_hand_drag.get("card", {}))
	var target_world_position: Vector2 = screen_to_world(current_screen)
	var target_data: Dictionary = resolve_card_target(hero, hand_card, target_world_position)
	if target_data.is_empty():
		return {}
	var preview: Dictionary = {
		"hero": hero,
		"card": hand_card,
		"target_data": target_data,
		"valid": hand_card_phase_allows_play(hand_card),
		"world_position": Vector2(target_data.get("world_position", target_world_position)),
	}
	var target_room: Vector2i = target_data.get("room", INVALID_ROOM)
	if bool(preview.get("valid", false)) and target_room != INVALID_ROOM:
		var cast_room: Vector2i = best_card_cast_room(active_hero_room_for_commands(hero), target_room, hand_card, Vector2(preview.get("world_position", target_world_position)))
		preview["cast_room"] = cast_room
		preview["valid"] = cast_room != INVALID_ROOM
	return preview

func draw_active_hand_card_target_preview() -> void:
	var preview: Dictionary = active_hand_drag_target_preview()
	if preview.is_empty():
		return
	var target_data: Dictionary = Dictionary(preview.get("target_data", {}))
	if target_data.is_empty():
		return
	var card_preview: Dictionary = Dictionary(preview.get("card", {}))
	var preview_color: Color = card_preview.get("color", Color("9fe7ff"))
	var outline_color: Color = preview_color
	var fill_color: Color = preview_color
	if bool(preview.get("valid", false)):
		outline_color.a = 0.94
		fill_color.a = 0.12
	else:
		outline_color = Color("ff8f7f")
		fill_color = Color("ff8f7f")
		outline_color.a = 0.9
		fill_color.a = 0.08
	if target_data.has("room"):
		var target_room: Vector2i = target_data.get("room", INVALID_ROOM)
		if target_room != INVALID_ROOM and rooms.has(target_room):
			var room_highlight_rect: Rect2 = room_rect(target_room).grow(-8.0)
			draw_rect(room_highlight_rect, fill_color, true)
			draw_rect(room_highlight_rect, outline_color, false, 4.0)
			var target_position: Vector2 = Vector2(preview.get("world_position", room_center(target_room)))
			var indicator_radius: float = clampf(float(card_preview.get("impact_radius", card_preview.get("radius", 28.0))), 22.0, 86.0)
			var indicator_fill: Color = fill_color
			indicator_fill.a = 0.18 if bool(preview.get("valid", false)) else 0.12
			draw_circle(target_position, indicator_radius, indicator_fill)
			draw_arc(target_position, indicator_radius, 0.0, TAU, 40, outline_color, 3.0, true)
	if target_data.has("hero"):
		var target_hero: Variant = target_data.get("hero", null)
		if target_hero != null and is_instance_valid(target_hero):
			draw_circle(target_hero.global_position, 30.0, fill_color)
			draw_arc(target_hero.global_position, 30.0, 0.0, TAU, 36, outline_color, 4.0, true)

func build_item_defs() -> Dictionary:
	return {
		"axe": {
			"name": "Axe Rack",
			"short": "AXE",
			"size": Vector2i(2, 2),
			"color": Color("ffb36b"),
			"description_lines": ["Passive: hurls a bouncing axe in combat", "Synergies boost proc speed and damage"],
			"tags": ["weapon", "metal", "axe"],
			"stats": {"attack": 5.0},
			"synergy_sockets": [
				{"offset": Vector2i(-1, 0), "tag": "support", "bonuses": {"attack": 2.0, "card_charge_mult": 0.9}},
				{"offset": Vector2i(2, 1), "tag": "metal", "bonuses": {"card_damage": 5.0}},
			],
			"passive_combat_ability": {"card_id": "axe_card", "cooldown": 1.8},
		},
		"daggers": {
			"name": "Daggers",
			"short": "DAG",
			"size": Vector2i(1, 2),
			"color": Color("d8e4ff"),
			"description_lines": ["Passive: fires a 3-dagger fan in combat", "Back hits build combo and bonus damage"],
			"tags": ["weapon", "blade", "dagger"],
			"stats": {"attack": 3.0},
			"synergy_sockets": [
				{"offset": Vector2i(1, 0), "tag": "support", "bonuses": {"projectile_count": 1}},
				{"offset": Vector2i(1, 1), "tag": "metal", "bonuses": {"dagger_backstab_bonus": 0.25, "card_charge_mult": 0.92}},
			],
			"passive_combat_ability": {"card_id": "dagger_card", "cooldown": 1.35},
		},
		"blade": {
			"name": "Blade",
			"short": "BLD",
			"size": Vector2i(1, 2),
			"color": Color("ffb36b"),
			"description_lines": ["Simple weapon upgrade", "Purely boosts attack"],
			"tags": ["weapon", "metal"],
			"stats": {"attack": 6.0},
			"synergy_sockets": [
				{"offset": Vector2i(1, 0), "tag": "tool", "bonuses": {"attack": 2.0}},
			],
		},
		"boots": {
			"name": "Boots",
			"short": "BOT",
			"size": Vector2i(2, 1),
			"color": Color("8ed7c5"),
			"description_lines": ["Move faster and gain stamina", "Pairs well with support gear"],
			"tags": ["gear", "footwear"],
			"stats": {"speed": 36.0, "stamina": 1.0},
			"synergy_sockets": [
				{"offset": Vector2i(0, -1), "tag": "support", "bonuses": {"stamina": 1.0}},
			],
		},
		"ration": {
			"name": "Ration",
			"short": "RAT",
			"size": Vector2i(1, 2),
			"color": Color("c8e07b"),
			"description_lines": ["Packed meals for recovery", "Adds a self-support card over dungeon turns"],
			"tags": ["food", "support"],
			"stats": {"health": 12.0, "hand_size": 1},
			"hand_cards": [
				{"card_id": "ration_meal_card", "door_interval": 2, "generation_mode": "door_interval", "max_stored_cards": 1},
			],
			"synergy_sockets": [
				{"offset": Vector2i(0, -1), "tag": "support", "bonuses": {"hand_size": 1}},
			],
		},
		"buckler": {
			"name": "Buckler",
			"short": "BCK",
			"size": Vector2i(2, 2),
			"color": Color("9ec3ff"),
			"description_lines": ["Health and stamina buffer", "Weapon synergy lowers card stamina cost"],
			"tags": ["armor", "metal"],
			"stats": {"health": 18.0, "stamina": 1.0},
			"synergy_sockets": [
				{"offset": Vector2i(-1, 1), "tag": "weapon", "bonuses": {"stamina_cost_mult": 0.92}},
			],
		},
		"whetstone": {
			"name": "Whetstone",
			"short": "WHT",
			"size": Vector2i(1, 1),
			"color": Color("f2e4a4"),
			"description_lines": ["Star tool", "Stars buff neighboring weapons"],
			"tags": ["tool"],
			"synergy_sockets": [
				{"offset": Vector2i(-1, 0), "tag": "weapon", "bonuses": {"attack": 4.0}},
				{"offset": Vector2i(1, 0), "tag": "weapon", "bonuses": {"attack": 4.0}},
				{"offset": Vector2i(0, -1), "tag": "weapon", "bonuses": {"attack": 4.0}},
				{"offset": Vector2i(0, 1), "tag": "weapon", "bonuses": {"attack": 4.0}},
			],
		},
		"banner": {
			"name": "Banner",
			"short": "BNR",
			"size": Vector2i(1, 3),
			"color": Color("ea7e7e"),
			"description_lines": ["Star support standard", "Perimeter stars aid armor and weapons"],
			"tags": ["support"],
			"synergy_sockets": [
				{"offset": Vector2i(-1, 0), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(-1, 1), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(-1, 2), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(1, 0), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(1, 1), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(1, 2), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(0, -1), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
				{"offset": Vector2i(0, 3), "matches": [{"tag": "armor", "bonuses": {"health": 8.0}}, {"tag": "weapon", "bonuses": {"attack": 2.0}}]},
			],
		},
		"lantern": {
			"name": "Lantern",
			"short": "LNT",
			"size": Vector2i(1, 2),
			"color": Color("ffe38a"),
			"description_lines": ["Three-use utility light", "Readies one torch card per door, up to one held"],
			"tags": ["support", "light"],
			"stats": {"hand_size": 1},
			"max_charges": 3,
			"synergy_sockets": [
				{"offset": Vector2i(1, 0), "tag": "support", "bonuses": {"card_charge_mult": 0.85}},
			],
			"hand_card": {"card_id": "torch_card", "door_interval": 1, "generation_mode": "door_interval", "max_stored_cards": 1, "consume_item_charges_on_play": 1},
		},
		"medkit": {
			"name": "Medkit",
			"short": "MED",
			"size": Vector2i(2, 1),
			"color": Color("ff9b9b"),
			"description_lines": ["Adds a Mend card immediately", "Mend is a large combat heal"],
			"tags": ["support", "medical"],
			"stats": {"health": 8.0},
			"max_charges": 2,
			"synergy_sockets": [
				{"offset": Vector2i(0, 1), "tag": "food", "bonuses": {"health": 4.0}},
				{"offset": Vector2i(2, 0), "tag": "support", "bonuses": {"card_charge_mult": 0.9}},
			],
			"hand_card": {"card_id": "mend_card", "door_interval": 3, "generation_mode": "door_interval", "max_stored_cards": 1, "consume_item_charges_on_play": 1},
		},
		"torch": {
			"name": "Torch",
			"short": "TOR",
			"size": Vector2i(1, 2),
			"color": Color("ffbf73"),
			"description_lines": ["Single-use utility light", "Consumed when its torch card is played"],
			"tags": ["support", "light", "torch"],
			"hand_card": {"card_id": "torch_card", "generation_mode": "single", "consume_item_on_play": true},
		},
		"spellbook": {
			"name": "Spellbook",
			"short": "SPB",
			"size": Vector2i(1, 2),
			"color": Color("caa8ff"),
			"description_lines": ["Wizard focus", "Slots learned spells for one cast each floor"],
			"tags": ["arcane", "book", "support"],
			"stats": {"hand_size": 1},
		},
		"holy_symbol": {
			"name": "Holy Symbol",
			"short": "HLY",
			"size": Vector2i(1, 1),
			"color": Color("d8e8a8"),
			"description_lines": ["Cleric focus", "Prepares prayers for one cast each floor"],
			"tags": ["divine", "focus", "support"],
			"stats": {"hand_size": 1},
		},
		"scroll_fireball": {
			"name": "Scroll of Fireball",
			"short": "SFB",
			"size": Vector2i(1, 2),
			"color": Color("ff9a5e"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "fireball_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Fireball Scroll", "description_lines_override": ["Cast Fireball once", "Wizard can study it in calm mode"]},
		},
		"scroll_magic_missile": {
			"name": "Scroll of Magic Missile",
			"short": "SMM",
			"size": Vector2i(1, 2),
			"color": Color("9cd7ff"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "magic_missile_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Magic Missile Scroll", "description_lines_override": ["Launch seeking missiles once", "Wizard can study it in calm mode"]},
		},
		"scroll_misty_step": {
			"name": "Scroll of Misty Step",
			"short": "SMS",
			"size": Vector2i(1, 2),
			"color": Color("b89cff"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "misty_step_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Misty Step Scroll", "description_lines_override": ["Teleport once to a seen room", "Wizard can study it in calm mode"]},
		},
		"scroll_shield": {
			"name": "Scroll of Shield",
			"short": "SSH",
			"size": Vector2i(1, 2),
			"color": Color("9fc8ff"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "shield_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Shield Scroll", "description_lines_override": ["Gain a temporary arcane barrier", "Wizard can study it in calm mode"]},
		},
		"scroll_lightning_bolt": {
			"name": "Scroll of Lightning Bolt",
			"short": "SLB",
			"size": Vector2i(1, 2),
			"color": Color("8bd9ff"),
			"description_lines": ["Single-use spell scroll", "Cast once or study in calm as a wizard"],
			"tags": ["arcane", "scroll"],
			"hand_card": {"card_id": "lightning_bolt_card", "generation_mode": "single", "phase_override": "any", "learnable_spell_scroll": true, "consume_item_on_play": true, "max_stored_cards": 1, "name_override": "Lightning Bolt Scroll", "description_lines_override": ["Fire a piercing line through a doorway", "Wizard can study it in calm mode"]},
		},
	}

func hero_class_definition(class_id: String) -> Dictionary:
	match class_id:
		HERO_CLASS_CLERIC:
			return {
				"id": HERO_CLASS_CLERIC,
				"name": "Cleric",
				"title": "Melee Cleric",
				"move_speed": 325.0,
				"max_health": 118.0,
				"attack_damage": 18.0,
				"attack_range": 82.0,
				"attack_cooldown": 0.52,
				"attack_style": "melee",
				"weight": 2.0,
				"melee_windup": 0.21,
				"body_color": Color("9fe6b0"),
				"core_color": Color("f5fff1"),
			}
		HERO_CLASS_ROGUE:
			return {
				"id": HERO_CLASS_ROGUE,
				"name": "Rogue",
				"title": "Ranged Rogue",
				"move_speed": 388.0,
				"max_health": 92.0,
				"attack_damage": 15.0,
				"attack_range": 270.0,
				"attack_cooldown": 0.34,
				"attack_style": "laser",
				"weight": 1.35,
				"melee_windup": 0.16,
				"body_color": Color("c2d8ff"),
				"core_color": Color("f6fbff"),
			}
		HERO_CLASS_WIZARD:
			return {
				"id": HERO_CLASS_WIZARD,
				"name": "Wizard",
				"title": "Ranged Wizard",
				"move_speed": 306.0,
				"max_health": 86.0,
				"attack_damage": 24.0,
				"attack_range": 320.0,
				"attack_cooldown": 0.78,
				"attack_style": "laser",
				"weight": 1.2,
				"melee_windup": 0.18,
				"body_color": Color("c7a7ff"),
				"core_color": Color("fff6ff"),
			}
		_:
			return {
				"id": HERO_CLASS_FIGHTER,
				"name": "Fighter",
				"title": "Melee Fighter",
				"move_speed": 342.0,
				"max_health": 142.0,
				"attack_damage": 28.0,
				"attack_range": 76.0,
				"attack_cooldown": 0.58,
				"attack_style": "melee",
				"weight": 2.45,
				"melee_windup": 0.24,
				"body_color": Color("ff9a7a"),
				"core_color": Color("fff2dd"),
			}

func hero_portrait_texture(class_id: String) -> Texture2D:
	if hero_portrait_cache.has(class_id):
		return hero_portrait_cache[class_id]
	var portrait_path: String = Hero.portrait_path_for_class(class_id)
	var source_texture_resource: Resource = load(portrait_path)
	if not (source_texture_resource is Texture2D):
		return null
	var source_image: Image = source_texture_resource.get_image()
	var portrait: Image = source_image.get_region(Rect2i(0, 0, 100, 100))
	portrait.convert(Image.FORMAT_RGBA8)
	var texture: ImageTexture = ImageTexture.create_from_image(portrait)
	hero_portrait_cache[class_id] = texture
	return texture

func make_inventory_item(item_id: String, anchor: Vector2i = INVALID_ROOM, rotated: bool = false) -> Dictionary:
	var item: Dictionary = {
		"uid": next_item_uid,
		"item_id": item_id,
		"rotated": rotated,
	}
	if anchor != INVALID_ROOM:
		item["anchor"] = anchor
	next_item_uid += 1
	return normalize_item_instance(item)

func default_inventory_items_for_class(class_id: String) -> Array:
	var items: Array = []
	match class_id:
		HERO_CLASS_WIZARD:
			items.append(make_inventory_item("spellbook", INVENTORY_BASE_ORIGIN))
		HERO_CLASS_CLERIC:
			items.append(make_inventory_item("holy_symbol", INVENTORY_BASE_ORIGIN))
	return items

func default_learned_spells_for_class(class_id: String) -> Array[String]:
	return starting_known_spells_for_class(class_id)

func default_slotted_spells_for_class(class_id: String) -> Array[String]:
	var starter_spells: Array[String] = starting_known_spells_for_class(class_id)
	var slot_counts: Array[int] = spell_slot_counts_for_class_level(class_id, 1)
	var total_slots: int = 0
	for slot_count_variant in slot_counts:
		total_slots += int(slot_count_variant)
	var prepared: Array[String] = []
	for spell_variant in starter_spells:
		if prepared.size() >= total_slots:
			break
		prepared.append(String(spell_variant))
	return prepared

func implemented_spellbook_spells_for_class(class_id: String) -> Array[String]:
	match class_id:
		HERO_CLASS_WIZARD:
			return ["magic_missile_card", "shield_card", "misty_step_card", "fireball_card", "lightning_bolt_card"]
		HERO_CLASS_CLERIC:
			return ["cure_light_wounds_card", "sanctuary_card"]
		_:
			return []

func starting_known_spells_for_class(class_id: String) -> Array[String]:
	var learned: Array[String] = []
	for spell_id_variant in implemented_spellbook_spells_for_class(class_id):
		var spell_id: String = String(spell_id_variant)
		if spell_level(spell_id) != 1:
			continue
		learned.append(spell_id)
	return learned

func spell_display_name(spell_id: String) -> String:
	return String(card_definition(spell_id).get("name", spell_id.replace("_card", "").replace("_", " ").capitalize()))

func spell_display_names_joined(spell_ids: Array) -> String:
	var names: Array[String] = []
	for spell_variant in spell_ids:
		var spell_id: String = String(spell_variant)
		if spell_id == "":
			continue
		names.append(spell_display_name(spell_id))
	return ", ".join(PackedStringArray(names))

func spell_overlay_entry(spell_id: String) -> Dictionary:
	var card_def: Dictionary = card_definition(spell_id)
	return {
		"id": spell_id,
		"name": String(card_def.get("name", spell_id.replace("_card", "").replace("_", " ").capitalize())),
		"level": spell_level(spell_id),
		"description_lines": Array(card_def.get("description_lines", [])).duplicate(),
	}

func spell_overlay_entries(spell_ids: Array) -> Array:
	var entries: Array = []
	for spell_variant in spell_ids:
		var spell_id: String = String(spell_variant)
		if spell_id == "":
			continue
		entries.append(spell_overlay_entry(spell_id))
	return entries

func spell_focus_item_id_for_class(class_id: String) -> String:
	match class_id:
		HERO_CLASS_WIZARD:
			return "spellbook"
		HERO_CLASS_CLERIC:
			return "holy_symbol"
		_:
			return ""

func spell_panel_title_for_class(class_id: String) -> String:
	match class_id:
		HERO_CLASS_CLERIC:
			return "Prayer Book"
		_:
			return "Spellbook"

func full_caster_spell_slots_for_level(level_value: int) -> Array[int]:
	var table: Array = [
		[2, 0, 0, 0, 0, 0, 0, 0, 0],
		[3, 0, 0, 0, 0, 0, 0, 0, 0],
		[4, 2, 0, 0, 0, 0, 0, 0, 0],
		[4, 3, 0, 0, 0, 0, 0, 0, 0],
		[4, 3, 2, 0, 0, 0, 0, 0, 0],
		[4, 3, 3, 0, 0, 0, 0, 0, 0],
		[4, 3, 3, 1, 0, 0, 0, 0, 0],
		[4, 3, 3, 2, 0, 0, 0, 0, 0],
		[4, 3, 3, 3, 1, 0, 0, 0, 0],
		[4, 3, 3, 3, 2, 0, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 0, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 0, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 0],
		[4, 3, 3, 3, 2, 1, 1, 1, 0],
		[4, 3, 3, 3, 1, 1, 1, 1, 1],
		[4, 3, 3, 3, 1, 1, 1, 1, 1],
		[4, 3, 3, 3, 2, 1, 1, 1, 1],
		[4, 3, 3, 3, 2, 2, 1, 1, 1],
	]
	var index: int = clampi(level_value, 1, table.size()) - 1
	var row: Array = table[index]
	var slots: Array[int] = []
	for value in row:
		slots.append(int(value))
	return slots

func spell_level(spell_id: String) -> int:
	return maxi(0, int(card_definition(spell_id).get("spell_level", 0)))

func spell_class_id(spell_id: String) -> String:
	return String(card_definition(spell_id).get("spell_class", ""))

func spell_slot_counts_for_class_level(class_id: String, level_value: int) -> Array[int]:
	match class_id:
		HERO_CLASS_WIZARD:
			return full_caster_spell_slots_for_level(level_value)
		HERO_CLASS_CLERIC:
			return full_caster_spell_slots_for_level(level_value)
		_:
			return []

func hero_max_spell_level_for_class_level(class_id: String, level_value: int) -> int:
	var slot_counts: Array[int] = spell_slot_counts_for_class_level(class_id, level_value)
	for slot_index in range(slot_counts.size() - 1, -1, -1):
		if slot_counts[slot_index] > 0:
			return slot_index + 1
	return 0

func spell_slot_capacity_for_class_level(class_id: String, level_value: int) -> int:
	var total: int = 0
	for slot_count in spell_slot_counts_for_class_level(class_id, level_value):
		total += int(slot_count)
	return total

func default_hero_class_for_slot(hero_index: int) -> String:
	return String(HERO_CLASS_ORDER[hero_index % HERO_CLASS_ORDER.size()])

func hero_profile_class_id(hero_index: int) -> String:
	ensure_hero_profiles()
	var class_id: String = String(hero_profiles[hero_index].get("class_id", default_hero_class_for_slot(hero_index)))
	if HERO_CLASS_ORDER.has(class_id):
		return class_id
	return default_hero_class_for_slot(hero_index)

func hero_display_name(hero_index: int, class_id: String) -> String:
	var class_def: Dictionary = hero_class_definition(class_id)
	return "%s %d" % [String(class_def.get("name", "Hero")), hero_index + 1]

func set_hero_profile_class(hero_index: int, class_id: String, apply_to_spawned_hero: bool = true) -> void:
	ensure_hero_profiles()
	if hero_index < 0 or hero_index >= hero_profiles.size():
		return
	var resolved_class_id: String = class_id if HERO_CLASS_ORDER.has(class_id) else default_hero_class_for_slot(hero_index)
	hero_profiles[hero_index]["class_id"] = resolved_class_id
	hero_profiles[hero_index]["name"] = hero_display_name(hero_index, resolved_class_id)
	if not hero_class_selection_locked():
		hero_profiles[hero_index]["inventory_items"] = default_inventory_items_for_class(resolved_class_id)
		hero_profiles[hero_index]["learned_spells"] = default_learned_spells_for_class(resolved_class_id)
		hero_profiles[hero_index]["slotted_spells"] = default_slotted_spells_for_class(resolved_class_id)
	if apply_to_spawned_hero and hero_index < heroes.size():
		var hero: Variant = heroes[hero_index]
		if hero != null and is_instance_valid(hero):
			apply_hero_class_to_node(hero, resolved_class_id, hero_profiles[hero_index]["name"])
			if not hero_class_selection_locked():
				hero.inventory_items = Array(hero_profiles[hero_index].get("inventory_items", [])).duplicate(true)
				hero.learned_spells = Array(hero_profiles[hero_index].get("learned_spells", [])).duplicate()
				hero.slotted_spells = Array(hero_profiles[hero_index].get("slotted_spells", [])).duplicate()
				hero.active_floor_spells = hero.slotted_spells.duplicate()
				sanitize_hero_spellbook(hero)
			apply_inventory_stats_to_hero(hero)
			hero.restore_health()

func apply_hero_class_to_node(hero: Variant, class_id: String, display_name: String = "") -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var class_def: Dictionary = hero_class_definition(class_id)
	var resolved_name: String = display_name if display_name != "" else hero_display_name(hero.hero_index, class_id)
	hero.configure_archetype(
		String(class_def.get("id", HERO_CLASS_FIGHTER)),
		resolved_name,
		float(class_def.get("move_speed", 340.0)),
		float(class_def.get("max_health", 100.0)),
		float(class_def.get("attack_damage", 20.0)),
		float(class_def.get("attack_range", 150.0)),
		float(class_def.get("attack_cooldown", 0.55)),
		String(class_def.get("attack_style", "laser")),
		float(class_def.get("weight", 1.6)),
		float(class_def.get("melee_windup", 0.2)),
		class_def.get("body_color", Color("7ad7ff")),
		class_def.get("core_color", Color("f7f4d5"))
	)

func hero_class_summary_lines(class_id: String) -> Array[String]:
	var class_def: Dictionary = hero_class_definition(class_id)
	return [
		String(class_def.get("title", "Hero")),
		"%s  %d atk  %d hp  %d spd" % ["Melee" if String(class_def.get("attack_style", "laser")) == "melee" else "Ranged", int(round(float(class_def.get("attack_damage", 0.0)))), int(round(float(class_def.get("max_health", 0.0)))), int(round(float(class_def.get("move_speed", 0.0))))],
		"Range %d  Cooldown %.2fs  Weight %.1f" % [int(round(float(class_def.get("attack_range", 0.0)))), float(class_def.get("attack_cooldown", 0.0)), float(class_def.get("weight", 1.0))],
	]

func hero_class_selection_locked() -> bool:
	return doors_opened > 0 or opened_rooms > 1

func can_local_edit_hero_class(hero_index: int) -> bool:
	return can_local_control_hero_index(hero_index) and not hero_class_selection_locked()

func setup_multiplayer_callbacks() -> void:
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_multiplayer_connected_to_server)
	multiplayer.connection_failed.connect(_on_multiplayer_connection_failed)
	multiplayer.server_disconnected.connect(_on_multiplayer_server_disconnected)

func multiplayer_session_active() -> bool:
	return multiplayer.multiplayer_peer != null

func authoritative_simulation_active() -> bool:
	return not multiplayer_session_active() or multiplayer.is_server()

func local_peer_id() -> int:
	if multiplayer_session_active():
		return multiplayer.get_unique_id()
	return NETWORK_HOST_PEER_ID

func reset_hero_owner_peer_ids() -> void:
	hero_owner_peer_ids.clear()
	for _hero_index in range(HERO_COUNT):
		hero_owner_peer_ids.append(NETWORK_HOST_PEER_ID)
	ensure_valid_selected_hero()
	sync_lobby_peer_ready_states(not lobby_game_started)

func hero_owner_peer_id(hero_index: int) -> int:
	if hero_index < 0 or hero_index >= hero_owner_peer_ids.size():
		return NETWORK_HOST_PEER_ID
	return int(hero_owner_peer_ids[hero_index])

func can_local_control_hero_index(hero_index: int) -> bool:
	if hero_index < 0 or hero_index >= HERO_COUNT:
		return false
	if not multiplayer_session_active():
		return true
	return hero_owner_peer_id(hero_index) == local_peer_id()

func first_controlled_hero_index_for_peer(peer_id: int) -> int:
	for hero_index in range(hero_owner_peer_ids.size()):
		if int(hero_owner_peer_ids[hero_index]) == peer_id:
			return hero_index
	return -1

func controlled_hero_indices_for_peer(peer_id: int) -> Array[int]:
	var controlled_indices: Array[int] = []
	for hero_index in range(hero_owner_peer_ids.size()):
		if int(hero_owner_peer_ids[hero_index]) == peer_id:
			controlled_indices.append(hero_index)
	return controlled_indices

func first_local_controlled_hero_index() -> int:
	for hero_index in controlled_hero_indices_for_peer(local_peer_id()):
		var hero: Variant = heroes[hero_index] if hero_index >= 0 and hero_index < heroes.size() else null
		if hero_is_active(hero):
			return hero_index
	return -1

func ensure_valid_selected_hero() -> void:
	if can_local_control_hero_index(selected_hero_index) and hero_is_active(selected_hero()):
		return
	var fallback_index: int = first_local_controlled_hero_index()
	if fallback_index >= 0:
		selected_hero_index = fallback_index
	else:
		selected_hero_index = clampi(selected_hero_index, 0, max(HERO_COUNT - 1, 0))

func room_actions_allowed_for_local_peer() -> bool:
	return selected_hero() != null and can_local_control_hero_index(selected_hero_index)

func inventory_actions_allowed_for_local_peer() -> bool:
	return selected_hero() != null and can_local_control_hero_index(selected_hero_index)

func multiplayer_status_text() -> String:
	if not multiplayer_session_active():
		return "Offline"
	var local_heroes: Array[int] = controlled_hero_indices_for_peer(local_peer_id())
	var local_hero_text: String = ""
	if not local_heroes.is_empty():
		var labels: Array[String] = []
		for hero_index in local_heroes:
			labels.append("H%d" % (hero_index + 1))
		local_hero_text = " %s" % ",".join(labels)
	if multiplayer.is_server():
		return "Host %d/%d%s" % [1 + multiplayer.get_peers().size(), HERO_COUNT, local_hero_text]
	if not local_heroes.is_empty():
		return "Client%s" % local_hero_text
	return "Client"

func connected_session_peer_ids() -> Array[int]:
	var peer_ids: Array[int] = []
	var candidate_ids: Array[int] = [NETWORK_HOST_PEER_ID]
	if multiplayer_session_active():
		var local_id: int = multiplayer.get_unique_id()
		if local_id > 0:
			candidate_ids.append(local_id)
		for peer_id_variant in multiplayer.get_peers():
			candidate_ids.append(int(peer_id_variant))
	for peer_id in candidate_ids:
		if not peer_ids.has(peer_id):
			peer_ids.append(peer_id)
	peer_ids.sort()
	return peer_ids

func sync_lobby_peer_ready_states(reset_ready: bool = false) -> void:
	var next_ready: Dictionary = {}
	for peer_id in connected_session_peer_ids():
		next_ready[peer_id] = false if reset_ready else bool(lobby_peer_ready.get(peer_id, false))
	lobby_peer_ready = next_ready

func local_peer_ready_state() -> bool:
	return bool(lobby_peer_ready.get(local_peer_id(), false))

func all_lobby_players_ready() -> bool:
	var peer_ids: Array[int] = connected_session_peer_ids()
	if peer_ids.is_empty():
		return false
	for peer_id in peer_ids:
		if not bool(lobby_peer_ready.get(peer_id, false)):
			return false
	return true

func player_display_name(peer_id: int) -> String:
	if not multiplayer_session_active():
		return "Player"
	var label: String = "Host" if peer_id == NETWORK_HOST_PEER_ID else "Player %d" % peer_id
	if peer_id == local_peer_id():
		label += " (You)"
	return label

func lobby_hero_label(hero_index: int) -> String:
	var class_id: String = hero_profile_class_id(hero_index)
	var class_label: String = String(hero_class_definition(class_id).get("name", class_id.capitalize()))
	if hero_index < heroes.size():
		var hero: Variant = heroes[hero_index]
		if hero != null and is_instance_valid(hero):
			class_label = String(hero_class_definition(hero.hero_class_id).get("name", hero.hero_class_id.capitalize()))
	return "H%d %s%s" % [hero_index + 1, class_label, " [Dead]" if bool(hero_profiles[hero_index].get("dead", false)) else ""]

func rebuild_hero_select_player_list() -> void:
	if hero_select_player_list == null:
		return
	for child in hero_select_player_list.get_children():
		child.queue_free()
	for peer_id in connected_session_peer_ids():
		var row_panel: PanelContainer = PanelContainer.new()
		hero_select_player_list.add_child(row_panel)
		var row_vbox: VBoxContainer = VBoxContainer.new()
		row_vbox.add_theme_constant_override("separation", 6)
		row_panel.add_child(row_vbox)
		var title_label: Label = Label.new()
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.text = player_display_name(peer_id)
		row_vbox.add_child(title_label)
		var hero_lines: Array[String] = []
		for hero_index in controlled_hero_indices_for_peer(peer_id):
			hero_lines.append(lobby_hero_label(hero_index))
		var heroes_label: Label = Label.new()
		heroes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heroes_label.add_theme_font_size_override("font_size", 14)
		heroes_label.text = "Heroes: %s" % (", ".join(hero_lines) if not hero_lines.is_empty() else "None")
		row_vbox.add_child(heroes_label)
		var ready: bool = bool(lobby_peer_ready.get(peer_id, false))
		var status_label: Label = Label.new()
		status_label.add_theme_font_size_override("font_size", 14)
		status_label.add_theme_color_override("font_color", Color("8df4b2") if ready else Color("d6e4ee"))
		status_label.text = "Ready" if ready else "Not Ready"
		row_vbox.add_child(status_label)
		if peer_id == local_peer_id() and not lobby_game_started:
			var ready_button: Button = Button.new()
			ready_button.custom_minimum_size = Vector2(0.0, 36.0)
			ready_button.add_theme_font_size_override("font_size", 14)
			ready_button.text = "Unready" if ready else "Ready"
			ready_button.pressed.connect(_on_hero_select_ready_button_pressed)
			row_vbox.add_child(ready_button)

func update_network_ui() -> void:
	if network_status_label == null:
		return
	network_status_label.text = multiplayer_status_text()
	var active: bool = multiplayer_session_active()
	if network_address_input != null:
		network_address_input.editable = not active
	if network_host_button != null:
		network_host_button.disabled = active
	if network_join_button != null:
		network_join_button.disabled = active
	if network_disconnect_button != null:
		network_disconnect_button.disabled = not active
	if hero_select_toggle_button != null:
		hero_select_toggle_button.text = "Close" if hero_select_overlay != null and hero_select_overlay.visible else "Lobby"
		hero_select_toggle_button.visible = lobby_game_started or (hero_select_overlay != null and hero_select_overlay.visible)
	update_hero_select_overlay()

func set_hero_select_overlay_visible(visible: bool) -> void:
	if hero_select_overlay == null:
		return
	if visible:
		clear_room_action_hold()
		close_room_action_menu()
		cancel_room_action_camera_focus()
		if inventory_overlay != null and inventory_overlay.visible:
			clear_inventory_session(true)
		build_menu_open = false
		clear_build_mode()
	hero_select_overlay.visible = visible
	if hero_select_toggle_button != null:
		hero_select_toggle_button.text = "Close" if visible else "Lobby"
	update_hero_select_overlay()
	update_hud()

func update_hero_select_overlay() -> void:
	if hero_select_overlay == null:
		return
	ensure_hero_profiles()
	hero_select_active_index = clampi(hero_select_active_index, 0, HERO_COUNT - 1)
	var selection_locked: bool = hero_class_selection_locked()
	if hero_select_title_label != null:
		hero_select_title_label.text = "Lobby"
	if hero_select_start_button != null:
		if not lobby_game_started:
			if multiplayer_session_active() and not multiplayer.is_server():
				hero_select_start_button.text = "Waiting for Host"
				hero_select_start_button.disabled = true
			else:
				hero_select_start_button.text = "Start Game"
				hero_select_start_button.disabled = not all_lobby_players_ready()
		else:
			hero_select_start_button.text = "Close Lobby"
			hero_select_start_button.disabled = false
	for hero_index in range(HERO_COUNT):
		if not hero_select_cards.has(hero_index):
			continue
		var card: Dictionary = hero_select_cards[hero_index]
		var class_id: String = hero_profile_class_id(hero_index)
		var display_name: String = String(hero_profiles[hero_index].get("name", hero_display_name(hero_index, class_id)))
		var hero: Variant = heroes[hero_index] if hero_index < heroes.size() else null
		if hero != null and is_instance_valid(hero):
			class_id = hero.hero_class_id
			display_name = hero.hero_name
			hero_profiles[hero_index]["class_id"] = class_id
			hero_profiles[hero_index]["name"] = display_name
		var tile_button: Button = card.get("button", null)
		if tile_button != null:
			var tile_owner: String = "You" if not multiplayer_session_active() or can_local_control_hero_index(hero_index) else "Peer %d" % hero_owner_peer_id(hero_index)
			var dead_label: String = "\nDEAD" if bool(hero_profiles[hero_index].get("dead", false)) else ""
			tile_button.icon = hero_portrait_texture(class_id)
			tile_button.text = "H%d\n%s\n%s%s" % [hero_index + 1, String(hero_class_definition(class_id).get("name", class_id.capitalize())), tile_owner, dead_label]
			tile_button.button_pressed = hero_index == hero_select_active_index
	var active_class_id: String = hero_profile_class_id(hero_select_active_index)
	var active_display_name: String = String(hero_profiles[hero_select_active_index].get("name", hero_display_name(hero_select_active_index, active_class_id)))
	var active_hero: Variant = heroes[hero_select_active_index] if hero_select_active_index < heroes.size() else null
	if active_hero != null and is_instance_valid(active_hero):
		active_class_id = active_hero.hero_class_id
		active_display_name = active_hero.hero_name
	if hero_select_detail_portrait != null:
		hero_select_detail_portrait.texture = hero_portrait_texture(active_class_id)
	var active_locally_owned: bool = can_local_control_hero_index(hero_select_active_index)
	var owner_text: String = "You" if not multiplayer_session_active() or active_locally_owned else "Peer %d" % hero_owner_peer_id(hero_select_active_index)
	if hero_select_detail_title_label != null:
		hero_select_detail_title_label.text = "H%d  %s%s" % [hero_select_active_index + 1, active_display_name, "  [Dead]" if bool(hero_profiles[hero_select_active_index].get("dead", false)) else ""]
	if hero_select_detail_summary_label != null:
		var detail_lines: Array[String] = hero_class_summary_lines(active_class_id)
		detail_lines.append("Owner: %s" % owner_text)
		detail_lines.append("Selected for slot H%d." % [hero_select_active_index + 1])
		hero_select_detail_summary_label.text = "\n".join(detail_lines)
	if hero_select_detail_hint_label != null:
		if selection_locked:
			hero_select_detail_hint_label.text = "Class choice is locked after the first opened door."
		elif active_locally_owned:
			hero_select_detail_hint_label.text = "Tap a class below to set this hero before the run starts."
		else:
			hero_select_detail_hint_label.text = "You can inspect this hero here, but only its owner can change the class."
	for class_id_variant in HERO_CLASS_ORDER:
		var option_class_id: String = String(class_id_variant)
		var class_button: Button = hero_select_detail_class_buttons.get(option_class_id, null)
		if class_button == null:
			continue
		class_button.button_pressed = option_class_id == active_class_id
		class_button.disabled = selection_locked or not active_locally_owned or local_peer_ready_state()
	rebuild_hero_select_player_list()

func _on_hero_select_toggle_button_pressed() -> void:
	set_hero_select_overlay_visible(hero_select_overlay == null or not hero_select_overlay.visible)

func _on_hero_select_card_pressed(hero_index: int) -> void:
	hero_select_active_index = clampi(hero_index, 0, HERO_COUNT - 1)
	update_hero_select_overlay()

func _on_hero_select_detail_class_pressed(class_id: String) -> void:
	_on_hero_select_class_pressed(hero_select_active_index, class_id)

func _on_hero_select_ready_button_pressed() -> void:
	if lobby_game_started:
		return
	var next_ready: bool = not local_peer_ready_state()
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_lobby_ready.rpc_id(NETWORK_HOST_PEER_ID, next_ready)
		return
	lobby_peer_ready[local_peer_id()] = next_ready
	update_hud()
	if multiplayer_session_active() and multiplayer.is_server():
		broadcast_network_snapshot()

func _on_hero_select_class_pressed(hero_index: int, class_id: String) -> void:
	if hero_index < 0 or hero_index >= HERO_COUNT:
		return
	hero_select_active_index = hero_index
	if not can_local_edit_hero_class(hero_index):
		update_hero_select_overlay()
		return
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_hero_class.rpc_id(NETWORK_HOST_PEER_ID, hero_index, class_id)
		return
	lobby_peer_ready[local_peer_id()] = false
	set_hero_profile_class(hero_index, class_id, true)
	update_hero_select_overlay()
	update_hud()
	if multiplayer_session_active() and multiplayer.is_server():
		broadcast_network_snapshot()

func _on_hero_select_start_button_pressed() -> void:
	if not lobby_game_started:
		if multiplayer_session_active() and not multiplayer.is_server():
			return
		if not all_lobby_players_ready():
			status_message = "Everyone must be ready before the run can start."
			update_hud()
			return
		lobby_game_started = true
		status_message = "The run begins."
		set_hero_select_overlay_visible(false)
		if multiplayer_session_active() and multiplayer.is_server():
			broadcast_network_snapshot()
		return
	set_hero_select_overlay_visible(false)

func redistribute_multiplayer_hero_owners() -> void:
	reset_hero_owner_peer_ids()
	if not multiplayer_session_active():
		return
	var peer_ids: Array[int] = connected_session_peer_ids()
	if peer_ids.is_empty():
		return
	var participant_count: int = peer_ids.size()
	var base_hero_count: int = HERO_COUNT / participant_count
	var extra_hero_count: int = HERO_COUNT % participant_count
	var hero_cursor: int = 0
	for participant_index in range(peer_ids.size()):
		var owned_count: int = base_hero_count
		if participant_index < extra_hero_count:
			owned_count += 1
		for _owned_slot in range(owned_count):
			if hero_cursor >= HERO_COUNT:
				break
			hero_owner_peer_ids[hero_cursor] = peer_ids[participant_index]
			hero_cursor += 1
	ensure_valid_selected_hero()

func start_host_session() -> void:
	if multiplayer_session_active():
		return
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var create_error: int = peer.create_server(NETWORK_PORT, NETWORK_MAX_CLIENTS)
	if create_error != OK:
		status_message = "Host failed on port %d." % NETWORK_PORT
		update_hud()
		return
	multiplayer.multiplayer_peer = peer
	redistribute_multiplayer_hero_owners()
	if not lobby_game_started:
		sync_lobby_peer_ready_states(true)
	network_snapshot_timer = 0.0
	status_message = "Hosting co-op on port %d." % NETWORK_PORT
	ensure_valid_selected_hero()
	update_hud()
	update_network_ui()
	broadcast_network_snapshot()

func join_host_session(address_text: String) -> void:
	if multiplayer_session_active():
		return
	var target_address: String = address_text.strip_edges()
	if target_address == "":
		target_address = NETWORK_DEFAULT_ADDRESS
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var create_error: int = peer.create_client(target_address, NETWORK_PORT)
	if create_error != OK:
		status_message = "Join failed for %s:%d." % [target_address, NETWORK_PORT]
		update_hud()
		return
	multiplayer.multiplayer_peer = peer
	reset_hero_owner_peer_ids()
	if not lobby_game_started:
		sync_lobby_peer_ready_states(true)
	network_snapshot_timer = 0.0
	status_message = "Joining %s:%d..." % [target_address, NETWORK_PORT]
	update_hud()
	update_network_ui()

func stop_network_session(reason: String = "Returned to offline mode.") -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	reset_hero_owner_peer_ids()
	sync_lobby_peer_ready_states(not lobby_game_started)
	network_snapshot_timer = 0.0
	status_message = reason
	ensure_valid_selected_hero()
	update_hud()
	update_network_ui()

func _on_multiplayer_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	redistribute_multiplayer_hero_owners()
	if not lobby_game_started:
		sync_lobby_peer_ready_states(true)
	var assigned_heroes: Array[int] = controlled_hero_indices_for_peer(peer_id)
	var assigned_labels: Array[String] = []
	for hero_index in assigned_heroes:
		assigned_labels.append("H%d" % (hero_index + 1))
	status_message = "Peer %d joined and took %s." % [peer_id, ",".join(assigned_labels)]
	ensure_valid_selected_hero()
	update_hud()
	update_network_ui()
	broadcast_network_snapshot()

func _on_multiplayer_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		redistribute_multiplayer_hero_owners()
		sync_lobby_peer_ready_states(not lobby_game_started)
		status_message = "Peer %d disconnected." % peer_id
		ensure_valid_selected_hero()
		update_hud()
		update_network_ui()
		broadcast_network_snapshot()

func _on_multiplayer_connected_to_server() -> void:
	status_message = "Connected to host. Waiting for room state."
	update_hud()
	update_network_ui()

func _on_multiplayer_connection_failed() -> void:
	stop_network_session("Connection failed.")

func _on_multiplayer_server_disconnected() -> void:
	stop_network_session("Host disconnected.")

func _on_network_host_button_pressed() -> void:
	start_host_session()

func _on_network_join_button_pressed() -> void:
	join_host_session(network_address_input.text if network_address_input != null else NETWORK_DEFAULT_ADDRESS)

func _on_network_disconnect_button_pressed() -> void:
	stop_network_session()

func ensure_runtime_ui() -> void:
	apply_hud_styling()
	if hero_select_toggle_button == null:
		hero_select_toggle_button = Button.new()
		hero_select_toggle_button.custom_minimum_size = Vector2(78.0, 36.0)
		hero_select_toggle_button.text = "Lobby"
		hero_select_toggle_button.add_theme_font_size_override("font_size", 16)
		hero_select_toggle_button.pressed.connect(_on_hero_select_toggle_button_pressed)
		top_bar_panel.get_node("HBox").add_child(hero_select_toggle_button)
		top_bar_panel.get_node("HBox").move_child(hero_select_toggle_button, max(top_bar_panel.get_node("HBox").get_child_count() - 2, 0))
	if calm_speed_bar == null:
		calm_speed_bar = HBoxContainer.new()
		calm_speed_bar.add_theme_constant_override("separation", 4)
		var speed_label: Label = Label.new()
		speed_label.text = "Speed"
		speed_label.add_theme_font_size_override("font_size", 15)
		speed_label.add_theme_color_override("font_color", Color("d6e4ee"))
		calm_speed_bar.add_child(speed_label)
		for option_index in range(CALM_SPEED_OPTIONS.size()):
			var multiplier: int = int(CALM_SPEED_OPTIONS[option_index])
			var speed_button: Button = Button.new()
			speed_button.custom_minimum_size = Vector2(44.0, 34.0)
			speed_button.add_theme_font_size_override("font_size", 15)
			speed_button.toggle_mode = true
			speed_button.text = "%dx" % multiplier
			speed_button.pressed.connect(_on_calm_speed_button_pressed.bind(option_index))
			calm_speed_bar.add_child(speed_button)
			calm_speed_buttons.append(speed_button)
		top_bar_panel.get_node("HBox").add_child(calm_speed_bar)
		top_bar_panel.get_node("HBox").move_child(calm_speed_bar, 0)
	if hero_bar == null:
		hero_bar = HBoxContainer.new()
		hero_bar.add_theme_constant_override("separation", 6)
		top_bar_panel.get_node("HBox").add_child(hero_bar)
		top_bar_panel.get_node("HBox").move_child(hero_bar, top_bar_panel.get_node("HBox").get_child_count() - 1)
	if crystal_action_button == null:
		crystal_action_button = Button.new()
		crystal_action_button.visible = false
		crystal_action_button.custom_minimum_size = Vector2(132.0, 56.0)
		crystal_action_button.add_theme_font_size_override("font_size", 20)
		crystal_action_button.text = "Carry"
		crystal_action_button.pressed.connect(_on_crystal_action_button_pressed)
		$UI.add_child(crystal_action_button)
	if exit_button == null:
		exit_button = Button.new()
		exit_button.visible = false
		exit_button.anchor_left = 0.5
		exit_button.anchor_top = 1.0
		exit_button.anchor_right = 0.5
		exit_button.anchor_bottom = 1.0
		exit_button.offset_left = -170.0
		exit_button.offset_top = -246.0
		exit_button.offset_right = 170.0
		exit_button.offset_bottom = -178.0
		exit_button.add_theme_font_size_override("font_size", 26)
		exit_button.text = "Escape Floor"
		exit_button.pressed.connect(_on_exit_button_pressed)
		$UI.add_child(exit_button)
	if restart_button_hold_fill == null and restart_button != null and is_instance_valid(restart_button):
		restart_button_hold_fill = Panel.new()
		restart_button_hold_fill.name = "HoldFill"
		restart_button_hold_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		restart_button_hold_fill.show_behind_parent = true
		restart_button_hold_fill.anchor_left = 0.0
		restart_button_hold_fill.anchor_top = 0.0
		restart_button_hold_fill.anchor_right = 0.0
		restart_button_hold_fill.anchor_bottom = 1.0
		restart_button_hold_fill.offset_left = 0.0
		restart_button_hold_fill.offset_top = 0.0
		restart_button_hold_fill.offset_right = 0.0
		restart_button_hold_fill.offset_bottom = 0.0
		var restart_fill_style: StyleBoxFlat = StyleBoxFlat.new()
		restart_fill_style.bg_color = Color("d26448")
		restart_fill_style.corner_radius_top_left = 10
		restart_fill_style.corner_radius_bottom_left = 10
		restart_fill_style.corner_radius_top_right = 10
		restart_fill_style.corner_radius_bottom_right = 10
		restart_button_hold_fill.add_theme_stylebox_override("panel", restart_fill_style)
		restart_button.add_child(restart_button_hold_fill)
		restart_button.move_child(restart_button_hold_fill, 0)
	if inventory_overlay == null:
		inventory_overlay = INVENTORY_OVERLAY_SCENE.instantiate()
		inventory_overlay.visible = false
		$UI.add_child(inventory_overlay)
		inventory_overlay.close_requested.connect(_on_inventory_close_requested)
		inventory_overlay.inventory_changed.connect(_on_inventory_overlay_changed)
		inventory_overlay.pack_layout_changed.connect(_on_inventory_pack_layout_changed)
		inventory_overlay.level_up_requested.connect(_on_inventory_level_up_requested)
		inventory_overlay.item_dropped.connect(_on_inventory_item_dropped)
		inventory_overlay.spellbook_slots_changed.connect(_on_inventory_spellbook_slots_changed)
	if hero_select_overlay == null:
		hero_select_overlay = ColorRect.new()
		hero_select_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hero_select_overlay.color = Color(0.03, 0.06, 0.08, 0.82)
		hero_select_overlay.visible = false
		hero_select_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		$UI.add_child(hero_select_overlay)
		hero_select_panel = PanelContainer.new()
		hero_select_panel.anchor_left = 0.04
		hero_select_panel.anchor_top = 0.05
		hero_select_panel.anchor_right = 0.96
		hero_select_panel.anchor_bottom = 0.95
		hero_select_panel.offset_left = 0.0
		hero_select_panel.offset_top = 0.0
		hero_select_panel.offset_right = 0.0
		hero_select_panel.offset_bottom = 0.0
		hero_select_overlay.add_child(hero_select_panel)
		var root_vbox: VBoxContainer = VBoxContainer.new()
		root_vbox.add_theme_constant_override("separation", 10)
		hero_select_panel.add_child(root_vbox)
		hero_select_title_label = Label.new()
		hero_select_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_select_title_label.add_theme_font_size_override("font_size", 24)
		hero_select_title_label.text = "Lobby"
		root_vbox.add_child(hero_select_title_label)
		var subtitle_label: Label = Label.new()
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle_label.add_theme_font_size_override("font_size", 13)
		subtitle_label.text = "Host or join a run, then choose the heroes your local player controls."
		root_vbox.add_child(subtitle_label)
		network_panel = PanelContainer.new()
		root_vbox.add_child(network_panel)
		network_bar = HBoxContainer.new()
		network_bar.add_theme_constant_override("separation", 6)
		network_panel.add_child(network_bar)
		network_address_input = LineEdit.new()
		network_address_input.custom_minimum_size = Vector2(140.0, 34.0)
		network_address_input.placeholder_text = "Host IP"
		network_address_input.text = NETWORK_DEFAULT_ADDRESS
		network_address_input.add_theme_font_size_override("font_size", 14)
		network_bar.add_child(network_address_input)
		network_host_button = Button.new()
		network_host_button.custom_minimum_size = Vector2(58.0, 34.0)
		network_host_button.text = "Host"
		network_host_button.add_theme_font_size_override("font_size", 14)
		network_host_button.pressed.connect(_on_network_host_button_pressed)
		network_bar.add_child(network_host_button)
		network_join_button = Button.new()
		network_join_button.custom_minimum_size = Vector2(58.0, 34.0)
		network_join_button.text = "Join"
		network_join_button.add_theme_font_size_override("font_size", 14)
		network_join_button.pressed.connect(_on_network_join_button_pressed)
		network_bar.add_child(network_join_button)
		network_disconnect_button = Button.new()
		network_disconnect_button.custom_minimum_size = Vector2(62.0, 34.0)
		network_disconnect_button.text = "Leave"
		network_disconnect_button.add_theme_font_size_override("font_size", 14)
		network_disconnect_button.pressed.connect(_on_network_disconnect_button_pressed)
		network_bar.add_child(network_disconnect_button)
		network_status_label = Label.new()
		network_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		network_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		network_status_label.add_theme_font_size_override("font_size", 14)
		network_status_label.add_theme_color_override("font_color", Color("d6e4ee"))
		network_bar.add_child(network_status_label)
		var content_row: HBoxContainer = HBoxContainer.new()
		content_row.add_theme_constant_override("separation", 12)
		content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root_vbox.add_child(content_row)
		var hero_tile_panel: PanelContainer = PanelContainer.new()
		hero_tile_panel.custom_minimum_size = Vector2(240.0, 0.0)
		content_row.add_child(hero_tile_panel)
		var card_grid: GridContainer = GridContainer.new()
		card_grid.columns = 2
		card_grid.add_theme_constant_override("h_separation", 8)
		card_grid.add_theme_constant_override("v_separation", 8)
		hero_tile_panel.add_child(card_grid)
		var detail_panel: PanelContainer = PanelContainer.new()
		detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_row.add_child(detail_panel)
		var detail_vbox: VBoxContainer = VBoxContainer.new()
		detail_vbox.add_theme_constant_override("separation", 10)
		detail_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		detail_panel.add_child(detail_vbox)
		hero_select_detail_portrait = TextureRect.new()
		hero_select_detail_portrait.custom_minimum_size = Vector2(96.0, 96.0)
		hero_select_detail_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero_select_detail_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		detail_vbox.add_child(hero_select_detail_portrait)
		hero_select_detail_title_label = Label.new()
		hero_select_detail_title_label.add_theme_font_size_override("font_size", 24)
		detail_vbox.add_child(hero_select_detail_title_label)
		hero_select_detail_summary_label = Label.new()
		hero_select_detail_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hero_select_detail_summary_label.add_theme_font_size_override("font_size", 15)
		hero_select_detail_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		detail_vbox.add_child(hero_select_detail_summary_label)
		hero_select_detail_hint_label = Label.new()
		hero_select_detail_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hero_select_detail_hint_label.add_theme_font_size_override("font_size", 14)
		hero_select_detail_hint_label.add_theme_color_override("font_color", Color("d6e4ee"))
		detail_vbox.add_child(hero_select_detail_hint_label)
		var class_grid: GridContainer = GridContainer.new()
		class_grid.columns = 2
		class_grid.add_theme_constant_override("h_separation", 8)
		class_grid.add_theme_constant_override("v_separation", 8)
		detail_vbox.add_child(class_grid)
		var player_panel: PanelContainer = PanelContainer.new()
		player_panel.custom_minimum_size = Vector2(214.0, 0.0)
		content_row.add_child(player_panel)
		var player_vbox: VBoxContainer = VBoxContainer.new()
		player_vbox.add_theme_constant_override("separation", 8)
		player_panel.add_child(player_vbox)
		var player_title: Label = Label.new()
		player_title.add_theme_font_size_override("font_size", 18)
		player_title.text = "Players"
		player_vbox.add_child(player_title)
		hero_select_player_list = VBoxContainer.new()
		hero_select_player_list.add_theme_constant_override("separation", 8)
		hero_select_player_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		player_vbox.add_child(hero_select_player_list)
		for hero_index in range(HERO_COUNT):
			var card_button: Button = Button.new()
			card_button.toggle_mode = true
			card_button.custom_minimum_size = Vector2(0.0, 94.0)
			card_button.add_theme_font_size_override("font_size", 15)
			card_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			card_button.pressed.connect(_on_hero_select_card_pressed.bind(hero_index))
			card_grid.add_child(card_button)
			hero_select_cards[hero_index] = {
				"button": card_button,
			}
		for class_id_variant in HERO_CLASS_ORDER:
			var class_id: String = String(class_id_variant)
			var class_def: Dictionary = hero_class_definition(class_id)
			var class_button: Button = Button.new()
			class_button.toggle_mode = true
			class_button.custom_minimum_size = Vector2(0.0, 38.0)
			class_button.text = String(class_def.get("name", class_id.capitalize()))
			class_button.add_theme_font_size_override("font_size", 15)
			class_button.pressed.connect(_on_hero_select_detail_class_pressed.bind(class_id))
			class_grid.add_child(class_button)
			hero_select_detail_class_buttons[class_id] = class_button
		var footer_bar: HBoxContainer = HBoxContainer.new()
		footer_bar.alignment = BoxContainer.ALIGNMENT_END
		footer_bar.add_theme_constant_override("separation", 10)
		root_vbox.add_child(footer_bar)
		hero_select_start_button = Button.new()
		hero_select_start_button.custom_minimum_size = Vector2(168.0, 44.0)
		hero_select_start_button.add_theme_font_size_override("font_size", 18)
		hero_select_start_button.text = "Close Lobby"
		hero_select_start_button.pressed.connect(_on_hero_select_start_button_pressed)
		footer_bar.add_child(hero_select_start_button)
	update_hero_select_overlay()
	update_network_ui()

func apply_hud_styling() -> void:
	var bottom_style: StyleBoxEmpty = StyleBoxEmpty.new()
	bottom_bar_panel.add_theme_stylebox_override("panel", bottom_style)
	room_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0, 0.95))
	hint_label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.95, 0.88))
	dust_label.add_theme_color_override("font_color", Color("f3d88f"))
	food_label.add_theme_color_override("font_color", Color("9ee28b"))
	industry_label.add_theme_color_override("font_color", Color("f1c26b"))
	science_label.add_theme_color_override("font_color", Color("8bc1ff"))
	crystal_label.add_theme_color_override("font_color", Color("f6e3a4"))
	wave_label.add_theme_color_override("font_color", Color("d6e4ee"))

func rebuild_hero_bar() -> void:
	if hero_bar == null:
		return
	for button in hero_buttons:
		if is_instance_valid(button):
			button.queue_free()
	hero_buttons.clear()
	for hero_index in range(heroes.size()):
		var hero_button: Button = Button.new()
		hero_button.custom_minimum_size = Vector2(64.0, 36.0)
		hero_button.add_theme_font_size_override("font_size", 16)
		hero_button.pressed.connect(_on_hero_button_pressed.bind(hero_index))
		hero_bar.add_child(hero_button)
		hero_buttons.append(hero_button)

func build_dungeon(reset_resources: bool = true) -> void:
	if reset_resources:
		hero_profiles.clear()
	else:
		save_hero_profiles_from_nodes()
	clear_inventory_session(false)
	clear_floor_actors()
	rooms.clear()
	room_nav_cache.clear()
	projectiles.clear()
	floating_resource_texts.clear()
	pending_enemy_spawns.clear()
	pending_room_constructions.clear()
	next_enemy_uid = 1
	next_card_uid = 1
	global_item_card_states.clear()
	global_item_passive_timers.clear()
	active_hand_drag.clear()
	hand_card_return_animations.clear()
	pending_melee_attacks.clear()
	build_menu_open = false
	pending_build_type = ""
	opened_rooms = 1
	doors_opened = 0
	wave_index = 0
	exit_room = INVALID_ROOM
	crystal_holder = null
	crystal_ground_room = crystal_room
	crystal_prompt_visible = false
	crystal_pressure_timer_left = 0.0
	door_wave_auto_heal_pending = false
	door_wave_healing_active = false
	opening_room = INVALID_ROOM
	opening_origin_room = INVALID_ROOM
	opening_hero = null
	opening_timer_left = 0.0
	opening_heroes.clear()
	room_action_hold.clear()
	room_action_menu.clear()
	if reset_resources:
		floor_index = 1
		dust = 4
		food = 10
		industry = 14
		science = 0
		crystal_health = 100.0
	var crystal_door_dirs: Array = crystal_room_door_dirs_for_floor()
	create_room(crystal_room, ROOM_TEMPLATE_FORGE, crystal_door_dirs, Vector2.ZERO)
	var crystal: Dictionary = rooms[crystal_room]
	crystal["opened"] = true
	crystal["lit"] = true
	crystal["permanent_light"] = true
	crystal["temporary_light_turns"] = 0
	crystal["wave_torch_until_wave"] = -1
	crystal["crystal"] = true
	crystal["minor_slots"] = 0
	crystal["major_slots"] = 0
	crystal["major_under_construction"] = false
	var target_room_count: int = 12
	var layout_attempts: int = 0
	while rooms.size() < target_room_count and layout_attempts < 800:
		layout_attempts += 1
		var frontier_sockets: Array = collect_frontier_sockets()
		if frontier_sockets.is_empty():
			break
		var socket: Dictionary = frontier_sockets[rng.randi_range(0, frontier_sockets.size() - 1)]
		var origin: Vector2i = socket["room"]
		var direction: Vector2i = socket["direction"]
		var room_coord: Vector2i = origin + direction
		var generating_second_room: bool = rooms.size() == 1
		var prefer_dead_end: bool = rooms.size() >= 4 and frontier_sockets.size() >= 3 and rng.randf() < 0.58
		var minimum_doors: int = 2 if generating_second_room else 1
		var blueprint: Dictionary = roll_room_blueprint(-direction, generating_second_room, prefer_dead_end, minimum_doors)
		if blueprint.is_empty():
			continue
		var template_id: String = String(blueprint["template_id"])
		var candidate_center: Vector2 = proposed_room_center(origin, template_id, direction)
		if not can_place_room_center(candidate_center, room_template_size(template_id)):
			continue
		create_room(room_coord, template_id, blueprint["door_dirs"], candidate_center)
		connect_rooms(origin, room_coord)
	finalize_room_slot_distribution()
	assign_exit_room()
	refresh_room_lighting_states()
	refresh_camera_bounds()
	invalidate_static_dungeon_layer()

func clear_floor_actors() -> void:
	pending_room_loot_requests.clear()
	pending_room_action_requests.clear()
	pending_room_constructions.clear()
	pending_melee_attacks.clear()
	floating_resource_texts.clear()
	for hero in heroes:
		if is_instance_valid(hero):
			hero.queue_free()
	heroes.clear()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

func ensure_hero_profiles() -> void:
	if hero_profiles.size() >= HERO_COUNT:
		for hero_index in range(hero_profiles.size()):
			if not hero_profiles[hero_index].has("class_id"):
				hero_profiles[hero_index]["class_id"] = default_hero_class_for_slot(hero_index)
			if not hero_profiles[hero_index].has("dead"):
				hero_profiles[hero_index]["dead"] = false
			hero_profiles[hero_index]["name"] = hero_display_name(hero_index, String(hero_profiles[hero_index].get("class_id", default_hero_class_for_slot(hero_index))))
			if not hero_profiles[hero_index].has("learned_spells"):
				hero_profiles[hero_index]["learned_spells"] = default_learned_spells_for_class(String(hero_profiles[hero_index]["class_id"]))
			if not hero_profiles[hero_index].has("slotted_spells"):
				hero_profiles[hero_index]["slotted_spells"] = default_slotted_spells_for_class(String(hero_profiles[hero_index]["class_id"]))
		return
	for hero_index in range(hero_profiles.size(), HERO_COUNT):
		var class_id: String = default_hero_class_for_slot(hero_index)
		hero_profiles.append({
			"class_id": class_id,
			"name": hero_display_name(hero_index, class_id),
			"level": 1,
			"dead": false,
			"pack_modules": [],
			"inventory_items": default_inventory_items_for_class(class_id),
			"learned_spells": default_learned_spells_for_class(class_id),
			"slotted_spells": default_slotted_spells_for_class(class_id),
		})

func hero_supports_spell_repertoire(hero: Variant) -> bool:
	return hero != null and is_instance_valid(hero) and spell_focus_item_id_for_class(String(hero.hero_class_id)) != ""

func hero_has_spell_focus_item(hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	var focus_item_id: String = spell_focus_item_id_for_class(String(hero.hero_class_id))
	if focus_item_id == "":
		return false
	for item_variant in hero.inventory_items:
		if String((item_variant as Dictionary).get("item_id", "")) == focus_item_id:
			return true
	return false

func spell_focus_item_uid_for_hero(hero: Variant) -> int:
	if hero == null or not is_instance_valid(hero):
		return -1
	var focus_item_id: String = spell_focus_item_id_for_class(String(hero.hero_class_id))
	if focus_item_id == "":
		return -1
	for item_variant in hero.inventory_items:
		var item: Dictionary = item_variant
		if String(item.get("item_id", "")) == focus_item_id:
			return int(item.get("uid", -1))
	return -1

func hero_can_prepare_spell(hero: Variant, spell_id: String) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if spell_id == "" or spell_class_id(spell_id) != String(hero.hero_class_id):
		return false
	var required_level: int = spell_level(spell_id)
	if required_level <= 0:
		return false
	return required_level <= hero_max_spell_level_for_class_level(String(hero.hero_class_id), int(hero.level))

func hero_spell_repertoire_editable(hero: Variant) -> bool:
	return hero != null and is_instance_valid(hero) and hero_supports_spell_repertoire(hero)

func prepared_spell_max_copies(hero: Variant, spell_id: String, slot_counts: Array[int] = []) -> int:
	if hero == null or not is_instance_valid(hero) or spell_id == "":
		return 0
	var card_def: Dictionary = card_definition(spell_id)
	var explicit_limit: int = int(card_def.get("max_prepared_copies", 0))
	if explicit_limit > 0:
		return explicit_limit
	if bool(card_def.get("reusable", false)):
		return 1
	var resolved_slot_counts: Array[int] = slot_counts if not slot_counts.is_empty() else spell_slot_counts_for_class_level(String(hero.hero_class_id), int(hero.level))
	var level_index: int = spell_level(spell_id) - 1
	if level_index < 0 or level_index >= resolved_slot_counts.size():
		return 0
	return int(resolved_slot_counts[level_index])

func default_prepared_spell_list(hero: Variant, slot_counts: Array[int]) -> Array[String]:
	var prepared: Array[String] = []
	if hero == null or not is_instance_valid(hero):
		return prepared
	var copy_counts: Dictionary = {}
	for level_index in range(slot_counts.size()):
		var slots_remaining: int = int(slot_counts[level_index])
		if slots_remaining <= 0:
			continue
		var level_spells: Array[String] = []
		for learned_spell_variant in hero.learned_spells:
			var learned_spell_id: String = String(learned_spell_variant)
			if spell_level(learned_spell_id) == level_index + 1 and hero_can_prepare_spell(hero, learned_spell_id):
				level_spells.append(learned_spell_id)
		if level_spells.is_empty():
			continue
		var made_progress: bool = true
		while slots_remaining > 0 and made_progress:
			made_progress = false
			for level_spell_id in level_spells:
				var used_copies: int = int(copy_counts.get(level_spell_id, 0))
				if used_copies >= prepared_spell_max_copies(hero, level_spell_id, slot_counts):
					continue
				copy_counts[level_spell_id] = used_copies + 1
				prepared.append(level_spell_id)
				slots_remaining -= 1
				made_progress = true
				if slots_remaining <= 0:
					break
	return prepared

func cleaned_prepared_spell_list(hero: Variant, source_spells: Array) -> Array[String]:
	var cleaned_slots: Array[String] = []
	if hero == null or not is_instance_valid(hero):
		return cleaned_slots
	var slot_counts: Array[int] = spell_slot_counts_for_class_level(String(hero.hero_class_id), int(hero.level))
	var used_slots_by_level: Array[int] = []
	used_slots_by_level.resize(slot_counts.size())
	for slot_index in range(used_slots_by_level.size()):
		used_slots_by_level[slot_index] = 0
	var used_spell_copies: Dictionary = {}
	for spell_variant in source_spells:
		var spell_id: String = String(spell_variant)
		if spell_id == "" or not hero.learned_spells.has(spell_id) or not hero_can_prepare_spell(hero, spell_id):
			continue
		var level_index: int = spell_level(spell_id) - 1
		if level_index < 0 or level_index >= slot_counts.size() or used_slots_by_level[level_index] >= slot_counts[level_index]:
			continue
		var used_copies: int = int(used_spell_copies.get(spell_id, 0))
		if used_copies >= prepared_spell_max_copies(hero, spell_id, slot_counts):
			continue
		cleaned_slots.append(spell_id)
		used_slots_by_level[level_index] += 1
		used_spell_copies[spell_id] = used_copies + 1
	if cleaned_slots.is_empty() and not hero.learned_spells.is_empty():
		cleaned_slots = default_prepared_spell_list(hero, slot_counts)
	return cleaned_slots

func refresh_active_floor_spells(hero: Variant, force_saved_repertoire: bool = false) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if force_saved_repertoire or hero.active_floor_spells.is_empty() or doors_opened == 0:
		hero.active_floor_spells = cleaned_prepared_spell_list(hero, hero.slotted_spells)
	else:
		hero.active_floor_spells = cleaned_prepared_spell_list(hero, hero.active_floor_spells)

func sanitize_hero_spellbook(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if not hero_supports_spell_repertoire(hero) or not hero_has_spell_focus_item(hero):
		hero.learned_spells.clear()
		hero.slotted_spells.clear()
		hero.active_floor_spells.clear()
		hero.studying_spell_id = ""
		hero.studying_room = INVALID_ROOM
		hero.studying_started_at_door = -1
		return
	var known_map: Dictionary = {}
	var cleaned_known: Array[String] = []
	for spell_variant in hero.learned_spells:
		var spell_id: String = String(spell_variant)
		if spell_id == "" or known_map.has(spell_id) or spell_class_id(spell_id) != String(hero.hero_class_id):
			continue
		known_map[spell_id] = true
		cleaned_known.append(spell_id)
	if cleaned_known.is_empty():
		cleaned_known = default_learned_spells_for_class(hero.hero_class_id).duplicate()
	hero.learned_spells = cleaned_known
	hero.slotted_spells = cleaned_prepared_spell_list(hero, hero.slotted_spells)
	refresh_active_floor_spells(hero)

func save_hero_profiles_from_nodes() -> void:
	ensure_hero_profiles()
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		hero_profiles[hero.hero_index]["class_id"] = hero.hero_class_id
		hero_profiles[hero.hero_index]["name"] = hero.hero_name
		hero_profiles[hero.hero_index]["level"] = hero.level
		hero_profiles[hero.hero_index]["dead"] = bool(hero.has_method("is_dead_state") and hero.is_dead_state())
		hero_profiles[hero.hero_index]["pack_modules"] = hero.pack_modules.duplicate(true)
		hero_profiles[hero.hero_index]["inventory_items"] = hero.inventory_items.duplicate(true)
		hero_profiles[hero.hero_index]["learned_spells"] = hero.learned_spells.duplicate()
		hero_profiles[hero.hero_index]["slotted_spells"] = hero.slotted_spells.duplicate()

func roll_room_template() -> String:
	var roll: float = rng.randf()
	if roll < 0.28:
		return ROOM_TEMPLATE_NOOK
	if roll < 0.52:
		return ROOM_TEMPLATE_GALLERY
	if roll < 0.8:
		return ROOM_TEMPLATE_WORKSHOP
	return ROOM_TEMPLATE_FORGE

func crystal_room_door_dirs_for_floor() -> Array:
	if floor_index == 1:
		return [CARDINAL_DIRS[rng.randi_range(0, CARDINAL_DIRS.size() - 1)]]
	return random_template_doors(ROOM_TEMPLATE_FORGE)

func shrink_normalized_rect(rect: Rect2, margin: Vector2) -> Rect2:
	var shrunk_position: Vector2 = rect.position + margin
	var shrunk_size: Vector2 = rect.size - margin * 2.0
	return Rect2(
		shrunk_position,
		Vector2(
			maxf(shrunk_size.x, 0.04),
			maxf(shrunk_size.y, 0.04)
		)
	)

func room_layout_platform_rect(template_id: String, crystal_chamber: bool = false) -> Rect2:
	if crystal_chamber:
		return Rect2(0.24, 0.23, 0.52, 0.54)
	match template_id:
		ROOM_TEMPLATE_GALLERY:
			return Rect2(0.27, 0.28, 0.46, 0.44)
		ROOM_TEMPLATE_WORKSHOP:
			return Rect2(0.23, 0.24, 0.54, 0.50)
		ROOM_TEMPLATE_FORGE:
			return Rect2(0.21, 0.22, 0.58, 0.54)
		_:
			return Rect2(0.28, 0.29, 0.44, 0.42)

func room_layout_causeway_width(template_id: String, crystal_chamber: bool = false) -> float:
	if crystal_chamber:
		return 0.18
	match template_id:
		ROOM_TEMPLATE_GALLERY:
			return 0.16
		ROOM_TEMPLATE_WORKSHOP:
			return 0.17
		ROOM_TEMPLATE_FORGE:
			return 0.18
		_:
			return 0.15

func room_layout_causeway_rect(direction: Vector2i, platform_rect: Rect2, width: float) -> Rect2:
	var center_x: float = platform_rect.position.x + platform_rect.size.x * 0.5
	var center_y: float = platform_rect.position.y + platform_rect.size.y * 0.5
	match direction:
		Vector2i.LEFT:
			return Rect2(0.0, center_y - width * 0.5, maxf(platform_rect.position.x, 0.08), width)
		Vector2i.RIGHT:
			var right_start: float = platform_rect.position.x + platform_rect.size.x
			return Rect2(right_start, center_y - width * 0.5, maxf(1.0 - right_start, 0.08), width)
		Vector2i.UP:
			return Rect2(center_x - width * 0.5, 0.0, width, maxf(platform_rect.position.y, 0.08))
		Vector2i.DOWN:
			var lower_start: float = platform_rect.position.y + platform_rect.size.y
			return Rect2(center_x - width * 0.5, lower_start, width, maxf(1.0 - lower_start, 0.08))
		_:
			return platform_rect

func floor_theme_id_for_floor(target_floor_index: int) -> String:
	if FLOOR_THEME_ORDER.is_empty():
		return FLOOR_THEME_CAVERN
	return FLOOR_THEME_ORDER[posmod(target_floor_index - 1, FLOOR_THEME_ORDER.size())]

func current_floor_theme_id() -> String:
	return floor_theme_id_for_floor(floor_index)

func pick_room_geometry_id(template_id: String, door_dirs: Array, crystal_chamber: bool = false) -> String:
	if crystal_chamber:
		return "crystal_grotto"
	var candidates: Array[String] = [
		"flooded_cross",
		"moss_terraces",
	]
	var has_horizontal: bool = door_dirs.has(Vector2i.LEFT) or door_dirs.has(Vector2i.RIGHT)
	var has_vertical: bool = door_dirs.has(Vector2i.UP) or door_dirs.has(Vector2i.DOWN)
	if has_horizontal:
		candidates.append("stream_horizontal")
	if has_vertical:
		candidates.append("stream_vertical")
	if template_id == ROOM_TEMPLATE_WORKSHOP or template_id == ROOM_TEMPLATE_FORGE or door_dirs.size() >= 3:
		candidates.append("moss_terraces")
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func build_room_geometry(template_id: String, door_dirs: Array, crystal_chamber: bool = false) -> Dictionary:
	var platform_rect: Rect2 = room_layout_platform_rect(template_id, crystal_chamber)
	var causeway_width: float = room_layout_causeway_width(template_id, crystal_chamber)
	var walkable_regions: Array = [platform_rect]
	for direction in CARDINAL_DIRS:
		if door_dirs.has(direction):
			walkable_regions.append(room_layout_causeway_rect(direction, platform_rect, causeway_width))
	var slot_regions: Array = []
	if not crystal_chamber:
		slot_regions.append(shrink_normalized_rect(platform_rect, Vector2(0.05, 0.05)))
	var geometry_id: String = pick_room_geometry_id(template_id, door_dirs, crystal_chamber)
	var liquid_regions: Array = []
	var growth_regions: Array = []
	var obstacle_regions: Array = []
	match geometry_id:
		"stream_horizontal":
			liquid_regions = [
				Rect2(0.05, 0.13, 0.90, 0.15),
				Rect2(0.05, 0.71, 0.90, 0.12),
			]
			growth_regions = [
				Rect2(0.10, 0.31, 0.18, 0.11),
				Rect2(0.73, 0.57, 0.16, 0.10),
				Rect2(0.36, 0.82, 0.22, 0.09),
			]
			obstacle_regions = [
				Rect2(0.06, 0.05, 0.24, 0.08),
				Rect2(0.70, 0.85, 0.22, 0.07),
			]
		"stream_vertical":
			liquid_regions = [
				Rect2(0.12, 0.07, 0.16, 0.86),
				Rect2(0.72, 0.07, 0.13, 0.86),
			]
			growth_regions = [
				Rect2(0.34, 0.10, 0.14, 0.11),
				Rect2(0.48, 0.75, 0.18, 0.10),
				Rect2(0.34, 0.46, 0.14, 0.10),
			]
			obstacle_regions = [
				Rect2(0.04, 0.09, 0.08, 0.22),
				Rect2(0.88, 0.66, 0.07, 0.20),
			]
		"moss_terraces":
			liquid_regions = [
				Rect2(0.06, 0.16, 0.18, 0.17),
				Rect2(0.76, 0.66, 0.18, 0.17),
			]
			growth_regions = [
				Rect2(0.12, 0.62, 0.20, 0.13),
				Rect2(0.68, 0.20, 0.18, 0.12),
				Rect2(0.39, 0.10, 0.22, 0.10),
				Rect2(0.38, 0.79, 0.22, 0.09),
			]
			obstacle_regions = [
				Rect2(0.05, 0.04, 0.25, 0.09),
				Rect2(0.71, 0.05, 0.21, 0.08),
				Rect2(0.07, 0.86, 0.19, 0.07),
			]
		"crystal_grotto":
			liquid_regions = [
				Rect2(0.05, 0.17, 0.16, 0.18),
				Rect2(0.79, 0.17, 0.16, 0.18),
				Rect2(0.08, 0.69, 0.15, 0.16),
				Rect2(0.77, 0.69, 0.15, 0.16),
			]
			growth_regions = [
				Rect2(0.15, 0.48, 0.16, 0.12),
				Rect2(0.68, 0.48, 0.16, 0.12),
			]
			obstacle_regions = [
				Rect2(0.32, 0.06, 0.36, 0.08),
				Rect2(0.31, 0.86, 0.38, 0.07),
			]
		_:
			liquid_regions = [
				Rect2(0.06, 0.10, 0.20, 0.22),
				Rect2(0.74, 0.10, 0.20, 0.22),
				Rect2(0.08, 0.67, 0.18, 0.17),
				Rect2(0.74, 0.67, 0.18, 0.17),
			]
			growth_regions = [
				Rect2(0.11, 0.39, 0.16, 0.10),
				Rect2(0.73, 0.39, 0.16, 0.10),
				Rect2(0.38, 0.80, 0.24, 0.08),
			]
			obstacle_regions = [
				Rect2(0.05, 0.04, 0.22, 0.07),
				Rect2(0.72, 0.87, 0.19, 0.06),
			]
	return {
		"geometry_id": geometry_id,
		"walkable_regions": walkable_regions,
		"slot_regions": slot_regions,
		"liquid_regions": liquid_regions,
		"growth_regions": growth_regions,
		"obstacle_regions": obstacle_regions,
	}

func create_room(room_coord: Vector2i, template_id: String, door_dirs: Array, world_center: Vector2 = Vector2.INF) -> void:
	var room_size: Vector2 = Vector2(330.0, 220.0)
	var minor_slots: int = 2
	var major_slots: int = 0
	var template_name: String = "Nook"
	match template_id:
		ROOM_TEMPLATE_GALLERY:
			room_size = Vector2(400.0, 250.0)
			minor_slots = 3
			template_name = "Gallery"
		ROOM_TEMPLATE_WORKSHOP:
			room_size = Vector2(490.0, 320.0)
			minor_slots = 5
			major_slots = 1
			template_name = "Workshop"
		ROOM_TEMPLATE_FORGE:
			room_size = Vector2(540.0, 350.0)
			minor_slots = 7
			major_slots = 1
			template_name = "Forge"
		_:
			room_size = Vector2(330.0, 220.0)
			minor_slots = 2
			major_slots = 0
			template_name = "Nook"
	var geometry_data: Dictionary = build_room_geometry(template_id, door_dirs, room_coord == crystal_room)
	var theme_id: String = current_floor_theme_id()
	rooms[room_coord] = {
		"neighbors": [],
		"center": world_center if world_center != Vector2.INF else room_center(room_coord),
		"opened": false,
		"lit": false,
		"permanent_light": false,
		"temporary_light_turns": 0,
		"wave_torch_until_wave": -1,
		"crystal": false,
		"exit": false,
		"profile": template_id,
		"theme_id": theme_id,
		"template_name": template_name,
		"door_dirs": door_dirs.duplicate(),
		"geometry_id": String(geometry_data.get("geometry_id", "flooded_cross")),
		"walkable_regions": Array(geometry_data.get("walkable_regions", [])),
		"slot_regions": Array(geometry_data.get("slot_regions", [])),
		"liquid_regions": Array(geometry_data.get("liquid_regions", [])),
		"growth_regions": Array(geometry_data.get("growth_regions", [])),
		"obstacle_regions": Array(geometry_data.get("obstacle_regions", [])),
		"size": room_size,
		"minor_slots": minor_slots,
		"major_slots": major_slots,
		"minor_modules": [],
		"major_module_type": "",
		"major_health": 0.0,
		"major_under_construction": false,
		"warning_timer_left": 0.0,
		"ground_items": [],
	}

func room_template_door_options(template_id: String) -> Array:
	match template_id:
		ROOM_TEMPLATE_GALLERY:
			return [
				[Vector2i.LEFT, Vector2i.RIGHT],
				[Vector2i.UP, Vector2i.DOWN],
				[Vector2i.LEFT, Vector2i.UP],
				[Vector2i.UP, Vector2i.RIGHT],
				[Vector2i.RIGHT, Vector2i.DOWN],
				[Vector2i.DOWN, Vector2i.LEFT],
			]
		ROOM_TEMPLATE_WORKSHOP:
			return [
				[Vector2i.LEFT],
				[Vector2i.RIGHT],
				[Vector2i.UP],
				[Vector2i.DOWN],
				[Vector2i.LEFT, Vector2i.UP],
				[Vector2i.UP, Vector2i.RIGHT],
				[Vector2i.RIGHT, Vector2i.DOWN],
				[Vector2i.DOWN, Vector2i.LEFT],
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP],
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN],
				[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT],
				[Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT],
			]
		ROOM_TEMPLATE_FORGE:
			return [
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP],
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN],
				[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT],
				[Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT],
				[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN],
			]
		_:
			return [
				[Vector2i.LEFT],
				[Vector2i.RIGHT],
				[Vector2i.UP],
				[Vector2i.DOWN],
			]

func random_template_doors(template_id: String, required_dir: Vector2i = INVALID_ROOM) -> Array:
	var valid_options: Array = []
	for option in room_template_door_options(template_id):
		if required_dir == INVALID_ROOM or option.has(required_dir):
			valid_options.append(option)
	if valid_options.is_empty():
		return []
	var chosen: Array = valid_options[rng.randi_range(0, valid_options.size() - 1)]
	return chosen.duplicate()

func template_can_support_major_slots(template_id: String) -> bool:
	return template_id == ROOM_TEMPLATE_WORKSHOP or template_id == ROOM_TEMPLATE_FORGE

func room_blueprint_weight(template_id: String, door_dirs: Array, prefer_major: bool = false, prefer_dead_end: bool = false) -> float:
	var weight: float = 1.0
	match template_id:
		ROOM_TEMPLATE_NOOK:
			weight = 3.0
		ROOM_TEMPLATE_GALLERY:
			weight = 2.1
		ROOM_TEMPLATE_WORKSHOP:
			weight = 2.2
		ROOM_TEMPLATE_FORGE:
			weight = 1.15
		_:
			weight = 1.0
	var door_count: int = door_dirs.size()
	if prefer_dead_end:
		if door_count <= 1:
			weight *= 2.45
		elif door_count == 2:
			weight *= 1.05
		else:
			weight *= 0.58
	else:
		if door_count <= 1:
			weight *= 1.22
		elif door_count >= 4:
			weight *= 0.82
	if prefer_major:
		if template_can_support_major_slots(template_id):
			weight *= 3.0
		elif template_id == ROOM_TEMPLATE_GALLERY:
			weight *= 0.55
		else:
			weight *= 0.18
	return weight

func roll_room_blueprint(required_dir: Vector2i, prefer_major: bool = false, prefer_dead_end: bool = false, minimum_doors: int = 1) -> Dictionary:
	var candidates: Array = []
	var total_weight: float = 0.0
	for template_id_variant in [ROOM_TEMPLATE_NOOK, ROOM_TEMPLATE_GALLERY, ROOM_TEMPLATE_WORKSHOP, ROOM_TEMPLATE_FORGE]:
		var template_id: String = String(template_id_variant)
		for option_variant in room_template_door_options(template_id):
			var door_dirs: Array = Array(option_variant)
			if (required_dir != INVALID_ROOM and not door_dirs.has(required_dir)) or door_dirs.size() < minimum_doors:
				continue
			var candidate_weight: float = room_blueprint_weight(template_id, door_dirs, prefer_major, prefer_dead_end)
			if candidate_weight <= 0.0:
				continue
			candidates.append({
				"template_id": template_id,
				"door_dirs": door_dirs.duplicate(),
				"weight": candidate_weight,
			})
			total_weight += candidate_weight
	if candidates.is_empty():
		return {}
	var roll: float = rng.randf() * maxf(total_weight, 0.001)
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		roll -= float(candidate.get("weight", 1.0))
		if roll <= 0.0:
			return {
				"template_id": String(candidate.get("template_id", ROOM_TEMPLATE_NOOK)),
				"door_dirs": Array(candidate.get("door_dirs", [])).duplicate(),
			}
	var fallback: Dictionary = candidates[candidates.size() - 1]
	return {
		"template_id": String(fallback.get("template_id", ROOM_TEMPLATE_NOOK)),
		"door_dirs": Array(fallback.get("door_dirs", [])).duplicate(),
	}

func room_template_size(template_id: String) -> Vector2:
	match template_id:
		ROOM_TEMPLATE_GALLERY:
			return Vector2(400.0, 250.0)
		ROOM_TEMPLATE_WORKSHOP:
			return Vector2(490.0, 320.0)
		ROOM_TEMPLATE_FORGE:
			return Vector2(540.0, 350.0)
		_:
			return Vector2(330.0, 220.0)

func proposed_room_center(origin_room: Vector2i, template_id: String, direction: Vector2i) -> Vector2:
	var origin_size: Vector2 = room_size_for(origin_room)
	var next_size: Vector2 = room_template_size(template_id)
	var offset: Vector2 = Vector2.ZERO
	if direction.x != 0:
		offset.x = float(direction.x) * ((origin_size.x + next_size.x) * 0.5 + ROOM_DOOR_GAP)
	if direction.y != 0:
		offset.y = float(direction.y) * ((origin_size.y + next_size.y) * 0.5 + ROOM_DOOR_GAP)
	return room_center(origin_room) + offset

func can_place_room_center(world_center: Vector2, room_size: Vector2) -> bool:
	var candidate_rect: Rect2 = Rect2(world_center - room_size * 0.5, room_size).grow(ROOM_LAYOUT_CLEARANCE)
	for existing_coord_variant in rooms.keys():
		var existing_coord: Vector2i = existing_coord_variant
		if candidate_rect.intersects(room_rect(existing_coord).grow(ROOM_LAYOUT_CLEARANCE)):
			return false
	return true

func collect_frontier_sockets() -> Array:
	var sockets: Array = []
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		for direction_variant in room["door_dirs"]:
			var direction: Vector2i = direction_variant
			var candidate: Vector2i = room_coord + direction
			if not is_in_bounds(candidate) or rooms.has(candidate):
				continue
			sockets.append({
				"room": room_coord,
				"direction": direction,
			})
	return sockets

func connect_rooms(a: Vector2i, b: Vector2i) -> void:
	var delta: Vector2i = b - a
	if not rooms[a]["door_dirs"].has(delta) or not rooms[b]["door_dirs"].has(-delta):
		return
	if not rooms[a]["neighbors"].has(b):
		rooms[a]["neighbors"].append(b)
	if not rooms[b]["neighbors"].has(a):
		rooms[b]["neighbors"].append(a)

func are_neighbors(a: Vector2i, b: Vector2i) -> bool:
	return rooms.has(a) and rooms[a]["neighbors"].has(b)

func finalize_room_slot_distribution() -> void:
	var second_room: Vector2i = INVALID_ROOM
	if rooms.has(crystal_room):
		var crystal_neighbors: Array = Array(rooms[crystal_room].get("neighbors", []))
		if not crystal_neighbors.is_empty():
			second_room = Vector2i(crystal_neighbors[0])
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if room_coord == crystal_room:
			room["minor_slots"] = 0
			room["major_slots"] = 0
			continue
		var degree: int = Array(room.get("neighbors", [])).size()
		match String(room.get("profile", ROOM_TEMPLATE_NOOK)):
			ROOM_TEMPLATE_FORGE:
				room["major_slots"] = 1
			ROOM_TEMPLATE_WORKSHOP:
				var workshop_major_chance: float = 0.62 if degree <= 1 else 0.44
				room["major_slots"] = 1 if rng.randf() < workshop_major_chance else 0
			_:
				room["major_slots"] = 0
	if second_room != INVALID_ROOM and rooms.has(second_room):
		rooms[second_room]["major_slots"] = max(1, int(rooms[second_room].get("major_slots", 0)))

func assign_exit_room() -> void:
	var best_path_length: int = -1
	exit_room = INVALID_ROOM
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		rooms[room_coord]["exit"] = false
		if room_coord == crystal_room:
			continue
		var path: Array[Vector2i] = find_path(crystal_room, room_coord, false)
		if path.is_empty():
			continue
		if path.size() > best_path_length:
			best_path_length = path.size()
			exit_room = room_coord
	if exit_room == INVALID_ROOM:
		for neighbor_variant in Array(rooms.get(crystal_room, {}).get("neighbors", [])):
			var fallback_room: Vector2i = neighbor_variant
			if rooms.has(fallback_room):
				exit_room = fallback_room
				break
	if exit_room != INVALID_ROOM:
		rooms[exit_room]["exit"] = true

func spawn_heroes() -> void:
	ensure_hero_profiles()
	for hero_index in range(HERO_COUNT):
		var hero: Variant = HERO_SCENE.instantiate()
		actor_layer.add_child(hero)
		hero.hero_index = hero_index
		var hero_class_id: String = hero_profile_class_id(hero_index)
		apply_hero_class_to_node(hero, hero_class_id, String(hero_profiles[hero_index].get("name", hero_display_name(hero_index, hero_class_id))))
		hero.level = int(hero_profiles[hero_index].get("level", 1))
		hero.selected = hero_index == selected_hero_index
		hero.inventory_canvas_size = INVENTORY_CANVAS_SIZE
		hero.base_inventory_origin = INVENTORY_BASE_ORIGIN
		hero.base_inventory_size = INVENTORY_BASE_SIZE
		hero.pack_modules = Array(hero_profiles[hero_index].get("pack_modules", [])).duplicate(true)
		hero.inventory_items = Array(hero_profiles[hero_index].get("inventory_items", [])).duplicate(true)
		hero.learned_spells = Array(hero_profiles[hero_index].get("learned_spells", default_learned_spells_for_class(hero_class_id))).duplicate()
		hero.slotted_spells = Array(hero_profiles[hero_index].get("slotted_spells", default_slotted_spells_for_class(hero_class_id))).duplicate()
		hero.active_floor_spells = hero.slotted_spells.duplicate()
		sanitize_hero_spellbook(hero)
		hero.set_calm_movement_multiplier(selected_calm_speed_multiplier())
		hero.set_room(crystal_room, hero_idle_position(crystal_room, hero_index, HERO_COUNT))
		apply_inventory_stats_to_hero(hero)
		if bool(hero_profiles[hero_index].get("dead", false)):
			hero.set_permanently_dead_hidden()
		heroes.append(hero)
	if selected_hero_index >= heroes.size():
		selected_hero_index = 0
	ensure_valid_selected_hero()
	rebuild_hero_bar()
	update_selected_hero_flags()

func item_size_in_cells(item: Dictionary) -> Vector2i:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	if bool(item.get("rotated", false)):
		return Vector2i(base_size.y, base_size.x)
	return base_size

func normalize_item_instance(item_variant: Variant) -> Dictionary:
	var item: Dictionary = (item_variant as Dictionary).duplicate(true)
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	if not item.has("uid"):
		item["uid"] = next_item_uid
		next_item_uid += 1
	if item_def.has("max_charges") and not item.has("charges_left"):
		item["charges_left"] = int(item_def.get("max_charges", 0))
	return item

func make_ground_item(item_id: String, world_position: Vector2) -> Dictionary:
	var ground_item: Dictionary = normalize_item_instance({
		"uid": next_item_uid,
		"item_id": item_id,
		"position": world_position,
		"rotated": false,
	})
	next_item_uid += 1
	return ground_item

func roll_ground_item_id() -> String:
	var weighted_item_ids: Array[String] = [
		"ration", "ration",
		"boots", "boots",
		"blade", "blade",
		"buckler",
		"whetstone", "whetstone",
		"banner",
		"lantern",
		"medkit",
		"torch",
		"axe",
		"daggers",
		"scroll_fireball",
		"scroll_magic_missile",
		"scroll_misty_step",
		"scroll_shield",
		"scroll_lightning_bolt",
	]
	if weighted_item_ids.is_empty():
		return ""
	return String(weighted_item_ids[rng.randi_range(0, weighted_item_ids.size() - 1)])

func spawn_ground_loot(room_coord: Vector2i) -> void:
	if not rooms.has(room_coord):
		return
	if rng.randf() > 0.72:
		return
	var loot_count: int = 1
	if rng.randf() < 0.18:
		loot_count = 2
	for loot_index in range(loot_count):
		var item_id: String = roll_ground_item_id()
		if item_id == "":
			continue
		var item_position: Vector2 = clamp_point_to_room(room_center(room_coord) + random_room_offset(84.0 + float(loot_index) * 28.0), room_coord)
		rooms[room_coord]["ground_items"].append(make_ground_item(item_id, item_position))

func ground_item_draw_rect(ground_item: Dictionary) -> Rect2:
	var size_cells: Vector2i = item_size_in_cells(ground_item)
	var draw_size: Vector2 = Vector2(size_cells) * GROUND_ITEM_DRAW_SCALE
	return Rect2(Vector2(ground_item["position"]) - draw_size * 0.5, draw_size)

func ground_item_pick_rect(ground_item: Dictionary) -> Rect2:
	var draw_rect_local: Rect2 = ground_item_draw_rect(ground_item)
	var expanded_size: Vector2 = Vector2(
		maxf(draw_rect_local.size.x + 20.0, GROUND_ITEM_PICK_MIN_SIZE),
		maxf(draw_rect_local.size.y + 20.0, GROUND_ITEM_PICK_MIN_SIZE)
	)
	return Rect2(draw_rect_local.get_center() - expanded_size * 0.5, expanded_size)

func ground_item_at_world_position(world_position: Vector2) -> Dictionary:
	var closest_hit: Dictionary = {}
	var closest_distance: float = GROUND_ITEM_PICK_RADIUS
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if not room["opened"]:
			continue
		for item_index in range(room["ground_items"].size() - 1, -1, -1):
			var ground_item: Dictionary = room["ground_items"][item_index]
			var item_center: Vector2 = Vector2(ground_item["position"])
			var item_distance: float = item_center.distance_to(world_position)
			if not ground_item_pick_rect(ground_item).has_point(world_position) and item_distance > GROUND_ITEM_PICK_RADIUS:
				continue
			if closest_hit.is_empty() or item_distance < closest_distance:
				closest_distance = item_distance
				closest_hit = {
					"room": room_coord,
					"index": item_index,
					"item": ground_item,
				}
	return closest_hit

func find_ground_item_index(room_coord: Vector2i, item_uid: int) -> int:
	if not rooms.has(room_coord):
		return -1
	for item_index in range(rooms[room_coord]["ground_items"].size()):
		if int(rooms[room_coord]["ground_items"][item_index]["uid"]) == item_uid:
			return item_index
	return -1

func prepare_ground_items_for_room(room_coord: Vector2i, ground_items: Array) -> Array:
	var prepared_items: Array = []
	for item_index in range(ground_items.size()):
		var ground_item: Dictionary = normalize_item_instance(ground_items[item_index])
		ground_item.erase("anchor")
		var fallback_position: Vector2 = room_center(room_coord) + random_room_offset(70.0 + float(item_index) * 20.0)
		ground_item["position"] = clamp_point_to_room(Vector2(ground_item.get("position", fallback_position)), room_coord)
		prepared_items.append(ground_item)
	return prepared_items

func inventory_base_cells() -> Array:
	var cells: Array = []
	for offset_y in range(INVENTORY_BASE_SIZE.y):
		for offset_x in range(INVENTORY_BASE_SIZE.x):
			cells.append(INVENTORY_BASE_ORIGIN + Vector2i(offset_x, offset_y))
	return cells

func pack_cells(pack_module: Dictionary) -> Array:
	var cells: Array = []
	var anchor: Vector2i = pack_module.get("anchor", INVALID_ROOM)
	var size_cells: Vector2i = pack_module.get("size", Vector2i.ONE)
	if anchor == INVALID_ROOM:
		return cells
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			cells.append(anchor + Vector2i(offset_x, offset_y))
	return cells

func active_inventory_cells_from_packs(pack_modules: Array) -> Dictionary:
	var active_cells: Dictionary = {}
	for base_cell in inventory_base_cells():
		active_cells[base_cell] = true
	for pack_module_variant in pack_modules:
		for pack_cell in pack_cells(pack_module_variant):
			active_cells[pack_cell] = true
	return active_cells

func inventory_capacity(pack_modules: Array) -> int:
	return active_inventory_cells_from_packs(pack_modules).size()

func can_place_pack_module(pack_modules: Array, pack_size: Vector2i, anchor: Vector2i, ignore_index: int = -1) -> bool:
	if anchor.x < 0 or anchor.y < 0:
		return false
	if anchor.x + pack_size.x > INVENTORY_CANVAS_SIZE.x or anchor.y + pack_size.y > INVENTORY_CANVAS_SIZE.y:
		return false
	var occupied_cells: Dictionary = {}
	for base_cell in inventory_base_cells():
		occupied_cells[base_cell] = true
	for pack_index in range(pack_modules.size()):
		if pack_index == ignore_index:
			continue
		for pack_cell in pack_cells(pack_modules[pack_index]):
			occupied_cells[pack_cell] = true
	var touches_existing: bool = false
	for offset_y in range(pack_size.y):
		for offset_x in range(pack_size.x):
			var cell: Vector2i = anchor + Vector2i(offset_x, offset_y)
			if occupied_cells.has(cell):
				return false
			for direction in CARDINAL_DIRS:
				if occupied_cells.has(cell + direction):
					touches_existing = true
	if pack_modules.is_empty():
		return touches_existing
	return touches_existing

func item_fits_active_cells(item: Dictionary, active_cells: Dictionary) -> bool:
	for occupied_cell_variant in item_occupied_cells(item):
		var occupied_cell: Vector2i = occupied_cell_variant
		if not active_cells.has(occupied_cell):
			return false
	return true

func find_default_pack_anchor(pack_modules: Array, pack_size: Vector2i) -> Vector2i:
	for anchor_y in range(INVENTORY_CANVAS_SIZE.y - pack_size.y + 1):
		for anchor_x in range(INVENTORY_CANVAS_SIZE.x - pack_size.x + 1):
			var anchor: Vector2i = Vector2i(anchor_x, anchor_y)
			if can_place_pack_module(pack_modules, pack_size, anchor):
				return anchor
	return INVALID_ROOM

func next_level_pack_size(level_value: int) -> Vector2i:
	var sequence_index: int = maxi(level_value - 2, 0) % LEVEL_UP_PACK_SEQUENCE.size()
	return LEVEL_UP_PACK_SEQUENCE[sequence_index]

func hero_level_stat_bonuses(level_value: int) -> Dictionary:
	var earned_levels: int = maxi(level_value - 1, 0)
	return {
		"health": float(earned_levels) * 8.0,
		"attack": float(earned_levels) * 2.0,
		"speed": float(earned_levels) * 10.0,
		"stamina": float(earned_levels) * 0.5,
	}

func hero_spell_slot_capacity(hero: Variant) -> int:
	if hero == null or not is_instance_valid(hero) or not hero_supports_spell_repertoire(hero):
		return 0
	return spell_slot_capacity_for_class_level(String(hero.hero_class_id), int(hero.level))

func hero_spell_slot_counts(hero: Variant) -> Array[int]:
	if hero == null or not is_instance_valid(hero) or not hero_supports_spell_repertoire(hero):
		return []
	return spell_slot_counts_for_class_level(String(hero.hero_class_id), int(hero.level))

func hero_spellbook_overlay_data(hero: Variant) -> Dictionary:
	if hero == null or not is_instance_valid(hero):
		return {
			"enabled": false,
			"known": [],
			"slotted": [],
			"capacity": 0,
		}
	var focus_item_id: String = spell_focus_item_id_for_class(String(hero.hero_class_id))
	return {
		"enabled": hero_supports_spell_repertoire(hero) and hero_has_spell_focus_item(hero),
		"focus_item_id": focus_item_id,
		"title": spell_panel_title_for_class(String(hero.hero_class_id)),
		"known": hero.learned_spells.duplicate(),
		"spells": spell_overlay_entries(hero.learned_spells),
		"slotted": hero.slotted_spells.duplicate(),
		"capacity": hero_spell_slot_capacity(hero),
		"slots_by_level": hero_spell_slot_counts(hero),
		"editable": hero_spell_repertoire_editable(hero),
		"prep_note": "Level %d spells. In the first room, slot edits immediately refresh generated spell cards, but no cards can be played until the first door opens. After that, edits save for next floor only, and existing generated cards stay until played." % hero_max_spell_level_for_class_level(String(hero.hero_class_id), int(hero.level)),
	}

func hero_can_study_spell(hero: Variant, spell_id: String) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hero.hero_class_id != HERO_CLASS_WIZARD or not hero_has_spell_focus_item(hero):
		return false
	if spell_id == "" or hero.learned_spells.has(spell_id):
		return false
	return not wave_in_progress()

func begin_spell_scroll_study(hero: Variant, spell_id: String) -> bool:
	if not hero_can_study_spell(hero, spell_id):
		return false
	hero.studying_spell_id = spell_id
	hero.studying_room = active_hero_room_for_commands(hero)
	hero.studying_started_at_door = doors_opened
	status_message = "%s began studying %s. Stay in the room until the next door opens." % [hero.hero_name, spell_display_name(spell_id)]
	return true

func resolve_spell_scroll_studies() -> void:
	for hero in heroes:
		if hero == null or not is_instance_valid(hero) or hero.studying_spell_id == "":
			continue
		if doors_opened <= hero.studying_started_at_door:
			continue
		var studied_spell_id: String = hero.studying_spell_id
		var study_succeeded: bool = hero.current_room == hero.studying_room and hero.pending_room == INVALID_ROOM and hero.pending_open_room == INVALID_ROOM
		hero.studying_spell_id = ""
		hero.studying_room = INVALID_ROOM
		hero.studying_started_at_door = -1
		if not study_succeeded:
			status_message = "%s lost focus and failed to learn %s." % [hero.hero_name, spell_display_name(studied_spell_id)]
			continue
		if not hero.learned_spells.has(studied_spell_id):
			hero.learned_spells.append(studied_spell_id)
		var prepared_level_index: int = spell_level(studied_spell_id) - 1
		var slot_counts: Array[int] = hero_spell_slot_counts(hero)
		var prepared_count_for_level: int = 0
		for slotted_spell_variant in hero.slotted_spells:
			if spell_level(String(slotted_spell_variant)) == prepared_level_index + 1:
				prepared_count_for_level += 1
		if prepared_level_index >= 0 and prepared_level_index < slot_counts.size() and prepared_count_for_level < int(slot_counts[prepared_level_index]) and not hero.slotted_spells.has(studied_spell_id):
			hero.slotted_spells.append(studied_spell_id)
		sanitize_hero_spellbook(hero)
		apply_inventory_stats_to_hero(hero)
		status_message = "%s learned %s." % [hero.hero_name, spell_display_name(studied_spell_id)]

func advance_spell_scroll_studies() -> void:
	for hero in heroes:
		if hero == null or not is_instance_valid(hero) or hero.studying_spell_id == "":
			continue
		if hero.current_room == hero.studying_room and hero.pending_room == INVALID_ROOM and hero.pending_open_room == INVALID_ROOM:
			continue
		var studied_spell_id: String = hero.studying_spell_id
		hero.studying_spell_id = ""
		hero.studying_room = INVALID_ROOM
		hero.studying_started_at_door = -1
		status_message = "%s interrupted study of %s." % [hero.hero_name, spell_display_name(studied_spell_id)]

func hero_next_level_unlock_names(hero: Variant) -> Array[String]:
	var unlock_names: Array[String] = []
	if hero == null or not is_instance_valid(hero):
		return unlock_names
	var next_level: int = hero.level + 1
	var class_def: Dictionary = hero_class_definition(hero.hero_class_id)
	for passive_unlock_variant in Array(class_def.get("level_passives", [])):
		var passive_unlock: Dictionary = passive_unlock_variant
		if int(passive_unlock.get("level", -1)) != next_level:
			continue
		unlock_names.append(String(passive_unlock.get("name", "Passive")))
	return unlock_names

func build_level_up_reward_lines(hero: Variant) -> Array[String]:
	var reward_lines: Array[String] = []
	if hero == null or not is_instance_valid(hero):
		return reward_lines
	var current_bonus: Dictionary = hero_level_stat_bonuses(hero.level)
	var next_bonus: Dictionary = hero_level_stat_bonuses(hero.level + 1)
	var health_gain: int = int(round(float(next_bonus.get("health", 0.0)) - float(current_bonus.get("health", 0.0))))
	var attack_gain: int = int(round(float(next_bonus.get("attack", 0.0)) - float(current_bonus.get("attack", 0.0))))
	var speed_gain: int = int(round(float(next_bonus.get("speed", 0.0)) - float(current_bonus.get("speed", 0.0))))
	var stamina_gain: float = float(next_bonus.get("stamina", 0.0)) - float(current_bonus.get("stamina", 0.0))
	var next_pack_size: Vector2i = hero_next_pack_size(hero)
	var unlock_names: Array[String] = hero_next_level_unlock_names(hero)
	reward_lines.append("Stats +%d hp  +%d dmg  +%d spd  +%.1f sta" % [health_gain, attack_gain, speed_gain, stamina_gain])
	reward_lines.append("Pack %dx%d inventory module" % [next_pack_size.x, next_pack_size.y])
	if unlock_names.is_empty():
		reward_lines.append("Passive ability: none this level")
	else:
		reward_lines.append("Passive ability: %s" % ", ".join(PackedStringArray(unlock_names)))
	return reward_lines

func level_up_food_cost(level_value: int) -> int:
	return 4 + level_value * 2

func hero_next_pack_size(hero: Variant) -> Vector2i:
	return next_level_pack_size(hero.level + 1)

func hero_can_level_up(hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if food < level_up_food_cost(hero.level):
		return false
	return find_default_pack_anchor(hero.pack_modules, hero_next_pack_size(hero)) != INVALID_ROOM

func grant_level_up_pack_to_hero(hero: Variant) -> bool:
	if not hero_can_level_up(hero):
		return false
	var next_pack_size: Vector2i = hero_next_pack_size(hero)
	var pack_anchor: Vector2i = find_default_pack_anchor(hero.pack_modules, next_pack_size)
	if pack_anchor == INVALID_ROOM:
		return false
	food -= level_up_food_cost(hero.level)
	hero.level += 1
	hero.pack_modules.append({
		"size": next_pack_size,
		"anchor": pack_anchor,
	})
	if hero.hero_index >= 0 and hero.hero_index < hero_profiles.size():
		hero_profiles[hero.hero_index]["level"] = hero.level
		hero_profiles[hero.hero_index]["pack_modules"] = hero.pack_modules.duplicate(true)
	return true

func item_occupied_cells(item: Dictionary) -> Array:
	var occupied_cells: Array = []
	var anchor: Vector2i = item.get("anchor", INVALID_ROOM)
	if anchor == INVALID_ROOM:
		return occupied_cells
	var size_cells: Vector2i = item_size_in_cells(item)
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			occupied_cells.append(anchor + Vector2i(offset_x, offset_y))
	return occupied_cells

func can_place_inventory_item(hero: Variant, item: Dictionary, anchor: Vector2i, ignore_uid: int = -1) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	var size_cells: Vector2i = item_size_in_cells(item)
	if anchor.x < 0 or anchor.y < 0:
		return false
	if anchor.x + size_cells.x > hero.inventory_canvas_size.x or anchor.y + size_cells.y > hero.inventory_canvas_size.y:
		return false
	var active_cells: Dictionary = active_inventory_cells_from_packs(hero.pack_modules)
	var occupied_cells: Dictionary = {}
	for other_item_variant in hero.inventory_items:
		var other_item: Dictionary = other_item_variant
		if int(other_item.get("uid", -1)) == ignore_uid:
			continue
		for occupied_cell_variant in item_occupied_cells(other_item):
			occupied_cells[occupied_cell_variant] = true
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			var cell: Vector2i = anchor + Vector2i(offset_x, offset_y)
			if not active_cells.has(cell) or occupied_cells.has(cell):
				return false
	return true

func find_first_inventory_item_anchor(hero: Variant, item: Dictionary) -> Vector2i:
	if hero == null or not is_instance_valid(hero):
		return INVALID_ROOM
	var size_cells: Vector2i = item_size_in_cells(item)
	for anchor_y in range(hero.inventory_canvas_size.y - size_cells.y + 1):
		for anchor_x in range(hero.inventory_canvas_size.x - size_cells.x + 1):
			var anchor: Vector2i = Vector2i(anchor_x, anchor_y)
			if can_place_inventory_item(hero, item, anchor):
				return anchor
	return INVALID_ROOM

func add_item_to_hero_inventory(hero: Variant, item_variant: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	var item: Dictionary = normalize_item_instance(item_variant)
	item.erase("position")
	var anchor: Vector2i = item.get("anchor", INVALID_ROOM)
	if anchor == INVALID_ROOM or not can_place_inventory_item(hero, item, anchor):
		anchor = find_first_inventory_item_anchor(hero, item)
	if anchor == INVALID_ROOM:
		return false
	item["anchor"] = anchor
	hero.inventory_items.append(item)
	apply_inventory_stats_to_hero(hero)
	return true

func item_has_tag(item: Dictionary, tag_name: String) -> bool:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	return Array(item_def.get("tags", [])).has(tag_name)

func item_instance_enabled(item: Dictionary) -> bool:
	return true

func rotated_socket_offset(item: Dictionary, socket_offset: Vector2i) -> Vector2i:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	if not bool(item.get("rotated", false)):
		return socket_offset
	return Vector2i(base_size.y - 1 - socket_offset.y, socket_offset.x)

func socket_match_entries(socket_rule: Dictionary) -> Array:
	if socket_rule.has("matches"):
		return Array(socket_rule.get("matches", []))
	if socket_rule.has("tag"):
		return [{
			"tag": String(socket_rule.get("tag", "")),
			"bonuses": Dictionary(socket_rule.get("bonuses", {})),
		}]
	return []

func card_definition(card_id: String) -> Dictionary:
	match card_id:
		"fireball_card":
			return {
				"id": "fireball_card",
				"name": "Fireball",
				"spell_class": HERO_CLASS_WIZARD,
				"spell_level": 3,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Can cast into adjacent rooms", "Generated once per floor"],
				"stamina_cost": 2.0,
				"base_damage": 42.0,
				"impact_radius": 92.0,
				"radius": 12.0,
				"speed": 880.0,
				"cast_adjacent_hops": 1,
				"color": Color("ff9a5e"),
			}
		"magic_missile_card":
			return {
				"id": "magic_missile_card",
				"name": "Magic Missile",
				"spell_class": HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Launches three seeking missiles", "Generated once per floor from a slotted spell"],
				"stamina_cost": 1.0,
				"base_damage": 14.0,
				"projectile_count": 3,
				"cast_adjacent_hops": 1,
				"color": Color("9cd7ff"),
			}
		"light_cantrip_card":
			return {
				"id": "light_cantrip_card",
				"name": "Light",
				"spell_class": HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "same_room",
				"phase": "out_of_combat",
				"description_lines": ["Wizard cantrip", "Lights the wizard's current room", "Light follows the wizard until recast or the floor ends"],
				"stamina_cost": 0.0,
				"color": Color("fff1a8"),
				"reusable": true,
			}
		"misty_step_card":
			return {
				"id": "misty_step_card",
				"name": "Misty Step",
				"spell_class": HERO_CLASS_WIZARD,
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "any",
				"description_lines": ["Teleport to a seen point", "Can hop into an adjacent room through a doorway", "Generated once per floor from a slotted spell"],
				"stamina_cost": 0.0,
				"cast_adjacent_hops": 1,
				"color": Color("b89cff"),
			}
		"shield_card":
			return {
				"id": "shield_card",
				"name": "Shield",
				"spell_class": HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-casts on a fatal hit", "Grants 6 seconds of immunity", "Generated once per floor from a slotted spell"],
				"stamina_cost": 1.0,
				"shield_amount": 0.0,
				"shield_duration": 0.0,
				"immunity_duration": 6.0,
				"auto_cast_on_fatal": true,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"color": Color("9fc8ff"),
			}
		"lightning_bolt_card":
			return {
				"id": "lightning_bolt_card",
				"name": "Lightning Bolt",
				"spell_class": HERO_CLASS_WIZARD,
				"spell_level": 3,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Strike a line through one room or doorway", "Generated once per floor from a slotted spell"],
				"stamina_cost": 2.0,
				"base_damage": 30.0,
				"impact_radius": 18.0,
				"cast_adjacent_hops": 1,
				"color": Color("8bd9ff"),
			}
		"lantern_torch_card":
			return {
				"id": "lantern_torch_card",
				"name": "Lamp Oil",
				"target_scope": "hero",
				"phase": "out_of_combat",
				"description_lines": ["Create one torch in a hero backpack", "Consumes 1 lantern charge"],
				"door_interval": 1,
				"color": Color("ffe38a"),
			}
		"torch_card":
			return {
				"id": "torch_card",
				"name": "Torch",
				"target_scope": "opened_room",
				"phase": "out_of_combat",
				"description_lines": ["Light one opened room", "Lasts through the next combat wave"],
				"door_interval": 2,
				"color": Color("ffe38a"),
			}
		"cure_light_wounds_card":
			return {
				"id": "cure_light_wounds_card",
				"name": "Cure Light Wounds",
				"spell_class": HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "hero",
				"phase": "combat",
				"description_lines": ["Restore 36 health to one hero", "Generated once per floor from a prepared prayer"],
				"heal_amount": 36.0,
				"color": Color("c3ffb3"),
			}
		"sanctuary_card":
			return {
				"id": "sanctuary_card",
				"name": "Sanctuary",
				"spell_class": HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Gain a brief divine ward", "Generated once per floor from a prepared prayer"],
				"stamina_cost": 1.0,
				"shield_amount": 24.0,
				"shield_duration": 8.0,
				"color": Color("e3ff9f"),
			}
		"mend_card":
			return {
				"id": "mend_card",
				"name": "Mend",
				"target_scope": "hero",
				"phase": "combat",
				"description_lines": ["Large combat heal", "Restore 60 health to one hero"],
				"heal_amount": 60.0,
				"door_interval": 3,
				"color": Color("ff9b9b"),
			}
		"emergency_snack_card":
			return {
				"id": "emergency_snack_card",
				"name": "Emergency Snack",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Spend party food to fully patch up", "Combat only, expires on the next door"],
				"food_cost": HEAL_FOOD_COST,
				"heal_full": true,
				"restore_stamina_full": true,
				"expires_after_turns": 1,
				"reaction_trigger": "stamina_negative",
				"reaction_default_enabled": true,
				"color": Color("ffd79c"),
			}
		"ration_meal_card":
			return {
				"id": "ration_meal_card",
				"name": "Eat Ration",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Combat heal plus stamina restore", "Also grants minor combat stamina regen"],
				"heal_amount": 24.0,
				"stamina_restore": 2.0,
				"stamina_regen_rate": 0.45,
				"stamina_regen_duration": 7.0,
				"door_interval": 2,
				"reaction_trigger": "stamina_negative",
				"reaction_default_enabled": true,
				"color": Color("d7f09f"),
			}
		"dagger_card":
			return {
				"id": "dagger_card",
				"name": "Dagger Fan",
				"target_scope": "same_room",
				"stamina_cost": 1.0,
				"base_damage": 10.0,
				"projectile_count": 3,
				"spread": 0.16,
				"speed": 1020.0,
				"bounces": 1,
				"lifetime": 1.45,
				"color": Color("d7f0ff"),
				"backstab_multiplier": 1.75,
				"combo_gain": 1,
				"test_cooldown": 1.35,
			}
		_:
			return {
				"id": "axe_card",
				"name": "Whirling Axe",
				"target_scope": "same_room",
				"stamina_cost": 2.0,
				"base_damage": 20.0,
				"speed": 760.0,
				"bounces": 2,
				"lifetime": 2.2,
				"color": Color("ffd27a"),
				"radius": 17.0,
				"test_cooldown": 1.8,
			}

func card_target_scope_label(target_scope: String) -> String:
	match target_scope:
		"same_hero":
			return "Self"
		"same_room", "hero_room":
			return "Room"
		"hero":
			return "Hero"
		"opened_room":
			return "Open"
		"global":
			return "Global"
		_:
			return "Free"

func hero_builtin_card_generators(hero: Variant) -> Array:
	if hero == null or not is_instance_valid(hero):
		return []
	var generators: Array = [{
		"card_id": "emergency_snack_card",
		"door_interval": 1,
		"generation_mode": "door_interval",
		"initial_queued_cards": 1,
		"max_stored_cards": 1,
		"source_type": "hero_builtin",
		"hero_index": hero.hero_index,
		"generator_key": "hero:%d:emergency_snack_card" % hero.hero_index,
	}]
	if hero.hero_class_id == HERO_CLASS_WIZARD:
		generators.append({
			"card_id": "light_cantrip_card",
			"generation_mode": "single",
			"max_stored_cards": 1,
			"source_type": "hero_builtin",
			"hero_index": hero.hero_index,
			"generator_key": "hero:%d:light_cantrip_card" % hero.hero_index,
			"persistent_card": true,
		})
	return generators

func spellbook_card_generators(hero: Variant, effect_summary: Dictionary) -> Array:
	var generators: Array = []
	if hero == null or not is_instance_valid(hero) or not hero_supports_spell_repertoire(hero):
		return generators
	var focus_item_uid: int = spell_focus_item_uid_for_hero(hero)
	var focus_item_id: String = spell_focus_item_id_for_class(String(hero.hero_class_id))
	if focus_item_uid < 0 or focus_item_id == "":
		return generators
	for spell_index in range(hero.active_floor_spells.size()):
		var spell_id: String = String(hero.active_floor_spells[spell_index])
		if spell_id == "" or not hero_can_prepare_spell(hero, spell_id):
			continue
		generators.append({
			"card_id": spell_id,
			"item_uid": focus_item_uid,
			"item_id": focus_item_id,
			"item_bonus": Dictionary(effect_summary.get("item_bonus_by_uid", {}).get(focus_item_uid, empty_inventory_effect_summary())).duplicate(true),
			"generation_mode": "floor_once",
			"max_stored_cards": 1,
			"generator_key": "spellbook:%d:%d:%s" % [hero.hero_index, spell_index, spell_id],
		})
	return generators

func empty_inventory_effect_summary() -> Dictionary:
	return {
		"speed": 0.0,
		"health": 0.0,
		"attack": 0.0,
		"stamina": 0.0,
		"hand_size": 0,
		"card_damage": 0.0,
		"projectile_count": 0,
		"dagger_backstab_bonus": 0.0,
		"card_charge_mult": 1.0,
		"stamina_cost_mult": 1.0,
		"synergies": 0,
		"card_generators": [],
		"combat_passives": [],
		"item_bonus_by_uid": {},
	}

func apply_inventory_effect_bonuses(target: Dictionary, bonus_stats: Dictionary) -> void:
	for bonus_key_variant in bonus_stats.keys():
		var bonus_key: String = String(bonus_key_variant)
		match bonus_key:
			"hand_size", "projectile_count":
				target[bonus_key] = int(target.get(bonus_key, 0)) + int(bonus_stats[bonus_key_variant])
			"card_charge_mult", "stamina_cost_mult":
				target[bonus_key] = float(target.get(bonus_key, 1.0)) * float(bonus_stats[bonus_key_variant])
			_:
				target[bonus_key] = float(target.get(bonus_key, 0.0)) + float(bonus_stats[bonus_key_variant])

func inventory_effect_summary(items: Array) -> Dictionary:
	var summary: Dictionary = empty_inventory_effect_summary()
	var move_bonus: float = 0.0
	var health_bonus: float = 0.0
	var attack_bonus: float = 0.0
	for item_variant in items:
		var item: Dictionary = item_variant
		if not item_instance_enabled(item):
			continue
		var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
		var direct_stats: Dictionary = item_def.get("stats", {})
		apply_inventory_effect_bonuses(summary, direct_stats)
		move_bonus += float(direct_stats.get("speed", 0.0))
		health_bonus += float(direct_stats.get("health", 0.0))
		attack_bonus += float(direct_stats.get("attack", 0.0))
	var cell_to_item: Dictionary = {}
	for item_index in range(items.size()):
		if not item_instance_enabled(items[item_index]):
			continue
		for cell in item_occupied_cells(items[item_index]):
			cell_to_item[cell] = item_index
	for item_index in range(items.size()):
		var item: Dictionary = items[item_index]
		if not item_instance_enabled(item):
			continue
		var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
		var item_uid: int = int(item.get("uid", -1))
		var item_bonus: Dictionary = empty_inventory_effect_summary()
		var socket_rules: Array = Array(item_def.get("synergy_sockets", []))
		var item_anchor: Vector2i = item.get("anchor", INVALID_ROOM)
		if item_anchor != INVALID_ROOM:
			for socket_variant in socket_rules:
				var socket_rule: Dictionary = socket_variant
				var target_cell: Vector2i = item_anchor + rotated_socket_offset(item, Vector2i(socket_rule.get("offset", Vector2i.ZERO)))
				var neighbor_index_variant: Variant = cell_to_item.get(target_cell, null)
				if neighbor_index_variant == null or int(neighbor_index_variant) == item_index:
					continue
				var neighbor_item: Dictionary = items[int(neighbor_index_variant)]
				for match_variant in socket_match_entries(socket_rule):
					var match_rule: Dictionary = match_variant as Dictionary
					if not item_has_tag(neighbor_item, String(match_rule.get("tag", ""))):
						continue
					var socket_bonus: Dictionary = Dictionary(match_rule.get("bonuses", {}))
					apply_inventory_effect_bonuses(summary, socket_bonus)
					apply_inventory_effect_bonuses(item_bonus, socket_bonus)
					summary["synergies"] = int(summary.get("synergies", 0)) + 1
					break
		if item_uid >= 0:
			summary["item_bonus_by_uid"][item_uid] = item_bonus
	for item_variant in items:
		var item_with_card: Dictionary = item_variant
		if not item_instance_enabled(item_with_card):
			continue
		var item_def_card: Dictionary = item_defs.get(String(item_with_card.get("item_id", "")), {})
		var item_uid_card: int = int(item_with_card.get("uid", -1))
		var card_generators: Array = []
		if item_def_card.has("hand_cards"):
			card_generators = Array(item_def_card.get("hand_cards", [])).duplicate(true)
		else:
			var single_generator: Dictionary = Dictionary(item_def_card.get("hand_card", item_def_card.get("combat_card", {})))
			if not single_generator.is_empty():
				card_generators.append(single_generator)
		for card_generator_variant in card_generators:
			var card_generator: Dictionary = Dictionary(card_generator_variant).duplicate(true)
			card_generator["item_uid"] = item_uid_card
			card_generator["item_id"] = String(item_with_card.get("item_id", ""))
			card_generator["item_bonus"] = Dictionary(summary.get("item_bonus_by_uid", {}).get(item_uid_card, empty_inventory_effect_summary())).duplicate(true)
			summary["card_generators"].append(card_generator)
		var combat_passive: Dictionary = Dictionary(item_def_card.get("passive_combat_ability", {}))
		if not combat_passive.is_empty():
			combat_passive["item_uid"] = item_uid_card
			combat_passive["item_id"] = String(item_with_card.get("item_id", ""))
			combat_passive["item_bonus"] = Dictionary(summary.get("item_bonus_by_uid", {}).get(item_uid_card, empty_inventory_effect_summary())).duplicate(true)
			summary["combat_passives"].append(combat_passive)
	summary["speed"] = move_bonus + float(summary.get("speed", 0.0)) - move_bonus
	summary["health"] = health_bonus + float(summary.get("health", 0.0)) - health_bonus
	summary["attack"] = attack_bonus + float(summary.get("attack", 0.0)) - attack_bonus
	return summary

func inventory_bonus_summary(items: Array) -> Dictionary:
	return inventory_effect_summary(items)

func build_inventory_stat_lines(hero: Variant, items: Array) -> Array[String]:
	var bonuses: Dictionary = inventory_effect_summary(items)
	var level_bonuses: Dictionary = hero_level_stat_bonuses(hero.level)
	var used_cells: int = 0
	for item_variant in items:
		used_cells += item_occupied_cells(item_variant).size()
	var stat_lines: Array[String] = []
	stat_lines.append("Damage %d" % int(round(hero.base_attack_damage + float(level_bonuses.get("attack", 0.0)) + float(bonuses["attack"]))))
	stat_lines.append("Health %d" % int(round(hero.base_max_health + float(level_bonuses.get("health", 0.0)) + float(bonuses["health"]))))
	stat_lines.append("Speed %d" % int(round(hero.base_move_speed + float(level_bonuses.get("speed", 0.0)) + float(bonuses["speed"]))))
	stat_lines.append("Stamina %d" % int(round(hero.base_max_stamina + float(level_bonuses.get("stamina", 0.0)) + float(bonuses.get("stamina", 0.0)))))
	stat_lines.append("Hand %d" % maxi(1, hero.base_max_hand_size + int(bonuses.get("hand_size", 0))))
	stat_lines.append("Synergies %d" % int(bonuses["synergies"]))
	stat_lines.append("Space %d/%d" % [used_cells, inventory_capacity(hero.pack_modules)])
	return stat_lines

func format_ability_metric(value: float) -> String:
	if absf(value - round(value)) <= 0.05:
		return str(int(round(value)))
	return "%.1f" % value

func ability_detail_text(cooldown: float, power_text: String, stamina_cost: float, extra_text: String = "") -> String:
	var detail: String = "CD %ss  Pow %s  Sta %s" % [format_ability_metric(cooldown), power_text, format_ability_metric(stamina_cost)]
	if extra_text != "":
		detail += "  %s" % extra_text
	return detail

func ability_power_text(card_id: String, payload: Dictionary) -> String:
	match card_id:
		"dagger_card":
			return "%sx%d" % [format_ability_metric(float(payload.get("damage", 0.0))), maxi(1, int(payload.get("projectile_count", 1)))]
		"axe_card":
			return format_ability_metric(float(payload.get("damage", 0.0)))
		_:
			return format_ability_metric(float(payload.get("damage", 0.0)))

func build_inventory_ability_sections(hero: Variant) -> Array:
	var sections: Array = []
	if hero == null or not is_instance_valid(hero):
		return sections
	var class_def: Dictionary = hero_class_definition(hero.hero_class_id)
	var basic_attack_detail: String = ability_detail_text(hero.attack_cooldown, format_ability_metric(hero.attack_damage), 0.0, "%s %d rng" % ["Melee" if String(class_def.get("attack_style", hero.preferred_attack_style)) == "melee" else "Ranged", int(round(hero.attack_range))])
	sections.append({
		"title": "Current",
		"entries": [{
			"name": "Basic Attack",
			"detail": basic_attack_detail,
		}],
	})
	var effect_summary: Dictionary = inventory_effect_summary(hero.inventory_items)
	var gear_entries: Array = []
	for passive_variant in Array(effect_summary.get("combat_passives", [])):
		var passive_ability: Dictionary = passive_variant
		var item_id: String = String(passive_ability.get("item_id", ""))
		var item_def: Dictionary = item_defs.get(item_id, {})
		var item_bonus: Dictionary = Dictionary(passive_ability.get("item_bonus", {}))
		var card_def: Dictionary = card_definition(String(passive_ability.get("card_id", "")))
		var base_cooldown: float = float(passive_ability.get("cooldown", card_def.get("test_cooldown", 1.5)))
		var effective_cooldown: float = maxf(base_cooldown * float(item_bonus.get("card_charge_mult", 1.0)), 0.25)
		var passive_payload: Dictionary = build_passive_combat_payload(passive_ability, effect_summary)
		gear_entries.append({
			"name": "%s: %s" % [String(item_def.get("name", item_id.capitalize())), String(card_def.get("name", "Passive"))],
			"detail": ability_detail_text(effective_cooldown, ability_power_text(String(card_def.get("id", "")), passive_payload), float(passive_payload.get("stamina_cost", 0.0))),
		})
	if not gear_entries.is_empty():
		sections.append({
			"title": "Gear Passives",
			"entries": gear_entries,
		})
	var level_entries: Array = []
	for passive_unlock_variant in Array(class_def.get("level_passives", [])):
		var passive_unlock: Dictionary = passive_unlock_variant
		var passive_detail: String = String(passive_unlock.get("detail", passive_unlock.get("description", "Locked")))
		level_entries.append({
			"level": int(passive_unlock.get("level", -1)),
			"name": String(passive_unlock.get("name", "Passive")),
			"detail": passive_detail,
		})
	if not level_entries.is_empty():
		level_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("level", 0)) < int(b.get("level", 0))
		)
		sections.append({
			"title": "Level Path",
			"entries": level_entries,
		})
	return sections

func apply_inventory_stats_to_hero(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var normalized_items: Array = []
	for item_variant in hero.inventory_items:
		normalized_items.append(normalize_item_instance(item_variant))
	hero.inventory_items = normalized_items
	sanitize_hero_spellbook(hero)
	var bonuses: Dictionary = inventory_effect_summary(hero.inventory_items)
	var level_bonuses: Dictionary = hero_level_stat_bonuses(hero.level)
	hero.apply_inventory_stats(
		float(level_bonuses.get("speed", 0.0)) + float(bonuses["speed"]),
		float(level_bonuses.get("health", 0.0)) + float(bonuses["health"]),
		float(level_bonuses.get("attack", 0.0)) + float(bonuses["attack"]),
		float(level_bonuses.get("stamina", 0.0)) + float(bonuses.get("stamina", 0.0)),
		int(bonuses.get("hand_size", 0)),
		int(bonuses["synergies"])
	)
	sync_hero_card_sources(hero, bonuses)
	sync_hero_passive_combat_sources(hero, bonuses)
	if hero.hero_index >= 0 and hero.hero_index < hero_profiles.size():
		hero_profiles[hero.hero_index]["level"] = hero.level
		hero_profiles[hero.hero_index]["pack_modules"] = hero.pack_modules.duplicate(true)
		hero_profiles[hero.hero_index]["inventory_items"] = hero.inventory_items.duplicate(true)
		hero_profiles[hero.hero_index]["learned_spells"] = hero.learned_spells.duplicate()
		hero_profiles[hero.hero_index]["slotted_spells"] = hero.slotted_spells.duplicate()

func card_generator_key(item_uid: int, card_id: String) -> String:
	return "%d:%s" % [item_uid, card_id]

func combat_passive_key(item_uid: int, card_id: String) -> String:
	return "passive:%d:%s" % [item_uid, card_id]

func collect_world_item_uids() -> Dictionary:
	var known_item_uids: Dictionary = {}
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		for item_variant in hero.inventory_items:
			known_item_uids[int((item_variant as Dictionary).get("uid", -1))] = true
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		for ground_item_variant in rooms[room_coord]["ground_items"]:
			known_item_uids[int((ground_item_variant as Dictionary).get("uid", -1))] = true
	return known_item_uids

func hero_has_hand_card_for_generator_key(generator_key: String) -> bool:
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		for hand_card_variant in hero.hand_cards:
			var hand_card: Dictionary = hand_card_variant
			var hand_key: String = String(hand_card.get("generator_key", card_generator_key(int(hand_card.get("item_uid", -1)), String(hand_card.get("card_id", "")))))
			if hand_key == generator_key:
				return true
	return false

func hero_hand_card_count_for_generator_key(hero: Variant, generator_key: String) -> int:
	if hero == null or not is_instance_valid(hero):
		return 0
	var count: int = 0
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = hand_card_variant
		var hand_key: String = String(hand_card.get("generator_key", card_generator_key(int(hand_card.get("item_uid", -1)), String(hand_card.get("card_id", "")))))
		if hand_key == generator_key:
			count += 1
	return count

func cleanup_global_item_card_states() -> void:
	var known_item_uids: Dictionary = collect_world_item_uids()
	var stale_timer_keys: Array = []
	for timer_key_variant in global_item_card_states.keys():
		var timer_key: String = String(timer_key_variant)
		var state: Dictionary = Dictionary(global_item_card_states.get(timer_key, {}))
		var item_uid: int = int(state.get("item_uid", -1))
		var queued_cards: int = int(state.get("queued_cards", 0))
		if known_item_uids.has(item_uid) or queued_cards > 0 or hero_has_hand_card_for_generator_key(timer_key):
			continue
		stale_timer_keys.append(timer_key)
	for stale_key_variant in stale_timer_keys:
		global_item_card_states.erase(String(stale_key_variant))

func mark_orphaned_card_states_for_item(item_uid: int) -> void:
	for timer_key_variant in global_item_card_states.keys():
		var timer_key: String = String(timer_key_variant)
		var state: Dictionary = Dictionary(global_item_card_states.get(timer_key, {})).duplicate(true)
		if int(state.get("item_uid", -1)) != item_uid:
			continue
		state["allow_orphaned_cards"] = true
		global_item_card_states[timer_key] = state

func remove_item_by_uid_from_world(item_uid: int) -> void:
	if item_uid < 0:
		return
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		var filtered_items: Array = []
		var removed_any: bool = false
		for item_variant in hero.inventory_items:
			var item: Dictionary = item_variant
			if int(item.get("uid", -1)) == item_uid:
				removed_any = true
				continue
			filtered_items.append(item.duplicate(true))
		if removed_any:
			hero.inventory_items = filtered_items
			apply_inventory_stats_to_hero(hero)
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var filtered_ground_items: Array = []
		var removed_ground: bool = false
		for ground_item_variant in rooms[room_coord]["ground_items"]:
			var ground_item: Dictionary = ground_item_variant
			if int(ground_item.get("uid", -1)) == item_uid:
				removed_ground = true
				continue
			filtered_ground_items.append(ground_item.duplicate(true))
		if removed_ground:
			rooms[room_coord]["ground_items"] = prepare_ground_items_for_room(room_coord, filtered_ground_items)

func consume_item_charges_by_uid(item_uid: int, amount: int, orphan_generated_cards_on_break: bool = false) -> bool:
	if item_uid < 0 or amount <= 0:
		return false
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		for item_index in range(hero.inventory_items.size()):
			var item: Dictionary = normalize_item_instance(hero.inventory_items[item_index])
			if int(item.get("uid", -1)) != item_uid:
				continue
			if not item.has("charges_left"):
				return false
			item["charges_left"] = int(item.get("charges_left", 0)) - amount
			if int(item.get("charges_left", 0)) <= 0:
				if orphan_generated_cards_on_break:
					mark_orphaned_card_states_for_item(item_uid)
				remove_item_by_uid_from_world(item_uid)
			else:
				hero.inventory_items[item_index] = item
				apply_inventory_stats_to_hero(hero)
			return true
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		for item_index in range(rooms[room_coord]["ground_items"].size()):
			var ground_item: Dictionary = normalize_item_instance(rooms[room_coord]["ground_items"][item_index])
			if int(ground_item.get("uid", -1)) != item_uid:
				continue
			if not ground_item.has("charges_left"):
				return false
			ground_item["charges_left"] = int(ground_item.get("charges_left", 0)) - amount
			if int(ground_item.get("charges_left", 0)) <= 0:
				if orphan_generated_cards_on_break:
					mark_orphaned_card_states_for_item(item_uid)
				remove_item_by_uid_from_world(item_uid)
			else:
				rooms[room_coord]["ground_items"][item_index] = ground_item
			return true
	return false

func hero_emits_room_light(hero: Variant) -> bool:
	return hero != null and is_instance_valid(hero) and hero.current_health > 0.0 and bool(hero.light_cantrip_active)

func room_has_wave_torch_light(room: Dictionary) -> bool:
	var expiry_wave: int = int(room.get("wave_torch_until_wave", -1))
	if expiry_wave < 0:
		return false
	if wave_index < expiry_wave:
		return true
	return wave_index == expiry_wave and wave_in_progress()

func refresh_room_lighting_states() -> void:
	var changed: bool = false
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		var previous_lit: bool = bool(room.get("lit", false))
		var lit: bool = bool(room.get("crystal", false)) or bool(room.get("permanent_light", false)) or int(room.get("temporary_light_turns", 0)) > 0 or room_has_wave_torch_light(room)
		if not lit:
			for hero in heroes:
				if not hero_emits_room_light(hero):
					continue
				if hero.current_room == room_coord and room_rect(room_coord).has_point(hero.global_position):
					lit = true
					break
		room["lit"] = lit
		if previous_lit != lit:
			changed = true
	if changed:
		invalidate_static_dungeon_layer()

func apply_temporary_light_to_room(room_coord: Vector2i, turn_count: int) -> bool:
	if turn_count <= 0 or not rooms.has(room_coord):
		return false
	var room: Dictionary = rooms[room_coord]
	room["temporary_light_turns"] = maxi(int(room.get("temporary_light_turns", 0)), turn_count)
	refresh_room_lighting_states()
	return true

func apply_wave_torch_light_to_room(room_coord: Vector2i) -> bool:
	if not rooms.has(room_coord):
		return false
	var room: Dictionary = rooms[room_coord]
	room["wave_torch_until_wave"] = maxi(int(room.get("wave_torch_until_wave", -1)), wave_index + 1)
	refresh_room_lighting_states()
	return true

func apply_portable_item_effects_on_door_open() -> void:
	return

func resolve_card_generator_mode(generator: Dictionary, card_def: Dictionary = {}) -> String:
	var resolved_card_def: Dictionary = card_def
	if resolved_card_def.is_empty():
		resolved_card_def = card_definition(String(generator.get("card_id", "")))
	var generation_mode: String = String(generator.get("generation_mode", resolved_card_def.get("generation_mode", "")))
	if generation_mode != "":
		return generation_mode
	var base_interval: int = int(resolved_card_def.get("door_interval", int(generator.get("door_interval", 0))))
	return "door_interval" if base_interval > 0 else "single"

func generator_max_stored_cards(generator: Dictionary, card_def: Dictionary = {}) -> int:
	var resolved_card_def: Dictionary = card_def
	if resolved_card_def.is_empty():
		resolved_card_def = card_definition(String(generator.get("card_id", "")))
	return int(generator.get("max_stored_cards", resolved_card_def.get("max_stored_cards", 1)))

func resolve_generator_key(generator: Dictionary, card_def: Dictionary = {}) -> String:
	var resolved_card_def: Dictionary = card_def
	if resolved_card_def.is_empty():
		resolved_card_def = card_definition(String(generator.get("card_id", "")))
	return String(generator.get("generator_key", card_generator_key(int(generator.get("item_uid", -1)), String(resolved_card_def.get("id", "")))))

func build_hand_card_from_generator(hero: Variant, generator: Dictionary, effect_summary: Dictionary) -> Dictionary:
	var card_def: Dictionary = card_definition(String(generator.get("card_id", "")))
	var item_bonus: Dictionary = Dictionary(generator.get("item_bonus", empty_inventory_effect_summary()))
	var phase: String = String(generator.get("phase_override", card_def.get("phase", "combat")))
	var target_scope: String = String(generator.get("target_scope_override", card_def.get("target_scope", "same_room")))
	var expires_after_turns: int = int(card_def.get("expires_after_turns", int(generator.get("expires_after_turns", 0))))
	var base_stamina_cost: float = float(card_def.get("stamina_cost", 0.0))
	var description_lines: Array = Array(generator.get("description_lines_override", card_def.get("description_lines", [])))
	var hand_card: Dictionary = {
		"uid": next_card_uid,
		"card_id": String(card_def.get("id", "")),
		"name": String(generator.get("name_override", card_def.get("name", "Card"))),
		"item_uid": int(generator.get("item_uid", -1)),
		"item_id": String(generator.get("item_id", "")),
		"source_type": String(generator.get("source_type", "item")),
		"source_hero_index": int(generator.get("hero_index", hero.hero_index)),
		"phase": phase,
		"target_scope": target_scope,
		"target_scope_label": card_target_scope_label(target_scope),
		"description_lines": description_lines,
		"door_interval": int(card_def.get("door_interval", int(generator.get("door_interval", 0)))),
		"generation_mode": resolve_card_generator_mode(generator, card_def),
		"stamina_cost": maxf(base_stamina_cost * float(effect_summary.get("stamina_cost_mult", 1.0)), 0.0),
		"requires_line_of_effect": bool(card_def.get("requires_line_of_effect", false)),
		"damage": float(card_def.get("base_damage", 0.0)) + float(item_bonus.get("card_damage", 0.0)),
		"projectile_count": int(card_def.get("projectile_count", 1)) + int(item_bonus.get("projectile_count", 0)),
		"spread": float(card_def.get("spread", 0.0)),
		"speed": float(card_def.get("speed", 900.0)),
		"bounces": int(card_def.get("bounces", 0)),
		"lifetime": float(card_def.get("lifetime", 1.5)),
		"radius": float(card_def.get("radius", 12.0)),
		"impact_radius": float(card_def.get("impact_radius", card_def.get("radius", 12.0))),
		"shield_amount": float(card_def.get("shield_amount", 0.0)),
		"shield_duration": float(card_def.get("shield_duration", 0.0)),
		"immunity_duration": float(card_def.get("immunity_duration", 0.0)),
		"cast_adjacent_hops": int(card_def.get("cast_adjacent_hops", 0)),
		"color": card_def.get("color", Color("d7efff")),
		"backstab_multiplier": float(card_def.get("backstab_multiplier", 1.0)) + float(item_bonus.get("dagger_backstab_bonus", 0.0)),
		"combo_gain": int(card_def.get("combo_gain", 0)),
		"heal_amount": float(card_def.get("heal_amount", 0.0)),
		"heal_full": bool(card_def.get("heal_full", false)),
		"restore_stamina_full": bool(card_def.get("restore_stamina_full", false)),
		"stamina_restore": float(card_def.get("stamina_restore", 0.0)),
		"stamina_regen_rate": float(card_def.get("stamina_regen_rate", 0.0)),
		"stamina_regen_duration": float(card_def.get("stamina_regen_duration", 0.0)),
		"food_cost": int(card_def.get("food_cost", 0)),
		"expires_on_doors_opened": doors_opened + expires_after_turns if expires_after_turns > 0 else -1,
		"hero_index": hero.hero_index,
		"max_stored_cards": generator_max_stored_cards(generator, card_def),
		"reusable": bool(card_def.get("reusable", false)),
		"generator_key": resolve_generator_key(generator, card_def),
		"consume_item_on_play": bool(generator.get("consume_item_on_play", false)),
		"consume_item_charges_on_play": int(generator.get("consume_item_charges_on_play", 0)),
		"learnable_spell_scroll": bool(generator.get("learnable_spell_scroll", false)),
		"learn_spell_id": String(generator.get("learn_spell_id", card_def.get("id", ""))),
		"reaction_trigger": String(card_def.get("reaction_trigger", "")),
		"reaction_enabled": bool(card_def.get("reaction_default_enabled", false)),
		"auto_cast_on_fatal": bool(card_def.get("auto_cast_on_fatal", false)),
	}
	next_card_uid += 1
	return hand_card

func build_passive_combat_payload(passive_ability: Dictionary, effect_summary: Dictionary) -> Dictionary:
	var card_def: Dictionary = card_definition(String(passive_ability.get("card_id", "")))
	var item_bonus: Dictionary = Dictionary(passive_ability.get("item_bonus", empty_inventory_effect_summary()))
	return {
		"card_id": String(card_def.get("id", "")),
		"stamina_cost": maxf(float(card_def.get("stamina_cost", 0.0)) * float(effect_summary.get("stamina_cost_mult", 1.0)), 0.0),
		"damage": float(card_def.get("base_damage", 0.0)) + float(item_bonus.get("card_damage", 0.0)),
		"projectile_count": int(card_def.get("projectile_count", 1)) + int(item_bonus.get("projectile_count", 0)),
		"spread": float(card_def.get("spread", 0.0)),
		"speed": float(card_def.get("speed", 900.0)),
		"bounces": int(card_def.get("bounces", 0)),
		"lifetime": float(card_def.get("lifetime", 1.5)),
		"radius": float(card_def.get("radius", 12.0)),
		"color": card_def.get("color", Color("d7efff")),
		"backstab_multiplier": float(card_def.get("backstab_multiplier", 1.0)) + float(item_bonus.get("dagger_backstab_bonus", 0.0)),
		"combo_gain": int(card_def.get("combo_gain", 0)),
	}

func sync_hero_builtin_card_sources(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var builtin_generators: Array = hero_builtin_card_generators(hero)
	var valid_keys: Dictionary = {}
	for generator_variant in builtin_generators:
		var generator: Dictionary = Dictionary(generator_variant).duplicate(true)
		var generator_key: String = String(generator.get("generator_key", "hero:%d:%s" % [hero.hero_index, String(generator.get("card_id", ""))]))
		valid_keys[generator_key] = true
		var card_def: Dictionary = card_definition(String(generator.get("card_id", "")))
		var effective_interval: int = maxi(1, int(card_def.get("door_interval", int(generator.get("door_interval", 1)))))
		var persistent_card: bool = bool(generator.get("persistent_card", false))
		var initial_queued_cards: int = maxi(0, int(generator.get("initial_queued_cards", 0)))
		var max_stored_cards: int = generator_max_stored_cards(generator, card_def)
		var current_stored_cards: int = hero_hand_card_count_for_generator_key(hero, generator_key)
		if not hero.card_generation_timers.has(generator_key):
			var starting_queued_cards: int = 0
			if persistent_card:
				starting_queued_cards = 1
			starting_queued_cards = maxi(starting_queued_cards, initial_queued_cards)
			if max_stored_cards > 0:
				starting_queued_cards = mini(starting_queued_cards, maxi(0, max_stored_cards - current_stored_cards))
			hero.card_generation_timers[generator_key] = {
				"generator": generator,
				"interval": effective_interval,
				"remaining_doors": effective_interval,
				"queued_cards": starting_queued_cards,
			}
			continue
		var state: Dictionary = Dictionary(hero.card_generation_timers.get(generator_key, {})).duplicate(true)
		state["generator"] = generator
		state["interval"] = effective_interval
		state["remaining_doors"] = clampi(int(state.get("remaining_doors", effective_interval)), 1, effective_interval)
		hero.card_generation_timers[generator_key] = state
	var stale_keys: Array = []
	for timer_key_variant in hero.card_generation_timers.keys():
		var timer_key: String = String(timer_key_variant)
		if not valid_keys.has(timer_key):
			stale_keys.append(timer_key)
	for stale_key_variant in stale_keys:
		hero.card_generation_timers.erase(String(stale_key_variant))

func fill_queued_hero_builtin_cards(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero) or hero.hand_cards.size() >= hero.max_hand_size:
		return
	sync_hero_builtin_card_sources(hero)
	for timer_key_variant in hero.card_generation_timers.keys():
		if hero.hand_cards.size() >= hero.max_hand_size:
			break
		var timer_key: String = String(timer_key_variant)
		var state: Dictionary = Dictionary(hero.card_generation_timers.get(timer_key, {})).duplicate(true)
		var queued_cards: int = int(state.get("queued_cards", 0))
		var generator: Dictionary = Dictionary(state.get("generator", {})).duplicate(true)
		var max_stored_cards: int = generator_max_stored_cards(generator)
		var current_stored_cards: int = hero_hand_card_count_for_generator_key(hero, timer_key) + queued_cards
		if bool(generator.get("persistent_card", false)) and (max_stored_cards <= 0 or current_stored_cards < max_stored_cards):
			queued_cards = 1
		while queued_cards > 0 and hero.hand_cards.size() < hero.max_hand_size:
			hero.hand_cards.append(build_hand_card_from_generator(hero, generator, empty_inventory_effect_summary()))
			queued_cards -= 1
		state["queued_cards"] = queued_cards
		hero.card_generation_timers[timer_key] = state

func advance_hero_builtin_door_card_generators(door_count: int = 1) -> void:
	if door_count <= 0:
		return
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		sync_hero_builtin_card_sources(hero)
		for timer_key_variant in hero.card_generation_timers.keys():
			var timer_key: String = String(timer_key_variant)
			var state: Dictionary = Dictionary(hero.card_generation_timers.get(timer_key, {})).duplicate(true)
			var generator: Dictionary = Dictionary(state.get("generator", {})).duplicate(true)
			if String(generator.get("generation_mode", resolve_card_generator_mode(generator))) != "door_interval":
				hero.card_generation_timers[timer_key] = state
				continue
			var remaining_doors: int = int(state.get("remaining_doors", 1)) - door_count
			var interval: int = maxi(1, int(state.get("interval", 1)))
			var queued_cards: int = int(state.get("queued_cards", 0))
			var max_stored_cards: int = generator_max_stored_cards(generator)
			while remaining_doors <= 0:
				var current_stored_cards: int = queued_cards + hero_hand_card_count_for_generator_key(hero, timer_key)
				if max_stored_cards <= 0 or current_stored_cards < max_stored_cards:
					queued_cards += 1
				remaining_doors += interval
			state["remaining_doors"] = remaining_doors
			state["queued_cards"] = queued_cards
			hero.card_generation_timers[timer_key] = state
		fill_queued_hero_builtin_cards(hero)

func expire_door_turn_hand_cards() -> void:
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		var filtered_hand: Array = []
		for hand_card_variant in hero.hand_cards:
			var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
			var expires_on: int = int(hand_card.get("expires_on_doors_opened", -1))
			if expires_on >= 0 and doors_opened >= expires_on:
				continue
			filtered_hand.append(hand_card)
		hero.hand_cards = filtered_hand

func sync_hero_card_sources(hero: Variant, effect_summary: Dictionary = {}) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var resolved_summary: Dictionary = effect_summary if not effect_summary.is_empty() else inventory_effect_summary(hero.inventory_items)
	var resolved_generators: Array = Array(resolved_summary.get("card_generators", [])).duplicate(true)
	for spell_generator_variant in spellbook_card_generators(hero, resolved_summary):
		resolved_generators.append((spell_generator_variant as Dictionary).duplicate(true))
	var initially_exhausted_item_uids: Dictionary = {}
	for generator_variant in resolved_generators:
		var generator: Dictionary = generator_variant
		var key: String = resolve_generator_key(generator)
		var item_bonus: Dictionary = Dictionary(generator.get("item_bonus", {}))
		var card_def: Dictionary = card_definition(String(generator.get("card_id", "")))
		var generation_mode: String = resolve_card_generator_mode(generator, card_def)
		var base_interval: int = maxi(1, int(card_def.get("door_interval", int(generator.get("door_interval", 1)))))
		var interval_multiplier: float = float(item_bonus.get("card_charge_mult", 1.0))
		var effective_interval: int = maxi(1, int(round(float(base_interval) * interval_multiplier)))
		var exhaust_cards: int = int(generator.get("exhaust_cards", 0))
		if not global_item_card_states.has(key):
			var initial_state: Dictionary = {
				"item_uid": int(generator.get("item_uid", -1)),
				"generation_mode": generation_mode,
				"remaining_doors": effective_interval,
				"interval": effective_interval,
				"queued_cards": 0 if hero_hand_card_count_for_generator_key(hero, key) > 0 else 1,
				"remaining_generations": 0,
				"allow_orphaned_cards": false,
			}
			if generation_mode == "door_interval":
				initial_state["remaining_generations"] = max(exhaust_cards - 1, 0) if exhaust_cards > 0 else -1
				if exhaust_cards == 1:
					initial_state["allow_orphaned_cards"] = true
					initially_exhausted_item_uids[int(generator.get("item_uid", -1))] = true
			global_item_card_states[key] = initial_state
		else:
			var state: Dictionary = Dictionary(global_item_card_states.get(key, {})).duplicate(true)
			state["generation_mode"] = generation_mode
			state["interval"] = effective_interval
			if generation_mode == "door_interval":
				state["remaining_doors"] = clampi(int(state.get("remaining_doors", effective_interval)), 1, effective_interval)
			else:
				state["remaining_doors"] = effective_interval
			global_item_card_states[key] = state
	for exhausted_uid_variant in initially_exhausted_item_uids.keys():
		remove_item_by_uid_from_world(int(exhausted_uid_variant))
	cleanup_global_item_card_states()
	var valid_item_uids: Dictionary = {}
	var valid_generator_keys: Dictionary = {}
	for item_variant in hero.inventory_items:
		var inventory_item: Dictionary = item_variant as Dictionary
		var item_uid: int = int(inventory_item.get("uid", -1))
		valid_item_uids[item_uid] = true
	for generator_variant in resolved_generators:
		var generator: Dictionary = generator_variant
		var generator_key: String = resolve_generator_key(generator)
		valid_generator_keys[generator_key] = true
	var filtered_hand: Array = []
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
		if String(hand_card.get("source_type", "item")) == "hero_builtin":
			if int(hand_card.get("source_hero_index", -1)) == hero.hero_index:
				filtered_hand.append(hand_card)
			continue
		var hand_item_uid: int = int(hand_card.get("item_uid", -1))
		var hand_key: String = String(hand_card.get("generator_key", card_generator_key(hand_item_uid, String(hand_card.get("card_id", "")))))
		if valid_item_uids.has(hand_item_uid):
			if not valid_generator_keys.has(hand_key):
				continue
			filtered_hand.append(hand_card)
		else:
			var hand_state: Dictionary = Dictionary(global_item_card_states.get(hand_key, {}))
			if bool(hand_state.get("allow_orphaned_cards", false)):
				filtered_hand.append(hand_card)
			elif global_item_card_states.has(hand_key):
				hand_state = Dictionary(global_item_card_states.get(hand_key, {})).duplicate(true)
				hand_state["queued_cards"] = int(hand_state.get("queued_cards", 0)) + 1
				global_item_card_states[hand_key] = hand_state
	hero.hand_cards = filtered_hand
	while hero.hand_cards.size() > hero.max_hand_size:
		hero.hand_cards.pop_back()
	fill_queued_hand_cards(hero, resolved_summary, resolved_generators)

func sync_hero_passive_combat_sources(hero: Variant, effect_summary: Dictionary = {}) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var resolved_summary: Dictionary = effect_summary if not effect_summary.is_empty() else inventory_effect_summary(hero.inventory_items)
	for passive_variant in Array(resolved_summary.get("combat_passives", [])):
		var passive_ability: Dictionary = passive_variant
		var key: String = combat_passive_key(int(passive_ability.get("item_uid", -1)), String(passive_ability.get("card_id", "")))
		var item_bonus: Dictionary = Dictionary(passive_ability.get("item_bonus", {}))
		var card_def: Dictionary = card_definition(String(passive_ability.get("card_id", "")))
		var base_cooldown: float = float(passive_ability.get("cooldown", card_def.get("test_cooldown", 1.5)))
		var effective_cooldown: float = maxf(base_cooldown * float(item_bonus.get("card_charge_mult", 1.0)), 0.25)
		if not global_item_passive_timers.has(key):
			global_item_passive_timers[key] = {
				"item_uid": int(passive_ability.get("item_uid", -1)),
				"timer_left": effective_cooldown,
			}
		else:
			var passive_state: Dictionary = Dictionary(global_item_passive_timers.get(key, {})).duplicate(true)
			passive_state["timer_left"] = minf(float(passive_state.get("timer_left", effective_cooldown)), effective_cooldown)
			global_item_passive_timers[key] = passive_state
	var known_item_uids: Dictionary = collect_world_item_uids()
	var stale_keys: Array = []
	for timer_key_variant in global_item_passive_timers.keys():
		var timer_key: String = String(timer_key_variant)
		var passive_state: Dictionary = Dictionary(global_item_passive_timers.get(timer_key, {}))
		if not known_item_uids.has(int(passive_state.get("item_uid", -1))):
			stale_keys.append(timer_key)
	for stale_key_variant in stale_keys:
		global_item_passive_timers.erase(String(stale_key_variant))

func fill_queued_hand_cards(hero: Variant, effect_summary: Dictionary = {}, precomputed_generators: Array = []) -> void:
	if hero == null or not is_instance_valid(hero) or hero.hand_cards.size() >= hero.max_hand_size:
		return
	var resolved_summary: Dictionary = effect_summary if not effect_summary.is_empty() else inventory_effect_summary(hero.inventory_items)
	var resolved_generators: Array = precomputed_generators.duplicate(true) if not precomputed_generators.is_empty() else Array(resolved_summary.get("card_generators", [])).duplicate(true)
	if precomputed_generators.is_empty():
		for spell_generator_variant in spellbook_card_generators(hero, resolved_summary):
			resolved_generators.append((spell_generator_variant as Dictionary).duplicate(true))
	var generators_by_key: Dictionary = {}
	for generator_variant in resolved_generators:
		var generator: Dictionary = generator_variant
		var generators_key: String = resolve_generator_key(generator)
		generators_by_key[generators_key] = generator
	for timer_key_variant in global_item_card_states.keys():
		if hero.hand_cards.size() >= hero.max_hand_size:
			break
		var timer_key: String = String(timer_key_variant)
		if not generators_by_key.has(timer_key):
			continue
		var state: Dictionary = Dictionary(global_item_card_states.get(timer_key, {})).duplicate(true)
		var queued_cards: int = int(state.get("queued_cards", 0))
		while queued_cards > 0 and hero.hand_cards.size() < hero.max_hand_size:
			hero.hand_cards.append(build_hand_card_from_generator(hero, Dictionary(generators_by_key[timer_key]), resolved_summary))
			queued_cards -= 1
		state["queued_cards"] = queued_cards
		global_item_card_states[timer_key] = state
	fill_queued_hero_builtin_cards(hero)

func advance_item_door_card_generators(door_count: int = 1) -> void:
	if door_count <= 0:
		return
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		var effect_summary: Dictionary = inventory_effect_summary(hero.inventory_items)
		var resolved_generators: Array = Array(effect_summary.get("card_generators", [])).duplicate(true)
		for spell_generator_variant in spellbook_card_generators(hero, effect_summary):
			resolved_generators.append((spell_generator_variant as Dictionary).duplicate(true))
		sync_hero_card_sources(hero, effect_summary)
		var exhausted_item_uids: Dictionary = {}
		for generator_variant in resolved_generators:
			var generator: Dictionary = generator_variant
			var key: String = resolve_generator_key(generator)
			var state: Dictionary = Dictionary(global_item_card_states.get(key, {})).duplicate(true)
			if state.is_empty():
				continue
			if String(state.get("generation_mode", resolve_card_generator_mode(generator))) != "door_interval":
				continue
			var remaining_doors: int = int(state.get("remaining_doors", 1)) - door_count
			var interval: int = maxi(1, int(state.get("interval", 1)))
			var queued_cards: int = int(state.get("queued_cards", 0))
			var remaining_generations: int = int(state.get("remaining_generations", -1))
			var max_stored_cards: int = generator_max_stored_cards(generator)
			while remaining_doors <= 0:
				if remaining_generations == 0:
					break
				var current_stored_cards: int = queued_cards + hero_hand_card_count_for_generator_key(hero, key)
				if max_stored_cards <= 0 or current_stored_cards < max_stored_cards:
					queued_cards += 1
				if remaining_generations > 0:
					remaining_generations -= 1
				remaining_doors += interval
			state["remaining_doors"] = remaining_doors
			state["queued_cards"] = queued_cards
			state["remaining_generations"] = remaining_generations
			if remaining_generations == 0:
				state["allow_orphaned_cards"] = true
				exhausted_item_uids[int(state.get("item_uid", -1))] = true
			global_item_card_states[key] = state
		for exhausted_uid_variant in exhausted_item_uids.keys():
			remove_item_by_uid_from_world(int(exhausted_uid_variant))
		fill_queued_hand_cards(hero, effect_summary, resolved_generators)
	cleanup_global_item_card_states()

func open_room_loot_inventory(hero: Variant, room_coord: Vector2i) -> void:
	if hero == null or not is_instance_valid(hero) or not rooms.has(room_coord):
		return
	clear_pending_room_loot_request(hero.hero_index)
	open_hero_inventory(hero, room_coord)

func open_hero_inventory(hero: Variant, room_coord: Vector2i = INVALID_ROOM) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	build_menu_open = false
	clear_build_mode()
	crystal_prompt_visible = false
	room_action_menu.clear()
	var ground_items: Array = []
	var loot_enabled: bool = rooms.has(room_coord)
	if loot_enabled:
		for ground_item_variant in rooms[room_coord]["ground_items"]:
			ground_items.append((ground_item_variant as Dictionary).duplicate(true))
	inventory_session = {
		"hero_index": hero.hero_index,
		"room": room_coord,
	}
	inventory_overlay.configure(hero.hero_name, hero.level, food, level_up_food_cost(hero.level), hero_can_level_up(hero), build_inventory_stat_lines(hero, hero.inventory_items), build_inventory_ability_sections(hero), build_level_up_reward_lines(hero), hero.inventory_canvas_size, hero.base_inventory_origin, hero.base_inventory_size, hero.pack_modules, item_defs, hero.inventory_items, ground_items, loot_enabled, hero_spellbook_overlay_data(hero))
	status_message = "Inventory open for %s." % hero.hero_name
	mouse_pressed = false
	mouse_dragging = false
	touch_points.clear()
	active_touch_id = -1
	room_action_hold.clear()
	update_hud()

func clear_inventory_session(_commit_pending_item: bool) -> void:
	if inventory_session.is_empty():
		if inventory_overlay != null:
			inventory_overlay.hide_overlay()
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	var room_coord: Vector2i = inventory_session.get("room", INVALID_ROOM)
	if inventory_overlay != null:
		var commit_items: Array = inventory_overlay.get_inventory_items()
		var commit_ground_items: Array = inventory_overlay.get_ground_items()
		commit_inventory_state(hero_index, room_coord, commit_items, commit_ground_items)
		if multiplayer_session_active() and not authoritative_simulation_active():
			server_commit_inventory_state.rpc_id(NETWORK_HOST_PEER_ID, hero_index, room_coord, commit_items, commit_ground_items)
	if inventory_overlay != null:
		inventory_overlay.hide_overlay()
	inventory_session.clear()
	if multiplayer_session_active() and multiplayer.is_server():
		broadcast_network_snapshot()
	queue_redraw()

func commit_inventory_state(hero_index: int, room_coord: Vector2i, items: Array, ground_items: Array) -> void:
	if rooms.has(room_coord):
		rooms[room_coord]["ground_items"] = prepare_ground_items_for_room(room_coord, ground_items)
	if hero_index >= 0 and hero_index < heroes.size():
		var hero: Variant = heroes[hero_index]
		if is_instance_valid(hero):
			hero.inventory_items = items.duplicate(true)
			apply_inventory_stats_to_hero(hero)

func commit_pack_layout(hero_index: int, pack_modules: Array) -> void:
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	hero.pack_modules = pack_modules.duplicate(true)
	apply_inventory_stats_to_hero(hero)

func reset_hero_spellbook_generated_cards(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var filtered_hand: Array = []
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
		var generator_key: String = String(hand_card.get("generator_key", ""))
		if generator_key.begins_with("spellbook:%d:" % hero.hero_index):
			continue
		filtered_hand.append(hand_card)
	hero.hand_cards = filtered_hand
	var stale_keys: Array = []
	for state_key_variant in global_item_card_states.keys():
		var state_key: String = String(state_key_variant)
		if state_key.begins_with("spellbook:%d:" % hero.hero_index):
			stale_keys.append(state_key)
	for stale_key_variant in stale_keys:
		global_item_card_states.erase(String(stale_key_variant))

func commit_spell_slots(hero_index: int, slotted_spells: Array) -> void:
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	hero.slotted_spells = Array(slotted_spells).duplicate()
	sanitize_hero_spellbook(hero)
	if doors_opened == 0:
		reset_hero_spellbook_generated_cards(hero)
		refresh_active_floor_spells(hero, true)
	apply_inventory_stats_to_hero(hero)

func center_camera() -> void:
	refresh_camera_bounds()
	camera.zoom = Vector2(CAMERA_DEFAULT_ZOOM, CAMERA_DEFAULT_ZOOM)
	camera.global_position = hero_focus_position()
	clamp_camera()

func hero_is_active(hero: Variant) -> bool:
	return hero != null and is_instance_valid(hero) and (not hero.has_method("is_dead_state") or not hero.is_dead_state()) and float(hero.current_health) > 0.0

func alive_hero_count() -> int:
	var count: int = 0
	for hero in heroes:
		if hero_is_active(hero):
			count += 1
	return count

func selected_hero() -> Variant:
	if selected_hero_index < 0 or selected_hero_index >= heroes.size():
		return null
	var hero: Variant = heroes[selected_hero_index]
	return hero if hero_is_active(hero) else null

func update_selected_hero_flags() -> void:
	for hero_index in range(heroes.size()):
		var hero: Variant = heroes[hero_index]
		if is_instance_valid(hero):
			hero.selected = hero_index == selected_hero_index and hero_is_active(hero)

func select_hero_by_index(hero_index: int) -> void:
	if hero_index < 0 or hero_index >= heroes.size() or not can_local_control_hero_index(hero_index):
		return
	selected_hero_index = hero_index
	update_selected_hero_flags()
	var hero: Variant = selected_hero()
	if hero != null:
		selected_room = active_hero_room_for_commands(hero)
		status_message = "%s selected." % hero.hero_name
	update_hud()
	queue_redraw()

func hero_idle_position(room_coord: Vector2i, hero_index: int, total_heroes: int) -> Vector2:
	var room_rect_local: Rect2 = room_rect(room_coord)
	var spread: float = 52.0
	var start_x: float = -spread * 0.5 * float(max(total_heroes - 1, 1))
	return clamp_point_to_room(room_rect_local.get_center() + Vector2(start_x + float(hero_index) * spread, 24.0), room_coord)

func crystal_world_position() -> Vector2:
	if crystal_holder != null and is_instance_valid(crystal_holder):
		return crystal_holder.global_position + Vector2(0.0, -36.0)
	if crystal_ground_room != INVALID_ROOM and rooms.has(crystal_ground_room) and rooms[crystal_ground_room]["opened"]:
		return room_walkable_center(crystal_ground_room)
	return room_walkable_center(crystal_room)

func carrier_in_exit_room() -> bool:
	return hero_is_active(crystal_holder) and crystal_holder.current_room == exit_room and crystal_holder.pending_room == INVALID_ROOM and crystal_holder.is_idle()

func all_heroes_in_exit_room() -> bool:
	if exit_room == INVALID_ROOM or not carrier_in_exit_room():
		return false
	for hero in heroes:
		if not hero_is_active(hero):
			continue
		if hero.current_room != exit_room or hero.pending_room != Hero.INVALID_ROOM or not hero.is_idle():
			return false
	return true

func ui_button_hold_duration(button_id: String) -> float:
	match button_id:
		"restart":
			return UI_RESTART_HOLD_DURATION
		_:
			return UI_BUTTON_HOLD_DURATION

func ui_button_hold_button(button_id: String) -> Button:
	match button_id:
		"inventory":
			return inventory_button
		"stamina":
			return stamina_toggle_button
		"restart":
			return restart_button
		_:
			return null

func ui_button_hold_progress(button_id: String) -> float:
	if ui_button_hold.is_empty() or String(ui_button_hold.get("id", "")) != button_id:
		return 0.0
	return clampf(float(ui_button_hold.get("elapsed", 0.0)) / maxf(float(ui_button_hold.get("duration", 0.001)), 0.001), 0.0, 1.0)

func hold_button_text(base_text: String, button_id: String) -> String:
	var progress: float = ui_button_hold_progress(button_id)
	if progress <= 0.0:
		return base_text
	return "%s %d%%" % [base_text, int(round(progress * 100.0))]

func update_restart_button_hold_fill() -> void:
	if restart_button_hold_fill == null or not is_instance_valid(restart_button_hold_fill):
		return
	var progress: float = ui_button_hold_progress("restart")
	restart_button_hold_fill.visible = progress > 0.001
	restart_button_hold_fill.anchor_right = progress
	restart_button_hold_fill.offset_right = 0.0
	var fill_style: StyleBoxFlat = restart_button_hold_fill.get_theme_stylebox("panel") as StyleBoxFlat
	if fill_style != null:
		fill_style.corner_radius_top_right = 10 if progress >= 0.995 else 0
		fill_style.corner_radius_bottom_right = 10 if progress >= 0.995 else 0

func begin_ui_button_hold(button_id: String) -> void:
	var button: Button = ui_button_hold_button(button_id)
	if button == null or not is_instance_valid(button) or button.disabled or not button.visible:
		return
	ui_button_hold = {
		"id": button_id,
		"elapsed": 0.0,
		"duration": ui_button_hold_duration(button_id),
	}
	update_hud()

func cancel_ui_button_hold(button_id: String = "") -> void:
	if ui_button_hold.is_empty():
		return
	if button_id != "" and String(ui_button_hold.get("id", "")) != button_id:
		return
	ui_button_hold.clear()
	update_hud()

func advance_ui_button_hold(delta: float) -> void:
	if ui_button_hold.is_empty():
		return
	var button_id: String = String(ui_button_hold.get("id", ""))
	var button: Button = ui_button_hold_button(button_id)
	if button == null or not is_instance_valid(button) or button.disabled or not button.visible:
		cancel_ui_button_hold()
		return
	ui_button_hold["elapsed"] = float(ui_button_hold.get("elapsed", 0.0)) + delta
	if float(ui_button_hold.get("elapsed", 0.0)) >= float(ui_button_hold.get("duration", UI_BUTTON_HOLD_DURATION)):
		ui_button_hold.clear()
		trigger_ui_button_hold_action(button_id)
	else:
		update_hud()

func trigger_ui_button_hold_action(button_id: String) -> void:
	match button_id:
		"restart":
			_on_restart_button_pressed()

func _on_ui_button_hold_down(button_id: String) -> void:
	begin_ui_button_hold(button_id)

func _on_ui_button_hold_up(button_id: String) -> void:
	cancel_ui_button_hold(button_id)

func _on_ui_button_hold_cancel(button_id: String) -> void:
	cancel_ui_button_hold(button_id)

func refresh_camera_bounds() -> void:
	var crystal_rect: Rect2 = room_rect(crystal_room)
	var min_point: Vector2 = crystal_rect.position
	var max_point: Vector2 = crystal_rect.position + crystal_rect.size
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		var rect: Rect2 = room_rect(room_coord)
		min_point.x = minf(min_point.x, rect.position.x)
		min_point.y = minf(min_point.y, rect.position.y)
		max_point.x = maxf(max_point.x, rect.position.x + rect.size.x)
		max_point.y = maxf(max_point.y, rect.position.y + rect.size.y)
	var viewport_padding: Vector2 = get_viewport_rect().size * 0.12 * camera.zoom
	var total_padding: Vector2 = CAMERA_BOUNDS_PADDING + CAMERA_DISCOVERED_PAN_SLACK + viewport_padding
	camera_bounds = Rect2(min_point - total_padding, (max_point - min_point) + total_padding * 2.0)

func hero_focus_position() -> Vector2:
	var hero: Variant = selected_hero()
	if hero == null:
		return room_center(crystal_room)
	return hero.global_position + CAMERA_SOFT_FOLLOW_OFFSET * camera.zoom.y

func mark_camera_interaction() -> void:
	camera_interaction_cooldown = CAMERA_INTERACTION_COOLDOWN

func mark_camera_pan_interaction() -> void:
	camera_interaction_cooldown = maxf(camera_interaction_cooldown, CAMERA_MANUAL_PAN_COOLDOWN)

func reset_camera_pan_state() -> void:
	return

func cancel_room_action_camera_focus() -> void:
	room_action_camera_target_active = false

func room_action_overlay_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	return clampf(minf(viewport_size.x, viewport_size.y) / 900.0, 0.84, 1.28)

func room_action_menu_screen_center() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	return viewport_size * 0.5

func advance_camera(delta: float) -> void:
	camera_interaction_cooldown = maxf(camera_interaction_cooldown - delta, 0.0)
	if not room_action_menu.is_empty():
		camera.global_position = camera.global_position.lerp(room_action_camera_target, minf(CAMERA_ROOM_ACTION_PAN_SPEED * delta, 1.0))
		if camera.global_position.distance_to(room_action_camera_target) <= 3.0:
			camera.global_position = room_action_camera_target
		clamp_camera()
		return
	if room_action_camera_target_active:
		camera.global_position = camera.global_position.lerp(room_action_camera_target, minf(CAMERA_ROOM_ACTION_PAN_SPEED * delta, 1.0))
		if camera.global_position.distance_to(room_action_camera_target) <= 6.0:
			room_action_camera_target_active = false
		clamp_camera()
		return
	if touch_dragging and active_touch_id >= 0 and touch_points.has(active_touch_id):
		var touch_screen: Vector2 = Vector2(touch_points[active_touch_id])
		camera.global_position -= (touch_screen - touch_pan_last_screen) * camera.zoom * CAMERA_PAN_DRAG_MULTIPLIER
		touch_pan_last_screen = touch_screen
	if camera_interaction_cooldown <= 0.0 and touch_points.is_empty() and not mouse_pressed:
		var hero: Variant = selected_hero()
		if hero != null and (not hero.is_idle() or hero.pending_room != Hero.INVALID_ROOM):
			var target_position: Vector2 = hero_focus_position()
			camera.global_position = camera.global_position.lerp(target_position, minf(CAMERA_SOFT_FOLLOW_SPEED * delta, 1.0))
	clamp_camera()

func clamp_camera() -> void:
	if camera_bounds == Rect2():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var view_half: Vector2 = viewport_size * 0.5 * camera.zoom
	var min_x: float = camera_bounds.position.x + view_half.x
	var max_x: float = camera_bounds.position.x + camera_bounds.size.x - view_half.x
	var min_y: float = camera_bounds.position.y + view_half.y
	var max_y: float = camera_bounds.position.y + camera_bounds.size.y - view_half.y
	if min_x > max_x:
		camera.global_position.x = camera_bounds.get_center().x
	else:
		camera.global_position.x = clampf(camera.global_position.x, min_x, max_x)
	if min_y > max_y:
		camera.global_position.y = camera_bounds.get_center().y
	else:
		camera.global_position.y = clampf(camera.global_position.y, min_y, max_y)

func set_camera_zoom(zoom_value: float) -> void:
	var clamped_zoom: float = clampf(zoom_value, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM)
	camera.zoom = Vector2(clamped_zoom, clamped_zoom)
	clamp_camera()

func handle_inventory_input(event: InputEvent) -> void:
	if inventory_overlay == null or not inventory_overlay.visible:
		return
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			inventory_overlay.pointer_press(touch_event.position)
		else:
			inventory_overlay.pointer_release(touch_event.position)
	elif event is InputEventScreenDrag:
		inventory_overlay.pointer_move(event.position)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			inventory_overlay.pointer_press(mouse_event.position)
		else:
			inventory_overlay.pointer_release(mouse_event.position)
	elif event is InputEventMouseMotion:
		inventory_overlay.pointer_move(event.position)

func clear_pending_room_loot_request(hero_index: int = -1) -> void:
	if hero_index < 0:
		pending_room_loot_requests.clear()
		return
	pending_room_loot_requests.erase(hero_index)

func clear_pending_room_action_request(hero_index: int = -1) -> void:
	if hero_index < 0:
		pending_room_action_requests.clear()
		return
	pending_room_action_requests.erase(hero_index)

func try_open_pending_room_loot_request(hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if inventory_overlay != null and inventory_overlay.visible:
		return false
	if not pending_room_loot_requests.has(hero.hero_index):
		return false
	if hero.pending_room != Hero.INVALID_ROOM or not hero.is_idle() or not hero.move_steps.is_empty():
		return false
	var loot_request: Dictionary = pending_room_loot_requests[hero.hero_index]
	var room_coord: Vector2i = loot_request.get("room", INVALID_ROOM)
	if hero.current_room != room_coord:
		return false
	clear_pending_room_loot_request(hero.hero_index)
	hero.player_command_locked = false
	open_room_loot_inventory(hero, room_coord)
	return true

func try_execute_pending_room_action_request(hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if not pending_room_action_requests.has(hero.hero_index):
		return false
	var action_request: Dictionary = pending_room_action_requests[hero.hero_index]
	var action_room: Vector2i = action_request.get("room", INVALID_ROOM)
	match String(action_request.get("kind", "")):
		"card":
			var card_room: Vector2i = action_request.get("target_room", action_room)
			if not hero_ready_for_card_cast(hero, action_room, card_room, hand_card_by_uid(hero, int(action_request.get("card_uid", -1))), Vector2(action_request.get("target_world_position", room_center(card_room)))):
				return false
		_:
			if not hero_ready_for_room_action(hero, action_room):
				return false
	clear_pending_room_action_request(hero.hero_index)
	var room_coord: Vector2i = action_room
	match String(action_request.get("kind", "")):
		"light":
			hero.player_command_locked = false
			toggle_room_light(room_coord)
			return true
		"build":
			hero.player_command_locked = false
			queue_room_construction(room_coord, String(action_request.get("module_type", "")))
			return true
		"card":
			hero.player_command_locked = false
			return play_card_for_hero(hero.hero_index, int(action_request.get("card_uid", -1)), Vector2(action_request.get("target_world_position", room_center(room_coord))))
		_:
			return false

func clear_room_action_hold() -> void:
	room_action_hold.clear()

func clear_room_action_menu_pointer() -> void:
	room_action_menu_hold_selection_active = false
	if room_action_menu.is_empty():
		return
	room_action_menu.erase("pointer_kind")
	room_action_menu.erase("pointer_id")
	room_action_menu.erase("pointer_origin_screen")
	room_action_menu.erase("pointer_screen")
	room_action_menu.erase("pointer_active")

func room_action_menu_virtual_pointer_screen_position() -> Vector2:
	var menu_center: Vector2 = room_action_menu_screen_center()
	if room_action_menu.is_empty() or not bool(room_action_menu.get("pointer_active", false)):
		return menu_center
	var origin_screen: Vector2 = Vector2(room_action_menu.get("pointer_origin_screen", menu_center))
	var pointer_screen: Vector2 = Vector2(room_action_menu.get("pointer_screen", origin_screen))
	return menu_center + (pointer_screen - origin_screen)

func begin_room_action_menu_pointer(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if room_action_menu.is_empty():
		return false
	room_action_menu_hold_selection_active = true
	room_action_menu["pointer_kind"] = pointer_kind
	room_action_menu["pointer_id"] = pointer_id
	room_action_menu["pointer_origin_screen"] = screen_position
	room_action_menu["pointer_screen"] = screen_position
	room_action_menu["pointer_active"] = true
	queue_redraw()
	return true

func update_room_action_menu_pointer(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if room_action_menu.is_empty() or not bool(room_action_menu.get("pointer_active", false)):
		return false
	if String(room_action_menu.get("pointer_kind", "")) != pointer_kind or int(room_action_menu.get("pointer_id", -1)) != pointer_id:
		return false
	room_action_menu["pointer_screen"] = screen_position
	queue_redraw()
	return true

func release_room_action_menu_pointer(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if not update_room_action_menu_pointer(pointer_kind, pointer_id, screen_position):
		return false
	var pointer_position: Vector2 = room_action_menu_virtual_pointer_screen_position()
	var action_id: String = room_action_button_at_screen_position(pointer_position)
	clear_room_action_menu_pointer()
	if action_id == "":
		close_room_action_menu()
		queue_redraw()
		return true
	perform_room_action(room_action_menu.get("room", INVALID_ROOM), action_id)
	return true

func focus_room_action_menu(room_coord: Vector2i, _center_on_screen: bool) -> void:
	room_action_camera_target = room_center(room_coord)
	room_action_camera_target_active = true
	reset_camera_pan_state()
	mark_camera_interaction()
	queue_redraw()

func close_room_action_menu() -> void:
	room_action_menu.clear()
	clear_room_action_menu_pointer()
	cancel_room_action_camera_focus()

func room_action_target_for_selected_hero() -> Vector2i:
	var hero: Variant = selected_hero()
	if hero == null or not is_instance_valid(hero):
		return INVALID_ROOM
	if opening_hero == hero and opening_origin_room != INVALID_ROOM and rooms.has(opening_origin_room) and rooms[opening_origin_room]["opened"]:
		return opening_origin_room
	if hero.pending_open_origin_room != Hero.INVALID_ROOM and rooms.has(hero.pending_open_origin_room) and rooms[hero.pending_open_origin_room]["opened"]:
		return hero.pending_open_origin_room
	if not hero.move_steps.is_empty():
		for step_index in range(hero.move_steps.size() - 1, -1, -1):
			var step: Dictionary = hero.move_steps[step_index]
			var step_room: Vector2i = step.get("room", INVALID_ROOM)
			if step_room != INVALID_ROOM and rooms.has(step_room) and rooms[step_room]["opened"]:
				return step_room
	if hero.pending_room != Hero.INVALID_ROOM and rooms.has(hero.pending_room) and rooms[hero.pending_room]["opened"]:
		return hero.pending_room
	if rooms.has(hero.current_room) and rooms[hero.current_room]["opened"]:
		return hero.current_room
	return INVALID_ROOM

func begin_room_action_hold(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> void:
	if not room_actions_allowed_for_local_peer():
		return
	var room_coord: Vector2i = room_action_target_for_selected_hero()
	if room_coord == INVALID_ROOM:
		clear_room_action_hold()
		return
	room_action_hold = {
		"pointer_kind": pointer_kind,
		"pointer_id": pointer_id,
		"start_screen": screen_position,
		"current_screen": screen_position,
		"elapsed": 0.0,
		"room": room_coord,
	}

func advance_room_action_hold(delta: float) -> void:
	if room_action_hold.is_empty() or inventory_overlay != null and inventory_overlay.visible or not room_action_menu.is_empty():
		return
	room_action_hold["elapsed"] = float(room_action_hold["elapsed"]) + delta
	if float(room_action_hold["elapsed"]) < ROOM_ACTION_HOLD_START_DELAY + ROOM_ACTION_HOLD_LOADER_DURATION:
		return
	open_room_action_menu(
		room_action_hold["room"],
		room_action_hold["current_screen"],
		true,
		String(room_action_hold.get("pointer_kind", "")),
		int(room_action_hold.get("pointer_id", -1))
	)
	clear_room_action_hold()
	update_hud()

func handle_screen_touch(event: InputEventScreenTouch) -> void:
	mark_camera_interaction()
	if not event.pressed and finish_hand_card_drag("touch", event.index, event.position):
		touch_points.erase(event.index)
		if touch_points.is_empty():
			active_touch_id = -1
			touch_dragging = false
			pinch_active = false
		return
	if event.pressed and dismiss_hand_card_info_if_outside(event.position):
		return
	if event.pressed and not room_action_menu.is_empty():
		begin_room_action_menu_pointer("touch", event.index, event.position)
		return
	if not event.pressed and not room_action_menu.is_empty():
		touch_points.erase(event.index)
		if event.index == active_touch_id:
			active_touch_id = -1
			touch_dragging = false
			pinch_active = false
		release_room_action_menu_pointer("touch", event.index, event.position)
		return
	if event.pressed:
		if begin_hand_card_drag("touch", event.index, event.position):
			return
		touch_points[event.index] = event.position
		reset_camera_pan_state()
		if touch_points.size() == 1:
			active_touch_id = event.index
			touch_start_screen = event.position
			touch_pan_last_screen = event.position
			touch_dragging = false
			pinch_active = false
			begin_room_action_hold("touch", event.index, event.position)
		elif touch_points.size() >= 2:
			begin_pinch_gesture()
			clear_room_action_hold()
		return
	var released_position: Vector2 = event.position
	var should_tap: bool = event.index == active_touch_id and not touch_dragging and not pinch_active
	var was_dragging: bool = event.index == active_touch_id and touch_dragging
	touch_points.erase(event.index)
	if not room_action_hold.is_empty() and room_action_hold["pointer_kind"] == "touch" and int(room_action_hold["pointer_id"]) == event.index:
		clear_room_action_hold()
	if should_tap:
		handle_world_tap(screen_to_world(released_position), released_position)
	if touch_points.size() == 1:
		var remaining_ids: Array = touch_points.keys()
		active_touch_id = int(remaining_ids[0])
		touch_start_screen = touch_points[active_touch_id]
		touch_pan_last_screen = touch_points[active_touch_id]
		touch_dragging = false
		pinch_active = false
	elif touch_points.is_empty():
		active_touch_id = -1
		touch_dragging = false
		pinch_active = false

func handle_screen_drag(event: InputEventScreenDrag) -> void:
	if update_hand_card_drag("touch", event.index, event.position):
		return
	if not room_action_menu.is_empty():
		update_room_action_menu_pointer("touch", event.index, event.position)
		return
	touch_points[event.index] = event.position
	mark_camera_interaction()
	if not room_action_hold.is_empty() and room_action_hold["pointer_kind"] == "touch" and int(room_action_hold["pointer_id"]) == event.index:
		room_action_hold["current_screen"] = event.position
		if event.position.distance_to(Vector2(room_action_hold["start_screen"])) > ROOM_ACTION_HOLD_CANCEL_DISTANCE:
			clear_room_action_hold()
	if touch_points.size() >= 2:
		mark_camera_pan_interaction()
		update_pinch_gesture()
		touch_dragging = true
		return
	if event.index != active_touch_id:
		return
	if not touch_dragging and event.position.distance_to(touch_start_screen) > CAMERA_DRAG_THRESHOLD:
		touch_dragging = true
		touch_pan_last_screen = event.position
	if touch_dragging:
		cancel_room_action_camera_focus()
		mark_camera_pan_interaction()

func begin_pinch_gesture() -> void:
	var ids: Array = touch_points.keys()
	if ids.size() < 2:
		return
	var first_index: int = int(ids[0])
	var second_index: int = int(ids[1])
	var first_point: Vector2 = touch_points[first_index]
	var second_point: Vector2 = touch_points[second_index]
	pinch_last_distance = first_point.distance_to(second_point)
	pinch_last_midpoint = (first_point + second_point) * 0.5
	pinch_active = pinch_last_distance > 0.0
	active_touch_id = -1
	touch_dragging = false
	reset_camera_pan_state()
	mark_camera_pan_interaction()
	cancel_room_action_camera_focus()

func update_pinch_gesture() -> void:
	var ids: Array = touch_points.keys()
	if ids.size() < 2:
		return
	var first_index: int = int(ids[0])
	var second_index: int = int(ids[1])
	var first_point: Vector2 = touch_points[first_index]
	var second_point: Vector2 = touch_points[second_index]
	var current_distance: float = first_point.distance_to(second_point)
	if current_distance <= 0.0:
		return
	var current_midpoint: Vector2 = (first_point + second_point) * 0.5
	if pinch_last_distance > 0.0:
		var zoom_scale: float = pinch_last_distance / current_distance
		set_camera_zoom(camera.zoom.x * zoom_scale)
	cancel_room_action_camera_focus()
	mark_camera_pan_interaction()
	camera.global_position -= (current_midpoint - pinch_last_midpoint) * camera.zoom
	pinch_last_distance = current_distance
	pinch_last_midpoint = current_midpoint
	clamp_camera()

func handle_mouse_button(event: InputEventMouseButton) -> void:
	if not touch_points.is_empty():
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		mark_camera_interaction()
		set_camera_zoom(camera.zoom.x * 0.9)
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		mark_camera_interaction()
		set_camera_zoom(camera.zoom.x * 1.1)
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not event.pressed and finish_hand_card_drag("mouse", 0, event.position):
		mouse_pressed = false
		mouse_dragging = false
		return
	if event.pressed and dismiss_hand_card_info_if_outside(event.position):
		mouse_pressed = false
		mouse_dragging = false
		return
	if event.pressed and not room_action_menu.is_empty():
		begin_room_action_menu_pointer("mouse", 0, event.position)
		return
	if not event.pressed and not room_action_menu.is_empty():
		release_room_action_menu_pointer("mouse", 0, event.position)
		mouse_pressed = false
		mouse_dragging = false
		return
	if event.pressed:
		if begin_hand_card_drag("mouse", 0, event.position):
			mouse_pressed = false
			mouse_dragging = false
			return
		mouse_pressed = true
		mouse_dragging = false
		mouse_press_screen = event.position
		reset_camera_pan_state()
		mark_camera_interaction()
		begin_room_action_hold("mouse", 0, event.position)
	else:
		var should_tap: bool = mouse_pressed and not mouse_dragging
		mouse_pressed = false
		if not room_action_hold.is_empty() and room_action_hold["pointer_kind"] == "mouse":
			clear_room_action_hold()
		if should_tap:
			handle_world_tap(screen_to_world(event.position), event.position)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if update_hand_card_drag("mouse", 0, event.position):
		return
	if not mouse_pressed or not touch_points.is_empty():
		return
	if not room_action_menu.is_empty():
		update_room_action_menu_pointer("mouse", 0, event.position)
		return
	if not room_action_hold.is_empty() and room_action_hold["pointer_kind"] == "mouse":
		room_action_hold["current_screen"] = event.position
		if event.position.distance_to(Vector2(room_action_hold["start_screen"])) > ROOM_ACTION_HOLD_CANCEL_DISTANCE:
			clear_room_action_hold()
	if not mouse_dragging and event.position.distance_to(mouse_press_screen) > CAMERA_DRAG_THRESHOLD:
		mouse_dragging = true
	if mouse_dragging:
		cancel_room_action_camera_focus()
		mark_camera_pan_interaction()
		camera.global_position -= event.relative * camera.zoom * CAMERA_PAN_DRAG_MULTIPLIER

func try_select_hero_at_position(world_position: Vector2) -> bool:
	for hero_index in range(heroes.size()):
		var hero: Variant = heroes[hero_index]
		if not is_instance_valid(hero):
			continue
		if not can_local_control_hero_index(hero_index):
			continue
		if hero.global_position.distance_to(world_position) <= HERO_SELECTION_RADIUS:
			select_hero_by_index(hero_index)
			selected_room = active_hero_room_for_commands(hero)
			return true
	return false

func try_handle_crystal_tap(world_position: Vector2) -> bool:
	if crystal_holder != null or crystal_ground_room == INVALID_ROOM or not is_exit_discovered():
		return false
	if not rooms.has(crystal_ground_room) or not rooms[crystal_ground_room]["opened"]:
		return false
	if crystal_world_position().distance_to(world_position) > 40.0:
		return false
	crystal_prompt_visible = true
	selected_room = crystal_ground_room
	var hero: Variant = selected_hero()
	if hero != null and hero.current_room == crystal_ground_room and hero.pending_room == Hero.INVALID_ROOM and hero.is_idle():
		status_message = "Crystal selected. Tap Carry to burden %s with it." % hero.hero_name
	else:
		status_message = "Crystal selected. Move a hero into this room, then tap Carry."
	return true

func can_selected_hero_pick_up_crystal() -> bool:
	var hero: Variant = selected_hero()
	return hero != null and crystal_holder == null and crystal_ground_room != INVALID_ROOM and is_exit_discovered() and hero.current_room == crystal_ground_room and hero.pending_room == Hero.INVALID_ROOM and hero.is_idle()

func is_exit_discovered() -> bool:
	return exit_room != INVALID_ROOM and rooms.has(exit_room) and rooms[exit_room]["opened"]

func drop_crystal(room_coord: Vector2i) -> void:
	if crystal_holder != null and is_instance_valid(crystal_holder):
		crystal_holder.carrying_crystal = false
	crystal_holder = null
	crystal_ground_room = room_coord
	crystal_prompt_visible = false
	crystal_pressure_timer_left = 0.0

func handle_world_tap(world_position: Vector2, screen_position: Vector2) -> void:
	if not room_action_menu.is_empty():
		close_room_action_menu()
		queue_redraw()
		return
	var build_target_tap: bool = is_valid_build_target_tap(world_position)
	if build_menu_open or pending_build_type != "":
		var tapping_build_menu: bool = build_menu_contains_screen_position(screen_position)
		if tapping_build_menu:
			return
		if pending_build_type != "" and build_target_tap:
			build_menu_open = false
			if handle_build_tap(world_position):
				clear_build_mode()
				update_hud()
				queue_redraw()
				return
		build_menu_open = false
		if pending_build_type != "":
			clear_build_mode()
			status_message = "Build cancelled."
			update_hud()
			queue_redraw()
			return
	if try_select_hero_at_position(world_position):
		return
	if try_handle_crystal_tap(world_position):
		update_hud()
		queue_redraw()
		return
	var hero: Variant = selected_hero()
	if hero == null or not can_local_control_hero_index(selected_hero_index):
		return
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_world_command.rpc_id(NETWORK_HOST_PEER_ID, selected_hero_index, world_position)
		status_message = "%s command sent." % hero.hero_name
		update_hud()
		return
	execute_world_command_for_hero(selected_hero_index, world_position, true)
	if multiplayer_session_active() and multiplayer.is_server():
		broadcast_network_snapshot()

func execute_world_command_for_hero(hero_index: int, world_position: Vector2, update_local_selection: bool) -> void:
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	var command_room: Vector2i = active_hero_room_for_commands(hero)
	var frontier_door: Dictionary = frontier_target_at_position(world_position)
	var tapped_room: Vector2i = corridor_room_target_at_position(world_position, command_room)
	if frontier_door.is_empty() and tapped_room == INVALID_ROOM:
		return
	command_room = interrupt_hero_orders(hero)
	if not frontier_door.is_empty():
		var from_room: Vector2i = frontier_door["from_room"]
		var sealed_room: Vector2i = frontier_door["to_room"]
		if update_local_selection:
			selected_room = from_room
		hero.pending_open_origin_room = from_room
		hero.pending_open_room = sealed_room
		if command_room == from_room:
			issue_hero_steps(hero, build_steps_for_path([from_room], hero.global_position, doorway_position(from_room, sealed_room)))
		else:
			var door_path: Array[Vector2i] = find_path(command_room, from_room, true)
			if door_path.is_empty():
				status_message = "No open route to that door."
				update_hud()
				return
			issue_hero_steps(hero, build_steps_for_path(door_path, hero.global_position, doorway_position(from_room, sealed_room)))
		status_message = "%s moving to open a new chamber from %s." % [hero.hero_name, room_title(from_room)]
		update_hud()
		return
	if update_local_selection:
		selected_room = tapped_room
	if tapped_room == command_room:
		var move_target: Vector2 = clamp_point_to_room(world_position, tapped_room)
		issue_hero_steps(hero, build_steps_for_path([tapped_room], hero.global_position, move_target))
		status_message = "%s moving inside %s." % [hero.hero_name, room_title(tapped_room)]
		update_hud()
		return
	var path: Array[Vector2i] = find_path(command_room, tapped_room, true)
	if path.size() <= 1:
		status_message = "No open route to that room."
	else:
		issue_hero_steps(hero, build_steps_for_path(path, hero.global_position, clamp_point_to_room(world_position, tapped_room)))
		status_message = "%s moving to %s." % [hero.hero_name, room_title(tapped_room)]
	update_hud()

func open_room_action_menu(room_coord: Vector2i, screen_position: Vector2, hold_selection_active: bool = false, pointer_kind: String = "", pointer_id: int = -1) -> void:
	if room_coord == INVALID_ROOM or not rooms.has(room_coord) or not rooms[room_coord]["opened"]:
		return
	selected_room = room_coord
	build_menu_open = false
	clear_build_mode()
	room_action_menu_hold_selection_active = hold_selection_active
	room_action_menu = {
		"room": room_coord,
		"mode": "root",
		"pointer_kind": pointer_kind,
		"pointer_id": pointer_id,
		"pointer_origin_screen": screen_position,
		"pointer_screen": screen_position,
		"pointer_active": hold_selection_active,
	}
	focus_room_action_menu(room_coord, not hold_selection_active)
	status_message = "Room actions for %s." % room_title(room_coord)
	queue_redraw()

func room_action_button_layout() -> Array:
	var mode: String = String(room_action_menu.get("mode", "root"))
	match mode:
		"build_kind":
			return [
				{"id": "build_minor_menu", "label": "Minor", "angle": -3.08, "fill": Color("9bd8ff")},
				{"id": "build_major_menu", "label": "Major", "angle": -2.42, "fill": Color("f6c983")},
				{"id": "submenu_back", "label": "Back", "angle": -1.76, "fill": Color("d7dfeb")},
			]
		"build_minor":
			return [
				{"id": "build_minor_turret", "label": "Laser", "angle": -3.12, "fill": Color("89f2ff")},
				{"id": "build_minor_pulse", "label": "Pulse", "angle": -2.62, "fill": Color("ff8ce1")},
				{"id": "build_minor_cannon", "label": "Cannon", "angle": -2.12, "fill": Color("ffbf73")},
				{"id": "submenu_back_build", "label": "Back", "angle": -1.60, "fill": Color("d7dfeb")},
			]
		"build_major":
			return [
				{"id": "build_major_food", "label": "Food", "angle": -3.10, "fill": Color("8ee28a")},
				{"id": "build_major_science", "label": "Science", "angle": -2.58, "fill": Color("8bc1ff")},
				{"id": "build_major_industry", "label": "Industry", "angle": -2.06, "fill": Color("f1c26b")},
				{"id": "submenu_back_build", "label": "Back", "angle": -1.54, "fill": Color("d7dfeb")},
			]
		_:
			return [
				{"id": "loot", "label": "Loot", "angle": -3.08, "fill": Color("a6efba")},
				{"id": "build_menu", "label": "Build", "angle": -2.42, "fill": Color("91d1ff")},
				{"id": "light", "label": "Light", "angle": -1.76, "fill": Color("f3d88f")},
			]

func room_action_sector_layout() -> Array:
	var buttons: Array = room_action_button_layout()
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

func room_action_angle_near_reference(angle: float, reference: float) -> float:
	return reference + wrapf(angle - reference, -PI, PI)

func room_action_button_screen_center(button_data: Dictionary) -> Vector2:
	var menu_center: Vector2 = room_action_menu_screen_center()
	var angle: float = float(button_data.get("angle", 0.0))
	return menu_center + Vector2(cos(angle), sin(angle)) * ROOM_ACTION_LABEL_RADIUS * room_action_overlay_scale()

func room_action_button_at_screen_position(screen_position: Vector2) -> String:
	if room_action_menu.is_empty():
		return ""
	var menu_center: Vector2 = room_action_menu_screen_center()
	var offset: Vector2 = screen_position - menu_center
	if offset.length() < ROOM_ACTION_DEADZONE_RADIUS * room_action_overlay_scale():
		return ""
	var pointer_angle: float = offset.angle()
	for sector_data_variant in room_action_sector_layout():
		var sector_data: Dictionary = sector_data_variant
		var center_angle: float = float(sector_data.get("angle", 0.0))
		var local_angle: float = room_action_angle_near_reference(pointer_angle, center_angle)
		if local_angle >= float(sector_data.get("start_angle", center_angle)) and local_angle <= float(sector_data.get("end_angle", center_angle)):
			return String(sector_data.get("id", ""))
	return ""

func room_action_sector_points(center: Vector2, inner_radius: float, outer_radius: float, start_angle: float, end_angle: float, segments: int = 18) -> PackedVector2Array:
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

func handle_room_action_menu_tap(screen_position: Vector2) -> void:
	var action_id: String = room_action_button_at_screen_position(screen_position)
	if action_id == "":
		close_room_action_menu()
		queue_redraw()
		return
	perform_room_action(room_action_menu.get("room", INVALID_ROOM), action_id)

func perform_room_action(room_coord: Vector2i, action_id: String) -> void:
	if room_coord == INVALID_ROOM or not rooms.has(room_coord):
		return
	if not room_action_enabled(room_coord, action_id):
		close_room_action_menu()
		status_message = "That action is unavailable for %s." % room_title(room_coord)
		update_hud()
		queue_redraw()
		return
	selected_room = room_coord
	clear_room_action_menu_pointer()
	match action_id:
		"build_menu":
			room_action_menu["mode"] = "build_kind"
			focus_room_action_menu(room_coord, true)
			status_message = "Choose a build category for %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
		"build_minor_menu":
			room_action_menu["mode"] = "build_minor"
			focus_room_action_menu(room_coord, true)
			status_message = "Choose a minor module for %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
		"build_major_menu":
			room_action_menu["mode"] = "build_major"
			focus_room_action_menu(room_coord, true)
			status_message = "Choose a major module for %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
		"submenu_back":
			room_action_menu["mode"] = "root"
			focus_room_action_menu(room_coord, true)
			status_message = "Room actions for %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
		"submenu_back_build":
			room_action_menu["mode"] = "build_kind"
			focus_room_action_menu(room_coord, true)
			status_message = "Choose a build category for %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
		"light":
			close_room_action_menu()
			request_room_light(room_coord)
		"loot":
			close_room_action_menu()
			request_room_loot(room_coord)
		"build_minor_turret":
			if request_room_construction(room_coord, MINOR_MODULE_TURRET):
				var hero: Variant = selected_hero()
				if hero_ready_for_room_action(hero, room_coord):
					room_action_menu["mode"] = "build_minor"
					focus_room_action_menu(room_coord, true)
					queue_redraw()
				else:
					close_room_action_menu()
			else:
				close_room_action_menu()
		"build_minor_pulse":
			if request_room_construction(room_coord, MINOR_MODULE_PULSE):
				var hero_pulse: Variant = selected_hero()
				if hero_ready_for_room_action(hero_pulse, room_coord):
					room_action_menu["mode"] = "build_minor"
					focus_room_action_menu(room_coord, true)
					queue_redraw()
				else:
					close_room_action_menu()
			else:
				close_room_action_menu()
		"build_minor_cannon":
			if request_room_construction(room_coord, MINOR_MODULE_CANNON):
				var hero_cannon: Variant = selected_hero()
				if hero_ready_for_room_action(hero_cannon, room_coord):
					room_action_menu["mode"] = "build_minor"
					focus_room_action_menu(room_coord, true)
					queue_redraw()
				else:
					close_room_action_menu()
			else:
				close_room_action_menu()
		"build_major_food":
			close_room_action_menu()
			request_room_construction(room_coord, MAJOR_MODULE_FOOD)
		"build_major_science":
			close_room_action_menu()
			request_room_construction(room_coord, MAJOR_MODULE_SCIENCE)
		"build_major_industry":
			close_room_action_menu()
			request_room_construction(room_coord, MAJOR_MODULE_INDUSTRY)

func request_room_loot(room_coord: Vector2i) -> void:
	request_room_loot_for_hero(selected_hero_index, room_coord)

func request_room_loot_for_hero(hero_index: int, room_coord: Vector2i) -> void:
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if not rooms.has(room_coord) or not rooms[room_coord]["opened"]:
		return
	if multiplayer_session_active() and not authoritative_simulation_active():
		clear_pending_room_action_request(hero.hero_index)
		pending_room_loot_requests[hero.hero_index] = {
			"room": room_coord,
		}
		server_request_room_loot.rpc_id(NETWORK_HOST_PEER_ID, hero_index, room_coord)
		status_message = "%s moving to loot %s." % [hero.hero_name, room_title(room_coord)]
		update_hud()
		queue_redraw()
		return
	clear_pending_room_action_request(hero.hero_index)
	var command_room: Vector2i = interrupt_hero_orders(hero)
	if command_room == room_coord:
		open_room_loot_inventory(hero, room_coord)
		return
	var path: Array[Vector2i] = find_path(command_room, room_coord, true)
	if path.size() <= 1:
		status_message = "No open route to that room's loot."
		update_hud()
		queue_redraw()
		return
	pending_room_loot_requests[hero.hero_index] = {
		"room": room_coord,
	}
	issue_hero_steps(hero, build_steps_for_path(path, hero.global_position, loot_focus_position(room_coord)))
	status_message = "%s moving to loot %s." % [hero.hero_name, room_title(room_coord)]
	update_hud()
	queue_redraw()

func hero_ready_for_room_action(hero: Variant, room_coord: Vector2i) -> bool:
	return hero != null and is_instance_valid(hero) and rooms.has(room_coord) and hero.current_room == room_coord and hero.pending_room == Hero.INVALID_ROOM and hero.is_idle() and hero.move_steps.is_empty() and room_rect(room_coord).has_point(hero.global_position)

func room_action_staging_position(room_coord: Vector2i) -> Vector2:
	return room_walkable_center(room_coord)

func request_deferred_room_action(room_coord: Vector2i, kind: String, module_type: String = "") -> bool:
	return request_deferred_room_action_for_hero(selected_hero_index, room_coord, kind, module_type)

func request_deferred_room_action_for_hero(hero_index: int, room_coord: Vector2i, kind: String, module_type: String = "") -> bool:
	if hero_index < 0 or hero_index >= heroes.size():
		return false
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not rooms.has(room_coord) or not rooms[room_coord]["opened"]:
		return false
	clear_pending_room_loot_request(hero.hero_index)
	clear_pending_room_action_request(hero.hero_index)
	var command_room: Vector2i = interrupt_hero_orders(hero)
	pending_room_action_requests[hero.hero_index] = {
		"room": room_coord,
		"kind": kind,
		"module_type": module_type,
	}
	var target_position: Vector2 = room_action_staging_position(room_coord)
	if command_room == room_coord:
		issue_hero_steps(hero, build_steps_for_path([room_coord], hero.global_position, target_position))
	else:
		var path: Array[Vector2i] = find_path(command_room, room_coord, true)
		if path.size() <= 1:
			clear_pending_room_action_request(hero.hero_index)
			status_message = "No open route to %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
			return false
		issue_hero_steps(hero, build_steps_for_path(path, hero.global_position, target_position))
	var action_label: String = "light %s" % room_title(room_coord) if kind == "light" else "build in %s" % room_title(room_coord)
	status_message = "%s moving to %s." % [hero.hero_name, action_label]
	update_hud()
	queue_redraw()
	return true

func request_deferred_room_card_for_hero(hero_index: int, room_coord: Vector2i, target_room: Vector2i, card_uid: int, target_world_position: Vector2) -> bool:
	if hero_index < 0 or hero_index >= heroes.size():
		return false
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not rooms.has(room_coord) or not rooms[room_coord]["opened"]:
		return false
	clear_pending_room_loot_request(hero.hero_index)
	clear_pending_room_action_request(hero.hero_index)
	var command_room: Vector2i = interrupt_hero_orders(hero)
	pending_room_action_requests[hero.hero_index] = {
		"room": room_coord,
		"target_room": target_room,
		"kind": "card",
		"card_uid": card_uid,
		"target_world_position": target_world_position,
	}
	if command_room == room_coord:
		var current_position_target: Vector2 = card_cast_staging_position(room_coord, target_room, hand_card_by_uid(hero, card_uid), target_world_position)
		if current_position_target == Vector2.INF:
			clear_pending_room_action_request(hero.hero_index)
			status_message = "No line of effect to %s." % room_title(target_room)
			update_hud()
			queue_redraw()
			return false
		if hero.current_room == room_coord and hero.global_position.distance_to(current_position_target) > 22.0:
			issue_hero_steps(hero, build_steps_for_path([room_coord], hero.global_position, current_position_target))
		else:
			hero.move_steps.clear()
	else:
		var hand_card: Dictionary = hand_card_by_uid(hero, card_uid)
		var target_position: Vector2 = card_cast_staging_position(room_coord, target_room, hand_card, target_world_position)
		if target_position == Vector2.INF:
			clear_pending_room_action_request(hero.hero_index)
			status_message = "No line of effect to %s." % room_title(target_room)
			update_hud()
			queue_redraw()
			return false
		var path: Array[Vector2i] = find_path(command_room, room_coord, true)
		if path.size() <= 1:
			clear_pending_room_action_request(hero.hero_index)
			status_message = "No open route to %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
			return false
		issue_hero_steps(hero, build_steps_for_path(path, hero.global_position, target_position))
	status_message = "%s moving to cast into %s." % [hero.hero_name, room_title(target_room)]
	update_hud()
	queue_redraw()
	return true

func request_room_light(room_coord: Vector2i) -> bool:
	return request_room_light_for_hero(selected_hero_index, room_coord)

func request_room_light_for_hero(hero_index: int, room_coord: Vector2i) -> bool:
	if hero_index < 0 or hero_index >= heroes.size():
		return false
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return false
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_room_light.rpc_id(NETWORK_HOST_PEER_ID, hero_index, room_coord)
		status_message = "%s moving to light %s." % [hero.hero_name, room_title(room_coord)]
		update_hud()
		queue_redraw()
		return true
	if hero_ready_for_room_action(hero, room_coord):
		toggle_room_light(room_coord)
		return true
	return request_deferred_room_action_for_hero(hero_index, room_coord, "light")

func request_room_construction(room_coord: Vector2i, module_type: String) -> bool:
	return request_room_construction_for_hero(selected_hero_index, room_coord, module_type)

func request_room_construction_for_hero(hero_index: int, room_coord: Vector2i, module_type: String) -> bool:
	if hero_index < 0 or hero_index >= heroes.size():
		return false
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return false
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_room_construction.rpc_id(NETWORK_HOST_PEER_ID, hero_index, room_coord, module_type)
		status_message = "%s moving to build in %s." % [hero.hero_name, room_title(room_coord)]
		update_hud()
		queue_redraw()
		return true
	if hero_ready_for_room_action(hero, room_coord):
		return queue_room_construction(room_coord, module_type)
	return request_deferred_room_action_for_hero(hero_index, room_coord, "build", module_type)

func loot_focus_position(room_coord: Vector2i) -> Vector2:
	if rooms.has(room_coord) and not rooms[room_coord]["ground_items"].is_empty():
		return clamp_point_to_room(Vector2(rooms[room_coord]["ground_items"][0]["position"]), room_coord)
	return room_walkable_center(room_coord)

func room_action_enabled(room_coord: Vector2i, action_id: String) -> bool:
	match action_id:
		"light":
			return can_toggle_light(room_coord)
		"build_menu":
			return can_open_build_for_room(room_coord)
		"build_minor_menu":
			return can_open_build_for_room(room_coord)
		"build_major_menu":
			return can_open_build_for_room(room_coord)
		"build_minor_turret":
			return can_build_or_repair_turret(room_coord)
		"build_minor_pulse":
			return can_build_or_repair_turret(room_coord)
		"build_minor_cannon":
			return can_build_or_repair_turret(room_coord)
		"build_major_food":
			return can_build_or_repair_major(room_coord, MAJOR_MODULE_FOOD)
		"build_major_science":
			return can_build_or_repair_major(room_coord, MAJOR_MODULE_SCIENCE)
		"build_major_industry":
			return can_build_or_repair_major(room_coord, MAJOR_MODULE_INDUSTRY)
		"submenu_back", "submenu_back_build":
			return true
		"loot":
			return rooms.has(room_coord) and rooms[room_coord]["opened"]
		_:
			return false

func build_menu_contains_screen_position(screen_position: Vector2) -> bool:
	return build_menu.visible and build_menu.get_global_rect().has_point(screen_position)

func is_valid_build_target_tap(world_position: Vector2) -> bool:
	if pending_build_type == "":
		return false
	var tapped_room: Vector2i = room_at_world_position(world_position)
	if tapped_room == INVALID_ROOM or not can_manage_modules(tapped_room):
		return false
	if pending_build_type == MINOR_MODULE_TURRET:
		return minor_slot_at_position(tapped_room, world_position) >= 0
	return major_slot_contains_point(tapped_room, world_position)

func start_room_opening(room_coord: Vector2i, from_room: Vector2i) -> void:
	opening_room = room_coord
	opening_origin_room = from_room
	opening_timer_left = DOOR_OPEN_DURATION
	opening_heroes.clear()
	if opening_hero != null and is_instance_valid(opening_hero):
		opening_heroes.append(opening_hero)
	status_message = "Opening %s. Hold for %.1fs." % [room_title(room_coord), DOOR_OPEN_DURATION]
	update_hud()

func advance_room_opening(delta: float) -> void:
	if opening_room == INVALID_ROOM:
		return
	var active_openers: Array = []
	for hero_variant in opening_heroes:
		var hero: Variant = hero_variant
		if hero == null or not is_instance_valid(hero):
			continue
		if hero.current_room == opening_origin_room and hero.pending_room == Hero.INVALID_ROOM and hero.is_idle():
			active_openers.append(hero)
	opening_heroes = active_openers
	var opener_count: int = max(opening_heroes.size(), 1)
	opening_timer_left = maxf(opening_timer_left - delta * float(opener_count), 0.0)
	if opening_timer_left <= 0.0:
		finish_room_opening()
		return
	var progress_ratio: float = 1.0 - (opening_timer_left / DOOR_OPEN_DURATION)
	status_message = "Opening %s from %s. %d%%" % [room_title(opening_room), room_title(opening_origin_room), int(progress_ratio * 100.0)]
	update_hud()

func finish_room_opening() -> void:
	var breached_room: Vector2i = opening_room
	var from_room: Vector2i = opening_origin_room
	var breach_heroes: Array = opening_heroes.duplicate()
	opening_room = INVALID_ROOM
	opening_origin_room = INVALID_ROOM
	opening_hero = null
	opening_timer_left = 0.0
	opening_heroes.clear()
	open_room(breached_room)
	for breach_hero_variant in breach_heroes:
		var breach_hero: Variant = breach_hero_variant
		if breach_hero != null and is_instance_valid(breach_hero):
			issue_hero_steps(breach_hero, [
				make_hero_step(breached_room, doorway_position(breached_room, from_room)),
			])
	update_hud()

func advance_temporary_room_lights(turn_count: int = 1) -> void:
	if turn_count <= 0:
		return
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if int(room.get("temporary_light_turns", 0)) <= 0:
			continue
		var remaining_turns: int = max(0, int(room.get("temporary_light_turns", 0)) - turn_count)
		room["temporary_light_turns"] = remaining_turns
	refresh_room_lighting_states()

func open_room(room_coord: Vector2i) -> void:
	if rooms[room_coord]["opened"]:
		return
	advance_temporary_room_lights(1)
	var room: Dictionary = rooms[room_coord]
	room["opened"] = true
	opened_rooms += 1
	doors_opened += 1
	resolve_spell_scroll_studies()
	expire_door_turn_hand_cards()
	advance_item_door_card_generators(1)
	advance_hero_builtin_door_card_generators(1)
	apply_portable_item_effects_on_door_open()
	var door_reward: Dictionary = calculate_door_rewards()
	food += int(door_reward["food"])
	industry += int(door_reward["industry"])
	science += int(door_reward["science"])
	var dust_reward: int = 0
	if rng.randf() < 0.35:
		dust += 1
		dust_reward = 1
	if room_coord != crystal_room:
		spawn_ground_loot(room_coord)
	spawn_door_reward_texts(room_coord, door_reward, dust_reward)
	refresh_camera_bounds()
	invalidate_static_dungeon_layer()
	door_wave_auto_heal_pending = true
	launch_wave(room_coord)
	status_message = "Opened %s. +%d food, +%d industry, +%d science." % [room_title(room_coord), int(door_reward["food"]), int(door_reward["industry"]), int(door_reward["science"])]
	if dust_reward > 0:
		status_message += " +1 dust."
	if room_coord == exit_room:
		status_message += " Exit discovered."

func calculate_door_rewards() -> Dictionary:
	var food_reward: int = DOOR_REWARD_FOOD_BASE
	var industry_reward: int = DOOR_REWARD_INDUSTRY_BASE
	var science_reward: int = DOOR_REWARD_SCIENCE_BASE
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if not room["opened"] or not room["lit"]:
			continue
		match String(room["major_module_type"]):
			MAJOR_MODULE_FOOD:
				if float(room["major_health"]) > 0.0 and not bool(room.get("major_under_construction", false)):
					food_reward += DOOR_REWARD_FOOD_MODULE
			MAJOR_MODULE_SCIENCE:
				if float(room["major_health"]) > 0.0 and not bool(room.get("major_under_construction", false)):
					science_reward += DOOR_REWARD_SCIENCE_MODULE
			MAJOR_MODULE_INDUSTRY:
				if float(room["major_health"]) > 0.0 and not bool(room.get("major_under_construction", false)):
					industry_reward += DOOR_REWARD_INDUSTRY_MODULE
	return {
		"food": food_reward,
		"industry": industry_reward,
		"science": science_reward,
	}

func spawn_door_reward_texts(room_coord: Vector2i, door_reward: Dictionary, dust_reward: int) -> void:
	var popup_entries: Array = [
		{"text": "+%d Food" % int(door_reward.get("food", 0)), "color": Color("9ee28b"), "offset": Vector2(-84.0, -14.0)},
		{"text": "+%d Ind" % int(door_reward.get("industry", 0)), "color": Color("f1c26b"), "offset": Vector2(0.0, -30.0)},
		{"text": "+%d Sci" % int(door_reward.get("science", 0)), "color": Color("8bc1ff"), "offset": Vector2(84.0, -14.0)},
	]
	if dust_reward > 0:
		popup_entries.append({"text": "+%d Dust" % dust_reward, "color": Color("f3d88f"), "offset": Vector2(0.0, 12.0)})
	var anchor: Vector2 = room_walkable_center(room_coord)
	for popup_entry_variant in popup_entries:
		var popup_entry: Dictionary = popup_entry_variant
		add_resource_floating_text(anchor + Vector2(popup_entry.get("offset", Vector2.ZERO)), String(popup_entry.get("text", "")), popup_entry.get("color", Color.WHITE))

func add_resource_floating_text(world_position: Vector2, popup_text: String, popup_color: Color) -> void:
	floating_resource_texts.append({
		"position": world_position,
		"text": popup_text,
		"color": popup_color,
		"timer_left": RESOURCE_FLOAT_DURATION,
	})

func advance_floating_resource_texts(delta: float) -> void:
	var active_popups: Array = []
	for popup_variant in floating_resource_texts:
		var popup: Dictionary = popup_variant
		popup["timer_left"] = maxf(float(popup.get("timer_left", 0.0)) - delta, 0.0)
		if float(popup["timer_left"]) > 0.0:
			active_popups.append(popup)
	floating_resource_texts = active_popups

func draw_floating_resource_texts() -> void:
	var view_rect: Rect2 = current_view_world_rect(96.0)
	for popup_variant in floating_resource_texts:
		var popup: Dictionary = popup_variant
		var duration: float = maxf(RESOURCE_FLOAT_DURATION, 0.001)
		var life_ratio: float = clampf(1.0 - (float(popup.get("timer_left", 0.0)) / duration), 0.0, 1.0)
		var rise_ratio: float = 1.0 - pow(1.0 - life_ratio, 2.0)
		var fade_ratio: float = clampf(1.0 - maxf(life_ratio - 0.45, 0.0) / 0.55, 0.0, 1.0)
		var popup_position: Vector2 = Vector2(popup.get("position", Vector2.ZERO)) + Vector2(0.0, -RESOURCE_FLOAT_RISE * rise_ratio)
		if not view_rect.has_point(popup_position):
			continue
		var popup_color: Color = popup.get("color", Color.WHITE)
		popup_color.a = 0.22 + 0.78 * fade_ratio
		var shadow_color: Color = Color(0.02, 0.06, 0.08, 0.55 * fade_ratio)
		draw_string(ThemeDB.fallback_font, popup_position + Vector2(2.0, 2.0), String(popup.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 110.0, 20, shadow_color)
		draw_string(ThemeDB.fallback_font, popup_position, String(popup.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 110.0, 20, popup_color)

func launch_wave(entered_room: Vector2i) -> void:
	var dark_rooms: Array[Vector2i] = []
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if room_coord == crystal_room or not room["opened"] or room["lit"]:
			continue
		dark_rooms.append(room_coord)
	if dark_rooms.is_empty():
		door_wave_auto_heal_pending = false
		door_wave_healing_active = true
		status_message = "Opened a lit frontier. No dark room was available for a wave."
		update_hud()
		return
	wave_index += 1
	var spawn_room_count: int = mini(1 + int(floor(float(max(wave_index - 1, 0)) / 2.0)), dark_rooms.size())
	var total_enemies: int = mini(4 + wave_index, 12)
	var chosen_rooms: Array[Vector2i] = []
	while chosen_rooms.size() < spawn_room_count and not dark_rooms.is_empty():
		var room_index: int = rng.randi_range(0, dark_rooms.size() - 1)
		chosen_rooms.append(dark_rooms[room_index])
		dark_rooms.remove_at(room_index)
	var delayed_room_order: int = 0
	for spawn_index in range(chosen_rooms.size()):
		var room_coord: Vector2i = chosen_rooms[spawn_index]
		var enemy_count: int = maxi(1, int(floor(float(total_enemies) / float(chosen_rooms.size()))))
		if spawn_index < total_enemies % chosen_rooms.size():
			enemy_count += 1
		var immediate: bool = room_coord == entered_room
		queue_wave_spawn(room_coord, enemy_count, immediate, delayed_room_order)
		if not immediate:
			delayed_room_order += 1
	status_message = "Wave %d emerged from %d dark room%s." % [wave_index, chosen_rooms.size(), "" if chosen_rooms.size() == 1 else "s"]
	update_hud()

func queue_wave_spawn(room_coord: Vector2i, count: int, immediate: bool, spawn_order: int) -> void:
	if not rooms.has(room_coord):
		return
	var spawn_plan: Array[String] = build_enemy_spawn_plan(count, false)
	if spawn_plan.is_empty():
		return
	if immediate:
		for enemy_type in spawn_plan:
			spawn_wave_enemy(room_coord, enemy_type)
		return
	var room_delay: float = 0.0 if immediate else WAVE_WARNING_DURATION + float(spawn_order) * WAVE_STAGGER_ROOM_INTERVAL
	rooms[room_coord]["warning_timer_left"] = room_delay
	pending_enemy_spawns.append({
		"room": room_coord,
		"remaining": spawn_plan.size(),
		"delay_left": room_delay,
		"interval": WAVE_STAGGER_ENEMY_INTERVAL,
		"total_count": spawn_plan.size(),
		"spawned": 0,
		"plan": spawn_plan,
	})

func advance_pending_enemy_spawns(delta: float) -> void:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		rooms[room_coord]["warning_timer_left"] = maxf(float(rooms[room_coord].get("warning_timer_left", 0.0)) - delta, 0.0)
	var active_spawns: Array = []
	for pending_spawn in pending_enemy_spawns:
		pending_spawn["delay_left"] = float(pending_spawn["delay_left"]) - delta
		while int(pending_spawn["remaining"]) > 0 and float(pending_spawn["delay_left"]) <= 0.0:
			var plan: Array = Array(pending_spawn.get("plan", []))
			var spawn_index: int = int(pending_spawn.get("spawned", 0))
			if spawn_index < 0 or spawn_index >= plan.size():
				break
			spawn_wave_enemy(Vector2i(pending_spawn["room"]), String(plan[spawn_index]))
			pending_spawn["spawned"] = int(pending_spawn["spawned"]) + 1
			pending_spawn["remaining"] = int(pending_spawn["remaining"]) - 1
			pending_spawn["delay_left"] = float(pending_spawn["delay_left"]) + float(pending_spawn["interval"])
		if int(pending_spawn["remaining"]) > 0:
			active_spawns.append(pending_spawn)
	pending_enemy_spawns = active_spawns

func advance_crystal_pressure(delta: float) -> void:
	if crystal_holder == null or not is_instance_valid(crystal_holder):
		return
	crystal_pressure_timer_left = maxf(crystal_pressure_timer_left - delta, 0.0)
	if crystal_pressure_timer_left > 0.0:
		return
	crystal_pressure_timer_left = CRYSTAL_PRESSURE_INTERVAL
	trigger_crystal_pressure()

func trigger_crystal_pressure() -> void:
	var dark_rooms: Array[Vector2i] = []
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if room_coord == crystal_room or not room["opened"] or room["lit"]:
			continue
		dark_rooms.append(room_coord)
	if dark_rooms.is_empty():
		return
	for room_coord in dark_rooms:
		queue_pressure_spawn(room_coord, CRYSTAL_PRESSURE_ENEMIES_PER_ROOM + int(floor(float(max(floor_index - 1, 0)) / 2.0)))
	status_message = "The crystal agitates %d dark room%s." % [dark_rooms.size(), "" if dark_rooms.size() == 1 else "s"]
	update_hud()

func queue_pressure_spawn(room_coord: Vector2i, count: int) -> void:
	if not rooms.has(room_coord) or count <= 0:
		return
	var spawn_plan: Array[String] = build_enemy_spawn_plan(count, true)
	if spawn_plan.is_empty():
		return
	rooms[room_coord]["warning_timer_left"] = maxf(float(rooms[room_coord].get("warning_timer_left", 0.0)), CRYSTAL_PRESSURE_WARNING_DURATION)
	pending_enemy_spawns.append({
		"room": room_coord,
		"remaining": spawn_plan.size(),
		"delay_left": CRYSTAL_PRESSURE_WARNING_DURATION,
		"interval": WAVE_STAGGER_ENEMY_INTERVAL,
		"total_count": spawn_plan.size(),
		"spawned": 0,
		"plan": spawn_plan,
	})

func enemy_wave_size(enemy_type: String) -> int:
	match enemy_type:
		ENEMY_TYPE_LIZARDMAN:
			return 1
		ENEMY_TYPE_GOBLIN:
			return 5
		ENEMY_TYPE_KOBOLD:
			return 3
		ENEMY_TYPE_GOLEM:
			return 1
		ENEMY_TYPE_GOBLIN_SHAMAN:
			return 2
		_:
			return 1

func enemy_spawn_weight(enemy_type: String, pressure_spawn: bool = false) -> float:
	match enemy_type:
		ENEMY_TYPE_LIZARDMAN:
			return 1.6 if not pressure_spawn else 1.2
		ENEMY_TYPE_GOBLIN:
			return 3.8 if not pressure_spawn else 2.4
		ENEMY_TYPE_KOBOLD:
			return 3.0 if not pressure_spawn else 3.8
		ENEMY_TYPE_GOLEM:
			return 1.0 if not pressure_spawn else 0.8
		ENEMY_TYPE_GOBLIN_SHAMAN:
			return 1.4 if not pressure_spawn else 1.1
		_:
			return 1.0

func weighted_enemy_type_choice(candidates: Array[String], pressure_spawn: bool = false) -> String:
	if candidates.is_empty():
		return ENEMY_TYPE_GOBLIN
	var total_weight: float = 0.0
	for enemy_type in candidates:
		total_weight += enemy_spawn_weight(enemy_type, pressure_spawn)
	var roll: float = rng.randf() * maxf(total_weight, 0.001)
	for enemy_type in candidates:
		roll -= enemy_spawn_weight(enemy_type, pressure_spawn)
		if roll <= 0.0:
			return enemy_type
	return candidates[candidates.size() - 1]

func build_enemy_spawn_plan(budget: int, pressure_spawn: bool = false) -> Array[String]:
	var remaining: int = maxi(1, budget)
	var plan: Array[String] = []
	while remaining > 0:
		var candidates: Array[String] = []
		for enemy_type in [ENEMY_TYPE_GOBLIN, ENEMY_TYPE_KOBOLD, ENEMY_TYPE_GOBLIN_SHAMAN, ENEMY_TYPE_LIZARDMAN, ENEMY_TYPE_GOLEM]:
			if enemy_wave_size(enemy_type) <= remaining:
				candidates.append(enemy_type)
		if candidates.is_empty():
			candidates = [ENEMY_TYPE_LIZARDMAN, ENEMY_TYPE_GOLEM]
		var chosen_type: String = weighted_enemy_type_choice(candidates, pressure_spawn)
		var pack_size: int = mini(enemy_wave_size(chosen_type), remaining)
		for _pack_index in range(pack_size):
			plan.append(chosen_type)
		remaining -= pack_size
	return plan

func spawn_wave(room_coord: Vector2i, count: int) -> void:
	var spawn_plan: Array[String] = build_enemy_spawn_plan(count, false)
	for enemy_type in spawn_plan:
		spawn_wave_enemy(room_coord, enemy_type)

func spawn_wave_enemy(room_coord: Vector2i, enemy_type: String) -> void:
	var enemy: Variant = ENEMY_SCENE.instantiate()
	enemy_layer.add_child(enemy)
	enemy.enemy_uid = next_enemy_uid
	next_enemy_uid += 1
	var spawn_position: Vector2 = random_walkable_point(room_coord)
	enemy.global_position = spawn_position
	enemy.reset_physics_interpolation()
	enemy.set_role(enemy_type)
	enemy.current_room = room_coord
	enemy.previous_room = room_coord
	enemy.next_room = room_coord
	enemy.set_destination(spawn_position)
	enemies.append(enemy)

func issue_enemy_steps(enemy: Variant, steps: Array) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	enemy.move_steps.clear()
	for step in steps:
		enemy.move_steps.append(step)

func enemy_move_plan_matches(enemy: Variant, target_room: Vector2i, target_position: Vector2) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.move_steps.is_empty():
		return false
	var final_step: Dictionary = enemy.move_steps[enemy.move_steps.size() - 1]
	if Vector2i(final_step.get("room", INVALID_ROOM)) != target_room:
		return false
	var planned_position: Vector2 = Vector2(final_step.get("position", Vector2.INF))
	var desired_position: Vector2 = clamp_point_to_room(target_position, target_room)
	return planned_position != Vector2.INF and planned_position.distance_squared_to(desired_position) <= 196.0

func issue_hero_steps(hero: Variant, steps: Array) -> void:
	hero.move_steps.clear()
	hero.player_command_locked = not steps.is_empty()
	for step in steps:
		hero.move_steps.append(step)

func active_hero_room_for_commands(hero: Variant) -> Vector2i:
	if hero.pending_room == Hero.INVALID_ROOM:
		return hero.current_room
	var current_distance: float = hero.global_position.distance_to(room_center(hero.current_room))
	var pending_distance: float = hero.global_position.distance_to(room_center(hero.pending_room))
	if pending_distance + 24.0 < current_distance:
		return hero.pending_room
	return hero.current_room

func interrupt_hero_orders(hero: Variant) -> Vector2i:
	var command_room: Vector2i = active_hero_room_for_commands(hero)
	clear_pending_room_loot_request(hero.hero_index)
	clear_pending_room_action_request(hero.hero_index)
	hero.move_steps.clear()
	hero.player_command_locked = false
	opening_heroes.erase(hero)
	if opening_hero == hero:
		opening_hero = opening_heroes[0] if not opening_heroes.is_empty() else null
	if opening_room != INVALID_ROOM and opening_heroes.is_empty():
		opening_room = INVALID_ROOM
		opening_origin_room = INVALID_ROOM
		opening_hero = null
		opening_timer_left = 0.0
	hero.pending_open_room = Hero.INVALID_ROOM
	hero.pending_open_origin_room = Hero.INVALID_ROOM
	hero.pending_room = Hero.INVALID_ROOM
	hero.current_room = command_room
	hero.set_destination(hero.global_position)
	return command_room

func hero_has_locked_player_command(hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if bool(hero.player_command_locked):
		return true
	if pending_room_action_requests.has(hero.hero_index) or pending_room_loot_requests.has(hero.hero_index):
		return true
	if hero.pending_room != Hero.INVALID_ROOM or hero.pending_open_room != Hero.INVALID_ROOM or not hero.move_steps.is_empty():
		return true
	return opening_hero == hero or opening_heroes.has(hero)

func release_finished_player_command(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero) or not bool(hero.player_command_locked):
		return
	if pending_room_action_requests.has(hero.hero_index) or pending_room_loot_requests.has(hero.hero_index):
		return
	if hero.pending_room != Hero.INVALID_ROOM or hero.pending_open_room != Hero.INVALID_ROOM or not hero.move_steps.is_empty():
		return
	if opening_hero == hero or opening_heroes.has(hero):
		return
	if not hero.is_idle():
		return
	hero.player_command_locked = false

func pause_autonomous_heroes_for_hand_drag() -> void:
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		if hero_has_locked_player_command(hero):
			continue
		hero.set_destination(hero.global_position)

func make_hero_step(room_coord: Vector2i, world_position: Vector2) -> Dictionary:
	return {
		"room": room_coord,
		"position": world_position,
	}

func room_nav_fallback_points(room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> Array:
	var clamped_start: Vector2 = clamp_point_to_room(start_position, room_coord)
	var clamped_target: Vector2 = clamp_point_to_room(target_position, room_coord)
	var walkable_regions: Array = room_walkable_regions(room_coord, 0.0)
	if walkable_regions.is_empty():
		return [clamped_target]
	var start_region_index: int = walkable_region_index_for_point(room_coord, clamped_start, 0.0)
	var target_region_index: int = walkable_region_index_for_point(room_coord, clamped_target, 0.0)
	if start_region_index < 0 or target_region_index < 0 or start_region_index == target_region_index:
		return [clamped_target]
	var primary_region: Rect2 = largest_region_rect(walkable_regions)
	var points: Array = []
	if not primary_region.has_point(clamped_start):
		points.append(closest_point_in_rect(clamped_start, primary_region))
	if not primary_region.has_point(clamped_target):
		var bridge_target: Vector2 = closest_point_in_rect(clamped_target, primary_region)
		if points.is_empty() or Vector2(points[points.size() - 1]).distance_squared_to(bridge_target) > 16.0:
			points.append(bridge_target)
	if points.is_empty() or Vector2(points[points.size() - 1]).distance_squared_to(clamped_target) > 16.0:
		points.append(clamped_target)
	return points

func room_nav_data(room_coord: Vector2i) -> Dictionary:
	if room_nav_cache.has(room_coord):
		return room_nav_cache[room_coord]
	var walkable_regions: Array = room_walkable_regions(room_coord, 0.0)
	if walkable_regions.is_empty():
		room_nav_cache[room_coord] = {}
		return {}
	var bounds: Rect2 = bounding_rect_for_regions(walkable_regions).grow(ROOM_NAV_CELL_SIZE)
	var min_cell: Vector2i = Vector2i(
		int(floor(bounds.position.x / ROOM_NAV_CELL_SIZE)),
		int(floor(bounds.position.y / ROOM_NAV_CELL_SIZE))
	)
	var max_cell: Vector2i = Vector2i(
		int(ceil(bounds.end.x / ROOM_NAV_CELL_SIZE)),
		int(ceil(bounds.end.y / ROOM_NAV_CELL_SIZE))
	)
	var grid_size: Vector2i = Vector2i.ONE + (max_cell - min_cell)
	var astar: AStarGrid2D = AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, grid_size)
	astar.cell_size = Vector2.ONE * ROOM_NAV_CELL_SIZE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	var walkable_cells: Array = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var local_cell: Vector2i = Vector2i(x, y)
			var world_rect: Rect2 = Rect2(Vector2(min_cell + local_cell) * ROOM_NAV_CELL_SIZE, Vector2.ONE * ROOM_NAV_CELL_SIZE)
			var is_walkable: bool = room_walkable_contains_point(room_coord, world_rect.get_center(), ROOM_NAV_WALKABLE_MARGIN)
			astar.set_point_solid(local_cell, not is_walkable)
			if is_walkable:
				walkable_cells.append(local_cell)
	var nav_data_value: Dictionary = {
		"astar": astar,
		"origin_cell": min_cell,
		"grid_size": grid_size,
		"walkable_cells": walkable_cells,
	}
	room_nav_cache[room_coord] = nav_data_value
	return nav_data_value

func room_nav_cell_rect(nav_data: Dictionary, local_cell: Vector2i) -> Rect2:
	var origin_cell: Vector2i = nav_data.get("origin_cell", Vector2i.ZERO)
	return Rect2(Vector2(origin_cell + local_cell) * ROOM_NAV_CELL_SIZE, Vector2.ONE * ROOM_NAV_CELL_SIZE)

func room_nav_local_cell_for_world(nav_data: Dictionary, world_position: Vector2) -> Vector2i:
	var origin_cell: Vector2i = nav_data.get("origin_cell", Vector2i.ZERO)
	var world_cell: Vector2i = Vector2i(
		int(floor(world_position.x / ROOM_NAV_CELL_SIZE)),
		int(floor(world_position.y / ROOM_NAV_CELL_SIZE))
	)
	return world_cell - origin_cell

func room_nav_is_local_cell_in_bounds(nav_data: Dictionary, local_cell: Vector2i) -> bool:
	var grid_size: Vector2i = nav_data.get("grid_size", Vector2i.ZERO)
	return Rect2i(Vector2i.ZERO, grid_size).has_point(local_cell)

func nearest_walkable_room_nav_cell(nav_data: Dictionary, world_position: Vector2) -> Vector2i:
	if nav_data.is_empty():
		return Vector2i(-1, -1)
	var astar: AStarGrid2D = nav_data.get("astar", null)
	if astar == null:
		return Vector2i(-1, -1)
	var local_cell: Vector2i = room_nav_local_cell_for_world(nav_data, world_position)
	if room_nav_is_local_cell_in_bounds(nav_data, local_cell) and not astar.is_point_solid(local_cell):
		return local_cell
	var walkable_cells: Array = nav_data.get("walkable_cells", [])
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_distance_squared: float = INF
	for cell_variant in walkable_cells:
		var candidate_cell: Vector2i = cell_variant
		var candidate_center: Vector2 = room_nav_cell_rect(nav_data, candidate_cell).get_center()
		var distance_squared: float = candidate_center.distance_squared_to(world_position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_cell = candidate_cell
	return best_cell

func room_nav_point_for_cell(nav_data: Dictionary, local_cell: Vector2i, preferred_position: Vector2) -> Vector2:
	return closest_point_in_rect(preferred_position, room_nav_cell_rect(nav_data, local_cell))

func room_nav_segment_is_walkable(room_coord: Vector2i, start_position: Vector2, end_position: Vector2) -> bool:
	var distance: float = start_position.distance_to(end_position)
	if distance <= 1.0:
		return room_walkable_contains_point(room_coord, end_position, ROOM_NAV_WALKABLE_MARGIN)
	var sample_count: int = maxi(int(ceil(distance / maxf(ROOM_NAV_CELL_SIZE * 0.45, 4.0))), 1)
	for sample_index in range(sample_count + 1):
		var t: float = float(sample_index) / float(sample_count)
		var sample_point: Vector2 = start_position.lerp(end_position, t)
		if not room_walkable_contains_point(room_coord, sample_point, ROOM_NAV_WALKABLE_MARGIN):
			return false
	return true

func smooth_room_navigation_points(room_coord: Vector2i, points: Array) -> Array:
	if points.size() <= 2:
		return points.duplicate()
	var smoothed: Array = []
	var anchor_point: Vector2 = points[0]
	var next_index: int = 1
	while next_index < points.size():
		var furthest_index: int = next_index
		for test_index in range(next_index + 1, points.size()):
			if not room_nav_segment_is_walkable(room_coord, anchor_point, Vector2(points[test_index])):
				break
			furthest_index = test_index
		var chosen_point: Vector2 = points[furthest_index]
		smoothed.append(chosen_point)
		anchor_point = chosen_point
		next_index = furthest_index + 1
	return smoothed

func simplify_room_navigation_points(points: Array) -> Array:
	if points.size() <= 2:
		return points.duplicate()
	var simplified: Array = [points[0]]
	var previous_direction: Vector2 = Vector2.ZERO
	for index in range(1, points.size()):
		var current_point: Vector2 = points[index]
		var previous_point: Vector2 = simplified[simplified.size() - 1]
		var direction: Vector2 = (current_point - previous_point).normalized()
		if index < points.size() - 1 and previous_direction != Vector2.ZERO and absf(direction.dot(previous_direction)) > 0.995:
			simplified[simplified.size() - 1] = current_point
		else:
			simplified.append(current_point)
		previous_direction = direction
	return simplified

func room_navigation_points(room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> Array:
	var clamped_start: Vector2 = clamp_point_to_room(start_position, room_coord)
	var clamped_target: Vector2 = clamp_point_to_room(target_position, room_coord)
	if clamped_start.distance_squared_to(clamped_target) <= 16.0:
		return [clamped_target]
	var nav_data: Dictionary = room_nav_data(room_coord)
	if nav_data.is_empty():
		return room_nav_fallback_points(room_coord, clamped_start, clamped_target)
	var astar: AStarGrid2D = nav_data.get("astar", null)
	if astar == null:
		return room_nav_fallback_points(room_coord, clamped_start, clamped_target)
	var start_cell: Vector2i = nearest_walkable_room_nav_cell(nav_data, clamped_start)
	var target_cell: Vector2i = nearest_walkable_room_nav_cell(nav_data, clamped_target)
	if start_cell.x < 0 or target_cell.x < 0:
		return room_nav_fallback_points(room_coord, clamped_start, clamped_target)
	if start_cell == target_cell:
		return [clamped_target]
	var cell_path: Array = astar.get_id_path(start_cell, target_cell)
	if cell_path.is_empty():
		return room_nav_fallback_points(room_coord, clamped_start, clamped_target)
	var raw_points: Array = [clamped_start]
	for path_index in range(1, cell_path.size() - 1):
		var local_cell: Vector2i = cell_path[path_index]
		raw_points.append(room_nav_cell_rect(nav_data, local_cell).get_center())
	raw_points.append(clamped_target)
	var nav_points: Array = smooth_room_navigation_points(room_coord, raw_points)
	if nav_points.is_empty() or Vector2(nav_points[nav_points.size() - 1]).distance_squared_to(clamped_target) > 4.0:
		nav_points.append(clamped_target)
	return simplify_room_navigation_points(nav_points)

func append_room_navigation_steps(steps: Array, room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> void:
	for nav_point_variant in room_navigation_points(room_coord, start_position, target_position):
		var nav_point: Vector2 = nav_point_variant
		if not steps.is_empty():
			var previous_step: Dictionary = steps[steps.size() - 1]
			if Vector2i(previous_step.get("room", INVALID_ROOM)) == room_coord and Vector2(previous_step.get("position", Vector2.INF)).distance_squared_to(nav_point) <= 4.0:
				continue
		steps.append(make_hero_step(room_coord, nav_point))

func build_steps_for_path(path: Array[Vector2i], start_position: Vector2, final_position: Vector2) -> Array:
	var steps: Array = []
	if path.is_empty():
		return steps
	var current_position: Vector2 = start_position
	if current_position == Vector2.INF:
		current_position = room_walkable_center(path[0])
	if path.size() == 1:
		append_room_navigation_steps(steps, path[0], current_position, final_position)
		return steps
	for index in range(path.size() - 1):
		var current_room: Vector2i = path[index]
		var next_room: Vector2i = path[index + 1]
		var exit_position: Vector2 = doorway_position(current_room, next_room)
		append_room_navigation_steps(steps, current_room, current_position, exit_position)
		var entry_position: Vector2 = doorway_position(next_room, current_room)
		steps.append(make_hero_step(next_room, entry_position))
		current_position = entry_position
	var destination_room: Vector2i = path[path.size() - 1]
	append_room_navigation_steps(steps, destination_room, current_position, final_position)
	return steps

func advance_hero_movement() -> void:
	update_selected_hero_flags()
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		if try_execute_pending_room_action_request(hero):
			continue
		if try_open_pending_room_loot_request(hero):
			continue
		if hero.pending_room != Hero.INVALID_ROOM:
			if hero.is_idle():
				hero.current_room = hero.pending_room
				hero.pending_room = Hero.INVALID_ROOM
				if hero == selected_hero():
					selected_room = hero.current_room
			else:
				continue
		if opening_room == INVALID_ROOM and hero.pending_open_room != Hero.INVALID_ROOM and hero.is_idle() and hero.move_steps.is_empty():
			var breach_room: Vector2i = hero.pending_open_room
			var from_room: Vector2i = hero.pending_open_origin_room
			hero.pending_open_room = Hero.INVALID_ROOM
			hero.pending_open_origin_room = Hero.INVALID_ROOM
			opening_hero = hero
			start_room_opening(breach_room, from_room)
			continue
		if opening_room != INVALID_ROOM and hero.pending_open_room == opening_room and hero.pending_open_origin_room == opening_origin_room and hero.is_idle() and hero.move_steps.is_empty():
			hero.pending_open_room = Hero.INVALID_ROOM
			hero.pending_open_origin_room = Hero.INVALID_ROOM
			if not opening_heroes.has(hero):
				opening_heroes.append(hero)
			continue
		if hero.move_steps.is_empty() or not hero.is_idle():
			continue
		var next_step: Dictionary = hero.move_steps[0]
		hero.move_steps.remove_at(0)
		var next_room: Vector2i = next_step["room"]
		var next_position: Vector2 = next_step["position"]
		if next_room != hero.current_room:
			hero.pending_room = next_room
		hero.set_destination(next_position)
	for hero in heroes:
		if is_instance_valid(hero):
			release_finished_player_command(hero)
	refresh_room_lighting_states()

func advance_enemy_routes(delta: float) -> void:
	for enemy in enemies:
		if not enemy_is_active(enemy):
			continue
		enemy.attack_cooldown_left = maxf(enemy.attack_cooldown_left - delta, 0.0)
		if enemy.pending_room != INVALID_ROOM:
			if enemy.is_idle():
				enemy.moving_between_rooms = false
				enemy.previous_room = enemy.current_room
				enemy.current_room = enemy.pending_room
				enemy.pending_room = INVALID_ROOM
			else:
				continue
		var target_room: Vector2i = target_room_for_enemy(enemy)
		if target_room == INVALID_ROOM:
			enemy.move_steps.clear()
			continue
		var target_position: Vector2 = enemy_target_position(enemy)
		if not enemy.is_idle():
			continue
		if enemy.current_room == target_room and enemy.global_position.distance_to(target_position) <= 18.0:
			enemy.move_steps.clear()
			resolve_enemy_attack(enemy)
			continue
		if enemy.move_steps.is_empty() or not enemy_move_plan_matches(enemy, target_room, target_position):
			if enemy.current_room == target_room:
				issue_enemy_steps(enemy, build_steps_for_path([target_room], enemy.global_position, target_position))
			else:
				var path: Array[Vector2i] = find_path(enemy.current_room, target_room, true)
				if path.size() <= 1:
					enemy.move_steps.clear()
					continue
				issue_enemy_steps(enemy, build_steps_for_path(path, enemy.global_position, target_position))
		if enemy.move_steps.is_empty():
			continue
		var next_step: Dictionary = enemy.move_steps[0]
		enemy.move_steps.remove_at(0)
		var next_room: Vector2i = next_step["room"]
		var next_position: Vector2 = next_step["position"]
		if next_room != enemy.current_room:
			enemy.pending_room = next_room
			enemy.next_room = next_room
			enemy.moving_between_rooms = true
		else:
			enemy.next_room = enemy.current_room
			enemy.moving_between_rooms = false
		enemy.set_destination(next_position)

func target_room_for_enemy(enemy: Variant) -> Vector2i:
	match String(enemy.enemy_role):
		ENEMY_TYPE_LIZARDMAN:
			var lizard_target: Variant = lizardman_target_hero(enemy)
			if lizard_target == null:
				return crystal_room
			return hero_room_for_enemy_targeting(lizard_target)
		ENEMY_TYPE_GOBLIN, ENEMY_TYPE_GOBLIN_SHAMAN:
			if not heroes_in_room(enemy.current_room).is_empty():
				return enemy.current_room
			return crystal_room
		ENEMY_TYPE_GOLEM:
			var major_module_room: Vector2i = preferred_golem_major_module_room(enemy)
			if major_module_room != INVALID_ROOM:
				return major_module_room
			return crystal_room
		ENEMY_TYPE_KOBOLD:
			return crystal_room
		_:
			return crystal_room

func enemy_room_goal_position(enemy: Variant, room_coord: Vector2i) -> Vector2:
	var target_room: Vector2i = target_room_for_enemy(enemy)
	if target_room == INVALID_ROOM:
		return clamp_point_to_room(enemy.global_position, room_coord)
	if room_coord == target_room:
		return enemy_target_position(enemy)
	var path: Array[Vector2i] = find_path(room_coord, target_room, true)
	if path.size() > 1:
		return doorway_position(room_coord, path[1])
	return clamp_point_to_room(enemy.global_position, room_coord)

func enemy_target_position(enemy: Variant) -> Vector2:
	match String(enemy.enemy_role):
		ENEMY_TYPE_LIZARDMAN:
			var lizard_target: Variant = lizardman_target_hero(enemy)
			if lizard_target != null and hero_is_in_room(lizard_target, enemy.current_room):
				return lizard_target.global_position
			return clamp_point_to_room(enemy.global_position, enemy.current_room)
		ENEMY_TYPE_GOBLIN, ENEMY_TYPE_GOBLIN_SHAMAN:
			var room_target: Variant = default_room_hero_target(enemy.current_room, enemy.global_position)
			if room_target != null:
				return room_target.global_position
			return crystal_world_position()
		ENEMY_TYPE_GOLEM:
			var major_module_room: Vector2i = preferred_golem_major_module_room(enemy)
			if major_module_room != INVALID_ROOM and major_module_room == enemy.current_room:
				return major_module_target_position(enemy.current_room)
			return crystal_world_position()
		ENEMY_TYPE_KOBOLD:
			return crystal_world_position()
		_:
			return crystal_world_position()

func hero_room_for_enemy_targeting(hero: Variant) -> Vector2i:
	if hero == null or not is_instance_valid(hero):
		return INVALID_ROOM
	if hero.pending_room != Hero.INVALID_ROOM and rooms.has(hero.pending_room) and room_rect(hero.pending_room).has_point(hero.global_position):
		return hero.pending_room
	return hero.current_room

func hero_is_in_room(hero: Variant, room_coord: Vector2i) -> bool:
	return hero_room_for_enemy_targeting(hero) == room_coord

func hero_default_aggro_value(hero: Variant) -> float:
	if hero == null or not is_instance_valid(hero):
		return INF
	var barrier_value: float = maxf(float(hero.barrier_capacity), float(hero.barrier_amount))
	return float(hero.max_health) + barrier_value

func room_path_distance(from_room: Vector2i, to_room: Vector2i) -> int:
	if from_room == to_room:
		return 0
	var path: Array[Vector2i] = find_path(from_room, to_room, true)
	if path.is_empty():
		return 99999
	return maxi(path.size() - 1, 0)

func heroes_in_room(room_coord: Vector2i) -> Array:
	var room_heroes: Array = []
	for hero in heroes:
		if not hero_is_active(hero):
			continue
		if hero_is_in_room(hero, room_coord):
			room_heroes.append(hero)
	return room_heroes

func default_room_hero_target(room_coord: Vector2i, origin: Vector2) -> Variant:
	var chosen_hero: Variant = null
	var chosen_aggro: float = INF
	var chosen_distance: float = INF
	for hero in heroes_in_room(room_coord):
		var aggro_value: float = hero_default_aggro_value(hero)
		var distance_value: float = origin.distance_to(hero.global_position)
		if chosen_hero == null \
		or aggro_value < chosen_aggro - 0.01 \
		or (absf(aggro_value - chosen_aggro) <= 0.01 and distance_value < chosen_distance):
			chosen_hero = hero
			chosen_aggro = aggro_value
			chosen_distance = distance_value
	return chosen_hero

func lizardman_target_hero(enemy: Variant) -> Variant:
	var chosen_hero: Variant = null
	var chosen_path_length: int = 99999
	var chosen_aggro: float = INF
	var chosen_distance: float = INF
	for hero in heroes:
		if not hero_is_active(hero):
			continue
		var candidate_room: Vector2i = hero_room_for_enemy_targeting(hero)
		if candidate_room == INVALID_ROOM:
			continue
		var path_length: int = room_path_distance(enemy.current_room, candidate_room)
		if path_length >= 99999:
			continue
		var aggro_value: float = hero_default_aggro_value(hero)
		var distance_value: float = enemy.global_position.distance_to(hero.global_position)
		if chosen_hero == null \
		or path_length < chosen_path_length \
		or (path_length == chosen_path_length and aggro_value < chosen_aggro - 0.01) \
		or (path_length == chosen_path_length and absf(aggro_value - chosen_aggro) <= 0.01 and distance_value < chosen_distance):
			chosen_hero = hero
			chosen_path_length = path_length
			chosen_aggro = aggro_value
			chosen_distance = distance_value
	return chosen_hero

func module_target_position(room_coord: Vector2i, origin: Vector2) -> Vector2:
	if not rooms.has(room_coord):
		return origin
	var room: Dictionary = rooms[room_coord]
	var candidates: Array[Vector2] = []
	if room["major_module_type"] != "" and float(room["major_health"]) > 0.0:
		candidates.append(major_slot_position(room_coord))
	var slot_positions: Array = minor_slot_positions(room_coord)
	for module_data in room["minor_modules"]:
		if float(module_data["health"]) <= 0.0:
			continue
		var slot_index: int = int(module_data.get("slot_index", -1))
		if slot_index < 0 or slot_index >= slot_positions.size():
			continue
		candidates.append(slot_positions[slot_index])
	if candidates.is_empty():
		return room_walkable_center(room_coord)
	var chosen_position: Vector2 = candidates[0]
	var closest_distance: float = origin.distance_to(chosen_position)
	for candidate in candidates:
		var distance: float = origin.distance_to(candidate)
		if distance < closest_distance:
			closest_distance = distance
			chosen_position = candidate
	return chosen_position

func major_module_target_position(room_coord: Vector2i) -> Vector2:
	if not rooms.has(room_coord):
		return room_walkable_center(room_coord)
	var room: Dictionary = rooms[room_coord]
	if String(room.get("major_module_type", "")) == "" or float(room.get("major_health", 0.0)) <= 0.0:
		return room_walkable_center(room_coord)
	return major_slot_position(room_coord)

func preferred_golem_major_module_room(enemy: Variant) -> Vector2i:
	var module_room: Vector2i = find_nearest_major_module_room(enemy.current_room)
	if module_room == INVALID_ROOM:
		return INVALID_ROOM
	var module_distance: int = room_path_distance(enemy.current_room, module_room)
	var crystal_distance: int = room_path_distance(enemy.current_room, crystal_room)
	if module_distance < crystal_distance:
		return module_room
	return INVALID_ROOM

func resolve_enemy_attack(enemy: Variant) -> void:
	if enemy.attack_cooldown_left > 0.0:
		return
	match String(enemy.enemy_role):
		ENEMY_TYPE_LIZARDMAN:
			var lizard_target: Variant = lizardman_target_hero(enemy)
			if lizard_target == null or not hero_is_in_room(lizard_target, enemy.current_room):
				return
			enemy.trigger_attack(lizard_target.global_position)
			if try_auto_cast_fatal_shield(lizard_target, enemy.attack_damage):
				enemy.attack_cooldown_left = enemy.attack_cooldown
				update_hud()
				return
			var lizard_killed: bool = lizard_target.take_damage(enemy.attack_damage)
			if lizard_killed:
				finalize_hero_death(lizard_target, "A lizardman")
			else:
				apply_weighted_melee_knockback(enemy, lizard_target, enemy.current_room)
				status_message = "A lizardman is attacking %s." % lizard_target.hero_name
		ENEMY_TYPE_GOBLIN:
			var goblin_target: Variant = default_room_hero_target(enemy.current_room, enemy.global_position)
			if goblin_target != null:
				enemy.trigger_attack(goblin_target.global_position)
				if try_auto_cast_fatal_shield(goblin_target, enemy.attack_damage):
					enemy.attack_cooldown_left = enemy.attack_cooldown
					update_hud()
					return
				var goblin_killed: bool = goblin_target.take_damage(enemy.attack_damage)
				if goblin_killed:
					finalize_hero_death(goblin_target, "Goblins")
				else:
					apply_weighted_melee_knockback(enemy, goblin_target, enemy.current_room)
					status_message = "Goblins are swarming %s." % goblin_target.hero_name
			elif enemy.current_room == crystal_room:
				enemy.trigger_attack(room_center(crystal_room))
				crystal_health = maxf(crystal_health - enemy.attack_damage, 0.0)
				status_message = "Goblins are striking the crystal."
			else:
				return
		ENEMY_TYPE_KOBOLD:
			if enemy.current_room != crystal_room:
				return
			enemy.trigger_attack(room_center(crystal_room))
			crystal_health = maxf(crystal_health - enemy.attack_damage, 0.0)
			status_message = "Kobolds gnaw at the crystal."
		ENEMY_TYPE_GOLEM:
			var target_major_room: Vector2i = preferred_golem_major_module_room(enemy)
			if target_major_room != INVALID_ROOM and target_major_room == enemy.current_room:
				enemy.trigger_attack(room_center(enemy.current_room))
				if not damage_module(enemy.current_room, enemy.attack_damage, true, "A golem"):
					return
			elif enemy.current_room == crystal_room:
				enemy.trigger_attack(room_center(crystal_room))
				crystal_health = maxf(crystal_health - enemy.attack_damage, 0.0)
				status_message = "A golem is pounding the crystal."
			else:
				return
		ENEMY_TYPE_GOBLIN_SHAMAN:
			var room_targets: Array = heroes_in_room(enemy.current_room)
			if not room_targets.is_empty():
				enemy.trigger_attack(room_center(enemy.current_room))
				var defeated_heroes: Array[String] = []
				for hero in room_targets:
					if try_auto_cast_fatal_shield(hero, enemy.attack_damage):
						continue
					if hero.take_damage(enemy.attack_damage):
						defeated_heroes.append(hero.hero_name)
				for hero_name in defeated_heroes:
					for hero in room_targets:
						if is_instance_valid(hero) and hero.hero_name == hero_name:
							finalize_hero_death(hero, "A goblin shaman")
							break
				damage_module(enemy.current_room, enemy.attack_damage * 0.6, false, "A goblin shaman")
				if defeated_heroes.is_empty():
					status_message = "A goblin shaman unleashes a room-wide blast."
				elif defeated_heroes.size() == 1:
					status_message = "A goblin shaman killed %s." % defeated_heroes[0]
				else:
					status_message = "A goblin shaman killed multiple heroes."
			elif enemy.current_room == crystal_room:
				enemy.trigger_attack(room_center(crystal_room))
				crystal_health = maxf(crystal_health - enemy.attack_damage, 0.0)
				status_message = "Goblin shamans are scorching the crystal."
			else:
				return
		_:
			if enemy.current_room != crystal_room:
				return
			enemy.trigger_attack(room_center(crystal_room))
			crystal_health = maxf(crystal_health - enemy.attack_damage, 0.0)
			status_message = "Enemies are striking the crystal."
	enemy.attack_cooldown_left = enemy.attack_cooldown
	update_hud()

func find_nearest_major_module_room(from_room: Vector2i) -> Vector2i:
	var closest_room: Vector2i = INVALID_ROOM
	var closest_path_length: int = 9999
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if room_coord == crystal_room or not room["opened"]:
			continue
		if String(room.get("major_module_type", "")) == "" or float(room.get("major_health", 0.0)) <= 0.0:
			continue
		var path: Array[Vector2i] = find_path(from_room, room_coord, true)
		if path.is_empty():
			continue
		if path.size() < closest_path_length:
			closest_path_length = path.size()
			closest_room = room_coord
	return closest_room

func damage_module(room_coord: Vector2i, amount: float, major_only: bool = false, attacker_label: String = "Enemies") -> bool:
	if not rooms.has(room_coord):
		return false
	var room: Dictionary = rooms[room_coord]
	var module_count: int = room["minor_modules"].size()
	var can_hit_major: bool = room["major_module_type"] != "" and float(room["major_health"]) > 0.0
	if (major_only and not can_hit_major) or (module_count == 0 and not can_hit_major):
		return false
	var attack_major: bool = can_hit_major and (major_only or module_count == 0 or rng.randf() < 0.45)
	if attack_major:
		room["major_health"] = maxf(float(room["major_health"]) - amount, 0.0)
		if float(room["major_health"]) <= 0.0:
			status_message = "%s destroyed the major module in %s." % [attacker_label, room_title(room_coord)]
			room["major_module_type"] = ""
			room["major_under_construction"] = false
			cancel_pending_major_construction(room_coord)
		else:
			status_message = "%s is damaging the major module in %s." % [attacker_label, room_title(room_coord)]
		return true
	if major_only:
		return false
	var module_index: int = rng.randi_range(0, module_count - 1)
	var module_data: Dictionary = room["minor_modules"][module_index]
	module_data["health"] = maxf(float(module_data["health"]) - amount, 0.0)
	if float(module_data["health"]) <= 0.0:
		cancel_pending_minor_construction(room_coord, int(module_data.get("slot_index", -1)))
		room["minor_modules"].remove_at(module_index)
		status_message = "%s destroyed a turret in %s." % [attacker_label, room_title(room_coord)]
	else:
		status_message = "%s is damaging a turret in %s." % [attacker_label, room_title(room_coord)]
	return true

func send_hero_back_to_crystal(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	clear_pending_room_loot_request(hero.hero_index)
	clear_pending_room_action_request(hero.hero_index)
	if crystal_holder == hero:
		drop_crystal(hero.current_room)
	hero.restore_health()
	hero.move_steps.clear()
	hero.pending_room = Hero.INVALID_ROOM
	hero.pending_open_room = Hero.INVALID_ROOM
	hero.pending_open_origin_room = Hero.INVALID_ROOM
	opening_heroes.erase(hero)
	if opening_hero == hero:
		opening_hero = opening_heroes[0] if not opening_heroes.is_empty() else null
	if opening_room != INVALID_ROOM and opening_heroes.is_empty():
		opening_room = INVALID_ROOM
		opening_origin_room = INVALID_ROOM
		opening_hero = null
		opening_timer_left = 0.0
	hero.current_room = crystal_room
	if hero == selected_hero():
		selected_room = crystal_room
	hero.set_room(crystal_room, hero_idle_position(crystal_room, hero.hero_index, heroes.size()))
	hero.combo_points = 0

func advance_passive_item_combat_procs(delta: float) -> void:
	if not wave_in_progress():
		return
	for hero in heroes:
		if hero == null or not is_instance_valid(hero) or hero.current_health <= 0.0 or hero.carrying_crystal:
			continue
		var effect_summary: Dictionary = inventory_effect_summary(hero.inventory_items)
		sync_hero_passive_combat_sources(hero, effect_summary)
		var room_target: Variant = nearest_enemy_in_room(hero.current_room, hero.global_position, 100000.0)
		for passive_variant in Array(effect_summary.get("combat_passives", [])):
			var passive_ability: Dictionary = passive_variant
			var key: String = combat_passive_key(int(passive_ability.get("item_uid", -1)), String(passive_ability.get("card_id", "")))
			var item_bonus: Dictionary = Dictionary(passive_ability.get("item_bonus", {}))
			var card_def: Dictionary = card_definition(String(passive_ability.get("card_id", "")))
			var base_cooldown: float = float(passive_ability.get("cooldown", card_def.get("test_cooldown", 1.5)))
			var effective_cooldown: float = maxf(base_cooldown * float(item_bonus.get("card_charge_mult", 1.0)), 0.25)
			var passive_state: Dictionary = Dictionary(global_item_passive_timers.get(key, {})).duplicate(true)
			var timer_left: float = maxf(float(passive_state.get("timer_left", effective_cooldown)) - delta, 0.0)
			passive_state["timer_left"] = timer_left
			global_item_passive_timers[key] = passive_state
			if timer_left > 0.0 or room_target == null:
				continue
			var passive_payload: Dictionary = build_passive_combat_payload(passive_ability, effect_summary)
			if not spend_hero_stamina_with_reactions(hero, float(passive_payload.get("stamina_cost", 0.0))):
				continue
			match String(passive_payload.get("card_id", "")):
				"dagger_card":
					spawn_dagger_card_projectiles(hero, room_target.global_position, passive_payload)
				_:
					spawn_axe_card_projectile(hero, room_target.global_position, passive_payload)
			passive_state["timer_left"] = effective_cooldown
			global_item_passive_timers[key] = passive_state

func advance_hero_stamina_effects(delta: float) -> void:
	if delta <= 0.0:
		return
	for hero in heroes:
		if hero == null or not is_instance_valid(hero):
			continue
		if hero.stamina_regen_time_left > 0.0:
			hero.stamina_regen_time_left = maxf(hero.stamina_regen_time_left - delta, 0.0)
			if wave_in_progress() and hero.current_health > 0.0:
				hero.restore_stamina(hero.stamina_regen_rate * delta)
			if hero.stamina_regen_time_left <= 0.0:
				hero.clear_stamina_regen_buff()
		if hero.barrier_time_left > 0.0:
			hero.barrier_time_left = maxf(hero.barrier_time_left - delta, 0.0)
			if hero.barrier_time_left <= 0.0:
				hero.clear_barrier()
		if hero.invulnerability_time_left > 0.0:
			hero.invulnerability_time_left = maxf(hero.invulnerability_time_left - delta, 0.0)
			if hero.invulnerability_time_left <= 0.0:
				hero.clear_invulnerability()

func projected_hero_damage_after_barrier(hero: Variant, amount: float) -> float:
	if hero == null or not is_instance_valid(hero):
		return maxf(amount, 0.0)
	return maxf(float(amount) - float(hero.barrier_amount), 0.0)

func hero_hand_card_index(hero: Variant, card_uid: int) -> int:
	if hero == null or not is_instance_valid(hero):
		return -1
	for card_index in range(hero.hand_cards.size()):
		if int((hero.hand_cards[card_index] as Dictionary).get("uid", -1)) == card_uid:
			return card_index
	return -1

func hero_hand_card_index_by_id(hero: Variant, card_id: String) -> int:
	if hero == null or not is_instance_valid(hero) or card_id == "":
		return -1
	for card_index in range(hero.hand_cards.size()):
		if String((hero.hand_cards[card_index] as Dictionary).get("card_id", "")) == card_id:
			return card_index
	return -1

func card_supports_reaction(hand_card: Dictionary) -> bool:
	return String(hand_card.get("reaction_trigger", "")) != ""

func play_reaction_card_for_hero_at_index(hero: Variant, hand_index: int) -> bool:
	if hero == null or not is_instance_valid(hero) or hand_index < 0 or hand_index >= hero.hand_cards.size():
		return false
	var hand_card: Dictionary = (hero.hand_cards[hand_index] as Dictionary).duplicate(true)
	if not hand_card_phase_allows_play(hand_card):
		return false
	var target_data: Dictionary = {
		"hero": hero,
		"room": hero.current_room,
		"world_position": hero.global_position,
	}
	if not apply_hand_card_effect(hero, hand_card, target_data):
		return false
	if not bool(hand_card.get("reusable", false)):
		hero.hand_cards.remove_at(hand_index)
		finalize_played_hand_card_source(hand_card)
	fill_queued_hand_cards(hero)
	cleanup_global_item_card_states()
	return true

func trigger_first_reaction_card(hero: Variant, trigger_id: String) -> bool:
	if hero == null or not is_instance_valid(hero) or trigger_id == "":
		return false
	for hand_index in range(hero.hand_cards.size()):
		var hand_card: Dictionary = hero.hand_cards[hand_index]
		if String(hand_card.get("reaction_trigger", "")) != trigger_id or not bool(hand_card.get("reaction_enabled", false)):
			continue
		if play_reaction_card_for_hero_at_index(hero, hand_index):
			return true
	return false

func spend_hero_stamina_with_reactions(hero: Variant, amount: float) -> bool:
	if amount > 0.0 and not stamina_use_enabled:
		return false
	if hero == null or not is_instance_valid(hero):
		return false
	var previous_stamina: float = hero.stamina
	if not hero.spend_stamina(amount):
		return false
	if previous_stamina >= -0.001 and hero.stamina < -0.001:
		trigger_first_reaction_card(hero, "stamina_negative")
	return true

func commit_hand_state(hero_index: int, hand_state: Array) -> void:
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	var cards_by_uid: Dictionary = {}
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = (hand_card_variant as Dictionary).duplicate(true)
		cards_by_uid[int(hand_card.get("uid", -1))] = hand_card
	var rebuilt_hand: Array = []
	for state_variant in hand_state:
		var state: Dictionary = state_variant as Dictionary
		var card_uid: int = int(state.get("uid", -1))
		if not cards_by_uid.has(card_uid):
			continue
		var rebuilt_card: Dictionary = (cards_by_uid[card_uid] as Dictionary).duplicate(true)
		if card_supports_reaction(rebuilt_card):
			rebuilt_card["reaction_enabled"] = bool(state.get("reaction_enabled", rebuilt_card.get("reaction_enabled", false)))
		rebuilt_hand.append(rebuilt_card)
		cards_by_uid.erase(card_uid)
	for remaining_card_variant in hero.hand_cards:
		var remaining_card: Dictionary = remaining_card_variant as Dictionary
		var remaining_uid: int = int(remaining_card.get("uid", -1))
		if cards_by_uid.has(remaining_uid):
			rebuilt_hand.append((cards_by_uid[remaining_uid] as Dictionary).duplicate(true))
			cards_by_uid.erase(remaining_uid)
	hero.hand_cards = rebuilt_hand

func serialized_hand_state(hero: Variant) -> Array:
	var state: Array = []
	if hero == null or not is_instance_valid(hero):
		return state
	for hand_card_variant in hero.hand_cards:
		var hand_card: Dictionary = hand_card_variant as Dictionary
		state.append({
			"uid": int(hand_card.get("uid", -1)),
			"reaction_enabled": bool(hand_card.get("reaction_enabled", false)),
		})
	return state

func toggle_hand_card_reaction(hero: Variant, hand_index: int) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hand_index < 0 or hand_index >= hero.hand_cards.size():
		return false
	var hand_card: Dictionary = (hero.hand_cards[hand_index] as Dictionary).duplicate(true)
	if not card_supports_reaction(hand_card):
		return false
	hand_card["reaction_enabled"] = not bool(hand_card.get("reaction_enabled", false))
	hero.hand_cards[hand_index] = hand_card
	return true

func move_hand_card(hero: Variant, from_index: int, insertion_index: int) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if from_index < 0 or from_index >= hero.hand_cards.size():
		return false
	var clamped_insertion: int = clampi(insertion_index, 0, hero.hand_cards.size())
	if from_index < clamped_insertion:
		clamped_insertion -= 1
	if clamped_insertion == from_index:
		return false
	var moving_card: Dictionary = (hero.hand_cards[from_index] as Dictionary).duplicate(true)
	hero.hand_cards.remove_at(from_index)
	hero.hand_cards.insert(clampi(clamped_insertion, 0, hero.hand_cards.size()), moving_card)
	return true

func hand_card_by_uid(hero: Variant, card_uid: int) -> Dictionary:
	var hand_index: int = hero_hand_card_index(hero, card_uid)
	if hand_index < 0:
		return {}
	return (hero.hand_cards[hand_index] as Dictionary).duplicate(true)

func hero_at_world_position(world_position: Vector2, controllable_only: bool = false) -> Variant:
	for hero_index in range(heroes.size()):
		var hero: Variant = heroes[hero_index]
		if hero == null or not is_instance_valid(hero):
			continue
		if controllable_only and not can_local_control_hero_index(hero_index):
			continue
		if hero.global_position.distance_to(world_position) <= HERO_SELECTION_RADIUS:
			return hero
	return null

func room_target_at_world_position(world_position: Vector2, preferred_from_room: Vector2i = INVALID_ROOM) -> Vector2i:
	var direct_room: Vector2i = room_at_world_position(world_position)
	if direct_room != INVALID_ROOM:
		return direct_room
	return corridor_room_target_at_position(world_position, preferred_from_room)

func resolve_card_target(hero: Variant, hand_card: Dictionary, target_world_position: Vector2) -> Dictionary:
	if hero == null or not is_instance_valid(hero):
		return {}
	var target_scope: String = String(hand_card.get("target_scope", "hero_room"))
	match target_scope:
		"global":
			return {
				"world_position": target_world_position,
			}
		"hero":
			var target_hero: Variant = hero_at_world_position(target_world_position, false)
			if target_hero == null or not is_instance_valid(target_hero):
				return {}
			return {
				"hero": target_hero,
				"hero_index": target_hero.hero_index,
				"world_position": target_hero.global_position,
			}
		"same_hero":
			return {
				"hero": hero,
				"hero_index": hero.hero_index,
				"world_position": hero.global_position,
			}
		"opened_room":
			var target_room: Vector2i = room_target_at_world_position(target_world_position, active_hero_room_for_commands(hero))
			if target_room == INVALID_ROOM or not rooms.has(target_room) or not rooms[target_room]["opened"]:
				return {}
			return {
				"room": target_room,
				"world_position": clamp_point_to_room(target_world_position, target_room),
			}
		"same_room", "hero_room":
			if not rooms.has(hero.current_room) or not room_rect(hero.current_room).has_point(target_world_position):
				return {}
			return {
				"room": hero.current_room,
				"world_position": target_world_position,
			}
	return {}

func card_cast_candidate_rooms(target_room: Vector2i, hand_card: Dictionary) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	if target_room == INVALID_ROOM or not rooms.has(target_room) or not rooms[target_room]["opened"]:
		return candidates
	var max_hops: int = maxi(0, int(hand_card.get("cast_adjacent_hops", 0)))
	var frontier: Array = [{
		"room": target_room,
		"depth": 0,
	}]
	var visited: Dictionary = {
		target_room: true,
	}
	while not frontier.is_empty():
		var entry: Dictionary = frontier.pop_front()
		var room_coord: Vector2i = entry.get("room", INVALID_ROOM)
		var depth: int = int(entry.get("depth", 0))
		if room_coord == INVALID_ROOM or not rooms.has(room_coord) or not rooms[room_coord]["opened"]:
			continue
		candidates.append(room_coord)
		if depth >= max_hops:
			continue
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if visited.has(neighbor) or not rooms.has(neighbor) or not rooms[neighbor]["opened"]:
				continue
			visited[neighbor] = true
			frontier.append({
				"room": neighbor,
				"depth": depth + 1,
			})
	return candidates

func room_has_neighbor(room_coord: Vector2i, neighbor: Vector2i) -> bool:
	return rooms.has(room_coord) and Array(rooms[room_coord].get("neighbors", [])).has(neighbor)

func room_interior_rect(room_coord: Vector2i, margin: float = 24.0) -> Rect2:
	var walkable_regions: Array = room_walkable_regions(room_coord, margin)
	if walkable_regions.is_empty():
		return room_rect(room_coord).grow(-margin)
	return bounding_rect_for_regions(walkable_regions)

func cross_room_card_cast_staging_position(cast_room: Vector2i, target_room: Vector2i, target_world_position: Vector2) -> Vector2:
	if cast_room == INVALID_ROOM or target_room == INVALID_ROOM or not rooms.has(cast_room) or not rooms.has(target_room):
		return Vector2.INF
	if not room_has_neighbor(cast_room, target_room):
		return Vector2.INF
	var target_point: Vector2 = clamp_point_to_room(target_world_position, target_room)
	var doorway_cast: Vector2 = doorway_position(cast_room, target_room)
	var delta: Vector2i = target_room - cast_room
	for inset_step in range(0, 7):
		var inset: float = 56.0 - float(inset_step) * 6.0
		if abs(delta.x) == 1:
			var stage_x: float = doorway_cast.x - float(delta.x) * inset
			var denominator_x: float = target_point.x - stage_x
			if absf(denominator_x) <= 0.001:
				continue
			var interpolation_x: float = (doorway_cast.x - stage_x) / denominator_x
			if interpolation_x <= 0.0 or interpolation_x >= 1.0:
				continue
			var stage_y: float = (doorway_cast.y - interpolation_x * target_point.y) / (1.0 - interpolation_x)
			var candidate: Vector2 = Vector2(stage_x, stage_y)
			if room_walkable_contains_point(cast_room, candidate, 20.0):
				return candidate
		elif abs(delta.y) == 1:
			var stage_y_axis: float = doorway_cast.y - float(delta.y) * inset
			var denominator_y: float = target_point.y - stage_y_axis
			if absf(denominator_y) <= 0.001:
				continue
			var interpolation_y: float = (doorway_cast.y - stage_y_axis) / denominator_y
			if interpolation_y <= 0.0 or interpolation_y >= 1.0:
				continue
			var stage_x_axis: float = (doorway_cast.x - interpolation_y * target_point.x) / (1.0 - interpolation_y)
			var candidate_axis: Vector2 = Vector2(stage_x_axis, stage_y_axis)
			if room_walkable_contains_point(cast_room, candidate_axis, 20.0):
				return candidate_axis
	return Vector2.INF

func card_cast_staging_position(cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2 = Vector2.INF) -> Vector2:
	if cast_room == INVALID_ROOM or not rooms.has(cast_room):
		return Vector2.INF
	if not bool(hand_card.get("requires_line_of_effect", false)):
		return room_action_staging_position(cast_room)
	if target_room == INVALID_ROOM or cast_room == target_room:
		return room_action_staging_position(cast_room)
	var resolved_target: Vector2 = target_world_position
	if resolved_target == Vector2.INF:
		resolved_target = room_walkable_center(target_room)
	return cross_room_card_cast_staging_position(cast_room, target_room, resolved_target)

func card_cast_has_line_of_effect(cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2) -> bool:
	if not bool(hand_card.get("requires_line_of_effect", false)):
		return true
	if cast_room == INVALID_ROOM or target_room == INVALID_ROOM or not rooms.has(cast_room) or not rooms.has(target_room):
		return false
	if cast_room == target_room:
		return room_walkable_contains_point(target_room, clamp_point_to_room(target_world_position, target_room), 10.0)
	return card_cast_staging_position(cast_room, target_room, hand_card, target_world_position) != Vector2.INF

func hero_ready_for_card_cast(hero: Variant, cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2 = Vector2.INF) -> bool:
	if not hero_ready_for_room_action(hero, cast_room):
		return false
	if not bool(hand_card.get("requires_line_of_effect", false)):
		return true
	if cast_room == target_room or target_room == INVALID_ROOM:
		return true
	var staging_position: Vector2 = card_cast_staging_position(cast_room, target_room, hand_card, target_world_position)
	return staging_position != Vector2.INF and hero.global_position.distance_to(staging_position) <= 22.0

func best_card_cast_room(from_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2) -> Vector2i:
	var candidates: Array[Vector2i] = card_cast_candidate_rooms(target_room, hand_card)
	if candidates.is_empty():
		return INVALID_ROOM
	var best_room: Vector2i = INVALID_ROOM
	var best_path_size: int = 999999
	var best_target_distance: int = 999999
	for candidate in candidates:
		if bool(hand_card.get("requires_line_of_effect", false)) and not card_cast_has_line_of_effect(candidate, target_room, hand_card, target_world_position):
			continue
		var path_size: int = 1
		if candidate != from_room:
			var path: Array[Vector2i] = find_path(from_room, candidate, true)
			if path.size() <= 1:
				continue
			path_size = path.size()
		var target_distance: int = 0 if candidate == target_room else 1
		if best_room == INVALID_ROOM or path_size < best_path_size or (path_size == best_path_size and target_distance < best_target_distance):
			best_room = candidate
			best_path_size = path_size
			best_target_distance = target_distance
	return best_room

func card_target_is_valid(hero: Variant, hand_card: Dictionary, target_world_position: Vector2) -> bool:
	return not resolve_card_target(hero, hand_card, target_world_position).is_empty()

func hand_card_starts_spell_study(hero: Variant, hand_card: Dictionary, target_data: Dictionary) -> bool:
	if hero == null or not is_instance_valid(hero) or wave_in_progress():
		return false
	if not bool(hand_card.get("learnable_spell_scroll", false)):
		return false
	var spell_id: String = String(hand_card.get("learn_spell_id", ""))
	if not hero_can_study_spell(hero, spell_id):
		return false
	var target_room: Vector2i = target_data.get("room", INVALID_ROOM)
	if target_room != INVALID_ROOM:
		return target_room == hero.current_room and hero_ready_for_room_action(hero, target_room)
	var target_hero: Variant = target_data.get("hero", null)
	return target_hero == hero and hero_ready_for_room_action(hero, hero.current_room)

func hand_card_phase_allows_play(hand_card: Dictionary) -> bool:
	var phase: String = String(hand_card.get("phase", "combat"))
	match phase:
		"out_of_combat":
			return not wave_in_progress()
		"combat":
			return wave_in_progress()
		"any":
			return true
		_:
			return true

func apply_hand_card_effect(hero: Variant, hand_card: Dictionary, target_data: Dictionary) -> bool:
	var target_world_position: Vector2 = Vector2(target_data.get("world_position", hero.global_position))
	if hand_card_starts_spell_study(hero, hand_card, target_data):
		return begin_spell_scroll_study(hero, String(hand_card.get("learn_spell_id", "")))
	match String(hand_card.get("card_id", "")):
		"fireball_card":
			var room_coord: Vector2i = target_data.get("room", INVALID_ROOM)
			if room_coord == INVALID_ROOM or not rooms.has(room_coord):
				return false
			cast_fireball_spell(hero, target_world_position, room_coord, hand_card)
			status_message = "%s cast Fireball." % hero.hero_name
			return true
		"magic_missile_card":
			var missile_room: Vector2i = target_data.get("room", INVALID_ROOM)
			if missile_room == INVALID_ROOM or not rooms.has(missile_room):
				return false
			cast_magic_missile_spell(hero, target_world_position, missile_room, hand_card)
			status_message = "%s cast Magic Missile." % hero.hero_name
			return true
		"light_cantrip_card":
			hero.light_cantrip_active = true
			refresh_room_lighting_states()
			hero.trigger_attack(hero.global_position + Vector2(0.0, -18.0), "laser")
			status_message = "%s invoked Light." % hero.hero_name
			return true
		"misty_step_card":
			var teleport_room: Vector2i = target_data.get("room", INVALID_ROOM)
			if teleport_room == INVALID_ROOM or not rooms.has(teleport_room):
				return false
			cast_misty_step_spell(hero, target_world_position, teleport_room, hand_card)
			status_message = "%s cast Misty Step." % hero.hero_name
			return true
		"shield_card":
			cast_shield_spell(hero, hand_card)
			status_message = "%s cast Shield." % hero.hero_name
			return true
		"cure_light_wounds_card":
			var cleric_target: Variant = target_data.get("hero", hero)
			if cleric_target == null or not is_instance_valid(cleric_target):
				return false
			var previous_cleric_health: float = cleric_target.current_health
			cleric_target.heal(float(hand_card.get("heal_amount", 36.0)))
			hero.trigger_attack(cleric_target.global_position, "laser")
			if cleric_target.current_health <= previous_cleric_health + 0.001:
				status_message = "%s does not need healing." % cleric_target.hero_name
				return false
			status_message = "%s cast Cure Light Wounds." % hero.hero_name
			return true
		"sanctuary_card":
			cast_shield_spell(hero, {
				"shield_amount": float(hand_card.get("shield_amount", 24.0)),
				"shield_duration": float(hand_card.get("shield_duration", 8.0)),
				"color": hand_card.get("color", Color("e3ff9f")),
			})
			status_message = "%s invoked Sanctuary." % hero.hero_name
			return true
		"lightning_bolt_card":
			var bolt_room: Vector2i = target_data.get("room", INVALID_ROOM)
			if bolt_room == INVALID_ROOM or not rooms.has(bolt_room):
				return false
			cast_lightning_bolt_spell(hero, target_world_position, bolt_room, hand_card)
			status_message = "%s cast Lightning Bolt." % hero.hero_name
			return true
		"lantern_torch_card":
			var target_hero: Variant = target_data.get("hero", null)
			if target_hero == null or not is_instance_valid(target_hero):
				return false
			var created_torch: Dictionary = make_inventory_item("torch")
			if not add_item_to_hero_inventory(target_hero, created_torch):
				status_message = "%s has no room for a torch." % target_hero.hero_name
				return false
			hero.trigger_attack(target_hero.global_position, "laser")
			status_message = "%s prepared a torch for %s." % [hero.hero_name, target_hero.hero_name]
			return true
		"torch_card":
			var room_coord: Vector2i = target_data.get("room", INVALID_ROOM)
			if room_coord == INVALID_ROOM or not rooms.has(room_coord):
				return false
			var target_room_data: Dictionary = rooms[room_coord]
			if bool(target_room_data.get("permanent_light", false)) or room_has_wave_torch_light(target_room_data):
				status_message = "%s is already secured by light." % room_title(room_coord)
				return false
			apply_wave_torch_light_to_room(room_coord)
			hero.trigger_attack(room_center(room_coord), "laser")
			status_message = "%s lit %s through the next wave." % [hero.hero_name, room_title(room_coord)]
			return true
		"mend_card":
			var target_hero: Variant = target_data.get("hero", null)
			if target_hero == null or not is_instance_valid(target_hero):
				return false
			var previous_health: float = target_hero.current_health
			target_hero.heal(float(hand_card.get("heal_amount", 35.0)))
			hero.trigger_attack(target_hero.global_position, "laser")
			if target_hero.current_health <= previous_health + 0.001:
				status_message = "%s is already fully patched up." % target_hero.hero_name
				return false
			status_message = "%s restored %s." % [hero.hero_name, target_hero.hero_name]
			return true
		"emergency_snack_card":
			var snack_target: Variant = target_data.get("hero", hero)
			if snack_target == null or not is_instance_valid(snack_target):
				return false
			var food_cost: int = int(hand_card.get("food_cost", HEAL_FOOD_COST))
			if food < food_cost:
				status_message = "Not enough food for %s." % String(hand_card.get("name", "that card"))
				return false
			food -= food_cost
			snack_target.restore_health()
			snack_target.refill_stamina()
			snack_target.combo_points = 0
			snack_target.clear_stamina_regen_buff()
			hero.trigger_attack(snack_target.global_position, "laser")
			status_message = "%s used an emergency snack." % snack_target.hero_name
			return true
		"ration_meal_card":
			var ration_target: Variant = target_data.get("hero", hero)
			if ration_target == null or not is_instance_valid(ration_target):
				return false
			var previous_ration_health: float = ration_target.current_health
			var previous_ration_stamina: float = ration_target.stamina
			var previous_regen_time_left: float = ration_target.stamina_regen_time_left
			if bool(hand_card.get("heal_full", false)):
				ration_target.restore_health()
			else:
				ration_target.heal(float(hand_card.get("heal_amount", 0.0)))
			if bool(hand_card.get("restore_stamina_full", false)):
				ration_target.refill_stamina()
			else:
				ration_target.restore_stamina(float(hand_card.get("stamina_restore", 0.0)))
			ration_target.apply_stamina_regen_buff(float(hand_card.get("stamina_regen_rate", 0.0)), float(hand_card.get("stamina_regen_duration", 0.0)))
			hero.trigger_attack(ration_target.global_position, "laser")
			if ration_target.current_health <= previous_ration_health + 0.001 and ration_target.stamina <= previous_ration_stamina + 0.001 and ration_target.stamina_regen_time_left <= previous_regen_time_left + 0.001:
				status_message = "%s does not need a ration right now." % ration_target.hero_name
				return false
			status_message = "%s ate a ration." % ration_target.hero_name
			return true
		"dagger_card":
			spawn_dagger_card_projectiles(hero, target_world_position, hand_card)
			status_message = "%s flung a dagger fan." % hero.hero_name
			return true
		_:
			spawn_axe_card_projectile(hero, target_world_position, hand_card)
			status_message = "%s hurled a whirling axe." % hero.hero_name
			return true

func finalize_played_hand_card_source(hand_card: Dictionary) -> void:
	var item_uid: int = int(hand_card.get("item_uid", -1))
	if item_uid < 0:
		return
	if bool(hand_card.get("consume_item_on_play", false)):
		remove_item_by_uid_from_world(item_uid)
		return
	var charge_cost: int = int(hand_card.get("consume_item_charges_on_play", 0))
	if charge_cost > 0:
		consume_item_charges_by_uid(item_uid, charge_cost)

func play_card_for_hero(hero_index: int, card_uid: int, target_world_position: Vector2) -> bool:
	if hero_index < 0 or hero_index >= heroes.size():
		return false
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or hero.current_health <= 0.0 or hero.carrying_crystal:
		return false
	if doors_opened == 0:
		status_message = "Cards cannot be played until the first door opens."
		update_hud()
		return false
	var hand_index: int = hero_hand_card_index(hero, card_uid)
	if hand_index < 0:
		return false
	var hand_card: Dictionary = (hero.hand_cards[hand_index] as Dictionary).duplicate(true)
	if not hand_card_phase_allows_play(hand_card):
		return false
	var target_data: Dictionary = resolve_card_target(hero, hand_card, target_world_position)
	if target_data.is_empty():
		return false
	var target_room: Vector2i = target_data.get("room", INVALID_ROOM)
	if target_room != INVALID_ROOM:
		var cast_room: Vector2i = best_card_cast_room(active_hero_room_for_commands(hero), target_room, hand_card, Vector2(target_data.get("world_position", target_world_position)))
		if cast_room == INVALID_ROOM:
			status_message = "No line of effect to that spot."
			update_hud()
			return false
		if not hero_ready_for_card_cast(hero, cast_room, target_room, hand_card, Vector2(target_data.get("world_position", target_world_position))):
			return request_deferred_room_card_for_hero(hero_index, cast_room, target_room, card_uid, Vector2(target_data.get("world_position", target_world_position)))
	var is_study_play: bool = hand_card_starts_spell_study(hero, hand_card, target_data)
	var stamina_cost: float = float(hand_card.get("stamina_cost", 0.0))
	if not is_study_play and stamina_cost > 0.0 and not spend_hero_stamina_with_reactions(hero, stamina_cost):
		status_message = "%s is too exhausted for that." % hero.hero_name
		update_hud()
		return false
	if not apply_hand_card_effect(hero, hand_card, target_data):
		return false
	if not bool(hand_card.get("reusable", false)):
		hero.hand_cards.remove_at(hand_index)
		finalize_played_hand_card_source(hand_card)
	fill_queued_hand_cards(hero)
	cleanup_global_item_card_states()
	update_hud()
	return true

func cast_fireball_spell(hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	hero.trigger_attack(target_world_position, "laser")
	explode_fireball_projectile({
		"position": target_world_position,
		"target_position": target_world_position,
		"damage": float(hand_card.get("damage", 42.0)),
		"color": hand_card.get("color", Color("ff9a5e")),
		"radius": float(hand_card.get("radius", 12.0)),
		"impact_radius": float(hand_card.get("impact_radius", 92.0)),
		"push_distance": 56.0,
		"room": target_room,
	})

func nearest_enemies_in_room(room_coord: Vector2i, origin: Vector2, max_count: int) -> Array:
	var room_enemies: Array = []
	for enemy in enemies:
		if not enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		room_enemies.append({
			"enemy": enemy,
			"distance": origin.distance_squared_to(enemy.global_position),
		})
	room_enemies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", INF)) < float(b.get("distance", INF))
	)
	var resolved: Array = []
	for enemy_entry_variant in room_enemies:
		if resolved.size() >= max_count:
			break
		resolved.append(enemy_entry_variant.get("enemy", null))
	return resolved

func cast_magic_missile_spell(hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	hero.trigger_attack(target_world_position, "laser")
	var missile_targets: Array = nearest_enemies_in_room(target_room, target_world_position, int(hand_card.get("projectile_count", 3)))
	if missile_targets.is_empty():
		add_resource_floating_text(target_world_position, "Miss", Color(hand_card.get("color", Color("9cd7ff"))))
		return
	var missile_count: int = maxi(1, int(hand_card.get("projectile_count", 3)))
	for missile_index in range(missile_count):
		var target_enemy: Variant = missile_targets[missile_index % missile_targets.size()]
		if target_enemy == null or not is_instance_valid(target_enemy):
			continue
		spawn_laser_projectile(hero.global_position, target_enemy, float(hand_card.get("damage", hand_card.get("base_damage", 14.0))), hand_card.get("color", Color("9cd7ff")), 4.2, 1480.0)

func cast_misty_step_spell(hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	var landing_position: Vector2 = clamp_point_to_room(target_world_position, target_room)
	hero.clear_orders()
	clear_pending_room_action_request(hero.hero_index)
	clear_pending_room_loot_request(hero.hero_index)
	hero.set_room(target_room, landing_position)
	hero.trigger_attack(landing_position, "laser")
	projectiles.append({
		"kind": "fireball_blast",
		"position": landing_position,
		"previous": landing_position,
		"target_position": landing_position,
		"color": hand_card.get("color", Color("b89cff")),
		"radius": 18.0,
		"impact_radius": 42.0,
		"lifetime_left": 0.16,
		"blast_duration": 0.16,
		"width": 4.0,
	})
	add_resource_floating_text(landing_position, "Step", Color(hand_card.get("color", Color("b89cff"))))

func cast_shield_spell(hero: Variant, hand_card: Dictionary) -> void:
	var barrier_amount: float = float(hand_card.get("shield_amount", 34.0))
	var barrier_duration: float = float(hand_card.get("shield_duration", 10.0))
	var immunity_duration: float = float(hand_card.get("immunity_duration", 0.0))
	if barrier_amount > 0.0 and barrier_duration > 0.0:
		hero.apply_barrier(barrier_amount, barrier_duration)
	if immunity_duration > 0.0:
		hero.apply_invulnerability(immunity_duration)
	hero.trigger_attack(hero.global_position + Vector2.UP * 8.0, "laser")
	projectiles.append({
		"kind": "shield_flash",
		"position": hero.global_position,
		"previous": hero.global_position,
		"target_position": hero.global_position,
		"color": hand_card.get("color", Color("9fc8ff")),
		"radius": 34.0,
		"impact_radius": 34.0,
		"lifetime_left": 0.22,
		"blast_duration": 0.22,
		"width": 3.0,
	})

func try_auto_cast_fatal_shield(hero: Variant, incoming_damage: float) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if hero.current_health <= 0.0 or hero.invulnerability_time_left > 0.0:
		return false
	var lethal_damage: float = projected_hero_damage_after_barrier(hero, incoming_damage)
	if lethal_damage < hero.current_health - 0.001:
		return false
	if not trigger_first_reaction_card(hero, "fatal_damage"):
		return false
	status_message = "%s reflexively cast Shield." % hero.hero_name
	return true

func cast_lightning_bolt_spell(hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	var bolt_origin: Vector2 = hero.global_position
	var bolt_target: Vector2 = clamp_point_to_room(target_world_position, target_room)
	var bolt_radius: float = maxf(float(hand_card.get("impact_radius", 18.0)), 8.0)
	var bolt_damage: float = float(hand_card.get("damage", hand_card.get("base_damage", 30.0)))
	for enemy in enemies:
		if not enemy_is_active(enemy):
			continue
		if enemy.current_room != hero.current_room and enemy.current_room != target_room:
			continue
		if point_distance_to_segment(enemy.global_position, bolt_origin, bolt_target) > bolt_radius:
			continue
		enemy.take_damage(bolt_damage)
	hero.trigger_attack(bolt_target, "laser")
	projectiles.append({
		"kind": "lightning_bolt",
		"position": bolt_target,
		"previous": bolt_origin,
		"target_position": bolt_target,
		"color": hand_card.get("color", Color("8bd9ff")),
		"radius": bolt_radius,
		"impact_radius": bolt_radius,
		"lifetime_left": 0.18,
		"blast_duration": 0.18,
		"width": 7.0,
		"room": target_room,
	})
	add_resource_floating_text(bolt_target, "Bolt", Color(hand_card.get("color", Color("8bd9ff"))))

func explode_fireball_projectile(projectile: Dictionary) -> void:
	var room_coord: Vector2i = projectile.get("room", INVALID_ROOM)
	var target_position: Vector2 = projectile.get("target_position", projectile.get("position", Vector2.ZERO))
	if room_coord == INVALID_ROOM or not rooms.has(room_coord):
		return
	var impact_radius: float = maxf(float(projectile.get("impact_radius", 92.0)), 12.0)
	var damage: float = float(projectile.get("damage", 42.0))
	var push_distance: float = float(projectile.get("push_distance", 56.0))
	var hit_any: bool = false
	for enemy in enemies:
		if not enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		var enemy_offset: Vector2 = enemy.global_position - target_position
		var enemy_distance: float = enemy_offset.length()
		if enemy_distance > impact_radius:
			continue
		enemy.take_damage(damage)
		var push_direction: Vector2 = enemy_offset.normalized() if enemy_distance > 0.001 else random_room_offset(1.0).normalized()
		if push_direction == Vector2.ZERO:
			push_direction = Vector2.RIGHT
		var distance_ratio: float = 1.0 - clampf(enemy_distance / impact_radius, 0.0, 1.0)
		var pushed_position: Vector2 = clamp_point_to_room(enemy.global_position + push_direction * push_distance * (0.35 + distance_ratio * 0.65), room_coord)
		enemy.global_position = pushed_position
		enemy.set_destination(pushed_position)
		hit_any = true
	projectiles.append({
		"kind": "fireball_blast",
		"position": target_position,
		"previous": target_position,
		"target_position": target_position,
		"color": projectile.get("color", Color("ff9a5e")),
		"radius": impact_radius,
		"impact_radius": impact_radius,
		"lifetime_left": 0.24,
		"blast_duration": 0.24,
		"width": 6.0,
	})
	add_resource_floating_text(target_position, "Fireball" if hit_any else "Miss", Color(projectile.get("color", Color("ff9a5e"))))

func spawn_axe_card_projectile(hero: Variant, target_world_position: Vector2, hand_card: Dictionary) -> void:
	var direction: Vector2 = (target_world_position - hero.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	hero.trigger_attack(target_world_position, "melee")
	projectiles.append({
		"kind": "axe",
		"position": hero.global_position,
		"previous": hero.global_position,
		"velocity": direction * float(hand_card.get("speed", 760.0)),
		"damage": float(hand_card.get("damage", 20.0)),
		"color": hand_card.get("color", Color("ffd27a")),
		"width": 7.0,
		"radius": float(hand_card.get("radius", 17.0)),
		"room": hero.current_room,
		"lifetime_left": float(hand_card.get("lifetime", 2.2)),
		"remaining_bounces": int(hand_card.get("bounces", 2)),
		"rotation_angle": 0.0,
		"spin_speed": 18.0,
		"hit_enemy_uids": [],
		"owner_hero_index": hero.hero_index,
	})

func spawn_dagger_card_projectiles(hero: Variant, target_world_position: Vector2, hand_card: Dictionary) -> void:
	var count: int = maxi(1, int(hand_card.get("projectile_count", 3)))
	var center_direction: Vector2 = (target_world_position - hero.global_position).normalized()
	if center_direction == Vector2.ZERO:
		center_direction = Vector2.RIGHT
	hero.trigger_attack(target_world_position, "laser")
	var spread: float = float(hand_card.get("spread", 0.16))
	for projectile_index in range(count):
		var offset_ratio: float = 0.0 if count == 1 else (float(projectile_index) / float(count - 1) - 0.5) * 2.0
		var direction: Vector2 = center_direction.rotated(offset_ratio * spread)
		projectiles.append({
			"kind": "dagger",
			"position": hero.global_position,
			"previous": hero.global_position,
			"velocity": direction * float(hand_card.get("speed", 1020.0)),
			"damage": float(hand_card.get("damage", 10.0)) + float(hero.combo_points) * 1.5,
			"color": hand_card.get("color", Color("d7f0ff")),
			"width": 4.0,
			"radius": 9.0,
			"room": hero.current_room,
			"lifetime_left": float(hand_card.get("lifetime", 1.45)),
			"remaining_bounces": int(hand_card.get("bounces", 1)),
			"rotation_angle": direction.angle(),
			"spin_speed": 0.0,
			"hit_enemy_uids": [],
			"owner_hero_index": hero.hero_index,
			"backstab_multiplier": float(hand_card.get("backstab_multiplier", 1.75)),
			"combo_gain": int(hand_card.get("combo_gain", 1)),
		})

func enemy_forward_direction(enemy: Variant) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return Vector2.RIGHT
	var velocity_like: Vector2 = enemy.destination - enemy.global_position
	if velocity_like.length() > 3.0:
		return velocity_like.normalized()
	var target_position: Vector2 = enemy_target_position(enemy)
	var target_direction: Vector2 = target_position - enemy.global_position
	if target_direction.length() > 3.0:
		return target_direction.normalized()
	return Vector2.RIGHT

func enemy_is_active(enemy: Variant) -> bool:
	return enemy != null and is_instance_valid(enemy) and (not enemy.has_method("is_dying_state") or not enemy.is_dying_state())

func actor_weight(actor: Variant) -> float:
	if actor == null or not is_instance_valid(actor):
		return 1.0
	return maxf(float(actor.get("weight")), 0.1)

func find_enemy_by_uid(enemy_uid: int) -> Variant:
	for enemy in enemies:
		if enemy_is_active(enemy) and int(enemy.enemy_uid) == enemy_uid:
			return enemy
	return null

func find_hero_by_index(hero_index: int) -> Variant:
	if hero_index < 0 or hero_index >= heroes.size():
		return null
	var hero: Variant = heroes[hero_index]
	return hero if hero_is_active(hero) else null

func knockback_actor(actor: Variant, direction: Vector2, distance: float, room_coord: Vector2i) -> void:
	if actor == null or not is_instance_valid(actor) or direction == Vector2.ZERO or distance <= 0.0:
		return
	var target_position: Vector2 = clamp_point_to_room(actor.global_position + direction.normalized() * distance, room_coord)
	actor.global_position = target_position
	actor.set_destination(target_position)
	actor.reset_physics_interpolation()

func apply_weighted_melee_knockback(attacker: Variant, defender: Variant, room_coord: Vector2i, base_force: float = 26.0) -> void:
	if attacker == null or defender == null or not is_instance_valid(attacker) or not is_instance_valid(defender):
		return
	var push_direction: Vector2 = (defender.global_position - attacker.global_position).normalized()
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	var attacker_weight: float = actor_weight(attacker)
	var defender_weight: float = actor_weight(defender)
	if absf(attacker_weight - defender_weight) <= 0.18:
		knockback_actor(defender, push_direction, base_force * 0.58, room_coord)
		knockback_actor(attacker, -push_direction, base_force * 0.58, room_coord)
		return
	if attacker_weight > defender_weight:
		knockback_actor(defender, push_direction, base_force * clampf(attacker_weight / defender_weight, 1.0, 2.5), room_coord)
		knockback_actor(attacker, -push_direction, base_force * 0.2 * clampf(defender_weight / attacker_weight, 0.4, 1.0), room_coord)
		return
	knockback_actor(attacker, -push_direction, base_force * clampf(defender_weight / attacker_weight, 1.0, 2.5), room_coord)
	knockback_actor(defender, push_direction, base_force * 0.2 * clampf(attacker_weight / defender_weight, 0.4, 1.0), room_coord)

func attacker_pending_melee_key(attacker: Variant) -> String:
	if attacker == null or not is_instance_valid(attacker):
		return ""
	if attacker is Hero:
		return "hero:%d" % int(attacker.hero_index)
	return "enemy:%d" % int(attacker.enemy_uid)

func attacker_has_pending_melee(attacker: Variant) -> bool:
	var attacker_key: String = attacker_pending_melee_key(attacker)
	if attacker_key == "":
		return false
	for pending_attack_variant in pending_melee_attacks:
		var pending_attack: Dictionary = pending_attack_variant
		if String(pending_attack.get("attacker_key", "")) == attacker_key:
			return true
	return false

func queue_pending_melee_attack(attacker: Variant, target: Variant, damage: float, windup: float, source_label: String) -> void:
	if attacker == null or target == null or not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	if attacker_has_pending_melee(attacker):
		return
	var target_enemy_uid: int = int(target.enemy_uid) if target is DungeonEnemy else -1
	var target_hero_index: int = int(target.hero_index) if target is Hero else -1
	pending_melee_attacks.append({
		"attacker_key": attacker_pending_melee_key(attacker),
		"attacker_is_hero": attacker is Hero,
		"attacker_hero_index": int(attacker.hero_index) if attacker is Hero else -1,
		"attacker_enemy_uid": int(attacker.enemy_uid) if attacker is DungeonEnemy else -1,
		"target_hero_index": target_hero_index,
		"target_enemy_uid": target_enemy_uid,
		"damage": damage,
		"timer_left": maxf(windup, 0.05),
		"source_label": source_label,
	})

func finalize_hero_death(hero: Variant, source_label: String) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var was_selected: bool = hero.hero_index == selected_hero_index
	clear_pending_room_loot_request(hero.hero_index)
	clear_pending_room_action_request(hero.hero_index)
	if crystal_holder == hero:
		drop_crystal(hero.current_room)
	opening_heroes.erase(hero)
	if opening_hero == hero:
		opening_hero = opening_heroes[0] if not opening_heroes.is_empty() else null
	if opening_room != INVALID_ROOM and opening_heroes.is_empty():
		opening_room = INVALID_ROOM
		opening_origin_room = INVALID_ROOM
		opening_hero = null
		opening_timer_left = 0.0
	hero.combo_points = 0
	hero.clear_orders()
	hero.begin_death()
	if hero.hero_index >= 0 and hero.hero_index < hero_profiles.size():
		hero_profiles[hero.hero_index]["dead"] = true
	if was_selected:
		ensure_valid_selected_hero()
		var next_selected: Variant = selected_hero()
		if next_selected != null:
			selected_room = active_hero_room_for_commands(next_selected)
	update_selected_hero_flags()
	pending_melee_attacks = pending_melee_attacks.filter(func(entry: Dictionary) -> bool:
		return int(entry.get("attacker_hero_index", -1)) != hero.hero_index and int(entry.get("target_hero_index", -1)) != hero.hero_index
	)
	if alive_hero_count() <= 0:
		game_over = true
		status_message = "All heroes have fallen."
	else:
		status_message = "%s killed %s." % [source_label, hero.hero_name]
	update_hud()

func advance_pending_melee_attacks(delta: float) -> void:
	if pending_melee_attacks.is_empty():
		return
	var active_attacks: Array = []
	for pending_attack_variant in pending_melee_attacks:
		var pending_attack: Dictionary = pending_attack_variant
		pending_attack["timer_left"] = maxf(float(pending_attack.get("timer_left", 0.0)) - delta, 0.0)
		if float(pending_attack["timer_left"]) > 0.0:
			active_attacks.append(pending_attack)
			continue
		var attacker: Variant = find_hero_by_index(int(pending_attack.get("attacker_hero_index", -1))) if bool(pending_attack.get("attacker_is_hero", false)) else find_enemy_by_uid(int(pending_attack.get("attacker_enemy_uid", -1)))
		var target_enemy_uid: int = int(pending_attack.get("target_enemy_uid", -1))
		var target_hero_index: int = int(pending_attack.get("target_hero_index", -1))
		var target: Variant = find_enemy_by_uid(target_enemy_uid) if target_enemy_uid >= 0 else find_hero_by_index(target_hero_index)
		if attacker == null or target == null:
			continue
		var attack_room: Vector2i = attacker.current_room
		if target is Hero and not hero_is_in_room(target, attack_room):
			continue
		if target is DungeonEnemy and target.current_room != attack_room:
			continue
		var attack_range: float = attacker.attack_range if attacker is Hero else float(attacker.get("melee_reach"))
		if attacker.global_position.distance_to(target.global_position) > attack_range + 18.0:
			continue
		if target is Hero and try_auto_cast_fatal_shield(target, float(pending_attack.get("damage", 0.0))):
			continue
		var defeated: bool = target.take_damage(float(pending_attack.get("damage", 0.0)))
		if not defeated:
			apply_weighted_melee_knockback(attacker, target, attack_room)
		elif target is Hero:
			finalize_hero_death(target, String(pending_attack.get("source_label", "An enemy")))
	pending_melee_attacks = active_attacks

func apply_card_projectile_hits(projectile: Dictionary) -> void:
	var projectile_kind: String = String(projectile.get("kind", ""))
	if projectile_kind != "axe" and projectile_kind != "dagger":
		return
	var room_coord: Vector2i = projectile.get("room", INVALID_ROOM)
	var previous: Vector2 = projectile.get("previous", projectile.get("position", Vector2.ZERO))
	var current: Vector2 = projectile.get("position", Vector2.ZERO)
	var hit_radius: float = float(projectile.get("radius", 10.0))
	var already_hit: Array = Array(projectile.get("hit_enemy_uids", []))
	for enemy in enemies:
		if not enemy_is_active(enemy) or enemy.current_room != room_coord:
			continue
		if already_hit.has(int(enemy.enemy_uid)):
			continue
		if point_distance_to_segment(enemy.global_position, previous, current) > hit_radius:
			continue
		var damage: float = float(projectile.get("damage", 0.0))
		if projectile_kind == "dagger":
			var projectile_forward: Vector2 = Vector2(projectile.get("velocity", Vector2.RIGHT)).normalized()
			if projectile_forward.dot(enemy_forward_direction(enemy)) > 0.45:
				damage *= float(projectile.get("backstab_multiplier", 1.75))
				var owner_index: int = int(projectile.get("owner_hero_index", -1))
				if owner_index >= 0 and owner_index < heroes.size():
					var owner_hero: Variant = heroes[owner_index]
					if owner_hero != null and is_instance_valid(owner_hero):
						owner_hero.combo_points += int(projectile.get("combo_gain", 1))
		enemy.take_damage(damage)
		already_hit.append(int(enemy.enemy_uid))
	projectile["hit_enemy_uids"] = already_hit

func process_combat(_delta: float) -> void:
	advance_pending_melee_attacks(_delta)
	for hero in heroes:
		if not hero_is_active(hero):
			continue
		hero.cooldown_left = maxf(hero.cooldown_left - _delta, 0.0)
		if hero.carrying_crystal or hero.pending_room != Hero.INVALID_ROOM or hero.cooldown_left > 0.0 or attacker_has_pending_melee(hero):
			continue
		if hero.preferred_attack_style == "melee":
			var melee_target: Variant = nearest_enemy_in_room(hero.current_room, hero.global_position, 100000.0)
			if melee_target == null:
				continue
			var melee_offset: Vector2 = melee_target.global_position - hero.global_position
			var melee_distance: float = melee_offset.length()
			if melee_distance > hero.attack_range:
				if not active_hand_drag.is_empty() or hero_has_locked_player_command(hero):
					continue
				var engage_direction: Vector2 = melee_offset.normalized() if melee_distance > 0.001 else Vector2.RIGHT
				var desired_position: Vector2 = clamp_point_to_room(melee_target.global_position - engage_direction * minf(hero.attack_range * 0.35, 18.0), hero.current_room)
				issue_hero_steps(hero, build_steps_for_path([hero.current_room], hero.global_position, desired_position))
				continue
			hero.trigger_attack(melee_target.global_position, hero.preferred_attack_style)
			queue_pending_melee_attack(hero, melee_target, hero.attack_damage, hero.melee_windup_duration, hero.hero_name)
			hero.cooldown_left = hero.attack_cooldown
			continue
		var hero_target: Variant = nearest_enemy_in_room(hero.current_room, hero.global_position, hero.attack_range)
		if hero_target != null:
			hero.trigger_attack(hero_target.global_position, hero.preferred_attack_style)
			spawn_laser_projectile(hero.global_position, hero_target, hero.attack_damage, Color("ffe48a"), 5.5, 1220.0)
			hero.cooldown_left = hero.attack_cooldown

func process_modules(delta: float) -> void:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if not room["opened"] or not room["lit"]:
			continue
		var slot_positions: Array = minor_slot_positions(room_coord)
		for module_data in room["minor_modules"]:
			if float(module_data["health"]) <= 0.0 or bool(module_data.get("under_construction", false)):
				continue
			module_data["cooldown"] = maxf(float(module_data["cooldown"]) - delta, 0.0)
			if float(module_data["cooldown"]) > 0.0:
				continue
			var slot_index: int = int(module_data.get("slot_index", -1))
			if slot_index < 0 or slot_index >= slot_positions.size():
				continue
			var slot_position: Vector2 = slot_positions[slot_index]
			var turret_target: Variant = nearest_enemy_in_room(room_coord, slot_position, 620.0)
			if turret_target == null:
				continue
			var module_type: String = String(module_data.get("type", MINOR_MODULE_TURRET))
			module_data["cooldown"] = minor_module_cooldown(module_type)
			spawn_laser_projectile(slot_position, turret_target, minor_module_damage(module_type), minor_module_color(module_type), minor_module_projectile_width(module_type), minor_module_projectile_speed(module_type))

func spawn_laser_projectile(origin: Vector2, target: Variant, damage: float, color: Color = Color("89f2ff"), width: float = 4.0, speed: float = PROJECTILE_SPEED) -> void:
	projectiles.append({
		"kind": "laser",
		"position": origin,
		"previous": origin,
		"target": target,
		"target_position": target.global_position if is_instance_valid(target) else origin,
		"damage": damage,
		"speed": speed,
		"color": color,
		"width": width,
	})

func advance_projectiles(delta: float) -> void:
	var active_projectiles: Array = []
	for projectile in projectiles:
		var projectile_kind: String = String(projectile.get("kind", "laser"))
		if projectile_kind == "axe" or projectile_kind == "dagger":
			projectile["lifetime_left"] = float(projectile.get("lifetime_left", 0.0)) - delta
			if float(projectile["lifetime_left"]) <= 0.0:
				continue
			var previous_position: Vector2 = projectile.get("position", Vector2.ZERO)
			var current_position: Vector2 = previous_position
			var velocity: Vector2 = projectile.get("velocity", Vector2.ZERO)
			var room_coord: Vector2i = projectile.get("room", INVALID_ROOM)
			var room_bounds: Rect2 = room_rect(room_coord).grow(-14.0) if rooms.has(room_coord) else Rect2(current_position - Vector2(320.0, 220.0), Vector2(640.0, 440.0))
			var next_position: Vector2 = current_position + velocity * delta
			var remaining_bounces: int = int(projectile.get("remaining_bounces", 0))
			var bounced: bool = false
			if next_position.x < room_bounds.position.x or next_position.x > room_bounds.end.x:
				if remaining_bounces <= 0:
					continue
				velocity.x *= -1.0
				next_position.x = clampf(next_position.x, room_bounds.position.x, room_bounds.end.x)
				remaining_bounces -= 1
				bounced = true
			if next_position.y < room_bounds.position.y or next_position.y > room_bounds.end.y:
				if remaining_bounces <= 0:
					continue
				velocity.y *= -1.0
				next_position.y = clampf(next_position.y, room_bounds.position.y, room_bounds.end.y)
				remaining_bounces -= 1
				bounced = true
			projectile["previous"] = previous_position
			projectile["position"] = next_position
			projectile["velocity"] = velocity
			projectile["remaining_bounces"] = remaining_bounces
			projectile["rotation_angle"] = float(projectile.get("rotation_angle", 0.0)) + float(projectile.get("spin_speed", 0.0)) * delta
			apply_card_projectile_hits(projectile)
			if bounced and projectile_kind == "dagger":
				projectile["rotation_angle"] = velocity.angle()
			active_projectiles.append(projectile)
			continue
		if projectile_kind == "fireball_blast" or projectile_kind == "shield_flash" or projectile_kind == "lightning_bolt":
			projectile["lifetime_left"] = maxf(float(projectile.get("lifetime_left", 0.0)) - delta, 0.0)
			if float(projectile["lifetime_left"]) <= 0.0:
				continue
			active_projectiles.append(projectile)
			continue
		var current_position: Vector2 = projectile["position"]
		var target_position: Vector2 = projectile["target_position"]
		var target: Variant = projectile["target"]
		if enemy_is_active(target):
			target_position = target.global_position
			projectile["target_position"] = target_position
		else:
			target = null
		var offset: Vector2 = target_position - current_position
		if offset.length() <= 6.0:
			if enemy_is_active(target):
				target.take_damage(float(projectile["damage"]))
			continue
		var travel_distance: float = minf(float(projectile["speed"]) * delta, offset.length())
		projectile["previous"] = current_position
		projectile["position"] = current_position + offset.normalized() * travel_distance
		active_projectiles.append(projectile)
	projectiles = active_projectiles

func draw_projectiles() -> void:
	var view_rect: Rect2 = current_view_world_rect(140.0)
	for projectile in projectiles:
		var previous: Vector2 = projectile["previous"]
		var current_position: Vector2 = projectile["position"]
		if not view_rect.has_point(current_position) and not view_rect.has_point(previous):
			continue
		var color: Color = projectile["color"]
		var width: float = float(projectile.get("width", 4.0))
		var projectile_kind: String = String(projectile.get("kind", "laser"))
		if projectile_kind == "axe":
			var angle: float = float(projectile.get("rotation_angle", 0.0))
			var radius: float = float(projectile.get("radius", 17.0))
			draw_circle(current_position, radius * 0.55, color)
			draw_line(current_position + Vector2.RIGHT.rotated(angle) * radius, current_position - Vector2.RIGHT.rotated(angle) * radius, color.lightened(0.18), 5.0, true)
			draw_line(current_position + Vector2.UP.rotated(angle) * (radius * 0.8), current_position - Vector2.UP.rotated(angle) * (radius * 0.8), Color("fff7cf"), 3.0, true)
			continue
		if projectile_kind == "dagger":
			var velocity: Vector2 = Vector2(projectile.get("velocity", Vector2.RIGHT))
			var direction: Vector2 = velocity.normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT
			var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
			var tip: Vector2 = current_position + direction * 12.0
			var tail_left: Vector2 = current_position - direction * 8.0 + perpendicular * 4.0
			var tail_right: Vector2 = current_position - direction * 8.0 - perpendicular * 4.0
			draw_colored_polygon(PackedVector2Array([tip, tail_left, tail_right]), color)
			draw_line(current_position - direction * 10.0, current_position + direction * 4.0, Color("eff8ff"), 2.0, true)
			continue
		if projectile_kind == "fireball_blast":
			var duration: float = maxf(float(projectile.get("blast_duration", 0.24)), 0.001)
			var life_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / duration, 0.0, 1.0)
			var blast_radius: float = lerpf(10.0, float(projectile.get("impact_radius", projectile.get("radius", 92.0))), life_ratio)
			var blast_color: Color = color
			blast_color.a = 0.32 * (1.0 - life_ratio)
			draw_circle(current_position, blast_radius, blast_color)
			draw_arc(current_position, blast_radius, 0.0, TAU, 44, color.lightened(0.18), maxf(width * (1.0 - life_ratio * 0.35), 2.0), true)
			draw_circle(current_position, blast_radius * 0.42, Color(1.0, 0.95, 0.78, 0.18 * (1.0 - life_ratio)))
			continue
		if projectile_kind == "shield_flash":
			var shield_duration: float = maxf(float(projectile.get("blast_duration", 0.22)), 0.001)
			var shield_ratio: float = 1.0 - clampf(float(projectile.get("lifetime_left", 0.0)) / shield_duration, 0.0, 1.0)
			var shield_radius: float = lerpf(16.0, float(projectile.get("radius", 34.0)), shield_ratio)
			draw_arc(current_position, shield_radius, 0.0, TAU, 40, Color(color.r, color.g, color.b, 0.75 - shield_ratio * 0.55), maxf(width * (1.0 - shield_ratio * 0.35), 1.5), true)
			draw_circle(current_position, shield_radius * 0.55, Color(color.r, color.g, color.b, 0.10))
			continue
		if projectile_kind == "lightning_bolt":
			var bolt_duration: float = maxf(float(projectile.get("blast_duration", 0.18)), 0.001)
			var bolt_ratio: float = clampf(float(projectile.get("lifetime_left", 0.0)) / bolt_duration, 0.0, 1.0)
			var origin: Vector2 = projectile.get("previous", current_position)
			draw_line(origin, current_position, Color(1.0, 0.98, 0.86, 0.95 * bolt_ratio), width + 3.0, true)
			draw_line(origin, current_position, Color(color.r, color.g, color.b, 0.9 * bolt_ratio), width, true)
			draw_circle(current_position, 6.0 + 6.0 * bolt_ratio, Color(color.r, color.g, color.b, 0.38))
			continue
		draw_line(previous, current_position, color, width, true)
		draw_circle(current_position, 3.0, color)

func nearest_enemy_in_room(room_coord: Vector2i, origin: Vector2, max_range: float) -> Variant:
	var closest_enemy: Variant = null
	var closest_distance: float = max_range
	for enemy in enemies:
		if not enemy_is_active(enemy) or enemy.current_room != room_coord or enemy.moving_between_rooms:
			continue
		var distance: float = origin.distance_to(enemy.global_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	return closest_enemy

func cleanup_enemies() -> void:
	var alive_enemies: Array = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			alive_enemies.append(enemy)
	enemies = alive_enemies

func peer_can_control_hero(peer_id: int, hero_index: int) -> bool:
	return hero_index >= 0 and hero_index < hero_owner_peer_ids.size() and int(hero_owner_peer_ids[hero_index]) == peer_id

func maybe_broadcast_network_snapshot(delta: float) -> void:
	if not multiplayer_session_active() or not multiplayer.is_server():
		return
	network_snapshot_timer += delta
	if network_snapshot_timer < NETWORK_SNAPSHOT_INTERVAL:
		return
	network_snapshot_timer = 0.0
	broadcast_network_snapshot()

func broadcast_network_snapshot() -> void:
	if not multiplayer_session_active() or not multiplayer.is_server():
		return
	receive_network_snapshot.rpc(build_network_snapshot())

func build_network_snapshot() -> Dictionary:
	var hero_states: Array = []
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		hero_states.append({
			"hero_index": hero.hero_index,
			"hero_name": hero.hero_name,
			"hero_class_id": hero.hero_class_id,
			"level": hero.level,
			"pack_modules": hero.pack_modules.duplicate(true),
			"inventory_items": hero.inventory_items.duplicate(true),
			"position": hero.global_position,
			"destination": hero.destination,
			"current_room": hero.current_room,
			"pending_room": hero.pending_room,
			"pending_open_room": hero.pending_open_room,
			"pending_open_origin_room": hero.pending_open_origin_room,
			"player_command_locked": hero.player_command_locked,
			"current_health": hero.current_health,
			"max_health": hero.max_health,
			"stamina": hero.stamina,
			"max_stamina": hero.max_stamina,
			"stamina_regen_rate": hero.stamina_regen_rate,
			"stamina_regen_time_left": hero.stamina_regen_time_left,
			"barrier_amount": hero.barrier_amount,
			"barrier_capacity": hero.barrier_capacity,
			"barrier_time_left": hero.barrier_time_left,
			"invulnerability_time_left": hero.invulnerability_time_left,
			"max_hand_size": hero.max_hand_size,
			"combo_points": hero.combo_points,
			"hand_cards": hero.hand_cards.duplicate(true),
			"attack_damage": hero.attack_damage,
			"attack_range": hero.attack_range,
			"attack_cooldown": hero.attack_cooldown,
			"move_speed": hero.move_speed,
			"cooldown_left": hero.cooldown_left,
			"carrying_crystal": hero.carrying_crystal,
			"dead_started": hero.dead_started,
			"attack_effect_left": hero.attack_effect_left,
			"attack_direction": hero.attack_direction,
			"attack_style": hero.attack_style,
			"preferred_attack_style": hero.preferred_attack_style,
			"calm_multiplier": hero.calm_move_speed_multiplier,
			"combat_multiplier": hero.combat_move_speed_multiplier,
			"combat_mode": hero.combat_movement_mode,
			"light_cantrip_active": hero.light_cantrip_active,
			"learned_spells": hero.learned_spells.duplicate(),
			"slotted_spells": hero.slotted_spells.duplicate(),
			"active_floor_spells": hero.active_floor_spells.duplicate(),
			"studying_spell_id": hero.studying_spell_id,
			"studying_room": hero.studying_room,
			"studying_started_at_door": hero.studying_started_at_door,
		})
	var projectile_states: Array = []
	for projectile_variant in projectiles:
		var projectile: Dictionary = projectile_variant
		projectile_states.append({
			"kind": projectile.get("kind", "laser"),
			"position": projectile.get("position", Vector2.ZERO),
			"previous": projectile.get("previous", Vector2.ZERO),
			"target_position": projectile.get("target_position", Vector2.ZERO),
			"velocity": projectile.get("velocity", Vector2.ZERO),
			"damage": float(projectile.get("damage", 0.0)),
			"speed": float(projectile.get("speed", PROJECTILE_SPEED)),
			"color": projectile.get("color", Color.WHITE),
			"width": float(projectile.get("width", 4.0)),
			"radius": float(projectile.get("radius", 0.0)),
			"impact_radius": float(projectile.get("impact_radius", 0.0)),
			"room": projectile.get("room", INVALID_ROOM),
			"lifetime_left": float(projectile.get("lifetime_left", 0.0)),
			"blast_duration": float(projectile.get("blast_duration", 0.0)),
			"remaining_bounces": int(projectile.get("remaining_bounces", 0)),
			"rotation_angle": float(projectile.get("rotation_angle", 0.0)),
			"spin_speed": float(projectile.get("spin_speed", 0.0)),
			"hit_enemy_uids": Array(projectile.get("hit_enemy_uids", [])).duplicate(true),
			"owner_hero_index": int(projectile.get("owner_hero_index", -1)),
			"backstab_multiplier": float(projectile.get("backstab_multiplier", 1.0)),
			"combo_gain": int(projectile.get("combo_gain", 0)),
		})
	var enemy_states: Array = []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		enemy_states.append({
			"enemy_uid": enemy.enemy_uid,
			"position": enemy.global_position,
			"destination": enemy.destination,
			"current_room": enemy.current_room,
			"pending_room": enemy.pending_room,
			"previous_room": enemy.previous_room,
			"next_room": enemy.next_room,
			"moving_between_rooms": enemy.moving_between_rooms,
			"enemy_role": enemy.enemy_role,
			"current_health": enemy.current_health,
			"attack_cooldown_left": enemy.attack_cooldown_left,
			"death_started": enemy.death_started,
		})
	return {
		"rooms": rooms.duplicate(true),
		"projectiles": projectile_states,
		"floating_resource_texts": floating_resource_texts.duplicate(true),
		"pending_enemy_spawns": pending_enemy_spawns.duplicate(true),
		"pending_room_constructions": pending_room_constructions.duplicate(true),
		"global_item_card_states": global_item_card_states.duplicate(true),
		"global_item_passive_timers": global_item_passive_timers.duplicate(true),
		"hero_owner_peer_ids": hero_owner_peer_ids.duplicate(true),
		"lobby_peer_ready": lobby_peer_ready.duplicate(true),
		"lobby_game_started": lobby_game_started,
		"heroes": hero_states,
		"enemies": enemy_states,
		"opening_room": opening_room,
		"opening_origin_room": opening_origin_room,
		"opening_timer_left": opening_timer_left,
		"selected_room": selected_room,
		"crystal_room": crystal_room,
		"exit_room": exit_room,
		"floor_index": floor_index,
		"dust": dust,
		"food": food,
		"industry": industry,
		"science": science,
		"crystal_health": crystal_health,
		"stamina_use_enabled": stamina_use_enabled,
		"opened_rooms": opened_rooms,
		"wave_index": wave_index,
		"doors_opened": doors_opened,
		"game_over": game_over,
		"status_message": status_message,
		"crystal_ground_room": crystal_ground_room,
		"crystal_holder_index": crystal_holder.hero_index if crystal_holder != null and is_instance_valid(crystal_holder) else -1,
		"door_wave_auto_heal_pending": door_wave_auto_heal_pending,
		"door_wave_healing_active": door_wave_healing_active,
		"next_enemy_uid": next_enemy_uid,
		"next_item_uid": next_item_uid,
	}

@rpc("authority", "call_remote", "reliable")
func receive_network_snapshot(snapshot: Dictionary) -> void:
	if authoritative_simulation_active():
		return
	apply_network_snapshot(snapshot)

func apply_network_snapshot(snapshot: Dictionary) -> void:
	var previous_lobby_started: bool = lobby_game_started
	rooms = Dictionary(snapshot.get("rooms", {})).duplicate(true)
	projectiles = Array(snapshot.get("projectiles", [])).duplicate(true)
	floating_resource_texts = Array(snapshot.get("floating_resource_texts", [])).duplicate(true)
	pending_enemy_spawns = Array(snapshot.get("pending_enemy_spawns", [])).duplicate(true)
	pending_room_constructions = Array(snapshot.get("pending_room_constructions", [])).duplicate(true)
	global_item_card_states = Dictionary(snapshot.get("global_item_card_states", global_item_card_states)).duplicate(true)
	global_item_passive_timers = Dictionary(snapshot.get("global_item_passive_timers", global_item_passive_timers)).duplicate(true)
	hero_owner_peer_ids = Array(snapshot.get("hero_owner_peer_ids", [])).duplicate(true)
	if hero_owner_peer_ids.size() != HERO_COUNT:
		reset_hero_owner_peer_ids()
	lobby_peer_ready = Dictionary(snapshot.get("lobby_peer_ready", {})).duplicate(true)
	lobby_game_started = bool(snapshot.get("lobby_game_started", lobby_game_started))
	opening_room = snapshot.get("opening_room", INVALID_ROOM)
	opening_origin_room = snapshot.get("opening_origin_room", INVALID_ROOM)
	opening_timer_left = float(snapshot.get("opening_timer_left", 0.0))
	selected_room = snapshot.get("selected_room", crystal_room)
	crystal_room = snapshot.get("crystal_room", crystal_room)
	exit_room = snapshot.get("exit_room", INVALID_ROOM)
	floor_index = int(snapshot.get("floor_index", floor_index))
	dust = int(snapshot.get("dust", dust))
	food = int(snapshot.get("food", food))
	industry = int(snapshot.get("industry", industry))
	science = int(snapshot.get("science", science))
	crystal_health = float(snapshot.get("crystal_health", crystal_health))
	stamina_use_enabled = bool(snapshot.get("stamina_use_enabled", stamina_use_enabled))
	opened_rooms = int(snapshot.get("opened_rooms", opened_rooms))
	wave_index = int(snapshot.get("wave_index", wave_index))
	doors_opened = int(snapshot.get("doors_opened", doors_opened))
	game_over = bool(snapshot.get("game_over", game_over))
	status_message = String(snapshot.get("status_message", status_message))
	crystal_ground_room = snapshot.get("crystal_ground_room", INVALID_ROOM)
	door_wave_auto_heal_pending = bool(snapshot.get("door_wave_auto_heal_pending", false))
	door_wave_healing_active = bool(snapshot.get("door_wave_healing_active", false))
	next_enemy_uid = int(snapshot.get("next_enemy_uid", next_enemy_uid))
	next_item_uid = int(snapshot.get("next_item_uid", next_item_uid))
	apply_hero_snapshots(Array(snapshot.get("heroes", [])))
	apply_enemy_snapshots(Array(snapshot.get("enemies", [])))
	var crystal_holder_index: int = int(snapshot.get("crystal_holder_index", -1))
	crystal_holder = heroes[crystal_holder_index] if crystal_holder_index >= 0 and crystal_holder_index < heroes.size() else null
	if crystal_holder != null or crystal_ground_room == INVALID_ROOM or not is_exit_discovered():
		crystal_prompt_visible = false
	ensure_valid_selected_hero()
	var local_selected: Variant = selected_hero()
	if local_selected != null and is_instance_valid(local_selected):
		selected_room = active_hero_room_for_commands(local_selected)
	if lobby_game_started and not previous_lobby_started and hero_select_overlay != null:
		hero_select_overlay.visible = false
		if hero_select_toggle_button != null:
			hero_select_toggle_button.text = "Lobby"
	process_client_pending_local_requests()
	refresh_camera_bounds()
	update_hud()
	queue_redraw()

func process_client_pending_local_requests() -> void:
	if authoritative_simulation_active():
		return
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		if try_open_pending_room_loot_request(hero):
			return

func apply_hero_snapshots(hero_states: Array) -> void:
	ensure_hero_profiles()
	for hero_state_variant in hero_states:
		var hero_state: Dictionary = hero_state_variant
		var hero_index: int = int(hero_state.get("hero_index", -1))
		if hero_index < 0 or hero_index >= heroes.size():
			continue
		var hero: Variant = heroes[hero_index]
		if hero == null or not is_instance_valid(hero):
			continue
		var hero_class_id: String = String(hero_state.get("hero_class_id", hero.hero_class_id))
		var hero_name: String = String(hero_state.get("hero_name", hero.hero_name))
		apply_hero_class_to_node(hero, hero_class_id, hero_name)
		hero_profiles[hero_index]["class_id"] = hero_class_id
		hero_profiles[hero_index]["name"] = hero_name
		hero_profiles[hero_index]["dead"] = bool(hero_state.get("dead_started", false))
		hero.level = int(hero_state.get("level", hero.level))
		hero.pack_modules = Array(hero_state.get("pack_modules", hero.pack_modules)).duplicate(true)
		hero.inventory_items = Array(hero_state.get("inventory_items", hero.inventory_items)).duplicate(true)
		hero.learned_spells = Array(hero_state.get("learned_spells", hero.learned_spells)).duplicate()
		hero.slotted_spells = Array(hero_state.get("slotted_spells", hero.slotted_spells)).duplicate()
		hero.active_floor_spells = Array(hero_state.get("active_floor_spells", hero.active_floor_spells)).duplicate()
		hero.studying_spell_id = String(hero_state.get("studying_spell_id", hero.studying_spell_id))
		hero.studying_room = hero_state.get("studying_room", hero.studying_room)
		hero.studying_started_at_door = int(hero_state.get("studying_started_at_door", hero.studying_started_at_door))
		sanitize_hero_spellbook(hero)
		hero_profiles[hero_index]["learned_spells"] = hero.learned_spells.duplicate()
		hero_profiles[hero_index]["slotted_spells"] = hero.slotted_spells.duplicate()
		hero.stamina = float(hero_state.get("stamina", hero.stamina))
		hero.max_stamina = float(hero_state.get("max_stamina", hero.max_stamina))
		hero.stamina_regen_rate = float(hero_state.get("stamina_regen_rate", hero.stamina_regen_rate))
		hero.stamina_regen_time_left = float(hero_state.get("stamina_regen_time_left", hero.stamina_regen_time_left))
		hero.barrier_amount = float(hero_state.get("barrier_amount", hero.barrier_amount))
		hero.barrier_capacity = float(hero_state.get("barrier_capacity", hero.barrier_capacity))
		hero.barrier_time_left = float(hero_state.get("barrier_time_left", hero.barrier_time_left))
		hero.invulnerability_time_left = float(hero_state.get("invulnerability_time_left", hero.invulnerability_time_left))
		hero.max_hand_size = int(hero_state.get("max_hand_size", hero.max_hand_size))
		hero.combo_points = int(hero_state.get("combo_points", hero.combo_points))
		hero.hand_cards = Array(hero_state.get("hand_cards", hero.hand_cards)).duplicate(true)
		hero.move_speed = float(hero_state.get("move_speed", hero.move_speed))
		hero.max_health = float(hero_state.get("max_health", hero.max_health))
		hero.attack_damage = float(hero_state.get("attack_damage", hero.attack_damage))
		hero.attack_range = float(hero_state.get("attack_range", hero.attack_range))
		hero.attack_cooldown = float(hero_state.get("attack_cooldown", hero.attack_cooldown))
		hero.current_health = float(hero_state.get("current_health", hero.current_health))
		if bool(hero_state.get("dead_started", false)):
			hero.begin_death()
		hero.cooldown_left = float(hero_state.get("cooldown_left", hero.cooldown_left))
		hero.current_room = hero_state.get("current_room", hero.current_room)
		hero.pending_room = hero_state.get("pending_room", hero.pending_room)
		hero.pending_open_room = hero_state.get("pending_open_room", hero.pending_open_room)
		hero.pending_open_origin_room = hero_state.get("pending_open_origin_room", hero.pending_open_origin_room)
		hero.player_command_locked = bool(hero_state.get("player_command_locked", hero.player_command_locked))
		hero.carrying_crystal = bool(hero_state.get("carrying_crystal", false))
		hero.attack_effect_left = float(hero_state.get("attack_effect_left", 0.0))
		hero.attack_direction = Vector2(hero_state.get("attack_direction", Vector2.RIGHT))
		hero.attack_style = String(hero_state.get("attack_style", ""))
		hero.preferred_attack_style = String(hero_state.get("preferred_attack_style", hero.preferred_attack_style))
		hero.combat_move_speed_multiplier = float(hero_state.get("combat_multiplier", hero.combat_move_speed_multiplier))
		hero.set_calm_movement_multiplier(float(hero_state.get("calm_multiplier", hero.calm_move_speed_multiplier)))
		hero.set_combat_movement_mode(bool(hero_state.get("combat_mode", false)))
		hero.light_cantrip_active = bool(hero_state.get("light_cantrip_active", hero.light_cantrip_active))
		hero.global_position = Vector2(hero_state.get("position", hero.global_position))
		hero.destination = Vector2(hero_state.get("destination", hero.destination))
		hero.move_steps.clear()
		hero.queue_redraw()

func apply_enemy_snapshots(enemy_states: Array) -> void:
	var existing_by_uid: Dictionary = {}
	for enemy in enemies:
		if is_instance_valid(enemy):
			existing_by_uid[int(enemy.enemy_uid)] = enemy
	var synced_enemies: Array = []
	for enemy_state_variant in enemy_states:
		var enemy_state: Dictionary = enemy_state_variant
		var enemy_uid: int = int(enemy_state.get("enemy_uid", -1))
		if enemy_uid < 0:
			continue
		var enemy: Variant = existing_by_uid.get(enemy_uid, null)
		if enemy == null or not is_instance_valid(enemy):
			enemy = ENEMY_SCENE.instantiate()
			enemy.enemy_uid = enemy_uid
			enemy_layer.add_child(enemy)
		existing_by_uid.erase(enemy_uid)
		enemy.set_role(String(enemy_state.get("enemy_role", ENEMY_TYPE_GOBLIN)))
		enemy.current_health = float(enemy_state.get("current_health", enemy.current_health))
		enemy.attack_cooldown_left = float(enemy_state.get("attack_cooldown_left", enemy.attack_cooldown_left))
		enemy.current_room = enemy_state.get("current_room", enemy.current_room)
		enemy.pending_room = enemy_state.get("pending_room", enemy.pending_room)
		enemy.previous_room = enemy_state.get("previous_room", enemy.previous_room)
		enemy.next_room = enemy_state.get("next_room", enemy.next_room)
		enemy.moving_between_rooms = bool(enemy_state.get("moving_between_rooms", false))
		enemy.global_position = Vector2(enemy_state.get("position", enemy.global_position))
		enemy.destination = Vector2(enemy_state.get("destination", enemy.destination))
		enemy.move_steps.clear()
		if bool(enemy_state.get("death_started", false)):
			enemy.begin_death()
		synced_enemies.append(enemy)
		enemy.queue_redraw()
	for enemy_variant in existing_by_uid.values():
		var stale_enemy: Variant = enemy_variant
		if is_instance_valid(stale_enemy):
			stale_enemy.queue_free()
	enemies = synced_enemies

@rpc("any_peer", "call_remote", "reliable")
func server_request_world_command(hero_index: int, world_position: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	execute_world_command_for_hero(hero_index, world_position, false)
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_room_loot(hero_index: int, room_coord: Vector2i) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	request_room_loot_for_hero(hero_index, room_coord)
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_room_light(hero_index: int, room_coord: Vector2i) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	request_room_light_for_hero(hero_index, room_coord)
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_room_construction(hero_index: int, room_coord: Vector2i, module_type: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	request_room_construction_for_hero(hero_index, room_coord, module_type)
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_hero_class(hero_index: int, class_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	if hero_class_selection_locked():
		return
	if not HERO_CLASS_ORDER.has(class_id):
		return
	lobby_peer_ready[sender_peer_id] = false
	set_hero_profile_class(hero_index, class_id, true)
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_lobby_ready(ready: bool) -> void:
	if not multiplayer.is_server():
		return
	if lobby_game_started:
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	lobby_peer_ready[sender_peer_id] = ready
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_play_card(hero_index: int, card_uid: int, target_world_position: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	if play_card_for_hero(hero_index, card_uid, target_world_position):
		broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_pick_up_crystal(hero_index: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if crystal_holder != null or crystal_ground_room == INVALID_ROOM or not is_exit_discovered():
		return
	if hero.current_room != crystal_ground_room or hero.pending_room != Hero.INVALID_ROOM or not hero.is_idle():
		return
	crystal_holder = hero
	crystal_holder.carrying_crystal = true
	crystal_ground_room = INVALID_ROOM
	crystal_prompt_visible = false
	crystal_pressure_timer_left = CRYSTAL_PRESSURE_INTERVAL
	status_message = "%s picked up the crystal. Dark rooms will keep spawning." % hero.hero_name
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_exit_floor(hero_index: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero != crystal_holder or not all_heroes_in_exit_room():
		return
	floor_index += 1
	status_message = "Escaped to floor %d." % floor_index
	build_dungeon(false)
	spawn_heroes()
	assign_multiplayer_hero_owners_after_floor_transition()
	selected_room = crystal_room
	center_camera()
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_set_stamina_use_enabled(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	stamina_use_enabled = enabled
	status_message = "Stamina use %s." % ("enabled" if stamina_use_enabled else "disabled")
	update_hud()
	broadcast_network_snapshot()

func assign_multiplayer_hero_owners_after_floor_transition() -> void:
	if not multiplayer_session_active() or not multiplayer.is_server():
		return
	redistribute_multiplayer_hero_owners()
	ensure_valid_selected_hero()

@rpc("any_peer", "call_remote", "reliable")
func server_commit_inventory_state(hero_index: int, room_coord: Vector2i, items: Array, ground_items: Array) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	commit_inventory_state(hero_index, room_coord, items, ground_items)
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_commit_pack_layout(hero_index: int, pack_modules: Array) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	commit_pack_layout(hero_index, pack_modules)
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_commit_spell_slots(hero_index: int, slotted_spells: Array) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	commit_spell_slots(hero_index, slotted_spells)
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_commit_hand_state(hero_index: int, hand_state: Array) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	commit_hand_state(hero_index, hand_state)
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_inventory_level_up(hero_index: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if grant_level_up_pack_to_hero(hero):
		status_message = "%s reached level %d." % [hero.hero_name, hero.level]
	else:
		status_message = "Not enough food or no room for another pack."
	apply_inventory_stats_to_hero(hero)
	update_hud()
	broadcast_network_snapshot()

@rpc("any_peer", "call_remote", "reliable")
func server_request_inventory_drop(hero_index: int, item: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if not peer_can_control_hero(sender_peer_id, hero_index):
		return
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not rooms.has(hero.current_room):
		return
	var dropped_item: Dictionary = item.duplicate(true)
	dropped_item.erase("anchor")
	if not dropped_item.has("uid"):
		dropped_item["uid"] = next_item_uid
		next_item_uid += 1
	dropped_item["position"] = clamp_point_to_room(hero.global_position + Vector2(0.0, 34.0) + random_room_offset(18.0), hero.current_room)
	rooms[hero.current_room]["ground_items"].append(dropped_item)
	status_message = "%s dropped %s." % [hero.hero_name, String(item_defs.get(String(dropped_item.get("item_id", "")), {}).get("name", "an item"))]
	update_hud()
	broadcast_network_snapshot()

func find_path(from_room: Vector2i, to_room: Vector2i, only_open_rooms: bool) -> Array[Vector2i]:
	if from_room == to_room:
		return [from_room]
	var frontier: Array[Vector2i] = [from_room]
	var came_from: Dictionary = {from_room: from_room}
	while not frontier.is_empty():
		var current: Vector2i = frontier[0]
		frontier.remove_at(0)
		if current == to_room:
			break
		for neighbor_variant in rooms[current]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if only_open_rooms and not rooms[neighbor]["opened"]:
				continue
			if came_from.has(neighbor):
				continue
			frontier.append(neighbor)
			came_from[neighbor] = current
	if not came_from.has(to_room):
		return []
	var path: Array[Vector2i] = []
	var cursor: Vector2i = to_room
	while true:
		path.append(cursor)
		if cursor == from_room:
			break
		cursor = came_from[cursor]
	path.reverse()
	return path

func room_at_world_position(world_position: Vector2) -> Vector2i:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if rooms[room_coord]["opened"] and room_rect(room_coord).has_point(world_position):
			return room_coord
	return INVALID_ROOM

func corridor_room_target_at_position(world_position: Vector2, preferred_from_room: Vector2i = INVALID_ROOM) -> Vector2i:
	var direct_room: Vector2i = room_at_world_position(world_position)
	if direct_room != INVALID_ROOM:
		return direct_room
	var best_room: Vector2i = INVALID_ROOM
	var best_distance: float = INF
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if not rooms[neighbor]["opened"]:
				continue
			if room_coord.x > neighbor.x or (room_coord.x == neighbor.x and room_coord.y > neighbor.y):
				continue
			var corridor_target: Dictionary = open_corridor_target_for_pair(world_position, room_coord, neighbor, preferred_from_room)
			if corridor_target.is_empty():
				continue
			var corridor_distance: float = float(corridor_target.get("distance", INF))
			if corridor_distance < best_distance:
				best_distance = corridor_distance
				best_room = corridor_target.get("room", INVALID_ROOM)
	return best_room

func open_corridor_target_for_pair(world_position: Vector2, room_a: Vector2i, room_b: Vector2i, preferred_from_room: Vector2i = INVALID_ROOM) -> Dictionary:
	var delta: Vector2i = room_b - room_a
	var direction: Vector2 = Vector2(float(delta.x), float(delta.y))
	if direction == Vector2.ZERO:
		return {}
	direction = direction.normalized()
	var tangent: Vector2 = Vector2(-direction.y, direction.x)
	var doorway_a: Vector2 = doorway_position(room_a, room_b)
	var doorway_b: Vector2 = doorway_position(room_b, room_a)
	var corridor_depth: float = doorway_a.distance_to(doorway_b)
	var offset: Vector2 = world_position - doorway_a
	var forward_distance: float = offset.dot(direction)
	var lateral_distance: float = absf(offset.dot(tangent))
	var room_a_half: Vector2 = room_size_for(room_a) * 0.5
	var room_b_half: Vector2 = room_size_for(room_b) * 0.5
	var lateral_limit: float = maxf(room_a_half.y, room_b_half.y) + 34.0 if delta.x != 0 else maxf(room_a_half.x, room_b_half.x) + 34.0
	if forward_distance < -18.0 or forward_distance > corridor_depth + 18.0 or lateral_distance > lateral_limit:
		return {}
	var target_room: Vector2i = INVALID_ROOM
	if preferred_from_room == room_a:
		target_room = room_b
	elif preferred_from_room == room_b:
		target_room = room_a
	else:
		target_room = room_b if forward_distance >= corridor_depth * 0.5 else room_a
	return {
		"room": target_room,
		"distance": point_distance_to_segment(world_position, doorway_a, doorway_b),
	}

func room_is_revealed(room_coord: Vector2i) -> bool:
	return rooms.has(room_coord) and rooms[room_coord]["opened"]

func frontier_target_at_position(world_position: Vector2) -> Dictionary:
	var door_target: Dictionary = frontier_door_at_position(world_position)
	if not door_target.is_empty():
		return door_target
	var wall_target: Dictionary = frontier_wall_target_at_position(world_position)
	if not wall_target.is_empty():
		return wall_target
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if rooms[neighbor]["opened"]:
				continue
			if hidden_room_entry_zone_contains(world_position, room_coord, neighbor):
				return {
					"from_room": room_coord,
					"to_room": neighbor,
				}
			var open_doorway: Vector2 = doorway_position(room_coord, neighbor)
			var hidden_doorway: Vector2 = doorway_position(neighbor, room_coord)
			if point_distance_to_segment(world_position, open_doorway, hidden_doorway) <= 28.0:
				return {
					"from_room": room_coord,
					"to_room": neighbor,
				}
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if rooms[room_coord]["opened"] or not room_rect(room_coord).has_point(world_position):
			continue
		var opened_neighbors: Array[Vector2i] = []
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if rooms[neighbor]["opened"]:
				opened_neighbors.append(neighbor)
		if opened_neighbors.is_empty():
			continue
		var best_from_room: Vector2i = opened_neighbors[0]
		var best_distance: float = doorway_position(best_from_room, room_coord).distance_to(world_position)
		for opened_neighbor in opened_neighbors:
			var doorway_distance: float = doorway_position(opened_neighbor, room_coord).distance_to(world_position)
			if doorway_distance < best_distance:
				best_distance = doorway_distance
				best_from_room = opened_neighbor
		return {
			"from_room": best_from_room,
			"to_room": room_coord,
		}
	return {}

func frontier_wall_target_at_position(world_position: Vector2) -> Dictionary:
	var best_target: Dictionary = {}
	var best_distance: float = INF
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		var room_rect_value: Rect2 = room_rect(room_coord)
		var room_center_point: Vector2 = room_rect_value.get_center()
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if rooms[neighbor]["opened"]:
				continue
			var delta: Vector2i = neighbor - room_coord
			var doorway: Vector2 = doorway_position(room_coord, neighbor)
			var hit_distance: float = INF
			match delta:
				Vector2i.RIGHT:
					var within_x_right: bool = world_position.x >= room_rect_value.end.x - 38.0 and world_position.x <= room_rect_value.end.x + 42.0
					var within_y_right: bool = absf(world_position.y - doorway.y) <= maxf(room_rect_value.size.y * 0.32, 52.0)
					if within_x_right and within_y_right:
						hit_distance = absf(world_position.x - room_rect_value.end.x) + absf(world_position.y - doorway.y) * 0.25
				Vector2i.LEFT:
					var within_x_left: bool = world_position.x <= room_rect_value.position.x + 38.0 and world_position.x >= room_rect_value.position.x - 42.0
					var within_y_left: bool = absf(world_position.y - doorway.y) <= maxf(room_rect_value.size.y * 0.32, 52.0)
					if within_x_left and within_y_left:
						hit_distance = absf(world_position.x - room_rect_value.position.x) + absf(world_position.y - doorway.y) * 0.25
				Vector2i.DOWN:
					var within_y_down: bool = world_position.y >= room_rect_value.end.y - 38.0 and world_position.y <= room_rect_value.end.y + 42.0
					var within_x_down: bool = absf(world_position.x - doorway.x) <= maxf(room_rect_value.size.x * 0.32, 52.0)
					if within_y_down and within_x_down:
						hit_distance = absf(world_position.y - room_rect_value.end.y) + absf(world_position.x - doorway.x) * 0.25
				Vector2i.UP:
					var within_y_up: bool = world_position.y <= room_rect_value.position.y + 38.0 and world_position.y >= room_rect_value.position.y - 42.0
					var within_x_up: bool = absf(world_position.x - doorway.x) <= maxf(room_rect_value.size.x * 0.32, 52.0)
					if within_y_up and within_x_up:
						hit_distance = absf(world_position.y - room_rect_value.position.y) + absf(world_position.x - doorway.x) * 0.25
			if hit_distance >= INF:
				continue
			if room_center_point.distance_to(world_position) > maxf(room_rect_value.size.x, room_rect_value.size.y):
				continue
			if hit_distance < best_distance:
				best_distance = hit_distance
				best_target = {
					"from_room": room_coord,
					"to_room": neighbor,
				}
	return best_target

func frontier_door_at_position(world_position: Vector2) -> Dictionary:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if rooms[neighbor]["opened"]:
				continue
			var doorway: Vector2 = doorway_position(room_coord, neighbor)
			var stub_position: Vector2 = doorway + (room_center(neighbor) - room_center(room_coord)).normalized() * 12.0
			if stub_position.distance_to(world_position) <= FRONTIER_DOOR_RADIUS:
				return {
					"from_room": room_coord,
				"to_room": neighbor,
			}
	return {}

func point_distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment: Vector2 = end - start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(start)
	var t: float = clampf((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest_point: Vector2 = start + segment * t
	return point.distance_to(closest_point)

func hidden_room_entry_zone_contains(world_position: Vector2, from_room: Vector2i, to_room: Vector2i) -> bool:
	var delta: Vector2i = to_room - from_room
	var direction: Vector2 = Vector2(float(delta.x), float(delta.y))
	if direction == Vector2.ZERO:
		return false
	direction = direction.normalized()
	var tangent: Vector2 = Vector2(-direction.y, direction.x)
	var doorway: Vector2 = doorway_position(from_room, to_room)
	var hidden_doorway: Vector2 = doorway_position(to_room, from_room)
	var corridor_depth: float = doorway.distance_to(hidden_doorway)
	var offset: Vector2 = world_position - doorway
	var forward_distance: float = offset.dot(direction)
	var lateral_distance: float = absf(offset.dot(tangent))
	var hidden_half: Vector2 = room_size_for(to_room) * 0.5
	var lateral_limit: float = hidden_half.y + 42.0 if delta.x != 0 else hidden_half.x + 42.0
	var forward_limit: float = corridor_depth + 126.0
	return forward_distance >= -18.0 and forward_distance <= forward_limit and lateral_distance <= lateral_limit

func room_center(room_coord: Vector2i) -> Vector2:
	if rooms.has(room_coord) and rooms[room_coord].has("center"):
		return Vector2(rooms[room_coord]["center"])
	var offset_x: float = (float(room_coord.x) - float(GRID_SIZE.x - 1) * 0.5) * ROOM_SPACING.x
	var offset_y: float = (float(room_coord.y) - float(GRID_SIZE.y - 1) * 0.5) * ROOM_SPACING.y
	return Vector2(offset_x, offset_y)

func room_size_for(room_coord: Vector2i) -> Vector2:
	return rooms[room_coord]["size"]

func room_rect(room_coord: Vector2i) -> Rect2:
	var room_size: Vector2 = room_size_for(room_coord)
	return Rect2(room_center(room_coord) - room_size * 0.5, room_size)

func normalized_rect_to_room(room_coord: Vector2i, normalized_rect: Rect2) -> Rect2:
	var rect: Rect2 = room_rect(room_coord)
	return Rect2(
		rect.position + Vector2(normalized_rect.position.x * rect.size.x, normalized_rect.position.y * rect.size.y),
		Vector2(normalized_rect.size.x * rect.size.x, normalized_rect.size.y * rect.size.y)
	)

func room_layout_regions(room_coord: Vector2i, key: String, inset: float = 0.0) -> Array:
	if not rooms.has(room_coord):
		return []
	var normalized_regions: Array = Array(rooms[room_coord].get(key, []))
	if normalized_regions.is_empty():
		var fallback_rect: Rect2 = room_rect(room_coord).grow(-maxf(inset, 26.0))
		return [fallback_rect]
	var regions: Array = []
	for rect_variant in normalized_regions:
		var world_rect: Rect2 = normalized_rect_to_room(room_coord, Rect2(rect_variant))
		if inset > 0.0:
			var inset_amount: float = minf(inset, minf(world_rect.size.x, world_rect.size.y) * 0.48)
			world_rect = world_rect.grow(-inset_amount)
		if world_rect.size.x <= 6.0 or world_rect.size.y <= 6.0:
			continue
		regions.append(world_rect)
	return regions

func room_walkable_regions(room_coord: Vector2i, inset: float = ROOM_WALKABLE_INSET) -> Array:
	return room_layout_regions(room_coord, "walkable_regions", inset)

func room_slot_regions(room_coord: Vector2i, inset: float = ROOM_SLOT_INSET) -> Array:
	return room_layout_regions(room_coord, "slot_regions", inset)

func largest_region_rect(regions: Array) -> Rect2:
	if regions.is_empty():
		return Rect2()
	var largest_rect: Rect2 = Rect2(regions[0])
	var largest_area: float = largest_rect.size.x * largest_rect.size.y
	for region_variant in regions:
		var region_rect: Rect2 = Rect2(region_variant)
		var region_area: float = region_rect.size.x * region_rect.size.y
		if region_area > largest_area:
			largest_area = region_area
			largest_rect = region_rect
	return largest_rect

func bounding_rect_for_regions(regions: Array) -> Rect2:
	if regions.is_empty():
		return Rect2()
	var bounds: Rect2 = Rect2(regions[0])
	var min_point: Vector2 = bounds.position
	var max_point: Vector2 = bounds.end
	for region_variant in regions:
		var region_rect: Rect2 = Rect2(region_variant)
		min_point.x = minf(min_point.x, region_rect.position.x)
		min_point.y = minf(min_point.y, region_rect.position.y)
		max_point.x = maxf(max_point.x, region_rect.end.x)
		max_point.y = maxf(max_point.y, region_rect.end.y)
	return Rect2(min_point, max_point - min_point)

func room_slot_anchor_rect(room_coord: Vector2i) -> Rect2:
	var slot_regions: Array = room_slot_regions(room_coord)
	if not slot_regions.is_empty():
		return bounding_rect_for_regions(slot_regions)
	var walkable_regions: Array = room_walkable_regions(room_coord)
	if not walkable_regions.is_empty():
		return largest_region_rect(walkable_regions)
	return room_rect(room_coord).grow(-26.0)

func closest_point_in_rect(world_position: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clampf(world_position.x, rect.position.x, rect.end.x),
		clampf(world_position.y, rect.position.y, rect.end.y)
	)

func room_walkable_contains_point(room_coord: Vector2i, world_position: Vector2, inset: float = ROOM_WALKABLE_INSET) -> bool:
	for region_variant in room_walkable_regions(room_coord, inset):
		if Rect2(region_variant).has_point(world_position):
			return true
	return false

func room_walkable_center(room_coord: Vector2i) -> Vector2:
	if not rooms.has(room_coord):
		return room_center(room_coord)
	var walkable_regions: Array = room_walkable_regions(room_coord)
	if walkable_regions.is_empty():
		return room_center(room_coord)
	var primary_rect: Rect2 = largest_region_rect(walkable_regions)
	return closest_point_in_rect(room_center(room_coord), primary_rect)

func random_point_in_regions(regions: Array) -> Vector2:
	if regions.is_empty():
		return Vector2.ZERO
	var total_area: float = 0.0
	for region_variant in regions:
		var region_rect: Rect2 = Rect2(region_variant)
		total_area += maxf(region_rect.size.x * region_rect.size.y, 1.0)
	var roll: float = rng.randf() * total_area
	for region_variant in regions:
		var candidate_rect: Rect2 = Rect2(region_variant)
		roll -= maxf(candidate_rect.size.x * candidate_rect.size.y, 1.0)
		if roll > 0.0:
			continue
		return Vector2(
			rng.randf_range(candidate_rect.position.x, candidate_rect.end.x),
			rng.randf_range(candidate_rect.position.y, candidate_rect.end.y)
		)
	var fallback_rect: Rect2 = Rect2(regions[regions.size() - 1])
	return fallback_rect.get_center()

func random_walkable_point(room_coord: Vector2i) -> Vector2:
	var walkable_regions: Array = room_walkable_regions(room_coord)
	if walkable_regions.is_empty():
		return clamp_point_to_room(room_center(room_coord), room_coord)
	return random_point_in_regions(walkable_regions)

func walkable_region_index_for_point(room_coord: Vector2i, world_position: Vector2, inset: float = ROOM_WALKABLE_INSET) -> int:
	var walkable_regions: Array = room_walkable_regions(room_coord, inset)
	if walkable_regions.is_empty():
		return -1
	for region_index in range(walkable_regions.size()):
		if Rect2(walkable_regions[region_index]).has_point(world_position):
			return region_index
	var best_index: int = 0
	var best_distance_squared: float = INF
	for region_index in range(walkable_regions.size()):
		var candidate_point: Vector2 = closest_point_in_rect(world_position, Rect2(walkable_regions[region_index]))
		var distance_squared: float = candidate_point.distance_squared_to(world_position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_index = region_index
	return best_index

func clear_enemy_room_navigation(enemy: Variant) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_meta("room_nav_waypoint"):
		enemy.remove_meta("room_nav_waypoint")
	if enemy.has_meta("room_nav_final"):
		enemy.remove_meta("room_nav_final")

func enemy_room_navigation_destination(enemy: Variant, room_coord: Vector2i, target_position: Vector2) -> Vector2:
	var clamped_target: Vector2 = clamp_point_to_room(target_position, room_coord)
	if enemy == null or not is_instance_valid(enemy):
		return clamped_target
	var walkable_regions: Array = room_walkable_regions(room_coord, 0.0)
	if walkable_regions.is_empty():
		return clamped_target
	var clamped_start: Vector2 = clamp_point_to_room(enemy.global_position, room_coord)
	var start_region_index: int = walkable_region_index_for_point(room_coord, clamped_start, 0.0)
	var target_region_index: int = walkable_region_index_for_point(room_coord, clamped_target, 0.0)
	if start_region_index < 0 or target_region_index < 0 or start_region_index == target_region_index:
		clear_enemy_room_navigation(enemy)
		return clamped_target
	var primary_region: Rect2 = largest_region_rect(walkable_regions)
	var start_in_primary: bool = primary_region.has_point(clamped_start)
	var target_in_primary: bool = primary_region.has_point(clamped_target)
	clear_enemy_room_navigation(enemy)
	if not start_in_primary:
		return closest_point_in_rect(clamped_start, primary_region)
	if not target_in_primary:
		return closest_point_in_rect(clamped_target, primary_region)
	return clamped_target

func clamp_point_to_room(world_position: Vector2, room_coord: Vector2i) -> Vector2:
	var walkable_regions: Array = room_walkable_regions(room_coord)
	if walkable_regions.is_empty():
		var padded_rect: Rect2 = room_rect(room_coord).grow(-26.0)
		return Vector2(
			clampf(world_position.x, padded_rect.position.x, padded_rect.end.x),
			clampf(world_position.y, padded_rect.position.y, padded_rect.end.y)
		)
	var nearest_point: Vector2 = room_walkable_center(room_coord)
	var nearest_distance_squared: float = INF
	for region_variant in walkable_regions:
		var candidate_point: Vector2 = closest_point_in_rect(world_position, Rect2(region_variant))
		var distance_squared: float = candidate_point.distance_squared_to(world_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_point = candidate_point
	return nearest_point

func doorway_position(from_room: Vector2i, to_room: Vector2i) -> Vector2:
	var room_half: Vector2 = room_size_for(from_room) * 0.5
	var center: Vector2 = room_center(from_room)
	var delta: Vector2i = to_room - from_room
	if delta.x != 0:
		return center + Vector2(float(delta.x) * (room_half.x - 20.0), 0.0)
	return center + Vector2(0.0, float(delta.y) * (room_half.y - 20.0))

func major_slot_position(room_coord: Vector2i) -> Vector2:
	var rect: Rect2 = room_slot_anchor_rect(room_coord)
	return rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.23)

func minor_slot_positions(room_coord: Vector2i) -> Array:
	var rect: Rect2 = room_slot_anchor_rect(room_coord)
	var count: int = int(rooms[room_coord]["minor_slots"])
	var offsets: Array[Vector2] = []
	match count:
		0:
			offsets = []
		2:
			offsets = [
				Vector2(-0.24, 0.18),
				Vector2(0.24, 0.18),
			]
		3:
			offsets = [
				Vector2(-0.28, 0.02),
				Vector2(0.0, 0.22),
				Vector2(0.28, 0.02),
			]
		5:
			offsets = [
				Vector2(-0.30, -0.14),
				Vector2(0.0, -0.20),
				Vector2(0.30, -0.14),
				Vector2(-0.18, 0.18),
				Vector2(0.18, 0.18),
			]
		7:
			offsets = [
				Vector2(-0.34, -0.18),
				Vector2(0.0, -0.18),
				Vector2(0.34, -0.18),
				Vector2(-0.34, 0.06),
				Vector2(0.0, 0.06),
				Vector2(0.34, 0.06),
				Vector2(0.0, 0.30),
			]
		_:
			offsets = [
				Vector2(-0.26, -0.08),
				Vector2(0.26, -0.08),
				Vector2(-0.26, 0.22),
				Vector2(0.26, 0.22),
			]
	var slot_positions: Array = []
	for offset in offsets:
		slot_positions.append(rect.get_center() + Vector2(offset.x * rect.size.x, offset.y * rect.size.y))
	return slot_positions

func minor_module_index_for_slot(room_coord: Vector2i, slot_index: int) -> int:
	if not rooms.has(room_coord):
		return -1
	for module_index in range(rooms[room_coord]["minor_modules"].size()):
		var module_data: Dictionary = rooms[room_coord]["minor_modules"][module_index]
		if int(module_data.get("slot_index", -1)) == slot_index:
			return module_index
	return -1

func minor_slot_at_position(room_coord: Vector2i, world_position: Vector2) -> int:
	var slot_positions: Array = minor_slot_positions(room_coord)
	for slot_index in range(slot_positions.size()):
		if slot_positions[slot_index].distance_to(world_position) <= 28.0:
			return slot_index
	return -1

func draw_room_door_marker(room_coord: Vector2i, neighbor: Vector2i, accessible: bool) -> void:
	if not rooms.has(room_coord) or not rooms.has(neighbor):
		return
	var rect: Rect2 = room_rect(room_coord)
	var doorway: Vector2 = doorway_position(room_coord, neighbor)
	var delta: Vector2i = neighbor - room_coord
	var opening_half_width: float = DOOR_VISUAL_WIDTH * 0.5
	var background_color: Color = Color("0c1418")
	var threshold_fill: Color = Color("dbefff") if accessible else Color("f4d892")
	var threshold_shadow: Color = Color("31434d") if accessible else Color("685639")
	if delta.x != 0:
		var edge_x: float = rect.end.x if delta.x > 0 else rect.position.x
		var gap_rect: Rect2 = Rect2(Vector2(edge_x - 4.0, doorway.y - opening_half_width), Vector2(8.0, DOOR_VISUAL_WIDTH))
		draw_rect(gap_rect, background_color, true)
		var threshold_rect: Rect2 = Rect2(Vector2(edge_x - 2.0, doorway.y - opening_half_width + 2.0), Vector2(4.0, DOOR_VISUAL_WIDTH - 4.0))
		draw_rect(threshold_rect, threshold_shadow, true)
		draw_line(Vector2(edge_x, doorway.y - opening_half_width + 4.0), Vector2(edge_x, doorway.y + opening_half_width - 4.0), threshold_fill, DOOR_VISUAL_THICKNESS, true)
	else:
		var edge_y: float = rect.end.y if delta.y > 0 else rect.position.y
		var gap_rect_h: Rect2 = Rect2(Vector2(doorway.x - opening_half_width, edge_y - 4.0), Vector2(DOOR_VISUAL_WIDTH, 8.0))
		draw_rect(gap_rect_h, background_color, true)
		var threshold_rect_h: Rect2 = Rect2(Vector2(doorway.x - opening_half_width + 2.0, edge_y - 2.0), Vector2(DOOR_VISUAL_WIDTH - 4.0, 4.0))
		draw_rect(threshold_rect_h, threshold_shadow, true)
		draw_line(Vector2(doorway.x - opening_half_width + 4.0, edge_y), Vector2(doorway.x + opening_half_width - 4.0, edge_y), threshold_fill, DOOR_VISUAL_THICKNESS, true)

func major_slot_contains_point(room_coord: Vector2i, world_position: Vector2) -> bool:
	return major_slot_position(room_coord).distance_to(world_position) <= 28.0

func pending_minor_construction_for_slot(room_coord: Vector2i, slot_index: int) -> Dictionary:
	for construction_variant in pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", INVALID_ROOM) == room_coord and not bool(construction.get("is_major", false)) and int(construction.get("slot_index", -1)) == slot_index:
			return construction
	return {}

func pending_major_construction_for_room(room_coord: Vector2i) -> Dictionary:
	for construction_variant in pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", INVALID_ROOM) == room_coord and bool(construction.get("is_major", false)):
			return construction
	return {}

func cancel_pending_minor_construction(room_coord: Vector2i, slot_index: int) -> void:
	if slot_index < 0:
		return
	var active_constructions: Array = []
	for construction_variant in pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", INVALID_ROOM) == room_coord and not bool(construction.get("is_major", false)) and int(construction.get("slot_index", -1)) == slot_index:
			continue
		active_constructions.append(construction)
	pending_room_constructions = active_constructions

func cancel_pending_major_construction(room_coord: Vector2i) -> void:
	var active_constructions: Array = []
	for construction_variant in pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", INVALID_ROOM) == room_coord and bool(construction.get("is_major", false)):
			continue
		active_constructions.append(construction)
	pending_room_constructions = active_constructions

func should_highlight_minor_slot(room_coord: Vector2i, slot_index: int) -> bool:
	if not is_minor_module_type(pending_build_type) or not can_manage_modules(room_coord):
		return false
	var module_index: int = minor_module_index_for_slot(room_coord, slot_index)
	if module_index < 0:
		return true
	return float(rooms[room_coord]["minor_modules"][module_index]["health"]) < MINOR_MODULE_MAX_HEALTH

func should_highlight_major_slot(room_coord: Vector2i) -> bool:
	if not can_manage_modules(room_coord):
		return false
	if pending_build_type != MAJOR_MODULE_FOOD and pending_build_type != MAJOR_MODULE_SCIENCE and pending_build_type != MAJOR_MODULE_INDUSTRY:
		return false
	return can_build_or_repair_major(room_coord, pending_build_type)

func should_show_room_slot_guides(room_coord: Vector2i) -> bool:
	if not can_open_build_for_room(room_coord):
		return false
	var room: Dictionary = rooms[room_coord]
	return int(room.get("minor_slots", 0)) > 0 or int(room.get("major_slots", 0)) > 0

func random_room_offset(radius: float) -> Vector2:
	return Vector2(
		rng.randf_range(-radius, radius),
		rng.randf_range(-radius * 0.55, radius * 0.55)
	)

func draw_dungeon_connections() -> void:
	var view_rect: Rect2 = current_view_world_rect(120.0)
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		if not view_rect.intersects(room_rect(room_coord)):
			continue
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if not rooms[neighbor]["opened"]:
				continue
			if room_coord.x > neighbor.x or (room_coord.x == neighbor.x and room_coord.y > neighbor.y):
				continue
			var passage_color: Color = Color("31434d")
			if rooms[room_coord]["opened"] and rooms[neighbor]["opened"]:
				passage_color = Color("8aa8b7")
			var doorway_a: Vector2 = doorway_position(room_coord, neighbor)
			var doorway_b: Vector2 = doorway_position(neighbor, room_coord)
			draw_line(doorway_a, doorway_b, passage_color.darkened(0.35), DOOR_VISUAL_WIDTH + 2.0, true)
			draw_line(doorway_a, doorway_b, passage_color, DOOR_VISUAL_WIDTH * 0.58, true)

func draw_frontier_doors() -> void:
	var view_rect: Rect2 = current_view_world_rect(120.0)
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		if not view_rect.intersects(room_rect(room_coord)):
			continue
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if rooms[neighbor]["opened"]:
				continue
			var doorway: Vector2 = doorway_position(room_coord, neighbor)
			var direction: Vector2 = (room_center(neighbor) - room_center(room_coord)).normalized()
			var outer_position: Vector2 = doorway + direction * 14.0
			var tangent: Vector2 = Vector2(-direction.y, direction.x)
			draw_line(doorway - direction * 5.0, outer_position, Color("fff4cb"), 9.0, true)
			draw_line(doorway - direction * 3.0, outer_position, Color("7a6745"), 3.0, true)
			draw_circle(outer_position, 12.0, Color("203039"))
			draw_arc(outer_position, 13.0, 0.0, TAU, 28, Color("f6e39d"), 3.0, true)
			draw_line(outer_position - tangent * 5.0, outer_position + tangent * 5.0, Color("f6e39d"), 2.2, true)
			draw_line(outer_position - direction * 5.0, outer_position + direction * 5.0, Color("f6e39d"), 2.2, true)

func draw_soft_rect(rect: Rect2, fill: Color, outline: Color = Color.TRANSPARENT, outline_width: float = 0.0) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var radius: float = minf(minf(rect.size.x, rect.size.y) * 0.24, 24.0)
	radius = minf(radius, minf(rect.size.x * 0.5, rect.size.y * 0.5))
	var middle_width: float = maxf(rect.size.x - radius * 2.0, 0.0)
	var middle_height: float = maxf(rect.size.y - radius * 2.0, 0.0)
	if middle_width > 0.0:
		draw_rect(Rect2(rect.position + Vector2(radius, 0.0), Vector2(middle_width, rect.size.y)), fill, true)
	if middle_height > 0.0:
		draw_rect(Rect2(rect.position + Vector2(0.0, radius), Vector2(rect.size.x, middle_height)), fill, true)
	var top_left: Vector2 = rect.position + Vector2(radius, radius)
	var top_right: Vector2 = rect.position + Vector2(rect.size.x - radius, radius)
	var bottom_right: Vector2 = rect.position + Vector2(rect.size.x - radius, rect.size.y - radius)
	var bottom_left: Vector2 = rect.position + Vector2(radius, rect.size.y - radius)
	draw_circle(top_left, radius, fill)
	draw_circle(top_right, radius, fill)
	draw_circle(bottom_right, radius, fill)
	draw_circle(bottom_left, radius, fill)
	if outline_width <= 0.0 or outline.a <= 0.0:
		return
	draw_line(top_left + Vector2(0.0, -radius), top_right + Vector2(0.0, -radius), outline, outline_width, true)
	draw_line(top_right + Vector2(radius, 0.0), bottom_right + Vector2(radius, 0.0), outline, outline_width, true)
	draw_line(bottom_left + Vector2(0.0, radius), bottom_right + Vector2(0.0, radius), outline, outline_width, true)
	draw_line(top_left + Vector2(-radius, 0.0), bottom_left + Vector2(-radius, 0.0), outline, outline_width, true)
	draw_arc(top_left, radius, PI, PI * 1.5, 10, outline, outline_width, true)
	draw_arc(top_right, radius, PI * 1.5, TAU, 10, outline, outline_width, true)
	draw_arc(bottom_right, radius, 0.0, PI * 0.5, 10, outline, outline_width, true)
	draw_arc(bottom_left, radius, PI * 0.5, PI, 10, outline, outline_width, true)

func draw_liquid_region(rect: Rect2, fill: Color, glow: Color, outline: Color) -> void:
	draw_soft_rect(rect, fill, outline, 1.6)
	var inner_inset: float = minf(10.0, minf(rect.size.x, rect.size.y) * 0.22)
	if inner_inset > 1.0:
		var inner_rect: Rect2 = rect.grow(-inner_inset)
		draw_soft_rect(inner_rect, glow, Color.TRANSPARENT, 0.0)
	var wave_start: Vector2 = rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.50)
	var wave_end: Vector2 = rect.position + Vector2(rect.size.x * 0.82, rect.size.y * 0.50)
	draw_line(wave_start, wave_end, Color(glow.r, glow.g, glow.b, minf(glow.a + 0.18, 0.85)), 2.0, true)

func draw_growth_region(rect: Rect2, fill: Color, edge: Color) -> void:
	draw_soft_rect(rect, fill, edge, 1.2)
	var center: Vector2 = rect.get_center()
	var radius: float = minf(rect.size.x, rect.size.y) * 0.18
	draw_circle(center + Vector2(-rect.size.x * 0.16, 0.0), radius, Color(edge.r, edge.g, edge.b, 0.18))
	draw_circle(center + Vector2(rect.size.x * 0.12, rect.size.y * 0.06), radius * 0.92, Color(edge.r, edge.g, edge.b, 0.15))

func room_theme_palette(theme_id: String, lit: bool, crystal_chamber: bool) -> Dictionary:
	var palette: Dictionary = {}
	match theme_id:
		FLOOR_THEME_FUNGAL:
			palette = {
				"base_fill": Color("110d16"),
				"base_outline": Color(0.20, 0.15, 0.28, 0.32),
				"obstacle_fill": Color("17111f"),
				"obstacle_outline": Color("362845"),
				"floor_fill": Color("32273d"),
				"floor_outline": Color("8f7aa8"),
				"floor_grain": Color("4a3a56"),
				"liquid_fill": Color("291d3d"),
				"liquid_glow": Color(0.42, 0.22, 0.64, 0.20),
				"liquid_outline": Color("8d69bc"),
				"growth_fill": Color(0.28, 0.42, 0.32, 0.56),
				"growth_edge": Color("8ec29a"),
			}
			if lit:
				palette = {
					"base_fill": Color("2c2234"),
					"base_outline": Color(0.52, 0.44, 0.66, 0.48),
					"obstacle_fill": Color("3b2d48"),
					"obstacle_outline": Color("876aa6"),
					"floor_fill": Color("755a89"),
					"floor_outline": Color("f0e7ff"),
					"floor_grain": Color("9f7eb8"),
					"liquid_fill": Color("6c51a0"),
					"liquid_glow": Color(0.86, 0.66, 1.0, 0.36),
					"liquid_outline": Color("f3e2ff"),
					"growth_fill": Color(0.62, 0.88, 0.64, 0.88),
					"growth_edge": Color("f0ffd9"),
				}
		FLOOR_THEME_RUINS:
			palette = {
				"base_fill": Color("0f1214"),
				"base_outline": Color(0.18, 0.21, 0.23, 0.32),
				"obstacle_fill": Color("181d20"),
				"obstacle_outline": Color("39444a"),
				"floor_fill": Color("353d40"),
				"floor_outline": Color("7f8f95"),
				"floor_grain": Color("4b5558"),
				"liquid_fill": Color("1f3e45"),
				"liquid_glow": Color(0.20, 0.48, 0.52, 0.18),
				"liquid_outline": Color("679aa1"),
				"growth_fill": Color(0.34, 0.29, 0.16, 0.48),
				"growth_edge": Color("b09d5e"),
			}
			if lit:
				palette = {
					"base_fill": Color("282d30"),
					"base_outline": Color(0.46, 0.54, 0.57, 0.46),
					"obstacle_fill": Color("3c4346"),
					"obstacle_outline": Color("83969d"),
					"floor_fill": Color("798587"),
					"floor_outline": Color("f1fbfc"),
					"floor_grain": Color("97a3a6"),
					"liquid_fill": Color("4f8490"),
					"liquid_glow": Color(0.60, 0.96, 1.0, 0.34),
					"liquid_outline": Color("e0fdff"),
					"growth_fill": Color(0.78, 0.68, 0.38, 0.82),
					"growth_edge": Color("fff2b8"),
				}
		_:
			palette = {
				"base_fill": Color("100f0b"),
				"base_outline": Color(0.22, 0.19, 0.14, 0.30),
				"obstacle_fill": Color("181711"),
				"obstacle_outline": Color("2c291f"),
				"floor_fill": Color("373224"),
				"floor_outline": Color("726954"),
				"floor_grain": Color("494230"),
				"liquid_fill": Color("14110f"),
				"liquid_glow": Color(0.16, 0.13, 0.10, 0.08),
				"liquid_outline": Color("393227"),
				"growth_fill": Color(0.13, 0.12, 0.10, 0.42),
				"growth_edge": Color("4a4339"),
			}
			if lit:
				palette = {
					"base_fill": Color("2c2d20"),
					"base_outline": Color(0.54, 0.56, 0.40, 0.44),
					"obstacle_fill": Color("403d2d"),
					"obstacle_outline": Color("6f6850"),
					"floor_fill": Color("7a7058"),
					"floor_outline": Color("efe6c9"),
					"floor_grain": Color("a09070"),
					"liquid_fill": Color("39342d"),
					"liquid_glow": Color(0.38, 0.33, 0.26, 0.22),
					"liquid_outline": Color("938673"),
					"growth_fill": Color(0.35, 0.31, 0.24, 0.72),
					"growth_edge": Color("b0a088"),
				}
	if crystal_chamber:
		palette["base_fill"] = Color("2c2416")
		palette["base_outline"] = Color(0.60, 0.47, 0.22, 0.40)
		palette["obstacle_fill"] = Color("3a2e1a")
		palette["obstacle_outline"] = Color("6d5329")
		palette["floor_fill"] = Color("756041")
		palette["floor_outline"] = Color("ffd98c")
		palette["floor_grain"] = Color("a7864f")
		palette["liquid_fill"] = Color("2a241d")
		palette["liquid_glow"] = Color(0.33, 0.28, 0.20, 0.12)
		palette["liquid_outline"] = Color("7f6740")
		palette["growth_fill"] = Color(0.31, 0.26, 0.18, 0.50)
		palette["growth_edge"] = Color("a7864f")
	return palette

func draw_rooms() -> void:
	var view_rect: Rect2 = current_view_world_rect(160.0)
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		var room: Dictionary = rooms[room_coord]
		var rect: Rect2 = room_rect(room_coord)
		if not view_rect.intersects(rect):
			continue
		var warning_ratio: float = float(room.get("warning_timer_left", 0.0)) / maxf(WAVE_WARNING_DURATION, 0.001)
		var room_has_hero: bool = false
		var room_has_selected_hero: bool = false
		for hero in heroes:
			if not is_instance_valid(hero):
				continue
			if room_coord == hero.current_room or room_coord == hero.pending_room:
				room_has_hero = true
				if hero == selected_hero():
					room_has_selected_hero = true
		if room_coord == selected_room:
			draw_rect(rect.grow(-10.0), Color("f7f7f2", 0.92), false, 3.0)
		if room_has_hero:
			var marker_color: Color = Color("5f8796")
			if room_has_selected_hero:
				marker_color = Color("7ad7ff")
			var marker_center: Vector2 = rect.position + Vector2(rect.size.x - 24.0, 24.0)
			draw_circle(marker_center, 10.0, Color(marker_color.r, marker_color.g, marker_color.b, 0.18))
			draw_arc(marker_center, 10.0, 0.0, TAU, 24, marker_color, 2.2, true)
			draw_circle(marker_center, 4.0, marker_color)
		if room["lit"] and room_coord != crystal_room:
			draw_circle(rect.position + Vector2(28.0, 28.0), 11.0, Color("fff49c"))
		if room["major_slots"] > 0 and room_coord != crystal_room:
			var major_position: Vector2 = major_slot_position(room_coord)
			var pending_major: Dictionary = pending_major_construction_for_room(room_coord)
			var show_major_slot: bool = should_show_room_slot_guides(room_coord) or should_highlight_major_slot(room_coord) or (room["major_module_type"] != "" and float(room["major_health"]) > 0.0) or not pending_major.is_empty()
			if show_major_slot:
				var major_outline: Color = Color("182024")
				if should_show_room_slot_guides(room_coord) and not should_highlight_major_slot(room_coord):
					major_outline = Color(0.78, 0.80, 0.74, 0.55)
				if should_highlight_major_slot(room_coord):
					major_outline = Color("ffe39b")
				draw_rect(Rect2(major_position - Vector2(17.0, 17.0), Vector2(34.0, 34.0)), major_outline, false, 2.0)
			if room["major_module_type"] != "" and float(room["major_health"]) > 0.0:
				var major_color: Color = Color("f1c26b")
				match String(room["major_module_type"]):
					MAJOR_MODULE_FOOD:
						major_color = Color("8ee28a")
					MAJOR_MODULE_SCIENCE:
						major_color = Color("8bc1ff")
					MAJOR_MODULE_INDUSTRY:
						major_color = Color("f1c26b")
				draw_rect(Rect2(major_position - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), major_color, true)
				var major_ratio: float = float(room["major_health"]) / MAJOR_MODULE_MAX_HEALTH
				draw_rect(Rect2(major_position + Vector2(-20.0, 22.0), Vector2(40.0, 5.0)), Color("1b1610"), true)
				draw_rect(Rect2(major_position + Vector2(-20.0, 22.0), Vector2(40.0 * major_ratio, 5.0)), major_color.lightened(0.15), true)
				if bool(room.get("major_under_construction", false)):
					draw_string(ThemeDB.fallback_font, major_position + Vector2(-18.0, -20.0), "BUILD", HORIZONTAL_ALIGNMENT_LEFT, 40.0, 12, Color("fff1b7"))
			if not pending_major.is_empty():
				var pending_ratio: float = 1.0 - (float(pending_major.get("timer_left", 0.0)) / maxf(float(pending_major.get("duration", 1.0)), 0.001))
				draw_rect(Rect2(major_position - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), Color(1.0, 0.91, 0.69, 0.22), true)
				draw_arc(major_position, 19.0, -PI * 0.5, -PI * 0.5 + TAU * pending_ratio, 24, Color("ffe39b"), 3.0, true)
				draw_rect(Rect2(major_position + Vector2(-20.0, 30.0), Vector2(40.0, 5.0)), Color("1b1610"), true)
				draw_rect(Rect2(major_position + Vector2(-20.0, 30.0), Vector2(40.0 * pending_ratio, 5.0)), Color("ffe39b"), true)
		var slot_positions: Array = minor_slot_positions(room_coord)
		for slot_index in range(slot_positions.size()):
			var slot_position: Vector2 = slot_positions[slot_index]
			var module_index: int = minor_module_index_for_slot(room_coord, slot_index)
			var pending_minor: Dictionary = pending_minor_construction_for_slot(room_coord, slot_index)
			var show_minor_slot: bool = should_show_room_slot_guides(room_coord) or should_highlight_minor_slot(room_coord, slot_index) or module_index >= 0 or not pending_minor.is_empty()
			if show_minor_slot:
				var slot_fill: Color = Color("152127")
				var slot_outline: Color = Color("4f6c7b")
				if should_show_room_slot_guides(room_coord) and not should_highlight_minor_slot(room_coord, slot_index):
					slot_fill = Color(0.11, 0.15, 0.17, 0.28)
					slot_outline = Color(0.74, 0.77, 0.72, 0.46)
				if should_highlight_minor_slot(room_coord, slot_index):
					slot_fill = Color("23323a")
					slot_outline = Color("8df6ff")
				draw_circle(slot_position, 10.0, slot_fill)
				draw_arc(slot_position, 11.0, 0.0, TAU, 24, slot_outline, 2.0, true)
			if module_index >= 0:
				var module_data: Dictionary = room["minor_modules"][module_index]
				if float(module_data["health"]) > 0.0:
					var module_type: String = String(module_data.get("type", MINOR_MODULE_TURRET))
					var module_color: Color = minor_module_color(module_type)
					match module_type:
						MINOR_MODULE_PULSE:
							draw_circle(slot_position, 7.0, module_color)
							draw_arc(slot_position, 10.0, 0.0, TAU, 20, module_color.lightened(0.2), 2.0, true)
						MINOR_MODULE_CANNON:
							draw_rect(Rect2(slot_position - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), module_color, true)
							draw_line(slot_position + Vector2(0.0, -8.0), slot_position + Vector2(0.0, -18.0), module_color.lightened(0.25), 3.0)
						_:
							draw_circle(slot_position, 7.5, module_color)
							draw_line(slot_position + Vector2(0.0, -10.0), slot_position + Vector2(0.0, -18.0), module_color.lightened(0.25), 2.0)
					if bool(module_data.get("under_construction", false)) or float(module_data["health"]) < MINOR_MODULE_MAX_HEALTH:
						var turret_ratio: float = float(module_data["health"]) / MINOR_MODULE_MAX_HEALTH
						draw_rect(Rect2(slot_position + Vector2(-12.0, 14.0), Vector2(24.0, 4.0)), Color("142026"), true)
						draw_rect(Rect2(slot_position + Vector2(-12.0, 14.0), Vector2(24.0 * turret_ratio, 4.0)), module_color, true)
					if bool(module_data.get("under_construction", false)):
						draw_string(ThemeDB.fallback_font, slot_position + Vector2(-12.0, -15.0), "B", HORIZONTAL_ALIGNMENT_LEFT, 18.0, 12, Color("fff1b7"))
			if not pending_minor.is_empty():
				var pending_ratio_minor: float = 1.0 - (float(pending_minor.get("timer_left", 0.0)) / maxf(float(pending_minor.get("duration", 1.0)), 0.001))
				draw_circle(slot_position, 8.0, Color("b3efff", 0.18))
				draw_arc(slot_position, 14.0, -PI * 0.5, -PI * 0.5 + TAU * pending_ratio_minor, 24, Color("8df6ff"), 2.5, true)
		for ground_item_variant in room["ground_items"]:
			var ground_item: Dictionary = ground_item_variant
			var item_rect: Rect2 = ground_item_draw_rect(ground_item)
			var item_def: Dictionary = item_defs.get(String(ground_item.get("item_id", "")), {})
			var item_color: Color = item_def.get("color", Color("9ed4ff"))
			draw_rect(item_rect, item_color, true)
			draw_rect(item_rect, Color("f1fbff"), false, 2.0)
			draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(4.0, item_rect.size.y * 0.65), String(item_def.get("short", "ITM")), HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 4.0, 12, Color("0d171d"))
			draw_arc(item_rect.get_center(), maxf(item_rect.size.x, item_rect.size.y) * 0.55, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.18), 1.5, true)
		if room_coord == opening_origin_room:
			var progress_ratio: float = 1.0 - (opening_timer_left / DOOR_OPEN_DURATION)
			draw_rect(rect, Color(1.0, 1.0, 1.0, 0.08), true)
			draw_rect(Rect2(rect.position + Vector2(18.0, rect.size.y - 20.0), Vector2(rect.size.x - 36.0, 8.0)), Color("1d2630"), true)
			draw_rect(Rect2(rect.position + Vector2(18.0, rect.size.y - 20.0), Vector2((rect.size.x - 36.0) * progress_ratio, 8.0)), Color("f3dfa2"), true)
		if warning_ratio > 0.0:
			var inset: float = 12.0 + 8.0 * (1.0 - warning_ratio)
			draw_rect(rect.grow(-inset), Color(1.0, 0.66, 0.52, 0.10 + 0.12 * warning_ratio), false, 4.0)
		if room["exit"]:
			var exit_center: Vector2 = rect.get_center() + Vector2(0.0, -12.0)
			draw_circle(exit_center, 18.0, Color("203846"))
			draw_arc(exit_center, 18.0, 0.0, TAU, 28, Color("a5f7ff"), 3.0, true)
			draw_line(exit_center + Vector2(-6.0, 0.0), exit_center + Vector2(10.0, 0.0), Color("a5f7ff"), 3.0, true)
			draw_line(exit_center + Vector2(4.0, -6.0), exit_center + Vector2(10.0, 0.0), Color("a5f7ff"), 3.0, true)
			draw_line(exit_center + Vector2(4.0, 6.0), exit_center + Vector2(10.0, 0.0), Color("a5f7ff"), 3.0, true)
		if crystal_holder == null and crystal_ground_room == room_coord:
			var center: Vector2 = rect.get_center()
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -32.0),
				center + Vector2(24.0, 0.0),
				center + Vector2(0.0, 32.0),
				center + Vector2(-24.0, 0.0),
			]), Color("ffe7a1"))

func draw_room_action_hold() -> void:
	if room_action_hold.is_empty():
		return
	var hold_room: Vector2i = room_action_hold.get("room", INVALID_ROOM)
	if hold_room == INVALID_ROOM or not rooms.has(hold_room):
		return
	var hold_elapsed: float = float(room_action_hold.get("elapsed", 0.0))
	if hold_elapsed < ROOM_ACTION_HOLD_START_DELAY:
		return
	var hold_ratio: float = clampf((hold_elapsed - ROOM_ACTION_HOLD_START_DELAY) / maxf(ROOM_ACTION_HOLD_LOADER_DURATION, 0.001), 0.0, 1.0)
	var center: Vector2 = room_center(hold_room)
	var radius: float = (44.0 + 20.0 * hold_ratio) * camera.zoom.x
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * hold_ratio, 34, Color("ffe39b"), 6.2 * camera.zoom.x, true)
	draw_circle(center, 14.0 * camera.zoom.x, Color(1.0, 0.93, 0.68, 0.12 + 0.16 * hold_ratio))

func draw_room_action_menu() -> void:
	if room_action_menu.is_empty():
		return
	var menu_center_screen: Vector2 = room_action_menu_screen_center()
	var menu_center_world: Vector2 = screen_to_world(menu_center_screen)
	var pointer_screen: Vector2 = room_action_menu_virtual_pointer_screen_position()
	var pointer_world: Vector2 = screen_to_world(pointer_screen)
	var hovered_action_id: String = room_action_button_at_screen_position(pointer_screen) if room_action_menu_hold_selection_active else ""
	var overlay_scale: float = room_action_overlay_scale()
	var menu_radius_world: float = ROOM_ACTION_MENU_RADIUS * overlay_scale * camera.zoom.x
	var center_radius_world: float = ROOM_ACTION_DEADZONE_RADIUS * overlay_scale * camera.zoom.x
	var sector_inner_radius_world: float = maxf(center_radius_world + 12.0 * overlay_scale * camera.zoom.x, 28.0 * overlay_scale * camera.zoom.x)
	var sector_outer_radius_world: float = ROOM_ACTION_SECTOR_OUTER_RADIUS * overlay_scale * camera.zoom.x
	draw_circle(menu_center_world, center_radius_world, Color("132129"))
	draw_circle(menu_center_world, center_radius_world * 1.9, Color(0.07, 0.14, 0.17, 0.12))
	draw_arc(menu_center_world, menu_radius_world * 0.68, 0.0, TAU, 58, Color("476775"), 2.8 * camera.zoom.x, true)
	if room_action_menu_hold_selection_active:
		draw_line(menu_center_world, pointer_world, Color("8fe7ff"), 3.6 * camera.zoom.x, true)
		draw_circle(pointer_world, 12.0 * overlay_scale * camera.zoom.x, Color("eefbff"))
		draw_circle(pointer_world, 20.0 * overlay_scale * camera.zoom.x, Color(0.72, 0.94, 1.0, 0.12))
	for sector_data_variant in room_action_sector_layout():
		var sector_data: Dictionary = sector_data_variant
		var button_center_screen: Vector2 = room_action_button_screen_center(sector_data)
		var button_center_world: Vector2 = screen_to_world(button_center_screen)
		var action_id: String = String(sector_data.get("id", ""))
		var enabled: bool = room_action_enabled(room_action_menu.get("room", INVALID_ROOM), action_id)
		var fill: Color = sector_data.get("fill", Color("9ed4ff"))
		if not enabled:
			fill = fill.darkened(0.5)
		var highlighted: bool = hovered_action_id == action_id and enabled
		var outline_color: Color = fill.lightened(0.18) if highlighted else fill
		var outline_width: float = (4.8 if highlighted else 3.2) * camera.zoom.x
		if not enabled:
			outline_color = Color("5e6d75")
		var start_angle: float = float(sector_data.get("start_angle", 0.0))
		var end_angle: float = float(sector_data.get("end_angle", 0.0))
		var sector_points: PackedVector2Array = room_action_sector_points(menu_center_world, sector_inner_radius_world, sector_outer_radius_world, start_angle, end_angle)
		draw_colored_polygon(sector_points, Color(fill, 0.24 if enabled else 0.12))
		if highlighted:
			var highlighted_points: PackedVector2Array = room_action_sector_points(menu_center_world, sector_inner_radius_world + 10.0 * overlay_scale * camera.zoom.x, sector_outer_radius_world - 10.0 * overlay_scale * camera.zoom.x, start_angle, end_angle)
			draw_colored_polygon(highlighted_points, Color(fill.lightened(0.18), 0.28))
		draw_arc(menu_center_world, sector_outer_radius_world, start_angle, end_angle, 18, outline_color, outline_width, true)
		draw_arc(menu_center_world, sector_inner_radius_world, start_angle, end_angle, 18, outline_color, outline_width * 0.85, true)
		draw_line(menu_center_world + Vector2(cos(start_angle), sin(start_angle)) * sector_inner_radius_world, menu_center_world + Vector2(cos(start_angle), sin(start_angle)) * sector_outer_radius_world, outline_color, outline_width * 0.8, true)
		draw_line(menu_center_world + Vector2(cos(end_angle), sin(end_angle)) * sector_inner_radius_world, menu_center_world + Vector2(cos(end_angle), sin(end_angle)) * sector_outer_radius_world, outline_color, outline_width * 0.8, true)
		draw_string(ThemeDB.fallback_font, button_center_world + Vector2(0.0, 8.0) * overlay_scale * camera.zoom.x, String(sector_data.get("label", "")), HORIZONTAL_ALIGNMENT_CENTER, 104.0 * overlay_scale * camera.zoom.x, int(round(26.0 * overlay_scale * camera.zoom.x)), Color("eef8ff"))

func room_title(room_coord: Vector2i) -> String:
	return "Room %d-%d" % [room_coord.x + 1, room_coord.y + 1]

func room_summary(room_coord: Vector2i) -> String:
	if room_coord == crystal_room:
		var crystal_state: String = "crystal present" if crystal_ground_room == crystal_room and crystal_holder == null else "crystal removed"
		return "Crystal Chamber, permanently lit, %s" % crystal_state
	if not rooms.has(room_coord) or not rooms[room_coord]["opened"]:
		return "Unknown Chamber"
	var room: Dictionary = rooms[room_coord]
	var state: String = "open"
	if room_coord == opening_room:
		state = "opening"
	var light_state: String = "lit" if room["lit"] else "dark"
	if room["exit"]:
		light_state += ", exit"
	var major_text: String = "major 0/%d" % int(room["major_slots"])
	if int(room["major_slots"]) > 0 and room["major_module_type"] != "":
		major_text = "%s %d%%" % [String(room["major_module_type"]).capitalize(), int((float(room["major_health"]) / MAJOR_MODULE_MAX_HEALTH) * 100.0)]
	var minor_text: String = "turrets %d/%d" % [room["minor_modules"].size(), int(room["minor_slots"])]
	if crystal_ground_room == room_coord and crystal_holder == null:
		minor_text += ", crystal here"
	if room["ground_items"].size() > 0:
		minor_text += ", loot %d" % room["ground_items"].size()
	return "%s, %s, %s, %s, %s" % [room_title(room_coord), String(room.get("template_name", "Room")), state, light_state, "%s, %s" % [minor_text, major_text]]

func can_toggle_light(room_coord: Vector2i) -> bool:
	return rooms.has(room_coord) and rooms[room_coord]["opened"] and room_coord != crystal_room and not game_over

func can_manage_modules(room_coord: Vector2i) -> bool:
	return rooms.has(room_coord) and rooms[room_coord]["opened"] and rooms[room_coord]["lit"] and room_coord != crystal_room and not game_over

func can_open_build_for_room(room_coord: Vector2i) -> bool:
	return rooms.has(room_coord) and rooms[room_coord]["opened"] and room_coord != crystal_room and not game_over

func toggle_room_light(room_coord: Vector2i) -> void:
	if not can_toggle_light(room_coord):
		return
	var room: Dictionary = rooms[room_coord]
	if room["lit"]:
		var was_permanent: bool = bool(room.get("permanent_light", false))
		room["permanent_light"] = false
		room["temporary_light_turns"] = 0
		room["wave_torch_until_wave"] = -1
		if was_permanent:
			dust += 1
			status_message = "Darkened %s. Dust returned to the pool." % room_title(room_coord)
		else:
			status_message = "Darkened %s." % room_title(room_coord)
	else:
		if dust <= 0:
			status_message = "No dust available to light that room."
			update_hud()
			queue_redraw()
			return
		dust -= 1
		room["permanent_light"] = true
		room["temporary_light_turns"] = 0
		room["wave_torch_until_wave"] = -1
		status_message = "Lit %s. It can no longer spawn a wave." % room_title(room_coord)
	refresh_room_lighting_states()
	update_hud()
	queue_redraw()

func ensure_room_lit_for_build(room_coord: Vector2i) -> bool:
	if not can_open_build_for_room(room_coord):
		status_message = "That room cannot build modules right now."
		return false
	var room: Dictionary = rooms[room_coord]
	if room["lit"]:
		return true
	if dust <= 0:
		status_message = "%s is dark. Build needs 1 dust to light it first." % room_title(room_coord)
		return false
	dust -= 1
	room["permanent_light"] = true
	room["temporary_light_turns"] = 0
	room["wave_torch_until_wave"] = -1
	status_message = "Lit %s for building." % room_title(room_coord)
	refresh_room_lighting_states()
	return true

func heal_all_heroes() -> void:
	for hero in heroes:
		if is_instance_valid(hero):
			hero.restore_health()

func advance_wave_recovery(delta: float) -> void:
	if door_wave_auto_heal_pending and pending_enemy_spawns.is_empty() and enemies.is_empty():
		door_wave_auto_heal_pending = false
		door_wave_healing_active = true
		for hero in heroes:
			if is_instance_valid(hero):
				hero.refill_stamina()
				hero.combo_points = 0
				hero.clear_stamina_regen_buff()
		status_message = "The wave is over. Heroes are recovering."
		refresh_room_lighting_states()
		update_hud()
	if not door_wave_healing_active:
		return
	var everyone_full: bool = true
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		if hero.current_health < hero.max_health - 0.05:
			hero.heal(POST_WAVE_HEAL_RATE * delta)
		if hero.current_health < hero.max_health - 0.05:
			everyone_full = false
	if everyone_full:
		door_wave_healing_active = false
		status_message = "The wave is over. The heroes recovered."
	update_hud()

func update_hud() -> void:
	update_selected_hero_flags()
	var inventory_open: bool = inventory_overlay != null and inventory_overlay.visible
	if inventory_open:
		refresh_open_inventory_overlay()
	var door_income: Dictionary = calculate_door_rewards()
	var calm_phase: bool = not wave_in_progress()
	var inventory_allowed: bool = inventory_actions_allowed_for_local_peer()
	dust_label.text = "Dust %d" % dust
	food_label.text = "Food %d +%d" % [food, int(door_income["food"])]
	industry_label.text = "Ind %d +%d" % [industry, int(door_income["industry"])]
	science_label.text = "Sci %d +%d" % [science, int(door_income["science"])]
	if crystal_holder != null and is_instance_valid(crystal_holder):
		crystal_label.text = "Crystal %d%%  %s Carrying" % [int(clampf(crystal_health, 0.0, 100.0)), crystal_holder.hero_name]
	else:
		crystal_label.text = "Crystal %d%%" % int(clampf(crystal_health, 0.0, 100.0))
	wave_label.text = "Floor %d  Doors %d  Waves %d  Dark %d" % [floor_index, doors_opened, wave_index, count_dark_open_rooms()]
	room_label.text = room_summary(selected_room)
	inventory_button.disabled = inventory_open or selected_hero() == null or not inventory_allowed
	inventory_button.text = "Inventory"
	stamina_toggle_button.disabled = false
	stamina_toggle_button.button_pressed = stamina_use_enabled
	stamina_toggle_button.text = "Use Stamina"
	restart_button.disabled = false
	restart_button.text = "Restart"
	update_restart_button_hold_fill()
	build_menu.visible = build_menu_open and not inventory_open
	build_menu_title.text = build_menu_title_text()
	turret_button.disabled = not any_room_can_build_or_repair_turret()
	turret_button.text = turret_button_text(selected_room)
	food_major_button.disabled = not any_room_can_build_or_repair_major(MAJOR_MODULE_FOOD)
	science_major_button.disabled = not any_room_can_build_or_repair_major(MAJOR_MODULE_SCIENCE)
	industry_major_button.disabled = not any_room_can_build_or_repair_major(MAJOR_MODULE_INDUSTRY)
	food_major_button.text = major_button_text(selected_room, MAJOR_MODULE_FOOD, "Food")
	science_major_button.text = major_button_text(selected_room, MAJOR_MODULE_SCIENCE, "Science")
	industry_major_button.text = major_button_text(selected_room, MAJOR_MODULE_INDUSTRY, "Industry")
	update_calm_speed_bar(calm_phase)
	update_hero_button_text()
	update_runtime_button_state()
	hint_label.text = status_message
	update_network_ui()
	update_hero_select_overlay()

func refresh_open_inventory_overlay() -> void:
	if inventory_overlay == null or not inventory_overlay.visible or inventory_session.is_empty():
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	inventory_overlay.refresh_state(build_inventory_stat_lines(hero, hero.inventory_items), build_inventory_ability_sections(hero), build_level_up_reward_lines(hero), food, level_up_food_cost(hero.level), hero_can_level_up(hero), hero.level, hero.pack_modules, hero_spellbook_overlay_data(hero))

func selected_calm_speed_multiplier() -> float:
	return float(CALM_SPEED_OPTIONS[clampi(calm_speed_option_index, 0, CALM_SPEED_OPTIONS.size() - 1)])

func apply_calm_speed_multiplier_to_heroes() -> void:
	var multiplier: float = selected_calm_speed_multiplier()
	for hero in heroes:
		if is_instance_valid(hero):
			hero.set_calm_movement_multiplier(multiplier)

func update_calm_speed_bar(calm_phase: bool) -> void:
	if calm_speed_bar == null:
		return
	var host_can_control_speed: bool = not multiplayer_session_active() or multiplayer.is_server()
	calm_speed_bar.visible = calm_phase and host_can_control_speed
	for option_index in range(mini(calm_speed_buttons.size(), CALM_SPEED_OPTIONS.size())):
		var speed_button: Button = calm_speed_buttons[option_index]
		if not is_instance_valid(speed_button):
			continue
		speed_button.button_pressed = option_index == calm_speed_option_index
		speed_button.disabled = not host_can_control_speed

func _on_calm_speed_button_pressed(option_index: int) -> void:
	if multiplayer_session_active() and not multiplayer.is_server():
		return
	calm_speed_option_index = clampi(option_index, 0, CALM_SPEED_OPTIONS.size() - 1)
	apply_calm_speed_multiplier_to_heroes()
	update_hud()

func update_hero_button_text() -> void:
	for hero_index in range(mini(hero_buttons.size(), heroes.size())):
		var hero_button: Button = hero_buttons[hero_index]
		var hero: Variant = heroes[hero_index]
		if not is_instance_valid(hero_button):
			continue
		var title: String = "Dead"
		if hero_is_active(hero):
			title = hero.hero_name
		if hero_is_active(hero) and hero.carrying_crystal:
			title += " C"
		if multiplayer_session_active():
			title = "H%d %s" % [hero_index + 1, title]
		if hero_index == selected_hero_index and hero_is_active(hero):
			title = "[%s]" % title
		hero_button.text = title
		hero_button.disabled = not can_local_control_hero_index(hero_index) or not hero_is_active(hero)

func update_runtime_button_state() -> void:
	var inventory_open: bool = inventory_overlay != null and inventory_overlay.visible
	if crystal_action_button != null:
		crystal_action_button.visible = not inventory_open and crystal_prompt_visible and crystal_holder == null and crystal_ground_room != INVALID_ROOM and rooms.has(crystal_ground_room) and rooms[crystal_ground_room]["opened"] and can_local_control_hero_index(selected_hero_index)
		crystal_action_button.disabled = not can_selected_hero_pick_up_crystal()
		crystal_action_button.text = "Carry" if crystal_action_button.disabled == false else "Hero Needed"
		if crystal_action_button.visible:
			var crystal_screen: Vector2 = world_to_screen(crystal_world_position())
			crystal_action_button.position = crystal_screen + Vector2(36.0, -36.0)
	if exit_button != null:
		exit_button.visible = not inventory_open and carrier_in_exit_room() and crystal_holder != null and is_instance_valid(crystal_holder) and can_local_control_hero_index(crystal_holder.hero_index)
		exit_button.disabled = not all_heroes_in_exit_room()
		exit_button.text = "Escape Floor" if exit_button.disabled == false else "Gather Heroes"

func count_dark_open_rooms() -> int:
	var count: int = 0
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if room_coord != crystal_room and room["opened"] and not room["lit"]:
			count += 1
	return count

func can_build_or_repair_turret(room_coord: Vector2i) -> bool:
	if not rooms.has(room_coord):
		return false
	var room: Dictionary = rooms[room_coord]
	if not room["opened"] or room_coord == crystal_room:
		return false
	for slot_index in range(int(room["minor_slots"])):
		if minor_module_index_for_slot(room_coord, slot_index) < 0 and pending_minor_construction_for_slot(room_coord, slot_index).is_empty():
			return true
	return false

func any_room_can_build_or_repair_turret() -> bool:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if can_build_or_repair_turret(room_coord):
			return true
	return false

func turret_button_text(room_coord: Vector2i) -> String:
	if not rooms.has(room_coord):
		return "Turret"
	var room: Dictionary = rooms[room_coord]
	if not room["lit"]:
		return "Turret Auto-Lights"
	if room["minor_modules"].size() < int(room["minor_slots"]):
		return "Place Turret (3)"
	return "Turrets Full"

func can_build_or_repair_major(room_coord: Vector2i, module_type: String) -> bool:
	if not rooms.has(room_coord):
		return false
	var room: Dictionary = rooms[room_coord]
	if int(room["major_slots"]) <= 0:
		return false
	if not pending_major_construction_for_room(room_coord).is_empty():
		return false
	if room["major_module_type"] == "":
		return true
	return String(room["major_module_type"]) == module_type and not bool(room.get("major_under_construction", false)) and float(room["major_health"]) < MAJOR_MODULE_MAX_HEALTH

func any_room_can_build_or_repair_major(module_type: String) -> bool:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if can_open_build_for_room(room_coord) and can_build_or_repair_major(room_coord, module_type):
			return true
	return false

func major_button_text(room_coord: Vector2i, module_type: String, label: String) -> String:
	if not rooms.has(room_coord):
		return "Build %s" % label
	var room: Dictionary = rooms[room_coord]
	if int(room["major_slots"]) <= 0:
		return "No %s Slot" % label
	if room["major_module_type"] == "":
		return "Build %s" % label
	if String(room["major_module_type"]) == module_type and float(room["major_health"]) < MAJOR_MODULE_MAX_HEALTH:
		return "Repair %s" % label
	if String(room["major_module_type"]) == module_type:
		return "%s Online" % label
	return "%s Locked" % label

func build_type_label(module_type: String) -> String:
	match module_type:
		MINOR_MODULE_TURRET:
			return "Laser Turret"
		MINOR_MODULE_PULSE:
			return "Pulse Turret"
		MINOR_MODULE_CANNON:
			return "Cannon Turret"
		MAJOR_MODULE_FOOD:
			return "Food Module"
		MAJOR_MODULE_SCIENCE:
			return "Science Module"
		MAJOR_MODULE_INDUSTRY:
			return "Industry Module"
		_:
			return "Build"

func is_minor_module_type(module_type: String) -> bool:
	return module_type == MINOR_MODULE_TURRET or module_type == MINOR_MODULE_PULSE or module_type == MINOR_MODULE_CANNON

func is_major_module_type(module_type: String) -> bool:
	return module_type == MAJOR_MODULE_FOOD or module_type == MAJOR_MODULE_SCIENCE or module_type == MAJOR_MODULE_INDUSTRY

func minor_module_cost(module_type: String) -> int:
	match module_type:
		MINOR_MODULE_PULSE:
			return 4
		MINOR_MODULE_CANNON:
			return 6
		_:
			return 3

func minor_module_damage(module_type: String) -> float:
	match module_type:
		MINOR_MODULE_PULSE:
			return 7.0
		MINOR_MODULE_CANNON:
			return 24.0
		_:
			return 11.0

func minor_module_cooldown(module_type: String) -> float:
	match module_type:
		MINOR_MODULE_PULSE:
			return 0.26
		MINOR_MODULE_CANNON:
			return 1.05
		_:
			return 0.55

func minor_module_color(module_type: String) -> Color:
	match module_type:
		MINOR_MODULE_PULSE:
			return Color("ff8ce1")
		MINOR_MODULE_CANNON:
			return Color("ffbf73")
		_:
			return Color("89f2ff")

func minor_module_projectile_width(module_type: String) -> float:
	match module_type:
		MINOR_MODULE_PULSE:
			return 3.6
		MINOR_MODULE_CANNON:
			return 6.2
		_:
			return 4.0

func minor_module_projectile_speed(module_type: String) -> float:
	match module_type:
		MINOR_MODULE_CANNON:
			return 820.0
		MINOR_MODULE_PULSE:
			return 1080.0
		_:
			return PROJECTILE_SPEED

func wave_in_progress() -> bool:
	return not pending_enemy_spawns.is_empty() or not enemies.is_empty()

func update_hero_combat_movement_mode() -> void:
	var in_combat: bool = wave_in_progress()
	for hero in heroes:
		if is_instance_valid(hero):
			hero.set_combat_movement_mode(in_combat)

func room_has_pending_construction(room_coord: Vector2i) -> bool:
	for construction_variant in pending_room_constructions:
		var construction: Dictionary = construction_variant
		if construction.get("room", INVALID_ROOM) == room_coord:
			return true
	return false

func preferred_turret_slot(room_coord: Vector2i) -> int:
	if not rooms.has(room_coord):
		return -1
	var room: Dictionary = rooms[room_coord]
	for slot_index in range(int(room["minor_slots"])):
		if minor_module_index_for_slot(room_coord, slot_index) < 0 and pending_minor_construction_for_slot(room_coord, slot_index).is_empty():
			return slot_index
	return -1

func queue_room_construction(room_coord: Vector2i, module_type: String) -> bool:
	if not can_open_build_for_room(room_coord):
		status_message = "%s cannot build modules." % room_title(room_coord)
		update_hud()
		queue_redraw()
		return false
	if not ensure_room_lit_for_build(room_coord):
		update_hud()
		queue_redraw()
		return false
	var room: Dictionary = rooms[room_coord]
	var is_major: bool = is_major_module_type(module_type)
	var industry_cost: int = 0
	var repairing: bool = false
	var slot_index: int = -1
	if is_major:
		if int(room["major_slots"]) <= 0:
			status_message = "%s has no major module slot." % room_title(room_coord)
			update_hud()
			queue_redraw()
			return false
		if not pending_major_construction_for_room(room_coord).is_empty():
			status_message = "Major construction is already underway in %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
			return false
		if room["major_module_type"] == "":
			industry_cost = MAJOR_MODULE_COST
		elif String(room["major_module_type"]) == module_type and float(room["major_health"]) < MAJOR_MODULE_MAX_HEALTH:
			industry_cost = 3
			repairing = true
		else:
			status_message = "That major slot is already occupied."
			update_hud()
			queue_redraw()
			return false
	else:
		slot_index = preferred_turret_slot(room_coord)
		if slot_index < 0:
			status_message = "No minor slot is available in %s." % room_title(room_coord)
			update_hud()
			queue_redraw()
			return false
		industry_cost = minor_module_cost(module_type)
	if industry < industry_cost:
		status_message = "Not enough industry for %s." % build_type_label(module_type).to_lower()
		update_hud()
		queue_redraw()
		return false
	industry -= industry_cost
	var duration: float = BUILD_DURATION_WAVE if wave_in_progress() else BUILD_DURATION_CALM
	var start_health: float = 1.0
	var target_health: float = MAJOR_MODULE_MAX_HEALTH if is_major else MINOR_MODULE_MAX_HEALTH
	if is_major:
		if repairing:
			start_health = float(room["major_health"])
		else:
			room["major_module_type"] = module_type
			room["major_health"] = start_health
		room["major_under_construction"] = true
	else:
		room["minor_modules"].append({
			"type": module_type,
			"slot_index": slot_index,
			"health": start_health,
			"cooldown": 0.2,
			"under_construction": true,
		})
	pending_room_constructions.append({
		"room": room_coord,
		"module_type": module_type,
		"is_major": is_major,
		"slot_index": slot_index,
		"repairing": repairing,
		"start_health": start_health,
		"target_health": target_health,
		"duration": duration,
		"timer_left": duration,
	})
	status_message = "%s started in %s." % [("Repair" if repairing else "Build"), room_title(room_coord)]
	update_hud()
	queue_redraw()
	return true

func advance_room_constructions(delta: float) -> void:
	var active_constructions: Array = []
	var completed_any: bool = false
	for construction_variant in pending_room_constructions:
		var construction: Dictionary = construction_variant
		construction["timer_left"] = maxf(float(construction.get("timer_left", 0.0)) - delta, 0.0)
		apply_construction_progress(construction)
		if float(construction["timer_left"]) <= 0.0:
			finish_room_construction(construction)
			completed_any = true
		else:
			active_constructions.append(construction)
	pending_room_constructions = active_constructions
	if completed_any:
		update_hud()
		queue_redraw()

func apply_construction_progress(construction: Dictionary) -> void:
	var room_coord: Vector2i = construction.get("room", INVALID_ROOM)
	if not rooms.has(room_coord):
		return
	var room: Dictionary = rooms[room_coord]
	var duration: float = maxf(float(construction.get("duration", 1.0)), 0.001)
	var timer_left: float = float(construction.get("timer_left", 0.0))
	var progress: float = 1.0 - (timer_left / duration)
	var start_health: float = float(construction.get("start_health", 1.0))
	var target_health: float = float(construction.get("target_health", 1.0))
	var next_health: float = lerpf(start_health, target_health, progress)
	if bool(construction.get("is_major", false)):
		room["major_health"] = next_health
		return
	var slot_index: int = int(construction.get("slot_index", -1))
	var module_index: int = minor_module_index_for_slot(room_coord, slot_index)
	if module_index >= 0:
		room["minor_modules"][module_index]["health"] = next_health

func finish_room_construction(construction: Dictionary) -> void:
	var room_coord: Vector2i = construction.get("room", INVALID_ROOM)
	if not rooms.has(room_coord):
		return
	var room: Dictionary = rooms[room_coord]
	var module_type: String = String(construction.get("module_type", ""))
	if bool(construction.get("is_major", false)):
		room["major_health"] = MAJOR_MODULE_MAX_HEALTH
		room["major_under_construction"] = false
		status_message = "%s completed in %s." % [build_type_label(module_type), room_title(room_coord)]
		return
	var slot_index: int = int(construction.get("slot_index", -1))
	if slot_index < 0:
		return
	var module_index: int = minor_module_index_for_slot(room_coord, slot_index)
	if module_index >= 0:
		room["minor_modules"][module_index]["health"] = MINOR_MODULE_MAX_HEALTH
		room["minor_modules"][module_index]["under_construction"] = false
	status_message = "%s completed in %s." % [build_type_label(module_type), room_title(room_coord)]

func build_menu_title_text() -> String:
	if pending_build_type == "":
		return "Build Menu"
	return "%s: tap a room" % build_type_label(pending_build_type)

func clear_build_mode() -> void:
	pending_build_type = ""

func select_build_mode(module_type: String) -> void:
	build_menu_open = true
	pending_build_type = module_type
	status_message = "%s selected. Tap the room you want to build in." % build_type_label(module_type)
	update_hud()
	queue_redraw()

func handle_build_tap(world_position: Vector2) -> bool:
	var tapped_room: Vector2i = room_at_world_position(world_position)
	if tapped_room == INVALID_ROOM:
		status_message = "Tap a room to place %s." % build_type_label(pending_build_type).to_lower()
		return true
	selected_room = tapped_room
	request_room_construction(tapped_room, pending_build_type)
	return true

func screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position

func world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position

func screen_rect_to_world_rect(screen_rect: Rect2) -> Rect2:
	var top_left: Vector2 = screen_to_world(screen_rect.position)
	var bottom_right: Vector2 = screen_to_world(screen_rect.position + screen_rect.size)
	return Rect2(top_left, bottom_right - top_left)

func current_view_world_rect(padding: float = 0.0) -> Rect2:
	var world_rect: Rect2 = screen_rect_to_world_rect(Rect2(Vector2.ZERO, get_viewport_rect().size))
	return world_rect.abs().grow(padding)

func rect_visible_in_view(world_rect: Rect2, padding: float = 0.0) -> bool:
	return current_view_world_rect(padding).intersects(world_rect)

func point_visible_in_view(world_position: Vector2, padding: float = 0.0) -> bool:
	return current_view_world_rect(padding).has_point(world_position)

func active_hand_returning_uids() -> Dictionary:
	var returning: Dictionary = {}
	for animation_variant in hand_card_return_animations:
		var animation: Dictionary = animation_variant
		returning[int(animation.get("card_uid", -1))] = true
	return returning

func selected_hand_hero() -> Variant:
	if not lobby_game_started or game_over:
		return null
	if hero_select_overlay != null and hero_select_overlay.visible:
		return null
	if inventory_overlay != null and inventory_overlay.visible:
		return null
	var hero: Variant = selected_hero()
	if hero == null or not is_instance_valid(hero) or not can_local_control_hero_index(hero.hero_index):
		return null
	if hero.hand_cards.is_empty():
		return null
	return hero

func combat_hand_panel_rect(hero: Variant) -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var slot_count: int = maxi(maxi(hero.hand_cards.size(), hero.max_hand_size), 1)
	var visible_slots: int = mini(slot_count, 5)
	var panel_width: float = minf(viewport_size.x - CARD_HAND_SIDE_MARGIN * 2.0, CARD_HAND_CARD_SIZE.x * float(visible_slots) + CARD_HAND_GAP * float(maxi(visible_slots - 1, 0)) + 24.0)
	var panel_height: float = CARD_HAND_CARD_SIZE.y + 44.0
	return Rect2(Vector2((viewport_size.x - panel_width) * 0.5, viewport_size.y - panel_height - CARD_HAND_BOTTOM_MARGIN), Vector2(panel_width, panel_height))

func combat_hand_card_rect(hero: Variant, card_index: int) -> Rect2:
	var panel_rect: Rect2 = combat_hand_panel_rect(hero)
	var visible_count: int = maxi(hero.hand_cards.size(), 1)
	var total_width: float = CARD_HAND_CARD_SIZE.x * float(visible_count) + CARD_HAND_GAP * float(maxi(visible_count - 1, 0))
	var start_x: float = panel_rect.get_center().x - total_width * 0.5
	return Rect2(Vector2(start_x + float(card_index) * (CARD_HAND_CARD_SIZE.x + CARD_HAND_GAP), panel_rect.position.y + 8.0), CARD_HAND_CARD_SIZE)

func combat_hand_info_button_rect(hero: Variant) -> Rect2:
	var panel_rect: Rect2 = combat_hand_panel_rect(hero)
	return Rect2(Vector2(panel_rect.position.x + 10.0, panel_rect.position.y + panel_rect.size.y - 28.0), Vector2(56.0, 20.0))

func combat_hand_info_panel_rect(hero: Variant) -> Rect2:
	var panel_rect: Rect2 = combat_hand_panel_rect(hero)
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_width: float = minf(viewport_size.x - 24.0, 332.0)
	var panel_height: float = 138.0
	return Rect2(Vector2((viewport_size.x - panel_width) * 0.5, panel_rect.position.y - panel_height - 10.0), Vector2(panel_width, panel_height))

func combat_hand_reaction_rect(hero: Variant, card_index: int) -> Rect2:
	var card_rect: Rect2 = combat_hand_card_rect(hero, card_index)
	return Rect2(card_rect.position + Vector2(card_rect.size.x - 24.0, 6.0), Vector2(18.0, 18.0))

func combat_hand_reaction_touch_rect(hero: Variant, card_index: int) -> Rect2:
	return combat_hand_reaction_rect(hero, card_index).grow(8.0)

func combat_hand_insertion_index(hero: Variant, screen_position: Vector2) -> int:
	if hero == null or not is_instance_valid(hero) or hero.hand_cards.is_empty():
		return 0
	var insertion_index: int = 0
	for card_index in range(hero.hand_cards.size()):
		var card_rect: Rect2 = combat_hand_card_rect(hero, card_index)
		if screen_position.x < card_rect.get_center().x:
			return card_index
		insertion_index = card_index + 1
	return insertion_index

func combat_hand_card_index_at_screen_position(hero: Variant, screen_position: Vector2) -> int:
	for card_index in range(hero.hand_cards.size() - 1, -1, -1):
		if combat_hand_card_rect(hero, card_index).has_point(screen_position):
			return card_index
	return -1

func hand_card_footer_bits(hand_card: Dictionary) -> Array[String]:
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
		footer_bits.append("Exp %d" % maxi(0, expires_on - doors_opened))
	if card_supports_reaction(hand_card):
		footer_bits.append("React")
	return footer_bits

func open_hand_card_info(hero: Variant, hand_card: Dictionary) -> void:
	if hero == null or not is_instance_valid(hero):
		active_hand_info_card.clear()
		active_hand_info_hero_index = -1
		return
	active_hand_info_card = hand_card.duplicate(true)
	active_hand_info_hero_index = hero.hero_index
	queue_redraw()

func clear_hand_card_info() -> void:
	active_hand_info_card.clear()
	active_hand_info_hero_index = -1

func dismiss_hand_card_info_if_outside(screen_position: Vector2) -> bool:
	if active_hand_info_card.is_empty():
		return false
	var hero: Variant = selected_hand_hero()
	if hero == null or not is_instance_valid(hero) or active_hand_info_hero_index != hero.hero_index:
		clear_hand_card_info()
		return false
	if combat_hand_info_panel_rect(hero).has_point(screen_position):
		return false
	clear_hand_card_info()
	queue_redraw()
	return true

func draw_hand_card(screen_rect: Rect2, hand_card: Dictionary, highlighted: bool, reaction_rect_screen: Rect2 = Rect2()) -> void:
	var world_rect: Rect2 = screen_rect_to_world_rect(screen_rect)
	var fill: Color = hand_card.get("color", Color("cfe6ff"))
	if highlighted:
		fill = fill.lightened(0.12)
	draw_rect(world_rect, fill, true)
	draw_rect(world_rect, Color("eff8ff"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, world_rect.position + Vector2(5.0, 13.0), String(hand_card.get("name", "Card")), HORIZONTAL_ALIGNMENT_LEFT, world_rect.size.x - 10.0, 10, Color("091116"))
	var phase_label: String = "Calm"
	match String(hand_card.get("phase", "combat")):
		"combat":
			phase_label = "Fight"
		"any":
			phase_label = "Any"
	var tag_line: String = "%s  %s" % [phase_label, String(hand_card.get("target_scope_label", card_target_scope_label(String(hand_card.get("target_scope", "same_room")))))]
	if bool(hand_card.get("requires_line_of_effect", false)):
		tag_line += "  LoE"
	draw_string(font, world_rect.position + Vector2(5.0, 26.0), tag_line, HORIZONTAL_ALIGNMENT_LEFT, world_rect.size.x - 10.0, 8, Color("102028"))
	var info_lines: Array = Array(hand_card.get("description_lines", []))
	for line_index in range(mini(info_lines.size(), 2)):
		draw_string(font, world_rect.position + Vector2(5.0, 40.0 + float(line_index) * 10.0), String(info_lines[line_index]), HORIZONTAL_ALIGNMENT_LEFT, world_rect.size.x - 10.0, 8, Color("102028"))
	var footer_bits: Array[String] = hand_card_footer_bits(hand_card)
	if not footer_bits.is_empty():
		draw_string(font, world_rect.position + Vector2(5.0, world_rect.size.y - 7.0), "  ".join(footer_bits), HORIZONTAL_ALIGNMENT_LEFT, world_rect.size.x - 10.0, 8, Color("20323d"))
	if card_supports_reaction(hand_card) and reaction_rect_screen.size != Vector2.ZERO:
		var reaction_world_rect: Rect2 = screen_rect_to_world_rect(reaction_rect_screen)
		draw_rect(reaction_world_rect, Color(0.08, 0.14, 0.18, 0.92), true)
		draw_rect(reaction_world_rect, Color("d8eef8"), false, 1.5)
		if bool(hand_card.get("reaction_enabled", false)):
			draw_line(reaction_world_rect.position + Vector2(3.0, 10.0), reaction_world_rect.position + Vector2(7.0, 14.0), Color("9cffb4"), 2.0, true)
			draw_line(reaction_world_rect.position + Vector2(7.0, 14.0), reaction_world_rect.position + Vector2(15.0, 4.0), Color("9cffb4"), 2.0, true)
		draw_string(font, reaction_world_rect.position + Vector2(-12.0, 15.0), "R", HORIZONTAL_ALIGNMENT_LEFT, 10.0, 10, Color("eef8ff"))

func draw_hand_card_info_panel(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if active_hand_info_card.is_empty() or active_hand_info_hero_index != hero.hero_index:
		return
	var panel_screen: Rect2 = combat_hand_info_panel_rect(hero)
	var panel_world: Rect2 = screen_rect_to_world_rect(panel_screen)
	draw_rect(panel_world, Color(0.06, 0.1, 0.13, 0.96), true)
	draw_rect(panel_world, Color("83a6b4"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, panel_world.position + Vector2(12.0, 18.0), String(active_hand_info_card.get("name", "Card")), HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x - 24.0, 14, Color("eef8ff"))
	var tag_line: String = "%s  %s" % [
		"Fight" if String(active_hand_info_card.get("phase", "combat")) == "combat" else ("Any" if String(active_hand_info_card.get("phase", "combat")) == "any" else "Calm"),
		String(active_hand_info_card.get("target_scope_label", card_target_scope_label(String(active_hand_info_card.get("target_scope", "same_room"))))),
	]
	if bool(active_hand_info_card.get("requires_line_of_effect", false)):
		tag_line += "  LoE"
	if card_supports_reaction(active_hand_info_card):
		tag_line += "  Reaction"
	draw_string(font, panel_world.position + Vector2(12.0, 35.0), tag_line, HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x - 24.0, 11, Color("bed6e3"))
	var y: float = panel_world.position.y + 55.0
	for line_variant in Array(active_hand_info_card.get("description_lines", [])):
		draw_string(font, Vector2(panel_world.position.x + 12.0, y), String(line_variant), HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x - 24.0, 11, Color("dce9f2"))
		y += 15.0
	for footer_line in hand_card_footer_bits(active_hand_info_card):
		draw_string(font, Vector2(panel_world.position.x + 12.0, y), String(footer_line), HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x - 24.0, 10, Color("f2d8a4"))
		y += 13.0

func draw_combat_hand() -> void:
	var hero: Variant = selected_hand_hero()
	if hero == null:
		return
	var panel_screen: Rect2 = combat_hand_panel_rect(hero)
	var panel_world: Rect2 = screen_rect_to_world_rect(panel_screen)
	draw_rect(panel_world, Color(0.07, 0.12, 0.16, 0.86), true)
	draw_rect(panel_world, Color("5f8796"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, panel_world.position + Vector2(10.0, 16.0), "%s Cards" % hero.hero_name, HORIZONTAL_ALIGNMENT_LEFT, panel_world.size.x * 0.52, 13, Color("eef8ff"))
	var phase_status: String = "Combat" if wave_in_progress() else "Calm"
	draw_string(font, panel_world.position + Vector2(panel_world.size.x - 116.0, 16.0), phase_status, HORIZONTAL_ALIGNMENT_LEFT, 108.0, 12, Color("bde3ff"))
	draw_string(font, panel_world.position + Vector2(panel_world.size.x - 116.0, 30.0), "%d/%d" % [hero.hand_cards.size(), hero.max_hand_size], HORIZONTAL_ALIGNMENT_LEFT, 108.0, 11, Color("ffd8a0"))
	var info_button_world: Rect2 = screen_rect_to_world_rect(combat_hand_info_button_rect(hero))
	var info_button_fill: Color = Color(0.12, 0.18, 0.21, 0.96)
	if not active_hand_drag.is_empty() and combat_hand_info_button_rect(hero).grow(12.0).has_point(Vector2(active_hand_drag.get("current_screen", Vector2.ZERO))):
		info_button_fill = Color(0.2, 0.28, 0.18, 0.98)
	draw_rect(info_button_world, info_button_fill, true)
	draw_rect(info_button_world, Color("8db2c2"), false, 1.5)
	draw_string(font, info_button_world.position + Vector2(14.0, 14.0), "Info", HORIZONTAL_ALIGNMENT_LEFT, info_button_world.size.x - 16.0, 11, Color("eef8ff"))
	var hidden_uids: Dictionary = active_hand_returning_uids()
	if not active_hand_drag.is_empty():
		hidden_uids[int(active_hand_drag.get("card_uid", -1))] = true
	for card_index in range(hero.hand_cards.size()):
		var hand_card: Dictionary = hero.hand_cards[card_index]
		var card_uid: int = int(hand_card.get("uid", -1))
		if hidden_uids.has(card_uid):
			continue
		draw_hand_card(combat_hand_card_rect(hero, card_index), hand_card, false, combat_hand_reaction_rect(hero, card_index))
	for animation_variant in hand_card_return_animations:
		var animation: Dictionary = animation_variant
		var progress: float = clampf(float(animation.get("progress", 1.0)), 0.0, 1.0)
		var from_rect: Rect2 = animation.get("from_rect", Rect2())
		var to_rect: Rect2 = animation.get("to_rect", Rect2())
		var eased: float = ease(progress if from_rect.position.distance_to(to_rect.position) > 0.0 else 1.0, -1.8)
		var animation_rect: Rect2 = Rect2(from_rect.position.lerp(to_rect.position, eased), from_rect.size.lerp(to_rect.size, eased))
		draw_hand_card(animation_rect, animation.get("card", {}), true)
	if not active_hand_drag.is_empty():
		var drag_card: Dictionary = active_hand_drag.get("card", {})
		var drag_rect: Rect2 = Rect2(Vector2(active_hand_drag.get("current_screen", Vector2.ZERO)) - CARD_HAND_CARD_SIZE * 0.5, CARD_HAND_CARD_SIZE)
		draw_hand_card(drag_rect, drag_card, true)
	draw_hand_card_info_panel(hero)

func begin_hand_card_drag(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	var hero: Variant = selected_hand_hero()
	if hero == null or hero.hand_cards.is_empty():
		return false
	var card_index: int = combat_hand_card_index_at_screen_position(hero, screen_position)
	if card_index < 0:
		return false
	active_hand_drag = {
		"pointer_kind": pointer_kind,
		"pointer_id": pointer_id,
		"hero_index": hero.hero_index,
		"source_index": card_index,
		"card_uid": int((hero.hand_cards[card_index] as Dictionary).get("uid", -1)),
		"card": (hero.hand_cards[card_index] as Dictionary).duplicate(true),
		"start_screen": screen_position,
		"current_screen": screen_position,
		"tap_toggle_candidate": card_supports_reaction(hero.hand_cards[card_index]),
	}
	pause_autonomous_heroes_for_hand_drag()
	clear_room_action_hold()
	close_room_action_menu()
	return true

func update_hand_card_drag(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if active_hand_drag.is_empty():
		return false
	if String(active_hand_drag.get("pointer_kind", "")) != pointer_kind or int(active_hand_drag.get("pointer_id", -1)) != pointer_id:
		return false
	active_hand_drag["current_screen"] = screen_position
	return true

func start_hand_card_return_animation(hand_card: Dictionary, from_rect: Rect2, to_rect: Rect2) -> void:
	hand_card_return_animations.append({
		"card_uid": int(hand_card.get("uid", -1)),
		"card": hand_card.duplicate(true),
		"from_rect": from_rect,
		"to_rect": to_rect,
		"progress": 0.0,
	})

func advance_hand_card_return_animations(delta: float) -> void:
	if hand_card_return_animations.is_empty():
		return
	var active_animations: Array = []
	for animation_variant in hand_card_return_animations:
		var animation: Dictionary = animation_variant
		animation["progress"] = minf(float(animation.get("progress", 0.0)) + delta / CARD_HAND_RETURN_DURATION, 1.0)
		if float(animation["progress"]) < 1.0:
			active_animations.append(animation)
	hand_card_return_animations = active_animations

func finish_hand_card_drag(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	if active_hand_drag.is_empty():
		return false
	if String(active_hand_drag.get("pointer_kind", "")) != pointer_kind or int(active_hand_drag.get("pointer_id", -1)) != pointer_id:
		return false
	var hero_index: int = int(active_hand_drag.get("hero_index", -1))
	var source_index: int = int(active_hand_drag.get("source_index", -1))
	var drag_card: Dictionary = Dictionary(active_hand_drag.get("card", {}))
	var source_hero: Variant = heroes[hero_index] if hero_index >= 0 and hero_index < heroes.size() else null
	var source_rect: Rect2 = combat_hand_card_rect(source_hero, source_index) if source_hero != null and is_instance_valid(source_hero) else Rect2(screen_position - CARD_HAND_CARD_SIZE * 0.5, CARD_HAND_CARD_SIZE)
	var drag_rect: Rect2 = Rect2(screen_position - CARD_HAND_CARD_SIZE * 0.5, CARD_HAND_CARD_SIZE)
	var drag_distance: float = Vector2(active_hand_drag.get("start_screen", screen_position)).distance_to(screen_position)
	if source_hero != null and is_instance_valid(source_hero) and combat_hand_info_button_rect(source_hero).grow(12.0).has_point(screen_position):
		open_hand_card_info(source_hero, drag_card)
		start_hand_card_return_animation(drag_card, drag_rect, source_rect)
		active_hand_drag.clear()
		return true
	if bool(active_hand_drag.get("tap_toggle_candidate", false)) and drag_distance <= CARD_HAND_TAP_DISTANCE and source_rect.grow(18.0).has_point(screen_position):
		if toggle_hand_card_reaction(source_hero, source_index):
			if multiplayer_session_active() and not authoritative_simulation_active():
				server_commit_hand_state.rpc_id(NETWORK_HOST_PEER_ID, hero_index, serialized_hand_state(source_hero))
			elif multiplayer_session_active() and multiplayer.is_server():
				broadcast_network_snapshot()
			update_hud()
			queue_redraw()
		active_hand_drag.clear()
		return true
	if source_hero != null and is_instance_valid(source_hero) and combat_hand_panel_rect(source_hero).grow(18.0).has_point(screen_position):
		var insertion_index: int = combat_hand_insertion_index(source_hero, screen_position)
		if move_hand_card(source_hero, source_index, insertion_index):
			if multiplayer_session_active() and not authoritative_simulation_active():
				server_commit_hand_state.rpc_id(NETWORK_HOST_PEER_ID, hero_index, serialized_hand_state(source_hero))
			elif multiplayer_session_active() and multiplayer.is_server():
				broadcast_network_snapshot()
			update_hud()
			active_hand_drag.clear()
			return true
	var played: bool = false
	var target_world_position: Vector2 = screen_to_world(screen_position)
	if screen_position.distance_to(source_rect.get_center()) > CARD_HAND_RELEASE_DISTANCE and source_hero != null and is_instance_valid(source_hero) and card_target_is_valid(source_hero, drag_card, target_world_position):
		if multiplayer_session_active() and not authoritative_simulation_active():
			server_request_play_card.rpc_id(NETWORK_HOST_PEER_ID, hero_index, int(drag_card.get("uid", -1)), target_world_position)
			played = true
		else:
			played = play_card_for_hero(hero_index, int(drag_card.get("uid", -1)), target_world_position)
			if played and multiplayer_session_active() and multiplayer.is_server():
				broadcast_network_snapshot()
		if not played:
			start_hand_card_return_animation(drag_card, drag_rect, source_rect)
	else:
		start_hand_card_return_animation(drag_card, drag_rect, source_rect)
	active_hand_drag.clear()
	return true

func is_in_bounds(room_coord: Vector2i) -> bool:
	return room_coord.x >= 0 and room_coord.y >= 0 and room_coord.x < GRID_SIZE.x and room_coord.y < GRID_SIZE.y

func _on_turret_button_pressed() -> void:
	if not any_room_can_build_or_repair_turret():
		return
	select_build_mode(MINOR_MODULE_TURRET)
	update_hud()
	queue_redraw()

func _on_food_major_button_pressed() -> void:
	if any_room_can_build_or_repair_major(MAJOR_MODULE_FOOD):
		select_build_mode(MAJOR_MODULE_FOOD)

func _on_science_major_button_pressed() -> void:
	if any_room_can_build_or_repair_major(MAJOR_MODULE_SCIENCE):
		select_build_mode(MAJOR_MODULE_SCIENCE)

func _on_industry_major_button_pressed() -> void:
	if any_room_can_build_or_repair_major(MAJOR_MODULE_INDUSTRY):
		select_build_mode(MAJOR_MODULE_INDUSTRY)

func _on_inventory_button_pressed() -> void:
	if not inventory_actions_allowed_for_local_peer():
		return
	var hero: Variant = selected_hero()
	if hero == null:
		return
	clear_room_action_hold()
	close_room_action_menu()
	open_hero_inventory(hero)
	status_message = "Inventory open for %s." % hero.hero_name
	update_hud()

func _on_stamina_toggle_button_toggled(enabled: bool) -> void:
	if stamina_use_enabled == enabled:
		update_hud()
		return
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_set_stamina_use_enabled.rpc_id(NETWORK_HOST_PEER_ID, enabled)
		stamina_toggle_button.set_pressed_no_signal(stamina_use_enabled)
		status_message = "Requested stamina use %s." % ("enabled" if enabled else "disabled")
		update_hud()
		return
	stamina_use_enabled = enabled
	status_message = "Stamina use %s." % ("enabled" if stamina_use_enabled else "disabled")
	update_hud()
	if multiplayer_session_active() and multiplayer.is_server():
		broadcast_network_snapshot()

func _on_center_button_pressed() -> void:
	mark_camera_interaction()
	camera.global_position = hero_focus_position()
	clamp_camera()

func _on_hero_button_pressed(hero_index: int) -> void:
	if not can_local_control_hero_index(hero_index):
		return
	if inventory_actions_allowed_for_local_peer() and hero_index == selected_hero_index and (inventory_overlay == null or not inventory_overlay.visible):
		var hero: Variant = selected_hero()
		open_hero_inventory(hero)
		return
	select_hero_by_index(hero_index)

func _on_inventory_overlay_changed(items: Array) -> void:
	if inventory_session.is_empty():
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	var room_coord: Vector2i = inventory_session.get("room", INVALID_ROOM)
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if rooms.has(room_coord) and inventory_overlay != null:
		rooms[room_coord]["ground_items"] = prepare_ground_items_for_room(room_coord, inventory_overlay.get_ground_items())
	hero.inventory_items = items.duplicate(true)
	apply_inventory_stats_to_hero(hero)
	if multiplayer_session_active() and not authoritative_simulation_active() and inventory_overlay != null:
		server_commit_inventory_state.rpc_id(NETWORK_HOST_PEER_ID, hero_index, room_coord, items, inventory_overlay.get_ground_items())
	inventory_overlay.refresh_state(build_inventory_stat_lines(hero, hero.inventory_items), build_inventory_ability_sections(hero), build_level_up_reward_lines(hero), food, level_up_food_cost(hero.level), hero_can_level_up(hero), hero.level, hero.pack_modules, hero_spellbook_overlay_data(hero))
	update_hud()

func _on_inventory_close_requested() -> void:
	clear_inventory_session(true)
	status_message = "Inventory closed."
	update_hud()

func _on_inventory_pack_layout_changed(pack_modules: Array) -> void:
	if inventory_session.is_empty():
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	commit_pack_layout(hero_index, pack_modules)
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_commit_pack_layout.rpc_id(NETWORK_HOST_PEER_ID, hero_index, pack_modules)
	inventory_overlay.refresh_state(build_inventory_stat_lines(hero, hero.inventory_items), build_inventory_ability_sections(hero), build_level_up_reward_lines(hero), food, level_up_food_cost(hero.level), hero_can_level_up(hero), hero.level, hero.pack_modules, hero_spellbook_overlay_data(hero))
	update_hud()

func _on_inventory_level_up_requested() -> void:
	if inventory_session.is_empty():
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_inventory_level_up.rpc_id(NETWORK_HOST_PEER_ID, hero_index)
		status_message = "Level-up requested for %s." % hero.hero_name
		update_hud()
		return
	if grant_level_up_pack_to_hero(hero):
		status_message = "%s reached level %d." % [hero.hero_name, hero.level]
	else:
		status_message = "Not enough food or no room for another pack."
	apply_inventory_stats_to_hero(hero)
	inventory_overlay.refresh_state(build_inventory_stat_lines(hero, hero.inventory_items), build_inventory_ability_sections(hero), build_level_up_reward_lines(hero), food, level_up_food_cost(hero.level), hero_can_level_up(hero), hero.level, hero.pack_modules, hero_spellbook_overlay_data(hero))
	update_hud()

func _on_inventory_spellbook_slots_changed(slotted_spells: Array) -> void:
	if inventory_session.is_empty():
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	commit_spell_slots(hero_index, slotted_spells)
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_commit_spell_slots.rpc_id(NETWORK_HOST_PEER_ID, hero_index, slotted_spells)
	inventory_overlay.refresh_state(build_inventory_stat_lines(hero, hero.inventory_items), build_inventory_ability_sections(hero), build_level_up_reward_lines(hero), food, level_up_food_cost(hero.level), hero_can_level_up(hero), hero.level, hero.pack_modules, hero_spellbook_overlay_data(hero))
	update_hud()

func _on_inventory_item_dropped(item: Dictionary) -> void:
	if inventory_session.is_empty():
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero) or not rooms.has(hero.current_room):
		return
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_inventory_drop.rpc_id(NETWORK_HOST_PEER_ID, hero_index, item)
		status_message = "%s dropped %s." % [hero.hero_name, String(item_defs.get(String(item.get("item_id", "")), {}).get("name", "an item"))]
		update_hud()
		return
	var dropped_item: Dictionary = item.duplicate(true)
	dropped_item.erase("anchor")
	if not dropped_item.has("uid"):
		dropped_item["uid"] = next_item_uid
		next_item_uid += 1
	dropped_item["position"] = clamp_point_to_room(hero.global_position + Vector2(0.0, 34.0) + random_room_offset(18.0), hero.current_room)
	rooms[hero.current_room]["ground_items"].append(dropped_item)
	status_message = "%s dropped %s." % [hero.hero_name, String(item_defs.get(String(dropped_item.get("item_id", "")), {}).get("name", "an item"))]
	update_hud()
	queue_redraw()

func _on_crystal_action_button_pressed() -> void:
	if not can_selected_hero_pick_up_crystal():
		status_message = "Move the selected hero onto the crystal first."
		update_hud()
		return
	var hero: Variant = selected_hero()
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_pick_up_crystal.rpc_id(NETWORK_HOST_PEER_ID, hero.hero_index)
		status_message = "%s reached for the crystal." % hero.hero_name
		update_hud()
		return
	crystal_holder = hero
	crystal_holder.carrying_crystal = true
	crystal_ground_room = INVALID_ROOM
	crystal_prompt_visible = false
	crystal_pressure_timer_left = CRYSTAL_PRESSURE_INTERVAL
	status_message = "%s picked up the crystal. Dark rooms will keep spawning." % hero.hero_name
	update_hud()
	queue_redraw()

func _on_exit_button_pressed() -> void:
	if not carrier_in_exit_room():
		return
	if not all_heroes_in_exit_room():
		status_message = "Bring every hero into the exit room first."
		update_hud()
		return
	var hero: Variant = crystal_holder
	if hero == null or not is_instance_valid(hero):
		return
	if multiplayer_session_active() and not authoritative_simulation_active():
		server_request_exit_floor.rpc_id(NETWORK_HOST_PEER_ID, hero.hero_index)
		status_message = "%s is escaping the floor." % hero.hero_name
		update_hud()
		return
	floor_index += 1
	status_message = "Escaped to floor %d." % floor_index
	build_dungeon(false)
	spawn_heroes()
	selected_room = crystal_room
	center_camera()
	update_hud()
	queue_redraw()

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
