class_name BuildingSprites
extends RefCounted

const CAFE_ANIM_PATH = "res://assets/sprites/cafe_anim.png"
const FACTORY_ANIM_PATH = "res://assets/sprites/factory_anim.png"
const BANK_ANIM_PATH = "res://assets/sprites/bank_anim.png"

const FRAME_COUNT = 24
const FPS = 6.0

static var _cached_frames: Dictionary = {}

static func get_sprite_frames(kind: String) -> SpriteFrames:
	if _cached_frames.has(kind):
		return _cached_frames[kind]
	var path = ""
	match kind:
		"cafe":
			path = CAFE_ANIM_PATH
		"factory":
			path = FACTORY_ANIM_PATH
		"bank":
			path = BANK_ANIM_PATH
		_:
			return null
	if not ResourceLoader.exists(path):
		return null
	var tex = load(path) as Texture2D
	if tex == null:
		return null
	var sf = SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_speed("idle", FPS)
	sf.set_animation_loop("idle", true)
	for i in range(FRAME_COUNT):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(float(i) * 32.0, 0.0, 32.0, 32.0)
		sf.add_frame("idle", atlas)
	_cached_frames[kind] = sf
	return sf

static func create_animated_sprite(kind: String) -> AnimatedSprite2D:
	var frames = get_sprite_frames(kind)
	if frames == null:
		return null
	var spr = AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.animation = "idle"
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.play("idle")
	return spr
