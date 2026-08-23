class_name Portfolio
extends RefCounted

const STARTING_CASH := 10000.0
const FIXED_COMMISSION := 2.0
const PERCENT_COMMISSION := 0.002

var cash: float = STARTING_CASH
var holdings: Dictionary = {}
var avg_cost: Dictionary = {}
var trade_history: Array[Dictionary] = []
var total_commissions: float = 0.0
var day_start_value: float = STARTING_CASH
var days_played: int = 0
var last_equity: float = STARTING_CASH
var last_alpha: float = 0.0
var equity_ath: float = STARTING_CASH
var beat_streak: int = 0
var best_beat_streak: int = 0
var best_alpha: float = 0.0
var worst_alpha: float = 0.0
var has_alpha_stats: bool = false


func reset_new_game() -> void:
	cash = STARTING_CASH
	holdings.clear()
	avg_cost.clear()
	trade_history.clear()
	total_commissions = 0.0
	day_start_value = STARTING_CASH
	days_played = 0
	last_equity = STARTING_CASH
	last_alpha = 0.0
	equity_ath = STARTING_CASH
	beat_streak = 0
	best_beat_streak = 0
	best_alpha = 0.0
	worst_alpha = 0.0
	has_alpha_stats = false


func apply_save(data: Dictionary) -> void:
	cash = float(data.get("cash", STARTING_CASH))
	days_played = int(data.get("days_played", 0))
	total_commissions = float(data.get("total_commissions", 0.0))
	holdings.clear()
	avg_cost.clear()
	var saved_holdings: Variant = data.get("holdings", {})
	if typeof(saved_holdings) == TYPE_DICTIONARY:
		for symbol in saved_holdings:
			holdings[str(symbol)] = int(saved_holdings[symbol])
	var saved_avg: Variant = data.get("avg_cost", {})
	if typeof(saved_avg) == TYPE_DICTIONARY:
		for symbol in saved_avg:
			avg_cost[str(symbol)] = float(saved_avg[symbol])
	day_start_value = cash
	last_equity = float(data.get("last_equity", cash))
	last_alpha = float(data.get("last_alpha", 0.0))
	equity_ath = float(data.get("equity_ath", maxf(last_equity, STARTING_CASH)))
	beat_streak = int(data.get("beat_streak", 0))
	best_beat_streak = int(data.get("best_beat_streak", beat_streak))
	best_alpha = float(data.get("best_alpha", 0.0))
	worst_alpha = float(data.get("worst_alpha", 0.0))
	has_alpha_stats = bool(data.get("has_alpha_stats", false))


func get_avg_cost(symbol: String) -> float:
	return float(avg_cost.get(symbol, 0.0))


func get_shares(symbol: String) -> int:
	return int(holdings.get(symbol, 0))


func get_position_pl(symbol: String, current_price: float) -> float:
	return (current_price - get_avg_cost(symbol)) * float(get_shares(symbol))


func max_buyable(ask_price: float) -> int:
	if ask_price <= 0.0:
		return 0
	return maxi(int((cash - FIXED_COMMISSION) / (ask_price * (1.0 + PERCENT_COMMISSION))), 0)


func estimate(shares: int, price: float) -> Dictionary:
	var trade_value: float = float(shares) * price
	var commission: float = calculate_commission(trade_value) if shares > 0 else 0.0
	return {
		"trade_value": trade_value,
		"commission": commission,
		"total": trade_value + commission,
		"proceeds": trade_value - commission,
	}


func get_holdings_value(stocks: Dictionary) -> float:
	var total := 0.0
	for symbol in holdings:
		if stocks.has(symbol):
			total += holdings[symbol] * stocks[symbol].price
	return total


func get_portfolio_value(stocks: Dictionary) -> float:
	return cash + get_holdings_value(stocks)


