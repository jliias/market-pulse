class_name NewsGenerator
extends RefCounted

const COMPANY_TEMPLATES := {
	"A": {
		"positive": [
			"Alpha Technologies announces record quarterly earnings.",
			"Alpha Technologies wins major cloud contract.",
			"Analysts upgrade Alpha Technologies to Buy.",
			"Alpha Technologies unveils breakthrough AI chip.",
		],
		"negative": [
			"Alpha Technologies CEO announces resignation.",
			"Alpha Technologies faces patent lawsuit.",
			"Alpha Technologies misses earnings expectations.",
			"Alpha Technologies product recall announced.",
		],
	},
	"B": {
		"positive": [
			"Green Energy Corp receives government subsidy.",
			"Green Energy Corp secures wind farm contract.",
			"Green Energy Corp beats revenue forecasts.",
			"Green Energy Corp stock added to green index.",
		],
		"negative": [
			"Green Energy Corp project delayed by regulators.",
			"Green Energy Corp reports turbine failures.",
			"Subsidy cuts threaten Green Energy Corp margins.",
			"Green Energy Corp CFO steps down unexpectedly.",
		],
	},
	"C": {
		"positive": [
			"North Mining Ltd discovers new ore deposit.",
			"North Mining Ltd commodity prices surge.",
			"North Mining Ltd exceeds production targets.",
			"North Mining Ltd signs long-term supply deal.",
		],
		"negative": [
			"North Mining Ltd reports unexpected production shutdown.",
			"North Mining Ltd faces environmental fine.",
			"Commodity slump hits North Mining Ltd shares.",
			"North Mining Ltd labor dispute halts operations.",
		],
	},
}

const MAJOR_TEMPLATES := {
	"A": {
		"positive": [
			"BREAKING: Alpha Technologies announces transformative acquisition.",
			"BREAKING: Alpha Technologies wins landmark government contract.",
		],
		"negative": [
			"BREAKING: Alpha Technologies discloses major accounting investigation.",
			"BREAKING: Alpha Technologies hit with catastrophic product failure.",
		],
	},
	"B": {
		"positive": [
			"BREAKING: Green Energy Corp secures record-breaking subsidy package.",
			"BREAKING: Green Energy Corp announces revolutionary battery breakthrough.",
		],
		"negative": [
			"BREAKING: Green Energy Corp loses critical regulatory approval.",
			"BREAKING: Green Energy Corp warns of imminent bankruptcy risk.",
		],
	},
	"C": {
		"positive": [
			"BREAKING: North Mining Ltd discovers massive new ore deposit.",
			"BREAKING: North Mining Ltd commodity prices spike to record highs.",
		],
		"negative": [
			"BREAKING: North Mining Ltd halts all production indefinitely.",
			"BREAKING: North Mining Ltd faces catastrophic mine collapse.",
		],
	},
}

const GLOBAL_TEMPLATES := {
	"positive": [
		"Central bank signals interest rate cut.",
		"Global markets rally on trade deal optimism.",
		"Economic data exceeds expectations.",
		"Investor confidence reaches multi-month high.",
	],
	"negative": [
		"Recession fears grow amid weak jobs data.",
		"Geopolitical tensions rattle global markets.",
		"Central bank hints at further rate hikes.",
		"Inflation data spooks investors.",
	],
}


func generate(stocks: Array[Stock], session_time: String) -> NewsEvent:
	if randf() < 0.08:
		return _generate_major_company(stocks, session_time)
	if randf() < 0.22:
		return _generate_global(session_time, stocks)
	return _generate_routine_company(stocks, session_time)


func generate_initial(stocks: Array[Stock], session_time: String) -> NewsEvent:
	var stock: Stock = stocks[randi() % stocks.size()]
	var headline: String = "Markets open. Traders watch %s closely." % stock.company_name
	return NewsEvent.new(session_time, headline, [], 0.0, 0.0, 0, false)


func _generate_routine_company(stocks: Array[Stock], session_time: String) -> NewsEvent:
	var stock: Stock = stocks[randi() % stocks.size()]
	var is_positive := randf() > 0.45
	var category: String = "positive" if is_positive else "negative"
	var templates: Array = COMPANY_TEMPLATES[stock.symbol][category]
	var headline: String = templates[randi() % templates.size()]
	var sentiment: float = 1.0 if is_positive else -1.0
	var magnitude: float = randf_range(0.005, 0.03)
	var impact: float = magnitude * sentiment
	var duration: int = randi_range(2, 5)

	return NewsEvent.new(session_time, headline, [stock.symbol], sentiment, impact, duration, false)


func _generate_major_company(stocks: Array[Stock], session_time: String) -> NewsEvent:
	var stock: Stock = stocks[randi() % stocks.size()]
	var is_positive := randf() > 0.4
	var category: String = "positive" if is_positive else "negative"
	var templates: Array = MAJOR_TEMPLATES[stock.symbol][category]
	var headline: String = templates[randi() % templates.size()]
	var sentiment: float = 1.0 if is_positive else -1.0
	var magnitude: float = randf_range(0.08, 0.14)
	var impact: float = magnitude * sentiment
	var duration: int = randi_range(1, 3)

	return NewsEvent.new(session_time, headline, [stock.symbol], sentiment, impact, duration, true)


func _generate_global(session_time: String, stocks: Array[Stock]) -> NewsEvent:
	var is_positive := randf() > 0.5
	var category: String = "positive" if is_positive else "negative"
	var templates: Array = GLOBAL_TEMPLATES[category]
	var headline: String = templates[randi() % templates.size()]
	var sentiment: float = 1.0 if is_positive else -1.0
	var magnitude: float = randf_range(0.004, 0.015)
	var impact: float = magnitude * sentiment
	var symbols: Array[String] = []
	for stock in stocks:
		symbols.append(stock.symbol)
	return NewsEvent.new(session_time, headline, symbols, sentiment, impact, randi_range(2, 4), false)
