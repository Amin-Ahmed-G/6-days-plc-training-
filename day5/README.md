# 📓 Day 5 — HMI Design, VFD Integration & PID Control

> **"Closing the loop: operator interfaces, variable-speed drives, and process control"**

**Duration**: 7 Hours | **Format**: 40% Lecture/Demo + 60% Hands-On Lab
**Prerequisite**: Day 4 — Advanced Instructions

---

## 🎯 Learning Outcomes

By the end of Day 5, you will be able to:
- ✅ Configure HMI tag bindings to PLC memory and build functional operator screens
- ✅ Design alarm management with severity classification and acknowledgement logic
- ✅ Wire and configure a VFD for digital I/O and analog speed reference from a PLC
- ✅ Explain P, I, and D terms in a PID controller and their effect on loop behavior
- ✅ Configure a PLC PID instruction block for a water level control application
- ✅ Perform basic manual PID tuning using step-response observation

---

## 🖥️ 1. HMI Design Fundamentals

### 1.1 What is an HMI?

A **Human-Machine Interface (HMI)** is the operator touchpoint for a PLC-controlled machine. It:
- **Displays** real-time process values (temperatures, speeds, levels, alarm states)
- **Accepts** operator commands (start/stop, setpoint entry, mode selection)
- **Records** alarm history and process trends

### 1.2 HMI–PLC Communication

| Protocol | Common Platform | Speed | Application |
|:---|:---|:---|:---|
| **PROFINET** | Siemens | Fast (real-time) | Siemens PLC to Siemens HMI panels |
| **EtherNet/IP** | Allen-Bradley | Fast | AB PLCs to PanelView HMIs |
| **OPC-UA** | Multi-vendor | Medium | Cross-vendor SCADA/HMI connections |
| **Modbus TCP** | Multi-vendor | Medium | Legacy and low-cost HMI connections |

### 1.3 Tag Binding

Tag binding maps PLC memory addresses to HMI screen objects:

| HMI Object | Bound PLC Tag | Direction |
|:---|:---|:---|
| Start button (momentary) | `%M0.0` → `HMI_Start_Cmd` | HMI writes to PLC |
| Running indicator lamp | `%Q0.0` → `Motor_Running` | PLC reads to HMI |
| Setpoint numeric entry | `%MD10` → `SpeedSetpoint_pct` | HMI writes to PLC |
| Process value bar graph | `%MD20` → `CurrentSpeed_pct` | PLC reads to HMI |
| Alarm indicator | `%M10.0` → `HighTemp_Alarm` | PLC reads to HMI |

### 1.4 HMI Screen Design Principles

**Main Operator Screen**:
- Process overview (machine state, key values)
- Start/Stop/Reset buttons with confirmation dialogs
- Active alarm count indicator always visible
- Navigation to detail screens

**Alarm Screen**:
- Active alarm list with timestamp, description, and severity
- Acknowledge button
- Alarm history (last 100 events)

**Trend Screen**:
- Historical process values plotted over time
- Configurable time window (1 minute to 24 hours)
- Essential for PID tuning observation

---

## 🔔 2. Alarm Management

### 2.1 Alarm Severity Classification

| Severity | Color | Sound | Response Required | Example |
|:---|:---|:---|:---|:---|
| **Warning** | Yellow | None | Operator awareness | Temp approaching limit |
| **Fault** | Orange | Alert tone | Operator investigation | Sensor signal loss |
| **Critical** | Red | Alarm horn | Immediate intervention + machine stop | E-stop triggered |

### 2.2 Alarm State Machine

```
        [ Normal ]
            │
            │ Alarm condition TRUE
            ▼
        [ Unacknowledged Active ]   ← flashing indicator, horn on
            │                  │
            │ Operator ACKs    │ Condition clears before ACK
            ▼                  ▼
        [ Acknowledged Active ] [ Unacknowledged Inactive ]
            │                       │
            │ Condition clears       │ Operator ACKs
            ▼                       ▼
        [ Normal (cleared) ]    [ Normal (cleared) ]
```

### 2.3 Alarm Acknowledgement Ladder Logic

```iecst
(* Alarm state machine *)
IF HighTempAlarm AND NOT AlarmAcked THEN
    AlarmUnacked := TRUE;
    AlarmHorn    := TRUE;
END_IF;

IF AlarmAcked_Btn THEN
    AlarmAcked := TRUE;
    AlarmHorn  := FALSE;
END_IF;

IF NOT HighTempAlarm THEN
    AlarmAcked    := FALSE;   // reset for next alarm event
    AlarmUnacked  := FALSE;
END_IF;
```

---

## ⚡ 3. Variable Frequency Drive (VFD) Integration

### 3.1 VFD Operating Principle

A **Variable Frequency Drive (VFD)** — also called an **Inverter** or **AC Drive** — controls AC motor speed by varying the frequency and voltage of the output waveform:

