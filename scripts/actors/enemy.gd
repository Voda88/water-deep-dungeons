extends CharacterBody2D
class_name DungeonEnemy

const GAME_ENEMY_DEFS: GDScript = preload("res://scripts/content/game_enemy_defs.gd")

const INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const TYPE_ORC_RIDER: String = "orc_rider"
const TYPE_ORC: String = "orc"
const TYPE_BAT: String = "bat"
const TYPE_GOLEM: String = "golem"
const TYPE_ORC_SHAMAN: String = "orc_shaman"
const TYPE_SKELETON_ARCHER: String = "skeleton_archer"
const SPRITE_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const MELEE_IMPACT_FRAME: float = 2.0
const MELEE_ATTACK_FPS: float = 13.0
const MELEE_ATTACK_SPEED_SCALE: float = 0.82
const ENEMY_ATTACK_DAMAGE_MULTIPLIER: float = 0.5
const ENEMY_ATTACK_COOLDOWN_MULTIPLIER: float = 0.5
const OVERKILL_KNOCKBACK_FORCE_PER_DAMAGE: float = 18.0
const OVERKILL_KNOCKBACK_MAX_FORCE: float = 620.0
const OVERKILL_KNOCKBACK_DURATION_PER_DAMAGE: float = 0.008
const OVERKILL_KNOCKBACK_MAX_DURATION: float = 0.34

static var enemy_sprite_frames_cache: Dictionary = {}

@export var move_speed: float = 60.0
@export var max_health: float = 40.0
@export var attack_damage: float = 6.0
@export var attack_cooldown: float = 0.95
@export var attack_range: float = 70.0
@export var weight: float = 1.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_health: float = 0.0
var attack_cooldown_left: float = 0.0
var enemy_uid: int = -1
var current_room: Vector2i = Vector2i.ZERO
var pending_room: Vector2i = INVALID_ROOM
var previous_room: Vector2i = Vector2i.ZERO
var next_room: Vector2i = Vector2i.ZERO
var destination: Vector2 = Vector2.ZERO
var move_steps: Array = []
var moving_between_rooms: bool = false
var transit_stage: String = ""
var enemy_role: String = TYPE_ORC
var body_color: Color = Color("ff7764")
var base_move_speed: float = 60.0
var situational_speed_multiplier: float = 1.0
var recovering_slow_time_left: float = 0.0
var recovering_slow_duration: float = 0.0
var recovering_slow_move_multiplier: float = 1.0
var recovering_slow_attack_speed_multiplier: float = 1.0
var attack_effect_left: float = 0.0
var hurt_effect_left: float = 0.0
var visual_facing_left: bool = false
var death_started: bool = false
var rooted_time_left: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_left: float = 0.0
var knockback_duration: float = 0.0
var knockback_bounds_enabled: bool = false
var knockback_bounds: Rect2 = Rect2()
var knockback_regions: Array = []

func _ready() -> void:
	current_health = max_health
	base_move_speed = move_speed
	destination = global_position
	next_room = current_room
	previous_room = current_room
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

static func sprite_profile_for_role(role_name: String) -> Dictionary:
	return GAME_ENEMY_DEFS.enemy_sprite_profile(role_name)

static func load_sprite_texture(profile: Dictionary, key: String, fallback_key: String) -> Texture2D:
	var preferred_path: String = String(profile.get(key, ""))
	if preferred_path != "":
		var preferred_resource: Resource = load(preferred_path)
		if preferred_resource is Texture2D:
			return preferred_resource
	var fallback_path: String = String(GAME_ENEMY_DEFS.enemy_sprite_profile(TYPE_ORC).get(fallback_key, ""))
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

