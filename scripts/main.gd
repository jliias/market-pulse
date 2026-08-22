extends Control

const TICK_INTERVAL := 1.0
const CARD_SCENE := preload("res://scenes/watchlist_card.tscn")
const NARROW_WIDTH := 1100.0
const TIMEFRAMES := ["1M", "5M", "15M", "1H", "1D"]
const TF_POINTS := {"1M": 20, "5M": 60, "15M": 120, "1H": 180, "1D": 400}
const UI_BORDER := 1
const TRADE_BORDER := 3
const UI_ACCENT := Color(0.78, 0.82, 0.9)
const TRADE_ACCENT := Color(0.45, 0.86, 0.98)
const BUY_ACCENT := Color(0.32, 0.92, 0.48)
const SELL_ACCENT := Color(0.98, 0.42, 0.42)
const SELECTED_ACCENT := Color(0.9, 0.75, 0.25)
const INACTIVE_ACCENT := Color(0.48, 0.5, 0.55)
const PREOPEN_SECONDS := 10.0

var market := MarketSimulator.new()
var portfolio := Portfolio.new()
var session_active := true
var selected_symbol: String = "ALPH"
var buy_mode := true
var quantity: int = 20
var timeframe: String = "5M"
var watchlist_cards: Dictionary = {}
var awaiting_open := false
var preopen_remaining := 0.0
var menu_confirm_open := false

@onready var body_columns: BoxContainer = %BodyColumns
@onready var watchlist_column: Control = %WatchlistColumn
@onready var trade_column: Control = %TradeColumn
@onready var watchlist_list: VBoxContainer = %WatchlistList
@onready var portfolio_list: VBoxContainer = %PortfolioList
@onready var portfolio_total_label: Label = %PortfolioTotalLabel

@onready var portfolio_value_label: Label = %PortfolioValueLabel
@onready var cash_value_label: Label = %CashValueLabel
@onready var daily_pl_label: Label = %DailyPLLabel
@onready var session_label: Label = %SessionLabel
@onready var vs_market_label: Label = %VsMarketLabel

@onready var selected_name_label: Label = %SelectedNameLabel
@onready var selected_price_label: Label = %SelectedPriceLabel
@onready var selected_change_label: Label = %SelectedChangeLabel
@onready var selected_meta_label: Label = %SelectedMetaLabel
@onready var main_chart: PriceChart = %MainChart
@onready var news_feed: RichTextLabel = %NewsFeed
@onready var timeframe_buttons: HBoxContainer = %TimeframeButtons

@onready var trade_symbol_label: Label = %TradeSymbolLabel
@onready var trade_price_label: Label = %TradePriceLabel
@onready var buy_mode_button: Button = %BuyModeButton
@onready var sell_mode_button: Button = %SellModeButton
@onready var qty_label: Label = %QtyLabel
@onready var est_price_label: Label = %EstPriceLabel
@onready var est_total_label: Label = %EstTotalLabel
@onready var commission_label: Label = %CommissionLabel
@onready var final_total_label: Label = %FinalTotalLabel
@onready var place_order_button: Button = %PlaceOrderButton
@onready var trade_message_label: Label = %TradeMessageLabel

@onready var market_status_label: Label = %MarketStatusLabel
@onready var day_label: Label = %DayLabel
@onready var update_speed_label: Label = %UpdateSpeedLabel
@onready var next_update_label: Label = %NextUpdateLabel
@onready var end_session_button: Button = %EndSessionButton
@onready var new_day_button: Button = %NewDayButton
@onready var tick_timer: Timer = %TickTimer
@onready var settings_dialog: AcceptDialog = %SettingsDialog
@onready var menu_dialog: ConfirmationDialog = %MenuDialog
@onready var end_session_dialog: ConfirmationDialog = %EndSessionDialog
@onready var open_countdown_overlay: CenterContainer = %OpenCountdownOverlay
@onready var open_countdown_label: Label = %OpenCountdownLabel
@onready var closed_overlay: CenterContainer = %ClosedOverlay


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if session_active:
			_end_session()
		else:
			SaveManager.save_game(portfolio, market)


