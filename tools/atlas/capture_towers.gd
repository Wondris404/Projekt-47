extends SceneTree
const OUT := "res://docs/atlas-towers-proposal/"

class Board extends Control:
	var font: Font = load("res://assets/fonts/NotoSans-Regular.ttf")
	var textures := {}
	var kinds := ["bank","casino","hotel"]
	var names := ["BANKA", "KASÍNO", "HOTEL"]
	var subtitles := ["Finančná veža · stupňovitá koruna", "Dvojvežový rezort · zlato a neón", "Výškový hotel · balkóny a strešný bazén"]
	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		for kind in kinds:
			for level in range(1,4):
				var key := "%s_%d" % [kind,level]
				textures[key] = ImageTexture.create_from_image(Image.load_from_file(OUT+"sprites/"+key+".png"))
	func sprite(kind: String, level: int, pos: Vector2, width: float) -> void:
		draw_texture_rect(textures["%s_%d" % [kind,level]],Rect2(pos,Vector2(width,width*72.0/64.0)),false)
	func _draw() -> void:
		draw_rect(Rect2(0,0,1440,840),Color("101f27"))
		draw_string(font,Vector2(30,40),"PROJEKT-47  /  NÁVRH VÝŠKOVÝCH BUDOV",HORIZONTAL_ALIGNMENT_LEFT,1380,26,Color("e7ddc2"))
		draw_string(font,Vector2(30,68),"Tri odlišné siluety · spoločná mierka · návrh na kontrolu",HORIZONTAL_ALIGNMENT_LEFT,1380,17,Color("a0b4b8"))
		for i in 3:
			var x := i*480.0
			draw_rect(Rect2(x+16,90,448,726),Color("22343b"))
			draw_string(font,Vector2(x+36,130),names[i],HORIZONTAL_ALIGNMENT_LEFT,410,25,Color("e3b45b"))
			draw_string(font,Vector2(x+36,158),subtitles[i],HORIZONTAL_ALIGNMENT_LEFT,410,15,Color("c8d4d5"))
			sprite(kinds[i],3,Vector2(x+112,175),256)
			draw_string(font,Vector2(x+36,492),"Vývoj budovy — úrovne 1 / 2 / 3",HORIZONTAL_ALIGNMENT_LEFT,410,16,Color("dce5df"))
			for level in range(1,4):
				var bx := x+42+(level-1)*134
				sprite(kinds[i],level,Vector2(bx,513),112)
				draw_string(font,Vector2(bx+20,662),"Úroveň %d" % level,HORIZONTAL_ALIGNMENT_LEFT,100,14,Color("b5c6c8"))
			draw_line(Vector2(x+36,687),Vector2(x+440,687),Color("48616a"),1)
			for j in 3:
				var width: float = [24,32,48][j]
				var bx := x+80+j*136
				sprite(kinds[i],3,Vector2(bx,759-width*72/64),width)
				draw_string(font,Vector2(bx-2,787),"%d px" % int(width),HORIZONTAL_ALIGNMENT_LEFT,80,13,Color("c8d4d5"))

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1440,840)
	root.content_scale_size = Vector2i(1440,840)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var board := Board.new()
	root.add_child(board)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var err := img.save_png(ProjectSettings.globalize_path(OUT+"navrh.png"))
	for i in 3:
		img.get_region(Rect2i(i*480,90,480,735)).save_png(ProjectSettings.globalize_path(OUT+board.kinds[i]+".png"))
	print("P47_TOWERS_CAPTURE ",err," renderer=",RenderingServer.get_video_adapter_name())
	quit(0 if err == OK else 1)
