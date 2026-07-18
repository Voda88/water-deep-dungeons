extends CharacterBody2D
class_name Hero

const INVALID_ROOM: Vector2i = Vector2i(-99, -99)

@export var move_speed: float = 340.0
@export var crystal_carry_speed_multiplier: float = 0.42
@export var max_health: float = 100.0
@export var attack_damage: float = 20.0
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 0.55

var hero_index: int = 0
var hero_name: String = "Hero"
var level: int = 1
var base_move_speed: float = 0.0
var base_max_health: float = 0.0
var base_attack_damage: float = 0.0
var inventory_canvas_size: Vector2i = Vector2i(9, 8)
var base_inventory_origin: Vector2i = Vector2i(3, 3)
var base_inventory_size: Vector2i = Vector2i(2, 2)
var pack_modules: Array = []
var inventory_items: Array = []
var synergy_count: int = 0
var current_health: float = 0.0
var cooldown_left: float = 0.0
var current_room: Vector2i = Vector2i.ZERO
var pending_room: Vector2i = INVALID_ROOM
var destination: Vector2 = Vector2.ZERO
var move_steps: Array = []
var pending_open_room: Vector2i = INVALID_ROOM
var pending_open_origin_room: Vector2i = INVALID_ROOM
var selected: bool = true
var carrying_crystal: bool = false
var attack_effect_left: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var attack_style: String = ""

func _ready() -> void:
	base_move_speed = move_speed
	base_max_health = max_health
	base_attack_damage = attack_damage
	current_health = max_health
	destination = global_position

func set_room(room: Vector2i, world_position: Vector2) -> void:
	current_room = room
	pending_room = INVALID_ROOM
	global_position = world_position
	destination = world_position
	queue_redraw()

func set_destination(world_position: Vector2) -> void:
	destination = world_position

func take_damage(amount: float) -> bool:
	current_health = maxf(current_health - amount, 0.0)
	queue_redraw()
	return current_health <= 0.0

func restore_health() -> void:
	current_health = max_health
	queue_redraw()

func apply_inventory_stats(move_bonus: float, health_bonus: float, attack_bonus: float, next_synergy_count: int) -> void:
	move_speed = base_move_speed + move_bonus
	var previous_max_health: float = max_health
	max_health = base_max_health + health_bonus
	attack_damage = base_attack_damage + attack_bonus
	synergy_count = next_synergy_count
	if previous_max_health <= 0.001:
		current_health = max_health
	else:
		current_health = clampf(current_health + (max_health - previous_max_health), 1.0, max_health)
	queue_redraw()

func trigger_attack(target_position: Vector2, style: String = "laser") -> void:
	attack_direction = (target_position - global_position).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.RIGHT
	attack_style = style
	attack_effect_left = 0.14
	queue_redraw()

func movement_speed() -> float:
	if carrying_crystal:
		return move_speed * crystal_carry_speed_multiplier
	return move_speed

func command_room() -> Vector2i:
	if pending_room == INVALID_ROOM:
		return current_room
	var current_distance: float = global_position.distance_to(destination)
	var pending_distance: float = global_position.distance_to(destination)
	if pending_distance + 24.0 < current_distance:
		return pending_room
	return current_room

func clear_orders(stop_movement: bool = true) -> void:
	move_steps.clear()
	pending_open_room = INVALID_ROOM
	pending_open_origin_room = INVALID_ROOM
	if pending_room != INVALID_ROOM and stop_movement:
		current_room = pending_room
	pending_room = INVALID_ROOM
	if stop_movement:
		destination = global_position
		velocity = Vector2.ZERO

func is_idle() -> bool:
	return global_position.distance_to(destination) < 6.0

func _physics_process(delta: float) -> void:
	attack_effect_left = maxf(attack_effect_left - delta, 0.0)
	var offset: Vector2 = destination - global_position
	if offset.length() < 4.0:
		velocity = Vector2.ZERO
		global_position = destination
	else:
		var step: float = minf(movement_speed() * delta, offset.length())
		velocity = offset.normalized() * step / maxf(delta, 0.001)
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 19.0, Color("7ad7ff"))
	draw_circle(Vector2.ZERO, 8.0, Color("f7f4d5"))
	draw_string(ThemeDB.fallback_font, Vector2(-14.0, 34.0), hero_name, HORIZONTAL_ALIGNMENT_LEFT, 48.0, 15, Color("f4fbff"))
	var health_ratio: float = current_health / maxf(max_health, 0.001)
	draw_rect(Rect2(Vector2(-22.0, -33.0), Vector2(44.0, 6.0)), Color("1a2225"), true)
	draw_rect(Rect2(Vector2(-22.0, -33.0), Vector2(44.0 * health_ratio, 6.0)), Color("8df4b2"), true)
	if carrying_crystal:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, -52.0),
			Vector2(12.0, -36.0),
			Vector2(0.0, -20.0),
			Vector2(-12.0, -36.0),
		]), Color("ffe7a1"))
	if attack_effect_left > 0.0:
		var pulse: float = attack_effect_left / 0.14
		match attack_style:
			"laser":
				draw_line(Vector2.ZERO, attack_direction * 34.0, Color(1.0, 0.92, 0.62, 0.9), 5.0 * pulse, true)
				draw_circle(attack_direction * 18.0, 4.0 + 3.0 * pulse, Color("fff1a8"))
			_:
				draw_arc(Vector2.ZERO, 30.0, attack_direction.angle() - 0.45, attack_direction.angle() + 0.45, 16, Color("fff1a8"), 4.0, true)
	if selected:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 48, Color("f8ff7a"), 4.0, true)
