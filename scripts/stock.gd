class_name Stock
extends RefCounted

enum Trend { BULLISH, BEARISH, SIDEWAYS }

const MIN_PRICE := 1.0
const DISTRESSED_FLOOR := 0.05
const MAX_PRICE := 1000.0
const MAX_NORMAL_TICK_CHANGE := 0.0016
const MAX_ROUTINE_NEWS_TICK_CHANGE := 0.006
const MAX_MAJOR_TICK_CHANGE := 0.12

const LISTING_LISTED := "listed"
const LISTING_HALTED := "halted"
const LISTING_DISTRESSED := "distressed"

const HALT_EXISTENTIAL := "existential"
const HALT_VOLATILITY := "volatility"

const OUTCOME_RESUME := "resume"
const OUTCOME_DISTRESS := "distress"

const CIRCUIT_LOOKBACK := 5

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
var risk_key: String = "growth"
var news_mult: float = 1.0
var news_abs_cap: float = 0.048
var organic_mult: float = 1.0
var tick_cap_mult: float = 1.0
var routine_cap_mult: float = 1.0
var major_cap_mult: float = 1.0
var drama_mult: float = 1.0
var fade_bonus: float = 0.0
var surprise_mult: float = 1.0
var revert_mult: float = 1.0
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
var digest_queue: Array = []

var previous_close: float
var last_tick_volume: int = 0
var price_history: PackedFloat32Array = PackedFloat32Array()
var volume_history: PackedInt32Array = PackedInt32Array()

var listing: String = LISTING_LISTED
var halt_ticks: int = 0
var reopen_at_open: bool = false
var reopen_price: float = 0.0
var halt_reason: String = ""
var halt_outcome: String = OUTCOME_DISTRESS
var last_reopen: String = ""
var circuit_used_today: bool = false
var just_reopened: bool = false
var just_halted: bool = false


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
	price = clampf(start_price, floor_price(), MAX_PRICE)
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
	var profile: Dictionary = CompanyCatalog.spec(symbol)
	if profile.is_empty():
		personality_label = "Balanced"
		news_sensitivity = {"general": 1.0}
		return
	personality_label = str(profile["label"])
	volatility = float(profile["volatility"])
	growth = float(profile["growth"])
	liquidity = float(profile["liquidity"])
	popularity = float(profile["popularity"])
	institutional_ownership = float(profile["institutional_ownership"])
	speculation_factor = float(profile["speculation_factor"])
	trend_flip_chance = float(profile["trend_flip"])
	news_sensitivity = (profile["news"] as Dictionary).duplicate()
	risk_key = CompanyCatalog.risk_key(symbol)
	var risk: Dictionary = CompanyCatalog.risk_profile(symbol)
	news_mult = float(risk["news_mult"])
	news_abs_cap = float(risk["news_abs_cap"])
	organic_mult = float(risk["organic_mult"])
	tick_cap_mult = float(risk["tick_cap_mult"])
	routine_cap_mult = float(risk["routine_cap_mult"])
	major_cap_mult = float(risk["major_cap_mult"])
	drama_mult = float(risk["drama_mult"])
	fade_bonus = float(risk["fade_bonus"])
	surprise_mult = float(risk["surprise_mult"])
	revert_mult = float(risk["revert_mult"])


func _assign_industries() -> void:
	industries.clear()
	var profile: Dictionary = CompanyCatalog.spec(symbol)
	var listed: Variant = profile.get("industries", [])
	if typeof(listed) == TYPE_ARRAY:
		for item in listed:
			var name: String = str(item)
			if not name.is_empty() and not industries.has(name):
				industries.append(name)
	if industries.is_empty() and not sector.is_empty():
		industries.append(sector)


func in_industry(industry_name: String) -> bool:
	return sector == industry_name or industries.has(industry_name)


func is_listed() -> bool:
	return listing == LISTING_LISTED


func is_halted() -> bool:
	return listing == LISTING_HALTED


func is_distressed() -> bool:
	return listing == LISTING_DISTRESSED


func can_buy() -> bool:
	return listing == LISTING_LISTED


func can_sell() -> bool:
	return listing != LISTING_HALTED


func floor_price() -> float:
	if listing == LISTING_DISTRESSED:
		return DISTRESSED_FLOOR
	return MIN_PRICE