func _ready() -> void:
	resized.connect(_apply_responsive_layout)
	_connect_controls()
	_build_timeframe_buttons()
	_build_watchlist()
	_apply_launch_mode()
	market.player_portfolio = portfolio
	_begin_session()
	tick_timer.wait_time = TICK_INTERVAL
	tick_timer.timeout.connect(_on_market_tick)
	_apply_responsive_layout()


func _process(_delta: float) -> void:
	if menu_confirm_open:
		return
	if awaiting_open:
		preopen_remaining = maxf(preopen_remaining - _delta, 0.0)
		_refresh_open_countdown()
		if preopen_remaining <= 0.0:
			_open_market()
		return
	if session_active and not tick_timer.is_stopped():
		next_update_label.text = "NEXT UPDATE: %02d:%02d" % [int(tick_timer.time_left) / 60, int(tick_timer.time_left) % 60]


func _connect_controls() -> void:
	%QtyMinusButton.pressed.connect(func() -> void: _set_quantity(quantity - 1))
	%QtyPlusButton.pressed.connect(func() -> void: _set_quantity(quantity + 1))
	%Qty10Button.pressed.connect(func() -> void: _set_quantity(10))
	%Qty20Button.pressed.connect(func() -> void: _set_quantity(20))
	%Qty50Button.pressed.connect(func() -> void: _set_quantity(50))
	%Qty100Button.pressed.connect(func() -> void: _set_quantity(100))
	%QtyMaxButton.pressed.connect(_set_max_quantity)
	buy_mode_button.pressed.connect(func() -> void: _set_buy_mode(true))
	sell_mode_button.pressed.connect(func() -> void: _set_buy_mode(false))
	place_order_button.pressed.connect(_place_order)
	end_session_button.pressed.connect(_confirm_end_session)
	new_day_button.pressed.connect(_restart_session)
	%SettingsButton.pressed.connect(func() -> void: settings_dialog.popup_centered())
	%MenuButton.pressed.connect(_confirm_return_to_menu)
	menu_dialog.confirmed.connect(_return_to_menu)
	menu_dialog.canceled.connect(_cancel_confirm_dialog)
	menu_dialog.get_cancel_button().text = "Stay"
	end_session_dialog.confirmed.connect(_end_session)
	end_session_dialog.canceled.connect(_cancel_confirm_dialog)
	end_session_dialog.get_cancel_button().text = "Stay"
	_style_ui_buttons()


func _apply_launch_mode() -> void:
	if SaveManager.launch_mode == "continue":
		var data: Dictionary = SaveManager.load_game()
		if not data.is_empty():
			SaveManager.apply_to(portfolio, market, data)
	else:
		portfolio.reset_new_game()
		market.chain_director.reset()
		market.regime.reset()
	SaveManager.launch_mode = "new"


func _build_timeframe_buttons() -> void:
	for child in timeframe_buttons.get_children():
		timeframe_buttons.remove_child(child)
		child.free()
	for tf in TIMEFRAMES:
		var button := Button.new()
		button.text = tf
		button.toggle_mode = true
		button.button_pressed = tf == timeframe
		button.pressed.connect(_on_timeframe_pressed.bind(tf))
		timeframe_buttons.add_child(button)
	_style_timeframe_buttons()


func _on_timeframe_pressed(tf: String) -> void:
	timeframe = tf
	_style_timeframe_buttons()
	_refresh_chart()


func _build_watchlist() -> void:
	for child in watchlist_list.get_children():
		watchlist_list.remove_child(child)
		child.free()
	watchlist_cards.clear()
	for symbol in MarketSimulator.SYMBOL_ORDER:
		var card: WatchlistCard = CARD_SCENE.instantiate()
		watchlist_list.add_child(card)
		card.selected.connect(_select_stock)
		watchlist_cards[symbol] = card


