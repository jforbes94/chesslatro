extends Node

var game_state = null
var board_root = null
var selected_tile = null
var current_turn = "w"

var promotion_popup = null
var pending_promotion_tile = null
var pending_promotion_color = ""

func set_game_state(state) -> void:
	game_state = state

func set_board_root(root) -> void:
	board_root = root

func set_promotion_popup(popup) -> void:
	promotion_popup = popup
	promotion_popup.piece_selected.connect(_on_promotion_selected)

func handle_tile_click(tile: ColorRect) -> void:
	
	print("did we get to here")
	if promotion_popup and promotion_popup.visible:
		return
	print("what about here?")
	var tile_name = tile.name
	var pos = game_state.square_to_indices(tile_name)
	var piece_code = game_state.get_piece_at(pos.x, pos.y)

	if selected_tile == null:
		if piece_code != "" and piece_code.begins_with(current_turn):
			selected_tile = tile
			tile.color = Color(1, 0.8, 0.2)
	else:
		var old_pos = game_state.square_to_indices(selected_tile.name)
		var new_pos = pos
		var moved_piece = game_state.get_piece_at(old_pos.x, old_pos.y)

		if _is_valid_move(moved_piece, old_pos, new_pos):
			game_state.set_piece_at(old_pos.x, old_pos.y, "")
			game_state.set_piece_at(new_pos.x, new_pos.y, moved_piece)

			# Check for promotion
			if moved_piece[1] == "p":
				if (moved_piece.begins_with("w") and new_pos.x == 0) or (moved_piece.begins_with("b") and new_pos.x == 7):
					print("🟢 Promotion triggered for", moved_piece)
					pending_promotion_tile = tile
					pending_promotion_color = moved_piece[0]
					promotion_popup.show_promotion(moved_piece[0])
					selected_tile.color = _get_tile_color(selected_tile)
					selected_tile = null
					return

			move_piece(selected_tile, tile, moved_piece)
			current_turn = "b" if current_turn == "w" else "w"

		selected_tile.color = _get_tile_color(selected_tile)
		selected_tile = null

func _is_valid_move(piece_code: String, old_pos: Vector2i, new_pos: Vector2i) -> bool:
	match piece_code[1]:
		"p":
			return game_state.is_valid_pawn_move(old_pos, new_pos, piece_code)
		"n":
			return game_state.is_valid_knight_move(old_pos, new_pos,piece_code)
		"b":
			return game_state.is_valid_bishop_move(old_pos, new_pos,piece_code)
		"r":
			return game_state.is_valid_rook_move(old_pos, new_pos,piece_code)
		"q":
			return game_state.is_valid_queen_move(old_pos, new_pos,piece_code)
		"k":
			return game_state.is_valid_king_move(old_pos, new_pos, piece_code)
		_:
			return false

func move_piece(from_tile: ColorRect, to_tile: ColorRect, piece_code: String) -> void:
	var texture = get_piece_texture(piece_code)
	remove_piece_from_tile(to_tile)
	remove_piece_from_tile(from_tile)
	draw_piece_on_tile(to_tile, texture)

func get_piece_texture(piece_code: String) -> Texture2D:
	var texture_path = "res://assets/pieces/alpha/" + piece_code + ".png"
	return load(texture_path)

func draw_piece_on_tile(tile: ColorRect, texture: Texture2D) -> void:
	var piece = TextureRect.new()
	piece.texture = texture
	piece.stretch_mode = TextureRect.STRETCH_SCALE
	piece.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.add_child(piece)

func remove_piece_from_tile(tile: ColorRect) -> void:
	for child in tile.get_children():
		if child is TextureRect:
			child.queue_free()

func _get_tile_color(tile: ColorRect) -> Color:
	var pos = game_state.square_to_indices(tile.name)
	return Color.WHITE if (pos.x + pos.y) % 2 == 0 else Color.GRAY

func _on_promotion_selected(type: String) -> void:
	if not pending_promotion_tile:
		print("⚠️ No tile to promote on")
		return

	var color = pending_promotion_color
	var new_piece_code = color + type
	var texture = get_piece_texture(new_piece_code)

	remove_piece_from_tile(pending_promotion_tile)
	draw_piece_on_tile(pending_promotion_tile, texture)

	var pos = game_state.square_to_indices(pending_promotion_tile.name)
	game_state.set_piece_at(pos.x, pos.y, new_piece_code)

	pending_promotion_tile = null
	pending_promotion_color = ""
