module multiplier_fu #(
    parameter width = 32,
    parameter out_width = width+width
)(
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   on_off,
    input  wire [width-1:0]       a,
    input  wire [width-1:0]       b,
    output wire                   ack,
    output wire [out_width-1:0]   c
);

    logic [out_width-1:0]         product_reg;
    logic                         ack_reg;

    always_ff @(posedge clk) begin
        if (reset || !on_off) begin
            product_reg <= {out_width{1'b0}};
            ack_reg   <= 1'b0;
        end else begin
            product_reg <= a * b;
            ack_reg   <= 1'b1;
        end
    end

    assign c   = product_reg;
    assign ack = ack_reg;

endmodule
