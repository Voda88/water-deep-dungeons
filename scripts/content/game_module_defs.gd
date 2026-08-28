extends RefCounted

const MINOR_MODULE_TURRET: String = "ballista_turret"
const MINOR_MODULE_BLIGHT_GAS: String = "tear_gas"
const MINOR_MODULE_RUNEBURST_MORTAR: String = "neurostun_array"
const MINOR_MODULE_ARCANA_TURRET: String = "kip_cannon"
const MINOR_MODULE_CONVERSION: String = "conversion_turret"
const MINOR_MODULE_BOUNTY_INDUSTRY: String = "bounty_materials"
const MINOR_MODULE_BOUNTY_FOOD: String = "bounty_food"
const MINOR_MODULE_BOUNTY_SCIENCE: String = "bounty_arcana"
const MAJOR_MODULE_FOOD: String = "food"
const MAJOR_MODULE_SCIENCE: String = "science"
const MAJOR_MODULE_INDUSTRY: String = "industry"
const MINOR_MODULE_LEVEL_DEFINITIONS: Dictionary = {
	MINOR_MODULE_TURRET: [
		{"build_material_cost": 3, "research_material_cost": 8, "max_health": 80.0, "defence": 10.0, "damage": 9.0, "cooldown": 0.50},
		{"build_material_cost": 4, "research_material_cost": 8, "max_health": 120.0, "defence": 15.0, "damage": 10.0, "cooldown": 0.50},
		{"build_material_cost": 5, "research_material_cost": 8, "max_health": 180.0, "defence": 22.5, "damage": 12.0, "cooldown": 0.50},
		{"build_material_cost": 6, "research_material_cost": 8, "max_health": 270.0, "defence": 33.75, "damage": 14.0, "cooldown": 0.50},
	],
	MINOR_MODULE_BLIGHT_GAS: [
		{"build_material_cost": 12, "research_material_cost": 11, "max_health": 80.0, "defence": 10.0, "damage": 1.7, "cooldown": 1.10},
		{"build_material_cost": 16, "research_material_cost": 16, "max_health": 120.0, "defence": 15.0, "damage": 2.4, "cooldown": 1.02},
		{"build_material_cost": 21, "research_material_cost": 21, "max_health": 180.0, "defence": 22.5, "damage": 3.1, "cooldown": 0.94},
		{"build_material_cost": 24, "research_material_cost": 27, "max_health": 270.0, "defence": 33.75, "damage": 3.8, "cooldown": 0.86},
	],
	MINOR_MODULE_RUNEBURST_MORTAR: [
		{"build_material_cost": 12, "research_material_cost": 11, "max_health": 80.0, "defence": 10.0, "damage": 16.0, "cooldown": 1.45},
		{"build_material_cost": 16, "research_material_cost": 16, "max_health": 120.0, "defence": 15.0, "damage": 22.0, "cooldown": 1.33},
		{"build_material_cost": 21, "research_material_cost": 21, "max_health": 180.0, "defence": 22.5, "damage": 28.0, "cooldown": 1.21},
		{"build_material_cost": 24, "research_material_cost": 27, "max_health": 270.0, "defence": 33.75, "damage": 34.0, "cooldown": 1.09},
	],
	MINOR_MODULE_ARCANA_TURRET: [
		{"build_material_cost": 12, "research_material_cost": 11, "max_health": 80.0, "defence": 10.0, "damage": 16.0, "cooldown": 1.50, "max_damage": 100},
		{"build_material_cost": 16, "research_material_cost": 16, "max_health": 120.0, "defence": 15.0, "damage": 21.0, "cooldown": 1.50, "max_damage": 130},
		{"build_material_cost": 21, "research_material_cost": 21, "max_health": 180.0, "defence": 22.5, "damage": 26.0, "cooldown": 1.50, "max_damage": 160},
		{"build_material_cost": 24, "research_material_cost": 27, "max_health": 270.0, "defence": 33.75, "damage": 31.0, "cooldown": 1.50, "max_damage": 190},
	],
	MINOR_MODULE_CONVERSION: [
		{"build_material_cost": 12, "research_material_cost": 11, "max_health": 80.0, "defence": 10.0, "damage": 0.0, "cooldown": 3.40, "conversion_duration": 7.2},
		{"build_material_cost": 16, "research_material_cost": 16, "max_health": 120.0, "defence": 15.0, "damage": 0.0, "cooldown": 3.05, "conversion_duration": 9.6},
		{"build_material_cost": 21, "research_material_cost": 21, "max_health": 180.0, "defence": 22.5, "damage": 0.0, "cooldown": 2.70, "conversion_duration": 12.0},
		{"build_material_cost": 24, "research_material_cost": 27, "max_health": 270.0, "defence": 33.75, "damage": 0.0, "cooldown": 2.35, "conversion_duration": 14.4},
	],
	MINOR_MODULE_BOUNTY_INDUSTRY: [
		{"build_material_cost": 12, "research_material_cost": 11, "max_health": 80.0, "defence": 10.0, "damage": 0.0, "cooldown": 0.10, "kills_required": 6},
		{"build_material_cost": 16, "research_material_cost": 16, "max_health": 120.0, "defence": 15.0, "damage": 0.0, "cooldown": 0.10, "kills_required": 5},
		{"build_material_cost": 21, "research_material_cost": 21, "max_health": 180.0, "defence": 22.5, "damage": 0.0, "cooldown": 0.10, "kills_required": 4},
		{"build_material_cost": 24, "research_material_cost": 27, "max_health": 270.0, "defence": 33.75, "damage": 0.0, "cooldown": 0.10, "kills_required": 3},
	],
	MINOR_MODULE_BOUNTY_FOOD: [
		{"build_material_cost": 12, "research_material_cost": 11, "max_health": 80.0, "defence": 10.0, "damage": 0.0, "cooldown": 0.10, "kills_required": 6},
		{"build_material_cost": 16, "research_material_cost": 16, "max_health": 120.0, "defence": 15.0, "damage": 0.0, "cooldown": 0.10, "kills_required": 5},
		{"build_material_cost": 21, "research_material_cost": 21, "max_health": 180.0, "defence": 22.5, "damage": 0.0, "cooldown": 0.10, "kills_required": 4},
		{"build_material_cost": 24, "research_material_cost": 27, "max_health": 270.0, "defence": 33.75, "damage": 0.0, "cooldown": 0.10, "kills_required": 3},
	],
	MINOR_MODULE_BOUNTY_SCIENCE: [
		{"build_material_cost": 12, "research_material_cost": 11, "max_health": 80.0, "defence": 10.0, "damage": 0.0, "cooldown": 0.10, "kills_required": 6},
		{"build_material_cost": 16, "research_material_cost": 16, "max_health": 120.0, "defence": 15.0, "damage": 0.0, "cooldown": 0.10, "kills_required": 5},
		{"build_material_cost": 21, "research_material_cost": 21, "max_health": 180.0, "defence": 22.5, "damage": 0.0, "cooldown": 0.10, "kills_required": 4},
		{"build_material_cost": 24, "research_material_cost": 27, "max_health": 270.0, "defence": 33.75, "damage": 0.0, "cooldown": 0.10, "kills_required": 3},
	],
}
const MINOR_MODULE_DEFINITIONS: Dictionary = {
	MINOR_MODULE_TURRET: {"color": Color("d8bf7a"), "targeting": {"strategy": "nearest", "range": 620.0}, "delivery": "arrow", "projectile_kind": "arrow", "projectile_width": 2.4, "projectile_speed_offset": 80.0, "projectile_curve_offset": 0.0},
	MINOR_MODULE_BLIGHT_GAS: {"color": Color("b7e88f"), "targeting": {"strategy": "all", "range": 0.0}, "delivery": "arrow", "projectile_kind": "arrow", "projectile_width": 2.4, "projectile_speed_offset": 80.0, "projectile_curve_offset": 0.0},
	MINOR_MODULE_RUNEBURST_MORTAR: {"color": Color("ffb977"), "targeting": {"strategy": "nearest", "range": 620.0}, "delivery": "arrow", "projectile_kind": "arrow", "projectile_width": 3.4, "projectile_speed": 860.0, "projectile_curve_offset": 0.0},
	MINOR_MODULE_ARCANA_TURRET: {"color": Color("b38cff"), "targeting": {"strategy": "strongest", "range": 620.0}, "delivery": "laser", "projectile_kind": "arcana_bolt", "projectile_width": 4.6, "projectile_speed": 980.0, "projectile_curve_offset": 0.18},
	MINOR_MODULE_CONVERSION: {"color": Color("8effc4"), "targeting": {"strategy": "strongest", "range": 620.0}, "delivery": "arrow", "projectile_kind": "arrow", "projectile_width": 2.4, "projectile_speed_offset": 80.0, "projectile_curve_offset": 0.0},
	MINOR_MODULE_BOUNTY_INDUSTRY: {"color": Color("f0c87b"), "targeting": {"strategy": "none", "range": 0.0}, "delivery": "arrow", "projectile_kind": "arrow", "projectile_width": 2.4, "projectile_speed_offset": 80.0, "projectile_curve_offset": 0.0, "bounty_resource_id": "industry"},
	MINOR_MODULE_BOUNTY_FOOD: {"color": Color("9ce589"), "targeting": {"strategy": "none", "range": 0.0}, "delivery": "arrow", "projectile_kind": "arrow", "projectile_width": 2.4, "projectile_speed_offset": 80.0, "projectile_curve_offset": 0.0, "bounty_resource_id": "food"},
	MINOR_MODULE_BOUNTY_SCIENCE: {"color": Color("8ec2ff"), "targeting": {"strategy": "none", "range": 0.0}, "delivery": "arrow", "projectile_kind": "arrow", "projectile_width": 2.4, "projectile_speed_offset": 80.0, "projectile_curve_offset": 0.0, "bounty_resource_id": "science"},
}

