extends Node

signal match_over(result: String)
signal wrong_move(tile: ColorRect)
signal puzzle_complete
signal puzzle_failed(tile: ColorRect)
signal white_moved

var game_state = null
var board_root = null
var selected_tile = null
var promotion_popup = null
var pending_promotion_tile = null
var pending_promotion_color = ""
var last_moved_tile: ColorRect = null
var piece_manager = null

var puzzle_mode: bool = true
var solution_moves: Array = []
var solution_index: int = 0

const COLOR_SELECTED  = Color(1, 0.8, 0.2)
const COLOR_LAST_MOVE = Color(0.4, 0.9, 0.4)
const COLOR_WRONG     = Color(1, 0.2, 0.2)

@onready var stockfish: Node = get_node("/root/ChessBoard/StockfishInterface")

func _ready():
	var chessboard = get_parent()
	board_root      = chessboard.get_node("BoardTiles")
	promotion_popup = chessboard.get_node("UI/PromotionPopup")
	self.stockfish  = chessboard.get_node("StockfishInterface")

	if not promotion_popup.piece_selected.is_connected(_on_promotion_selected):
		promotion_popup.piece_selected.connect(_on_promotion_selected)
	promotion_popup.visible = false
	promotion_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	promotion_popup.hide()
	print("✅ movement_manager ready")

# --- Setup ---

func set_game_state(state) -> void: game_state = state
func set_board_root(root)    -> void: board_root = root
func set_piece_manager(pm)   -> void: piece_manager = pm
func set_promotion_popup(popup) -> void:
	promotion_popup = popup
	promotion_popup.piece_selected.connect(_on_promotion_selected)

func start_puzzle(moves: Array) -> void:
	puzzle_mode    = true
	solution_moves = moves
	solution_index = 0

func apply_setup_move(move: String) -> void:
	_apply_uci_move(move)
	GameStateManager.current_turn = "w"

func start_boss() -> void:
	puzzle_mode    = false
	solution_moves = []
	solution_index = 0

# --- Input ---

func handle_tile_click(tile: ColorRect) -> void:
	if promotion_popup and promotion_popup.visible:
		return

	var pos        = game_state.square_to_indices(tile.name)
	var piece_code = game_state.get_piece_at(pos.x, pos.y)

	if selected_tile == null:
		if piece_code != "" and piece_code.begins_with(GameStateManager.current_turn):
			selected_tile = tile
			tile.color = COLOR_SELECTED
	else:
		var old_pos     = game_state.square_to_indices(selected_tile.name)
		var new_pos     = pos
		var moved_piece = game_state.get_piece_at(old_pos.x, old_pos.y)

		if _is_valid_move(moved_piece, old_pos, new_pos) and is_move_safe(moved_piece, old_pos, new_pos):

			# Puzzle mode: check against solution before committing
			if puzzle_mode and GameStateManager.current_turn == "w":
				var move_str = selected_tile.name + tile.name
				var expected = solution_moves[solution_index].substr(0, 4)
				if move_str != expected:
					emit_signal("wrong_move", tile)
					emit_signal("puzzle_failed", tile)
					selected_tile.color = _get_tile_color(selected_tile)
					selected_tile = null
					return

			# Commit move to game state
			game_state.set_piece_at(old_pos.x, old_pos.y, "")
			game_state.set_piece_at(new_pos.x, new_pos.y, moved_piece)

			# En passant capture
			if moved_piece[1] == "p" and game_state.en_passant_target == new_pos:
				var captured_row  = old_pos.x
				var captured_name = game_state.indices_to_square_name(captured_row, new_pos.y)
				var captured_tile = board_root.get_node_or_null(captured_name)
				if captured_tile:
					remove_piece_from_tile(captured_tile)

			# Pawn promotion
			if moved_piece[1] == "p":
				if (moved_piece.begins_with("w") and new_pos.x == 0) or \
				   (moved_piece.begins_with("b") and new_pos.x == 7):
					pending_promotion_tile  = tile
					pending_promotion_color = moved_piece[0]
					promotion_popup.show_promotion(moved_piece[0])

			# Castling — move rook too
			if moved_piece[1] == "k":
				var dx = new_pos.y - old_pos.y
				if abs(dx) == 2:
					var rook_from_col = 7 if dx > 0 else 0
					var rook_to_col   = new_pos.y - 1 if dx > 0 else new_pos.y + 1
					var row           = old_pos.x
					var rf_name = game_state.indices_to_square_name(row, rook_from_col)
					var rt_name = game_state.indices_to_square_name(row, rook_to_col)
					var rf_tile = board_root.get_node_or_null(rf_name)
					var rt_tile = board_root.get_node_or_null(rt_name)
					if rf_tile and rt_tile:
						var rook_piece = game_state.get_piece_at(row, rook_from_col)
						game_state.set_piece_at(row, rook_from_col, "")
						game_state.set_piece_at(row, rook_to_col, rook_piece)
						move_piece(rf_tile, rt_tile, rook_piece)

			move_piece(selected_tile, tile, moved_piece)
			end_turn()

		selected_tile.color = _get_tile_color(selected_tile)
		selected_tile = null

