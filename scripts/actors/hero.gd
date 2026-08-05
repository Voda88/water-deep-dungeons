extends CharacterBody2D
class_name Hero

const INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const SPRITE_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const MELEE_IMPACT_FRAME: float = 2.0
const MELEE_ATTACK_FPS: float = 13.0
const MELEE_ATTACK_SPEED_SCALE: float = 0.72
const UNLIMITED_HAND_SIZE: int = 9999
const FIGHTER_CLASS_ID: String = "fighter"
const FIGHTER_RAGE_MAX_START: int = 6
const FIGHTER_RAGE_HITS_PER_POINT: int = 2
const HERO_SPRITE_PROFILES := {
	"fighter": {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Knight/Knight/Knight_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Knight/Knight/Knight_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Knight/Knight/Knight_Hurt.png",
		"attack_melee_path": "res://assets/characters/packs/pack01/characters_split_100x100/Knight/Knight/Knight_Attack01.png",
		"attack_ranged_path": "res://assets/characters/packs/pack01/characters_split_100x100/Knight/Knight/Knight_Attack02.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Knight/Knight/Knight_Death.png",
		"portrait_path": "res://assets/characters/packs/pack01/characters_split_100x100/Knight/Knight/Knight_Idle.png",
	},
	"cleric": {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Priest/Priest/Priest_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Priest/Priest/Priest_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Priest/Priest/Priest_Hurt.png",
		"attack_melee_path": "res://assets/characters/packs/pack01/characters_split_100x100/Priest/Priest/Priest_Attack.png",
		"attack_ranged_path": "res://assets/characters/packs/pack01/characters_split_100x100/Priest/Priest/Priest_Heal.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Priest/Priest/Priest_Death.png",
		"portrait_path": "res://assets/characters/packs/pack01/characters_split_100x100/Priest/Priest/Priest_Idle.png",
	},
	"rogue": {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Swordsman/Swordsman/Swordsman_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Swordsman/Swordsman/Swordsman_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Swordsman/Swordsman/Swordsman_Hurt.png",
		"attack_melee_path": "res://assets/characters/packs/pack01/characters_split_100x100/Swordsman/Swordsman/Swordsman_Attack01.png",
		"attack_ranged_path": "res://assets/characters/packs/pack01/characters_split_100x100/Swordsman/Swordsman/Swordsman_Attack02.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Swordsman/Swordsman/Swordsman_Death.png",
		"portrait_path": "res://assets/characters/packs/pack01/characters_split_100x100/Swordsman/Swordsman/Swordsman_Idle.png",
	},
	"wizard": {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Wizard/Wizard/Wizard_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Wizard/Wizard/Wizard_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Wizard/Wizard/Wizard_Hurt.png",
		"attack_melee_path": "res://assets/characters/packs/pack01/characters_split_100x100/Wizard/Wizard/Wizard_Attack01.png",
		"attack_ranged_path": "res://assets/characters/packs/pack01/characters_split_100x100/Wizard/Wizard/Wizard_Attack02.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Wizard/Wizard/Wizard_Death.png",
		"portrait_path": "res://assets/characters/packs/pack01/characters_split_100x100/Wizard/Wizard/Wizard_Idle.png",
	},
}

static var hero_sprite_frames_cache: Dictionary = {}

