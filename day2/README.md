# Day 2 — Timers, Counters & Troubleshooting

## 📖 Concept Summary & Technical Guide

### 1. Timers (TON, TOF, RTO)

| Instruction | Full Name | Behavior | Resets When | Typical Use Cases |
| :--- | :--- | :--- | :--- | :--- |
| **TON** | Timer On-Delay | $Q$ goes `TRUE` once $ET \ge PT$ while $IN$ stays `TRUE` continuously. | $IN$ goes `FALSE` (snaps $ET \rightarrow 0$ immediately). | Delay before motor start, purge cycles, debounce. |
| **TOF** | Timer Off-Delay | $Q$ goes `TRUE` instantly on $IN$'s rising edge. $Q$ stays `TRUE` for $PT$ duration after $IN$ drops `FALSE`. | $PT$ elapsed after $IN$ goes `FALSE`. | Cooling fan run-on, security light timer. |
| **RTO** | Retentive Timer On | Like TON, but $ET$ is **retained** across $IN$ going `FALSE`. | Requires explicit `RES` instruction. | Cumulative motor run-time tracking, shift production time. |

#### TON Internal Logic
```iecst
IF IN = TRUE THEN
    IF ET < PT THEN
        ET := ET + (time_since_last_scan);
    END_IF;
    IF ET >= PT THEN
        Q := TRUE;
    END_IF;
ELSE
    ET := 0;
    Q := FALSE;
END_IF;
```

---

### 2. Counters (CTU, CTD) & Edge Detection (ONS / R_TRIG)
- **CTU (Count Up)**: Increments $CV$ once per false$\rightarrow$true (rising) edge on $CU$. $Q$ goes `TRUE` when $CV \ge PV$. Resets via `RESET`.
- **CTD (Count Down)**: Decrements $CV$ toward $0$. Uses `LOAD` (not `RESET`) to set a starting $PV$.
- **Edge Detection (ONS / R_TRIG)**: Stores previous scan input state and asserts output for **exactly one scan** on a rising edge.
  ```iecst
  // R_TRIG logic
  Q := CurrentInput AND NOT PreviousInput;
  PreviousInput := CurrentInput;
  ```

---

### 3. Online Monitoring, Forcing I/O & Fault Triage

#### Fault Triage Sequence (Order Matters!)
1. **Check CPU State**: Verify RUN / STOP / FAULT LED and CPU fault log first.
2. **Check Module Fault LEDs**: Diagnose channel-level or backplane comms faults.
3. **Online Rung Monitoring**: Inspect logic execution and tag values.

#### Forcing I/O
- Overrides physical input/output terminals directly at the image table interface.
- **Hardware Isolation**: Force input high $\rightarrow$ if logic responds, fault is in physical sensor/wiring.
- **Output Testing**: Force output high $\rightarrow$ verifies actuator wiring without running upstream logic.
- ⚠️ **Safety Warning**: Forces bypass safety interlocks! Always clear all forces before leaving system live.

---

## 🛠️ Tasks & Instructor Solutions (Tasks 1 – 17)

### Task 1 — TON Full-Duration Trace
- **Given**: `Start_PB` held for $6\text{s}$, $PT = 5000\text{ms}$.
- **Result**: $Q$ asserts at $5\text{s}$. $ET$ reaches $6000\text{ms}$ at $6\text{s}$. When `Start_PB` releases, $ET \rightarrow 0$ and $Q \rightarrow \text{FALSE}$ on the next scan.

### Task 2 — TON Early-Release Trace
- **Given**: `Start_PB` held for $3\text{s}$, $PT = 5000\text{ms}$.
- **Result**: $ET$ reaches $3000\text{ms}$ then snaps to $0$. $Q$ never asserts (no partial credit).

### Task 3 — Cooling Fan Build (TOF)
```text
// Network 1
|--[ Motor_Running ]-----------------------------------( TOF )--|
                                                      Timer: FanRunOn
                                                      Preset: 30000 ms
// Network 2
|--[ FanRunOn.Q ]--------------------------------------( Fan_Output )--|
```

### Task 4 — Direction Confusion Quiz (TON vs TOF)
- **TOF**: $Q$ responds immediately (no delay) on rising edge; delay is applied on falling edge.
- **TON**: $Q$ is delayed on rising edge; drops immediately on falling edge.

