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
const LEVEL_BUTTON_PROGRESS: Color = Color("87d78f")
const PENDING_BG: Color = Color("1c3038")
const PACK_SNAP_DURATION: float = 0.18
const LEVEL_HOLD_DURATION: float = 0.7
const ITEM_SNAP_DURATION: float = 0.16
const PACK_SNAP_SEARCH_RADIUS: int = 2
const SWIPE_CLOSE_START_THRESHOLD: float = 20.0
const SWIPE_CLOSE_TRIGGER_DISTANCE: float = 168.0
const SWIPE_CLOSE_MAX_OFFSET: float = 360.0
const INVENTORY_NUDGE_DISTANCE: float = 34.0
const INVENTORY_NUDGE_DELAY: float = 0.16
const INVENTORY_NUDGE_DURATION: float = 0.54
const INVENTORY_NUDGE_HINT_OPENS: int = 3
const GROUND_ITEM_TOUCH_PADDING: float = 14.0
const GROUND_ITEM_MIN_HIT_SIZE: float = 78.0

var hero_name: String = ""
var hero_level: int = 1
var food_value: int = 0
var level_up_cost: int = 0
var can_level_up: bool = false
var stats_lines: Array[String] = []
var ability_sections: Array = []
var level_up_reward_lines: Array[String] = []
var inventory_canvas_size: Vector2i = Vector2i(9, 8)
var base_origin: Vector2i = Vector2i(3, 3)
var base_size: Vector2i = Vector2i(2, 2)
var pack_modules: Array = []
var item_defs: Dictionary = {}
var items: Array = []
var ground_items: Array = []
var loot_enabled: bool = false
var dragging_item: Dictionary = {}
var dragging_source_index: int = -1
var dragging_from_ground: bool = false
var dragging_ground_source_index: int = -1
var dragging_pack: Dictionary = {}
var dragging_pack_source_index: int = -1
var drag_pointer_local: Vector2 = Vector2.ZERO
var rotate_hover_latched: bool = false
var toggle_hover_latched: bool = false
var highlighted_pack_index: int = -1
var highlighted_pack_timer: float = 0.0
var pack_snap_rect: Rect2 = Rect2()
var pack_snap_timer: float = 0.0
var item_snap_animations: Array = []
var next_item_snap_animation_id: int = 1
var level_hold_active: bool = false
var level_hold_completed: bool = false
var level_hold_progress: float = 0.0
var swipe_close_tracking: bool = false
var swipe_close_active: bool = false
var swipe_close_start_local: Vector2 = Vector2.ZERO
var swipe_close_offset_y: float = 0.0
var inventory_open_count: int = 0
var inventory_nudge_timer: float = -1.0
var last_touched_item: Dictionary = {}

@onready var layout_root: Control = $LayoutRoot
@onready var main_panel_guide: Control = $LayoutRoot/MainPanelGuide
@onready var title_label: Label = $LayoutRoot/MainPanelGuide/TitleLabel
@onready var stats_guide: Control = $LayoutRoot/MainPanelGuide/StatsGuide
@onready var description_guide: Control = $LayoutRoot/MainPanelGuide/DescriptionGuide
@onready var loot_guide: Control = $LayoutRoot/MainPanelGuide/LootGuide
@onready var rotate_button_node: Button = $LayoutRoot/MainPanelGuide/RotateButton
@onready var toggle_button_node: Button = $LayoutRoot/MainPanelGuide/ToggleButton

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prepare_runtime_guides()
	update_layout_nodes()
	visible = false

func _process(delta: float) -> void:
	var needs_redraw: bool = false
	update_layout_nodes()
	if advance_inventory_nudge(delta):
		needs_redraw = true
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
	if advance_item_snap_animations(delta):
		needs_redraw = true
	if level_hold_active:
		if not can_level_up:
			reset_level_hold()
		else:
			level_hold_progress = minf(level_hold_progress + delta / LEVEL_HOLD_DURATION, 1.0)
			if level_hold_progress >= 1.0 and not level_hold_completed:
				level_hold_completed = true
				level_hold_active = false
				level_up_requested.emit()
			needs_redraw = true
	if not swipe_close_active and not swipe_close_tracking and absf(swipe_close_offset_y) > 0.01:
		swipe_close_offset_y = lerpf(swipe_close_offset_y, 0.0, minf(delta * 18.0, 1.0))
		if absf(swipe_close_offset_y) < 0.5:
			swipe_close_offset_y = 0.0
		needs_redraw = true
	if not needs_redraw:
		return
	queue_redraw()

func prepare_runtime_guides() -> void:
	if Engine.is_editor_hint():
		return
	for guide in [main_panel_guide, stats_guide, description_guide, loot_guide]:
		if guide != null:
			guide.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	for action_button in [rotate_button_node, toggle_button_node]:
		if action_button != null:
			action_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if toggle_button_node != null:
		toggle_button_node.visible = false

func update_layout_nodes() -> void:
	if layout_root == null:
		return
	layout_root.position = Vector2(0.0, panel_offset_y())
	if title_label != null:
		title_label.text = "%s Inventory" % hero_name
	update_action_button_nodes()

func update_action_button_nodes() -> void:
	if rotate_button_node != null:
		rotate_button_node.text = "Rotate"
		rotate_button_node.modulate = ROTATE_HIGHLIGHT if rotate_hover_latched else Color.WHITE
	if toggle_button_node != null:
		toggle_button_node.visible = false

func control_local_rect(control: Control) -> Rect2:
	return Rect2(screen_to_local(control.get_global_rect().position), control.size)

