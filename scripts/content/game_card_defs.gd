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
				"base_damage": 42.0,
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
				"description_lines": ["Target one opened room", "Launches three seeking missiles", "Recharges after 1 opened room from a slotted spell"],
				"stamina_cost": 1.0,
				"base_damage": 36.0,
				"projectile_count": 3,
				"adjacent_cast_anywhere": true,
				"cast_adjacent_hops": 1,
				"door_interval": 1,
				"color": Color("c18dff"),
			}
		"light_cantrip_card":
			return {
				"id": "light_cantrip_card",
				"name": "Light",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
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
				"description_lines": ["Teleport to a seen point", "Can hop into an adjacent room through a doorway", "Recharges after 2 opened rooms from a slotted spell"],
				"stamina_cost": 0.0,
				"cast_adjacent_hops": 1,
				"door_interval": 2,
				"color": Color("b89cff"),
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
		"shield_card":
			return {
				"id": "shield_card",
				"name": "Shield",
				"spell_class": game.HERO_CLASS_WIZARD,
				"spell_level": 1,
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Auto-casts on a fatal hit", "Grants 6 seconds of immunity", "Recharges after 2 opened rooms from a slotted spell"],
				"stamina_cost": 1.0,
				"shield_amount": 0.0,
				"shield_duration": 0.0,
				"immunity_duration": 6.0,
				"auto_cast_on_fatal": true,
				"reaction_trigger": "fatal_damage",
				"reaction_default_enabled": true,
				"door_interval": 2,
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
				"base_damage": 30.0,
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
		"lantern_torch_card":
			return {
				"id": "lantern_torch_card",
				"name": "Lamp Oil",
				"target_scope": "hero",
				"phase": "out_of_combat",
				"description_lines": ["Create one torch in a hero backpack", "Consumes 1 lantern charge"],
				"door_interval": 1,
				"color": Color("ffe38a"),
			}
		"torch_card":
			return {
				"id": "torch_card",
				"name": "Torch",
				"target_scope": "opened_room",
				"phase": "out_of_combat",
				"description_lines": ["Light one opened room", "Lasts through the next combat wave"],
				"door_interval": 2,
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
				"description_lines": ["Restore 36 health to one hero", "Recharges after 2 opened rooms from a prepared prayer"],
				"heal_amount": 36.0,
				"door_interval": 2,
				"color": Color("c3ffb3"),
			}
		"sanctuary_card":
			return {
				"id": "sanctuary_card",
				"name": "Sanctuary",
				"spell_class": game.HERO_CLASS_CLERIC,
				"spell_level": 1,
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Gain a brief divine ward", "Recharges after 2 opened rooms from a prepared prayer"],
				"stamina_cost": 1.0,
				"shield_amount": 24.0,
				"shield_duration": 8.0,
				"door_interval": 2,
				"color": Color("e3ff9f"),
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
		"emergency_snack_card":
			return {
				"id": "emergency_snack_card",
				"name": "Emergency Snack",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Spend party food to fully patch up", "Combat only, expires on the next door"],
				"food_cost": game.HEAL_FOOD_COST,
				"heal_full": true,
				"restore_stamina_full": true,
				"expires_after_turns": 1,
				"reaction_trigger": "stamina_negative",
				"reaction_default_enabled": true,
				"color": Color("ffd79c"),
			}
		"ration_meal_card":
			return {
				"id": "ration_meal_card",
				"name": "Eat Ration",
				"target_scope": "same_hero",
				"phase": "combat",
				"description_lines": ["Combat heal plus stamina restore", "Also grants minor combat stamina regen"],
				"heal_amount": 24.0,
				"stamina_restore": 2.0,
				"stamina_regen_rate": 0.45,
				"stamina_regen_duration": 7.0,
				"door_interval": 2,
				"reaction_trigger": "stamina_negative",
				"reaction_default_enabled": true,
				"color": Color("d7f09f"),
			}
		"dagger_card":
			return {
				"id": "dagger_card",
				"name": "Dagger Fan",
				"target_scope": "same_room",
				"stamina_cost": 1.0,
				"base_damage": 10.0,
				"projectile_count": 3,
				"spread": 0.16,
				"speed": 1020.0,
				"bounces": 1,
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
				"stamina_cost": 2.0,
				"base_damage": 20.0,
				"speed": 760.0,
				"bounces": 2,
				"lifetime": 2.2,
				"color": Color("ffd27a"),
				"radius": 17.0,
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
