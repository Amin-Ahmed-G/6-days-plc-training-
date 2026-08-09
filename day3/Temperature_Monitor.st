(* ============================================================
   Day 3 Project: Temperature Monitoring & Event Logging System
   Language:      IEC 61131-3 Structured Text
   Standard:      IEC 61131-3
   Description:   Scales 4-20mA thermocouple, applies moving
                  average filter, hysteresis alarm, and one-shot
                  event logging to a circular buffer.
   ============================================================ *)

TYPE
    ALARM_ENTRY : STRUCT
        Temperature  : REAL;
        RawADC       : INT;
        Scan         : DINT;  // scan counter at alarm time
    END_STRUCT;
END_TYPE

PROGRAM Temperature_Monitor
VAR
    (* ── Analog Input ─────────────────────────────────────── *)
    RawADC          : INT;       // 0–1023, from analog input module

    (* ── Scaled Values ─────────────────────────────────────── *)
    Normalized      : REAL;      // 0.0 – 1.0
    ScaledTemp      : REAL;      // °C (unfiltered)
    FilteredTemp    : REAL;      // °C (3-sample moving average)

    (* ── Filter Buffer ─────────────────────────────────────── *)
    Samples         : ARRAY[0..2] OF REAL := [0.0, 0.0, 0.0];

    (* ── Alarm State ───────────────────────────────────────── *)
    HighTempAlarm   : BOOL;      // TRUE when temp > 50.0°C
    AlarmAcked      : BOOL;      // HMI acknowledgement input
    HighTempOut     : BOOL;      // output to alarm lamp

    (* ── Alarm thresholds ──────────────────────────────────── *)
    ALARM_ON_TEMP   : REAL := 50.0;   // °C: alarm activates above this
    ALARM_OFF_TEMP  : REAL := 48.0;   // °C: alarm clears below this (hysteresis)

    (* ── Event Logging ─────────────────────────────────────── *)
    LogTrigger      : BOOL;
    R_TRIG_Alarm    : R_TRIG;
    LogIndex        : INT;
    ScanCount       : DINT;      // running scan counter for timestamps
    AlarmLog        : ARRAY[0..99] OF ALARM_ENTRY;

    (* ── Diagnostics ───────────────────────────────────────── *)
    AlarmCount      : INT;       // total alarm events since reset
END_VAR

(* ─────────────────────────────────────────────────────────────
   Block 1: Scale raw ADC count to engineering units (°C)
   Formula: EU = ((Raw - RawMin) / (RawMax - RawMin)) * (EUMax - EUMin) + EUMin
   ───────────────────────────────────────────────────────────── *)
Normalized := NORM_X(MIN := INT#0, VALUE := RawADC, MAX := INT#1023);
ScaledTemp := SCALE_X(MIN := REAL#0.0, VALUE := Normalized, MAX := REAL#100.0);

(* ─────────────────────────────────────────────────────────────
   Block 2: 3-Sample FIFO Moving Average Filter
   Shifts samples, inserts new reading at [0], averages all 3.
   ───────────────────────────────────────────────────────────── *)
Samples[2]   := Samples[1];
Samples[1]   := Samples[0];
Samples[0]   := ScaledTemp;
FilteredTemp := (Samples[0] + Samples[1] + Samples[2]) / REAL#3.0;

(* ─────────────────────────────────────────────────────────────
   Block 3: Alarm Hysteresis (Dead-Band)
   ON above 50°C, OFF below 48°C, holds state in between.
   ───────────────────────────────────────────────────────────── *)
IF FilteredTemp > ALARM_ON_TEMP THEN
    HighTempAlarm := TRUE;
ELSIF FilteredTemp < ALARM_OFF_TEMP THEN
    HighTempAlarm := FALSE;
    (* Note: no ELSE clause — alarm state is HELD between 48-50°C *)
END_IF;

(* ─────────────────────────────────────────────────────────────
   Block 4: One-Shot Event Log on Alarm Rising Edge
   LogTrigger is TRUE for exactly 1 scan at alarm onset.
   ───────────────────────────────────────────────────────────── *)
R_TRIG_Alarm(CLK := HighTempAlarm);
LogTrigger := R_TRIG_Alarm.Q;

IF LogTrigger THEN
    AlarmLog[LogIndex].Temperature := FilteredTemp;
    AlarmLog[LogIndex].RawADC      := RawADC;
    AlarmLog[LogIndex].Scan        := ScanCount;

    (* Advance circular buffer index *)
    LogIndex := LogIndex + 1;
    IF LogIndex >= 100 THEN
        LogIndex := 0;
    END_IF;

    AlarmCount := AlarmCount + 1;
END_IF;

(* ─────────────────────────────────────────────────────────────
   Block 5: Drive outputs
   ───────────────────────────────────────────────────────────── *)
HighTempOut := HighTempAlarm AND NOT AlarmAcked;

(* ─────────────────────────────────────────────────────────────
   Block 6: Scan counter (increments every scan for timestamps)
   ───────────────────────────────────────────────────────────── *)
ScanCount := ScanCount + 1;

END_PROGRAM