static func shared_enemy_sprite_frames(role_name: String) -> SpriteFrames:
	if enemy_sprite_frames_cache.has(role_name):
		return enemy_sprite_frames_cache[role_name]
	var profile: Dictionary = sprite_profile_for_role(role_name)
	var idle_texture: Texture2D = load_sprite_texture(profile, "idle_path", "idle_path")
	var walk_texture: Texture2D = load_sprite_texture(profile, "walk_path", "walk_path")
	var hurt_texture: Texture2D = load_sprite_texture(profile, "hurt_path", "hurt_path")
	var attack_texture: Texture2D = load_sprite_texture(profile, "attack_path", "attack_path")
	var death_texture: Texture2D = load_sprite_texture(profile, "death_path", "death_path")
	var frames: SpriteFrames = SpriteFrames.new()
	build_strip_animation(frames, "idle", idle_texture, strip_frame_count(idle_texture, 6), 7.0, true)
	build_strip_animation(frames, "walk", walk_texture, strip_frame_count(walk_texture, 8), 11.0, true)
	build_strip_animation(frames, "hurt", hurt_texture, strip_frame_count(hurt_texture, 4), 14.0, false)
	build_strip_animation(frames, "attack", attack_texture, strip_frame_count(attack_texture, 6), 13.0, false)
	build_strip_animation(frames, "death", death_texture, strip_frame_count(death_texture, 4), 10.0, false)
	enemy_sprite_frames_cache[role_name] = frames
	return frames

func ensure_sprite_setup() -> void:
	if animated_sprite == null:
		return
	var role_frames: SpriteFrames = shared_enemy_sprite_frames(enemy_role)
	if animated_sprite.sprite_frames != role_frames:
		animated_sprite.sprite_frames = role_frames
	animated_sprite.animation = "idle"
	animated_sprite.play()
	apply_role_visuals()

func animation_speed_scale_for(animation_name: String) -> float:
	match animation_name:
		"walk":
			return clampf(effective_move_speed() / 48.0, 0.7, 2.1)
		"attack":
			return 0.82
		_:
			return 1.0

func animation_duration(animation_name: String, fallback_duration: float = 0.3) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation(animation_name):
		return fallback_duration
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
	var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name)
	var speed_scale: float = animation_speed_scale_for(animation_name)
	return maxf(float(frame_count) / maxf(fps * speed_scale, 0.001), 0.08)

func role_scale() -> float:
	return GAME_ENEMY_DEFS.enemy_role_scale(enemy_role)

func apply_role_visuals() -> void:
	if animated_sprite == null:
		return
	animated_sprite.modulate = Color.WHITE.lerp(body_color, 0.16)
	animated_sprite.scale = Vector2.ONE * role_scale()

func desired_sprite_animation(move_offset: Vector2) -> String:
	if death_started:
		return "death"
	if hurt_effect_left > 0.0:
		return "hurt"
	if attack_effect_left > 0.0:
		return "attack"
	if velocity.length() > 6.0 or move_offset.length() > 8.0:
		return "walk"
	return "idle"

func update_visual_facing(move_offset: Vector2) -> void:
	var facing_source: Vector2 = velocity if velocity.length() > 4.0 else move_offset
	if attack_effect_left > 0.0 and destination.distance_squared_to(global_position) > 1.0:
		facing_source = destination - global_position
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
	animated_sprite.speed_scale = animation_speed_scale_for(animation_name)

func effective_move_speed() -> float:
	if rooted_time_left > 0.0:
		return 0.0
	return move_speed * situational_speed_multiplier * current_recovering_slow_move_multiplier()

func recovering_slow_strength() -> float:
	if recovering_slow_time_left <= 0.0 or recovering_slow_duration <= 0.0:
		return 0.0
	return clampf(recovering_slow_time_left / recovering_slow_duration, 0.0, 1.0)

func current_recovering_slow_move_multiplier() -> float:
	var strength: float = recovering_slow_strength()
	return lerpf(1.0, recovering_slow_move_multiplier, strength)

func current_recovering_slow_attack_speed_multiplier() -> float:
	var strength: float = recovering_slow_strength()
	return clampf(lerpf(1.0, recovering_slow_attack_speed_multiplier, strength), 0.0, 1.0)

func effective_attack_cooldown_multiplier() -> float:
	return 1.0 / maxf(current_recovering_slow_attack_speed_multiplier(), 0.001)

func attack_cooldown_tick_scale() -> float:
	return current_recovering_slow_attack_speed_multiplier()

