@tool
extends Node2D

const DOOR_TEXTURE: Texture2D = preload("res://assets/dungeon/tileset/doors_lever_chest_animation.png")
const DOOR_SCALE: Vector2 = Vector2(1.35, 1.35)
const DOOR_Z_INDEX: int = 6
const DOOR_SELF_MODULATE: Color = Color(1.85, 1.75, 1.62, 1.0)
const DOOR_GLOW_MODULATE: Color = Color(1.0, 0.9, 0.72, 0.34)
const DOOR_GLOW_SCALE_MULTIPLIER: float = 1.18
const DIRECTION_NAMES: Array[String] = ["Left", "Right", "Up", "Down"]

var _last_signature: String = ""

func _enter_tree() -> void:
	_rebuild_if_needed(true)

func _ready() -> void:
	_rebuild_if_needed(true)
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_rebuild_if_needed()

func _rebuild_if_needed(force: bool = false) -> void:
	var signature: String = _build_signature()
	if not force and signature == _last_signature:
		return
	_last_signature = signature
	for direction_name in DIRECTION_NAMES:
		var marker: Marker2D = _door_marker(direction_name)
		var direction_root: Node2D = _ensure_direction_root(direction_name)
		if marker == null:
			direction_root.visible = false
			continue
		direction_root.visible = true
		direction_root.position = marker.position
		_configure_glow_sprite(_ensure_sprite(direction_root, "ClosedGlow"), direction_name, false)
		_configure_glow_sprite(_ensure_sprite(direction_root, "OpenGlow"), direction_name, true)
		_configure_sprite(_ensure_sprite(direction_root, "Closed"), direction_name, false)
		_configure_sprite(_ensure_sprite(direction_root, "Open"), direction_name, true)

func _build_signature() -> String:
	var parts: PackedStringArray = []
	for direction_name in DIRECTION_NAMES:
		var marker: Marker2D = _door_marker(direction_name)
		if marker == null:
			parts.append("%s:none" % direction_name)
			continue
		parts.append("%s:%s" % [direction_name, str(marker.position)])
	return "|".join(parts)

func _doors_root() -> Node:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return null
	return parent_node.get_node_or_null(^"Doors")

func _door_marker(direction_name: String) -> Marker2D:
	var doors_root: Node = _doors_root()
	if doors_root == null:
		return null
	return doors_root.get_node_or_null(NodePath(direction_name)) as Marker2D

func _ensure_direction_root(direction_name: String) -> Node2D:
	var direction_root: Node2D = get_node_or_null(NodePath(direction_name)) as Node2D
	if direction_root == null:
		direction_root = Node2D.new()
		direction_root.name = direction_name
		add_child(direction_root)
	return direction_root

func _ensure_sprite(direction_root: Node2D, sprite_name: String) -> Sprite2D:
	var sprite: Sprite2D = direction_root.get_node_or_null(NodePath(sprite_name)) as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = sprite_name
		direction_root.add_child(sprite)
	return sprite

func _configure_sprite(sprite: Sprite2D, direction_name: String, opened: bool) -> void:
	var region_rect: Rect2 = _door_region(direction_name, opened)
	sprite.texture = DOOR_TEXTURE
	sprite.centered = false
	sprite.z_index = DOOR_Z_INDEX
	sprite.scale = DOOR_SCALE
	sprite.self_modulate = DOOR_SELF_MODULATE
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = true
	sprite.region_rect = region_rect
	sprite.position = _door_offset(direction_name, region_rect.size, DOOR_SCALE)
	sprite.show_behind_parent = false
	sprite.visible = not opened

func _configure_glow_sprite(sprite: Sprite2D, direction_name: String, opened: bool) -> void:
	var glow_scale: Vector2 = DOOR_SCALE * DOOR_GLOW_SCALE_MULTIPLIER
	var region_rect: Rect2 = _door_region(direction_name, opened)
	sprite.texture = DOOR_TEXTURE
	sprite.centered = false
	sprite.z_index = DOOR_Z_INDEX - 1
	sprite.scale = glow_scale
	sprite.self_modulate = DOOR_GLOW_MODULATE
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = true
	sprite.region_rect = region_rect
	sprite.position = _door_offset(direction_name, region_rect.size, glow_scale)
	sprite.show_behind_parent = true
	sprite.visible = not opened

func _door_region(direction_name: String, opened: bool) -> Rect2:
	match direction_name:
		"Left":
			return Rect2(48, 32, 16, 31) if opened else Rect2(16, 32, 16, 31)
		"Right":
			return Rect2(32, 32, 16, 31) if opened else Rect2(0, 32, 16, 31)
		"Up":
			return Rect2(32, 48, 32, 16) if opened else Rect2(0, 48, 32, 16)
		"Down":
			return Rect2(32, 32, 32, 16) if opened else Rect2(0, 32, 32, 16)
		_:
			return Rect2(0, 32, 32, 32)

func _door_offset(direction_name: String, region_size: Vector2, sprite_scale: Vector2 = DOOR_SCALE) -> Vector2:
	var scaled_size: Vector2 = Vector2(region_size.x * sprite_scale.x, region_size.y * sprite_scale.y)
	match direction_name:
		"Left":
			return Vector2(0.0, -scaled_size.y * 0.5)
		"Right":
			return Vector2(-scaled_size.x, -scaled_size.y * 0.5)
		"Up":
			return Vector2(-scaled_size.x * 0.5, 0.0)
		"Down":
			return Vector2(-scaled_size.x * 0.5, -scaled_size.y)
		_:
			return Vector2.ZERO
