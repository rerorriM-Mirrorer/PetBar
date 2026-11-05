# PetBar TESTING.md

## Current Development Status — Pet Fade Live Test 3 (2026-11-04, America/Chicago)

- **Canonical repo / isolated branch:** `rerorriM-Mirrorer/PetBar` / `dev/pet-fade-live-test3-2026-11-04`. Source baseline is the dormant infrastructure commit `a800cbdc7d60d63dee0a38aa561bbdfe74428cda`; `main`, Test 1 and Test 2 branches remain untouched.
- **Original user request:** Add natural fade-in on summon; normal-color fade-out on pet death; white-on-release fade of **every foreground and text stroke**; remove the redundant TP prefix, keeping its number. User also asked about smaller translucent SMN-HUD portraits behind HP and future Rage/Ward cooldown badges; these are *design discussion only* and **not included** in Test 3.
- **What changed:** PetBar version `0.3.0-test3`. The existing dormant `petTransitions` / `transitionColors` units are now wired into real pet scans, owner-checked TP packet acquisitions, cutscene/zone resets, preview behavior, and per-frame native gauge rendering. Native images preserve original per-sprite effect alpha/tint before each fade, so TP layers, 3000 full bar flash, HP recovery/trails, and text-stroke outlines are all faded together without cumulative tint drift. Pet-name/HP/TP snapshot persists during final exit.
- **Release detection:** Windower `0x01A` outgoing `Category=9` / `Param=90` (SMN Release's job ability resource ID); the marker expires after 2.5 seconds, is tied to the currently owned pet ID and is **only acted on if the pet actually disappears**. HP0 death overrides the marker. If any packet variant differs, the departure stays normal-colored. Manual `//pb release` sends normal `/pet "Release" <me>` and marks intent. Actual client packet values not yet validated. No packets are injected.
- **Preview:** `//pb preview show`, `//pb preview death` and `//pb preview release` allow visual checks without issuing pet commands. `//pb preview tp N` remains available for overlap test.
- **Timing defaults:** enter 0.24s, death/missing 0.40s, Release 0.48s and white tint 0.12s. Screen changes and cutscenes still clear visuals immediately. Colors return to original palette on a new pet.
- **Available source checks:** inspected current root workflow and testing, reread Windower `images.lua` (`color/alpha` getters), `texts.lua` (`stroke_color/stroke_alpha`), job ability Release resource 90, and outgoing `0x01A` field definitions. Added `tests/release_detector_spec.lua` and `tests/fade_entry_spec.lua`, plus the prior `tests/transitions_spec.lua`. Updated branch coverage in `.github/workflows/lua51.yml`. **No successful Lua 5.1 CI result, live Windower smoke, or actual PetBar Test 3 gameplay testing has been confirmed.** Treat as experimental.
- **Known-good baseline:** PetBar Test 1 was shown in-game with Carbuncle at 99% HP / 211 TP, but contained a persistent endcap and no spirits. Test 2 and Test 3 remain live-unverified. See older entries below without interpreting inherited claims as current release status.

### Test 3 live checklist

1. Back up the current `Windower4/addons/PetBar/` and `data/` settings. Unpack the entire Test 3 branch ZIP, rename extracted root to `PetBar`, and overlay it carefully; ensure `WORKFLOW.md` and `TESTING.md` are inside the addon folder. `//lua reload PetBar`, then `//pb status` should show version `0.3.0-test3`.
2. With no pet: `//pb preview show` should appear smoothly and fade away after eight seconds. Try `//pb preview death` to verify the normal pink/blue, dark-stroke fade; `//pb preview release` to verify both bars and both text strokes become white while fading, then fully hide. Repeat twice to detect lingering whiteness.
3. Summon Carbuncle, then a spirit. Check smooth entrance, pet name/HP/TP, TP **number alone with no `TP` prefix**, exit on summon replacement, and no white contamination between pets.
4. Make a pet actually die with HP reaching 0: pink/blue elements and strokes should only fade down, not turn white. Detached finishing ghost is preserved for death but scene cleanup cancels it.
5. Use normal `/pet "Release" <me>` and compare `//pb release`. The *same* pet should turn white and fade only after it disappears. If it instead fades normally, enable `//pb debug on` and capture outgoing action/TP evidence: `0x01A` Category and Param plus observed pet ID. A blocked/unsuccessful Release must not whiten the HUD. If an unrelated pet disappears while a Release hint is pending, it must not inherit that white exit.
6. During entry or exit, invoke another summon or a preview, then zone or enter a cutscene. Confirm no ghost UI, no stale HP/TP, correct new colors, no hidden drag interception.
7. Retest existing Test 2 width/offset/layout commands, TP 1000/2000 overlay and flash, HP impact and ghost animations, `tpflash black/white`, lock/unlock, manual `show/hide`, restart/unload, and normal EnemyBar2 running alongside PetBar.

### Small Test 3 patch record

| Commit | Feature |
| --- | --- |
| `48594de` | Non-destructive fade and whitening of native HP and TP gauge sprites |
| `d039df4` | Apply the same fade to both TP layers |
| `bdb1285`, `f65efd3` | Conservative Release intent classifier and negative cases |
| `f524d21` | Remove `TP` text prefix, preserve numeric value |
| `2d85588` | Connect state machine, persistent departing snapshot, text stroke tint |
| `b2f35bf` | Send/observe Release, expose normal-death and white-release previews |
| `0875901` | Restore live pet values after preview |
| `76011d9` | Mocked Windower scenario test for entrance, release, death and TP number |
| `e1e5567` | CI branch coverage for Lua 5.1 parsing and model checks |
| `de104a7` | README usage and cumulative changelog |
| Final documentation commit and remote head are reported in the delivery handoff. |

### Future design requests — explicitly deferred

- Small, dim, semi-transparent avatar portrait artwork behind the HP bar, potentially inspired by Nalfey's SMN-HUD. Original assets are not currently available from its published repository; obtain properly authorized images or create original artwork before embedding.
- Two compact BP Rage and BP Ward countdown badges: recognizable offensive/support icons, dim with time remaining while cooling, brighter when ready; consider native FFXI icon source and `get_ability_recasts` when implementing.
- Keep the XIVParty TP flash port and optional 1000/2000/3000 sound cue as separate future work.

---

## Current Development Status — Dormant Pet Fade Infrastructure (2026-11-04)

- **Repository:** `rerorriM-Mirrorer/PetBar`; isolated `dev/pet-fade-infrastructure-2026-11-04` branch from the exact Test 2 head `5036b97f1770e3c29f91bcb703236e6882915ba5`.
- **User request:** Stand by on integrating the new visual behavior while Test 2 is being tested; prepare only non-invasive fade infrastructure.
- **New standalone modules:** `petTransitions.lua` (pet identity-aware entrance/exit state machine) and `transitionColors.lua` (pure RGBA fade and white-tint transformation, with **text stroke/outline** treated explicitly). They are **not imported** by the running `petbar.lua` entry point; the visible PetBar Test 2 remains unchanged.
- **Intent:** New pet fade in; death normal-color fade out; independently verified Release whites every image/text/stroke and fades out; missing/unclassified pet uses normal-color fade, avoiding false Release classifications; cutscene/zone/unload immediate cleanup.
- **Local simulated verification:** `texlua tests/transitions_spec.lua` **PASS** using local Lua 5.3, with synthetic timestamps and palette samples. This is **not Lua 5.1 verification, Windower, or live in-game testing**.
- **Next:** Continue Test 2 gameplay tests and gather release-vs-death recognition evidence. Only later wire transitions into `petbar.lua`, preserve pet/TP snapshot during exit, and propagate alpha/tint to all native sprites, number texts, text strokes, and detached ghost effects.
- **No installable fade build has been released.** Test 2 branch and `main` are unchanged. Existing previous status and testing history preserved below.

### Source and patch register (dormant groundwork)

- `ed6ad09` — pure transition timelines, pet-identity handling and explicit death/release reasons.
- `261e356` — independent tint/alpha transformer for texture, text, **text stroke**.
- `c80b8c2` — deterministic smoke tests for appearance, departure, release whitening, interruption, cleanup.
- `f1c40f1` — integration boundaries and documentation.
- Final documentation and remote head to be reported in handoff.

---

## Current Development Status — SMN Test 2 (2026-11-04, America/Chicago)

- **Repository / working branch:** `rerorriM-Mirrorer/PetBar` / `dev/smn-test2-2026-11-04`; forked from Test 1 commit `1f0a79ae649ec854829014c06a8df6a1774321e8`. `main` and Test 1 stay unchanged.
- **Most recent user-confirmed live behavior:** PetBar Test 1 was seen in-game displaying Carbuncle at 99% HP and 211 TP. User reported the appearance was good but identified a persistent gold TP-endcap protrusion and missing SMN elemental spirits. **Those are Test 1 observations**, not evidence that Test 2 fixes passed. Separately, the user verified the original game's TP appearance: completed 1000-TP underlays flash, later fills are only slightly transparent, the underlying flash speeds up at 2000, and 3000 alternates the complete bar between dark blue and another color.
- **Current implementation:** Separate persisted HP/TP widths and offsets for HP, TP, pet-name/HP text, and TP number; updated right-edge geometry; spirit support; exactly two drawable native TP layers, with 238/255 (93.3%) overlay, 1000/2000 pulse cadence .8s/.4s, dark-blue/white or dark-blue/black .3s alternating full bar at 3000; saved `tpflash` color control; Franklet-derived EnemyBar2 animation defaults with latest 1px-up/2px-down ghost and explicit `defaults animations` reset; per-frame gauge animation advancement.
- **Static regression coverage:** Added `tests/layout_spec.lua`, `tests/summon_spec.lua`, `tests/tp_tiers_spec.lua`, `tests/tp_renderer_spec.lua`, `tests/animation_preset_spec.lua`. GitHub Actions source for a Lua 5.1 parse-and-test workflow is committed at `.github/workflows/lua51.yml`. **No result from that workflow has been independently confirmed during this batch.**
- **Verification limitation:** GitHub file/branch source reviewed and small commits pushed. No live FFXI/Windower Test 2 session performed by the assistant. Do not claim source review equals Lua 5.1 compilation or in-game rendering.
- **Next:** Execute Test 2 live checklist below, then adjust native TP colors and timing against the player's observed reference before considering `main` promotion. Later XIVParty/sound implementation remains deferred.

### Test 2 commands and live acceptance checklist

1. Install the current branch as `Windower4/addons/PetBar/`, retaining `WORKFLOW.md` and `TESTING.md`; enter `//lua reload PetBar`, `//pb status`, `//pb help`. Confirm version `0.2.0-test2` and absence of Lua errors. `main` is documentation only.
2. Compare `//pb preview tp 999`, `1000`, `1450`, `1999`, `2000`, `2600`, `2999`, `3000`. At 1000, the base is fully filled and flashing; 1000-1999, overlay gradually advances with opacity about93%; at 2000 the underlay brightens and its flashing speeds up; beyond 2000 the overlay restarts in brighter cyan; at 3000 the overlay disappears and the full bar alternates. Confirm no third independent visible layer.
3. Compare `//pb tpflash white` and `//pb tpflash black` during 3000 preview; record which resembles the game's native behavior. Current colors/periods are **test approximations**, not sampled game color values.
4. `//pb preview hit`, `heal`, `tp`: verify native pink HP ghost, death effects, gradual HP recovery, blue TP gain, and genuine animation completion after a **single** packet/command. Verify TP expenditure does not shake. In particular, confirm the right golden cap no longer projects past the specified bar width; the native end cap itself still exists.
5. `//pb width 260`, `//pb width hp 300`, `//pb width tp 180`; `//pb offset hp 0 0`, `offset tp 0 4`, `offset name 5 2`, `offset tptext -8 2`, `offset`, `offset reset all`. Confirm positions and values persist through reload, remain independent in horizontal/vertical layouts, and respect screen bounds at 3840x2160 and 960x540. Ensure the original shared-width command clears specific width overrides.
6. For an existing saved-settings installation, confirm no silent animation reset. Then explicitly issue `//pb defaults animations`, compare classic shake, slow 3s HP fill, 2s red trailing hold, 1.2s numeric count and subtle ghost drift; verify offsets, labels and widths survive.
7. Summon at least Carbuncle and one elemental spirit (e.g. Ice Spirit); optionally inspect all eight spirits and other avatars. Confirm owner-scoped name/HP/TP, clean resummon, hide on dismissal/zoning/cutscenes, no unintended BST/DRG/PUP pet HUD.
8. Regression: test `//pb preview off`, lock/unlock/drag, restart/unload, repeated reloads and unrelated EnemyBar2 concurrently. Confirm no input interception while hidden and no chat spam.

### Test 2 patch register (small, coherent commits)

| Commit | Purpose |
| --- | --- |
| `21bf909` | Remove extra two-pixel width accounting on native gauge |
| `962a9ef`, `5332e10` | Isolate and connect independent layout/width/label-offset commands |
| `8c01de5` | Admit SMN elemental spirits |
| `dd43293`, `f1410b2`, `daf624c`, `fd0f708` | Initial stage-model / renderer integration checkpoints, subsequently refined |
| `4b0e067`, `ce4d7d9` | Franklet-derived EnemyBar2 animation preset and explicit saved-safe adoption |
| `1a5afb7`, `94d8d75`, `8b3f7bc`, `f58f38b` | User-corrected two-layer TP, translucent overlay, faster 2000 flash, 3000 black/white choice |
| `70961ec` | Advance all native effect timelines on render frames |
| `fa3e2da` | Add Lua 5.1 CI parse + model regression workflow |

All entries are published on `dev/smn-test2-2026-11-04` rather than `main`. The source checkpoint through `fa3e2daf9ddf086aa491615f919230a4968ebd20` includes the full behavior prior to documentation updates. The final published head is reported at handoff.

### Test 2 follow-up and caution

- FFXI TP overlay opacity, blue RGB and full-bar flash **are visual estimates** awaiting exact reference sampling. The user's original FFXI observations motivate the design but do not validate this approximation.
- Exact 0x067/0x068 pet ownership/TP fields are still pending controlled Windower captures; see `docs/PACKETS.md`.
- No TP-ready sound or XIVParty port included. Keep both future requests on record.
- Native 12px gauge height is unchanged. Small-window recovery may prioritize visible placement over extreme custom offsets.

---

## Current development status — dedicated PetBar repository, November 4, 2026

- **Canonical repository:** `rerorriM-Mirrorer/PetBar`, branch `dev/smn-test1-2026-11-04` (experimental). `main` remains documentation-only, reserved for a later live-tested release.
- **Transfer:** Copied PetBar's seven Lua modules, 13 FFXI-native PNG assets, README, WORKFLOW/AGENTS, and packet investigation notes from the original EnemyBar2 staging branch. Kept the earlier cumulative test history below, explicitly as a historical staging record.
- **Original staging source:** `rerorriM-Mirrorer/enemybar2` / `dev/petbar-smn-v1-2026-11-04` at `cccf4052132ed6b744a8bac1461caf5e6bfb1a29`. This is now provenance, **not** the active PetBar repository.
- **Install:** Download ZIP from the PetBar development branch, extract and rename the extracted archive folder to `PetBar`, and place it in `Windower4/addons/`. Do not replace EnemyBar2. See README for precise instructions.
- **Verification:** GitHub source and binary asset transfer, and repository isolation checks; **no Lua runtime smoke or in-game FFXI tests performed**. All previously pending live checks remain pending.

### Recorded repository correction

The original sections beginning at "Current batch — SMN Test 1" reference the temporary EnemyBar2 staging repository and its branch, which was correct when first written. As of this migration the canonical repository is **rerorriM-Mirrorer/PetBar** and the active branch is **dev/smn-test1-2026-11-04**. This addendum supersedes the old location without deleting its history.

---

## Source integrity and final review — 2026-11-04

- GitHub compare from base `7a7777ae37f3270aefd42a295d2a702b7537acc8` through documentation commit `8dcc851a3c3c5b06ea2851592fdb3a70a580f7c0`: **25 added files, all under PetBar/**; no tracked files outside this new directory changed.
- Checked existence of the six support/native renderer Lua modules, petbar.lua, WORKFLOW/TESTING/README/AGENTS, packet notes, and all **13 PNG sprites** (fetched in binary-safe base64).
- Checked the main entrypoint contains mouse, keyboard, prerender, status, zone, job, logout, incoming-packet and unload handlers; checked that original invalid string-literal method-call syntax was corrected in source commit `0e29e7398baa06d1f888f36104cdeb9e8210f301`.
- **Verification is structural/source review only.** These checks do not prove Lua 5.1 compilation, successful Windower load, packet behavior, or animation rendering. All live tests below remain pending.

---

## Current batch — SMN Test 1 (2026-11-04, America/Chicago)

- **Repository:** `rerorriM-Mirrorer/enemybar2`; isolated branch `dev/petbar-smn-v1-2026-11-04`.
- **Base:** `cioara-appearance-2026-11-02` at `7a7777ae37f3270aefd42a295d2a702b7537acc8`.
- **Installable directory:** `PetBar/` (keep all 13 PNG sprite files in `assets/ffxi/`). Never replace the existing EnemyBar2 addon.
- **Contents:** New SMN-only PetBar source, independently vendored EnemyBar2 native gauge and five support modules, original FFXI-native sprites, color-specific TP recovery, docs.
- **Verification so far:** Inspected the current EnemyBar2 repository, code and workflow, and the PetTP/PartyPets packet handling references. Patched Lua literal color-call syntax during source review. GitHub tree references confirm source and sprite snapshot provenance. **No in-game FFXI testing or Lua 5.1 runtime smoke test has occurred.**
- **Interpretation:** All behaviors are development intentions, not live-confirmed. Do not merge the dev branch into a known-good branch until tests pass.

### Live test instructions

1. `//lua load PetBar`, `//pb help`, `//pb status`, `//pb preview show`. Verify two equal-width native gauges and avatar name below. Preview should expire in ~8 seconds.
2. Use `//pb preview hit` to inspect HP trailing loss, ghost chunk, full impact shake; `preview heal` for HP recovery; `preview tp` for blue gain glow without shaking.
3. As SMN, summon Carbuncle. Verify name and HP% appear; TP remains `--` until an owner-validated update arrives. Check TP gain and expenditure in combat, including 1000/3000 values.
4. Replace Carbuncle with another avatar; ensure HP/TP from the prior pet do not bleed across. Release, lose pet, allow death, die, zone, log out/in and reload with an existing avatar.
5. Enter/exit cutscenes: bar, caption, and ghost effects hide, and only come back after exiting.
6. Use `//pb layout horizontal` then vertical; width/gap/scale/font commands, drag/Ctrl-drag, lock/unlock and reload persistence. Compare 3840x2160 and 1280x720/960x540 clients.
7. Check `//pb hide`, `show`, `auto`, `restart`, `unload`, `debug`; BattleStations message colors, no chat spam, EnemyBar2 unaffected.

### Known uncertainty / opportunities

- `0x067`/`0x068` pet TP/ownership packet variants need actual captures; `0x067` message-type-4 index reversal follows SnickySnacks' PetTP.
- SMN subjob avatar handling, Siren identification and fast pet replacements are unverified.
- Size scaling retains native 12px gauge height; future work can scale the complete sprite geometry.
- Ghost/heal/TP gain visuals are original EnemyBar2 physics and color substitutions, but need in-game acceptance.
- PetBar currently lives as an isolated directory in the EnemyBar2 repo because creation of a standalone PetBar repository was not available here.

## Previous tests
None yet. Prior EnemyBar2 testing belongs to EnemyBar2, not automatically to PetBar.

## Delivery record

| Date | Batch | Branch | Status |
| --- | --- | --- | --- |
| 2026-11-04 | SMN Test 1 | `dev/petbar-smn-v1-2026-11-04` | GitHub source; live testing pending |

## User requests retained

- SMN avatars only for v1; no Blood Pact timers, Favor indicators, other pets or player HUD yet.
- Pink HP over blue TP, same widths, optional side-by-side mode, default vertical.
- Avatar name just below the bars like EnemyBar2; preserve original impact effects including shake.
- TP gains resemble blue-tinted HP recovery; BattleStations-like help and chat feedback.

Add future results, user observations and corrections here without discarding this history.

## Delivery register — dedicated repository

| Date | Batch | Commit / branch | Status |
| --- | --- | --- | --- |
| 2026-11-04 | Repository migration | `dev/smn-test1-2026-11-04` | GitHub source and textures transferred; FFXI live checks pending |
