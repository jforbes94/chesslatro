extends Node2D

const TILE_SIZE  = Globals.TILE_SIZE
const BOARD_SIZE = 8

const COLOR_LIGHT = Globals.COLOR_TILE_LIGHT
const COLOR_DARK  = Globals.COLOR_TILE_DARK
const COLOR_GOLD  = Color(1.0,  0.84, 0.0)
const COLOR_BTN   = Color(0.45, 0.33, 0.12)

const PieceManager    = preload("res://scripts/piece_manager.gd")
const MovementManager = preload("res://scripts/movement_manager.gd")

@onready var piece_manager    = PieceManager.new()
@onready var movement_manager = $MovementManager

var level_label:    Label
var turn_label:     Label
var progress_label: Label
var gold_label:     Label

var overlay:       ColorRect
var overlay_label: Label
var next_button:   Button

var store_overlay:    ColorRect
var store_gold_label: Label
var store_content:    VBoxContainer

var current_puzzle_difficulty: String = "medium"
var difficulty_overlay: ColorRect
var main_menu_overlay:  ColorRect
var run_end_overlay:    ColorRect
var run_end_label:      Label
var settings_panel:     ColorRect

# Timers
var puzzle_timer_active: bool  = false
var puzzle_time_left:    float = 15.0
var boss_timer_active:   bool  = false
var boss_time_left:      float = 180.0  # 3 minutes
const BOSS_INCREMENT:    float = 2.0
var timer_label:         Label

func _ready() -> void:
	_add_border()
	draw_board()
	movement_manager.set_game_state(GameStateManager)
	movement_manager.set_piece_manager(piece_manager)
	set_process_input(true)
	_build_hud()
	_build_store_overlay()
	_build_difficulty_screen()
	_build_run_end_overlay()
	_build_main_menu()
	movement_manager.match_over.connect(_on_match_over)
	movement_manager.wrong_move.connect(_on_wrong_move)
	movement_manager.puzzle_complete.connect(_on_puzzle_complete)
	movement_manager.puzzle_failed.connect(_on_puzzle_failed)
	movement_manager.white_moved.connect(_on_white_moved)
	print("✅ ChessBoard ready")

# --- Border ---

func _add_border() -> void:
	var board_px    = TILE_SIZE * BOARD_SIZE
	var border_size = 16
	var border      = ColorRect.new()
	border.color    = Color(0.16, 0.10, 0.05)
	border.position = Vector2(-border_size, -border_size)
	border.size     = Vector2(board_px + border_size * 2, board_px + border_size * 2)
	border.z_index  = -1
	add_child(border)

# --- Button styling ---

func _style_button(btn: Button, color: Color = COLOR_BTN) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var s = StyleBoxFlat.new()
		s.bg_color = color.lightened(0.1) if state == "hover" else \
					 color.darkened(0.15) if state == "pressed" else \
					 color.darkened(0.3)  if state == "disabled" else color
		s.set_corner_radius_all(6)
		s.content_margin_left   = 14
		s.content_margin_right  = 14
		s.content_margin_top    = 8
		s.content_margin_bottom = 8
		btn.add_theme_stylebox_override(state, s)
	btn.add_theme_color_override("font_color",         Color.WHITE)
	btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color",Color(0.6, 0.6, 0.6))

# --- Main Menu ---

