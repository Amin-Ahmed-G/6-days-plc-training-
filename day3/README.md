# Day 3 — Analog & Data Processing

## 📖 Concept Summary & Technical Guide

### 1. Analog Inputs/Outputs & Signal Types
- **4–20mA Current Loop**: Industry standard for long distance runs (tens to hundreds of meters). Current is constant throughout the series loop regardless of wire resistance.
  - **Live-Zero Justification**: A reading of `0mA` indicates a broken wire or power loss (fault condition). `4mA` represents the true minimum process variable value ($0\%$).
  - **2-Wire Loop Powering**: Transmitters draw operating power directly from the $4\text{mA}$ baseline current.
- **0–10V Voltage Signal**: Simpler to wire, but susceptible to line voltage drop ($V = IR$) and electrical noise from VFDs/motors over long wire runs.

---

### 2. Raw ADC Counts vs. Engineering Units
- **10-Bit ADC**: Resolution $2^{10} - 1 = 0 \text{ to } 1023$ counts.
- **12-Bit ADC**: Resolution $2^{12} - 1 = 0 \text{ to } 4095$ counts.
- **Siemens S7 Analog Range**: Normalized $0 \text{ to } 27648$ raw counts.

#### Universal Scaling Formula
$$\text{EU} = \left(\frac{\text{Raw} - \text{RawMin}}{\text{RawMax} - \text{RawMin}}\right) \times (\text{EUMax} - \text{EUMin}) + \text{EUMin}$$

#### Worked Example ($0–1023$ Raw $\rightarrow 0–100^\circ\text{C}$, Raw = 512):
$$\text{EU} = \left(\frac{512 - 0}{1023 - 0}\right) \times (100 - 0) + 0 = 50.0489^\circ\text{C}$$

---

### 3. Built-In Scaling Instructions

#### IEC Two-Step Scaling (`NORM_X` + `SCALE_X`):
```iecst
normalized := NORM_X(MIN := 0, VALUE := RawValue, MAX := 1023); // Output REAL 0.0 - 1.0
ScaledTemp := SCALE_X(MIN := 0.0, VALUE := normalized, MAX := 100.0); // Output REAL Engineering Units
```

#### Single-Instruction Scaling (`SCL` / `SCALE_X`):
```iecst
SCL(Source := RawADC, InputMin := 0, InputMax := 1023, ScaledMin := 0.0, ScaledMax := 100.0, Dest := ScaledTemp);
```

---

### 4. Arithmetic Instructions & Division-by-Zero Guards
- **ST Arithmetic Syntax**:
  ```iecst
  Sum := ScaledTemp1 + ScaledTemp2;
  Deviation := ScaledTemp - Setpoint;
  Scaled_F := (ScaledTemp * 1.8) + 32.0; // °C to °F conversion
  ```
- ⚠️ **Division-by-Zero Guard**:
  ```iecst
  IF SensorCount > 0 THEN
      Average := Sum / REAL#SensorCount;
  ELSE
      Average := 0.0; // Guard prevents major CPU runtime fault
  END_IF;
  ```

---

### 5. Data Types Reference Table

| Type | Bit Size | Range | Typical Industrial Use Case |
| :--- | :--- | :--- | :--- |
| **BOOL** | 1 bit | `0` or `1` | Digital I/O, alarms, logic states |
| **INT** | 16 bits signed | $-32,768 \text{ to } 32,767$ | Raw ADC counts (10/12-bit), small counters |
| **DINT** | 32 bits signed | $-2,147,483,648 \text{ to } 2,147,483,647$ | Siemens raw counts, high-capacity accumulators |
| **REAL** | 32 bits IEEE 754 | $\approx \pm 3.4 \times 10^{38}$ (~7 sig digits) | Scaled engineering values ($^\circ\text{C}$, PSI, GPM) |

> ⚠️ **Floating Point Equality Bug (`EQ`)**: Never use exact equality (`=`) on `REAL` numbers due to IEEE 754 binary representation rounding ($49.999998 \neq 50.0$). Always use $\ge$ (`GE`) or $\le$ (`LE`).

---

## 🌡️ Day 3 Project — Temperature Monitoring & Event Logging System

### Architecture Pipeline
$$\text{RawADC (INT)} \xrightarrow{\text{SCL}} \text{ScaledTemp (REAL)} \xrightarrow{> 50.0^\circ\text{C}} \text{HighTempAlarm (BOOL)} \xrightarrow{\text{ONS / R\_TRIG}} \text{LogTrigger (BOOL)}$$

### Ladder / ST Implementation

```iecst
// Rung 1: Scale raw input to temperature in °C
ScaledTemp := SCALE_X(MIN := 0.0, VALUE := NORM_X(MIN := 0, VALUE := RawADC, MAX := 1023), MAX := 100.0);

// Rung 2: High Temperature Alarm Comparison
|--[ ScaledTemp GT 50.0 ]------------------------------( HighTempAlarm )--|

// Rung 3: One-shot event log trigger on alarm activation
|--[ HighTempAlarm ]--[ ONS ]--------------------------( LogTrigger )--|

// Rung 4: Capture timestamp and temperature on first transition
|--[ LogTrigger ]--------------------------------------[ MOV CurrentTime -> AlarmLogTimestamp ]--|
                                                       [ MOV ScaledTemp -> AlarmLogValue ]--|
```

---

### 🔬 Advanced Concepts: Hysteresis & Moving Average Filter

#### 1. Alarm Hysteresis (Prevent Signal Chatter)
```iecst
IF ScaledTemp > 50.0 THEN
    HighTempAlarm := TRUE;  // Turns ON above 50.0°C
ELSIF ScaledTemp < 48.0 THEN
    HighTempAlarm := FALSE; // Turns OFF below 48.0°C (2°C Dead-Band)
END_IF;
```

#### 2. 3-Sample FIFO Moving Average Filter
```iecst
// Shift array elements (oldest sample dropped)
Samples[2] := Samples[1];
Samples[1] := Samples[0];
Samples[0] := ScaledTemp;

// Compute filtered average
FilteredTemp := (Samples[0] + Samples[1] + Samples[2]) / 3.0;
```
