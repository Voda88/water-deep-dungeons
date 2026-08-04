extends RefCounted

const EFFECT_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const NECROMANCER_ATTACK_EFFECT: Texture2D = preload("res://assets/characters/packs/pack01/projectiles/magic/Necromancer_Sumon_Effect.png")
const LOOT_CHEST_TEXTURE: Texture2D = preload("res://assets/dungeon/tileset/doors_lever_chest_animation.png")
const MERCHANT_DEMONESS_IDLE_TEXTURE: Texture2D = preload("res://assets/characters/packs/pack02/characters_split_100x100/Demoness_A/Demoness_A/Demoness_A_Idle.png")
const LOOT_CHEST_FRAME_SIZE: Vector2i = Vector2i(32, 32)
const LOOT_CHEST_FRAME_ORIGIN: Vector2i = Vector2i(0, 128)
const LOOT_CHEST_ANIM_FRAME_COUNT: int = 5
const MERCHANT_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const MERCHANT_DRAW_SIZE: Vector2 = Vector2(124.0, 124.0)
const PROJECTILE_AIM_PREVIEW_CARD_IDS: Dictionary = {
	"fireball_card": true,
	"magic_missile_card": true,
	"scorching_ray_card": true,
	"dagger_card": true,
	"axe_card": true,
}

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
	var card_id: String = String(hand_card.get("card_id", ""))
	var preview: Dictionary = {
		"hero": hero,
		"card": hand_card,
		"target_data": target_data,
		"valid": game.hand_card_phase_allows_play(hand_card) and game.card_target_is_valid(hero, hand_card, target_world_position),
		"world_position": Vector2(target_data.get("world_position", target_world_position)),
	}
	var target_room: Vector2i = target_data.get("room", game.INVALID_ROOM)
	if bool(preview.get("valid", false)) and target_room != game.INVALID_ROOM and card_id != "evasive_roll_card" and card_id != "whirling_blade_card":
		var cast_room: Vector2i = game.best_card_cast_room(game.active_hero_room_for_commands(hero), target_room, hand_card, Vector2(preview.get("world_position", target_world_position)))
		preview["cast_room"] = cast_room
		preview["valid"] = cast_room != game.INVALID_ROOM
	return preview

static func card_uses_projectile_target_indicator(card_id: String) -> bool:
	return PROJECTILE_AIM_PREVIEW_CARD_IDS.has(card_id)

static func draw_shield_bash_sector_indicator(game: Node, preview: Dictionary, target_position: Vector2, fill_color: Color, outline_color: Color) -> void:
	var preview_hero: Variant = preview.get("hero", null)
	if preview_hero == null or not is_instance_valid(preview_hero):
		return
	var card_preview: Dictionary = Dictionary(preview.get("card", {}))
	var origin: Vector2 = preview_hero.global_position
	var aim_direction: Vector2 = (target_position - origin).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.LEFT if bool(preview_hero.get("visual_facing_left")) else Vector2.RIGHT
	var impact_radius: float = maxf(float(card_preview.get("impact_radius", 138.0)), 18.0)
	var arc_angle_degrees: float = clampf(float(card_preview.get("arc_angle_deg", 110.0)), 10.0, 180.0)
	var half_arc_radians: float = deg_to_rad(arc_angle_degrees * 0.5)
	var start_angle: float = aim_direction.angle() - half_arc_radians
	var end_angle: float = aim_direction.angle() + half_arc_radians
	var point_count: int = maxi(16, int(round(arc_angle_degrees / 5.0)))
	var sector_points: PackedVector2Array = PackedVector2Array([origin])
	for point_index in range(point_count + 1):
		var interpolation: float = float(point_index) / float(point_count)
		var angle: float = lerpf(start_angle, end_angle, interpolation)
		sector_points.append(origin + Vector2.RIGHT.rotated(angle) * impact_radius)
	var sector_fill: Color = fill_color
	sector_fill.a = 0.2 if bool(preview.get("valid", false)) else 0.1
	game.draw_colored_polygon(sector_points, sector_fill)
	var left_edge: Vector2 = origin + Vector2.RIGHT.rotated(start_angle) * impact_radius
	var right_edge: Vector2 = origin + Vector2.RIGHT.rotated(end_angle) * impact_radius
	game.draw_line(origin, left_edge, outline_color, 2.4, true)
	game.draw_line(origin, right_edge, outline_color, 2.4, true)
	game.draw_arc(origin, impact_radius, start_angle, end_angle, point_count * 2, outline_color, 3.0, true)
	game.draw_line(origin, origin + aim_direction * impact_radius, Color(outline_color.r, outline_color.g, outline_color.b, outline_color.a * 0.72), 1.8, true)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 120.0)
	var reticle_radius: float = 8.0 + pulse * 3.2
	game.draw_arc(target_position, reticle_radius, 0.0, TAU, 28, Color(outline_color.r, outline_color.g, outline_color.b, outline_color.a * 0.76), 1.8, true)