func listing_label() -> String:
	match listing:
		LISTING_HALTED:
			if halt_outcome == OUTCOME_RESUME:
				return "HALTED · listed"
			return "HALTED · make-or-break"
		LISTING_DISTRESSED:
			return "DISTRESSED"
		_:
			return personality_label.to_upper()


func halt_stamp() -> String:
	if halt_outcome == OUTCOME_RESUME:
		return "HALTED · volatility pause · reopens listed"
	return "HALTED · make-or-break · reopens distressed"


func halt_tooltip() -> String:
	if listing == LISTING_DISTRESSED:
		return CopyHints.HUD_DISTRESSED
	if listing != LISTING_HALTED:
		return ""
	if halt_outcome == OUTCOME_RESUME:
		return CopyHints.HUD_HALTED_RESUME
	return CopyHints.HUD_HALTED_DISTRESS


func begin_halt(until_open: bool, reason: String = HALT_EXISTENTIAL, outcome: String = OUTCOME_DISTRESS) -> void:
	if listing == LISTING_DISTRESSED or listing == LISTING_HALTED:
		return
	listing = LISTING_HALTED
	halt_reason = reason
	halt_outcome = outcome if outcome == OUTCOME_RESUME else OUTCOME_DISTRESS
	just_reopened = false
	just_halted = true
	last_reopen = ""
	reopen_at_open = until_open
	if until_open:
		halt_ticks = 0
	elif halt_outcome == OUTCOME_RESUME:
		halt_ticks = randi_range(2, 5)
	else:
		halt_ticks = randi_range(3, 8)
	if halt_outcome == OUTCOME_DISTRESS:
		reopen_price = maxf(DISTRESSED_FLOOR, price * randf_range(0.05, 0.20))
	else:
		reopen_price = price
	news_move_remaining = 0.0
	news_move_ticks = 0
	news_initial_ticks = 0
	news_is_major = false
	news_is_lasting = false
	revert_remaining = 0.0
	revert_ticks = 0
	lasting_bias = 0.0
	lasting_ticks = 0
	digest_queue.clear()
	momentum = 0.0
	_update_spread()


func reopen() -> void:
	if listing != LISTING_HALTED:
		return
	if halt_outcome == OUTCOME_RESUME:
		reopen_listed()
	else:
		reopen_distressed()


func reopen_listed() -> void:
	listing = LISTING_LISTED
	halt_ticks = 0
	reopen_at_open = false
	just_reopened = true
	just_halted = false
	last_reopen = OUTCOME_RESUME
	price = clampf(price * (1.0 + randf_range(-0.008, 0.008)), floor_price(), MAX_PRICE)
	halt_reason = ""
	reopen_price = 0.0
	last_tick_volume = randi_range(90000, 180000)
	volume += last_tick_volume
	_update_spread()
	_record_history()


func reopen_distressed() -> void:
	if listing == LISTING_DISTRESSED:
		return
	listing = LISTING_DISTRESSED
	halt_ticks = 0
	reopen_at_open = false
	just_reopened = true
	just_halted = false
	last_reopen = OUTCOME_DISTRESS
	halt_reason = HALT_EXISTENTIAL
	halt_outcome = OUTCOME_DISTRESS
	price = clampf(reopen_price if reopen_price > 0.0 else price * 0.1, DISTRESSED_FLOOR, MAX_PRICE)
	trend = Trend.BEARISH
	sentiment = -1.0
	momentum = -0.002
	news_move_remaining = 0.0
	news_move_ticks = 0
	lasting_bias = 0.0
	lasting_ticks = 0
	digest_queue.clear()
	last_tick_volume = randi_range(180000, 420000)
	volume += last_tick_volume
	_update_spread()
	_record_history()


func serialize_listing() -> Dictionary:
	return {
		"listing": listing,
		"halt_ticks": halt_ticks,
		"reopen_at_open": reopen_at_open,
		"reopen_price": reopen_price,
		"halt_reason": halt_reason,
		"halt_outcome": halt_outcome,
		"circuit_used_today": circuit_used_today,
	}


