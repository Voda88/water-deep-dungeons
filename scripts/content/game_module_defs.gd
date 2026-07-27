extends RefCounted

const MINOR_MODULE_TURRET: String = "ballista_turret"
const MINOR_MODULE_PULSE: String = "tear_gas"
const MINOR_MODULE_CANNON: String = "neurostun_array"
const MINOR_MODULE_KIP: String = "kip_cannon"
const MAJOR_MODULE_FOOD: String = "food"
const MAJOR_MODULE_SCIENCE: String = "science"
const MAJOR_MODULE_INDUSTRY: String = "industry"
const BALLISTA_LEVEL_DAMAGE: Array[float] = [9.0, 10.0, 12.0, 14.0]

static func canonical_minor_module_type(module_type: String) -> String:
	return module_type

static func minor_module_catalog() -> Array[String]:
	return [
		MINOR_MODULE_TURRET,
		MINOR_MODULE_PULSE,
		MINOR_MODULE_CANNON,
		MINOR_MODULE_KIP,
	]

static func initialized_minor_module_levels() -> Dictionary:
	return {
		MINOR_MODULE_TURRET: 1,
		MINOR_MODULE_PULSE: 0,
		MINOR_MODULE_CANNON: 0,
		MINOR_MODULE_KIP: 0,
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
			return "Tear Gas"
		MINOR_MODULE_CANNON:
			return "Neurostun"
		MINOR_MODULE_KIP:
			return "KIP Cannon"
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
			return "Tear Gas"
		MINOR_MODULE_CANNON:
			return "Neurostun"
		MINOR_MODULE_KIP:
			return "KIP Cannon"
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
	return canonical_type == MINOR_MODULE_TURRET or canonical_type == MINOR_MODULE_PULSE or canonical_type == MINOR_MODULE_CANNON or canonical_type == MINOR_MODULE_KIP

static func is_major_module_type(module_type: String) -> bool:
	return module_type == MAJOR_MODULE_FOOD or module_type == MAJOR_MODULE_SCIENCE or module_type == MAJOR_MODULE_INDUSTRY

static func minor_module_cost(module_type: String) -> int:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_PULSE:
			return 4
		MINOR_MODULE_CANNON:
			return 6
		MINOR_MODULE_KIP:
			return 5
		_:
			return 3

static func minor_module_damage(module_type: String, minor_module_levels: Dictionary) -> float:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_PULSE:
			return 2.0 + float(level)
		MINOR_MODULE_CANNON:
			return 0.0
		MINOR_MODULE_KIP:
			return 20.0 + float(level - 1) * 4.0
		_:
			return BALLISTA_LEVEL_DAMAGE[level - 1]

static func minor_module_cooldown(module_type: String, minor_module_levels: Dictionary) -> float:
	var level: int = clampi(minor_module_level(module_type, minor_module_levels), 1, 4)
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_PULSE:
			return 0.9
		MINOR_MODULE_CANNON:
			return 1.1 - float(level - 1) * 0.1
		MINOR_MODULE_KIP:
			return 1.2 - float(level - 1) * 0.08
		_:
			return 0.5

static func minor_module_color(module_type: String) -> Color:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_PULSE:
			return Color("b8ef7d")
		MINOR_MODULE_CANNON:
			return Color("8fe3ff")
		MINOR_MODULE_KIP:
			return Color("ffb36e")
		_:
			return Color("d8bf7a")

static func minor_module_projectile_width(module_type: String) -> float:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_KIP:
			return 4.8
		_:
			return 2.4

static func minor_module_projectile_speed(module_type: String, base_projectile_speed: float) -> float:
	match canonical_minor_module_type(module_type):
		MINOR_MODULE_KIP:
			return 920.0
		_:
			return base_projectile_speed + 80.0
