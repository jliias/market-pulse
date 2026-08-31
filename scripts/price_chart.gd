class_name PriceChart
extends Control

var prices: PackedFloat32Array = PackedFloat32Array()
var volumes: PackedInt32Array = PackedInt32Array()
var compact: bool = false
var session_volume: int = 0
var line_color: Color = Color(0.35, 0.82, 0.5)
var status_banner: String = ""
var status_sub: String = ""
var status_color: Color = Color(0.95, 0.78, 0.28)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_series(p_prices: Variant, p_volumes: Variant = PackedInt32Array(), p_session_volume: int = 0) -> void:
	prices = PackedFloat32Array(p_prices)
	volumes = PackedInt32Array(p_volumes)
	session_volume = p_session_volume
	if prices.size() >= 2:
		if prices[prices.size() - 1] >= prices[0]:
			line_color = Color(0.35, 0.82, 0.5)
		else:
			line_color = Color(0.92, 0.38, 0.4)
	queue_redraw()


func set_status_banner(title: String, subtitle: String = "", color: Color = Color(0.95, 0.78, 0.28)) -> void:
	status_banner = title
	status_sub = subtitle
	status_color = color
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		return

	draw_rect(rect, Color(0.07, 0.08, 0.11, 1.0))
	if prices.size() < 2:
		_draw_status_banner(rect)
		return

	var volume_h: float = 0.0 if compact else rect.size.y * 0.22
	var chart_h: float = rect.size.y - volume_h
	var pad: float = 4.0 if compact else 10.0
	var axis_w: float = 0.0 if compact else 62.0
	var chart_rect := Rect2(pad, pad, rect.size.x - pad * 2.0 - axis_w, chart_h - pad * 2.0)

	var min_p: float = prices[0]
	var max_p: float = prices[0]
	for p in prices:
		min_p = minf(min_p, p)
		max_p = maxf(max_p, p)
	if is_equal_approx(min_p, max_p):
		min_p -= 0.5
		max_p += 0.5

	if not compact:
		var font: Font = ThemeDB.fallback_font
		var last_y: float = -999.0
		if prices.size() >= 1:
			var last_n: float = (prices[prices.size() - 1] - min_p) / (max_p - min_p)
			last_y = chart_rect.end.y - last_n * chart_rect.size.y
		for i in range(5):
			var t: float = float(i) / 4.0
			var y: float = chart_rect.position.y + chart_rect.size.y * t
			draw_line(Vector2(chart_rect.position.x, y), Vector2(chart_rect.end.x, y), Color(1, 1, 1, 0.06), 1.0)
			if absf(y - last_y) < 14.0:
				continue
			var level: float = max_p - (max_p - min_p) * t
			_draw_axis_label(font, y, level, Color(0.72, 0.76, 0.84, 0.9))
		var last_price: float = prices[prices.size() - 1]
		draw_line(
			Vector2(chart_rect.end.x, last_y),
			Vector2(chart_rect.end.x + 6.0, last_y),
			line_color,
			1.5
		)
		_draw_axis_label(font, last_y, last_price, line_color)

	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(prices.size()):
		var t: float = float(i) / float(prices.size() - 1)
		var x: float = chart_rect.position.x + t * chart_rect.size.x
		var n: float = (prices[i] - min_p) / (max_p - min_p)
		var y: float = chart_rect.end.y - n * chart_rect.size.y
		pts.append(Vector2(x, y))

	var fill: PackedVector2Array = pts.duplicate()
	fill.append(Vector2(pts[pts.size() - 1].x, chart_rect.end.y))
	fill.append(Vector2(pts[0].x, chart_rect.end.y))
	var fill_color := Color(line_color.r, line_color.g, line_color.b, 0.16)
	draw_colored_polygon(fill, fill_color)
	draw_polyline(pts, line_color, 2.0 if compact else 2.4, true)

	if compact or volumes.is_empty() or volume_h < 16.0:
		_draw_status_banner(rect)
		return

	var vol_top: float = chart_h
	draw_line(
		Vector2(pad, vol_top),
		Vector2(rect.size.x - pad, vol_top),
		Color(1, 1, 1, 0.12),
		1.0
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(pad, vol_top + 12.0),
		"VOL %s" % Stock.format_volume(maxi(session_volume, 0)),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		Color(0.55, 0.58, 0.64, 0.9)
	)

	var max_v: int = 1
	for v in volumes:
		max_v = maxi(max_v, v)

	var count: int = volumes.size()
	var usable_w: float = chart_rect.size.x
	var slot_w: float = usable_w / float(maxi(count, 1))
	var bar_w: float = clampf(slot_w * 0.7, 2.0, 10.0)
	var bar_area_h: float = volume_h - 16.0

	for i in range(count):
		var x: float = chart_rect.position.x + (float(i) + 0.5) * slot_w
		var h: float = maxf((float(volumes[i]) / float(max_v)) * bar_area_h, 2.0)
		var bar := Rect2(x - bar_w * 0.5, rect.size.y - pad - h, bar_w, h)
		var up: bool = i == 0 or (i < prices.size() and prices[i] >= prices[maxi(i - 1, 0)])
		var bar_color := Color(0.32, 0.78, 0.48, 0.7) if up else Color(0.9, 0.38, 0.4, 0.7)
		draw_rect(bar, bar_color, true)

	_draw_status_banner(rect)


func _draw_status_banner(rect: Rect2) -> void:
	if compact or status_banner.is_empty():
		return
	var tint := Color(status_color.r, status_color.g, status_color.b, 0.14)
	draw_rect(rect, tint)
	var font: Font = ThemeDB.fallback_font
	var title_size := 52
	var title_sz: Vector2 = font.get_string_size(status_banner, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
	var title_pos := Vector2(
		rect.position.x + (rect.size.x - title_sz.x) * 0.5,
		rect.position.y + rect.size.y * 0.42 + title_sz.y * 0.25
	)
	var shadow := Color(0.04, 0.05, 0.07, 0.85)
	draw_string(font, title_pos + Vector2(2, 2), status_banner, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, shadow)
	draw_string(font, title_pos, status_banner, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, status_color)
	if status_sub.is_empty():
		return
	var sub_size := 18
	var sub_sz: Vector2 = font.get_string_size(status_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size)
	var sub_pos := Vector2(
		rect.position.x + (rect.size.x - sub_sz.x) * 0.5,
		title_pos.y + 28.0
	)
	draw_string(font, sub_pos, status_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, Color(status_color.r, status_color.g, status_color.b, 0.92))


func _draw_axis_label(font: Font, y: float, price: float, color: Color) -> void:
	var text: String = "$%.2f" % price
	var font_size := 12
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := Vector2(size.x - 8.0 - text_size.x, y + 4.0)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
