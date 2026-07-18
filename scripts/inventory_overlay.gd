extends Control
class_name InventoryOverlay

signal close_requested
signal inventory_changed(items: Array)
signal item_dropped(item: Dictionary)
signal pack_layout_changed(pack_modules: Array)
signal level_up_requested

const INVALID_CELL: Vector2i = Vector2i(-1, -1)
const BACKDROP_COLOR: Color = Color(0.03, 0.06, 0.08, 0.82)
const PANEL_FILL: Color = Color("122128")
const PANEL_OUTLINE: Color = Color("6c93a3")
const GRID_BG: Color = Color("132028")
const GRID_INACTIVE: Color = Color("10181d")
const GRID_BASE: Color = Color("314149")
const GRID_PACK: Color = Color("2f5567")
const GRID_CELL_OUTLINE: Color = Color("476775")
const GRID_BASE_OUTLINE: Color = Color("e6d18d")
const GRID_PACK_OUTLINE: Color = Color("9de7ff")
const GRID_PACK_HANDLE: Color = Color("dff9ff")
const GRID_PACK_HIGHLIGHT: Color = Color("fff4b0")
const GRID_PACK_SNAP: Color = Color("bdfdff")
const GRID_VALID: Color = Color(0.43, 0.84, 0.58, 0.28)
const GRID_INVALID: Color = Color(0.92, 0.33, 0.29, 0.26)
const ROTATE_FILL: Color = Color("22414b")
const ROTATE_HIGHLIGHT: Color = Color("f1d693")
const LEVEL_BUTTON_FILL: Color = Color("3a5c3d")
const LEVEL_BUTTON_DISABLED: Color = Color("29352a")
const PENDING_BG: Color = Color("1c3038")
const PACK_SNAP_DURATION: float = 0.18

var hero_name: String = ""
var hero_level: int = 1
var food_value: int = 0
var level_up_cost: int = 0
var can_level_up: bool = false
var stats_lines: Array[String] = []
var inventory_canvas_size: Vector2i = Vector2i(9, 8)
var base_origin: Vector2i = Vector2i(3, 3)
var base_size: Vector2i = Vector2i(2, 2)
var pack_modules: Array = []
var item_defs: Dictionary = {}
var items: Array = []
var pending_item: Dictionary = {}
var dragging_item: Dictionary = {}
var dragging_source_index: int = -1
var dragging_from_pending: bool = false
var dragging_pack: Dictionary = {}
var dragging_pack_source_index: int = -1
var drag_pointer_local: Vector2 = Vector2.ZERO
var rotate_hover_latched: bool = false
var highlighted_pack_index: int = -1
var highlighted_pack_timer: float = 0.0
var pack_snap_rect: Rect2 = Rect2()
var pack_snap_timer: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

func _process(delta: float) -> void:
	var needs_redraw: bool = false
	if highlighted_pack_timer > 0.0:
		highlighted_pack_timer = maxf(highlighted_pack_timer - delta, 0.0)
		if highlighted_pack_timer <= 0.0:
			highlighted_pack_index = -1
		needs_redraw = true
	if pack_snap_timer > 0.0:
		pack_snap_timer = maxf(pack_snap_timer - delta, 0.0)
		if pack_snap_timer <= 0.0:
			pack_snap_rect = Rect2()
		needs_redraw = true
	if not needs_redraw:
		return
	queue_redraw()

func configure(next_hero_name: String, next_hero_level: int, next_food_value: int, next_level_up_cost: int, next_can_level_up: bool, next_stats_lines: Array, next_inventory_canvas_size: Vector2i, next_base_origin: Vector2i, next_base_size: Vector2i, next_pack_modules: Array, next_item_defs: Dictionary, next_items: Array, next_pending_item: Dictionary) -> void:
	hero_name = next_hero_name
	hero_level = next_hero_level
	food_value = next_food_value
	level_up_cost = next_level_up_cost
	can_level_up = next_can_level_up
	stats_lines.clear()
	for stat_line_variant in next_stats_lines:
		stats_lines.append(String(stat_line_variant))
	inventory_canvas_size = next_inventory_canvas_size
	base_origin = next_base_origin
	base_size = next_base_size
	pack_modules.clear()
	for pack_variant in next_pack_modules:
		pack_modules.append((pack_variant as Dictionary).duplicate(true))
	item_defs = next_item_defs
	items.clear()
	for item_variant in next_items:
		items.append((item_variant as Dictionary).duplicate(true))
	pending_item = next_pending_item.duplicate(true)
	dragging_item.clear()
	dragging_pack.clear()
	dragging_source_index = -1
	dragging_pack_source_index = -1
	dragging_from_pending = false
	rotate_hover_latched = false
	highlighted_pack_index = -1
	highlighted_pack_timer = 0.0
	pack_snap_rect = Rect2()
	pack_snap_timer = 0.0
	visible = true
	queue_redraw()

