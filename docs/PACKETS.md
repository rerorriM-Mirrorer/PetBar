# PetBar packet investigation

## 2026-11-11 — Provisional zero-HP / false Carbuncle death investigation

**User-observed FFXI behavior:** On some Carbuncle summons, the addon briefly plays a death/ghost-hit-looking transition, then never shows the bar even though Carbuncle remains summoned. The exact initiating packet was **not captured**; do not equate this observation with proof that any specific packet reported HP=0.

**Source-established failure path in Test 4b:** `scan()` acquired a named pet entity even when `pet.hpp==0`, immediately called the death transition, then recorded `s.fading_id` and suppressed future scans/packets for that same pet ID until the mob vanished. Separately, the incoming pet packet handler immediately called `hp:set_value(0,false)` for any owner-checked `Current HP%=0`; this could trigger the large-loss ghost animation if the field was provisional. A single missing entity lookup also caused an immediate exit.

**Test 4c hypothesis and mitigation:** Treat new `0%` HP as possibly uninitialized and require positive HP before adopting a new summon; ignore provisional zero packets instead of sending an immediate 100-to-0 HP animation; require sustained zero on a previously confirmed living pet for ~0.35s before death, and missing lookups for ~0.40s before departure; clear a previous ID's fade quarantine when positive HP is observed. This is a **defensive fix for source-confirmed races**, not yet validation of their precise FFXI cause. Old behavior remains documented in Test 4b history.

**Suggested controlled capture:** With `//pb debug on`, repeatedly summon/release Carbuncle and an elemental spirit. If false death recurs, capture timestamped `0x067` / `0x068` direction and fields (`Owner Index`, `Pet Index`, `Current HP%`, `Pet TP`, `Message Type`) plus locally observed pet ID/index/HPP and whether `player.mob.pet_index` was zero. Correlate transitions to entity visibility; confirm if reported zero is an initialization placeholder, a stale value, or a packet field with different meaning. No injection is performed.

---

This documents **reviewed source behavior**, not captured new FFXI sessions.

## Incoming 0x067 and 0x068

PetTP and PartyPets inspect `Owner Index`, `Pet Index`, `Current HP%`, `Pet TP`. PetTP specifically swaps the interpreted index roles for `0x067` message type `0x04`. PetBar uses Windower's `packets.parse`, validates current player entity ownership and checks a corresponding owned avatar entity before accepting values.

- Confidence: medium for general behavior; unverified for all variants in our client sessions.
- To capture: summon Carbuncle, gain TP in melee, spend TP, swap avatars, zone, die and resummon; record packet IDs, field presence and owner/index matching.
- No packets are injected.

## Entity HPP

PetBar reads locally available pet entity `hpp` and holds an owner-validated HP packet reading for 0.30 seconds to avoid flicker caused by stale entity data. Exact HP and max HP are **not** inferred for avatars.
