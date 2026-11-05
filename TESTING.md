# PetBar TESTING.md

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
