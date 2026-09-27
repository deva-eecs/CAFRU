`timescale 1ns / 1ps

module context_logger (
    input  wire        clk,
    input  wire        rst_n,
    
    // Fault/Bottleneck inputs from Monitor
    input  wire        fault_valid,
    input  wire [3:0]  fault_source, // 1: Timeout, 2: Bus Error, 3: Trap, 4: Bottleneck
    input  wire [31:0] fault_addr,
    
    // Internal Log Registers
    output reg  [31:0] log_timestamp,
    output reg  [3:0]  log_source,
    output reg  [31:0] log_address,
    output reg  [31:0] log_count,
    output reg  [31:0] bottleneck_count  // Dedicated performance counter for 4'd4
);

    reg [31:0] cycle_counter;

    // Up-time cycle counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 32'd0;
        end else begin
            cycle_counter <= cycle_counter + 1'b1;
        end
    end

    // Logging logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            log_timestamp    <= 32'd0;
            log_source       <= 4'd0;
            log_address      <= 32'd0;
            log_count        <= 32'd0;
            bottleneck_count <= 32'd0;
        end else if (fault_valid) begin
            log_timestamp <= cycle_counter;
            log_source    <= fault_source;
            log_address   <= fault_addr;
            
            if (fault_source == 4'd4) begin
                // Track total soft performance bottlenecks separately
                bottleneck_count <= bottleneck_count + 1'b1;
            end else begin
                // Track total hard fault occurrences
                log_count <= log_count + 1'b1;
            end
        end
    end

endmodule
