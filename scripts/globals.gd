class_name Globals

const TILE_SIZE        = 80
const COLOR_TILE_LIGHT = Color(0.95, 0.94, 0.88)
const COLOR_TILE_DARK  = Color(0.72, 0.60, 0.44)

const PIECE_CP = {
	"p": 100, "n": 300, "b": 300, "r": 500, "q": 900,
}

const UPGRADE_OPTIONS = [
	{"type": "n", "name": "Knight", "cost": 2},
	{"type": "b", "name": "Bishop", "cost": 2},
	{"type": "r", "name": "Rook",   "cost": 4},
	{"type": "q", "name": "Queen",  "cost": 8},
]

const THEMES = {
	"jungle": {
		"kingdom":     "The Verdant Realm",
		"boss":        "The Vine King",
		"tile_light":  Color(0.76, 0.88, 0.58),
		"tile_dark":   Color(0.18, 0.38, 0.14),
		"border":      Color(0.18, 0.10, 0.03),
		"background":  Color(0.05, 0.10, 0.04),
		"hud_bg":      Color(0.06, 0.14, 0.05, 0.95),
		"accent":      Color(0.45, 0.85, 0.20),
		"overlay_bg":  Color(0.03, 0.08, 0.03, 0.92),
		"white_tint":  Color(0.95, 1.00, 0.82),
		"black_tint":  Color(0.22, 0.48, 0.14),
	},
	"ocean": {
		"kingdom":     "The Abyssal Kingdom",
		"boss":        "The Tide Sovereign",
		"tile_light":  Color(0.70, 0.88, 0.92),
		"tile_dark":   Color(0.10, 0.28, 0.55),
		"border":      Color(0.05, 0.10, 0.25),
		"background":  Color(0.03, 0.06, 0.16),
		"hud_bg":      Color(0.05, 0.10, 0.22, 0.95),
		"accent":      Color(0.20, 0.80, 0.95),
		"overlay_bg":  Color(0.02, 0.05, 0.14, 0.92),
		"white_tint":  Color(0.88, 0.96, 1.00),
		"black_tint":  Color(0.12, 0.32, 0.68),
	},
	"volcano": {
		"kingdom":     "The Magma Throne",
		"boss":        "The Ember King",
		"tile_light":  Color(0.82, 0.72, 0.62),
		"tile_dark":   Color(0.26, 0.09, 0.05),
		"border":      Color(0.75, 0.28, 0.04),
		"background":  Color(0.09, 0.03, 0.02),
		"hud_bg":      Color(0.18, 0.05, 0.02, 0.95),
		"accent":      Color(1.00, 0.42, 0.05),
		"overlay_bg":  Color(0.10, 0.03, 0.01, 0.92),
		"white_tint":  Color(1.00, 0.92, 0.80),
		"black_tint":  Color(0.40, 0.10, 0.04),
	},
}

const DIFFICULTY_TIERS = {
	"easy":   ["beginner", "intermediate", "advanced"],
	"medium": ["club", "expert", "master"],
	"hard":   ["master", "grandmaster", "elite"],
}

const TIER_DATA = {
	"beginner":    {"reward": 1, "penalty": 0, "label": "Novice"},
	"intermediate":{"reward": 2, "penalty": 1, "label": "Apprentice"},
	"advanced":    {"reward": 3, "penalty": 1, "label": "Advanced"},
	"club":        {"reward": 2, "penalty": 0, "label": "Club"},
	"expert":      {"reward": 3, "penalty": 1, "label": "Expert"},
	"master":      {"reward": 4, "penalty": 2, "label": "Master"},
	"grandmaster": {"reward": 5, "penalty": 2, "label": "Grandmaster"},
	"elite":       {"reward": 6, "penalty": 3, "label": "Elite"},
}

static func get_theme(run_number: int) -> Dictionary:
	if run_number <= 1:
		return THEMES["jungle"]
	elif run_number == 2:
		return THEMES["ocean"]
	else:
		return THEMES["volcano"]

static func get_theme_key(run_number: int) -> String:
	if run_number <= 1:
		return "jungle"
	elif run_number == 2:
		return "ocean"
	else:
		return "volcano"