@export var move_speed: float = 340.0
@export var calm_move_speed_multiplier: float = 1.95
@export var combat_move_speed_multiplier: float = 0.72
@export var crystal_carry_speed_multiplier: float = 0.4
@export var max_health: float = 100.0
@export var attack_damage: float = 20.0
@export var defence: float = 0.0
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
var base_attack_damage: float = 0.0
var base_defence: float = 0.0
var base_attack_range: float = 0.0
var base_attack_cooldown: float = 0.0
var base_max_hand_size: int = 4
var inventory_canvas_size: Vector2i = Vector2i(9, 8)
var base_inventory_origin: Vector2i = Vector2i(3, 3)
var base_inventory_size: Vector2i = Vector2i(2, 2)
var pack_modules: Array = []
var inventory_items: Array = []
var synergy_count: int = 0
var basic_attack_knockback: float = 0.0
var current_health: float = 0.0
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
var combo_attack_progress: int = 0
var combo_decay_time_left: float = 0.0
var fighter_rage: int = 0
var fighter_rage_max: int = 0
var fighter_rage_hit_progress: int = 0
var food_attack_cooldown_multiplier: float = 1.0
var food_attack_speed_time_left: float = 0.0
var food_defence_bonus: float = 0.0
var food_defence_time_left: float = 0.0
var food_move_speed_multiplier: float = 1.0
var food_move_speed_time_left: float = 0.0
var haste_move_speed_multiplier: float = 1.0
var haste_attack_cooldown_multiplier: float = 1.0
var haste_time_left: float = 0.0
var scorcher_channel_active: bool = false
var scorcher_channel_room: Vector2i = INVALID_ROOM
var scorcher_channel_direction: Vector2 = Vector2.RIGHT
var scorcher_channel_range: float = 220.0
var scorcher_channel_arc_degrees: float = 70.0
var scorcher_dot_damage_per_second: float = 0.0
var scorcher_channel_tick_interval: float = 0.25
var scorcher_channel_tick_time_left: float = 0.0
var temporary_skulker_until_doors_opened: int = 0
var skulking_visual_active: bool = false
var operate_room: Vector2i = INVALID_ROOM
var operate_started_at_door: int = -1
var operate_attuned: bool = false
var applied_poisons: Array = []
var hand_cards: Array = []
var card_generation_timers: Dictionary = {}
var passive_combat_timers: Dictionary = {}
var barrier_amount: float = 0.0
var barrier_capacity: float = 0.0
var barrier_time_left: float = 0.0
var invulnerability_time_left: float = 0.0
var light_cantrip_active: bool = false
var learned_spells: Array[String] = []
var slotted_spells: Array[String] = []
var active_floor_spells: Array[String] = []
var pending_item_fusions: Array = []
var studying_spell_id: String = ""
var studying_room: Vector2i = INVALID_ROOM
var studying_started_at_door: int = -1
var hurt_effect_left: float = 0.0
var visual_facing_left: bool = false
var dead_started: bool = false
var permanently_hidden_dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_left: float = 0.0
var knockback_duration: float = 0.0
var knockback_bounds_enabled: bool = false
var knockback_bounds: Rect2 = Rect2()
var knockback_regions: Array = []
var reaction_card_preferences: Dictionary = {}
var evasive_roll_time_left: float = 0.0
var evasive_roll_speed_multiplier: float = 1.0
var evasive_roll_spin_speed: float = 0.0

func _ready() -> void:
	base_move_speed = move_speed
	base_max_health = max_health
	base_attack_damage = attack_damage
	base_defence = defence
	base_attack_range = attack_range
	base_attack_cooldown = attack_cooldown
	base_max_hand_size = max_hand_size
	current_health = max_health
	destination = global_position
	ensure_sprite_setup()
	if animated_sprite != null and not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
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

func active_food_buff_tint() -> Color:
	var tint: Color = Color.WHITE
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	if food_attack_speed_time_left > 0.0:
		tint = tint.lerp(Color(1.0, 0.74, 0.56, 1.0), 0.18 + 0.10 * pulse)
	if food_defence_time_left > 0.0:
		tint = tint.lerp(Color(0.68, 0.84, 1.0, 1.0), 0.18 + 0.10 * pulse)
	if food_move_speed_time_left > 0.0:
		tint = tint.lerp(Color(0.62, 1.0, 0.82, 1.0), 0.18 + 0.10 * pulse)
	return tint

func apply_sprite_tint() -> void:
	if animated_sprite == null:
		return
	var base_tint: Color = sprite_tint_for_class()
	var buff_tint: Color = active_food_buff_tint()
	animated_sprite.modulate = Color(base_tint.r * buff_tint.r, base_tint.g * buff_tint.g, base_tint.b * buff_tint.b, base_tint.a)

func should_reduce_animations() -> bool:
	var host: Node = get_parent()
	while host != null:
		if host.has_method("animations_reduced_mode_active"):
			return bool(host.call("animations_reduced_mode_active"))
		host = host.get_parent()
	return false

func desired_sprite_animation(move_offset: Vector2) -> String:
	if dead_started:
		return "death"
	if hurt_effect_left > 0.0:
		return "hurt"
	if attack_effect_left > 0.0:
		return attack_animation_name()
	if velocity.length() > 8.0 or move_offset.length() > 8.0:
		return "walk"
	return "idle"

func animation_name_for_style(style: String = "") -> String:
	var resolved_style: String = style if style != "" else preferred_attack_style
	if resolved_style == "holy_bolt":
		return "attack_ranged"
	if resolved_style == "heal_cast":
		return "attack_ranged"
	return "attack_melee" if resolved_style == "melee" else "attack_ranged"

func attack_animation_name() -> String:
	return animation_name_for_style(attack_style)

