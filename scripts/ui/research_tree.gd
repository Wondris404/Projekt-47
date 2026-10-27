extends Control

func _ready() -> void:
	custom_minimum_size = Vector2(280, 160)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var projects: Array = DataLoader.research
	var pos = {}
	var i = 0
	for row in projects:
		var x = 16.0 + float(i % 4) * 68.0
		var y = 18.0 + float(i / 4) * 70.0
		pos[str(row.get("id", ""))] = Vector2(x, y)
		i += 1
	for edge in GameState.research_edges():
		var a: Vector2 = pos.get(str(edge.get("from", "")), Vector2.ZERO)
		var b: Vector2 = pos.get(str(edge.get("to", "")), Vector2.ZERO)
		if a != Vector2.ZERO and b != Vector2.ZERO:
			draw_line(a + Vector2(24, 10), b + Vector2(24, 10), UiPalette.BORDER_HI, 2.0, false)
	var done = GameState.player.get("done", [])
	if typeof(done) != TYPE_ARRAY:
		done = []
	var research = GameState.player.get("research", {})
	if typeof(research) != TYPE_DICTIONARY:
		research = {}
	for row in projects:
		var p: Vector2 = pos[str(row.get("id", ""))]
		var col = UiPalette.BG_2
		if str(row.get("id", "")) in done:
			col = UiPalette.OK
		elif str(research.get("id", "")) == str(row.get("id", "")):
			col = UiPalette.ACCENT_DIM
		draw_rect(Rect2(p, Vector2(56, 22)), col)
		draw_rect(Rect2(p, Vector2(56, 22)), UiPalette.ACCENT, false, 1.0)
