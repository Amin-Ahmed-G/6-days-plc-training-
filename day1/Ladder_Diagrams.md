# 🔌 Day 1 — Ladder Logic Diagrams

This document contains standard IEC-style Ladder Diagrams for all Day 1 circuits and exercises.

---

## Rung 1: Two-Pushbutton AND Logic (Series Contacts)

### Logic Description
The output `Lamp` energizes **only when both** `PB1` AND `PB2` are physically pressed at the same time.

```text
  Power Rail (+)                                                    Power Rail (-)
       |                                                                  |
  1    |-------[ Start_PB ]--------------[ Safety_OK ]------------( Motor_Run )--|
       |          (NO)                      (NO)                     (Coil)       |
       |                                                                  |
```

---

## Rung 2: Two-Pushbutton OR Logic (Parallel Contacts / Branches)

### Logic Description
The output `Lamp` energizes when **either** `PB1` OR `PB2` (or both) is pressed.

```text
  Power Rail (+)                                                    Power Rail (-)
       |                                                                  |
  1    |-------[ PB1 ]--------------------------------------------( Lamp )--------|
       |        (NO)                                              (Coil)          |
       |                                                                          |
       |-------[ PB2 ]------------------------------------------------------------|
       |        (NO)                                                              |
```

---

## Rung 3: Motor Start/Stop with Seal-In Circuit (Day 1 Project)

### Logic Description
- Momentary push of `Start_PB` energizes `Motor_Run`.
- The output's own NO contact (`Motor_Run`) in the bottom branch maintains power flow (*seals in*) after `Start_PB` is released.
- Pressing `Stop_PB` (wired Normally Closed - NC) opens the circuit and breaks the seal-in.

```text
  Power Rail (+)                                                    Power Rail (-)
       |                                                                  |
  1    |----+---[ Start_PB ]---+-----------------[/ Stop_PB ]-----( Motor_Run )---|
       |    |     (NO)         |                   (NC)              (Coil)       |
       |    |                  |                                                  |
       |    +---[ Motor_Run ]--+                                                  |
       |          (NO Seal-in)                                                    |
```

### Flow Walkthrough
1. **Initial State**: `Start_PB` = 0, `Motor_Run` = 0, `Stop_PB` = 1 (NC closed). Rung is FALSE $\rightarrow$ `Motor_Run` = 0.
2. **Start Pressed**: `Start_PB` = 1. Rung becomes TRUE $\rightarrow$ `Motor_Run` energizes to 1.
3. **Start Released**: `Start_PB` returns to 0. `Motor_Run` contact in parallel remains 1 from previous scan, keeping power flow TRUE.
4. **Stop Pressed**: `Stop_PB` opens (reads 0). Series path breaks $\rightarrow$ `Motor_Run` de-energizes to 0.

---

## Rung 4: Forward / Reverse Mutual Exclusion Interlock (Stretch Project)

### Logic Description
- Two directional outputs (`Fwd_Run` and `Rev_Run`).
- Each direction includes a Normally Closed (NC) contact of the *opposite* output to guarantee mutual exclusion (preventing both contactors from energizing simultaneously).

```text
  Power Rail (+)                                                                            Power Rail (-)
       |                                                                                          |
  1    |----+---[ Fwd_PB ]---+-----------------[/ Stop_PB ]------[/ Rev_Run ]-------( Fwd_Run )----|
       |    |     (NO)       |                   (NC)              (NC Interlock)    (Coil)       |
       |    |                |                                                                    |
       |    +---[ Fwd_Run ]--+                                                                    |
       |          (NO Seal-in)                                                                    |
       |                                                                                          |
  2    |----+---[ Rev_PB ]---+-----------------[/ Stop_PB ]------[/ Fwd_Run ]-------( Rev_Run )----|
       |    |     (NO)       |                   (NC)              (NC Interlock)    (Coil)       |
       |    |                |                                                                    |
       |    +---[ Rev_Run ]--+                                                                    |
       |          (NO Seal-in)                                                                    |
```

> ⚡ **Scan Order Note**: If both `Fwd_PB` and `Rev_PB` are pressed on the exact same scan, Rung 1 is evaluated first. `Fwd_Run` energizes, opening `[/ Fwd_Run ]` on Rung 2 and instantly locking out `Rev_Run`.
