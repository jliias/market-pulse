class_name Portfolio
extends RefCounted

const STARTING_CASH := 10000.0
const FIXED_COMMISSION := 2.0
const PERCENT_COMMISSION := 0.002
const FADE_BOOK_CAP := 0.2
const CHAPTER_LENGTH := 5
const WEEKDAYS: Array[String] = [
	"Monday", "Tuesday", "Wednesday", "Thursday", "Friday"
]

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
var chapter_open_equity: float = STARTING_CASH
var chapter_alpha_sum: float = 0.0
var chapter_beats: int = 0
var chapter_days: int = 0
var pending_chapter: bool = false
var fades: Dictionary = {}


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
	chapter_open_equity = STARTING_CASH
	chapter_alpha_sum = 0.0
	chapter_beats = 0
	chapter_days = 0
	pending_chapter = false
	fades.clear()


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
	chapter_open_equity = float(data.get("chapter_open_equity", last_equity))
	chapter_alpha_sum = float(data.get("chapter_alpha_sum", 0.0))
	chapter_beats = int(data.get("chapter_beats", 0))
	chapter_days = int(data.get("chapter_days", days_played % CHAPTER_LENGTH))
	pending_chapter = bool(data.get("pending_chapter", false))
	fades.clear()
	var saved_fades: Variant = data.get("fades", {})
	if typeof(saved_fades) == TYPE_DICTIONARY:
		for symbol in saved_fades:
			var row: Variant = saved_fades[symbol]
			if typeof(row) != TYPE_DICTIONARY:
				continue
			fades[str(symbol)] = {
				"shares": int(row.get("shares", 0)),
				"entry": float(row.get("entry", 0.0)),
			}


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


func get_fade_shares(symbol: String) -> int:
	if not fades.has(symbol):
		return 0
	return int((fades[symbol] as Dictionary).get("shares", 0))


func get_fade_entry(symbol: String) -> float:
	if not fades.has(symbol):
		return 0.0
	return float((fades[symbol] as Dictionary).get("entry", 0.0))


func get_fade_pl(stocks: Dictionary) -> float:
	var total := 0.0
	for symbol in fades:
		if not stocks.has(symbol):
			continue
		var shares: int = get_fade_shares(str(symbol))
		var entry: float = get_fade_entry(str(symbol))
		total += (entry - stocks[symbol].price) * float(shares)
	return total


func fade_notional(stocks: Dictionary) -> float:
	var total := 0.0
	for symbol in fades:
		if stocks.has(symbol):
			total += float(get_fade_shares(str(symbol))) * stocks[symbol].price
	return total


func max_fadable(price: float, stocks: Dictionary) -> int:
	if price <= 0.0:
		return 0
	var cap: float = (cash + get_holdings_value(stocks)) * FADE_BOOK_CAP
	var room: float = cap - fade_notional(stocks)
	return maxi(int(room / price), 0)


func get_portfolio_value(stocks: Dictionary) -> float:
	return cash + get_holdings_value(stocks) + get_fade_pl(stocks)


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
	chapter_alpha_sum += alpha_pct
	chapter_days += 1
	if alpha_pct > 0.05:
		chapter_beats += 1


func streak_line() -> String:
	if beat_streak > 0:
		if best_beat_streak > beat_streak:
			return "%d days ahead of the market (best %d)" % [beat_streak, best_beat_streak]
		return "%d days ahead of the market" % beat_streak
	if best_beat_streak > 0:
		return "Streak broken  ·  best was %d days" % best_beat_streak
	return "No beat-the-market streak yet"


func career_close_line() -> String:
	var lines: PackedStringArray = []
	lines.append(streak_line())
	lines.append("Book $%.0f  ·  ATH $%.0f" % [last_equity, equity_ath])
	if has_alpha_stats:
		lines.append("Best day %+.1f%% vs Market  ·  Worst %+.1f%%" % [best_alpha, worst_alpha])
	return "\n".join(lines)


func chapter_just_finished() -> bool:
	return days_played > 0 and days_played % CHAPTER_LENGTH == 0


func begin_next_chapter() -> void:
	pending_chapter = false
	chapter_open_equity = last_equity
	chapter_alpha_sum = 0.0
	chapter_beats = 0
	chapter_days = 0


