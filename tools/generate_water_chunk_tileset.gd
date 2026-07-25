extends SceneTree

const SOURCE_IMAGE_PATH := "res://assets/dungeon/source_pack/tiled/Water_coasts_animation.png"
const SOURCE_TMX_PATH := "res://assets/dungeon/source_pack/tiled/Dungeon1.tmx"
const OUTPUT_TILESET_PATH := "res://resources/tilesets/cavern_water_chunk_main.tres"
const TILESET_NAME := "Water_coasts_animation"
const TILE_SIZE := Vector2i(16, 16)
const SOURCE_COLUMNS := 29
const FRAME_COLUMNS := 3
const FRAME_ROWS := 2
const LOGICAL_TILES_PER_ROW := 4
const FRAME_DURATION_SECONDS := 0.15

func _init() -> void:
	var source_image: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_IMAGE_PATH))
	if source_image == null or source_image.is_empty():
		push_error("Missing source water atlas at %s" % SOURCE_IMAGE_PATH)
		quit(1)
		return

	var water_tiles: Array = parse_water_animation_tiles(ProjectSettings.globalize_path(SOURCE_TMX_PATH))
	if water_tiles.is_empty():
		push_error("Could not find any animated water tiles in %s" % SOURCE_TMX_PATH)
		quit(1)
		return

	var curated_image: Image = build_curated_water_image(source_image, water_tiles)
	var curated_texture: ImageTexture = ImageTexture.create_from_image(curated_image)
	curated_texture.resource_name = "cavern_water_chunk_main"

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = TILE_SIZE

	var atlas_source: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas_source.resource_name = "water_chunk_main"
	atlas_source.texture = curated_texture
	atlas_source.texture_region_size = TILE_SIZE

	for index in range(water_tiles.size()):
		var atlas_coords: Vector2i = curated_tile_origin(index)
		atlas_source.create_tile(atlas_coords)
		atlas_source.set_tile_animation_columns(atlas_coords, FRAME_COLUMNS)
		atlas_source.set_tile_animation_frames_count(atlas_coords, FRAME_COLUMNS * FRAME_ROWS)
		atlas_source.set_tile_animation_separation(atlas_coords, Vector2i.ZERO)
		atlas_source.set_tile_animation_speed(atlas_coords, 1.0 / FRAME_DURATION_SECONDS)
		for frame_index in range(FRAME_COLUMNS * FRAME_ROWS):
			atlas_source.set_tile_animation_frame_duration(atlas_coords, frame_index, 1.0)

	tile_set.add_source(atlas_source, 0)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources/tilesets"))
	var save_result: Error = ResourceSaver.save(tile_set, OUTPUT_TILESET_PATH)
	if save_result != OK:
		push_error("Could not save %s" % OUTPUT_TILESET_PATH)
		quit(1)
		return

	print("Saved curated water chunk tileset to %s with %d animated tiles." % [OUTPUT_TILESET_PATH, water_tiles.size()])
	quit()

func parse_water_animation_tiles(tmx_path: String) -> Array:
	var parser: XMLParser = XMLParser.new()
	var open_result: Error = parser.open(tmx_path)
	if open_result != OK:
		return []

	var tiles: Array = []
	var in_target_tileset: bool = false
	var current_tile_id: int = -1
	var current_frames: Array = []

	while true:
		var read_result: Error = parser.read()
		if read_result == ERR_FILE_EOF:
			break
		if read_result != OK:
			break

		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var node_name: String = parser.get_node_name()
				if node_name == "tileset":
					in_target_tileset = parser.get_named_attribute_value_safe("name") == TILESET_NAME
				elif in_target_tileset and node_name == "tile":
					current_tile_id = int(parser.get_named_attribute_value_safe("id"))
					current_frames.clear()
				elif in_target_tileset and node_name == "frame":
					current_frames.append({
						"tileid": int(parser.get_named_attribute_value_safe("tileid")),
						"duration_ms": int(parser.get_named_attribute_value_safe("duration")),
					})
			XMLParser.NODE_ELEMENT_END:
				var end_node_name: String = parser.get_node_name()
				if in_target_tileset and end_node_name == "tile" and current_tile_id >= 0 and not current_frames.is_empty():
					tiles.append({
						"id": current_tile_id,
						"frames": current_frames.duplicate(true),
					})
					current_tile_id = -1
					current_frames.clear()
				elif in_target_tileset and end_node_name == "tileset":
					in_target_tileset = false

	tiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("id", -1)) < int(b.get("id", -1)))
	return tiles

func build_curated_water_image(source_image: Image, water_tiles: Array) -> Image:
	var logical_rows: int = int(ceil(float(water_tiles.size()) / float(LOGICAL_TILES_PER_ROW)))
	var output_size: Vector2i = Vector2i(
		LOGICAL_TILES_PER_ROW * FRAME_COLUMNS * TILE_SIZE.x,
		logical_rows * FRAME_ROWS * TILE_SIZE.y
	)
	var output_image: Image = Image.create_empty(output_size.x, output_size.y, false, Image.FORMAT_RGBA8)

	for tile_index in range(water_tiles.size()):
		var frames: Array = Array(Dictionary(water_tiles[tile_index]).get("frames", []))
		for frame_index in range(frames.size()):
			var source_tile_id: int = int(Dictionary(frames[frame_index]).get("tileid", -1))
			if source_tile_id < 0:
				continue
			var source_cell: Vector2i = Vector2i(source_tile_id % SOURCE_COLUMNS, source_tile_id / SOURCE_COLUMNS)
			var source_rect: Rect2i = Rect2i(source_cell * TILE_SIZE, TILE_SIZE)
			var destination_cell: Vector2i = curated_frame_coords(tile_index, frame_index)
			output_image.blit_rect(source_image, source_rect, destination_cell * TILE_SIZE)
	return output_image

func curated_tile_origin(tile_index: int) -> Vector2i:
	var logical_column: int = tile_index % LOGICAL_TILES_PER_ROW
	var logical_row: int = tile_index / LOGICAL_TILES_PER_ROW
	return Vector2i(logical_column * FRAME_COLUMNS, logical_row * FRAME_ROWS)

func curated_frame_coords(tile_index: int, frame_index: int) -> Vector2i:
	var origin: Vector2i = curated_tile_origin(tile_index)
	return origin + Vector2i(frame_index % FRAME_COLUMNS, frame_index / FRAME_COLUMNS)
