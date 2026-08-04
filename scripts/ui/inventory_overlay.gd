extends Control
class_name InventoryOverlay

signal close_requested
signal inventory_changed(items: Array)
signal item_dropped(item: Dictionary)
signal pack_layout_changed(pack_modules: Array)
signal level_up_requested
signal spellbook_slots_changed(slotted_spells: Array)

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
const PREVIEW_BONUS_COLOR: Color = Color("8fe38f")
const PACK_SNAP_DURATION: float = 0.18
const LEVEL_HOLD_DURATION: float = 0.7
const SPELLBOOK_ACTION_HOLD_DURATION: float = 0.5
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
const ITEM_LEVEL_COLORS: Array[Color] = [
	Color("7a8a94"),
	Color("6ea877"),
	Color("5c8fcd"),
	Color("c59a62"),
	Color("c96767"),
	Color("8e9bd6"),
]
const ITEM_SYMBOLS: Dictionary = {
	"axe": "R",
	"daggers": "D",
	"ricochet_dagger": "C",
	"cloak_of_shadows": "S",
	"rogue_bandolier": "R",
	"fighter_emergency_snack": "F",
	"cleric_emergency_snack": "C",
	"rogue_emergency_snack": "J",
	"wizard_emergency_snack": "M",
	"arcana_conduit": "Q",
	"serpent_venom": "V",
	"wyvern_toxin": "X",
	"blacklotus_oil": "O",
	"boots": "B",
	"whirling_blade": "W",
	"sunpepper_jerky": "J",
	"moon_truffle": "U",
	"tidekelp_roll": "T",
	"buckler": "K",
	"lantern": "L",
	"spellbook": "P",
	"holy_symbol": "H",
	"scroll_fireball": "1",
	"scroll_magic_missile": "2",
	"scroll_misty_step": "3",
	"scroll_web": "4",
	"scroll_shield": "5",
	"scroll_scorching_ray": "6",
	"scroll_lightning_bolt": "7",
	"scroll_light_cantrip": "8",
	"scroll_scry": "9",
	"scroll_summon_arcane_sentinel": "Q",
	"scroll_cure_light_wounds": "C",
	"scroll_sanctuary": "Y",
	"scroll_hold_person": "O",
	"scroll_fear": "F",
	"scroll_spiritual_weapon": "W",
	"scroll_summon_warden_spirit": "Z",
}

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
var spellbook_action_hold_active: bool = false
var spellbook_action_hold_completed: bool = false
var spellbook_action_hold_progress: float = 0.0
var swipe_close_tracking: bool = false
var swipe_close_active: bool = false
var swipe_close_start_local: Vector2 = Vector2.ZERO
var swipe_close_offset_y: float = 0.0
var inventory_open_count: int = 0
var inventory_nudge_timer: float = -1.0
var last_touched_item: Dictionary = {}
var spellbook_enabled: bool = false
var spellbook_known: Array[String] = []
var spellbook_slotted: Array[String] = []
var spellbook_slot_capacity: int = 0
var spellbook_editable: bool = false
var spellbook_title: String = "Spellbook"
var spellbook_prep_note: String = ""
var spellbook_focus_item_id: String = "spellbook"
var selected_spellbook_spell_id: String = ""
var spellbook_overlay_open: bool = false
var synergy_shine_time: float = 0.0
var fusion_glow_uids: Dictionary = {}
var fusion_links: Array = []

@onready var layout_root: Control = $LayoutRoot
@onready var main_panel_guide: Control = $LayoutRoot/MainPanelGuide
@onready var title_label: Label = $LayoutRoot/MainPanelGuide/TitleLabel
@onready var stats_guide: Control = $LayoutRoot/MainPanelGuide/StatsGuide
@onready var description_guide: Control = $LayoutRoot/MainPanelGuide/DescriptionGuide
@onready var loot_guide: Control = $LayoutRoot/MainPanelGuide/LootGuide
@onready var rotate_button_node: Button = $LayoutRoot/MainPanelGuide/RotateButton
@onready var toggle_button_node: Button = $LayoutRoot/MainPanelGuide/ToggleButton
@onready var spellbook_overlay_node: Variant = $SpellbookOverlay

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prepare_runtime_guides()
	if spellbook_overlay_node != null:
		spellbook_overlay_node.close_requested.connect(_on_spellbook_overlay_close_requested)
		spellbook_overlay_node.slots_changed.connect(_on_spellbook_overlay_slots_changed)
	update_layout_nodes()
	visible = false

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			pointer_press(touch_event.position)
		else:
			pointer_release(touch_event.position)
		accept_event()
		return
	if event is InputEventScreenDrag:
		pointer_move(event.position)
		accept_event()
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			pointer_press(mouse_event.position)
		else:
			pointer_release(mouse_event.position)
		accept_event()
		return
	if event is InputEventMouseMotion:
		pointer_move(event.position)
		accept_event()

func _process(delta: float) -> void:
	var needs_redraw: bool = false
	update_layout_nodes()
	if visible:
		synergy_shine_time += delta
		needs_redraw = true
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
	if spellbook_action_hold_active:
		if not spell_focus_selected_item():
			reset_spellbook_action_hold()
		else:
			spellbook_action_hold_progress = minf(spellbook_action_hold_progress + delta / SPELLBOOK_ACTION_HOLD_DURATION, 1.0)
			if spellbook_action_hold_progress >= 1.0 and not spellbook_action_hold_completed:
				spellbook_action_hold_completed = true
				spellbook_action_hold_active = false
				toggle_spellbook_overlay()
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
		rotate_button_node.visible = not spellbook_overlay_open
	if toggle_button_node != null:
		toggle_button_node.visible = false

func control_local_rect(control: Control) -> Rect2:
	return Rect2(screen_to_local(control.get_global_rect().position), control.size)

