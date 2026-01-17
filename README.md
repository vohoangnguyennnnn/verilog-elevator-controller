# Verilog Elevator Controller (FSM-Based)

A synthesizable elevator controller implemented in Verilog HDL using a clean and robust finite state machine (FSM) architecture.  
This project is intended for RTL design practice, verification demonstration, and digital IC design portfolios.

---

# 🇬🇧 ENGLISH VERSION

## 1. Overview

This repository contains a fully synthesizable elevator controller written in Verilog HDL.  
The design is based on a finite state machine (FSM) and follows good RTL coding practices suitable for synthesis and hardware implementation.

The project focuses on:
- Clear state-based control logic
- Proper separation of combinational and sequential logic
- Robust handling of multiple floor requests
- Clean, tool-friendly RTL code

This repository is suitable for students and entry-level digital / RTL design engineers.

---

## 2. Features

- FSM-based elevator control
- Multiple floor requests using bitmask representation
- Direction-aware scheduling (up / down)
- Configurable door open duration
- One-cycle STOP state before door opening (realistic behavior)
- Moore-style output logic
- No latches, no unsafe constructs, synthesizable RTL

---

## 3. FSM States

| State | Description |
|------|------------|
| IDLE | Elevator is stationary, waiting for requests |
| UP | Elevator moving upward |
| DN | Elevator moving downward |
| STOP | One-cycle delay after reaching a target floor |
| DOOR | Door open state for a programmable duration |

---

### RTL Coding Style
- `_q` / `_d` naming convention for registers and next-state logic
- Single combinational block for next-state calculation
- Single sequential block for state and register updates
- Moore FSM outputs for predictable timing

---

## 5. Parameters

| Parameter | Description |
|---------|------------|
| FLOORS | Number of supported floors |
| POS_W | Bit-width of floor position |
| DOOR_CYCLES | Number of clock cycles the door remains open |

---

## 6. Simulation and Verification

The provided testbench verifies:
- Single and multiple floor requests
- Correct direction decision logic
- Proper STOP → DOOR sequencing
- Door timing behavior
- No unnecessary door openings when requests are canceled

Simulation can be run using:
- Vivado Simulator
- ModelSim / Questa
- Icarus Verilog

---

## 7. License

This project is released under the MIT License.

---

## 8. Author

Vo Hoang Nguyen
GitHub: https://github.com/vohoangnguyennnnn