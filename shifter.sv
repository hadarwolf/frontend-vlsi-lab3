
module shifter (
    input [3:0] a,
    input [1:0] b,
    output reg [6:0] y
);

// The sensitivity list includes all inputs: a and b
always_comb begin
    // Reset y to all zeros before assignment to handle all cases (especially unused bits)
    y = 7'b0; 

    // Use a case statement to implement the shift based on the value of b
    case (b)
        2'b00: // Shift by 0
            y = {3'b000, a[3:0]}; // Concatenate 3 leading zeros, then a
        2'b01: // Shift by 1
            y = {2'b00, a[3:0], 1'b0}; // Concatenate a, 2 leading zeros, and 1 trailing zero
        2'b10: // Shift by 2
            y = {1'b0, a[3:0], 2'b00}; // Concatenate a, 1 leading zero, and 2 trailing zeros
        2'b11: // Shift by 3
            y = {a[3:0], 3'b000}; // Concatenate a and 3 trailing zeros
        default: // Should not happen with 2-bit b, but good practice
            y = 7'b0;
    endcase
end

endmodule
