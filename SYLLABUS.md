# Complete Training Syllabus - 6-Day Industrial PLC Engineering Program

**Program Title**: Programmable Logic Controller (PLC) Engineering - Industrial Automation Fundamentals to Capstone
**Total Duration**: 42 Hours (6 Days x 7 Hours)
**Standard**: IEC 61131-3 | Industry Platforms: Siemens TIA Portal, Allen-Bradley Studio 5000, CODESYS

---

## Program Learning Outcomes

Upon successful completion of this program, participants will be able to:

1. **Explain** PLC hardware architecture, scan cycle mechanics, and I/O module selection criteria
2. **Design and implement** ladder logic programs for industrial motor control, safety interlocks, and sequencing
3. **Program and configure** TON/TOF/RTO timers and CTU/CTD counters for time-based and count-based automation
4. **Diagnose and resolve** PLC faults using a systematic triage methodology (CPU -> module -> logic)
5. **Scale analog signals** (4-20mA / 0-10V) from raw ADC counts to engineering units using industry-standard formulas and built-in instructions
6. **Design advanced PLC programs** using sequencers, data blocks, shift registers, and reusable function blocks
7. **Integrate an HMI** with PLC tag binding, alarm management, and trend display configuration
8. **Configure and control a Variable Frequency Drive (VFD)** via digital I/O and analog speed reference
9. **Implement a PID control loop** for closed-loop process variable regulation
10. **Deliver a complete automation project**: from I/O list through commissioning and documentation

---

## [Day 1 - PLC Foundations & Basic Ladder Logic](day1/README.md)
**Duration**: 7 Hours | **Format**: 60% Lecture/Demo + 40% Hands-On Lab

### Session 1: Introduction to PLCs (1.5 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| History: relay panels to PLCs | Conceptual | 10 min |
| PLC hardware architecture | Technical detail | 20 min |
| Power supply: AC mains to 24V DC | Theory + wiring | 15 min |
| CPU: memory, I/O image table, processor | Technical | 15 min |
| Backplane & module communication | Overview | 10 min |

**Learning Outcome**: Student can label and explain every major hardware component in a PLC panel.

### Session 2: Digital I/O Modules & Field Wiring (1.5 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| Digital input module voltage thresholds | Technical detail | 20 min |
| Sinking (NPN) vs sourcing (PNP) wiring | Wiring diagram + lab | 30 min |
| Output module types: Relay, Transistor, Triac | Comparison table | 20 min |
| Output module selection by application | Decision matrix | 20 min |

**Learning Outcome**: Student can select correct output module type and wire a 24V DC digital I/O circuit.

### Session 3: PLC Scan Cycle (1 hr)
| Topic | Depth | Time |
|:---|:---|:---|
| 3-phase scan cycle: Input Scan -> Logic Solve -> Output Update | Technical walk-through | 25 min |
| I/O Image Table mechanics | Deep dive | 20 min |
| Scan time implications: missed pulses | Practical diagnosis | 15 min |

**Learning Outcome**: Student can predict PLC output behavior given a specific scan-cycle timing scenario.

### Session 4: Ladder Logic Basics (2 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| Ladder diagram anatomy: power rails, rungs, contacts, coils | Introduction | 20 min |
| NO and NC contacts: logical vs physical | Critical distinction | 20 min |
| Boolean AND (series), OR (parallel), NOT (negated contact) | Theory + lab build | 30 min |
| Output coils, SET/RESET (Latch/Unlatch) | Lab | 20 min |
| Symbolic tag naming vs raw address | Best practice | 10 min |
| Rung commenting standards | Best practice | 10 min |

**Learning Outcome**: Student can write and interpret ladder logic rungs for AND, OR, NOT, SET, and RESET operations.

### Session 5: Fail-Safe Wiring Design (30 min)
| Topic | Depth | Time |
|:---|:---|:---|
| NO vs NC: physical wiring implications | Safety-critical | 15 min |
| Fail-safe NC E-stop principle | Safety-critical | 15 min |

**Learning Outcome**: Student can explain and demonstrate why E-stops must be wired NC.

### Day 1 Project Lab (30 min)
- Project A: Two-button AND/OR logic - build, test, document
- Project B: Motor Start/Stop with Seal-In circuit
- Project C (Stretch): Forward/Reverse motor control with hardware + software mutual-exclusion interlock

---

## [Day 2 - Timers, Counters & Fault Diagnosis](day2/README.md)
**Duration**: 7 Hours | **Format**: 50% Lecture/Demo + 50% Hands-On Lab

### Session 1: TON and TOF Timers (2 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| TON function block signature and parameters | Technical | 20 min |
| TON internal state machine (pseudo-code walkthrough) | Deep dive | 20 min |
| TON timing diagrams: full-duration, early-release | Diagram analysis | 20 min |
| TOF function block and timing diagram | Technical | 20 min |
| TON vs TOF: direction of delay confusion | Error prevention | 20 min |
| Lab: Build TON motor delay + TOF fan run-on circuits | Hands-on | 20 min |

**Learning Outcome**: Student can correctly configure and explain TON and TOF timer behavior from timing diagrams.

