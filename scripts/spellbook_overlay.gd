extends Control
class_name SpellbookOverlay

signal close_requested
signal slots_changed(slotted_spells: Array)

const BACKDROP_COLOR: Color = Color(0.03, 0.06, 0.08, 0.9)
const PANEL_FILL: Color = Color("0d151b")
const PANEL_OUTLINE: Color = Color("7d8fb8")
const SLOT_FILL: Color = Color("1d2d35")
const SLOT_OUTLINE: Color = Color("6a88a3")
const SLOT_ACTIVE: Color = Color("36586a")
const SLOT_VALID: Color = Color(0.45, 0.85, 0.58, 0.28)
const SLOT_INVALID: Color = Color(0.9, 0.35, 0.3, 0.22)
const CARD_FILL: Color = Color("243841")
const CARD_SELECTED: Color = Color("3d5870")
const CARD_PREPARED: Color = Color("6a5f2d")
const CARD_OUTLINE: Color = Color("7ea0b2")
const CARD_TEXT: Color = Color("edf5ff")
const CARD_SUBTEXT: Color = Color("b7d2de")
const DESCRIPTION_FILL: Color = Color("142028")
const DESCRIPTION_OUTLINE: Color = Color("56798b")
const CLOSE_FILL: Color = Color("2a3f4c")
const CLOSE_OUTLINE: Color = Color("9fb8c8")
const DRAG_THRESHOLD: float = 8.0
const SLOT_LABEL_WIDTH: float = 74.0
const SLOT_CELL_GAP: float = 10.0

var spellbook_enabled: bool = false
var spellbook_editable: bool = false
var spellbook_title: String = "Spellbook"
var spellbook_prep_note: String = ""
var slot_capacity: int = 0
var slot_counts_by_level: Array[int] = []
var spell_entries: Array = []
var spell_entries_by_id: Dictionary = {}
var slot_rows: Array = []
var selected_spell_id: String = ""
var pointer_local: Vector2 = Vector2.ZERO
var pressed_spell_id: String = ""
var pressed_slot_level: int = -1
var pressed_slot_column: int = -1
var press_local: Vector2 = Vector2.ZERO
var dragging_spell_id: String = ""
var dragging_from_level: int = -1
var dragging_from_column: int = -1
var dragging_active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

func configure_overlay(spellbook_data: Dictionary) -> void:
	spellbook_enabled = bool(spellbook_data.get("enabled", false))
	spellbook_editable = bool(spellbook_data.get("editable", false))
	spellbook_title = String(spellbook_data.get("title", "Spellbook"))
	spellbook_prep_note = String(spellbook_data.get("prep_note", ""))
	slot_capacity = maxi(0, int(spellbook_data.get("capacity", 0)))
	slot_counts_by_level.clear()
	for count_variant in Array(spellbook_data.get("slots_by_level", [])):
		slot_counts_by_level.append(int(count_variant))
	spell_entries.clear()
	spell_entries_by_id.clear()
	for entry_variant in Array(spellbook_data.get("spells", [])):
		var entry: Dictionary = (entry_variant as Dictionary).duplicate(true)
		var spell_id: String = String(entry.get("id", ""))
		if spell_id == "":
			continue
		spell_entries.append(entry)
		spell_entries_by_id[spell_id] = entry
	spell_entries.sort_custom(_sort_spell_entries)
	slot_rows = build_slot_rows(Array(spellbook_data.get("slotted", [])))
	if selected_spell_id == "" or not spell_entries_by_id.has(selected_spell_id):
		selected_spell_id = first_available_spell_id()
	if not spellbook_enabled:
		hide_overlay()
	queue_redraw()

func open_overlay() -> void:
	if not spellbook_enabled:
		return
	visible = true
	queue_redraw()

func hide_overlay() -> void:
	visible = false
	reset_drag_state()
	queue_redraw()

func is_open() -> bool:
	return visible