func _begin_session() -> void:
	session_active = true
	awaiting_open = true
	preopen_remaining = PREOPEN_SECONDS
	market.calendar_day = portfolio.days_played
	market.prepare()
	portfolio.mark_day_start(market.stocks)
	news_feed.clear()
	selected_symbol = MarketSimulator.SYMBOL_ORDER[0]
	_set_buy_mode(true)
	_set_quantity(20)
	trade_message_label.text = "Premarket is out. Read the tape — the open is in 10 seconds."
	for event in market.premarket_events:
		_add_news_to_feed(event)
	new_day_button.visible = false
	end_session_button.visible = true
	place_order_button.disabled = true
	tick_timer.stop()
	open_countdown_overlay.visible = true
	closed_overlay.visible = false
	_refresh_open_countdown()
	_update_ui()


func _open_market() -> void:
	if not awaiting_open:
		return
	awaiting_open = false
	open_countdown_overlay.visible = false
	closed_overlay.visible = false
	var open_bell: NewsEvent = market.open()
	_add_news_to_feed(open_bell)
	place_order_button.disabled = false
	trade_message_label.text = "Market is open. Try to beat the tape."
	tick_timer.start()
	_update_ui()


func _refresh_open_countdown() -> void:
	var seconds: int = maxi(ceili(preopen_remaining), 0)
	open_countdown_label.text = "Market will open in %d seconds" % seconds
	next_update_label.text = "OPENS IN: %02d:%02d" % [seconds / 60, seconds % 60]


func _on_market_tick() -> void:
	if not session_active or awaiting_open:
		return
	var new_events := market.tick()
	for event in new_events:
		_add_news_to_feed(event)
	_update_ui()
	if market.is_closed:
		_end_session()


func _select_stock(symbol: String) -> void:
	if not market.stocks.has(symbol):
		return
	selected_symbol = symbol
	_update_ui()


func _set_buy_mode(is_buy: bool) -> void:
	buy_mode = is_buy
	_refresh_trade_panel()


func _set_quantity(value: int) -> void:
	quantity = maxi(value, 1)
	_refresh_trade_panel()


func _set_max_quantity() -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	if buy_mode:
		_set_quantity(maxi(portfolio.max_buyable(stock.ask), 1))
	else:
		_set_quantity(maxi(portfolio.get_shares(selected_symbol), 1))


func _place_order() -> void:
	if awaiting_open:
		trade_message_label.text = "Market is not open yet."
		return
	if market.is_closed or not session_active:
		trade_message_label.text = "Market is closed."
		return
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	var result: Dictionary
	if buy_mode:
		result = portfolio.buy(selected_symbol, quantity, stock.ask)
		if bool(result.get("success", false)):
			market.note_player_trade(
				"BUY",
				selected_symbol,
				quantity,
				stock.ask,
				portfolio.get_shares(selected_symbol),
				portfolio.get_avg_cost(selected_symbol),
				portfolio.cash,
				portfolio.get_portfolio_value(market.stocks)
			)
	else:
		var avg_cost: float = portfolio.get_avg_cost(selected_symbol)
		result = portfolio.sell(selected_symbol, quantity, stock.bid)
		if bool(result.get("success", false)):
			market.note_player_trade(
				"SELL",
				selected_symbol,
				quantity,
				stock.bid,
				portfolio.get_shares(selected_symbol),
				avg_cost,
				portfolio.cash,
				portfolio.get_portfolio_value(market.stocks)
			)
	trade_message_label.text = str(result["message"])
	_update_ui()


func _end_session() -> void:
	if not session_active:
		return
	menu_confirm_open = false
	var left_before_close: bool = not market.is_closed
	_run_tape_to_close()
	session_active = false
	awaiting_open = false
	open_countdown_overlay.visible = false
	closed_overlay.visible = true
	market.stop()
	tick_timer.stop()
	place_order_button.disabled = true
	end_session_button.visible = false
	new_day_button.visible = true

	var player_pct := portfolio.get_profit_loss_pct(market.stocks)
	var market_pct := market.get_market_return_pct()
	var alpha_pct := market.get_alpha_pct(player_pct)
	var result_text: String
	if alpha_pct > 0.05:
		result_text = "Closed. You beat the market by %+.1f%%." % alpha_pct
	elif alpha_pct < -0.05:
		result_text = "Closed. The market beat you by %.1f%%." % absf(alpha_pct)
	else:
		result_text = "Closed. You matched the tape."
	if left_before_close:
		result_text = "Tape run to the close. " + result_text
	trade_message_label.text = result_text
	market.chain_director.calendar_day = market.calendar_day
	market.chain_director.on_session_end()
	market.regime.on_day_close()
	portfolio.days_played += 1
	SaveManager.save_game(portfolio, market)
	_update_ui()