# --- Move validation ---

func _is_valid_move(piece_code: String, old_pos: Vector2i, new_pos: Vector2i) -> bool:
	match piece_code[1]:
		"p": return game_state.is_valid_pawn_move(old_pos, new_pos, piece_code)
		"n": return game_state.is_valid_knight_move(old_pos, new_pos, piece_code)
		"b": return game_state.is_valid_bishop_move(old_pos, new_pos, piece_code)
		"r": return game_state.is_valid_rook_move(old_pos, new_pos, piece_code)
		"q": return game_state.is_valid_queen_move(old_pos, new_pos, piece_code)
		"k": return game_state.is_valid_king_move(old_pos, new_pos, piece_code)
		_:   return false

func is_move_safe(piece_code: String, from: Vector2i, to: Vector2i) -> bool:
	var original_target  = game_state.get_piece_at(to.x, to.y)
	var original_ep      = game_state.en_passant_target
	game_state.set_piece_at(from.x, from.y, "")
	game_state.set_piece_at(to.x, to.y, piece_code)

	var ep_captured = ""
	if piece_code[1] == "p" and game_state.en_passant_target == to:
		var captured_pos = Vector2i(from.x, to.y)
		ep_captured = game_state.get_piece_at(captured_pos.x, captured_pos.y)
		game_state.set_piece_at(captured_pos.x, captured_pos.y, "")

	var safe = not game_state.is_king_in_check(piece_code[0])

	game_state.set_piece_at(from.x, from.y, piece_code)
	game_state.set_piece_at(to.x, to.y, original_target)
	game_state.en_passant_target = original_ep
	if ep_captured != "":
		game_state.set_piece_at(from.x, to.y, ep_captured)

	return safe

# --- Turn management ---

func end_turn() -> void:
	var just_moved     = GameStateManager.current_turn
	var opponent_color = "b" if just_moved == "w" else "w"

	if puzzle_mode:
		GameStateManager.current_turn = opponent_color
		if just_moved == "w":
			solution_index += 1
			if solution_index >= solution_moves.size():
				emit_signal("puzzle_complete")
			else:
				call_deferred("_play_scripted_black_move")
	else:
		evaluate_board_state(opponent_color)
		GameStateManager.current_turn = opponent_color
		if just_moved == "w":
			emit_signal("white_moved")
		if GameStateManager.current_turn == "b":
			call_deferred("_make_ai_move")

func evaluate_board_state(next_turn: String) -> void:
	if game_state.is_king_in_check(next_turn):
		if game_state.is_checkmate(next_turn):
			var winner = GameStateManager.current_turn
			print("♟️ CHECKMATE! " + winner + " wins!")
			emit_signal("match_over", "checkmate_" + winner)
		else:
			print("♛ " + next_turn + " is in check.")
	elif game_state.is_stalemate(next_turn):
		print("🤝 STALEMATE!")
		emit_signal("match_over", "stalemate")

# --- Scripted Black response (puzzle mode) ---

func _play_scripted_black_move() -> void:
	await get_tree().create_timer(0.3).timeout
	if solution_index >= solution_moves.size():
		GameStateManager.current_turn = "w"
		return
	_apply_uci_move(solution_moves[solution_index])
	solution_index += 1
	GameStateManager.current_turn = "w"
	if solution_index >= solution_moves.size():
		emit_signal("puzzle_complete")

# --- Stockfish (boss mode) ---

func _make_ai_move() -> void:
	if stockfish == null:
		print("❌ Stockfish is null")
		return
	var fen  = game_state.board_state_to_fen()
	var move = stockfish.call("GetBestMove", fen)
	print("✅ Stockfish move:", move)
	apply_stockfish_move(move)

