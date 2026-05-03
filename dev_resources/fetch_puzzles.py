"""
Fetches chess puzzles from the Lichess API and saves them to puzzles.json.
Run this once to build the local puzzle repository.

Usage:
    python dev_resources/fetch_puzzles.py

You need a free Lichess API token:
    1. Go to lichess.org/account/oauth/token
    2. Create a token (no scopes needed)
    3. Paste it into API_TOKEN below
"""

import json
import os
import time
import urllib.request
import urllib.error

# Token is read from dev_resources/.env (not committed to git)
def _load_token() -> str:
    env_path = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                if line.startswith("LICHESS_TOKEN="):
                    return line.strip().split("=", 1)[1]
    return ""

API_TOKEN = _load_token()

PUZZLES_PER_TIER = 30

TIERS = [
    {"difficulty": "easiest", "level_min": 1, "level_max": 2},
    {"difficulty": "easier",  "level_min": 3, "level_max": 4},
    {"difficulty": "normal",  "level_min": 5, "level_max": 6},
    {"difficulty": "harder",  "level_min": 7, "level_max": 8},
    {"difficulty": "hardest", "level_min": 9, "level_max": 10},
]

API_URL = "https://lichess.org/api/puzzle/next?difficulty={difficulty}"

def make_headers() -> dict:
    headers = {"Accept": "application/json"}
    if API_TOKEN:
        headers["Authorization"] = f"Bearer {API_TOKEN}"
    return headers

def fetch_puzzle(difficulty: str) -> dict | None:
    url = API_URL.format(difficulty=difficulty)
    req = urllib.request.Request(url, headers=make_headers())
    delay = 2.0
    for _ in range(6):
        try:
            with urllib.request.urlopen(req, timeout=15) as response:
                data = json.loads(response.read().decode())
                puzzle = data.get("puzzle", {})
                game   = data.get("game", {})
                return {
                    "id":        puzzle.get("id", ""),
                    "fen":       game.get("fen", ""),
                    "moves":     puzzle.get("solution", []),
                    "rating":    puzzle.get("rating", 0),
                    "themes":    puzzle.get("themes", []),
                }
        except urllib.error.HTTPError as e:
            if e.code == 429:
                print(f"  Rate limited — waiting {delay:.0f}s...")
                time.sleep(delay)
                delay *= 2
            else:
                print(f"  HTTP error: {e.code}")
                return None
        except urllib.error.URLError as e:
            print(f"  Request failed: {e}")
            return None
    print("  Giving up after retries.")
    return None

def main():
    if not API_TOKEN:
        print("⚠️  No API token set — you will likely get rate limited.")
        print("    Get a free token at lichess.org/account/oauth/token\n")

    all_puzzles = []
    seen_ids = set()

    for tier in TIERS:
        difficulty = tier["difficulty"]
        level_min  = tier["level_min"]
        level_max  = tier["level_max"]
        print(f"\nFetching '{difficulty}' puzzles (levels {level_min}-{level_max})...")

        fetched = 0
        attempts = 0
        while fetched < PUZZLES_PER_TIER and attempts < PUZZLES_PER_TIER * 4:
            attempts += 1
            puzzle = fetch_puzzle(difficulty)

            if not puzzle or not puzzle["fen"] or puzzle["id"] in seen_ids:
                time.sleep(1.5)
                continue

            puzzle["level_min"] = level_min
            puzzle["level_max"] = level_max
            all_puzzles.append(puzzle)
            seen_ids.add(puzzle["id"])
            fetched += 1

            print(f"  [{fetched}/{PUZZLES_PER_TIER}] id={puzzle['id']}  rating={puzzle['rating']}  themes={puzzle['themes'][:2]}")
            time.sleep(1.5)

    output = {"puzzles": all_puzzles}
    with open("puzzles.json", "w") as f:
        json.dump(output, f, indent=2)

    print(f"\nDone. {len(all_puzzles)} puzzles saved to puzzles.json")

if __name__ == "__main__":
    main()