func hide_overlay() -> void:
	visible = false
	dragging_item.clear()
	dragging_pack.clear()
	dragging_source_index = -1
	dragging_pack_source_index = -1
	dragging_from_pending = false
	highlighted_pack_index = -1
	highlighted_pack_timer = 0.0
	pack_snap_rect = Rect2()
	pack_snap_timer = 0.0
	queue_redraw()

func refresh_state(next_stats_lines: Array, next_food_value: int, next_level_up_cost: int, next_can_level_up: bool, next_hero_level: int, next_pack_modules: Array) -> void:
	stats_lines.clear()
	for stat_line_variant in next_stats_lines:
		stats_lines.append(String(stat_line_variant))
	food_value = next_food_value
	level_up_cost = next_level_up_cost
	can_level_up = next_can_level_up
	hero_level = next_hero_level
	pack_modules.clear()
	for pack_variant in next_pack_modules:
		pack_modules.append((pack_variant as Dictionary).duplicate(true))
	queue_redraw()

func begin_pending_drag(screen_position: Vector2) -> void:
	if pending_item.is_empty():
		return
	dragging_from_pending = true
	dragging_source_index = -1
	dragging_item = pending_item.duplicate(true)
	drag_pointer_local = screen_to_local(screen_position)
	rotate_hover_latched = false
	queue_redraw()

func pointer_press(screen_position: Vector2) -> void:
	if not visible:
		return
	var local_position: Vector2 = screen_to_local(screen_position)
	if close_button_rect().has_point(local_position):
		close_requested.emit()
		return
	if level_up_button_rect().has_point(local_position) and can_level_up:
		level_up_requested.emit()
		return
	if not dragging_item.is_empty() or not dragging_pack.is_empty():
		return
	if not pending_item.is_empty() and pending_item_rect().has_point(local_position):
		begin_pending_drag(screen_position)
		return
	var item_index: int = inventory_item_index_at(local_position)
	if item_index >= 0:
		dragging_from_pending = false
		dragging_source_index = item_index
		dragging_item = items[item_index].duplicate(true)
		items.remove_at(item_index)
		drag_pointer_local = local_position
		rotate_hover_latched = false
		queue_redraw()
		return
	var pack_index: int = pack_index_at(local_position)
	if pack_index >= 0:
		highlight_pack(pack_index)
		if pack_is_movable(pack_index):
			dragging_pack_source_index = pack_index
			dragging_pack = pack_modules[pack_index].duplicate(true)
			pack_modules.remove_at(pack_index)
			drag_pointer_local = local_position
		queue_redraw()

func pointer_move(screen_position: Vector2) -> void:
	if not visible:
		return
	drag_pointer_local = screen_to_local(screen_position)
	if not dragging_item.is_empty():
		var pointer_on_rotate: bool = rotate_button_rect().has_point(drag_pointer_local)
		if pointer_on_rotate and not rotate_hover_latched:
			dragging_item["rotated"] = not bool(dragging_item.get("rotated", false))
			rotate_hover_latched = true
		elif not pointer_on_rotate:
			rotate_hover_latched = false
		queue_redraw()
		return
	if not dragging_pack.is_empty():
		queue_redraw()

