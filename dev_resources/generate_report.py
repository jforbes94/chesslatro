from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.enums import TA_CENTER

doc = SimpleDocTemplate(
    "dev_resources/ChessLatro_Report.pdf",
    pagesize=A4,
    rightMargin=2*cm, leftMargin=2*cm,
    topMargin=2*cm, bottomMargin=2*cm
)

styles = getSampleStyleSheet()
title_style   = ParagraphStyle('T',  parent=styles['Title'],   fontSize=26, textColor=colors.HexColor('#1a1a2e'), spaceAfter=6)
sub_style     = ParagraphStyle('S',  parent=styles['Normal'],  fontSize=12, textColor=colors.HexColor('#555'), spaceAfter=20, alignment=TA_CENTER)
h1_style      = ParagraphStyle('H1', parent=styles['Heading1'],fontSize=16, textColor=colors.HexColor('#16213e'), spaceBefore=16, spaceAfter=6)
h2_style      = ParagraphStyle('H2', parent=styles['Heading2'],fontSize=12, textColor=colors.HexColor('#0f3460'), spaceBefore=10, spaceAfter=4)
body_style    = ParagraphStyle('B',  parent=styles['Normal'],  fontSize=10, leading=16, spaceAfter=6)
bullet_style  = ParagraphStyle('BL', parent=styles['Normal'],  fontSize=10, leading=14, leftIndent=16, spaceAfter=3)
code_style    = ParagraphStyle('C',  parent=styles['Code'],    fontSize=8,  leading=12, backColor=colors.HexColor('#f4f4f4'), leftIndent=12, spaceAfter=6)

def h1(t): return Paragraph(t, h1_style)
def h2(t): return Paragraph(t, h2_style)
def body(t): return Paragraph(t, body_style)
def bullet(t): return Paragraph(f"• {t}", bullet_style)
def code(t): return Paragraph(t, code_style)
def space(n=8): return Spacer(1, n)
def hr(): return HRFlowable(width="100%", thickness=1, color=colors.HexColor('#cccccc'), spaceAfter=8)

def table(data, col_widths):
    t = Table(data, colWidths=col_widths)
    t.setStyle(TableStyle([
        ('BACKGROUND',   (0,0), (-1,0),  colors.HexColor('#16213e')),
        ('TEXTCOLOR',    (0,0), (-1,0),  colors.white),
        ('FONTNAME',     (0,0), (-1,0),  'Helvetica-Bold'),
        ('FONTSIZE',     (0,0), (-1,-1), 9),
        ('ROWBACKGROUNDS',(0,1),(-1,-1), [colors.white, colors.HexColor('#f0f4ff')]),
        ('GRID',         (0,0), (-1,-1), 0.5, colors.HexColor('#cccccc')),
        ('PADDING',      (0,0), (-1,-1), 6),
        ('VALIGN',       (0,0), (-1,-1), 'TOP'),
    ]))
    return t

content = []

# Title
content.append(space(10))
content.append(Paragraph("ChessLatro", title_style))
content.append(Paragraph("Full Technical Overview — 2026", sub_style))
content.append(hr())
content.append(space(4))

# ── 1. PROJECT OVERVIEW ──────────────────────────────────────────────────────
content.append(h1("1. Project Overview"))
content.append(body(
    "ChessLatro is a <b>roguelite chess game</b> built with <b>Godot 4.4</b>. "
    "The player solves Lichess chess puzzles to earn gold, spends gold upgrading their army in a store, "
    "then fights a boss (Stockfish AI) with their upgraded pieces. "
    "The game is written in <b>GDScript</b> with a <b>C# (.NET 8)</b> bridge to the Fairy-Stockfish engine."
))
content.append(space(4))

content.append(table([
    ["Component", "Technology"],
    ["Game Engine", "Godot 4.4 (Forward Plus renderer)"],
    ["Primary Language", "GDScript"],
    ["AI Bridge", "C# (.NET 8.0) — StockfishInterface.cs"],
    ["Chess AI", "Fairy-Stockfish (UCI protocol, depth 10, MultiPV 3)"],
    ["Puzzle Source", "Lichess puzzle database (puzzles_easy/medium/hard.json)"],
    ["Art Assets", "PNG sprites — alpha piece theme"],
], [5*cm, 10*cm]))
content.append(space())

