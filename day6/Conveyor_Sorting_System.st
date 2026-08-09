(* ============================================================
   Day 6 Capstone: Automated Conveyor Sorting System
   Language:       IEC 61131-3 Structured Text
   Standard:       IEC 61131-3
   Description:    Full sorting system with shift register product
                   tracking, divert arm control, VFD conveyor speed,
                   E-stop safety latch, and HMI interface.
   ============================================================ *)

(* ── Global Types ─────────────────────────────────────────────── *)
TYPE
    AlarmEntry : STRUCT
        AlarmID    : INT;
        ScanNumber : DINT;
        Active     : BOOL;
        Acked      : BOOL;
    END_STRUCT;
END_TYPE

(* ────────────────────────────────────────────────────────────────
   FUNCTION BLOCK: Safety_Manager
   Purpose: E-stop latch, system-ready flag, tower lamp control
   ───────────────────────────────────────────────────────────── *)
FUNCTION_BLOCK Safety_Manager
VAR_INPUT
    EStop_NC        : BOOL;    // NC input: 1=safe, 0=tripped or wire fault
    VFD_Fault_NC    : BOOL;    // NC input: 1=no fault, 0=VFD fault
    Reset_Cmd       : BOOL;    // HMI reset button
    System_Run_Cmd  : BOOL;    // HMI start command
END_VAR
VAR_OUTPUT
    System_Safe     : BOOL;    // TRUE when no faults
    System_Ready    : BOOL;    // TRUE when safe and reset
    System_Running  : BOOL;    // TRUE when actively running
    Tower_Green     : BOOL;    // Green tower lamp output
    Tower_Red       : BOOL;    // Red tower lamp output
    Fault_Code      : INT;     // 0=none, 1=E-stop, 2=VFD fault
END_VAR
VAR
    EStop_Latched   : BOOL;
    VFD_Fault_Latched : BOOL;
END_VAR

(* Check current safety conditions *)
System_Safe := EStop_NC AND VFD_Fault_NC;

(* Latch faults — require explicit reset *)
IF NOT EStop_NC THEN
    EStop_Latched     := TRUE;
    System_Running    := FALSE;
    Fault_Code        := 1;
END_IF;

IF NOT VFD_Fault_NC THEN
    VFD_Fault_Latched := TRUE;
    System_Running    := FALSE;
    Fault_Code        := 2;
END_IF;

(* Clear latches only when fault is cleared AND reset pressed *)
IF Reset_Cmd AND EStop_NC THEN
    EStop_Latched := FALSE;
END_IF;

IF Reset_Cmd AND VFD_Fault_NC THEN
    VFD_Fault_Latched := FALSE;
END_IF;

IF NOT EStop_Latched AND NOT VFD_Fault_Latched THEN
    Fault_Code := 0;
END_IF;

(* System ready when all clear *)
System_Ready := System_Safe AND NOT EStop_Latched AND NOT VFD_Fault_Latched;

(* Start/stop control *)
IF System_Run_Cmd AND System_Ready THEN
    System_Running := TRUE;
ELSIF NOT System_Ready THEN
    System_Running := FALSE;
END_IF;

(* Tower lamp outputs *)
Tower_Green := System_Running AND System_Ready;
Tower_Red   := EStop_Latched OR VFD_Fault_Latched;

END_FUNCTION_BLOCK


(* ────────────────────────────────────────────────────────────────
   FUNCTION BLOCK: Conveyor_Controller
   Purpose: VFD run/stop, analog speed reference, running feedback
   ───────────────────────────────────────────────────────────── *)
FUNCTION_BLOCK Conveyor_Controller
VAR_INPUT
    Run_Enable       : BOOL;     // from safety manager
    SpeedSetpoint_pct : REAL;   // 0.0 – 100.0 % from HMI
    VFD_Running_FB   : BOOL;    // VFD running status feedback
END_VAR
VAR_OUTPUT
    VFD_Run          : BOOL;    // digital run command to VFD
    Speed_AO_Raw     : INT;     // 4-20mA raw count to AO module
    Conveyor_Running : BOOL;    // confirmed running (from VFD feedback)
END_VAR

VFD_Run := Run_Enable;

(* Scale 0-100% setpoint to 4-20mA: 4mA=5530 counts, 20mA=27648 counts *)
IF Run_Enable THEN
    Speed_AO_Raw := INT#5530 + REAL_TO_INT(SpeedSetpoint_pct / REAL#100.0
                    * REAL#(27648 - 5530));
ELSE
    Speed_AO_Raw := INT#0;   // 0mA when stopped
END_IF;

Conveyor_Running := VFD_Running_FB;

END_FUNCTION_BLOCK


(* ────────────────────────────────────────────────────────────────
   PROGRAM: Sorting_Logic
   Purpose: Shift register product tracking and divert arm control
   ───────────────────────────────────────────────────────────── *)
