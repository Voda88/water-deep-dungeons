extends Node2D

const HERO_SCENE: PackedScene = preload("res://scenes/actors/hero.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/enemy.tscn")
const INVENTORY_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/inventory_overlay.tscn")
const HERO_SCRIPT: GDScript = preload("res://scripts/actors/hero.gd")
const ENEMY_SCRIPT: GDScript = preload("res://scripts/actors/enemy.gd")
const GAME_CONTENT_DEFS: GDScript = preload("res://scripts/world/game_content_defs.gd")
const GAME_MODULE_DEFS: GDScript = preload("res://scripts/world/game_module_defs.gd")
const GAME_RESEARCH_FLOW: GDScript = preload("res://scripts/world/game_research_flow.gd")
const GAME_ROOM_ACTION_MENU: GDScript = preload("res://scripts/world/game_room_action_menu.gd")
const GAME_COMMAND_FLOW: GDScript = preload("res://scripts/world/game_command_flow.gd")
const GAME_MULTIPLAYER_LOBBY: GDScript = preload("res://scripts/world/game_multiplayer_lobby.gd")
const GAME_NETWORK_SYNC: GDScript = preload("res://scripts/world/game_network_sync.gd")
const GAME_DUNGEON_BUILDER: GDScript = preload("res://scripts/world/game_dungeon_builder.gd")
const GAME_COMBAT_FLOW: GDScript = preload("res://scripts/world/game_combat_flow.gd")
const GAME_PATHING_FLOW: GDScript = preload("res://scripts/world/game_pathing_flow.gd")
const GAME_ENEMY_AI_FLOW: GDScript = preload("res://scripts/world/game_enemy_ai_flow.gd")
const GAME_CARD_ACTIONS: GDScript = preload("res://scripts/world/game_card_actions.gd")
const GAME_HERO_PROGRESSION_FLOW: GDScript = preload("res://scripts/world/game_hero_progression_flow.gd")
const GAME_HERO_PROFILE_FLOW: GDScript = preload("res://scripts/world/game_hero_profile_flow.gd")
const GAME_ACTOR_ROSTER_FLOW: GDScript = preload("res://scripts/world/game_actor_roster_flow.gd")
const GAME_INVENTORY_OVERLAY_FLOW: GDScript = preload("res://scripts/world/game_inventory_overlay_flow.gd")
const GAME_INVENTORY_ITEM_FLOW: GDScript = preload("res://scripts/world/game_inventory_item_flow.gd")
const GAME_CARD_SOURCE_FLOW: GDScript = preload("res://scripts/world/game_card_source_flow.gd")
const GAME_FLOOR_FLOW: GDScript = preload("res://scripts/world/game_floor_flow.gd")
const GAME_ACTOR_COMBAT_FLOW: GDScript = preload("res://scripts/world/game_actor_combat_flow.gd")
const GAME_HUD_FLOW: GDScript = preload("res://scripts/world/game_hud_flow.gd")
const GAME_COMBAT_HAND_UI_FLOW: GDScript = preload("res://scripts/world/game_combat_hand_ui_flow.gd")
const GAME_CONSTRUCTION_FLOW: GDScript = preload("res://scripts/world/game_construction_flow.gd")
const GAME_WORLD_RENDER_FLOW: GDScript = preload("res://scripts/world/game_world_render_flow.gd")
const GAME_WORLD_INPUT_FLOW: GDScript = preload("res://scripts/world/game_world_input_flow.gd")
const GAME_UI_BUTTON_HOLD_FLOW: GDScript = preload("res://scripts/world/game_ui_button_hold_flow.gd")
const GAME_CAMERA_FLOW: GDScript = preload("res://scripts/world/game_camera_flow.gd")
const GAME_RUNTIME_UI_FLOW: GDScript = preload("res://scripts/world/game_runtime_ui_flow.gd")
const GRID_SIZE: Vector2i = Vector2i(7, 7)
const ROOM_SPACING: Vector2 = Vector2(548.0, 358.0)
const ROOM_DOOR_GAP: float = 0.0
const ROOM_LAYOUT_CLEARANCE: float = 0.0
const DOOR_VISUAL_WIDTH: float = 42.0
const DOOR_VISUAL_THICKNESS: float = 10.0
const ROOM_WALKABLE_INSET: float = 4.0
const ROOM_SLOT_INSET: float = 18.0
const ROOM_NAV_CELL_SIZE: float = 12.0
const ROOM_NAV_WALKABLE_MARGIN: float = 3.0
const INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const HERO_INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const DOOR_OPEN_DURATION: float = 1.82
const FRONTIER_DOOR_RADIUS: float = 24.0
const ROOM_TEMPLATE_NOOK: String = "nook"
const ROOM_TEMPLATE_GALLERY: String = "gallery"
const ROOM_TEMPLATE_WORKSHOP: String = "workshop"
const ROOM_TEMPLATE_FORGE: String = "forge"
const FLOOR1_CRYSTAL_ROOM_SCENE: PackedScene = preload("res://scenes/rooms/floor1_crystal_room/floor1_crystal_room.tscn")
const CRYSTAL_ROOM_SCENE: PackedScene = preload("res://scenes/rooms/crystal_room/crystal_room.tscn")
const ROOM_TEMPLATE_SCENES: Dictionary = {
	ROOM_TEMPLATE_NOOK: preload("res://scenes/rooms/nook_room/nook_room.tscn"),
	ROOM_TEMPLATE_GALLERY: preload("res://scenes/rooms/gallery_room/gallery_room.tscn"),
	ROOM_TEMPLATE_WORKSHOP: preload("res://scenes/rooms/workshop_room/workshop_room.tscn"),
	ROOM_TEMPLATE_FORGE: preload("res://scenes/rooms/forge_room/forge_room.tscn"),
}
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
const ENEMY_TYPE_BAT: String = "bat"
const ENEMY_TYPE_GOLEM: String = "golem"
const ENEMY_TYPE_GOBLIN_SHAMAN: String = "goblin_shaman"
const ENEMY_TYPE_SKELETON_ARCHER: String = "skeleton_archer"
const MINOR_MODULE_TURRET: String = "ballista_turret"
const MINOR_MODULE_PULSE: String = "tear_gas"
const MINOR_MODULE_CANNON: String = "neurostun_array"
const MINOR_MODULE_KIP: String = "kip_cannon"
const MAJOR_MODULE_FOOD: String = "food"
const MAJOR_MODULE_SCIENCE: String = "science"
const MAJOR_MODULE_INDUSTRY: String = "industry"
const MAJOR_MODULE_COST: int = 14
const MINOR_MODULE_MAX_HEALTH: float = 80.0
const MAJOR_MODULE_MAX_HEALTH: float = 180.0
const PROJECTILE_SPEED: float = 950.0
const RESEARCH_REROLL_COST: int = 4
const BALLISTA_LEVEL_DAMAGE: Array[float] = [9.0, 10.0, 12.0, 14.0]
const BALLISTA_LEVEL_SCIENCE_COST: Array[int] = [0, 17, 23, 31]
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
const DOOR_WAVE_POINTS: int = 2
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
const HERO_SELECTION_RADIUS: float = 72.0
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
var room_template_metadata_cache: Dictionary = {}
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
var hero_bar_panel: PanelContainer = null
var hero_bar: HBoxContainer = null
var crystal_action_button: Button = null
var exit_button: Button = null
var hero_buttons: Array = []
var inventory_overlay: Variant = null
var research_overlay: ColorRect = null
var research_panel: PanelContainer = null
var research_title_label: Label = null
var research_room_label: Label = null
var research_choice_buttons: Array = []
var research_detail_title_label: Label = null
var research_detail_summary_label: Label = null
var research_detail_stats_label: Label = null
var research_detail_cost_label: Label = null
var research_start_button: Button = null
var research_reroll_button: Button = null
var research_overlay_open_room: Vector2i = INVALID_ROOM
var research_offer_choices: Array = []
var research_selected_index: int = -1
var active_research: Dictionary = {}
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
var minor_module_levels: Dictionary = {}
var major_module_levels: Dictionary = {}

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
	GAME_WORLD_INPUT_FLOW._unhandled_input(self, event)

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
	GAME_WORLD_RENDER_FLOW._draw(self)

func build_item_defs() -> Dictionary:
	return GAME_CONTENT_DEFS.build_item_defs()

func hero_class_definition(class_id: String) -> Dictionary:
	return GAME_CONTENT_DEFS.hero_class_definition(class_id)

func default_learned_spells_for_class(class_id: String) -> Array[String]:
	return GAME_CONTENT_DEFS.default_learned_spells_for_class(class_id, Callable(self, "card_definition"))

func default_slotted_spells_for_class(class_id: String) -> Array[String]:
	return GAME_CONTENT_DEFS.default_slotted_spells_for_class(class_id, Callable(self, "card_definition"))

func implemented_spellbook_spells_for_class(class_id: String) -> Array[String]:
	return GAME_CONTENT_DEFS.implemented_spellbook_spells_for_class(class_id)

func starting_known_spells_for_class(class_id: String) -> Array[String]:
	return GAME_CONTENT_DEFS.starting_known_spells_for_class(class_id, Callable(self, "card_definition"))

func spell_display_name(spell_id: String) -> String:
	return GAME_CONTENT_DEFS.spell_display_name(spell_id, Callable(self, "card_definition"))

func spell_display_names_joined(spell_ids: Array) -> String:
	return GAME_CONTENT_DEFS.spell_display_names_joined(spell_ids, Callable(self, "card_definition"))

func spell_overlay_entry(spell_id: String) -> Dictionary:
	return GAME_CONTENT_DEFS.spell_overlay_entry(spell_id, Callable(self, "card_definition"))

func spell_overlay_entries(spell_ids: Array) -> Array:
	return GAME_CONTENT_DEFS.spell_overlay_entries(spell_ids, Callable(self, "card_definition"))

func spell_focus_item_id_for_class(class_id: String) -> String:
	return GAME_CONTENT_DEFS.spell_focus_item_id_for_class(class_id)

func spell_panel_title_for_class(class_id: String) -> String:
	return GAME_CONTENT_DEFS.spell_panel_title_for_class(class_id)

func full_caster_spell_slots_for_level(level_value: int) -> Array[int]:
	return GAME_CONTENT_DEFS.full_caster_spell_slots_for_level(level_value)

func spell_level(spell_id: String) -> int:
	return GAME_CONTENT_DEFS.spell_level(spell_id, Callable(self, "card_definition"))

func spell_class_id(spell_id: String) -> String:
	return GAME_CONTENT_DEFS.spell_class_id(spell_id, Callable(self, "card_definition"))

func spell_slot_counts_for_class_level(class_id: String, level_value: int) -> Array[int]:
	return GAME_CONTENT_DEFS.spell_slot_counts_for_class_level(class_id, level_value)

func hero_max_spell_level_for_class_level(class_id: String, level_value: int) -> int:
	return GAME_CONTENT_DEFS.hero_max_spell_level_for_class_level(class_id, level_value)

func spell_slot_capacity_for_class_level(class_id: String, level_value: int) -> int:
	return GAME_CONTENT_DEFS.spell_slot_capacity_for_class_level(class_id, level_value)

func default_hero_class_for_slot(hero_index: int) -> String:
	return GAME_CONTENT_DEFS.default_hero_class_for_slot(hero_index, HERO_CLASS_ORDER)

func hero_profile_class_id(hero_index: int) -> String:
	return GAME_HERO_PROFILE_FLOW.hero_profile_class_id(self, hero_index)

func hero_display_name(hero_index: int, class_id: String) -> String:
	return GAME_HERO_PROFILE_FLOW.hero_display_name(self, hero_index, class_id)

func set_hero_profile_class(hero_index: int, class_id: String, apply_to_spawned_hero: bool = true) -> void:
	GAME_HERO_PROFILE_FLOW.set_hero_profile_class(self, hero_index, class_id, apply_to_spawned_hero)

func apply_hero_class_to_node(hero: Variant, class_id: String, display_name: String = "") -> void:
	GAME_HERO_PROFILE_FLOW.apply_hero_class_to_node(self, hero, class_id, display_name)

func hero_class_summary_lines(class_id: String) -> Array[String]:
	return GAME_HERO_PROFILE_FLOW.hero_class_summary_lines(self, class_id)

func hero_class_selection_locked() -> bool:
	return doors_opened > 0 or opened_rooms > 1

func can_local_edit_hero_class(hero_index: int) -> bool:
	return can_local_control_hero_index(hero_index) and not hero_class_selection_locked()

func setup_multiplayer_callbacks() -> void:
	GAME_MULTIPLAYER_LOBBY.setup_multiplayer_callbacks(self)

func multiplayer_session_active() -> bool:
	return GAME_MULTIPLAYER_LOBBY.multiplayer_session_active(self)

func authoritative_simulation_active() -> bool:
	return GAME_MULTIPLAYER_LOBBY.authoritative_simulation_active(self)

func local_peer_id() -> int:
	return GAME_MULTIPLAYER_LOBBY.local_peer_id(self)

func reset_hero_owner_peer_ids() -> void:
	GAME_MULTIPLAYER_LOBBY.reset_hero_owner_peer_ids(self)

func hero_owner_peer_id(hero_index: int) -> int:
	return GAME_MULTIPLAYER_LOBBY.hero_owner_peer_id(self, hero_index)

func can_local_control_hero_index(hero_index: int) -> bool:
	return GAME_MULTIPLAYER_LOBBY.can_local_control_hero_index(self, hero_index)

func first_controlled_hero_index_for_peer(peer_id: int) -> int:
	return GAME_MULTIPLAYER_LOBBY.first_controlled_hero_index_for_peer(self, peer_id)

func controlled_hero_indices_for_peer(peer_id: int) -> Array[int]:
	return GAME_MULTIPLAYER_LOBBY.controlled_hero_indices_for_peer(self, peer_id)

func first_local_controlled_hero_index() -> int:
	return GAME_MULTIPLAYER_LOBBY.first_local_controlled_hero_index(self)