func _build_main_menu() -> void:
	var board_px = TILE_SIZE * BOARD_SIZE
	var cx       = board_px / 2

	main_menu_overlay = ColorRect.new()
	main_menu_overlay.color       = Color(0.05, 0.05, 0.10, 0.98)
	main_menu_overlay.position    = Vector2(0, 0)
	main_menu_overlay.size        = Vector2(board_px, board_px)
	main_menu_overlay.z_index     = 60
	main_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(main_menu_overlay)

	var title = Label.new()
	title.text = "ChessLatro"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.position = Vector2(cx - 145, 80)
	main_menu_overlay.add_child(title)

	var tagline = Label.new()
	tagline.text = "Solve. Upgrade. Conquer."
	tagline.add_theme_font_size_override("font_size", 15)
	tagline.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	tagline.position = Vector2(cx - 100, 148)
	main_menu_overlay.add_child(tagline)

	var new_run_btn = Button.new()
	new_run_btn.text     = "New Run"
	new_run_btn.size     = Vector2(240, 58)
	new_run_btn.position = Vector2(cx - 120, 230)
	new_run_btn.pressed.connect(_on_main_menu_new_run)
	_style_button(new_run_btn, Color(0.18, 0.48, 0.18))
	main_menu_overlay.add_child(new_run_btn)

	var settings_btn = Button.new()
	settings_btn.text     = "Settings"
	settings_btn.size     = Vector2(240, 48)
	settings_btn.position = Vector2(cx - 120, 304)
	settings_btn.pressed.connect(_on_main_menu_settings)
	_style_button(settings_btn, Color(0.28, 0.28, 0.38))
	main_menu_overlay.add_child(settings_btn)

	# Settings panel (hidden by default)
	settings_panel = ColorRect.new()
	settings_panel.color    = Color(0.10, 0.10, 0.18, 0.98)
	settings_panel.position = Vector2(cx - 160, 370)
	settings_panel.size     = Vector2(320, 180)
	settings_panel.visible  = false
	main_menu_overlay.add_child(settings_panel)

	var settings_title = Label.new()
	settings_title.text = "Settings"
	settings_title.add_theme_font_size_override("font_size", 16)
	settings_title.add_theme_color_override("font_color", COLOR_GOLD)
	settings_title.position = Vector2(12, 10)
	settings_panel.add_child(settings_title)

	var info_lines = [
		"Puzzle timer:    15 seconds per puzzle",
		"Boss timer:      3 minutes + 2s per move",
		"Puzzle mode:     Strict (exact solution required)",
		"AI strength:     Depth 10, top-3 random pick",
		"Army upgrades:   Persist across all runs",
	]
	var y = 40
	for line in info_lines:
		var lbl = Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		lbl.position = Vector2(12, y)
		settings_panel.add_child(lbl)
		y += 22

	var version_lbl = Label.new()
	version_lbl.text = "ChessLatro — 2026"
	version_lbl.add_theme_font_size_override("font_size", 10)
	version_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	version_lbl.position = Vector2(cx - 60, board_px - 36)
	main_menu_overlay.add_child(version_lbl)

func _on_main_menu_new_run() -> void:
	_hide(main_menu_overlay)
	_show(difficulty_overlay)

func _on_main_menu_settings() -> void:
	settings_panel.visible = not settings_panel.visible

# --- Run End Overlay ---

func _build_run_end_overlay() -> void:
	var board_px = TILE_SIZE * BOARD_SIZE

	run_end_overlay = ColorRect.new()
	run_end_overlay.color       = Color(0.04, 0.04, 0.08, 0.92)
	run_end_overlay.position    = Vector2(0, 0)
	run_end_overlay.size        = Vector2(board_px, board_px)
	run_end_overlay.z_index     = 45
	run_end_overlay.visible     = false
	run_end_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(run_end_overlay)

	run_end_label = Label.new()
	run_end_label.add_theme_font_size_override("font_size", 15)
	run_end_label.add_theme_color_override("font_color", Color.WHITE)
	run_end_label.position    = Vector2(board_px / 2 - 160, board_px / 2 - 130)
	run_end_label.size        = Vector2(320, 200)
	run_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_end_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	run_end_overlay.add_child(run_end_label)

	var play_again_btn = Button.new()
	play_again_btn.size     = Vector2(210, 50)
	play_again_btn.position = Vector2(board_px / 2 - 110, board_px / 2 + 80)
	play_again_btn.text     = "Play Again →"
	play_again_btn.pressed.connect(_on_run_end_play_again)
	_style_button(play_again_btn, Color(0.18, 0.48, 0.18))
	run_end_overlay.add_child(play_again_btn)

	var menu_btn = Button.new()
	menu_btn.size     = Vector2(210, 40)
	menu_btn.position = Vector2(board_px / 2 - 110, board_px / 2 + 140)
	menu_btn.text     = "Main Menu"
	menu_btn.pressed.connect(_on_run_end_main_menu)
	_style_button(menu_btn, Color(0.28, 0.28, 0.38))
	run_end_overlay.add_child(menu_btn)

