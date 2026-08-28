class_name EventChain
extends RefCounted

const STAGE_ORDER: Array[String] = [
	"announcement",
	"follow_up",
	"reaction",
	"twist",
	"resolution",
]

var arc_id: String = ""
var subject: String = ""
var scope: String = "company"
var industry: String = ""
var polarity: float = 1.0
var fired: Array[String] = []
var skipped: Array[String] = []
var beat_log: Array = []
var pending: String = "announcement"
var due_day: int = 0
var due_tick: int = 0
var prefer_premarket: bool = false
var started_day: int = 0
var log_rev: int = 0
var seen_rev: int = 0


func to_dict() -> Dictionary:
	return {
		"arc_id": arc_id,
		"subject": subject,
		"scope": scope,
		"industry": industry,
		"polarity": polarity,
		"fired": fired.duplicate(),
		"skipped": skipped.duplicate(),
		"beat_log": beat_log.duplicate(true),
		"pending": pending,
		"due_day": due_day,
		"due_tick": due_tick,
		"prefer_premarket": prefer_premarket,
		"started_day": started_day,
		"log_rev": log_rev,
		"seen_rev": seen_rev,
	}


static func from_dict(data: Dictionary) -> EventChain:
	var chain := EventChain.new()
	chain.arc_id = str(data.get("arc_id", ""))
	chain.subject = str(data.get("subject", ""))
	chain.scope = str(data.get("scope", "company"))
	chain.industry = str(data.get("industry", ""))
	chain.polarity = float(data.get("polarity", 1.0))
	chain.pending = str(data.get("pending", ""))
	chain.due_day = int(data.get("due_day", 0))
	chain.due_tick = int(data.get("due_tick", 0))
	chain.prefer_premarket = bool(data.get("prefer_premarket", false))
	chain.started_day = int(data.get("started_day", 0))
	chain.fired = _string_array(data.get("fired", []))
	chain.skipped = _string_array(data.get("skipped", []))
	chain.beat_log = _beat_array(data.get("beat_log", []))
	if data.has("log_rev"):
		chain.log_rev = int(data.get("log_rev", 0))
		chain.seen_rev = int(data.get("seen_rev", 0))
	else:
		chain.log_rev = _headline_count(chain.beat_log)
		chain.seen_rev = chain.log_rev
	return chain


func log_beat(stage: String, headline: String, day: int, time: String) -> void:
	_append_log("fired", stage, headline, day, time)


func log_skip(stage: String, day: int) -> void:
	_append_log("skipped", stage, "", day, "")


func log_tape(headline: String, day: int, time: String) -> void:
	_append_log("tape", "", headline, day, time)


func _append_log(kind: String, stage: String, headline: String, day: int, time: String) -> void:
	if not headline.is_empty():
		for item in beat_log:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = item
			if str(row.get("headline", "")) == headline and int(row.get("day", 0)) == day:
				return
	beat_log.append({
		"kind": kind,
		"stage": stage,
		"headline": headline,
		"day": day,
		"time": time,
	})
	if not headline.is_empty() and kind != "skipped":
		log_rev += 1
	if beat_log.size() > 40:
		beat_log.remove_at(0)


func has_unread() -> bool:
	return log_rev > seen_rev


func mark_seen() -> void:
	seen_rev = log_rev


static func _headline_count(rows: Array) -> int:
	var n := 0
	for item in rows:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = item
		if str(row.get("kind", "")) == "skipped":
			continue
		if not str(row.get("headline", "")).is_empty():
			n += 1
	return n


static func _beat_array(value: Variant) -> Array:
	var out: Array = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for item in value:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = item
		out.append({
			"kind": str(row.get("kind", "fired")),
			"stage": str(row.get("stage", "")),
			"headline": str(row.get("headline", "")),
			"day": int(row.get("day", 0)),
			"time": str(row.get("time", "")),
		})
	return out


static func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for item in value:
		out.append(str(item))
	return out


static func display_stage(stage: String) -> String:
	match stage:
		"announcement":
			return "story"
		"follow_up":
			return "follow-up"
		"reaction":
			return "reaction"
		"twist":
			return "twist"
		"resolution":
			return "resolution"
		_:
			return "story"
