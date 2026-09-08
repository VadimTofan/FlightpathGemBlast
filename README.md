# BetterBejeweled


BetterBejeweled is an original 8×8 fantasy match-three game for Retail World
of Warcraft. Open it from the minimap button or with `/bb`, then click or drag
adjacent gems to make matches.

Moves animate through swaps, invalid returns, matched-gem removal, falling,
refilling, and cascades. The board accepts another move only after the current
animation sequence settles.

The current board, score, sound preference, window position, and minimap
button position are saved automatically. Press Escape to close the game.

## Development tests

Run the pure Lua rules tests with Lua 5.1:

```powershell
& 'C:\Program Files (x86)\Lua\5.1\lua.exe' tests/run.lua
```
