extends Node

var current_turn := "w"
var white_kingside_castling := true
var white_queenside_castling := true
var black_kingside_castling := true
var black_queenside_castling := true
var en_passant_square := "-"

var board_state: Array = []
var en_passant_target: Vector2i = Vector2i(-1, -1)

func _ready():
	initialize_empty_board()

# for translating my piece codes to stockfish
const FEN_MAP = {
	"wp": "P", "wr": "R", "wn": "N", "wb": "B", "wq": "Q", "wk": "K",
	"bp": "p", "br": "r", "bn": "n", "bb": "b", "bq": "q", "bk": "k"
}


func initialize_empty_board() -> void:
	board_state.clear()
	for _i in 8:
		var row := []
		for _j in 8:
			row.append("")
		board_state.append(row)

func set_piece_at(rank: int, file: int, piece_code: String) -> void:
	board_state[rank][file] = piece_code

func get_piece_at(rank: int, file: int) -> String:
	return board_state[rank][file]

func square_to_indices(square: String) -> Vector2i:
	var file := square.unicode_at(0) - 'a'.unicode_at(0)
	var rank := 8 - int(square.substr(1, 1))
	return Vector2i(rank, file)
	
func indices_to_square_name(row: int, col: int) -> String:
	var file = char('a'.unicode_at(0) + col)
	var rank = str(8 - row)
	return file + rank

func is_valid_pawn_move(from: Vector2i, to: Vector2i, piece_code: String) -> bool:
	if piece_code.length() != 2 or piece_code[1] != "p":
		return false

	var direction = -1 if piece_code[0] == "w" else 1
	var start_rank = 6 if piece_code[0] == "w" else 1

	var delta_rank = to.x - from.x
	var delta_file = to.y - from.y

	# Forward move
	if delta_file == 0:
		if delta_rank == direction and get_piece_at(to.x, to.y) == "":
			return true
		if delta_rank == 2 * direction and from.x == start_rank:
			var between = from + Vector2i(direction, 0)
			if get_piece_at(between.x, between.y) == "" and get_piece_at(to.x, to.y) == "":
				en_passant_target = between
				return true

	# Diagonal capture
	if delta_rank == direction and abs(delta_file) == 1:
		var target_piece = get_piece_at(to.x, to.y)
		if target_piece != "" and target_piece[0] != piece_code[0]:
			return true

		# En passant capture
		if to == en_passant_target:
			var captured_pawn_square = Vector2i(from.x, to.y)
			var target = get_piece_at(captured_pawn_square.x, captured_pawn_square.y)
			if target != "" and target[0] != piece_code[0] and target[1] == "p":
				return true

	return false

func is_valid_knight_move(from: Vector2i, to: Vector2i, piece_code: String) -> bool:
	var delta_rank = abs(to.x - from.x)
	var delta_file = abs(to.y - from.y)
	if (delta_rank == 2 and delta_file == 1) or (delta_rank == 1 and delta_file == 2):
		var target_piece = get_piece_at(to.x, to.y)
		if target_piece == "" or target_piece[0] != piece_code[0]:
			return true
	return false

func remove_piece_at(rank: int, file: int) -> void:
	set_piece_at(rank, file, "")

func is_valid_bishop_move(from: Vector2i, to: Vector2i, piece_code: String) -> bool:
	var delta_rank = to.x - from.x
	var delta_file = to.y - from.y
	if abs(delta_rank) != abs(delta_file) or delta_rank == 0:
		return false


	var step_rank = delta_rank / abs(delta_rank)
	var step_file = delta_file / abs(delta_file)

	var current = from + Vector2i(step_rank, step_file)
	while current != to:
		if get_piece_at(current.x, current.y) != "":
			return false
		current += Vector2i(step_rank, step_file)

	var target_piece = get_piece_at(to.x, to.y)
	if target_piece == "" or target_piece[0] != piece_code[0]:
		return true

	return false

func is_valid_rook_move(from: Vector2i, to: Vector2i, piece_code: String) -> bool:
	var delta_rank = to.x - from.x
	var delta_file = to.y - from.y

	if delta_rank != 0 and delta_file != 0:
		return false

	var step_rank = 0
	var step_file = 0

	if delta_rank != 0:
		step_rank = delta_rank / abs(delta_rank)
	if delta_file != 0:
		step_file = delta_file / abs(delta_file)

	var current = from + Vector2i(step_rank, step_file)
	while current != to:
		if get_piece_at(current.x, current.y) != "":
			return false
		current += Vector2i(step_rank, step_file)

	var target_piece = get_piece_at(to.x, to.y)
	if target_piece == "" or target_piece[0] != piece_code[0]:
		return true

	return false

func is_valid_queen_move(from: Vector2i, to: Vector2i, piece_code: String) -> bool:
	if is_valid_bishop_move(from, to, piece_code) or is_valid_rook_move(from, to, piece_code):
		return true
	return false