func _show_run_end(won: bool) -> void:
	var upgrades = RunState.army.values().filter(func(p): return p != "wp" and p[1] != "k" and p[1] != "r" and p[1] != "n" and p[1] != "b" or true).size()
	var non_standard = 0
	var default_army = ["wr","wn","wb","wq","wk","wb","wn","wr","wp","wp","wp","wp","wp","wp","wp","wp"]
	for piece in RunState.army.values():
		if not piece in default_army:
			non_standard += 1

	if won:
		RunState.run_number += 1
		run_end_label.add_theme_color_override("font_color", COLOR_GOLD)
		run_end_label.text = (
			"Victory!\n\n" +
			"Run %d Complete\n\n" % (RunState.run_number - 1) +
			"Puzzles Solved:   %d / 5\n" % RunState.puzzles_solved +
			"Gold Earned:      %d\n" % RunState.gold_earned +
			"Army Upgrades:    %d\n" % non_standard +
			"Boss Moves:       %d\n\n" % RunState.boss_moves +
			"Your army grows stronger..."
		)
	else:
		run_end_label.add_theme_color_override("font_color", Color.WHITE)
		run_end_label.text = (
			"Defeated.\n\n" +
			"Run %d\n\n" % RunState.run_number +
			"Puzzles Solved:   %d / 5\n" % RunState.puzzles_solved +
			"Gold Earned:      %d\n" % RunState.gold_earned +
			"Boss Moves:       %d\n\n" % RunState.boss_moves +
			"Better luck next time."
		)

	$BoardTiles.modulate = Color(0.55, 0.55, 0.55)
	run_end_overlay.modulate.a = 0.0
	run_end_overlay.visible    = true
	run_end_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(run_end_overlay, "modulate:a", 1.0, 0.3)

func _on_run_end_play_again() -> void:
	run_end_overlay.visible      = false
	run_end_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$BoardTiles.modulate         = Color.WHITE
	RunState.reset_run()
	_reset_board()
	_load_puzzle()
	_refresh_hud()

func _on_run_end_main_menu() -> void:
	run_end_overlay.visible      = false
	run_end_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$BoardTiles.modulate         = Color.WHITE
	RunState.reset_run()
	_reset_board()
	_refresh_hud()
	_show(main_menu_overlay)

# --- Timers ---

func _process(delta: float) -> void:
	if puzzle_timer_active:
		puzzle_time_left -= delta
		timer_label.text = "⏱  %ds" % ceili(puzzle_time_left)
		if puzzle_time_left <= 5.0:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)
		if puzzle_time_left <= 0.0:
			puzzle_timer_active = false
			timer_label.text = "⏱  0s"
			_on_puzzle_failed(null)

	elif boss_timer_active and GameStateManager.current_turn == "w":
		boss_time_left -= delta
		var mins = int(boss_time_left) / 60
		var secs = int(boss_time_left) % 60
		timer_label.text = "⏱  %d:%02d" % [mins, secs]
		if boss_time_left <= 30.0:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)
		if boss_time_left <= 0.0:
			boss_timer_active = false
			timer_label.text = "⏱  0:00"
			_show_run_end(false)

func _on_white_moved() -> void:
	if boss_timer_active:
		boss_time_left = minf(boss_time_left + BOSS_INCREMENT, 180.0)
		RunState.boss_moves += 1

func _start_puzzle_timer() -> void:
	puzzle_time_left  = 15.0
	puzzle_timer_active = true
	timer_label.add_theme_color_override("font_color", Color.WHITE)

func _stop_puzzle_timer() -> void:
	puzzle_timer_active = false
	timer_label.text = ""

func _start_boss_timer() -> void:
	boss_time_left    = 180.0
	boss_timer_active = true
	timer_label.add_theme_color_override("font_color", Color.WHITE)

func _stop_boss_timer() -> void:
	boss_timer_active = false
	timer_label.text = ""

# --- Difficulty selection screen ---

