# PetBar — SMN avatar HP / TP

> **Development status, November 4, 2026:** Current testing branch: [`dev/smn-test2-2026-11-04`](https://github.com/rerorriM-Mirrorer/PetBar/tree/dev/smn-test2-2026-11-04). The first build has been seen in-game, but these new Test 2 changes remain unverified in FFXI. `main` remains documentation-only pending acceptance. EnemyBar2's original source and older PetBar Test 1 remain unchanged.

PetBar Test 2 is a **standalone Windower 4 addon** for Summoner avatars and elemental spirits. It is an independent companion to EnemyBar2, not an EnemyBar2 patch or runtime dependency.

## Installation

From the [PetBar Test 2 branch](https://github.com/rerorriM-Mirrorer/PetBar/tree/dev/smn-test2-2026-11-04), download its ZIP, extract the archive, and **rename the extracted repository folder to `PetBar`**. Place that full folder (including Lua modules, `assets/ffxi` and documentation) at `Windower4/addons/PetBar/`. Then type `//lua load PetBar`.

PetBar is now its own GitHub repository; **do not** merge its files into the existing `enemybar2` addon folder. No change is needed to EnemyBar2, XIVCrossbar, or Trust.

## Appearance and behavior

- HP: pink, native EnemyBar2 texture and animation (damage trail, healing, detached large-hit ghost, impact shaking, low-health pulse and finishing spark).
- TP: starts as a blue fill covering the full width by **1,000 TP**. After 1,000, the completed bar pulses underneath a **93% opaque blue overlay** filling across it toward 2,000; after 2,000 the lower pulse becomes faster, and the same translucent overlay restarts in brighter cyan to 3,000. At **3,000** the overlay disappears and the single full-width bar alternates between darkest blue and white (or black, selectable). These are provisional colors/timings awaiting comparison with in-game FFXI flashing.
- Spending TP snaps/rebases the fill without damage shake or ghosts; each new TP gain uses a blue recovery-style highlight.
- `vertical` (default): TP immediately beneath HP. `horizontal`: HP and TP side by side. Both start equal width but can be independently sized or offset.
- Avatar name and HP% just below the bars in EnemyBar2-style italic Arial; TP amount appears at the right end of the same caption row.
- SMN avatars **and all eight elemental spirits**. BST pets, wyverns, automatons and unrelated pets remain excluded.
- Automatically hides with no avatar and in cutscenes. Pet replacement resets old HP/TP. TP reads packets only; until a verified local TP update, displays `--`, not an invented number.
- Settings persist separately per client via Windower config. Default x is centered relative to UI width, default y is near the lower part of the UI. Personal saved position wins. Ctrl+drag snaps to 10px; left mouse release saves.

`//pb scale` scales width, gap and caption font. The native gauge remains 12px high in Test 2 to preserve its artwork. Local offsets are independent of the whole-HUD drag position.

## Commands

`//pb help` displays BattleStations-style colorized chat help. Geometry and positioning:

```text
//pb width 260               -- Sets both; clears separate width overrides
//pb width hp 300            -- Independent HP gauge width
//pb width tp 260            -- Independent TP gauge width
//pb offset hp 0 0           -- Local HP offset (x, y)
//pb offset tp 0 4           -- Local TP offset
//pb offset name 5 2         -- Avatar name and HP percentage offset
//pb offset tptext -8 2      -- TP number offset
//pb offset                 -- Report all offsets
//pb offset reset all       -- Recover individual/all offsets
//pb layout vertical        -- Default; use horizontal to place bars side by side
//pb pos 400 200            -- Whole display position; drag and Ctrl+drag also work
```

Offsets are signed integer UI pixels (-1000..1000), positive right/down; each component is separately configurable and saved. `//pb offset name` reports the name offset; `//pb offset reset name` resets only that component. `//pb offset pet` aliases `name`, and `//pb offset tpnumber` aliases `tptext`.

To inspect the progressive flashing without waiting for battle TP:

```text
//pb preview tp 999
//pb preview tp 1000
//pb preview tp 1450
//pb preview tp 2000
//pb preview tp 2600
//pb preview tp 3000
//pb tpflash white          -- At 3000: dark blue <-> pure white
//pb tpflash black          -- At 3000: dark blue <-> black
```

For HP animations, `//pb preview hit`, `//pb preview heal`, `//pb shake on|off`, and `//pb ghost on|off` remain available. **New installs** adopt Franklet-derived EnemyBar2 animation timings and the latest 1px-up/2px-down ghost drift. **Existing saved animations remain authoritative** until `//pb defaults animations` is explicitly used, and that command preserves widths and positions.

Other commands include `//pb status`, `//pb show|hide|auto`, `//pb preview off`, `//pb gap <0..40>`, `//pb scale <0.65..2>`, `//pb fontsize <8..24>`, `//pb resetpos`, `//pb lock|unlock`, `//pb debug on|off`, `//pb save`, `//pb restart` and `//pb unload`.


## Origin

PetBar vendors the native rendering source and assets from `rerorriM-Mirrorer/enemybar2`, branch `cioara-appearance-2026-11-02` (Batch20, November 2, 2026), built on EnemyBar2 by Mike McKee / AkadenTK and subsequent A branch changes. Original source header and texture attribution remain with their files. PetBar's local native-gauge derivative now also supports independent animation progression, transparent TP overlays, tier pulses, neutral white/black flash silhouettes, and corrected right-edge dimensions; none of these changes alters EnemyBar2 itself.

BarFiller2 and XIVParty xi_select informed design; their runtime modules are not required.

## Cumulative changelog

- **2026-11-04 — SMN Test 2:** Correct native gauge width; independent saved HP/TP width and HP, TP, name, value offsets; SMN elemental spirits; 1,000/2,000 TP overlays using exactly two native gauges with a 93.3% overlay, second-stage faster pulse and brighter cyan; full-width 3,000 TP alternate dark blue/white or dark blue/black; dedicated preview/status/help controls; Franklet-derived animation defaults with explicit saved-safe reset; per-frame animation progression; offline model tests and Lua 5.1 CI configuration. **New behavior still needs live FFXI verification.**
- **2026-11-04 — Repository migration:** Moved source, all 13 textures, and cumulative testing notes from the temporary EnemyBar2 development folder into the dedicated PetBar repository's `dev/smn-test1-2026-11-04` branch. No live FFXI testing was performed during migration.
- **2026-11-04 — SMN Test 1:** Independent PetBar, native effect snapshot, equal-width HP/TP, two layouts, SMN pet tracking, packet TP, previews, cutscene hide, drag/lock, resolution-relative default, BattleStations help, graceful lifecycle. **Not yet tested in-game.**
