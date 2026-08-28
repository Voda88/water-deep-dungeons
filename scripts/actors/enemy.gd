extends CharacterBody2D
class_name DungeonEnemy

const GAME_ENEMY_DEFS: GDScript = preload("res://scripts/content/game_enemy_defs.gd")
const GAME_STATUS_EFFECTS: GDScript = preload("res://scripts/actors/game_status_effects.gd")

const INVALID_ROOM: Vector2i = Vector2i(-99, -99)
const TYPE_ORC_RIDER: String = "orc_rider"
const TYPE_ORC: String = "orc"
const TYPE_BAT: String = "bat"
const TYPE_GOLEM: String = "golem"
const TYPE_DEMON_A: String = "demon_a"
const TYPE_DEMON_D: String = "demon_d"
const TYPE_WRAITH: String = "wraith"
const TYPE_ORC_SHAMAN: String = TYPE_WRAITH
const TYPE_DEATH_KNIGHT: String = "death_knight"
const TYPE_SKELETON_ARCHER: String = "skeleton_archer"
const TYPE_SPIRITUAL_WEAPON: String = "spiritual_weapon"
const TYPE_SLIME: String = "slime"
const FAMILIAR_SUMMON_CARD_ID: String = "find_familiar_card"
const FAMILIAR_ATTACK_SWOOP_DURATION: float = 0.34
const FAMILIAR_ATTACK_SWOOP_DISTANCE: float = 58.0
const FAMILIAR_ATTACK_DIVE_RATIO: float = 0.34
const FAMILIAR_ATTACK_BANK_DISTANCE: float = 16.0
const SPRITE_FRAME_SIZE: Vector2i = Vector2i(100, 100)
const MELEE_IMPACT_FRAME: float = 2.0
const MELEE_ATTACK_FPS: float = 13.0
const MELEE_ATTACK_SPEED_SCALE: float = 0.82
const OVERKILL_KNOCKBACK_FORCE_PER_DAMAGE: float = 18.0
const OVERKILL_KNOCKBACK_MAX_FORCE: float = 620.0
const OVERKILL_KNOCKBACK_DURATION_PER_DAMAGE: float = 0.008
const OVERKILL_KNOCKBACK_MAX_DURATION: float = 0.34
const OVERLAY_REDRAW_INTERVAL: float = 1.0 / 30.0
const THROW_KNOCKBACK_MIN_SPEED: float = 26.0
const THROW_KNOCKBACK_DAMPING: float = 2.25

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
var network_position_initialized: bool = false
var move_steps: Array = []
var moving_between_rooms: bool = false
var transit_stage: String = ""
var enemy_role: String = TYPE_ORC
var body_color: Color = Color("ff7764")
var visual_scale_multiplier: float = 1.0
var base_move_speed: float = 60.0
var situational_speed_multiplier: float = 1.0
var recovering_slow_time_left: float = 0.0
var recovering_slow_duration: float = 0.0
var recovering_slow_move_multiplier: float = 1.0
var recovering_slow_attack_speed_multiplier: float = 1.0
var flatfooted_time_left: float = 0.0
var flatfooted_duration: float = 0.0
var flatfooted_damage_taken_multiplier: float = 1.0
var allied_aura_damage_taken_multiplier: float = 1.0
var hold_person_time_left: float = 0.0
var hold_person_duration: float = 0.0
var fear_time_left: float = 0.0
var fear_duration: float = 0.0
var fear_move_speed_multiplier: float = 1.2
var fear_source_position: Vector2 = Vector2.ZERO
var turn_undead_time_left: float = 0.0
var turn_undead_duration: float = 0.0
var turn_undead_damage_taken_multiplier: float = 1.0
var calm_emotions_time_left: float = 0.0
var calm_emotions_duration: float = 0.0
var attack_effect_left: float = 0.0
var attack_style: String = ""
var hurt_effect_left: float = 0.0
var visual_facing_left: bool = false
var death_started: bool = false
var pool_managed: bool = false
var default_collision_layer: int = 0
var default_collision_mask: int = 0
var rooted_time_left: float = 0.0
var converted_time_left: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_left: float = 0.0
var knockback_duration: float = 0.0
var knockback_bounds_enabled: bool = false
var knockback_bounds: Rect2 = Rect2()
var knockback_regions: Array = []
var throw_active: bool = false
var throw_velocity: Vector2 = Vector2.ZERO
var throw_time_left: float = 0.0
var throw_bounces_left: int = 0
var throw_bounce_damage: float = 0.0
var throw_flatfooted_duration: float = 0.0
var throw_flatfooted_move_multiplier: float = 1.0
var throw_flatfooted_attack_speed_multiplier: float = 1.0
var throw_flatfooted_damage_taken_multiplier: float = 1.0
var throw_restitution: float = 0.9
var throw_source_hero_index: int = -1
var throw_bounce_fx_color: Color = Color("c5d4df")
var familiar_swoop_time_left: float = 0.0
var familiar_swoop_direction: Vector2 = Vector2.RIGHT
var familiar_swoop_bank_sign: float = 1.0
var familiar_swoop_distance: float = FAMILIAR_ATTACK_SWOOP_DISTANCE
var familiar_swoop_target_position: Vector2 = Vector2.ZERO
var overlay_redraw_time_left: float = 0.0

func _ready() -> void:
	current_health = max_health
	base_move_speed = move_speed
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
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
	return GAME_ENEMY_DEFS.enemy_role_scale(enemy_role) * visual_scale_multiplier

func set_visual_scale_multiplier(multiplier: float) -> void:
	visual_scale_multiplier = clampf(multiplier, 0.3, 3.0)
	apply_role_visuals()
	queue_redraw()