func _build_difficulty_screen() -> void:
	var board_px = TILE_SIZE * BOARD_SIZE
	var cx       = board_px / 2

	difficulty_overlay = ColorRect.new()
	difficulty_overlay.color    = Color(0.07, 0.07, 0.12, 0.97)
	difficulty_overlay.position = Vector2(0, 0)
	difficulty_overlay.size     = Vector2(board_px, board_px)
	difficulty_overlay.z_index  = 50
	difficulty_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(difficulty_overlay)

	var title = Label.new()
	title.text = "ChessLatro"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.position = Vector2(cx - 130, 80)
	difficulty_overlay.add_child(title)

	var sub = Label.new()
	sub.text = "Select Difficulty"
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	sub.position = Vector2(cx - 68, 148)
	difficulty_overlay.add_child(sub)

	var difficulties = [
		{"key": "easy",   "label": "Easy",   "desc": "Puzzles rated 600–1500\n+$1–$2 per solve",  "color": Color(0.18, 0.48, 0.18)},
		{"key": "medium", "label": "Medium", "desc": "Puzzles rated 1300–2200\n+$1–$2 per solve", "color": Color(0.55, 0.38, 0.08)},
		{"key": "hard",   "label": "Hard",   "desc": "Puzzles rated 2000–2600+\n+$1–$2 per solve","color": Color(0.55, 0.12, 0.12)},
	]

	var y = 210
	for d in difficulties:
		var btn = Button.new()
		btn.text     = d["label"]
		btn.size     = Vector2(230, 50)
		btn.position = Vector2(cx - 115, y)
		btn.pressed.connect(_select_difficulty.bind(d["key"]))
		_style_button(btn, d["color"])
		difficulty_overlay.add_child(btn)

		var desc = Label.new()
		desc.text = d["desc"]
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		desc.position = Vector2(cx - 115, y + 54)
		difficulty_overlay.add_child(desc)

		y += 128

func _select_difficulty(difficulty: String) -> void:
	RunState.game_difficulty = difficulty
	PuzzleManager.load_for_difficulty(difficulty)
	_hide(difficulty_overlay)
	_load_puzzle()

# --- HUD ---

func _build_hud() -> void:
	var board_px  = TILE_SIZE * BOARD_SIZE
	var hud_x     = board_px + 8
	var panel_w   = 180

	# Background panel
	var hud_panel = ColorRect.new()
	hud_panel.color    = Color(0.10, 0.10, 0.15, 0.92)
	hud_panel.position = Vector2(hud_x, 0)
	hud_panel.size     = Vector2(panel_w, 160)
	add_child(hud_panel)

	# Gold accent stripe on left edge
	var stripe = ColorRect.new()
	stripe.color    = COLOR_GOLD
	stripe.position = Vector2(hud_x, 0)
	stripe.size     = Vector2(3, 160)
	add_child(stripe)

	level_label = Label.new()
	level_label.position = Vector2(hud_x + 12, 8)
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", COLOR_GOLD)
	add_child(level_label)

	turn_label = Label.new()
	turn_label.position = Vector2(hud_x + 12, 38)
	turn_label.add_theme_font_size_override("font_size", 13)
	turn_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(turn_label)

	progress_label = Label.new()
	progress_label.position = Vector2(hud_x + 12, 62)
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	add_child(progress_label)

	gold_label = Label.new()
	gold_label.position = Vector2(hud_x + 12, 86)
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.add_theme_color_override("font_color", COLOR_GOLD)
	add_child(gold_label)

	timer_label = Label.new()
	timer_label.position = Vector2(hud_x + 12, 116)
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(timer_label)

	# Result overlay
	overlay = ColorRect.new()
	overlay.color = Color(0.04, 0.04, 0.08, 0.88)
	overlay.size = Vector2(board_px, board_px)
	overlay.position = Vector2.ZERO
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	overlay_label = Label.new()
	overlay_label.add_theme_font_size_override("font_size", 30)
	overlay_label.add_theme_color_override("font_color", Color.WHITE)
	overlay_label.position = Vector2(board_px / 2 - 160, board_px / 2 - 80)
	overlay_label.size = Vector2(320, 100)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	overlay.add_child(overlay_label)

	next_button = Button.new()
	next_button.size = Vector2(210, 50)
	next_button.position = Vector2(board_px / 2 - 105, board_px / 2 + 30)
	next_button.pressed.connect(_on_next_pressed)
	_style_button(next_button)
	overlay.add_child(next_button)

	_refresh_hud()

