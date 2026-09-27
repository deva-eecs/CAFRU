`timescale 1ns / 1ps

module fault_monitor #(
    parameter TIMEOUT_CYCLES = 256,
    parameter BOTTLENECK_THRESH = 32  // Cycles before flagging a latency bottleneck
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // Wishbone Bus Monitoring Signals
    input  wire        wb_cyc,
    input  wire        wb_stb,
    input  wire        wb_ack,
    input  wire        wb_err,
    input  wire [31:0] wb_addr,
    
    // Core Status Signals
    input  wire        core_trap,
    
    // Fault Triggers to Recovery Controller / Logger
    output reg         fault_valid,
    output reg  [3:0]  fault_source, // 0: None, 1: Bus Timeout, 2: Bus Error, 3: Core Trap, 4: Bottleneck
    output reg  [31:0] fault_addr,
    
    // Dedicated Bottleneck Warning Line (e.g., can route as an interrupt to CPU)
    output reg         bottleneck_warn
);

    reg [15:0] timeout_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_counter <= 16'd0;
            fault_valid     <= 1'b0;
            fault_source    <= 4'd0;
            fault_addr      <= 32'd0;
            bottleneck_warn <= 1'b0;
        end else begin
            fault_valid     <= 1'b0; // Default pulse high for 1 cycle
            bottleneck_warn <= 1'b0;
            
            // Bus Transaction Monitoring
            if (wb_cyc && wb_stb && !wb_ack) begin
                timeout_counter <= timeout_counter + 1'b1;

                // 1. Bottleneck Check (Soft Warning Threshold)
                if (timeout_counter == BOTTLENECK_THRESH) begin
                    bottleneck_warn <= 1'b1;
                    fault_valid     <= 1'b1;
                    fault_source    <= 4'd4; // Source 4 = Bus Bottleneck / High Latency
                    fault_addr      <= wb_addr;
                end

                // 2. Hard Timeout Check (Triggers Localized Recovery Reset)
                if (timeout_counter >= TIMEOUT_CYCLES) begin
                    fault_valid     <= 1'b1;
                    fault_source    <= 4'd1; // Source 1 = Hard Bus Timeout
                    fault_addr      <= wb_addr;
                    timeout_counter <= 16'd0;
                end
            end else begin
                timeout_counter <= 16'd0;
            end

            // Bus Error Flag Check
            if (wb_cyc && wb_stb && wb_err) begin
                fault_valid  <= 1'b1;
                fault_source <= 4'd2; // Bus Error
                fault_addr   <= wb_addr;
            end

            // CPU Trap Check
            if (core_trap) begin
                fault_valid  <= 1'b1;
                fault_source <= 4'd3; // Core Trap
                fault_addr   <= wb_addr;
            end
        end
    end

endmodule
