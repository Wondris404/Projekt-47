extends Node

func cl(v: float, a: float, b: float) -> float:
	return clampf(v, a, b)

func annuity(principal: float, annual_rate: float, days: int) -> float:
	if principal <= 0.0:
		return 0.0
	if days <= 0:
		return principal
	if annual_rate <= 0.0000001:
		return principal / float(days)
	var r = annual_rate / 365.0
	var g = pow(1.0 + r, float(days))
	return principal * (r * g) / (g - 1.0)

func haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var r = 6371.0
	var p1 = deg_to_rad(lat1)
	var p2 = deg_to_rad(lat2)
	var dp = deg_to_rad(lat2 - lat1)
	var dl = deg_to_rad(lon2 - lon1)
	var s = sin(dp * 0.5)
	var t = sin(dl * 0.5)
	var h = s * s + cos(p1) * cos(p2) * t * t
	return 2.0 * r * asin(min(1.0, sqrt(h)))

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func lerp_f(a: float, b: float, t: float) -> float:
	return lerpf(a, b, t)

func rich_index(gdp_pc_usd: float) -> float:
	var lo = log(2000.0)
	var hi = log(70000.0)
	return cl((log(max(gdp_pc_usd, 500.0)) - lo) / (hi - lo), 0.0, 1.0)

func eur(v: float) -> String:
	var n = int(round(v))
	var sign = "-" if n < 0 else ""
	var s = str(absi(n))
	var out = ""
	while s.length() > 3:
		out = " " + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return sign + s + out + " €"

func pct(v: float) -> String:
	return str(snapped(v * 100.0, 0.01)) + " %"

func date_sk(y: int, m: int, d: int) -> String:
	return "%02d.%02d.%04d" % [d, m, y]

func is_bad(v: float) -> bool:
	return is_nan(v) or is_inf(v)
