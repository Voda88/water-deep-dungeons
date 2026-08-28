extends RefCounted

const TYPE_ORC_RIDER: String = "orc_rider"
const TYPE_ORC: String = "orc"
const TYPE_BAT: String = "bat"
const TYPE_GOLEM: String = "golem"
const TYPE_DEMON_A: String = "demon_a"
const TYPE_DEMON_D: String = "demon_d"
const TYPE_HELLHOUND: String = "hellhound"
const TYPE_DEATH_KNIGHT: String = "death_knight"
const TYPE_SLIME: String = "slime"
const TYPE_WARLOCK: String = "warlock"
const TYPE_ARCHER_IMP: String = "archer_imp"
const TYPE_SKELETON: String = "skeleton"
const TYPE_SKELETON_ARMORED: String = "skeleton_armored"
const TYPE_SKELETON_GREATSWORD: String = "skeleton_greatsword"
const TYPE_SPIRITUAL_WEAPON: String = "spiritual_weapon"
const TYPE_WRAITH: String = "wraith"
const TYPE_ORC_SHAMAN: String = TYPE_WRAITH
const TYPE_SKELETON_ARCHER: String = "skeleton_archer"

const ENEMY_SPRITE_PROFILES := {
	TYPE_ORC: {
		"idle_path": "res://assets/characters/enemies/orc/Orc_Idle.png",
		"walk_path": "res://assets/characters/enemies/orc/Orc_Walk.png",
		"hurt_path": "res://assets/characters/enemies/orc/Orc_Hurt.png",
		"attack_path": "res://assets/characters/enemies/orc/Orc_Attack01.png",
		"death_path": "res://assets/characters/enemies/orc/Orc_Death.png",
	},
	TYPE_WRAITH: {
		"idle_path": "res://assets/characters/enemies/wraith/Necromancer_Idle.png",
		"walk_path": "res://assets/characters/enemies/wraith/Necromancer_Walk.png",
		"hurt_path": "res://assets/characters/enemies/wraith/Necromancer_Hurt.png",
		"attack_path": "res://assets/characters/enemies/wraith/Necromancer_Attack02.png",
		"death_path": "res://assets/characters/enemies/wraith/Necromancer_DEATH.png",
	},
	TYPE_BAT: {
		"idle_path": "res://assets/characters/enemies/bat/Bat_Flying.png",
		"walk_path": "res://assets/characters/enemies/bat/Bat_Flying.png",
		"hurt_path": "res://assets/characters/enemies/bat/Bat_Hurt.png",
		"attack_path": "res://assets/characters/enemies/bat/Bat_Attack01.png",
		"death_path": "res://assets/characters/enemies/bat/Bat_Death.png",
	},
	TYPE_ORC_RIDER: {
		"idle_path": "res://assets/characters/enemies/orc_rider/Armored Orc_Idle.png",
		"walk_path": "res://assets/characters/enemies/orc_rider/Armored Orc_Walk.png",
		"hurt_path": "res://assets/characters/enemies/orc_rider/Armored Orc_Hurt.png",
		"attack_path": "res://assets/characters/enemies/orc_rider/Armored Orc_Attack01.png",
		"death_path": "res://assets/characters/enemies/orc_rider/Armored Orc_Death.png",
	},
	TYPE_GOLEM: {
		"idle_path": "res://assets/characters/enemies/golem/Flame Golem_Idle.png",
		"walk_path": "res://assets/characters/enemies/golem/Flame Golem_Walk.png",
		"hurt_path": "res://assets/characters/enemies/golem/Flame Golem_Hurt.png",
		"attack_path": "res://assets/characters/enemies/golem/Flame Golem_Attack03.png",
		"death_path": "res://assets/characters/enemies/golem/Flame Golem_Death.png",
	},
	TYPE_DEMON_A: {
		"idle_path": "res://assets/characters/enemies/demon_a/Demon_A_Idle.png",
		"walk_path": "res://assets/characters/enemies/demon_a/Demon_A_Walk.png",
		"hurt_path": "res://assets/characters/enemies/demon_a/Demon_A_Hurt.png",
		"attack_path": "res://assets/characters/enemies/demon_a/Demon_A_Attack01.png",
		"death_path": "res://assets/characters/enemies/demon_a/Demon_A_Death.png",
	},
	TYPE_DEMON_D: {
		"idle_path": "res://assets/characters/enemies/demon_d/Demon_D_Idle.png",
		"walk_path": "res://assets/characters/enemies/demon_d/Demon_D_Walk.png",
		"hurt_path": "res://assets/characters/enemies/demon_d/Demon_D_Hurt.png",
		"attack_path": "res://assets/characters/enemies/demon_d/Demon_D_Attack01.png",
		"death_path": "res://assets/characters/enemies/demon_d/Demon_D_Death.png",
	},
	TYPE_HELLHOUND: {
		"idle_path": "res://assets/characters/enemies/hellhound/Hellhound_Idle.png",
		"walk_path": "res://assets/characters/enemies/hellhound/Hellhound_Walk.png",
		"hurt_path": "res://assets/characters/enemies/hellhound/Hellhound_Hurt.png",
		"attack_path": "res://assets/characters/enemies/hellhound/Hellhound_Attack01.png",
		"death_path": "res://assets/characters/enemies/hellhound/Hellhound_Death.png",
	},
	TYPE_WARLOCK: {
		"idle_path": "res://assets/characters/enemies/warlock/Warlock_Idle.png",
		"walk_path": "res://assets/characters/enemies/warlock/Warlock_Walk.png",
		"hurt_path": "res://assets/characters/enemies/warlock/Warlock_Hurt.png",
		"attack_path": "res://assets/characters/enemies/warlock/Warlock_Attack02(With magic effects).png",
		"death_path": "res://assets/characters/enemies/warlock/Warlock_Death.png",
	},
	TYPE_ARCHER_IMP: {
		"idle_path": "res://assets/characters/enemies/archer_imp/Demon_B_Idle.png",
		"walk_path": "res://assets/characters/enemies/archer_imp/Demon_B_Walk.png",
		"hurt_path": "res://assets/characters/enemies/archer_imp/Demon_B_Hurt.png",
		"attack_path": "res://assets/characters/enemies/archer_imp/Demon_B_Attack02.png",
		"death_path": "res://assets/characters/enemies/archer_imp/Demon_B_Death.png",
	},
	TYPE_SKELETON: {
		"idle_path": "res://assets/characters/enemies/skeleton/Skeleton_Idle.png",
		"walk_path": "res://assets/characters/enemies/skeleton/Skeleton_Walk.png",
		"hurt_path": "res://assets/characters/enemies/skeleton/Skeleton_Hurt.png",
		"attack_path": "res://assets/characters/enemies/skeleton/Skeleton_Attack01.png",
		"death_path": "res://assets/characters/enemies/skeleton/Skeleton_Death.png",
	},
	TYPE_SKELETON_ARMORED: {
		"idle_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Idle.png",
		"walk_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Walk.png",
		"hurt_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Hurt.png",
		"attack_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Attack01.png",
		"death_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Death.png",
	},
	TYPE_DEATH_KNIGHT: {
		"idle_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Idle.png",
		"walk_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Walk.png",
		"hurt_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Hurt.png",
		"attack_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Attack01.png",
		"death_path": "res://assets/characters/enemies/skeleton_armored/Armored Skeleton_Death.png",
	},
	TYPE_SKELETON_GREATSWORD: {
		"idle_path": "res://assets/characters/enemies/skeleton_greatsword/Greatsword Skeleton_Idle.png",
		"walk_path": "res://assets/characters/enemies/skeleton_greatsword/Greatsword Skeleton_Walk.png",
		"hurt_path": "res://assets/characters/enemies/skeleton_greatsword/Greatsword Skeleton_Hurt.png",
		"attack_path": "res://assets/characters/enemies/skeleton_greatsword/Greatsword Skeleton_Attack01.png",
		"death_path": "res://assets/characters/enemies/skeleton_greatsword/Greatsword Skeleton_Death.png",
	},
	TYPE_SPIRITUAL_WEAPON: {
		"idle_path": "res://assets/characters/enemies/spiritual_weapon/spiritual_weapon_idle.png",
		"walk_path": "res://assets/characters/enemies/spiritual_weapon/spiritual_weapon_idle.png",
		"hurt_path": "res://assets/characters/enemies/spiritual_weapon/spiritual_weapon_idle.png",
		"attack_path": "res://assets/characters/enemies/spiritual_weapon/spiritual_weapon_attack.png",
		"death_path": "res://assets/characters/enemies/spiritual_weapon/spiritual_weapon_attack.png",
	},
	TYPE_SKELETON_ARCHER: {
		"idle_path": "res://assets/characters/enemies/skeleton_archer/Skeleton Archer_Idle.png",
		"walk_path": "res://assets/characters/enemies/skeleton_archer/Skeleton Archer_Walk.png",
		"hurt_path": "res://assets/characters/enemies/skeleton_archer/Skeleton Archer_Hurt.png",
		"attack_path": "res://assets/characters/enemies/skeleton_archer/Skeleton Archer_Attack.png",
		"death_path": "res://assets/characters/enemies/skeleton_archer/Skeleton Archer_Death.png",
	},
}