PROGRAM Sorting_Logic
VAR
    (* ── Physical I/O ──────────────────────────────────────── *)
    Optical_Sensor   : BOOL;    // %I0.0 — part detected at Zone 0
    Metal_Prox       : BOOL;    // %I0.1 — metal detected at Zone 2
    Part_At_Zone5    : BOOL;    // %I0.2 — part trigger sensor at Zone 5
    EStop_NC         : BOOL;    // %I0.3 — E-stop (NC)
    VFD_Fault_NC     : BOOL;    // %I0.4 — VFD fault relay (NC)
    VFD_Running_FB   : BOOL;    // %I0.5 — VFD running feedback
    Divert_Solenoid  : BOOL;    // %Q0.0 — divert arm solenoid
    Conveyor_VFD_Run : BOOL;    // %Q0.1 — VFD run command
    Tower_Green      : BOOL;    // %Q0.2
    Tower_Red        : BOOL;    // %Q0.3
    Conveyor_Speed_AO : INT;    // %QW64 — 4-20mA speed reference

    (* ── HMI Interface Tags ─────────────────────────────────── *)
    HMI_Start        : BOOL;
    HMI_Stop         : BOOL;
    HMI_Reset        : BOOL;
    HMI_SpeedSP_pct  : REAL := 30.0;
    HMI_TotalCount   : INT;
    HMI_MetalCount   : INT;
    HMI_NonMetalCount : INT;
    HMI_System_State : INT;     // 0=Idle, 1=Running, 2=Fault

    (* ── Shift Register (10 conveyor zones) ─────────────────── *)
    PartPresent      : ARRAY[0..9] OF BOOL;
    PartIsMetal      : ARRAY[0..9] OF BOOL;

    (* ── Zone advancement (from encoder or timing) ───────────── *)
    R_TRIG_Zone      : R_TRIG;
    TON_ZoneTimer    : TON;     // advance zones on 500ms timer
    ZoneAdvance      : BOOL;

    (* ── Divert Arm ─────────────────────────────────────────── *)
    DivertArm_Active : BOOL;
    TON_Divert       : TON;

    (* ── Function Block Instances ───────────────────────────── *)
    Safety           : Safety_Manager;
    Conveyor         : Conveyor_Controller;

    (* ── Diagnostics ─────────────────────────────────────────── *)
    ScanCount        : DINT;
    i                : INT;     // loop index
END_VAR

(* ─────────────────────────────────────────────────────────────
   Block 1: Safety Management
   ───────────────────────────────────────────────────────────── *)
Safety(
    EStop_NC       := EStop_NC,
    VFD_Fault_NC   := VFD_Fault_NC,
    Reset_Cmd      := HMI_Reset,
    System_Run_Cmd := HMI_Start AND NOT HMI_Stop
);

Tower_Green := Safety.Tower_Green;
Tower_Red   := Safety.Tower_Red;

(* ─────────────────────────────────────────────────────────────
   Block 2: Conveyor VFD Control
   ───────────────────────────────────────────────────────────── *)
Conveyor(
    Run_Enable        := Safety.System_Running,
    SpeedSetpoint_pct := HMI_SpeedSP_pct,
    VFD_Running_FB    := VFD_Running_FB
);

Conveyor_VFD_Run  := Conveyor.VFD_Run;
Conveyor_Speed_AO := Conveyor.Speed_AO_Raw;

(* ─────────────────────────────────────────────────────────────
   Block 3: Zone Advancement Timer (advances zones every 500ms)
   In real system, replace with encoder pulse input
   ───────────────────────────────────────────────────────────── *)
TON_ZoneTimer(IN := Safety.System_Running, PT := T#500ms);
IF TON_ZoneTimer.Q THEN
    TON_ZoneTimer(IN := FALSE, PT := T#500ms);  // reset for next cycle
    ZoneAdvance := TRUE;
ELSE
    ZoneAdvance := FALSE;
END_IF;

(* ─────────────────────────────────────────────────────────────
   Block 4: Shift Register — Product Zone Tracking
   ───────────────────────────────────────────────────────────── *)
R_TRIG_Zone(CLK := ZoneAdvance);

IF R_TRIG_Zone.Q THEN
    (* Shift all zones forward by one *)
    FOR i := 9 DOWNTO 1 DO
        PartPresent[i] := PartPresent[i - 1];
        PartIsMetal[i] := PartIsMetal[i - 1];
    END_FOR;

    (* Load new part detection at Zone 0 *)
    PartPresent[0] := Optical_Sensor;
    PartIsMetal[0] := Metal_Prox;

    (* Count new part entering system *)
    IF Optical_Sensor THEN
        HMI_TotalCount := HMI_TotalCount + 1;
        IF Metal_Prox THEN
            HMI_MetalCount    := HMI_MetalCount + 1;
        ELSE
            HMI_NonMetalCount := HMI_NonMetalCount + 1;
        END_IF;
    END_IF;
END_IF;

(* ─────────────────────────────────────────────────────────────
   Block 5: Divert Arm Control
   Fire when metal part physically arrives at Zone 5
   ───────────────────────────────────────────────────────────── *)
IF PartPresent[5] AND PartIsMetal[5] AND Part_At_Zone5
   AND Safety.System_Running THEN
    DivertArm_Active := TRUE;
END_IF;

(* Auto-retract after 500ms *)
TON_Divert(IN := DivertArm_Active, PT := T#500ms);
IF TON_Divert.Q THEN
    DivertArm_Active := FALSE;
    TON_Divert(IN := FALSE, PT := T#500ms);
END_IF;

Divert_Solenoid := DivertArm_Active;

(* ─────────────────────────────────────────────────────────────
   Block 6: HMI State Update
   ───────────────────────────────────────────────────────────── *)
IF Safety.Tower_Red THEN
    HMI_System_State := 2;       // Fault
ELSIF Safety.System_Running THEN
    HMI_System_State := 1;       // Running
ELSE
    HMI_System_State := 0;       // Idle
END_IF;

ScanCount := ScanCount + 1;

END_PROGRAM