func apply_role_visuals() -> void:
	if animated_sprite == null:
		return
	animated_sprite.visible = true
	if enemy_role == TYPE_SPIRITUAL_WEAPON:
		animated_sprite.modulate = Color(1.0, 0.94, 0.68, 0.98)
	else:
		animated_sprite.modulate = Color.WHITE.lerp(body_color, 0.16)
	animated_sprite.scale = Vector2.ONE * role_scale()

func should_reduce_animations() -> bool:
	var host: Node = get_parent()
	while host != null:
		if host.has_method("animations_reduced_mode_active"):
			return bool(host.call("animations_reduced_mode_active"))
		host = host.get_parent()
	return false

func is_find_familiar_summon() -> bool:
	if not bool(get_meta("temporary_summon", false)):
		return false
	var summon_card_id: String = String(get_meta("summon_card_id", ""))
	return summon_card_id == FAMILIAR_SUMMON_CARD_ID

func start_familiar_attack_swoop(target_position: Vector2) -> void:
	if not is_find_familiar_summon():
		return
	var anchor_position: Vector2 = Vector2(get_meta("summon_anchor_position", global_position))
	familiar_swoop_target_position = target_position
	var target_distance: float = anchor_position.distance_to(target_position)
	var melee_contact_padding: float = 0.0
	var next_direction: Vector2 = (target_position - anchor_position).normalized()
	if next_direction == Vector2.ZERO:
		next_direction = Vector2.LEFT if visual_facing_left else Vector2.RIGHT
	familiar_swoop_direction = next_direction
	familiar_swoop_bank_sign = -1.0 if randf() < 0.5 else 1.0
	familiar_swoop_distance = clampf(maxf(target_distance - melee_contact_padding, 18.0), 18.0, 280.0)
	familiar_swoop_time_left = FAMILIAR_ATTACK_SWOOP_DURATION

func familiar_swoop_world_position(anchor_position: Vector2) -> Vector2:
	if familiar_swoop_time_left <= 0.0:
		return anchor_position
	var normalized_time: float = clampf(1.0 - (familiar_swoop_time_left / FAMILIAR_ATTACK_SWOOP_DURATION), 0.0, 1.0)
	var dive_ratio: float = clampf(FAMILIAR_ATTACK_DIVE_RATIO, 0.12, 0.88)
	var target_position: Vector2 = familiar_swoop_target_position
	if target_position == Vector2.ZERO:
		target_position = anchor_position + familiar_swoop_direction * familiar_swoop_distance
	var bank_vector: Vector2 = Vector2.ZERO
	if normalized_time <= dive_ratio:
		var dive_t: float = clampf(normalized_time / maxf(dive_ratio, 0.001), 0.0, 1.0)
		var dive_progress: float = 1.0 - pow(1.0 - dive_t, 3.0)
		bank_vector = familiar_swoop_direction.orthogonal() * (FAMILIAR_ATTACK_BANK_DISTANCE * sin(dive_t * PI) * familiar_swoop_bank_sign)
		return anchor_position.lerp(target_position, dive_progress) + bank_vector
	else:
		var return_t: float = clampf((normalized_time - dive_ratio) / maxf(1.0 - dive_ratio, 0.001), 0.0, 1.0)
		var return_progress: float = pow(return_t, 1.8)
		bank_vector = familiar_swoop_direction.orthogonal() * (FAMILIAR_ATTACK_BANK_DISTANCE * 0.75 * sin(return_t * PI) * -familiar_swoop_bank_sign)
		return target_position.lerp(anchor_position, return_progress) + bank_vector

func desired_sprite_animation(move_offset: Vector2) -> String:
	if death_started:
		return "death"
	if hurt_effect_left > 0.0:
		return "hurt"
	if attack_effect_left > 0.0:
		return attack_animation_name()
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
	if should_reduce_animations() and animation_name != "death":
		if animated_sprite.animation != animation_name:
			animated_sprite.animation = animation_name
		animated_sprite.speed_scale = 1.0
		animated_sprite.stop()
		animated_sprite.frame = 0
		return
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play()
	animated_sprite.speed_scale = animation_speed_scale_for(animation_name)

func effective_move_speed() -> float:
	if is_calm_emotions_neutralized():
		return 0.0
	if rooted_time_left > 0.0:
		return 0.0
	var resolved_speed: float = move_speed * situational_speed_multiplier * current_recovering_slow_move_multiplier()
	if fear_time_left > 0.0:
		resolved_speed *= maxf(fear_move_speed_multiplier, 1.0)
	return resolved_speed

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

func flatfooted_strength() -> float:
	return GAME_STATUS_EFFECTS.flatfooted_strength(flatfooted_time_left, flatfooted_duration)

func current_flatfooted_damage_taken_multiplier() -> float:
	var flatfooted_multiplier: float = GAME_STATUS_EFFECTS.flatfooted_damage_taken_multiplier(flatfooted_time_left, flatfooted_duration, flatfooted_damage_taken_multiplier)
	var turned_multiplier: float = lerpf(1.0, turn_undead_damage_taken_multiplier, turn_undead_strength())
	return maxf(flatfooted_multiplier, turned_multiplier)

func current_damage_taken_multiplier() -> float:
	return current_flatfooted_damage_taken_multiplier() * allied_aura_damage_taken_multiplier

func clear_allied_defence_aura() -> void:
	allied_aura_damage_taken_multiplier = 1.0

func apply_allied_defence_aura(damage_taken_multiplier: float) -> void:
	if death_started:
		return
	allied_aura_damage_taken_multiplier = minf(allied_aura_damage_taken_multiplier, clampf(damage_taken_multiplier, 0.1, 1.0))

