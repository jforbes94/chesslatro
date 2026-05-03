extends Node

var game_difficulty:   String = ""   # "easy" | "medium" | "hard" — set on start screen
var current_level:     int    = 1
var current_phase:     String = "puzzle"  # "puzzle" or "boss"
var puzzles_solved:    int    = 0
var puzzles_attempted: int    = 0
var earned_powerups:   Array  = []
var gold:              int    = 0

# Persistent army — survives across all runs, never reset
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
	puzzles_solved    = 0
	puzzles_attempted = 0
	gold              = 0
	earned_powerups.clear()
	# army intentionally preserved
