class_name Globals

const TILE_SIZE       = 80
const COLOR_TILE_LIGHT = Color(0.95, 0.94, 0.88)
const COLOR_TILE_DARK  = Color(0.72, 0.60, 0.44)

# Centipawn values — used to price upgrades: cost = (piece_cp - pawn_cp) / 100
const PIECE_CP = {
	"p": 100,
	"n": 300,
	"b": 300,
	"r": 500,
	"q": 900,
}

const UPGRADE_OPTIONS = [
	{"type": "n", "name": "Knight", "cost": 2},
	{"type": "b", "name": "Bishop", "cost": 2},
	{"type": "r", "name": "Rook",   "cost": 4},
	{"type": "q", "name": "Queen",  "cost": 8},
]