func configure(next_hero_name: String, next_hero_level: int, next_food_value: int, next_level_up_cost: int, next_can_level_up: bool, next_stats_lines: Array, next_ability_sections: Array, next_level_up_reward_lines: Array, next_inventory_canvas_size: Vector2i, next_base_origin: Vector2i, next_base_size: Vector2i, next_pack_modules: Array, next_item_defs: Dictionary, next_items: Array, next_ground_items: Array, next_loot_enabled: bool, next_spellbook_data: Dictionary = {}) -> void:
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
	apply_spellbook_data(next_spellbook_data)
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
	reset_spellbook_action_hold()
	close_spellbook_overlay()
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
	reset_spellbook_action_hold()
	inventory_nudge_timer = -1.0
	last_touched_item.clear()
	close_spellbook_overlay()
	queue_redraw()

func refresh_state(next_stats_lines: Array, next_ability_sections: Array, next_level_up_reward_lines: Array, next_food_value: int, next_level_up_cost: int, next_can_level_up: bool, next_hero_level: int, next_pack_modules: Array, next_spellbook_data: Dictionary = {}) -> void:
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
	apply_spellbook_data(next_spellbook_data)
	reset_swipe_close_state()
	swipe_close_offset_y = 0.0
	reset_level_hold()
	reset_spellbook_action_hold()
	update_layout_nodes()
	queue_redraw()

func apply_spellbook_data(next_spellbook_data: Dictionary) -> void:
	spellbook_enabled = bool(next_spellbook_data.get("enabled", false))
	spellbook_editable = bool(next_spellbook_data.get("editable", false))
	spellbook_title = String(next_spellbook_data.get("title", "Spellbook"))
	spellbook_prep_note = String(next_spellbook_data.get("prep_note", ""))
	spellbook_focus_item_id = String(next_spellbook_data.get("focus_item_id", "spellbook"))
	fusion_glow_uids.clear()
	fusion_links.clear()
	for uid_variant in Array(next_spellbook_data.get("fusion_glow_uids", [])):
		var uid: int = int(uid_variant)
		if uid >= 0:
			fusion_glow_uids[uid] = true
	for link_variant in Array(next_spellbook_data.get("fusion_links", [])):
		var link_entry: Dictionary = Dictionary(link_variant)
		var left_uid: int = int(link_entry.get("left_uid", -1))
		var right_uid: int = int(link_entry.get("right_uid", -1))
		if left_uid < 0 or right_uid < 0:
			continue
		fusion_links.append({
			"left_uid": left_uid,
			"right_uid": right_uid,
		})
	spellbook_known.clear()
	for spell_variant in Array(next_spellbook_data.get("known", [])):
		spellbook_known.append(String(spell_variant))
	spellbook_slotted.clear()
	for spell_variant in Array(next_spellbook_data.get("slotted", [])):
		spellbook_slotted.append(String(spell_variant))
	spellbook_slot_capacity = maxi(0, int(next_spellbook_data.get("capacity", 0)))
	if selected_spellbook_spell_id != "" and not spellbook_known.has(selected_spellbook_spell_id):
		selected_spellbook_spell_id = ""
	if spellbook_overlay_node != null:
		spellbook_overlay_node.configure_overlay(next_spellbook_data)
	if not spellbook_enabled:
		close_spellbook_overlay()

func spell_focus_selected_item() -> bool:
	return spellbook_enabled and String(last_touched_item.get("item_id", "")) == spellbook_focus_item_id

func toggle_spellbook_overlay() -> void:
	if not spell_focus_selected_item():
		return
	reset_spellbook_action_hold()
	spellbook_overlay_open = not spellbook_overlay_open
	if not spellbook_overlay_open:
		selected_spellbook_spell_id = ""
	if spellbook_overlay_node != null:
		if spellbook_overlay_open:
			spellbook_overlay_node.open_overlay()
		else:
			spellbook_overlay_node.hide_overlay()
	queue_redraw()

func close_spellbook_overlay() -> void:
	reset_spellbook_action_hold()
	spellbook_overlay_open = false
	if spellbook_overlay_node != null:
		spellbook_overlay_node.hide_overlay()
	if not visible:
		return
	spellbook_overlay_open = false
	selected_spellbook_spell_id = ""
	queue_redraw()

func pointer_press(screen_position: Vector2) -> void:
	if not visible:
		return
	cancel_inventory_nudge_hint()
	var local_position: Vector2 = screen_to_local(screen_position)
	if level_hold_active or level_hold_completed or spellbook_action_hold_active or spellbook_action_hold_completed:
		return
	if spellbook_overlay_open and spellbook_overlay_node != null:
		spellbook_overlay_node.pointer_press(screen_position)
		return
	if level_up_button_rect().has_point(local_position) and can_level_up:
		begin_level_hold()
		return
	if spell_focus_selected_item() and spellbook_action_touch_rect().has_point(local_position):
		begin_spellbook_action_hold()
		return
	if handle_spellbook_pointer_press(local_position):
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
	if spellbook_overlay_open and spellbook_overlay_node != null:
		spellbook_overlay_node.pointer_move(screen_position)
		return
	if spellbook_action_hold_active:
		if not spell_focus_selected_item() or not spellbook_action_touch_rect().has_point(drag_pointer_local):
			reset_spellbook_action_hold()
		else:
			queue_redraw()
		return
	if spellbook_action_hold_completed:
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
	if spellbook_action_hold_active or spellbook_action_hold_completed:
		reset_spellbook_action_hold()
		return
	if spellbook_overlay_open and spellbook_overlay_node != null:
		spellbook_overlay_node.pointer_release(screen_position)
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

func begin_spellbook_action_hold() -> void:
	spellbook_action_hold_active = true
	spellbook_action_hold_completed = false
	spellbook_action_hold_progress = 0.0
	queue_redraw()

