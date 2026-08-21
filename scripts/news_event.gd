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
var reaction: String = ""


func _init(
	p_timestamp: String,
	p_headline: String,
	p_symbols: Array[String],
	p_sentiment: float,
	p_impact: float,
	p_duration: int,
	p_is_major: bool = false,
	p_is_premarket: bool = false,
	p_category: String = "general"
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
