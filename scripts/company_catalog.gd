class_name CompanyCatalog
extends RefCounted

const NEWS_GROWTH := {
	"product": 1.45, "earnings": 1.25, "analyst": 1.15, "rumor": 0.65,
	"macro": 0.85, "commodity": 0.35, "regulatory": 0.90, "industry": 1.15, "general": 1.0,
}
const NEWS_SPEC := {
	"rumor": 1.70, "regulatory": 1.55, "analyst": 1.25, "earnings": 0.62,
	"product": 1.05, "macro": 1.20, "commodity": 0.50, "industry": 1.20, "general": 1.10,
}
const NEWS_STABLE := {
	"commodity": 1.20, "earnings": 1.20, "rumor": 0.28, "product": 0.50,
	"analyst": 0.70, "macro": 0.75, "regulatory": 0.85, "industry": 0.80, "general": 0.85,
}

const ALL := {
	"ALPH": {
		"name": "Alpha Technologies", "price": 187.45, "sector": "Technology", "cap": "Large Cap",
		"label": "Growth", "volatility": 1.22, "growth": 0.88, "liquidity": 0.72, "popularity": 0.85,
		"institutional_ownership": 0.55, "speculation_factor": 0.45, "trend_flip": 0.010,
		"industries": ["Technology", "Growth"], "news": NEWS_GROWTH,
	},
	"GRNE": {
		"name": "Green Energy Corp", "price": 34.20, "sector": "Energy", "cap": "Mid Cap",
		"label": "Speculative", "volatility": 1.38, "growth": 0.58, "liquidity": 0.42, "popularity": 0.70,
		"institutional_ownership": 0.28, "speculation_factor": 0.92, "trend_flip": 0.024,
		"industries": ["Energy", "Growth", "Commodities"], "news": NEWS_SPEC,
	},
	"NMIN": {
		"name": "North Mining Ltd", "price": 512.80, "sector": "Materials", "cap": "Large Cap",
		"label": "Stable", "volatility": 0.62, "growth": 0.42, "liquidity": 0.88, "popularity": 0.50,
		"institutional_ownership": 0.78, "speculation_factor": 0.22, "trend_flip": 0.006,
		"industries": ["Materials", "Commodities"], "news": NEWS_STABLE,
	},
	"HELX": {
		"name": "Helix Biotech", "price": 62.40, "sector": "Healthcare", "cap": "Mid Cap",
		"label": "Growth", "volatility": 1.28, "growth": 0.82, "liquidity": 0.58, "popularity": 0.68,
		"institutional_ownership": 0.42, "speculation_factor": 0.58, "trend_flip": 0.014,
		"industries": ["Healthcare", "Growth"], "news": NEWS_GROWTH,
	},
	"RETL": {
		"name": "Redline Retail", "price": 88.15, "sector": "Consumer", "cap": "Large Cap",
		"label": "Stable", "volatility": 0.72, "growth": 0.48, "liquidity": 0.84, "popularity": 0.62,
		"institutional_ownership": 0.70, "speculation_factor": 0.28, "trend_flip": 0.007,
		"industries": ["Consumer"], "news": NEWS_STABLE,
	},
	"CYBR": {
		"name": "CyberNest Inc", "price": 41.90, "sector": "Technology", "cap": "Mid Cap",
		"label": "Speculative", "volatility": 1.42, "growth": 0.74, "liquidity": 0.48, "popularity": 0.72,
		"institutional_ownership": 0.32, "speculation_factor": 0.88, "trend_flip": 0.022,
		"industries": ["Technology", "Growth"], "news": NEWS_SPEC,
	},
	"AERO": {
		"name": "Aether Aerospace", "price": 156.30, "sector": "Industrials", "cap": "Large Cap",
		"label": "Growth", "volatility": 1.12, "growth": 0.78, "liquidity": 0.66, "popularity": 0.60,
		"institutional_ownership": 0.52, "speculation_factor": 0.42, "trend_flip": 0.011,
		"industries": ["Industrials", "Growth"], "news": NEWS_GROWTH,
	},
	"BANK": {
		"name": "Bastion Bank", "price": 73.55, "sector": "Financials", "cap": "Large Cap",
		"label": "Stable", "volatility": 0.68, "growth": 0.44, "liquidity": 0.90, "popularity": 0.58,
		"institutional_ownership": 0.80, "speculation_factor": 0.20, "trend_flip": 0.006,
		"industries": ["Financials"], "news": NEWS_STABLE,
	},
	"FOOD": {
		"name": "Harbor Foods", "price": 29.80, "sector": "Consumer", "cap": "Mid Cap",
		"label": "Stable", "volatility": 0.70, "growth": 0.46, "liquidity": 0.80, "popularity": 0.55,
		"institutional_ownership": 0.64, "speculation_factor": 0.30, "trend_flip": 0.008,
		"industries": ["Consumer"], "news": NEWS_STABLE,
	},
	"QBIT": {
		"name": "Qubit Labs", "price": 18.65, "sector": "Technology", "cap": "Small Cap",
		"label": "Speculative", "volatility": 1.50, "growth": 0.90, "liquidity": 0.36, "popularity": 0.64,
		"institutional_ownership": 0.22, "speculation_factor": 0.95, "trend_flip": 0.026,
		"industries": ["Technology", "Growth"], "news": NEWS_SPEC,
	},
}

const ORDER: Array[String] = ["ALPH", "GRNE", "NMIN", "HELX", "RETL", "CYBR", "AERO", "BANK", "FOOD", "QBIT"]
const DEFAULT_WATCHLIST: Array[String] = ["ALPH", "GRNE", "NMIN"]
const ALIASES := {
	"ALPH": "ALPH", "ALPHA": "ALPH",
	"GRNE": "GRNE", "GREEN": "GRNE",
	"NMIN": "NMIN", "NORTH": "NMIN", "MINING": "NMIN",
	"HELX": "HELX", "HELIX": "HELX",
	"RETL": "RETL", "REDLINE": "RETL", "RETAIL": "RETL",
	"CYBR": "CYBR", "CYBER": "CYBR", "CYBERNEST": "CYBR",
	"AERO": "AERO", "AETHER": "AERO",
	"BANK": "BANK", "BASTION": "BANK",
	"FOOD": "FOOD", "HARBOR": "FOOD",
	"QBIT": "QBIT", "QUBIT": "QBIT",
}


static func resolve_alias(input: String) -> String:
	return str(ALIASES.get(input.to_upper(), ""))


static func has_symbol(symbol: String) -> bool:
	return ALL.has(symbol)


static func spec(symbol: String) -> Dictionary:
	if ALL.has(symbol):
		return ALL[symbol]
	return {}


static func display_name(symbol: String) -> String:
	var data: Dictionary = spec(symbol)
	return str(data.get("name", symbol))


static func make_stock(symbol: String) -> Stock:
	var data: Dictionary = spec(symbol)
	return Stock.new(
		symbol,
		str(data.get("name", symbol)),
		float(data.get("price", 50.0)),
		float(data.get("volatility", 1.0)),
		str(data.get("sector", "")),
		str(data.get("cap", ""))
	)


static func sanitize_watchlist(symbols: Array) -> Array[String]:
	var out: Array[String] = []
	for item in symbols:
		var symbol: String = str(item)
		if has_symbol(symbol) and not out.has(symbol):
			out.append(symbol)
		if out.size() == 3:
			break
	if out.size() != 3:
		return DEFAULT_WATCHLIST.duplicate()
	return out
