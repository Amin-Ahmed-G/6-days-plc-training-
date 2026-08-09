# Day 2 — Timers, Counters & Troubleshooting: Full Instructor Teaching Material (Technical Edition)

**Total session time**: 210 minutes (3.5 hrs).

---

## 1. Timers: TON, TOF — 30 min

### 1a. TON (Timer On-Delay) — 12 min
Function block signature:
```iecst
TON_Instance(IN := StartCondition, PT := T#5s);
Q := TON_Instance.Q; // BOOL, true when ET >= PT
ET := TON_Instance.ET; // TIME/DINT, elapsed time
```

Internal state machine:
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

Timing diagram:
```text
IN ___╱‾‾‾‾‾‾‾‾‾╲________╱‾‾‾╲___
ET ___╱‾‾‾‾‾╲____0________╱‾╲__0_
      PT reached IN drops before PT
Q _________╱‾‾‾╲__________________ (Q never asserts on 2nd pulse)
```

Critical behavior: $ET$ resets to $0$ the scan after $IN$ goes false.

### 1b. TOF (Timer Off-Delay) — 12 min
Function block signature:
```iecst
TOF_Instance(IN := MotorRunning, PT := T#30s);
Q := TOF_Instance.Q; // true immediately on IN rising edge, stays true PT after IN falls
```

Timing diagram:
```text
IN ___╱‾‾‾‾‾‾‾‾‾╲___________________
Q  ___╱‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾╲___________
                     |<-- PT (30s) -->|
```

Real-world rung — cooling fan:
```text
|--[ Motor_Running ]------------------( TOF )--|
                                      Timer: FanRunOn
                                      Preset: 30000 (ms)
|--[ FanRunOn.Q ]----------------------( Fan_Output )--|
```

---

## 2. Counters (CTU, CTD) + Edge Detection — 35 min

### 2a. CTU (Count Up) — 8 min
Function block:
```iecst
CTU_Instance(CU := PartSensor, RESET := ResetBtn, PV := 10);
CV := CTU_Instance.CV; // current count
Q  := CTU_Instance.Q;  // true when CV >= PV
```
Count-up input $CU$ is rising-edge sensitive by instruction design.

### 2b. CTD (Count Down) — 7 min
```iecst
CTD_Instance(CD := PartRemoved, LOAD := LoadBtn, PV := StartingCount);
```
CTD loads $CV \leftarrow PV$ via `LOAD` input rather than resetting to $0$.

### 2c. Edge-Triggered Instructions — R_TRIG / F_TRIG — 10 min
Internal state comparison:
```iecst
IF (CurrentInput = TRUE) AND (PreviousInput = FALSE) THEN
    Q := TRUE; // exactly one scan
ELSE
    Q := FALSE;
END_IF;
PreviousInput := CurrentInput;
```

Ladder form:
```text
|--[ PartSensor ]--[ ONS ]----------------( CountPulse )--|
|--[ CountPulse ]---------------------------( CTU )--|
                                            Counter: PartCount
                                            Preset: 10
```

---

## 3. Online Monitoring & Forcing I/O — 25 min

### 3b. Forcing Inputs/Outputs for Testing — 10 min
Mechanism: Forcing intercepts value between physical I/O module and logic engine.
- Normal: `Physical terminal --> Input Image Table --> Logic --> Output Image Table --> Physical terminal`
- Forced: `[FORCED VALUE] --> Input Image Table --> Logic --> [FORCED VALUE] --> Physical terminal`

*Safety caveat*: Forcing bypasses safety interlocks! Always check for and clear active forces before leaving a system in production.

### 3c. Reading Fault/Diagnostic Indicators — 7 min
Order of triage:
1. Check **CPU state** first (RUN/STOP/FAULT LED & fault log).
2. Check **Module-level fault LEDs** next.
3. Only then move into **online logic monitoring**.

---

## 4. Combine Timer + Counter, Group Troubleshooting — 25 min

### 4a. Retentive vs. Non-Retentive Timers — 10 min
RTO (Retentive Timer On):
```iecst
RTO_Instance(IN := MotorRunSignal, PT := T#8h);
ET := RTO_Instance.ET; // accumulates across multiple IN pulses
RES_Instance(RTO_Instance); // separate explicit reset instruction required
```

### 4c. Counter with Built-In Delay (Debounce) — 5 min
```text
|--[ PartSensor ]--[ ONS ]--( DebouncePulse )--|
|--[ DebouncePulse ]----------------( TON )--|
                                    Timer: DebounceTimer
                                    Preset: 3000 (ms)
|--[ DebounceTimer.Q ]---------------( CTU )--|
                                    Counter: PartCount
```

---

## 5. Day Project — Traffic Light Controller — 95 min

Goal: Red $\rightarrow$ Green $\rightarrow$ Yellow $\rightarrow$ Red, looping, timed by TONs, driven by an explicit state variable.

### Option A (INT State Register + EQU):
```text
|--[ TrafficState EQU 0 ]-----------------------------( Red_Light )--|
|--[ TrafficState EQU 0 ]-----------------------------( TON_Red )--|
                                                      Preset: 10000
|--[ TON_Red.Q ]--------------------[ MOV 1, TrafficState ]--( RES TON_Red )--|

|--[ TrafficState EQU 1 ]-----------------------------( Green_Light )--|
|--[ TrafficState EQU 1 ]-----------------------------( TON_Green )--|
                                                      Preset: 8000
|--[ TON_Green.Q ]------------------[ MOV 2, TrafficState ]--( RES TON_Green )--|

|--[ TrafficState EQU 2 ]-----------------------------( Yellow_Light )--|
|--[ TrafficState EQU 2 ]-----------------------------( TON_Yellow )--|
                                                      Preset: 3000
|--[ TON_Yellow.Q ]-----------------[ MOV 0, TrafficState ]--( RES TON_Yellow )--|
```