static func normalize_enemy_type(enemy_type: String) -> String:
	match enemy_type:
		"lizardman":
			return TYPE_ORC_RIDER
		"goblin":
			return TYPE_ORC
		"goblin_shaman":
			return TYPE_WRAITH
		"orc_shaman":
			return TYPE_WRAITH
		"kobold":
			return TYPE_BAT
		"raider_demon":
			return TYPE_DEMON_D
	return enemy_type

static func enemy_is_undead(enemy_type: String) -> bool:
	match normalize_enemy_type(enemy_type):
		TYPE_SKELETON, TYPE_SKELETON_ARMORED, TYPE_SKELETON_GREATSWORD, TYPE_SKELETON_ARCHER, TYPE_DEATH_KNIGHT, TYPE_WRAITH:
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
		TYPE_DEATH_KNIGHT:
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
		TYPE_HELLHOUND:
			return 1.78
		TYPE_SLIME:
			return 1.42
		TYPE_WARLOCK:
			return 1.82
		TYPE_ARCHER_IMP:
			return 1.56
		TYPE_WRAITH:
			return 2.05
		_:
			return 1.92

static func enemy_role_definition(enemy_type: String) -> Dictionary:
	match normalize_enemy_type(enemy_type):
		TYPE_ORC_RIDER:
			return {
				"id": TYPE_ORC_RIDER,
				"move_speed": 110.0,
				"max_health": 135.2,
				"attack_damage": 18.0,
				"attack_cooldown": 0.5,
				"attack_range": 78.0,
				"weight": 3.35,
				"body_color": Color("8d9e67"),
				"ignore_room_opponent_slowdown": true,
			}
		TYPE_DEATH_KNIGHT:
			return {
				"id": TYPE_DEATH_KNIGHT,
				"move_speed": 110.0,
				"max_health": 135.2,
				"attack_damage": 18.0,
				"attack_cooldown": 0.5,
				"attack_range": 78.0,
				"weight": 3.35,
				"body_color": Color("8b9bb4"),
				"ally_aura_radius": 150.0,
				"ally_aura_damage_taken_multiplier": 0.72,
				"ignore_room_opponent_slowdown": true,
			}
		TYPE_BAT:
			return {
				"id": TYPE_BAT,
				"move_speed": 57.0,
				"max_health": 44.2,
				"attack_damage": 6.0,
				"attack_cooldown": 0.5,
				"attack_range": 36.0,
				"weight": 0.55,
				"body_color": Color("d0c6c0"),
			}
		TYPE_GOLEM:
			return {
				"id": TYPE_GOLEM,
				"move_speed": 33.0,
				"max_health": 96.2,
				"attack_damage": 12.0,
				"attack_cooldown": 0.575,
				"attack_range": 80.0,
				"weight": 5.4,
				"body_color": Color("8a887d"),
			}
		TYPE_DEMON_A:
			return {
				"id": TYPE_DEMON_A,
				"move_speed": 74.0,
				"max_health": 35.1,
				"attack_damage": 4.5,
				"attack_cooldown": 0.41,
				"attack_range": 76.0,
				"weight": 0.9,
				"body_color": Color("d8b7ff"),
			}
		TYPE_DEMON_D:
			return {
				"id": TYPE_DEMON_D,
				"move_speed": 64.0,
				"max_health": 119.6,
				"attack_damage": 16.0,
				"attack_cooldown": 0.475,
				"attack_range": 74.0,
				"weight": 1.65,
				"body_color": Color("d46c57"),
			}
		TYPE_HELLHOUND:
			return {
				"id": TYPE_HELLHOUND,
				"move_speed": 96.0,
				"max_health": 33.8,
				"attack_damage": 4.0,
				"attack_cooldown": 0.45,
				"attack_range": 62.0,
				"weight": 0.8,
				"body_color": Color("e89c62"),
				"hero_slow_per_hit": 0.12,
				"hero_slow_max": 0.48,
				"hero_slow_duration": 4.0,
				"hero_flatfooted_damage_taken_multiplier": 1.5,
				"ignore_room_opponent_slowdown": true,
			}
		TYPE_SLIME:
			return {
				"id": TYPE_SLIME,
				"move_speed": 42.0,
				"max_health": 52.0,
				"attack_damage": 5.0,
				"attack_cooldown": 0.7,
				"attack_range": 54.0,
				"weight": 1.2,
				"body_color": Color("69d889"),
			}
		TYPE_WARLOCK:
			return {
				"id": TYPE_WARLOCK,
				"move_speed": 42.0,
				"max_health": 39.0,
				"attack_damage": 3.0,
				"attack_cooldown": 0.6,
				"attack_range": 64.0,
				"weight": 0.85,
				"body_color": Color("b67fe8"),
				"hero_aura_radius": 132.0,
				"hero_aura_attack_damage_multiplier": 0.75,
			}
		TYPE_ARCHER_IMP:
			return {
				"id": TYPE_ARCHER_IMP,
				"move_speed": 48.0,
				"max_health": 29.9,
				"attack_damage": 4.5,
				"attack_cooldown": 0.6,
				"attack_range": 120.0,
				"weight": 0.65,
				"body_color": Color("e3a0d9"),
				"attack_delivery": "arrow",
				"attack_label": "An archer imp",
				"attack_status_template": "%s marks %s.",
				"attack_projectile_color": Color("ff956a"),
				"attack_projectile_width": 2.8,
				"attack_projectile_speed": 1060.0,
				"expose_stacks_per_hit": 1,
				"expose_max_stacks": 3,
				"expose_duration": 6.0,
			}
		TYPE_SKELETON:
			return {
				"id": TYPE_SKELETON,
				"move_speed": 50.0,
				"max_health": 54.6,
				"attack_damage": 8.0,
				"attack_cooldown": 0.5,
				"attack_range": 70.0,
				"weight": 1.1,
				"body_color": Color("d9ded5"),
			}
		TYPE_SKELETON_ARMORED:
			return {
				"id": TYPE_SKELETON_ARMORED,
				"move_speed": 36.0,
				"max_health": 124.8,
				"attack_damage": 7.0,
				"attack_cooldown": 0.6,
				"attack_range": 68.0,
				"weight": 3.8,
				"body_color": Color("a4a8b1"),
			}
		TYPE_SKELETON_GREATSWORD:
			return {
				"id": TYPE_SKELETON_GREATSWORD,
				"move_speed": 58.0,
				"max_health": 66.3,
				"attack_damage": 15.0,
				"attack_cooldown": 0.46,
				"attack_range": 76.0,
				"weight": 1.85,
				"body_color": Color("e2ddd3"),
			}
		TYPE_SPIRITUAL_WEAPON:
			return {
				"id": TYPE_SPIRITUAL_WEAPON,
				"move_speed": 84.0,
				"max_health": 36.4,
				"attack_damage": 9.0,
				"attack_damage_override": 31.0,
				"attack_cooldown": 0.44,
				"attack_range": 78.0,
				"weight": 0.4,
				"body_color": Color("ecedff"),
			}
		TYPE_WRAITH:
			return {
				"id": TYPE_WRAITH,
				"move_speed": 31.0,
				"max_health": 176.8,
				"attack_damage": 8.0,
				"attack_cooldown": 0.65,
				"attack_range": 120.0,
				"weight": 1.32,
				"body_color": Color("a16fd5"),
				"attack_delivery": "fireball",
				"attack_label": "A wraith",
				"attack_status_template": "%s hurls a mini fireball.",
				"attack_single_defeat_status_template": "%s burned down %s.",
				"attack_multiple_defeat_status": "A wraith burned down multiple heroes.",
				"attack_blast_radius": 68.0,
				"attack_blast_force": 360.0,
				"ignore_room_opponent_slowdown": true,
			}
		TYPE_SKELETON_ARCHER:
			return {
				"id": TYPE_SKELETON_ARCHER,
				"move_speed": 42.0,
				"max_health": 70.98,
				"attack_damage": 6.5,
				"attack_cooldown": 0.65,
				"attack_range": 120.0,
				"weight": 0.95,
				"body_color": Color("d7decf"),
				"attack_delivery": "laser",
				"attack_label": "A skeleton archer",
				"attack_status_template": "%s looses an arrow at %s.",
				"attack_projectile_color": Color("dbe5c8"),
				"attack_projectile_width": 3.2,
				"attack_projectile_speed": 980.0,
			}
		_:
			return {
				"id": TYPE_ORC,
				"move_speed": 48.0,
				"max_health": 44.2,
				"attack_damage": 10.0,
				"attack_cooldown": 0.5,
				"attack_range": 70.0,
				"weight": 1.28,
				"body_color": Color("7fad5b"),
			}

