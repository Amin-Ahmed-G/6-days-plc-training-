// Day 1 Project: Motor Start/Stop with Seal-In Circuit
// Language: Structured Text (IEC 61131-3)

PROGRAM Motor_Control
VAR
    Start_PB  : BOOL; // Normally Open Push Button
    Stop_PB   : BOOL; // Normally Closed Push Button (Fail-Safe)
    Motor_Run : BOOL; // Motor Contactor Output
END_VAR

// Rung Logic: Seal-in circuit with NC Stop override
Motor_Run := (Start_PB OR Motor_Run) AND NOT Stop_PB;

END_PROGRAM
