class_name DramaDirector
extends RefCounted

const MAX_PER_DAY := 2
const MIN_GAP_TICKS := 95
const MIN_SESSION_TICK := 18

var dramas_today: int = 0
var last_drama_tick: int = -999
var last_buy_tick: Dictionary = {}
var last_symbol_drama_tick: Dictionary = {}
var pending_headlines: Array = []
var spectator: bool = false


func reset() -> void:
	dramas_today = 0
	last_drama_tick = -999
	last_buy_tick.clear()
	last_symbol_drama_tick.clear()
	pending_headlines.clear()
	spectator = false


func note_buy(symbol: String, shares: int, price: float, stock: Stock, tick: int, cash: float, portfolio_value: float) -> void:
	last_buy_tick[symbol] = tick
	if spectator or not _can_fire(tick, symbol):
		return
	var notional: float = float(shares) * price
	if not _meaningful(notional, portfolio_value):
		return
	var chase: bool = stock.get_day_change_pct() > 0.7
	var odds: float = 0.16 if chase else 0.07
	if randf() > odds:
		return
	var wait: int = randi_range(8, 22)
	var move: float = -randf_range(0.016, 0.036)
	if chase:
		move -= randf_range(0.004, 0.01)
	_schedule(
		stock,
		tick,
		wait,
		move,
		_headline(stock, "Sellers overwhelm %s after the squeeze." % stock.company_name, -1.0),
		"crash"
	)


func note_sell(symbol: String, shares: int, price: float, stock: Stock, tick: int, remaining: int, avg_cost: float, portfolio_value: float) -> void:
	if remaining <= 0:
		last_buy_tick.erase(symbol)
	if spectator or not _can_fire(tick, symbol):
		return
	var notional: float = float(shares) * price
	if not _meaningful(notional, portfolio_value):
		return
	var winner: bool = avg_cost > 0.0 and price > avg_cost * 1.004
	var odds: float = 0.18 if winner else 0.08
	if stock.get_day_change_pct() > 0.4:
		odds += 0.04
	if randf() > odds:
		return
	var wait: int = randi_range(10, 28)
	var move: float = randf_range(0.015, 0.038)
	if winner:
		move += randf_range(0.004, 0.012)
	_schedule(
		stock,
		tick,
		wait,
		move,
		_headline(stock, "Late money chases %s after the dip." % stock.company_name, 1.0),
		"sold_early"
	)


func tick(market: MarketSimulator, portfolio: Portfolio) -> Array[NewsEvent]:
	if not spectator:
		if market.tick_count % 22 == 0:
			_maybe_hold_too_long(market, portfolio)
		if market.tick_count % 34 == 0:
			_maybe_missed_breakout(market, portfolio)
	var released: Array[NewsEvent] = _release_headlines()
	for event in released:
		event.timestamp = market.get_time_string()
	return released


func _maybe_hold_too_long(market: MarketSimulator, portfolio: Portfolio) -> void:
	for symbol in portfolio.holdings.keys():
		var shares: int = portfolio.get_shares(str(symbol))
		if shares <= 0 or not market.stocks.has(symbol):
			continue
		var stock: Stock = market.stocks[symbol]
		var held: int = market.tick_count - int(last_buy_tick.get(symbol, market.tick_count))
		var day_pct: float = stock.get_day_change_pct()
		var pos_pct: float = 0.0
		var avg: float = portfolio.get_avg_cost(str(symbol))
		if avg > 0.0:
			pos_pct = ((stock.price - avg) / avg) * 100.0
		if held < 55:
			continue
		if day_pct < 1.15 and pos_pct < 1.8:
			continue
		if not _can_fire(market.tick_count, str(symbol)):
			continue
		if randf() > 0.13:
			continue
		var wait: int = randi_range(6, 16)
		var move: float = -randf_range(0.014, 0.034)
		_schedule(
			stock,
			market.tick_count,
			wait,
			move,
			_headline(stock, "Profit-taking hits %s after the run." % stock.company_name, -1.0),
			"held_long"
		)
		return
	return


func _maybe_missed_breakout(market: MarketSimulator, portfolio: Portfolio) -> void:
	if portfolio.cash < 600.0:
		return
	var candidates: Array[Stock] = []
	for symbol in MarketSimulator.SYMBOL_ORDER:
		if portfolio.get_shares(symbol) > 0:
			continue
		if not market.stocks.has(symbol):
			continue
		var stock: Stock = market.stocks[symbol]
		if absf(stock.get_day_change_pct()) > 0.85:
			continue
		if not _can_fire(market.tick_count, symbol):
			continue
		candidates.append(stock)
	if candidates.is_empty() or randf() > 0.11:
		return
	var stock: Stock = candidates[randi() % candidates.size()]
	var wait: int = randi_range(8, 20)
	var move: float = randf_range(0.018, 0.042)
	_schedule(
		stock,
		market.tick_count,
		wait,
		move,
		_headline(stock, "%s breaks out on a burst of fresh flow." % stock.company_name, 1.0),
		"missed_breakout"
	)


func _schedule(stock: Stock, tick: int, wait: int, move: float, event: NewsEvent, _kind: String) -> void:
	dramas_today += 1
	last_drama_tick = tick
	last_symbol_drama_tick[stock.symbol] = tick
	stock.queue_scripted_move(wait, move, randi_range(8, 16), absf(move) > 0.028, absf(move) > 0.022)
	pending_headlines.append({"wait": wait, "event": event})


func _release_headlines() -> Array[NewsEvent]:
	var out: Array[NewsEvent] = []
	var i: int = 0
	while i < pending_headlines.size():
		var item: Dictionary = pending_headlines[i]
		var wait: int = int(item.get("wait", 1)) - 1
		if wait <= 0:
			pending_headlines.remove_at(i)
			var event: NewsEvent = item.get("event")
			if event != null:
				out.append(event)
		else:
			item["wait"] = wait
			pending_headlines[i] = item
			i += 1
	return out


func _can_fire(tick: int, symbol: String) -> bool:
	if dramas_today >= MAX_PER_DAY:
		return false
	if tick < MIN_SESSION_TICK:
		return false
	if tick - last_drama_tick < MIN_GAP_TICKS:
		return false
	if not symbol.is_empty():
		if tick - int(last_symbol_drama_tick.get(symbol, -999)) < MIN_GAP_TICKS:
			return false
	return true


func _meaningful(notional: float, portfolio_value: float) -> bool:
	if notional < 350.0:
		return false
	if portfolio_value <= 0.0:
		return true
	return notional >= portfolio_value * 0.07


func _headline(stock: Stock, text: String, sentiment: float) -> NewsEvent:
	return NewsEvent.new(
		"",
		text,
		[stock.symbol],
		sentiment,
		0.0,
		0,
		false,
		false,
		"rumor",
		"company",
		"moderate",
		false,
		""
	)