func animation_speed_scale_for(animation_name: String) -> float:
	match animation_name:
		"walk":
			return clampf(movement_speed() / maxf(base_move_speed, 1.0), 0.75, 2.2)
		"attack_melee":
			return 0.72
		"attack_ranged":
			var base_scale: float = 0.92
			if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(animation_name):
				var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
				var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name)
				var minimum_scale: float = float(frame_count) / maxf(fps * maxf(current_attack_cooldown(), 0.001), 0.001)
				return maxf(base_scale, minimum_scale)
			return base_scale
		_:
			return 1.0

func animation_duration(animation_name: String, fallback_duration: float = 0.3) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation(animation_name):
		return fallback_duration
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
	var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name)
	var speed_scale: float = animation_speed_scale_for(animation_name)
	return maxf(float(frame_count) / maxf(fps * speed_scale, 0.001), 0.08)

func should_play_attack_animation_backwards(animation_name: String) -> bool:
	if attack_effect_left <= 0.0 or animation_name != "attack_ranged":
		return false
	return attack_style == "laser" or attack_style == "fire_bolt" or attack_style == "holy_bolt"

func play_animation_with_current_mode(animation_name: String) -> void:
	if animated_sprite == null:
		return
	if should_reduce_animations() and animation_name != "death":
		animated_sprite.speed_scale = 1.0
		if animated_sprite.animation != animation_name:
			animated_sprite.animation = animation_name
		animated_sprite.stop()
		animated_sprite.frame = 0
		return
	var speed_value: float = animation_speed_scale_for(animation_name)
	if should_play_attack_animation_backwards(animation_name):
		animated_sprite.speed_scale = 1.0
		animated_sprite.play(animation_name, -speed_value, true)
		return
	animated_sprite.speed_scale = speed_value
	animated_sprite.play(animation_name)

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
		play_animation_with_current_mode(animation_name)
	elif not animated_sprite.is_playing():
		play_animation_with_current_mode(animation_name)

func is_dead_state() -> bool:
	return dead_started

func begin_death() -> void:
	if dead_started:
		return
	dead_started = true
	end_scorcher_channel()
	end_evasive_roll()
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
	if animated_sprite != null:
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("death")
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

func melee_impact_delay() -> float:
	var attack_frames: SpriteFrames = animated_sprite.sprite_frames if animated_sprite != null else null
	var attack_fps: float = MELEE_ATTACK_FPS
	if attack_frames != null and attack_frames.has_animation("attack_melee"):
		attack_fps = attack_frames.get_animation_speed("attack_melee")
	return MELEE_IMPACT_FRAME / maxf(attack_fps * animation_speed_scale_for("attack_melee"), 0.001)

func knockback_recovery_factor() -> float:
	if knockback_time_left <= 0.0 or knockback_duration <= 0.0:
		return 1.0
	return clampf(1.0 - (knockback_time_left / knockback_duration), 0.0, 1.0)

func apply_knockback_impulse(next_velocity: Vector2, duration: float, bounds: Rect2 = Rect2(), walkable_regions: Array = []) -> void:
	if next_velocity.length() <= 0.001 or duration <= 0.0:
		return
	if next_velocity.length() >= knockback_velocity.length():
		knockback_velocity = next_velocity
	else:
		knockback_velocity += next_velocity * 0.35
	knockback_duration = maxf(knockback_duration, duration)
	knockback_time_left = maxf(knockback_time_left, duration)
	if not walkable_regions.is_empty():
		knockback_regions = walkable_regions.duplicate(true)
		knockback_bounds_enabled = true
		knockback_bounds = bounds
	elif bounds.size.x > 0.0 and bounds.size.y > 0.0:
		knockback_regions.clear()
		knockback_bounds = bounds
		knockback_bounds_enabled = true
	queue_redraw()

func advance_knockback(delta: float) -> Vector2:
	var current_impulse: Vector2 = knockback_velocity
	if knockback_time_left > 0.0:
		knockback_time_left = maxf(knockback_time_left - delta, 0.0)
	var damping: float = clampf(delta * 9.0, 0.0, 1.0)
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, damping)
	if knockback_time_left <= 0.0 and knockback_velocity.length() <= 10.0:
		knockback_velocity = Vector2.ZERO
		knockback_duration = 0.0
		knockback_bounds_enabled = false
		knockback_regions.clear()
	return current_impulse

