extends "res://tests/atlas_style_capture.gd"

func run(main: Node) -> void:
	OUT = "res://docs/atlas-city-scale/"
	views = [["stredna_europa",17.1,48.15,42.0],["vieden_bratislava",16.75,48.19,160.0],["pariz",2.35,48.85,120.0],["tokio",139.75,35.68,100.0]]
	await super.run(main)
