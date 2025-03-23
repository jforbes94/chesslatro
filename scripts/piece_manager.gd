extends Node

class_name PieceManager

const TILE_SIZE = 64

@export var piece_theme: String = "alpha"

func place_starting_pieces(parent: Node, game_state: Node) -> void:
	var starting_positions = {
		"a2": "wp", "b2": "wp", "c2": "wp", "d2": "wp", "e2": "wp", "f2": "wp", "g2": "wp", "h2": "wp",
		"a7": "bp", "b7": "bp", "c7": "bp", "d7": "bp", "e7": "bp", "f7": "bp", "g7": "bp", "h7": "bp",
		"a1": "wr", "b1": "wn", "c1": "wb", "d1": "wq", "e1": "wk", "f1": "wb", "g1": "wn", "h1": "wr",
		"a8": "br", "b8": "bn", "c8": "bb", "d8": "bq", "e8": "bk", "f8": "bb", "g8": "bn", "h8": "br",
	}

	for square_name in starting_positions.keys():
		var piece_code = starting_positions[square_name]
		var sprite := create_piece_sprite(piece_code)
		var tile := parent.get_node_or_null(square_name)
		if tile:
			tile.add_child(sprite)

			# Update game state
			var coords: Vector2i = game_state.square_to_indices(square_name)
			game_state.set_piece_at(coords.x, coords.y, piece_code)

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
	return sprite
