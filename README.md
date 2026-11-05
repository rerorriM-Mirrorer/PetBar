# PetBar — SMN avatar HP / TP

> **Development status, November 5, 2026:** Current testing branch: [`dev/tp-alpha-flash-and-zorder-2026-11-05`](https://github.com/rerorriM-Mirrorer/PetBar/tree/dev/tp-alpha-flash-and-zorder-2026-11-05). This Test 4 candidate retains the earlier HP/TP layout while changing rendering order, TP flashing and departure fades. **Test 4 has not been verified in-game.** `main` and earlier testing branches remain unchanged.

PetBar Test 4 is a **standalone Windower 4 addon** for Summoner avatars and elemental spirits. It is an independent companion to EnemyBar2, not an EnemyBar2 patch or runtime dependency.

## Installation

From the [PetBar Test 4 branch](https://github.com/rerorriM-Mirrorer/PetBar/tree/dev/tp-alpha-flash-and-zorder-2026-11-05), download its ZIP, extract the archive, and **rename the extracted repository folder to `PetBar`**. Place that full folder (including Lua modules, `assets/ffxi` and documentation) at `Windower4/addons/PetBar/`. Then type `//lua load PetBar`.

PetBar is now its own GitHub repository; **do not** merge its files into the existing `enemybar2` addon folder. No change is needed to EnemyBar2, XIVCrossbar, or Trust.

## Appearance and behavior

- HP: pink, native EnemyBar2 texture and animation (damage trail, healing, detached large-hit ghost, impact shaking, low-health pulse and finishing spark).
- TP: from 0–999, a steady blue fill. At **1,000**, the full underlying bar begins alternating between **100% opacity and 0% opacity**, with a slightly brighter **93.3%-opaque** blue overlay filling toward 2,000. At **2,000**, the underlying blink becomes faster and the overlay restarts in brighter cyan. At **3,000**, the overlay hides and the single full-width blue bar alternates between visible and entirely transparent. **No brightness/color pulsing, no black/white color flashes.** TP colors are provisional and await in-game comparison.
- Spending TP snaps/rebases the fill without damage shake or ghosts; each new TP gain uses a blue recovery-style highlight.
- `vertical` (default): TP immediately beneath HP. `horizontal`: HP and TP side by side. Both start equal width but can be independently sized or offset. **HP gauge sprites draw above TP gauge sprites** when the two overlap.
- Avatar name and HP% just below the bars in EnemyBar2-style italic Arial; **numeric TP without a redundant `TP` label** appears at the right end of the same caption row.
- SMN avatars **and all eight elemental spirits**. BST pets, wyverns, automatons and unrelated pets remain excluded.
- New summons fade in, and **all departures use the same normal-color fade-out**, whether the pet dies, is released or otherwise disappears. No special white release or death treatment. The exit snapshot keeps the last name/HP/TP until fully faded; cutscenes, zoning, logout and unload still clear immediately. TP comes only from verified local packets; unknown TP displays `--`.
- Settings persist separately per client via Windower config. Default x is centered relative to UI width, default y is near the lower part of the UI. Personal saved position wins. Ctrl+drag snaps to 10px; left mouse release saves.

`//pb scale` scales width, gap and caption font. The native gauge remains 12px high in Test 4 to preserve its artwork. Local offsets are independent of the whole-HUD drag position.

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
//pb tpflashperiod           -- Report current full on/off cycles
//pb tpflashperiod 1000 0.8  -- 1000-1999 TP: 0.8s per full cycle
//pb tpflashperiod 2000 0.4  -- 2000-2999 TP: 0.4s per full cycle
//pb tpflashperiod 3000 0.3  -- 3000 TP: 0.3s per full cycle
//pb tpflashperiod all 0.5   -- Use one period at every threshold
```

For HP animations, `//pb preview hit`, `//pb preview heal`, `//pb shake on|off`, and `//pb ghost on|off` remain available.

To check the new pet lifecycle effects **without losing a real summon**:

```text
//pb preview show
//pb preview fade
//pb preview death            -- Alias; same visual fade
//pb preview release          -- Alias; same visual fade
```

Typical fade durations are **0.24 seconds to appear and 0.40 seconds to depart**. All bar artwork, both numbers/name and their strokes fade together while keeping the original colors. The optional `//pb release` still issues normal `/pet "Release" <me>` without any special visual effect. **New installs** adopt Franklet-derived EnemyBar2 animation defaults. **Existing saved animations remain authoritative** until `//pb defaults animations` is explicitly used, which preserves widths and offsets.

Flash period commands accept 0.1–5 seconds for a **complete visible/invisible cycle**, with an instantaneous switch halfway through. No TP flash occurs below 1,000. The legacy `tp_flash_target` entry (including `black`) may remain in your old XML but is ignored. New period keys are `tp_flash_1000`, `tp_flash_2000`, and `tp_flash_3000`; changing them never resets unrelated character-specific settings.

Other commands include `//pb status`, `//pb show|hide|auto`, `//pb preview off`, `//pb gap <0..40>`, `//pb scale <0.65..2>`, `//pb fontsize <8..24>`, `//pb resetpos`, `//pb lock|unlock`, `//pb debug on|off`, `//pb save`, `//pb restart` and `//pb unload`.


## Origin

PetBar vendors the native rendering source and assets from `rerorriM-Mirrorer/enemybar2`, branch `cioara-appearance-2026-11-02` (Batch20, November 2, 2026), built on EnemyBar2 by Mike McKee / AkadenTK and subsequent A branch changes. Original source header and texture attribution remain with their files. PetBar's local native-gauge derivative now also supports independent animation progression, transparent TP overlays, the earlier tier effects (now superseded by alpha-only blinking), and corrected right-edge dimensions; none of these changes alters EnemyBar2 itself.

BarFiller2 and XIVParty xi_select informed design; their runtime modules are not required.

## Cumulative changelog

- **2026-11-05 — SMN Test 4 (unverified):** All pet exits share one normal-color fade (no white release); retired release-only detector; HP bar sprites now draw after/above TP sprites; completed TP underlay blinks between 100% and 0% opacity without color/brightness pulses; the 3000 TP bar also blinks completely transparent rather than flashing black/white; adjustable per-threshold full-cycle period via `//pb tpflashperiod` (defaults 0.8s/0.4s/0.3s); preserve existing XML appearance settings, offsets, widths and HP animations. Includes updated regression tests. Previous Test 3 behavior is recorded below as history.
- **2026-11-04 — SMN Test 3 (unverified):** Live fade-in on summon, normal death/missing fade, conditional white-release fade across both bars and text/strokes, snapshot preservation through exits and preview cleanup, commands `//pb preview death`, `//pb preview release`, `//pb release`. Removed redundant `TP` text prefix while keeping the TP number and its independent offset. Includes conservative Windower 0x01A Release hint (PetCommand resource ID 90), pure transition model and mocked-entrypoint tests. No SMN-HUD artwork or Rage/Ward timer assets in this test.
- **2026-11-04 — SMN Test 2:** Correct native gauge width; independent saved HP/TP width and HP, TP, name, value offsets; SMN elemental spirits; 1,000/2,000 TP overlays using exactly two native gauges with a 93.3% overlay, second-stage faster pulse and brighter cyan; full-width 3,000 TP alternate dark blue/white or dark blue/black; dedicated preview/status/help controls; Franklet-derived animation defaults with explicit saved-safe reset; per-frame animation progression; offline model tests and Lua 5.1 CI configuration. **New behavior still needs live FFXI verification.**
- **2026-11-04 — Repository migration:** Moved source, all 13 textures, and cumulative testing notes from the temporary EnemyBar2 development folder into the dedicated PetBar repository's `dev/smn-test1-2026-11-04` branch. No live FFXI testing was performed during migration.
- **2026-11-04 — SMN Test 1:** Independent PetBar, native effect snapshot, equal-width HP/TP, two layouts, SMN pet tracking, packet TP, previews, cutscene hide, drag/lock, resolution-relative default, BattleStations help, graceful lifecycle. **Not yet tested in-game.**
