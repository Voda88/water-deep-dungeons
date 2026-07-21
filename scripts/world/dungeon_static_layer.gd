extends Node2D

const DOOR_VISUAL_WIDTH: float = 42.0
const DOOR_VISUAL_THICKNESS: float = 10.0
const WALLS_FLOOR_TEXTURE: Texture2D = preload("res://assets/dungeon/tileset/walls_floor.png")
const CRACKS_FLOOR_TEXTURE: Texture2D = preload("res://assets/dungeon/tileset/decorative_cracks_floor.png")
const CRACKS_WALLS_TEXTURE: Texture2D = preload("res://assets/dungeon/tileset/decorative_cracks_walls.png")
const WATER_DETAIL_TEXTURE: Texture2D = preload("res://assets/dungeon/tileset/water_detilazation_v2.png")
const DOOR_TEXTURE: Texture2D = preload("res://assets/dungeon/tileset/doors_lever_chest_animation.png")
const ROCK_TILE_REGION: Rect2 = Rect2(0.0, 0.0, 32.0, 32.0)
const FLOOR_TILE_REGION: Rect2 = Rect2(48.0, 48.0, 32.0, 32.0)
const FLOOR_ALT_TILE_REGION: Rect2 = Rect2(80.0, 48.0, 32.0, 32.0)
const FLOOR_CRACK_REGION: Rect2 = Rect2(0.0, 0.0, 32.0, 32.0)
const WALL_CRACK_REGION: Rect2 = Rect2(0.0, 0.0, 32.0, 32.0)
const DOOR_TILE_REGION: Rect2 = Rect2(32.0, 32.0, 32.0, 32.0)

static var atlas_texture_cache: Dictionary = {}

var game = null

func configure(next_game) -> void:
	game = next_game
	queue_redraw()

func rebuild() -> void:
	queue_redraw()

static func atlas_region(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var cache_key: String = "%s:%s:%s:%s:%s" % [texture.resource_path, region.position.x, region.position.y, region.size.x, region.size.y]
	if atlas_texture_cache.has(cache_key):
		return atlas_texture_cache[cache_key]
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	atlas_texture_cache[cache_key] = atlas
	return atlas

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(Vector2(-2400.0, -1800.0), Vector2(4800.0, 3600.0)), Color("0c1418"), true)
	draw_dungeon_connections()
	draw_rooms()
	draw_frontier_doors()

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
	draw_tiled_overlay(rect.grow(-4.0), CRACKS_FLOOR_TEXTURE, FLOOR_CRACK_REGION, Color(edge.r, edge.g, edge.b, 0.24))
	var center: Vector2 = rect.get_center()
	var radius: float = minf(rect.size.x, rect.size.y) * 0.18
	draw_circle(center + Vector2(-rect.size.x * 0.16, 0.0), radius, Color(edge.r, edge.g, edge.b, 0.18))
	draw_circle(center + Vector2(rect.size.x * 0.12, rect.size.y * 0.06), radius * 0.92, Color(edge.r, edge.g, edge.b, 0.15))

func draw_tiled_overlay(rect: Rect2, texture: Texture2D, region: Rect2, modulate: Color = Color.WHITE) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	draw_texture_rect(atlas_region(texture, region), rect, true, modulate)

func draw_room_backdrop(rect: Rect2, palette: Dictionary, lit: bool) -> void:
	var cave_fill: Color = palette.get("base_fill", Color("191812"))
	var cave_outline: Color = palette.get("base_outline", Color(0.33, 0.30, 0.24, 0.32))
	draw_soft_rect(rect.grow(-2.0), cave_fill, cave_outline, 1.6)
	draw_tiled_overlay(rect.grow(-6.0), WALLS_FLOOR_TEXTURE, ROCK_TILE_REGION, Color(1.0, 1.0, 1.0, 0.17 if lit else 0.11))
	draw_tiled_overlay(rect.grow(-8.0), CRACKS_WALLS_TEXTURE, WALL_CRACK_REGION, Color(cave_outline.r, cave_outline.g, cave_outline.b, 0.28 if lit else 0.18))

