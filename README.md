# Hardware-Accelerated Limit Order Book (LOB)
##  Overview
A highly parallelized, deterministic Limit Order Book (LOB) accelerator designed for High-Frequency Trading (HFT) applications. This core maintains the top 5 "Bids" and top 5 "Asks" for a single instrument, capable of processing new orders, sorting the book, and updating the Top of Book (ToB) prices in a **strict, single-cycle deterministic latency**.

Designed specifically to bypass the limitations of traditional memory architectures, this project maps complex algorithmic order-matching bottlenecks directly onto custom hardware structures to guarantee nanosecond response times.

---

##  Architectural Decisions & Optimization

### 1. The Memory Bottleneck: Flattened Registers over BRAM
Standard Block RAM (BRAM) only permits reading 1-2 addresses per clock cycle. To achieve true $O(1)$ single-cycle insertion, BRAM was entirely avoided. The book state is maintained in a **flattened array of D-Flip Flops**, allowing all 5 price/quantity levels on both sides of the book to be read, compared, and written to simultaneously.

### 2. Overcoming the Silicon Limit: Thermometer Masking
**The Problem:** The initial architecture utilized cascaded `if-else` priority multiplexers. Synthesizing this on a Xilinx Artix-7 resulted in a deep logic chain, yielding a Setup Time violation (**WNS: -2.026 ns** at 300MHz). The signal simply couldn't propagate through 5 cascading multiplexers before the next clock edge.

**The Solution:** Refactored the architecture to eliminate sequential dependencies by implementing a **Parallel Thermometer Mask**. 
* Incoming order prices are routed to 5 separate combinational comparators simultaneously.
* This generates an instant binary mask (e.g., `00111`) indicating exactly which levels the new order beats.
* The insertion logic relies solely on this pre-computed mask, flattening the logic depth to a single 3-input multiplexer per register level.

---

## ⏱️ Timing Closure & Performance

This design achieved timing closure without the need for multi-cycle pipelining, ensuring zero Read-After-Write (RAW) data hazards for back-to-back consecutive orders.

* **Target Device:** Xilinx Artix-7 (`xc7a100tcsg324-1`)
* **Target Clock Period:** $4.500 \text{ ns}$ (~222 MHz)
* **Worst Negative Slack (WNS):** $+0.197 \text{ ns}$
* **Throughput:** 1 Order / Clock Cycle (Deterministic)

*Note: While 222MHz reflects the physical routing limits of the Artix-7 silicon for 32-bit parallel comparisons, this flattened architecture is designed to easily scale beyond 300MHz+ when synthesized on enterprise-grade Virtex UltraScale+ FPGAs.*

---

##  Repository Structure

* `limit_order_book.v` : The core RTL implementation containing the parallel comparator arrays and single-cycle shift-and-insert logic.
* `tb_lob.v` : The behavioral testbench injecting back-to-back overlapping Buy and Sell orders.
* `timing.xdc` : Xilinx Design Constraints file defining the target clock frequency.
* `timing_passed.png` : Visual proof of setup/hold timing closure post-synthesis in Vivado.

---

##  How to Run & Verify

**1. Synthesis & Timing Analysis (Vivado):**
* Create a new Vivado RTL project targeting `xc7a100tcsg324-1`.
* Add `limit_order_book.v` to Design Sources.
* Add `timing.xdc` to Constraints.
* Run **Synthesis** and open the synthesized design.
* Generate a **Timing Summary Report** to verify positive WNS and WHS.

**2. Behavioral Simulation:**
* Add `tb_lob.v` as a Simulation Source.
* Run **Behavioral Simulation** in Vivado.
* Monitor the waveform to observe `best_bid_price` and `best_ask_price` updating deterministically on the clock edge immediately following `order_valid`.
