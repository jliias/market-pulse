class_name MarketSimulator
extends RefCounted

const TICK_INTERVAL := 5.0
const SYMBOL_ALIASES := {
	"A": "A",
	"ALPHA": "A",
	"B": "B",
	"GREEN": "B",
	"C": "C",
	"NORTH": "C",
	"MINING": "C",
}

var stocks: Dictionary = {}
var news_feed: Array[NewsEvent] = []
var news_generator: NewsGenerator = NewsGenerator.new()
var session_minutes: int = 0
var session_seconds: int = 0
var tick_count: int = 0
var is_running: bool = false


func _init() -> void:
	_setup_stocks()


func _setup_stocks() -> void:
	var stock_a := Stock.new("A", "Alpha Technologies", 187.45, 1.0)
	var stock_b := Stock.new("B", "Green Energy Corp", 34.20, 0.85)
	var stock_c := Stock.new("C", "North Mining Ltd", 512.80, 1.15)
	stocks["A"] = stock_a
	stocks["B"] = stock_b
	stocks["C"] = stock_c


func start() -> void:
	is_running = true
	session_minutes = 9
	session_seconds = 30
	var opening_news := news_generator.generate_initial(get_stock_list(), get_time_string())
	news_feed.append(opening_news)


func stop() -> void:
	is_running = false


func tick() -> Array[NewsEvent]:
	if not is_running:
		return []

	tick_count += 1
	_advance_time()

	var new_events: Array[NewsEvent] = []

	if tick_count == 1 or randf() < 0.35:
		var event := news_generator.generate(get_stock_list(), get_time_string())
		news_feed.append(event)
		new_events.append(event)
		_apply_news(event)

	for symbol in stocks:
		stocks[symbol].tick()

	if news_feed.size() > 50:
		news_feed.remove_at(0)

	return new_events


func _apply_news(event: NewsEvent) -> void:
	for symbol in event.affected_symbols:
		if stocks.has(symbol):
			stocks[symbol].apply_news_impact(event.impact, event.duration_ticks, event.is_major)


func _advance_time() -> void:
	session_seconds += int(TICK_INTERVAL)
	while session_seconds >= 60:
		session_seconds -= 60
		session_minutes += 1
	if session_minutes >= 60:
		session_minutes = 16
		session_seconds = 0


func get_time_string() -> String:
	return "%02d:%02d" % [session_minutes, session_seconds]


func get_stock_list() -> Array[Stock]:
	var list: Array[Stock] = []
	for symbol in ["A", "B", "C"]:
		list.append(stocks[symbol])
	return list


func resolve_symbol(input: String) -> String:
	var upper := input.to_upper()
	return SYMBOL_ALIASES.get(upper, "")


func get_stock(symbol: String) -> Stock:
	return stocks.get(symbol, null)
