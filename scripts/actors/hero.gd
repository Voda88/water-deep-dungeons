extends CharacterBody2D
class_name Hero

const INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const SPRITE_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const HERO_SPRITE_PROFILES := {
	"fighter": {
		"idle_path": "res://assets/characters/heroes/fighter/Swordsman_Idle.png",
		"walk_path": "res://assets/characters/heroes/fighter/Swordsman_Walk.png",
		"hurt_path": "res://assets/characters/heroes/fighter/Swordsman_Hurt.png",
		"attack_melee_path": "res://assets/characters/heroes/fighter/Swordsman_Attack01.png",
		"attack_ranged_path": "res://assets/characters/heroes/fighter/Swordsman_Attack02.png",
		"death_path": "res://assets/characters/heroes/fighter/Swordsman_Death.png",
		"portrait_path": "res://assets/characters/heroes/fighter/Swordsman_Idle.png",
	},
	"cleric": {
		"idle_path": "res://assets/characters/heroes/cleric/Priest_Idle.png",
		"walk_path": "res://assets/characters/heroes/cleric/Priest_Walk.png",
		"hurt_path": "res://assets/characters/heroes/cleric/Priest_Hurt.png",
		"attack_melee_path": "res://assets/characters/heroes/cleric/Priest_Attack.png",
		"attack_ranged_path": "res://assets/characters/heroes/cleric/Priest_Heal.png",
		"death_path": "res://assets/characters/heroes/cleric/Priest_Death.png",
		"portrait_path": "res://assets/characters/heroes/cleric/Priest_Idle.png",
	},
	"rogue": {
		"idle_path": "res://assets/characters/heroes/rogue/Archer_Idle.png",
		"walk_path": "res://assets/characters/heroes/rogue/Archer_Walk.png",
		"hurt_path": "res://assets/characters/heroes/rogue/Archer_Hurt.png",
		"attack_melee_path": "res://assets/characters/heroes/rogue/Archer_Attack01.png",
		"attack_ranged_path": "res://assets/characters/heroes/rogue/Archer_Attack01.png",
		"death_path": "res://assets/characters/heroes/rogue/Archer_Death.png",
		"portrait_path": "res://assets/characters/heroes/rogue/Archer_Idle.png",
	},
	"wizard": {
		"idle_path": "res://assets/characters/heroes/wizard/Wizard_Idle.png",
		"walk_path": "res://assets/characters/heroes/wizard/Wizard_Walk.png",
		"hurt_path": "res://assets/characters/heroes/wizard/Wizard_Hurt.png",
		"attack_melee_path": "res://assets/characters/heroes/wizard/Wizard_Attack01.png",
		"attack_ranged_path": "res://assets/characters/heroes/wizard/Wizard_Attack01(With magic effects).png",
		"death_path": "res://assets/characters/heroes/wizard/Wizard_Death.png",
		"portrait_path": "res://assets/characters/heroes/wizard/Wizard_Idle.png",
	},
}

static var hero_sprite_frames_cache: Dictionary = {}