func has_active_status_effect() -> bool:
	return recovering_slow_time_left > 0.0 \
		or flatfooted_time_left > 0.0 \
		or hold_person_time_left > 0.0 \
		or fear_time_left > 0.0 \
		or turn_undead_time_left > 0.0 \
		or calm_emotions_time_left > 0.0 \
		or rooted_time_left > 0.0 \
		or converted_time_left > 0.0

func is_flatfooted() -> bool:
	return flatfooted_time_left > 0.0 and not death_started

func apply_flatfooted_debuff(duration: float, move_multiplier: float, attack_speed_multiplier: float, damage_taken_multiplier: float = 1.5) -> void:
	if duration <= 0.0 or death_started:
		return
	apply_recovering_slow_debuff(duration, move_multiplier, attack_speed_multiplier)
	var flatfooted_state: Dictionary = GAME_STATUS_EFFECTS.refresh_flatfooted_state(flatfooted_time_left, flatfooted_duration, flatfooted_damage_taken_multiplier, duration, damage_taken_multiplier)
	flatfooted_time_left = float(flatfooted_state["time_left"])
	flatfooted_duration = float(flatfooted_state["duration"])
	flatfooted_damage_taken_multiplier = float(flatfooted_state["damage_taken_multiplier"])
	queue_redraw()

func hold_person_strength() -> float:
	if hold_person_time_left <= 0.0 or hold_person_duration <= 0.0:
		return 0.0
	return clampf(hold_person_time_left / hold_person_duration, 0.0, 1.0)

func is_held_person() -> bool:
	return hold_person_time_left > 0.0 and not death_started

func apply_hold_person_debuff(duration: float) -> void:
	if duration <= 0.0 or death_started:
		return
	hold_person_duration = maxf(hold_person_duration, duration)
	hold_person_time_left = maxf(hold_person_time_left, duration)
	apply_root(duration)
	apply_recovering_slow_debuff(duration, 0.0, 0.0)
	queue_redraw()

func fear_strength() -> float:
	if fear_time_left <= 0.0 or fear_duration <= 0.0:
		return 0.0
	return clampf(fear_time_left / fear_duration, 0.0, 1.0)

func turn_undead_strength() -> float:
	if turn_undead_time_left <= 0.0 or turn_undead_duration <= 0.0:
		return 0.0
	return clampf(turn_undead_time_left / turn_undead_duration, 0.0, 1.0)

func is_feared() -> bool:
	return fear_time_left > 0.0 and not death_started

func fear_origin_position() -> Vector2:
	return fear_source_position

func apply_fear_debuff(duration: float, source_position: Vector2, move_speed_multiplier: float = 1.2) -> void:
	if duration <= 0.0 or death_started:
		return
	fear_duration = maxf(fear_duration, duration)
	fear_time_left = maxf(fear_time_left, duration)
	fear_move_speed_multiplier = maxf(fear_move_speed_multiplier, move_speed_multiplier)
	fear_source_position = source_position
	queue_redraw()

func apply_turn_undead_debuff(duration: float, source_position: Vector2, move_speed_multiplier: float = 1.2, damage_taken_multiplier: float = 2.0) -> void:
	if duration <= 0.0 or death_started:
		return
	apply_fear_debuff(duration, source_position, move_speed_multiplier)
	turn_undead_duration = maxf(turn_undead_duration, duration)
	turn_undead_time_left = maxf(turn_undead_time_left, duration)
	turn_undead_damage_taken_multiplier = maxf(turn_undead_damage_taken_multiplier, clampf(damage_taken_multiplier, 1.0, 4.0))
	queue_redraw()

func clear_turn_undead_debuff(clear_fear: bool = false) -> void:
	if turn_undead_time_left <= 0.0 and turn_undead_duration <= 0.0:
		return
	var previous_turn_time_left: float = turn_undead_time_left
	turn_undead_time_left = 0.0
	turn_undead_duration = 0.0
	turn_undead_damage_taken_multiplier = 1.0
	if clear_fear and fear_time_left <= previous_turn_time_left + 0.05:
		fear_time_left = 0.0
		fear_duration = 0.0
		fear_move_speed_multiplier = 1.2
	queue_redraw()

func is_calm_emotions_neutralized() -> bool:
	return calm_emotions_time_left > 0.0 and not death_started

func apply_calm_emotions(duration: float) -> void:
	if duration <= 0.0 or death_started:
		return
	calm_emotions_duration = maxf(calm_emotions_duration, duration)
	calm_emotions_time_left = maxf(calm_emotions_time_left, duration)
	velocity = Vector2.ZERO
	move_steps.clear()
	queue_redraw()

func clear_calm_emotions() -> void:
	if calm_emotions_time_left <= 0.0 and calm_emotions_duration <= 0.0:
		return
	calm_emotions_time_left = 0.0
	calm_emotions_duration = 0.0
	queue_redraw()

func set_situational_speed_multiplier(multiplier: float) -> void:
	situational_speed_multiplier = clampf(multiplier, 0.15, 2.5)

func apply_root(duration: float) -> void:
	if duration <= 0.0 or death_started:
		return
	rooted_time_left = maxf(rooted_time_left, duration)
	velocity = Vector2.ZERO
	queue_redraw()

func apply_conversion(duration: float) -> void:
	if duration <= 0.0 or death_started:
		return
	converted_time_left = maxf(converted_time_left, duration)
	queue_redraw()

func is_converted() -> bool:
	return converted_time_left > 0.0 and not death_started

func set_destination(world_position: Vector2) -> void:
	if death_started:
		return
	destination = world_position

func overlay_redraw_interval() -> float:
	return OVERLAY_REDRAW_INTERVAL