func configure(next_hero_name: String, next_hero_level: int, next_food_value: int, next_level_up_cost: int, next_can_level_up: bool, next_stats_lines: Array, next_ability_sections: Array, next_level_up_reward_lines: Array, next_inventory_canvas_size: Vector2i, next_base_origin: Vector2i, next_base_size: Vector2i, next_pack_modules: Array, next_item_defs: Dictionary, next_items: Array, next_ground_items: Array, next_loot_enabled: bool) -> void:
	hero_name = next_hero_name
	hero_level = next_hero_level
	food_value = next_food_value
	level_up_cost = next_level_up_cost
	can_level_up = next_can_level_up
	stats_lines.clear()
	for stat_line_variant in next_stats_lines:
		stats_lines.append(String(stat_line_variant))
	ability_sections.clear()
	for section_variant in next_ability_sections:
		ability_sections.append((section_variant as Dictionary).duplicate(true))
	level_up_reward_lines.clear()
	for reward_line_variant in next_level_up_reward_lines:
		level_up_reward_lines.append(String(reward_line_variant))
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
	ground_items.clear()
	for ground_item_variant in next_ground_items:
		ground_items.append((ground_item_variant as Dictionary).duplicate(true))
	loot_enabled = next_loot_enabled
	dragging_item.clear()
	dragging_pack.clear()
	dragging_source_index = -1
	dragging_pack_source_index = -1
	dragging_from_ground = false
	dragging_ground_source_index = -1
	rotate_hover_latched = false
	toggle_hover_latched = false
	highlighted_pack_index = -1
	highlighted_pack_timer = 0.0
	pack_snap_rect = Rect2()
	pack_snap_timer = 0.0
	item_snap_animations.clear()
	reset_swipe_close_state()
	swipe_close_offset_y = 0.0
	reset_level_hold()
	if not items.is_empty():
		last_touched_item = (items[0] as Dictionary).duplicate(true)
	elif not ground_items.is_empty():
		last_touched_item = (ground_items[0] as Dictionary).duplicate(true)
	else:
		last_touched_item.clear()
	inventory_open_count += 1
	start_inventory_nudge_hint_if_needed()
	visible = true
	update_layout_nodes()
	queue_redraw()

func hide_overlay() -> void:
	visible = false
	dragging_item.clear()
	dragging_pack.clear()
	dragging_source_index = -1
	dragging_pack_source_index = -1
	dragging_from_ground = false
	dragging_ground_source_index = -1
	highlighted_pack_index = -1
	highlighted_pack_timer = 0.0
	pack_snap_rect = Rect2()
	pack_snap_timer = 0.0
	item_snap_animations.clear()
	rotate_hover_latched = false
	toggle_hover_latched = false
	reset_swipe_close_state()
	swipe_close_offset_y = 0.0
	reset_level_hold()
	inventory_nudge_timer = -1.0
	last_touched_item.clear()
	queue_redraw()

func refresh_state(next_stats_lines: Array, next_ability_sections: Array, next_level_up_reward_lines: Array, next_food_value: int, next_level_up_cost: int, next_can_level_up: bool, next_hero_level: int, next_pack_modules: Array) -> void:
	stats_lines.clear()
	for stat_line_variant in next_stats_lines:
		stats_lines.append(String(stat_line_variant))
	ability_sections.clear()
	for section_variant in next_ability_sections:
		ability_sections.append((section_variant as Dictionary).duplicate(true))
	level_up_reward_lines.clear()
	for reward_line_variant in next_level_up_reward_lines:
		level_up_reward_lines.append(String(reward_line_variant))
	food_value = next_food_value
	level_up_cost = next_level_up_cost
	can_level_up = next_can_level_up
	hero_level = next_hero_level
	pack_modules.clear()
	for pack_variant in next_pack_modules:
		pack_modules.append((pack_variant as Dictionary).duplicate(true))
	reset_swipe_close_state()
	swipe_close_offset_y = 0.0
	reset_level_hold()
	update_layout_nodes()
	queue_redraw()

func pointer_press(screen_position: Vector2) -> void:
	if not visible:
		return
	cancel_inventory_nudge_hint()
	var local_position: Vector2 = screen_to_local(screen_position)
	if level_hold_active or level_hold_completed:
		return
	if level_up_button_rect().has_point(local_position) and can_level_up:
		begin_level_hold()
		return
	if rotate_button_rect().has_point(local_position):
		return
	if not dragging_item.is_empty() or not dragging_pack.is_empty():
		return
	var ground_item_index: int = ground_item_index_at(local_position)
	if ground_item_index >= 0:
		remember_touched_item(ground_items[ground_item_index])
		dragging_from_ground = true
		dragging_ground_source_index = ground_item_index
		dragging_source_index = -1
		dragging_item = ground_items[ground_item_index].duplicate(true)
		ground_items.remove_at(ground_item_index)
		drag_pointer_local = local_position
		rotate_hover_latched = false
		toggle_hover_latched = false
		queue_redraw()
		return
	var item_index: int = inventory_item_index_at(local_position)
	if item_index >= 0:
		remember_touched_item(items[item_index])
		dragging_from_ground = false
		dragging_ground_source_index = -1
		dragging_source_index = item_index
		dragging_item = items[item_index].duplicate(true)
		items.remove_at(item_index)
		drag_pointer_local = local_position
		rotate_hover_latched = false
		toggle_hover_latched = false
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
		return
	if panel_rect().has_point(local_position):
		begin_swipe_close(local_position)

func pointer_move(screen_position: Vector2) -> void:
	if not visible:
		return
	drag_pointer_local = screen_to_local(screen_position)
	if swipe_close_tracking:
		update_swipe_close(drag_pointer_local)
		return
	if level_hold_active:
		if not level_up_button_rect().has_point(drag_pointer_local):
			reset_level_hold()
		else:
			queue_redraw()
		return
	if level_hold_completed:
		return
	if not dragging_item.is_empty():
		var drag_item_rect: Rect2 = dragging_item_rect()
		var item_on_rotate: bool = drag_item_rect.intersects(rotate_button_rect())
		if item_on_rotate and not rotate_hover_latched:
			dragging_item["rotated"] = not bool(dragging_item.get("rotated", false))
			rotate_hover_latched = true
		elif not item_on_rotate:
			rotate_hover_latched = false
		toggle_hover_latched = false
		queue_redraw()
		return
	if not dragging_pack.is_empty():
		var drag_pack_rect: Rect2 = dragging_pack_rect()
		var pack_on_rotate: bool = drag_pack_rect.intersects(rotate_button_rect())
		if pack_on_rotate and not rotate_hover_latched:
			rotate_pack_module(dragging_pack)
			rotate_hover_latched = true
		elif not pack_on_rotate:
			rotate_hover_latched = false
		toggle_hover_latched = false
		queue_redraw()
		return
	var hovered_ground_index: int = ground_item_index_at(drag_pointer_local)
	if hovered_ground_index >= 0:
		remember_touched_item(ground_items[hovered_ground_index])
		return
	var hovered_item_index: int = inventory_item_index_at(drag_pointer_local)
	if hovered_item_index >= 0:
		remember_touched_item(items[hovered_item_index])