func _refresh_hud() -> void:
	if RunState.current_phase == "puzzle":
		level_label.text    = "Level %d" % RunState.current_level
		turn_label.text     = "White to Play"
		progress_label.text = "Puzzle %d / 5" % RunState.puzzles_attempted
		gold_label.text     = "◆  %d gold" % RunState.gold
	else:
		level_label.text    = "Boss Fight"
		turn_label.text     = ""
		progress_label.text = "%d power up(s)" % RunState.earned_powerups.size()
		gold_label.text     = "◆  %d gold" % RunState.gold

# --- Store overlay ---

func _build_store_overlay() -> void:
	var board_px = TILE_SIZE * BOARD_SIZE

	store_overlay = ColorRect.new()
	store_overlay.color = Color(0.06, 0.06, 0.10, 0.96)
	store_overlay.size = Vector2(board_px, board_px)
	store_overlay.position = Vector2.ZERO
	store_overlay.visible = false
	store_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(store_overlay)

	var title = Label.new()
	title.text = "Upgrade Store"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.position = Vector2(board_px / 2 - 110, 24)
	store_overlay.add_child(title)

	store_gold_label = Label.new()
	store_gold_label.add_theme_font_size_override("font_size", 16)
	store_gold_label.add_theme_color_override("font_color", COLOR_GOLD)
	store_gold_label.position = Vector2(board_px / 2 - 60, 68)
	store_overlay.add_child(store_gold_label)

	var divider = Label.new()
	divider.text = "Pawn Upgrades  —  $2 each"
	divider.add_theme_font_size_override("font_size", 13)
	divider.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	divider.position = Vector2(board_px / 2 - 105, 100)
	store_overlay.add_child(divider)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 124)
	scroll.size = Vector2(board_px - 40, board_px - 210)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	store_overlay.add_child(scroll)

	store_content = VBoxContainer.new()
	store_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	store_content.add_theme_constant_override("separation", 8)
	scroll.add_child(store_content)

	var fight_btn = Button.new()
	fight_btn.text = "Fight Boss →"
	fight_btn.size = Vector2(210, 50)
	fight_btn.position = Vector2(board_px / 2 - 105, board_px - 68)
	fight_btn.pressed.connect(_start_boss_phase)
	_style_button(fight_btn, Color(0.55, 0.12, 0.12))
	store_overlay.add_child(fight_btn)

func _show_store() -> void:
	store_gold_label.text = "◆  %d gold available" % RunState.gold

	for child in store_content.get_children():
		child.queue_free()

	var upgradeable_pawns = RunState.army.keys().filter(
		func(sq): return RunState.army[sq] == "wp"
	)

	if upgradeable_pawns.is_empty():
		var lbl = Label.new()
		lbl.text = "No pawns left to upgrade."
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		store_content.add_child(lbl)
	else:
		var btn_colors = {
			"n": Color(0.28, 0.18, 0.48),
			"b": Color(0.18, 0.38, 0.55),
			"r": Color(0.45, 0.28, 0.10),
			"q": Color(0.55, 0.38, 0.08),
		}
		for sq in upgradeable_pawns:
			var pawn_label = Label.new()
			pawn_label.text = "Pawn at %s" % sq.to_upper()
			pawn_label.add_theme_font_size_override("font_size", 13)
			pawn_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			store_content.add_child(pawn_label)

			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)

			for opt in Globals.UPGRADE_OPTIONS:
				var cost = _upgrade_cost(sq, opt["type"])
				var btn = Button.new()
				btn.text     = "%s  $%d" % [opt["name"], cost]
				btn.disabled = RunState.gold < cost
				btn.pressed.connect(_upgrade_pawn.bind(sq, opt["type"]))
				_style_button(btn, btn_colors[opt["type"]])
				row.add_child(btn)

			store_content.add_child(row)

			var spacer = ColorRect.new()
			spacer.color = Color(0.3, 0.3, 0.3, 0.4)
			spacer.custom_minimum_size = Vector2(0, 1)
			store_content.add_child(spacer)

	_show(store_overlay)

