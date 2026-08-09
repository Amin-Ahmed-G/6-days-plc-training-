# Day 1 — Student Tasks & Instructor Solutions

## Task 1 — Architecture Labeling
- **Given**: Power Supply $\rightarrow$ CPU $\rightarrow$ I/O Modules.
- **Solution**: Mains side: 100–240V AC. I/O side: 24V DC. Logic changes modify RAM memory, not physical wiring.

## Task 2 — Relay vs. PLC Scenario
- **Question**: Compare adding an interlock in a relay panel vs. a PLC.
- **Solution**: Relay panel requires physical re-wiring of contacts across the rack (hours of work). PLC solves the interlock in stored program RAM against the frozen I/O image table; field wiring remains untouched.

## Task 3 — Output Module Selection
- **(a) 230V AC Solenoid**: Relay or Triac (Transistor cannot switch AC).
- **(b) High-frequency PWM DC valve**: Transistor (DC only, no mechanical wear).
- **(c) 24V DC indicator lamp (50,000 switches/day)**: Transistor (Exceeds relay mechanical cycle limits).

## Task 4 — Trace the Scan
- Output turns on at the **OUTPUT UPDATE** phase of the first full scan cycle following the press.

## Task 5 — Missed Pulse Diagnosis
- Pulse duration is shorter than the scan time, so the signal went high and low between input scan phases without being latched into IIT.

## Task 6 — Wire It, Verify It
- Confirm bit toggling in online I/O status view before writing logic.

## Task 7 — E-Stop Fault Analysis
- NC wiring guarantees safe machine shutdown on wire breaks. NO wiring allows undetected dangerous faults.

## Task 8 — Rung Translation Drill
- **ST**: `Lamp := (SensorA OR SensorB) AND NOT GuardDoor;`

## Task 9 — Tag Naming Audit
- Raw address `%I0.3` conveys no meaning, while `Start_PB` and `Safety_OK` communicate intent immediately.

## Task 10 — AND/OR Project (Graded)
- **AND**: `Lamp := PB1 AND PB2;`
- **OR**: `Lamp := PB1 OR PB2;`

## Task 11 — Predict-Before-Build (Seal-In)
- Without `Motor_Run` seal-in contact, motor runs only while `Start_PB` is physically held.

## Task 12 — Build & Debug (Seal-In)
- **ST**: `Motor_Run := (Start_PB OR Motor_Run) AND NOT Stop_PB;`

## Task 13 — Forward/Reverse Interlock (Stretch)
- **ST**:
  ```iecst
  Fwd_Run := (Fwd_PB OR Fwd_Run) AND NOT Stop_PB AND NOT Rev_Run;
  Rev_Run := (Rev_PB OR Rev_Run) AND NOT Stop_PB AND NOT Fwd_Run;
  ```
- **Winner Determination**: Top-to-bottom scan order determines the winner if both buttons are pressed on the same scan.
