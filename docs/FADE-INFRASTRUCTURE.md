# Current fade behavior — November 5, 2026

**Test 4 supersedes the historical Release-white design below.** On `dev/tp-alpha-flash-and-zorder-2026-11-05`, every pet departure (Release, death, or unexplained disappearance) uses the **same normal-color fade out** with the same duration. The release-only intent detector, white native mask and differentiated fade timing have been retired from the runtime. `//pb preview fade`, `//pb preview death` and `//pb preview release` all demonstrate the same look. The user confirmed the regular fade is the desired appearance.

This remains an unverified Test 4 visual patch. See the newest `TESTING.md` section for the user-supplied layout baseline, current source checkpoint and live instructions. The older notes remain below solely as design history.

---

# PetBar transitions — provenance and integration status

**2026-11-04 update:** This document originally described the intentionally dormant fade modules on `dev/pet-fade-infrastructure-2026-11-04`. That historical stage remains accurately recorded below. The newer **`dev/pet-fade-live-test3-2026-11-04`** branch now imports those modules into `petbar.lua`, adds a conservative owner-scoped Release detector and full renderer/text-stroke tinting, and supplies `//pb preview death` / `//pb preview release`. For current setup and unverified checks, read root `README.md` and the newest section of `TESTING.md` first. **No live FFXI acceptance of the integrated fade has yet been reported.**

---

# PetBar transitions: dormant infrastructure

This code is staged separately on `dev/pet-fade-infrastructure-2026-11-04`, based on the Test 2 checkpoint. Neither `petbar.lua` nor the native renderer imports it yet. Installing the user-tested Test 2 branch has **no change** to fade behavior.

When wired in after Test 2 acceptance:

- New pet: fade from transparent to its normal colors in about 0.24 seconds.
- Death (observed HP=0): **normal-color** fade out in about 0.4 seconds.
- Confirmed voluntary release: whiten **all parts**, including native bar textures, TP overlay, pet-name and number text, and both text strokes, while fading out over about 0.48 seconds. Whitening completes in about 0.12 seconds. Original palettes remain immutable so rescans cannot bleach future pets.
- Unclassified disappearance: fade out in the original colors; do not assume release.
- Zoning, cutscene, logout and unload: immediate cleanup, never leave a ghost UI displayed in a new scene.
- Identical pet reappearing during exit resumes fading in; a different pet identity gets a fresh entrance rather than inheriting the departed pet's name or TP.

Unresolved integration issues: classify release from a reliable, owner-scoped observation (not disappearance alone); preserve name/HP/TP snapshots while the final fade runs; apply an overall alpha multiplier to every visible gauge sprite, flare and TP layer **without overwriting their own animation alpha**; whiten both text glyphs and outline/stroke; define treatment of detached EnemyBar2 ghost effects. These belong to the later visual patch, not this infrastructure-only branch.

The two pure modules `petTransitions.lua` and `transitionColors.lua` can be exercised without Windower, using deterministic timestamps. Their test is `tests/transitions_spec.lua`. Tested under Lua 5.3 `texlua`; actual Lua 5.1 parsing and in-game Windower behavior remain unverified.