### Task 5 — Basic Count Prediction (CTU)
- **Given**: $PV = 10$. 12 rising edges.
- **After 10th edge**: $CV = 10, Q = \text{TRUE}$.
- **After 12th edge**: $CV = 12, Q = \text{TRUE}$ (CTU does not stop at $PV$).

### Task 6 — Why Edge Detection Is Needed
- A plain `ADD` rung held for $2\text{s}$ at $10\text{ms}$ scan time increments $\approx 200$ times.
- **Fix**: Insert `ONS` / `R_TRIG` before increment logic so it fires for exactly 1 scan per press.

### Task 7 — CTU vs. CTD Semantics
- CTU uses `RESET` to clear $CV \rightarrow 0$.
- CTD uses `LOAD` to load $CV \leftarrow PV$. They are not symmetric.

### Task 8 — Edge-Triggered Part Counting Project
```text
|--[ PartSensor ]--[ ONS ]-----------------------------( CTU )--|
                                                       PartCount (PV=10)

|--[ PartCount.Q ]-------------------------------------( BatchComplete )--|

|--[ ResetBtn ]----------------------------------------[ RES PartCount ]--|
```
*Note*: `ResetBtn` does not need an `ONS` because holding `RESET` true safely holds $CV = 0$.

### Task 9 — Fault Triage Order
Correct order: **1) CPU state first**, **2) Module-level LEDs next**, **3) Online logic monitoring last**.

### Task 10 — Forcing Exercise
- Forcing `PartSensor` high isolates sensor wiring vs counting logic.
- Forcing `Fan_Output` directly isolates fan hardware/wiring vs TOF logic.

### Task 11 — Shift Accumulation Design (RTO)
- Plain TON is unusable for cumulative 8-hour shift tracking because intermediate stops reset $ET \rightarrow 0$.
- **RTO** holds $ET$ across stops until an explicit `RES` instruction fires at shift end.

### Task 12 — Three Planted Faults Debugging
1. *Missing RES on RTO*: $ET$ grows indefinitely across cycles.
2. *Missing ONS in front of CTU*: $CV$ increments 100x faster than expected.
3. *RTO used where TON was needed*: Stale elapsed time causes immediate false alarms on restart.

### Task 13 — Debounce Counter Project
Requires sensor to be continuously high for $3\text{s}$ before counting:
```text
|--[ PartSensor ]--------------------------------------( TON )--|
                                                       DebounceTimer (PT=3000ms)

|--[ DebounceTimer.Q ]--[ ONS ]------------------------( CTU )--|
                                                       PartCount (PV=10)
```

---

## 🚦 Day 2 Project — Traffic Light State Machine

### State Sequence & Timing
- **Red State (0)**: `Red_Light` ON, `TON_Red` $PT = 10,000\text{ms}$ $\rightarrow$ Transition to Green.
- **Green State (1)**: `Green_Light` ON, `TON_Green` $PT = 8,000\text{ms}$ $\rightarrow$ Transition to Yellow.
- **Yellow State (2)**: `Yellow_Light` ON, `TON_Yellow` $PT = 3,000\text{ms}$ $\rightarrow$ Transition to Red.

### Implementation Option A (INT State Register + EQU)
```text
|--[ TrafficState EQU 0 ]------------------------------( Red_Light )--|
|--[ TrafficState EQU 0 ]------------------------------( TON_Red: 10000ms )--|
|--[ TON_Red.Q ]-------------------[ MOV 1 -> TrafficState ]--[ RES TON_Red ]--|

|--[ TrafficState EQU 1 ]------------------------------( Green_Light )--|
|--[ TrafficState EQU 1 ]------------------------------( TON_Green: 8000ms )--|
|--[ TON_Green.Q ]-----------------[ MOV 2 -> TrafficState ]--[ RES TON_Green ]--|

|--[ TrafficState EQU 2 ]------------------------------( Yellow_Light )--|
|--[ TrafficState EQU 2 ]------------------------------( TON_Yellow: 3000ms )--|
|--[ TON_Yellow.Q ]----------------[ MOV 0 -> TrafficState ]--[ RES TON_Yellow ]--|
```

### Task 16 — Missing RES Bug
If `RES TON_Red` is omitted during state transition, stale $ET$ values can cause a short first pulse on the next cycle. Explicit `RES` ensures clean state re-entry.

### Task 17 — Pedestrian Interrupt Priority (Stretch)
```text
|--[ PedestrianBtn ]-----------------------------------[ MOV 3 -> TrafficState ]--|
```
*Evaluated at the TOP of the program (Rung 0) for instant priority override.*
