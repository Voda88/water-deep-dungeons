extends RefCounted

const MINOR_MODULE_TURRET: String = "ballista_turret"
const MINOR_MODULE_PULSE: String = "tear_gas"
const MINOR_MODULE_CANNON: String = "neurostun_array"
const MINOR_MODULE_KIP: String = "kip_cannon"
const MINOR_MODULE_CONVERSION: String = "conversion_turret"
const MINOR_MODULE_BOUNTY_INDUSTRY: String = "bounty_materials"
const MINOR_MODULE_BOUNTY_FOOD: String = "bounty_food"
const MINOR_MODULE_BOUNTY_SCIENCE: String = "bounty_arcana"
const MAJOR_MODULE_FOOD: String = "food"
const MAJOR_MODULE_SCIENCE: String = "science"
const MAJOR_MODULE_INDUSTRY: String = "industry"
const BALLISTA_LEVEL_DAMAGE: Array[float] = [4.5, 5.0, 6.0, 7.0]
const MINOR_MODULE_BOUNTY_THRESHOLDS: Array[int] = [6, 5, 4, 3]
const MINOR_MODULE_KIP_MAX_DAMAGE_BY_LEVEL: Array[int] = [100, 130, 160, 190]

static func canonical_minor_module_type(module_type: String) -> String:
	return module_type

static func minor_module_catalog() -> Array[String]:
	return [
		MINOR_MODULE_TURRET,
		MINOR_MODULE_PULSE,
		MINOR_MODULE_CANNON,
		MINOR_MODULE_KIP,
		MINOR_MODULE_CONVERSION,
		MINOR_MODULE_BOUNTY_INDUSTRY,
		MINOR_MODULE_BOUNTY_FOOD,
		MINOR_MODULE_BOUNTY_SCIENCE,
	]

