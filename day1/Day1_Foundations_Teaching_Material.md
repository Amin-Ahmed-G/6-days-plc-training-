# Day 1 — Foundations: Full Instructor Teaching Material (Technical Edition)

**Total session time**: 210 minutes (3.5 hrs).

---

## 1. PLC Basics — 15 min

### Definition, precisely
A PLC is a purpose-built industrial computer executing a single control program in a deterministic, cyclic loop, reading digital/analog inputs and driving digital/analog outputs each cycle. Core architecture:

```text
[Power Supply] --24VDC--> [CPU] <-- backplane bus --> [Input Modules] <-- field wiring -- sensors/switches
                            |
                     [Output Modules] -- field wiring --> actuators/lamps/motors
```

### Why it replaced relay panels
- **Relay Panel**: Implements Boolean logic in hardware. Changing logic requires physical re-wiring across the panel.
- **PLC**: CPU solves logic as *stored program instructions* in RAM against an input/output image table. Physical wiring topology remains unchanged.

---

## 2. PLC Hardware — 30 min

### 2a. CPU & Power Supply — 8 min
- Converts mains AC (100–240V, 50/60Hz) to **24V DC**.
- **24V DC Reasons**: Non-lethal voltage, industry-wide sensor/actuator standard, manageable voltage drop across field wiring runs.

### 2b. Input Modules — 8 min
- Reads 24V DC threshold: ~15V–24V for logic `1` (true), ~0V–5V for logic `0` (false).
- Module reports raw voltage state — does not know if field device is NO or NC.

### 2c. Output Modules — 8 min
| Type | Switches | Response Time | Mechanism | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Relay** | AC or DC | Slower (ms range) | Electromechanical contact | Galvanically isolates PLC from load. Limited cycle life ($10^5-10^6$). |
| **Transistor** | DC only | Fast ($\mu$s-ms) | Solid-state | No mechanical wear. Suited to PWM/high-speed DC loads. Cannot switch AC. |
| **Triac** | AC only | Fast, solid-state | Solid-state AC | Common for AC lamps and AC solenoids. Zero mechanical wear. |

---

## 3. PLC Scan Cycle — 15 min

### The Core Loop
1. **INPUT SCAN**: Read all physical input terminals, latch values into Input Image Table (IIT).
2. **LOGIC SOLVE**: Execute entire program top-to-bottom against frozen IIT, write results to Output Image Table (OIT).
3. **OUTPUT UPDATE**: Write entire OIT out to physical terminals simultaneously.

*Scan Time*: Commonly 1–10ms. Pulses shorter than scan time can be missed entirely if they occur between input scans.

---

## 4. Inputs/Outputs + NO/NC Contacts — 40 min

### Fail-Safe E-Stop Principle
- **NC Wiring**: Wire cut or unplugged reads logic `0` (same as pressed) $\rightarrow$ Machine stops safely.
- **NO Wiring**: Wire cut reads logic `0` (same as unpressed) $\rightarrow$ Machine keeps running during a real fault (Unsafe!).

---

## 5. Ladder Logic Basics + Tag Naming — 60 min

- **AND (Series)**: Both contacts must be closed for power flow.
- **OR (Parallel)**: Either contact branch energizes the coil.
- **NOT (Negated Contact)**: Uses NC-style contact symbol for negation.
- **Symbolic Tag Naming**: Replace raw addresses (`%I0.0`, `%Q0.0`) with meaningful names (`Start_PB`, `Motor_Run`).
