`timescale 1ns / 1ps

module wb_interconnect (
    input  wire        clk,
    input  wire        rst_n,

    // --- Master Interface (PicoRV32 Core) ---
    input  wire [31:0] m_wb_adr_i,
    input  wire [31:0] m_wb_dat_i,
    output reg  [31:0] m_wb_dat_o,
    input  wire        m_wb_we_i,
    input  wire [3:0]  m_wb_sel_i,
    input  wire        m_wb_stb_i,
    input  wire        m_wb_cyc_i,
    output reg         m_wb_ack_o,
    output reg         m_wb_err_o,

    // --- Slave 0: SRAM Memory (0x0000_0000 - 0x0000_07FF) ---
    output wire [31:0] s0_wb_adr_o,
    output wire [31:0] s0_wb_dat_o,
    input  wire [31:0] s0_wb_dat_i,
    output wire        s0_wb_we_o,
    output wire [3:0]  s0_wb_sel_o,
    output wire        s0_wb_stb_o,
    output wire        s0_wb_cyc_o,
    input  wire        s0_wb_ack_i,

    // --- Slave 1: UART Peripheral (0x4000_0000 - 0x4000_FFFF) ---
    output wire [31:0] s1_wb_adr_o,
    output wire [31:0] s1_wb_dat_o,
    input  wire [31:0] s1_wb_dat_i,
    output wire        s1_wb_we_o,
    output wire [3:0]  s1_wb_sel_o,
    output wire        s1_wb_stb_o,
    output wire        s1_wb_cyc_o,
    input  wire        s1_wb_ack_i,

    // --- Slave 2: GPIO Peripheral (0x4001_0000 - 0x4001_FFFF) ---
    output wire [31:0] s2_wb_adr_o,
    output wire [31:0] s2_wb_dat_o,
    input  wire [31:0] s2_wb_dat_i,
    output wire        s2_wb_we_o,
    output wire [3:0]  s2_wb_sel_o,
    output wire        s2_wb_stb_o,
    output wire        s2_wb_cyc_o,
    input  wire        s2_wb_ack_i,

    // --- Slave 3: Timer Peripheral (0x4002_0000 - 0x4002_FFFF) ---
    output wire [31:0] s3_wb_adr_o,
    output wire [31:0] s3_wb_dat_o,
    input  wire [31:0] s3_wb_dat_i,
    output wire        s3_wb_we_o,
    output wire [3:0]  s3_wb_sel_o,
    output wire        s3_wb_stb_o,
    output wire        s3_wb_cyc_o,
    input  wire        s3_wb_ack_i,

    // --- Slave 4: CA-FRU Registers (0x5000_0000 - 0x5000_FFFF) ---
    output wire [31:0] s4_wb_adr_o,
    output wire [31:0] s4_wb_dat_o,
    input  wire [31:0] s4_wb_dat_i,
    output wire        s4_wb_we_o,
    output wire [3:0]  s4_wb_sel_o,
    output wire        s4_wb_stb_o,
    output wire        s4_wb_cyc_o,
    input  wire        s4_wb_ack_i
);

    // --- Address Decoding Logic (Based on Memory Map) ---
    wire sel_sram  = (m_wb_adr_i[31:16] == 16'h0000);
    wire sel_uart  = (m_wb_adr_i[31:16] == 16'h4000);
    wire sel_gpio  = (m_wb_adr_i[31:16] == 16'h4001);
    wire sel_timer = (m_wb_adr_i[31:16] == 16'h4002);
    wire sel_cafru = (m_wb_adr_i[31:16] == 16'h5000);

    // Unmapped address flag
    wire invalid_addr = m_wb_cyc_i && m_wb_stb_i && !(sel_sram || sel_uart || sel_gpio || sel_timer || sel_cafru);

    // --- Broadcast Common Signals to All Slaves ---
    assign s0_wb_adr_o = m_wb_adr_i;  assign s0_wb_dat_o = m_wb_dat_i;  assign s0_wb_we_o = m_wb_we_i;  assign s0_wb_sel_o = m_wb_sel_i;
    assign s1_wb_adr_o = m_wb_adr_i;  assign s1_wb_dat_o = m_wb_dat_i;  assign s1_wb_we_o = m_wb_we_i;  assign s1_wb_sel_o = m_wb_sel_i;
    assign s2_wb_adr_o = m_wb_adr_i;  assign s2_wb_dat_o = m_wb_dat_i;  assign s2_wb_we_o = m_wb_we_i;  assign s2_wb_sel_o = m_wb_sel_i;
    assign s3_wb_adr_o = m_wb_adr_i;  assign s3_wb_dat_o = m_wb_dat_i;  assign s3_wb_we_o = m_wb_we_i;  assign s3_wb_sel_o = m_wb_sel_i;
    assign s4_wb_adr_o = m_wb_adr_i;  assign s4_wb_dat_o = m_wb_dat_i;  assign s4_wb_we_o = m_wb_we_i;  assign s4_wb_sel_o = m_wb_sel_i;

    // --- Targeted Strobe & Cycle Routing ---
    assign s0_wb_cyc_o = m_wb_cyc_i && sel_sram;   assign s0_wb_stb_o = m_wb_stb_i && sel_sram;
    assign s1_wb_cyc_o = m_wb_cyc_i && sel_uart;   assign s1_wb_stb_o = m_wb_stb_i && sel_uart;
    assign s2_wb_cyc_o = m_wb_cyc_i && sel_gpio;   assign s2_wb_stb_o = m_wb_stb_i && sel_gpio;
    assign s3_wb_cyc_o = m_wb_cyc_i && sel_timer;  assign s3_wb_stb_o = m_wb_stb_i && sel_timer;
    assign s4_wb_cyc_o = m_wb_cyc_i && sel_cafru;  assign s4_wb_stb_o = m_wb_stb_i && sel_cafru;

    // --- Master Multiplexer: Return Read Data, Acknowledge & Bus Errors ---
    always @(*) begin
        m_wb_dat_o = 32'd0;
        m_wb_ack_o = 1'b0;
        m_wb_err_o = 1'b0;

        if (sel_sram) begin
            m_wb_dat_o = s0_wb_dat_i;
            m_wb_ack_o = s0_wb_ack_i;
        end else if (sel_uart) begin
            m_wb_dat_o = s1_wb_dat_i;
            m_wb_ack_o = s1_wb_ack_i;
        end else if (sel_gpio) begin
            m_wb_dat_o = s2_wb_dat_i;
            m_wb_ack_o = s2_wb_ack_i;
        end else if (sel_timer) begin
            m_wb_dat_o = s3_wb_dat_i;
            m_wb_ack_o = s3_wb_ack_i;
        end else if (sel_cafru) begin
            m_wb_dat_o = s4_wb_dat_i;
            m_wb_ack_o = s4_wb_ack_i;
        end else if (invalid_addr) begin
            m_wb_err_o = 1'b1; // Trigger Bus Error (wb_err = 1) for CA-FRU to capture as 4'd2
        end
    end

endmodule