func apply_listing(data: Dictionary) -> void:
	listing = str(data.get("listing", LISTING_LISTED))
	if listing != LISTING_HALTED and listing != LISTING_DISTRESSED:
		listing = LISTING_LISTED
	halt_ticks = int(data.get("halt_ticks", 0))
	reopen_at_open = bool(data.get("reopen_at_open", false))
	reopen_price = float(data.get("reopen_price", 0.0))
	halt_reason = str(data.get("halt_reason", ""))
	halt_outcome = str(data.get("halt_outcome", OUTCOME_DISTRESS))
	if halt_outcome != OUTCOME_RESUME:
		halt_outcome = OUTCOME_DISTRESS
	circuit_used_today = bool(data.get("circuit_used_today", false))
	price = clampf(price, floor_price(), MAX_PRICE)
	_update_spread()


func interpret_news(
	headline_impact: float,
	is_major: bool,
	market_sentiment: float,
	news_category: String = "general",
	climate: String = "normal",
	weather: String = ""
) -> Dictionary:
	var headline_sign: float = signf(headline_impact)
	var headline_size: float = absf(headline_impact)
	if headline_sign == 0.0 or headline_size <= 0.0:
		return {"move": 0.0, "reaction": "", "pulses": []}

	var category: String = news_category if news_category != "" else "general"
	var category_mult: float = float(news_sensitivity.get(category, news_sensitivity.get("general", 1.0)))
	var combined_mood: float = clampf(market_sentiment * 0.65 + sentiment * 0.35, -1.0, 1.0)
	var day_pct: float = get_day_change_pct()
	var clarity: float = _news_clarity(category, category_mult, headline_sign, combined_mood, is_major, weather)
	var thesis: Dictionary = _news_thesis(headline_impact, headline_sign, headline_size, category, category_mult, combined_mood, day_pct, climate, weather, is_major)
	var total_move: float = clampf(float(thesis["move"]) * news_mult, -news_abs_cap, news_abs_cap)
	var wait: int = _read_delay(clarity, is_major, absf(total_move))
	var pulses: Array = _build_digest_pulses(total_move, wait, clarity, is_major)
	var reaction: String = str(thesis["reaction"])
	if _pulses_hesitate(pulses):
		reaction = "Desks are split — the first reaction may reverse as they finish reading it."
	elif wait >= 12:
		reaction = "Still digesting — a larger move may show up after the tape processes it."
	elif reaction.is_empty():
		reaction = "The headline is out; flow has not fully shown up yet."
	return {
		"move": total_move,
		"reaction": reaction,
		"clarity": clarity,
		"pulses": pulses,
	}


func _news_clarity(category: String, category_mult: float, headline_sign: float, combined_mood: float, is_major: bool, weather: String) -> float:
	var clarity: float = 0.52 + (category_mult - 1.0) * 0.28
	match category:
		"rumor":
			clarity -= 0.24
		"analyst":
			clarity -= 0.1
		"macro":
			clarity -= 0.06
		"earnings", "product":
			clarity += 0.14
		"regulatory":
			clarity -= 0.04
		"commodity":
			clarity += 0.06
	if headline_sign * combined_mood < 0.0:
		clarity -= 0.2
	if weather == "high_vol":
		clarity -= 0.12
	elif weather == "panic" or weather == "euphoria":
		clarity -= 0.05
	if is_major:
		clarity += 0.08
	clarity += randf_range(-0.1, 0.1)
	return clampf(clarity, 0.1, 0.92)


func _read_delay(clarity: float, is_major: bool, move_size: float) -> int:
	var seconds: float = lerpf(26.0, 3.5, clarity)
	if is_major:
		seconds *= 0.78
	if move_size > 0.025 and clarity < 0.45:
		seconds += lerpf(14.0, 4.0, clarity)
	seconds *= lerpf(1.22, 0.62, speculation_factor)
	seconds *= randf_range(0.72, 1.38)
	return clampi(int(round(seconds)), 2, 42)