func has_dynamic_overlay_visuals() -> bool:
	if throw_active:
		return true
	if enemy_role == "warlock" and not is_converted():
		return true
	if enemy_role == TYPE_DEATH_KNIGHT and not has_active_status_effect():
		return true
	if enemy_role == TYPE_SPIRITUAL_WEAPON or bool(get_meta("temporary_summon", false)):
		return true
	if hold_person_time_left > 0.0:
		return true
	if fear_time_left > 0.0:
		return true
	if rooted_time_left > 0.0:
		return true
	if recovering_slow_time_left > 0.0:
		return true
	if flatfooted_time_left > 0.0:
		return true
	if converted_time_left > 0.0:
		return true
	return false

func advance_overlay_redraw(delta: float, had_dynamic_before: bool) -> void:
	var has_dynamic_now: bool = has_dynamic_overlay_visuals()
	if not has_dynamic_now:
		overlay_redraw_time_left = 0.0
		if had_dynamic_before:
			queue_redraw()
		return
	overlay_redraw_time_left = maxf(overlay_redraw_time_left - delta, 0.0)
	if overlay_redraw_time_left <= 0.0:
		overlay_redraw_time_left = overlay_redraw_interval()
		queue_redraw()

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

func clear_throw_state() -> void:
	throw_active = false
	throw_velocity = Vector2.ZERO
	throw_time_left = 0.0
	throw_bounces_left = 0
	throw_bounce_damage = 0.0
	throw_flatfooted_duration = 0.0
	throw_flatfooted_move_multiplier = 1.0
	throw_flatfooted_attack_speed_multiplier = 1.0
	throw_flatfooted_damage_taken_multiplier = 1.0
	throw_restitution = 0.9
	throw_source_hero_index = -1
	throw_bounce_fx_color = Color("c5d4df")

func begin_physics_throw(launch_velocity: Vector2, duration: float, bounds: Rect2, walkable_regions: Array = [], max_wall_bounces: int = 0, wall_hit_damage: float = 0.0, flatfooted_duration_seconds: float = 0.0, flatfooted_move_multiplier_value: float = 1.0, flatfooted_attack_speed_multiplier_value: float = 1.0, flatfooted_damage_taken_multiplier_value: float = 1.5, source_hero_index: int = -1, bounce_effect_color: Color = Color("c5d4df")) -> void:
	if death_started or duration <= 0.0 or launch_velocity.length() <= 0.001:
		return
	move_steps.clear()
	moving_between_rooms = false
	pending_room = INVALID_ROOM
	destination = global_position
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	knockback_time_left = 0.0
	knockback_duration = 0.0
	knockback_bounds = bounds
	knockback_bounds_enabled = bounds.size.x > 0.0 and bounds.size.y > 0.0
	knockback_regions = walkable_regions.duplicate(true) if not walkable_regions.is_empty() else []
	throw_active = true
	throw_velocity = launch_velocity
	throw_time_left = duration
	throw_bounces_left = maxi(max_wall_bounces, 0)
	throw_bounce_damage = 0.0
	throw_flatfooted_duration = maxf(flatfooted_duration_seconds, 0.0)
	throw_flatfooted_move_multiplier = clampf(flatfooted_move_multiplier_value, 0.0, 1.0)
	throw_flatfooted_attack_speed_multiplier = clampf(flatfooted_attack_speed_multiplier_value, 0.0, 1.0)
	throw_flatfooted_damage_taken_multiplier = maxf(flatfooted_damage_taken_multiplier_value, 1.0)
	throw_restitution = clampf(0.86 + minf(float(throw_bounces_left), 2.0) * 0.05, 0.86, 0.96)
	throw_source_hero_index = source_hero_index
	throw_bounce_fx_color = bounce_effect_color
	queue_redraw()

func apply_throw_wall_hit(wall_normal: Vector2) -> void:
	var hit_direction: Vector2 = -wall_normal if wall_normal != Vector2.ZERO else throw_velocity.normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = Vector2.RIGHT
	if throw_flatfooted_duration > 0.0:
		apply_flatfooted_debuff(throw_flatfooted_duration, throw_flatfooted_move_multiplier, throw_flatfooted_attack_speed_multiplier, throw_flatfooted_damage_taken_multiplier)

