extends RefCounted

const GAME_FLOOR_FLOW: GDScript = preload("res://scripts/world/game_floor_flow.gd")

static func research_option_cost(game: Node, module_type: String, next_level: int, is_major: bool) -> int:
	if is_major:
		return game.major_module_upgrade_cost(next_level)
	match game.canonical_minor_module_type(module_type):
		game.MINOR_MODULE_TURRET:
			return game.minor_module_research_cost(module_type, next_level)
		game.MINOR_MODULE_PULSE:
			return game.minor_module_research_cost(module_type, next_level)
		game.MINOR_MODULE_CANNON:
			return game.minor_module_research_cost(module_type, next_level)
		game.MINOR_MODULE_KIP:
			return game.minor_module_research_cost(module_type, next_level)
		game.MINOR_MODULE_CONVERSION:
			return game.minor_module_research_cost(module_type, next_level)
		game.MINOR_MODULE_BOUNTY_INDUSTRY:
			return game.minor_module_research_cost(module_type, next_level)
		game.MINOR_MODULE_BOUNTY_FOOD:
			return game.minor_module_research_cost(module_type, next_level)
		game.MINOR_MODULE_BOUNTY_SCIENCE:
			return game.minor_module_research_cost(module_type, next_level)
		_:
			return game.minor_module_research_cost(module_type, next_level)

static func research_option_description(game: Node, module_type: String, next_level: int, is_major: bool) -> String:
	if is_major:
		return "Upgrade to level %d.\nEach online %s yields %d per door." % [next_level, game.research_display_name(module_type).to_lower(), game.major_module_door_yield(next_level)]
	match game.canonical_minor_module_type(module_type):
		game.MINOR_MODULE_TURRET:
			return "Unlocks or upgrades the arrow turret.\nLevel %d: %d damage, 0.5s cooldown." % [next_level, int(game.BALLISTA_LEVEL_DAMAGE[clampi(next_level - 1, 0, 3)])]
		game.MINOR_MODULE_PULSE:
			return "Blight gas pulse.\nLevel %d increases room-wide damage over time and slow uptime." % next_level
		game.MINOR_MODULE_CANNON:
			return "Runeburst mortar shell.\nLevel %d increases splash damage and cadence." % next_level
		game.MINOR_MODULE_KIP:
			return "Arcana turret beam.\nDamage equals stored Arcana up to a level-based cap; level %d raises the cap." % next_level
		game.MINOR_MODULE_CONVERSION:
			return "Soulbind conversion spire.\nLevel %d converts one enemy and splashes nearby foes." % next_level
		game.MINOR_MODULE_BOUNTY_INDUSTRY:
			return "Salvage sigil.\nEarn materials every few enemy kills in the room; level %d lowers the kill requirement." % next_level
		game.MINOR_MODULE_BOUNTY_FOOD:
			return "Provision sigil.\nEarn food every few enemy kills in the room; level %d lowers the kill requirement." % next_level
		game.MINOR_MODULE_BOUNTY_SCIENCE:
			return "Sage sigil.\nEarn arcana every few enemy kills in the room; level %d lowers the kill requirement." % next_level
		_:
			return "Research level %d." % next_level

static func active_research_title(game: Node) -> String:
	return String(game.active_research.get("title", game.research_display_name(String(game.active_research.get("module_type", "")))))

static func complete_active_research(game: Node) -> void:
	if game.active_research.is_empty():
		return
	var module_type: String = String(game.active_research.get("module_type", ""))
	var next_level: int = int(game.active_research.get("next_level", 1))
	if bool(game.active_research.get("is_major", false)):
		game.major_module_levels[module_type] = next_level
	else:
		game.minor_module_levels[game.canonical_minor_module_type(module_type)] = next_level
	var research_room: Vector2i = Vector2i(game.active_research.get("room", game.INVALID_ROOM))
	game.status_message = "Research complete: %s." % active_research_title(game)
	game.active_research.clear()
	if game.research_overlay != null and game.research_overlay.visible:
		close_research_overlay(game)
	game.update_hud()
	game.queue_redraw()

static func advance_active_research_on_door_open(game: Node) -> String:
	if game.active_research.is_empty():
		return ""
	var completed_title: String = active_research_title(game)
	game.active_research["doors_remaining"] = maxi(int(game.active_research.get("doors_remaining", 0)) - 1, 0)
	if GAME_FLOOR_FLOW.all_floor_doors_opened(game) or int(game.active_research.get("doors_remaining", 0)) <= 0:
		complete_active_research(game)
		return completed_title
	return ""