func pointer_release(screen_position: Vector2) -> void:
	if not visible:
		return
	drag_pointer_local = screen_to_local(screen_position)
	if swipe_close_tracking:
		finish_swipe_close()
		return
	if level_hold_active or level_hold_completed:
		reset_level_hold()
		return
	if not dragging_pack.is_empty():
		finish_pack_drag()
		return
	if dragging_item.is_empty():
		return
	var restored_item: Dictionary = dragging_item.duplicate(true)
	var drag_rect: Rect2 = dragging_item_rect()
	var released_on_rotate: bool = rotate_button_rect().has_point(drag_pointer_local)
	var released_outside_grid: bool = not grid_rect().has_point(drag_pointer_local)
	var placement_anchor: Vector2i = preview_anchor_for_item(restored_item, drag_pointer_local)
	if released_on_rotate:
		restore_dragged_item(restored_item)
	elif released_outside_grid:
		if dragging_from_ground:
			restore_dragged_item(restored_item)
		elif loot_enabled:
			restored_item.erase("anchor")
			ground_items.append(restored_item)
			_emit_inventory_changed()
		else:
			item_dropped.emit(restored_item)
			_emit_inventory_changed()
	elif can_place_item(restored_item, placement_anchor):
		restored_item["anchor"] = placement_anchor
		start_item_snap_animation(restored_item, drag_rect, item_rect_for_anchor(restored_item))
		items.append(restored_item)
		remember_touched_item(restored_item)
		_emit_inventory_changed()
	else:
		restore_dragged_item(restored_item)
	dragging_item.clear()
	dragging_source_index = -1
	dragging_from_ground = false
	dragging_ground_source_index = -1
	rotate_hover_latched = false
	toggle_hover_latched = false
	queue_redraw()

func begin_level_hold() -> void:
	level_hold_active = true
	level_hold_completed = false
	level_hold_progress = 0.0
	queue_redraw()

func reset_level_hold() -> void:
	level_hold_active = false
	level_hold_completed = false
	level_hold_progress = 0.0
	queue_redraw()

func begin_swipe_close(local_position: Vector2) -> void:
	swipe_close_tracking = true
	swipe_close_active = false
	swipe_close_start_local = local_position
	queue_redraw()

func update_swipe_close(local_position: Vector2) -> void:
	var delta: Vector2 = local_position - swipe_close_start_local
	if not swipe_close_active:
		if absf(delta.x) > SWIPE_CLOSE_START_THRESHOLD and absf(delta.x) > absf(delta.y) * 1.15:
			reset_swipe_close_state()
			return
		if absf(delta.y) < SWIPE_CLOSE_START_THRESHOLD or absf(delta.y) <= absf(delta.x) * 1.05:
			queue_redraw()
			return
		swipe_close_active = true
	swipe_close_offset_y = clampf(delta.y, -SWIPE_CLOSE_MAX_OFFSET, SWIPE_CLOSE_MAX_OFFSET)
	queue_redraw()

func finish_swipe_close() -> void:
	var should_close: bool = swipe_close_active and absf(swipe_close_offset_y) >= SWIPE_CLOSE_TRIGGER_DISTANCE
	reset_swipe_close_state()
	if should_close:
		close_requested.emit()
	else:
		queue_redraw()

func reset_swipe_close_state() -> void:
	swipe_close_tracking = false
	swipe_close_active = false
	swipe_close_start_local = Vector2.ZERO

func start_inventory_nudge_hint_if_needed() -> void:
	if inventory_open_count <= INVENTORY_NUDGE_HINT_OPENS:
		inventory_nudge_timer = 0.0
	else:
		inventory_nudge_timer = -1.0

func cancel_inventory_nudge_hint() -> void:
	if inventory_nudge_timer >= 0.0:
		inventory_nudge_timer = -1.0
		queue_redraw()

func advance_inventory_nudge(delta: float) -> bool:
	if inventory_nudge_timer < 0.0:
		return false
	inventory_nudge_timer += delta
	if inventory_nudge_timer >= INVENTORY_NUDGE_DELAY + INVENTORY_NUDGE_DURATION:
		inventory_nudge_timer = -1.0
	return true

func panel_offset_y() -> float:
	return swipe_close_offset_y + nudge_offset_y()

func nudge_offset_y() -> float:
	if inventory_nudge_timer < INVENTORY_NUDGE_DELAY or inventory_nudge_timer < 0.0:
		return 0.0
	var t: float = clampf((inventory_nudge_timer - INVENTORY_NUDGE_DELAY) / INVENTORY_NUDGE_DURATION, 0.0, 1.0)
	return sin(t * PI) * INVENTORY_NUDGE_DISTANCE

func get_inventory_items() -> Array:
	var snapshot: Array = []
	for item_variant in items:
		snapshot.append(clean_item_snapshot(item_variant))
	return snapshot

func get_ground_items() -> Array:
	var snapshot: Array = []
	for item_variant in ground_items:
		snapshot.append(clean_item_snapshot(item_variant))
	return snapshot

func clean_item_snapshot(item_variant: Variant) -> Dictionary:
	var snapshot: Dictionary = (item_variant as Dictionary).duplicate(true)
	snapshot.erase("_snap_anim_id")
	return snapshot

func _draw() -> void:
	if not visible:
		return
	var backdrop: Color = BACKDROP_COLOR
	backdrop.a *= 1.0 - minf(absf(swipe_close_offset_y) / SWIPE_CLOSE_MAX_OFFSET, 1.0) * 0.35
	draw_rect(Rect2(Vector2.ZERO, size), backdrop, true)
	var panel: Rect2 = panel_rect()
	draw_rect(panel, PANEL_FILL, true)
	draw_rect(panel, PANEL_OUTLINE, false, 3.0)
	draw_stats_block()
	draw_grid()
	draw_ground_items()
	draw_item_description_panel()
	draw_dragging_pack()
	draw_dragging_item()

func panel_rect() -> Rect2:
	return control_local_rect(main_panel_guide)

func stats_rect() -> Rect2:
	var base_rect: Rect2 = control_local_rect(stats_guide)
	var description_rect: Rect2 = item_description_rect()
	var target_right: float = description_rect.position.x - inter_column_gap()
	if target_right <= base_rect.position.x + 40.0:
		return base_rect
	return Rect2(base_rect.position, Vector2(target_right - base_rect.position.x, base_rect.size.y))