func draw_walkable_region(rect: Rect2, palette: Dictionary, geometry_id: String, lit: bool) -> void:
	var stone_fill: Color = palette.get("floor_fill", Color("4d4638"))
	var stone_outline: Color = palette.get("floor_outline", Color("8b826f"))
	var stone_grain: Color = palette.get("floor_grain", Color("605847"))
	draw_soft_rect(rect, stone_fill, stone_outline, 2.4)
	var floor_region: Rect2 = FLOOR_TILE_REGION
	if geometry_id == "stream_vertical" or geometry_id == "moss_terraces":
		floor_region = FLOOR_ALT_TILE_REGION
	draw_tiled_overlay(rect.grow(-5.0), WALLS_FLOOR_TEXTURE, floor_region, Color(1.0, 1.0, 1.0, 0.30 if lit else 0.22))
	draw_tiled_overlay(rect.grow(-7.0), CRACKS_FLOOR_TEXTURE, FLOOR_CRACK_REGION, Color(stone_grain.r, stone_grain.g, stone_grain.b, 0.24 if lit else 0.18))
	if rect.size.x >= rect.size.y:
		draw_line(
			Vector2(rect.position.x + 12.0, rect.get_center().y),
			Vector2(rect.end.x - 12.0, rect.get_center().y),
			stone_grain,
			1.3,
			true
		)
	else:
		draw_line(
			Vector2(rect.get_center().x, rect.position.y + 12.0),
			Vector2(rect.get_center().x, rect.end.y - 12.0),
			stone_grain,
			1.3,
			true
		)

func draw_obstacle_region(rect: Rect2, palette: Dictionary, lit: bool) -> void:
	var obstacle_fill: Color = palette.get("obstacle_fill", palette.get("base_fill", Color("171510")))
	var obstacle_outline: Color = palette.get("obstacle_outline", palette.get("base_outline", Color("2e2a23")))
	draw_soft_rect(rect, obstacle_fill, obstacle_outline, 1.4)
	draw_tiled_overlay(rect.grow(-4.0), WALLS_FLOOR_TEXTURE, ROCK_TILE_REGION, Color(1.0, 1.0, 1.0, 0.18 if lit else 0.12))
	draw_tiled_overlay(rect.grow(-6.0), CRACKS_WALLS_TEXTURE, WALL_CRACK_REGION, Color(obstacle_outline.r, obstacle_outline.g, obstacle_outline.b, 0.18))

func draw_crystal_room_accent(room_coord: Vector2i, palette: Dictionary) -> void:
	var center: Vector2 = game.room_center(room_coord)
	draw_arc(center, 34.0, 0.0, TAU, 32, palette.get("floor_outline", Color("ffd98c")), 2.2, true)
	draw_arc(center, 20.0, 0.0, TAU, 24, Color(1.0, 0.92, 0.70, 0.32), 1.6, true)

func draw_room_door_marker(room_coord: Vector2i, neighbor: Vector2i, accessible: bool) -> void:
	if game == null or not game.rooms.has(room_coord) or not game.rooms.has(neighbor):
		return
	var rect: Rect2 = game.room_rect(room_coord)
	var doorway: Vector2 = game.doorway_position(room_coord, neighbor)
	var delta: Vector2i = neighbor - room_coord
	var opening_half_width: float = DOOR_VISUAL_WIDTH * 0.5
	var background_color: Color = Color("0c1418")
	var threshold_fill: Color = Color("dbefff") if accessible else Color("f4d892")
	var threshold_shadow: Color = Color("31434d") if accessible else Color("685639")
	var door_plate_size: Vector2 = Vector2(32.0, 32.0)
	if delta.x != 0:
		var edge_x: float = rect.end.x if delta.x > 0 else rect.position.x
		var gap_rect: Rect2 = Rect2(Vector2(edge_x - 4.0, doorway.y - opening_half_width), Vector2(8.0, DOOR_VISUAL_WIDTH))
		draw_rect(gap_rect, background_color, true)
		var threshold_rect: Rect2 = Rect2(Vector2(edge_x - 2.0, doorway.y - opening_half_width + 2.0), Vector2(4.0, DOOR_VISUAL_WIDTH - 4.0))
		draw_rect(threshold_rect, threshold_shadow, true)
		draw_line(Vector2(edge_x, doorway.y - opening_half_width + 4.0), Vector2(edge_x, doorway.y + opening_half_width - 4.0), threshold_fill, DOOR_VISUAL_THICKNESS, true)
		draw_texture_rect(atlas_region(DOOR_TEXTURE, DOOR_TILE_REGION), Rect2(doorway - door_plate_size * 0.5, door_plate_size), false, Color(1.0, 1.0, 1.0, 0.9 if accessible else 0.82))
	else:
		var edge_y: float = rect.end.y if delta.y > 0 else rect.position.y
		var gap_rect_h: Rect2 = Rect2(Vector2(doorway.x - opening_half_width, edge_y - 4.0), Vector2(DOOR_VISUAL_WIDTH, 8.0))
		draw_rect(gap_rect_h, background_color, true)
		var threshold_rect_h: Rect2 = Rect2(Vector2(doorway.x - opening_half_width + 2.0, edge_y - 2.0), Vector2(DOOR_VISUAL_WIDTH - 4.0, 4.0))
		draw_rect(threshold_rect_h, threshold_shadow, true)
		draw_line(Vector2(doorway.x - opening_half_width + 4.0, edge_y), Vector2(doorway.x + opening_half_width - 4.0, edge_y), threshold_fill, DOOR_VISUAL_THICKNESS, true)
		draw_texture_rect(atlas_region(DOOR_TEXTURE, DOOR_TILE_REGION), Rect2(doorway - door_plate_size * 0.5, door_plate_size), false, Color(1.0, 1.0, 1.0, 0.9 if accessible else 0.82))

