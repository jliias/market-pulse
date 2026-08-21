extends Control

const UI_BORDER := 1
const UI_ACCENT := Color(0.78, 0.82, 0.9)
const SELECTED_ACCENT := Color(0.9, 0.75, 0.25)
const BUY_ACCENT := Color(0.32, 0.92, 0.48)


func _ready() -> void:
	_style_button(%NewGameButton, BUY_ACCENT, true)
	_style_button(%ContinueButton, SELECTED_ACCENT, SaveManager.has_save())
	_style_button(%ExitButton, UI_ACCENT, true)
	%ContinueButton.disabled = not SaveManager.has_save()
	%SaveSummaryLabel.text = SaveManager.summary_text() if SaveManager.has_save() else "No saved game yet."
	%NewGameButton.pressed.connect(_on_new_game)
	%ContinueButton.pressed.connect(_on_continue)
	%ExitButton.pressed.connect(_on_exit)


func _on_new_game() -> void:
	SaveManager.launch_mode = "new"
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_continue() -> void:
	if not SaveManager.has_save():
		return
	SaveManager.launch_mode = "continue"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_exit() -> void:
	get_tree().quit()


func _style_button(button: Button, accent: Color, enabled: bool) -> void:
	if not enabled:
		accent = Color(accent.r, accent.g, accent.b, 0.4)
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", accent.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", accent.darkened(0.08))
	button.add_theme_color_override("font_disabled_color", Color(accent.r, accent.g, accent.b, 0.4))
	button.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
		box.border_color = accent
		box.set_border_width_all(UI_BORDER)
		box.set_corner_radius_all(8)
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 12
		box.content_margin_bottom = 12
		if state == "hover":
			box.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
			box.set_border_width_all(UI_BORDER + 1)
		elif state == "disabled":
			box.bg_color = Color(0.12, 0.13, 0.16, 1.0)
			box.border_color = Color(accent.r, accent.g, accent.b, 0.3)
		button.add_theme_stylebox_override(state, box)
