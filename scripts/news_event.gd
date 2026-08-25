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


func effect_label() -> String:
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
