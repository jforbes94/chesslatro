extends Control

signal piece_selected(type: String)

func hide_popup():
	visible = false
	$Panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_promotion(color: String) -> void:
	visible = true
	$Panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox = get_node("Panel/HBoxContainer")
	for button in hbox.get_children():
		var type = button.name.replace("Button", "").substr(0, 1).to_lower()
		var texture_path = "res://assets/pieces/alpha/" + color + type + ".png"
		button.texture_normal = load(texture_path)

		if button.pressed.is_connected(_on_piece_selected):
			button.pressed.disconnect(_on_piece_selected)

		button.pressed.connect(_on_piece_selected.bind(type))


func _on_piece_selected(type: String) -> void:
	emit_signal("piece_selected", type)
	hide_popup()
