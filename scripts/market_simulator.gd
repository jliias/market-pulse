class_name MarketSimulator
extends RefCounted

const TICK_INTERVAL := 1.0
const MARKET_MINUTES_PER_TICK := 1
const OPEN_HOUR := 9
const OPEN_MINUTE := 30
const CLOSE_HOUR := 16
const CLOSE_MINUTE := 0
const SYMBOL_ORDER: Array[String] = ["ALPH", "GRNE", "NMIN"]
const SYMBOL_ALIASES := {
	"A": "ALPH",
	"ALPH": "ALPH",
	"ALPHA": "ALPH",
	"B": "GRNE",
	"GRNE": "GRNE",
	"GREEN": "GRNE",
	"C": "NMIN",
	"NMIN": "NMIN",
	"NORTH": "NMIN",
	"MINING": "NMIN",
}

var stocks: Dictionary = {}
var news_feed: Array[NewsEvent] = []
var news_generator: NewsGenerator = NewsGenerator.new()
var session_minutes: int = 0
var session_seconds: int = 0
var tick_count: int = 0
var is_running: bool = false
var is_closed: bool = false
var market_sentiment: float = 0.0
var opening_index: float = 0.0
var premarket_events: Array[NewsEvent] = []


func _init() -> void:
	_setup_stocks()


func _setup_stocks() -> void:
	stocks["ALPH"] = Stock.new("ALPH", "Alpha Technologies", 187.45, 1.0, "Technology", "Large Cap")
	stocks["GRNE"] = Stock.new("GRNE", "Green Energy Corp", 34.20, 0.85, "Energy", "Mid Cap")
	stocks["NMIN"] = Stock.new("NMIN", "North Mining Ltd", 512.80, 1.15, "Materials", "Large Cap")


func apply_saved_prices(prices: Dictionary) -> void:
	for symbol in SYMBOL_ORDER:
		if prices.has(symbol):
			stocks[symbol].apply_saved_close(float(prices[symbol]))


func roll_to_next_day() -> void:
	for symbol in SYMBOL_ORDER:
		stocks[symbol].roll_to_next_day()


func prepare() -> void:
	is_running = false
	is_closed = false
	tick_count = 0
	session_minutes = 9
	session_seconds = 25
	market_sentiment = randf_range(-0.25, 0.25)
	premarket_events.clear()
	news_feed.clear()

	var briefing := news_generator.generate_premarket(get_stock_list(), get_time_string())
	for event in briefing:
		news_feed.append(event)
		premarket_events.append(event)
		_apply_premarket_news(event)

	opening_index = _current_index()


func open() -> NewsEvent:
	session_minutes = OPEN_HOUR
	session_seconds = OPEN_MINUTE
	opening_index = _current_index()
	is_running = true
	is_closed = false
	var open_bell := news_generator.generate_open_bell(get_time_string())
	news_feed.append(open_bell)
	return open_bell


func start() -> void:
	prepare()
	open()


func stop() -> void:
	is_running = false


func tick() -> Array[NewsEvent]:
	if not is_running or is_closed:
		return []

	tick_count += 1
	_advance_time()
	_drift_market_sentiment()

	var new_events: Array[NewsEvent] = []

	if _is_at_or_after_close():
		is_closed = true
		is_running = false
		var close_event := NewsEvent.new(
			get_time_string(),
			"Market closed. Final prints are in — did you beat the tape?",
			[],
			0.0,
			0.0,
			0
		)
		news_feed.append(close_event)
		new_events.append(close_event)
		return new_events

	if randf() < 0.055:
		var event := news_generator.generate_intraday(get_stock_list(), get_time_string())
		news_feed.append(event)
		new_events.append(event)
		_apply_news(event)

	for symbol in stocks:
		stocks[symbol].tick(market_sentiment)

	if news_feed.size() > 50:
		news_feed.remove_at(0)

	return new_events


func get_market_return_pct() -> float:
	if opening_index <= 0.0:
		return 0.0
	return ((_current_index() - opening_index) / opening_index) * 100.0


func get_alpha_pct(player_return_pct: float) -> float:
	return player_return_pct - get_market_return_pct()


func _current_index() -> float:
	var total := 0.0
	var count := 0
	for symbol in SYMBOL_ORDER:
		total += stocks[symbol].price
		count += 1
	return total / float(count)


