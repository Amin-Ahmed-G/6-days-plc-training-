# ✅ Day 6 — Commissioning Checklist & Sign-Off Sheet
## Automated Conveyor Sorting System

**Project**: 6-Day PLC Training Capstone
**Date**: ________________
**Technician**: ________________
**Supervisor**: ________________

---

## Phase 1: Pre-Power Safety Check

| # | Check | Pass | Fail | Notes |
|:--|:--|:--:|:--:|:--|
| 1 | All unused terminals insulated | ☐ | ☐ | |
| 2 | E-stop wired NC, tested continuity | ☐ | ☐ | |
| 3 | VFD fault relay wired NC, tested | ☐ | ☐ | |
| 4 | 24V DC supply fuses correct rating | ☐ | ☐ | |
| 5 | No exposed conductors inside panel | ☐ | ☐ | |
| 6 | Earth/ground bonding verified | ☐ | ☐ | |

---

## Phase 2: I/O Point-to-Point Verification

| # | Tag | Address | Test Method | Expected | Actual | Pass |
|:--|:--|:--|:--|:--|:--|:--:|
| 1 | `Optical_Sensor` | `%I0.0` | Hand in front of sensor | I0.0 = 1 | | ☐ |
| 2 | `Metal_Prox` | `%I0.1` | Metal plate at sensor | I0.1 = 1 | | ☐ |
| 3 | `Part_At_Zone5` | `%I0.2` | Hand at Zone 5 sensor | I0.2 = 1 | | ☐ |
| 4 | `EStop_NC` | `%I0.3` | Press E-stop | I0.3 = 0 | | ☐ |
| 5 | `EStop_NC` wire-pull | `%I0.3` | Disconnect E-stop wire | I0.3 = 0 | | ☐ |
| 6 | `VFD_Fault_NC` | `%I0.4` | Trip VFD manually | I0.4 = 0 | | ☐ |
| 7 | `Divert_Solenoid` | `%Q0.0` | Force Q0.0=1 | Arm extends | | ☐ |
| 8 | `Conveyor_VFD_Run` | `%Q0.1` | Force Q0.1=1 | VFD starts | | ☐ |
| 9 | `Tower_Green` | `%Q0.2` | Force Q0.2=1 | Green lamp ON | | ☐ |
| 10 | `Tower_Red` | `%Q0.3` | Force Q0.3=1 | Red lamp ON | | ☐ |
| 11 | `Conveyor_Speed_AO` | `%QW64` | Set to 50%, measure | 12mA on meter | | ☐ |

> ⚠️ **CLEAR ALL FORCES BEFORE PROCEEDING TO PHASE 3**

Forces cleared: ☐ **Initials**: ________

---

## Phase 3: Logic Dry-Run (Forced I/O)

| # | Test Scenario | Procedure | Expected Result | Pass |
|:--|:--|:--|:--|:--:|
| 1 | Non-metal through Zone 5 | Force Optical=1, Metal=0, advance 5 zones | No divert arm activation | ☐ |
| 2 | Metal through Zone 5 | Force Optical=1, Metal=1, advance 5 zones | Divert arm fires at Zone 5 | ☐ |
| 3 | E-stop while running | Press E-stop button | Belt stops, Tower Red ON, latch set | ☐ |
| 4 | Reset after E-stop | Release E-stop, press HMI Reset | Tower Red OFF, system ready | ☐ |
| 5 | VFD fault simulation | Simulate VFD fault | Belt stops, Red lamp, fault latch | ☐ |
| 6 | Reset VFD fault | Clear VFD fault, press Reset | System ready | ☐ |

---

## Phase 4: Live Production Test

| # | Test | Parts Fed | Expected Result | Actual | Pass |
|:--|:--|:--|:--|:--|:--:|
| 1 | All non-metal | 10 non-metal | 0 diversions, NonMetal=10 | | ☐ |
| 2 | All metal | 10 metal | 10 diversions, Metal=10 | | ☐ |
| 3 | Mixed 50/50 | 5 metal, 5 non-metal | 5 diversions, correct counts | | ☐ |
| 4 | High speed | 10 mixed at 80% speed | Correct sorting maintained | | ☐ |
| 5 | E-stop mid-run | Press E-stop during production | Immediate stop, latch | | ☐ |

---

## Phase 5: HMI Verification

| # | Screen | Element | Check | Pass |
|:--|:--|:--|:--|:--:|
| 1 | Main | System State display | Shows Idle/Running/Fault correctly | ☐ |
| 2 | Main | Part counts | TotalCount, MetalCount, NonMetalCount update correctly | ☐ |
| 3 | Main | Speed setpoint | Changing % value changes conveyor speed | ☐ |
| 4 | Alarms | E-stop alarm | Appears when E-stop pressed | ☐ |
| 5 | Alarms | ACK button | Alarm acknowledged, horn stops | ☐ |

---

## Sign-Off

| Role | Name | Signature | Date |
|:--|:--|:--|:--|
| Trainee / Programmer | | | |
| Supervisor / Instructor | | | |
| Safety Officer | | | |

**Overall Result**: ☐ PASS — System commissioned and approved for production testing