func _news_thesis(
	headline_impact: float,
	headline_sign: float,
	headline_size: float,
	category: String,
	category_mult: float,
	combined_mood: float,
	day_pct: float,
	climate: String,
	weather: String,
	is_major: bool
) -> Dictionary:
	var priced_in: float = 0.1 if is_major else 0.18
	priced_in += randf_range(-0.04, 0.06)
	if headline_sign < 0.0:
		priced_in += 0.08
		if combined_mood < -0.25 or day_pct < -1.2:
			priced_in += 0.16
		if climate == "bear" or weather == "panic":
			priced_in += 0.08
	else:
		if combined_mood > 0.35 or day_pct > 1.4:
			priced_in += 0.12
		if climate == "bull" or weather == "euphoria":
			priced_in += 0.06
	if category == "rumor":
		priced_in += lerpf(0.16, -0.06, speculation_factor)
	if category_mult < 0.5:
		priced_in += 0.14

	var fade_chance: float = 0.06 if is_major else 0.11
	fade_chance += fade_bonus
	fade_chance += randf_range(-0.03, 0.05)
	if headline_sign > 0.0:
		fade_chance += maxf(0.0, -combined_mood) * 0.35
		if trend == Trend.BEARISH or climate == "bear" or weather == "panic":
			fade_chance += 0.12
	else:
		fade_chance += maxf(0.0, combined_mood) * 0.25
		if trend == Trend.BULLISH or climate == "bull" or weather == "euphoria":
			fade_chance += 0.1
	if category == "earnings" and speculation_factor > 0.7:
		fade_chance += 0.14

	var surprise_chance: float = (0.07 if is_major else 0.1) * surprise_mult
	if weather == "high_vol":
		surprise_chance += 0.08 * surprise_mult
	if is_major:
		priced_in *= 0.55
		fade_chance *= 0.55
		surprise_chance *= 0.7
	priced_in = clampf(priced_in, 0.04, 0.48)
	fade_chance = clampf(fade_chance, 0.03, 0.42)

	var roll: float = randf()
	if roll < priced_in:
		var drip: float = headline_sign * headline_size * randf_range(0.0, 0.12) * category_mult
		if randf() < 0.4:
			drip = 0.0
		return {"move": drip, "reaction": _priced_in_reaction(headline_sign, category)}
	roll -= priced_in
	if roll < fade_chance:
		var fade_scale: float = randf_range(0.18, 0.85) * maxf(category_mult, 0.35)
		return {"move": -headline_sign * headline_size * fade_scale, "reaction": _fade_reaction(category, headline_sign)}
	roll -= fade_chance
	if roll < surprise_chance:
		var surprise: Dictionary = _surprise_reaction(headline_sign, headline_size, category_mult, category)
		return {"move": float(surprise["move"]) + float(surprise.get("delay_move", 0.0)) * 0.35, "reaction": str(surprise["reaction"])}

	var follow: float = headline_impact * category_mult * randf_range(0.28, 1.55)
	follow *= randf_range(0.85, 1.15)
	if speculation_factor > 0.75:
		follow *= randf_range(0.55, 1.7)
	if weather == "high_vol":
		follow *= randf_range(0.6, 1.6)
	return {"move": follow, "reaction": _follow_reaction(category, headline_sign, 0.7, follow)}


func _build_digest_pulses(total_move: float, wait: int, clarity: float, is_major: bool) -> Array:
	var pulses: Array = []
	if absf(total_move) < 0.00025:
		return pulses

	var hesitate: float = clampf(lerpf(0.42, 0.08, clarity) + randf_range(-0.06, 0.08), 0.05, 0.5)
	var unclear_big: bool = absf(total_move) > 0.012 and clarity < 0.48
	var duration: int = randi_range(6, 14) if not is_major else randi_range(10, 22)

	if unclear_big:
		var probe: float = total_move * randf_range(0.12, 0.32)
		var rest: float = total_move - probe
		pulses.append(_pulse(wait, probe, maxi(duration - 4, 4), is_major, false))
		var rest_wait: int = wait + randi_range(6, 18)
		if randf() < hesitate:
			rest *= -randf_range(0.35, 1.15)
			pulses.append(_pulse(rest_wait, rest, duration, is_major, false))
			pulses.append(_pulse(rest_wait + randi_range(5, 16), total_move * randf_range(0.4, 1.1), duration, is_major, is_major))
		else:
			pulses.append(_pulse(rest_wait, rest, duration, is_major, is_major))
		return pulses

	pulses.append(_pulse(wait, total_move, duration, is_major, is_major and absf(total_move) > 0.008))
	if randf() < hesitate:
		var swing: float = -total_move * randf_range(0.35, 1.25)
		if randf() < 0.45:
			swing = total_move * randf_range(0.4, 0.95)
		pulses.append(_pulse(wait + randi_range(5, 20), swing, randi_range(5, 14), false, false))
	return pulses


