extends RefCounted

const TYPE_ORC_RIDER: String = "orc_rider"
const TYPE_ORC: String = "orc"
const TYPE_BAT: String = "bat"
const TYPE_GOLEM: String = "golem"
const TYPE_DEMON_A: String = "demon_a"
const TYPE_DEMON_D: String = "demon_d"
const TYPE_SKELETON: String = "skeleton"
const TYPE_SKELETON_ARMORED: String = "skeleton_armored"
const TYPE_SKELETON_GREATSWORD: String = "skeleton_greatsword"
const TYPE_SPIRITUAL_WEAPON: String = "spiritual_weapon"
const TYPE_ORC_SHAMAN: String = "orc_shaman"
const TYPE_SKELETON_ARCHER: String = "skeleton_archer"

const ENEMY_SPRITE_PROFILES := {
	TYPE_ORC: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Orc/Orc/Orc_Death.png",
	},
	TYPE_ORC_SHAMAN: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Necromancer/Necromancer/Necromancer_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Necromancer/Necromancer/Necromancer_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Necromancer/Necromancer/Necromancer_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Necromancer/Necromancer/Necromancer_Attack02.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Necromancer/Necromancer/Necromancer_DEATH.png",
	},
	TYPE_BAT: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Flying.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Flying.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Bat/Bat/Bat_Death.png",
	},
	TYPE_ORC_RIDER: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Orc/Armored Orc/Armored Orc_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Orc/Armored Orc/Armored Orc_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Orc/Armored Orc/Armored Orc_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Orc/Armored Orc/Armored Orc_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Orc/Armored Orc/Armored Orc_Death.png",
	},
	TYPE_GOLEM: {
		"idle_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Idle.png",
		"walk_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Attack03.png",
		"death_path": "res://assets/characters/packs/pack02/characters_split_100x100/Flame Golem/Flame Golem/Flame Golem_Death.png",
	},
	TYPE_DEMON_A: {
		"idle_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_A/Demon_A/Demon_A_Idle.png",
		"walk_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_A/Demon_A/Demon_A_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_A/Demon_A/Demon_A_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_A/Demon_A/Demon_A_Attack01.png",
		"death_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_A/Demon_A/Demon_A_Death.png",
	},
	TYPE_DEMON_D: {
		"idle_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_D/Demon_D/Demon_D_Idle.png",
		"walk_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_D/Demon_D/Demon_D_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_D/Demon_D/Demon_D_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_D/Demon_D/Demon_D_Attack01.png",
		"death_path": "res://assets/characters/packs/pack02/characters_split_100x100/Demon_D/Demon_D/Demon_D_Death.png",
	},
	TYPE_SKELETON: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton/Skeleton/Skeleton_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton/Skeleton/Skeleton_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton/Skeleton/Skeleton_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton/Skeleton/Skeleton_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton/Skeleton/Skeleton_Death.png",
	},
	TYPE_SKELETON_ARMORED: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Skeleton/Armored Skeleton/Armored Skeleton_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Skeleton/Armored Skeleton/Armored Skeleton_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Skeleton/Armored Skeleton/Armored Skeleton_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Skeleton/Armored Skeleton/Armored Skeleton_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Armored Skeleton/Armored Skeleton/Armored Skeleton_Death.png",
	},
	TYPE_SKELETON_GREATSWORD: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Greatsword Skeleton/Greatsword Skeleton/Greatsword Skeleton_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Greatsword Skeleton/Greatsword Skeleton/Greatsword Skeleton_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Greatsword Skeleton/Greatsword Skeleton/Greatsword Skeleton_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Greatsword Skeleton/Greatsword Skeleton/Greatsword Skeleton_Attack01.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Greatsword Skeleton/Greatsword Skeleton/Greatsword Skeleton_Death.png",
	},
	TYPE_SPIRITUAL_WEAPON: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/spiritual weapon/spiritual_weapon_idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/spiritual weapon/spiritual_weapon_idle.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/spiritual weapon/spiritual_weapon_idle.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/spiritual weapon/spiritual_weapon_attack.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/spiritual weapon/spiritual_weapon_attack.png",
	},
	TYPE_SKELETON_ARCHER: {
		"idle_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Idle.png",
		"walk_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Walk.png",
		"hurt_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Hurt.png",
		"attack_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Attack.png",
		"death_path": "res://assets/characters/packs/pack01/characters_split_100x100/Skeleton Archer/Skeleton Archer/Skeleton Archer_Death.png",
	},
}