static func initialized_minor_module_levels() -> Dictionary:
	return {
		MINOR_MODULE_TURRET: 1,
		MINOR_MODULE_PULSE: 0,
		MINOR_MODULE_CANNON: 0,
		MINOR_MODULE_KIP: 0,
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
		normalized[canonical_key] = maxi(int(source.get(key_variant, normalized[canonical_key])), int(normalized[canonical_key]))
	return normalized

static func normalized_major_module_levels(source: Dictionary) -> Dictionary:
	var normalized: Dictionary = initialized_major_module_levels()
	for key_variant in source.keys():
		var key: String = String(key_variant)
		if not normalized.has(key):
			continue
		normalized[key] = maxi(int(source.get(key_variant, normalized[key])), int(normalized[key]))
	return normalized

static func minor_module_level(module_type: String, minor_module_levels: Dictionary) -> int:
	var canonical_type: String = canonical_minor_module_type(module_type)
	var default_levels: Dictionary = initialized_minor_module_levels()
	var default_level: int = int(default_levels.get(canonical_type, 0))
	if minor_module_levels.has(canonical_type):
		return maxi(int(minor_module_levels.get(canonical_type, default_level)), default_level)
	for key_variant in minor_module_levels.keys():
		var source_key: String = String(key_variant)
		if canonical_minor_module_type(source_key) != canonical_type:
			continue
		return maxi(int(minor_module_levels.get(source_key, default_level)), default_level)
	return default_level

static func major_module_level(module_type: String, major_module_levels: Dictionary) -> int:
	return int(major_module_levels.get(module_type, 1))

static func minor_module_unlocked(module_type: String, minor_module_levels: Dictionary) -> bool:
	return minor_module_level(module_type, minor_module_levels) > 0

static func research_display_name(module_type: String) -> String:
	match module_type:
		MINOR_MODULE_TURRET:
			return "Crossbow"
		MINOR_MODULE_PULSE:
			return "Blight Gas"
		MINOR_MODULE_CANNON:
			return "Runeburst Mortar"
		MINOR_MODULE_KIP:
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
		MINOR_MODULE_PULSE:
			return "Blight Gas"
		MINOR_MODULE_CANNON:
			return "Runeburst Mortar"
		MINOR_MODULE_KIP:
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
		or canonical_type == MINOR_MODULE_PULSE \
		or canonical_type == MINOR_MODULE_CANNON \
		or canonical_type == MINOR_MODULE_KIP \
		or canonical_type == MINOR_MODULE_CONVERSION \
		or canonical_type == MINOR_MODULE_BOUNTY_INDUSTRY \
		or canonical_type == MINOR_MODULE_BOUNTY_FOOD \
		or canonical_type == MINOR_MODULE_BOUNTY_SCIENCE

static func is_major_module_type(module_type: String) -> bool:
	return module_type == MAJOR_MODULE_FOOD or module_type == MAJOR_MODULE_SCIENCE or module_type == MAJOR_MODULE_INDUSTRY

static func minor_module_base_cost(module_type: String) -> int:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_TURRET:
			return 3
		MINOR_MODULE_PULSE:
			return 20
		MINOR_MODULE_CANNON:
			return 35
		MINOR_MODULE_KIP:
			return 30
		MINOR_MODULE_CONVERSION:
			return 25
		MINOR_MODULE_BOUNTY_INDUSTRY:
			return 22
		MINOR_MODULE_BOUNTY_FOOD:
			return 22
		MINOR_MODULE_BOUNTY_SCIENCE:
			return 22
		_:
			return 15

static func minor_module_cost(module_type: String, minor_module_levels: Dictionary = {}) -> int:
	var base_cost: int = minor_module_base_cost(module_type)
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	var level_multiplier: float = 1.0 + float(level - 1) * 0.32
	if level >= 4:
		level_multiplier += 0.04
	return maxi(1, int(round(float(base_cost) * level_multiplier)))

static func minor_module_research_cost(module_type: String, next_level: int) -> int:
	var base_cost: int = minor_module_base_cost(module_type)
	var multipliers: Array[float] = [0.90, 1.30, 1.75, 2.25]
	var index: int = clampi(next_level - 1, 0, multipliers.size() - 1)
	return maxi(8, int(round(float(base_cost) * multipliers[index])))

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

static func minor_module_kip_max_damage(level: int) -> int:
	var index: int = clampi(level - 1, 0, MINOR_MODULE_KIP_MAX_DAMAGE_BY_LEVEL.size() - 1)
	return int(MINOR_MODULE_KIP_MAX_DAMAGE_BY_LEVEL[index])

static func minor_module_damage(module_type: String, minor_module_levels: Dictionary) -> float:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_PULSE:
			return 1.0 + float(level) * 0.7
		MINOR_MODULE_CANNON:
			return 8.0 + float(level - 1) * 3.0
		MINOR_MODULE_KIP:
			return 16.0 + float(level - 1) * 5.0
		MINOR_MODULE_CONVERSION:
			return 0.0
		MINOR_MODULE_BOUNTY_INDUSTRY, MINOR_MODULE_BOUNTY_FOOD, MINOR_MODULE_BOUNTY_SCIENCE:
			return 0.0
		_:
			return BALLISTA_LEVEL_DAMAGE[level - 1]

static func minor_module_cooldown(module_type: String, minor_module_levels: Dictionary) -> float:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_PULSE:
			return 1.1 - float(level - 1) * 0.08
		MINOR_MODULE_CANNON:
			return 1.45 - float(level - 1) * 0.12
		MINOR_MODULE_KIP:
			return 1.5
		MINOR_MODULE_CONVERSION:
			return 3.4 - float(level - 1) * 0.35
		MINOR_MODULE_BOUNTY_INDUSTRY, MINOR_MODULE_BOUNTY_FOOD, MINOR_MODULE_BOUNTY_SCIENCE:
			return 0.1
		_:
			return 0.5

static func minor_module_color(module_type: String) -> Color:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_PULSE:
			return Color("b7e88f")
		MINOR_MODULE_CANNON:
			return Color("ffb977")
		MINOR_MODULE_KIP:
			return Color("b38cff")
		MINOR_MODULE_CONVERSION:
			return Color("8effc4")
		MINOR_MODULE_BOUNTY_INDUSTRY:
			return Color("f0c87b")
		MINOR_MODULE_BOUNTY_FOOD:
			return Color("9ce589")
		MINOR_MODULE_BOUNTY_SCIENCE:
			return Color("8ec2ff")
		_:
			return Color("d8bf7a")

static func minor_module_projectile_width(module_type: String) -> float:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_KIP:
			return 4.6
		MINOR_MODULE_CANNON:
			return 3.4
		_:
			return 2.4

static func minor_module_projectile_speed(module_type: String, base_projectile_speed: float) -> float:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_KIP:
			return 980.0
		MINOR_MODULE_CANNON:
			return 860.0
		_:
			return base_projectile_speed + 80.0

static func minor_module_bounty_resource_id(module_type: String) -> String:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_BOUNTY_INDUSTRY:
			return "industry"
		MINOR_MODULE_BOUNTY_FOOD:
			return "food"
		MINOR_MODULE_BOUNTY_SCIENCE:
			return "science"
		_:
			return ""

static func minor_module_is_bounty_type(module_type: String) -> bool:
	return minor_module_bounty_resource_id(module_type) != ""

static func minor_module_bounty_kills_required(module_type: String, minor_module_levels: Dictionary) -> int:
	if not minor_module_is_bounty_type(module_type):
		return 0
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	return MINOR_MODULE_BOUNTY_THRESHOLDS[level - 1]
