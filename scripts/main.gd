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
const FADE_ACCENT := Color(0.78, 0.62, 0.98)

var market := MarketSimulator.new()
var portfolio := Portfolio.new()
var session_active := true
var selected_symbol: String = "ALPH"
var buy_mode := true
var fade_mode := false
var quantity: int = 20
var tape_speed: int = 1
var print_pause_active := false
var print_pause_left := 0.0
var print_pause_symbol: String = ""
var close_alpha_pct := 0.0
var close_verdict: String = ""
var close_book_line: String = ""
var close_tomorrow: String = ""
var close_streak: String = ""
var speed_buttons: Array[Button] = []
var story_board_sig: String = ""
var timeframe: String = "5M"
var watchlist_cards: Dictionary = {}
var awaiting_open := false
var preopen_remaining := 0.0
var menu_confirm_open := false
var chapter_overlay: ColorRect
var recap_page: VBoxContainer
var recap_label: Label
var rebalance_page: VBoxContainer
var rebalance_hint: Label
var rebalance_title: Label
var drop_header: Label
var keep_book_button: Button
var drop_list: VBoxContainer
var add_list: VBoxContainer
var confirm_swap_button: Button
var drop_pick: String = ""
var add_pick: String = ""
var add_picks: Array[String] = []
var forced_drops: Array[String] = []
var keep_book: bool = true
var leave_intent: String = "menu"
var cash_out_button: Button

@onready var body_columns: BoxContainer = %BodyColumns
@onready var top_row: BoxContainer = %TopRow
@onready var bottom_row: BoxContainer = %BottomRow
@onready var watchlist_column: Control = %WatchlistColumn
@onready var portfolio_column: Control = %PortfolioColumn
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
@onready var fade_mode_button: Button = %FadeModeButton
@onready var qty_label: Label = %QtyLabel
@onready var est_price_label: Label = %EstPriceLabel
@onready var est_total_label: Label = %EstTotalLabel
@onready var commission_label: Label = %CommissionLabel
@onready var final_total_label: Label = %FinalTotalLabel
@onready var place_order_button: Button = %PlaceOrderButton
@onready var trade_message_label: Label = %TradeMessageLabel

@onready var market_status_label: Label = %MarketStatusLabel
@onready var day_label: Label = %DayLabel
@onready var end_session_button: Button = %EndSessionButton
@onready var new_day_button: Button = %NewDayButton
@onready var tick_timer: Timer = %TickTimer
@onready var settings_dialog: AcceptDialog = %SettingsDialog
@onready var menu_dialog: ConfirmationDialog = %MenuDialog
@onready var end_session_dialog: ConfirmationDialog = %EndSessionDialog
@onready var open_countdown_overlay: CenterContainer = %OpenCountdownOverlay
@onready var open_countdown_label: Label = %OpenCountdownLabel
@onready var closed_overlay: CenterContainer = %ClosedOverlay
@onready var close_hero_label: Label = %CloseHeroLabel
@onready var close_verdict_label: Label = %CloseVerdictLabel
@onready var close_streak_label: Label = %CloseStreakLabel
@onready var close_book_label: Label = %CloseBookLabel
@onready var close_tomorrow_label: Label = %CloseTomorrowLabel
@onready var close_listing_label: Label = %CloseListingLabel
@onready var story_board: HBoxContainer = %StoryBoard
@onready var print_pause_overlay: ColorRect = %PrintPauseOverlay
@onready var print_pause_headline: Label = %PrintPauseHeadline
@onready var print_pause_reaction: Label = %PrintPauseReaction
@onready var print_pause_timer: Label = %PrintPauseTimer
@onready var print_pause_hold_button: Button = %PrintPauseHoldButton
@onready var print_pause_ticket_button: Button = %PrintPauseTicketButton


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_confirm_leave_desk("quit")


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	resized.connect(_apply_responsive_layout)
	_connect_controls()
	_build_timeframe_buttons()
	_apply_hud_tooltips()
	_apply_launch_mode()
	tape_speed = SaveManager.tape_speed
	_build_settings()
	_build_watchlist()
	_build_chapter_overlay()
	market.player_portfolio = portfolio
	_apply_tape_speed()
	tick_timer.timeout.connect(_on_market_tick)
	_apply_responsive_layout()
	if portfolio.pending_chapter:
		_show_chapter_recap()
	else:
		_begin_session()


func _process(_delta: float) -> void:
	if menu_confirm_open:
		return
	if chapter_overlay != null and chapter_overlay.visible:
		return
	if print_pause_active:
		print_pause_left = maxf(print_pause_left - _delta, 0.0)
		_refresh_print_pause_timer()
		if print_pause_left <= 0.0:
			_end_print_pause()
		return
	if awaiting_open:
		preopen_remaining = maxf(preopen_remaining - _delta, 0.0)
		_refresh_open_countdown()
		if preopen_remaining <= 0.0:
			_open_market()
		return


func _connect_controls() -> void:
	%QtyMinusButton.pressed.connect(func() -> void: _set_quantity(quantity - 1))
	%QtyPlusButton.pressed.connect(func() -> void: _set_quantity(quantity + 1))
	%Qty10Button.pressed.connect(func() -> void: _set_quantity(10))
	%Qty20Button.pressed.connect(func() -> void: _set_quantity(20))
	%Qty50Button.pressed.connect(func() -> void: _set_quantity(50))
	%Qty100Button.pressed.connect(func() -> void: _set_quantity(100))
	%QtyMaxButton.pressed.connect(_set_max_quantity)
	sell_mode_button.pressed.connect(func() -> void: _set_trade_mode("sell"))
	fade_mode_button.pressed.connect(func() -> void: _set_trade_mode("fade"))
	buy_mode_button.pressed.connect(func() -> void: _set_trade_mode("buy"))
	place_order_button.pressed.connect(_place_order)
	end_session_button.pressed.connect(_confirm_end_session)
	new_day_button.pressed.connect(_restart_session)
	%SettingsButton.pressed.connect(func() -> void: settings_dialog.popup_centered())
	%MenuButton.pressed.connect(func() -> void: _confirm_leave_desk("menu"))
	menu_dialog.confirmed.connect(_on_leave_hold)
	menu_dialog.canceled.connect(_cancel_confirm_dialog)
	menu_dialog.get_cancel_button().text = "Stay"
	menu_dialog.ok_button_text = "Hold and leave"
	cash_out_button = menu_dialog.add_button("Cash out and leave", true, "cash_out")
	menu_dialog.custom_action.connect(_on_leave_custom_action)
	end_session_dialog.confirmed.connect(_end_session)
	print_pause_hold_button.pressed.connect(_end_print_pause)
	print_pause_ticket_button.pressed.connect(_print_pause_to_ticket)
	end_session_dialog.canceled.connect(_cancel_confirm_dialog)
	end_session_dialog.get_cancel_button().text = "Stay"
	_style_ui_buttons()


