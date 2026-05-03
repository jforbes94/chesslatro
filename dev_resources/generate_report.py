from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.enums import TA_LEFT, TA_CENTER

doc = SimpleDocTemplate(
    "dev_resources/ChessLatro_Report.pdf",
    pagesize=A4,
    rightMargin=2*cm, leftMargin=2*cm,
    topMargin=2*cm, bottomMargin=2*cm
)

styles = getSampleStyleSheet()

title_style = ParagraphStyle('Title', parent=styles['Title'], fontSize=24, textColor=colors.HexColor('#1a1a2e'), spaceAfter=6)
subtitle_style = ParagraphStyle('Subtitle', parent=styles['Normal'], fontSize=12, textColor=colors.HexColor('#555'), spaceAfter=20, alignment=TA_CENTER)
h1_style = ParagraphStyle('H1', parent=styles['Heading1'], fontSize=16, textColor=colors.HexColor('#16213e'), spaceBefore=16, spaceAfter=6)
h2_style = ParagraphStyle('H2', parent=styles['Heading2'], fontSize=12, textColor=colors.HexColor('#0f3460'), spaceBefore=10, spaceAfter=4)
body_style = ParagraphStyle('Body', parent=styles['Normal'], fontSize=10, leading=16, spaceAfter=6)
code_style = ParagraphStyle('Code', parent=styles['Code'], fontSize=8, leading=12, backColor=colors.HexColor('#f4f4f4'), leftIndent=12, spaceAfter=6)
bullet_style = ParagraphStyle('Bullet', parent=styles['Normal'], fontSize=10, leading=14, leftIndent=16, spaceAfter=3, bulletIndent=6)

def h1(text): return Paragraph(text, h1_style)
def h2(text): return Paragraph(text, h2_style)
def body(text): return Paragraph(text, body_style)
def bullet(text): return Paragraph(f"• {text}", bullet_style)
def code(text): return Paragraph(text, code_style)
def space(n=8): return Spacer(1, n)
def hr(): return HRFlowable(width="100%", thickness=1, color=colors.HexColor('#cccccc'), spaceAfter=8)

content = []

# Title
content.append(space(10))
content.append(Paragraph("ChessLatro", title_style))
content.append(Paragraph("Technical Overview — How the Project Works", subtitle_style))
content.append(hr())
content.append(space(4))

# Overview
content.append(h1("Project Overview"))
content.append(body(
    "ChessLatro is a fully playable chess game built with the <b>Godot 4.4</b> game engine. "
    "It supports all standard chess rules and uses the <b>Stockfish</b> chess engine as an AI opponent. "
    "The game is written in <b>GDScript</b> for game logic, with a <b>C#</b> wrapper to interface with Stockfish. "
    "The player controls White; Black is handled automatically by Stockfish at search depth 10."
))
content.append(space())

# Tech Stack table
content.append(h2("Tech Stack"))
stack_data = [
    ["Component", "Technology"],
    ["Game Engine", "Godot 4.4"],
    ["Primary Language", "GDScript"],
    ["AI Bridge", "C# (.NET 8.0)"],
    ["Chess AI", "Stockfish (external process)"],
    ["Rendering", "Forward Plus renderer"],
    ["Art Assets", "PNG sprites (alpha theme)"],
]
t = Table(stack_data, colWidths=[5*cm, 10*cm])
t.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#16213e')),
    ('TEXTCOLOR', (0,0), (-1,0), colors.white),
    ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
    ('FONTSIZE', (0,0), (-1,-1), 9),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#f0f4ff')]),
    ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#cccccc')),
    ('PADDING', (0,0), (-1,-1), 6),
]))
content.append(t)
content.append(space())

# Architecture
content.append(h1("Architecture & File Structure"))
content.append(body("The project is split into six GDScript files and one C# file, each with a clear responsibility:"))
content.append(space(4))