func advance_thrown_motion(delta: float, had_dynamic_overlay_before: bool) -> bool:
	if not throw_active:
		return false
	if throw_time_left <= 0.0 or throw_velocity.length() <= THROW_KNOCKBACK_MIN_SPEED:
		clear_throw_state()
		return false
	var next_position: Vector2 = global_position + throw_velocity * delta
	var bounced: bool = false
	var wall_normal: Vector2 = Vector2.ZERO
	if knockback_bounds_enabled:
		if next_position.x <= knockback_bounds.position.x and throw_velocity.x < 0.0:
			next_position.x = knockback_bounds.position.x
			throw_velocity.x = absf(throw_velocity.x) * throw_restitution
			wall_normal.x = 1.0
			bounced = true
		elif next_position.x >= knockback_bounds.end.x and throw_velocity.x > 0.0:
			next_position.x = knockback_bounds.end.x
			throw_velocity.x = -absf(throw_velocity.x) * throw_restitution
			wall_normal.x = -1.0
			bounced = true
		if next_position.y <= knockback_bounds.position.y and throw_velocity.y < 0.0:
			next_position.y = knockback_bounds.position.y
			throw_velocity.y = absf(throw_velocity.y) * throw_restitution
			wall_normal.y = 1.0
			bounced = true
		elif next_position.y >= knockback_bounds.end.y and throw_velocity.y > 0.0:
			next_position.y = knockback_bounds.end.y
			throw_velocity.y = -absf(throw_velocity.y) * throw_restitution
			wall_normal.y = -1.0
			bounced = true
	global_position = next_position
	if bounced:
		if throw_bounces_left <= 0:
			clear_throw_state()
			velocity = Vector2.ZERO
			advance_overlay_redraw(delta, had_dynamic_overlay_before)
			return true
		apply_throw_wall_hit(wall_normal.normalized())
		throw_bounces_left -= 1
		if throw_bounces_left <= 0:
			clear_throw_state()
			velocity = Vector2.ZERO
			advance_overlay_redraw(delta, had_dynamic_overlay_before)
			return true
		var nudge_direction: Vector2 = throw_velocity.normalized()
		if nudge_direction != Vector2.ZERO:
			global_position += nudge_direction * 0.6
		clamp_to_knockback_bounds()
	var drag_factor: float = clampf(delta * THROW_KNOCKBACK_DAMPING, 0.0, 1.0)
	throw_velocity = throw_velocity.lerp(Vector2.ZERO, drag_factor)
	throw_time_left = maxf(throw_time_left - delta, 0.0)
	if throw_time_left <= 0.0 or throw_velocity.length() <= THROW_KNOCKBACK_MIN_SPEED:
		clear_throw_state()
	velocity = throw_velocity if throw_active else Vector2.ZERO
	destination = global_position
	move_steps.clear()
	if animated_sprite != null:
		animated_sprite.position = Vector2.ZERO
	update_sprite_state(velocity)
	advance_overlay_redraw(delta, had_dynamic_overlay_before)
	return true

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

func attack_animation_name() -> String:
	var styled_animation: String = "attack_%s" % attack_style
	if attack_style != "" and animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(styled_animation):
		return styled_animation
	return "attack"

func trigger_attack(target_position: Vector2, style: String = "") -> void:
	if death_started:
		return
	start_familiar_attack_swoop(target_position)
	destination = target_position if global_position.distance_to(target_position) <= 48.0 else destination
	attack_style = style
	attack_effect_left = maxf(attack_effect_left, animation_duration(attack_animation_name(), 0.32))
	update_visual_facing(target_position - global_position)
	update_sprite_state(destination - global_position)

func set_pool_managed(enabled: bool) -> void:
	pool_managed = enabled

func deactivate_for_pool() -> void:
	death_started = false
	attack_effect_left = 0.0
	hurt_effect_left = 0.0
	rooted_time_left = 0.0
	converted_time_left = 0.0
	recovering_slow_time_left = 0.0
	recovering_slow_duration = 0.0
	recovering_slow_move_multiplier = 1.0
	recovering_slow_attack_speed_multiplier = 1.0
	flatfooted_time_left = 0.0
	flatfooted_duration = 0.0
	flatfooted_damage_taken_multiplier = 1.0
	allied_aura_damage_taken_multiplier = 1.0
	hold_person_time_left = 0.0
	hold_person_duration = 0.0
	fear_time_left = 0.0
	fear_duration = 0.0
	fear_move_speed_multiplier = 1.2
	fear_source_position = Vector2.ZERO
	turn_undead_time_left = 0.0
	turn_undead_duration = 0.0
	turn_undead_damage_taken_multiplier = 1.0
	calm_emotions_time_left = 0.0
	calm_emotions_duration = 0.0
	knockback_velocity = Vector2.ZERO
	knockback_time_left = 0.0
	knockback_duration = 0.0
	knockback_bounds_enabled = false
	knockback_regions.clear()
	clear_throw_state()
	familiar_swoop_time_left = 0.0
	familiar_swoop_direction = Vector2.RIGHT
	familiar_swoop_bank_sign = 1.0
	familiar_swoop_distance = FAMILIAR_ATTACK_SWOOP_DISTANCE
	familiar_swoop_target_position = Vector2.ZERO
	move_steps.clear()
	moving_between_rooms = false
	transit_stage = ""
	pending_room = INVALID_ROOM
	current_room = INVALID_ROOM
	previous_room = INVALID_ROOM
	next_room = INVALID_ROOM
	enemy_uid = -1
	velocity = Vector2.ZERO
	destination = global_position
	current_health = max_health
	attack_cooldown_left = 0.0
	if collision_shape != null:
		collision_shape.disabled = true
	collision_layer = 0
	collision_mask = 0
	if animated_sprite != null:
		animated_sprite.stop()
		animated_sprite.animation = "idle"
		animated_sprite.frame = 0
		animated_sprite.position = Vector2.ZERO
	set_physics_process(false)
	visible = false
	queue_redraw()

func activate_from_pool(next_enemy_uid: int, role_name: String, room_coord: Vector2i, spawn_position: Vector2) -> void:
	if default_collision_layer == 0 and default_collision_mask == 0:
		default_collision_layer = 1
		default_collision_mask = 1
	for meta_key_variant in get_meta_list():
		remove_meta(meta_key_variant)
	death_started = false
	visible = true
	set_physics_process(true)
	if collision_shape != null:
		collision_shape.disabled = false
	collision_layer = default_collision_layer
	collision_mask = default_collision_mask
	enemy_uid = next_enemy_uid
	global_position = spawn_position
	reset_physics_interpolation()
	set_role(role_name)
	current_room = room_coord
	previous_room = room_coord
	next_room = room_coord
	pending_room = INVALID_ROOM
	moving_between_rooms = false
	transit_stage = ""
	move_steps.clear()
	velocity = Vector2.ZERO
	set_destination(spawn_position)
	familiar_swoop_time_left = 0.0
	familiar_swoop_direction = Vector2.RIGHT
	familiar_swoop_bank_sign = 1.0
	familiar_swoop_distance = FAMILIAR_ATTACK_SWOOP_DISTANCE
	familiar_swoop_target_position = Vector2.ZERO
	if animated_sprite != null:
		animated_sprite.speed_scale = 1.0
		animated_sprite.position = Vector2.ZERO
		animated_sprite.play("idle")
	queue_redraw()