func _run_tape_to_close() -> void:
	tick_timer.stop()
	open_countdown_overlay.visible = false
	if awaiting_open:
		awaiting_open = false
		if not market.is_closed and not market.is_running:
			var open_bell: NewsEvent = market.open()
			_add_news_to_feed(open_bell)
	if market.is_closed:
		return
	var remaining: Array[NewsEvent] = market.simulate_until_close()
	for event in remaining:
		_add_news_to_feed(event)


func _confirm_end_session() -> void:
	if not session_active:
		return
	if market.is_closed:
		_end_session()
		return
	_pause_for_confirm()
	end_session_dialog.popup_centered()


func _confirm_return_to_menu() -> void:
	_pause_for_confirm()
	if session_active and not market.is_closed:
		menu_dialog.dialog_text = "Are you sure you want to return to the menu?\n\nThe rest of the trading day will be marked to the close. Your cash and holdings will be saved."
	else:
		menu_dialog.dialog_text = "Return to the menu?\n\nYour cash and holdings are already saved."
	menu_dialog.popup_centered()


func _pause_for_confirm() -> void:
	menu_confirm_open = true
	tick_timer.stop()


func _cancel_confirm_dialog() -> void:
	menu_confirm_open = false
	if session_active and not awaiting_open and not market.is_closed:
		tick_timer.start()


func _return_to_menu() -> void:
	menu_confirm_open = false
	if session_active:
		_end_session()
	else:
		SaveManager.save_game(portfolio, market)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _restart_session() -> void:
	market.roll_to_next_day()
	_begin_session()


func _apply_responsive_layout() -> void:
	var narrow: bool = size.x < NARROW_WIDTH
	body_columns.vertical = narrow
	watchlist_column.custom_minimum_size.x = 0.0 if narrow else 280.0
	trade_column.custom_minimum_size.x = 0.0 if narrow else 300.0
	watchlist_column.size_flags_vertical = SIZE_EXPAND_FILL if narrow else SIZE_FILL
	trade_column.size_flags_vertical = SIZE_EXPAND_FILL if narrow else SIZE_FILL


func _update_ui() -> void:
	var value: float = portfolio.get_portfolio_value(market.stocks)
	var cash: float = portfolio.cash
	var pl: float = portfolio.get_profit_loss(market.stocks)
	var pl_pct: float = portfolio.get_profit_loss_pct(market.stocks)
	portfolio_value_label.text = "Portfolio: $%.2f" % value
	cash_value_label.text = "Cash: $%.2f" % cash
	daily_pl_label.text = "Daily P/L: %s$%.2f (%s%.2f%%)" % [
		_sign(pl), absf(pl), _sign(pl), absf(pl_pct)
	]
	daily_pl_label.add_theme_color_override("font_color", _pl_color(pl))

	var status := "MARKET CLOSED"
	if awaiting_open:
		status = "PREMARKET"
	elif session_active and not market.is_closed:
		status = "MARKET OPEN"
	session_label.text = "Session: %s — %s" % [market.get_time_string(), status]
	day_label.text = "DAY %d" % (portfolio.days_played + 1)
	var market_pct := market.get_market_return_pct()
	var alpha_pct := market.get_alpha_pct(pl_pct)
	vs_market_label.text = "vs Market: %+.1f%%  (tape %+.1f%%)" % [alpha_pct, market_pct]
	vs_market_label.add_theme_color_override("font_color", _pl_color(alpha_pct))

	for symbol in watchlist_cards:
		var card: WatchlistCard = watchlist_cards[symbol]
		card.refresh(market.stocks[symbol], portfolio.get_shares(symbol))
		card.set_selected(symbol == selected_symbol)

	_refresh_selected_stock()
	_refresh_chart()
	_refresh_portfolio()
	_refresh_trade_panel()

	market_status_label.text = "MARKET STATUS:  %s" % market.regime.status_text()
	market_status_label.add_theme_color_override("font_color", market.regime.status_color())
	update_speed_label.text = "UPDATE SPEED: 1 SECOND"


