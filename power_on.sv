// Corrected power_on.sv
module power_on (
    input logic clk,
    input logic resetb,
    input logic power_good,
    output logic enable
);

    // 5 bits needed for count 0 to 30.
    logic [4:0] counter;
    localparam COUNT_LIMIT = 5'd30; 

    // Use a single sequential block for the state logic (counter and enable)
    always_ff @(posedge clk or negedge resetb) begin
        if (~resetb) begin
            // Asynchronous reset
            counter <= 5'b0;
            enable <= 1'b0;
        end
        else if (~power_good) begin
            // If power_good is removed, reset sequence
            counter <= 5'b0;
            enable <= 1'b0;
        end
        else begin // power_good is asserted (high)
            
            if (counter < COUNT_LIMIT) begin
                // Synchronous update: Count up until limit
                counter <= counter + 1; 
                enable <= 1'b0; // Keep enable low
            end
            else begin
                // Limit is reached: Stop counting and assert enable permanently
                counter <= COUNT_LIMIT; // Counter holds at 30
                enable <= 1'b1;        // Assert enable
            end
            
        end
    end

endmodule