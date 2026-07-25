extends CharacterBody2D
class_name DungeonEnemy

const INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const TYPE_LIZARDMAN: String = "lizardman"
const TYPE_GOBLIN: String = "goblin"
const TYPE_KOBOLD: String = "kobold"
const TYPE_GOLEM: String = "golem"
const TYPE_GOBLIN_SHAMAN: String = "goblin_shaman"
const TYPE_SKELETON_ARCHER: String = "skeleton_archer"
const SPRITE_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const MELEE_IMPACT_FRAME: float = 2.0
const MELEE_ATTACK_FPS: float = 13.0
const MELEE_ATTACK_SPEED_SCALE: float = 0.82
const ENEMY_SPRITE_PROFILES := {
	TYPE_GOBLIN: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Death.png",
	},
	TYPE_GOBLIN_SHAMAN: {
		"idle_path": "res://assets/characters/packs/pack02/characters_split_100x100/Warlock/Warlock/Warlock_Idle.png",
		"walk_path": "res://assets/characters/packs/pack02/characters_split_100x100/Warlock/Warlock/Warlock_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack02/characters_split_100x100/Warlock/Warlock/Warlock_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack02/characters_split_100x100/Warlock/Warlock/Warlock_Attack02(With magic effects).png",
		"death_path": "res://assets/characters/packs/pack02/characters_split_100x100/Warlock/Warlock/Warlock_Death.png",
	},
	TYPE_KOBOLD: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Flying.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Flying.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Death.png",
	},
	TYPE_LIZARDMAN: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc rider/Orc rider/Orc rider_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc rider/Orc rider/Orc rider_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc rider/Orc rider/Orc rider_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc rider/Orc rider/Orc rider_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc rider/Orc rider/Orc rider_Death.png",
	},
	TYPE_GOLEM: {
		"idle_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Idle.png",
		"walk_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Attack01.png",
		"death_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Death.png",
	},
	TYPE_SKELETON_ARCHER: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Attack.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Death.png",
	},
}

static var enemy_sprite_frames_cache: Dictionary = {}

@export var move_speed: float = 60.0
@export var max_health: float = 40.0
@export var attack_damage: float = 6.0
@export var attack_cooldown: float = 0.95
@export var weight: float = 1.2
@export var melee_reach: float = 54.0

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
var enemy_role: String = TYPE_GOBLIN
var body_color: Color = Color("ff7764")
var attack_effect_left: float = 0.0
var hurt_effect_left: float = 0.0
var visual_facing_left: bool = false
var death_started: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_left: float = 0.0
var knockback_duration: float = 0.0
var knockback_bounds_enabled: bool = false
var knockback_bounds: Rect2 = Rect2()
var knockback_regions: Array = []

func _ready() -> void:
	current_health = max_health
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
	return ENEMY_SPRITE_PROFILES.get(role_name, ENEMY_SPRITE_PROFILES[TYPE_GOBLIN])

static func load_sprite_texture(profile: Dictionary, key: String, fallback_key: String) -> Texture2D:
	var preferred_path: String = String(profile.get(key, ""))
	if preferred_path != "":
		var preferred_resource: Resource = load(preferred_path)
		if preferred_resource is Texture2D:
			return preferred_resource
	var fallback_path: String = String(ENEMY_SPRITE_PROFILES[TYPE_GOBLIN].get(fallback_key, ""))
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

func role_scale() -> float:
	match enemy_role:
		TYPE_GOLEM:
			return 2.45
		TYPE_LIZARDMAN:
			return 2.15
		TYPE_KOBOLD:
			return 1.54
		TYPE_SKELETON_ARCHER:
			return 1.88
		TYPE_GOBLIN_SHAMAN:
			return 2.05
		_:
			return 1.92

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
	if animation_name == "walk":
		animated_sprite.speed_scale = clampf(move_speed / 48.0, 0.7, 2.1)
	elif animation_name == "attack":
		animated_sprite.speed_scale = 0.82
	else:
		animated_sprite.speed_scale = 1.0

func set_destination(world_position: Vector2) -> void:
	if death_started:
		return
	destination = world_position

func melee_impact_delay() -> float:
	return MELEE_IMPACT_FRAME / maxf(MELEE_ATTACK_FPS * MELEE_ATTACK_SPEED_SCALE, 0.001)

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
	attack_effect_left = maxf(attack_effect_left, 0.28)
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

func set_role(role_name: String) -> void:
	enemy_role = role_name
	match enemy_role:
		TYPE_LIZARDMAN:
			move_speed = 84.0
			max_health = 154.0
			attack_damage = 31.0
			attack_cooldown = 1.0
			weight = 3.15
			melee_reach = 62.0
			body_color = Color("8d9e67")
		TYPE_KOBOLD:
			move_speed = 70.0
			max_health = 14.0
			attack_damage = 6.0
			attack_cooldown = 1.0
			weight = 0.55
			melee_reach = 54.0
			body_color = Color("d0c6c0")
		TYPE_GOLEM:
			move_speed = 33.0
			max_health = 148.0
			attack_damage = 24.0
			attack_cooldown = 1.15
			weight = 5.4
			melee_reach = 68.0
			body_color = Color("8a887d")
		TYPE_GOBLIN_SHAMAN:
			move_speed = 38.0
			max_health = 36.0
			attack_damage = 11.0
			attack_cooldown = 1.1
			weight = 1.08
			melee_reach = 52.0
			body_color = Color("a16fd5")
		TYPE_SKELETON_ARCHER:
			move_speed = 50.0
			max_health = 26.0
			attack_damage = 13.0
			attack_cooldown = 1.0
			weight = 0.95
			melee_reach = 52.0
			body_color = Color("d7decf")
		_:
			move_speed = 42.0
			max_health = 32.0
			attack_damage = 10.0
			attack_cooldown = 1.0
			weight = 1.28
			melee_reach = 52.0
			body_color = Color("7fad5b")
	current_health = max_health
	ensure_sprite_setup()
	apply_role_visuals()
	update_sprite_state(destination - global_position)
	queue_redraw()

func is_idle() -> bool:
	return global_position.distance_to(destination) < 6.0

func take_damage(amount: float) -> bool:
	if death_started:
		return true
	current_health -= amount
	hurt_effect_left = maxf(hurt_effect_left, 0.22)
	if current_health <= 0.0:
		begin_death()
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
	var offset: Vector2 = destination - global_position
	var desired_velocity: Vector2 = Vector2.ZERO
	if offset.length() < 4.0:
		global_position = destination
	else:
		var step: float = minf(move_speed * knockback_recovery_factor() * delta, offset.length())
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
