extends RefCounted

const EFFECT_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const NECROMANCER_ATTACK_EFFECT: Texture2D = preload("res://assets/characters/packs/pack01/projectiles/magic/Necromancer_Attack02_Effect.png")

static func _draw(game: Node) -> void:
	draw_room_overlays(game)
	draw_active_hand_card_target_preview(game)
	draw_floating_resource_texts(game)
	game.draw_room_action_hold()
	game.draw_room_action_menu()
	game.draw_combat_hand()

static func active_hand_drag_target_preview(game: Node) -> Dictionary:
	if game.active_hand_drag.is_empty():
		return {}
	var hero_index: int = int(game.active_hand_drag.get("hero_index", -1))
	if hero_index < 0 or hero_index >= game.heroes.size():
		return {}
	var hero: Variant = game.heroes[hero_index]
	if hero == null or not is_instance_valid(hero):
		return {}
	var current_screen: Vector2 = Vector2(game.active_hand_drag.get("current_screen", Vector2.ZERO))
	if game.combat_hand_panel_rect(hero).grow(18.0).has_point(current_screen):
		return {}
	var hand_card: Dictionary = Dictionary(game.active_hand_drag.get("card", {}))
	var target_world_position: Vector2 = screen_to_world(game, current_screen)
	var target_data: Dictionary = game.resolve_card_target(hero, hand_card, target_world_position)
	if target_data.is_empty():
		return {}
	var preview: Dictionary = {
		"hero": hero,
		"card": hand_card,
		"target_data": target_data,
		"valid": game.hand_card_phase_allows_play(hand_card),
		"world_position": Vector2(target_data.get("world_position", target_world_position)),
	}
	var target_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
	if bool(preview.get("valid", false)) and target_room != game.INVALID_ROOM:
		var cast_room: Vector2i = game.best_card_cast_room(game.active_hero_room_for_commands(hero), target_room, hand_card, Vector2(preview.get("world_position", target_world_position)))
		preview["cast_room"] = cast_room
		preview["valid"] = cast_room != game.INVALID_ROOM
	return preview

static func draw_active_hand_card_target_preview(game: Node) -> void:
	var preview: Dictionary = active_hand_drag_target_preview(game)
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
		var target_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
		if target_room != game.INVALID_ROOM and game.rooms.has(target_room):
			var room_highlight_rect: Rect2 = game.room_rect(target_room).grow(-8.0)
			game.draw_rect(room_highlight_rect, fill_color, true)
			game.draw_rect(room_highlight_rect, outline_color, false, 4.0)
			var target_position: Vector2 = Vector2(preview.get("world_position", game.room_center(target_room)))
			var indicator_radius: float = clampf(float(card_preview.get("impact_radius", card_preview.get("radius", 28.0))), 22.0, 86.0)
			var indicator_fill: Color = fill_color
			indicator_fill.a = 0.18 if bool(preview.get("valid", false)) else 0.12
			game.draw_circle(target_position, indicator_radius, indicator_fill)
			game.draw_arc(target_position, indicator_radius, 0.0, TAU, 40, outline_color, 3.0, true)
	if target_data.has("hero"):
		var target_hero: Variant = target_data.get("hero", null)
		if target_hero != null and is_instance_valid(target_hero):
			game.draw_circle(target_hero.global_position, 30.0, fill_color)
			game.draw_arc(target_hero.global_position, 30.0, 0.0, TAU, 36, outline_color, 4.0, true)

static func screen_to_world(game: Node, screen_position: Vector2) -> Vector2:
	return game.get_viewport().get_canvas_transform().affine_inverse() * screen_position

static func world_to_screen(game: Node, world_position: Vector2) -> Vector2:
	return game.get_viewport().get_canvas_transform() * world_position

static func screen_rect_to_world_rect(game: Node, screen_rect: Rect2) -> Rect2:
	var top_left: Vector2 = screen_to_world(game, screen_rect.position)
	var bottom_right: Vector2 = screen_to_world(game, screen_rect.position + screen_rect.size)
	return Rect2(top_left, bottom_right - top_left)

static func current_view_world_rect(game: Node, padding: float = 0.0) -> Rect2:
	var world_rect: Rect2 = screen_rect_to_world_rect(game, Rect2(Vector2.ZERO, game.get_viewport_rect().size))
	return world_rect.abs().grow(padding)