$$\text{Motor Speed (RPM)} = \frac{120 \times f}{P}$$

Where $f$ = output frequency (Hz) and $P$ = number of motor poles.

At 50Hz (standard), a 4-pole motor runs at ~1,450 RPM. At 25Hz, it runs at ~725 RPM.

### 3.2 PLC-to-VFD Control Interface

#### Digital I/O Interface (Basic)

| PLC Output | VFD Terminal | Function |
|:---|:---|:---|
| `%Q0.0` → `VFD_Run` | VFD DI1 (RUN) | Start/stop command |
| `%Q0.1` → `VFD_Fwd` | VFD DI2 (FWD/REV) | Direction control |
| `%I0.0` ← `VFD_Fault` | VFD Fault Relay NC | Fault detection |
| `%I0.1` ← `VFD_Running` | VFD Running Output | Status feedback |

#### Analog Speed Reference (4–20mA or 0–10V)

```
PLC Analog Output Channel → VFD Analog Input (AI1)

PLC Output:  0–20mA or 4–20mA or 0–10V
VFD Scaling: 0% speed at 4mA, 100% speed at 20mA (configurable)
```

```iecst
(* Convert speed percentage to 4-20mA raw output count *)
(* Siemens AO: 4mA = 5530 counts, 20mA = 27648 counts *)
VFD_Speed_Raw := INT#5530 + REAL_TO_INT(SpeedSetpoint_pct / REAL#100.0
                 * REAL#(27648 - 5530));
```

### 3.3 VFD Parameter Setup Checklist

| Parameter | Typical Setting | Notes |
|:---|:---|:---|
| Motor rated frequency | 50Hz or 60Hz | Match motor nameplate |
| Motor rated voltage | 380/400/415V | Match motor nameplate |
| Motor rated current | From nameplate | Sets overcurrent protection |
| Acceleration time | 5–30 seconds | Depends on load inertia |
| Deceleration time | 5–30 seconds | Depends on load and braking |
| Analog input type | 4–20mA or 0–10V | Match PLC AO module |
| Speed reference source | Analog input | vs. fixed preset speeds |
| Control mode | V/Hz or Sensorless Vector | Vector = better torque control |

### 3.4 Reading VFD Fault Codes

Common VFD faults and their causes:

| Fault Code | Typical Fault Name | Common Causes |
|:---|:---|:---|
| F001 | Overcurrent | Load jam, too-fast acceleration, short circuit |
| F002 | Overvoltage | Too-fast deceleration, regenerative load |
| F003 | Undervoltage | Supply power dip or failure |
| F004 | Overtemperature | Blocked drive ventilation, high ambient temp |
| F005 | Ground Fault | Motor insulation breakdown, wiring fault |

---

## 🔄 4. PID Control

### 4.1 Closed-Loop Control Concept

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
Setpoint (SP) ─────►│ Error = SP - PV  ──► PID Controller   ├──► Output ──► Process
                    │                                         │
         Process Variable (PV) ◄───────────────────────── Sensor
                    │                                         │
                    └─────────────────────────────────────────┘
```

### 4.2 The Three PID Terms

#### Proportional (P) — React to current error

$$\text{Output}_P = K_p \times e(t)$$

- Larger $K_p$ → faster response but more oscillation
- **Proportional offset (droop)**: P-only control always has a steady-state error because the output is zero only when error is zero — but output must be non-zero to sustain the process

#### Integral (I) — React to accumulated error over time

$$\text{Output}_I = K_i \times \int_0^t e(\tau)\, d\tau$$

- Eliminates steady-state error (offset) by integrating until error is zero
- **Integral windup**: If output saturates (hits 0% or 100%), integral continues accumulating — implement **anti-windup** clamping

#### Derivative (D) — React to rate of change of error

$$\text{Output}_D = K_d \times \frac{de(t)}{dt}$$

- Provides anticipatory damping — reduces overshoot
- Very sensitive to high-frequency noise — apply a **derivative filter**

### 4.3 PLC PID Instruction Configuration (Siemens TIA / Generic)

```iecst
(* PID_Compact block — Siemens TIA Portal style *)
PID_Level(
    Setpoint        := LevelSetpoint_mm,    // REAL: desired level in mm
    Input           := FilteredLevel_mm,    // REAL: scaled level sensor value
    ManualEnable    := ManualMode,          // BOOL: switch to manual control
    ManualValue     := ManualPumpSpeed_pct, // REAL: manual pump speed (0-100%)
    Output          := PumpSpeed_pct        // REAL: output to VFD analog ref
);
```

### 4.4 Manual PID Tuning — Step-Response Method

1. **Set I=0, D=0**, increase P until oscillation begins — call this $K_{cu}$ (critical gain)
2. **Record oscillation period** $T_u$ (time between peaks)
3. **Apply Ziegler-Nichols starting point**: $K_p = 0.6 K_{cu}$, $T_i = 0.5 T_u$, $T_d = 0.125 T_u$
4. **Fine-tune**: reduce overshoot by reducing $K_p$; eliminate offset by adjusting $K_i$

---

## 🚿 5. Day 5 Project — Pump Speed Control System

### 5.1 System Description

Control water level in a tank using a pump driven by a VFD, with the level setpoint entered from an HMI:

```
HMI Setpoint Entry ──────► PLC PID Block ──────► AO Module ──────► VFD Analog In ──────► Pump Speed
                                 ▲
                    Level Sensor (4-20mA → scaled mm)