func pointer_release(screen_position: Vector2) -> void:
	if not visible:
		return
	drag_pointer_local = screen_to_local(screen_position)
	if not dragging_pack.is_empty():
		finish_pack_drag()
		return
	if dragging_item.is_empty():
		return
	var restored_item: Dictionary = dragging_item.duplicate(true)
	var released_on_rotate: bool = rotate_button_rect().has_point(drag_pointer_local)
	var released_outside_grid: bool = not grid_rect().has_point(drag_pointer_local)
	var placement_anchor: Vector2i = preview_anchor_for_item(restored_item, drag_pointer_local)
	if released_on_rotate:
		restore_dragged_item(restored_item)
	elif released_outside_grid and not dragging_from_pending:
		item_dropped.emit(restored_item)
		_emit_inventory_changed()
	elif can_place_item(restored_item, placement_anchor):
		restored_item["anchor"] = placement_anchor
		items.append(restored_item)
		if dragging_from_pending:
			pending_item.clear()
		_emit_inventory_changed()
	else:
		restore_dragged_item(restored_item)
	dragging_item.clear()
	dragging_source_index = -1
	dragging_from_pending = false
	rotate_hover_latched = false
	queue_redraw()

func get_inventory_items() -> Array:
	var snapshot: Array = []
	for item_variant in items:
		snapshot.append((item_variant as Dictionary).duplicate(true))
	return snapshot

func pending_consumed() -> bool:
	return pending_item.is_empty()

func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP_COLOR, true)
	var panel: Rect2 = panel_rect()
	draw_rect(panel, PANEL_FILL, true)
	draw_rect(panel, PANEL_OUTLINE, false, 3.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, panel.position + Vector2(28.0, 38.0), "%s Inventory" % hero_name, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 160.0, 24, Color("eef8ff"))
	draw_rect(close_button_rect(), Color("243840"), true)
	draw_rect(close_button_rect(), Color("9bcde0"), false, 2.0)
	draw_string(font, close_button_rect().position + Vector2(18.0, 26.0), "Close", HORIZONTAL_ALIGNMENT_LEFT, 70.0, 18, Color("eef8ff"))
	draw_stats_block()
	draw_grid()
	draw_pending_item()
	draw_rotate_button()
	draw_dragging_pack()
	draw_dragging_item()

func panel_rect() -> Rect2:
	var margin: Vector2 = Vector2(44.0, 40.0)
	return Rect2(margin, size - margin * 2.0)

func stats_rect() -> Rect2:
	var panel: Rect2 = panel_rect()
	return Rect2(panel.position + Vector2(24.0, 72.0), Vector2(panel.size.x * 0.34, panel.size.y - 150.0))

func grid_rect() -> Rect2:
	var panel: Rect2 = panel_rect()
	var right_width: float = panel.size.x * 0.56
	var available_rect: Rect2 = Rect2(panel.position + Vector2(panel.size.x - right_width - 26.0, 88.0), Vector2(right_width, panel.size.y - 168.0))
	var cell_extent: float = minf(floor(available_rect.size.x / float(inventory_canvas_size.x)), floor(available_rect.size.y / float(inventory_canvas_size.y)))
	var grid_size_pixels: Vector2 = Vector2(float(inventory_canvas_size.x) * cell_extent, float(inventory_canvas_size.y) * cell_extent)
	return Rect2(available_rect.position + (available_rect.size - grid_size_pixels) * 0.5, grid_size_pixels)

func cell_size() -> float:
	return grid_rect().size.x / maxf(float(inventory_canvas_size.x), 1.0)

func close_button_rect() -> Rect2:
	var panel: Rect2 = panel_rect()
	return Rect2(panel.position + Vector2(panel.size.x - 98.0, 18.0), Vector2(76.0, 34.0))

func level_up_button_rect() -> Rect2:
	var stats: Rect2 = stats_rect()
	return Rect2(stats.position + Vector2(16.0, 162.0), Vector2(stats.size.x - 32.0, 56.0))

func rotate_button_rect() -> Rect2:
	var stats: Rect2 = stats_rect()
	var grid: Rect2 = grid_rect()
	var gap_left: float = stats.position.x + stats.size.x + 14.0
	var gap_right: float = grid.position.x - 14.0
	var button_width: float = clampf(gap_right - gap_left, 132.0, 188.0)
	var button_height: float = 70.0
	var button_x: float = gap_left + ((gap_right - gap_left) - button_width) * 0.5
	var button_y: float = grid.get_center().y - button_height * 0.5
	return Rect2(Vector2(button_x, button_y), Vector2(button_width, button_height))

func pending_item_rect() -> Rect2:
	var stats: Rect2 = stats_rect()
	return Rect2(Vector2(stats.position.x, stats.position.y + stats.size.y - 156.0), Vector2(stats.size.x - 18.0, 132.0))

