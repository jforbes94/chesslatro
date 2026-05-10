extends Node

var puzzles: Array = []
var used_ids: Array = []

func load_for_difficulty(difficulty: String) -> void:
	used_ids.clear()
	puzzles.clear()
	var path = "res://puzzles_%s.json" % difficulty
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Puzzle file not found: %s — run extract_puzzles.py first" % path)
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data and data.has("puzzles"):
		puzzles = data["puzzles"]
		print("✅ Loaded %d puzzles (%s)" % [puzzles.size(), difficulty])

func get_puzzle_for_tier(tier: String) -> Dictionary:
	var matches = puzzles.filter(func(p):
		return p.get("difficulty", "") == tier and not used_ids.has(p["id"])
	)
	if matches.is_empty():
		for p in puzzles:
			if p.get("difficulty", "") == tier:
				used_ids.erase(p["id"])
		matches = puzzles.filter(func(p): return p.get("difficulty", "") == tier)
	if matches.is_empty():
		push_error("No puzzles for tier: " + tier)
		return {}
	var puzzle = matches[randi() % matches.size()]
	used_ids.append(puzzle["id"])
	return puzzle

func get_puzzle_for_level(_level: int) -> Dictionary:
	var matches = puzzles.filter(func(p):
		return not used_ids.has(p["id"])
	)
	if matches.is_empty():
		used_ids.clear()
		matches = puzzles.duplicate()
	if matches.is_empty():
		push_error("No puzzles available")
		return {}
	var puzzle = matches[randi() % matches.size()]
	used_ids.append(puzzle["id"])
	return puzzle
