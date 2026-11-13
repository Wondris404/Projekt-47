extends RefCounted
# M02: svetové napätie 0–100 a DEFCON 5→1. Koeficienty v data/p47x_balance.json (ODHAD).

static func value(m) -> float:
	var row = m.peek("tension")
	return float(row.get("value", m.num("M02", "start", 15.0)))

static func by_iso(m, iso: String) -> float:
	return float(m.peek("tension").get("by_iso", {}).get(iso, 0.0))

static func defcon_of(m, v: float) -> int:
	return 5 - int(floor(clampf(v, 0.0, 99.9) / maxf(m.num("M02", "defcon_step", 20.0), 1.0)))

static func defcon(m) -> int:
	return defcon_of(m, value(m))

static func _row(m) -> Dictionary:
	var row = m.state("tension")
	if not row.has("value"):
		row["value"] = m.num("M02", "start", 15.0)
		row["by_iso"] = {}
		row["log"] = []
		row["defcon"] = defcon_of(m, float(row.value))
	return row

static func add(m, amount: float, iso: String, reason: String) -> void:
	var row = _row(m)
	var before = int(row.get("defcon", defcon_of(m, float(row.value))))
	row.value = clampf(float(row.value) + amount, 0.0, 100.0)
	if iso != "":
		row.by_iso[iso] = clampf(float(row.by_iso.get(iso, 0.0)) + amount, 0.0, 100.0)
	var log: Array = row.log
	log.append({"day": GameState.day_index, "delta": amount, "iso": iso, "reason": reason})
	while log.size() > int(m.num("M02", "log_max", 24)):
		log.pop_front()
	_defcon_news(m, row, before)

static func _defcon_news(m, row: Dictionary, before: int) -> void:
	var now = defcon_of(m, float(row.value))
	row["defcon"] = now
	if now == before:
		return
	GameState.post_news("DEFCON %d (svetové napätie %.0f)." % [now, float(row.value)], "politika")
	if now == 1 and before > 1:
		GameState.post_news("Jadrová kríza: svet je na pokraji jadrovej vojny.", "politika")

static func monthly(m) -> void:
	var row = _row(m)
	var before = int(row.get("defcon", 5))
	row.value = maxf(0.0, float(row.value) * (1.0 - m.num("M02", "decay_month", 0.04)))
	var keep: Dictionary = {}
	for iso in row.by_iso.keys():
		var v = float(row.by_iso[iso]) * (1.0 - m.num("M02", "iso_decay_month", 0.035))
		if v > 0.01:
			keep[iso] = v
	row.by_iso = keep
	_defcon_news(m, row, before)

static func action_amount(m, action: String) -> float:
	match action:
		"war":
			return m.num("M02", "war", 12.0)
		"embargo":
			return m.num("M02", "embargo", 3.0)
		"sanction":
			return m.num("M02", "sanction", 2.0)
		"un":
			return m.num("M02", "security_council", 4.0)
	return 0.0

static func would_lower_defcon(m, action: String) -> bool:
	var amount = action_amount(m, action)
	return amount > 0.0 and defcon_of(m, value(m) + amount) < defcon(m)

static func demand_mult(m, cid: String) -> float:
	if not (cid in ["arms", "weapons", "chemicals", "pmc_services", "pmc"]):
		return 1.0
	return 1.0 + float(5 - defcon(m)) * m.num("M02", "arms_demand_per_level", 0.08)

static func breakdown(m) -> Array:
	var parts: Array = [{"label": "Štart", "value": m.num("M02", "start", 15.0)}]
	for item in m.peek("tension").get("log", []):
		parts.append({"label": str(item.get("reason", "")), "value": float(item.get("delta", 0.0))})
	return parts