files_data = [
    ["File", "Role"],
    ["scripts/game_state_manager.gd", "Autoloaded singleton — owns all board state and move validation"],
    ["scripts/chess_board.gd", "Main scene — draws the 8x8 board and routes tile click events"],
    ["scripts/movement_manager.gd", "Handles user input, executes moves, triggers AI, manages turn flow"],
    ["scripts/piece_manager.gd", "Places starting pieces and creates piece sprites from PNG assets"],
    ["scripts/promotion_popup.gd", "Pawn promotion UI — emits signal with chosen piece type"],
    ["scripts/camera_controller.gd", "Scales the viewport/camera to fit the board responsively"],
    ["StockfishInterface.cs", "C# class — spawns Stockfish process, sends FEN, returns best move"],
]
t2 = Table(files_data, colWidths=[7*cm, 9*cm])
t2.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#0f3460')),
    ('TEXTCOLOR', (0,0), (-1,0), colors.white),
    ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
    ('FONTSIZE', (0,0), (-1,-1), 8.5),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#f0f4ff')]),
    ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#cccccc')),
    ('PADDING', (0,0), (-1,-1), 6),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
]))
content.append(t2)
content.append(space())

# Game State Manager
content.append(h1("1. Game State Manager (game_state_manager.gd)"))
content.append(body(
    "This is the central brain of the game, registered as a Godot <b>Autoload singleton</b> called "
    "<b>GameStateManager</b>. It is accessible from every other script without needing a reference."
))
content.append(h2("What it stores"))
for item in [
    "board_state — an 8x8 array of piece codes (e.g. 'wp', 'bk', '' for empty)",
    "current_turn — 'w' or 'b'",
    "Castling rights — four booleans (white/black x kingside/queenside)",
    "en_passant_target — Vector2i of the square a pawn can capture via en passant",
    "move_log — array of all moves played",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("Piece Code Format"))
content.append(body("Pieces are identified by a two-character string: <b>[color][type]</b>"))
content.append(code("'w' = white,  'b' = black"))
content.append(code("'p'=pawn  'n'=knight  'b'=bishop  'r'=rook  'q'=queen  'k'=king"))
content.append(code("Examples:  'wp' = white pawn,  'bk' = black king,  'wq' = white queen"))
content.append(space(4))

content.append(h2("Move Validation"))
content.append(body("Each piece type has its own validation function:"))
for item in [
    "is_valid_pawn_move — handles forward moves, double-step from start rank, diagonal captures, and en passant",
    "is_valid_knight_move — checks L-shaped offsets (2+1 or 1+2)",
    "is_valid_bishop_move — walks diagonals, fails if any piece is in the way",
    "is_valid_rook_move — walks ranks/files, fails if any piece blocks the path",
    "is_valid_queen_move — delegates to bishop + rook validators",
    "is_valid_king_move — one square any direction, plus castling (2-square move with rook)",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("Check, Checkmate & Stalemate"))
content.append(body(
    "is_king_in_check scans every opponent piece and tests whether it can attack the king's square. "
    "has_legal_move simulates every possible move for a color, temporarily applies it to board_state, "
    "checks if the king is still in check, then reverts — returning True if any safe move exists. "
    "Checkmate = in check + no legal moves. Stalemate = not in check + no legal moves."
))
content.append(space(4))

content.append(h2("FEN Generation"))
content.append(body(
    "board_state_to_fen converts the internal board array into a FEN string, which is the universal "
    "chess position format used to communicate with Stockfish. It encodes piece positions, active color, "
    "castling rights, and en passant target square."
))

# Chess Board
content.append(h1("2. Chess Board (chess_board.gd)"))
content.append(body(
    "The main scene script. On startup it calls draw_board() to create 64 ColorRect nodes (one per square), "
    "naming each one with its algebraic coordinate (e.g. 'e4', 'h8'). Each tile is 80x80 pixels, "
    "colored white or gray based on (rank + file) % 2. Tile click signals are connected here and "
    "forwarded to MovementManager."
))

# Movement Manager
content.append(h1("3. Movement Manager (movement_manager.gd)"))
content.append(body("Handles all interactive gameplay. The main flow on a tile click:"))
for item in [
    "First click — if the tile has a piece belonging to the current turn, select it (highlight gold)",
    "Second click — validate the move using GameStateManager validators + is_move_safe (king safety check)",
    "If valid — update board_state, move the sprite visually, handle special cases",
    "Call end_turn() — evaluate board state, switch current_turn, trigger AI if it is Black's turn",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("Special Move Handling"))