static func effect_frame_count(texture: Texture2D) -> int:
	if texture == null:
		return 1
	return maxi(int(texture.get_width() / float(EFFECT_FRAME_SIZE.x)), 1)

static func animated_effect_frame_index(texture: Texture2D, seconds_per_frame: float = 0.06) -> int:
	var frame_count: int = effect_frame_count(texture)
	if frame_count <= 1:
		return 0
	return int(floor(float(Time.get_ticks_msec()) / maxf(seconds_per_frame * 1000.0, 1.0))) % frame_count

static func draw_effect_strip(surface: CanvasItem, texture: Texture2D, frame_index: int, world_position: Vector2, draw_size: Vector2, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	var frame_count: int = effect_frame_count(texture)
	var clamped_index: int = clampi(frame_index, 0, frame_count - 1)
	var source_rect: Rect2 = Rect2(float(clamped_index * EFFECT_FRAME_SIZE.x), 0.0, float(EFFECT_FRAME_SIZE.x), float(EFFECT_FRAME_SIZE.y))
	var draw_rect: Rect2 = Rect2(world_position - draw_size * 0.5, draw_size)
	surface.draw_texture_rect_region(texture, draw_rect, source_rect, modulate, false, true)

static func draw_room_spawn_warning_effects(game: Node, room_coord: Vector2i, view_rect: Rect2) -> void:
	if NECROMANCER_ATTACK_EFFECT == null:
		return
	var effect_frame: int = animated_effect_frame_index(NECROMANCER_ATTACK_EFFECT, 0.052)
	for pending_spawn_variant in game.pending_enemy_spawns:
		var pending_spawn: Dictionary = pending_spawn_variant
		if Vector2i(pending_spawn.get("room", game.INVALID_ROOM)) != room_coord:
			continue
		var positions: Array = Array(pending_spawn.get("positions", []))
		var spawned_count: int = int(pending_spawn.get("spawned", 0))
		var spawn_interval: float = maxf(float(pending_spawn.get("interval", game.WAVE_STAGGER_ENEMY_INTERVAL)), 0.001)
		var next_delay: float = maxf(float(pending_spawn.get("delay_left", 0.0)), 0.0)
		for spawn_index in range(spawned_count, positions.size()):
			var spawn_position: Vector2 = Vector2(positions[spawn_index])
			if not view_rect.has_point(spawn_position):
				continue
			var index_offset: int = spawn_index - spawned_count
			var time_until_spawn: float = next_delay + float(index_offset) * spawn_interval
			var pulse_alpha: float = clampf(0.62 - float(index_offset) * 0.08, 0.16, 0.62)
			var pulse_wave: float = 0.72 + 0.28 * sin(float(Time.get_ticks_msec()) / 120.0 + float(index_offset) * 0.55)
			var ring_radius: float = 16.0 + clampf(time_until_spawn * 18.0, 0.0, 22.0)
			game.draw_circle(spawn_position, ring_radius, Color(1.0, 0.54, 0.36, 0.05 * pulse_wave))
			game.draw_arc(spawn_position, ring_radius, 0.0, TAU, 28, Color(1.0, 0.66, 0.52, pulse_alpha * pulse_wave), 2.2, true)
			draw_effect_strip(game, NECROMANCER_ATTACK_EFFECT, effect_frame, spawn_position + Vector2(0.0, -4.0), Vector2(96.0, 96.0), Color(1.0, 0.63, 0.44, pulse_alpha))

static func draw_floating_resource_texts(game: Node) -> void:
	var view_rect: Rect2 = current_view_world_rect(game, 96.0)
	for popup_variant in game.floating_resource_texts:
		var popup: Dictionary = popup_variant
		var duration: float = maxf(game.RESOURCE_FLOAT_DURATION, 0.001)
		var life_ratio: float = clampf(1.0 - (float(popup.get("timer_left", 0.0)) / duration), 0.0, 1.0)
		var rise_ratio: float = 1.0 - pow(1.0 - life_ratio, 2.0)
		var fade_ratio: float = clampf(1.0 - maxf(life_ratio - 0.45, 0.0) / 0.55, 0.0, 1.0)
		var popup_position: Vector2 = Vector2(popup.get("position", Vector2.ZERO)) + Vector2(0.0, -game.RESOURCE_FLOAT_RISE * rise_ratio)
		if not view_rect.has_point(popup_position):
			continue
		var popup_color: Color = popup.get("color", Color.WHITE)
		popup_color.a = 0.22 + 0.78 * fade_ratio
		var shadow_color: Color = Color(0.02, 0.06, 0.08, 0.55 * fade_ratio)
		game.draw_string(ThemeDB.fallback_font, popup_position + Vector2(2.0, 2.0), String(popup.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 110.0, 20, shadow_color)
		game.draw_string(ThemeDB.fallback_font, popup_position, String(popup.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 110.0, 20, popup_color)

static func draw_room_door_marker(game: Node, room_coord: Vector2i, neighbor: Vector2i, accessible: bool) -> void:
	if not game.rooms.has(room_coord) or not game.rooms.has(neighbor):
		return
	var rect: Rect2 = game.room_rect(room_coord)
	var doorway: Vector2 = game.doorway_position(room_coord, neighbor)
	var delta: Vector2i = neighbor - room_coord
	var opening_half_width: float = game.DOOR_VISUAL_WIDTH * 0.5
	var background_color: Color = Color("0c1418")
	var threshold_fill: Color = Color("dbefff") if accessible else Color("f4d892")
	var threshold_shadow: Color = Color("31434d") if accessible else Color("685639")
	if delta.x != 0:
		var edge_x: float = rect.end.x if delta.x > 0 else rect.position.x
		var gap_rect: Rect2 = Rect2(Vector2(edge_x - 4.0, doorway.y - opening_half_width), Vector2(8.0, game.DOOR_VISUAL_WIDTH))
		game.draw_rect(gap_rect, background_color, true)
		var threshold_rect: Rect2 = Rect2(Vector2(edge_x - 2.0, doorway.y - opening_half_width + 2.0), Vector2(4.0, game.DOOR_VISUAL_WIDTH - 4.0))
		game.draw_rect(threshold_rect, threshold_shadow, true)
		game.draw_line(Vector2(edge_x, doorway.y - opening_half_width + 4.0), Vector2(edge_x, doorway.y + opening_half_width - 4.0), threshold_fill, game.DOOR_VISUAL_THICKNESS, true)
	else:
		var edge_y: float = rect.end.y if delta.y > 0 else rect.position.y
		var gap_rect_h: Rect2 = Rect2(Vector2(doorway.x - opening_half_width, edge_y - 4.0), Vector2(game.DOOR_VISUAL_WIDTH, 8.0))
		game.draw_rect(gap_rect_h, background_color, true)
		var threshold_rect_h: Rect2 = Rect2(Vector2(doorway.x - opening_half_width + 2.0, edge_y - 2.0), Vector2(game.DOOR_VISUAL_WIDTH - 4.0, 4.0))
		game.draw_rect(threshold_rect_h, threshold_shadow, true)
		game.draw_line(Vector2(doorway.x - opening_half_width + 4.0, edge_y), Vector2(doorway.x + opening_half_width - 4.0, edge_y), threshold_fill, game.DOOR_VISUAL_THICKNESS, true)

static func draw_soft_rect(game: Node, rect: Rect2, fill: Color, outline: Color = Color.TRANSPARENT, outline_width: float = 0.0) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var radius: float = minf(minf(rect.size.x, rect.size.y) * 0.24, 24.0)
	radius = minf(radius, minf(rect.size.x * 0.5, rect.size.y * 0.5))
	var middle_width: float = maxf(rect.size.x - radius * 2.0, 0.0)
	var middle_height: float = maxf(rect.size.y - radius * 2.0, 0.0)
	if middle_width > 0.0:
		game.draw_rect(Rect2(rect.position + Vector2(radius, 0.0), Vector2(middle_width, rect.size.y)), fill, true)
	if middle_height > 0.0:
		game.draw_rect(Rect2(rect.position + Vector2(0.0, radius), Vector2(rect.size.x, middle_height)), fill, true)
	var top_left: Vector2 = rect.position + Vector2(radius, radius)
	var top_right: Vector2 = rect.position + Vector2(rect.size.x - radius, radius)
	var bottom_right: Vector2 = rect.position + Vector2(rect.size.x - radius, rect.size.y - radius)
	var bottom_left: Vector2 = rect.position + Vector2(radius, rect.size.y - radius)
	game.draw_circle(top_left, radius, fill)
	game.draw_circle(top_right, radius, fill)
	game.draw_circle(bottom_right, radius, fill)
	game.draw_circle(bottom_left, radius, fill)
	if outline_width <= 0.0 or outline.a <= 0.0:
		return
	game.draw_line(top_left + Vector2(0.0, -radius), top_right + Vector2(0.0, -radius), outline, outline_width, true)
	game.draw_line(top_right + Vector2(radius, 0.0), bottom_right + Vector2(radius, 0.0), outline, outline_width, true)
	game.draw_line(bottom_left + Vector2(0.0, radius), bottom_right + Vector2(0.0, radius), outline, outline_width, true)
	game.draw_line(top_left + Vector2(-radius, 0.0), bottom_left + Vector2(-radius, 0.0), outline, outline_width, true)
	game.draw_arc(top_left, radius, PI, PI * 1.5, 10, outline, outline_width, true)
	game.draw_arc(top_right, radius, PI * 1.5, TAU, 10, outline, outline_width, true)
	game.draw_arc(bottom_right, radius, 0.0, PI * 0.5, 10, outline, outline_width, true)
	game.draw_arc(bottom_left, radius, PI * 0.5, PI, 10, outline, outline_width, true)

static func draw_liquid_region(game: Node, rect: Rect2, fill: Color, glow: Color, outline: Color) -> void:
	draw_soft_rect(game, rect, fill, outline, 1.6)
	var inner_inset: float = minf(10.0, minf(rect.size.x, rect.size.y) * 0.22)
	if inner_inset > 1.0:
		var inner_rect: Rect2 = rect.grow(-inner_inset)
		draw_soft_rect(game, inner_rect, glow, Color.TRANSPARENT, 0.0)
	var wave_start: Vector2 = rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.50)
	var wave_end: Vector2 = rect.position + Vector2(rect.size.x * 0.82, rect.size.y * 0.50)
	game.draw_line(wave_start, wave_end, Color(glow.r, glow.g, glow.b, minf(glow.a + 0.18, 0.85)), 2.0, true)

static func draw_growth_region(game: Node, rect: Rect2, fill: Color, edge: Color) -> void:
	draw_soft_rect(game, rect, fill, edge, 1.2)
	var center: Vector2 = rect.get_center()
	var radius: float = minf(rect.size.x, rect.size.y) * 0.18
	game.draw_circle(center + Vector2(-rect.size.x * 0.16, 0.0), radius, Color(edge.r, edge.g, edge.b, 0.18))
	game.draw_circle(center + Vector2(rect.size.x * 0.12, rect.size.y * 0.06), radius * 0.92, Color(edge.r, edge.g, edge.b, 0.15))

static func room_theme_palette(game: Node, theme_id: String, lit: bool, crystal_chamber: bool) -> Dictionary:
	var palette: Dictionary = {}
	match theme_id:
		game.FLOOR_THEME_FUNGAL:
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
		game.FLOOR_THEME_RUINS:
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

static func draw_room_overlays(game: Node) -> void:
	var view_rect: Rect2 = current_view_world_rect(game, 160.0)
	for room_coord_variant in game.rooms.keys():
		var room_coord: Vector2i = room_coord_variant
		if not game.rooms[room_coord]["opened"]:
			continue
		var room: Dictionary = game.rooms[room_coord]
		var rect: Rect2 = game.room_rect(room_coord)
		if not view_rect.intersects(rect):
			continue
		var warning_ratio: float = float(room.get("warning_timer_left", 0.0)) / maxf(game.WAVE_WARNING_DURATION, 0.001)
		var room_has_hero: bool = false
		var room_has_selected_hero: bool = false
		for hero in game.heroes:
			if not is_instance_valid(hero):
				continue
			if room_coord == hero.current_room or room_coord == hero.pending_room:
				room_has_hero = true
				if hero == game.selected_hero():
					room_has_selected_hero = true
		if room_coord == game.selected_room:
			game.draw_rect(rect.grow(-10.0), Color("f7f7f2", 0.92), false, 3.0)
		if room_has_hero:
			var marker_color: Color = Color("5f8796")
			if room_has_selected_hero:
				marker_color = Color("7ad7ff")
			var marker_center: Vector2 = rect.position + Vector2(rect.size.x - 24.0, 24.0)
			game.draw_circle(marker_center, 10.0, Color(marker_color.r, marker_color.g, marker_color.b, 0.18))
			game.draw_arc(marker_center, 10.0, 0.0, TAU, 24, marker_color, 2.2, true)
			game.draw_circle(marker_center, 4.0, marker_color)
		if room["lit"] and room_coord != game.crystal_room:
			game.draw_circle(rect.position + Vector2(28.0, 28.0), 11.0, Color("fff49c"))
		if room["major_slots"] > 0 and room_coord != game.crystal_room:
			var major_position: Vector2 = game.major_slot_position(room_coord)
			var pending_major: Dictionary = game.pending_major_construction_for_room(room_coord)
			var show_major_slot: bool = game.should_show_room_slot_guides(room_coord) or game.should_highlight_major_slot(room_coord) or (room["major_module_type"] != "" and float(room["major_health"]) > 0.0) or not pending_major.is_empty()
			if show_major_slot:
				var major_fill: Color = Color(0.08, 0.12, 0.15, 0.34)
				var major_outline: Color = Color("182024")
				if game.should_show_room_slot_guides(room_coord) and not game.should_highlight_major_slot(room_coord):
					major_fill = Color(0.10, 0.14, 0.16, 0.24)
					major_outline = Color(0.82, 0.88, 0.92, 0.78)
				if game.should_highlight_major_slot(room_coord):
					major_fill = Color(1.0, 0.89, 0.61, 0.16)
					major_outline = Color("ffe39b")
				game.draw_rect(Rect2(major_position - Vector2(17.0, 17.0), Vector2(34.0, 34.0)), major_fill, true)
				game.draw_rect(Rect2(major_position - Vector2(17.0, 17.0), Vector2(34.0, 34.0)), major_outline, false, 2.0)
			if room["major_module_type"] != "" and float(room["major_health"]) > 0.0:
				var major_color: Color = Color("f1c26b")
				match String(room["major_module_type"]):
					game.MAJOR_MODULE_FOOD:
						major_color = Color("8ee28a")
					game.MAJOR_MODULE_SCIENCE:
						major_color = Color("8bc1ff")
					game.MAJOR_MODULE_INDUSTRY:
						major_color = Color("f1c26b")
				game.draw_rect(Rect2(major_position - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), major_color, true)
				var major_ratio: float = float(room["major_health"]) / game.MAJOR_MODULE_MAX_HEALTH
				game.draw_rect(Rect2(major_position + Vector2(-20.0, 22.0), Vector2(40.0, 5.0)), Color("1b1610"), true)
				game.draw_rect(Rect2(major_position + Vector2(-20.0, 22.0), Vector2(40.0 * major_ratio, 5.0)), major_color.lightened(0.15), true)
				if bool(room.get("major_under_construction", false)):
					game.draw_string(ThemeDB.fallback_font, major_position + Vector2(-18.0, -20.0), "BUILD", HORIZONTAL_ALIGNMENT_LEFT, 40.0, 12, Color("fff1b7"))
			elif game.room_has_research_crystal(room_coord):
				var pulse_phase: float = fmod(float(Time.get_ticks_msec()) / 1000.0, 1.2) / 1.2
				game.draw_colored_polygon(PackedVector2Array([
					major_position + Vector2(0.0, -16.0),
					major_position + Vector2(14.0, 0.0),
					major_position + Vector2(0.0, 16.0),
					major_position + Vector2(-14.0, 0.0),
				]), Color("87c9ff"))
				game.draw_arc(major_position, 18.0, 0.0, TAU, 28, Color("d9f4ff"), 2.2, true)
				if game.room_has_active_research(room_coord):
					var pulse_radius: float = lerpf(20.0, 32.0, pulse_phase)
					var pulse_alpha: float = 0.36 * (1.0 - pulse_phase)
					game.draw_arc(major_position, pulse_radius, 0.0, TAU, 36, Color(0.55, 0.86, 1.0, pulse_alpha), 3.0, true)
					game.draw_circle(major_position, 8.0 + 3.0 * sin(float(Time.get_ticks_msec()) / 170.0), Color(0.62, 0.88, 1.0, 0.18))
			if not pending_major.is_empty():
				var pending_ratio: float = 1.0 - (float(pending_major.get("timer_left", 0.0)) / maxf(float(pending_major.get("duration", 1.0)), 0.001))
				game.draw_rect(Rect2(major_position - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), Color(1.0, 0.91, 0.69, 0.22), true)
				game.draw_arc(major_position, 19.0, -PI * 0.5, -PI * 0.5 + TAU * pending_ratio, 24, Color("ffe39b"), 3.0, true)
				game.draw_rect(Rect2(major_position + Vector2(-20.0, 30.0), Vector2(40.0, 5.0)), Color("1b1610"), true)
				game.draw_rect(Rect2(major_position + Vector2(-20.0, 30.0), Vector2(40.0 * pending_ratio, 5.0)), Color("ffe39b"), true)
		var slot_positions: Array = game.minor_slot_positions(room_coord)
		for slot_index in range(slot_positions.size()):
			var slot_position: Vector2 = slot_positions[slot_index]
			var module_index: int = game.minor_module_index_for_slot(room_coord, slot_index)
			var pending_minor: Dictionary = game.pending_minor_construction_for_slot(room_coord, slot_index)
			var show_minor_slot: bool = game.should_show_room_slot_guides(room_coord) or game.should_highlight_minor_slot(room_coord, slot_index) or module_index >= 0 or not pending_minor.is_empty()
			if show_minor_slot:
				var slot_fill: Color = Color(0.08, 0.12, 0.15, 0.44)
				var slot_outline: Color = Color(0.68, 0.84, 0.92, 0.82)
				if game.should_show_room_slot_guides(room_coord) and not game.should_highlight_minor_slot(room_coord, slot_index):
					slot_fill = Color(0.10, 0.14, 0.16, 0.24)
					slot_outline = Color(0.82, 0.88, 0.92, 0.78)
				if game.should_highlight_minor_slot(room_coord, slot_index):
					slot_fill = Color("23323a")
					slot_outline = Color("8df6ff")
				game.draw_circle(slot_position, 10.0, slot_fill)
				game.draw_arc(slot_position, 11.0, 0.0, TAU, 24, slot_outline, 2.0, true)
			if module_index >= 0:
				var module_data: Dictionary = room["minor_modules"][module_index]
				if float(module_data["health"]) > 0.0:
					var module_type: String = String(module_data.get("type", game.MINOR_MODULE_TURRET))
					module_type = game.canonical_minor_module_type(module_type)
					var module_color: Color = game.minor_module_color(module_type)
					match module_type:
						game.MINOR_MODULE_PULSE:
							game.draw_circle(slot_position, 8.0, Color(module_color.r, module_color.g, module_color.b, 0.26))
							game.draw_arc(slot_position, 11.0, 0.0, TAU, 20, module_color.lightened(0.12), 2.0, true)
						game.MINOR_MODULE_CANNON:
							game.draw_circle(slot_position, 7.0, module_color)
							game.draw_arc(slot_position, 14.0, 0.0, TAU, 24, module_color.lightened(0.2), 2.0, true)
						game.MINOR_MODULE_KIP:
							game.draw_rect(Rect2(slot_position - Vector2(8.0, 6.0), Vector2(16.0, 12.0)), module_color, true)
							game.draw_line(slot_position + Vector2(0.0, -6.0), slot_position + Vector2(0.0, -18.0), module_color.lightened(0.25), 3.0)
						_:
							game.draw_circle(slot_position, 7.5, module_color)
							game.draw_line(slot_position + Vector2(0.0, -10.0), slot_position + Vector2(0.0, -18.0), module_color.lightened(0.25), 2.0)
					game.draw_string(ThemeDB.fallback_font, slot_position + Vector2(-8.0, -16.0), str(clampi(game.minor_module_level(module_type), 1, 4)), HORIZONTAL_ALIGNMENT_LEFT, 18.0, 12, Color("f5f8fb"))
					if bool(module_data.get("under_construction", false)) or float(module_data["health"]) < game.MINOR_MODULE_MAX_HEALTH:
						var turret_ratio: float = float(module_data["health"]) / game.MINOR_MODULE_MAX_HEALTH
						game.draw_rect(Rect2(slot_position + Vector2(-12.0, 14.0), Vector2(24.0, 4.0)), Color("142026"), true)
						game.draw_rect(Rect2(slot_position + Vector2(-12.0, 14.0), Vector2(24.0 * turret_ratio, 4.0)), module_color, true)
					if bool(module_data.get("under_construction", false)):
						game.draw_string(ThemeDB.fallback_font, slot_position + Vector2(-12.0, -15.0), "B", HORIZONTAL_ALIGNMENT_LEFT, 18.0, 12, Color("fff1b7"))
			if not pending_minor.is_empty():
				var pending_ratio_minor: float = 1.0 - (float(pending_minor.get("timer_left", 0.0)) / maxf(float(pending_minor.get("duration", 1.0)), 0.001))
				game.draw_circle(slot_position, 8.0, Color("b3efff", 0.18))
				game.draw_arc(slot_position, 14.0, -PI * 0.5, -PI * 0.5 + TAU * pending_ratio_minor, 24, Color("8df6ff"), 2.5, true)
		for ground_item_variant in room["ground_items"]:
			var ground_item: Dictionary = ground_item_variant
			var item_rect: Rect2 = game.ground_item_draw_rect(ground_item)
			var item_def: Dictionary = game.item_defs.get(String(ground_item.get("item_id", "")), {})
			var item_color: Color = item_def.get("color", Color("9ed4ff"))
			game.draw_rect(item_rect, item_color, true)
			game.draw_rect(item_rect, Color("f1fbff"), false, 2.0)
			game.draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(4.0, item_rect.size.y * 0.65), String(item_def.get("short", "ITM")), HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 4.0, 12, Color("0d171d"))
			game.draw_arc(item_rect.get_center(), maxf(item_rect.size.x, item_rect.size.y) * 0.55, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.18), 1.5, true)
		if room_coord == game.opening_origin_room:
			var progress_ratio: float = 1.0 - (game.opening_timer_left / game.DOOR_OPEN_DURATION)
			game.draw_rect(rect, Color(1.0, 1.0, 1.0, 0.08), true)
			game.draw_rect(Rect2(rect.position + Vector2(18.0, rect.size.y - 20.0), Vector2(rect.size.x - 36.0, 8.0)), Color("1d2630"), true)
			game.draw_rect(Rect2(rect.position + Vector2(18.0, rect.size.y - 20.0), Vector2((rect.size.x - 36.0) * progress_ratio, 8.0)), Color("f3dfa2"), true)
		if warning_ratio > 0.0:
			var inset: float = 12.0 + 8.0 * (1.0 - warning_ratio)
			game.draw_rect(rect.grow(-inset), Color(1.0, 0.66, 0.52, 0.10 + 0.12 * warning_ratio), false, 4.0)
			draw_room_spawn_warning_effects(game, room_coord, view_rect)
		if room["exit"]:
			var exit_center: Vector2 = rect.get_center() + Vector2(0.0, -12.0)
			game.draw_circle(exit_center, 18.0, Color("203846"))
			game.draw_arc(exit_center, 18.0, 0.0, TAU, 28, Color("a5f7ff"), 3.0, true)
			game.draw_line(exit_center + Vector2(-6.0, 0.0), exit_center + Vector2(10.0, 0.0), Color("a5f7ff"), 3.0, true)
			game.draw_line(exit_center + Vector2(4.0, -6.0), exit_center + Vector2(10.0, 0.0), Color("a5f7ff"), 3.0, true)
			game.draw_line(exit_center + Vector2(4.0, 6.0), exit_center + Vector2(10.0, 0.0), Color("a5f7ff"), 3.0, true)
		if game.crystal_holder == null and game.crystal_ground_room == room_coord:
			var center: Vector2 = rect.get_center()
			game.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -32.0),
				center + Vector2(24.0, 0.0),
				center + Vector2(0.0, 32.0),
				center + Vector2(-24.0, 0.0),
			]), Color("ffe7a1"))

