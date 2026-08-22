class_name EventChainDirector
extends RefCounted

const MAX_ACTIVE := 2
const SKIP_CHANCE := {
	"follow_up": 0.24,
	"reaction": 0.34,
	"twist": 0.48,
	"resolution": 0.16,
}

const ARCS := {
	"alph_nexis": {
		"scope": "company",
		"subject": "ALPH",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Alpha Technologies announces the Nexis AI accelerator.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Alpha Technologies delays the Nexis AI accelerator.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: two hyperscalers are said to be testing Nexis.", "category": "product", "strength": "moderate", "lasting": true},
					{"text": "Follow-up: Alpha Technologies raises Nexis qualification commentary.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: Nexis customers are said to be pushing out orders.", "category": "product", "strength": "moderate", "lasting": true},
					{"text": "Follow-up: street cuts Nexis shipment assumptions.", "category": "analyst", "strength": "moderate", "lasting": false},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: momentum desks pile into Alpha Technologies on the Nexis tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: fast money dumps Alpha Technologies after the Nexis headlines.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: Nexis yields come in better than the company billed.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: Nexis yields look worse than billed — street second-guesses the launch.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Alpha Technologies confirms Nexis is shipping in volume.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Alpha Technologies shelves the first Nexis production wave.", "category": "product", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"grne_subsidy": {
		"scope": "company",
		"subject": "GRNE",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Green Energy Corp says a new subsidy bill is moving in committee.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Green Energy Corp warns a key subsidy bill may be pulled.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: whip count improves for the Green Energy Corp subsidy language.", "category": "regulatory", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: the subsidy text for Green Energy Corp is being watered down.", "category": "regulatory", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: speculative flow chases Green Energy Corp on the policy tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Green Energy Corp gets sold as traders fade the policy rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a last-minute amendment restores the Green Energy Corp subsidy.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: the committee shelves the Green Energy Corp subsidy overnight.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the subsidy bill clears — Green Energy Corp keeps the support.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the subsidy effort dies — Green Energy Corp loses the support.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"nmin_pit": {
		"scope": "company",
		"subject": "NMIN",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "North Mining Ltd reports a high-grade intercept at the north pit.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "North Mining Ltd reports a disruption at the north pit.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: North Mining Ltd lifts the pit's near-term output range.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: North Mining Ltd trims pit shipments while it investigates.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: miners bid North Mining Ltd as the pit story spreads.", "category": "commodity", "strength": "minor", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: North Mining Ltd slips as desks fade the pit headline.", "category": "commodity", "strength": "minor", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: the north pit comes back faster than North Mining Ltd guided.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: the north pit issue is wider than first reported.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: North Mining Ltd restores full pit operations and holds guidance.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: North Mining Ltd cuts full-year output after the pit setback.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"growth_rotation": {
		"scope": "industry",
		"subject": "GROWTH",
		"industry": "Growth",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Desks call a growth rotation: duration and speculative names are back in favor.", "category": "macro", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Desks warn a growth unwind is starting across high-duration names.", "category": "macro", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: growth-factor flows stay bid into the session.", "category": "macro", "strength": "minor", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: growth-factor selling persists as positioning stays crowded.", "category": "macro", "strength": "minor", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: growth names on the board catch the bid.", "category": "macro", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: growth names on the board are offered as duration gets cut.", "category": "macro", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a soft data print supercharges the growth bid.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a hot data print torches the growth trade.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the growth rotation holds — desks stay long duration.", "category": "macro", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the growth unwind is done — desks call the factor reset complete.", "category": "macro", "strength": "moderate", "lasting": true},
				],
			},
		},
	},
	"helx_trial": {
		"scope": "company",
		"subject": "HELX",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Helix Biotech says a pivotal readout is coming in range.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Helix Biotech says a pivotal readout may slip.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: investigators sound constructive on the Helix Biotech cohort.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: enrollment at Helix Biotech looks slower than billed.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: biotech flow chases Helix Biotech on the trial tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Helix Biotech is offered as desks fade the trial rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a subgroup look at Helix Biotech comes in cleaner than feared.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a safety flag at Helix Biotech is wider than first billed.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Helix Biotech confirms the trial met the primary endpoint.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Helix Biotech says the trial missed and the timeline is under review.", "category": "product", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"cybr_contract": {
		"scope": "company",
		"subject": "CYBR",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "CyberNest Inc says it is in late talks on a large security award.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "CyberNest Inc warns a large security award may slip.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: CyberNest Inc commentary on the award stays constructive.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: the CyberNest Inc award looks more competitive than billed.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: speculative flow chases CyberNest Inc on the contract tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: CyberNest Inc is sold as traders fade the award rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: CyberNest Inc is said to have the inside track after a bake-off.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a protest is said to be hanging over the CyberNest Inc award.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: CyberNest Inc confirms the multi-year security award.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: CyberNest Inc loses the award — the rumor dies.", "category": "product", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"qbit_demo": {
		"scope": "company",
		"subject": "QBIT",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Qubit Labs teases a public quantum demo this month.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Qubit Labs warns the public quantum demo may slip.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Qubit Labs says lab metrics are tracking ahead of the demo.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: Qubit Labs trims demo commentary as calibration slips.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: hot money piles into Qubit Labs on the demo tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Qubit Labs is offered as traders fade the demo rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a partner lab corroborates the Qubit Labs metrics.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a rival notes holes in the Qubit Labs demo claims.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Qubit Labs completes the demo and holds the narrative.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Qubit Labs postpones the demo — the squeeze unwinds.", "category": "product", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"hawkish_tape": {
		"scope": "market",
		"subject": "MARKET",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Leak: policymakers are more open to an easier stance than the street priced.", "category": "macro", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Leak: policymakers may stay tighter for longer than the street priced.", "category": "macro", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: overnight commentary stays dovish versus the leak.", "category": "macro", "strength": "minor", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: overnight commentary stays hawkish versus the leak.", "category": "macro", "strength": "minor", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: risk appetite returns across the tape.", "category": "macro", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: risk-off hits every name after the policy leak.", "category": "macro", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: an official walk-back sounds easier than the original leak.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: an official walk-back sounds tighter than the original leak.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the official print lands dovish — the easier-policy story holds.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the official print lands hawkish — the tighter-policy story holds.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
		},
	},
}