func record_session_close(equity: float, alpha_pct: float) -> void:
	last_equity = equity
	last_alpha = alpha_pct
	if equity > equity_ath:
		equity_ath = equity
	if not has_alpha_stats:
		best_alpha = alpha_pct
		worst_alpha = alpha_pct
		has_alpha_stats = true
	else:
		best_alpha = maxf(best_alpha, alpha_pct)
		worst_alpha = minf(worst_alpha, alpha_pct)
	if alpha_pct > 0.05:
		beat_streak += 1
		best_beat_streak = maxi(best_beat_streak, beat_streak)
	elif alpha_pct < -0.05:
		beat_streak = 0


func streak_line() -> String:
	if beat_streak > 0:
		if best_beat_streak > beat_streak:
			return "%d days ahead of the tape (best %d)" % [beat_streak, best_beat_streak]
		return "%d days ahead of the tape" % beat_streak
	if best_beat_streak > 0:
		return "Streak broken  ·  best was %d days" % best_beat_streak
	return "No beat-the-market streak yet"


func career_close_line() -> String:
	var lines: PackedStringArray = []
	lines.append(streak_line())
	lines.append("Book $%.0f  ·  ATH $%.0f" % [last_equity, equity_ath])
	if has_alpha_stats:
		lines.append("Best day %+.1f%% vs tape  ·  Worst %+.1f%%" % [best_alpha, worst_alpha])
	return "\n".join(lines)


func mark_day_start(stocks: Dictionary) -> void:
	day_start_value = get_portfolio_value(stocks)
	if day_start_value < 0.01:
		day_start_value = STARTING_CASH


func get_profit_loss(stocks: Dictionary) -> float:
	return get_portfolio_value(stocks) - day_start_value


func get_profit_loss_pct(stocks: Dictionary) -> float:
	if day_start_value <= 0.0:
		return 0.0
	return (get_profit_loss(stocks) / day_start_value) * 100.0


func calculate_commission(trade_value: float) -> float:
	return FIXED_COMMISSION + trade_value * PERCENT_COMMISSION


func buy(symbol: String, shares: int, ask_price: float) -> Dictionary:
	if shares <= 0:
		return {"success": false, "message": "Share amount must be positive."}

	var trade_value := shares * ask_price
	var commission := calculate_commission(trade_value)
	var total_cost := trade_value + commission

	if total_cost > cash:
		var max_affordable := int((cash - FIXED_COMMISSION) / (ask_price * (1.0 + PERCENT_COMMISSION)))
		return {
			"success": false,
			"message": "Insufficient funds. You can afford at most %d shares." % maxi(max_affordable, 0),
		}

	cash -= total_cost
	total_commissions += commission
	var owned: int = get_shares(symbol)
	var old_cost: float = get_avg_cost(symbol) * float(owned)
	holdings[symbol] = owned + shares
	avg_cost[symbol] = (old_cost + trade_value) / float(holdings[symbol])

	var trade := {
		"type": "BUY",
		"symbol": symbol,
		"shares": shares,
		"price": ask_price,
		"commission": commission,
	}
	trade_history.append(trade)

	return {
		"success": true,
		"message": "Bought %d shares of %s at $%.2f (commission: $%.2f)" % [shares, symbol, ask_price, commission],
	}


func sell(symbol: String, shares: int, bid_price: float) -> Dictionary:
	if shares <= 0:
		return {"success": false, "message": "Share amount must be positive."}

	var owned := get_shares(symbol)
	if shares > owned:
		return {"success": false, "message": "You only own %d shares of %s." % [owned, symbol]}

	var trade_value := shares * bid_price
	var commission := calculate_commission(trade_value)
	var proceeds := trade_value - commission

	cash += proceeds
	total_commissions += commission
	holdings[symbol] = owned - shares
	if holdings[symbol] == 0:
		holdings.erase(symbol)
		avg_cost.erase(symbol)

	var trade := {
		"type": "SELL",
		"symbol": symbol,
		"shares": shares,
		"price": bid_price,
		"commission": commission,
	}
	trade_history.append(trade)

	return {
		"success": true,
		"message": "Sold %d shares of %s at $%.2f (commission: $%.2f)" % [shares, symbol, bid_price, commission],
	}
