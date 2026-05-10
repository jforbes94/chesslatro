extends Node

const SAVE_PATH = "user://chesslatro_stats.json"

var total_attempted: int = 0
var total_solved:    int = 0
var by_tier:         Dictionary = {}  # tier -> {attempted, solved}
var by_category:     Dictionary = {}  # theme -> {attempted, solved}

func _ready() -> void:
	load_stats()

func record_attempt(themes: Array, tier: String, solved: bool) -> void:
	total_attempted += 1
	if solved:
		total_solved += 1

	if tier != "":
		if not by_tier.has(tier):
			by_tier[tier] = {"attempted": 0, "solved": 0}
		by_tier[tier]["attempted"] += 1
		if solved:
			by_tier[tier]["solved"] += 1

	for theme in themes:
		if theme == "" or theme in ["short", "long", "veryLong", "oneMove"]:
			continue
		if not by_category.has(theme):
			by_category[theme] = {"attempted": 0, "solved": 0}
		by_category[theme]["attempted"] += 1
		if solved:
			by_category[theme]["solved"] += 1

	save_stats()

func win_pct(attempted: int, solved: int) -> String:
	if attempted == 0:
		return "—"
	return "%.1f%%" % (solved * 100.0 / attempted)

func reset() -> void:
	total_attempted = 0
	total_solved    = 0
	by_tier.clear()
	by_category.clear()
	save_stats()

func save_stats() -> void:
	var data = {
		"total_attempted": total_attempted,
		"total_solved":    total_solved,
		"by_tier":         by_tier,
		"by_category":     by_category,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_stats() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data:
		return
	total_attempted = data.get("total_attempted", 0)
	total_solved    = data.get("total_solved",    0)
	by_tier         = data.get("by_tier",         {})
	by_category     = data.get("by_category",     {})