```

### 5.2 I/O List

| Tag | Address | Type | Description |
|:---|:---|:---|:---|
| `LevelSensor_Raw` | `%IW64` | INT | 4–20mA level sensor raw (0–27648) |
| `FilteredLevel_mm` | `%MD10` | REAL | Scaled and filtered level in mm |
| `LevelSetpoint_mm` | `%MD20` | REAL | HMI setpoint entry |
| `PumpSpeed_pct` | `%MD30` | REAL | PID output → VFD reference |
| `VFD_Speed_Raw` | `%QW64` | INT | Analog output to VFD (0–27648) |
| `VFD_Run` | `%Q0.0` | BOOL | VFD run/stop digital command |
| `VFD_Fault` | `%I0.0` | BOOL | VFD fault relay feedback |
| `HighLevel_Alarm` | `%M10.0` | BOOL | High level alarm (overflow risk) |
| `LowLevel_Alarm` | `%M10.1` | BOOL | Low level alarm (pump dry-run protection) |

### 5.3 Structured Text Program Outline

```iecst
(* ── 1. Scale level sensor ── *)
Normalized := NORM_X(MIN := INT#0, VALUE := LevelSensor_Raw, MAX := INT#27648);
ScaledLevel_mm := SCALE_X(MIN := 0.0, VALUE := Normalized, MAX := REAL#1000.0); // 0-1000mm tank

(* ── 2. Moving average filter ── *)
Samples[2] := Samples[1]; Samples[1] := Samples[0]; Samples[0] := ScaledLevel_mm;
FilteredLevel_mm := (Samples[0] + Samples[1] + Samples[2]) / 3.0;

(* ── 3. Level alarms ── *)
IF FilteredLevel_mm > 950.0 THEN HighLevel_Alarm := TRUE;
ELSIF FilteredLevel_mm < 920.0 THEN HighLevel_Alarm := FALSE; END_IF;

IF FilteredLevel_mm < 50.0 THEN LowLevel_Alarm := TRUE;
ELSIF FilteredLevel_mm > 80.0 THEN LowLevel_Alarm := FALSE; END_IF;

(* ── 4. PID control ── *)
PID_Level(
    Setpoint := LevelSetpoint_mm,
    Input    := FilteredLevel_mm,
    Output   := PumpSpeed_pct
);

(* ── 5. Dry-run protection — inhibit pump if low level alarm ── *)
IF LowLevel_Alarm THEN
    PumpSpeed_pct := 0.0;
    VFD_Run       := FALSE;
ELSE
    VFD_Run := System_Running;
END_IF;

(* ── 6. Scale PID output % to Siemens AO raw count ── *)
VFD_Speed_Raw := REAL_TO_INT(PumpSpeed_pct / 100.0 * 27648.0);
```

---

## 📝 Day 5 Assessment Tasks

| Task | Description | Difficulty |
|:---|:---|:---|
| Task 1 | Build HMI screen with Start/Stop, speed display, alarm indicator | ⭐⭐ Intermediate |
| Task 2 | Configure alarm with 3 severity levels on HMI | ⭐⭐ Intermediate |
| Task 3 | Wire VFD digital I/O (Run/Stop/Fault) to PLC I/O | ⭐⭐ Intermediate |
| Task 4 | Configure VFD analog speed reference from PLC AO | ⭐⭐⭐ Advanced |
| Task 5 | Explain effect of increasing P gain on a step response | ⭐⭐ Intermediate |
| Task 6 | Explain integral windup and implement anti-windup clamping | ⭐⭐⭐ Advanced |
| Task 7 | Build complete pump level control system with PID and HMI | ⭐⭐⭐ Advanced |
| Task 8 | Add dry-run protection and high-level overflow alarm | ⭐⭐⭐ Advanced |

---

## 📂 Day 5 Files

| File | Description |
|:---|:---|
| [`README.md`](README.md) | This document — Day 5 complete reference |
| [`Pump_Level_Control.st`](Pump_Level_Control.st) | PID pump control ST source code |
| [`VFD_IO_Wiring_Guide.md`](VFD_IO_Wiring_Guide.md) | Step-by-step VFD wiring and parameter setup |
