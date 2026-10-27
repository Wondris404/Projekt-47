extends RefCounted

func run(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e7
	var err = GameState.found_firm("cafe", "Test personálu", "SK")
	u._chk("employment_firm_created", err == "", err)
	if err != "":
		return
	var firm: Dictionary = GameState.player_firms()[-1]
	var target = IndustrySystem.target_workers(firm)
	var people = IndustrySystem.target_headcount(firm)  # JUAN-P47: staty a zavislost pocitaju realnych ludi
	u._chk("employment_default_consistent", target > 0.0 and is_equal_approx(float(Empire.stats().employees), people))
	var population = float(GameState.world.SK.population)
	u._chk("employment_dependency_default", is_equal_approx(float(Empire.dependency("SK").emp_share), people / (population * 0.5)))
	firm.workers = 0.0
	u._chk("employment_zero_respected", float(Empire.stats().employees) == 0.0 and float(Empire.dependency("SK").emp_share) == 0.0)
	firm.workers = target * 0.5
	u._chk("employment_partial_respected", is_equal_approx(float(Empire.stats().employees), round(people * 0.5)))
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var load_error = GameState.from_dict(saved)
	u._chk("employment_save_v3", load_error == "" and int(saved.v) == 3 and is_equal_approx(float(Empire.stats().employees), round(people * 0.5)), load_error)
	u._new()
	GameState.player.cash = 1.0e7
	BankingSystem.found_player_bank("Zahraničná banka", "CZ")
	var bank: Dictionary = BankingSystem._player_bank()
	var err_loan = SovereignLoans.lend(bank, "SK", 100000.0, SovereignLoans.suggested_rate("SK"), 12)
	u._chk("dependency_sovereign_other_country", err_loan == "" and is_equal_approx(float(Empire.dependency("SK").loans), 100000.0), err_loan)
	u._chk("dependency_sovereign_not_home_country", float(Empire.dependency("CZ").loans) == 0.0)
