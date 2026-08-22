extends Control

const UI_BORDER := 1
const UI_ACCENT := Color(0.78, 0.82, 0.9)
const SELECTED_ACCENT := Color(0.82, 0.9, 1.0)
const BUY_ACCENT := Color(0.32, 0.92, 0.48)

const SECTION_COPY := {
	"safe": "SAFE — smaller potential gains",
	"growth": "GROWTH — moderate risk and reward",
	"volatile": "VOLATILE — larger gains and losses",
}

var selected: Array[String] = []
var row_buttons: Dictionary = {}


func _ready() -> void:
	_style_button(%BackButton, UI_ACCENT, true)
	_style_button(%StartButton, BUY_ACCENT, false)
	%BackButton.pressed.connect(_on_back)
	%StartButton.pressed.connect(_on_start)
	_build_list()
	_refresh_state()


func _build_list() -> void:
	for child in %CompanyList.get_children():
		%CompanyList.remove_child(child)
		child.free()
	row_buttons.clear()
	for key in CompanyCatalog.RISK_SECTIONS:
		var header := Label.new()
		header.text = str(SECTION_COPY.get(key, key.to_upper()))
		header.add_theme_color_override("font_color", CompanyCatalog.risk_color(key))
		header.add_theme_font_size_override("font_size", 15)
		%CompanyList.add_child(header)
		var blurb := Label.new()
		var profile: Dictionary = CompanyCatalog.RISK_PROFILES[key]
		blurb.text = "%s  Typical day %s" % [str(profile["blurb"]), str(profile["typical"])]
		blurb.add_theme_color_override("font_color", Color(0.62, 0.65, 0.72))
		blurb.add_theme_font_size_override("font_size", 13)
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		%CompanyList.add_child(blurb)
		for symbol in CompanyCatalog.symbols_for_risk(key):
			_add_row(symbol, key)


func _add_row(symbol: String, key: String) -> void:
	var data: Dictionary = CompanyCatalog.spec(symbol)
	var profile: Dictionary = CompanyCatalog.risk_profile(symbol)
	var button := Button.new()
	button.toggle_mode = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 58)
	button.text = "%s    %s\n%s  ·  %s  ·  Typical day %s" % [
		symbol,
		str(data.get("name", symbol)),
		str(data.get("label", "")),
		"%s · %s" % [str(data.get("sector", "")), str(data.get("cap", ""))],
		str(profile.get("typical", "")),
	]
	button.pressed.connect(_on_row_pressed.bind(symbol))
	%CompanyList.add_child(button)
	row_buttons[symbol] = button
	_style_row(button, key, false)


func _on_row_pressed(symbol: String) -> void:
	var button: Button = row_buttons[symbol]
	if selected.has(symbol):
		selected.erase(symbol)
		button.button_pressed = false
	elif selected.size() < 3:
		selected.append(symbol)
		button.button_pressed = true
	else:
		button.button_pressed = false
	_refresh_state()


func _refresh_state() -> void:
	for symbol in row_buttons:
		var on: bool = selected.has(symbol)
		var button: Button = row_buttons[symbol]
		button.button_pressed = on
		_style_row(button, CompanyCatalog.risk_key(symbol), on)
	var count: int = selected.size()
	%HintLabel.text = "Choose exactly 3 names. Your mix is the risk for this whole run. %d of 3 selected." % count
	%PickedLabel.text = CompanyCatalog.mix_summary(selected)
	%StartButton.disabled = count != 3
	_style_button(%StartButton, BUY_ACCENT, count == 3)


func _on_start() -> void:
	if selected.size() != 3:
		return
	SaveManager.pending_watchlist = CompanyCatalog.sanitize_watchlist(selected)
	SaveManager.launch_mode = "new"
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_back() -> void:
	SaveManager.pending_watchlist.clear()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _style_row(button: Button, key: String, on: bool) -> void:
	var accent: Color = SELECTED_ACCENT if on else CompanyCatalog.risk_color(key)
	_style_button(button, accent, true, on)
	button.add_theme_font_size_override("font_size", 15)


func _style_button(button: Button, accent: Color, enabled: bool, selected_row: bool = false) -> void:
	if not enabled:
		accent = Color(accent.r, accent.g, accent.b, 0.4)
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", accent.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", accent.darkened(0.08))
	button.add_theme_color_override("font_disabled_color", Color(accent.r, accent.g, accent.b, 0.4))
	button.add_theme_font_size_override("font_size", 20)
	var fill: float = 0.28 if selected_row else 0.12
	var border: int = UI_BORDER + 2 if selected_row else UI_BORDER
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(accent.r, accent.g, accent.b, fill)
		box.border_color = accent
		box.set_border_width_all(border)
		box.set_corner_radius_all(8)
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		if state == "hover":
			box.bg_color = Color(accent.r, accent.g, accent.b, fill + 0.1)
			box.set_border_width_all(border + 1)
		elif state == "disabled":
			box.bg_color = Color(0.12, 0.13, 0.16, 1.0)
			box.border_color = Color(accent.r, accent.g, accent.b, 0.3)
		button.add_theme_stylebox_override(state, box)