var active: Array[EventChain] = []
var cooldowns: Dictionary = {}
var calendar_day: int = 0
var news_generator: NewsGenerator


var last_tick: int = 0


func _init(p_generator: NewsGenerator) -> void:
	news_generator = p_generator


func reset() -> void:
	active.clear()
	cooldowns.clear()
	calendar_day = 0
	last_tick = 0


func serialize() -> Dictionary:
	var chains: Array = []
	for chain in active:
		chains.append(chain.to_dict())
	return {
		"active": chains,
		"cooldowns": cooldowns.duplicate(),
	}


func deserialize(data: Dictionary) -> void:
	active.clear()
	cooldowns.clear()
	var saved_chains: Variant = data.get("active", [])
	if typeof(saved_chains) == TYPE_ARRAY:
		for item in saved_chains:
			if typeof(item) == TYPE_DICTIONARY:
				var chain: EventChain = EventChain.from_dict(item)
				if ARCS.has(chain.arc_id) and not chain.pending.is_empty():
					active.append(chain)
	var saved_cd: Variant = data.get("cooldowns", {})
	if typeof(saved_cd) == TYPE_DICTIONARY:
		for key in saved_cd:
			cooldowns[str(key)] = int(saved_cd[key])


func occupied_subjects() -> Array[String]:
	var names: Array[String] = []
	for chain in active:
		names.append(chain.subject)
	return names


func collect_premarket(stocks: Array[Stock], session_time: String) -> Array[NewsEvent]:
	last_tick = 0
	_prune_cooldowns()
	var events: Array[NewsEvent] = []
	var due: Array[EventChain] = []
	for chain in active:
		if _is_due_premarket(chain):
			due.append(chain)
	for chain in due:
		var event: NewsEvent = _fire(chain, stocks, session_time, true)
		if event != null:
			events.append(event)
		if events.size() >= 2:
			break
	if events.is_empty() and active.size() < MAX_ACTIVE and randf() < 0.16:
		var started: NewsEvent = try_start(stocks, session_time, true)
		if started != null:
			events.append(started)
	return events


