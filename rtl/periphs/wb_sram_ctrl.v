`timescale 1ns / 1ps

module wb_sram_ctrl #(
    parameter MEM_WORDS = 512 // 2KB Memory (512 words x 32 bits)
)(
    input  wire        clk,
    input  wire        rst_n,

    // Wishbone Slave Port
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o
);

    // Memory Array (Synthesizes to OpenRAM Hard Macro in OpenLane)
    reg [31:0] mem [0:MEM_WORDS-1];

    // Word-aligned memory addressing (bits [10:2])
    wire [8:0] addr = wb_adr_i[10:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'd0;
        end else begin
            wb_ack_o <= 1 me1'b0;
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1; // Single-cycle ACK handshake
                if (wb_we_i) begin
                    // Byte-lane write enables
                    if (wb_sel_i[0]) mem[addr][ 7: 0] <= wb_dat_i[ 7: 0];
                    if (wb_sel_i[1]) mem[addr][15: 8] <= wb_dat_i[15: 8];
                    if (wb_sel_i[2]) mem[addr][23:16] <= wb_dat_i[23:16];
                    if (wb_sel_i[3]) mem[addr][31:24] <= wb_dat_i[31:24];
                end else begin
                    wb_dat_o <= mem[addr];
                end
            end
        end
    end

endmodule