static func build_research_option(game: Node, module_type: String, is_major: bool) -> Dictionary:
	var current_level: int = game.major_module_level(module_type) if is_major else game.minor_module_level(module_type)
	var next_level: int = clampi(current_level + 1, 1, 4)
	return {
		"module_type": module_type,
		"is_major": is_major,
		"next_level": next_level,
		"cost": research_option_cost(game, module_type, next_level, is_major),
		"title": "%s %s" % [game.research_display_name(module_type), game.module_level_roman(next_level)],
		"description": research_option_description(game, module_type, next_level, is_major),
	}

static func research_resource_label(resource_id: String) -> String:
	match resource_id:
		"food":
			return "Food"
		"industry":
			return "Materials"
		"science":
			return "Arcana"
		"dust":
			return "Dust"
		_:
			return resource_id.capitalize()

static func research_option_stats_text(game: Node, option: Dictionary) -> String:
	var module_type: String = String(option.get("module_type", ""))
	var next_level: int = int(option.get("next_level", 1))
	var current_level: int = max(next_level - 1, 0)
	if bool(option.get("is_major", false)):
		var current_yield: int = game.major_module_door_yield(current_level)
		var next_yield: int = game.major_module_door_yield(next_level)
		return "Current level %d -> %d\nPer-module door yield %d -> %d." % [current_level, next_level, current_yield, next_yield]
	match game.canonical_minor_module_type(module_type):
		game.MINOR_MODULE_TURRET:
			var next_damage: int = int(game.BALLISTA_LEVEL_DAMAGE[clampi(next_level - 1, 0, game.BALLISTA_LEVEL_DAMAGE.size() - 1)])
			var next_dps: int = int(round(float(next_damage) / 0.5))
			return "Current level %d -> %d\nAttack Power %d\nAttack Cooldown 0.5\nDPS %d" % [current_level, next_level, next_damage, next_dps]
		game.MINOR_MODULE_PULSE:
			var pulse_level: int = clampi(next_level, 1, 4)
			var pulse_damage: float = 1.0 + float(pulse_level) * 0.7
			var pulse_slow_duration: float = 1.4 + float(pulse_level) * 0.2
			var pulse_cooldown: float = 1.1 - float(pulse_level - 1) * 0.08
			return "Current level %d -> %d\nRoom-wide blight gas\nPer tick damage %.1f\nSlow field %.1fs\nCooldown %.2fs" % [current_level, next_level, pulse_damage, pulse_slow_duration, pulse_cooldown]
		game.MINOR_MODULE_CANNON:
			var mortar_level: int = clampi(next_level, 1, 4)
			var mortar_damage: float = 8.0 + float(mortar_level - 1) * 3.0
			var mortar_cooldown: float = 1.45 - float(mortar_level - 1) * 0.12
			return "Current level %d -> %d\nRuneburst splash shell\nSplash damage %.1f\nCooldown %.2fs" % [current_level, next_level, mortar_damage, mortar_cooldown]
		game.MINOR_MODULE_KIP:
			var current_arcana_cap: int = game.minor_module_kip_max_damage(current_level)
			var next_arcana_cap: int = game.minor_module_kip_max_damage(next_level)
			var stored_arcana_damage: int = maxi(game.science, 0)
			var effective_current_damage: int = mini(stored_arcana_damage, current_arcana_cap)
			return "Current level %d -> %d\nArcana beam turret\nDamage = min(stored Arcana, cap) = min(%d, %d) = %d\nMax damage cap %d -> %d\nCooldown 1.50s" % [current_level, next_level, stored_arcana_damage, current_arcana_cap, effective_current_damage, current_arcana_cap, next_arcana_cap]
		game.MINOR_MODULE_CONVERSION:
			var conversion_level: int = clampi(next_level, 1, 4)
			var conversion_damage: float = 6.0 + float(conversion_level - 1) * 2.0
			var conversion_cooldown: float = 3.4 - float(conversion_level - 1) * 0.35
			return "Current level %d -> %d\nConverts one enemy on proc\nSplash damage %d\nCooldown %.2fs" % [current_level, next_level, int(conversion_damage), conversion_cooldown]
		game.MINOR_MODULE_BOUNTY_INDUSTRY, game.MINOR_MODULE_BOUNTY_FOOD, game.MINOR_MODULE_BOUNTY_SCIENCE:
			var resource_label: String = research_resource_label(game.minor_module_bounty_resource_id(module_type))
			var threshold_by_level: Array[int] = [6, 5, 4, 3]
			var threshold: int = threshold_by_level[clampi(next_level - 1, 0, threshold_by_level.size() - 1)]
			return "Current level %d -> %d\nPassive bounty module\n+1 %s every %d kills in room" % [current_level, next_level, resource_label, threshold]
		_:
			return "Current level %d -> %d" % [current_level, next_level]

