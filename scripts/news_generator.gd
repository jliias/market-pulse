class_name NewsGenerator
extends RefCounted

const PREMARKET_TEMPLATES := {
	"ALPH": {
		"positive": [
			"PREMARKET: Alpha Technologies beats quarterly earnings and raises guidance.",
			"PREMARKET: Alpha Technologies reports record annual revenue.",
		],
		"negative": [
			"PREMARKET: Alpha Technologies misses quarterly earnings and cuts outlook.",
			"PREMARKET: Alpha Technologies issues a profit warning before the open.",
		],
	},
	"GRNE": {
		"positive": [
			"PREMARKET: Green Energy Corp beats earnings on strong project pipeline.",
			"PREMARKET: Green Energy Corp raises full-year guidance.",
		],
		"negative": [
			"PREMARKET: Green Energy Corp misses earnings as subsidies disappoint.",
			"PREMARKET: Green Energy Corp slashes annual production forecast.",
		],
	},
	"NMIN": {
		"positive": [
			"PREMARKET: North Mining Ltd posts better-than-expected quarterly results.",
			"PREMARKET: North Mining Ltd lifts annual output guidance.",
		],
		"negative": [
			"PREMARKET: North Mining Ltd misses earnings on weaker commodity prices.",
			"PREMARKET: North Mining Ltd cuts annual production targets.",
		],
	},
}

const INTRADAY_TEMPLATES := {
	"ALPH": {
		"positive": [
			"Analyst raises Alpha Technologies price target.",
			"Street chatter: Alpha Technologies named a top pick.",
			"Options flow leans bullish on Alpha Technologies.",
		],
		"negative": [
			"Analyst trims Alpha Technologies price target.",
			"Desk note: Alpha Technologies valuation looks stretched.",
			"Whispers of profit-taking in Alpha Technologies.",
		],
	},
	"GRNE": {
		"positive": [
			"Analyst upgrades Green Energy Corp to Overweight.",
			"Green Energy Corp mentioned in a sector rotation note.",
			"Intraday rumor: Green Energy Corp nearing a new contract.",
		],
		"negative": [
			"Analyst downgrades Green Energy Corp to Neutral.",
			"Traders fade Green Energy Corp after the morning pop.",
			"Sector note warns of subsidy risk for Green Energy Corp.",
		],
	},
	"NMIN": {
		"positive": [
			"Commodity desk lifts North Mining Ltd target price.",
			"Analysts flag North Mining Ltd as oversold.",
			"Intraday rumor: North Mining Ltd production running hot.",
		],
		"negative": [
			"Analyst cuts North Mining Ltd to Underweight.",
			"Commodity weakness weighs on North Mining Ltd chatter.",
			"Traders question North Mining Ltd's morning move.",
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
		false
	)


func _make_premarket_company(stock: Stock, session_time: String) -> NewsEvent:
	var is_positive := randf() > 0.42
	var category: String = "positive" if is_positive else "negative"
	var templates: Array = PREMARKET_TEMPLATES[stock.symbol][category]
	var headline: String = templates[randi() % templates.size()]
	var sentiment: float = 1.0 if is_positive else -1.0
	var impact: float = randf_range(0.035, 0.09) * sentiment
	return NewsEvent.new(session_time, headline, [stock.symbol], sentiment, impact, 12, true, true)


func _make_intraday_company(stocks: Array[Stock], session_time: String) -> NewsEvent:
	var stock: Stock = stocks[randi() % stocks.size()]
	var is_positive := randf() > 0.48
	var category: String = "positive" if is_positive else "negative"
	var templates: Array = INTRADAY_TEMPLATES[stock.symbol][category]
	var headline: String = templates[randi() % templates.size()]
	var sentiment: float = 1.0 if is_positive else -1.0
	var impact: float = randf_range(0.004, 0.018) * sentiment
	return NewsEvent.new(session_time, headline, [stock.symbol], sentiment, impact, randi_range(8, 16), false, false)


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
	return NewsEvent.new(session_time, headline, [stock.symbol], sentiment, impact, 8, true, false)


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
		premarket
	)
