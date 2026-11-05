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
