`timescale 1ns / 1ps

module wb_timer (
    input  wire        clk,
    input  wire        rst_n, // Connected to CA-FRU rst_n_timer line

    // Wishbone Slave Interface
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o,

    // Timer Interrupt Output
    output reg         timer_irq
);

    // Register Map (Base Address: 0x4002_0000)
    // 0x00: Counter Register (timer_counter)
    // 0x04: Compare Register (timer_compare)
    // 0x08: Control Register (timer_ctrl: bit 0 = enable)
    reg [31:0] timer_counter;
    reg [31:0] timer_compare;
    reg        timer_enable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_counter <= 32'd0;
            timer_compare <= 32'hFFFF_FFFF;
            timer_enable  <= 1'b0;
            timer_irq     <= 1'b0;
            wb_ack_o      <= 1'b0;
            wb_dat_o      <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;

            // Timer Tick Logic
            if (timer_enable) begin
                timer_counter <= timer_counter + 1'b1;
                if (timer_counter >= timer_compare) begin
                    timer_irq <= 1'b1; // Assert interrupt when target value is reached
                end
            end

            // Wishbone Read/Write Interface Logic
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[3:0])
                        4'h0: timer_counter <= wb_dat_i;
                        4'h4: timer_compare <= wb_dat_i;
                        4'h8: begin
                            timer_enable <= wb_dat_i[0];
                            if (wb_dat_i[1]) timer_irq <= 1'b1; // Clear IRQ flag
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[3:0])
                        4'h0: wb_dat_o <= timer_counter;
                        4'h4: wb_dat_o <= timer_compare;
                        4'h8: wb_dat_o <= {30'd0, timer_irq, timer_enable};
                        default: wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
