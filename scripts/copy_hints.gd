class_name CopyHints
extends RefCounted

const HUD_PL := "Profit and loss vs the start of this session. Green is up, red is down."
const HUD_VS := "Your session return minus the average of your three names. That is the score: beat the market."
const HUD_BOOK := "Your book: cash plus the current value of everything you hold."
const HUD_ATH := "All-time high for this book — the peak value you have marked."
const HUD_BID_ASK := "Buy at the ask (sellers' price). Sell at the bid (buyers' price). The last print sits in between."
const HUD_BID := "Bid: what buyers will pay. You sell at this price."
const HUD_ASK := "Ask: what sellers want. You buy at this price."
const HUD_HALTED := "Trading is stopped on this name. Wait for the reopen — it will come back distressed."
const HUD_DISTRESSED := "Near-worthless residual. You can sell at the bid. You cannot buy. Replaced at week recap."
const HUD_COMMISSION := "A $2 fee plus 0.2% of the trade, taken on every order."
const HUD_MENU := "Book is cash plus holdings. ATH is this book's peak. vs Market is how you did against your three names."

const CHART := {
	"1M": "Last 20 market minutes. One print per minute — not one month.",
	"5M": "Last 60 market minutes (one hour of the session).",
	"15M": "Last 120 market minutes (two hours of the session).",
	"1H": "Last 180 market minutes (three hours of the session).",
	"1D": "The full session, as far as prices have printed.",
}

const _HINTS := {
	"NII": "Net interest income: what a bank earns on loans minus what it pays on deposits.",
	"ARR": "Annual recurring revenue: yearly subscription or contract income.",
	"RFP": "Request for proposal: a company asking vendors to compete for a contract.",
	"SKU": "Stock keeping unit: one specific product on the shelf.",
	"CIO": "Chief information officer: the IT buyer at a large company.",
	"CIOs": "Chief information officers: IT buyers at large companies.",
	"tape": "The live stream of prices and headlines. Old slang from ticker-tape machines.",
	"Tape": "The live stream of prices and headlines. Old slang from ticker-tape machines.",
	"PREMARKET": "Headlines and price moves before the 9:30 open.",
	"Premarket": "Headlines and price moves before the 9:30 open.",
	"premarket": "Headlines and price moves before the 9:30 open.",
	"OVERNIGHT": "While the session was closed. Prices can jump before you can trade.",
	"Overnight": "While the session was closed. Prices can jump before you can trade.",
	"overnight": "While the session was closed. Prices can jump before you can trade.",
	"gapped": "A jump in price from the last close to the next open, with little trading in between.",
	"gaps": "A jump in price from the last close to the next open, with little trading in between.",
	"Gap": "A jump in price from the last close to the next open, with little trading in between.",
	"gap": "A jump in price from the last close to the next open, with little trading in between.",
	"prints": "An official number hitting the market — earnings, inflation, traffic, and the like.",
	"Print": "An official number hitting the market — earnings, inflation, traffic, and the like.",
	"print": "An official number hitting the market — earnings, inflation, traffic, and the like.",
	"bids": "Buyers stepping in. That flow lifts the price.",
	"Bid": "Buyers stepping in. That flow lifts the price.",
	"bid": "Buyers stepping in. That flow lifts the price.",
	"Offered": "Sellers hitting the market. The name is being sold.",
	"offered": "Sellers hitting the market. The name is being sold.",
	"fades": "Trading against the headline — selling good news or buying bad news.",
	"faded": "Trading against the headline — selling good news or buying bad news.",
	"Fade": "Trading against the headline — selling good news or buying bad news.",
	"fade": "Trading against the headline — selling good news or buying bad news.",
	"Desks": "Professional traders at funds and banks.",
	"desks": "Professional traders at funds and banks.",
	"Desk": "Professional traders at funds and banks.",
	"desk": "Professional traders at funds and banks.",
	"Dovish": "Policy looking easier — cheaper money, usually a lift for stocks.",
	"dovish": "Policy looking easier — cheaper money, usually a lift for stocks.",
	"Hawkish": "Policy looking tighter — dearer money, usually a knock for stocks.",
	"hawkish": "Policy looking tighter — dearer money, usually a knock for stocks.",
	"high-duration": "How far out the cash is. Growth names swing more when rates move.",
	"Duration": "How far out the cash is. Growth names swing more when rates move.",
	"duration": "How far out the cash is. Growth names swing more when rates move.",
	"offtaker": "A buyer contracted to take the mine's output.",
	"Offtake": "A buyer contracted to take the mine's output.",
	"offtake": "A buyer contracted to take the mine's output.",
	"Guidance": "What the company says it will earn or ship from here.",
	"guidance": "What the company says it will earn or ship from here.",
	"Overweight": "Analyst speak for buy — they want more of this name than the typical basket.",
	"Underweight": "Analyst speak for sell — they want less of this name than the typical basket.",
	"HALTED": "Trading stopped on this name until it reopens.",
	"Distressed": "A leftover stub after a wipe. Sell-only, then it leaves the board at week recap.",
	"distressed": "A leftover stub after a wipe. Sell-only, then it leaves the board at week recap.",
	"DISTRESSED": "A leftover stub after a wipe. Sell-only, then it leaves the board at week recap.",
	"Binary": "The next print can make or break the name — including a halt and a near-worthless reopen.",
}

static var _term_re: RegEx


static func hover(control: Control, text: String) -> void:
	control.tooltip_text = text
	control.mouse_filter = Control.MOUSE_FILTER_STOP


static func chart_tooltip(timeframe: String) -> String:
	return str(CHART.get(timeframe, "Chart window on this name."))


static func annotate(text: String) -> String:
	if text.is_empty():
		return text
	var re: RegEx = _compiled()
	var out := ""
	var pos := 0
	var found: RegExMatch = re.search(text, pos)
	while found != null:
		out += text.substr(pos, found.get_start() - pos)
		var form: String = found.get_string()
		out += "[hint=%s][u]%s[/u][/hint]" % [str(_HINTS.get(form, "")), form]
		pos = found.get_end()
		found = re.search(text, pos)
	out += text.substr(pos)
	return out


static func _compiled() -> RegEx:
	if _term_re != null:
		return _term_re
	var forms: Array[String] = []
	for key in _HINTS.keys():
		forms.append(str(key))
	forms.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	var parts: PackedStringArray = []
	for form in forms:
		parts.append(_escape_re(form))
	_term_re = RegEx.new()
	_term_re.compile("\\b(?:%s)\\b" % "|".join(parts))
	return _term_re


static func _escape_re(text: String) -> String:
	var out := ""
	for ch in text:
		if ".\\+*?[^]$(){}=!<>|:".contains(ch):
			out += "\\"
		out += ch
	return out