static func draw_projectile_target_indicator(game: Node, preview: Dictionary, target_position: Vector2, target_room: Vector2i, preview_color: Color, outline_color: Color) -> void:
	var preview_hero: Variant = preview.get("hero", null)
	if preview_hero == null or not is_instance_valid(preview_hero):
		return
	var card_preview: Dictionary = Dictionary(preview.get("card", {}))
	var card_id: String = String(card_preview.get("card_id", ""))
	var valid_preview: bool = bool(preview.get("valid", false))
	var origin: Vector2 = preview_hero.global_position
	var aim_direction: Vector2 = (target_position - origin).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.RIGHT
	var guide_glow: Color = Color(preview_color.r, preview_color.g, preview_color.b, 0.28 if valid_preview else 0.14)
	var guide_core: Color = Color(0.98, 0.99, 1.0, 0.78 if valid_preview else 0.38)
	game.draw_line(origin, target_position, guide_glow, 9.0, true)
	game.draw_line(origin, target_position, guide_core, 3.2, true)

	if card_id == "dagger_card":
		var dagger_count: int = maxi(1, int(card_preview.get("projectile_count", 3)))
		var dagger_spread: float = float(card_preview.get("spread", 0.16))
		var guide_length: float = minf(maxf(origin.distance_to(target_position), 56.0), 220.0)
		for projectile_index in range(dagger_count):
			var offset_ratio: float = 0.0 if dagger_count == 1 else (float(projectile_index) / float(dagger_count - 1) - 0.5) * 2.0
			var spread_direction: Vector2 = aim_direction.rotated(offset_ratio * dagger_spread)
			var spread_end: Vector2 = origin + spread_direction * guide_length
			game.draw_line(origin, spread_end, Color(preview_color.r, preview_color.g, preview_color.b, 0.5 if valid_preview else 0.22), 2.0, true)

	if card_id == "magic_missile_card" or card_id == "scorching_ray_card":
		var shot_count: int = clampi(maxi(1, int(card_preview.get("projectile_count", 3))), 1, 8)
		var ring_radius: float = 10.0 + float(shot_count) * 1.8
		for shot_index in range(shot_count):
			var angle: float = TAU * float(shot_index) / float(shot_count)
			var marker_position: Vector2 = target_position + Vector2.RIGHT.rotated(angle) * ring_radius
			game.draw_circle(marker_position, 2.8, Color(preview_color.r, preview_color.g, preview_color.b, 0.86 if valid_preview else 0.42))

	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 115.0)
	var reticle_radius: float = 12.0 + pulse * 4.0
	game.draw_arc(target_position, reticle_radius, 0.0, TAU, 36, outline_color, 2.4, true)
	game.draw_line(target_position + Vector2(-reticle_radius - 6.0, 0.0), target_position + Vector2(-reticle_radius + 1.0, 0.0), outline_color, 2.0, true)
	game.draw_line(target_position + Vector2(reticle_radius - 1.0, 0.0), target_position + Vector2(reticle_radius + 6.0, 0.0), outline_color, 2.0, true)
	game.draw_line(target_position + Vector2(0.0, -reticle_radius - 6.0), target_position + Vector2(0.0, -reticle_radius + 1.0), outline_color, 2.0, true)
	game.draw_line(target_position + Vector2(0.0, reticle_radius - 1.0), target_position + Vector2(0.0, reticle_radius + 6.0), outline_color, 2.0, true)

	if target_room != game.INVALID_ROOM and game.rooms.has(target_room):
		var room_bounds: Rect2 = game.room_rect(target_room).grow(-8.0)
		if room_bounds.has_point(target_position):
			var room_center: Vector2 = room_bounds.get_center()
			var room_center_hint: Vector2 = room_center + (target_position - room_center).normalized() * 18.0
			game.draw_line(room_center, room_center_hint, Color(preview_color.r, preview_color.g, preview_color.b, 0.44 if valid_preview else 0.22), 1.8, true)

