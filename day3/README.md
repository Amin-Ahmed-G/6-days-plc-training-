# Day 3 - Analog I/O, Scaling & Data Processing

> "Reading the physical world: temperature, pressure, and level - in engineering units"

**Duration**: 7 Hours | **Format**: 45% Lecture/Demo + 55% Hands-On Lab
**Prerequisite**: Day 2 — Timers, Counters & Fault Diagnosis

---

## Learning Outcomes

By the end of Day 3, you will be able to:
- Explain why 4-20mA is preferred over 0-10V for industrial applications
- Calculate engineering units from raw ADC counts using the scaling formula
- Implement NORM_X/SCALE_X and SCL scaling instructions in a PLC program
- Apply arithmetic instructions with correct division-by-zero guards
- Select correct data types (BOOL/INT/DINT/REAL) for a given variable
- Implement alarm hysteresis (dead-band) logic to prevent contact chatter
- Build a 3-sample FIFO moving average filter for noisy analog signals
- Build a complete temperature monitoring system from sensor to alarm log

---

## 1. Analog Signal Theory

### 1.1 The 4–20mA Current Loop

The **4–20mA current loop** is the dominant standard for analog sensor signals in industrial automation.

**Why current, not voltage?**

Ohm's Law tells us that for a series circuit, the same current flows through every element regardless of wire resistance. This means:
- A 100Ω wire resistance causes zero signal error (V drops across wire, current stays same)
- Signal integrity is maintained over **hundreds of meters** of cable

**The Live-Zero Principle**:

| Signal Level | Meaning | Significance |
|:---|:---|:---|
| **0 mA** | Broken wire / no power | **Fault condition** — detectable! |
| **4 mA** | 0% of process range (minimum) | Live zero — below-range is distinguishable from fault |
| **12 mA** | 50% of process range | Mid-scale |
| **20 mA** | 100% of process range (maximum) | Full scale |

**2-Wire Loop-Powered Transmitters**: The transmitter draws its operating power from the 4mA baseline current. This allows a single 2-wire cable to carry both power and signal.

### 1.2 0–10V Voltage Signal

| Feature | 4–20mA | 0–10V |
|:---|:---|:---|
| Long cable run noise | ✅ Immune (constant current) | ❌ Susceptible (voltage drop, EMI) |
| Wire break detection | ✅ Yes (0mA = fault) | ❌ No (0V = valid minimum) |
| Wiring simplicity | Same | Same |
| Short circuit risk | Lower | Higher |
| Typical run distance | Up to 500m+ | Up to ~100m |
| Common use | Field instruments, transmitters | Sensors near panel, short runs |

### 1.3 ADC Resolution — From Signal to Raw Count

An **Analog-to-Digital Converter (ADC)** on the input module samples the analog voltage/current and converts it to a digital integer.

| ADC Resolution | Count Range | 1 LSB (°C, 0–100°C range) |
|:---|:---|:---|
| 10-bit | 0 to 1,023 ($2^{10}-1$) | 0.0978°C/count |
| 12-bit | 0 to 4,095 ($2^{12}-1$) | 0.0244°C/count |
| 16-bit (Siemens) | 0 to 27,648 | 0.0036°C/count |

> 💡 Siemens S7 uses **27,648** (not 32,767) as its full-scale count for 4–20mA inputs.

---

## 2. Analog Scaling

### 2.1 Universal Scaling Formula

The relationship between raw counts and engineering units is **linear interpolation**:

$$\text{EU} = \left(\frac{\text{Raw} - \text{Raw}_{\min}}{\text{Raw}_{\max} - \text{Raw}_{\min}}\right) \times (\text{EU}_{\max} - \text{EU}_{\min}) + \text{EU}_{\min}$$

**Derivation**: This is the slope-intercept form of a line between two known points:
- Point A: $(\text{Raw}_{\min}, \text{EU}_{\min})$
- Point B: $(\text{Raw}_{\max}, \text{EU}_{\max})$

### 2.2 Worked Examples

