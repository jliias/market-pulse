extends Control

const UI_BORDER := 1
const UI_ACCENT := Color(0.78, 0.82, 0.9)
const SELECTED_ACCENT := Color(0.9, 0.75, 0.25)
const BUY_ACCENT := Color(0.32, 0.92, 0.48)

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
	for symbol in CompanyCatalog.ORDER:
		var data: Dictionary = CompanyCatalog.spec(symbol)
		var button := Button.new()
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s    %s    %s · %s · %s" % [
			symbol,
			str(data.get("name", symbol)),
			str(data.get("label", "")),
			str(data.get("sector", "")),
			str(data.get("cap", "")),
		]
		button.pressed.connect(_on_row_pressed.bind(symbol))
		%CompanyList.add_child(button)
		row_buttons[symbol] = button
		_style_row(button, false)


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
		_style_row(button, on)
	var count: int = selected.size()
	%HintLabel.text = "Choose exactly 3 names for this run. %d of 3 selected." % count
	if count == 3:
		%PickedLabel.text = "Watchlist: %s" % ", ".join(selected)
	else:
		%PickedLabel.text = "Watchlist: —"
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


func _style_row(button: Button, on: bool) -> void:
	var accent: Color = SELECTED_ACCENT if on else UI_ACCENT
	_style_button(button, accent, true)
	button.add_theme_font_size_override("font_size", 16)


func _style_button(button: Button, accent: Color, enabled: bool) -> void:
	if not enabled:
		accent = Color(accent.r, accent.g, accent.b, 0.4)
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", accent.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", accent.darkened(0.08))
	button.add_theme_color_override("font_disabled_color", Color(accent.r, accent.g, accent.b, 0.4))
	button.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
		box.border_color = accent
		box.set_border_width_all(UI_BORDER)
		box.set_corner_radius_all(8)
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		if state == "hover":
			box.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
			box.set_border_width_all(UI_BORDER + 1)
		elif state == "disabled":
			box.bg_color = Color(0.12, 0.13, 0.16, 1.0)
			box.border_color = Color(accent.r, accent.g, accent.b, 0.3)
		button.add_theme_stylebox_override(state, box)