static func enemy_pack_size(enemy_type: String) -> int:
	match normalize_enemy_type(enemy_type):
		TYPE_ORC_RIDER:
			return 1
		TYPE_DEATH_KNIGHT:
			return 1
		TYPE_DEMON_A:
			return 1
		TYPE_HELLHOUND:
			return 2
		TYPE_SLIME:
			return 2
		TYPE_WARLOCK:
			return 1
		TYPE_ARCHER_IMP:
			return 2
		TYPE_ORC:
			return 3
		TYPE_BAT:
			return 3
		TYPE_SKELETON_ARCHER:
			return 2
		TYPE_DEMON_D:
			return 1
		TYPE_GOLEM:
			return 1
		TYPE_WRAITH:
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
		TYPE_DEATH_KNIGHT:
			return 0.55 if not pressure_spawn else 0.42
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
		TYPE_WRAITH:
			return 0.72 if not pressure_spawn else 0.54
		TYPE_HELLHOUND:
			return 1.65 if not pressure_spawn else 1.4
		TYPE_SLIME:
			return 1.0 if not pressure_spawn else 0.75
		TYPE_WARLOCK:
			return 0.75 if not pressure_spawn else 0.55
		TYPE_ARCHER_IMP:
			return 1.35 if not pressure_spawn else 1.0
		_:
			return 1.0

