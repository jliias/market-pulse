class_name NewsGenerator
extends RefCounted

const STRENGTH_RANGE := {
	"minor": {"day": Vector2(0.003, 0.008), "pre": Vector2(0.010, 0.022)},
	"moderate": {"day": Vector2(0.009, 0.018), "pre": Vector2(0.022, 0.042)},
	"major": {"day": Vector2(0.028, 0.055), "pre": Vector2(0.040, 0.090)},
}

const INDUSTRY_KEYS: Array[String] = ["Technology", "Energy", "Materials", "Commodities", "Growth"]

const COMPANY_NEWS := {
	"ALPH": {
		"positive": [
			{"text": "Alpha Technologies unveils a faster AI chip.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Alpha Technologies lands a multi-year cloud contract.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Analyst raises Alpha Technologies price target.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Street chatter: Alpha Technologies named a top pick.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Alpha Technologies beats a mid-quarter revenue checkpoint.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Alpha Technologies delays a flagship product launch.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Alpha Technologies warns of weaker enterprise demand.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "Analyst trims Alpha Technologies price target.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Whispers of profit-taking in Alpha Technologies.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Options flow turns sharply bearish in Alpha Technologies.", "category": "rumor", "strength": "moderate", "lasting": false},
		],
	},
	"GRNE": {
		"positive": [
			{"text": "Intraday rumor: Green Energy Corp nearing a new contract.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Regulators signal multi-year support for Green Energy Corp subsidies.", "category": "regulatory", "strength": "major", "lasting": true},
			{"text": "Analyst upgrades Green Energy Corp to Overweight.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Green Energy Corp confirms a grid-storage win.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Hot money piles into Green Energy Corp on subsidy chatter.", "category": "rumor", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Sector note warns of subsidy risk for Green Energy Corp.", "category": "regulatory", "strength": "major", "lasting": true},
			{"text": "Traders fade Green Energy Corp after the morning pop.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Analyst downgrades Green Energy Corp to Neutral.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Green Energy Corp delays a key project commissioning.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Whisper: Green Energy Corp may miss a subsidy window.", "category": "rumor", "strength": "moderate", "lasting": false},
		],
	},
	"NMIN": {
		"positive": [
			{"text": "North Mining Ltd reports steady production.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "North Mining Ltd extends a long-term offtake agreement.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Analysts flag North Mining Ltd as oversold.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Intraday bid: North Mining Ltd sees dip-buying interest.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "North Mining Ltd lifts a local output checkpoint.", "category": "earnings", "strength": "minor", "lasting": true},
		],
		"negative": [
			{"text": "North Mining Ltd flags a temporary pit disruption.", "category": "product", "strength": "moderate", "lasting": false},
			{"text": "North Mining Ltd cuts a near-term shipment guide.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "Intraday rumor: North Mining Ltd output running light.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Analyst cuts North Mining Ltd to Underweight.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Flow desks lean short North Mining Ltd into the close.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
}

const PREMARKET_COMPANY := {
	"ALPH": {
		"positive": [
			{"text": "PREMARKET: Alpha Technologies beats quarterly earnings and raises guidance.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Alpha Technologies reports record annual revenue.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Alpha Technologies misses quarterly earnings and cuts outlook.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Alpha Technologies issues a profit warning before the open.", "category": "earnings", "strength": "major", "lasting": true},
		],
	},
	"GRNE": {
		"positive": [
			{"text": "PREMARKET: Green Energy Corp beats earnings on strong project pipeline.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Green Energy Corp raises full-year guidance.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Green Energy Corp misses earnings as subsidies disappoint.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Green Energy Corp slashes annual production forecast.", "category": "earnings", "strength": "major", "lasting": true},
		],
	},
	"NMIN": {
		"positive": [
			{"text": "PREMARKET: North Mining Ltd posts better-than-expected quarterly results.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: North Mining Ltd lifts annual output guidance.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: North Mining Ltd misses earnings on weaker commodity prices.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: North Mining Ltd cuts annual production targets.", "category": "earnings", "strength": "major", "lasting": true},
		],
	},
}

const INDUSTRY_NEWS := {
	"Technology": {
		"positive": [
			{"text": "Tech sector: AI spending forecasts are raised across the group.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Chip demand firms — technology names catch a bid.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Tech sector: enterprise software demand looks softer.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Growth-tech selling hits the tape after a crowded rally.", "category": "industry", "strength": "minor", "lasting": false},
		],
	},
	"Energy": {
		"positive": [
			{"text": "Energy complex: power-price strength lifts the group.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Clean-energy policy chatter turns constructive.", "category": "regulatory", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Energy complex: subsidy reviews weigh on the group.", "category": "regulatory", "strength": "major", "lasting": true},
			{"text": "Power-price softness knocks energy names.", "category": "commodity", "strength": "minor", "lasting": false},
		],
	},
	"Materials": {
		"positive": [
			{"text": "Materials: miners catch a bid as industrial demand steadies.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Metals desks turn constructive on bulk commodities.", "category": "commodity", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Materials: industrial demand worries hit the miners.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Mining names slip as inventory data disappoints.", "category": "commodity", "strength": "minor", "lasting": false},
		],
	},
	"Commodities": {
		"positive": [
			{"text": "Commodity complex rallies — energy and metals both bid.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Risk-on in commodities as the dollar eases.", "category": "commodity", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Broad commodity selloff hits energy and materials.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Commodity tape turns heavy into the afternoon.", "category": "commodity", "strength": "minor", "lasting": false},
		],
	},
	"Growth": {
		"positive": [
			{"text": "Growth rotation: high-duration names catch a bid.", "category": "macro", "strength": "moderate", "lasting": true},
			{"text": "Risk appetite returns to growth and speculative names.", "category": "macro", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Growth unwind: traders cut duration and speculative exposure.", "category": "macro", "strength": "moderate", "lasting": true},
			{"text": "Crowded growth trades get squeezed on the offer.", "category": "macro", "strength": "minor", "lasting": false},
		],
	},
}

const MARKET_NEWS := {
	"positive": [
		{"text": "Intraday: buyers step back in across the tape.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Desk note: dip-buying interest is returning.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Soft landing print lifts risk appetite market-wide.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "Liquidity returns — the whole tape catches a bid.", "category": "macro", "strength": "moderate", "lasting": false},
	],
	"negative": [
		{"text": "Intraday: risk-off tone spreads across the market.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Desk note: traders reduce exposure into the close.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Hawkish shock knocks the whole market lower.", "category": "macro", "strength": "major", "lasting": true},
		{"text": "Liquidity thins — selling pressure hits every name.", "category": "macro", "strength": "moderate", "lasting": false},
	],
}

const MARKET_PREMARKET := {
	"positive": [
		{"text": "PREMARKET: Futures jump after overnight economic data.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "PREMARKET: Risk appetite returns after a quiet overnight session.", "category": "macro", "strength": "minor", "lasting": false},
	],
	"negative": [
		{"text": "PREMARKET: Futures slip as overnight data disappoints.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "PREMARKET: Cautious tape after weak global sentiment overnight.", "category": "macro", "strength": "minor", "lasting": false},
	],
}


var company_hits: Dictionary = {}


func generate_premarket(stocks: Array[Stock], session_time: String, avoid_subjects: Array[String] = []) -> Array[NewsEvent]:
	company_hits.clear()
	var events: Array[NewsEvent] = []
	var featured: Stock = _pick_company_stock(stocks)
	events.append(_make_company_event(featured, session_time, true))

	if randf() < 0.55:
		if randf() < 0.4:
			events.append(_make_industry_event(stocks, session_time, true))
		else:
			events.append(_make_company_event(_pick_company_stock(stocks), session_time, true))

	if randf() < 0.4:
		events.append(_make_market_event(stocks, session_time, true))

	return events


func generate_intraday(stocks: Array[Stock], session_time: String, avoid_subjects: Array[String] = []) -> NewsEvent:
	var roll := randf()
	if roll < 0.08:
		return _generate_surprise(_pick_company_stock(stocks), session_time)
	if roll < 0.28:
		return _make_industry_event(stocks, session_time, false)
	if roll < 0.46:
		return _make_market_event(stocks, session_time, false)
	return _make_company_event(_pick_company_stock(stocks), session_time, false)


func generate_open_bell(session_time: String) -> NewsEvent:
	return NewsEvent.new(
		session_time,
		"Market open. Use the premarket tape — then try to beat the market.",
		[],
		0.0,
		0.0,
		0,
		false,
		false,
		"general",
		"system"
	)


func _make_company_event(stock: Stock, session_time: String, premarket: bool) -> NewsEvent:
	var is_positive := randf() > (0.42 if premarket else 0.48)
	var pool: Dictionary = PREMARKET_COMPANY if premarket else COMPANY_NEWS
	var item: Dictionary = _pick_item(pool[stock.symbol], is_positive)
	return _from_item(item, session_time, [stock.symbol], is_positive, premarket, "company", "")


func _make_industry_event(stocks: Array[Stock], session_time: String, premarket: bool, _avoid_subjects: Array[String] = []) -> NewsEvent:
	var industry: String = INDUSTRY_KEYS[randi() % INDUSTRY_KEYS.size()]
	var names: Array[String] = _symbols_for_industry(stocks, industry)
	if names.is_empty():
		return _make_market_event(stocks, session_time, premarket)
	var is_positive := randf() > 0.48
	var item: Dictionary = _pick_item(INDUSTRY_NEWS[industry], is_positive)
	var headline: String = str(item["text"])
	if premarket and not headline.begins_with("PREMARKET"):
		headline = "PREMARKET: " + headline
	var event := _from_item(item, session_time, names, is_positive, premarket, "industry", industry)
	event.headline = headline
	return event


func _make_market_event(stocks: Array[Stock], session_time: String, premarket: bool) -> NewsEvent:
	var is_positive := randf() > 0.5
	var pool: Dictionary = MARKET_PREMARKET if premarket else MARKET_NEWS
	var item: Dictionary = _pick_item(pool, is_positive)
	var names: Array[String] = []
	for stock in stocks:
		names.append(stock.symbol)
	return _from_item(item, session_time, names, is_positive, premarket, "market", "")


func _generate_surprise(stock: Stock, session_time: String) -> NewsEvent:
	var is_positive := randf() > 0.5
	var headline: String
	if is_positive:
		headline = "BREAKING: unexpected upgrade hits %s mid-session." % stock.company_name
	else:
		headline = "BREAKING: unexpected downgrade hits %s mid-session." % stock.company_name
	var item := {
		"text": headline,
		"category": "analyst",
		"strength": "major",
		"lasting": randf() < 0.45,
	}
	return _from_item(item, session_time, [stock.symbol], is_positive, false, "company", "")


func make_from_item(
	item: Dictionary,
	session_time: String,
	symbols: Array[String],
	is_positive: bool,
	premarket: bool,
	scope: String,
	industry: String
) -> NewsEvent:
	return _from_item(item, session_time, symbols, is_positive, premarket, scope, industry)


func symbols_for_industry(stocks: Array[Stock], industry: String) -> Array[String]:
	return _symbols_for_industry(stocks, industry)


func _pick_company_stock(stocks: Array[Stock]) -> Stock:
	var lowest: int = 9999
	for stock in stocks:
		lowest = mini(lowest, int(company_hits.get(stock.symbol, 0)))
	var pool: Array[Stock] = []
	for stock in stocks:
		if int(company_hits.get(stock.symbol, 0)) <= lowest:
			pool.append(stock)
	var picked: Stock = pool[randi() % pool.size()]
	company_hits[picked.symbol] = int(company_hits.get(picked.symbol, 0)) + 1
	return picked


func _pick_unrelated_stock(stocks: Array[Stock], _avoid_subjects: Array[String]) -> Stock:
	return _pick_company_stock(stocks)


func _from_item(
	item: Dictionary,
	session_time: String,
	symbols: Array[String],
	is_positive: bool,
	premarket: bool,
	scope: String,
	industry: String
) -> NewsEvent:
	var strength: String = str(item.get("strength", "moderate"))
	var lasting: bool = bool(item.get("lasting", false))
	var category: String = str(item.get("category", "general"))
	var sentiment: float = 1.0 if is_positive else -1.0
	var impact: float = _roll_magnitude(strength, premarket, scope) * sentiment
	var duration: int = _roll_duration(strength, lasting)
	var is_major: bool = strength == "major"
	return NewsEvent.new(
		session_time,
		str(item["text"]),
		symbols,
		sentiment,
		impact,
		duration,
		is_major,
		premarket,
		category,
		scope,
		strength,
		lasting,
		industry
	)


func _roll_magnitude(strength: String, premarket: bool, scope: String) -> float:
	var profile: Dictionary = STRENGTH_RANGE.get(strength, STRENGTH_RANGE["moderate"])
	var band: Vector2 = profile["pre"] if premarket else profile["day"]
	var mag: float = randf_range(band.x, band.y)
	if scope == "industry":
		mag *= 0.85
	elif scope == "market":
		mag *= 0.72
	return mag


func _roll_duration(strength: String, lasting: bool) -> int:
	if lasting:
		match strength:
			"major":
				return randi_range(28, 48)
			"minor":
				return randi_range(16, 26)
			_:
				return randi_range(22, 36)
	match strength:
		"major":
			return randi_range(8, 14)
		"minor":
			return randi_range(3, 7)
		_:
			return randi_range(5, 11)


func _symbols_for_industry(stocks: Array[Stock], industry: String) -> Array[String]:
	var names: Array[String] = []
	for stock in stocks:
		if stock.in_industry(industry):
			names.append(stock.symbol)
	return names


func _pick_item(company_templates: Dictionary, is_positive: bool) -> Dictionary:
	var side: String = "positive" if is_positive else "negative"
	var items: Array = company_templates[side]
	var picked: Variant = items[randi() % items.size()]
	if typeof(picked) == TYPE_DICTIONARY:
		return picked
	return {"text": str(picked), "category": "general", "strength": "moderate", "lasting": false}
