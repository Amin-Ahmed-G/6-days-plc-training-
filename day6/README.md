# Day 6 - Capstone Project: Automated Conveyor Sorting System

> "A complete industrial automation project from I/O list to commissioning"

**Duration**: 7 Hours | **Format**: 20% Design + 80% Build/Test/Document
**Prerequisite**: Days 1–5

---

## Learning Outcomes

By the end of Day 6 capstone, you will have demonstrated:
- End-to-end project delivery: requirements -> I/O list -> program -> HMI -> test -> documentation
- Modular FB-based program architecture for maintainability
- Integration of digital sensing, analog scaling, VFD control, HMI, and alarm management
- Fail-safe E-stop architecture (hardwired + software interlock)
- Systematic commissioning: point-to-point I/O test -> logic dry-run -> live production test
- Technical documentation to industry standard

---

## 1. System Overview

### 1.1 Conveyor Sorting System Description

A single conveyor belt transports mixed product (metal and non-metal parts) past two sensors:
- **Optical sensor** (Zone 0): Detects any part (presence detection)
- **Metal proximity sensor** (Zone 2): Discriminates metal parts from non-metal

At **Zone 5**, a pneumatic divert arm kicks metal parts off the main conveyor to a reject bin. Non-metal parts continue to Zone 9 (good-parts bin).

```
    ┌─────────────────────────────────────────────────────────────┐
    │  CONVEYOR BELT (left to right)                              │
    │                                                             │
    │  [Opt]─────────[Metal]──────────────[Divert]────────────   │
    │ Zone 0        Zone 2              Zone 5      Zone 9       │
    │  Part          Metal?             Kick!    Good parts bin   │
    │  detected      detected           (metal only)             │
    └─────────────────────────────────────────────────────────────┘
```

### 1.2 System Diagram

```
Field Devices                PLC                    HMI/VFD
─────────────────────────────────────────────────────────────────
Optical Sensor  ──────────► DI %I0.0                    │
Metal Prox. Sensor ────────► DI %I0.1              PROFINET
Part@Zone5_Sensor ─────────► DI %I0.2                    │
E-Stop (NC) ───────────────► DI %I0.3              ┌────────────┐
VFD Fault (NC) ────────────► DI %I0.4              │   HMI      │
VFD Running ───────────────► DI %I0.5              │  Touchscreen│
                                                    └────────────┘
Divert Arm Solenoid ◄───────── DO %Q0.0
Conveyor VFD Run ◄──────────── DO %Q0.1
Status Tower: Green ◄───────── DO %Q0.2
Status Tower: Red ◄─────────── DO %Q0.3

Conveyor Speed ◄────────────── AO %QW64 (4-20mA to VFD)
```

---

## 2. I/O List (As-Built)

| Tag Name | Address | Type | Signal | Field Device | Notes |
|:---|:---|:---|:---|:---|:---|
| `Optical_Sensor` | `%I0.0` | DI | 24V DC NPN | Sick WL18G | Part presence at Zone 0 |
| `Metal_Prox` | `%I0.1` | DI | 24V DC PNP | Omron E2E-X5MF | Metal detection at Zone 2 |
| `Part_At_Zone5` | `%I0.2` | DI | 24V DC NPN | Sick WL18G | Part trigger for divert |
| `EStop` | `%I0.3` | DI | 24V DC NC | Schmersal ES21 | E-stop, fail-safe NC |
| `VFD_Fault_FB` | `%I0.4` | DI | 24V DC NC | VFD relay output | VFD fault feedback, NC |
| `VFD_Running_FB` | `%I0.5` | DI | 24V DC NO | VFD running output | VFD running status |
| `Divert_Solenoid` | `%Q0.0` | DO Relay | 24V DC | SMC SY3120 | Pneumatic divert arm |
| `Conveyor_VFD_Run` | `%Q0.1` | DO Transistor | 24V DC | VFD DI1 | Conveyor run command |
| `Tower_Green` | `%Q0.2` | DO Transistor | 24V DC | Patlite LA6 | Green = running normal |
| `Tower_Red` | `%Q0.3` | DO Transistor | 24V DC | Patlite LA6 | Red = fault/E-stop |
| `Conveyor_Speed_AO` | `%QW64` | AO | 4–20mA | VFD AI1 | Conveyor speed reference |