func apply_recovering_slow_debuff(duration: float, move_multiplier: float, attack_speed_multiplier: float) -> void:
	if duration <= 0.0 or death_started:
		return
	recovering_slow_duration = maxf(recovering_slow_duration, duration)
	recovering_slow_time_left = maxf(recovering_slow_time_left, duration)
	recovering_slow_move_multiplier = minf(recovering_slow_move_multiplier, clampf(move_multiplier, 0.0, 1.0))
	recovering_slow_attack_speed_multiplier = minf(recovering_slow_attack_speed_multiplier, clampf(attack_speed_multiplier, 0.0, 1.0))
	queue_redraw()

func set_situational_speed_multiplier(multiplier: float) -> void:
	situational_speed_multiplier = clampf(multiplier, 0.15, 2.5)

func apply_root(duration: float) -> void:
	if duration <= 0.0 or death_started:
		return
	rooted_time_left = maxf(rooted_time_left, duration)
	velocity = Vector2.ZERO
	queue_redraw()

func set_destination(world_position: Vector2) -> void:
	if death_started:
		return
	destination = world_position

func melee_impact_delay() -> float:
	var attack_frames: SpriteFrames = animated_sprite.sprite_frames if animated_sprite != null else null
	var attack_fps: float = MELEE_ATTACK_FPS
	if attack_frames != null and attack_frames.has_animation("attack"):
		attack_fps = attack_frames.get_animation_speed("attack")
	return MELEE_IMPACT_FRAME / maxf(attack_fps * animation_speed_scale_for("attack"), 0.001)

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

func trigger_attack(target_position: Vector2) -> void:
	if death_started:
		return
	destination = target_position if global_position.distance_to(target_position) <= 48.0 else destination
	attack_effect_left = maxf(attack_effect_left, animation_duration("attack", 0.32))
	update_visual_facing(target_position - global_position)
	update_sprite_state(destination - global_position)

func is_dying_state() -> bool:
	return death_started

func begin_death() -> void:
	if death_started:
		return
	death_started = true
	current_health = 0.0
	attack_effect_left = 0.0
	hurt_effect_left = 0.0
	move_steps.clear()
	moving_between_rooms = false
	pending_room = INVALID_ROOM
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

func _on_animated_sprite_animation_finished() -> void:
	if death_started and animated_sprite != null and animated_sprite.animation == "death":
		queue_free()
	elif animated_sprite != null:
		match String(animated_sprite.animation):
			"attack":
				attack_effect_left = 0.0
			"hurt":
				hurt_effect_left = 0.0

func set_role(role_name: String) -> void:
	var role_def: Dictionary = GAME_ENEMY_DEFS.enemy_role_definition(role_name)
	enemy_role = String(role_def.get("id", TYPE_ORC))
	move_speed = float(role_def.get("move_speed", 48.0))
	max_health = float(role_def.get("max_health", 34.0))
	attack_damage = float(role_def.get("attack_damage", 10.0)) * ENEMY_ATTACK_DAMAGE_MULTIPLIER
	attack_cooldown = maxf(float(role_def.get("attack_cooldown", 1.0)) * ENEMY_ATTACK_COOLDOWN_MULTIPLIER, 0.05)
	attack_range = float(role_def.get("attack_range", 70.0))
	weight = float(role_def.get("weight", 1.28))
	body_color = role_def.get("body_color", Color("7fad5b"))
	base_move_speed = move_speed
	situational_speed_multiplier = 1.0
	recovering_slow_time_left = 0.0
	recovering_slow_duration = 0.0
	recovering_slow_move_multiplier = 1.0
	recovering_slow_attack_speed_multiplier = 1.0
	current_health = max_health
	ensure_sprite_setup()
	apply_role_visuals()
	update_sprite_state(destination - global_position)
	queue_redraw()

func is_idle() -> bool:
	return global_position.distance_to(destination) < 6.0

