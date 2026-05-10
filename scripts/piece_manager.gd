extends Node

class_name PieceManager

const TILE_SIZE = Globals.TILE_SIZE

@export var piece_theme: String = "alpha"

var white_tint: Color = Color.WHITE
var black_tint: Color = Color.WHITE

func set_tints(w_tint: Color, b_tint: Color) -> void:
	white_tint = w_tint
	black_tint = b_tint

func place_starting_pieces(parent: Node, game_state: Node, starting_positions: Dictionary = {}) -> void:
	if starting_positions.is_empty():
		starting_positions = LevelConfig.get_starting_positions(RunState.current_level)

	if not "h8" in starting_positions or starting_positions["h8"] != "br":
		GameStateManager.black_kingside_castling = false
	if not "a8" in starting_positions or starting_positions["a8"] != "br":
		GameStateManager.black_queenside_castling = false

	for square_name in starting_positions.keys():
		var piece_code = starting_positions[square_name]
		var sprite := create_piece_sprite(piece_code)
		var tile := parent.get_node_or_null(square_name)
		if tile:
			tile.add_child(sprite)
			var coords: Vector2i = game_state.square_to_indices(square_name)
			game_state.set_piece_at(coords.x, coords.y, piece_code)

func place_pieces_from_board_state(parent: Node, game_state: Node) -> void:
	for rank in range(8):
		for file in range(8):
			var piece_code = game_state.get_piece_at(rank, file)
			if piece_code == "":
				continue
			var square_name = game_state.indices_to_square_name(rank, file)
			var tile = parent.get_node_or_null(square_name)
			if tile:
				tile.add_child(create_piece_sprite(piece_code))

func create_piece_sprite(piece_code: String) -> TextureRect:
	var sprite := TextureRect.new()
	var path := "res://assets/pieces/%s/%s.png" % [piece_theme, piece_code]

	var texture := load(path)
	if not texture:
		push_error("Missing piece art: %s" % path)
		return sprite

	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	sprite.modulate = white_tint if piece_code.begins_with("w") else black_tint
	return sprite