static func room_title(_game: Node, room_coord: Vector2i) -> String:
	return "Room %d-%d" % [room_coord.x + 1, room_coord.y + 1]

static func room_summary(game: Node, room_coord: Vector2i) -> String:
	if room_coord == game.crystal_room:
		var crystal_state: String = "crystal present" if game.crystal_ground_room == game.crystal_room and game.crystal_holder == null else "crystal removed"
		return "Crystal Chamber, permanently lit, %s" % crystal_state
	if not game.rooms.has(room_coord) or not game.rooms[room_coord]["opened"]:
		return "Unknown Chamber"
	var room: Dictionary = game.rooms[room_coord]
	var state: String = "open"
	if room_coord == game.opening_room:
		state = "opening"
	var light_state: String = "lit" if room["lit"] else "dark"
	if room["exit"]:
		light_state += ", exit"
	if game.room_has_active_research(room_coord):
		light_state += ", researching"
	var major_text: String = "major 0/%d" % int(room["major_slots"])
	if game.room_has_research_crystal(room_coord):
		major_text = "research crystal"
	elif int(room["major_slots"]) > 0 and room["major_module_type"] != "":
		major_text = "%s %d%%" % [game.build_type_label(String(room["major_module_type"])), int((float(room["major_health"]) / game.MAJOR_MODULE_MAX_HEALTH) * 100.0)]
	var minor_text: String = "minor %d/%d" % [room["minor_modules"].size(), game.effective_minor_slot_count(room_coord)]
	if game.crystal_ground_room == room_coord and game.crystal_holder == null:
		minor_text += ", crystal here"
	if room["ground_items"].size() > 0:
		minor_text += ", loot %d" % room["ground_items"].size()
	return "%s, %s, %s, %s, %s" % [room_title(game, room_coord), String(room.get("template_name", "Room")), state, light_state, "%s, %s" % [minor_text, major_text]]

