
---
title: "Surface diving into Tenstorrent's Wormhole architecture"
date: 2026-06-07
tags: ["AI", "Accelerator", "Blackhole", "Wormhole","Tenstorrent"]
---

## 0: Overview and stats
This blog will be focusing mainly on it's microarchitecture, along with their NoC. I will touch their peripherals and compiler a lil as well, but won't be digging too much into their ISA, because honestly, it's a documentation hell in their tt-metal and ISA documentation repo (not complaining tho, thankyou TT for making it open, very cool).

Before understanding their microarchitecture, it's good to know the performance it delivers (LOL jk, I just put it there to sound like a nerd).
Below is a table comparing their various accelerator cards with their performance and hardware specifications. We'll discuss everything soon dw.


| Architectural Specification| Grayskull (e150)       | Wormhole (n300s - Dual ASIC) | Blackhole (p150a - Single ASIC)  |
|----------------------------|------------------------|------------------------------|----------------------------------|
| Process Node               | 12nm                   | 12nm                         | 6nm                              |
| Usable Tensix Cores        | 120                    | 128 (64 per ASIC)            | 120                              |
| Application CPU Cores      | None (Host Dependent)  | None (Host Dependent)        | 16x SiFive Intelligence X280     |
| On-Die SRAM Capacity       | 120 MB                 | 192 MB                       | 180 MB                           |
| DRAM Capacity              | 8 GB LPDDR4            | 24 GB GDDR6                  | 32 GB GDDR6                      |
| DRAM Bandwidth             | 118 GB/s               | 576 GB/s                     | 512 GB/s                         |
| Ethernet Interconnect      | N/A (PCIe 4.0 x16 only)| 4x 100 GbE (Warp 100 + QSFP-DD) | 4x 800 GbE (QSFP-DD)          |
| Compute Throughput (FP8)   | 332 TeraFLOPS          | 466 TeraFLOPS                | 745 TeraFLOPS                    |
| Total Board Power (TBP)    | 200W                   | 300W                         | 300W                             |


## 1: What's a Tensix Tile/Core?
Tenstorrent's architecture is a spacially distributed grid of compute cores connected by an NoC. They've named them `Tensix cores`. Fundamentally, the architecture isn't SIMD/SIMT or dataflow, it's basically a grid of Tensix cores and the compiler schedules compute load onto each core.
Wormhole has around 64 Tensix cores, and blackhole has 128 as specified in the table, arranged in 2D torus topology connected by a quasi full duplex NoC (It's a fancy term I'll explain later).
### 1.1: Components within a Tensix Core: 
Components in Tensix Cores:
1. 1.5 MB SRAM (L1)
2. 5x Baby RISCV (RV32IM)
3. 1x Tensix CoProcessor
4. 2x NoC connections + 1 NoC Overlay

![](https://nogieman.github.io/nogieman/images/tensix_dataflow.png)

#### Baby RISCV Cores 
- They are small 32-bit in-order single-issue cores, that execute RV32IM ISA + custom tensix extension.
- The 5x RISCV cores are used as controllers, & are expected to execute one RV32IM instruction per cycle, with 1GHz clk. 
   The fundamental life cycle of an AI compute kernel, i.e, Drata Ingress -> Unpacking -> Compute -> Packing -> Data egress, are driven by the 5 RISCV cores.
- These are responsible as control circuits alone and do not perform any compute operations. They are optimized for area and power.
-  The 5 cores are given 2 main designated tasks: 
    1. NCRISC and BRISC Handle NoC communications.
        - These issue asynchronous NoC read-write commands.
    2. TRISC0, TRISC1 and TRISC2  manage Trnsix execution pipeline.
        - TRISC0 is the unpacker, instructing the DMA engine to load data from SRAM into 4KiB srcA and srcB registers.
        - TRISC1 is the math dispatcher that issues instructions to ALUs.
        - TRISC2 functions as the packer, instructing the hew to format accumulator results and push into SRAM.


| Core Designation  | Primary Hardware Function                     | Pipeline Stage  | Local Instruction Memory| Local Data Memory | Coprocessor Privileges |
|-------------------|-----------------------------------------------|-----------------|-------------------------|-------------------|------------------------|
| RISC-V NC (NCRISC)| NoC 0 Control, DRAM Ingress                   |  Data Movement| ½ KiB Cache + 16 KiB RAM| 4 KiB RAM         | Debug Bus Only         |
| RISC-V T0 (TRISC0)| Unpacker Hardware Dispatch                    |  Data Unpack  | 2 KiB Cache             | 2 KiB RAM         | High / Full Access     |
| RISC-V T1 (TRISC1)| Matrix (FPU) & Vector (SFPU) Dispatch         |  Compute      | ½ KiB Cache             | 2 KiB RAM         | High / Full Access     |
| RISC-V T2 (TRISC2)| Packer Hardware Dispatch                      |  Data Pack    | 2 KiB Cache             | 2 KiB RAM         | High / Full Access     |
| RISC-V B (BRISC)  | NoC 1 Control, DRAM Egress, Tile Orchestration|  Data Movement| 2 KiB Cache             | 4 KiB RAM         | Moderate               |



![Pipeline](https://nogieman.github.io/nogieman/images/pipeline.png)

#### SRAM L1/Scratchpad
TT calls this as L1 but it's just a Scratchpad, as mentioned in their tt-metal docs.
The 1.5 MB SRAM is available per Tensix Core that holds transient data. Hundreads of tensix cores in the chip offer enough memory capacity. The architecture avoids complex cache hierarchies, and instead uses a flat software managed SRAM pool. 
The architecture has hybrid approach where data can be stored in both SRAM and DRAM, to avoid storing excessive data on-chip as well as avoiding multiple DRAM accesses by storing enough intermediate data in SRAM.
- It's organised as 16 banks (91.5 KiB each), each capable of 128 bit read or write per cycle.
- Any port can access any bank, but one at a time. If there's a conflict, remaining ports are forced to wait.
- Some ports (6 ports) have multiple clients attached to them via mux, only one client can access it at a time and remaining will be forced to wait.


![L1](https://nogieman.github.io/nogieman/images/L1.png)

##### Functionalities supported by the ports:
- 128 bit read-write.
- Narrow reads, implemented by simply reading 128 bits and discarding unwamted bits, hence uses same BW as normal read.
- Narrow writes, implemented by read-modify-write operation, blocking port as well as the bank for 5 cycles, hence uses 5 times of the write bandwidth.
- Atomics (operations executed as one uninterrupted task) are implemented as read-modify-write opetations, and block the port and the corresponding bank for 5 cycles. This function is exposed to NoC and ThCon.
- Near memory accumulate (4x FP32 or INT32, sign-magniture with saturation, or 8x FP16, BF16) is implemented as atomic read-modify-write operation, or non-atomic operation. If non-atomic, then it blocks the prot and bank for only 2 cycles, but users have to ensure overlapping operations are not targetting overlapping addresses in the banks. This function is exposed to packers.

The physical placement of DRAM controllers are exploited by default, using "interleaved" mode where data is distributed across all available controllers to balance performance. For specific operations, the data can be stored in "sharded" mode where tensors are distributed across multiple Tensix cores. We'll see them in detail.

# [To be continued because lazy]
