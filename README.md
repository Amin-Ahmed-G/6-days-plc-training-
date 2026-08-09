# ⚡ 6 Days PLC Training

Welcome to the official repository for the **6 Days PLC (Programmable Logic Controller) Industrial Automation Training**! This repository serves as a complete reference containing concept summaries, instructor teaching guides, ladder/ST code examples, project tasks, and solutions.

---

## 📁 Repository Structure

```text
6-days-plc-training-/
├── day1/           # Day 1: Foundations (PLC Hardware, Scan Cycle, NO/NC, Seal-In, Interlocks)
├── day2/           # Day 2: Timers, Counters, Edge Detection, Troubleshooting & Traffic Light State Machine
├── day3/           # Day 3: Analog & Data (4-20mA, ADC Scaling, Data Types, Temperature Event Logging)
├── day4/           # Day 4: Advanced Data Handling & Math Operations
├── day5/           # Day 5: HMI Integration & Sensor / Actuator Interfaces
├── day6/           # Day 6: Capstone Automation Project & Case Studies
├── CONTRIBUTORS.md # Project Contributors List
└── README.md       # Main Documentation
```

---

## 👥 Contributors

We acknowledge and celebrate the contributions of our team members:

| Contributor | GitHub Profile | Role |
| :--- | :--- | :--- |
| **A.M Jafrein** | [@Jafrein](https://github.com/Jafrein) | Co-Author & Contributor |
| **M Vaishnavi** | [@robo-maker-glitch](https://github.com/robo-maker-glitch) | Co-Author & Contributor |
| **Amin Ahmed G** | [@Amin-Ahmed-G](https://github.com/Amin-Ahmed-G) | Maintainer & Lead Contributor |

---

## 📅 Course Syllabus & Modules

### 📘 [Day 1 — PLC Foundations](day1/)
- **Concepts**: PLC Architecture, Power Supply (24V DC), Relay vs Transistor vs Triac output selection, PLC Scan Cycle (Input Scan $\rightarrow$ Logic Solve $\rightarrow$ Output Update), NO/NC Contacts, Fail-Safe E-Stop wiring.
- **Projects**: Two-button AND/OR logic, Motor Start/Stop with Seal-In Circuit, Forward/Reverse Interlock.

### 📙 [Day 2 — Timers, Counters & Troubleshooting](day2/)
- **Concepts**: Timers (TON, TOF, RTO), Counters (CTU, CTD, CTUD), Edge Detection (ONS / R_TRIG / F_TRIG), Online Monitoring, Forcing I/O, Fault Triage Order.
- **Projects**: Debounce Counter, 17 Student Tasks & Instructor Solutions, 3-Phase Traffic Light State Machine (INT State + EQU vs BOOL Bits).

### 📗 [Day 3 — Analog & Data Processing](day3/)
- **Concepts**: 4–20mA (Live Zero) vs 0–10V, 10-bit / 12-bit ADC raw counts, Universal Scaling Formula, `NORM_X` / `SCALE_X` / `SCL`, Divide-by-zero guards, Data Types (`BOOL`, `INT`, `DINT`, `REAL`, `ARRAY`), IEEE 754 floating-point `EQ` bugs.
- **Projects**: Temperature Monitoring System, One-shot Alarm Event Logging, 2°C Dead-Band Hysteresis, 3-Sample Moving Average FIFO Filter.

### 📕 [Day 4 — Advanced Data Handling & Math](day4/)
- **Concepts**: Data transfer (`MOV`, `BLKMOV`), Array processing, `FOR` loops in Structured Text, Signal clamping (`MIN`, `MAX`, `LIMIT`).

### 📓 [Day 5 — HMI Integration & Field Devices](day5/)
- **Concepts**: HMI Tag Binding, Screen Design, Alarm Banners, Proximity Sensors, VFDs, Relays, Solenoid Actuators.

### 🎓 [Day 6 — Industrial Capstone Project](day6/)
- **Projects**: Automated Conveyor Belt Sorting System / Industrial Tank Multi-Stage Level Control.

---

## 📜 License & Usage

This repository is maintained for educational and industrial automation training purposes.
