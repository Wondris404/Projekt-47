extends RefCounted
# Testy voliteľných mechaník Projekt-47 experimental 1.0.

func run(u) -> void:
	load("res://tests/p47x_m44.gd").new().run(u)
	load("res://tests/p47x_m12.gd").new().run(u)
	load("res://tests/p47x_m09.gd").new().run(u)
	load("res://tests/p47x_m02.gd").new().run(u)
	load("res://tests/p47x_m03.gd").new().run(u)
