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

var price_history: PackedFloat32Array = PackedFloat32Array()


func _init(p_symbol: String, p_name: String, start_price: float, p_volatility: float) -> void:
	symbol = p_symbol
	company_name = p_name
	price = clampf(start_price, MIN_PRICE, MAX_PRICE)
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


func apply_news_impact(total_move: float, duration_ticks: int, is_major: bool = false) -> void:
	news_move_remaining = total_move
	news_move_ticks = maxi(duration_ticks, 1)
	news_initial_ticks = news_move_ticks
	news_is_major = is_major
	sentiment = clampf(sentiment + total_move * 8.0, -1.0, 1.0)


func tick() -> void:
	var major_news_active: bool = news_is_major and news_move_ticks > 0
	var news_move: float = _consume_news_move()

	if randf() < 0.06:
		trend = Trend.values()[randi() % Trend.size()]

	var base_random: float = randf_range(-0.0006, 0.0006) * volatility
	var trend_move: float = _get_trend_drift() * volatility
	var momentum_move: float = clampf(momentum * 0.12, -0.00025, 0.00025)
	var growth_bias: float = (growth - 0.5) * 0.00008

	var volume_factor: float = clampf(float(volume) / 15000.0, 0.5, 2.0)
	var liquidity_noise: float = randf_range(-0.0003, 0.0003) * (1.0 - liquidity) / volume_factor

	var organic_change: float = base_random + trend_move + momentum_move + growth_bias + liquidity_noise
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