func pointer_press(screen_position: Vector2) -> bool:
	if not visible:
		return false
	pointer_local = screen_to_local(screen_position)
	if not panel_rect().has_point(pointer_local):
		close_requested.emit()
		return true
	if close_button_rect().has_point(pointer_local):
		close_requested.emit()
		return true
	var available_spell_id: String = spell_id_at_available_point(pointer_local)
	if available_spell_id != "":
		selected_spell_id = available_spell_id
		pressed_spell_id = available_spell_id
		pressed_slot_level = -1
		pressed_slot_column = -1
		press_local = pointer_local
		queue_redraw()
		return true
	var slot_hit: Dictionary = slot_hit_at_point(pointer_local)
	if not slot_hit.is_empty():
		pressed_slot_level = int(slot_hit.get("level_index", -1))
		pressed_slot_column = int(slot_hit.get("column_index", -1))
		pressed_spell_id = slot_spell_id(pressed_slot_level, pressed_slot_column)
		if pressed_spell_id != "":
			selected_spell_id = pressed_spell_id
		press_local = pointer_local
		queue_redraw()
		return true
	if description_rect().has_point(pointer_local):
		queue_redraw()
		return true
	return true

func pointer_move(screen_position: Vector2) -> bool:
	if not visible:
		return false
	pointer_local = screen_to_local(screen_position)
	if not spellbook_editable:
		return true
	if pressed_spell_id != "" and not dragging_active and press_local.distance_to(pointer_local) >= DRAG_THRESHOLD:
		begin_drag(pressed_spell_id, -1, -1)
	elif pressed_slot_level >= 0 and pressed_slot_column >= 0 and not dragging_active and press_local.distance_to(pointer_local) >= DRAG_THRESHOLD:
		begin_drag(slot_spell_id(pressed_slot_level, pressed_slot_column), pressed_slot_level, pressed_slot_column)
	if dragging_active:
		queue_redraw()
	return true

func pointer_release(screen_position: Vector2) -> bool:
	if not visible:
		return false
	pointer_local = screen_to_local(screen_position)
	if dragging_active:
		finish_drag()
	else:
		handle_click_release()
	reset_press_state()
	queue_redraw()
	return true

func _draw() -> void:
	if not visible:
		return
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP_COLOR, true)
	var panel: Rect2 = panel_rect()
	draw_rect(panel, PANEL_FILL, true)
	draw_rect(panel, PANEL_OUTLINE, false, 2.0)
	draw_header(font)
	draw_slots(font)
	draw_description(font)
	draw_available_spells(font)
	if dragging_active and dragging_spell_id != "":
		draw_dragged_spell(font)

func draw_header(font: Font) -> void:
	var panel: Rect2 = panel_rect()
	draw_string(font, panel.position + Vector2(22.0, 30.0), spellbook_title, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x * 0.54, 24, Color("e8dcff"))
	var status_text: String = "%d/%d prepared" % [prepared_spell_count(), slot_capacity]
	draw_string(font, panel.position + Vector2(panel.end.x - 220.0, 30.0), status_text, HORIZONTAL_ALIGNMENT_LEFT, 140.0, 16, Color("cdd9ff"))
	var instruction_text: String = "Drag spells into same-level slots. Drag prepared spells out to clear them." if spellbook_editable else "Prepared spells are locked after the first door."
	draw_string(font, panel.position + Vector2(22.0, 54.0), instruction_text, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 180.0, 14, Color("a8bfd6"))
	if spellbook_prep_note != "":
		draw_string(font, panel.position + Vector2(22.0, 74.0), spellbook_prep_note, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 180.0, 13, Color("fff1b8"))
	var close_rect: Rect2 = close_button_rect()
	draw_rect(close_rect, CLOSE_FILL, true)
	draw_rect(close_rect, CLOSE_OUTLINE, false, 2.0)
	draw_string(font, close_rect.position + Vector2(18.0, 24.0), "Close", HORIZONTAL_ALIGNMENT_LEFT, close_rect.size.x - 24.0, 16, Color("eef8ff"))

