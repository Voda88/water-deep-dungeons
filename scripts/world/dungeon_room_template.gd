@tool
extends Node2D

const DOOR_VISUAL_WIDTH: float = 42.0
const PREVIEW_BACKGROUND: Color = Color(0.05, 0.07, 0.08, 0.65)
const BACKDROP_NODE_PATH: NodePath = ^"Art/RoomBackdrop"
const INNER_WALL_NODE_PATH: NodePath = ^"Art/InnerWall"
const DUNGEON_TILEMAP_NODE_PATH: NodePath = ^"Art/DungeonTileMap"
const WATER_TILEMAP_NODE_PATH: NodePath = ^"Art/WaterTileMap"
const DOOR_ART_ROOT_PATH: NodePath = ^"DoorArt"
const TEMPLATE_GEOMETRY = preload("res://scripts/world/dungeon_room_template_geometry.gd")
const TEMPLATE_VISUALS = preload("res://scripts/world/dungeon_room_template_visuals.gd")

@export var template_id: String = "nook"
@export var template_name: String = "Nook"
@export var room_size: Vector2 = Vector2(300.0, 200.0)
@export var default_minor_slots: int = 2
@export var default_major_slots: int = 0
@export var preview_theme_id: String = "cavern"
@export var preview_lit: bool = false
@export var preview_crystal: bool = false
@export var preview_left_door: bool = true
@export var preview_right_door: bool = true
@export var preview_up_door: bool = true
@export var preview_down_door: bool = true
@export var dark_room_modulate: Color = Color(0.20, 0.22, 0.28, 1.0)

var runtime_game = null
var runtime_room_coord: Vector2i = Vector2i.ZERO
var runtime_room: Dictionary = {}

func _ready() -> void:
	sync_control_input_passthrough()
	refresh_room_visuals()

func apply_room_state(next_game, room_coord: Vector2i, room_data: Dictionary) -> void:
	runtime_game = next_game
	runtime_room_coord = room_coord
	runtime_room = room_data.duplicate(true)
	sync_control_input_passthrough()
	refresh_room_visuals()

func build_template_metadata() -> Dictionary:
	return TEMPLATE_GEOMETRY.build_template_metadata(self)

func room_theme_palette(theme_id: String, lit: bool, crystal_chamber: bool) -> Dictionary:
	return TEMPLATE_VISUALS.room_theme_palette(self, theme_id, lit, crystal_chamber)

func current_theme_id() -> String:
	return TEMPLATE_VISUALS.current_theme_id(self)

func current_lit() -> bool:
	return TEMPLATE_VISUALS.current_lit(self)

func current_crystal() -> bool:
	return TEMPLATE_VISUALS.current_crystal(self)

func current_door_dirs() -> Array:
	return TEMPLATE_VISUALS.current_door_dirs(self)

func direction_key_to_vector(direction_key: String) -> Vector2i:
	return TEMPLATE_VISUALS.direction_key_to_vector(direction_key)

func local_point_to_normalized(local_point: Vector2) -> Vector2:
	return TEMPLATE_GEOMETRY.local_point_to_normalized(self, local_point)

func backdrop_local_rect() -> Rect2:
	return TEMPLATE_GEOMETRY.backdrop_local_rect(self)

func interior_local_rect() -> Rect2:
	return TEMPLATE_GEOMETRY.interior_local_rect(self)

func wall_thickness() -> float:
	return TEMPLATE_GEOMETRY.wall_thickness(self)

func clamped_interior_edge_position(direction_key: String, marker_position: Vector2) -> Vector2:
	return TEMPLATE_GEOMETRY.clamped_interior_edge_position(self, direction_key, marker_position)

func door_positions_normalized() -> Dictionary:
	return TEMPLATE_GEOMETRY.door_positions_normalized(self)

func door_art_opened(direction_key: String) -> bool:
	return TEMPLATE_VISUALS.door_art_opened(self, direction_key)

func minor_slot_positions_normalized() -> Array:
	return TEMPLATE_GEOMETRY.minor_slot_positions_normalized(self)

func walkable_region_specs_normalized() -> Array:
	return TEMPLATE_GEOMETRY.walkable_region_specs_normalized(self)

func slot_regions_normalized() -> Array:
	return TEMPLATE_GEOMETRY.slot_regions_normalized(self)

func door_dir_keys(door_dirs: Array) -> Dictionary:
	return TEMPLATE_VISUALS.door_dir_keys(door_dirs)

func sync_control_input_passthrough() -> void:
	TEMPLATE_VISUALS.sync_control_input_passthrough(self)

func sync_backdrop_visuals() -> void:
	TEMPLATE_VISUALS.sync_backdrop_visuals(self)

func sync_tilemap_lighting() -> void:
	TEMPLATE_VISUALS.sync_tilemap_lighting(self)

func sync_door_art() -> void:
	TEMPLATE_VISUALS.sync_door_art(self)

func refresh_room_visuals() -> void:
	TEMPLATE_VISUALS.refresh_room_visuals(self)