func clamp_to_knockback_bounds() -> void:
	if not knockback_bounds_enabled:
		return
	if not knockback_regions.is_empty():
		var nearest_point: Vector2 = global_position
		var nearest_distance_squared: float = INF
		for region_variant in knockback_regions:
			var region: Rect2 = Rect2(region_variant)
			if region.has_point(global_position):
				return
			var candidate_point: Vector2 = Vector2(
				clampf(global_position.x, region.position.x, region.end.x),
				clampf(global_position.y, region.position.y, region.end.y)
			)
			var distance_squared: float = candidate_point.distance_squared_to(global_position)
			if distance_squared < nearest_distance_squared:
				nearest_distance_squared = distance_squared
				nearest_point = candidate_point
		global_position = nearest_point
		return
	global_position = Vector2(
		clampf(global_position.x, knockback_bounds.position.x, knockback_bounds.end.x),
		clampf(global_position.y, knockback_bounds.position.y, knockback_bounds.end.y)
	)

func mitigated_damage_by_defence(attack_power: float) -> float:
	var safe_attack_power: float = maxf(attack_power, 0.0)
	var safe_defence: float = maxf(defence + (food_defence_bonus if food_defence_time_left > 0.0 else 0.0), 0.0)
	if safe_attack_power <= 0.0 or safe_defence <= 0.0:
		return safe_attack_power
	var mitigation_ratio: float = safe_defence / (safe_defence + 100.0)
	return safe_attack_power * (1.0 - mitigation_ratio)

func current_attack_cooldown() -> float:
	var cooldown_multiplier: float = 1.0
	if food_attack_speed_time_left > 0.0:
		cooldown_multiplier *= maxf(food_attack_cooldown_multiplier, 0.1)
	if haste_time_left > 0.0:
		cooldown_multiplier *= maxf(haste_attack_cooldown_multiplier, 0.1)
	return maxf(attack_cooldown * maxf(cooldown_multiplier, 0.1), 0.08)

func apply_food_attack_speed_buff(cooldown_multiplier: float, duration: float) -> void:
	if duration <= 0.0 or cooldown_multiplier <= 0.0:
		return
	food_attack_cooldown_multiplier = minf(food_attack_cooldown_multiplier, cooldown_multiplier)
	food_attack_speed_time_left = maxf(food_attack_speed_time_left, duration)
	apply_sprite_tint()
	queue_redraw()

func apply_food_defence_buff(defence_bonus: float, duration: float) -> void:
	if duration <= 0.0 or defence_bonus <= 0.0:
		return
	food_defence_bonus = maxf(food_defence_bonus, defence_bonus)
	food_defence_time_left = maxf(food_defence_time_left, duration)
	apply_sprite_tint()
	queue_redraw()

func apply_food_move_speed_buff(speed_multiplier: float, duration: float) -> void:
	if duration <= 0.0 or speed_multiplier <= 1.0:
		return
	food_move_speed_multiplier = maxf(food_move_speed_multiplier, speed_multiplier)
	food_move_speed_time_left = maxf(food_move_speed_time_left, duration)
	apply_sprite_tint()
	queue_redraw()

func apply_haste_buff(duration: float, move_speed_multiplier: float = 2.0, attack_speed_multiplier: float = 2.0) -> void:
	if duration <= 0.0:
		return
	haste_time_left = maxf(haste_time_left, duration)
	haste_move_speed_multiplier = maxf(haste_move_speed_multiplier, move_speed_multiplier)
	var cooldown_multiplier: float = 1.0 / maxf(attack_speed_multiplier, 0.1)
	haste_attack_cooldown_multiplier = minf(haste_attack_cooldown_multiplier, cooldown_multiplier)
	apply_sprite_tint()
	queue_redraw()

func clear_haste_buff() -> void:
	haste_time_left = 0.0
	haste_move_speed_multiplier = 1.0
	haste_attack_cooldown_multiplier = 1.0
	apply_sprite_tint()
	queue_redraw()

func advance_food_buffs(delta: float) -> void:
	if delta <= 0.0:
		return
	var changed: bool = false
	if food_attack_speed_time_left > 0.0:
		food_attack_speed_time_left = maxf(food_attack_speed_time_left - delta, 0.0)
		changed = true
		if food_attack_speed_time_left <= 0.0:
			food_attack_cooldown_multiplier = 1.0
	if food_defence_time_left > 0.0:
		food_defence_time_left = maxf(food_defence_time_left - delta, 0.0)
		changed = true
		if food_defence_time_left <= 0.0:
			food_defence_bonus = 0.0
	if food_move_speed_time_left > 0.0:
		food_move_speed_time_left = maxf(food_move_speed_time_left - delta, 0.0)
		changed = true
		if food_move_speed_time_left <= 0.0:
			food_move_speed_multiplier = 1.0
	if changed:
		apply_sprite_tint()

