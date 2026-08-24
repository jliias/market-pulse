class_name MarketRegime
extends RefCounted

const CLIMATE_NORMAL := "normal"
const CLIMATE_BULL := "bull"
const CLIMATE_BEAR := "bear"

const WEATHER_NONE := ""
const WEATHER_PANIC := "panic"
const WEATHER_EUPHORIA := "euphoria"
const WEATHER_HIGH_VOL := "high_vol"

var climate: String = CLIMATE_NORMAL
var climate_days: int = 0
var weather: String = WEATHER_NONE
var weather_ticks: int = 0
var announce_climate: bool = false
var panic_ticks_today: int = 0
var euphoria_ticks_today: int = 0
var high_vol_ticks_today: int = 0


func reset() -> void:
	climate = CLIMATE_NORMAL
	climate_days = 0
	weather = WEATHER_NONE
	weather_ticks = 0
	announce_climate = false
	panic_ticks_today = 0
	euphoria_ticks_today = 0
	high_vol_ticks_today = 0


func serialize() -> Dictionary:
	return {
		"climate": climate,
		"climate_days": climate_days,
	}


func deserialize(data: Dictionary) -> void:
	climate = str(data.get("climate", CLIMATE_NORMAL))
	if climate != CLIMATE_BULL and climate != CLIMATE_BEAR:
		climate = CLIMATE_NORMAL
	climate_days = int(data.get("climate_days", 0))
	weather = WEATHER_NONE
	weather_ticks = 0
	announce_climate = climate != CLIMATE_NORMAL
	panic_ticks_today = 0
	euphoria_ticks_today = 0
	high_vol_ticks_today = 0


func opening_sentiment() -> float:
	match climate:
		CLIMATE_BULL:
			return randf_range(0.22, 0.52)
		CLIMATE_BEAR:
			return randf_range(-0.52, -0.22)
		_:
			return randf_range(-0.14, 0.14)


func news_roll_chance() -> float:
	if weather == WEATHER_PANIC or weather == WEATHER_HIGH_VOL:
		return 0.08
	if weather == WEATHER_EUPHORIA:
		return 0.07
	if climate != CLIMATE_NORMAL:
		return 0.062
	return 0.055


func tick_modifiers() -> Dictionary:
	var drift: float = 0.0
	var vol_mult: float = 1.0
	var flip_mult: float = 1.0
	var volume_mult: float = 1.0
	match climate:
		CLIMATE_BULL:
			drift += 0.000045
			vol_mult *= 1.08
			volume_mult *= 1.08
		CLIMATE_BEAR:
			drift -= 0.000045
			vol_mult *= 1.12
			flip_mult *= 1.15
			volume_mult *= 1.05
	match weather:
		WEATHER_PANIC:
			drift -= 0.00009
			vol_mult *= 1.55
			flip_mult *= 1.8
			volume_mult *= 1.45
		WEATHER_EUPHORIA:
			drift += 0.00009
			vol_mult *= 1.4
			flip_mult *= 1.35
			volume_mult *= 1.4
		WEATHER_HIGH_VOL:
			vol_mult *= 1.7
			flip_mult *= 2.2
			volume_mult *= 1.35
	return {
		"drift": drift,
		"vol_mult": vol_mult,
		"flip_mult": flip_mult,
		"volume_mult": volume_mult,
	}


func tick() -> void:
	if weather_ticks > 0:
		weather_ticks -= 1
		match weather:
			WEATHER_PANIC:
				panic_ticks_today += 1
			WEATHER_EUPHORIA:
				euphoria_ticks_today += 1
			WEATHER_HIGH_VOL:
				high_vol_ticks_today += 1
		if weather_ticks <= 0:
			weather = WEATHER_NONE


