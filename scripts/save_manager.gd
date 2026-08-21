class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://market_pulse_save.json"
static var launch_mode: String = "new"


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func delete_save() -> void:
	if not has_save():
		return
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.remove("market_pulse_save.json")


static func save_game(portfolio: Portfolio, market: MarketSimulator) -> void:
	var holdings: Dictionary = {}
	for symbol in portfolio.holdings:
		holdings[str(symbol)] = int(portfolio.holdings[symbol])

	var avg_cost: Dictionary = {}
	for symbol in portfolio.avg_cost:
		avg_cost[str(symbol)] = float(portfolio.avg_cost[symbol])

	var prices: Dictionary = {}
	for symbol in MarketSimulator.SYMBOL_ORDER:
		if market.stocks.has(symbol):
			prices[symbol] = market.stocks[symbol].price

	var data := {
		"version": 1,
		"cash": portfolio.cash,
		"holdings": holdings,
		"avg_cost": avg_cost,
		"days_played": portfolio.days_played,
		"total_commissions": portfolio.total_commissions,
		"stock_prices": prices,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file.")
		return
	file.store_string(JSON.stringify(data))


static func load_game() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func apply_to(portfolio: Portfolio, market: MarketSimulator, data: Dictionary) -> void:
	portfolio.apply_save(data)
	if data.has("stock_prices") and typeof(data["stock_prices"]) == TYPE_DICTIONARY:
		market.apply_saved_prices(data["stock_prices"])


static func summary_text() -> String:
	var data := load_game()
	if data.is_empty():
		return "No saved game"
	var cash: float = float(data.get("cash", 0.0))
	var days: int = int(data.get("days_played", 0))
	return "Day %d  ·  Cash $%.2f" % [days, cash]