func draw_slots(font: Font) -> void:
	var slots_area: Rect2 = slots_area_rect()
	draw_string(font, slots_area.position + Vector2(0.0, -6.0), "Prepared Slots", HORIZONTAL_ALIGNMENT_LEFT, slots_area.size.x, 16, Color("fff1b8"))
	for level_index in range(slot_rows.size()):
		var row_rect: Rect2 = slot_row_rect(level_index)
		if row_rect.size.y <= 8.0:
			continue
		draw_string(font, row_rect.position + Vector2(0.0, row_rect.size.y * 0.62), "Level %d" % (level_index + 1), HORIZONTAL_ALIGNMENT_LEFT, SLOT_LABEL_WIDTH - 6.0, 15, Color("dceaf0"))
		var row_slots: Array = slot_rows[level_index]
		for column_index in range(row_slots.size()):
			var square_rect: Rect2 = slot_cell_rect(level_index, column_index)
			var spell_id: String = String(row_slots[column_index])
			draw_rect(square_rect, SLOT_ACTIVE if spell_id != "" else SLOT_FILL, true)
			var outline_color: Color = SLOT_OUTLINE
			if dragging_active and dragging_spell_id != "":
				var accepts_drag: bool = slot_accepts_spell(level_index, column_index, dragging_spell_id)
				outline_color = Color("9fd2a5") if accepts_drag else Color("d78888")
				draw_rect(square_rect, SLOT_VALID if accepts_drag else SLOT_INVALID, true)
			draw_rect(square_rect, outline_color, false, 2.0)
			if spell_id != "":
				draw_spell_card(square_rect.grow(-4.0), spell_id, font, true)
			else:
				draw_string(font, square_rect.position + Vector2(12.0, square_rect.size.y * 0.58), "Empty", HORIZONTAL_ALIGNMENT_LEFT, square_rect.size.x - 18.0, 13, Color("8ea5b4"))

func draw_description(font: Font) -> void:
	var info_rect: Rect2 = description_rect()
	draw_rect(info_rect, DESCRIPTION_FILL, true)
	draw_rect(info_rect, DESCRIPTION_OUTLINE, false, 2.0)
	draw_string(font, info_rect.position + Vector2(18.0, 28.0), "Spell", HORIZONTAL_ALIGNMENT_LEFT, info_rect.size.x - 24.0, 18, Color("fff1b8"))
	var focused_spell_id: String = focused_spell()
	if focused_spell_id == "":
		draw_string(font, info_rect.position + Vector2(18.0, 58.0), "Select or drag a spell to inspect it.", HORIZONTAL_ALIGNMENT_LEFT, info_rect.size.x - 24.0, 16, Color("a8bfd6"))
		return
	var entry: Dictionary = spell_entries_by_id.get(focused_spell_id, {})
	var spell_level_value: int = int(entry.get("level", 1))
	draw_string(font, info_rect.position + Vector2(18.0, 58.0), String(entry.get("name", focused_spell_id)), HORIZONTAL_ALIGNMENT_LEFT, info_rect.size.x - 24.0, 20, Color("eef8ff"))
	draw_string(font, info_rect.position + Vector2(18.0, 82.0), "Level %d" % spell_level_value, HORIZONTAL_ALIGNMENT_LEFT, info_rect.size.x - 24.0, 14, Color("b9d8e4"))
	var line_y: float = info_rect.position.y + 110.0
	for line_variant in Array(entry.get("description_lines", [])):
		draw_string(font, Vector2(info_rect.position.x + 18.0, line_y), String(line_variant), HORIZONTAL_ALIGNMENT_LEFT, info_rect.size.x - 24.0, 14, Color("d4eaf4"))
		line_y += 18.0
	var prepared_count: int = prepared_copies_for_spell(focused_spell_id)
	var prep_state: String = "Prepared x%d" % prepared_count if prepared_count > 0 else "Available"
	draw_string(font, Vector2(info_rect.position.x + 18.0, info_rect.end.y - 18.0), prep_state, HORIZONTAL_ALIGNMENT_LEFT, info_rect.size.x - 24.0, 14, Color("ffe28a"))

