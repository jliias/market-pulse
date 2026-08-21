class_name Stock
extends RefCounted

enum Trend { BULLISH, BEARISH, SIDEWAYS }

const MIN_PRICE := 1.0
const MAX_PRICE := 1000.0
const MAX_NORMAL_TICK_CHANGE := 0.0016
const MAX_ROUTINE_NEWS_TICK_CHANGE := 0.006
const MAX_MAJOR_TICK_CHANGE := 0.12

const PERSONALITIES := {
	"ALPH": {
		"label": "Growth",
		"volatility": 1.22,
		"growth": 0.88,
		"liquidity": 0.72,
		"popularity": 0.85,
		"institutional_ownership": 0.55,
		"speculation_factor": 0.45,
		"trend_flip": 0.010,
		"news": {
			"product": 1.45,
			"earnings": 1.25,
			"analyst": 1.15,
			"rumor": 0.65,
			"macro": 0.85,
			"commodity": 0.35,
			"regulatory": 0.90,
			"industry": 1.15,
			"general": 1.0,
		},
	},
	"GRNE": {
		"label": "Speculative",
		"volatility": 1.38,
		"growth": 0.58,
		"liquidity": 0.42,
		"popularity": 0.70,
		"institutional_ownership": 0.28,
		"speculation_factor": 0.92,
		"trend_flip": 0.024,
		"news": {
			"rumor": 1.70,
			"regulatory": 1.55,
			"analyst": 1.25,
			"earnings": 0.62,
			"product": 1.05,
			"macro": 1.20,
			"commodity": 0.50,
			"industry": 1.20,
			"general": 1.10,
		},
	},
	"NMIN": {
		"label": "Stable",
		"volatility": 0.62,
		"growth": 0.42,
		"liquidity": 0.88,
		"popularity": 0.50,
		"institutional_ownership": 0.78,
		"speculation_factor": 0.22,
		"trend_flip": 0.006,
		"news": {
			"commodity": 1.50,
			"earnings": 1.20,
			"rumor": 0.28,
			"product": 0.50,
			"analyst": 0.70,
			"macro": 0.75,
			"regulatory": 0.85,
			"industry": 0.80,
			"general": 0.85,
		},
	},
}

var symbol: String
var company_name: String
var sector: String
var market_cap_label: String
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
var personality_label: String = ""
var news_sensitivity: Dictionary = {}
var trend_flip_chance: float = 0.012

var industries: Array[String] = []
var news_move_remaining: float = 0.0
var news_move_ticks: int = 0
var news_initial_ticks: int = 0
var news_is_major: bool = false
var news_is_lasting: bool = false
var revert_remaining: float = 0.0
var revert_ticks: int = 0
var lasting_bias: float = 0.0
var lasting_ticks: int = 0

var previous_close: float
var last_tick_volume: int = 0
var price_history: PackedFloat32Array = PackedFloat32Array()
var volume_history: PackedInt32Array = PackedInt32Array()


func _init(
	p_symbol: String,
	p_name: String,
	start_price: float,
	p_volatility: float,
	p_sector: String = "",
	p_cap: String = ""
) -> void:
	symbol = p_symbol
	company_name = p_name
	sector = p_sector
	market_cap_label = p_cap
	price = clampf(start_price, MIN_PRICE, MAX_PRICE)
	previous_close = price
	volatility = p_volatility
	volume = randi_range(800000, 2500000)
	sentiment = randf_range(-0.2, 0.2)
	trend = Trend.values()[randi() % Trend.size()]

	growth = randf_range(0.3, 1.0)
	liquidity = randf_range(0.4, 1.0)
	popularity = randf_range(0.3, 1.0)
	institutional_ownership = randf_range(0.2, 0.8)
	speculation_factor = randf_range(0.2, 0.9)
	_apply_personality()
	_assign_industries()

	_update_spread()
	last_tick_volume = randi_range(40000, 90000)
	_record_history()


func _apply_personality() -> void:
	if not PERSONALITIES.has(symbol):
		personality_label = "Balanced"
		news_sensitivity = {"general": 1.0}
		return
	var profile: Dictionary = PERSONALITIES[symbol]
	personality_label = str(profile["label"])
	volatility = float(profile["volatility"])
	growth = float(profile["growth"])
	liquidity = float(profile["liquidity"])
	popularity = float(profile["popularity"])
	institutional_ownership = float(profile["institutional_ownership"])
	speculation_factor = float(profile["speculation_factor"])
	trend_flip_chance = float(profile["trend_flip"])
	news_sensitivity = (profile["news"] as Dictionary).duplicate()


