
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


#### NoC Interfaces 

![Pipeline](https://nogieman.github.io/nogieman/images/pipeline.png)

#### SRAM L1/Scratchpad
TT calls this as L1 but it's just a Scratchpad, as mentioned in their tt-metal docs.
The 1.5 MB SRAM is available per Tensix Core that holds transient data. Hundreads of tensix cores in the chip offer enough memory capacity. The architecture avoids complex cache hierarchies, and instead uses a flat software managed SRAM pool. 
The architecture has hybrid approach where data can be stored in both SRAM and DRAM, to avoid storing excessive data on-chip as well as avoiding multiple DRAM accesses by storing enough intermediate data in SRAM.
- It's organised as 16 banks (91.5 KiB each), each capable of 128 bit read or write per cycle.
- Any port can access any bank, but one at a time. If there's a conflict, remaining ports are forced to wait.
- Some ports (6 ports) have multiple clients attached to them via mux, only one client can access it at a time and remaining will be forced to wait.


![L1](https://nogieman.github.io/nogieman/images/L1.png)

Functionalities supported by the ports:
- 128 bit read-write.
- Narrow reads, implemented by simply reading 128 bits and discarding unwamted bits, hence uses same BW as normal read.
- Narrow writes, implemented by read-modify-write operation, blocking port as well as the bank for 5 cycles, hence uses 5 times of the write bandwidth.
- Atomics (operations executed as one uninterrupted task) are implemented as read-modify-write opetations, and block the port and the corresponding bank for 5 cycles. This function is exposed to NoC and ThCon.
- Near memory accumulate (4x FP32 or INT32, sign-magniture with saturation, or 8x FP16, BF16) is implemented as atomic read-modify-write operation, or non-atomic operation. If non-atomic, then it blocks the prot and bank for only 2 cycles, but users have to ensure overlapping operations are not targetting overlapping addresses in the banks. This function is exposed to packers.

The physical placement of DRAM controllers are exploited by default, using "interleaved" mode where data is distributed across all available controllers to balance performance. For specific operations, the data can be stored in "sharded" mode where tensors are distributed across multiple Tensix cores. We'll see them in detail.

#### Bandwidth
##### RISCV Cores 
-> These store instructions (always narrow), so peak bandwidth is 32 bit write every 5 cycles (6.4 bits per cycle). It can be delayed more when other hardwares are trying to access via same port.
-> Number of issued loads is limited to 4, hence the sustained throughput is limited to 4 32-bit reads every 7 cycles. If loads are interdependent, throughput may decrease even further with poorly sheduled assembly, to 1 load every 8 cycles.
-> Instruction fetches into cache are always 128 bit, so it yields 4 instructions, so it's expected to occur once every 4 cycles at most, and ideally it's even less if instruction cache hit rate is high.

-> These numbers are lower than other `clients`, so it's better if the cores insrtruct the clients to access L1 on their behalf. For atomic operations, they have to instruct either ThCon or NoC to perform, as they don't implement "A" instructions.
-> It's better to use any other memory region as their bandwidth is higher than L1. Particularly, it's better the call stack is kept in local data RAM rather than L1.

##### Mover
-> It has 1 connection each for reading and writing. Theoretically it allows one 128 bit read and write every cycle, but practucally it does eight 128 bit read and write in 11 cycles (93.1 x2 bit per cycle). The port connection's access may reduce it further.
-> Reader and writer do not have any bank conflicts, because usually they don't access same bank. It may cause a conflict if they're accessed by different clients and they need the same bank.

##### Unpackers
-> If one unpacker is operating, it can achieve four 128 bit reads in 1 cycle theoretically. If both are operating, thoretically they can achieve five 128 bit reads per cycle because of shared ports.
-> There could be a lot of access port connection for BFFP exponent reads but they're infrequent, because one read can provide exponents for 256 datums.
-> The bottleneck for it could be the downstream, where it'll stop reading from L1.

##### Packers 
-> There are 4 packers, each theoretically capable of one 128 bit write or atomic accumulate every 5 cycles or one 128 bit non atomic accumulate every 2 cycles. Port or bank contention may reduce this.
-> Packer 0 can optionally read from L1, these operations can theoretically achieve one 128 bit write or read per cycle and one 128 bit accumulate evry 5 cycles. The remaining 3 can't do this so they'll be in idle when L1-L1 operation is being performed, so, Packer 2's write and Packer 0's operation can never have contention here in port 2.

##### Scalar Unit (ThCon)
-> Can perform 32 or 128 bit reads.
-> Can issue only 1 memory request every 3 cycles.
-> 32 bit write cycles have peak BW of one write every 5 cycles, so 128 bit is preferred.

##### NoC
-> Four 128 bit connections to L1, a pair for reading and writing each. They don't get port contention (as only debug clients are there) but may get bank conflicts.
-> Theoretically they can do 256 bit reads and writes per cycle, and connections between adjacent NoC routers are also of same width so they can perform 256 bit hops through the network, and one hop takes 9 cycles.

# [To be continued because lazy]