func ready_for_pool_recycle() -> bool:
	if not pool_managed or not death_started:
		return false
	if animated_sprite == null:
		return true
	return animated_sprite.animation == "death" and not animated_sprite.is_playing()

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
	if not throw_active:
		clear_throw_state()
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
		if throw_active:
			return
		if pool_managed:
			set_physics_process(false)
		else:
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
	var attack_damage_override: float = maxf(float(role_def.get("attack_damage_override", 0.0)), 0.0)
	attack_damage = attack_damage_override if attack_damage_override > 0.0 else float(role_def.get("attack_damage", 10.0))
	attack_cooldown = maxf(float(role_def.get("attack_cooldown", 1.0)), 0.05)
	attack_range = float(role_def.get("attack_range", 70.0))
	weight = float(role_def.get("weight", 1.28))
	body_color = role_def.get("body_color", Color("7fad5b"))
	visual_scale_multiplier = clampf(float(get_meta("summon_visual_scale_multiplier", 1.0)), 0.3, 3.0)
	base_move_speed = move_speed
	situational_speed_multiplier = 1.0
	recovering_slow_time_left = 0.0
	recovering_slow_duration = 0.0
	recovering_slow_move_multiplier = 1.0
	recovering_slow_attack_speed_multiplier = 1.0
	flatfooted_time_left = 0.0
	flatfooted_duration = 0.0
	flatfooted_damage_taken_multiplier = 1.0
	allied_aura_damage_taken_multiplier = 1.0
	hold_person_time_left = 0.0
	hold_person_duration = 0.0
	fear_time_left = 0.0
	fear_duration = 0.0
	fear_move_speed_multiplier = 1.2
	fear_source_position = Vector2.ZERO
	turn_undead_time_left = 0.0
	turn_undead_duration = 0.0
	turn_undead_damage_taken_multiplier = 1.0
	calm_emotions_time_left = 0.0
	calm_emotions_duration = 0.0
	converted_time_left = 0.0
	clear_throw_state()
	current_health = max_health
	if collision_shape != null:
		collision_shape.disabled = enemy_role == TYPE_SPIRITUAL_WEAPON
	if enemy_role == TYPE_SPIRITUAL_WEAPON:
		collision_layer = 0
		collision_mask = 0
	else:
		collision_layer = default_collision_layer
		collision_mask = default_collision_mask
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
	if enemy_role == TYPE_SPIRITUAL_WEAPON:
		return false
	var applied_damage: float = maxf(amount, 0.0) * current_damage_taken_multiplier()
	var health_before: float = current_health
	current_health = maxf(current_health - applied_damage, 0.0)
	if applied_damage > 0.0 and turn_undead_time_left > 0.0:
		clear_turn_undead_debuff(true)
	clear_calm_emotions()
	hurt_effect_left = maxf(hurt_effect_left, 0.22)
	if enemy_role == TYPE_SLIME \
	and not bool(get_meta("slime_has_split", false)) \
	and health_before > max_health * 0.5 \
	and current_health > 0.0 \
	and current_health <= max_health * 0.5:
		set_meta("slime_split_pending", true)
		set_meta("slime_split_health", current_health)
	if current_health <= 0.0:
		begin_death()
		var overkill_damage: float = maxf(applied_damage - health_before, 0.0)
		apply_overkill_knockback(overkill_damage, hit_direction)
		return true
	queue_redraw()
	return false

func _physics_process(delta: float) -> void:
	var had_dynamic_overlay_before: bool = has_dynamic_overlay_visuals()
	if death_started:
		if throw_active:
			advance_thrown_motion(delta, had_dynamic_overlay_before)
			if not throw_active:
				if pool_managed:
					set_physics_process(false)
				else:
					queue_free()
				return
		else:
			var corpse_impulse: Vector2 = advance_knockback(delta)
			velocity = corpse_impulse
			move_and_slide()
			clamp_to_knockback_bounds()
		if animated_sprite != null and animated_sprite.animation != "death":
			animated_sprite.speed_scale = 1.0
			animated_sprite.play("death")
		advance_overlay_redraw(delta, had_dynamic_overlay_before)
		return
	attack_effect_left = maxf(attack_effect_left - delta, 0.0)
	hurt_effect_left = maxf(hurt_effect_left - delta, 0.0)
	rooted_time_left = maxf(rooted_time_left - delta, 0.0)
	converted_time_left = maxf(converted_time_left - delta, 0.0)
	recovering_slow_time_left = maxf(recovering_slow_time_left - delta, 0.0)
	var flatfooted_state: Dictionary = GAME_STATUS_EFFECTS.advance_flatfooted_state(flatfooted_time_left, flatfooted_duration, flatfooted_damage_taken_multiplier, delta)
	flatfooted_time_left = float(flatfooted_state["time_left"])
	flatfooted_duration = float(flatfooted_state["duration"])
	flatfooted_damage_taken_multiplier = float(flatfooted_state["damage_taken_multiplier"])
	hold_person_time_left = maxf(hold_person_time_left - delta, 0.0)
	fear_time_left = maxf(fear_time_left - delta, 0.0)
	turn_undead_time_left = maxf(turn_undead_time_left - delta, 0.0)
	calm_emotions_time_left = maxf(calm_emotions_time_left - delta, 0.0)
	familiar_swoop_time_left = maxf(familiar_swoop_time_left - delta, 0.0)
	if advance_thrown_motion(delta, had_dynamic_overlay_before):
		return
	if is_find_familiar_summon() and knockback_time_left <= 0.0:
		var familiar_anchor: Vector2 = Vector2(get_meta("summon_anchor_position", global_position))
		destination = familiar_anchor
		global_position = familiar_swoop_world_position(familiar_anchor)
		velocity = Vector2.ZERO
		if animated_sprite != null:
			animated_sprite.position = Vector2.ZERO
		var facing_offset: Vector2 = familiar_swoop_direction if familiar_swoop_time_left > 0.0 else Vector2.ZERO
		update_sprite_state(facing_offset)
		advance_overlay_redraw(delta, had_dynamic_overlay_before)
		return
	if recovering_slow_time_left <= 0.0 and recovering_slow_duration > 0.0:
		recovering_slow_duration = 0.0
		recovering_slow_move_multiplier = 1.0
		recovering_slow_attack_speed_multiplier = 1.0
	if hold_person_time_left <= 0.0 and hold_person_duration > 0.0:
		hold_person_duration = 0.0
	if fear_time_left <= 0.0 and fear_duration > 0.0:
		fear_duration = 0.0
		fear_move_speed_multiplier = 1.2
	if turn_undead_time_left <= 0.0 and turn_undead_duration > 0.0:
		turn_undead_duration = 0.0
		turn_undead_damage_taken_multiplier = 1.0
	if calm_emotions_time_left <= 0.0 and calm_emotions_duration > 0.0:
		calm_emotions_duration = 0.0
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
	if animated_sprite != null:
		animated_sprite.position = Vector2.ZERO
	update_sprite_state(offset if offset.length() > 0.0 else knockback_impulse)
	advance_overlay_redraw(delta, had_dynamic_overlay_before)