func consider_event(event: NewsEvent) -> String:
	if event == null or event.scope == "system" or event.impact == 0.0:
		return ""
	var sign: float = signf(event.sentiment)
	if sign == 0.0:
		sign = signf(event.impact)
	var major: bool = event.is_major or event.strength == "major"
	var broad: bool = event.scope == "market" or event.scope == "industry"
	var twist: bool = event.chain_stage == "twist" or event.chain_stage == "resolution"
	var started: String = ""

	if major and sign < 0.0 and (broad or twist):
		var panic_odds: float = 0.5 if event.scope == "market" else 0.28
		if twist:
			panic_odds += 0.18
		if randf() < panic_odds:
			started = _set_weather(WEATHER_PANIC, randi_range(32, 85))
	elif major and sign > 0.0 and (broad or twist):
		var euphoria_odds: float = 0.48 if event.scope == "market" else 0.26
		if twist:
			euphoria_odds += 0.16
		if randf() < euphoria_odds:
			started = _set_weather(WEATHER_EUPHORIA, randi_range(28, 75))

	if started.is_empty() and major and randf() < (0.34 if broad else 0.12):
		started = _set_weather(WEATHER_HIGH_VOL, randi_range(22, 58))
	elif started.is_empty() and twist and randf() < 0.22:
		started = _set_weather(WEATHER_HIGH_VOL, randi_range(18, 40))

	if event.chain_stage == "resolution" and event.scope == "market" and event.lasting:
		if sign > 0.0 and randf() < 0.4:
			_set_climate(CLIMATE_BULL, randi_range(3, 9))
		elif sign < 0.0 and randf() < 0.4:
			_set_climate(CLIMATE_BEAR, randi_range(3, 9))

	return started


func on_day_close() -> void:
	if climate_days > 0:
		climate_days -= 1
	if climate != CLIMATE_NORMAL and climate_days <= 0:
		_set_climate(CLIMATE_NORMAL, 0)

	if panic_ticks_today >= 48:
		if climate == CLIMATE_BULL:
			_set_climate(CLIMATE_NORMAL, 0)
		elif climate == CLIMATE_NORMAL and randf() < 0.42:
			_set_climate(CLIMATE_BEAR, randi_range(3, 8))
		elif climate == CLIMATE_BEAR:
			climate_days = maxi(climate_days, randi_range(2, 5))
	elif euphoria_ticks_today >= 48:
		if climate == CLIMATE_BEAR:
			_set_climate(CLIMATE_NORMAL, 0)
		elif climate == CLIMATE_NORMAL and randf() < 0.42:
			_set_climate(CLIMATE_BULL, randi_range(3, 8))
		elif climate == CLIMATE_BULL:
			climate_days = maxi(climate_days, randi_range(2, 5))
	elif climate == CLIMATE_NORMAL and randf() < 0.07:
		if randf() < 0.5:
			_set_climate(CLIMATE_BULL, randi_range(4, 10))
		else:
			_set_climate(CLIMATE_BEAR, randi_range(4, 10))
	elif climate != CLIMATE_NORMAL and randf() < 0.1:
		_set_climate(CLIMATE_NORMAL, 0)

	weather = WEATHER_NONE
	weather_ticks = 0
	panic_ticks_today = 0
	euphoria_ticks_today = 0
	high_vol_ticks_today = 0


func drift_while_away() -> void:
	if climate_days > 0:
		climate_days -= 1
	if climate != CLIMATE_NORMAL and climate_days <= 0:
		_set_climate(CLIMATE_NORMAL, 0)
	elif climate == CLIMATE_NORMAL and randf() < 0.18:
		if randf() < 0.5:
			_set_climate(CLIMATE_BULL, randi_range(3, 9))
		else:
			_set_climate(CLIMATE_BEAR, randi_range(3, 9))
	elif climate != CLIMATE_NORMAL and randf() < 0.16:
		_set_climate(CLIMATE_NORMAL, 0)
	elif climate != CLIMATE_NORMAL and randf() < 0.22:
		climate_days = maxi(climate_days, randi_range(2, 6))
	weather = WEATHER_NONE
	weather_ticks = 0
	panic_ticks_today = 0
	euphoria_ticks_today = 0
	high_vol_ticks_today = 0