func _apply_launch_mode() -> void:
	if SaveManager.launch_mode == "continue":
		var data: Dictionary = SaveManager.load_game()
		if not data.is_empty():
			SaveManager.apply_to(portfolio, market, data)
	else:
		var names: Array[String] = CompanyCatalog.sanitize_watchlist(SaveManager.pending_watchlist)
		market.set_watchlist(names)
		SaveManager.pending_watchlist.clear()
		portfolio.reset_new_game()
		market.chain_director.reset()
		market.regime.reset()
		SaveManager.clear_away()
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
		button.tooltip_text = CopyHints.chart_tooltip(tf)
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
	for symbol in market.watchlist:
		var card: WatchlistCard = CARD_SCENE.instantiate()
		watchlist_list.add_child(card)
		card.selected.connect(_select_stock)
		watchlist_cards[symbol] = card


func _apply_hud_tooltips() -> void:
	CopyHints.hover(daily_pl_label, CopyHints.HUD_PL)
	CopyHints.hover(portfolio_total_label, CopyHints.HUD_PL)
	CopyHints.hover(vs_market_label, CopyHints.HUD_VS)
	CopyHints.hover(portfolio_value_label, CopyHints.HUD_BOOK)
	CopyHints.hover(commission_label, CopyHints.HUD_COMMISSION)
	CopyHints.hover(est_price_label, CopyHints.HUD_BID_ASK)
	CopyHints.hover(trade_price_label, CopyHints.HUD_BID_ASK)
	CopyHints.hover(market_status_label, market.regime.status_tooltip())
	CopyHints.hover(fade_mode_button, CopyHints.HUD_FADE)


func _displayed_day_number() -> int:
	if session_active:
		return portfolio.days_played + 1
	return maxi(portfolio.days_played, 1)


func _begin_session() -> void:
	session_active = true
	awaiting_open = true
	preopen_remaining = PREOPEN_SECONDS
	market.calendar_day = portfolio.days_played
	_consume_away_step()
	market.prepare()
	portfolio.mark_day_start(market.stocks)
	news_feed.clear()
	selected_symbol = market.watchlist[0]
	_set_trade_mode("buy")
	_set_quantity(20)
	trade_message_label.text = "Premarket is out. Read the headlines — the open is in 10 seconds."
	if market.away_applied:
		trade_message_label.text = "The desk moved overnight. Read the headlines — the open is in 10 seconds."
	for event in market.premarket_events:
		_add_news_to_feed(event)
	new_day_button.visible = false
	end_session_button.visible = true
	_refresh_end_session_button()
	place_order_button.disabled = true
	tick_timer.stop()
	open_countdown_overlay.visible = true
	closed_overlay.visible = false
	story_board_sig = ""
	_clear_print_pause()
	_refresh_open_countdown()
	_update_ui()


func _open_market() -> void:
	if not awaiting_open:
		return
	awaiting_open = false
	open_countdown_overlay.visible = false
	closed_overlay.visible = false
	var reopened: Array[NewsEvent] = market.reopen_halts_at_open()
	for event in reopened:
		_add_news_to_feed(event)
	var open_bell: NewsEvent = market.open()
	_add_news_to_feed(open_bell)
	place_order_button.disabled = false
	if reopened.is_empty():
		trade_message_label.text = "Market is open. Try to beat the market."
	tick_timer.start()
	_update_ui()
	_consider_act_pauses(reopened)


func _refresh_open_countdown() -> void:
	var seconds: int = maxi(ceili(preopen_remaining), 0)
	open_countdown_label.text = "Market will open in %d seconds" % seconds


func _on_market_tick() -> void:
	if not session_active or awaiting_open:
		return
	var new_events := market.tick()
	for event in new_events:
		_add_news_to_feed(event)
	_update_ui()
	if market.is_closed:
		_end_session()
		return
	_consider_act_pauses(new_events)


func _select_stock(symbol: String) -> void:
	if not market.stocks.has(symbol):
		return
	selected_symbol = symbol
	_update_ui()


func _set_trade_mode(mode: String) -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if mode == "buy" and stock != null and not stock.can_buy():
		mode = "sell"
	if mode == "fade" and stock != null and (not stock.is_listed() or portfolio.get_shares(selected_symbol) > 0):
		if portfolio.get_fade_shares(selected_symbol) > 0:
			mode = "fade"
		else:
			mode = "sell"
	fade_mode = mode == "fade"
	buy_mode = mode == "buy"
	_refresh_trade_panel()


func _set_quantity(value: int) -> void:
	quantity = maxi(value, 1)
	_refresh_trade_panel()


func _set_max_quantity() -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	if fade_mode:
		if portfolio.get_fade_shares(selected_symbol) > 0:
			_set_quantity(maxi(portfolio.get_fade_shares(selected_symbol), 1))
		else:
			_set_quantity(maxi(portfolio.max_fadable(stock.price, market.stocks), 1))
	elif buy_mode:
		_set_quantity(maxi(portfolio.max_buyable(stock.ask), 1))
	else:
		_set_quantity(maxi(portfolio.get_shares(selected_symbol), 1))


func _place_order() -> void:
	if print_pause_active:
		trade_message_label.text = "Act on the print, or Hold."
		return
	if awaiting_open:
		trade_message_label.text = "Market is not open yet."
		return
	if market.is_closed or not session_active:
		trade_message_label.text = "Market is closed."
		return
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	if fade_mode:
		var covering: bool = portfolio.get_fade_shares(selected_symbol) > 0
		var fill_shares: int = portfolio.get_fade_shares(selected_symbol) if covering else quantity
		var fade_result: Dictionary
		if covering:
			fade_result = portfolio.cover_fade(selected_symbol, stock.price)
		else:
			if not stock.is_listed():
				trade_message_label.text = "You can only fade a live name."
				return
			fade_result = portfolio.open_fade(selected_symbol, quantity, stock.price, market.stocks)
		trade_message_label.text = str(fade_result["message"])
		_update_ui()
		if bool(fade_result.get("success", false)):
			call_deferred("_play_fill_feedback", "cover" if covering else "fade", selected_symbol, fill_shares)
		return
	if buy_mode and not stock.can_buy():
		trade_message_label.text = "This name is %s. You cannot buy it." % stock.listing_label().to_lower()
		return
	if not buy_mode and not stock.can_sell():
		trade_message_label.text = "This name is halted. Wait for the reopen."
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
	if bool(result.get("success", false)):
		call_deferred("_play_fill_feedback", "buy" if buy_mode else "sell", selected_symbol, quantity)