func _upgrade_cost(square: String, piece_type: String) -> int:
	var base = 0
	for opt in Globals.UPGRADE_OPTIONS:
		if opt["type"] == piece_type:
			base = opt["cost"]
			break

	# File modifier: central = +1, semi-central = 0, flank = -1
	var file_mod = 0
	match square[0]:
		"d", "e": file_mod =  1
		"c", "f": file_mod =  0
		_:         file_mod = -1

	# Rank modifier: advanced pawn = higher cost
	var rank     = int(square[1])
	var rank_mod = 2 if rank >= 5 else (1 if rank >= 3 else 0)

	return max(1, base + file_mod + rank_mod)

func _upgrade_pawn(square: String, piece_type: String) -> void:
	var cost = _upgrade_cost(square, piece_type)
	if RunState.gold < cost:
		return
	RunState.gold -= cost
	RunState.army[square] = "w" + piece_type
	print("⬆️ %s → w%s  ($%d spent, %d gold left)" % [square, piece_type, cost, RunState.gold])
	_refresh_hud()
	call_deferred("_show_store")

# --- Puzzle loading ---

func _load_puzzle() -> void:
	var puzzle = PuzzleManager.get_puzzle_for_level(RunState.current_level)
	if puzzle.is_empty():
		push_error("No puzzle for level %d" % RunState.current_level)
		return
	var moves: Array = puzzle["moves"]
	if moves.size() < 2:
		push_error("Puzzle %s has too few moves" % puzzle["id"])
		return
	print("🧩 Puzzle %s  rating=%d  difficulty=%s" % [puzzle["id"], puzzle["rating"], puzzle.get("difficulty", "?")])
	current_puzzle_difficulty = puzzle.get("difficulty", "medium")

	GameStateManager.load_from_fen(puzzle["fen"])
	piece_manager.place_pieces_from_board_state($BoardTiles, GameStateManager)
	movement_manager.apply_setup_move(moves[0])
	movement_manager.start_puzzle(moves.slice(1))
	_start_puzzle_timer()
	_refresh_hud()

# --- Signals ---

func _on_wrong_move(tile: ColorRect) -> void:
	var original_pos   = tile.position
	var original_color = _default_tile_color(tile.name)
	tile.color = Color(0.85, 0.18, 0.18)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(tile, "position", original_pos + Vector2(7, 0),  0.06)
	tween.tween_property(tile, "position", original_pos - Vector2(7, 0),  0.06)
	tween.tween_property(tile, "position", original_pos + Vector2(4, 0),  0.05)
	tween.tween_property(tile, "position", original_pos,                  0.05)
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(tile):
		tile.color = original_color

func _on_puzzle_complete() -> void:
	_stop_puzzle_timer()
	RunState.puzzles_solved    += 1
	RunState.puzzles_attempted += 1
	var reward = 2 if current_puzzle_difficulty == "expert" else 1
	RunState.gold        += reward
	RunState.gold_earned += reward
	RunState.earned_powerups.append("Extra Knight")

	overlay_label.text = "Puzzle Cleared!\n+%d Gold  (Total: %d)" % [reward, RunState.gold]
	next_button.text   = "Visit Store →" if RunState.puzzles_attempted >= 5 else "Next Puzzle →"
	_style_button(next_button, Color(0.18, 0.48, 0.18) if RunState.puzzles_attempted < 5 else COLOR_BTN)
	_show(overlay)
	_refresh_hud()

func _on_puzzle_failed(_tile) -> void:
	_stop_puzzle_timer()
	RunState.puzzles_attempted += 1
	await get_tree().create_timer(0.5).timeout
	overlay_label.text = "Puzzle Failed\n+0 Gold"
	next_button.text   = "Visit Store →" if RunState.puzzles_attempted >= 5 else "Next Puzzle →"
	_style_button(next_button)
	_show(overlay)
	_refresh_hud()

func _on_match_over(result: String) -> void:
	_stop_boss_timer()
	var won = result.begins_with("checkmate_w") or result == "stalemate"
	_show_run_end(won)

func _on_next_pressed() -> void:
	_hide(overlay)
	if RunState.puzzles_attempted >= 5:
		_show_store()
	else:
		_reset_board()
		_load_puzzle()

# --- Phase transitions ---