static func canonical_minor_module_type(module_type: String) -> String:
	return module_type

static func minor_module_catalog() -> Array[String]:
	return [
		MINOR_MODULE_TURRET,
		MINOR_MODULE_BLIGHT_GAS,
		MINOR_MODULE_RUNEBURST_MORTAR,
		MINOR_MODULE_ARCANA_TURRET,
		MINOR_MODULE_CONVERSION,
		MINOR_MODULE_BOUNTY_INDUSTRY,
		MINOR_MODULE_BOUNTY_FOOD,
		MINOR_MODULE_BOUNTY_SCIENCE,
	]

static func initialized_minor_module_levels() -> Dictionary:
	return {
		MINOR_MODULE_TURRET: 1,
		MINOR_MODULE_BLIGHT_GAS: 0,
		MINOR_MODULE_RUNEBURST_MORTAR: 0,
		MINOR_MODULE_ARCANA_TURRET: 0,
		MINOR_MODULE_CONVERSION: 0,
		MINOR_MODULE_BOUNTY_INDUSTRY: 0,
		MINOR_MODULE_BOUNTY_FOOD: 0,
		MINOR_MODULE_BOUNTY_SCIENCE: 0,
	}

static func initialized_major_module_levels() -> Dictionary:
	return {
		MAJOR_MODULE_FOOD: 1,
		MAJOR_MODULE_SCIENCE: 1,
		MAJOR_MODULE_INDUSTRY: 1,
	}

