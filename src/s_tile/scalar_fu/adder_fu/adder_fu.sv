module adder_fu #(parameter width = 16) (
    input wire clk,
    input wire reset,
    input wire [width-1:0] a,
    input wire [width-1:0] b,
    output logic [width-1:0] c,
    output logic ack,
    input wire on_off
);

    always @(posedge clk) begin
        if (reset || !on_off) begin
            c <= {width{1'b0}};
            ack <= 1'b0;
        end else begin
            c = a + b;
            ack <= 1'b1;
        end
    end

endmodule