func ensure_valid_selected_hero() -> void:
	GAME_MULTIPLAYER_LOBBY.ensure_valid_selected_hero(self)

func room_actions_allowed_for_local_peer() -> bool:
	return GAME_MULTIPLAYER_LOBBY.room_actions_allowed_for_local_peer(self)

func inventory_actions_allowed_for_local_peer() -> bool:
	return GAME_MULTIPLAYER_LOBBY.inventory_actions_allowed_for_local_peer(self)

func multiplayer_status_text() -> String:
	return GAME_MULTIPLAYER_LOBBY.multiplayer_status_text(self)

func connected_session_peer_ids() -> Array[int]:
	return GAME_MULTIPLAYER_LOBBY.connected_session_peer_ids(self)

func sync_lobby_peer_ready_states(reset_ready: bool = false) -> void:
	GAME_MULTIPLAYER_LOBBY.sync_lobby_peer_ready_states(self, reset_ready)

func local_peer_ready_state() -> bool:
	return GAME_MULTIPLAYER_LOBBY.local_peer_ready_state(self)

func all_lobby_players_ready() -> bool:
	return GAME_MULTIPLAYER_LOBBY.all_lobby_players_ready(self)

func player_display_name(peer_id: int) -> String:
	return GAME_MULTIPLAYER_LOBBY.player_display_name(self, peer_id)

func lobby_hero_label(hero_index: int) -> String:
	return GAME_MULTIPLAYER_LOBBY.lobby_hero_label(self, hero_index)

func rebuild_hero_select_player_list() -> void:
	GAME_MULTIPLAYER_LOBBY.rebuild_hero_select_player_list(self)

func update_network_ui() -> void:
	GAME_MULTIPLAYER_LOBBY.update_network_ui(self)

func set_hero_select_overlay_visible(visible: bool) -> void:
	GAME_MULTIPLAYER_LOBBY.set_hero_select_overlay_visible(self, visible)

func update_hero_select_overlay() -> void:
	GAME_MULTIPLAYER_LOBBY.update_hero_select_overlay(self)

func _on_hero_select_toggle_button_pressed() -> void:
	GAME_MULTIPLAYER_LOBBY.on_hero_select_toggle_button_pressed(self)

func _on_hero_select_card_pressed(hero_index: int) -> void:
	GAME_MULTIPLAYER_LOBBY.on_hero_select_card_pressed(self, hero_index)

func _on_hero_select_detail_class_pressed(class_id: String) -> void:
	GAME_MULTIPLAYER_LOBBY.on_hero_select_detail_class_pressed(self, class_id)

func _on_hero_select_ready_button_pressed() -> void:
	GAME_MULTIPLAYER_LOBBY.on_hero_select_ready_button_pressed(self)

func _on_hero_select_class_pressed(hero_index: int, class_id: String) -> void:
	GAME_MULTIPLAYER_LOBBY.on_hero_select_class_pressed(self, hero_index, class_id)

func _on_hero_select_start_button_pressed() -> void:
	GAME_MULTIPLAYER_LOBBY.on_hero_select_start_button_pressed(self)

func redistribute_multiplayer_hero_owners() -> void:
	GAME_MULTIPLAYER_LOBBY.redistribute_multiplayer_hero_owners(self)

func start_host_session() -> void:
	GAME_MULTIPLAYER_LOBBY.start_host_session(self)

func join_host_session(address_text: String) -> void:
	GAME_MULTIPLAYER_LOBBY.join_host_session(self, address_text)

func stop_network_session(reason: String = "Returned to offline mode.") -> void:
	GAME_MULTIPLAYER_LOBBY.stop_network_session(self, reason)

func _on_multiplayer_peer_connected(peer_id: int) -> void:
	GAME_MULTIPLAYER_LOBBY.on_multiplayer_peer_connected(self, peer_id)

func _on_multiplayer_peer_disconnected(peer_id: int) -> void:
	GAME_MULTIPLAYER_LOBBY.on_multiplayer_peer_disconnected(self, peer_id)

func _on_multiplayer_connected_to_server() -> void:
	GAME_MULTIPLAYER_LOBBY.on_multiplayer_connected_to_server(self)

func _on_multiplayer_connection_failed() -> void:
	GAME_MULTIPLAYER_LOBBY.on_multiplayer_connection_failed(self)

func _on_multiplayer_server_disconnected() -> void:
	GAME_MULTIPLAYER_LOBBY.on_multiplayer_server_disconnected(self)

func _on_network_host_button_pressed() -> void:
	GAME_MULTIPLAYER_LOBBY.on_network_host_button_pressed(self)

func _on_network_join_button_pressed() -> void:
	GAME_MULTIPLAYER_LOBBY.on_network_join_button_pressed(self)

func _on_network_disconnect_button_pressed() -> void:
	GAME_MULTIPLAYER_LOBBY.on_network_disconnect_button_pressed(self)

func ensure_runtime_ui() -> void:
	GAME_RUNTIME_UI_FLOW.ensure_runtime_ui(self)

func research_option_cost(module_type: String, next_level: int, is_major: bool) -> int:
	return GAME_RESEARCH_FLOW.research_option_cost(self, module_type, next_level, is_major)

func research_option_description(module_type: String, next_level: int, is_major: bool) -> String:
	return GAME_RESEARCH_FLOW.research_option_description(self, module_type, next_level, is_major)

func active_research_title() -> String:
	return GAME_RESEARCH_FLOW.active_research_title(self)

func complete_active_research() -> void:
	GAME_RESEARCH_FLOW.complete_active_research(self)

func advance_active_research_on_door_open() -> String:
	return GAME_RESEARCH_FLOW.advance_active_research_on_door_open(self)

func build_research_option(module_type: String, is_major: bool) -> Dictionary:
	return GAME_RESEARCH_FLOW.build_research_option(self, module_type, is_major)

func research_option_stats_text(option: Dictionary) -> String:
	return GAME_RESEARCH_FLOW.research_option_stats_text(self, option)

func roll_research_offer_choices() -> Array:
	return GAME_RESEARCH_FLOW.roll_research_offer_choices(self)

func refresh_research_overlay() -> void:
	GAME_RESEARCH_FLOW.refresh_research_overlay(self)

func open_research_overlay(room_coord: Vector2i) -> void:
	GAME_RESEARCH_FLOW.open_research_overlay(self, room_coord)

func close_research_overlay() -> void:
	GAME_RESEARCH_FLOW.close_research_overlay(self)

func apply_research_option(choice_index: int) -> void:
	GAME_RESEARCH_FLOW.apply_research_option(self, choice_index)

func apply_hud_styling() -> void:
	GAME_HUD_FLOW.apply_hud_styling(self)

func rebuild_hero_bar() -> void:
	GAME_HUD_FLOW.rebuild_hero_bar(self)

func build_dungeon(reset_resources: bool = true) -> void:
	GAME_DUNGEON_BUILDER.build_dungeon(self, reset_resources)

func clear_floor_actors() -> void:
	GAME_ACTOR_ROSTER_FLOW.clear_floor_actors(self)

func ensure_hero_profiles() -> void:
	GAME_HERO_PROFILE_FLOW.ensure_hero_profiles(self)

func hero_supports_spell_repertoire(hero: Variant) -> bool:
	return GAME_HERO_PROFILE_FLOW.hero_supports_spell_repertoire(self, hero)

func hero_has_spell_focus_item(hero: Variant) -> bool:
	return GAME_HERO_PROFILE_FLOW.hero_has_spell_focus_item(self, hero)

func spell_focus_item_uid_for_hero(hero: Variant) -> int:
	return GAME_HERO_PROFILE_FLOW.spell_focus_item_uid_for_hero(self, hero)

func hero_can_prepare_spell(hero: Variant, spell_id: String) -> bool:
	return GAME_HERO_PROFILE_FLOW.hero_can_prepare_spell(self, hero, spell_id)

func hero_spell_repertoire_editable(hero: Variant) -> bool:
	return GAME_HERO_PROFILE_FLOW.hero_spell_repertoire_editable(self, hero)

func prepared_spell_max_copies(hero: Variant, spell_id: String, slot_counts: Array[int] = []) -> int:
	return GAME_HERO_PROFILE_FLOW.prepared_spell_max_copies(self, hero, spell_id, slot_counts)

func default_prepared_spell_list(hero: Variant, slot_counts: Array[int]) -> Array[String]:
	return GAME_HERO_PROFILE_FLOW.default_prepared_spell_list(self, hero, slot_counts)

func cleaned_prepared_spell_list(hero: Variant, source_spells: Array) -> Array[String]:
	return GAME_HERO_PROFILE_FLOW.cleaned_prepared_spell_list(self, hero, source_spells)

func refresh_active_floor_spells(hero: Variant, force_saved_repertoire: bool = false) -> void:
	GAME_HERO_PROFILE_FLOW.refresh_active_floor_spells(self, hero, force_saved_repertoire)

func sanitize_hero_spellbook(hero: Variant) -> void:
	GAME_HERO_PROFILE_FLOW.sanitize_hero_spellbook(self, hero)

func save_hero_profiles_from_nodes() -> void:
	GAME_HERO_PROFILE_FLOW.save_hero_profiles_from_nodes(self)

func roll_room_template() -> String:
	return GAME_DUNGEON_BUILDER.roll_room_template(self)

func crystal_room_door_dirs_for_floor() -> Array:
	return GAME_DUNGEON_BUILDER.crystal_room_door_dirs_for_floor(self)

func door_dirs_suffix(door_dirs: Array) -> String:
	return GAME_DUNGEON_BUILDER.door_dirs_suffix(self, door_dirs)

func cardinal_dir_key(direction: Vector2i) -> String:
	return GAME_DUNGEON_BUILDER.cardinal_dir_key(self, direction)

func room_template_base_scene_path(template_id: String, crystal_chamber: bool = false) -> String:
	return GAME_DUNGEON_BUILDER.room_template_base_scene_path(self, template_id, crystal_chamber)

func room_template_scene_path(template_id: String, _door_dirs: Array = [], crystal_chamber: bool = false) -> String:
	return GAME_DUNGEON_BUILDER.room_template_scene_path(self, template_id, _door_dirs, crystal_chamber)

func room_template_scene(template_id: String, door_dirs: Array = [], crystal_chamber: bool = false) -> PackedScene:
	return GAME_DUNGEON_BUILDER.room_template_scene(self, template_id, door_dirs, crystal_chamber)

func room_template_metadata(template_id: String, door_dirs: Array = [], crystal_chamber: bool = false) -> Dictionary:
	return GAME_DUNGEON_BUILDER.room_template_metadata(self, template_id, door_dirs, crystal_chamber)

func shrink_normalized_rect(rect: Rect2, margin: Vector2) -> Rect2:
	return GAME_DUNGEON_BUILDER.shrink_normalized_rect(self, rect, margin)

func floor_theme_id_for_floor(target_floor_index: int) -> String:
	return GAME_DUNGEON_BUILDER.floor_theme_id_for_floor(self, target_floor_index)

func current_floor_theme_id() -> String:
	return GAME_DUNGEON_BUILDER.current_floor_theme_id(self)

func pick_room_geometry_id(template_id: String, door_dirs: Array, crystal_chamber: bool = false) -> String:
	return GAME_DUNGEON_BUILDER.pick_room_geometry_id(self, template_id, door_dirs, crystal_chamber)

func build_room_geometry(template_id: String, door_dirs: Array, crystal_chamber: bool = false) -> Dictionary:
	return GAME_DUNGEON_BUILDER.build_room_geometry(self, template_id, door_dirs, crystal_chamber)

func normalize_runtime_room_slot_capacity(room_coord: Vector2i, room_data: Dictionary) -> Dictionary:
	return GAME_DUNGEON_BUILDER.normalize_runtime_room_slot_capacity(self, room_coord, room_data)

func normalize_runtime_rooms_slot_capacity() -> void:
	GAME_DUNGEON_BUILDER.normalize_runtime_rooms_slot_capacity(self)

func create_room(room_coord: Vector2i, template_id: String, door_dirs: Array, world_center: Vector2 = Vector2.INF) -> void:
	GAME_DUNGEON_BUILDER.create_room(self, room_coord, template_id, door_dirs, world_center)

func room_template_door_options(template_id: String) -> Array:
	return GAME_DUNGEON_BUILDER.room_template_door_options(self, template_id)

func random_template_doors(template_id: String, required_dir: Vector2i = INVALID_ROOM) -> Array:
	return GAME_DUNGEON_BUILDER.random_template_doors(self, template_id, required_dir)

func template_can_support_major_slots(template_id: String) -> bool:
	return GAME_DUNGEON_BUILDER.template_can_support_major_slots(self, template_id)

func room_blueprint_weight(template_id: String, door_dirs: Array, prefer_major: bool = false, prefer_dead_end: bool = false) -> float:
	return GAME_DUNGEON_BUILDER.room_blueprint_weight(self, template_id, door_dirs, prefer_major, prefer_dead_end)

func roll_room_blueprint(required_dir: Vector2i, prefer_major: bool = false, prefer_dead_end: bool = false, minimum_doors: int = 1) -> Dictionary:
	return GAME_DUNGEON_BUILDER.roll_room_blueprint(self, required_dir, prefer_major, prefer_dead_end, minimum_doors)

func room_template_size(template_id: String) -> Vector2:
	return GAME_DUNGEON_BUILDER.room_template_size(self, template_id)