func take_damage(amount: float, allow_lethal_death: bool = true) -> bool:
	if dead_started:
		return true
	if invulnerability_time_left > 0.0:
		return false
	if amount > 0.0 and hero_class_id == FIGHTER_CLASS_ID and fighter_rage_max > 0:
		fighter_rage_hit_progress = maxi(fighter_rage_hit_progress, 0) + 1
		if fighter_rage_hit_progress >= FIGHTER_RAGE_HITS_PER_POINT:
			gain_fighter_rage(fighter_rage_hit_progress / FIGHTER_RAGE_HITS_PER_POINT)
			fighter_rage_hit_progress = fighter_rage_hit_progress % FIGHTER_RAGE_HITS_PER_POINT
	var remaining_damage: float = mitigated_damage_by_defence(amount)
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
	if current_health <= 0.0 and allow_lethal_death:
		begin_death()
	queue_redraw()
	return current_health <= 0.0

func restore_health() -> void:
	current_health = max_health
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

func begin_evasive_roll(duration: float, speed_multiplier: float = 2.0, spin_speed: float = 18.0, grant_invulnerability: bool = true) -> void:
	if dead_started or duration <= 0.0:
		return
	evasive_roll_time_left = maxf(evasive_roll_time_left, duration)
	evasive_roll_speed_multiplier = maxf(evasive_roll_speed_multiplier, speed_multiplier)
	if absf(evasive_roll_spin_speed) <= 0.001:
		evasive_roll_spin_speed = spin_speed
	else:
		evasive_roll_spin_speed = signf(evasive_roll_spin_speed) * maxf(absf(evasive_roll_spin_speed), absf(spin_speed))
	if grant_invulnerability:
		apply_invulnerability(duration)

func end_evasive_roll() -> void:
	evasive_roll_time_left = 0.0
	evasive_roll_speed_multiplier = 1.0
	evasive_roll_spin_speed = 0.0
	if animated_sprite != null:
		animated_sprite.rotation = 0.0

func has_active_scorcher_channel() -> bool:
	return scorcher_channel_active and scorcher_channel_room != INVALID_ROOM and scorcher_dot_damage_per_second > 0.0

func begin_scorcher_channel(room_coord: Vector2i, direction: Vector2, range_value: float, arc_degrees: float, damage_per_second: float, tick_interval: float) -> void:
	if dead_started:
		return
	scorcher_channel_active = true
	scorcher_channel_room = room_coord
	scorcher_channel_direction = direction.normalized()
	if scorcher_channel_direction == Vector2.ZERO:
		scorcher_channel_direction = Vector2.LEFT if visual_facing_left else Vector2.RIGHT
	scorcher_channel_range = maxf(range_value, 12.0)
	scorcher_channel_arc_degrees = clampf(arc_degrees, 10.0, 180.0)
	scorcher_dot_damage_per_second = maxf(damage_per_second, 0.0)
	scorcher_channel_tick_interval = maxf(tick_interval, 0.05)
	scorcher_channel_tick_time_left = 0.0
	move_steps.clear()
	set_destination(global_position)
	player_command_locked = true

func end_scorcher_channel() -> void:
	scorcher_channel_active = false
	scorcher_channel_room = INVALID_ROOM
	scorcher_channel_direction = Vector2.RIGHT
	scorcher_channel_range = 220.0
	scorcher_channel_arc_degrees = 70.0
	scorcher_dot_damage_per_second = 0.0
	scorcher_channel_tick_interval = 0.25
	scorcher_channel_tick_time_left = 0.0

func clear_invulnerability() -> void:
	invulnerability_time_left = 0.0
	queue_redraw()

func reaction_preference_key(generator_key: String, card_id: String) -> String:
	if generator_key != "":
		return "gen:%s" % generator_key
	if card_id != "":
		return "card:%s" % card_id
	return ""

func get_reaction_card_preference(generator_key: String, card_id: String, default_enabled: bool) -> bool:
	var key: String = reaction_preference_key(generator_key, card_id)
	if key == "":
		return default_enabled
	if reaction_card_preferences.has(key):
		return bool(reaction_card_preferences[key])
	return default_enabled

func set_reaction_card_preference(generator_key: String, card_id: String, enabled: bool) -> void:
	var key: String = reaction_preference_key(generator_key, card_id)
	if key == "":
		return
	reaction_card_preferences[key] = enabled