func _end_session() -> void:
	if not session_active:
		return
	_clear_print_pause()
	menu_confirm_open = false
	var left_before_close: bool = not market.is_closed
	_run_tape_to_close()
	session_active = false
	awaiting_open = false
	open_countdown_overlay.visible = false
	print_pause_overlay.visible = false
	portfolio.cover_all_fades(market.stocks)
	closed_overlay.visible = true
	market.stop()
	tick_timer.stop()
	place_order_button.disabled = true
	end_session_button.visible = false
	new_day_button.visible = true

	var player_pct := portfolio.get_profit_loss_pct(market.stocks)
	var market_pct := market.get_market_return_pct()
	var alpha_pct := market.get_alpha_pct(player_pct)
	close_alpha_pct = alpha_pct
	var result_text: String
	if alpha_pct > 0.05:
		close_verdict = "BEAT"
		result_text = "You beat the market by %+.1f%%." % alpha_pct
	elif alpha_pct < -0.05:
		close_verdict = "LOST"
		result_text = "The market beat you by %.1f%%." % absf(alpha_pct)
	else:
		close_verdict = "MATCHED"
		result_text = "You matched the market."
	if left_before_close:
		result_text = "Marked to the close. " + result_text
	var wrecked: Array[String] = market.distressed_symbols()
	if not wrecked.is_empty():
		result_text += "\n%s marked distressed — sell-only until week recap." % ", ".join(wrecked)
	market.chain_director.calendar_day = market.calendar_day
	market.chain_director.on_session_end()
	market.regime.on_day_close()
	portfolio.record_session_close(portfolio.get_portfolio_value(market.stocks), alpha_pct)
	portfolio.days_played += 1
	if portfolio.chapter_just_finished():
		portfolio.pending_chapter = true
		new_day_button.text = "Week Recap"
	else:
		new_day_button.text = "New Day"
	var hook: String = market.chain_director.hook_line()
	if hook.is_empty():
		close_tomorrow = "No open story on the board."
		hook = close_tomorrow
	else:
		close_tomorrow = "Tomorrow: " + hook
		hook = close_tomorrow
	close_streak = portfolio.streak_line()
	close_book_line = _session_story_line()
	trade_message_label.text = "%s\n%s\n%s" % [result_text, portfolio.career_close_line(), hook]
	SaveManager.save_game(portfolio, market)
	_update_ui()


func _run_tape_to_close() -> void:
	tick_timer.stop()
	open_countdown_overlay.visible = false
	if awaiting_open:
		awaiting_open = false
		if not market.is_closed and not market.is_running:
			for event in market.reopen_halts_at_open():
				_add_news_to_feed(event)
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
	if not market.can_end_session():
		trade_message_label.text = "The open has to trade. End Session unlocks at 10:30."
		return
	_pause_for_confirm()
	end_session_dialog.popup_centered()


func _refresh_end_session_button() -> void:
	if not end_session_button.visible:
		return
	if session_active and not market.is_closed and not market.can_end_session():
		end_session_button.disabled = true
		end_session_button.tooltip_text = "The open has to trade. Unlocks after the first hour of the session."
		if awaiting_open:
			end_session_button.text = "End Session  10:30"
		else:
			end_session_button.text = "End Session  %dm" % market.minutes_until_end_session()
	else:
		end_session_button.disabled = false
		end_session_button.text = "End Session"
		end_session_button.tooltip_text = "Skip to the close. Today still marks overnight."


func _confirm_leave_desk(intent: String) -> void:
	leave_intent = intent
	_pause_for_confirm()
	var has_positions: bool = not portfolio.holdings.is_empty()
	if cash_out_button != null:
		cash_out_button.visible = has_positions
	if intent == "quit":
		menu_dialog.title = "Leave the Desk"
	else:
		menu_dialog.title = "Return to Menu"

	var lines: PackedStringArray = []
	if session_active and not market.is_closed:
		lines.append("If the market is still open, today will be marked to the close.")
	if has_positions:
		lines.append("A long real-world gap before you return can gap names overnight. Open positions may move while you are away.")
		lines.append("Hold them overnight, or sell everything at the bid now.")
		menu_dialog.ok_button_text = "Hold and leave"
	else:
		lines.append("Your book is cash. Nothing is left overnight in names.")
		menu_dialog.ok_button_text = "Leave"
	menu_dialog.dialog_text = "\n\n".join(lines)
	menu_dialog.popup_centered()


func _pause_for_confirm() -> void:
	menu_confirm_open = true
	tick_timer.stop()


func _cancel_confirm_dialog() -> void:
	menu_confirm_open = false
	if print_pause_active:
		return
	if session_active and not awaiting_open and not market.is_closed:
		tick_timer.start()


func _on_leave_custom_action(action: StringName) -> void:
	if str(action) != "cash_out":
		return
	_leave_desk(true)


func _on_leave_hold() -> void:
	_leave_desk(false)


func _leave_desk(cash_out: bool) -> void:
	menu_confirm_open = false
	if session_active:
		_end_session()
	if cash_out:
		_cash_out_all()
	SaveManager.stamp_left_desk()
	SaveManager.save_game(portfolio, market)
	if leave_intent == "quit":
		get_tree().quit()
	else:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _cash_out_all() -> void:
	portfolio.cover_all_fades(market.stocks)
	var symbols: Array = portfolio.holdings.keys()
	for item in symbols:
		_flatten_symbol(str(item))


func _restart_session() -> void:
	if portfolio.pending_chapter:
		_show_chapter_recap()
		return
	_start_next_trading_day()


func _consume_away_step() -> void:
	var hours: float = SaveManager.pending_away_hours
	if hours < SaveManager.AWAY_GAP_HOURS:
		return
	market.apply_away_step(hours)
	SaveManager.clear_away()
	SaveManager.save_game(portfolio, market)


func _start_next_trading_day() -> void:
	market.roll_to_next_day()
	_begin_session()


