`timescale 1ns / 1ps

module tb_soc_top;

    reg clk;
    reg sys_rst_n;
    wire [7:0] gpio_out;
    wire uart_tx;
    wire bottleneck_warn;

    // Instantiate Top System
    soc_top uut (
        .clk(clk),
        .sys_rst_n(sys_rst_n),
        .gpio_out(gpio_out),
        .uart_tx(uart_tx),
        .bottleneck_warn(bottleneck_warn)
    );

    // 50 MHz System Clock Generation
    always #10 clk = ~clk;

    initial begin
        $dumpfile("tb_soc_top.vcd");
        $dumpvars(0, tb_soc_top);

        clk = 0;
        sys_rst_n = 0;
        #100;
        sys_rst_n = 1;

        $display("--- Starting CA-FRU RISC-V SoC Simulation ---");

        #50000;
        $display("--- Simulation Ended Successfully ---");
        $finish;
    end

endmodule
