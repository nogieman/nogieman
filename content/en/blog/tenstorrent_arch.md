
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

# [To be continued]
