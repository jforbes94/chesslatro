extends Node

# Enemy (Black) piece sets per level.
# King must always be on e8 for standard FEN compatibility.
# White always uses the standard full starting army.

const LEVELS = {
	1: {
		"name": "Scout Force",
		"black": {
			"e8": "bk",
			"c7": "bp", "d7": "bp", "e7": "bp", "f7": "bp",
			"b8": "bn",
		}
	},
	2: {
		"name": "Raiding Party",
		"black": {
			"e8": "bk",
			"b7": "bp", "c7": "bp", "d7": "bp", "e7": "bp", "f7": "bp", "g7": "bp",
			"h8": "br",
			"c8": "bb",
			"g8": "bn",
		}
	},
	3: {
		"name": "Full Army",
		"black": {
			"a8": "br", "b8": "bn", "c8": "bb", "d8": "bq", "e8": "bk", "f8": "bb", "g8": "bn", "h8": "br",
			"a7": "bp", "b7": "bp", "c7": "bp", "d7": "bp", "e7": "bp", "f7": "bp", "g7": "bp", "h7": "bp",
		}
	},
}

const WHITE_STANDARD = {
	"a1": "wr", "b1": "wn", "c1": "wb", "d1": "wq", "e1": "wk", "f1": "wb", "g1": "wn", "h1": "wr",
	"a2": "wp", "b2": "wp", "c2": "wp", "d2": "wp", "e2": "wp", "f2": "wp", "g2": "wp", "h2": "wp",
}

static func get_starting_positions(level: int) -> Dictionary:
	var black = LEVELS[level]["black"] if LEVELS.has(level) else LEVELS[3]["black"]
	var combined = WHITE_STANDARD.duplicate()
	for square in black:
		combined[square] = black[square]
	return combined

static func get_level_name(level: int) -> String:
	return LEVELS[level]["name"] if LEVELS.has(level) else "Unknown"