func _assign_industries() -> void:
	industries.clear()
	if not sector.is_empty():
		industries.append(sector)
	match symbol:
		"ALPH":
			if not industries.has("Growth"):
				industries.append("Growth")
		"GRNE":
			if not industries.has("Growth"):
				industries.append("Growth")
			if not industries.has("Commodities"):
				industries.append("Commodities")
		"NMIN":
			if not industries.has("Commodities"):
				industries.append("Commodities")


func in_industry(industry_name: String) -> bool:
	return sector == industry_name or industries.has(industry_name)


func interpret_news(headline_impact: float, is_major: bool, market_sentiment: float, news_category: String = "general") -> Dictionary:
	var headline_sign: float = signf(headline_impact)
	var headline_size: float = absf(headline_impact)
	if headline_sign == 0.0 or headline_size <= 0.0:
		return {"move": 0.0, "reaction": ""}

	var category: String = news_category if news_category != "" else "general"
	var category_mult: float = float(news_sensitivity.get(category, news_sensitivity.get("general", 1.0)))

	var combined_mood: float = clampf(market_sentiment * 0.65 + sentiment * 0.35, -1.0, 1.0)
	var alignment: float = clampf(0.55 + headline_sign * combined_mood * 0.5, 0.08, 1.2)

	var ignore_chance: float = 0.07 if is_major else 0.2
	if headline_sign > 0.0 and combined_mood > 0.3:
		ignore_chance += 0.12
	elif headline_sign < 0.0 and combined_mood < -0.3:
		ignore_chance += 0.08
	if trend == Trend.SIDEWAYS:
		ignore_chance += 0.04
	if category == "rumor":
		ignore_chance += lerpf(0.22, -0.12, speculation_factor)
	elif category == "earnings":
		ignore_chance += lerpf(-0.04, 0.10, speculation_factor)

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
	if category == "earnings" and speculation_factor > 0.7:
		fade_chance += 0.18
	elif category == "rumor" and speculation_factor < 0.35:
		fade_chance += 0.12

	if is_major:
		ignore_chance *= 0.45
		fade_chance *= 0.5
	if category_mult < 0.5:
		ignore_chance = clampf(ignore_chance + 0.18, 0.0, 0.7)

	if randf() < ignore_chance:
		return {
			"move": 0.0,
			"reaction": _ignore_reaction(category),
		}

	if randf() < fade_chance:
		var fade_move: float = -headline_sign * headline_size * randf_range(0.25, 0.7) * maxf(category_mult, 0.4)
		return {"move": fade_move, "reaction": _fade_reaction(category, headline_sign)}

	var actual_move: float = headline_impact * alignment * category_mult * randf_range(0.65, 1.05)
	if speculation_factor > 0.75:
		actual_move *= randf_range(0.7, 1.45)
	var reaction: String = _follow_reaction(category, headline_sign, alignment, actual_move)
	return {"move": actual_move, "reaction": reaction}


func _ignore_reaction(category: String) -> String:
	match category:
		"rumor":
			if speculation_factor < 0.4:
				return "Little reaction — this name does not trade on chatter."
			return "Little reaction — traders treat it as already priced in."
		"earnings":
			if speculation_factor > 0.7:
				return "The print is ignored — this name still trades the next rumor."
			return "Little reaction — traders treat it as already priced in."
		"commodity":
			return "Muted — commodity names wait for the tape, not the headline."
		_:
			return "Little reaction — traders treat it as already priced in."


func _fade_reaction(category: String, headline_sign: float) -> String:
	if category == "earnings" and speculation_factor > 0.7:
		return "Traders fade the print — this name lives on rumors, not results."
	if category == "rumor" and speculation_factor < 0.4:
		return "Institutions fade the chatter and stay with the longer-term tape."
	if headline_sign > 0.0:
		return "Selling into the news as broader sentiment stays weak."
	return "Dip buyers step in despite the headline."


