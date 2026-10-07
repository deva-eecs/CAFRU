`timescale 1ns / 1ps

module wb_gpio (
    input  wire        clk,
    input  wire        rst_n, // Soft reset line from CA-FRU

    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o,

    output reg  [7:0]  gpio_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_out <= 8'd0;
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    gpio_out <= wb_dat_i[7:0];
                end else begin
                    wb_dat_o <= {24'd0, gpio_out};
                end
            end
        end
    end

endmodule
