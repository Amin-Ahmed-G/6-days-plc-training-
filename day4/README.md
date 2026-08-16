# Day 4 - Advanced Instructions: Sequencers, Data Blocks & Reusable Code

> "Production-grade PLC code: structured, reusable, and maintainable"

**Duration**: 7 Hours | **Format**: 40% Lecture/Demo + 60% Hands-On Lab
**Prerequisite**: Day 3 — Analog I/O, Scaling & Data Processing

---

## Learning Outcomes

By the end of Day 4, you will be able to:
- Design and use Data Blocks with structured variable types
- Process arrays of I/O values using FOR/WHILE loops in Structured Text
- Implement a multi-step industrial sequencer using CASE statements
- Use shift registers (BSL/BSR) for conveyor product-tracking buffers
- Write reusable Function Blocks (FBs) with instance data for multi-motor systems
- Build an 8-step batch process sequencer with step timers and fault recovery

---

## 1. Data Blocks & Structured Variables

### 1.1 Why Data Blocks?

In production PLC programs, grouping related variables into a **Data Block (DB)** provides:
- **Organization**: All conveyor data in `DB_Conveyor`, all mixer data in `DB_Mixer`
- **Reusability**: FBs can use instance DBs — each FB call gets its own data copy
- **HMI accessibility**: DB variables are easily mapped to HMI tags by path (`DB1.Conveyor_Speed`)

### 1.2 STRUCT Declaration

```iecst
TYPE Motor_Data : STRUCT
    Running      : BOOL;
    Faulted      : BOOL;
    SpeedRef_pct : REAL;       // 0.0 – 100.0% speed reference
    RunHours     : REAL;       // accumulated run hours
    FaultCode    : INT;        // VFD fault code
END_STRUCT;
END_TYPE

TYPE Batch_Step : STRUCT
    StepNumber   : INT;
    StepName     : STRING[32];
    StepTimer_PT : TIME;       // preset duration
    Complete     : BOOL;
END_STRUCT;
END_TYPE
```

### 1.3 Data Block Instance

```iecst
VAR_GLOBAL
    DB_Motors    : ARRAY[0..7] OF Motor_Data;    // 8 motor data records
    DB_Batch     : ARRAY[0..7] OF Batch_Step;    // 8 batch step records
    DB_AlarmLog  : ARRAY[0..99] OF ALARM_ENTRY;  // 100-entry circular log
END_VAR
```

### 1.4 MOV and BLKMOV Instructions

```iecst
(* MOV — single value transfer *)
DB_Motors[ActiveMotor].SpeedRef_pct := NewSpeedReference;

(* BLKMOV — block copy array segment *)
// Copy first 4 recipe values to active recipe area
FOR i := 0 TO 3 DO
    ActiveRecipe[i] := RecipeLibrary[SelectedRecipe, i];
END_FOR;
```

---

## 2. Loops in Structured Text

### 2.1 FOR Loop — Bounded Iteration

```iecst
(* Scale all 8 analog inputs in one loop — no repeated code *)
FOR i := 0 TO 7 DO
    IF RawMax[i] > RawMin[i] THEN  // division-by-zero guard
        ScaledValues[i] := (INT_TO_REAL(RawInputs[i]) - RawMin[i])
                           / (RawMax[i] - RawMin[i])
                           * (EUMax[i] - EUMin[i])
                           + EUMin[i];
    ELSE
        ScaledValues[i] := 0.0;
    END_IF;
END_FOR;
```

### 2.2 WHILE Loop — Condition-Based Iteration

```iecst
(* Find first available slot in alarm log *)
SearchIndex := 0;
WHILE (SearchIndex < LOG_SIZE) AND NOT AlarmLog[SearchIndex].Empty DO
    SearchIndex := SearchIndex + 1;
END_WHILE;

IF SearchIndex < LOG_SIZE THEN
    (* Write to found slot *)
    AlarmLog[SearchIndex].Temperature := CurrentTemp;
    AlarmLog[SearchIndex].Empty := FALSE;
END_IF;
```

> ⚠️ **WHILE loop caution**: A WHILE loop that never exits causes a **watchdog timeout** and CPU fault. Always ensure loop can terminate, and use FOR loops where iteration count is known.

---

## 3. Sequencer Design - CASE Statement Pattern

### 3.1 Why Use a State Machine/Sequencer?

A sequential machine process (mix → heat → transfer → drain → clean) has:
- **Steps that must happen in order** — not all at once
- **Time-based or condition-based transitions**
- **Fault states** that interrupt normal flow

A state machine with a `CASE` statement is the IEC 61131-3 standard approach.

### 3.2 8-Step Batch Sequencer

