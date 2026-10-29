extends RefCounted
## Presentation only. No RNG, game time, save fields or simulation mutations.
const DURATION := 0.55
var active: Dictionary = {}
var revision := -1

static func still(level: int) -> Array:
	var result := [0.0, 0.0, 0.0]
	result[clampi(level, 1, 3) - 1] = 1.0
	return result

func sync_revision(value: int) -> void:
	if revision != value:
		active.clear()
		revision = value

func weights(id: String, level: int) -> Array:
	if not active.has(id):
		return still(level)
	var state: Dictionary = active[id]
	# A load, direct edit or removed/reused firm must not animate stale levels.
	if int(state.target) != clampi(level, 1, 3):
		active.erase(id)
		return still(level)
	var t := clampf(float(state.elapsed) / DURATION, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	var target := still(level)
	var result: Array = []
	for i in 3:
		result.append(lerpf(float(state.start[i]), float(target[i]), t))
	return result

func begin(id: String, old_level: int, new_level: int) -> void:
	var start := weights(id, old_level)
	active[id] = {"start": start, "target": clampi(new_level, 1, 3), "elapsed": 0.0}

func advance(delta: float) -> bool:
	var changed := not active.is_empty()
	for id in active.keys():
		active[id].elapsed += maxf(delta, 0.0)
		if float(active[id].elapsed) >= DURATION:
			active.erase(id)
	return changed
