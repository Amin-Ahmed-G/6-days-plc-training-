# 🔌 Day 2 — Ladder Logic Diagrams

This document contains standard IEC-style Ladder Diagrams for all Day 2 timers, counters, one-shots, and state machine circuits.

---

## Rung 1: TON (Timer On-Delay) Motor Delay

```text
  Power Rail (+)                                                    Power Rail (-)
       |                                                                  |
  1    |-------[ Start_PB ]-------------------+---------------------------|
       |          (NO)                        |   TON                     |
       |                                      |  MotorDelay               |
       |                                      |  PT = 5000 ms             |
       |                                      +---------------------------|
       |                                                                  |
  2    |-------[ MotorDelay.Q ]---------------------------------( Motor )--|
       |            (NO)                                         (Coil)   |
```

---

## Rung 2: TOF (Timer Off-Delay) Cooling Fan Run-On

```text
  Power Rail (+)                                                    Power Rail (-)
       |                                                                  |
  1    |-------[ Motor_Running ]--------------+---------------------------|
       |             (NO)                     |   TOF                     |
       |                                      |  FanRunOn                 |
       |                                      |  PT = 30000 ms            |
       |                                      +---------------------------|
       |                                                                  |
  2    |-------[ FanRunOn.Q ]------------------------------( Fan_Output )--|
       |           (NO)                                       (Coil)      |
```

---

## Rung 3: Edge-Triggered Part Counter (PartSensor $\rightarrow$ ONS $\rightarrow$ CTU)

```text
  Power Rail (+)                                                              Power Rail (-)
       |                                                                            |
  1    |-------[ PartSensor ]-----------[ ONS ]------------+------------------------|
       |           (NO)                (One-Shot)          |   CTU                  |
       |                                                   |  PartCount             |
       |                                                   |  PV = 10               |
       |                                                   +------------------------|
       |                                                                            |
  2    |-------[ PartCount.Q ]--------------------------------( BatchComplete )-----|
       |           (NO)                                            (Coil)           |
       |                                                                            |
  3    |-------[ ResetBtn ]------------------------------------[ RES PartCount ]----|
       |          (NO)                                           (Reset Counter)    |
```

---

## Rung 4: Debounce Counter (PartSensor $\rightarrow$ TON $\rightarrow$ ONS $\rightarrow$ CTU)

```text
  Power Rail (+)                                                              Power Rail (-)
       |                                                                            |
  1    |-------[ PartSensor ]-----------------------------+-------------------------|
       |           (NO)                                   |   TON                   |
       |                                                  |  DebounceTimer          |
       |                                                  |  PT = 3000 ms           |
       |                                                  +-------------------------|
       |                                                                            |
  2    |-------[ DebounceTimer.Q ]-------[ ONS ]-----------+-------------------------|
       |              (NO)             (One-Shot)         |   CTU                   |
       |                                                  |  PartCount              |
       |                                                  |  PV = 10                |
       |                                                  +-------------------------|
```

---

## Rung 5: Traffic Light Controller State Machine (Option A: INT State + EQU)

```text
  Power Rail (+)                                                              Power Rail (-)
       |                                                                            |
  1    |-------[ EQU TrafficState 0 ]------------------------------( Red_Light )----|
       |                                                            (Coil)          |
       |                                                                            |
  2    |-------[ EQU TrafficState 0 ]---------------------+-------------------------|
       |                                                  |   TON                   |
       |                                                  |  TON_Red                |
       |                                                  |  PT = 10000 ms          |
       |                                                  +-------------------------|
       |                                                                            |
  3    |-------[ TON_Red.Q ]------------------------[ MOV 1 -> TrafficState ]-------|
       |           (NO)                             [ RES TON_Red           ]       |
       |                                                                            |
  4    |-------[ EQU TrafficState 1 ]----------------------------( Green_Light )----|
       |                                                            (Coil)          |
       |                                                                            |
  5    |-------[ EQU TrafficState 1 ]---------------------+-------------------------|
       |                                                  |   TON                   |
       |                                                  |  TON_Green              |
       |                                                  |  PT = 8000 ms           |
       |                                                  +-------------------------|
       |                                                                            |
  6    |-------[ TON_Green.Q ]----------------------[ MOV 2 -> TrafficState ]-------|
       |           (NO)                             [ RES TON_Green         ]       |
       |                                                                            |
  7    |-------[ EQU TrafficState 2 ]----------------------------( Yellow_Light )---|
       |                                                            (Coil)          |
       |                                                                            |
  8    |-------[ EQU TrafficState 2 ]---------------------+-------------------------|
       |                                                  |   TON                   |
       |                                                  |  TON_Yellow             |
       |                                                  |  PT = 3000 ms           |
       |                                                  +-------------------------|
       |                                                                            |
  9    |-------[ TON_Yellow.Q ]---------------------[ MOV 0 -> TrafficState ]-------|
       |           (NO)                             [ RES TON_Yellow        ]       |
```
