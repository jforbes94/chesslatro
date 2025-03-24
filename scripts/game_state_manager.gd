extends Node
class_name GameStateManager

var board_state: Array = []

var white_kingside_castling: bool = true
var white_queenside_castling: bool = true
var black_kingside_castling: bool = true
var black_queenside_castling: bool = true

var en_passant_target: Vector2i = Vector2i(-1, -1)

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
	if delta_rank <= 1 and delta_file <= 1 and (delta_rank != 0 or delta_file != 0):
		var target_piece = get_piece_at(to.x, to.y)
		if target_piece == "" or target_piece[0] != piece_code[0]:
			return true

	if delta_rank == 0 and delta_file == 2:
		if piece_code[0] == "w":
			if to == Vector2i(7, 6):
				if not white_kingside_castling:
					return false
				if get_piece_at(7, 5) == "" and get_piece_at(7, 6) == "" and get_piece_at(7, 7) == "wr":
					return true
			elif to == Vector2i(7, 2):
				if not white_queenside_castling:
					return false
				if get_piece_at(7, 3) == "" and get_piece_at(7, 2) == "" and get_piece_at(7, 1) == "" and get_piece_at(7, 0) == "wr":
					return true
		elif piece_code[0] == "b":
			if to == Vector2i(0, 6):
				if not black_kingside_castling:
					return false
				if get_piece_at(0, 5) == "" and get_piece_at(0, 6) == "" and get_piece_at(0, 7) == "br":
					return true
			elif to == Vector2i(0, 2):
				if not black_queenside_castling:
					return false
				if get_piece_at(0, 3) == "" and get_piece_at(0, 2) == "" and get_piece_at(0, 1) == "" and get_piece_at(0, 0) == "br":
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