func grid_rect() -> Rect2:
	var stats: Rect2 = stats_rect()
	var description: Rect2 = item_description_rect()
	var rotate_rect: Rect2 = rotate_button_rect()
	var grid_left: float = description.position.x + description.size.x + inter_column_gap()
	var grid_right: float = rotate_rect.position.x - inter_column_gap()
	var available_rect: Rect2 = Rect2(Vector2(grid_left, content_top_y()), Vector2(grid_right - grid_left, content_bottom_y() - content_top_y()))
	var cell_extent: float = minf(floor(available_rect.size.x / float(inventory_canvas_size.x)), floor(available_rect.size.y / float(inventory_canvas_size.y)))
	var grid_size_pixels: Vector2 = Vector2(float(inventory_canvas_size.x) * cell_extent, float(inventory_canvas_size.y) * cell_extent)
	return Rect2(available_rect.position + (available_rect.size - grid_size_pixels) * 0.5, grid_size_pixels)

func cell_size() -> float:
	return grid_rect().size.x / maxf(float(inventory_canvas_size.x), 1.0)

func level_up_button_rect() -> Rect2:
	var stats: Rect2 = stats_rect()
	return Rect2(Vector2(stats.position.x + 14.0, stats.position.y + stats.size.y - 112.0), Vector2(stats.size.x - 28.0, 96.0))

func rotate_button_rect() -> Rect2:
	return control_local_rect(rotate_button_node)

func ground_item_dock_rect() -> Rect2:
	return control_local_rect(loot_guide)

func ground_item_list_rect() -> Rect2:
	return ground_item_dock_rect()

func item_description_rect() -> Rect2:
	return control_local_rect(description_guide)

func left_column_width() -> float:
	return stats_rect().size.x

func inter_column_gap() -> float:
	return 8.0

func loot_dock_height() -> float:
	return ground_item_dock_rect().size.y

func content_top_y() -> float:
	return stats_rect().position.y

func content_bottom_y() -> float:
	return ground_item_dock_rect().position.y - 12.0

func ground_item_content_rect() -> Rect2:
	var dock_rect: Rect2 = ground_item_list_rect()
	return Rect2(dock_rect.position + Vector2(14.0, 34.0), Vector2(dock_rect.size.x - 28.0, dock_rect.size.y - 46.0))