func heal(amount: float) -> bool:
	if amount <= 0.0:
		return current_health >= max_health
	var previous_health: float = current_health
	current_health = minf(current_health + amount, max_health)
	if current_health > previous_health:
		queue_redraw()
	return current_health >= max_health

func gain_fighter_rage(amount: int = 1) -> int:
	if hero_class_id != FIGHTER_CLASS_ID or fighter_rage_max <= 0 or amount <= 0:
		return fighter_rage
	fighter_rage = clampi(fighter_rage + amount, 0, fighter_rage_max)
	return fighter_rage

func fighter_rage_ratio() -> float:
	if fighter_rage_max <= 0:
		return 0.0
	return clampf(float(fighter_rage) / float(fighter_rage_max), 0.0, 1.0)

func apply_inventory_stats(move_bonus: float, health_bonus: float, attack_bonus: float, defence_bonus: float, _hand_bonus: int, next_synergy_count: int, basic_attack_knockback_bonus: float = 0.0) -> void:
	move_speed = base_move_speed + move_bonus
	var previous_max_health: float = max_health
	max_health = base_max_health + health_bonus
	attack_damage = base_attack_damage + attack_bonus
	defence = maxf(base_defence + defence_bonus, 0.0)
	basic_attack_knockback = maxf(basic_attack_knockback_bonus, 0.0)
	max_hand_size = UNLIMITED_HAND_SIZE
	synergy_count = next_synergy_count
	if previous_max_health <= 0.001:
		current_health = max_health
	else:
		current_health = clampf(current_health + (max_health - previous_max_health), 1.0, max_health)
	combo_points = maxi(combo_points, 0)
	fighter_rage = clampi(fighter_rage, 0, fighter_rage_max)
	fighter_rage_hit_progress = maxi(fighter_rage_hit_progress, 0)
	combo_attack_progress = maxi(combo_attack_progress, 0)
	combo_decay_time_left = maxf(combo_decay_time_left, 0.0)
	food_attack_speed_time_left = maxf(food_attack_speed_time_left, 0.0)
	food_defence_time_left = maxf(food_defence_time_left, 0.0)
	food_move_speed_time_left = maxf(food_move_speed_time_left, 0.0)
	haste_time_left = maxf(haste_time_left, 0.0)
	if operate_attuned and operate_room == INVALID_ROOM:
		operate_attuned = false
	operate_started_at_door = maxi(operate_started_at_door, -1)
	apply_sprite_tint()
	queue_redraw()

func trigger_attack(target_position: Vector2, style: String = "laser") -> void:
	if dead_started:
		return
	attack_direction = (target_position - global_position).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.RIGHT
	attack_style = style
	var animation_name: String = animation_name_for_style(style)
	attack_effect_left = maxf(attack_effect_left, animation_duration(animation_name, 0.32 if style == "melee" else 0.22))
	update_visual_facing(target_position - global_position)
	update_sprite_state(destination - global_position)
	queue_redraw()

func _on_animated_sprite_animation_finished() -> void:
	if animated_sprite == null:
		return
	match String(animated_sprite.animation):
		"attack_melee", "attack_ranged":
			attack_effect_left = 0.0
		"hurt":
			hurt_effect_left = 0.0

