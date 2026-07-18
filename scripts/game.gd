extends Node2D

const HERO_SCENE: PackedScene = preload("res://scenes/actors/hero.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/enemy.tscn")
const INVENTORY_OVERLAY_SCRIPT: GDScript = preload("res://scripts/inventory_overlay.gd")
const GRID_SIZE: Vector2i = Vector2i(7, 7)
const ROOM_SPACING: Vector2 = Vector2(580.0, 392.0)
const INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const DOOR_OPEN_DURATION: float = 1.35
const FRONTIER_DOOR_RADIUS: float = 30.0
const ROOM_TEMPLATE_NOOK: String = "nook"
const ROOM_TEMPLATE_GALLERY: String = "gallery"
const ROOM_TEMPLATE_WORKSHOP: String = "workshop"
const ROOM_TEMPLATE_FORGE: String = "forge"
const ENEMY_ROLE_CRYSTAL: String = "crystal"
const ENEMY_ROLE_HUNTER: String = "hunter"
const ENEMY_ROLE_SABOTEUR: String = "saboteur"
const MINOR_MODULE_TURRET: String = "laser_turret"
const MAJOR_MODULE_FOOD: String = "food"
const MAJOR_MODULE_SCIENCE: String = "science"
const MAJOR_MODULE_INDUSTRY: String = "industry"
const MINOR_TURRET_COST: int = 3
const MAJOR_MODULE_COST: int = 14
const MINOR_MODULE_MAX_HEALTH: float = 22.0
const MAJOR_MODULE_MAX_HEALTH: float = 46.0
const TURRET_SHOT_COOLDOWN: float = 0.55
const TURRET_DAMAGE: float = 11.0
const PROJECTILE_SPEED: float = 950.0
const HERO_COUNT: int = 2
const INVENTORY_CANVAS_SIZE: Vector2i = Vector2i(9, 8)
const INVENTORY_BASE_ORIGIN: Vector2i = Vector2i(3, 3)
const INVENTORY_BASE_SIZE: Vector2i = Vector2i(2, 2)
const DOOR_REWARD_FOOD_BASE: int = 1
const DOOR_REWARD_INDUSTRY_BASE: int = 2
const DOOR_REWARD_SCIENCE_BASE: int = 0
const DOOR_REWARD_FOOD_MODULE: int = 2
const DOOR_REWARD_INDUSTRY_MODULE: int = 3
const DOOR_REWARD_SCIENCE_MODULE: int = 2
const WAVE_WARNING_DURATION: float = 1.0
const WAVE_STAGGER_ROOM_INTERVAL: float = 2.0
const WAVE_STAGGER_ENEMY_INTERVAL: float = 0.1
const CRYSTAL_PRESSURE_INTERVAL: float = 6.0
const CRYSTAL_PRESSURE_WARNING_DURATION: float = 0.65
const CRYSTAL_PRESSURE_ENEMIES_PER_ROOM: int = 3
const GROUND_ITEM_HOLD_DURATION: float = 0.28
const GROUND_ITEM_HOLD_CANCEL_DISTANCE: float = 28.0
const GROUND_ITEM_DRAW_SCALE: float = 17.0
const GROUND_ITEM_PICK_MIN_SIZE: float = 46.0
const GROUND_ITEM_PICK_RADIUS: float = 34.0
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
const CAMERA_DRAG_THRESHOLD: float = 18.0
const CAMERA_INTERACTION_COOLDOWN: float = 0.75
const CAMERA_SOFT_FOLLOW_SPEED: float = 2.5
const CAMERA_SOFT_FOLLOW_OFFSET: Vector2 = Vector2(0.0, -70.0)
const CAMERA_BOUNDS_PADDING: Vector2 = Vector2(240.0, 220.0)
const CARDINAL_DIRS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]

@onready var camera: Camera2D = $Camera2D
@onready var actor_layer: Node2D = $ActorLayer
@onready var enemy_layer: Node2D = $EnemyLayer
@onready var dust_label: Label = $UI/TopBar/Margin/Panel/HBox/DustLabel
@onready var food_label: Label = $UI/TopBar/Margin/Panel/HBox/FoodLabel
@onready var industry_label: Label = $UI/TopBar/Margin/Panel/HBox/IndustryLabel
@onready var science_label: Label = $UI/TopBar/Margin/Panel/HBox/ScienceLabel
@onready var crystal_label: Label = $UI/TopBar/Margin/Panel/HBox/CrystalLabel
@onready var wave_label: Label = $UI/TopBar/Margin/Panel/HBox/WaveLabel
@onready var center_button: Button = $UI/TopBar/Margin/Panel/HBox/CenterButton
@onready var room_label: Label = $UI/BottomBar/Margin/Panel/VBox/RoomLabel
@onready var hint_label: Label = $UI/BottomBar/Margin/Panel/VBox/HintLabel
@onready var light_button: Button = $UI/BottomBar/Margin/Panel/VBox/Actions/LightButton
@onready var build_button: Button = $UI/BottomBar/Margin/Panel/VBox/Actions/BuildButton
@onready var inventory_button: Button = $UI/BottomBar/Margin/Panel/VBox/Actions/InventoryButton
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
var pending_enemy_spawns: Array = []
var opening_room: Vector2i = INVALID_ROOM
var opening_origin_room: Vector2i = INVALID_ROOM
var opening_hero: Variant = null
var opening_timer_left: float = 0.0
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
var pinch_active: bool = false
var pinch_last_distance: float = 0.0
var pinch_last_midpoint: Vector2 = Vector2.ZERO
var mouse_pressed: bool = false
var mouse_dragging: bool = false
var mouse_press_screen: Vector2 = Vector2.ZERO
var camera_interaction_cooldown: float = 0.0
var hero_bar: HBoxContainer = null
var crystal_action_button: Button = null
var exit_button: Button = null
var hero_buttons: Array = []
var inventory_overlay: Variant = null
var inventory_session: Dictionary = {}
var ground_item_hold: Dictionary = {}
var pending_ground_item_pickups: Dictionary = {}
var next_item_uid: int = 1

func _ready() -> void:
	rng.randomize()
	item_defs = build_item_defs()
	center_button.pressed.connect(_on_center_button_pressed)
	light_button.pressed.connect(_on_light_button_pressed)
	build_button.pressed.connect(_on_build_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	turret_button.pressed.connect(_on_turret_button_pressed)
	food_major_button.pressed.connect(_on_food_major_button_pressed)
	science_major_button.pressed.connect(_on_science_major_button_pressed)
	industry_major_button.pressed.connect(_on_industry_major_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	ensure_runtime_ui()
	build_dungeon(true)
	spawn_heroes()
	selected_room = crystal_room
	center_camera()
	update_hud()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
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
	advance_ground_item_hold(delta)
	if inventory_overlay != null and inventory_overlay.visible:
		queue_redraw()
		return
	advance_room_opening(delta)
	advance_hero_movement()
	advance_pending_enemy_spawns(delta)
	advance_crystal_pressure(delta)
	advance_enemy_routes(delta)
	advance_projectiles(delta)
	process_combat(delta)
	process_modules(delta)
	cleanup_enemies()
	advance_camera(delta)
	if crystal_health <= 0.0:
		crystal_health = 0.0
		game_over = true
		status_message = "Crystal destroyed. Restart to try again."
		update_hud()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-2400.0, -1800.0), Vector2(4800.0, 3600.0)), Color("0c1418"), true)
	draw_dungeon_connections()
	draw_rooms()
	draw_frontier_doors()
	draw_projectiles()

func build_item_defs() -> Dictionary:
	return {
		"blade": {
			"name": "Blade",
			"short": "BLD",
			"size": Vector2i(1, 2),
			"color": Color("ffb36b"),
			"tags": ["weapon", "metal"],
			"stats": {"attack": 7.0},
		},
		"boots": {
			"name": "Boots",
			"short": "BOT",
			"size": Vector2i(2, 1),
			"color": Color("8ed7c5"),
			"tags": ["gear", "footwear"],
			"stats": {"speed": 36.0},
		},
		"ration": {
			"name": "Ration",
			"short": "RAT",
			"size": Vector2i(1, 2),
			"color": Color("c8e07b"),
			"tags": ["food"],
			"stats": {"health": 12.0},
		},
		"buckler": {
			"name": "Buckler",
			"short": "BCK",
			"size": Vector2i(2, 2),
			"color": Color("9ec3ff"),
			"tags": ["armor", "metal"],
			"stats": {"health": 18.0},
		},
		"whetstone": {
			"name": "Whetstone",
			"short": "WHT",
			"size": Vector2i(1, 1),
			"color": Color("f2e4a4"),
			"tags": ["tool"],
			"adjacency": {
				"weapon": {"attack": 4.0},
			},
		},
		"banner": {
			"name": "Banner",
			"short": "BNR",
			"size": Vector2i(1, 3),
			"color": Color("ea7e7e"),
			"tags": ["support"],
			"adjacency": {
				"armor": {"health": 8.0},
				"weapon": {"attack": 2.0},
			},
		},
	}