func _follow_reaction(category: String, headline_sign: float, alignment: float, actual_move: float) -> String:
	if alignment < 0.4:
		return "Muted reaction amid mixed or cautious sentiment."
	match category:
		"product":
			return "Growth money chases the product cycle." if headline_sign > 0.0 else "Product-cycle names sell the delay."
		"commodity":
			return "The miner tracks the commodity tape."
		"regulatory":
			return "Policy-sensitive names swing hard on the headline."
		"rumor":
			return "Speculative flow piles into the rumor." if headline_sign > 0.0 else "Hot money dumps on the whisper."
		"earnings":
			if headline_sign > 0.0 and actual_move > 0.0:
				return "The print lands — buyers follow the numbers."
			return "Sellers press the stock on the miss."
		_:
			if headline_sign > 0.0 and actual_move > 0.0:
				return "Buyers respond to the headline."
			if headline_sign < 0.0 and actual_move < 0.0:
				return "Sellers press the stock on the news."
			return ""


func roll_to_next_day() -> void:
	previous_close = price
	news_move_remaining = 0.0
	news_move_ticks = 0
	news_initial_ticks = 0
	news_is_major = false
	news_is_lasting = false
	revert_remaining = 0.0
	revert_ticks = 0
	lasting_bias = 0.0
	lasting_ticks = 0
	momentum = 0.0
	volume = randi_range(800000, 2500000)
	price_history = PackedFloat32Array()
	volume_history = PackedInt32Array()
	last_tick_volume = randi_range(40000, 90000)
	_update_spread()
	_record_history()


func apply_saved_close(close_price: float) -> void:
	price = clampf(close_price, MIN_PRICE, MAX_PRICE)
	roll_to_next_day()


func apply_overnight_gap(gap_pct: float, is_major: bool = true, lasting: bool = true) -> void:
	price = clampf(price * (1.0 + gap_pct), MIN_PRICE, MAX_PRICE)
	momentum = clampf(gap_pct * 0.4, -0.002, 0.002)
	sentiment = clampf(sentiment + gap_pct * (6.0 if lasting else 3.0), -1.0, 1.0)
	if gap_pct > 0.01:
		trend = Trend.BULLISH
	elif gap_pct < -0.01:
		trend = Trend.BEARISH
	news_move_remaining = gap_pct * 0.22
	news_move_ticks = 10
	news_initial_ticks = 10
	news_is_major = is_major
	news_is_lasting = lasting
	revert_remaining = 0.0
	revert_ticks = 0
	if lasting:
		_set_lasting_bias(gap_pct, is_major)
	else:
		_queue_flash_revert(gap_pct)
	last_tick_volume = int(abs(gap_pct) * 1200000.0 * popularity) + randi_range(60000, 140000)
	volume += last_tick_volume
	_update_spread()
	_record_history()


func get_day_change() -> float:
	return price - previous_close


func get_day_change_pct() -> float:
	if previous_close <= 0.0:
		return 0.0
	return ((price - previous_close) / previous_close) * 100.0


func apply_news_impact(total_move: float, duration_ticks: int, is_major: bool = false, lasting: bool = false) -> void:
	news_move_remaining = total_move
	news_move_ticks = maxi(duration_ticks, 1)
	news_initial_ticks = news_move_ticks
	news_is_major = is_major
	news_is_lasting = lasting
	revert_remaining = 0.0
	revert_ticks = 0
	if total_move == 0.0:
		news_move_ticks = 0
		news_initial_ticks = 0
		news_is_major = false
		return
	if lasting:
		sentiment = clampf(sentiment + total_move * 8.0, -1.0, 1.0)
		_set_lasting_bias(total_move, is_major)
		if total_move > 0.004:
			trend = Trend.BULLISH
		elif total_move < -0.004:
			trend = Trend.BEARISH
	else:
		sentiment = clampf(sentiment + total_move * 3.0, -1.0, 1.0)
		_queue_flash_revert(total_move)
		if total_move > 0.004 and randf() < 0.22:
			trend = Trend.BULLISH
		elif total_move < -0.004 and randf() < 0.22:
			trend = Trend.BEARISH