---

## 3. Program Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  OB1 (Main Cyclic)                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐   │
│  │ Safety_FB   │  │ Conveyor_FB │  │  Sorting_Logic_FB    │   │
│  │             │  │             │  │                      │   │
│  │ E-Stop check│  │ VFD control │  │ Shift register       │   │
│  │ System ready│  │ Speed ref   │  │ Divert arm control   │   │
│  │ Fault latch │  │ Status lamps│  │ Batch counting       │   │
│  └─────────────┘  └─────────────┘  └──────────────────────┘   │
│                                                                 │
│  ┌──────────────────────┐  ┌──────────────────────────────┐   │
│  │  Alarm_Manager_FB    │  │  HMI_Interface               │   │
│  │                      │  │                              │   │
│  │ Alarm state machines │  │ Read HMI commands            │   │
│  │ Event log writes     │  │ Write HMI displays           │   │
│  │ ACK handling         │  │ Scale speed % to AO raw      │   │
│  └──────────────────────┘  └──────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Core Program Logic

### 4.1 Sorting State Machine (Conveyor Shift Register)

```iecst
PROGRAM Sorting_Logic
VAR
    (* Shift register: tracks which zones have parts and if they are metal *)
    PartPresent    : ARRAY[0..9] OF BOOL;  // is there a part in this zone?
    PartIsMetal    : ARRAY[0..9] OF BOOL;  // is the part in this zone metal?

    (* Zone advancement trigger from encoder or timer *)
    R_TRIG_Advance : R_TRIG;
    ZoneAdvanceTrigger : BOOL;  // from conveyor encoder pulse

    (* Divert arm *)
    DivertArm_Active : BOOL;
    TON_DivertArm    : TON;

    (* Counters *)
    TotalCount     : INT;
    MetalCount     : INT;
    NonMetalCount  : INT;

    (* Inputs *)
    Optical_Sensor  : BOOL;
    Metal_Prox      : BOOL;
    Part_At_Zone5   : BOOL;
END_VAR

(* ── Rising edge on encoder pulse ── *)
R_TRIG_Advance(CLK := ZoneAdvanceTrigger);

IF R_TRIG_Advance.Q THEN
    (* Shift all zones forward *)
    FOR i := 9 DOWNTO 1 DO
        PartPresent[i] := PartPresent[i - 1];
        PartIsMetal[i] := PartIsMetal[i - 1];
    END_FOR;

    (* Load new detections at Zone 0 *)
    PartPresent[0] := Optical_Sensor;
    PartIsMetal[0] := Metal_Prox;

    (* Count new part at zone 0 *)
    IF Optical_Sensor THEN
        TotalCount := TotalCount + 1;
        IF Metal_Prox THEN
            MetalCount := MetalCount + 1;
        ELSE
            NonMetalCount := NonMetalCount + 1;
        END_IF;
    END_IF;
END_IF;

(* ── Divert arm fires when metal part reaches Zone 5 ── *)
IF PartPresent[5] AND PartIsMetal[5] AND Part_At_Zone5 THEN
    DivertArm_Active := TRUE;
END_IF;

(* Auto-retract divert arm after 500ms *)
TON_DivertArm(IN := DivertArm_Active, PT := T#500ms);
IF TON_DivertArm.Q THEN
    DivertArm_Active := FALSE;
    TON_DivertArm(IN := FALSE, PT := T#500ms);
END_IF;

Divert_Solenoid := DivertArm_Active;

END_PROGRAM
```

### 4.2 Safety and E-Stop Logic

```iecst
PROGRAM Safety_FB

(* E-Stop is wired NC — reads 1 when safe, 0 when activated OR wire break *)
System_Safe := EStop AND NOT VFD_Fault_FB;

(* Safety latch: system must be explicitly reset after E-stop *)
IF NOT System_Safe THEN
    System_Running := FALSE;
    EStop_Latched  := TRUE;
END_IF;

IF EStop_Reset_Cmd AND System_Safe THEN
    EStop_Latched := FALSE;
END_IF;

(* System can only run when safe and not latched *)
System_Ready := System_Safe AND NOT EStop_Latched;

(* Status tower lamps *)
Tower_Green := System_Running AND System_Ready;
Tower_Red   := EStop_Latched OR VFD_Fault_FB;
```

