RSA IP used - Trust Hub BASICRSA - T100

FPGA : ARTY Z7
Vivado Xilinx IP : FIFO, BRAM

# RSA WRAPPER (FPGA / AXI-based Design)

## Overview

This project implements an FPGA-based RSA WRAPPER integrated within a Zynq SoC environment.  
The design includes a FIFO-based controller, AXI-based communication interfaces, and BRAM integration to enable efficient hardware acceleration and system-level interaction between the Processing System (PS) and Programmable Logic (PL).

## Architecture

### RSA IP Block Diagram

![RSA IP Block Diagram](RSA IP block diagram.png)

The RSA IP core performs cryptographic operations and is connected to system memory and control interfaces via AMBA AXI protocols.

---

### RSA Controller Block Diagram

![RSA Controller Block Diagram](RSA_controller_block_diagram.png)

A FIFO-based controller manages data flow, buffering, and control signals between the processing system and hardware accelerator.

---

### WRAP_RSA System Architecture

![WRAP RSA Architecture](WRAP_RSA.drawio.png)

System-level integration showing AXI interconnect, BRAM usage, and PS–PL interaction within the Zynq SoC environment.

---

## Key Features

- FPGA-based RSA hardware acceleration
- FIFO-based RTL controller design
- AMBA AXI interface integration
- PS–PL communication in Zynq SoC
- BRAM-based data buffering

## Environment

- Zynq SoC Platform
- Vitis/Vivado
- Verilog RTL Design
- AMBA AXI Interconnect