# ── 2. GAME LOOP ─────────────────────────────────────────────────────────────
content.append(h1("2. Game Loop"))
content.append(body("Each run follows this structure:"))
for item in [
    "Select difficulty (Easy / Medium / Hard) on the start screen",
    "Puzzle Phase — solve 5 chess puzzles (15 seconds each, strict solution required)",
    "Each puzzle solved earns gold ($1 for lower tiers, $2 for top tier)",
    "Upgrade Store — spend gold upgrading pawns to stronger pieces before the boss",
    "Boss Fight — play full chess against Fairy-Stockfish with your upgraded army (3+2 timer)",
    "Win the boss fight → run resets, army upgrades persist into the next run",
    "Lose or time out → try again",
]:
    content.append(bullet(item))
content.append(space())

# ── 3. FILE STRUCTURE ────────────────────────────────────────────────────────
content.append(h1("3. File Structure"))
content.append(table([
    ["File", "Role"],
    ["scripts/chess_board.gd",        "Main scene — board drawing, HUD, overlays, timers, input routing"],
    ["scripts/movement_manager.gd",   "Move validation, puzzle logic, scripted responses, Stockfish turns"],
    ["scripts/game_state_manager.gd", "Autoload — board state (8x8 array), FEN parsing, move validators"],
    ["scripts/run_state.gd",          "Autoload — persistent army, gold, phase, puzzle counters"],
    ["scripts/puzzle_manager.gd",     "Autoload — loads puzzle JSON, picks puzzles per level"],
    ["scripts/level_config.gd",       "Autoload — legacy level definitions (superseded by puzzle JSON)"],
    ["scripts/piece_manager.gd",      "Piece sprite creation, board setup from state"],
    ["scripts/globals.gd",            "Shared constants: TILE_SIZE, tile colors, upgrade options, piece CP values"],
    ["scripts/promotion_popup.gd",    "Pawn promotion UI — emits signal with chosen piece type"],
    ["scripts/camera_controller.gd",  "Viewport/camera scaling for responsive display"],
    ["StockfishInterface.cs",         "C# — spawns Fairy-Stockfish process, handles UCI, MultiPV, evaluation"],
    ["dev_resources/extract_puzzles.py", "One-time script — extracts 3x1000 puzzles from Lichess .zst database"],
    ["dev_resources/ROADMAP.md",      "Living feature roadmap with status tags"],
], [5.5*cm, 10.5*cm]))
content.append(space())

# ── 4. AUTOLOAD SINGLETONS ───────────────────────────────────────────────────
content.append(h1("4. Autoload Singletons"))

content.append(h2("GameStateManager"))
content.append(body("Central board state. Accessible from every script without a reference."))
for item in [
    "board_state — 8x8 array of piece codes (e.g. 'wp', 'bk', '' for empty)",
    "current_turn — 'w' or 'b'",
    "Castling rights — four booleans (white/black x kingside/queenside)",
    "en_passant_target — Vector2i for en passant square",
    "load_from_fen(fen) — parses any FEN string into board state + turn + castling + en passant",
    "board_state_to_fen() — converts board state back to FEN for Stockfish",
    "Move validators for all 6 piece types, check/checkmate/stalemate detection",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("RunState"))
content.append(body("Persistent run and army state. Army survives across runs; puzzle counters reset each run."))
for item in [
    "game_difficulty — 'easy', 'medium', or 'hard' (set on start screen)",
    "army — Dictionary of square→piece_code for white's persistent army",
    "current_phase — 'puzzle' or 'boss'",
    "puzzles_solved, puzzles_attempted — tracked per run",
    "gold — earned in puzzle phase, spent in store",
    "earned_powerups — list of upgrade labels (for future display)",
    "BLACK_STANDARD — const dictionary of black's standard starting army",
    "reset_run() — resets puzzle/phase/gold but NOT the army",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("PuzzleManager"))
content.append(body("Loads puzzle JSON and serves puzzles."))
for item in [
    "load_for_difficulty(difficulty) — loads puzzles_easy/medium/hard.json",
    "get_puzzle_for_level(level) — returns a random unused puzzle, cycles when exhausted",
    "Tracks used_ids to avoid repeats within a run",
]:
    content.append(bullet(item))
content.append(space())

# ── 5. PUZZLE PHASE ──────────────────────────────────────────────────────────
content.append(h1("5. Puzzle Phase (Strict Mode)"))
content.append(body(
    "Puzzles come from the Lichess database filtered to White-to-move positions "
    "(FEN active color = 'b', meaning Black made the last move and White responds). "
    "Each puzzle has a solution sequence in UCI format."
))
content.append(space(4))

content.append(h2("Puzzle Loading Flow"))
for item in [
    "Load FEN into GameStateManager via load_from_fen()",
    "Place pieces visually via piece_manager.place_pieces_from_board_state()",
    "Auto-play moves[0] (Black's setup move) via movement_manager.apply_setup_move()",
    "Pass moves[1:] to movement_manager.start_puzzle() as the solution sequence",
    "Start 15-second countdown timer",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("Puzzle Gameplay"))
