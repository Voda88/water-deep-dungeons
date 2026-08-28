extends RefCounted
class_name GameStatusEffects

static func refresh_flatfooted_state(current_time_left: float, current_duration: float, current_damage_taken_multiplier: float, duration: float, damage_taken_multiplier: float) -> Dictionary:
	return {
		"time_left": maxf(current_time_left, duration),
		"duration": maxf(current_duration, duration),
		"damage_taken_multiplier": maxf(current_damage_taken_multiplier, clampf(damage_taken_multiplier, 1.0, 4.0)),
	}

static func advance_flatfooted_state(time_left: float, duration: float, damage_taken_multiplier: float, delta: float) -> Dictionary:
	var next_time_left: float = maxf(time_left - delta, 0.0)
	if next_time_left <= 0.0:
		return {
			"time_left": 0.0,
			"duration": 0.0,
			"damage_taken_multiplier": 1.0,
		}
	return {
		"time_left": next_time_left,
		"duration": duration,
		"damage_taken_multiplier": damage_taken_multiplier,
	}

static func flatfooted_strength(time_left: float, duration: float) -> float:
	if time_left <= 0.0 or duration <= 0.0:
		return 0.0
	return clampf(time_left / duration, 0.0, 1.0)

static func flatfooted_damage_taken_multiplier(time_left: float, duration: float, damage_taken_multiplier: float) -> float:
	return lerpf(1.0, damage_taken_multiplier, flatfooted_strength(time_left, duration))