func resolve_overkill_knockback_direction(hit_direction: Vector2) -> Vector2:
	var resolved_direction: Vector2 = hit_direction.normalized()
	if resolved_direction != Vector2.ZERO:
		return resolved_direction
	if velocity.length() > 6.0:
		resolved_direction = velocity.normalized()
		if resolved_direction != Vector2.ZERO:
			return resolved_direction
	var destination_offset: Vector2 = destination - global_position
	if destination_offset.length() > 0.001:
		resolved_direction = destination_offset.normalized()
		if resolved_direction != Vector2.ZERO:
			return resolved_direction
	return Vector2.RIGHT

func apply_overkill_knockback(overkill_damage: float, hit_direction: Vector2) -> void:
	if overkill_damage <= 0.0:
		return
	var force: float = minf(overkill_damage * OVERKILL_KNOCKBACK_FORCE_PER_DAMAGE, OVERKILL_KNOCKBACK_MAX_FORCE)
	if force <= 0.0:
		return
	var duration: float = clampf(0.12 + overkill_damage * OVERKILL_KNOCKBACK_DURATION_PER_DAMAGE, 0.12, OVERKILL_KNOCKBACK_MAX_DURATION)
	apply_knockback_impulse(resolve_overkill_knockback_direction(hit_direction) * force, duration)

func take_damage(amount: float, hit_direction: Vector2 = Vector2.ZERO) -> bool:
	if death_started:
		return true
	var applied_damage: float = maxf(amount, 0.0)
	var health_before: float = current_health
	current_health = maxf(current_health - applied_damage, 0.0)
	hurt_effect_left = maxf(hurt_effect_left, 0.22)
	if current_health <= 0.0:
		begin_death()
		var overkill_damage: float = maxf(applied_damage - health_before, 0.0)
		apply_overkill_knockback(overkill_damage, hit_direction)
		return true
	queue_redraw()
	return false

func _physics_process(delta: float) -> void:
	if death_started:
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
	rooted_time_left = maxf(rooted_time_left - delta, 0.0)
	recovering_slow_time_left = maxf(recovering_slow_time_left - delta, 0.0)
	if recovering_slow_time_left <= 0.0 and recovering_slow_duration > 0.0:
		recovering_slow_duration = 0.0
		recovering_slow_move_multiplier = 1.0
		recovering_slow_attack_speed_multiplier = 1.0
	var offset: Vector2 = destination - global_position
	var desired_velocity: Vector2 = Vector2.ZERO
	if offset.length() < 4.0:
		global_position = destination
	else:
		var step: float = minf(effective_move_speed() * knockback_recovery_factor() * delta, offset.length())
		desired_velocity = offset.normalized() * step / maxf(delta, 0.001)
	var knockback_impulse: Vector2 = advance_knockback(delta)
	velocity = desired_velocity + knockback_impulse
	move_and_slide()
	clamp_to_knockback_bounds()
	update_sprite_state(offset if offset.length() > 0.0 else knockback_impulse)
	queue_redraw()

func _draw() -> void:
	var health_ratio: float = clampf(current_health / maxf(max_health, 0.001), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-18.0, -31.0), Vector2(36.0, 4.0)), Color(0.08, 0.1, 0.11, 0.9), true)
	draw_rect(Rect2(Vector2(-18.0, -31.0), Vector2(36.0 * health_ratio, 4.0)), Color(0.98, 0.48, 0.42, 0.95), true)
	if rooted_time_left > 0.0:
		draw_circle(Vector2(0.0, 2.0), 22.0, Color(0.84, 0.92, 1.0, 0.08))
		draw_arc(Vector2(0.0, 2.0), 19.0, 0.0, TAU, 20, Color(0.92, 0.98, 1.0, 0.7), 1.8, true)
		draw_line(Vector2(-13.0, -8.0), Vector2(13.0, 12.0), Color(0.95, 0.98, 1.0, 0.55), 1.5, true)
		draw_line(Vector2(-13.0, 12.0), Vector2(13.0, -8.0), Color(0.95, 0.98, 1.0, 0.55), 1.5, true)
	if recovering_slow_time_left > 0.0 and rooted_time_left <= 0.0:
		draw_arc(Vector2.ZERO, 21.0, -PI * 0.5, -PI * 0.5 + TAU * recovering_slow_strength(), 18, Color(0.62, 0.8, 1.0, 0.9), 2.0, true)
