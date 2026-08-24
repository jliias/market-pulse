class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://market_pulse_save.json"
static var launch_mode: String = "new"
static var pending_watchlist: Array[String] = []
static var left_at: float = 0.0
static var pending_away_hours: float = 0.0
const AWAY_GAP_HOURS := 8.0


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
	for symbol in market.watchlist:
		if market.stocks.has(symbol):
			prices[symbol] = market.stocks[symbol].price

	var data := {
		"version": 7,
		"watchlist": market.watchlist.duplicate(),
		"cash": portfolio.cash,
		"holdings": holdings,
		"avg_cost": avg_cost,
		"days_played": portfolio.days_played,
		"total_commissions": portfolio.total_commissions,
		"stock_prices": prices,
		"event_chains": market.chain_director.serialize(),
		"regime": market.regime.serialize(),
		"last_equity": portfolio.last_equity,
		"last_alpha": portfolio.last_alpha,
		"equity_ath": portfolio.equity_ath,
		"beat_streak": portfolio.beat_streak,
		"best_beat_streak": portfolio.best_beat_streak,
		"best_alpha": portfolio.best_alpha,
		"worst_alpha": portfolio.worst_alpha,
		"has_alpha_stats": portfolio.has_alpha_stats,
		"chapter_open_equity": portfolio.chapter_open_equity,
		"chapter_alpha_sum": portfolio.chapter_alpha_sum,
		"chapter_beats": portfolio.chapter_beats,
		"chapter_days": portfolio.chapter_days,
		"pending_chapter": portfolio.pending_chapter,
		"left_at": left_at,
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
	market.set_watchlist(watchlist_from_save(data))
	portfolio.apply_save(data)
	if data.has("stock_prices") and typeof(data["stock_prices"]) == TYPE_DICTIONARY:
		market.apply_saved_prices(data["stock_prices"])
	if data.has("event_chains") and typeof(data["event_chains"]) == TYPE_DICTIONARY:
		market.chain_director.deserialize(data["event_chains"])
	else:
		market.chain_director.reset()
	market.chain_director.prune_to_universe(market.watchlist, market.get_stock_list())
	if data.has("regime") and typeof(data["regime"]) == TYPE_DICTIONARY:
		market.regime.deserialize(data["regime"])
	else:
		market.regime.reset()
	if not data.has("last_equity"):
		portfolio.last_equity = portfolio.get_portfolio_value(market.stocks)
		portfolio.equity_ath = maxf(portfolio.equity_ath, portfolio.last_equity)
	left_at = float(data.get("left_at", 0.0))
	pending_away_hours = hours_away()
	if pending_away_hours < AWAY_GAP_HOURS:
		pending_away_hours = 0.0
		left_at = 0.0


static func stamp_left_desk() -> void:
	left_at = Time.get_unix_time_from_system()


static func clear_away() -> void:
	left_at = 0.0
	pending_away_hours = 0.0


static func hours_away() -> float:
	if left_at <= 0.0:
		return 0.0
	return (Time.get_unix_time_from_system() - left_at) / 3600.0


static func is_away_due(data: Dictionary = {}) -> bool:
	var stamp: float = left_at
	if not data.is_empty():
		stamp = float(data.get("left_at", 0.0))
	if stamp <= 0.0:
		return false
	return (Time.get_unix_time_from_system() - stamp) / 3600.0 >= AWAY_GAP_HOURS


static func watchlist_from_save(data: Dictionary) -> Array[String]:
	if data.has("watchlist") and typeof(data["watchlist"]) == TYPE_ARRAY:
		return CompanyCatalog.sanitize_watchlist(data["watchlist"])
	if data.has("stock_prices") and typeof(data["stock_prices"]) == TYPE_DICTIONARY:
		return CompanyCatalog.sanitize_watchlist((data["stock_prices"] as Dictionary).keys())
	return CompanyCatalog.DEFAULT_WATCHLIST.duplicate()


static func summary_text() -> String:
	var data := load_game()
	if data.is_empty():
		return "No saved game yet."
	return "\n".join(cliffhanger_lines(data))


static func equity_from_save(data: Dictionary) -> float:
	if data.has("last_equity"):
		return float(data["last_equity"])
	var cash: float = float(data.get("cash", 0.0))
	var holdings: Variant = data.get("holdings", {})
	var prices: Variant = data.get("stock_prices", {})
	if typeof(holdings) != TYPE_DICTIONARY or typeof(prices) != TYPE_DICTIONARY:
		return cash
	var total: float = cash
	for symbol in holdings:
		total += float(holdings[symbol]) * float((prices as Dictionary).get(symbol, 0.0))
	return total


static func cliffhanger_lines(data: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var days: int = int(data.get("days_played", 0))
	var equity: float = equity_from_save(data)
	var ath: float = float(data.get("equity_ath", equity))
	lines.append("Day %d  ·  Book $%.0f  ·  ATH $%.0f" % [days, equity, maxf(ath, equity)])

	var watch: Variant = data.get("watchlist", [])
	if typeof(watch) == TYPE_ARRAY and not (watch as Array).is_empty():
		var names: PackedStringArray = []
		for item in watch:
			names.append(str(item))
		lines.append("Watchlist  %s" % ", ".join(names))

	var climate_bit: String = _climate_line(data)
	var streak_bit: String = _streak_line(data)
	if climate_bit.is_empty():
		lines.append(streak_bit)
	else:
		lines.append("%s  ·  %s" % [climate_bit, streak_bit])

	var hook: String = EventChainDirector.hook_from_save(data.get("event_chains", {}))
	if hook.is_empty():
		hook = "No open story on the board."
	lines.append(hook)

	if bool(data.get("has_alpha_stats", false)):
		lines.append("Last close  %+.1f%% vs tape" % float(data.get("last_alpha", 0.0)))
	if is_away_due(data):
		lines.append("The desk has been dark. Overnight risk is in play.")
	return lines


static func _climate_line(data: Dictionary) -> String:
	var regime: Variant = data.get("regime", {})
	if typeof(regime) != TYPE_DICTIONARY:
		return ""
	var climate: String = str((regime as Dictionary).get("climate", "normal"))
	var days_left: int = int((regime as Dictionary).get("climate_days", 0))
	match climate:
		"bull":
			if days_left > 0:
				return "BULL MARKET (%d days left)" % days_left
			return "BULL MARKET"
		"bear":
			if days_left > 0:
				return "BEAR MARKET (%d days left)" % days_left
			return "BEAR MARKET"
		_:
			return "NORMAL TAPE"


static func _streak_line(data: Dictionary) -> String:
	var streak: int = int(data.get("beat_streak", 0))
	var best: int = int(data.get("best_beat_streak", 0))
	if streak > 0:
		if best > streak:
			return "%d days ahead of the tape (best %d)" % [streak, best]
		return "%d days ahead of the tape" % streak
	if best > 0:
		return "Streak broken  ·  best was %d days" % best
	return "No beat-the-market streak yet"