func draw_dungeon_connections() -> void:
	if game == null:
		return
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if not game.rooms[neighbor]["opened"]:
				continue
			if room_coord.x > neighbor.x or (room_coord.x == neighbor.x and room_coord.y > neighbor.y):
				continue
			var passage_color: Color = Color("8aa8b7")
			var doorway_a: Vector2 = game.doorway_position(room_coord, neighbor)
			var doorway_b: Vector2 = game.doorway_position(neighbor, room_coord)
			draw_line(doorway_a, doorway_b, passage_color.darkened(0.35), DOOR_VISUAL_WIDTH + 2.0, true)
			draw_line(doorway_a, doorway_b, passage_color, DOOR_VISUAL_WIDTH * 0.58, true)

func draw_frontier_doors() -> void:
	if game == null:
		return
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		for neighbor_variant in game.rooms[room_coord]["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if game.rooms[neighbor]["opened"]:
				continue
			var doorway: Vector2 = game.doorway_position(room_coord, neighbor)
			var direction: Vector2 = (game.room_center(neighbor) - game.room_center(room_coord)).normalized()
			var outer_position: Vector2 = doorway + direction * 14.0
			var tangent: Vector2 = Vector2(-direction.y, direction.x)
			draw_line(doorway - direction * 5.0, outer_position, Color("fff4cb"), 9.0, true)
			draw_line(doorway - direction * 3.0, outer_position, Color("7a6745"), 3.0, true)
			draw_circle(outer_position, 12.0, Color("203039"))
			draw_arc(outer_position, 13.0, 0.0, TAU, 28, Color("f6e39d"), 3.0, true)
			draw_line(outer_position - tangent * 5.0, outer_position + tangent * 5.0, Color("f6e39d"), 2.2, true)
			draw_line(outer_position - direction * 5.0, outer_position + direction * 5.0, Color("f6e39d"), 2.2, true)

func draw_rooms() -> void:
	if game == null:
		return
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		var room: Dictionary = game.rooms[room_coord]
		var rect: Rect2 = game.room_rect(room_coord)
		var palette: Dictionary = game.room_theme_palette(String(room.get("theme_id", "cavern")), bool(room["lit"]), bool(room["crystal"]))
		var lit: bool = bool(room["lit"])
		draw_room_backdrop(rect, palette, lit)
		for liquid_region_variant in game.room_layout_regions(room_coord, "liquid_regions", 0.0):
			var liquid_region: Rect2 = Rect2(liquid_region_variant)
			draw_liquid_region(
				liquid_region,
				palette.get("liquid_fill", Color("14110f")),
				palette.get("liquid_glow", Color(0.16, 0.13, 0.10, 0.08)),
				palette.get("liquid_outline", Color("393227"))
			)
			draw_tiled_overlay(liquid_region.grow(-6.0), WATER_DETAIL_TEXTURE, Rect2(Vector2.ZERO, WATER_DETAIL_TEXTURE.get_size()), Color(0.70, 0.92, 1.0, 0.22 if lit else 0.15))
		for growth_region_variant in game.room_layout_regions(room_coord, "growth_regions", 0.0):
			var growth_region: Rect2 = Rect2(growth_region_variant)
			draw_growth_region(
				growth_region,
				palette.get("growth_fill", Color(0.13, 0.12, 0.10, 0.42)),
				palette.get("growth_edge", Color("4a4339"))
			)
		for obstacle_region_variant in game.room_layout_regions(room_coord, "obstacle_regions", 0.0):
			var obstacle_region: Rect2 = Rect2(obstacle_region_variant)
			draw_obstacle_region(obstacle_region, palette, lit)
		for walkable_region_variant in game.room_walkable_regions(room_coord, 0.0):
			var walkable_region: Rect2 = Rect2(walkable_region_variant)
			draw_walkable_region(walkable_region, palette, String(room.get("geometry_id", "")), lit)
		if bool(room.get("crystal", false)):
			draw_crystal_room_accent(room_coord, palette)
		for neighbor_variant in room["neighbors"]:
			var neighbor: Vector2i = neighbor_variant
			if not game.rooms.has(neighbor):
				continue
			draw_room_door_marker(room_coord, neighbor, bool(game.rooms[neighbor]["opened"]))
