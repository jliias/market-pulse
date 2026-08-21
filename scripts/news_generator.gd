class_name NewsGenerator
extends RefCounted

const PREMARKET_TEMPLATES := {
	"ALPH": {
		"positive": [
			{"text": "PREMARKET: Alpha Technologies beats quarterly earnings and raises guidance.", "category": "earnings"},
			{"text": "PREMARKET: Alpha Technologies reports record annual revenue.", "category": "earnings"},
		],
		"negative": [
			{"text": "PREMARKET: Alpha Technologies misses quarterly earnings and cuts outlook.", "category": "earnings"},
			{"text": "PREMARKET: Alpha Technologies issues a profit warning before the open.", "category": "earnings"},
		],
	},
	"GRNE": {
		"positive": [
			{"text": "PREMARKET: Green Energy Corp beats earnings on strong project pipeline.", "category": "earnings"},
			{"text": "PREMARKET: Green Energy Corp raises full-year guidance.", "category": "earnings"},
		],
		"negative": [
			{"text": "PREMARKET: Green Energy Corp misses earnings as subsidies disappoint.", "category": "earnings"},
			{"text": "PREMARKET: Green Energy Corp slashes annual production forecast.", "category": "earnings"},
		],
	},
	"NMIN": {
		"positive": [
			{"text": "PREMARKET: North Mining Ltd posts better-than-expected quarterly results.", "category": "earnings"},
			{"text": "PREMARKET: North Mining Ltd lifts annual output guidance.", "category": "earnings"},
		],
		"negative": [
			{"text": "PREMARKET: North Mining Ltd misses earnings on weaker commodity prices.", "category": "earnings"},
			{"text": "PREMARKET: North Mining Ltd cuts annual production targets.", "category": "earnings"},
		],
	},
}

const INTRADAY_TEMPLATES := {
	"ALPH": {
		"positive": [
			{"text": "Alpha Technologies unveils a faster AI chip.", "category": "product"},
			{"text": "Analyst raises Alpha Technologies price target.", "category": "analyst"},
			{"text": "Street chatter: Alpha Technologies named a top pick.", "category": "rumor"},
		],
		"negative": [
			{"text": "Alpha Technologies delays a flagship product launch.", "category": "product"},
			{"text": "Analyst trims Alpha Technologies price target.", "category": "analyst"},
			{"text": "Whispers of profit-taking in Alpha Technologies.", "category": "rumor"},
		],
	},
	"GRNE": {
		"positive": [
			{"text": "Intraday rumor: Green Energy Corp nearing a new contract.", "category": "rumor"},
			{"text": "Regulators signal support for Green Energy Corp subsidies.", "category": "regulatory"},
			{"text": "Analyst upgrades Green Energy Corp to Overweight.", "category": "analyst"},
		],
		"negative": [
			{"text": "Sector note warns of subsidy risk for Green Energy Corp.", "category": "regulatory"},
			{"text": "Traders fade Green Energy Corp after the morning pop.", "category": "rumor"},
			{"text": "Analyst downgrades Green Energy Corp to Neutral.", "category": "analyst"},
		],
	},
	"NMIN": {
		"positive": [
			{"text": "Commodity prices lift North Mining Ltd.", "category": "commodity"},
			{"text": "North Mining Ltd reports steady production.", "category": "earnings"},
			{"text": "Analysts flag North Mining Ltd as oversold.", "category": "analyst"},
		],
		"negative": [
			{"text": "Commodity weakness weighs on North Mining Ltd.", "category": "commodity"},
			{"text": "Intraday rumor: North Mining Ltd output running light.", "category": "rumor"},
			{"text": "Analyst cuts North Mining Ltd to Underweight.", "category": "analyst"},
		],
	},
}

const GLOBAL_PREMARKET := {
	"positive": [
		"PREMARKET: Futures jump after overnight economic data.",
		"PREMARKET: Risk appetite returns after a quiet overnight session.",
	],
	"negative": [
		"PREMARKET: Futures slip as overnight data disappoints.",
		"PREMARKET: Cautious tape after weak global sentiment overnight.",
	],
}