func summon_particle_primary_color() -> Color:
	if has_meta("summon_particle_primary_color"):
		return Color(get_meta("summon_particle_primary_color", Color("ffd26a")))
	if enemy_role == TYPE_SPIRITUAL_WEAPON:
		return Color("ffd26a")
	if is_find_familiar_summon():
		return Color("b289ff")
	return Color("7de8c0")

func summon_particle_secondary_color() -> Color:
	if has_meta("summon_particle_secondary_color"):
		return Color(get_meta("summon_particle_secondary_color", Color("fff2be")))
	if enemy_role == TYPE_SPIRITUAL_WEAPON:
		return Color("fff2be")
	if is_find_familiar_summon():
		return Color("ead8ff")
	return Color("d8fff0")

func draw_summon_particles(primary_color: Color, secondary_color: Color) -> void:
	var time_seconds: float = float(Time.get_ticks_msec()) / 1000.0
	for particle_index in range(18):
		var seed: float = float(particle_index)
		var orbit_angle: float = time_seconds * (2.6 + 0.14 * seed) + seed * 2.13
		var radius: float = 13.0 + 7.0 * (0.5 + 0.5 * sin(time_seconds * 3.1 + seed * 1.91))
		var particle_position: Vector2 = Vector2(cos(orbit_angle), sin(orbit_angle)) * radius
		particle_position.y *= 0.7
		var pulse: float = 0.45 + 0.55 * sin(time_seconds * 6.4 + seed * 1.37)
		var particle_size: float = 0.9 + pulse * 2.0
		var particle_color: Color = Color(primary_color.r, primary_color.g, primary_color.b, 0.24 + pulse * 0.5)
		draw_circle(particle_position, particle_size, particle_color)
	for streak_index in range(6):
		var streak_seed: float = float(streak_index)
		var streak_angle: float = time_seconds * 2.2 + streak_seed * (TAU / 6.0)
		var streak_center: Vector2 = Vector2(cos(streak_angle), sin(streak_angle)) * 16.0
		streak_center.y *= 0.76
		var tangent: Vector2 = Vector2(-sin(streak_angle), cos(streak_angle))
		var half_length: float = 3.8 + 1.6 * sin(time_seconds * 5.6 + streak_seed * 0.8)
		draw_line(
			streak_center - tangent * half_length,
			streak_center + tangent * half_length,
			Color(secondary_color.r, secondary_color.g, secondary_color.b, 0.62),
			1.4,
			true
		)

