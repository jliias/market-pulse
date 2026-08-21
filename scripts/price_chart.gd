class_name PriceChart
extends Control

var prices: PackedFloat32Array = PackedFloat32Array()
var volumes: PackedInt32Array = PackedInt32Array()
var compact: bool = false
var line_color: Color = Color(0.35, 0.82, 0.5)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_series(p_prices: Variant, p_volumes: Variant = PackedInt32Array()) -> void:
	prices = PackedFloat32Array(p_prices)
	volumes = PackedInt32Array(p_volumes)
	if prices.size() >= 2:
		if prices[prices.size() - 1] >= prices[0]:
			line_color = Color(0.35, 0.82, 0.5)
		else:
			line_color = Color(0.92, 0.38, 0.4)
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		return

	draw_rect(rect, Color(0.07, 0.08, 0.11, 1.0))
	if prices.size() < 2:
		return

	var volume_h: float = 0.0 if compact else rect.size.y * 0.22
	var chart_h: float = rect.size.y - volume_h
	var pad: float = 4.0 if compact else 10.0
	var chart_rect := Rect2(pad, pad, rect.size.x - pad * 2.0, chart_h - pad * 2.0)

	var min_p: float = prices[0]
	var max_p: float = prices[0]
	for p in prices:
		min_p = minf(min_p, p)
		max_p = maxf(max_p, p)
	if is_equal_approx(min_p, max_p):
		min_p -= 0.5
		max_p += 0.5

	if not compact:
		for i in range(5):
			var y: float = chart_rect.position.y + chart_rect.size.y * float(i) / 4.0
			draw_line(Vector2(chart_rect.position.x, y), Vector2(chart_rect.end.x, y), Color(1, 1, 1, 0.06), 1.0)

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
		"VOL",
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
