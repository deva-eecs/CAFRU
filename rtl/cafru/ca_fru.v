`timescale 1ns / 1ps

module ca_fru (
    input  wire        clk,
    input  wire        sys_rst_n,
    
    // Monitored Bus Signals
    input  wire        wb_cyc,
    input  wire        wb_stb,
    input  wire        wb_ack,
    input  wire        wb_err,
    input  wire [31:0] wb_addr,
    
    // Core Status
    input  wire        core_trap,
    
    // Isolated System Resets
    output wire        rst_n_uart,
    output wire        rst_n_gpio,
    output wire        rst_n_timer,
    output wire        rst_n_cpu,
    
    // Bottleneck Warning Line (routed directly to CPU Interrupt Controller)
    output wire        bottleneck_warn,
    
    // Status Register Outputs (for CPU readout)
    output wire [31:0] log_timestamp,
    output wire [3:0]  log_source,
    output wire [31:0] log_address,
    output wire [31:0] log_count,
    output wire [31:0] bottleneck_count
);

    wire        fault_valid;
    wire [3:0]  fault_source;
    wire [31:0] fault_addr;

    fault_monitor u_monitor (
        .clk(clk),
        .rst_n(sys_rst_n),
        .wb_cyc(wb_cyc),
        .wb_stb(wb_stb),
        .wb_ack(wb_ack),
        .wb_err(wb_err),
        .wb_addr(wb_addr),
        .core_trap(core_trap),
        .fault_valid(fault_valid),
        .fault_source(fault_source),
        .fault_addr(fault_addr),
        .bottleneck_warn(bottleneck_warn)
    );

    context_logger u_logger (
        .clk(clk),
        .rst_n(sys_rst_n),
        .fault_valid(fault_valid),
        .fault_source(fault_source),
        .fault_addr(fault_addr),
        .log_timestamp(log_timestamp),
        .log_source(log_source),
        .log_address(log_address),
        .log_count(log_count),
        .bottleneck_count(bottleneck_count)
    );

    recovery_ctrl u_recovery (
        .clk(clk),
        .sys_rst_n(sys_rst_n),
        .fault_valid(fault_valid),
        .fault_source(fault_source),
        .fault_addr(fault_addr),
        .rst_n_uart(rst_n_uart),
        .rst_n_gpio(rst_n_gpio),
        .rst_n_timer(rst_n_timer),
        .rst_n_cpu(rst_n_cpu)
    );

endmodule