static func draw_active_hand_card_target_preview(game: Node) -> void:
	var preview: Dictionary = active_hand_drag_target_preview(game)
	if preview.is_empty():
		return
	var target_data: Dictionary = Dictionary(preview.get("target_data", {}))
	if target_data.is_empty():
		return
	var card_preview: Dictionary = Dictionary(preview.get("card", {}))
	var card_id: String = String(card_preview.get("card_id", ""))
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
			var projectile_card_preview: bool = card_uses_projectile_target_indicator(card_id)
			var shield_bash_preview: bool = card_id == "shield_bash_card"
			var room_highlight_rect: Rect2 = game.room_rect(target_room).grow(-8.0)
			game.draw_rect(room_highlight_rect, fill_color, true)
			game.draw_rect(room_highlight_rect, outline_color, false, 4.0)
			var target_position: Vector2 = Vector2(preview.get("world_position", game.room_center(target_room)))
			if shield_bash_preview:
				draw_shield_bash_sector_indicator(game, preview, target_position, fill_color, outline_color)
			else:
				var indicator_radius: float = clampf(float(card_preview.get("impact_radius", card_preview.get("radius", 28.0))), 22.0, 86.0)
				if projectile_card_preview:
					indicator_radius = clampf(float(card_preview.get("radius", card_preview.get("impact_radius", 16.0))), 10.0, 34.0)
				var indicator_fill: Color = fill_color
				indicator_fill.a = 0.18 if bool(preview.get("valid", false)) else 0.12
				game.draw_circle(target_position, indicator_radius, indicator_fill)
				game.draw_arc(target_position, indicator_radius, 0.0, TAU, 40, outline_color, 3.0, true)
			if projectile_card_preview:
				draw_projectile_target_indicator(game, preview, target_position, target_room, preview_color, outline_color)
			if card_id == "lightning_bolt_card":
				var preview_hero: Variant = preview.get("hero", null)
				if preview_hero != null and is_instance_valid(preview_hero):
					var bounce_count: int = maxi(0, int(card_preview.get("bounce_count", 2)))
					var bolt_points: Array = game.build_lightning_bolt_points(preview_hero.global_position, target_position, target_room, bounce_count)
					if bolt_points.size() >= 2:
						for point_index in range(1, bolt_points.size()):
							var segment_start: Vector2 = Vector2(bolt_points[point_index - 1])
							var segment_end: Vector2 = Vector2(bolt_points[point_index])
							game.draw_line(segment_start, segment_end, Color(1.0, 0.98, 0.86, 0.82 if bool(preview.get("valid", false)) else 0.42), 8.0, true)
							game.draw_line(segment_start, segment_end, Color(preview_color.r, preview_color.g, preview_color.b, 0.92 if bool(preview.get("valid", false)) else 0.5), 4.8, true)
						for point_variant in bolt_points:
							game.draw_circle(Vector2(point_variant), 4.2, Color(preview_color.r, preview_color.g, preview_color.b, 0.75 if bool(preview.get("valid", false)) else 0.42))
	if target_data.has("hero"):
		var target_hero: Variant = target_data.get("hero", null)
		if target_hero != null and is_instance_valid(target_hero):
			game.draw_circle(target_hero.global_position, 30.0, fill_color)
			game.draw_arc(target_hero.global_position, 30.0, 0.0, TAU, 36, outline_color, 4.0, true)
	if card_id == "speed_dash_card":
		var dash_hero: Variant = preview.get("hero", null)
		if dash_hero != null and is_instance_valid(dash_hero):
			var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 90.0)
			var dash_radius: float = 26.0 + pulse * 5.5
			game.draw_circle(dash_hero.global_position, dash_radius + 7.0, Color(preview_color.r, preview_color.g, preview_color.b, 0.12 if bool(preview.get("valid", false)) else 0.06))
			game.draw_arc(dash_hero.global_position, dash_radius, 0.0, TAU, 44, outline_color, 3.2, true)

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
	var marker_lead: float = maxf(float(game.WAVE_PRESPAWN_MARKER_LEAD), 0.0)
	var effect_frame: int = animated_effect_frame_index(NECROMANCER_ATTACK_EFFECT, 0.052)
	for pending_spawn_variant in game.pending_enemy_spawns:
		var pending_spawn: Dictionary = pending_spawn_variant
		if Vector2i(pending_spawn.get("room", game.INVALID_ROOM)) != room_coord:
			continue
		var positions: Array = Array(pending_spawn.get("positions", []))
		var spawned_count: int = int(pending_spawn.get("spawned", 0))
		var delay_left: float = float(pending_spawn.get("delay_left", 0.0))
		var interval: float = maxf(float(pending_spawn.get("interval", game.WAVE_STAGGER_ENEMY_INTERVAL)), 0.0)
		for spawn_index in range(spawned_count, positions.size()):
			var index_offset: int = spawn_index - spawned_count
			var time_until_spawn: float = maxf(delay_left, 0.0) + float(index_offset) * interval
			if time_until_spawn > marker_lead:
				continue
			var spawn_position: Vector2 = Vector2(positions[spawn_index])
			if not view_rect.has_point(spawn_position):
				continue
			var pulse_alpha: float = clampf(0.94 - float(index_offset) * 0.08, 0.72, 0.94)
			var pulse_wave: float = 0.9 + 0.1 * sin(float(Time.get_ticks_msec()) / 95.0 + float(index_offset) * 0.55)
			draw_effect_strip(game, NECROMANCER_ATTACK_EFFECT, effect_frame, spawn_position + Vector2(0.0, -4.0), Vector2(124.0, 124.0), Color(1.0, 0.95, 0.86, minf(pulse_alpha * pulse_wave, 1.0)))

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