```iecst
PROGRAM Batch_Sequencer
VAR
    BatchState     : INT := 0;    // current step number
    TON_Step       : TON;         // single reusable timer instance
    FaultDetected  : BOOL;        // from any step's fault detection
    BatchComplete  : BOOL;
    (* Physical I/O *)
    InletValve     : BOOL;
    MixerMotor     : BOOL;
    HeaterEnable   : BOOL;
    TransferPump   : BOOL;
    DrainValve     : BOOL;
    TempOK         : BOOL;        // from temp comparison
    LevelFull      : BOOL;        // from level sensor
    TankEmpty      : BOOL;        // from level sensor
END_VAR

(* ── Fault override — runs BEFORE case, highest priority ── *)
IF FaultDetected AND BatchState <> 99 THEN
    (* Stop all outputs *)
    InletValve    := FALSE;
    MixerMotor    := FALSE;
    HeaterEnable  := FALSE;
    TransferPump  := FALSE;
    DrainValve    := FALSE;
    TON_Step(IN := FALSE, PT := T#0s);
    BatchState    := 99;   // jump to fault state
END_IF;

CASE BatchState OF

    0:  (* IDLE — waiting for start command *)
        BatchComplete := FALSE;
        (* Transition: start command received externally *)

    1:  (* FILL — open inlet valve until level full *)
        InletValve := TRUE;
        IF LevelFull THEN
            InletValve := FALSE;
            BatchState := 2;
        END_IF;

    2:  (* MIX — run mixer for 10 minutes *)
        MixerMotor := TRUE;
        TON_Step(IN := TRUE, PT := T#10m);
        IF TON_Step.Q THEN
            TON_Step(IN := FALSE, PT := T#10m);
            MixerMotor := FALSE;
            BatchState := 3;
        END_IF;

    3:  (* HEAT — heat until temperature OK *)
        HeaterEnable := TRUE;
        IF TempOK THEN
            HeaterEnable := FALSE;
            BatchState   := 4;
        END_IF;

    4:  (* HOLD — maintain temperature for 15 min *)
        HeaterEnable := TRUE;
        TON_Step(IN := TRUE, PT := T#15m);
        IF TON_Step.Q THEN
            TON_Step(IN := FALSE, PT := T#15m);
            BatchState := 5;
        END_IF;

    5:  (* TRANSFER — pump to downstream vessel *)
        TransferPump := TRUE;
        TON_Step(IN := TRUE, PT := T#5m);
        IF TON_Step.Q OR TankEmpty THEN
            TON_Step(IN := FALSE, PT := T#5m);
            TransferPump := FALSE;
            BatchState   := 6;
        END_IF;

    6:  (* DRAIN — open drain valve, wait tank empty *)
        DrainValve := TRUE;
        IF TankEmpty THEN
            DrainValve := FALSE;
            BatchState := 7;
        END_IF;

    7:  (* RINSE — fill with water, drain, complete *)
        TON_Step(IN := TRUE, PT := T#3m);
        IF TON_Step.Q THEN
            TON_Step(IN := FALSE, PT := T#3m);
            BatchComplete := TRUE;
            BatchState    := 0;   // return to IDLE
        END_IF;

    99: (* FAULT STATE — operator reset required *)
        (* All outputs already cleared in fault override above *)
        (* HMI displays fault, operator acknowledges and resets *)

ELSE
    BatchState := 0;   // safety default

END_CASE;

END_PROGRAM
```

---

## 4. Shift Register - Conveyor Product Tracking

### 4.1 Application

A conveyor has 10 zones. Each zone has one output (kicker solenoid). When a product enters Zone 0, it should be kicked at Zone 5 only. A shift register tracks product position:

```
Conveyor zones:     [0] [1] [2] [3] [4] [5] [6] [7] [8] [9]
ProductBits (BOOL array): [1]  0   0   0   0   0   0   0   0   0
                    ↓ each scan cycle (triggered by encoder pulse)
                           0  [1]  0   0   0   0   0   0   0   0
                    ↓
                           0   0  [1]  0   0   0   0   0   0   0
                    ↓ (5 more shifts)
                           0   0   0   0   0  [1]  0   0   0   0
                                              ↑ Kick solenoid fires here!
```

```iecst
(* Triggered by encoder pulse (1 pulse per zone advance) *)
R_TRIG_Encoder(CLK := EncoderPulse);

IF R_TRIG_Encoder.Q THEN
    (* Shift all bits one position forward (BSL equivalent) *)
    FOR i := CONV_LENGTH - 1 DOWNTO 1 DO
        ProductBits[i] := ProductBits[i - 1];
    END_FOR;
    ProductBits[0] := NewPartDetected;   // load new detection at zone 0
END_IF;

(* Drive kicker solenoid at zone 5 *)
KickerSolenoid := ProductBits[5];
```

---

## 5. Reusable Function Blocks

### 5.1 FC vs. FB

