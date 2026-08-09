# Day 1 - PLC Foundations & Basic Ladder Logic

> "From relay panels to stored-program industrial computers"

**Duration**: 7 Hours | **Format**: 60% Lecture/Demo + 40% Hands-On Lab
**Standard**: IEC 61131-3 | **Platform**: Siemens S7-1200 / Allen-Bradley CompactLogix

---

## Learning Outcomes

By the end of Day 1, you will be able to:
- Label and explain every major component in a PLC hardware panel
- Calculate correct wire sizing and protection for 24V DC I/O circuits
- Select the correct digital output module type (relay/transistor/triac) for a given load
- Describe all 3 phases of the PLC scan cycle and predict I/O timing behavior
- Write and interpret ladder logic rungs for AND, OR, NOT, SET, and RESET operations
- Implement a motor Start/Stop circuit with Seal-In and a Forward/Reverse interlock
- Explain and demonstrate fail-safe NC E-stop wiring

---

## 1. Introduction to PLCs

### 1.1 What is a PLC?

A **Programmable Logic Controller (PLC)** is an industrially hardened digital computer designed to control manufacturing processes, machinery, and automation systems. Unlike general-purpose computers, a PLC:

- Executes a single control program in a **deterministic, repeating scan cycle**
- Is hardened for **industrial environments** (vibration, EMI, temperature extremes, dust)
- Reads **physical input signals** (sensors, switches) and drives **physical output signals** (motors, valves, lamps)
- Provides **real-time, predictable response** (scan times typically 1–10ms)

### 1.2 PLC vs. Relay Control Panel

| Feature | Relay Panel | PLC |
|:---|:---|:---|
| Logic Implementation | Physical wire connections | Stored program in CPU RAM |
| Logic Change | Re-wiring required (hours/days) | Program edit + download (minutes) |
| Diagnostics | Voltage meter, visual inspection | Online monitoring, fault logs |
| Expandability | Add physical relays | Add I/O modules |
| Maintenance | Mechanical relay replacement | Module swap |
| Documentation | Wiring diagram | Program + I/O list |

### 1.3 PLC Hardware Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PLC PANEL                                │
│                                                                 │
│  ┌──────────┐    ┌─────────┐    ┌──────────┐    ┌──────────┐  │
│  │  POWER   │    │   CPU   │    │  DIGITAL │    │  DIGITAL │  │
│  │  SUPPLY  │◄───│         │───►│  INPUT   │    │  OUTPUT  │  │
│  │          │    │ RAM     │    │  MODULE  │    │  MODULE  │  │
│  │ AC→24VDC │    │ Program │    │          │    │          │  │
│  │          │    │ I/O     │    │ %I0.0    │    │ %Q0.0    │  │
│  │          │    │ Image   │    │ %I0.1    │    │ %Q0.1    │  │
│  │          │    │ Table   │    │ %I0.2    │    │ %Q0.2    │  │
│  └──────────┘    └─────────┘    └────┬─────┘    └────┬─────┘  │
│         ▲                           │               │         │
│         │              Backplane Bus │               │         │
└─────────┼───────────────────────────┼───────────────┼─────────┘
          │                           │               │
      Mains AC                   Field Wiring      Field Wiring
    100-240V AC               (Sensors/Switches)  (Actuators/Lamps)