static func normalize_enemy_type(enemy_type: String) -> String:
	match enemy_type:
		"lizardman":
			return TYPE_ORC_RIDER
		"goblin":
			return TYPE_ORC
		"goblin_shaman":
			return TYPE_ORC_SHAMAN
		"kobold":
			return TYPE_BAT
		"raider_demon":
			return TYPE_DEMON_D
	return enemy_type

static func enemy_is_undead(enemy_type: String) -> bool:
	match normalize_enemy_type(enemy_type):
		TYPE_SKELETON, TYPE_SKELETON_ARMORED, TYPE_SKELETON_GREATSWORD, TYPE_SKELETON_ARCHER:
			return true
		_:
			return false

static func enemy_is_mindless(enemy_type: String) -> bool:
	match normalize_enemy_type(enemy_type):
		TYPE_GOLEM, TYPE_SPIRITUAL_WEAPON:
			return true
		_:
			return enemy_is_undead(enemy_type)

static func enemy_can_be_feared(enemy_type: String) -> bool:
	return not enemy_is_mindless(enemy_type)

static func enemy_sprite_profile(enemy_type: String) -> Dictionary:
	var resolved_type: String = normalize_enemy_type(enemy_type)
	return ENEMY_SPRITE_PROFILES.get(resolved_type, ENEMY_SPRITE_PROFILES[TYPE_ORC])

static func enemy_role_scale(enemy_type: String) -> float:
	match normalize_enemy_type(enemy_type):
		TYPE_GOLEM:
			return 2.45
		TYPE_ORC_RIDER:
			return 2.15
		TYPE_SKELETON_ARMORED:
			return 2.35
		TYPE_SKELETON_GREATSWORD:
			return 2.12
		TYPE_SKELETON:
			return 1.88
		TYPE_SPIRITUAL_WEAPON:
			return 1.96
		TYPE_DEMON_A:
			return 1.96
		TYPE_BAT:
			return 1.54
		TYPE_SKELETON_ARCHER:
			return 1.88
		TYPE_DEMON_D:
			return 2.1
		TYPE_ORC_SHAMAN:
			return 2.05
		_:
			return 1.92

static func enemy_role_definition(enemy_type: String) -> Dictionary:
	match normalize_enemy_type(enemy_type):
		TYPE_ORC_RIDER:
			return {
				"id": TYPE_ORC_RIDER,
				"move_speed": 110.0,
				"max_health": 208.0,
				"attack_damage": 36.0,
				"attack_cooldown": 1.0,
				"attack_range": 78.0,
				"weight": 3.35,
				"body_color": Color("8d9e67"),
			}
		TYPE_BAT:
			return {
				"id": TYPE_BAT,
				"move_speed": 57.0,
				"max_health": 68.0,
				"attack_damage": 12.0,
				"attack_cooldown": 1.0,
				"attack_range": 36.0,
				"weight": 0.55,
				"body_color": Color("d0c6c0"),
			}
		TYPE_GOLEM:
			return {
				"id": TYPE_GOLEM,
				"move_speed": 33.0,
				"max_health": 148.0,
				"attack_damage": 24.0,
				"attack_cooldown": 1.15,
				"attack_range": 80.0,
				"weight": 5.4,
				"body_color": Color("8a887d"),
			}
		TYPE_DEMON_A:
			return {
				"id": TYPE_DEMON_A,
				"move_speed": 74.0,
				"max_health": 54.0,
				"attack_damage": 9.0,
				"attack_cooldown": 0.82,
				"attack_range": 76.0,
				"weight": 0.9,
				"body_color": Color("d8b7ff"),
			}
		TYPE_DEMON_D:
			return {
				"id": TYPE_DEMON_D,
				"move_speed": 64.0,
				"max_health": 92.0,
				"attack_damage": 16.0,
				"attack_cooldown": 0.95,
				"attack_range": 74.0,
				"weight": 1.65,
				"body_color": Color("d46c57"),
			}
		TYPE_SKELETON:
			return {
				"id": TYPE_SKELETON,
				"move_speed": 50.0,
				"max_health": 84.0,
				"attack_damage": 16.0,
				"attack_cooldown": 1.0,
				"attack_range": 70.0,
				"weight": 1.1,
				"body_color": Color("d9ded5"),
			}
		TYPE_SKELETON_ARMORED:
			return {
				"id": TYPE_SKELETON_ARMORED,
				"move_speed": 36.0,
				"max_health": 192.0,
				"attack_damage": 14.0,
				"attack_cooldown": 1.2,
				"attack_range": 68.0,
				"weight": 3.8,
				"body_color": Color("a4a8b1"),
			}
		TYPE_SKELETON_GREATSWORD:
			return {
				"id": TYPE_SKELETON_GREATSWORD,
				"move_speed": 58.0,
				"max_health": 102.0,
				"attack_damage": 30.0,
				"attack_cooldown": 0.92,
				"attack_range": 76.0,
				"weight": 1.85,
				"body_color": Color("e2ddd3"),
			}
		TYPE_SPIRITUAL_WEAPON:
			return {
				"id": TYPE_SPIRITUAL_WEAPON,
				"move_speed": 84.0,
				"max_health": 56.0,
				"attack_damage": 18.0,
				"attack_cooldown": 0.88,
				"attack_range": 78.0,
				"weight": 0.4,
				"body_color": Color("ecedff"),
			}
		TYPE_ORC_SHAMAN:
			return {
				"id": TYPE_ORC_SHAMAN,
				"move_speed": 31.0,
				"max_health": 272.0,
				"attack_damage": 16.0,
				"attack_cooldown": 1.3,
				"attack_range": 78.0,
				"weight": 1.32,
				"body_color": Color("a16fd5"),
			}
		TYPE_SKELETON_ARCHER:
			return {
				"id": TYPE_SKELETON_ARCHER,
				"move_speed": 42.0,
				"max_health": 109.2,
				"attack_damage": 13.0,
				"attack_cooldown": 1.3,
				"attack_range": 52.0,
				"weight": 0.95,
				"body_color": Color("d7decf"),
			}
		_:
			return {
				"id": TYPE_ORC,
				"move_speed": 48.0,
				"max_health": 68.0,
				"attack_damage": 20.0,
				"attack_cooldown": 1.0,
				"attack_range": 70.0,
				"weight": 1.28,
				"body_color": Color("7fad5b"),
			}