func draw_available_spells(font: Font) -> void:
	var list_rect: Rect2 = available_rect()
	draw_rect(list_rect, DESCRIPTION_FILL, true)
	draw_rect(list_rect, DESCRIPTION_OUTLINE, false, 2.0)
	draw_string(font, list_rect.position + Vector2(16.0, 24.0), "Available Spells", HORIZONTAL_ALIGNMENT_LEFT, list_rect.size.x - 22.0, 18, Color("fff1b8"))
	if spell_entries.is_empty():
		draw_string(font, list_rect.position + Vector2(16.0, 56.0), "No learned spells.", HORIZONTAL_ALIGNMENT_LEFT, list_rect.size.x - 22.0, 16, Color("9fb8c2"))
		return
	for spell_index in range(spell_entries.size()):
		var spell_id: String = String((spell_entries[spell_index] as Dictionary).get("id", ""))
		draw_spell_card(available_spell_rect(spell_index), spell_id, font, false)

func draw_spell_card(card_rect: Rect2, spell_id: String, font: Font, compact: bool) -> void:
	if spell_id == "":
		return
	var entry: Dictionary = spell_entries_by_id.get(spell_id, {})
	var fill: Color = CARD_FILL
	if selected_spell_id == spell_id:
		fill = CARD_SELECTED
	elif prepared_copies_for_spell(spell_id) > 0:
		fill = CARD_PREPARED
	draw_rect(card_rect, fill, true)
	draw_rect(card_rect, CARD_OUTLINE, false, 1.5)
	var level_value: int = int(entry.get("level", 1))
	draw_string(font, card_rect.position + Vector2(10.0, 20.0), "L%d" % level_value, HORIZONTAL_ALIGNMENT_LEFT, 34.0, 12, Color("ffe28a"))
	var title_y: float = 38.0 if compact else 30.0
	draw_string(font, card_rect.position + Vector2(10.0, title_y), String(entry.get("name", spell_id)), HORIZONTAL_ALIGNMENT_LEFT, card_rect.size.x - 18.0, 15 if compact else 16, CARD_TEXT)
	if compact:
		return
	var prepared_count: int = prepared_copies_for_spell(spell_id)
	var description_lines: Array = Array(entry.get("description_lines", []))
	var detail_line: String = "Prepared x%d" % prepared_count if prepared_count > 0 else (String(description_lines[0]) if not description_lines.is_empty() else "")
	draw_string(font, card_rect.position + Vector2(10.0, card_rect.size.y - 14.0), detail_line, HORIZONTAL_ALIGNMENT_LEFT, card_rect.size.x - 18.0, 12, CARD_SUBTEXT)

func draw_dragged_spell(font: Font) -> void:
	var drag_rect: Rect2 = Rect2(pointer_local - available_card_size() * 0.5, available_card_size())
	draw_spell_card(drag_rect, dragging_spell_id, font, false)
	draw_rect(drag_rect, Color(1.0, 1.0, 1.0, 0.18), false, 2.0)

func handle_click_release() -> void:
	if pressed_spell_id != "":
		selected_spell_id = pressed_spell_id

func begin_drag(spell_id: String, from_level: int, from_column: int) -> void:
	if not spellbook_editable or spell_id == "":
		return
	dragging_spell_id = spell_id
	dragging_from_level = from_level
	dragging_from_column = from_column
	dragging_active = true
	selected_spell_id = spell_id
	queue_redraw()

func finish_drag() -> void:
	var previous_flat: Array = flattened_slots()
	var slot_hit: Dictionary = slot_hit_at_point(pointer_local)
	var changed: bool = false
	if not slot_hit.is_empty():
		var level_index: int = int(slot_hit.get("level_index", -1))
		var column_index: int = int(slot_hit.get("column_index", -1))
		if slot_accepts_spell(level_index, column_index, dragging_spell_id):
			if dragging_from_level >= 0 and dragging_from_column >= 0:
				slot_rows[dragging_from_level][dragging_from_column] = ""
			slot_rows[level_index][column_index] = dragging_spell_id
			changed = true
	elif dragging_from_level >= 0 and dragging_from_column >= 0:
		slot_rows[dragging_from_level][dragging_from_column] = ""
		changed = true
	if changed and flattened_slots() != previous_flat:
		emit_slots_changed()
	reset_drag_state()

