class_name WatchlistCard
extends PanelContainer

signal selected(symbol: String)

var symbol: String = ""
var _selected: bool = false

@onready var ticker_label: Label = %TickerLabel
@onready var risk_label: Label = %RiskLabel
@onready var name_label: Label = %NameLabel
@onready var price_label: Label = %PriceLabel
@onready var change_label: Label = %ChangeLabel
@onready var volume_label: Label = %VolumeLabel
@onready var owned_label: Label = %OwnedLabel
@onready var mini_chart: PriceChart = %MiniChart
@onready var highlight: ColorRect = %Highlight


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_style()


func set_selected(on: bool) -> void:
	_selected = on
	highlight.visible = on
	_apply_style()


func refresh(stock: Stock, owned_shares: int = 0) -> void:
	symbol = stock.symbol
	ticker_label.text = stock.symbol
	risk_label.text = stock.listing_label()
	if stock.is_halted():
		risk_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
		CopyHints.hover(risk_label, stock.halt_tooltip())
	elif stock.is_distressed():
		risk_label.add_theme_color_override("font_color", Color(0.95, 0.38, 0.38))
		CopyHints.hover(risk_label, CopyHints.HUD_DISTRESSED)
	else:
		risk_label.add_theme_color_override("font_color", CompanyCatalog.risk_color(stock.risk_key))
		risk_label.tooltip_text = ""
	name_label.text = stock.company_name
	price_label.text = "$%.2f" % stock.price
	var change: float = stock.get_day_change()
	var pct: float = stock.get_day_change_pct()
	var sign := "+" if change >= 0.0 else "-"
	change_label.text = "%s$%.2f (%s%.2f%%)" % [sign, absf(change), sign, absf(pct)]
	change_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45) if change >= 0.0 else Color(0.95, 0.38, 0.38))
	volume_label.text = "Volume: %s" % _format_volume(stock.volume)
	if owned_shares > 0:
		owned_label.text = "Owned: %d" % owned_shares
		owned_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.25, 1))
	else:
		owned_label.text = "Owned: 0"
		owned_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.74, 1))
	var slice: Dictionary = stock.get_chart_slice(24, 1)
	mini_chart.compact = true
	mini_chart.set_series(slice["prices"], slice["volumes"])


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			selected.emit(symbol)


func _apply_style() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.14, 0.16, 0.22, 1.0) if _selected else Color(0.11, 0.12, 0.16, 1.0)
	box.border_color = Color(0.9, 0.75, 0.25, 0.95) if _selected else Color(0.78, 0.82, 0.9, 0.7)
	box.set_border_width_all(2 if _selected else 1)
	box.set_corner_radius_all(8)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	add_theme_stylebox_override("panel", box)


func _format_volume(vol: int) -> String:
	if vol >= 1000000:
		return "%.2fM" % (float(vol) / 1000000.0)
	if vol >= 1000:
		return "%.1fK" % (float(vol) / 1000.0)
	return str(vol)
