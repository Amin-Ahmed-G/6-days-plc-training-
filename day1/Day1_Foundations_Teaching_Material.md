# Day 1 — Foundations: Full Instructor Teaching Material (Technical Edition)

**Total session time**: 210 minutes (3.5 hrs). Each section is sized to its time budget with talking points, board work, wiring/ladder detail, and explicit framing lines.

**Addressing convention used throughout** (adjust to whatever platform the lab runs — Allen-Bradley/RSLogix, Siemens TIA/S7, or CODESYS/IEC 61131-3 generic):
- IEC generic: `%I0.0` (input bit), `%Q0.0` (output bit), `%M0.0` (internal memory bit)
- Allen-Bradley: tag-based, e.g. `Start_PB`, `Motor_Run`
- Siemens: `I0.0`, `Q0.0`, `M0.0`

---

## 1. PLC Basics — 15 min

### Definition, precisely
A PLC is a purpose-built industrial computer executing a single control program in a deterministic, cyclic loop, reading digital/analog inputs and driving digital/analog outputs each cycle. Core architecture to put on the board:

```text
[Power Supply] --24VDC--> [CPU] <-- backplane bus --> [Input Modules] <-- field wiring -- sensors/switches
                            |
                     [Output Modules] -- field wiring --> actuators/lamps/motors
```

### Why it replaced relay panels — the technical distinction, not just the analogy
- A relay panel implements Boolean logic in hardware: each relay coil, when energized, physically closes or opens a set of contacts wired to the next relay or output. Changing logic means physically re-wiring contacts across a rack that can span dozens of relays for a moderately complex machine.
- A PLC's CPU executes the equivalent Boolean logic as *stored program instructions* against an input/output image table held in RAM. The physical I/O wiring topology to field devices does not change when logic changes — only the program in memory changes, which can be edited and downloaded to the CPU in minutes.

*Analogy*: house wiring vs. software — same physical switches and lights, but behavior lives in an editable program instead of physical connections.

*Real-world use cases*: conveyor belts (start/stop, jam detection via a timed no-motion condition on a speed sensor), packaging lines (fill/seal/count cycles), elevators (floor sequencing with door interlocks — a direct preview of interlocking logic in today's end-of-day project), traffic lights (state-sequenced timing — the entire subject of Day 2's Day Project).

### Key terms, defined with precision:
- **Input**: a physical signal (digital or analog) read into the CPU's input image table each scan.
- **Output**: a physical signal written from the CPU's output image table to a physical terminal each scan.
- **Program/Logic**: the stored set of instructions (ladder, structured text, function block) solved each scan against the frozen input image.
- **Scan**: the full input-scan/logic-solve/output-update cycle (unpacked in Block 3).

*Common misconception to correct explicitly*: a PLC is not a general-purpose multitasking OS. It runs one control program in a tight, predictable, repeating loop, hardened against vibration, temperature extremes, and electrical noise (via features like galvanic isolation on I/O modules and conformal-coated boards).

---

## 2. PLC Hardware — 30 min

### 2a. CPU & Power Supply — 8 min
Power supply converts mains AC (100–240V, 50/60Hz) to **24V DC**, the near-universal standard for PLC I/O-side power. State explicitly why 24V DC specifically:
- Low enough that accidental contact is not lethal under normal conditions, a meaningful safety margin for technicians working live on a panel.
- Standardized across virtually every industrial sensor/actuator manufacturer, meaning a 24V DC proximity sensor from one vendor plugs directly into a PLC input module from a different vendor with no voltage-matching concerns.
- Low enough voltage drop tolerance issues are manageable at typical field wiring run lengths compared to lower voltages like 5V/12V, while still being safely below mains.

CPU executes the input-scan/logic-solve/output-update loop and typically has its own onboard diagnostic LEDs (`RUN` / `STOP` / `FAULT` / `FORCE`).

### 2b. Input Modules — 8 min
Digital input module electrical behavior: reads 24V DC present at a terminal as logic `1` (true), 0V (or below a defined threshold, commonly ~5V for a `0` and ~15V for a guaranteed `1`, with an undefined region between) as logic `0`. This threshold-based reading, not a clean binary switch, is why proper wiring practice matters — a marginal voltage due to a poor connection can produce unreliable/chattering logic state.

State explicitly: the module reports raw voltage-derived state — it has no knowledge of whether that terminal is wired to a Normally Open or Normally Closed field switch.

### 2c. Output Modules — 8 min
Three output types, with the electrical distinctions that actually matter on the job:

| Type | Switches | Typical Response Time | Mechanism | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Relay** | AC or DC | Slower (ms range, mechanical) | Electromechanical contact | Robust, galvanically isolates PLC from load, finite mechanical switching life ($10^5-10^6$ cycles). |
| **Transistor** | DC only | Fast ($\mu$s-ms range) | Solid-state switching | No mechanical wear, suited to high-frequency switching (e.g. PWM), cannot switch AC loads. |
| **Triac** | AC only | Fast, solid-state | Solid-state AC switching | Common for lamps/solenoids on AC circuits, no mechanical wear. |