for item in [
    "Player clicks a piece then a destination — input handled via _input() using canvas transform",
    "Move validated for chess legality (is_valid_move + is_move_safe)",
    "Move compared against solution_moves[solution_index] (first 4 chars = from+to square)",
    "Wrong move — tile shakes (tween), puzzle fails immediately, +0 gold",
    "Correct move — committed, solution_index advances",
    "Black's scripted response auto-plays from solution (0.3s delay)",
    "Puzzle complete when solution_index reaches end of solution array",
    "Timer reaches 0 — puzzle fails",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("Gold Rewards"))
content.append(table([
    ["Difficulty", "Tier", "Rating Range", "Reward"],
    ["Easy",   "Beginner",     "600–900",    "$1"],
    ["Easy",   "Intermediate", "900–1200",   "$1"],
    ["Easy",   "Advanced",     "1200–1500",  "$2"],
    ["Medium", "Club",         "1300–1600",  "$1"],
    ["Medium", "Expert",       "1600–1900",  "$1"],
    ["Medium", "Master",       "1900–2200",  "$2"],
    ["Hard",   "Master",       "2000–2300",  "$1"],
    ["Hard",   "Grandmaster",  "2300–2600",  "$1"],
    ["Hard",   "Elite",        "2600+",      "$2"],
], [3*cm, 3.5*cm, 3.5*cm, 2*cm]))
content.append(space())

# ── 6. UPGRADE STORE ─────────────────────────────────────────────────────────
content.append(h1("6. Upgrade Store"))
content.append(body(
    "After 5 puzzles, the store appears before the boss fight. "
    "Players spend gold upgrading pawns in RunState.army to stronger pieces. "
    "Upgrades persist across ALL runs — the army grows stronger each time."
))
content.append(space(4))

content.append(h2("Position-Based Upgrade Costs"))
content.append(body(
    "Cost = base_piece_cost + file_modifier + rank_modifier. "
    "Central advanced pawns cost more to upgrade because they are already more valuable."
))
content.append(table([
    ["Upgrade", "Base Cost", "File Modifier", "Rank Modifier", "Example Range"],
    ["→ Knight", "$2", "Center +1, Flank -1", "Rank 3-4: +1, Rank 5+: +2", "$1–$5"],
    ["→ Bishop", "$2", "Center +1, Flank -1", "Rank 3-4: +1, Rank 5+: +2", "$1–$5"],
    ["→ Rook",   "$4", "Center +1, Flank -1", "Rank 3-4: +1, Rank 5+: +2", "$3–$7"],
    ["→ Queen",  "$8", "Center +1, Flank -1", "Rank 3-4: +1, Rank 5+: +2", "$7–$11"],
], [2.5*cm, 2.5*cm, 3.5*cm, 4*cm, 3*cm]))
content.append(space())

# ── 7. BOSS FIGHT ────────────────────────────────────────────────────────────
content.append(h1("7. Boss Fight"))
content.append(body(
    "Standard chess vs Fairy-Stockfish. White uses RunState.army (with all upgrades). "
    "Black uses the standard full army. Player has a 3+2 chess clock."
))
for item in [
    "Board built from RunState.army (white) + RunState.BLACK_STANDARD (black)",
    "Fairy-Stockfish plays at depth 10 with MultiPV 3 — picks randomly from top 3 moves for unpredictability",
    "Player timer: 3 minutes base + 2 seconds added after each White move",
    "Timer counts down only on White's turn; pauses while Stockfish thinks",
    "Win: checkmate Stockfish — run resets, army retained",
    "Lose: get checkmated or time out — try again from boss fight",
]:
    content.append(bullet(item))
content.append(space())

# ── 8. FAIRY-STOCKFISH INTEGRATION ───────────────────────────────────────────
content.append(h1("8. Fairy-Stockfish Integration (StockfishInterface.cs)"))
content.append(body(
    "C# class decorated with [GlobalClass] so Godot treats it as a native node. "
    "Spawns a new process per move (stateless). Uses full UCI handshake."
))
content.append(h2("GetBestMove(fen) flow"))
for item in [
    "Spawn process → send 'uci' → wait for 'uciok'",
    "Send: setoption name UCI_Variant value chess",
    "Send: setoption name MultiPV value 3",
    "Send: isready → wait for 'readyok'",
    "Send: position fen <FEN>",
    "Send: go depth 10",
    "Parse 'info ... multipv N ... pv <move>' lines to collect top 3 candidate moves",
    "Pick randomly from candidates for unpredictability",
    "Parse score cp / score mate lines — store as LastScoreCentipawns (always White's perspective)",
    "Send 'quit', wait for exit",
]:
    content.append(bullet(item))