func apply_stockfish_move(move: String) -> void:
	if move == null or move.length() < 4:
		print("⚠️ Invalid move string:", move)
		return
	_apply_uci_move(move)
	end_turn()

# --- Shared UCI move applicator ---

func _apply_uci_move(move: String) -> void:
	if move == null or move.length() < 4:
		print("⚠️ Invalid UCI move:", move)
		return

	var from_file = move[0].unicode_at(0) - "a".unicode_at(0)
	var from_rank = 8 - int(move[1])
	var to_file   = move[2].unicode_at(0) - "a".unicode_at(0)
	var to_rank   = 8 - int(move[3])

	var from_pos  = Vector2i(from_rank, from_file)
	var to_pos    = Vector2i(to_rank, to_file)
	var from_name = game_state.indices_to_square_name(from_rank, from_file)
	var to_name   = game_state.indices_to_square_name(to_rank, to_file)
	var from_tile = board_root.get_node_or_null(from_name)
	var to_tile   = board_root.get_node_or_null(to_name)

	if not from_tile or not to_tile:
		print("⚠️ Tiles not found for move:", move)
		return

	var piece = game_state.get_piece_at(from_pos.x, from_pos.y)
	if piece == "":
		print("⚠️ No piece at:", from_name)
		return

	# Castling — move rook
	var base = move.substr(0, 4)
	var castling_map = {
		"e1g1": [Vector2i(7,7), Vector2i(7,5)],
		"e1c1": [Vector2i(7,0), Vector2i(7,3)],
		"e8g8": [Vector2i(0,7), Vector2i(0,5)],
		"e8c8": [Vector2i(0,0), Vector2i(0,3)],
	}
	if castling_map.has(base):
		var rook_from = castling_map[base][0]
		var rook_to   = castling_map[base][1]
		var rook_piece = game_state.get_piece_at(rook_from.x, rook_from.y)
		game_state.set_piece_at(rook_from.x, rook_from.y, "")
		game_state.set_piece_at(rook_to.x, rook_to.y, rook_piece)
		var rf_tile = board_root.get_node_or_null(game_state.indices_to_square_name(rook_from.x, rook_from.y))
		var rt_tile = board_root.get_node_or_null(game_state.indices_to_square_name(rook_to.x, rook_to.y))
		if rf_tile and rt_tile:
			move_piece(rf_tile, rt_tile, rook_piece)

	# Promotion
	if move.length() == 5:
		piece = piece[0] + move[4]
		game_state.set_piece_at(from_pos.x, from_pos.y, piece)

	game_state.set_piece_at(from_pos.x, from_pos.y, "")
	game_state.set_piece_at(to_pos.x, to_pos.y, piece)
	move_piece(from_tile, to_tile, piece)

# --- Visual helpers ---

func move_piece(from_tile: ColorRect, to_tile: ColorRect, piece_code: String) -> void:
	if last_moved_tile and is_instance_valid(last_moved_tile):
		last_moved_tile.color = _get_tile_color(last_moved_tile)
	remove_piece_from_tile(to_tile)
	remove_piece_from_tile(from_tile)
	GameStateManager.disable_castling_rights_for(piece_code, from_tile.name)
	to_tile.color = COLOR_LAST_MOVE
	last_moved_tile = to_tile
	var sprite = piece_manager.create_piece_sprite(piece_code)
	to_tile.add_child(sprite)

func remove_piece_from_tile(tile: ColorRect) -> void:
	for child in tile.get_children():
		if child is TextureRect or child is Sprite2D:
			child.queue_free()

func _get_tile_color(tile: ColorRect) -> Color:
	var pos      = game_state.square_to_indices(tile.name)
	var is_light = (pos.x + pos.y) % 2 == 0
	var theme    = Globals.get_theme(RunState.run_number)
	return theme["tile_light"] if is_light else theme["tile_dark"]

# --- Promotion popup ---

func _on_promotion_selected(type: String) -> void:
	if not pending_promotion_tile:
		return
	var new_piece_code = pending_promotion_color + type
	for child in pending_promotion_tile.get_children():
		if child is TextureRect or child is Sprite2D:
			child.queue_free()
	var sprite = piece_manager.create_piece_sprite(new_piece_code)
	pending_promotion_tile.add_child(sprite)
	var pos = game_state.square_to_indices(pending_promotion_tile.name)
	game_state.set_piece_at(pos.x, pos.y, new_piece_code)
	pending_promotion_tile  = null
	pending_promotion_color = ""
	promotion_popup.hide_popup()
