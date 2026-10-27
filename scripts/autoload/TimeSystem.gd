extends Node

const MD = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

func roll() -> void:
	var y: int = int(GameState.date.y)
	var m: int = int(GameState.date.m)
	var d: int = int(GameState.date.d)
	var dim = MD[m - 1]
	if m == 2 and _leap(y):
		dim = 29
	d += 1
	if d > dim:
		d = 1
		m += 1
		if m > 12:
			m = 1
			y += 1
	GameState.date.y = y
	GameState.date.m = m
	GameState.date.d = d

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func leap(y: int) -> bool:
	return _leap(y)

func _leap(y: int) -> bool:
	return (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)

func yday(y: int, m: int, d: int) -> int:
	var n = d
	for i in range(m - 1):
		n += MD[i]
		if i == 1 and _leap(y):
			n += 1
	return n

func season_index(lat: float) -> int:
	var m: int = int(GameState.date.m)
	var north = 0
	if m == 12 or m <= 2:
		north = 0
	elif m <= 5:
		north = 1
	elif m <= 8:
		north = 2
	else:
		north = 3
	if lat < 0.0:
		return (north + 2) % 4
	return north

func dow() -> int:
	return GameState.day_index % 7

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func is_month_start() -> bool:
	return int(GameState.date.d) == 1 and GameState.day_index > 0

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func is_year_start() -> bool:
	return int(GameState.date.d) == 1 and int(GameState.date.m) == 1 and GameState.day_index > 0

func easter(year: int) -> Dictionary:
	var a = year % 19
	var b = int(year / 100.0)
	var c = year % 100
	var d = int(b / 4.0)
	var e = b % 4
	var f = int((b + 8) / 25.0)
	var g = int((b - f + 1) / 3.0)
	var h = (19 * a + b - d - g + 15) % 30
	var i = int(c / 4.0)
	var k = c % 4
	var l = (32 + 2 * e + 2 * i - h - k) % 7
	var m = int((a + 11 * h + 22 * l) / 451.0)
	var month = int((h + l - 7 * m + 114) / 31.0)
	var day = ((h + l - 7 * m + 114) % 31) + 1
	return {"m": month, "d": day}

func orthodox_easter(year: int) -> Dictionary:
	var a = year % 4
	var b = year % 7
	var c = year % 19
	var d = (19 * c + 15) % 30
	var e = (2 * a + 4 * b - d + 34) % 7
	var month = int((d + e + 114) / 31.0)
	var day = ((d + e + 114) % 31) + 1
	return _add(year, month, day, 13)

func _add(y: int, m: int, d: int, extra: int) -> Dictionary:
	var dim = MD[m - 1]
	if m == 2 and _leap(y):
		dim = 29
	d += extra
	while d > dim:
		d -= dim
		m += 1
		if m > 12:
			m = 1
			y += 1
		dim = MD[m - 1]
		if m == 2 and _leap(y):
			dim = 29
	return {"y": y, "m": m, "d": d}

func within_md(month: int, day: int, length: int) -> bool:
	var y: int = int(GameState.date.y)
	var start = yday(y, month, day)
	var now = yday(y, int(GameState.date.m), int(GameState.date.d))
	var span = now - start
	if span < 0:
		span += 365 + (1 if _leap(y) else 0)
	return span >= 0 and span < length