func _apply_responsive_layout() -> void:
	var narrow: bool = size.x < NARROW_WIDTH
	body_columns.vertical = narrow
	top_row.vertical = narrow
	bottom_row.vertical = narrow
	watchlist_column.custom_minimum_size.x = 0.0 if narrow else 280.0
	portfolio_column.custom_minimum_size.x = 0.0 if narrow else 280.0
	trade_column.custom_minimum_size.x = 0.0 if narrow else 300.0
	watchlist_column.size_flags_vertical = SIZE_EXPAND_FILL
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
	day_label.text = Portfolio.session_heading(_displayed_day_number())
	var market_pct := market.get_market_return_pct()
	var alpha_pct := market.get_alpha_pct(pl_pct)
	vs_market_label.text = "vs Market: %+.1f%%  (market %+.1f%%)" % [alpha_pct, market_pct]
	vs_market_label.add_theme_color_override("font_color", _pl_color(alpha_pct))

	for symbol in watchlist_cards:
		var card: WatchlistCard = watchlist_cards[symbol]
		card.refresh(
			market.stocks[symbol],
			portfolio.get_shares(symbol),
			portfolio.get_fade_shares(symbol),
			portfolio.get_fade_entry(symbol)
		)
		card.set_selected(symbol == selected_symbol)

	_refresh_selected_stock()
	_refresh_chart()
	_refresh_story_board()
	_refresh_portfolio()
	_refresh_trade_panel()

	market_status_label.text = "MARKET STATUS:  %s" % market.regime.status_text()
	market_status_label.add_theme_color_override("font_color", market.regime.status_color())
	market_status_label.tooltip_text = market.regime.status_tooltip()
	_refresh_end_session_button()


func _refresh_selected_stock() -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	selected_name_label.text = "%s — %s" % [stock.symbol, stock.company_name]
	selected_price_label.text = "$%.2f" % stock.price
	var change: float = stock.get_day_change()
	selected_change_label.text = "%s$%.2f (%s%.2f%%)" % [_sign(change), absf(change), _sign(change), absf(stock.get_day_change_pct())]
	selected_change_label.add_theme_color_override("font_color", _pl_color(change))
	var typical: String = str(CompanyCatalog.risk_profile(stock.symbol).get("typical", ""))
	if stock.is_halted():
		if stock.halt_outcome == Stock.OUTCOME_RESUME:
			selected_meta_label.text = "HALTED · volatility pause · reopens listed"
		else:
			selected_meta_label.text = "HALTED · no trading until distressed reopen"
		selected_meta_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
		CopyHints.hover(selected_meta_label, stock.halt_tooltip())
	elif stock.is_distressed():
		selected_meta_label.text = "DISTRESSED · sell-only residual · replaced at week recap"
		selected_meta_label.add_theme_color_override("font_color", Color(0.95, 0.38, 0.38))
		CopyHints.hover(selected_meta_label, CopyHints.HUD_DISTRESSED)
	else:
		selected_meta_label.text = "%s · %s · %s · %s" % [stock.personality_label, typical, stock.sector, stock.market_cap_label]
		selected_meta_label.add_theme_color_override("font_color", CompanyCatalog.risk_color(stock.risk_key))
		selected_meta_label.tooltip_text = ""


func _refresh_chart() -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	var points: int = int(TF_POINTS[timeframe])
	var slice: Dictionary = stock.get_chart_slice(points, 1)
	main_chart.compact = false
	main_chart.set_series(slice["prices"], slice["volumes"])
	var session_over: bool = closed_overlay.visible or market.is_closed
	if session_over:
		main_chart.set_status_banner("")
	elif stock.is_halted():
		var sub: String = "No trading · reopens listed" if stock.halt_outcome == Stock.OUTCOME_RESUME else "No trading · reopens distressed"
		main_chart.set_status_banner("HALTED", sub, Color(0.95, 0.78, 0.28))
	elif stock.is_distressed():
		main_chart.set_status_banner("DISTRESSED", "Sell-only residual", Color(0.95, 0.38, 0.38))
	else:
		main_chart.set_status_banner("")
	_refresh_closed_overlay(stock)


func _refresh_closed_overlay(stock: Stock) -> void:
	if not closed_overlay.visible:
		return
	close_hero_label.text = "%+.1f%% vs Market" % close_alpha_pct
	close_hero_label.add_theme_color_override("font_color", _pl_color(close_alpha_pct))
	close_verdict_label.text = close_verdict
	close_verdict_label.add_theme_color_override("font_color", _pl_color(close_alpha_pct))
	close_streak_label.text = close_streak
	close_book_label.text = close_book_line
	close_tomorrow_label.text = close_tomorrow
	if stock.is_distressed():
		close_listing_label.text = "DISTRESSED · sell-only residual"
		close_listing_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.52, 0.95))
	elif stock.is_halted():
		close_listing_label.text = "HALTED"
		close_listing_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45, 0.95))
	else:
		close_listing_label.text = "Market closed"
		close_listing_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))


func _refresh_portfolio() -> void:
	for child in portfolio_list.get_children():
		portfolio_list.remove_child(child)
		child.free()

	var total_pl := 0.0
	var has_rows := false
	for symbol in market.watchlist:
		if not portfolio.holdings.has(symbol):
			continue
		has_rows = true
		var stock: Stock = market.stocks[symbol]
		var shares: int = portfolio.get_shares(symbol)
		var avg: float = portfolio.get_avg_cost(symbol)
		var pos_pl: float = portfolio.get_position_pl(symbol, stock.price)
		total_pl += pos_pl
		var row := Label.new()
		row.text = "%s — %d shares — $%.2f — %s$%.2f" % [
			symbol, shares, avg, _sign(pos_pl), absf(pos_pl)
		]
		row.set_meta("fill_key", symbol)
		row.add_theme_color_override("font_color", _pl_color(pos_pl))
		portfolio_list.add_child(row)
	for symbol in market.watchlist:
		if portfolio.get_fade_shares(symbol) <= 0:
			continue
		has_rows = true
		var fade_stock: Stock = market.stocks[symbol]
		var fade_pl: float = (portfolio.get_fade_entry(symbol) - fade_stock.price) * float(portfolio.get_fade_shares(symbol))
		total_pl += fade_pl
		var fade_row := Label.new()
		fade_row.text = "FADE %s — %d — $%.2f — %s$%.2f" % [
			symbol, portfolio.get_fade_shares(symbol), portfolio.get_fade_entry(symbol), _sign(fade_pl), absf(fade_pl)
		]
		fade_row.set_meta("fill_key", "fade:%s" % symbol)
		fade_row.add_theme_color_override("font_color", _pl_color(fade_pl))
		portfolio_list.add_child(fade_row)
	if not has_rows:
		var empty := Label.new()
		empty.text = "No positions yet."
		empty.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
		portfolio_list.add_child(empty)

	portfolio_total_label.text = "Open P/L: %s$%.2f" % [_sign(total_pl), absf(total_pl)]
	portfolio_total_label.add_theme_color_override("font_color", _pl_color(total_pl))


