`timescale 1ns / 1ps

module wb_uart (
    input  wire        clk,
    input  wire        rst_n, // Soft reset line from CA-FRU

    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o,

    output reg         tx
);

    reg [31:0] tx_shift;
    reg [3:0]  bit_cnt;
    reg        busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx       <= 1'b1;
            busy     <= 1'b0;
            bit_cnt  <= 4'd0;
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i && !busy) begin
                    tx_shift <= {1'b1, wb_dat_i[7:0], 1'b0}; // Stop bit, Data, Start bit
                    busy     <= 1'b1;
                    bit_cnt  <= 4'd10;
                end else begin
                    wb_dat_o <= {31'd0, busy};
                end
            end

            if (busy) begin
                tx       <= tx_shift[0];
                tx_shift <= {1'b1, tx_shift[31:1]};
                bit_cnt  <= bit_cnt - 1'b1;
                if (bit_cnt == 4'd1) busy <= 1'b0;
            end
        end
    end

endmodule