```

### 1.4 Why 24V DC?

The 24V DC standard is used for field-side I/O for three reasons:
1. **Safety**: Below the 50V AC / 120V DC threshold considered dangerous for contact — less lethal in a pinch
2. **Standardisation**: Virtually every industrial sensor and actuator manufacturer builds to 24V DC — universal compatibility
3. **Noise immunity**: 24V swing is large enough to reject typical EMI from VFDs and motors compared to 5V/12V logic

---

## 2. Digital I/O Modules

### 2.1 Digital Input Module Electrical Behavior

A digital input module converts a physical voltage at its terminal into a logic state:
- **Logic 1 (TRUE)**: ≥ 15V DC at terminal
- **Logic 0 (FALSE)**: ≤ 5V DC at terminal
- **Undefined region**: 5V–15V — avoid by design

> ⚠️ **Critical**: The module reads voltage state only. It does NOT know if the field device is wired NO or NC — that is the programmer's responsibility in ladder logic.

### 2.2 Sinking vs. Sourcing (NPN vs. PNP)

| Wiring Type | Current Direction | Sensor Type | Common In |
|:---|:---|:---|:---|
| **Sinking (NPN)** | Current flows INTO sensor output | NPN open-collector | Europe, Siemens |
| **Sourcing (PNP)** | Current flows OUT OF sensor output | PNP open-collector | Americas, Allen-Bradley |

### 2.3 Digital Output Module Selection

| Module Type | Switches | Max Switching Speed | Mechanical Wear | Load Types |
|:---|:---|:---|:---|:---|
| **Relay** | AC or DC | Slow (5–10ms, mechanical) | Yes (~10⁶ cycles) | Any voltage/current within rating |
| **Transistor (BJT/FET)** | DC only | Fast (μs–ms) | None (solid-state) | DC actuators, PWM signals |
| **Triac** | AC only | Fast (solid-state AC) | None (solid-state) | AC solenoids, AC indicator lamps |

**Selection Rule**:
- AC load → Relay or Triac
- DC load with high switching frequency → Transistor
- Mixed AC/DC panel needing galvanic isolation → Relay

---

## 3. PLC Scan Cycle

### 3.1 The Three-Phase Cycle

```
┌─────────────────────────────────────────────────────────┐
│                    ONE SCAN CYCLE                       │
│                                                         │
│   Phase 1          Phase 2           Phase 3            │
│ ┌──────────┐     ┌──────────┐     ┌──────────┐          │
│ │  INPUT   │────►│  LOGIC   │────►│  OUTPUT  │──► (repeat)
│ │   SCAN   │     │  SOLVE   │     │  UPDATE  │          │
│ └──────────┘     └──────────┘     └──────────┘          │
│                                                         │
│  Read all physical    Execute entire    Write OIT to    │
│  inputs into IIT.     program against   physical        │
│  Inputs are FROZEN    frozen IIT.       terminals.      │
│  for entire scan.     Write to OIT.                     │
└─────────────────────────────────────────────────────────┘
```

**Phase 1 — INPUT SCAN**:
- All physical input terminal voltages are sampled simultaneously
- Values are stored in the **Input Image Table (IIT)** — a block of RAM
- These values are FROZEN — the program reads from IIT only, not physical terminals

**Phase 2 — LOGIC SOLVE**:
- CPU executes program instructions top-to-bottom, rung by rung
- All reads come from the frozen IIT
- All writes go to the **Output Image Table (OIT)** — another RAM block
- Physical outputs are NOT yet updated during this phase

**Phase 3 — OUTPUT UPDATE**:
- The entire OIT is written to physical output terminals simultaneously
- Only now do actuators, lamps, and motors see the new logic result

### 3.2 Scan Time Implications

With a 5ms scan time, any input pulse shorter than 5ms may be missed completely if it occurs between two Input Scan phases. Solutions:
- **Hardware interrupt inputs** (fast inputs with dedicated interrupt OBs)
- **Hardware latching circuits** that hold a pulse until the next scan reads it

---

## 4. NO/NC Contacts & Fail-Safe Wiring

### 4.1 Normally Open (NO) vs. Normally Closed (NC)

| Contact Type | Rest State | Actuated State | Logic at Rest | Logic When Actuated |
|:---|:---|:---|:---|:---|
| **NO (Normally Open)** | Open circuit | Closed circuit | 0 | 1 |
| **NC (Normally Closed)** | Closed circuit | Open circuit | 1 | 0 |

### 4.2 The Fail-Safe Principle — Why E-Stops MUST Be NC

| Scenario | NC Wiring | NO Wiring |
|:---|:---|:---|
| E-stop pressed (normal operation) | Circuit opens → reads 0 → machine stops ✅ | Circuit closes → reads 1 → ... wait |
| Wire cut / connector unplugged | Circuit opens → reads 0 → machine STOPS ✅ | Circuit stays open → reads 0 → BUT machine still runs ❌ |
| Terminal corrodes open | Circuit opens → reads 0 → machine STOPS ✅ | Machine keeps running, fault invisible ❌ |

> ⚠️ **Safety Rule**: An E-stop wired NO is invisible to the PLC when a wire breaks. Only NC wiring guarantees that every fault mode (wire break, connector failure, switch mechanism failure) causes a safe machine stop.

---

## 5. Ladder Logic Programming

### 5.1 Anatomy of a Ladder Rung

```
  Left Power Rail                                    Right Power Rail
        │                                                    │
  Rung  ├──[Contact 1]──[Contact 2]──────────(Output Coil)──┤
        │                                                    │
