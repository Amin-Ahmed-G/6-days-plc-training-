# 6-Day Industrial PLC Training Program
### Programmable Logic Controller Engineering - Comprehensive Hands-On Curriculum

![PLC Training](https://img.shields.io/badge/Training-Industrial%20Automation-blue?style=for-the-badge)
![PLC Standard](https://img.shields.io/badge/Standard-IEC%2061131--3-orange?style=for-the-badge)
![Languages](https://img.shields.io/badge/Languages-Ladder%20%7C%20ST%20%7C%20FBD-green?style=for-the-badge)
![Days](https://img.shields.io/badge/Duration-6%20Days%20%7C%2042%20Hours-red?style=for-the-badge)

---

> **This repository documents a rigorous, industry-aligned 6-day PLC training program.**
> It covers PLC hardware, IEC 61131-3 programming, analog signal conditioning, state machines,
> HMI design, VFD integration, and a full capstone industrial automation project.
> The curriculum is written to the standard and depth expected of a junior-to-mid level
> Industrial Automation / Controls Engineer.

---

## Program Overview

| Item | Details |
|:---|:---|
| **Duration** | 6 Days x 7 Hours = **42 Hours** of hands-on training |
| **Target Role** | PLC Programmer / Controls Engineer / Automation Technician |
| **PLC Standard** | IEC 61131-3 (Ladder Diagram / Structured Text / Function Block Diagram) |
| **Platform** | Siemens TIA Portal / Allen-Bradley Studio 5000 / CODESYS (IEC Generic) |
| **Hardware** | Siemens S7-1200 / Allen-Bradley CompactLogix / Generic Training Trainer |
| **Key Skills** | Hardware wiring / Ladder Logic / ST Programming / Analog I/O / HMI / VFD / Fault Diagnosis |

---

## Repository Structure

```
6-days-plc-training-/
├── day1/       <- PLC Foundations: Hardware, Scan Cycle, Basic Ladder Logic
├── day2/       <- Timers (TON/TOF/RTO), Counters (CTU/CTD), Fault Diagnosis
├── day3/       <- Analog I/O, 4-20mA Scaling, Data Types, Temperature Control
├── day4/       <- Advanced Instructions: Sequencers, Math, Data Blocks, Shift Registers
├── day5/       <- HMI Design, VFD Communication, PID Control, Alarm Management
├── day6/       <- Capstone Project: Fully Automated Conveyor Sorting System
├── CONTRIBUTORS.md
├── SYLLABUS.md <- Complete 42-hour curriculum with learning outcomes
└── README.md
```

---

## Day-by-Day Syllabus

### [Day 1 - PLC Foundations & Basic Ladder Logic](day1/)
> "From relay panels to stored-program industrial computers"

- PLC hardware architecture (CPU, I/O modules, power supply, backplane)
- PLC scan cycle (Input Scan -> Logic Solve -> Output Update)
- Digital I/O wiring (sinking/sourcing, NPN/PNP, 24V DC field power)
- Fail-safe wiring design (NC E-stops, wire-break safety)
- Normally Open (NO) and Normally Closed (NC) contacts in ladder logic
- Output coils, Latch (SET) and Unlatch (RESET) instructions
- Boolean AND / OR / NOT gate implementation
- Motor Start/Stop with Seal-In circuit
- Forward/Reverse interlock with hardware and software mutual exclusion
- **Project**: Fully wired and programmed Start/Stop/Forward/Reverse motor control panel

---

### [Day 2 - Timers, Counters & Troubleshooting](day2/)
> "Time-based and count-based industrial control, plus reading a live PLC"

- TON (Timer On-Delay), TOF (Timer Off-Delay), RTO (Retentive Timer) with timing diagrams
- CTU (Count Up), CTD (Count Down), CTUD (Up-Down Counter)
- Edge detection: ONS (One-Shot), R_TRIG, F_TRIG - why they exist and scan-level proof
- Online monitoring and live rung status interpretation
- Forcing digital I/O for hardware/software fault isolation
- Fault triage methodology (CPU fault log -> module LEDs -> online logic monitoring)
- Retentive vs. non-retentive timer selection for production applications
- **Project**: 3-phase Traffic Light State Machine (INT state register + EQU comparison)

---

### [Day 3 - Analog I/O, Scaling & Data Processing](day3/)
> "Reading the physical world: temperature, pressure, level - in engineering units"

- 4-20 mA current loop signal theory and live-zero justification
- 0-10V voltage signal: noise vulnerability and distance limitations
- 10-bit, 12-bit, and Siemens 27648-count ADC raw count resolution
- Universal analog scaling formula (derived mathematically)
- Built-in scaling: NORM_X / SCALE_X / SCL instructions
- Arithmetic instructions: ADD, SUB, MUL, DIV with division-by-zero guard
- Comparison instructions: GT, LT, GE, LE, EQ and IEEE 754 REAL equality pitfall
- Data types: BOOL, INT, DINT, REAL - sizing, range, and selection rationale
- Alarm hysteresis (dead-band logic) to prevent contact chatter
- 3-sample FIFO moving average filter for noisy analog signals
- **Project**: Temperature Monitoring System with alarm logging, hysteresis and digital filter

---

### [Day 4 - Advanced Instructions: Sequencers, Math & Data Blocks](day4/)
> "Production-grade PLC code: structured, reusable, and maintainable"

- Data Block (DB) design and structured variable organization
- MOV, BLKMOV: single and block data transfer
- Array processing with FOR / WHILE loops in Structured Text
- Sequencer (SQO/SQC) for multi-step machine cycles
- Shift Register (BSL/BSR) for conveyor tracking buffers
- Math operations: ABS, SQRT, SIN, COS for engineering calculations
- Signal clamping using MIN, MAX, LIMIT instructions
- Function Block (FB) design for reusable, instance-based logic
- PLC program organization: OBs, FBs, FCs, DBs (Siemens) / Tasks and Programs (IEC)
- **Project**: 8-step Batch Process Sequencer with step timers and fault recovery logic

---

### [Day 5 - HMI, VFD Communication & PID Control](day5/)
> "Closing the loop: operator interfaces, variable speed drives, and process control"

- HMI tag binding: mapping PLC memory to HMI screen objects
- Screen design: pushbuttons, indicator lamps, numeric entry, bar graphs, trend displays
- Alarm banner design, severity classification, and acknowledgement logic
- PROFINET / EtherNet/IP communication overview for HMI-to-PLC
- Variable Frequency Drive (VFD) control via digital I/O and analog speed reference
- VFD parameter setup: accel/decel ramps, current limits, fault relay wiring
- PID control block overview: P, I, D terms, setpoint, process variable, output
- PID tuning basics: manual vs. auto-tune, common industrial tuning methods
- **Project**: Pump Speed Control System - HMI setpoint entry + VFD analog output + PID water level control

---

### [Day 6 - Capstone: Automated Conveyor Sorting System](day6/)
> "A complete industrial automation project from I/O list to commissioning"

- Full system requirements analysis and I/O list creation
- Program architecture design (modular FB-based structure)
- Optical part detection -> metal proximity discrimination -> pneumatic divert arm control
- Conveyor motor speed control via VFD analog reference from HMI
- Batch counting with reject accumulation alarm
- HMI screen design: live conveyor status, part counts, reject rates, alarm history
- E-stop safety interlock architecture (hardwired + PLC software interlock)
- Production test and commissioning procedure
- **Project**: Full working Conveyor Belt Sorting System - programmed, documented, tested

---

## Contributors

| Contributor | GitHub Profile | Role |
|:---|:---|:---|
| **A.M Jafrein** | [@Jafrein](https://github.com/Jafrein) | PLC Engineer & Trainer |
| **M Vaishnavi** | [@robo-maker-glitch](https://github.com/robo-maker-glitch) | PLC Engineer & Trainer |
| **Amin Ahmed G** | [@Amin-Ahmed-G](https://github.com/Amin-Ahmed-G) | PLC Engineer & Trainer |

---

## Competencies Demonstrated

Upon completion of this training program, participants demonstrate competency in:

| Competency Area | Specific Skills |
|:---|:---|
| **PLC Hardware** | Module selection, I/O wiring, 24V DC field power, output type selection (relay/transistor/triac) |
| **Ladder Logic** | Contacts, coils, seal-in, interlocks, timer/counter rungs, comparison rungs |
| **Structured Text** | IEC 61131-3 ST syntax, loops, conditionals, function blocks, data types |
| **Analog Signals** | 4-20mA, 0-10V, ADC scaling, NORM_X/SCALE_X, hysteresis, digital filtering |
| **Fault Diagnosis** | PLC fault logs, module LED triage, forced I/O testing, online monitoring |
| **HMI Design** | Tag binding, screen layout, alarm management, trend displays |
| **VFD Control** | Digital/analog VFD interface, parameter configuration, accel/decel tuning |
| **PID Control** | Control loop architecture, P/I/D term effects, basic tuning methodology |
| **Safety Design** | Fail-safe NC wiring, E-stop architecture, interlock design principles |
| **Project Delivery** | I/O list -> program design -> commissioning -> documentation |

---

## Course Resources & Presentations

| File | Description |
|:---|:---|
| [`Presentation.pptx`](Presentation.pptx) | Master Course PowerPoint Presentation |
| [`PLC_Syllabus.pdf`](PLC_Syllabus.pdf) | Official PLC Training Syllabus PDF |
| [`PLC_Trainer_Guide.pdf`](PLC_Trainer_Guide.pdf) | Complete PLC Trainer Guide PDF |
| [`SYLLABUS.md`](SYLLABUS.md) | Detailed 42-hour curriculum markdown document |
| [`CONTRIBUTORS.md`](CONTRIBUTORS.md) | Program authors and contributor roles |

---

## Reference Standards

- **IEC 61131-3**: International Standard for PLC programming languages
- **IEC 61508 / IEC 62061**: Functional Safety of E/E/PE Safety-related Systems
- **NFPA 79**: Electrical Standard for Industrial Machinery (US)
- **ISO 13849**: Safety of machinery - Safety-related parts of control systems

---

## License

This repository is maintained for educational and professional development purposes.
All code examples are written to IEC 61131-3 standard and may be adapted for any compliant PLC platform.