@export var move_speed: float = 340.0
@export var calm_move_speed_multiplier: float = 1.95
@export var combat_move_speed_multiplier: float = 0.72
@export var crystal_carry_speed_multiplier: float = 0.42
@export var max_health: float = 100.0
@export var max_stamina: float = 5.0
@export var attack_damage: float = 20.0
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 0.55
@export var weight: float = 1.6
@export var melee_windup_duration: float = 0.2
@export var body_color: Color = Color("7ad7ff")
@export var core_color: Color = Color("f7f4d5")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var hero_index: int = 0
var hero_name: String = "Hero"
var hero_class_id: String = "fighter"
var level: int = 1
var base_move_speed: float = 0.0
var base_max_health: float = 0.0
var base_max_stamina: float = 0.0
var base_attack_damage: float = 0.0
var base_attack_range: float = 0.0
var base_attack_cooldown: float = 0.0
var base_max_hand_size: int = 4
var inventory_canvas_size: Vector2i = Vector2i(9, 8)
var base_inventory_origin: Vector2i = Vector2i(3, 3)
var base_inventory_size: Vector2i = Vector2i(2, 2)
var pack_modules: Array = []
var inventory_items: Array = []
var synergy_count: int = 0
var current_health: float = 0.0
var stamina: float = 0.0
var cooldown_left: float = 0.0
var current_room: Vector2i = Vector2i.ZERO
var pending_room: Vector2i = INVALID_ROOM
var destination: Vector2 = Vector2.ZERO
var move_steps: Array = []
var pending_open_room: Vector2i = INVALID_ROOM
var pending_open_origin_room: Vector2i = INVALID_ROOM
var player_command_locked: bool = false
var selected: bool = true
var carrying_crystal: bool = false
var attack_effect_left: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var attack_style: String = ""
var preferred_attack_style: String = "laser"
var combat_movement_mode: bool = false
var max_hand_size: int = 4
var combo_points: int = 0
var hand_cards: Array = []
var card_generation_timers: Dictionary = {}
var passive_combat_timers: Dictionary = {}
var stamina_regen_rate: float = 0.0
var stamina_regen_time_left: float = 0.0
var barrier_amount: float = 0.0
var barrier_capacity: float = 0.0
var barrier_time_left: float = 0.0
var invulnerability_time_left: float = 0.0
var light_cantrip_active: bool = false
var learned_spells: Array[String] = []
var slotted_spells: Array[String] = []
var active_floor_spells: Array[String] = []
var studying_spell_id: String = ""
var studying_room: Vector2i = INVALID_ROOM
var studying_started_at_door: int = -1
var hurt_effect_left: float = 0.0
var visual_facing_left: bool = false
var dead_started: bool = false
var permanently_hidden_dead: bool = false

func _ready() -> void:
	base_move_speed = move_speed
	base_max_health = max_health
	base_max_stamina = max_stamina
	base_attack_damage = attack_damage
	base_attack_range = attack_range
	base_attack_cooldown = attack_cooldown
	base_max_hand_size = max_hand_size
	current_health = max_health
	stamina = max_stamina
	destination = global_position
	ensure_sprite_setup()
	update_sprite_state(Vector2.ZERO)

static func build_strip_animation(frames: SpriteFrames, animation_name: String, texture: Texture2D, frame_count: int, fps: float, loop: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)
	for frame_index in range(frame_count):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * SPRITE_FRAME_SIZE.x, 0, SPRITE_FRAME_SIZE.x, SPRITE_FRAME_SIZE.y)
		frames.add_frame(animation_name, atlas)

static func sprite_profile_for_class(class_id: String) -> Dictionary:
	return HERO_SPRITE_PROFILES.get(class_id, HERO_SPRITE_PROFILES["fighter"])

static func portrait_path_for_class(class_id: String) -> String:
	return String(sprite_profile_for_class(class_id).get("portrait_path", HERO_SPRITE_PROFILES["fighter"]["portrait_path"]))

static func load_sprite_texture(profile: Dictionary, key: String, fallback_key: String) -> Texture2D:
	var preferred_path: String = String(profile.get(key, ""))
	if preferred_path != "":
		var preferred_resource: Resource = load(preferred_path)
		if preferred_resource is Texture2D:
			return preferred_resource
	var fallback_path: String = String(HERO_SPRITE_PROFILES["fighter"].get(fallback_key, ""))
	var fallback_resource: Resource = load(fallback_path)
	if fallback_resource is Texture2D:
		return fallback_resource
	return null

static func strip_frame_count(texture: Texture2D, fallback: int) -> int:
	if texture == null:
		return fallback
	var width: int = texture.get_width()
	if width <= 0:
		return fallback
	return maxi(int(round(float(width) / float(SPRITE_FRAME_SIZE.x))), 1)