func _draw() -> void:
	var has_summon_particles: bool = enemy_role == TYPE_SPIRITUAL_WEAPON or bool(get_meta("temporary_summon", false))
	var reduced_animations: bool = should_reduce_animations()
	if enemy_role != TYPE_SPIRITUAL_WEAPON:
		var health_ratio: float = clampf(current_health / maxf(max_health, 0.001), 0.0, 1.0)
		draw_rect(Rect2(Vector2(-18.0, -31.0), Vector2(36.0, 4.0)), Color(0.08, 0.1, 0.11, 0.9), true)
		draw_rect(Rect2(Vector2(-18.0, -31.0), Vector2(36.0 * health_ratio, 4.0)), Color(0.98, 0.48, 0.42, 0.95), true)
	if enemy_role == "warlock" and not is_converted():
		var aura_pulse: float = 0.5 if reduced_animations else 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
		var aura_radius: float = 132.0 + aura_pulse * 4.0
		draw_circle(Vector2.ZERO, aura_radius, Color(0.66, 0.34, 0.96, 0.035 + aura_pulse * 0.025))
		draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 56, Color(0.78, 0.5, 1.0, 0.34 + aura_pulse * 0.16), 1.6, true)
	if enemy_role == TYPE_DEATH_KNIGHT and not has_active_status_effect():
		var defence_pulse: float = 0.5 if reduced_animations else 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.005)
		var defence_radius: float = 150.0 + defence_pulse * 4.0
		draw_circle(Vector2.ZERO, defence_radius, Color(0.38, 0.66, 0.92, 0.035 + defence_pulse * 0.025))
		draw_arc(Vector2.ZERO, defence_radius, 0.0, TAU, 56, Color(0.54, 0.78, 1.0, 0.32 + defence_pulse * 0.16), 1.6, true)
	if has_summon_particles and not reduced_animations:
		draw_summon_particles(summon_particle_primary_color(), summon_particle_secondary_color())
	elif has_summon_particles:
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 18, Color(0.88, 0.96, 1.0, 0.55), 1.4, true)
	if rooted_time_left > 0.0:
		draw_circle(Vector2(0.0, 2.0), 22.0, Color(0.84, 0.92, 1.0, 0.08))
		draw_arc(Vector2(0.0, 2.0), 19.0, 0.0, TAU, 20, Color(0.92, 0.98, 1.0, 0.7), 1.8, true)
		draw_line(Vector2(-13.0, -8.0), Vector2(13.0, 12.0), Color(0.95, 0.98, 1.0, 0.55), 1.5, true)
		draw_line(Vector2(-13.0, 12.0), Vector2(13.0, -8.0), Color(0.95, 0.98, 1.0, 0.55), 1.5, true)
	if recovering_slow_time_left > 0.0 and rooted_time_left <= 0.0:
		draw_arc(Vector2.ZERO, 21.0, -PI * 0.5, -PI * 0.5 + TAU * recovering_slow_strength(), 18, Color(0.62, 0.8, 1.0, 0.9), 2.0, true)
	if flatfooted_time_left > 0.0:
		draw_arc(Vector2.ZERO, 25.0, PI * 0.2, PI * 1.8, 24, Color(1.0, 0.88, 0.55, 0.86), 2.2, true)
		draw_circle(Vector2.ZERO, 16.5, Color(1.0, 0.84, 0.38, 0.07 + 0.12 * flatfooted_strength()))
	if hold_person_time_left > 0.0:
		if reduced_animations:
			draw_circle(Vector2.ZERO, 21.0, Color(0.84, 0.70, 1.0, 0.16))
			draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 22, Color(0.92, 0.82, 1.0, 0.84), 2.2, true)
		else:
			var hold_ratio: float = hold_person_strength()
			var hold_time: float = float(Time.get_ticks_msec()) / 1000.0
			var hold_pulse: float = 0.5 + 0.5 * sin(hold_time * 8.4)
			var outer_radius: float = 27.0 + hold_pulse * 2.6
			var inner_radius: float = 17.5 + hold_pulse * 1.8
			draw_circle(Vector2.ZERO, 22.0 + hold_pulse * 1.8, Color(0.83, 0.68, 1.0, 0.12 + 0.16 * hold_ratio))
			draw_arc(Vector2.ZERO, outer_radius, hold_time * 2.1, hold_time * 2.1 + PI * 1.32, 30, Color(0.92, 0.82, 1.0, 0.9), 2.5, true)
			draw_arc(Vector2.ZERO, outer_radius, hold_time * -2.4 + PI, hold_time * -2.4 + PI + PI * 1.32, 30, Color(0.79, 0.63, 1.0, 0.86), 2.0, true)
			draw_arc(Vector2.ZERO, inner_radius, hold_time * 3.2 + PI * 0.1, hold_time * 3.2 + PI * 1.7, 26, Color(0.95, 0.91, 1.0, 0.76), 1.5, true)
			for sigil_index in range(8):
				var sigil_seed: float = float(sigil_index)
				var sigil_angle: float = hold_time * (2.4 + sigil_seed * 0.04) + sigil_seed * (TAU / 8.0)
				var sigil_radius: float = 19.0 + 4.0 * sin(hold_time * 4.2 + sigil_seed * 1.13)
				var sigil_position: Vector2 = Vector2(cos(sigil_angle), sin(sigil_angle)) * sigil_radius
				sigil_position.y *= 0.78
				var sigil_alpha: float = 0.34 + 0.28 * (0.5 + 0.5 * sin(hold_time * 6.8 + sigil_seed * 1.77))
				draw_circle(sigil_position, 1.6 + hold_pulse * 0.9, Color(0.96, 0.89, 1.0, sigil_alpha))
				var tangent: Vector2 = Vector2(-sin(sigil_angle), cos(sigil_angle))
				draw_line(sigil_position - tangent * 2.3, sigil_position + tangent * 2.3, Color(0.84, 0.72, 1.0, sigil_alpha * 0.7), 1.2, true)
	if fear_time_left > 0.0:
		var fear_ratio: float = fear_strength()
		draw_arc(Vector2.ZERO, 30.0, -PI * 0.85, PI * 0.85, 26, Color(0.86, 0.64, 1.0, 0.88), 2.0, true)
		draw_circle(Vector2(0.0, -18.0), 6.8 + fear_ratio * 2.2, Color(0.92, 0.75, 1.0, 0.18 + 0.18 * fear_ratio))
		draw_circle(Vector2(-12.0, -14.0), 2.6 + fear_ratio * 1.2, Color(0.94, 0.8, 1.0, 0.36 + 0.24 * fear_ratio))
		draw_circle(Vector2(12.0, -14.0), 2.6 + fear_ratio * 1.2, Color(0.94, 0.8, 1.0, 0.36 + 0.24 * fear_ratio))
	if converted_time_left > 0.0:
		var conversion_ratio: float = clampf(converted_time_left / 8.0, 0.15, 1.0)
		draw_circle(Vector2.ZERO, 19.0, Color(0.56, 1.0, 0.78, 0.08 + 0.08 * conversion_ratio))
		draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 24, Color(0.7, 1.0, 0.86, 0.78), 1.8, true)
