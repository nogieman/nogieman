---
title: "Surface diving into Sambanova's RDU architecture"
date: 2026-10-28
tags: ["AI", "Accelerator", "Reconfigurable", "CGRA","Sambanova"]
---

## 0: First things first
We'll dive into the arch after learning about a few basics, won't take much time I promise. 
As we all know, while building an AI accelerator (specifically for inference) the traditional approach is to build an ISA and then build hardware for it. Standard accelerators dedicate instruction fetch, decode, schedule and execute hardware, which takes lots of area even in ASICs like Tenstorrent's wormhole or, say Huawei's Ascend. RDU circumvents it with this new paradigm (not exactly but new to the AI market) called `Coarse Grained Reconfigurable Architecture` (CGRA).

A Coarse Grain Reconfigurable Architecture ([CGRA](https://aha.stanford.edu/research/cgra-architecture-and-tools)) is a reconfigurable architecture that operates on coarser granularity than traditional reconfigurable architectures such as FPGA.
Generally, CGRA hardware has arrays of mainly two kinds of tiles, one for data storage (memory units) and the other for processing (compute units).

![](https://nogieman.github.io/nogieman/images/cgra.png)

With our focus on Sambanova's Reconfigurable DataFlow Unit (RDU), we'll focus on both the units with all the information we have that is accessible through the internet.

## 1: Sambanova Product SPECS


| Metric | SN10 RDU | SN40L RDU |
|---|---|---|
| Peak Compute | >300 BF16 TFLOPS | 638 BF16 TFLOPS (Per Socket) |
| On-Chip SRAM (PMU) | >300 MB | 520 MB |
| On-Chip Network BW | 150 TB/s | "Hundreds of TB/s" |
| HBM Tier | Not present | 64 GB HBM3 @ 1.8 TB/s |
| DDR Tier (Host to Chip) | 1.5 TB @ 6 Channels (3200MHz) | 1.5 TB DD5 @ 200 GB/s |
| Clock Frequency | Not specified | < 2 GHz |
| Process Node | TSMC 7nm | TSMC 5nm (Dual-die CoWoS) |
| Power Consumption | On-chip Power Management Controller (PwMC) manages ALU switching current. | Regulated by PwMC |

Hardware Rack numbers SN40L:
- Fabricated using TSMC 5nm technology, with a 2.5D Chip-on-Wafer-on-Substrate (CoWoS) chiplet-based design containing two SN40L Reconfigurable Dataflow Dies (RDDs) and HBM. 

- RDUs per socket: 1 RDU per socket. 
    - Each single SN40L RDU socket contains 2 Reconfigurable Dataflow Dies (RDDs).
- Sockets per node: 8 sockets (RDUs) per standard SN40L Node.
- Sockets per rack: 16 sockets (RDUs) in a full commercial data center rack (sold as the SambaRack SN40L-16 or DataScale SN40L-16).
- Hosts per node/rack: 1 Host system per node or rack. (In the 16-socket commercial rack, this single host server is powered by two 64-core CPUs).

We'll now get into the main architecture and later discuss stuff within SN40L RDU.

## 2: Plasticine


# [To be continued because lazy]