func take_climate_headline() -> String:
	if not announce_climate:
		return ""
	announce_climate = false
	match climate:
		CLIMATE_BULL:
			return "PREMARKET: desks call a bull market — bid the dips."
		CLIMATE_BEAR:
			return "PREMARKET: desks call a bear tape — rallies may fail."
		_:
			return "PREMARKET: the tape looks more balanced again."


func status_text() -> String:
	var climate_label: String
	match climate:
		CLIMATE_BULL:
			climate_label = "BULL MARKET"
		CLIMATE_BEAR:
			climate_label = "BEAR MARKET"
		_:
			climate_label = "NORMAL"
	match weather:
		WEATHER_PANIC:
			return "%s · PANIC" % climate_label
		WEATHER_EUPHORIA:
			return "%s · EUPHORIA" % climate_label
		WEATHER_HIGH_VOL:
			return "%s · HIGH VOL" % climate_label
		_:
			return climate_label


func status_tooltip() -> String:
	var lines: PackedStringArray = []
	match climate:
		CLIMATE_BULL:
			lines.append("Bull market: the lasting tilt is up. Dips are more likely to get bought.")
		CLIMATE_BEAR:
			lines.append("Bear market: the lasting tilt is down. Rallies are more likely to fail.")
		_:
			lines.append("Normal: no lasting bull or bear tilt. The session can still swing.")
	if climate != CLIMATE_NORMAL and climate_days > 0:
		lines.append("This tilt is set to last about %d more trading day(s)." % climate_days)
	match weather:
		WEATHER_PANIC:
			lines.append("Panic: short-lived selling weather. Fast, messy drops on top of the climate.")
		WEATHER_EUPHORIA:
			lines.append("Euphoria: short-lived buying weather. Fast, messy rips on top of the climate.")
		WEATHER_HIGH_VOL:
			lines.append("High vol: ranges are stretched. Both sides can print hard.")
	if climate == CLIMATE_BEAR and weather == WEATHER_EUPHORIA:
		lines.append("Together: a bounce inside a bear market. It can feel like a new uptrend and still roll over.")
	elif climate == CLIMATE_BULL and weather == WEATHER_PANIC:
		lines.append("Together: a dump inside a bull market. Ugly, but dips may still get bought.")
	elif climate == CLIMATE_BEAR and weather == WEATHER_PANIC:
		lines.append("Together: selling feeding on itself. Hard to fade until it cools.")
	elif climate == CLIMATE_BULL and weather == WEATHER_EUPHORIA:
		lines.append("Together: a chase. Easy to overpay if you buy the rip.")
	elif weather == WEATHER_HIGH_VOL and climate != CLIMATE_NORMAL:
		lines.append("Together: the lasting tilt is still in force, but the path is noisy.")
	return "\n".join(lines)


func status_color() -> Color:
	if weather == WEATHER_PANIC:
		return Color(0.95, 0.38, 0.38)
	if weather == WEATHER_EUPHORIA:
		return Color(0.35, 0.85, 0.45)
	if weather == WEATHER_HIGH_VOL:
		return Color(0.95, 0.78, 0.28)
	match climate:
		CLIMATE_BULL:
			return Color(0.45, 0.82, 0.52)
		CLIMATE_BEAR:
			return Color(0.9, 0.48, 0.42)
		_:
			return Color(0.78, 0.82, 0.88)


func _set_weather(kind: String, ticks: int) -> String:
	if weather == kind and weather_ticks > 12:
		weather_ticks = maxi(weather_ticks, ticks)
		return ""
	weather = kind
	weather_ticks = ticks
	return kind


func _set_climate(kind: String, days: int) -> void:
	if climate == kind and kind != CLIMATE_NORMAL:
		climate_days = maxi(climate_days, days)
		return
	if climate == kind:
		return
	climate = kind
	climate_days = days
	announce_climate = true