func is_valid_king_move(from: Vector2i, to: Vector2i, piece_code: String) -> bool:
	var delta_rank = abs(to.x - from.x)
	var delta_file = abs(to.y - from.y)

	# Normal king move (1 square in any direction)
	if delta_rank <= 1 and delta_file <= 1 and (delta_rank != 0 or delta_file != 0):
		var target_piece = get_piece_at(to.x, to.y)
		if target_piece == "" or target_piece[0] != piece_code[0]:
			return true

	# Castling
	if delta_rank == 0 and delta_file == 2:
		var color = piece_code[0]
		var row = from.x

		var kingside = to.y > from.y
		var rook_col = 7 if kingside else 0
		var mid_col_1 = from.y + 1 if kingside else from.y - 1
		var mid_col_2 = from.y + 2 if kingside else from.y - 2
		var rook_code = color + "r"
		var castling_flag = false

		if color == "w":
			if kingside:
				castling_flag = white_kingside_castling
			else:
				castling_flag = white_queenside_castling
		else:
			if kingside:
				castling_flag = black_kingside_castling
			else:
				castling_flag = black_queenside_castling

		if not castling_flag:
			return false

		# Check pieces and path
		var rook_piece = get_piece_at(row, rook_col)
		if rook_piece != rook_code:
			return false

		var path_clear = true
		for col in range(min(from.y, rook_col) + 1, max(from.y, rook_col)):
			if get_piece_at(row, col) != "":
				path_clear = false
				break

		if not path_clear:
			return false

		# 🧠 Prevent castling through or into check
		if is_king_in_check(color):
			print("cannot Castle with King in Check")
			return false
		if does_square_threaten_king(Vector2i(row, mid_col_1), color):
			print("Cannot Castle, interrim square threatened")
			return false
		if does_square_threaten_king(Vector2i(row, mid_col_2), color):
			print("Cannot Castle, final square threatened")
			return false

		return true

	return false

	


func disable_castling_rights_for(piece_code: String, square: String) -> void:
	if piece_code == "wk":
		white_kingside_castling = false
		white_queenside_castling = false
	elif piece_code == "bk":
		black_kingside_castling = false
		black_queenside_castling = false
	elif piece_code == "wr":
		if square == "h1":
			white_kingside_castling = false
		elif square == "a1":
			white_queenside_castling = false
	elif piece_code == "br":
		if square == "h8":
			black_kingside_castling = false
		elif square == "a8":
			black_queenside_castling = false

func is_king_in_check(color: String) -> bool:
	var king_pos := Vector2i(-1, -1)

	# 1. Find the king
	for row in range(8):
		for col in range(8):
			var piece = board_state[row][col]
			if piece == color + "k":
				king_pos = Vector2i(row, col)
				break

	if king_pos == Vector2i(-1, -1):
		print("⚠️ King not found for color:", color)
		return false

	# 2. See if any opponent piece can move to the king
	for row in range(8):
		for col in range(8):
			var piece = board_state[row][col]
			if piece != "" and not piece.begins_with(color):
				if does_piece_threaten(piece, Vector2i(row, col), king_pos):
					return true

	return false
	
	
func does_piece_threaten(piece_code: String, from: Vector2i, to: Vector2i) -> bool:
	match piece_code[1]:
		"p":
			return is_valid_pawn_move(from, to, piece_code)
		"n":
			return is_valid_knight_move(from, to, piece_code)
		"b":
			return is_valid_bishop_move(from, to, piece_code)
		"r":
			return is_valid_rook_move(from, to, piece_code)
		"q":
			return is_valid_queen_move(from, to, piece_code)
		"k":
			return is_valid_king_move(from, to, piece_code)
		_:
			return false

# Specific Castling Check logic. 
func does_square_threaten_king(pos: Vector2i, color: String) -> bool:
	print("checking for Check in Castling")
	# Simulate king on the square and check if opponent could attack it
	for row in range(8):
		for col in range(8):
			var piece = board_state[row][col]
			if piece != "" and not piece.begins_with(color):
				if does_piece_threaten(piece, Vector2i(row, col), pos):
					return true
	return false

#helper function for Stalemate and Checkmate function
func has_legal_move(color: String) -> bool:
	for row in range(8):
		for col in range(8):
			var piece = board_state[row][col]
			if piece != "" and piece.begins_with(color):
				var from := Vector2i(row, col)

				for to_row in range(8):
					for to_col in range(8):
						var to := Vector2i(to_row, to_col)

						if does_piece_threaten(piece, from, to):
							# Simulate move
							var captured = board_state[to.x][to.y]
							board_state[from.x][from.y] = ""
							board_state[to.x][to.y] = piece

							var still_in_check = is_king_in_check(color)

							# Undo move
							board_state[from.x][from.y] = piece
							board_state[to.x][to.y] = captured

							if not still_in_check:
								return true
	return false

func is_checkmate(color: String) -> bool:
	if not is_king_in_check(color):
		return false
	return not has_legal_move(color)

	
func is_stalemate(color: String) -> bool:
	if is_king_in_check(color):
		return false
	return not has_legal_move(color)
	
func board_state_to_fen() -> String:
	var fen := ""

	for row in board_state:
		var empty_count := 0
		for cell in row:
			if cell == "":
				empty_count += 1
			else:
				if empty_count > 0:
					fen += str(empty_count)
					empty_count = 0
				fen += _piece_code_to_fen(cell)
		if empty_count > 0:
			fen += str(empty_count)
		fen += "/"

	fen = fen.substr(0, fen.length() - 1)  # Remove trailing "/"

	var turn = GameStateManager.current_turn
	var castling_rights = get_fen_castling_rights_fen()
	var en_passant = GameStateManager.en_passant_square

	fen += " %s %s %s" % [turn, castling_rights, en_passant]

	return fen


func _piece_code_to_fen(code: String) -> String:
	if FEN_MAP.has(code):
		return FEN_MAP[code]
	return ""
	
func get_fen_castling_rights_fen() -> String:
	var rights := ""
	if white_kingside_castling:
		rights += "K"
	if white_queenside_castling:
		rights += "Q"
	if black_kingside_castling:
		rights += "k"
	if black_queenside_castling:
		rights += "q"
	if rights == "":
		rights = "-"
	return rights
