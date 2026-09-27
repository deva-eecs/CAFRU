`timescale 1ns / 1ps

module recovery_ctrl #(
    parameter RESET_PULSE_CYCLES = 16
)(
    input  wire        clk,
    input  wire        sys_rst_n,
    
    // Fault/Bottleneck Events
    input  wire        fault_valid,
    input  wire [3:0]  fault_source,
    input  wire [31:0] fault_addr,
    
    // Isolated Active-Low Soft Resets
    output reg         rst_n_uart,
    output reg         rst_n_gpio,
    output reg         rst_n_timer,
    output reg         rst_n_cpu
);

    reg [7:0] uart_rst_cnt;
    reg [7:0] gpio_rst_cnt;
    reg [7:0] timer_rst_cnt;

    // Filter out bottleneck warnings (4'd4) — only hard faults (1, 2, 3) trigger resets
    wire is_hard_fault = fault_valid && (fault_source != 4'd4);

    // Decode peripheral address ranges
    wire is_uart_addr  = (fault_addr[31:16] == 16'h4000); // UART Range 0x4000_xxxx
    wire is_gpio_addr  = (fault_addr[31:16] == 16'h4001); // GPIO Range 0x4001_xxxx
    wire is_timer_addr = (fault_addr[31:16] == 16'h4002); // Timer Range 0x4002_xxxx

    always @(posedge clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rst_n_uart   <= 1'b1;
            rst_n_gpio   <= 1'b1;
            rst_n_timer  <= 1'b1;
            rst_n_cpu    <= 1'b1;
            uart_rst_cnt <= 8'd0;
            gpio_rst_cnt <= 8'd0;
            timer_rst_cnt<= 8'd0;
        end else begin
            // Pulse handling for UART reset
            if (is_hard_fault && is_uart_addr) begin
                rst_n_uart   <= 1'b0;
                uart_rst_cnt <= RESET_PULSE_CYCLES;
            end else if (uart_rst_cnt > 0) begin
                uart_rst_cnt <= uart_rst_cnt - 1'b1;
                if (uart_rst_cnt == 8'd1) rst_n_uart <= 1'b1;
            end

            // Pulse handling for GPIO reset
            if (is_hard_fault && is_gpio_addr) begin
                rst_n_gpio   <= 1'b0;
                gpio_rst_cnt <= RESET_PULSE_CYCLES;
            end else if (gpio_rst_cnt > 0) begin
                gpio_rst_cnt <= gpio_rst_cnt - 1'b1;
                if (gpio_rst_cnt == 8'd1) rst_n_gpio <= 1'b1;
            end

            // Pulse handling for Timer reset
            if (is_hard_fault && is_timer_addr) begin
                rst_n_timer   <= 1'b0;
                timer_rst_cnt <= RESET_PULSE_CYCLES;
            end else if (timer_rst_cnt > 0) begin
                timer_rst_cnt <= timer_rst_cnt - 1'b1;
                if (timer_rst_cnt == 8'd1) rst_n_timer <= 1'b1;
            end
            
            // Core Reset on unmapped hard fault or Core Trap
            if (is_hard_fault && (fault_source == 4'd3 || (!is_uart_addr && !is_gpio_addr && !is_timer_addr))) begin
                rst_n_cpu <= 1'b0;
            end else begin
                rst_n_cpu <= 1'b1;
            end
        end
    end

endmodule
