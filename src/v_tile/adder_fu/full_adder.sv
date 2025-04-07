module full_adder #(parameter width = 16) (
    input wire clk,
    input wire reset,
    input wire [width-1:0] a,
    input wire [width-1:0] b,
    input wire carry_in,
    output reg [width-1:0] c,
    output reg carry_out,
    output reg ack,
    input wire carry_listen,
    input wire on_off
);

    always @(posedge clk) begin
        if (reset || !on_off) begin
            c <= {width{1'b0}};
            carry_out <= 1'b0;
            ack <= 1'b0;
        end else begin
            if (carry_listen) begin
                {carry_out, c} = a + b + carry_in;
                ack <= 1'b1;
            end else begin
                {carry_out, c} = a + b;
                ack <= 1'b1;
            end
        end
    end

endmodule