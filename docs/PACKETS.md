# PetBar packet investigation

This documents **reviewed source behavior**, not captured new FFXI sessions.

## Incoming 0x067 and 0x068

PetTP and PartyPets inspect `Owner Index`, `Pet Index`, `Current HP%`, `Pet TP`. PetTP specifically swaps the interpreted index roles for `0x067` message type `0x04`. PetBar uses Windower's `packets.parse`, validates current player entity ownership and checks a corresponding owned avatar entity before accepting values.

- Confidence: medium for general behavior; unverified for all variants in our client sessions.
- To capture: summon Carbuncle, gain TP in melee, spend TP, swap avatars, zone, die and resummon; record packet IDs, field presence and owner/index matching.
- No packets are injected.

## Entity HPP

PetBar reads locally available pet entity `hpp` and holds an owner-validated HP packet reading for 0.30 seconds to avoid flicker caused by stale entity data. Exact HP and max HP are **not** inferred for avatars.