**Example 1**: 10-bit ADC, Raw=512, Range: 0–100°C
$$\text{Temp} = \left(\frac{512 - 0}{1023 - 0}\right) \times 100 + 0 = 50.05°\text{C}$$

**Example 2**: Siemens 27648, Raw=13824, Range: -10 to 50 PSI
$$\text{Pressure} = \left(\frac{13824}{27648}\right) \times 60 + (-10) = 0.5 \times 60 - 10 = 20.0 \text{ PSI}$$

**Example 3**: 12-bit ADC, 4–20mA → 0–5.0 bar, Raw=2048
$$\text{Pressure} = \left(\frac{2048 - 0}{4095 - 0}\right) \times 5.0 = 2.50 \text{ bar}$$

### 2.3 Built-In Scaling Instructions

#### IEC 61131-3 Two-Step Method (`NORM_X` + `SCALE_X`)

```iecst
(* Step 1: Normalize raw INT to REAL 0.0 → 1.0 *)
Normalized := NORM_X(MIN := INT#0, VALUE := RawADC, MAX := INT#1023);

(* Step 2: Scale 0.0 → 1.0 to engineering units *)
ScaledTemp := SCALE_X(MIN := REAL#0.0, VALUE := Normalized, MAX := REAL#100.0);
```

#### Single Instruction (`SCL` — Allen-Bradley)

```iecst
ScaledTemp := SCL(
    Source   := RawADC,
    InputMin := 0,
    InputMax := 1023,
    ScaledMin := 0.0,
    ScaledMax := 100.0
);
```

#### Ladder Diagram

```
Power Rail (+)                                                              Power Rail (-)
     │                                                                           │
1    ├──────────────────────────────────────────────────────────────────────────┤
     │                          SCL                                              │
     │              Source:     RawADC    (INT)                                 │
     │              InputMin:   0                                               │
     │              InputMax:   1023                                            │
     │              ScaledMin:  0.0                                             │
     │              ScaledMax:  100.0                                           │
     │              Dest:       ScaledTemp (REAL)                               │
```

---

## 3. Arithmetic Instructions

### 3.1 Standard Math Operations

```iecst
(* Basic arithmetic *)
Sum      := Temp1 + Temp2;                    // ADD
Delta    := ScaledTemp - Setpoint;            // SUB
Scaled_F := (ScaledTemp * REAL#1.8) + 32.0;  // MUL + ADD (°C to °F)
Average  := SumTemps / SensorCount;           // DIV

(* Engineering calculation: flow from differential pressure *)
Flow_m3h := FlowCoefficient * SQRT(DiffPressure_Pa);
```

### 3.2 Division-by-Zero Guard

A division by zero causes a **major CPU fault** that can halt the entire PLC program.

```iecst
(* INCORRECT — crashes if SensorCount = 0 *)
Average := SumTemps / REAL#SensorCount;

(* CORRECT — always guard division *)
IF SensorCount > 0 THEN
    Average := SumTemps / REAL#SensorCount;
ELSE
    Average  := REAL#0.0;
    DivError := TRUE;   // set diagnostic flag
END_IF;
```

---

## 4. Data Types

### 4.1 Data Type Selection Reference

| Type | Size | Range | Industrial Use Case |
|:---|:---|:---|:---|
| **BOOL** | 1 bit | `FALSE` / `TRUE` | Digital I/O, alarm flags, mode bits |
| **BYTE** | 8 bits | 0 – 255 | Packed status bits, small data |
| **INT** | 16 bits signed | -32,768 – 32,767 | Raw ADC counts (10/12-bit), small counters |
| **DINT** | 32 bits signed | -2,147,483,648 – 2,147,483,647 | Siemens 27648 raw counts, large accumulators |
| **REAL** | 32-bit IEEE 754 | ±3.4×10³⁸ (~7 sig. figures) | Scaled temperatures, pressures, flow rates |
| **TIME** | 32-bit | T#0ms – T#49d17h | Timer presets and elapsed values |
| **STRING** | Variable | Up to 254 chars | HMI messages, alarm text |

