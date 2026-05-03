"""
Extracts puzzles from the Lichess database into 3 difficulty files.
Filters to White-to-move puzzles only, sorted by popularity.

Output:
    puzzles_easy.json
    puzzles_medium.json
    puzzles_hard.json

Usage:
    python dev_resources/extract_puzzles.py
"""

import csv
import json
import zstandard as zstd
import io
import os

DB_PATH  = os.path.join(os.path.dirname(__file__), "lichess_db_puzzle.csv.zst")
PUZZLES_PER_TIER = 1000

DIFFICULTIES = {
    "easy": {
        "output": "puzzles_easy.json",
        "tiers": [
            {"name": "beginner",     "rating_min": 600,  "rating_max": 900,  "reward": 1},
            {"name": "intermediate", "rating_min": 900,  "rating_max": 1200, "reward": 1},
            {"name": "advanced",     "rating_min": 1200, "rating_max": 1500, "reward": 2},
        ]
    },
    "medium": {
        "output": "puzzles_medium.json",
        "tiers": [
            {"name": "club",   "rating_min": 1300, "rating_max": 1600, "reward": 1},
            {"name": "expert", "rating_min": 1600, "rating_max": 1900, "reward": 1},
            {"name": "master", "rating_min": 1900, "rating_max": 2200, "reward": 2},
        ]
    },
    "hard": {
        "output": "puzzles_hard.json",
        "tiers": [
            {"name": "master",      "rating_min": 2000, "rating_max": 2300, "reward": 1},
            {"name": "grandmaster", "rating_min": 2300, "rating_max": 2600, "reward": 1},
            {"name": "elite",       "rating_min": 2600, "rating_max": 9999, "reward": 2},
        ]
    },
}

def build_tier_lookup():
    """Returns a flat list of (rating_min, rating_max, difficulty_key, tier) for fast lookup."""
    lookup = []
    for diff_key, diff in DIFFICULTIES.items():
        for tier in diff["tiers"]:
            lookup.append((tier["rating_min"], tier["rating_max"], diff_key, tier))
    return lookup

def main():
    tier_lookup = build_tier_lookup()

    # Buckets: difficulty -> tier_name -> list of puzzles
    buckets = {}
    for diff_key, diff in DIFFICULTIES.items():
        buckets[diff_key] = {t["name"]: [] for t in diff["tiers"]}

    def bucket_full(diff_key, tier_name):
        return len(buckets[diff_key][tier_name]) >= PUZZLES_PER_TIER

    def all_full():
        for diff_key, diff in DIFFICULTIES.items():
            for tier in diff["tiers"]:
                if not bucket_full(diff_key, tier["name"]):
                    return False
        return True

    print(f"Scanning {DB_PATH}...")
    print("Reading full database to rank by popularity — takes a few minutes.\n")

    candidates = {diff_key: {t["name"]: [] for t in diff["tiers"]} for diff_key, diff in DIFFICULTIES.items()}
    scanned = 0

    with open(DB_PATH, "rb") as fh:
        dctx   = zstd.ZstdDecompressor()
        stream = dctx.stream_reader(fh)
        text   = io.TextIOWrapper(stream, encoding="utf-8")
        reader = csv.DictReader(text)

        for row in reader:
            scanned += 1
            if scanned % 500000 == 0:
                total = sum(len(v) for d in candidates.values() for v in d.values())
                print(f"  Scanned {scanned:,} rows — {total:,} candidates collected...")

            # Black to move in FEN = White is the player
            # (moves[0] is Black's setup move, moves[1] is White's first solution move)
            fen = row.get("FEN", "")
            fen_parts = fen.split(" ")
            if len(fen_parts) < 2 or fen_parts[1] != "b":
                continue

            try:
                rating     = int(row["Rating"])
                popularity = int(row["Popularity"])
            except (ValueError, KeyError):
                continue

            for (rmin, rmax, diff_key, tier) in tier_lookup:
                if rmin <= rating < rmax:
                    candidates[diff_key][tier["name"]].append({
                        "id":         row.get("PuzzleId", ""),
                        "fen":        fen,
                        "moves":      row.get("Moves", "").split(),
                        "rating":     rating,
                        "popularity": popularity,
                        "themes":     row.get("Themes", "").split(),
                        "difficulty": tier["name"],
                        "reward":     tier["reward"],
                    })
                    break

    print(f"\nScanned {scanned:,} rows total. Sorting and writing files...\n")

    for diff_key, diff in DIFFICULTIES.items():
        all_puzzles = []
        for tier in diff["tiers"]:
            pool = candidates[diff_key][tier["name"]]
            pool.sort(key=lambda p: p["popularity"], reverse=True)
            top  = pool[:PUZZLES_PER_TIER]
            print(f"  [{diff_key}] {tier['name']}: {len(top):,} puzzles  "
                  f"(rating {tier['rating_min']}–{tier['rating_max']}, reward ${tier['reward']})")
            all_puzzles.extend(top)

        out_path = diff["output"]
        with open(out_path, "w") as f:
            json.dump({"difficulty": diff_key, "puzzles": all_puzzles}, f, indent=2)
        print(f"  → Saved {len(all_puzzles):,} puzzles to {out_path}\n")

    print("Done.")

if __name__ == "__main__":
    main()