static func normalized_minor_module_levels(source: Dictionary) -> Dictionary:
	var normalized: Dictionary = initialized_minor_module_levels()
	for key_variant in source.keys():
		var canonical_key: String = canonical_minor_module_type(String(key_variant))
		if not normalized.has(canonical_key):
			continue
		var current_value: int = int(normalized[canonical_key])
		var source_value: int = int(source[key_variant]) if source.has(key_variant) else current_value
		normalized[canonical_key] = maxi(source_value, current_value)
	return normalized

static func normalized_major_module_levels(source: Dictionary) -> Dictionary:
	var normalized: Dictionary = initialized_major_module_levels()
	for key_variant in source.keys():
		var key: String = String(key_variant)
		if not normalized.has(key):
			continue
		var current_value: int = int(normalized[key])
		var source_value: int = int(source[key_variant]) if source.has(key_variant) else current_value
		normalized[key] = maxi(source_value, current_value)
	return normalized

static func minor_module_level(module_type: String, minor_module_levels: Dictionary) -> int:
	var canonical_type: String = canonical_minor_module_type(module_type)
	var default_levels: Dictionary = initialized_minor_module_levels()
	var default_level: int = int(default_levels[canonical_type]) if default_levels.has(canonical_type) else 0
	if minor_module_levels.has(canonical_type):
		return maxi(int(minor_module_levels[canonical_type]), default_level)
	for key_variant in minor_module_levels.keys():
		var source_key: String = String(key_variant)
		if canonical_minor_module_type(source_key) != canonical_type:
			continue
		return maxi(int(minor_module_levels[source_key]), default_level)
	return default_level

