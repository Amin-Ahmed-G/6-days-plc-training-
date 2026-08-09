# Day 3 — Analog & Data: Full Instructor Teaching Material (Technical Edition)

**Total session time**: 210 minutes (3.5 hrs).

---

## 1. Analog Inputs/Outputs — 40 min

### 1a. How Analog Signals Work — 8 min
- **4–20mA current loop**: Current source. Signal does not degrade over long distance runs (tens to hundreds of meters) because the same current flows through every device in the series circuit regardless of wire resistance.
- **0–10V voltage signal**: Voltage source. Degrades over long cable runs due to $V = IR$ line loss and is susceptible to noise from VFDs/motors.
- **Why 4–20mA (Live-Zero Justification)**: `0mA` represents a broken wire/fault. `4mA` represents $0\%$ scale minimum. Transmitters also draw operating power from the $4\text{mA}$ baseline.

### 1b. Raw ADC Counts vs. Engineering Units — 8 min
- 10-bit ADC: $0–1023$ counts ($2^{10}-1$). Resolution = $100^\circ\text{C} / 1023 \approx 0.0978^\circ\text{C}/\text{count}$.
- 12-bit ADC: $0–4095$ counts ($2^{12}-1$).
- Siemens S7: $0–27648$ counts.

```text
Physical signal (4-20mA) --> ADC --> Raw count (0-1023, INT) --> Scaling --> Engineering value (REAL, °C)
```

### 1c. Scaling Formula Walkthrough — 12 min
$$\text{EU} = \left(\frac{\text{Raw} - \text{RawMin}}{\text{RawMax} - \text{RawMin}}\right) \times (\text{EUMax} - \text{EUMin}) + \text{EUMin}$$

- *Worked Example 1* ($\text{Raw} = 512, 0-1023 \rightarrow 0-100^\circ\text{C}$):
  $$\text{EU} = \left(\frac{512 - 0}{1023 - 0}\right) \times (100 - 0) + 0 = 50.0489^\circ\text{C}$$

- *Worked Example 2* ($\text{Raw} = 13824, 0-27648 \rightarrow -10 \text{ to } 50 \text{ PSI}$):
  $$\text{EU} = \left(\frac{13824 - 0}{27648 - 0}\right) \times (50 - (-10)) + (-10) = 0.5 \times 60 - 10 = 20 \text{ PSI}$$

- *Built-in IEC Instructions*:
  ```iecst
  normalized := NORM_X(MIN := 0, VALUE := RawValue, MAX := 1023);
  ScaledTemp := SCALE_X(MIN := 0.0, VALUE := normalized, MAX := 100.0);
  ```

---

## 2. Arithmetic Instructions — 20 min

### 2a. ADD/SUB, MUL/DIV — 14 min
```iecst
Sum := ScaledTemp1 + ScaledTemp2;
Deviation := ScaledTemp - Setpoint;
Scaled_F := (ScaledTemp * 1.8) + 32.0; // °C to °F conversion
Average := Sum / Count;
```

#### Division-by-Zero Guard
```iecst
IF Count > 0 THEN
    Average := Sum / REAL#Count;
ELSE
    Average := 0.0; // Prevents major CPU fault
END_IF;
```

---

## 3. Comparison Instructions — 20 min

### 3a. GT/LT/EQ Concept — 8 min
```iecst
HighAlarm := ScaledTemp > 50.0; // GT
LowAlarm := ScaledTemp < 10.0; // LT
```

---

## 4. Data Types — 20 min

### 4a. BOOL vs. INT vs. REAL Table — 10 min

| Type | Size | Range | Typical Use |
| :--- | :--- | :--- | :--- |
| **BOOL** | 1 bit | `0` or `1` | Digital I/O, logic states, alarm flags |
| **INT** | 16-bit signed | $-32,768 \text{ to } 32,767$ | Raw ADC counts (10/12-bit), small counters |
| **DINT** | 32-bit signed | $-2,147,483,648 \text{ to } 2,147,483,647$ | Large counters, Siemens raw ranges ($0-27648$) |
| **REAL** | 32-bit IEEE 754 | $\approx \pm 3.4 \times 10^{38}$ (~7 sig digits) | Scaled engineering values ($^\circ\text{C}$, PSI) |

> ⚠️ IEEE 754 floating point representation rounding error means exact equality `EQ` (`=`) can fail for REAL numbers ($49.999998 \neq 50.0$). Use `GT`/`GE` or `LT`/`LE`.

---

## 5. Day Project — Temperature Monitoring System — 110 min

$$\text{RawADC (INT)} \xrightarrow{\text{SCL}} \text{ScaledTemp (REAL)} \xrightarrow{\text{GT 50.0}} \text{HighTempAlarm (BOOL)} \xrightarrow{\text{ONS/R\_TRIG}} \text{LogTrigger (BOOL)}$$

```iecst
// Alarm Comparison
|--[ ScaledTemp GT 50.0 ]----------------------------( HighTempAlarm )--|

// Event Logging Trigger (One-Shot)
|--[ HighTempAlarm ]--[ ONS ]------------------------( LogTrigger )--|
|--[ LogTrigger ]------------------------------------[ MOV CurrentTime, AlarmLogTimestamp ]--|
                                                     [ MOV ScaledTemp, AlarmLogValue     ]--|
```

### Alarm Hysteresis (2°C Dead-Band):
```iecst
IF ScaledTemp > 50.0 THEN
    HighTempAlarm := TRUE;  // ON above 50.0°C
ELSIF ScaledTemp < 48.0 THEN
    HighTempAlarm := FALSE; // OFF below 48.0°C
END_IF;
```

### 3-Sample FIFO Moving Average Filter:
```iecst
Samples[2] := Samples[1];
Samples[1] := Samples[0];
Samples[0] := ScaledTemp;
FilteredTemp := (Samples[0] + Samples[1] + Samples[2]) / 3.0;
```