func emit_slots_changed() -> void:
	slots_changed.emit(flattened_slots())
	queue_redraw()

func flattened_slots() -> Array:
	var flattened: Array = []
	for row_variant in slot_rows:
		var row_slots: Array = row_variant
		for spell_variant in row_slots:
			var spell_id: String = String(spell_variant)
			if spell_id != "":
				flattened.append(spell_id)
	return flattened

func reset_press_state() -> void:
	pressed_spell_id = ""
	pressed_slot_level = -1
	pressed_slot_column = -1
	press_local = Vector2.ZERO

func reset_drag_state() -> void:
	reset_press_state()
	dragging_spell_id = ""
	dragging_from_level = -1
	dragging_from_column = -1
	dragging_active = false

func build_slot_rows(slotted_spells: Array) -> Array:
	var rows: Array = []
	for level_index in range(slot_counts_by_level.size()):
		var slot_count: int = int(slot_counts_by_level[level_index])
		var row_slots: Array = []
		row_slots.resize(slot_count)
		for slot_index in range(slot_count):
			row_slots[slot_index] = ""
		rows.append(row_slots)
	for spell_variant in slotted_spells:
		var spell_id: String = String(spell_variant)
		var level_index: int = spell_level_for_id(spell_id) - 1
		if spell_id == "" or level_index < 0 or level_index >= rows.size():
			continue
		for slot_index in range((rows[level_index] as Array).size()):
			if String(rows[level_index][slot_index]) == "":
				rows[level_index][slot_index] = spell_id
				break
	return rows

func spell_level_for_id(spell_id: String) -> int:
	return maxi(1, int((spell_entries_by_id.get(spell_id, {}) as Dictionary).get("level", 1)))

func slot_accepts_spell(level_index: int, column_index: int, spell_id: String) -> bool:
	if not spellbook_editable or spell_id == "":
		return false
	if level_index < 0 or level_index >= slot_rows.size():
		return false
	var row_slots: Array = slot_rows[level_index]
	if column_index < 0 or column_index >= row_slots.size():
		return false
	return spell_level_for_id(spell_id) == level_index + 1

func slot_spell_id(level_index: int, column_index: int) -> String:
	if level_index < 0 or level_index >= slot_rows.size():
		return ""
	var row_slots: Array = slot_rows[level_index]
	if column_index < 0 or column_index >= row_slots.size():
		return ""
	return String(row_slots[column_index])

func prepared_spell_count() -> int:
	return flattened_slots().size()

func prepared_copies_for_spell(spell_id: String) -> int:
	if spell_id == "":
		return 0
	var count: int = 0
	for row_variant in slot_rows:
		var row_slots: Array = row_variant
		for row_spell_variant in row_slots:
			if String(row_spell_variant) == spell_id:
				count += 1
	return count

func focused_spell() -> String:
	if dragging_active and dragging_spell_id != "":
		return dragging_spell_id
	if selected_spell_id != "":
		return selected_spell_id
	for row_variant in slot_rows:
		var row_slots: Array = row_variant
		for spell_variant in row_slots:
			var spell_id: String = String(spell_variant)
			if spell_id != "":
				return spell_id
	return first_available_spell_id()

func first_available_spell_id() -> String:
	if spell_entries.is_empty():
		return ""
	return String((spell_entries[0] as Dictionary).get("id", ""))

func _sort_spell_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_level: int = int(a.get("level", 1))
	var b_level: int = int(b.get("level", 1))
	if a_level != b_level:
		return a_level < b_level
	return String(a.get("name", a.get("id", ""))) < String(b.get("name", b.get("id", "")))