for item in [
    "Castling — detected when king moves 2 squares; rook is also moved in board_state and visually",
    "En passant — captured pawn is removed from its actual square (not the destination square)",
    "Promotion — pawn reaching rank 1 (white) or rank 8 (black) triggers the promotion popup",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("is_move_safe"))
content.append(body(
    "Before committing any move, the manager simulates it on board_state, calls is_king_in_check, "
    "then reverts. This prevents players from making moves that leave their own king in check."
))

# Stockfish
content.append(h1("4. Stockfish Integration (StockfishInterface.cs)"))
content.append(body(
    "A C# class decorated with [GlobalClass] so Godot treats it as a native node. "
    "When it is Black's turn, MovementManager calls GetBestMove(fen):"
))
for item in [
    "Spawns a new Stockfish process with stdin/stdout redirected",
    "Sends: position fen <FEN string>",
    "Sends: go depth 10  (searches 10 moves deep)",
    "Reads output lines until one starts with 'bestmove'",
    "Parses and returns the move string (e.g. 'e7e5', 'e8g8' for castling, 'e7e8q' for promotion)",
    "Sends 'quit' and waits for the process to exit",
]:
    content.append(bullet(item))
content.append(space(4))
content.append(body(
    "The returned move string is in UCI format (from-square + to-square + optional promotion piece). "
    "apply_stockfish_move in MovementManager parses this string and applies it to the board."
))

# Piece Manager
content.append(h1("5. Piece Manager (piece_manager.gd)"))
content.append(body(
    "Handles visual representation of pieces. place_starting_pieces sets up the standard chess starting "
    "position by placing PNG sprites on tiles and updating GameStateManager's board_state. "
    "create_piece_sprite loads the correct PNG from res://assets/pieces/alpha/<piece_code>.png "
    "and returns a scaled TextureRect sized to fit the 80px tile."
))

# Turn Flow
content.append(h1("6. Turn Flow Diagram"))
content.append(body("A complete turn cycle from player click to AI response:"))
steps = [
    ("1. Player clicks a tile", "chess_board.gd routes to movement_manager.handle_tile_click()"),
    ("2. Piece selected", "Tile highlighted gold; waiting for destination click"),
    ("3. Destination clicked", "Validators check move legality + king safety"),
    ("4. Move applied", "board_state updated, sprite moved, special cases handled"),
    ("5. end_turn() called", "evaluate_board_state() checks check/checkmate/stalemate"),
    ("6. Turn switches to Black", "call_deferred('_make_ai_move') scheduled"),
    ("7. FEN generated", "board_state_to_fen() produces current position string"),
    ("8. Stockfish called", "GetBestMove(fen) runs Stockfish at depth 10"),
    ("9. AI move applied", "apply_stockfish_move() parses UCI string, updates board"),
    ("10. end_turn() called again", "evaluates state, switches back to White"),
]
flow_data = [["Step", "What Happens"]] + [[s, d] for s, d in steps]
t3 = Table(flow_data, colWidths=[4.5*cm, 11.5*cm])
t3.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#16213e')),
    ('TEXTCOLOR', (0,0), (-1,0), colors.white),
    ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
    ('FONTSIZE', (0,0), (-1,-1), 8.5),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#f0f4ff')]),
    ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#cccccc')),
    ('PADDING', (0,0), (-1,-1), 6),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
]))
content.append(t3)
content.append(space())

# Known Notes
content.append(h1("7. Notes & Known Quirks"))
for item in [
    "Checkmate/stalemate is detected and printed to console but there is no in-game UI for it yet",
    "Stockfish spawns a new process on every move — no persistent engine session",
    "Black castling validation is kept as redundant safety even though Stockfish handles it",
    "The promotion popup blocks all input while visible (mouse_filter = IGNORE on the board)",
    "piece_manager.place_starting_pieces has several commented-out debug position variants",
    "move_log is tracked but not currently used for display or replay",
]:
    content.append(bullet(item))

content.append(space(20))
content.append(hr())
content.append(Paragraph("Generated automatically from ChessLatro source — 2026", subtitle_style))

doc.build(content)
print("PDF saved to dev_resources/ChessLatro_Report.pdf")