### Session 2: RTO Retentive Timer (45 min)
| Topic | Depth | Time |
|:---|:---|:---|
| Why RTO is needed: cumulative run-time tracking | Motivation | 15 min |
| RTO vs TON: retained ET vs snap-reset | Comparison | 15 min |
| Explicit RES instruction requirement | Critical detail | 15 min |

**Learning Outcome**: Student can select between TON, TOF, and RTO for a given industrial application.

### Session 3: CTU and CTD Counters (1.5 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| CTU function block and rising-edge sensitivity | Technical | 20 min |
| CTD function block and LOAD vs RESET asymmetry | Technical | 20 min |
| Edge detection: ONS, R_TRIG, F_TRIG - scan-level proof | Deep dive | 30 min |
| Lab: Edge-triggered part counter with batch-complete output | Hands-on | 20 min |

**Learning Outcome**: Student can implement edge-triggered counting and explain why ONS is critical.

### Session 4: Online Monitoring & Fault Diagnosis (2 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| Going online: connecting and monitoring live PLC | Practical | 20 min |
| Interpreting live rung status and tag values | Practical | 20 min |
| Forcing digital I/O: mechanism and safety warning | Technical + Safety | 30 min |
| CPU fault logs: reading and interpreting | Practical | 20 min |
| Module-level diagnostic LEDs | Practical | 20 min |
| Systematic fault triage order | Methodology | 10 min |

**Learning Outcome**: Student can diagnose a seeded hardware/software fault using a systematic methodology.

### Day 2 Project Lab (1 hr)
- Project: 3-Phase Traffic Light State Machine
- INT state register approach with EQU comparison and TON timing
- Stretch: Pedestrian interrupt priority logic

---

## [Day 3 - Analog I/O, Scaling & Data Processing](day3/README.md)
**Duration**: 7 Hours | **Format**: 45% Lecture/Demo + 55% Hands-On Lab

### Session 1: Analog Signals - Theory (1.5 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| 4-20mA current loop: physics, live-zero, 2-wire loop-powered | Deep dive | 30 min |
| 0-10V voltage signal: noise, voltage drop limitations | Comparison | 20 min |
| ADC resolution: 10-bit, 12-bit, Siemens 27648 | Mathematical | 20 min |
| Universal scaling formula (derived from linear interpolation) | Mathematical proof | 20 min |

**Learning Outcome**: Student can derive and apply the scaling formula for any ADC range and engineering unit span.

### Session 2: Scaling Instructions & Arithmetic (2 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| NORM_X + SCALE_X (IEC two-step method) | Technical lab | 30 min |
| SCL/SCALE single-instruction method | Technical lab | 20 min |
| ADD, SUB, MUL, DIV instructions | Lab | 20 min |
| Division-by-zero guard design | Safety pattern | 20 min |
| Worked examples with real sensor datasheets | Applied | 20 min |

**Learning Outcome**: Student can implement an end-to-end analog signal chain from raw ADC to engineering units.

### Session 3: Comparison Instructions & Data Types (1.5 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| GT, LT, GE, LE, EQ, NE comparison instructions | Technical lab | 30 min |
| IEEE 754 REAL equality pitfall (floating point representation) | Deep dive | 20 min |
| BOOL, INT, DINT, REAL, TIME: sizing and selection | Table + examples | 30 min |
| Implicit vs explicit type conversion | Critical detail | 10 min |

**Learning Outcome**: Student can select correct data types and implement safe comparison logic.

### Session 4: Advanced Signal Conditioning (1 hr)
| Topic | Depth | Time |
|:---|:---|:---|
| Alarm hysteresis (dead-band): why chatter occurs, fix | Pattern | 20 min |
| 3-sample FIFO moving average filter: array + shift | Algorithm | 25 min |
| Clamp/limit output: MIN/MAX/LIMIT instructions | Pattern | 15 min |

**Learning Outcome**: Student can implement production-quality alarm hysteresis and digital signal filtering.

### Day 3 Project Lab (1 hr)
- Project: Temperature Monitoring & Event Logging System
- 4-20mA thermocouple input scaling, high-temp alarm with 2C dead-band hysteresis
- One-shot event log trigger on alarm onset, 3-sample moving average filter

---

## [Day 4 - Advanced Instructions: Sequencers, Data Blocks & Reusable Code](day4/README.md)
**Duration**: 7 Hours | **Format**: 40% Lecture/Demo + 60% Hands-On Lab

### Session 1: Data Blocks & Structured Variables (1.5 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| Data Block (DB) purpose and design | Technical | 20 min |
| Structured variable declaration (STRUCT) | Technical lab | 25 min |
| MOV, BLKMOV: single and block data transfer | Lab | 20 min |
| Array declaration and indexed access | Technical lab | 25 min |

### Session 2: FOR/WHILE Loops in Structured Text (1 hr)
| Topic | Depth | Time |
|:---|:---|:---|
| FOR loop: syntax, bounds, iterator | Technical lab | 25 min |
| WHILE loop: condition-based iteration | Technical lab | 20 min |
| Batch array processing: scale all sensors in one loop | Applied | 15 min |