func try_fire_due(stocks: Array[Stock], session_time: String, tick_count: int) -> NewsEvent:
	last_tick = tick_count
	_prune_cooldowns()
	var overdue: EventChain = _pick_due_intraday(tick_count)
	if overdue == null:
		return null
	var wait: int = tick_count - overdue.due_tick
	if wait >= 80 or randf() < 0.035:
		return _fire(overdue, stocks, session_time, false)
	return null


func try_intraday(stocks: Array[Stock], session_time: String, tick_count: int) -> NewsEvent:
	return try_fire_due(stocks, session_time, tick_count)


func try_start(stocks: Array[Stock], session_time: String, premarket: bool) -> NewsEvent:
	var arc_id: String = _pick_available_arc(stocks)
	if arc_id.is_empty():
		return null
	var spec: Dictionary = ARCS[arc_id]
	var chain := EventChain.new()
	chain.arc_id = arc_id
	chain.subject = str(spec["subject"])
	chain.scope = str(spec["scope"])
	chain.industry = str(spec["industry"])
	chain.polarity = 1.0 if randf() > 0.46 else -1.0
	chain.pending = "announcement"
	chain.started_day = calendar_day
	chain.due_day = calendar_day
	chain.due_tick = 0
	chain.prefer_premarket = premarket
	active.append(chain)
	return _fire(chain, stocks, session_time, premarket)


func on_session_end() -> void:
	var still_active: Array[EventChain] = []
	for chain in active:
		if chain.pending.is_empty():
			_start_cooldown(chain.arc_id)
			continue
		if chain.due_day <= calendar_day:
			chain.due_day = calendar_day + 1
			chain.prefer_premarket = randf() < 0.55
			chain.due_tick = 0 if chain.prefer_premarket else randi_range(18, 200)
		if calendar_day - chain.started_day >= 10 and chain.pending != "resolution":
			chain.pending = "resolution"
			chain.due_day = calendar_day + 1
			chain.prefer_premarket = true
			chain.due_tick = 0
		if calendar_day - chain.started_day >= 16:
			_start_cooldown(chain.arc_id)
			continue
		still_active.append(chain)
	active = still_active


func _is_due_premarket(chain: EventChain) -> bool:
	if chain.pending.is_empty() or chain.due_day != calendar_day:
		return false
	return chain.prefer_premarket or chain.due_tick <= 0


func _pick_due_intraday(tick_count: int) -> EventChain:
	for chain in active:
		if chain.pending.is_empty():
			continue
		if chain.due_day != calendar_day:
			continue
		if chain.prefer_premarket and tick_count < 40:
			continue
		if tick_count >= chain.due_tick:
			return chain
	return null


func _fire(chain: EventChain, stocks: Array[Stock], session_time: String, premarket: bool) -> NewsEvent:
	var stage: String = chain.pending
	if stage.is_empty() or not ARCS.has(chain.arc_id):
		return null
	var positive: bool = chain.polarity > 0.0
	if stage == "twist":
		if randf() < 0.72:
			positive = not positive
			chain.polarity = 1.0 if positive else -1.0
	var item: Dictionary = _stage_item(chain.arc_id, stage, positive)
	if item.is_empty():
		_advance(chain, stage)
		return null
	var symbols: Array[String] = _symbols_for_chain(chain, stocks)
	var event: NewsEvent = news_generator.make_from_item(
		item, session_time, symbols, positive, premarket, chain.scope, chain.industry
	)
	var headline: String = str(item["text"])
	if premarket and not headline.begins_with("PREMARKET"):
		headline = "PREMARKET: " + headline
	event.headline = headline
	event.attach_chain(chain.arc_id, stage)
	_advance(chain, stage)
	return event


func _advance(chain: EventChain, fired_stage: String) -> void:
	if not chain.fired.has(fired_stage):
		chain.fired.append(fired_stage)
	var next_stage: String = _choose_next(fired_stage, chain)
	if next_stage.is_empty():
		chain.pending = ""
		_start_cooldown(chain.arc_id)
		active.erase(chain)
		return
	chain.pending = next_stage
	_schedule(chain, fired_stage)