static func can_toggle_light(game: Node, room_coord: Vector2i) -> bool:
	return game.rooms.has(room_coord) and game.rooms[room_coord]["opened"] and room_coord != game.crystal_room and not game.game_over

static func can_manage_modules(game: Node, room_coord: Vector2i) -> bool:
	return game.rooms.has(room_coord) and game.rooms[room_coord]["opened"] and game.rooms[room_coord]["lit"] and room_coord != game.crystal_room and not game.game_over

static func can_open_build_for_room(game: Node, room_coord: Vector2i) -> bool:
	return game.rooms.has(room_coord) and game.rooms[room_coord]["opened"] and room_coord != game.crystal_room and not game.game_over

static func toggle_room_light(game: Node, room_coord: Vector2i) -> void:
	if not can_toggle_light(game, room_coord):
		return
	var room: Dictionary = game.rooms[room_coord]
	if room["lit"]:
		var was_permanent: bool = bool(room.get("permanent_light", false))
		room["permanent_light"] = false
		room["temporary_light_turns"] = 0
		room["wave_torch_until_wave"] = -1
		if was_permanent:
			game.dust += 1
			game.status_message = "Darkened %s. Dust returned to the pool." % room_title(game, room_coord)
		else:
			game.status_message = "Darkened %s." % room_title(game, room_coord)
	else:
		if game.dust <= 0:
			game.status_message = "No dust available to light that room."
			game.update_hud()
			game.queue_redraw()
			return
		game.dust -= 1
		room["permanent_light"] = true
		room["temporary_light_turns"] = 0
		room["wave_torch_until_wave"] = -1
		game.status_message = "Lit %s. It can no longer spawn a wave." % room_title(game, room_coord)
	game.refresh_room_lighting_states()
	game.update_hud()
	game.queue_redraw()

static func ensure_room_lit_for_build(game: Node, room_coord: Vector2i) -> bool:
	if not can_open_build_for_room(game, room_coord):
		game.status_message = "That room cannot build modules right now."
		return false
	var room: Dictionary = game.rooms[room_coord]
	if room["lit"]:
		return true
	if game.dust <= 0:
		game.status_message = "%s is dark. Build needs 1 dust to light it first." % room_title(game, room_coord)
		return false
	game.dust -= 1
	room["permanent_light"] = true
	room["temporary_light_turns"] = 0
	room["wave_torch_until_wave"] = -1
	game.status_message = "Lit %s for building." % room_title(game, room_coord)
	game.refresh_room_lighting_states()
	return true
