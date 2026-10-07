`timescale 1ns / 1ps

module soc_top (
    input  wire        clk,
    input  wire        sys_rst_n,

    // External Peripherals
    output wire [7:0]  gpio_out,
    output wire        uart_tx,

    // Status Signals
    output wire        bottleneck_warn
);

    // Isolated Soft Resets driven by CA-FRU Recovery Unit
    wire rst_n_cpu;
    wire rst_n_uart;
    wire rst_n_gpio;
    wire rst_n_timer;

    // CPU Wishbone Master Interfaces
    wire [31:0] cpu_wb_adr, cpu_wb_wdata, cpu_wb_rdata;
    wire        cpu_wb_we, cpu_wb_stb, cpu_wb_cyc, cpu_wb_ack, cpu_wb_err;
    wire [3:0]  cpu_wb_sel;
    wire        core_trap;

    // Interconnect to Slave Interfaces
    wire [31:0] s0_adr, s0_wdata, s0_rdata; wire s0_we, s0_stb, s0_cyc, s0_ack; wire [3:0] s0_sel;
    wire [31:0] s1_adr, s1_wdata, s1_rdata; wire s1_we, s1_stb, s1_cyc, s1_ack; wire [3:0] s1_sel;
    wire [31:0] s2_adr, s2_wdata, s2_rdata; wire s2_we, s2_stb, s2_cyc, s2_ack; wire [3:0] s2_sel;
    wire [31:0] s3_adr, s3_wdata, s3_rdata; wire s3_we, s3_stb, s3_cyc, s3_ack; wire [3:0] s3_sel;
    wire [31:0] s4_adr, s4_wdata, s4_rdata; wire s4_we, s4_stb, s4_cyc, s4_ack; wire [3:0] s4_sel;

    // CA-FRU Readout Signals
    wire [31:0] log_timestamp, log_address, log_count, bottleneck_count;
    wire [3:0]  log_source;

    // 1. PicoRV32 Core Instance
    picorv32_wb #(
        .ENABLE_COUNTERS(1),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0)
    ) u_cpu (
        .wb_clk_i(clk),
        .wb_rst_i(~rst_n_cpu), // PicoRV32 uses active-high reset
        .wbm_adr_o(cpu_wb_adr),
        .wbm_dat_o(cpu_wb_wdata),
        .wbm_dat_i(cpu_wb_rdata),
        .wbm_we_o(cpu_wb_we),
        .wbm_sel_o(cpu_wb_sel),
        .wbm_stb_o(cpu_wb_stb),
        .wbm_cyc_o(cpu_wb_cyc),
        .wbm_ack_i(cpu_wb_ack),
        .trap(core_trap)
    );

    // 2. Wishbone Interconnect
    wb_interconnect u_bus (
        .clk(clk), .rst_n(sys_rst_n),
        .m_wb_adr_i(cpu_wb_adr), .m_wb_dat_i(cpu_wb_wdata), .m_wb_dat_o(cpu_wb_rdata),
        .m_wb_we_i(cpu_wb_we),   .m_wb_sel_i(cpu_wb_sel),   .m_wb_stb_i(cpu_wb_stb),
        .m_wb_cyc_i(cpu_wb_cyc), .m_wb_ack_o(cpu_wb_ack),   .m_wb_err_o(cpu_wb_err),

        .s0_wb_adr_o(s0_adr), .s0_wb_dat_o(s0_wdata), .s0_wb_dat_i(s0_rdata),
        .s0_wb_we_o(s0_we),   .s0_wb_sel_o(s0_sel),   .s0_wb_stb_o(s0_stb),
        .s0_wb_cyc_o(s0_cyc), .s0_wb_ack_i(s0_ack),

        .s1_wb_adr_o(s1_adr), .s1_wb_dat_o(s1_wdata), .s1_wb_dat_i(s1_rdata),
        .s1_wb_we_o(s1_we),   .s1_wb_sel_o(s1_sel),   .s1_wb_stb_o(s1_stb),
        .s1_wb_cyc_o(s1_cyc), .s1_wb_ack_i(s1_ack),

        .s2_wb_adr_o(s2_adr), .s2_wb_dat_o(s2_wdata), .s2_wb_dat_i(s2_rdata),
        .s2_wb_we_o(s2_we),   .s2_wb_sel_o(s2_sel),   .s2_wb_stb_o(s2_stb),
        .s2_wb_cyc_o(s2_cyc), .s2_wb_ack_i(s2_ack),

        .s3_wb_adr_o(s3_adr), .s3_wb_dat_o(s3_wdata), .s3_wb_dat_i(s3_rdata),
        .s3_wb_we_o(s3_we),   .s3_wb_sel_o(s3_sel),   .s3_wb_stb_o(s3_stb),
        .s3_wb_cyc_o(s3_cyc), .s3_wb_ack_i(s3_ack),

        .s4_wb_adr_o(s4_adr), .s4_wb_dat_o(s4_wdata), .s4_wb_dat_i(s4_rdata),
        .s4_wb_we_o(s4_we),   .s4_wb_sel_o(s4_sel),   .s4_wb_stb_o(s4_stb),
        .s4_wb_cyc_o(s4_cyc), .s4_wb_ack_i(s4_ack)
    );

    // 3. OpenRAM Controller
    wb_sram_ctrl u_sram_ctrl (
        .clk(clk), .rst_n(sys_rst_n),
        .wb_adr_i(s0_adr), .wb_dat_i(s0_wdata), .wb_dat_o(s0_rdata),
        .wb_we_i(s0_we),   .wb_sel_i(s0_sel),   .wb_stb_i(s0_stb),
        .wb_cyc_i(s0_cyc), .wb_ack_o(s0_ack)
    );

    // 4. UART Instance (Resets using rst_n_uart)
    wb_uart u_uart (
        .clk(clk), .rst_n(rst_n_uart),
        .wb_adr_i(s1_adr), .wb_dat_i(s1_wdata), .wb_dat_o(s1_rdata),
        .wb_we_i(s1_we),   .wb_stb_i(s1_stb),   .wb_cyc_i(s1_cyc),
        .wb_ack_o(s1_ack), .tx(uart_tx)
    );

    // 5. GPIO Instance (Resets using rst_n_gpio)
    wb_gpio u_gpio (
        .clk(clk), .rst_n(rst_n_gpio),
        .wb_adr_i(s2_adr), .wb_dat_i(s2_wdata), .wb_dat_o(s2_rdata),
        .wb_we_i(s2_we),   .wb_stb_i(s2_stb),   .wb_cyc_i(s2_cyc),
        .wb_ack_o(s2_ack), .gpio_out(gpio_out)
    );

    // 6. Timer Instance Stub (Resets using rst_n_timer)
    assign s3_ack = s3_cyc && s3_stb;
    assign s3_rdata = 32'd0;

    // 7. CA-FRU IP Subsystem
    ca_fru u_cafru (
        .clk(clk), .sys_rst_n(sys_rst_n),
        .wb_cyc(cpu_wb_cyc), .wb_stb(cpu_wb_stb), .wb_ack(cpu_wb_ack),
        .wb_err(cpu_wb_err), .wb_addr(cpu_wb_adr), .core_trap(core_trap),
        .rst_n_uart(rst_n_uart), .rst_n_gpio(rst_n_gpio),
        .rst_n_timer(rst_n_timer), .rst_n_cpu(rst_n_cpu),
        .bottleneck_warn(bottleneck_warn),
        .log_timestamp(log_timestamp), .log_source(log_source),
        .log_address(log_address), .log_count(log_count),
        .bottleneck_count(bottleneck_count)
    );

    // CA-FRU Memory-Mapped Register Readout (Base 0x5000_0000)
    reg [31:0] cafru_rdata; reg cafru_ack;
    always @(posedge clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cafru_ack <= 1'b0; cafru_rdata <= 32'd0;
        end else begin
            cafru_ack <= 1'b0;
            if (s4_cyc && s4_stb && !cafru_ack) begin
                cafru_ack <= 1'b1;
                case (s4_adr[3:0])
                    4'h0: cafru_rdata <= log_timestamp;
                    4'h4: cafru_rdata <= {28'd0, log_source};
                    4'h8: cafru_rdata <= log_address;
                    4'hC: cafru_rdata <= log_count;
                    4'h2: cafru_rdata <= bottleneck_count;
                    default: cafru_rdata <= 32'd0;
                endcase
            end
        end
    end
    assign s4_rdata = cafru_rdata;
    assign s4_ack   = cafru_ack;

endmodule
