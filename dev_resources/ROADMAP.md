# ChessLatro — Roguelite Roadmap

> **Core Loop:**
> 1. **Puzzle Phase** — Solve 5 puzzles (strict mode, exact solution moves required)
> 2. Each puzzle solved = earn a power up
> 3. **Boss Phase** — Head-to-head vs Stockfish using earned power ups
> 4. Win the boss fight → next run (harder puzzles, stronger Stockfish)

**Status tags:** `[ ]` not started · `[~]` in progress · `[x]` done

---

## 1. Puzzle Phase

Strict puzzle mode — player must play the exact Lichess solution sequence.

- [x] Load puzzle FEN from puzzles.json
- [x] Parse solution moves from puzzle data
- [ ] Validate White's move against solution — wrong move = immediate feedback
- [ ] Auto-play Black's scripted response from solution (not Stockfish)
- [ ] Advance through multi-move solutions (White move → Black response → White move...)
- [ ] Puzzle cleared when full solution sequence is completed
- [ ] Track puzzles solved this run (out of 5)
- [ ] Show puzzle progress on HUD (e.g. "Puzzle 2 / 5")
- [ ] Wrong move handling — retry same puzzle or skip with no power up reward
- [ ] Transition to Boss Phase after 5 puzzles attempted

---

## 2. Power Ups

Earned by solving puzzles, carried into the boss fight.

- [ ] Power up data structure — name, description, effect type
- [ ] Award 1 power up per solved puzzle (random from pool, or choose from 3)
- [ ] Power up selection screen between puzzle and next puzzle
- [ ] Power up examples to implement:
  - [ ] Extra Queen — start boss fight with an additional queen
  - [ ] Extra Knight — start boss fight with an additional knight
  - [ ] Pawn Wall — start with an extra row of pawns
  - [ ] Double Move — use once during boss fight to move twice in one turn
  - [ ] Resurrect — one captured piece comes back to its start square
  - [ ] Fog of War — hide enemy pieces for first 3 turns of boss fight
- [ ] Power ups applied to starting position when boss fight begins
- [ ] Show active power ups on HUD during boss fight

---

## 3. Boss Phase

Head-to-head chess vs Stockfish using power ups earned in puzzle phase.

- [x] Stockfish integration (Fairy-Stockfish, depth 10, MultiPV randomness)
- [ ] Boss starting position — standard Stockfish army (full strength)
- [ ] Apply earned power ups to player's starting position before fight
- [ ] Win condition — checkmate Stockfish
- [ ] Lose condition — get checkmated
- [ ] Boss difficulty scales per run (Stockfish depth increases each run)
- [ ] Boss fight HUD — show active power ups, move counter

---

## 4. Run Structure

The loop that ties puzzle phase and boss phase together.

- [x] RunState autoload — tracks current level
- [ ] RunState — add: puzzles_solved, puzzles_attempted, earned_powerups, current_phase
- [ ] Phase manager — controls flow: puzzle → power up screen → puzzle → ... → boss
- [ ] Run complete screen — show on boss win (puzzles solved, power ups used, moves taken)
- [ ] Run failed screen — show on boss loss, option to restart run
- [ ] Difficulty scaling per run — increase puzzle rating band and Stockfish depth each run

---

## 5. Core Engine Changes

- [x] Win/loss detection emits signal (match_over)
- [x] Fairy-Stockfish integration with MultiPV randomness
- [x] FEN loading (load_from_fen)
- [x] Puzzle JSON loading and level-based selection
- [ ] Strict puzzle validation — check player move against solution sequence
- [ ] Scripted Black responses — play solution moves automatically for Black
- [ ] Board mode switching — puzzle mode vs boss mode (affects AI behavior, win conditions)
- [ ] Board reset cleanly between puzzle and boss phases
- [ ] Piece instance system — unique IDs for pieces so power ups can be attached

---

## 6. UI / UX

- [x] Level label on HUD
- [x] "White to Play" label
- [x] Win/loss overlay with Next Puzzle button
- [ ] Puzzle progress tracker — "Puzzle X / 5"
- [ ] Wrong move flash — red highlight on illegal puzzle move
- [ ] Correct move flash — green highlight, then auto-play Black response
- [ ] Power up selection screen — pick 1 of 3 after each solved puzzle
- [ ] Power up HUD — icons showing active power ups during boss fight
- [ ] Boss intro screen — "Boss Fight!" splash before head-to-head begins
- [ ] Main menu — New Run, Settings

---

## 7. Black-Side Puzzle Support (future)

Allow player to play as Black in puzzles where it is Black to move.

- [ ] Read active color from puzzle FEN to determine player color
- [ ] Flip board rendering so player's pieces are always at the bottom
- [ ] Flip AI trigger — Stockfish plays whichever color the player is not
- [ ] Update move validation to respect dynamic player color

---

## 8. Polish & Future Ideas

- [ ] Animated piece moves
- [ ] Sound effects and music
- [ ] Permanent unlocks across runs (meta progression)
- [ ] Leaderboard / run scoring
- [ ] Piece skins earned through runs
- [ ] Variable board sizes (requires Fairy-Stockfish variant config)