func _pulse(wait: int, move: float, duration: int, is_major: bool, lasting: bool) -> Dictionary:
	return {
		"wait": maxi(wait, 2),
		"move": move,
		"duration": maxi(duration, 3),
		"major": is_major,
		"lasting": lasting,
	}


func _pulses_hesitate(pulses: Array) -> bool:
	if pulses.size() < 2:
		return false
	var first_sign: float = signf(float((pulses[0] as Dictionary).get("move", 0.0)))
	for i in range(1, pulses.size()):
		var pulse: Dictionary = pulses[i]
		var pulse_sign: float = signf(float(pulse.get("move", 0.0)))
		if first_sign != 0.0 and pulse_sign != 0.0 and pulse_sign != first_sign:
			return true
	return false


func _priced_in_reaction(headline_sign: float, category: String) -> String:
	if headline_sign < 0.0:
		return "Already in the price — the bad news does not land a fresh hit."
	if category == "rumor":
		return "Little reaction — traders treat it as already priced in."
	return "Buyers hesitate — the good news does not pay immediately."


func _delay_reaction(headline_sign: float) -> String:
	if headline_sign > 0.0:
		return "Muted at first — desks wait to see if the bid is real."
	return "Slow to react — the tape has not fully digested the headline."


func _stagger_reaction(headline_sign: float, actual_move: float) -> String:
	if headline_sign > 0.0 and actual_move > 0.0:
		return "A partial bid — the rest may leak in later, or not."
	if headline_sign < 0.0 and actual_move < 0.0:
		return "Only a partial hit — more selling could still show up."
	return "Uneven tape — the headline is not trading one-for-one."


func _surprise_reaction(headline_sign: float, headline_size: float, category_mult: float, category: String) -> Dictionary:
	var kind: float = randf()
	if kind < 0.4:
		return {
			"move": -headline_sign * headline_size * randf_range(0.4, 1.1) * maxf(category_mult, 0.4),
			"delay_move": 0.0,
			"delay_ticks": 0,
			"reaction": "Unexpected tape — flow goes the other way.",
		}
	if kind < 0.7:
		return {
			"move": headline_sign * headline_size * randf_range(1.4, 2.2) * category_mult,
			"delay_move": -headline_sign * headline_size * randf_range(0.3, 0.8),
			"delay_ticks": randi_range(5, 16),
			"reaction": "Knee-jerk overreaction — this may not hold.",
		}
	return {
		"move": headline_sign * headline_size * randf_range(-0.4, 0.4),
		"delay_move": headline_sign * headline_size * category_mult * randf_range(0.5, 1.2),
		"delay_ticks": randi_range(10, 36),
		"reaction": _delay_reaction(headline_sign) if category != "rumor" else "Choppy reaction — the rumor is not clean.",
	}


func _ignore_reaction(category: String) -> String:
	match category:
		"rumor":
			if speculation_factor < 0.4:
				return "Little reaction — this stock does not trade on chatter."
			return "Little reaction — traders treat it as already priced in."
		"earnings":
			if speculation_factor > 0.7:
				return "The numbers are ignored — this stock still trades the next rumor."
			return "Little reaction — traders treat it as already priced in."
		"commodity":
			return "Muted — commodity stocks wait for the tape, not the headline."
		_:
			return "Little reaction — traders treat it as already priced in."


func _fade_reaction(category: String, headline_sign: float) -> String:
	if category == "earnings" and speculation_factor > 0.7:
		return "Traders fade the numbers — this stock lives on rumors, not results."
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
			return "Growth money chases the product cycle." if headline_sign > 0.0 else "Product-cycle stocks sell the delay."
		"commodity":
			return "The miner tracks the commodity tape."
		"regulatory":
			return "Policy-sensitive stocks swing hard on the headline."
		"rumor":
			return "Speculative flow piles into the rumor." if headline_sign > 0.0 else "Hot money dumps on the whisper."
		"earnings":
			if headline_sign > 0.0 and actual_move > 0.0:
				return "The numbers land — buyers follow them."
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
	digest_queue.clear()
	momentum = 0.0
	volume = randi_range(800000, 2500000)
	price_history = PackedFloat32Array()
	volume_history = PackedInt32Array()
	last_tick_volume = randi_range(40000, 90000)
	circuit_used_today = false
	_update_spread()
	_record_history()