const GLOBAL_INTRADAY := {
	"positive": [
		"Intraday: buyers step back in across the tape.",
		"Desk note: dip-buying interest is returning.",
	],
	"negative": [
		"Intraday: risk-off tone spreads across the market.",
		"Desk note: traders reduce exposure into the close.",
	],
}


func generate_premarket(stocks: Array[Stock], session_time: String) -> Array[NewsEvent]:
	var events: Array[NewsEvent] = []
	var featured: Stock = stocks[randi() % stocks.size()]
	events.append(_make_premarket_company(featured, session_time))

	if randf() < 0.55:
		var others: Array[Stock] = []
		for stock in stocks:
			if stock.symbol != featured.symbol:
				others.append(stock)
		if not others.is_empty():
			events.append(_make_premarket_company(others[randi() % others.size()], session_time))

	if randf() < 0.4:
		events.append(_make_global(session_time, stocks, true))

	return events


func generate_intraday(stocks: Array[Stock], session_time: String) -> NewsEvent:
	if randf() < 0.008:
		return _generate_surprise(stocks, session_time)
	if randf() < 0.22:
		return _make_global(session_time, stocks, false)
	return _make_intraday_company(stocks, session_time)


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
		"general"
	)


func _make_premarket_company(stock: Stock, session_time: String) -> NewsEvent:
	var is_positive := randf() > 0.42
	var item: Dictionary = _pick_item(PREMARKET_TEMPLATES[stock.symbol], is_positive)
	var sentiment: float = 1.0 if is_positive else -1.0
	var impact: float = randf_range(0.035, 0.09) * sentiment
	return NewsEvent.new(
		session_time,
		str(item["text"]),
		[stock.symbol],
		sentiment,
		impact,
		12,
		true,
		true,
		str(item.get("category", "earnings"))
	)


func _make_intraday_company(stocks: Array[Stock], session_time: String) -> NewsEvent:
	var stock: Stock = stocks[randi() % stocks.size()]
	var is_positive := randf() > 0.48
	var item: Dictionary = _pick_item(INTRADAY_TEMPLATES[stock.symbol], is_positive)
	var sentiment: float = 1.0 if is_positive else -1.0
	var impact: float = randf_range(0.004, 0.018) * sentiment
	return NewsEvent.new(
		session_time,
		str(item["text"]),
		[stock.symbol],
		sentiment,
		impact,
		randi_range(8, 16),
		false,
		false,
		str(item.get("category", "general"))
	)


func _generate_surprise(stocks: Array[Stock], session_time: String) -> NewsEvent:
	var stock: Stock = stocks[randi() % stocks.size()]
	var is_positive := randf() > 0.5
	var headline: String
	if is_positive:
		headline = "BREAKING: unexpected upgrade hits %s mid-session." % stock.company_name
	else:
		headline = "BREAKING: unexpected downgrade hits %s mid-session." % stock.company_name
	var sentiment: float = 1.0 if is_positive else -1.0
	var impact: float = randf_range(0.03, 0.07) * sentiment
	return NewsEvent.new(session_time, headline, [stock.symbol], sentiment, impact, 8, true, false, "analyst")


func _make_global(session_time: String, stocks: Array[Stock], premarket: bool) -> NewsEvent:
	var is_positive := randf() > 0.5
	var category: String = "positive" if is_positive else "negative"
	var pool: Dictionary = GLOBAL_PREMARKET if premarket else GLOBAL_INTRADAY
	var templates: Array = pool[category]
	var headline: String = templates[randi() % templates.size()]
	var sentiment: float = 1.0 if is_positive else -1.0
	var magnitude: float = randf_range(0.008, 0.02) if premarket else randf_range(0.003, 0.012)
	var symbols: Array[String] = []
	for stock in stocks:
		symbols.append(stock.symbol)
	return NewsEvent.new(
		session_time,
		headline,
		symbols,
		sentiment,
		magnitude * sentiment,
		randi_range(8, 16),
		false,
		premarket,
		"macro"
	)


func _pick_item(company_templates: Dictionary, is_positive: bool) -> Dictionary:
	var side: String = "positive" if is_positive else "negative"
	var items: Array = company_templates[side]
	var picked: Variant = items[randi() % items.size()]
	if typeof(picked) == TYPE_DICTIONARY:
		return picked
	return {"text": str(picked), "category": "general"}
