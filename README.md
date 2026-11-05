# PetBar — SMN avatar HP / TP

> **Development status, November 4, 2026:** PetBar now lives in its own repository, [rerorriM-Mirrorer/PetBar](https://github.com/rerorriM-Mirrorer/PetBar). This branch is experimental; `main` remains documentation-only until in-game tests are accepted. The original staging branch in EnemyBar2 is retained for provenance only.

PetBar Test 1 is a new **standalone Windower 4 addon** for Summoner avatars. It is an independent companion to EnemyBar2, not an EnemyBar2 patch or runtime dependency.

## Installation

From the [PetBar development branch](https://github.com/rerorriM-Mirrorer/PetBar/tree/dev/smn-test1-2026-11-04), download its ZIP, extract the archive, and **rename the extracted repository folder to `PetBar`**. Place that full folder (including Lua modules, `assets/ffxi` and documentation) at `Windower4/addons/PetBar/`. Then type `//lua load PetBar`.

PetBar is now its own GitHub repository; **do not** merge its files into the existing `enemybar2` addon folder. No change is needed to EnemyBar2, XIVCrossbar, or Trust.

## Appearance and behavior

- HP: pink, native EnemyBar2 texture and animation (damage trail, healing, detached large-hit ghost, impact shaking, low-health pulse and finishing spark).
- TP: blue, same width as HP, with a blue/cyan-tinted HP-style healing animation on TP gain. Spending TP does not shake or spawn damage ghosts.
- `vertical` (default): TP immediately beneath HP. `horizontal`: HP and TP side by side.
- Avatar name and HP% just below the bars in EnemyBar2-style italic Arial; TP amount appears at the right end of the same caption row.
- Only persistent SMN avatars: Carbuncle, six elemental avatars, Fenrir, Diabolos, Cait Sith and Siren. Elemental spirits and other pets deliberately excluded.
- Automatically hides with no avatar and in cutscenes. Pet replacement resets old HP/TP. TP reads packets only; until a verified local TP update, displays `--`, not an invented number.
- Settings persist separately per client via Windower config. Default x is centered relative to UI width, default y is near the lower part of the UI. Personal saved position wins. Ctrl+drag snaps to 10px; left mouse release saves.

`//pb scale` scales bar width, gap and caption font. The native gauge remains 12px high in Test 1 to preserve its artwork.

## Commands

`//pb help` is BattleStations-style, colorized chat-only help. Also use `//pb status`, `//pb show`, `//pb hide`, `//pb auto`, `//pb preview [show|hit|heal|tp|off]`, `//pb layout <vertical|horizontal>`, `//pb width <60..800>`, `//pb gap <0..40>`, `//pb scale <0.65..2>`, `//pb fontsize <8..24>`, `//pb pos <x> <y>`, `//pb resetpos`, `//pb lock`, `//pb unlock`, `//pb shake [on|off]`, `//pb ghost [on|off]`, `//pb debug [on|off]`, `//pb save`, `//pb restart`, and `//pb unload`.

For your first visual check, try `//pb preview show`, then `//pb preview hit`, `//pb preview heal` and `//pb preview tp` before summoning Carbuncle.

## Origin

PetBar vendors the native rendering source and assets from `rerorriM-Mirrorer/enemybar2`, branch `cioara-appearance-2026-11-02` (Batch20, November 2, 2026), built on EnemyBar2 by Mike McKee / AkadenTK and subsequent A branch changes. Original source header and texture attribution remain with their files. PetBar's only functional native-gauge adjustment is configurable HP recovery palette, used for blue/cyan TP gain.

BarFiller2 and XIVParty xi_select informed design; their runtime modules are not required.

## Cumulative changelog

- **2026-11-04 — Repository migration:** Moved source, all 13 textures, and cumulative testing notes from the temporary EnemyBar2 development folder into the dedicated PetBar repository's `dev/smn-test1-2026-11-04` branch. No live FFXI testing was performed during migration.
- **2026-11-04 — SMN Test 1:** Independent PetBar, native effect snapshot, equal-width HP/TP, two layouts, SMN pet tracking, packet TP, previews, cutscene hide, drag/lock, resolution-relative default, BattleStations help, graceful lifecycle. **Not yet tested in-game.**
