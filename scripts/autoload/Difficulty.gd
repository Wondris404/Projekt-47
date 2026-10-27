extends Node
# JUAN4: obtiaznost hry. Ulozena v GameState.config.difficulty (stary save bez kluca = "medium" = neutralne cisla).
# cash      = startovacia hotovost hraca (EUR, pripocita sa pri novej hre)
# cost      = nasobok ceny zalozenia firmy / stavby
# event     = nasobok frekvencie nahodnych udalosti (EventSystem.monthly, zaklad 8 % mesacne)
# severity  = nasobok sily udalosti (zmena rastu HDP / inflacie)
# ai        = agresivita AI: AI vojny (sanca), AI konkurenti (expanzia, cenove vojny)
# rate_add  = prirazka k urokom uverov pre hraca (p.b.)
const MODES = {
	"easy":      {"name": "Easy",      "cash": 400000.0, "cost": 0.80, "event": 0.50, "severity": 0.60, "ai": 0.60, "rate_add": -0.010, "wars": false},
	"tutorial":  {"name": "Tutoriál",  "cash": 200000.0, "cost": 0.90, "event": 0.50, "severity": 0.70, "ai": 0.70, "rate_add": -0.005, "wars": false},
	"medium":    {"name": "Medium",    "cash": 150000.0, "cost": 1.00, "event": 1.00, "severity": 1.00, "ai": 1.00, "rate_add": 0.000, "wars": true},
	"hard":      {"name": "Hard",      "cash": 50000.0,  "cost": 1.25, "event": 1.60, "severity": 1.40, "ai": 1.50, "rate_add": 0.015, "wars": true},
	"realistic": {"name": "Realistic", "cash": 0.0,      "cost": 1.10, "event": 1.30, "severity": 1.20, "ai": 1.30, "rate_add": 0.010, "wars": true},
}
const ORDER = ["easy", "tutorial", "medium", "hard", "realistic"]

func mode() -> String:
	var m = str(GameState.config.get("difficulty", "medium"))
	return m if MODES.has(m) else "medium"

func p(key: String) -> float:
	return float(MODES[mode()].get(key, 1.0))

func cost_mult() -> float:
	return p("cost")

func event_mult() -> float:
	return p("event")

func severity() -> float:
	return p("severity")

func ai_mult() -> float:
	return p("ai")

func rate_add() -> float:
	return p("rate_add")

func start_cash(m: String) -> float:
	return float(MODES.get(m, MODES.medium).cash)

func describe(m: String) -> String:
	var r: Dictionary = MODES.get(m, MODES.medium)
	return "%s: štart %s, ceny ×%.2f, udalosti ×%.1f (sila ×%.1f), AI ×%.1f, úroky %+.1f p.b." % [r.name, EconMath.eur(float(r.cash)), float(r.cost), float(r.event), float(r.severity), float(r.ai), float(r.rate_add) * 100.0]
