# 🔌 Day 3 — Ladder Logic Diagrams

This document contains standard IEC-style Ladder Diagrams for Day 3 Analog Scaling, Comparator Logic, Event Logging, and Arithmetic Guard circuits.

---

## Rung 1: Analog Input Scaling (`RawADC` $0-1023 \rightarrow 0.0-100.0^\circ\text{C}$)

```text
  Power Rail (+)                                                              Power Rail (-)
       |                                                                            |
  1    |--------------------------------------------[ SCL                       ]---|
       |                                            [ Source:   RawADC          ]   |
       |                                            [ InputMin: 0               ]   |
       |                                            [ InputMax: 1023            ]   |
       |                                            [ ScaledMin:0.0             ]   |
       |                                            [ ScaledMax:100.0           ]   |
       |                                            [ Dest:     ScaledTemp      ]   |
```

---

## Rung 2: High Temperature Comparison (`ScaledTemp > 50.0^\circ\text{C}`)

```text
  Power Rail (+)                                                              Power Rail (-)
       |                                                                            |
  1    |-------[ GT ScaledTemp 50.0 ]----------------------------( HighTempAlarm )--|
       |          (Greater Than)                                       (Coil)       |
```

---

## Rung 3: One-Shot Alarm Event Logging (`HighTempAlarm` $\rightarrow$ `ONS` $\rightarrow$ `LogTrigger`)

```text
  Power Rail (+)                                                              Power Rail (-)
       |                                                                            |
  1    |-------[ HighTempAlarm ]--------[ ONS ]-----------------------( LogTrigger )|
       |             (NO)              (One-Shot)                        (Coil)     |
       |                                                                            |
  2    |-------[ LogTrigger ]-----------------------[ MOV CurrentTime -> LogTime  ]-|
       |           (NO)                             [ MOV ScaledTemp  -> LogVal  ]  |
```

---

## Rung 4: Division-by-Zero Guard for Averaging Operation

```text
  Power Rail (+)                                                              Power Rail (-)
       |                                                                            |
  1    |-------[ ADD ScaledTemp1 ScaledTemp2 SumTemp ]------------------------------|
       |                                                                            |
  2    |-------[ GT SensorCount 0 ]-----------------[ DIV SumTemp SensorCount Avg ]-|
       |         (SensorCount > 0)                    (Execute Division safely)     |
```
