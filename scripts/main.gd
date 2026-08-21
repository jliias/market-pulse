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
@onready var vs_market_label: Label = %VsMarketLabel
@onready var stock_panels: VBoxContainer = %StockPanels
@onready var news_feed: RichTextLabel = %NewsFeed
@onready var output_log: RichTextLabel = %OutputLog
@onready var command_input: LineEdit = %CommandInput
@onready var tick_timer: Timer = %TickTimer

var stock_labels: Dictionary = {}


func _ready() -> void:
	command_handler = CommandHandler.new(market, portfolio)
	_build_stock_panels()
	_begin_session()
	tick_timer.wait_time = TICK_INTERVAL
	tick_timer.timeout.connect(_on_market_tick)
	tick_timer.start()
	command_input.text_submitted.connect(_on_command_submitted)
	command_input.grab_focus()


func _begin_session() -> void:
	session_active = true
	market.start()
	_log("Welcome to Market Pulse.")
	_log("Premarket is out. Read the tape, then try to beat the market by close.")
	_log("Starting capital: $10,000. Type HELP for commands.")
	for event in market.premarket_events:
		_add_news_to_feed(event)
	_update_ui()


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
	if market.is_closed:
		_end_session()


func _on_command_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return

	_log("> %s" % text)
	var result := command_handler.execute(text)

	if result == "QUIT":
		_end_session()
		return

	if result == "AGAIN":
		_restart_session()
		command_input.clear()
		command_input.grab_focus()
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
	var player_pct := portfolio.get_profit_loss_pct(market.stocks)
	var market_pct := market.get_market_return_pct()
	var alpha_pct := market.get_alpha_pct(player_pct)
	var pl_sign := "+" if pl >= 0 else ""
	var m_sign := "+" if market_pct >= 0 else ""
	var a_sign := "+" if alpha_pct >= 0 else ""

	_log("")
	_log("=== MARKET CLOSED ===")
	_log("Final portfolio: $%.2f" % portfolio.get_portfolio_value(market.stocks))
	_log("Your return: %s%.1f%%" % [pl_sign, player_pct])
	_log("Market return: %s%.1f%%" % [m_sign, market_pct])
	if alpha_pct > 0.05:
		_log("You beat the market by %s%.1f%%. Type AGAIN to chase a bigger win." % [a_sign, alpha_pct])
	elif alpha_pct < -0.05:
		_log("The market beat you by %.1f%%. Type AGAIN to try another day." % absf(alpha_pct))
	else:
		_log("You matched the tape. Type AGAIN to take another shot.")
	_log("Trades: %d  |  Commissions: $%.2f" % [portfolio.trade_history.size(), portfolio.total_commissions])

	command_input.editable = true


func _restart_session() -> void:
	for child in stock_panels.get_children():
		stock_panels.remove_child(child)
		child.free()
	stock_labels.clear()
	news_feed.clear()
	output_log.clear()
	market = MarketSimulator.new()
	portfolio = Portfolio.new()
	command_handler = CommandHandler.new(market, portfolio)
	_build_stock_panels()
	command_input.editable = true
	if tick_timer.is_stopped():
		tick_timer.start()
	_begin_session()
	_log("New trading day. Fresh tape, same goal: beat the market.")


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

	var market_pct := market.get_market_return_pct()
	var alpha_pct := market.get_alpha_pct(portfolio.get_profit_loss_pct(market.stocks))
	var a_sign := "+" if alpha_pct >= 0 else ""
	var m_sign := "+" if market_pct >= 0 else ""
	vs_market_label.text = "vs Market: %s%.1f%%  (tape %s%.1f%%)" % [a_sign, alpha_pct, m_sign, market_pct]
	if alpha_pct >= 0:
		vs_market_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	else:
		vs_market_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))

	for symbol in stock_labels:
		var stock: Stock = market.stocks[symbol]
		var labels: Dictionary = stock_labels[symbol]
		var day_pct: float = stock.get_day_change_pct()
		var day_sign: String = "+" if day_pct >= 0 else ""
		labels["price"].text = "Price: $%.2f (%s%.1f%% today)  (Bid: $%.2f / Ask: $%.2f)" % [
			stock.price, day_sign, day_pct, stock.bid, stock.ask
		]
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
	if not event.reaction.is_empty():
		news_feed.append_text("[color=#888888]    %s[/color]\n" % event.reaction)


func _log(message: String) -> void:
	output_log.append_text(message + "\n")


func _format_volume(vol: int) -> String:
	if vol >= 1000000:
		return "%.1fM" % (float(vol) / 1000000.0)
	if vol >= 1000:
		return "%.1fK" % (float(vol) / 1000.0)
	return str(vol)
