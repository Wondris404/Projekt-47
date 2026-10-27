extends Node2D
# JUAN20: Atlas mapa – zapecene dlazdice terenu (assets/atlas), kreslene POD krajinami (show_behind_parent).
# Cache: textury sa nacitaju lenivo raz a drzia sa v pamati (svet 2880x1440 + dlazdice 960x960 pre 30x30 stupnov).
const TEX = preload("res://scripts/ui/tex_util.gd")
const TILE_DEG = 30.0
var map: Control
var _world: Texture2D
var _tiles: Dictionary = {}  # "ix_iy" -> Texture2D alebo null (bez pevniny)
var _last := []
var tiles_drawn := 0
var load_ms := 0.0

func _ready() -> void:
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_process(true)

# JUAN23: vsetky dlazdice sa prednacitaju na pozadi (vlakna) hned po zapnuti Atlasu -> ziadne seknutie pri posune/zoome
var _pre_started := false
var _pending := {}  # key -> path (ResourceLoader threaded) alebo "img:"+path (dekodovanie vo WorkerThreadPool)
var _imgs := {}
var _mx := Mutex.new()

func _decode(key: String, path: String) -> void:
	var img = Image.new()
	var ok = img.load(ProjectSettings.globalize_path(path)) == OK
	_mx.lock()
	_imgs[key] = img if ok else null
	_mx.unlock()

func preload_all() -> void:
	if _pre_started:
		return
	_pre_started = true
	for iy in 6:
		for ix in 12:
			var key = "%d_%d" % [ix, iy]
			if _tiles.has(key):
				continue
			var p = "res://assets/atlas/t_%s.jpg" % key
			if ResourceLoader.exists(p):
				if ResourceLoader.load_threaded_request(p, "", false) == OK:
					_pending[key] = p
			elif FileAccess.file_exists(p):
				_pending[key] = "img:" + p
				WorkerThreadPool.add_task(_decode.bind(key, p))
			else:
				_tiles[key] = null

func _poll_preload() -> void:
	if _pending.is_empty():
		return
	var made = 0
	for key in _pending.keys():
		var p = str(_pending[key])
		if p.begins_with("img:"):
			_mx.lock()
			var has = _imgs.has(key)
			var img = _imgs.get(key)
			if has:
				_imgs.erase(key)
			_mx.unlock()
			if not has:
				continue
			_tiles[key] = ImageTexture.create_from_image(img) if img != null else null
		else:
			var stt = ResourceLoader.load_threaded_get_status(p)
			if stt == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				continue
			_tiles[key] = ResourceLoader.load_threaded_get(p) if stt == ResourceLoader.THREAD_LOAD_LOADED else null
		_pending.erase(key)
		made += 1
		if made >= 3:
			break
	if made > 0:
		queue_redraw()

func _process(_d: float) -> void:
	if map == null:
		return
	if map.atlas:
		preload_all()
		_poll_preload()
	var k = [map.atlas, map.zoom, map.pan, map.size]
	if k != _last:
		_last = k
		visible = map.atlas
		queue_redraw()

func _tex(ix: int, iy: int) -> Texture2D:
	var key = "%d_%d" % [ix, iy]
	if _pending.has(key):
		return null  # este sa nacitava na pozadi - pod nim je svetova textura
	if not _tiles.has(key):
		var t0 = Time.get_ticks_usec()
		var p = "res://assets/atlas/t_%s.jpg" % key
		_tiles[key] = TEX.load_tex(p) if FileAccess.file_exists(p) or ResourceLoader.exists(p) else null
		load_ms += float(Time.get_ticks_usec() - t0) / 1000.0
	return _tiles[key]

func _draw() -> void:
	tiles_drawn = 0
	if map == null or not map.atlas:
		return
	var mw = float(DataLoader.map.get("w", 1440))
	var mh = float(DataLoader.map.get("h", 720))
	draw_rect(Rect2(Vector2.ZERO, map.size), Color("12203A"))
	if _world == null:
		_world = TEX.load_tex("res://assets/atlas/world.jpg")
	var a = map._to_screen(Vector2.ZERO)
	var b = map._to_screen(Vector2(mw - 1.0, mh - 1.0))
	if _world:
		draw_texture_rect(_world, Rect2(a, b - a), false)
	var px_deg = (b.x - a.x) / 360.0
	if px_deg < 9.0:
		return
	var view = Rect2(Vector2.ZERO, map.size)
	for iy in 6:
		for ix in 12:
			var ta = map._to_screen(Vector2(ix * TILE_DEG / 360.0 * (mw - 1.0), iy * TILE_DEG / 180.0 * (mh - 1.0)))
			var tb = map._to_screen(Vector2((ix + 1) * TILE_DEG / 360.0 * (mw - 1.0), (iy + 1) * TILE_DEG / 180.0 * (mh - 1.0)))
			var r = Rect2(ta, tb - ta)
			if not r.intersects(view):
				continue
			var t = _tex(ix, iy)
			if t:
				draw_texture_rect(t, r, false)
				tiles_drawn += 1