func apply_saved_close(close_price: float) -> void:
	price = clampf(close_price, floor_price(), MAX_PRICE)
	roll_to_next_day()


func apply_overnight_gap(gap_pct: float, is_major: bool = true, lasting: bool = true) -> void:
	if not is_listed():
		return
	price = clampf(price * (1.0 + gap_pct), floor_price(), MAX_PRICE)
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


func apply_interpreted_news(result: Dictionary, duration_ticks: int, is_major: bool, lasting: bool, overnight: bool = false) -> void:
	if not is_listed():
		return
	var pulses: Array = result.get("pulses", [])
	var duration: int = maxi(int(round(float(duration_ticks) * randf_range(0.65, 1.45))), 3)
	if typeof(pulses) != TYPE_ARRAY or pulses.is_empty():
		return
	for item in pulses:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var pulse: Dictionary = item
		var wait: int = int(pulse.get("wait", 4))
		if overnight:
			wait = maxi(2, int(round(float(wait) * 0.45)) - randi_range(0, 3))
		digest_queue.append({
			"wait": wait,
			"move": float(pulse.get("move", 0.0)),
			"duration": maxi(int(pulse.get("duration", duration)), 3),
			"major": bool(pulse.get("major", is_major)),
			"lasting": bool(pulse.get("lasting", lasting)),
		})


func queue_scripted_move(wait: int, move: float, duration: int, is_major: bool, lasting: bool) -> void:
	if not is_listed():
		return
	if absf(move) < 0.0004:
		return
	digest_queue.append({
		"wait": maxi(wait, 2),
		"move": move,
		"duration": maxi(duration, 4),
		"major": is_major,
		"lasting": lasting,
	})


func apply_news_impact(total_move: float, duration_ticks: int, is_major: bool = false, lasting: bool = false) -> void:
	if not is_listed():
		return
	if absf(total_move) < 0.0002:
		return
	if news_move_ticks > 0:
		news_move_remaining += total_move
		news_move_ticks = maxi(news_move_ticks, duration_ticks)
		news_initial_ticks = maxi(news_initial_ticks, news_move_ticks)
		news_is_major = news_is_major or is_major
		news_is_lasting = news_is_lasting or lasting
	else:
		news_move_remaining = total_move
		news_move_ticks = maxi(duration_ticks, 1)
		news_initial_ticks = news_move_ticks
		news_is_major = is_major
		news_is_lasting = lasting
		revert_remaining = 0.0
		revert_ticks = 0
	if lasting:
		sentiment = clampf(sentiment + total_move * randf_range(4.0, 9.0), -1.0, 1.0)
		_set_lasting_bias(total_move, is_major)
		if absf(total_move) > 0.004 and randf() < 0.55:
			trend = Trend.BULLISH if total_move > 0.0 else Trend.BEARISH
	else:
		sentiment = clampf(sentiment + total_move * randf_range(1.5, 4.5), -1.0, 1.0)
		if randf() < 0.55:
			_queue_flash_revert(total_move)
		if absf(total_move) > 0.004 and randf() < 0.18:
			trend = Trend.BULLISH if total_move > 0.0 else Trend.BEARISH


