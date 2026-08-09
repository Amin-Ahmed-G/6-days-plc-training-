# Day 4 — Advanced Data Handling & Math Operations

## 📖 Concept Summary & Technical Guide

### 1. Data Manipulation & Storage
- **MOV (Move) & BLKMOV (Block Move)**: Transfer single values or contiguous memory blocks between registers and arrays.
- **Array Processing & Loop Logic**: Iterate over arrays using index pointers for batch processing of sensor arrays.

### 2. Advanced Math & Analog Signal Processing
- Multi-variable engineering calculations.
- Analog signal filtering and signal clamping logic (`MIN`, `MAX`, `LIMIT`).

---

## 💻 Day 4 Projects & Exercises

### Exercise 1: Multi-Sensor Data Normalization
Batch scaling across array elements `Sensors[0..5]` using `FOR` loop constructs in Structured Text:
```iecst
FOR i := 0 TO 5 DO
    ScaledSensors[i] := (RawSensors[i] - RawMin) * (EUMax - EUMin) / (RawMax - RawMin) + EUMin;
END_FOR;
```
