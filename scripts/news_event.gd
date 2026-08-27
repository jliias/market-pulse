class_name NewsEvent
extends RefCounted

var timestamp: String
var headline: String
var affected_symbols: Array[String]
var sentiment: float
var impact: float
var duration_ticks: int
var is_major: bool
var is_premarket: bool = false
var category: String = "general"
var scope: String = "company"
var strength: String = "moderate"
var lasting: bool = false
var industry: String = ""
var chain_id: String = ""
var chain_stage: String = ""
var reaction: String = ""
var existential: bool = false
var skip_act_pause: bool = false
var drama_kind: String = ""
var weather_flip: bool = false


func _init(
	p_timestamp: String,
	p_headline: String,
	p_symbols: Array[String],
	p_sentiment: float,
	p_impact: float,
	p_duration: int,
	p_is_major: bool = false,
	p_is_premarket: bool = false,
	p_category: String = "general",
	p_scope: String = "company",
	p_strength: String = "moderate",
	p_lasting: bool = false,
	p_industry: String = ""
) -> void:
	timestamp = p_timestamp
	headline = p_headline
	affected_symbols = p_symbols
	sentiment = p_sentiment
	impact = p_impact
	duration_ticks = p_duration
	is_major = p_is_major
	is_premarket = p_is_premarket
	category = p_category
	scope = p_scope
	strength = p_strength
	lasting = p_lasting
	industry = p_industry
	chain_id = ""
	chain_stage = ""


func feed_tag() -> String:
	if not drama_kind.is_empty():
		return "YOUR TAPE"
	match scope:
		"market":
			return "MARKET"
		"industry":
			match industry:
				"Technology":
					return "TECH"
				"Energy":
					return "ENERGY"
				"Materials":
					return "MATERIALS"
				"Commodities":
					return "CMTY"
				"Healthcare":
					return "HLTH"
				"Consumer":
					return "CONS"
				"Industrials":
					return "INDU"
				"Financials":
					return "FIN"
				"Growth":
					return "GROWTH"
				_:
					return "SECTOR"
		"company":
			if affected_symbols.size() == 1:
				return affected_symbols[0]
			return "NAMES"
		_:
			return "MARKET"


func attach_chain(p_chain_id: String, p_stage: String) -> void:
	chain_id = p_chain_id
	chain_stage = p_stage


func should_act_pause(watchlist: Array[String] = []) -> bool:
	if skip_act_pause or is_premarket:
		return false
	if existential or weather_flip or not drama_kind.is_empty():
		return true
	if chain_stage == "resolution" and _hits_watchlist(watchlist):
		return true
	if not chain_id.is_empty():
		return false
	if scope != "company":
		return false
	if (is_major or strength == "major") and _hits_watchlist(watchlist):
		return true
	return false


func _hits_watchlist(watchlist: Array[String]) -> bool:
	for symbol in affected_symbols:
		if watchlist.has(str(symbol)):
			return true
	return false


func act_pause_seconds() -> float:
	if existential:
		return 14.0
	return 10.0


func effect_label() -> String:
	if not drama_kind.is_empty():
		return drama_kind
	if existential:
		return "resolution · existential"
	if not chain_stage.is_empty():
		var stage_name: String = EventChain.display_stage(chain_stage)
		var life: String = "lasting" if lasting else "flash"
		return "%s · %s · %s" % [stage_name, strength, life]
	if strength.is_empty() or impact == 0.0:
		return ""
	var life: String = "lasting" if lasting else "flash"
	return "%s · %s" % [strength, life]