func ensure_runtime_ui() -> void:
	if hero_bar == null:
		hero_bar = HBoxContainer.new()
		hero_bar.add_theme_constant_override("separation", 6)
		$UI/TopBar/Margin/Panel/HBox.add_child(hero_bar)
		$UI/TopBar/Margin/Panel/HBox.move_child(hero_bar, $UI/TopBar/Margin/Panel/HBox.get_child_count() - 1)
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
	if inventory_overlay == null:
		inventory_overlay = Control.new()
		inventory_overlay.set_script(INVENTORY_OVERLAY_SCRIPT)
		inventory_overlay.visible = false
		$UI.add_child(inventory_overlay)
		inventory_overlay.close_requested.connect(_on_inventory_close_requested)
		inventory_overlay.inventory_changed.connect(_on_inventory_overlay_changed)
		inventory_overlay.pack_layout_changed.connect(_on_inventory_pack_layout_changed)
		inventory_overlay.level_up_requested.connect(_on_inventory_level_up_requested)
		inventory_overlay.item_dropped.connect(_on_inventory_item_dropped)

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
	projectiles.clear()
	pending_enemy_spawns.clear()
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
	opening_room = INVALID_ROOM
	opening_origin_room = INVALID_ROOM
	opening_hero = null
	opening_timer_left = 0.0
	if reset_resources:
		floor_index = 1
		dust = 4
		food = 10
		industry = 14
		science = 0
		crystal_health = 100.0
	create_room(crystal_room, ROOM_TEMPLATE_FORGE, random_template_doors(ROOM_TEMPLATE_FORGE))
	var crystal: Dictionary = rooms[crystal_room]
	crystal["opened"] = true
	crystal["lit"] = true
	crystal["crystal"] = true
	crystal["minor_slots"] = 0
	crystal["major_slots"] = 0
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
		var blueprint: Dictionary = roll_room_blueprint(-direction)
		if blueprint.is_empty():
			continue
		create_room(room_coord, String(blueprint["template_id"]), blueprint["door_dirs"])
		connect_rooms(origin, room_coord)
	assign_exit_room()
	refresh_camera_bounds()

func clear_floor_actors() -> void:
	pending_ground_item_pickups.clear()
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
		return
	for hero_index in range(hero_profiles.size(), HERO_COUNT):
		hero_profiles.append({
			"name": "H%d" % (hero_index + 1),
			"level": 1,
			"pack_modules": [],
			"inventory_items": [],
		})

func save_hero_profiles_from_nodes() -> void:
	ensure_hero_profiles()
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		hero_profiles[hero.hero_index]["level"] = hero.level
		hero_profiles[hero.hero_index]["pack_modules"] = hero.pack_modules.duplicate(true)
		hero_profiles[hero.hero_index]["inventory_items"] = hero.inventory_items.duplicate(true)

func roll_room_template() -> String:
	var roll: float = rng.randf()
	if roll < 0.28:
		return ROOM_TEMPLATE_NOOK
	if roll < 0.52:
		return ROOM_TEMPLATE_GALLERY
	if roll < 0.8:
		return ROOM_TEMPLATE_WORKSHOP
	return ROOM_TEMPLATE_FORGE

