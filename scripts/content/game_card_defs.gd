extends RefCounted

static func runtime_card_definition(game: Node, card_id: String) -> Dictionary:
	match card_id:
		"fireball_card":
			return {
				"id": "fireball_card",
				"name": "Fireball",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 3,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Can cast into adjacent rooms", "Blast has friendly fire", "Recharges after 3 opened rooms"],
				"stamina_cost": 2.0,
				"base_damage": 72.0,
				"impact_radius": 92.0,
				"radius": 12.0,
				"speed": 880.0,
				"cast_adjacent_hops": 1,
				"door_interval": 3,
				"color": Color("ff9a5e"),
			}
		"magic_missile_card":
			return {
				"id": "magic_missile_card",
				"name": "Magic Missile",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Launches three seeking missiles", "Recharges after 3 opened rooms from a slotted spell"],
				"stamina_cost": 1.0,
				"base_damage": 36.0,
				"projectile_count": 3,
				"adjacent_cast_anywhere": true,
				"cast_adjacent_hops": 1,
				"door_interval": 3,
				"color": Color("c18dff"),
			}
		"light_cantrip_card":
			return {
				"id": "light_cantrip_card",
				"name": "Light",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 0,
				"target_scope": "same_room",
				"phase": "out_of_combat",
				"description_lines": ["Wizard cantrip", "Lights the wizard's current room", "Light follows the wizard until recast or the floor ends"],
				"stamina_cost": 0.0,
				"color": Color("fff1a8"),
				"reusable": true,
			}
		"misty_step_card":
			return {
				"id": "misty_step_card",
				"name": "Misty Step",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "any",
				"description_lines": ["Reaction: on fatal hit, step one room toward the crystal", "Play on an adjacent room to teleport there", "Recharges after 2 opened rooms from a slotted spell"],
				"stamina_cost": 0.0,
				"cast_adjacent_hops": 0,
				"requires_adjacent_room_target": true,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"door_interval": 2,
				"color": Color("b89cff"),
			}
		"evasive_roll_card":
			return {
				"id": "evasive_roll_card",
				"name": "Evasive Roll",
				"target_scope": "opened_room",
				"phase": "combat",
				"description_lines": ["Combat only", "Roll into an adjacent opened room", "Move at 2x speed while rolling", "Immune to attacks during the roll"],
				"stamina_cost": 0.0,
				"requires_adjacent_room_target": true,
				"cast_adjacent_hops": 0,
				"door_interval": 1,
				"color": Color("9ef4df"),
			}
		"speed_dash_card":
			return {
				"id": "speed_dash_card",
				"name": "Speed Dash",
				"target_scope": "opened_room",
				"phase": "combat",
				"description_lines": ["Combat only", "Target any opened room", "Run there at 4x speed", "Keep the speed buff for 6s after arrival"],
				"stamina_cost": 0.0,
				"dash_duration": 0.2,
				"dash_speed_multiplier": 4.0,
				"dash_post_duration": 6.0,
				"door_interval": 1,
				"color": Color("8ff6df"),
			}
		"whirling_blade_card":
			return {
				"id": "whirling_blade_card",
				"name": "Whirling Blade",
				"spell_level": 2,
				"target_scope": "opened_room",
				"phase": "combat",
				"description_lines": ["Spin in your room or through one adjacent opened room", "Deals AoE damage along the path", "Knocks enemies back on hit"],
				"stamina_cost": 1.0,
				"requires_adjacent_room_target": true,
				"cast_adjacent_hops": 0,
				"base_damage": 24.0,
				"impact_radius": 54.0,
				"knockback_force": 360.0,
				"knockback_duration": 0.22,
				"travel_speed_multiplier": 2.6,
				"spin_speed": 24.0,
				"door_interval": 2,
				"color": Color("ffe08b"),
			}
		"web_card":
			return {
				"id": "web_card",
				"name": "Web",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Roots enemies in an area for 6 to 12 seconds", "Recharges after 2 opened rooms from a slotted spell"],
				"stamina_cost": 2.0,
				"impact_radius": 108.0,
				"cast_adjacent_hops": 1,
				"door_interval": 2,
				"web_duration_min": 6.0,
				"web_duration_max": 12.0,
				"color": Color("c9f0ff"),
			}
		"scry_card":
			return {
				"id": "scry_card",
				"name": "Scry",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 2,
				"target_scope": "opened_room",
				"phase": "out_of_combat",
				"description_lines": ["Target one discovered room", "Reveal adjacent unopened room contents", "Revealed rooms glow with supernatural light", "Recharges after 2 opened rooms from a slotted spell"],
				"stamina_cost": 1.0,
				"door_interval": 2,
				"color": Color("9ed7ff"),
			}
		"shield_card":
			return {
				"id": "shield_card",
				"name": "Shield",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-casts on a fatal hit", "Grants 6 seconds of immunity", "Recharges after 3 opened rooms from a slotted spell"],
				"stamina_cost": 1.0,
				"shield_amount": 0.0,
				"shield_duration": 0.0,
				"immunity_duration": 6.0,
				"auto_cast_on_fatal": true,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"door_interval": 3,
				"color": Color("9fc8ff"),
			}
		"lightning_bolt_card":
			return {
				"id": "lightning_bolt_card",
				"name": "Lightning Bolt",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 3,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Strike a bouncing line through a room", "Hits enemies, heroes, and modules", "Recharges after 3 opened rooms from a slotted spell"],
				"stamina_cost": 2.0,
				"base_damage": 72.0,
				"impact_radius": 18.0,
				"bounce_count": 2,
				"cast_adjacent_hops": 1,
				"door_interval": 3,
				"color": Color("8bd9ff"),
			}
		"scorching_ray_card":
			return {
				"id": "scorching_ray_card",
				"name": "Scorching Ray",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Fires three ghostfire rays", "Recharges after 2 opened rooms from a slotted spell"],
				"stamina_cost": 2.0,
				"base_damage": 22.0,
				"projectile_count": 3,
				"cast_adjacent_hops": 1,
				"door_interval": 2,
				"color": Color("ffb366"),
			}
		"summon_arcane_sentinel_card":
			return {
				"id": "summon_arcane_sentinel_card",
				"name": "Find Familiar",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Summon a temporary allied familiar", "Familiar attacks the strongest enemy and inflicts Flatfooted", "Flatfooted targets take +50% damage", "The familiar fades when the room becomes calm"],
				"stamina_cost": 2.0,
				"cast_adjacent_hops": 1,
				"summon_enemy_role": game.ENEMY_TYPE_DEMON_A,
				"summon_count": 1,
				"summon_attack_damage_override": 1.0,
				"summon_behavior": "familiar_strongest",
				"summon_applies_flatfooted": true,
				"summon_flatfooted_duration": 6.0,
				"summon_flatfooted_move_multiplier": 0.0,
				"summon_flatfooted_attack_speed_multiplier": 0.0,
				"summon_flatfooted_damage_taken_multiplier": 1.5,
				"summon_source_label": "A familiar",
				"summon_conversion_duration": 600.0,
				"door_interval": 2,
				"color": Color("ceb7ff"),
			}
		"lantern_beacon_card":
			return {
				"id": "lantern_beacon_card",
				"name": "Beacon Oil",
				"target_scope": "opened_room",
				"phase": "out_of_combat",
				"description_lines": ["Light one opened room", "Lasts through the next combat wave", "Consumes 1 lantern charge"],
				"door_interval": 1,
				"color": Color("ffe38a"),
			}
		"cure_light_wounds_card":
			return {
				"id": "cure_light_wounds_card",
				"name": "Cure Light Wounds",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "hero",
				"phase": "combat",
				"description_lines": ["Restore 50% max health to one hero", "Auto-casts when an ally in the room drops below 0 HP", "Overrides Emergency Snack usage when available", "Recharges after 3 opened rooms from a prepared prayer"],
				"heal_percent": 0.5,
				"reaction_trigger": "ally_fatal_in_room",
				"reaction_default_enabled": true,
				"reaction_priority": 90,
				"door_interval": 3,
				"color": Color("c3ffb3"),
			}
		"sanctuary_card":
			return {
				"id": "sanctuary_card",
				"name": "Sanctuary",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "opened_room",
				"phase": "combat",
				"description_lines": ["Target one opened room", "Blesses the room with Sanctuary", "Heroes inside take reduced damage and regenerate slowly", "Recharges after 2 opened rooms from a prepared prayer"],
				"stamina_cost": 1.0,
				"cast_adjacent_hops": 1,
				"sanctuary_duration": 10.0,
				"sanctuary_damage_multiplier": 0.78,
				"sanctuary_regen_per_second": 3.0,
				"door_interval": 2,
				"color": Color("e3ff9f"),
			}
		"hold_person_card":
			return {
				"id": "hold_person_card",
				"name": "Hold Person",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Paralyze one enemy for 6s", "All melee attacks against that target are critical (2x damage)", "Recharges after 2 opened rooms from a prepared prayer"],
				"stamina_cost": 2.0,
				"cast_adjacent_hops": 1,
				"hold_duration": 6.0,
				"hold_target_count": 1,
				"door_interval": 2,
				"color": Color("d9c0ff"),
			}
		"fear_card":
			return {
				"id": "fear_card",
				"name": "Fear",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 2,
				"target_scope": "same_room",
				"phase": "combat",
				"description_lines": ["Target a direction in your room", "A long cone terrifies enemies for 6s", "Feared enemies run away 20% faster", "All damage against feared enemies is critical (2x damage)"],
				"stamina_cost": 2.0,
				"fear_duration": 6.0,
				"fear_speed_multiplier": 1.2,
				"fear_damage_taken_multiplier": 2.0,
				"impact_radius": 220.0,
				"arc_angle_deg": 62.0,
				"door_interval": 2,
				"color": Color("cda3ff"),
			}
		"spiritual_weapon_card":
			return {
				"id": "spiritual_weapon_card",
				"name": "Spiritual Weapon",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Summon a temporary spectral blade", "Weapon attacks the strongest enemy in the room", "Ignored by enemies and invulnerable", "Damage equals a level 2 fighter melee hit", "Fades when the room becomes calm", "Recharges after 2 opened rooms from a prepared prayer"],
				"stamina_cost": 2.0,
				"cast_adjacent_hops": 1,
				"summon_enemy_role": game.ENEMY_TYPE_SPIRITUAL_WEAPON,
				"summon_count": 1,
				"summon_attack_damage_override": 30.0,
				"summon_behavior": "familiar_strongest",
				"summon_source_label": "A spiritual weapon",
				"summon_conversion_duration": 600.0,
				"door_interval": 2,
				"color": Color("f0f1ff"),
			}
		"summon_warden_spirit_card":
			return {
				"id": "summon_warden_spirit_card",
				"name": "Animate Dead",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_classes": [game.HERO_CLASS_CLERIC, game.HERO_CLASS_WIZARD],
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Summon three temporary armored skeletons", "Armored skeletons hold the frontline", "Summons fade when the room becomes calm"],
				"stamina_cost": 2.0,
				"cast_adjacent_hops": 1,
				"summon_enemy_roles": [game.ENEMY_TYPE_SKELETON_ARMORED, game.ENEMY_TYPE_SKELETON_ARMORED, game.ENEMY_TYPE_SKELETON_ARMORED],
				"summon_count": 3,
				"summon_source_label": "Animated dead",
				"summon_conversion_duration": 600.0,
				"door_interval": 2,
				"color": Color("d9f4e2"),
			}
		"mend_card":
			return {
				"id": "mend_card",
				"name": "Mend",
				"target_scope": "hero",
				"phase": "combat",
				"description_lines": ["Large combat heal", "Restore 60 health to one hero"],
				"heal_amount": 60.0,
				"door_interval": 3,
				"color": Color("ff9b9b"),
			}
		"arcane_reset_card":
			return {
				"id": "arcane_reset_card",
				"name": "Reset Cooldowns",
				"spell_level": 0,
				"target_scope": "global",
				"phase": "any",
				"description_lines": ["Spend arcana to refresh cooldown cards", "Cost: 2 arcana per cooldown door per card level", "Always restored after use"],
				"color": Color("8bc1ff"),
			}
		"shield_bash_card":
			return {
				"id": "shield_bash_card",
				"name": "Shield Bash",
				"target_scope": "same_room",
				"phase": "combat",
				"description_lines": ["Slam enemies in a frontal arc", "Knocks enemies back", "Applies Flatfooted: slow + 50% increased damage taken for 6s"],
				"stamina_cost": 0.0,
				"base_damage": 12.0,
				"impact_radius": 138.0,
				"arc_angle_deg": 110.0,
				"knockback_force": 840.0,
				"knockback_duration": 0.24,
				"slow_duration": 6.0,
				"slow_move_multiplier": 0.0,
				"slow_attack_speed_multiplier": 0.0,
				"flatfooted_damage_taken_multiplier": 1.5,
				"door_interval": 2,
				"color": Color("9ec3ff"),
			}
		"emergency_snack_card":
			return {
				"id": "emergency_snack_card",
				"name": "Emergency Snack",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Spend party food to restore 40% max HP", "Auto-triggers at 0 HP", "Combat only, expires on the next door"],
				"food_cost": game.HEAL_FOOD_COST,
				"heal_percent": 0.4,
				"expires_after_turns": 1,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"color": Color("ffd79c"),
			}
		"sunpepper_jerky_card":
			return {
				"id": "sunpepper_jerky_card",
				"name": "Eat Sunpepper Jerky",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-triggers at 0 HP", "Restore 35% max HP", "Gain +2 combo", "Consumes the food item"],
				"heal_percent": 0.35,
				"combo_gain": 2,
				"door_interval": 2,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"reaction_priority": 40,
				"color": Color("ffbe95"),
			}
		"moon_truffle_card":
			return {
				"id": "moon_truffle_card",
				"name": "Eat Moon Truffle",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-triggers at 0 HP", "Restore 50% max HP", "Consumes the food item"],
				"heal_percent": 0.5,
				"door_interval": 2,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"reaction_priority": 55,
				"color": Color("ddd1ff"),
			}
		"tidekelp_roll_card":
			return {
				"id": "tidekelp_roll_card",
				"name": "Eat Tidekelp Roll",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-triggers at 0 HP", "Restore 32% max HP", "Restore 60% stamina", "Consumes the food item"],
				"heal_percent": 0.32,
				"stamina_restore_percent": 0.6,
				"door_interval": 2,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"reaction_priority": 48,
				"color": Color("9dece4"),
			}
		"dagger_card":
			return {
				"id": "dagger_card",
				"name": "Dagger Fan",
				"target_scope": "same_room",
				"stamina_cost": 0.0,
				"base_damage": 40.0,
				"projectile_count": 3,
				"spread": 0.16,
				"speed": 1020.0,
				"bounces": 2,
				"lifetime": 1.45,
				"color": Color("d7f0ff"),
				"backstab_multiplier": 1.75,
				"combo_gain": 1,
				"test_cooldown": 1.35,
			}
		_:
			return {
				"id": "axe_card",
				"name": "Whirling Axe",
				"target_scope": "same_room",
				"stamina_cost": 0.0,
				"base_damage": 40.0,
				"speed": 760.0,
				"bounces": 2,
				"lifetime": 2.2,
				"color": Color("ffd27a"),
				"radius": 17.0,
				"pierce": 2,
				"max_pierce": 3,
				"knockback_force": 220.0,
				"knockback_duration": 0.18,
				"final_hit_knockback_multiplier": 1.9,
				"test_cooldown": 1.8,
			}

static func card_target_scope_label(_game: Node, target_scope: String) -> String:
	match target_scope:
		"same_hero":
			return "Room->Self"
		"same_room", "hero_room":
			return "Room"
		"hero":
			return "Room"
		"opened_room":
			return "Open Room"
		"global":
			return "Global"
		_:
			return "Free"