static func major_module_level(module_type: String, major_module_levels: Dictionary) -> int:
	if major_module_levels.has(module_type):
		return int(major_module_levels[module_type])
	return 1

static func minor_module_unlocked(module_type: String, minor_module_levels: Dictionary) -> bool:
	return minor_module_level(module_type, minor_module_levels) > 0

static func research_display_name(module_type: String) -> String:
	match module_type:
		MINOR_MODULE_TURRET:
			return "Crossbow"
		MINOR_MODULE_BLIGHT_GAS:
			return "Blight Gas"
		MINOR_MODULE_RUNEBURST_MORTAR:
			return "Runeburst Mortar"
		MINOR_MODULE_ARCANA_TURRET:
			return "Arcana Turret"
		MINOR_MODULE_CONVERSION:
			return "Soulbind Spire"
		MINOR_MODULE_BOUNTY_INDUSTRY:
			return "Salvage Sigil"
		MINOR_MODULE_BOUNTY_FOOD:
			return "Provision Sigil"
		MINOR_MODULE_BOUNTY_SCIENCE:
			return "Sage Sigil"
		MAJOR_MODULE_FOOD:
			return "Food Module"
		MAJOR_MODULE_SCIENCE:
			return "Arcana Module"
		MAJOR_MODULE_INDUSTRY:
			return "Materials Module"
		_:
			return module_type.capitalize()

static func available_minor_module_build_types(minor_module_levels: Dictionary) -> Array[String]:
	var available: Array[String] = []
	for module_type_variant in minor_module_catalog():
		var module_type: String = String(module_type_variant)
		if minor_module_unlocked(module_type, minor_module_levels):
			available.append(module_type)
	if available.is_empty():
		available.append(MINOR_MODULE_TURRET)
	return available

static func module_level_roman(level: int) -> String:
	match level:
		2:
			return "II"
		3:
			return "III"
		4:
			return "IV"
		_:
			return "I"

static func build_type_label(module_type: String) -> String:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_TURRET:
			return "Crossbow"
		MINOR_MODULE_BLIGHT_GAS:
			return "Blight Gas"
		MINOR_MODULE_RUNEBURST_MORTAR:
			return "Runeburst Mortar"
		MINOR_MODULE_ARCANA_TURRET:
			return "Arcana Turret"
		MINOR_MODULE_CONVERSION:
			return "Soulbind Spire"
		MINOR_MODULE_BOUNTY_INDUSTRY:
			return "Salvage Sigil"
		MINOR_MODULE_BOUNTY_FOOD:
			return "Provision Sigil"
		MINOR_MODULE_BOUNTY_SCIENCE:
			return "Sage Sigil"
		MAJOR_MODULE_FOOD:
			return "Food Module"
		MAJOR_MODULE_SCIENCE:
			return "Arcana Module"
		MAJOR_MODULE_INDUSTRY:
			return "Materials Module"
		_:
			return "Build"

static func is_minor_module_type(module_type: String) -> bool:
	var canonical_type: String = canonical_minor_module_type(module_type)
	return canonical_type == MINOR_MODULE_TURRET \
		or canonical_type == MINOR_MODULE_BLIGHT_GAS \
		or canonical_type == MINOR_MODULE_RUNEBURST_MORTAR \
		or canonical_type == MINOR_MODULE_ARCANA_TURRET \
		or canonical_type == MINOR_MODULE_CONVERSION \
		or canonical_type == MINOR_MODULE_BOUNTY_INDUSTRY \
		or canonical_type == MINOR_MODULE_BOUNTY_FOOD \
		or canonical_type == MINOR_MODULE_BOUNTY_SCIENCE

static func is_major_module_type(module_type: String) -> bool:
	return module_type == MAJOR_MODULE_FOOD or module_type == MAJOR_MODULE_SCIENCE or module_type == MAJOR_MODULE_INDUSTRY

static func minor_module_level_definition(module_type: String, level: int) -> Dictionary:
	var definitions: Array = Array(MINOR_MODULE_LEVEL_DEFINITIONS.get(canonical_minor_module_type(module_type), []))
	if definitions.is_empty():
		return {}
	var index: int = clampi(level - 1, 0, definitions.size() - 1)
	return Dictionary(definitions[index])

static func minor_module_definition(module_type: String) -> Dictionary:
	return Dictionary(MINOR_MODULE_DEFINITIONS.get(canonical_minor_module_type(module_type), {}))