func _play_fill_feedback(kind: String, symbol: String, shares: int) -> void:
	var accent: Color = BUY_ACCENT
	var chip: String = "+%d %s" % [shares, symbol]
	var from_book: bool = false
	match kind:
		"sell":
			accent = SELL_ACCENT
			chip = "−%d %s" % [shares, symbol]
			from_book = true
		"fade":
			accent = FADE_ACCENT
			chip = "FADE %d %s" % [shares, symbol]
		"cover":
			accent = FADE_ACCENT
			chip = "COVER %d %s" % [shares, symbol]
			from_book = true
	var card: WatchlistCard = watchlist_cards.get(symbol) as WatchlistCard
	if card != null:
		card.pulse_fill(accent)
	_pulse_control(portfolio_column, accent)
	_pulse_control(portfolio_total_label, accent)
	var row_key: String = "fade:%s" % symbol if kind == "fade" or kind == "cover" else symbol
	_pulse_portfolio_row(row_key, accent)
	var from_node: Control = portfolio_column if from_book else card
	var to_node: Control = card if from_book else portfolio_column
	if from_node != null and to_node != null:
		_spawn_fill_chip(chip, accent, from_node, to_node)


func _pulse_control(node: Control, accent: Color) -> void:
	if node == null:
		return
	node.modulate = Color(
		clampf(accent.r + 0.35, 0.0, 1.0),
		clampf(accent.g + 0.35, 0.0, 1.0),
		clampf(accent.b + 0.35, 0.0, 1.0)
	)
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color.WHITE, 0.5)


func _pulse_portfolio_row(fill_key: String, accent: Color) -> void:
	for child in portfolio_list.get_children():
		if child.has_meta("fill_key") and str(child.get_meta("fill_key")) == fill_key:
			_pulse_control(child as Control, accent)
			return


func _spawn_fill_chip(text: String, accent: Color, from_node: Control, to_node: Control) -> void:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.top_level = true
	label.z_index = 40
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", accent)
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.05, 0.07, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	label.reset_size()
	var start: Vector2 = from_node.get_global_rect().get_center() - label.size * 0.5
	var finish: Vector2 = to_node.get_global_rect().get_center() - label.size * 0.5
	label.global_position = start
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(label, "global_position", finish, 0.48)
	tw.tween_property(label, "modulate:a", 0.0, 0.32).set_delay(0.18)
	tw.chain().tween_callback(label.queue_free)


func _refresh_trade_panel() -> void:
	var stock: Stock = market.get_stock(selected_symbol)
	if stock == null:
		return
	trade_symbol_label.text = "TRADE  %s" % stock.symbol
	if stock.is_distressed() and buy_mode:
		buy_mode = false
		fade_mode = false
	if fade_mode and not stock.is_listed() and portfolio.get_fade_shares(selected_symbol) <= 0:
		fade_mode = false
		buy_mode = false
	var covering: bool = fade_mode and portfolio.get_fade_shares(selected_symbol) > 0
	var px: float = stock.price if fade_mode else (stock.ask if buy_mode else stock.bid)
	trade_price_label.text = "$%.2f" % px
	qty_label.text = str(quantity)
	if covering:
		place_order_button.text = "COVER FADE"
	elif fade_mode:
		place_order_button.text = "OPEN FADE"
	elif buy_mode:
		place_order_button.text = "PLACE BUY ORDER"
	else:
		place_order_button.text = "PLACE SELL ORDER"
	var can_order: bool = session_active and not awaiting_open and not market.is_closed and not print_pause_active
	if fade_mode:
		if covering:
			can_order = can_order and true
		else:
			can_order = can_order and stock.is_listed() and portfolio.get_shares(selected_symbol) <= 0
	elif stock.is_halted() or (buy_mode and not stock.can_buy()) or (not buy_mode and not stock.can_sell()):
		can_order = false
	if not fade_mode and not buy_mode and portfolio.get_shares(selected_symbol) <= 0:
		can_order = false
	place_order_button.disabled = not can_order
	buy_mode_button.disabled = not stock.can_buy() or portfolio.get_fade_shares(selected_symbol) > 0
	fade_mode_button.disabled = (not stock.is_listed() and not covering) or (portfolio.get_shares(selected_symbol) > 0 and not covering)
	_style_trade_buttons()

	if fade_mode:
		est_price_label.text = "Last print: $%.2f" % stock.price
		if covering:
			var pl: float = (portfolio.get_fade_entry(selected_symbol) - stock.price) * float(portfolio.get_fade_shares(selected_symbol))
			est_total_label.text = "Open fade: %d @ $%.2f" % [portfolio.get_fade_shares(selected_symbol), portfolio.get_fade_entry(selected_symbol)]
			commission_label.text = "Marked P/L: %s$%.2f" % [_sign(pl), absf(pl)]
			final_total_label.text = "Pays if this name printed lower."
		else:
			var estimate: Dictionary = portfolio.estimate(quantity, stock.price)
			est_total_label.text = "Notional: $%.2f" % float(estimate["trade_value"])
			commission_label.text = "Commission: $%.2f" % float(estimate["commission"])
			final_total_label.text = "Pays if this name prints lower. Covers at the close."
		trade_price_label.tooltip_text = CopyHints.HUD_FADE
		return
	var estimate: Dictionary = portfolio.estimate(quantity, px)
	est_price_label.text = "Estimated price: $%.2f" % px
	est_total_label.text = "Estimated total: $%.2f" % float(estimate["trade_value"])
	commission_label.text = "Commission: $%.2f" % float(estimate["commission"])
	if buy_mode:
		final_total_label.text = "Total: $%.2f" % float(estimate["total"])
		trade_price_label.tooltip_text = CopyHints.HUD_ASK
	else:
		final_total_label.text = "Total proceeds: $%.2f" % float(estimate["proceeds"])
		trade_price_label.tooltip_text = CopyHints.HUD_BID


func _style_ui_buttons() -> void:
	_apply_button_style(%SettingsButton, UI_ACCENT, UI_BORDER)
	_apply_button_style(%MenuButton, UI_ACCENT, UI_BORDER)
	_apply_button_style(end_session_button, UI_ACCENT, UI_BORDER)
	_apply_button_style(new_day_button, SELECTED_ACCENT, UI_BORDER)
	_apply_button_style(print_pause_hold_button, UI_ACCENT, UI_BORDER)
	_apply_button_style(print_pause_ticket_button, SELECTED_ACCENT, UI_BORDER)