func configure_archetype(class_id: String, display_name: String, next_move_speed: float, next_max_health: float, next_attack_damage: float, next_defence: float, next_attack_range: float, next_attack_cooldown: float, next_attack_style: String, next_weight: float, next_melee_windup_duration: float, next_body_color: Color, next_core_color: Color) -> void:
	hero_class_id = class_id
	hero_name = display_name
	move_speed = next_move_speed
	max_health = next_max_health
	attack_damage = next_attack_damage
	defence = maxf(next_defence, 0.0)
	attack_range = next_attack_range
	attack_cooldown = next_attack_cooldown
	preferred_attack_style = next_attack_style
	weight = maxf(next_weight, 0.1)
	melee_windup_duration = maxf(next_melee_windup_duration, 0.05)
	body_color = next_body_color
	core_color = next_core_color
	base_move_speed = next_move_speed
	base_max_health = next_max_health
	base_attack_damage = next_attack_damage
	base_defence = defence
	base_attack_range = next_attack_range
	base_attack_cooldown = next_attack_cooldown
	base_max_hand_size = max_hand_size
	basic_attack_knockback = 0.0
	if class_id == FIGHTER_CLASS_ID:
		fighter_rage_max = FIGHTER_RAGE_MAX_START
		fighter_rage = 0
		fighter_rage_hit_progress = 0
	else:
		fighter_rage_max = 0
		fighter_rage = 0
		fighter_rage_hit_progress = 0
	clear_haste_buff()
	end_scorcher_channel()
	current_health = clampf(current_health if current_health > 0.0 else max_health, 1.0, max_health)
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
	if food_move_speed_time_left > 0.0:
		speed *= maxf(food_move_speed_multiplier, 1.0)
	if haste_time_left > 0.0:
		speed *= maxf(haste_move_speed_multiplier, 1.0)
	if evasive_roll_time_left > 0.0:
		speed *= maxf(evasive_roll_speed_multiplier, 1.0)
	if carrying_crystal:
		speed *= crystal_carry_speed_multiplier
	return speed * knockback_recovery_factor()

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
	advance_food_buffs(delta)
	apply_sprite_tint()
	if dead_started:
		var corpse_impulse: Vector2 = advance_knockback(delta)
		velocity = corpse_impulse
		move_and_slide()
		clamp_to_knockback_bounds()
		if animated_sprite != null and animated_sprite.animation != "death":
			animated_sprite.speed_scale = 1.0
			animated_sprite.play("death")
		queue_redraw()
		return
	attack_effect_left = maxf(attack_effect_left - delta, 0.0)
	hurt_effect_left = maxf(hurt_effect_left - delta, 0.0)
	if evasive_roll_time_left > 0.0:
		evasive_roll_time_left = maxf(evasive_roll_time_left - delta, 0.0)
		if animated_sprite != null:
			animated_sprite.rotation += evasive_roll_spin_speed * delta
		if evasive_roll_time_left <= 0.0:
			end_evasive_roll()
	if haste_time_left > 0.0:
		haste_time_left = maxf(haste_time_left - delta, 0.0)
		if haste_time_left <= 0.0:
			haste_move_speed_multiplier = 1.0
			haste_attack_cooldown_multiplier = 1.0
			apply_sprite_tint()
	var offset: Vector2 = destination - global_position
	var desired_velocity: Vector2 = Vector2.ZERO
	if offset.length() < 4.0:
		global_position = destination
	else:
		var step: float = minf(movement_speed() * delta, offset.length())
		desired_velocity = offset.normalized() * step / maxf(delta, 0.001)
	var knockback_impulse: Vector2 = advance_knockback(delta)
	velocity = desired_velocity + knockback_impulse
	move_and_slide()
	clamp_to_knockback_bounds()
	update_sprite_state(offset if offset.length() > 0.0 else knockback_impulse)
	queue_redraw()

