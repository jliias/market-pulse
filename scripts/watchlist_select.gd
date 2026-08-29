extends Control

const UI_BORDER := 1
const UI_ACCENT := Color(0.78, 0.82, 0.9)
const SELECTED_ACCENT := Color(0.82, 0.9, 1.0)
const BUY_ACCENT := Color(0.32, 0.92, 0.48)

const SECTION_COPY := {
	"safe": "SAFE",
	"growth": "GROWTH",
	"volatile": "VOLATILE",
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
	for child in %Board.get_children():
		%Board.remove_child(child)
		child.free()
	row_buttons.clear()
	for key in CompanyCatalog.RISK_SECTIONS:
		var accent: Color = CompanyCatalog.risk_color(key)
		var wrap := PanelContainer.new()
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var panel := StyleBoxFlat.new()
		panel.bg_color = Color(0.1, 0.11, 0.14, 1)
		panel.border_color = Color(accent.r, accent.g, accent.b, 0.35)
		panel.set_border_width_all(1)
		panel.set_corner_radius_all(10)
		panel.content_margin_left = 10
		panel.content_margin_right = 10
		panel.content_margin_top = 10
		panel.content_margin_bottom = 10
		wrap.add_theme_stylebox_override("panel", panel)
		%Board.add_child(wrap)

		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 8)
		wrap.add_child(column)

		var header := Label.new()
		header.text = str(SECTION_COPY.get(key, key.to_upper()))
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.custom_minimum_size = Vector2(0, 22)
		header.add_theme_color_override("font_color", accent)
		header.add_theme_font_size_override("font_size", 16)
		column.add_child(header)

		var underline := ColorRect.new()
		underline.custom_minimum_size = Vector2(0, 2)
		underline.color = Color(accent.r, accent.g, accent.b, 0.7)
		column.add_child(underline)

		var profile: Dictionary = CompanyCatalog.RISK_PROFILES[key]
		var blurb := Label.new()
		blurb.text = "%s  Typical %s" % [str(profile["blurb"]), str(profile["typical"])]
		blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.max_lines_visible = 2
		blurb.custom_minimum_size = Vector2(0, 36)
		blurb.add_theme_color_override("font_color", Color(0.62, 0.65, 0.72))
		blurb.add_theme_font_size_override("font_size", 12)
		column.add_child(blurb)

		for symbol in CompanyCatalog.symbols_for_risk(key):
			_add_card(column, symbol, key)


func _add_card(column: VBoxContainer, symbol: String, key: String) -> void:
	var data: Dictionary = CompanyCatalog.spec(symbol)
	var profile: Dictionary = CompanyCatalog.risk_profile(symbol)
	var button := Button.new()
	button.toggle_mode = true
	button.clip_text = true
	button.clip_contents = true
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_row_pressed.bind(symbol))

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	button.add_child(pad)

	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 2)
	pad.add_child(stack)

	var ticker := _card_line(symbol, 16, Color(0.92, 0.94, 0.98), 20)
	stack.add_child(ticker)

	var name_line := _card_line(str(data.get("name", symbol)), 14, Color(0.86, 0.88, 0.92), 20)
	stack.add_child(name_line)

	var meta := _card_line(
		"%s · %s · %s" % [str(data.get("sector", "")), str(data.get("cap", "")), str(profile.get("typical", ""))],
		11,
		Color(0.62, 0.65, 0.72),
		18
	)
	stack.add_child(meta)

	var story := Label.new()
	story.text = str(data.get("story", ""))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.max_lines_visible = 3
	story.custom_minimum_size = Vector2(0, 48)
	story.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story.add_theme_font_size_override("font_size", 11)
	story.add_theme_color_override("font_color", Color(0.72, 0.75, 0.82))
	story.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stack.add_child(story)

	column.add_child(button)
	row_buttons[symbol] = button
	_style_row(button, key, false)


func _card_line(text: String, font_size: int, color: Color, height: int) -> Label:
	var line := Label.new()
	line.text = text
	line.clip_text = true
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.custom_minimum_size = Vector2(0, height)
	line.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_font_size_override("font_size", font_size)
	line.add_theme_color_override("font_color", color)
	return line


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
	var mix: String = CompanyCatalog.mix_summary(selected)
	if count == 0:
		%StatusLabel.text = "0 of 3 selected"
	else:
		%StatusLabel.text = "%d of 3 selected  ·  %s" % [count, mix]
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


func _style_button(button: Button, accent: Color, enabled: bool, selected_row: bool = false) -> void:
	if not enabled:
		accent = Color(accent.r, accent.g, accent.b, 0.4)
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", accent.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", accent.darkened(0.08))
	button.add_theme_color_override("font_disabled_color", Color(accent.r, accent.g, accent.b, 0.4))
	button.add_theme_font_size_override("font_size", 18)
	var fill: float = 0.28 if selected_row else 0.12
	var border: int = UI_BORDER + 2 if selected_row else UI_BORDER
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(accent.r, accent.g, accent.b, fill)
		box.border_color = accent
		box.set_border_width_all(border)
		box.set_corner_radius_all(8)
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		if state == "hover":
			box.bg_color = Color(accent.r, accent.g, accent.b, fill + 0.1)
			box.set_border_width_all(border + 1)
		elif state == "disabled":
			box.bg_color = Color(0.12, 0.13, 0.16, 1.0)
			box.border_color = Color(accent.r, accent.g, accent.b, 0.3)
		button.add_theme_stylebox_override(state, box)