static func shared_hero_sprite_frames(class_id: String) -> SpriteFrames:
	if hero_sprite_frames_cache.has(class_id):
		return hero_sprite_frames_cache[class_id]
	var profile: Dictionary = sprite_profile_for_class(class_id)
	var idle_texture: Texture2D = load_sprite_texture(profile, "idle_path", "idle_path")
	var walk_texture: Texture2D = load_sprite_texture(profile, "walk_path", "walk_path")
	var hurt_texture: Texture2D = load_sprite_texture(profile, "hurt_path", "hurt_path")
	var attack_melee_texture: Texture2D = load_sprite_texture(profile, "attack_melee_path", "attack_melee_path")
	var attack_ranged_texture: Texture2D = load_sprite_texture(profile, "attack_ranged_path", "attack_ranged_path")
	var death_texture: Texture2D = load_sprite_texture(profile, "death_path", "death_path")
	var frames: SpriteFrames = SpriteFrames.new()
	build_strip_animation(frames, "idle", idle_texture, strip_frame_count(idle_texture, 6), 7.0, true)
	build_strip_animation(frames, "walk", walk_texture, strip_frame_count(walk_texture, 8), 11.0, true)
	build_strip_animation(frames, "hurt", hurt_texture, strip_frame_count(hurt_texture, 4), 14.0, false)
	build_strip_animation(frames, "attack_melee", attack_melee_texture, strip_frame_count(attack_melee_texture, 6), 13.0, false)
	build_strip_animation(frames, "attack_ranged", attack_ranged_texture, strip_frame_count(attack_ranged_texture, 6), 14.0, false)
	build_strip_animation(frames, "death", death_texture, strip_frame_count(death_texture, 4), 10.0, false)
	hero_sprite_frames_cache[class_id] = frames
	return frames

func ensure_sprite_setup() -> void:
	if animated_sprite == null:
		return
	var class_frames: SpriteFrames = shared_hero_sprite_frames(hero_class_id)
	if animated_sprite.sprite_frames != class_frames:
		animated_sprite.sprite_frames = class_frames
	animated_sprite.animation = "idle"
	animated_sprite.play()
	apply_sprite_tint()

func sprite_tint_for_class() -> Color:
	return Color.WHITE

func apply_sprite_tint() -> void:
	if animated_sprite == null:
		return
	animated_sprite.modulate = sprite_tint_for_class()

func desired_sprite_animation(move_offset: Vector2) -> String:
	if dead_started:
		return "death"
	if hurt_effect_left > 0.0:
		return "hurt"
	if attack_effect_left > 0.0:
		return "attack_melee" if preferred_attack_style == "melee" else "attack_ranged"
	if velocity.length() > 8.0 or move_offset.length() > 8.0:
		return "walk"
	return "idle"

func update_visual_facing(move_offset: Vector2) -> void:
	var facing_source: Vector2 = attack_direction if attack_effect_left > 0.0 else (velocity if velocity.length() > 4.0 else move_offset)
	if absf(facing_source.x) >= 3.0:
		visual_facing_left = facing_source.x < 0.0
	if animated_sprite != null:
		animated_sprite.flip_h = visual_facing_left

func update_sprite_state(move_offset: Vector2) -> void:
	if animated_sprite == null:
		return
	update_visual_facing(move_offset)
	var animation_name: String = desired_sprite_animation(move_offset)
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play()
	if animation_name == "walk":
		animated_sprite.speed_scale = clampf(movement_speed() / maxf(base_move_speed, 1.0), 0.75, 2.2)
	elif animation_name == "attack_melee":
		animated_sprite.speed_scale = 0.72
	elif animation_name == "attack_ranged":
		animated_sprite.speed_scale = 0.92
	else:
		animated_sprite.speed_scale = 1.0

func is_dead_state() -> bool:
	return dead_started

func begin_death() -> void:
	if dead_started:
		return
	dead_started = true
	current_health = 0.0
	attack_effect_left = 0.0
	hurt_effect_left = 0.0
	move_steps.clear()
	pending_room = INVALID_ROOM
	pending_open_room = INVALID_ROOM
	pending_open_origin_room = INVALID_ROOM
	player_command_locked = false
	destination = global_position
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.disabled = true
	collision_layer = 0
	collision_mask = 0
	update_sprite_state(Vector2.ZERO)
	queue_redraw()