func _style_timeframe_buttons() -> void:
	for child in timeframe_buttons.get_children():
		var button := child as Button
		button.button_pressed = button.text == timeframe
		var accent: Color = SELECTED_ACCENT if button.text == timeframe else UI_ACCENT
		_apply_button_style(button, accent, UI_BORDER, button.text == timeframe)


func _style_trade_buttons() -> void:
	var buy_on: bool = buy_mode and not fade_mode
	var sell_on: bool = (not buy_mode) and not fade_mode
	var buy_accent: Color = BUY_ACCENT if buy_on else INACTIVE_ACCENT
	var sell_accent: Color = SELL_ACCENT if sell_on else INACTIVE_ACCENT
	var fade_accent: Color = FADE_ACCENT if fade_mode else INACTIVE_ACCENT
	_apply_button_style(buy_mode_button, buy_accent, TRADE_BORDER, buy_on, buy_on)
	_apply_button_style(sell_mode_button, sell_accent, TRADE_BORDER, sell_on, sell_on)
	_apply_button_style(fade_mode_button, fade_accent, TRADE_BORDER, fade_mode, fade_mode)
	_apply_button_style(%QtyMinusButton, TRADE_ACCENT, TRADE_BORDER)
	_apply_button_style(%QtyPlusButton, TRADE_ACCENT, TRADE_BORDER)
	_apply_button_style(%Qty10Button, TRADE_ACCENT, TRADE_BORDER, quantity == 10)
	_apply_button_style(%Qty20Button, TRADE_ACCENT, TRADE_BORDER, quantity == 20)
	_apply_button_style(%Qty50Button, TRADE_ACCENT, TRADE_BORDER, quantity == 50)
	_apply_button_style(%Qty100Button, TRADE_ACCENT, TRADE_BORDER, quantity == 100)
	_apply_button_style(%QtyMaxButton, TRADE_ACCENT, TRADE_BORDER)
	var order_accent: Color = FADE_ACCENT if fade_mode else (BUY_ACCENT if buy_mode else SELL_ACCENT)
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
			color, event.timestamp, tag, CopyHints.annotate(event.headline)
		])
	else:
		news_feed.append_text("[color=%s]%s  [b]%s[/b] · %s — %s[/color]\n" % [
			color, event.timestamp, tag, effect, CopyHints.annotate(event.headline)
		])
	if not event.reaction.is_empty():
		news_feed.append_text("[color=#888888]    %s[/color]\n" % CopyHints.annotate(event.reaction))
	if event.existential or event.headline.begins_with("HALTED") or event.headline.begins_with("REOPEN") or event.headline.begins_with("PREMARKET: HALTED") or event.headline.begins_with("PREMARKET: REOPEN"):
		trade_message_label.text = "%s\n%s" % [event.headline, event.reaction]


func _build_settings() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	settings_dialog.add_child(row)
	speed_buttons.clear()
	for n in [1, 2, 3]:
		var button := Button.new()
		button.text = "%d×" % n
		button.pressed.connect(_set_tape_speed.bind(n))
		row.add_child(button)
		speed_buttons.append(button)
		_apply_button_style(button, SELECTED_ACCENT if n == tape_speed else UI_ACCENT, UI_BORDER, n == tape_speed)


func _set_tape_speed(mult: int) -> void:
	tape_speed = clampi(mult, 1, 3)
	SaveManager.tape_speed = tape_speed
	_apply_tape_speed()
	for button in speed_buttons:
		var n: int = int(str(button.text).replace("×", ""))
		_apply_button_style(button, SELECTED_ACCENT if n == tape_speed else UI_ACCENT, UI_BORDER, n == tape_speed)


func _apply_tape_speed() -> void:
	tick_timer.wait_time = TICK_INTERVAL / float(maxi(tape_speed, 1))


func _consider_act_pauses(events: Array[NewsEvent]) -> void:
	if print_pause_active or awaiting_open or not session_active or market.is_closed:
		return
	if market.drama.spectator:
		return
	for event in events:
		if event.should_act_pause():
			_begin_print_pause(event)
			return


func _begin_print_pause(event: NewsEvent) -> void:
	print_pause_active = true
	print_pause_left = event.act_pause_seconds()
	print_pause_symbol = ""
	if event.affected_symbols.size() > 0:
		var symbol: String = event.affected_symbols[0]
		if market.watchlist.has(symbol):
			print_pause_symbol = symbol
	print_pause_headline.text = event.headline
	print_pause_reaction.text = event.reaction if not event.reaction.is_empty() else "The tape is waiting on your call."
	print_pause_ticket_button.visible = not print_pause_symbol.is_empty()
	print_pause_overlay.visible = true
	tick_timer.stop()
	_refresh_print_pause_timer()
	_refresh_trade_panel()


func _refresh_print_pause_timer() -> void:
	print_pause_timer.text = "Hold in %ds" % maxi(ceili(print_pause_left), 0)


func _clear_print_pause() -> void:
	print_pause_active = false
	print_pause_overlay.visible = false
	print_pause_left = 0.0


func _end_print_pause() -> void:
	var was_paused: bool = print_pause_active
	_clear_print_pause()
	if was_paused and session_active and not awaiting_open and not market.is_closed and not menu_confirm_open:
		tick_timer.start()
	_refresh_trade_panel()


func _print_pause_to_ticket() -> void:
	if not print_pause_symbol.is_empty():
		_select_stock(print_pause_symbol)
	_end_print_pause()


func _refresh_story_board() -> void:
	var entries: Array[Dictionary] = market.chain_director.board_entries()
	var sig: String = _story_board_signature(entries)
	if sig == story_board_sig:
		return
	story_board_sig = sig
	for child in story_board.get_children():
		story_board.remove_child(child)
		child.queue_free()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "No open story."
		empty.add_theme_color_override("font_color", Color(0.55, 0.58, 0.64))
		story_board.add_child(empty)
		return
	for entry in entries:
		story_board.add_child(_make_story_card(entry))


func _story_board_signature(entries: Array[Dictionary]) -> String:
	var bits: PackedStringArray = []
	for entry in entries:
		var subject: String = str(entry.get("subject", ""))
		var listing: String = ""
		if market.stocks.has(subject):
			listing = market.stocks[subject].listing_label()
		bits.append("%s|%s|%s|%s|%s" % [
			subject,
			str(entry.get("stage", "")),
			str(entry.get("polar", "")),
			str(entry.get("hook", "")),
			listing,
		])
	return "|".join(bits)


