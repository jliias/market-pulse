class_name CopyHints
extends RefCounted

const TAPE_HINT := "The live stream of prices and headlines. Old slang from ticker-tape machines."

const TERMS := {
	"NII": "Net interest income: what a bank earns on loans minus what it pays on deposits.",
	"ARR": "Annual recurring revenue: yearly subscription or contract income.",
	"RFP": "Request for proposal: a bid for a large contract.",
	"SKU": "Stock keeping unit: one specific product on the shelf.",
	"CIO": "Chief information officer: the IT buyer at a large company.",
	"CIOs": "Chief information officers: IT buyers at large companies.",
}

const CHART := {
	"1M": "Last 20 market minutes. One print per minute — not one month.",
	"5M": "Last 60 market minutes (one hour of the session).",
	"15M": "Last 120 market minutes (two hours of the session).",
	"1H": "Last 180 market minutes (three hours of the session).",
	"1D": "The full session, as far as prices have printed.",
}


static func annotate(text: String) -> String:
	if text.is_empty():
		return text
	var out: String = text
	out = out.replace("Tape", "\u0002")
	out = out.replace("tape", "\u0003")
	out = out.replace("CIOs", "\u0001")
	for term in ["NII", "ARR", "RFP", "SKU", "CIO"]:
		out = out.replace(term, _hint_tag(term, TERMS[term]))
	out = out.replace("\u0001", _hint_tag("CIOs", TERMS["CIOs"]))
	out = out.replace("\u0002", _hint_tag("Tape", TAPE_HINT))
	out = out.replace("\u0003", _hint_tag("tape", TAPE_HINT))
	return out


static func chart_tooltip(timeframe: String) -> String:
	return str(CHART.get(timeframe, "Chart window on this name."))


static func _hint_tag(term: String, hint: String) -> String:
	return "[hint=%s]%s[/hint]" % [hint, term]
