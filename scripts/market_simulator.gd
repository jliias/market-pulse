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
var chain_director: EventChainDirector
var session_minutes: int = 0
var session_seconds: int = 0
var tick_count: int = 0
var is_running: bool = false
var is_closed: bool = false
var market_sentiment: float = 0.0
var opening_index: float = 0.0
var premarket_events: Array[NewsEvent] = []
var mood_hold: float = 0.0
var mood_hold_ticks: int = 0
var calendar_day: int = 0
var regime: MarketRegime = MarketRegime.new()


func _init() -> void:
	_setup_stocks()
	chain_director = EventChainDirector.new(news_generator)


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
	market_sentiment = regime.opening_sentiment()
	mood_hold = 0.0
	mood_hold_ticks = 0
	premarket_events.clear()
	news_feed.clear()
	chain_director.calendar_day = calendar_day

	var climate_line: String = regime.take_climate_headline()
	if not climate_line.is_empty():
		var climate_event := NewsEvent.new(
			get_time_string(),
			climate_line,
			[],
			0.2 if regime.climate == MarketRegime.CLIMATE_BULL else (-0.2 if regime.climate == MarketRegime.CLIMATE_BEAR else 0.0),
			0.0,
			0,
			false,
			true,
			"macro",
			"system"
		)
		news_feed.append(climate_event)
		premarket_events.append(climate_event)

	var chain_briefing: Array[NewsEvent] = chain_director.collect_premarket(get_stock_list(), get_time_string())
	var avoid: Array[String] = chain_director.occupied_subjects()
	var briefing: Array[NewsEvent] = news_generator.generate_premarket(get_stock_list(), get_time_string(), avoid)
	var combined: Array[NewsEvent] = []
	for event in chain_briefing:
		combined.append(event)
	for event in briefing:
		if combined.size() >= 4:
			break
		combined.append(event)
	for event in combined:
		news_feed.append(event)
		premarket_events.append(event)
		_apply_premarket_news(event)
		var weather_note: NewsEvent = _maybe_shift_regime(event, true)
		if weather_note != null:
			premarket_events.append(weather_note)

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


func simulate_until_close() -> Array[NewsEvent]:
	if is_closed:
		return []
	if not is_running:
		is_running = true
	var caught_up: Array[NewsEvent] = []
	var guard: int = 0
	while not is_closed and guard < 500:
		guard += 1
		var batch: Array[NewsEvent] = tick()
		for event in batch:
			caught_up.append(event)
	return caught_up


func tick() -> Array[NewsEvent]:
	if not is_running or is_closed:
		return []

	tick_count += 1
	_advance_time()
	_drift_market_sentiment()
	regime.tick()

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
			0,
			false,
			false,
			"general",
			"system"
		)
		news_feed.append(close_event)
		new_events.append(close_event)
		return new_events

	var chain_event: NewsEvent = chain_director.try_fire_due(get_stock_list(), get_time_string(), tick_count)
	if chain_event != null:
		news_feed.append(chain_event)
		new_events.append(chain_event)
		_apply_news(chain_event)
		_push_regime_note(chain_event, new_events)
	elif randf() < regime.news_roll_chance():
		var event: NewsEvent = null
		if randf() < 0.18:
			event = chain_director.try_start(get_stock_list(), get_time_string(), false)
		if event == null:
			event = news_generator.generate_intraday(get_stock_list(), get_time_string(), chain_director.occupied_subjects())
		news_feed.append(event)
		new_events.append(event)
		_apply_news(event)
		_push_regime_note(event, new_events)

	for symbol in stocks:
		stocks[symbol].tick(market_sentiment, regime.tick_modifiers())

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
		var result: Dictionary = stock.interpret_news(
			event.impact, true, market_sentiment, event.category, regime.climate, regime.weather
		)
		var actual_move: float = float(result["move"])
		if absf(actual_move) < 0.008:
			actual_move = event.impact * randf_range(0.55, 0.9)
		stock.apply_overnight_gap(actual_move, event.is_major, event.lasting)
		var reaction_text: String = str(result["reaction"])
		if actual_move * event.impact < 0.0:
			reaction_text = "Futures fade the print — the gap may not hold."
		elif absf(actual_move) < absf(event.impact) * 0.45:
			reaction_text = "Overnight reaction looks softer than the headline."
		if not reaction_text.is_empty() and not reactions.has(reaction_text):
			reactions.append(reaction_text)

	if event.scope == "market":
		event.reaction = "Overnight futures lean with the headline."
	elif event.scope == "industry":
		event.reaction = "The sector gaps with the overnight note."
	elif not reactions.is_empty():
		event.reaction = reactions[0]

	_nudge_market_mood(event, event.impact)


