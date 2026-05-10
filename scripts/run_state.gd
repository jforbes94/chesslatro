extends Node

var game_difficulty:   String = ""
var run_number:        int    = 1
var current_level:     int    = 1
var current_phase:     String = "puzzle"
var earned_powerups:   Array  = []
var gold:              int    = 0
var gold_earned:       int    = 0
var boss_moves:        int    = 0

# Map state
var puzzles_solved:    int        = 0
var consecutive_fails: int        = 0
var map_layout:        Array      = []   # Array of floor arrays
var map_floor:         int        = 0   # Current floor index
var map_current_node:  Dictionary = {}  # Node being played
var map_available:     Array      = []  # Available node indices in current floor

# Persistent army — survives all runs
var army: Dictionary = {
	"a1": "wr", "b1": "wn", "c1": "wb", "d1": "wq",
	"e1": "wk", "f1": "wb", "g1": "wn", "h1": "wr",
	"a2": "wp", "b2": "wp", "c2": "wp", "d2": "wp",
	"e2": "wp", "f2": "wp", "g2": "wp", "h2": "wp",
}

const BLACK_STANDARD: Dictionary = {
	"a8": "br", "b8": "bn", "c8": "bb", "d8": "bq",
	"e8": "bk", "f8": "bb", "g8": "bn", "h8": "br",
	"a7": "bp", "b7": "bp", "c7": "bp", "d7": "bp",
	"e7": "bp", "f7": "bp", "g7": "bp", "h7": "bp",
}

func reset_run() -> void:
	current_level     = 1
	current_phase     = "puzzle"
	gold              = 0
	gold_earned       = 0
	boss_moves        = 0
	puzzles_solved    = 0
	consecutive_fails = 0
	map_layout.clear()
	map_floor         = 0
	map_current_node  = {}
	map_available.clear()
	earned_powerups.clear()
	# army and run_number intentionally preserved