func draw_stats_block() -> void:
	var stats: Rect2 = stats_rect()
	draw_rect(stats, Color("182a31"), true)
	draw_rect(stats, Color("557887"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, stats.position + Vector2(18.0, 28.0), "Stats", HORIZONTAL_ALIGNMENT_LEFT, stats.size.x - 24.0, 20, Color("e9f6ff"))
	var y: float = stats.position.y + 58.0
	for stat_line in stats_lines:
		draw_string(font, Vector2(stats.position.x + 18.0, y), stat_line, HORIZONTAL_ALIGNMENT_LEFT, stats.size.x - 30.0, 18, Color("d4eaf4"))
		y += 24.0
	var level_rect: Rect2 = level_up_button_rect()
	var level_fill: Color = LEVEL_BUTTON_FILL if can_level_up else LEVEL_BUTTON_DISABLED
	draw_rect(level_rect, level_fill, true)
	draw_rect(level_rect, Color("9fd2a5"), false, 2.0)
	draw_string(font, level_rect.position + Vector2(14.0, 22.0), "Level %d" % hero_level, HORIZONTAL_ALIGNMENT_LEFT, level_rect.size.x - 24.0, 18, Color("eef8ff"))
	if can_level_up:
		draw_string(font, level_rect.position + Vector2(14.0, 43.0), "Spend %d food for next pack" % level_up_cost, HORIZONTAL_ALIGNMENT_LEFT, level_rect.size.x - 24.0, 15, Color("d8f0dc"))
	else:
		draw_string(font, level_rect.position + Vector2(14.0, 43.0), "Need %d food to level" % level_up_cost, HORIZONTAL_ALIGNMENT_LEFT, level_rect.size.x - 24.0, 15, Color("c3d0c6"))
	draw_rect(Rect2(stats.position + Vector2(18.0, 234.0), Vector2(18.0, 18.0)), GRID_BASE, true)
	draw_rect(Rect2(stats.position + Vector2(18.0, 234.0), Vector2(18.0, 18.0)), GRID_BASE_OUTLINE, false, 2.0)
	draw_string(font, stats.position + Vector2(46.0, 248.0), "Core bag", HORIZONTAL_ALIGNMENT_LEFT, stats.size.x - 60.0, 15, Color("d6e5ec"))
	draw_rect(Rect2(stats.position + Vector2(18.0, 258.0), Vector2(18.0, 18.0)), GRID_PACK, true)
	draw_rect(Rect2(stats.position + Vector2(18.0, 258.0), Vector2(18.0, 18.0)), GRID_PACK_OUTLINE, false, 2.0)
	draw_circle(stats.position + Vector2(31.0, 267.0), 1.6, GRID_PACK_HANDLE)
	draw_circle(stats.position + Vector2(27.0, 267.0), 1.6, GRID_PACK_HANDLE)
	draw_circle(stats.position + Vector2(35.0, 267.0), 1.6, GRID_PACK_HANDLE)
	draw_string(font, stats.position + Vector2(46.0, 272.0), "Moveable pack", HORIZONTAL_ALIGNMENT_LEFT, stats.size.x - 60.0, 15, Color("d6e5ec"))
	draw_string(font, Vector2(stats.position.x + 18.0, stats.position.y + stats.size.y - 182.0), "Food %d" % food_value, HORIZONTAL_ALIGNMENT_LEFT, stats.size.x - 24.0, 18, Color("eef8ff"))
	draw_string(font, Vector2(stats.position.x + 18.0, stats.position.y + stats.size.y - 156.0), "Loot", HORIZONTAL_ALIGNMENT_LEFT, stats.size.x - 24.0, 20, Color("e9f6ff"))
	if pending_item.is_empty():
		draw_string(font, Vector2(stats.position.x + 18.0, stats.position.y + stats.size.y - 122.0), "Hold an item on the dungeon floor to stage it here.", HORIZONTAL_ALIGNMENT_LEFT, stats.size.x - 34.0, 16, Color("a5c3d0"))

func draw_grid() -> void:
	var grid: Rect2 = grid_rect()
	var grid_cell_size: float = cell_size()
	var active_cells: Dictionary = active_cells_from_current_layout()
	var base_cells: Dictionary = base_cells_map()
	draw_rect(grid, GRID_BG, true)
	for y in range(inventory_canvas_size.y):
		for x in range(inventory_canvas_size.x):
			var cell: Vector2i = Vector2i(x, y)
			var cell_rect: Rect2 = Rect2(grid.position + Vector2(float(x), float(y)) * grid_cell_size, Vector2.ONE * grid_cell_size)
			var fill: Color = GRID_INACTIVE
			if active_cells.has(cell):
				fill = GRID_BASE if base_cells.has(cell) else GRID_PACK
			draw_rect(cell_rect, fill, true)
			draw_rect(cell_rect, GRID_CELL_OUTLINE, false, 1.0)
	draw_core_outline()
	draw_pack_outlines()
	draw_pack_snap_effect()
	for item_variant in items:
		var item: Dictionary = item_variant
		draw_inventory_item(item_rect_for_anchor(item), item, false)
	var preview_pack: Dictionary = dragging_pack if not dragging_pack.is_empty() else {}
	if not preview_pack.is_empty():
		var preview_pack_anchor: Vector2i = preview_anchor_for_pack(preview_pack, drag_pointer_local)
		var preview_pack_rect: Rect2 = Rect2(grid.position + Vector2(preview_pack_anchor) * grid_cell_size, Vector2(preview_pack["size"]) * grid_cell_size)
		var pack_valid: bool = can_place_pack(preview_pack, preview_pack_anchor)
		draw_rect(preview_pack_rect, GRID_VALID if pack_valid else GRID_INVALID, true)
	var preview_item: Dictionary = dragging_item if not dragging_item.is_empty() else {}
	if not preview_item.is_empty():
		var preview_anchor: Vector2i = preview_anchor_for_item(preview_item, drag_pointer_local)
		var preview_size: Vector2i = item_size_in_cells(preview_item)
		var preview_rect: Rect2 = Rect2(grid.position + Vector2(preview_anchor) * grid_cell_size, Vector2(preview_size) * grid_cell_size)
		var preview_color: Color = GRID_VALID if can_place_item(preview_item, preview_anchor) else GRID_INVALID
		draw_rect(preview_rect, preview_color, true)

func draw_pending_item() -> void:
	if pending_item.is_empty() or (not dragging_item.is_empty() and dragging_from_pending):
		return
	var dock_rect: Rect2 = pending_item_rect()
	draw_rect(dock_rect, PENDING_BG, true)
	draw_rect(dock_rect, Color("5a8593"), false, 2.0)
	var item_size_pixels: Vector2 = Vector2(item_size_in_cells(pending_item)) * cell_size()
	var item_rect: Rect2 = Rect2(dock_rect.get_center() - item_size_pixels * 0.5, item_size_pixels)
	draw_inventory_item(item_rect, pending_item, true)

func draw_rotate_button() -> void:
	var rotate_rect: Rect2 = rotate_button_rect()
	var fill: Color = ROTATE_HIGHLIGHT if rotate_hover_latched else ROTATE_FILL
	draw_rect(rotate_rect, fill, true)
	draw_rect(rotate_rect, Color("98c2d0"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, rotate_rect.position + Vector2(16.0, 26.0), "Rotate", HORIZONTAL_ALIGNMENT_LEFT, rotate_rect.size.x - 24.0, 18, Color("eef8ff"))
	draw_string(font, rotate_rect.position + Vector2(16.0, 49.0), "Pass through", HORIZONTAL_ALIGNMENT_LEFT, rotate_rect.size.x - 24.0, 15, Color("d0e6ef"))
	draw_string(font, rotate_rect.position + Vector2(16.0, 66.0), "to turn 90 deg", HORIZONTAL_ALIGNMENT_LEFT, rotate_rect.size.x - 24.0, 15, Color("d0e6ef"))

func draw_dragging_item() -> void:
	if dragging_item.is_empty():
		return
	draw_inventory_item(dragging_item_rect(), dragging_item, true)

func draw_dragging_pack() -> void:
	if dragging_pack.is_empty():
		return
	var preview_rect: Rect2 = dragging_pack_rect()
	draw_rect(preview_rect, Color(0.76, 0.92, 1.0, 0.24), true)
	draw_rect(preview_rect, GRID_PACK_HIGHLIGHT, false, 4.0)
	draw_pack_handle_marks(preview_rect)
	draw_string(ThemeDB.fallback_font, preview_rect.position + Vector2(8.0, 18.0), "MOVING", HORIZONTAL_ALIGNMENT_LEFT, preview_rect.size.x - 12.0, 14, GRID_PACK_HIGHLIGHT)

func draw_inventory_item(item_rect: Rect2, item: Dictionary, emphasize: bool) -> void:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var fill: Color = item_def.get("color", Color("9ed4ff"))
	if emphasize:
		fill = fill.lightened(0.12)
	draw_rect(item_rect, fill, true)
	draw_rect(item_rect, Color("eff8ff"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	var item_name: String = String(item_def.get("name", "Item"))
	var short_label: String = String(item_def.get("short", item_name.substr(0, mini(item_name.length(), 3)).to_upper()))
	draw_string(font, item_rect.position + Vector2(8.0, 22.0), short_label, HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 12.0, 18, Color("0f171b"))
	draw_string(font, item_rect.position + Vector2(8.0, item_rect.size.y - 8.0), item_name, HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 12.0, 14, Color("0f171b"))

func item_rect_for_anchor(item: Dictionary) -> Rect2:
	var grid: Rect2 = grid_rect()
	var size_cells: Vector2i = item_size_in_cells(item)
	return Rect2(grid.position + Vector2(item["anchor"]) * cell_size(), Vector2(size_cells) * cell_size())

func dragging_item_rect() -> Rect2:
	var size_cells: Vector2i = item_size_in_cells(dragging_item)
	var item_size_pixels: Vector2 = Vector2(size_cells) * cell_size()
	return Rect2(drag_pointer_local - item_size_pixels * 0.5, item_size_pixels)

func dragging_pack_rect() -> Rect2:
	var pack_size: Vector2i = dragging_pack.get("size", Vector2i.ONE)
	var pack_size_pixels: Vector2 = Vector2(pack_size) * cell_size()
	return Rect2(drag_pointer_local - pack_size_pixels * 0.5, pack_size_pixels)

func inventory_item_index_at(local_position: Vector2) -> int:
	for item_index in range(items.size() - 1, -1, -1):
		if item_rect_for_anchor(items[item_index]).has_point(local_position):
			return item_index
	return -1

func pack_index_at(local_position: Vector2) -> int:
	for pack_index in range(pack_modules.size() - 1, -1, -1):
		if pack_rect(pack_modules[pack_index]).has_point(local_position):
			return pack_index
	return -1

func item_size_in_cells(item: Dictionary) -> Vector2i:
	var item_id: String = String(item.get("item_id", ""))
	var item_def: Dictionary = item_defs.get(item_id, {})
	var item_base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	if bool(item.get("rotated", false)):
		return Vector2i(item_base_size.y, item_base_size.x)
	return item_base_size

func preview_anchor_for_item(item: Dictionary, local_position: Vector2) -> Vector2i:
	var grid: Rect2 = grid_rect()
	var item_size_cells: Vector2i = item_size_in_cells(item)
	var item_size_pixels: Vector2 = Vector2(item_size_cells) * cell_size()
	var top_left: Vector2 = local_position - item_size_pixels * 0.5
	var anchor_x: int = int(floor((top_left.x - grid.position.x) / cell_size()))
	var anchor_y: int = int(floor((top_left.y - grid.position.y) / cell_size()))
	return Vector2i(anchor_x, anchor_y)

func preview_anchor_for_pack(pack_module: Dictionary, local_position: Vector2) -> Vector2i:
	var grid: Rect2 = grid_rect()
	var pack_size_cells: Vector2i = pack_module.get("size", Vector2i.ONE)
	var pack_size_pixels: Vector2 = Vector2(pack_size_cells) * cell_size()
	var top_left: Vector2 = local_position - pack_size_pixels * 0.5
	var anchor_x: int = int(floor((top_left.x - grid.position.x) / cell_size()))
	var anchor_y: int = int(floor((top_left.y - grid.position.y) / cell_size()))
	return Vector2i(anchor_x, anchor_y)

func can_place_item(item: Dictionary, anchor: Vector2i) -> bool:
	if anchor.x < 0 or anchor.y < 0:
		return false
	var size_cells: Vector2i = item_size_in_cells(item)
	if anchor.x + size_cells.x > inventory_canvas_size.x or anchor.y + size_cells.y > inventory_canvas_size.y:
		return false
	var active_cells: Dictionary = active_cells_from_current_layout()
	var occupied_cells: Dictionary = {}
	for existing_item_variant in items:
		var existing_item: Dictionary = existing_item_variant
		for cell in occupied_cells_for_item(existing_item):
			occupied_cells[cell] = true
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			var cell: Vector2i = anchor + Vector2i(offset_x, offset_y)
			if not active_cells.has(cell) or occupied_cells.has(cell):
				return false
	return true

func occupied_cells_for_item(item: Dictionary) -> Array:
	var cells: Array = []
	var anchor: Vector2i = item.get("anchor", INVALID_CELL)
	var size_cells: Vector2i = item_size_in_cells(item)
	if anchor == INVALID_CELL:
		return cells
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			cells.append(anchor + Vector2i(offset_x, offset_y))
	return cells

func base_cells_map() -> Dictionary:
	var active_cells: Dictionary = {}
	for offset_y in range(base_size.y):
		for offset_x in range(base_size.x):
			active_cells[base_origin + Vector2i(offset_x, offset_y)] = true
	return active_cells

func pack_cells(pack_module: Dictionary) -> Array:
	var cells: Array = []
	var anchor: Vector2i = pack_module.get("anchor", INVALID_CELL)
	var size_cells: Vector2i = pack_module.get("size", Vector2i.ONE)
	if anchor == INVALID_CELL:
		return cells
	for offset_y in range(size_cells.y):
		for offset_x in range(size_cells.x):
			cells.append(anchor + Vector2i(offset_x, offset_y))
	return cells

func active_cells_from_current_layout() -> Dictionary:
	var active_cells: Dictionary = base_cells_map()
	for pack_module_variant in pack_modules:
		for pack_cell in pack_cells(pack_module_variant):
			active_cells[pack_cell] = true
	return active_cells

func pack_rect(pack_module: Dictionary) -> Rect2:
	var grid: Rect2 = grid_rect()
	var anchor: Vector2i = pack_module.get("anchor", INVALID_CELL)
	var pack_size: Vector2i = pack_module.get("size", Vector2i.ONE)
	return Rect2(grid.position + Vector2(anchor) * cell_size(), Vector2(pack_size) * cell_size())

func draw_core_outline() -> void:
	var grid: Rect2 = grid_rect()
	var core_rect: Rect2 = Rect2(grid.position + Vector2(base_origin) * cell_size(), Vector2(base_size) * cell_size())
	draw_rect(core_rect.grow(2.0), GRID_BASE_OUTLINE, false, 3.0)
	draw_string(ThemeDB.fallback_font, core_rect.position + Vector2(8.0, 18.0), "CORE", HORIZONTAL_ALIGNMENT_LEFT, core_rect.size.x - 12.0, 14, GRID_BASE_OUTLINE)

func draw_pack_outlines() -> void:
	for pack_index in range(pack_modules.size()):
		var pack_module: Dictionary = pack_modules[pack_index]
		var module_rect: Rect2 = pack_rect(pack_module)
		var outline_color: Color = GRID_PACK_HIGHLIGHT if pack_index == highlighted_pack_index and highlighted_pack_timer > 0.0 else GRID_PACK_OUTLINE
		var fill_color: Color = Color(1.0, 0.95, 0.68, 0.08) if outline_color == GRID_PACK_HIGHLIGHT else Color.TRANSPARENT
		if fill_color.a > 0.0:
			draw_rect(module_rect.grow(1.0), fill_color, true)
		draw_rect(module_rect.grow(2.0), outline_color, false, 3.0)
		draw_pack_handle_marks(module_rect)
		if module_rect.size.x >= 42.0 and module_rect.size.y >= 26.0:
			draw_string(ThemeDB.fallback_font, module_rect.position + Vector2(8.0, 18.0), "PACK", HORIZONTAL_ALIGNMENT_LEFT, module_rect.size.x - 12.0, 14, outline_color)

func draw_pack_handle_marks(module_rect: Rect2) -> void:
	var handle_center: Vector2 = module_rect.position + Vector2(12.0, 12.0)
	draw_circle(handle_center + Vector2(-4.0, 0.0), 1.6, GRID_PACK_HANDLE)
	draw_circle(handle_center, 1.6, GRID_PACK_HANDLE)
	draw_circle(handle_center + Vector2(4.0, 0.0), 1.6, GRID_PACK_HANDLE)

func pack_is_movable(pack_index: int) -> bool:
	var pack_module: Dictionary = pack_modules[pack_index]
	var pack_cell_map: Dictionary = {}
	for pack_cell in pack_cells(pack_module):
		pack_cell_map[pack_cell] = true
	for item_variant in items:
		for occupied_cell_variant in occupied_cells_for_item(item_variant):
			var occupied_cell: Vector2i = occupied_cell_variant
			if pack_cell_map.has(occupied_cell):
				return false
	return true

func can_place_pack(pack_module: Dictionary, anchor: Vector2i) -> bool:
	var pack_size: Vector2i = pack_module.get("size", Vector2i.ONE)
	if anchor.x < 0 or anchor.y < 0:
		return false
	if anchor.x + pack_size.x > inventory_canvas_size.x or anchor.y + pack_size.y > inventory_canvas_size.y:
		return false
	var occupied_cells: Dictionary = base_cells_map()
	for existing_pack_variant in pack_modules:
		for pack_cell in pack_cells(existing_pack_variant):
			occupied_cells[pack_cell] = true
	var touches_existing: bool = false
	for offset_y in range(pack_size.y):
		for offset_x in range(pack_size.x):
			var cell: Vector2i = anchor + Vector2i(offset_x, offset_y)
			if occupied_cells.has(cell):
				return false
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if occupied_cells.has(cell + direction):
					touches_existing = true
	if not touches_existing:
		return false
	var preview_pack: Dictionary = pack_module.duplicate(true)
	preview_pack["anchor"] = anchor
	var active_cells: Dictionary = active_cells_from_current_layout()
	for pack_cell in pack_cells(preview_pack):
		active_cells[pack_cell] = true
	for item_variant in items:
		for occupied_cell_variant in occupied_cells_for_item(item_variant):
			var occupied_cell: Vector2i = occupied_cell_variant
			if not active_cells.has(occupied_cell):
				return false
	return true

func finish_pack_drag() -> void:
	var restored_pack: Dictionary = dragging_pack.duplicate(true)
	var placement_anchor: Vector2i = preview_anchor_for_pack(restored_pack, drag_pointer_local)
	if can_place_pack(restored_pack, placement_anchor):
		restored_pack["anchor"] = placement_anchor
		pack_modules.append(restored_pack)
		start_pack_snap(pack_rect(restored_pack))
		highlight_pack(pack_modules.size() - 1)
		_emit_pack_layout_changed()
	else:
		var restore_index: int = clampi(dragging_pack_source_index, 0, pack_modules.size())
		pack_modules.insert(restore_index, restored_pack)
		highlight_pack(restore_index)
	dragging_pack.clear()
	dragging_pack_source_index = -1
	queue_redraw()

func restore_dragged_item(item: Dictionary) -> void:
	if dragging_from_pending:
		pending_item = item
	else:
		var restore_index: int = clampi(dragging_source_index, 0, items.size())
		items.insert(restore_index, item)

func _emit_inventory_changed() -> void:
	var snapshot: Array = []
	for item_variant in items:
		snapshot.append((item_variant as Dictionary).duplicate(true))
	inventory_changed.emit(snapshot)

func _emit_pack_layout_changed() -> void:
	var snapshot: Array = []
	for pack_variant in pack_modules:
		snapshot.append((pack_variant as Dictionary).duplicate(true))
	pack_layout_changed.emit(snapshot)

func screen_to_local(screen_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_position

func highlight_pack(pack_index: int) -> void:
	highlighted_pack_index = pack_index
	highlighted_pack_timer = 0.55

func start_pack_snap(module_rect: Rect2) -> void:
	pack_snap_rect = module_rect
	pack_snap_timer = PACK_SNAP_DURATION

func draw_pack_snap_effect() -> void:
	if pack_snap_timer <= 0.0 or pack_snap_rect == Rect2():
		return
	var ratio: float = pack_snap_timer / PACK_SNAP_DURATION
	var grow_amount: float = 16.0 * ratio
	var effect_rect: Rect2 = pack_snap_rect.grow(grow_amount)
	var alpha: float = 0.30 * ratio
	draw_rect(effect_rect, Color(GRID_PACK_SNAP, alpha), false, 5.0)
	draw_rect(pack_snap_rect.grow(4.0), Color(GRID_PACK_SNAP, 0.42 * ratio), false, 3.0)