func draw_stats_block() -> void:
	var stats: Rect2 = stats_rect()
	draw_rect(stats, Color("182a31"), true)
	draw_rect(stats, Color("557887"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, stats.position + Vector2(16.0, 26.0), "Hero", HORIZONTAL_ALIGNMENT_LEFT, stats.size.x * 0.55, 20, Color("e9f6ff"))
	draw_string(font, stats.position + Vector2(stats.size.x - 122.0, 26.0), "Level %d" % hero_level, HORIZONTAL_ALIGNMENT_LEFT, 108.0, 18, Color("f2f6b0"))
	draw_string(font, stats.position + Vector2(16.0, 50.0), "Food %d" % food_value, HORIZONTAL_ALIGNMENT_LEFT, stats.size.x - 28.0, 17, Color("d8f0dc"))
	var level_rect: Rect2 = level_up_button_rect()
	var content_top: float = stats.position.y + 76.0
	var content_bottom: float = level_rect.position.y - 12.0
	var divider_x: float = stats.position.x + stats.size.x * 0.46
	var left_rect: Rect2 = Rect2(Vector2(stats.position.x + 14.0, content_top), Vector2(divider_x - stats.position.x - 22.0, content_bottom - content_top))
	var right_rect: Rect2 = Rect2(Vector2(divider_x + 8.0, content_top), Vector2(stats.position.x + stats.size.x - divider_x - 22.0, content_bottom - content_top))
	draw_line(Vector2(divider_x, content_top - 6.0), Vector2(divider_x, content_bottom), Color(0.42, 0.57, 0.63, 0.55), 1.0, true)
	draw_string(font, left_rect.position + Vector2(0.0, 0.0), "Stats", HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x, 15, Color("d7edf7"))
	draw_string(font, right_rect.position + Vector2(0.0, 0.0), "Abilities", HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x, 15, Color("d7edf7"))
	var stats_y: float = left_rect.position.y + 20.0
	var stat_line_height: float = 18.0
	var max_stat_lines: int = maxi(0, int(floor((left_rect.size.y - 22.0) / stat_line_height)))
	for stat_index in range(mini(stats_lines.size(), max_stat_lines)):
		draw_string(font, Vector2(left_rect.position.x, stats_y), stats_lines[stat_index], HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x, 15, Color("d4eaf4"))
		stats_y += stat_line_height
	if stats_lines.size() > max_stat_lines:
		draw_string(font, Vector2(left_rect.position.x, stats_y), "...", HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x, 15, Color("9fb8c2"))
	draw_ability_sections(right_rect)
	var level_fill: Color = LEVEL_BUTTON_FILL if can_level_up else LEVEL_BUTTON_DISABLED
	var progress_fill_rect: Rect2 = Rect2(level_rect.position + Vector2(3.0, 3.0), Vector2((level_rect.size.x - 6.0) * level_hold_progress, level_rect.size.y - 6.0))
	draw_rect(level_rect, level_fill, true)
	if level_hold_progress > 0.0:
		draw_rect(progress_fill_rect, Color(LEVEL_BUTTON_PROGRESS, 0.35), true)
	draw_rect(level_rect, Color("9fd2a5"), false, 2.0)
	draw_string(font, level_rect.position + Vector2(14.0, 22.0), "Level Up", HORIZONTAL_ALIGNMENT_LEFT, level_rect.size.x - 24.0, 18, Color("eef8ff"))
	for reward_index in range(mini(level_up_reward_lines.size(), 3)):
		draw_string(font, level_rect.position + Vector2(176.0, 21.0 + float(reward_index) * 17.0), level_up_reward_lines[reward_index], HORIZONTAL_ALIGNMENT_LEFT, level_rect.size.x - 188.0, 12, Color("dbead8"))
	if can_level_up:
		var hold_text: String = "Hold to spend %d food" % level_up_cost
		if level_hold_active:
			hold_text = "Keep holding %d%%" % int(level_hold_progress * 100.0)
		elif level_hold_completed:
			hold_text = "Leveling..."
		draw_string(font, level_rect.position + Vector2(14.0, 46.0), hold_text, HORIZONTAL_ALIGNMENT_LEFT, 156.0, 15, Color("d8f0dc"))
		draw_string(font, level_rect.position + Vector2(14.0, 63.0), "Rewards on next level", HORIZONTAL_ALIGNMENT_LEFT, 156.0, 13, Color("c6e3cb"))
		draw_string(font, level_rect.position + Vector2(14.0, 79.0), "Release early to cancel", HORIZONTAL_ALIGNMENT_LEFT, 156.0, 13, Color("c6e3cb"))
	else:
		draw_string(font, level_rect.position + Vector2(14.0, 46.0), "Need %d food to level" % level_up_cost, HORIZONTAL_ALIGNMENT_LEFT, 156.0, 15, Color("c3d0c6"))
		draw_string(font, level_rect.position + Vector2(14.0, 63.0), "Rewards on next level", HORIZONTAL_ALIGNMENT_LEFT, 156.0, 13, Color("aebbb0"))
		draw_string(font, level_rect.position + Vector2(14.0, 79.0), "No confirmation unless ready", HORIZONTAL_ALIGNMENT_LEFT, 156.0, 13, Color("aebbb0"))

func draw_ability_sections(content_rect: Rect2) -> void:
	var font: Font = ThemeDB.fallback_font
	var y: float = content_rect.position.y + 20.0
	var section_gap: float = 10.0
	var line_gap: float = 14.0
	var detail_gap: float = 13.0
	var current_level_group: int = -1
	if ability_sections.is_empty():
		draw_string(font, Vector2(content_rect.position.x, y), "No listed passives yet.", HORIZONTAL_ALIGNMENT_LEFT, content_rect.size.x, 13, Color("9fb8c2"))
		return
	for section_variant in ability_sections:
		var section: Dictionary = section_variant
		var section_title: String = String(section.get("title", "Abilities"))
		var entries: Array = Array(section.get("entries", []))
		if entries.is_empty():
			continue
		draw_string(font, Vector2(content_rect.position.x, y), section_title, HORIZONTAL_ALIGNMENT_LEFT, content_rect.size.x, 13, Color("fff1b8"))
		y += 16.0
		current_level_group = -1
		for entry_variant in entries:
			var entry: Dictionary = entry_variant
			var entry_level: int = int(entry.get("level", -1))
			if entry_level >= 0 and entry_level != current_level_group:
				current_level_group = entry_level
				draw_string(font, Vector2(content_rect.position.x, y), "Lv %d" % entry_level, HORIZONTAL_ALIGNMENT_LEFT, content_rect.size.x, 12, Color("b8dff1"))
				y += 13.0
			draw_string(font, Vector2(content_rect.position.x, y), String(entry.get("name", "Ability")), HORIZONTAL_ALIGNMENT_LEFT, content_rect.size.x, 12, Color("dfeff7"))
			y += line_gap
			draw_string(font, Vector2(content_rect.position.x + 4.0, y), String(entry.get("detail", "")), HORIZONTAL_ALIGNMENT_LEFT, content_rect.size.x - 4.0, 11, Color("a7c8d5"))
			y += detail_gap
			if y > content_rect.position.y + content_rect.size.y - 14.0:
				draw_string(font, Vector2(content_rect.position.x, content_rect.position.y + content_rect.size.y - 2.0), "...", HORIZONTAL_ALIGNMENT_LEFT, content_rect.size.x, 12, Color("9fb8c2"))
				return
		y += section_gap

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
		if item_is_animating(item):
			continue
		draw_inventory_item(item_rect_for_anchor(item), item, false)
	draw_item_snap_animations()
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

func draw_ground_items() -> void:
	var dock_rect: Rect2 = ground_item_list_rect()
	draw_rect(dock_rect, PENDING_BG, true)
	draw_rect(dock_rect, Color("5a8593"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, dock_rect.position + Vector2(14.0, 24.0), "Loot", HORIZONTAL_ALIGNMENT_LEFT, dock_rect.size.x - 24.0, 20, Color("e9f6ff"))
	if ground_items.is_empty():
		var empty_text: String = "This room has no loose loot." if loot_enabled else "Use Loot on a room to browse floor items."
		draw_string(font, dock_rect.position + Vector2(14.0, 52.0), empty_text, HORIZONTAL_ALIGNMENT_LEFT, dock_rect.size.x - 28.0, 16, Color("a5c3d0"))
		return
	var item_rects: Array = ground_item_item_rects()
	for item_index in range(item_rects.size()):
		var slot_rect: Rect2 = item_rects[item_index]
		draw_rect(slot_rect, Color("243841"), true)
		draw_rect(slot_rect, Color("5a8593"), false, 1.0)
		draw_inventory_item(ground_item_display_rect(slot_rect, ground_items[item_index]), ground_items[item_index], true)

func draw_item_description_panel() -> void:
	var description_rect: Rect2 = item_description_rect()
	draw_rect(description_rect, PENDING_BG, true)
	draw_rect(description_rect, Color("5a8593"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, description_rect.position + Vector2(14.0, 24.0), "Item", HORIZONTAL_ALIGNMENT_LEFT, description_rect.size.x - 24.0, 20, Color("e9f6ff"))
	if last_touched_item.is_empty():
		draw_string(font, description_rect.position + Vector2(14.0, 52.0), "Touch an item to inspect it.", HORIZONTAL_ALIGNMENT_LEFT, description_rect.size.x - 24.0, 16, Color("a5c3d0"))
		return
	var item_def: Dictionary = item_defs.get(String(last_touched_item.get("item_id", "")), {})
	draw_string(font, description_rect.position + Vector2(14.0, 52.0), String(item_def.get("name", "Item")), HORIZONTAL_ALIGNMENT_LEFT, description_rect.size.x - 24.0, 18, Color("fff1b8"))
	var item_lines: Array[String] = item_description_lines(last_touched_item)
	var line_y: float = description_rect.position.y + 74.0
	var line_height: float = 15.0
	var max_lines: int = maxi(1, int(floor((description_rect.size.y - 82.0) / line_height)))
	for line_index in range(mini(item_lines.size(), max_lines)):
		draw_string(font, Vector2(description_rect.position.x + 14.0, line_y), item_lines[line_index], HORIZONTAL_ALIGNMENT_LEFT, description_rect.size.x - 24.0, 14, Color("d4eaf4"))
		line_y += line_height

func draw_rotate_button() -> void:
	var rotate_rect: Rect2 = rotate_button_rect()
	var fill: Color = ROTATE_HIGHLIGHT if rotate_hover_latched else ROTATE_FILL
	draw_rect(rotate_rect, fill, true)
	draw_rect(rotate_rect, Color("98c2d0"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, rotate_rect.position + Vector2(5.0, 18.0), "Rotate", HORIZONTAL_ALIGNMENT_LEFT, rotate_rect.size.x - 8.0, 11, Color("eef8ff"))
	draw_string(font, rotate_rect.position + Vector2(5.0, 33.0), "Hover", HORIZONTAL_ALIGNMENT_LEFT, rotate_rect.size.x - 8.0, 10, Color("d0e6ef"))
	draw_rect(toggle_rect, Color("98c2d0"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	var title: String = "Disable" if enabled else "Enable"
	var subtitle: String = "Hover" if has_item else "Touch"
	draw_string(font, toggle_rect.position + Vector2(4.0, 18.0), title, HORIZONTAL_ALIGNMENT_LEFT, toggle_rect.size.x - 8.0, 10, Color("eef8ff"))
	draw_string(font, toggle_rect.position + Vector2(4.0, 33.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, toggle_rect.size.x - 8.0, 10, Color("d0e6ef"))

func draw_dragging_item() -> void:
	if dragging_item.is_empty():
		return
	draw_inventory_item(dragging_item_rect(), dragging_item, true)

func draw_item_snap_animations() -> void:
	for animation_variant in item_snap_animations:
		var animation: Dictionary = animation_variant
		var animation_rect: Rect2 = interpolated_item_snap_rect(animation)
		draw_inventory_item(animation_rect, animation.get("item", {}), true)

func interpolated_item_snap_rect(animation: Dictionary) -> Rect2:
	var from_rect: Rect2 = animation.get("from_rect", Rect2())
	var to_rect: Rect2 = animation.get("to_rect", Rect2())
	var progress: float = clampf(float(animation.get("progress", 1.0)), 0.0, 1.0)
	var eased: float = ease_out_back(progress)
	return Rect2(
		from_rect.position.lerp(to_rect.position, eased),
		from_rect.size.lerp(to_rect.size, eased)
	)

func ease_out_back(progress: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	var t: float = progress - 1.0
	return 1.0 + c3 * t * t * t + c1 * t * t

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
	draw_item_synergy_sockets(item_rect, item)

func remember_touched_item(item: Dictionary, should_redraw: bool = true) -> void:
	if item.is_empty():
		return
	last_touched_item = item.duplicate(true)
	if should_redraw:
		queue_redraw()

func item_description_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	for line_variant in Array(item_def.get("description_lines", [])):
		lines.append(String(line_variant))
	var stats: Dictionary = item_def.get("stats", {})
	if float(stats.get("attack", 0.0)) != 0.0:
		lines.append("+%d damage" % int(round(float(stats.get("attack", 0.0)))))
	if float(stats.get("health", 0.0)) != 0.0:
		lines.append("+%d health" % int(round(float(stats.get("health", 0.0)))))
	if float(stats.get("speed", 0.0)) != 0.0:
		lines.append("+%d speed" % int(round(float(stats.get("speed", 0.0)))))
	if float(stats.get("stamina", 0.0)) != 0.0:
		lines.append("+%d stamina" % int(round(float(stats.get("stamina", 0.0)))))
	if int(stats.get("hand_size", 0)) != 0:
		lines.append("+%d hand size" % int(stats.get("hand_size", 0)))
	var card_generators: Array = []
	if item_def.has("hand_cards"):
		card_generators = Array(item_def.get("hand_cards", [])).duplicate(true)
	else:
		var hand_card: Dictionary = Dictionary(item_def.get("hand_card", {}))
		if not hand_card.is_empty():
			card_generators.append(hand_card)
	for generator_variant in card_generators:
		var generator: Dictionary = Dictionary(generator_variant)
		var card_id: String = String(generator.get("card_id", "card"))
		var generation_mode: String = String(generator.get("generation_mode", ""))
		var generator_label: String = card_id.replace("_card", "").replace("_", " ").capitalize()
		match generation_mode:
			"single":
				lines.append("Carries 1 %s card while held" % generator_label)
			"floor_once":
				lines.append("Generates 1 %s card each floor" % generator_label)
			_:
				lines.append("Adds %s every %d doors" % [generator_label, int(generator.get("door_interval", 1))])
		var max_stored_cards: int = int(generator.get("max_stored_cards", 0))
		if max_stored_cards > 0:
			lines.append("Stores at most %d ready %s card%s" % [max_stored_cards, generator_label, "" if max_stored_cards == 1 else "s"])
		var exhaust_cards: int = int(generator.get("exhaust_cards", 0))
		if exhaust_cards > 0:
			lines.append("Exhausts after %d generated cards" % exhaust_cards)
	if item_def.has("max_charges"):
		lines.append("Charges %d/%d" % [int(item.get("charges_left", item_def.get("max_charges", 0))), int(item_def.get("max_charges", 0))])
	var passive_ability: Dictionary = Dictionary(item_def.get("passive_combat_ability", {}))
	if not passive_ability.is_empty():
		lines.append("Passive combat proc every %.1fs" % float(passive_ability.get("cooldown", 1.0)))
	var tags: Array = Array(item_def.get("tags", []))
	if not tags.is_empty():
		var tag_text: String = ""
		for tag_index in range(tags.size()):
			if tag_index > 0:
				tag_text += ", "
			tag_text += String(tags[tag_index])
		lines.append("Tags: %s" % tag_text)
	if lines.is_empty():
		lines.append("No special notes.")
	return lines

func touched_inventory_item_index() -> int:
	if last_touched_item.is_empty():
		return -1
	var touched_uid: int = int(last_touched_item.get("uid", -1))
	if touched_uid < 0:
		return -1
	for item_index in range(items.size()):
		if int(items[item_index].get("uid", -1)) == touched_uid:
			return item_index
	return -1

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

func ground_item_item_rects() -> Array:
	var item_rects: Array = []
	var dock_rect: Rect2 = ground_item_content_rect()
	if ground_items.is_empty():
		return item_rects
	var columns: int = mini(maxi(int(floor(dock_rect.size.x / 120.0)), 1), maxi(ground_items.size(), 1))
	var rows: int = maxi(1, int(ceil(float(ground_items.size()) / float(columns))))
	var gap: float = 8.0
	var slot_width: float = (dock_rect.size.x - gap * float(columns - 1)) / float(columns)
	var slot_height: float = (dock_rect.size.y - gap * float(rows - 1)) / float(rows)
	for item_index in range(ground_items.size()):
		var row: int = item_index / columns
		var column: int = item_index % columns
		item_rects.append(Rect2(
			dock_rect.position + Vector2(float(column) * (slot_width + gap), float(row) * (slot_height + gap)),
			Vector2(slot_width, slot_height)
		))
	return item_rects

func ground_item_display_rect(slot_rect: Rect2, item: Dictionary) -> Rect2:
	var size_cells: Vector2i = item_size_in_cells(item)
	var max_cell_extent: float = minf(slot_rect.size.x / maxf(float(size_cells.x), 1.0), slot_rect.size.y / maxf(float(size_cells.y), 1.0))
	var item_size_pixels: Vector2 = Vector2(size_cells) * minf(max_cell_extent, cell_size() * 0.92)
	return Rect2(slot_rect.get_center() - item_size_pixels * 0.5, item_size_pixels)

func ground_item_hit_rect(slot_rect: Rect2) -> Rect2:
	var hit_size: Vector2 = Vector2(
		maxf(slot_rect.size.x + GROUND_ITEM_TOUCH_PADDING * 2.0, GROUND_ITEM_MIN_HIT_SIZE),
		maxf(slot_rect.size.y + GROUND_ITEM_TOUCH_PADDING * 2.0, GROUND_ITEM_MIN_HIT_SIZE)
	)
	return Rect2(slot_rect.get_center() - hit_size * 0.5, hit_size)

func ground_item_index_at(local_position: Vector2) -> int:
	var item_rects: Array = ground_item_item_rects()
	var best_index: int = -1
	var best_distance: float = INF
	for item_index in range(item_rects.size()):
		var slot_rect: Rect2 = item_rects[item_index]
		if not ground_item_hit_rect(slot_rect).has_point(local_position):
			continue
		var center_distance: float = slot_rect.get_center().distance_squared_to(local_position)
		if slot_rect.has_point(local_position):
			center_distance *= 0.45
		if center_distance < best_distance:
			best_distance = center_distance
			best_index = item_index
	return best_index

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
	var anchor_x: int = int(round((top_left.x - grid.position.x) / cell_size()))
	var anchor_y: int = int(round((top_left.y - grid.position.y) / cell_size()))
	return Vector2i(anchor_x, anchor_y)

func preview_anchor_for_pack(pack_module: Dictionary, local_position: Vector2) -> Vector2i:
	var grid: Rect2 = grid_rect()
	var pack_size_cells: Vector2i = pack_module.get("size", Vector2i.ONE)
	var pack_size_pixels: Vector2 = Vector2(pack_size_cells) * cell_size()
	var top_left: Vector2 = local_position - pack_size_pixels * 0.5
	var anchor_position: Vector2 = (top_left - grid.position) / cell_size()
	var rounded_anchor: Vector2i = Vector2i(
		int(round(anchor_position.x)),
		int(round(anchor_position.y))
	)
	var best_anchor: Vector2i = INVALID_CELL
	var best_distance: float = INF
	var min_x: int = maxi(0, rounded_anchor.x - PACK_SNAP_SEARCH_RADIUS)
	var max_x: int = mini(inventory_canvas_size.x - pack_size_cells.x, rounded_anchor.x + PACK_SNAP_SEARCH_RADIUS)
	var min_y: int = maxi(0, rounded_anchor.y - PACK_SNAP_SEARCH_RADIUS)
	var max_y: int = mini(inventory_canvas_size.y - pack_size_cells.y, rounded_anchor.y + PACK_SNAP_SEARCH_RADIUS)
	for anchor_y in range(min_y, max_y + 1):
		for anchor_x in range(min_x, max_x + 1):
			var candidate_anchor: Vector2i = Vector2i(anchor_x, anchor_y)
			if not can_place_pack(pack_module, candidate_anchor):
				continue
			var candidate_distance: float = Vector2(candidate_anchor).distance_squared_to(anchor_position)
			if candidate_distance < best_distance:
				best_distance = candidate_distance
				best_anchor = candidate_anchor
	if best_anchor != INVALID_CELL:
		return best_anchor
	return rounded_anchor

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

func inventory_item_has_tag(item: Dictionary, tag_name: String) -> bool:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	return Array(item_def.get("tags", [])).has(tag_name)

func rotated_socket_offset(item: Dictionary, socket_offset: Vector2i) -> Vector2i:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	if not bool(item.get("rotated", false)):
		return socket_offset
	return Vector2i(base_size.y - 1 - socket_offset.y, socket_offset.x)

func draw_item_synergy_sockets(item_rect: Rect2, item: Dictionary) -> void:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var sockets: Array = Array(item_def.get("synergy_sockets", []))
	var anchor: Vector2i = item.get("anchor", INVALID_CELL)
	if sockets.is_empty() or anchor == INVALID_CELL:
		return
	var socket_cell_size: float = cell_size()
	for socket_variant in sockets:
		var socket_rule: Dictionary = socket_variant
		var socket_offset: Vector2i = rotated_socket_offset(item, Vector2i(socket_rule.get("offset", Vector2i.ZERO)))
		var target_cell: Vector2i = anchor + socket_offset
		var socket_center: Vector2 = grid_rect().position + (Vector2(anchor + socket_offset) + Vector2(0.5, 0.5)) * socket_cell_size
		var socket_matched: bool = false
		for other_item_variant in items:
			var other_item: Dictionary = other_item_variant
			if int(other_item.get("uid", -1)) == int(item.get("uid", -1)):
				continue
			if not inventory_item_has_tag(other_item, String(socket_rule.get("tag", ""))):
				continue
			if occupied_cells_for_item(other_item).has(target_cell):
				socket_matched = true
				break
		var star_radius: float = clampf(socket_cell_size * 0.16, 5.0, 8.5)
		var star_fill: Color = Color("fff6ca") if socket_matched else Color(1.0, 1.0, 1.0, 0.18)
		var star_outline: Color = Color("ffe083") if socket_matched else Color("92aeb9")
		draw_colored_polygon(star_points(socket_center, star_radius), star_fill)
		draw_polyline(star_points(socket_center, star_radius, star_radius * 0.46), star_outline, 1.6, true)

func star_points(center: Vector2, outer_radius: float, inner_radius: float = -1.0) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var resolved_inner: float = inner_radius if inner_radius > 0.0 else outer_radius * 0.48
	for point_index in range(10):
		var angle: float = -PI * 0.5 + float(point_index) * TAU / 10.0
		var radius: float = outer_radius if point_index % 2 == 0 else resolved_inner
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	points.append(points[0])
	return points

func base_cells_map() -> Dictionary:
	var active_cells: Dictionary = {}
	for offset_y in range(base_size.y):
		for offset_x in range(base_size.x):
			active_cells[base_origin + Vector2i(offset_x, offset_y)] = true
	return active_cells

func base_cells() -> Array:
	var cells: Array = []
	for offset_y in range(base_size.y):
		for offset_x in range(base_size.x):
			cells.append(base_origin + Vector2i(offset_x, offset_y))
	return cells

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

func rotate_pack_module(pack_module: Dictionary) -> void:
	var pack_size: Vector2i = pack_module.get("size", Vector2i.ONE)
	pack_module["size"] = Vector2i(pack_size.y, pack_size.x)

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
	draw_module_outline(base_cells(), GRID_BASE_OUTLINE, 3.0)
	draw_string(ThemeDB.fallback_font, core_rect.position + Vector2(8.0, 18.0), "CORE", HORIZONTAL_ALIGNMENT_LEFT, core_rect.size.x - 12.0, 14, GRID_BASE_OUTLINE)

func draw_pack_outlines() -> void:
	for pack_index in range(pack_modules.size()):
		var pack_module: Dictionary = pack_modules[pack_index]
		var module_rect: Rect2 = pack_rect(pack_module)
		var outline_color: Color = GRID_PACK_HIGHLIGHT if pack_index == highlighted_pack_index and highlighted_pack_timer > 0.0 else GRID_PACK_OUTLINE
		var fill_color: Color = Color(1.0, 0.95, 0.68, 0.08) if outline_color == GRID_PACK_HIGHLIGHT else Color.TRANSPARENT
		if fill_color.a > 0.0:
			draw_rect(module_rect.grow(1.0), fill_color, true)
		draw_module_outline(pack_cells(pack_module), outline_color, 3.0)
		draw_pack_handle_marks(module_rect)
		if module_rect.size.x >= 42.0 and module_rect.size.y >= 26.0:
			draw_string(ThemeDB.fallback_font, module_rect.position + Vector2(8.0, 18.0), "PACK", HORIZONTAL_ALIGNMENT_LEFT, module_rect.size.x - 12.0, 14, outline_color)

func draw_module_outline(module_cells: Array, outline_color: Color, line_width: float) -> void:
	var active_cells: Dictionary = active_cells_from_current_layout()
	var grid: Rect2 = grid_rect()
	var step: float = cell_size()
	for cell_variant in module_cells:
		var cell: Vector2i = cell_variant
		var origin: Vector2 = grid.position + Vector2(cell) * step
		if not active_cells.has(cell + Vector2i.UP):
			draw_line(origin, origin + Vector2(step, 0.0), outline_color, line_width, true)
		if not active_cells.has(cell + Vector2i.RIGHT):
			draw_line(origin + Vector2(step, 0.0), origin + Vector2(step, step), outline_color, line_width, true)
		if not active_cells.has(cell + Vector2i.DOWN):
			draw_line(origin + Vector2(0.0, step), origin + Vector2(step, step), outline_color, line_width, true)
		if not active_cells.has(cell + Vector2i.LEFT):
			draw_line(origin, origin + Vector2(0.0, step), outline_color, line_width, true)

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
	if dragging_from_ground:
		var restore_index: int = clampi(dragging_ground_source_index, 0, ground_items.size())
		ground_items.insert(restore_index, item)
	else:
		var restore_index: int = clampi(dragging_source_index, 0, items.size())
		items.insert(restore_index, item)

func start_item_snap_animation(item: Dictionary, from_rect: Rect2, to_rect: Rect2) -> void:
	var animation_id: int = next_item_snap_animation_id
	next_item_snap_animation_id += 1
	item["_snap_anim_id"] = animation_id
	item_snap_animations.append({
		"id": animation_id,
		"item": item.duplicate(true),
		"from_rect": from_rect,
		"to_rect": to_rect,
		"timer_left": ITEM_SNAP_DURATION,
		"progress": 0.0,
	})

func advance_item_snap_animations(delta: float) -> bool:
	if item_snap_animations.is_empty():
		return false
	var active_animations: Array = []
	var changed: bool = false
	for animation_variant in item_snap_animations:
		var animation: Dictionary = animation_variant
		var timer_left: float = maxf(float(animation.get("timer_left", 0.0)) - delta, 0.0)
		animation["timer_left"] = timer_left
		animation["progress"] = 1.0 - timer_left / ITEM_SNAP_DURATION if ITEM_SNAP_DURATION > 0.0 else 1.0
		if timer_left <= 0.0:
			clear_item_snap_marker(int(animation.get("id", -1)))
		else:
			active_animations.append(animation)
		changed = true
	item_snap_animations = active_animations
	return changed

func clear_item_snap_marker(animation_id: int) -> void:
	if animation_id < 0:
		return
	for item_index in range(items.size()):
		if int(items[item_index].get("_snap_anim_id", -1)) == animation_id:
			items[item_index].erase("_snap_anim_id")
			return

func item_is_animating(item: Dictionary) -> bool:
	var animation_id: int = int(item.get("_snap_anim_id", -1))
	if animation_id < 0:
		return false
	for animation_variant in item_snap_animations:
		if int((animation_variant as Dictionary).get("id", -1)) == animation_id:
			return true
	return false

func _emit_inventory_changed() -> void:
	var snapshot: Array = []
	for item_variant in items:
		snapshot.append(clean_item_snapshot(item_variant))
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