func tick(p_market_sentiment: float = 0.0) -> void:
	var major_news_active: bool = news_is_major and news_move_ticks > 0
	var news_move: float = _consume_news_or_revert()

	if randf() < trend_flip_chance:
		trend = Trend.values()[randi() % Trend.size()]

	var base_random: float = randf_range(-0.00028, 0.00028) * volatility
	var trend_move: float = _get_trend_drift() * volatility
	var momentum_move: float = clampf(momentum * 0.1, -0.00012, 0.00012)
	var growth_bias: float = (growth - 0.5) * 0.00003
	var mood_bias: float = clampf(p_market_sentiment * 0.00008 + sentiment * 0.00005, -0.00016, 0.00016)

	var volume_factor: float = clampf(float(volume) / 15000.0, 0.5, 2.0)
	var liquidity_noise: float = randf_range(-0.00012, 0.00012) * (1.0 - liquidity) / volume_factor

	if lasting_ticks > 0:
		mood_bias += lasting_bias
		lasting_ticks -= 1
		lasting_bias *= 0.988
	else:
		lasting_bias = 0.0

	var organic_change: float = base_random + trend_move + momentum_move + growth_bias + liquidity_noise + mood_bias
	organic_change *= lerpf(0.92, 1.08, speculation_factor)
	if speculation_factor > 0.8 and randf() < 0.012:
		organic_change += randf_range(-0.0011, 0.0011)
	var organic_cap: float = MAX_NORMAL_TICK_CHANGE * clampf(volatility, 0.5, 1.6)
	organic_change = clampf(organic_change, -organic_cap, organic_cap)

	var total_change: float = organic_change + news_move
	if major_news_active:
		total_change = clampf(total_change, -MAX_MAJOR_TICK_CHANGE, MAX_MAJOR_TICK_CHANGE)
	elif news_move != 0.0:
		total_change = clampf(total_change, -MAX_ROUTINE_NEWS_TICK_CHANGE, MAX_ROUTINE_NEWS_TICK_CHANGE)
	else:
		total_change = clampf(total_change, -organic_cap, organic_cap)

	momentum = clampf(momentum * 0.82 + total_change * 1.5, -0.002, 0.002)
	price = clampf(price * (1.0 + total_change), MIN_PRICE, MAX_PRICE)

	var tick_volume: int = randi_range(25000, 70000) + int(abs(total_change) * 9000000.0 * popularity)
	last_tick_volume = tick_volume
	volume += tick_volume

	_update_spread()
	_record_history()


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


func _consume_news_or_revert() -> float:
	if news_move_ticks > 0:
		return _consume_news_move()
	if revert_ticks <= 0:
		return 0.0
	var move: float = revert_remaining / float(revert_ticks)
	revert_remaining -= move
	revert_ticks -= 1
	if revert_ticks <= 0:
		revert_remaining = 0.0
	return move


func _set_lasting_bias(move: float, is_major: bool) -> void:
	var extra: float = 0.00008 if is_major else 0.000045
	lasting_bias = clampf(lasting_bias + signf(move) * extra, -0.00022, 0.00022)
	var hold: int = 70 if is_major else 42
	lasting_ticks = maxi(lasting_ticks, hold)


func _queue_flash_revert(move: float) -> void:
	if absf(move) < 0.001:
		return
	revert_remaining = -move * randf_range(0.38, 0.78)
	revert_ticks = randi_range(6, 14)


func _get_trend_drift() -> float:
	match trend:
		Trend.BULLISH:
			return 0.00004
		Trend.BEARISH:
			return -0.00004
		_:
			return 0.0


func _record_history() -> void:
	price_history.append(price)
	volume_history.append(last_tick_volume)
	if price_history.size() > 500:
		price_history.remove_at(0)
	if volume_history.size() > 500:
		volume_history.remove_at(0)


func get_chart_slice(max_points: int, stride: int = 1) -> Dictionary:
	var prices: PackedFloat32Array = PackedFloat32Array()
	var volumes: PackedInt32Array = PackedInt32Array()
	if price_history.is_empty():
		return {"prices": prices, "volumes": volumes}

	var step: int = maxi(stride, 1)
	var start: int = maxi(price_history.size() - max_points * step, 0)
	var last_sampled: int = -1
	var i: int = start
	while i < price_history.size():
		prices.append(price_history[i])
		if i < volume_history.size():
			volumes.append(volume_history[i])
		last_sampled = i
		i += step

	var last_index: int = price_history.size() - 1
	if last_sampled != last_index:
		prices.append(price_history[last_index])
		if last_index < volume_history.size():
			volumes.append(volume_history[last_index])

	return {"prices": prices, "volumes": volumes}


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