func _apply_news(event: NewsEvent) -> void:
	var reactions: PackedStringArray = []
	var applied_moves: PackedFloat32Array = PackedFloat32Array()

	for symbol in event.affected_symbols:
		if not stocks.has(symbol):
			continue
		var stock: Stock = stocks[symbol]
		var result: Dictionary = stock.interpret_news(
			event.impact, event.is_major, market_sentiment, event.category, regime.climate, regime.weather
		)
		var actual_move: float = float(result["move"])
		var reaction_text: String = str(result["reaction"])
		stock.apply_news_impact(actual_move, event.duration_ticks, event.is_major, event.lasting)
		applied_moves.append(actual_move)
		if not reaction_text.is_empty() and not reactions.has(reaction_text):
			reactions.append(reaction_text)

	if event.scope == "market":
		event.reaction = _summarize_global_reaction(applied_moves, event.impact)
	elif event.scope == "industry":
		event.reaction = _summarize_industry_reaction(applied_moves, event.impact, event.industry)
	elif not reactions.is_empty():
		event.reaction = reactions[0]

	var mood_impulse: float = event.impact
	if not applied_moves.is_empty() and event.scope == "company":
		mood_impulse = applied_moves[0]
	_nudge_market_mood(event, mood_impulse)


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


func _summarize_industry_reaction(applied_moves: PackedFloat32Array, headline_impact: float, industry: String) -> String:
	var label: String = industry if not industry.is_empty() else "sector"
	if applied_moves.is_empty():
		return "Quiet tape in %s." % label

	var headline_sign: float = signf(headline_impact)
	var follow_count := 0
	var fade_count := 0
	var ignore_count := 0
	for move in applied_moves:
		if absf(move) < 0.0015:
			ignore_count += 1
		elif headline_sign != 0.0 and signf(move) != headline_sign:
			fade_count += 1
		else:
			follow_count += 1

	if ignore_count == applied_moves.size():
		return "The %s group shrugs the sector note." % label
	if fade_count >= follow_count:
		return "The %s group fades the sector headline." % label
	if ignore_count > 0 or fade_count > 0:
		return "Uneven reaction across %s names." % label
	return "The %s group leans with the headline." % label


func _push_regime_note(source: NewsEvent, into: Array[NewsEvent]) -> void:
	var note: NewsEvent = _maybe_shift_regime(source, false)
	if note != null:
		into.append(note)


func _maybe_shift_regime(event: NewsEvent, premarket: bool) -> NewsEvent:
	var kind: String = regime.consider_event(event)
	if kind.is_empty():
		return null
	var headline: String
	match kind:
		MarketRegime.WEATHER_PANIC:
			headline = "Panic hits the tape — sellers chase every downtick."
			market_sentiment = clampf(market_sentiment - 0.28, -1.0, 1.0)
		MarketRegime.WEATHER_EUPHORIA:
			headline = "Euphoria hits the tape — buyers chase every uptick."
			market_sentiment = clampf(market_sentiment + 0.28, -1.0, 1.0)
		_:
			headline = "High-volatility session: ranges expand and the tape gets noisy."
	if premarket and not headline.begins_with("PREMARKET"):
		headline = "PREMARKET: " + headline
	var note := NewsEvent.new(
		get_time_string(),
		headline,
		[],
		-1.0 if kind == MarketRegime.WEATHER_PANIC else (1.0 if kind == MarketRegime.WEATHER_EUPHORIA else 0.0),
		0.0,
		0,
		false,
		premarket,
		"macro",
		"system",
		"moderate",
		false,
		""
	)
	news_feed.append(note)
	return note


func _nudge_market_mood(event: NewsEvent, impulse: float) -> void:
	var scale: float = 1.2
	match event.scope:
		"market":
			scale = 3.2 if event.lasting else 2.2
		"industry":
			scale = 1.8 if event.lasting else 1.2
		_:
			scale = 1.1 if event.lasting else 0.7
	market_sentiment = clampf(market_sentiment + impulse * scale, -1.0, 1.0)
	if event.lasting and event.scope == "market":
		mood_hold_ticks = maxi(mood_hold_ticks, 40 if event.is_major else 24)
		mood_hold = clampf(mood_hold + impulse * 2.0, -0.35, 0.35)


func _drift_market_sentiment() -> void:
	var decay: float = 0.997 if mood_hold_ticks > 0 else 0.994
	if mood_hold_ticks > 0:
		market_sentiment = clampf(market_sentiment * decay + mood_hold * 0.08 + randf_range(-0.008, 0.008), -1.0, 1.0)
		mood_hold_ticks -= 1
		mood_hold *= 0.97
	else:
		mood_hold = 0.0
		market_sentiment = clampf(market_sentiment * decay + randf_range(-0.012, 0.012), -1.0, 1.0)


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
