extends SceneTree

const TILESET_PATH := "res://resources/dungeon_walkable_tileset.tres"
const TEXTURE_PATH := "res://assets/dungeon/tileset/walls_floor.png"
const TILE_SIZE := Vector2i(16, 16)
const SLICE_ROW_COUNTS: Array[int] = [6, 6, 6, 5]

func _init() -> void:
	var source_image: Image = Image.load_from_file(ProjectSettings.globalize_path(TEXTURE_PATH))
	if source_image == null or source_image.is_empty():
		push_error("Missing texture at %s" % TEXTURE_PATH)
		quit(1)
		return

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = TILE_SIZE

	var texture_width: int = source_image.get_width()
	var texture_height: int = source_image.get_height()
	var total_rows: int = texture_height / TILE_SIZE.y
	var row_start: int = 0
	var source_id: int = 0
	for row_count in SLICE_ROW_COUNTS:
		if row_start >= total_rows:
			break
		var bounded_row_count: int = mini(row_count, total_rows - row_start)
		if bounded_row_count <= 0:
			continue
		var slice_height: int = bounded_row_count * TILE_SIZE.y
		var slice_image: Image = Image.create_empty(texture_width, slice_height, false, source_image.get_format())
		slice_image.blit_rect(
			source_image,
			Rect2i(0, row_start * TILE_SIZE.y, texture_width, slice_height),
			Vector2i.ZERO
		)
		var slice_texture: ImageTexture = ImageTexture.create_from_image(slice_image)
		slice_texture.resource_name = "walls_floor_rows_%d_%d" % [row_start, row_start + bounded_row_count - 1]

		var atlas_source: TileSetAtlasSource = TileSetAtlasSource.new()
		atlas_source.texture = slice_texture
		atlas_source.texture_region_size = TILE_SIZE
		atlas_source.resource_name = "rows_%d_%d" % [row_start, row_start + bounded_row_count - 1]

		var columns: int = texture_width / TILE_SIZE.x
		for y in range(bounded_row_count):
			for x in range(columns):
				atlas_source.create_tile(Vector2i(x, y))

		tile_set.add_source(atlas_source, source_id)
		source_id += 1
		row_start += bounded_row_count

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources"))
	var save_result: Error = ResourceSaver.save(tile_set, TILESET_PATH)
	if save_result != OK:
		push_error("Could not save %s" % TILESET_PATH)
		quit(1)
		return
	quit()