func _refresh_selected_stock() -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	selected_name_label.text = "%s — %s" % [stock.symbol, stock.company_name]
	selected_price_label.text = "$%.2f" % stock.price
	var change: float = stock.get_day_change()
	selected_change_label.text = "%s$%.2f (%s%.2f%%)" % [_sign(change), absf(change), _sign(change), absf(stock.get_day_change_pct())]
	selected_change_label.add_theme_color_override("font_color", _pl_color(change))
	selected_meta_label.text = "%s · %s · %s" % [stock.personality_label, stock.sector, stock.market_cap_label]


func _refresh_chart() -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	var points: int = int(TF_POINTS[timeframe])
	var slice: Dictionary = stock.get_chart_slice(points, 1)
	main_chart.compact = false
	main_chart.set_series(slice["prices"], slice["volumes"])


func _refresh_portfolio() -> void:
	for child in portfolio_list.get_children():
		portfolio_list.remove_child(child)
		child.free()

	var total_pl := 0.0
	if portfolio.holdings.is_empty():
		var empty := Label.new()
		empty.text = "No positions yet."
		empty.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
		portfolio_list.add_child(empty)
	else:
		for symbol in MarketSimulator.SYMBOL_ORDER:
			if not portfolio.holdings.has(symbol):
				continue
			var stock: Stock = market.stocks[symbol]
			var shares: int = portfolio.get_shares(symbol)
			var avg: float = portfolio.get_avg_cost(symbol)
			var pos_pl: float = portfolio.get_position_pl(symbol, stock.price)
			total_pl += pos_pl
			var row := Label.new()
			row.text = "%s — %d shares — $%.2f — %s$%.2f" % [
				symbol, shares, avg, _sign(pos_pl), absf(pos_pl)
			]
			row.add_theme_color_override("font_color", _pl_color(pos_pl))
			portfolio_list.add_child(row)

	portfolio_total_label.text = "Open P/L: %s$%.2f" % [_sign(total_pl), absf(total_pl)]
	portfolio_total_label.add_theme_color_override("font_color", _pl_color(total_pl))


func _refresh_trade_panel() -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	trade_symbol_label.text = "TRADE  %s" % stock.symbol
	var px: float = stock.ask if buy_mode else stock.bid
	trade_price_label.text = "$%.2f" % px
	qty_label.text = str(quantity)
	place_order_button.text = "PLACE BUY ORDER" if buy_mode else "PLACE SELL ORDER"
	_style_trade_buttons()

	var estimate: Dictionary = portfolio.estimate(quantity, px)
	est_price_label.text = "Estimated price: $%.2f" % px
	est_total_label.text = "Estimated total: $%.2f" % float(estimate["trade_value"])
	commission_label.text = "Commission: $%.2f" % float(estimate["commission"])
	if buy_mode:
		final_total_label.text = "Total: $%.2f" % float(estimate["total"])
	else:
		final_total_label.text = "Total proceeds: $%.2f" % float(estimate["proceeds"])


func _style_ui_buttons() -> void:
	_apply_button_style(%SettingsButton, UI_ACCENT, UI_BORDER)
	_apply_button_style(%MenuButton, UI_ACCENT, UI_BORDER)
	_apply_button_style(end_session_button, UI_ACCENT, UI_BORDER)
	_apply_button_style(new_day_button, SELECTED_ACCENT, UI_BORDER)


