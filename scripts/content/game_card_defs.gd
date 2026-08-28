extends RefCounted

const MAGIC_MISSILE_ATTACK_VARIANTS: Array[String] = [
	"magic_missile_left",
	"magic_missile_right",
	"magic_missile_wide_left",
	"magic_missile_wide_right",
]

static func attack_definition(game: Node, attack_id: String) -> Dictionary:
	var variant_index: int = MAGIC_MISSILE_ATTACK_VARIANTS.find(attack_id)
	if variant_index < 0:
		return {}
	var definition: Dictionary = runtime_card_definition(game, "magic_missile_card")
	var curve_offsets: Array = Array(definition.get("projectile_curve_offsets", []))
	if variant_index >= curve_offsets.size():
		return {}
	definition["attack_id"] = attack_id
	definition["projectile_curve_offset"] = float(curve_offsets[variant_index])
	return definition

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
				"base_damage": 46.8,
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
				"base_damage": 23.4,
				"delivery": "magic_missile",
				"visual_style": "laser",
				"allow_cross_room_targets": true,
				"projectile_kind": "magic_missile",
				"projectile_motion": "homing",
				"projectile_initial_direction": "perpendicular",
				"projectile_acceleration": 3068.0,
				"projectile_turn_rate": 2.8,
				"projectile_glow_radius": 22.0,
				"projectile_hit_radius": 12.0,
				"projectile_width": 4.8,
				"projectile_speed": 1180.0,
				"projectile_count": 3,
				"projectile_curve_offsets": [-0.58, 0.72, -0.86, 1.00],
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
				"color": Color("fff1a8"),
				"reusable": true,
			}
		"scorcher_card":
			return {
				"id": "scorcher_card",
				"name": "Scorcher",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 2,
				"target_scope": "same_room",
				"phase": "combat",
				"description_lines": ["Channel a cone of flame from your current room", "Deals damage over time while channeling", "Can be interrupted by giving another command", "The flames also hit allies", "Recharges after 2 opened rooms from a slotted spell"],
				"impact_radius": 220.0,
				"arc_angle_deg": 70.0,
				"dot_damage_per_second": 28.0,
				"channel_tick_interval": 0.25,
				"door_interval": 2,
				"color": Color("ff9b63"),
			}
		"evasive_roll_card":
			return {
				"id": "evasive_roll_card",
				"name": "Evasive Roll",
				"target_scope": "opened_room",
				"phase": "combat",
				"description_lines": ["Combat only", "Roll into an adjacent opened room", "Move at 2x speed while rolling", "Immune to attacks during the roll"],
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
				"requires_adjacent_room_target": true,
				"cast_adjacent_hops": 0,
				"base_damage": 15.6,
				"impact_radius": 54.0,
				"knockback_force": 360.0,
				"knockback_duration": 0.22,
				"travel_speed_multiplier": 2.6,
				"spin_speed": 24.0,
				"door_interval": 2,
				"color": Color("ffe08b"),
			}
		"silver_gauntlet_toss_card":
			return {
				"id": "silver_gauntlet_toss_card",
				"name": "Thrash Around",
				"spell_level": 0,
				"target_scope": "same_room",
				"phase": "combat",
				"description_lines": ["Combat self-buff", "Auto-triggers at full Rage unless disabled", "Consumes all Rage", "Next 6 hits throw enemies with Rage-scaled force", "Wall bounces apply Flatfooted (no damage)", "Each buffed hit adds +5 damage per Rage level", "No Rage gain while buff is active"],
				"reaction_trigger": "fighter_rage_full",
				"reaction_default_enabled": true,
				"rage_throw_buff_hits": 6,
				"pickup_radius_multiplier": 2.0,
				"knockback_force": 840.0,
				"knockback_force_per_rage": 40.0,
				"knockback_duration": 0.24,
				"throw_distance_scale": 2.35,
				"throw_distance_curve": 1.8,
				"max_bounces": 2,
				"base_bounce_damage": 8.0,
				"bounce_damage_per_rage": 9.0,
				"flatfooted_duration": 4.0,
				"flatfooted_move_multiplier": 0.72,
				"flatfooted_attack_speed_multiplier": 0.78,
				"flatfooted_damage_taken_multiplier": 1.5,
				"reusable": true,
				"color": Color("c5d4df"),
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
				"base_damage": 46.8,
				"impact_radius": 18.0,
				"bounce_count": 2,
				"cast_adjacent_hops": 1,
				"door_interval": 3,
				"color": Color("8bd9ff"),
			}
		"haste_card":
			return {
				"id": "haste_card",
				"name": "Haste",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 3,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Buffs the highest-damage ally in that room", "Double move speed and attack speed for 18s", "Recharges after 3 opened rooms from a slotted spell"],
				"cast_adjacent_hops": 1,
				"haste_duration": 18.0,
				"haste_move_speed_multiplier": 2.0,
				"haste_attack_speed_multiplier": 2.0,
				"door_interval": 3,
				"color": Color("ffd56e"),
			}
		"find_familiar_card":
			return {
				"id": "find_familiar_card",
				"name": "Find Familiar",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Summon a temporary allied familiar", "Familiar attacks the strongest enemy and inflicts Flatfooted", "Flatfooted targets take +50% damage", "The familiar fades when the room becomes calm"],
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
				"description_lines": ["Light one opened room", "Lasts through the next combat wave", "Reusable"],
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
		"cleric_operate_card":
			return {
				"id": "cleric_operate_card",
				"name": "Divine Aid",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "same_room",
				"phase": "out_of_combat",
				"icon_path": "res://assets/generated/cards/cleric_operate_card.png",
				"description_lines": ["Operate your current lit major module", "Adds your Wit of its resource at the next wave payout", "Stays active after you leave the room", "Recharges after 2 opened rooms from a prepared prayer"],
				"door_interval": 2,
				"color": Color("9eeaff"),
			}
		"sanctuary_card":
			return {
				"id": "sanctuary_card",
				"name": "Sanctuary",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "opened_room",
				"phase": "combat",
				"description_lines": ["Target one opened room", "Blesses the most wounded ally there", "Only that ally gains damage reduction and slow regeneration", "Recharges after 2 opened rooms from a prepared prayer"],
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
				"description_lines": ["Target a direction in your room", "A long cone terrifies enemies for 6s", "Mindless enemies are unaffected", "Feared enemies run away 20% faster", "All damage against feared enemies is critical (2x damage)"],
				"fear_duration": 6.0,
				"fear_speed_multiplier": 1.2,
				"fear_damage_taken_multiplier": 2.0,
				"impact_radius": 220.0,
				"arc_angle_deg": 62.0,
				"door_interval": 2,
				"color": Color("cda3ff"),
			}
		"calm_emotions_card":
			return {
				"id": "calm_emotions_card",
				"name": "Calm Emotions",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Living enemies there become neutral for 12s", "Undead are unaffected", "Neutral enemies do not move or attack", "Effect ends immediately when they take damage"],
				"cast_adjacent_hops": 1,
				"calm_duration": 12.0,
				"door_interval": 2,
				"color": Color("b7e8ff"),
			}
		"beacon_of_hope_card":
			return {
				"id": "beacon_of_hope_card",
				"name": "Beacon of Hope",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 3,
				"target_scope": "opened_room",
				"phase": "combat",
				"description_lines": ["Target one opened room", "Blesses all allies there", "All allies gain damage reduction and regeneration", "Recharges after 3 opened rooms from a prepared prayer"],
				"cast_adjacent_hops": 1,
				"sanctuary_duration": 10.0,
				"sanctuary_damage_multiplier": 0.78,
				"sanctuary_regen_per_second": 3.0,
				"sanctuary_aoe": true,
				"door_interval": 3,
				"color": Color("d4ff9f"),
			}
		"turn_undead_card":
			return {
				"id": "turn_undead_card",
				"name": "Turn Undead",
				"target_scope": "same_room",
				"phase": "combat",
				"description_lines": ["A holy pulse fills your current room", "All undead there are turned", "Turned undead run away faster and take critical damage", "Effect ends on first damage taken"],
				"fear_duration": 6.0,
				"fear_speed_multiplier": 1.2,
				"fear_damage_taken_multiplier": 2.0,
				"door_interval": 1,
				"color": Color("f0efb5"),
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
				"description_lines": ["Target one opened room", "Summon a temporary spectral blade", "Weapon attacks the strongest enemy in the room", "Ignored by enemies and invulnerable", "Deals 31 damage per strike", "Fades when the room becomes calm", "Recharges after 2 opened rooms from a prepared prayer"],
				"cast_adjacent_hops": 1,
				"summon_enemy_role": game.ENEMY_TYPE_SPIRITUAL_WEAPON,
				"summon_count": 1,
				"summon_behavior": "familiar_strongest",
				"summon_source_label": "A spiritual weapon",
				"summon_conversion_duration": 600.0,
				"door_interval": 2,
				"color": Color("f0f1ff"),
			}
		"animate_dead_card":
			return {
				"id": "animate_dead_card",
				"name": "Animate Dead",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_classes": [game.HERO_CLASS_CLERIC, game.HERO_CLASS_WIZARD],
				"spell_level": 2,
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"phase": "combat",
				"description_lines": ["Target one opened room", "Summon three temporary skeletons", "Skeletons hold the frontline", "Summons fade when the room becomes calm"],
				"cast_adjacent_hops": 1,
				"summon_enemy_roles": [game.ENEMY_TYPE_SKELETON, game.ENEMY_TYPE_SKELETON, game.ENEMY_TYPE_SKELETON],
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
				"base_damage": 7.8,
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
				"spell_level": 0,
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
		"serpent_venom_card":
			return {
				"id": "serpent_venom_card",
				"name": "Apply Serpent Venom",
				"target_scope": "same_hero",
				"phase": "any",
				"description_lines": ["Coat your weapon for 1 dungeon turn", "Applies on all physical hits (basic + physical abilities)", "On hit: venom DoT"],
				"door_interval": 1,
				"poison_id": "serpent_venom",
				"poison_name": "Serpent Venom",
				"poison_stackable": false,
				"poison_apply_stacks": 1,
				"poison_hit_charges": -1,
				"poison_turn_duration_doors": 1,
				"poison_physical_only": true,
				"poison_dot_damage_per_second": 7.0,
				"poison_dot_duration": 5.0,
				"poison_dot_max_stacks": 1,
				"color": Color("8fe78f"),
			}
		"wyvern_toxin_card":
			return {
				"id": "wyvern_toxin_card",
				"name": "Apply Wyvern Toxin",
				"target_scope": "same_hero",
				"phase": "any",
				"description_lines": ["Coat your weapon for 1 dungeon turn", "Applies on all physical hits (basic + physical abilities)", "On hit: bonus damage and slowing toxin"],
				"door_interval": 1,
				"poison_id": "wyvern_toxin",
				"poison_name": "Wyvern Toxin",
				"poison_stackable": false,
				"poison_apply_stacks": 1,
				"poison_hit_charges": -1,
				"poison_turn_duration_doors": 1,
				"poison_physical_only": true,
				"poison_on_hit_damage_per_stack": 6.0,
				"poison_slow_duration": 1.8,
				"poison_slow_move_multiplier": 0.74,
				"poison_slow_attack_speed_multiplier": 0.8,
				"color": Color("7ad8ff"),
			}
		"blacklotus_oil_card":
			return {
				"id": "blacklotus_oil_card",
				"name": "Apply Black Lotus Oil",
				"target_scope": "same_hero",
				"phase": "any",
				"description_lines": ["Coat your weapon for 1 dungeon turn", "Applies on all physical hits (basic + physical abilities)", "On hit: burst flatfooted"],
				"door_interval": 1,
				"poison_id": "blacklotus_oil",
				"poison_name": "Black Lotus Oil",
				"poison_stackable": false,
				"poison_apply_stacks": 1,
				"poison_hit_charges": -1,
				"poison_turn_duration_doors": 1,
				"poison_physical_only": true,
				"poison_on_hit_damage_per_stack": 4.0,
				"poison_flatfooted_duration": 3.2,
				"poison_flatfooted_damage_taken_multiplier": 1.38,
				"poison_flatfooted_move_multiplier": 0.9,
				"poison_flatfooted_attack_speed_multiplier": 0.88,
				"color": Color("cfb7ff"),
			}
		"cloak_of_shadows_card":
			return {
				"id": "cloak_of_shadows_card",
				"name": "Cloak of Shadows",
				"target_scope": "same_hero",
				"phase": "any",
				"description_lines": ["Gain Skulker for 1 dungeon turn", "Enemies ignore you in dark rooms while active"],
				"door_interval": 2,
				"skulker_duration_doors": 1,
				"color": Color("9db9ff"),
			}
		"sunpepper_jerky_card":
			return {
				"id": "sunpepper_jerky_card",
				"name": "Eat Sunpepper Jerky",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-triggers at 0 HP", "Restore 35% max HP", "Gain +35% attack speed for 10s", "Consumes the food item"],
				"heal_percent": 0.35,
				"food_buff_duration": 10.0,
				"food_attack_cooldown_multiplier": 0.74,
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
				"description_lines": ["Auto-triggers at 0 HP", "Restore 35% max HP", "Gain +12 defense for 10s", "Consumes the food item"],
				"heal_percent": 0.35,
				"food_buff_duration": 10.0,
				"food_defence_bonus": 12.0,
				"door_interval": 2,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"reaction_priority": 40,
				"color": Color("ddd1ff"),
			}
		"tidekelp_roll_card":
			return {
				"id": "tidekelp_roll_card",
				"name": "Eat Tidekelp Roll",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-triggers at 0 HP", "Restore 32% max HP", "Gain +30% movement speed for 10s", "Consumes the food item"],
				"heal_percent": 0.32,
				"food_buff_duration": 10.0,
				"food_move_speed_multiplier": 1.3,
				"door_interval": 2,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"reaction_priority": 40,
				"color": Color("9dece4"),
			}
		"dagger_card":
			return {
				"id": "dagger_card",
				"name": "Dagger Fan",
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"base_damage": 26.0,
				"projectile_count": 3,
				"spread": 0.16,
				"speed": 1020.0,
				"bounces": 1,
				"cast_adjacent_hops": 1,
				"lifetime": 1.45,
				"color": Color("d7f0ff"),
				"backstab_multiplier": 2.0,
				"combo_damage_scale": 0.0,
				"combo_gain": 1,
				"test_cooldown": 1.35,
			}
		"rogue_combo_dagger_card":
			return {
				"id": "rogue_combo_dagger_card",
				"name": "Shadow Throw",
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"base_damage": 10.4,
				"projectile_count": 1,
				"spread": 0.0,
				"speed": 1120.0,
				"bounces": 1,
				"cast_adjacent_hops": 1,
				"lifetime": 1.35,
				"color": Color("9c5cff"),
				"backstab_multiplier": 2.0,
				"combo_damage_scale": 0.0,
				"combo_flatfooted_level_2_threshold": 2,
				"combo_flatfooted_level_3_threshold": 3,
				"combo_flatfooted_duration_level_2": 2.4,
				"combo_flatfooted_duration_level_3": 4.0,
				"combo_flatfooted_damage_taken_multiplier_level_2": 1.3,
				"combo_flatfooted_damage_taken_multiplier_level_3": 1.55,
				"combo_flatfooted_move_multiplier": 0.85,
				"combo_flatfooted_attack_speed_multiplier": 0.82,
				"test_cooldown": 1.1,
			}
		"ricochet_dagger_card":
			return {
				"id": "ricochet_dagger_card",
				"name": "Ricochet Chakram",
				"target_scope": "opened_room",
				"requires_line_of_effect": true,
				"description_lines": ["High-damage chakram throw", "Bounces up to 4 times", "If it bounces 3 times before the first hit, it explodes like Fireball", "At Combo 3: all damaged enemies become Flatfooted"],
				"base_damage": 44.2,
				"projectile_count": 1,
				"spread": 0.0,
				"speed": 1160.0,
				"bounces": 4,
				"cast_adjacent_hops": 1,
				"lifetime": 1.8,
				"impact_radius": 92.0,
				"color": Color("ffd7a6"),
				"backstab_multiplier": 2.0,
				"combo_damage_scale": 0.0,
				"combo_flatfooted_level_3_threshold": 3,
				"combo_flatfooted_duration_level_3": 4.0,
				"combo_flatfooted_damage_taken_multiplier_level_3": 1.55,
				"combo_flatfooted_move_multiplier": 0.82,
				"combo_flatfooted_attack_speed_multiplier": 0.82,
				"bounce_explosion_min_bounces": 3,
				"bounce_explosion_impact_radius": 92.0,
				"bounce_explosion_damage_multiplier": 1.0,
				"test_cooldown": 1.55,
			}
		_:
			return {
				"id": "axe_card",
				"name": "Razor Boomerang",
				"target_scope": "same_room",
				"description_lines": ["Throw a heavy razor boomerang", "Pierces and bounces through enemies", "At Combo 3: enemies hit become Flatfooted"],
				"base_damage": 26.0,
				"speed": 760.0,
				"bounces": 2,
				"lifetime": 2.2,
				"color": Color("ffd27a"),
				"radius": 17.0,
				"pierce": 2,
				"max_pierce": 3,
				"knockback_force": 420.0,
				"knockback_duration": 0.22,
				"final_hit_knockback_multiplier": 2.15,
				"combo_flatfooted_level_3_threshold": 3,
				"combo_flatfooted_duration_level_3": 4.0,
				"combo_flatfooted_damage_taken_multiplier_level_3": 1.55,
				"combo_flatfooted_move_multiplier": 0.82,
				"combo_flatfooted_attack_speed_multiplier": 0.82,
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