### Session 3: Sequencers & Shift Registers (1.5 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| Step-based sequencer design using INT state + CASE | Technical | 30 min |
| SQO/SQC sequencer instructions (Allen-Bradley) | Platform-specific | 20 min |
| Shift Register (BSL/BSR): conveyor part-tracking buffer | Pattern | 25 min |

### Session 4: Reusable Function Blocks (1.5 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| Function (FC) vs Function Block (FB) distinction | Technical | 20 min |
| FB design: instance data, VAR_INPUT, VAR_OUTPUT | Technical lab | 30 min |
| Creating a reusable Motor Control FB | Applied lab | 30 min |
| Calling multiple FB instances for multi-motor panel | Applied lab | 20 min |

### Day 4 Project Lab (1 hr)
- Project: 8-Step Batch Process Sequencer with per-step timers, fault detection, and recovery logic

---

## [Day 5 - HMI Design, VFD Integration & PID Control](day5/README.md)
**Duration**: 7 Hours | **Format**: 40% Lecture/Demo + 60% Hands-On Lab

### Session 1: HMI Design Fundamentals (2 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| HMI hardware overview: panels, runtime software | Overview | 15 min |
| Communication: PROFINET/EtherNet/IP overview | Technical | 20 min |
| Tag binding: mapping PLC memory to HMI objects | Technical lab | 30 min |
| Screen objects: pushbuttons, lamps, numeric I/O, bar graphs | Lab | 30 min |
| Trend display configuration | Lab | 25 min |

### Session 2: Alarm Management (1 hr)
| Topic | Depth | Time |
|:---|:---|:---|
| Alarm architecture: discrete vs analog alarms | Technical | 20 min |
| Severity classification: Warning / Fault / Critical | Design | 15 min |
| Acknowledgement logic and alarm history | Technical lab | 25 min |

### Session 3: Variable Frequency Drive (VFD) Integration (2 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| VFD operating principle: V/Hz and vector control | Technical theory | 25 min |
| Digital I/O control: Run/Stop/Fault relay wiring | Lab | 20 min |
| Analog speed reference: 0-10V or 4-20mA output | Lab | 20 min |
| VFD parameter setup: accel/decel ramps, current limits | Lab | 25 min |
| Reading VFD fault codes and fault relay wiring | Practical | 15 min |
| Fieldbus VFD control overview | Overview | 15 min |

### Session 4: PID Control (2 hrs)
| Topic | Depth | Time |
|:---|:---|:---|
| Closed-loop control: setpoint, PV, error, output | Theory | 20 min |
| P term: proportional band, offset (droop) | Technical | 20 min |
| I term: integral windup and anti-windup | Technical | 20 min |
| D term: derivative kick and filtering | Technical | 15 min |
| PLC PID instruction configuration | Lab | 25 min |
| Manual vs auto-tune tuning methods | Practical | 20 min |

### Day 5 Project Lab
- Project: Pump Speed Control System
- HMI level setpoint, PLC PID block, VFD analog reference, high/low level alarms

---

## [Day 6 - Capstone Project: Automated Conveyor Sorting System](day6/README.md)
**Duration**: 7 Hours | **Format**: 20% Design + 80% Build/Test/Document

### Phase 1: System Design (1 hr)
- Requirements analysis, I/O list creation, program architecture design, HMI screen layout

### Phase 2: Programming & Wiring (3 hrs)
- Optical sensor part detection, metal proximity discrimination, pneumatic divert arm
- Conveyor motor VFD speed control, batch counter, E-stop safety interlock

### Phase 3: HMI Build (1 hr)
- Main operator screen, alarm screen, alarm history trending

### Phase 4: Test & Commission (1.5 hrs)
- I/O point-to-point verification, logic dry-run with forced I/O, live run with physical parts, E-stop wire-pull test

### Phase 5: Documentation & Presentation (30 min)
- Program printout, I/O list as-built notes, lessons learned and Q&A

---

## Tools & Software Used

| Tool | Purpose |
|:---|:---|
| Siemens TIA Portal v17+ | PLC/HMI programming environment |
| Allen-Bradley Studio 5000 | Alternative PLC programming environment |
| CODESYS v3.5 | IEC 61131-3 generic platform |
| WinCC / Comfort Panel Runtime | HMI runtime |
| Excel / LibreOffice Calc | I/O list and documentation |

---

## Assessment Criteria

| Assessment | Weight | Description |
|:---|:---|:---|
| Daily Lab Completion | 40% | Functional build and test of each day's project |
| Fault Diagnosis Exercise | 20% | Timed diagnosis of seeded hardware/software faults |
| Capstone Project | 30% | Fully functional system with documentation |
| Technical Presentation | 10% | Clear verbal explanation of design decisions |

---

## Recommended Pre-Reading

1. IEC 61131-3 standard overview (free summary available at PLCopen.org)
2. Siemens S7-1200 System Manual - Chapter 2 (Hardware) and Chapter 3 (Programming)
3. 4-20mA Fundamentals - Analog signal theory primer
4. Ladder Logic Basics - Any introductory tutorial (AutomationDirect or RealPars)