static func room_loot_chest_position(game: Node, room_coord: Vector2i, room: Dictionary) -> Vector2:
	if not Array(room.get("ground_items", [])).is_empty():
		var first_ground_item: Dictionary = Dictionary(room["ground_items"][0])
		return game.clamp_point_to_room(Vector2(first_ground_item.get("position", game.room_center(room_coord))), room_coord)
	return game.room_walkable_center(room_coord)

static func draw_room_loot_chest(game: Node, room_coord: Vector2i, room: Dictionary, lit: bool) -> void:
	var item_count: int = int(Array(room.get("ground_items", [])).size())
	if item_count <= 0:
		return
	var chest_position: Vector2 = room_loot_chest_position(game, room_coord, room)
	if LOOT_CHEST_TEXTURE != null:
		var chest_frame_index: int = int(floor(float(Time.get_ticks_msec()) / 135.0)) % LOOT_CHEST_ANIM_FRAME_COUNT
		var source_rect: Rect2 = Rect2(
			float(LOOT_CHEST_FRAME_ORIGIN.x + chest_frame_index * LOOT_CHEST_FRAME_SIZE.x),
			float(LOOT_CHEST_FRAME_ORIGIN.y),
			float(LOOT_CHEST_FRAME_SIZE.x),
			float(LOOT_CHEST_FRAME_SIZE.y)
		)
		var draw_rect: Rect2 = Rect2(chest_position + Vector2(-18.0, -16.0), Vector2(36.0, 36.0))
		game.draw_texture_rect_region(LOOT_CHEST_TEXTURE, draw_rect, source_rect, Color(1.0, 1.0, 1.0, 0.96), false, true)
	else:
		game.draw_rect(Rect2(chest_position + Vector2(-12.0, -2.0), Vector2(24.0, 16.0)), Color("9f6b2c"), true)
		game.draw_rect(Rect2(chest_position + Vector2(-12.0, -2.0), Vector2(24.0, 16.0)), Color("f3d79e"), false, 2.0)
	game.draw_string(ThemeDB.fallback_font, chest_position + Vector2(-14.0, 32.0), "Loot x%d" % item_count, HORIZONTAL_ALIGNMENT_LEFT, 52.0, 12, Color("fff0c7" if lit else "d7be8d"))

