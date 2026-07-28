extends Control
class_name MerchantOverlay

signal close_requested
signal buy_requested(offer_uid: int)
signal sell_requested(item_uid: int)
signal buyback_requested(offer_uid: int)

const TAB_BUY: String = "buy"
const TAB_SELL: String = "sell"
const TAB_BUYBACK: String = "buyback"

var room_coord: Vector2i = Vector2i(-99, -99)
var merchant_title: String = "Merchant"
var room_title: String = ""
var hero_title: String = ""
var resource_title: String = ""
var footer_title: String = ""
var buy_entries: Array = []
var sell_entries: Array = []
var buyback_entries: Array = []
var active_tab: String = TAB_BUY

@onready var layout_root: Control = $LayoutRoot
@onready var title_label: Label = $LayoutRoot/MainPanel/Margin/VBox/HeaderRow/TitleLabel
@onready var resource_label: Label = $LayoutRoot/MainPanel/Margin/VBox/HeaderRow/ResourceLabel
@onready var close_button: Button = $LayoutRoot/MainPanel/Margin/VBox/HeaderRow/CloseButton
@onready var room_label: Label = $LayoutRoot/MainPanel/Margin/VBox/RoomLabel
@onready var hero_label: Label = $LayoutRoot/MainPanel/Margin/VBox/HeroLabel
@onready var buy_tab_button: Button = $LayoutRoot/MainPanel/Margin/VBox/TabsRow/BuyTabButton
@onready var sell_tab_button: Button = $LayoutRoot/MainPanel/Margin/VBox/TabsRow/SellTabButton
@onready var buyback_tab_button: Button = $LayoutRoot/MainPanel/Margin/VBox/TabsRow/BuybackTabButton
@onready var entry_list: VBoxContainer = $LayoutRoot/MainPanel/Margin/VBox/EntryPanel/EntryScroll/EntryList
@onready var footer_label: Label = $LayoutRoot/MainPanel/Margin/VBox/FooterLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if close_button != null:
		close_button.pressed.connect(_on_close_button_pressed)
	if buy_tab_button != null:
		buy_tab_button.pressed.connect(_on_buy_tab_pressed)
	if sell_tab_button != null:
		sell_tab_button.pressed.connect(_on_sell_tab_pressed)
	if buyback_tab_button != null:
		buyback_tab_button.pressed.connect(_on_buyback_tab_pressed)
	visible = false

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			close_requested.emit()
			accept_event()

func configure(data: Dictionary) -> void:
	room_coord = Vector2i(data.get("room_coord", Vector2i(-99, -99)))
	merchant_title = String(data.get("merchant_title", "Merchant"))
	room_title = String(data.get("room_title", ""))
	hero_title = String(data.get("hero_title", ""))
	resource_title = String(data.get("resource_title", ""))
	footer_title = String(data.get("footer_title", ""))
	buy_entries = Array(data.get("buy_entries", [])).duplicate(true)
	sell_entries = Array(data.get("sell_entries", [])).duplicate(true)
	buyback_entries = Array(data.get("buyback_entries", [])).duplicate(true)
	var requested_tab: String = String(data.get("active_tab", active_tab))
	if requested_tab == TAB_BUY or requested_tab == TAB_SELL or requested_tab == TAB_BUYBACK:
		active_tab = requested_tab
	refresh_overlay()
	visible = true

func hide_overlay() -> void:
	visible = false
	entry_list_clear()

func refresh_overlay() -> void:
	if title_label != null:
		title_label.text = merchant_title
	if resource_label != null:
		resource_label.text = resource_title
	if room_label != null:
		room_label.text = room_title
	if hero_label != null:
		hero_label.text = hero_title
	if footer_label != null:
		footer_label.text = footer_title
	refresh_tab_buttons()
	rebuild_entry_buttons()
	queue_redraw()

func set_active_tab(tab_id: String) -> void:
	if tab_id != TAB_BUY and tab_id != TAB_SELL and tab_id != TAB_BUYBACK:
		return
	active_tab = tab_id
	refresh_overlay()

func refresh_tab_buttons() -> void:
	if buy_tab_button != null:
		buy_tab_button.button_pressed = active_tab == TAB_BUY
	if sell_tab_button != null:
		sell_tab_button.button_pressed = active_tab == TAB_SELL
	if buyback_tab_button != null:
		buyback_tab_button.button_pressed = active_tab == TAB_BUYBACK

func current_entries() -> Array:
	match active_tab:
		TAB_SELL:
			return sell_entries
		TAB_BUYBACK:
			return buyback_entries
		_:
			return buy_entries

func entry_list_clear() -> void:
	for child in entry_list.get_children():
		child.queue_free()

func rebuild_entry_buttons() -> void:
	entry_list_clear()
	var entries: Array = current_entries()
	if entries.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No entries available."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color("d3dde6"))
		entry_list.add_child(empty_label)
		return
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var entry_uid: int = int(entry.get("uid", -1))
		if entry_uid < 0:
			continue
		var entry_button: Button = Button.new()
		entry_button.custom_minimum_size = Vector2(0.0, 46.0)
		entry_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry_button.text = String(entry.get("label", "Offer"))
		entry_button.disabled = not bool(entry.get("enabled", true))
		entry_button.add_theme_font_size_override("font_size", 17)
		entry_button.pressed.connect(_on_entry_button_pressed.bind(active_tab, entry_uid))
		entry_list.add_child(entry_button)
		var note_text: String = String(entry.get("note", ""))
		if note_text != "":
			var note_label: Label = Label.new()
			note_label.text = note_text
			note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note_label.add_theme_font_size_override("font_size", 13)
			note_label.add_theme_color_override("font_color", Color("8ea0ad"))
			note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			entry_list.add_child(note_label)

func _on_close_button_pressed() -> void:
	close_requested.emit()

func _on_buy_tab_pressed() -> void:
	set_active_tab(TAB_BUY)

func _on_sell_tab_pressed() -> void:
	set_active_tab(TAB_SELL)

func _on_buyback_tab_pressed() -> void:
	set_active_tab(TAB_BUYBACK)

func _on_entry_button_pressed(tab_id: String, entry_uid: int) -> void:
	match tab_id:
		TAB_SELL:
			sell_requested.emit(entry_uid)
		TAB_BUYBACK:
			buyback_requested.emit(entry_uid)
		_:
			buy_requested.emit(entry_uid)