static func enemy_pack_size(enemy_type: String) -> int:
	match normalize_enemy_type(enemy_type):
		TYPE_ORC_RIDER:
			return 1
		TYPE_DEMON_A:
			return 1
		TYPE_ORC:
			return 3
		TYPE_BAT:
			return 3
		TYPE_SKELETON_ARCHER:
			return 2
		TYPE_DEMON_D:
			return 2
		TYPE_GOLEM:
			return 1
		TYPE_ORC_SHAMAN:
			return 1
		_:
			return 1

static func enemy_wave_point_cost(enemy_type: String) -> int:
	match normalize_enemy_type(enemy_type):
		TYPE_GOLEM:
			return 2
		_:
			return 1

static func enemy_spawn_weight(enemy_type: String, pressure_spawn: bool = false) -> float:
	match normalize_enemy_type(enemy_type):
		TYPE_ORC_RIDER:
			return 1.1 if not pressure_spawn else 0.9
		TYPE_ORC:
			return 3.4 if not pressure_spawn else 2.8
		TYPE_BAT:
			return 2.8 if not pressure_spawn else 3.2
		TYPE_SKELETON_ARCHER:
			return 1.4 if not pressure_spawn else 1.1
		TYPE_DEMON_D:
			return 1.35 if not pressure_spawn else 1.25
		TYPE_GOLEM:
			return 0.42 if not pressure_spawn else 0.36
		TYPE_ORC_SHAMAN:
			return 0.72 if not pressure_spawn else 0.54
		_:
			return 1.0

static func enemy_spawn_order() -> Array[String]:
	return [TYPE_ORC, TYPE_BAT, TYPE_SKELETON_ARCHER, TYPE_ORC_SHAMAN, TYPE_ORC_RIDER, TYPE_GOLEM, TYPE_DEMON_D]

static func enemy_dust_drop_chance(enemy_type: String) -> float:
	match normalize_enemy_type(enemy_type):
		TYPE_BAT:
			return 0.4
		TYPE_ORC:
			return 0.5
		TYPE_SKELETON_ARCHER:
			return 0.7
		TYPE_ORC_SHAMAN:
			return 0.7
		TYPE_ORC_RIDER:
			return 0.9
		TYPE_DEMON_D:
			return 0.75
		_:
			return 0.0

static func enemy_available_on_floor(enemy_type: String, floor_index: int) -> bool:
	var resolved_type: String = normalize_enemy_type(enemy_type)
	if resolved_type == TYPE_BAT:
		return floor_index <= 1
	if resolved_type == TYPE_DEMON_A:
		return false
	if resolved_type == TYPE_SKELETON or resolved_type == TYPE_SKELETON_ARMORED or resolved_type == TYPE_SKELETON_GREATSWORD or resolved_type == TYPE_SPIRITUAL_WEAPON:
		return false
	if resolved_type == TYPE_GOLEM or resolved_type == TYPE_DEMON_D:
		return floor_index >= 2
	return true