```

### 5.2 Core Instructions

#### Normally Open Contact `[ ]`
Passes power when its associated bit is **TRUE (1)**.
```
|──[ Start_PB ]──|
```

#### Normally Closed Contact `[/]`
Passes power when its associated bit is **FALSE (0)** — inverse logic.
```
|──[/Stop_PB ]──|
```

#### Output Coil `( )`
Sets its associated bit TRUE when rung has power flow; FALSE otherwise.
```
|──────────────────────────( Motor_Run )──|
```

#### SET / RESET (Latch / Unlatch)
- **SET (S)**: Latches bit to TRUE. Remains TRUE even if SET rung loses power.
- **RESET (R)**: Unlatches bit to FALSE. Remains FALSE even if RESET rung loses power.

### 5.3 Logic Gate Implementation in Ladder

#### AND Gate (Series)
```
  |──[ PB1 ]──[ PB2 ]──────────────────( Lamp )──|
```
- `Lamp` energizes only when BOTH PB1 AND PB2 are TRUE

#### OR Gate (Parallel)
```
  |──[ PB1 ]──────────────────────────( Lamp )──|
  |                                             |
  |──[ PB2 ]──────────────────────────────────|
```
- `Lamp` energizes when EITHER PB1 OR PB2 is TRUE

#### NOT Gate (Negated Contact)
```
  |──[/GuardDoor_Closed ]──────────────( Alarm )──|
```
- `Alarm` energizes when `GuardDoor_Closed` is FALSE (door open)

### 5.4 Tag Naming Best Practice

| Raw Address | ❌ Bad Name | ✅ Good Name |
|:---|:---|:---|
| `%I0.0` | `Input_0` | `Start_PB` |
| `%I0.1` | `Input_1` | `Stop_PB` |
| `%Q0.0` | `Output_0` | `Motor_Run` |
| `%Q0.1` | `Output_1` | `Fwd_Contactor` |
| `%M0.0` | `Mem_0` | `System_Ready` |

---

## 6. Motor Start/Stop with Seal-In Circuit

### 6.1 Concept

A momentary NO Start button energizes `Motor_Run`. The output's own contact is wired in **parallel with Start** (the **seal-in contact**) to maintain power flow after Start is released. An NC Stop button breaks the entire circuit.

### 6.2 Ladder Diagram

```
  Power Rail (+)                                                  Power Rail (-)
       │                                                               │
  1    ├──┬──[ Start_PB ]──┬──────────────[/Stop_PB ]──────( Motor_Run )──┤
       │  │    (NO)        │               (NC)               (Coil)       │
       │  │                │                                              │
       │  └──[ Motor_Run ]─┘                                              │
       │       (NO Seal-in)                                               │