static func minor_module_cost(module_type: String, minor_module_levels: Dictionary = {}) -> int:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	return maxi(1, int(minor_module_level_definition(module_type, level).get("build_material_cost", 1)))

static func minor_module_research_cost(module_type: String, next_level: int) -> int:
	return maxi(1, int(minor_module_level_definition(module_type, next_level).get("research_material_cost", 8)))

static func minor_module_max_health(module_type: String, minor_module_levels: Dictionary) -> float:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	return float(minor_module_level_definition(module_type, level).get("max_health", 80.0))

static func minor_module_defence(module_type: String, minor_module_levels: Dictionary) -> float:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	return float(minor_module_level_definition(module_type, level).get("defence", 0.0))

static func major_module_upgrade_cost(next_level: int) -> int:
	match clampi(next_level, 1, 4):
		2:
			return 45
		3:
			return 60
		4:
			return 100
		_:
			return 30

static func major_module_door_yield(level: int) -> int:
	return clampi(level + 2, 3, 6)

static func minor_module_arcana_turret_max_damage(level: int) -> int:
	return int(minor_module_level_definition(MINOR_MODULE_ARCANA_TURRET, level).get("max_damage", 0))

static func minor_module_damage(module_type: String, minor_module_levels: Dictionary) -> float:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	return float(minor_module_level_definition(module_type, level).get("damage", 0.0))

static func minor_module_damage_at_level(module_type: String, level: int) -> float:
	var canonical_type: String = canonical_minor_module_type(module_type)
	return minor_module_damage(canonical_type, {canonical_type: level})

static func minor_module_cooldown(module_type: String, minor_module_levels: Dictionary) -> float:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	return float(minor_module_level_definition(module_type, level).get("cooldown", 0.5))

static func minor_module_conversion_duration_by_level(level: int) -> float:
	return float(minor_module_level_definition(MINOR_MODULE_CONVERSION, level).get("conversion_duration", 0.0))

static func minor_module_conversion_duration(module_type: String, minor_module_levels: Dictionary) -> float:
	if canonical_minor_module_type(module_type) != MINOR_MODULE_CONVERSION:
		return 0.0
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	return minor_module_conversion_duration_by_level(level)

static func minor_module_color(module_type: String) -> Color:
	return minor_module_definition(module_type).get("color", Color("d8bf7a"))

static func minor_module_projectile_width(module_type: String) -> float:
	return float(minor_module_definition(module_type).get("projectile_width", 2.4))

static func minor_module_projectile_speed(module_type: String, base_projectile_speed: float) -> float:
	var definition: Dictionary = minor_module_definition(module_type)
	if definition.has("projectile_speed"):
		return float(definition["projectile_speed"])
	return base_projectile_speed + float(definition.get("projectile_speed_offset", 80.0))

static func minor_module_projectile_curve_offset(module_type: String) -> float:
	return float(minor_module_definition(module_type).get("projectile_curve_offset", 0.0))

static func minor_module_targeting_definition(module_type: String) -> Dictionary:
	return Dictionary(minor_module_definition(module_type).get("targeting", {"strategy": "nearest", "range": 620.0}))

static func minor_module_attack_definition(module_type: String, base_projectile_speed: float) -> Dictionary:
	var canonical_type: String = canonical_minor_module_type(module_type)
	var definition: Dictionary = minor_module_definition(canonical_type)
	return {
		"delivery": String(definition.get("delivery", "arrow")),
		"projectile_kind": String(definition.get("projectile_kind", "arrow")),
		"projectile_color": minor_module_color(canonical_type),
		"projectile_width": minor_module_projectile_width(canonical_type),
		"projectile_speed": minor_module_projectile_speed(canonical_type, base_projectile_speed),
		"projectile_curve_offset": minor_module_projectile_curve_offset(canonical_type),
	}

static func minor_module_bounty_resource_id(module_type: String) -> String:
	return String(minor_module_definition(module_type).get("bounty_resource_id", ""))

static func minor_module_is_bounty_type(module_type: String) -> bool:
	return minor_module_bounty_resource_id(module_type) != ""

static func minor_module_bounty_kills_required(module_type: String, minor_module_levels: Dictionary) -> int:
	if not minor_module_is_bounty_type(module_type):
		return 0
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	return int(minor_module_level_definition(module_type, level).get("kills_required", 0))
