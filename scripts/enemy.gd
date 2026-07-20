extends CharacterBody2D
class_name DungeonEnemy

const ROLE_CRYSTAL: String = "crystal"
const ROLE_HUNTER: String = "hunter"
const ROLE_SABOTEUR: String = "saboteur"

@export var move_speed: float = 60.0
@export var max_health: float = 40.0
@export var attack_damage: float = 6.0
@export var attack_cooldown: float = 0.95

var current_health: float = 0.0
var attack_cooldown_left: float = 0.0
var enemy_uid: int = -1
var current_room: Vector2i = Vector2i.ZERO
var previous_room: Vector2i = Vector2i.ZERO
var next_room: Vector2i = Vector2i.ZERO
var destination: Vector2 = Vector2.ZERO
var moving_between_rooms: bool = false
var transit_stage: String = ""
var enemy_role: String = ROLE_CRYSTAL
var body_color: Color = Color("ff7764")

func _ready() -> void:
	current_health = max_health
	destination = global_position
	next_room = current_room
	previous_room = current_room

func set_destination(world_position: Vector2) -> void:
	destination = world_position

func set_role(role_name: String) -> void:
	enemy_role = role_name
	match enemy_role:
		ROLE_HUNTER:
			move_speed = 54.0
			max_health = 46.0
			attack_damage = 8.0
			attack_cooldown = 0.9
			body_color = Color("ff8f5b")
		ROLE_SABOTEUR:
			move_speed = 48.0
			max_health = 36.0
			attack_damage = 10.0
			attack_cooldown = 1.15
			body_color = Color("f1e48a")
		_:
			move_speed = 60.0
			max_health = 42.0
			attack_damage = 7.0
			attack_cooldown = 1.0
			body_color = Color("ff5f70")
	current_health = max_health
	queue_redraw()

func is_idle() -> bool:
	return global_position.distance_to(destination) < 6.0

func take_damage(amount: float) -> bool:
	current_health -= amount
	if current_health <= 0.0:
		queue_free()
		return true
	queue_redraw()
	return false

func _physics_process(delta: float) -> void:
	var offset: Vector2 = destination - global_position
	if offset.length() < 4.0:
		velocity = Vector2.ZERO
		global_position = destination
	else:
		var step: float = minf(move_speed * delta, offset.length())
		velocity = offset.normalized() * step / maxf(delta, 0.001)
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -16.0),
		Vector2(15.0, 10.0),
		Vector2(0.0, 16.0),
		Vector2(-15.0, 10.0),
	])
	draw_colored_polygon(points, body_color)
	draw_circle(Vector2.ZERO, 4.5, Color("2d0f11"))
	match enemy_role:
		ROLE_HUNTER:
			draw_line(Vector2(-8.0, -18.0), Vector2(8.0, -18.0), Color("fff5cc"), 3.0)
		ROLE_SABOTEUR:
			draw_circle(Vector2(0.0, -20.0), 4.0, Color("fff5cc"))
		_:
			draw_circle(Vector2(0.0, -20.0), 3.0, Color("ffdae2"))