### 4.2 IEEE 754 Floating-Point Equality Pitfall

```iecst
(* ❌ WRONG — May NEVER evaluate TRUE due to binary representation error *)
IF ScaledTemp = 50.0 THEN
    TempReached := TRUE;
END_IF;

(* ✅ CORRECT — Use greater-than-or-equal for threshold comparisons *)
IF ScaledTemp >= 50.0 THEN
    TempReached := TRUE;
END_IF;
```

**Why**: `50.0` in IEEE 754 binary floating point may actually be stored as `49.999998...` due to base-2 approximation of base-10 decimals.

### 4.3 Type Conversion

```iecst
(* INT to REAL — explicit cast required in strict IEC mode *)
AverageTemp := REAL#SensorCount;      // cast INT to REAL before arithmetic
AverageTemp := INT_TO_REAL(RawCount); // explicit conversion function
```

---

## 5. Day 3 Project - Temperature Monitoring & Event Logging System

### 5.1 System Architecture

```
4-20mA Thermocouple  →  Analog Input Module  →  Raw ADC (INT)
                                                      │
                                                   SCL Block
                                                      │
                                                 ScaledTemp (REAL, °C)
                                                      │
                                              ┌───────┴────────┐
                                              │                │
                                          GT 50.0         3-Sample
                                              │              Filter
                                         HighAlarm       FilteredTemp
                                              │
                                           R_TRIG
                                              │
                                          LogTrigger (1 scan only)
                                              │
                                       MOV Timestamp + Value
                                       to Event Log Array
```

### 5.2 Temperature Alarm with Hysteresis (Dead-Band)

Without hysteresis, an alarm at exactly 50.0°C chatter-activates and de-activates each scan as signal noise crosses the threshold. A **dead-band** prevents this:

```iecst
(* 2°C dead-band: ON at 50°C, OFF at 48°C *)
IF ScaledTemp > REAL#50.0 THEN
    HighTempAlarm := TRUE;      // alarm turns ON above 50.0°C
ELSIF ScaledTemp < REAL#48.0 THEN
    HighTempAlarm := FALSE;     // alarm turns OFF below 48.0°C
END_IF;
(* Between 48-50°C: alarm maintains its previous state — no chatter *)
```

```
Alarm state:
                   50°C ─── ON threshold ────────────────────
                                  ▲    ▲            ▲
           ┌──────────────────────┘    │            │
           │                          │            │
           │         48°C ─── OFF threshold ───────┘
           │                          │
Signal:  ──┴──────────────────────────┴──────────────────────
                                   Noise region — alarm HELD
```

### 5.3 One-Shot Event Logging

```iecst
(* Trigger log entry on alarm ONSET only — not while alarm is sustained *)
R_TRIG_Alarm(CLK := HighTempAlarm);
LogTrigger := R_TRIG_Alarm.Q;   // TRUE for exactly 1 scan

IF LogTrigger THEN
    (* Capture event data at moment of alarm *)
    AlarmLog[LogIndex].Timestamp := CurrentDT;
    AlarmLog[LogIndex].Temperature := ScaledTemp;
    AlarmLog[LogIndex].AlarmType := ALARM_HIGH_TEMP;

    (* Advance log index, wrap around at end of array *)
    LogIndex := LogIndex + 1;
    IF LogIndex >= LOG_SIZE THEN
        LogIndex := 0;  // circular buffer
    END_IF;
END_IF;
```

### 5.4 3-Sample FIFO Moving Average Filter

```iecst
(* Shift previous samples down the array *)
Samples[2] := Samples[1];
Samples[1] := Samples[0];
Samples[0] := ScaledTemp;         // latest reading at index 0

(* Compute simple moving average *)
FilteredTemp := (Samples[0] + Samples[1] + Samples[2]) / REAL#3.0;
```

**Why filter?**: A thermocouple in turbulent process flow can show ±2°C scan-to-scan noise. Feeding raw noisy signal to an alarm threshold generates false alarms. The filtered value is stable and suitable for alarm and control decisions.