---

## 5. Commissioning Procedure

### Phase 1: Point-to-Point I/O Verification

| Test | Method | Expected Result |
|:---|:---|:---|
| Optical sensor activation | Hand in front of sensor | `%I0.0` = 1 in I/O monitor |
| Metal proximity check | Hold metal plate at sensor | `%I0.1` = 1 in I/O monitor |
| E-stop activation | Press E-stop | `%I0.3` = 0 (NC opens) |
| E-stop wire-pull test | Disconnect E-stop wire | `%I0.3` = 0 (fails safe) |
| Divert arm force test | Force `%Q0.0` = 1 | Arm extends, verify retraction |
| VFD run test | Force `%Q0.1` = 1 | VFD starts, belt moves slowly |
| ⚠️ Clear all forces | Remove all forces | All forces cleared before live test |

### Phase 2: Logic Dry-Run (Forced I/O)

| Test | Procedure | Expected Result |
|:---|:---|:---|
| Non-metal part simulation | Force Optical=1, Metal=0, advance 5 zones | No divert arm activation at Zone 5 |
| Metal part simulation | Force Optical=1, Metal=1, advance 5 zones | Divert arm fires at Zone 5 |
| E-stop during run | Press E-stop while belt running | Belt stops, Tower Red ON |
| Reset after E-stop | Release E-stop, press Reset | System ready, Tower Green ON |

### Phase 3: Live Production Test

1. Start conveyor at 30% speed from HMI
2. Feed 10 non-metal parts — verify 0 diversions, NonMetalCount = 10
3. Feed 10 metal parts — verify 10 diversions, MetalCount = 10
4. Mix feed (5 metal, 5 non-metal) — verify correct sorting, counts correct
5. Increase speed to 80% — verify sorting still accurate
6. Trigger E-stop mid-run — verify immediate belt stop, latch, tower red
7. Reset and restart — verify clean restart from safe state

---

## 6. Project Documentation

### 6.1 I/O List
> See [I/O List table above](#-2-io-list-as-built) — this is the as-built reference.

### 6.2 Program Description

| Program Block | Purpose | Key Variables |
|:---|:---|:---|
| `Safety_FB` | E-stop latch, system ready flag, tower lamps | `System_Safe`, `System_Ready`, `EStop_Latched` |
| `Conveyor_FB` | VFD run/stop, speed AO, running status | `Conveyor_VFD_Run`, `Conveyor_Speed_AO` |
| `Sorting_Logic` | Shift register, divert arm, counters | `PartPresent[]`, `PartIsMetal[]`, `DivertArm_Active` |
| `Alarm_Manager` | Alarm states, event log, ACK | `AlarmLog[]`, `AlarmAcked` |

### 6.3 HMI Screen Summary

| Screen | Key Elements |
|:---|:---|
| **Main** | Belt running indicator, speed bar, total/metal/non-metal counts, E-stop status |
| **Alarms** | Active alarm list, ACK button, alarm history |
| **Settings** | Conveyor speed setpoint, divert timing, reset counters |
| **Diagnostics** | I/O status, force panel (maintenance mode) |

---

## Capstone Assessment Rubric

| Criteria | Weight | Marks Available |
|:---|:---|:---|
| I/O list completeness and accuracy | 10% | 10 |
| Program compiles without errors | 10% | 10 |
| Correct sorting logic (all 10 live part tests pass) | 25% | 25 |
| E-stop NC wiring and latch logic correct | 20% | 20 |
| HMI screens functional with tag bindings | 15% | 15 |
| Commissioning test sheet completed | 10% | 10 |
| Technical documentation quality | 10% | 10 |
| **Total** | **100%** | **100** |

---

## Day 6 Files

| File | Description |
|:---|:---|
| [`README.md`](README.md) | This document — Day 6 complete reference & project spec |
| [`Conveyor_Sorting_System.st`](Conveyor_Sorting_System.st) | Complete capstone project ST source code |
| [`IO_List.md`](IO_List.md) | Detailed I/O register with addresses, types, and notes |
| [`Commissioning_Checklist.md`](Commissioning_Checklist.md) | Point-to-point I/O test sheet and sign-off |
