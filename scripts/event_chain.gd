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
var pending: String = "announcement"
var due_day: int = 0
var due_tick: int = 0
var prefer_premarket: bool = false
var started_day: int = 0


func to_dict() -> Dictionary:
	return {
		"arc_id": arc_id,
		"subject": subject,
		"scope": scope,
		"industry": industry,
		"polarity": polarity,
		"fired": fired.duplicate(),
		"skipped": skipped.duplicate(),
		"pending": pending,
		"due_day": due_day,
		"due_tick": due_tick,
		"prefer_premarket": prefer_premarket,
		"started_day": started_day,
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
	return chain


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