func proposed_room_center(origin_room: Vector2i, template_id: String, direction: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.proposed_room_center(self, origin_room, template_id, direction)

func can_place_room_center(world_center: Vector2, room_size: Vector2) -> bool:
	return GAME_DUNGEON_BUILDER.can_place_room_center(self, world_center, room_size)

func collect_frontier_sockets() -> Array:
	return GAME_DUNGEON_BUILDER.collect_frontier_sockets(self)

func connect_rooms(a: Vector2i, b: Vector2i) -> void:
	GAME_DUNGEON_BUILDER.connect_rooms(self, a, b)

func are_neighbors(a: Vector2i, b: Vector2i) -> bool:
	return GAME_DUNGEON_BUILDER.are_neighbors(self, a, b)

func finalize_room_slot_distribution() -> void:
	GAME_DUNGEON_BUILDER.finalize_room_slot_distribution(self)

func assign_exit_room() -> void:
	GAME_DUNGEON_BUILDER.assign_exit_room(self)

func assign_research_crystals() -> void:
	GAME_DUNGEON_BUILDER.assign_research_crystals(self)

func spawn_heroes() -> void:
	GAME_ACTOR_ROSTER_FLOW.spawn_heroes(self)

func item_size_in_cells(item: Dictionary) -> Vector2i:
	return GAME_INVENTORY_ITEM_FLOW.item_size_in_cells(self, item)

func normalize_item_instance(item_variant: Variant) -> Dictionary:
	return GAME_INVENTORY_ITEM_FLOW.normalize_item_instance(self, item_variant)

func make_ground_item(item_id: String, world_position: Vector2) -> Dictionary:
	return GAME_INVENTORY_ITEM_FLOW.make_ground_item(self, item_id, world_position)

func roll_ground_item_id() -> String:
	return GAME_INVENTORY_ITEM_FLOW.roll_ground_item_id(self)

func spawn_ground_loot(room_coord: Vector2i) -> void:
	GAME_INVENTORY_ITEM_FLOW.spawn_ground_loot(self, room_coord)

func ground_item_draw_rect(ground_item: Dictionary) -> Rect2:
	return GAME_INVENTORY_ITEM_FLOW.ground_item_draw_rect(self, ground_item)

func ground_item_pick_rect(ground_item: Dictionary) -> Rect2:
	return GAME_INVENTORY_ITEM_FLOW.ground_item_pick_rect(self, ground_item)

func ground_item_at_world_position(world_position: Vector2) -> Dictionary:
	return GAME_INVENTORY_ITEM_FLOW.ground_item_at_world_position(self, world_position)

func find_ground_item_index(room_coord: Vector2i, item_uid: int) -> int:
	return GAME_INVENTORY_ITEM_FLOW.find_ground_item_index(self, room_coord, item_uid)

func prepare_ground_items_for_room(room_coord: Vector2i, ground_items: Array) -> Array:
	return GAME_INVENTORY_ITEM_FLOW.prepare_ground_items_for_room(self, room_coord, ground_items)

func inventory_base_cells() -> Array:
	return GAME_INVENTORY_ITEM_FLOW.inventory_base_cells(self)

func pack_cells(pack_module: Dictionary) -> Array:
	return GAME_INVENTORY_ITEM_FLOW.pack_cells(self, pack_module)

func active_inventory_cells_from_packs(pack_modules: Array) -> Dictionary:
	return GAME_INVENTORY_ITEM_FLOW.active_inventory_cells_from_packs(self, pack_modules)

func inventory_capacity(pack_modules: Array) -> int:
	return GAME_INVENTORY_ITEM_FLOW.inventory_capacity(self, pack_modules)

func can_place_pack_module(pack_modules: Array, pack_size: Vector2i, anchor: Vector2i, ignore_index: int = -1) -> bool:
	return GAME_INVENTORY_ITEM_FLOW.can_place_pack_module(self, pack_modules, pack_size, anchor, ignore_index)

func item_fits_active_cells(item: Dictionary, active_cells: Dictionary) -> bool:
	return GAME_INVENTORY_ITEM_FLOW.item_fits_active_cells(self, item, active_cells)

func find_default_pack_anchor(pack_modules: Array, pack_size: Vector2i) -> Vector2i:
	return GAME_INVENTORY_ITEM_FLOW.find_default_pack_anchor(self, pack_modules, pack_size)

func next_level_pack_size(level_value: int) -> Vector2i:
	return GAME_HERO_PROGRESSION_FLOW.next_level_pack_size(self, level_value)

func hero_level_stat_bonuses(level_value: int) -> Dictionary:
	return GAME_HERO_PROGRESSION_FLOW.hero_level_stat_bonuses(self, level_value)

func hero_spell_slot_capacity(hero: Variant) -> int:
	return GAME_HERO_PROGRESSION_FLOW.hero_spell_slot_capacity(self, hero)

func hero_spell_slot_counts(hero: Variant) -> Array[int]:
	return GAME_HERO_PROGRESSION_FLOW.hero_spell_slot_counts(self, hero)

func hero_spellbook_overlay_data(hero: Variant) -> Dictionary:
	return GAME_HERO_PROGRESSION_FLOW.hero_spellbook_overlay_data(self, hero)

func hero_can_study_spell(hero: Variant, spell_id: String) -> bool:
	return GAME_HERO_PROGRESSION_FLOW.hero_can_study_spell(self, hero, spell_id)

func begin_spell_scroll_study(hero: Variant, spell_id: String) -> bool:
	return GAME_HERO_PROGRESSION_FLOW.begin_spell_scroll_study(self, hero, spell_id)

func resolve_spell_scroll_studies() -> void:
	GAME_HERO_PROGRESSION_FLOW.resolve_spell_scroll_studies(self)

func advance_spell_scroll_studies() -> void:
	GAME_HERO_PROGRESSION_FLOW.advance_spell_scroll_studies(self)

func hero_next_level_unlock_names(hero: Variant) -> Array[String]:
	return GAME_HERO_PROGRESSION_FLOW.hero_next_level_unlock_names(self, hero)

func build_level_up_reward_lines(hero: Variant) -> Array[String]:
	return GAME_HERO_PROGRESSION_FLOW.build_level_up_reward_lines(self, hero)

func level_up_food_cost(level_value: int) -> int:
	return GAME_HERO_PROGRESSION_FLOW.level_up_food_cost(self, level_value)

func hero_next_pack_size(hero: Variant) -> Vector2i:
	return GAME_HERO_PROGRESSION_FLOW.hero_next_pack_size(self, hero)

func hero_can_level_up(hero: Variant) -> bool:
	return GAME_HERO_PROGRESSION_FLOW.hero_can_level_up(self, hero)

func grant_level_up_pack_to_hero(hero: Variant) -> bool:
	return GAME_HERO_PROGRESSION_FLOW.grant_level_up_pack_to_hero(self, hero)

func item_occupied_cells(item: Dictionary) -> Array:
	return GAME_INVENTORY_ITEM_FLOW.item_occupied_cells(self, item)

func can_place_inventory_item(hero: Variant, item: Dictionary, anchor: Vector2i, ignore_uid: int = -1) -> bool:
	return GAME_INVENTORY_ITEM_FLOW.can_place_inventory_item(self, hero, item, anchor, ignore_uid)

func find_first_inventory_item_anchor(hero: Variant, item: Dictionary) -> Vector2i:
	return GAME_INVENTORY_ITEM_FLOW.find_first_inventory_item_anchor(self, hero, item)

func add_item_to_hero_inventory(hero: Variant, item_variant: Variant) -> bool:
	return GAME_INVENTORY_ITEM_FLOW.add_item_to_hero_inventory(self, hero, item_variant)

func item_has_tag(item: Dictionary, tag_name: String) -> bool:
	return GAME_INVENTORY_ITEM_FLOW.item_has_tag(self, item, tag_name)

func item_instance_enabled(item: Dictionary) -> bool:
	return GAME_INVENTORY_ITEM_FLOW.item_instance_enabled(self, item)

func rotated_socket_offset(item: Dictionary, socket_offset: Vector2i) -> Vector2i:
	return GAME_INVENTORY_ITEM_FLOW.rotated_socket_offset(self, item, socket_offset)

func socket_match_entries(socket_rule: Dictionary) -> Array:
	return GAME_INVENTORY_ITEM_FLOW.socket_match_entries(self, socket_rule)

func card_definition(card_id: String) -> Dictionary:
	return GAME_CONTENT_DEFS.runtime_card_definition(self, card_id)

func card_target_scope_label(target_scope: String) -> String:
	return GAME_CONTENT_DEFS.card_target_scope_label(self, target_scope)

func hero_builtin_card_generators(hero: Variant) -> Array:
	return GAME_CONTENT_DEFS.hero_builtin_card_generators(self, hero)

func spellbook_card_generators(hero: Variant, effect_summary: Dictionary) -> Array:
	return GAME_CONTENT_DEFS.spellbook_card_generators(self, hero, effect_summary)

func empty_inventory_effect_summary() -> Dictionary:
	return GAME_INVENTORY_ITEM_FLOW.empty_inventory_effect_summary(self)

func inventory_effect_summary(items: Array) -> Dictionary:
	return GAME_INVENTORY_ITEM_FLOW.inventory_effect_summary(self, items)

func build_inventory_stat_lines(hero: Variant, items: Array) -> Array[String]:
	return GAME_HERO_PROGRESSION_FLOW.build_inventory_stat_lines(self, hero, items)

func format_ability_metric(value: float) -> String:
	return GAME_HERO_PROGRESSION_FLOW.format_ability_metric(self, value)

func ability_detail_text(cooldown: float, power_text: String, stamina_cost: float, extra_text: String = "") -> String:
	return GAME_HERO_PROGRESSION_FLOW.ability_detail_text(self, cooldown, power_text, stamina_cost, extra_text)

func ability_power_text(card_id: String, payload: Dictionary) -> String:
	return GAME_HERO_PROGRESSION_FLOW.ability_power_text(self, card_id, payload)

func build_inventory_ability_sections(hero: Variant) -> Array:
	return GAME_HERO_PROGRESSION_FLOW.build_inventory_ability_sections(self, hero)

func apply_inventory_stats_to_hero(hero: Variant) -> void:
	GAME_HERO_PROGRESSION_FLOW.apply_inventory_stats_to_hero(self, hero)
func card_generator_key(item_uid: int, card_id: String) -> String:
	return "%d:%s" % [item_uid, card_id]

func combat_passive_key(item_uid: int, card_id: String) -> String:
	return "passive:%d:%s" % [item_uid, card_id]

func collect_world_item_uids() -> Dictionary:
	return GAME_INVENTORY_ITEM_FLOW.collect_world_item_uids(self)

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
	GAME_INVENTORY_ITEM_FLOW.cleanup_global_item_card_states(self)

func remove_item_by_uid_from_world(item_uid: int) -> void:
	GAME_INVENTORY_ITEM_FLOW.remove_item_by_uid_from_world(self, item_uid)

func consume_item_charges_by_uid(item_uid: int, amount: int, orphan_generated_cards_on_break: bool = false) -> bool:
	return GAME_INVENTORY_ITEM_FLOW.consume_item_charges_by_uid(self, item_uid, amount, orphan_generated_cards_on_break)

func hero_emits_room_light(hero: Variant) -> bool:
	return GAME_FLOOR_FLOW.hero_emits_room_light(self, hero)

func room_has_wave_torch_light(room: Dictionary) -> bool:
	return GAME_FLOOR_FLOW.room_has_wave_torch_light(self, room)

func refresh_room_lighting_states() -> void:
	GAME_FLOOR_FLOW.refresh_room_lighting_states(self)

func apply_temporary_light_to_room(room_coord: Vector2i, turn_count: int) -> bool:
	return GAME_FLOOR_FLOW.apply_temporary_light_to_room(self, room_coord, turn_count)

func apply_wave_torch_light_to_room(room_coord: Vector2i) -> bool:
	return GAME_FLOOR_FLOW.apply_wave_torch_light_to_room(self, room_coord)

func apply_portable_item_effects_on_door_open() -> void:
	GAME_FLOOR_FLOW.apply_portable_item_effects_on_door_open(self)

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
	return GAME_CARD_SOURCE_FLOW.build_hand_card_from_generator(self, hero, generator, effect_summary)

func build_passive_combat_payload(passive_ability: Dictionary, effect_summary: Dictionary) -> Dictionary:
	return GAME_CARD_SOURCE_FLOW.build_passive_combat_payload(self, passive_ability, effect_summary)

func sync_hero_builtin_card_sources(hero: Variant) -> void:
	GAME_CARD_SOURCE_FLOW.sync_hero_builtin_card_sources(self, hero)

func fill_queued_hero_builtin_cards(hero: Variant) -> void:
	GAME_CARD_SOURCE_FLOW.fill_queued_hero_builtin_cards(self, hero)

func advance_hero_builtin_door_card_generators(door_count: int = 1) -> void:
	GAME_CARD_SOURCE_FLOW.advance_hero_builtin_door_card_generators(self, door_count)

func expire_door_turn_hand_cards() -> void:
	GAME_CARD_SOURCE_FLOW.expire_door_turn_hand_cards(self)

func sync_hero_card_sources(hero: Variant, effect_summary: Dictionary = {}) -> void:
	GAME_CARD_SOURCE_FLOW.sync_hero_card_sources(self, hero, effect_summary)

func sync_hero_passive_combat_sources(hero: Variant, effect_summary: Dictionary = {}) -> void:
	GAME_CARD_SOURCE_FLOW.sync_hero_passive_combat_sources(self, hero, effect_summary)

func fill_queued_hand_cards(hero: Variant, effect_summary: Dictionary = {}, precomputed_generators: Array = []) -> void:
	GAME_CARD_SOURCE_FLOW.fill_queued_hand_cards(self, hero, effect_summary, precomputed_generators)

func advance_item_door_card_generators(door_count: int = 1) -> void:
	GAME_CARD_SOURCE_FLOW.advance_item_door_card_generators(self, door_count)

func open_room_loot_inventory(hero: Variant, room_coord: Vector2i) -> void:
	GAME_INVENTORY_OVERLAY_FLOW.open_room_loot_inventory(self, hero, room_coord)

func open_hero_inventory(hero: Variant, room_coord: Vector2i = INVALID_ROOM) -> void:
	GAME_INVENTORY_OVERLAY_FLOW.open_hero_inventory(self, hero, room_coord)

func clear_inventory_session(_commit_pending_item: bool) -> void:
	GAME_INVENTORY_OVERLAY_FLOW.clear_inventory_session(self, _commit_pending_item)

func commit_inventory_state(hero_index: int, room_coord: Vector2i, items: Array, ground_items: Array) -> void:
	GAME_INVENTORY_OVERLAY_FLOW.commit_inventory_state(self, hero_index, room_coord, items, ground_items)

func commit_pack_layout(hero_index: int, pack_modules: Array) -> void:
	GAME_INVENTORY_OVERLAY_FLOW.commit_pack_layout(self, hero_index, pack_modules)

func reset_hero_spellbook_generated_cards(hero: Variant) -> void:
	GAME_INVENTORY_OVERLAY_FLOW.reset_hero_spellbook_generated_cards(self, hero)

func commit_spell_slots(hero_index: int, slotted_spells: Array) -> void:
	GAME_INVENTORY_OVERLAY_FLOW.commit_spell_slots(self, hero_index, slotted_spells)
func center_camera() -> void:
	GAME_CAMERA_FLOW.center_camera(self)

func hero_is_active(hero: Variant) -> bool:
	return hero != null and is_instance_valid(hero) and (not hero.has_method("is_dead_state") or not hero.is_dead_state()) and float(hero.current_health) > 0.0

func is_hero_actor(actor: Variant) -> bool:
	return actor != null and is_instance_valid(actor) and actor.get_script() == HERO_SCRIPT

func is_enemy_actor(actor: Variant) -> bool:
	return actor != null and is_instance_valid(actor) and actor.get_script() == ENEMY_SCRIPT

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

func room_local_idle_position_for_hero(room_coord: Vector2i, hero: Variant) -> Vector2:
	if hero == null or not is_instance_valid(hero):
		return room_walkable_center(room_coord)
	var room_heroes: Array = heroes_in_room(room_coord)
	room_heroes.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(a.hero_index) < int(b.hero_index)
	)
	var slot_index: int = 0
	for index in range(room_heroes.size()):
		if room_heroes[index] == hero:
			slot_index = index
			break
	var room_rect_local: Rect2 = room_rect(room_coord)
	var count: int = max(room_heroes.size(), 1)
	var spread: float = 52.0
	var start_x: float = -spread * 0.5 * float(max(count - 1, 1))
	return clamp_point_to_room(room_rect_local.get_center() + Vector2(start_x + float(slot_index) * spread, 24.0), room_coord)

