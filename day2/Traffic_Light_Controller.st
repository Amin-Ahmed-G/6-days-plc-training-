(* ============================================================
   Day 2 Project: 3-Phase Traffic Light State Machine
   Language:      IEC 61131-3 Structured Text
   Standard:      IEC 61131-3
   Description:   Cyclic Red → Green → Yellow → Red state
                  machine using CASE statement and TON timers.
   ============================================================ *)

PROGRAM Traffic_Light_Controller

VAR
    (* State Register: 0=Red, 1=Green, 2=Yellow, 3=Pedestrian *)
    TrafficState   : INT := 0;

    (* Output Coils *)
    Red_Light      : BOOL;
    Green_Light    : BOOL;
    Yellow_Light   : BOOL;
    Ped_Walk       : BOOL;  // Pedestrian walk signal

    (* Inputs *)
    PedestrianBtn  : BOOL;  // Pedestrian push-button

    (* Timer Instances *)
    TON_Red        : TON;
    TON_Green      : TON;
    TON_Yellow     : TON;
    TON_Ped        : TON;
END_VAR

(* ── Clear all outputs at start of each scan ─────────────────── *)
Red_Light    := FALSE;
Green_Light  := FALSE;
Yellow_Light := FALSE;
Ped_Walk     := FALSE;

(* ── Pedestrian Priority Override (Rung 0 — highest priority) ── *)
IF PedestrianBtn AND (TrafficState = 1 OR TrafficState = 2) THEN
    (* Reset running timers before state jump *)
    TON_Green(IN  := FALSE, PT := T#8s);
    TON_Yellow(IN := FALSE, PT := T#3s);
    TrafficState := 3;
END_IF;

(* ── Main State Machine ──────────────────────────────────────── *)
CASE TrafficState OF

    0: (* ─── RED STATE ─── *)
        Red_Light := TRUE;
        TON_Red(IN := TRUE, PT := T#10s);
        IF TON_Red.Q THEN
            TON_Red(IN := FALSE, PT := T#10s);  // reset
            TrafficState := 1;                   // → Green
        END_IF;

    1: (* ─── GREEN STATE ─── *)
        Green_Light := TRUE;
        TON_Green(IN := TRUE, PT := T#8s);
        IF TON_Green.Q THEN
            TON_Green(IN := FALSE, PT := T#8s);  // reset
            TrafficState := 2;                    // → Yellow
        END_IF;

    2: (* ─── YELLOW STATE ─── *)
        Yellow_Light := TRUE;
        TON_Yellow(IN := TRUE, PT := T#3s);
        IF TON_Yellow.Q THEN
            TON_Yellow(IN := FALSE, PT := T#3s);  // reset
            TrafficState := 0;                     // → Red
        END_IF;

    3: (* ─── PEDESTRIAN STATE ─── *)
        Red_Light := TRUE;
        Ped_Walk  := TRUE;
        TON_Ped(IN := TRUE, PT := T#5s);
        IF TON_Ped.Q THEN
            TON_Ped(IN := FALSE, PT := T#5s);    // reset
            TrafficState := 0;                    // → Red (full cycle reset)
        END_IF;

ELSE
    (* Safety: invalid state — default to Red *)
    TrafficState := 0;
    TON_Red(IN := FALSE, PT := T#10s);

END_CASE;

END_PROGRAM
