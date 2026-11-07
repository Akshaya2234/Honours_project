// =============================================================================
// File    : timer_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Package for System Timer VIP
// =============================================================================

`ifndef TIMER_PKG_SV
`define TIMER_PKG_SV

package timer_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "timer_seq_item.sv"
    `include "timer_config.sv"
    `include "timer_monitor.sv"
    `include "timer_agent.sv"
endpackage : timer_pkg

`endif // TIMER_PKG_SV