func set_permanently_dead_hidden() -> void:
	begin_death()
	permanently_hidden_dead = true
	visible = false
	set_physics_process(false)
	queue_redraw()

func set_room(room: Vector2i, world_position: Vector2) -> void:
	current_room = room
	pending_room = INVALID_ROOM
	global_position = world_position
	destination = world_position
	reset_physics_interpolation()
	update_sprite_state(Vector2.ZERO)
	queue_redraw()

func set_destination(world_position: Vector2) -> void:
	if dead_started:
		return
	destination = world_position

func take_damage(amount: float) -> bool:
	if dead_started:
		return true
	if invulnerability_time_left > 0.0:
		return false
	var remaining_damage: float = maxf(amount, 0.0)
	if barrier_amount > 0.0 and remaining_damage > 0.0:
		var absorbed: float = minf(barrier_amount, remaining_damage)
		barrier_amount = maxf(barrier_amount - absorbed, 0.0)
		remaining_damage -= absorbed
		if barrier_amount <= 0.001:
			barrier_amount = 0.0
			barrier_capacity = 0.0
			barrier_time_left = 0.0
	current_health = maxf(current_health - remaining_damage, 0.0)
	hurt_effect_left = maxf(hurt_effect_left, 0.22)
	if current_health <= 0.0:
		begin_death()
	queue_redraw()
	return current_health <= 0.0

func restore_health() -> void:
	current_health = max_health
	queue_redraw()

func refill_stamina() -> void:
	stamina = max_stamina
	queue_redraw()

func can_use_stamina_cost(amount: float) -> bool:
	return amount <= 0.0 or stamina >= -0.001

