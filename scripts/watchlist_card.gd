class_name WatchlistCard
extends PanelContainer

signal selected(symbol: String)

var symbol: String = ""
var _selected: bool = false
var _fading: bool = false
var _pulse_tween: Tween

@onready var ticker_label: Label = %TickerLabel
@onready var risk_label: Label = %RiskLabel
@onready var price_label: Label = %PriceLabel
@onready var tick_arrow_label: Label = %TickArrowLabel
@onready var change_label: Label = %ChangeLabel
@onready var owned_label: Label = %OwnedLabel
@onready var pl_label: Label = %PlLabel
@onready var highlight: ColorRect = %Highlight
@onready var select_bar: ColorRect = %SelectBar


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_style()


func set_selected(on: bool) -> void:
	_selected = on
	highlight.visible = on
	select_bar.color = Color(0.9, 0.75, 0.25, 1.0) if on else Color(0.9, 0.75, 0.25, 0.0)
	_apply_style()


func refresh(stock: Stock, owned_shares: int = 0, fade_shares: int = 0, fade_entry: float = 0.0, avg_cost: float = 0.0) -> void:
	symbol = stock.symbol
	ticker_label.text = stock.symbol
	if stock.is_halted():
		risk_label.text = "HALT"
		risk_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
		CopyHints.hover(risk_label, stock.halt_tooltip())
	elif stock.is_distressed():
		risk_label.text = "DST"
		risk_label.add_theme_color_override("font_color", Color(0.95, 0.38, 0.38))
		CopyHints.hover(risk_label, CopyHints.HUD_DISTRESSED)
	else:
		match stock.risk_key:
			"safe":
				risk_label.text = "SAFE"
			"volatile":
				risk_label.text = "VOL"
			_:
				risk_label.text = "GRW"
		risk_label.add_theme_color_override("font_color", CompanyCatalog.risk_color(stock.risk_key))
		risk_label.tooltip_text = ""
	price_label.text = "$%.2f" % stock.price
	_refresh_tick_arrow(stock.last_tick_delta)
	var pct: float = stock.get_day_change_pct()
	var sign := "+" if pct >= 0.0 else "-"
	change_label.text = "%s%.2f%%" % [sign, absf(pct)]
	change_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45) if pct >= 0.0 else Color(0.95, 0.38, 0.38))
	stock.sync_session_range()
	_fading = fade_shares > 0
	if _fading:
		var fade_pl: float = (fade_entry - stock.price) * float(fade_shares)
		owned_label.text = "S%d" % fade_shares
		owned_label.add_theme_color_override("font_color", Color(0.78, 0.62, 0.98))
		_set_pl(fade_pl)
		CopyHints.hover(owned_label, CopyHints.HUD_SHORT)
		CopyHints.hover(pl_label, "SHORT %d  %s$%.2f\n%s" % [
			fade_shares, "+" if fade_pl >= 0.0 else "-", absf(fade_pl), CopyHints.HUD_SHORT
		])
	elif owned_shares > 0:
		var pos_pl: float = (stock.price - avg_cost) * float(owned_shares)
		owned_label.text = "L%d" % owned_shares
		owned_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 1))
		_set_pl(pos_pl)
		CopyHints.hover(owned_label, CopyHints.HUD_LONG)
		CopyHints.hover(pl_label, "LONG %d  %s$%.2f\n%s" % [
			owned_shares, "+" if pos_pl >= 0.0 else "-", absf(pos_pl), CopyHints.HUD_LONG
		])
	else:
		owned_label.text = ""
		owned_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.74, 1))
		owned_label.tooltip_text = ""
		pl_label.text = ""
		pl_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.74, 1))
		pl_label.tooltip_text = ""
	CopyHints.hover(ticker_label, "%s\n%s  ·  %s\nL $%.2f  H $%.2f" % [
		stock.company_name,
		stock.sector,
		str(CompanyCatalog.risk_profile(stock.symbol).get("typical", "")),
		stock.day_low,
		stock.day_high,
	])
	_apply_style()


func _set_pl(amount: float) -> void:
	pl_label.text = "%s$%.2f" % ["+" if amount >= 0.0 else "-", absf(amount)]
	pl_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45) if amount >= 0.0 else Color(0.95, 0.38, 0.38))


func _refresh_tick_arrow(delta: float) -> void:
	if delta > 0.0000005:
		tick_arrow_label.text = "▲"
		tick_arrow_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
	elif delta < -0.0000005:
		tick_arrow_label.text = "▼"
		tick_arrow_label.add_theme_color_override("font_color", Color(0.95, 0.38, 0.38))
	else:
		tick_arrow_label.text = "·"
		tick_arrow_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.74, 1))


func pulse_fill(accent: Color) -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	modulate = Color(
		clampf(accent.r + 0.25, 0.0, 1.0),
		clampf(accent.g + 0.25, 0.0, 1.0),
		clampf(accent.b + 0.25, 0.0, 1.0)
	)
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.55)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			selected.emit(symbol)


func _apply_style() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.16, 0.17, 0.23, 1.0) if _selected else Color(0.1, 0.11, 0.15, 1.0)
	if _selected:
		box.border_color = Color(0.9, 0.75, 0.25, 0.95)
	elif _fading:
		box.border_color = Color(0.78, 0.62, 0.98, 0.85)
	else:
		box.border_color = Color(0.78, 0.82, 0.9, 0.28)
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.content_margin_left = 4
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	add_theme_stylebox_override("panel", box)