static func draw_room_merchant_visual(game: Node, room_coord: Vector2i, room: Dictionary, lit: bool) -> void:
	if String(room.get("merchant_theme", "")) == "":
		return
	if MERCHANT_DEMONESS_IDLE_TEXTURE == null:
		return
	var merchant_position: Vector2 = game.merchant_world_position(room_coord)
	var frame_count: int = maxi(int(MERCHANT_DEMONESS_IDLE_TEXTURE.get_width() / maxf(float(MERCHANT_FRAME_SIZE.x), 1.0)), 1)
	var frame_index: int = 0
	if frame_count > 1:
		frame_index = int(floor(float(Time.get_ticks_msec()) / 120.0)) % frame_count
	var source_rect: Rect2 = Rect2(float(frame_index * MERCHANT_FRAME_SIZE.x), 0.0, float(MERCHANT_FRAME_SIZE.x), float(MERCHANT_FRAME_SIZE.y))
	var draw_rect: Rect2 = Rect2(merchant_position + Vector2(-MERCHANT_DRAW_SIZE.x * 0.5, -MERCHANT_DRAW_SIZE.y + 30.0), MERCHANT_DRAW_SIZE)
	var shadow_center: Vector2 = merchant_position + Vector2(0.0, 10.0)
	var sprite_tint: Color = Color.WHITE if lit else Color(0.73, 0.78, 0.82, 0.88)
	game.draw_texture_rect_region(MERCHANT_DEMONESS_IDLE_TEXTURE, draw_rect, source_rect, sprite_tint, false, true)
	game.draw_string(ThemeDB.fallback_font, shadow_center + Vector2(-30.0, -30.0), "Merchant", HORIZONTAL_ALIGNMENT_LEFT, 68.0, 13, Color("eaf6ff"))

static func room_wave_torch_waves_left(game: Node, room: Dictionary) -> int:
	var expiry_wave: int = int(room.get("wave_torch_until_wave", -1))
	if expiry_wave < 0:
		return 0
	if game.wave_index < expiry_wave:
		return expiry_wave - game.wave_index
	if game.wave_index == expiry_wave and game.wave_in_progress():
		return 1
	return 0

