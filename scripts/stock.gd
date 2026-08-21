class_name Stock
extends RefCounted

enum Trend { BULLISH, BEARISH, SIDEWAYS }

const MIN_PRICE := 1.0
const MAX_PRICE := 1000.0
const MAX_NORMAL_TICK_CHANGE := 0.0035
const MAX_ROUTINE_NEWS_TICK_CHANGE := 0.008
const MAX_MAJOR_TICK_CHANGE := 0.15

var symbol: String
var company_name: String
var price: float
var bid: float
var ask: float
var volume: int
var volatility: float
var sentiment: float
var trend: Trend = Trend.SIDEWAYS
var momentum: float = 0.0

var growth: float
var liquidity: float
var popularity: float
var institutional_ownership: float
var speculation_factor: float

var news_move_remaining: float = 0.0
var news_move_ticks: int = 0
var news_initial_ticks: int = 0
var news_is_major: bool = false

var previous_close: float
var price_history: PackedFloat32Array = PackedFloat32Array()


func _init(p_symbol: String, p_name: String, start_price: float, p_volatility: float) -> void:
	symbol = p_symbol
	company_name = p_name
	price = clampf(start_price, MIN_PRICE, MAX_PRICE)
	previous_close = price
	volatility = p_volatility
	volume = randi_range(5000, 20000)
	sentiment = randf_range(-0.2, 0.2)
	trend = Trend.values()[randi() % Trend.size()]

	growth = randf_range(0.3, 1.0)
	liquidity = randf_range(0.4, 1.0)
	popularity = randf_range(0.3, 1.0)
	institutional_ownership = randf_range(0.2, 0.8)
	speculation_factor = randf_range(0.2, 0.9)

	_update_spread()
	price_history.append(price)


func interpret_news(headline_impact: float, is_major: bool, market_sentiment: float) -> Dictionary:
	var headline_sign: float = signf(headline_impact)
	var headline_size: float = absf(headline_impact)
	if headline_sign == 0.0 or headline_size <= 0.0:
		return {"move": 0.0, "reaction": ""}

	var combined_mood: float = clampf(market_sentiment * 0.65 + sentiment * 0.35, -1.0, 1.0)
	var alignment: float = clampf(0.55 + headline_sign * combined_mood * 0.5, 0.08, 1.2)

	var ignore_chance: float = 0.07 if is_major else 0.2
	if headline_sign > 0.0 and combined_mood > 0.3:
		ignore_chance += 0.12
	elif headline_sign < 0.0 and combined_mood < -0.3:
		ignore_chance += 0.08
	if trend == Trend.SIDEWAYS:
		ignore_chance += 0.04

	var fade_chance: float = 0.04 if is_major else 0.08
	if headline_sign > 0.0:
		fade_chance += maxf(0.0, -combined_mood) * 0.4
		if trend == Trend.BEARISH:
			fade_chance += 0.14
		if market_sentiment < -0.2:
			fade_chance += 0.1
	else:
		fade_chance += maxf(0.0, combined_mood) * 0.28
		if trend == Trend.BULLISH:
			fade_chance += 0.1

	if is_major:
		ignore_chance *= 0.45
		fade_chance *= 0.5

	if randf() < ignore_chance:
		return {
			"move": 0.0,
			"reaction": "Little reaction — traders treat it as already priced in.",
		}

	if randf() < fade_chance:
		var fade_move: float = -headline_sign * headline_size * randf_range(0.25, 0.7)
		var fade_text: String
		if headline_sign > 0.0:
			fade_text = "Selling into the news as broader sentiment stays weak."
		else:
			fade_text = "Dip buyers step in despite the headline."
		return {"move": fade_move, "reaction": fade_text}

	var actual_move: float = headline_impact * alignment * randf_range(0.65, 1.05)
	var reaction := ""
	if alignment < 0.4:
		reaction = "Muted reaction amid mixed or cautious sentiment."
	elif headline_sign > 0.0 and actual_move > 0.0:
		reaction = "Buyers respond to the headline."
	elif headline_sign < 0.0 and actual_move < 0.0:
		reaction = "Sellers press the stock on the news."

	return {"move": actual_move, "reaction": reaction}


