module multiplier_fu #(
    parameter A_WIDTH = 8,
    parameter B_WIDTH = 8,
    parameter C_WIDTH = A_WIDTH+B_WIDTH
)(
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   on_off,
    input  wire [A_WIDTH-1:0]     a,
    input  wire [B_WIDTH-1:0]     b,
    output wire                   valid_out,
    output wire [C_WIDTH-1:0]     c
);

    logic [C_WIDTH-1:0] product_reg;
    logic                       valid_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            product_reg <= {C_WIDTH{1'b0}};
            valid_reg   <= 1'b0;
        end else begin
            if (on_off) begin
                product_reg <= a * b;
            end else begin 
                product_reg <= {C_WIDTH{1'b0}};
            end
        end
    end

    assign c   = product_reg;
    assign valid_out = valid_reg;

endmodule