| Feature | Function (FC) | Function Block (FB) |
|:---|:---|:---|
| Internal state (memory) | ❌ No — stateless | ✅ Yes — instance data persists |
| Multiple instances | Same code, no per-instance data | Each instance has its own data DB |
| Use case | Conversion calculations | Motor control, PID loops, timers |

### 5.2 Motor Control Function Block

```iecst
FUNCTION_BLOCK Motor_Control_FB
VAR_INPUT
    Start_Cmd    : BOOL;    // from HMI or sequence
    Stop_Cmd     : BOOL;    // from HMI, E-stop, or sequence
    Reset_Fault  : BOOL;    // from HMI
    VFD_Fault    : BOOL;    // from VFD fault relay input
END_VAR
VAR_OUTPUT
    Running      : BOOL;    // status to HMI
    Faulted      : BOOL;    // status to HMI
    Coil_Out     : BOOL;    // to VFD Run input
END_VAR
VAR
    MotorState   : INT;     // 0=Stopped, 1=Running, 2=Faulted
END_VAR

(* ── Fault detection — always runs first ── *)
IF VFD_Fault AND MotorState = 1 THEN
    MotorState := 2;
END_IF;

CASE MotorState OF
    0: (* Stopped *)
        Coil_Out := FALSE;
        Running  := FALSE;
        Faulted  := FALSE;
        IF Start_Cmd AND NOT VFD_Fault THEN
            MotorState := 1;
        END_IF;

    1: (* Running *)
        Coil_Out := TRUE;
        Running  := TRUE;
        Faulted  := FALSE;
        IF Stop_Cmd THEN
            MotorState := 0;
        END_IF;

    2: (* Faulted *)
        Coil_Out := FALSE;
        Running  := FALSE;
        Faulted  := TRUE;
        IF Reset_Fault AND NOT VFD_Fault THEN
            MotorState := 0;
        END_IF;
END_CASE;

END_FUNCTION_BLOCK
```

### 5.3 Instantiating Multiple Motors

```iecst
VAR
    (* Each instance has independent state — instance data stored in separate DBs *)
    ConveyorMotor    : Motor_Control_FB;
    MixerMotor       : Motor_Control_FB;
    FeedPumpMotor    : Motor_Control_FB;
END_VAR

(* Call each instance with its own I/O signals *)
ConveyorMotor(
    Start_Cmd   := HMI_Conveyor_Start,
    Stop_Cmd    := HMI_Conveyor_Stop OR EStop_Active,
    Reset_Fault := HMI_Conv_Reset,
    VFD_Fault   := DI_ConvVFD_Fault
);
ConveyorRun_Status := ConveyorMotor.Running;

MixerMotor(
    Start_Cmd   := BatchState = 2,   // started by sequencer in step 2
    Stop_Cmd    := NOT (BatchState = 2),
    Reset_Fault := HMI_Mixer_Reset,
    VFD_Fault   := DI_MixerVFD_Fault
);
```

---

## Day 4 Assessment Tasks

| Task | Description | Difficulty |
|:---|:---|:---|
| Task 1 | Create a STRUCT for a pump with: running, fault, speed, run-hours | Intermediate |
| Task 2 | Use FOR loop to scale 8 analog inputs to engineering units | Intermediate |
| Task 3 | Implement a 6-step fill-mix-heat-transfer-drain-clean sequencer | Advanced |
| Task 4 | Add step-timeout fault detection to the sequencer | Advanced |
| Task 5 | Build a 10-zone conveyor shift register in ST | Advanced |
| Task 6 | Write a Motor_Control FB and instantiate 3 motors | Advanced |
| Task 7 | Add RunHours accumulation inside Motor_Control FB using RTO | Advanced |

---

## Day 4 Files

| File | Description |
|:---|:---|
| [`README.md`](README.md) | This document - Day 4 complete reference |
| [`sys_time_and_date.project`](sys_time_and_date.project) | CODESYS project: System time and date function simulation |
| [`PLC-DAY-4.pdf`](PLC-DAY-4.pdf) | Day 4 Presentation Slides & Learning Content PDF |
| [`Day4_Colored.pdf`](Day4_Colored.pdf) | Day 4 Colored Reference PDF |
| [`Day4_Learning_Content.pdf`](Day4_Learning_Content.pdf) | Day 4 Learning Content PDF |
| [`Day4_PLC_Training.pdf`](Day4_PLC_Training.pdf) | Day 4 Training Overview PDF |
| [`Batch_Sequencer.st`](Batch_Sequencer.st) | 8-Step Batch Sequencer ST source code |
| [`Motor_Control_FB.st`](Motor_Control_FB.st) | Reusable Motor Control Function Block |
| [`Conveyor_Shift_Register.st`](Conveyor_Shift_Register.st) | 10-zone shift register tracking logic |
