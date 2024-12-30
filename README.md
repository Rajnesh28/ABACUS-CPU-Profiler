# ABACUS - CPU Profiler for CVA5 Softcore

This repository presents a CPU profiler that adheres to the ABACUS (hArdware Based Analyzer for the Characterization of User Software) framework. It profiles the CVA5 RISC-V softcore processor running on an FPGA. This repository includes both HDL and software components for profiling software performance on baremetal and Linux systems.

## Project Structure

HDL/
├── CVA5 fork/              # Forked and modified version of the CVA5 core
├── profiling_units/        # Contains hardware profiling units (Instruction, Cache, and Stall Unit)
├── tests/                  # Verification tests for hardware modules
├── abacus_top.sv           # Top-level Verilog module integrating profiler with CVA5 core
└── core.py                 # Python script for generating Verilog wrappers and other SoC components in LiteX

SW/
├── baremetal/              # Software for running profiler in a baremetal environment
└── linux/                  # Software and drivers for profiling in Linux userspace

## Key Components

### 1. **CVA5 Core**
The CVA5 processor is a 32-bit RISC-V processor supporting RV32IMAD instructions with Linux-capable user and supervisor modes. This project uses a custom fork of CVA5 with modifications to expose profiling nets to the profiler.

### 2. **Profiling Units**
- **Instruction Profiling Unit**: Monitors issued instructions and categorizes them by type (e.g., Load, Store, Branch). It provides detailed insights into how many instructions of each type are executed.
- **Cache Profiling Unit**: Tracks the number of cache requests, hits, and misses, and the time to refill cache lines after misses. This helps evaluate memory usage efficiency and cache replacement policies.
- **Stall Unit**: Profiles different causes of pipeline stalls (e.g., no instructions ready, operands not ready) to help improve CPU performance by reducing stalls.

### 3. **ABACUS Profiler Integration**
The top-level design integrates the ABACUS profiler with the CVA5 processor using a Wishbone bus interface. Software running on the CPU can enable or disable profiling units and read performance data from memory-mapped registers.

## Software Components

### 1. **Baremetal Profiling**
The baremetal software directly accesses the profiler's registers using physical memory addresses. This allows developers to profile CPU performance without an operating system, providing low-level performance data.

### 2. **Userspace Software Profiling**
In Linux, the profiler is accessed via a character device driver. This driver maps the profiler's physical memory into the Linux kernel space, allowing userspace applications to read profiling data and control the profiler through a simple API.