static func roll_research_offer_choices(game: Node) -> Array:
	var options: Array = []
	var major_candidates: Array[String] = []
	for module_type_variant in [game.MAJOR_MODULE_FOOD, game.MAJOR_MODULE_SCIENCE, game.MAJOR_MODULE_INDUSTRY]:
		var module_type: String = String(module_type_variant)
		if game.major_module_level(module_type) < 4:
			major_candidates.append(module_type)
	if not major_candidates.is_empty():
		var major_pick_index: int = game.rng.randi_range(0, major_candidates.size() - 1)
		options.append(build_research_option(game, major_candidates[major_pick_index], true))
	var minor_candidates: Array[String] = []
	for module_type_variant in game.minor_module_catalog():
		var module_type: String = String(module_type_variant)
		if game.minor_module_level(module_type) < 4:
			minor_candidates.append(module_type)
	while options.size() < 4 and not minor_candidates.is_empty():
		var candidate_index: int = game.rng.randi_range(0, minor_candidates.size() - 1)
		var candidate_type: String = minor_candidates[candidate_index]
		minor_candidates.remove_at(candidate_index)
		options.append(build_research_option(game, candidate_type, false))
	return options

static func refresh_research_overlay(game: Node) -> void:
	if game.research_overlay == null:
		return
	if game.research_room_label != null:
		var room_name: String = game.room_title(game.research_overlay_open_room) if game.rooms.has(game.research_overlay_open_room) else "Research"
		game.research_room_label.text = "%s\nArcana %d  Materials %d" % [room_name, game.science, game.industry]
	if game.research_offer_choices.is_empty():
		game.research_selected_index = -1
	elif game.research_selected_index < 0 or game.research_selected_index >= game.research_offer_choices.size():
		game.research_selected_index = 0
	for button_index in range(game.research_choice_buttons.size()):
		var choice_button: Button = game.research_choice_buttons[button_index]
		var enabled: bool = button_index < game.research_offer_choices.size()
		choice_button.visible = enabled
		choice_button.button_pressed = enabled and button_index == game.research_selected_index
		if not enabled:
			continue
		var option: Dictionary = game.research_offer_choices[button_index]
		var option_cost: int = int(option.get("cost", 0))
		choice_button.disabled = false
		choice_button.text = "%s\n%d Arcana" % [String(option.get("title", "")), option_cost]
	if game.research_selected_index >= 0 and game.research_selected_index < game.research_offer_choices.size():
		var selected_option: Dictionary = game.research_offer_choices[game.research_selected_index]
		var selected_cost: int = int(selected_option.get("cost", 0))
		if game.research_detail_title_label != null:
			game.research_detail_title_label.text = String(selected_option.get("title", "Research"))
		if game.research_detail_summary_label != null:
			game.research_detail_summary_label.text = String(selected_option.get("description", ""))
		if game.research_detail_stats_label != null:
			game.research_detail_stats_label.text = research_option_stats_text(game, selected_option)
		if game.research_detail_cost_label != null:
			game.research_detail_cost_label.text = "Cost %d Arcana  |  Duration 3 doors" % selected_cost
		if game.research_start_button != null:
			game.research_start_button.disabled = game.science < selected_cost
			game.research_start_button.text = "Start Research"
	else:
		if game.research_detail_title_label != null:
			game.research_detail_title_label.text = "No Research Available"
		if game.research_detail_summary_label != null:
			game.research_detail_summary_label.text = "This crystal has nothing left to offer."
		if game.research_detail_stats_label != null:
			game.research_detail_stats_label.text = ""
		if game.research_detail_cost_label != null:
			game.research_detail_cost_label.text = ""
		if game.research_start_button != null:
			game.research_start_button.disabled = true
	if game.research_reroll_button != null:
			var reroll_cost: int = game.research_reroll_cost()
			game.research_reroll_button.disabled = game.science < reroll_cost
			game.research_reroll_button.text = "Reroll (%d Arc)" % reroll_cost

