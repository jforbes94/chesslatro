extends Node2D

const TILE_SIZE = 64
const BOARD_SIZE = 8

const PieceManager = preload("res://scripts/piece_manager.gd")
const MovementManager = preload("res://scripts/movement_manager.gd")
const GameStateManager = preload("res://scripts/game_state_manager.gd")

@onready var piece_manager = PieceManager.new()
@onready var movement_manager = MovementManager.new()
@onready var game_state = GameStateManager.new()

func _ready() -> void:
	draw_board()
	game_state.initialize_empty_board()
	piece_manager.place_starting_pieces($BoardTiles, game_state)
	movement_manager.set_game_state(game_state)
	movement_manager.set_board_root($BoardTiles)
	movement_manager.set_promotion_popup($UI/PromotionPopup)
	set_process_input(true)
	print("✅ ChessBoard is ready")
	print("🏁 ChessBoard _ready(): Scene running:", get_tree().current_scene.name)


# DEBUG: Print all UI nodes and force them transparent to input
	for child in $UI.get_children():
		if child is Control:
			print("🧽 Forcing mouse_filter IGNORE on:", child.name)
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for sub in child.get_children():
				if sub is Control:
					print("   ↳ Sub-node:", sub.name)
					sub.mouse_filter = Control.MOUSE_FILTER_IGNORE

func draw_board() -> void:
	for rank in range(BOARD_SIZE):
		for file in range(BOARD_SIZE):
			var tile := ColorRect.new()
			var is_white := (rank + file) % 2 == 0
			tile.color = Color.WHITE if is_white else Color.GRAY

			tile.size = Vector2(TILE_SIZE, TILE_SIZE)
			tile.position = Vector2(file * TILE_SIZE, rank * TILE_SIZE)
			tile.visible = true
			tile.focus_mode = Control.FOCUS_ALL
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow clicks to pass through to parent

			var tile_name = "%s%s" % [char(97 + file), str(8 - rank)]
			tile.name = tile_name

			var label := Label.new()
			label.text = tile_name
			label.position = Vector2(4, 4)
			label.set("theme_override_colors/font_color", Color.BLACK if is_white else Color.WHITE)
			label.set("theme_override_font_sizes/font_size", 10)
			tile.add_child(label)

			$BoardTiles.add_child(tile)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = get_global_mouse_position()
		var file = int(world_pos.x / TILE_SIZE)
		var rank = int(world_pos.y / TILE_SIZE)

		if file >= 0 and file < BOARD_SIZE and rank >= 0 and rank < BOARD_SIZE:
			var tile_name = "%s%s" % [char(97 + file), str(8 - rank)]
			var tile = $BoardTiles.get_node_or_null(tile_name)
			if tile:
				print("🖱️ Clicked tile:", tile_name)
				movement_manager.handle_tile_click(tile)
