extends Control

const TICK_INTERVAL := 5.0

var market := MarketSimulator.new()
var portfolio := Portfolio.new()
var command_handler: CommandHandler
var session_active := true

@onready var time_label: Label = %TimeLabel
@onready var cash_label: Label = %CashLabel
@onready var portfolio_label: Label = %PortfolioLabel
@onready var pl_label: Label = %PLLabel
@onready var stock_panels: VBoxContainer = %StockPanels
@onready var news_feed: RichTextLabel = %NewsFeed
@onready var output_log: RichTextLabel = %OutputLog
@onready var command_input: LineEdit = %CommandInput
@onready var tick_timer: Timer = %TickTimer

var stock_labels: Dictionary = {}


func _ready() -> void:
	command_handler = CommandHandler.new(market, portfolio)
	market.start()
	_build_stock_panels()
	_update_ui()
	_log("Welcome to Market Pulse!")
	_log("Starting capital: $10,000. Type HELP for commands.")
	_add_news_to_feed(market.news_feed[0])
	tick_timer.wait_time = TICK_INTERVAL
	tick_timer.timeout.connect(_on_market_tick)
	tick_timer.start()
	command_input.text_submitted.connect(_on_command_submitted)
	command_input.grab_focus()


func _build_stock_panels() -> void:
	for symbol in ["A", "B", "C"]:
		var stock: Stock = market.stocks[symbol]
		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		panel.add_child(vbox)

		var header := Label.new()
		header.text = "%s — %s" % [symbol, stock.company_name]
		header.add_theme_font_size_override("font_size", 16)
		vbox.add_child(header)

		var price_label := Label.new()
		price_label.name = "PriceLabel"
		vbox.add_child(price_label)

		var detail_label := Label.new()
		detail_label.name = "DetailLabel"
		vbox.add_child(detail_label)

		var owned_label := Label.new()
		owned_label.name = "OwnedLabel"
		vbox.add_child(owned_label)

		stock_panels.add_child(panel)
		stock_labels[symbol] = {
			"price": price_label,
			"detail": detail_label,
			"owned": owned_label,
		}


func _on_market_tick() -> void:
	if not session_active:
		return

	var new_events := market.tick()
	for event in new_events:
		_add_news_to_feed(event)

	_update_ui()
	_log("--- Market update (%s) ---" % market.get_time_string())


func _on_command_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return

	_log("> %s" % text)
	var result := command_handler.execute(text)

	if result == "QUIT":
		_end_session()
		return

	if not result.is_empty():
		_log(result)

	command_input.clear()
	command_input.grab_focus()
	_update_ui()


func _end_session() -> void:
	session_active = false
	market.stop()
	tick_timer.stop()

	var pl := portfolio.get_profit_loss(market.stocks)
	var pl_sign := "+" if pl >= 0 else ""

	_log("")
	_log("=== TRADING SESSION ENDED ===")
	_log("Final portfolio value: $%.2f" % portfolio.get_portfolio_value(market.stocks))
	_log("Profit/Loss: %s$%.2f (%s%.1f%%)" % [
		pl_sign, pl, pl_sign, portfolio.get_profit_loss_pct(market.stocks)
	])
	_log("Total trades: %d" % portfolio.trade_history.size())
	_log("Total commissions: $%.2f" % portfolio.total_commissions)
	_log("")
	_log("Thanks for playing Market Pulse!")

	command_input.editable = false


func _update_ui() -> void:
	time_label.text = "Time: %s" % market.get_time_string()
	cash_label.text = "Cash: $%.2f" % portfolio.cash
	portfolio_label.text = "Portfolio: $%.2f" % portfolio.get_portfolio_value(market.stocks)

	var pl := portfolio.get_profit_loss(market.stocks)
	var pl_sign := "+" if pl >= 0 else ""
	pl_label.text = "P/L: %s$%.2f (%s%.1f%%)" % [pl_sign, pl, pl_sign, portfolio.get_profit_loss_pct(market.stocks)]

	if pl >= 0:
		pl_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	else:
		pl_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))

	for symbol in stock_labels:
		var stock: Stock = market.stocks[symbol]
		var labels: Dictionary = stock_labels[symbol]
		labels["price"].text = "Price: $%.2f  (Bid: $%.2f / Ask: $%.2f)" % [stock.price, stock.bid, stock.ask]
		labels["detail"].text = "Volume: %s  |  Trend: %s  |  Volatility: %.0f%%" % [
			_format_volume(stock.volume), stock.get_trend_name(), stock.volatility * 100
		]
		labels["owned"].text = "Owned: %d shares" % portfolio.get_shares(symbol)


func _add_news_to_feed(event: NewsEvent) -> void:
	var color := "#aaaaaa"
	if event.sentiment > 0:
		color = "#55cc55"
	elif event.sentiment < 0:
		color = "#cc5555"

	news_feed.append_text("[color=%s][%s] %s[/color]\n" % [color, event.timestamp, event.headline])


func _log(message: String) -> void:
	output_log.append_text(message + "\n")


func _format_volume(vol: int) -> String:
	if vol >= 1000000:
		return "%.1fM" % (float(vol) / 1000000.0)
	if vol >= 1000:
		return "%.1fK" % (float(vol) / 1000.0)
	return str(vol)
