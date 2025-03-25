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
	
var piece_manager = null

func set_piece_manager(pm) -> void:
	piece_manager = pm

func set_promotion_popup(popup) -> void:
	promotion_popup = popup
	promotion_popup.piece_selected.connect(_on_promotion_selected)

func handle_tile_click(tile: ColorRect) -> void:
	
	#print("did we get to here")
	if promotion_popup and promotion_popup.visible:
		return
	#print("what about here?")
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
		
		# checks if the move is legal and if the move would put king into check
		if _is_valid_move(moved_piece, old_pos, new_pos) and is_move_safe(moved_piece, old_pos, new_pos):

			game_state.set_piece_at(old_pos.x, old_pos.y, "")
			game_state.set_piece_at(new_pos.x, new_pos.y, moved_piece)
			
			#checks if it was an En Passant capture
			if moved_piece[1] == "p" and game_state.en_passant_target == new_pos:
				var captured_pawn_row = old_pos.x  # The pawn is on the same rank the moving pawn came from
				var captured_tile_name = game_state.indices_to_square_name(captured_pawn_row, new_pos.y)
				var captured_tile = board_root.get_node_or_null(captured_tile_name)
				if captured_tile:
					remove_piece_from_tile(captured_tile)

			# Check for promotion
			if moved_piece[1] == "p":
				if (moved_piece.begins_with("w") and new_pos.x == 0) or (moved_piece.begins_with("b") and new_pos.x == 7):
					pending_promotion_tile = tile  # tile is the destination
					pending_promotion_color = moved_piece[0]
					promotion_popup.show_promotion(moved_piece[0])
					
			if moved_piece[1] == "k":
				var dx = new_pos.y - old_pos.y
				if abs(dx) == 2:
					var rook_from_col = 7 if dx > 0 else 0
					var rook_to_col = new_pos.y - 1 if dx > 0 else new_pos.y + 1
					var row = old_pos.x

					var rook_from_name = game_state.indices_to_square_name(row, rook_from_col)
					var rook_to_name = game_state.indices_to_square_name(row, rook_to_col)

					var rook_from_tile = board_root.get_node_or_null(rook_from_name)
					var rook_to_tile = board_root.get_node_or_null(rook_to_name)

					if rook_from_tile and rook_to_tile:
						var rook_piece = game_state.get_piece_at(row, rook_from_col)
						game_state.set_piece_at(row, rook_from_col, "")
						game_state.set_piece_at(row, rook_to_col, rook_piece)
						move_piece(rook_from_tile, rook_to_tile, rook_piece)

			move_piece(selected_tile, tile, moved_piece)

			# Determine who's up next
			var opponent_color = ""
			if current_turn == "w":
				opponent_color = "b"
			else:
				opponent_color = "w"

			# Check for check/checkmate BEFORE flipping the turn
			if game_state.is_king_in_check(opponent_color):
				if game_state.is_checkmate(opponent_color):
					print("♟️ CHECKMATE! " + current_turn + " wins!")
				else:
					print("♛ " + opponent_color + " is in check.")
			elif game_state.is_stalemate(opponent_color):
				print("🤝 STALEMATE! It's a draw.")

			# Now flip the turn
			current_turn = opponent_color
			
			#checking for check_mate
			


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
	remove_piece_from_tile(to_tile)
	remove_piece_from_tile(from_tile)

	var sprite = piece_manager.create_piece_sprite(piece_code)
	to_tile.add_child(sprite)

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
		if child is TextureRect or child is Sprite2D:
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

	# 1. Remove the pawn
	for child in pending_promotion_tile.get_children():
		if child is TextureRect or child is Sprite2D:
			child.queue_free()

	# 2. Add the promoted piece visually
	var sprite = piece_manager.create_piece_sprite(new_piece_code)
	pending_promotion_tile.add_child(sprite)

	# 3. Update game state
	var pos = game_state.square_to_indices(pending_promotion_tile.name)
	game_state.set_piece_at(pos.x, pos.y, new_piece_code)

	# 4. Clean up
	pending_promotion_tile = null
	pending_promotion_color = ""
	promotion_popup.hide_popup()

#temporary move check to understand if the move would put the king in check.
func is_move_safe(piece_code: String, from: Vector2i, to: Vector2i) -> bool:
	# Save current state
	var original_target_piece = game_state.get_piece_at(to.x, to.y)
	var original_en_passant = game_state.en_passant_target

	# Apply the move
	game_state.set_piece_at(from.x, from.y, "")
	game_state.set_piece_at(to.x, to.y, piece_code)

	# Special case: if en passant capture happens, remove captured pawn temporarily
	var ep_captured_piece = ""
	if piece_code[1] == "p" and game_state.en_passant_target == to:
		var captured_pos = Vector2i(from.x, to.y)
		ep_captured_piece = game_state.get_piece_at(captured_pos.x, captured_pos.y)
		game_state.set_piece_at(captured_pos.x, captured_pos.y, "")

	# Check for king safety
	var color = piece_code[0]
	var safe = not game_state.is_king_in_check(color)

	# Revert state
	game_state.set_piece_at(from.x, from.y, piece_code)
	game_state.set_piece_at(to.x, to.y, original_target_piece)
	game_state.en_passant_target = original_en_passant

	if ep_captured_piece != "":
		var captured_pos = Vector2i(from.x, to.y)
		game_state.set_piece_at(captured_pos.x, captured_pos.y, ep_captured_piece)

	return safe