func _choose_next(from_stage: String, chain: EventChain) -> String:
	var start: int = EventChain.STAGE_ORDER.find(from_stage) + 1
	if start <= 0:
		start = 1
	var chosen: String = ""
	for i in range(start, EventChain.STAGE_ORDER.size()):
		var stage: String = EventChain.STAGE_ORDER[i]
		var chance: float = float(SKIP_CHANCE.get(stage, 0.0))
		if randf() < chance:
			if not chain.skipped.has(stage):
				chain.skipped.append(stage)
			continue
		chosen = stage
		break
	if chosen.is_empty() and from_stage != "resolution" and randf() < 0.55:
		return "resolution"
	return chosen


func _schedule(chain: EventChain, from_stage: String) -> void:
	var same_day_chance: float = 0.42
	match from_stage:
		"announcement":
			same_day_chance = 0.46
		"follow_up":
			same_day_chance = 0.5
		"reaction":
			same_day_chance = 0.55
		"twist":
			same_day_chance = 0.28
	var ticks_left: bool = last_tick < 300
	if randf() < same_day_chance and ticks_left:
		chain.due_day = calendar_day
		chain.prefer_premarket = false
		chain.due_tick = last_tick + randi_range(18, 70)
	else:
		chain.due_day = calendar_day + randi_range(1, 5)
		chain.prefer_premarket = randf() < 0.62
		chain.due_tick = 0 if chain.prefer_premarket else randi_range(20, 180)


func prune_to_universe(watchlist: Array[String], stocks: Array[Stock]) -> void:
	var keep: Array[EventChain] = []
	for chain in active:
		if not ARCS.has(chain.arc_id):
			continue
		if not _arc_allowed(ARCS[chain.arc_id], watchlist, stocks):
			continue
		keep.append(chain)
	active = keep


func _pick_available_arc(stocks: Array[Stock]) -> String:
	var taken: Array[String] = occupied_subjects()
	var watchlist: Array[String] = []
	for stock in stocks:
		watchlist.append(stock.symbol)
	var options: Array[String] = []
	for arc_id in ARCS.keys():
		var spec: Dictionary = ARCS[arc_id]
		var subject: String = str(spec["subject"])
		if taken.has(subject):
			continue
		if int(cooldowns.get(arc_id, -99)) > calendar_day:
			continue
		if not _arc_allowed(spec, watchlist, stocks):
			continue
		options.append(str(arc_id))
	if options.is_empty():
		return ""
	return options[randi() % options.size()]


func _arc_allowed(spec: Dictionary, watchlist: Array[String], stocks: Array[Stock]) -> bool:
	var scope: String = str(spec.get("scope", ""))
	if scope == "company":
		return watchlist.has(str(spec.get("subject", "")))
	if scope == "industry":
		return not news_generator.symbols_for_industry(stocks, str(spec.get("industry", ""))).is_empty()
	return true


func _stage_item(arc_id: String, stage: String, positive: bool) -> Dictionary:
	var spec: Dictionary = ARCS[arc_id]
	var stages: Dictionary = spec["stages"]
	if not stages.has(stage):
		return {}
	var sides: Dictionary = stages[stage]
	var key: String = "positive" if positive else "negative"
	var items: Array = sides[key]
	var picked: Variant = items[randi() % items.size()]
	if typeof(picked) == TYPE_DICTIONARY:
		return picked
	return {}


func _symbols_for_chain(chain: EventChain, stocks: Array[Stock]) -> Array[String]:
	match chain.scope:
		"market":
			var all_names: Array[String] = []
			for stock in stocks:
				all_names.append(stock.symbol)
			return all_names
		"industry":
			return news_generator.symbols_for_industry(stocks, chain.industry)
		_:
			return [chain.subject]


func _start_cooldown(arc_id: String) -> void:
	cooldowns[arc_id] = calendar_day + randi_range(5, 12)


func _prune_cooldowns() -> void:
	var drop: Array[String] = []
	for arc_id in cooldowns.keys():
		if int(cooldowns[arc_id]) <= calendar_day:
			drop.append(str(arc_id))
	for arc_id in drop:
		cooldowns.erase(arc_id)