func reset_spellbook_action_hold() -> void:
	spellbook_action_hold_active = false
	spellbook_action_hold_completed = false
	spellbook_action_hold_progress = 0.0
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
	draw_item_synergy_overlay()

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
		var stat_line: String = stats_lines[stat_index]
		draw_string(font, Vector2(left_rect.position.x, stats_y), stat_line, HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x, 15, Color("d4eaf4"))
		var preview_suffix: String = dragging_item_stat_preview_suffix(stat_line)
		if preview_suffix != "":
			var base_width: float = font.get_string_size(stat_line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x
			draw_string(font, Vector2(left_rect.position.x + base_width + 8.0, stats_y), preview_suffix, HORIZONTAL_ALIGNMENT_LEFT, maxf(left_rect.size.x - base_width - 8.0, 0.0), 15, PREVIEW_BONUS_COLOR)
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
		draw_inventory_item(item_rect_for_anchor(item), item, false, item_should_glow_for_fusion(item))
	draw_item_snap_animations()
	draw_item_fusion_links()
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
		draw_inventory_item(ground_item_display_rect(slot_rect, ground_items[item_index]), ground_items[item_index], true, item_should_glow_for_fusion(ground_items[item_index]))

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
	var wrapped_lines: Array = []
	var max_text_width: float = description_rect.size.x - 24.0
	for raw_line in item_lines:
		var line_text: String = String(raw_line)
		var line_color: Color = PREVIEW_BONUS_COLOR if line_text.begins_with("[") and line_text.ends_with("]") else Color("d4eaf4")
		for wrapped_line in wrap_text_for_width(font, line_text, max_text_width, 14):
			wrapped_lines.append({
				"text": wrapped_line,
				"color": line_color,
			})
	var line_y: float = description_rect.position.y + 74.0
	var line_height: float = 15.0
	var max_description_bottom: float = description_rect.position.y + description_rect.size.y - 8.0
	if spell_focus_selected_item():
		max_description_bottom = spellbook_action_button_rect().position.y - 10.0
	var max_lines: int = maxi(1, int(floor((max_description_bottom - line_y) / line_height)))
	var wrapped_count: int = wrapped_lines.size()
	var visible_lines: int = mini(wrapped_count, max_lines)
	var truncated: bool = wrapped_count > max_lines
	if truncated:
		visible_lines = maxi(0, max_lines - 1)
	for line_index in range(visible_lines):
		var draw_line: Dictionary = wrapped_lines[line_index]
		draw_string(font, Vector2(description_rect.position.x + 14.0, line_y), String(draw_line.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, max_text_width, 14, draw_line.get("color", Color("d4eaf4")))
		line_y += line_height
	if truncated and max_lines > 0:
		draw_string(font, Vector2(description_rect.position.x + 14.0, line_y), "...", HORIZONTAL_ALIGNMENT_LEFT, max_text_width, 14, Color("9fb8c2"))
	if spell_focus_selected_item():
		draw_spellbook_action_button(font)

func wrap_text_for_width(font: Font, text: String, max_width: float, font_size: int) -> Array[String]:
	var wrapped: Array[String] = []
	var source_text: String = text.strip_edges()
	if source_text == "":
		wrapped.append("")
		return wrapped
	for source_line in source_text.split("\n"):
		var words: PackedStringArray = source_line.split(" ", false)
		if words.is_empty():
			wrapped.append("")
			continue
		var current_line: String = ""
		for word in words:
			var candidate: String = word if current_line == "" else "%s %s" % [current_line, word]
			if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x <= max_width:
				current_line = candidate
				continue
			if current_line != "":
				wrapped.append(current_line)
			if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x <= max_width:
				current_line = word
				continue
			var remainder: String = word
			while remainder.length() > 0:
				var chunk: String = ""
				var char_index: int = 0
				while char_index < remainder.length():
					var next_chunk: String = chunk + remainder.substr(char_index, 1)
					if chunk != "" and font.get_string_size(next_chunk, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > max_width:
						break
					chunk = next_chunk
					char_index += 1
				if chunk == "":
					chunk = remainder.substr(0, 1)
					char_index = 1
				wrapped.append(chunk)
				remainder = remainder.substr(char_index)
			current_line = ""
		if current_line != "":
			wrapped.append(current_line)
	if wrapped.is_empty():
		wrapped.append(source_text)
	return wrapped
		
func draw_spellbook_action_button(font: Font) -> void:
	var action_rect: Rect2 = spellbook_action_button_rect()
	if action_rect.size.x <= 8.0 or action_rect.size.y <= 8.0:
		return
	draw_rect(action_rect, Color("2a3f4c"), true)
	if spellbook_action_hold_progress > 0.0:
		var progress_fill_rect: Rect2 = Rect2(action_rect.position + Vector2(3.0, 3.0), Vector2((action_rect.size.x - 6.0) * spellbook_action_hold_progress, action_rect.size.y - 6.0))
		draw_rect(progress_fill_rect, Color(LEVEL_BUTTON_PROGRESS, 0.32), true)
	draw_rect(action_rect, Color("9fb8c8"), false, 1.5)
	var label: String = "Prepare Spells" if spellbook_editable else "View Prepared"
	draw_string(font, action_rect.position + Vector2(12.0, 22.0), label, HORIZONTAL_ALIGNMENT_LEFT, action_rect.size.x - 24.0, 16, Color("eef8ff"))
	var hold_text: String = "Hold to open %s" % spellbook_title.to_lower()
	if spellbook_action_hold_active:
		hold_text = "Keep holding %d%%" % int(spellbook_action_hold_progress * 100.0)
	elif spellbook_action_hold_completed:
		hold_text = "Opening..."
	draw_string(font, action_rect.position + Vector2(12.0, 39.0), hold_text, HORIZONTAL_ALIGNMENT_LEFT, action_rect.size.x - 24.0, 12, Color("c8dde8"))

func draw_spellbook_panel(font: Font) -> void:
	var panel: Rect2 = spellbook_panel_rect()
	if panel.size.x <= 12.0 or panel.size.y <= 12.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP_COLOR, true)
	draw_rect(panel, Color("0b1419"), true)
	draw_rect(panel, Color("7d8fb8"), false, 2.0)
	draw_string(font, panel.position + Vector2(18.0, 28.0), spellbook_title, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x * 0.52, 24, Color("e8dcff"))
	draw_string(font, panel.position + Vector2(panel.size.x - 150.0, 28.0), "%d/%d slots" % [spellbook_slotted.size(), spellbook_slot_capacity], HORIZONTAL_ALIGNMENT_LEFT, 100.0, 18, Color("cdd9ff"))
	var instruction_text: String = "Tap a spell, then tap a slot." if spellbook_editable else "Prepared spells are locked after the first door."
	draw_string(font, panel.position + Vector2(18.0, 54.0), instruction_text, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 180.0, 14, Color("a8bfd6"))
	if spellbook_prep_note != "":
		draw_string(font, panel.position + Vector2(18.0, 72.0), spellbook_prep_note, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 180.0, 13, Color("fff1b8"))
	var close_rect: Rect2 = spellbook_close_button_rect()
	draw_rect(close_rect, Color("2a3f4c"), true)
	draw_rect(close_rect, Color("9fb8c8"), false, 1.5)
	draw_string(font, close_rect.position + Vector2(16.0, 23.0), "Close", HORIZONTAL_ALIGNMENT_LEFT, close_rect.size.x - 22.0, 16, Color("eef8ff"))
	var known_rect: Rect2 = spellbook_known_column_rect()
	var slots_rect: Rect2 = spellbook_slot_column_rect()
	draw_string(font, known_rect.position + Vector2(0.0, 0.0), "Known", HORIZONTAL_ALIGNMENT_LEFT, known_rect.size.x, 18, Color("fff1b8"))
	draw_string(font, slots_rect.position + Vector2(0.0, 0.0), "Prepared", HORIZONTAL_ALIGNMENT_LEFT, slots_rect.size.x, 18, Color("fff1b8"))
	if spellbook_known.is_empty():
		draw_string(font, known_rect.position + Vector2(0.0, 28.0), "No learned spells.", HORIZONTAL_ALIGNMENT_LEFT, known_rect.size.x, 16, Color("9fb8c2"))
	else:
		for spell_index in range(spellbook_known.size()):
			var row_rect: Rect2 = spellbook_known_row_rect(spell_index)
			var spell_id: String = spellbook_known[spell_index]
			var selected: bool = spell_id == selected_spellbook_spell_id
			var prepared: bool = spellbook_slotted.has(spell_id)
			var row_fill: Color = Color("394b66") if selected else Color("243841")
			var row_outline: Color = Color("b99fff") if selected else Color("6a88a3")
			if not spellbook_editable:
				row_fill = row_fill.darkened(0.18)
				row_outline = row_outline.darkened(0.2)
			draw_rect(row_rect, row_fill, true)
			draw_rect(row_rect, row_outline, false, 1.0)
			draw_string(font, row_rect.position + Vector2(10.0, 22.0), spell_display_name_local(spell_id), HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 20.0, 15, Color("edf5ff"))
			if prepared:
				draw_string(font, row_rect.position + Vector2(row_rect.size.x - 46.0, 22.0), "SET", HORIZONTAL_ALIGNMENT_LEFT, 36.0, 12, Color("ffe28a"))
	for slot_index in range(spellbook_slot_capacity):
		var slot_rect: Rect2 = spellbook_slot_rect(slot_index)
		var slotted_spell_id: String = spellbook_slotted[slot_index] if slot_index < spellbook_slotted.size() else ""
		draw_rect(slot_rect, Color("243841"), true)
		draw_rect(slot_rect, Color("6a88a3"), false, 1.0)
		var slot_label: String = "Slot %d" % [slot_index + 1]
		draw_string(font, slot_rect.position + Vector2(10.0, 18.0), slot_label, HORIZONTAL_ALIGNMENT_LEFT, slot_rect.size.x - 20.0, 13, Color("b9d8e4"))
		var slot_spell_name: String = spell_display_name_local(slotted_spell_id) if slotted_spell_id != "" else "Empty"
		var slot_color: Color = Color("edf5ff") if slotted_spell_id != "" else Color("8ea5b4")
		draw_string(font, slot_rect.position + Vector2(10.0, 38.0), slot_spell_name, HORIZONTAL_ALIGNMENT_LEFT, slot_rect.size.x - 20.0, 15, slot_color)

func draw_rotate_button() -> void:
	var rotate_rect: Rect2 = rotate_button_rect()
	var fill: Color = ROTATE_HIGHLIGHT if rotate_hover_latched else ROTATE_FILL
	draw_rect(rotate_rect, fill, true)
	draw_rect(rotate_rect, Color("98c2d0"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, rotate_rect.position + Vector2(5.0, 18.0), "Rotate", HORIZONTAL_ALIGNMENT_LEFT, rotate_rect.size.x - 8.0, 11, Color("eef8ff"))
	draw_string(font, rotate_rect.position + Vector2(5.0, 33.0), "Hover", HORIZONTAL_ALIGNMENT_LEFT, rotate_rect.size.x - 8.0, 10, Color("d0e6ef"))

func draw_dragging_item() -> void:
	if dragging_item.is_empty():
		return
	draw_inventory_item(dragging_item_rect(), dragging_item, true, item_should_glow_for_fusion(dragging_item))

func draw_item_snap_animations() -> void:
	for animation_variant in item_snap_animations:
		var animation: Dictionary = animation_variant
		var animation_rect: Rect2 = interpolated_item_snap_rect(animation)
		var animated_item: Dictionary = Dictionary(animation.get("item", {}))
		draw_inventory_item(animation_rect, animated_item, true, item_should_glow_for_fusion(animated_item))

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

func draw_inventory_item(item_rect: Rect2, item: Dictionary, emphasize: bool, fusion_glow: bool = false) -> void:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var item_id: String = String(item.get("item_id", ""))
	var item_level: int = maxi(0, int(item.get("item_level", item_def.get("item_level", 1))))
	var size_cells: Vector2i = item_size_in_cells(item)
	var footprint_cells: Array = item_footprint_offsets(item)
	if fusion_glow:
		var glow_pulse: float = 0.5 + 0.5 * sin(synergy_shine_time * 7.0 + float(int(item.get("uid", -1)) % 11))
		draw_rect(item_rect.grow(5.0 + glow_pulse * 1.8), Color(0.98, 0.90, 0.52, 0.16 + glow_pulse * 0.14), true)
	var fill: Color = item_level_color(item_level)
	if emphasize:
		fill = fill.lightened(0.12)
	if footprint_cells.is_empty():
		draw_rect(item_rect, fill, true)
	else:
		for footprint_cell_variant in footprint_cells:
			var footprint_cell: Vector2i = footprint_cell_variant
			draw_rect(item_cell_rect(item_rect, size_cells, footprint_cell), fill, true)
	var identity_tint: Color = item_def.get("color", Color("eff8ff"))
	if footprint_cells.is_empty():
		draw_rect(item_rect, identity_tint.lightened(0.34), false, 2.0)
	else:
		for footprint_cell_variant in footprint_cells:
			var footprint_cell: Vector2i = footprint_cell_variant
			draw_rect(item_cell_rect(item_rect, size_cells, footprint_cell), identity_tint.lightened(0.34), false, 2.0)
	if fusion_glow:
		draw_rect(item_rect.grow(1.0), Color(1.0, 0.95, 0.72, 0.88), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	var item_name: String = String(item_def.get("name", "Item"))
	var short_label: String = String(item_def.get("short", item_name.substr(0, mini(item_name.length(), 3)).to_upper()))
	var compact_tile: bool = item_rect.size.x < 96.0 or item_rect.size.y < 68.0
	var symbol: String = item_symbol_for_item(item_id, short_label)
	var symbol_size: int = 22 if compact_tile else 28
	draw_string(font, item_rect.position + Vector2(item_rect.size.x * 0.5 - 10.0, item_rect.size.y * 0.5 + 8.0), symbol, HORIZONTAL_ALIGNMENT_LEFT, 24.0, symbol_size, Color("0e171c"))
	var level_badge: Rect2 = Rect2(item_rect.position + Vector2(item_rect.size.x - 34.0, 4.0), Vector2(30.0, 14.0))
	draw_rect(level_badge, Color(0.06, 0.11, 0.14, 0.46), true)
	draw_rect(level_badge, Color(0.90, 0.96, 1.0, 0.62), false, 1.0)
	draw_string(font, level_badge.position + Vector2(4.0, 11.0), "L%d" % item_level, HORIZONTAL_ALIGNMENT_LEFT, level_badge.size.x - 6.0, 11, Color("eaf6ff"))
	if compact_tile:
		draw_string(font, item_rect.position + Vector2(6.0, 14.0), short_label, HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 40.0, 12, Color("eef7ff"))
		return
	draw_string(font, item_rect.position + Vector2(8.0, 18.0), short_label, HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 40.0, 13, Color("eef7ff"))
	draw_string(font, item_rect.position + Vector2(8.0, item_rect.size.y - 8.0), item_name, HORIZONTAL_ALIGNMENT_LEFT, item_rect.size.x - 12.0, 13, Color("f0f8ff"))

func item_level_color(item_level: int) -> Color:
	if ITEM_LEVEL_COLORS.is_empty():
		return Color("7a8a94")
	var palette_index: int = clampi(item_level, 1, ITEM_LEVEL_COLORS.size()) - 1
	return ITEM_LEVEL_COLORS[palette_index]

func draw_item_fusion_links() -> void:
	for link_variant in fusion_links:
		var link_entry: Dictionary = link_variant
		var left_uid: int = int(link_entry.get("left_uid", -1))
		var right_uid: int = int(link_entry.get("right_uid", -1))
		var left_rect: Rect2 = item_rect_for_uid(left_uid)
		var right_rect: Rect2 = item_rect_for_uid(right_uid)
		if left_rect.size == Vector2.ZERO or right_rect.size == Vector2.ZERO:
			continue
		var start_point: Vector2 = left_rect.get_center()
		var end_point: Vector2 = right_rect.get_center()
		var pulse: float = 0.5 + 0.5 * sin(synergy_shine_time * 7.8 + float((left_uid + right_uid) % 23))
		draw_line(start_point, end_point, Color(0.56, 0.84, 1.0, 0.22 + pulse * 0.14), 6.0 + pulse * 2.0, true)
		draw_line(start_point, end_point, Color(0.98, 0.93, 0.74, 0.72 + pulse * 0.22), 2.2 + pulse * 0.8, true)
		var spark_progress: float = fposmod(synergy_shine_time * 0.9 + float((left_uid * 3 + right_uid) % 11) * 0.09, 1.0)
		var spark_position: Vector2 = start_point.lerp(end_point, spark_progress)
		draw_circle(spark_position, 2.4 + pulse * 0.8, Color(1.0, 0.98, 0.88, 0.92))

func item_rect_for_uid(item_uid: int) -> Rect2:
	if item_uid < 0:
		return Rect2()
	for item_variant in items:
		var item: Dictionary = item_variant
		if int(item.get("uid", -1)) == item_uid:
			return item_rect_for_anchor(item)
	if not dragging_item.is_empty() and int(dragging_item.get("uid", -1)) == item_uid:
		return dragging_item_rect()
	for animation_variant in item_snap_animations:
		var animation: Dictionary = animation_variant
		var animation_item: Dictionary = Dictionary(animation.get("item", {}))
		if int(animation_item.get("uid", -1)) == item_uid:
			return interpolated_item_snap_rect(animation)
	return Rect2()

func item_should_glow_for_fusion(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	return fusion_glow_uids.has(int(item.get("uid", -1)))

func item_symbol_for_item(item_id: String, fallback_short_label: String) -> String:
	if ITEM_SYMBOLS.has(item_id):
		return String(ITEM_SYMBOLS[item_id])
	if fallback_short_label != "":
		return fallback_short_label.left(1)
	return "?"

func draw_item_synergy_overlay() -> void:
	for item_variant in items:
		var item: Dictionary = item_variant
		if item_is_animating(item):
			continue
		draw_item_synergy_sockets(item)
	for animation_variant in item_snap_animations:
		var animation: Dictionary = animation_variant
		draw_item_synergy_sockets(animation.get("item", {}))
	if not dragging_item.is_empty():
		var preview_item: Dictionary = dragging_item.duplicate(true)
		preview_item["anchor"] = preview_anchor_for_item(preview_item, drag_pointer_local)
		draw_item_synergy_sockets(preview_item)

func remember_touched_item(item: Dictionary, should_redraw: bool = true) -> void:
	if item.is_empty():
		return
	last_touched_item = item.duplicate(true)
	if spellbook_overlay_open and not spell_focus_selected_item():
		close_spellbook_overlay()
	if should_redraw:
		queue_redraw()

func _on_spellbook_overlay_close_requested() -> void:
	close_spellbook_overlay()

func _on_spellbook_overlay_slots_changed(slotted_spells: Array) -> void:
	spellbook_slotted.clear()
	for spell_variant in slotted_spells:
		var spell_id: String = String(spell_variant)
		if spell_id != "":
			spellbook_slotted.append(spell_id)
	spellbook_slots_changed.emit(spellbook_slotted.duplicate())
	queue_redraw()

func item_description_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var item_level: int = maxi(0, int(item.get("item_level", item_def.get("item_level", 1))))
	lines.append("Item Level %d" % item_level)
	var unique_star_lines: Dictionary = {}
	for line_variant in Array(item_def.get("description_lines", [])):
		lines.append(String(line_variant))
	var stats: Dictionary = item_def.get("stats", {})
	var passive_bonus_text: String = synergy_bonus_text(stats)
	if passive_bonus_text != "":
		lines.append("[%s]" % passive_bonus_text)
	for socket_variant in Array(item_def.get("synergy_sockets", [])):
		var socket_rule: Dictionary = socket_variant
		for match_variant in socket_match_entries(socket_rule):
			var match_rule: Dictionary = match_variant as Dictionary
			var socket_tag: String = String(match_rule.get("tag", "item"))
			var socket_bonus_text: String = synergy_bonus_text(Dictionary(match_rule.get("bonuses", {})))
			if socket_bonus_text != "":
				unique_star_lines["Star needs %s: %s" % [socket_tag, socket_bonus_text]] = true
	for star_line_variant in unique_star_lines.keys():
		lines.append(String(star_line_variant))
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
		var max_stored_cards: int = int(generator.get("max_stored_cards", 1))
		if max_stored_cards > 0:
			lines.append("Stores at most %d ready %s card%s from this source" % [max_stored_cards, generator_label, "" if max_stored_cards == 1 else "s"])
		var exhaust_cards: int = int(generator.get("exhaust_cards", 0))
		if exhaust_cards > 0:
			lines.append("Exhausts after %d generated cards" % exhaust_cards)
	if item_def.has("max_charges"):
		lines.append("Charges %d/%d" % [int(item.get("charges_left", item_def.get("max_charges", 0))), int(item_def.get("max_charges", 0))])
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

func synergy_bonus_text(bonus_stats: Dictionary) -> String:
	var parts: Array[String] = []
	for bonus_key_variant in bonus_stats.keys():
		var bonus_key: String = String(bonus_key_variant)
		match bonus_key:
			"attack":
				parts.append("+%d damage" % int(round(float(bonus_stats[bonus_key_variant]))))
			"health":
				parts.append("+%d health" % int(round(float(bonus_stats[bonus_key_variant]))))
			"speed":
				parts.append("+%d speed" % int(round(float(bonus_stats[bonus_key_variant]))))
			"hand_size":
				parts.append("+%d hand size" % int(bonus_stats[bonus_key_variant]))
			"projectile_count":
				parts.append("+%d projectile" % int(bonus_stats[bonus_key_variant]))
			"card_damage":
				parts.append("+%d card damage" % int(round(float(bonus_stats[bonus_key_variant]))))
			"dagger_backstab_bonus":
				parts.append("+%d%% backstab" % int(round(float(bonus_stats[bonus_key_variant]) * 100.0)))
			"card_charge_mult":
				var charge_mult: float = float(bonus_stats[bonus_key_variant])
				if charge_mult < 1.0:
					parts.append("%d%% faster card charge" % int(round((1.0 - charge_mult) * 100.0)))
				elif charge_mult > 1.0:
					parts.append("%d%% slower card charge" % int(round((charge_mult - 1.0) * 100.0)))
	if parts.is_empty():
		return ""
	return ", ".join(PackedStringArray(parts))

func socket_match_entries(socket_rule: Dictionary) -> Array:
	if socket_rule.has("matches"):
		return Array(socket_rule.get("matches", []))
	if socket_rule.has("tag"):
		return [{
			"tag": String(socket_rule.get("tag", "")),
			"bonuses": Dictionary(socket_rule.get("bonuses", {})),
		}]
	return []

func dragging_item_passive_stats() -> Dictionary:
	if dragging_item.is_empty():
		return {}
	var item_def: Dictionary = item_defs.get(String(dragging_item.get("item_id", "")), {})
	return Dictionary(item_def.get("stats", {}))

func dragging_item_stat_preview_suffix(stat_line: String) -> String:
	var stats: Dictionary = dragging_item_passive_stats()
	if stats.is_empty():
		return ""
	if stat_line.begins_with("Damage "):
		return format_preview_bonus_suffix(float(stats.get("attack", 0.0)))
	if stat_line.begins_with("Health "):
		return format_preview_bonus_suffix(float(stats.get("health", 0.0)))
	if stat_line.begins_with("Speed "):
		return format_preview_bonus_suffix(float(stats.get("speed", 0.0)))
	if stat_line.begins_with("Hand "):
		return format_preview_bonus_suffix(float(int(stats.get("hand_size", 0))))
	return ""

func format_preview_bonus_suffix(value: float) -> String:
	if absf(value) <= 0.001:
		return ""
	var metric: String = format_socket_metric(absf(value))
	return "[+%s]" % metric if value > 0.0 else "[-%s]" % metric

func format_socket_metric(value: float) -> String:
	if absf(value - round(value)) <= 0.05:
		return str(int(round(value)))
	return "%.1f" % value

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

func item_cell_rect(item_rect: Rect2, size_cells: Vector2i, cell_offset: Vector2i) -> Rect2:
	var cell_width: float = item_rect.size.x / maxf(float(size_cells.x), 1.0)
	var cell_height: float = item_rect.size.y / maxf(float(size_cells.y), 1.0)
	return Rect2(item_rect.position + Vector2(float(cell_offset.x) * cell_width, float(cell_offset.y) * cell_height), Vector2(cell_width, cell_height))

func dragging_item_rect() -> Rect2:
	var size_cells: Vector2i = item_size_in_cells(dragging_item)
	var item_size_pixels: Vector2 = Vector2(size_cells) * cell_size()
	return Rect2(drag_pointer_local - item_size_pixels * 0.5, item_size_pixels)

func dragging_pack_rect() -> Rect2:
	var pack_size: Vector2i = dragging_pack.get("size", Vector2i.ONE)
	var pack_size_pixels: Vector2 = Vector2(pack_size) * cell_size()
	return Rect2(drag_pointer_local - pack_size_pixels * 0.5, pack_size_pixels)

func inventory_item_index_at(local_position: Vector2) -> int:
	var grid_cell: Vector2i = local_to_inventory_cell(local_position)
	if grid_cell == INVALID_CELL:
		return -1
	for item_index in range(items.size() - 1, -1, -1):
		if occupied_cells_for_item(items[item_index]).has(grid_cell):
			return item_index
	return -1

func local_to_inventory_cell(local_position: Vector2) -> Vector2i:
	var grid: Rect2 = grid_rect()
	if not grid.has_point(local_position):
		return INVALID_CELL
	var grid_cell_size: float = cell_size()
	var cell_x: int = int(floor((local_position.x - grid.position.x) / grid_cell_size))
	var cell_y: int = int(floor((local_position.y - grid.position.y) / grid_cell_size))
	if cell_x < 0 or cell_y < 0 or cell_x >= inventory_canvas_size.x or cell_y >= inventory_canvas_size.y:
		return INVALID_CELL
	return Vector2i(cell_x, cell_y)

func ground_item_item_rects() -> Array:
	var item_rects: Array = []
	var dock_rect: Rect2 = ground_item_content_rect()
	if ground_items.is_empty():
		return item_rects
	var columns: int = mini(maxi(int(floor(dock_rect.size.x / 120.0)), 1), maxi(ground_items.size(), 1))
	var rows: int = maxi(1, int(ceil(float(ground_items.size()) / float(columns))))
	var gap: float = 8.0
	var usable_width: float = maxf(dock_rect.size.x - gap * float(columns - 1), 1.0)
	var usable_height: float = maxf(dock_rect.size.y - gap * float(rows - 1), 1.0)
	var slot_width: float = usable_width / float(columns)
	var slot_height: float = usable_height / float(rows)
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
	for item_index in range(item_rects.size()):
		if Rect2(item_rects[item_index]).has_point(local_position):
			return item_index
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

func item_base_footprint_offsets(item: Dictionary) -> Array:
	var item_id: String = String(item.get("item_id", ""))
	var item_def: Dictionary = item_defs.get(item_id, {})
	var footprint: Array = []
	if item_def.has("footprint_cells"):
		for cell_variant in Array(item_def.get("footprint_cells", [])):
			if cell_variant is Vector2i:
				footprint.append(cell_variant)
			elif cell_variant is Vector2:
				footprint.append(Vector2i(cell_variant))
			elif cell_variant is Array:
				var raw_cell: Array = cell_variant
				if raw_cell.size() >= 2:
					footprint.append(Vector2i(int(raw_cell[0]), int(raw_cell[1])))
	if not footprint.is_empty():
		return footprint
	var item_base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	for offset_y in range(item_base_size.y):
		for offset_x in range(item_base_size.x):
			footprint.append(Vector2i(offset_x, offset_y))
	return footprint

func item_footprint_offsets(item: Dictionary) -> Array:
	var item_id: String = String(item.get("item_id", ""))
	var item_def: Dictionary = item_defs.get(item_id, {})
	var base_size: Vector2i = item_def.get("size", Vector2i.ONE)
	var base_footprint: Array = item_base_footprint_offsets(item)
	if not bool(item.get("rotated", false)):
		return base_footprint
	var rotated_footprint: Array = []
	for offset_variant in base_footprint:
		var offset: Vector2i = offset_variant
		rotated_footprint.append(Vector2i(base_size.y - 1 - offset.y, offset.x))
	return rotated_footprint

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
	var placed_item: Dictionary = item.duplicate(true)
	placed_item["anchor"] = anchor
	for occupied_cell_variant in occupied_cells_for_item(placed_item):
		var occupied_cell: Vector2i = occupied_cell_variant
		if occupied_cell.x < 0 or occupied_cell.y < 0:
			return false
		if occupied_cell.x >= inventory_canvas_size.x or occupied_cell.y >= inventory_canvas_size.y:
			return false
		if not active_cells.has(occupied_cell) or occupied_cells.has(occupied_cell):
			return false
	return true

func occupied_cells_for_item(item: Dictionary) -> Array:
	var cells: Array = []
	var anchor: Vector2i = item.get("anchor", INVALID_CELL)
	if anchor == INVALID_CELL:
		return cells
	for offset_variant in item_footprint_offsets(item):
		var offset: Vector2i = offset_variant
		cells.append(anchor + offset)
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

func draw_inventory_star(socket_center: Vector2, socket_cell: Vector2i, socket_matched: bool, socket_cell_size: float) -> void:
	var star_radius: float = clampf(socket_cell_size * 0.16, 5.0, 8.5)
	var pulse: float = 0.5 + 0.5 * sin(synergy_shine_time * 5.0 + float(socket_cell.x * 3 + socket_cell.y) * 0.75)
	if socket_matched:
		draw_circle(socket_center, star_radius * (2.05 + pulse * 0.28), Color(1.0, 0.9, 0.35, 0.11 + pulse * 0.08))
		draw_circle(socket_center, star_radius * (1.4 + pulse * 0.14), Color(1.0, 0.96, 0.62, 0.22 + pulse * 0.12))
		var shine_direction: Vector2 = Vector2.RIGHT.rotated(synergy_shine_time * 1.7 + float(socket_cell.x + socket_cell.y) * 0.35)
		draw_line(socket_center - shine_direction * star_radius * 1.45, socket_center + shine_direction * star_radius * 1.45, Color(1.0, 0.99, 0.8, 0.22 + pulse * 0.1), 1.6, true)
		draw_line(socket_center - shine_direction.orthogonal() * star_radius * 0.9, socket_center + shine_direction.orthogonal() * star_radius * 0.9, Color(1.0, 0.96, 0.72, 0.16 + pulse * 0.08), 1.2, true)
	var star_fill: Color = Color(1.0, 0.93, 0.58, 0.72 + pulse * 0.18) if socket_matched else Color(0.0, 0.0, 0.0, 0.0)
	var star_outline: Color = Color(1.0, 0.98, 0.76, 0.95) if socket_matched else Color(0.55, 0.60, 0.66, 0.92)
	if socket_matched:
		draw_colored_polygon(star_points(socket_center, star_radius), star_fill)
	draw_polyline(star_points(socket_center, star_radius, star_radius * 0.46), star_outline, 2.0 if socket_matched else 1.6, true)

func draw_item_synergy_sockets(item: Dictionary) -> void:
	var item_def: Dictionary = item_defs.get(String(item.get("item_id", "")), {})
	var anchor: Vector2i = item.get("anchor", INVALID_CELL)
	if anchor == INVALID_CELL:
		return
	var sockets: Array = Array(item_def.get("synergy_sockets", []))
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
			if occupied_cells_for_item(other_item).has(target_cell):
				for match_variant in socket_match_entries(socket_rule):
					var match_rule: Dictionary = match_variant as Dictionary
					if inventory_item_has_tag(other_item, String(match_rule.get("tag", ""))):
						socket_matched = true
						break
			if socket_matched:
				break
		draw_inventory_star(socket_center, target_cell, socket_matched, socket_cell_size)

func spellbook_action_button_rect() -> Rect2:
	if not spell_focus_selected_item():
		return Rect2()
	var description_rect: Rect2 = item_description_rect()
	return Rect2(Vector2(description_rect.position.x + 14.0, description_rect.end.y - 60.0), Vector2(description_rect.size.x - 28.0, 46.0))

func spellbook_action_touch_rect() -> Rect2:
	var action_rect: Rect2 = spellbook_action_button_rect()
	if action_rect.size == Vector2.ZERO:
		return action_rect
	return action_rect.grow_individual(8.0, 10.0, 8.0, 12.0)

func spellbook_panel_rect() -> Rect2:
	if not spellbook_overlay_open:
		return Rect2()
	return Rect2(Vector2(12.0, 12.0), size - Vector2(24.0, 24.0))

func spellbook_close_button_rect() -> Rect2:
	var panel: Rect2 = spellbook_panel_rect()
	return Rect2(Vector2(panel.end.x - 112.0, panel.position.y + 14.0), Vector2(96.0, 32.0))

func spellbook_known_column_rect() -> Rect2:
	var panel: Rect2 = spellbook_panel_rect()
	var column_top: float = panel.position.y + 92.0
	return Rect2(panel.position + Vector2(18.0, 92.0), Vector2(panel.size.x * 0.62 - 26.0, panel.end.y - column_top - 18.0))

func spellbook_slot_column_rect() -> Rect2:
	var panel: Rect2 = spellbook_panel_rect()
	var column_top: float = panel.position.y + 92.0
	var left_width: float = panel.size.x * 0.62
	return Rect2(panel.position + Vector2(left_width + 10.0, 92.0), Vector2(panel.size.x - left_width - 28.0, panel.end.y - column_top - 18.0))

func spellbook_known_row_rect(spell_index: int) -> Rect2:
	var known_rect: Rect2 = spellbook_known_column_rect()
	var row_height: float = 32.0
	return Rect2(known_rect.position + Vector2(0.0, 24.0 + float(spell_index) * (row_height + 6.0)), Vector2(known_rect.size.x, row_height))

func spellbook_slot_rect(slot_index: int) -> Rect2:
	var slots_rect: Rect2 = spellbook_slot_column_rect()
	var row_height: float = 52.0
	return Rect2(slots_rect.position + Vector2(0.0, 24.0 + float(slot_index) * (row_height + 8.0)), Vector2(slots_rect.size.x, row_height))

func spell_display_name_local(spell_id: String) -> String:
	if spell_id == "":
		return ""
	return spell_id.replace("_card", "").replace("_", " ").capitalize()

func handle_spellbook_pointer_press(local_position: Vector2) -> bool:
	if not spellbook_overlay_open:
		return false
	if not spellbook_panel_rect().has_point(local_position):
		close_spellbook_overlay()
		return true
	if spellbook_close_button_rect().has_point(local_position):
		close_spellbook_overlay()
		return true
	if not spellbook_editable:
		return true
	for spell_index in range(spellbook_known.size()):
		if not spellbook_known_row_rect(spell_index).has_point(local_position):
			continue
		var spell_id: String = spellbook_known[spell_index]
		selected_spellbook_spell_id = "" if selected_spellbook_spell_id == spell_id else spell_id
		queue_redraw()
		return true
	for slot_index in range(spellbook_slot_capacity):
		if not spellbook_slot_rect(slot_index).has_point(local_position):
			continue
		var next_slots: Array[String] = padded_spellbook_slots()
		var previous_spell: String = next_slots[slot_index]
		if selected_spellbook_spell_id != "":
			var existing_slot_index: int = next_slots.find(selected_spellbook_spell_id)
			if previous_spell == selected_spellbook_spell_id:
				next_slots[slot_index] = ""
			elif existing_slot_index >= 0:
				next_slots[existing_slot_index] = previous_spell
				next_slots[slot_index] = selected_spellbook_spell_id
			else:
				next_slots[slot_index] = selected_spellbook_spell_id
		else:
			next_slots[slot_index] = ""
		var compact_slots: Array[String] = []
		for spell_variant in next_slots:
			var spell_id: String = String(spell_variant)
			if spell_id != "":
				compact_slots.append(spell_id)
		spellbook_slotted = compact_slots
		spellbook_slots_changed.emit(compact_slots)
		queue_redraw()
		return true
	return false

func padded_spellbook_slots() -> Array[String]:
	var padded: Array[String] = []
	for slot_index in range(spellbook_slot_capacity):
		padded.append(spellbook_slotted[slot_index] if slot_index < spellbook_slotted.size() else "")
	return padded

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