static func enemy_spawn_order() -> Array[String]:
	return [TYPE_ORC, TYPE_BAT, TYPE_HELLHOUND, TYPE_SLIME, TYPE_ARCHER_IMP, TYPE_SKELETON_ARCHER, TYPE_WARLOCK, TYPE_WRAITH, TYPE_ORC_RIDER, TYPE_DEATH_KNIGHT, TYPE_GOLEM, TYPE_DEMON_D]

static func enemy_dust_drop_chance(enemy_type: String) -> float:
	match normalize_enemy_type(enemy_type):
		TYPE_BAT:
			return 0.4
		TYPE_ORC:
			return 0.5
		TYPE_SKELETON_ARCHER:
			return 0.7
		TYPE_WRAITH:
			return 0.7
		TYPE_ORC_RIDER:
			return 0.9
		TYPE_DEATH_KNIGHT:
			return 0.85
		TYPE_DEMON_D:
			return 0.75
		TYPE_HELLHOUND:
			return 0.45
		TYPE_WARLOCK:
			return 0.6
		TYPE_ARCHER_IMP:
			return 0.55
		_:
			return 0.0

static func enemy_available_on_floor(enemy_type: String, floor_index: int) -> bool:
	var resolved_type: String = normalize_enemy_type(enemy_type)
	if resolved_type == TYPE_BAT:
		return floor_index <= 1
	if resolved_type == TYPE_DEMON_A:
		return false
	if resolved_type == TYPE_HELLHOUND:
		return floor_index <= 5
	if resolved_type == TYPE_SLIME:
		return floor_index >= 2
	if resolved_type == TYPE_WARLOCK:
		return floor_index >= 2
	if resolved_type == TYPE_DEATH_KNIGHT:
		return floor_index >= 3
	if resolved_type == TYPE_ARCHER_IMP:
		return floor_index >= 2
	if resolved_type == TYPE_SKELETON or resolved_type == TYPE_SKELETON_ARMORED or resolved_type == TYPE_SKELETON_GREATSWORD or resolved_type == TYPE_SPIRITUAL_WEAPON:
		return false
	if resolved_type == TYPE_GOLEM or resolved_type == TYPE_DEMON_D:
		return floor_index >= 2
	return true