func _style_timeframe_buttons() -> void:
	for child in timeframe_buttons.get_children():
		var button := child as Button
		button.button_pressed = button.text == timeframe
		var accent: Color = SELECTED_ACCENT if button.text == timeframe else UI_ACCENT
		_apply_button_style(button, accent, UI_BORDER, button.text == timeframe)


func _style_trade_buttons() -> void:
	var buy_accent: Color = BUY_ACCENT if buy_mode else INACTIVE_ACCENT
	var sell_accent: Color = SELL_ACCENT if not buy_mode else INACTIVE_ACCENT
	_apply_button_style(buy_mode_button, buy_accent, TRADE_BORDER, buy_mode, buy_mode)
	_apply_button_style(sell_mode_button, sell_accent, TRADE_BORDER, not buy_mode, not buy_mode)
	_apply_button_style(%QtyMinusButton, TRADE_ACCENT, TRADE_BORDER)
	_apply_button_style(%QtyPlusButton, TRADE_ACCENT, TRADE_BORDER)
	_apply_button_style(%Qty10Button, TRADE_ACCENT, TRADE_BORDER, quantity == 10)
	_apply_button_style(%Qty20Button, TRADE_ACCENT, TRADE_BORDER, quantity == 20)
	_apply_button_style(%Qty50Button, TRADE_ACCENT, TRADE_BORDER, quantity == 50)
	_apply_button_style(%Qty100Button, TRADE_ACCENT, TRADE_BORDER, quantity == 100)
	_apply_button_style(%QtyMaxButton, TRADE_ACCENT, TRADE_BORDER)
	var order_accent: Color = BUY_ACCENT if buy_mode else SELL_ACCENT
	_apply_button_style(place_order_button, order_accent, TRADE_BORDER, true)
	place_order_button.add_theme_font_size_override("font_size", 18)


func _apply_button_style(button: Button, accent: Color, border: int, emphasized: bool = false, strong_fill: bool = false) -> void:
	var fill: float = 0.08
	if emphasized:
		fill = 0.22
	if strong_fill:
		fill = 0.62
	if button.disabled:
		accent = Color(accent.r, accent.g, accent.b, 0.4)
		fill = 0.05

	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", accent.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", accent.darkened(0.08))
	button.add_theme_color_override("font_disabled_color", Color(accent.r, accent.g, accent.b, 0.45))

	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(accent.r, accent.g, accent.b, fill)
		box.border_color = accent
		box.set_border_width_all(border)
		box.set_corner_radius_all(6)
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		if state == "hover":
			box.bg_color = Color(accent.r, accent.g, accent.b, fill + 0.1)
			box.set_border_width_all(border + 1)
		elif state == "pressed":
			box.bg_color = Color(accent.r, accent.g, accent.b, fill + 0.16)
		elif state == "disabled":
			box.border_color = Color(accent.r, accent.g, accent.b, 0.35)
			box.bg_color = Color(0.12, 0.13, 0.16, 1.0)
		button.add_theme_stylebox_override(state, box)


func _add_news_to_feed(event: NewsEvent) -> void:
	var color := "#aaaaaa"
	if event.sentiment > 0:
		color = "#55cc55"
	elif event.sentiment < 0:
		color = "#cc5555"
	var tag: String = event.feed_tag()
	var effect: String = event.effect_label()
	if effect.is_empty():
		news_feed.append_text("[color=%s]%s  [b]%s[/b] — %s[/color]\n" % [
			color, event.timestamp, tag, event.headline
		])
	else:
		news_feed.append_text("[color=%s]%s  [b]%s[/b] · %s — %s[/color]\n" % [
			color, event.timestamp, tag, effect, event.headline
		])
	if not event.reaction.is_empty():
		news_feed.append_text("[color=#888888]    %s[/color]\n" % event.reaction)


func _sign(value: float) -> String:
	return "+" if value >= 0.0 else "-"


func _pl_color(value: float) -> Color:
	if value >= 0.0:
		return Color(0.35, 0.85, 0.45)
	return Color(0.95, 0.38, 0.38)
