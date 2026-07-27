extends RefCounted

static func ui_button_hold_duration(game: Node, button_id: String) -> float:
	match button_id:
		"restart":
			return game.UI_RESTART_HOLD_DURATION
		_:
			return game.UI_BUTTON_HOLD_DURATION

static func ui_button_hold_button(game: Node, button_id: String) -> Button:
	match button_id:
		"inventory":
			return game.inventory_button
		"stamina":
			return game.stamina_toggle_button
		"restart":
			return game.restart_button
		_:
			return null

static func ui_button_hold_progress(game: Node, button_id: String) -> float:
	if game.ui_button_hold.is_empty() or String(game.ui_button_hold.get("id", "")) != button_id:
		return 0.0
	return clampf(float(game.ui_button_hold.get("elapsed", 0.0)) / maxf(float(game.ui_button_hold.get("duration", 0.001)), 0.001), 0.0, 1.0)

static func hold_button_text(game: Node, base_text: String, button_id: String) -> String:
	var progress: float = ui_button_hold_progress(game, button_id)
	if progress <= 0.0:
		return base_text
	return "%s %d%%" % [base_text, int(round(progress * 100.0))]

static func begin_ui_button_hold(game: Node, button_id: String) -> void:
	var button: Button = ui_button_hold_button(game, button_id)
	if button == null or not is_instance_valid(button) or button.disabled or not button.visible:
		return
	game.ui_button_hold = {
		"id": button_id,
		"elapsed": 0.0,
		"duration": ui_button_hold_duration(game, button_id),
	}
	game.update_hud()

static func cancel_ui_button_hold(game: Node, button_id: String = "") -> void:
	if game.ui_button_hold.is_empty():
		return
	if button_id != "" and String(game.ui_button_hold.get("id", "")) != button_id:
		return
	game.ui_button_hold.clear()
	game.update_hud()

static func advance_ui_button_hold(game: Node, delta: float) -> void:
	if game.ui_button_hold.is_empty():
		return
	var button_id: String = String(game.ui_button_hold.get("id", ""))
	var button: Button = ui_button_hold_button(game, button_id)
	if button == null or not is_instance_valid(button) or button.disabled or not button.visible:
		cancel_ui_button_hold(game)
		return
	game.ui_button_hold["elapsed"] = float(game.ui_button_hold.get("elapsed", 0.0)) + delta
	if float(game.ui_button_hold.get("elapsed", 0.0)) >= float(game.ui_button_hold.get("duration", game.UI_BUTTON_HOLD_DURATION)):
		game.ui_button_hold.clear()
		trigger_ui_button_hold_action(game, button_id)
	else:
		game.update_hud()

static func trigger_ui_button_hold_action(game: Node, button_id: String) -> void:
	match button_id:
		"restart":
			game._on_restart_button_pressed()