static func draw_room_light_marker(game: Node, room_coord: Vector2i, room: Dictionary) -> void:
	if room_coord == game.crystal_room or not bool(room.get("lit", false)):
		return
	var marker_base: Vector2 = game.room_rect(room_coord).position + Vector2(28.0, 28.0)
	var permanent_light: bool = bool(room.get("permanent_light", false))
	var seeded_permanent_light: bool = permanent_light and bool(room.get("permanent_light_seeded", false))
	var temporary_turns_left: int = int(room.get("temporary_light_turns", 0))
	var wave_torch_waves_left: int = room_wave_torch_waves_left(game, room)
	var temporary_light_active: bool = temporary_turns_left > 0 or wave_torch_waves_left > 0
	if not permanent_light and not temporary_light_active:
		game.draw_circle(marker_base, 11.0, Color("fff49c"))
		return
	var shaft_start: Vector2 = marker_base + Vector2(0.0, 7.0)
	var shaft_end: Vector2 = marker_base + Vector2(0.0, 18.0)
	game.draw_line(shaft_start, shaft_end, Color("7f6144"), 3.0, true)
	var flame_shell: Color = Color("ffab47")
	var flame_core: Color = Color("fff0bc")
	if seeded_permanent_light:
		flame_shell = Color("73c8ff")
		flame_core = Color("e5f7ff")
	elif not permanent_light:
		flame_shell = Color("7ed8ff")
		flame_core = Color("ebf8ff")
	var glow_color: Color = Color(flame_shell.r, flame_shell.g, flame_shell.b, 0.26)
	game.draw_circle(marker_base + Vector2(0.0, 2.0), 9.0, glow_color)
	game.draw_circle(marker_base + Vector2(0.0, 2.0), 6.0, flame_shell)
	game.draw_circle(marker_base + Vector2(0.0, 0.5), 3.2, flame_core)
	var marker_label: String = ""
	if permanent_light:
		marker_label = "P"
	elif wave_torch_waves_left > 0:
		marker_label = str(wave_torch_waves_left)
	elif temporary_turns_left > 0:
		marker_label = str(temporary_turns_left)
	if marker_label != "":
		var label_shadow: Color = Color(0.02, 0.05, 0.08, 0.62)
		var label_color: Color = Color("d8f2ff") if seeded_permanent_light else (Color("ffe6c0") if permanent_light else Color("d9f5ff"))
		var label_position: Vector2 = marker_base + Vector2(10.0, 8.0)
		game.draw_string(ThemeDB.fallback_font, label_position + Vector2(1.0, 1.0), marker_label, HORIZONTAL_ALIGNMENT_LEFT, 22.0, 12, label_shadow)
		game.draw_string(ThemeDB.fallback_font, label_position, marker_label, HORIZONTAL_ALIGNMENT_LEFT, 22.0, 12, label_color)

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
		var room: Dictionary = game.rooms[room_coord]
		var opened: bool = bool(room.get("opened", false))
		var scry_revealed: bool = bool(room.get("scry_revealed", false))
		if not opened and not scry_revealed:
			continue
		var rect: Rect2 = game.room_rect(room_coord)
		if not view_rect.intersects(rect):
			continue
		if scry_revealed and not opened:
			var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 210.0 + float(room_coord.x + room_coord.y) * 0.2)
			var scry_fill: Color = Color(0.30, 0.68, 0.92, 0.12 + 0.05 * pulse)
			var scry_outline: Color = Color(0.68, 0.90, 1.0, 0.74)
			game.draw_rect(rect.grow(-8.0), scry_fill, true)
			game.draw_rect(rect.grow(-8.0), scry_outline, false, 2.2)
			var sigil_center: Vector2 = rect.get_center() + Vector2(0.0, -10.0)
			game.draw_arc(sigil_center, 24.0 + 2.0 * pulse, 0.0, TAU, 36, Color(0.76, 0.94, 1.0, 0.54), 2.2, true)
			game.draw_string(ThemeDB.fallback_font, rect.position + Vector2(14.0, 22.0), "SCRY", HORIZONTAL_ALIGNMENT_LEFT, 56.0, 12, Color("d8f4ff"))
			continue
		var warning_ratio: float = clampf(float(room.get("warning_timer_left", 0.0)) / maxf(game.WAVE_WARNING_DURATION, 0.001), 0.0, 1.0)
		var sanctuary_ratio: float = clampf(float(room.get("sanctuary_time_left", 0.0)) / maxf(float(room.get("sanctuary_duration", room.get("sanctuary_time_left", 1.0))), 0.001), 0.0, 1.0)
		if float(room.get("sanctuary_time_left", 0.0)) > 0.0:
			var aura_pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 150.0 + float(room_coord.x - room_coord.y) * 0.33)
			var aura_inset: float = 10.0 + 5.0 * aura_pulse
			game.draw_rect(rect.grow(-aura_inset), Color(0.88, 1.0, 0.72, 0.08 + 0.05 * aura_pulse), false, 3.0)
			var sanctuary_label: String = "Sanctuary %ds" % int(ceil(float(room.get("sanctuary_time_left", 0.0))))
			game.draw_string(ThemeDB.fallback_font, rect.position + Vector2(12.0, rect.size.y - 12.0), sanctuary_label, HORIZONTAL_ALIGNMENT_LEFT, 118.0, 12, Color(0.93, 1.0, 0.82, 0.78 + 0.18 * sanctuary_ratio))
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
		draw_room_light_marker(game, room_coord, room)
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
					var shimmer: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 140.0)
					game.draw_circle(major_position, 26.0 + 3.0 * shimmer, Color(0.54, 0.85, 1.0, 0.16 + 0.08 * shimmer))
					game.draw_circle(major_position, 18.0 + 2.0 * shimmer, Color(0.68, 0.93, 1.0, 0.22 + 0.10 * shimmer))
					var pulse_radius: float = lerpf(20.0, 32.0, pulse_phase)
					var pulse_alpha: float = 0.36 * (1.0 - pulse_phase)
					game.draw_arc(major_position, pulse_radius, 0.0, TAU, 36, Color(0.55, 0.86, 1.0, pulse_alpha), 3.0, true)
					game.draw_arc(major_position, 24.0 + 2.0 * shimmer, 0.0, TAU, 40, Color(0.86, 0.98, 1.0, 0.46 + 0.18 * shimmer), 2.2, true)
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
		draw_room_loot_chest(game, room_coord, room, bool(room.get("lit", false)))
		draw_room_merchant_visual(game, room_coord, room, bool(room.get("lit", false)))
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
	if not game.rooms.has(room_coord):
		return "Unknown Chamber"
	var room: Dictionary = game.rooms[room_coord]
	if not bool(room.get("opened", false)):
		if bool(room.get("scry_revealed", false)):
			var theme_name: String = String(room.get("template_name", "Room"))
			return "%s, %s, scry-revealed (still sealed)" % [room_title(game, room_coord), theme_name]
		return "Unknown Chamber"
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
	var merchant_suffix: String = ""
	var merchant_theme: String = String(room.get("merchant_theme", ""))
	if merchant_theme != "":
		var merchant_name: String = "Merchant"
		match merchant_theme:
			"food":
				merchant_name = "Food Merchant"
			"materials":
				merchant_name = "Materials Merchant"
			"arcana":
				merchant_name = "Arcana Merchant"
			"dust":
				merchant_name = "Dust Merchant"
		var stock_count: int = Array(room.get("merchant_stock", [])).size()
		var buyback_count: int = Array(room.get("merchant_buyback", [])).size()
		merchant_suffix = ", %s (%d offers, %d buyback)" % [merchant_name, stock_count, buyback_count]
	return "%s, %s, %s, %s, %s%s" % [room_title(game, room_coord), String(room.get("template_name", "Room")), state, light_state, "%s, %s" % [minor_text, major_text], merchant_suffix]