static func open_research_overlay(game: Node, room_coord: Vector2i) -> void:
	if game.research_overlay == null or not game.room_has_research_crystal(room_coord):
		return
	if game.research_in_progress():
		game.status_message = "Research already underway: %s." % active_research_title(game)
		game.update_hud()
		return
	if GAME_FLOOR_FLOW.all_floor_doors_opened(game):
		game.status_message = "No unopened doors remain on this floor."
		game.update_hud()
		return
	game.research_overlay_open_room = room_coord
	game.research_offer_choices = roll_research_offer_choices(game)
	game.research_selected_index = 0
	if game.research_offer_choices.is_empty():
		game.research_overlay_open_room = game.INVALID_ROOM
		game.status_message = "No additional research remains at this crystal."
		game.update_hud()
		return
	game.research_overlay.visible = true
	refresh_research_overlay(game)

static func close_research_overlay(game: Node) -> void:
	game.research_overlay_open_room = game.INVALID_ROOM
	game.research_offer_choices.clear()
	game.research_selected_index = -1
	if game.research_overlay != null:
		game.research_overlay.visible = false

static func apply_research_option(game: Node, choice_index: int) -> void:
	if game.research_overlay_open_room == game.INVALID_ROOM or choice_index < 0 or choice_index >= game.research_offer_choices.size():
		return
	if game.research_in_progress():
		game.status_message = "Research already underway."
		game.update_hud()
		return
	if GAME_FLOOR_FLOW.all_floor_doors_opened(game):
		game.status_message = "No unopened doors remain on this floor."
		game.update_hud()
		return
	var option: Dictionary = game.research_offer_choices[choice_index]
	var option_cost: int = int(option.get("cost", 0))
	if game.science < option_cost:
		game.status_message = "Not enough arcana."
		game.update_hud()
		return
	game.science -= option_cost
	game.active_research = option.duplicate(true)
	game.active_research["room"] = game.research_overlay_open_room
	game.active_research["doors_remaining"] = 3
	game.active_research["doors_total"] = 3
	game.status_message = "Research started: %s. 3 doors remaining." % String(option.get("title", "Research"))
	close_research_overlay(game)
	game.update_hud()
	game.queue_redraw()

static func room_has_research_crystal(game: Node, room_coord: Vector2i) -> bool:
	return game.rooms.has(room_coord) and bool(game.rooms[room_coord].get("research_crystal", false))

static func research_in_progress(game: Node) -> bool:
	return not game.active_research.is_empty()

static func room_has_active_research(game: Node, room_coord: Vector2i) -> bool:
	return research_in_progress(game) and Vector2i(game.active_research.get("room", game.INVALID_ROOM)) == room_coord

static func can_start_research_in_room(game: Node, room_coord: Vector2i) -> bool:
	return room_has_research_crystal(game, room_coord) and not research_in_progress(game) and not GAME_FLOOR_FLOW.all_floor_doors_opened(game)

static func _on_research_choice_button_pressed(game: Node, choice_index: int) -> void:
	game.research_selected_index = choice_index
	refresh_research_overlay(game)

static func _on_research_start_button_pressed(game: Node) -> void:
	if game.research_selected_index < 0:
		return
	apply_research_option(game, game.research_selected_index)

static func _on_research_reroll_button_pressed(game: Node) -> void:
	if game.research_overlay_open_room == game.INVALID_ROOM:
		return
	var reroll_cost: int = game.research_reroll_cost()
	if game.science < reroll_cost:
		game.status_message = "Not enough arcana to reroll."
		game.update_hud()
		return
	game.science -= reroll_cost
	game.research_reroll_count += 1
	game.research_offer_choices = roll_research_offer_choices(game)
	game.research_selected_index = 0 if not game.research_offer_choices.is_empty() else -1
	game.status_message = "Research options rerolled."
	refresh_research_overlay(game)
	game.update_hud()

static func _on_research_close_button_pressed(game: Node) -> void:
	close_research_overlay(game)
	game.update_hud()
