extends RefCounted
const GROUPS := {"Energia":["electricity","coal","crude_oil","natural_gas","fuel"],"Suroviny":["iron_ore","copper","wheat","coffee","meat"],"Polotovary":["steel","chemicals","textiles"],"Výrobky":["electronics","pharma","automobiles","weapons","arms","ships","aircraft","construction","logistics","food_service","finance","pmc","pmc_services","compute","ai_services"]}
var revision := -1
var day := -1
var previous: Dictionary = {}
var current: Dictionary = {}
var delta: Dictionary = {}
var interval := 0

static func number(value: float, digits: int = 1) -> String:
	return (str(int(round(value))) if is_equal_approx(value,round(value)) else ("%.*f" % [digits,value])).replace(".",",")

static func compact(value: float, money: bool = false) -> String:
	var amount := value
	var suffix := ""
	for pair in [[1e9," mld."],[1e6," mil."],[1e3," tis."]]:
		if absf(value)>=pair[0]:
			amount = value/pair[0]
			suffix = pair[1]
			break
	return number(amount,4 if absf(amount)<.001 else (3 if absf(amount)<.1 else (2 if absf(amount)<1.0 else 1)))+suffix+(" €" if money else "")

func sample(values: Dictionary, at_day: int, at_revision: int) -> void:
	if revision != at_revision or at_day < day:
		revision = at_revision
		day = at_day
		previous.clear()
		current = values.duplicate()
		delta.clear()
		interval = 0
		return
	if at_day != day:
		previous = current.duplicate()
		interval = at_day-day
		day = at_day
	current = values.duplicate()
	if not previous.is_empty():
		for key in values: delta[key] = float(values[key])-float(previous.get(key,values[key]))

func trend_text(key: String, money: bool = false) -> String:
	if not delta.has(key): return "Denná zmena: zatiaľ nemeraná; dostupná po uzavretí dňa."
	var value := float(delta[key])
	return "Zmena za %d %s: %s%s" % [interval,"deň" if interval==1 else "dní","+" if value>0 else "",compact(value,money)]

static func values() -> Dictionary:
	var data := Empire.stats()
	data["debt"] = GameState.debt()
	return data

static func sources(key: String) -> String:
	match key:
		"cash": return "Osobná hotovosť hráča: %s.\nFiremné účty sú oddelené; dividendy sa pripisujú pri mesačnej výplate." % EconMath.eur(float(GameState.player.get("cash",0)))
		"debt": return "Zostávajúca istina %d osobných úverov: %s.\nVydané dlhopisy sa zohľadňujú osobitne v čistom majetku." % [GameState.player.get("loans",[]).size(),EconMath.eur(GameState.debt())]
		"worth":
			var firm_cash := 0.0
			var assets := 0.0
			for f in GameState.player_firms():
				firm_cash += float(f.get("cash",0))
				if not f.facilities.is_empty(): assets += float(DataLoader.industries.get(f.industry,{}).get("cost",0))*.45*float(f.facilities[0].get("scale",1))
			return "Čistý majetok: %s\nOsobná hotovosť %s; firemná hotovosť %s; odhad prevádzok %s.\nĎalej kapitál bánk, dlhopisy, akcie, nehnuteľnosti, finančné divízie a vinkulované peniaze; odpočítané osobné úvery a vlastné vydané dlhopisy." % [EconMath.eur(GameState.net_worth()),EconMath.eur(float(GameState.player.cash)),EconMath.eur(firm_cash),EconMath.eur(assets)]
		"employees": return "Súčet skutočného počtu zamestnancov aktívnych vlastných firiem a %d bankových pobočiek. Obsadenosť podľa workers/target_workers a personálu receptov." % BankingSystem.player_banks().size()
		"influence":
			var rows: Array[String] = []
			for iso in PoliticsSystem.influence_map():
				var amount := float(PoliticsSystem.influence(str(iso)))
				if amount>0: rows.append("%s: %s" % [str(GameState.world.get(iso,{}).get("name_sk",iso)),number(amount)])
			return "Súčet politického vplyvu v krajinách.\n"+("Zatiaľ bez vplyvu." if rows.is_empty() else "\n".join(rows.slice(0,8)))+("\nĎalších %d krajín; úplný zoznam: Vplyv." % (rows.size()-8) if rows.size()>8 else "")
		"popularity": return "Hodnotenie hráča (player.rating), rozsah 0–100. Mení ho charita a herné politické udalosti."
		"security":
			var count := 0
			for f in GameState.player_firms():
				if f.industry in ["pmc_unit","arms_plant"]: count += 1
			return "%d bezpečnostných/zbrojárskych podnikov × 10 bodov + %d bodov z bonusu PMC." % [count,int(PoliticsSystem.bonus_sum("pmc")*100)]
		"firms": return "%d aktívnych vlastných podnikov; zatvorené firmy sa nepočítajú. Bankové pobočky sú oddelené." % GameState.player_firms().size()
		"states": return "Vlastnené štáty: "+(", ".join(Empire.st().states.slice(0,12)) if not Empire.st().states.is_empty() else "žiadne")+(" · ďalších %d (Portfólio)." % (Empire.st().states.size()-12) if Empire.st().states.size()>12 else "")
	return ""

static func roles(cid: String) -> Dictionary:
	var result := {}
	for f in GameState.player_firms():
		var role := 0
		for fac in f.get("facilities",[]):
			var recipe: Dictionary = DataLoader.recipes.get(str(fac.get("recipe","")),{})
			if recipe.get("outputs",{}).has(cid): role |= 1
			if recipe.get("inputs",{}).has(cid): role |= 2
		if role: result[str(f.id)] = role
	return result

static func resources() -> Dictionary:
	var ledger: Dictionary = IndustrySystem.hud_resources
	var known := int(ledger.get("revision",-1))==GameState.state_revision and int(ledger.get("day",-2))==GameState.day_index-1
	var stock := {}
	for f in GameState.player_firms():
		for fac in f.get("facilities",[]):
			for cid in fac.get("inventory",{}): stock[cid] = float(stock.get(cid,0))+float(fac.inventory[cid])
	var rows := {}
	for cid in DataLoader.commodities:
		var made := float(ledger.get("produced",{}).get(cid,0)) if known else 0.0
		var used := float(ledger.get("consumed",{}).get(cid,0)) if known else 0.0
		rows[cid] = {"produced":made,"consumed":used,"balance":made-used,"stock":float(stock.get(cid,0)),"price":MarketSystem.price(GameState.selected_iso,cid),"demand":float(ledger.get("demand",{}).get(cid,0)) if known else 0.0}
	return {"known":known,"rows":rows,"country":GameState.selected_iso}

static func power(rows: Dictionary, known: bool) -> Dictionary:
	var row: Dictionary = rows.get("electricity",{})
	var made := float(row.get("produced",0))/24.0
	var used := float(row.get("consumed",0))/24.0
	var need := float(row.get("demand",0))/24.0
	var ratio := made/need if need>0.0 else 1.0
	return {"made":made,"used":used,"need":need,"ratio":ratio,"state":"unknown" if not known else ("idle" if need<=0.0 else ("ok" if ratio>=1.0 else ("warning" if ratio>=.9 else "deficit")))}