func recap_summary(climate_line: String) -> Dictionary:
	var week_n: int = maxi(days_played / CHAPTER_LENGTH, 1)
	var counted: int = maxi(chapter_days, 1)
	var avg_alpha: float = chapter_alpha_sum / float(counted)
	var book_pct: float = 0.0
	if chapter_open_equity > 0.01:
		book_pct = ((last_equity - chapter_open_equity) / chapter_open_equity) * 100.0
	var start_day: int = days_played - counted + 1
	return {
		"week": "Week %d complete  ·  %s–%s  ·  days %d–%d" % [
			week_n,
			weekday_name(start_day),
			weekday_name(days_played),
			start_day,
			days_played,
		],
		"book": "Book $%.0f → $%.0f  (%+.1f%%)" % [chapter_open_equity, last_equity, book_pct],
		"vs": "Ahead of the market %d of %d days  ·  avg vs Market %+.1f%%" % [chapter_beats, counted, avg_alpha],
		"climate": climate_line,
		"streak": streak_line(),
	}


func recap_text(climate_line: String, watchlist: Array[String]) -> String:
	var bits: Dictionary = recap_summary(climate_line)
	var names: PackedStringArray = []
	for symbol in watchlist:
		names.append(str(symbol))
	var lines: PackedStringArray = [
		str(bits.get("week", "")),
		str(bits.get("book", "")),
		str(bits.get("vs", "")),
	]
	var climate: String = str(bits.get("climate", ""))
	if not climate.is_empty():
		lines.append(climate)
	lines.append(str(bits.get("streak", "")))
	lines.append("Board  %s" % ", ".join(names))
	return "\n".join(lines)


static func weekday_name(day_number: int) -> String:
	var n: int = maxi(day_number, 1)
	return WEEKDAYS[(n - 1) % WEEKDAYS.size()]


static func week_number(day_number: int) -> int:
	return (maxi(day_number, 1) - 1) / CHAPTER_LENGTH + 1


static func session_heading(day_number: int) -> String:
	return "DAY %d (%s, Week %d)" % [day_number, weekday_name(day_number), week_number(day_number)]


static func career_heading(day_number: int) -> String:
	return "Day %d (%s, Week %d)" % [day_number, weekday_name(day_number), week_number(day_number)]


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
	if get_fade_shares(symbol) > 0:
		return {"success": false, "message": "Cover the short on %s before you buy it." % symbol}
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


func open_fade(symbol: String, shares: int, price: float, stocks: Dictionary) -> Dictionary:
	if shares <= 0:
		return {"success": false, "message": "Share amount must be positive."}
	if get_shares(symbol) > 0:
		return {"success": false, "message": "Sell the long before you short %s." % symbol}
	if get_fade_shares(symbol) > 0:
		return {"success": false, "message": "You already short %s. Cover it first." % symbol}
	var trade_value := float(shares) * price
	var cap: float = (cash + get_holdings_value(stocks)) * FADE_BOOK_CAP
	if fade_notional(stocks) + trade_value > cap + 0.01:
		var room: int = max_fadable(price, stocks)
		return {"success": false, "message": "Short is capped at 20%% of the book. At most %d shares." % maxi(room, 0)}
	var commission := calculate_commission(trade_value)
	if commission > cash:
		return {"success": false, "message": "Not enough cash to pay the short commission."}
	cash -= commission
	total_commissions += commission
	fades[symbol] = {"shares": shares, "entry": price}
	trade_history.append({"type": "FADE", "symbol": symbol, "shares": shares, "price": price, "commission": commission})
	return {
		"success": true,
		"message": "Shorting %d of %s from $%.2f. Pays if the price falls. Covers at the close." % [shares, symbol, price],
	}


func cover_fade(symbol: String, price: float) -> Dictionary:
	var shares: int = get_fade_shares(symbol)
	if shares <= 0:
		return {"success": false, "message": "No short on %s." % symbol}
	var entry: float = get_fade_entry(symbol)
	var pl: float = (entry - price) * float(shares)
	var commission := calculate_commission(float(shares) * price)
	cash += pl - commission
	total_commissions += commission
	fades.erase(symbol)
	trade_history.append({"type": "COVER", "symbol": symbol, "shares": shares, "price": price, "commission": commission})
	return {
		"success": true,
		"message": "Covered short on %s at $%.2f (%s$%.2f)" % [symbol, price, "+" if pl >= 0.0 else "−", absf(pl)],
	}


func cover_all_fades(stocks: Dictionary) -> void:
	var symbols: Array = fades.keys()
	for item in symbols:
		var symbol: String = str(item)
		if stocks.has(symbol):
			cover_fade(symbol, stocks[symbol].price)