### 5.5 Complete Program — Structured Text

```iecst
PROGRAM Temperature_Monitor
VAR
    (* I/O *)
    RawADC         : INT;      // from analog input module (0-1023)
    HighTempOut    : BOOL;     // output coil to lamp/HMI

    (* Processing *)
    Normalized     : REAL;
    ScaledTemp     : REAL;     // in °C
    FilteredTemp   : REAL;
    Samples        : ARRAY[0..2] OF REAL;

    (* Alarm *)
    HighTempAlarm  : BOOL;
    LogTrigger     : BOOL;
    R_TRIG_Alarm   : R_TRIG;
    LogIndex       : INT;
    AlarmLog       : ARRAY[0..99] OF ALARM_ENTRY;  // 100-entry circular log
END_VAR

(* ── 1. Scale raw ADC to engineering units ── *)
Normalized := NORM_X(MIN := INT#0, VALUE := RawADC, MAX := INT#1023);
ScaledTemp := SCALE_X(MIN := REAL#0.0, VALUE := Normalized, MAX := REAL#100.0);

(* ── 2. 3-Sample moving average filter ── *)
Samples[2]   := Samples[1];
Samples[1]   := Samples[0];
Samples[0]   := ScaledTemp;
FilteredTemp := (Samples[0] + Samples[1] + Samples[2]) / REAL#3.0;

(* ── 3. Alarm hysteresis (2°C dead-band) ── *)
IF FilteredTemp > REAL#50.0 THEN
    HighTempAlarm := TRUE;
ELSIF FilteredTemp < REAL#48.0 THEN
    HighTempAlarm := FALSE;
END_IF;

(* ── 4. One-shot event log on alarm onset ── *)
R_TRIG_Alarm(CLK := HighTempAlarm);
LogTrigger := R_TRIG_Alarm.Q;

IF LogTrigger THEN
    AlarmLog[LogIndex].Temperature := FilteredTemp;
    LogIndex := LogIndex + 1;
    IF LogIndex >= 100 THEN LogIndex := 0; END_IF;
END_IF;

(* ── 5. Drive output ── *)
HighTempOut := HighTempAlarm;

END_PROGRAM
```

---

## Day 3 Assessment Tasks

| Task | Description | Difficulty |
|:---|:---|:---|
| Task 1 | Derive scaling formula from first principles for 4-20mA → 0-100°C | ⭐⭐ Intermediate |
| Task 2 | Calculate EU for Raw=750, 0-1023 → -20 to 80°C | ⭐⭐ Intermediate |
| Task 3 | Implement NORM_X + SCALE_X in a ladder rung | ⭐⭐ Intermediate |
| Task 4 | Build arithmetic rung: convert ScaledTemp_C to Fahrenheit | ⭐⭐ Intermediate |
| Task 5 | Add division guard to average of 3 sensor values | ⭐⭐ Intermediate |
| Task 6 | Explain why EQ comparison on REAL can fail. Show example | ⭐⭐ Intermediate |
| Task 7 | Implement 3°C dead-band hysteresis alarm for process at 75°C | ⭐⭐⭐ Advanced |
| Task 8 | Build R_TRIG-triggered alarm event log with circular buffer | ⭐⭐⭐ Advanced |
| Task 9 | Implement 5-sample moving average filter as ST code | ⭐⭐⭐ Advanced |
| Task 10 | Full project: build Temperature Monitor from sensor to log | ⭐⭐⭐ Advanced |

---

## Day 3 Files

| File | Description |
|:---|:---|
| [`README.md`](README.md) | This document — Day 3 complete reference |
| [`Ladder_Diagrams.md`](Ladder_Diagrams.md) | All Day 3 ladder diagrams |
| [`Day3_Analog_and_Data_Teaching_Material.md`](Day3_Analog_and_Data_Teaching_Material.md) | Full instructor session notes |
| [`Temperature_Monitor.st`](Temperature_Monitor.st) | Temperature monitoring system ST source code |