func _apply_premarket_news(event: NewsEvent) -> void:
	var reactions: PackedStringArray = []
	for symbol in event.affected_symbols:
		if not stocks.has(symbol):
			continue
		var stock: Stock = stocks[symbol]
		var result: Dictionary = stock.interpret_news(event.impact, true, market_sentiment)
		var actual_move: float = float(result["move"])
		if absf(actual_move) < 0.008:
			actual_move = event.impact * randf_range(0.55, 0.9)
		stock.apply_overnight_gap(actual_move, event.is_major)
		var reaction_text: String = str(result["reaction"])
		if actual_move * event.impact < 0.0:
			reaction_text = "Futures fade the print — the gap may not hold."
		elif absf(actual_move) < absf(event.impact) * 0.45:
			reaction_text = "Overnight reaction looks softer than the headline."
		if not reaction_text.is_empty() and not reactions.has(reaction_text):
			reactions.append(reaction_text)

	if event.affected_symbols.size() > 1:
		event.reaction = "Overnight futures lean with the headline."
	elif not reactions.is_empty():
		event.reaction = reactions[0]

	if event.affected_symbols.size() > 1:
		market_sentiment = clampf(market_sentiment + event.impact * 3.0, -1.0, 1.0)
	elif not event.affected_symbols.is_empty():
		market_sentiment = clampf(market_sentiment + event.impact * 1.5, -1.0, 1.0)


func _apply_news(event: NewsEvent) -> void:
	var reactions: PackedStringArray = []
	var applied_moves: PackedFloat32Array = PackedFloat32Array()

	for symbol in event.affected_symbols:
		if not stocks.has(symbol):
			continue
		var stock: Stock = stocks[symbol]
		var result: Dictionary = stock.interpret_news(event.impact, event.is_major, market_sentiment)
		var actual_move: float = float(result["move"])
		var reaction_text: String = str(result["reaction"])
		stock.apply_news_impact(actual_move, event.duration_ticks, event.is_major)
		applied_moves.append(actual_move)
		if not reaction_text.is_empty() and not reactions.has(reaction_text):
			reactions.append(reaction_text)

	if event.affected_symbols.size() > 1:
		event.reaction = _summarize_global_reaction(applied_moves, event.impact)
	elif not reactions.is_empty():
		event.reaction = reactions[0]

	if event.affected_symbols.size() > 1:
		market_sentiment = clampf(market_sentiment + event.impact * 2.5, -1.0, 1.0)
	elif not applied_moves.is_empty():
		market_sentiment = clampf(market_sentiment + applied_moves[0] * 1.2, -1.0, 1.0)


func _summarize_global_reaction(applied_moves: PackedFloat32Array, headline_impact: float) -> String:
	if applied_moves.is_empty():
		return ""

	var follow_count := 0
	var fade_count := 0
	var ignore_count := 0
	var headline_sign: float = signf(headline_impact)

	for move in applied_moves:
		if absf(move) < 0.0015:
			ignore_count += 1
		elif headline_sign != 0.0 and signf(move) != headline_sign:
			fade_count += 1
		else:
			follow_count += 1

	if ignore_count == applied_moves.size():
		return "Markets largely shrug it off."
	if fade_count >= follow_count:
		return "Investors fade the headline as broader mood stays cautious."
	if ignore_count > 0 or fade_count > 0:
		return "Uneven reaction across the tape."
	return "The wider market leans with the headline."


func _drift_market_sentiment() -> void:
	market_sentiment = clampf(market_sentiment * 0.994 + randf_range(-0.012, 0.012), -1.0, 1.0)


func _advance_time() -> void:
	session_seconds += MARKET_MINUTES_PER_TICK
	while session_seconds >= 60:
		session_seconds -= 60
		session_minutes += 1


func _is_at_or_after_close() -> bool:
	if session_minutes > CLOSE_HOUR:
		return true
	return session_minutes == CLOSE_HOUR and session_seconds >= CLOSE_MINUTE


func get_time_string() -> String:
	return "%02d:%02d" % [session_minutes, session_seconds]


func get_stock_list() -> Array[Stock]:
	var list: Array[Stock] = []
	for symbol in SYMBOL_ORDER:
		list.append(stocks[symbol])
	return list


func resolve_symbol(input: String) -> String:
	var upper := input.to_upper()
	return SYMBOL_ALIASES.get(upper, "")


func get_stock(symbol: String) -> Stock:
	return stocks.get(symbol, null)