content.append(space())

# ── 9. INPUT SYSTEM ──────────────────────────────────────────────────────────
content.append(h1("9. Input System"))
content.append(body(
    "Board tiles are ColorRect (Control) nodes inside a Node2D scene with Camera2D. "
    "Control.gui_input doesn't work correctly with Camera2D canvas transforms, "
    "so all click handling is done via Node2D._input() using canvas transform math."
))
content.append(code("world_pos = get_canvas_transform().affine_inverse() * viewport_mouse_pos"))
content.append(code("tile_col = int(world_pos.x / TILE_SIZE)   tile_row = int(world_pos.y / TILE_SIZE)"))
content.append(body(
    "Clicks are ignored while any overlay (result, store, difficulty) is visible. "
    "Overlays use mouse_filter=STOP when shown and mouse_filter=IGNORE when hidden "
    "to prevent invisible panels from eating click events."
))
content.append(space())

# ── 10. VISUAL SYSTEM ────────────────────────────────────────────────────────
content.append(h1("10. Visual System"))
content.append(h2("Board"))
for item in [
    "Light tiles: Color(0.95, 0.94, 0.88) — warm cream",
    "Dark tiles: Color(0.72, 0.60, 0.44) — warm brown",
    "Border: 16px dark wood Color(0.16, 0.10, 0.05)",
    "Selected piece: gold highlight Color(1, 0.8, 0.2)",
    "Last moved tile: green highlight Color(0.4, 0.9, 0.4)",
    "Wrong move: red flash + tile shake tween (left-right bounce)",
    "Tile colors shared via Globals.COLOR_TILE_LIGHT/DARK to stay consistent across scripts",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("HUD (right of board)"))
for item in [
    "Dark panel with gold left-edge accent stripe",
    "Level label — gold color",
    "Turn label — white",
    "Puzzle progress — off-white (Puzzle X / 5)",
    "Gold counter — gold color with diamond icon (◆ X gold)",
    "Timer — white, turns red under 5s (puzzle) or 30s (boss)",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("Overlays"))
for item in [
    "All overlays fade in over 0.25s (cubic tween on modulate.a)",
    "Board dims to 55% brightness when any overlay is active",
    "All buttons use StyleBoxFlat with rounded corners and hover/press states",
    "Button colors: green=success, red=boss/fail, blue=bishop, purple=knight, orange=rook, gold=queen",
]:
    content.append(bullet(item))
content.append(space())

# ── 11. PUZZLE DATABASE ───────────────────────────────────────────────────────
content.append(h1("11. Puzzle Database"))
content.append(body(
    "Puzzles extracted from the Lichess open puzzle database (CC0 license). "
    "Run dev_resources/extract_puzzles.py once with the .zst file to generate the JSON files."
))
for item in [
    "Filter: FEN active color = 'b' (Black to move = White is the player)",
    "Sort by popularity score (highest first) to get best quality puzzles",
    "1000 puzzles per tier, 3 tiers per difficulty = 3000 puzzles per JSON file",
    "Each puzzle: id, fen, moves (UCI array), rating, popularity, themes, difficulty, reward",
    "moves[0] = Black's setup move (auto-played on load), moves[1:] = White's solution",
    "puzzles_easy/medium/hard.json are gitignored (regenerate from source)",
]:
    content.append(bullet(item))
content.append(space())

# ── 12. KNOWN ISSUES & NEXT STEPS ────────────────────────────────────────────
content.append(h1("12. Known Issues & Next Steps"))
content.append(h2("Known Issues"))
for item in [
    "Checkmate/stalemate detection prints to console only — no in-game UI yet for boss fight end",
    "Stockfish spawns a new process every move — no persistent session",
    "Power up system tracks count but doesn't yet apply specific effects in boss fight",
    "Board flip for Black-side puzzles not yet implemented",
]:
    content.append(bullet(item))
content.append(space(4))

content.append(h2("Roadmap Highlights (see ROADMAP.md for full list)"))
for item in [
    "Strict puzzle wrong-move penalty — currently fails immediately, may want N attempts",
    "Real power up effects — extra pieces, double move, resurrect, fog of war",
    "Board flip for puzzles where player is Black",
    "Boss difficulty scaling per run (increase Stockfish depth each run)",
    "Main menu scene, run summary screen",
    "Sound effects and animations",
]:
    content.append(bullet(item))

content.append(space(20))
content.append(hr())
content.append(Paragraph("Generated from ChessLatro source — 2026", sub_style))

doc.build(content)
print("PDF saved to dev_resources/ChessLatro_Report.pdf")