func apply_overnight_gap(gap_pct: float, is_major: bool = true) -> void:
	price = clampf(price * (1.0 + gap_pct), MIN_PRICE, MAX_PRICE)
	momentum = clampf(gap_pct * 0.4, -0.002, 0.002)
	sentiment = clampf(sentiment + gap_pct * 4.0, -1.0, 1.0)
	if gap_pct > 0.01:
		trend = Trend.BULLISH
	elif gap_pct < -0.01:
		trend = Trend.BEARISH
	news_move_remaining = gap_pct * 0.22
	news_move_ticks = 3
	news_initial_ticks = 3
	news_is_major = is_major
	_update_spread()
	price_history.append(price)


func get_day_change_pct() -> float:
	if previous_close <= 0.0:
		return 0.0
	return ((price - previous_close) / previous_close) * 100.0


func apply_news_impact(total_move: float, duration_ticks: int, is_major: bool = false) -> void:
	news_move_remaining = total_move
	news_move_ticks = maxi(duration_ticks, 1)
	news_initial_ticks = news_move_ticks
	news_is_major = is_major
	if total_move == 0.0:
		return
	sentiment = clampf(sentiment + total_move * 6.0, -1.0, 1.0)
	if total_move > 0.004 and randf() < 0.35:
		trend = Trend.BULLISH
	elif total_move < -0.004 and randf() < 0.35:
		trend = Trend.BEARISH


func tick(p_market_sentiment: float = 0.0) -> void:
	var major_news_active: bool = news_is_major and news_move_ticks > 0
	var news_move: float = _consume_news_move()

	if randf() < 0.06:
		trend = Trend.values()[randi() % Trend.size()]

	var base_random: float = randf_range(-0.0006, 0.0006) * volatility
	var trend_move: float = _get_trend_drift() * volatility
	var momentum_move: float = clampf(momentum * 0.12, -0.00025, 0.00025)
	var growth_bias: float = (growth - 0.5) * 0.00008
	var mood_bias: float = clampf(p_market_sentiment * 0.00018 + sentiment * 0.00012, -0.00035, 0.00035)

	var volume_factor: float = clampf(float(volume) / 15000.0, 0.5, 2.0)
	var liquidity_noise: float = randf_range(-0.0003, 0.0003) * (1.0 - liquidity) / volume_factor

	var organic_change: float = base_random + trend_move + momentum_move + growth_bias + liquidity_noise + mood_bias
	organic_change *= lerpf(0.92, 1.08, speculation_factor)
	organic_change = clampf(organic_change, -MAX_NORMAL_TICK_CHANGE, MAX_NORMAL_TICK_CHANGE)

	var total_change: float = organic_change + news_move
	if major_news_active:
		total_change = clampf(total_change, -MAX_MAJOR_TICK_CHANGE, MAX_MAJOR_TICK_CHANGE)
	elif news_move != 0.0:
		total_change = clampf(total_change, -MAX_ROUTINE_NEWS_TICK_CHANGE, MAX_ROUTINE_NEWS_TICK_CHANGE)
	else:
		total_change = clampf(total_change, -MAX_NORMAL_TICK_CHANGE, MAX_NORMAL_TICK_CHANGE)

	momentum = clampf(momentum * 0.82 + total_change * 1.5, -0.002, 0.002)
	price = clampf(price * (1.0 + total_change), MIN_PRICE, MAX_PRICE)

	var volume_change: int = int(abs(total_change) * 50000.0 * popularity)
	volume = maxi(volume + volume_change - randi_range(100, 800), 1000)

	_update_spread()
	price_history.append(price)
	if price_history.size() > 120:
		price_history.remove_at(0)


func _consume_news_move() -> float:
	if news_move_ticks <= 0:
		return 0.0

	var move: float = 0.0
	var ticks_elapsed: int = news_initial_ticks - news_move_ticks

	if news_is_major:
		if ticks_elapsed == 0:
			move = news_move_remaining * 0.65
		else:
			move = news_move_remaining / float(news_move_ticks)
	else:
		move = news_move_remaining / float(news_move_ticks)

	news_move_remaining -= move
	news_move_ticks -= 1

	if news_move_ticks <= 0:
		news_is_major = false
		news_move_remaining = 0.0

	return move


func _get_trend_drift() -> float:
	match trend:
		Trend.BULLISH:
			return 0.00015
		Trend.BEARISH:
			return -0.00015
		_:
			return 0.0


func _update_spread() -> void:
	var spread_pct: float = 0.001 + (1.0 - liquidity) * 0.003
	bid = price * (1.0 - spread_pct)
	ask = price * (1.0 + spread_pct)


func get_trend_name() -> String:
	match trend:
		Trend.BULLISH:
			return "Bullish"
		Trend.BEARISH:
			return "Bearish"
		_:
			return "Sideways"