static func can_toggle_light(game: Node, room_coord: Vector2i) -> bool:
	if not game.rooms.has(room_coord) or not game.rooms[room_coord]["opened"] or room_coord == game.crystal_room or game.game_over:
		return false
	var room: Dictionary = game.rooms[room_coord]
	if bool(room.get("permanent_light", false)) and bool(room.get("permanent_light_seeded", false)) and bool(room.get("lit", false)):
		return false
	return true

static func can_manage_modules(game: Node, room_coord: Vector2i) -> bool:
	return game.rooms.has(room_coord) and game.rooms[room_coord]["opened"] and game.rooms[room_coord]["lit"] and room_coord != game.crystal_room and not game.game_over

static func can_open_build_for_room(game: Node, room_coord: Vector2i) -> bool:
	return game.rooms.has(room_coord) and game.rooms[room_coord]["opened"] and room_coord != game.crystal_room and not game.game_over

static func toggle_room_light(game: Node, room_coord: Vector2i) -> void:
	if not can_toggle_light(game, room_coord):
		if game.rooms.has(room_coord) and bool(game.rooms[room_coord].get("permanent_light", false)) and bool(game.rooms[room_coord].get("lit", false)):
			game.status_message = "%s is permanently lit and cannot be darkened." % room_title(game, room_coord)
			game.update_hud()
			game.queue_redraw()
		return
	var room: Dictionary = game.rooms[room_coord]
	if room["lit"]:
		var was_permanent: bool = bool(room.get("permanent_light", false))
		var was_seeded_permanent: bool = bool(room.get("permanent_light_seeded", false))
		room["permanent_light"] = false
		room["permanent_light_seeded"] = false
		room["temporary_light_turns"] = 0
		room["wave_torch_until_wave"] = -1
		if was_permanent and not was_seeded_permanent:
			game.dust += game.ROOM_LIGHT_DUST_COST
			game.status_message = "Darkened %s. %d dust returned to the pool." % [room_title(game, room_coord), game.ROOM_LIGHT_DUST_COST]
		else:
			game.status_message = "Darkened %s." % room_title(game, room_coord)
	else:
		if game.dust < game.ROOM_LIGHT_DUST_COST:
			game.status_message = "Need %d dust to light that room." % game.ROOM_LIGHT_DUST_COST
			game.update_hud()
			game.queue_redraw()
			return
		game.dust -= game.ROOM_LIGHT_DUST_COST
		room["permanent_light"] = true
		room["permanent_light_seeded"] = false
		room["temporary_light_turns"] = 0
		room["wave_torch_until_wave"] = -1
		game.status_message = "Lit %s for %d dust. It can no longer spawn a wave." % [room_title(game, room_coord), game.ROOM_LIGHT_DUST_COST]
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
	if game.dust < game.ROOM_LIGHT_DUST_COST:
		game.status_message = "%s is dark. Build needs %d dust to light it first." % [room_title(game, room_coord), game.ROOM_LIGHT_DUST_COST]
		return false
	game.dust -= game.ROOM_LIGHT_DUST_COST
	room["permanent_light"] = true
	room["permanent_light_seeded"] = false
	room["temporary_light_turns"] = 0
	room["wave_torch_until_wave"] = -1
	game.status_message = "Lit %s for building (%d dust)." % [room_title(game, room_coord), game.ROOM_LIGHT_DUST_COST]
	game.refresh_room_lighting_states()
	return true
