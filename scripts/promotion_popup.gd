extends Control

signal piece_selected(type: String)

func _ready() -> void:
	hide()

func show_promotion(color: String) -> void:
	show()
	var hbox = get_node("Panel/HBoxContainer")
	for button in hbox.get_children():
		var type = button.name.replace("Button", "").substr(0, 1).to_lower()
		var texture_path = "res://assets/pieces/alpha/" + color + type + ".png"
		button.texture_normal = load(texture_path)
		button.pressed.connect(_on_piece_selected.bind(type))

func _on_piece_selected(type: String) -> void:
	emit_signal("piece_selected", type)
	hide()