func create_room(room_coord: Vector2i, template_id: String, door_dirs: Array) -> void:
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
	rooms[room_coord] = {
		"neighbors": [],
		"opened": false,
		"lit": false,
		"crystal": false,
		"exit": false,
		"profile": template_id,
		"template_name": template_name,
		"door_dirs": door_dirs.duplicate(),
		"size": room_size,
		"minor_slots": minor_slots,
		"major_slots": major_slots,
		"minor_modules": [],
		"major_module_type": "",
		"major_health": 0.0,
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

func roll_room_blueprint(required_dir: Vector2i) -> Dictionary:
	var preferred_templates: Array[String] = []
	for _attempt in range(8):
		preferred_templates.append(roll_room_template())
	for template_id in [ROOM_TEMPLATE_NOOK, ROOM_TEMPLATE_GALLERY, ROOM_TEMPLATE_WORKSHOP, ROOM_TEMPLATE_FORGE]:
		if not preferred_templates.has(template_id):
			preferred_templates.append(template_id)
	for template_id_variant in preferred_templates:
		var template_id: String = String(template_id_variant)
		var door_dirs: Array = random_template_doors(template_id, required_dir)
		if door_dirs.is_empty():
			continue
		return {
			"template_id": template_id,
			"door_dirs": door_dirs,
		}
	return {}

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

func can_place_room_at(room_coord: Vector2i) -> bool:
	var candidate_rect: Rect2 = Rect2(room_center(room_coord) - room_template_size(ROOM_TEMPLATE_FORGE) * 0.5, room_template_size(ROOM_TEMPLATE_FORGE)).grow(18.0)
	for existing_coord_variant in rooms.keys():
		var existing_coord: Vector2i = existing_coord_variant
		if candidate_rect.intersects(room_rect(existing_coord).grow(18.0)):
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
			if not is_in_bounds(candidate) or rooms.has(candidate) or not can_place_room_at(candidate):
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

func assign_exit_room() -> void:
	var best_path_length: int = -1
	exit_room = INVALID_ROOM
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		rooms[room_coord]["exit"] = false
		if room_coord == crystal_room:
			continue
		var path: Array[Vector2i] = find_path(crystal_room, room_coord, false)
		if path.size() > best_path_length:
			best_path_length = path.size()
			exit_room = room_coord
	if exit_room != INVALID_ROOM:
		rooms[exit_room]["exit"] = true

func spawn_heroes() -> void:
	ensure_hero_profiles()
	for hero_index in range(HERO_COUNT):
		var hero: Variant = HERO_SCENE.instantiate()
		actor_layer.add_child(hero)
		hero.hero_index = hero_index
		hero.hero_name = String(hero_profiles[hero_index].get("name", "H%d" % (hero_index + 1)))
		hero.level = int(hero_profiles[hero_index].get("level", 1))
		hero.selected = hero_index == selected_hero_index
		hero.inventory_canvas_size = INVENTORY_CANVAS_SIZE
		hero.base_inventory_origin = INVENTORY_BASE_ORIGIN
		hero.base_inventory_size = INVENTORY_BASE_SIZE
		hero.pack_modules = Array(hero_profiles[hero_index].get("pack_modules", [])).duplicate(true)
		hero.inventory_items = Array(hero_profiles[hero_index].get("inventory_items", [])).duplicate(true)
		hero.set_room(crystal_room, hero_idle_position(crystal_room, hero_index, HERO_COUNT))
		apply_inventory_stats_to_hero(hero)
		heroes.append(hero)
	if selected_hero_index >= heroes.size():
		selected_hero_index = 0
	rebuild_hero_bar()
	update_selected_hero_flags()

func item_size_in_cells(item: Dictionary) -> Vector2i:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	if bool(item.get("rotated", false)):
		return Vector2i(base_size.y, base_size.x)
	return base_size

func make_ground_item(item_id: String, world_position: Vector2) -> Dictionary:
	var ground_item: Dictionary = {
		"uid": next_item_uid,
		"item_id": item_id,
		"position": world_position,
		"rotated": false,
	}
	next_item_uid += 1
	return ground_item

func roll_ground_item_id() -> String:
	var item_keys: Array = item_defs.keys()
	if item_keys.is_empty():
		return ""
	return String(item_keys[rng.randi_range(0, item_keys.size() - 1)])

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

func item_has_tag(item: Dictionary, tag_name: String) -> bool:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	return Array(item_def.get("tags", [])).has(tag_name)

func inventory_bonus_summary(items: Array) -> Dictionary:
	var move_bonus: float = 0.0
	var health_bonus: float = 0.0
	var attack_bonus: float = 0.0
	var synergy_hits: int = 0
	for item_variant in items:
		var item: Dictionary = item_variant
		var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
		var direct_stats: Dictionary = item_def.get("stats", {})
		move_bonus += float(direct_stats.get("speed", 0.0))
		health_bonus += float(direct_stats.get("health", 0.0))
		attack_bonus += float(direct_stats.get("attack", 0.0))
	var cell_to_item: Dictionary = {}
	for item_index in range(items.size()):
		for cell in item_occupied_cells(items[item_index]):
			cell_to_item[cell] = item_index
	for item_index in range(items.size()):
		var item: Dictionary = items[item_index]
		var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
		var adjacency_rules: Dictionary = item_def.get("adjacency", {})
		if adjacency_rules.is_empty():
			continue
		var touched_indices: Dictionary = {}
		for cell_variant in item_occupied_cells(item):
			var cell: Vector2i = cell_variant
			for direction in CARDINAL_DIRS:
				var neighbor_index: Variant = cell_to_item.get(cell + direction, null)
				if neighbor_index == null or int(neighbor_index) == item_index:
					continue
				touched_indices[int(neighbor_index)] = true
		for neighbor_index_variant in touched_indices.keys():
			var neighbor_item: Dictionary = items[int(neighbor_index_variant)]
			for tag_variant in adjacency_rules.keys():
				var tag_name: String = String(tag_variant)
				if not item_has_tag(neighbor_item, tag_name):
					continue
				var bonus_stats: Dictionary = adjacency_rules[tag_name]
				move_bonus += float(bonus_stats.get("speed", 0.0))
				health_bonus += float(bonus_stats.get("health", 0.0))
				attack_bonus += float(bonus_stats.get("attack", 0.0))
				synergy_hits += 1
	return {
		"speed": move_bonus,
		"health": health_bonus,
		"attack": attack_bonus,
		"synergies": synergy_hits,
	}

func build_inventory_stat_lines(hero: Variant, items: Array) -> Array[String]:
	var bonuses: Dictionary = inventory_bonus_summary(items)
	var used_cells: int = 0
	for item_variant in items:
		used_cells += item_occupied_cells(item_variant).size()
	var stat_lines: Array[String] = []
	stat_lines.append("Level %d" % hero.level)
	stat_lines.append("Damage %d" % int(round(hero.base_attack_damage + float(bonuses["attack"]))))
	stat_lines.append("Health %d" % int(round(hero.base_max_health + float(bonuses["health"]))))
	stat_lines.append("Speed %d" % int(round(hero.base_move_speed + float(bonuses["speed"]))))
	stat_lines.append("Synergies %d" % int(bonuses["synergies"]))
	stat_lines.append("Space %d/%d" % [used_cells, inventory_capacity(hero.pack_modules)])
	return stat_lines

func apply_inventory_stats_to_hero(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var bonuses: Dictionary = inventory_bonus_summary(hero.inventory_items)
	hero.apply_inventory_stats(float(bonuses["speed"]), float(bonuses["health"]), float(bonuses["attack"]), int(bonuses["synergies"]))
	if hero.hero_index >= 0 and hero.hero_index < hero_profiles.size():
		hero_profiles[hero.hero_index]["level"] = hero.level
		hero_profiles[hero.hero_index]["pack_modules"] = hero.pack_modules.duplicate(true)
		hero_profiles[hero.hero_index]["inventory_items"] = hero.inventory_items.duplicate(true)

func open_inventory_for_ground_item(hero: Variant, room_coord: Vector2i, item_uid: int, screen_position: Vector2, auto_drag_pending: bool = true) -> void:
	var item_index: int = find_ground_item_index(room_coord, item_uid)
	if item_index < 0:
		return
	var pending_item: Dictionary = rooms[room_coord]["ground_items"][item_index].duplicate(true)
	clear_pending_ground_item_pickup(hero.hero_index)
	open_hero_inventory(hero, pending_item, room_coord, item_uid, screen_position, auto_drag_pending)

func open_hero_inventory(hero: Variant, pending_item: Dictionary = {}, room_coord: Vector2i = INVALID_ROOM, item_uid: int = -1, screen_position: Vector2 = Vector2.ZERO, auto_drag_pending: bool = false) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	build_menu_open = false
	clear_build_mode()
	crystal_prompt_visible = false
	inventory_session = {
		"hero_index": hero.hero_index,
		"room": room_coord,
		"item_uid": item_uid,
	}
	inventory_overlay.configure(hero.hero_name, hero.level, food, level_up_food_cost(hero.level), hero_can_level_up(hero), build_inventory_stat_lines(hero, hero.inventory_items), hero.inventory_canvas_size, hero.base_inventory_origin, hero.base_inventory_size, hero.pack_modules, item_defs, hero.inventory_items, pending_item)
	if auto_drag_pending:
		inventory_overlay.begin_pending_drag(screen_position)
	status_message = "Inventory open for %s." % hero.hero_name
	mouse_pressed = false
	mouse_dragging = false
	touch_points.clear()
	active_touch_id = -1
	clear_ground_item_hold()
	update_hud()

func clear_inventory_session(commit_pending_item: bool) -> void:
	if inventory_session.is_empty():
		if inventory_overlay != null:
			inventory_overlay.hide_overlay()
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	var room_coord: Vector2i = inventory_session.get("room", INVALID_ROOM)
	var item_uid: int = int(inventory_session.get("item_uid", -1))
	if hero_index >= 0 and hero_index < heroes.size():
		var hero: Variant = heroes[hero_index]
		if is_instance_valid(hero) and inventory_overlay != null:
			hero.inventory_items = inventory_overlay.get_inventory_items()
			apply_inventory_stats_to_hero(hero)
	if commit_pending_item and rooms.has(room_coord):
		var item_index: int = find_ground_item_index(room_coord, item_uid)
		if item_index >= 0 and inventory_overlay != null and inventory_overlay.pending_consumed():
			rooms[room_coord]["ground_items"].remove_at(item_index)
	if inventory_overlay != null:
		inventory_overlay.hide_overlay()
	inventory_session.clear()
	queue_redraw()

func center_camera() -> void:
	refresh_camera_bounds()
	camera.zoom = Vector2(CAMERA_DEFAULT_ZOOM, CAMERA_DEFAULT_ZOOM)
	camera.global_position = hero_focus_position()
	clamp_camera()

func selected_hero() -> Variant:
	if selected_hero_index < 0 or selected_hero_index >= heroes.size():
		return null
	return heroes[selected_hero_index]

func update_selected_hero_flags() -> void:
	for hero_index in range(heroes.size()):
		var hero: Variant = heroes[hero_index]
		if is_instance_valid(hero):
			hero.selected = hero_index == selected_hero_index

func select_hero_by_index(hero_index: int) -> void:
	if hero_index < 0 or hero_index >= heroes.size():
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
		return room_rect(crystal_ground_room).get_center()
	return room_center(crystal_room)

func carrier_in_exit_room() -> bool:
	return crystal_holder != null and is_instance_valid(crystal_holder) and crystal_holder.current_room == exit_room and crystal_holder.pending_room == INVALID_ROOM and crystal_holder.is_idle()

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
	camera_bounds = Rect2(min_point - CAMERA_BOUNDS_PADDING, (max_point - min_point) + CAMERA_BOUNDS_PADDING * 2.0)

func hero_focus_position() -> Vector2:
	var hero: Variant = selected_hero()
	if hero == null:
		return room_center(crystal_room)
	return hero.global_position + CAMERA_SOFT_FOLLOW_OFFSET * camera.zoom.y

func mark_camera_interaction() -> void:
	camera_interaction_cooldown = CAMERA_INTERACTION_COOLDOWN

func advance_camera(delta: float) -> void:
	camera_interaction_cooldown = maxf(camera_interaction_cooldown - delta, 0.0)
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

func clear_ground_item_hold() -> void:
	ground_item_hold.clear()

func clear_pending_ground_item_pickup(hero_index: int = -1) -> void:
	if hero_index < 0:
		pending_ground_item_pickups.clear()
		return
	pending_ground_item_pickups.erase(hero_index)

func try_open_pending_ground_item_pickup(hero: Variant) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if inventory_overlay != null and inventory_overlay.visible:
		return false
	if not pending_ground_item_pickups.has(hero.hero_index):
		return false
	if hero.pending_room != Hero.INVALID_ROOM or not hero.is_idle() or not hero.move_steps.is_empty():
		return false
	var pickup_request: Dictionary = pending_ground_item_pickups[hero.hero_index]
	var room_coord: Vector2i = pickup_request.get("room", INVALID_ROOM)
	var item_uid: int = int(pickup_request.get("item_uid", -1))
	if hero.current_room != room_coord:
		return false
	if find_ground_item_index(room_coord, item_uid) < 0:
		clear_pending_ground_item_pickup(hero.hero_index)
		status_message = "That loot is no longer available."
		update_hud()
		return true
	open_inventory_for_ground_item(hero, room_coord, item_uid, Vector2.ZERO, false)
	return true

func begin_ground_item_hold(pointer_kind: String, pointer_id: int, screen_position: Vector2) -> void:
	var ground_item: Dictionary = ground_item_at_world_position(screen_to_world(screen_position))
	if ground_item.is_empty():
		clear_ground_item_hold()
		return
	ground_item_hold = {
		"pointer_kind": pointer_kind,
		"pointer_id": pointer_id,
		"start_screen": screen_position,
		"current_screen": screen_position,
		"elapsed": 0.0,
		"room": ground_item["room"],
		"item_uid": int(ground_item["item"]["uid"]),
	}

func advance_ground_item_hold(delta: float) -> void:
	if ground_item_hold.is_empty() or inventory_overlay != null and inventory_overlay.visible:
		return
	ground_item_hold["elapsed"] = float(ground_item_hold["elapsed"]) + delta
	if float(ground_item_hold["elapsed"]) < GROUND_ITEM_HOLD_DURATION:
		return
	var item_uid: int = int(ground_item_hold["item_uid"])
	var room_coord: Vector2i = ground_item_hold["room"]
	var screen_position: Vector2 = ground_item_hold["current_screen"]
	clear_ground_item_hold()
	var hero: Variant = selected_hero()
	if hero == null:
		return
	var command_room: Vector2i = interrupt_hero_orders(hero)
	if command_room == room_coord:
		open_inventory_for_ground_item(hero, room_coord, item_uid, screen_position, true)
		return
	var item_index: int = find_ground_item_index(room_coord, item_uid)
	if item_index < 0:
		status_message = "That loot is no longer available."
		update_hud()
		return
	var item_position: Vector2 = rooms[room_coord]["ground_items"][item_index]["position"]
	var path: Array[Vector2i] = find_path(command_room, room_coord, true)
	if path.size() <= 1:
		status_message = "No open route to that loot."
		update_hud()
		return
	pending_ground_item_pickups[hero.hero_index] = {
		"room": room_coord,
		"item_uid": item_uid,
	}
	issue_hero_steps(hero, build_steps_for_path(path, item_position))
	status_message = "%s moving to pick up loot in %s." % [hero.hero_name, room_title(room_coord)]
	update_hud()

func handle_screen_touch(event: InputEventScreenTouch) -> void:
	mark_camera_interaction()
	if event.pressed:
		touch_points[event.index] = event.position
		if touch_points.size() == 1:
			active_touch_id = event.index
			touch_start_screen = event.position
			touch_dragging = false
			pinch_active = false
			begin_ground_item_hold("touch", event.index, event.position)
		elif touch_points.size() >= 2:
			begin_pinch_gesture()
			clear_ground_item_hold()
		return
	var released_position: Vector2 = event.position
	var should_tap: bool = event.index == active_touch_id and not touch_dragging and not pinch_active
	touch_points.erase(event.index)
	if not ground_item_hold.is_empty() and ground_item_hold["pointer_kind"] == "touch" and int(ground_item_hold["pointer_id"]) == event.index:
		clear_ground_item_hold()
	if should_tap:
		handle_world_tap(screen_to_world(released_position), released_position)
	if touch_points.size() == 1:
		var remaining_ids: Array = touch_points.keys()
		active_touch_id = int(remaining_ids[0])
		touch_start_screen = touch_points[active_touch_id]
		touch_dragging = false
		pinch_active = false
	elif touch_points.is_empty():
		active_touch_id = -1
		touch_dragging = false
		pinch_active = false

func handle_screen_drag(event: InputEventScreenDrag) -> void:
	touch_points[event.index] = event.position
	mark_camera_interaction()
	if not ground_item_hold.is_empty() and ground_item_hold["pointer_kind"] == "touch" and int(ground_item_hold["pointer_id"]) == event.index:
		ground_item_hold["current_screen"] = event.position
		if event.position.distance_to(Vector2(ground_item_hold["start_screen"])) > GROUND_ITEM_HOLD_CANCEL_DISTANCE:
			clear_ground_item_hold()
	if touch_points.size() >= 2:
		update_pinch_gesture()
		touch_dragging = true
		return
	if event.index != active_touch_id:
		return
	if not touch_dragging and event.position.distance_to(touch_start_screen) > CAMERA_DRAG_THRESHOLD:
		touch_dragging = true
	if touch_dragging:
		camera.global_position -= event.relative * camera.zoom
		clamp_camera()

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
	if event.pressed:
		mouse_pressed = true
		mouse_dragging = false
		mouse_press_screen = event.position
		mark_camera_interaction()
		begin_ground_item_hold("mouse", 0, event.position)
	else:
		var should_tap: bool = mouse_pressed and not mouse_dragging
		mouse_pressed = false
		if not ground_item_hold.is_empty() and ground_item_hold["pointer_kind"] == "mouse":
			clear_ground_item_hold()
		if should_tap:
			handle_world_tap(screen_to_world(event.position), event.position)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not mouse_pressed or not touch_points.is_empty():
		return
	if not ground_item_hold.is_empty() and ground_item_hold["pointer_kind"] == "mouse":
		ground_item_hold["current_screen"] = event.position
		if event.position.distance_to(Vector2(ground_item_hold["start_screen"])) > GROUND_ITEM_HOLD_CANCEL_DISTANCE:
			clear_ground_item_hold()
	if not mouse_dragging and event.position.distance_to(mouse_press_screen) > CAMERA_DRAG_THRESHOLD:
		mouse_dragging = true
	if mouse_dragging:
		mark_camera_interaction()
		camera.global_position -= event.relative * camera.zoom
		clamp_camera()

func try_select_hero_at_position(world_position: Vector2) -> bool:
	for hero_index in range(heroes.size()):
		var hero: Variant = heroes[hero_index]
		if not is_instance_valid(hero):
			continue
		if hero.global_position.distance_to(world_position) <= 28.0:
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
	if hero == null:
		return
	if opening_room != INVALID_ROOM:
		status_message = "Door breach in progress for %s." % room_title(opening_room)
		update_hud()
		return
	var frontier_door: Dictionary = frontier_target_at_position(world_position)
	var tapped_room: Vector2i = room_at_world_position(world_position)
	if frontier_door.is_empty() and tapped_room == INVALID_ROOM:
		return
	var command_room: Vector2i = interrupt_hero_orders(hero)
	if not frontier_door.is_empty():
		var from_room: Vector2i = frontier_door["from_room"]
		var sealed_room: Vector2i = frontier_door["to_room"]
		selected_room = from_room
		hero.pending_open_origin_room = from_room
		hero.pending_open_room = sealed_room
		if command_room == from_room:
			issue_hero_steps(hero, [make_hero_step(from_room, doorway_position(from_room, sealed_room))])
		else:
			var door_path: Array[Vector2i] = find_path(command_room, from_room, true)
			if door_path.is_empty():
				status_message = "No open route to that door."
				update_hud()
				return
			issue_hero_steps(hero, build_steps_for_path(door_path, doorway_position(from_room, sealed_room)))
		status_message = "%s moving to open a new chamber from %s." % [hero.hero_name, room_title(from_room)]
		update_hud()
		return
	selected_room = tapped_room
	if tapped_room == command_room:
		var move_target: Vector2 = clamp_point_to_room(world_position, tapped_room)
		issue_hero_steps(hero, [make_hero_step(tapped_room, move_target)])
		status_message = "%s moving inside %s." % [hero.hero_name, room_title(tapped_room)]
		update_hud()
		return
	var path: Array[Vector2i] = find_path(command_room, tapped_room, true)
	if path.size() <= 1:
		status_message = "No open route to that room."
	else:
		issue_hero_steps(hero, build_steps_for_path(path, clamp_point_to_room(world_position, tapped_room)))
		status_message = "%s moving to %s." % [hero.hero_name, room_title(tapped_room)]
	update_hud()

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
	status_message = "Opening %s. Hold for %.1fs." % [room_title(room_coord), DOOR_OPEN_DURATION]
	update_hud()

func advance_room_opening(delta: float) -> void:
	if opening_room == INVALID_ROOM:
		return
	opening_timer_left = maxf(opening_timer_left - delta, 0.0)
	if opening_timer_left <= 0.0:
		finish_room_opening()
		return
	var progress_ratio: float = 1.0 - (opening_timer_left / DOOR_OPEN_DURATION)
	status_message = "Opening %s. %d%%" % [room_title(opening_room), int(progress_ratio * 100.0)]
	update_hud()

func finish_room_opening() -> void:
	var breached_room: Vector2i = opening_room
	var from_room: Vector2i = opening_origin_room
	var breach_hero: Variant = opening_hero
	opening_room = INVALID_ROOM
	opening_origin_room = INVALID_ROOM
	opening_hero = null
	opening_timer_left = 0.0
	open_room(breached_room)
	if breach_hero != null and is_instance_valid(breach_hero):
		issue_hero_steps(breach_hero, [
			make_hero_step(breached_room, doorway_position(breached_room, from_room)),
		])
	update_hud()

func open_room(room_coord: Vector2i) -> void:
	if rooms[room_coord]["opened"]:
		return
	var room: Dictionary = rooms[room_coord]
	room["opened"] = true
	opened_rooms += 1
	doors_opened += 1
	var door_reward: Dictionary = calculate_door_rewards()
	food += int(door_reward["food"])
	industry += int(door_reward["industry"])
	science += int(door_reward["science"])
	if rng.randf() < 0.35:
		dust += 1
	if room_coord != crystal_room:
		spawn_ground_loot(room_coord)
	refresh_camera_bounds()
	launch_wave(room_coord)
	status_message = "Opened %s. +%d food, +%d industry, +%d science." % [room_title(room_coord), int(door_reward["food"]), int(door_reward["industry"]), int(door_reward["science"])]
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
				if float(room["major_health"]) > 0.0:
					food_reward += DOOR_REWARD_FOOD_MODULE
			MAJOR_MODULE_SCIENCE:
				if float(room["major_health"]) > 0.0:
					science_reward += DOOR_REWARD_SCIENCE_MODULE
			MAJOR_MODULE_INDUSTRY:
				if float(room["major_health"]) > 0.0:
					industry_reward += DOOR_REWARD_INDUSTRY_MODULE
	return {
		"food": food_reward,
		"industry": industry_reward,
		"science": science_reward,
	}

func launch_wave(entered_room: Vector2i) -> void:
	var dark_rooms: Array[Vector2i] = []
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if room_coord == crystal_room or not room["opened"] or room["lit"]:
			continue
		dark_rooms.append(room_coord)
	if dark_rooms.is_empty():
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
	if immediate:
		spawn_wave(room_coord, count)
		return
	var room_delay: float = 0.0 if immediate else WAVE_WARNING_DURATION + float(spawn_order) * WAVE_STAGGER_ROOM_INTERVAL
	rooms[room_coord]["warning_timer_left"] = room_delay
	pending_enemy_spawns.append({
		"room": room_coord,
		"remaining": count,
		"delay_left": room_delay,
		"interval": WAVE_STAGGER_ENEMY_INTERVAL,
		"total_count": count,
		"spawned": 0,
	})

func advance_pending_enemy_spawns(delta: float) -> void:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		rooms[room_coord]["warning_timer_left"] = maxf(float(rooms[room_coord].get("warning_timer_left", 0.0)) - delta, 0.0)
	var active_spawns: Array = []
	for pending_spawn in pending_enemy_spawns:
		pending_spawn["delay_left"] = float(pending_spawn["delay_left"]) - delta
		while int(pending_spawn["remaining"]) > 0 and float(pending_spawn["delay_left"]) <= 0.0:
			spawn_wave_enemy(Vector2i(pending_spawn["room"]), int(pending_spawn["spawned"]), int(pending_spawn["total_count"]))
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
	rooms[room_coord]["warning_timer_left"] = maxf(float(rooms[room_coord].get("warning_timer_left", 0.0)), CRYSTAL_PRESSURE_WARNING_DURATION)
	pending_enemy_spawns.append({
		"room": room_coord,
		"remaining": count,
		"delay_left": CRYSTAL_PRESSURE_WARNING_DURATION,
		"interval": WAVE_STAGGER_ENEMY_INTERVAL,
		"total_count": count,
		"spawned": 0,
	})

func spawn_wave(room_coord: Vector2i, count: int) -> void:
	for enemy_index in range(count):
		spawn_wave_enemy(room_coord, enemy_index, count)

func spawn_wave_enemy(room_coord: Vector2i, enemy_index: int, count: int) -> void:
	var enemy: Variant = ENEMY_SCENE.instantiate()
	enemy_layer.add_child(enemy)
	var spawn_position: Vector2 = room_center(room_coord) + random_room_offset(56.0)
	enemy.global_position = spawn_position
	enemy.set_role(roll_enemy_role(enemy_index, count))
	enemy.current_room = room_coord
	enemy.previous_room = room_coord
	enemy.next_room = room_coord
	enemy.set_destination(spawn_position)
	enemies.append(enemy)

func roll_enemy_role(enemy_index: int, count: int) -> String:
	if enemy_index == 0:
		return ENEMY_ROLE_CRYSTAL
	if enemy_index == count - 1 and count >= 3:
		return ENEMY_ROLE_SABOTEUR
	var roll: float = rng.randf()
	if roll < 0.42:
		return ENEMY_ROLE_HUNTER
	if roll < 0.72:
		return ENEMY_ROLE_CRYSTAL
	return ENEMY_ROLE_SABOTEUR

func issue_hero_steps(hero: Variant, steps: Array) -> void:
	hero.move_steps.clear()
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
	clear_pending_ground_item_pickup(hero.hero_index)
	hero.move_steps.clear()
	hero.pending_open_room = Hero.INVALID_ROOM
	hero.pending_open_origin_room = Hero.INVALID_ROOM
	hero.pending_room = Hero.INVALID_ROOM
	hero.current_room = command_room
	hero.set_destination(hero.global_position)
	return command_room

func make_hero_step(room_coord: Vector2i, world_position: Vector2) -> Dictionary:
	return {
		"room": room_coord,
		"position": world_position,
	}

func build_steps_for_path(path: Array[Vector2i], final_position: Vector2) -> Array:
	var steps: Array = []
	if path.is_empty():
		return steps
	if path.size() == 1:
		steps.append(make_hero_step(path[0], clamp_point_to_room(final_position, path[0])))
		return steps
	for index in range(path.size() - 1):
		var current_room: Vector2i = path[index]
		var next_room: Vector2i = path[index + 1]
		steps.append(make_hero_step(current_room, doorway_position(current_room, next_room)))
		steps.append(make_hero_step(next_room, doorway_position(next_room, current_room)))
	var destination_room: Vector2i = path[path.size() - 1]
	steps.append(make_hero_step(destination_room, clamp_point_to_room(final_position, destination_room)))
	return steps

func advance_hero_movement() -> void:
	update_selected_hero_flags()
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		if try_open_pending_ground_item_pickup(hero):
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
		if hero.move_steps.is_empty() or not hero.is_idle():
			continue
		var next_step: Dictionary = hero.move_steps[0]
		hero.move_steps.remove_at(0)
		var next_room: Vector2i = next_step["room"]
		var next_position: Vector2 = next_step["position"]
		if next_room != hero.current_room:
			hero.pending_room = next_room
		hero.set_destination(next_position)

func advance_enemy_routes(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		enemy.attack_cooldown_left = maxf(enemy.attack_cooldown_left - delta, 0.0)
		if enemy.moving_between_rooms:
			if enemy.is_idle():
				enemy.moving_between_rooms = false
				enemy.previous_room = enemy.current_room
				enemy.current_room = enemy.next_room
				enemy.set_destination(enemy_room_goal_position(enemy, enemy.current_room))
			continue
		var target_room: Vector2i = target_room_for_enemy(enemy)
		if target_room == INVALID_ROOM:
			continue
		if enemy.current_room == target_room:
			var target_position: Vector2 = enemy_target_position(enemy)
			enemy.set_destination(target_position)
			if enemy.global_position.distance_to(target_position) <= 18.0:
				resolve_enemy_attack(enemy)
			continue
		var path: Array[Vector2i] = find_path(enemy.current_room, target_room, true)
		if path.size() <= 1:
			continue
		var next_room: Vector2i = path[1]
		var exit_position: Vector2 = doorway_position(enemy.current_room, next_room)
		enemy.set_destination(exit_position)
		if enemy.global_position.distance_to(exit_position) <= 10.0:
			enemy.previous_room = enemy.current_room
			enemy.next_room = next_room
			enemy.moving_between_rooms = true
			enemy.set_destination(doorway_position(next_room, enemy.current_room))

func target_room_for_enemy(enemy: Variant) -> Vector2i:
	match String(enemy.enemy_role):
		ENEMY_ROLE_HUNTER:
			var hunter_target: Variant = hunter_target_hero(enemy)
			if hunter_target == null:
				return crystal_room
			if hunter_target.pending_room != Hero.INVALID_ROOM:
				return hunter_target.pending_room
			return hunter_target.current_room
		ENEMY_ROLE_SABOTEUR:
			var module_room: Vector2i = find_nearest_module_room(enemy.current_room)
			if module_room != INVALID_ROOM:
				return module_room
			return crystal_room
		_:
			return crystal_room

func enemy_room_goal_position(enemy: Variant, room_coord: Vector2i) -> Vector2:
	var target_room: Vector2i = target_room_for_enemy(enemy)
	if target_room == INVALID_ROOM:
		return room_center(room_coord)
	if room_coord == target_room:
		return enemy_target_position(enemy)
	var path: Array[Vector2i] = find_path(room_coord, target_room, true)
	if path.size() > 1:
		return doorway_position(room_coord, path[1])
	return room_center(room_coord)

func enemy_target_position(enemy: Variant) -> Vector2:
	match String(enemy.enemy_role):
		ENEMY_ROLE_HUNTER:
			var hunter_target: Variant = hunter_target_hero(enemy)
			if hunter_target == null:
				return room_center(enemy.current_room)
			if enemy.current_room == hunter_target.current_room:
				return hunter_target.global_position
			if hunter_target.pending_room != Hero.INVALID_ROOM and enemy.current_room == hunter_target.pending_room:
				return doorway_position(hunter_target.pending_room, hunter_target.current_room)
			return room_center(enemy.current_room)
		ENEMY_ROLE_SABOTEUR:
			return module_target_position(enemy.current_room, enemy.global_position)
		_:
			return room_center(crystal_room)

func hunter_target_hero(enemy: Variant) -> Variant:
	var chosen_hero: Variant = null
	var chosen_path_length: int = 99999
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		var candidate_room: Vector2i = hero.current_room
		if hero.pending_room != Hero.INVALID_ROOM:
			candidate_room = hero.pending_room
		var path: Array[Vector2i] = find_path(enemy.current_room, candidate_room, true)
		if path.is_empty():
			continue
		if path.size() < chosen_path_length:
			chosen_path_length = path.size()
			chosen_hero = hero
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
		if String(module_data["type"]) != MINOR_MODULE_TURRET or float(module_data["health"]) <= 0.0:
			continue
		var slot_index: int = int(module_data.get("slot_index", -1))
		if slot_index < 0 or slot_index >= slot_positions.size():
			continue
		candidates.append(slot_positions[slot_index])
	if candidates.is_empty():
		return room_center(room_coord)
	var chosen_position: Vector2 = candidates[0]
	var closest_distance: float = origin.distance_to(chosen_position)
	for candidate in candidates:
		var distance: float = origin.distance_to(candidate)
		if distance < closest_distance:
			closest_distance = distance
			chosen_position = candidate
	return chosen_position

func resolve_enemy_attack(enemy: Variant) -> void:
	if enemy.attack_cooldown_left > 0.0:
		return
	match String(enemy.enemy_role):
		ENEMY_ROLE_HUNTER:
			var hunter_target: Variant = hunter_target_hero(enemy)
			if hunter_target == null:
				return
			if enemy.current_room != hunter_target.current_room and enemy.current_room != hunter_target.pending_room:
				return
			if hunter_target.take_damage(enemy.attack_damage):
				send_hero_back_to_crystal(hunter_target)
				status_message = "Hunters forced %s back to the crystal chamber." % hunter_target.hero_name
			else:
				status_message = "Hunters are attacking %s." % hunter_target.hero_name
		ENEMY_ROLE_SABOTEUR:
			if not damage_module(enemy.current_room, enemy.attack_damage):
				return
		_:
			if enemy.current_room != crystal_room:
				return
			crystal_health -= enemy.attack_damage
			status_message = "Raiders are striking the crystal."
	enemy.attack_cooldown_left = enemy.attack_cooldown
	update_hud()

func find_nearest_module_room(from_room: Vector2i) -> Vector2i:
	var closest_room: Vector2i = INVALID_ROOM
	var closest_path_length: int = 9999
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		var room: Dictionary = rooms[room_coord]
		if room_coord == crystal_room or not room["opened"] or not room["lit"]:
			continue
		if room["minor_modules"].is_empty() and room["major_module_type"] == "":
			continue
		var path: Array[Vector2i] = find_path(from_room, room_coord, true)
		if path.is_empty():
			continue
		if path.size() < closest_path_length:
			closest_path_length = path.size()
			closest_room = room_coord
	return closest_room

func damage_module(room_coord: Vector2i, amount: float) -> bool:
	if not rooms.has(room_coord):
		return false
	var room: Dictionary = rooms[room_coord]
	var module_count: int = room["minor_modules"].size()
	var can_hit_major: bool = room["major_module_type"] != "" and float(room["major_health"]) > 0.0
	if module_count == 0 and not can_hit_major:
		return false
	var attack_major: bool = can_hit_major and (module_count == 0 or rng.randf() < 0.45)
	if attack_major:
		room["major_health"] = maxf(float(room["major_health"]) - amount, 0.0)
		if float(room["major_health"]) <= 0.0:
			status_message = "Saboteurs destroyed the major module in %s." % room_title(room_coord)
			room["major_module_type"] = ""
		else:
			status_message = "Saboteurs are damaging the major module in %s." % room_title(room_coord)
		return true
	var module_index: int = rng.randi_range(0, module_count - 1)
	var module_data: Dictionary = room["minor_modules"][module_index]
	module_data["health"] = maxf(float(module_data["health"]) - amount, 0.0)
	if float(module_data["health"]) <= 0.0:
		room["minor_modules"].remove_at(module_index)
		status_message = "Saboteurs destroyed a turret in %s." % room_title(room_coord)
	else:
		status_message = "Saboteurs are damaging a turret in %s." % room_title(room_coord)
	return true

func send_hero_back_to_crystal(hero: Variant) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	clear_pending_ground_item_pickup(hero.hero_index)
	if crystal_holder == hero:
		drop_crystal(hero.current_room)
	hero.restore_health()
	hero.move_steps.clear()
	hero.pending_room = Hero.INVALID_ROOM
	hero.pending_open_room = Hero.INVALID_ROOM
	hero.pending_open_origin_room = Hero.INVALID_ROOM
	if opening_hero == hero:
		opening_room = INVALID_ROOM
		opening_origin_room = INVALID_ROOM
		opening_hero = null
		opening_timer_left = 0.0
	hero.current_room = crystal_room
	if hero == selected_hero():
		selected_room = crystal_room
	hero.set_room(crystal_room, hero_idle_position(crystal_room, hero.hero_index, heroes.size()))

func process_combat(delta: float) -> void:
	for hero in heroes:
		if not is_instance_valid(hero):
			continue
		hero.cooldown_left = maxf(hero.cooldown_left - delta, 0.0)
		if hero.carrying_crystal or hero.pending_room != Hero.INVALID_ROOM or hero.cooldown_left > 0.0:
			continue
		var hero_target: Variant = nearest_enemy_in_room(hero.current_room, hero.global_position, hero.attack_range)
		if hero_target != null:
			hero.trigger_attack(hero_target.global_position, "laser")
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
			if String(module_data["type"]) != MINOR_MODULE_TURRET or float(module_data["health"]) <= 0.0:
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
			module_data["cooldown"] = TURRET_SHOT_COOLDOWN
			spawn_laser_projectile(slot_position, turret_target, TURRET_DAMAGE)

func spawn_laser_projectile(origin: Vector2, target: Variant, damage: float, color: Color = Color("89f2ff"), width: float = 4.0, speed: float = PROJECTILE_SPEED) -> void:
	projectiles.append({
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
		var current_position: Vector2 = projectile["position"]
		var target_position: Vector2 = projectile["target_position"]
		var target: Variant = projectile["target"]
		if is_instance_valid(target):
			target_position = target.global_position
			projectile["target_position"] = target_position
		var offset: Vector2 = target_position - current_position
		if offset.length() <= 6.0:
			if is_instance_valid(target):
				target.take_damage(float(projectile["damage"]))
			continue
		var travel_distance: float = minf(float(projectile["speed"]) * delta, offset.length())
		projectile["previous"] = current_position
		projectile["position"] = current_position + offset.normalized() * travel_distance
		active_projectiles.append(projectile)
	projectiles = active_projectiles

func draw_projectiles() -> void:
	for projectile in projectiles:
		var previous: Vector2 = projectile["previous"]
		var current_position: Vector2 = projectile["position"]
		var color: Color = projectile["color"]
		var width: float = float(projectile.get("width", 4.0))
		draw_line(previous, current_position, color, width, true)
		draw_circle(current_position, 3.0, color)

func nearest_enemy_in_room(room_coord: Vector2i, origin: Vector2, max_range: float) -> Variant:
	var closest_enemy: Variant = null
	var closest_distance: float = max_range
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.current_room != room_coord or enemy.moving_between_rooms:
			continue
		var distance: float = origin.distance_to(enemy.global_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	return closest_enemy

func first_enemy_in_room(room_coord: Vector2i) -> Variant:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.current_room == room_coord and not enemy.moving_between_rooms:
			return enemy
	return null

func cleanup_enemies() -> void:
	var alive_enemies: Array = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			alive_enemies.append(enemy)
	enemies = alive_enemies

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

func room_is_revealed(room_coord: Vector2i) -> bool:
	return rooms.has(room_coord) and rooms[room_coord]["opened"]

func frontier_target_at_position(world_position: Vector2) -> Dictionary:
	var door_target: Dictionary = frontier_door_at_position(world_position)
	if not door_target.is_empty():
		return door_target
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
			var stub_position: Vector2 = doorway + (room_center(neighbor) - room_center(room_coord)).normalized() * 18.0
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
	var offset_x: float = (float(room_coord.x) - float(GRID_SIZE.x - 1) * 0.5) * ROOM_SPACING.x
	var offset_y: float = (float(room_coord.y) - float(GRID_SIZE.y - 1) * 0.5) * ROOM_SPACING.y
	return Vector2(offset_x, offset_y)

func room_size_for(room_coord: Vector2i) -> Vector2:
	return rooms[room_coord]["size"]

func room_rect(room_coord: Vector2i) -> Rect2:
	var room_size: Vector2 = room_size_for(room_coord)
	return Rect2(room_center(room_coord) - room_size * 0.5, room_size)

func clamp_point_to_room(world_position: Vector2, room_coord: Vector2i) -> Vector2:
	var padded_rect: Rect2 = room_rect(room_coord).grow(-26.0)
	return Vector2(
		clampf(world_position.x, padded_rect.position.x, padded_rect.position.x + padded_rect.size.x),
		clampf(world_position.y, padded_rect.position.y, padded_rect.position.y + padded_rect.size.y)
	)

func doorway_position(from_room: Vector2i, to_room: Vector2i) -> Vector2:
	var room_half: Vector2 = room_size_for(from_room) * 0.5
	var center: Vector2 = room_center(from_room)
	var delta: Vector2i = to_room - from_room
	if delta.x != 0:
		return center + Vector2(float(delta.x) * (room_half.x - 20.0), 0.0)
	return center + Vector2(0.0, float(delta.y) * (room_half.y - 20.0))

func major_slot_position(room_coord: Vector2i) -> Vector2:
	var rect: Rect2 = room_rect(room_coord)
	return rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.23)

func minor_slot_positions(room_coord: Vector2i) -> Array:
	var rect: Rect2 = room_rect(room_coord)
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

func major_slot_contains_point(room_coord: Vector2i, world_position: Vector2) -> bool:
	return major_slot_position(room_coord).distance_to(world_position) <= 28.0

func should_highlight_minor_slot(room_coord: Vector2i, slot_index: int) -> bool:
	if pending_build_type != MINOR_MODULE_TURRET or not can_manage_modules(room_coord):
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

func random_room_offset(radius: float) -> Vector2:
	return Vector2(
		rng.randf_range(-radius, radius),
		rng.randf_range(-radius * 0.55, radius * 0.55)
	)

func draw_dungeon_connections() -> void:
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
			var passage_color: Color = Color("31434d")
			if rooms[room_coord]["opened"] and rooms[neighbor]["opened"]:
				passage_color = Color("4d6977")
			draw_line(room_center(room_coord), room_center(neighbor), passage_color, 38.0, true)
			draw_line(room_center(room_coord), room_center(neighbor), passage_color.lightened(0.12), 18.0, true)

func draw_frontier_doors() -> void:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if rooms[neighbor]["opened"]:
				continue
			var doorway: Vector2 = doorway_position(room_coord, neighbor)
			var direction: Vector2 = (room_center(neighbor) - room_center(room_coord)).normalized()
			var outer_position: Vector2 = doorway + direction * 28.0
			var tangent: Vector2 = Vector2(-direction.y, direction.x)
			draw_line(doorway - direction * 6.0, outer_position, Color("eff7ff"), 7.0, true)
			draw_line(doorway - direction * 4.0, outer_position, Color("5f7a88"), 3.0, true)
			draw_circle(outer_position, 13.0, Color("203039"))
			draw_arc(outer_position, 14.0, 0.0, TAU, 28, Color("f6e39d"), 3.0, true)
			draw_line(outer_position - tangent * 6.0, outer_position + tangent * 6.0, Color("f6e39d"), 2.0, true)
			draw_line(outer_position - direction * 6.0, outer_position + direction * 6.0, Color("f6e39d"), 2.0, true)

func draw_rooms() -> void:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not rooms[room_coord]["opened"]:
			continue
		var room: Dictionary = rooms[room_coord]
		var rect: Rect2 = room_rect(room_coord)
		var fill: Color = Color("18252b")
		var outline: Color = Color("4f6c7b")
		if room["opened"]:
			fill = Color("25363d")
		if room["lit"]:
			fill = Color("4c6b4b")
			outline = Color("d6f7b2")
		if room["crystal"]:
			fill = Color("5f4d25")
			outline = Color("ffd35b")
		var warning_ratio: float = float(room.get("warning_timer_left", 0.0)) / maxf(WAVE_WARNING_DURATION, 0.001)
		if warning_ratio > 0.0:
			var pulse: float = 0.45 + 0.55 * absf(sin((WAVE_WARNING_DURATION - float(room.get("warning_timer_left", 0.0))) * 11.0))
			fill = fill.lerp(Color("7a2626"), 0.18 + 0.18 * pulse)
			outline = outline.lerp(Color("ffb2a3"), 0.35 + 0.35 * pulse)
		draw_rect(rect, fill, true)
		draw_rect(rect, outline, false, 4.0)
		if room_coord == selected_room:
			draw_rect(rect.grow(8.0), Color("f7f7f2"), false, 4.0)
		for hero in heroes:
			if not is_instance_valid(hero):
				continue
			if room_coord == hero.current_room or room_coord == hero.pending_room:
				var hero_outline: Color = Color("5f8796")
				if hero == selected_hero():
					hero_outline = Color("7ad7ff")
				draw_rect(rect.grow(14.0), hero_outline, false, 4.0)
		if room["lit"] and room_coord != crystal_room:
			draw_circle(rect.position + Vector2(28.0, 28.0), 11.0, Color("fff49c"))
		if room["major_slots"] > 0 and room_coord != crystal_room:
			var major_position: Vector2 = major_slot_position(room_coord)
			var major_outline: Color = Color("182024")
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
		var slot_positions: Array = minor_slot_positions(room_coord)
		for slot_index in range(slot_positions.size()):
			var slot_position: Vector2 = slot_positions[slot_index]
			var slot_fill: Color = Color("152127")
			var slot_outline: Color = Color("4f6c7b")
			if should_highlight_minor_slot(room_coord, slot_index):
				slot_fill = Color("23323a")
				slot_outline = Color("8df6ff")
			draw_circle(slot_position, 10.0, slot_fill)
			draw_arc(slot_position, 11.0, 0.0, TAU, 24, slot_outline, 2.0, true)
			var module_index: int = minor_module_index_for_slot(room_coord, slot_index)
			if module_index >= 0:
				var module_data: Dictionary = room["minor_modules"][module_index]
				if String(module_data["type"]) == MINOR_MODULE_TURRET and float(module_data["health"]) > 0.0:
					draw_circle(slot_position, 7.5, Color("89f2ff"))
					draw_line(slot_position + Vector2(0.0, -10.0), slot_position + Vector2(0.0, -18.0), Color("cffcff"), 2.0)
		for ground_item_variant in room["ground_items"]:
			var ground_item: Dictionary = ground_item_variant
			var item_rect: Rect2 = ground_item_draw_rect(ground_item)
			var item_def: Dictionary = item_defs.get(String(ground_item.get("item_id", "")), {})
			var item_color: Color = item_def.get("color", Color("9ed4ff"))
			if not ground_item_hold.is_empty() and int(ground_item_hold.get("item_uid", -1)) == int(ground_item.get("uid", -2)):
				var hold_ratio: float = clampf(float(ground_item_hold.get("elapsed", 0.0)) / GROUND_ITEM_HOLD_DURATION, 0.0, 1.0)
				var hold_center: Vector2 = item_rect.get_center()
				var hold_radius: float = maxf(item_rect.size.x, item_rect.size.y) * (0.72 + 0.08 * hold_ratio)
				var hold_arc_width: float = 3.0 + hold_ratio * 2.0
				item_color = item_color.lightened(0.18)
				draw_arc(hold_center, hold_radius, -PI * 0.5, -PI * 0.5 + TAU * hold_ratio, 24, Color("ffe39b"), hold_arc_width, true)
				draw_arc(hold_center, hold_radius + 6.0, 0.0, TAU, 24, Color(1.0, 0.96, 0.78, 0.18 + hold_ratio * 0.18), 1.8, true)
				draw_rect(item_rect.grow(4.0 + hold_ratio * 4.0), Color(1.0, 0.93, 0.72, 0.08 + hold_ratio * 0.12), false, 2.0)
			draw_rect(item_rect, item_color, true)
			draw_rect(item_rect, Color("f1fbff"), false, 2.0)
			draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(4.0, item_rect.size.y * 0.65), String(item_def.get("short", "ITM")), HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 4.0, 12, Color("0d171d"))
			draw_arc(item_rect.get_center(), maxf(item_rect.size.x, item_rect.size.y) * 0.55, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.18), 1.5, true)
			if not ground_item_hold.is_empty() and int(ground_item_hold.get("item_uid", -1)) == int(ground_item.get("uid", -2)):
				draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(-6.0, item_rect.size.y + 18.0), "Hold", HORIZONTAL_ALIGNMENT_CENTER, item_rect.size.x + 12.0, 14, Color("fff3c6"))
		if room_coord == opening_room:
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

func update_hud() -> void:
	update_selected_hero_flags()
	var inventory_open: bool = inventory_overlay != null and inventory_overlay.visible
	dust_label.text = "Dust %d" % dust
	food_label.text = "Food %d" % food
	industry_label.text = "Industry %d" % industry
	science_label.text = "Science %d" % science
	if crystal_holder != null and is_instance_valid(crystal_holder):
		crystal_label.text = "Crystal %d%%  %s Carrying" % [int(clampf(crystal_health, 0.0, 100.0)), crystal_holder.hero_name]
	else:
		crystal_label.text = "Crystal %d%%" % int(clampf(crystal_health, 0.0, 100.0))
	wave_label.text = "Floor %d  Doors %d  Waves %d  Dark %d" % [floor_index, doors_opened, wave_index, count_dark_open_rooms()]
	room_label.text = room_summary(selected_room)
	light_button.disabled = inventory_open or not can_toggle_light(selected_room)
	if can_toggle_light(selected_room) and rooms[selected_room]["lit"]:
		light_button.text = "Darken Room"
	else:
		light_button.text = "Light Room"
	build_button.disabled = inventory_open or game_over
	inventory_button.disabled = inventory_open or selected_hero() == null
	inventory_button.text = "Inventory"
	build_button.text = "Hide Build" if build_menu_open else "Build"
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
	update_hero_button_text()
	update_runtime_button_state()
	hint_label.text = status_message

func update_hero_button_text() -> void:
	for hero_index in range(mini(hero_buttons.size(), heroes.size())):
		var hero_button: Button = hero_buttons[hero_index]
		var hero: Variant = heroes[hero_index]
		if not is_instance_valid(hero_button) or not is_instance_valid(hero):
			continue
		var title: String = hero.hero_name
		if hero.carrying_crystal:
			title += " C"
		if hero_index == selected_hero_index:
			title = "[%s]" % title
		hero_button.text = title

func update_runtime_button_state() -> void:
	var inventory_open: bool = inventory_overlay != null and inventory_overlay.visible
	if crystal_action_button != null:
		crystal_action_button.visible = not inventory_open and crystal_prompt_visible and crystal_holder == null and crystal_ground_room != INVALID_ROOM and rooms.has(crystal_ground_room) and rooms[crystal_ground_room]["opened"]
		crystal_action_button.disabled = not can_selected_hero_pick_up_crystal()
		crystal_action_button.text = "Carry" if crystal_action_button.disabled == false else "Hero Needed"
		if crystal_action_button.visible:
			var crystal_screen: Vector2 = world_to_screen(crystal_world_position())
			crystal_action_button.position = crystal_screen + Vector2(36.0, -36.0)
	if exit_button != null:
		exit_button.visible = not inventory_open and carrier_in_exit_room()
		exit_button.disabled = not carrier_in_exit_room()

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
	if not room["opened"] or not room["lit"] or room_coord == crystal_room:
		return false
	if room["minor_modules"].size() < int(room["minor_slots"]):
		return true
	for module_data in room["minor_modules"]:
		if float(module_data["health"]) < MINOR_MODULE_MAX_HEALTH:
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
		return "Turret Needs Light"
	if room["minor_modules"].size() < int(room["minor_slots"]):
		return "Place Turret (3)"
	for module_data in room["minor_modules"]:
		if float(module_data["health"]) < MINOR_MODULE_MAX_HEALTH:
			return "Repair Turret"
	return "Turrets Full"

func can_build_or_repair_major(room_coord: Vector2i, module_type: String) -> bool:
	if not rooms.has(room_coord):
		return false
	var room: Dictionary = rooms[room_coord]
	if int(room["major_slots"]) <= 0:
		return false
	if room["major_module_type"] == "":
		return true
	return String(room["major_module_type"]) == module_type and float(room["major_health"]) < MAJOR_MODULE_MAX_HEALTH

func any_room_can_build_or_repair_major(module_type: String) -> bool:
	for room_coord_variant in rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if can_manage_modules(room_coord) and can_build_or_repair_major(room_coord, module_type):
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
		MAJOR_MODULE_FOOD:
			return "Food Module"
		MAJOR_MODULE_SCIENCE:
			return "Science Module"
		MAJOR_MODULE_INDUSTRY:
			return "Industry Module"
		_:
			return "Build"

func build_menu_title_text() -> String:
	if pending_build_type == "":
		return "Build Menu"
	return "%s: tap a slot" % build_type_label(pending_build_type)

func clear_build_mode() -> void:
	pending_build_type = ""

func select_build_mode(module_type: String) -> void:
	build_menu_open = true
	pending_build_type = module_type
	status_message = "%s selected. Tap a matching slot in the room you want." % build_type_label(module_type)
	update_hud()
	queue_redraw()

func handle_build_tap(world_position: Vector2) -> bool:
	var tapped_room: Vector2i = room_at_world_position(world_position)
	if tapped_room == INVALID_ROOM:
		status_message = "Tap a room slot to place %s." % build_type_label(pending_build_type).to_lower()
		return true
	selected_room = tapped_room
	if not can_manage_modules(tapped_room):
		status_message = "%s must be open and lit before building." % room_title(tapped_room)
		return true
	if pending_build_type == MINOR_MODULE_TURRET:
		var slot_index: int = minor_slot_at_position(tapped_room, world_position)
		if slot_index < 0:
			status_message = "Tap a minor slot in %s to place or repair a turret." % room_title(tapped_room)
			return true
		build_or_repair_turret_at_slot(tapped_room, slot_index)
		return true
	if not major_slot_contains_point(tapped_room, world_position):
		status_message = "Tap the major slot in %s to place or repair that module." % room_title(tapped_room)
		return true
	build_or_repair_major_at_room(tapped_room, pending_build_type)
	return true

func build_or_repair_turret_at_slot(room_coord: Vector2i, slot_index: int) -> void:
	var room: Dictionary = rooms[room_coord]
	var module_index: int = minor_module_index_for_slot(room_coord, slot_index)
	if module_index >= 0:
		var module_data: Dictionary = room["minor_modules"][module_index]
		if float(module_data["health"]) >= MINOR_MODULE_MAX_HEALTH:
			status_message = "That turret slot is already occupied and healthy."
			return
		if industry < 1:
			status_message = "Not enough industry to repair a turret."
			return
		industry -= 1
		module_data["health"] = MINOR_MODULE_MAX_HEALTH
		status_message = "Repaired a turret in %s." % room_title(room_coord)
		return
	if industry < MINOR_TURRET_COST:
		status_message = "Not enough industry for a turret."
		return
	industry -= MINOR_TURRET_COST
	room["minor_modules"].append({
		"type": MINOR_MODULE_TURRET,
		"slot_index": slot_index,
		"health": MINOR_MODULE_MAX_HEALTH,
		"cooldown": 0.2,
	})
	status_message = "Built a laser turret in %s." % room_title(room_coord)

func build_or_repair_major_at_room(room_coord: Vector2i, module_type: String) -> void:
	var room: Dictionary = rooms[room_coord]
	if int(room["major_slots"]) <= 0:
		status_message = "%s has no major module slot." % room_title(room_coord)
		return
	if room["major_module_type"] == "":
		if industry < MAJOR_MODULE_COST:
			status_message = "Not enough industry for a %s." % build_type_label(module_type).to_lower()
			return
		industry -= MAJOR_MODULE_COST
		room["major_module_type"] = module_type
		room["major_health"] = MAJOR_MODULE_MAX_HEALTH
		status_message = "Built a %s in %s." % [build_type_label(module_type).to_lower(), room_title(room_coord)]
		return
	if String(room["major_module_type"]) == module_type and float(room["major_health"]) < MAJOR_MODULE_MAX_HEALTH:
		if industry < 3:
			status_message = "Not enough industry to repair that %s." % build_type_label(module_type).to_lower()
			return
		industry -= 3
		room["major_health"] = MAJOR_MODULE_MAX_HEALTH
		status_message = "Repaired the %s in %s." % [build_type_label(module_type).to_lower(), room_title(room_coord)]
		return
	status_message = "That major slot is already occupied."

func screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position

func world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position

func is_in_bounds(room_coord: Vector2i) -> bool:
	return room_coord.x >= 0 and room_coord.y >= 0 and room_coord.x < GRID_SIZE.x and room_coord.y < GRID_SIZE.y

func _on_light_button_pressed() -> void:
	if not can_toggle_light(selected_room):
		return
	var room: Dictionary = rooms[selected_room]
	if room["lit"]:
		room["lit"] = false
		dust += 1
		status_message = "Darkened %s. Dust returned to the pool." % room_title(selected_room)
	else:
		if dust <= 0:
			status_message = "No dust available to light that room."
			update_hud()
			return
		dust -= 1
		room["lit"] = true
		status_message = "Lit %s. It can no longer spawn a wave." % room_title(selected_room)
	update_hud()
	queue_redraw()

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

func _on_build_button_pressed() -> void:
	build_menu_open = not build_menu_open
	if not build_menu_open:
		clear_build_mode()
		status_message = "Build menu hidden."
	else:
		status_message = "Build menu open. Choose a module, then tap a slot."
	update_hud()
	queue_redraw()

func _on_inventory_button_pressed() -> void:
	var hero: Variant = selected_hero()
	if hero == null:
		return
	clear_ground_item_hold()
	open_hero_inventory(hero)
	status_message = "Inventory open for %s." % hero.hero_name
	update_hud()

func _on_center_button_pressed() -> void:
	mark_camera_interaction()
	camera.global_position = hero_focus_position()
	clamp_camera()

func _on_hero_button_pressed(hero_index: int) -> void:
	if hero_index == selected_hero_index and (inventory_overlay == null or not inventory_overlay.visible):
		var hero: Variant = selected_hero()
		open_hero_inventory(hero)
		return
	select_hero_by_index(hero_index)

func _on_inventory_overlay_changed(items: Array) -> void:
	if inventory_session.is_empty():
		return
	var hero_index: int = int(inventory_session.get("hero_index", -1))
	if hero_index < 0 or hero_index >= heroes.size():
		return
	var hero: Variant = heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return
	hero.inventory_items = items.duplicate(true)
	apply_inventory_stats_to_hero(hero)
	inventory_overlay.refresh_state(build_inventory_stat_lines(hero, hero.inventory_items), food, level_up_food_cost(hero.level), hero_can_level_up(hero), hero.level, hero.pack_modules)
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
	hero.pack_modules = pack_modules.duplicate(true)
	apply_inventory_stats_to_hero(hero)
	inventory_overlay.refresh_state(build_inventory_stat_lines(hero, hero.inventory_items), food, level_up_food_cost(hero.level), hero_can_level_up(hero), hero.level, hero.pack_modules)
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
	if grant_level_up_pack_to_hero(hero):
		status_message = "%s reached level %d." % [hero.hero_name, hero.level]
	else:
		status_message = "Not enough food or no room for another pack."
	apply_inventory_stats_to_hero(hero)
	inventory_overlay.refresh_state(build_inventory_stat_lines(hero, hero.inventory_items), food, level_up_food_cost(hero.level), hero_can_level_up(hero), hero.level, hero.pack_modules)
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