func screen_to_local(screen_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_position

func panel_rect() -> Rect2:
	return Rect2(Vector2(14.0, 14.0), size - Vector2(28.0, 28.0))

func close_button_rect() -> Rect2:
	var panel: Rect2 = panel_rect()
	return Rect2(Vector2(panel.end.x - 122.0, panel.position.y + 14.0), Vector2(104.0, 36.0))

func slots_area_rect() -> Rect2:
	var panel: Rect2 = panel_rect()
	return Rect2(panel.position + Vector2(22.0, 104.0), Vector2(panel.size.x * 0.56, minf(panel.size.y * 0.48, 540.0)))

func description_rect() -> Rect2:
	var panel: Rect2 = panel_rect()
	var top_y: float = panel.position.y + 104.0
	var width: float = panel.size.x * 0.30
	return Rect2(Vector2(panel.end.x - width - 22.0, top_y), Vector2(width, panel.size.y - 126.0))

func available_rect() -> Rect2:
	var panel: Rect2 = panel_rect()
	var slots_area: Rect2 = slots_area_rect()
	var top_y: float = slots_area.end.y + 28.0
	var right_limit: float = description_rect().position.x - 20.0
	return Rect2(Vector2(panel.position.x + 22.0, top_y), Vector2(right_limit - panel.position.x - 22.0, panel.end.y - top_y - 22.0))

func slot_row_rect(level_index: int) -> Rect2:
	var area: Rect2 = slots_area_rect()
	var row_count: int = maxi(slot_rows.size(), 1)
	var gap: float = 10.0
	var top_padding: float = 20.0
	var available_height: float = area.size.y - top_padding - float(maxi(row_count - 1, 0)) * gap
	var row_height: float = clampf(available_height / float(row_count), 42.0, 70.0)
	return Rect2(area.position + Vector2(0.0, top_padding + float(level_index) * (row_height + gap)), Vector2(area.size.x - 8.0, row_height))

func slot_cell_size(level_index: int) -> float:
	if level_index < 0 or level_index >= slot_rows.size():
		return 0.0
	var row_slots: Array = slot_rows[level_index]
	if row_slots.is_empty():
		return 0.0
	var row_rect: Rect2 = slot_row_rect(level_index)
	var available_width: float = row_rect.size.x - SLOT_LABEL_WIDTH - float(maxi(row_slots.size() - 1, 0)) * SLOT_CELL_GAP
	return clampf(available_width / float(row_slots.size()), 38.0, 64.0)

func slot_cell_rect(level_index: int, column_index: int) -> Rect2:
	var row_rect: Rect2 = slot_row_rect(level_index)
	var cell_size: float = slot_cell_size(level_index)
	return Rect2(row_rect.position + Vector2(SLOT_LABEL_WIDTH + float(column_index) * (cell_size + SLOT_CELL_GAP), (row_rect.size.y - cell_size) * 0.5), Vector2.ONE * cell_size)

func available_card_size() -> Vector2:
	var list_rect: Rect2 = available_rect()
	var columns: int = maxi(1, int(floor((list_rect.size.x + 12.0) / 152.0)))
	var card_width: float = clampf((list_rect.size.x - float(columns - 1) * 12.0) / float(columns), 126.0, 184.0)
	return Vector2(card_width, 72.0)

func available_spell_rect(spell_index: int) -> Rect2:
	var list_rect: Rect2 = available_rect()
	var card_size: Vector2 = available_card_size()
	var columns: int = maxi(1, int(floor((list_rect.size.x + 12.0) / (card_size.x + 12.0))))
	var row: int = spell_index / columns
	var column: int = spell_index % columns
	return Rect2(list_rect.position + Vector2(float(column) * (card_size.x + 12.0), 36.0 + float(row) * (card_size.y + 12.0)), card_size)

func spell_id_at_available_point(local_position: Vector2) -> String:
	for spell_index in range(spell_entries.size()):
		var spell_id: String = String((spell_entries[spell_index] as Dictionary).get("id", ""))
		if available_spell_rect(spell_index).has_point(local_position):
			return spell_id
	return ""

func slot_hit_at_point(local_position: Vector2) -> Dictionary:
	for level_index in range(slot_rows.size()):
		var row_slots: Array = slot_rows[level_index]
		for column_index in range(row_slots.size()):
			if slot_cell_rect(level_index, column_index).has_point(local_position):
				return {
					"level_index": level_index,
					"column_index": column_index,
				}
	return {}