func spend_stamina(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if not can_use_stamina_cost(amount):
		return false
	stamina = clampf(stamina - amount, -maxf(max_stamina, 1.0), max_stamina)
	queue_redraw()
	return true

func restore_stamina(amount: float) -> void:
	if amount <= 0.0:
		return
	stamina = clampf(stamina + amount, -maxf(max_stamina, 1.0), max_stamina)
	queue_redraw()

func apply_stamina_regen_buff(rate: float, duration: float) -> void:
	if duration <= 0.0 or rate <= 0.0:
		return
	stamina_regen_rate = maxf(stamina_regen_rate, rate)
	stamina_regen_time_left = maxf(stamina_regen_time_left, duration)
	queue_redraw()

func clear_stamina_regen_buff() -> void:
	stamina_regen_rate = 0.0
	stamina_regen_time_left = 0.0
	queue_redraw()

func apply_barrier(amount: float, duration: float) -> void:
	if amount <= 0.0 or duration <= 0.0:
		return
	barrier_amount = maxf(barrier_amount, amount)
	barrier_capacity = maxf(barrier_capacity, barrier_amount)
	barrier_time_left = maxf(barrier_time_left, duration)
	queue_redraw()

func clear_barrier() -> void:
	barrier_amount = 0.0
	barrier_capacity = 0.0
	barrier_time_left = 0.0
	queue_redraw()

func apply_invulnerability(duration: float) -> void:
	if duration <= 0.0:
		return
	invulnerability_time_left = maxf(invulnerability_time_left, duration)
	queue_redraw()

func clear_invulnerability() -> void:
	invulnerability_time_left = 0.0
	queue_redraw()

func heal(amount: float) -> bool:
	if amount <= 0.0:
		return current_health >= max_health
	var previous_health: float = current_health
	current_health = minf(current_health + amount, max_health)
	if current_health > previous_health:
		queue_redraw()
	return current_health >= max_health

func apply_inventory_stats(move_bonus: float, health_bonus: float, attack_bonus: float, stamina_bonus: float, hand_bonus: int, next_synergy_count: int) -> void:
	move_speed = base_move_speed + move_bonus
	var previous_max_health: float = max_health
	max_health = base_max_health + health_bonus
	var previous_max_stamina: float = max_stamina
	max_stamina = base_max_stamina + stamina_bonus
	attack_damage = base_attack_damage + attack_bonus
	max_hand_size = maxi(1, base_max_hand_size + hand_bonus)
	synergy_count = next_synergy_count
	if previous_max_health <= 0.001:
		current_health = max_health
	else:
		current_health = clampf(current_health + (max_health - previous_max_health), 1.0, max_health)
	if previous_max_stamina <= 0.001:
		stamina = max_stamina
	else:
		stamina = clampf(stamina + (max_stamina - previous_max_stamina), -maxf(max_stamina, 1.0), max_stamina)
	while hand_cards.size() > max_hand_size:
		hand_cards.pop_back()
	combo_points = maxi(combo_points, 0)
	queue_redraw()

func trigger_attack(target_position: Vector2, style: String = "laser") -> void:
	if dead_started:
		return
	attack_direction = (target_position - global_position).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.RIGHT
	attack_style = style
	attack_effect_left = 0.32 if style == "melee" else 0.18
	update_visual_facing(target_position - global_position)
	update_sprite_state(destination - global_position)
	queue_redraw()

func configure_archetype(class_id: String, display_name: String, next_move_speed: float, next_max_health: float, next_attack_damage: float, next_attack_range: float, next_attack_cooldown: float, next_attack_style: String, next_weight: float, next_melee_windup_duration: float, next_body_color: Color, next_core_color: Color) -> void:
	hero_class_id = class_id
	hero_name = display_name
	move_speed = next_move_speed
	max_health = next_max_health
	attack_damage = next_attack_damage
	attack_range = next_attack_range
	attack_cooldown = next_attack_cooldown
	preferred_attack_style = next_attack_style
	weight = maxf(next_weight, 0.1)
	melee_windup_duration = maxf(next_melee_windup_duration, 0.05)
	body_color = next_body_color
	core_color = next_core_color
	base_move_speed = next_move_speed
	base_max_health = next_max_health
	base_max_stamina = max_stamina
	base_attack_damage = next_attack_damage
	base_attack_range = next_attack_range
	base_attack_cooldown = next_attack_cooldown
	base_max_hand_size = max_hand_size
	current_health = clampf(current_health if current_health > 0.0 else max_health, 1.0, max_health)
	stamina = clampf(stamina if stamina > 0.0 else max_stamina, 0.0, max_stamina)
	ensure_sprite_setup()
	apply_sprite_tint()
	update_sprite_state(destination - global_position)
	queue_redraw()

func set_combat_movement_mode(in_combat: bool) -> void:
	combat_movement_mode = in_combat

func set_calm_movement_multiplier(multiplier: float) -> void:
	calm_move_speed_multiplier = maxf(multiplier, 0.1)

func movement_speed() -> float:
	var speed: float = move_speed * (combat_move_speed_multiplier if combat_movement_mode else calm_move_speed_multiplier)
	if carrying_crystal:
		return speed * crystal_carry_speed_multiplier
	return speed

func command_room() -> Vector2i:
	if pending_room == INVALID_ROOM:
		return current_room
	var current_distance: float = global_position.distance_to(destination)
	var pending_distance: float = global_position.distance_to(destination)
	if pending_distance + 24.0 < current_distance:
		return pending_room
	return current_room

func clear_orders(stop_movement: bool = true) -> void:
	if dead_started:
		return
	move_steps.clear()
	pending_open_room = INVALID_ROOM
	pending_open_origin_room = INVALID_ROOM
	player_command_locked = false
	if pending_room != INVALID_ROOM and stop_movement:
		current_room = pending_room
	pending_room = INVALID_ROOM
	if stop_movement:
		destination = global_position
		velocity = Vector2.ZERO

func is_idle() -> bool:
	return global_position.distance_to(destination) < 6.0

func _physics_process(delta: float) -> void:
	if permanently_hidden_dead:
		return
	if dead_started:
		velocity = Vector2.ZERO
		update_sprite_state(Vector2.ZERO)
		queue_redraw()
		return
	attack_effect_left = maxf(attack_effect_left - delta, 0.0)
	hurt_effect_left = maxf(hurt_effect_left - delta, 0.0)
	var offset: Vector2 = destination - global_position
	if offset.length() < 4.0:
		velocity = Vector2.ZERO
		global_position = destination
	else:
		var step: float = minf(movement_speed() * delta, offset.length())
		velocity = offset.normalized() * step / maxf(delta, 0.001)
	move_and_slide()
	update_sprite_state(offset)
	queue_redraw()

func _draw() -> void:
	if permanently_hidden_dead:
		return
	draw_string(ThemeDB.fallback_font, Vector2(-14.0, 34.0), hero_name, HORIZONTAL_ALIGNMENT_LEFT, 48.0, 15, Color("f4fbff"))
	var health_ratio: float = current_health / maxf(max_health, 0.001)
	draw_rect(Rect2(Vector2(-22.0, -38.0), Vector2(44.0, 6.0)), Color("1a2225"), true)
	draw_rect(Rect2(Vector2(-22.0, -38.0), Vector2(44.0 * health_ratio, 6.0)), Color("8df4b2"), true)
	var stamina_ratio: float = clampf(stamina / maxf(max_stamina, 0.001), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-22.0, -29.0), Vector2(44.0, 4.0)), Color("1a2225"), true)
	draw_rect(Rect2(Vector2(-22.0, -29.0), Vector2(44.0 * stamina_ratio, 4.0)), Color("8bc1ff"), true)
	if stamina < 0.0:
		var exhausted_ratio: float = clampf(absf(stamina) / maxf(max_stamina, 0.001), 0.0, 1.0)
		draw_rect(Rect2(Vector2(-22.0, -29.0), Vector2(44.0 * exhausted_ratio, 4.0)), Color("ff8d78"), true)
	if stamina_regen_time_left > 0.0:
		draw_rect(Rect2(Vector2(-22.0, -24.0), Vector2(44.0, 2.0)), Color("17323e"), true)
		draw_rect(Rect2(Vector2(-22.0, -24.0), Vector2(44.0 * clampf(stamina_regen_time_left / 8.0, 0.0, 1.0), 2.0)), Color("a4f3ff"), true)
	if barrier_time_left > 0.0 and barrier_capacity > 0.0:
		var barrier_ratio: float = clampf(barrier_amount / maxf(barrier_capacity, 0.001), 0.0, 1.0)
		draw_rect(Rect2(Vector2(-22.0, -44.0), Vector2(44.0, 3.0)), Color("17323e"), true)
		draw_rect(Rect2(Vector2(-22.0, -44.0), Vector2(44.0 * barrier_ratio, 3.0)), Color("b7d9ff"), true)
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 40, Color(0.72, 0.87, 1.0, 0.45 + 0.2 * barrier_ratio), 2.0, true)
	if invulnerability_time_left > 0.0:
		var shimmer: float = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.018)
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 44, Color(0.96, 0.98, 1.0, 0.45 + shimmer * 0.28), 3.0, true)
		draw_circle(Vector2.ZERO, 22.0, Color(0.75, 0.9, 1.0, 0.08 + shimmer * 0.05))
	if carrying_crystal:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, -52.0),
			Vector2(12.0, -36.0),
			Vector2(0.0, -20.0),
			Vector2(-12.0, -36.0),
		]), Color("ffe7a1"))
	if attack_effect_left > 0.0:
		var pulse: float = attack_effect_left / 0.32
		match attack_style:
			"laser":
				draw_line(Vector2.ZERO, attack_direction * 34.0, Color(1.0, 0.92, 0.62, 0.9), 5.0 * pulse, true)
				draw_circle(attack_direction * 18.0, 4.0 + 3.0 * pulse, Color("fff1a8"))
			_:
				draw_arc(Vector2.ZERO, 30.0, attack_direction.angle() - 0.45, attack_direction.angle() + 0.45, 16, Color("fff1a8"), 4.0, true)
	if selected:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 48, Color("f8ff7a"), 4.0, true)