```

### 6.3 Structured Text Equivalent

```iecst
(* Motor Start/Stop with Seal-In *)
Motor_Run := (Start_PB OR Motor_Run) AND NOT Stop_PB;
```

### 6.4 Step-by-Step Trace

| Step | Start_PB | Stop_PB | Motor_Run (prev scan) | Motor_Run (result) |
|:---|:---|:---|:---|:---|
| 1 — Power on, nothing pressed | 0 | 1 (NC) | 0 | 0 |
| 2 — Start button pressed | 1 | 1 (NC) | 0 | 1 ✅ STARTS |
| 3 — Start button released | 0 | 1 (NC) | 1 (seal-in) | 1 ✅ SEALED |
| 4 — Stop button pressed | 0 | 0 (NC opens) | 1 | 0 ❌ STOPS |
| 5 — Stop button released | 0 | 1 (NC) | 0 | 0 |

---

## 7. Forward/Reverse Interlock (Stretch Project)

### 7.1 Design Requirements

Two contactors (Forward and Reverse) must **never energize simultaneously** — simultaneous energization would short-circuit the motor power phases causing immediate motor/drive damage.

### 7.2 Hardware Interlock
Wire a mechanical auxiliary contact of the Forward contactor into the coil circuit of the Reverse contactor and vice versa. This is the **mandatory hardware interlock** — it works even during a PLC failure.

### 7.3 Software Interlock (Additional Layer)

```
  Power Rail (+)                                                            Power Rail (-)
       │                                                                         │
  1    ├──┬──[ Fwd_PB ]──┬──────[/Stop_PB ]──────[/Rev_Run ]──────( Fwd_Run )──┤
       │  │    (NO)      │       (NC)               (NC Interlock)   (Coil)      │
       │  │              │                                                       │
       │  └──[ Fwd_Run ]─┘                                                      │
       │      (Seal-in)                                                          │
       │                                                                         │
  2    ├──┬──[ Rev_PB ]──┬──────[/Stop_PB ]──────[/Fwd_Run ]──────( Rev_Run )──┤
       │  │    (NO)      │       (NC)               (NC Interlock)   (Coil)      │
       │  │              │                                                       │
       │  └──[ Rev_Run ]─┘                                                      │
       │      (Seal-in)                                                          │
```

### 7.4 Structured Text

```iecst
(* Forward/Reverse Motor Control — Mutual Exclusion *)
Fwd_Run := (Fwd_PB OR Fwd_Run) AND NOT Stop_PB AND NOT Rev_Run;
Rev_Run := (Rev_PB OR Rev_Run) AND NOT Stop_PB AND NOT Fwd_Run;
```

> 💡 **Scan Order Note**: If both buttons are pressed simultaneously, `Fwd_Run` (Rung 1) evaluates first. `Fwd_Run` goes TRUE, immediately opening the `[/Fwd_Run]` NC contact in Rung 2, preventing `Rev_Run` from energizing — all within a single scan cycle.

---

## Day 1 Assessment Tasks

| Task | Description | Difficulty |
|:---|:---|:---|
| Task 1 | Label all PLC panel components on a given diagram | Beginner |
| Task 2 | Select output module type for 3 given load scenarios | Beginner |
| Task 3 | Trace a scan cycle: predict which output activates first | Intermediate |
| Task 4 | Wire a push-button to an input terminal and verify in I/O monitor | Intermediate |
| Task 5 | Build AND logic (PB1 + PB2 -> Lamp), test | Intermediate |
| Task 6 | Build OR logic (PB1 OR PB2 -> Lamp), test | Intermediate |
| Task 7 | Explain E-stop wiring fault analysis table | Intermediate |
| Task 8 | Build Motor Start/Stop seal-in circuit, test, trace | Intermediate |
| Task 9 | Add run-indicator lamp to motor circuit | Intermediate |
| Task 10 | Build Forward/Reverse with interlock, test both directions | Advanced |
| Task 11 | Prove interlock works: press both buttons simultaneously | Advanced |
| Task 12 | Convert motor seal-in ladder to Structured Text | Advanced |

---

## Day 1 Files

| File | Description |
|:---|:---|
| [`README.md`](README.md) | This document - Day 1 complete reference |
| [`Motor.project`](Motor.project) | CODESYS project: Motor forward-reverse seal-in (built and simulated) |
| [`example.project`](example.project) | CODESYS project: Day 1 logic practice example |
| [`Ladder_Diagrams.md`](Ladder_Diagrams.md) | All Day 1 ladder diagrams (ASCII + descriptions) |
| [`Motor_SealIn_Circuit.st`](Motor_SealIn_Circuit.st) | Structured Text source code |
| [`Day1_Foundations_Teaching_Material.md`](Day1_Foundations_Teaching_Material.md) | Full instructor session notes |
| [`Day1_Tasks_and_Solutions.md`](Day1_Tasks_and_Solutions.md) | All tasks with full solutions |