func _make_story_card(entry: Dictionary) -> Button:
	var subject: String = str(entry.get("subject", ""))
	var scope: String = str(entry.get("scope", "company"))
	var title: String = subject
	match scope:
		"company":
			title = subject
		"industry":
			var industry_name: String = str(entry.get("industry", "SECTOR"))
			title = industry_name if not industry_name.is_empty() else "SECTOR"
		_:
			title = "TAPE"
	var listing: String = ""
	if market.stocks.has(subject):
		var stock: Stock = market.stocks[subject]
		if stock.is_halted():
			listing = " · HALTED"
		elif stock.is_distressed():
			listing = " · DISTRESSED"
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s  %s  %s%s\n%s" % [
		title,
		str(entry.get("polar", "")),
		str(entry.get("stage", "")),
		listing,
		str(entry.get("hook", "")),
	]
	button.clip_text = true
	if scope == "company" and market.watchlist.has(subject):
		button.pressed.connect(_select_stock.bind(subject), CONNECT_DEFERRED)
	_apply_button_style(button, UI_ACCENT, UI_BORDER)
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 52)
	return button


func _session_story_line() -> String:
	var wrecked: Array[String] = market.distressed_symbols()
	if not wrecked.is_empty():
		var held: PackedStringArray = []
		var flat: PackedStringArray = []
		for symbol in wrecked:
			if portfolio.get_shares(symbol) > 0:
				held.append(symbol)
			else:
				flat.append(symbol)
		if not held.is_empty():
			return "You held %s through the wipe." % ", ".join(held)
		return "You flattened before the wipe on %s." % ", ".join(flat)
	for chain in market.chain_director.active:
		if chain.pending != "resolution":
			continue
		if chain.polarity >= 0.0 or not EventChainDirector.arc_is_existential(chain.arc_id):
			continue
		if chain.scope == "company":
			if portfolio.get_shares(chain.subject) > 0:
				return "You are still long into tomorrow's binary on %s." % chain.subject
			return "You are flat into tomorrow's binary on %s." % chain.subject
		return "You are heading into a binary print."
	return "No wipe on the book today."


func _sign(value: float) -> String:
	return "+" if value >= 0.0 else "-"


func _pl_color(value: float) -> Color:
	if value >= 0.0:
		return Color(0.35, 0.85, 0.45)
	return Color(0.95, 0.38, 0.38)


