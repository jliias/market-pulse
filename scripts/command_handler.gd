class_name CommandHandler
extends RefCounted

var market: MarketSimulator
var portfolio: Portfolio


func _init(p_market: MarketSimulator, p_portfolio: Portfolio) -> void:
	market = p_market
	portfolio = p_portfolio


func execute(command_line: String) -> String:
	var parts: PackedStringArray = command_line.strip_edges().split(" ", false)
	if parts.is_empty():
		return ""

	var cmd: String = parts[0].to_upper()

	match cmd:
		"BUY":
			return _handle_buy(parts)
		"SELL":
			return _handle_sell(parts)
		"WAIT":
			return "Waiting for next market update..."
		"STATUS":
			return _handle_status()
		"HELP":
			return _handle_help()
		"QUIT":
			return "QUIT"
		_:
			return "Unknown command: %s. Type HELP for available commands." % cmd


func _handle_buy(parts: PackedStringArray) -> String:
	if parts.size() < 3:
		return "Usage: BUY <stock> <shares>  (e.g. BUY A 50)"

	var symbol: String = market.resolve_symbol(parts[1])
	if symbol.is_empty():
		return "Unknown stock: %s. Use A, B, or C." % parts[1]

	var shares: int = parts[2].to_int()
	if shares <= 0:
		return "Invalid share amount."

	var stock: Stock = market.get_stock(symbol)
	return portfolio.buy(symbol, shares, stock.ask)["message"]


func _handle_sell(parts: PackedStringArray) -> String:
	if parts.size() < 3:
		return "Usage: SELL <stock> <shares>  (e.g. SELL B 20)"

	var symbol: String = market.resolve_symbol(parts[1])
	if symbol.is_empty():
		return "Unknown stock: %s. Use A, B, or C." % parts[1]

	var shares: int = parts[2].to_int()
	if shares <= 0:
		return "Invalid share amount."

	var stock: Stock = market.get_stock(symbol)
	return portfolio.sell(symbol, shares, stock.bid)["message"]


func _handle_status() -> String:
	var lines: PackedStringArray = []
	lines.append("=== MARKET STATUS ===")
	lines.append("Time: %s" % market.get_time_string())
	lines.append("")
	lines.append("Cash: $%.2f" % portfolio.cash)
	lines.append("Holdings value: $%.2f" % portfolio.get_holdings_value(market.stocks))
	lines.append("Portfolio value: $%.2f" % portfolio.get_portfolio_value(market.stocks))
	var pl: float = portfolio.get_profit_loss(market.stocks)
	var pl_sign: String = "+" if pl >= 0 else ""
	lines.append("Profit/Loss: %s$%.2f (%s%.1f%%)" % [
		pl_sign, pl, pl_sign, portfolio.get_profit_loss_pct(market.stocks)
	])
	lines.append("Total commissions: $%.2f" % portfolio.total_commissions)
	lines.append("")
	lines.append("--- Stocks ---")

	for symbol in ["A", "B", "C"]:
		var stock: Stock = market.stocks[symbol]
		var owned: int = portfolio.get_shares(symbol)
		lines.append("%s (%s)" % [symbol, stock.company_name])
		lines.append("  Price: $%.2f  Bid: $%.2f  Ask: $%.2f" % [stock.price, stock.bid, stock.ask])
		lines.append("  Volume: %s  Trend: %s  Owned: %d" % [
			_format_volume(stock.volume), stock.get_trend_name(), owned
		])

	if not portfolio.trade_history.is_empty():
		lines.append("")
		lines.append("--- Recent Trades ---")
		var start := maxi(portfolio.trade_history.size() - 5, 0)
		for i in range(start, portfolio.trade_history.size()):
			var t: Dictionary = portfolio.trade_history[i]
			lines.append("  %s %d %s @ $%.2f" % [t["type"], t["shares"], t["symbol"], t["price"]])

	return "\n".join(lines)


func _handle_help() -> String:
	return """Available commands:
  BUY <stock> <shares>   Buy shares (e.g. BUY A 50)
  SELL <stock> <shares>  Sell shares (e.g. SELL B 20)
  WAIT                   Wait for next update
  STATUS                 Show account and market info
  HELP                   Show this help
  QUIT                   End trading session

Stocks: A (Alpha Technologies), B (Green Energy Corp), C (North Mining Ltd)
Commission: $2.00 + 0.2% per trade"""


func _format_volume(vol: int) -> String:
	if vol >= 1000000:
		return "%.1fM" % (float(vol) / 1000000.0)
	if vol >= 1000:
		return "%.1fK" % (float(vol) / 1000.0)
	return str(vol)
