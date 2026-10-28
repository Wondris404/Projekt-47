extends RefCounted

const Traffic = preload("res://scripts/ui/transport_traffic.gd")

func run(u) -> void:
	u._new()
	var zero = Traffic.rail_plan(0.0, 20.0)
	var low_zoom = Traffic.rail_plan(1.0, 1.0)
	var light = Traffic.rail_plan(0.15, 12.0)
	var half = Traffic.rail_plan(0.5, 12.0)
	var full = Traffic.rail_plan(1.0, 12.0)
	var overload = Traffic.rail_plan(1.5, 12.0)
	var regional = Traffic.rail_plan(0.5, 4.0)
	u._chk("traffic_zero_has_no_train", not bool(zero.enabled) and int(zero.trains) == 0)
	u._chk("traffic_distant_lod_off", not bool(low_zoom.enabled))
	u._chk("traffic_load_increases_count", int(light.trains) == 1 and int(half.trains) == 2 and int(full.trains) == 3 and int(overload.trains) == 4)
	u._chk("traffic_fill_matches_load", is_equal_approx(float(light.fill), 0.15) and is_equal_approx(float(full.fill), 1.0))
	u._chk("traffic_overload_fill_clamped", is_equal_approx(float(overload.fill), 1.0))
	u._chk("traffic_detail_has_three_wagons", int(full.wagons) == 3)
	u._chk("traffic_regional_is_simplified", bool(regional.enabled) and int(regional.wagons) == 1)