func _build_chapter_overlay() -> void:
	chapter_overlay = ColorRect.new()
	chapter_overlay.visible = false
	chapter_overlay.color = Color(0.04, 0.05, 0.07, 0.9)
	chapter_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chapter_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(chapter_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chapter_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(0.1, 0.11, 0.14, 1)
	panel_box.border_color = Color(0.78, 0.82, 0.9, 0.7)
	panel_box.set_border_width_all(1)
	panel_box.set_corner_radius_all(10)
	panel_box.content_margin_left = 20
	panel_box.content_margin_right = 20
	panel_box.content_margin_top = 18
	panel_box.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", panel_box)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)

	recap_page = VBoxContainer.new()
	recap_page.add_theme_constant_override("separation", 12)
	stack.add_child(recap_page)
	var recap_title := Label.new()
	recap_title.text = "WEEK RECAP"
	recap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recap_title.add_theme_color_override("font_color", SELECTED_ACCENT)
	recap_title.add_theme_font_size_override("font_size", 22)
	recap_page.add_child(recap_title)
	recap_label = Label.new()
	recap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recap_label.add_theme_font_size_override("font_size", 15)
	recap_page.add_child(recap_label)
	CopyHints.hover(recap_label, "%s\n%s\n%s" % [CopyHints.HUD_BOOK, CopyHints.HUD_ATH, CopyHints.HUD_VS])
	var recap_next := Button.new()
	recap_next.text = "Rebalance Watchlist"
	recap_next.custom_minimum_size = Vector2(0, 44)
	recap_next.pressed.connect(_show_chapter_rebalance)
	recap_page.add_child(recap_next)
	_apply_button_style(recap_next, SELECTED_ACCENT, UI_BORDER, true)

	rebalance_page = VBoxContainer.new()
	rebalance_page.visible = false
	rebalance_page.add_theme_constant_override("separation", 10)
	stack.add_child(rebalance_page)
	rebalance_title = Label.new()
	rebalance_title.text = "ONE SWAP"
	rebalance_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rebalance_title.add_theme_color_override("font_color", SELECTED_ACCENT)
	rebalance_title.add_theme_font_size_override("font_size", 20)
	rebalance_page.add_child(rebalance_title)
	rebalance_hint = Label.new()
	rebalance_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rebalance_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rebalance_hint.add_theme_font_size_override("font_size", 14)
	rebalance_hint.text = "Keep these three, or drop one name and pick a replacement. A dropped name is sold at the bid."
	if not forced_drops.is_empty():
		rebalance_hint.text = "Distressed names must leave the board. Pick a replacement for each. Residual shares sell at the bid."
	CopyHints.hover(rebalance_hint, CopyHints.HUD_BID)
	rebalance_page.add_child(rebalance_hint)
	keep_book_button = Button.new()
	keep_book_button.toggle_mode = true
	keep_book_button.text = "Keep this book"
	CopyHints.hover(keep_book_button, CopyHints.HUD_BOOK)
	keep_book_button.pressed.connect(_on_keep_book)
	rebalance_page.add_child(keep_book_button)
	drop_header = Label.new()
	drop_header.text = "Drop (optional)"
	drop_header.add_theme_font_size_override("font_size", 13)
	rebalance_page.add_child(drop_header)
	drop_list = VBoxContainer.new()
	drop_list.add_theme_constant_override("separation", 6)
	rebalance_page.add_child(drop_list)
	var add_header := Label.new()
	add_header.text = "Add"
	add_header.add_theme_font_size_override("font_size", 13)
	rebalance_page.add_child(add_header)
	add_list = VBoxContainer.new()
	add_list.add_theme_constant_override("separation", 6)
	rebalance_page.add_child(add_list)
	confirm_swap_button = Button.new()
	confirm_swap_button.text = "Continue"
	confirm_swap_button.custom_minimum_size = Vector2(0, 44)
	confirm_swap_button.pressed.connect(_confirm_chapter_rebalance)
	rebalance_page.add_child(confirm_swap_button)


func _show_chapter_recap() -> void:
	session_active = false
	awaiting_open = false
	tick_timer.stop()
	open_countdown_overlay.visible = false
	closed_overlay.visible = false
	new_day_button.visible = false
	end_session_button.visible = false
	recap_page.visible = true
	rebalance_page.visible = false
	recap_label.text = portfolio.recap_text(market.regime.status_text(), market.watchlist)
	var wrecked: Array[String] = market.distressed_symbols()
	if not wrecked.is_empty():
		recap_label.text += "\n%s distressed — must replace. Residual shares sell at the bid." % ", ".join(wrecked)
	chapter_overlay.visible = true


func _show_chapter_rebalance() -> void:
	recap_page.visible = false
	rebalance_page.visible = true
	forced_drops = market.distressed_symbols()
	keep_book = forced_drops.is_empty()
	drop_pick = ""
	add_pick = ""
	add_picks.clear()
	_rebuild_rebalance_lists()
	_refresh_rebalance_state()


func _rebuild_rebalance_lists() -> void:
	for child in drop_list.get_children():
		drop_list.remove_child(child)
		child.free()
	for child in add_list.get_children():
		add_list.remove_child(child)
		child.free()
	for symbol in market.watchlist:
		var button := Button.new()
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _rebalance_row_text(symbol)
		button.pressed.connect(_on_drop_pressed.bind(symbol))
		drop_list.add_child(button)
	for symbol in CompanyCatalog.bench_symbols(market.watchlist):
		var button := Button.new()
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _rebalance_row_text(symbol)
		button.pressed.connect(_on_add_pressed.bind(symbol))
		add_list.add_child(button)


func _rebalance_row_text(symbol: String) -> String:
	var data: Dictionary = CompanyCatalog.spec(symbol)
	var line: String = "%s  %s  ·  %s" % [symbol, str(data.get("name", symbol)), str(data.get("label", ""))]
	if market.stocks.has(symbol) and market.stocks[symbol].is_distressed():
		line += "  ·  DISTRESSED"
	return line


func _on_keep_book() -> void:
	if not forced_drops.is_empty():
		keep_book_button.button_pressed = false
		return
	keep_book = true
	drop_pick = ""
	add_pick = ""
	add_picks.clear()
	_refresh_rebalance_state()


func _on_drop_pressed(symbol: String) -> void:
	if forced_drops.has(symbol):
		_refresh_rebalance_state()
		return
	if not forced_drops.is_empty():
		_refresh_rebalance_state()
		return
	keep_book = false
	if drop_pick == symbol:
		drop_pick = ""
		keep_book = true
	else:
		drop_pick = symbol
	add_pick = ""
	_refresh_rebalance_state()


func _on_add_pressed(symbol: String) -> void:
	if not forced_drops.is_empty():
		if add_picks.has(symbol):
			add_picks.erase(symbol)
		elif add_picks.size() < forced_drops.size():
			add_picks.append(symbol)
		_refresh_rebalance_state()
		return
	if drop_pick.is_empty():
		add_pick = ""
		_refresh_rebalance_state()
		return
	keep_book = false
	add_pick = "" if add_pick == symbol else symbol
	_refresh_rebalance_state()


func _refresh_rebalance_state() -> void:
	var forced: bool = not forced_drops.is_empty()
	keep_book_button.disabled = forced
	keep_book_button.visible = not forced
	keep_book_button.button_pressed = keep_book and not forced
	_apply_button_style(keep_book_button, SELECTED_ACCENT if keep_book and not forced else UI_ACCENT, UI_BORDER, keep_book and not forced)
	if forced:
		rebalance_title.text = "REPLACE DISTRESSED"
		drop_header.text = "Must drop"
		rebalance_hint.text = "Distressed names must leave the board. Pick %d replacement(s). Residual shares sell at the bid." % forced_drops.size()
	else:
		rebalance_title.text = "ONE SWAP"
		drop_header.text = "Drop (optional)"
		rebalance_hint.text = "Keep these three, or drop one name and pick a replacement. A dropped name is sold at the bid."
	var drop_i := 0
	for child in drop_list.get_children():
		var button := child as Button
		var symbol: String = market.watchlist[drop_i]
		var locked: bool = forced_drops.has(symbol)
		var on: bool = locked or drop_pick == symbol
		button.button_pressed = on
		button.disabled = forced and not locked
		_apply_button_style(button, SELECTED_ACCENT if on else CompanyCatalog.risk_color(CompanyCatalog.risk_key(symbol)), UI_BORDER, on)
		drop_i += 1
	var bench: Array[String] = CompanyCatalog.bench_symbols(market.watchlist)
	var add_i := 0
	for child in add_list.get_children():
		var button := child as Button
		var symbol: String = bench[add_i]
		var on: bool = add_picks.has(symbol) if forced else add_pick == symbol
		button.disabled = not forced and drop_pick.is_empty()
		button.button_pressed = on
		var accent: Color = SELECTED_ACCENT if on else CompanyCatalog.risk_color(CompanyCatalog.risk_key(symbol))
		_apply_button_style(button, accent, UI_BORDER, on)
		add_i += 1
	var ready: bool
	if forced:
		ready = add_picks.size() == forced_drops.size()
		confirm_swap_button.text = "Replace distressed names"
		if ready:
			confirm_swap_button.text = "Replace %s → %s" % [", ".join(forced_drops), ", ".join(add_picks)]
	else:
		ready = keep_book or (not drop_pick.is_empty() and not add_pick.is_empty())
		confirm_swap_button.text = "Keep book and continue" if keep_book else "Swap %s → %s" % [drop_pick, add_pick]
	confirm_swap_button.disabled = not ready
	_apply_button_style(confirm_swap_button, BUY_ACCENT, UI_BORDER, ready, ready)


func _confirm_chapter_rebalance() -> void:
	if not forced_drops.is_empty():
		if add_picks.size() != forced_drops.size():
			return
		for symbol in forced_drops:
			_flatten_symbol(symbol)
		market.replace_watchlist_names(forced_drops, add_picks)
		if forced_drops.has(selected_symbol):
			selected_symbol = market.watchlist[0]
		_build_watchlist()
	elif not keep_book:
		if drop_pick.is_empty() or add_pick.is_empty():
			return
		_flatten_symbol(drop_pick)
		market.swap_watchlist_name(drop_pick, add_pick)
		if selected_symbol == drop_pick:
			selected_symbol = add_pick
		_build_watchlist()
	portfolio.begin_next_chapter()
	SaveManager.save_game(portfolio, market)
	chapter_overlay.visible = false
	drop_pick = ""
	add_pick = ""
	add_picks.clear()
	forced_drops.clear()
	keep_book = true
	_start_next_trading_day()


func _flatten_symbol(symbol: String) -> void:
	var stock: Stock = market.get_stock(symbol)
	if stock == null:
		return
	if portfolio.get_fade_shares(symbol) > 0:
		portfolio.cover_fade(symbol, stock.price)
	var shares: int = portfolio.get_shares(symbol)
	if shares <= 0:
		return
	if stock.is_halted():
		stock.reopen()
	portfolio.sell(symbol, shares, stock.bid)
