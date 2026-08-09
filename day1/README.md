# Day 1 — PLC Foundations

## 📖 Concept Summary & Technical Guide

### 1. PLC Basics
A **Programmable Logic Controller (PLC)** is a purpose-built industrial computer executing a single control program in a deterministic, cyclic loop: **Read Inputs → Solve Logic → Write Outputs**.
- **Relay Panel Replacement**: Relay panels implement Boolean logic in hardware (physical contact wiring). A PLC replaces physical interlocks with software logic stored in RAM, executed scan by scan against an Input/Output Image Table.
- **Hardware Architecture**:
  ```text
  [Power Supply (24V DC)] --> [CPU] <-- Backplane Bus --> [Input Modules] <-- Sensors/Switches
                                |
                         [Output Modules] --> Actuators/Solenoids/Lamps
  ```

---

### 2. PLC Hardware & Module Selection
- **Power Supply**: Converts mains AC (100–240V AC) to **24V DC**, the near-universal safe industrial standard.
- **Digital Input Modules**: Read voltage as logic `1` (true) or `0` (false) based on threshold values (e.g. ~15V–24V for `1`, ~0V–5V for `0`).
- **Digital Output Modules**:
  | Output Type | Switching Voltage | Response Time | Mechanism | Best Use Case |
  | :--- | :--- | :--- | :--- | :--- |
  | **Relay** | AC or DC | Slower (ms) | Electromechanical | AC/DC loads, high surge capacity, limited cycle life ($10^5-10^6$) |
  | **Transistor** | DC only | Fast ($\mu$s-ms) | Solid-state (NPN/PNP) | DC loads, high-frequency/PWM switching, unlimited mechanical life |
  | **Triac** | AC only | Fast (solid-state AC) | Solid-state AC | AC solenoids, AC indicator lamps, zero-cross switching |

---

### 3. PLC Scan Cycle
The PLC executes a repeating 3-phase cycle:
1. **INPUT SCAN**: Freezes all physical input states into the **Input Image Table (IIT)**.
2. **LOGIC SOLVE**: Executes program top-to-bottom against the frozen IIT and writes outputs to the **Output Image Table (OIT)**.
3. **OUTPUT UPDATE**: Writes the entire OIT out to physical output terminals simultaneously.

> ⚠️ **Key Rule**: A physical input pulse shorter than one scan time can be missed entirely if it goes high and low between input scan phases.

---

### 4. Inputs/Outputs & NO/NC Fail-Safe Design
- **Normally Open (NO)**: Reads `0` at rest, `1` when actuated.
- **Normally Closed (NC)**: Reads `1` at rest, `0` when actuated.
- **Fail-Safe E-Stop Principle**: E-stops **must** be wired **Normally Closed (NC)**.
  - Cut wire / unplugged connector reads logic `0` (same as button pressed) $\rightarrow$ Machine stops safely.
  - Wiring an E-stop NO would let a real wire break go undetected while keeping the machine running.

---

### 5. Rung Logic Basics & Tag Naming
- **AND (Series)**: `Coil := ContactA AND ContactB;`
- **OR (Parallel)**: `Coil := ContactA OR ContactB;`
- **NOT (Negated Contact)**: `Coil := NOT ContactA;`
- **Tag Naming**: Production code uses symbolic names (`Start_PB`, `Motor_Run`) instead of raw addresses (`%I0.0`, `%Q0.0`).

---

## 🛠️ Tasks & Instructor Solutions

### Task 1 — Architecture Labeling
Label signal directions and voltage levels in the PLC architecture:
- Mains side: 100–240V AC. I/O side: 24V DC.
- Logic changes alter program memory only; physical wiring topology remains fixed.

### Task 2 — Relay vs. PLC Scenario
*A packaging line needs a new interlock added.*
- **Relay Panel**: Requires physical re-wiring of contacts across the rack (takes hours, risks wiring errors).
- **PLC**: CPU solves the interlock as part of its stored program executed each scan against the I/O image table; field wiring remains untouched.

### Task 3 — Output Module Selection
1. **230V AC Solenoid**: Relay or Triac (Transistor cannot switch AC).
2. **High-frequency PWM DC valve**: Transistor (DC only, high speed, no mechanical wear).
3. **24V DC lamp switched 50,000 times/day**: Transistor (Avoids mechanical relay wear limit).

### Task 4 — Trace the Scan
A button press mid-scan is captured on the *next* scan's Input Scan phase, solved in Logic Solve, and energized during Output Update.

### Task 7 — E-Stop Fault Analysis
| Wiring | Physical Condition | Logic Level | Machine State | Safety |
| :--- | :--- | :--- | :--- | :--- |
| **NC** | Cut Wire / Unplugged | `0` | STOPS | ✅ Safe |
| **NC** | Actuated (Pressed) | `0` | STOPS | ✅ Safe |
| **NO** | Cut Wire / Unplugged | `0` | KEEPS RUNNING | ❌ Unsafe Fault |
| **NO** | Actuated (Pressed) | `1` / `0` | Depends | ❌ Unreliable |

---

## 💻 Day 1 Projects

### Project 1: Two-Button AND / OR Logic
```text
// Ladder AND Version
|--[ PB1 ]--[ PB2 ]------------------------------------( Lamp )--|

// Structured Text AND Version
Lamp := PB1 AND PB2;

// Ladder OR Version
|--[ PB1 ]---------------------------------------------( Lamp )--|
|--[ PB2 ]---------------------------------------------|

// Structured Text OR Version
Lamp := PB1 OR PB2;
```

---

### Project 2: Motor Start/Stop with Seal-In Circuit (Day Project)

#### Concept
A momentary NO `Start_PB` energizes `Motor_Run`. The output's own NO contact is wired in parallel with `Start_PB` (the seal-in contact) to maintain power after release. An NC `Stop_PB` breaks the circuit.

#### Ladder Diagram
```text
|--[ Start_PB ]----+----------------[/ Stop_PB ]------( Motor_Run )--|
|                  |
|--[ Motor_Run ]---+ (Seal-in contact)
```

#### Structured Text
```iecst
Motor_Run := (Start_PB OR Motor_Run) AND NOT Stop_PB;
```

---

### Stretch Project: Forward/Reverse Mutual-Exclusion Interlock

#### Ladder Diagram
```text
|--[ Fwd_PB ]----+----------------[/ Stop_PB ]--[/ Rev_Run ]--( Fwd_Run )--|
|                |
|--[ Fwd_Run ]---+

|--[ Rev_PB ]----+----------------[/ Stop_PB ]--[/ Fwd_Run ]--( Rev_Run )--|
|                |
|--[ Rev_Run ]---+
```

#### Structured Text
```iecst
Fwd_Run := (Fwd_PB OR Fwd_Run) AND NOT Stop_PB AND NOT Rev_Run;
Rev_Run := (Rev_PB OR Rev_Run) AND NOT Stop_PB AND NOT Fwd_Run;
```
> 💡 **Scan Order Rule**: If both buttons are pressed on the exact same scan, top-to-bottom scan order determines the winner. Whichever rung evaluates first energizes its output and locks out the other on the subsequent scan.