*Practical takeaway*: if a spec sheet says "transistor output module," that module physically cannot drive an AC contactor coil — attempting to do so can damage the output stage.

### 2d. Label Exercise — 6 min
Locate and label on a panel diagram: CPU, power supply, input terminal block, output terminal block.

---

## 3. PLC Scan Cycle — 15 min

### The Core Loop
```text
1. INPUT SCAN   — read all physical input terminals, latch values into Input Image Table (IIT)
                  (inputs frozen here — no re-read until next cycle)
2. LOGIC SOLVE  — execute entire program top-to-bottom against the frozen IIT,
                  write results to Output Image Table (OIT) — NOT to physical terminals yet
3. OUTPUT UPDATE— write entire OIT to physical output terminals, all at once
                  [+ housekeeping: communications servicing, diagnostics, etc.]
--> repeat
```

*Typical scan time*: 1–10ms. Scan time varies slightly cycle to cycle depending on which logic branches execute.

*Why scan time matters*: if a physical input pulse (e.g. from a fast proximity sensor) is shorter in duration than one scan time, the PLC can miss it entirely.

---

## 4. Inputs/Outputs + NO/NC Contacts — 40 min

### 4a. Wiring a Push-Button Input — 10 min
Terminal numbering (`%I0.0`), Common vs signal wire (sourcing vs sinking PNP/NPN), I/O status view verification.

### 4b. Wiring a Lamp Output — 10 min
Confirm module type matches load (relay/transistor/triac).

### 4c. Live Status Monitoring — 10 min
Online/monitor view showing live I/O state.

### 4d. NO vs. NC in Real Circuits — 10 min
- **NO (Normally Open)**: contact open at rest; closes when actuated. Reads logic `0` until actuated, `1` while actuated.
- **NC (Normally Closed)**: contact closed at rest; opens when actuated. Reads logic `1` until actuated, `0` while actuated.

#### Why E-stops are wired NC (Fail-Safe Principle)
If an E-stop is wired NC and any of the following occurs — wire cut, connector unplugged, switch mechanism fails open — the input reads logic `0` (identical signature to button pressed). The safety logic responds exactly as if someone pressed the E-stop: the machine stops. Wiring an E-stop NO would let a real fault go undetected while the machine keeps running.

---

## 5. Ladder Logic Basics + Tag Naming — 60 min

### 5a. Rungs & Basic Instructions — 15 min
- **AND (Series Contacts)**:
  - Ladder: `|--[ ContactA ]--[ ContactB ]------------------( Coil )--|`
  - ST: `Coil := ContactA AND ContactB;`
- **OR (Parallel Contacts)**:
  - Ladder: `|--[ ContactA ]------------------------------( Coil )--|`
  - Ladder: `|--[ ContactB ]------------------------------|`
  - ST: `Coil := ContactA OR ContactB;`
- **NOT (Negated Contact)**:
  - Ladder: `|--[/ ContactA ]-----------------------------( Coil )--|`
  - ST: `Coil := NOT ContactA;`

### 5b. Guided Practice — 15 min
Build single NO $\rightarrow$ coil, two NO in series (AND), two NO in parallel (OR).

### 5c. Symbolic Addressing & Tag Naming — 15 min
Replace raw addresses (`%I0.0`, `%Q0.1`) with symbolic tags (`Start_PB`, `Motor_Run`).

### 5d. Commenting Rungs — 5 min
Record *why* the logic evaluates what it does.

### 5e. Project: Two-Button AND/OR Logic — 10 min

---

## 6. Day Project — Motor Start/Stop with Seal-In Circuit — 50 min

### Core Concept
A momentary Start button must energize an output that remains energized after release. Requires the output's own contact wired in parallel with Start (seal-in), combined with an NC Stop condition.

### Logic Pattern
```text
Ladder:
|--[ Start_PB ]----+----------------[/ Stop_PB ]------( Motor_Run )--|
|                  |
|--[ Motor_Run ]---+ (seal-in contact, in parallel with Start_PB)

ST:
Motor_Run := (Start_PB OR Motor_Run) AND NOT Stop_PB;
```

### Walkthrough & Stretch (Forward/Reverse Interlock)
```iecst
Fwd_Run := (Fwd_PB OR Fwd_Run) AND NOT Stop_PB AND NOT Rev_Run;
Rev_Run := (Rev_PB OR Rev_Run) AND NOT Stop_PB AND NOT Fwd_Run;
```
Whichever rung evaluates first on a scan energizes its output and locks out the other on the next scan.
