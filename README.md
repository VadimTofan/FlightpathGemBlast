# Gem Blast

https://www.curseforge.com/wow/addons/gem-blast
Gem Blast is an original 8x8 fantasy match-three game for Retail
World of Warcraft. Swap gems, build cascades, create special pieces, progress
through levels, and compare scores without leaving the game.

The addon is standalone and actively developed for Retail World of Warcraft.
It does not require external libraries.

## Features

- Click or drag adjacent gems to make a move.
- Smooth animations for swaps, invalid returns, clears, falls, refills,
  cascades, and reshuffles.
- A subtle hint after 10 seconds without a move.
- Automatic reshuffling when the board has no valid moves.
- Level progression with an emote whenever a new level is reached.
- Party and public Top 10 leaderboards.
- Automatic saving of the current game, score, settings, and window layout.

## Special gems

Matching four gems in a straight line creates a directionless line bomb.
Moving it left or right clears its row; moving it up or down clears its column.
If another effect triggers it, the direction is random. Matching a T or L
shape creates an area bomb that clears the surrounding 3x3 area.

Swapping two line bombs clears a full row-and-column cross. Swapping a line
bomb with an area bomb clears three full rows or columns based on the swap
direction. Swapping two area bombs creates a larger 5x5 explosion centered on
the destination cell.

Matching five gems creates a spark. Swap the spark with another gem to clear
every gem of that color from the board. Bombs and sparks are preserved when
the board reshuffles.

## Leaderboards

The collapsible leaderboard panel includes two modes:

- **Party Top 10** records scores received from party, raid, and instance-group
  members.
- **Public Top 10** exchanges scores through the optional hidden
  Gem Blast channel.

Scores are stored by account identity, so characters belonging to the same
account share one leaderboard position. The highest recorded score is kept,
including when a later addon update supplies new seeded scores.

Joining the public leaderboard is optional. The public tab remains disabled
until participation is enabled from the leaderboard panel.

## Opening and closing the game

Open Gem Blast from its minimap button or enter:

```text
/gb
```

Close the window with its **X** button or by pressing **Escape**. When the menu
is open, the **X** button dismisses the menu first.

## Settings

The in-game menu provides controls for:

- Opening the game automatically during flight paths.
- Closing the game when combat begins.
- Enabling or disabling sound.
- Changing the window scale.
- Resetting the window position.

The minimap button can be dragged around the minimap border.

## Saved data

Gem Blast saves the following account-wide data between sessions:

- Current board and score.
- Party and public Top 10 scores.
- Public leaderboard preference.
- Sound and automation settings.
- Window position and scale.
- Minimap button position.

Installing an addon update does not reset this data.

## Installation

Install Gem Blast with the CurseForge app, or install it manually:

1. Download the latest release archive.
2. Extract the `GemBlast` folder into
   `World of Warcraft/_retail_/Interface/AddOns/`.
3. Restart World of Warcraft or enter `/reload` if the addon was already
   installed.
4. Enable Gem Blast from the AddOns list.

## Support

Gem Blast is maintained by Vadim. Report bugs or suggest features
through [GitHub Issues](https://github.com/VadimTofan/GemBlast/issues).