func hero_room_command_target_position(hero: Variant, room_coord: Vector2i) -> Vector2:
	if hero == null or not is_instance_valid(hero):
		return room_action_staging_position(room_coord)
	return hero_idle_position(room_coord, int(hero.hero_index), max(alive_hero_count(), 1))

func hero_room_entry_target_position(path: Array[Vector2i], hero: Variant, room_coord: Vector2i) -> Vector2:
	if path.size() > 1:
		return doorway_navigation_position(room_coord, path[path.size() - 2])
	return hero_room_command_target_position(hero, room_coord)

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
		if hero.current_room != exit_room or hero.pending_room != HERO_INVALID_ROOM or not hero.is_idle():
			return false
	return true

func ui_button_hold_duration(button_id: String) -> float:
	return GAME_UI_BUTTON_HOLD_FLOW.ui_button_hold_duration(self, button_id)

func ui_button_hold_button(button_id: String) -> Button:
	return GAME_UI_BUTTON_HOLD_FLOW.ui_button_hold_button(self, button_id)

func ui_button_hold_progress(button_id: String) -> float:
	return GAME_UI_BUTTON_HOLD_FLOW.ui_button_hold_progress(self, button_id)

func hold_button_text(base_text: String, button_id: String) -> String:
	return GAME_UI_BUTTON_HOLD_FLOW.hold_button_text(self, base_text, button_id)

func update_restart_button_hold_fill() -> void:
	GAME_HUD_FLOW.update_restart_button_hold_fill(self)
func begin_ui_button_hold(button_id: String) -> void:
	GAME_UI_BUTTON_HOLD_FLOW.begin_ui_button_hold(self, button_id)

func cancel_ui_button_hold(button_id: String = "") -> void:
	GAME_UI_BUTTON_HOLD_FLOW.cancel_ui_button_hold(self, button_id)

func advance_ui_button_hold(delta: float) -> void:
	GAME_UI_BUTTON_HOLD_FLOW.advance_ui_button_hold(self, delta)

func trigger_ui_button_hold_action(button_id: String) -> void:
	GAME_UI_BUTTON_HOLD_FLOW.trigger_ui_button_hold_action(self, button_id)

func _on_ui_button_hold_down(button_id: String) -> void:
	begin_ui_button_hold(button_id)

func _on_ui_button_hold_up(button_id: String) -> void:
	cancel_ui_button_hold(button_id)

func _on_ui_button_hold_cancel(button_id: String) -> void:
	cancel_ui_button_hold(button_id)

func refresh_camera_bounds() -> void:
	GAME_CAMERA_FLOW.refresh_camera_bounds(self)

func hero_focus_position() -> Vector2:
	return GAME_CAMERA_FLOW.hero_focus_position(self)

func mark_camera_interaction() -> void:
	GAME_CAMERA_FLOW.mark_camera_interaction(self)

func mark_camera_pan_interaction() -> void:
	GAME_CAMERA_FLOW.mark_camera_pan_interaction(self)

func reset_camera_pan_state() -> void:
	GAME_CAMERA_FLOW.reset_camera_pan_state(self)

func cancel_room_action_camera_focus() -> void:
	GAME_CAMERA_FLOW.cancel_room_action_camera_focus(self)

func room_action_overlay_scale() -> float:
	return GAME_ROOM_ACTION_MENU.room_action_overlay_scale(self)

func room_action_menu_screen_center() -> Vector2:
	return GAME_ROOM_ACTION_MENU.room_action_menu_screen_center(self)

func advance_camera(delta: float) -> void:
	GAME_CAMERA_FLOW.advance_camera(self, delta)

func clamp_camera() -> void:
	GAME_CAMERA_FLOW.clamp_camera(self)

func set_camera_zoom(zoom_value: float) -> void:
	GAME_CAMERA_FLOW.set_camera_zoom(self, zoom_value)

func handle_inventory_input(event: InputEvent) -> void:
	GAME_WORLD_INPUT_FLOW.handle_inventory_input(self, event)
func clear_pending_room_loot_request(hero_index: int = -1) -> void:
	GAME_COMMAND_FLOW.clear_pending_room_loot_request(self, hero_index)

func clear_pending_room_action_request(hero_index: int = -1) -> void:
	GAME_COMMAND_FLOW.clear_pending_room_action_request(self, hero_index)

func try_open_pending_room_loot_request(hero: Variant) -> bool:
	return GAME_COMMAND_FLOW.try_open_pending_room_loot_request(self, hero)

func try_execute_pending_room_action_request(hero: Variant) -> bool:
	return GAME_COMMAND_FLOW.try_execute_pending_room_action_request(self, hero)

func clear_room_action_hold() -> void:
	GAME_ROOM_ACTION_MENU.clear_room_action_hold(self)

func clear_room_action_menu_pointer() -> void:
	GAME_ROOM_ACTION_MENU.clear_room_action_menu_pointer(self)

func room_action_menu_virtual_pointer_screen_position() -> Vector2:
	return GAME_ROOM_ACTION_MENU.room_action_menu_virtual_pointer_screen_position(self)