func _draw() -> void:
	if permanently_hidden_dead:
		return
	var reduced_animations: bool = should_reduce_animations()
	# Keep class-based names like "Fighter 1" visible and centered under the sprite.
	var name_max_width: float = 140.0
	draw_string(ThemeDB.fallback_font, Vector2(-name_max_width * 0.5, 34.0), hero_name, HORIZONTAL_ALIGNMENT_CENTER, name_max_width, 15, Color("f4fbff"))
	var health_ratio: float = current_health / maxf(max_health, 0.001)
	draw_rect(Rect2(Vector2(-22.0, -38.0), Vector2(44.0, 6.0)), Color("1a2225"), true)
	draw_rect(Rect2(Vector2(-22.0, -38.0), Vector2(44.0 * health_ratio, 6.0)), Color("8df4b2"), true)
	if carrying_crystal:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, -52.0),
			Vector2(12.0, -36.0),
			Vector2(0.0, -20.0),
			Vector2(-12.0, -36.0),
		]), Color("ffe7a1"))
	if selected:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 48, Color("f8ff7a"), 4.0, true)
	if reduced_animations:
		return
	if evasive_roll_time_left > 0.0 and absf(evasive_roll_spin_speed) <= 0.001:
		var dash_pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.026)
		var dash_radius: float = 26.0 + 4.0 * dash_pulse
		draw_circle(Vector2.ZERO, dash_radius + 7.0, Color(0.48, 0.95, 0.86, 0.11))
		draw_circle(Vector2.ZERO, dash_radius + 2.0, Color(0.48, 0.95, 0.86, 0.16))
		draw_arc(Vector2.ZERO, dash_radius, 0.0, TAU, 44, Color(0.78, 1.0, 0.95, 0.8), 2.4, true)
	if barrier_time_left > 0.0 and barrier_capacity > 0.0:
		var barrier_ratio: float = clampf(barrier_amount / maxf(barrier_capacity, 0.001), 0.0, 1.0)
		draw_rect(Rect2(Vector2(-22.0, -44.0), Vector2(44.0, 3.0)), Color("17323e"), true)
		draw_rect(Rect2(Vector2(-22.0, -44.0), Vector2(44.0 * barrier_ratio, 3.0)), Color("b7d9ff"), true)
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 40, Color(0.72, 0.87, 1.0, 0.55 + 0.22 * barrier_ratio), 2.4, true)
	var shield_time_left: float = maxf(barrier_time_left, invulnerability_time_left)
	if shield_time_left > 0.0:
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.014)
		var glow_strength: float = 0.55 + 0.45 * pulse
		var bubble_radius: float = 27.0 + glow_strength * 2.2
		draw_circle(Vector2.ZERO, bubble_radius + 9.0, Color(0.33, 0.63, 1.0, 0.08 + 0.06 * glow_strength))
		draw_circle(Vector2.ZERO, bubble_radius + 5.0, Color(0.47, 0.77, 1.0, 0.12 + 0.08 * glow_strength))
		draw_circle(Vector2.ZERO, bubble_radius + 1.0, Color(0.65, 0.88, 1.0, 0.12 + 0.08 * glow_strength))
		draw_arc(Vector2.ZERO, bubble_radius, 0.0, TAU, 56, Color(0.82, 0.95, 1.0, 0.62 + 0.18 * glow_strength), 3.0, true)
		draw_arc(Vector2.ZERO, bubble_radius - 4.5, 0.0, TAU, 48, Color(0.62, 0.84, 1.0, 0.44 + 0.18 * glow_strength), 1.8, true)
	if invulnerability_time_left > 0.0:
		var shimmer: float = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.018)
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 44, Color(0.96, 0.98, 1.0, 0.56 + shimmer * 0.30), 3.2, true)
		draw_circle(Vector2.ZERO, 22.0, Color(0.75, 0.9, 1.0, 0.12 + shimmer * 0.08))
	if skulking_visual_active:
		var skulker_time: float = float(Time.get_ticks_msec()) * 0.0035
		for particle_index in range(9):
			var angle: float = skulker_time + float(particle_index) * (TAU / 9.0)
			var radial_pulse: float = 0.5 + 0.5 * sin(skulker_time * 2.2 + float(particle_index) * 0.7)
			var radius: float = 12.0 + radial_pulse * 10.0
			var particle_position: Vector2 = Vector2(cos(angle), sin(angle) * 0.65) * radius + Vector2(0.0, -4.0)
			var particle_size: float = 1.3 + 1.1 * radial_pulse
			draw_circle(particle_position, particle_size, Color(0.70, 0.86, 1.0, 0.28 + 0.26 * radial_pulse))
		draw_arc(Vector2(0.0, -4.0), 20.0 + 2.0 * (0.5 + 0.5 * sin(skulker_time * 1.7)), 0.0, TAU, 30, Color(0.78, 0.9, 1.0, 0.34), 1.4, true)
	if operate_room != INVALID_ROOM:
		var head_center: Vector2 = Vector2(0.0, -52.0)
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.016)
		if operate_attuned:
			var attuned_outer: float = 10.5 + 1.8 * pulse
			draw_circle(head_center, attuned_outer + 4.0, Color(0.56, 0.93, 1.0, 0.22 + 0.10 * pulse))
			draw_circle(head_center, attuned_outer, Color(0.84, 0.98, 1.0, 0.24 + 0.12 * pulse))
			draw_arc(head_center, attuned_outer + 0.5, 0.0, TAU, 28, Color(0.94, 0.99, 1.0, 0.88), 1.9, true)
		else:
			var charge_outer: float = 8.0 + 1.4 * pulse
			draw_circle(head_center, charge_outer + 3.0, Color(0.92, 0.83, 0.56, 0.16 + 0.08 * pulse))
			draw_arc(head_center, charge_outer, 0.0, TAU, 24, Color(1.0, 0.92, 0.66, 0.74), 1.6, true)
	if attack_effect_left > 0.0:
		var pulse: float = attack_effect_left / 0.32
		match attack_style:
			"laser":
				draw_line(Vector2.ZERO, attack_direction * 34.0, Color(1.0, 0.92, 0.62, 0.9), 5.0 * pulse, true)
				draw_circle(attack_direction * 18.0, 4.0 + 3.0 * pulse, Color("fff1a8"))
			_:
				draw_arc(Vector2.ZERO, 30.0, attack_direction.angle() - 0.45, attack_direction.angle() + 0.45, 16, Color("fff1a8"), 4.0, true)