func _start_boss_phase() -> void:
	_hide(store_overlay)
	RunState.current_phase = "boss"
	movement_manager.start_boss()
	_clear_board()

	GameStateManager.initialize_empty_board()
	GameStateManager.current_turn            = "w"
	GameStateManager.white_kingside_castling  = true
	GameStateManager.white_queenside_castling = true
	GameStateManager.black_kingside_castling  = true
	GameStateManager.black_queenside_castling = true
	GameStateManager.en_passant_square = "-"
	GameStateManager.en_passant_target = Vector2i(-1, -1)

	for sq in RunState.BLACK_STANDARD:
		var coords = GameStateManager.square_to_indices(sq)
		GameStateManager.set_piece_at(coords.x, coords.y, RunState.BLACK_STANDARD[sq])

	for sq in RunState.army:
		var coords = GameStateManager.square_to_indices(sq)
		GameStateManager.set_piece_at(coords.x, coords.y, RunState.army[sq])

	piece_manager.place_pieces_from_board_state($BoardTiles, GameStateManager)
	movement_manager.selected_tile   = null
	movement_manager.last_moved_tile = null
	_start_boss_timer()
	_refresh_hud()

# --- Overlay helpers ---

func _show(panel: ColorRect) -> void:
	panel.modulate.a = 0.0
	panel.visible    = true
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	$BoardTiles.modulate = Color(0.55, 0.55, 0.55)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)

func _hide(panel: ColorRect) -> void:
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not overlay.visible and not store_overlay.visible and not difficulty_overlay.visible:
		$BoardTiles.modulate = Color.WHITE

# --- Board helpers ---

func _reset_board() -> void:
	# Clear lingering tile highlights before nulling references
	if is_instance_valid(movement_manager.selected_tile):
		movement_manager.selected_tile.color = _default_tile_color(movement_manager.selected_tile.name)
	if is_instance_valid(movement_manager.last_moved_tile):
		movement_manager.last_moved_tile.color = _default_tile_color(movement_manager.last_moved_tile.name)
	movement_manager.selected_tile   = null
	movement_manager.last_moved_tile = null
	_stop_puzzle_timer()
	_stop_boss_timer()
	_clear_board()
	GameStateManager.initialize_empty_board()
	GameStateManager.current_turn            = "w"
	GameStateManager.white_kingside_castling  = true
	GameStateManager.white_queenside_castling = true
	GameStateManager.black_kingside_castling  = true
	GameStateManager.black_queenside_castling = true
	GameStateManager.en_passant_square = "-"
	GameStateManager.en_passant_target = Vector2i(-1, -1)

func _clear_board() -> void:
	for tile in $BoardTiles.get_children():
		for child in tile.get_children():
			if child is TextureRect or child is Sprite2D:
				child.queue_free()
		tile.color = _default_tile_color(tile.name)

func _default_tile_color(tile_name: String) -> Color:
	var pos = GameStateManager.square_to_indices(tile_name)
	return Globals.COLOR_TILE_LIGHT if (pos.x + pos.y) % 2 == 0 else Globals.COLOR_TILE_DARK

# --- Board drawing ---

func draw_board() -> void:
	for rank in range(BOARD_SIZE):
		for file in range(BOARD_SIZE):
			var tile     := ColorRect.new()
			var is_white := (rank + file) % 2 == 0
			tile.color = COLOR_LIGHT if is_white else COLOR_DARK
			tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			tile.size     = Vector2(TILE_SIZE, TILE_SIZE)
			tile.position = Vector2(file * TILE_SIZE, rank * TILE_SIZE)
			tile.visible    = true
			tile.focus_mode = Control.FOCUS_ALL

			var tile_name = "%s%s" % [char(97 + file), str(8 - rank)]
			tile.name = tile_name
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

			$BoardTiles.add_child(tile)

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if overlay.visible or store_overlay.visible or difficulty_overlay.visible:
		return

	var vp_pos    = get_viewport().get_mouse_position()
	var world_pos = get_canvas_transform().affine_inverse() * vp_pos

	var tile_col = int(world_pos.x / TILE_SIZE)
	var tile_row = int(world_pos.y / TILE_SIZE)

	if tile_col < 0 or tile_col >= BOARD_SIZE or tile_row < 0 or tile_row >= BOARD_SIZE:
		return

	var tile_name = "%s%s" % [char(97 + tile_col), str(8 - tile_row)]
	var tile = $BoardTiles.get_node_or_null(tile_name)
	if tile:
		movement_manager.handle_tile_click(tile)