func begin_room_action_menu_pointer(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	return GAME_ROOM_ACTION_MENU.begin_room_action_menu_pointer(self, pointer_kind, pointer_id, screen_position)

func update_room_action_menu_pointer(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	return GAME_ROOM_ACTION_MENU.update_room_action_menu_pointer(self, pointer_kind, pointer_id, screen_position)

func release_room_action_menu_pointer(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	return GAME_ROOM_ACTION_MENU.release_room_action_menu_pointer(self, pointer_kind, pointer_id, screen_position)

func focus_room_action_menu(room_coord: Vector2i, _center_on_screen: bool) -> void:
	GAME_ROOM_ACTION_MENU.focus_room_action_menu(self, room_coord, _center_on_screen)

func close_room_action_menu() -> void:
	GAME_ROOM_ACTION_MENU.close_room_action_menu(self)

func room_action_target_for_selected_hero() -> Vector2i:
	return GAME_ROOM_ACTION_MENU.room_action_target_for_selected_hero(self)

func begin_room_action_hold(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> void:
	GAME_ROOM_ACTION_MENU.begin_room_action_hold(self, pointer_kind, pointer_id, screen_position)

func advance_room_action_hold(delta: float) -> void:
	GAME_ROOM_ACTION_MENU.advance_room_action_hold(self, delta)

func handle_screen_touch(event: InputEventScreenTouch) -> void:
	GAME_COMMAND_FLOW.handle_screen_touch(self, event)

func handle_screen_drag(event: InputEventScreenDrag) -> void:
	GAME_COMMAND_FLOW.handle_screen_drag(self, event)

func begin_pinch_gesture() -> void:
	GAME_COMMAND_FLOW.begin_pinch_gesture(self)

func update_pinch_gesture() -> void:
	GAME_COMMAND_FLOW.update_pinch_gesture(self)

func handle_mouse_button(event: InputEventMouseButton) -> void:
	GAME_COMMAND_FLOW.handle_mouse_button(self, event)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	GAME_COMMAND_FLOW.handle_mouse_motion(self, event)

func try_handle_crystal_tap(world_position: Vector2) -> bool:
	return GAME_WORLD_INPUT_FLOW.try_handle_crystal_tap(self, world_position)

func can_selected_hero_pick_up_crystal() -> bool:
	return GAME_WORLD_INPUT_FLOW.can_selected_hero_pick_up_crystal(self)

func is_exit_discovered() -> bool:
	return GAME_WORLD_INPUT_FLOW.is_exit_discovered(self)

func drop_crystal(room_coord: Vector2i) -> void:
	GAME_WORLD_INPUT_FLOW.drop_crystal(self, room_coord)

func handle_world_tap(world_position: Vector2, screen_position: Vector2) -> void:
	GAME_COMMAND_FLOW.handle_world_tap(self, world_position, screen_position)

func execute_world_command_for_hero(hero_index: int, world_position: Vector2, update_local_selection: bool) -> void:
	GAME_COMMAND_FLOW.execute_world_command_for_hero(self, hero_index, world_position, update_local_selection)

func open_room_action_menu(room_coord: Vector2i, screen_position: Vector2, hold_selection_active: bool = false, pointer_kind: String = "", pointer_id: int = -1) -> void:
	GAME_ROOM_ACTION_MENU.open_room_action_menu(self, room_coord, screen_position, hold_selection_active, pointer_kind, pointer_id)

func room_action_button_layout() -> Array:
	return GAME_ROOM_ACTION_MENU.room_action_button_layout(self)

func room_action_sector_layout() -> Array:
	return GAME_ROOM_ACTION_MENU.room_action_sector_layout(self)

func room_action_angle_near_reference(angle: float, reference: float) -> float:
	return GAME_ROOM_ACTION_MENU.room_action_angle_near_reference(self, angle, reference)

func room_action_button_screen_center(button_data: Dictionary) -> Vector2:
	return GAME_ROOM_ACTION_MENU.room_action_button_screen_center(self, button_data)

func room_action_button_at_screen_position(screen_position: Vector2) -> String:
	return GAME_ROOM_ACTION_MENU.room_action_button_at_screen_position(self, screen_position)

func room_action_sector_points(center: Vector2, inner_radius: float, outer_radius: float, start_angle: float, end_angle: float, segments: int = 18) -> PackedVector2Array:
	return GAME_ROOM_ACTION_MENU.room_action_sector_points(self, center, inner_radius, outer_radius, start_angle, end_angle, segments)

func handle_room_action_menu_tap(screen_position: Vector2) -> void:
	GAME_ROOM_ACTION_MENU.handle_room_action_menu_tap(self, screen_position)

func perform_room_action(room_coord: Vector2i, action_id: String) -> void:
	GAME_ROOM_ACTION_MENU.perform_room_action(self, room_coord, action_id)

func request_room_loot(room_coord: Vector2i) -> void:
	GAME_COMMAND_FLOW.request_room_loot(self, room_coord)

func request_room_loot_for_hero(hero_index: int, room_coord: Vector2i) -> void:
	GAME_COMMAND_FLOW.request_room_loot_for_hero(self, hero_index, room_coord)

func hero_ready_for_room_action(hero: Variant, room_coord: Vector2i) -> bool:
	return GAME_COMMAND_FLOW.hero_ready_for_room_action(self, hero, room_coord)

func room_action_staging_position(room_coord: Vector2i) -> Vector2:
	return GAME_COMMAND_FLOW.room_action_staging_position(self, room_coord)

func request_deferred_room_action(room_coord: Vector2i, kind: String, module_type: String = "") -> bool:
	return GAME_COMMAND_FLOW.request_deferred_room_action(self, room_coord, kind, module_type)

func request_deferred_room_action_for_hero(hero_index: int, room_coord: Vector2i, kind: String, module_type: String = "") -> bool:
	return GAME_COMMAND_FLOW.request_deferred_room_action_for_hero(self, hero_index, room_coord, kind, module_type)

func request_deferred_room_card_for_hero(hero_index: int, room_coord: Vector2i, target_room: Vector2i, card_uid: int, target_world_position: Vector2) -> bool:
	return GAME_COMMAND_FLOW.request_deferred_room_card_for_hero(self, hero_index, room_coord, target_room, card_uid, target_world_position)

func request_room_light(room_coord: Vector2i) -> bool:
	return GAME_COMMAND_FLOW.request_room_light(self, room_coord)

func request_room_light_for_hero(hero_index: int, room_coord: Vector2i) -> bool:
	return GAME_COMMAND_FLOW.request_room_light_for_hero(self, hero_index, room_coord)

func request_room_research(room_coord: Vector2i) -> bool:
	return GAME_COMMAND_FLOW.request_room_research(self, room_coord)

func request_room_research_for_hero(hero_index: int, room_coord: Vector2i) -> bool:
	return GAME_COMMAND_FLOW.request_room_research_for_hero(self, hero_index, room_coord)

func request_room_construction(room_coord: Vector2i, module_type: String) -> bool:
	return GAME_COMMAND_FLOW.request_room_construction(self, room_coord, module_type)

func request_room_construction_for_hero(hero_index: int, room_coord: Vector2i, module_type: String) -> bool:
	return GAME_COMMAND_FLOW.request_room_construction_for_hero(self, hero_index, room_coord, module_type)

func loot_focus_position(room_coord: Vector2i) -> Vector2:
	if rooms.has(room_coord) and not rooms[room_coord]["ground_items"].is_empty():
		return clamp_point_to_room(Vector2(rooms[room_coord]["ground_items"][0]["position"]), room_coord)
	return room_walkable_center(room_coord)

func room_action_enabled(room_coord: Vector2i, action_id: String) -> bool:
	return GAME_COMMAND_FLOW.room_action_enabled(self, room_coord, action_id)

func build_menu_contains_screen_position(screen_position: Vector2) -> bool:
	return build_menu.visible and build_menu.get_global_rect().has_point(screen_position)

func is_valid_build_target_tap(world_position: Vector2) -> bool:
	return GAME_CONSTRUCTION_FLOW.is_valid_build_target_tap(self, world_position)

func start_room_opening(room_coord: Vector2i, from_room: Vector2i) -> void:
	GAME_FLOOR_FLOW.start_room_opening(self, room_coord, from_room)

func advance_room_opening(delta: float) -> void:
	GAME_FLOOR_FLOW.advance_room_opening(self, delta)

func finish_room_opening() -> void:
	GAME_FLOOR_FLOW.finish_room_opening(self)

func advance_temporary_room_lights(turn_count: int = 1) -> void:
	GAME_FLOOR_FLOW.advance_temporary_room_lights(self, turn_count)

func open_room(room_coord: Vector2i) -> void:
	GAME_FLOOR_FLOW.open_room(self, room_coord)

func calculate_door_rewards() -> Dictionary:
	return GAME_FLOOR_FLOW.calculate_door_rewards(self)

func spawn_door_reward_texts(room_coord: Vector2i, door_reward: Dictionary, dust_reward: int) -> void:
	GAME_FLOOR_FLOW.spawn_door_reward_texts(self, room_coord, door_reward, dust_reward)

func add_resource_floating_text(world_position: Vector2, popup_text: String, popup_color: Color) -> void:
	GAME_FLOOR_FLOW.add_resource_floating_text(self, world_position, popup_text, popup_color)

func advance_floating_resource_texts(delta: float) -> void:
	GAME_FLOOR_FLOW.advance_floating_resource_texts(self, delta)

func draw_floating_resource_texts() -> void:
	GAME_WORLD_RENDER_FLOW.draw_floating_resource_texts(self)
func launch_wave(entered_room: Vector2i) -> void:
	GAME_COMBAT_FLOW.launch_wave(self, entered_room)

func queue_wave_spawn(room_coord: Vector2i, wave_points: int, immediate: bool, spawn_order: int) -> void:
	GAME_COMBAT_FLOW.queue_wave_spawn(self, room_coord, wave_points, immediate, spawn_order)

func advance_pending_enemy_spawns(delta: float) -> void:
	GAME_COMBAT_FLOW.advance_pending_enemy_spawns(self, delta)

func advance_crystal_pressure(delta: float) -> void:
	GAME_COMBAT_FLOW.advance_crystal_pressure(self, delta)

func trigger_crystal_pressure() -> void:
	GAME_COMBAT_FLOW.trigger_crystal_pressure(self)

func queue_pressure_spawn(room_coord: Vector2i, count: int) -> void:
	GAME_COMBAT_FLOW.queue_pressure_spawn(self, room_coord, count)

func enemy_pack_size(enemy_type: String) -> int:
	return GAME_COMBAT_FLOW.enemy_pack_size(self, enemy_type)

func enemy_wave_point_cost(enemy_type: String) -> int:
	return GAME_COMBAT_FLOW.enemy_wave_point_cost(self, enemy_type)

func enemy_spawn_weight(enemy_type: String, pressure_spawn: bool = false) -> float:
	return GAME_COMBAT_FLOW.enemy_spawn_weight(self, enemy_type, pressure_spawn)

func weighted_enemy_type_choice(candidates: Array[String], pressure_spawn: bool = false) -> String:
	return GAME_COMBAT_FLOW.weighted_enemy_type_choice(self, candidates, pressure_spawn)

func build_enemy_spawn_plan(budget: int, pressure_spawn: bool = false) -> Array[String]:
	return GAME_COMBAT_FLOW.build_enemy_spawn_plan(self, budget, pressure_spawn)

func spawn_wave(room_coord: Vector2i, count: int) -> void:
	GAME_COMBAT_FLOW.spawn_wave(self, room_coord, count)

func spawn_wave_enemy(room_coord: Vector2i, enemy_type: String) -> void:
	GAME_COMBAT_FLOW.spawn_wave_enemy(self, room_coord, enemy_type)

func issue_enemy_steps(enemy: Variant, steps: Array) -> void:
	GAME_PATHING_FLOW.issue_enemy_steps(self, enemy, steps)

func enemy_move_plan_matches(enemy: Variant, target_room: Vector2i, target_position: Vector2) -> bool:
	return GAME_PATHING_FLOW.enemy_move_plan_matches(self, enemy, target_room, target_position)

func issue_hero_steps(hero: Variant, steps: Array) -> void:
	GAME_PATHING_FLOW.issue_hero_steps(self, hero, steps)

func active_hero_room_for_commands(hero: Variant) -> Vector2i:
	return GAME_PATHING_FLOW.active_hero_room_for_commands(self, hero)

func interrupt_hero_orders(hero: Variant) -> Vector2i:
	return GAME_PATHING_FLOW.interrupt_hero_orders(self, hero)

func hero_has_locked_player_command(hero: Variant) -> bool:
	return GAME_PATHING_FLOW.hero_has_locked_player_command(self, hero)

func release_finished_player_command(hero: Variant) -> void:
	GAME_PATHING_FLOW.release_finished_player_command(self, hero)

func pause_autonomous_heroes_for_hand_drag() -> void:
	GAME_PATHING_FLOW.pause_autonomous_heroes_for_hand_drag(self)

func make_hero_step(room_coord: Vector2i, world_position: Vector2) -> Dictionary:
	return GAME_PATHING_FLOW.make_hero_step(self, room_coord, world_position)

func room_nav_fallback_points(room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> Array:
	return GAME_PATHING_FLOW.room_nav_fallback_points(self, room_coord, start_position, target_position)

func room_nav_data(room_coord: Vector2i) -> Dictionary:
	return GAME_PATHING_FLOW.room_nav_data(self, room_coord)

func room_nav_cell_rect(nav_data: Dictionary, local_cell: Vector2i) -> Rect2:
	return GAME_PATHING_FLOW.room_nav_cell_rect(self, nav_data, local_cell)

func room_nav_local_cell_for_world(nav_data: Dictionary, world_position: Vector2) -> Vector2i:
	return GAME_PATHING_FLOW.room_nav_local_cell_for_world(self, nav_data, world_position)

func room_nav_is_local_cell_in_bounds(nav_data: Dictionary, local_cell: Vector2i) -> bool:
	return GAME_PATHING_FLOW.room_nav_is_local_cell_in_bounds(self, nav_data, local_cell)

func nearest_walkable_room_nav_cell(nav_data: Dictionary, world_position: Vector2) -> Vector2i:
	return GAME_PATHING_FLOW.nearest_walkable_room_nav_cell(self, nav_data, world_position)

func room_nav_point_for_cell(nav_data: Dictionary, local_cell: Vector2i, preferred_position: Vector2) -> Vector2:
	return GAME_PATHING_FLOW.room_nav_point_for_cell(self, nav_data, local_cell, preferred_position)

func room_nav_segment_is_walkable(room_coord: Vector2i, start_position: Vector2, end_position: Vector2) -> bool:
	return GAME_PATHING_FLOW.room_nav_segment_is_walkable(self, room_coord, start_position, end_position)

func smooth_room_navigation_points(room_coord: Vector2i, points: Array) -> Array:
	return GAME_PATHING_FLOW.smooth_room_navigation_points(self, room_coord, points)

func simplify_room_navigation_points(points: Array) -> Array:
	return GAME_PATHING_FLOW.simplify_room_navigation_points(self, points)

func room_navigation_points(room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> Array:
	return GAME_PATHING_FLOW.room_navigation_points(self, room_coord, start_position, target_position)

func append_room_navigation_steps(steps: Array, room_coord: Vector2i, start_position: Vector2, target_position: Vector2) -> void:
	GAME_PATHING_FLOW.append_room_navigation_steps(self, steps, room_coord, start_position, target_position)

func build_steps_for_path(path: Array[Vector2i], start_position: Vector2, final_position: Vector2) -> Array:
	return GAME_PATHING_FLOW.build_steps_for_path(self, path, start_position, final_position)

func advance_hero_movement() -> void:
	GAME_PATHING_FLOW.advance_hero_movement(self)

func advance_enemy_routes(delta: float) -> void:
	GAME_ENEMY_AI_FLOW.advance_enemy_routes(self, delta)

func target_room_for_enemy(enemy: Variant) -> Vector2i:
	return GAME_ENEMY_AI_FLOW.target_room_for_enemy(self, enemy)

func enemy_room_goal_position(enemy: Variant, room_coord: Vector2i) -> Vector2:
	return GAME_ENEMY_AI_FLOW.enemy_room_goal_position(self, enemy, room_coord)

func enemy_target_position(enemy: Variant) -> Vector2:
	return GAME_ENEMY_AI_FLOW.enemy_target_position(self, enemy)

func enemy_attack_start_distance(enemy: Variant) -> float:
	return GAME_ENEMY_AI_FLOW.enemy_attack_start_distance(self, enemy)

func melee_attack_resolution_distance(attacker: Variant, target: Variant) -> float:
	return GAME_ENEMY_AI_FLOW.melee_attack_resolution_distance(self, attacker, target)

func hero_room_for_enemy_targeting(hero: Variant) -> Vector2i:
	return GAME_ENEMY_AI_FLOW.hero_room_for_enemy_targeting(self, hero)

func hero_is_in_room(hero: Variant, room_coord: Vector2i) -> bool:
	return GAME_ENEMY_AI_FLOW.hero_is_in_room(self, hero, room_coord)

func hero_is_long_range_target(hero: Variant) -> bool:
	return GAME_ENEMY_AI_FLOW.hero_is_long_range_target(self, hero)

func hero_target_priority_rank(hero: Variant) -> int:
	return GAME_ENEMY_AI_FLOW.hero_target_priority_rank(self, hero)

func orc_rider_target_priority_rank(hero: Variant) -> int:
	return GAME_ENEMY_AI_FLOW.orc_rider_target_priority_rank(self, hero)

func room_path_distance(from_room: Vector2i, to_room: Vector2i) -> int:
	return GAME_PATHING_FLOW.room_path_distance(self, from_room, to_room)

func heroes_in_room(room_coord: Vector2i) -> Array:
	return GAME_ENEMY_AI_FLOW.heroes_in_room(self, room_coord)

func default_room_hero_target(room_coord: Vector2i, origin: Vector2) -> Variant:
	return GAME_ENEMY_AI_FLOW.default_room_hero_target(self, room_coord, origin)

func enemy_room_hero_candidates(enemy: Variant) -> Array:
	return GAME_ENEMY_AI_FLOW.enemy_room_hero_candidates(self, enemy)

func local_enemy_override_target(enemy: Variant) -> Variant:
	return GAME_ENEMY_AI_FLOW.local_enemy_override_target(self, enemy)

func priority_hunter_target_hero(enemy: Variant) -> Variant:
	return GAME_ENEMY_AI_FLOW.priority_hunter_target_hero(self, enemy)

func orc_rider_target_hero(enemy: Variant) -> Variant:
	return GAME_ENEMY_AI_FLOW.orc_rider_target_hero(self, enemy)

func goblin_target_hero(enemy: Variant) -> Variant:
	return GAME_ENEMY_AI_FLOW.goblin_target_hero(self, enemy)

func bat_target_hero(enemy: Variant) -> Variant:
	return GAME_ENEMY_AI_FLOW.bat_target_hero(self, enemy)

func golem_target_hero(enemy: Variant) -> Variant:
	return GAME_ENEMY_AI_FLOW.golem_target_hero(self, enemy)

func enemy_situational_speed_multiplier(enemy: Variant) -> float:
	return GAME_ENEMY_AI_FLOW.enemy_situational_speed_multiplier(self, enemy)

func skeleton_archer_target_hero(enemy: Variant) -> Variant:
	return GAME_ENEMY_AI_FLOW.skeleton_archer_target_hero(self, enemy)

func skeleton_archer_goal_position(enemy: Variant) -> Vector2:
	return GAME_ENEMY_AI_FLOW.skeleton_archer_goal_position(self, enemy)

func module_target_position(room_coord: Vector2i, origin: Vector2) -> Vector2:
	return GAME_ENEMY_AI_FLOW.module_target_position(self, room_coord, origin)

func major_module_target_position(room_coord: Vector2i) -> Vector2:
	return GAME_ENEMY_AI_FLOW.major_module_target_position(self, room_coord)

func preferred_golem_major_module_room(enemy: Variant) -> Vector2i:
	return GAME_ENEMY_AI_FLOW.preferred_golem_major_module_room(self, enemy)

func resolve_enemy_attack(enemy: Variant) -> void:
	GAME_ENEMY_AI_FLOW.resolve_enemy_attack(self, enemy)

func find_nearest_major_module_room(from_room: Vector2i) -> Vector2i:
	return GAME_ENEMY_AI_FLOW.find_nearest_major_module_room(self, from_room)

func damage_module(room_coord: Vector2i, amount: float, major_only: bool = false, attacker_label: String = "Enemies") -> bool:
	return GAME_ENEMY_AI_FLOW.damage_module(self, room_coord, amount, major_only, attacker_label)

func send_hero_back_to_crystal(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	clear_pending_room_loot_request(hero.hero_index)
	clear_pending_room_action_request(hero.hero_index)
	if crystal_holder == hero:
		drop_crystal(hero.current_room)
	hero.restore_health()
	hero.move_steps.clear()
	hero.pending_room = HERO_INVALID_ROOM
	hero.pending_open_room = HERO_INVALID_ROOM
	hero.pending_open_origin_room = HERO_INVALID_ROOM
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
	return GAME_CARD_ACTIONS.projected_hero_damage_after_barrier(self, hero, amount)

func hero_hand_card_index(hero: Variant, card_uid: int) -> int:
	return GAME_CARD_ACTIONS.hero_hand_card_index(self, hero, card_uid)

func hero_hand_card_index_by_id(hero: Variant, card_id: String) -> int:
	return GAME_CARD_ACTIONS.hero_hand_card_index_by_id(self, hero, card_id)

func card_supports_reaction(hand_card: Dictionary) -> bool:
	return GAME_CARD_ACTIONS.card_supports_reaction(self, hand_card)

func play_reaction_card_for_hero_at_index(hero: Variant, hand_index: int) -> bool:
	return GAME_CARD_ACTIONS.play_reaction_card_for_hero_at_index(self, hero, hand_index)

func trigger_first_reaction_card(hero: Variant, trigger_id: String) -> bool:
	return GAME_CARD_ACTIONS.trigger_first_reaction_card(self, hero, trigger_id)

func spend_hero_stamina_with_reactions(hero: Variant, amount: float) -> bool:
	return GAME_CARD_ACTIONS.spend_hero_stamina_with_reactions(self, hero, amount)

func commit_hand_state(hero_index: int, hand_state: Array) -> void:
	GAME_CARD_ACTIONS.commit_hand_state(self, hero_index, hand_state)

func serialized_hand_state(hero: Variant) -> Array:
	return GAME_CARD_ACTIONS.serialized_hand_state(self, hero)

func toggle_hand_card_reaction(hero: Variant, hand_index: int) -> bool:
	return GAME_CARD_ACTIONS.toggle_hand_card_reaction(self, hero, hand_index)

func move_hand_card(hero: Variant, from_index: int, insertion_index: int) -> bool:
	return GAME_CARD_ACTIONS.move_hand_card(self, hero, from_index, insertion_index)

func hand_card_by_uid(hero: Variant, card_uid: int) -> Dictionary:
	return GAME_CARD_ACTIONS.hand_card_by_uid(self, hero, card_uid)

func hero_at_world_position(world_position: Vector2, controllable_only: bool = false) -> Variant:
	return GAME_CARD_ACTIONS.hero_at_world_position(self, world_position, controllable_only)

func room_target_at_world_position(world_position: Vector2, preferred_from_room: Vector2i = INVALID_ROOM) -> Vector2i:
	return GAME_CARD_ACTIONS.room_target_at_world_position(self, world_position, preferred_from_room)

func resolve_card_target(hero: Variant, hand_card: Dictionary, target_world_position: Vector2) -> Dictionary:
	return GAME_CARD_ACTIONS.resolve_card_target(self, hero, hand_card, target_world_position)

func card_cast_candidate_rooms(target_room: Vector2i, hand_card: Dictionary) -> Array[Vector2i]:
	return GAME_CARD_ACTIONS.card_cast_candidate_rooms(self, target_room, hand_card)

func room_has_neighbor(room_coord: Vector2i, neighbor: Vector2i) -> bool:
	return GAME_CARD_ACTIONS.room_has_neighbor(self, room_coord, neighbor)

func room_interior_rect(room_coord: Vector2i, margin: float = 24.0) -> Rect2:
	return GAME_CARD_ACTIONS.room_interior_rect(self, room_coord, margin)

func cross_room_card_cast_staging_position(cast_room: Vector2i, target_room: Vector2i, target_world_position: Vector2) -> Vector2:
	return GAME_CARD_ACTIONS.cross_room_card_cast_staging_position(self, cast_room, target_room, target_world_position)

func card_cast_staging_position(cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2 = Vector2.INF) -> Vector2:
	return GAME_CARD_ACTIONS.card_cast_staging_position(self, cast_room, target_room, hand_card, target_world_position)

func card_cast_has_line_of_effect(cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2) -> bool:
	return GAME_CARD_ACTIONS.card_cast_has_line_of_effect(self, cast_room, target_room, hand_card, target_world_position)

func hero_ready_for_card_cast(hero: Variant, cast_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2 = Vector2.INF) -> bool:
	return GAME_CARD_ACTIONS.hero_ready_for_card_cast(self, hero, cast_room, target_room, hand_card, target_world_position)

func best_card_cast_room(from_room: Vector2i, target_room: Vector2i, hand_card: Dictionary, target_world_position: Vector2) -> Vector2i:
	return GAME_CARD_ACTIONS.best_card_cast_room(self, from_room, target_room, hand_card, target_world_position)

func card_target_is_valid(hero: Variant, hand_card: Dictionary, target_world_position: Vector2) -> bool:
	return GAME_CARD_ACTIONS.card_target_is_valid(self, hero, hand_card, target_world_position)

func hand_card_starts_spell_study(hero: Variant, hand_card: Dictionary, target_data: Dictionary) -> bool:
	return GAME_CARD_ACTIONS.hand_card_starts_spell_study(self, hero, hand_card, target_data)

func hand_card_phase_allows_play(hand_card: Dictionary) -> bool:
	return GAME_CARD_ACTIONS.hand_card_phase_allows_play(self, hand_card)

func apply_hand_card_effect(hero: Variant, hand_card: Dictionary, target_data: Dictionary) -> bool:
	return GAME_CARD_ACTIONS.apply_hand_card_effect(self, hero, hand_card, target_data)

func finalize_played_hand_card_source(hand_card: Dictionary) -> void:
	GAME_CARD_ACTIONS.finalize_played_hand_card_source(self, hand_card)

func play_card_for_hero(hero_index: int, card_uid: int, target_world_position: Vector2) -> bool:
	return GAME_CARD_ACTIONS.play_card_for_hero(self, hero_index, card_uid, target_world_position)

func cast_fireball_spell(hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	GAME_CARD_ACTIONS.cast_fireball_spell(self, hero, target_world_position, target_room, hand_card)

func nearest_enemies_in_room(room_coord: Vector2i, origin: Vector2, max_count: int) -> Array:
	return GAME_CARD_ACTIONS.nearest_enemies_in_room(self, room_coord, origin, max_count)

func cast_magic_missile_spell(hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	GAME_CARD_ACTIONS.cast_magic_missile_spell(self, hero, target_world_position, target_room, hand_card)

func cast_misty_step_spell(hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	GAME_CARD_ACTIONS.cast_misty_step_spell(self, hero, target_world_position, target_room, hand_card)

func cast_shield_spell(hero: Variant, hand_card: Dictionary) -> void:
	GAME_CARD_ACTIONS.cast_shield_spell(self, hero, hand_card)

func try_auto_cast_fatal_shield(hero: Variant, incoming_damage: float) -> bool:
	return GAME_CARD_ACTIONS.try_auto_cast_fatal_shield(self, hero, incoming_damage)

func cast_lightning_bolt_spell(hero: Variant, target_world_position: Vector2, target_room: Vector2i, hand_card: Dictionary) -> void:
	GAME_CARD_ACTIONS.cast_lightning_bolt_spell(self, hero, target_world_position, target_room, hand_card)

func explode_fireball_projectile(projectile: Dictionary) -> void:
	GAME_CARD_ACTIONS.explode_fireball_projectile(self, projectile)

func explode_enemy_fireball(room_coord: Vector2i, target_position: Vector2, damage: float, impact_radius: float, push_force: float, source_label: String) -> Array[String]:
	return GAME_CARD_ACTIONS.explode_enemy_fireball(self, room_coord, target_position, damage, impact_radius, push_force, source_label)

func spawn_axe_card_projectile(hero: Variant, target_world_position: Vector2, hand_card: Dictionary) -> void:
	GAME_CARD_ACTIONS.spawn_axe_card_projectile(self, hero, target_world_position, hand_card)

func spawn_dagger_card_projectiles(hero: Variant, target_world_position: Vector2, hand_card: Dictionary) -> void:
	GAME_CARD_ACTIONS.spawn_dagger_card_projectiles(self, hero, target_world_position, hand_card)

func enemy_forward_direction(enemy: Variant) -> Vector2:
	return GAME_ACTOR_COMBAT_FLOW.enemy_forward_direction(self, enemy)

func enemy_is_active(enemy: Variant) -> bool:
	return GAME_ACTOR_COMBAT_FLOW.enemy_is_active(self, enemy)

func actor_weight(actor: Variant) -> float:
	return GAME_ACTOR_COMBAT_FLOW.actor_weight(self, actor)

func find_enemy_by_uid(enemy_uid: int) -> Variant:
	return GAME_ACTOR_COMBAT_FLOW.find_enemy_by_uid(self, enemy_uid)

func find_hero_by_index(hero_index: int) -> Variant:
	return GAME_ACTOR_COMBAT_FLOW.find_hero_by_index(self, hero_index)

func knockback_actor(actor: Variant, direction: Vector2, impulse_strength: float, recovery_duration: float, room_coord: Vector2i) -> void:
	GAME_ACTOR_COMBAT_FLOW.knockback_actor(self, actor, direction, impulse_strength, recovery_duration, room_coord)

func apply_weighted_melee_knockback(attacker: Variant, defender: Variant, room_coord: Vector2i, base_force: float = 0.0) -> void:
	GAME_ACTOR_COMBAT_FLOW.apply_weighted_melee_knockback(self, attacker, defender, room_coord, base_force)

func attacker_pending_melee_key(attacker: Variant) -> String:
	return GAME_ACTOR_COMBAT_FLOW.attacker_pending_melee_key(self, attacker)

func attacker_has_pending_melee(attacker: Variant) -> bool:
	return GAME_ACTOR_COMBAT_FLOW.attacker_has_pending_melee(self, attacker)

func queue_pending_melee_attack(attacker: Variant, target: Variant, damage: float, windup: float, source_label: String) -> void:
	GAME_ACTOR_COMBAT_FLOW.queue_pending_melee_attack(self, attacker, target, damage, windup, source_label)

func finalize_hero_death(hero: Variant, source_label: String) -> void:
	GAME_ACTOR_COMBAT_FLOW.finalize_hero_death(self, hero, source_label)

func advance_pending_melee_attacks(delta: float) -> void:
	GAME_ACTOR_COMBAT_FLOW.advance_pending_melee_attacks(self, delta)

func apply_card_projectile_hits(projectile: Dictionary) -> void:
	GAME_COMBAT_FLOW.apply_card_projectile_hits(self, projectile)

func process_combat(_delta: float) -> void:
	GAME_COMBAT_FLOW.process_combat(self, _delta)

func process_modules(delta: float) -> void:
	GAME_COMBAT_FLOW.process_modules(self, delta)

func spawn_arrow_projectile(origin: Vector2, target: Variant, damage: float, color: Color = Color("d8bf7a"), width: float = 2.4, speed: float = PROJECTILE_SPEED) -> void:
	GAME_COMBAT_FLOW.spawn_arrow_projectile(self, origin, target, damage, color, width, speed)

func spawn_laser_projectile(origin: Vector2, target: Variant, damage: float, color: Color = Color("89f2ff"), width: float = 4.0, speed: float = PROJECTILE_SPEED) -> void:
	GAME_COMBAT_FLOW.spawn_laser_projectile(self, origin, target, damage, color, width, speed)

func advance_projectiles(delta: float) -> void:
	GAME_COMBAT_FLOW.advance_projectiles(self, delta)

func draw_projectiles() -> void:
	GAME_COMBAT_FLOW.draw_projectiles(self)

func nearest_enemy_in_room(room_coord: Vector2i, origin: Vector2, max_range: float) -> Variant:
	return GAME_COMBAT_FLOW.nearest_enemy_in_room(self, room_coord, origin, max_range)

func strongest_enemy_in_room(room_coord: Vector2i, origin: Vector2, max_range: float) -> Variant:
	return GAME_COMBAT_FLOW.strongest_enemy_in_room(self, room_coord, origin, max_range)

func cleanup_enemies() -> void:
	GAME_COMBAT_FLOW.cleanup_enemies(self)

func peer_can_control_hero(peer_id: int, hero_index: int) -> bool:
	return GAME_NETWORK_SYNC.peer_can_control_hero(self, peer_id, hero_index)

func maybe_broadcast_network_snapshot(delta: float) -> void:
	GAME_NETWORK_SYNC.maybe_broadcast_network_snapshot(self, delta)

func broadcast_network_snapshot() -> void:
	GAME_NETWORK_SYNC.broadcast_network_snapshot(self)

func build_network_snapshot() -> Dictionary:
	return GAME_NETWORK_SYNC.build_network_snapshot(self)

@rpc("authority", "call_remote", "reliable")
func receive_network_snapshot(snapshot: Dictionary) -> void:
	GAME_NETWORK_SYNC.receive_network_snapshot(self, snapshot)

func apply_network_snapshot(snapshot: Dictionary) -> void:
	GAME_NETWORK_SYNC.apply_network_snapshot(self, snapshot)

func process_client_pending_local_requests() -> void:
	GAME_NETWORK_SYNC.process_client_pending_local_requests(self)

func apply_hero_snapshots(hero_states: Array) -> void:
	GAME_NETWORK_SYNC.apply_hero_snapshots(self, hero_states)

func apply_enemy_snapshots(enemy_states: Array) -> void:
	GAME_NETWORK_SYNC.apply_enemy_snapshots(self, enemy_states)

@rpc("any_peer", "call_remote", "reliable")
func server_request_world_command(hero_index: int, world_position: Vector2) -> void:
	GAME_NETWORK_SYNC.server_request_world_command(self, hero_index, world_position)

@rpc("any_peer", "call_remote", "reliable")
func server_request_room_loot(hero_index: int, room_coord: Vector2i) -> void:
	GAME_NETWORK_SYNC.server_request_room_loot(self, hero_index, room_coord)

@rpc("any_peer", "call_remote", "reliable")
func server_request_room_light(hero_index: int, room_coord: Vector2i) -> void:
	GAME_NETWORK_SYNC.server_request_room_light(self, hero_index, room_coord)

@rpc("any_peer", "call_remote", "reliable")
func server_request_room_construction(hero_index: int, room_coord: Vector2i, module_type: String) -> void:
	GAME_NETWORK_SYNC.server_request_room_construction(self, hero_index, room_coord, module_type)

@rpc("any_peer", "call_remote", "reliable")
func server_request_hero_class(hero_index: int, class_id: String) -> void:
	GAME_NETWORK_SYNC.server_request_hero_class(self, hero_index, class_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_lobby_ready(ready: bool) -> void:
	GAME_NETWORK_SYNC.server_request_lobby_ready(self, ready)

@rpc("any_peer", "call_remote", "reliable")
func server_request_play_card(hero_index: int, card_uid: int, target_world_position: Vector2) -> void:
	GAME_NETWORK_SYNC.server_request_play_card(self, hero_index, card_uid, target_world_position)

@rpc("any_peer", "call_remote", "reliable")
func server_request_pick_up_crystal(hero_index: int) -> void:
	GAME_NETWORK_SYNC.server_request_pick_up_crystal(self, hero_index)

@rpc("any_peer", "call_remote", "reliable")
func server_request_exit_floor(hero_index: int) -> void:
	GAME_NETWORK_SYNC.server_request_exit_floor(self, hero_index)

@rpc("any_peer", "call_remote", "reliable")
func server_request_set_stamina_use_enabled(enabled: bool) -> void:
	GAME_NETWORK_SYNC.server_request_set_stamina_use_enabled(self, enabled)

func assign_multiplayer_hero_owners_after_floor_transition() -> void:
	GAME_NETWORK_SYNC.assign_multiplayer_hero_owners_after_floor_transition(self)

@rpc("any_peer", "call_remote", "reliable")
func server_commit_inventory_state(hero_index: int, room_coord: Vector2i, items: Array, ground_items: Array) -> void:
	GAME_NETWORK_SYNC.server_commit_inventory_state(self, hero_index, room_coord, items, ground_items)

@rpc("any_peer", "call_remote", "reliable")
func server_commit_pack_layout(hero_index: int, pack_modules: Array) -> void:
	GAME_NETWORK_SYNC.server_commit_pack_layout(self, hero_index, pack_modules)

@rpc("any_peer", "call_remote", "reliable")
func server_commit_spell_slots(hero_index: int, slotted_spells: Array) -> void:
	GAME_NETWORK_SYNC.server_commit_spell_slots(self, hero_index, slotted_spells)

@rpc("any_peer", "call_remote", "reliable")
func server_commit_hand_state(hero_index: int, hand_state: Array) -> void:
	GAME_NETWORK_SYNC.server_commit_hand_state(self, hero_index, hand_state)

@rpc("any_peer", "call_remote", "reliable")
func server_request_inventory_level_up(hero_index: int) -> void:
	GAME_NETWORK_SYNC.server_request_inventory_level_up(self, hero_index)

@rpc("any_peer", "call_remote", "reliable")
func server_request_inventory_drop(hero_index: int, item: Dictionary) -> void:
	GAME_NETWORK_SYNC.server_request_inventory_drop(self, hero_index, item)

func find_path(from_room: Vector2i, to_room: Vector2i, only_open_rooms: bool) -> Array[Vector2i]:
	return GAME_DUNGEON_BUILDER.find_path(self, from_room, to_room, only_open_rooms)

func room_at_world_position(world_position: Vector2) -> Vector2i:
	return GAME_DUNGEON_BUILDER.room_at_world_position(self, world_position)

func corridor_room_target_at_position(world_position: Vector2, preferred_from_room: Vector2i = INVALID_ROOM) -> Vector2i:
	return GAME_DUNGEON_BUILDER.corridor_room_target_at_position(self, world_position, preferred_from_room)

func open_corridor_target_for_pair(world_position: Vector2, room_a: Vector2i, room_b: Vector2i, preferred_from_room: Vector2i = INVALID_ROOM) -> Dictionary:
	return GAME_DUNGEON_BUILDER.open_corridor_target_for_pair(self, world_position, room_a, room_b, preferred_from_room)

func room_is_revealed(room_coord: Vector2i) -> bool:
	return GAME_DUNGEON_BUILDER.room_is_revealed(self, room_coord)

func frontier_target_at_position(world_position: Vector2) -> Dictionary:
	return GAME_DUNGEON_BUILDER.frontier_target_at_position(self, world_position)

func frontier_wall_target_at_position(world_position: Vector2) -> Dictionary:
	return GAME_DUNGEON_BUILDER.frontier_wall_target_at_position(self, world_position)

func frontier_door_at_position(world_position: Vector2) -> Dictionary:
	return GAME_DUNGEON_BUILDER.frontier_door_at_position(self, world_position)

func point_distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	return GAME_DUNGEON_BUILDER.point_distance_to_segment(self, point, start, end)

func hidden_room_entry_zone_contains(world_position: Vector2, from_room: Vector2i, to_room: Vector2i) -> bool:
	return GAME_DUNGEON_BUILDER.hidden_room_entry_zone_contains(self, world_position, from_room, to_room)

func room_center(room_coord: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.room_center(self, room_coord)

func room_size_for(room_coord: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.room_size_for(self, room_coord)

func room_rect(room_coord: Vector2i) -> Rect2:
	return GAME_DUNGEON_BUILDER.room_rect(self, room_coord)

func normalized_rect_to_room(room_coord: Vector2i, normalized_rect: Rect2) -> Rect2:
	return GAME_DUNGEON_BUILDER.normalized_rect_to_room(self, room_coord, normalized_rect)

func normalized_point_to_room(room_coord: Vector2i, normalized_point: Vector2) -> Vector2:
	return GAME_DUNGEON_BUILDER.normalized_point_to_room(self, room_coord, normalized_point)

func room_layout_regions(room_coord: Vector2i, key: String, inset: float = 0.0) -> Array:
	return GAME_DUNGEON_BUILDER.room_layout_regions(self, room_coord, key, inset)

func room_walkable_regions(room_coord: Vector2i, inset: float = ROOM_WALKABLE_INSET) -> Array:
	return GAME_DUNGEON_BUILDER.room_walkable_regions(self, room_coord, inset)

func room_slot_regions(room_coord: Vector2i, inset: float = ROOM_SLOT_INSET) -> Array:
	return GAME_DUNGEON_BUILDER.room_slot_regions(self, room_coord, inset)

func largest_region_rect(regions: Array) -> Rect2:
	return GAME_DUNGEON_BUILDER.largest_region_rect(self, regions)

func bounding_rect_for_regions(regions: Array) -> Rect2:
	return GAME_DUNGEON_BUILDER.bounding_rect_for_regions(self, regions)

func room_slot_anchor_rect(room_coord: Vector2i) -> Rect2:
	return GAME_DUNGEON_BUILDER.room_slot_anchor_rect(self, room_coord)

func closest_point_in_rect(world_position: Vector2, rect: Rect2) -> Vector2:
	return GAME_DUNGEON_BUILDER.closest_point_in_rect(self, world_position, rect)

func room_walkable_contains_point(room_coord: Vector2i, world_position: Vector2, inset: float = ROOM_WALKABLE_INSET) -> bool:
	return GAME_DUNGEON_BUILDER.room_walkable_contains_point(self, room_coord, world_position, inset)

func room_walkable_center(room_coord: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.room_walkable_center(self, room_coord)

func doorway_navigation_position(from_room: Vector2i, to_room: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.doorway_navigation_position(self, from_room, to_room)

func random_point_in_regions(regions: Array) -> Vector2:
	return GAME_DUNGEON_BUILDER.random_point_in_regions(self, regions)

func random_walkable_point(room_coord: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.random_walkable_point(self, room_coord)

func walkable_region_index_for_point(room_coord: Vector2i, world_position: Vector2, inset: float = ROOM_WALKABLE_INSET) -> int:
	return GAME_DUNGEON_BUILDER.walkable_region_index_for_point(self, room_coord, world_position, inset)

func clear_enemy_room_navigation(enemy: Variant) -> void:
	GAME_DUNGEON_BUILDER.clear_enemy_room_navigation(self, enemy)

func enemy_room_navigation_destination(enemy: Variant, room_coord: Vector2i, target_position: Vector2) -> Vector2:
	return GAME_DUNGEON_BUILDER.enemy_room_navigation_destination(self, enemy, room_coord, target_position)

func clamp_point_to_room(world_position: Vector2, room_coord: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.clamp_point_to_room(self, world_position, room_coord)

func doorway_position(from_room: Vector2i, to_room: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.doorway_position(self, from_room, to_room)

func major_slot_position(room_coord: Vector2i) -> Vector2:
	return GAME_DUNGEON_BUILDER.major_slot_position(self, room_coord)

func effective_minor_slot_count(room_coord: Vector2i) -> int:
	return GAME_DUNGEON_BUILDER.effective_minor_slot_count(self, room_coord)

func minor_slot_positions(room_coord: Vector2i) -> Array:
	return GAME_DUNGEON_BUILDER.minor_slot_positions(self, room_coord)

func minor_module_index_for_slot(room_coord: Vector2i, slot_index: int) -> int:
	return GAME_CONSTRUCTION_FLOW.minor_module_index_for_slot(self, room_coord, slot_index)

func minor_slot_at_position(room_coord: Vector2i, world_position: Vector2) -> int:
	return GAME_CONSTRUCTION_FLOW.minor_slot_at_position(self, room_coord, world_position)
func draw_room_door_marker(room_coord: Vector2i, neighbor: Vector2i, accessible: bool) -> void:
	GAME_WORLD_RENDER_FLOW.draw_room_door_marker(self, room_coord, neighbor, accessible)

func major_slot_contains_point(room_coord: Vector2i, world_position: Vector2) -> bool:
	return GAME_CONSTRUCTION_FLOW.major_slot_contains_point(self, room_coord, world_position)

func pending_minor_construction_for_slot(room_coord: Vector2i, slot_index: int) -> Dictionary:
	return GAME_CONSTRUCTION_FLOW.pending_minor_construction_for_slot(self, room_coord, slot_index)

func pending_major_construction_for_room(room_coord: Vector2i) -> Dictionary:
	return GAME_CONSTRUCTION_FLOW.pending_major_construction_for_room(self, room_coord)

func cancel_pending_minor_construction(room_coord: Vector2i, slot_index: int) -> void:
	GAME_CONSTRUCTION_FLOW.cancel_pending_minor_construction(self, room_coord, slot_index)

func cancel_pending_major_construction(room_coord: Vector2i) -> void:
	GAME_CONSTRUCTION_FLOW.cancel_pending_major_construction(self, room_coord)

func should_highlight_minor_slot(room_coord: Vector2i, slot_index: int) -> bool:
	return GAME_CONSTRUCTION_FLOW.should_highlight_minor_slot(self, room_coord, slot_index)

func should_highlight_major_slot(room_coord: Vector2i) -> bool:
	return GAME_CONSTRUCTION_FLOW.should_highlight_major_slot(self, room_coord)

func should_show_room_slot_guides(room_coord: Vector2i) -> bool:
	return GAME_CONSTRUCTION_FLOW.should_show_room_slot_guides(self, room_coord)

func room_theme_palette(theme_id: String, lit: bool, crystal_chamber: bool) -> Dictionary:
	return GAME_WORLD_RENDER_FLOW.room_theme_palette(self, theme_id, lit, crystal_chamber)

func draw_room_overlays() -> void:
	GAME_WORLD_RENDER_FLOW.draw_room_overlays(self)
func draw_room_action_hold() -> void:
	GAME_ROOM_ACTION_MENU.draw_room_action_hold(self)

func draw_room_action_menu() -> void:
	GAME_ROOM_ACTION_MENU.draw_room_action_menu(self)

func room_title(room_coord: Vector2i) -> String:
	return GAME_WORLD_RENDER_FLOW.room_title(self, room_coord)

func room_summary(room_coord: Vector2i) -> String:
	return GAME_WORLD_RENDER_FLOW.room_summary(self, room_coord)

func can_toggle_light(room_coord: Vector2i) -> bool:
	return GAME_WORLD_RENDER_FLOW.can_toggle_light(self, room_coord)

func can_manage_modules(room_coord: Vector2i) -> bool:
	return GAME_WORLD_RENDER_FLOW.can_manage_modules(self, room_coord)

func can_open_build_for_room(room_coord: Vector2i) -> bool:
	return GAME_WORLD_RENDER_FLOW.can_open_build_for_room(self, room_coord)

func toggle_room_light(room_coord: Vector2i) -> void:
	GAME_WORLD_RENDER_FLOW.toggle_room_light(self, room_coord)

func ensure_room_lit_for_build(room_coord: Vector2i) -> bool:
	return GAME_WORLD_RENDER_FLOW.ensure_room_lit_for_build(self, room_coord)

func advance_wave_recovery(delta: float) -> void:
	GAME_FLOOR_FLOW.advance_wave_recovery(self, delta)

func update_hud() -> void:
	GAME_HUD_FLOW.update_hud(self)
func refresh_open_inventory_overlay() -> void:
	GAME_INVENTORY_OVERLAY_FLOW.refresh_open_inventory_overlay(self)

func selected_calm_speed_multiplier() -> float:
	return GAME_HUD_FLOW.selected_calm_speed_multiplier(self)

func apply_calm_speed_multiplier_to_heroes() -> void:
	GAME_HUD_FLOW.apply_calm_speed_multiplier_to_heroes(self)

func update_calm_speed_bar(calm_phase: bool) -> void:
	GAME_HUD_FLOW.update_calm_speed_bar(self, calm_phase)

func _on_calm_speed_button_pressed(option_index: int) -> void:
	GAME_HUD_FLOW._on_calm_speed_button_pressed(self, option_index)

func update_hero_button_text() -> void:
	GAME_HUD_FLOW.update_hero_button_text(self)

func update_runtime_button_state() -> void:
	GAME_HUD_FLOW.update_runtime_button_state(self)

func count_dark_open_rooms() -> int:
	return GAME_HUD_FLOW.count_dark_open_rooms(self)

func can_build_or_repair_turret(room_coord: Vector2i) -> bool:
	return GAME_CONSTRUCTION_FLOW.can_build_or_repair_turret(self, room_coord)

func any_room_can_build_or_repair_turret() -> bool:
	return GAME_CONSTRUCTION_FLOW.any_room_can_build_or_repair_turret(self)

func turret_button_text(room_coord: Vector2i) -> String:
	return GAME_CONSTRUCTION_FLOW.turret_button_text(self, room_coord)

func can_build_or_repair_major(room_coord: Vector2i, module_type: String) -> bool:
	return GAME_CONSTRUCTION_FLOW.can_build_or_repair_major(self, room_coord, module_type)

func any_room_can_build_or_repair_major(module_type: String) -> bool:
	return GAME_CONSTRUCTION_FLOW.any_room_can_build_or_repair_major(self, module_type)

func major_button_text(room_coord: Vector2i, module_type: String, label: String) -> String:
	return GAME_CONSTRUCTION_FLOW.major_button_text(self, room_coord, module_type, label)

func canonical_minor_module_type(module_type: String) -> String:
	return GAME_MODULE_DEFS.canonical_minor_module_type(module_type)

func minor_module_catalog() -> Array[String]:
	return GAME_MODULE_DEFS.minor_module_catalog()

func initialized_minor_module_levels() -> Dictionary:
	return GAME_MODULE_DEFS.initialized_minor_module_levels()

func initialized_major_module_levels() -> Dictionary:
	return GAME_MODULE_DEFS.initialized_major_module_levels()

func normalized_minor_module_levels(source: Dictionary) -> Dictionary:
	return GAME_MODULE_DEFS.normalized_minor_module_levels(source)

func normalized_major_module_levels(source: Dictionary) -> Dictionary:
	return GAME_MODULE_DEFS.normalized_major_module_levels(source)

func minor_module_level(module_type: String) -> int:
	return GAME_MODULE_DEFS.minor_module_level(module_type, minor_module_levels)

func major_module_level(module_type: String) -> int:
	return GAME_MODULE_DEFS.major_module_level(module_type, major_module_levels)

func minor_module_unlocked(module_type: String) -> bool:
	return GAME_MODULE_DEFS.minor_module_unlocked(module_type, minor_module_levels)

func research_display_name(module_type: String) -> String:
	return GAME_MODULE_DEFS.research_display_name(module_type)

func available_minor_module_build_types() -> Array[String]:
	return GAME_MODULE_DEFS.available_minor_module_build_types(minor_module_levels)

func module_level_roman(level: int) -> String:
	return GAME_MODULE_DEFS.module_level_roman(level)

func room_has_research_crystal(room_coord: Vector2i) -> bool:
	return GAME_RESEARCH_FLOW.room_has_research_crystal(self, room_coord)

func research_in_progress() -> bool:
	return GAME_RESEARCH_FLOW.research_in_progress(self)

func room_has_active_research(room_coord: Vector2i) -> bool:
	return GAME_RESEARCH_FLOW.room_has_active_research(self, room_coord)

func can_start_research_in_room(room_coord: Vector2i) -> bool:
	return GAME_RESEARCH_FLOW.can_start_research_in_room(self, room_coord)

func minor_module_action_id(module_type: String) -> String:
	return "build_minor_%s" % canonical_minor_module_type(module_type)

func minor_module_type_for_action(action_id: String) -> String:
	if not action_id.begins_with("build_minor_"):
		return ""
	return canonical_minor_module_type(action_id.trim_prefix("build_minor_"))

func available_minor_module_action_specs() -> Array:
	var specs: Array = []
	for module_type_variant in available_minor_module_build_types():
		var module_type: String = String(module_type_variant)
		specs.append({
			"id": minor_module_action_id(module_type),
			"label": build_type_label(module_type),
			"fill": minor_module_color(module_type),
		})
	return specs

func build_type_label(module_type: String) -> String:
	return GAME_MODULE_DEFS.build_type_label(module_type)

func is_minor_module_type(module_type: String) -> bool:
	return GAME_MODULE_DEFS.is_minor_module_type(module_type)

func is_major_module_type(module_type: String) -> bool:
	return GAME_MODULE_DEFS.is_major_module_type(module_type)

func minor_module_cost(module_type: String) -> int:
	return GAME_MODULE_DEFS.minor_module_cost(module_type)

func minor_module_damage(module_type: String) -> float:
	return GAME_MODULE_DEFS.minor_module_damage(module_type, minor_module_levels)

func minor_module_cooldown(module_type: String) -> float:
	return GAME_MODULE_DEFS.minor_module_cooldown(module_type, minor_module_levels)

func minor_module_color(module_type: String) -> Color:
	return GAME_MODULE_DEFS.minor_module_color(module_type)

func minor_module_projectile_width(module_type: String) -> float:
	return GAME_MODULE_DEFS.minor_module_projectile_width(module_type)

func minor_module_projectile_speed(module_type: String) -> float:
	return GAME_MODULE_DEFS.minor_module_projectile_speed(module_type, PROJECTILE_SPEED)

func wave_in_progress() -> bool:
	return not pending_enemy_spawns.is_empty() or not enemies.is_empty()

func update_hero_combat_movement_mode() -> void:
	var in_combat: bool = wave_in_progress()
	for hero in heroes:
		if is_instance_valid(hero):
			hero.set_combat_movement_mode(in_combat)

func room_has_pending_construction(room_coord: Vector2i) -> bool:
	return GAME_CONSTRUCTION_FLOW.room_has_pending_construction(self, room_coord)

func preferred_turret_slot(room_coord: Vector2i) -> int:
	return GAME_CONSTRUCTION_FLOW.preferred_turret_slot(self, room_coord)

func queue_room_construction(room_coord: Vector2i, module_type: String) -> bool:
	return GAME_CONSTRUCTION_FLOW.queue_room_construction(self, room_coord, module_type)

func advance_room_constructions(delta: float) -> void:
	GAME_CONSTRUCTION_FLOW.advance_room_constructions(self, delta)

func apply_construction_progress(construction: Dictionary) -> void:
	GAME_CONSTRUCTION_FLOW.apply_construction_progress(self, construction)

func finish_room_construction(construction: Dictionary) -> void:
	GAME_CONSTRUCTION_FLOW.finish_room_construction(self, construction)

func build_menu_title_text() -> String:
	return GAME_CONSTRUCTION_FLOW.build_menu_title_text(self)

func clear_build_mode() -> void:
	GAME_CONSTRUCTION_FLOW.clear_build_mode(self)

func select_build_mode(module_type: String) -> void:
	GAME_CONSTRUCTION_FLOW.select_build_mode(self, module_type)

func handle_build_tap(world_position: Vector2) -> bool:
	return GAME_CONSTRUCTION_FLOW.handle_build_tap(self, world_position)
func _on_research_choice_button_pressed(choice_index: int) -> void:
	GAME_RESEARCH_FLOW._on_research_choice_button_pressed(self, choice_index)

func _on_research_start_button_pressed() -> void:
	GAME_RESEARCH_FLOW._on_research_start_button_pressed(self)

func _on_research_reroll_button_pressed() -> void:
	GAME_RESEARCH_FLOW._on_research_reroll_button_pressed(self)

func _on_research_close_button_pressed() -> void:
	GAME_RESEARCH_FLOW._on_research_close_button_pressed(self)

func screen_to_world(screen_position: Vector2) -> Vector2:
	return GAME_WORLD_RENDER_FLOW.screen_to_world(self, screen_position)

func world_to_screen(world_position: Vector2) -> Vector2:
	return GAME_WORLD_RENDER_FLOW.world_to_screen(self, world_position)

func screen_rect_to_world_rect(screen_rect: Rect2) -> Rect2:
	return GAME_WORLD_RENDER_FLOW.screen_rect_to_world_rect(self, screen_rect)

func current_view_world_rect(padding: float = 0.0) -> Rect2:
	return GAME_WORLD_RENDER_FLOW.current_view_world_rect(self, padding)
func active_hand_returning_uids() -> Dictionary:
	return GAME_COMBAT_HAND_UI_FLOW.active_hand_returning_uids(self)

func selected_hand_hero() -> Variant:
	return GAME_COMBAT_HAND_UI_FLOW.selected_hand_hero(self)

func combat_hand_panel_rect(hero: Variant) -> Rect2:
	return GAME_COMBAT_HAND_UI_FLOW.combat_hand_panel_rect(self, hero)

func combat_hand_card_rect(hero: Variant, card_index: int) -> Rect2:
	return GAME_COMBAT_HAND_UI_FLOW.combat_hand_card_rect(self, hero, card_index)

func combat_hand_info_button_rect(hero: Variant) -> Rect2:
	return GAME_COMBAT_HAND_UI_FLOW.combat_hand_info_button_rect(self, hero)

func combat_hand_info_panel_rect(hero: Variant) -> Rect2:
	return GAME_COMBAT_HAND_UI_FLOW.combat_hand_info_panel_rect(self, hero)

func combat_hand_reaction_rect(hero: Variant, card_index: int) -> Rect2:
	return GAME_COMBAT_HAND_UI_FLOW.combat_hand_reaction_rect(self, hero, card_index)

func combat_hand_reaction_touch_rect(hero: Variant, card_index: int) -> Rect2:
	return GAME_COMBAT_HAND_UI_FLOW.combat_hand_reaction_touch_rect(self, hero, card_index)

func combat_hand_insertion_index(hero: Variant, screen_position: Vector2) -> int:
	return GAME_COMBAT_HAND_UI_FLOW.combat_hand_insertion_index(self, hero, screen_position)

func combat_hand_card_index_at_screen_position(hero: Variant, screen_position: Vector2) -> int:
	return GAME_COMBAT_HAND_UI_FLOW.combat_hand_card_index_at_screen_position(self, hero, screen_position)

func hand_card_footer_bits(hand_card: Dictionary) -> Array[String]:
	return GAME_COMBAT_HAND_UI_FLOW.hand_card_footer_bits(self, hand_card)

func open_hand_card_info(hero: Variant, hand_card: Dictionary) -> void:
	GAME_COMBAT_HAND_UI_FLOW.open_hand_card_info(self, hero, hand_card)

func clear_hand_card_info() -> void:
	GAME_COMBAT_HAND_UI_FLOW.clear_hand_card_info(self)

func dismiss_hand_card_info_if_outside(screen_position: Vector2) -> bool:
	return GAME_COMBAT_HAND_UI_FLOW.dismiss_hand_card_info_if_outside(self, screen_position)

func draw_hand_card(screen_rect: Rect2, hand_card: Dictionary, highlighted: bool, reaction_rect_screen: Rect2 = Rect2()) -> void:
	GAME_COMBAT_HAND_UI_FLOW.draw_hand_card(self, screen_rect, hand_card, highlighted, reaction_rect_screen)

func draw_hand_card_info_panel(hero: Variant) -> void:
	GAME_COMBAT_HAND_UI_FLOW.draw_hand_card_info_panel(self, hero)

func draw_combat_hand() -> void:
	GAME_COMBAT_HAND_UI_FLOW.draw_combat_hand(self)

func begin_hand_card_drag(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	return GAME_COMBAT_HAND_UI_FLOW.begin_hand_card_drag(self, pointer_kind, pointer_id, screen_position)

func update_hand_card_drag(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	return GAME_COMBAT_HAND_UI_FLOW.update_hand_card_drag(self, pointer_kind, pointer_id, screen_position)

func start_hand_card_return_animation(hand_card: Dictionary, from_rect: Rect2, to_rect: Rect2) -> void:
	GAME_COMBAT_HAND_UI_FLOW.start_hand_card_return_animation(self, hand_card, from_rect, to_rect)

func advance_hand_card_return_animations(delta: float) -> void:
	GAME_COMBAT_HAND_UI_FLOW.advance_hand_card_return_animations(self, delta)

func finish_hand_card_drag(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> bool:
	return GAME_COMBAT_HAND_UI_FLOW.finish_hand_card_drag(self, pointer_kind, pointer_id, screen_position)

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
	GAME_CAMERA_FLOW.center_on_selected_hero(self)

func _on_hero_button_pressed(hero_index: int) -> void:
	if not can_local_control_hero_index(hero_index):
		return
	select_hero_by_index(hero_index)

func _on_inventory_overlay_changed(items: Array) -> void:
	GAME_INVENTORY_OVERLAY_FLOW._on_inventory_overlay_changed(self, items)

func _on_inventory_close_requested() -> void:
	GAME_INVENTORY_OVERLAY_FLOW._on_inventory_close_requested(self)

func _on_inventory_pack_layout_changed(pack_modules: Array) -> void:
	GAME_INVENTORY_OVERLAY_FLOW._on_inventory_pack_layout_changed(self, pack_modules)

func _on_inventory_level_up_requested() -> void:
	GAME_INVENTORY_OVERLAY_FLOW._on_inventory_level_up_requested(self)

func _on_inventory_spellbook_slots_changed(slotted_spells: Array) -> void:
	GAME_INVENTORY_OVERLAY_FLOW._on_inventory_spellbook_slots_changed(self, slotted_spells)

func _on_inventory_item_dropped(item: Dictionary) -> void:
	GAME_INVENTORY_OVERLAY_FLOW._on_inventory_item_dropped(self, item)

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