func tick(p_market_sentiment: float = 0.0, p_regime: Dictionary = {}, allow_circuit: bool = true) -> void:
	just_reopened = false
	just_halted = false
	if listing == LISTING_HALTED:
		if not reopen_at_open:
			halt_ticks -= 1
			if halt_ticks <= 0:
				reopen()
				return
		last_tick_volume = randi_range(8000, 18000)
		_update_spread()
		_record_history()
		return

	_tick_digest_queue()
	var major_news_active: bool = news_is_major and news_move_ticks > 0
	var news_move: float = _consume_news_or_revert()
	var vol_mult: float = float(p_regime.get("vol_mult", 1.0))
	var flip_mult: float = float(p_regime.get("flip_mult", 1.0))
	var regime_drift: float = float(p_regime.get("drift", 0.0))
	var volume_mult: float = float(p_regime.get("volume_mult", 1.0))

	if randf() < trend_flip_chance * flip_mult:
		trend = Trend.values()[randi() % Trend.size()]

	var base_random: float = randf_range(-0.00028, 0.00028) * volatility * vol_mult
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

	var organic_change: float = base_random + trend_move + momentum_move + growth_bias + liquidity_noise + mood_bias + regime_drift
	organic_change *= lerpf(0.92, 1.08, speculation_factor) * organic_mult
	if listing == LISTING_DISTRESSED:
		organic_change *= 0.35
		news_move = 0.0
	if speculation_factor > 0.8 and randf() < 0.012 * flip_mult:
		organic_change += randf_range(-0.0011, 0.0011) * organic_mult
	var cap_mult: float = clampf(lerpf(1.0, 1.4, (vol_mult - 1.0) / 0.7), 1.0, 1.45)
	var organic_cap: float = MAX_NORMAL_TICK_CHANGE * clampf(volatility, 0.5, 1.6) * cap_mult * tick_cap_mult
	organic_change = clampf(organic_change, -organic_cap, organic_cap)

	var total_change: float = organic_change + news_move
	if major_news_active:
		total_change = clampf(total_change, -MAX_MAJOR_TICK_CHANGE * major_cap_mult, MAX_MAJOR_TICK_CHANGE * major_cap_mult)
	elif news_move != 0.0:
		total_change = clampf(total_change, -MAX_ROUTINE_NEWS_TICK_CHANGE * routine_cap_mult, MAX_ROUTINE_NEWS_TICK_CHANGE * routine_cap_mult)
	else:
		total_change = clampf(total_change, -organic_cap, organic_cap)

	momentum = clampf(momentum * 0.82 + total_change * 1.5, -0.002, 0.002)
	price = clampf(price * (1.0 + total_change), floor_price(), MAX_PRICE)

	var tick_volume: int = int(float(randi_range(25000, 70000) + int(abs(total_change) * 9000000.0 * popularity)) * volume_mult)
	last_tick_volume = tick_volume
	volume += tick_volume

	_update_spread()
	_record_history()
	_maybe_circuit_halt(allow_circuit)


func _maybe_circuit_halt(allow_circuit: bool) -> void:
	if not allow_circuit or circuit_used_today or not is_listed():
		return
	if risk_key == "safe":
		return
	if price_history.size() < CIRCUIT_LOOKBACK + 1:
		return
	var then_px: float = price_history[price_history.size() - 1 - CIRCUIT_LOOKBACK]
	if then_px < 0.05:
		return
	var window: float = absf((price - then_px) / then_px)
	var need: float = 0.05 if risk_key == "growth" else 0.08
	if window < need:
		return
	circuit_used_today = true
	begin_halt(false, HALT_VOLATILITY, OUTCOME_RESUME)


func _tick_digest_queue() -> void:
	var i: int = 0
	while i < digest_queue.size():
		var pulse: Dictionary = digest_queue[i]
		var wait: int = int(pulse.get("wait", 1)) - 1
		if wait <= 0:
			digest_queue.remove_at(i)
			apply_news_impact(
				float(pulse.get("move", 0.0)),
				int(pulse.get("duration", 8)),
				bool(pulse.get("major", false)),
				bool(pulse.get("lasting", false))
			)
		else:
			pulse["wait"] = wait
			digest_queue[i] = pulse
			i += 1


func _consume_news_move() -> float:
	if news_move_ticks <= 0:
		return 0.0

	var move: float = 0.0
	var ticks_elapsed: int = news_initial_ticks - news_move_ticks

	if news_is_major:
		if ticks_elapsed == 0:
			move = news_move_remaining * randf_range(0.22, 0.72)
		else:
			move = news_move_remaining / float(news_move_ticks)
	else:
		move = news_move_remaining * randf_range(0.7, 1.3) / float(news_move_ticks)
		move = clampf(move, -absf(news_move_remaining), absf(news_move_remaining))
		if signf(move) != signf(news_move_remaining) and news_move_remaining != 0.0:
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
	revert_remaining = -move * randf_range(0.38, 0.78) * revert_mult
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
	if listing == LISTING_HALTED:
		bid = price
		ask = price
		return
	var spread_pct: float = 0.001 + (1.0 - liquidity) * 0.003
	if listing == LISTING_DISTRESSED:
		spread_pct = 0.08 + (1.0 - liquidity) * 0.06
	bid = maxf(floor_price(), price * (1.0 - spread_pct))
	ask = price * (1.0 + spread_pct)


func get_trend_name() -> String:
	match trend:
		Trend.BULLISH:
			return "Bullish"
		Trend.BEARISH:
			return "Bearish"
		_:
			return "Sideways"
