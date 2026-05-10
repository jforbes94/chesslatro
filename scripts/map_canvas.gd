extends Control

var _lines: Array = []

func clear_lines() -> void:
	_lines.clear()
	queue_redraw()

func add_line(from_pos: Vector2, to_pos: Vector2, col: Color, width: float = 2.5) -> void:
	_lines.append({"f": from_pos, "t": to_pos, "c": col, "w": width})
	queue_redraw()

func _draw() -> void:
	for l in _lines:
		draw_line(l["f"], l["t"], l["c"], l["w"])
